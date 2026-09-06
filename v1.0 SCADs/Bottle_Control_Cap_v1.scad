/*
 Hope Turtle — control cap for the CURRENT FULL-TURTLE sine cage.
 Units: mm. License: CERN-OHL-S-2.0. Self-contained.
 Cap disk 100 mm; matching cage cavity 102 mm (1 mm radial clearance).
 Print bearing face down at Z=0, with the open insert facing upward.
*/
$fn = 120;

/* [Bottle and cage fit] */
bottle_diameter = 82;
bottle_wall_thickness = 0.5;
insert_shaft_radial_clearance = 1;
matching_cage_inner_diameter = 102;
cage_radial_clearance = 1;

/* [Cap body] */
top_disk_thickness = 5;
centre_boss_depth = 2; // Extra projection into the hollow cap
centre_boss_diameter = 18;
cup_wall_thickness = 4;
insert_total_h = 35;
entry_chamfer_h = 1;
entry_chamfer_delta = 1;

/* [Axle and buttons] */
shaft_hole_d = 8.6;
button_upper_d = 17;
button_axis = "y"; // [x,y]
hole_spacing_cc = 24; // Radius: hole centres are 48 mm apart

/* [Silicone band channels] */
band_channels_enable = true;
band_count = 2; // [0:1:2]
band1_center_z_local = 12; // Measured from the insert's shoulder
band2_center_z_local = 25;
band_channel_w = 2; // Axial groove height
band_channel_depth = 2; // Radial groove depth

/* [Hidden] */
cx = 0;
cy = 0;
top_disk_od = matching_cage_inner_diameter - 2*cage_radial_clearance;
bottle_socket_diameter = bottle_diameter - 2*bottle_wall_thickness;
insert_shaft_diameter = bottle_socket_diameter - 2*insert_shaft_radial_clearance;
plug_top_od = insert_shaft_diameter;
plug_bottom_od = plug_top_od;
plug_total_h = top_disk_thickness + insert_total_h;
disk_r = top_disk_od/2;
inner_top_od_raw = plug_top_od - 2*cup_wall_thickness;
inner_bottom_od_raw = plug_bottom_od - 2*cup_wall_thickness;
inner_top_od = max(1,inner_top_od_raw);
inner_bottom_od = max(1,inner_bottom_od_raw);
inner_chamfer_delta = max(0,entry_chamfer_delta);
inner_tip_od = max(0.5,inner_bottom_od-inner_chamfer_delta);
function clamp(v,lo,hi) = min(max(v,lo),hi);
function taper_od_at(z_local) =
    plug_top_od+(plug_bottom_od-plug_top_od)*(z_local/insert_total_h);

assert(cage_radial_clearance>0 && insert_shaft_radial_clearance>0);
assert(top_disk_od>plug_top_od && plug_top_od>2*cup_wall_thickness);
assert(top_disk_thickness>0 && insert_total_h>entry_chamfer_h && entry_chamfer_h>=0);
assert(cup_wall_thickness>band_channel_depth && band_channel_depth>=0);
assert(band_channel_w>0 && band_count>=0 && band_count<=2);
if (band_channels_enable) {
    for (z = band_count == 2 ? [band1_center_z_local,band2_center_z_local]
                            : band_count == 1 ? [band1_center_z_local] : [])
        assert(z-band_channel_w/2>0
               && z+band_channel_w/2<insert_total_h-entry_chamfer_h,
               "Seal groove must stay inside the straight insert body.");
    if (band_count == 2)
        assert(abs(band2_center_z_local-band1_center_z_local)>band_channel_w,
               "Seal grooves must not overlap.");
}
assert(shaft_hole_d>0 && hole_spacing_cc-button_upper_d/2>shaft_hole_d/2);
assert(hole_spacing_cc+button_upper_d/2<top_disk_od/2);
assert(button_axis=="x" || button_axis=="y");
assert(centre_boss_depth>0 && centre_boss_depth<insert_total_h);
assert(centre_boss_diameter>shaft_hole_d
       && centre_boss_diameter<inner_top_od);
assert(centre_boss_diameter/2<hole_spacing_cc-button_upper_d/2,
       "Centre boss must clear the button openings.");

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

module plug_outer() {
    difference() {
        base_body();
        band_channel_system_cut();
    }
}

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

module servo_axle_hole_cut() {
    translate([cx, cy, -0.01])
        cylinder(h = top_disk_thickness + centre_boss_depth + 0.02,
                 d = shaft_hole_d);
}

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

module control_cap() {
    difference() {
        union() {
            difference() {
                plug_outer();
                cup_cavity_cut();
            }
            // Overlap the roof so the reinforcing collar is one solid body.
            translate([cx,cy,top_disk_thickness-0.02])
                cylinder(d=centre_boss_diameter,h=centre_boss_depth+0.02);
        }
        servo_axle_hole_cut();
        button_holes_cut();
    }
}

color([0.74,0.77,0.79]) control_cap();
echo("Cap disk / insert diameter / total height = ",top_disk_od,plug_top_od,plug_total_h);
echo("Matching cage ID / radial clearance = ",matching_cage_inner_diameter,cage_radial_clearance);
echo("Seal groove root diameter / height / radial depth = ",
     plug_top_od-2*band_channel_depth,band_channel_w,band_channel_depth);
echo("Roof / boss depth / total axle bearing length = ",
     top_disk_thickness,centre_boss_depth,top_disk_thickness+centre_boss_depth);
