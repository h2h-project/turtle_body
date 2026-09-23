/*
 Hope Turtle — silicone ring mold, EXPERIMENTAL variant "vX" for the new
 semicircular insert-wrap O-ring grooves. Units: mm. License: CERN-OHL-S-2.0.

 HAND-BUILT ONE-OFF VARIANT — NOT a generated bundle, NOT produced by
 build/build.py, NOT wired into build/manifest.json. Forked from
 lib/silicone_ring_mold.scad (turtle_body v4.0.0), matching the seal-groove
 redesign in scads_v1/Bottle_Control_Cap-vX.scad (2026-09-22, "Rev 6" in
 that file's header): the two insert-wrap seal grooves are no longer a
 rectangular slot for a FLAT cast ring -- they're a semicircular channel for
 a round-section O-ring. This mold casts THAT O-ring instead of the flat one.

 WHAT CHANGED FROM PRODUCTION:
  - The flat-ring cavity (ring_shape(), Ø75 ID / Ø85 OD x 1.5 slab) is GONE
    -- there is no matching groove for it any more in the vX cap, so casting
    it here would be pointless.
  - In its place: `ring_count` BIG O-RINGS, one per insert-wrap groove --
    round cross-section, AS-CAST mean radius tied live to p_insert_shaft_d()/2
    (the cap's actual insert OD/2, so it tracks lib/params.scad automatically)
    SHRUNK by p_seal_ring_elasticity_reduction() (25%, same factor and same
    rationale the old flat ring used -- see the "Big insert-wrap O-ring"
    customizer block below), so the cast ring is under radial tension once
    stretched onto the cap instead of sitting at a slack 1:1 fit. Tube radius
    (cross-section radius) = big_oring_tube_r, default 2 mm to MATCH
    Bottle_Control_Cap-vX.scad's band_channel_depth -- that default is
    NOT live-tied (that value is a customizer literal in a different
    standalone file, same as every other hand-synced number between these
    two vX files); re-check it by hand if band_channel_depth changes there.
    ring_count defaults to 2, matching the cap's 2 grooves exactly -- unlike
    the small axle O-ring below, there's no "extra chances" padding built
    in, since these two rings are each going into a SPECIFIC, different
    groove (different Z position on the cap), not interchangeable spares.
  - The small AXLE O-ring is unchanged and still nested in the centre of
    every big-O-ring's own bore (same "additional mold circle per ring"
    idea as production) -- same ID/OD/CS, tied to p_axle_round_d().
  - The top plate's fill/vent holes for the big O-ring: production's small
    O-ring uses 2 (180 deg apart) because its circumference is tiny (~31 mm
    at the reference params). This ring's circumference is roughly 8x
    longer (~2*pi*40.5 = 254 mm at the current 81 mm insert diameter), so a
    single fill point is unlikely to push silicone all the way around
    before it stops flowing -- this mold instead gives it `big_fill_points`
    (default 4, spaced 90 deg apart) so it can be filled from multiple
    points around the ring. The small axle O-ring keeps the original 2.
  - Same two-part pressed-mold mechanics as production otherwise: bottom
    plate carries the lower half-tori + 3 male pegs, top plate carries the
    upper half-tori + 3 female holes + the fill/vent holes, press together
    (pegs seat in holes), fill, cure, split, peel. part=mold/mold_bottom/
    mold_top/rings/oring all mean the same thing as production; part=
    "big_oring" is new (a single bare big O-ring, matching production's
    "oring" for the small one).

 Nominal dimensions; no shrinkage compensation. Neither this mold's fit nor
 the groove it casts for has been physically validated -- same caveat as
 every other vX file in this set.

 SOURCE OF THE UNCHANGED PORTIONS — lib/silicone_ring_mold.scad + lib/params.scad.
*/

use <../lib/params.scad>

/* [Output] */
part = "mold"; // [mold,mold_bottom,mold_top,rings,big_oring,oring]
ring_count = 2;
curve_segments = 240; // [120:24:480]

/* [Mold body] */
mold_floor_thickness = 3;
mold_spacing = 8; // gap between mold bodies

/* [Big insert-wrap O-ring -- vX]
   true_insert_mean_r is the cap's ACTUAL groove centreline radius --
   p_insert_shaft_d()/2, live from lib/params.scad. Like the old flat ring
   (p_seal_ring_elasticity_reduction()), the ring is cast SMALLER than that
   -- big_oring_mean_r (the AS-CAST mean radius actually passed to the mold
   modules below) is true_insert_mean_r shrunk by big_oring_elasticity_
   reduction, so the stretchy silicone is under radial tension -- and
   therefore actually grips -- once stretched onto the cap, rather than
   sitting at a slack 1:1 fit. Same 25% default as the old flat ring
   (p_seal_ring_elasticity_reduction()); NOT physically validated for a
   ring this size (the flat ring's 25% was itself never validated either --
   see CLAUDE.md s8). Tube radius (cross-section radius) does NOT auto-
   track -- keep it equal to Bottle_Control_Cap-vX.scad's band_channel_depth
   by hand; default 2 mm matches that file's current default. */
true_insert_mean_r = p_insert_shaft_d() / 2;
big_oring_elasticity_reduction = p_seal_ring_elasticity_reduction();  // 0.25
big_oring_mean_r = true_insert_mean_r * (1 - big_oring_elasticity_reduction);  // AS-CAST
big_oring_tube_r = 2;
big_fill_points = 4; // [2:1:8] fill/vent holes spaced evenly around the big ring

// ---- cast shapes (oring_torus copied verbatim from lib/silicone_ring_mold.scad) ----
module oring_torus(mean_r = p_axle_oring_mean_r(),
                   tube_r = p_axle_oring_cs() / 2, fn = 240) {
    rotate_extrude($fn = fn)
        translate([mean_r, 0]) circle(r = tube_r, $fn = max(24, floor(fn / 4)));
}

// ---- the two-part pressed mold (layout helpers copied verbatim) ----
function _srm_mold_d(outer_d) = outer_d + 2 * _srm_press_wall();  // press-wall rim around one ring's footprint
function _srm_press_wall() = 8;
function _srm_top_floor() = 3;
function _srm_centres(n, spacing, outer_d) =
    [for (i = [0 : n - 1])
        [_srm_mold_d(outer_d) / 2 + i * (_srm_mold_d(outer_d) + spacing),
         _srm_mold_d(outer_d) / 2]];

// bottom plate: lower half of the BIG O-ring torus + lower half of the
// SMALL axle O-ring (nested in its bore) in every slot, three male pegs.
// See lib/silicone_ring_mold.scad's srm_bottom_plate() for the long note on
// why the peg angles are mirrored (-90/-210/-330) relative to the top
// plate's hole angles (90/210/330) -- same physical reason applies here
// unchanged (srm_top_plate_vX is modelled parting-face-down and gets
// Z-mirrored for printing, which a real 180-degree turn doesn't match).
module srm_bottom_plate_vX(ring_count = 2, floor_t = 3, spacing = 8,
                           big_mean_r, big_tube_r,
                           small_mean_r = p_axle_oring_mean_r(),
                           small_tube_r = p_axle_oring_cs() / 2,
                           peg_d = 4, peg_h = 4, fn = 240) {
    big_od  = 2 * (big_mean_r + big_tube_r);
    cs      = _srm_centres(ring_count, spacing, big_od);
    fmd     = _srm_mold_d(big_od);
    part_z  = floor_t + big_tube_r;               // parting face -- at the big ring's own equatorial plane
    align_r = big_od / 2 + peg_d / 2 + 2;

    difference() {
        union() {
            hull() for (c = cs) translate(c) cylinder(d = fmd, h = part_z, $fn = fn);
            for (a = [-90, -210, -330])
                translate(cs[0] + align_r * [cos(a), sin(a), 0])
                    translate([0, 0, part_z - p_eps()])
                        cylinder(d = peg_d, h = peg_h + p_eps(), $fn = 32);
        }
        // lower half of the big insert-wrap O-ring
        for (c = cs) translate([c[0], c[1], part_z])
            oring_torus(mean_r = big_mean_r, tube_r = big_tube_r, fn = fn);
        // lower half of the small axle O-ring, nested in the big ring's own bore
        for (c = cs) translate([c[0], c[1], part_z])
            oring_torus(mean_r = small_mean_r, tube_r = small_tube_r, fn = fn);
    }
}

// top plate: upper halves of both tori, three female holes, fill/vent holes
// for each (built parting-face-DOWN, Z = 0; "mold_top" flips it for printing).
module srm_top_plate_vX(ring_count = 2, top_floor = _srm_top_floor(), spacing = 8,
                        big_mean_r, big_tube_r,
                        small_mean_r = p_axle_oring_mean_r(),
                        small_tube_r = p_axle_oring_cs() / 2,
                        peg_d = 4, peg_h = 4, peg_fit = 0.35,
                        fill_d = 2, big_fill_points = 4, fn = 240) {
    big_od  = 2 * (big_mean_r + big_tube_r);
    cs      = _srm_centres(ring_count, spacing, big_od);
    fmd     = _srm_mold_d(big_od);
    plate_t = top_floor + big_tube_r;
    align_r = big_od / 2 + peg_d / 2 + 2;
    big_fill_step = 360 / big_fill_points;

    difference() {
        hull() for (c = cs) translate(c) cylinder(d = fmd, h = plate_t, $fn = fn);
        for (c = cs) translate([c[0], c[1], 0])
            oring_torus(mean_r = big_mean_r, tube_r = big_tube_r, fn = fn);
        for (c = cs) translate([c[0], c[1], 0])
            oring_torus(mean_r = small_mean_r, tube_r = small_tube_r, fn = fn);
        // 3 female alignment holes
        for (a = [90, 210, 330])
            translate(cs[0] + align_r * [cos(a), sin(a), 0])
                translate([0, 0, -p_eps()])
                    cylinder(d = peg_d + peg_fit, h = peg_h + 0.5, $fn = 32);
        // big O-ring: fill/vent spaced evenly around its (much longer) circumference
        for (c = cs)
            for (a = [0 : big_fill_step : 359])
                translate([c[0], c[1], -p_eps()])
                    rotate([0, 0, a]) translate([big_mean_r, 0, 0])
                        cylinder(d = fill_d, h = plate_t + 2 * p_eps(), $fn = 24);
        // small axle O-ring: same 2-point fill/vent production always used
        for (c = cs)
            for (a = [45, 225])
                translate([c[0], c[1], -p_eps()])
                    rotate([0, 0, a]) translate([small_mean_r, 0, 0])
                        cylinder(d = fill_d, h = plate_t + 2 * p_eps(), $fn = 24);
    }
}

// ---- dispatch ----------------------------------------------------------
module silicone_ring_molds_vX(part = "mold", ring_count = 2,
                              floor_t = 3, spacing = 8, fn = 240,
                              // AS-CAST mean radius, already shrunk from the
                              // true insert radius by p_seal_ring_elasticity_
                              // reduction() (25%) for stretch-fit tension --
                              // see the customizer block above for the full note.
                              big_mean_r = (p_insert_shaft_d() / 2) * (1 - p_seal_ring_elasticity_reduction()),
                              big_tube_r = 2,
                              big_fill_points = 4) {
    small_mean_r = p_axle_oring_mean_r();
    small_tube_r = p_axle_oring_cs() / 2;
    big_od  = 2 * (big_mean_r + big_tube_r);
    part_z  = floor_t + big_tube_r;
    y_gap   = 20;

    assert(ring_count >= 1 && ring_count == floor(ring_count),
           "silicone_ring_molds_vX: ring_count must be a positive integer.");
    assert(big_mean_r > big_tube_r,
           "silicone_ring_molds_vX: big O-ring mean radius must exceed its own tube radius (or the bore closes up).");
    assert(big_tube_r > 0 && floor_t > 0 && spacing > 0);
    assert(p_axle_oring_id() > 0 && p_axle_oring_cs() > 0);
    assert(small_mean_r + small_tube_r < big_mean_r - big_tube_r,
           "silicone_ring_molds_vX: small axle O-ring must fit inside the big O-ring's own bore.");
    assert(big_fill_points >= 2 && big_fill_points == floor(big_fill_points),
           "silicone_ring_molds_vX: big_fill_points must be a positive integer >= 2.");

    cs = _srm_centres(ring_count, spacing, big_od);

    if (part == "mold") {
        // PRINTABLE layout: both plates flat on the bed, working faces UP,
        // side by side -- one STL, one print job, no support.
        srm_bottom_plate_vX(ring_count, floor_t, spacing, big_mean_r, big_tube_r,
                            small_mean_r, small_tube_r, fn = fn);
        translate([0, _srm_mold_d(big_od) + y_gap, 0])
            translate([0, 0, _srm_top_floor() + big_tube_r]) mirror([0, 0, 1])
                srm_top_plate_vX(ring_count, spacing = spacing,
                                big_mean_r = big_mean_r, big_tube_r = big_tube_r,
                                small_mean_r = small_mean_r, small_tube_r = small_tube_r,
                                big_fill_points = big_fill_points, fn = fn);
    }
    else if (part == "mold_bottom")
        srm_bottom_plate_vX(ring_count, floor_t, spacing, big_mean_r, big_tube_r,
                            small_mean_r, small_tube_r, fn = fn);
    else if (part == "mold_top")
        translate([0, 0, _srm_top_floor() + big_tube_r]) mirror([0, 0, 1])
            srm_top_plate_vX(ring_count, spacing = spacing,
                            big_mean_r = big_mean_r, big_tube_r = big_tube_r,
                            small_mean_r = small_mean_r, small_tube_r = small_tube_r,
                            big_fill_points = big_fill_points, fn = fn);
    else if (part == "rings") {
        for (c = cs) {
            translate([c[0], c[1], big_tube_r])
                oring_torus(mean_r = big_mean_r, tube_r = big_tube_r, fn = fn);
            translate([c[0], c[1], big_tube_r])
                oring_torus(mean_r = small_mean_r, tube_r = small_tube_r, fn = fn);
        }
    }
    else if (part == "big_oring")
        oring_torus(mean_r = big_mean_r, tube_r = big_tube_r, fn = fn);
    else if (part == "oring")
        oring_torus(mean_r = small_mean_r, tube_r = small_tube_r, fn = fn);
    else
        assert(false, str("silicone_ring_molds_vX: unknown part '", part, "'"));

    echo("MOLD vX: two-part pressed, plates printed side by side. Big insert-wrap O-ring AS-CAST mean r / tube r / OD = ",
         big_mean_r, big_tube_r, 2 * (big_mean_r + big_tube_r), " x ", ring_count,
         " (mates to a ", big_tube_r, " mm-radius semicircular groove on the cap -- see",
         " Bottle_Control_Cap-vX.scad's band_channel_depth); fill/vent at ", big_fill_points,
         " points around the ring. Cast ", p_seal_ring_elasticity_reduction() * 100,
         "% smaller than the true mating radius (", big_mean_r / (1 - p_seal_ring_elasticity_reduction()),
         " mm) for stretch-fit tension.");
    echo("MOLD vX: one centre (axle) O-ring per big ring (x ", ring_count,
         "), ID/OD/CS = ", p_axle_oring_id(), p_axle_oring_od(), p_axle_oring_cs(),
         " (ID tied to axle round dia ", p_axle_round_d(),
         "). 3 pegs (bottom) + 3 holes (top) align the halves.");
}

silicone_ring_molds_vX(part = part, ring_count = ring_count,
                       floor_t = mold_floor_thickness, spacing = mold_spacing,
                       fn = curve_segments,
                       big_mean_r = big_oring_mean_r, big_tube_r = big_oring_tube_r,
                       big_fill_points = big_fill_points);
