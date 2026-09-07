// ==========================================================================
//  Turtle Body -- round / hex centre axle  (lib module)
// --------------------------------------------------------------------------
//  Round section bears in the cap; hex section drives the cage and passes
//  through the sail bar. Magnet recess opens at the round end for an AS5600
//  sensing magnet. See CLAUDE.md s9.
//
//  TB-04: derived to the resolved 5 mm cap roof (TB-03). The round section
//  spans `round_inside_cap` (roof underside -> round end, 30 mm, INCLUDING
//  the boss -- do not add the boss again) + the 5 mm roof + 1 mm proud, so
//  the round end still sits 1 mm above the cap's outer face and the overall
//  axle is 59 mm (was 58 mm at the stale 4 mm roof).
//
//  Definitions only. Geometry is emitted by control_axle().
// ==========================================================================

use <params.scad>

module control_axle(round_d        = p_axle_round_d(),
                    round_inside_cap = p_axle_round_inside_cap(),  // 30, roof underside -> round end
                    round_ext      = p_axle_round_ext(),           // 1, proud of the cap face
                    cap_roof_t     = p_cap_roof_t(),               // 5 (TB-03)
                    hex_af         = p_axle_hex_af(),
                    hex_len        = p_axle_hex_len(),
                    join_overlap   = p_axle_join_overlap(),
                    magnet         = true,
                    magnet_d       = p_magnet_d(),
                    magnet_t       = p_magnet_t(),
                    fn             = undef) {
    nn        = fn == undef ? p_fn_plastic() : fn;
    hex_cd    = hex_af / cos(30);
    round_len = round_inside_cap + cap_roof_t + round_ext;
    total_len = hex_len + round_len;

    // ---- interface asserts (inputs from the shared contract) ----
    assert(round_d > 0 && round_d < p_cap_axle_bore_d(),
           "control_axle: round shaft must clear the cap bore.");
    assert(hex_af > round_d && hex_af < p_cage_hex_bore_af(),
           "control_axle: hex across-flats must sit between round dia and cage bore.");
    assert(hex_cd < p_sail_bar_axle_hole_d(),
           "control_axle: hex corners must fit the sail-bar axle hole.");
    assert(join_overlap > 0 && join_overlap < min(hex_len, round_len));
    assert(round_inside_cap > 0 && cap_roof_t > 0 && round_ext >= 0);
    assert(round_inside_cap > p_cap_boss_depth(),
           "control_axle: round section must pass the boss.");
    assert(round_inside_cap < p_cap_insert_len(),
           "control_axle: keep the round end inside the cap's open insert rim.");
    assert(hex_len + round_ext >
           p_cage_bearing_d() / 2 + p_cage_roof_t() + p_top_crossbar_t(),
           "control_axle: axle must reach through the cage roof and sail bar.");
    assert(!magnet || (magnet_d > 0 && magnet_d < round_d
           && magnet_t > 0 && magnet_t < round_inside_cap));

    $fn = nn;
    difference() {
        union() {
            cylinder(d = hex_cd, h = hex_len + join_overlap, $fn = 6);
            translate([0, 0, hex_len - join_overlap])
                cylinder(d = round_d, h = round_len + join_overlap);
        }
        if (magnet)
            translate([0, 0, total_len - magnet_t])
                cylinder(d = magnet_d, h = magnet_t + p_eps());
    }

    echo("AXLE: total / round / hex length = ", total_len, round_len, hex_len);
    echo("AXLE: round dia / hex across flats / hex corners = ", round_d, hex_af, hex_cd);
}

// Print pose: hex end already on Z=0, magnet opening up -- this is the
// as-modelled orientation, so no reseat module is needed.
