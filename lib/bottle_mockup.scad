// ==========================================================================
//  Turtle Body -- lightweight bottle mock-up  (lib module)
// --------------------------------------------------------------------------
//  A translucent visual reference for the full assembly only. The standalone
//  components never emit a bottle. Dedupes the two parallel bottle models
//  that were in the monolith (canonical + "Buzdagi"). See CLAUDE.md s5.
//
//  Local origin at the base; +Z toward the cap. Profile:
//    bottom dome | straight body | top dome | neck | collar | cap
//  summing to bottle_height.
//
//  Definitions only. Geometry is emitted by parametric_bottle().
// ==========================================================================

use <params.scad>

function bm_top_superellipse_radius(t, body_r, neck_r, p) =
    neck_r + (body_r - neck_r) * pow(max(0, 1 - pow(t, p)), 1 / p);

function bm_bottom_superellipse_radius(t, base_r, body_r, p) =
    base_r + (body_r - base_r) * pow(max(0, 1 - pow(1 - t, p)), 1 / p);

module bm_top_dome(h, body_d, neck_d, steps, p) {
    body_r = body_d / 2; neck_r = neck_d / 2;
    rotate_extrude(convexity = 4)
        polygon(concat([[0, 0]],
            [for (i = [0 : steps]) let(t = i / steps)
                [bm_top_superellipse_radius(t, body_r, neck_r, p), h * t]],
            [[0, h]]));
}

module bm_bottom_dome(h, base_d, body_d, steps, p) {
    base_r = base_d / 2; body_r = body_d / 2;
    rotate_extrude(convexity = 4)
        polygon(concat([[0, 0]],
            [for (i = [0 : steps]) let(t = i / steps)
                [bm_bottom_superellipse_radius(t, base_r, body_r, p), h * t]],
            [[0, h]]));
}

module parametric_bottle(bottle_d   = p_bottle_d(),
                         bottle_h   = p_bottle_h(),
                         cap_d      = p_bottle_cap_d(),
                         cap_h      = p_bottle_cap_h(),
                         collar_d   = p_collar_d(),
                         collar_h   = p_bottle_collar_h(),
                         neck_d     = p_bottle_neck_d(),
                         neck_h     = p_bottle_neck_h(),
                         top_dome_h = p_top_dome_h(),
                         bottom_dome_h = p_bottom_dome_h(),
                         dome_p     = p_dome_power(),
                         base_ratio = p_bottle_base_ratio(),
                         steps      = p_bottle_profile_steps()) {
    straight_h = bottle_h - bottom_dome_h - top_dome_h - neck_h - collar_h - cap_h;
    body_z0    = bottom_dome_h;
    top_dome_z0 = body_z0 + straight_h;
    neck_z0    = top_dome_z0 + top_dome_h;
    collar_z0  = neck_z0 + neck_h;
    cap_z0     = collar_z0 + collar_h;
    assert(straight_h > 0, "parametric_bottle: profile heights exceed bottle_height.");

    color("cyan", 0.40) union() {
        bm_bottom_dome(bottom_dome_h, bottle_d * base_ratio, bottle_d, steps, dome_p);
        translate([0, 0, body_z0])
            cylinder(h = straight_h, d = bottle_d, $fn = 48);
        translate([0, 0, top_dome_z0])
            bm_top_dome(top_dome_h, bottle_d, neck_d, steps, dome_p);
        translate([0, 0, neck_z0])
            cylinder(h = neck_h, d = neck_d, $fn = 36);
    }
    color([0, 1, 1, 0.90])
        translate([0, 0, collar_z0]) cylinder(h = collar_h, d = collar_d, $fn = 36);
    color("blue")
        translate([0, 0, cap_z0]) cylinder(h = cap_h, d = cap_d, $fn = 36);
}

// The bottle as cut for the control head: full body/collar/cap, less the
// lower dome (removed below `cut_height`) and a short internal socket bore
// (diameter `socket_d`, up `socket_h`) that the cap insert enters. See
// CLAUDE.md s5 / the "buzdagi" bottle. Local origin at the (removed) base.
module cut_bottle(bottle_d   = p_bottle_d(),
                  bottle_h   = p_bottle_h(),
                  cap_d      = p_bottle_cap_d(),
                  cap_h      = p_bottle_cap_h(),
                  collar_d   = p_collar_d(),
                  collar_h   = p_bottle_collar_h(),
                  neck_d     = p_bottle_neck_d(),
                  neck_h     = p_bottle_neck_h(),
                  top_dome_h = p_top_dome_h(),
                  bottom_dome_h = p_bottom_dome_h(),
                  dome_p     = p_dome_power(),
                  base_ratio = p_bottle_base_ratio(),
                  steps      = p_bottle_profile_steps(),
                  cut_height = p_bottle_cut_height(),
                  socket_d   = p_bottle_socket_d(),
                  socket_h   = p_cap_insert_len(),
                  body_color = [0.0, 0.85, 0.95, 0.40],
                  cap_color  = [0.10, 0.32, 0.92]) {
    straight_h  = bottle_h - bottom_dome_h - top_dome_h - neck_h - collar_h - cap_h;
    body_z0     = bottom_dome_h;
    top_dome_z0 = body_z0 + straight_h;
    neck_z0     = top_dome_z0 + top_dome_h;
    collar_z0   = neck_z0 + neck_h;
    cap_z0      = collar_z0 + collar_h;
    e = p_eps();
    assert(straight_h > 0, "cut_bottle: profile heights exceed bottle_height.");
    assert(cut_height >= body_z0, "cut_bottle: cut plane is above the straight body.");

    color(body_color) difference() {
        union() {
            bm_bottom_dome(bottom_dome_h, bottle_d * base_ratio, bottle_d, steps, dome_p);
            translate([0, 0, body_z0]) cylinder(h = straight_h, d = bottle_d, $fn = 48);
            translate([0, 0, top_dome_z0])
                bm_top_dome(top_dome_h, bottle_d, neck_d, steps, dome_p);
            translate([0, 0, neck_z0]) cylinder(h = neck_h, d = neck_d, $fn = 36);
        }
        translate([-bottle_d, -bottle_d, -e])
            cube([2 * bottle_d, 2 * bottle_d, cut_height + e]);
        translate([0, 0, cut_height - e])
            cylinder(h = socket_h + 2 * e, d = socket_d, $fn = 96);
    }
    color([0, 1, 1, 0.90])
        translate([0, 0, collar_z0]) cylinder(h = collar_h, d = collar_d, $fn = 36);
    color(cap_color)
        translate([0, 0, cap_z0]) cylinder(h = cap_h, d = cap_d, $fn = 36);
}
