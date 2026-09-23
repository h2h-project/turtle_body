// ==========================================================================
//  Turtle Body -- sail shaft: uniform round centre axle  (lib module)
// --------------------------------------------------------------------------
//  TB-08: one uniform round bar top to bottom -- no hex section. The lower
//  (round_inside_cap) portion bears/free-spins in the cap's bore; the upper
//  portion continues on up through the cage hub and the top sail bar's own
//  hole with a light running clearance (p_axle_shaft_hole_d()) and is
//  locked to the ROTATING cage by a single radial M3 set screw through the
//  cage hub (see lib/control_cage.scad) instead of a shaped interference
//  fit. Magnet recess opens at the round/lower end for an AS5600 sensing
//  magnet. See CLAUDE.md s9.
//
//  TB-04: derived to the resolved 5 mm cap roof (TB-03). round_inside_cap
//  spans roof underside -> round end, 30 mm, INCLUDING the boss -- do not
//  add the boss again -- + the 5 mm roof + 1 mm proud, so the shaft's
//  lower end still sits 1 mm above the cap's outer face and the overall
//  shaft is 59 mm.
//
//  Definitions only. Geometry is emitted by sail_shaft().
// ==========================================================================

use <params.scad>

module sail_shaft(round_d          = p_axle_round_d(),
                  round_inside_cap = p_axle_round_inside_cap(),  // 30, roof underside -> round end
                  round_ext        = p_axle_round_ext(),         // 1, proud of the cap face
                  cap_roof_t       = p_cap_roof_t(),              // 5 (TB-03)
                  upper_len        = p_axle_upper_len(),          // 23, continues up through cage + sail bar
                  magnet           = true,
                  magnet_d         = p_magnet_d(),
                  magnet_t         = p_magnet_t(),
                  fn               = undef) {
    nn        = fn == undef ? p_fn_plastic() : fn;
    round_len = round_inside_cap + cap_roof_t + round_ext;
    total_len = upper_len + round_len;

    // ---- interface asserts (inputs from the shared contract) ----
    assert(round_d > 0 && round_d < p_cap_axle_bore_d(),
           "sail_shaft: shaft must clear the cap bore.");
    assert(round_d < p_axle_shaft_hole_d(),
           "sail_shaft: shaft must clear the cage hub / sail bar running hole.");
    assert(round_inside_cap > 0 && cap_roof_t > 0 && round_ext >= 0 && upper_len > 0);
    assert(round_inside_cap > p_cap_boss_depth(),
           "sail_shaft: shaft must pass the boss.");
    assert(round_inside_cap < p_cap_insert_len(),
           "sail_shaft: keep the lower end inside the cap's open insert rim.");
    assert(upper_len + round_ext >
           p_cage_bearing_d() / 2 + p_cage_roof_t() + p_top_crossbar_t(),
           "sail_shaft: shaft must reach through the cage roof and sail bar.");
    assert(!magnet || (magnet_d > 0 && magnet_d < round_d
           && magnet_t > 0 && magnet_t < round_inside_cap));

    $fn = nn;
    difference() {
        cylinder(d = round_d, h = total_len);
        if (magnet)
            translate([0, 0, total_len - magnet_t])
                cylinder(d = magnet_d, h = magnet_t + p_eps());
    }

    echo("SAIL SHAFT: total / round-in-cap / upper length = ", total_len, round_len, upper_len);
    echo("SAIL SHAFT: diameter (uniform, no hex) = ", round_d);
}

// Print pose: either end can sit flat on the bed (a bare cylinder); modelled
// with the upper (cage-lock) end at Z=0 and the magnet opening up, matching
// the as-modelled orientation used before TB-08 -- no reseat module needed.
