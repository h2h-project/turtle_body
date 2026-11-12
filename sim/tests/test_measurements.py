import copy
import json
import yaml
import numpy as np
import pytest
import trimesh
from pydantic import ValidationError
from turtle_sim.config import Configuration,Component,missing,build_model,shell,calculate
from turtle_sim.geometry import ROOT,COMPONENTS


def template():
    return Configuration.model_validate(yaml.safe_load((ROOT/'physics/components.yaml').read_text()))


def inventory():
    return {'fingerprint':'test','components':[{'id':k,'kind':kind,'centroid_m':[0,0,0],'mesh':k+'.stl'} for k,(_,kind) in COMPONENTS.items()],'rulers':[]}


def test_no_unmeasured_demo_predictions():
    c=template();errors=missing(c,inventory())
    assert any('density' in e for e in errors)
    assert any('measured mass' in e for e in errors)
    assert all(p.mass_kg is None for p in c.components)
    with pytest.raises(ValueError,match='mass'):build_model(c,inventory())


def test_duplicate_group_and_nonuniform_centre_rejected():
    c=template();c.components.append(c.components[0].model_copy())
    c.components[0].com_source='cad_uniform'
    errors=missing(c,inventory())
    assert any('Duplicate' in e for e in errors)
    assert any('not uniform' in e for e in errors)


def test_flooded_control_housing_requires_actual_walls():
    c=template();housing=next(p for p in c.components if p.id=='control_housing')
    housing.displacement='flooded';housing.uniform_shell_mm=.5
    assert any('solid-wall mesh' in e for e in missing(c,inventory()))


def test_uniform_shell_retains_material_not_air():
    m=trimesh.creation.box(extents=[.1,.1,.1])
    s=shell(m,1)
    assert s.is_volume
    assert s.volume==pytest.approx(.1**3-.098**3,rel=.01)


def test_payloads_and_measured_group_not_counted_twice(tmp_path,monkeypatch):
    import turtle_sim.config as module
    c=template();c.dimensions_checked=True;c.density_kg_m3=1000
    for p in c.components:p.installed=False
    box=trimesh.creation.box(extents=[.2,.2,.2]);box.export(tmp_path/'front_fin.stl')
    fin=next(p for p in c.components if p.id=='front_fin')
    fin.installed=True;fin.mass_kg=2;fin.displacement='solid';fin.geometry_confirmed=True
    c.payloads=[module.Payload(id='battery',mass_kg=2,com_m=(0,0,-.06),notes='inside front fin test envelope')]
    monkeypatch.setattr(module,'GENERATED',tmp_path)
    model=build_model(c,inventory())
    assert model.mass==4
    assert model.com==pytest.approx([0,0,-.03])
    assert model.obj.volume()==pytest.approx(.008)
    fin.offset_m=(.1,0,0)
    assert build_model(c,inventory()).com==pytest.approx([.05,0,-.03])


def test_nonfinite_and_unknown_fields_rejected():
    data=template().model_dump()
    data['density_kg_m3']=float('nan')
    with pytest.raises(ValidationError):Configuration.model_validate(data)
    with pytest.raises(ValidationError):Configuration.model_validate({**template().model_dump(),'mystery':42})


def test_observation_filter_and_signed_residual(monkeypatch,tmp_path):
    import turtle_sim.config as module
    c=template();c.dimensions_checked=True;c.density_kg_m3=1000;c.name='A'
    for p in c.components:p.installed=False
    fin=next(p for p in c.components if p.id=='front_fin')
    fin.installed=True;fin.mass_kg=4;fin.com_source='measured';fin.com_m=(0,0,-.06)
    fin.geometry_confirmed=True;fin.displacement='solid'
    trimesh.creation.box(extents=[.2,.2,.2]).export(tmp_path/'front_fin.stl')
    m=inventory();m['rulers']=[{'id':'front_port','fin':'front','zero_m':[.08,.006,0],'direction':[0,0,1],'range_mm':[-100,100]}]
    c.observations=[module.Observation(id='same',configuration='A',water_density_kg_m3=1000,readings_mm={'front_port':2}),
                    module.Observation(id='other',configuration='B',water_density_kg_m3=1000)]
    monkeypatch.setattr(module,'GENERATED',tmp_path)
    result=calculate(c.model_dump(),m)
    assert len(result['comparisons'])==1
    assert result['comparisons'][0]['residuals_mm']['front_port']==pytest.approx(-2,abs=.01)


def test_reference_density_is_not_mislabeled_as_measurement():
    c=template();c.density_kg_m3=1010;c.density_source='freshwater_reference'
    assert any('Density differs' in e for e in missing(c,inventory()))
