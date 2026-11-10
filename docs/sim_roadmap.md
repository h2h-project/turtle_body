# Turtle_Sim development roadmap

## Purpose

Turtle_Sim will be a Python application for exploring and improving the Hope Turtle’s buoyancy, stability, turning and sailing performance. It will combine the existing OpenSCAD design with measured component masses and physical properties, using NumPy/SciPy for calculations and Trimesh for geometry processing. Development will begin with flotation and balance, then add sail and underwater forces so that movement and turning emerge from the turtle’s physical configuration. Simulated sensors and actuator interfaces will align with TurtleOS, allowing later comparisons between simulated experiments and real water trials.

The application will initially run on an Ubuntu laptop, with FastAPI connecting the simulation engine to a lightweight browser interface. Three.js will show the turtle in water and its trajectory under different wind and current conditions. A live mode will let the user adjust the sail in real time and attempt to reach a chosen destination. Saved scenarios, live navigation and later TurtleOS experiments will share the same engine. Keeping the engine independent of the interface and storage will support eventual server deployment.

## 1. Keep CAD and physical data connected

The editable `.scad` sources remain the master files for shapes, dimensions and component placement. A companion `physics/components.yaml` file will hold masses, local centres of mass and other physical properties. No additional editable CAD format is required.

Extend the existing build tools to export geometry and installed component positions automatically. Changes to the CAD assembly must carry through to the simulator without manually copying coordinates. Edit source files in `lib/` and `src/`, then regenerate the existing CAD bundles.

Assign stable component identities, use consistent coordinates and convert CAD millimetres to physics metres at the export boundary. Record which properties are measured or estimated. Keep bottle displacement envelopes separate from loaded mass, and avoid counting included equipment or overlapping displacement twice.

## 2. Build the buoyancy workbench

Calculate total mass, centre of mass, submerged volume, centre of buoyancy and resting waterline, including pitch and roll. Show whether a tilted turtle tends to return upright.

Let users change loading and ballast placement and immediately inspect the result in the water view. Check the calculations against simple reference shapes, then compare the assembled turtle with float and tilt tests.

**First milestone:** a visual turtle with a calculated waterline and useful feedback on loading and stability.

## 3. Establish TurtleOS sensor and actuator contracts

Add a small adapter layer that translates physical simulation state into readings compatible with TurtleOS.

| Hardware | Simulated counterpart |
| --- | --- |
| GNSS | Position, course over ground, fix quality and age, including loss of fix |
| GY-87 compass and MPU6050 | Heading, acceleration, angular velocity and derived pitch/roll |
| AS5600 rotary encoder | Measured sail-shaft angle, quantization and magnet/presence status |
| MG996R sail servo | Commanded pulse, actual motion, travel limits, settling and power state |
| INA219 | Main-battery voltage and signed net current |
| RTC and environmental sensors | Compatible time, temperature, humidity and pressure values |

Keep physical truth, sensor readings and derived estimates separate. For example, the environment knows the wind, but emulated TurtleOS must estimate it from its sensor inputs.

Define units, sensor mounting axes, angle zeros, sample timing and unavailable readings explicitly. Calibrate the mapping between servo commands, physical sail angle and encoder angle. Reproduce current firmware behaviour separately from planned improvements such as fused heading. Initially, readings beyond the first model’s physical scope can use clearly identified configurable values.

The main battery and servo battery are separate power domains. The onboard INA219 must not be presented as measuring servo consumption.

## 4. Reproduce the luff tests

Support both existing TurtleOS approaches: the bench test that holds positions and measures flutter, and the navigation sweep that detects luffing while moving.

Introduce an adjustable model of sail/shaft flutter and mechanical response, then feed the resulting encoder samples into the existing algorithms through the adapter. Preserve sampling and settling times using a shared simulation clock, independent of browser rendering.

Test detection, missed detections, noise and missing-magnet cases. Preserve the 180-degree wind-axis ambiguity where applicable. Use recorded physical tests to calibrate the model: synthetic flutter can verify software behaviour, but cannot establish whether the real mechanism detects wind reliably.

**Milestone:** run and replay the real luff algorithms against simulated sensor traces.

## 5. Add sailing and turning

Model apparent wind, sail forces, water resistance and passive fin forces. Apply these forces at their physical locations to calculate forward motion, sideways drift and turning.

The rudder is fixed; only the sail rotates. A sail command must change forces rather than directly set heading. Keep heading, course over ground and speed through water distinct.

Start with horizontal movement and yaw, using approximate equilibrium flotation and heel. Detailed wave response and dynamic capsize modelling come later. Check numerical behaviour and calibrate uncertain force coefficients with tow and sailing trials.

Follow the TurtleOS experimental sequence: establish luff detection, useful propulsion and repeatable turning influence before relying on automated navigation. Existing placeholder steering remains an experimental controller.

## 6. Add visual experiments and live navigation

Provide a 3D water view, overhead trajectory, wind/current arrows, destination marker and performance graphs. Users can vary conditions, compare designs, pause runs and replay results.

In live mode, the user operates the simulated sail controls to attempt a destination challenge. Match the real actuator’s limits and movement rate. Reaching the destination records arrival; the turtle can continue drifting afterward.

Allow later experiments with the actual TurtleOS navigation code through the same sensor and actuator interfaces. Keep manual and automatic control ownership explicit.

## 7. Record experiments for comparison

Save the design version, physical configuration, environmental conditions, control commands, firmware/algorithm version and simulation settings with each run.

Align exported observations with existing TurtleOS/Wrangler field meanings, units and missing-data conventions. Record high-rate sensor traces around luff tests and sail movements alongside ordinary telemetry summaries.

Compare hold periods with sail adjustments, following the AOELL approach. Evaluate turning and progress using ground tracks and progress toward the destination, alongside heading changes. Distinguish measured, estimated and unavailable results. Use separate physical trials for calibration and validation.

## 8. Organize the code and deployment

| Location | Responsibility |
| --- | --- |
| `physics/` | Component properties and calibration |
| `build/export_sim.py` | Geometry and assembly export |
| `sim/turtle_sim/core/` | Physics and simulation clock |
| `sim/turtle_sim/adapters/` | TurtleOS sensor and actuator interfaces |
| `sim/turtle_sim/api/` | FastAPI and live sessions |
| `sim/web/` | Browser interface and Three.js |
| `sim/scenarios/` and `sim/tests/` | Repeatable experiments and verification |

Begin with a Python virtual environment, local files and one launcher that opens the browser. Run expensive simulations in worker processes so the interface stays responsive. Local scenarios and browser assets should work offline. Snap packaging is outside this plan.

Deploy the same application later behind NGINX and HTTPS, managed by systemd, with persistent storage and backups. Add authentication, session isolation and queued workers when shared use requires them.

Later stages can introduce Mediterranean wind/current datasets and more detailed waves through the environmental interface.

## Starting point

Inventory component masses, define the geometry export and sensor contracts, then build the buoyancy workbench. Establish the TurtleOS adapter before developing luff and sailing experiments so the physical model and its observations grow together.
