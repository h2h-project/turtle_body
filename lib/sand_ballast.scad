// ==========================================================================
//  Turtle Body -- sand ballast container  (lib module)  EXPERIMENTAL
// --------------------------------------------------------------------------
//  A 3D-printed U-shaped box (bottom tray + snap-on lid) that the builder
//  fills with sand, clicks shut and slides into the gap between the bottom
//  (+Y port) bottle's base and the ballast's orange bottom board. The two
//  arms of the U pass either side of the yellow ballast fin; the U's closed
//  end (the bridge) lies past the board's back edge. Tight under the bottle,
//  it holds the bottle in place.
//
//  Ballast-local frame (lib/ballast_fin.scad): board on Z 0..t, board long
//  axis X, board width Y 0..bl_board_w(); bottle axis at
//  [bl_center_slot(), bl_core_w()/2]; yellow fin centred on X =
//  bl_center_slot(), running from Y = bl_center_slot_depth() +
//  bl_fin_slot_depth() toward -Y.
//
//  Box frame (this file): X across the box, centred on the fin slot; Y = 0
//  at the open (fin-side) end, +Y toward the bridge; Z = 0 the floor
//  underside. sb_installed() maps it into the ballast-local frame.
//
//  Not built, filled or tested. 0.4 mm walls are a single extrusion line.
//
//  Definitions only. Geometry is emitted by the modules below.
// ==========================================================================

use <params.scad>
use <ballast_fin.scad>

// ---- physical inputs ----------------------------------------------------
function sb_wall_t()          = 0.4;   // side walls (one 0.4 mm extrusion line)
function sb_floor_t()         = 0.4;   // tray floor (perpendicular, also on the back chamfer)
function sb_lid_t()           = 0.4;   // lid plate (perpendicular, also on the front chamfer)
function sb_front_overhang()  = 50;    // past the bottle's fin-side edge
function sb_back_overhang()   = 60;    // past the board's back edge (Y = board width); v6.7.1: was 50
function sb_side_clear()      = 0.5;   // per side, to each green core slat face
function sb_fin_clear()       = 0.5;   // per side, slot wall to the yellow fin
function sb_fin_end_clear()   = 1.0;   // slot root past the fin's inner end
function sb_vert_clear()      = 0.5;   // total, box height below the bottle base

// 45 deg end cuts (v6.7.1), in the turtle's cutting style: the front (open,
// fin-side) end loses its TOP edge, the back (bridge) end its BOTTOM edge.
// Each leaves a vertical end face sb_end_face_h() tall.
function sb_end_face_h()      = 8;

// snap ("click") seal: a thickened rim band at the tray top with a V groove,
// and a lid skirt that drops inside the band with a V bead. Depths are
// measured perpendicular to the top surface, so they follow the front cut.
function sb_rim_t()           = 1.2;   // rim band thickness (inward from the outer face)
function sb_rim_h()           = 5.0;   // rim band depth, below the tray top
function sb_skirt_t()         = 0.8;   // lid skirt thickness
function sb_skirt_fit()       = 0.15;  // per side, skirt outer face to rim inner face
function sb_groove_depth()    = 0.4;   // into the rim band
function sb_bead_depth()      = 0.4;   // out from the skirt (interference = depth - fit)
function sb_snap_h()          = 1.6;   // groove / bead height (V, 45 deg flanks)
function sb_snap_z()          = 2.5;   // groove / bead centre, below the tray top

// ---- derived ------------------------------------------------------------
// Bottle-base gap in the installed turtle. In src/Full_Turtle.scad the green
// slat top starts at the port entrance (outer John face - t), is then pushed
// one port_length into the port (ballast_vertical_lift), and the bottle cap
// is inserted cap_h + port_height past the outer John face. Net:
//   gap = port_height + 2t - port_length   (26 mm at the 84 mm reference).
// The full turtle asserts its placed geometry equals this.
function sb_bottle_gap()      = p_port_height() + 2 * p_wood_t() - p_port_length();

function sb_height()          = sb_bottle_gap() - sb_vert_clear();          // closed box
function sb_tray_h()          = sb_height() - sb_lid_t();                   // tray, flat part
function sb_width()           = p_bottle_d() - 2 * sb_side_clear();         // between slats
function sb_slot_w()          = p_wood_t() + 2 * sb_fin_clear();
function sb_front_chamfer()   = sb_height() - sb_end_face_h();              // 17.5
function sb_back_chamfer()    = sb_height() - sb_end_face_h();              // 17.5

// ballast-local Y of the features the box is sized from
function sb_bottle_axis_y()   = bl_core_w() / 2;
function sb_fin_inner_y()     = bl_center_slot_depth() + bl_fin_slot_depth();
function sb_y0_local()        = sb_bottle_axis_y() - p_bottle_d() / 2 - sb_front_overhang();
function sb_y1_local()        = bl_board_w() + sb_back_overhang();
function sb_length()          = sb_y1_local() - sb_y0_local();
function sb_slot_len()        = sb_fin_inner_y() + sb_fin_end_clear() - sb_y0_local();
function sb_arm_w()           = (sb_width() - sb_slot_w()) / 2;

module sb_assert_valid() {
    assert(sb_bottle_gap() > 0, "sand ballast: no gap between bottle base and board.");
    assert(sb_end_face_h() >= sb_lid_t() + sb_rim_h() + (sb_rim_t() - sb_wall_t())
                              + sb_floor_t() + 1,
           "sand ballast: end faces too short for lid, snap rim and floor.");
    assert(sb_front_chamfer() > 0 && sb_front_chamfer() <= sb_front_overhang(),
           "sand ballast: front cut would reach under the bottle.");
    assert(sb_back_chamfer() > 0 && sb_back_chamfer() <= sb_back_overhang(),
           "sand ballast: back cut would lift the box off the board.");
    assert(sb_arm_w() > 2 * sb_rim_t() + 2 * (sb_skirt_fit() + sb_skirt_t()) + 2,
           "sand ballast: arms too narrow for the rim band and lid skirt.");
    assert(sb_slot_len() < sb_length() - sb_back_chamfer() - 2 * sb_rim_t() - 2,
           "sand ballast: fin slot leaves no bridge at the closed end.");
    assert(sb_y1_local() > sb_fin_inner_y() + sb_fin_end_clear(),
           "sand ballast: bridge would hit the yellow fin.");
    assert(sb_rim_t() - sb_groove_depth() >= sb_wall_t(),
           "sand ballast: groove would cut through the rim band.");
    assert(sb_bead_depth() > sb_skirt_fit(),
           "sand ballast: bead does not interfere with the rim -- no click.");
    assert(sb_snap_h() >= 2 * max(sb_groove_depth(), sb_bead_depth()),
           "sand ballast: snap V flanks flatter than 45 deg -- needs support.");
    assert(sb_snap_z() + sb_snap_h() / 2 < sb_rim_h() - 0.5
           && sb_snap_z() - sb_snap_h() / 2 > 0.5,
           "sand ballast: snap groove/bead runs off the rim band.");
}

// ---- 2D plan outline (box frame, XY) ------------------------------------
// U outline: full rectangle minus the fin slot open at Y = 0.
module sb_outline_2d() {
    e = 0.01;
    difference() {
        translate([-sb_width() / 2, 0]) square([sb_width(), sb_length()]);
        translate([-sb_slot_w() / 2, -e]) square([sb_slot_w(), sb_slot_len() + e]);
    }
}

// band between two inward offsets of the outline (a outer, b > a inner)
module sb_band_2d(a, b)
    difference() {
        offset(delta = -a) sb_outline_2d();
        offset(delta = -b) sb_outline_2d();
    }

// ---- 2D side profiles (box frame, YZ: u = Y, v = Z) ----------------------
// Region below the box's top surface (flat at sb_height(), cut 45 deg at the
// front), shrunk d mm perpendicular to that surface. Open below / beyond.
function sb_big() = 1000;
module sb_below_top_2d(d) {
    B = sb_big(); H = sb_height(); c = sb_front_chamfer();
    offset(delta = -d)
        polygon([[-B, -B], [B, -B], [B, H], [c, H], [c - B, H - B]]);
}
// Region above the floor (flat at Z = 0, cut 45 deg at the back), shrunk d.
module sb_above_floor_2d(d) {
    B = sb_big(); L = sb_length(); c = sb_back_chamfer();
    offset(delta = -d)
        polygon([[-B, 0], [L - c, 0], [L - c + B, B], [-B, B]]);
}
// Slab between perpendicular depths d1 < d2 below the top surface.
module sb_top_slab_2d(d1, d2)
    difference() { sb_below_top_2d(d1); sb_below_top_2d(d2); }

// extrude a YZ profile across the full box width (X)
module sb_yz(w = 400)
    rotate([90, 0, 90]) linear_extrude(height = w, center = true) children();

// plan outline (XY) extruded through everything
module sb_xy(h = 400)
    translate([0, 0, -h / 2]) linear_extrude(height = h) children();

// V ring reaching OUTWARD from the plan face at inward offset a_face, centred
// d_c below the top surface: depth d at its centre, 0 at +-h/2. Groove
// cutter (subtracted from the rim band) and lid bead (added) alike.
module sb_v_ring(d_c, h, a_face, d, n = 8) {
    dz = h / n;
    for (k = [0 : n - 1]) {
        zm = -h / 2 + (k + 0.5) * dz;
        dk = d * (1 - abs(zm) / (h / 2));
        intersection() {
            sb_xy() sb_band_2d(a_face - dk, a_face + 0.001);
            sb_yz() sb_top_slab_2d(d_c - h / 2 + k * dz - 0.0005,
                                   d_c - h / 2 + (k + 1) * dz + 0.0005);
        }
    }
}

// ---- parts (box frame, installed orientation) ---------------------------
module sand_ballast_bottom() {
    sb_assert_valid();
    lt = sb_lid_t();
    difference() {
        intersection() {
            union() {
                // thin shell: walls + floor (follows the back cut), open on top
                difference() {
                    sb_xy() sb_outline_2d();
                    intersection() {
                        sb_xy() offset(delta = -sb_wall_t()) sb_outline_2d();
                        sb_yz() sb_above_floor_2d(sb_floor_t());
                    }
                }
                // rim band under the lid, following the front cut
                intersection() {
                    sb_xy() sb_band_2d(0, sb_rim_t());
                    sb_yz() sb_top_slab_2d(lt - 0.01, lt + sb_rim_h());
                }
                // 45 deg shoulder under the rim band (prints without support)
                sb_v_shoulder(lt + sb_rim_h());
            }
            // outer envelope: below the lid, above the board, both cuts
            sb_yz() intersection() {
                sb_below_top_2d(lt);
                sb_above_floor_2d(0);
            }
        }
        // click groove in the rim band's inner face
        sb_v_ring(lt + sb_snap_z(), sb_snap_h(), sb_rim_t() + 0.01, sb_groove_depth() + 0.01);
    }
}

module sb_v_shoulder(d_top, n = 8) {
    w = sb_rim_t() - sb_wall_t();
    dz = w / n;
    for (k = [0 : n - 1])
        intersection() {
            sb_xy() sb_band_2d(0, sb_rim_t() - (k + 0.5) * dz);
            sb_yz() sb_top_slab_2d(d_top + k * dz - 0.0005, d_top + (k + 1) * dz + 0.0005);
        }
}

// lid in its closed position: plate (flat + the 45 deg front panel) on top,
// skirt hanging inside the rim band.
module sand_ballast_lid() {
    sb_assert_valid();
    lt = sb_lid_t();
    a = sb_rim_t() + sb_skirt_fit();             // skirt outer face inset
    skirt_h = sb_rim_h() - 0.5;
    intersection() {
        union() {
            intersection() {
                sb_xy() sb_outline_2d();
                sb_yz() sb_top_slab_2d(0, lt);
            }
            intersection() {
                sb_xy() sb_band_2d(a, a + sb_skirt_t());
                sb_yz() sb_top_slab_2d(lt - 0.01, lt + skirt_h);
            }
            sb_v_ring(lt + sb_snap_z(), sb_snap_h(), a, sb_bead_depth());
        }
        sb_yz() sb_above_floor_2d(0);
    }
}

// ---- print poses ---------------------------------------------------------
// tray: floor on the bed (already). lid: flat plate on the bed, skirt up; the
// front panel rises off the bed at 45 deg.
module sand_ballast_bottom_print() sand_ballast_bottom();
module sand_ballast_lid_print()
    translate([0, 0, sb_height()]) mirror([0, 0, 1]) sand_ballast_lid();

// Outer envelope of the closed box, as one solid (sim displacement).
module sand_ballast_envelope()
    intersection() {
        sb_xy() sb_outline_2d();
        sb_yz() intersection() { sb_below_top_2d(0); sb_above_floor_2d(0); }
    }

// The sand space of the closed box (sim fill level / volume estimates).
module sand_ballast_fill()
    difference() {
        sand_ballast_envelope();
        sand_ballast_bottom();
        sand_ballast_lid();
    }

// ---- closed box + installation into the ballast-local frame --------------
module sand_ballast_closed(colored = true) {
    color(colored ? [0.86, 0.74, 0.48] : [0.80, 0.80, 0.78]) sand_ballast_bottom();
    color(colored ? [0.95, 0.86, 0.60] : [0.88, 0.88, 0.86]) sand_ballast_lid();
}

// Floor on the board's inner face (ballast-local Z = t).
// what = "closed" (tray + lid), "envelope" (one outer solid) or "fill".
module sb_installed(colored = true, what = "closed")
    translate([bl_center_slot(), sb_y0_local(), p_wood_t()])
        if (what == "envelope") sand_ballast_envelope();
        else if (what == "fill") sand_ballast_fill();
        else sand_ballast_closed(colored);

module sand_ballast_echo()
    echo("SAND BALLAST: L x W x H = ", sb_length(), sb_width(), sb_height(),
         " | bottle gap = ", sb_bottle_gap(),
         " | fin slot w x len = ", sb_slot_w(), sb_slot_len(),
         " | arm w = ", sb_arm_w(),
         " | front top / back bottom 45 deg cuts = ", sb_front_chamfer(), sb_back_chamfer(),
         " | end faces = ", sb_end_face_h());
