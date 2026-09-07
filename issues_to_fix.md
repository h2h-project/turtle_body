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

## TB-06 — Connect the Python body generators  — P2, external

`generate_turtle_rear_fin_v2.py`, `generate_turtle_ballast.py`,
`generate_turtle_sail_apparatus.py` live in the HopeTurtles.org repository, not
here. When integrating, wire them to the `lib/params.scad` contract rather than
re-deriving dimensions; keep `--force` protection and self-contained UTF-8 output.

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
