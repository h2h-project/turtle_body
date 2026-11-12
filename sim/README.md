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
   balance points, displacement status and water density; confirm geometry.
3. Save measurements and calculate. Water appears only after a successful solve.
4. Record signed ruler observations under the exact configuration name. Compare
   independent validation trials with the predictions. No automatic parameter fit.

Double-click a component to focus the view and inspect its ruler. Red marks the
centre of mass, blue the centre of buoyancy. The faint gold plane is body Z=0.
Ruler readings are listed port / starboard; positive = above bottle centre.
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
`/api/solve`, `/api/jobs/{id}`, `/api/mesh-upload/{component}` and `/api/config.yaml`.
FastAPI's `/docs` describes validated measurement types. Jobs run in a separate
process and results retain the configuration and CAD fingerprint. The UI discards
results if measurements changed during the calculation.

Force balance uses a level water plane at world Z=0. Multiple initial poses search
within ±85° roll/pitch; found alternatives are retained in run JSON. Local one-axis
restoring moments are not a full coupled-stability analysis or capsize limit.
Waves, dynamic capsize, slosh, sailing forces, sensor emulation, online services
and website-generator changes are outside this first workbench.

Use measured geometry and separate physical trials to calibrate and validate.
A plausible rendering or analytic-shape test does not establish accuracy for the
real turtle. The third-party Three.js license is in `web/vendor/`.
