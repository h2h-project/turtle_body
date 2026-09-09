#!/usr/bin/env python3
"""Export every ``lib/params.scad`` value to ``build/params.json``.

``lib/params.scad`` is the shared dimension contract, expressed as zero-argument
``function p_*()`` definitions. The HopeTurtles.org generators
(``../hopeTurtles.org/generator/``) are downstream consumers that keep their own
copy of many of these numbers; nothing links the two, which is how they drift
(see that repo's ``generator/SYNC_PLAN.md``, item S-5, and CLAUDE.md section 19).

This script evaluates the contract once and writes it out as plain JSON so the
generator side can diff its own defaults against a machine-readable snapshot
instead of a human re-reading the .scad. It is run by ``build/build.py`` so the
snapshot is always regenerated alongside the bundles and committed with them.

Method: collect the ``p_*()`` names from ``lib/params.scad``, emit a throwaway
.scad that ``echo()``s each one, render it headless, and parse the ``ECHO:``
lines. Nothing here re-implements a formula -- OpenSCAD evaluates them.

Usage:
    build/export_params.py            # write build/params.json
    build/export_params.py --check    # exit nonzero if it is stale, write nothing
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scad_lib import find_openscad, parse_console, read_version, render, repo_root  # noqa: E402

PARAMS_SCAD = "lib/params.scad"
OUT_PATH = "build/params.json"

_FUNC_RE = re.compile(r"^\s*function\s+(p_[A-Za-z0-9_]*)\s*\(\s*\)\s*=", re.MULTILINE)
_ECHO_RE = re.compile(r'^ECHO:\s*"P",\s*"([^"]+)",\s*(.*\S)\s*$')


def _param_names(scad_text: str) -> list[str]:
    """Zero-arg ``p_*()`` function names, in source order, de-duplicated."""
    seen: dict[str, None] = {}
    for name in _FUNC_RE.findall(scad_text):
        seen.setdefault(name, None)
    return list(seen)


def _coerce(literal: str):
    """Turn one OpenSCAD echo value into a JSON-friendly Python value."""
    literal = literal.strip()
    if literal.startswith('"') and literal.endswith('"'):
        return literal[1:-1]
    if literal.startswith("["):
        # OpenSCAD vector syntax is JSON-compatible once whitespace is normal.
        return json.loads(literal)
    if literal in ("true", "false"):
        return literal == "true"
    if literal.lower() in ("inf", "-inf", "nan", "undef"):
        raise ValueError(f"non-finite parameter value: {literal!r}")
    num = float(literal)
    return int(num) if num.is_integer() and "." not in literal and "e" not in literal.lower() else num


def compute_params(*, openscad: str | None = None) -> dict:
    root = repo_root()
    names = _param_names((root / PARAMS_SCAD).read_text(encoding="utf-8"))
    if not names:
        raise SystemExit("export_params: no p_*() functions found in " + PARAMS_SCAD)

    params_abs = (root / PARAMS_SCAD).resolve()
    # `use <>` is resolved relative to the probe file, so give it an absolute
    # path; a throwaway cube keeps the STL export (hence the exit code) clean.
    probe = (
        f"use <{params_abs}>\n"
        + "".join(f'echo("P", "{n}", {n}());\n' for n in names)
        + "cube(1);\n"
    )
    with tempfile.TemporaryDirectory() as td:
        probe_path = Path(td) / "params_probe.scad"
        probe_path.write_text(probe, encoding="utf-8")
        result = render(str(probe_path), out_dir=td, openscad=openscad)

    found: dict[str, object] = {}
    for line in parse_console(result.console)["echoes"]:
        m = _ECHO_RE.match(line)
        if m:
            found[m.group(1)] = _coerce(m.group(2))

    missing = [n for n in names if n not in found]
    if missing:
        raise SystemExit(
            "export_params: no value captured for "
            + ", ".join(missing)
            + "\n--- OpenSCAD output ---\n"
            + result.console
        )

    # Emit in source order, version last, so the diff reads like params.scad.
    ordered = {n: found[n] for n in names}
    ordered["version"] = read_version()
    return ordered


def _render(params: dict) -> str:
    return json.dumps(params, indent=2) + "\n"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="exit nonzero if stale, write nothing")
    args = ap.parse_args(argv)

    try:
        find_openscad()
    except RuntimeError as exc:
        print(f"export_params: SKIPPED ({exc})", file=sys.stderr)
        return 0

    out = repo_root() / OUT_PATH
    new = _render(compute_params())
    old = out.read_text(encoding="utf-8") if out.exists() else ""

    if new == old:
        if not args.check:
            print(f"params up to date  {OUT_PATH}")
        return 0
    if args.check:
        print(f"STALE   {OUT_PATH}  -- run: python3 build/export_params.py")
        return 1
    out.write_text(new, encoding="utf-8")
    print(f"wrote   {OUT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
