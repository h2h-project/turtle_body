#!/usr/bin/env python3
"""Regenerate the committed, self-contained .scad bundles from lib/ + src/.

For every manifest target that has an existing `src`, bundle.py inlines its
lib references and the result is written to the target's `out` path
(Full_Turtle_v1.scad or a v1.0 SCADs/*.scad). Targets without a src yet
(before the M1-M7 refactor lands) are skipped and reported.

This is the sync step: editing lib/ or src/ on either the master or a
component side and re-running this propagates the change to every bundle.

Usage:
    build/build.py            # rebuild all; nonzero exit if any bundle changed
    build/build.py --check    # do not write; nonzero exit if a bundle is stale
    build/build.py <id> ...   # rebuild only the named manifest target ids
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scad_lib import load_manifest, repo_root  # noqa: E402
from bundle import bundle, BundleError, BANNER  # noqa: E402

_BANNER_MARK = "// ====="


def _strip_banner(text: str) -> str:
    """Drop a leading generated-banner block so a version-only change does not
    count as a content change."""
    if not text.startswith(_BANNER_MARK):
        return text
    lines = text.splitlines(keepends=True)
    for i, ln in enumerate(lines):
        if i and ln.startswith(_BANNER_MARK):
            return "".join(lines[i + 1:])
    return text


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("ids", nargs="*", help="manifest target ids to rebuild (default: all)")
    ap.add_argument("--check", action="store_true", help="report staleness, write nothing")
    args = ap.parse_args(argv)

    root = repo_root()
    targets = load_manifest()["targets"]
    if args.ids:
        want = set(args.ids)
        targets = [t for t in targets if t["id"] in want]
        missing = want - {t["id"] for t in targets}
        if missing:
            print(f"unknown target id(s): {', '.join(sorted(missing))}", file=sys.stderr)
            return 2

    changed, skipped, errors = [], [], []
    for t in targets:
        src = root / t["src"]
        out = root / t["out"]
        if not src.exists():
            skipped.append(t["id"])
            continue
        try:
            new = bundle(src)
        except BundleError as exc:
            errors.append(f"{t['id']}: {exc}")
            continue

        old = out.read_text(encoding="utf-8") if out.exists() else ""
        if _strip_banner(old) == _strip_banner(new) and old == new:
            continue
        content_changed = _strip_banner(old) != _strip_banner(new)
        if args.check:
            if content_changed:
                changed.append(t["id"])
                print(f"STALE   {t['out']}")
            continue
        out.write_text(new, encoding="utf-8")
        changed.append(t["id"])
        print(f"{'rebuilt ' if content_changed else 'rebanner'} {t['out']}")

    if skipped:
        print(f"\nskipped (no src/ yet): {', '.join(skipped)}")
    if errors:
        print("\nERRORS:", file=sys.stderr)
        for e in errors:
            print("  " + e, file=sys.stderr)
        return 1
    if args.check:
        if changed:
            print(f"\n{len(changed)} bundle(s) stale -- run: python3 build/build.py")
            return 1
        print("all bundles up to date")
        return 0
    print(f"\n{len(changed)} bundle(s) written" if changed else "\nno changes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
