// ==========================================================================
//  Turtle Body -- head fin: front fin  (lib module, EXPERIMENTAL)
// --------------------------------------------------------------------------
//  The rear fin's counterpart on the front (-X) port. Three wooden pieces:
//  one vertical triangular fin and two flat bottle-holder slats, one above
//  and one below the front bottle. The slats bolt to the front port's Little
//  John M5 pairs exactly like the rear-fin shafts, run the length of the
//  bottle, and half-lap into the fin, whose rear edge abuts the bottle base.
//
//  Local frame (installed by the full turtle):
//    X = along the bottle axis, outward. X = 0 is the fin's rear edge = the
//        bottle base. Slats run X = -reach .. overlap; fin X = 0 .. width.
//    Y = across (slat width, fin thickness), centred on the bottle axis.
//    Z = vertical, centred on the bottle axis, +Z = physically UP (v6.3.0).
//        Slats at Z = +-(d/2 .. d/2+t).
//
//  Fin width (X) = the widest board, p_fin_board_w(): the fin is cut across
//  one board. v6.3.1 profile: the top edge runs out to p_head_fin_heel_x()
//  (where the slats end); the leading edge slopes down and FORWARD to a
//  vertical flat toe, p_head_fin_toe_h() tall, at the full width; the bottom
//  edge is full width. v6.3.2: the fin also drops p_head_fin_drop() below
//  that, with a raked forefoot (bottom-front corner set back by
//  p_head_fin_forefoot_setback()); the rear edge runs straight down. Earlier: v5.8.0 symmetric spear head (both corners cut
//  to a flat nose); v6.3.0 the mirror slope (full width along the top).
//
//  Half-laps split the X = 0..overlap common zone at overlap/2: fin slots
//  open from its rear edge, slat slots open from their outer ends. Clearance
//  is 0.2 mm TOTAL, centred on the 12 mm board (opening 12.2), as the rear
//  fin. Not built, fitted or tested.
//
//  Definitions only. Geometry is emitted by head_fin_assembly() or the
//  individual part modules.
// ==========================================================================

use <params.scad>
use <util.scad>

function hf_t()            = p_wood_t();
function hf_fin_width()    = p_head_fin_w();          // 93
function hf_fin_height()   = p_head_fin_h();          // 156
function hf_heel_x()       = p_head_fin_heel_x();     // 48: top-edge length
function hf_toe_h()        = p_head_fin_toe_h();      // 24: bottom-front flat
function hf_drop()         = p_head_fin_drop();       // 36: extension below the toe
function hf_setback()      = p_head_fin_forefoot_setback();   // 18
function hf_bottom_z()     = -hf_fin_height() / 2 - hf_drop();  // -114
// leading-edge X at height z (top heel -> top of the toe flat)
function hf_leading_x(z)   = hf_heel_x()
    + (hf_fin_width() - hf_heel_x())
      * (hf_fin_height() / 2 - z) / (hf_fin_height() - hf_toe_h());
function hf_overlap()      = p_head_slat_overlap();   // 48
function hf_joint_meet_x() = hf_overlap() / 2;        // 24
function hf_slat_length()  = p_head_slat_len();       // 382
function hf_slat_width()   = p_head_slat_width();     // 60
function hf_slat_rear_x()  = hf_overlap();
function hf_slat_front_x() = hf_slat_rear_x() - hf_slat_length();   // -334
// The slats sit flush against the port's Little Johns, so they follow the
// PORT height (== bottle diameter here; the HopeTurtles.org generator adds
// the builder's fit offset to it, v6.3.5).
function hf_upper_slat_z0() = p_port_height() / 2;                  // 42
function hf_lower_slat_z0() = -p_port_height() / 2 - hf_t();        // -54

module hf_assert_valid(half_lap, hole_from_front, hole_d) {
    t = hf_t();
    assert(t > 0 && p_bottle_d() > 0 && p_fin_board_w() > 2 * t);
    assert(half_lap >= 0 && half_lap < t);
    assert(hf_overlap() > half_lap && hf_overlap() < hf_fin_width(),
           "head_fin: slat overlap must sit inside the fin width.");
    assert(hf_heel_x() >= hf_overlap() && hf_heel_x() < hf_fin_width(),
           "head_fin: the top edge must reach at or beyond the slat ends.");
    assert(hf_toe_h() >= 0 && hf_toe_h() < hf_fin_height(),
           "head_fin: the bottom-front flat must be shorter than the fin.");
    assert(hf_drop() >= 0 && hf_setback() >= 0
           && hf_setback() < hf_fin_width() - hf_heel_x(),
           "head_fin: forefoot setback leaves no bottom edge.");
    // every slat end (both faces) must stay behind the sloping leading edge
    for (z = [hf_lower_slat_z0(), hf_lower_slat_z0() + t,
              hf_upper_slat_z0(), hf_upper_slat_z0() + t])
        assert(hf_leading_x(z) > hf_overlap(),
               "head_fin: a slat end pokes through the fin's leading edge.");
    assert(hf_upper_slat_z0() + t + half_lap / 2 < hf_fin_height() / 2,
           "head_fin: upper slat slot breaks out of the fin's top edge.");
    assert(hf_slat_width() > t + half_lap);
    assert(hole_d > 0 && 2 * p_eco_screw_pair_offset() + hole_d < hf_slat_width(),
           "head_fin: M5 hole pair runs off the slat edges.");
    assert(hole_from_front > hole_d / 2
           && hf_slat_front_x() + hole_from_front + hole_d / 2 < 0,
           "head_fin: slat hole must stay in the unjointed portion, behind the bottle base.");
}

module head_fin(half_lap = p_fit_clearance(), fn = undef, colored = true) {
    t = hf_t(); eps = p_eps();
    nn = fn == undef ? p_fn_wood() : fn;
    W = hf_fin_width(); H2 = hf_fin_height() / 2;
    // colour code: blue fin. Neutral: p_wood_shade_fin(), shared with the
    // rear and ballast fins.
    wood_color([0.15, 0.45, 0.85], colored, p_wood_shade_fin()) rotate([90, 0, 0])
        linear_extrude(height = t, center = true, $fn = nn) difference() {
            polygon([[0, hf_bottom_z()], [W - hf_setback(), hf_bottom_z()],
                     [W, -H2], [W, -H2 + hf_toe_h()],
                     [hf_heel_x(), H2], [0, H2]]);
            for (z = [hf_upper_slat_z0(), hf_lower_slat_z0()])
                translate([-eps, z - half_lap / 2])
                    square([hf_joint_meet_x() + half_lap / 2 + eps, t + half_lap]);
        }
}

module head_slat(z0 = 0, half_lap = p_fit_clearance(),
                 hole_from_front = undef, hole_d = undef, colored = true) {
    t = hf_t(); eps = p_eps();
    hff = hole_from_front == undef ? p_head_slat_hole_from_front() : hole_from_front;
    hd  = hole_d == undef ? p_m5_hole_d() : hole_d;
    wood_color([0.55, 0.2, 0.7], colored, p_wood_shade_rear_fin()) difference() {
        translate([hf_slat_front_x(), -hf_slat_width() / 2, z0])
            cube([hf_slat_length(), hf_slat_width(), t]);
        // M5 pair across the slat width, matching the John clamp pair
        for (dy = [-p_eco_screw_pair_offset(), p_eco_screw_pair_offset()])
            translate([hf_slat_front_x() + hff, dy, z0 - eps])
                cylinder(d = hd, h = t + 2 * eps, $fn = 16);
        translate([hf_joint_meet_x() - half_lap / 2, -(t + half_lap) / 2, z0 - eps])
            cube([hf_slat_rear_x() - hf_joint_meet_x() + half_lap / 2 + eps,
                  t + half_lap, t + 2 * eps]);
    }
}

module head_fin_assembly(half_lap = p_fit_clearance(), exploded = 0,
                         fn = undef, colored = true) {
    hf_assert_valid(half_lap, p_head_slat_hole_from_front(), p_m5_hole_d());
    translate([exploded, 0, 0]) head_fin(half_lap, fn, colored);
    translate([0, 0,  exploded]) head_slat(hf_upper_slat_z0(), half_lap, colored = colored);
    translate([0, 0, -exploded]) head_slat(hf_lower_slat_z0(), half_lap, colored = colored);

    echo("HEAD FIN: fin = ", hf_fin_width(), " x ", hf_fin_height() + hf_drop(),
         " | slat length = ", hf_slat_length(),
         " | hole from front = ", p_head_slat_hole_from_front(),
         " | half-lap engagement = ", p_head_half_lap_engagement(),
         " | slot opening = ", hf_t() + half_lap);
}
