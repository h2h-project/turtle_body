# Turtle Body build system

Local, no network, no CI service. Python 3 standard library + OpenSCAD only.

## Layout

| Path | Role |
| --- | --- |
| `lib/*.scad` | **Editable.** One parametric module per subsystem, plus `params.scad` (the shared dimension contract, exposed as `function p_*()`), plus `util.scad`. Definitions only — no top-level geometry, no top-level variable assignments. |
| `src/Full_Turtle.scad`, `src/components/*.scad` | **Editable.** Thin wrappers: customizer block + `use <../lib/...>` + a `part=` / `assembly_view` dispatch. No geometry of their own. |
| `Full_Turtle_v1.scad`, `v1.0 SCADs/*.scad` | **Generated. Do not edit.** Self-contained bundles produced from `src/` + `lib/`. Committed so they stay downloadable and STL-ready. A banner marks them. |
| `v1.0 STLs/*_v<version>.stl` | Fabrication exports, written on demand by `export_stl.py`. Not auto-committed. |
| `build/manifest.json` | Every renderable target: its `src`, its generated `out`, and the `-D` defines for each render. |
| `tests/expected_bounds.json` | Regression baseline (bounding box + triangle count per render) that `test.py` checks. |
| `tests/baseline/*.json` | Full per-render dump from the last `baseline.py` run (bounds, echoes, warnings, timing). |
| `VERSION.json` | Single set-level version + changelog. |

## Scripts

```bash
python3 build/build.py            # regenerate every bundle from src/ + lib/  (the sync step)
python3 build/build.py --check    # fail if a committed bundle is stale
python3 build/lint.py             # bundle freshness + git whitespace + OpenSCAD CSG parse + lib hygiene
python3 build/test.py             # mesh every render, compare bounds/warnings to the baseline (maintainer-run — see workflow)
python3 build/baseline.py         # re-record the baseline (only when geometry changes are intentional; maintainer-run)
python3 build/export_stl.py       # write the PLA-part STLs, version-stamped
python3 build/bundle.py SRC.scad  # inline use/include for one file (build.py uses this)
```

`OPENSCAD=/path/to/openscad` overrides binary discovery (PATH → `~/.local/bin` → macOS app bundle).

## Change workflow

1. Edit **only** `lib/` and/or `src/`. Never edit a generated bundle.
2. `python3 build/build.py` — propagates to `Full_Turtle_v1.scad` and every `v1.0 SCADs/*.scad`.
3. `python3 build/lint.py`
4. Visually inspect the change in OpenSCAD. `build/test.py` is **not** run automatically
   (it is slow, and it only detects change vs. baseline in renders you did not open) — run it,
   and `baseline.py` if a bounds change is intentional, only for a shared-contract edit
   (`lib/params.scad`, `lib/util.scad`, a shared module signature) or before a commit / STL
   release. Review the `tests/expected_bounds.json` diff as the sign-off. See CLAUDE.md §15
   step 5 for the full policy (agents recommend the run and wait; they do not run it themselves).
5. Bump `VERSION.json`: `+0.0.1` component-scoped, `+0.1.0` full-turtle-scoped, `+1.0.0` bottle/
   hardware interface break. Append a `changelog` entry.
6. `python3 build/export_stl.py` when new fabrication files are actually needed.
