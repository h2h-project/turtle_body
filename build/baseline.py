#!/usr/bin/env python3
"""Render every manifest target and record a regression baseline.

Writes one JSON per render under tests/baseline/ (bounding box, triangle
count, ECHO lines, warnings) and refreshes tests/expected_bounds.json, which
build/test.py checks against.

Run this once at M0 against the committed originals, and again after any
milestone whose geometry changes are intentional -- reviewing the diff of
tests/expected_bounds.json is how those changes get signed off.

Usage:
    build/baseline.py                 # render all targets, refresh expected bounds
    build/baseline.py <id> ...        # only the named targets
    build/baseline.py --from-src      # render src/ where it exists (default: 'out' bundle)
    build/baseline.py --tolerance 0.05
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scad_lib import (  # noqa: E402
    load_manifest, repo_root, find_openscad, openscad_version,
    render, stl_bounds, parse_console,
)

DEFAULT_TOL = 0.05  # mm


def _targets(ids):
    ts = load_manifest()["targets"]
    return [t for t in ts if not ids or t["id"] in set(ids)]


def _pick(t, from_src, root):
    if from_src and (root / t["src"]).exists():
        return root / t["src"]
    return root / t["out"]


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("ids", nargs="*")
    ap.add_argument("--from-src", action="store_true")
    ap.add_argument("--tolerance", type=float, default=DEFAULT_TOL)
    args = ap.parse_args(argv)

    root = repo_root()
    osc = find_openscad()
    ver = openscad_version(osc)
    print(f"openscad: {osc}\n{ver}\n")

    bl_dir = root / "tests" / "baseline"
    bl_dir.mkdir(parents=True, exist_ok=True)
    scratch = root / "tests" / "_scratch"
    scratch.mkdir(parents=True, exist_ok=True)

    # merge into any existing expected_bounds.json so target-by-target runs
    # accumulate; per-key 'tolerance_mm' / 'note' overrides are preserved
    prev_path = root / "tests" / "expected_bounds.json"
    expected = {
        "_note": (
            "Regression baseline for build/test.py. Keys are '<target-id>__<render-name>'. "
            "Update via build/baseline.py ONLY when the geometry change is intentional; "
            "review this file's diff as the sign-off."
        ),
        "_openscad": ver.splitlines()[0] if ver else "",
        "_tolerance_mm": args.tolerance,
        "renders": {},
    }
    if prev_path.exists():
        try:
            prev = json.loads(prev_path.read_text(encoding="utf-8"))
            expected["renders"] = prev.get("renders", {})
        except json.JSONDecodeError:
            pass

    failures = []
    for t in _targets(args.ids):
        scad = _pick(t, args.from_src, root)
        if not scad.exists():
            print(f"--  {t['id']}: no file ({scad.relative_to(root)}), skipped")
            continue
        for r in t["renders"]:
            key = f"{t['id']}__{r['name']}"
            t0 = time.time()
            res = render(scad, defines=r.get("defines"), out_dir=str(scratch),
                         binary_stl=True, timeout=900, openscad=osc)
            dt = time.time() - t0
            cons = parse_console(res.console)
            bounds = stl_bounds(res.stl_path) if res.ok else None
            rec = {
                "target": t["id"], "render": r["name"],
                "source": str(scad.relative_to(root)),
                "defines": r.get("defines", {}),
                "returncode": res.returncode, "timed_out": res.timed_out,
                "seconds": round(dt, 1),
                "bounds": bounds,
                "warnings": cons["warnings"], "errors": cons["errors"],
                "echoes": cons["echoes"],
            }
            (bl_dir / f"{key}.json").write_text(json.dumps(rec, indent=2), encoding="utf-8")

            entry = expected["renders"].get(key, {})
            entry["warnings"] = cons["warnings"]   # known-OK warnings for test.py
            if bounds is None:
                entry.update({"bounds": None})
                failures.append(f"{key}: no geometry (rc={res.returncode}, timeout={res.timed_out})")
                flag = "!! "
            else:
                entry.update({"bounds": {"min": bounds["min"], "max": bounds["max"]},
                              "tris": bounds["tris"]})
                flag = "   "
            expected["renders"][key] = entry
            wtag = f" [{len(cons['warnings'])}W]" if cons["warnings"] else ""
            etag = f" [{len(cons['errors'])}E]" if cons["errors"] else ""
            sz = f"{bounds['size']}" if bounds else "EMPTY"
            print(f"{flag}{key:<34} {dt:6.1f}s  size={sz}{wtag}{etag}")

    prev_path.write_text(json.dumps(expected, indent=2) + "\n", encoding="utf-8")
    scope = "all" if not args.ids else ", ".join(args.ids)
    print(f"\nwrote tests/expected_bounds.json ({len(expected['renders'])} renders; this run: {scope})")

    if failures:
        print("\nRENDERS WITH NO GEOMETRY:")
        for f in failures:
            print("  " + f)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
