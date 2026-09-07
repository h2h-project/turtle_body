"""Shared helpers for the Turtle Body build/lint/test scripts.

Standard library only. No third-party dependencies.

Contents:
  find_openscad()          locate the OpenSCAD binary
  render(...)              headless render a .scad to a temp STL, capture output
  stl_bounds(path)         axis-aligned bounding box of an STL (ascii or binary)
  parse_console(text)      split OpenSCAD console output into ECHO/WARNING/ERROR
  load_manifest()          read build/manifest.json
  repo_root()              absolute path to the repository root
  read_version()           version string from VERSION.json
"""

from __future__ import annotations

import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path


# --------------------------------------------------------------------------- #
# paths
# --------------------------------------------------------------------------- #

def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def load_manifest() -> dict:
    with open(repo_root() / "build" / "manifest.json", encoding="utf-8") as fh:
        return json.load(fh)


def read_version() -> str:
    try:
        with open(repo_root() / "VERSION.json", encoding="utf-8") as fh:
            return json.load(fh)["version"]
    except (FileNotFoundError, KeyError, json.JSONDecodeError):
        return "0.0.0"


# --------------------------------------------------------------------------- #
# locating OpenSCAD
# --------------------------------------------------------------------------- #

_CANDIDATES = [
    os.environ.get("OPENSCAD"),
    "openscad",
    str(Path.home() / ".local" / "bin" / "openscad"),
    "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD",
    "/Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD",
    "/usr/bin/openscad",
    "/snap/bin/openscad",
]


def find_openscad() -> str:
    """Return a runnable OpenSCAD command, or raise RuntimeError."""
    for cand in _CANDIDATES:
        if not cand:
            continue
        resolved = shutil.which(cand) or (cand if Path(cand).exists() else None)
        if not resolved:
            continue
        try:
            out = subprocess.run(
                [resolved, "--version"],
                capture_output=True, text=True, timeout=30,
            )
            if out.returncode == 0 and "OpenSCAD" in (out.stdout + out.stderr):
                return resolved
        except (OSError, subprocess.SubprocessError):
            continue
    raise RuntimeError(
        "OpenSCAD not found. Install it, put it on PATH, or set the OPENSCAD "
        "environment variable to the binary."
    )


def openscad_version(binary: str | None = None) -> str:
    binary = binary or find_openscad()
    out = subprocess.run([binary, "--version"], capture_output=True, text=True, timeout=30)
    return (out.stdout + out.stderr).strip()


# --------------------------------------------------------------------------- #
# rendering
# --------------------------------------------------------------------------- #

def _define_args(defines: dict | None) -> list[str]:
    args: list[str] = []
    for key, val in (defines or {}).items():
        if isinstance(val, bool):
            literal = "true" if val else "false"
        elif isinstance(val, (int, float)):
            literal = repr(val)
        else:
            literal = '"%s"' % str(val).replace('"', r"\"")
        args += ["-D", f"{key}={literal}"]
    return args


class RenderResult:
    def __init__(self, returncode, stdout, stderr, stl_path, timed_out=False):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr
        self.stl_path = stl_path
        self.timed_out = timed_out

    @property
    def console(self) -> str:
        return (self.stdout or "") + (self.stderr or "")

    @property
    def ok(self) -> bool:
        return self.returncode == 0 and not self.timed_out


def render(scad_path, defines=None, out_dir=None, binary_stl=True,
           hardwarnings=False, timeout=600, openscad=None) -> RenderResult:
    """Render *scad_path* to an STL. The STL lands in *out_dir* (a temp dir if
    None) and its path is returned on the result. Console output is captured."""
    openscad = openscad or find_openscad()
    scad_path = str(scad_path)
    cleanup = False
    if out_dir is None:
        out_dir = tempfile.mkdtemp(prefix="turtle_render_")
        cleanup = False  # caller inspects the STL; left for OS temp reaping
    stem = Path(scad_path).stem
    tag = "_".join(f"{k}-{v}" for k, v in (defines or {}).items()) or "default"
    safe_tag = "".join(c if c.isalnum() or c in "-_" else "_" for c in tag)
    out_stl = str(Path(out_dir) / f"{stem}__{safe_tag}.stl")

    cmd = [openscad]
    if hardwarnings:
        cmd.append("--hardwarnings")
    cmd += ["--export-format", "binstl" if binary_stl else "asciistl"]
    cmd += _define_args(defines)
    cmd += ["-o", out_stl, scad_path]

    def _s(v):
        if v is None:
            return ""
        return v.decode("utf-8", "replace") if isinstance(v, bytes) else v

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        return RenderResult(
            None, _s(exc.stdout), _s(exc.stderr) + f"\nTIMEOUT after {timeout}s",
            out_stl, timed_out=True,
        )
    return RenderResult(proc.returncode, proc.stdout, proc.stderr, out_stl)


# --------------------------------------------------------------------------- #
# STL bounding box
# --------------------------------------------------------------------------- #

def _is_binary_stl(path: str) -> bool:
    size = os.path.getsize(path)
    if size < 84:
        return False
    with open(path, "rb") as fh:
        fh.seek(80)
        (ntri,) = struct.unpack("<I", fh.read(4))
    return size == 84 + ntri * 50


def stl_bounds(path: str) -> dict | None:
    """Return {'min':[x,y,z], 'max':[x,y,z], 'size':[dx,dy,dz], 'tris':n} or
    None if the STL holds no geometry."""
    path = str(path)
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return None

    lo = [float("inf")] * 3
    hi = [float("-inf")] * 3
    tris = 0

    if _is_binary_stl(path):
        with open(path, "rb") as fh:
            fh.seek(80)
            (ntri,) = struct.unpack("<I", fh.read(4))
            for _ in range(ntri):
                data = fh.read(50)
                if len(data) < 50:
                    break
                vals = struct.unpack("<12fH", data)
                for v in range(3):
                    for axis in range(3):
                        c = vals[3 + v * 3 + axis]
                        lo[axis] = min(lo[axis], c)
                        hi[axis] = max(hi[axis], c)
                tris += 1
    else:
        with open(path, "r", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if line.startswith("vertex"):
                    _, xs, ys, zs = line.split()[:4]
                    for axis, s in enumerate((xs, ys, zs)):
                        c = float(s)
                        lo[axis] = min(lo[axis], c)
                        hi[axis] = max(hi[axis], c)
                elif line.startswith("facet"):
                    tris += 1

    if tris == 0 or lo[0] == float("inf"):
        return None
    return {
        "min": [round(v, 4) for v in lo],
        "max": [round(v, 4) for v in hi],
        "size": [round(hi[i] - lo[i], 4) for i in range(3)],
        "tris": tris,
    }


def bounds_delta(a: dict | None, b: dict | None) -> float:
    """Largest absolute coordinate difference between two bounds dicts.
    inf if one side is missing and the other is not."""
    if a is None and b is None:
        return 0.0
    if a is None or b is None:
        return float("inf")
    worst = 0.0
    for key in ("min", "max"):
        for i in range(3):
            worst = max(worst, abs(a[key][i] - b[key][i]))
    return worst


# --------------------------------------------------------------------------- #
# console parsing
# --------------------------------------------------------------------------- #

def parse_console(text: str) -> dict:
    echoes, warnings, errors = [], [], []
    for raw in (text or "").splitlines():
        line = raw.strip()
        if line.startswith("ECHO:"):
            echoes.append(line)
            # an echo whose text itself starts with WARNING is a soft design flag
            body = line[len("ECHO:"):].strip().strip('"')
            if body.upper().startswith("WARNING"):
                warnings.append(line)
        elif line.startswith("WARNING:"):
            warnings.append(line)
        elif line.startswith("ERROR:") or line.startswith("TRACE:"):
            errors.append(line)
    return {"echoes": echoes, "warnings": warnings, "errors": errors}


if __name__ == "__main__":
    # quick self-check
    b = find_openscad()
    print("openscad:", b)
    print(openscad_version(b))
