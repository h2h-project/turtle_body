// ==========================================================================
//  Turtle Body -- silicone ring molds  (lib module)
// --------------------------------------------------------------------------
//  Two kinds of mold:
//
//  1. FLAT INSERT-SEAL RINGS (part = "mold" / "rings").  Open-top scrape
//     molds: fill the annular channel with silicone, scrape flush with the
//     rim + centre island, peel the cured flat ring. Ø75 ID / Ø85 OD, tied
//     to the cap insert (p_seal_groove_root_d()).
//
//  2. AXLE ROTARY-SEAL O-RING (part = "oring_bottom" / "oring_top" /
//     "oring_pair" / "oring").  A round-cross-section O-ring for the control-
//     cap axle bore. This needs a TWO-PART PRESSED mold: a bottom half and a
//     top half, each with a half-torus channel, that press together to close
//     a full round cavity. THREE male pegs on the bottom half enter THREE
//     female holes in the top half so the halves cannot shift when pressed;
//     fill + vent holes run through the top half. O-ring ID is tied to the
//     axle shaft diameter (p_axle_oring_id() = p_axle_round_d()).
//
//  Nominal dimensions; no shrinkage compensation. The seals are NOT validated
//  -- see CLAUDE.md s8.  Print all mold bodies flat, cavity openings up.
//
//  Definitions only. Geometry is emitted by silicone_ring_molds().
// ==========================================================================

use <params.scad>

// ---- 1. flat insert-seal ring -----------------------------------------
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

module ring_mold(floor_t = 3, outer_wall = 3,
                 ring_axial_t = p_seal_ring_axial_t(),
                 inner_d = p_seal_groove_root_d(),
                 outer_d = p_seal_groove_root_d() + 2 * p_seal_ring_radial_w(),
                 fn = 240) {
    mold_outer_d = outer_d + 2 * outer_wall;
    difference() {
        cylinder(d = mold_outer_d, h = floor_t + ring_axial_t, $fn = fn);
        translate([0, 0, floor_t])
            ring_shape(ring_axial_t + p_eps(), inner_d, outer_d, fn);
    }
}

// ---- 2. axle rotary-seal O-ring + its two-part pressed mold ----------
// the cast O-ring itself (round cross-section torus)
module oring_torus(mean_r = p_axle_oring_mean_r(),
                   tube_r = p_axle_oring_cs() / 2, fn = 240) {
    rotate_extrude($fn = fn)
        translate([mean_r, 0]) circle(r = tube_r, $fn = max(24, fn / 4));
}

// one half of the pressed mold. Built channel-side UP (prints flat as-is).
// is_top = false -> 3 alignment PEGS stand up from the parting face.
// is_top = true  -> 3 alignment HOLES + a fill hole + a vent hole.
module oring_mold_half(is_top = false,
                       mean_r  = p_axle_oring_mean_r(),
                       tube_r  = p_axle_oring_cs() / 2,
                       wall    = 6, floor_t = 3,
                       peg_d = 3, peg_h = 3, peg_fit = 0.4,
                       fill_d = 2, fn = 240) {
    e        = p_eps();
    half_t   = floor_t + tube_r;                 // parting face at Z = half_t
    mold_d   = 2 * (mean_r + tube_r) + 2 * wall;
    align_r  = mean_r + tube_r + 2;               // clear of the channel

    assert(align_r + peg_d / 2 + 1 <= mold_d / 2,
           "oring_mold_half: alignment pegs fall outside the mold plate (raise wall).");

    difference() {
        union() {
            cylinder(d = mold_d, h = half_t, $fn = fn);
            // 3 male alignment pegs on the bottom half
            if (!is_top)
                for (a = [0 : 120 : 359]) rotate([0, 0, a + 60])
                    translate([align_r, 0, half_t - e])
                        cylinder(d = peg_d, h = peg_h + e, $fn = 32);
        }
        // half-torus channel opening at the parting face (plate ends at half_t,
        // so only the lower half of the torus is subtracted)
        translate([0, 0, half_t])
            rotate_extrude($fn = fn)
                translate([mean_r, 0]) circle(r = tube_r, $fn = max(24, fn / 4));

        if (is_top) {
            // 3 female alignment holes (blind, into the parting face)
            for (a = [0 : 120 : 359]) rotate([0, 0, a + 60])
                translate([align_r, 0, half_t - peg_h - 0.5])
                    cylinder(d = peg_d + peg_fit, h = peg_h + 0.5 + e, $fn = 32);
            // fill + vent: through the plate at the channel, 180 deg apart
            for (a = [45, 225]) rotate([0, 0, a])
                translate([mean_r, 0, -e])
                    cylinder(d = fill_d, h = half_t + 2 * e, $fn = 24);
        }
    }
}

// ---- assembly / layout ---------------------------------------------
module silicone_ring_molds(part = "mold", ring_count = 2,
                           floor_t = 3, outer_wall = 3, spacing = 8,
                           fn = 240) {
    inner_d = p_seal_groove_root_d();
    outer_d = p_seal_groove_root_d() + 2 * p_seal_ring_radial_w();
    ring_axial_t = p_seal_ring_axial_t();
    flat_mold_d = outer_d + 2 * outer_wall;
    oring_pitch = 2 * (p_axle_oring_mean_r() + p_axle_oring_cs() / 2) + 2 * 6;

    assert(ring_count >= 1 && ring_count == floor(ring_count),
           "silicone_ring_molds: ring_count must be a positive integer.");
    assert(ring_axial_t > 0 && ring_axial_t <= p_seal_groove_axial_h(),
           "Cast ring must not be taller than the groove it seats in.");
    assert(p_seal_ring_radial_w() > p_seal_groove_radial_depth(),
           "Ring must project past the groove root to grip.");
    assert(floor_t > 0 && outer_wall > 0 && spacing > 0);
    assert(p_axle_oring_id() > 0 && p_axle_oring_cs() > 0);

    module flat_row()
        for (i = [0 : ring_count - 1])
            translate([flat_mold_d / 2 + i * (flat_mold_d + spacing), flat_mold_d / 2, 0]) {
                if (part == "rings") ring_shape(ring_axial_t, inner_d, outer_d, fn);
                else ring_mold(floor_t, outer_wall, ring_axial_t, inner_d, outer_d, fn);
            }

    if (part == "mold" || part == "rings")
        flat_row();
    else if (part == "oring")
        oring_torus(fn = fn);
    else if (part == "oring_bottom")
        oring_mold_half(is_top = false, floor_t = floor_t, fn = fn);
    else if (part == "oring_top")
        oring_mold_half(is_top = true, floor_t = floor_t, fn = fn);
    else if (part == "oring_pair") {
        half_t = floor_t + p_axle_oring_cs() / 2;
        oring_mold_half(is_top = false, floor_t = floor_t, fn = fn);
        // top half flipped over the bottom, lifted for inspection
        translate([0, 0, 2 * half_t + spacing]) rotate([180, 0, 0])
            oring_mold_half(is_top = true, floor_t = floor_t, fn = fn);
    }
    else if (part == "all") {
        // flat molds on the left, the centre O-ring pressed mold to their right
        flat_row();
        translate([ring_count * (flat_mold_d + spacing) + oring_pitch / 2,
                   flat_mold_d / 2, 0]) {
            oring_mold_half(is_top = false, floor_t = floor_t, fn = fn);
            translate([oring_pitch + spacing, 0, 0])
                oring_mold_half(is_top = true, floor_t = floor_t, fn = fn);
        }
    }
    else
        assert(false, str("silicone_ring_molds: unknown part '", part, "'"));

    echo("MOLD (flat insert ring): ID / OD / axial thickness = ",
         inner_d, outer_d, ring_axial_t);
    echo("MOLD (axle O-ring, two-part pressed): ID ", p_axle_oring_id(),
         " / OD ", p_axle_oring_od(), " / CS ", p_axle_oring_cs(),
         " -- ID tied to the axle shaft ", p_axle_round_d(),
         ". 3 male pegs (bottom) + 3 female holes (top) align the halves; "
         , "fill + vent through the top half.");
}
