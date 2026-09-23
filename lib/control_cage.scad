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

use <params.scad>

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
