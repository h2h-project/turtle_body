#!/usr/bin/env python3
"""Inline `use <>` / `include <>` directives into one self-contained .scad file.

The Turtle Body editable sources live in lib/ (parametric modules + the
parameter contract) and src/ (thin wrappers). The committed, downloadable,
STL-ready files (Full_Turtle_v1.scad, v1.0 SCADs/*.scad) are produced from
those by pasting every referenced lib file in place.

This is safe because lib/ files contain only `function` and `module`
definitions and comments -- never a top-level variable assignment or a
top-level geometry call -- so textual inlining matches OpenSCAD's `use`
semantics. bundle.py refuses to inline a file that breaks that rule.

Usage:
    build/bundle.py SRC.scad                 # bundled output to stdout
    build/bundle.py SRC.scad -o OUT.scad     # ... to a file
    build/bundle.py --list-deps SRC.scad     # referenced files, one per line
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from scad_lib import read_version  # noqa: E402

_DIRECTIVE = re.compile(
    r'^(?P<indent>\s*)(?P<kind>use|include)\s*<(?P<path>[^>]+)>\s*;?\s*(?P<trail>//.*)?$'
)
# a bare top-level assignment: `name = ...;`  (not `function name = ...`, not indented)
_TOP_ASSIGN = re.compile(r'^[A-Za-z_$][A-Za-z0-9_$]*\s*=')

BANNER = """\
// ==========================================================================
//  GENERATED FILE -- DO NOT EDIT.
//  Produced by build/build.py from {src}
//  Turtle Body version {version}
//  Edit lib/ and src/ instead, then run: python3 build/build.py
// ==========================================================================
"""


class BundleError(RuntimeError):
    pass


def _check_inlinable(path: Path, text: str) -> None:
    """A lib file that is `use`d must not carry top-level side effects, or
    pasting it changes behaviour."""
    for lineno, raw in enumerate(text.splitlines(), 1):
        line = raw.split("//", 1)[0].rstrip()
        if not line or line[0] in " \t":
            continue
        if line.startswith(("function ", "module ", "//", "/*", "*")):
            continue
        if _TOP_ASSIGN.match(line):
            raise BundleError(
                f"{path}:{lineno}: top-level assignment `{line.strip()}` in a "
                f"file that is inlined via use<>. Move constants into "
                f"lib/params.scad as `function p_x() = ...;`."
            )


def _inline(path: Path, seen: set, stack: list, deps: list) -> list[str]:
    ap = path.resolve()
    if ap in stack:
        chain = " -> ".join(str(p) for p in stack + [ap])
        raise BundleError(f"include cycle: {chain}")
    if ap in seen:
        return [f"// [bundle] already inlined: {ap.name}\n"]
    seen.add(ap)
    stack.append(ap)

    try:
        text = ap.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise BundleError(f"referenced file not found: {ap}")

    # only enforce the no-side-effect rule on nested (lib) files, not the root
    if len(stack) > 1:
        _check_inlinable(ap, text)

    out: list[str] = []
    for raw in text.splitlines(keepends=True):
        m = _DIRECTIVE.match(raw.rstrip("\n"))
        if not m:
            out.append(raw)
            continue
        ref = (ap.parent / m.group("path")).resolve()
        deps.append(ref)
        out.append(f"// [bundle] begin {m.group('kind')} <{m.group('path')}>\n")
        out.extend(_inline(ref, seen, stack, deps))
        if not out[-1].endswith("\n"):
            out.append("\n")
        out.append(f"// [bundle] end   <{m.group('path')}>\n")

    stack.pop()
    return out


def bundle(src: Path) -> str:
    src = Path(src)
    body = _inline(src, seen=set(), stack=[], deps=[])
    root = src.resolve().parent.parent  # repo root, assuming src/ or v1.0 SCADs/
    try:
        rel = src.resolve().relative_to(src.resolve().parents[1])
    except (ValueError, IndexError):
        rel = src.name
    return BANNER.format(src=rel, version=read_version()) + "".join(body)


def list_deps(src: Path) -> list[Path]:
    deps: list[Path] = []
    _inline(Path(src), seen=set(), stack=[], deps=deps)
    # unique, order-preserving
    out, ok = [], set()
    for d in deps:
        if d not in ok:
            ok.add(d)
            out.append(d)
    return out


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("src", type=Path)
    ap.add_argument("-o", "--output", type=Path)
    ap.add_argument("--list-deps", action="store_true")
    args = ap.parse_args(argv)

    try:
        if args.list_deps:
            for d in list_deps(args.src):
                print(d)
            return 0
        result = bundle(args.src)
    except BundleError as exc:
        print(f"bundle: {exc}", file=sys.stderr)
        return 1

    if args.output:
        args.output.write_text(result, encoding="utf-8")
    else:
        sys.stdout.write(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
