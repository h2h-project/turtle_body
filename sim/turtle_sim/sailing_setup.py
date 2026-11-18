"""Stage 3 inputs (scenario, hydrodynamic coefficients) and the vessel builder.

Builds a `core.sailing.Vessel` from the measured configuration, the CAD export
and the stage-2 equilibrium, then runs a scenario. Runs in the worker process.
"""
from pathlib import Path
from typing import Literal
import json
import math
import os
import numpy as np
import yaml
from pydantic import BaseModel, ConfigDict, Field, FiniteFloat, model_validator
from turtle_sim.geometry import ROOT, GENERATED, load_mesh
from turtle_sim.config import Configuration, build_model
from turtle_sim.core.hydrostatics import rotation
from turtle_sim.core import sailing
from turtle_sim.core.sail_geometry import clip_triangles, plate_from_triangles, bluff_table

SCENARIOS = ROOT / 'sim/scenarios'
COEFFICIENTS = ROOT / 'physics/hydrodynamics.yaml'
FINS = {'front_fin': 'Front fin', 'rear_fin': 'Rear fin'}


class Strict(BaseModel):
    model_config = ConfigDict(extra='forbid')


class Coef(Strict):
    value: FiniteFloat
    source: Literal['placeholder', 'literature', 'calibrated', 'measured', 'user']
    note: str = ''


class Hydrodynamics(Strict):
    schema_version: Literal[1] = 1
    air_density_kg_m3: Coef
    plate_stall_deg: Coef
    plate_stall_width_deg: Coef
    plate_cd0: Coef
    plate_cn_max: Coef
    sail_lift_factor: Coef
    fin_lift_factor: Coef
    hull_cd_water: Coef
    hull_cd_air: Coef
    added_mass_translation_k: Coef
    added_mass_yaw_k: Coef
    servo_travel_deg: Coef
    servo_zero_pos: Coef
    servo_rate_deg_s: Coef
    notes: str = ''

    @model_validator(mode='after')
    def ranges(self):
        limits = {'air_density_kg_m3': (0.5, 2), 'plate_stall_deg': (2, 45), 'plate_stall_width_deg': (0.5, 15),
                  'plate_cd0': (0, 0.5), 'plate_cn_max': (0.3, 2.5), 'sail_lift_factor': (0, 2),
                  'fin_lift_factor': (0, 2), 'hull_cd_water': (0, 3), 'hull_cd_air': (0, 3),
                  'added_mass_translation_k': (0, 3), 'added_mass_yaw_k': (0, 3),
                  'servo_travel_deg': (10, 360), 'servo_zero_pos': (0, 180), 'servo_rate_deg_s': (1, 3000)}
        for name, (lo, hi) in limits.items():
            v = getattr(self, name).value
            if not lo <= v <= hi:
                raise ValueError(f'{name} = {v} is outside {lo}..{hi}')
        return self

    def placeholders(self):
        return [k for k, v in self if isinstance(v, Coef) and v.source == 'placeholder']


class Step(Strict):
    t_s: FiniteFloat = Field(ge=0)
    servo_pos: FiniteFloat = Field(ge=0, le=180)


class Scenario(Strict):
    schema_version: Literal[1] = 1
    id: str = ''
    name: str
    description: str = ''
    duration_s: FiniteFloat = Field(gt=0, le=3600)
    dt_s: FiniteFloat = Field(default=0.5, ge=0.05, le=10)
    # Defaults: bow north, wind from the south (blowing north), current from the north.
    heading_deg: FiniteFloat = Field(default=0, ge=0, lt=360)
    initial_speed_mps: FiniteFloat = Field(default=0, ge=0, le=5)
    wind_from_deg: FiniteFloat = Field(default=180, ge=0, lt=360)
    wind_speed_mps: FiniteFloat = Field(default=0, ge=0, le=30)
    current_from_deg: FiniteFloat = Field(default=0, ge=0, lt=360)
    current_speed_mps: FiniteFloat = Field(default=0, ge=0, le=5)
    # Optional destination: compass bearing + distance from the start; 0 m = none.
    destination_bearing_deg: FiniteFloat = Field(default=0, ge=0, lt=360)
    destination_distance_m: FiniteFloat = Field(default=0, ge=0, le=10000)
    arrival_radius_m: FiniteFloat = Field(default=20, gt=0, le=1000)
    # End the trip at the first sample inside the arrival circle.
    stop_at_destination: bool = False
    servo_schedule: list[Step] = Field(min_length=1)

    @model_validator(mode='after')
    def schedule(self):
        times = [s.t_s for s in self.servo_schedule]
        if times[0] != 0:
            raise ValueError('servo_schedule must start at t_s = 0')
        if any(b <= a for a, b in zip(times, times[1:])):
            raise ValueError('servo_schedule times must increase strictly')
        if self.duration_s / self.dt_s > 20000:
            raise ValueError('Too many output samples; increase dt_s or shorten the run')
        return self


def highlight_faces(component, name):
    """Face indices the CAD export tagged (e.g. 'sail' on sail_unit).

    The display JSON and the .npz are written from the same mesh, so the
    indices address the .npz faces. (Kept out of geometry.py, whose source is
    part of the CAD fingerprint.)
    """
    data = json.loads((GENERATED / f'{component}.json').read_text())
    return np.asarray(data.get('highlights', {}).get(name, []), dtype=np.int64)


def data_dir():
    return Path(os.environ.get('TURTLE_SIM_DATA', str(ROOT / 'sim/data')))


def load_coefficients():
    """The user's copy in sim/data if present, else the distributed template."""
    p = data_dir() / 'hydrodynamics.yaml'
    return Hydrodynamics.model_validate(yaml.safe_load((p if p.exists() else COEFFICIENTS).read_text()))


def list_scenarios():
    out = []
    for p in sorted(SCENARIOS.glob('*.yaml')):
        s = Scenario.model_validate(yaml.safe_load(p.read_text()))
        out.append({**s.model_dump(mode='json'), 'id': p.stem})
    return out


def coefficients(h: Hydrodynamics, water_density):
    return sailing.Coefficients(
        air_density=h.air_density_kg_m3.value, water_density=water_density,
        stall_deg=h.plate_stall_deg.value, stall_width_deg=h.plate_stall_width_deg.value,
        plate_cd0=h.plate_cd0.value, plate_cn_max=h.plate_cn_max.value,
        hull_cd_water=h.hull_cd_water.value, hull_cd_air=h.hull_cd_air.value,
        servo_travel_deg=h.servo_travel_deg.value, servo_zero_pos=h.servo_zero_pos.value,
        servo_rate_deg_s=h.servo_rate_deg_s.value)


_CACHE = {}


def build_vessel(config: Configuration, manifest, h: Hydrodynamics):
    """Vessel geometry + mass properties on the stage-2 selected equilibrium.

    Cached per (configuration, CAD fingerprint, added-mass/lift factors) in the
    worker process: the equilibrium solve and silhouette tables take ~1 min.
    """
    key = json.dumps([config.model_dump(mode='json'), manifest['fingerprint'],
                      h.added_mass_translation_k.value, h.added_mass_yaw_k.value,
                      h.sail_lift_factor.value, h.fin_lift_factor.value], sort_keys=True)
    if key in _CACHE:
        return _CACHE[key]
    hydro = build_model(config, manifest)
    result = hydro.solve()
    if result['status'] != 'equilibrium':
        raise ValueError(f"No calm-water equilibrium to sail from ({result['status']}); fix flotation first.")
    eq = result['equilibria'][result['selected']]
    R = rotation(math.radians(eq['roll_deg']), math.radians(eq['pitch_deg']))
    heave = eq['heave_m']
    cg = np.asarray(eq['centre_mass_m'])
    roll_slope = next(c['slope_nm_per_rad'] for c in eq['stability'] if c['axis'] == 'roll')

    parts = {c['id']: c for c in manifest['components']}
    water, air, fixed, sails = [], [], [], []
    izz = 0.0
    for c in config.components:
        if not c.installed:
            continue
        mesh = load_mesh(GENERATED / parts[c.id]['mesh'], c.id)
        mesh.apply_translation(c.offset_m)
        # Mass distribution (body frame; the few degrees of heel are ignored for inertia).
        centre = np.array(parts[c.id]['centroid_m'] if c.com_source == 'cad_uniform' else c.com_m) + c.offset_m
        body_cg = hydro.com
        izz += c.mass_kg * ((centre[0] - body_cg[0]) ** 2 + (centre[1] - body_cg[1]) ** 2)
        if mesh.volume > 0:
            izz += c.mass_kg / mesh.volume * float(mesh.moment_inertia[2, 2])
        tri_body = mesh.vertices[mesh.faces]
        mask = np.ones(len(tri_body), bool)
        if c.id == 'sail_unit':
            idx = highlight_faces('sail_unit', 'sail')
            if not len(idx):
                raise ValueError('The CAD export has no tagged sail faces; export CAD again.')
            mask[idx] = False
            sail_tri = tri_body[idx]
            for sign, side in ((1, 'port'), (-1, 'starboard')):
                pick = np.sign(sail_tri.mean(1)[:, 1]) == sign
                plate = plate_from_triangles(f'Sail ({side})', 'air', sail_tri[pick], np.array([1., 0, 0]))
                if plate:
                    plate.lift_factor = h.sail_lift_factor.value
                    sails.append(plate)
        tri = tri_body[mask] @ R.T + [0, 0, heave]
        below = clip_triangles(tri, keep_below=True)
        above = clip_triangles(tri, keep_below=False)
        air.append(above)
        if c.id in FINS:
            plate = plate_from_triangles(FINS[c.id], 'water', below, R @ np.array([0., 1, 0]))
            if plate:
                plate.lift_factor = h.fin_lift_factor.value
                fixed.append(plate)
        else:
            water.append(below)
    for p in config.payloads:
        izz += p.mass_kg * ((p.com_m[0] - hydro.com[0]) ** 2 + (p.com_m[1] - hydro.com[1]) ** 2)
    if not sails:
        raise ValueError('No sail is installed; stage 3 needs the sail unit.')
    v_sub = float(eq['volume_m3'])
    rho = config.density_kg_m3
    vessel = sailing.Vessel(
        mass=hydro.mass, izz=izz,
        added_mass=h.added_mass_translation_k.value * rho * v_sub,
        added_izz=h.added_mass_yaw_k.value * izz,
        cg=cg, R=R, heave=heave, fixed_plates=fixed, sail_plates=sails,
        tables={'water': bluff_table('water', np.concatenate(water), cg),
                'air': bluff_table('air', np.concatenate(air), cg)},
        roll_slope_nm_per_rad=roll_slope)
    summary = {
        'equilibrium': {k: eq[k] for k in ('heave_m', 'roll_deg', 'pitch_deg', 'stable')},
        'mass_kg': vessel.mass, 'izz_kg_m2': izz, 'added_mass_kg': vessel.added_mass,
        'added_izz_kg_m2': vessel.added_izz, 'roll_slope_nm_per_rad': roll_slope,
        'plates': [{'name': p.name, 'medium': p.medium, 'area_m2': p.area, 'aspect': p.aspect,
                    'centre_m': list(map(float, p.centre))} for p in sails + fixed],
        'projected_area_m2': {m: {'head_on': float(t.at(180)[0]), 'beam': float(t.at(90)[0])}
                              for m, t in vessel.tables.items()},
    }
    while len(_CACHE) >= 4:
        _CACHE.pop(next(iter(_CACHE)))
    _CACHE[key] = (vessel, summary, eq)
    return _CACHE[key]


def run_sailing(config_dict, manifest, scenario_dict, coefficient_dict=None):
    config = Configuration.model_validate(config_dict)
    scenario = Scenario.model_validate(scenario_dict)
    h = Hydrodynamics.model_validate(coefficient_dict) if coefficient_dict else load_coefficients()
    vessel, summary, eq = build_vessel(config, manifest, h)
    co = coefficients(h, config.density_kg_m3)
    run = sailing.simulate(vessel, co, scenario.model_dump(mode='json'))
    warnings = []
    placeholders = h.placeholders()
    if placeholders:
        warnings.append(f'{len(placeholders)} force coefficients are placeholders, so speeds and turning '
                        'rates are not calibrated. Stage 4 trials calibrate them.')
    if not eq['stable']:
        warnings.append('The float pose this run sails from is not locally stable.')
    if not config.observations:
        warnings.append('The float pose has not been validated against ruler readings yet.')
    estimated = [c.id for c in config.components if c.installed and 'estimat' in c.notes.lower()]
    if estimated:
        warnings.append('Estimated (not measured) inputs noted for: ' + ', '.join(estimated) + '.')
    heel = [abs(v) for v in run['samples']['heel_estimate_deg'] if v is not None]
    if heel and max(heel) > 10:
        warnings.append(f'Estimated heel reaches {max(heel):.0f}°. This model holds the float pose fixed, '
                        'so results at this heel are doubtful.')
    warnings.append('Ballast fin is modelled as drag only (no lift); sail-frame windage does not rotate with the sail.')
    run.update({'kind': 'sailing', 'scenario': scenario.model_dump(mode='json'),
                'coefficients': h.model_dump(mode='json'), 'model': summary,
                'configuration_name': config.name, 'cad_fingerprint': manifest['fingerprint'],
                'conventions': {'heading': 'compass degrees true, 0 = north, clockwise',
                                'wind_from_deg / current_from_deg': 'direction the wind or water comes FROM',
                                'destination': 'compass bearing + distance from the start',
                                'world': 'x east, y north (m), start at the origin',
                                'sail_deg': '0 = sail square across the hull (CAD pose); + = counter-clockwise seen from above',
                                'servo_cmd': 'contract servo_pos, 0..180 over the full servo travel',
                                'apparent_wind_from_deg': 'relative to the bow, + = from port',
                                'heel_estimate_deg': 'quasi-static, + raises port; diagnostic only'},
                'warnings': warnings})
    return run
