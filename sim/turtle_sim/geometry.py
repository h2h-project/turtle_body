"""Geometry provenance, assembly export contract and mesh validation."""
from pathlib import Path
import hashlib
import json
import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parents[2]
GENERATED = ROOT / 'sim/generated'
COMPONENTS = {
    'frame': ('Ecojoiner and clamps', 'mixed'),
    'bottle_front': ('Front bottle and closure', 'bottle'),
    'bottle_rear': ('Rear bottle and closure', 'bottle'),
    'bottle_port': ('Port bottle and closure', 'bottle'),
    'bottle_starboard': ('Starboard bottle and closure', 'bottle'),
    'bottle_bottom': ('Bottom bottle and closure', 'bottle'),
    'front_fin': ('Front engraved fin', 'uniform'),
    'front_support': ('Front support slats', 'uniform'),
    'rear_fin': ('Rear engraved fin', 'uniform'),
    'rear_support': ('Rear supports, panel and screws', 'mixed'),
    'ballast_frame': ('Ballast frame, fin and hardware', 'mixed'),
    'control_housing': ('Cut control bottle, cap and buttons', 'housing'),
    'sail_unit': ('Sail, frame, cage and shaft', 'mixed'),
}

def fingerprint():
    h = hashlib.sha256()
    for p in sorted([*ROOT.glob('lib/*.scad'), *ROOT.glob('src/**/*.scad'),
                     ROOT/'VERSION.json', ROOT/'build/export_sim.py',
                     Path(__file__)]):
        h.update(str(p.relative_to(ROOT)).encode())
        h.update(p.read_bytes())
    return h.hexdigest()


def manifest():
    p = GENERATED / 'manifest.json'
    if not p.exists():
        raise ValueError('Export geometry first using the Export CAD button.')
    data = json.loads(p.read_text())
    if data['fingerprint'] != fingerprint():
        raise ValueError('CAD export is stale. Export CAD again before calculating.')
    return data


def valid_mesh(mesh, name):
    if not isinstance(mesh, trimesh.Trimesh) or not len(mesh.faces):
        raise ValueError(f'{name}: empty or unsupported mesh')
    if not np.isfinite(mesh.vertices).all() or not mesh.is_volume:
        raise ValueError(f'{name}: displacement must be a closed, consistently wound positive-volume mesh')
    return mesh


def load_mesh(path, name):
    if Path(path).suffix == '.npz':
        with np.load(path, allow_pickle=False) as data:
            return valid_mesh(trimesh.Trimesh(data['vertices'],data['faces'],process=False),name)
    return valid_mesh(trimesh.load_mesh(path, process=True), name)
