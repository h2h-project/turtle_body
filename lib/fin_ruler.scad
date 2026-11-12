// Shared vector engraving: dimensions in mm, digits need no installed font.
use <params.scad>
function fr_depth() = 0.3;
function fr_stroke() = 0.25;
function fr_label_w(s) = len(s) * 2.2;
function fr_segments(c) =
    c == "0" ? [0,1,2,3,4,5] : c == "1" ? [1,2] :
    c == "2" ? [0,1,6,4,3] : c == "3" ? [0,1,6,2,3] :
    c == "4" ? [5,6,1,2] : c == "5" ? [0,5,6,2,3] :
    c == "6" ? [0,5,6,4,2,3] : c == "7" ? [0,1,2] :
    c == "8" ? [0,1,2,3,4,5,6] : c == "9" ? [0,1,2,3,5,6] : [];
module fr_char(c) {
    pts = [[[0,3],[1.5,3]], [[1.5,3],[1.5,1.5]],
           [[1.5,1.5],[1.5,0]], [[0,0],[1.5,0]],
           [[0,0],[0,1.5]], [[0,1.5],[0,3]], [[0,1.5],[1.5,1.5]]];
    for (i = fr_segments(c)) hull() for (p = pts[i])
        translate(p) square(fr_stroke(), center=true);
    if (c == "+" || c == "-") {
        translate([0,1.375]) square([1.5,0.25]);
        if (c == "+") translate([0.625,0.75]) square([0.25,1.5]);
    }
    if (c == "m") for (x=[0,0.75,1.5]) {
        translate([x,0]) square([0.25,1.5]);
        translate([x,1.25]) square([0.5,0.25]);
    }
}
module fr_label(s, mirrored=false) {
    translate([mirrored ? fr_label_w(s)-0.7 : 0,0])
        mirror([mirrored ? 1 : 0,0,0])
            for (i=[0:len(s)-1]) translate([i*2.2,0]) fr_char(s[i]);
}
// kind-specific fit predicates keep WHOLE marks and labels clear of edges/joints.
function fr_fits(kind, x0, x1, z0, z1) = kind == "head" ?
    z0 >= -p_head_fin_h()/2-p_head_fin_drop()+5 && z1 <= p_head_fin_h()/2-5 &&
    x0 >= p_head_slat_overlap()/2+p_fit_clearance()/2+5 &&
    x1+5 <= p_head_fin_heel_x() + (p_head_fin_w()-p_head_fin_heel_x()) *
        (p_head_fin_h()/2-z1)/(p_head_fin_h()-p_head_fin_toe_h()) &&
    x1+5 <= p_head_fin_w()-p_head_fin_forefoot_setback() :
    z0 >= max(0,(2/3)*p_bottle_d()-x0)+5 && z1 <= 3*p_bottle_d()-5 &&
    x0 >= (p_fin_board_w()-2*p_wood_t())/2+p_fit_clearance()/2+5 &&
    x1 <= p_fin_board_w()-2*p_wood_t()-5;
// Keep rulers beyond the half-lap ends when builders change stock dimensions.
// These margins preserve the reference build's X=30 / X=42 positions.
function fr_joint_margin(kind) = kind == "head" ? 5.9 : 7.4;
function fr_x(kind) = (kind == "head" ? p_head_slat_overlap()/2
                     : (p_fin_board_w()-2*p_wood_t())/2)
                     + p_fit_clearance()/2 + fr_joint_margin(kind);
function fr_tick_length(v) = v%10 == 0 ? 8 : v%5 == 0 ? 6 : 3;
function fr_tick_width(v) = v == 0 ? 0.6 : 0.25;
function fr_tick_values(kind, zero) = [for (v=[-500:500])
    if (fr_fits(kind,fr_x(kind),fr_x(kind)+fr_tick_length(v),
                zero+v-fr_tick_width(v)/2,zero+v+fr_tick_width(v)/2)) v];
function fr_range(kind, zero) = let(values=fr_tick_values(kind,zero))
    assert(len(values)>0,"Fin has no room for a ruler") [min(values),max(values)];
module fin_ruler_2d(kind, zero, mirrored=false) {
    x = fr_x(kind);
    for (v=[-500:500]) {
        z = zero+v;
        l = fr_tick_length(v);
        w = fr_tick_width(v);
        if (fr_fits(kind,x,x+l,z-w/2,z+w/2))
            translate([x,z-w/2]) square([l,w]);
        s = str(v>0 ? "+" : "",v);
        if (v%10 == 0 && fr_fits(kind,x+10,x+10+fr_label_w(s),z-1.7,z+1.7))
            translate([x+10,z-1.5]) fr_label(s,mirrored);
    }
    if (fr_fits(kind,x+10,x+15,zero+3,zero+6.5))
        translate([x+10,zero+3]) fr_label("mm",mirrored);
}
module fin_ruler_recess(kind, zero, thickness) {
    assert(thickness > 2*fr_depth(), "Fin must be thicker than both engravings.");
    for (side=[-1,1])
        translate([0,side*(thickness/2-fr_depth()/2+p_eps()/2),0])
            rotate([90,0,0]) linear_extrude(height=fr_depth()+p_eps(),center=true)
                fin_ruler_2d(kind,zero,side==1);
}
