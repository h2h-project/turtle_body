"""Calm-water force/moment balance, local stability and ruler observations.

Pose convention: R = Ry(pitch) @ Rx(roll), radians; heave is translation in
world Z. Water is world Z=0. Positive pitch rotates +X toward -world Z.
"""
import math
import numpy as np
import trimesh
import manifold3d as md
from scipy.optimize import least_squares, brentq
from turtle_sim.geometry import valid_mesh

G = 9.80665


def rotation(roll, pitch):
    cr,sr,cp,sp=np.cos(roll),np.sin(roll),np.cos(pitch),np.sin(pitch)
    return np.array([[cp,sp*sr,sp*cr],[0,cr,-sr],[-sp,cp*sr,cp*cr]])


def as_manifold(mesh):
    valid_mesh(mesh, 'Displacement')
    obj=md.Manifold(md.Mesh64(np.asarray(mesh.vertices,dtype=np.float64),
                              np.asarray(mesh.faces,dtype=np.uint64)))
    if obj.status() != md.Error.NoError:
        raise ValueError(f'Displacement Boolean failed: {obj.status()}')
    return obj


def as_trimesh(obj):
    m=obj.to_mesh64()
    return trimesh.Trimesh(np.asarray(m.vert_properties)[:,:3],np.asarray(m.tri_verts),process=False)


def displacement_union(meshes):
    if not meshes:
        raise ValueError('No displacement geometry selected')
    obj=md.Manifold.batch_boolean([as_manifold(m) for m in meshes],md.OpType.Add)
    if obj.status()!=md.Error.NoError or obj.volume() <= 0:
        raise ValueError('Could not union displacement geometry')
    return obj


def submerged(obj, heave, R):
    # Clip in BODY coordinates; Manifold closes the cut plane automatically.
    wet=obj.trim_by_plane(-R[2],heave)
    volume=wet.volume()
    if volume<1e-14:
        return 0.,np.zeros(3)
    cb_body=as_trimesh(wet).center_mass
    return volume, R@cb_body + [0,0,heave]


def ruler_reading(ruler, heave, R):
    origin=R@np.array(ruler['zero_m'])+[0,0,heave]
    direction=R@np.array(ruler['direction'])
    if abs(direction[2])<1e-8:
        return {'id':ruler['id'],'reading_mm':None,'in_range':False}
    mm=float(-origin[2]/direction[2]*1000)
    lo,hi=ruler['range_mm']
    return {'id':ruler['id'],'reading_mm':mm,'in_range':bool(lo<=mm<=hi)}


class Hydrostatics:
    def __init__(self, meshes, mass_kg, com_m, density=1000):
        if not np.isfinite([mass_kg,density,*com_m]).all() or mass_kg<=0 or density<=0:
            raise ValueError('Mass and density must be positive finite values')
        self.obj=displacement_union(meshes)
        self.mass=float(mass_kg)
        self.com=np.asarray(com_m,dtype=float)
        self.rho=float(density)
        self.mesh=as_trimesh(self.obj)
        self.scale=max(float(np.linalg.norm(self.mesh.extents)),.01)
        self.depth=max(float(np.max(np.linalg.norm(self.mesh.vertices,axis=1))),self.scale)*2+1

    def state(self, pose):
        heave,roll,pitch=pose
        R=rotation(roll,pitch)
        volume,cb=submerged(self.obj,heave,R)
        cg=R@self.com+[0,0,heave]
        buoyancy=self.rho*G*volume
        # Net moment about CG; gravity has zero moment here.
        moment=np.cross(cb-cg,[0,0,buoyancy])
        return volume,cb,cg,moment

    def residual(self, pose):
        volume,_,_,moment=self.state(pose)
        return np.r_[(self.rho*volume-self.mass)/self.mass,
                     moment[:2]/(self.mass*G*self.scale)]

    def heave_at(self, roll, pitch):
        def f(z):
            return self.rho*submerged(self.obj,z,rotation(roll,pitch))[0]-self.mass
        return brentq(f,-self.depth,self.depth,xtol=1e-9)

    def local_stability(self, pose):
        curves=[]
        # Moments are world axes; pitch coordinate rotates about world Y;
        # at nonzero pitch roll rotates about R_y * X, so project accordingly.
        for axis in [1,2]:
            samples=[]
            axis_vector=np.array([np.cos(pose[2]),0,-np.sin(pose[2])]) if axis==1 else np.array([0,1,0])
            for degrees in [-5,-2,-1,0,1,2,5]:
                p=np.array(pose,dtype=float,copy=True)
                p[axis]+=math.radians(degrees)
                p[0]=self.heave_at(p[1],p[2])
                moment=self.state(p)[3]
                samples.append({'offset_deg':degrees,'moment_nm':float(moment@axis_vector)})
            # d(moment)/d(angle)<0 means restoring; neutral is distinct.
            slope=(samples[4]['moment_nm']-samples[2]['moment_nm'])/math.radians(2)
            tol=self.mass*G*self.scale*1e-4
            curves.append({'axis':'roll' if axis==1 else 'pitch',
                           'classification':'restoring' if slope < -tol else 'overturning' if slope>tol else 'neutral',
                           'slope_nm_per_rad':slope,'samples':samples})
        return curves

    def solve(self, rulers=()):
        if self.rho*self.obj.volume() <= self.mass*(1+1e-6):
            return {'status':'insufficient_displacement','capacity_kg':self.rho*self.obj.volume()}
        solutions=[]
        # Upright neighbourhood, plus finite-angle seeds to reveal alternatives.
        for roll,pitch in [(0,0),(.4,0),(-.4,0),(0,.4),(0,-.4),(1.4,0),(-1.4,0)]:
            start=[self.heave_at(roll,pitch),roll,pitch]
            fit=least_squares(self.residual,start,
                              bounds=([-self.depth,-math.radians(85),-math.radians(85)],
                                      [self.depth,math.radians(85),math.radians(85)]),
                              diff_step=1e-4,xtol=1e-8,ftol=1e-8,gtol=1e-8,max_nfev=100)
            if np.linalg.norm(self.residual(fit.x),ord=np.inf)>1e-4:
                continue
            if any(np.linalg.norm(fit.x[1:]-s[1:])<1e-3 for s in solutions):
                continue
            solutions.append(fit.x)
        if not solutions:
            return {'status':'solver_failure','message':'No balanced pose found within ±85°. This is not proof that no equilibrium exists.'}
        solutions.sort(key=lambda p:float(np.linalg.norm(p[1:])))
        equilibria=[]
        for pose in solutions:
            v,cb,cg,moment=self.state(pose)
            stability=self.local_stability(pose)
            equilibria.append({'heave_m':float(pose[0]),'roll_deg':math.degrees(pose[1]),
                'pitch_deg':math.degrees(pose[2]),'rotation':rotation(*pose[1:]).tolist(),
                'volume_m3':v,'centre_buoyancy_m':cb.tolist(),'centre_mass_m':cg.tolist(),
                'relative_residual':self.residual(pose).tolist(), 'stability':stability,
                'stable':all(c['classification']=='restoring' for c in stability),
                'rulers':[ruler_reading(r,pose[0],rotation(*pose[1:])) for r in rulers]})
        preferred=next((i for i,s in enumerate(equilibria) if s['stable']),0)
        return {'status':'equilibrium','mass_kg':self.mass,'body_com_m':self.com.tolist(),
                'density_kg_m3':self.rho,'selected':preferred,'equilibria':equilibria,
                'search_note':'Search limited to ±85° pitch/roll; local axis stability does not establish a capsize limit or exclude coupled instability.'}
