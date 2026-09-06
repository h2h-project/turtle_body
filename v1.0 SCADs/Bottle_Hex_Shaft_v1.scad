/*
 Hope Turtle — centre axle for Turtle_Control_Cap.scad and
 Turtle_Control_Cage_Matched.scad (4 mm cap roof with 6 mm internal boss).
 Units: mm. License: CERN-OHL-S-2.0. Self-contained.
 Hex end is on Z=0 for printing; the magnet recess opens upward.
 Round section includes the cap roof plus 30 mm inside the cavity.
*/
$fn = 120;

/* [Round shaft] */
round_shaft_diameter = 8;
cap_roof_thickness = 4;
round_length_inside_cap = 30; // From roof underside, INCLUDING the 6 mm boss
round_extension_above_cap = 1;

/* [Hex shaft] */
hex_across_flats = 10;
hex_length = 23;
joining_overlap = 0.2;

/* [Magnet recess] */
magnet_recess_enabled = true;
magnet_diameter = 3;
magnet_thickness = 1;
magnet_diametral_clearance = 0;
magnet_depth_clearance = 0;

/* [Matching interfaces] */
cap_axle_hole_diameter = 8.6;
cap_boss_depth = 6;
cap_insert_length = 35;
cage_hex_across_flats = 10.3;
sail_bar_hole_diameter = 12;
cage_roof_thickness = 6;
bearing_height = 4.5;
sail_bar_thickness = 12;

/* [Hidden] */
eps = 0.02;
hex_corner_diameter = hex_across_flats/cos(30);
round_length = round_length_inside_cap+cap_roof_thickness+round_extension_above_cap;
total_length = hex_length+round_length;
recess_d = magnet_diameter+magnet_diametral_clearance;
recess_depth = magnet_thickness+magnet_depth_clearance;
assert(round_shaft_diameter>0 && round_shaft_diameter<cap_axle_hole_diameter);
assert(hex_across_flats>round_shaft_diameter && hex_across_flats<cage_hex_across_flats);
assert(hex_corner_diameter<sail_bar_hole_diameter);
assert(joining_overlap>0 && joining_overlap<min(hex_length,round_length));
assert(round_length_inside_cap>0 && cap_roof_thickness>0 && round_extension_above_cap>=0);
assert(cap_boss_depth>0 && round_length_inside_cap>cap_boss_depth);
assert(round_length_inside_cap<cap_insert_length,
       "Keep the round end inside the cap's open insert rim.");
assert(hex_length+round_extension_above_cap>
       bearing_height+cage_roof_thickness+sail_bar_thickness,
       "Axle must reach through the cage and sail bar.");
assert(!magnet_recess_enabled || (recess_d>0 && recess_d<round_shaft_diameter
       && recess_depth>0 && recess_depth<round_length_inside_cap));
assert(magnet_diametral_clearance>=0 && magnet_depth_clearance>=0);

module centre_axle() {
    difference() {
        union() {
            cylinder(d=hex_corner_diameter,h=hex_length+joining_overlap,$fn=6);
            translate([0,0,hex_length-joining_overlap])
                cylinder(d=round_shaft_diameter,h=round_length+joining_overlap);
        }
        if(magnet_recess_enabled)
            translate([0,0,total_length-recess_depth])
                cylinder(d=recess_d,h=recess_depth+eps);
    }
}
color([0.74,0.77,0.79]) centre_axle();
echo("Total / nominal round / nominal hex length = ",total_length,round_length,hex_length);
echo("Round diameter / hex across flats = ",round_shaft_diameter,hex_across_flats);
