// ==========================================================================
//  Turtle Body -- bottom ballast attachment  (lib module)
// --------------------------------------------------------------------------
//  Two green core slats, one orange bottom board, two red lock feet, one
//  yellow ballast fin. No bottle. See CLAUDE.md s12.
//
//  Use clear inner-face spacing (= bottle_diameter), not centre spacing, for
//  bottle clearance. The yellow fin's bottle-seat cut is enlarged by one
//  stock thickness so the bottle clears it -- preserved here. Ballast joints
//  keep nominal stock slot widths (the rear fin's 0.2 mm allowance is NOT
//  added here).
//
//  Definitions only. Geometry is emitted by local_ballast_assembly() or the
//  individual part modules.
// ==========================================================================

use <params.scad>
use <util.scad>

function bl_t()            = p_wood_t();
// The green core slats bolt flush against the Ecojoiner's Little Johns and
// clamp the bottle between them, so they follow the PORT height (== bottle
// diameter here; the HopeTurtles.org generator adds the form's fit offset):
// width == John height, inner-face gap == port height. v5.4.1: written in
// p_port_height() terms (same values) to make that tie explicit.
function bl_core_w()       = p_port_height() - 2 * bl_t();                       // 60 == John height
function bl_core_h()       = p_bottle_h() - p_bottle_cap_h() + 6.0 * bl_t();     // 360
function bl_lower_lobe()   = 2 * bl_t();
function bl_upper_lobe()   = 2 * bl_t();
function bl_core_slot_h()  = bl_t();
function bl_core_slot_depth() = bl_core_w() / 2;
function bl_neck_w()       = p_port_height() - 3 * bl_t();                       // 48
function bl_shoulder_step()   = bl_core_w() - bl_neck_w();                       // 12
// Distance from the slat top down to where the upper 45-degree shoulder cut
// begins. The seated slat top is port_length + t inside the outer John's
// port end, so the cut must start at least that far down or it bites into
// the slat while still inside the John. v5.6.0: was one port_height (84,
// 10 mm inside the John); now one board width lower and never above the
// John end -- max(port_height, port_length) + t (96 at defaults).
function bl_upper_diag_from_top() = max(p_port_height(), p_port_length()) + bl_t();
function bl_upper_diag_start() = bl_core_h() - bl_upper_diag_from_top();
function bl_upper_neck_start() = bl_upper_diag_start() - bl_shoulder_step();
function bl_core_slot_z0() = bl_lower_lobe();
function bl_core_slot_z1() = bl_core_slot_z0() + bl_core_slot_h();
function bl_lower_full_return() = bl_core_slot_z1() + bl_upper_lobe();
function bl_lower_neck_start()  = bl_lower_full_return() + bl_shoulder_step();
function bl_mount_hole_from_top() = p_port_length() + bl_t() - p_screw_side_offset();  // 77
function bl_mount_hole_x()  = bl_core_w() / 2;
function bl_mount_hole_y()  = bl_core_h() - bl_mount_hole_from_top();

function bl_board_len()    = p_ballast_board_len();                              // 318
function bl_board_w()      = p_fin_board_w();                                    // 93
function bl_board_slot_w() = bl_t();
function bl_board_slot_depth()  = p_fin_board_w() / 3;
function bl_center_slot_depth() = p_bottle_d() / 2;
function bl_center_slot()  = bl_board_len() / 2;
function bl_slat_spacing() = p_port_height() + bl_t();                          // 96
function bl_left_slot()    = bl_center_slot() - bl_slat_spacing() / 2;
function bl_right_slot()   = bl_center_slot() + bl_slat_spacing() / 2;
// Solid wood outboard of each red-foot slot. v5.5.0: 2 -> 3 board thicknesses
// (the board grew by 2*t to keep every slot where it was relative to centre)
// so the ends past the foot slots are less likely to split off.
function bl_end_slot_offset() = 3 * bl_t();                                      // 36
function bl_left_end_slot_x0()  = bl_end_slot_offset();
function bl_right_end_slot_x0() = bl_board_len() - bl_end_slot_offset() - bl_board_slot_w();
// 45-degree plan-view chamfer on both corners of the FRONT edge (y = board
// width, the red-foot-slot edge; the yellow fin trails aft from y = 0 in the
// full turtle). Legs are this long along each edge. v5.5.0.
function bl_board_front_chamfer() = 20;

function bl_lock_w()       = 5 * bl_t();                                         // 60
function bl_lock_h()       = 5 * bl_t();
function bl_lock_t()       = bl_t();
function bl_lock_slot_depth() = bl_lock_w() / 2;
function bl_lock_slot_h()  = bl_t();
function bl_lock_chamfer() = 1.5 * bl_t();

function bl_fin_len()      = 3 * p_bottle_d();                                   // 246
function bl_fin_h()        = p_fin_board_w();                                    // 93
function bl_fin_t()        = bl_t();
function bl_fin_lower_protrusion() = 2 * bl_t();
function bl_fin_slot_h()   = bl_t();
function bl_fin_slot_depth()   = p_bottle_d() / 2;
function bl_fin_upper_cut_depth() = p_bottle_d() + bl_t();   // +1 stock thickness so the bottle clears
function bl_fin_upper_cut_z0()    = bl_fin_lower_protrusion() + bl_fin_slot_h() + 1.5 * bl_t();
// One full board thickness of solid material between the chamfer and the
// slot above it (bl_fin_lower_protrusion() - bl_fin_front_chamfer() ==
// bl_t()): was 1.5*bl_t(), leaving only 0.5*bl_t() there -- a thin sliver
// right at the corner between two cuts, weaker than it needs to be.
function bl_fin_front_chamfer()   = bl_fin_lower_protrusion() - bl_t();   // = bl_t()

module bl_assert_valid() {
    t = bl_t();
    assert(p_bottle_h() > p_bottle_cap_h() && t > 0 && p_bottle_d() > 3 * t);
    assert(bl_core_h() - p_bottle_d() - t > 6 * t, "ballast: slat shoulders overlap.");
    assert(p_m5_hole_d() > 0
           && p_eco_screw_pair_offset() + p_m5_hole_d() / 2 < bl_core_w() / 2,
           "ballast: M5 hole pair runs off the core slat edges.");
    assert(bl_mount_hole_from_top() > p_m5_hole_d() / 2
           && bl_mount_hole_from_top() < p_bottle_d() - p_m5_hole_d() / 2,
           "ballast: mount holes miss the upper slat end.");
    assert(p_fin_board_w() > max(4.5 * t, p_bottle_d() / 2), "ballast: fin board too narrow.");
    assert(bl_core_w() == p_port_height() - 2 * t,
           "ballast: slat width must use the shared bottle diameter.");
    assert(bl_core_h() - bl_upper_diag_start() >= p_port_length() + t - 0.001,
           "ballast: top shoulder cut must begin at or below the John's port end.");
    assert(bl_upper_neck_start() > bl_lower_neck_start(),
           "ballast: upper and lower shoulder cuts overlap.");
    assert(abs((bl_slat_spacing() - bl_t()) - p_bottle_d()) < 0.001,
           "ballast: slat inner-face gap must equal the shared bottle diameter.");
    assert(bl_board_front_chamfer() >= 0
           && bl_board_front_chamfer() < bl_end_slot_offset()
           && bl_board_front_chamfer() < bl_board_slot_depth(),
           "ballast: board front chamfer would cut into a red-foot slot.");
    assert(abs(bl_center_slot_depth() - bl_fin_slot_depth()) < 0.001,
           "ballast: orange-base and yellow-fin slots must have equal depth.");
}

// ---- 2D profiles + parts -------------------------------------------
module bl_core_profile_2d()
    polygon([[0, 0], [bl_core_w(), 0],
             [bl_core_w(), bl_core_h()], [0, bl_core_h()],
             [0, bl_upper_diag_start()],
             [bl_shoulder_step(), bl_upper_neck_start()],
             [bl_shoulder_step(), bl_lower_neck_start()],
             [0, bl_lower_full_return()],
             [0, bl_core_slot_z1()],
             [bl_core_slot_depth(), bl_core_slot_z1()],
             [bl_core_slot_depth(), bl_core_slot_z0()],
             [0, bl_core_slot_z0()]]);

module ballast_core_slat_part(colored = true)
    wood_color([0.12, 0.38, 0.20], colored, p_wood_shade_ballast())
        linear_extrude(height = bl_t()) difference() {
            bl_core_profile_2d();
            // M5 pair, matching the Little John's clamp pair (v5.0.0)
            for (dx = [-p_eco_screw_pair_offset(), p_eco_screw_pair_offset()])
                translate([bl_mount_hole_x() + dx, bl_mount_hole_y()])
                    circle(d = p_m5_hole_d(), $fn = 16);
        }

module ballast_bottom_board_part(colored = true) {
    e = 0.01;
    wood_color([0.90, 0.38, 0.06], colored, p_wood_shade_ballast())
    linear_extrude(height = bl_t()) difference() {
        let(L = bl_board_len(), W = bl_board_w(), ch = bl_board_front_chamfer())
            polygon([[0, 0], [L, 0], [L, W - ch], [L - ch, W],
                     [ch, W], [0, W - ch]]);
        translate([bl_left_slot() - bl_board_slot_w() / 2, -e])
            square([bl_board_slot_w(), bl_board_slot_depth() + e]);
        translate([bl_center_slot() - bl_board_slot_w() / 2, -e])
            square([bl_board_slot_w(), bl_center_slot_depth() + e]);
        translate([bl_right_slot() - bl_board_slot_w() / 2, -e])
            square([bl_board_slot_w(), bl_board_slot_depth() + e]);
        translate([bl_left_end_slot_x0(), bl_board_w() - bl_board_slot_depth()])
            square([bl_board_slot_w(), bl_board_slot_depth() + e]);
        translate([bl_right_end_slot_x0(), bl_board_w() - bl_board_slot_depth()])
            square([bl_board_slot_w(), bl_board_slot_depth() + e]);
    }
}

module bl_lock_profile_2d() {
    y0 = (bl_lock_h() - bl_lock_slot_h()) / 2;
    y1 = y0 + bl_lock_slot_h();
    ch = bl_lock_chamfer();
    polygon([[0, 0], [bl_lock_w() - ch, 0], [bl_lock_w(), ch],
             [bl_lock_w(), bl_lock_h() - ch], [bl_lock_w() - ch, bl_lock_h()],
             [0, bl_lock_h()], [0, y1], [bl_lock_slot_depth(), y1],
             [bl_lock_slot_depth(), y0], [0, y0]]);
}

module ballast_lock_part(colored = true)
    wood_color([0.70, 0.12, 0.10], colored, p_wood_shade_ballast())
        linear_extrude(height = bl_lock_t()) bl_lock_profile_2d();

module bl_fin_profile_2d() {
    e = 0.01; ch = bl_fin_front_chamfer();
    difference() {
        polygon([[ch, 0], [bl_fin_len(), 0], [bl_fin_len(), bl_fin_h()],
                 [0, bl_fin_h()], [0, ch]]);
        translate([-e, bl_fin_lower_protrusion()])
            square([bl_fin_slot_depth() + e, bl_fin_slot_h()]);
        translate([-e, bl_fin_upper_cut_z0()])
            square([bl_fin_upper_cut_depth() + e, bl_fin_h() - bl_fin_upper_cut_z0() + e]);
    }
}

// Shares p_wood_shade_fin() with the rear fin so the two large fins read as a
// matched pair, distinct from the rest of the ballast.
module ballast_fin_part(colored = true)
    wood_color([0.95, 0.72, 0.02], colored, p_wood_shade_fin())
        linear_extrude(height = bl_fin_t()) bl_fin_profile_2d();

// ---- local assembly ------------------------------------------------
module bl_installed_green_slat(slot_center_x, colored = true)
    multmatrix([[0, 0, 1, slot_center_x - bl_t() / 2],
                [-1, 0, 0, bl_core_w()],
                [0, 1, 0, -bl_core_slot_z0()],
                [0, 0, 0, 1]])
        ballast_core_slat_part(colored);

module bl_installed_lock(slot_x0, colored = true) {
    lock_center_x = slot_x0 + bl_board_slot_w() / 2;
    lock_origin_y = (bl_board_w() - bl_board_slot_depth()) - bl_lock_slot_depth();
    y0 = (bl_lock_h() - bl_lock_slot_h()) / 2;
    multmatrix([[0, 0, 1, lock_center_x - bl_lock_t() / 2],
                [1, 0, 0, lock_origin_y],
                [0, 1, 0, -y0],
                [0, 0, 0, 1]])
        ballast_lock_part(colored);
}

module bl_installed_fin(inspection_pullout = 0, colored = true) {
    fin_origin_y = bl_center_slot_depth() + bl_fin_slot_depth() + inspection_pullout;
    multmatrix([[0, 0, 1, bl_center_slot() - bl_fin_t() / 2],
                [-1, 0, 0, fin_origin_y],
                [0, 1, 0, -bl_fin_lower_protrusion()],
                [0, 0, 0, 1]])
        ballast_fin_part(colored);
}

module local_ballast_assembly(inspection_pullout = 0, colored = true) {
    bl_assert_valid();
    ballast_bottom_board_part(colored);
    bl_installed_lock(bl_left_end_slot_x0(), colored);
    bl_installed_lock(bl_right_end_slot_x0(), colored);
    bl_installed_green_slat(bl_left_slot(), colored);
    bl_installed_green_slat(bl_right_slot(), colored);
    bl_installed_fin(inspection_pullout, colored);

    echo("BALLAST: slat w/len/t = ", bl_core_w(), bl_core_h(), bl_t(),
         " | inner-face gap = ", bl_slat_spacing() - bl_t(),
         " | M5 pair from slat top = ", bl_mount_hole_from_top());
}
