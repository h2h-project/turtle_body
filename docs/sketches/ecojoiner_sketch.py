#!/usr/bin/env python3
"""Pen-sketch illustration of the Ecojoiner with bottles in some of its six ports.

The geometry is exported per part from lib/ecojoiner.scad and lib/bottle_mockup.scad
through OpenSCAD, so the drawing follows the model. This script only draws it:
hidden lines are removed against a depth buffer, then every visible line becomes a
slightly wobbly ink stroke, with hatching for shade. Output is a black-on-white SVG.

    .venv/bin/python docs/sketches/ecojoiner_sketch.py --ports=+X,-X,+Z --png
"""
import argparse
import shutil
import subprocess
import tempfile
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import numpy as np
import trimesh
from scipy import ndimage
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components

REPO = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent

# Parts 0-11: the four Johns of each of the three rectangles (with their M5 clamps),
# 12-15: the Final Keys, 16: one bottle seated in the +Z port. Frame centre at origin.
SCAD = r"""
use <{lib}/ecojoiner.scad>
use <{lib}/bottle_mockup.scad>
use <{lib}/params.scad>
part = 0;
$fa = 3; $fs = 0.6;
fc = eco_frame_center();
rots = [[0, 0, 0], [0, 90, 90], [90, 0, 90]];
module john(r, j)
    rotate(rots[r]) translate(-fc) {
        if (j == 0) eco_standing_little_john(0, +1, false, false, false, is_master = (r == 2));
        if (j == 1) eco_standing_little_john(eco_rectangle_y(), -1, false, false, false);
        if (j == 2) eco_standing_flipped_long_john(eco_little_slot_1_x(), false);
        if (j == 3) eco_standing_flipped_long_john(eco_little_slot_2_x(), false);
    }
kx = eco_final_key_x_offset();
kz = eco_final_key_z_offset();
keys = [[-kx, -kz], [-kx, kz], [kx, -kz], [kx, kz]];
if (part < 12) john(floor(part / 4), part % 4);
else if (part < 16)
    translate(-fc) eco_inserted_final_key(keys[part - 12][0], keys[part - 12][1], false);
else
    translate([0, 0, eco_john_length() / 2 + p_bottle_h() - p_bottle_cap_h() - p_port_height()])
        rotate([180, 0, 0]) parametric_bottle();
"""
N_PARTS = 17
AXES = {"+X": (1, 0, 0), "-X": (-1, 0, 0), "+Y": (0, 1, 0),
        "-Y": (0, -1, 0), "+Z": (0, 0, 1), "-Z": (0, 0, -1)}

PAINT_OF_KIND = {"board": "wood", "bottle": "bottle", "soft": "mattress", "metal": None, "ground": None, "masonry": None}
WASHES = {"ground": "#93a1b5", "wood": "#d6a25f", "ply": "#e4c189", "bottle": "#9fd3de",
          "mattress": "#f0e0b8", "pillow": "#bfd3ea", "blanket": "#c9523a", "rug": "#d98a4e", "glow": "#ffcf4d"}

CREASE = np.radians(40)   # sharper than this between two faces = a drawn edge
EPS = 0.35                # mm of depth slack in the visibility test


def export_parts(work, openscad):
    work.mkdir(parents=True, exist_ok=True)
    scad = work / "parts.scad"
    scad.write_text(SCAD.replace("{lib}", str(REPO / "lib")))
    newest = max(p.stat().st_mtime for p in (REPO / "lib").glob("*.scad"))

    def run(i):
        out = work / f"part{i:02d}.stl"
        if not out.exists() or out.stat().st_mtime < newest:
            subprocess.run([openscad, "-o", str(out), "-D", f"part={i}", str(scad)],
                           check=True, capture_output=True)
        return out

    with ThreadPoolExecutor(8) as pool:
        return list(pool.map(run, range(N_PARTS)))


class Part:
    def __init__(self, kind, mesh):
        self.kind = kind
        self.buried = False                    # below the ground: drawn dashed
        self.paint = PAINT_OF_KIND[kind]       # which watercolour wash covers it
        self.V = np.asarray(mesh.vertices, float)
        self.F = np.asarray(mesh.faces)
        self.N = np.asarray(mesh.face_normals, float)
        self.area = np.asarray(mesh.area_faces, float)
        self.adj = np.asarray(mesh.face_adjacency)
        self.adj_edges = np.asarray(mesh.face_adjacency_edges)
        self.adj_angle = np.asarray(mesh.face_adjacency_angles)
        self.cen = self.V[self.F].mean(1)

    def groups(self, max_angle):
        """Face indices of each patch whose neighbours meet at less than max_angle."""
        a, b = self.adj[self.adj_angle <= max_angle].T
        n = len(self.F)
        _, label = connected_components(coo_matrix((np.ones(len(a)), (a, b)), shape=(n, n)),
                                        directed=False)
        order = np.argsort(label, kind="stable")
        return np.split(order, np.cumsum(np.bincount(label))[:-1])


def load_parts(stls, ports, layout, screws, bed_width=3, wall=(5, 3)):
    joiner = []
    for stl in stls[:16]:
        comps = sorted(trimesh.load(stl, process=True).split(only_watertight=False),
                       key=lambda c: -c.area)
        joiner.append(("board", comps[0]))
        joiner += [("metal", c) for c in comps[1:]]
    bottle = trimesh.load(stls[16], process=True)
    grids = {"cube": (2, 2, 2), "bed": (4, bed_width, 1), "wall": (wall[0] + 1, 1, wall[1] + 1)}
    if layout in grids:
        # A bottle is an edge: cap seated in one joiner, base butted against the Little
        # John that floors the facing port of the next (the board of part 4, normal to X).
        stop = max(c.bounds[1, 0] for c in trimesh.load(stls[4], process=True).split(only_watertight=False)
                   if c.area > 5000)
        edge = bottle.bounds[1, 2] + stop
        grid = {(i, j, k) for i in range(grids[layout][0]) for j in range(grids[layout][1])
                for k in range(grids[layout][2])}
        if layout == "wall":      # a square standing out from the foot of each end, as a brace
            grid |= {(i, -1, k) for i in (0, grids[layout][0] - 1) for k in (0, 1)}
        held = {g: set() for g in grid}
        bottles = []                                  # (grid point of the cap end, port)
        for g in sorted(grid):
            for a in range(3):
                nxt = tuple(g[i] + (i == a) for i in range(3))
                if nxt in grid:
                    bottles.append((g, "+" + "XYZ"[a]))
                    held[nxt].add("-" + "XYZ"[a])
            if layout == "bed" or (layout == "wall" and g[2] == 0):
                bottles.append((g, "-Z"))             # a leg / foundation stake, cap up into the port
        print(f"{layout}: {len(grid)} joiners {edge:.1f} mm apart, {len(bottles)} bottles")
    else:
        edge, held = 0.0, {(0, 0, 0): set()}
        bottles = [((0, 0, 0), p) for p in ports]
    xfs = []
    for g, port in bottles:
        held[g].add(port)
        M = trimesh.geometry.align_vectors([0, 0, 1], AXES[port])
        M[:3, 3] = np.array(g) * edge
        xfs.append(M)
    parts = []
    for g, ports_held in held.items():
        for kind, mesh in joiner:
            if kind == "metal" and screws != "all":
                # a clamp belongs to the port whose axis its centroid lies furthest along
                cen = mesh.centroid
                a = int(np.argmax(np.abs(cen)))
                if (("+-"[int(cen[a] < 0)] + "XYZ"[a]) in ports_held) != (screws == "bottle-ports"):
                    continue
            m = mesh.copy()
            m.apply_translation(np.array(g) * edge)
            parts.append(Part(kind, m))
    for M in xfs:
        m = bottle.copy()
        m.apply_transform(M)
        parts.append(Part("bottle", m))
    for part, (g, port) in zip(parts[-len(bottles):], bottles):
        part.buried = layout == "wall" and port == "-Z"
    feet = [M[:3, 3] - [0, 0, bottle.bounds[1, 2]] for (g, port), M in zip(bottles, xfs)
            if layout == "bed" and port == "-Z"]
    if layout == "wall":        # the wall stands on the downward port ends of its bottom row
        reach = max(m.bounds[1, 2] for kind, m in joiner if kind == "board")
        feet = [np.array(g) * edge - [0, 0, reach] for g in held if g[2] == 0]
    return parts, bottle, xfs, feet


def soft_box(lo, hi, r):
    """A cushion: the box lo..hi with every edge and corner rounded to radius r."""
    lo, hi = np.asarray(lo, float), np.asarray(hi, float)
    ball = trimesh.creation.icosphere(subdivisions=3, radius=r).vertices
    pts = [ball + [x, y, z] for x in (lo[0] + r, hi[0] - r) for y in (lo[1] + r, hi[1] - r)
           for z in (lo[2] + r, hi[2] - r)]
    return trimesh.convex.convex_hull(np.vstack(pts))


def rounded_loop(lo, hi, r, z, n=10):
    """Closed rounded rectangle in the plane z."""
    pts = []
    for cx, cy, a0 in ((hi[0] - r, hi[1] - r, 0), (lo[0] + r, hi[1] - r, 90),
                       (lo[0] + r, lo[1] + r, 180), (hi[0] - r, lo[1] + r, 270)):
        a = np.radians(a0 + np.linspace(0, 90, n))
        pts += [[cx + r * np.cos(t), cy + r * np.sin(t), z] for t in a]
    return np.array(pts + pts[:1])


def furnish(lo, hi, stage, rng):
    """What goes on the bed frame: (parts, detail lines). Stage 2 = plywood, 3 = bedding."""
    parts, detail = [], []
    if stage < 2:
        return parts, detail
    ply = 18.0
    top = hi[2]
    sheet = trimesh.creation.box(extents=[hi[0] - lo[0], hi[1] - lo[1], ply])
    sheet.apply_translation([(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, top + ply / 2])
    parts.append(Part("board", sheet))
    parts[-1].paint = "ply"
    for z in (top + ply / 3, top + 2 * ply / 3):            # the plies showing at the edges
        detail.append(rounded_loop(lo[:2] - 0.4, hi[:2] + 0.4, 0.5, z, 2))
    if stage == 2:
        for _ in range(26):                                   # face grain
            y = rng.uniform(lo[1] + 30, hi[1] - 30)
            x0 = rng.uniform(lo[0] + 20, hi[0] - 250)
            x = np.linspace(x0, min(hi[0] - 20, x0 + rng.uniform(150, 600)), 24)
            wave = rng.uniform(3, 10) * np.sin((x - x0) / rng.uniform(90, 220) + rng.uniform(0, 6.28))
            detail.append(np.stack([x, y + wave, np.full_like(x, top + ply + 0.4)], 1))
        return parts, detail

    m_lo = np.array([lo[0] + 15, lo[1] + 15, top + ply])
    m_hi = np.array([hi[0] - 15, hi[1] - 15, top + ply + 200])
    parts.append(Part("soft", soft_box(m_lo, m_hi, 45)))
    for z in (m_lo[2] + 32, m_hi[2] - 32):                   # piped seams
        detail.append(rounded_loop(m_lo[:2] - 0.6, m_hi[:2] + 0.6, 45, z))

    depth = 380                                              # two pillows at the head
    gap = (m_hi[1] - m_lo[1]) * 0.04
    half = (m_hi[1] - m_lo[1] - 3 * gap) / 2
    for i in range(2):
        y0 = m_lo[1] + gap + i * (half + gap)
        parts.append(Part("soft", soft_box([m_lo[0] + 50, y0, m_hi[2] - 12],
                                           [m_lo[0] + 50 + depth, y0 + half, m_hi[2] + 118], 62)))
        parts[-1].paint = "pillow"

    r = 55.0                                                 # blanket: over the foot, down the sides
    b_lo = np.array([m_lo[0] + 0.36 * (m_hi[0] - m_lo[0]), lo[1] - 28, top - 170])
    b_hi = np.array([hi[0] + 28, hi[1] + 28, m_hi[2] + 14])
    parts.append(Part("soft", soft_box(b_lo, b_hi, r)))
    parts[-1].paint = "blanket"
    arc = np.radians(np.linspace(0, 90, 8))
    e = 0.8
    xs = [b_lo[0] + 150]                                     # the turned-back fold, then stripes
    x = b_lo[0] + 330
    while x < b_hi[0] - r - 40:
        xs += [x, x + 22]
        x += 190
    for x in xs:
        ya, yb, zt, zb = b_lo[1] - e, b_hi[1] + e, b_hi[2] + e, b_lo[2] + r
        yz = ([[ya, zb], [ya, zt - r]]
              + [[ya + r - r * np.cos(t), zt - r + r * np.sin(t)] for t in arc]
              + [[yb - r + r * np.sin(t), zt - r + r * np.cos(t)] for t in arc]
              + [[yb, zt - r], [yb, zb]])
        detail.append(np.array([[x, y, z] for y, z in yz]))
    return parts, detail


def tent(lo, hi, ground, rng, gap=2300.0, slope=20.0, cozy=False):
    """A ruined building wall facing the foot of the Ecojoiner wall, and a tarpaulin from its
    top, down over the Ecojoiner wall at `slope` degrees and on to the ground.

    lo, hi: bounds of the Ecojoiner wall's boards (it stands in the plane y = 0, feet toward -y).
    Returns (solid parts, detail lines, the tarpaulin as a two-sided sheet for the wash).
    """
    import manifold3d as m3
    top = hi[2] + 8                                        # tarp over the wall's top port ends
    lo_y_foot = -lo[1] - hi[1]                             # how far the foot squares stand out
    reach = hi[1]                                          # half depth of the wall
    attach = top + (gap - reach) * np.tan(np.radians(slope))
    thick, course, block = 300.0, 200.0, 400.0
    x0, x1 = lo[0] - 180, hi[0] + 180                      # tarp width

    # masonry: columns one block wide, broken off at different heights beyond the tarp
    cols, heights = [], {}
    xs = np.arange(lo[0] - 3 * block, hi[0] + 3 * block, block)
    for i, x in enumerate(xs):
        under = x + block > x0 - 50 and x < x1 + 50
        if under:
            h = attach - ground
        elif x < x0:
            h = attach - ground + course * [1, 3, 2][i % 3]
        else:
            h = attach - ground - course * [2, 5, 7][min(2, int((x - x1) // block))]
        heights[x] = ground + h
        cols.append(m3.Manifold.cube([block + 0.5, thick, h]).translate([x, -gap - thick, ground]))
    wall = cols[0]
    for c in cols[1:]:
        wall = wall + c
    wx = lo[0] + 0.55 * (hi[0] - lo[0])
    wall = wall - m3.Manifold.cube([700, thick + 20, 900]).translate([wx, -gap - thick - 10, ground + 1000])
    mesh = wall.to_mesh()
    ruin = Part("masonry", trimesh.Trimesh(np.asarray(mesh.vert_properties)[:, :3], np.asarray(mesh.tri_verts)))
    parts, detail = [ruin], []
    for z in np.arange(ground + course, attach + 3 * course, course):      # a few block joints
        for x in xs:
            if z > heights[x] - 20 or (wx - block < x < wx + 700 and ground + 800 < z < ground + 2100):
                continue
            if rng.random() < 0.45:
                a, b = x + rng.uniform(0, 60), x + block - rng.uniform(0, 60)
                detail.append(np.array([[a, -gap + 1, z], [b, -gap + 1, z]]))
            if rng.random() < 0.3:
                xj = x + (block / 2 if int(z / course) % 2 else 0)
                detail.append(np.array([[xj, -gap + 1, z - course + 15], [xj, -gap + 1, z - 15]]))

    # tarp cross-section (y, z): over the ruin's top, down the slope with a little sag,
    # across the Ecojoiner wall's top, then straight down to the ground
    t = np.linspace(0, 1, 14)[1:-1]
    sag = 45 * np.sin(np.pi * t)
    yz = ([[-gap - 240, attach + 6], [-gap, attach + 6]]
          + [[-gap + u * (gap - reach), attach + 6 + u * (top - attach - 6) - d] for u, d in zip(t, sag)]
          + [[-reach, top], [reach, top]]
          + [[reach + 14, top - u * (top - ground - 6)] for u in np.linspace(0.08, 1, 9)])
    yz = np.array(yz)
    n = len(yz)
    section = lambda x: np.stack([np.full(n, x), yz[:, 0], yz[:, 1]], 1)
    xg = np.linspace(x0, x1, 25)
    grid_pts = np.array([section(x) for x in xg])              # (25, n, 3)
    V = grid_pts.reshape(-1, 3)
    quad = lambda i, j: [i * n + j, (i + 1) * n + j, (i + 1) * n + j + 1, i * n + j + 1]
    F = []
    for i in range(len(xg) - 1):
        for j in range(n - 1):
            a, b, c, d = quad(i, j)
            F += [[a, b, c], [a, c, d], [a, c, b], [a, d, c]]   # both sides
    # The tarp is wider than the wall: the overhang folds down over each end like wrapping a
    # parcel. The far end is closed; the near end keeps a door, its flap tied back to the foot.
    prof = np.vstack([yz[1:16], [[reach + 14, top]]])            # roof line, ruin to drop
    V, ends = list(V), []

    def strip(x, pts):
        base = len(V)
        for y, z in pts:
            V.extend([[x, y, z], [x, y, ground + 6]])
        for i in range(len(pts) - 1):
            a, b, c, d = base + 2 * i, base + 2 * i + 1, base + 2 * i + 3, base + 2 * i + 2
            F.extend([[a, b, c], [a, c, d], [a, c, b], [a, d, c]])

    roof_z = lambda y: np.interp(y, prof[:, 0], prof[:, 1])
    xe = x0 - 8                                                   # closed end
    strip(xe, prof)
    detail.append(np.array([[xe, y, ground + 6] for y in np.linspace(-gap, reach + 14, 20)])
                  + [0, 0, 1] * (12 * np.sin(np.linspace(0, 12, 20)))[:, None])
    detail.append(np.array([[xe, -gap, roof_z(-gap)], [xe, -gap, ground + 6]]))
    for y_top, y_bot in ((-gap + 60, -gap * 0.45), (reach - 40, -gap * 0.38)):      # parcel folds
        detail.append(np.array([[xe - 3, y_top, roof_z(y_top) - 30], [xe - 3, y_bot, ground + 300]]))
    xe = x1 + 8                                                   # door end
    door = -gap * 0.42
    closed = np.vstack([prof[prof[:, 0] < door], [[door, roof_z(door)]]])
    strip(xe, closed)
    detail.append(np.array([[xe, door, roof_z(door)], [xe, door, ground + 6]]))
    detail.append(np.array([[xe, -gap, roof_z(-gap)], [xe, -gap, ground + 6]]))
    detail.append(np.array([[xe, y, ground + 6] for y in np.linspace(-gap, door, 10)]))
    detail.append(np.array([[xe + 3, -gap + 60, roof_z(-gap + 60) - 30], [xe + 3, door - 150, ground + 300]]))
    tie = np.array([xe + 30, -lo_y_foot, ground + 1050])           # the flap, gathered and tied back
    lintel = np.vstack([[[door, roof_z(door)]], prof[prof[:, 0] > door]])
    base = len(V)
    V.append(list(tie))
    V.extend([[xe, y, z] for y, z in lintel])
    for i in range(len(lintel) - 1):
        F.extend([[base, base + 1 + i, base + 2 + i], [base, base + 2 + i, base + 1 + i]])
    for y, z in lintel[::2]:
        detail.append(np.array([[xe, y, z], tie + [0, (y - tie[1]) * 0.08, (z - tie[2]) * 0.05]]))
    detail.append(np.array([[xe, lintel[-1, 0], lintel[-1, 1]], tie]))
    detail.append(np.array([tie, [hi[0], -lo_y_foot, ground + 4.5 * reach]]))   # cord to the foot square's upper joiner
    for x_end, ys in ((x0 - 100, (-gap * 0.75, -gap * 0.3)), (x1 + 100, (-gap * 0.78,))):
        for y in ys:                                              # stones on the end hems
            stone = trimesh.creation.box(extents=[150, 190, 100])
            stone.apply_translation([x_end, y, ground + 50])
            parts.append(Part("board", stone))
    V = np.array(V)
    sheet = Part("ground", trimesh.Trimesh(V, F, process=False))

    detail += [section(x0), section(x1)]                                       # the two ends
    for j, part_len in ((0, 1.0), (1, 0.5), (n - 11, 0.6), (n - 10, 0.6), (n - 1, 1.0)):
        line = grid_pts[:, j].copy()                                           # edges and folds
        if j == n - 1:
            line[:, 1] += 25 * np.sin(np.linspace(0, 9 * np.pi, len(xg)))     # a wavy hem
        if part_len == 1.0:
            detail.append(line)
        else:
            for a in range(0, len(xg) - 4, 6):
                if rng.random() < part_len:
                    detail.append(line[a:a + rng.integers(3, 6)])
    for _ in range(9):                                                         # wrinkles on the slope
        x = rng.uniform(x0 + 100, x1 - 100)
        a = rng.integers(1, 8)
        detail.append(section(x)[a:a + rng.integers(3, 6)] + [0, 0, 3])
    for x in np.linspace(x0 + 150, x1 - 150, 7) + rng.uniform(-60, 60, 7):     # folds in the drop
        a = n - 9 + rng.integers(0, 3)
        fold = section(x)[a:n - rng.integers(0, 3)].copy()
        fold[:, 0] += 30 * np.sin(np.linspace(0, 2.5, len(fold)) + rng.uniform(0, 3))
        detail.append(fold + [0, 4, 0])

    def brick(c, size):
        b = trimesh.creation.box(extents=size)
        b.apply_transform(trimesh.transformations.rotation_matrix(rng.uniform(-0.4, 0.4), [0, 0, 1]))
        b.apply_translation(c)
        parts.append(Part("board", b))
    for x in np.linspace(x0 + 120, x1 - 120, 6):                               # weights on the top edge
        brick([x + rng.uniform(-40, 40), -gap - 130, attach + 6 + 45], [230, 120, 90])
    for x in np.linspace(x0 + 100, x1 - 100, 5):                               # stones on the hem
        brick([x + rng.uniform(-60, 60), yz[-1, 0] + 95, ground + 50], [190, 150, 100])

    sheet.glow = None
    if not cozy:
        return parts, detail, sheet

    # --- making it a home: a bed along the ruin, a rug, cushions, a crate, a lantern ---
    def soft(lo_, hi_, r, paint):
        parts.append(Part("soft", soft_box(lo_, hi_, r)))
        parts[-1].paint = paint
    bx0, bx1 = lo[0] + 60, lo[0] + 1960
    by0, by1 = -gap + 40, -gap + 860
    soft([bx0, by0, ground], [bx1, by1, ground + 170], 40, "mattress")
    soft([bx1 - 420, by0 + 60, ground + 150], [bx1 - 40, by1 - 60, ground + 270], 55, "pillow")
    soft([bx0 - 12, by0 - 10, ground + 20], [bx1 - 560, by1 + 14, ground + 190], 45, "blanket")
    for x in np.arange(bx0 + 80, bx1 - 700, 170):                              # blanket stripes
        detail.append(np.array([[x, by0 + 40, ground + 191], [x, by1 - 30, ground + 191]]))
        detail.append(np.array([[x + 20, by0 + 40, ground + 191], [x + 20, by1 - 30, ground + 191]]))
    rx0, rx1, ry0, ry1 = lo[0] + 250, lo[0] + 1900, by1 + 110, -hi[1] - 470
    rug = trimesh.creation.box(extents=[rx1 - rx0, ry1 - ry0, 14])
    rug.apply_translation([(rx0 + rx1) / 2, (ry0 + ry1) / 2, ground + 7])
    parts.append(Part("board", rug))
    parts[-1].paint = "rug"
    for inset in (45, 80):                                                     # rug border
        detail.append(rounded_loop(np.array([rx0 + inset, ry0 + inset]), np.array([rx1 - inset, ry1 - inset]),
                                   6, ground + 15, 2))
    for x in np.arange(rx0 + 180, rx1 - 150, 150):                             # and a diamond pattern
        cy, h = (ry0 + ry1) / 2, (ry1 - ry0) / 2 - 130
        detail.append(np.array([[x, cy, ground + 15], [x + 75, cy + h, ground + 15], [x + 150, cy, ground + 15],
                                [x + 75, cy - h, ground + 15], [x, cy, ground + 15]]))
    for cx, cy, ang in ((rx0 + 330, ry0 + 260, 0.3), (rx0 + 760, ry0 + 330, -0.5)):   # floor cushions
        cushion = soft_box([-190, -190, 0], [190, 190, 110], 50)
        cushion.apply_transform(trimesh.transformations.rotation_matrix(ang, [0, 0, 1]))
        cushion.apply_translation([cx, cy, ground + 14])
        parts.append(Part("soft", cushion))
        parts[-1].paint = "pillow"
    crate = trimesh.creation.box(extents=[380, 380, 300])
    crate.apply_translation([rx1 - 260, ry0 + 260, ground + 164])
    parts.append(Part("board", crate))
    pot = trimesh.creation.cylinder(radius=70, height=120, sections=28)
    pot.apply_translation([rx1 - 260, ry0 + 260, ground + 374])
    parts.append(Part("soft", pot))
    parts[-1].paint = "glow"
    lx, ly = (lo[0] + hi[0]) / 2, -gap * 0.52                                  # lantern under the tarp
    u = (ly + gap) / (gap - reach)
    roof = attach + 6 + u * (top - attach - 6) - 45 * np.sin(np.pi * u)
    lamp = trimesh.creation.cylinder(radius=65, height=170, sections=28)
    lamp.apply_translation([lx, ly, roof - 420])
    parts.append(Part("soft", lamp))
    parts[-1].paint = "glow"
    cap = trimesh.creation.cone(radius=95, height=60, sections=28)
    cap.apply_translation([lx, ly, roof - 335])
    parts.append(Part("soft", cap))
    detail.append(np.array([[lx, ly, roof - 275], [lx, ly, roof - 4]]))        # its cord
    sheet.glow = np.array([lx, ly, roof - 420])
    return parts, detail, sheet


class Camera:
    def __init__(self, az, el, dist, target):
        az, el = np.radians([az, el])
        d = np.array([np.cos(el) * np.cos(az), np.cos(el) * np.sin(az), np.sin(el)])
        self.eye = np.asarray(target, float) + dist * d
        f = -d
        r = np.cross(f, [0, 0, 1.0])
        r /= np.linalg.norm(r)
        self.R = np.stack([r, np.cross(r, f), f])
        self.scale, self.off = 1.0, np.zeros(2)

    def project(self, P):
        c = (np.asarray(P, float) - self.eye) @ self.R.T
        s = np.stack([c[:, 0] / c[:, 2], -c[:, 1] / c[:, 2]], 1)
        return s * self.scale + self.off, c[:, 2]

    def fit(self, P, size, margin):
        s, _ = self.project(P)
        lo, span = s.min(0), np.ptp(s, 0)
        self.scale = (size - 2 * margin) / span.max()
        self.off = margin - lo * self.scale
        return np.ceil(span * self.scale + 2 * margin).astype(int)


def rasterize(parts, cam, W, H, zbuf=None, idbuf=None, first_id=0):
    if zbuf is None:
        zbuf = np.full((H, W), np.inf, np.float32)
        idbuf = np.full((H, W), -1, np.int32)
    for pid, part in enumerate(parts, first_id):
        S, Z = cam.project(part.V)
        iz = 1.0 / Z
        front = np.einsum("ij,ij->i", part.N, cam.eye - part.cen) > 0
        for f in part.F[front]:
            (ax, ay), (bx, by), (cx, cy) = S[f]
            area = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
            if abs(area) < 1e-9:
                continue
            x0, x1 = max(int(min(ax, bx, cx)), 0), min(int(max(ax, bx, cx)), W - 1)
            y0, y1 = max(int(min(ay, by, cy)), 0), min(int(max(ay, by, cy)), H - 1)
            if x0 > x1 or y0 > y1:
                continue
            X = np.arange(x0, x1 + 1)[None, :] + 0.5
            Y = np.arange(y0, y1 + 1)[:, None] + 0.5
            w0 = ((bx - X) * (cy - Y) - (by - Y) * (cx - X)) / area
            w1 = ((cx - X) * (ay - Y) - (cy - Y) * (ax - X)) / area
            w2 = 1.0 - w0 - w1
            z = 1.0 / (w0 * iz[f[0]] + w1 * iz[f[1]] + w2 * iz[f[2]])
            zs = zbuf[y0:y1 + 1, x0:x1 + 1]
            hit = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6) & (z < zs)
            zs[hit] = z[hit]
            idbuf[y0:y1 + 1, x0:x1 + 1][hit] = pid
    return zbuf, idbuf


def chain(segs, xyz, max_turn):
    """Join segments (pairs of node ids) into polylines, breaking at junctions and corners."""
    nbr = defaultdict(list)
    for i, (u, v) in enumerate(segs):
        nbr[u].append((i, v))
        nbr[v].append((i, u))

    def turn(a, b, c):
        d1, d2 = xyz[b] - xyz[a], xyz[c] - xyz[b]
        cosang = d1 @ d2 / (np.linalg.norm(d1) * np.linalg.norm(d2) + 1e-12)
        return np.arccos(np.clip(cosang, -1, 1))

    def is_break(node):
        if len(nbr[node]) != 2:
            return True
        return turn(nbr[node][0][1], node, nbr[node][1][1]) > max_turn

    used = np.zeros(len(segs), bool)

    def walk(start, seg, nxt):
        used[seg] = True
        path = [start, nxt]
        while not is_break(path[-1]):
            rest = [(j, w) for j, w in nbr[path[-1]] if not used[j]]
            if not rest:
                break
            used[rest[0][0]] = True
            path.append(rest[0][1])
        return xyz[path]

    out = []
    for only_breaks in (True, False):      # open chains first, then closed loops
        for node in list(nbr):
            if only_breaks and not is_break(node):
                continue
            for seg, nxt in nbr[node]:
                if not used[seg]:
                    out.append(walk(node, seg, nxt))
    return out


def crease_lines(part, eye):
    front = np.einsum("ij,ij->i", part.N, eye - part.cen) > 0
    a, b = part.adj.T
    keep = (part.adj_angle > CREASE) & (front[a] | front[b])
    return chain(part.adj_edges[keep], part.V, np.radians(35))


def silhouette_lines(part, eye):
    """Where a smooth patch turns away from the eye (interpolated vertex normals)."""
    out = []
    for fi in part.groups(CREASE):
        n = part.N[fi]
        if len(fi) < 4 or (n @ n[0] > 0.9999).all():
            continue
        vn = np.zeros_like(part.V)
        for k in range(3):
            np.add.at(vn, part.F[fi, k], n * part.area[fi, None])
        vn /= np.linalg.norm(vn, axis=1, keepdims=True) + 1e-12
        g = np.einsum("ij,ij->i", vn, eye - part.V)
        gf = g[part.F[fi]]
        pos = gf > 0
        mixed = pos.any(1) & ~pos.all(1)
        nodes, xyz, segs = {}, [], []
        for f, gv in zip(part.F[fi][mixed], gf[mixed]):
            ends = []
            for i, j in ((0, 1), (1, 2), (2, 0)):
                if (gv[i] > 0) != (gv[j] > 0):
                    key = (min(f[i], f[j]), max(f[i], f[j]))
                    if key not in nodes:
                        t = gv[i] / (gv[i] - gv[j])
                        nodes[key] = len(xyz)
                        xyz.append(part.V[f[i]] + t * (part.V[f[j]] - part.V[f[i]]))
                    ends.append(nodes[key])
            segs.append(ends)
        if segs:
            out += chain(np.array(segs), np.array(xyz), np.radians(60))
    return out


def hatch_region(tri, n, spacing, angle, rng):
    """Parallel lines across one flat patch (tri: m x 3 x 3), lifted just off its plane."""
    u = np.eye(3)[np.argmin(np.abs(n))]
    u = u - (u @ n) * n
    u /= np.linalg.norm(u)
    v = np.cross(n, u)
    d = np.cos(angle) * u + np.sin(angle) * v
    e = np.cross(n, d)
    A, B = tri @ d, tri @ e
    base = (tri[0, 0] @ n + 0.05) * n
    lines = []
    b = B.min() + spacing * rng.uniform(0.3, 0.9)
    while b < B.max():
        a_cross = np.full(A.shape, np.nan)
        for i, j in ((0, 1), (1, 2), (2, 0)):
            cross = (B[:, i] - b) * (B[:, j] - b) < 0
            t = (b - B[cross, i]) / (B[cross, j] - B[cross, i])
            a_cross[cross, i] = A[cross, i] + t * (A[cross, j] - A[cross, i])
        ok = np.isfinite(a_cross).sum(1) == 2
        spans = sorted(zip(np.nanmin(a_cross[ok], 1), np.nanmax(a_cross[ok], 1)))
        merged = []
        for a0, a1 in spans:
            if merged and a0 <= merged[-1][1] + 1e-3:
                merged[-1][1] = max(merged[-1][1], a1)
            else:
                merged.append([a0, a1])
        for a0, a1 in merged:
            a0 += rng.uniform(0.2, 1.6)
            a1 -= rng.uniform(0.2, 1.6)
            if a1 - a0 > 2.5 and rng.random() > 0.03:
                lines.append(np.array([base + a0 * d + b * e, base + a1 * d + b * e]))
        b += spacing * rng.uniform(0.82, 1.18)
    return lines


def bottle_extras(mesh, light, rng):
    """Label band, base rim, petaloid grooves and shade strokes for the +Z bottle."""
    V = np.asarray(mesh.vertices)
    r_all = np.hypot(V[:, 0], V[:, 1])
    zs = np.unique(np.round(V[:, 2], 2))
    rs = np.array([r_all[np.abs(V[:, 2] - z) < 0.011].max() for z in zs])
    z_base, R = zs.max(), rs.max()
    straight = zs[rs > R - 0.02]
    t0, t1 = z_base - straight.max(), z_base - straight.min()   # along the body, from the base
    base_r = rs[-1]

    def ring(t, radius, n=120):
        phi = np.linspace(0, 2 * np.pi, n + 1) + rng.uniform(0, 6.28)
        return np.stack([radius * np.cos(phi), radius * np.sin(phi),
                         np.full(n + 1, z_base - t)], 1)

    lift = 0.2
    band0 = t0 + 0.28 * (t1 - t0)
    band1 = t0 + 0.68 * (t1 - t0)
    detail = [ring(band0, R + lift), ring(band1, R + lift),
              ring(-lift, base_r), ring(-lift, 0.16 * base_r, 40)]
    # five grooves between the feet: across the base, then up over the rounded edge
    rim = np.argsort(-zs)
    rim = rim[(z_base - zs[rim]) <= t0 * 0.9]
    phi0 = rng.uniform(0, 1.25)
    for k in range(5):
        phi = phi0 + k * 2 * np.pi / 5
        rr = np.concatenate([[0.34 * base_r], rs[rim] + lift])
        zz = np.concatenate([[z_base + lift], zs[rim] + lift * (zs[rim] >= z_base - 3)])
        detail.append(np.stack([rr * np.cos(phi), rr * np.sin(phi), zz], 1))
    shade = []
    for phi in np.radians(np.arange(0, 360, 4.5)):
        s = np.cos(phi) * light[0] + np.sin(phi) * light[1]
        if s > -0.2 or (s > -0.55 and rng.random() < 0.5):
            continue
        a = t0 + rng.uniform(0, 0.12) * (t1 - t0)
        b = t1 - rng.uniform(0, 0.05) * (t1 - t0)
        cuts = [a, b]
        if rng.random() < 0.6:      # lift the pen once along the way
            g = rng.uniform(a + 0.2 * (b - a), b - 0.2 * (b - a))
            cuts = [a, g - rng.uniform(2, 6), g + rng.uniform(2, 6), b]
        for c0, c1 in zip(cuts[::2], cuts[1::2]):
            x, y = (R + lift) * np.cos(phi), (R + lift) * np.sin(phi)
            shade.append(np.array([[x, y, z_base - c0], [x, y, z_base - c1]]))
    return detail, shade


def rdp(pts, tol):
    keep = np.zeros(len(pts), bool)
    keep[[0, -1]] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        i, j = stack.pop()
        if j - i < 2:
            continue
        d = pts[j] - pts[i]
        rel = pts[i + 1:j] - pts[i]
        L = np.hypot(*d)
        dist = np.abs(rel[:, 0] * d[1] - rel[:, 1] * d[0]) / L if L > 1e-9 else np.hypot(*rel.T)
        k = int(np.argmax(dist))
        if dist[k] > tol:
            keep[i + 1 + k] = True
            stack += [(i, i + 1 + k), (i + 1 + k, j)]
    return pts[keep]


class Scene:
    def __init__(self, cam, zbuf):
        self.cam = cam
        self.H, self.W = zbuf.shape
        self.near = ndimage.maximum_filter(zbuf, 3)
        self.far = ndimage.maximum_filter(zbuf, 9)

    def visible(self, P, buried=False):
        """Visible stretches of a 3D polyline: (screen points, is it an outline?).

        buried: instead, the stretches that only the ground hides.
        """
        s, _ = self.cam.project(P)
        n = np.maximum(1, np.ceil(np.linalg.norm(np.diff(s, axis=0), axis=1) / 0.75)).astype(int)
        seg = np.repeat(np.arange(len(n)), n)
        frac = (np.arange(n.sum()) - np.repeat(np.cumsum(n) - n, n)) / np.repeat(n, n)
        Q = np.vstack([P[seg] + (P[seg + 1] - P[seg]) * frac[:, None], P[-1:]])
        s, z = self.cam.project(Q)
        xi, yi = np.floor(s).astype(int).T
        inb = (xi >= 0) & (xi < self.W) & (yi >= 0) & (yi < self.H)
        vis = np.zeros(len(Q), bool)
        vis[inb] = z[inb] <= self.near[yi[inb], xi[inb]] + EPS
        if buried:
            vis[inb] = ~vis[inb] & (z[inb] <= self.open[yi[inb], xi[inb]] + EPS)
        vis |= ndimage.binary_closing(vis, np.ones(5, bool))
        edges = np.flatnonzero(np.diff(np.concatenate([[0], vis.view(np.int8), [0]])))
        runs = []
        for i0, i1 in zip(edges[::2], edges[1::2]):
            if i1 - i0 < 4:
                continue
            jump = self.far[yi[i0:i1], xi[i0:i1]] - z[i0:i1] > 12
            runs.append((rdp(s[i0:i1], 0.4), jump.mean() > 0.5))
        return runs


class Pen:
    def __init__(self, rng, k):
        self.rng, self.k = rng, k

    def stroke(self, pts, wobble=1.0, overshoot=0.0, nib=None):
        """SVG path data for one hand-drawn stroke along pts.

        With nib (a width), the stroke is a filled ribbon instead of a centre line:
        tapered at both ends and thicker across the nib's broad direction.
        """
        rng, k = self.rng, self.k
        seg = np.linalg.norm(np.diff(pts, axis=0), axis=1)
        L = seg.sum()
        if L < 0.5:
            return ""
        s_in = np.concatenate([[0], np.cumsum(seg)])
        ext = overshoot * k * rng.uniform(0.2, 1.0, 2) if L > 30 * k else np.zeros(2)
        s0, s1 = -ext[0], L + ext[1]
        straight = len(pts) == 2
        step = 8 if nib else 22 if straight else 9
        n = max(3 if nib else 2, int(round((s1 - s0) / (step * k))) + 1)
        s = np.linspace(s0, s1, n)
        sc = np.clip(s, 0, L)
        p = np.stack([np.interp(sc, s_in, pts[:, 0]), np.interp(sc, s_in, pts[:, 1])], 1)
        t_a = (pts[1] - pts[0]) / max(seg[0], 1e-9)
        t_b = (pts[-1] - pts[-2]) / max(seg[-1], 1e-9)
        p += np.minimum(s, 0)[:, None] * t_a + np.maximum(s - L, 0)[:, None] * t_b
        tan = np.gradient(p, axis=0)
        tan /= np.linalg.norm(tan, axis=1, keepdims=True) + 1e-12
        nrm = np.stack([-tan[:, 1], tan[:, 0]], 1)
        amp = wobble * 0.9 * k * (1.0 if straight else 0.6)
        off = amp * (0.6 * np.sin(2 * np.pi * s / (rng.uniform(160, 340) * k) + rng.uniform(0, 6.28))
                     + 0.4 * np.sin(2 * np.pi * s / (rng.uniform(50, 110) * k) + rng.uniform(0, 6.28)))
        if straight:
            off += rng.uniform(-1, 1) * wobble * min(1.6 * k, 0.006 * L) * np.sin(np.pi * (s - s0) / (s1 - s0))
        p += off[:, None] * nrm
        if nib:
            run = s1 - s0
            ends = np.minimum(s - s0, s1 - s) / min(16 * k, run / 2)
            taper = np.clip(ends, 0.12, 1) ** 0.7
            broad = 0.55 + 0.45 * np.abs(np.sin(np.arctan2(tan[:, 1], tan[:, 0]) + np.radians(40)))
            press = 1 + 0.15 * np.sin(2 * np.pi * s / (rng.uniform(180, 420) * k) + rng.uniform(0, 6.28))
            half = (nib * k * taper * broad * press / 2)[:, None] * nrm
            edge = np.vstack([p + half, (p - half)[::-1]])
            return "M" + "L".join("%.2f,%.2f" % tuple(q) for q in edge) + "Z"
        if n == 2:
            return "M%.1f,%.1fL%.1f,%.1f" % (*p[0], *p[1])
        q = np.vstack([p[:1], p, p[-1:]])           # Catmull-Rom through the points
        c1 = q[1:-2] + (q[2:-1] - q[:-3]) / 6
        c2 = q[2:-1] - (q[3:] - q[1:-2]) / 6
        return "M%.1f,%.1f" % tuple(p[0]) + "".join(
            "C%.1f,%.1f %.1f,%.1f %.1f,%.1f" % (*a, *b, *c) for a, b, c in zip(c1, c2, p[1:]))


def mask_path(mask, q):
    """SVG path covering a (downsampled by q) boolean mask, as one thin rectangle per run."""
    out = []
    for j, row in enumerate(mask):
        edges = np.flatnonzero(np.diff(np.concatenate([[0], row.view(np.int8), [0]])))
        out += [f"M{a * q},{j * q}h{(b - a) * q}v{q + 1}h{(a - b) * q}z"
                for a, b in zip(edges[::2], edges[1::2])]
    return "".join(out)


def metal_hatch(mask, step):
    """Tight diagonal strokes over the screen area covered by the black hardware."""
    H, W = mask.shape
    lines = []
    for c in range(0, W + H, step):
        x = np.arange(max(0, c - H + 1), min(W - 1, c) + 1)
        if not len(x):
            continue
        m = mask[c - x, x]
        edges = np.flatnonzero(np.diff(np.concatenate([[0], m.view(np.int8), [0]])))
        for i0, i1 in zip(edges[::2], edges[1::2]):
            if i1 - i0 >= 2:
                lines.append(np.array([[x[i0] + 0.5, c - x[i0] + 0.5],
                                       [x[i1 - 1] + 0.5, c - x[i1 - 1] + 0.5]]))
    return lines


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--ports", default="+X,-X,+Z", help="ports that hold a bottle")
    ap.add_argument("--layout", choices=["single", "cube", "bed", "wall"], default="single",
                    help="cube: 8 joiners, 12 bottles as edges; bed: flat grid of joiners, "
                         "4 long, standing on a leg bottle under each; wall: upright grid, "
                         "--wall-size squares")
    ap.add_argument("--wall-size", default="5x3", help="wall squares, long x high")
    ap.add_argument("--tent", action="store_true",
                    help="wall only: add a ruined building wall and a tarpaulin from its top, "
                         "over the Ecojoiner wall and down to the ground")
    ap.add_argument("--bed-width", type=int, default=3, help="joiners across the bed (2 or 3)")
    ap.add_argument("--cozy", action="store_true", help="with --tent: furnish the inside")
    ap.add_argument("--story", action="store_true",
                    help="bed only: three panels - frame, plywood on top, mattress and blanket")
    ap.add_argument("--style", choices=["pen", "fountain"], default="pen")
    ap.add_argument("--screws", choices=["all", "empty-ports", "bottle-ports"], default="all",
                    help="which ports keep their M5 clamp screws drawn")
    ap.add_argument("--az", type=float, default=-58, help="camera azimuth, degrees")
    ap.add_argument("--el", type=float, default=24, help="camera elevation, degrees")
    ap.add_argument("--dist", type=float, help="camera distance, mm (default 2400, cube 4200)")
    ap.add_argument("--size", type=int, help="longest side, px (default 2400, cube 3200)")
    ap.add_argument("--width-mm", type=float, default=160, help="physical width of the SVG")
    ap.add_argument("--pen", type=float, help="pen size relative to the canvas (default 1, wall 0.65)")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--out", type=Path)
    ap.add_argument("--work", type=Path, default=Path(tempfile.gettempdir()) / "ecojoiner_sketch")
    ap.add_argument("--openscad", default=shutil.which("openscad") or "openscad")
    ap.add_argument("--png", action="store_true", help="also export a PNG with Inkscape")
    args = ap.parse_args()
    ports = [p.strip().upper() for p in args.ports.split(",") if p.strip()]
    rng = np.random.default_rng(args.seed)
    args.dist = args.dist or {"single": 2400, "cube": 4200, "bed": 6000, "wall": 11000}[args.layout]
    args.size = args.size or {"single": 2400, "cube": 3200, "bed": 4000, "wall": 5200}[args.layout]
    args.out = args.out or HERE / {"single": "ecojoiner_3_bottles_sketch.svg",
                                   "cube": "ecojoiner_cube_sketch.svg",
                                   "wall": "ecojoiner_tent_sketch.svg" if args.tent
                                   else "ecojoiner_wall_sketch.svg",
                                   "bed": "ecojoiner_bed_story_sketch.svg" if args.story
                                   else "ecojoiner_bed_frame_sketch.svg"}[args.layout]
    k = args.size / 2400 * (args.pen or (0.65 if args.layout == "wall" else 1.0))
    fountain = args.style == "fountain"
    widths = ({"hatch": 0.8, "metal": 1.0, "buried": 1.3, "detail": 1.6, "edge": 2.3, "outline": 3.8} if fountain
              else {"hatch": 1.1, "metal": 1.3, "buried": 1.3, "detail": 1.5, "edge": 1.9, "outline": 3.0})
    ribbons = {"detail", "edge", "outline"} if fountain else set()
    steady = 0.55 if fountain else 1.0     # a more careful hand

    frame, bottle_mesh, bottle_xf, feet = load_parts(export_parts(args.work, args.openscad), ports,
                                                         args.layout, args.screws, args.bed_width,
                                                         tuple(int(n) for n in args.wall_size.split("x")))
    boards = np.vstack([p.V for p in frame if p.kind == "board"])
    story = args.story and args.layout == "bed"
    stages = [furnish(boards.min(0), boards.max(0), st, rng) for st in ((1, 2, 3) if story else (1,))]
    tarp = None
    if args.tent and args.layout == "wall":
        solids, lines, tarp = tent(boards.min(0), boards.max(0), feet[0][2], rng, cozy=args.cozy)
        stages = [(solids, lines)]
    allV = np.vstack([p.V for p in frame + stages[-1][0]] + ([tarp.V] if tarp else []))
    if args.layout == "wall":     # the sand the wall stands on and its stakes go into
        lo, hi, z = allV.min(0) - 900, allV.max(0) + 900, feet[0][2] - 2
        sand = trimesh.Trimesh([[lo[0], lo[1], z], [hi[0], lo[1], z], [hi[0], hi[1], z], [lo[0], hi[1], z]],
                               [[0, 1, 2], [0, 2, 3]])
        frame.append(Part("ground", sand))
    cam = Camera(args.az, args.el, args.dist, (allV.min(0) + allV.max(0)) / 2)
    W, H = cam.fit(allV, args.size, (150 if story else 70) * k)
    pen = Pen(rng, k)

    def draw_panel(parts, extra_detail, cam, W, H, bottle_xf, feet, color=False):
        r, u, f = cam.R
        light = -0.5 * r + 0.7 * u - 0.5 * f
        light /= np.linalg.norm(light)
        ground = [p for p in parts if p.kind == "ground"]
        parts = [p for p in parts if p.kind != "ground"]
        zbuf, idbuf = rasterize(parts, cam, W, H)
        above = Scene(cam, zbuf).near
        if tarp:        # a pale wash wherever the tarpaulin is the nearest thing, or veils what is behind
            tz, _ = rasterize([tarp], cam, W, H)
            layers_wash = [("#8db4e6", mask_path((np.isfinite(tz) & (tz <= zbuf + 1))[::3, ::3], 3))]
        if ground:
            zbuf, idbuf = rasterize(ground, cam, W, H, zbuf.copy(), idbuf, len(parts))
            idbuf[idbuf >= len(parts)] = -1
        scene = Scene(cam, zbuf)
        scene.open = above
        layers = defaultdict(list)
        if tarp:        # then the warm things inside, and the lantern's glow
            painted = np.array([p.paint for p in parts] + [None], dtype=object)[idbuf[::3, ::3]]
            layers["wash"] = layers_wash + [(WASHES[name], mask_path(painted == name, 3))
                                            for name in ("rug", "mattress", "pillow", "blanket", "glow")]
            if tarp.glow is not None:
                (gx, gy), = cam.project(tarp.glow[None])[0]
                rad = 900 * cam.scale / (np.linalg.norm(cam.eye - tarp.glow))
                layers["glow"] = [(gx, gy, rad)]

        def ink(layer, polylines, wobble=1.0, overshoot=0.0, outline_layer=None):
            for P in polylines:
                if layer == "buried":
                    layers[layer] += [pen.stroke(pts, wobble * steady) for pts, _ in scene.visible(P, True)]
                    continue
                for pts, is_outline in scene.visible(P):
                    target = outline_layer if (is_outline and outline_layer) else layer
                    layers[target].append(pen.stroke(pts, wobble * steady, overshoot * steady,
                                                     widths[target] if target in ribbons else None))
                    L = np.linalg.norm(np.diff(pts, axis=0), axis=1).sum()
                    if (not fountain and target == "outline" and len(pts) == 2 and L > 140 * k
                            and rng.random() < 0.3):
                        a, b = rng.uniform(0, 0.3), rng.uniform(0.7, 1.0)   # a second pass of the pen
                        d = pts[1] - pts[0]
                        side = np.array([-d[1], d[0]]) / L * rng.uniform(-1.4, 1.4) * k
                        layers["edge"].append(pen.stroke(np.array([pts[0] + a * d, pts[0] + b * d]) + side, 1.3))

        ink("detail", extra_detail)
        for part in parts:
            over = 5.0 if part.kind in ("board", "masonry") else 0.0
            ink("edge", crease_lines(part, cam.eye), overshoot=over, outline_layer="outline")
            if part.kind not in ("board", "masonry"):
                ink("edge", silhouette_lines(part, cam.eye), outline_layer="outline")
            if part.buried and ground:
                ink("buried", crease_lines(part, cam.eye) + silhouette_lines(part, cam.eye))
            if part.kind == "metal":
                continue
            for fi in part.groups(np.radians(1)):
                n = part.N[fi[0]]
                min_area = 150 if part.kind == "board" else 3000   # on a bottle: the base only
                if part.area[fi].sum() < min_area or n @ (cam.eye - part.cen[fi[0]]) <= 0:
                    continue
                shade = n @ light
                if shade > (0.15 if fountain else 0.6):   # fountain: shadow faces only
                    continue
                tri = part.V[part.F[fi]]
                light_gap, dark_gap = (6.5, 3.0) if fountain else (5.2, 2.7)
                if part.kind == "soft":
                    light_gap, dark_gap = 2.2 * light_gap, 2.2 * dark_gap
                if part.kind == "masonry":
                    light_gap, dark_gap = 14 * light_gap, 14 * dark_gap
                lines = hatch_region(tri, n, light_gap if shade > 0.15 else dark_gap, np.pi / 4, rng)
                if shade < -0.6 and part.kind not in ("soft", "masonry"):
                    lines += hatch_region(tri, n, 3.4, -np.pi / 4, rng)
                ink("hatch", lines, wobble=0.6)

        for M in bottle_xf:
            detail, shade = bottle_extras(bottle_mesh, M[:3, :3].T @ light, rng)
            place = lambda P: P @ M[:3, :3].T + M[:3, 3]
            ink("detail", [place(P) for P in detail], overshoot=3.0)
            ink("hatch", [place(P) for P in shade], wobble=0.8)

        if ground:      # stippled sand where each stake goes in
            for foot in feet:
                for _ in range(46):
                    a, rad = rng.uniform(0, 6.28), 48 + abs(rng.normal(0, 70))
                    c = foot + [rad * np.cos(a), rad * np.sin(a), 0]
                    ink("hatch", [np.array([c, c + [rng.uniform(2, 5), rng.uniform(-1, 1), 0]])])

        # the ground: a patch of shadow thrown away from the light under each foot
        away = -light[:2] / np.linalg.norm(light[:2])
        side = np.array([-away[1], away[0]])
        for foot in feet:
            lines = []
            for t in np.arange(-44, 45, 4.0):
                half = 105 * np.sqrt(1 - (t / 46) ** 2) * rng.uniform(0.85, 1.1)
                c = foot[:2] + away * 75 + side * t
                ends = [c - away * half, c + away * half * rng.uniform(0.9, 1.15)]
                lines.append(np.array([[*e, foot[2]] for e in ends]))
            ink("hatch", lines, wobble=0.8)

        is_metal = np.array([p.kind == "metal" for p in parts] + [False])
        layers["metal"] = [pen.stroke(p, 0.3) for p in metal_hatch(is_metal[idbuf], max(2, round(3 * k)))]
        if color:
            q = 3
            ids = idbuf[::q, ::q]
            paint = np.array([p.paint for p in parts] + [None], dtype=object)[ids]
            # the bed's shadow on the ground, wherever nothing stands in front of it
            lo, hi = boards.min(0), boards.max(0)
            away = -light[:2] / np.linalg.norm(light[:2]) * 130
            quad = [[x + away[0], y + away[1], feet[0][2]] for x, y in
                    ((lo[0], lo[1]), (hi[0], lo[1]), (hi[0], hi[1]), (lo[0], hi[1]))]
            sq, _ = cam.project(np.array(quad))
            yy, xx = np.mgrid[0:ids.shape[0], 0:ids.shape[1]] * q + q / 2
            turn = [(b[0] - a[0]) * (yy - a[1]) - (b[1] - a[1]) * (xx - a[0])
                    for a, b in zip(sq, np.roll(sq, -1, axis=0))]
            ground = (ids < 0) & (np.all([t > 0 for t in turn], 0) | np.all([t < 0 for t in turn], 0))
            layers["wash"] = [(WASHES["ground"], mask_path(ground, q))] + [
                (WASHES[name], mask_path(paint == name, q)) for name in WASHES if name != "ground"]
        return layers

    cell = [(0, 0)]
    panels = [draw_panel(frame + extra_parts, extra_detail, cam, W, H, bottle_xf, feet,
                         color=story and i == len(stages) - 1)
              for i, (extra_parts, extra_detail) in enumerate(stages)]
    if story:
        # opening panel: one joiner taking bottles the way a bed corner does
        one, _, one_xf, _ = load_parts(export_parts(args.work, args.openscad), ["+X", "+Y", "-Z"], "single",
                                       args.screws)
        V1 = np.vstack([p.V for p in one])
        cam1 = Camera(-58, 24, 2400, (V1.min(0) + V1.max(0)) / 2)
        W1, H1 = cam1.fit(V1, int(min(W, H) * 0.9), 70 * k)
        panels.insert(0, draw_panel(one, [], cam1, W1, H1, one_xf, []))
        cell = [((W - W1) // 2, (H - H1) // 2), (W, 0), (0, H), (W, H)]
    WW, HH = (2 * W, 2 * H) if story else (W, H)

    what = {"single": f'Ecojoiner with 1.5 L bottles in ports {", ".join(ports)}',
            "cube": "Ecojoiner cube: 8 joiners, 12 bottles",
            "wall": f"Ecojoiner wall: {args.wall_size} squares",
            "bed": "Ecojoiner bed frame" + (": joiner, frame, plywood, made bed" if story else "")}[args.layout]
    svg = ['<?xml version="1.0" encoding="UTF-8"?>',
           f'<svg xmlns="http://www.w3.org/2000/svg" width="{args.width_mm:g}mm" '
           f'height="{args.width_mm * HH / WW:.2f}mm" viewBox="0 0 {WW} {HH}">',
           f'<title>{what}</title>',
           f'<rect id="paper" width="{WW}" height="{HH}" fill="#fff"/>',
           # watercolour: ragged, slightly bled edges and uneven pigment
           f'<defs><filter id="wash" filterUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">'
           f'<feTurbulence type="fractalNoise" baseFrequency="{0.006 / k:.4f}" numOctaves="3" seed="4" result="n"/>'
           f'<feDisplacementMap in="SourceGraphic" in2="n" scale="{34 * k:.0f}" xChannelSelector="R" '
           'yChannelSelector="G" result="d"/>'
           f'<feGaussianBlur in="d" stdDeviation="{4 * k:.1f}" result="b"/>'
           f'<feTurbulence type="fractalNoise" baseFrequency="{0.007 / k:.4f}" numOctaves="2" seed="9"/>'
           '<feColorMatrix type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.9 0.5" result="m"/>'
           '<feComposite in="b" in2="m" operator="in"/></filter></defs>',
           '<g fill="none" stroke="#000" stroke-linecap="round" stroke-linejoin="round">']
    for i, layers in enumerate(panels):
        svg.append(f'<g id="panel{i + 1}" transform="translate({cell[i][0]},{cell[i][1]})">')
        for gx, gy, rad in layers.get("glow", []):
            svg.append('<radialGradient id="glow"><stop offset="0" stop-color="#ffd24d" stop-opacity="0.75"/>'
                       '<stop offset="0.45" stop-color="#ffdf80" stop-opacity="0.35"/>'
                       '<stop offset="1" stop-color="#ffe9a8" stop-opacity="0"/></radialGradient>'
                       f'<circle cx="{gx:.0f}" cy="{gy:.0f}" r="{rad:.0f}" fill="url(#glow)" stroke="none"/>')
        for j, (colour, d) in enumerate(layers.get("wash", [])):
            svg.append(f'<path id="wash{j}" fill="{colour}" fill-opacity="0.62" stroke="none" '
                       f'filter="url(#wash)" d="{d}"/>')
        for name, width in widths.items():
            d = "".join(s for s in layers.get(name, []) if s)
            paint = ('fill="#000" stroke="none"' if name in ribbons
                     else f'stroke-width="{width * k:.2f}"')
            if name == "buried":
                paint += f' stroke-dasharray="{7 * k:.1f} {6 * k:.1f}"'
            svg.append(f'<path id="{name}{i + 1}" {paint} d="{d}"/>')
        svg.append("</g>")
    svg += ["</g>", "</svg>"]
    args.out.write_text("\n".join(svg) + "\n")
    print(f"wrote {args.out}  ({WW} x {HH})")
    if args.png:
        png = args.out.with_suffix(".png").resolve()
        subprocess.run(["inkscape", "--export-type=png", f"--export-filename={png}",
                        f"--export-width={min(WW, 3600)}", str(args.out.resolve())], check=True, capture_output=True)
        print(f"wrote {png}")


if __name__ == "__main__":
    main()
