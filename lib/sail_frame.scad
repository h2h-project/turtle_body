// ==========================================================================
//  Turtle Body -- sail apparatus frame  (lib module)
// --------------------------------------------------------------------------
//  Wooden frame only: top crossbar, four battens (two sail, two non-sail),
//  bottom sail bars, joint strengtheners, orange C ends and the sail
//  membranes. Emits NO cap, cage, axle or bottle. See CLAUDE.md s10.
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

use <params.scad>
use <util.scad>

module sf_wood(coded_color, colored = true)
    color(colored ? coded_color : [0.94, 0.83, 0.62]) children();

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
    show_hardware = true
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
    top_sail_bar_axle_hole_diameter = 12;

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
    // CONTROL AXLE
    // ============================================================
    round_shaft_diameter   = 8.0;
    round_shaft_length     = 30.0;  // length inside the cap cavity
    round_shaft_extension_above_cap = 1.0;
    // Ø12 mm bar hole fit: 10 mm AF = 11.55 mm across corners.
    hex_shaft_across_flats = 10.0;
    hex_shaft_length       = 23.0; // Adds 3 mm for the thicker sine-cage roof
    joining_overlap        = 0.2;

    // OpenSCAD measures a six-sided cylinder across its corners.
    hex_corner_diameter =
        hex_shaft_across_flats / cos(30);

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

    cage_surface_thickness = 6;
    cage_side_wall_thickness = 6.5;

    // Preserve 1 mm radial running clearance around the top disk.
    control_cap_to_cage_diametral_clearance = 2;
    cage_inner_cavity_diameter =
        control_cap_diameter
        + control_cap_to_cage_diametral_clearance;

    cage_outer_diameter =
        cage_inner_cavity_diameter
        + 2 * cage_side_wall_thickness;

    cage_centre_hex_across_flats = 10.3;
    cage_centre_hex_wall_height = 3.5;
    cage_centre_hex_wall_thickness = 3;

    cage_top_hole_diameter = 18;
    cage_top_hole_angle = cage_button_angle;

    cage_bearing_diameter = 9;
    cage_bearing_count = 8;
    cage_bearing_contact_edge_overhang = 0.25;
    cage_bearing_pcd =
        control_cap_diameter
        - cage_bearing_diameter
        + 2 * cage_bearing_contact_edge_overhang;

    cage_total_height = 50; // 44 mm original skirt + 6 mm roof
    cage_hub_diameter = 29;
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
    cage_centre_hex_outer_across_flats =
        cage_centre_hex_across_flats
        + 2 * cage_centre_hex_wall_thickness;
    cage_centre_hex_corner_diameter =
        cage_centre_hex_across_flats / cos(30);
    cage_centre_hex_outer_corner_diameter =
        cage_centre_hex_outer_across_flats / cos(30);

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
    assert(cage_surface_thickness > cage_clip_pocket_depth
           && cage_hub_diameter > cage_clip_pocket_diameter
           && cage_clip_pocket_diameter > cage_centre_hex_corner_diameter);
    assert(cage_top_hole_radial_position - cage_top_hole_diameter/2
           > cage_hub_diameter/2);
    assert(cage_top_hole_radial_position + cage_top_hole_diameter/2
           < cage_bearing_pcd/2 - cage_bearing_diameter/2);
    assert(round_shaft_extension_above_cap + hex_shaft_length
           > cage_bearing_diameter/2 + cage_surface_thickness + top_sail_bar_thickness,
           "Hex shaft must reach through the roof and sail bar.");

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
    assert(cage_centre_hex_wall_height > 0
           && cage_centre_hex_wall_thickness > 0,
        "The cage central reinforcing-wall dimensions must be positive.");
    assert(cage_centre_hex_outer_corner_diameter / 2
           < cage_inner_cavity_radius,
        "The cage central reinforcing wall does not fit.");
    assert(cage_top_hole_radial_position
           > cage_centre_hex_outer_corner_diameter / 2
           + cage_top_hole_diameter / 2,
        "The cage top hole overlaps the central reinforcing wall.");
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
    assert(cage_centre_hex_across_flats < top_sail_bar_width,
        "The axle opening does not fit within the top sail bar.");
    assert(hex_corner_diameter < top_sail_bar_axle_hole_diameter,
        "The hex shaft does not fit through the sail bar axle hole.");
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

            // Complementary half-lap for the 90-degree strengthener slat.
            translate([
                joint_strengthener_rail_slot_offset,
                slot_y,
                -cage_epsilon
            ])
                cube([
                    joint_strengthener_thickness,
                    bottom_sail_bar_slot_depth + cage_epsilon,
                    bottom_sail_bar_thickness + 2 * cage_epsilon
                ]);
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
            // while the 24 mm face width runs tangentially in Y.
            cube([
                joint_strengthener_thickness,
                joint_strengthener_width,
                joint_strengthener_height
            ]);

            // 12 mm deep × one-board-thickness-high slot from the PNG.
            translate([
                -cage_epsilon,
                0,
                joint_strengthener_below_bar
            ])
                cube([
                    joint_strengthener_thickness + 2 * cage_epsilon,
                    joint_strengthener_slot_depth,
                    joint_strengthener_slot_height
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
            bottom_bar_z - joint_strengthener_below_bar;

        strengthener_inner_x =
            top_sail_bar_slot_centre_radius
            + side_batten_thickness / 2;

        sf_wood([0.35, 0.92, 0.34], colored) {
            // Right joint: rotated slat sits radially flush beside the batten.
            translate([
                strengthener_inner_x,
                -joint_strengthener_width / 2,
                strengthener_z
            ])
                joint_strengthener_part();

            // Left joint: identical mirrored half-lap arrangement.
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
        translate([0, sail_thickness / 2, 0])
            rotate([90, 0, 0])
                linear_extrude(height = sail_thickness)
                    polygon(points = [
                        [sail_inner_radius, sail_bottom_z],
                        [sail_bottom_outer_radius, sail_bottom_z],
                        [sail_top_outer_radius, sail_top_z],
                        [sail_inner_radius, sail_top_z]
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
