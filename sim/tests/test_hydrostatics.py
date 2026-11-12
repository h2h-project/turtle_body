import math
import numpy as np
import pytest
import trimesh
from turtle_sim.core.hydrostatics import Hydrostatics, rotation, submerged, displacement_union, ruler_reading
from turtle_sim.geometry import valid_mesh


def test_box_waterline_and_centroid():
    obj=displacement_union([trimesh.creation.box(extents=[2,4,6])])
    v,cb=submerged(obj,1,np.eye(3))
    assert v==pytest.approx(16)
    assert cb==pytest.approx([0,0,-1])
    v,cb=submerged(obj,-10,rotation(.2,.3))
    assert v==pytest.approx(48)
    assert cb==pytest.approx([0,0,-10])
    assert submerged(obj,10,np.eye(3))[0]==0


def test_sphere_analytic_half_volume_and_centroid():
    radius=.2
    sphere=trimesh.creation.icosphere(subdivisions=4,radius=radius)
    v,cb=submerged(displacement_union([sphere]),0,np.eye(3))
    assert v==pytest.approx(2*math.pi*radius**3/3,rel=.005)
    assert cb==pytest.approx([0,0,-3*radius/8],abs=.0003)


def test_overlap_does_not_double_displacement():
    a=trimesh.creation.box(extents=[1,1,1]);b=a.copy();b.apply_translation([.5,0,0])
    assert displacement_union([a,b]).volume()==pytest.approx(1.5)
    assert displacement_union([a,a.copy()]).volume()==pytest.approx(1)


def test_equilibrium_known_mass_and_stability():
    model=Hydrostatics([trimesh.creation.box(extents=[.2,.2,.2])],4,[0,0,-.06])
    result=model.solve()
    assert result['status']=='equilibrium'
    e=result['equilibria'][result['selected']]
    assert e['heave_m']==pytest.approx(0,abs=1e-7)
    assert e['roll_deg']==pytest.approx(0,abs=.001)
    assert e['volume_m3']==pytest.approx(.004,rel=1e-5)
    assert e['stable']
    assert max(map(abs,e['relative_residual']))<1e-4


def test_offcentre_mass_generates_pitch_not_commanded_heading():
    model=Hydrostatics([trimesh.creation.box(extents=[.4,.3,.2])],10,[.015,0,-.06])
    result=model.solve()
    assert result['status']=='equilibrium'
    e=result['equilibria'][result['selected']]
    assert e['pitch_deg']>0
    assert abs(e['roll_deg'])<.01


def test_high_centre_of_mass_overturns_upright():
    model=Hydrostatics([trimesh.creation.box(extents=[.2,.2,.2])],4,[0,0,.2])
    assert all(c['classification']=='overturning' for c in model.local_stability([0,0,0]))


def test_overload_and_invalid_mesh():
    model=Hydrostatics([trimesh.creation.box(extents=[.1,.1,.1])],2,[0,0,0])
    assert model.solve()['status']=='insufficient_displacement'
    m=trimesh.creation.box();m.update_faces(np.arange(len(m.faces)-1))
    with pytest.raises(ValueError,match='closed'):valid_mesh(m,'Broken bottle')


def test_ruler_datum_pitch_roll_and_range():
    r={'id':'front_port','zero_m':[.5,.1,0], 'direction':[0,0,1],'range_mm':[-100,100]}
    assert ruler_reading(r,0,np.eye(3))['reading_mm']==pytest.approx(0)
    assert ruler_reading(r,-.02,np.eye(3))['reading_mm']==pytest.approx(20)
    R=rotation(.1,.05);reading=ruler_reading(r,-.01,R)
    point=np.array(r['zero_m'])+np.array(r['direction'])*reading['reading_mm']/1000
    assert (R@point+[0,0,-.01])[2]==pytest.approx(0,abs=1e-10)
    assert not ruler_reading(r,-.2,np.eye(3))['in_range']
