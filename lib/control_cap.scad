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
}
