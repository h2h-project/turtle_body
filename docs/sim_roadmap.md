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

## 3. Add sailing and turning — first version built (2026-11-17)

**Status:** surge/sway/yaw on the fixed stage-2 float pose; flat-plate sails and
fins; bluff drag and windage from CAD silhouettes; rate-limited servo with ~270°
direct-drive travel; scenario files in `sim/scenarios/`; coefficients in
`physics/hydrodynamics.yaml` (mostly placeholders); overhead track view in the
workbench. Details and limits: `../sim/README.md`. Still open: ballast-fin lift,
heel feedback, waves and gusts. The milestone below is met only in the sense of
*plausible*. *Calibrated* waits for stage 4.

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

Wrangler does not record any of this yet. The changes it needs are now in the Wrangler roadmap (`../turtleOS/docs/wrangler/02_android_app.md` → *Phase 11 — trial recording for Turtle_Sim*).

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

Moved on 2026-11-19 to the Wrangler roadmap, `../turtleOS/docs/wrangler/02_android_app.md`
→ *Phase 11 — trial recording for Turtle_Sim*. It lists what Wrangler (and, for W5,
TurtleOS) needs before a trial can be imported here: W1 trial recorder, W2 trial notes,
W3 export, W4 sail-angle reference, W5 out-of-range coverage, W6 optional extras. Order
there: W1 + W3 first, then W2 + W4, then W5.

## Next steps

Updated 2026-11-19. Stages 1–3 are built; the sim app is stable enough to wait on
field data.

1. **Fin-ruler labels in turtle_labels.** Add the fin calibration rulers to
   `turtle_labels/scripts/export_labels.sh` so they come out on the printed sticker
   sheets. That way a turtle whose fins were not laser-engraved can still be read in a
   float test. `master/fin-ruler.svg` (20.4 × 123 mm) is already flattened by the
   exporter but has no place in its `SHEET_LAYOUT`, so it never reaches a sheet.
   - Place enough copies per turtle: two fins, read from either side, so up to four.
     Decide whether face B needs its own variant, as the engraving does (face B is
     mirrored about X = 0, `build/export_fin_dxf.py`).
   - Keep the sticker in step with this repo's ruler. The source of truth is
     `fin_ruler_scale_2d()` (`lib/fin_ruler.scad`), printed 1:1 by
     `build/export_ruler_svg.py` as `scads_v1/fin_ruler_scale_v<version>.svg`
     (±60 mm since v6.6.9). Check the master's span, tick spacing and zero against it,
     and consider having `export_ruler_svg.py` copy the generated file into
     turtle_labels the way `build/export_inventory.py` does for the inventory.
   - Say on the label, or in the build guide, where the zero line goes on each fin (the
     bottle-axis centre plane, section 11 of `CLAUDE.md`). A sticker placed off that
     datum gives wrong waterline readings.
2. **Finish stage 2 calibration with a float test.** Fill in the survey in
   `buoyancy_measurements.md`, float the turtle in calm water, and compare the fin-ruler
   readings (plus IMU pitch/roll) with the workbench's predicted waterline. Needs
   readable rulers on both fins, engraved or from step 1.
3. **Wrangler trial recorder and export (Wrangler Phase 11, W1 + W3).** This is the
   blocker for stage 4: one recorded, exportable trial is enough to start the importer.
   W2 (notes) and W4 (sail-angle zero) follow, because without them a trial cannot
   calibrate anything.
4. **Stage 4 importer** (`sim/turtle_sim/trials/`). Write the trial file format down
   first, using the TurtleOS contract's field names, so Wrangler and the sim build
   against the same spec. Then import, replay and overlay one real trial and report the
   mismatch.
5. **Stage 3 open items as trials demand them:** ballast-fin lift, heel feedback, waves
   and gusts. Hold these until real trials show which one matters.

## Buoyancy calibration datum

The workbench uses front/rear fin rulers, engraved 0.3 mm deep on both
faces. Zero is the horizontal bottle-axis centre plane; signed millimetres
increase physically upward. CAD supplies each ruler's installed reference line.
The solver predicts each ruler line's intersection with the world water plane after
heave, pitch and roll, which is then compared with face-identified trial readings. Ruler observations validate the
volume/moment calculation; they do not replace it. Front/rear readings alone do
not independently establish roll. See `buoyancy_measurements.md` for the survey
and `../sim/README.md` for operation and current model limits.
