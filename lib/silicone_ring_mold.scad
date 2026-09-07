// ==========================================================================
//  Turtle Body -- silicone ring mold  (lib module)
// --------------------------------------------------------------------------
//  ONE two-part pressed mold that casts, in a single session:
//
//    * `ring_count` FLAT insert-seal rings   -- Ø75 ID / Ø85 OD x 1.5, for
//      the cap insert grooves. Tied to p_seal_groove_root_d().
//    * ONE round AXLE O-RING                 -- nested in the centre of the
//      first flat-ring mold ("an additional mold circle"). ID is tied to
//      the sealing (round) section of the hex-shaft axle,
//      p_axle_oring_id() = p_axle_round_d() (8); CS 2, OD 12.
//
//  The bottom plate carries the flat-ring channels (full depth, scrape-fill),
//  the LOWER half of the O-ring torus, and THREE male alignment pegs. The top
//  plate carries the UPPER half of the O-ring torus, THREE female holes, and
//  the O-ring fill + vent. Press the plates together (pegs seat in holes),
//  fill, cure, split, peel out the rings.
//
//  part = "mold"        exploded inspection view of both plates (NOT a print)
//  part = "mold_bottom" the bottom plate, printable (channels + pegs up)
//  part = "mold_top"    the top plate, printable (channel + holes up)
//  part = "rings"       every cast ring (flat rings + the O-ring torus)
//  part = "oring"       the bare O-ring torus
//
//  Nominal dimensions; no shrinkage compensation. Seals NOT validated (s8).
//
//  Definitions only. Geometry is emitted by silicone_ring_molds().
// ==========================================================================

use <params.scad>

// ---- cast shapes ------------------------------------------------------
// one flat cast ring / flat-channel cutter
module ring_shape(height,
                  inner_d = p_seal_groove_root_d(),       // 75
                  outer_d = p_seal_groove_root_d() + 2 * p_seal_ring_radial_w(),  // 85
                  fn = 240) {
    difference() {
        cylinder(d = outer_d, h = height, $fn = fn);
        translate([0, 0, -p_eps()])
            cylinder(d = inner_d, h = height + 2 * p_eps(), $fn = fn);
    }
}

// the cast O-ring itself (round cross-section torus)
module oring_torus(mean_r = p_axle_oring_mean_r(),
                   tube_r = p_axle_oring_cs() / 2, fn = 240) {
    rotate_extrude($fn = fn)
        translate([mean_r, 0]) circle(r = tube_r, $fn = max(24, floor(fn / 4)));
}

// ---- the two-part pressed mold -------------------------------------
function _srm_flat_od() = p_seal_groove_root_d() + 2 * p_seal_ring_radial_w();  // 85
function _srm_press_wall() = 8;                                                 // rim for the pegs
function _srm_flat_mold_d() = _srm_flat_od() + 2 * _srm_press_wall();           // 101
function _srm_centres(n, spacing) =
    [for (i = [0 : n - 1])
        [_srm_flat_mold_d() / 2 + i * (_srm_flat_mold_d() + spacing),
         _srm_flat_mold_d() / 2]];

// bottom plate: flat-ring channels (full depth), lower half-torus in centre 0,
// three male pegs on the parting face.
module srm_bottom_plate(ring_count = 2, floor_t = 3, spacing = 8,
                        ring_axial_t = p_seal_ring_axial_t(),
                        tube_r = p_axle_oring_cs() / 2,
                        peg_d = 4, peg_h = 4, fn = 240) {
    cs      = _srm_centres(ring_count, spacing);
    fmd     = _srm_flat_mold_d();
    part_z  = floor_t + ring_axial_t;                 // parting face
    align_r = _srm_flat_od() / 2 + peg_d / 2 + 2;     // pegs sit in the rim

    difference() {
        union() {
            hull() for (c = cs) translate(c) cylinder(d = fmd, h = part_z, $fn = fn);
            for (a = [90, 210, 330])
                translate(cs[0] + align_r * [cos(a), sin(a), 0])
                    translate([0, 0, part_z - p_eps()])
                        cylinder(d = peg_d, h = peg_h + p_eps(), $fn = 32);
        }
        // flat-ring channels
        for (c = cs) translate([c[0], c[1], floor_t])
            ring_shape(ring_axial_t + p_eps(), fn = fn);
        // lower half of the O-ring torus, centre of mold 0
        translate([cs[0][0], cs[0][1], part_z])
            oring_torus(tube_r = tube_r, fn = fn);
    }
}

// top plate: upper half-torus in centre 0, three female holes, fill + vent.
// built parting-face-DOWN (Z = 0); "mold_top" flips it for printing.
module srm_top_plate(ring_count = 2, top_floor = 3, spacing = 8,
                     tube_r = p_axle_oring_cs() / 2,
                     mean_r = p_axle_oring_mean_r(),
                     ring_axial_t = p_seal_ring_axial_t(),
                     peg_d = 4, peg_h = 4, peg_fit = 0.35,
                     fill_d = 2, fn = 240) {
    cs      = _srm_centres(ring_count, spacing);
    fmd     = _srm_flat_mold_d();
    plate_t = top_floor + tube_r;
    align_r = _srm_flat_od() / 2 + peg_d / 2 + 2;

    difference() {
        hull() for (c = cs) translate(c) cylinder(d = fmd, h = plate_t, $fn = fn);
        // upper half of the O-ring torus (recessed up from the parting face)
        translate([cs[0][0], cs[0][1], 0])
            oring_torus(tube_r = tube_r, fn = fn);
        // 3 female alignment holes
        for (a = [90, 210, 330])
            translate(cs[0] + align_r * [cos(a), sin(a), 0])
                translate([0, 0, -p_eps()])
                    cylinder(d = peg_d + peg_fit, h = peg_h + 0.5, $fn = 32);
        // fill + vent for the O-ring cavity, 180 deg apart, over the channel
        for (a = [45, 225])
            translate([cs[0][0], cs[0][1], -p_eps()])
                rotate([0, 0, a]) translate([mean_r, 0, 0])
                    cylinder(d = fill_d, h = plate_t + 2 * p_eps(), $fn = 24);
    }
}

// ---- dispatch --------------------------------------------------------
module silicone_ring_molds(part = "mold", ring_count = 2,
                           floor_t = 3, outer_wall = 3, spacing = 8,
                           fn = 240) {
    ring_axial_t = p_seal_ring_axial_t();
    inner_d = p_seal_groove_root_d();
    outer_d = _srm_flat_od();
    tube_r  = p_axle_oring_cs() / 2;
    part_z  = floor_t + ring_axial_t;

    assert(ring_count >= 1 && ring_count == floor(ring_count),
           "silicone_ring_molds: ring_count must be a positive integer.");
    assert(ring_axial_t > 0 && ring_axial_t <= p_seal_groove_axial_h(),
           "Cast ring must not be taller than the groove it seats in.");
    assert(p_seal_ring_radial_w() > p_seal_groove_radial_depth(),
           "Ring must project past the groove root to grip.");
    assert(floor_t > 0 && spacing > 0);
    assert(p_axle_oring_id() > 0 && p_axle_oring_cs() > 0);
    assert(p_axle_oring_od() < inner_d,
           "silicone_ring_molds: O-ring must fit inside the flat-ring bore.");

    cs = _srm_centres(ring_count, spacing);

    if (part == "mold") {
        // exploded: bottom (parting face up), top lifted with its parting
        // face DOWN toward it -- as the halves actually mate.
        srm_bottom_plate(ring_count, floor_t, spacing, fn = fn);
        translate([0, 0, part_z + 10])
            srm_top_plate(ring_count, spacing = spacing, fn = fn);
    }
    else if (part == "mold_bottom")
        srm_bottom_plate(ring_count, floor_t, spacing, fn = fn);
    else if (part == "mold_top")
        // flip about Z so the channel + holes face up for printing; Y stays positive
        translate([0, 0, 3 + tube_r]) mirror([0, 0, 1])
            srm_top_plate(ring_count, spacing = spacing, fn = fn);
    else if (part == "rings") {
        for (c = cs) translate([c[0], c[1], 0])
            ring_shape(ring_axial_t, inner_d, outer_d, fn);
        translate([cs[0][0], cs[0][1], tube_r]) oring_torus(fn = fn);
    }
    else if (part == "oring")
        oring_torus(fn = fn);
    else
        assert(false, str("silicone_ring_molds: unknown part '", part, "'"));

    echo("MOLD: two-part pressed. Flat ring ID/OD/axial = ",
         inner_d, outer_d, ring_axial_t, " x ", ring_count,
         "; centre O-ring ID/OD/CS = ", p_axle_oring_id(), p_axle_oring_od(),
         p_axle_oring_cs(), " (ID tied to axle round dia ", p_axle_round_d(),
         "). 3 pegs (bottom) + 3 holes (top) align the halves.");
}
