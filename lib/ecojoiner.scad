// ==========================================================================
//  Turtle Body -- Ecojoiner core frame  (lib module)
// --------------------------------------------------------------------------
//  Three interlocked rectangles of Long + Little Johns, four Final Keys and
//  the M5 bottle clamps: two black socket-head cap screws at each Little/
//  Master John port end (24 in all), stacked across the John height, each
//  biting into its 5.2 mm hole and poking through to the port side where a
//  black acorn nut bears on the bottle (v5.0.0 replaced the M6 bolt + 12 mm
//  presser disk; v5.1.0 dropped the jam nut and wing head). One of the six Little Johns is
//  a "Master John": identical outline, but its two top slots are cut deeper so
//  it can be dropped in last, past the already-seated Johns of the almost-
//  closed frame. Bottle dimensions are sizing inputs only -- this module never
//  emits a bottle. See CLAUDE.md s13.
//
//  Standalone output clamps all six ports. Where the rear-fin shafts and
//  ballast core slats fill the port gap, the full Turtle passes the suppress
//  flags through eco_centered_rectangle(): those screw pairs then bite through
//  John + slat, backed out so the bare tip just meets the bottle; no acorn.
//  The suppress_* argument names are kept from the presser era.
//
//  Definitions only. Geometry is emitted by eco_ecojoiner_only() or, for the
//  full assembly, by eco_centered_rectangle() + eco_inserted_final_key().
// ==========================================================================

use <params.scad>
use <util.scad>

// ---- derived dimensions (shared contract in, one definition each) -------
function eco_slat_t()        = p_wood_t();
function eco_port_length()   = p_port_length();
function eco_port_height()   = p_port_height();
function eco_john_height()   = eco_port_height() - 2 * eco_slat_t();          // 58
function eco_john_length()   = 2 * eco_port_length() + eco_port_height()
                             + 4 * eco_slat_t();                             // 294
function eco_slot_width()    = eco_slat_t() + p_fit_clearance();             // 12.2
function eco_slot_depth()    = ceil(eco_john_height() / 2);                  // 29
// The Master John is inserted last, into an almost-closed frame, so its two
// top slots run deeper than a standard John's -- normally half the port
// height, capped at 60% of the slat's own height so enough material stays
// below the groove. Rule lifted from the HopeTurtles.org 6FC generator
// (objects/ecojoiner_6fc.py :: master_slot_depth) -- see CLAUDE.md s19.
function eco_master_slot_depth() = min(floor(eco_port_height() / 2),
                                      floor(eco_john_height() * 0.6));      // 34
function eco_long_end_span()   = eco_port_length();
function eco_little_end_span()  = eco_port_length() + eco_slat_t();
function eco_screw_y_center()  = eco_john_height() / 2;
function eco_final_key_length() = eco_port_height() + 4 * eco_slat_t();      // 130
function eco_final_key_width()  = 2 * eco_slat_t();                          // 24
function eco_little_slot_1_x() = eco_little_end_span() + eco_slat_t() / 2;
function eco_little_slot_2_x() = eco_john_length() - eco_little_end_span() - eco_slat_t() / 2;
function eco_long_slot_2_x()   = eco_john_length() - eco_long_end_span() - eco_slat_t() / 2;
function eco_rectangle_y()     = eco_long_slot_2_x()
                               - (eco_long_end_span() + eco_slat_t() / 2);
function eco_frame_center()    = [eco_john_length() / 2, eco_rectangle_y() / 2,
                                  eco_john_height() / 2];
function eco_final_key_x_offset() = eco_john_height() / 2 + eco_final_key_width() / 2;
function eco_final_key_z_offset() = eco_john_height() / 2 + eco_slat_t() / 2;

// ---- M5 clamp stack (see p_m5_*() / p_eco_screw_*() in params) ----------
// Bolt heights on the John: centreline +- the pair offset.
function eco_screw_ys() = [eco_screw_y_center() - p_eco_screw_pair_offset(),
                           eco_screw_y_center() + p_eco_screw_pair_offset()];
// Clear gap between a Little John's port-side face and the bottle at its
// closest point (the bottle is centred between the two Little Johns).
function eco_port_gap() = (eco_rectangle_y() - eco_slat_t() - p_bottle_d()) / 2;   // 12
// The pair sits off the centreline, where the round bottle has curved away:
// distance along the bolt from the John's port face to the bottle surface.
function eco_clamp_reach() = let(r = p_bottle_d() / 2, v = p_eco_screw_pair_offset())
    eco_port_gap() + r - sqrt(r * r - v * v);                                   // 16.05
// Open port, acorn run fully down the thread, dome tip touching the bottle:
// shank tip measured inward from the John's port face, and how far the cap
// screw head then stands off the John's outer face (the adjustable part --
// the screw holds by its bite in the wood).
function eco_clamp_tip()  = eco_clamp_reach() - p_m5_acorn_h() + p_m5_acorn_thread_depth();
function eco_clamp_head_standoff() = p_m5_bolt_len() - eco_slat_t() - eco_clamp_tip();
// Through port (John + rear-fin / ballast slat, no acorn): the bare tip is set
// to just meet the bottle, so the head stands off by whatever is left over.
function eco_through_room() = let(r = p_bottle_d() / 2, v = p_eco_screw_pair_offset())
    r - sqrt(r * r - v * v);                                                     // 4.05
function eco_through_tip() = min(p_m5_bolt_len() - 2 * eco_slat_t(), eco_through_room());
function eco_through_head_standoff() = p_m5_bolt_len() - 2 * eco_slat_t() - eco_through_tip();
// Footprint that must fit on a John face: the larger of the screw head and
// the acorn's across-corners hex.
function eco_clamp_footprint_d() = max(p_m5_head_d(), p_m5_acorn_af() / cos(30));

module eco_assert_valid() {
    assert(eco_john_height() > 0,
           "Ecojoiner: bottle diameter must exceed twice the wood thickness.");
    assert(eco_port_height() == p_bottle_d(),
           "Ecojoiner: port_height must equal canonical bottle_diameter.");
    assert(p_bottle_cap_d() < eco_john_height(), "Ecojoiner: cap hole too large for John height.");
    assert(p_collar_d() < eco_john_height(), "Ecojoiner: collar hole too large for John height.");
    assert(eco_master_slot_depth() >= eco_slot_depth(),
           "Ecojoiner: Master John slot must be at least as deep as a standard slot.");
    assert(eco_master_slot_depth() < eco_john_height(),
           "Ecojoiner: Master John slot would cut through the slat.");
    // M5 clamp pair
    assert(p_eco_screw_pair_offset() + eco_clamp_footprint_d() / 2 <= eco_john_height() / 2,
           "Ecojoiner: M5 screw head / acorn overhangs the John edge -- raise p_eco_screw_edge_inset().");
    assert(2 * p_eco_screw_pair_offset() >= eco_clamp_footprint_d(),
           "Ecojoiner: the two M5 screws of a pair are too close for their heads.");
    assert(p_screw_side_offset() >= eco_clamp_footprint_d() / 2,
           "Ecojoiner: M5 screw head overhangs the John end.");
    assert(p_eco_screw_pair_offset() < p_bottle_d() / 2,
           "Ecojoiner: M5 pair sits outside the bottle silhouette -- acorns cannot reach it.");
    assert(eco_clamp_reach() - p_m5_acorn_h() >= 0,
           "Ecojoiner: acorn nut would sit inside the John -- no room in the port gap.");
    assert(eco_clamp_head_standoff() >= 0,
           "Ecojoiner: M5 screw too short to reach the bottle through the John.");
    assert(eco_through_tip() >= 0,
           "Ecojoiner: M5 screw too short to pass through John + fin/ballast slat.");
}

// ---- 2D profiles ------------------------------------------------------
module eco_top_slot(center_x, depth)
    translate([center_x - eco_slot_width() / 2, eco_john_height() - depth])
        square([eco_slot_width(), depth + 1]);

module eco_center_hole(diameter)
    translate([eco_john_length() / 2, eco_john_height() / 2]) circle(d = diameter);

// Two M5 clearance holes at each end: 4 per Little / Master John.
module eco_screw_holes_2d()
    for (x = [p_screw_side_offset(), eco_john_length() - p_screw_side_offset()])
        for (y = eco_screw_ys())
            translate([x, y]) circle(d = p_m5_hole_d(), $fn = 16);

module eco_long_john_2d()
    difference() {
        square([eco_john_length(), eco_john_height()]);
        eco_top_slot(eco_long_end_span() + eco_slat_t() / 2, eco_slot_depth());
        eco_top_slot(eco_john_length() - eco_long_end_span() - eco_slat_t() / 2, eco_slot_depth());
        eco_center_hole(p_bottle_cap_d());
    }

module eco_little_john_2d()
    difference() {
        square([eco_john_length(), eco_john_height()]);
        eco_top_slot(eco_little_end_span() + eco_slat_t() / 2, eco_slot_depth());
        eco_top_slot(eco_john_length() - eco_little_end_span() - eco_slat_t() / 2, eco_slot_depth());
        eco_center_hole(p_collar_d());
        eco_screw_holes_2d();
    }

// A Little John with deeper top slots -- the last piece fitted to the frame.
module eco_master_john_2d()
    difference() {
        square([eco_john_length(), eco_john_height()]);
        eco_top_slot(eco_little_end_span() + eco_slat_t() / 2, eco_master_slot_depth());
        eco_top_slot(eco_john_length() - eco_little_end_span() - eco_slat_t() / 2, eco_master_slot_depth());
        eco_center_hole(p_collar_d());
        eco_screw_holes_2d();
    }

// ---- 3D parts -------------------------------------------------------
module eco_long_john(colored = true)
    wood_color("yellow", colored, p_wood_shade_eco())
        linear_extrude(height = eco_slat_t()) eco_long_john_2d();

module eco_little_john(colored = true)
    wood_color("seagreen", colored, p_wood_shade_eco())
        linear_extrude(height = eco_slat_t()) eco_little_john_2d();

// Same family as the Little John; darker tint marks the deeper-slotted one.
module eco_master_john(colored = true)
    wood_color([0.13, 0.42, 0.28], colored, p_wood_shade_eco())
        linear_extrude(height = eco_slat_t()) eco_master_john_2d();

module eco_final_key(colored = true)
    wood_color([0.82, 0.78, 0.05], colored, p_wood_shade_eco())
        cube([eco_final_key_length(), eco_final_key_width(), eco_slat_t()]);

// ---- M5 clamp hardware (visual only: no thread, no torque rating) -------
// Local frame: Z = 0 is the John's port-side face, +Z points into the port
// (toward the bottle), the John occupies Z = -slat_t..0.
function eco_m5_black() = [0.07, 0.07, 0.08];

module eco_m5_hex(af, h) cylinder(d = af / cos(30), h = h, $fn = 6);

// Black socket-head cap screw, kept deliberately plain for fast renders:
// one cylinder for the shank, one for the head. tip_z is the shank tip; the
// head sits below tip_z - bolt_len.
module eco_m5_cap_screw(tip_z) color(eco_m5_black()) {
    z0 = tip_z - p_m5_bolt_len();                // underside of the head
    translate([0, 0, z0]) cylinder(d = p_m5_bolt_d(), h = p_m5_bolt_len(), $fn = 12);
    translate([0, 0, z0 - p_m5_head_h()]) cylinder(d = p_m5_head_d(), h = p_m5_head_h(), $fn = 16);
}

// Black acorn nut whose dome tip is at tip_z: hex body + hemispherical dome.
module eco_m5_acorn(tip_z) color(eco_m5_black()) {
    r = p_m5_acorn_af() / 2;
    base = tip_z - p_m5_acorn_h();
    translate([0, 0, base]) eco_m5_hex(p_m5_acorn_af(), p_m5_acorn_h() - r);
    translate([0, 0, tip_z - r]) intersection() {
        sphere(r = r, $fn = 12);
        translate([-r, -r, 0]) cube([2 * r, 2 * r, r]);
    }
}

// Open port: screw bites through the John, acorn on the tip bears on the
// bottle. Through port: screw bites through John + the fin/ballast slat that
// fills the gap, bare tip just meeting the bottle, no acorn.
module eco_m5_clamp(through = false) {
    if (through) eco_m5_cap_screw(tip_z = eco_slat_t() + eco_through_tip());
    else {
        eco_m5_cap_screw(tip_z = eco_clamp_tip());
        eco_m5_acorn(tip_z = eco_clamp_reach());
    }
}

// ---- vertical Johns + rectangle -----------------------------------
module eco_standing_little_john(target_y = 0, inside_sign = 1,
                               suppress_far_hole_presser = false,
                               suppress_near_hole_presser = false,
                               colored = true,
                               is_master = false) {
    multmatrix([[1, 0, 0, 0],
                [0, 0, 1, target_y - eco_slat_t() / 2],
                [0, 1, 0, 0],
                [0, 0, 0, 1]])
        if (is_master) eco_master_john(colored);
        else eco_little_john(colored);

    // "suppressed" ports are the ones a rear-fin / ballast slat fills: the
    // screw pair there bites through John + slat (see eco_m5_clamp()).
    inner_face_y = target_y + inside_sign * eco_slat_t() / 2;
    for (hole_x = [p_screw_side_offset(), eco_john_length() - p_screw_side_offset()]) {
        through = (suppress_far_hole_presser  && hole_x > eco_john_length() / 2)
               || (suppress_near_hole_presser && hole_x < eco_john_length() / 2);
        for (hole_z = eco_screw_ys())
            translate([hole_x, inner_face_y, hole_z])
                rotate([inside_sign > 0 ? -90 : 90, 0, 0])
                    eco_m5_clamp(through);
    }
}

module eco_standing_flipped_long_john(target_x = 0, colored = true)
    multmatrix([[0, 0, 1, target_x - eco_slat_t() / 2],
                [-1, 0, 0, eco_long_slot_2_x()],
                [0, -1, 0, eco_john_height()],
                [0, 0, 0, 1]])
        eco_long_john(colored);

// master_first_john turns this rectangle's first standing Little John (the one
// at target_y = 0) into the deeper-slotted Master John. Exactly one of the
// three rectangles in eco_ecojoiner_only() sets it.
module eco_john_rectangle(suppress_positive_port_pressers = false,
                          suppress_negative_port_pressers = false,
                          colored = true,
                          master_first_john = false) {
    eco_standing_little_john(0, +1, suppress_positive_port_pressers,
                             suppress_negative_port_pressers, colored,
                             is_master = master_first_john);
    eco_standing_little_john(eco_rectangle_y(), -1, suppress_positive_port_pressers,
                             suppress_negative_port_pressers, colored);
    eco_standing_flipped_long_john(eco_little_slot_1_x(), colored);
    eco_standing_flipped_long_john(eco_little_slot_2_x(), colored);
}

// master_first_john is last so the four positional callers in src/Full_Turtle.scad
// (rot, suppress+, suppress-, colored) are unaffected.
module eco_centered_rectangle(rot = [0, 0, 0],
                              suppress_positive_port_pressers = false,
                              suppress_negative_port_pressers = false,
                              colored = true,
                              master_first_john = false) {
    fc = eco_frame_center();
    translate(fc) rotate(rot) translate([-fc[0], -fc[1], -fc[2]])
        eco_john_rectangle(suppress_positive_port_pressers,
                           suppress_negative_port_pressers, colored,
                           master_first_john = master_first_john);
}

module eco_inserted_final_key(x_offset, z_offset, colored = true) {
    fc = eco_frame_center();
    translate([fc[0] + x_offset - eco_final_key_width() / 2,
               fc[1] - eco_final_key_length() / 2,
               fc[2] + z_offset - eco_slat_t() / 2])
        multmatrix([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
            eco_final_key(colored);
}

// ---- the standalone artifact --------------------------------------
module eco_ecojoiner_only(colored = true) {
    eco_assert_valid();
    eco_centered_rectangle([0, 0, 0], colored = colored);
    eco_centered_rectangle([0, 90, 90], colored = colored);
    // Third (last-seated) rectangle: its first standing John is the Master John.
    eco_centered_rectangle([90, 0, 90], colored = colored, master_first_john = true);
    for (x = [-eco_final_key_x_offset(), eco_final_key_x_offset()])
        for (z = [-eco_final_key_z_offset(), eco_final_key_z_offset()])
            eco_inserted_final_key(x, z, colored);

    echo("ECOJOINER: John L/H = ", eco_john_length(), eco_john_height(),
         " | slot depth std/master = ", eco_slot_depth(), eco_master_slot_depth(),
         " | slot w = ", eco_slot_width());
    echo("ECOJOINER: final key L/W/T = ", eco_final_key_length(),
         eco_final_key_width(), eco_slat_t());
    eco_echo_clamp();
}

module eco_echo_clamp() {
    echo("ECOJOINER M5 clamp: black M5x", p_m5_bolt_len(), " cap screws, 2 per John end at +-",
         p_eco_screw_pair_offset(), " | bite hole d = ", p_m5_hole_d(),
         " | port gap = ", eco_port_gap(), " | acorn reach = ", eco_clamp_reach(),
         " | head stand-off = ", eco_clamp_head_standoff(),
         " | fin/ballast ports: tip past slat = ", eco_through_tip(),
         ", head stand-off = ", eco_through_head_standoff());
}
