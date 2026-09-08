# Turtle Body — open issues

Last updated **2026-09-07**. Read `CLAUDE.md` for design rationale, the build
workflow (§15) and current dimensions. Resolved items have been removed; their
history is in `VERSION.json` and the `CLAUDE.md` changelog.

## Resolved (for the record)

The shared-library refactor (M0–M8) is complete. **TB-01, TB-02, TB-03, TB-04,
TB-07 are applied to both the standalone components and the full assembly** — all
geometry now flows from `lib/` and `build/build.py`. TB-05's core (a real
OpenSCAD 2021.01 regression baseline + `build/test.py` enforcement) is in place.
The one recorded intentional bounds change is the TB-03 cap roof 8 → 5 mm, which
drops `full_turtle` / `top_sail` Z-max to 306.5 (noted in
`tests/expected_bounds.json`). No source drift remains; open items below are
physical / interface checks, an external hookup, and an STL release.

---

## CH-2 — Verify rotating-assembly retention (physical + inspection)  — P2

`hope_turtle_sail_apparatus` still has no modelled axial lock. A hex fit
transmits torque but does not stop the cage/axle separating.

- Inspect the centre clip pocket and identify (or add) the retaining feature.
- Confirm hex angular phase and full engagement between axle, cage bore and
  sail-bar hole after the CH-1 transforms.
- Record the magnet-face and AS5600 sensor-plane positions once CH-1 fixes the
  cap/axle datum.

---

## TB-06 (residual) — Build the generator sync mechanism (S-5)  — P3, external

Every recorded drift item is fixed as of 2026-09-08 (list below, for the record). What
remains is S-5 only: the automatic sync mechanism, deliberately deferred in favor of
hand-fixing directly. Without it, the next turtle_body release needs this same manual
comparison redone by hand — see the closing paragraph below.

The generators live in `../hopeTurtles.org/generator/` (`objects/ecojoiner_6fc.py`,
`objects/back_fin.py`, `objects/ballast.py`, `objects/sails.py` + their reference
scripts). The bridge contract is `CLAUDE.md` §19 here and "Turtle Generator" in
that repository's `CLAUDE.md`; the ordered work plan is
`../hopeTurtles.org/generator/SYNC_PLAN.md` (S-1…S-6) and the running log is
`generator/SYNC_LOG.md`. Recorded drift as of 2026-09-08 (lib wins):

- ~~Rear fin~~ **fixed 2026-09-08**: shaft hole Ø6.0 → 6.4; hole 50 mm from front →
  TB-07 formula (103), now derived rather than a constant.
- ~~Ballast~~ **fixed 2026-09-08**: defaults 15/320/35 → 12/305/31; slat 4.5·t → 6·t;
  also found and fixed a missing M6 mount hole (none existed) and a latent bug where
  the shoulder cut read `port_length` instead of `bottle_diameter`.
- ~~Sails~~ **fixed 2026-09-08**: bottle diameter and cap/collar/dome heights are now
  real inputs (the SCAD already accepted them; only the Python wrapper never passed
  them through). SVG/DXF/PDF writers were also missing entirely for all 7 part
  shapes — added and verified against real OpenSCAD-rendered bounding boxes.
- ~~6FC Ecojoiner~~ **fixed 2026-09-08**: Master John + 5 Little Johns → 6 Little
  Johns; cap/collar/port height 32/32/85 → 31/34/82; screw 4.5 → Ø6.4. `objects/six_fc.py`
  renamed `objects/ecojoiner_6fc.py` (internal only — object_type and job-slug unchanged).
- ~~Port length~~ **fixed in v1.7.2**: lib had flattened it to a constant 82; it is
  now `p_top_dome_h() + p_port_allowance()`, the same rule the generators use.

This repository's share (S-5, the automatic sync mechanism): still open, deliberately
deferred in favor of hand-fixing the drift directly (2026-09-08). Would add
`build/export_params.py` writing `build/params.json` from every `p_*()`, hooked into
`build/build.py`, so the next turtle_body release doesn't need this comparison redone
by hand.

---

## TB-08 — Choose and validate the silicone-ring prototype  — P2, physical

Committed mold: Ø75 ID, Ø85 OD, 1.5 mm axial, 5 mm radial width. Ø85 inside an
assumed Ø81 bottle needs 2 mm radial deflection — may wrinkle/roll/distort. A
milder alternative (3.5 mm radial width → Ø82 OD, 0.5 mm interference) was
suggested but not implemented (`p_seal_ring_radial_w()` still 5).

Before treating the mold as final: measure the real bottle interior at both
groove positions on two perpendicular axes; identify the actual silicone product
and cured hardness; test demolding, insertion, retention and leakage; then set
`p_seal_ring_radial_w()`. The ring is not the whole seal — the axle and button
openings are separate interfaces.

---

## TB-05 (residual) — Release STLs from current sources  — P1 before a fabrication release

`v1.0 STLs/` still holds the original four exports. Before publishing a matched
set, regenerate with `python3 build/export_stl.py` (writes
`<name>_v<version>.stl`) and keep the `VERSION.json` version + `source_commit`
current so each STL's provenance is recorded.
