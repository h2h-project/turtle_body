"""Local API. All numerical work and CAD exports run in an owned worker process."""
from contextlib import asynccontextmanager
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
import asyncio
import os
import json
import sys
import subprocess
import uuid
import yaml
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from turtle_sim.geometry import ROOT, GENERATED, COMPONENTS, manifest, load_mesh
from turtle_sim.config import Configuration, missing, calculate

DATA=Path(os.environ.get('TURTLE_SIM_DATA', str(ROOT/'sim/data')))
JOBS={}


def export_job():
    p=subprocess.run([sys.executable,str(ROOT/'build/export_sim.py')],cwd=ROOT,
                     capture_output=True,text=True,timeout=7200)
    if p.returncode: raise ValueError(p.stderr[-4000:] or p.stdout[-4000:])
    return {'status':'exported','manifest':manifest()}


@asynccontextmanager
async def lifespan(app):
    DATA.mkdir(parents=True,exist_ok=True)
    app.state.pool=ProcessPoolExecutor(max_workers=1)
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
    if component not in COMPONENTS: raise HTTPException(404)
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
        if function is calculate:
            (DATA/'runs').mkdir(exist_ok=True)
            (DATA/'runs'/f'{job_id}.json').write_text(json.dumps(result,indent=2,allow_nan=False))
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


app.mount('/',StaticFiles(directory=ROOT/'sim/web',html=True),name='web')
