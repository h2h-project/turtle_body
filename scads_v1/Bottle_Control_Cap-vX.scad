/*
 Hope Turtle — control cap, EXPERIMENTAL side-tab variant "vX". Units: mm.
 License: CERN-OHL-S-2.0.

 HAND-BUILT ONE-OFF VARIANT — NOT a generated bundle, NOT produced by
 build/build.py, NOT wired into build/manifest.json. Forked from the
 production src/components/Bottle_Control_Cap.scad / lib/control_cap.scad
 (turtle_body v4.0.0). Everything outside the side tabs (disk, insert,
 O-ring gland, band channels, button holes, asserts) is copied verbatim from
 lib/control_cap.scad; only the side-tab placement/taper/wire-channel logic
 below is a hand-modified fork (see the precedent: v1.0
 SCADs/Bottle_Control_Cap_v1XX.scad).

 SELF-CONTAINED (2026-09-23): lib/params.scad and lib/util.scad are pasted
 inline below (between the "[bundle] begin/end" markers), snapshotted at
 turtle_body v4.0.0. No other files are needed to open or render this file.
 Consequence: it no longer tracks lib/params.scad — a later lib change must
 be re-bundled by hand (python3 build/bundle.py on a copy with the two
 `use <../lib/...>` lines restored).

 Revision history (all 2026-09-22):

 Rev 1: no rotation off the button axis; each tab slides sideways by
 tab_side_offset (mirrored +6/-6); taper removed (straight inner face).

 Rev 2/3: chased a "still looks rotated" report by dropping the curved
 (wall-hugging) outer face for a flat one, and fixed the offset from
 mirrored to both-same-direction.

 Rev 4 (this one) — reverts the flat outer face. Confirmed from the actual
 renders: a flat/unclipped outer face is what looked like "ugly rectangles"
 that don't match the cap's round wall. The outer face is curved again —
 intersected against the TRUE cavity-wall / insert-wall cylinders (centred
 on the real cap axis, unmoved), same as lib/control_cap.scad's production
 cap_side_tabs() — so it genuinely follows the wall's own curvature. This is
 safe (not the rev-1 "diagonal" bug) because that block and that cylinder
 are BOTH invariant along Z within each segment: intersecting a fixed 2-D
 footprint with a fixed-radius cylinder, repeated unchanged at every height,
 produces a perfectly vertical curved wall, not a sloped/diagonal one. What
 actually varies is the plan (top-down) shape: since the tab is offset from
 the wall's own centre, its curved outer face naturally sits a little closer
 to the true wall on the side nearer the offset direction and a little
 farther on the other side — that asymmetry IS "matching the curve of a
 wall you're not centred on," not a defect. The two things rev 2/3 also
 fixed are kept:
   - x_off (tab_side_offset) is the SAME for both tabs — a uniform slide,
     not mirrored.
   - Inner face stays a straight vertical line (no taper) top to bottom.
   - Wire channel: 4 mm dia, blind, exits at the radial centre of the cap's
     own insert-wall thickness (not into the hollow cavity), cut in the
     outer/global difference() so it can reach past the tab's own material.
 As in production, the rib (inside the cavity height, Z <= lip_z) clips to
 the true cavity-wall radius (r_outer_true); the lip extension (free-
 standing above the cap's own body, Z > lip_z) clips to the true insert
 outer-wall radius (r_wall_true) — the same real step production always
 had, just now off-axis instead of on it.

 Rev 5 (this one) — two more changes:
  (a) The tab's INNER face is now positioned by a new adjustable variable,
      tab_inner_wall_distance (2 cm / 20 mm default), measured INWARD from
      the true outer wall radius (r_wall_true -- the cap's actual outer
      diameter along the button axis), not from the cavity wall the way
      tab_depth used to work. r_inner = r_wall_true - tab_inner_wall_distance.
      This reaches much deeper into the cap than the old 2 mm tab_depth did
      (r_inner drops from ~34.5 mm to ~20.5 mm at the current 81 mm insert
      diameter) -- comfortably still clear of the centre boss, asserted.
  (b) Wire channel direction reversed back to angling INWARD and breaking
      into the HOLLOW CAVITY, not blind in the solid wall the way rev 2-4
      had it. entry_r stays centred in the tip's own material; exit_r is
      now max(0, r_inner - wire_hole_d) -- a full hole-diameter past the
      (now much deeper) inner face, same formula production always used.
      The open end remains at the tip (outside, where a wire is fed in);
      what changed is where the OTHER end opens -- now on the inside of the
      cap (the cavity), not dead-ending in the wall's own material.

 Rev 6 (this one) — new silicone-seal strategy for the two insert-wrap seal
 grooves (cap_plug_outer()'s one_groove(), separate from the small axle
 O-ring gland). Production/rev 1-5 cut a RECTANGULAR slot (flat floor,
 square corners: 2.7 mm wide x 2 mm deep) meant for a flat cast ring
 (lib/silicone_ring_mold.scad's flat-ring mold). This instead cuts a
 SEMICIRCULAR channel -- open flush with the insert's true outer surface,
 curving inward to a rounded floor -- sized to seat a round-section O-ring:
   band_channel_depth (kept at the same 2 mm) IS the semicircle's radius,
   so the groove's open width is always 2 x band_channel_depth (4 mm), and
   that's also the O-ring's own cross-section diameter -- half its
   thickness recesses into the groove, half stands proud of the surface for
   compression sealing, same convention as the existing axle O-ring gland.
 band_channel_w is gone as an independent input (width is now derived, not
 free); the two groove positions (band1/2_center_z_local) are unchanged.
 NOT yet matched on the casting side: lib/silicone_ring_mold.scad still
 only casts FLAT rectangular rings -- it would need a round-torus mold (like
 the small axle O-ring's own two-part mold there) sized to this new 4 mm
 cross-section before this groove shape could actually be filled with a
 matching cast part. Flagged, not implemented here (out of scope of "the
 groove on the cap" as asked).

 Rev 7 (this one) — two changes:
  (a) tab_inner_wall_distance default 20 -> 12 mm (r_inner now sits ~7.5 mm
      further out, closer to the true outer wall, still clear of the centre
      boss per the existing assert).
  (b) New faint reference etch line: a shallow (0.2 mm deep, 0.6 mm wide)
      groove recessed into the cavity ceiling (roof underside, the inner
      face you see looking up into the hollow insert), spanning the full
      cavity diameter along button_axis -- i.e. it passes through the centre
      bore and both button centres. Alignment mark only, no structural role.
      New inputs: etch_line_enable / etch_line_width / etch_line_depth.

 Rev 8 (this one) — four changes:
  (a) tab_wire_hole_diameter 4 -> 7 mm.
  (b) centre_boss_diameter: 12 mm was requested but fails the existing
      O-ring-gland-clearance assert (needs boss_d > gland OD + 1 mm = 12.5);
      set to 13 mm, the smallest value that still clears it.
  (c) New button_axis_offset (6 mm): both button holes now slide off the
      etched axle line, same direction as tab_side_offset (mirrors the tab
      slide, not mirrored left/right). Clearance asserts on button_radius
      now use the true centre distance (hypot of radius and offset), not
      just the nominal radius.
  (d) Button spacing: 18 mm centre-to-centre was requested but is not
      reachable at the existing 17 mm button diameter (the two holes would
      nearly touch each other and swallow the centre boss/bore). Per
      instruction, kept button_upper_d at 17 mm and used the real minimum
      spacing instead: hole_spacing_cc (radius) 25 -> 15 mm, giving 30 mm
      true centre-to-centre spacing (smallest that clears the 13 mm boss
      with ~1 mm margin, accounting for the offset in (c)).

 Rev 9 (this one) — two changes:
  (a) Tab wire channel's cavity-side opening moved: it now breaks through
      exactly at the cap's own inside corner -- where the flat roof
      (z = roof_t) meets the cavity wall (r = r_outer_true) -- instead of
      partway down the rib at a z = lip_z - wire_hole_exit_from_lip offset
      (that parameter is gone). The open end at the tip is unchanged.
  (b) New rectangular PCB-spacer notch in each tab's leg (the lip-extension
      portion beyond lip_z that sticks out past the cap body): starts
      tab_notch_from_lip (5 mm) past the lip, cuts tab_notch_depth (5 mm)
      radially in from the tab's inner face, and runs tab_notch_height
      (8 mm) further up the leg toward the tip. Full tab width. New module
      cap_tab_notches_vX(); new inputs tab_notch_enable /
      tab_notch_from_lip / tab_notch_depth / tab_notch_height.

 Rev 10 (this one) — the rev-9 wire channel change (a) is reverted: the
 "breaks through at the roof/wall corner" routing put the whole channel
 in the leg's outer material band, which turned out to overlap the notch
 added in rev 9(b) -- the notch's remaining wall (33.5 to 40.5 mm radius,
 only 7 mm thick, same as the hole's own diameter) had no room left for
 the hole to also pass through there without either touching the notch or
 breaking out the leg's own outer surface. Back to rev5's shape instead:
 open at the tip, angling inward to break through on the LOWER INSIDE of
 the tab (into the hollow cavity, below the lip) -- tab_wire_hole_exit_
 from_lip (15 mm) is back. New: when tab_notch is enabled, the channel now
 bends -- it completes its whole inward angle BEFORE its z drops to the
 notch's own top face (reaching its final, already-low exit radius right
 there), then runs straight down through the notch's z-band and on to the
 exit at that constant, already-safe radius -- so within the notch's
 z-band it only ever occupies space the notch (or the open cavity past
 r_inner) has already cleared, not fresh wall beside it. With no notch,
 it's the original single straight run, unchanged.

 Rev 11 (this one) — SUPERSEDED by rev 12, see below. Tried letting the
 wire channel's entry itself move down the tab's own vertical axis
 (tab_wire_entry_depth), auto-snapping its radius to whichever true outer
 surface was active there so it would still breach the outside. Confirmed
 by render to be wrong: that snap moved the visibly-open entry off the
 tab's flat tip (foot) face onto the tab's side -- not what was wanted.

 Rev 12 (this one) — reverted the entry position: it is FIXED again at the
 tip, centred in the tab's own material (entry_r = (r_inner + r_wall_true)/2,
 z = tip_z), exactly as rev 10 had it -- it must always emerge dead-centre
 on the tab's flat tip face, never on the side, and this does not move.
 tab_wire_entry_depth is renamed tab_wire_immersion_depth and now controls
 something narrower: how far down the tab's own vertical axis the channel
 runs straight (still centred, still fully enclosed -- never touching a
 side surface) before it starts bending inward toward the exit. When the
 PCB-spacer notch is on, that straight run is clamped so it can never
 overlap the notch's own z-band (at entry_r it would cut fresh wall next to
 the already-thinned notch) -- a request deeper than the clamp allows runs
 at the notch's top face instead (rev 10's shape) and is flagged with an
 echo WARNING, not silently widened into the notch. At the notch's current
 default dimensions the clamp is 15 mm, so tab_wire_immersion_depth's
 default was set to 15 (the deepest immersion the fixed entry and the notch
 both allow), not the 20 mm first asked for.

 Rev 13 (this one) — tab_wire_immersion_depth (an mm value, plus a separate
 clamp/bend-segment machinery) replaced with a single tab_wire_hole_exit_
 angle (degrees from vertical), asked for directly as the tunable. Entry is
 still fixed exactly as rev 12 (tip, centred, never moves). The channel is
 now one straight diagonal -- no more separate straight-immersion + bend
 segments -- whose end point is DERIVED from the angle:
   exit_z = tip_z - (entry_r - exit_r) / tan(exit_angle_deg)
 Smaller angle (closer to vertical) = deeper immersion before it opens into
 the cavity; larger angle (closer to horizontal) = shallower. Replaces both
 the old tab_wire_hole_exit_from_lip (exit_z is derived now, not set) and
 tab_wire_immersion_depth. Notch safety was a HARD assert in this revision:
 since the diagonal's radius is only safe once it has fully transitioned to
 exit_r, control_cap() required exit_z land at or above the notch's own top
 face when tab_notch is on -- an angle too small for that failed the whole
 render. Superseded by rev 14 below.

 Rev 14 (this one) — rev 13's hard assert made every render fail below the
 minimum angle (~40.9 deg at current notch defaults), which broke the
 "tweak it live" workflow the angle control was added for. Changed to
 clamp-and-warn, matching how tab_wire_immersion_depth's notch clamp worked
 in rev 12: wire_exit_angle_eff (computed once, unconditionally, right after
 tip_z -- not inside an `if`, so the same value reaches the warning echo AND
 the actual cut) clamps UP to whichever minimum applies -- the notch angle
 (tab_notch on) or the cap-floor angle (always) -- and only WARNS if the
 requested angle was raised. The model now always renders; a request below
 the minimum just quietly (with an echo) uses the steepest safe angle
 instead, exactly like the floor/notch clamps everywhere else in this file.

 Rev 15 (this one) — two fixes:
  (a) The angle wasn't visibly moving anything: rev 13/14's exit_r sat a
      full hole-diameter past r_inner, i.e. already inside the tab's own
      always-open interior (nothing to cut there regardless of z) -- the
      only thing actually visible on the tab is where the hole crosses
      r_inner (the tab's own inner face) into that open space, and that
      crossing point only moved by the fraction of the entry_r-to-exit_r
      span that lies above r_inner (~46% of the total change), which barely
      registered. Redesigned: the angle now drives the diagonal from the
      entry down to where it crosses r_inner directly (break_z = tip_z -
      (entry_r - r_inner)/tan(angle)) -- that crossing IS the emergence you
      see move. A short fixed horizontal stub then continues on to
      wire_exit_r at the same z, purely to guarantee a full clean
      breakthrough rather than a knife-edge graze; since it's already past
      r_inner (always-open space), it doesn't add to the visible immersion.
      This also relaxed the notch's minimum angle (now ~16.9 deg instead of
      ~40.9) since the diagonal only needs to reach a safe radius near the
      notch's own edge before crossing its z-band, not travel all the way
      to the far interior exit radius.
  (b) tab_corner_fillet default 4 -> 0: the tabs' bottom (floor-facing)
      corners, where each leg meets the cap's inner surface, were rounded
      by cap_side_tabs_vX's own fillet cutter -- unwanted; 0 disables it, so
      the tabs now go straight down to the inner cap surface with sharp
      corners, as asked.

 Rev 16 (2026-09-24) — two changes:
  (a) hole_spacing_cc (button radius, centre-to-axis) 15 -> 20 mm: 40 mm
      centre-to-centre along the axis. The hole's outer edge now reaches
      28.5 mm from the axis, exactly r_inner -- tangent to the tab rib's
      inner face at the roof, zero margin (no overlap: holes are in the roof,
      tabs start below it).
  (b) Taper returned to both tabs, new input tab_taper_loss (2 mm). The
      inner face runs straight at r_inner from the tip down through the
      PCB-spacer notch; from the notch's lower edge (the lip when tab_notch
      is off) it leans linearly OUTWARD (toward the cap wall, away from the
      axis) going down, reaching r_inner + 2 = 30.5 mm where the tab meets
      the cap surface (roof_t) -- thinner at the base, which gives the
      button holes (outer edge 28.5 mm, from (a)) 2 mm of clearance to the
      tab base instead of being tangent to it. Spans the lip stretch below
      the notch and the whole rib. Tip, notch and wire channel unchanged.
      (Earlier attempts in the same session tapered above the notch, then
      toward the axis -- both wrong, reverted.)

 Confirmed current production dimensions this variant was forked from:
   - insert (plug) outer diameter:      81 mm
   - cavity (inner) diameter:           73 mm  (insert_od - 2 x wall_t)
   - cap wall thickness:                 4 mm  (insert_wall_t)
   - axle/centre-shaft bore, with allowance: 8.7 mm (0.35 mm radial / 0.7 mm
     diametral clearance over the Ø8 mm shaft)

 Not validated — a fit/registration experiment, same caveat as production.

 SOURCE OF THE UNCHANGED PORTIONS — lib/control_cap.scad + lib/params.scad.
*/

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
// [bundle] begin use <../lib/util.scad>
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
// [bundle] end   <../lib/util.scad>

/* [Cap body] */
top_disk_thickness  = 5;
centre_boss_depth   = 1.5;
centre_boss_diameter = 13;  // 12 mm requested, but the boss must clear the
                             // existing 11.5 mm O-ring gland OD by >=1 mm wall
                             // (control_cap's own assert) -- 13 is the smallest
                             // value that still satisfies it; see chat
cup_wall_thickness  = 4;
insert_total_h      = 35;
entry_chamfer_h     = 1;
entry_chamfer_delta = 1;

/* [Axle and buttons] */
shaft_hole_d   = 8.7;
button_upper_d = 17;
button_axis    = "y"; // [x,y]
hole_spacing_cc = 20;  // button_radius (centre-to-axis, NOT centre-to-centre) --
                        // 40 mm centre-to-centre along the axis. Rev 16: 15 -> 20.
                        // At 20 the hole's outer edge (20 + 17/2 along the axis, at
                        // x = button_axis_offset, inside the tab's width) reaches
                        // 28.5 mm, flush with the tab rib's inner face (r_inner) --
                        // tangent, zero margin.
button_axis_offset = 6;  // shift BOTH button centres off the etched axle line,
                          // same direction and magnitude as tab_side_offset

/* [Axle O-ring gland] */
oring_gland_enable = true;
oring_gland_od = 11.5;
oring_gland_width = 2.6;
oring_gland_from_face = 3.5;

/* [Silicone band channels -- vX: semicircular O-ring grooves] */
// Half-round channel, not the old rectangular slot: band_channel_depth IS
// the semicircle's radius, so it also sets the O-ring's cross-section --
// a round-section O-ring of diameter 2*band_channel_depth seats with half
// its thickness recessed, half proud (same convention as the axle O-ring
// gland elsewhere in this file, just applied to a big ring around the
// whole insert). Width is no longer an independent input -- it's always
// 2*band_channel_depth. Depth kept at the same 2 mm production used.
band_channels_enable = true;
band_count = 2; // [0:1:2]
band1_center_z_local = 12;
band2_center_z_local = 25;
band_channel_depth = 2;   // = O-ring groove radius; O-ring cross-section dia = 2 x this (4 mm)

/* [Side tabs -- vX] */
// Two internal ribs, inner face straight from the tip through the notch, then
// tapering inward down to the cap surface (rev 16), CURVED outer face
// that hugs the real cavity/insert wall (see header for why this is safe).
// No rotation off the button axis -- both tabs slide the SAME real-world
// direction, sideways (tangentially), by tab_side_offset.
side_tabs_enable = true;
tab_width  = 21;
tab_inner_wall_distance = 12;  // tab's inner face, measured INWARD from the
                                // true outer wall (r_wall_true) along the button axis
                                // (r_inner = r_wall_true - tab_inner_wall_distance)
tab_top_overhang = 28;
tab_corner_fillet = 3;  // rounds the tab's OUTWARD-facing vertical edges (where
                         // each flat side wall meets the tab's own outer curved
                         // surface), full height, both segments. The tab still
                         // runs straight down to the cap's inner surface with
                         // sharp bottom corners -- only the outward edges round.
tab_side_offset = 6;   // same direction for both tabs (not mirrored)
tab_taper_loss  = 2;   // rev 16: the tab's inner face leans OUTWARD (toward the
                        // cap wall, away from the axis -- the tab gets thinner,
                        // giving the button holes room) by this much in total,
                        // linearly, from the
                        // PCB-spacer notch's lower edge (the lip when the notch
                        // is off) down to where the tab meets the cap surface.
                        // Notch + leg above it stay straight. Both tabs. 0 = off.

/* [Reference etch line -- vX] */
// Faint reference groove on the cavity ceiling (roof underside, the "inner"
// face you see looking up into the hollow insert), marking the diameter
// axis that runs through the centre bore and both button centres -- i.e.
// along button_axis. Purely a visual/assembly alignment mark: shallow
// (0.2 mm) and narrow (0.6 mm), no structural role, no assert coupling.
etch_line_enable = true;
etch_line_width  = 0.6;
etch_line_depth  = 0.2;

/* [Tab wire hole] */
// Entry is FIXED at the tip, dead-centre on the tab's flat foot face -- it
// never moves, never breaches the tab's side. tab_wire_hole_exit_angle is
// the single dial for the flue's whole descent: the slant, measured from
// VERTICAL, at which it angles inward from the entry down to where it
// breaks through into the hollow cavity below the lip. Smaller angle (closer
// to vertical) = deeper immersion before it opens up; larger angle (closer
// to horizontal) = shallower. control_cap() asserts the resulting exit
// point stays inside the cap and (when tab_notch is on) clears the
// PCB-spacer notch's own z-band -- reports the minimum angle if not.
tab_wire_hole_enable = true;
tab_wire_hole_diameter = 7;
tab_wire_hole_exit_angle = 45;  // degrees from vertical (0 = straight down,
                                 // 90 = horizontal); tweak to dial in the
                                 // immersion -- smaller = deeper

/* [Tab PCB-spacer notch] */
// Rectangular notch in each tab's leg (the part beyond the lip, sticking
// out past the cap body) for a brass circuit-board spacer.
tab_notch_enable    = true;
tab_notch_from_lip  = 5;   // mm past the lip before the notch starts
tab_notch_depth     = 5;   // mm cut radially in from the tab's inner face
tab_notch_height    = 8;   // mm the notch runs up the leg

/* [Render] */
fn = 120; // [48:8:240]

// ==========================================================================
//  Geometry -- unchanged helpers copied verbatim from lib/control_cap.scad
// ==========================================================================

function cap_taper_od_at(z_local, top_od, bot_od, insert_len) =
    top_od + (bot_od - top_od) * (z_local / insert_len);

module cap_plug_outer(disk_od, roof_t, insert_len, insert_od,
                      chamfer_h, chamfer_delta,
                      band_enable, band_count, band_z1, band_z2,
                      band_depth, band_fn = 96) {
    top_od = insert_od;
    bot_od = insert_od;
    straight_h = insert_len - chamfer_h;
    R = insert_od / 2;   // grooves live on the straight section, where top_od == bot_od == insert_od

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

    // Semicircular O-ring groove: a half-round channel, open flush with the
    // true outer surface (X = R) and curving inward to a rounded floor at
    // radius R - band_depth -- i.e. band_depth IS the semicircle's radius,
    // so a round-section O-ring of cross-section diameter 2*band_depth
    // seats with exactly half its thickness recessed and half proud of the
    // surface (the usual O-ring-gland convention, applied here to a big
    // ring that wraps the whole insert instead of a small axle seal).
    // Built as rotate_extrude() of a half-disk 2-D profile (X = radial
    // distance from the axis, Y = local Z offset from center_z).
    module one_groove(center_z) {
        translate([0, 0, roof_t + center_z])
            rotate_extrude($fn = band_fn)
                intersection() {
                    translate([R, 0]) circle(r = band_depth, $fn = band_fn);
                    translate([R - band_depth - p_eps(), -(band_depth + p_eps())])
                        square([band_depth + p_eps(), 2 * (band_depth + p_eps())]);
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

// Reference etch line -- vX: a shallow groove recessed into the cavity
// ceiling (roof underside, z = roof_t), running the full cavity diameter
// along the given axis and centred on the cap axis -- i.e. it passes
// through the centre bore and (for axis == button_axis) both button
// centres. Purely a faint alignment mark, not a functional feature.
module cap_axis_etch_line_vX(span_r, roof_t, width, depth, axis) {
    len = 2 * span_r;
    translate([0, 0, roof_t - depth])
        if (axis == "x")
            translate([-len / 2, -width / 2, 0])
                cube([len, width, depth + p_eps()]);
        else
            translate([-width / 2, -len / 2, 0])
                cube([width, len, depth + p_eps()]);
}

// vX: button holes carry an optional off-axis offset (same direction for
// both holes, not mirrored) so they can be slid off the etched axle line --
// mirrors how cap_side_tabs_vX slides both tabs by tab_side_offset.
module cap_button_holes_cut(roof_t, button_d, axis, radius, offset = 0) {
    module hole(x, y)
        translate([x, y, -p_eps()]) cylinder(h = roof_t + 2 * p_eps(), d = button_d);
    if (axis == "x") { hole(radius, offset); hole(-radius, offset); }
    else             { hole(offset, radius); hole(offset, -radius); }
}

// ==========================================================================
//  Geometry -- vX side tabs (rev 4; see header)
// --------------------------------------------------------------------------
//  Each tab: a flat rectangular footprint (tab_width wide, offset by x_off,
//  SAME x_off for both tabs), extruded from the cavity floor to the free
//  tip, INTERSECTED with a cylinder centred on the true cap axis so the
//  outer face follows the wall's own curvature:
//    RIB (Z: roof_t .. lip_z): clipped to r_outer_true (the true cavity
//        wall) -- matches the cap's own cavity radius there.
//    LIP (Z: lip_z .. tip_z):  clipped to r_wall_true (the true insert
//        outer wall) -- matches the insert body's own outer surface there,
//        continuing it flush past the lip with no step.
// The inner face is a flat plane at r_inner -- never clipped/curved, never
//  filleted -- straight from the tip down to taper_top_z (rev 16: the notch's
//  lower edge), then leaning outward by taper_loss down to the floor (roof_t). Only the two
//  OUTWARD vertical edges -- where each flat X-side wall meets the curved
//  outer surface, full height -- are filleted (tab_fillet_r); the floor
//  (bottom, Z) transition stays sharp. The wire-routing channel is cut
//  separately in the global difference() -- see cap_tab_wire_channels_vX().
// ==========================================================================
module cap_side_tabs_vX(r_inner, r_outer_true, r_wall_true, roof_t, lip_z, tip_z,
                        tab_width, axis, tab_fillet_r = 0, tab_side_offset = 0,
                        taper_top_z = 0, taper_loss = 0, fn = 48) {
    // Tab cross-section (2D, plan view), rounded only on its two OUTWARD
    // corners -- where the flat X-side edges meet the curved outer arc --
    // and only when fillet_on is true (the caller passes false for the rib
    // segment, which sits INSIDE the cap body; only the lip segment, which
    // sticks out past the cap, gets rounded). The outer boundary is a
    // CIRCLE, not a flat plane, so the true corner sits inset from
    // (x_side*tab_width/2, r_outer) along the arc -- not at that point
    // itself (a naive 3D corner cutter placed there misses the material
    // entirely, since the real edge is recessed). Standard erosion/regrowth
    // technique instead: shrink the X-sides and the circle by tab_fillet_r,
    // take their intersection (the eroded core), grow the whole thing back
    // out by tab_fillet_r via minkowski (this rounds every convex corner of
    // the eroded core with that radius), then re-clip the inner (r_inner)
    // edge back to a sharp flat line -- it was left unconstrained in the
    // core specifically so the regrowth can't push it outward, and this
    // final clip removes any bleed past it. Built for the sign>0
    // orientation (Y: r_inner .. r_outer); callers mirror for sign<0.
    module tab_profile_2d(x_off, r_outer, fillet_on, r_in = r_inner) {
        half_w = tab_width / 2;
        if (tab_fillet_r <= 0 || !fillet_on) {
            intersection() {
                translate([-half_w + x_off, r_in])
                    square([tab_width, r_outer]);
                circle(r = r_outer, $fn = fn);
            }
        } else {
            core_half_w = half_w - tab_fillet_r;
            core_r = r_outer - tab_fillet_r;
            intersection() {
                minkowski() {
                    intersection() {
                        translate([-core_half_w + x_off, r_in - 1000])
                            square([2 * core_half_w, 1000 + core_r]);
                        circle(r = core_r, $fn = fn);
                    }
                    circle(r = tab_fillet_r, $fn = fn);
                }
                translate([-half_w - 10 + x_off, r_in])
                    square([tab_width + 20, 10000]);
            }
        }
    }

    module one_tab(sign) {
        x_off = tab_side_offset;   // SAME for both tabs -- not mirrored
        // Small p_eps() overlap at the rib/lip seam (their cross-sections
        // differ -- r_outer_true vs r_wall_true -- so an exact shared Z
        // boundary between the two extrusions is a degenerate/non-manifold
        // coincident face; a hair of overlap avoids that, same as the
        // original intersection-based construction used).
        //
        // Rev 16: the inner face tapers. It sits at r_inner from taper_top_z
        // (the PCB-spacer notch's lower edge) up to the tip, and leans OUTWARD
        // (toward the cap wall) linearly going down, reaching
        // r_inner + taper_loss where the tab meets the cap surface (roof_t).
        function r_in_at(z) = (taper_loss <= 0 || z >= taper_top_z) ? r_inner
            : r_inner + taper_loss * (taper_top_z - z) / (taper_top_z - roof_t);
        // One Z-span of the tab. The profile is convex, so where the inner
        // face differs between the two ends a hull() of a thin slice at each
        // end is exactly the linear taper (outer arc + fillets are identical
        // in both slices and stay vertical); otherwise a plain extrusion.
        module slice(z, h, r_outer, fillet_on, r_in)
            translate([0, 0, z])
                linear_extrude(height = h)
                    mirror([0, sign > 0 ? 0 : 1, 0])
                        tab_profile_2d(x_off, r_outer, fillet_on, r_in);
        module segment(z0, z1, r_outer, fillet_on) {
            ra = r_in_at(z0);
            rb = r_in_at(z1);
            if (z1 - z0 > p_eps()) {
                if (abs(ra - rb) < 1e-6)
                    slice(z0 - p_eps(), z1 - z0 + 2 * p_eps(), r_outer, fillet_on, ra);
                else
                    hull() {
                        slice(z0 - p_eps(), p_eps(), r_outer, fillet_on, ra);
                        slice(z1, p_eps(), r_outer, fillet_on, rb);
                    }
            }
        }
        // Leg split at the taper top so the tapered and straight stretches
        // are each one linear piece.
        t_top = max(lip_z, min(tip_z, taper_top_z));
        union() {
            // r_outer_true here is the SAME radius cap_cavity_cut() uses for
            // its own wall (both derive from inner_top_od/2) -- unioning the
            // rib flush against that already-cut wall is an exact, zero-
            // clearance coincident surface, a degenerate case for the CSG
            // engine (non-manifold result even though nothing looks wrong).
            // + p_eps() here gives real overlap instead. The rib sits INSIDE
            // the cap body, so it stays sharp (fillet_on = false); only the
            // lip -- the part that sticks out past the cap -- gets rounded.
            segment(roof_t, lip_z, r_outer_true + p_eps(), false);
            segment(lip_z, t_top, r_wall_true, true);
            segment(t_top, tip_z, r_wall_true, true);
        }
    }

    base_rot = (axis == "x") ? 90 : 0;
    rotate([0, 0, base_rot]) { one_tab(1); one_tab(-1); }
}

// PCB-spacer notch -- vX: a rectangular notch cut into each tab's leg (the
// lip-extension portion beyond lip_z, i.e. the part that extends out past
// the cap's own body) to clear a brass circuit-board spacer. Starts
// notch_from_lip past the lip, cuts notch_depth radially in from the tab's
// inner face (r_inner), and runs notch_height further up the leg (toward
// the tip). Full tab width, same x_off slide as the rest of the tab.
module cap_tab_notches_vX(r_inner, lip_z, tab_width, axis, tab_side_offset,
                          notch_from_lip, notch_depth, notch_height) {
    z0    = lip_z + notch_from_lip;
    x_off = tab_side_offset;

    module one_notch(sign) {
        y0 = sign > 0 ? r_inner : -(r_inner + notch_depth);
        translate([-tab_width / 2 + x_off, y0, z0])
            cube([tab_width, notch_depth, notch_height]);
    }

    base_rot = (axis == "x") ? 90 : 0;
    rotate([0, 0, base_rot]) { one_notch(1); one_notch(-1); }
}

// Wire-routing channel, angled INWARD from the open entry -- FIXED at the
// tip, dead-centre in the tab's own material (entry_r = (r_inner +
// r_wall_true)/2, z = tip_z) -- down to a breakthrough point past the tab's
// own inner face, into the HOLLOW CAVITY below the lip. The entry never
// moves; it must always emerge dead-centre on the tab's flat tip (foot)
// face.
//
// exit_angle_deg is the slant, measured from VERTICAL (the tab's own axis),
// of the diagonal from the entry down to where it crosses r_inner -- the
// tab's own inner face, i.e. the actual VISIBLE breakthrough (everything
// past r_inner is already open/hollow, so that crossing point -- not some
// deeper point already in open space -- is what you actually see move):
//   break_z = tip_z - (entry_r - r_inner) / tan(exit_angle_deg)
// Small angle = steep/mostly-vertical descent (slow radial change, DEEPER
// immersion before break_z); large angle = shallow/mostly-horizontal
// descent (SHALLOWER). From there, a short horizontal stub (same z, no
// further angle influence) continues on to exit_r -- a full hole-diameter
// past r_inner -- purely to guarantee a clean full breakthrough rather than
// a knife-edge graze; it's already in open space, so it doesn't move the
// visible emergence point.
//
// When the PCB-spacer notch (cap_tab_notches_vX) is present, the angled
// portion must already be at a safe radius (clear of the notch's own
// removed band, with margin) by the time its z drops to the notch's own
// top face -- otherwise part of the still-high-radius run would fall
// inside the notch's z-band, right next to its already-thinned wall.
// control_cap() asserts/clamps this; see its wire_min_angle_notch.
module cap_tab_wire_channels_vX(r_inner, r_wall_true, r_outer_true,
                                tip_z, lip_z, tab_width, axis,
                                tab_side_offset, wire_hole_d,
                                exit_angle_deg, fn = 48) {
    entry_r = (r_inner + r_wall_true) / 2;   // fixed -- centred in the tip's own material, never moves
    break_z = tip_z - (entry_r - r_inner) / tan(exit_angle_deg);  // the visible breakthrough point
    exit_r  = max(0, r_inner - wire_hole_d); // a full diameter past the inner face -> guarantees full clearance
    x_off   = tab_side_offset;

    module one_channel(sign) {
        union() {
            hull() {
                translate([x_off, sign * entry_r, tip_z]) sphere(d = wire_hole_d, $fn = fn);
                translate([x_off, sign * r_inner, break_z]) sphere(d = wire_hole_d, $fn = fn);
            }
            hull() {
                translate([x_off, sign * r_inner, break_z]) sphere(d = wire_hole_d, $fn = fn);
                translate([x_off, sign * exit_r, break_z]) sphere(d = wire_hole_d, $fn = fn);
            }
        }
    }

    base_rot = (axis == "x") ? 90 : 0;
    rotate([0, 0, base_rot]) { one_channel(1); one_channel(-1); }
}

// ==========================================================================
//  control_cap -- vX (forked from lib/control_cap.scad; side_tabs always on)
// ==========================================================================
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
                   button_offset = 0,
                   band_enable   = true,
                   band_count    = undef,
                   band_z1       = p_seal_groove1_from_shoulder(),
                   band_z2       = p_seal_groove2_from_shoulder(),
                   band_depth    = p_seal_groove_radial_depth(),  // vX: also the O-ring groove's radius
                   oring_gland   = true,
                   oring_gland_od = p_cap_oring_gland_od(),
                   oring_gland_w  = p_cap_oring_gland_w(),
                   oring_gland_z  = p_cap_oring_gland_from_face(),
                   tab_width_p    = 21,
                   tab_wall_inset_p = 20,
                   tab_overhang_p = 14,
                   tab_fillet_p   = 0,
                   tab_side_offset_p = 0,
                   tab_taper_loss_p = 0,   // rev 16: inner face leans outward (toward the wall) this much at the cap surface
                   tab_wire_hole    = false,
                   tab_wire_hole_d  = 4,
                   tab_wire_hole_exit_angle = 45,
                   tab_notch        = false,
                   tab_notch_from_lip = 5,
                   tab_notch_depth  = 5,
                   tab_notch_height = 8,
                   etch_line       = false,
                   etch_line_w     = 0.6,
                   etch_line_d     = 0.2,
                   fn            = undef) {
    bc = band_count == undef ? p_seal_groove_count() : band_count;
    nn = fn == undef ? p_fn_plastic() : fn;
    inner_top_od = max(1, insert_od - 2 * insert_wall_t);

    // ---- vX tab geometry (see header) ----
    r_outer_true = inner_top_od / 2;   // true cavity wall radius -- rib's curved clip
    r_wall_true  = insert_od / 2;      // true insert outer wall radius -- lip's curved clip
    r_inner      = r_wall_true - tab_wall_inset_p;  // measured from the TRUE outer wall, not the cavity wall
    lip_z        = roof_t + insert_len;
    tip_z        = lip_z + tab_overhang_p;
    // Rev 16: the tab's inner face tapers from the PCB-spacer notch's lower
    // edge (the lip if the notch is off) down to the cap surface (roof_t),
    // leaning outward (toward the wall) by tab_taper_loss_p there. Notch and
    // leg above: straight.
    taper_top_z  = tab_notch ? lip_z + tab_notch_from_lip : lip_z;
    r_base_inner = r_inner + tab_taper_loss_p;

    // Wire channel angle clamp -- computed unconditionally (not just inside
    // an `if (tab_wire_hole)`) so the same clamped value reaches both the
    // warning echo and the actual cut below. The angle drives the diagonal
    // from the entry down to where it crosses r_inner (the visible
    // breakthrough -- see cap_tab_wire_channels_vX()); a short fixed
    // horizontal stub then continues on to wire_exit_r for full clearance,
    // so only the r_inner crossing matters for these minimums.
    wire_entry_r = (r_inner + r_wall_true) / 2;
    wire_exit_r  = max(0, r_inner - tab_wire_hole_d);
    // Floor: the r_inner crossing itself must stay inside the cap body.
    wire_min_angle_floor = atan((wire_entry_r - r_inner) / (tip_z - roof_t - 1));
    // Notch: the diagonal must already be at a safe radius (clear of the
    // notch's own removed band, by half the hole's own diameter) by the
    // time it crosses into the notch's z-band.
    wire_notch_safe_r = max(r_inner, r_inner + tab_notch_depth - tab_wire_hole_d / 2);
    wire_min_angle_notch = (tab_notch && wire_entry_r > wire_notch_safe_r)
        ? atan((wire_entry_r - wire_notch_safe_r) / (tip_z - (lip_z + tab_notch_from_lip + tab_notch_height)))
        : 0;
    wire_min_angle = max(wire_min_angle_floor, wire_min_angle_notch);
    wire_exit_angle_eff = max(tab_wire_hole_exit_angle, wire_min_angle);

    assert(disk_od > insert_od && insert_od > 2 * insert_wall_t);
    assert(roof_t > 0 && insert_len > chamfer_h && chamfer_h >= 0);
    assert(insert_wall_t > band_depth && band_depth > 0, "control_cap: vX -- O-ring groove radius (band_depth) must be positive and less than the insert wall thickness.");
    assert(bc >= 0 && bc <= 2);
    band_w = 2 * band_depth;  // vX: derived, not an independent input -- see header
    if (band_enable)
        for (z = bc == 2 ? [band_z1, band_z2] : bc == 1 ? [band_z1] : [])
            assert(z - band_w / 2 > 0 && z + band_w / 2 < insert_len - chamfer_h,
                   "control_cap: seal groove must stay inside the straight insert body.");
    if (band_enable && bc == 2)
        assert(abs(band_z2 - band_z1) > band_w, "control_cap: seal grooves overlap.");
    // vX: button holes can carry an off-axis offset (button_offset), so
    // clearance checks use the true centre-to-centre distance, not just
    // button_radius along the nominal axis.
    button_center_dist = sqrt(button_radius * button_radius + button_offset * button_offset);
    assert(axle_bore_d > 0 && button_center_dist - button_d / 2 > axle_bore_d / 2,
           "control_cap: button hole overlaps the centre axle bore -- increase button_radius/reduce button_d, or reduce button_offset.");
    assert(button_center_dist + button_d / 2 < disk_od / 2);
    assert(button_axis == "x" || button_axis == "y");
    assert(boss_depth > 0 && boss_depth < insert_len);
    assert(boss_d > axle_bore_d && boss_d < inner_top_od);
    assert(boss_d / 2 < button_center_dist - button_d / 2,
           "control_cap: centre boss must clear the button openings.");
    if (oring_gland) {
        assert(oring_gland_od > axle_bore_d && oring_gland_od < boss_d - 1,
               "control_cap: O-ring gland OD must sit between the bore and the boss wall.");
        assert(oring_gland_z - oring_gland_w / 2 > 0.5
               && oring_gland_z + oring_gland_w / 2 < roof_t + boss_depth - 0.5,
               "control_cap: O-ring gland + lands do not fit the axle bore column (deepen the boss or move the gland).");
    }
    assert(tab_wall_inset_p > 0 && tab_wall_inset_p < r_wall_true
           && r_inner > boss_d / 2,
           "control_cap: side tab wall inset must be positive, less than the true outer wall radius, and the resulting inner face must stay clear of the centre boss.");
    assert(tab_width_p > 0 && tab_width_p < inner_top_od,
           "control_cap: side tab width does not fit the cavity wall.");
    assert(tab_overhang_p > 0,
           "control_cap: side tab overhang must be positive.");
    assert(tab_taper_loss_p >= 0 && r_base_inner < r_outer_true,
           "control_cap: side tab taper loss must be non-negative and leave the tab's base inside the cavity wall.");
    // The button holes are cut through the roof only; a tab base that reaches
    // over a hole partly covers that opening from the inside. Flagged, not blocked.
    button_far_r = button_radius + button_d / 2;
    if (abs(button_offset) < tab_width_p / 2 + abs(tab_side_offset_p) && button_far_r > r_base_inner)
        echo(str("CAP vX WARNING: the tapered tab base (inner face r=", r_base_inner,
                 " at the cap surface) overhangs the button hole (outer edge r=", button_far_r,
                 ") by ", button_far_r - r_base_inner, " mm -- reduce hole_spacing_cc or increase tab_taper_loss."));
    assert(tab_fillet_p >= 0,
           "control_cap: side tab fillet radius cannot be negative.");
    // Not a hard assert: at tab_width/tab_side_offset combinations where the
    // far edge sits close to (or past) the cavity wall's own curve, the rib
    // (below the lip, clipped to the smaller r_outer_true) can legitimately
    // taper to a point and vanish before reaching the tab's nominal far
    // edge -- that's the curve genuinely "matching the wall," taken to its
    // extreme, not a broken shape (the lip extension above, clipped to the
    // larger r_wall_true, is unaffected). Flagged, not blocked.
    tab_x_far = tab_width_p / 2 + abs(tab_side_offset_p);
    rib_far_edge_reach = sqrt(max(0, r_outer_true * r_outer_true - tab_x_far * tab_x_far));
    if (rib_far_edge_reach <= r_base_inner)
        echo(str("CAP vX WARNING: the rib's far edge (below the lip) vanishes to a point ",
                 "before reaching its nominal width -- tab_width/tab_side_offset put it ",
                 "past the cavity wall's own curve there (far-edge reach ", rib_far_edge_reach,
                 " mm <= tab base inner face ", r_base_inner, " mm). The lip extension above is unaffected."));
    if (tab_wire_hole) {
        assert(tab_wire_hole_d > 0, "control_cap: wire hole diameter must be positive.");
        assert(tab_wire_hole_exit_angle > 0 && tab_wire_hole_exit_angle < 90,
               "control_cap: wire hole exit angle must be between 0 and 90 degrees (exclusive) -- measured from vertical.");
        // Below wire_min_angle_floor the diagonal would run past the cap's
        // own floor; below wire_min_angle_notch (when a notch is present)
        // it would still be near entry_r when crossing the notch's z-band,
        // cutting fresh wall beside it. Rather than fail the render on every
        // small tweak, wire_exit_angle_eff (computed above) already clamps
        // UP to whichever minimum applies -- just warn here, don't block.
        if (wire_exit_angle_eff != tab_wire_hole_exit_angle)
            echo(str("CAP vX WARNING: tab_wire_hole_exit_angle (", tab_wire_hole_exit_angle,
                     " deg) is below the minimum ", wire_min_angle, " degrees ",
                     tab_notch && wire_min_angle_notch >= wire_min_angle_floor
                         ? "(would cut into the PCB-spacer notch's own z-band)"
                         : "(would run the flue past the cap's own floor)",
                     " -- clamped to ", wire_exit_angle_eff, " degrees instead of cutting bad geometry."));
    }
    if (etch_line)
        assert(etch_line_d > 0 && etch_line_d < roof_t,
               "control_cap: etch line depth must be positive and less than the roof thickness.");
    if (tab_notch) {
        assert(tab_notch_depth > 0 && tab_notch_depth < r_wall_true - r_inner,
               "control_cap: tab notch depth must be positive and less than the leg's radial thickness (r_wall_true - r_inner).");
        assert(tab_notch_from_lip >= 0 && tab_notch_height > 0
               && tab_notch_from_lip + tab_notch_height <= tip_z - lip_z,
               "control_cap: tab notch must land within the leg (the tab length beyond the lip).");
    }

    $fn = nn;
    difference() {
        union() {
            difference() {
                cap_plug_outer(disk_od, roof_t, insert_len, insert_od,
                               chamfer_h, chamfer_delta,
                               band_enable, bc, band_z1, band_z2, band_depth, nn);
                cap_cavity_cut(roof_t, insert_len, insert_od, insert_wall_t,
                               chamfer_h, chamfer_delta);
            }
            translate([0, 0, roof_t - 2 * p_eps()])
                cylinder(d = boss_d, h = boss_depth + 2 * p_eps());
            cap_side_tabs_vX(r_inner, r_outer_true, r_wall_true, roof_t, lip_z, tip_z,
                             tab_width_p, button_axis, tab_fillet_p, tab_side_offset_p,
                             taper_top_z, tab_taper_loss_p, nn);
        }
        translate([0, 0, -p_eps()])
            cylinder(h = roof_t + boss_depth + 2 * p_eps(), d = axle_bore_d);
        if (oring_gland)
            translate([0, 0, oring_gland_z - oring_gland_w / 2])
                rotate_extrude($fn = nn)
                    translate([axle_bore_d / 2 - p_eps(), 0])
                        square([oring_gland_od / 2 - axle_bore_d / 2 + p_eps(),
                                oring_gland_w]);
        cap_button_holes_cut(roof_t, button_d, button_axis, button_radius, button_offset);
        if (etch_line)
            cap_axis_etch_line_vX(r_outer_true, roof_t, etch_line_w, etch_line_d, button_axis);
        if (tab_wire_hole)
            cap_tab_wire_channels_vX(r_inner, r_wall_true, r_outer_true,
                                     tip_z, lip_z, tab_width_p, button_axis,
                                     tab_side_offset_p, tab_wire_hole_d,
                                     wire_exit_angle_eff, nn);
        if (tab_notch)
            cap_tab_notches_vX(r_inner, lip_z, tab_width_p, button_axis, tab_side_offset_p,
                               tab_notch_from_lip, tab_notch_depth, tab_notch_height);
    }

    echo("CAP vX: disk / insert dia / total height = ",
         disk_od, insert_od, roof_t + insert_len);
    echo("CAP vX: roof / boss depth / axle bearing length = ",
         roof_t, boss_depth, roof_t + boss_depth);
    echo("CAP vX: buttons -- dia ", button_d, ", nominal radius ", button_radius,
         ", off-axis offset ", button_offset, " (same direction, not mirrored) -> true centre dist ",
         button_center_dist, " mm, centre-to-centre spacing ", 2 * button_radius,
         " mm along the axis, ", 2 * button_center_dist, " mm true straight-line.");
    if (oring_gland)
        echo("CAP vX: axle O-ring gland -- bore ", axle_bore_d, " -> groove OD ",
             oring_gland_od, " x ", oring_gland_w, " wide, centred ", oring_gland_z,
             " mm below the outer face. Seals a ", p_axle_oring_cs(),
             " mm-CS O-ring (ID ", p_axle_oring_id(), ") on the axle round section.");
    if (band_enable)
        echo("CAP vX: ", bc, " insert-wrap O-ring groove(s) -- SEMICIRCULAR, radius ", band_depth,
             " mm (= depth), open width ", band_w,
             " mm at the true surface -> holds a round-section O-ring of dia ", band_w,
             " mm with half its thickness proud of the surface, wrapping the full ",
             insert_od, " mm insert diameter.");
    echo("CAP vX: side tabs -- width ", tab_width_p, ", inner face straight at r_inner=", r_inner,
         " (= r_wall_true ", r_wall_true, " - tab_wall_inset_p ", tab_wall_inset_p, ")",
         "; outer face CURVED, clipped to r_outer_true=", r_outer_true,
         " below the lip and r_wall_true=", r_wall_true, " above it",
         "; floor to lip+overhang height ", tip_z - roof_t, " mm, ", tab_fillet_p,
         " mm outward-edge fillet, on the ", button_axis,
         " axis, BOTH tabs slid ", tab_side_offset_p, " mm the same direction (no rotation, not mirrored).");
    if (tab_taper_loss_p > 0)
        echo("CAP vX: tab taper -- inner face straight at r=", r_inner, " from the tip down to z=", taper_top_z,
             tab_notch ? " (PCB-spacer notch lower edge)" : " (lip)",
             ", then leans outward ", tab_taper_loss_p, " mm to r=", r_base_inner,
             " at the cap surface (z=", roof_t, ").");
    if (tab_wire_hole) {
        echo_break_z = tip_z - (wire_entry_r - r_inner) / tan(wire_exit_angle_eff);
        echo("CAP vX: tab wire channel -- ", tab_wire_hole_d,
             " mm dia, entry FIXED at the tip (z=", tip_z, ", r=", wire_entry_r,
             ", centred in the tab's own material -- always the centre of the tab's flat tip face);",
             " slants down at ", wire_exit_angle_eff, " deg from vertical, immersing ",
             tip_z - echo_break_z, " mm before crossing r_inner (the visible breakthrough, z=",
             echo_break_z, ") then a short horizontal stub on to exit radius ", wire_exit_r,
             " mm into the HOLLOW CAVITY.");
    }
    if (tab_notch)
        echo("CAP vX: tab PCB-spacer notch -- ", tab_notch_depth, " mm deep x ",
             tab_notch_height, " mm tall x ", tab_width_p, " mm wide, starting ",
             tab_notch_from_lip, " mm past the lip (z = ", lip_z + tab_notch_from_lip,
             " to ", lip_z + tab_notch_from_lip + tab_notch_height,
             "), cut into the leg's inner face from r_inner=", r_inner, " out to ",
             r_inner + tab_notch_depth, " mm.");
    if (etch_line)
        echo("CAP vX: reference etch line -- ", etch_line_w, " x ", etch_line_d,
             " mm groove on the cavity ceiling, spanning the full ", 2 * r_outer_true,
             " mm cavity diameter along the ", button_axis,
             " axis -- passes through the centre bore and both button centres.");
}

color([0.74, 0.77, 0.79])
control_cap(roof_t        = top_disk_thickness,
            boss_d        = centre_boss_diameter,
            boss_depth    = centre_boss_depth,
            insert_len    = insert_total_h,
            insert_wall_t = cup_wall_thickness,
            chamfer_h     = entry_chamfer_h,
            chamfer_delta = entry_chamfer_delta,
            axle_bore_d   = shaft_hole_d,
            button_d      = button_upper_d,
            button_axis   = button_axis,
            button_radius = hole_spacing_cc,
            button_offset = button_axis_offset,
            band_enable   = band_channels_enable,
            band_count    = band_count,
            band_z1       = band1_center_z_local,
            band_z2       = band2_center_z_local,
            band_depth    = band_channel_depth,
            oring_gland    = oring_gland_enable,
            oring_gland_od = oring_gland_od,
            oring_gland_w  = oring_gland_width,
            oring_gland_z  = oring_gland_from_face,
            tab_width_p    = tab_width,
            tab_wall_inset_p = tab_inner_wall_distance,
            tab_overhang_p = tab_top_overhang,
            tab_fillet_p   = tab_corner_fillet,
            tab_side_offset_p = tab_side_offset,
            tab_taper_loss_p = tab_taper_loss,
            tab_wire_hole    = tab_wire_hole_enable,
            tab_wire_hole_d  = tab_wire_hole_diameter,
            tab_wire_hole_exit_angle = tab_wire_hole_exit_angle,
            tab_notch        = tab_notch_enable,
            tab_notch_from_lip = tab_notch_from_lip,
            tab_notch_depth  = tab_notch_depth,
            tab_notch_height = tab_notch_height,
            etch_line       = etch_line_enable,
            etch_line_w     = etch_line_width,
            etch_line_d     = etch_line_depth,
            fn            = fn);
