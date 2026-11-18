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
    // v6.6.7: one top bar over three legs (was a separate flag per leg, which read "rrr")
    if (c == "m") {
        translate([0,1.25]) square([1.75,0.25]);
        for (x=[0,0.75,1.5]) translate([x,0]) square([0.25,1.5]);
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
// v6.6.9: the scale runs PAST +-bottle radius, by 10 mm plus a 5 mm margin
// shown above that (fr_range_beyond() = 15), rounded up to the next 5 mm mark
// so it ends on a half-centimetre tick: +-60 at Ø84 / Ø90. The buoyancy
// workbench predicted a waterline above the bottle top (stern awash), which the
// old scale could not show. History: v6.6.5 stopped 10 mm SHORT of the radius
// ("the waterline cannot pass one radius" -- wrong for a heavy turtle), v6.6.8
// rounded that up to +-35. Marks that do not fit the fin are still dropped.
function fr_range_beyond() = 15;
function fr_half_range() = ceil((p_bottle_d()/2 + fr_range_beyond()) / 5) * 5;
// value label; the zero carries the unit as one string so it reads "0 mm"
// on both faces (face B is engraved mirrored) -- v6.6.8, was "mm" above the 0
function fr_value_text(v) = v == 0 ? "0 mm" : str(v > 0 ? "+" : "", v);
function fr_tick_length(v) = v%10 == 0 ? 8 : v%5 == 0 ? 6 : 3;
function fr_tick_width(v) = v == 0 ? 0.6 : 0.25;
function fr_tick_values(kind, zero) = [for (v=[-fr_half_range():fr_half_range()])
    if (fr_fits(kind,fr_x(kind),fr_x(kind)+fr_tick_length(v),
                zero+v-fr_tick_width(v)/2,zero+v+fr_tick_width(v)/2)) v];
function fr_range(kind, zero) = let(values=fr_tick_values(kind,zero))
    assert(len(values)>0,"Fin has no room for a ruler") [min(values),max(values)];
module fin_ruler_2d(kind, zero, mirrored=false) {
    x = fr_x(kind);
    for (v=[-fr_half_range():fr_half_range()]) {
        z = zero+v;
        l = fr_tick_length(v);
        w = fr_tick_width(v);
        if (fr_fits(kind,x,x+l,z-w/2,z+w/2))
            translate([x,z-w/2]) square([l,w]);
        s = fr_value_text(v);
        if (v%10 == 0 && fr_fits(kind,x+10,x+10+fr_label_w(s),z-1.7,z+1.7))
            translate([x+10,z-1.5]) fr_label(s,mirrored);
    }
}
module fin_ruler_recess(kind, zero, thickness) {
    assert(thickness > 2*fr_depth(), "Fin must be thicker than both engravings.");
    for (side=[-1,1])
        translate([0,side*(thickness/2-fr_depth()/2+p_eps()/2),0])
            rotate([90,0,0]) linear_extrude(height=fr_depth()+p_eps(),center=true)
                fin_ruler_2d(kind,zero,side==1);
}
// v6.6.6: the bare scale for a printed (paper / sticker) ruler. Same ticks,
// labels and +-fr_half_range() span as the engraving, but no fin-fit
// predicates, so one print serves both the head and the rear fin. Ticks start
// at X = 0; the zero mark is on Y = 0. build/export_ruler_svg.py exports it.
// font = "" draws the font-free stroke digits used for the engraving. v6.6.8:
// the paper export passes a real font ("Mulish:style=Regular", registered by
// the caller with use <...ttf>); size = text size, 3 -> ~3 mm tall digits,
// matching the stroke digits. The engraved fins always keep the strokes.
module fin_ruler_scale_2d(font = "", size = 3) {
    h = fr_half_range();
    for (v = [-h:h]) {
        translate([0, v - fr_tick_width(v)/2]) square([fr_tick_length(v), fr_tick_width(v)]);
        if (v % 10 == 0) {
            if (font == "") translate([10, v - 1.5]) fr_label(fr_value_text(v));
            else translate([10, v]) text(fr_value_text(v), font = font, size = size,
                                         halign = "left", valign = "center", $fn = 48);
        }
    }
}
