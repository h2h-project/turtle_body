#!/usr/bin/env python3
"""Black-and-white icon: one square of four Ecojoiners and four bottles, in perspective.

Deliberately not the real geometry. Each joiner is reduced to a solid black six-armed
"jack" with white edge lines, each bottle to a white cylinder with a black outline; only
the spacing (joiner reach, bottle diameter, centre distance) follows the model.

    .venv/bin/python docs/sketches/ecojoiner_icon.py --out icon.svg --png
"""
import argparse
import subprocess
from pathlib import Path

import manifold3d as m3
import numpy as np
import trimesh

from ecojoiner_sketch import Camera, Part, Scene, rasterize

REACH, ARM, BOTTLE_R = 148.0, 96.0, 42.0   # mm, from the Ecojoiner model
PITCH = 500.0                             # stretched from 418 so the bottles read at icon size


def jack(centre):
    solid = None
    for axis in range(3):
        size = [ARM] * 3
        size[axis] = 2 * REACH
        bar = m3.Manifold.cube(size, True)
        solid = bar if solid is None else solid + bar
    mesh = solid.to_mesh()
    out = trimesh.Trimesh(np.asarray(mesh.vert_properties)[:, :3], np.asarray(mesh.tri_verts))
    out.apply_translation(centre)
    return out


def bottle(a, b):
    a, b = np.asarray(a, float), np.asarray(b, float)
    out = trimesh.creation.cylinder(radius=BOTTLE_R, height=np.linalg.norm(b - a), sections=64)
    out.apply_transform(trimesh.geometry.align_vectors([0, 0, 1], (b - a) / np.linalg.norm(b - a)))
    out.apply_translation((a + b) / 2)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--shape", choices=["square", "cube"], default="square")
    ap.add_argument("--az", type=float, default=-58)
    ap.add_argument("--el", type=float, default=20)
    ap.add_argument("--dist", type=float, default=1500, help="camera distance, mm: nearer = more perspective")
    ap.add_argument("--size", type=int, default=1000, help="canvas, px")
    ap.add_argument("--mm", type=float, default=40, help="physical size of the SVG")
    ap.add_argument("--line", type=float, default=13, help="bottle outline width, px")
    ap.add_argument("--solid", action="store_true", help="black joiners with white edges, white bottles")
    ap.add_argument("--out", type=Path)
    ap.add_argument("--png", action="store_true")
    args = ap.parse_args()
    args.out = args.out or Path(__file__).with_name(f"ecojoiner_{args.shape}_icon.svg")

    # the square stands upright in the plane y = 0; the cube adds a second one behind it
    depth = (0, 1) if args.shape == "cube" else (0,)
    grid = [(i, j, k) for i in (0, 1) for j in depth for k in (0, 1)]
    parts = [("jack", jack(np.array(g) * PITCH)) for g in grid]
    for g in grid:
        for axis in range(3):
            h = tuple(g[i] + (i == axis) for i in range(3))
            if h in grid:
                d = np.eye(3)[axis]
                parts.append(("bottle", bottle(np.array(g) * PITCH + d * (REACH - 6),
                                               np.array(h) * PITCH - d * (REACH - 6))))

    allV = np.vstack([m.vertices for _, m in parts])
    cam = Camera(args.az, args.el, args.dist, (allV.min(0) + allV.max(0)) / 2)
    W, H = cam.fit(allV, args.size, 0.07 * args.size)
    w = args.line

    def path(polys, close=True):
        return "".join("M" + "L".join("%.1f,%.1f" % tuple(p) for p in poly) + ("Z" if close else "")
                       for poly in polys)

    svg = ['<?xml version="1.0" encoding="UTF-8"?>',
           f'<svg xmlns="http://www.w3.org/2000/svg" width="{args.mm * W / max(W, H):.2f}mm" '
           f'height="{args.mm * H / max(W, H):.2f}mm" viewBox="0 0 {W} {H}">',
           f'<title>Ecojoiner {args.shape} icon</title>',
           '<g stroke-linejoin="round" stroke-linecap="round">']
    solids = [Part("board" if kind == "jack" else "bottle", mesh) for kind, mesh in parts]
    scene = Scene(cam, rasterize(solids, cam, W, H)[0])     # for hiding lines behind things
    lines = {}

    def draw(colour, width, polyline):
        lines.setdefault((colour, width), []).extend(pts for pts, _ in scene.visible(polyline))

    # fills in painter's order, far to near; every part first lays down a halo that separates it
    for kind, mesh in sorted(parts, key=lambda p: -np.linalg.norm(p[1].centroid - cam.eye)):
        S, _ = cam.project(mesh.vertices)
        front = np.einsum("ij,ij->i", mesh.face_normals, cam.eye - mesh.triangles_center) > 0
        tris = path(S[mesh.faces[front]])
        dark = (kind == "jack") == args.solid          # which of the two is the black one
        ink = "#fff" if dark else "#000"
        if dark:
            svg.append(f'<path d="{tris}" fill="#fff" stroke="#fff" stroke-width="{0.9 * w:.1f}"/>')
            svg.append(f'<path d="{tris}" fill="#000" stroke="#000" stroke-width="1.5"/>')
        else:
            svg.append(f'<path d="{tris}" fill="#000" stroke="#000" stroke-width="{2 * w:.1f}"/>')
            svg.append(f'<path d="{tris}" fill="#fff" stroke="#fff" stroke-width="1.5"/>')
        a, b = mesh.face_adjacency.T
        sharp = (mesh.face_adjacency_angles > np.radians(40)) & front[a] & front[b]
        for edge in mesh.vertices[mesh.face_adjacency_edges[sharp]]:
            draw(ink, 0.32 * w if dark else 0.6 * w, edge)
        if kind == "bottle":                           # a label band: two rings
            lo, hi = mesh.bounds
            axis = np.eye(3)[np.argmax(hi - lo)]
            u, v = np.eye(3)[[i for i in range(3) if axis[i] == 0]]
            t = np.linspace(0, 2 * np.pi, 97)
            for f in (-0.2, 0.2):
                draw(ink, 0.45 * w, mesh.centroid + axis * f * (hi - lo).max()
                     + (BOTTLE_R + 0.6) * (np.outer(np.cos(t), u) + np.outer(np.sin(t), v)))
    for (colour, width), polylines in lines.items():
        svg.append(f'<path d="{path(polylines, False)}" fill="none" stroke="{colour}" stroke-width="{width:.1f}"/>')
    svg += ["</g>", "</svg>"]
    args.out.write_text("\n".join(svg) + "\n")
    print(f"wrote {args.out}  ({W} x {H})")
    if args.png:
        png = args.out.with_suffix(".png").resolve()
        subprocess.run(["inkscape", "--export-type=png", "--export-background=#ffffff",
                        f"--export-filename={png}", f"--export-width={W}", str(args.out.resolve())],
                       check=True, capture_output=True)
        print(f"wrote {png}")


if __name__ == "__main__":
    main()
