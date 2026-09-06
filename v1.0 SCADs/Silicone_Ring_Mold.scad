/*
 Hope Turtle — two open-top silicone ring molds. Units: mm.
 License: CERN-OHL-S-2.0. Self-contained.
 Print flat, cavity openings up. Fill each annular channel and scrape flush
 with the rim and centre island. Allow the silicone to cure according to
 its manufacturer's instructions before peeling out the flexible ring.
 Nominal dimensions; no silicone shrinkage compensation is applied.
*/

/* [Output] */
part = "mold"; // [mold,rings]
ring_count = 2;
curve_segments = 240;

/* [Matching cap] */
bottle_diameter = 82;
bottle_wall_thickness = 0.5;
insert_shaft_radial_clearance = 1;
groove_radial_depth = 2;
groove_axial_height = 2;

/* [Silicone ring] */
ring_axial_thickness = 1.5;
ring_radial_width = 5;

/* [Mold body] */
mold_floor_thickness = 3;
mold_outer_wall = 3;
mold_spacing = 8; // Gap between the two separate mold bodies

/* [Hidden] */
$fn = curve_segments;
eps = 0.02;
cap_insert_diameter = bottle_diameter-2*bottle_wall_thickness
                     -2*insert_shaft_radial_clearance;
ring_inner_diameter = cap_insert_diameter-2*groove_radial_depth;
ring_outer_diameter = ring_inner_diameter+2*ring_radial_width;
mold_outer_diameter = ring_outer_diameter+2*mold_outer_wall;
mold_height = mold_floor_thickness+ring_axial_thickness;

assert(ring_count>=1 && ring_count==floor(ring_count));
assert(ring_inner_diameter>0 && groove_radial_depth>0);
assert(ring_axial_thickness>0 && ring_axial_thickness<=groove_axial_height);
assert(ring_radial_width>groove_radial_depth);
assert(mold_floor_thickness>0 && mold_outer_wall>0 && mold_spacing>0);

module ring_shape(height) {
    difference() {
        cylinder(d=ring_outer_diameter,h=height);
        translate([0,0,-eps])
            cylinder(d=ring_inner_diameter,h=height+2*eps);
    }
}

module ring_mold() {
    difference() {
        cylinder(d=mold_outer_diameter,h=mold_height);
        // Flat centre island and outer rim provide the scraping plane.
        translate([0,0,mold_floor_thickness])
            ring_shape(ring_axial_thickness+eps);
    }
}

for(i=[0:ring_count-1])
    translate([mold_outer_diameter/2+i*(mold_outer_diameter+mold_spacing),
               mold_outer_diameter/2,0])
        if(part=="mold") ring_mold();
        else if(part=="rings") ring_shape(ring_axial_thickness);
        else assert(false,str("Unknown part: ",part));

echo("Ring ID / OD / axial thickness = ",
     ring_inner_diameter,ring_outer_diameter,ring_axial_thickness);
echo("Ring projection beyond cap = ",ring_radial_width-groove_radial_depth);
echo("Mold layout X / Y / Z = ",
     ring_count*mold_outer_diameter+(ring_count-1)*mold_spacing,
     mold_outer_diameter,mold_height);
