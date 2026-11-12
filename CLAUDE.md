# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Turtle Body — project instructions and mechanical design context

This repository contains the parametric mechanical designs for Hope Turtle. Read this file before changing geometry, dimensions, generators, or fabrication outputs. It records design decisions from the development conversation and the repository state inspected on **2026-09-06**.

Repository snapshot inspected: `main`, commit `015a162f2bcac592a70c50a740c1671a10352732`. Recheck the working tree and subsequent commits before treating the dimensions below as current. This document is project guidance, not evidence of successful fabrication or physical validation.

See `issues_to_fix.md` for the accompanying prioritized repair and verification backlog. It separates confirmed source drift from design decisions and unverified physical risks.

> **2026-09-07 — build system + shared-library refactor COMPLETE (M0–M8).**
> Editable geometry lives in `lib/` (parametric modules + `params.scad`, the
> shared dimension contract) and `src/` (thin wrappers). `Full_Turtle_v1.scad`
> and `scads_v1/*.scad` are **generated bundles** — never hand-edit them; run
> `python3 build/build.py`. See **section 15** for the workflow and
> `build/README.md`.
>
> **Every subsystem in the full turtle now flows from `lib/`** — bottle + cut
> bottle, `wood_color`/`m6_bolt_placeholder`, Ecojoiner, ballast, rear-fin wood,
> sail frame, control cap, control axle, control cage. `src/Full_Turtle.scad`
> went 4656 → 2749 lines. **TB-01, TB-02, TB-03, TB-04, TB-07 are all applied to
> the full assembly.** The one recorded intentional bounds change: the cap roof
> 8 → 5 mm (TB-03) drops the sail head 3 mm via `control_assembly_z`, so
> `full_turtle` / `top_sail` Z-max is 306.5 (was 309.5) — noted in
> `tests/expected_bounds.json`. Everything else matches the pre-refactor baseline.
> Remaining `issues_to_fix.md` items are physical / interface checks and the
> generator sync — no source drift left in this repository.
>
> **2026-09-08 — downstream bridge to the HopeTurtles.org generators.** The
> Python generators that turn a builder's measurements into cutting files live
> in the HopeTurtles.org repository `/home/russs/WebstormProjects/hopeTurtles.org/generator/`. **`lib/params.scad`
> is authoritative; they follow it.** Any change to a shared value or a wooden
> component must be propagated (or logged) there — see **section 19** and step 8
> of the section 15 workflow.

## 1. Start here

- Use millimetres throughout. Distinguish diameter from radius, axial height from radial depth, and across-flats from across-corners dimensions.
- Read the current source before editing. New user instructions and deliberate repository edits take precedence over older conversation values.
- Preserve working geometry outside the requested change. Identify affected mating parts and report any resulting incompatibility.
- Keep standalone components, Python generator templates, the full assembly, and regenerated STLs consistent when the task requests synchronization. A standalone edit has not automatically updated the full assembly.
- Do not assume a larger filename version number means newer geometry. Files were renamed during repository import.
- Do not restore removed C-piece or non-sail-batten bottom screw holes. Retain the two M3 cage attachment holes in every batten.
- Preserve the open-bottom cage, eight solid bearing hemispheres, four continuous sine-wall peaks, and the mounting grooves centred on those peaks.
- Do not claim “watertight,” “print-ready,” “stronger,” or “tested” solely from a plausible rendering or balanced SCAD delimiters. State what was actually checked.
- Quote paths containing spaces. Prefer `rg` for searching source and `git diff` for reviewing changes.
- Preserve the repository's CERN-OHL-S-2.0 notices and existing `LICENSE`.

## 2. Project purpose and related systems

Hope Turtle is a wind-powered marine vessel built around ordinary bottles, locally available wooden stock, and accessible fabrication. Turtle Body provides the bottle interfaces, Ecojoiner frame, control cap, rotating cage, magnetic sensing axle, sail frame, rear solar-panel support/fin, and ballast attachment.

Related projects:

| Project | Responsibility |
| --- | --- |
| [Turtle Body](https://github.com/h2h-project/turtle_body) | Mechanical source models and fabrication files |
| [TurtleOS](https://github.com/h2h-project/turtleOS) | Sensing, actuation and navigation software. Local checkout: `/home/russs/PycharmProjects/turtleOS` (`../turtleOS`) |
| [TurtleShell PCB](https://github.com/h2h-project/turtle_Shells) | Electronics interconnection and power hardware. Local checkout: `/home/russs/PycharmProjects/turtle_Shells` (`../turtle_Shells`) |
| [Turtle Wrangler](https://github.com/h2h-project/turtle_wrangler) | Android app for talking to and sending requests to turtles; its telemetry field meanings are what the sim roadmap aligns with (section 20). Local checkout: `/home/russs/PycharmProjects/turtle_wrangler` (`../turtle_wrangler`) |
| [Turtle Labels](https://github.com/h2h-project/turtle_labels) | Multilingual SVG labels/iconography printed or laser-engraved on turtles. Receives `turtle_body_full_inventory_<version>.svg` from this repo (section 21). Local checkout: `/home/russs/WebstormProjects/turtle_labels` |
| [HopeTurtles.org source](https://github.com/h2h-project/hopeTurtles.org) | Builder-facing website; hosts the Python turtle generators in `generator/` that are downstream of this repository's `lib/` (section 19). Local checkout: `/home/russs/WebstormProjects/hopeTurtles.org`. |
| [HopeTurtles.org](https://hopeturtles.org) | Public project website; `/ecojoiners/generate` is the live generator form |

The generator accepts a builder's bottle, board and solar-panel dimensions and produces cutting files (SCAD, SVG, DXF, PDF) for the wooden components. It runs as Python inside the HopeTurtles.org Node app, not as a service this repository calls. Do not invent a deployed geometry API, CI workflow, package manager, or frontend build process here.

## 3. Actual repository map

Paths below were verified in the inspected GitHub tree.

| Path | Role |
| --- | --- |
| `lib/params.scad` | **Editable.** Shared dimension contract — every cross-subsystem value as a `function p_*()`. One definition per concept; derived values are functions of other `p_*()`. |
| `lib/util.scad` | **Editable.** `wood_color()`, `m6_bolt_placeholder()`, `clamp()`, `hex_prism_af()`. |
| `lib/<subsystem>.scad` | **Editable.** One parametric module per subsystem: `control_cap`, `control_cage`, `sail_shaft` (`sail_shaft`, TB-08: was `hex_shaft` / `control_axle`), `silicone_ring_mold`, `ecojoiner`, `ballast_fin`, `rear_fin`, `head_fin` (v5.8.0, experimental), `pressor` (v6.6.1, experimental), `sail_frame`, `bottle_mockup`. Module args default to `p_*()`; wrappers override individually. Definitions only — no top-level geometry or assignments. |
| `src/components/*.scad` | **Editable.** Thin wrappers: customizer block + `use <../../lib/...>` + a `part=` dispatch → one lib call. |
| `src/Full_Turtle.scad` | **Editable.** The full-assembly source (git-renamed from `Full_Turtle_v1.scad`). M7 pending: still holds embedded geometry, not yet `use`-ing lib. |
| `Full_Turtle_v1.scad` | **GENERATED** by `build/build.py` from `src/Full_Turtle.scad`. Self-contained, committed, downloadable. Do not hand-edit (a banner says so). |
| `scads_v1/*.scad` | **GENERATED** bundles from `src/components/*.scad` + `lib/`. Eight files named after their `src/components/` wrapper (no `_v1` suffix — the folder carries it); each is a self-contained single-file download. |
| `build/` | `scad_lib.py` (helpers), `bundle.py` (inline `use`/`include`), `build.py` (regenerate all bundles = the sync step), `lint.py`, `test.py`, `baseline.py`, `export_stl.py`, `manifest.json`, `README.md` — Python 3 stdlib only. Exceptions (need the sim venv, section 20): `export_sim.py` (installed meshes + ruler datums → `sim/generated/`) and `export_fin_dxf.py` (fin CUT/ENGRAVE DXFs → `fabrication/fins/`). |
| `lib/fin_ruler.scad` | **Editable.** Shared 0.3 mm-deep vector ruler engraving (font-free digits) used by `lib/head_fin.scad` and `lib/rear_fin.scad`, and by `src/Full_Turtle.scad` for ruler datums (v6.6.0). |
| `sim/`, `physics/`, `run_sim.sh` | Turtle_Sim buoyancy workbench (v6.6.0) — see **section 20**. `physics/components.yaml` is the distributed measurement template (unknowns null). |
| `docs/` | `sim_roadmap.md` (Turtle_Sim plan), `buoyancy_measurements.md` (physical survey), `generator_sync_pending.md` (record of the v6.6.0 website sync). |
| `tests/expected_bounds.json` | Regression baseline (per-render bounding box + tris + known warnings) checked by `build/test.py`. `tests/baseline/` holds the full per-render dumps. |
| `VERSION.json` | Single set-level version + bump rules + changelog. STL exports carry this version in their filename. |
| `turtle_body_full_inventory_<version>.svg` | **GENERATED** by `build/export_inventory.py`: every wooden piece in one Turtle, 1:1, labelled. Only the current version is kept here; a copy goes to turtle_labels (section 21). Do not hand-edit. |
| `stls_v1/` | Fabrication exports, written on demand by `build/export_stl.py` as `<name>_v<version>.stl`. The pre-refactor un-versioned STLs were deleted at v1.6.0; the v1.7.0/v1.7.1 set was cleared at v1.10.0 so only the current version's files remain. Current printable set (all `_v6.6.3`): cap, cage, the combined mold layout (`Silicone_Ring_Mold`) and its two plates (`Silicone_Ring_Mold_bottom` / `_top`), plus the experimental `Turtle_Pressor` (printed prototype of a part meant to be cut from board, section 13a). No sail shaft STL — the shaft is an Ø5 steel rod since v6.4.0 (manifest `export_stl: false`). `stls_v1/gear_housing/` holds gear-housing STLs that the build scripts do not generate or manage. F6-verified, not physically validated. |
| `README.md` | Project overview and generator intent |
| `LICENSE` | CERN Open Hardware Licence v2, Strongly Reciprocal |

OpenSCAD is required for `build/lint.py`, `build/test.py`, `build/baseline.py` and
`build/export_stl.py` (2021.01 was used for the baseline). Scripts find it via
`$OPENSCAD` → `PATH` → `~/.local/bin/openscad` → the macOS app bundle. `build/build.py`
and `build/bundle.py` are pure Python. There is no CI service — everything runs locally.
The Python geometry generators described in section 14 live in the HopeTurtles.org
repository (`/home/russs/WebstormProjects/hopeTurtles.org/generator/`), not here; section 19 is the contract between
the two.

## 4. Important differences to reconcile

These are observations, not permission to overwrite the repository with older versions.

| Component | Conversation's latest delivered standalone state | Inspected repository state |
| --- | --- | --- |
| Cap roof and boss | 4 mm roof + 6 mm boss, 10 mm bearing length | Standalone cap has **5 mm roof + 2 mm boss**, 7 mm bearing length |
| Axle interface assumptions | 4 mm cap roof, 6 mm boss, 58 mm overall axle | Standalone axle still has these assumptions; it has not followed the cap's 5/2 mm settings |
| Full assembly cap | Standalone evolved to twin narrow grooves and a boss | Full assembly still uses 8 mm roof, no corresponding internal boss, and one 13 mm-wide × 1.1 mm-deep band channel |
| Full assembly axle | Standalone shortened to 58 mm and has magnet pocket | Embedded full-model axle still uses the older roof-based length and lacks the standalone magnet recess |
| Sail attachment details | No C-piece bores, no non-sail-batten bottom bores, brown bottom rails | Standalone sail file incorporates these changes; full assembly still has old bores and orange bottom rails |
| Seal ring | Implemented 5 mm radial width; 3.5 mm later suggested | Mold still uses **5 mm radial width**; the narrower suggestion was not implemented |
| Python generators | Delivered for rear fin, ballast and sails | Present in `/home/russs/WebstormProjects/hopeTurtles.org/generator/` (plus a 6FC Ecojoiner generator), but drifted from `lib/params.scad` — see section 19 |

The repository's 5 mm roof/2 mm boss appears to be a later edit outside the conversation. Preserve it unless the user requests otherwise. It changes the cap-to-axle relationship: the 58 mm axle's round end is 34 mm below the bearing face, so it extends 29 mm beyond a 5 mm roof, rather than the 30 mm assumed by its parameter comments. This is a dimension mismatch to evaluate, not proof that it cannot assemble.

The standalone sail SCAD contains inherited cap-related variables even though cap geometry is not emitted. Do not interpret those unused settings as the current manufactured cap specification.

## 5. Shared dimensions and reference rules

Current principal foundation values:

| Parameter | Value | Meaning |
| --- | ---: | --- |
| Bottle outside diameter | 82 | Shared body/port sizing reference |
| Bottle total height | 305 | Includes the ordinary bottle cap |
| Ordinary bottle-cap diameter | 31 | Distinct from the large control-cap disk |
| Ordinary bottle-cap height | 17 | Used in rear-fin and ballast formulas |
| Collar diameter | 34 | Independent of cap diameter |
| Top / bottom dome heights | 62 / 25 | Canonical bottle profile |
| Wooden stock thickness | 12 | Shared stock; do not create conflicting subsystem defaults |
| Fin-board width | 93 | Shared fin-system stock dimension |
| Ecojoiner port length / height | 82 / 82 | Axial port length and opening height are separate concepts. **Port length is derived**: `p_port_length() = p_top_dome_h() + p_port_allowance()` (62 + 20). It was a fixed 82 until 2026-09-08 (v1.7.2), which was wrong for any bottle whose taper differs from the reference |
| Rear solar panel W × H × T | 148 × 223 × 2.5 | Actual panel dimensions, not wooden holder thickness |

For the current control-cap insertion model:

```text
bottle nominal inside diameter = 82 - 2 × 0.5 = 81
control-cap insert diameter = 81 - 2 × 1 = 79
control-cap disk diameter = 100
cage inner diameter = 100 + 2 × 1 = 102
cage outer diameter = 102 + 2 × 6.5 = 115
```

The 0.5 mm bottle wall and circular 81 mm interior are modelling assumptions. Real bottles may be oval or vary with axial position. Do not treat nominal dimensions as caliper measurements.

An earlier standalone cage used a 94.5 mm cap and 96.5 mm cavity. That is a different sizing family. Do not combine it silently with the current 100/102 mm pair.

## 6. Control cage: geometry and history

> **FABRICATION CONSTRAINT — the cage is 3D-printed ROOF-FACE-DOWN.** The flat
> top surface goes on the printer bed (the wrapper's `part="print"` pose flips
> it). Every change to the roof top must stay self-supporting in that
> orientation: bevels/chamfers on the roof-top edge must flare **outward** as
> they rise from the bed (≤ 45° from vertical), never undercut; do not add a
> downward-facing pocket, lip or overhang to the roof top. A change that would
> need support material in the roof-down pose must be **flagged to the user**,
> not silently made. The horizontal M3 bores bridge in the slicer. The
> recessed clip pocket around the axle is OFF by default since v1.10.0
> (`control_cage(top_pocket = false)`) — no shaft clip at this prototype
> stage. `p_cage_roof_bevel()` (default 3 mm) is a true 45°
> outward chamfer that runs the full roof-top outer edge — the four batten
> grooves are chamfered along with everything else, not masked out, so no
> groove wall stands proud of the bevel. Printable as-is (single
> `rotate_extrude` cutter, radius only grows from the bed upward).

The cage is an inverted, open-bottom rotating cup. The circular roof is supported above the fixed cap by eight downward-facing hemispherical bumps. Those bumps were initially misread from the drawing as holes in a bottom plate. **There is no bottom plate and those eight features are solid hemispheres.**

The design evolved from a continuous cylindrical skirt with four grooves to a continuous sinusoidal annular wall. Separate extended tabs, widened shoulders and triangular gussets were intermediate designs. The user ultimately requested that the wall peaks stand on their own, with the batten mounts centred on them. Do not reintroduce separate tab components by default.

| Current cage dimension | Value |
| --- | ---: |
| Inner / outer diameter | 102 / 115 |
| Radial wall thickness | 6.5 |
| Roof thickness | 4 (was 6 through v1.9.1; roof underside fixed, top dropped 2 mm) |
| Original skirt depth | 44 |
| Extra peak extension | 20 |
| Maximum wall depth below roof | 64 |
| Minimum wall depth between mounts | 10 |
| Roof-to-tip overall height | 68 (was 70) |
| Groove count / width / depth | 4 / 22.5 / 3.7 |
| Mount holes | Two Ø3.2 holes per groove, eight total |
| Mount-hole vertical pitch | 32 |
| Lower hole distance from peak tip | 10 |
| Bearing bumps | Eight Ø9 hemispheres |
| Bearing pitch-circle diameter | 91.5 |
| Centre shaft hole (round; Ø8.2 for the old PLA shaft, a 10.3 AF hex before TB-08) | 5.4 (Ø5 steel rod + 0.4) |
| Set screw (TB-08) | **OFF since v6.0.0** (`p_cage_setscrew_enabled()` / wrapper `setscrew`, which also drops the recess) — the sail crossbar connector's M3 clamps the shaft instead. When on: single radial M3, pilot Ø2.5, aimed at the centre of the roof button opening (follows `button_angle`), at the vertical centre of the access recess (Z 4.75 installed) — v4.1.2 |
| Centre hub / top pocket diameter | 29 / 26 (top pocket OFF by default since v1.10.0 — `control_cage(top_pocket=false)`) |
| Pocket depth | 4 (only when `top_pocket=true`) |
| Button opening / centre radius | 18 / 25 in `lib/params.scad`; the standalone cage wrapper uses r 23.2 to match the cap (v6.5.2: opening back to Ø18 from Ø22 — the Ø22 only existed to uncover the hub's set-screw face, and the set screw is off; the hub-bite assert now applies only when `setscrew = true`) |
| Set-screw access recess | 5 wide × 3 deep, flat floor at r 11, full hub height Z 1 → 8.5, open end to end (`p_cage_setscrew_recess_*()`) — v4.1.2 |
| Hub bottom above cap face | 1 mm gap (bearing tips carry the cage; hub is a tilt backstop — keep) |

The wave uses `cos(4*a)`: maxima in wall depth align with 0°, 90°, 180° and 270°; minimum wall depth is halfway between. Cosine is simply the chosen phase of the sinusoidal profile.

The standalone cage uses an installed reference where bearing tips touch cap Z=0. Roof underside Z=4.5, roof top Z=8.5 (was 10.5 before the 4 mm roof), longest wall tip Z=-59.5. Hole centres are Z=-17.5 and -49.5. The print view flips the model so the roof faces the bed. Its other view raises the longest wall tips to Z=0.

The recessed clip pocket that used to sit around the axle in the roof top is gone by default — `control_cage(top_pocket = false)`. It was there for a shaft retaining clip that this prototype stage does not use; `p_cage_pocket_d()` / `p_cage_pocket_depth()` and the wrapper's `top_pocket` checkbox bring it back. Removing it also let the roof drop to 4 mm without tripping the old "shaft / clip axial clearance" assert.

The full assembly and sail frame use different native translations. Compare physical interfaces after transforms, not raw Z values from different files. The cage's standalone button angle is 90°; the full model may apply a 90° installation rotation to a local 0° opening.

The wave mesh has four vertices per angular station, triangulated faces and consistent OpenSCAD face winding. Keep it closed, preserve the bore, and use a small Boolean overlap at the roof junction. Numerical topology checks were performed previously; this does not establish structural strength or F6 validity.

Historical Ø2.8 M3 pilot holes, three-hole asymmetric patterns and M3 countersinks belong to earlier cage revisions. The current cage uses **two Ø3.2 clearance holes per mount**. Do not confuse a clearance hole with a thread-biting pilot hole.

## 7. Control cap and centre boss

The large cap disk is stationary; the cage rotates above it. Its insert goes into the cut bottle body. Do not confuse this control cap with the bottle's original Ø31 mm screw cap.

Current repository standalone dimensions:

| Feature | Value |
| --- | ---: |
| Disk diameter / roof thickness | 100 / 5 |
| Boss outside diameter / inward projection | 18 / **0 — removed in v6.5.1, cavity ceiling is flat** (was 2, then 1.5) |
| Nominal total axle-bearing length | 5 (roof only; was 7) |
| Axle bore diameter | 6 (0.5 mm radial clearance to the Ø5 steel rod, v6.4.0; was 8.6/8.7 for the Ø8 PLA shaft) |
| Insert outside diameter / length | 79 / 35 |
| Insert wall thickness | 4 |
| Nominal total cap height | 40 |
| Button holes | Two Ø17 at ±24 along Y |
| Entry chamfer height / diameter reduction | 1 / 1 |
| Axle O-ring gland (in the bore) | Ø8.5 groove root × 2.6 wide, centred 2.5 mm below the outer face (mid-roof since v6.5.1; was 3.5) |

The boss is an integral cylindrical collar on the hollow underside. It does not protrude onto the flat surface facing the cage. The centre bore must pass through both roof and boss, and the cavity subtraction must not erase the boss. Ensure a positive overlap connects it to the roof.

Rationale from the conversation: an 8 mm roof resists flex and provides a longer axle bearing, but distributes material across the entire disk. A thinner roof plus a local boss concentrates support around the axle. A longer bore does not eliminate the 0.5 mm radial clearance between the Ø5 steel rod and the Ø6 bore. No stiffness or wear optimization has been physically verified.

**Axle O-ring gland (rotary seal).** The bore now carries an annular groove
(`oring_gland`, default on) that seats a round-section O-ring against the
spinning Ø5 steel rod, closing the 0.5 mm radial bore gap as a water path. The
gland root is Ø8.5, 2.6 mm axial, centred 2.5 mm below the cap outer face
(mid-roof) — lands of ~1.2 mm remain each side within the 5 mm bore column.
Parameters: `p_axle_oring_cs()` (2.0), `p_axle_oring_id()` = `p_axle_round_d()`
(5 — tied to the shaft), `p_axle_oring_od()` (9), `p_cap_oring_gland_*()`. `control_cap()`
asserts the gland OD sits between the bore and the boss wall and that the
groove + lands fit the bore column — a change that violates either is flagged,
not silently made. The O-ring is cast in the two-part mold (section 8). Not
physically validated: squeeze (0.25 mm radial), dynamic friction on the
rotating shaft, and silicone durometer all need a real test.

## 8. Silicone grooves, rings and mold

Two grooves are required on the insert body:

- Axial height: 2 mm each.
- Radial depth: 2 mm each.
- Centres: 12 and 25 mm from the insert shoulder, not from the disk's outer face.
- Groove root diameter: 79 - 2 × 2 = 75 mm.
- Remaining nominal insert wall at each groove: 4 - 2 = 2 mm.

Current mold geometry produces two flat annular rings:

| Dimension | Implemented value |
| --- | ---: |
| Inside diameter | 75 |
| Radial width | 5 |
| Outside diameter | 85 |
| Axial thickness | 1.5 |
| Projection beyond Ø79 insert | 3 radially |
| Mold floor / outer wall thickness | 3 / 3 |
| Two-mold layout envelope | 190 × 91 × 4.5 |

The molds are open on top. Their centre islands and outer rims share a scraping plane. The user intends to fill them with commercial silicone from a caulking gun. No shrinkage correction is applied. Cure time, release compatibility, adhesion and final hardness depend on the actual product and need checking before fabrication instructions become definitive.

The proposed seal is **not validated**. An Ø85 ring inside the assumed Ø81 bottle requires 2 mm radial deflection. It may bend into a lip, wrinkle, roll or distort the bottle. A 3.5 mm radial-width ring, giving Ø82 outside diameter and 0.5 mm radial interference, was suggested as a less aggressive prototype. The user did not ask to implement that reduction, and the committed mold still has 5 mm width. Do not report the narrower ring as built or tested.

Measure the actual bottle interior at both groove positions and along perpendicular axes before concluding the seal is suitable. This ring does not make the entire cap watertight: the axle and button openings are separate interfaces.

### One two-part pressed mold — flat rings + the axle O-ring together

`lib/silicone_ring_mold.scad` is a single **two-part pressed mold** that casts
in one session:

- `ring_count` **flat insert-seal rings** — Ø75 ID / Ø85 OD × 1.5, tied to
  `p_seal_groove_root_d()`, scrape-filled in the bottom plate.
- **`ring_count` axle O-rings** — round cross-section, one nested in the centre
  of **every** flat-ring mold ("an additional mold circle" per ring), so the
  default 2-ring mold casts **two** O-rings and you get two chances at a good
  one. ID = `p_axle_oring_id()` = `p_axle_round_d()` (**5 — tied to the Ø5
  steel sail-shaft rod, v6.4.0**), CS `p_axle_oring_cs()` (2), OD 9.
  Each torus is split across the two plates (lower half in the bottom, upper
  half in the top).

`part` values: `mold` = **the printable layout** — both plates laid flat and
side by side, working faces up, so the single exported STL prints both halves
in one job (no support); `mold_bottom` / `mold_top` = the same plates alone
(channels/pegs/holes up); `rings` = every cast ring; `oring` = a bare O-ring
torus. **Three male pegs** on the bottom plate (in the 8 mm rim, 120° around
the first mold) seat in **three female holes** in the top plate so the halves
cannot shift when pressed; each O-ring fill + vent runs through the top plate.
Process: scrape-fill the flat channels, fill each O-ring lower half, press the
top plate on (pegs → holes), cure, split, peel out `ring_count` flat rings +
`ring_count` O-rings.

Neither seal is validated. The O-ring's radial squeeze, the dynamic friction
of a silicone lip on a rotating steel rod, and demoulding a round ring from a
pressed mold without flash all need real testing. Casting two O-rings per
session is a yield hedge, not a fix for any of those.

## 9. Sail shaft and magnetic sensing

> **v6.4.0 — the shaft is an Ø5 steel rod, not a printed part.** `p_axle_round_d()`
> = 5 (was an Ø8 printed PLA shaft). `lib/sail_shaft.scad` / `Bottle_Sail_Shaft.scad`
> now only document the rod's **cut length (59 mm)** and the magnet-recess
> position; the model is a reference, not a print. Its manifest render has
> `export_stl: false`, so `build/export_stl.py` does not write a shaft STL — do
> not add one back to the printable set. Mating holes followed the rod: cap bore
> Ø6, cage hub bore Ø5.4 (`p_axle_shaft_hole_d()` = 5 + 0.4 diametral clearance),
> sail crossbar connector Ø6 (`p_sail_connector_axle_hole_d()`), axle O-ring ID 5.
> The TB-08 note below is kept for history; its Ø8 / Ø8.2 / 0.2 mm values are
> superseded.

> **TB-08 (2026-09-22) — the axle is now a uniform round shaft, no hex.**
> `lib/hex_shaft.scad` / `control_axle()` were renamed to `lib/sail_shaft.scad`
> / `sail_shaft()` (wrapper: `Bottle_Hex_Shaft.scad` → `Bottle_Sail_Shaft.scad`).
> The shaft free-spins in the cap's bore (unchanged, `p_cap_axle_bore_d()`)
> and passes with a light **0.2 mm diametral running clearance**
> (`p_axle_shaft_clearance()`) through both the cage hub bore and the top
> sail bar's own hole — both now `p_axle_shaft_hole_d()` = shaft diameter +
> that clearance = **Ø8.2**, replacing the old Ø12 hex-corner clearance hole
> and the Ø10.3 hex cage bore. The shaft no longer *keys* into the cage by
> shape; instead it is locked to the (rotating) cage by a single radial M3
> **set screw** through the cage hub wall (`p_cage_setscrew_pilot_d()` /
> `lib/control_cage.scad`; since v4.1.0 it points into the roof button opening) that presses directly
> against the shaft. This is a **hardware interface break**: an
> old hex shaft will not engage a new cage (no more hex bore), and a new
> round shaft will not stay put in an old cage (nothing to press against
> without the set-screw hole). The cap needed no change — its axle bore was
> already round and already sized only for the shaft's uniform diameter.

The earlier 100 mm hex shaft, coupler ideas and 50 mm stepped axle are historical, as is the 10 mm-AF hex section itself (TB-08 removed it). The latest delivered shaft:

| Feature | Value |
| --- | ---: |
| Material | Ø5 steel rod (v6.4.0) — cut to length, not printed |
| Diameter (uniform, whole shaft) | 5 |
| Nominal length inside cap | 35 |
| Upper length (through cage hub + sail crossbar connector) | 23 |
| Overall (cut) length | 59 |
| Magnet recess | Ø3 × 1 deep in the lower end, adjustable (must be drilled into the steel end; how the AS5600 magnet behaves on a steel rod is an installation check) |
| Cap bore | 6 (0.5 mm radial clearance) |
| Cage hub bore | 5.4 (shaft + 0.4 mm diametral clearance) |
| Sail crossbar connector hole | 6 (clearance, not a bearing) |
| Frame / cage lock | v6.0.0: M3 through the side of the sail crossbar connector, Ø2.8 pilot, pressing on the rod (the cage hub set screw is switched off; untested) |

The nominal round-in-cap length is `30 inside cap + 5 roof + 1 external extension` (TB-03/TB-04 datum). The 30 mm measurement starts at the roof underside and includes the boss; do not add the boss again. The magnet recess opens at the lower end for an AS5600 sensing magnet. Sensor-to-magnet distance and orientation remain installation checks.

The 23 mm upper length (unchanged from the old hex length) was originally lengthened from 20 mm when the cage roof increased from 3 to 6 mm, and the stack check that sizes it (shaft must reach through the cage roof + sail bar) is unchanged by TB-08 — only the cross-section changed from hex to round. The centre hub is not proof of a complete axial retention mechanism; the set screw provides rotational lock, not axial retention, and neither has been physically validated (thread engagement into printed PLA, torque before stripping, and how much axial float remains all need a real test).

## 10. Sail apparatus and mounting-hole rules

The standalone sail apparatus emits the wooden frame, four battens, reinforcements, C ends, sails and optional hardware previews. It emits no cage, cap, bottle or axle. The default assembly is an inspection view, not a fabrication layout.

| Feature | Current value or rule |
| --- | --- |
| Wood thickness | 12 mm |
| Batten height / width / radial thickness | sail 217 (205 + t) · non-sail 178 (top flush with the cage roof top) — v6.1.0 / 20 / t = 12 mm (board stock since v6.5.0; separate 10 mm stock before) |
| Top crossbar span (tip to tip) / width / thickness | 504 (`p_top_crossbar_len()` = 6 × bottle d; 843.6 in v6.1.0 only) / 22 / 12 mm — **three pieces since v6.0.0**, see below |
| Crossbar halves (×2) | 212.2 mm (derived from the span; v6.1.0's 382 reverted in v6.2.0), on top of the connector, from 15 mm inboard of each sail batten out to the tip |
| Sail crossbar connector | 163.6 mm (159.6 before v6.5.0), on the cage roof, 15 mm past each sail batten's outer face; Ø6 shaft hole (v6.4.0) (clearance, not a bearing) |
| Shaft clamp | one M3 self-tapped from the connector's +Y side face into a Ø2.8 pilot, pressing on the shaft (untested in wood) |
| Half-to-connector screws | one M3 per side, Ø3.2 clearance in the half, Ø2.8 pilot in the connector, centred in the connector overhang |
| Sail-batten upper notch | 2t = 24 mm tall (connector + half), 15 mm of batten above it (v6.1.0; 27 in v6.0.0) |
| Bottom rail length | 264 mm = 3 × bottle diameter + t (`p_bottom_rail_len()`, v6.3.0; 252 in v6.2.0, 360 in v6.1.0) |
| Bottom rails' bottle clearance | 1 mm nominal |
| Cage mounting holes | Two Ø3.2 per batten, 32 mm pitch |
| Hole centres from batten top | sail battens 65 and 97 mm; non-sail 26 and 58 mm (v6.1.0) |
| Hole centres from batten bottom | 152 and 120 mm (unchanged by v6.0.0) |
| Top and bottom rail colour | Brown `[0.56, 0.39, 0.39]` |
| C-piece colour | Orange, retained |

**Split crossbar (v6.0.0).** The 504 mm one-piece top bar was too long a board. It is now two halves plus a centre *sail crossbar connector*. The connector lies on the cage roof and spans the two sail battens; the halves sit on top of it, and both layers half-lap into the same 24 mm sail-batten notch. The batten bottoms, cage M3 holes and lower rails did not move — the battens grew 24 mm at the top (12 for the second layer, 12 extra above). The sails grew 12 mm taller (top edge follows the half underside). v6.1.0 tried shared cut lengths (halves 382 = head-fin slats, bottom rails 360 = ballast slats); v6.2.0 reverted them — the sails came out too big and top-heavy. Non-sail battens end flush with the cage roof top (kept from v6.1.0). The connector's side M3 is now the frame-to-shaft lock; the cage hub set screw is switched off (section 6). Sail `part` values `top_bar_half` / `top_bar_connector` replace `top_bar`. Not built or tested.

The two sail battens have upper and lower interlocking slots. The perpendicular non-sail battens retain their lower slots and C retainers, but no upper sail-crossbar slot.

Final screw-hole decisions:

1. Retain both M3 cage holes in all four battens.
2. Remove the tangential M6 bores from the orange C pieces.
3. Remove the corresponding bottom bores from the non-sail battens in both assembly and individual-part outputs.
4. Preserve unrelated M6 reinforcement joints unless explicitly changed.

Some source functions still accept `include_non_sail_joint_hole`; current output calls pass false. Unused optional cutters are not proof that a hole is emitted. Inspect call sites and rendered output.

The cage and frame must use common radial and vertical datums. For the current native sail coordinates, roof top is Z=50, original skirt underside reference is Z=44, mount holes are Z=22 and -10, and the batten bottom is Z=-128. Translating the standalone frame for display must move every mating part equally.

## 11. Rear fin and rear solar support

The rear assembly consists of one yellow vertical fin, two green bottle-holder shafts and one red solar crossbar. The separate panel is reference geometry in the standalone rear-fin file; its F5 background display is excluded from F6/STL there. The full assembly uses a visible panel and visual fasteners instead.

Shaft formula (v5.3.0, user-directed — supersedes the earlier "approved" 334 mm; v5.7.0 fin width):

```text
fin_width    = fin_board_width = 93            (v5.7.0: was board + 15 mm "rear tab" = 108,
                                                 wider than the board it is cut from — do not restore)
shaft_rear_x = fin_width - 2*wood_thickness = 93 - 24 = 69
shaft_length = bottle_height + (2/3)*(fin_board_width - 2*wood_thickness) - cap_height + shaft_rear_x
             = 305 + (2/3)*(93 - 24) - 17 + 69 = 403 mm
```

Every sawn wooden part must fit within the builder's max board width; the HopeTurtles.org
generators enforce this (`common.board_width_errors()`).

**The bottle base abuts the yellow fin's front edge (rear-local X = 0)** — the fin holds the bottle in its port. Until v5.3.0 the full turtle seated the bottle base at the shafts' rear end (X = 84), which put the first 84 mm of the fin inside the bottle; the shafts were lengthened by exactly that overlap (84 then, 69 since v5.7.0) so their front end and John hole pair did not move (`p_rear_shaft_hole_from_front()` stays 113). Do not re-seat the bottle at `rear_shaft_rear_x`. The 334 mm, 310.5 mm and other older results are superseded.

The green/yellow common overlap is X=0..69 (0..84 before v5.7.0). Split it at X=34.5: yellow slots open from the front, green slots open from the rear. Two slots cut into the same end do not form a functioning interlock. The nominal engagement depth is 34.5 mm (`p_rear_half_lap_engagement()`, was 42).

Both half-lap clearance and solar-joint clearance are 0.2 mm **total** extra width, centred on the mating 12 mm board. Thus slot openings are 12.2 mm, not 12.4 mm. Root clearances are also symmetric. Do not add clearance to the wooden part's thickness or move the nominal installation datum.

**Green shaft width = Ecojoiner John height** (`p_rear_shaft_width()` = port height − 2 × stock, 60 mm at defaults; v5.4.0 — was a fixed 59). The shaft bolts flush against a Little John, so their edges and M5 pairs must line up; a full-turtle assert enforces it. Downstream, the fin generator derives it from the fit-adjusted port height (57 mm at "Very Tight").

The red crossbar is 148 mm long, 36 mm high and 12 mm thick. The actual panel is 148 × 223 × 2.5 mm: width along local Y, length/height along local X, thickness along Z. It extends forward from the crossbar. Panel thickness is independent of stock thickness.

Standalone rear shafts use a 50 mm mounting-hole offset from their front. The full assembly computes the offset from the mating John, yielding 103 mm at current defaults. Preserve that distinction until the standalone/full mounting interface is deliberately unified. (Since TB-07 both use the derived value, 113 mm after v4.2.0. Since v5.0.0 that position carries an **M5 hole pair** (Ø5.2 bite holes since v5.1.0) at ±18 mm (since v5.2.0) across the 59 mm shaft width, matching the John clamp pair; see section 13.)

In the full Turtle, the rear assembly belongs at the physical 3-o'clock/back port and is rotated 180° around the bottle axis so the yellow fin points downward. Earlier 9-o'clock placements were corrected. Do not infer the port from a screenshot alone.

**Fin rulers (v6.6.0).** Both the rear fin and the head fin carry a signed-millimetre ruler engraved 0.3 mm deep on **both** broad faces (`lib/fin_ruler.scad`, `fin_ruler_recess()`). Zero is the horizontal bottle-axis centre plane; values increase physically upward. Rear zero is `rf_ruler_zero()` (lower shaft top + bottle radius); head zero is local Z = 0. Ruler columns follow joint placement (`fr_x()`, `fr_joint_margin()`). The engravings are the buoyancy workbench's calibration datum (section 20); keep `lib/fin_ruler.scad`, `build/export_fin_dxf.py`, `build/export_sim.py` and the website's shared ruler geometry in step if a fin outline, a joint or the bottle-axis datum moves. `build/export_fin_dxf.py` writes face A (CUT + ENGRAVE) and face B (ENGRAVE only, mirrored about X = 0) for each fin. Engraving depth and face registration are not physically tested.

## 11a. Head fin (front fin) — EXPERIMENTAL, v5.8.0; raked profile since v6.3.1

`lib/head_fin.scad` + wrapper `src/components/Turtle_Head_Fin.scad` → `scads_v1/Turtle_Head_Fin.scad` (parts `assembly` / `fin` / `slat`). The rear fin's mirror on the front port (pre-orientation −X, physical 9 o'clock): two purple flat slats above and below the front bottle and one blue vertical raked fin. Not built, fitted or tested. Exported by the HopeTurtles.org generator (`object_type: "head_fin"`) since 2026-10-22, which renders this bundle with the builder's dimensions — so the slats follow `p_port_height()` (the generator adds the fit offset) and **the profile needs 7·t < board width** (4t top edge + 3t cut).

| Feature | Default |
| --- | ---: |
| Slat length × width × t | 382 × 60 (= John height) × 12 |
| Slat reach, bottle base → slat front | 334 (`p_head_slat_reach()` = rear shaft length − rear overlap, so the M5 pair is at the same 113 mm, `p_head_slat_hole_from_front()`) |
| Slat run into the fin / half-lap engagement | 48 (4t) / 24 |
| Fin width (forward) × height | 93 (= `p_fin_board_w()`, cut across one board) × 192: 156 (bottle_d + 6t, 2t beyond each slat) + a 36 mm (3t, `p_head_fin_drop()`) extension below, v6.3.2 |
| Profile (v6.3.1) | top edge runs out to X = 48 (`p_head_fin_heel_x()`, the slat ends); the leading edge slopes down and **forward** to a 36 mm (3t, `p_head_fin_toe_h()`, v6.3.4; 2t before) vertical flat nose at the full width; full-width bottom edge; below the toe the fin drops a further 36 mm with a 45° cut at the bottom front, 36 × 36 mm (`p_head_fin_forefoot_setback()` = `p_head_fin_drop()`, v6.3.3; 18 mm setback in v6.3.2). Superseded: v5.8.0 symmetric spear head, v6.3.0 the mirror slope (full width on top) — do not restore either |

Head-local frame: X = 0 is the fin's rear edge = the bottle base (abutting, like the rear fin since v5.3.0), +X outward; bottle axis at Y = Z = 0; **+Z is physically up** (v6.3.0 — the fin is no longer up/down symmetric, so the full-turtle install maps local +Z to pre −Y). Fin slots open from its rear edge, slat slots from their outer ends, meeting at X = 24; 0.2 mm total clearance as the rear fin. In the full turtle, frame 1 now through-bolts (no acorn) its −X clamp pairs as well as +X, and asserts check the slat M5 pair coincides with the −X John pair and that each slat sits flush against its Little John.

## 12. Ballast attachment

Six wooden components: two green core slats, one orange bottom board, two red lock feet and one yellow ballast fin. No bottle is included in the standalone artifact.

| Feature | Default |
| --- | ---: |
| Core slat width | 82 - 2 × 12 = 58 |
| Core slat length | 305 - 17 + 6 × 12 = 360 |
| Clear gap between core slats | 82 |
| Slat centre spacing | 82 + 12 = 94 |
| Mount holes (v5.2.0) | M5 bite-hole pair, Ø5.2, 12 mm in from each long edge (matches the John clamp pair) |
| Mount-pair distance from top | port_length + 12 - 17 = 77 |
| Upper 45° shoulder cut from top (v5.6.0) | max(port_height, port_length) + 12 = 96 — starts at/below the outer John's port end (94); was port_height (84), 10 mm inside the John |
| Bottom board length × width | 3.5 × bottle_d + 2 × 12 (318 at Ø84) × 93; 3t solid past each foot slot, 20 × 20 mm 45° chamfers on both front (foot-slot-edge) corners — v5.5.0 |
| Lock-foot width × height | 60 × 60 |
| Yellow fin length × height | 246 × 93 |

Use clear inner-face spacing, not centre spacing, when checking bottle clearance. The yellow fin's bottle-seat cut was enlarged by one stock thickness to stop it intersecting the bottle. Preserve that correction.

Ballast mounting transforms reference the Ecojoiner port entrance and insertion length. Do not replace them with a visually estimated translation. The standalone output preserves local assembly relationships and raises the lowest component to Z=0.

Slots in the ballast extraction retain nominal stock widths; the rear fin's 0.2 mm fit allowance was not automatically added to ballast joints.

## 13. Ecojoiner-only output

The standalone extraction (`eco_ecojoiner_only()`) contains six Long Johns, six Little Johns — one of which is the **Master John** — four Final Keys and the visual M5 clamp hardware (see below). The Master John is a Little John whose two top slots are cut to `eco_master_slot_depth()` (34 mm at reference params) rather than the standard `eco_slot_depth()` (29 mm); everything else — outline, collar hole, M5 holes, placement — is identical. It is the piece fitted last, and the deeper slots are what let it drop past the already-seated Johns into the almost-closed frame. Restored in v1.8.1 (it had been flattened to a plain Little John in the v1.7.1 generator sync). The full-Turtle assembly (`ecojoiner_and_bottles()` in `src/Full_Turtle.scad`) does not flag a Master John, so its six Little Johns stay uniform; only the standalone artifact carries one. Talk of additional Saddlers still refers to other revisions, not this file.

**Bottle clamp (v5.0.0 → v5.1.0, 2026-10-09) — the Presser is gone.** Each Little/Master John port end carries **two black M5 × 30 socket-head cap screws** (`p_m5_bolt_len()`), stacked across the John height at ±`p_eco_screw_pair_offset()` (±18 mm; 12 mm in from each long edge, `p_eco_screw_edge_inset()` — 10 until v5.2.0) and still `p_screw_side_offset()` (17 mm) from the John end — four holes per John, 24 screws total. **There is no nut.** Each screw bites into a **Ø5.2** hole (`p_m5_hole_d()`, the builder's own research; slightly over the 5 mm nominal, so the hold relies on fibre springback — unverified here). The screw therefore holds its own position and is adjusted with a hex key from outside. A **black acorn nut** run fully onto the tip bears on the bottle. Off-centre, the round bottle has curved away, so the acorn reach is 16.05 mm (not the 12 mm centreline gap) and the head stands ~5 mm off the John's outer face. Asserts in `eco_assert_valid()` check head/acorn footprint fit and that the screw reaches. Hardware is visual only (ISO 4762 / DIN 1587 nominals) and **kept deliberately plain for fast renders** (v5.1.1): the screw is two cylinders, no thread, no socket, no chamfer; holes are $fn 16. Do not add cosmetic threads. Do not reintroduce the presser disk, the jam nut or the wing head (v5.0.0's interim hardware).

On the four ports where the rear-fin shafts / ballast core slats fill the gap (the `suppress_*_port_pressers` flags, names kept from the presser era), the screw pair bites through John + slat with **no acorn**, backed out so the bare tip just meets the bottle (4.05 mm past the slat; head stands off ~1.95 mm). This resolved v5.0.0's 35 mm-bolt interference. Not physically tested.

Current references: 12 mm stock, 82 mm port length (derived: top dome 62 + 20 mm allowance), 82 mm port height, 31 mm cap diameter, 34 mm collar diameter, Ø5.2 M5 bite-hole pairs and 0.2 mm slot fit allowance. Bottle dimensions are sizing inputs only; the Ecojoiner-only model must not emit bottle solids.

## 13a. Pressor — EXPERIMENTAL, v6.6.1

`lib/pressor.scad` + wrapper `src/components/Turtle_Pressor.scad` → `scads_v1/Turtle_Pressor.scad` (parts `assembly` / `pressor` / `profile`). The file always outputs ONE piece (v6.6.3): the default is `part="pressor"`, and the assembly view shows one pressor in its port, with the bottle and John as F5-only references. It does not model the M5 screws (v6.6.2). `part="pressor"` is exported as `stls_v1/Turtle_Pressor_v<version>.stl` for a 3D-printed prototype, printed flat on its board face; the edge holes print as horizontal bores. This is meant to replace the acorn nut on each Little John's M5 pair. Two pressors per port, one each side of the bottle, hug it between them. Not built, fitted or tested. **Standalone only:** the Ecojoiner and full-turtle assemblies still show acorns (section 13), no website generator emits it, and it is not in the slat inventory (section 21).

| Feature | Default |
| --- | ---: |
| Stock | one 12 mm board (`p_wood_t()`); the sketched shape is the board face, thickness runs along the bottle axis, centred on the screw pair 17 mm in from the John end |
| Width (back edge → inner edge) | 32 = port gap 12 − travel 1 + wrap 21 |
| Height | 83.8 = port height − 0.2 fit clearance (slides between the Long Johns) |
| Inner cut | concave arc, bottle radius, centred on the bottle axis; symmetric top/bottom (no diagonal); runs out at ±36.4, corners beyond stay square |
| Wrap past the bottle tangent | `p_pressor_wrap()` = d/4 = 21 |
| Screw travel | `p_pressor_travel()` = 1: pressed, the back edge stands 1 mm off the John face |
| M5 holes | two Ø5.3 holes (`p_pressor_hole_d()`, v6.6.2; the Johns keep Ø5.2) at ±18 (`p_eco_screw_pair_offset()`), mid-thickness, 10 deep (`p_pressor_hole_depth()`) |
| Wood around a hole / beyond the tip | 3.35 each side / 5.05 to the bottle (asserted ≥ `p_pressor_min_wall()` = 3) |
| M5 × 30 head standoff (pressed) | 7 mm off the John's outer face |

How it works: each screw bites into both the John and the pressor, so turning it in carries the pressor toward the bottle; turning it out backs the pressor off. Local frame: X = 0 at the pressor's back edge, +X toward the bottle; Y across the port, centred on the bottle axis; Z = board thickness. `pressor_assert_valid()` checks the travel leaves wood on the centreline, the arc stays inside the block and covers the screw lines, there is enough wood around and beyond the holes, the screw reaches, and the width fits the board. Unverified: whether a Ø5 screw in the 12 mm edge splits the board, how much clamping force the pair gives, and whether 1 mm of travel is enough for real bottle variation.

## 14. Python generation logic

The generators live in the HopeTurtles.org repository at `/home/russs/WebstormProjects/hopeTurtles.org/generator/` (renamed from `ecojoiner/` on 2026-09-08). There is no `generators/` directory in this repository. Section 19 holds the component-to-generator map and the propagation rule; this section records how the scripts themselves behave.

| File in `/home/russs/WebstormProjects/hopeTurtles.org/generator/` | Geometry |
| --- | --- |
| `generate_exports.py` | CLI dispatcher the website runs; no geometry; `OBJECT_MODULES` maps `object_type` → module |
| `objects/ecojoiner_6fc.py` | 6FC Ecojoiner core — self-contained SCAD f-string plus SVG/DXF/PDF writers (renamed from `six_fc.py` 2026-09-08) |
| `objects/back_fin.py` + `back_fin_generator.py` | Rear fin, shafts and solar holder; the reference script owns `build_scad()` |
| `objects/ballast.py` + `bottom_ballast_fin_generator.py` | Ballast assembly and parts (`bottom_fin_raw.py` is an orphan variant) |
| `objects/sails.py` + `generate_sails.py` | Sail apparatus; SCAD only, other formats reported as unsupported |

The reference scripts embed their SCAD source/templates and expose `build_scad(...)` plus a CLI. They do not require a remote file or another SCAD include. Output files use UTF-8; existing output is protected unless `--force` is supplied. The rear-fin generator uses `--defaults` for noninteractive default generation. Consult each script's `--help` before changing CLI contracts. Example commands, run from the HopeTurtles.org root:

```bash
python3 generator/back_fin_generator.py --defaults --output /tmp/rear_fin.scad
python3 generator/bottom_ballast_fin_generator.py --output /tmp/ballast.scad
python3 generator/generate_sails.py --output /tmp/sails.scad
generator/.venv/bin/python3 generator/generate_exports.py --json payload.json --dry-run
```

Maintain one authoritative definition of an input within each generated file. Reject NaN, infinity, nonpositive dimensions and known invalid geometry. Keep Boolean tolerances distinct from fit clearances. When editing an emitted SCAD and its generator, update both and verify generation reproduces the intended source, including comments and selectors where byte-for-byte reproducibility is expected.

The sail generator currently uses targeted first-occurrence replacements for a few top-level controls. Renaming those controls without updating the template replacement logic can silently break parameterization. Its detailed geometry assertions remain in the SCAD; Python validation is not a full geometric solver.

## 15. Editing and verification workflow

**Geometry lives in `lib/` and `src/` only. Never hand-edit a generated bundle**
(`Full_Turtle_v1.scad`, `scads_v1/*.scad`) — a banner in each says so, and
`build/lint.py` fails if one is stale. Editing the full turtle and editing a
component are the same operation: change the shared source, then rebuild
regenerates every dependent bundle. There is no hand-porting between copies.

**Testing policy.** `build/build.py` and `build/lint.py` run on every geometry
change — they are fast and do no meshing. The slow mesh regression
(`build/test.py` and `build/baseline.py`) is **never run automatically by an
agent.** It exists to catch changes in renders you did not open — a new
ERROR/WARNING, an empty mesh, a timeout, or a bounding box that drifted past
tolerance — not to prove geometry is correct. So an agent leaves it to the
maintainer's own visual inspection in OpenSCAD, and only **recommends** a run
(then waits) in the two cases in step 5: a shared-contract edit, or a
pre-commit / STL-release change. A self-contained change whose effect is fully
visible in one OpenSCAD view needs neither the run nor the recommendation.

On **any** geometry change:

1. **Locate the source.** A shared dimension → `lib/params.scad` (as a `function
   p_*()`; add it there once, derive from other `p_*()`). Subsystem geometry →
   `lib/<subsystem>.scad`. A component's customizer surface or `part` dispatch →
   `src/components/<Name>.scad`. Assembly placement / world transform / view
   dispatch → `src/Full_Turtle.scad`.
2. **Edit the source layer only.** Keep derived relationships explicit; keep the
   in-SCAD `assert()`s meaningful.
3. `python3 build/build.py` — regenerates `Full_Turtle_v1.scad` and every
   `scads_v1/*.scad` from `lib/` + `src/`. This is the sync step.
4. `python3 build/lint.py` — bundle freshness, `git diff --check`, `lib/`
   hygiene (no top-level side effects), and an OpenSCAD CSG parse of every
   `lib/`, `src/` and bundle file (catches undefined vars, failed asserts,
   unexpected warnings). Seconds, no meshing.
5. **Decide whether the mesh regression is warranted — do not run it
   reflexively, and never run it automatically.** `python3 build/test.py` meshes
   every component `part` and every `assembly_view` headless and checks each
   against `tests/expected_bounds.json` (nonzero exit / timeout / empty mesh /
   new ERROR line / a WARNING not already in the baseline / bounding box moved
   more than the tolerance all fail it). It is slow (see below) and it detects
   *change in the renders you did not open* — it is not a correctness proof.

   - **Change confined to one subsystem, effect fully visible in an OpenSCAD
     view** (no shared value touched): `lint.py` plus your own visual
     inspection is enough. Do **not** run `build/test.py`, and do **not**
     recommend it — just state what you inspected.
   - **The edit touched the shared contract** (`lib/params.scad`,
     `lib/util.scad`, a shared module's signature, or any value feeding more
     than one subsystem) **or** the change is about to be committed / STLs
     others rely on are about to be cut: **recommend that the maintainer run
     `python3 build/test.py`** — and `python3 build/baseline.py <target>` if the
     dimensional change is intentional — **then wait.** Do not run either
     yourself unless the user asks. If the user declines, record in the report
     that the cross-subsystem regression was not run.

   When a baseline *is* re-recorded, review the `tests/expected_bounds.json`
   diff as the sign-off and add a `note` to each changed entry saying why.
6. **Bump `VERSION.json`.** `+0.0.1` for a component-scoped change (one
   `lib/<subsystem>.scad` or one `src/components/*.scad`); `+0.1.0` for a
   full-turtle-scoped change (`src/Full_Turtle.scad`, a world transform, the
   `assembly_view` dispatch, or a `lib/params.scad` value that moves a mating
   interface); `+1.0.0` for a bottle / board / hardware interface break. Append
   a `changelog` entry: version, date, files, one-line reason.
7. **Report** what changed, which bundles regenerated (`git diff --stat`), the
   `build/lint.py` result, what you inspected visually, and — per step 5 —
   either that no cross-subsystem regression was needed, or that you have
   recommended the maintainer run `build/test.py` (with the result if they ran
   it). STLs are **not** auto-exported — run `python3 build/export_stl.py`
   (writes `stls_v1/<name>_v<version>.stl`) only when new fabrication files
   are actually needed.

8. **Propagate to the HopeTurtles.org generators (section 19).** If the change
   touched `lib/params.scad`, `lib/util.scad`, `lib/ecojoiner.scad`,
   `lib/rear_fin.scad`, `lib/ballast_fin.scad`, `lib/sail_frame.scad`, a wooden
   component's wrapper customizer / `part` surface, or bumped `VERSION.json` by
   a minor or major step: `build/build.py` has already refreshed `build/params.json`;
   in `/home/russs/WebstormProjects/hopeTurtles.org` run `python3 generator/sync_from_turtle_body.py --turtle-body /home/russs/PycharmProjects/turtle_body &&
   python3 generator/check_params_sync.py`, fix any default the checker flags, and
   eyeball each affected `derive_dimensions()` against the vendored bundle (the
   checker does not cover the formula layer).
   If that is out of the task's scope, append an `open` entry to
   `/home/russs/WebstormProjects/hopeTurtles.org/generator/SYNC_LOG.md` and say so in the report. PLA-only
   changes (cap, cage, axle, mold) need neither.

9. **Refresh the label inventory (section 21).** If the change touched any wooden
   part's outline, holes, count or code (`lib/ecojoiner.scad`, `lib/rear_fin.scad`,
   `lib/ballast_fin.scad`, `lib/head_fin.scad`, `lib/sail_frame.scad`, a `p_*()` that
   feeds them, or `INVENTORY` in `build/export_inventory.py`), **or** `VERSION.json` was
   bumped and the change is being released/committed, run
   `python3 build/export_inventory.py`. It renders every wooden part (~20 s) and
   writes `turtle_body_full_inventory_<version>.svg` here and in turtle_labels. If it is out
   of the task's scope, say in the report that the inventory is still at the old version.

Commands from the repository root:

```bash
python3 build/build.py                 # regenerate all bundles + build/params.json — every change
python3 build/build.py --check         # fail if any bundle or params.json is stale
python3 build/export_params.py         # just the p_*() -> build/params.json snapshot (build.py runs this)
python3 build/lint.py                  # parse + freshness (incl. params.json), no meshing — every change
python3 build/test.py                  # cross-subsystem mesh regression — maintainer-run; shared-contract or pre-commit only. accepts target ids: build/test.py control_cap ecojoiner ...
python3 build/baseline.py <target>     # re-record baseline (intentional changes only; maintainer-run)
python3 build/export_stl.py            # versioned PLA-part STLs
python3 build/export_inventory.py      # versioned wooden-slat inventory SVG -> here + turtle_labels (~20 s)
openscad -D 'part="non_sail_batten"' -o /tmp/x.stl 'scads_v1/Turtle_Sail_Apparatus.scad'
git diff --stat && git diff --check
```

Renders are slow under OpenSCAD 2021.01 — the cage is ~90 s per view and a full
turtle view is 2–10 min. This slowness is the reason `build/test.py` is
maintainer-run and scoped (step 5), not part of the automatic loop; it accepts
target ids so a run can cover just the affected subsystem. `rg` may be absent;
use `grep -rn`.

### M7 — wire `src/Full_Turtle.scad` to the lib modules  (COMPLETE)

Every subsystem in the full turtle now flows from `lib/`. `src/Full_Turtle.scad`
went 4656 → 2749 lines. All `assembly_view` and component renders match
`tests/expected_bounds.json` except the one recorded TB-03 change below. What
changed, in order:

- bottle mock-up → `lib/bottle_mockup.scad`; `wood_color` / `m6_bolt_placeholder`
  → `lib/util.scad` (call sites now pass `enable_color_coding`).
- Ecojoiner → `lib/ecojoiner.scad` (`ecojoiner_and_bottles()` calls
  `eco_centered_rectangle(rot, s_pos, s_neg, ecc)` + `eco_inserted_final_key`).
- ballast → `lib/ballast_fin.scad` (`installed_ballast_on_positive_y_port()`
  keeps its transform, calls `local_ballast_assembly(pullout, ecc)`).
- **sail wooden frame → `lib/sail_frame.scad`.** Added `part = "native_assembly"`
  (→ `sail_frame_native_group()`, the frame without the Z=0 raise that
  `"assembly"` applies). The full turtle deleted its 24 frame modules +
  `positioned_*` chain and now calls one `positioned_sail_frame()` that wraps
  `sail_frame(part="native_assembly", …)` in the identical
  `translate(control_assembly_z + cage_bearing_tip_native_z - cage_vertical_position)
  rotate(cage_mount_alignment_angle) rotate(sail_frame_rotation_angle) rotate(180)`
  transform. **TB-01 + TB-02 now apply to the full assembly** (bounds unchanged:
  internal bores + colour; the cage-batten bolt set is 4-fold symmetric so the
  extra 90° in the merged transform is invisible).
- **cut control bottle → `lib/bottle_mockup.scad` `cut_bottle()`** (new; +
  `p_bottle_cut_height()` / `p_bottle_cut_extra()` in params). `positioned_buzdagi_bottle()`
  now calls it; the `buzdagi_*` modules + their dome fns are deleted.
- **rear-fin wooden parts → `lib/rear_fin.scad`.** Deleted `rear_fin_part` /
  `rear_bottle_holder_shaft` / `rear_solar_panel_holder`; the monolith's
  `rear_fin_assembly()` renamed to `full_rear_fin_assembly()` (avoids the
  name clash with `lib/rear_fin.scad`'s `rear_fin_assembly`) and now composes
  `rear_fin()` + `bottle_holder_shaft()` ×2 + `solar_panel_holder()` + the
  kept local `rear_solar_panel()` + `rear_solar_panel_screws()` (the visible
  solid panel + M3 screws — `lib/rear_fin.scad` only carries a `%` panel).
  `solar_panel_width/height/thickness` globals now reference `p_solar_panel_*()`.
  Every derived value verified equal to `lib/rear_fin.scad` first; bounds
  unchanged.

- **control cap → `lib/control_cap.scad`** (TB-03). Deleted `base_body` /
  `plug_outer` / `cup_cavity_cut` / `servo_axle_hole_cut` / `button_holes_cut` /
  the band-channel modules / `control_cap` / `taper_od_at` / local `clamp`; kept
  `button_preview_cylinders`. `top_disk_thickness = p_cap_roof_t()` (was 8.0);
  `control_assembly_z = bottle_cut_height - top_disk_thickness` unchanged, so the
  whole head + sail frame drop 3 mm — **`full_turtle` / `top_sail` Z-max 309.5 →
  306.5**, the only axis that moved, `core` unchanged. Baseline updated with a
  note. The 5 mm roof + 2 mm boss + twin 2×2 mm grooves (replacing the single
  13×1.1) are internal to the cut bottle — no other bounds effect.
- **control axle → `lib/hex_shaft.scad` `control_axle()`** (TB-04, 59 mm +
  Ø3×1 magnet recess). `lib`'s origin is the hex bottom; the embedded axle used
  Z=0 = cap face, so it is placed at
  `control_assembly_z - (p_axle_hex_len() + p_axle_round_ext())`. With that shift
  the lib axle's hex span `[-24, -0.8]` and round span `[-1.2, 35]` match the
  embedded axle exactly; the magnet recess is buried in the bottle → bounds
  unchanged. `printable_turtle_control_axle` gone (`control_axle()`'s hex is
  already on Z=0).
- **control cage → `lib/control_cage.scad`.** Deleted the ten `cage_*` build
  modules; kept `function cage_edge_z` (a live assert reads it). The embedded
  cage-native frame put bearing tips at `cage_bearing_tip_native_z` (39.5);
  `lib/control_cage` puts them at Z = 0 (`cage_under_z()` / `cage_roof_top_z()` /
  `cage_wall_tip_z()` give the references). So `positioned_cage_assembly()` drops
  the `+ cage_bearing_tip_native_z` term:
  `translate([cx,cy, control_assembly_z - cage_vertical_position]) rotate(90)
  rotate(180) control_cage(button_angle = cage_button_angle)`. `button_angle` 0
  + the 90° install rotate nets to 90, as before. Bounds unchanged.

Derived globals (`john_length`, `frame_center`, `ballast_*`, `control_assembly_z`,
`cage_bearing_tip_native_z`, `cage_surface_under_z` …) stay — the placement
transforms and the embedded assert block still read them.

For physical prototypes, separately check bottle fit, cage rubbing, shaft wobble, magnet-to-sensor placement, silicone insertion/sealing, batten joint stiffness and fastener engagement. Material savings or a smoother profile alone do not establish stronger structure.

## 16. Printing, modelling and communication conventions

- Cap: flat bearing face on the bed, open insert and boss pointing upward.
- Sail shaft: **not printed** — an Ø5 steel rod cut to 59 mm (v6.4.0). The SCAD model's pose (upper end on Z=0, magnet recess up) is just the as-modelled reference.
- Cage: **printed roof-face-down** (flat top on the bed) — this is a hard fabrication constraint, not a preference. Roof-top features must be self-supporting in that pose (bevels flare outward ≤ 45°, no undercut, no downward pocket/overhang); flag any change that would need support instead of making it. Inspect the clip-pocket bridging and horizontal bores in the slicer. See section 6.
- Mold: openings up. Silicone rings are flexible cast parts, not rigid printed substitutes.
- Sail and wood assemblies: inspection outputs are not automatically flat fabrication layouts.
- Keep colours useful: brown sail rails, orange C ends, distinguishable other wooden components. Colour changes do not change manufacturing material.
- A hardware placeholder has no modelled thread, torque rating or verified engagement unless explicitly implemented.
- Use readable physical parameter groups and keep derived calculations below them. Explain whether a clearance is radial, diametral or total slot allowance.
- Preserve accessible single-file SCAD downloads. If shared modules are introduced later, maintain self-contained release artifacts or document dependencies explicitly.
- Clearly separate implemented changes, suggested experiments and physical test results. Do not promote the narrower silicone ring proposal or historical cap dimensions into current facts.

## 17. Suggested future work, only when in scope

The shared-library refactor (M0–M8) is done — the standalone↔full sync now
happens through `lib/` + `build/build.py`. Open items live in `issues_to_fix.md`.
Remaining scoped clean-ups:

- Trim the inert cap/cage/axle parameter block still carried inside
  `lib/sail_frame.scad` (kept only because a few live frame asserts read from
  it). The embedded `hope_turtle_sail_apparatus` in `src/Full_Turtle.scad` also
  still keeps a cap/cage/axle *variable + assert* block feeding the placement
  transforms; it is inert geometry-wise but could be reduced to just the values
  the transforms need.
- The `src/Full_Turtle.scad` `hope_turtle_sail_apparatus` module could be
  unwrapped now that it emits almost nothing itself — it is essentially just
  `fixed_control_bottle_unit()` + `rotating_cage_sail_unit()` around lib calls.
- Add a GitHub Actions job that runs `build/lint.py` + `build/test.py` if the
  project ever wants CI (currently local-only by design).
- The generator sync plan in `/home/russs/WebstormProjects/hopeTurtles.org/generator/SYNC_PLAN.md`
  (items S-1…S-6) is done through S-5. This repo's part: `build/export_params.py`
  → `build/params.json` (every `p_*()` + version), regenerated by `build/build.py`
  and gated by `build/lint.py`. S-5b (generators loading from that snapshot rather
  than carrying checked literals) and S-6 (hygiene) remain, deferred.

## 18. Provenance and maintenance

This handoff combines the development conversation with direct inspection of the repository README, license, full assembly and all eight standalone SCAD files at the snapshot above. Repository values are labelled separately wherever they differ from the conversation. No repository source or remote branch was modified while preparing this document.

Keep this file at the repository root as **`CLAUDE.md`**. That is the project-instruction filename documented by [Claude Code](https://code.claude.com/docs/en/memory). This deliberately extensive handoff can later be split into shorter core instructions and subsystem documents if maintaining it as one file becomes cumbersome.

When updating it, change the inspection date/revision, close resolved discrepancies, and retain enough rationale to prevent a future agent from reintroducing a corrected design error.

## 19. Downstream: the HopeTurtles.org generator bridge

> **Checkout locations (2026-11-12).** This repo lives at `/home/russs/PycharmProjects/turtle_body`; the
> website at `/home/russs/WebstormProjects/hopeTurtles.org`. They are **not siblings**, so the
> website's `sync_from_turtle_body.py` default (`../turtle_body`) does not find this repo. Always pass
> `--turtle-body /home/russs/PycharmProjects/turtle_body` or set `TURTLE_BODY_DIR`.
> `/home/russs/WebstormProjects/turtle_body_OLD- nov11` is a stale older clone. Never sync from it or edit it.

HopeTurtles.org (`/home/russs/WebstormProjects/hopeTurtles.org`, a different parent folder from this repo; note the capital T) lets a
builder enter bottle, board and solar-panel measurements at `/ecojoiners/generate` and
download cutting files. Those files come from Python generators in
`/home/russs/WebstormProjects/hopeTurtles.org/generator/` (renamed from `ecojoiner/` on 2026-09-08, because the
directory generates the wooden parts of a whole turtle, of which the Ecojoiner is the
central part). The generators were written against the old monolithic `Full_Turtle`
SCAD and **drifted** once geometry moved into `lib/`. This section is the contract that
keeps them in step. The mirror of it lives in `/home/russs/WebstormProjects/hopeTurtles.org/CLAUDE.md` →
"Turtle Generator".

**Direction of truth: `lib/params.scad` (and the wooden `lib/*.scad` modules) win.**
The generators are consumers. When a value differs, the generator is wrong. The 6FC
Ecojoiner generator's old cap 32 / port 85 values were legacy from when the website
only generated Ecojoiners; they were drift, not a separate design, and were corrected
to lib in the v1.7.1 sync. The **Master John was the exception**: it was a real
parametric feature the generator had always carried and lib lacked. The v1.7.1 sync
wrongly deleted it from the generator to match lib; v1.8.1 reversed that by lifting the
rule upstream (`eco_master_slot_depth()` in `lib/ecojoiner.scad`) — the "lib owns the
rule" precedent, applied in the generator→lib direction.

### Component map

| Component | Source here | Wrapper / bundle | Generator there (`generator/`) | `object_type` |
| --- | --- | --- | --- | --- |
| Ecojoiner core (Long/Little/Master Johns, Final Keys; M5 clamp holes — no Pressers since v5.0.0) | `lib/ecojoiner.scad` + `lib/params.scad` | `src/components/Turtle_Core_Ecojoiner.scad` → `scads_v1/Turtle_Core_Ecojoiner.scad` | `objects/ecojoiner_6fc.py` | `6fc` |
| Rear fin, bottle-holder shafts, solar holder | `lib/rear_fin.scad` | `Turtle_Rear_Fin.scad` | `objects/back_fin.py` + `back_fin_generator.py` | `fin` |
| Ballast (core slats, bottom board, lock feet, fin) | `lib/ballast_fin.scad` | `Turtle_Bottom_Ballast_Fin.scad` | `objects/ballast.py` + `bottom_ballast_fin_generator.py` | `ballast` |
| Pressor (port clamp block) — experimental, v6.6.1 | `lib/pressor.scad` | `Turtle_Pressor.scad` | **none yet**: the 6FC generator still emits the acorn clamp; add a pressor part there if it replaces the acorns | — |
| Head fin (front slats + raked fin) — experimental | `lib/head_fin.scad` | `Turtle_Head_Fin.scad` | `head_fin_generator.py` + `objects/head_fin.py` (SCAD = the vendored bundle with `p_*()` overrides) | `head_fin` |
| Sail frame (crossbar halves + connector, battens, strengtheners, C pieces, sails) | `lib/sail_frame.scad` | `Turtle_Sail_Apparatus.scad` | `objects/sails.py` + `generate_sails.py` (SCAD = the vendored bundle with `p_*()` overrides since 2026-10-22) | `sails` |
| Cap, cage, shaft, mold (printed PLA) | `lib/control_*.scad`, `lib/sail_shaft.scad`, `lib/silicone_ring_mold.scad` | — | **no generator; never needs propagation** | — |

Each generator carries three copies of every formula — the `lib/` module, its embedded
SCAD body, and a Python `derive_dimensions()` that re-derives 2D outlines for SVG/DXF/PDF.
Only the last one has no mechanical fix, which is why the rule below exists.

### Propagation rule (also step 8 of the section 15 workflow)

A change to **any** of the following must be carried to the matching generator in the
same task, or explicitly logged if it cannot be:

- `lib/params.scad` or `lib/util.scad` (any value — check which components consume it);
- `lib/ecojoiner.scad`, `lib/rear_fin.scad`, `lib/ballast_fin.scad`, `lib/sail_frame.scad`;
- a wooden component's wrapper customizer surface or `part` list in `src/components/`;
- a minor (`+0.1.0`) or major (`+1.0.0`) bump of `VERSION.json`.

To carry it: open the generator named in the map, update `DEFAULTS` / `TUNING` /
formula / template, keep the upstream `p_*()` name cited in the comment beside each
constant, and re-run the generator's dry run (section 14). If the task cannot include
that, append an `open` line to `/home/russs/WebstormProjects/hopeTurtles.org/generator/SYNC_LOG.md` (format is at
the top of that file) and state it in the report. Never let a `lib/` change go
unrecorded on the generator side.

### Known drift, recorded 2026-09-08 against v1.7.1 — now fully resolved

Rear fin, ballast, sails (including its SVG/DXF/PDF writers) and 6FC were all hand-fixed the
same day (S-5, the automatic sync mechanism, was deliberately deferred — see
`generator/SYNC_PLAN.md`). No open drift remains on the generator side.

Resolved: rear fin's `shaft_hole_diameter` (6.0 → 6.4) and its fixed `shaft_hole_from_front`
(50 → derived via TB-07, no longer a constant — section 11's "preserve the 50 mm standalone
offset" note is superseded); ballast's defaults (15/320/35 → 12/305/31), slat-height formula
(4.5·t → 6·t), a **missing M6 mount hole** (the standalone generator's core slat had none at
all), and a latent bug where the shoulder-cut position read `port_length` instead of
`bottle_diameter`/port height (the two are numerically equal only at the reference bottle's
defaults, so a non-default taper would have silently mis-cut the shoulder); sails' bottle
diameter and cap/collar/dome heights (the SCAD module already accepted them as parameters —
only the Python wrapper never threaded a caller's values through) **plus** its previously
missing SVG/DXF/PDF carpenter-sheet writers, built for all 7 part shapes and verified against
real OpenSCAD-rendered bounding boxes; 6FC's `cap_diameter` 32→31,
`collar_diameter` 32→34, `port_height` 85→82, `screw_diameter` 4.5 (pilot)→6.4 (M6 clearance)
— `objects/six_fc.py` renamed `objects/ecojoiner_6fc.py` in the same pass (internal only;
`object_type`, job-slug prefix and every public identifier are unchanged). Full detail in
`generator/SYNC_PLAN.md` §7 (History) and `SYNC_LOG.md`.

**Corrected in v1.8.1:** the same v1.7.1 sync also flattened the generator's **Master
John** (Little John ×5 + Master John ×1) into six plain Little Johns, to match a lib that
never modelled one. That was the wrong direction — the Master John is a real assembly
feature (the deeper-slotted John fitted last). v1.8.1 lifts the rule into
`lib/ecojoiner.scad` (`eco_master_slot_depth()`, `eco_master_john()`) and the generator's
`master_slot_depth` / part list are being restored downstream. Part list is back to Long
×6 + Little ×5 + Master ×1 + Final Key ×4 + Presser ×12.

**"Lib wins" means lib owns the *rule*, not just the number.** The port-length case
(v1.7.2) is the precedent: lib carried an evaluated constant (82) where the generators
carried the formula (taper + 20). The formula was right and lib was fixed to derive it.
When syncing, compare rules first; if a generator has a parametric rule that lib has
flattened into a constant, lift the rule into `lib/params.scad` rather than hardcoding
the generator.

The assessment and ordered work items (S-1 rear fin, S-2 ballast, S-3 sails, S-4 6FC,
S-5 the sync mechanism, S-6 hygiene) are in `/home/russs/WebstormProjects/hopeTurtles.org/generator/SYNC_PLAN.md`.
**S-1…S-5 are done (2026-09-08).** This repo's part of S-5: `build/export_params.py`
renders every `p_*()` and writes `build/params.json` (values + version); `build/build.py`
regenerates it with the bundles and `build/lint.py` fails on a stale one. The generator
side vendors that file plus the four `scads_v1/` bundles into
`/home/russs/WebstormProjects/hopeTurtles.org/generator/turtle_body/` (`sync_from_turtle_body.py`) and
`check_params_sync.py` asserts every generator's shared-input default against it in
`npm run lint`. So a release here is propagated by: `python3 build/build.py`, then in
hopeTurtles.org `python3 generator/sync_from_turtle_body.py --turtle-body
/home/russs/PycharmProjects/turtle_body && python3
generator/check_params_sync.py`, then a human review of `derive_dimensions()` against the
vendored bundles. S-5b (generators loading defaults from the snapshot) and S-6 remain.

## 20. Turtle_Sim — buoyancy workbench (v6.6.0, first milestone)

A local Python app for flotation, trim and stability, driven by this CAD. Plan:
`docs/sim_roadmap.md`. How to operate it and its current model limits: `sim/README.md`.
Physical survey: `docs/buoyancy_measurements.md`. Scope today is **calm-water hydrostatics
only**. Sailing forces, waves, dynamic capsize, slosh, TurtleOS sensor/actuator emulation
and the luff tests are roadmap stages 3–7, not built.

| Path | Role |
| --- | --- |
| `sim/turtle_sim/core/` | Engine (`hydrostatics.py`), independent of HTTP. Manifold unions displacement; Trimesh mass properties; SciPy force/moment balance |
| `sim/turtle_sim/api/app.py` | FastAPI app (`/api/geometry`, `/api/config`, `/api/solve`, `/api/jobs/{id}` …); jobs run in a separate process |
| `sim/turtle_sim/geometry.py`, `config.py` | Component list / CAD fingerprint / mesh loading; measurement config |
| `sim/web/` | Browser UI + vendored Three.js 0.180.0 (works offline) |
| `sim/tests/` | `pytest` suite (hydrostatics against reference shapes, API, measurements, fin exports) + optional Playwright `browser_smoke.py` |
| `physics/components.yaml` | Distributed measurement template. Unknowns stay **null**. Never fill it with guessed masses |
| `build/export_sim.py` | Renders installed component meshes + ruler datums from `src/Full_Turtle.scad` into `sim/generated/` (metres; sim axes +X forward, +Y port, +Z up). No Python copy of assembly placements |
| `run_sim.sh` | Launcher → `sim/launch.py`, binds `127.0.0.1:8765` only |
| `sim/generated/`, `sim/data/`, `fabrication/` | **Git-ignored.** Exported meshes, the user's personal measurements, and fin DXFs |

Setup and checks, from the repository root:

```bash
python3 -m venv .venv && .venv/bin/pip install -r sim/requirements.txt
./run_sim.sh                                   # --no-browser / --port 8766
.venv/bin/python build/export_sim.py           # CAD -> sim/generated/ (minutes; the UI's "Export CAD" does this)
.venv/bin/python build/export_fin_dxf.py       # fin DXFs -> fabrication/fins/
PYTHONPATH=sim .venv/bin/pytest sim/tests -q
```

Rules:

- **The CAD stays the master geometry.** The sim reads installed placements from
  `src/Full_Turtle.scad` through `build/export_sim.py`. Do not hard-code coordinates in Python.
  Convert mm → m only at the export boundary. A CAD/source fingerprint rejects stale exports,
  so after any geometry change, re-export before you trust a solve.
- **The CAD build stays stdlib-only.** NumPy/SciPy/Trimesh/FastAPI/ezdxf live only in the
  `.venv` (`sim/requirements.txt`, pinned). `build/build.py`, `lint.py`, `test.py` and
  `export_stl.py` must not import them.
- **Measured vs estimated is explicit.** Masses, centres of mass and displacement status come
  from the user's measurements. Keep bottle displacement envelopes separate from loaded mass, and
  never count contained equipment twice. The CAD centre plane (body Z = 0) is a datum, **not** a
  predicted waterline. Water appears only after a successful solve.
- **The fin rulers (section 11) are the calibration datum.** The solver predicts where each
  ruler line meets the water after heave, pitch and roll; trial readings validate the
  volume/moment model and do not replace it. Front and rear readings alone do not establish roll.
  There is no automatic parameter fit.
- Sign conventions: positive roll raises port; positive mathematical pitch lowers the bow; ruler
  values are positive above the bottle centre.
- A passing analytic-shape test or a plausible water view does **not** show the real turtle
  floats as predicted. Report what was solved or measured, nothing more.
- Adding a component the sim should see means updating `COMPONENTS` in
  `sim/turtle_sim/geometry.py`, its export in `build/export_sim.py`, and a null entry in
  `physics/components.yaml`, together.

## 21. Downstream: the turtle_labels inventory bridge

[turtle_labels](https://github.com/h2h-project/turtle_labels), checked out at
`/home/russs/WebstormProjects/turtle_labels`, is the design source for the printed and
laser-engraved turtle labels. Label artwork for the wooden parts is laid out on the
**full slat inventory** generated here. The direction of truth is the same as for the
website: `lib/` wins, and the labels repo receives a generated copy.

- **Generator:** `build/export_inventory.py` (stdlib + OpenSCAD). The parts, quantities,
  piece codes (`EJ-LJ1`, `RF-FIN` …) and fills are in its `INVENTORY` table. Each
  wooden part is rendered from `lib/`, laid flat, projected top-down at 1:1 (mm), and every
  physical copy is drawn and captioned. Only through-face holes show. Sails are excluded.
- **Output name carries the master version:** `turtle_body_full_inventory_<VERSION.json
  version>.svg` (e.g. `turtle_body_full_inventory_6.6.0.svg`). The version also appears in
  the SVG title, header line and generated-file comment.
- **Here:** written to the repo root. Older `turtle_body_full_inventory*.svg` files are deleted
  so only the current version remains, as in `stls_v1/`.
- **turtle_labels:** the same file is copied to that repo's root. **Older versions there are
  never deleted.** Label artwork may have been built on them, so pruning is the labels
  maintainer's decision. The checkout is found from `--labels-dir`, else `$TURTLE_LABELS_DIR`,
  else `~/WebstormProjects/turtle_labels`, else `../turtle_labels`. If none is found, the
  script warns and writes only the local copy. `--no-labels` skips the copy deliberately.
- **Piece codes are an interface.** Labels reference them. Renaming or renumbering a code
  in `INVENTORY` breaks existing label artwork, so flag it to the user and don't change one
  silently.
- Nothing is committed in turtle_labels by this repo's tooling. The new file shows up there as
  untracked for its maintainer to commit.
- When to run it: workflow step 9 (section 15).
