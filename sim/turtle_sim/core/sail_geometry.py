"""Geometry reductions for the sailing model: waterline clipping, flat plates
and silhouette (projected-area) tables. Pure NumPy/Shapely; no I/O."""
import math
import numpy as np
import shapely
from turtle_sim.core.sailing import BluffTable, Plate


def triangle_normals(tri):
    return np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])


def _clip_polygon(poly, keep_below):
    """Sutherland-Hodgman against the plane z = 0."""
    out = []
    sign = -1 if keep_below else 1
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        ina, inb = sign * a[2] >= 0, sign * b[2] >= 0
        if ina:
            out.append(a)
        if ina != inb:
            t = a[2] / (a[2] - b[2])
            out.append(a + t * (b - a))
    return out


def clip_triangles(tri, keep_below):
    """Triangles (n,3,3) cut by the water plane z = 0, keeping one side.

    Orientation (winding) is preserved, so face normals stay meaningful.
    """
    z = tri[:, :, 2]
    if keep_below:
        whole, none = (z <= 0).all(1), (z > 0).all(1)
    else:
        whole, none = (z >= 0).all(1), (z < 0).all(1)
    pieces = [tri[whole]]
    for t in tri[~whole & ~none]:
        poly = _clip_polygon(list(t), keep_below)
        for k in range(1, len(poly) - 1):
            pieces.append(np.array([[poly[0], poly[k], poly[k + 1]]]))
    return np.concatenate(pieces) if pieces else np.zeros((0, 3, 3))


def plate_from_triangles(name, medium, tri, normal, centre_frame_tri=None):
    """A flat plate from the triangles of a thin slab whose broad faces have `normal`.

    Area is one broad face (half the summed area of faces within ~25 deg of
    +-normal). Aspect ratio = vertical extent / horizontal extent within the plane.
    """
    if len(tri) == 0:
        return None
    n = triangle_normals(tri)
    a = np.linalg.norm(n, axis=1)
    ok = a > 1e-15
    tri, n, a = tri[ok], n[ok], a[ok]
    broad = np.abs((n / a[:, None]) @ normal) > 0.9
    if not broad.any():
        return None
    area = a[broad].sum() / 4  # |cross| = 2 * triangle area; two faces per slab
    if area < 1e-6:
        return None
    centre = (tri[broad].mean(1) * a[broad, None]).sum(0) / a[broad].sum()
    pts = tri[broad].reshape(-1, 3)
    up = np.array([0., 0., 1.])
    along = np.cross(up, normal)
    if np.linalg.norm(along) < 1e-6:
        along = np.array([1., 0., 0.])
    along /= np.linalg.norm(along)
    span = np.ptp(pts @ up)
    chord = np.ptp(pts @ along)
    return Plate(name, medium, float(area), float(span / max(chord, 1e-6)), centre, np.asarray(normal, float))


def silhouette(tri, flow_deg):
    """Union of the triangles projected along the horizontal flow direction.

    Returns the projected polygon in (lateral, z) coordinates, lateral measured
    along perp = (-sin, cos) of the flow direction.
    """
    a = math.radians(flow_deg)
    d = np.array([math.cos(a), math.sin(a), 0.])
    perp = np.array([-math.sin(a), math.cos(a), 0.])
    n = triangle_normals(tri)
    # Upstream-facing faces cover a closed surface's silhouette. A waterline cut
    # leaves an open horizontal edge, but horizontal rays never pass through it.
    front = n @ d < 0
    t = tri[front]
    if not len(t):
        return shapely.Polygon()
    pts = np.stack([t @ perp, t[:, :, 2]], axis=-1)
    ring = np.concatenate([pts, pts[:, :1]], axis=1)
    polys = shapely.polygons(ring)
    polys = polys[shapely.area(polys) > 1e-12]
    return shapely.union_all(polys) if len(polys) else shapely.Polygon()


def bluff_table(medium, tri, cg, step_deg=10):
    """Projected area and silhouette centroid vs flow direction, about the CG."""
    tri = np.asarray(tri, float) - np.asarray(cg, float)
    angles = np.arange(0, 360, step_deg, dtype=float)
    half = len(angles) // 2
    area = np.zeros(len(angles)); lateral = np.zeros(len(angles)); height = np.zeros(len(angles))
    yaw_m5 = 0.0
    for k in range(half):
        shape = silhouette(tri, angles[k])
        if shape.is_empty or shape.area <= 0:
            continue
        c = shape.centroid
        area[k], lateral[k], height[k] = shape.area, c.x, c.y
        # Opposite flow sees the same silhouette mirrored in `lateral`.
        area[k + half], lateral[k + half], height[k + half] = shape.area, -c.x, c.y
        if abs(angles[k] - 90) < 1e-9:
            yaw_m5 = yaw_moment_integral(shape)
    if half and not any(abs(angles[:half] - 90) < 1e-9):
        yaw_m5 = yaw_moment_integral(silhouette(tri, 90.0))
    return BluffTable(medium, angles, area, lateral, height, yaw_m5)


def yaw_moment_integral(shape, strips=60):
    """Integral of h(x) |x|^3 dx over a side silhouette (flow along +Y).

    For flow along +Y, perp = (-1, 0), so the silhouette's first coordinate is -x.
    """
    if shape.is_empty:
        return 0.0
    x0, _, x1, _ = shape.bounds
    edges = np.linspace(x0, x1, strips + 1)
    total = 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        piece = shape.intersection(shapely.box(lo, -1e3, hi, 1e3))
        if piece.is_empty:
            continue
        x = abs(0.5 * (lo + hi))
        total += piece.area * x ** 3
    return float(total)
