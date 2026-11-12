# Turtle buoyancy measurements

Use the browser survey at http://127.0.0.1:8765 after running `./run_sim.sh`.
Unknown physical values are deliberately blank. The CAD centre plane is NOT a
predicted water surface. Export CAD before checking geometry or calculating.

## 1. Identify the exact build

Give each loading a unique configuration name, for example `pond_2026-11-12_A`.
Reuse that name in trials only when the equipment, loading and placements match.
Record the bottle diameter, total length including closure, shoulders and base
shape; check against the CAD. Photograph any differences, identify installed or
absent groups, and enter dimensions/notes in Build & water. Correct mismatched
CAD before confirming the displacement shape. Current CAD dimensions come from
`lib/params.scad`, not from this guide.

## 2. Weigh the groups

Supply kilograms (grams ÷ 1000). Note scale resolution and repeat readings.

| Browser group | Include exactly once |
| --- | --- |
| Ecojoiner and clamps | All frame boards, keys, clamp screws/nuts |
| Five ordinary bottles | Each bottle, its closure and any permanent fittings; identify front, rear, port, starboard and bottom |
| Front engraved fin | Fin only |
| Front support slats | Both slats; hardware belongs in the group that actually includes it |
| Rear engraved fin | Fin only |
| Rear supports, panel and screws | Slats, solar holder, panel and attachment hardware |
| Ballast frame, fin and hardware | Wooden ballast assembly and hardware; note separately added ballast |
| Cut control bottle, cap and buttons | Cut bottle and fixed housing/closure parts |
| Sail, frame, cage and shaft | Fabric, frame, rotating cage, shaft and attached hardware |
| Extra loads | Electronics, main battery, servo battery, servo, wiring, cargo and ballast that were not included above |

Use notes to resolve hardware grouping. A loaded assembly's measured mass already
includes its contents: do not add those contents as extra loads again. Displaced
bottle volume never determines bottle mass. Independently weigh the assembled
ready-to-float turtle and enter Complete mass as a cross-check.

## 3. Find the balance points and placements

All positions are metres in the body's nominal, level frame: +X toward the front,
+Y toward port (left looking forward), +Z upward. The origin is the centre of the
bottle-axis intersection, marked in the 3D view. These are BODY coordinates, not
coordinates measured from the ground or from a tilted waterline.

Uniform front/rear wooden fins and the front wooden support group may use the
explicit CAD-uniform centre assumption with measured masses. Other groups need a
measured centre in body coordinates. Balance a detached group along two directions
or suspend it from two points: the vertical balance lines locate its centre.
Repeat in a perpendicular orientation to locate its height. Fit the measured local
balance point into its installed position relative to the bottle-axis datum.
Record the method and uncertainty. Ask for help mapping a local measurement if
needed; do not guess battery or ballast heights.

The group move fields translate both its mass and displacement from CAD. The
measured centre field describes the original installed position BEFORE that
translation. Extra-load centres are their actual installed positions. Groups
support translation only; changed orientations require a new CAD export.

## 4. Define the displaced water boundary

- Solid: exposed solid material, including its cutouts and engraved recesses.
- Sealed: an ordinary bottle or housing whose CAD displacement envelope actually
  matches its closed outer boundary. Confirm the real seal and geometry.
- Flooded: water enters the cavity; no trapped-air buoyancy is credited. Ordinary
  bottles can use a measured, explicitly assumed UNIFORM wall/closure thickness;
  this is a morphological shell model of the CAD envelope. If wall or closure
  thickness varies, provide an appropriate solid-wall displacement STL instead.
- Contained: adds mass only because it is fully inside another displaced envelope.
  Name that enclosing component in notes. Use this for enclosed batteries rather
  than counting their volume again.

The cut control bottle is not automatically a sealed float. A flooded control
housing needs an equivalent solid-wall STL; thickness alone cannot describe its
complex cap, openings and internal parts. Replacement displacement STL files use
METRES and the same BODY coordinates as the browser, not local component millimetres.
They must represent closed, positive-volume solid walls/envelopes. Offsets apply
after importing. Custom uploads remain in `sim/data/meshes/` on this laptop.

An exposed added load can use a measured axis-aligned box, with dimensions in metres.
Do not approximate an irregular immersed load by a box without recording that
assumption. Immobilise liquid payloads: free surfaces and slosh are outside v1.

## 5. Choose water density

Select an explicit freshwater reference (1000 kg/m³), seawater reference
(1025 kg/m³), or enter a measured density. References are assumptions, not measured
water properties. Record water temperature/salinity in trial notes if known.

## 6. Read the fin rulers

The front and rear rulers are vertical relative to the LEVEL turtle. Their zeros
lie in the horizontal centre plane through the front and rear bottle axes; zero
is not the midpoint of either fin's outline or the halfway point along bottle length.

- Values are millimetres. **+20 means the water surface is 20 mm ABOVE the
  bottle-centre plane on that ruler: deeper immersion. −20 is below it.**
- There are 1 mm ticks, longer 5 mm ticks and numbers every 10 mm. Some end ticks
  have no label where the fin edge leaves insufficient room. Do not extrapolate
  beyond the engraved ticks.
- Face A in fabrication files is local fin Y-negative; face B is Y-positive.
  In the assembled workbench, choose PORT or STARBOARD for the side you read.
  The browser uses exported geometry to map each face.
- With the turtle level, use a straightedge/level to confirm the two zero lines
  are at the bottle axes' mid-height before collecting calibration data. Record
  assembly misalignment; fix it or correct the geometry before comparing trials.
- Float freely in calm water, clear of the bottom, walls and taut tethers. Let it
  settle. Read the undisturbed surface, NOT the meniscus rising against the wood.
- Record front and rear readings and which face you read. Repeat three times;
  record a representative value and uncertainty covering wave/readout variation.
  Photograph with a camera near the surface height to reduce parallax.
- Read both sides if possible. Front/rear readings alone do not independently
  determine roll; supply a separate level/inclinometer measurement or additional
  lateral waterline observations. The two broad faces are only a board thickness
  apart, so their difference is a weak roll measurement.

The app predicts the water-plane intersection on EACH tilted ruler. It does not
substitute ruler height for displacement volume. Different front/rear readings
can indicate pitch; a single global reading cannot describe a tilted turtle.

## 7. Record a trial

For each trial, fill in purpose (calibration or independent validation), unique
trial ID, exact configuration name, date/time, density, front/rear readings with
face, uncertainty and roll if available. Notes should include conditions,
waterline range, photo references and any tilt-test outcome.

For a known-weight trial: record the added mass and its body-coordinate position,
then save BEFORE and AFTER as separate configurations and trial observations.
Add the mass to the AFTER configuration's actual load inputs; the trial metadata
alone does not add physical mass to a calculation. Try forward, aft and lateral
placements while retaining a safe flotation margin.

For a gentle tilt test: record direction, approximate release angle and whether
it returns, stays tilted or tips farther. This is a qualitative local-stability
check, not a dynamic capsize validation.

Calculate each exact configuration and compare predicted-minus-measured readings.
The app only compares trials whose configuration name and density match current
inputs; this naming rule requires care when editing loads. Configuration snapshots
and all calculated equilibria are saved with each run. Calibration changes are
manual and documented; two ruler readings cannot independently identify mass,
centre of mass and displacement errors. Reserve fresh trials for validation.

## Save and transfer

Save measurements writes `sim/data/current.yaml`; Download YAML creates a portable
copy and Load file accepts YAML or JSON. Unknown fields/invalid values are rejected.
Runs are saved in `sim/data/runs/`. Back up the entire `sim/data/` directory to keep
custom meshes and calculated histories as well as measurements. To send measurements
here, attach/paste the downloaded YAML and relevant trial photographs.
