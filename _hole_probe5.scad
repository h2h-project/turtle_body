include <Full_Turtle_v1.scad>
module full_turtle_scene(include_top_sail = true) { }

module upper_shaft_installed() {
    multmatrix([[1,0,0,rear_install_pre_x],[0,0,1,rear_install_pre_y],
                [0,-1,0,rear_install_pre_z],[0,0,0,1]])
        translate([rear_shaft_rear_x, 0, rear_local_bottle_axis_z])
            rotate([180,0,0])
                translate([-rear_shaft_rear_x, 0, -rear_local_bottle_axis_z])
                    bottle_holder_shaft(rear_upper_shaft_z0);
}
module lower_shaft_installed() {
    multmatrix([[1,0,0,rear_install_pre_x],[0,0,1,rear_install_pre_y],
                [0,-1,0,rear_install_pre_z],[0,0,0,1]])
        translate([rear_shaft_rear_x, 0, rear_local_bottle_axis_z])
            rotate([180,0,0])
                translate([-rear_shaft_rear_x, 0, -rear_local_bottle_axis_z])
                    bottle_holder_shaft(rear_lower_shaft_z0);
}

// select which single solid to export via $part
if ($preview) { } // no-op
part2 = "john_upper_target";
