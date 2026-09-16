// ==========================================================================
//  Turtle Body -- silicone ring mold  (lib module)
// --------------------------------------------------------------------------
//  ONE two-part pressed mold that casts, in a single session:
//
//    * `ring_count` FLAT insert-seal rings   -- Ø75 ID / Ø85 OD x 1.5, for
//      the cap insert grooves. Tied to p_seal_groove_root_d().
//    * `ring_count` round AXLE O-RINGS       -- one nested in the centre of
//      EVERY flat-ring mold ("an additional mold circle" per ring), so the
//      default 2-ring mold yields TWO O-rings and you get two chances at a
//      good one. ID is tied to the sealing (round) section of the hex-shaft
//      axle, p_axle_oring_id() = p_axle_round_d() (8); CS 2, OD 12.
//
//  The bottom plate carries the flat-ring channels (full depth, scrape-fill),
//  the LOWER half of each O-ring torus, and THREE male alignment pegs. The
//  top plate carries the UPPER half of each O-ring torus, THREE female holes,
//  and one O-ring fill + vent per ring. Press the plates together (pegs seat
//  in holes), fill, cure, split, peel out the rings.
//
//  part = "mold"        PRINTABLE layout -- both plates flat on the bed,
//                       working faces UP, laid side by side so one STL prints
//                       both halves in a single job.
//  part = "mold_bottom" the bottom plate alone, printable (channels + pegs up)
//  part = "mold_top"    the top plate alone, printable (channel + holes up)
//  part = "rings"       every cast ring (flat rings + the O-ring tori)
//  part = "oring"       a single bare O-ring torus
//
//  Nominal dimensions; no shrinkage compensation. Seals NOT validated (s8).
//
//  Definitions only. Geometry is emitted by silicone_ring_molds().
// ==========================================================================

use <params.scad>

// ---- cast shapes ------------------------------------------------------
// The ring is cast SMALLER than the groove it mates to (see
// p_seal_ring_elasticity_reduction()) so the stretchy silicone is under
// radial tension -- and therefore actually grips -- once stretched onto
// the cap, rather than sitting at a 1:1 as-cast fit.
function _srm_cast_inner_d(mate_d = p_seal_groove_root_d(),
                           reduction = p_seal_ring_elasticity_reduction()) =
    mate_d * (1 - reduction);

// one flat cast ring / flat-channel cutter
module ring_shape(height,
                  inner_d = _srm_cast_inner_d(),          // 59.25 (79 mating x 0.75)
                  outer_d = _srm_cast_inner_d() + 2 * p_seal_ring_radial_w(),  // 79.25
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
function _srm_flat_od() = _srm_cast_inner_d() + 2 * p_seal_ring_radial_w();  // 79.25 at reference params
// NOTE: outer_d is a parameter (not always _srm_flat_od()) so a caller can
// override the flat ring's outer diameter -- the rim/peg layout must follow
// whatever ring size is actually being cast.
function _srm_flat_mold_d(outer_d = _srm_flat_od()) = outer_d + 2 * _srm_press_wall();  // 101 at reference params
function _srm_press_wall() = 8;                                                 // rim for the pegs
function _srm_top_floor() = 3;                                                  // top-plate floor over the half-torus
function _srm_centres(n, spacing, outer_d = _srm_flat_od()) =
    [for (i = [0 : n - 1])
        [_srm_flat_mold_d(outer_d) / 2 + i * (_srm_flat_mold_d(outer_d) + spacing),
         _srm_flat_mold_d(outer_d) / 2]];

// bottom plate: flat-ring channels (full depth), a lower half-torus in the
// centre of EVERY flat mold, three male pegs on the parting face.
//
// PEG ANGLES ARE MIRRORED (-90/-210/-330, i.e. 270/150/30) RELATIVE TO THE
// TOP PLATE'S HOLE ANGLES (90/210/330) ON PURPOSE. srm_top_plate is modelled
// parting-face-down (its natural "as used" pose); to print it without
// support it is Z-mirrored into a face-up pose (see "mold_top" below), and
// the user then has to physically turn that printed part back over to seat
// it on the bottom plate. A physical 180 deg turn is a rotation about an
// in-plane (X or Y) axis, not a pure Z-mirror -- it also negates Y, which a
// software mirror(0,0,1) does not. So the top plate's holes land at
// (-90,-210,-330) once the printed part is actually turned over. The bottom
// plate's pegs are placed at that same mirrored set of angles so the two
// physically line up; using the *unmirrored* angles (matching the raw SCAD
// coordinates of both modules) looks right on screen but the printed pegs
// and holes end up diametrically misaligned.
module srm_bottom_plate(ring_count = 2, floor_t = 3, spacing = 8,
                        ring_axial_t = p_seal_ring_axial_t(),
                        ring_inner_d = _srm_cast_inner_d(),
                        ring_outer_d = _srm_flat_od(),
                        tube_r = p_axle_oring_cs() / 2,
                        peg_d = 4, peg_h = 4, fn = 240) {
    cs      = _srm_centres(ring_count, spacing, ring_outer_d);
    fmd     = _srm_flat_mold_d(ring_outer_d);
    part_z  = floor_t + ring_axial_t;                 // parting face
    align_r = ring_outer_d / 2 + peg_d / 2 + 2;       // pegs sit in the rim

    difference() {
        union() {
            hull() for (c = cs) translate(c) cylinder(d = fmd, h = part_z, $fn = fn);
            for (a = [-90, -210, -330])
                translate(cs[0] + align_r * [cos(a), sin(a), 0])
                    translate([0, 0, part_z - p_eps()])
                        cylinder(d = peg_d, h = peg_h + p_eps(), $fn = 32);
        }
        // flat-ring channels
        for (c = cs) translate([c[0], c[1], floor_t])
            ring_shape(ring_axial_t + p_eps(), ring_inner_d, ring_outer_d, fn);
        // lower half of the O-ring torus, centre of every flat mold
        for (c = cs) translate([c[0], c[1], part_z])
            oring_torus(tube_r = tube_r, fn = fn);
    }
}

// top plate: an upper half-torus in the centre of every flat mold, three
// female holes, one fill + vent per O-ring cavity.
// built parting-face-DOWN (Z = 0); "mold_top" flips it for printing.
// Hole angles (90/210/330) are the "as modelled" pose -- see the long note
// on srm_bottom_plate for why the bottom plate's pegs use the mirrored set.
module srm_top_plate(ring_count = 2, top_floor = _srm_top_floor(), spacing = 8,
                     tube_r = p_axle_oring_cs() / 2,
                     mean_r = p_axle_oring_mean_r(),
                     ring_axial_t = p_seal_ring_axial_t(),
                     ring_outer_d = _srm_flat_od(),
                     peg_d = 4, peg_h = 4, peg_fit = 0.35,
                     fill_d = 2, fn = 240) {
    cs      = _srm_centres(ring_count, spacing, ring_outer_d);
    fmd     = _srm_flat_mold_d(ring_outer_d);
    plate_t = top_floor + tube_r;
    align_r = ring_outer_d / 2 + peg_d / 2 + 2;

    difference() {
        hull() for (c = cs) translate(c) cylinder(d = fmd, h = plate_t, $fn = fn);
        // upper half of the O-ring torus (recessed up from the parting face)
        for (c = cs) translate([c[0], c[1], 0])
            oring_torus(tube_r = tube_r, fn = fn);
        // 3 female alignment holes
        for (a = [90, 210, 330])
            translate(cs[0] + align_r * [cos(a), sin(a), 0])
                translate([0, 0, -p_eps()])
                    cylinder(d = peg_d + peg_fit, h = peg_h + 0.5, $fn = 32);
        // fill + vent for each O-ring cavity, 180 deg apart, over the channel
        for (c = cs)
            for (a = [45, 225])
                translate([c[0], c[1], -p_eps()])
                    rotate([0, 0, a]) translate([mean_r, 0, 0])
                        cylinder(d = fill_d, h = plate_t + 2 * p_eps(), $fn = 24);
    }
}

// ---- dispatch --------------------------------------------------------
// ring_inner_d / ring_outer_d / ring_axial_t override the FLAT insert-seal
// ring's cast dimensions (default: derived from lib/params.scad's groove +
// elasticity-reduction formula). The axle O-ring nested inside each flat
// mold is not affected -- it stays tied to p_axle_oring_*().
module silicone_ring_molds(part = "mold", ring_count = 2,
                           floor_t = 3, outer_wall = 3, spacing = 8,
                           fn = 240,
                           ring_inner_d = _srm_cast_inner_d(),
                           ring_outer_d = _srm_flat_od(),
                           ring_axial_t = p_seal_ring_axial_t()) {
    tube_r  = p_axle_oring_cs() / 2;
    part_z  = floor_t + ring_axial_t;
    y_gap   = 20;   // bed gap between the two plates in the "mold" print layout
    ring_radial_w = (ring_outer_d - ring_inner_d) / 2;

    assert(ring_count >= 1 && ring_count == floor(ring_count),
           "silicone_ring_molds: ring_count must be a positive integer.");
    assert(ring_axial_t > 0 && ring_axial_t <= p_seal_groove_axial_h(),
           "Cast ring must not be taller than the groove it seats in.");
    assert(ring_outer_d > ring_inner_d,
           "silicone_ring_molds: ring_outer_d must exceed ring_inner_d.");
    assert(ring_radial_w > p_seal_groove_radial_depth(),
           "Ring must project past the groove root to grip.");
    assert(floor_t > 0 && spacing > 0);
    assert(p_axle_oring_id() > 0 && p_axle_oring_cs() > 0);
    assert(p_axle_oring_od() < ring_inner_d,
           "silicone_ring_molds: O-ring must fit inside the flat-ring bore.");

    cs = _srm_centres(ring_count, spacing, ring_outer_d);

    if (part == "mold") {
        // PRINTABLE layout: both plates flat on the bed, working faces UP,
        // side by side -- one STL, one print job, no support.
        srm_bottom_plate(ring_count, floor_t, spacing, ring_axial_t,
                         ring_inner_d, ring_outer_d, fn = fn);
        translate([0, _srm_flat_mold_d(ring_outer_d) + y_gap, 0])
            translate([0, 0, _srm_top_floor() + tube_r]) mirror([0, 0, 1])
                srm_top_plate(ring_count, spacing = spacing,
                             ring_axial_t = ring_axial_t,
                             ring_outer_d = ring_outer_d, fn = fn);
    }
    else if (part == "mold_bottom")
        srm_bottom_plate(ring_count, floor_t, spacing, ring_axial_t,
                         ring_inner_d, ring_outer_d, fn = fn);
    else if (part == "mold_top")
        // flip about Z so the channel + holes face up for printing; Y stays positive
        translate([0, 0, _srm_top_floor() + tube_r]) mirror([0, 0, 1])
            srm_top_plate(ring_count, spacing = spacing,
                         ring_axial_t = ring_axial_t,
                         ring_outer_d = ring_outer_d, fn = fn);
    else if (part == "rings") {
        for (c = cs) {
            translate([c[0], c[1], 0])
                ring_shape(ring_axial_t, ring_inner_d, ring_outer_d, fn);
            translate([c[0], c[1], tube_r]) oring_torus(fn = fn);
        }
    }
    else if (part == "oring")
        oring_torus(fn = fn);
    else
        assert(false, str("silicone_ring_molds: unknown part '", part, "'"));

    echo("MOLD: two-part pressed, plates printed side by side. Flat ring AS-CAST ID/OD/axial = ",
         ring_inner_d, ring_outer_d, ring_axial_t, " x ", ring_count,
         "; mates to groove root dia ", p_seal_groove_root_d(),
         " (elasticity_reduction ", p_seal_ring_elasticity_reduction(), ")",
         "; one centre O-ring per ring (x ", ring_count,
         "), ID/OD/CS = ", p_axle_oring_id(), p_axle_oring_od(),
         p_axle_oring_cs(), " (ID tied to axle round dia ", p_axle_round_d(),
         "). 3 pegs (bottom) + 3 holes (top) align the halves.");
}
