// ==========================================================================
//  TEST VARIANT — hand-built, NOT produced by build/build.py.
//  Forked from v1.0 SCADs/Bottle_Hex_Shaft_v1.scad (Turtle Body v1.10.0).
//  Do not treat this as a source-of-truth bundle: it is a one-off experiment
//  and is not wired into lib/, src/, build/build.py, build/lint.py,
//  build/test.py or VERSION.json. If this redesign is adopted for real, port
//  it into lib/params.scad + lib/hex_shaft.scad through the normal workflow
//  (CLAUDE.md section 15) instead of hand-editing this file further.
//
//  DELIBERATE REDESIGN, latest cut: the hex-top piece is dropped entirely --
//  this file now emits ONLY the round shaft, a single straight Ø8 mm
//  cylinder (no 7 mm neck, no taper). Overall length is 20 mm longer than
//  the previous 48 mm two-part shaft length, i.e. 68 mm. The magnet recess
//  opens at one end, deepened to 3.5 mm (was 3) with a wider +0.3 mm
//  diametral fit margin (was +0.1) for easier insertion.
//
//  Units: mm. License: CERN-OHL-S-2.0 (same as the rest of this repository).
// ==========================================================================

/* [Round shaft -- straight, constant diameter, no taper] */
shaft_d   = 8;    // full diameter, constant along the whole length
shaft_len = 68;   // previous two-part length (48) + 20 mm

/* [Magnet recess -- blind hole at one end] */
magnet_recess_enabled = true;
magnet_diameter    = 4;    // nominal magnet size
magnet_fit_margin  = 0.3;  // diametral allowance added on top, for insertion (was 0.1)
magnet_depth       = 3.5;  // was 3

/* [Render] */
fn = 120; // [48:8:240]

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
// A port must swallow the bottle's tapered top (the top dome) plus a seating
// allowance, so its axial length is DERIVED from the bottle, not fixed. This
// is the same rule the HopeTurtles.org generators use
// (port_length = taper_height + port_allowance); until 2026-09-08 lib carried
// the evaluated constant 82 instead, which silently broke the rule for any
// bottle other than the reference one. Ballast and Ecojoiner both read it.
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
//  Derived to the 5/2 cap datum (TB-03/TB-04). round_inside_cap is measured
//  from the roof underside and INCLUDES the boss -- do not add the boss again.
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
//  A round-section O-ring seated in a gland in the control-cap bore, sealing
//  against the spinning round section of the axle. ID is tied to the shaft.
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
// 45-deg outward chamfer on the roof-top outer edge (0 = sharp). The cage
// prints roof-face-down, so this bevel flares OUT from the bed and stays
// printable; it runs the full perimeter, batten grooves included. See
// lib/control_cage.scad.
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
// TB-07: the green-slat mounting hole follows the mating Ecojoiner John, not a
// fixed 50 mm. Derived from the install transform; the john_length/2 terms
// cancel, leaving a pure function of the shared contract (= 103 at defaults).
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
// With the full colour code off, every wooden subsystem still renders in its
// OWN shade of brown so the parts stay visually separable. All are warm browns
// (R > G > B) spaced by lightness. The two large fins share one darker shade so
// they read as a matched pair, distinct from the rest of their own assembly.
function p_wood_shade_sail()     = [0.85, 0.66, 0.47]; // sail frame  (lightest)
function p_wood_shade_rear_fin() = [0.72, 0.50, 0.33]; // rear-fin shafts + solar holder
function p_wood_shade_eco()      = [0.62, 0.44, 0.28]; // Ecojoiner core
function p_wood_shade_ballast()  = [0.52, 0.34, 0.22]; // ballast slats / board / locks
function p_wood_shade_fin()      = [0.40, 0.26, 0.17]; // rear fin + ballast fin, shared (darkest)
// [bundle] end   <params.scad>

// Round shaft -- a single straight Ø8 mm cylinder, no neck, no taper, no
// separate hex-top piece. The magnet recess (a blind hole, not through)
// opens at one end for the sensing magnet.
module shaft_round_part(d            = 8,
                        len          = 68,
                        magnet       = true,
                        magnet_d     = 4,
                        magnet_fit_margin = 0.3,
                        magnet_depth = 3.5,
                        fn           = undef) {
    nn = fn == undef ? p_fn_plastic() : fn;
    magnet_hole_d = magnet_d + magnet_fit_margin;

    assert(d > 0 && len > 0, "shaft_round_part: diameter and length must be positive.");
    assert(!magnet || (magnet_fit_margin >= 0 && magnet_hole_d > 0 && magnet_hole_d < d
           && magnet_depth > 0 && magnet_depth < len),
           "shaft_round_part: magnet recess (incl. fit margin) must fit inside the shaft.");

    $fn = nn;
    difference() {
        cylinder(d = d, h = len);
        if (magnet)
            translate([0, 0, len - magnet_depth])
                cylinder(d = magnet_hole_d, h = magnet_depth + p_eps());
    }

    echo("SHAFT: diameter / length = ", d, len);
    if (magnet)
        echo("SHAFT: magnet nominal / fit margin / hole dia / depth = ",
             magnet_d, magnet_fit_margin, magnet_hole_d, magnet_depth);
}

color([0.74, 0.77, 0.79])
    shaft_round_part(d            = shaft_d,
                     len          = shaft_len,
                     magnet       = magnet_recess_enabled,
                     magnet_d     = magnet_diameter,
                     magnet_fit_margin = magnet_fit_margin,
                     magnet_depth = magnet_depth,
                     fn           = fn);
