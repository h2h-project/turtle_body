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
water_transparency = 0.30; // 30% transparent = alpha 0.70; increase for a clearer view.

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

bottle_diameter      = 82;
bottle_height        = 305;

cap_diameter         = 31;
cap_height           = 17;

// User-set collar diameter.
// This is intentionally independent of cap diameter.
collar_diameter      = 34;

top_dome_height      = 62;
bottom_dome_height   = 25;


// Shared stock / fin-system variables.
fin_board_width       = 93;
solar_panel_width     = 148; // Rear panel: across the red crossbar (local Y)
solar_panel_height    = 223; // Rear panel: forward length (local X)
solar_panel_thickness = 2.5; // Panel only; wooden stock uses slat_thickness

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
// SUPERELLIPSE DOME FUNCTIONS
// ============================================================================
//
// TOP:
// t = 0 at full bottle body
// t = 1 at neck
//
// For dome_power > 2, the bottle stays near full diameter longer,
// then rounds inward more strongly near the neck.
//
function top_superellipse_radius(t, body_r, neck_r, p = dome_power) =
    neck_r
    + (body_r - neck_r)
      * pow(max(0, 1 - pow(t, p)), 1 / p);


//
// BOTTOM:
// Outward-puffing transition from the narrower base to the full body.
// The curvature is oriented so it reaches the cylindrical body with a
// smooth, broad shoulder instead of curling inward near the body.
//
// t = 0 at the narrower base
// t = 1 at full body diameter
//
function bottom_superellipse_radius(t, base_r, body_r, p = dome_power) =
    base_r
    + (body_r - base_r)
      * pow(
            max(0, 1 - pow(1 - t, p)),
            1 / p
        );


// ============================================================================
// LIGHTWEIGHT ROTATIONAL PROFILES
// ============================================================================

// Shared material selector for wooden geometry only.
module wood_color(coded_color) {
    color(enable_color_coding ? coded_color : [0.94, 0.83, 0.62])
        children();
}

module top_superellipse_dome(
    h,
    body_d,
    neck_d,
    steps = profile_steps
) {

    body_r = body_d / 2;
    neck_r = neck_d / 2;

    rotate_extrude(convexity = 4)
        polygon(points =
            concat(
                [[0, 0]],
                [
                    for (i = [0 : steps])
                        let(
                            t = i / steps,
                            z = h * t,
                            r = top_superellipse_radius(
                                t,
                                body_r,
                                neck_r
                            )
                        )
                        [r, z]
                ],
                [[0, h]]
            )
        );
}


module bottom_superellipse_dome(
    h,
    base_d,
    body_d,
    steps = profile_steps
) {

    base_r = base_d / 2;
    body_r = body_d / 2;

    rotate_extrude(convexity = 4)
        polygon(points =
            concat(
                [[0, 0]],
                [
                    for (i = [0 : steps])
                        let(
                            t = i / steps,
                            z = h * t,
                            r = bottom_superellipse_radius(
                                t,
                                base_r,
                                body_r
                            )
                        )
                        [r, z]
                ],
                [[0, h]]
            )
        );
}


// ============================================================================
// BOTTLE BODY
// ============================================================================

module bottle_body() {

    // 60% transparent => alpha 0.40.
    color("cyan", 0.40)
    union() {

        // Bottom outward superellipse dome.
        bottom_superellipse_dome(
            h = bottom_dome_height,
            base_d = bottom_base_diameter,
            body_d = bottle_diameter
        );

        // Straight central body.
        translate([0, 0, body_z0])
            cylinder(
                h = straight_body_height,
                d = bottle_diameter,
                $fn = 48
            );

        // Top superellipse dome.
        translate([0, 0, top_dome_z0])
            top_superellipse_dome(
                h = top_dome_height,
                body_d = bottle_diameter,
                neck_d = bottle_neck_diameter
            );

        // Hard-coded 5 mm bottle neck.
        translate([0, 0, neck_z0])
            cylinder(
                h = bottle_neck_height,
                d = bottle_neck_diameter,
                $fn = 36
            );
    }
}


// ============================================================================
// COLLAR
// ============================================================================

module bottle_collar() {

    color([0, 1, 1, 0.90])
        translate([0, 0, collar_z0])
            cylinder(
                h = collar_height,
                d = collar_diameter,
                $fn = 36
            );
}


// ============================================================================
// SIMPLE SOLID CAP
// ============================================================================

module bottle_cap() {

    color("blue")
        translate([0, 0, cap_z0])
            cylinder(
                h = cap_height,
                d = cap_diameter,
                $fn = 36
            );
}


// ============================================================================
// COMPLETE BOTTLE
// ============================================================================

module parametric_bottle() {
    bottle_body();
    bottle_collar();
    bottle_cap();
}

// canonical bottle rendered by assembly below


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

module top_slot(center_x, depth) {
    translate([
        center_x - slot_width / 2,
        john_height - depth
    ])
        square([
            slot_width,
            depth + 1
        ]);
}


module center_hole(diameter) {
    translate([
        john_length / 2,
        john_height / 2
    ])
        circle(d = diameter);
}


module screw_holes_2d() {
    translate([
        screw_side_offset,
        screw_y_center
    ])
        circle(d = screw_diameter);

    translate([
        john_length - screw_side_offset,
        screw_y_center
    ])
        circle(d = screw_diameter);
}


// ============================================================================
// JOHN PROFILES
// ============================================================================

module long_john_2d() {
    difference() {
        square([
            john_length,
            john_height
        ]);

        top_slot(
            long_end_span + slat_thickness / 2,
            standard_slot_depth
        );

        top_slot(
            john_length
            - long_end_span
            - slat_thickness / 2,
            standard_slot_depth
        );

        center_hole(ecojoiner_cap_diameter);
    }
}


module little_john_2d() {
    difference() {
        square([
            john_length,
            john_height
        ]);

        top_slot(
            little_end_span + slat_thickness / 2,
            standard_slot_depth
        );

        top_slot(
            john_length
            - little_end_span
            - slat_thickness / 2,
            standard_slot_depth
        );

        center_hole(collar_diameter);
        screw_holes_2d();
    }
}


// ============================================================================
// 3D PARTS
// ============================================================================

module long_john() {
    wood_color("yellow")
        linear_extrude(height = slat_thickness)
            long_john_2d();
}


module little_john() {
    wood_color("seagreen")
        linear_extrude(height = slat_thickness)
            little_john_2d();
}


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

module final_key() {
    wood_color([0.82, 0.78, 0.05])
        cube([
            final_key_length,
            final_key_width,
            slat_thickness
        ]);
}


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

module presser() {
    wood_color([0.10, 0.34, 0.20])
        difference() {
            cylinder(
                d = presser_diameter,
                h = slat_thickness
            );

            translate([0, 0, -0.1])
                cylinder(
                    d = presser_through_hole_diameter,
                    h = slat_thickness + 0.2
                );
        }
}

// Same simple M6 appearance as the cage bolts: no threads or nuts.
// Local Z=0 is the underside of the head; the shaft runs toward +Z.
module m6_bolt_placeholder(grip_length, tip_extension = 1) {
    shaft_diameter = 6;
    head_diameter = 12;
    head_thickness = 4;
    assert(grip_length > 0, "M6 bolt grip length must be positive.");
    color([0.15, 0.15, 0.15]) // Opaque, 85% toward black.
        union() {
            cylinder(d = shaft_diameter,
                     h = grip_length + tip_extension, $fn = 48);
            translate([0, 0, -head_thickness])
                cylinder(d = head_diameter, h = head_thickness, $fn = 48);
        }
}

module presser_with_m6_bolt() {
    // Presser occupies Z=0..t; its matching John occupies Z=-t..0.
    // The head rests against the outside John face at Z=-t.
    presser();
    translate([0, 0, -slat_thickness])
        m6_bolt_placeholder(grip_length = 2 * slat_thickness);
}


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

module standing_little_john(target_y = 0, inside_sign = 1,
                            suppress_far_hole_presser = false,
                            suppress_near_hole_presser = false) {

    // The John itself.
    multmatrix([
        [1, 0, 0, 0],
        [0, 0, 1, target_y - slat_thickness / 2],
        [0, 1, 0, 0],
        [0, 0, 0, 1]
    ])
        little_john();


    // ------------------------------------------------------------
    // Two Pressers on the INNER face of this Little John.
    // ------------------------------------------------------------
    //
    // Each Presser axis is normal to the John face, and its through
    // hole is exactly coaxial with the corresponding John through hole.
    //
    // inside_sign:
    //   +1 -> inside points toward +Y
    //   -1 -> inside points toward -Y

    inner_face_y =
        target_y + inside_sign * slat_thickness / 2;

    for (hole_x = [
        screw_side_offset,
        john_length - screw_side_offset
    ]) {

        show_this_presser =
            !(suppress_far_hole_presser &&
              hole_x > john_length / 2)
            &&
            !(suppress_near_hole_presser &&
              hole_x < john_length / 2);

        if (show_this_presser && inside_sign > 0) {
            translate([
                hole_x,
                inner_face_y,
                screw_y_center
            ])
                rotate([-90, 0, 0])
                    presser_with_m6_bolt();
        }
        else if (show_this_presser) {
            translate([
                hole_x,
                inner_face_y,
                screw_y_center
            ])
                rotate([90, 0, 0])
                    presser_with_m6_bolt();
        }
        else {
            // These four excluded pressers are replaced by the two rear-fin
            // and two ballast slats. Use the same John-hole axis and head seat.
            translate([hole_x, inner_face_y, screw_y_center])
                rotate([inside_sign > 0 ? -90 : 90, 0, 0])
                    translate([0, 0, -slat_thickness])
                        m6_bolt_placeholder(grip_length = 2 * slat_thickness);
        }
    }
}


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

module standing_flipped_long_john(target_x = 0) {

    long_origin_y =
        long_slot_2_x;

    multmatrix([
        [0, 0, 1, target_x - slat_thickness / 2],
        [-1, 0, 0, long_origin_y],
        [0, -1, 0, john_height],
        [0, 0, 0, 1]
    ])
        long_john();
}


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

module john_rectangle(suppress_positive_port_pressers = false,
                      suppress_negative_port_pressers = false) {

    // Little John — near side
    standing_little_john(
        0,
        +1,
        suppress_positive_port_pressers,
        suppress_negative_port_pressers
    );

    // Little John — far side
    standing_little_john(
        rectangle_y,
        -1,
        suppress_positive_port_pressers,
        suppress_negative_port_pressers
    );

    // Long John — left side
    standing_flipped_long_john(little_slot_1_x);

    // Long John — right side
    standing_flipped_long_john(little_slot_2_x);
}


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

module centered_rectangle(rot = [0, 0, 0],
                          suppress_positive_port_pressers = false,
                          suppress_negative_port_pressers = false) {

    translate(frame_center)
        rotate(rot)
            translate([
                -frame_center[0],
                -frame_center[1],
                -frame_center[2]
            ])
                john_rectangle(
                    suppress_positive_port_pressers,
                    suppress_negative_port_pressers
                );
}


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

module inserted_final_key(x_offset, z_offset) {

    translate([
        frame_center[0] + x_offset - final_key_width / 2,
        frame_center[1] - final_key_length / 2,
        frame_center[2] + z_offset - slat_thickness / 2
    ])
        // Rotated 90 degrees about the key's long axis.
        //
        // Mapping:
        // local X (length)    -> world Y
        // local Y (24 width)  -> world X
        // local Z (12 thick)  -> world Z
        //
        // End-on appearance is therefore 24 mm wide x 12 mm high,
        // matching the four rectangular gaps between the Johns.
        multmatrix([
            [0, 1, 0, 0],
            [1, 0, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ])
            final_key();
}


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

module ballast_core_profile_2d() {

    polygon(points=[
        [0, 0],
        [ballast_core_width, 0],
        [ballast_core_width, ballast_core_height],
        [0, ballast_core_height],
        [0, ballast_upper_diagonal_start],
        [ballast_shoulder_step, ballast_upper_neck_start],
        [ballast_shoulder_step, ballast_lower_neck_start],
        [0, ballast_lower_full_return],
        [0, ballast_core_slot_z1],
        [ballast_core_slot_depth, ballast_core_slot_z1],
        [ballast_core_slot_depth, ballast_core_slot_z0],
        [0, ballast_core_slot_z0]
    ]);
}


module ballast_core_slat_part() {
    wood_color([0.12, 0.38, 0.20])
        linear_extrude(height = slat_thickness)
            difference() {
                ballast_core_profile_2d();

                // Through hole aligned with the Little John M6 mounting hole.
                translate([
                    ballast_core_mount_hole_x,
                    ballast_core_mount_hole_y
                ])
                    circle(
                        d = ballast_core_mount_hole_diameter,
                        $fn = 48
                    );
            }
}


module ballast_bottom_board_part() {

    wood_color([0.90, 0.38, 0.06])
    linear_extrude(height = slat_thickness)
    difference() {

        square([
            ballast_board_length,
            ballast_board_width
        ]);

        translate([
            ballast_left_slot - ballast_board_slot_width/2,
            -0.01
        ])
            square([
                ballast_board_slot_width,
                ballast_board_slot_depth + 0.01
            ]);

        translate([
            ballast_center_slot - ballast_board_slot_width/2,
            -0.01
        ])
            square([
                ballast_board_slot_width,
                ballast_center_slot_depth + 0.01
            ]);

        translate([
            ballast_right_slot - ballast_board_slot_width/2,
            -0.01
        ])
            square([
                ballast_board_slot_width,
                ballast_board_slot_depth + 0.01
            ]);

        translate([
            ballast_left_end_slot_x0,
            ballast_board_width - ballast_board_slot_depth
        ])
            square([
                ballast_board_slot_width,
                ballast_board_slot_depth + 0.01
            ]);

        translate([
            ballast_right_end_slot_x0,
            ballast_board_width - ballast_board_slot_depth
        ])
            square([
                ballast_board_slot_width,
                ballast_board_slot_depth + 0.01
            ]);
    }
}


module ballast_lock_profile_2d() {

    lock_slot_y0 =
        (ballast_lock_height - ballast_lock_slot_height) / 2;

    lock_slot_y1 =
        lock_slot_y0 + ballast_lock_slot_height;

    polygon(points=[
        [0, 0],
        [ballast_lock_width - ballast_lock_chamfer, 0],
        [ballast_lock_width, ballast_lock_chamfer],
        [ballast_lock_width,
         ballast_lock_height - ballast_lock_chamfer],
        [ballast_lock_width - ballast_lock_chamfer,
         ballast_lock_height],
        [0, ballast_lock_height],
        [0, lock_slot_y1],
        [ballast_lock_slot_depth, lock_slot_y1],
        [ballast_lock_slot_depth, lock_slot_y0],
        [0, lock_slot_y0]
    ]);
}


module ballast_lock_part() {
    wood_color([0.70, 0.12, 0.10])
        linear_extrude(height = ballast_lock_thickness)
            ballast_lock_profile_2d();
}


module ballast_fin_profile_2d() {

    fin_slot_z0 =
        ballast_fin_lower_protrusion;

    difference() {

        polygon(points=[
            [ballast_fin_front_chamfer, 0],
            [ballast_fin_length, 0],
            [ballast_fin_length, ballast_fin_height],
            [0, ballast_fin_height],
            [0, ballast_fin_front_chamfer]
        ]);

        translate([
            -0.01,
            fin_slot_z0
        ])
            square([
                ballast_fin_slot_depth + 0.01,
                ballast_fin_slot_height
            ]);

        translate([
            -0.01,
            ballast_fin_upper_cut_z0
        ])
            square([
                ballast_fin_upper_cut_depth + 0.01,
                ballast_fin_height
                - ballast_fin_upper_cut_z0
                + 0.01
            ]);
    }
}


module ballast_fin_part() {
    wood_color([0.95, 0.72, 0.02])
        linear_extrude(height = ballast_fin_thickness)
            ballast_fin_profile_2d();
}


// ============================================================================
// BALLAST LOCAL ASSEMBLY
// ============================================================================

module ballast_installed_green_slat(slot_center_x) {

    multmatrix([
        [0, 0, 1,
         slot_center_x - slat_thickness/2],
        [-1, 0, 0,
         ballast_core_width],
        [0, 1, 0,
         -ballast_core_slot_z0],
        [0, 0, 0, 1]
    ])
        ballast_core_slat_part();
}


module ballast_installed_lock(slot_x0) {

    lock_center_x =
        slot_x0 + ballast_board_slot_width/2;

    board_slot_inner_y =
        ballast_board_width - ballast_board_slot_depth;

    lock_origin_y =
        board_slot_inner_y - ballast_lock_slot_depth;

    lock_slot_y0 =
        (ballast_lock_height - ballast_lock_slot_height) / 2;

    multmatrix([
        [0, 0, 1,
         lock_center_x - ballast_lock_thickness/2],
        [1, 0, 0,
         lock_origin_y],
        [0, 1, 0,
         -lock_slot_y0],
        [0, 0, 0, 1]
    ])
        ballast_lock_part();
}


// Inspection control for the yellow ballast fin.
//
// Pull the fin completely out of its mating slot in the OPPOSITE direction
// so both the FULL fin shape and the orange ballast-board slot/surface can be
// inspected independently.
//
// Set this back to 0 when we are ready to re-seat the fin.
ballast_fin_inspection_pullout = 0;

module ballast_installed_fin() {

    // Equal slot engagement:
    // orange slot depth + yellow slot depth puts the two slot tips
    // exactly together at the joint mid-plane.
    fin_origin_y =
        ballast_center_slot_depth
        + ballast_fin_slot_depth
        + ballast_fin_inspection_pullout;

    multmatrix([
        [0, 0, 1,
         ballast_center_slot - ballast_fin_thickness/2],
        [-1, 0, 0,
         fin_origin_y],
        [0, 1, 0,
         -ballast_fin_lower_protrusion],
        [0, 0, 0, 1]
    ])
        ballast_fin_part();
}


module local_ballast_assembly() {

    ballast_bottom_board_part();

    ballast_installed_lock(
        ballast_left_end_slot_x0
    );

    ballast_installed_lock(
        ballast_right_end_slot_x0
    );

    ballast_installed_green_slat(
        ballast_left_slot
    );

    ballast_installed_green_slat(
        ballast_right_slot
    );

    ballast_installed_fin();
}


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
                        local_ballast_assembly();
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

module rear_fin_part() {

    wood_color([1.0, 0.72, 0.05])
    rotate([90, 0, 0])
    linear_extrude(
        height = rear_fin_thickness,
        center = true
    )
    difference() {

        polygon(points=[
            [0, rear_fin_diagonal_rise],
            [rear_fin_diagonal_run, 0],
            [rear_fin_width, 0],
            [rear_fin_width, rear_fin_height],
            [0, rear_fin_height]
        ]);

        // Open FRONT slots. Width clearance is centered on each green board.
        for (joint_z = [rear_fin_upper_joint_z0, rear_fin_lower_joint_z0])
            translate([
                -rear_boolean_epsilon,
                joint_z - rear_half_lap_clearance / 2
            ])
                square([
                    rear_joint_meet_x + rear_half_lap_clearance / 2
                        + rear_boolean_epsilon,
                    rear_joint_slot_thickness + rear_half_lap_clearance
                ]);

        // Upright red solar-holder receiving slot.
        translate([
            rear_fin_solar_notch_x0 - rear_solar_slot_clearance / 2,
            rear_solar_meet_z - rear_solar_slot_clearance / 2
        ])
            square([
                rear_fin_solar_notch_width + rear_solar_slot_clearance,
                rear_fin_height - rear_solar_meet_z
                    + rear_solar_slot_clearance / 2 + rear_boolean_epsilon
            ]);
    }
}


module rear_bottle_holder_shaft(z0 = 0) {

    x0 =
        rear_shaft_rear_x
        - rear_shaft_length;

    wood_color([0.20, 0.38, 0.05])
    difference() {

        translate([
            x0,
            -rear_shaft_width/2,
            z0
        ])
            cube([
                rear_shaft_length,
                rear_shaft_width,
                rear_shaft_thickness
            ]);

        // M6 hole.
        translate([
            x0 + rear_shaft_hole_from_front,
            0,
            z0 - 1
        ])
            cylinder(
                h = rear_shaft_thickness + 2,
                d = rear_shaft_hole_diameter
            );

        // Open REAR slot, complementary to the yellow fin's FRONT slot.
        translate([
            rear_green_slot_inset_x,
            -(rear_joint_slot_thickness + rear_half_lap_clearance) / 2,
            z0 - rear_boolean_epsilon
        ])
            cube([
                rear_shaft_rear_x - rear_green_slot_inset_x
                    + rear_boolean_epsilon,
                rear_joint_slot_thickness
                + rear_half_lap_clearance,
                rear_shaft_thickness + 2 * rear_boolean_epsilon
            ]);
    }
}


module rear_solar_panel_holder() {

    wood_color("red")
    translate([
        rear_solar_holder_x0,
        0,
        rear_solar_holder_z0
    ])
    rotate([90, 0, 90])
    translate([
        -rear_solar_holder_length/2,
        0,
        0
    ])
    difference() {

        linear_extrude(
            height = rear_solar_holder_thickness
        )
        difference() {

            square([
                rear_solar_holder_length,
                rear_solar_holder_height
            ]);

            polygon(points=[
                [0, 0],
                [rear_solar_holder_bottom_chamfer, 0],
                [0, rear_solar_holder_bottom_chamfer]
            ]);

            polygon(points=[
                [rear_solar_holder_length, 0],
                [
                    rear_solar_holder_length
                    - rear_solar_holder_bottom_chamfer,
                    0
                ],
                [
                    rear_solar_holder_length,
                    rear_solar_holder_bottom_chamfer
                ]
            ]);
        }

        translate([
            (
                rear_solar_holder_length
                - rear_solar_holder_notch_width
            ) / 2,
            -rear_boolean_epsilon,
            -rear_boolean_epsilon
        ])
            cube([
                rear_solar_holder_notch_width,
                rear_solar_holder_notch_depth + rear_solar_slot_clearance / 2
                    + rear_boolean_epsilon,
                rear_solar_holder_thickness + 2 * rear_boolean_epsilon
            ]);
    }
}


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

module rear_fin_assembly() {

    rear_fin_part();

    rear_bottle_holder_shaft(
        rear_upper_shaft_z0
    );

    rear_bottle_holder_shaft(
        rear_lower_shaft_z0
    );

    rear_solar_panel_holder();
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
                    rear_fin_assembly();
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

    top_disk_thickness = 8.0;   // strengthened roof and shaft bearing
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
    module base_body() {
        union() {
            // top cap disk
            translate([cx, cy, 0])
                cylinder(h=top_disk_thickness, d=top_disk_od);

            // tapered insert shaft
            translate([cx, cy, top_disk_thickness])
                cylinder(
                    h  = insert_total_h - entry_chamfer_h,
                    d1 = plug_top_od,
                    d2 = taper_od_at(insert_total_h - entry_chamfer_h)
                );

            // entry chamfer at bottom of insert shaft
            if (entry_chamfer_h > 0)
                translate([cx, cy, top_disk_thickness + insert_total_h - entry_chamfer_h])
                    cylinder(
                        h  = entry_chamfer_h,
                        d1 = taper_od_at(insert_total_h - entry_chamfer_h),
                        d2 = max(0.1, plug_bottom_od - entry_chamfer_delta)
                    );
        }
    }

    // ============================================================
    // OUTER SILICONE BAND CHANNEL CUTS
    // ============================================================
    //
    // These remove material only in the OUTER annular shell region.
    // They do not cut the whole shaft away.
    //
    module single_band_channel_outer_cut(center_z_local) {
        z0 = clamp(center_z_local - band_channel_w/2, 0, insert_total_h);
        z1 = clamp(center_z_local + band_channel_w/2, 0, insert_total_h);

        if (z1 > z0) {
            difference() {
                translate([cx, cy, top_disk_thickness + z0])
                    cylinder(
                        h  = z1 - z0,
                        d1 = taper_od_at(z0) + 0.02,
                        d2 = taper_od_at(z1) + 0.02
                    );

                translate([cx, cy, top_disk_thickness + z0 - 0.01])
                    cylinder(
                        h  = z1 - z0 + 0.02,
                        d1 = max(0.1, taper_od_at(z0) - 2 * band_channel_depth),
                        d2 = max(0.1, taper_od_at(z1) - 2 * band_channel_depth)
                    );
            }
        }
    }

    module band_channel_system_cut() {
        if (band_channels_enable) {
            if (band_count >= 1) single_band_channel_outer_cut(band1_center_z_local);
            if (band_count >= 2) single_band_channel_outer_cut(band2_center_z_local);
        }
    }

    // ============================================================
    // OUTER BODY
    // ============================================================
    module plug_outer() {
        difference() {
            base_body();
            band_channel_system_cut();
        }
    }

    // ============================================================
    // CUP INTERIOR CAVITY
    // ============================================================
    module cup_cavity_cut() {
        union() {
            translate([cx, cy, top_disk_thickness - 0.01])
                cylinder(
                    h  = insert_total_h - entry_chamfer_h + 0.02,
                    d1 = inner_top_od,
                    d2 = inner_bottom_od
                );

            if (entry_chamfer_h > 0)
                translate([cx, cy, top_disk_thickness + insert_total_h - entry_chamfer_h])
                    cylinder(
                        h  = entry_chamfer_h + 0.02,
                        d1 = inner_bottom_od,
                        d2 = inner_tip_od
                    );
        }
    }

    // ============================================================
    // SERVO AXLE / CENTER HOLE CUT
    // ============================================================
    module servo_axle_hole_cut() {
        translate([cx, cy, -0.01])
            cylinder(h = top_disk_thickness + 0.02, d = shaft_hole_d);
    }

    // ============================================================
    // BUTTON HOLES
    // ============================================================
    module button_top_hole_at(x, y) {
        translate([x, y, -0.01])
            cylinder(h = top_disk_thickness + 0.02, d = button_upper_d);
    }

    module button_holes_cut() {
        if (button_axis == "x") {
            button_top_hole_at(cx + hole_spacing_cc, cy);
            button_top_hole_at(cx - hole_spacing_cc, cy);
        } else {
            button_top_hole_at(cx, cy + hole_spacing_cc);
            button_top_hole_at(cx, cy - hole_spacing_cc);
        }
    }

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
    // CONTROL AXLE
    // ============================================================
    //
    // Installed orientation:
    // - Ø8 mm round section extends 30 mm into the cup cavity
    // - round section passes through the 8 mm cap roof
    // - round section projects 1 mm beyond the cap's outer face
    // - 10 mm AF hex section begins after the round extension
    //
    module turtle_control_axle() {
        union() {
            // Continuous cylindrical section: cavity + roof + 1 mm outside
            translate([
                cx,
                cy,
                -round_shaft_extension_above_cap
                    - joining_overlap
            ])
                cylinder(
                    h = round_shaft_extension_above_cap
                        + joining_overlap
                        + top_disk_thickness
                        + round_shaft_length,
                    d = round_shaft_diameter,
                    $fn = 96
                );

            // Larger hexagonal section beginning after the round extension
            translate([
                cx,
                cy,
                -round_shaft_extension_above_cap
                    - hex_shaft_length
            ])
                cylinder(
                    h = hex_shaft_length + joining_overlap,
                    d = hex_corner_diameter,
                    $fn = 6
                );
        }
    }

    module printable_turtle_control_axle() {
        // Hex end on the print bed.
        translate([
            -cx,
            -cy,
            round_shaft_extension_above_cap
                + hex_shaft_length
        ])
            turtle_control_axle();
    }

    // ============================================================
    // CONTROL CAP
    // ============================================================
    module control_cap() {
        difference() {
            plug_outer();
            cup_cavity_cut();
            servo_axle_hole_cut();
            button_holes_cut();
        }
    }

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

    module cage_side_notch_profile() {
        for (i = [0 : cage_notch_count - 1])
            rotate(i * 360 / cage_notch_count)
                translate([
                    cage_notch_root_radius,
                    -cage_notch_width / 2
                ])
                    square([
                        cage_outer_radius - cage_notch_root_radius
                            + cage_epsilon,
                        cage_notch_width
                    ]);
    }

    module cage_notched_outer_profile() {
        difference() {
            circle(d = cage_outer_diameter);
            cage_side_notch_profile();
        }
    }

    module cage_centre_hex_2d() {
        rotate(30)
            circle(
                d = cage_centre_hex_corner_diameter,
                $fn = 6
            );
    }

    module cage_centre_hex_reinforcing_wall() {
        difference() {
            translate([0,0,-cage_centre_hex_wall_height])
                cylinder(d=cage_hub_diameter,
                         h=cage_centre_hex_wall_height+cage_surface_thickness);
            translate([0,0,-cage_centre_hex_wall_height-cage_epsilon])
                linear_extrude(height=cage_centre_hex_wall_height
                                      +cage_surface_thickness+2*cage_epsilon)
                    cage_centre_hex_2d();
        }
    }

    module cage_surface_plate() {
        difference() {
            linear_extrude(height = cage_surface_thickness)
                cage_notched_outer_profile();

            translate([0, 0, -cage_epsilon])
                linear_extrude(
                    height = cage_surface_thickness
                        + 2 * cage_epsilon
                )
                    cage_centre_hex_2d();

            rotate([0, 0, cage_top_hole_angle])
                translate([
                    cage_top_hole_radial_position,
                    0,
                    -cage_epsilon
                ])
                    cylinder(
                        h = cage_surface_thickness
                            + 2 * cage_epsilon,
                        d = cage_top_hole_diameter
                    );
        }
    }

    module cage_underside_bearing() {
        cage_bearing_radius = cage_bearing_diameter / 2;

        intersection() {
            sphere(d = cage_bearing_diameter);

            translate([
                -cage_bearing_radius - cage_epsilon,
                -cage_bearing_radius - cage_epsilon,
                -cage_bearing_radius - cage_epsilon
            ])
                cube([
                    2 * cage_bearing_radius + 2 * cage_epsilon,
                    2 * cage_bearing_radius + 2 * cage_epsilon,
                    cage_bearing_radius + 2 * cage_epsilon
                ]);
        }
    }

    module cage_surface_part() {
        difference() {
            union() {
                cage_surface_plate();
                cage_centre_hex_reinforcing_wall();
                for (i=[0:cage_bearing_count-1])
                    rotate([0,0,i*360/cage_bearing_count])
                        translate([cage_bearing_pcd/2,0,0]) cage_underside_bearing();
            }
            translate([0,0,cage_surface_thickness-cage_clip_pocket_depth])
                cylinder(d=cage_clip_pocket_diameter,
                         h=cage_clip_pocket_depth+cage_epsilon);
        }
    }

    module cage_wave_ring() {
        pts = [for(i=[0:cage_wave_n-1]) each
            let(a=i*360/cage_wave_n, lo=cage_edge_z(a),
                hi=cage_surface_under_z+cage_epsilon) [
                [cage_outer_radius*cos(a),cage_outer_radius*sin(a),lo],
                [cage_inner_cavity_radius*cos(a),cage_inner_cavity_radius*sin(a),lo],
                [cage_outer_radius*cos(a),cage_outer_radius*sin(a),hi],
                [cage_inner_cavity_radius*cos(a),cage_inner_cavity_radius*sin(a),hi]
            ]];
        faces = [for(i=[0:cage_wave_n-1]) each
            let(b=4*i,c=4*((i+1)%cage_wave_n)) [
                [b,c,c+2],[b,c+2,b+2],
                [b+1,b+3,c+3],[b+1,c+3,c+1],
                [b+2,c+2,c+3],[b+2,c+3,b+3],
                [b,b+1,c+1],[b,c+1,c]
            ]];
        // OpenSCAD clockwise winding, as in the standalone sine cage.
        polyhedron(points=pts,faces=[for(f=faces) [f[2],f[1],f[0]]],convexity=12);
    }

    module cage_side_walls_part() {
        difference() {
            cage_wave_ring();
            translate([0,0,cage_wall_tip_z-cage_epsilon])
                linear_extrude(height=cage_surface_under_z+cage_peak_extension
                                      +3*cage_epsilon)
                    cage_side_notch_profile();
            // Continuous wall peaks carry both bores; no separate tabs.
            for(a=[0:90:270]) rotate([0,0,a])
                for(z=cage_mount_z_positions)
                    translate([cage_inner_cavity_radius-cage_mount_hole_diameter,0,z])
                        rotate([0,90,0])
                            cylinder(d=cage_mount_hole_diameter,
                                     h=cage_side_wall_thickness+cage_mount_hole_diameter
                                       +2*cage_epsilon);
        }
    }

    module cage_assembly_native() {
        color([0.74, 0.77, 0.79])
            cage_side_walls_part();

        color([0.76, 0.79, 0.81])
            translate([
                0,
                0,
                cage_surface_under_z + cage_exploded_view
            ])
                cage_surface_part();
    }

    // Turn the cage upside down over the cap. At position 0, the
    // hemispherical bearing tips lie exactly on the cap's Z=0 surface.
    module positioned_cage_assembly() {
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([180, 0, 0])
                    cage_assembly_native();
    }

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
        wood_color([0.56, 0.39, 0.39])
            translate([0, 0, cage_total_height])
                top_sail_bar_part();
    }

    module positioned_top_sail_bar() {
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([0, 0, sail_frame_rotation_angle])
                    rotate([180, 0, 0])
                        top_sail_bar_native_assembly();
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

        wood_color([0.18, 0.78, 0.24]) {
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
                include_non_sail_joint_hole = true
            );
    }

    module positioned_side_battens() {
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([0, 0, sail_frame_rotation_angle])
                    rotate([180, 0, 0])
                        side_battens_native_assembly();
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

        wood_color([1.0, 0.52, 0.20]) {
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

    module positioned_bottom_sail_bars() {
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([0, 0, sail_frame_rotation_angle])
                    rotate([180, 0, 0])
                        bottom_sail_bars_native_assembly();
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

        wood_color([0.35, 0.92, 0.34]) {
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

    module positioned_joint_strengtheners() {
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([0, 0, sail_frame_rotation_angle])
                    rotate([180, 0, 0])
                        joint_strengtheners_native_assembly();
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

    module positioned_sails() {
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([0, 0, sail_frame_rotation_angle])
                    rotate([180, 0, 0])
                        sails_native_assembly();
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

            // Tangential M6 through-hole shared with the non-sail batten.
            translate([
                c_end_piece_m6_x_local,
                -cage_epsilon,
                c_end_piece_thickness / 2
            ])
                rotate([-90, 0, 0])
                    cylinder(
                        h = c_end_piece_width + 2 * cage_epsilon,
                        d = batten_cage_m6_hole_diameter,
                        $fn = 72
                    );
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

        wood_color([1.0, 0.58, 0.26]) {
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

    module positioned_c_end_pieces() {
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([0, 0, sail_frame_rotation_angle])
                    rotate([180, 0, 0])
                        c_end_pieces_native_assembly();
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

    module positioned_m6_bolts() {
        // Four cage-to-batten bolts follow the cage orientation.
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([180, 0, 0])
                    cage_batten_bolts_native_assembly();

        // Only the front-facing green-supporter bolts remain at the lower joints.
        // The orange C pieces now rely on their interlocking slots, without bolts.
        translate([
            cx,
            cy,
            control_assembly_z
                + cage_bearing_tip_native_z
                - cage_vertical_position
        ])
            rotate([0, 0, cage_mount_alignment_angle])
                rotate([0, 0, sail_frame_rotation_angle])
                    rotate([180, 0, 0])
                        sail_strengthener_bolts_native();
    }

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

    function bottle_top_superellipse_radius(
        t,
        body_r,
        neck_r,
        p = bottle_dome_power
    ) =
        neck_r
        + (body_r - neck_r)
          * pow(max(0, 1 - pow(t, p)), 1 / p);

    function bottle_bottom_superellipse_radius(
        t,
        base_r,
        body_r,
        p = bottle_dome_power
    ) =
        base_r
        + (body_r - base_r)
          * pow(
                max(0, 1 - pow(1 - t, p)),
                1 / p
            );

    module bottle_top_superellipse_dome(
        h,
        body_d,
        neck_d,
        steps = bottle_profile_steps
    ) {
        body_r = body_d / 2;
        neck_r = neck_d / 2;

        rotate_extrude(convexity = 4, $fn = 48)
            polygon(
                points = concat(
                    [[0, 0]],
                    [
                        for (i = [0 : steps])
                            let(
                                t = i / steps,
                                z = h * t,
                                r = bottle_top_superellipse_radius(
                                    t,
                                    body_r,
                                    neck_r
                                )
                            )
                            [r, z]
                    ],
                    [[0, h]]
                )
            );
    }

    module bottle_bottom_superellipse_dome(
        h,
        base_d,
        body_d,
        steps = bottle_profile_steps
    ) {
        base_r = base_d / 2;
        body_r = body_d / 2;

        rotate_extrude(convexity = 4, $fn = 48)
            polygon(
                points = concat(
                    [[0, 0]],
                    [
                        for (i = [0 : steps])
                            let(
                                t = i / steps,
                                z = h * t,
                                r = bottle_bottom_superellipse_radius(
                                    t,
                                    base_r,
                                    body_r
                                )
                            )
                            [r, z]
                    ],
                    [[0, h]]
                )
            );
    }

    module buzdagi_bottle_body() {
        color([0.0, 0.85, 0.95, 0.40])
            union() {
                bottle_bottom_superellipse_dome(
                    h = bottom_dome_height,
                    base_d = bottle_bottom_base_diameter,
                    body_d = bottle_diameter
                );

                translate([0, 0, bottle_body_z0])
                    cylinder(
                        h = bottle_straight_body_height,
                        d = bottle_diameter,
                        $fn = 48
                    );

                translate([0, 0, bottle_top_dome_z0])
                    bottle_top_superellipse_dome(
                        h = top_dome_height,
                        body_d = bottle_diameter,
                        neck_d = bottle_neck_diameter
                    );

                translate([0, 0, bottle_neck_z0])
                    cylinder(
                        h = bottle_neck_height,
                        d = bottle_neck_diameter,
                        $fn = 36
                    );
            }
    }

    module buzdagi_bottle_collar() {
        color([0, 1, 1, 0.90])
            translate([0, 0, bottle_collar_z0])
                cylinder(
                    h = bottle_collar_height,
                    d = bottle_collar_diameter,
                    $fn = 36
                );
    }

    module buzdagi_bottle_cap() {
        color([0.10, 0.32, 0.92])
            translate([0, 0, bottle_cap_z0])
                cylinder(
                    h = cap_height,
                    d = cap_diameter,
                    $fn = 36
                );
    }

    module buzdagi_bottle() {
        color([0.0, 0.85, 0.95, 0.40])
        difference() {
            buzdagi_bottle_body();

            // Remove the original flat bottom and lower dome.
            translate([
                -bottle_diameter,
                -bottle_diameter,
                -cage_epsilon
            ])
                cube([
                    2 * bottle_diameter,
                    2 * bottle_diameter,
                    bottle_cut_height + cage_epsilon
                ]);

            // Open a short socket inside the remaining straight body
            // so the control cap can slide in without solid overlap.
            translate([
                0,
                0,
                bottle_cut_height - cage_epsilon
                ])
                cylinder(
                    h = insert_total_h + 2 * cage_epsilon,
                    d = bottle_socket_diameter,
                    $fn = 96
                );
        }

        buzdagi_bottle_collar();
        buzdagi_bottle_cap();
    }

    module positioned_buzdagi_bottle() {
        // Native bottle orientation already places its flat bottom at
        // the low-Z end and its blue cap at the high-Z end. In this
        // assembly, +Z is downward, so the bottom faces the cage and
        // the blue cap points down.
        translate([cx, cy, 0])
            buzdagi_bottle();
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
        // Keep the axle with the cage so their hexagonal connection stays aligned.
        translate([0, 0, bottle_height])
        rotate([180, 0, 0]) {
            translate([cx, cy, control_assembly_z])
                color([0.95, 0.65, 0.12])
                    turtle_control_axle();
            positioned_cage_assembly();
            positioned_top_sail_bar();
            positioned_side_battens();
            positioned_bottom_sail_bars();
            positioned_joint_strengtheners();
            positioned_c_end_pieces();
            positioned_sails();
            positioned_m6_bolts();
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
        printable_turtle_control_axle();
    }
    else if (part == "buttons") {
        button_preview_cylinders();
    }
    else if (part == "cage_assembly") {
        positioned_cage_assembly();
        positioned_top_sail_bar();
        positioned_side_battens();
        positioned_bottom_sail_bars();
        positioned_joint_strengtheners();
        positioned_c_end_pieces();
        positioned_sails();
        positioned_m6_bolts();
    }
    else if (part == "cage_surface") {
        translate([0, 0, cage_bearing_diameter / 2])
            cage_surface_part();
    }
    else if (part == "cage_side_walls") {
        cage_side_walls_part();
    }
    else if (part == "top_sail_bar") {
        top_sail_bar_part();
    }
    else if (part == "side_battens") {
        side_battens_native_assembly();
    }
    else if (part == "bottom_sail_bars") {
        bottom_sail_bars_native_assembly();
    }
    else if (part == "joint_strengtheners") {
        joint_strengtheners_native_assembly();
    }
    else if (part == "c_end_pieces") {
        c_end_pieces_native_assembly();
    }
    else if (part == "sails") {
        sails_native_assembly();
    }
    else if (part == "m6_bolts") {
        positioned_m6_bolts();
    }
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

    // Frame 1: suppress the two Pressers on the physical 3-o'clock port
    // (pre-orientation +X) for the rear-fin green shafts.
    // The 9-o'clock Pressers are restored.
    centered_rectangle([0, 0, 0], true, false);

    centered_rectangle([
        0,
        frame_step_tilt,
        frame_step_spin
    ]);

    // Frame 3: suppress only the physical DOWN ballast-port Pressers
    // (pre-orientation +Y). The 12-o'clock / -Y pair is restored.
    centered_rectangle([
        frame_step_tilt,
        0,
        frame_step_spin
    ], true, false);


    // Four Final Keys.
    inserted_final_key(
        -final_key_x_offset,
         final_key_z_offset
    );

    inserted_final_key(
         final_key_x_offset,
         final_key_z_offset
    );

    inserted_final_key(
        -final_key_x_offset,
        -final_key_z_offset
    );

    inserted_final_key(
         final_key_x_offset,
        -final_key_z_offset
    );


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
