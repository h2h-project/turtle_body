# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Turtle Body — project instructions and mechanical design context

This repository contains the parametric mechanical designs for Hope Turtle. Read this file before changing geometry, dimensions, generators, or fabrication outputs. It records design decisions from the development conversation and the repository state inspected on **2026-09-06**.

Repository snapshot inspected: `main`, commit `015a162f2bcac592a70c50a740c1671a10352732`. Recheck the working tree and subsequent commits before treating the dimensions below as current. This document is project guidance, not evidence of successful fabrication or physical validation.

See `issues_to_fix.md` for the accompanying prioritized repair and verification backlog. It separates confirmed source drift from design decisions and unverified physical risks.

> **2026-09-07 — build system + shared-library refactor COMPLETE (M0–M8).**
> Editable geometry lives in `lib/` (parametric modules + `params.scad`, the
> shared dimension contract) and `src/` (thin wrappers). `Full_Turtle_v1.scad`
> and `v1.0 SCADs/*.scad` are **generated bundles** — never hand-edit them; run
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
> Remaining `issues_to_fix.md` items are physical / interface checks and an
> external-generator hookup — no source drift left.

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
| [TurtleOS](https://github.com/h2h-project/turtleOS) | Sensing, actuation and navigation software |
| TurtleShell PCB | Electronics interconnection and power hardware; no repository URL established by this task |
| [HopeTurtles.org source](https://github.com/h2h-project/hopeTurtles.org) | Builder-facing website and planned body-generator integration |
| [HopeTurtles.org](https://hopeturtles.org) | Public project website |

The intended generator accepts local bottle, board, panel and hardware dimensions and produces a compatible set of models. This is an intended integration, not an existing API verified in this repository. Do not invent a deployed geometry service, CI workflow, package manager, or frontend build process.

## 3. Actual repository map

Paths below were verified in the inspected GitHub tree.

| Path | Role |
| --- | --- |
| `lib/params.scad` | **Editable.** Shared dimension contract — every cross-subsystem value as a `function p_*()`. One definition per concept; derived values are functions of other `p_*()`. |
| `lib/util.scad` | **Editable.** `wood_color()`, `m6_bolt_placeholder()`, `clamp()`, `hex_prism_af()`. |
| `lib/<subsystem>.scad` | **Editable.** One parametric module per subsystem: `control_cap`, `control_cage`, `hex_shaft` (`control_axle`), `silicone_ring_mold`, `ecojoiner`, `ballast_fin`, `rear_fin`, `sail_frame`, `bottle_mockup`. Module args default to `p_*()`; wrappers override individually. Definitions only — no top-level geometry or assignments. |
| `src/components/*.scad` | **Editable.** Thin wrappers: customizer block + `use <../../lib/...>` + a `part=` dispatch → one lib call. |
| `src/Full_Turtle.scad` | **Editable.** The full-assembly source (git-renamed from `Full_Turtle_v1.scad`). M7 pending: still holds embedded geometry, not yet `use`-ing lib. |
| `Full_Turtle_v1.scad` | **GENERATED** by `build/build.py` from `src/Full_Turtle.scad`. Self-contained, committed, downloadable. Do not hand-edit (a banner says so). |
| `v1.0 SCADs/*.scad` | **GENERATED** bundles from `src/components/*.scad` + `lib/`. Same eight filenames as before; still self-contained single-file downloads. |
| `build/` | `scad_lib.py` (helpers), `bundle.py` (inline `use`/`include`), `build.py` (regenerate all bundles = the sync step), `lint.py`, `test.py`, `baseline.py`, `export_stl.py`, `manifest.json`, `README.md`. Python 3 stdlib only. |
| `tests/expected_bounds.json` | Regression baseline (per-render bounding box + tris + known warnings) checked by `build/test.py`. `tests/baseline/` holds the full per-render dumps. |
| `VERSION.json` | Single set-level version + bump rules + changelog. STL exports carry this version in their filename. |
| `v1.0 STLs/` | Fabrication exports, written on demand by `build/export_stl.py` as `<name>_v<version>.stl`. The pre-refactor un-versioned STLs were deleted at v1.6.0; current set is the six `_v1.6.0` files (cap, cage, hex shaft, flat ring mold, O-ring mold bottom + top). F6-verified, not physically validated. |
| `README.md` | Project overview and generator intent |
| `LICENSE` | CERN Open Hardware Licence v2, Strongly Reciprocal |

OpenSCAD is required for `build/lint.py`, `build/test.py`, `build/baseline.py` and
`build/export_stl.py` (2021.01 was used for the baseline). Scripts find it via
`$OPENSCAD` → `PATH` → `~/.local/bin/openscad` → the macOS app bundle. `build/build.py`
and `build/bundle.py` are pure Python. There is no CI service — everything runs locally.
The three Python geometry generators described in section 14 live in the HopeTurtles.org
repository, not here; connecting them is future work.

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
| Python generators | Delivered for rear fin, ballast and sails | Missing from inspected repository tree |

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
| Ecojoiner port length / height | 82 / 82 | Axial port length and opening height are separate concepts |
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
> not silently made. The clip pocket and the horizontal M3 bores already
> bridge in the slicer. `p_cage_roof_bevel()` (default 4 mm) is a true 45°
> outward chamfer on the roof-top outer edge, masked away around each batten
> groove so the groove walls stay square — printable as-is.

The cage is an inverted, open-bottom rotating cup. The circular roof is supported above the fixed cap by eight downward-facing hemispherical bumps. Those bumps were initially misread from the drawing as holes in a bottom plate. **There is no bottom plate and those eight features are solid hemispheres.**

The design evolved from a continuous cylindrical skirt with four grooves to a continuous sinusoidal annular wall. Separate extended tabs, widened shoulders and triangular gussets were intermediate designs. The user ultimately requested that the wall peaks stand on their own, with the batten mounts centred on them. Do not reintroduce separate tab components by default.

| Current cage dimension | Value |
| --- | ---: |
| Inner / outer diameter | 102 / 115 |
| Radial wall thickness | 6.5 |
| Roof thickness | 6 |
| Original skirt depth | 44 |
| Extra peak extension | 20 |
| Maximum wall depth below roof | 64 |
| Minimum wall depth between mounts | 10 |
| Roof-to-tip overall height | 70 |
| Groove count / width / depth | 4 / 22.5 / 3.7 |
| Mount holes | Two Ø3.2 holes per groove, eight total |
| Mount-hole vertical pitch | 32 |
| Lower hole distance from peak tip | 10 |
| Bearing bumps | Eight Ø9 hemispheres |
| Bearing pitch-circle diameter | 91.5 |
| Hex opening across flats | 10.3 |
| Centre hub / top pocket diameter | 29 / 26 |
| Pocket depth | 4 |
| Button opening / centre radius | 18 / 24 |

The wave uses `cos(4*a)`: maxima in wall depth align with 0°, 90°, 180° and 270°; minimum wall depth is halfway between. Cosine is simply the chosen phase of the sinusoidal profile.

The standalone cage uses an installed reference where bearing tips touch cap Z=0. Roof underside Z=4.5, roof top Z=10.5, longest wall tip Z=-59.5. Hole centres are Z=-17.5 and -49.5. The print view flips the model so the roof faces the bed. Its other view raises the longest wall tips to Z=0.

The full assembly and sail frame use different native translations. Compare physical interfaces after transforms, not raw Z values from different files. The cage's standalone button angle is 90°; the full model may apply a 90° installation rotation to a local 0° opening.

The wave mesh has four vertices per angular station, triangulated faces and consistent OpenSCAD face winding. Keep it closed, preserve the bore, and use a small Boolean overlap at the roof junction. Numerical topology checks were performed previously; this does not establish structural strength or F6 validity.

Historical Ø2.8 M3 pilot holes, three-hole asymmetric patterns and M3 countersinks belong to earlier cage revisions. The current cage uses **two Ø3.2 clearance holes per mount**. Do not confuse a clearance hole with a thread-biting pilot hole.

## 7. Control cap and centre boss

The large cap disk is stationary; the cage rotates above it. Its insert goes into the cut bottle body. Do not confuse this control cap with the bottle's original Ø31 mm screw cap.

Current repository standalone dimensions:

| Feature | Value |
| --- | ---: |
| Disk diameter / roof thickness | 100 / 5 |
| Boss outside diameter / inward projection | 18 / 2 |
| Nominal total axle-bearing length | 7 |
| Axle bore diameter | 8.6 |
| Insert outside diameter / length | 79 / 35 |
| Insert wall thickness | 4 |
| Nominal total cap height | 40 |
| Button holes | Two Ø17 at ±24 along Y |
| Entry chamfer height / diameter reduction | 1 / 1 |
| Axle O-ring gland (in the bore) | Ø11.5 groove root × 2.6 wide, centred 3.5 mm below the outer face |

The boss is an integral cylindrical collar on the hollow underside. It does not protrude onto the flat surface facing the cage. The centre bore must pass through both roof and boss, and the cavity subtraction must not erase the boss. Ensure a positive overlap connects it to the roof.

Rationale from the conversation: an 8 mm roof resists flex and provides a longer axle bearing, but distributes material across the entire disk. A thinner roof plus a local boss concentrates support around the axle. A longer bore does not eliminate the 0.3 mm radial clearance between Ø8 shaft and Ø8.6 bore. No stiffness or wear optimization has been physically verified.

**Axle O-ring gland (rotary seal).** The bore now carries an annular groove
(`oring_gland`, default on) that seats a round-section O-ring against the
spinning axle round section, closing the 0.3 mm bore gap as a water path. The
gland root is Ø11.5, 2.6 mm axial, centred 3.5 mm below the cap outer face —
lands of ~2.2 mm remain each side within the 7 mm bore column. Parameters:
`p_axle_oring_cs()` (2.0), `p_axle_oring_id()` = `p_axle_round_d()` (8 — tied to
the shaft), `p_axle_oring_od()` (12), `p_cap_oring_gland_*()`. `control_cap()`
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

### Axle O-ring and its two-part pressed mold

`lib/silicone_ring_mold.scad` now makes **two** kinds of ring:

1. **Flat insert-seal rings** — unchanged. `part = "mold"` (the two open-top
   scrape molds, 190 × 91 × 4.5 envelope) / `part = "rings"` (the bare cast
   rings). Ø75 ID / Ø85 OD, tied to `p_seal_groove_root_d()`.
2. **Axle rotary-seal O-ring** — round cross-section, for the cap bore gland
   (section 7). ID = `p_axle_round_d()` (8), CS = `p_axle_oring_cs()` (2),
   OD 12. A round ring needs a **two-part pressed mold**: `part =
   "oring_bottom"` and `part = "oring_top"` are the two halves (print each
   flat, half-torus channel opening up); `part = "oring_pair"` shows them
   exploded; `part = "oring"` is the cast torus itself. **Three male pegs** on
   the bottom half seat in **three female holes** in the top half (120° apart,
   outside the channel) so the halves cannot shift when pressed; fill + vent
   holes run through the top half. `part = "all"` lays the flat molds and the
   O-ring mold out together. `oring_mold_half()` asserts the pegs stay inside
   the plate.

Neither seal is validated. The O-ring's radial squeeze, the dynamic friction
of a silicone lip on a rotating PLA shaft, and demoulding a round ring from a
pressed mold without flash all need real testing.

## 9. Round/hex centre axle and magnetic sensing

The earlier 100 mm hex shaft, coupler ideas and 50 mm stepped axle are historical. The latest delivered standalone axle is:

| Feature | Value |
| --- | ---: |
| Round diameter | 8 |
| Nominal round length | 35 |
| Hex across flats / nominal length | 10 / 23 |
| Overall length | 58 |
| Joining overlap | 0.2 |
| Magnet recess | Ø3 × 1 deep, adjustable |
| Assumed cap roof / boss | 4 / 6 — stale relative to repository cap |

The nominal round length was `30 inside cap + 4 roof + 1 external extension`. The 30 mm measurement starts at the roof underside and includes the boss; do not add the boss again. The magnet recess opens at the circular end for an AS5600 sensing magnet. Sensor-to-magnet distance and orientation remain installation checks.

For a six-sided OpenSCAD cylinder, the specified diameter is across corners:

```scad
hex_corner_diameter = hex_across_flats / cos(30);
```

A 10 mm-AF hex is about 11.55 mm across corners, fitting the Ø12 sail-bar opening. The cage hex is 10.3 mm AF. Preserve angular phase as well as size when combining standalone and embedded parts.

The 23 mm hex was lengthened from 20 mm when the cage roof increased from 3 to 6 mm. The stack check includes a 4.5 mm bearing height, 6 mm cage roof and 12 mm sail bar. The existing hub pocket is not proof of a complete axial retention or clip mechanism; do not claim the assembly locks together without inspecting the actual retaining components.

## 10. Sail apparatus and mounting-hole rules

The standalone sail apparatus emits the wooden frame, four battens, reinforcements, C ends, sails and optional hardware previews. It emits no cage, cap, bottle or axle. The default assembly is an inspection view, not a fabrication layout.

| Feature | Current value or rule |
| --- | --- |
| Wood thickness | 12 mm |
| Batten height / width / radial thickness | 205 / 20 / 10 mm |
| Top crossbar length / width / thickness | 492 / 22 / 12 mm |
| Top crossbar axle hole | Ø12 mm |
| Bottom rail length | 246 mm = 3 × bottle diameter |
| Bottom rails' bottle clearance | 1 mm nominal |
| Cage mounting holes | Two Ø3.2 per batten, 32 mm pitch |
| Hole centres from batten top | 55 and 87 mm at default stock thickness |
| Hole centres from batten bottom | 150 and 118 mm at default batten height |
| Top and bottom rail colour | Brown `[0.56, 0.39, 0.39]` |
| C-piece colour | Orange, retained |

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

Preserve the explicitly approved shaft formula:

```text
shaft_length = bottle_height + (2/3)*(fin_board_width - 2*wood_thickness) - cap_height
             = 305 + (2/3)*(93 - 24) - 17 = 334 mm
```

Older alternate formulas and 310.5 mm results are superseded for this design.

The green/yellow common overlap is X=0..84. Split it at X=42: yellow slots open from the front, green slots open from the rear. Two slots cut into the same end do not form a functioning interlock. The corrected nominal engagement depth is 42 mm.

Both half-lap clearance and solar-joint clearance are 0.2 mm **total** extra width, centred on the mating 12 mm board. Thus slot openings are 12.2 mm, not 12.4 mm. Root clearances are also symmetric. Do not add clearance to the wooden part's thickness or move the nominal installation datum.

The red crossbar is 148 mm long, 36 mm high and 12 mm thick. The actual panel is 148 × 223 × 2.5 mm: width along local Y, length/height along local X, thickness along Z. It extends forward from the crossbar. Panel thickness is independent of stock thickness.

Standalone rear shafts use a 50 mm mounting-hole offset from their front. The full assembly computes the offset from the mating John, yielding 103 mm at current defaults. Preserve that distinction until the standalone/full mounting interface is deliberately unified.

In the full Turtle, the rear assembly belongs at the physical 3-o'clock/back port and is rotated 180° around the bottle axis so the yellow fin points downward. Earlier 9-o'clock placements were corrected. Do not infer the port from a screenshot alone.

## 12. Ballast attachment

Six wooden components: two green core slats, one orange bottom board, two red lock feet and one yellow ballast fin. No bottle is included in the standalone artifact.

| Feature | Default |
| --- | ---: |
| Core slat width | 82 - 2 × 12 = 58 |
| Core slat length | 305 - 17 + 6 × 12 = 360 |
| Clear gap between core slats | 82 |
| Slat centre spacing | 82 + 12 = 94 |
| M6 hole diameter | 6.4 |
| M6 hole distance from top | 82 + 12 - 25 = 69 |
| Bottom board length × width | 287 × 93 |
| Lock-foot width × height | 60 × 60 |
| Yellow fin length × height | 246 × 93 |

Use clear inner-face spacing, not centre spacing, when checking bottle clearance. The yellow fin's bottle-seat cut was enlarged by one stock thickness to stop it intersecting the bottle. Preserve that correction.

Ballast mounting transforms reference the Ecojoiner port entrance and insertion length. Do not replace them with a visually estimated translation. The standalone output preserves local assembly relationships and raises the lowest component to Z=0.

Slots in the ballast extraction retain nominal stock widths; the rear fin's 0.2 mm fit allowance was not automatically added to ballast joints.

## 13. Ecojoiner-only output

The inspected extraction contains six Long Johns, six Little Johns, four Final Keys and twelve Pressers with visual M6 bolts. Earlier discussions of five Little Johns plus a Master John or additional Saddlers refer to other revisions, not this file's emitted geometry.

All six ports have their pressers restored in the standalone Ecojoiner. The full Turtle suppresses selected pressers to accommodate the rear-fin and ballast attachments. Preserve the appropriate configuration for each output.

Current references: 12 mm stock, 82 mm port length, 82 mm port height, 31 mm cap diameter, 34 mm collar diameter, Ø6.4 M6 clearance holes and 0.2 mm slot fit allowance. Bottle dimensions are sizing inputs only; the Ecojoiner-only model must not emit bottle solids.

## 14. Python generation logic

These standalone standard-library generators were created in the conversation, but are missing from the inspected tree:

| Delivered filename | Geometry |
| --- | --- |
| `generate_turtle_rear_fin_v2.py` | Corrected rear fin, shafts and solar holder |
| `generate_turtle_ballast.py` | Ballast assembly and individual components |
| `generate_turtle_sail_apparatus.py` | Latest sail apparatus and hole/colour corrections |

They embed their SCAD source/templates and expose `build_scad(...)` plus a CLI. They do not require a remote file or another SCAD include. Output files use UTF-8; existing output is protected unless `--force` is supplied. The rear-fin generator uses `--defaults` for noninteractive default generation. Consult each script's `--help` before changing CLI contracts.

After the scripts are actually added, example commands are:

```bash
python3 generate_turtle_rear_fin_v2.py --defaults --output /tmp/rear_fin.scad
python3 generate_turtle_ballast.py --output /tmp/ballast.scad
python3 generate_turtle_sail_apparatus.py --output /tmp/sails.scad
```

These commands are not currently runnable from the inspected repository without first adding the scripts. Do not pretend there is a `generators/` directory already.

Maintain one authoritative definition of an input within each generated file. Reject NaN, infinity, nonpositive dimensions and known invalid geometry. Keep Boolean tolerances distinct from fit clearances. When editing an emitted SCAD and its generator, update both and verify generation reproduces the intended source, including comments and selectors where byte-for-byte reproducibility is expected.

The sail generator currently uses targeted first-occurrence replacements for a few top-level controls. Renaming those controls without updating the template replacement logic can silently break parameterization. Its detailed geometry assertions remain in the SCAD; Python validation is not a full geometric solver.

## 15. Editing and verification workflow

**Geometry lives in `lib/` and `src/` only. Never hand-edit a generated bundle**
(`Full_Turtle_v1.scad`, `v1.0 SCADs/*.scad`) — a banner in each says so, and
`build/lint.py` fails if one is stale. Editing the full turtle and editing a
component are the same operation: change the shared source, then rebuild
regenerates every dependent bundle. There is no hand-porting between copies.

On **any** geometry change:

1. **Locate the source.** A shared dimension → `lib/params.scad` (as a `function
   p_*()`; add it there once, derive from other `p_*()`). Subsystem geometry →
   `lib/<subsystem>.scad`. A component's customizer surface or `part` dispatch →
   `src/components/<Name>.scad`. Assembly placement / world transform / view
   dispatch → `src/Full_Turtle.scad`.
2. **Edit the source layer only.** Keep derived relationships explicit; keep the
   in-SCAD `assert()`s meaningful.
3. `python3 build/build.py` — regenerates `Full_Turtle_v1.scad` and every
   `v1.0 SCADs/*.scad` from `lib/` + `src/`. This is the sync step.
4. `python3 build/lint.py` — bundle freshness, `git diff --check`, `lib/`
   hygiene (no top-level side effects), and an OpenSCAD CSG parse of every
   `lib/`, `src/` and bundle file (catches undefined vars, failed asserts,
   unexpected warnings). Seconds, no meshing.
5. `python3 build/test.py` — meshes every component `part` and every
   `assembly_view` headless and checks each against `tests/expected_bounds.json`:
   nonzero exit / timeout / empty mesh / new ERROR line / a WARNING not already
   in the baseline / bounding box moved more than the tolerance all fail it.
   If a dimensional change is **intentional**, re-run `python3 build/baseline.py
   <target>` and review the `tests/expected_bounds.json` diff as the sign-off
   (add a `note` to the changed entry saying why).
6. **Bump `VERSION.json`.** `+0.0.1` for a component-scoped change (one
   `lib/<subsystem>.scad` or one `src/components/*.scad`); `+0.1.0` for a
   full-turtle-scoped change (`src/Full_Turtle.scad`, a world transform, the
   `assembly_view` dispatch, or a `lib/params.scad` value that moves a mating
   interface); `+1.0.0` for a bottle / board / hardware interface break. Append
   a `changelog` entry: version, date, files, one-line reason.
7. **Report** what changed, which bundles regenerated (`git diff --stat`), and
   the lint/test results. STLs are **not** auto-exported — run
   `python3 build/export_stl.py` (writes `v1.0 STLs/<name>_v<version>.stl`) only
   when new fabrication files are actually needed.

Commands from the repository root:

```bash
python3 build/build.py                 # regenerate all bundles (the sync step)
python3 build/build.py --check         # fail if any bundle is stale
python3 build/lint.py
python3 build/test.py                  # or: build/test.py control_cap ecojoiner ...
python3 build/baseline.py <target>     # re-record baseline (intentional changes only)
python3 build/export_stl.py            # versioned PLA-part STLs
openscad -D 'part="non_sail_batten"' -o /tmp/x.stl 'v1.0 SCADs/Turtle_Sail_Apparatus.scad'
git diff --stat && git diff --check
```

Renders are slow under OpenSCAD 2021.01 — the cage is ~90 s per view and a full
turtle view is 2–10 min. `build/test.py` accepts target ids so you can check
just the affected subsystem. `rg` may be absent; use `grep -rn`.

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
- Axle: hex end on the bed, magnet opening upward.
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
- Connect the HopeTurtles.org Python generators to this `lib/` contract after
  checking that repository's actual architecture and interfaces.

## 18. Provenance and maintenance

This handoff combines the development conversation with direct inspection of the repository README, license, full assembly and all eight standalone SCAD files at the snapshot above. Repository values are labelled separately wherever they differ from the conversation. No repository source or remote branch was modified while preparing this document.

Keep this file at the repository root as **`CLAUDE.md`**. That is the project-instruction filename documented by [Claude Code](https://code.claude.com/docs/en/memory). This deliberately extensive handoff can later be split into shorter core instructions and subsystem documents if maintaining it as one file becomes cumbersome.

When updating it, change the inspection date/revision, close resolved discrepancies, and retain enough rationale to prevent a future agent from reintroducing a corrected design error.
