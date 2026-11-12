# Website generator synchronization — completed

Status: SYNCED (uncommitted), 2026-11-12, turtle_body v6.6.0.

The website checkout is `/home/russs/WebstormProjects/hopeTurtles.org`, rather than
beside this PyCharm checkout. Its generator has now been synchronized from
`/home/russs/PycharmProjects/turtle_body` using the explicit upstream path.

Delivered downstream:

- Refreshed parameter snapshot, version and all five wooden-component SCAD bundles.
- Head fin SCAD uses the upstream bundle. The existing rear template embeds the
  upstream engraving definitions and preserves its shaft/connection overrides.
- Shared Python ruler geometry feeds both fins' SVG, DXF and PDF writers without
  requiring OpenSCAD on the website server.
- Existing DXF cut geometry is retained; ruler paths use the separate ENGRAVE
  layer. Each request also includes a registered opposite-face engraving-only
  DXF. Both faces use the same zero and signed millimetres as the simulator.
- Ruler columns now follow joint placement when board dimensions change while
  retaining the reference build's X=30 / X=42 positions.
- PDF annotations were moved clear of the ruler glyphs. Manifests include ruler
  zero, sign, range, units and engraving depth.
- Updated website `generator/SYNC_LOG.md`, `generator/FIN_RULERS.md` and its
  `CLAUDE.md`, preserving unrelated existing changes.

Verification: 16 geometric footprint comparisons between generated SCAD and
Python paths, eight complete SCAD/SVG/DXF/PDF export sets, positive/negative
connection-fit offsets, changed bottle/stock dimensions, face registration,
invalid inputs, and all 81 shared-parameter checks. These checks do not establish
physical calibration or manufacturing validation.

## Two local upstream checkouts

`/home/russs/WebstormProjects/turtle_body` is a separate older checkout. Until it
is reconciled with this one, website sync commands must select the intended
upstream explicitly:

```bash
cd /home/russs/WebstormProjects/hopeTurtles.org
python3 generator/sync_from_turtle_body.py --turtle-body /home/russs/PycharmProjects/turtle_body
python3 generator/sync_from_turtle_body.py --check --turtle-body /home/russs/PycharmProjects/turtle_body
python3 generator/check_params_sync.py
generator/.venv/bin/python generator/verify_fin_rulers.py
```

Alternatively set `TURTLE_BODY_DIR` before `npm run generator:sync`. No commits,
pushes, production deployment or unrelated working-tree edits were performed.
