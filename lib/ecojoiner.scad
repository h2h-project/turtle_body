// ==========================================================================
//  Turtle Body -- Ecojoiner core frame  (lib module)
// --------------------------------------------------------------------------
//  Three interlocked rectangles of Long + Little Johns, four Final Keys and
//  up to twelve pressers with visual M6 bolts. One of the six Little Johns is
//  a "Master John": identical outline, but its two top slots are cut deeper so
//  it can be dropped in last, past the already-seated Johns of the almost-
//  closed frame. Bottle dimensions are sizing inputs only -- this module never
//  emits a bottle. See CLAUDE.md s13.
//
//  Standalone output restores all six ports' pressers. The full Turtle
//  suppresses selected pressers where the rear fin and ballast attach; pass
//  the suppress flags through eco_centered_rectangle().
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
function eco_presser_d()       = max(1, p_bottle_cap_d() - 1);              // 30
function eco_little_slot_1_x() = eco_little_end_span() + eco_slat_t() / 2;
function eco_little_slot_2_x() = eco_john_length() - eco_little_end_span() - eco_slat_t() / 2;
function eco_long_slot_2_x()   = eco_john_length() - eco_long_end_span() - eco_slat_t() / 2;
function eco_rectangle_y()     = eco_long_slot_2_x()
                               - (eco_long_end_span() + eco_slat_t() / 2);
function eco_frame_center()    = [eco_john_length() / 2, eco_rectangle_y() / 2,
                                  eco_john_height() / 2];
function eco_final_key_x_offset() = eco_john_height() / 2 + eco_final_key_width() / 2;
function eco_final_key_z_offset() = eco_john_height() / 2 + eco_slat_t() / 2;

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
}

// ---- 2D profiles ------------------------------------------------------
module eco_top_slot(center_x, depth)
    translate([center_x - eco_slot_width() / 2, eco_john_height() - depth])
        square([eco_slot_width(), depth + 1]);

module eco_center_hole(diameter)
    translate([eco_john_length() / 2, eco_john_height() / 2]) circle(d = diameter);

module eco_screw_holes_2d() {
    translate([p_screw_side_offset(), eco_screw_y_center()]) circle(d = p_m6_clearance_d());
    translate([eco_john_length() - p_screw_side_offset(), eco_screw_y_center()])
        circle(d = p_m6_clearance_d());
}

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

module eco_presser(colored = true)
    wood_color([0.10, 0.34, 0.20], colored, p_wood_shade_eco())
        difference() {
            cylinder(d = eco_presser_d(), h = eco_slat_t());
            translate([0, 0, -0.1])
                cylinder(d = p_m6_clearance_d(), h = eco_slat_t() + 0.2);
        }

module eco_presser_with_m6_bolt(colored = true) {
    eco_presser(colored);
    translate([0, 0, -eco_slat_t()])
        m6_bolt_placeholder(grip_length = 2 * eco_slat_t());
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

    inner_face_y = target_y + inside_sign * eco_slat_t() / 2;
    for (hole_x = [p_screw_side_offset(), eco_john_length() - p_screw_side_offset()]) {
        show = !(suppress_far_hole_presser  && hole_x > eco_john_length() / 2)
             && !(suppress_near_hole_presser && hole_x < eco_john_length() / 2);
        if (show)
            translate([hole_x, inner_face_y, eco_screw_y_center()])
                rotate([inside_sign > 0 ? -90 : 90, 0, 0])
                    eco_presser_with_m6_bolt(colored);
        else
            translate([hole_x, inner_face_y, eco_screw_y_center()])
                rotate([inside_sign > 0 ? -90 : 90, 0, 0])
                    translate([0, 0, -eco_slat_t()])
                        m6_bolt_placeholder(grip_length = 2 * eco_slat_t());
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
         eco_final_key_width(), eco_slat_t(), " | presser dia = ", eco_presser_d());
}
