"""Validate actual CAD/DXF exports when present, without running the slow regression."""
import json
from pathlib import Path
import numpy as np
import pytest
import ezdxf
from turtle_sim.geometry import ROOT,GENERATED,manifest,load_mesh


def test_ruler_datums_and_engraved_meshes():
    if not (GENERATED/'manifest.json').exists():pytest.skip('Export CAD for geometry integration checks')
    m=manifest()
    assert len(m['rulers'])==4
    for r in m['rulers']:
        assert r['zero_m'][2]==pytest.approx(0,abs=1e-9)
        assert r['direction']==[0,0,1]
        assert r['range_mm'][0]<0<r['range_mm'][1]
        assert r['zero_m'][0]>0 if r['fin']=='front' else r['zero_m'][0]<0
        assert r['zero_m'][1]>0 if r['face']=='port' else r['zero_m'][1]<0
    for part in m['components']:
        assert load_mesh(GENERATED/part['mesh'],part['id']).is_volume
        if part['normalization']:
            n=part['normalization']
            assert abs(n['volume_delta_mm3'])<=.001*abs(n['source_volume_mm3'])


def test_fabrication_layers_units_and_opposite_face_registration():
    folder=ROOT/'fabrication/fins'
    if not (folder/'head_fin_face_a.dxf').exists():pytest.skip('Run export_fin_dxf.py for DXF integration checks')
    for kind in ['head','rear']:
        a=ezdxf.readfile(folder/f'{kind}_fin_face_a.dxf')
        b=ezdxf.readfile(folder/f'{kind}_fin_face_b.dxf')
        assert a.units==b.units==4
        cuts=[e for e in a.modelspace() if e.dxf.layer=='CUT']
        etch_a=[e for e in a.modelspace() if e.dxf.layer=='ENGRAVE']
        etch_b=list(b.modelspace())
        assert len(cuts)>0 and len(etch_a)>100 and len(etch_a)==len(etch_b)
        assert all(e.dxf.layer=='ENGRAVE' for e in etch_b)
        assert all(e.dxftype() in ('LINE','LWPOLYLINE','POLYLINE') for e in etch_a)
