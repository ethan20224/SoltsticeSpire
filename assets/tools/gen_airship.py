"""
Blender 5.2.1 LTS Sculptor: 'The Dawnbreaker' — Stylized Ghibli x Astro-Bot Sky-Airship
Docked beside World 1's Awakening Terrace for Solstice Spire's Story Arrival!
Preserves named pivot `PropellerPivot` for live spinning rear brass propeller in Godot.
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector, Matrix

OUT_PATH = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/scenery/sky_airship.glb"
os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_mat(name, col, rough=0.55, metal=0.0, em=None, em_s=0.0, coat=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*col, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = coat
    if em is not None and em_s > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*em, 1.0)
        bsdf.inputs["Emission Strength"].default_value = em_s
    return m


def add_bm(name, bm, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True, bevel=0.0, parent=None):
    mesh = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = rot
    obj.data.materials.append(m)
    if parent is not None:
        obj.parent = parent
    if smooth:
        for p in mesh.polygons:
            p.use_smooth = True
    if bevel > 0.0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    return obj


def box(name, size, m, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.03, parent=None):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= size[0]
        v.co.y *= size[1]
        v.co.z *= size[2]
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=False, bevel=bevel, parent=parent)


def cyl(name, r1, r2, depth, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True, bevel=0.0, parent=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=depth)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel, parent=parent)


def sweep_tube(name, pts, radii, m, segs=8, cap=True, parent=None):
    bm = bmesh.new()
    rings = []
    n = len(pts)
    prev_up = Vector((0, 0, 1))
    for i, pt in enumerate(pts):
        if i == 0:
            t = (pts[1] - pts[0]).normalized()
        elif i == n - 1:
            t = (pts[-1] - pts[-2]).normalized()
        else:
            t = (pts[i + 1] - pts[i - 1]).normalized()
        if abs(t.dot(prev_up)) > 0.94:
            prev_up = Vector((1, 0, 0)) if abs(t.x) < 0.8 else Vector((0, 1, 0))
        side = t.cross(prev_up).normalized()
        up = side.cross(t).normalized()
        prev_up = up
        r = radii[i]
        ring = []
        for s in range(segs):
            a = math.tau * s / segs
            ring.append(bm.verts.new(pt + (side * math.cos(a) + up * math.sin(a)) * r))
        rings.append(ring)
    for i in range(n - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            bm.faces.new((rings[i][s], rings[i][sn], rings[i + 1][sn], rings[i + 1][s]))
    if cap:
        c0 = bm.verts.new(pts[0])
        c1 = bm.verts.new(pts[-1])
        for s in range(segs):
            sn = (s + 1) % segs
            bm.faces.new((c0, rings[0][sn], rings[0][s]))
            bm.faces.new((c1, rings[-1][s], rings[-1][sn]))
    return add_bm(name, bm, m, smooth=True, parent=parent)


def build_airship():
    clear()
    # Rich Studio Ghibli x Astro-Bot warm palette
    m_wood = make_mat("ShipWoodCedar", (0.44, 0.23, 0.12), rough=0.62)
    m_wood_dark = make_mat("ShipWoodDark", (0.26, 0.14, 0.08), rough=0.68)
    m_brass = make_mat("ShipBrass", (0.84, 0.60, 0.20), rough=0.25, metal=0.88)
    m_cream = make_mat("BalloonCream", (0.95, 0.90, 0.78), rough=0.72)
    m_crimson = make_mat("BalloonCrimson", (0.72, 0.19, 0.15), rough=0.58)
    m_rope = make_mat("ShipRope", (0.64, 0.52, 0.34), rough=0.84)
    m_glow = make_mat("CabinAmberGlow", (1.0, 0.74, 0.28), rough=0.18, em=(1.0, 0.68, 0.22), em_s=2.4)

    # 1. Sculpted Tapered Wooden Boat Hull (oriented along Y: +Y bow, -Y stern, deck around Z = 0.0)
    bm_hull = bmesh.new()
    y_stations = [-4.4, -3.4, -2.0, -0.4, 1.4, 3.0, 4.2, 5.2]
    half_widths = [0.75, 1.35, 1.72, 1.85, 1.74, 1.32, 0.72, 0.14]
    keel_zs = [-0.65, -1.25, -1.55, -1.62, -1.52, -1.18, -0.62, 0.08]
    deck_zs = [0.42, 0.24, 0.12, 0.08, 0.14, 0.28, 0.48, 0.74]

    cross_n = 12
    rings = []
    for yi, y in enumerate(y_stations):
        w = half_widths[yi]
        kz = keel_zs[yi]
        dz = deck_zs[yi]
        ring = []
        for ci in range(cross_n):
            # Profile from port gunwale -> down belly -> keel -> up belly -> starboard gunwale -> deck
            u = ci / cross_n
            ang = u * math.tau
            px = math.sin(ang) * w
            if math.cos(ang) >= 0.0:
                # Top deck arch (slight camber)
                pz = dz + 0.06 * math.cos(ang)
            else:
                # Rounded boat hull bottom
                t_b = -math.cos(ang)
                pz = dz + (kz - dz) * (t_b ** 0.78)
            ring.append(bm_hull.verts.new((px, y, pz)))
        rings.append(ring)

    for yi in range(len(rings) - 1):
        for ci in range(cross_n):
            cn = (ci + 1) % cross_n
            bm_hull.faces.new((rings[yi][ci], rings[yi][cn], rings[yi + 1][cn], rings[yi + 1][ci]))
    # Cap stern & bow cleanly
    c_stern = bm_hull.verts.new((0.0, y_stations[0], -0.15))
    c_bow = bm_hull.verts.new((0.0, y_stations[-1] + 0.22, 0.45))
    for ci in range(cross_n):
        cn = (ci + 1) % cross_n
        bm_hull.faces.new((c_stern, rings[0][cn], rings[0][ci]))
        bm_hull.faces.new((c_bow, rings[-1][ci], rings[-1][cn]))
    add_bm("AirshipHull", bm_hull, m_wood, smooth=True)

    # Dark wood trim gunwales & brass hull belt rails
    for sx in (-1.0, 1.0):
        rail_pts = [Vector((sx * (half_widths[i] + 0.04), y_stations[i], deck_zs[i] + 0.12)) for i in range(len(y_stations))]
        sweep_tube(f"GunwaleRail_{sx}", rail_pts, [0.11] * len(rail_pts), m_wood_dark, segs=8)
        brass_pts = [Vector((sx * (half_widths[i] + 0.06), y_stations[i], deck_zs[i] - 0.34)) for i in range(1, len(y_stations) - 1)]
        sweep_tube(f"HullBrassStripe_{sx}", brass_pts, [0.075] * len(brass_pts), m_brass, segs=8)

    # Ornate Golden Bow Bowsprit & Sun-Finial
    sweep_tube(
        "Bowsprit",
        [Vector((0, 4.6, 0.55)), Vector((0, 6.2, 1.05)), Vector((0, 7.2, 1.38))],
        [0.14, 0.09, 0.04],
        m_brass,
        segs=10,
    )

    # 2. Cozy Stern Captain's Cabin Deckhouse with Glowing Amber Portholes
    box("CabinBody", (2.35, 3.1, 1.45), m_wood_dark, loc=(0.0, -2.05, 0.85), bevel=0.06)
    box("CabinRoof", (2.68, 3.45, 0.22), m_crimson, loc=(0.0, -2.05, 1.66), bevel=0.06)
    box("CabinBrassTrim", (2.74, 3.50, 0.08), m_brass, loc=(0.0, -2.05, 1.56), bevel=0.02)
    # Warm glowing brass portholes on both sides + stern windows
    for sx in (-1.0, 1.0):
        for py in (-2.95, -2.05, -1.15):
            cyl(f"PortRim_{sx}_{py}", 0.26, 0.26, 0.14, 14, m_brass, loc=(sx * 1.18, py, 0.96), rot=(0, math.pi * 0.5, 0))
            cyl(f"PortGlow_{sx}_{py}", 0.19, 0.19, 0.17, 14, m_glow, loc=(sx * 1.19, py, 0.96), rot=(0, math.pi * 0.5, 0))
    for px in (-0.55, 0.55):
        cyl(f"SternRim_{px}", 0.26, 0.26, 0.14, 14, m_brass, loc=(px, -3.62, 0.96), rot=(math.pi * 0.5, 0, 0))
        cyl(f"SternGlow_{px}", 0.19, 0.19, 0.17, 14, m_glow, loc=(px, -3.63, 0.96), rot=(math.pi * 0.5, 0, 0))

    # Mid-deck wooden helm wheel & glowing bow lantern post
    cyl("HelmPedestal", 0.12, 0.16, 0.92, 10, m_brass, loc=(0.0, 0.35, 0.55))
    cyl("BowLanternPost", 0.06, 0.07, 1.35, 8, m_brass, loc=(0.0, 3.55, 0.95))
    cyl("BowLanternGlow", 0.20, 0.16, 0.36, 10, m_glow, loc=(0.0, 3.55, 1.65))

    # 3. Plump Quilted Dirigible Balloon Envelope overhead (centered at Z = +5.6m, length ~14.4m along Y!)
    bm_bal = bmesh.new()
    u_rings = 24
    v_segs = 28
    bal_rings = []
    for ui in range(1, u_rings):
        t = ui / u_rings  # 0..1 stern -> bow
        y = (t - 0.5) * 14.4
        # Teardrop classic airship envelope profile (fuller forward, sleek tapered stern)
        profile = math.sin(t * math.pi) ** 0.78
        if t > 0.5:
            profile *= 1.0 + 0.08 * math.sin((t - 0.5) * math.pi)
        r_base = 3.15 * profile
        ring = []
        for vi in range(v_segs):
            a = vi * math.tau / v_segs
            # Quilted longitudinal melon-gore puffiness!
            gore = 1.0 + 0.032 * abs(math.sin(a * 7.0))
            px = math.cos(a) * r_base * gore
            pz = 7.45 + math.sin(a) * r_base * 0.92 * gore
            ring.append(bm_bal.verts.new((px, y, pz)))
        bal_rings.append(ring)

    for ui in range(len(bal_rings) - 1):
        for vi in range(v_segs):
            vn = (vi + 1) % v_segs
            bm_bal.faces.new((bal_rings[ui][vi], bal_rings[ui][vn], bal_rings[ui + 1][vn], bal_rings[ui + 1][vi]))
    cap_s = bm_bal.verts.new((0.0, -7.25, 7.45))
    cap_b = bm_bal.verts.new((0.0, 7.25, 7.45))
    for vi in range(v_segs):
        vn = (vi + 1) % v_segs
        bm_bal.faces.new((cap_s, bal_rings[0][vn], bal_rings[0][vi]))
        bm_bal.faces.new((cap_b, bal_rings[-1][vi], bal_rings[-1][vn]))
    add_bm("BalloonEnvelope", bm_bal, m_cream, smooth=True)

    # Rich Crimson & Burnished Gold Decorative Solstice Belts circling the Balloon!
    for by, rad_b, width_b, mat_b in [
        (-2.6, 2.86, 0.78, m_crimson),
        (0.0, 3.24, 1.35, m_crimson),
        (2.8, 2.94, 0.78, m_crimson),
        (-2.15, 2.96, 0.14, m_brass),
        (-0.72, 3.27, 0.16, m_brass),
        (0.72, 3.28, 0.16, m_brass),
        (2.35, 3.04, 0.14, m_brass),
    ]:
        cyl(f"BalloonBand_{by}", rad_b, rad_b, width_b, 28, mat_b, loc=(0.0, by, 7.45), rot=(math.pi * 0.5, 0, 0), smooth=True)

    # Brass nose cone & stern cap on Balloon
    cyl("NoseCone", 0.65, 0.06, 0.72, 16, m_brass, loc=(0.0, 7.28, 7.45), rot=(-math.pi * 0.5, 0, 0))
    cyl("SternCap", 0.65, 0.08, 0.68, 16, m_brass, loc=(0.0, -7.25, 7.45), rot=(math.pi * 0.5, 0, 0))

    # Swept Crimson & Gold Tail Stabilizer Fins (top, bottom, port, starboard)
    box("FinTop", (0.16, 2.8, 1.95), m_crimson, loc=(0.0, -5.2, 9.4), rot=(0.24, 0.0, 0.0), bevel=0.04)
    box("FinPort", (2.1, 2.6, 0.14), m_crimson, loc=(-2.35, -5.1, 7.45), rot=(0.0, 0.0, 0.18), bevel=0.04)
    box("FinStbd", (2.1, 2.6, 0.14), m_crimson, loc=(2.35, -5.1, 7.45), rot=(0.0, 0.0, -0.18), bevel=0.04)
    box("RudderFin", (0.14, 1.6, 1.55), m_crimson, loc=(0.0, -4.95, 0.15), rot=(0.15, 0.0, 0.0), bevel=0.04)

    # Suspension Rigging Cables & Brass Struts connecting Balloon Envelope to Hull
    for sx in (-1.0, 1.0):
        for hy, by, bx_off in [(-3.0, -3.5, 2.45), (-0.8, -0.9, 2.88), (1.4, 1.6, 2.82), (3.1, 3.6, 2.38)]:
            sweep_tube(
                f"Rig_{sx}_{hy}",
                [Vector((sx * 1.52, hy, 0.45)), Vector((sx * bx_off, by, 5.95))],
                [0.045, 0.045],
                m_rope,
                segs=6,
            )

    # 4. Walkable Wooden Boarding Gangplank extending off the Starboard Side (+X toward Terrace!)
    box("GangplankDeck", (3.8, 1.45, 0.14), m_wood, loc=(3.2, 0.9, 0.04), rot=(0.0, 0.06, 0.0), bevel=0.025)
    for py in (0.24, 1.56):
        for gx in (1.75, 3.2, 4.65):
            cyl(f"PlankPost_{py}_{gx}", 0.045, 0.055, 0.72, 8, m_brass, loc=(gx, py, 0.40))
        sweep_tube(
            f"PlankRope_{py}",
            [Vector((1.75, py, 0.72)), Vector((3.2, py, 0.64)), Vector((4.65, py, 0.68))],
            [0.032, 0.032, 0.032],
            m_rope,
            segs=6,
        )

    # 5. Live Spinning Rear Brass Propeller under a named Empty Pivot (`PropellerPivot`)!
    prop_pivot = bpy.data.objects.new("PropellerPivot", None)
    bpy.context.collection.objects.link(prop_pivot)
    prop_pivot.location = (0.0, -4.62, -0.35)

    cyl("PropHub", 0.24, 0.14, 0.42, 12, m_brass, loc=(0.0, -0.10, 0.0), rot=(math.pi * 0.5, 0, 0), parent=prop_pivot)
    for bi in range(4):
        ang = bi * math.pi * 0.5
        bx = math.cos(ang) * 0.72
        bz = math.sin(ang) * 0.72
        box(
            f"PropBlade_{bi}",
            (1.18, 0.07, 0.24),
            m_brass,
            loc=(bx, -0.14, bz),
            rot=(0.35, ang, 0.0),
            bevel=0.015,
            parent=prop_pivot,
        )

    bpy.ops.export_scene.gltf(filepath=OUT_PATH, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[gen_airship] Exported {OUT_PATH}")


if __name__ == "__main__":
    build_airship()
