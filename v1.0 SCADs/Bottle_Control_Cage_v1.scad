/*
  Hope Turtle — scalloped, reinforced PLA cage
  Units: mm. Standalone OpenSCAD; no dependencies.
  Prototype: not load-tested or structurally optimized by simulation.
  Matched to Turtle_Control_Cap.scad: 100 mm cap, 102 mm cavity. One continuous sinusoidal annular
  wall forms four rounded mountain tops when viewed roof-down. Each batten
  groove and its two M3 holes are centered on a mountain top.
  No separate tabs, added gussets, or flat-topped mounting plateaus.
  Print roof down; inspect clip-pocket and horizontal-bore local supports.
  Test fit, torsion, bending and layer adhesion before service.
*/

/* [View] */
part = "print"; // [print,upright]
curve_segments = 120; // [48:12:240]

/* [Bottle and cap sizing] */
bottle_diameter = 82;
cap_diameter_allowance = 18; // 82 mm bottle + 18 = 100 mm cap
cage_diametral_clearance = 2; // 1 mm radial clearance to 100 mm cap

/* [Cage body] */
cage_wall = 6.5;
cage_roof = 6;
skirt_height = 44; // Roof underside to ORIGINAL skirt rim
notch_width = 22.5;
notch_depth = 3.7;
m3_hole_diameter = 3.2;

/* [Continuous sine wall] */
scallops_enabled = true;
roof_ring_height = 10; // Minimum skirt depth between mounts
wave_segments = 240; // [120:24:480]

/* [Mountain tops and mounting holes] */
mount_extension = 20; // Crest extends this far past the original skirt rim
lower_hole_from_tip = 10;

/* [Bearings and button] */
bump_d = 9;
button_diameter = 18;
button_r = 24;
button_angle = 90; // [0:0.5:359.5]

/* [Shaft hub and clip pocket] */
cage_hex_af = 10.3;
cage_hub_d = 29;
clip_pocket_depth = 4;
pocket_d = 26;

/* [Hidden] */
$fn = curve_segments;
eps = 0.02;
cap_diameter = bottle_diameter + cap_diameter_allowance;
cage_id = cap_diameter + cage_diametral_clearance;
cage_od = cage_id + 2*cage_wall;
ri = cage_id/2;
ro = cage_od/2;
groove_r = ro - notch_depth;
bump_pcd = cap_diameter - bump_d + 0.5;

// Original joint coordinates: bearing tips touch cap Z=0.
cage_under = bump_d/2;
cage_top = cage_under + cage_roof;
cage_bottom = cage_under - skirt_height;
cage_hub_bottom = 1;
pocket_floor = cage_top - clip_pocket_depth;
wall_tip_z = cage_bottom - mount_extension;
max_wall_height = skirt_height + mount_extension;
wave_n = max(48, 4*ceil(wave_segments/4));
mount_hole_z = cage_bottom + skirt_height/2;
lower_hole_z = wall_tip_z + lower_hole_from_tip;
cut_start = ri - m3_hole_diameter;
cut_length = ro - cut_start + 2*eps;

assert(cap_diameter>0 && cage_diametral_clearance>0);
assert(cage_wall>notch_depth && notch_depth>0 && notch_width>0);
assert(m3_hole_diameter>0 && m3_hole_diameter<notch_width);
assert(cage_roof>clip_pocket_depth && clip_pocket_depth>0);
assert(roof_ring_height>0 && roof_ring_height<skirt_height);
assert(mount_extension>=0);
assert(lower_hole_from_tip>m3_hole_diameter/2+2
       && lower_hole_from_tip<max_wall_height-m3_hole_diameter/2);
assert(bump_d>0 && bump_pcd/2+bump_d/2<ri);
assert(cage_hex_af>10 && cage_hex_af/cos(30)<pocket_d);
assert(cage_hub_d>pocket_d && pocket_d>25 && pocket_floor>cage_hub_bottom);
assert(pocket_floor<=6.5 && cage_top>10.2,
       "Keep original shaft/clip axial clearances.");
assert(button_r-button_diameter/2>cage_hub_d/2
       && button_r+button_diameter/2<ri);
assert(button_r+button_diameter/2<bump_pcd/2-bump_d/2,
       "Button must clear bearings at every rotation angle.");

// Cosine is a phase-shifted sine wave. Four identical rounded crests:
// maximum wall height at 0/90/180/270 degrees; valleys halfway between.
// Print view reverses Z, so these longest wall regions become mountain tops.
function skirt_edge_z(a) = wall_tip_z + (scallops_enabled ?
    (max_wall_height-roof_ring_height)*(1-cos(4*a))/2 : 0);

// Conservative full-bore edge clearance at the inner wall.
hole_edge_angle = asin((m3_hole_diameter/2)/ri);
assert(lower_hole_z-m3_hole_diameter/2 >
       skirt_edge_z(hole_edge_angle)+2,
       "Lower screw hole needs at least 2 mm material to the sine edge.");

module groove_cuts_2d() {
    for(a=[0:90:270]) rotate(a)
        translate([groove_r,-notch_width/2])
            square([notch_depth+eps,notch_width]);
}
module outer_profile() {
    difference() { circle(r=ro); groove_cuts_2d(); }
}

// Closed annular mesh with varying lower edge. Four vertices per station:
// outer lower, inner lower, outer upper, inner upper.
module wave_ring() {
    pts = [for(i=[0:wave_n-1]) each let(a=i*360/wave_n,
            lo=skirt_edge_z(a), hi=cage_under+eps) [
        [ro*cos(a),ro*sin(a),lo], [ri*cos(a),ri*sin(a),lo],
        [ro*cos(a),ro*sin(a),hi], [ri*cos(a),ri*sin(a),hi]
    ]];
    faces = [for(i=[0:wave_n-1]) each let(b=4*i,c=4*((i+1)%wave_n)) [
        [b,c,c+2],[b,c+2,b+2],
        [b+1,b+3,c+3],[b+1,c+3,c+1],
        [b+2,c+2,c+3],[b+2,c+3,b+3],
        [b,b+1,c+1],[b,c+1,c]
    ]];
    // OpenSCAD uses clockwise winding viewed from outside.
    polyhedron(points=pts, faces=[for(f=faces) [f[2],f[1],f[0]]], convexity=12);
}
module scalloped_wall() {
    difference() {
        wave_ring();
        translate([0,0,wall_tip_z-eps])
            linear_extrude(height=max_wall_height+3*eps) groove_cuts_2d();
    }
}

module hemisphere() {
    intersection() {
        sphere(d=bump_d);
        translate([-bump_d,-bump_d,-bump_d])
            cube([2*bump_d,2*bump_d,bump_d+eps]);
    }
}
module cage_solid() {
    difference() {
        union() {
            scalloped_wall();
            translate([0,0,cage_under])
                linear_extrude(height=cage_roof) outer_profile();
            translate([0,0,cage_hub_bottom])
                cylinder(d=cage_hub_d,h=cage_top-cage_hub_bottom);
            for(a=[0:45:315]) rotate([0,0,a])
                translate([bump_pcd/2,0,cage_under]) hemisphere();
        }
        translate([0,0,cage_hub_bottom-eps])
            cylinder(d=cage_hex_af/cos(30),h=cage_top-cage_hub_bottom+2*eps,$fn=6);
        translate([0,0,pocket_floor])
            cylinder(d=pocket_d,h=clip_pocket_depth+eps);
        rotate([0,0,button_angle]) translate([button_r,0,cage_under-eps])
            cylinder(d=button_diameter,h=cage_roof+2*eps);
        for(a=[0:90:270]) rotate([0,0,a])
            for(z=[mount_hole_z,lower_hole_z])
                translate([cut_start,0,z]) rotate([0,90,0])
                    cylinder(d=m3_hole_diameter,h=cut_length);
    }
}

color([0.74,0.77,0.79]) {
    if(part=="print")
        translate([0,0,cage_top]) rotate([180,0,0]) cage_solid();
    else if(part=="upright")
        // Put longest wall crests at Z=0 in installed orientation.
        translate([0,0,-wall_tip_z]) cage_solid();
    else assert(false,str("Unknown view: ",part));
}
echo("OD / ID / roof-to-tip = ",cage_od,cage_id,cage_top-wall_tip_z);
echo("Groove width / depth = ",notch_width,notch_depth);
echo("M3 diameter / vertical pitch = ",m3_hole_diameter,mount_hole_z-lower_hole_z);
echo("Sine peak-to-valley / roof-ring depth = ",max_wall_height-roof_ring_height,roof_ring_height);

