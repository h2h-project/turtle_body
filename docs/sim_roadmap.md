# Turtle_Sim development roadmap

## Purpose

Turtle_Sim is a Python application for exploring and improving the Hope Turtle’s buoyancy, stability, turning and sailing performance. It combines the OpenSCAD design with measured component masses and physical properties, using NumPy/SciPy for calculations and Trimesh for geometry processing. Development began with flotation and balance. It continues with sail and underwater forces, so that movement and turning emerge from the turtle’s physical configuration. Real-world trials recorded through the Turtle Wrangler app calibrate and validate those forces.

The application runs on an Ubuntu laptop, with FastAPI connecting the simulation engine to a lightweight browser interface. Three.js shows the turtle in water and its trajectory under different wind and current conditions. A live mode will let the user adjust the sail in real time and attempt to reach a chosen destination. Saved scenarios, imported field trials and live navigation share the same engine. Keeping the engine independent of the interface and storage will support eventual server deployment.

**Scope.** The simulator models the turtle’s physics. It does not emulate the sensor stack for its own sake. Sensors enter in two narrow ways:

- **Inward, as measurements.** Real readings from water trials (GNSS track, heading, pitch/roll, sail angle) calibrate and validate the physical model (stage 4).
- **Outward, as a thin adapter.** Only when TurtleOS navigation code is run against the simulated turtle (stage 5).

Luff detection is out of scope. It depends on how a real sail and shaft flutter, which a simulator can only invent. It is developed and tested on real turtles through Turtle Wrangler.

## 1. Keep CAD and physical data connected — done

The editable `.scad` sources remain the master files for shapes, dimensions and component placement. `physics/components.yaml` holds masses, local centres of mass and other physical properties. No additional editable CAD format is required.

`build/export_sim.py` exports geometry and installed component positions automatically, so CAD changes carry through to the simulator without manually copying coordinates. Edit source files in `lib/` and `src/`, then regenerate the CAD bundles.

Components have stable identities and consistent coordinates, and millimetres convert to metres at the export boundary. Each property records whether it is measured or estimated. Bottle displacement envelopes stay separate from loaded mass, and included equipment and overlapping displacement are never counted twice.

## 2. Build the buoyancy workbench — done (v6.6.0)

Calculates total mass, centre of mass, submerged volume, centre of buoyancy and resting waterline, including pitch and roll, and shows whether a tilted turtle tends to return upright. Users can change loading and ballast placement and inspect the result in the water view. Calculations are checked against simple reference shapes.

**Remaining:** compare the assembled turtle with float and tilt tests using the fin rulers (see *Buoyancy calibration datum*). Front and rear ruler readings alone do not establish roll. A logged MPU6050 pitch/roll reading taken during the same float test can supply it. It is used as a measurement, not an emulated sensor.

## 3. Add sailing and turning

Model apparent wind, sail forces, water resistance and passive fin forces. Apply these forces at their physical locations to calculate forward motion, sideways drift and turning.

The rudder is fixed; only the sail rotates. A sail command must change forces rather than directly set heading. Keep heading, course over ground and speed through water distinct.

Work from the simulator’s true state (exact heading, sail angle, velocity). No sensor emulation is needed at this stage. Start with horizontal movement and yaw, using approximate equilibrium flotation and heel. Detailed wave response and dynamic capsize modelling come later. Check numerical behaviour first, and treat force coefficients as uncertain until stage 4 calibrates them.

Represent the actuator realistically from the start: sail travel limits, movement rate and settling time, matching the MG996R servo and the sail-shaft geometry.

**Milestone:** a scenario where a fixed sail angle, wind and current produce a plausible track, and changing the sail angle changes the turning behaviour.

## 4. Import real-world trials from Turtle Wrangler

Turtle Wrangler talks to the turtle over Bluetooth during water trials and already shows live values and journey progress. Make it the source of field data for the simulator:

- Wrangler records a trial: position and fix quality, heading, pitch/roll, sail command and AS5600 sail angle, time-stamped, plus the trial notes the operator enters (wind estimate, current, ballast/loading configuration, design version). It exports the trial as a file.
- The simulator imports that file, replays the recorded sail commands against the modelled turtle under the recorded conditions, and overlays the simulated track on the real one.
- The differences are what calibrate the uncertain force coefficients (sail lift/drag, hull and fin resistance, turning response). Use separate trials for calibration and validation.

The import uses the field names, units and "no data" sentinels of the TurtleOS GATT contract (`../turtleOS/docs/wrangler/README.md`). It does not invent a parallel format. Wrangler is a short-range link. A log covers only the stretch the operator was in range for, or whatever the turtle buffered and handed over afterward. Mark gaps as unavailable, never interpolated.

Wrangler does not record any of this yet. See *Wrangler and TurtleOS changes for sim compatibility* below.

Wrangler also hosts the luff tests. The simulator can consume their *results* (for example, an estimated apparent-wind angle with its quality) as recorded observations. It does not reproduce the detection itself.

**Milestone:** one real trial imported, replayed and overlaid on the simulated track, with the mismatch reported.

## 5. Run TurtleOS navigation against the simulated turtle

Once stage 3 produces believable turning and stage 4 has calibrated it, close the loop: run the actual TurtleOS navigation controller against the simulated turtle. This answers questions no single-subsystem test can. Can the controller reach a destination at the turtle’s real turning rate, with noisy GNSS and fix dropouts? Does a design change (fin size, sail area, ballast) make the turtle more steerable by its own software?

Add a thin adapter covering only what the controller reads and commands:

| Hardware | Simulated counterpart |
| --- | --- |
| GNSS | Position, course over ground, fix quality and age, including loss of fix |
| GY-87 compass / MPU6050 | Heading, and pitch/roll if the controller uses them |
| AS5600 rotary encoder | Measured sail-shaft angle with quantization and magnet-present status |
| MG996R sail servo | Commanded position → actual motion, using the stage 3 actuator model |

Keep physical truth, sensor readings and derived estimates separate. The environment knows the wind, but the emulated controller must work only from its inputs. Define units, mounting axes, angle zeros, sample timing and unavailable readings explicitly. Reproduce current firmware behaviour separately from planned improvements such as fused heading.

Battery monitoring (INA219), RTC and environmental sensors are not emulated. They do not affect the physics or the controller’s steering decisions. Add one only when a specific question needs it.

The adapter couples this repository to firmware that is still changing. Build it only when there is a controller question to answer, and keep it small.

## 6. Add visual experiments and live navigation

Provide a 3D water view, overhead trajectory, wind/current arrows, destination marker and performance graphs. Users can vary conditions, compare designs, pause runs and replay results, including imported Wrangler trials alongside simulated ones.

In live mode, the user operates the simulated sail controls to attempt a destination challenge, within the real actuator’s limits and movement rate. Reaching the destination records arrival; the turtle can continue drifting afterward. When stage 5 exists, the same controls can be handed to the TurtleOS controller; keep manual and automatic control ownership explicit.

## 7. Record experiments for comparison

Save the design version, physical configuration, environmental conditions, control commands, firmware/algorithm version and simulation settings with each run. Simulated runs and imported trials use the same record format, so they compare directly.

Compare hold periods with sail adjustments, following the AOELL approach. Evaluate turning and progress using ground tracks and progress toward the destination, alongside heading changes. Distinguish measured, estimated and unavailable results.

## 8. Organize the code and deployment

| Location | Responsibility |
| --- | --- |
| `physics/` | Component properties and calibration |
| `build/export_sim.py` | Geometry and assembly export |
| `sim/turtle_sim/core/` | Physics and simulation clock |
| `sim/turtle_sim/trials/` | Wrangler trial import, replay and comparison (stage 4) |
| `sim/turtle_sim/adapters/` | Thin TurtleOS controller interface (stage 5) |
| `sim/turtle_sim/api/` | FastAPI and live sessions |
| `sim/web/` | Browser interface and Three.js |
| `sim/scenarios/` and `sim/tests/` | Repeatable experiments and verification |

Run with a Python virtual environment, local files and one launcher that opens the browser. Expensive simulations run in worker processes so the interface stays responsive. Local scenarios and browser assets work offline. Snap packaging is outside this plan.

Deploy the same application later behind NGINX and HTTPS, managed by systemd, with persistent storage and backups. Add authentication, session isolation and queued workers when shared use requires them.

Later stages can introduce Mediterranean wind/current datasets and more detailed waves through the environmental interface.

## Wrangler and TurtleOS changes for sim compatibility

This section is written to be moved into the Wrangler roadmap
(`../turtleOS/docs/wrangler/02_android_app.md`). It reflects Wrangler v0.3.0 and GATT
contract v1 as inspected on 2026-11-17. Wrangler's own rule applies: any new Bluetooth field
goes into the TurtleOS contract first, then both sides.

### What Wrangler has today

| Already there | Use to the sim |
| --- | --- |
| Live Position, Nav, Sail and IMU notifications at 1 Hz (Sail 2 Hz while sweeping) | The raw channels a trial needs. 1 Hz is enough for tracks and slow turns |
| Journey records (`JourneyStore`): departure, destination, arrival, end time, and a route of `(t, lat, lon)` merged from the phone's view and the turtle's `JOURNEY_TRACK` | A ground track with start/finish, but no heading or sail data |
| Find the Wind panel: luff bench sweep, turtle heading vs phone compass (true north at the turtle's position) | An observed wind direction with confidence. The phone compass is a practical way to note true wind on the bank |
| Servo dial and manual sail hold (`SERVO_SET_ANGLE`) | The way an operator runs controlled sail-angle trials |

What's missing: heading, sail angle, servo command and pitch/roll are shown live but never
stored. Battery and environment histories live in memory for one connection. Nothing can be
exported as a file.

### W1. Trial recorder (Wrangler only, no contract change)

A **Record trial** control (Navigate or Diagnostics) that, while running, appends every
notification it receives from Position `0110`, Nav `0111`, Sail `0113`, IMU `0115` and
Journey `0117`/`0119` to a per-trial file. Each row carries:

- the phone receive time (ms) and the turtle's `device_now` with its `clock_source`;
- the decoded fields under their contract names (`lat`, `lon`, `sats`, `fix_quality`,
  `fix_age_s`, `imu_heading`, `compass_offset_deg`, `machine_state`, `trim`,
  `sail_angle`, `servo_pos`, `wind_angle`, `imu_pitch`, `imu_roll`);
- null for a sentinel. The recorder never fills gaps, and never drops a row because a field
  is missing.

Also log **every command sent** (opcode, payload, send time, result code), especially
`SERVO_SET_ANGLE` and manual holds. Replay depends on knowing when the sail was told to move,
not only where it ended up. Mark link drops and reconnects as events, so the sim can tell
"no data" from "turtle stopped".

### W2. Trial notes (Wrangler only)

A short form at the start and end of a trial, saved in the same file:

- wind: direction (the phone compass as in Find the Wind, plus any luff result with
  confidence) and a speed estimate or handheld anemometer reading;
- water: current estimate, sea state, location name;
- turtle configuration: Turtle Body version (`VERSION.json`, e.g. 6.6.3), ballast/loading
  notes, a pointer to the sim's measurement set (`sim/data/`) if one exists, and free text;
- calibration readings taken that day: fin-ruler readings at rest (front/rear, face) and the
  AS5600 reading with the sail on the hull centreline (see W4).

### W3. Export (Wrangler only)

Export a trial (and optionally a plain journey) through Android's share sheet as one file.
Suggested shape: a JSON header (format version, app version, contract version, turtle name,
notes) followed by JSON Lines rows, one per notification or event. The field names are the
contract's own. The sim's stage 4 importer reads that file. A `trial_format` version number
lets either side evolve. Wrangler's privacy rule still holds: no phone location, and the file
leaves the phone only when the operator shares it.

### W4. Sail-angle reference (calibration, small)

The sim needs the sail angle relative to the hull. Today `sail_angle` is raw AS5600 encoder
degrees with no defined zero, and `servo_pos` is a 0–180 command spanning ~270° of servo
travel. Add a Diagnostics step that records the AS5600 reading with the sail on the hull
centreline (bow-pointing), and the readings at both servo end stops. Store these with the
trial (W2). This is a per-turtle calibration, so it is a recording, not a firmware constant.

### W5. Out-of-range coverage (TurtleOS + contract change)

Bluetooth reaches a few metres, so W1 alone covers only trials where the operator follows
the turtle. To cover a whole sail, the turtle's journey track (`journey_<id>.trk`, served by
`JOURNEY_TRACK`) would need more than `(recorded_at, lat, lon, machine_state)`. It would need
at least `imu_heading`, `sail_angle`, `servo_pos` and `imu_pitch`/`imu_roll`, and possibly a
faster logging rate during a trial. This is a contract change, so it starts in TurtleOS
(`docs/wrangler/README.md`): new track-point fields, the track file format, storage limits on
the turtle, and a contract version note. Wrangler then decodes the longer points and merges
them into the trial file as it does with journey routes today.

### W6. Optional, later

- A faster notify rate (for example 5 Hz Nav/Sail/IMU) while a trial is recording, if 1 Hz
  proves too coarse for turning. Contract change; check the power cost with Wrangler's power
  test first.
- Shore data: once hopeturtles.org serves journey tracks (app API Phase D), the sim could
  import long-range tracks from the server too. Those would be position only, unless W5's
  fields also reach the telemetry JSON.
- `xte_m` is defined in the contract but not computed yet. The sim can compute cross-track
  error itself from the track and destination, so this is not a blocker.

### Order

W1 + W3 first (one recorded, exportable trial is enough to start stage 4), then W2 and W4
(they make the trial calibratable), then W5 when trials outgrow Bluetooth range. Luff-test
work in Wrangler is independent of all of these.

## Next steps

1. Finish stage 2 calibration with fin-ruler (and IMU pitch/roll) float tests.
2. Build stage 3 sailing and turning on true state.
3. In parallel, build the Wrangler trial recorder and export (W1, W3) so that the first sailing trials are recorded in a form stage 4 can import.

## Buoyancy calibration datum

The workbench uses front/rear fin rulers, engraved 0.3 mm deep on both
faces. Zero is the horizontal bottle-axis centre plane; signed millimetres
increase physically upward. CAD supplies each ruler's installed reference line.
The solver predicts each ruler line's intersection with the world water plane after
heave, pitch and roll, which is then compared with face-identified trial readings. Ruler observations validate the
volume/moment calculation; they do not replace it. Front/rear readings alone do
not independently establish roll. See `buoyancy_measurements.md` for the survey
and `../sim/README.md` for operation and current model limits.
