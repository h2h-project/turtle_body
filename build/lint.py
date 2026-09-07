#!/usr/bin/env python3
"""Fast static checks for the Turtle Body sources and bundles.

  1. bundle freshness  -- every committed .scad matches `bundle.py` of its src
  2. git whitespace    -- `git diff --check`
  3. OpenSCAD parse    -- CSG-tree evaluation (no CGAL meshing) of every
                          lib/, src/ and bundle .scad; fails on ERROR lines,
                          failed asserts, or unexpected WARNING lines
  4. lib hygiene       -- no top-level variable assignments in lib/ files
                          (they are inlined via use<> and must be side-effect free)

This does not mesh geometry -- that is build/test.py. Runs in a few seconds.

Usage: build/lint.py
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scad_lib import load_manifest, repo_root, find_openscad, parse_console  # noqa: E402
import build as build_mod  # noqa: E402
from bundle import _check_inlinable, BundleError  # noqa: E402

WARN_ALLOW = (
    "No top level geometry to render",
)


def _parse_check(scad: Path, osc: str) -> list[str]:
    """Run a CSG evaluation and return a list of problem strings (empty = ok)."""
    with tempfile.TemporaryDirectory() as td:
        out = str(Path(td) / "x.csg")
        proc = subprocess.run([osc, "-o", out, str(scad)],
                              capture_output=True, text=True, timeout=180)
    cons = parse_console(proc.stdout + proc.stderr)
    problems = []
    if proc.returncode != 0:
        problems.append(f"exit {proc.returncode}")
    for e in cons["errors"]:
        problems.append(e[:120])
    for w in cons["warnings"]:
        if not any(a in w for a in WARN_ALLOW):
            problems.append(w[:120])
    return problems


def main() -> int:
    root = repo_root()
    fails = 0

    # 1. bundle freshness ---------------------------------------------------
    print("== bundle freshness ==")
    rc = build_mod.main(["--check"])
    if rc != 0:
        fails += 1

    # 2. git whitespace ---------------------------------------------------
    print("\n== git diff --check ==")
    gd = subprocess.run(["git", "-C", str(root), "diff", "--check"],
                        capture_output=True, text=True)
    if gd.returncode != 0:
        print(gd.stdout + gd.stderr)
        fails += 1
    else:
        print("clean")

    # 3. lib hygiene ----------------------------------------------------
    print("\n== lib/ hygiene (no top-level side effects) ==")
    lib_files = sorted((root / "lib").glob("*.scad"))
    if not lib_files:
        print("(no lib/*.scad yet)")
    for f in lib_files:
        try:
            _check_inlinable(f, f.read_text(encoding="utf-8"))
            print(f"ok   {f.relative_to(root)}")
        except BundleError as exc:
            print(f"FAIL {exc}")
            fails += 1

    # 4. OpenSCAD parse ------------------------------------------------
    print("\n== OpenSCAD parse / CSG eval ==")
    try:
        osc = find_openscad()
    except RuntimeError as exc:
        print(f"SKIPPED: {exc}")
        return 1 if fails else 0

    scads = []
    scads += sorted((root / "lib").glob("*.scad"))
    scads += sorted((root / "src").rglob("*.scad"))
    for t in load_manifest()["targets"]:
        p = root / t["out"]
        if p.exists():
            scads.append(p)
    for scad in scads:
        problems = _parse_check(scad, osc)
        if problems:
            fails += 1
            print(f"FAIL {scad.relative_to(root)}")
            for p in problems:
                print("       " + p)
        else:
            print(f"ok   {scad.relative_to(root)}")

    print(f"\n{'LINT FAILED' if fails else 'lint ok'} ({fails} problem group(s))")
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
