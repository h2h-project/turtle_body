import yaml
from fastapi.testclient import TestClient
from turtle_sim.api import app as module
from turtle_sim.geometry import ROOT


def test_missing_measurements_save_load_and_import(tmp_path,monkeypatch):
    monkeypatch.setattr(module,'DATA',tmp_path)
    with TestClient(module.app) as client:
        c=client.get('/api/config').json()
        assert c['density_kg_m3'] is None
        assert client.put('/api/config',json=c).status_code==200
        assert client.get('/api/config').json()==c
        assert client.post('/api/import',content=yaml.safe_dump(c)).json()==c
        assert client.post('/api/import',content='schema_version: 999').status_code==422
        problems=client.post('/api/validate',json=c).json()['missing']
        assert problems
        assert client.post('/api/solve',json=c).status_code in (409,422)
        assert client.get('/api/config.yaml').status_code==200
        assert client.get('/measurement-guide').status_code==200
        assert client.get('/vendor/three.module.js').status_code==200
        assert client.get('/api/mesh/unknown').status_code==404
        assert client.put('/api/config',json=c,headers={'Origin':'https://unrelated.example'}).status_code==403


def test_invalid_mesh_upload_removed(tmp_path,monkeypatch):
    monkeypatch.setattr(module,'DATA',tmp_path)
    with TestClient(module.app) as client:
        assert client.post('/api/mesh-upload/front_fin',content=b'not STL').status_code==422
    assert not list((tmp_path/'meshes').glob('*.stl'))


def test_background_calculation_returns_snapshot(tmp_path,monkeypatch):
    import time
    from turtle_sim.config import Configuration,Component,Payload
    from turtle_sim.geometry import COMPONENTS
    # Synthetic reference shape only; these are not turtle measurements.
    m={'fingerprint':'synthetic-test','components':[{'id':k} for k in COMPONENTS],'rulers':[]}
    monkeypatch.setattr(module,'DATA',tmp_path)
    monkeypatch.setattr(module,'manifest',lambda:m)
    module.JOBS.clear()
    config=Configuration(name='synthetic-box',density_kg_m3=1000,dimensions_checked=True,
        components=[Component(id=k,installed=False) for k in COMPONENTS],
        payloads=[Payload(id='reference-box',mass_kg=4,com_m=(0,0,0),displacement='box',size_m=(.4,.3,.1))])
    with TestClient(module.app) as client:
        response=client.post('/api/solve',json=config.model_dump(mode='json'))
        assert response.status_code==200
        key=response.json()['job_id']
        for _ in range(100):
            job=client.get('/api/jobs/'+key).json()
            if job['status']!='running':break
            time.sleep(.05)
        assert job['status']=='complete',job
        result=job['result']
        assert result['status']=='equilibrium'
        assert result['configuration']['name']=='synthetic-box'
        assert result['cad_fingerprint']=='synthetic-test'
        assert (tmp_path/'runs'/f'{key}.json').exists()
