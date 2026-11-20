"""Local API. All numerical work and CAD exports run in an owned worker process."""
from contextlib import asynccontextmanager
from concurrent.futures import ProcessPoolExecutor
from concurrent.futures.process import BrokenProcessPool
from pathlib import Path
import asyncio
import os
import resource
import json
import sys
import subprocess
import uuid
import yaml
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from turtle_sim.geometry import ROOT, GENERATED, COMPONENTS, SAND_BALLAST, manifest, load_mesh
from turtle_sim.config import Configuration, missing, calculate
from turtle_sim.sailing_setup import Scenario, run_sailing, list_scenarios, load_coefficients
from pydantic import BaseModel, ConfigDict


class SailRequest(BaseModel):
    model_config=ConfigDict(extra='forbid')
    configuration: Configuration
    scenario: Scenario

DATA=Path(os.environ.get('TURTLE_SIM_DATA', str(ROOT/'sim/data')))
JOBS={}
# Address-space cap for the worker process, so a runaway calculation fails on
# its own instead of exhausting system RAM. A normal full-turtle solve reserves
# ~2.1 GB of address space (~0.3 GB resident). Override with
# TURTLE_SIM_WORKER_MEM_MB; 0 disables the cap.
WORKER_MEM_MB=int(os.environ.get('TURTLE_SIM_WORKER_MEM_MB','4096'))
MEMORY_MESSAGE=(f'The calculation ran out of its {WORKER_MEM_MB} MB memory allowance and was '
                'stopped to protect the computer. Raise TURTLE_SIM_WORKER_MEM_MB if this '
                'model genuinely needs more.')


def limit_worker_memory():
    """Process-pool initializer: cap the worker's soft address-space limit."""
    if WORKER_MEM_MB>0:
        _,hard=resource.getrlimit(resource.RLIMIT_AS)
        resource.setrlimit(resource.RLIMIT_AS,(WORKER_MEM_MB*1024*1024,hard))


def lift_memory_limit():
    # OpenSCAD's own memory need is not measured; keep its pre-existing behaviour.
    _,hard=resource.getrlimit(resource.RLIMIT_AS)
    resource.setrlimit(resource.RLIMIT_AS,(hard,hard))


def new_pool():
    return ProcessPoolExecutor(max_workers=1,initializer=limit_worker_memory)


def export_job():
    p=subprocess.run([sys.executable,str(ROOT/'build/export_sim.py')],cwd=ROOT,
                     capture_output=True,text=True,timeout=7200,preexec_fn=lift_memory_limit)
    if p.returncode: raise ValueError(p.stderr[-4000:] or p.stdout[-4000:])
    return {'status':'exported','manifest':manifest()}


@asynccontextmanager
async def lifespan(app):
    DATA.mkdir(parents=True,exist_ok=True)
    app.state.pool=new_pool()
    app.state.exporting=False
    yield
    app.state.pool.shutdown(wait=True,cancel_futures=True)


app=FastAPI(title='Turtle buoyancy workbench',lifespan=lifespan)


@app.middleware('http')
async def local_limits(request, call_next):
    if int(request.headers.get('content-length','0'))>25_000_000:
        return JSONResponse({'detail':'Request too large (25 MB limit)'},status_code=413)
    # This is a local desktop tool; reject cross-origin mutation requests.
    origin=request.headers.get('origin')
    if request.method not in ('GET','HEAD') and origin and origin!=str(request.base_url).rstrip('/'):
        return JSONResponse({'detail':'Use this workbench’s own browser tab'},status_code=403)
    return await call_next(request)


@app.get('/api/geometry')
def geometry():
    try: return {'ready':True,**manifest()}
    except ValueError as e: return {'ready':False,'message':str(e)}


@app.get('/api/mesh/{component}')
def mesh(component:str):
    if component not in COMPONENTS and component!=SAND_BALLAST: raise HTTPException(404)
    try: manifest()
    except ValueError as e: raise HTTPException(409,str(e)) from e
    return FileResponse(GENERATED/f'{component}.json')


@app.get('/api/config')
def configuration():
    p=DATA/'current.yaml'
    return yaml.safe_load(p.read_text()) if p.exists() else yaml.safe_load((ROOT/'physics/components.yaml').read_text())


@app.post('/api/import')
async def import_config(request:Request):
    try:
        data=yaml.safe_load(await request.body())
        return Configuration.model_validate(data).model_dump(mode='json')
    except Exception as e:
        raise HTTPException(422,str(e)) from e


@app.post('/api/validate')
def validate(config:Configuration):
    try: return {'missing':missing(config,manifest())}
    except ValueError as e: return {'missing':[str(e)]}


@app.put('/api/config')
def save_config(config:Configuration):
    DATA.mkdir(parents=True,exist_ok=True)
    tmp=DATA/'current.tmp'
    tmp.write_text(yaml.safe_dump(config.model_dump(mode='json'),sort_keys=False))
    tmp.replace(DATA/'current.yaml')
    return {'status':'saved'}


@app.post('/api/mesh-upload/{component}')
async def upload_mesh(component:str,request:Request):
    if component not in COMPONENTS: raise HTTPException(404)
    body=await request.body()
    if len(body)>25_000_000: raise HTTPException(413,'Mesh is too large')
    target=DATA/'meshes'/f'{uuid.uuid4().hex}.stl'
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(body)
    try: load_mesh(target,component)
    except Exception as e:
        target.unlink(missing_ok=True)
        raise HTTPException(422,str(e)) from e
    return {'id':target.name,'units':'m','frame':'body coordinates; +X forward, +Y port, +Z up'}


async def run_job(job_id, function, *args):
    try:
        result=await asyncio.get_running_loop().run_in_executor(app.state.pool,function,*args)
        JOBS[job_id]={'status':'complete','result':result}
        if function is calculate or function is run_sailing:
            (DATA/'runs').mkdir(exist_ok=True)
            prefix='sail_' if function is run_sailing else ''
            (DATA/'runs'/f'{prefix}{job_id}.json').write_text(json.dumps(result,indent=2,allow_nan=False))
    except MemoryError:
        JOBS[job_id]={'status':'failed','message':MEMORY_MESSAGE}
    except BrokenProcessPool:
        # Native code (e.g. Manifold) can abort the worker on allocation failure
        # instead of raising. Replace the dead pool so later jobs still run.
        app.state.pool=new_pool()
        JOBS[job_id]={'status':'failed','message':'The calculation worker stopped unexpectedly, most likely by '
                      'exceeding its memory allowance. '+MEMORY_MESSAGE}
    except Exception as e:
        JOBS[job_id]={'status':'failed','message':str(e)}
    finally:
        if function is export_job: app.state.exporting=False


def submit(function,*args):
    if any(j['status']=='running' for j in JOBS.values()):
        raise HTTPException(409,'A calculation or CAD export is already running; wait for it to finish')
    # Bound in-memory history; full calculation results remain in data/runs.
    while len(JOBS)>=20: JOBS.pop(next(iter(JOBS)))
    key=uuid.uuid4().hex
    JOBS[key]={'status':'running'}
    asyncio.create_task(run_job(key,function,*args))
    return {'job_id':key}


@app.post('/api/export')
async def export():
    job=submit(export_job)
    app.state.exporting=True
    return job


@app.post('/api/solve')
async def solve(config:Configuration):
    try: m=manifest()
    except ValueError as e: raise HTTPException(409,str(e)) from e
    errors=missing(config,m)
    if errors: raise HTTPException(422,errors)
    return submit(calculate,config.model_dump(mode='json'),m)


@app.get('/api/scenarios')
def scenarios():
    try: return list_scenarios()
    except Exception as e: raise HTTPException(500,f'A scenario file is invalid: {e}') from e


@app.get('/api/hydrodynamics')
def hydrodynamics():
    try: h=load_coefficients()
    except Exception as e: raise HTTPException(422,f'Coefficient file is invalid: {e}') from e
    return {**h.model_dump(mode='json'),'placeholders':h.placeholders()}


@app.post('/api/sail/run')
async def sail_run(request:SailRequest):
    try: m=manifest()
    except ValueError as e: raise HTTPException(409,str(e)) from e
    errors=missing(request.configuration,m)
    if errors: raise HTTPException(422,errors)
    try: coefficients=load_coefficients().model_dump(mode='json')
    except Exception as e: raise HTTPException(422,f'Coefficient file is invalid: {e}') from e
    return submit(run_sailing,request.configuration.model_dump(mode='json'),m,
                  request.scenario.model_dump(mode='json'),coefficients)


@app.get('/api/jobs/{key}')
def job(key:str):
    if key not in JOBS: raise HTTPException(404,'Job no longer available')
    return JOBS[key]


@app.get('/api/config.yaml')
def download_config():
    p=DATA/'current.yaml'
    return FileResponse(p if p.exists() else ROOT/'physics/components.yaml',filename='components.yaml')


@app.get('/measurement-guide')
def guide():
    return FileResponse(ROOT/'docs/buoyancy_measurements.md',media_type='text/plain')


@app.get('/turtle_sprite.svg')
def turtle_sprite():
    # Overhead turtle drawing (groups turtle_body + turtle_sail_system); kept
    # in sim/ as the editable source, not copied into sim/web.
    return FileResponse(ROOT/'sim/turtle_sprite.svg',media_type='image/svg+xml',
                        headers={'Cache-Control':'no-cache'})


class WebFiles(StaticFiles):
    """The UI files, revalidated on every load. Without this a browser can
    heuristically cache an old style.css next to a new app.js after an update."""
    async def get_response(self, path, scope):
        response=await super().get_response(path, scope)
        response.headers['Cache-Control']='no-cache'
        return response


app.mount('/',WebFiles(directory=ROOT/'sim/web',html=True),name='web')
