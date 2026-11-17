#!/usr/bin/env python3
"""Export installed component meshes and exact ruler datums from the CAD scene.

Run with .venv/bin/python build/export_sim.py. Outputs are metres in simulator
axes (+X forward, +Y port, +Z up); no Python copy of assembly placements.
"""
from pathlib import Path
import argparse
import json
import re
import sys
import tempfile
import os

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'sim'))
from turtle_sim.geometry import COMPONENTS, GENERATED, fingerprint, load_mesh, manifest
from scad_lib import find_openscad, render, read_version
import numpy as np


# Display-only details: render the component again without the detail; the
# faces missing from that render are the detail. Physics meshes are unchanged.
DETAILS = {'sail_unit': ('no_sails', 'sail'), 'rear_support': ('no_panel', 'solar_panel')}


def render_mesh(osc, component, td, extra=None):
    """Render one sim component to a closed trimesh in CAD millimetres."""
    import trimesh
    target = Path(td)/'part.stl'
    r = render(ROOT/'src/Full_Turtle.scad',
               {'sim_component': component, 'show_water': False, **(extra or {})}, out_dir=td,
               openscad=osc, timeout=600)
    target = Path(r.stl_path)
    if r.returncode != 0 or not target.exists():
        raise ValueError(f'{component}{extra or ""}: CAD export failed: {r.stderr[-2500:]}')
    console = r.stdout + r.stderr
    warnings = [line for line in console.splitlines() if 'WARNING:' in line]
    unexpected = [w for w in warnings if 'may not be a valid 2-manifold' not in w]
    if unexpected or 'ERROR:' in console:
        raise ValueError(f'{component}: CAD warnings/errors: {console[-2500:]}')
    mesh = trimesh.load_mesh(target, process=True)
    normalization = None
    if not mesh.is_volume:
        # CGAL can emit coincident cavity seams. Only accept exact
        # Manifold reconstruction with a bounded, recorded volume delta.
        import manifold3d as md
        raw_volume = mesh.volume
        obj = md.Manifold(md.Mesh64(np.asarray(mesh.vertices),np.asarray(mesh.faces,dtype=np.uint64)))
        if obj.status() != md.Error.NoError:
            raise ValueError(f'{component}: non-manifold CAD; fix the source geometry')
        rebuilt = obj.to_mesh64()
        mesh = trimesh.Trimesh(rebuilt.vert_properties,rebuilt.tri_verts,process=True)
        if not mesh.is_volume or abs(mesh.volume-raw_volume)>abs(raw_volume)*0.001:
            raise ValueError(f'{component}: CAD reconstruction changed volume by more than 0.1%')
        normalization = {'method':'Manifold coincident-seam reconstruction',
                         'source_volume_mm3':raw_volume,'volume_delta_mm3':mesh.volume-raw_volume}
    return mesh, normalization, warnings, console


def winding_numbers(points, triangles, chunk_bytes=64_000_000):
    """Generalised winding number of each point w.r.t. a closed triangle mesh."""
    out = np.zeros(len(points))
    step = max(1, chunk_bytes // (24 * 3 * max(len(triangles), 1)))
    for i in range(0, len(points), step):
        r = triangles[None, :, :, :] - points[i:i+step, None, None, :]
        a, b, c = r[..., 0, :], r[..., 1, :], r[..., 2, :]
        la, lb, lc = (np.linalg.norm(v, axis=-1) for v in (a, b, c))
        det = np.einsum('ptj,ptj->pt', a, np.cross(b, c))
        den = (la*lb*lc + np.einsum('ptj,ptj->pt', a, b)*lc
               + np.einsum('ptj,ptj->pt', b, c)*la + np.einsum('ptj,ptj->pt', c, a)*lb)
        out[i:i+step] = (2*np.arctan2(det, den)).sum(axis=1) / (4*np.pi)
    return out


def detail_faces(mesh, without, inset=0.01):
    """Indices of mesh faces lying on the solid (mesh minus without).

    Each face centre is stepped `inset` mm inward (sails are 0.1 mm thick) and
    tested for being inside the detail solid by its winding number.
    """
    import manifold3d as md
    def manifold(m):
        return md.Manifold(md.Mesh64(np.asarray(m.vertices, dtype=np.float64),
                                     np.asarray(m.faces, dtype=np.uint64)))
    detail = manifold(mesh) - manifold(without)
    if detail.status() != md.Error.NoError or detail.volume() <= 0:
        return np.zeros(0, dtype=int)
    dm = detail.to_mesh64()
    tris = np.asarray(dm.vert_properties)[:, :3][np.asarray(dm.tri_verts)]
    probe = mesh.triangles_center - mesh.face_normals * inset
    lo, hi = tris.reshape(-1, 3).min(axis=0) - inset, tris.reshape(-1, 3).max(axis=0) + inset
    near = np.flatnonzero(((probe >= lo) & (probe <= hi)).all(axis=1))
    inside = winding_numbers(probe[near], tris) > 0.5
    return near[inside]


def export():
    import trimesh
    try:
        current = manifest()
        print('CAD export is up to date', flush=True)
        return current
    except ValueError:
        pass
    GENERATED.mkdir(parents=True, exist_ok=True)
    # An incomplete export must never retain a usable old manifest.
    (GENERATED/'manifest.json').unlink(missing_ok=True)
    osc = find_openscad()
    parts = []
    rulers = []
    signature = fingerprint()
    for component, (label, kind) in COMPONENTS.items():
        print(f'Exporting {label}', flush=True)
        with tempfile.TemporaryDirectory() as td:
            mesh, normalization, warnings, console = render_mesh(osc, component, td)
            origin_match = re.search(r'ECHO: "SIM_ORIGIN", (\[[^\n]+\])', console)
            if not origin_match:
                raise ValueError('CAD did not export SIM_ORIGIN')
            origin = np.array(json.loads(origin_match[1]))
            transform = np.diag([-1., -1., 1., 1.])
            transform[:3, :3] *= 0.001
            transform[:3, 3] = -transform[:3,:3] @ origin
            highlights = {}
            if component in DETAILS:
                switch, name = DETAILS[component]
                print(f'  finding {name} faces for display', flush=True)
                without, *_ = render_mesh(osc, component, td, {'sim_detail': switch})
                highlights[name] = detail_faces(mesh, without).tolist()
                if not highlights[name]:
                    raise ValueError(f'{component}: no {name} faces found; check sim_detail="{switch}"')
            mesh.apply_transform(transform)
            # Preserve float64 topology; STL float32 can collapse tiny sail seams.
            np.savez_compressed(GENERATED/f'{component}.npz',vertices=mesh.vertices,faces=mesh.faces)
            load_mesh(GENERATED/f'{component}.npz',component)
            # Indexed JSON avoids an extra browser loader and keeps geometry selectable.
            display = {'vertices': mesh.vertices.tolist(), 'faces': mesh.faces.tolist(),
                       'highlights': highlights}
            (GENERATED/f'{component}.json').write_text(json.dumps(display,separators=(',',':')))
            parts.append({'id':component,'label':label,'kind':kind,
                          'normalization':normalization,'cad_warnings':warnings,'mesh':f'{component}.npz','centroid_m':mesh.center_mass.tolist(),
                          'source_to_body':transform.tolist(), 'bounds_m':mesh.bounds.tolist()})
            if not rulers:
                for m in re.finditer(r'ECHO: "SIM_RULER", "(front|rear)", (-?1), (\[[^\]]+\]), (\[[^\]]+\])', console):
                    fin,side,point,span=m.groups()
                    p=transform@np.r_[json.loads(point),1]
                    y=p[1]
                    rulers.append({'id':f'{fin}_{"port" if y>0 else "starboard"}',
                                   'fin':fin,'face':'port' if y>0 else 'starboard',
                                   'zero_m':p[:3].tolist(),'direction':[0,0,1],
                                   'range_mm':json.loads(span)})
    if len(rulers)!=4:
        raise ValueError('Expected four CAD ruler face datums')
    if signature != fingerprint():
        raise ValueError('CAD changed during export; please export again')
    data={'fingerprint':signature,'cad_version':read_version(),
          'units':'m','components':parts,'rulers':rulers}
    tmp=GENERATED/'manifest.tmp'
    tmp.write_text(json.dumps(data,indent=2)+'\n')
    os.replace(tmp,GENERATED/'manifest.json')
    return data

if __name__=='__main__':
    argparse.ArgumentParser(description=__doc__).parse_args()
    export()
