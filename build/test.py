#!/usr/bin/env python3
"""Render every manifest target and check it against the recorded baseline.

A render fails if any of these hold:
  * OpenSCAD exits nonzero or times out
  * the mesh is empty
  * an ERROR / failed-assert line appears in the console
  * a WARNING appears that is not in the baseline for that render
  * the bounding box moved by more than the tolerance (global, or the
    per-render 'tolerance_mm' override in tests/expected_bounds.json)

Renders src/ where it exists, else the committed 'out' bundle.

Usage:
    build/test.py                 # all targets
    build/test.py <id> ...        # only the named targets
    build/test.py --out           # force the committed bundles, not src/
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scad_lib import (  # noqa: E402
    load_manifest, repo_root, find_openscad, render, stl_bounds,
    parse_console, bounds_delta,
)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("ids", nargs="*")
    ap.add_argument("--out", action="store_true", help="render committed bundles, not src/")
    args = ap.parse_args(argv)

    root = repo_root()
    exp_path = root / "tests" / "expected_bounds.json"
    if not exp_path.exists():
        print("no tests/expected_bounds.json -- run: python3 build/baseline.py", file=sys.stderr)
        return 2
    expected = json.loads(exp_path.read_text(encoding="utf-8"))
    global_tol = float(expected.get("_tolerance_mm", 0.05))
    exp_renders = expected.get("renders", {})

    osc = find_openscad()
    scratch = root / "tests" / "_scratch"
    scratch.mkdir(parents=True, exist_ok=True)

    targets = load_manifest()["targets"]
    if args.ids:
        targets = [t for t in targets if t["id"] in set(args.ids)]

    rows, failed = [], 0
    for t in targets:
        src = root / t["src"]
        scad = (root / t["out"]) if (args.out or not src.exists()) else src
        for r in t["renders"]:
            key = f"{t['id']}__{r['name']}"
            exp = exp_renders.get(key)
            tol = float(exp.get("tolerance_mm", global_tol)) if isinstance(exp, dict) else global_tol
            base_warnings = set(exp.get("warnings", [])) if isinstance(exp, dict) else set()

            t0 = time.time()
            res = render(scad, defines=r.get("defines"), out_dir=str(scratch),
                         binary_stl=True, timeout=900, openscad=osc)
            dt = time.time() - t0
            cons = parse_console(res.console)
            bounds = stl_bounds(res.stl_path) if res.ok else None

            problems = []
            if res.timed_out:
                problems.append("TIMEOUT")
            elif res.returncode != 0:
                problems.append(f"exit {res.returncode}")
            if cons["errors"]:
                problems.append(f"{len(cons['errors'])} error line(s): {cons['errors'][0][:80]}")
            new_warn = [w for w in cons["warnings"] if w not in base_warnings]
            if new_warn:
                problems.append(f"new warning: {new_warn[0][:80]}")
            if bounds is None:
                problems.append("empty mesh")
            elif exp is None or exp.get("bounds") is None:
                problems.append("no baseline (run baseline.py)")
            else:
                d = bounds_delta(bounds, exp["bounds"])
                if d > tol:
                    problems.append(f"bounds moved {d:.3f}mm > {tol}mm "
                                    f"(now min={bounds['min']} max={bounds['max']}; "
                                    f"was min={exp['bounds']['min']} max={exp['bounds']['max']})")

            ok = not problems
            failed += 0 if ok else 1
            rows.append((key, ok, dt, problems))
            mark = "ok  " if ok else "FAIL"
            print(f"{mark} {key:<34} {dt:6.1f}s" + ("" if ok else "  " + "; ".join(problems)))

    total = len(rows)
    print(f"\n{total - failed}/{total} renders passed"
          + (f", {failed} FAILED" if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
