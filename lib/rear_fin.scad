// ==========================================================================
//  Turtle Body -- rear fin + solar-panel support  (lib module)
// --------------------------------------------------------------------------
//  One yellow vertical fin, two green bottle-holder shafts, one red solar
//  crossbar. In the standalone the panel + bottle are %-reference only and
//  excluded from F6/STL. See CLAUDE.md s11.
//
//  Shaft length keeps the approved formula 305 + (2/3)(93-24) - 17 = 334.
//  Half-lap and solar-joint clearances are 0.2 mm TOTAL, centred on the
//  12 mm board (slot opening 12.2 mm, not 12.4). TB-07: the green-slat
//  mounting hole is p_rear_shaft_hole_from_front() (103 mm at defaults),
//  matching the assembled Turtle -- not the old fixed 50 mm.
//
//  Definitions only. Geometry is emitted by rear_fin_assembly() or the
//  individual part modules.
// ==========================================================================

use <params.scad>

function rf_t()             = p_wood_t();
function rf_fin_width()     = p_fin_board_w() + p_rear_fin_tab_width();          // 108
function rf_fin_height()    = 3 * p_bottle_d();                                  // 246
function rf_diag()          = (2/3) * p_bottle_d();                              // 54.667
function rf_shaft_length()  = p_rear_shaft_len();                               // 334
function rf_shaft_width()   = p_rear_shaft_width();                             // 59
function rf_solar_holder_len() = p_solar_panel_w();                            // 148
function rf_solar_holder_h()   = 3 * rf_t();                                    // 36
function rf_solar_chamfer()    = 1.5 * rf_t();                                  // 18
function rf_solar_slot_depth() = rf_solar_holder_h() / 2;                       // 18
function rf_solar_notch_x0()   = rf_fin_width() - 2 * rf_t();                    // 84
function rf_shaft_rear_x()     = rf_solar_notch_x0();                            // 84
function rf_shaft_front_x()    = rf_shaft_rear_x() - rf_shaft_length();
function rf_joint_meet_x()     = rf_shaft_rear_x() / 2;
function rf_upper_shaft_z0()   = rf_fin_height() - 3 * rf_t();
function rf_lower_shaft_z0()   = rf_upper_shaft_z0() - p_bottle_d() - rf_t();
function rf_solar_meet_z()     = rf_upper_shaft_z0() + rf_solar_slot_depth();

module rf_assert_valid(half_lap, solar_clear, hole_from_front, hole_d) {
    t = rf_t();
    assert(t > 0 && p_bottle_h() > p_bottle_cap_h() && p_bottle_cap_d() > 0);
    assert(p_bottle_d() > 0 && p_fin_board_w() > 2 * t && p_rear_fin_tab_width() > 0);
    assert(p_solar_panel_w() > 0 && p_solar_panel_h() > 0 && p_solar_panel_t() > 0);
    assert(half_lap >= 0 && solar_clear >= 0);
    assert(rf_shaft_front_x() < 0 && rf_joint_meet_x() > half_lap / 2);
    assert(rf_shaft_width() > t + half_lap);
    assert(half_lap < t && half_lap < p_bottle_d());
    assert(rf_lower_shaft_z0() - half_lap / 2 >= rf_diag(),
           "rear_fin: lower joint intersects the diagonal fin edge.");
    assert(rf_fin_width() > rf_diag());
    assert(solar_clear < t && rf_solar_notch_x0() > solar_clear / 2);
    assert(2 * rf_solar_chamfer() + t + solar_clear < rf_solar_holder_len(),
           "rear_fin: panel width leaves too little red-board material beside the slot.");
    assert(hole_d > 0 && rf_shaft_width() > hole_d);
    assert(hole_from_front > hole_d / 2
           && rf_shaft_front_x() + hole_from_front + hole_d / 2 < 0,
           "rear_fin: shaft hole must stay in the forward, unjointed portion.");
}

module rear_fin(half_lap = p_fit_clearance(), solar_clear = p_fit_clearance(),
                fn = undef) {
    t = rf_t(); eps = p_eps();
    nn = fn == undef ? p_fn_wood() : fn;
    color([1, 0.72, 0.05]) rotate([90, 0, 0])
        linear_extrude(height = t, center = true, $fn = nn) difference() {
            polygon([[0, rf_diag()], [rf_diag(), 0],
                     [rf_fin_width(), 0], [rf_fin_width(), rf_fin_height()],
                     [0, rf_fin_height()]]);
            for (z = [rf_upper_shaft_z0(), rf_lower_shaft_z0()])
                translate([-eps, z - half_lap / 2])
                    square([rf_joint_meet_x() + half_lap / 2 + eps, t + half_lap]);
            translate([rf_solar_notch_x0() - solar_clear / 2,
                       rf_solar_meet_z() - solar_clear / 2])
                square([t + solar_clear,
                        rf_fin_height() - rf_solar_meet_z() + solar_clear / 2 + eps]);
        }
}

module bottle_holder_shaft(z0 = 0, half_lap = p_fit_clearance(),
                           hole_from_front = undef, hole_d = undef, fn = undef) {
    t = rf_t(); eps = p_eps();
    nn  = fn == undef ? p_fn_wood() : fn;
    hff = hole_from_front == undef ? p_rear_shaft_hole_from_front() : hole_from_front;
    hd  = hole_d == undef ? p_m6_clearance_d() : hole_d;
    color([0.2, 0.38, 0.05]) difference() {
        translate([rf_shaft_front_x(), -rf_shaft_width() / 2, z0])
            cube([rf_shaft_length(), rf_shaft_width(), t]);
        translate([rf_shaft_front_x() + hff, 0, z0 - eps])
            cylinder(d = hd, h = t + 2 * eps, $fn = nn);
        translate([rf_joint_meet_x() - half_lap / 2, -(t + half_lap) / 2, z0 - eps])
            cube([rf_shaft_rear_x() - rf_joint_meet_x() + half_lap / 2 + eps,
                  t + half_lap, t + 2 * eps]);
    }
}

module solar_panel_holder(solar_clear = p_fit_clearance(), fn = undef) {
    t = rf_t(); eps = p_eps();
    nn = fn == undef ? p_fn_wood() : fn;
    L = rf_solar_holder_len(); H = rf_solar_holder_h(); ch = rf_solar_chamfer();
    color("red") translate([rf_solar_notch_x0(), 0, rf_upper_shaft_z0()])
        rotate([90, 0, 90]) translate([-L / 2, 0, 0])
            linear_extrude(height = t, $fn = nn) difference() {
                square([L, H]);
                polygon([[0, 0], [ch, 0], [0, ch]]);
                polygon([[L, 0], [L - ch, 0], [L, ch]]);
                translate([(L - t - solar_clear) / 2, -eps])
                    square([t + solar_clear, rf_solar_slot_depth() + solar_clear / 2 + eps]);
            }
}

module rear_fin_assembly(half_lap = p_fit_clearance(), solar_clear = p_fit_clearance(),
                         exploded = 0, fn = undef) {
    rf_assert_valid(half_lap, solar_clear,
                    p_rear_shaft_hole_from_front(), p_m6_clearance_d());
    rear_fin(half_lap, solar_clear, fn);
    translate([-exploded, 0,  exploded]) bottle_holder_shaft(rf_upper_shaft_z0(), half_lap, fn = fn);
    translate([-exploded, 0, -exploded]) bottle_holder_shaft(rf_lower_shaft_z0(), half_lap, fn = fn);
    translate([ exploded, 0,  exploded]) solar_panel_holder(solar_clear, fn);

    echo("REAR FIN: shaft length = ", rf_shaft_length(),
         " | hole from front (TB-07) = ", p_rear_shaft_hole_from_front(),
         " | slot opening = ", rf_t() + half_lap);
}
