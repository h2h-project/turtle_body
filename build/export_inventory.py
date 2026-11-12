#!/usr/bin/env python3
"""Write turtle_body_full_inventory_<version>.svg -- every wooden slat in one Turtle, 1:1.

Each wooden part is rendered from lib/ (via its src/components wrapper, or a
direct lib call for the Ecojoiner Johns), laid flat on its thinnest axis
(board thickness -> view axis, longest edge -> horizontal) and projected
top-down with OpenSCAD's projection(). Every physical copy is drawn and
labelled separately -- six Long Johns, not one -- grouped by component.

Units are millimetres and the SVG is sized in mm, so printing it at 100 %
gives true-size outlines. Only holes that pass through the board face show;
holes drilled into an edge (e.g. the sail-connector M3 side pilot) and blind
pockets do not appear in a top-down view. Sails (fabric) are not wood and
are excluded.

Each piece's code appears only in the caption beneath it; the outline itself
is left clean and uninterrupted so labelling artwork can be added later. The
codes live in INVENTORY below -- edit the `code` fields to change them.

Output (<version> = VERSION.json "version", e.g. 6.6.0):
  * turtle_body/turtle_body_full_inventory_<version>.svg. Older
    turtle_body_full_inventory*.svg files in the repo root are removed, so only
    the current version remains, like stls_v1/.
  * the same file copied into the turtle_labels repository root, where label
    artwork is designed against it. Older versions there are left alone. The
    labels checkout is --labels-dir, else $TURTLE_LABELS_DIR, else
    ~/WebstormProjects/turtle_labels, else ../turtle_labels. If none exists,
    a warning is printed and only the turtle_body copy is written.

Usage:
    python3 build/export_inventory.py               # both copies, versioned
    python3 build/export_inventory.py --no-labels   # turtle_body copy only
    python3 build/export_inventory.py --labels-dir /path/to/turtle_labels
    python3 build/export_inventory.py --out x.svg   # explicit path; no pruning
    python3 build/export_inventory.py --keep-temp   # keep the per-part STL/SVG scratch

Standard library only; needs OpenSCAD (found like the other build scripts).
"""

from __future__ import annotations

import argparse
import datetime
import html
import math
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scad_lib import find_openscad, read_version, repo_root, render  # noqa: E402

# --------------------------------------------------------------------------- #
# inventory: what to draw, how many, and what each copy is labelled
# --------------------------------------------------------------------------- #
# source: ("wrapper", "<src/components file>", {defines})
#      or ("lib", "<lib file>", "<module call>")
# pieces_in_render: how many identical bodies that render emits (the first is
# drawn); qty: how many the Turtle needs. code: label prefix; copies get 1..qty.

ECO = "src/components/Turtle_Core_Ecojoiner.scad"
RF = "src/components/Turtle_Rear_Fin.scad"
BA = "src/components/Turtle_Bottom_Ballast_Fin.scad"
HF = "src/components/Turtle_Head_Fin.scad"
SF = "src/components/Turtle_Sail_Apparatus.scad"

INVENTORY = [
    {
        "title": "Ecojoiner",
        "code": "EJ",
        "parts": [
            dict(name="Long John", code="LJ", qty=6, fill="#e8d84a",
                 source=("lib", "lib/ecojoiner.scad", "eco_long_john(colored = false);")),
            dict(name="Little John", code="SJ", qty=5, fill="#5fbf8a",
                 source=("lib", "lib/ecojoiner.scad", "eco_little_john(colored = false);")),
            dict(name="Master John", code="MJ", qty=1, fill="#2f8a5c",
                 note="deeper slots - fitted last",
                 source=("lib", "lib/ecojoiner.scad", "eco_master_john(colored = false);")),
            dict(name="Final Key", code="FK", qty=4, fill="#d1c70d",
                 source=("lib", "lib/ecojoiner.scad", "eco_final_key(colored = false);")),
        ],
    },
    {
        "title": "Rear Fin (back fin + solar support)",
        "code": "RF",
        "parts": [
            dict(name="Rear fin", code="FIN", qty=1, fill="#f2d64b",
                 source=("wrapper", RF, {"part": "fin"})),
            dict(name="Bottle-holder shaft", code="SH", qty=2, fill="#6cc46c",
                 source=("wrapper", RF, {"part": "shaft"})),
            dict(name="Solar crossbar", code="SOL", qty=1, fill="#e06a5a",
                 source=("wrapper", RF, {"part": "solar_holder"})),
        ],
    },
    {
        "title": "Bottom Ballast",
        "code": "BB",
        "parts": [
            dict(name="Core slat", code="CS", qty=2, fill="#6cc46c",
                 source=("wrapper", BA, {"part": "core_slat"})),
            dict(name="Bottom board", code="BB", qty=1, fill="#f0a050",
                 source=("wrapper", BA, {"part": "bottom_board"})),
            dict(name="Lock foot", code="LF", qty=2, fill="#e06a5a",
                 source=("wrapper", BA, {"part": "lock_foot"})),
            dict(name="Ballast fin", code="FIN", qty=1, fill="#f2d64b",
                 source=("wrapper", BA, {"part": "fin"})),
        ],
    },
    {
        "title": "Head Fin (front fin) - EXPERIMENTAL",
        "code": "HF",
        "parts": [
            dict(name="Head fin", code="FIN", qty=1, fill="#6a9be0",
                 source=("wrapper", HF, {"part": "fin"})),
            dict(name="Head slat", code="SL", qty=2, fill="#a77ad6",
                 source=("wrapper", HF, {"part": "slat"})),
        ],
    },
    {
        "title": "Sail Frame",
        "code": "SF",
        "parts": [
            dict(name="Crossbar half", code="CH", qty=2, fill="#a8807e",
                 source=("wrapper", SF, {"part": "top_bar_half"})),
            dict(name="Crossbar connector", code="CC", qty=1, fill="#8a5f5f",
                 note="M3 side pilot not visible from the top",
                 source=("wrapper", SF, {"part": "top_bar_connector"})),
            dict(name="Sail batten", code="SB", qty=2, fill="#d9b98c",
                 source=("wrapper", SF, {"part": "sail_batten"})),
            dict(name="Non-sail batten", code="NB", qty=2, fill="#e6cfa8",
                 source=("wrapper", SF, {"part": "non_sail_batten"})),
            dict(name="Bottom rail", code="BR", qty=2, fill="#a8807e", pieces_in_render=2,
                 source=("wrapper", SF, {"part": "bottom_bars", "show_hardware": False})),
            dict(name="Joint strengthener", code="ST", qty=2, fill="#7fe07a", pieces_in_render=2,
                 source=("wrapper", SF, {"part": "strengtheners", "show_hardware": False})),
            dict(name="C end piece", code="CE", qty=2, fill="#ff9442", pieces_in_render=2,
                 source=("wrapper", SF, {"part": "c_end_pieces", "show_hardware": False})),
        ],
    },
]

# --------------------------------------------------------------------------- #
# layout (all mm)
# --------------------------------------------------------------------------- #
PAGE_W = 1200.0
MARGIN = 25.0
GAP_X = 30.0
GAP_Y = 14.0
CAPTION_H = 22.0         # two caption lines under each piece
GROUP_TITLE_H = 40.0
GROUP_GAP = 30.0
FONT = "'Barlow Condensed', 'Oswald', 'Arial Narrow', Arial, sans-serif"


# --------------------------------------------------------------------------- #
# STL helpers
# --------------------------------------------------------------------------- #

def read_stl_tris(path: Path) -> list[tuple]:
    data = path.read_bytes()
    tris = []
    if len(data) >= 84:
        (n,) = struct.unpack("<I", data[80:84])
        if len(data) == 84 + 50 * n:
            for i in range(n):
                v = struct.unpack("<9f", data[84 + 50 * i + 12: 84 + 50 * i + 48])
                tris.append((v[0:3], v[3:6], v[6:9]))
            return tris
    pts = [tuple(map(float, l.split()[1:4]))
           for l in data.decode("utf-8", "replace").splitlines()
           if l.strip().startswith("vertex")]
    return [tuple(pts[i:i + 3]) for i in range(0, len(pts) - 2, 3)]


def write_stl_tris(path: Path, tris) -> None:
    with open(path, "wb") as fh:
        fh.write(b"\0" * 80 + struct.pack("<I", len(tris)))
        for t in tris:
            fh.write(struct.pack("<12fH", 0, 0, 0, *t[0], *t[1], *t[2], 0))


def components(tris) -> list[list]:
    """Split triangles into connected bodies (shared vertices)."""
    parent = list(range(len(tris)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    owner = {}
    for i, t in enumerate(tris):
        for v in t:
            key = tuple(round(c, 3) for c in v)
            j = owner.setdefault(key, i)
            ri, rj = find(i), find(j)
            if ri != rj:
                parent[ri] = rj
    groups = {}
    for i, t in enumerate(tris):
        groups.setdefault(find(i), []).append(t)
    out = list(groups.values())
    # stable order: by min corner, so "the first piece" is deterministic
    out.sort(key=lambda g: tuple(round(min(v[a] for t in g for v in t), 1) for a in range(3)))
    return out


def bbox(tris):
    lo = [min(v[a] for t in tris for v in t) for a in range(3)]
    hi = [max(v[a] for t in tris for v in t) for a in range(3)]
    return lo, hi


def flat_matrix(lo, hi):
    """Rows of a rotation (det +1) taking long->X, mid->Y, thin->Z, plus the
    sorted extents."""
    ext = [hi[a] - lo[a] for a in range(3)]
    order = sorted(range(3), key=lambda a: -ext[a])     # long, mid, thin
    e = [[1.0 if c == order[r] else 0.0 for c in range(3)] for r in range(3)]
    # make it a proper rotation: thin = long x mid
    cx = [e[0][1] * e[1][2] - e[0][2] * e[1][1],
          e[0][2] * e[1][0] - e[0][0] * e[1][2],
          e[0][0] * e[1][1] - e[0][1] * e[1][0]]
    e[2] = cx
    return e, [ext[a] for a in order]


# --------------------------------------------------------------------------- #
# OpenSCAD SVG projection -> polygon list
# --------------------------------------------------------------------------- #

_TOK = re.compile(r"[MLZmlz]|-?\d*\.?\d+(?:[eE][-+]?\d+)?")


def parse_openscad_svg(text: str) -> list[list[tuple[float, float]]]:
    polys = []
    for d in re.findall(r'<path[^>]*\sd="([^"]*)"', text):
        toks = _TOK.findall(d)
        cur, nums = None, []
        for tk in toks:
            if tk in "MLZmlz":
                if tk in "Mm":
                    if cur:
                        polys.append(cur)
                    cur = []
                elif tk in "Zz":
                    if cur:
                        polys.append(cur)
                    cur = None
                continue
            nums.append(float(tk))
            if len(nums) == 2:
                if cur is None:
                    cur = []
                cur.append((nums[0], nums[1]))
                nums = []
        if cur:
            polys.append(cur)
    return [p for p in polys if len(p) >= 3]


def project_piece(osc: str, stl: Path, work: Path) -> tuple[list, list[float]]:
    tris = read_stl_tris(stl)
    lo, hi = bbox(tris)
    rows, ext = flat_matrix(lo, hi)
    mm = [[rows[r][0], rows[r][1], rows[r][2], 0] for r in range(3)] + [[0, 0, 0, 1]]
    c = [-(lo[a] + hi[a]) / 2 for a in range(3)]
    scad = work / (stl.stem + "_proj.scad")
    scad.write_text(
        f"projection() multmatrix({mm}) translate({c}) import(\"{stl.as_posix()}\");\n",
        encoding="utf-8")
    svg = work / (stl.stem + "_proj.svg")
    proc = subprocess.run([osc, "-o", str(svg), str(scad)],
                          capture_output=True, text=True, timeout=600)
    if proc.returncode != 0 or not svg.exists():
        raise RuntimeError(f"projection failed for {stl.name}:\n{proc.stderr[-2000:]}")
    polys = parse_openscad_svg(svg.read_text(encoding="utf-8"))
    if not polys:
        raise RuntimeError(f"empty projection for {stl.name}")
    xs = [x for p in polys for x, _ in p]
    ys = [y for p in polys for _, y in p]
    x0, y0 = min(xs), min(ys)
    polys = [[(x - x0, y - y0) for x, y in p] for p in polys]
    return polys, ext


# --------------------------------------------------------------------------- #
# rendering each part
# --------------------------------------------------------------------------- #

def render_part(osc: str, part: dict, work: Path, idx: str) -> Path:
    root = repo_root()
    kind = part["source"][0]
    if kind == "wrapper":
        _, rel, defines = part["source"]
        res = render(root / rel, defines=defines, out_dir=str(work), openscad=osc, timeout=1200)
    else:
        _, rel, call = part["source"]
        drv = work / f"drv_{idx}.scad"
        drv.write_text(f'use <{(root / rel).as_posix()}>\n{call}\n', encoding="utf-8")
        res = render(drv, out_dir=str(work), openscad=osc, timeout=1200)
    if not res.ok:
        raise RuntimeError(f"render failed for {part['name']}:\n{res.console[-2000:]}")
    tris = read_stl_tris(Path(res.stl_path))
    bodies = components(tris)
    want = part.get("pieces_in_render", 1)
    if want == 1:
        body = [t for b in bodies for t in b]
    else:
        if len(bodies) != want:
            raise RuntimeError(f"{part['name']}: expected {want} bodies, got {len(bodies)}")
        body = bodies[0]
    out = work / f"piece_{idx}.stl"
    write_stl_tris(out, body)
    return out


# --------------------------------------------------------------------------- #
# SVG writing
# --------------------------------------------------------------------------- #

def fmt(v: float) -> str:
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return s if s != "-0" else "0"


def dim(v: float) -> str:
    return fmt(round(v, 1))


def path_d(polys, ox, oy) -> str:
    return " ".join(
        "M " + " L ".join(f"{fmt(x + ox)},{fmt(y + oy)}" for x, y in p) + " Z"
        for p in polys)


def esc(s: str) -> str:
    return html.escape(s, quote=True)


def build_svg(groups_out, version: str) -> str:
    body = []
    y = MARGIN
    total = sum(len(g["pieces"]) for g in groups_out)

    # header
    body.append(f'<text x="{MARGIN}" y="{fmt(y + 22)}" font-size="26" font-weight="700">'
                f'Hope Turtle - Turtle Body full wooden slat inventory</text>')
    body.append(f'<text x="{MARGIN}" y="{fmt(y + 40)}" font-size="11">'
                f'Turtle Body v{esc(version)} - generated {datetime.date.today().isoformat()} by '
                f'build/export_inventory.py from lib/ - {total} pieces - top-down views at 1:1 '
                f'(print at 100 %, units mm). Caption: label - part - length x width x thickness.</text>')
    body.append(f'<text x="{MARGIN}" y="{fmt(y + 54)}" font-size="9" fill="#555">'
                f'Only through-face holes are shown; edge-drilled holes and blind pockets are not visible '
                f'from the top. Sails (fabric) are excluded. Head fin is experimental (not built or tested).</text>')
    # 100 mm scale bar
    sx, sy = PAGE_W - MARGIN - 100, y + 30
    body.append(f'<g stroke="#000" stroke-width="0.6" fill="none">'
                f'<path d="M {fmt(sx)},{fmt(sy)} H {fmt(sx + 100)} '
                f'M {fmt(sx)},{fmt(sy - 4)} V {fmt(sy + 4)} '
                f'M {fmt(sx + 50)},{fmt(sy - 2)} V {fmt(sy + 2)} '
                f'M {fmt(sx + 100)},{fmt(sy - 4)} V {fmt(sy + 4)}"/></g>')
    body.append(f'<text x="{fmt(sx + 50)}" y="{fmt(sy - 7)}" font-size="9" text-anchor="middle">'
                f'100 mm check</text>')
    y += 70

    for g in groups_out:
        n = len(g["pieces"])
        body.append(f'<g id="group-{esc(g["code"])}">')
        body.append(f'<line x1="{MARGIN}" y1="{fmt(y)}" x2="{fmt(PAGE_W - MARGIN)}" y2="{fmt(y)}" '
                    f'stroke="#000" stroke-width="0.8"/>')
        body.append(f'<text x="{MARGIN}" y="{fmt(y + 24)}" font-size="22" font-weight="700">'
                    f'{esc(g["code"])} - {esc(g["title"])}</text>')
        body.append(f'<text x="{fmt(PAGE_W - MARGIN)}" y="{fmt(y + 24)}" font-size="12" '
                    f'text-anchor="end">{n} pieces</text>')
        y += GROUP_TITLE_H

        # shelf-pack the pieces in order
        x, row_h = MARGIN, 0.0
        for pc in g["pieces"]:
            w, h = pc["w"], pc["h"]
            cell_w = max(w, 60.0)
            if x > MARGIN and x + cell_w > PAGE_W - MARGIN:
                x, y = MARGIN, y + row_h + GAP_Y
                row_h = 0.0
            ox, oy = x, y
            label = pc["label"]
            body.append(f'<g id="{esc(label)}">')
            body.append(f'<path d="{path_d(pc["polys"], ox, oy)}" fill="{pc["fill"]}" '
                        f'fill-opacity="0.55" fill-rule="evenodd" stroke="#000" stroke-width="0.4"/>')
            body.append(f'<text x="{fmt(ox)}" y="{fmt(oy + h + 9)}" font-size="8">'
                        f'<tspan font-weight="700">{esc(label)}</tspan> {esc(pc["name"])}</text>')
            cap2 = f'{dim(pc["ext"][0])} x {dim(pc["ext"][1])} x {dim(pc["ext"][2])}'
            if pc.get("note"):
                cap2 += f' - {pc["note"]}'
            body.append(f'<text x="{fmt(ox)}" y="{fmt(oy + h + 18)}" font-size="7" fill="#444">'
                        f'{esc(cap2)}</text>')
            body.append('</g>')
            x += cell_w + GAP_X
            row_h = max(row_h, h + CAPTION_H)
        y += row_h + GROUP_GAP
        body.append('</g>')

    page_h = y + MARGIN
    head = (f'<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<!-- GENERATED by build/export_inventory.py - do not hand-edit. '
            f'Turtle Body v{esc(version)}. License: CERN-OHL-S-2.0. -->\n'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{fmt(PAGE_W)}mm" '
            f'height="{fmt(page_h)}mm" viewBox="0 0 {fmt(PAGE_W)} {fmt(page_h)}" '
            f'font-family="{esc(FONT)}">\n'
            f'<title>Hope Turtle - Turtle Body full wooden slat inventory v{esc(version)}</title>\n'
            f'<rect width="100%" height="100%" fill="#fff"/>\n')
    return head + "\n".join(body) + "\n</svg>\n"


# --------------------------------------------------------------------------- #
# output locations
# --------------------------------------------------------------------------- #

INVENTORY_STEM = "turtle_body_full_inventory"


def inventory_name(version: str) -> str:
    return f"{INVENTORY_STEM}_{version}.svg"


def find_labels_dir(cli_value: str | None) -> Path | None:
    """The turtle_labels checkout: --labels-dir, $TURTLE_LABELS_DIR, then the
    maintainer's ~/WebstormProjects/turtle_labels, then a ../turtle_labels sibling."""
    root = repo_root()
    candidates = [cli_value, os.environ.get("TURTLE_LABELS_DIR"),
                  Path.home() / "WebstormProjects" / "turtle_labels",
                  root.parent / "turtle_labels"]
    for c in candidates:
        if not c:
            continue
        path = Path(c).expanduser().resolve()
        if (path / ".git").exists() or (path / "master").is_dir():
            return path
        if c in (cli_value, os.environ.get("TURTLE_LABELS_DIR")):
            raise SystemExit(f"export_inventory: {path} is not a turtle_labels checkout")
    return None


def prune_old(directory: Path, keep: Path) -> list[Path]:
    removed = []
    for old in sorted(directory.glob(f"{INVENTORY_STEM}*.svg")):
        if old.resolve() != keep.resolve():
            old.unlink()
            removed.append(old)
    return removed


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=None,
                    help="explicit output path (default: turtle_body_full_inventory_<version>.svg "
                         "in the repo root, replacing older versions there)")
    ap.add_argument("--labels-dir", default=None, help="turtle_labels checkout to copy into")
    ap.add_argument("--no-labels", action="store_true", help="do not copy into turtle_labels")
    ap.add_argument("--keep-temp", action="store_true")
    args = ap.parse_args(argv)

    root = repo_root()
    osc = find_openscad()
    version = read_version()
    work = Path(tempfile.mkdtemp(prefix="turtle_inventory_"))
    groups_out = []
    try:
        for gi, g in enumerate(INVENTORY):
            pieces = []
            for pi, part in enumerate(g["parts"]):
                idx = f"{gi}_{pi}"
                stl = render_part(osc, part, work, idx)
                polys, ext = project_piece(osc, stl, work)
                xs = [x for p in polys for x, _ in p]
                ys = [y for p in polys for _, y in p]
                w, h = max(xs), max(ys)
                print(f"{g['code']}-{part['code']:<4} x{part['qty']}  {part['name']:<22} "
                      f"{dim(ext[0])} x {dim(ext[1])} x {dim(ext[2])}")
                for k in range(1, part["qty"] + 1):
                    suffix = str(k) if part["qty"] > 1 else ""
                    pieces.append(dict(label=f"{g['code']}-{part['code']}{suffix}",
                                       name=part["name"], polys=polys, ext=ext, w=w, h=h,
                                       fill=part["fill"], note=part.get("note")))
            groups_out.append(dict(title=g["title"], code=g["code"], pieces=pieces))
        svg_text = build_svg(groups_out, version)
        n_pieces = sum(len(g["pieces"]) for g in groups_out)
        if args.out:
            out = Path(args.out) if Path(args.out).is_absolute() else root / args.out
        else:
            out = root / inventory_name(version)
        out.write_text(svg_text, encoding="utf-8")
        print(f"\nwrote {out}  ({n_pieces} pieces)")
        if not args.out:
            for old in prune_old(root, out):
                print(f"removed superseded {old.name}")
        if not args.no_labels:
            labels = find_labels_dir(args.labels_dir)
            if labels is None:
                print("WARNING: turtle_labels checkout not found (set TURTLE_LABELS_DIR or "
                      "--labels-dir); labels copy NOT written", file=sys.stderr)
            else:
                dest = labels / inventory_name(version)
                dest.write_text(svg_text, encoding="utf-8")
                print(f"wrote {dest}")
    finally:
        if args.keep_temp:
            print(f"scratch kept in {work}")
        else:
            shutil.rmtree(work, ignore_errors=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
