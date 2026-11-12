"""Validated measurement inputs, mass accounting and displacement policy."""
from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, FiniteFloat
import numpy as np
import trimesh
import manifold3d as md
from turtle_sim.geometry import COMPONENTS, GENERATED, load_mesh, valid_mesh
from turtle_sim.core.hydrostatics import Hydrostatics, as_manifold, as_trimesh

Vec3=tuple[FiniteFloat,FiniteFloat,FiniteFloat]

class Strict(BaseModel):
    model_config=ConfigDict(extra='forbid')

class Component(Strict):
    id: str
    installed: bool = True
    mass_kg: FiniteFloat | None = Field(default=None,ge=0)
    com_source: Literal['measured','cad_uniform'] = 'measured'
    com_m: Vec3 | None = None
    displacement: Literal['unknown','solid','sealed','flooded','contained'] = 'unknown'
    geometry_confirmed: bool = False
    uniform_shell_mm: FiniteFloat | None = Field(default=None,gt=0)
    displacement_mesh: str | None = None
    offset_m: Vec3 = (0,0,0)
    notes: str = ''

class Payload(Strict):
    id: str
    mass_kg: FiniteFloat | None = Field(default=None,gt=0)
    com_m: Vec3 | None = None
    displacement: Literal['contained','box'] = 'contained'
    size_m: Vec3 | None = None
    notes: str = ''

class Observation(Strict):
    id: str
    purpose: Literal['calibration','validation']='validation'
    configuration: str
    timestamp: str = ''
    water_density_kg_m3: FiniteFloat | None = Field(default=None,gt=0)
    readings_mm: dict[Literal['front_port','front_starboard','rear_port','rear_starboard'],FiniteFloat|None] = {}
    uncertainty_mm: FiniteFloat = Field(default=1,gt=0)
    roll_deg: FiniteFloat | None = None
    added_mass_kg: FiniteFloat | None = Field(default=None,ge=0)
    added_mass_position_m: Vec3 | None = None
    notes: str = ''

class Configuration(Strict):
    schema_version: Literal[1] = 1
    name: str = 'My turtle'
    density_kg_m3: FiniteFloat | None = Field(default=None,gt=0)
    density_source: Literal['measured','freshwater_reference','seawater_reference'] = 'freshwater_reference'
    assembled_mass_kg: FiniteFloat | None = Field(default=None,gt=0)
    dimensions_checked: bool = False
    bottle_dimensions_mm: dict[str,FiniteFloat|None] = {}
    components: list[Component]
    payloads: list[Payload] = []
    observations: list[Observation] = []
    notes: str = ''


def missing(config, manifest):
    errors=[]
    if config.density_kg_m3 is None: errors.append('Select or measure water density')
    reference={'freshwater_reference':1000,'seawater_reference':1025}.get(config.density_source)
    if config.density_kg_m3 is not None and reference is not None and config.density_kg_m3 != reference:
        errors.append('Density differs from its selected reference; mark it as measured or select the reference again')
    if not config.dimensions_checked: errors.append('Verify the physical build and bottle dimensions against CAD')
    ids=[c.id for c in config.components]
    expected={c['id'] for c in manifest['components']}
    if len(ids)!=len(set(ids)): errors.append('Duplicate component IDs would count mass twice')
    if set(ids)!=expected: errors.append('Component inventory differs from the current CAD export; reload the inventory')
    if len({p.id for p in config.payloads})!=len(config.payloads) or any(p.id in ids for p in config.payloads):
        errors.append('Payload IDs must be unique and distinct from CAD components')
    for c in config.components:
        if not c.installed: continue
        prefix=COMPONENTS.get(c.id,(c.id,''))[0]
        if c.mass_kg is None: errors.append(f'{prefix}: measured mass required')
        if c.com_source=='cad_uniform' and COMPONENTS.get(c.id,('',None))[1]!='uniform':
            errors.append(f'{prefix}: measure a balance point; this group is not uniform')
        if c.com_source=='measured' and c.com_m is None:
            errors.append(f'{prefix}: measured centre of mass required')
        if not c.geometry_confirmed: errors.append(f'{prefix}: confirm displacement geometry and sealed/flooded status')
        if c.displacement=='unknown': errors.append(f'{prefix}: select displacement treatment')
        if c.displacement=='contained' and not c.notes.strip(): errors.append(f'{prefix}: identify the enclosing displaced component in notes')
        if c.displacement=='sealed' and COMPONENTS.get(c.id,('',None))[1] not in ('bottle','housing'):
            errors.append(f'{prefix}: sealed treatment is only for bottles/housings')
        if COMPONENTS.get(c.id,('',None))[1] in ('bottle','housing') and c.displacement=='solid':
            errors.append(f'{prefix}: choose sealed or flooded, not solid')
        if c.displacement=='flooded' and not c.displacement_mesh:
            if not c.uniform_shell_mm or COMPONENTS.get(c.id,('',None))[1]!='bottle':
                errors.append(f'{prefix}: flooded cavity needs an uploaded solid-wall mesh (ordinary bottles may use a measured uniform shell thickness)')
    for p in config.payloads:
        if p.mass_kg is None: errors.append(f'{p.id}: measured load mass required')
        if p.com_m is None: errors.append(f'{p.id}: measured load centre required')
        if p.displacement=='box' and (p.size_m is None or min(p.size_m)<=0):
            errors.append(f'{p.id}: immersed box needs three positive measured dimensions')
        if p.displacement=='contained' and not p.notes.strip():
            errors.append(f'{p.id}: identify its enclosing displaced component in notes')
    return errors


def shell(mesh, thickness_mm):
    obj=as_manifold(mesh)
    # Explicit uniform-wall model; all closure walls have this thickness too.
    inner=obj.minkowski_difference(md.Manifold.sphere(thickness_mm/1000,8))
    if inner.is_empty():
        raise ValueError('Uniform shell thickness removes the entire bottle interior')
    return valid_mesh(as_trimesh(obj-inner),'Flooded uniform shell')


def build_model(config, manifest):
    issues=missing(config,manifest)
    if issues: raise ValueError('\n'.join(issues))
    data={c['id']:c for c in manifest['components']}
    total=0.; weighted=np.zeros(3); meshes=[]
    for c in config.components:
        if not c.installed: continue
        part=data[c.id]
        center=np.array(part['centroid_m'] if c.com_source=='cad_uniform' else c.com_m)+c.offset_m
        total+=c.mass_kg; weighted+=c.mass_kg*center
        if c.displacement=='contained': continue
        if c.displacement_mesh:
            # Only server-issued upload IDs, never arbitrary paths.
            import re
            if not re.fullmatch(r'[a-f0-9]{32}\.stl',c.displacement_mesh):
                raise ValueError(f'{c.id}: invalid displacement upload ID')
            from turtle_sim.geometry import ROOT
            import os
            from pathlib import Path
            mesh=load_mesh(Path(os.environ.get('TURTLE_SIM_DATA', str(ROOT/'sim/data')))/'meshes'/c.displacement_mesh,c.id)
        else:
            mesh=load_mesh(GENERATED/part['mesh'],c.id)
            if c.displacement=='flooded': mesh=shell(mesh,c.uniform_shell_mm)
        mesh.apply_translation(c.offset_m)
        meshes.append(mesh)
    for p in config.payloads:
        total+=p.mass_kg;weighted+=p.mass_kg*np.array(p.com_m)
        if p.displacement=='box':
            mesh=trimesh.creation.box(extents=p.size_m)
            mesh.apply_translation(p.com_m);meshes.append(mesh)
    if total<=0: raise ValueError('Total measured mass must be positive')
    return Hydrostatics(meshes,total,weighted/total,config.density_kg_m3)


def calculate(config_dict, manifest):
    config=Configuration.model_validate(config_dict)
    model=build_model(config,manifest)
    rulers=[]
    for r in manifest['rulers']:
        fin_id='front_fin' if r['fin']=='front' else 'rear_fin'
        c=next(c for c in config.components if c.id==fin_id)
        if c.installed:
            rulers.append({**r,'zero_m':(np.array(r['zero_m'])+c.offset_m).tolist()})
    result=model.solve(rulers)
    result['configuration']=config.model_dump(mode='json')
    result['cad_fingerprint']=manifest['fingerprint']
    result['warnings']=[]
    if config.assembled_mass_kg:
        result['assembled_mass_difference_kg']=model.mass-config.assembled_mass_kg
        if abs(model.mass-config.assembled_mass_kg)>0.01*config.assembled_mass_kg:
            result['warnings'].append('Component total differs from independent assembled mass by more than 1%; check missing or double-counted equipment.')
    if result['status']=='equilibrium':
        predicted={r['id']:r for r in result['equilibria'][result['selected']]['rulers']}
        comparisons=[]
        for obs in config.observations:
            # A historical observation must not silently validate today's loading.
            if obs.configuration!=config.name or obs.water_density_kg_m3 is None or not np.isclose(obs.water_density_kg_m3,config.density_kg_m3):
                continue
            comparisons.append({'id':obs.id,'purpose':obs.purpose,'uncertainty_mm':obs.uncertainty_mm,
                'residuals_mm':{key:predicted[key]['reading_mm']-value
                    for key,value in obs.readings_mm.items() if key in predicted and value is not None and predicted[key]['in_range']}})
        result['comparisons']=comparisons
    return result
