// ==========================================================================
//  Turtle Body -- shared helper modules and functions
// --------------------------------------------------------------------------
//  Small pieces that were copy-pasted across the standalone files. Geometry
//  lives in the per-subsystem lib/ modules; this file is only glue.
//
//  Definitions only -- no top-level geometry, no top-level assignments.
// ==========================================================================

use <params.scad>

// Colour wrapper for wooden parts. When colour coding is off, every wooden
// component renders in one neutral wood tone; bottles, hardware, sails and
// printed parts keep their own colours and never call this.
module wood_color(coded_color, enabled = true, neutral = [0.94, 0.83, 0.62]) {
    color(enabled ? coded_color : neutral) children();
}

// scalar clamp
function clamp(v, lo, hi) = v < lo ? lo : (v > hi ? hi : v);

// Visual-only M6 bolt: plain shaft + hex-less cylindrical head. No thread,
// no torque rating -- a placeholder for fit inspection.
//  Local Z=0 is the underside of the head; the shaft runs toward +Z from Z=0
//  (plus an optional tip_extension), the head sits at Z=-head_t..0. Matches
//  the standalone files.
module m6_bolt_placeholder(grip_length, tip_extension = 1,
                           shaft_d = undef, head_d = undef, head_t = undef,
                           color_rgb = [0.15, 0.15, 0.15], fn = 48) {
    sd = shaft_d == undef ? p_m6_bolt_shaft_d() : shaft_d;
    hd = head_d  == undef ? p_m6_bolt_head_d()  : head_d;
    ht = head_t  == undef ? p_m6_bolt_head_t()  : head_t;
    assert(grip_length > 0, "m6_bolt_placeholder: grip_length must be positive.");
    color(color_rgb)
        union() {
            cylinder(d = sd, h = grip_length + tip_extension, $fn = fn);
            translate([0, 0, -ht])
                cylinder(d = hd, h = ht, $fn = fn);
        }
}

// Regular hexagonal prism specified by across-flats width (OpenSCAD's
// cylinder($fn=6) is specified across corners, which is the usual trap).
module hex_prism_af(across_flats, h, center = false) {
    cylinder(d = across_flats / cos(30), h = h, $fn = 6, center = center);
}
