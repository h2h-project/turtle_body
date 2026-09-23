// ==========================================================================
//  GENERATED FILE -- DO NOT EDIT.
//  Produced by build/build.py from src/Full_Turtle.scad
//  Turtle Body version 4.0.0
//  Edit lib/ and src/ instead, then run: python3 build/build.py
// ==========================================================================
/*
  Hope Turtle — Comprehensive Parametric Assembly, revision 11 (self-contained)
  Ecojoiner body, shared bottles, ballast, rear fin, and sail apparatus
  Rear-fin update: complementary half-laps and centered 0.2 mm fit clearance.
  Sine cage: four continuous peaks, two M3 mounts per peak, 6 mm roof.
  License: CERN-OHL-S-2.0

  The bottle specification and wood thickness below are the single source
  of truth for every integrated subsystem.

  Open THIS file directly. No companion SCAD files are required.
  The working standalone control-cap file is not loaded or changed.
*/

$fn = 96;

// Use top_sail to inspect the installed bottle and sail apparatus by itself.
// Use core to inspect the remaining turtle without the top apparatus.
assembly_view = "full_turtle"; // [full_turtle,top_sail,core]
echo("FULL_TURTLE_V11_SELF_CONTAINED", assembly_view);

// Wooden parts only; bottles, hardware, sails and printed parts keep their colors.
enable_color_coding = true;

// Water is a visual F5 preview layer, excluded from F6 and mesh exports.
// Units are mm: 2000 x 2000 x 2000 = 8 cubic metres.
show_water = true;
water_cube_size = 2000;
water_transparency = 0.63; // 63% transparent = alpha 0.37; increase for a clearer view.

// Top apparatus controls. Full turtle is self-contained; no companion required.
// Rotates only the cage, axle and connected sail frame. Bottle/cap stay fixed.
// 0 preserves the installed pose; positive = counterclockwise viewed from above.
// This is the input for future animation or control code (for example 360*$t).
cage_rotation_angle = 0; // [0:1:360]
side_batten_height = 205;
cage_vertical_position = 0;
sail_frame_rotation_angle = 90;
cage_exploded_view = 0;
sail_curve_segments = 180;

// Continuous sine cage: shared controls passed to the sail apparatus.
cage_wave_segments = 240;
cage_valley_wall_height = 10;
cage_peak_extension = 20;
cage_lower_hole_from_tip = 10;
cage_mount_hole_diameter = 3.2;
cage_button_angle = 0; // Local angle; installation adds 90 degrees


// ============================================================================
// CANONICAL HOPE TURTLE BOTTLE
// ============================================================================
// Embedded from hope_turtle_bottle.scad.
// The bottle geometry remains the canonical lightweight transparent model.

/*
    Hope Turtle — Lightweight Parametric Bottle Model v6
    Units: millimetres

    Design goal:
      Efficient visual bottle geometry for scenes containing several bottles.

    bottle_height is TOTAL height including cap.

    Colors:
      Bottle body : cyan, 60% transparent
      Collar      : cyan, 90% opaque
      Cap         : blue

    Shape:
      - Top and bottom transitions use mirrored superellipse dome profiles.
      - dome_power controls how much the shoulders "puff out".
      - Bottle body and cap remain simple solid shapes for fast rendering.
*/

// $fn supplied by Ecojoiner assembly
// ============================================================================
// SHARED USER / FORM VARIABLES — SINGLE SOURCE OF TRUTH
// ============================================================================
//
// These values drive every bottle, the Ecojoiner, ballast, rear fin and sails.
// Do not redefine them elsewhere in this file.

bottle_diameter      = p_bottle_d();  // was a hardcoded 82 literal, disconnected from
                                       // lib/params.scad -- drift surfaced when p_bottle_d()
                                       // moved to 86 (rear-fin/John Y-axis assert failed
                                       // because this file's own Ecojoiner-rectangle copy
                                       // stayed on the old literal while lib-derived values
                                       // picked up 86). Now genuinely single-sourced.
bottle_height        = 305;

cap_diameter         = 31;
cap_height           = 17;

// User-set collar diameter.
// This is intentionally independent of cap diameter.
collar_diameter      = 34;

top_dome_height      = 62;
bottom_dome_height   = 25;


// Shared stock / fin-system variables. Solar-panel W/H/T come from the
// shared contract (lib/params.scad) so the rear fin and the visible panel
// agree; the values are 148 / 223 / 2.5 mm.
fin_board_width       = 93;
solar_panel_width     = p_solar_panel_w(); // across the red crossbar (local Y)
solar_panel_height    = p_solar_panel_h(); // forward length (local X)
solar_panel_thickness = p_solar_panel_t(); // panel only; wooden stock uses slat_thickness

// TOTAL extra slot width, centered on the mating wooden piece (mm).
rear_half_lap_clearance   = 0.2;
rear_solar_slot_clearance = 0.2;


// ============================================================================
// STANDARD / HARD-CODED BOTTLE VALUES
// ============================================================================

// Dome fullness.
// p = 2 gives a quarter ellipse.
// p > 2 stays broad longer before turning inward.
dome_power = 2.5;

// Bottle neck is always 3 mm smaller than the cap and 5 mm high.
bottle_neck_diameter =
    cap_diameter - 3;

bottle_neck_height =
    5;

// Collar remains visible and 1 mm high.
// Diameter is a USER-SET value from the shared bottle specification above.
collar_height =
    1;

// Slightly narrower footprint at the bottle base.
bottom_base_ratio =
    0.88;

bottom_base_diameter =
    bottle_diameter * bottom_base_ratio;


// ============================================================================
// RENDER QUALITY
// ============================================================================

profile_steps = 16;


// ============================================================================
// DERIVED HEIGHTS
// ============================================================================

straight_body_height =
    bottle_height
    - bottom_dome_height
    - top_dome_height
    - bottle_neck_height
    - collar_height
    - cap_height;

body_z0 =
    bottom_dome_height;

top_dome_z0 =
    body_z0 + straight_body_height;

neck_z0 =
    top_dome_z0 + top_dome_height;

collar_z0 =
    neck_z0 + bottle_neck_height;

cap_z0 =
    collar_z0 + collar_height;


// ============================================================================
// SANITY CHECKS
// ============================================================================

assert(bottle_diameter > 0,
       "Bottle diameter must be positive.");

assert(cap_diameter > 3,
       "Cap diameter must be greater than 3 mm.");

assert(bottle_neck_diameter > 0,
       "Derived bottle-neck diameter must be positive.");

assert(collar_diameter > 0,
       "Derived collar diameter must be positive.");

assert(straight_body_height > 0,
       "Bottle height is too short for the selected dimensions.");

assert(abs((cap_z0 + cap_height) - bottle_height) < 0.001,
       "Bottle component heights do not sum to bottle_height.");


// ============================================================================
// BOTTLE MOCK-UP  (visual reference only; from lib/)
// ============================================================================
// parametric_bottle() and its superellipse domes now come from
// lib/bottle_mockup.scad. Its module args default to lib/params.scad, whose
// values equal the SINGLE SOURCE OF TRUTH block above, so bottle_at_port()
// keeps calling parametric_bottle() with no change.
// [bundle] begin use <../lib/params.scad>
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
function p_bottle_d()        = 84;    // outside diameter (was 86, and 82 before that; other bottle dims held)
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
function p_cap_boss_depth()  = 1.5;   // extra projection of the centre boss into the hollow cap
                                       // (was 2; lowered 0.5 mm -> 6.5 mm axle bearing length)
function p_cap_boss_d()      = 18;
function p_cap_insert_len()  = 35;    // straight insert shaft length
function p_cap_insert_wall_t() = 4;
function p_cap_entry_chamfer_h()     = 1;
function p_cap_entry_chamfer_delta() = 1;
function p_cap_axle_bore_d() = 8.7;   // 0.35 mm radial clearance to the Ø8 shaft (was 8.6 / 0.3 mm)
function p_cap_cage_radial_clearance() = 1;   // cap disk -> cage inner wall (radial)
function p_cap_total_h()     = p_cap_roof_t() + p_cap_insert_len();           // 40
function p_cap_bearing_len() = p_cap_roof_t() + p_cap_boss_depth();           // 6.5 (was 7)

// buttons (through both cap and cage)
function p_button_upper_d()  = 17;    // clearance hole in the cap
function p_button_axis()     = "y";   // "x" or "y"
function p_button_radius()   = 25;    // radial position of the two button centres (50 mm apart;
                                       // was 24 / 48 mm -- shared with the cage's matching bore)

// ---- silicone seal grooves + rings (CLAUDE.md s8) ------------------
function p_seal_groove_count()      = 2;
function p_seal_groove_axial_h()    = 2.7; // groove height (was 3.5; retuned to just clear
                                            // the 2.6 mm ring axial thickness below, 0.1 mm margin)
function p_seal_groove_radial_depth() = 2; // groove depth
function p_seal_groove1_from_shoulder() = 12;  // groove centre, measured from the insert SHOULDER
function p_seal_groove2_from_shoulder() = 25;
function p_seal_ring_axial_t()      = 2.6;  // cast ring thickness (was 3)
function p_seal_ring_radial_w()     = 10;   // cast ring radial width (was 5; doubled). NOT validated.
function p_seal_ring_elasticity_reduction() = 0.25;
    // Cast the ring's inner diameter this fraction SMALLER than the groove
    // root it mates to, so real (stretchy) silicone is under tension --
    // and therefore actually grips -- once stretched onto the cap, instead
    // of sitting at a 1:1 as-cast fit. Tweak this here as real silicone
    // behaviour is characterized; NOT validated (see lib/silicone_ring_mold.scad).
function p_seal_groove_root_d() = p_insert_shaft_d()
                                - 2 * p_seal_groove_radial_depth();            // 79 at the 86 mm bottle

// ---- sail shaft: uniform round centre axle (CLAUDE.md s9) ----------
//  Derived to the 5/2 cap datum (TB-03/TB-04). round_inside_cap is measured
//  from the roof underside and INCLUDES the boss -- do not add the boss again.
//  TB-08: the shaft is now one uniform round bar top to bottom -- no hex
//  section. It free-spins in the cap bore (p_cap_axle_bore_d) and passes
//  with a light running clearance through the cage hub bore and the top
//  sail bar's own hole (both p_axle_shaft_hole_d()); it locks to the
//  ROTATING cage with a single M3 set screw through the cage hub
//  (p_cage_setscrew_pilot_d()) rather than a shaped (hex) interference fit.
function p_axle_round_d()        = 8;
function p_axle_round_ext()      = 1;    // projection above the cap's outer face
function p_axle_round_inside_cap() = p_cap_insert_len() - 5;  // 30: roof underside to round end (incl. boss)
function p_axle_round_len()      = p_axle_round_inside_cap() + p_cap_roof_t() + p_axle_round_ext();  // 36
function p_axle_upper_len()      = 23;   // continues up through the cage hub + sail bar (was the hex length)
function p_axle_total_len()      = p_axle_upper_len() + p_axle_round_len();
function p_axle_shaft_clearance() = 0.2; // light running clearance, diametral: any hole the shaft passes
                                          // (but does not bear in) is p_axle_round_d() + this
function p_axle_shaft_hole_d()   = p_axle_round_d() + p_axle_shaft_clearance();  // 8.2
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
// TB-08: hex bore replaced by a plain round bore (p_axle_shaft_hole_d(),
// shared with the sail bar) + a radial M3 set screw that locks the cage to
// the shaft -- see p_cage_setscrew_*() below.
function p_cage_bearing_d()  = 9;     // hemispherical bearing bump
function p_cage_bearing_count() = 8;
function p_cage_bearing_pcd() = p_cap_disk_d() - p_cage_bearing_d() + 0.5;          // 91.5
function p_cage_top_hole_d() = 18;    // central button / access hole through the roof
function p_cage_mount_hole_d() = 3.2; // two M3 clearance holes per batten / groove
function p_cage_mount_pitch()  = 32;  // vertical pitch of the pair
function p_cage_lower_hole_from_tip() = 10;
// Single radial M3 set (grub) screw through the hub wall, pressing on the
// shaft to lock cage <-> shaft rotation (TB-08). Self-tapping into the
// printed PLA hub -- not a clearance hole for a separate nut, unlike the
// batten/mount M3 holes above. Pilot diameter is an untested starting
// point (typical M3-into-rigid-plastic self-tap pilots run 2.5-2.8 mm) --
// verify real thread engagement and tapping torque before relying on it.
function p_cage_setscrew_pilot_d() = 2.5;
function p_cage_setscrew_angle()   = 0;    // radial angle of the lock screw around the hub
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
function p_sail_bar_axle_hole_d() = p_axle_shaft_hole_d();  // TB-08: Ø8.2, same running
                                                              // clearance as the cage hub bore (was Ø12 for the hex corners)
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
// [bundle] end   <../lib/params.scad>
// [bundle] begin use <../lib/bottle_mockup.scad>
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

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
// [bundle] end   <params.scad>

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
// [bundle] end   <../lib/bottle_mockup.scad>
// [bundle] begin use <../lib/ecojoiner.scad>
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

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
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
// [bundle] end   <util.scad>

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
// [bundle] end   <../lib/ecojoiner.scad>
// [bundle] begin use <../lib/ballast_fin.scad>
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

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
// [bundle] end   <params.scad>
// [bundle] begin use <util.scad>
// [bundle] already inlined: util.scad
// [bundle] end   <util.scad>

function bl_t()            = p_wood_t();
function bl_core_w()       = p_bottle_d() - 2 * bl_t();                          // 58
function bl_core_h()       = p_bottle_h() - p_bottle_cap_h() + 6.0 * bl_t();     // 360
function bl_lower_lobe()   = 2 * bl_t();
function bl_upper_lobe()   = 2 * bl_t();
function bl_core_slot_h()  = bl_t();
function bl_core_slot_depth() = bl_core_w() / 2;
function bl_neck_w()       = p_bottle_d() - 3 * bl_t();                          // 46
function bl_shoulder_step()   = bl_core_w() - bl_neck_w();                       // 12
function bl_upper_diag_start() = bl_core_h() - p_port_height();
function bl_upper_neck_start() = bl_upper_diag_start() - bl_shoulder_step();
function bl_core_slot_z0() = bl_lower_lobe();
function bl_core_slot_z1() = bl_core_slot_z0() + bl_core_slot_h();
function bl_lower_full_return() = bl_core_slot_z1() + bl_upper_lobe();
function bl_lower_neck_start()  = bl_lower_full_return() + bl_shoulder_step();
function bl_mount_hole_from_top() = p_port_length() + bl_t() - p_screw_side_offset();  // 69
function bl_mount_hole_x()  = bl_core_w() / 2;
function bl_mount_hole_y()  = bl_core_h() - bl_mount_hole_from_top();

function bl_board_len()    = 3.5 * p_bottle_d();                                 // 287
function bl_board_w()      = p_fin_board_w();                                    // 93
function bl_board_slot_w() = bl_t();
function bl_board_slot_depth()  = p_fin_board_w() / 3;
function bl_center_slot_depth() = p_bottle_d() / 2;
function bl_center_slot()  = bl_board_len() / 2;
function bl_slat_spacing() = p_bottle_d() + bl_t();                             // 94
function bl_left_slot()    = bl_center_slot() - bl_slat_spacing() / 2;
function bl_right_slot()   = bl_center_slot() + bl_slat_spacing() / 2;
function bl_end_slot_offset() = 2 * bl_t();
function bl_left_end_slot_x0()  = bl_end_slot_offset();
function bl_right_end_slot_x0() = bl_board_len() - bl_end_slot_offset() - bl_board_slot_w();

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
    assert(p_m6_clearance_d() > 0 && p_m6_clearance_d() < p_bottle_d() - 2 * t);
    assert(bl_mount_hole_from_top() > p_m6_clearance_d() / 2
           && bl_mount_hole_from_top() < p_bottle_d() - p_m6_clearance_d() / 2,
           "ballast: mount hole misses the upper slat end.");
    assert(p_fin_board_w() > max(4.5 * t, p_bottle_d() / 2), "ballast: fin board too narrow.");
    assert(bl_core_w() == p_port_height() - 2 * t,
           "ballast: slat width must use the shared bottle diameter.");
    assert(abs((bl_core_h() - bl_upper_diag_start()) - p_port_height()) < 0.001,
           "ballast: top shoulder cut must begin one port_height below the slat top.");
    assert(abs((bl_slat_spacing() - bl_t()) - p_bottle_d()) < 0.001,
           "ballast: slat inner-face gap must equal the shared bottle diameter.");
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
            translate([bl_mount_hole_x(), bl_mount_hole_y()])
                circle(d = p_m6_clearance_d(), $fn = 48);
        }

module ballast_bottom_board_part(colored = true) {
    e = 0.01;
    wood_color([0.90, 0.38, 0.06], colored, p_wood_shade_ballast())
    linear_extrude(height = bl_t()) difference() {
        square([bl_board_len(), bl_board_w()]);
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
         " | M6 from slat top = ", bl_mount_hole_from_top());
}
// [bundle] end   <../lib/ballast_fin.scad>
// [bundle] begin use <../lib/rear_fin.scad>
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

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
// [bundle] end   <params.scad>
// [bundle] begin use <util.scad>
// [bundle] already inlined: util.scad
// [bundle] end   <util.scad>

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
                fn = undef, colored = true) {
    t = rf_t(); eps = p_eps();
    nn = fn == undef ? p_fn_wood() : fn;
    // colour code: yellow fin. Neutral: p_wood_shade_fin(), shared with the
    // ballast fin so the two large fins read as a pair.
    wood_color([1, 0.72, 0.05], colored, p_wood_shade_fin()) rotate([90, 0, 0])
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
                           hole_from_front = undef, hole_d = undef, fn = undef,
                           colored = true) {
    t = rf_t(); eps = p_eps();
    nn  = fn == undef ? p_fn_wood() : fn;
    hff = hole_from_front == undef ? p_rear_shaft_hole_from_front() : hole_from_front;
    hd  = hole_d == undef ? p_m6_clearance_d() : hole_d;
    wood_color([0.2, 0.38, 0.05], colored, p_wood_shade_rear_fin()) difference() {
        translate([rf_shaft_front_x(), -rf_shaft_width() / 2, z0])
            cube([rf_shaft_length(), rf_shaft_width(), t]);
        translate([rf_shaft_front_x() + hff, 0, z0 - eps])
            cylinder(d = hd, h = t + 2 * eps, $fn = nn);
        translate([rf_joint_meet_x() - half_lap / 2, -(t + half_lap) / 2, z0 - eps])
            cube([rf_shaft_rear_x() - rf_joint_meet_x() + half_lap / 2 + eps,
                  t + half_lap, t + 2 * eps]);
    }
}

module solar_panel_holder(solar_clear = p_fit_clearance(), fn = undef,
                          colored = true) {
    t = rf_t(); eps = p_eps();
    nn = fn == undef ? p_fn_wood() : fn;
    L = rf_solar_holder_len(); H = rf_solar_holder_h(); ch = rf_solar_chamfer();
    wood_color("red", colored, p_wood_shade_rear_fin())
        translate([rf_solar_notch_x0(), 0, rf_upper_shaft_z0()])
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
                         exploded = 0, fn = undef, colored = true) {
    rf_assert_valid(half_lap, solar_clear,
                    p_rear_shaft_hole_from_front(), p_m6_clearance_d());
    rear_fin(half_lap, solar_clear, fn, colored);
    translate([-exploded, 0,  exploded]) bottle_holder_shaft(rf_upper_shaft_z0(), half_lap, fn = fn, colored = colored);
    translate([-exploded, 0, -exploded]) bottle_holder_shaft(rf_lower_shaft_z0(), half_lap, fn = fn, colored = colored);
    translate([ exploded, 0,  exploded]) solar_panel_holder(solar_clear, fn, colored);

    echo("REAR FIN: shaft length = ", rf_shaft_length(),
         " | hole from front (TB-07) = ", p_rear_shaft_hole_from_front(),
         " | slot opening = ", rf_t() + half_lap);
}
// [bundle] end   <../lib/rear_fin.scad>
// [bundle] begin use <../lib/control_cap.scad>
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
//  Optional SIDE TABS (`side_tabs`, off by default in this module but ON in
//  the wrapper): two internal ribs on the hollow insert cavity's inner wall,
//  rooted at the cavity floor, that continue past the top lip as a free
//  full-wall-thickness post with a gradual inward taper. See cap_side_tabs()
//  below. Not validated -- a fit/registration experiment.
//
//  Optional TAB WIRE HOLE (`tab_wire_hole`, off by default, ON in the
//  wrapper alongside side_tabs): a round channel drilled down each side
//  tab from its exposed free tip to a point inside the cap body, breaking
//  through the tab's inner face into the hollow cavity -- for routing
//  button wires from outside, down through the tab, into the cap interior.
//
//  Definitions only. Geometry is emitted by control_cap().
// ==========================================================================

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
// [bundle] end   <params.scad>
// [bundle] begin use <util.scad>
// [bundle] already inlined: util.scad
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

// Two internal ribs ("side tabs") on the hollow insert cavity's inner
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
//     is widened to run the FULL insert wall thickness -- same flat
//     parallel sides as the rib -- then intersected with a cylinder at the
//     insert's own outer wall radius, so only ITS outer corners get clipped
//     onto that (larger) arc.
// Above tab_taper_start_offset mm BELOW the lip, the INNER face stops being
// flat: from that Z up to the free tip it leans inward (radially), gaining
// tab_taper_gain (total, radially) by the tip, as ONE continuous linear
// slope -- the widening step at the lip only changes which cylinder the
// OUTER face is clipped to (r_outer inside the cavity, r_wall above it), it
// does not break the taper. Below the taper-start Z the inner face is still
// the plain flat rib. Each tapered stretch is a hull() of two thin end
// slices, so it stays a single flat sloped face -- a shallow, gradual,
// self-supporting overhang, not a step -- while the outer face and the two
// tangential side faces stay flat/vertical exactly as before.
// The two bottom edges of the rib (where its flat SIDE faces meet the
// cavity floor) are rounded with a tab_fillet_r quarter-round, cut with a
// corner-sliver subtraction (only the floor-facing edges; the lip
// extension doesn't touch the floor, so it stays unrounded).
// The finished pair is placed along the button axis (axis "x"/"y") and then
// rotated an extra tab_rotate_deg about Z -- positive = counter-clockwise,
// negative = clockwise, viewed from above (+Z looking down at the boss/
// insert side) -- to swing both tabs off that axis together.
// Not a cut: this ADDS material into the cavity (and, above the lip, past
// the cap's normal outer profile).
//
// WIRE HOLE (`wire_hole`, off by default here): a round channel drilled
// down each tab for routing button wires. It runs from the exposed free
// tip (open air above the cap, where a wire is fed in) down to a point
// `wire_hole_exit_from_lip` mm below the lip, comfortably inside the cap
// body -- not straight, but angled so its lower end sits at least one hole
// diameter inboard of the tab's own inner face at that height, breaking
// through into the real hollow cavity rather than dead-ending in solid
// rib/lip material. Modelled as a hull of two spheres (a capsule) between
// the entry and exit points -- simplest way to get a smooth round tunnel
// between two off-axis points. Only ever removes tab material (the
// breakout point is already inside the cavity's own empty radius, so nothing
// else needs cutting).
module cap_side_tabs(wall_d, outer_wall_d, roof_t, lip_h, tab_width, tab_depth, tab_overhang, axis, tab_fillet_r = 0, tab_taper_gain = 0, tab_taper_start_offset = 0, tab_rotate_deg = 0, wire_hole = false, wire_hole_d = 5, wire_hole_exit_from_lip = 15, fn = 48) {
    r_outer = wall_d / 2;        // cavity wall radius -- rib's outer clip radius
    r_wall  = outer_wall_d / 2;  // insert's outer wall radius -- lip-extension's outer clip radius
    r_inner = r_outer - tab_depth; // rib's flat inner face at/below the taper start

    lip_z    = roof_t + lip_h;                                   // top of the rooted rib
    tip_z    = lip_z + tab_overhang;                              // free tip
    taper0_z = max(roof_t, lip_z - tab_taper_start_offset);       // where the inward lean begins
    taper_span = tip_z - taper0_z;                                // > 0 whenever tab_overhang > 0

    // linear inner-face radius at height z, valid for z in [taper0_z, tip_z]
    function r_at(z) = r_inner - tab_taper_gain * (z - taper0_z) / taper_span;
    r_lip = r_at(lip_z);          // inner-face radius exactly at the lip (the r1 hand-off point)
    r_tip = r_inner - tab_taper_gain;

    // wire-hole entry (top, at the tip) / exit (breaking into the cavity)
    wire_exit_z    = lip_z - wire_hole_exit_from_lip;
    wire_entry_r   = (r_tip + r_wall) / 2;                  // centred in the tip's radial thickness
    wire_inner_r_at_exit = (wire_exit_z >= taper0_z) ? r_at(wire_exit_z) : r_inner;
    wire_exit_r    = max(0, wire_inner_r_at_exit - wire_hole_d);  // a full diameter past the inner face

    // flat, parallel-sided block: X in [-tab_width/2, tab_width/2],
    // radial coordinate (named Y here) in [r0,r1], axial in [z0,z1].
    // Built along the local +Y axis; one_tab() places it at +/-Y (or, for
    // axis="x", the whole pair is rotated 90 deg afterwards).
    module raw_block(sign, r0, r1, z0, z1) {
        translate([-tab_width / 2, sign > 0 ? r0 : -r1, z0])
            cube([tab_width, r1 - r0, z1 - z0]);
    }

    // Same footprint as raw_block, but the inner face (r0) moves linearly
    // from r0_bot at z0 to r0_top at z1 while the outer face (r1) stays
    // put -- a single flat sloped inner face, built as a hull of two thin
    // end slices so it stays a plain linear taper (no bulge).
    module raw_block_tapered(sign, r0_bot, r0_top, r1, z0, z1) {
        hull() {
            translate([-tab_width / 2, sign > 0 ? r0_bot : -r1, z0])
                cube([tab_width, max(p_eps(), r1 - r0_bot), p_eps()]);
            translate([-tab_width / 2, sign > 0 ? r0_top : -r1, z1 - p_eps()])
                cube([tab_width, max(p_eps(), r1 - r0_top), p_eps()]);
        }
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

    // capsule-shaped wire channel: a hull of two spheres between the tip
    // entry point and the cavity-breakout exit point, both at local X=0,
    // Y = sign * radius (matching the raw_block sign convention above).
    module wire_channel(sign) {
        hull() {
            translate([0, sign * wire_entry_r, tip_z])
                sphere(d = wire_hole_d, $fn = fn);
            translate([0, sign * wire_exit_r, wire_exit_z])
                sphere(d = wire_hole_d, $fn = fn);
        }
    }

    module one_tab(sign) {
        rib_y0 = sign > 0 ? r_inner : -r_outer; // start of the rib's radial span
        difference() {
            union() {
                // A: plain flat rib, floor up to the taper start (skipped
                // when the taper starts at/below the floor).
                if (taper0_z - roof_t > p_eps())
                    intersection() {
                        raw_block(sign, r_inner, r_outer, roof_t, taper0_z + p_eps());
                        curved_clip(r_outer, roof_t - p_eps(), taper0_z + 2 * p_eps());
                    }
                // B: taper begins, still inside the cavity (outer face still
                // clipped to the cavity wall, r_outer) -- skipped when the
                // taper starts exactly at the lip (tab_taper_start_offset = 0).
                if (lip_z - taper0_z > p_eps())
                    intersection() {
                        raw_block_tapered(sign, r_inner, r_lip, r_outer, taper0_z, lip_z + p_eps());
                        curved_clip(r_outer, taper0_z - p_eps(), lip_z + 2 * p_eps());
                    }
                // C: lip extension proper -- outer face widens to the
                // insert's own outer wall (r_wall); taper continues from
                // r_lip (whatever it reached at the lip) to r_tip.
                intersection() {
                    raw_block_tapered(sign, r_lip, r_tip, r_wall, lip_z, tip_z);
                    curved_clip(r_wall, lip_z - p_eps(), tip_z + p_eps());
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
            if (wire_hole)
                wire_channel(sign);
        }
    }

    base_rot = (axis == "x") ? 90 : 0;
    rotate([0, 0, base_rot + tab_rotate_deg]) { one_tab(1); one_tab(-1); }
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
                   side_tabs      = false,  // two internal cavity ribs + lip extension
                   tab_width_p    = 22,
                   tab_depth_p    = 2,
                   tab_overhang_p = 14,    // how far the lip extension runs past the top lip
                   tab_fillet_p   = 0,     // rounds the rib's two bottom (floor) edges
                   tab_taper_gain_p = 0,   // total inward (radial) lean of the inner face by
                                           // the free tip, vs. the plain rib thickness
                   tab_taper_start_p = 0,  // taper begins this far BELOW the lip (0 = at the lip)
                   tab_rotate_p     = 0,   // extra rotation of the tab pair about Z, off the
                                           // button axis (+ = CCW, - = CW, viewed from above)
                   tab_wire_hole    = false, // drill a wire-routing channel down each tab
                   tab_wire_hole_d  = 5,
                   tab_wire_hole_exit_from_lip = 15, // how far below the lip the channel breaks
                                                      // through into the hollow cavity
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
        assert(tab_taper_gain_p >= 0
               && tab_taper_gain_p < inner_top_od / 2 - tab_depth_p - boss_d / 2,
               "control_cap: side tab taper gain must stay clear of the centre boss.");
        assert(tab_taper_start_p >= 0,
               "control_cap: side tab taper start offset cannot be negative.");
        // The rib runs the full insert_len (floor to top lip); the lip
        // extension then continues tab_overhang_p further, widened to the
        // full insert wall thickness (see cap_side_tabs). Both are
        // deliberately outside the plain cylindrical cavity envelope. The
        // inner face tapers inward by tab_taper_gain_p (total, by the free
        // tip) starting tab_taper_start_p mm below the lip (0 = at the lip).
        if (tab_wire_hole) {
            assert(tab_wire_hole_d > 0, "control_cap: wire hole diameter must be positive.");
            assert(tab_wire_hole_exit_from_lip > 0
                   && roof_t + insert_len - tab_wire_hole_exit_from_lip > roof_t,
                   "control_cap: wire hole exit point must land inside the cap body, above the floor.");
        }
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
            // internal cavity side tabs, rooted at the cavity floor,
            // widening into a full-thickness lip extension past the top lip
            if (side_tabs)
                cap_side_tabs(inner_top_od, insert_od, roof_t, insert_len,
                              tab_width_p, tab_depth_p, tab_overhang_p, button_axis,
                              tab_fillet_p, tab_taper_gain_p, tab_taper_start_p, tab_rotate_p,
                              tab_wire_hole, tab_wire_hole_d, tab_wire_hole_exit_from_lip, nn);
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
             " mm full-thickness lip extension, inner face tapers +", tab_taper_gain_p,
             " mm radially starting ", tab_taper_start_p, " mm below the lip, ",
             tab_fillet_p, " mm bottom-edge fillet, on the ", button_axis,
             " axis rotated ", tab_rotate_p, " deg.");
    if (side_tabs && tab_wire_hole)
        echo("CAP: tab wire hole -- ", tab_wire_hole_d,
             " mm dia, from the tip down to ", tab_wire_hole_exit_from_lip,
             " mm below the lip, where it breaks into the cavity.");
}
// [bundle] end   <../lib/control_cap.scad>
// [bundle] begin use <../lib/sail_shaft.scad>
// ==========================================================================
//  Turtle Body -- sail shaft: uniform round centre axle  (lib module)
// --------------------------------------------------------------------------
//  TB-08: one uniform round bar top to bottom -- no hex section. The lower
//  (round_inside_cap) portion bears/free-spins in the cap's bore; the upper
//  portion continues on up through the cage hub and the top sail bar's own
//  hole with a light running clearance (p_axle_shaft_hole_d()) and is
//  locked to the ROTATING cage by a single radial M3 set screw through the
//  cage hub (see lib/control_cage.scad) instead of a shaped interference
//  fit. Magnet recess opens at the round/lower end for an AS5600 sensing
//  magnet. See CLAUDE.md s9.
//
//  TB-04: derived to the resolved 5 mm cap roof (TB-03). round_inside_cap
//  spans roof underside -> round end, 30 mm, INCLUDING the boss -- do not
//  add the boss again -- + the 5 mm roof + 1 mm proud, so the shaft's
//  lower end still sits 1 mm above the cap's outer face and the overall
//  shaft is 59 mm.
//
//  Definitions only. Geometry is emitted by sail_shaft().
// ==========================================================================

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
// [bundle] end   <params.scad>

module sail_shaft(round_d          = p_axle_round_d(),
                  round_inside_cap = p_axle_round_inside_cap(),  // 30, roof underside -> round end
                  round_ext        = p_axle_round_ext(),         // 1, proud of the cap face
                  cap_roof_t       = p_cap_roof_t(),              // 5 (TB-03)
                  upper_len        = p_axle_upper_len(),          // 23, continues up through cage + sail bar
                  magnet           = true,
                  magnet_d         = p_magnet_d(),
                  magnet_t         = p_magnet_t(),
                  fn               = undef) {
    nn        = fn == undef ? p_fn_plastic() : fn;
    round_len = round_inside_cap + cap_roof_t + round_ext;
    total_len = upper_len + round_len;

    // ---- interface asserts (inputs from the shared contract) ----
    assert(round_d > 0 && round_d < p_cap_axle_bore_d(),
           "sail_shaft: shaft must clear the cap bore.");
    assert(round_d < p_axle_shaft_hole_d(),
           "sail_shaft: shaft must clear the cage hub / sail bar running hole.");
    assert(round_inside_cap > 0 && cap_roof_t > 0 && round_ext >= 0 && upper_len > 0);
    assert(round_inside_cap > p_cap_boss_depth(),
           "sail_shaft: shaft must pass the boss.");
    assert(round_inside_cap < p_cap_insert_len(),
           "sail_shaft: keep the lower end inside the cap's open insert rim.");
    assert(upper_len + round_ext >
           p_cage_bearing_d() / 2 + p_cage_roof_t() + p_top_crossbar_t(),
           "sail_shaft: shaft must reach through the cage roof and sail bar.");
    assert(!magnet || (magnet_d > 0 && magnet_d < round_d
           && magnet_t > 0 && magnet_t < round_inside_cap));

    $fn = nn;
    difference() {
        cylinder(d = round_d, h = total_len);
        if (magnet)
            translate([0, 0, total_len - magnet_t])
                cylinder(d = magnet_d, h = magnet_t + p_eps());
    }

    echo("SAIL SHAFT: total / round-in-cap / upper length = ", total_len, round_len, upper_len);
    echo("SAIL SHAFT: diameter (uniform, no hex) = ", round_d);
}

// Print pose: either end can sit flat on the bed (a bare cylinder); modelled
// with the upper (cage-lock) end at Z=0 and the magnet opening up, matching
// the as-modelled orientation used before TB-08 -- no reseat module needed.
// [bundle] end   <../lib/sail_shaft.scad>
// [bundle] begin use <../lib/control_cage.scad>
// ==========================================================================
//  Turtle Body -- rotating control cage  (lib module)
// --------------------------------------------------------------------------
//  An inverted open-bottom cup. One continuous sinusoidal annular wall
//  forms four rounded crests; each batten groove and its two M3 holes are
//  centred on a crest. Eight solid hemispherical bearing bumps ride on the
//  cap's flat face. No bottom plate, no separate tabs. See CLAUDE.md s6.
//
//  Native "installed" reference: bearing tips touch cap Z = 0.
//    roof underside  Z = bump_d/2         (= 4.5 default)
//    roof top        Z = bump_d/2 + roof  (= 10.5)
//    longest tip     Z = -(skirt + extension) + bump_d/2   (= -59.5)
//
//  FABRICATION -- READ BEFORE CHANGING THE ROOF: this part is 3D-PRINTED
//  ROOF-FACE-DOWN. The flat top surface goes on the printer bed (the
//  wrapper's part="print" pose flips it; see CLAUDE.md s6 / s16). Every
//  roof-top feature must be self-supporting in that orientation:
//    * a bevel/chamfer on the roof-top edge must flare OUTWARD as it rises
//      from the bed (<= 45 deg from vertical) -- p_cage_roof_bevel() is a
//      true 45-deg outward chamfer and is printable as-is;
//    * do NOT add a downward-facing pocket, lip or overhang to the roof top,
//      and do NOT make the bevel an undercut (radius growing then shrinking).
//  A change that would need support material in the roof-down pose must be
//  flagged to the user, not silently made. The horizontal M3 bores (batten
//  mounts + the TB-08 shaft set screw) bridge in the slicer; keep them
//  inspectable. The recessed clip pocket around the axle is behind
//  `top_pocket` (OFF by default -- no shaft clip while prototyping).
//
//  TB-08: the central bore is now a plain round hole (shaft_hole_d, shared
//  with the sail bar's own hole) that the uniform round shaft passes
//  through with a light running clearance -- not a shaped (hex)
//  interference fit. A single radial M3 set screw through the hub wall
//  (setscrew_pilot_d/setscrew_angle) presses on the shaft to lock it to the
//  rotating cage. The pilot is a self-tapping hole into the printed PLA hub,
//  not a clearance hole for a separate nut -- untested thread engagement.
//
//  Definitions only. Geometry is emitted by control_cage(); the wrapper /
//  full assembly applies the print-pose or installed transform.
// ==========================================================================

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
// [bundle] end   <params.scad>

// ---- native-frame Z references (for the full-assembly transform) --------
function cage_under_z(bearing_d = p_cage_bearing_d()) = bearing_d / 2;
function cage_roof_top_z(bearing_d = p_cage_bearing_d(), roof_t = p_cage_roof_t()) =
    bearing_d / 2 + roof_t;
function cage_wall_tip_z(bearing_d = p_cage_bearing_d(),
                         skirt = p_cage_skirt_depth(),
                         extension = p_cage_peak_extension()) =
    bearing_d / 2 - skirt - extension;

module control_cage(inner_d       = p_cage_inner_d(),
                    outer_d       = p_cage_outer_d(),
                    roof_t        = p_cage_roof_t(),
                    skirt         = p_cage_skirt_depth(),
                    extension     = p_cage_peak_extension(),
                    valley_wall_h = p_cage_valley_wall_h(),
                    notch_w       = p_cage_notch_w(),
                    notch_depth   = p_cage_notch_depth(),
                    notch_count   = p_cage_notch_count(),
                    m3_d          = p_cage_mount_hole_d(),
                    lower_hole_from_tip = p_cage_lower_hole_from_tip(),
                    bump_d        = p_cage_bearing_d(),
                    bump_count    = p_cage_bearing_count(),
                    bump_pcd      = p_cage_bearing_pcd(),
                    hub_d         = p_cage_hub_d(),
                    shaft_hole_d  = p_axle_shaft_hole_d(),
                    pocket_d      = p_cage_pocket_d(),
                    pocket_depth  = p_cage_pocket_depth(),
                    top_pocket    = false,  // recessed clip pocket around the axle; off for prototyping
                    button_d      = p_cage_top_hole_d(),
                    button_r      = p_button_radius(),
                    button_angle  = 90,
                    scallops      = true,
                    roof_bevel    = p_cage_roof_bevel(),
                    wave_segments = p_cage_wave_segments(),
                    setscrew_pilot_d = p_cage_setscrew_pilot_d(),  // TB-08: locks the shaft to the cage
                    setscrew_angle   = p_cage_setscrew_angle(),
                    fn            = undef) {
    nn  = fn == undef ? p_fn_plastic() : fn;
    eps = p_eps();
    ri  = inner_d / 2;
    ro  = outer_d / 2;
    groove_r = ro - notch_depth;

    cage_under      = bump_d / 2;
    cage_top        = cage_under + roof_t;
    cage_bottom     = cage_under - skirt;
    cage_hub_bottom = 1;
    pocket_floor    = cage_top - pocket_depth;
    wall_tip_z      = cage_bottom - extension;
    max_wall_h      = skirt + extension;
    wave_n          = max(48, 4 * ceil(wave_segments / 4));
    mount_hole_z    = cage_bottom + skirt / 2;
    lower_hole_z    = wall_tip_z + lower_hole_from_tip;
    cut_start       = ri - m3_d;
    cut_length      = ro - cut_start + 2 * eps;
    // Set-screw hole: centred in the hub's own Z span so it clears both the
    // hub floor and the roof top with margin either side.
    setscrew_z      = (cage_hub_bottom + cage_top) / 2;

    // four identical rounded crests: max wall height at 0/90/180/270
    function edge_z(a) = wall_tip_z + (scallops ?
        (max_wall_h - valley_wall_h) * (1 - cos(4 * a)) / 2 : 0);
    hole_edge_angle = asin((m3_d / 2) / ri);

    assert(inner_d > 0 && p_cap_cage_radial_clearance() > 0);
    assert(p_cage_wall_t() > notch_depth && notch_depth > 0 && notch_w > 0);
    assert(m3_d > 0 && m3_d < notch_w);
    assert(valley_wall_h > 0 && valley_wall_h < skirt);
    assert(extension >= 0);
    assert(lower_hole_from_tip > m3_d / 2 + 2
           && lower_hole_from_tip < max_wall_h - m3_d / 2);
    assert(bump_d > 0 && bump_pcd / 2 + bump_d / 2 < ri);
    assert(shaft_hole_d > 0 && shaft_hole_d < hub_d,
           "control_cage: shaft hole must fit inside the hub.");
    assert(roof_t >= 2 && cage_top > cage_hub_bottom + 2,
           "control_cage: roof too thin over the shaft hub.");
    if (top_pocket) {
        // recessed clip pocket around the axle -- kept behind a flag while
        // prototyping without a shaft clip. See CLAUDE.md s6.
        assert(roof_t > pocket_depth && pocket_depth > 0);
        assert(shaft_hole_d < pocket_d);
        assert(hub_d > pocket_d && pocket_d > 25 && pocket_floor > cage_hub_bottom);
        assert(pocket_floor <= 6.5 && cage_top > 10.2,
               "control_cage: keep the shaft / clip axial clearances.");
    }
    assert(button_r - button_d / 2 > hub_d / 2 && button_r + button_d / 2 < ri);
    assert(button_r + button_d / 2 < bump_pcd / 2 - bump_d / 2,
           "control_cage: button must clear the bearings at every angle.");
    assert(lower_hole_z - m3_d / 2 > edge_z(hole_edge_angle) + 2,
           "control_cage: lower M3 hole needs 2 mm material to the sine edge.");
    // TB-08: single radial set screw through the hub wall, pressing on the
    // shaft to lock it to the (rotating) cage.
    assert(setscrew_pilot_d > 0 && setscrew_pilot_d < hub_d,
           "control_cage: set screw pilot must fit within the hub.");
    assert(setscrew_z - setscrew_pilot_d / 2 > cage_hub_bottom
           && setscrew_z + setscrew_pilot_d / 2 < cage_top,
           "control_cage: set screw hole must stay inside the hub's own height.");
    // FABRICATION: roof prints face-down. Bevel is chamfered off that face,
    // must leave a flat central landing, and must not undercut.
    assert(roof_bevel >= 0 && roof_bevel < roof_t,
           "control_cage: roof_bevel must be 0..roof_t.");
    assert(roof_bevel < ro - hub_d / 2 - 2,
           "control_cage: roof_bevel leaves no flat roof-top landing.");

    module groove_cuts_2d()
        for (a = [0 : 360 / notch_count : 359]) rotate(a)
            translate([groove_r, -notch_w / 2])
                square([notch_depth + eps, notch_w]);

    module outer_profile()
        difference() { circle(r = ro, $fn = nn); groove_cuts_2d(); }

    // 45-deg OUTWARD chamfer on the roof-top outer edge, run around the full
    // perimeter -- the batten grooves are chamfered along with everything
    // else, not masked out, so no groove wall stands proud of the bevel.
    // Printable roof-down: radius only grows from the bed upward.
    module roof_bevel_cutter()
        rotate_extrude($fn = nn)
            polygon([[ro - roof_bevel, cage_top + eps],
                     [ro + 1,          cage_top + eps],
                     [ro + 1,          cage_top - roof_bevel]]);

    module wave_ring() {
        pts = [for (i = [0 : wave_n - 1]) each let(a = i * 360 / wave_n,
                lo = edge_z(a), hi = cage_under + eps) [
            [ro * cos(a), ro * sin(a), lo], [ri * cos(a), ri * sin(a), lo],
            [ro * cos(a), ro * sin(a), hi], [ri * cos(a), ri * sin(a), hi]
        ]];
        faces = [for (i = [0 : wave_n - 1]) each let(b = 4 * i, c = 4 * ((i + 1) % wave_n)) [
            [b, c, c + 2], [b, c + 2, b + 2],
            [b + 1, b + 3, c + 3], [b + 1, c + 3, c + 1],
            [b + 2, c + 2, c + 3], [b + 2, c + 3, b + 3],
            [b, b + 1, c + 1], [b, c + 1, c]
        ]];
        polyhedron(points = pts,
                   faces = [for (f = faces) [f[2], f[1], f[0]]], convexity = 12);
    }

    module scalloped_wall() {
        difference() {
            wave_ring();
            translate([0, 0, wall_tip_z - eps])
                linear_extrude(height = max_wall_h + 3 * eps) groove_cuts_2d();
        }
    }

    module hemisphere()
        intersection() {
            sphere(d = bump_d, $fn = nn);
            translate([-bump_d, -bump_d, -bump_d])
                cube([2 * bump_d, 2 * bump_d, bump_d + eps]);
        }

    $fn = nn;
    difference() {
        union() {
            scalloped_wall();
            translate([0, 0, cage_under])
                linear_extrude(height = roof_t) outer_profile();
            translate([0, 0, cage_hub_bottom])
                cylinder(d = hub_d, h = cage_top - cage_hub_bottom);
            for (a = [0 : 360 / bump_count : 359]) rotate([0, 0, a])
                translate([bump_pcd / 2, 0, cage_under]) hemisphere();
        }
        translate([0, 0, cage_hub_bottom - eps])
            cylinder(d = shaft_hole_d,
                     h = cage_top - cage_hub_bottom + 2 * eps);
        // TB-08: single radial set screw, drilled from the hub's outer
        // surface in past the centre so it always reaches the shaft hole
        // regardless of shaft_hole_d.
        rotate([0, 0, setscrew_angle])
            translate([-eps, 0, setscrew_z])
                rotate([0, 90, 0])
                    cylinder(d = setscrew_pilot_d, h = hub_d / 2 + 2 * eps, $fn = 32);
        if (top_pocket)
            translate([0, 0, pocket_floor])
                cylinder(d = pocket_d, h = pocket_depth + eps);
        rotate([0, 0, button_angle]) translate([button_r, 0, cage_under - eps])
            cylinder(d = button_d, h = roof_t + 2 * eps);
        for (a = [0 : 90 : 270]) rotate([0, 0, a])
            for (z = [mount_hole_z, lower_hole_z])
                translate([cut_start, 0, z]) rotate([0, 90, 0])
                    cylinder(d = m3_d, h = cut_length);
        if (roof_bevel > 0) roof_bevel_cutter();
    }

    echo("CAGE: OD / ID / roof-to-tip = ", outer_d, inner_d, cage_top - wall_tip_z);
    echo("CAGE: groove w / d = ", notch_w, notch_depth,
         " | M3 dia / pitch = ", m3_d, mount_hole_z - lower_hole_z);
    echo("CAGE: shaft hole = ", shaft_hole_d,
         " | set-screw pilot dia / angle = ", setscrew_pilot_d, setscrew_angle);
    echo("CAGE: prints ROOF-FACE-DOWN (flat top on the bed). roof_bevel = ",
         roof_bevel, " mm, a 45-deg OUTWARD chamfer (printable). Any new ",
         "roof-top feature must be self-supporting in that pose -- no undercut, ",
         "no downward pocket, no >45-deg overhang.");
}
// [bundle] end   <../lib/control_cage.scad>
// [bundle] begin use <../lib/sail_frame.scad>
// ==========================================================================
//  Turtle Body -- sail apparatus frame  (lib module)
// --------------------------------------------------------------------------
//  Wooden frame only: top crossbar, four battens (two sail, two non-sail),
//  bottom sail bars, joint strengtheners, orange C ends and the sail
//  membranes. Emits no axle. Emits no bottle/cap/cage either unless
//  show_control_bottle=true, which adds reference-only cut_bottle +
//  control_cap + control_cage geometry (from lib/bottle_mockup.scad,
//  lib/control_cap.scad, lib/control_cage.scad), positioned the same way
//  the full turtle places them relative to the frame. See CLAUDE.md s10.
//
//  Final screw-hole rules (TB-01): both Ø3.2 cage-mount holes kept in ALL
//  four battens; no tangential M6 bore in the C pieces; no lower joint bore
//  in the non-sail battens. Bottom rails are brown (TB-02).
//
//  Lifted verbatim from the standalone Turtle_Sail_Apparatus.scad, which
//  already carries those decisions. The inert cap/cage/axle parameter block
//  is retained only because several live frame asserts read from it.
//
//  Definitions only. Geometry is emitted by sail_frame().
// ==========================================================================

// [bundle] begin use <params.scad>
// [bundle] already inlined: params.scad
// [bundle] end   <params.scad>
// [bundle] begin use <util.scad>
// [bundle] already inlined: util.scad
// [bundle] end   <util.scad>
// [bundle] begin use <bottle_mockup.scad>
// [bundle] already inlined: bottle_mockup.scad
// [bundle] end   <bottle_mockup.scad>
// [bundle] begin use <control_cap.scad>
// [bundle] already inlined: control_cap.scad
// [bundle] end   <control_cap.scad>
// [bundle] begin use <control_cage.scad>
// [bundle] already inlined: control_cage.scad
// [bundle] end   <control_cage.scad>

module sf_wood(coded_color, colored = true)
    color(colored ? coded_color : p_wood_shade_sail()) children();

module sail_frame(
    bottle_diameter = p_bottle_d(),
    bottle_height = p_bottle_h(),
    cap_diameter = p_bottle_cap_d(),
    cap_height = p_bottle_cap_h(),
    collar_diameter = p_collar_d(),
    top_dome_height = p_top_dome_h(),
    bottom_dome_height = p_bottom_dome_h(),
    board_width = p_wood_t(),
    batten_cage_m6_hole_diameter = p_m6_clearance_d(),
    cage_mount_hole_diameter = p_cage_mount_hole_d(),
    cage_wave_segments = p_cage_wave_segments(),
    cage_valley_wall_height = p_cage_valley_wall_h(),
    cage_peak_extension = p_cage_peak_extension(),
    cage_lower_hole_from_tip = p_cage_lower_hole_from_tip(),
    cage_button_angle = 0,
    side_batten_height = p_side_batten_h(),
    cage_vertical_position = 0,
    cage_rotation_angle = 0,
    sail_frame_rotation_angle = 90,
    cage_exploded_view = 0,
    bottle_dome_power = p_dome_power(),
    bottle_neck_height = p_bottle_neck_h(),
    bottle_collar_height = p_bottle_collar_h(),
    bottle_bottom_base_ratio = 0.88,
    bottle_profile_steps = 16,
    curve_segments = p_fn_curve(),
    part = "assembly",
    colored = true,
    show_hardware = true,
    show_control_bottle = false
) {
    $fn = curve_segments;
    cage_epsilon = 0.02;
    m6_bolt_shaft_diameter = 6;
    m6_bolt_head_diameter = 12;
    m6_bolt_head_thickness = 4;
    // Assembly alignment, independent of the user-controlled rotor angle.
    cage_mount_alignment_angle = 90;

    assert(curve_segments >= 12, "Use at least 12 curve segments.");
    assert(board_width > 0, "Board thickness must be positive.");
    if (part == "full_assembly") {
        echo("SAIL: fixed control bottle and independently rotating cage/sails");
        echo("SAIL shared bottle / wood dimensions = ", bottle_diameter, board_width);
    }

    // Integration controls
    bottle_cut_extra_height = 5;
    bottle_wall_thickness = 0.5;
    insert_shaft_radial_clearance = 1.0;

    bottle_cut_height =
        bottom_dome_height + bottle_cut_extra_height;

    bottle_socket_diameter =
        bottle_diameter - 2 * bottle_wall_thickness;

    // ============================================================
    // TOP SAIL BAR
    // ============================================================
    top_sail_bar_length = 6 * bottle_diameter;
    top_sail_bar_width = 22;
    top_sail_bar_thickness = board_width;

    top_sail_bar_slot_depth = 11;
    top_sail_bar_slot_width = 10;
    // TB-08: round shaft + running clearance (was Ø12 for the hex corners).
    top_sail_bar_axle_hole_diameter = p_sail_bar_axle_hole_d();

    // ============================================================
    // SIDE BATTENS
    // ============================================================
    side_batten_width = 20;
    side_batten_thickness = top_sail_bar_slot_width;

    // Both end slots match the board width exactly.
    side_batten_notch_height = board_width;
    side_batten_notch_depth = side_batten_width / 2;
    side_batten_end_margin = 15;

    // ============================================================
    // BOTTOM SAIL BARS
    // ============================================================
    bottom_sail_bar_length = 3 * bottle_diameter;
    bottom_sail_bar_width = top_sail_bar_width;
    bottom_sail_bar_thickness = board_width;

    bottom_sail_bar_slot_width = side_batten_thickness;
    bottom_sail_bar_slot_depth = bottom_sail_bar_width / 2;
    bottom_sail_bar_bottle_clearance = 1;

    // Compact C-shaped retainers for the perpendicular battens.
    c_end_piece_width = bottom_sail_bar_width;
    c_end_piece_thickness = board_width;
    c_end_piece_outer_extension = 15;

    // Lower sail-bar / batten joint strengthener: a solid block that sits
    // directly on top of the bottom rail, its bottom face resting on the
    // rail's own top (horizontal) surface. No notch, no fastener into the
    // rail -- the rail keeps only its own batten slot (see
    // bottom_sail_bar_part()), and the strengthener is held by the
    // horizontal M6 bolt through the side batten alone.
    joint_strengthener_width = 24;
    joint_strengthener_above_bar = 24;
    joint_strengthener_thickness = board_width;
    joint_strengthener_height = joint_strengthener_above_bar;

    // Front-facing M6 bolt through the centre of the block.
    joint_strengthener_m6_z_local = joint_strengthener_above_bar / 2;
    side_batten_strengthener_m6_z_local =
        side_batten_end_margin + bottom_sail_bar_thickness
        + joint_strengthener_above_bar / 2;

    // ============================================================
    // SAILS
    // ============================================================
    sail_thickness = 0.1;
    // Straight fold-over tab at each rail edge (top and bottom), for
    // stapling the sail membrane to the rail. Height = board_width, so the
    // tab folds flat onto the rail's stock thickness without protruding
    // beyond the far face of the rail.
    sail_tab_height = board_width;

    // ============================================================
    // MASTER REFERENCE
    // ============================================================
    cx = 0;
    cy = 0;

    // ============================================================
    // CAP TOP / CUP SHELL CONTROL
    // ============================================================
    insert_shaft_diameter =
        bottle_socket_diameter
        - 2 * insert_shaft_radial_clearance;

    // Increased by 9 mm to strengthen the inner closures of the
    // lower sail bars and C end pieces.
    insert_shaft_to_top_disk_diameter_step = 21;

    control_cap_diameter =
        insert_shaft_diameter
        + insert_shaft_to_top_disk_diameter_step;

    top_disk_od = control_cap_diameter;

    top_disk_thickness = 4.0;   // strengthened roof and shaft bearing
    cup_wall_thickness = 4;   // adjustable

    // The underside of the top disk sits on the bottle cut plane.
    // Only the insert shaft crosses into the bottle.
    control_assembly_z =
        bottle_cut_height - top_disk_thickness;

    // ============================================================
    // INSERT SHAFT (OUTER SHAPE)
    // ============================================================
    insert_total_h      = 35.0;

    plug_top_od = insert_shaft_diameter;
    plug_bottom_od = plug_top_od;

    entry_chamfer_h     = 1.0;
    entry_chamfer_delta = 1.0;

    // ============================================================
    // SILICONE BAND CHANNEL SYSTEM
    // ============================================================
    //
    // Two indented circumferential channels on the OUTSIDE of the shaft.
    //
    band_channels_enable = true;
    band_count           = 1;

    band1_center_z_local = 16.0;
    band2_center_z_local = 36.0;

    band_channel_w       = 13.0;  // axial height
    band_channel_depth   = 1.1;   // radial depth inward from outer surface

    // ============================================================
    // BUTTONS
    // ============================================================
    button_upper_d      = 17.0;
    button_axis         = "y";
    hole_spacing_cc     = 24;

    button_preview_height_above_cap = 2;

    // ============================================================
    // CENTER SHAFT / SERVO TOP HOLE
    // ============================================================
    shaft_hole_d        = 8.6;

    // ============================================================
    // SAIL SHAFT (TB-08: uniform round, no hex)
    // ============================================================
    round_shaft_diameter   = 8.0;
    round_shaft_length     = 30.0;  // length inside the cap cavity
    round_shaft_extension_above_cap = 1.0;
    shaft_upper_length     = 23.0; // continues up through the cage hub + sail bar (was hex_shaft_length)

    // ============================================================
    // DERIVED
    // ============================================================
    plug_total_h = top_disk_thickness + insert_total_h;
    disk_r       = top_disk_od / 2;

    // Inner cavity diameters for cup shell
    inner_top_od_raw    = plug_top_od    - 2 * cup_wall_thickness;
    inner_bottom_od_raw = plug_bottom_od - 2 * cup_wall_thickness;

    inner_top_od        = max(1.0, inner_top_od_raw);
    inner_bottom_od     = max(1.0, inner_bottom_od_raw);

    inner_chamfer_delta = max(0, entry_chamfer_delta);
    inner_tip_od        = max(0.5, inner_bottom_od - inner_chamfer_delta);

    // ============================================================
    // HELPERS
    // ============================================================
    function clamp(v, lo, hi) = min(max(v, lo), hi);

    function taper_od_at(z_local) =
        plug_top_od + (plug_bottom_od - plug_top_od) * (z_local / insert_total_h);

    // ============================================================
    // WARNINGS
    // ============================================================
    if (hole_spacing_cc + button_upper_d/2 > disk_r)
        echo("WARNING: button holes may exceed top disk.");

    if (plug_top_od < plug_bottom_od)
        echo("WARNING: plug_top_od should not be smaller than plug_bottom_od.");

    if (entry_chamfer_h > insert_total_h)
        echo("WARNING: entry_chamfer_h exceeds insert_total_h.");

    if (inner_top_od_raw <= 0)
        echo("WARNING: cup_wall_thickness too large for plug_top_od.");

    if (inner_bottom_od_raw <= 0)
        echo("WARNING: cup_wall_thickness too large for plug_bottom_od.");

    // ============================================================
    // BASE BODY
    // ============================================================


    // ============================================================
    // OUTER SILICONE BAND CHANNEL CUTS
    // ============================================================
    //
    // These remove material only in the OUTER annular shell region.
    // They do not cut the whole shaft away.
    //




    // ============================================================
    // OUTER BODY
    // ============================================================


    // ============================================================
    // CUP INTERIOR CAVITY
    // ============================================================


    // ============================================================
    // SERVO AXLE / CENTER HOLE CUT
    // ============================================================


    // ============================================================
    // BUTTON HOLES
    // ============================================================








    // ============================================================
    // CONTROL AXLE
    // ============================================================
    //
    // Installed orientation:
    // - Ø8 mm round section extends 30 mm into the cup cavity
    // - round section passes through the 8 mm cap roof
    // - round section projects 1 mm beyond the cap's outer face
    // - 10 mm AF hex section begins after the round extension
    //




    // ============================================================
    // CONTROL CAP
    // ============================================================


    // ============================================================
    // TURTLE CONTROL CAGE
    // ============================================================

    cage_surface_thickness = p_cage_roof_t();
    cage_side_wall_thickness = 6.5;

    // Preserve 1 mm radial running clearance around the top disk.
    control_cap_to_cage_diametral_clearance = 2;
    cage_inner_cavity_diameter =
        control_cap_diameter
        + control_cap_to_cage_diametral_clearance;

    cage_outer_diameter =
        cage_inner_cavity_diameter
        + 2 * cage_side_wall_thickness;

    // TB-08: plain round shaft bore through the hub (was a hex bore).
    cage_shaft_hole_diameter = p_axle_shaft_hole_d();

    cage_top_hole_diameter = 18;
    cage_top_hole_angle = cage_button_angle;

    cage_bearing_diameter = 9;
    cage_bearing_count = 8;
    cage_bearing_contact_edge_overhang = 0.25;
    cage_bearing_pcd =
        control_cap_diameter
        - cage_bearing_diameter
        + 2 * cage_bearing_contact_edge_overhang;

    cage_total_height = p_cage_total_h(); // skirt depth + roof thickness (48 at defaults)
    cage_hub_diameter = 29;
    // Clip pocket around the axle: removed for prototyping
    // (lib/control_cage.scad top_pocket = false). Kept for the day it returns.
    cage_clip_pocket_diameter = 26;
    cage_clip_pocket_depth = 4;

    cage_notch_count = 4;
    cage_notch_width = 22.5;
    cage_notch_depth = 3.7;

    cage_outer_radius = cage_outer_diameter / 2;
    cage_inner_cavity_radius = cage_inner_cavity_diameter / 2;
    cage_notch_root_radius = cage_outer_radius - cage_notch_depth;

    // Clean radial relationship between bottle, battens, and lower bars.
    bottle_outer_radius = bottle_diameter / 2;
    side_batten_to_bottle_clearance =
        cage_notch_root_radius - bottle_outer_radius;
    bottom_sail_bar_inner_radius =
        bottle_outer_radius + bottom_sail_bar_bottle_clearance;
    bottom_sail_bar_inner_overhang =
        cage_notch_root_radius - bottom_sail_bar_inner_radius;

    c_end_piece_length =
        bottom_sail_bar_inner_overhang
        + side_batten_thickness
        + c_end_piece_outer_extension;

    // Place each sail-bar slot so its inward-facing edge is flush
    // with the inner/root surface of the corresponding cage notch.
    top_sail_bar_slot_centre_radius =
        cage_notch_root_radius + top_sail_bar_slot_width / 2;
    cage_surface_under_z =
        cage_total_height - cage_surface_thickness;
    cage_side_wall_height =
        cage_surface_under_z + cage_epsilon;

    // One shared native-Z datum keeps all four cage and batten holes aligned.
    cage_slot_vertical_centre_z = cage_surface_under_z / 2;
    cage_wall_tip_z = -cage_peak_extension;
    cage_lower_mount_z = cage_wall_tip_z + cage_lower_hole_from_tip;
    cage_mount_z_positions = [cage_slot_vertical_centre_z, cage_lower_mount_z];
    cage_wave_n = max(48, 4 * ceil(cage_wave_segments / 4));
    function cage_edge_z(a) = cage_wall_tip_z
        + (cage_surface_under_z + cage_peak_extension - cage_valley_wall_height)
            * (1 - cos(4*a)) / 2;
    side_batten_top_native_z =
        cage_total_height
        + top_sail_bar_thickness
        + (side_batten_notch_height - top_sail_bar_thickness) / 2
        + side_batten_end_margin;
    side_batten_bottom_native_z =
        side_batten_top_native_z - side_batten_height;
    side_batten_cage_hole_z_local =
        cage_slot_vertical_centre_z - side_batten_bottom_native_z;

    // Lower M6 joint shared by each non-sail batten and orange C piece.
    non_sail_joint_m6_z_local =
        side_batten_end_margin + c_end_piece_thickness / 2;
    c_end_piece_m6_x_local =
        bottom_sail_bar_inner_overhang + side_batten_thickness / 2;
    // Button positions remain fixed at the cap's 24 mm radius.
    cage_top_hole_radial_position = hole_spacing_cc;
    cage_top_hole_edge_to_centre =
        cage_outer_radius - cage_top_hole_radial_position;

    // In the cage's native coordinates, this is the bearing-tip plane.
    cage_bearing_tip_native_z =
        cage_surface_under_z - cage_bearing_diameter / 2;

    assert(cage_valley_wall_height > 0
           && cage_valley_wall_height < cage_surface_under_z
           && cage_peak_extension >= 0);
    assert(cage_mount_hole_diameter > 0
           && cage_mount_hole_diameter < cage_notch_width);
    assert(cage_lower_mount_z - cage_mount_hole_diameter / 2 >
           cage_edge_z(asin(cage_mount_hole_diameter / 2 / cage_inner_cavity_radius)) + 2,
           "Lower M3 hole needs 2 mm material to the sine edge.");
    assert(min(cage_mount_z_positions) - side_batten_bottom_native_z
           > cage_mount_hole_diameter / 2
           && max(cage_mount_z_positions) - side_batten_bottom_native_z
           < side_batten_height - cage_mount_hole_diameter / 2);
    // (clip-pocket dimension assert removed with the pocket -- top_pocket = false)
    assert(cage_hub_diameter > cage_shaft_hole_diameter,
           "Shaft hub must clear the shaft bore.");
    assert(cage_top_hole_radial_position - cage_top_hole_diameter/2
           > cage_hub_diameter/2);
    assert(cage_top_hole_radial_position + cage_top_hole_diameter/2
           < cage_bearing_pcd/2 - cage_bearing_diameter/2);
    assert(round_shaft_extension_above_cap + shaft_upper_length
           > cage_bearing_diameter/2 + cage_surface_thickness + top_sail_bar_thickness,
           "Sail shaft must reach through the cage roof and sail bar.");

    assert(cage_outer_diameter > 0,
        "Cage outer diameter must be greater than zero.");
    assert(cage_surface_thickness > 0,
        "Cage surface thickness must be greater than zero.");
    assert(cage_total_height > cage_surface_thickness,
        "Cage height must exceed its surface thickness.");
    assert(cage_side_wall_thickness > 0
           && cage_inner_cavity_diameter > 0,
        "Cage side-wall thickness leaves no inner cavity.");
    assert(cage_notch_count > 0
           && cage_notch_width > 0
           && cage_notch_depth > 0
           && cage_notch_depth < cage_side_wall_thickness,
        "Cage notches must be shallower than the side wall.");
    assert(cage_bearing_count > 0
           && cage_bearing_diameter > 0,
        "Cage bearing dimensions must be positive.");
    assert(cage_bearing_pcd / 2
           + cage_bearing_diameter / 2
           < cage_inner_cavity_radius,
        "The cage bearings do not fit inside the cavity.");
    assert(cage_top_hole_radial_position
           + cage_top_hole_diameter / 2
           < cage_outer_radius,
        "The cage top hole breaks through the circular edge.");
    assert(top_sail_bar_width <= cage_notch_width,
        "The top sail bar is wider than the cage side slots.");
    assert(
        abs(top_sail_bar_slot_depth
            - top_sail_bar_width / 2) < 0.001,
        "Top sail bar slots must reach the bar centreline."
    );
    assert(cage_shaft_hole_diameter < top_sail_bar_width,
        "The shaft opening does not fit within the top sail bar.");
    assert(round_shaft_diameter < top_sail_bar_axle_hole_diameter,
        "The sail shaft does not fit through the sail bar axle hole.");
    assert(
        top_sail_bar_slot_centre_radius + top_sail_bar_slot_width / 2
            < top_sail_bar_length / 2,
        "Top sail bar slots fall outside the bar."
    );
    assert(side_batten_width <= cage_notch_width,
        "The side battens are too wide for the cage slots.");
    assert(side_batten_thickness <= top_sail_bar_slot_width,
        "The side battens are too thick for the sail-bar slots.");
    assert(side_batten_notch_height == top_sail_bar_thickness,
        "The batten slots must exactly match the sail-bar board width.");
    assert(bottom_sail_bar_thickness == side_batten_notch_height,
        "The bottom sail bars must match the lower batten slots.");
    assert(bottom_sail_bar_slot_width == side_batten_thickness,
        "The bottom sail-bar slots must match the batten thickness.");
    assert(side_batten_to_bottle_clearance > 0,
        "The side battens overlap the bottle.");
    assert(bottom_sail_bar_inner_overhang >= 0,
        "The requested bottom-bar clearance exceeds the batten clearance.");
    assert(c_end_piece_thickness == side_batten_notch_height,
        "The C end pieces must match the lower batten slots.");
    assert(bottom_sail_bar_inner_overhang >= 10,
        "The bottle-side closure must be at least 10 mm long.");
    assert(c_end_piece_outer_extension >= 10,
        "The outer C-piece closure must be at least 10 mm long.");
    assert(joint_strengthener_above_bar > m6_bolt_head_diameter
           && joint_strengthener_width > m6_bolt_head_diameter,
        "The supporter upper face must fit the M6 bolt head.");
    assert(side_batten_strengthener_m6_z_local
           + batten_cage_m6_hole_diameter / 2 < side_batten_height,
        "The supporter M6 hole must remain inside the batten.");
    assert(side_batten_cage_hole_z_local
           > batten_cage_m6_hole_diameter / 2
           && side_batten_cage_hole_z_local
           < side_batten_height - batten_cage_m6_hole_diameter / 2,
        "The M6 cage-fastening hole falls outside the batten.");
    assert(non_sail_joint_m6_z_local
           < side_batten_height - batten_cage_m6_hole_diameter / 2,
        "The lower M6 joint hole falls outside the batten.");

    echo("Side batten to bottle clearance = ",
         side_batten_to_bottle_clearance, " mm");
    echo("Bottom sail bar to bottle clearance = ",
         bottom_sail_bar_bottle_clearance, " mm");
    echo("Bottom sail bar inward protrusion = ",
         bottom_sail_bar_inner_overhang, " mm");
    echo("Bottom sail bar inner-edge radius = ",
         bottom_sail_bar_inner_radius, " mm");
    echo("Cage M3 mount heights / hole diameter = ",
         cage_mount_z_positions, cage_mount_hole_diameter);





















    // Turn the cage upside down over the cap. At position 0, the
    // hemispherical bearing tips lie exactly on the cap's Z=0 surface.


    // ============================================================
    // TOP SAIL BAR
    // ============================================================
    module top_sail_bar_profile_2d() {
        difference() {
            square([
                top_sail_bar_length,
                top_sail_bar_width
            ], center = true);

            // Left slot: cut upward from the lower edge to the centreline.
            translate([
                -top_sail_bar_slot_centre_radius - top_sail_bar_slot_width / 2,
                -top_sail_bar_width / 2 - cage_epsilon
            ])
                square([
                    top_sail_bar_slot_width,
                    top_sail_bar_slot_depth + cage_epsilon
                ]);

            // Right slot: cut downward from the upper edge to the centreline.
            translate([
                top_sail_bar_slot_centre_radius - top_sail_bar_slot_width / 2,
                0
            ])
                square([
                    top_sail_bar_slot_width,
                    top_sail_bar_slot_depth + cage_epsilon
                ]);

            // The sail-bar opening is a hard-limited Ø12 mm round hole.
            circle(d = top_sail_bar_axle_hole_diameter);
        }
    }

    module top_sail_bar_part() {
        linear_extrude(height = top_sail_bar_thickness)
            top_sail_bar_profile_2d();
    }

    module top_sail_bar_native_assembly() {
        sf_wood([0.56, 0.39, 0.39], colored)
            translate([0, 0, cage_total_height])
                top_sail_bar_part();
    }



    // ============================================================
    // SIDE BATTENS
    // ============================================================

    // Native batten coordinates:
    //   X = radial thickness
    //   Y = 20 mm visible width
    //   Z = height, bottom at Z=0
    module side_batten_part(
        notch_from_positive_y = true,
        include_upper_slot = true,
        include_lower_slot = true,
        include_non_sail_joint_hole = false,
        include_strengthener_joint_hole = false
    ) {
        difference() {
            cube([
                side_batten_thickness,
                side_batten_width,
                side_batten_height
            ]);

            notch_y = notch_from_positive_y
                ? side_batten_width - side_batten_notch_depth
                : 0;

            if (include_upper_slot) {
                // Upper notch: interlocks with the top sail crossbar.
                translate([
                    -cage_epsilon,
                    notch_y,
                    side_batten_height
                        - side_batten_end_margin
                        - side_batten_notch_height
                ])
                    cube([
                        side_batten_thickness + 2 * cage_epsilon,
                        side_batten_notch_depth + cage_epsilon,
                        side_batten_notch_height
                    ]);

            }

            if (include_lower_slot) {
                // Lower notch is retained on all four battens.
                translate([
                    -cage_epsilon,
                    notch_y,
                    side_batten_end_margin
                ])
                    cube([
                        side_batten_thickness + 2 * cage_epsilon,
                        side_batten_notch_depth + cage_epsilon,
                        side_batten_notch_height
                    ]);
            }

            // Two M3 holes on the same native Z datums as each cage peak.
            for (mount_z = cage_mount_z_positions)
                translate([-cage_epsilon, side_batten_width/2,
                           mount_z-side_batten_bottom_native_z])
                    rotate([0,90,0])
                        cylinder(h=side_batten_thickness+2*cage_epsilon,
                                 d=cage_mount_hole_diameter,$fn=72);

            if (include_strengthener_joint_hole)
                translate([
                    -cage_epsilon,
                    side_batten_width / 2,
                    side_batten_strengthener_m6_z_local
                ])
                    rotate([0, 90, 0])
                        cylinder(
                            h = side_batten_thickness + 2 * cage_epsilon,
                            d = batten_cage_m6_hole_diameter,
                            $fn = 72
                        );

            if (include_non_sail_joint_hole)
                translate([
                    side_batten_thickness / 2,
                    -cage_epsilon,
                    non_sail_joint_m6_z_local
                ])
                    rotate([-90, 0, 0])
                        cylinder(
                            h = side_batten_width + 2 * cage_epsilon,
                            d = batten_cage_m6_hole_diameter,
                            $fn = 72
                        );
        }
    }

    module opposing_side_batten_pair_native(
        include_upper_slot = true,
        include_lower_slot = true,
        include_non_sail_joint_hole = false,
        include_strengthener_joint_hole = false
    ) {
        // The upper batten notch is exactly flush with the sail bar.
        batten_top_z =
            cage_total_height
            + top_sail_bar_thickness
            + (side_batten_notch_height - top_sail_bar_thickness) / 2
            + side_batten_end_margin;

        batten_bottom_z = batten_top_z - side_batten_height;

        sf_wood([0.18, 0.78, 0.24], colored) {
            // Left batten: fills the lower-half slot in the crossbar.
            translate([
                -top_sail_bar_slot_centre_radius
                    - side_batten_thickness / 2,
                -side_batten_width / 2,
                batten_bottom_z
            ])
                side_batten_part(
                    notch_from_positive_y = true,
                    include_upper_slot = include_upper_slot,
                    include_lower_slot = include_lower_slot,
                    include_non_sail_joint_hole =
                        include_non_sail_joint_hole,
                    include_strengthener_joint_hole =
                        include_strengthener_joint_hole
                );

            // Right batten: mirrored to fill the upper-half slot.
            translate([
                top_sail_bar_slot_centre_radius
                    - side_batten_thickness / 2,
                -side_batten_width / 2,
                batten_bottom_z
            ])
                side_batten_part(
                    notch_from_positive_y = false,
                    include_upper_slot = include_upper_slot,
                    include_lower_slot = include_lower_slot,
                    include_non_sail_joint_hole =
                        include_non_sail_joint_hole,
                    include_strengthener_joint_hole =
                        include_strengthener_joint_hole
                );
        }
    }

    module side_battens_native_assembly() {
        // First opposing pair engages the two sail-crossbar slots.
        opposing_side_batten_pair_native(
            include_upper_slot = true,
            include_lower_slot = true,
            include_non_sail_joint_hole = false,
            include_strengthener_joint_hole = true
        );

        // Perpendicular pair: no top-bar joint, but keep lower slots.
        rotate([0, 0, 90])
            opposing_side_batten_pair_native(
                include_upper_slot = false,
                include_lower_slot = true,
                include_non_sail_joint_hole = false
            );
    }



    // ============================================================
    // BOTTOM SAIL BARS
    // ============================================================

    module bottom_sail_bar_part(slot_from_positive_y = true) {
        difference() {
            cube([
                bottom_sail_bar_length,
                bottom_sail_bar_width,
                bottom_sail_bar_thickness
            ]);

            slot_y = slot_from_positive_y
                ? bottom_sail_bar_width - bottom_sail_bar_slot_depth
                : 0;

            translate([
                bottom_sail_bar_inner_overhang,
                slot_y,
                -cage_epsilon
            ])
                cube([
                    bottom_sail_bar_slot_width,
                    bottom_sail_bar_slot_depth + cage_epsilon,
                    bottom_sail_bar_thickness + 2 * cage_epsilon
                ]);

            // No second (strengthener) mortise here any more: the rail
            // keeps only its own batten slot. The joint strengthener now
            // rests on the rail via its own notch's horizontal shelf and
            // is screwed down from above -- see joint_strengthener_part().
        }
    }

    module bottom_sail_bars_native_assembly() {
        batten_top_z =
            cage_total_height
            + top_sail_bar_thickness
            + (side_batten_notch_height - top_sail_bar_thickness) / 2
            + side_batten_end_margin;

        batten_bottom_z = batten_top_z - side_batten_height;
        bottom_bar_z = batten_bottom_z + side_batten_end_margin;
        bottom_bar_inner_x = bottom_sail_bar_inner_radius;

        sf_wood([0.56, 0.39, 0.39], colored) {
            // Right bar points radially outward along +X.
            translate([
                bottom_bar_inner_x,
                -bottom_sail_bar_width / 2,
                bottom_bar_z
            ])
                bottom_sail_bar_part(slot_from_positive_y = true);

            // Left bar is the identical outward-pointing mirror.
            rotate([0, 0, 180])
                translate([
                    bottom_bar_inner_x,
                    -bottom_sail_bar_width / 2,
                    bottom_bar_z
                ])
                    bottom_sail_bar_part(slot_from_positive_y = true);
        }
    }



    // ============================================================
    // LOWER SAIL-BAR JOINT STRENGTHENERS
    // ============================================================

    module joint_strengthener_part() {
        difference() {
            // Rotated slat: board thickness runs radially in X,
            // while the 24 mm face width runs tangentially in Y. Bottom
            // face (Z=0) sits flush on the rail's own top surface -- no
            // notch, no fastener into the rail itself.
            cube([
                joint_strengthener_thickness,
                joint_strengthener_width,
                joint_strengthener_height
            ]);

            // Through the broad front face (X thickness), never the side edge.
            translate([
                -cage_epsilon,
                joint_strengthener_width / 2,
                joint_strengthener_m6_z_local
            ])
                rotate([0, 90, 0])
                    cylinder(
                        h = joint_strengthener_thickness + 2 * cage_epsilon,
                        d = batten_cage_m6_hole_diameter,
                        $fn = 72
                    );
        }
    }

    module joint_strengtheners_native_assembly() {
        batten_top_z =
            cage_total_height
            + top_sail_bar_thickness
            + (side_batten_notch_height - top_sail_bar_thickness) / 2
            + side_batten_end_margin;

        batten_bottom_z = batten_top_z - side_batten_height;
        bottom_bar_z = batten_bottom_z + side_batten_end_margin;
        strengthener_z =
            bottom_bar_z + bottom_sail_bar_thickness;

        strengthener_inner_x =
            top_sail_bar_slot_centre_radius
            + side_batten_thickness / 2;

        sf_wood([0.35, 0.92, 0.34], colored) {
            // Right joint: rotated slat sits radially flush beside the batten,
            // resting on top of the bottom rail.
            translate([
                strengthener_inner_x,
                -joint_strengthener_width / 2,
                strengthener_z
            ])
                joint_strengthener_part();

            // Left joint: identical mirrored arrangement.
            rotate([0, 0, 180])
                translate([
                    strengthener_inner_x,
                    -joint_strengthener_width / 2,
                    strengthener_z
                ])
                    joint_strengthener_part();
        }
    }



    // ============================================================
    // SAILS
    // ============================================================

    module right_sail_native() {
        batten_top_z =
            cage_total_height
            + top_sail_bar_thickness
            + (side_batten_notch_height - top_sail_bar_thickness) / 2
            + side_batten_end_margin;

        batten_bottom_z = batten_top_z - side_batten_height;
        bottom_bar_z = batten_bottom_z + side_batten_end_margin;

        sail_bottom_z =
            bottom_bar_z + bottom_sail_bar_thickness;
        sail_top_z = cage_total_height;

        // Begin immediately beyond the outer face of the joint
        // strengthener and follow the two rail endpoints outward.
        sail_inner_radius =
            top_sail_bar_slot_centre_radius
            + side_batten_thickness / 2
            + joint_strengthener_thickness;

        sail_top_outer_radius = top_sail_bar_length / 2;
        sail_bottom_outer_radius =
            bottom_sail_bar_inner_radius
            + bottom_sail_bar_length;

        assert(sail_top_outer_radius > sail_inner_radius,
            "The top rail leaves no width for the sail.");
        assert(sail_bottom_outer_radius > sail_top_outer_radius,
            "The lower sail rail must extend beyond the upper rail.");
        assert(sail_top_z > sail_bottom_z,
            "The sail rails leave no vertical space for the sail.");

        // Draw in X/Z, then extrude 0.1 mm symmetrically through Y.
        // Straight tabs extend the trapezoid past each rail edge, square
        // across that edge's full width, so the membrane can be folded
        // over the rail and stapled. The sail stays one flat 2D shape.
        translate([0, sail_thickness / 2, 0])
            rotate([90, 0, 0])
                linear_extrude(height = sail_thickness)
                    polygon(points = [
                        [sail_inner_radius, sail_bottom_z - sail_tab_height],
                        [sail_bottom_outer_radius, sail_bottom_z - sail_tab_height],
                        [sail_bottom_outer_radius, sail_bottom_z],
                        [sail_top_outer_radius, sail_top_z],
                        [sail_top_outer_radius, sail_top_z + sail_tab_height],
                        [sail_inner_radius, sail_top_z + sail_tab_height]
                    ]);
    }

    module sails_native_assembly() {
        color([1, 1, 1]) {
            right_sail_native();

            rotate([0, 0, 180])
                right_sail_native();
        }
    }



    // ============================================================
    // C END PIECES FOR THE PERPENDICULAR BATTENS
    // ============================================================

    module c_end_piece_part(slot_from_positive_y = true) {
        difference() {
            cube([
                c_end_piece_length,
                c_end_piece_width,
                c_end_piece_thickness
            ]);

            slot_y = slot_from_positive_y
                ? c_end_piece_width - bottom_sail_bar_slot_depth
                : 0;

            // Side-opening half-lap creates the C profile. The solid
            // 15 mm outer end closes and strengthens the C joint.
            translate([
                bottom_sail_bar_inner_overhang,
                slot_y,
                -cage_epsilon
            ])
                cube([
                    side_batten_thickness,
                    bottom_sail_bar_slot_depth + cage_epsilon,
                    c_end_piece_thickness + 2 * cage_epsilon
                ]);

        }
    }

    module c_end_piece_pair_native() {
        batten_top_z =
            cage_total_height
            + top_sail_bar_thickness
            + (side_batten_notch_height - top_sail_bar_thickness) / 2
            + side_batten_end_margin;

        batten_bottom_z = batten_top_z - side_batten_height;
        c_piece_z = batten_bottom_z + side_batten_end_margin;

        sf_wood([1.0, 0.58, 0.26], colored) {
            translate([
                bottom_sail_bar_inner_radius,
                -c_end_piece_width / 2,
                c_piece_z
            ])
                c_end_piece_part(slot_from_positive_y = true);

            rotate([0, 0, 180])
                translate([
                    bottom_sail_bar_inner_radius,
                    -c_end_piece_width / 2,
                    c_piece_z
                ])
                    c_end_piece_part(slot_from_positive_y = true);
        }
    }

    module c_end_pieces_native_assembly() {
        // Rotate the compact pair onto the two non-sail battens.
        rotate([0, 0, 90])
            c_end_piece_pair_native();
    }



    // ============================================================
    // VISUAL M6 BOLT PLACEHOLDERS
    // ============================================================

    module cage_batten_bolts_native_assembly() {
        shaft_start_radius = cage_inner_cavity_radius - 1;
        head_radius_position = cage_notch_root_radius + side_batten_thickness;
        color([0.15,0.15,0.15])
            for(a=[0:90:270]) rotate([0,0,a])
                for(z=cage_mount_z_positions) {
                    translate([shaft_start_radius,0,z]) rotate([0,90,0])
                        cylinder(d=3,h=head_radius_position-shaft_start_radius,$fn=48);
                    translate([head_radius_position,0,z]) rotate([0,90,0])
                        cylinder(d=6,h=2,$fn=48);
                }
    }

    module sail_strengthener_bolts_native() {
        // Head on the bottle-facing batten face, away from the sail.
        // Reverse insertion through the same two coaxial holes: shank outward.
        bolt_head_radius = top_sail_bar_slot_centre_radius
            - side_batten_thickness / 2;
        bolt_z = side_batten_bottom_native_z
            + side_batten_strengthener_m6_z_local;

        for (angle = [0, 180])
            rotate([0, 0, angle])
                translate([bolt_head_radius, 0, bolt_z])
                    rotate([0, 90, 0])
                        m6_bolt_placeholder(
                            grip_length = joint_strengthener_thickness
                                + side_batten_thickness,
                            // End flush so the exposed tip also clears the sail.
                            tip_extension = 0
                        );
    }




    // ============================================================
    // CONTROL BOTTLE + CAP + CAGE (reference only)
    // ============================================================
    //
    // Reference geometry for checking the frame fits around the actual
    // control head, all gated by the one show_control_bottle switch.
    // Positioned in this module's own cage-native frame by inverting
    // src/Full_Turtle.scad's placement chain: hope_turtle_sail_apparatus()
    // places the bottle/cap/cage/frame as four sibling groups sharing one
    // "local" (pre-outer-flip) coordinate space --
    //   bottle:      translate(0,0,0)                            . p
    //   cap:         translate(0,0,control_assembly_z)            . p
    //   cage:        translate(0,0,control_assembly_z)
    //                  . rotateZ(90) . rotateX(180)                . p
    //   sail_frame:  translate(0,0,control_assembly_z+cage_bearing_tip_native_z)
    //                  . rotateZ(90) . rotateZ(90) . rotateX(180)  . p
    // (cage_vertical_position=0, cx=cy=0 at these defaults). Composing each
    // target's transform with the frame transform's inverse gives, for a
    // point p in the target's own native space, its equivalent point in
    // this module's own frame-native space:
    //   bottle:  translate(0,0, control_assembly_z + cage_bearing_tip_native_z) . rotateY(180) . p
    //   cap:     translate(0,0, cage_bearing_tip_native_z)                      . rotateY(180) . p
    //   cage:    translate(0,0, cage_bearing_tip_native_z)                      . rotateZ(90)  . p
    // (rotateY(180) on the bottle/cap looks like an odd choice next to
    // rotateX(180)/rotateZ(90) above, but it is the correct composed
    // result, not a guess -- verified against the cage line by hand: it
    // reduces to "translate by cage_bearing_tip_native_z, rotate 90 about
    // Z", exactly matching this file's own existing use of
    // cage_bearing_tip_native_z as the frame-native Z where the cap's
    // outer face / cage bearing-tip plane sits.) Inspection aid only; not
    // itself a fabrication or fit reference for the cap/cage interfaces.
    module control_reference_native() {
        translate([0, 0, control_assembly_z + cage_bearing_tip_native_z])
            rotate([0, 180, 0])
                cut_bottle(
                    bottle_d      = bottle_diameter,
                    bottle_h      = bottle_height,
                    cap_d         = cap_diameter,
                    cap_h         = cap_height,
                    collar_d      = collar_diameter,
                    collar_h      = bottle_collar_height,
                    neck_d        = cap_diameter - 3,
                    neck_h        = bottle_neck_height,
                    top_dome_h    = top_dome_height,
                    bottom_dome_h = bottom_dome_height,
                    dome_p        = bottle_dome_power,
                    base_ratio    = bottle_bottom_base_ratio,
                    steps         = bottle_profile_steps,
                    cut_height    = bottle_cut_height,
                    socket_d      = bottle_socket_diameter,
                    socket_h      = insert_total_h
                );
        translate([0, 0, cage_bearing_tip_native_z]) {
            rotate([0, 180, 0])
                color([0.78, 0.78, 0.82])
                    control_cap();
            rotate([0, 0, 90])
                color([0.74, 0.77, 0.79])
                    control_cage(button_angle = cage_button_angle);
        }
    }

    module sail_frame_native_group() {
        top_sail_bar_native_assembly();
        side_battens_native_assembly();
        bottom_sail_bars_native_assembly();
        joint_strengtheners_native_assembly();
        c_end_pieces_native_assembly();
        sails_native_assembly();
        if(show_hardware) {
            cage_batten_bolts_native_assembly();
            sail_strengthener_bolts_native();
        }
        if(show_control_bottle)
            control_reference_native();
    }

    // All parts share the cage's native coordinates. "assembly" raises the
    // batten bottoms to Z=0 for an upright inspection view; "native_assembly"
    // leaves them in cage-native Z so the full turtle can apply its own
    // control-head install transform.
    if(part=="assembly")
        translate([0,0,-side_batten_bottom_native_z]) sail_frame_native_group();
    else if(part=="native_assembly")
        sail_frame_native_group();
    else if(part=="top_bar") top_sail_bar_part();
    else if(part=="sail_batten")
        side_batten_part(include_strengthener_joint_hole=true);
    else if(part=="non_sail_batten")
        side_batten_part(include_upper_slot=false,include_non_sail_joint_hole=false);
    else if(part=="bottom_bars") bottom_sail_bars_native_assembly();
    else if(part=="strengtheners") joint_strengtheners_native_assembly();
    else if(part=="c_end_pieces") c_end_pieces_native_assembly();
    else if(part=="sails") sails_native_assembly();
    else assert(false,str("Unknown part: ",part));
    echo("Cage mount hole diameter / vertical pitch = ",
         cage_mount_hole_diameter,cage_slot_vertical_centre_z-cage_lower_mount_z);
    echo("Cage mount centres from batten bottom = ",
         [for(z=cage_mount_z_positions) z-side_batten_bottom_native_z]);
}
// [bundle] end   <../lib/sail_frame.scad>


// ============================================================================
// LIGHTWEIGHT ROTATIONAL PROFILES
// ============================================================================

// Shared material selector for wooden geometry only.
// wood_color() + m6_bolt_placeholder() now come from lib/util.scad
// [bundle] begin use <../lib/util.scad>
// [bundle] already inlined: util.scad
// [bundle] end   <../lib/util.scad>


// ============================================================================
// DIMENSION REPORT
// ============================================================================

echo("Bottle diameter = ", bottle_diameter, " mm");
echo("Ecojoiner port diameter basis = ", port_height, " mm");
echo("Bottle total height = ", bottle_height, " mm");

echo("Dome power = ", dome_power);

echo("Bottom dome height = ", bottom_dome_height, " mm");
echo("Straight body height = ", straight_body_height, " mm");
echo("Top dome height = ", top_dome_height, " mm");

echo("Bottle neck diameter = cap diameter - 3 = ",
     bottle_neck_diameter, " mm");
echo("Bottle neck height = ", bottle_neck_height, " mm");

echo("User-set collar diameter = ",
     collar_diameter, " mm");
echo("Collar height = ", collar_height, " mm");

echo("Cap diameter = ", cap_diameter, " mm");
echo("Cap height = ", cap_height, " mm");

echo("Profile steps = ", profile_steps);



// ============================================================================
// INPUT VARIABLES — retained from source file
// ============================================================================

slat_thickness = 12.000;
port_length = 82.000;
// Ecojoiner bottle dimensions are NOT separate values.
// They are aliases of the shared canonical bottle specification.
port_height = bottle_diameter;
ecojoiner_bottle_height = bottle_height;
ecojoiner_cap_diameter = cap_diameter;
m6_clearance_diameter = 6.4;
screw_diameter = m6_clearance_diameter;
fit_clearance = 0.200;


// ============================================================================
// LAYOUT CONTROLS
// ============================================================================

piece_gap = 35;


// ============================================================================
// DERIVED DIMENSIONS
// ============================================================================

john_height =
    port_height - 2 * slat_thickness;

john_length =
    2 * port_length
    + port_height
    + 4 * slat_thickness;

slot_width =
    slat_thickness + fit_clearance;

standard_slot_depth =
    ceil(john_height / 2);

long_end_span =
    port_length;

little_end_span =
    port_length + slat_thickness;

screw_side_offset =
    25;

screw_y_center =
    john_height / 2;


// Final Key dimensions restored from the original Ecojoiner source.
final_key_length =
    port_height + 4 * slat_thickness;

final_key_width =
    2 * slat_thickness;


// Presser dimensions restored from the original Ecojoiner source.
presser_diameter =
    max(1, ecojoiner_cap_diameter - 1);

presser_through_hole_diameter =
    screw_diameter;


// ============================================================================
// SAFETY CHECKS
// ============================================================================

assert(john_height > 0,
       "Bottle diameter must be greater than twice the wood thickness.");

assert(port_height == bottle_diameter,
       "Ecojoiner port_height must equal canonical bottle_diameter.");

assert(ecojoiner_cap_diameter < john_height,
       "Cap hole too large for John height.");

assert(collar_diameter < john_height,
       "Collar hole too large for John height.");


// ============================================================================
// 2D HELPERS
// ============================================================================

// [M7] module top_slot() -> lib


// [M7] module center_hole() -> lib


// [M7] module screw_holes_2d() -> lib


// ============================================================================
// JOHN PROFILES
// ============================================================================

// [M7] module long_john_2d() -> lib


// [M7] module little_john_2d() -> lib


// ============================================================================
// 3D PARTS
// ============================================================================

// [M7] module long_john() -> lib


// [M7] module little_john() -> lib


// ============================================================================
// FINAL KEY
// ============================================================================
//
// Original Ecojoiner Final Key:
//   length    = port_height + 4 * slat_thickness
//   width     = 2 * slat_thickness
//   thickness = slat_thickness
//
// Keys use their diagnostic color or the shared light-wood finish.

// [M7] module final_key() -> lib


// ============================================================================
// PRESSER
// ============================================================================
//
// Original Ecojoiner Presser:
//   diameter  = ecojoiner_cap_diameter - 1
//   thickness = slat_thickness
//   through hole = screw_diameter
//
// Pressers use their diagnostic color or the shared light-wood finish.

// [M7] module presser() -> lib

// m6_bolt_placeholder(): see lib/util.scad

// [M7] module presser_with_m6_bolt() -> lib


// ============================================================================
// VERTICAL ORIENTATION + RECTANGLE ASSEMBLY
// ============================================================================
//
// The two Little Johns remain upright with their slots opening DOWN from
// their top edges.
//
// The two Long Johns are perpendicular to them and are flipped 180 degrees
// about their own long axes. This makes the Long John slots open UP from
// the ground edge, allowing the two sets of slots to interlock.
//
// Coordinate mapping:
//
// Little John:
//   local X (length)    -> world X
//   local Y (height)    -> world Z
//   local Z (thickness) -> world Y
//
// Long John, flipped:
//   local X (length)    -> world -Y
//   local Y (height)    -> world -Z
//   local Z (thickness) -> world X
//
// All four pieces remain on the same Z=0 ground plane.


// Slot centres along each John.
little_slot_1_x =
    little_end_span + slat_thickness / 2;

little_slot_2_x =
    john_length
    - little_end_span
    - slat_thickness / 2;

long_slot_1_x =
    long_end_span + slat_thickness / 2;

long_slot_2_x =
    john_length
    - long_end_span
    - slat_thickness / 2;


// Rectangle dimensions measured between slot centre-lines.
rectangle_x =
    little_slot_2_x - little_slot_1_x;

rectangle_y =
    long_slot_2_x - long_slot_1_x;


// --------------------------------------------------------------------------
// Standing Little John
// --------------------------------------------------------------------------
//
// thickness is centred on target world-Y.

// [M7] module standing_little_john() -> lib


// --------------------------------------------------------------------------
// Standing + 180° flipped Long John
// --------------------------------------------------------------------------
//
// Long John is perpendicular to the Little Johns.
//
// The 180° flip is around its own long horizontal axis:
// local top becomes world bottom, so its slots open upward.
//
// thickness is centred on target world-X.
//
// target_y_for_slot2 positions Long John's second slot on world Y=0.
// Its first slot then lands automatically at rectangle_y.

// [M7] module standing_flipped_long_john() -> lib


// ============================================================================
// INTERLOCKED RECTANGLE
// ============================================================================
//
// Little John slot centres:
//   X = little_slot_1_x, little_slot_2_x
//
// Long John slot centres:
//   Y = 0, rectangle_y
//
// Each crossing is therefore slot-to-slot.

// [M7] module john_rectangle() -> lib


// ============================================================================
// TRIPLE RECTANGLE ASSEMBLY
// ============================================================================
//
// Frame 1 remains in the original orientation.
//
// Frame 2 is an exact duplicate, rotated 90° and spun 90° about the shared
// geometric centre.
//
// Frame 3 duplicates Frame 2 and applies ANOTHER 90° rotate + 90° spin about
// the same shared centre. This fills the remaining orthogonal plane.
//
// Because every transform is performed about the same frame centre, the
// circular centre holes remain referenced to the same 3D point.

frame_center = [
    john_length / 2,
    rectangle_y / 2,
    john_height / 2
];

frame_step_tilt = 90;
frame_step_spin = 90;


// --------------------------------------------------------------------------
// Generic centered transform
// --------------------------------------------------------------------------

// [M7] module centered_rectangle() -> lib


// --------------------------------------------------------------------------
// Three orthogonal rectangles
// --------------------------------------------------------------------------

// Frame geometry is rendered later inside complete_turtle_scene().


// ============================================================================
// FOUR FINAL KEYS
// ============================================================================
//
// In the user's inspection view, the four remaining rectangular openings
// around the central circular hole are the end-on shape of a Final Key:
//
//      12 mm x 24 mm
//      (wood thickness x 2 wood thicknesses)
//
// Each key therefore runs through the assembly along Y.
//
// The opening centres are derived from the central John face rather than
// hard-coded:
//
//   horizontal offset = half John height + half key thickness
//   vertical offset   = half John height + half key width
//
// This places the inner edge of each key directly against the central
// 55 mm John envelope and fills the four quadrant openings symmetrically.

// After rotating each key 90 degrees about its long axis,
// the 24 mm width runs horizontally and the 12 mm wood thickness
// runs vertically in the user's inspection view.
final_key_x_offset =
    john_height / 2 + final_key_width / 2;

final_key_z_offset =
    john_height / 2 + slat_thickness / 2;


// A Final Key is originally modeled:
//   X = length
//   Y = width
//   Z = thickness
//
// Rotate it so:
//   length    -> world Y
//   width     -> world Z
//   thickness -> world X
//
// It is centered through the 115 mm inner frame depth.
// Since key length is 127 mm, it protrudes equally from both sides.

// [M7] module inserted_final_key() -> lib


// Final Keys are rendered later inside complete_turtle_scene().

// ============================================================================
// DIMENSION REPORT
// ============================================================================

echo("John length = ", john_length, " mm");
echo("John height = ", john_height, " mm");
echo("Wood thickness = ", slat_thickness, " mm");

echo("Little John slot centres = ",
     little_slot_1_x, ", ", little_slot_2_x, " mm");

echo("Long John slot centres = ",
     long_slot_1_x, ", ", long_slot_2_x, " mm");

echo("Rectangle X between slot centres = ", rectangle_x, " mm");
echo("Rectangle Y between slot centres = ", rectangle_y, " mm");
echo("Shared frame centre = ", frame_center);
echo("Frame step tilt = ", frame_step_tilt, " deg");
echo("Frame step spin = ", frame_step_spin, " deg");
echo("Rectangle count = 3");
echo("Final Key count = 4");
echo("Little John count across 3 rectangles = 6");
echo("Presser count before port exclusions = 12; active pressers carry M6 bolts");
echo("Presser diameter = ", presser_diameter, " mm");
echo("Presser thickness = ", slat_thickness, " mm");
echo("Presser through-hole diameter = ",
     presser_through_hole_diameter, " mm");
echo("Final Key length = ", final_key_length, " mm");
echo("Final Key width = ", final_key_width, " mm");
echo("Final Key thickness = ", slat_thickness, " mm");
echo("Final Key X offset = ", final_key_x_offset, " mm");
echo("Final Key Z offset = ", final_key_z_offset, " mm");

echo("Long John count = 2");
echo("Little John count = 2");


// ============================================================================
// CANONICAL BOTTLES — ONE CAP-FIRST IN EACH OF SIX PORTS
// ============================================================================
//
// The Ecojoiner has six orthogonal ports:
//   +X, -X, +Y, -Y, +Z, -Z
//
// Each bottle is inserted cap-first toward the shared Ecojoiner centre.
// All six bottle axes pass through frame_center.
//
// `bottle_insertion` is measured inward from the OUTERMOST John surface.
// Base insertion is cap_height. The additional bottle_inward_shift below
// also moves the collar/body inward; total insertion is 99 mm at defaults.

// Base cap engagement, before applying the separate inward shift.
bottle_insertion = cap_height;


// Central reference point of the Ecojoiner.
assembly_center = frame_center;


// Distance from the Ecojoiner centre to the OUTERMOST John face
// along the bottle-port axis.
//
// IMPORTANT:
// `john_height / 2` is only the half-width of a John and is NOT the
// axial outer face of the port.  The outermost face is one half of the
// full John length from the assembly centre.
port_outer_offset =
    john_length / 2;


// Bottle origin distance from the Ecojoiner centre.
//
// The bottle's local cap top is at local Z = bottle_height.
// After rotation, the bottle origin must sit this far outside the port so
// the cap top ends up bottle_insertion + bottle_inward_shift inside the face.
// Move every bottle INWARD by exactly one shared port height from the
// corrected outer-face datum.
bottle_inward_shift =
    port_height;

bottle_origin_offset =
    port_outer_offset
    + bottle_height
    - bottle_insertion
    - bottle_inward_shift;


// For the +Y ballast bottle:
//   outermost John face = assembly_center[1] + port_outer_offset
//   cap tip/top         = bottle origin Y - bottle_height
//
// Total cap-tip insertion includes both cap_height and bottle_inward_shift.
ballast_bottle_outer_john_y =
    assembly_center[1] + port_outer_offset;

ballast_bottle_origin_y =
    assembly_center[1] + bottle_origin_offset;

ballast_bottle_cap_top_y =
    ballast_bottle_origin_y - bottle_height;

ballast_bottle_actual_insertion =
    ballast_bottle_outer_john_y - ballast_bottle_cap_top_y;

// Requested adjustment: shift bottle inward by exactly one port_height.
assert(
    abs(
        ballast_bottle_actual_insertion
        - (cap_height + port_height)
    ) < 0.001,
    "Ballast bottle must be shifted inward by exactly one port_height."
);


assert(
    abs(bottle_insertion - cap_height) < 0.001,
    "Bottle insertion must equal cap_height exactly."
);


// ============================================================================
// BOTTLE PLACEMENT HELPER
// ============================================================================

module bottle_at_port(direction = "+Y") {

    if (direction == "+Y") {
        translate([
            assembly_center[0],
            assembly_center[1] + bottle_origin_offset,
            assembly_center[2]
        ])
            rotate([90, 0, 0])
                parametric_bottle();
    }

    else if (direction == "-Y") {
        translate([
            assembly_center[0],
            assembly_center[1] - bottle_origin_offset,
            assembly_center[2]
        ])
            rotate([-90, 0, 0])
                parametric_bottle();
    }

    else if (direction == "+X") {
        translate([
            assembly_center[0] + bottle_origin_offset,
            assembly_center[1],
            assembly_center[2]
        ])
            rotate([0, -90, 0])
                parametric_bottle();
    }

    else if (direction == "-X") {
        translate([
            assembly_center[0] - bottle_origin_offset,
            assembly_center[1],
            assembly_center[2]
        ])
            rotate([0, 90, 0])
                parametric_bottle();
    }

    else if (direction == "+Z") {
        translate([
            assembly_center[0],
            assembly_center[1],
            assembly_center[2] + bottle_origin_offset
        ])
            rotate([180, 0, 0])
                parametric_bottle();
    }

    else if (direction == "-Z") {
        translate([
            assembly_center[0],
            assembly_center[1],
            assembly_center[2] - bottle_origin_offset
        ])
            parametric_bottle();
    }
}


// ============================================================================
// SIX-BOTTLE ASSEMBLY
// ============================================================================

// Bottles are rendered later inside complete_turtle_scene().


echo("Ordinary Ecojoiner bottles shown = 5");
echo("Integrated sail-apparatus bottles shown = 1");
echo("Total Hope Turtle bottle count = 6");
echo("Bottle insertion depth = cap_height = ",
     bottle_insertion, " mm");
echo("Bottle collar height (whole bottle shifted inward) = ",
     collar_height, " mm");
echo("Bottle origin offset from centre = ",
     bottle_origin_offset, " mm");

echo("Ballast bottle outermost John face Y = ",
     ballast_bottle_outer_john_y, " mm");
echo("Ballast bottle cap top Y = ",
     ballast_bottle_cap_top_y, " mm");
echo("Bottle inward shift = one port_height = ",
     bottle_inward_shift, " mm");
echo("Verified ballast bottle insertion relative to outer face = ",
     ballast_bottle_actual_insertion, " mm");


// ============================================================================
// BALLAST ASSEMBLY — FITTED AROUND THE +Y BOTTLE
// ============================================================================
//
// Adapted from the canonical Turtle bottom-ballast assembly.
// This copy uses the CURRENT Ecojoiner + canonical bottle dimensions:
//
//   wood thickness  = slat_thickness
//   bottle diameter = bottle_diameter
//   bottle height   = bottle_height
//   cap dimensions  = canonical bottle values
//
// The ballast is rotated so its two long green slats run along the +Y bottle.
// The two +Y-port Pressers have been removed above to clear these slats.

ballast_fin_board_width = fin_board_width;

// Explicit aliases for auditability: ballast uses the SAME bottle values.
ballast_bottle_diameter =
    bottle_diameter;

ballast_bottle_height =
    bottle_height;


// --------------------------------------------------------------------------
// GREEN CORE SLATS
// --------------------------------------------------------------------------

ballast_core_width =
    ballast_bottle_diameter - 2 * slat_thickness;

assert(ballast_core_width == port_height - 2 * slat_thickness,
       "Ballast slat width must use the same bottle diameter as the Ecojoiner.");

// Green ballast-slat height.
//
// Base relationship was:
//   bottle_height - cap_height + 4.5 * slat_thickness
//
// Increase by another 1.5 * slat_thickness:
//
ballast_core_height =
    bottle_height
    - cap_height
    + 6.0 * slat_thickness;

assert(
    abs(
        ballast_core_height
        - (bottle_height - cap_height + 6.0 * slat_thickness)
    ) < 0.001,
    "Ballast green-slat height must follow the expanded canonical formula."
);

ballast_lower_lobe_height =
    2 * slat_thickness;

ballast_upper_lobe_height =
    2 * slat_thickness;

ballast_core_slot_height =
    slat_thickness;

ballast_core_slot_depth =
    ballast_core_width / 2;

ballast_neck_width =
    ballast_bottle_diameter - 3 * slat_thickness;

ballast_shoulder_step =
    ballast_core_width - ballast_neck_width;

// Top shoulder geometry.
//
// The 45-degree cut STARTS on the outer edge exactly one shared port_height
// below the top of the green slat.
ballast_upper_diagonal_start =
    ballast_core_height - port_height;

// Because this is a 45-degree cut, moving inward by ballast_shoulder_step
// also moves downward by the same amount.
ballast_upper_neck_start =
    ballast_upper_diagonal_start - ballast_shoulder_step;

assert(
    abs(
        (ballast_core_height - ballast_upper_diagonal_start)
        - port_height
    ) < 0.001,
    "Top ballast shoulder cut must begin exactly one port_height below the slat top."
);

ballast_core_slot_z0 =
    ballast_lower_lobe_height;

ballast_core_slot_z1 =
    ballast_core_slot_z0 + ballast_core_slot_height;

ballast_lower_full_return =
    ballast_core_slot_z1 + ballast_upper_lobe_height;

ballast_lower_neck_start =
    ballast_lower_full_return + ballast_shoulder_step;


// M6 mounting hole.
//
// The adjacent Little John hole is `screw_side_offset` from the OUTER end
// of the John. The seated ballast-slat top is farther inward by:
//
//     slat_thickness + port_length
//
// Therefore the ballast hole must sit this far DOWN from the slat top.
//
ballast_core_mount_hole_diameter =
    screw_diameter;

ballast_core_mount_hole_from_top =
    port_length
    + slat_thickness
    - screw_side_offset;

ballast_core_mount_hole_x =
    ballast_core_width / 2;

ballast_core_mount_hole_y =
    ballast_core_height
    - ballast_core_mount_hole_from_top;


// --------------------------------------------------------------------------
// ORANGE BOTTOM BOARD
// --------------------------------------------------------------------------

ballast_board_length =
    3.5 * ballast_bottle_diameter;

ballast_board_width =
    ballast_fin_board_width;

ballast_board_slot_width =
    slat_thickness;

ballast_board_slot_depth =
    ballast_fin_board_width / 3;

ballast_center_slot_depth =
    ballast_bottle_diameter / 2;

ballast_center_slot =
    ballast_board_length / 2;

// The two green ballast slats must CLEAR the bottle, not have their
// centre-lines separated by the bottle diameter.
//
// Each slat is slat_thickness wide in the radial direction. Therefore:
//
//   clear gap between inner slat faces = bottle_diameter
//
// requires:
//
//   slat centre-to-centre spacing = bottle_diameter + slat_thickness
//
ballast_slat_center_spacing =
    ballast_bottle_diameter + slat_thickness;

ballast_left_slot =
    ballast_center_slot - ballast_slat_center_spacing / 2;

ballast_right_slot =
    ballast_center_slot + ballast_slat_center_spacing / 2;


ballast_bottle_clear_gap =
    ballast_slat_center_spacing - slat_thickness;

assert(abs(ballast_bottle_clear_gap - ballast_bottle_diameter) < 0.001,
       "Ballast slat inner-face gap must equal shared bottle_diameter.");

assert(abs(port_height - bottle_diameter) < 0.001,
       "Ecojoiner port_height must equal canonical bottle_diameter.");

assert(abs(ecojoiner_bottle_height - bottle_height) < 0.001,
       "Ecojoiner bottle-height reference must equal canonical bottle_height.");

assert(abs(ballast_bottle_diameter - bottle_diameter) < 0.001,
       "Ballast bottle diameter must equal canonical bottle_diameter.");

assert(abs(ballast_bottle_height - bottle_height) < 0.001,
       "Ballast bottle height must equal canonical bottle_height.");

ballast_end_slot_offset =
    2 * slat_thickness;

ballast_left_end_slot_x0 =
    ballast_end_slot_offset;

ballast_right_end_slot_x0 =
    ballast_board_length
    - ballast_end_slot_offset
    - ballast_board_slot_width;


// --------------------------------------------------------------------------
// RED LOCK FEET
// --------------------------------------------------------------------------

ballast_lock_width =
    5 * slat_thickness;

ballast_lock_height =
    5 * slat_thickness;

ballast_lock_thickness =
    slat_thickness;

ballast_lock_slot_depth =
    ballast_lock_width / 2;

ballast_lock_slot_height =
    slat_thickness;

ballast_lock_chamfer =
    1.5 * slat_thickness;


// --------------------------------------------------------------------------
// YELLOW BALLAST FIN
// --------------------------------------------------------------------------

ballast_fin_length =
    3 * ballast_bottle_diameter;

ballast_fin_height =
    ballast_fin_board_width;

ballast_fin_thickness =
    slat_thickness;

ballast_fin_lower_protrusion =
    2 * slat_thickness;

ballast_fin_slot_height =
    slat_thickness;

ballast_fin_slot_depth =
    ballast_bottle_diameter / 2;


assert(
    abs(ballast_center_slot_depth - ballast_fin_slot_depth) < 0.001,
    "Orange-base and yellow-fin slots must have equal depth."
);

// Bottle-seat clearance in the yellow ballast fin.
//
// Remove one additional board thickness of yellow material so the bottle
// clears the fin instead of intersecting it.
ballast_fin_bottle_clearance_extra =
    slat_thickness;

ballast_fin_upper_cut_depth =
    ballast_bottle_diameter
    + ballast_fin_bottle_clearance_extra;

ballast_fin_upper_cut_z0 =
    ballast_fin_lower_protrusion
    + ballast_fin_slot_height
    + 1.5 * slat_thickness;

ballast_fin_front_chamfer =
    1.5 * slat_thickness;


// ============================================================================
// BALLAST PART MODULES
// ============================================================================

// [M7] module ballast_core_profile_2d() -> lib


// [M7] module ballast_core_slat_part() -> lib


// [M7] module ballast_bottom_board_part() -> lib


// [M7] module ballast_lock_profile_2d() -> lib


// [M7] module ballast_lock_part() -> lib


// [M7] module ballast_fin_profile_2d() -> lib


// [M7] module ballast_fin_part() -> lib


// ============================================================================
// BALLAST LOCAL ASSEMBLY
// ============================================================================

// [M7] module ballast_installed_green_slat() -> lib


// [M7] module ballast_installed_lock() -> lib


// Inspection control for the yellow ballast fin.
//
// Pull the fin completely out of its mating slot in the OPPOSITE direction
// so both the FULL fin shape and the orange ballast-board slot/surface can be
// inspected independently.
//
// Set this back to 0 when we are ready to re-seat the fin.
ballast_fin_inspection_pullout = 0;

// [M7] module ballast_installed_fin() -> lib


// [M7] module local_ballast_assembly() -> lib


// ============================================================================
// POSITION BALLAST AROUND THE +Y BOTTLE
// ============================================================================
//
// Local ballast Z is its long green-slat direction.
// rotate([90,0,0]) maps:
//
//   ballast X -> world X
//   ballast Y -> world Z
//   ballast Z -> world -Y
//
// This makes the two green slats run parallel to the protruding +Y bottle.
//
// The assembly is centered around the bottle axis in X and Z.
//
// First-pass axial fit:
// The FULL-WIDTH upper ends of the green slats abut the +Y ends of the two
// Johns that form this bottle port. Those John ends lie one half John-length
// from the shared center.

positive_y_john_end =
    assembly_center[1] + john_length / 2;

// The true port entrance is the INNER face of the outer John.
// The outer face is `positive_y_john_end`; move inward by exactly one
// shared board thickness.
ballast_port_entrance_y =
    positive_y_john_end - slat_thickness;

// The opposite yellow John face is one PORT LENGTH farther in.
//
// Important naming distinction:
//   port_height = shared bottle / opening diameter
//   port_length = axial depth of the Ecojoiner port = 82 mm
//
// This 2 mm distinction is exactly the small gap seen in v22.
ballast_target_john_face_y =
    ballast_port_entrance_y - port_length;


// Exact M6 alignment datum.
// The John hole is measured from its outer end.
// The ballast hole is measured downward from its fully seated top.
john_m6_hole_y =
    positive_y_john_end - screw_side_offset;

ballast_m6_hole_after_insertion_y =
    ballast_target_john_face_y
    + ballast_core_mount_hole_from_top;

assert(
    abs(ballast_m6_hole_after_insertion_y - john_m6_hole_y) < 0.001,
    "Ballast M6 hole must be coaxial with adjacent John M6 hole."
);

ballast_x_shift =
    assembly_center[0] - ballast_center_slot;

ballast_z_shift =
    assembly_center[2] - ballast_core_width / 2;

// Because rotated local +Z points toward world -Y:
// worldY = ballast_y_shift - localZ
//
// Align the ACTUAL top of each green ballast slat with the PORT ENTRANCE
// plane before insertion. This is the key datum correction that eliminates
// the extra-board-thickness fudge factor.
ballast_y_shift =
    ballast_port_entrance_y
    + ballast_core_height
    - ballast_core_slot_z0;


// Spin the ballast 90 degrees around the +Y bottle / port axis.
// In ballast-local coordinates that axis is local Z and passes through
// [ballast_center_slot, ballast_core_width/2].
ballast_port_spin = 90;

module installed_ballast_on_positive_y_port() {

    translate([
        ballast_x_shift,
        ballast_y_shift,
        ballast_z_shift
    ])
        rotate([90, 0, 0])
            translate([
                ballast_center_slot,
                ballast_core_width / 2,
                0
            ])
                rotate([0, 0, ballast_port_spin])
                    translate([
                        -ballast_center_slot,
                        -ballast_core_width / 2,
                        0
                    ])
                        local_ballast_assembly(ballast_fin_inspection_pullout,
                                               enable_color_coding);
}


// Ballast is rendered later inside complete_turtle_scene().


echo("Ballast added around +Y bottle");
echo("Ballast spin around bottle/port axis = ", ballast_port_spin, " deg");
echo("Removed Pressers on +Y port = 2");
echo("Ballast wood thickness = ", slat_thickness, " mm");
echo("Ballast shared port_height basis = ", port_height, " mm");
echo("Ballast green slat centre spacing = ",
     ballast_slat_center_spacing, " mm");
echo("Ballast clear gap between green slats = ",
     ballast_bottle_clear_gap, " mm");
echo("Unified bottle diameter check: bottle / Ecojoiner / ballast = ",
     bottle_diameter, " / ", port_height, " / ",
     ballast_core_width + 2 * slat_thickness, " mm");
echo("Ballast green slat height = ", ballast_core_height, " mm");
echo("Ballast +Y John abutment = ", positive_y_john_end, " mm");
echo("Ballast moved inward by = ",
     ballast_core_slot_z0, " mm");
echo("Ballast green mount-hole diameter = ",
     ballast_core_mount_hole_diameter, " mm");
echo("Ballast M6 hole from slat top = ",
     ballast_core_mount_hole_from_top, " mm");
echo("John M6 hole Y = ",
     john_m6_hole_y, " mm");
echo("Ballast M6 hole after insertion Y = ",
     ballast_m6_hole_after_insertion_y, " mm");




// ============================================================================
// REAR FIN APPARATUS — ADAPTED FROM THE USER'S FINAL REAR-FIN SCAD
// ============================================================================
//
// MASTER-VARIABLE RULE:
// This apparatus does NOT define its own bottle dimensions or wood thickness.
// It uses the same canonical values as the Ecojoiner + ballast:
//
//   bottle_diameter
//   bottle_height
//   cap_diameter
//   cap_height
//   slat_thickness
//
// It also shares fin_board_width with the ballast fin system.

// Rear-fin aliases are intentionally explicit for easy auditing.
rear_wood_thickness  = slat_thickness;
rear_bottle_height   = bottle_height;
rear_bottle_diameter = bottle_diameter;
rear_cap_diameter    = cap_diameter;
rear_cap_height      = cap_height;

rear_boolean_epsilon = 0.02; // Boolean overlap only, separate from fit clearance

// The rear green-slat hole must follow the mating John, not a fixed offset.
// All coordinates here are before the final turtle orientation.
rear_mount_hole_pre_x =
    assembly_center[0] + john_length / 2 - screw_side_offset;


// --------------------------------------------------------------------------
// DERIVED REAR-FIN DIMENSIONS
// --------------------------------------------------------------------------

rear_joint_slot_thickness =
    rear_wood_thickness;

rear_shaft_length =
    rear_bottle_height
    + (2/3 * (fin_board_width - 2 * rear_wood_thickness))
    - rear_cap_height;

rear_shaft_width =
    59;

rear_shaft_thickness =
    rear_wood_thickness;

rear_shaft_hole_diameter =
    screw_diameter;

// Clear gap between the two complete green shafts.
rear_shaft_gap =
    rear_bottle_diameter;


// --------------------------------------------------------------------------
// YELLOW REAR FIN
// --------------------------------------------------------------------------

rear_fin_tab_width =
    15;

rear_fin_width =
    fin_board_width + rear_fin_tab_width;

rear_fin_height =
    3 * rear_bottle_diameter;

rear_fin_thickness =
    rear_wood_thickness;

rear_fin_diagonal_rise =
    (2/3) * rear_bottle_diameter;

rear_fin_diagonal_run =
    rear_fin_diagonal_rise;

rear_fin_bottom_flat =
    rear_fin_width - rear_fin_diagonal_run;


// --------------------------------------------------------------------------
// RED SOLAR-PANEL HOLDER
// --------------------------------------------------------------------------

rear_solar_holder_length =
    solar_panel_width;

rear_solar_holder_height =
    3 * rear_wood_thickness;

rear_solar_holder_thickness =
    rear_wood_thickness;

rear_red_yellow_slot_depth =
    1.5 * rear_wood_thickness;

rear_solar_holder_notch_depth =
    rear_red_yellow_slot_depth;

rear_solar_holder_bottom_chamfer =
    1.5 * rear_wood_thickness;

rear_solar_holder_notch_width =
    rear_fin_thickness + rear_solar_slot_clearance;


// --------------------------------------------------------------------------
// SHAFT + HOLDER POSITIONS
// --------------------------------------------------------------------------

rear_upper_green_top_offset =
    2 * rear_wood_thickness;

rear_upper_shaft_z1 =
    rear_fin_height - rear_upper_green_top_offset;

rear_upper_shaft_z0 =
    rear_upper_shaft_z1 - rear_shaft_thickness;

rear_lower_shaft_z1 =
    rear_upper_shaft_z0 - rear_shaft_gap;

rear_lower_shaft_z0 =
    rear_lower_shaft_z1 - rear_shaft_thickness;

rear_fin_upper_joint_z0 =
    rear_upper_shaft_z0;

rear_fin_lower_joint_z0 =
    rear_lower_shaft_z0;

rear_fin_solar_notch_width =
    rear_solar_holder_thickness;

rear_fin_solar_notch_depth =
    rear_red_yellow_slot_depth;

rear_fin_solar_right_inset =
    rear_wood_thickness;

rear_fin_solar_notch_x0 =
    rear_fin_width
    - rear_fin_solar_right_inset
    - rear_fin_solar_notch_width;

rear_shaft_rear_x =
    rear_fin_solar_notch_x0;

// Actual green/yellow overlap is X=0..rear_shaft_rear_x.
// Yellow opens from the front, green from the rear, meeting halfway.
rear_joint_slot_depth = rear_shaft_rear_x / 2;
rear_joint_meet_x = rear_joint_slot_depth;

rear_green_slot_inset_x =
    rear_joint_meet_x - rear_half_lap_clearance / 2;

rear_solar_holder_x0 =
    rear_fin_solar_notch_x0;

rear_solar_holder_z0 =
    rear_upper_shaft_z0;

rear_solar_meet_z =
    rear_solar_holder_z0 + rear_solar_holder_notch_depth;

// Local +X points aft; the panel extends forward from the red crossbar.
// Its rear edge is flush with the holder's rear face, and its underside
// rests on the holder's top. Local Y remains centered across the crossbar.
rear_panel_corner_radius = 5;
rear_panel_x0 = rear_solar_holder_x0 + rear_solar_holder_thickness
                - solar_panel_height;
rear_panel_y0 = -solar_panel_width / 2;
rear_panel_mount_z = rear_fin_height;

// Visual M3 fasteners at the two holder-side panel corners.
// Center over the wooden crossbar; keep heads clear of rounded edges.
rear_panel_m3_side_inset = 8;
rear_panel_m3_x = rear_solar_holder_x0 + rear_solar_holder_thickness / 2;
rear_panel_m3_y = solar_panel_width / 2 - rear_panel_m3_side_inset;
rear_panel_m3_shaft_diameter = 3;
rear_panel_m3_head_diameter = 6;
rear_panel_m3_head_height = 2;
rear_panel_m3_embed_depth = 10;


// --------------------------------------------------------------------------
// REAR-FIN SANITY CHECKS
// --------------------------------------------------------------------------

assert(rear_shaft_length > fin_board_width,
       "Rear-fin shaft_length must exceed fin_board_width.");

assert(rear_lower_shaft_z0 - rear_half_lap_clearance / 2
       >= rear_fin_diagonal_rise,
       "Rear-fin lower shaft intersects the lower 45-degree cut.");

assert(fin_board_width > 2 * rear_wood_thickness,
       "fin_board_width must exceed twice the shared wood thickness.");

assert(rear_joint_slot_depth > 0,
       "Rear-fin joint slot depth must be positive.");

assert(rear_half_lap_clearance >= 0 && rear_solar_slot_clearance >= 0
       && rear_half_lap_clearance < rear_wood_thickness
       && rear_half_lap_clearance < rear_bottle_diameter
       && rear_solar_slot_clearance < rear_wood_thickness,
       "Rear-fin clearances must be nonnegative and smaller than the stock/gap.");
assert(rear_joint_slot_depth > rear_half_lap_clearance / 2
       && rear_shaft_width > rear_joint_slot_thickness + rear_half_lap_clearance
       && rear_shaft_rear_x - rear_shaft_length < 0,
       "Rear green/yellow joint leaves insufficient wood.");
assert(rear_fin_bottom_flat > 0
       && rear_fin_solar_notch_x0 > rear_solar_slot_clearance / 2
       && rear_fin_solar_right_inset > rear_solar_slot_clearance / 2,
       "Rear fin must retain wood beside its diagonal and solar slot.");
assert(2 * rear_solar_holder_bottom_chamfer + rear_solar_holder_notch_width
       < rear_solar_holder_length,
       "Solar holder is too narrow for the slot and corner chamfers.");

assert(abs(rear_shaft_gap - bottle_diameter) < 0.001,
       "Rear-fin shaft gap must equal canonical bottle_diameter.");

assert(abs(rear_shaft_thickness - slat_thickness) < 0.001,
       "Rear-fin green shafts must use shared slat_thickness.");

assert(abs(rear_fin_thickness - slat_thickness) < 0.001,
       "Rear fin must use shared slat_thickness.");

assert(abs(rear_solar_holder_thickness - slat_thickness) < 0.001,
       "Rear solar holder must use shared slat_thickness.");

assert(solar_panel_width > 2 * rear_panel_corner_radius
       && solar_panel_height > 2 * rear_panel_corner_radius
       && solar_panel_thickness > 0,
       "Solar panel dimensions must accommodate its 5 mm corner radius.");
assert(abs(rear_solar_holder_z0 + rear_solar_holder_height
           - rear_panel_mount_z) < 0.001,
       "The red crossbar and yellow fin must support the panel in one plane.");
assert(rear_solar_holder_thickness > rear_panel_m3_head_diameter
       && rear_panel_m3_side_inset >= rear_panel_corner_radius
                                       + rear_panel_m3_head_diameter / 2
       && rear_panel_m3_y > rear_panel_m3_head_diameter / 2
       && rear_panel_m3_embed_depth < rear_solar_holder_height
                                    - rear_solar_holder_bottom_chamfer,
       "Solar M3 placeholders must fit on the panel and within solid holder wood.");


// ============================================================================
// REAR-FIN PART MODULES
// ============================================================================

// [M7] module rear_fin_part() -> lib/rear_fin.scad


// [M7] module rear_bottle_holder_shaft() -> lib/rear_fin.scad


// [M7] module rear_solar_panel_holder() -> lib/rear_fin.scad


module rear_solar_panel() {
    // Opaque dark-grey panel, with rounded plan-view corners and a flat base.
    // It follows the rear-fin installation transform, not the rotating sails.
    color([0.20, 0.22, 0.24])
        translate([rear_panel_x0, rear_panel_y0, rear_panel_mount_z])
            linear_extrude(height = solar_panel_thickness)
                hull() {
                    for (x = [rear_panel_corner_radius,
                              solar_panel_height - rear_panel_corner_radius])
                        for (y = [rear_panel_corner_radius,
                                  solar_panel_width - rear_panel_corner_radius])
                            translate([x, y])
                                circle(r = rear_panel_corner_radius, $fn = 48);
                }
}

module rear_solar_panel_screws() {
    // Head undersides sit on the panel. Shanks extend through its thickness
    // and 10 mm into the wood. Visual placeholders: no threads or drilled cuts.
    color([0, 0, 0])
        for (side = [-1, 1])
            translate([rear_panel_m3_x, side * rear_panel_m3_y,
                       rear_panel_mount_z + solar_panel_thickness])
                union() {
                    cylinder(d = rear_panel_m3_head_diameter,
                             h = rear_panel_m3_head_height, $fn = 48);
                    translate([0, 0, -solar_panel_thickness - rear_panel_m3_embed_depth])
                        cylinder(d = rear_panel_m3_shaft_diameter,
                                 h = solar_panel_thickness + rear_panel_m3_embed_depth,
                                 $fn = 32);
                }
}

// Wooden parts from lib/rear_fin.scad; the visible solar panel + M3 screws
// stay local (lib/rear_fin.scad only carries a %-reference panel).
module full_rear_fin_assembly() {
    rear_fin(half_lap = rear_half_lap_clearance,
             solar_clear = rear_solar_slot_clearance,
             colored = enable_color_coding);
    bottle_holder_shaft(rear_upper_shaft_z0, half_lap = rear_half_lap_clearance,
                        colored = enable_color_coding);
    bottle_holder_shaft(rear_lower_shaft_z0, half_lap = rear_half_lap_clearance,
                        colored = enable_color_coding);
    solar_panel_holder(solar_clear = rear_solar_slot_clearance,
                       colored = enable_color_coding);
    rear_solar_panel();
    rear_solar_panel_screws();
}


// ============================================================================
// POSITION REAR FIN ON THE PHYSICAL 3-O'CLOCK / BACK PORT
// ============================================================================
//
// Final turtle orientation is rotate([-90,0,0]).
//
// Clock-face mapping in the current view:
//   pre -X -> physical 9 o'clock
//   pre +X -> physical 3 o'clock
//   pre -Y -> physical 12 o'clock
//   pre +Y -> physical 6 o'clock / ballast
//
// The rear-fin assembly now belongs on the pre +X bottle.
//
// We still want the yellow rear fin to point physically DOWN.
// Use this right-handed axis mapping:
//
//   rear local +X -> pre +X -> physical 3 o'clock / outward
//   rear local +Y -> pre -Z
//   rear local +Z -> pre +Y -> physical DOWN
//
// The source rear-fin virtual bottle ends at local X = rear_shaft_rear_x.
// Align that point with the ACTUAL base of the +X bottle.

rear_target_bottle_base_pre_x =
    assembly_center[0]
    + bottle_origin_offset;

// Centre of the virtual bottle between the two green rear-fin shafts.
rear_local_bottle_axis_z =
    rear_lower_shaft_z1
    + rear_shaft_gap / 2;

// Solve translation so:
//   transformed [rear_shaft_rear_x, 0, rear_local_bottle_axis_z]
//   = actual +X bottle base centre.
rear_install_pre_x =
    rear_target_bottle_base_pre_x
    - rear_shaft_rear_x;

rear_install_pre_y =
    assembly_center[1]
    - rear_local_bottle_axis_z;

rear_install_pre_z =
    assembly_center[2];

// Evaluate only after the shaft geometry and installation offset are defined.
// Same alignment formula as v6; the corrected declaration order avoids undef.
rear_shaft_hole_from_front =
    rear_mount_hole_pre_x
    - (rear_install_pre_x + rear_shaft_rear_x - rear_shaft_length);

assert(rear_shaft_hole_from_front > rear_shaft_hole_diameter / 2
       && rear_shaft_hole_from_front
          < rear_shaft_length - rear_shaft_hole_diameter / 2,
       "Rear-fin mounting hole must remain within the green slat.");
assert(abs(rear_install_pre_x + rear_shaft_rear_x - rear_shaft_length
           + rear_shaft_hole_from_front - rear_mount_hole_pre_x) < 0.001,
       "Rear-fin and John mounting-hole axes must coincide.");
assert(rear_shaft_rear_x - rear_shaft_length + rear_shaft_hole_from_front
       + rear_shaft_hole_diameter / 2 < 0,
       "Rear mounting hole must stay forward of the green/yellow joint.");

// Independent cross-check (Y axis): the assert above only checks X (the
// hole's distance along the shaft, "hole_from_front") against a value that
// is DEFINED FROM the same terms it is compared to, so it can never fail --
// it does not prove the shaft is actually flush against the John it bolts
// to. This block checks the other axis, the boards' stacking direction,
// against an independently-derived source: the target Little John's own
// board extent from lib/ecojoiner.scad (eco_slat_t(), eco_rectangle_y()),
// versus each shaft's own board Z-extent pushed through the real install
// transform. ecojoiner_and_bottles() suppresses exactly these two Little
// John holes -- "the two Pressers on the physical 3-o'clock port ... for
// the rear-fin green shafts" -- so these are the correct targets.
//
// Each shaft's board occupies local Z in [z0, z0+t]; the installed
// transform maps local Z to world Y via world_y = 2*rear_local_bottle_axis_z
// + rear_install_pre_y - local_z (see installed_rear_fin_on_3oclock_port()),
// so the board's world-Y span runs from that value at local Z = z0+t (the
// "near", touching edge) to the same value at local Z = z0 (the "far" edge).
// Which edge is the touching one flips between the two shafts because they
// mate to Little Johns on opposite sides of the rectangle (opposite
// inside_sign in eco_standing_little_john) -- so this checks both edges
// rather than assuming one.
rear_upper_shaft_hole_y_far  =
    2 * rear_local_bottle_axis_z + rear_install_pre_y - rear_upper_shaft_z0;
rear_upper_shaft_hole_y_near =
    rear_upper_shaft_hole_y_far - rear_shaft_thickness;
rear_lower_shaft_hole_y_far  =
    2 * rear_local_bottle_axis_z + rear_install_pre_y - rear_lower_shaft_z0;
rear_lower_shaft_hole_y_near =
    rear_lower_shaft_hole_y_far - rear_shaft_thickness;

rear_john_target_a_y = 0 + eco_slat_t() / 2;                  // target_y=0 Little John's inner face
rear_john_target_b_y = eco_rectangle_y() - eco_slat_t() / 2;  // target_y=eco_rectangle_y() Little John's inner face

assert(
    abs(rear_upper_shaft_hole_y_near - rear_john_target_a_y) < 0.001 ||
    abs(rear_upper_shaft_hole_y_far  - rear_john_target_a_y) < 0.001,
    "Rear-fin upper shaft board must sit flush against its Little John hole (Y axis)."
);
assert(
    abs(rear_lower_shaft_hole_y_near - rear_john_target_b_y) < 0.001 ||
    abs(rear_lower_shaft_hole_y_far  - rear_john_target_b_y) < 0.001,
    "Rear-fin lower shaft board must sit flush against its Little John hole (Y axis)."
);


module installed_rear_fin_on_3oclock_port() {

    multmatrix([
        [1,  0, 0, rear_install_pre_x],
        [0,  0, 1, rear_install_pre_y],
        [0, -1, 0, rear_install_pre_z],
        [0,  0, 0, 1]
    ])
        // Flip the complete rear-fin apparatus 180 degrees around the
        // 3-o'clock bottle / shaft axis (rear-fin local X axis).
        //
        // Rotate about the bottle-axis datum used to position the assembly,
        // so the port and axial placement stay unchanged.
        translate([
            rear_shaft_rear_x,
            0,
            rear_local_bottle_axis_z
        ])
            rotate([180, 0, 0])
                translate([
                    -rear_shaft_rear_x,
                    0,
                    -rear_local_bottle_axis_z
                ])
                    full_rear_fin_assembly();
}


// --------------------------------------------------------------------------
// Rear-fin diagnostics
// --------------------------------------------------------------------------

echo("Rear shaft length = ", rear_shaft_length, " mm");
echo("Rear green/yellow nominal slot depth = ", rear_joint_slot_depth, " mm");
echo("Rear green/yellow slot width = ",
     rear_joint_slot_thickness + rear_half_lap_clearance, " mm");
echo("Rear solar slot width / total clearance = ",
     rear_solar_holder_notch_width, rear_solar_slot_clearance, " mm");
echo("Rear panel width / height / thickness = ",
     solar_panel_width, solar_panel_height, solar_panel_thickness, " mm");

echo("Rear fin uses shared wood thickness = ",
     rear_wood_thickness, " mm");

echo("Rear fin uses shared bottle diameter = ",
     rear_bottle_diameter, " mm");

echo("Rear fin uses shared bottle height = ",
     rear_bottle_height, " mm");

echo("Rear fin target = physical 3-o’clock / back port (pre +X)");
echo("Rear fin source port = pre-orientation +X bottle");
echo("Rear fin rotated 180 deg around 3-o’clock bottle axis; yellow fin points DOWN");


// ============================================================================
// SELF-CONTAINED TOP SAIL APPARATUS
// ============================================================================
// The module is embedded below: no include, companion file, or global aliases.
// Every shared dimension is passed explicitly from the canonical turtle values.

// BEGIN SELF-CONTAINED SAIL MODULE — fixed body / rotating cage split
// Explicit parameters isolate all sail dimensions and helper modules.
// Full-assembly datum: blue-cap tip = [0,0,0]; bottle points upward (+Z).
module hope_turtle_sail_apparatus(
    bottle_diameter = 82,
    bottle_height = 305,
    cap_diameter = 31,
    cap_height = 17,
    collar_diameter = 34,
    top_dome_height = 62,
    bottom_dome_height = 25,
    board_width = 12,
    batten_cage_m6_hole_diameter = 6.4,
    cage_mount_hole_diameter = 3.2,
    cage_wave_segments = 240,
    cage_valley_wall_height = 10,
    cage_peak_extension = 20,
    cage_lower_hole_from_tip = 10,
    cage_button_angle = 0,
    side_batten_height = 205,
    cage_vertical_position = 0,
    cage_rotation_angle = 0,
    sail_frame_rotation_angle = 90,
    cage_exploded_view = 0,
    bottle_dome_power = 2.5,
    bottle_neck_height = 5,
    bottle_collar_height = 1,
    bottle_bottom_base_ratio = 0.88,
    bottle_profile_steps = 16,
    curve_segments = 180,
    part = "full_assembly"
) {
    $fn = curve_segments;
    cage_epsilon = 0.02;
    m6_bolt_shaft_diameter = 6;
    m6_bolt_head_diameter = 12;
    m6_bolt_head_thickness = 4;
    // Assembly alignment, independent of the user-controlled rotor angle.
    cage_mount_alignment_angle = 90;

    assert(curve_segments >= 12, "Use at least 12 curve segments.");
    assert(board_width > 0, "Board thickness must be positive.");
    if (part == "full_assembly") {
        echo("SAIL: fixed control bottle and independently rotating cage/sails");
        echo("SAIL shared bottle / wood dimensions = ", bottle_diameter, board_width);
    }

    // Integration controls
    bottle_cut_extra_height = 5;
    bottle_wall_thickness = 0.5;
    insert_shaft_radial_clearance = 1.0;

    bottle_cut_height =
        bottom_dome_height + bottle_cut_extra_height;

    bottle_socket_diameter =
        bottle_diameter - 2 * bottle_wall_thickness;

    // ============================================================
    // TOP SAIL BAR
    // ============================================================
    top_sail_bar_length = 6 * bottle_diameter;
    top_sail_bar_width = 22;
    top_sail_bar_thickness = board_width;

    top_sail_bar_slot_depth = 11;
    top_sail_bar_slot_width = 10;
    // TB-08: round shaft + running clearance (was Ø12 for the hex corners).
    top_sail_bar_axle_hole_diameter = p_sail_bar_axle_hole_d();

    // ============================================================
    // SIDE BATTENS
    // ============================================================
    side_batten_width = 20;
    side_batten_thickness = top_sail_bar_slot_width;

    // Both end slots match the board width exactly.
    side_batten_notch_height = board_width;
    side_batten_notch_depth = side_batten_width / 2;
    side_batten_end_margin = 15;

    // ============================================================
    // BOTTOM SAIL BARS
    // ============================================================
    bottom_sail_bar_length = 3 * bottle_diameter;
    bottom_sail_bar_width = top_sail_bar_width;
    bottom_sail_bar_thickness = board_width;

    bottom_sail_bar_slot_width = side_batten_thickness;
    bottom_sail_bar_slot_depth = bottom_sail_bar_width / 2;
    bottom_sail_bar_bottle_clearance = 1;

    // Compact C-shaped retainers for the perpendicular battens.
    c_end_piece_width = bottom_sail_bar_width;
    c_end_piece_thickness = board_width;
    c_end_piece_outer_extension = 15;

    // Lower sail-bar / batten joint strengtheners from the PNG.
    joint_strengthener_width = 24;
    joint_strengthener_above_bar = 24;
    joint_strengthener_below_bar = 15;
    joint_strengthener_thickness = board_width;
    joint_strengthener_slot_depth = 12;
    joint_strengthener_slot_height = bottom_sail_bar_thickness;
    joint_strengthener_height =
        joint_strengthener_above_bar
        + bottom_sail_bar_thickness
        + joint_strengthener_below_bar;

    // Front-facing M6 bolt through the centre of the solid upper section.
    joint_strengthener_m6_z_local =
        joint_strengthener_below_bar + joint_strengthener_slot_height
        + joint_strengthener_above_bar / 2;
    side_batten_strengthener_m6_z_local =
        side_batten_end_margin + bottom_sail_bar_thickness
        + joint_strengthener_above_bar / 2;

    // ============================================================
    // SAILS
    // ============================================================
    sail_thickness = 0.1;

    // ============================================================
    // MASTER REFERENCE
    // ============================================================
    cx = 0;
    cy = 0;

    // ============================================================
    // CAP TOP / CUP SHELL CONTROL
    // ============================================================
    insert_shaft_diameter =
        bottle_socket_diameter
        - 2 * insert_shaft_radial_clearance;

    // Increased by 9 mm to strengthen the inner closures of the
    // lower sail bars and C end pieces.
    insert_shaft_to_top_disk_diameter_step = 21;

    control_cap_diameter =
        insert_shaft_diameter
        + insert_shaft_to_top_disk_diameter_step;

    top_disk_od = control_cap_diameter;

    top_disk_thickness = p_cap_roof_t();   // TB-03: 5 mm (was 8.0). control_assembly_z follows.
    cup_wall_thickness = 4;   // adjustable

    // The underside of the top disk sits on the bottle cut plane.
    // Only the insert shaft crosses into the bottle.
    control_assembly_z =
        bottle_cut_height - top_disk_thickness;

    // ============================================================
    // INSERT SHAFT (OUTER SHAPE)
    // ============================================================
    insert_total_h      = 35.0;

    plug_top_od = insert_shaft_diameter;
    plug_bottom_od = plug_top_od;

    entry_chamfer_h     = 1.0;
    entry_chamfer_delta = 1.0;

    // ============================================================
    // SILICONE BAND CHANNEL SYSTEM
    // ============================================================
    //
    // Two indented circumferential channels on the OUTSIDE of the shaft.
    //
    band_channels_enable = true;
    band_count           = 1;

    band1_center_z_local = 16.0;
    band2_center_z_local = 36.0;

    band_channel_w       = 13.0;  // axial height
    band_channel_depth   = 1.1;   // radial depth inward from outer surface

    // ============================================================
    // BUTTONS
    // ============================================================
    button_upper_d      = 17.0;
    button_axis         = "y";
    hole_spacing_cc     = 24;

    button_preview_height_above_cap = 2;

    // ============================================================
    // CENTER SHAFT / SERVO TOP HOLE
    // ============================================================
    shaft_hole_d        = 8.6;

    // ============================================================
    // SAIL SHAFT (TB-08: uniform round, no hex)
    // ============================================================
    round_shaft_diameter   = 8.0;
    round_shaft_length     = 30.0;  // length inside the cap cavity
    round_shaft_extension_above_cap = 1.0;
    shaft_upper_length     = 23.0; // continues up through the cage hub + sail bar (was hex_shaft_length)

    // ============================================================
    // DERIVED
    // ============================================================
    plug_total_h = top_disk_thickness + insert_total_h;
    disk_r       = top_disk_od / 2;

    // Inner cavity diameters for cup shell
    inner_top_od_raw    = plug_top_od    - 2 * cup_wall_thickness;
    inner_bottom_od_raw = plug_bottom_od - 2 * cup_wall_thickness;

    inner_top_od        = max(1.0, inner_top_od_raw);
    inner_bottom_od     = max(1.0, inner_bottom_od_raw);

    inner_chamfer_delta = max(0, entry_chamfer_delta);
    inner_tip_od        = max(0.5, inner_bottom_od - inner_chamfer_delta);

    // ============================================================
    // HELPERS
    // ============================================================
// [M7] function clamp() -> lib/util.scad

// [M7] function taper_od_at() -> lib/control_cap.scad (cap_taper_od_at)

    // ============================================================
    // WARNINGS
    // ============================================================
    if (hole_spacing_cc + button_upper_d/2 > disk_r)
        echo("WARNING: button holes may exceed top disk.");

    if (plug_top_od < plug_bottom_od)
        echo("WARNING: plug_top_od should not be smaller than plug_bottom_od.");

    if (entry_chamfer_h > insert_total_h)
        echo("WARNING: entry_chamfer_h exceeds insert_total_h.");

    if (inner_top_od_raw <= 0)
        echo("WARNING: cup_wall_thickness too large for plug_top_od.");

    if (inner_bottom_od_raw <= 0)
        echo("WARNING: cup_wall_thickness too large for plug_bottom_od.");

    // ============================================================
    // BASE BODY
    // ============================================================
// [M7] module removed -> lib/control_cap.scad

    // ============================================================
    // OUTER SILICONE BAND CHANNEL CUTS
    // ============================================================
    //
    // These remove material only in the OUTER annular shell region.
    // They do not cut the whole shaft away.
    //
// [M7] module removed -> lib/control_cap.scad

// [M7] module removed -> lib/control_cap.scad

    // ============================================================
    // OUTER BODY
    // ============================================================
// [M7] module removed -> lib/control_cap.scad

    // ============================================================
    // CUP INTERIOR CAVITY
    // ============================================================
// [M7] module removed -> lib/control_cap.scad

    // ============================================================
    // SERVO AXLE / CENTER HOLE CUT
    // ============================================================
// [M7] module removed -> lib/control_cap.scad

    // ============================================================
    // BUTTON HOLES
    // ============================================================
// [M7] module removed -> lib/control_cap.scad

// [M7] module removed -> lib/control_cap.scad

    module button_preview_cylinders() {
        color([1.0, 0.25, 0.65])
            if (button_axis == "x") {
                button_preview_cylinder_at(cx + hole_spacing_cc, cy);
                button_preview_cylinder_at(cx - hole_spacing_cc, cy);
            } else {
                button_preview_cylinder_at(cx, cy + hole_spacing_cc);
                button_preview_cylinder_at(cx, cy - hole_spacing_cc);
            }
    }

    module button_preview_cylinder_at(x, y) {
        translate([
            x,
            y,
            -button_preview_height_above_cap
        ])
            cylinder(
                h = top_disk_thickness
                    + button_preview_height_above_cap,
                d = button_upper_d
            );
    }

    // ============================================================
    // SAIL SHAFT (TB-08: uniform round, no hex)
    // ============================================================
    //
    // Installed orientation:
    // - Ø8 mm round shaft extends 30 mm into the cup cavity
    // - shaft passes through the 8 mm cap roof
    // - shaft projects 1 mm beyond the cap's outer face
    // - same Ø8 shaft continues on up through the cage hub + sail bar,
    //   locked to the cage by a radial M3 set screw
    //
// [M7] module turtle_control_axle() -> lib/sail_shaft.scad sail_shaft()

// [M7] module printable_turtle_control_axle() -> lib/sail_shaft.scad sail_shaft()

    // ============================================================
    // CONTROL CAP
    // ============================================================
// [M7] module removed -> lib/control_cap.scad

    // ============================================================
    // TURTLE CONTROL CAGE
    // ============================================================

    cage_surface_thickness = p_cage_roof_t();   // roof underside fixed; top drops as this thins
    cage_side_wall_thickness = 6.5;

    // Preserve 1 mm radial running clearance around the top disk.
    control_cap_to_cage_diametral_clearance = 2;
    cage_inner_cavity_diameter =
        control_cap_diameter
        + control_cap_to_cage_diametral_clearance;

    cage_outer_diameter =
        cage_inner_cavity_diameter
        + 2 * cage_side_wall_thickness;

    // TB-08: plain round shaft bore through the hub (was a hex bore).
    cage_shaft_hole_diameter = p_axle_shaft_hole_d();

    cage_top_hole_diameter = 18;
    cage_top_hole_angle = cage_button_angle;

    cage_bearing_diameter = 9;
    cage_bearing_count = 8;
    cage_bearing_contact_edge_overhang = 0.25;
    cage_bearing_pcd =
        control_cap_diameter
        - cage_bearing_diameter
        + 2 * cage_bearing_contact_edge_overhang;

    cage_total_height = p_cage_total_h(); // skirt depth + roof thickness (48 at defaults)
    cage_hub_diameter = 29;
    // Recessed clip pocket around the axle: removed for prototyping
    // (lib/control_cage.scad top_pocket = false). Constants kept for the
    // day a shaft clip returns.
    cage_clip_pocket_diameter = 26;
    cage_clip_pocket_depth = 4;

    cage_notch_count = 4;
    cage_notch_width = 22.5;
    cage_notch_depth = 3.7;

    cage_outer_radius = cage_outer_diameter / 2;
    cage_inner_cavity_radius = cage_inner_cavity_diameter / 2;
    cage_notch_root_radius = cage_outer_radius - cage_notch_depth;

    // Clean radial relationship between bottle, battens, and lower bars.
    bottle_outer_radius = bottle_diameter / 2;
    side_batten_to_bottle_clearance =
        cage_notch_root_radius - bottle_outer_radius;
    bottom_sail_bar_inner_radius =
        bottle_outer_radius + bottom_sail_bar_bottle_clearance;
    bottom_sail_bar_inner_overhang =
        cage_notch_root_radius - bottom_sail_bar_inner_radius;

    c_end_piece_length =
        bottom_sail_bar_inner_overhang
        + side_batten_thickness
        + c_end_piece_outer_extension;

    // The strengthener sits immediately outward of the main batten.
    joint_strengthener_rail_slot_offset =
        bottom_sail_bar_inner_overhang
        + side_batten_thickness;

    // Place each sail-bar slot so its inward-facing edge is flush
    // with the inner/root surface of the corresponding cage notch.
    top_sail_bar_slot_centre_radius =
        cage_notch_root_radius + top_sail_bar_slot_width / 2;
    cage_surface_under_z =
        cage_total_height - cage_surface_thickness;
    cage_side_wall_height =
        cage_surface_under_z + cage_epsilon;

    // One shared native-Z datum keeps all four cage and batten holes aligned.
    cage_slot_vertical_centre_z = cage_surface_under_z / 2;
    cage_wall_tip_z = -cage_peak_extension;
    cage_lower_mount_z = cage_wall_tip_z + cage_lower_hole_from_tip;
    cage_mount_z_positions = [cage_slot_vertical_centre_z, cage_lower_mount_z];
    cage_wave_n = max(48, 4 * ceil(cage_wave_segments / 4));
    function cage_edge_z(a) = cage_wall_tip_z
        + (cage_surface_under_z + cage_peak_extension - cage_valley_wall_height)
            * (1 - cos(4*a)) / 2;
    side_batten_top_native_z =
        cage_total_height
        + top_sail_bar_thickness
        + (side_batten_notch_height - top_sail_bar_thickness) / 2
        + side_batten_end_margin;
    side_batten_bottom_native_z =
        side_batten_top_native_z - side_batten_height;
    side_batten_cage_hole_z_local =
        cage_slot_vertical_centre_z - side_batten_bottom_native_z;

    // Lower M6 joint shared by each non-sail batten and orange C piece.
    non_sail_joint_m6_z_local =
        side_batten_end_margin + c_end_piece_thickness / 2;
    c_end_piece_m6_x_local =
        bottom_sail_bar_inner_overhang + side_batten_thickness / 2;
    // Button positions remain fixed at the cap's 24 mm radius.
    cage_top_hole_radial_position = hole_spacing_cc;
    cage_top_hole_edge_to_centre =
        cage_outer_radius - cage_top_hole_radial_position;

    // In the cage's native coordinates, this is the bearing-tip plane.
    cage_bearing_tip_native_z =
        cage_surface_under_z - cage_bearing_diameter / 2;

    assert(cage_valley_wall_height > 0
           && cage_valley_wall_height < cage_surface_under_z
           && cage_peak_extension >= 0);
    assert(cage_mount_hole_diameter > 0
           && cage_mount_hole_diameter < cage_notch_width);
    assert(cage_lower_mount_z - cage_mount_hole_diameter / 2 >
           cage_edge_z(asin(cage_mount_hole_diameter / 2 / cage_inner_cavity_radius)) + 2,
           "Lower M3 hole needs 2 mm material to the sine edge.");
    assert(min(cage_mount_z_positions) - side_batten_bottom_native_z
           > cage_mount_hole_diameter / 2
           && max(cage_mount_z_positions) - side_batten_bottom_native_z
           < side_batten_height - cage_mount_hole_diameter / 2);
    // (clip-pocket dimension assert removed with the pocket -- top_pocket = false)
    assert(cage_hub_diameter > cage_shaft_hole_diameter,
           "Shaft hub must clear the shaft bore.");
    assert(cage_top_hole_radial_position - cage_top_hole_diameter/2
           > cage_hub_diameter/2);
    assert(cage_top_hole_radial_position + cage_top_hole_diameter/2
           < cage_bearing_pcd/2 - cage_bearing_diameter/2);
    assert(round_shaft_extension_above_cap + shaft_upper_length
           > cage_bearing_diameter/2 + cage_surface_thickness + top_sail_bar_thickness,
           "Sail shaft must reach through the cage roof and sail bar.");

    assert(cage_outer_diameter > 0,
        "Cage outer diameter must be greater than zero.");
    assert(cage_surface_thickness > 0,
        "Cage surface thickness must be greater than zero.");
    assert(cage_total_height > cage_surface_thickness,
        "Cage height must exceed its surface thickness.");
    assert(cage_side_wall_thickness > 0
           && cage_inner_cavity_diameter > 0,
        "Cage side-wall thickness leaves no inner cavity.");
    assert(cage_notch_count > 0
           && cage_notch_width > 0
           && cage_notch_depth > 0
           && cage_notch_depth < cage_side_wall_thickness,
        "Cage notches must be shallower than the side wall.");
    assert(cage_bearing_count > 0
           && cage_bearing_diameter > 0,
        "Cage bearing dimensions must be positive.");
    assert(cage_bearing_pcd / 2
           + cage_bearing_diameter / 2
           < cage_inner_cavity_radius,
        "The cage bearings do not fit inside the cavity.");
    assert(cage_top_hole_radial_position
           + cage_top_hole_diameter / 2
           < cage_outer_radius,
        "The cage top hole breaks through the circular edge.");
    assert(top_sail_bar_width <= cage_notch_width,
        "The top sail bar is wider than the cage side slots.");
    assert(
        abs(top_sail_bar_slot_depth
            - top_sail_bar_width / 2) < 0.001,
        "Top sail bar slots must reach the bar centreline."
    );
    assert(cage_shaft_hole_diameter < top_sail_bar_width,
        "The shaft opening does not fit within the top sail bar.");
    assert(round_shaft_diameter < top_sail_bar_axle_hole_diameter,
        "The sail shaft does not fit through the sail bar axle hole.");
    assert(
        top_sail_bar_slot_centre_radius + top_sail_bar_slot_width / 2
            < top_sail_bar_length / 2,
        "Top sail bar slots fall outside the bar."
    );
    assert(side_batten_width <= cage_notch_width,
        "The side battens are too wide for the cage slots.");
    assert(side_batten_thickness <= top_sail_bar_slot_width,
        "The side battens are too thick for the sail-bar slots.");
    assert(side_batten_notch_height == top_sail_bar_thickness,
        "The batten slots must exactly match the sail-bar board width.");
    assert(bottom_sail_bar_thickness == side_batten_notch_height,
        "The bottom sail bars must match the lower batten slots.");
    assert(bottom_sail_bar_slot_width == side_batten_thickness,
        "The bottom sail-bar slots must match the batten thickness.");
    assert(side_batten_to_bottle_clearance > 0,
        "The side battens overlap the bottle.");
    assert(bottom_sail_bar_inner_overhang >= 0,
        "The requested bottom-bar clearance exceeds the batten clearance.");
    assert(c_end_piece_thickness == side_batten_notch_height,
        "The C end pieces must match the lower batten slots.");
    assert(bottom_sail_bar_inner_overhang >= 10,
        "The bottle-side closure must be at least 10 mm long.");
    assert(c_end_piece_outer_extension >= 10,
        "The outer C-piece closure must be at least 10 mm long.");
    assert(joint_strengthener_below_bar == side_batten_end_margin,
        "The strengthener bottom must align with the batten bottom.");
    assert(joint_strengthener_slot_depth <= joint_strengthener_width,
        "The strengthener slot is deeper than the slat width.");
    assert(joint_strengthener_above_bar > m6_bolt_head_diameter
           && joint_strengthener_width > m6_bolt_head_diameter,
        "The supporter upper face must fit the M6 bolt head.");
    assert(side_batten_strengthener_m6_z_local
           + batten_cage_m6_hole_diameter / 2 < side_batten_height,
        "The supporter M6 hole must remain inside the batten.");
    assert(side_batten_cage_hole_z_local
           > batten_cage_m6_hole_diameter / 2
           && side_batten_cage_hole_z_local
           < side_batten_height - batten_cage_m6_hole_diameter / 2,
        "The M6 cage-fastening hole falls outside the batten.");
    assert(non_sail_joint_m6_z_local
           < side_batten_height - batten_cage_m6_hole_diameter / 2,
        "The lower M6 joint hole falls outside the batten.");

    echo("Side batten to bottle clearance = ",
         side_batten_to_bottle_clearance, " mm");
    echo("Bottom sail bar to bottle clearance = ",
         bottom_sail_bar_bottle_clearance, " mm");
    echo("Bottom sail bar inward protrusion = ",
         bottom_sail_bar_inner_overhang, " mm");
    echo("Bottom sail bar inner-edge radius = ",
         bottom_sail_bar_inner_radius, " mm");
    echo("Cage M3 mount heights / hole diameter = ",
         cage_mount_z_positions, cage_mount_hole_diameter);

// [M7] module cage_side_notch_profile() -> lib/control_cage.scad

// [M7] module cage_notched_outer_profile() -> lib/control_cage.scad

// [M7] module cage_centre_hex_2d() -> lib/control_cage.scad

// [M7] module cage_centre_hex_reinforcing_wall() -> lib/control_cage.scad

// [M7] module cage_surface_plate() -> lib/control_cage.scad

// [M7] module cage_underside_bearing() -> lib/control_cage.scad

// [M7] module cage_surface_part() -> lib/control_cage.scad

// [M7] module cage_wave_ring() -> lib/control_cage.scad

// [M7] module cage_side_walls_part() -> lib/control_cage.scad

// [M7] module cage_assembly_native() -> lib/control_cage.scad

    // Turn the cage upside down over the cap. At position 0, the
    // hemispherical bearing tips lie exactly on the cap's Z=0 surface.
    module positioned_cage_assembly() {
        translate([cx, cy, control_assembly_z - cage_vertical_position])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([180, 0, 0])
                    color([0.74, 0.77, 0.79])
                        control_cage(button_angle = cage_button_angle);
    }

    // ============================================================
    // TOP SAIL BAR
    // ============================================================

    // ============================================================
    // BUZDAĞI BOTTLE
    // ============================================================

    bottle_neck_diameter = cap_diameter - 3;

    bottle_collar_diameter = collar_diameter;

    bottle_bottom_base_diameter =
        bottle_diameter * bottle_bottom_base_ratio;

    bottle_straight_body_height =
        bottle_height
        - bottom_dome_height
        - top_dome_height
        - bottle_neck_height
        - bottle_collar_height
        - cap_height;

    bottle_body_z0 = bottom_dome_height;
    bottle_top_dome_z0 =
        bottle_body_z0 + bottle_straight_body_height;
    bottle_neck_z0 =
        bottle_top_dome_z0 + top_dome_height;
    bottle_collar_z0 =
        bottle_neck_z0 + bottle_neck_height;
    bottle_cap_z0 =
        bottle_collar_z0 + bottle_collar_height;

    assert(bottle_diameter > 0,
        "Bottle diameter must be positive.");
    assert(cap_diameter > 3,
        "Bottle cap diameter must exceed 3 mm.");
    assert(bottle_neck_diameter > 0,
        "Derived bottle-neck diameter must be positive.");
    assert(bottle_collar_diameter > 0,
        "Derived bottle-collar diameter must be positive.");
    assert(bottle_straight_body_height > 0,
        "Bottle height is too short for the selected dimensions.");
    assert(
        abs((bottle_cap_z0 + cap_height) - bottle_height)
            < 0.001,
        "Bottle components do not sum to bottle_height."
    );
    assert(bottle_cut_height >= bottle_body_z0,
        "Bottle cut must reach the straight body section.");
    assert(
        bottle_cut_height + insert_total_h
            <= bottle_top_dome_z0,
        "The control-cap socket extends beyond the straight body."
    );
    assert(
        abs(plug_top_od
            - (bottle_socket_diameter
               - 2 * insert_shaft_radial_clearance))
            < 0.001,
        "Insert-shaft diameter no longer follows bottle diameter."
    );
    assert(
        abs(
            (bottle_socket_diameter - plug_top_od) / 2
            - insert_shaft_radial_clearance
        ) < 0.001,
        "Insert shaft does not have the requested radial clearance."
    );
    assert(top_disk_od > bottle_diameter,
        "The top disk must remain outside the cut bottle.");
    assert(cage_inner_cavity_diameter > bottle_diameter,
        "The rotating cage does not clear the bottle.");


    // Cut bottle from lib/bottle_mockup.scad (lower dome removed + cap socket).
    module positioned_buzdagi_bottle() {
        translate([cx, cy, 0])
            cut_bottle(bottle_d      = bottle_diameter,
                       bottle_h      = bottle_height,
                       cap_d         = cap_diameter,
                       cap_h         = cap_height,
                       collar_d      = collar_diameter,
                       collar_h      = bottle_collar_height,
                       neck_d        = bottle_neck_diameter,
                       neck_h        = bottle_neck_height,
                       top_dome_h    = top_dome_height,
                       bottom_dome_h = bottom_dome_height,
                       dome_p        = bottle_dome_power,
                       base_ratio    = bottle_bottom_base_ratio,
                       steps         = bottle_profile_steps,
                       cut_height    = bottle_cut_height,
                       socket_d      = bottle_socket_diameter,
                       socket_h      = insert_total_h);
    }

    // Wooden sail frame from lib/sail_frame.scad, placed in the cage's native
    // frame with the same install transform the deleted positioned_* modules used.
    module positioned_sail_frame() {
        translate([cx, cy,
                   control_assembly_z + cage_bearing_tip_native_z - cage_vertical_position])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([0, 0, sail_frame_rotation_angle])
                    rotate([180, 0, 0])
                        sail_frame(part = "native_assembly",
                                   board_width = board_width,
                                   side_batten_height = side_batten_height,
                                   cage_mount_hole_diameter = cage_mount_hole_diameter,
                                   batten_cage_m6_hole_diameter = batten_cage_m6_hole_diameter,
                                   cage_wave_segments = cage_wave_segments,
                                   cage_valley_wall_height = cage_valley_wall_height,
                                   cage_peak_extension = cage_peak_extension,
                                   cage_lower_hole_from_tip = cage_lower_hole_from_tip,
                                   colored = enable_color_coding,
                                   show_hardware = true);
    }

    // ============================================================
    // FINAL OUTPUT
    // ============================================================
    module fixed_control_bottle_unit() {
        // Upright coordinates, with blue-cap tip at the origin.
        translate([0, 0, bottle_height])
        rotate([180, 0, 0]) {
            translate([cx, cy, control_assembly_z]) {
                color([0.78, 0.78, 0.82])
                    control_cap();
                button_preview_cylinders();
            }
            positioned_buzdagi_bottle();
        }
    }

    module rotating_cage_sail_unit() {
        // One rigid moving group in the same upright coordinate frame.
        // Keep the shaft with the cage so their set-screw lock stays engaged.
        translate([0, 0, bottle_height])
        rotate([180, 0, 0]) {
            translate([cx, cy,
                       control_assembly_z - (p_axle_upper_len() + p_axle_round_ext())])
                color([0.95, 0.65, 0.12])
                    sail_shaft();
            positioned_cage_assembly();
            positioned_sail_frame();
        }
    }

    module complete_sail_assembly() {
        fixed_control_bottle_unit();
        rotate([0, 0, cage_rotation_angle])
            rotating_cage_sail_unit();
    }

    // All geometry is emitted only by this module, never by an include.
    if (part == "full_assembly") {
        complete_sail_assembly();
    }
    else if (part == "control_cap") {
        control_cap();
    }
    else if (part == "axle") {
        sail_shaft();  // upper end already on Z=0
    }
    else if (part == "buttons") {
        button_preview_cylinders();
    }
    else if (part == "cage_assembly") {
        positioned_cage_assembly();
        positioned_sail_frame();
    }
    else if (part == "cage_surface") {
        translate([0, 0, cage_bearing_diameter / 2])
            control_cage();
    }
    else if (part == "cage_side_walls") {
        control_cage();
    }
    else if (part == "top_sail_bar")   { sail_frame(part = "top_bar", board_width = board_width); }
    else if (part == "side_battens")   { sail_frame(part = "sail_batten", board_width = board_width); }
    else if (part == "bottom_sail_bars") { sail_frame(part = "bottom_bars", board_width = board_width); }
    else if (part == "joint_strengtheners") { sail_frame(part = "strengtheners", board_width = board_width); }
    else if (part == "c_end_pieces")   { sail_frame(part = "c_end_pieces", board_width = board_width); }
    else if (part == "sails")          { sail_frame(part = "sails", board_width = board_width); }
    else if (part == "bottle") {
        positioned_buzdagi_bottle();
    }
    else {
        assert(false, str("Unknown part selection: ", part));
    }

}
// END SELF-CONTAINED SAIL MODULE


// The former top bottle occupies pre-orientation -Y, physical +Z.
// Preserve its exact seating: cap_height plus the existing inward bottle shift.
top_port_outer_face_y = assembly_center[1] - port_outer_offset;
top_sail_cap_insertion = bottle_insertion + bottle_inward_shift;
top_sail_cap_tip_y = top_port_outer_face_y + top_sail_cap_insertion;
top_sail_cap_tip = [assembly_center[0], top_sail_cap_tip_y, assembly_center[2]];

module installed_sail_apparatus_on_top_port() {
    // Local cap tip is the origin; +Z points out of the top port.
    // Final turtle Rx(-90) cancels this Rx(+90), leaving the apparatus upright.
    // Permanent 90-degree installation clocking; not a user rotation control.
    translate(top_sail_cap_tip)
        rotate([90, 0, 0])
            rotate([0, 0, 90])
                hope_turtle_sail_apparatus(
                    bottle_diameter = bottle_diameter,
                    bottle_height = bottle_height,
                    cap_diameter = cap_diameter,
                    cap_height = cap_height,
                    collar_diameter = collar_diameter,
                    top_dome_height = top_dome_height,
                    bottom_dome_height = bottom_dome_height,
                    board_width = slat_thickness,
                    batten_cage_m6_hole_diameter = m6_clearance_diameter,
                    cage_mount_hole_diameter = cage_mount_hole_diameter,
                    cage_wave_segments = cage_wave_segments,
                    cage_valley_wall_height = cage_valley_wall_height,
                    cage_peak_extension = cage_peak_extension,
                    cage_lower_hole_from_tip = cage_lower_hole_from_tip,
                    cage_button_angle = cage_button_angle,
                    side_batten_height = side_batten_height,
                    cage_vertical_position = cage_vertical_position,
                    cage_rotation_angle = cage_rotation_angle,
                    sail_frame_rotation_angle = sail_frame_rotation_angle,
                    cage_exploded_view = cage_exploded_view,
                    bottle_dome_power = dome_power,
                    bottle_neck_height = bottle_neck_height,
                    bottle_collar_height = collar_height,
                    bottle_bottom_base_ratio = bottom_base_ratio,
                    bottle_profile_steps = profile_steps,
                    curve_segments = sail_curve_segments,
                    part = "full_assembly"
                );
}

assert(abs(top_sail_cap_tip_y
           - (assembly_center[1] - bottle_origin_offset + bottle_height)) < 0.001,
    "Sail blue-cap tip must exactly replace the former top-bottle tip.");
assert(abs(top_sail_cap_insertion - (cap_height + port_height)) < 0.001,
    "Top sail bottle must preserve the turtle's existing seating depth.");
assert(bottle_diameter == port_height,
    "Sail bottle and Ecojoiner must share the same bottle diameter.");
echo("TOP SAIL cap-tip world XYZ = ",
     [top_sail_cap_tip[0], top_sail_cap_tip[2], -top_sail_cap_tip[1]]);
echo("TOP SAIL bottle/cap/cage centre axis world XY = ",
     [assembly_center[0], assembly_center[2]]);


// ============================================================================
// FINAL PHYSICAL ASSEMBLY — EXACT PORT-DATUM SEATING
// ============================================================================
//
// Geometry strategy:
//
//   1. The ballast's green-slat TOP is first aligned with the INNER face
//      of the bottom Ecojoiner John — the actual entrance to the port.
//
//   2. The entire ballast is then inserted by EXACTLY `port_length`.
//
//   3. Because every board uses `slat_thickness`, the final green-slat top
//      lands exactly on the underside / mating face of the yellow John.
//
// `port_height` remains the shared bottle/opening diameter;
// `port_length` is the 82 mm axial insertion distance.

// Insert the ballast through the actual axial depth of the port.
ballast_vertical_lift =
    port_length;


// --------------------------------------------------------------------------
// ECOJOINER + BOTTLES
// --------------------------------------------------------------------------

module ecojoiner_and_bottles() {
    ecc = enable_color_coding;

    // Frame 1: suppress the two Pressers on the physical 3-o'clock port
    // (pre-orientation +X) for the rear-fin green shafts.
    eco_centered_rectangle([0, 0, 0], true, false, ecc);

    eco_centered_rectangle([0, frame_step_tilt, frame_step_spin],
                           false, false, ecc);

    // Frame 3: suppress only the physical DOWN ballast-port Pressers
    // (pre-orientation +Y).
    eco_centered_rectangle([frame_step_tilt, 0, frame_step_spin],
                           true, false, ecc);

    // Four Final Keys.
    eco_inserted_final_key(-final_key_x_offset,  final_key_z_offset, ecc);
    eco_inserted_final_key( final_key_x_offset,  final_key_z_offset, ecc);
    eco_inserted_final_key(-final_key_x_offset, -final_key_z_offset, ecc);
    eco_inserted_final_key( final_key_x_offset, -final_key_z_offset, ecc);


    // Five ordinary bottles. The physical top port receives the integrated
    // sail apparatus and its own cap-down bottle below.
    bottle_at_port("+X");
    bottle_at_port("-X");

    bottle_at_port("+Y");

    bottle_at_port("+Z");
    bottle_at_port("-Z");
}


// --------------------------------------------------------------------------
// FINAL SCENE
// --------------------------------------------------------------------------
//
// In the pre-rotation coordinate system, translating ballast toward -Y
// becomes a physical upward movement after the fixed turtle orientation.

// The fixed scene rotation maps [x,y,z] to [x,z,-y]. All horizontal
// bottle axes therefore lie at world Z = -assembly_center[1].
water_surface_z = -assembly_center[1];
water_origin = [assembly_center[0] - water_cube_size / 2,
                assembly_center[2] - water_cube_size / 2,
                water_surface_z - water_cube_size];

assert(water_cube_size > 0 && water_transparency >= 0 && water_transparency <= 1,
       "Water size must be positive and transparency between 0 and 1.");

module water_preview() {
    // Keep separate from turtle solids: this depicts a waterline, not buoyancy.
    if (show_water && $preview)
        color([0.10, 0.45, 0.95, 1 - water_transparency])
            translate(water_origin)
                cube([water_cube_size, water_cube_size, water_cube_size]);
}

module full_turtle_scene(include_top_sail = true) {
    rotate([-90, 0, 0]) {
        ecojoiner_and_bottles();

        if (include_top_sail)
            installed_sail_apparatus_on_top_port();

        translate([0, -ballast_vertical_lift, 0])
            installed_ballast_on_positive_y_port();

        // Rear apparatus around / behind the physical rear bottle.
        installed_rear_fin_on_3oclock_port();
    }
    water_preview();
}

if (assembly_view == "full_turtle") {
    full_turtle_scene();
} else if (assembly_view == "top_sail") {
    // Exactly the same transform and master dimensions as the complete scene.
    rotate([-90, 0, 0])
        installed_sail_apparatus_on_top_port();
} else if (assembly_view == "core") {
    full_turtle_scene(include_top_sail = false);
} else {
    assert(false, str("Unknown assembly_view: ", assembly_view));
}


// ============================================================================
// EXACT-SEATING ASSERTIONS
// ============================================================================

// Before insertion, green slat top is exactly at the port entrance.
ballast_top_before_insertion_y =
    ballast_port_entrance_y;

// After insertion, it must equal the target yellow John face.
ballast_top_after_insertion_y =
    ballast_top_before_insertion_y
    - ballast_vertical_lift;

assert(
    abs(ballast_top_after_insertion_y - ballast_target_john_face_y) < 0.001,
    "Ballast slat top must be flush with yellow John mating face."
);


// ============================================================================
// CONSISTENCY / DATUM REPORT
// ============================================================================

echo("SHARED board thickness = ", slat_thickness, " mm");
echo("Integrated sail board thickness = ",
     slat_thickness, " mm");

echo("SHARED bottle diameter = ", bottle_diameter, " mm");
echo("Integrated sail bottle diameter = ",
     bottle_diameter, " mm");
echo("Ecojoiner port_height = ", port_height, " mm");
echo("Ballast bottle diameter = ", ballast_bottle_diameter, " mm");

echo("SHARED bottle height = ", bottle_height, " mm");
echo("Ecojoiner bottle-height reference = ",
     ecojoiner_bottle_height, " mm");
echo("Ballast bottle height = ", ballast_bottle_height, " mm");

echo("User-set collar diameter = ", collar_diameter, " mm");

echo("Outer bottom John face Y = ",
     positive_y_john_end, " mm");
echo("Port entrance inner face Y = ",
     ballast_port_entrance_y, " mm");
echo("Target yellow John face Y = ",
     ballast_target_john_face_y, " mm");

echo("Shared bottle/opening diameter (port_height) = ",
     port_height, " mm");
echo("Actual Ecojoiner axial port depth (port_length) = ",
     port_length, " mm");
echo("Ballast vertical lift = port_length = ",
     ballast_vertical_lift, " mm");

echo("Ballast top after insertion Y = ",
     ballast_top_after_insertion_y, " mm");
echo("Top sail cap insertion = ",
     top_sail_cap_insertion, " mm");


echo("Top 45-degree cut begins below slat top = ",
     ballast_core_height - ballast_upper_diagonal_start, " mm");
echo("Top shoulder inward step = ",
     ballast_shoulder_step, " mm");
echo("Ballast M6 hole down from slat top = ",
     ballast_core_mount_hole_from_top, " mm");
echo("Green ballast slat height = ", ballast_core_height, " mm");
echo("  formula: bottle_height - cap_height + 6.0 * slat_thickness");
echo("  = ", bottle_height, " - ", cap_height,
     " + 6.0 * ", slat_thickness,
     " = ", ballast_core_height, " mm");

echo("Yellow ballast fin inspection pullout = ",
     ballast_fin_inspection_pullout, " mm");


echo("Yellow ballast-fin bottle-seat cut depth = ",
     ballast_fin_upper_cut_depth, " mm");
echo("  bottle diameter = ", ballast_bottle_diameter, " mm");
echo("  extra clearance removed = one slat_thickness = ",
     ballast_fin_bottle_clearance_extra, " mm");

echo("Pressers removed on physical DOWN ballast port = 2");
echo("Pressers removed on physical 3-o’clock rear-fin port = 2");

echo("Ballast orange center-slot depth = ",
     ballast_center_slot_depth, " mm");
echo("Ballast yellow-fin slot depth = ",
     ballast_fin_slot_depth, " mm");
echo("Ballast slots re-seated equally; inspection pullout = ",
     ballast_fin_inspection_pullout, " mm");

echo("Physical ballast direction = -Z (bottom / underwater)");
