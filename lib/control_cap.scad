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

use <params.scad>
use <util.scad>

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
