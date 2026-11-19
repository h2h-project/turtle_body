# Turtle buoyancy workbench

A local calm-water workbench. It requires real masses and explicit displacement
classification before showing flotation. The CAD centre plane is only a datum.

## Start

From the repository root (Ubuntu, Python 3.14 tested, OpenSCAD 2021.01 tested):

```bash
python3 -m venv .venv
.venv/bin/pip install -r sim/requirements.txt
./run_sim.sh
```

OpenSCAD must be on PATH, in `~/.local/bin/openscad`, or selected with `OPENSCAD`.
The launcher binds only to `127.0.0.1:8765`. Use `--no-browser` or `--port 8766`
if needed. Installation needs internet; the running app and vendored Three.js
0.180.0 assets need none. Stop with Ctrl+C. Python packages live in the local
virtual environment; the existing CAD build commands remain standard-library only.

1. Press **Export CAD**. Installed meshes and exact ruler positions are generated
   from `src/Full_Turtle.scad`. This can take several minutes. Only one export or
   solve runs at a time; the browser stays responsive.
2. Follow [the measurement guide](../docs/buoyancy_measurements.md). Enter masses,
   balance points, displacement status and water density; confirm geometry. These
   forms live in the **Components & measurements** drawer: the gear at the right of
   the status bar opens and closes it (Escape also closes it). A dot on the gear
   means unsaved edits or missing measurements inside.
3. Save measurements (top of the drawer) and calculate. Water appears only after a
   successful solve.
4. Record signed ruler observations under the exact configuration name. Compare
   independent validation trials with the predictions. No automatic parameter fit.

Double-click a component to focus the view and inspect its ruler. Red marks the
centre of mass, blue the centre of buoyancy, and a fuchsia band the waterline:
where the calm water surface cuts the turtle at the solved pose (a legend appears
after a solve). The tilted bottle-centre plane (body Z=0, ruler zero) is hidden
by default; **Centre plane** toggles it. Sails (white) and the solar panel (dark grey)
are coloured from display-only face tags the CAD export writes; physics is unchanged.
The waterline cards always show the predicted reading; they turn red when it is
beyond the bottle radius at that fin (bottle under water, or clear of it) and say
when it is past the engraved scale. The export records the bottle diameter for this.
Each waterline card shows one reading in centimetres to one decimal (e.g.
+2.9cm) at the middle of the fin (the mean of its port and starboard face rulers;
the engraved rulers are in mm); positive = above bottle centre. Behind each
number a small gauge draws the bottle side-on: the card is three bottle diameters
tall, the grey lines at 1/3 and 2/3 are the bottle's bottom and top, the dotted
line its centre, and light blue water rises to the predicted level. The Roll
(seen from astern, port on the left) and Pitch (seen from starboard, bow on the
right) cards draw the same three lines tilted by the solved angle about the
turtle's middle, with level water at the mean of the front and rear readings.
Positive roll raises port; positive mathematical pitch lowers the bow.

Unknowns remain null in `physics/components.yaml`, the distributed input template.
The browser writes only `sim/data/`; generated meshes are in `sim/generated/`.
Both are ignored by Git. Download/load YAML and back up data, including uploaded
meshes. A CAD/source fingerprint prevents using stale exports.

## Fin fabrication

```bash
.venv/bin/python build/export_fin_dxf.py
```

Writes `fabrication/fins/{head,rear}_fin_face_{a,b}.dxf`. A: CUT + ENGRAVE;
B: ENGRAVE only. Millimetres; see the generated README for flipping/registration.
Engraving depth is 0.3 mm on each broad face; it is not a through-cut. Test CAM
and inspect face alignment before fabricating. The website exporters are
[synchronized](../docs/generator_sync_pending.md); that record identifies the
correct adjacent checkout and explicit upstream path for future syncs.

## Verification

```bash
PYTHONPATH=sim .venv/bin/pytest sim/tests -q
python3 build/build.py --check
python3 build/lint.py
```

The optional browser test uses Playwright and a local Chrome installation:

```bash
.venv/bin/pip install -r sim/requirements-dev.txt
.venv/bin/python sim/tests/browser_smoke.py
```

It starts its own local server, blocks external browser requests, and tests the
real missing-measurement survey and persistence using a temporary data directory.
The existing slow CAD mesh regression remains maintainer-run under CLAUDE.md.

## Model and interfaces

Engine code is independent of HTTP in `turtle_sim/core/`. Manifold unions solid
displacement and closes water-plane cuts; Trimesh supplies mass properties;
SciPy solves force/moment balance. Engraved recesses enter the displacement model.
CGAL coincident seams may be reconstructed only if Manifold accepts the topology,
produces a valid mesh and changes volume by at most 0.1%; deltas and original CAD
warnings are preserved in the manifest. Other bad meshes stop export/calculation.

API: `/api/geometry`, `/api/config`, `/api/validate`, `/api/import`, `/api/export`,
`/api/solve`, `/api/jobs/{id}`, `/api/mesh-upload/{component}`, `/api/config.yaml`,
and for sailing `/api/scenarios`, `/api/hydrodynamics` and `/api/sail/run`.
FastAPI's `/docs` describes validated measurement types. Jobs run in a separate
process and results retain the configuration and CAD fingerprint. The UI discards
results if measurements changed during the calculation.

**Sand ballast container** (section 05, `sand_ballast` in the configuration). The printed
U box under the bottom bottle (`lib/sand_ballast.scad`) is not a weighed component group,
so it is exported beside `COMPONENTS` as two meshes: its closed envelope (displacement)
and its inside fill space. The user picks *not attached*, *attached, empty* or
*attached, filled with sand*; a 0–100 % slider scales a full load of saturated sand
(`full_sand_mass_kg`, 0.75 kg). The sand settles to the floor as a level layer in the
CAD attitude: the solver cuts the fill space at the height that holds that fraction and
uses the layer's centroid. It does not re-settle the sand when the turtle heels. The empty
box's mass is the measured `box_mass_kg`, or else an estimate from its CAD plastic volume ×
1240 kg/m³, which the result flags. By default the box is sealed: the whole envelope
displaces water and the space above the sand holds air. `floods: true` fills that space
with water mass instead. The box needs the ballast frame installed. The sailing model
does not include the box's drag or yaw inertia yet.

Force balance uses a level water plane at world Z=0. Multiple initial poses search
within ±85° roll/pitch; found alternatives are retained in run JSON. Local one-axis
restoring moments are not a full coupled-stability analysis or capsize limit.
Waves, dynamic capsize, slosh, sensor emulation, online services and
website-generator changes are outside the workbench.

## Sailing and turning (roadmap stage 3, first version)

The **Sailing & turning** panel sails the turtle from its calculated float pose.
Pick a scenario from `sim/scenarios/*.yaml`, adjust it with the compass dials
(start heading, wind from, current from, destination direction) and the speed,
distance and sail-schedule fields, then **Run scenario**. Nobody steers: the
sail schedule is the only control. The result is an overhead track (north up,
green start, red end, amber destination ring; each turtle symbol is a circle with
an arrow at the bow and a line for the sail), a time slider, a destination
summary (arrived, or closest approach), and plots of speed, heading and sail
angle. The overhead view sits beside the 3D view and is always shown: before a
run it previews the dials (turtle in the middle, bow and starting sail, wind and
current flowing in toward it); changing a dial after a run drops that run and
returns to the preview. Each dial's explanation is a tooltip on its title.
Scenario defaults: bow north, wind from the south, current from the north.
Touching any dial or field switches the menu to **Custom**, which runs exactly
what the dials show. The destination card sets the distance, the arrival circle
(default 20 m) and, optionally, **End the trip when it arrives**
(`stop_at_destination`); otherwise the turtle sails on past it.
Runs are saved as `sim/data/runs/sail_<id>.json`. The first run for a
given set of measurements builds the model (equilibrium solve + silhouettes,
about a minute); later runs take under a second.

Model (`turtle_sim/core/sailing.py`, `core/sail_geometry.py`, `sailing_setup.py`):

- Horizontal motion only: surge, sway and yaw. Heave, roll and pitch stay at the
  stage-2 equilibrium. Heel is reported as a quasi-static estimate (sail roll
  moment ÷ the stage-2 roll restoring slope), not fed back; a warning appears
  above 10°.
- Sails: the two CAD-tagged sail faces as flat plates (lift with a finite-span
  slope below stall, normal force above), rotated about the shaft. Front and rear
  fins: the same plate model on their submerged area. Everything else: bluff
  drag on the projected area above and below the water, plus strip-theory yaw
  damping. Each force acts at its own point.
- Sail actuator: `servo_pos` 0–180 spans the ~270° travel (direct drive); 90 is
  the sail square across the hull (the CAD pose) until Wrangler W4 calibrates it;
  rate-limited. Commands change forces, never the heading. Launch with servo 90
  (crossbar square across, mid-travel) so the sail can trim ±135° either way. The
  sail dials' dot shows the way the sail faces (bow at 0°), so the ~90° dead zone is
  drawn directly behind the bow. A flat sail turned 180° lies on the same line, so
  the dead zone costs no sail setting.
- Conventions: heading in compass degrees true; world x east, y north; heading,
  course over ground, speed over ground and speed through water are separate.
  Wind and current are both given as the direction they come **from**. A
  destination is a bearing and distance from the start; arrival means coming
  within `arrival_radius_m` (default 20 m).
- Coefficients: `physics/hydrodynamics.yaml` (template). A copy at
  `sim/data/hydrodynamics.yaml` takes precedence. Each value says whether it is a
  placeholder, literature, calibrated, measured or user value, and every run
  warns while placeholders remain.

Limits: the ballast fin is drag only (no lift); sail-frame windage does not
rotate with the sail; the Munk moment is absent (isotropic added mass); no waves
or gusts. The outputs are true state, not sensor readings. The analytic tests
check equations and sign conventions only. Speeds and turn rates stay indicative
until recorded trials (stage 4) calibrate the coefficients.

Use measured geometry and separate physical trials to calibrate and validate.
A plausible rendering or analytic-shape test does not establish accuracy for the
real turtle. The third-party Three.js license is in `web/vendor/`; the Aleo and Mulish
fonts (SIL OFL 1.1) and their license are in `web/vendor/fonts/`.
