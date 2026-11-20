// ==========================================================================
//  Turtle Body -- pressor: bottle clamp block for an Ecojoiner port
//  (lib module, EXPERIMENTAL, v6.6.1)
// --------------------------------------------------------------------------
//  A flat block cut from 15 mm board (p_pressor_t(); the Johns stay 12 mm)
//  that sits in the port gap between a Little John's port face and the
//  bottle. Its inner edge is cut concave to the bottle radius so it wraps the
//  bottle flush. The John's two M5 cap screws pass through the John into two
//  plain Ø6 clearance holes (p_pressor_hole_d(), v6.7.4) in the pressor's
//  straight back edge and push on the hole floors, so turning them in drives
//  the pressor toward the bottle, with no acorn nut. Two pressors per port, one each side, hug the bottle between
//  them. Not built, fitted or tested.
//
//  Local frame (one pressor, as installed on the -X side of the bottle):
//    X = across the port, from the John toward the bottle. X = 0 is the
//        pressor's straight back edge (faces the John).
//    Y = across the port, along the John height, centred on the bottle axis.
//        The block spans the full port height between the Long Johns.
//    Z = along the bottle axis = the pressor board thickness, Z = 0..p_pressor_t().
//  The concave arc is centred at X = back-to-bottle-axis, Y = 0, radius =
//  bottle radius. The block's inner (straight) edge stands
//  p_pressor_wrap() past the bottle's tangent line, so the arc runs out at
//  Y = +-sqrt(r^2 - (r - wrap)^2) and the corners beyond stay square.
//
//  Pressed (installed) state: the arc meets the bottle; the back edge sits
//  p_pressor_travel() off the John face. Relaxed, the back is on the John and
//  the arc stands that far off the bottle.
//
//  Definitions only. Geometry is emitted by pressor(), pressor_2d() or
//  pressor_port_assembly().
// ==========================================================================

use <params.scad>
use <util.scad>
use <ecojoiner.scad>

function pr_t()         = p_pressor_t();                         // 15 (v6.7.4; was the 12 mm stock)
function pr_r()         = p_bottle_d() / 2;
function pr_gap()       = eco_port_gap();                         // 12: John face -> bottle
function pr_core_w()    = pr_gap() - p_pressor_travel();          // 11: back edge -> bottle, on the centreline
function pr_width()     = pr_core_w() + p_pressor_wrap();         // 32: back edge -> inner edge
function pr_height()    = p_port_height() - p_fit_clearance()
                          - 2 * p_pressor_end_trim();             // 80.8: slides between the Long Johns
                                                                  // (v6.6.4: 83.8 printed 3 mm too long)
function pr_axis_x()    = pr_core_w() + pr_r();                   // 53: back edge -> bottle axis
function pr_arc_half()  = let(a = pr_r() - p_pressor_wrap())
                          sqrt(pr_r() * pr_r() - a * a);          // 36.4: arc ends at +-Y
function pr_screw_ys()  = [-p_eco_screw_pair_offset(), p_eco_screw_pair_offset()];
// wood along a screw line, back edge -> bottle surface (the bottle has curved away off-centre)
function pr_wood_at_screw() = let(v = p_eco_screw_pair_offset())
    pr_axis_x() - sqrt(pr_r() * pr_r() - v * v);                  // 15.05
// round hole edges along the back edge (v6.7.4: plain holes, the v6.6.4 pill slots are gone)
function pr_hole_inner_y() = p_eco_screw_pair_offset() - p_pressor_hole_d() / 2;  // 15
function pr_hole_outer_y() = p_eco_screw_pair_offset() + p_pressor_hole_d() / 2;  // 21
// wood behind the hole at its inner edge -- the thinnest point (bottle closest)
function pr_wood_at_hole() = let(v = pr_hole_inner_y())
    pr_axis_x() - sqrt(pr_r() * pr_r() - v * v);                  // 13.77 at Ø84
// how far the cap-screw head stands off the John's outer face when pressed
// (the John is p_wood_t() thick, not the pressor's p_pressor_t())
function pr_head_standoff() = p_m5_bolt_len() - p_wood_t() - p_pressor_travel()
                              - p_pressor_hole_depth();            // 9

function pr_yellow() = [0.95, 0.55, 0.15];

module pressor_assert_valid() {
    assert(pr_core_w() > 0,
           "Pressor: travel leaves no wood on the centreline -- port gap too small.");
    assert(p_pressor_wrap() > 0 && p_pressor_wrap() < pr_r(),
           "Pressor: wrap must be between 0 and the bottle radius (the pair would meet).");
    assert(pr_arc_half() < pr_height() / 2,
           "Pressor: the arc would run out of the top/bottom edge.");
    assert(p_eco_screw_pair_offset() < pr_arc_half(),
           "Pressor: M5 pair sits outside the arc -- the screw lines miss the bottle contact.");
    assert(pr_t() - p_pressor_hole_d() >= 2 * p_pressor_min_wall(),
           "Pressor: board too thin around the M5 holes.");
    assert(p_pressor_hole_d() > p_m5_hole_d(),
           "Pressor: hole must clear the John's M5 screw.");
    assert(pr_wood_at_hole() - p_pressor_hole_depth() >= p_pressor_min_wall(),
           "Pressor: M5 hole too deep -- it would break through toward the bottle.");
    assert(pr_hole_inner_y() > 0,
           "Pressor: the two M5 holes would merge across the centreline.");
    assert(pr_hole_outer_y() <= pr_height() / 2 - p_pressor_min_wall(),
           "Pressor: M5 hole runs too close to the top/bottom edge.");
    assert(pr_head_standoff() >= 0,
           "Pressor: M5 screw too short to reach the hole depth through the John.");
    assert(pr_width() <= p_fin_board_w(),
           "Pressor: wider than the board it is cut from.");
}

// Flat profile, back edge on X = 0, centred on Y = 0.
module pressor_2d(fn = 128) {
    difference() {
        translate([0, -pr_height() / 2]) square([pr_width(), pr_height()]);
        translate([pr_axis_x(), 0]) circle(r = pr_r(), $fn = fn);
    }
}

// One pressor, board thickness on Z = 0..p_pressor_t(), with the two M5
// clearance holes drilled into the back edge at mid-thickness, on the John's
// screw lines. v6.7.4: plain Ø6 holes (v6.6.4's pill slots removed).
module pressor(fn = 128, colored = true) {
    pressor_assert_valid();
    wood_color(pr_yellow(), colored)
        difference() {
            linear_extrude(height = pr_t()) pressor_2d(fn);
            for (y = pr_screw_ys())
                translate([-0.01, y, pr_t() / 2]) rotate([0, 90, 0])
                    cylinder(d = p_pressor_hole_d(), h = p_pressor_hole_depth() + 0.01, $fn = 32);
        }
}

// Inspection view of one port slice, looking down the bottle axis (Z):
// ONE pressor (the -X side) pressed onto the bottle, with a translucent
// stand-in for its Little John (port face at X = -(r + gap)). Bottle axis at
// the origin. The stand-in and the bottle are F5 references only, so F6/STL
// output is always a single piece (v6.6.3; was the mirrored pair). The
// second pressor of a port is the same part, turned to face the bottle from
// the other side. The M5 screws are not modelled (v6.6.2).
module pressor_port_assembly(fn = 128, colored = true, show_references = true) {
    face_x = pr_r() + pr_gap();                       // bottle axis -> John port face
    // pressed: back edge p_pressor_travel() off the John face
    translate([-face_x + p_pressor_travel(), 0, 0]) pressor(fn, colored);
    if (show_references)
        %translate([-face_x - p_wood_t(), -eco_john_height() / 2, -pr_t()])
            cube([p_wood_t(), eco_john_height(), 3 * pr_t()]);
    if (show_references)
        %translate([0, 0, -pr_t()]) cylinder(r = pr_r(), h = 3 * pr_t(), $fn = fn);
}

module pressor_echo() {
    echo(str("PRESSOR: ", pr_width(), " x ", pr_height(), " x ", pr_t(),
             " mm | centreline wood ", pr_core_w(), " | arc +-", pr_arc_half(),
             " | wood on screw line ", pr_wood_at_screw(),
             " | M5 hole d/depth ", p_pressor_hole_d(), "/", p_pressor_hole_depth(),
             " at y +-", p_eco_screw_pair_offset(),
             " | wood behind hole ", pr_wood_at_hole(),
             " | head standoff ", pr_head_standoff()));
}
