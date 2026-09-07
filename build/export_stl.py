#!/usr/bin/env python3
"""Export fabrication STLs, version-stamped, into v1.0 STLs/.

By default only the parts historically exported as PLA prints are written
(control cap, control cage, hex shaft, silicone-ring mold -- the renders
flagged `export_stl` in build/manifest.json). Name any target id or
`id:render` to force others; `--all` writes every render in the manifest.

Output name:  <stl-name>_v<VERSION.json version>.stl
Renders src/ where it exists, else the committed 'out' bundle.

Usage:
    build/export_stl.py                     # the default PLA set
    build/export_stl.py ballast_fin:fin     # one extra part
    build/export_stl.py --all
    build/export_stl.py --ascii --dry-run
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scad_lib import (  # noqa: E402
    load_manifest, repo_root, read_version, find_openscad, render, stl_bounds,
)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("selectors", nargs="*", help="target id, or id:render, to force")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--ascii", action="store_true", help="ASCII STL (default: binary)")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--out-dir", default="v1.0 STLs")
    args = ap.parse_args(argv)

    root = repo_root()
    version = read_version()
    out_dir = root / args.out_dir
    forced_ids = {s.split(":")[0] for s in args.selectors}
    forced_pairs = {tuple(s.split(":", 1)) for s in args.selectors if ":" in s}

    jobs = []
    for t in load_manifest()["targets"]:
        for r in t["renders"]:
            pick = (
                args.all
                or r.get("export_stl")
                or t["id"] in forced_ids
                or (t["id"], r["name"]) in forced_pairs
            )
            if not pick:
                continue
            stl_name = r.get("stl") or f"{t['id']}_{r['name']}"
            src = root / t["src"]
            scad = src if src.exists() else root / t["out"]
            jobs.append((t["id"], r, scad, stl_name))

    if not jobs:
        print("nothing selected")
        return 1

    osc = find_openscad()
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"version {version}  ->  {out_dir}/\n")
    rc = 0
    for tid, r, scad, stl_name in jobs:
        dest = out_dir / f"{stl_name}_v{version}.stl"
        if args.dry_run:
            print(f"would write {dest.name:<40} from {scad.relative_to(root)} "
                  f"{r.get('defines') or ''}")
            continue
        t0 = time.time()
        res = render(scad, defines=r.get("defines"), out_dir=str(out_dir),
                     binary_stl=not args.ascii, timeout=1800, openscad=osc)
        dt = time.time() - t0
        if not res.ok:
            print(f"FAIL {dest.name}  (rc={res.returncode} timeout={res.timed_out})")
            rc = 1
            continue
        Path(res.stl_path).replace(dest)
        b = stl_bounds(dest)
        size = b["size"] if b else "EMPTY"
        print(f"wrote {dest.name:<40} {dt:6.1f}s  size={size}")
        if not b:
            rc = 1

    return rc


if __name__ == "__main__":
    raise SystemExit(main())
