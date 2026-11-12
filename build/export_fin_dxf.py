#!/usr/bin/env python3
"""Export registered CUT and ENGRAVE paths for both faces of each fin (mm).

First-face files have CUT + ENGRAVE. Opposite-face files contain ENGRAVE only,
reflected around the X=0 registration datum. Flip the blank about its local
vertical (2D Y) axis; do not auto-centre either file. Dry-run CAM before cutting.
"""
from pathlib import Path
import argparse
import subprocess
import sys
import tempfile
sys.path.insert(0,str(Path(__file__).resolve().parent))
from scad_lib import find_openscad, repo_root
import ezdxf


def export(out):
    root=repo_root();out.mkdir(parents=True,exist_ok=True)
    osc=find_openscad()
    for kind,module,zero in [('head','head_fin','0'),('rear','rear_fin','rf_ruler_zero()')]:
        paths={}
        with tempfile.TemporaryDirectory() as td:
            for layer,code in [('CUT',f'projection(cut=true) rotate([-90,0,0]) {module}_blank(colored=false);'),
                               ('ENGRAVE',f'fin_ruler_2d("{kind}",{zero},false);'),
                               ('BACK',f'mirror([1,0,0]) fin_ruler_2d("{kind}",{zero},true);')]:
                src=Path(td)/f'{layer}.scad';dest=Path(td)/f'{layer}.dxf'
                src.write_text(f'use <{root}/lib/{module}.scad>\nuse <{root}/lib/fin_ruler.scad>\n'+code+'\n')
                p=subprocess.run([osc,'-o',str(dest),str(src)],capture_output=True,text=True,timeout=180)
                if p.returncode or 'WARNING:' in p.stderr or 'ERROR:' in p.stderr:
                    raise ValueError(p.stderr)
                paths[layer]=ezdxf.readfile(dest)
            for face,layers in [('face_a',['CUT','ENGRAVE']),('face_b',['BACK'])]:
                doc=ezdxf.new('R2010');doc.units=4
                for layer in layers:
                    name='ENGRAVE' if layer=='BACK' else layer
                    if name not in doc.layers: doc.layers.new(name,dxfattribs={'color':1 if name=='ENGRAVE' else 7})
                    from ezdxf.addons import Importer
                    importer=Importer(paths[layer],doc)
                    before=set(doc.modelspace())
                    importer.import_modelspace();importer.finalize()
                    for e in set(doc.modelspace())-before:e.dxf.layer=name
                target=out/f'{kind}_fin_{face}.dxf';doc.saveas(target);print(target)
    (out/'README.txt').write_text(__doc__+'\nFirst face = local Y-negative face. Units mm. Zeros align with horizontal bottle axes.\n')

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,default=Path('fabrication/fins'))
    export(p.parse_args().out)
