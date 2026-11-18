"""Stage 3 sailing engine against synthetic shapes with known answers.

These check equations, conventions and numerics. They say nothing about how
the real turtle sails; that needs recorded trials (roadmap stage 4).
"""
import math
import numpy as np
import pytest
import trimesh
import yaml
from pydantic import ValidationError
from turtle_sim.core import sailing
from turtle_sim.core.sailing import Plate, Vessel, Coefficients, plate_force, simulate
from turtle_sim.core.sail_geometry import bluff_table, clip_triangles, plate_from_triangles
from turtle_sim.sailing_setup import Hydrodynamics, Scenario, COEFFICIENTS, list_scenarios


def box_tri(extents, centre=(0, 0, 0)):
    m = trimesh.creation.box(extents=extents)
    m.apply_translation(centre)
    return m.vertices[m.faces]


def scenario(**kw):
    base = dict(name='t', duration_s=60, dt_s=0.5, heading_deg=0, wind_from_deg=0, wind_speed_mps=0,
                current_from_deg=0, current_speed_mps=0, servo_schedule=[{'t_s': 0, 'servo_pos': 90}])
    base.update(kw)
    return Scenario.model_validate(base).model_dump(mode='json')


def vessel(sail=True, fins=(), air_table=True, mass=10.0):
    """Symmetric test turtle: a submerged box hull, optional box windage, two sail plates."""
    cg = np.zeros(3)
    tables = {'water': bluff_table('water', box_tri([0.4, 0.3, 0.2], (0, 0, -0.1)), cg)}
    if air_table:
        tables['air'] = bluff_table('air', box_tri([0.2, 0.2, 0.1], (0, 0, 0.05)), cg)
    sails = [Plate('s+', 'air', 0.03, 0.7, np.array([0., 0.18, 0.26]), np.array([1., 0, 0])),
             Plate('s-', 'air', 0.03, 0.7, np.array([0., -0.18, 0.26]), np.array([1., 0, 0]))] if sail else []
    return Vessel(mass=mass, izz=0.4, added_mass=5.0, added_izz=0.2, cg=cg, R=np.eye(3), heave=0.0,
                  fixed_plates=list(fins), sail_plates=sails, tables=tables, roll_slope_nm_per_rad=-4.0)


CO = Coefficients()


def test_flat_plate_broadside_edge_on_and_lift_direction():
    rho, area = 1.2, 0.5
    f, alpha = plate_force(np.array([2., 0, 0]), np.array([1., 0, 0]), area, 1.0, rho, CO)
    assert alpha == pytest.approx(90)
    assert f == pytest.approx([0.5 * rho * 4 * area * (CO.plate_cd0 + CO.plate_cn_max), 0, 0], rel=1e-3)
    f, alpha = plate_force(np.array([2., 0, 0]), np.array([0., 1, 0]), area, 1.0, rho, CO)
    assert alpha == pytest.approx(0)
    assert f == pytest.approx([0.5 * rho * 4 * area * CO.plate_cd0, 0, 0], rel=1e-3)
    # Flow along +X, plate tilted so the flow strikes its +n face: lift pushes toward +n's side.
    n = np.array([math.sin(math.radians(5)), math.cos(math.radians(5)), 0])
    f, _ = plate_force(np.array([2., 0, 0]), n, area, 1.0, rho, CO)
    assert f[1] > 0 and f[0] > 0


def test_clip_and_bluff_table_of_a_box():
    tri = box_tri([2, 1, 1])                       # z from -0.5 to 0.5
    below = clip_triangles(tri, keep_below=True)
    area = np.linalg.norm(np.cross(below[:, 1] - below[:, 0], below[:, 2] - below[:, 0]), axis=1).sum() / 2
    assert area == pytest.approx(2 * 1 + 2 * (2 * 0.5) + 2 * (1 * 0.5))   # bottom + half sides (open top)
    table = bluff_table('water', below, [0, 0, 0])
    assert table.at(0)[0] == pytest.approx(0.5)     # flow along X sees 1 x 0.5
    assert table.at(90)[0] == pytest.approx(1.0)    # flow along Y sees 2 x 0.5
    assert table.at(90)[2] == pytest.approx(-0.25)  # silhouette centroid height
    assert table.yaw_moment_m5 == pytest.approx(0.5 * 2 * 0.25, rel=0.01)  # h * 2 * int_0^1 x^3


def test_plate_from_a_thin_slab():
    p = plate_from_triangles('fin', 'water', box_tri([0.4, 0.012, 0.1], (1, 0, -0.05)), np.array([0., 1, 0]))
    assert p.area == pytest.approx(0.04)
    assert p.aspect == pytest.approx(0.25)
    assert p.centre == pytest.approx([1, 0, -0.05])


def test_still_water_stays_put():
    run = simulate(vessel(), CO, scenario())
    s = run['samples']
    assert run['status'] == 'complete'
    assert max(map(abs, s['x_m'] + s['y_m'])) < 1e-9
    assert set(s['heading_deg']) == {0.0}


def test_current_only_drifts_with_the_water():
    run = simulate(vessel(air_table=False), CO, scenario(current_from_deg=270, current_speed_mps=0.3, duration_s=120))
    s = run['samples']
    assert s['sog_mps'][-1] == pytest.approx(0.3, abs=1e-3)
    assert s['stw_mps'][-1] < 1e-3
    assert s['cog_deg'][-1] == pytest.approx(90, abs=0.5)


def test_downwind_square_sail_runs_straight_downwind():
    run = simulate(vessel(), CO, scenario(wind_from_deg=180, wind_speed_mps=4, duration_s=200))
    s = run['samples']
    assert s['y_m'][-1] > 5 and abs(s['x_m'][-1]) < 1e-6
    assert s['heading_deg'][-1] == pytest.approx(0, abs=1e-6)
    # Terminal speed: sail push balances hull drag (+ the windage of the moving body).
    assert s['sog_mps'][-1] == pytest.approx(s['sog_mps'][-20], rel=1e-3)


def test_mirror_sail_angles_give_mirror_tracks():
    a = simulate(vessel(), CO, scenario(wind_from_deg=180, wind_speed_mps=4, duration_s=100,
                                        servo_schedule=[{'t_s': 0, 'servo_pos': 110}]))['samples']
    b = simulate(vessel(), CO, scenario(wind_from_deg=180, wind_speed_mps=4, duration_s=100,
                                        servo_schedule=[{'t_s': 0, 'servo_pos': 70}]))['samples']
    assert np.allclose(a['x_m'], -np.array(b['x_m']), atol=1e-6)
    assert np.allclose(a['y_m'], b['y_m'], atol=1e-6)
    hdg = lambda h: (h + 180) % 360 - 180
    assert np.allclose([hdg(h) for h in a['heading_deg']], [-hdg(h) for h in b['heading_deg']], atol=1e-5)
    assert abs(a['x_m'][-1]) > 0.1  # the turned sail really does push sideways


def test_tail_fin_weathervanes_into_the_wind():
    tail = Plate('tail', 'air', 0.05, 1.0, np.array([-0.5, 0, 0.2]), np.array([0., 1, 0]))
    run = simulate(vessel(sail=False, fins=[tail]), CO,
                   scenario(wind_from_deg=0, wind_speed_mps=5, heading_deg=40, duration_s=300))
    hdg = (run['samples']['heading_deg'][-1] + 180) % 360 - 180
    assert abs(hdg) < 3


def test_servo_rate_limit_end_stop_and_no_direct_heading():
    co = Coefficients(servo_rate_deg_s=90)
    run = simulate(vessel(), co, scenario(duration_s=4, dt_s=0.1,
                                          servo_schedule=[{'t_s': 0, 'servo_pos': 90}, {'t_s': 1, 'servo_pos': 180}]))
    s = run['samples']
    rates = np.diff(s['sail_deg']) / np.diff(s['t_s'])
    assert rates.max() <= 90 + 1e-6
    assert max(s['sail_deg']) <= 135 + 1e-9
    assert s['sail_deg'][-1] == pytest.approx(135, abs=0.5)
    # Moving the sail in still air applies no force: heading and position do not change.
    assert set(s['heading_deg']) == {0.0} and max(map(abs, s['x_m'])) < 1e-12


def test_divergence_is_a_status_not_a_crash():
    # Negative drag feeds energy in: speed grows without bound (quadratic blow-up).
    co = Coefficients(hull_cd_water=-1.0)
    run = simulate(vessel(sail=False, air_table=False), co, scenario(initial_speed_mps=0.5, duration_s=600))
    assert run['status'] == 'diverged'


def test_inputs_validate():
    Hydrodynamics.model_validate(yaml.safe_load(COEFFICIENTS.read_text()))
    assert list_scenarios()
    bad = yaml.safe_load(COEFFICIENTS.read_text())
    bad['plate_stall_deg']['value'] = 80
    with pytest.raises(ValidationError):
        Hydrodynamics.model_validate(bad)
    with pytest.raises(ValidationError):
        scenario(servo_schedule=[{'t_s': 5, 'servo_pos': 90}])
    with pytest.raises(ValidationError):
        scenario(servo_schedule=[{'t_s': 0, 'servo_pos': 90}, {'t_s': 0, 'servo_pos': 100}])
    with pytest.raises(ValidationError):
        scenario(servo_schedule=[{'t_s': 0, 'servo_pos': 200}])


def test_heading_conventions():
    assert sailing.heading_from_psi(sailing.psi_from_heading(37)) == pytest.approx(37)
    assert sailing.compass_vector(90, 2) == pytest.approx([2, 0])   # toward east


def test_destination_closest_approach_and_arrival():
    # Downwind run north; destination 20 m north is reached, one 20 m east is not.
    north = simulate(vessel(), CO, scenario(wind_from_deg=180, wind_speed_mps=4, duration_s=300,
                                            destination_bearing_deg=0, destination_distance_m=20,
                                            arrival_radius_m=5))
    d = north['destination']
    assert d['x_m'] == pytest.approx(0, abs=1e-9) and d['y_m'] == pytest.approx(20)
    assert d['arrived'] and d['arrival_t_s'] is not None and d['closest_m'] < 5
    east = simulate(vessel(), CO, scenario(wind_from_deg=180, wind_speed_mps=4, duration_s=60,
                                           destination_bearing_deg=90, destination_distance_m=20,
                                           arrival_radius_m=5))['destination']
    assert not east['arrived'] and east['arrival_t_s'] is None and east['closest_m'] > 5
    assert simulate(vessel(), CO, scenario())['destination'] is None
    assert scenario(destination_distance_m=50)['arrival_radius_m'] == 20   # default circle
    stop = simulate(vessel(), CO, scenario(wind_from_deg=180, wind_speed_mps=4, duration_s=300,
                                           destination_distance_m=20, arrival_radius_m=5,
                                           stop_at_destination=True))
    assert stop['samples']['t_s'][-1] == stop['destination']['arrival_t_s'] < 300
    assert len(stop['samples']['x_m']) == len(stop['destination']['distance_m'])
    assert stop['destination']['final_m'] <= 5
