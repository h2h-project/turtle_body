"""Stage 3: horizontal sailing and turning on a fixed calm-water float pose.

Three degrees of freedom: position x, y (world ENU: x east, y north) and yaw
psi (angle of body +X from east, counter-clockwise). Heave, roll and pitch stay
at the stage-2 equilibrium. Every force acts at its own point, using the local
relative velocity (v + omega x r), so yaw damping comes from the geometry.

Frames: the *level* frame is the body after the equilibrium heel/trim rotation
R and heave, before yaw; its Z is world up and the water plane is Z = 0. Sail
plates are stored in body coordinates and rotated by the sail angle about the
shaft (body Z through the origin) before R is applied.

The equations are written in the world frame with isotropic added mass, which
is exact for this model in a steady uniform current; the Munk moment is zero for
isotropic added mass and is therefore not represented.

No sensor is emulated here: outputs are the simulator's true state.
"""
from dataclasses import dataclass, field
import math
import numpy as np
from scipy.integrate import solve_ivp


@dataclass
class Plate:
    """A thin lifting surface (sail or fin)."""
    name: str
    medium: str            # 'air' or 'water'
    area: float            # one face, m^2
    aspect: float          # span / chord
    centre: np.ndarray     # level frame (fixed) or body frame (sail)
    normal: np.ndarray     # unit, same frame as centre
    lift_factor: float = 1.0


@dataclass
class BluffTable:
    """Projected area and silhouette centroid vs relative-flow direction.

    angles_deg: flow direction in the level frame (direction the fluid moves
    relative to the body), 0..350 step 10. lateral_m: silhouette centroid offset
    from the CG along perp = (-sin, cos) of the flow direction. height_m:
    silhouette centroid height above the CG.
    """
    medium: str
    angles_deg: np.ndarray
    area_m2: np.ndarray
    lateral_m: np.ndarray
    height_m: np.ndarray
    yaw_moment_m5: float = 0.0   # integral h(x) |x|^3 dx of the side silhouette

    def at(self, angle_deg):
        a = angle_deg % 360.0
        xs = np.r_[self.angles_deg, 360.0]
        def interp(v):
            return float(np.interp(a, xs, np.r_[v, v[0]]))
        return interp(self.area_m2), interp(self.lateral_m), interp(self.height_m)


@dataclass
class Coefficients:
    air_density: float = 1.225
    water_density: float = 1000.0
    stall_deg: float = 15.0
    stall_width_deg: float = 4.0
    plate_cd0: float = 0.02
    plate_cn_max: float = 1.2
    hull_cd_water: float = 1.0
    hull_cd_air: float = 1.0
    servo_travel_deg: float = 270.0
    servo_zero_pos: float = 90.0
    servo_rate_deg_s: float = 300.0
    servo_gain_per_s: float = 10.0

    def density(self, medium):
        return self.air_density if medium == 'air' else self.water_density

    def hull_cd(self, medium):
        return self.hull_cd_air if medium == 'air' else self.hull_cd_water

    def sail_angle(self, servo_pos):
        """Servo command (contract `servo_pos`, 0..180 over the full travel) -> sail degrees."""
        pos = min(max(float(servo_pos), 0.0), 180.0)
        return (pos - self.servo_zero_pos) * self.servo_travel_deg / 180.0

    def sail_limits(self):
        return self.sail_angle(0), self.sail_angle(180)


@dataclass
class Vessel:
    mass: float
    izz: float
    added_mass: float
    added_izz: float
    cg: np.ndarray                     # level frame
    R: np.ndarray                      # body -> level rotation (heel/trim)
    heave: float
    fixed_plates: list = field(default_factory=list)
    sail_plates: list = field(default_factory=list)
    tables: dict = field(default_factory=dict)       # medium -> BluffTable
    roll_slope_nm_per_rad: float | None = None       # stage-2 restoring slope (<0)


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0.], [s, c, 0.], [0., 0., 1.]])


def plate_force(w, normal, area, aspect, rho, co, lift_factor=1.0):
    """Force (3) on a flat plate from fluid velocity `w` relative to the plate.

    Low-angle: thin-plate lift with a finite-span slope 2*pi*AR/(AR+2).
    High-angle: normal-force model CN = cn_max * sin(alpha). A smooth blend
    around the stall angle keeps the ODE right-hand side continuous.
    """
    speed = float(np.linalg.norm(w))
    if speed < 1e-9 or area <= 0:
        return np.zeros(3), 0.0
    wh = w / speed
    cosn = float(wh @ normal)
    alpha = math.asin(min(1.0, abs(cosn)))
    slope = 2 * math.pi * aspect / (aspect + 2) * lift_factor
    blend = 1 / (1 + math.exp(-(alpha - math.radians(co.stall_deg)) / math.radians(co.stall_width_deg)))
    cl_pre = slope * alpha
    cl = (1 - blend) * cl_pre + blend * co.plate_cn_max * math.sin(alpha) * math.cos(alpha)
    cd = ((1 - blend) * (co.plate_cd0 + cl_pre ** 2 / (math.pi * max(aspect, 1e-3)))
          + blend * (co.plate_cd0 + co.plate_cn_max * math.sin(alpha) ** 2))
    q = 0.5 * rho * speed ** 2 * area
    force = q * cd * wh
    perp = normal - cosn * wh
    norm = float(np.linalg.norm(perp))
    if norm > 1e-9:
        force = force + q * cl * math.copysign(1.0, cosn) * perp / norm
    return force, math.degrees(alpha)


def sail_plates_level(vessel, sail_deg):
    """Sail plates moved into the level frame at sail angle `sail_deg`."""
    M = vessel.R @ rot_z(math.radians(sail_deg))
    out = []
    for p in vessel.sail_plates:
        out.append(Plate(p.name, p.medium, p.area, p.aspect,
                         M @ p.centre + [0, 0, vessel.heave], M @ p.normal, p.lift_factor))
    return out


def forces(vessel, co, psi, vel_world, yaw_rate, sail_deg, wind_world, current_world):
    """Net horizontal force (level frame), yaw and roll moments about the CG."""
    Rw = rot_z(-psi)[:2, :2]
    V = Rw @ np.asarray(vel_world, float)
    fluid = {'air': Rw @ np.asarray(wind_world, float), 'water': Rw @ np.asarray(current_world, float)}
    F = np.zeros(3)
    yaw = roll = 0.0
    diag = {'sail_alpha_deg': [], 'sail_force_n': np.zeros(3)}

    def apply(force, point):
        nonlocal F, yaw, roll
        r = point - vessel.cg
        F = F + force
        yaw += r[0] * force[1] - r[1] * force[0]
        roll += r[1] * force[2] - r[2] * force[1]

    def local_flow(medium, point):
        r = point - vessel.cg
        v_point = np.array([V[0] - yaw_rate * r[1], V[1] + yaw_rate * r[0], 0.0])
        f = fluid[medium]
        return np.array([f[0], f[1], 0.0]) - v_point

    for p in vessel.fixed_plates:
        f, _ = plate_force(local_flow(p.medium, p.centre), p.normal, p.area, p.aspect,
                           co.density(p.medium), co, p.lift_factor)
        apply(f, p.centre)
    for p in sail_plates_level(vessel, sail_deg):
        f, alpha = plate_force(local_flow(p.medium, p.centre), p.normal, p.area, p.aspect,
                               co.density(p.medium), co, p.lift_factor)
        apply(f, p.centre)
        diag['sail_alpha_deg'].append(alpha)
        diag['sail_force_n'] = diag['sail_force_n'] + f
    for medium, table in vessel.tables.items():
        w = local_flow(medium, vessel.cg)
        speed = float(np.linalg.norm(w))
        rho, cd = co.density(medium), co.hull_cd(medium)
        if speed > 1e-9:
            angle = math.degrees(math.atan2(w[1], w[0]))
            area, lateral, height = table.at(angle)
            a = math.radians(angle)
            point = vessel.cg + np.array([-math.sin(a) * lateral, math.cos(a) * lateral, height])
            apply(0.5 * rho * cd * area * speed * w, point)
        # Pure-rotation cross-flow drag of the side silhouette (strip theory).
        yaw -= 0.5 * rho * cd * table.yaw_moment_m5 * yaw_rate * abs(yaw_rate)
    rel_air = fluid['air'] - V
    diag['apparent_wind_mps'] = float(np.linalg.norm(rel_air))
    # Direction the apparent wind comes FROM, relative to the bow: 0 ahead, +90 port.
    diag['apparent_wind_from_deg'] = math.degrees(math.atan2(-rel_air[1], -rel_air[0])) if diag['apparent_wind_mps'] > 1e-9 else None
    return F, yaw, roll, diag


def heading_from_psi(psi):
    return (90.0 - math.degrees(psi)) % 360.0


def psi_from_heading(heading_deg):
    return math.radians(90.0 - heading_deg)


def compass_vector(bearing_deg, speed):
    b = math.radians(bearing_deg)
    return np.array([math.sin(b), math.cos(b)]) * speed


def simulate(vessel, co, scenario):
    """Integrate a scenario. `scenario` is a dict (validated upstream).

    State: [x, y, psi, vx, vy, r, sail_deg]. Sail commands go through a
    rate-limited servo model; they change forces, never the heading directly.
    """
    # Both are given as the direction they come FROM (weather-report style).
    wind = -compass_vector(scenario['wind_from_deg'], scenario['wind_speed_mps'])
    current = -compass_vector(scenario['current_from_deg'], scenario['current_speed_mps'])
    psi0 = psi_from_heading(scenario['heading_deg'])
    v0 = current + scenario.get('initial_speed_mps', 0.0) * np.array([math.cos(psi0), math.sin(psi0)])
    schedule = sorted(scenario['servo_schedule'], key=lambda s: s['t_s'])
    lo, hi = co.sail_limits()
    m = vessel.mass + vessel.added_mass
    I = vessel.izz + vessel.added_izz
    duration, dt = float(scenario['duration_s']), float(scenario['dt_s'])

    def rhs(t, s, target):
        F, N, _, _ = forces(vessel, co, s[2], s[3:5], s[5], s[6], wind, current)
        Fw = rot_z(s[2])[:2, :2] @ F[:2]
        rate = max(-co.servo_rate_deg_s, min(co.servo_rate_deg_s, co.servo_gain_per_s * (target - s[6])))
        return [s[3], s[4], s[5], Fw[0] / m, Fw[1] / m, N / I, rate]

    state = np.array([0., 0., psi0, v0[0], v0[1], 0., co.sail_angle(schedule[0]['servo_pos'])])
    times = [0.0]; states = [state.copy()]; commands = [schedule[0]['servo_pos']]
    status, message = 'complete', ''
    edges = [s['t_s'] for s in schedule if 0 < s['t_s'] < duration] + [duration]
    start = 0.0
    for end in edges:
        cmd = [s for s in schedule if s['t_s'] <= start + 1e-9][-1]['servo_pos']
        target = min(max(co.sail_angle(cmd), lo), hi)
        k0 = math.floor(start / dt + 1e-9) + 1
        t_eval = [k * dt for k in range(k0, math.floor(end / dt + 1e-9) + 1)]
        if not t_eval or abs(t_eval[-1] - end) > 1e-9:
            t_eval.append(end)
        sol = solve_ivp(rhs, (start, end), state, t_eval=t_eval, args=(target,),
                        method='RK45', rtol=1e-6, atol=1e-8, max_step=max(dt, 0.05))
        if not sol.success or not np.isfinite(sol.y).all():
            status, message = 'diverged', sol.message or 'non-finite state'
            break
        for j, t in enumerate(sol.t):
            times.append(float(t)); states.append(sol.y[:, j].copy()); commands.append(cmd)
        state = sol.y[:, -1].copy()
        if np.hypot(state[3], state[4]) > 50 or abs(state[5]) > 50:
            status, message = 'diverged', 'speed or yaw rate became unphysical'
            break
        start = end
    run = samples(vessel, co, times, states, commands, wind, current, status, message)
    run['destination'] = destination_report(run['samples'], scenario)
    dest = run['destination']
    if dest and dest['arrived'] and scenario.get('stop_at_destination'):
        # Cut the record at arrival (the model has no notion of stopping; this
        # only ends the trip there).
        n = run['samples']['t_s'].index(dest['arrival_t_s']) + 1
        run['samples'] = {k: v[:n] for k, v in run['samples'].items()}
        dest['distance_m'] = dest['distance_m'][:n]
        dest['final_m'] = dest['distance_m'][-1]
        run['stopped_at_destination'] = True
    return run


def destination_report(samples, scenario):
    """Closest approach and arrival for an optional destination.

    The destination is a compass bearing and distance from the start (0, 0).
    Arrival = first sample within `arrival_radius_m`. None when no destination.
    """
    distance = scenario.get('destination_distance_m') or 0
    if distance <= 0:
        return None
    target = compass_vector(scenario.get('destination_bearing_deg', 0), distance)
    d = np.hypot(np.asarray(samples['x_m']) - target[0], np.asarray(samples['y_m']) - target[1])
    radius = scenario.get('arrival_radius_m', 20.0)
    inside = np.nonzero(d <= radius)[0]
    i = int(np.argmin(d))
    return {'x_m': float(target[0]), 'y_m': float(target[1]), 'arrival_radius_m': radius,
            'closest_m': float(d[i]), 'closest_t_s': samples['t_s'][i], 'final_m': float(d[-1]),
            'arrived': bool(len(inside)), 'arrival_t_s': samples['t_s'][int(inside[0])] if len(inside) else None,
            'distance_m': d.tolist()}


def samples(vessel, co, times, states, commands, wind, current, status, message):
    # Drop duplicate times produced at schedule edges, keeping the later sample.
    keep = {}
    for i, t in enumerate(times):
        keep[round(t, 9)] = i
    order = [keep[k] for k in sorted(keep)]
    out = {k: [] for k in ('t_s', 'x_m', 'y_m', 'heading_deg', 'cog_deg', 'sog_mps', 'stw_mps',
                           'yaw_rate_dps', 'sail_deg', 'servo_cmd', 'apparent_wind_mps',
                           'apparent_wind_from_deg', 'sail_alpha_deg', 'heel_estimate_deg')}
    for i in order:
        s = states[i]
        F, N, roll, diag = forces(vessel, co, s[2], s[3:5], s[5], s[6], wind, current)
        through_water = s[3:5] - current
        out['t_s'].append(times[i])
        out['x_m'].append(float(s[0])); out['y_m'].append(float(s[1]))
        out['heading_deg'].append(heading_from_psi(s[2]))
        sog = float(np.hypot(s[3], s[4]))
        out['sog_mps'].append(sog)
        out['cog_deg'].append(float(math.degrees(math.atan2(s[3], s[4])) % 360) if sog > 1e-4 else None)
        out['stw_mps'].append(float(np.hypot(*through_water)))
        out['yaw_rate_dps'].append(float(math.degrees(s[5])))
        out['sail_deg'].append(float(s[6]))
        out['servo_cmd'].append(float(commands[i]))
        out['apparent_wind_mps'].append(diag['apparent_wind_mps'])
        out['apparent_wind_from_deg'].append(diag['apparent_wind_from_deg'])
        out['sail_alpha_deg'].append(float(np.mean(diag['sail_alpha_deg'])) if diag['sail_alpha_deg'] else None)
        slope = vessel.roll_slope_nm_per_rad
        out['heel_estimate_deg'].append(float(math.degrees(roll / -slope)) if slope and slope < 0 else None)
    return {'status': status, 'message': message, 'samples': out}
