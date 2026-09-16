// ==========================================================================
//  TEST VARIANT — hand-built, NOT produced by build/build.py.
//  Forked from v1.0 SCADs/Bottle_Control_Cap_v1.scad (Turtle Body v1.10.0).
//  Do not treat this as a source-of-truth bundle: it is a one-off experiment
//  and is not wired into lib/, src/, build/build.py, build/lint.py,
//  build/test.py or VERSION.json. If either change below is adopted for
//  real, port it into lib/params.scad + lib/control_cap.scad through the
//  normal workflow (CLAUDE.md section 15) instead of hand-editing this file
//  further.
//
//  Two deliberate deviations from the standard cap:
//   1. Bottle outside diameter used for the insert-fit chain is 85 mm here
//      (vs. the project default 82 mm / p_bottle_d()). This only changes the
//      insert OD (the plug that enters the bottle socket); the cap disk,
//      button and axle-bore dimensions are untouched.
//   2. Two internal tabs are added inside the hollow insert cavity, one on
//      each side along the button axis. Each tab is rooted at the cavity
//      floor (where the hollow meets the solid roof/boss, i.e. the "inside
//      bottom" of the cap), is 22 mm wide (tangential), and projects 2 mm
//      radially inward from the cavity wall -- locally narrowing the
//      circular interior on those two sides. The tab runs the full height
//      of the cavity (floor to the top lip) and then continues 14 mm PAST
//      that lip, so each tab stands proud above the cap as a free post.
//      Purely a fit/registration experiment; not validated.
//
//  Units: mm. License: CERN-OHL-S-2.0 (same as the rest of this repository).
// ==========================================================================

/* [Test bottle fit] */
test_bottle_diameter   = 85;   // overrides p_bottle_d() for the insert-fit chain only
bottle_wall_t          = 0.5;  // same modelling assumption as p_bottle_wall_t()
insert_radial_clearance = 1;   // same as p_insert_shaft_radial_clearance()

/* [Cap body] */
top_disk_thickness  = 5;   // roof / disk thickness
centre_boss_depth   = 2;   // extra projection of the boss into the hollow cap
centre_boss_diameter = 18;
cup_wall_thickness  = 4;
insert_total_h      = 35;
entry_chamfer_h     = 1;
entry_chamfer_delta = 1;

/* [Axle and buttons] */
shaft_hole_d   = 8.6;
button_upper_d = 17;
button_axis    = "y"; // [x,y]
hole_spacing_cc = 24;  // radial position of the two button centres

/* [Axle O-ring gland] */
oring_gland_enable = true;
oring_gland_od = 11.5;      // groove bottom diameter in the bore
oring_gland_width = 2.6;    // groove axial width
oring_gland_from_face = 3.5; // groove centre, below the cap outer face

/* [Silicone band channels] */
band_channels_enable = true;
band_count = 2;             // [0:1:2]
band1_center_z_local = 12;  // groove centre, from the insert shoulder
band2_center_z_local = 25;
band_channel_w = 2;        // groove axial height
band_channel_depth = 2;    // groove radial depth

/* [Side tabs (new)] */
side_tabs_enable = true;
tab_width  = 22;   // tangential width, measured at the cavity-wall radius
tab_depth  = 2;    // radial projection inward from the cavity wall
tab_top_overhang = 14;  // tabs run the FULL cavity height, floor to top lip,
                         // then continue this far again PAST the top lip
tab_corner_fillet = 4;  // rounds the two bottom edges where the tab meets the floor

/* [Render] */
fn = 120; // [48:8:240]

// ---- derived: insert OD from the 85 mm test bottle ----------------------
test_bottle_socket_d = test_bottle_diameter - 2 * bottle_wall_t;              // 84
insert_shaft_d        = test_bottle_socket_d - 2 * insert_radial_clearance;   // 82

// [bundle] begin use <../../lib/control_cap.scad>
// ==========================================================================
//  Turtle Body -- control cap  (lib module)
// --------------------------------------------------------------------------
//  The large stationary disk. Its insert enters the cut bottle body; the
//  rotating cage sits above its flat outer face. NOT the bottle's Ø31 screw
//  cap. See CLAUDE.md s7 / s8.
//
//  TB-03: 5 mm roof + 2 mm internal boss (7 mm axle bearing length).
//  The boss is joined to the roof with a Boolean overlap and survives the
//  cavity subtraction; the central bore passes through both.
//
//  The bore carries an O-RING GLAND (`oring_gland`, on by default): an
//  annular groove in the bore wall that seats a round-section rotary-seal
//  O-ring against the spinning axle round section, waterproofing the bore.
//  The O-ring is cast in lib/silicone_ring_mold.scad; its ID is tied to the
//  axle shaft (p_axle_oring_id() = p_axle_round_d()).
//
//  Definitions only. Geometry is emitted by control_cap().
// ==========================================================================

// [bundle] begin use <params.scad>
// ==========================================================================
//  Turtle Body -- shared dimension contract
// --------------------------------------------------------------------------
//  The single source of truth for every dimension that more than one
//  subsystem depends on. Values are exposed as zero-argument functions so
//  this file can be pulled in with `use <params.scad>` (which ignores
//  top-level variable assignments) without polluting any namespace.
//
//  lib/ modules take these as DEFAULT argument values:
//      module control_cap(roof_t = p_cap_roof_t(), ...) { ... }
//  so a src/ wrapper can still override one value from its customizer block
//  while every other subsystem keeps the shared number.
//
//  Rules:
//   * one function per concept, canonical name (see CLAUDE.md cross-file table)
//   * derived values are functions of other p_*() functions, never re-typed
//   * mm throughout; names say _d (diameter), _r (radius), _t (thickness),
//     _len / _h (axial), _af (hex across-flats)
//   * do NOT add a bare `x = ...;` here -- bundle.py / lint.py will reject it
// ==========================================================================

// ---- tolerances and render quality --------------------------------------
function p_eps()          = 0.02;   // Boolean overlap / cut-through fudge
function p_fit_clearance() = 0.2;   // wood joint: TOTAL extra slot width, centred on the board
function p_fn_plastic()   = 120;    // printed PLA parts (cap, cage, axle, mold)
function p_fn_wood()      = 96;     // cut wooden parts
function p_fn_curve()     = 180;    // fine profile curves (bottle, sails)

// ---- bottle (the foundation reference) ---------------------------------
function p_bottle_d()        = 82;    // outside diameter
function p_bottle_h()        = 305;   // total height incl. ordinary screw cap
function p_bottle_wall_t()   = 0.5;   // modelling assumption, not a measurement
function p_bottle_cap_d()    = 31;    // ordinary screw cap (NOT the control-cap disk)
function p_bottle_cap_h()    = 17;    // ordinary screw cap height (rear-fin / ballast formulas)
function p_collar_d()        = 34;    // bottle collar, independent of cap diameter
function p_top_dome_h()      = 62;
function p_bottom_dome_h()   = 25;
function p_dome_power()      = 2.5;   // superellipse exponent
function p_bottle_neck_h()   = 5;
function p_bottle_collar_h() = 1;
function p_bottle_neck_d()   = p_bottle_cap_d() - 3;   // 28: neck is 3 mm under the cap
function p_bottle_base_ratio() = 0.88; // slightly narrower footprint at the base
function p_bottle_profile_steps() = 16;
// cut bottle (control head): the lower dome is removed and a short socket is
// bored so the control-cap insert slides in. Cut plane sits 5 mm above the
// bottom dome height.
function p_bottle_cut_extra()  = 5;
function p_bottle_cut_height() = p_bottom_dome_h() + p_bottle_cut_extra();   // 30

// nominal bottle interior and the cap insert that enters it
function p_bottle_socket_d() = p_bottle_d() - 2 * p_bottle_wall_t();          // 81
function p_insert_shaft_radial_clearance() = 1;
function p_insert_shaft_d()  = p_bottle_socket_d()
                             - 2 * p_insert_shaft_radial_clearance();          // 79

// ---- wooden stock -----------------------------------------------------
function p_wood_t()          = 12;    // shared board / slat thickness
function p_fin_board_w()     = 93;    // shared fin-system stock width
function p_screw_side_offset() = 25;  // mounting-hole inset from a John end

// ---- Ecojoiner port --------------------------------------------------
function p_port_allowance()  = 20;                 // seating allowance beyond the dome
function p_port_length()     = p_top_dome_h() + p_port_allowance();   // 62 + 20 = 82
function p_port_height()     = p_bottle_d();       // opening height == bottle diameter (asserted)

// ---- M6 hardware ---------------------------------------------------
function p_m6_clearance_d()  = 6.4;   // M6 clearance hole
function p_m6_bolt_shaft_d() = 6;     // visual placeholder only
function p_m6_bolt_head_d()  = 12;
function p_m6_bolt_head_t()  = 4;

// ---- control cap (large stationary disk; see CLAUDE.md s7) ----------
//  TB-03 resolution: repository 5 mm roof / 2 mm boss is authoritative;
//  the axle (below) is derived to this datum.
function p_cap_disk_d()      = 100;   // control-cap disk (independent of p_bottle_cap_d)
function p_cap_roof_t()      = 5;     // disk / roof thickness
function p_cap_boss_depth()  = 2;     // extra projection of the centre boss into the hollow cap
function p_cap_boss_d()      = 18;
function p_cap_insert_len()  = 35;    // straight insert shaft length
function p_cap_insert_wall_t() = 4;
function p_cap_entry_chamfer_h()     = 1;
function p_cap_entry_chamfer_delta() = 1;
function p_cap_axle_bore_d() = 8.6;   // 0.3 mm radial clearance to the Ø8 shaft
function p_cap_cage_radial_clearance() = 1;   // cap disk -> cage inner wall (radial)
function p_cap_total_h()     = p_cap_roof_t() + p_cap_insert_len();           // 40
function p_cap_bearing_len() = p_cap_roof_t() + p_cap_boss_depth();           // 7

// buttons (through both cap and cage)
function p_button_upper_d()  = 17;    // clearance hole in the cap
function p_button_axis()     = "y";   // "x" or "y"
function p_button_radius()   = 24;    // radial position of the two button centres (48 mm apart)

// ---- silicone seal grooves + rings (CLAUDE.md s8) ------------------
function p_seal_groove_count()      = 2;
function p_seal_groove_axial_h()    = 2;   // groove height
function p_seal_groove_radial_depth() = 2; // groove depth
function p_seal_groove1_from_shoulder() = 12;  // groove centre, measured from the insert SHOULDER
function p_seal_groove2_from_shoulder() = 25;
function p_seal_ring_axial_t()      = 1.5;  // cast ring thickness
function p_seal_ring_radial_w()     = 5;    // NOT validated; 3.5 was a suggested milder prototype
function p_seal_groove_root_d() = p_insert_shaft_d()
                                - 2 * p_seal_groove_radial_depth();            // 75

// ---- round / hex centre axle (CLAUDE.md s9) -----------------------
function p_axle_round_d()        = 8;
function p_axle_round_ext()      = 1;    // projection above the cap's outer face
function p_axle_round_inside_cap() = p_cap_insert_len() - 5;  // 30: roof underside to round end (incl. boss)
function p_axle_round_len()      = p_axle_round_inside_cap() + p_cap_roof_t() + p_axle_round_ext();  // 36
function p_axle_hex_af()         = 10.0; // shaft across-flats (0.3 mm to the Ø10.3 cage bore)
function p_axle_hex_len()        = 23;
function p_axle_join_overlap()   = 0.2;  // hex<->round Boolean overlap
function p_axle_total_len()      = p_axle_hex_len() + p_axle_round_len();
function p_axle_hex_corner_d()   = p_axle_hex_af() / cos(30);                  // ~11.55
function p_magnet_d()            = 3;    // AS5600 sensing magnet recess
function p_magnet_t()            = 1;

// ---- axle rotary shaft O-ring (waterproofs the axle bore; cast in the mold) ----
function p_axle_oring_cs()     = 2.0;                                   // cross-section
function p_axle_oring_id()     = p_axle_round_d();                      // 8 -- hugs the shaft
function p_axle_oring_od()     = p_axle_oring_id() + 2 * p_axle_oring_cs();          // 12
function p_axle_oring_mean_r() = (p_axle_oring_id() + p_axle_oring_cs()) / 2;        // 5
//  gland cut into the cap bore for it
function p_cap_oring_squeeze()      = 0.25;  // radial squeeze on the seal
function p_cap_oring_gland_od()     = p_axle_oring_od() - 2 * p_cap_oring_squeeze(); // 11.5
function p_cap_oring_gland_w()      = 1.3 * p_axle_oring_cs();                       // 2.6 axial
function p_cap_oring_gland_from_face() = 3.5; // gland centre, from the cap outer face, along the bore

// ---- rotating control cage (CLAUDE.md s6) ------------------------
function p_cage_wall_t()     = 6.5;   // radial wall thickness
function p_cage_roof_t()     = 4;     // roof / surface plate thickness
function p_cage_inner_d()    = p_cap_disk_d() + 2 * p_cap_cage_radial_clearance();   // 102
function p_cage_outer_d()    = p_cage_inner_d() + 2 * p_cage_wall_t();               // 115
function p_cage_skirt_depth()   = 44;   // roof underside to the ORIGINAL skirt rim
function p_cage_peak_extension() = 20;  // crest extends this far past the original rim
function p_cage_valley_wall_h()  = 10;  // minimum wall depth between mounts
function p_cage_total_h()    = p_cage_skirt_depth() + p_cage_roof_t();              // 48 (native)
function p_cage_notch_count()   = 4;
function p_cage_notch_w()    = 22.5;  // batten groove width
function p_cage_notch_depth() = 3.7;
function p_cage_wave_segments() = 240;
function p_cage_hub_d()      = 29;
function p_cage_pocket_d()   = 26;    // top clip pocket (control_cage top_pocket, OFF by default)
function p_cage_pocket_depth() = 4;   //   "        "     "
function p_cage_hex_bore_af() = 10.3; // central hex bore (0.3 mm to the Ø10.0 shaft)
function p_cage_bearing_d()  = 9;     // hemispherical bearing bump
function p_cage_bearing_count() = 8;
function p_cage_bearing_pcd() = p_cap_disk_d() - p_cage_bearing_d() + 0.5;          // 91.5
function p_cage_top_hole_d() = 18;    // central button / access hole through the roof
function p_cage_mount_hole_d() = 3.2; // two M3 clearance holes per batten / groove
function p_cage_mount_pitch()  = 32;  // vertical pitch of the pair
function p_cage_lower_hole_from_tip() = 10;
function p_cage_roof_bevel() = 3;

// ---- sail apparatus (CLAUDE.md s10) ---------------------------
function p_side_batten_h()   = 205;
function p_side_batten_w()   = 20;
function p_side_batten_radial_t() = 10;
function p_top_crossbar_len() = 6 * p_bottle_d();   // 492
function p_top_crossbar_w()  = 22;
function p_top_crossbar_t()  = p_wood_t();          // 12
function p_sail_bar_axle_hole_d() = 12;             // Ø12; fits the ~11.55 hex corner dia
function p_bottom_rail_len() = 3 * p_bottle_d();    // 246
function p_bottom_rail_bottle_clearance() = 1;
function p_sail_rail_color()  = [0.56, 0.39, 0.39]; // brown (top AND bottom rails)
function p_c_piece_color()    = [1.0, 0.52, 0.20];  // orange, retained

// ---- rear fin + solar support (CLAUDE.md s11) ----------------
function p_solar_panel_w() = 148;
function p_solar_panel_h() = 223;
function p_solar_panel_t() = 2.5;    // real panel, independent of wood thickness
function p_rear_shaft_len() = p_bottle_h()
                            + (2/3) * (p_fin_board_w() - 2 * p_wood_t())
                            - p_bottle_cap_h();                                 // 334
function p_rear_half_lap_engagement() = 42;   // green/yellow interlock depth
function p_rear_fin_tab_width() = 15;
function p_rear_shaft_width()   = 59;
function p_rear_shaft_hole_from_front() =
    p_rear_shaft_len() - p_screw_side_offset() - p_bottle_h()
    + p_bottle_cap_h() + p_port_height();

// ---- ballast attachment (CLAUDE.md s12) ---------------------
function p_ballast_core_w()   = p_bottle_d() - 2 * p_wood_t();                  // 58
function p_ballast_core_len() = p_bottle_h() - p_bottle_cap_h() + 6 * p_wood_t();  // 360
function p_ballast_slat_gap() = p_bottle_d();          // clear inner-face gap
function p_ballast_slat_spacing() = p_bottle_d() + p_wood_t();                  // 94
function p_ballast_board_len() = 3.5 * p_bottle_d();   // 287
function p_ballast_fin_len()   = 3 * p_bottle_d();     // 246
function p_ballast_lock_w()    = 5 * p_wood_t();       // 60

// ---- neutral wood shades (used when enable_color_coding = false) -------
function p_wood_shade_sail()     = [0.85, 0.66, 0.47]; // sail frame  (lightest)
function p_wood_shade_rear_fin() = [0.72, 0.50, 0.33]; // rear-fin shafts + solar holder
function p_wood_shade_eco()      = [0.62, 0.44, 0.28]; // Ecojoiner core
function p_wood_shade_ballast()  = [0.52, 0.34, 0.22]; // ballast slats / board / locks
function p_wood_shade_fin()      = [0.40, 0.26, 0.17]; // rear fin + ballast fin, shared (darkest)
// [bundle] end   <params.scad>
// [bundle] begin use <util.scad>
// ==========================================================================
//  Turtle Body -- shared helper modules and functions
// --------------------------------------------------------------------------
//  Small pieces that were copy-pasted across the standalone files. Geometry
//  lives in the per-subsystem lib/ modules; this file is only glue.
//
//  Definitions only -- no top-level geometry, no top-level assignments.
// ==========================================================================

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
// [bundle] end   <params.scad>

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
// [bundle] end   <util.scad>

function cap_taper_od_at(z_local, top_od, bot_od, insert_len) =
    top_od + (bot_od - top_od) * (z_local / insert_len);

// solid outer form: disk + straight insert + entry chamfer, less the seal grooves
module cap_plug_outer(disk_od, roof_t, insert_len, insert_od,
                      chamfer_h, chamfer_delta,
                      band_enable, band_count, band_z1, band_z2,
                      band_w, band_depth) {
    top_od = insert_od;
    bot_od = insert_od;
    straight_h = insert_len - chamfer_h;

    module base_body() {
        union() {
            cylinder(h = roof_t, d = disk_od);
            translate([0, 0, roof_t])
                cylinder(h = straight_h, d1 = top_od,
                         d2 = cap_taper_od_at(straight_h, top_od, bot_od, insert_len));
            if (chamfer_h > 0)
                translate([0, 0, roof_t + straight_h])
                    cylinder(h = chamfer_h,
                             d1 = cap_taper_od_at(straight_h, top_od, bot_od, insert_len),
                             d2 = max(0.1, bot_od - chamfer_delta));
        }
    }

    module one_groove(center_z) {
        z0 = clamp(center_z - band_w / 2, 0, insert_len);
        z1 = clamp(center_z + band_w / 2, 0, insert_len);
        if (z1 > z0)
            difference() {
                translate([0, 0, roof_t + z0])
                    cylinder(h = z1 - z0,
                             d1 = cap_taper_od_at(z0, top_od, bot_od, insert_len) + p_eps(),
                             d2 = cap_taper_od_at(z1, top_od, bot_od, insert_len) + p_eps());
                translate([0, 0, roof_t + z0 - p_eps() / 2])
                    cylinder(h = z1 - z0 + p_eps(),
                             d1 = max(0.1, cap_taper_od_at(z0, top_od, bot_od, insert_len) - 2 * band_depth),
                             d2 = max(0.1, cap_taper_od_at(z1, top_od, bot_od, insert_len) - 2 * band_depth));
            }
    }

    difference() {
        base_body();
        if (band_enable) {
            if (band_count >= 1) one_groove(band_z1);
            if (band_count >= 2) one_groove(band_z2);
        }
    }
}

module cap_cavity_cut(roof_t, insert_len, insert_od, insert_wall_t,
                      chamfer_h, chamfer_delta) {
    inner_top_od = max(1, insert_od - 2 * insert_wall_t);
    inner_bot_od = inner_top_od;
    inner_tip_od = max(0.5, inner_bot_od - max(0, chamfer_delta));
    straight_h = insert_len - chamfer_h;
    union() {
        translate([0, 0, roof_t - p_eps()])
            cylinder(h = straight_h + 2 * p_eps(), d1 = inner_top_od, d2 = inner_bot_od);
        if (chamfer_h > 0)
            translate([0, 0, roof_t + straight_h])
                cylinder(h = chamfer_h + p_eps(), d1 = inner_bot_od, d2 = inner_tip_od);
    }
}

module cap_button_holes_cut(roof_t, button_d, axis, radius) {
    module hole(x, y)
        translate([x, y, -p_eps()]) cylinder(h = roof_t + 2 * p_eps(), d = button_d);
    if (axis == "x") { hole(radius, 0); hole(-radius, 0); }
    else             { hole(0, radius); hole(0, -radius); }
}

// NEW: two internal ribs ("side tabs") on the hollow insert cavity's inner
// wall, one on each side along the button axis. Each tab has two stacked
// segments. Only the OUTER face (the one that would otherwise poke past
// the cap's own round wall) is curved to match that wall; the INNER face
// and the two tangential SIDE faces stay flat/straight, parallel-sided,
// exactly as in the original flat-cube tab:
//   - RIB (Z = roof_t .. roof_t + lip_h): rooted at the cavity floor (the
//     "inside bottom" where the hollow meets the solid roof/boss), thin --
//     spans from (cavity wall radius - tab_depth) out to the cavity wall
//     radius, i.e. filling in the sides of the circular interior locally.
//     Built as a flat tab_width x tab_depth block, then INTERSECTED with a
//     cylinder at the cavity-wall radius -- this only clips the block's
//     far outer corners back onto the wall's arc; the flat inner face and
//     flat parallel sides are untouched (the intersection doesn't reach
//     them).
//   - LIP EXTENSION (Z = roof_t + lip_h .. + tab_overhang): above the top
//     lip (chamfer tip) there is no cap material at all, so this segment
//     is widened to run the FULL insert wall thickness -- same inner face
//     and same flat parallel sides as the rib -- then intersected with a
//     cylinder at the insert's own outer wall radius, so only ITS outer
//     corners get clipped onto that (larger) arc.
// The two bottom edges of the rib (where its flat SIDE faces meet the
// cavity floor) are rounded with a tab_fillet_r quarter-round, cut with a
// corner-sliver subtraction (only the floor-facing edges; the lip
// extension doesn't touch the floor, so it stays unrounded).
// Not a cut: this ADDS material into the cavity (and, above the lip, past
// the cap's normal outer profile).
module cap_side_tabs(wall_d, outer_wall_d, roof_t, lip_h, tab_width, tab_depth, tab_overhang, axis, tab_fillet_r = 0) {
    r_outer = wall_d / 2;        // cavity wall radius -- rib's outer clip radius
    r_wall  = outer_wall_d / 2;  // insert's outer wall radius -- lip-extension's outer clip radius
    r_inner = r_outer - tab_depth; // shared flat inner face of both segments

    // flat, parallel-sided block: X in [-tab_width/2, tab_width/2],
    // radial coordinate (named Y here) in [r0,r1], axial in [z0,z1].
    // Built along the local +Y axis; one_tab() places it at +/-Y (or, for
    // axis="x", the whole pair is rotated 90 deg afterwards).
    module raw_block(sign, r0, r1, z0, z1) {
        translate([-tab_width / 2, sign > 0 ? r0 : -r1, z0])
            cube([tab_width, r1 - r0, z1 - z0]);
    }

    // clips a solid to a circle of radius r_clip (only trims material that
    // sticks out past that radius -- flat faces already inside it are
    // untouched, so this only rounds the far/outer corners of raw_block).
    module curved_clip(r_clip, z0, z1) {
        translate([0, 0, z0])
            cylinder(r = r_clip, h = z1 - z0);
    }

    // corner-sliver cutter: rounds the edge where local X=0 meets local
    // Z=0 (material assumed at X>0, Z>0) over length `len` along Y, to a
    // quarter-round of radius r.
    module side_sliver(len, r, fn = 48) {
        difference() {
            cube([r, len, r]);
            translate([r, -0.5, r])
                rotate([-90, 0, 0])
                    cylinder(r = r, h = len + 1, $fn = fn);
        }
    }

    module one_tab(sign) {
        rib_y0 = sign > 0 ? r_inner : -r_outer; // start of the rib's radial span
        difference() {
            union() {
                intersection() {
                    raw_block(sign, r_inner, r_outer, roof_t, roof_t + lip_h + p_eps());
                    curved_clip(r_outer, roof_t - p_eps(), roof_t + lip_h + 2 * p_eps());
                }
                intersection() {
                    raw_block(sign, r_inner, r_wall, roof_t + lip_h, roof_t + lip_h + tab_overhang);
                    curved_clip(r_wall, roof_t + lip_h - p_eps(), roof_t + lip_h + tab_overhang + p_eps());
                }
            }
            if (tab_fillet_r > 0) {
                // left side (X = -tab_width/2): material at X > -tab_width/2
                translate([-tab_width / 2, rib_y0, roof_t])
                    side_sliver(r_outer - r_inner, tab_fillet_r);
                // right side (X = +tab_width/2): material at X < +tab_width/2 -> mirror
                translate([tab_width / 2, rib_y0, roof_t])
                    mirror([1, 0, 0])
                        side_sliver(r_outer - r_inner, tab_fillet_r);
            }
        }
    }

    if (axis == "x")
        rotate([0, 0, 90]) { one_tab(1); one_tab(-1); }
    else
        { one_tab(1); one_tab(-1); }
}

module control_cap(disk_od       = p_cap_disk_d(),
                   roof_t        = p_cap_roof_t(),
                   boss_d        = p_cap_boss_d(),
                   boss_depth    = p_cap_boss_depth(),
                   insert_len    = p_cap_insert_len(),
                   insert_od     = p_insert_shaft_d(),
                   insert_wall_t = p_cap_insert_wall_t(),
                   chamfer_h     = p_cap_entry_chamfer_h(),
                   chamfer_delta = p_cap_entry_chamfer_delta(),
                   axle_bore_d   = p_cap_axle_bore_d(),
                   button_d      = p_button_upper_d(),
                   button_axis   = p_button_axis(),
                   button_radius = p_button_radius(),
                   band_enable   = true,
                   band_count    = undef,
                   band_z1       = p_seal_groove1_from_shoulder(),
                   band_z2       = p_seal_groove2_from_shoulder(),
                   band_w        = p_seal_groove_axial_h(),
                   band_depth    = p_seal_groove_radial_depth(),
                   oring_gland   = true,   // rotary seal on the axle round section
                   oring_gland_od = p_cap_oring_gland_od(),
                   oring_gland_w  = p_cap_oring_gland_w(),
                   oring_gland_z  = p_cap_oring_gland_from_face(),
                   side_tabs      = false,  // NEW: two internal cavity ribs + lip extension
                   tab_width_p    = 22,
                   tab_depth_p    = 2,
                   tab_overhang_p = 14,    // how far the lip extension runs past the top lip
                   tab_fillet_p   = 0,     // rounds the rib's two bottom (floor) edges
                   fn            = undef) {
    bc = band_count == undef ? p_seal_groove_count() : band_count;
    nn = fn == undef ? p_fn_plastic() : fn;
    inner_top_od = max(1, insert_od - 2 * insert_wall_t);

    // ---- fit / sanity asserts (kept from the standalone) ----
    assert(disk_od > insert_od && insert_od > 2 * insert_wall_t);
    assert(roof_t > 0 && insert_len > chamfer_h && chamfer_h >= 0);
    assert(insert_wall_t > band_depth && band_depth >= 0);
    assert(band_w > 0 && bc >= 0 && bc <= 2);
    if (band_enable)
        for (z = bc == 2 ? [band_z1, band_z2] : bc == 1 ? [band_z1] : [])
            assert(z - band_w / 2 > 0 && z + band_w / 2 < insert_len - chamfer_h,
                   "control_cap: seal groove must stay inside the straight insert body.");
    if (band_enable && bc == 2)
        assert(abs(band_z2 - band_z1) > band_w, "control_cap: seal grooves overlap.");
    assert(axle_bore_d > 0 && button_radius - button_d / 2 > axle_bore_d / 2);
    assert(button_radius + button_d / 2 < disk_od / 2);
    assert(button_axis == "x" || button_axis == "y");
    assert(boss_depth > 0 && boss_depth < insert_len);
    assert(boss_d > axle_bore_d && boss_d < inner_top_od);
    assert(boss_d / 2 < button_radius - button_d / 2,
           "control_cap: centre boss must clear the button openings.");
    if (oring_gland) {
        assert(oring_gland_od > axle_bore_d && oring_gland_od < boss_d - 1,
               "control_cap: O-ring gland OD must sit between the bore and the boss wall.");
        assert(oring_gland_z - oring_gland_w / 2 > 0.5
               && oring_gland_z + oring_gland_w / 2 < roof_t + boss_depth - 0.5,
               "control_cap: O-ring gland + lands do not fit the axle bore column (deepen the boss or move the gland).");
    }
    if (side_tabs) {
        assert(tab_depth_p > 0 && tab_depth_p < (inner_top_od - boss_d) / 2,
               "control_cap: side tab depth must stay clear of the centre boss.");
        assert(tab_width_p > 0 && tab_width_p < inner_top_od,
               "control_cap: side tab width does not fit the cavity wall.");
        assert(tab_overhang_p > 0,
               "control_cap: side tab overhang must be positive.");
        assert(tab_fillet_p >= 0,
               "control_cap: side tab fillet radius cannot be negative.");
        // The rib runs the full insert_len (floor to top lip); the lip
        // extension then continues tab_overhang_p further, widened to the
        // full insert wall thickness (see cap_side_tabs). Both are
        // deliberately outside the plain cylindrical cavity envelope.
    }

    $fn = nn;
    difference() {
        union() {
            difference() {
                cap_plug_outer(disk_od, roof_t, insert_len, insert_od,
                               chamfer_h, chamfer_delta,
                               band_enable, bc, band_z1, band_z2, band_w, band_depth);
                cap_cavity_cut(roof_t, insert_len, insert_od, insert_wall_t,
                               chamfer_h, chamfer_delta);
            }
            // boss, overlapped into the roof so it is one solid body
            translate([0, 0, roof_t - 2 * p_eps()])
                cylinder(d = boss_d, h = boss_depth + 2 * p_eps());
            // NEW: internal cavity side tabs, rooted at the cavity floor,
            // widening into a full-thickness lip extension past the top lip
            if (side_tabs)
                cap_side_tabs(inner_top_od, insert_od, roof_t, insert_len,
                              tab_width_p, tab_depth_p, tab_overhang_p, button_axis,
                              tab_fillet_p);
        }
        // central bore through roof + boss
        translate([0, 0, -p_eps()])
            cylinder(h = roof_t + boss_depth + 2 * p_eps(), d = axle_bore_d);
        // O-ring gland: an annular groove in the bore wall, centred oring_gland_z
        // below the cap outer face, that seats the axle rotary-seal O-ring.
        if (oring_gland)
            translate([0, 0, oring_gland_z - oring_gland_w / 2])
                rotate_extrude($fn = nn)
                    translate([axle_bore_d / 2 - p_eps(), 0])
                        square([oring_gland_od / 2 - axle_bore_d / 2 + p_eps(),
                                oring_gland_w]);
        cap_button_holes_cut(roof_t, button_d, button_axis, button_radius);
    }

    echo("CAP: disk / insert dia / total height = ",
         disk_od, insert_od, roof_t + insert_len);
    echo("CAP: roof / boss depth / axle bearing length = ",
         roof_t, boss_depth, roof_t + boss_depth);
    if (oring_gland)
        echo("CAP: axle O-ring gland -- bore ", axle_bore_d, " -> groove OD ",
             oring_gland_od, " x ", oring_gland_w, " wide, centred ", oring_gland_z,
             " mm below the outer face. Seals a ", p_axle_oring_cs(),
             " mm-CS O-ring (ID ", p_axle_oring_id(), ") on the axle round section.");
    if (side_tabs)
        echo("CAP: side tabs -- width ", tab_width_p, " x rib depth ", tab_depth_p,
             ", rib height ", insert_len, " (floor to lip) + ", tab_overhang_p,
             " mm full-thickness lip extension, ", tab_fillet_p,
             " mm bottom-edge fillet, on the ", button_axis, " axis.");
}
// [bundle] end   <../../lib/control_cap.scad>

color([0.74, 0.77, 0.79])
control_cap(roof_t        = top_disk_thickness,
            boss_d        = centre_boss_diameter,
            boss_depth    = centre_boss_depth,
            insert_len    = insert_total_h,
            insert_od     = insert_shaft_d,
            insert_wall_t = cup_wall_thickness,
            chamfer_h     = entry_chamfer_h,
            chamfer_delta = entry_chamfer_delta,
            axle_bore_d   = shaft_hole_d,
            button_d      = button_upper_d,
            button_axis   = button_axis,
            button_radius = hole_spacing_cc,
            band_enable   = band_channels_enable,
            band_count    = band_count,
            band_z1       = band1_center_z_local,
            band_z2       = band2_center_z_local,
            band_w        = band_channel_w,
            band_depth    = band_channel_depth,
            oring_gland    = oring_gland_enable,
            oring_gland_od = oring_gland_od,
            oring_gland_w  = oring_gland_width,
            oring_gland_z  = oring_gland_from_face,
            side_tabs      = side_tabs_enable,
            tab_width_p    = tab_width,
            tab_depth_p    = tab_depth,
            tab_overhang_p = tab_top_overhang,
            tab_fillet_p   = tab_corner_fillet,
            fn            = fn);
