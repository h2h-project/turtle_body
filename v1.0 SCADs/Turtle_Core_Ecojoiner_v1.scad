/*
  Hope Turtle — standalone Ecojoiner assembly
  Units: mm. License: CERN-OHL-S-2.0
  Extracted from the current full Turtle: six Long Johns, six Little Johns,
  four Final Keys, twelve Pressers and their M6 bolt placeholders.
  All six ports have their pressers restored.
  No bottles, fins, ballast, sails, control apparatus or external files.
*/
$fn = 96;
enable_color_coding = true;

// Sizing references only: these do not generate bottles.
bottle_diameter = 82;
bottle_height = 305;
cap_diameter = 31;
collar_diameter = 34;

module wood_color(coded_color) {
    color(enable_color_coding ? coded_color : [0.94,0.83,0.62]) children();
}

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



module ecojoiner_only() {
    centered_rectangle([0,0,0]);
    centered_rectangle([0,frame_step_tilt,frame_step_spin]);
    centered_rectangle([frame_step_tilt,0,frame_step_spin]);
    for(x=[-final_key_x_offset,final_key_x_offset])
        for(z=[-final_key_z_offset,final_key_z_offset])
            inserted_final_key(x,z);
}

// Same physical orientation as the full Turtle assembly.
rotate([-90,0,0]) ecojoiner_only();

