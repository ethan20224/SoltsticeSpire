"""
Blender 5.2.1 LTS Environmental Storytelling Scenery Generator (AAA Sculpted Polish)
Exports to assets/models/scenery/:
  1. cloud_puff.glb             - Fluffy multi-lobe Ghibli stylized cumulus cloud cluster
  2. floating_spire_rock.glb    - Organic sculpted multi-tiered mossy cliff rock + weathered fluted ruin columns + hanging ivy
  3. lantern_garland.glb        - Graceful curved cord of 5 glowing festival paper lanterns (World 3)
  4. hanging_chain_bell.glb     - Dramatic suspended vertical brass foundry chain & ornament (World 2)

NOTE: garden_tree.glb is owned exclusively by gen_detail_props.py (with alpha-scissor LeafCards) and is NOT exported here!
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector

OUT_DIR = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/scenery"
os.makedirs(OUT_DIR, exist_ok=True)


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, col, rough=0.55, metal=0.0, em=None, em_s=0.0, coat=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*col, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if coat > 0.0 and "Coat Weight" in b.inputs:
        b.inputs["Coat Weight"].default_value = coat
    if em and em_s > 0.0:
        b.inputs["Emission Color"].default_value = (*em, 1.0)
        b.inputs["Emission Strength"].default_value = em_s
    return m


def add_bm(name, bm, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True, subsurf=0, bevel=0.0):
    mesh = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = rot
    obj.data.materials.append(m)
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    if bevel > 0.0:
        bv = obj.modifiers.new("Bevel", "BEVEL")
        bv.width = bevel
        bv.segments = 2
        bv.limit_method = "ANGLE"
        bv.angle_limit = math.radians(32)
    if subsurf > 0:
        sb = obj.modifiers.new("Subsurf", "SUBSURF")
        sb.levels = subsurf
        sb.render_levels = subsurf
    return obj


def sphere(name, radii, m, loc=(0, 0, 0), rot=(0, 0, 0), u=14, v=10, subsurf=1):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=radii, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=True, subsurf=subsurf)


def cyl(name, r1, r2, h, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.03):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel)


def sweep_tube(name, points, radii, m, segs=6, cap=True):
    bm = bmesh.new()
    rings = []
    n = len(points)
    prev_up = Vector((0, 0, 1))
    for i, pt in enumerate(points):
        if i == 0:
            tangent = (points[1] - points[0]).normalized()
        elif i == n - 1:
            tangent = (points[-1] - points[-2]).normalized()
        else:
            tangent = (points[i + 1] - points[i - 1]).normalized()
        if abs(tangent.dot(prev_up)) > 0.94:
            prev_up = Vector((1, 0, 0)) if abs(tangent.x) < 0.8 else Vector((0, 1, 0))
        side = tangent.cross(prev_up).normalized()
        up = side.cross(tangent).normalized()
        prev_up = up
        r = radii[i]
        ring = []
        for s in range(segs):
            a = 2.0 * math.pi * s / segs
            ring.append(bm.verts.new(pt + (side * math.cos(a) + up * math.sin(a)) * r))
        rings.append(ring)
    for i in range(n - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            bm.faces.new((rings[i][s], rings[i][sn], rings[i + 1][sn], rings[i + 1][s]))
    if cap:
        c0 = bm.verts.new(points[0])
        c1 = bm.verts.new(points[-1])
        for s in range(segs):
            sn = (s + 1) % segs
            bm.faces.new((c0, rings[0][sn], rings[0][s]))
            bm.faces.new((c1, rings[-1][s], rings[-1][sn]))
    return add_bm(name, bm, m, smooth=True, bevel=0.0)


def join_by_material():
    by_mat = {}
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and len(obj.data.materials) == 1 and obj.data.materials[0] is not None:
            mname = obj.data.materials[0].name
            by_mat.setdefault(mname, []).append(obj)
    for _, objs in by_mat.items():
        if len(objs) <= 1:
            continue
        for o in objs:
            if o.modifiers:
                bpy.ops.object.select_all(action="DESELECT")
                o.select_set(True)
                bpy.context.view_layer.objects.active = o
                for mod in list(o.modifiers):
                    bpy.ops.object.modifier_apply(modifier=mod.name)
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.object.join()


def save(fname):
    join_by_material()
    p = os.path.join(OUT_DIR, fname)
    bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[gen_scenery] Exported {p}")


def build_cloud_puff():
    clear()
    m_cloud = mat("CloudCream", (0.86, 0.88, 0.92), rough=0.88)
    puffs = [
        ((0.0, 0.0, 0.4), (3.4, 2.4, 1.5)),
        ((-2.4, 0.4, 0.1), (2.4, 1.9, 1.15)),
        ((2.5, -0.3, 0.15), (2.6, 2.0, 1.25)),
        ((-1.1, -1.2, 0.65), (2.1, 1.8, 1.35)),
        ((1.2, 1.0, 0.75), (2.2, 1.7, 1.45)),
        ((0.1, 0.1, 1.25), (1.9, 1.6, 1.30)),
        ((-3.9, -0.2, -0.15), (1.5, 1.3, 0.75)),
        ((4.1, 0.2, -0.1), (1.6, 1.3, 0.80)),
    ]
    for i, (loc, rad) in enumerate(puffs):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=10, radius=1.0)
        for v in bm.verts:
            if v.co.z < -0.15:
                v.co.z = -0.15 + (v.co.z + 0.15) * 0.28
            v.co.x *= rad[0]
            v.co.y *= rad[1]
            v.co.z *= rad[2]
        add_bm(f"Puff{i}", bm, m_cloud, loc=loc, smooth=True, subsurf=1)
    save("cloud_puff.glb")


def build_floating_spire_rock():
    """Organic sculpted multi-tiered mossy cliff rock + stepped stone strata + weathered fluted ruin columns + hanging ivy."""
    clear()
    m_stone = mat("IsletStone", (0.60, 0.54, 0.44), rough=0.72)
    m_slate = mat("IsletTerraStrata", (0.48, 0.34, 0.24), rough=0.76)
    m_moss = mat("IsletMoss", (0.14, 0.44, 0.18), rough=0.88)
    m_ivy = mat("IsletIvy", (0.18, 0.50, 0.20), rough=0.86)

    def displaced_rock_tier(name, radii, z_center, m_r, seed=1, flat_top=False):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
        for v in bm.verts:
            p = v.co
            ang = math.atan2(p.y, p.x)
            n1 = 0.22 * math.sin(ang * 3.0 + seed * 1.3) * math.cos(p.z * 2.5)
            n2 = 0.14 * math.cos(ang * 5.0 - seed * 2.1 + p.z * 4.0)
            n3 = 0.08 * math.sin((p.x - p.y) * 4.5 + seed)
            disp = 1.0 + n1 + n2 + n3
            vx = p.x * radii[0] * disp
            vy = p.y * radii[1] * disp
            vz = p.z * radii[2]
            if flat_top and vz > 0.10:
                vz = 0.10 + (vz - 0.10) * 0.25
            v.co = Vector((vx, vy, vz + z_center))
        return add_bm(name, bm, m_r, smooth=False, bevel=0.04)

    # Multi-tiered stepped rocky cliff strata (replacing upside-down pyramid cone!)
    displaced_rock_tier("StrataTop", (2.95, 2.75, 0.72), -0.35, m_stone, seed=1, flat_top=True)
    displaced_rock_tier("StrataUpperCrag", (2.55, 2.35, 0.95), -1.25, m_slate, seed=3)
    displaced_rock_tier("StrataMidLedge", (2.05, 1.90, 1.15), -2.45, m_stone, seed=7)
    displaced_rock_tier("StrataLowerCrag", (1.35, 1.25, 1.35), -3.85, m_slate, seed=11)
    displaced_rock_tier("StrataKeelTip", (0.72, 0.68, 1.25), -5.35, m_stone, seed=17)
    # Side cantilevered rock shelf for dramatic asymmetric Ghibli cliff silhouette
    displaced_rock_tier("SideShelfCrag", (1.45, 1.15, 0.75), -1.65, m_stone, seed=23)
    bpy.data.objects["SideShelfCrag"].location = (1.55, 0.45, 0.0)

    # Lush mossy crown overhang pillows
    for i in range(9):
        a = i * math.tau / 9.0
        r_m = 2.15 + 0.45 * math.sin(i * 1.9)
        sphere(f"MossCrown_{i}", (0.85, 0.78, 0.28), m_moss,
               loc=(r_m * math.cos(a) * 0.75, r_m * math.sin(a) * 0.75, -0.02),
               rot=(0.08 * math.sin(a), -0.08 * math.cos(a), a), u=10, v=7)
    sphere("MossCenterCap", (2.15, 1.95, 0.26), m_moss, loc=(0, 0, -0.04), u=12, v=8)

    # Weathered fluted ruin columns & fallen stone arch block on crown
    for col_name, cx, cy, h_col, tilt in [("RuinColA", -0.88, 0.52, 2.35, 0.05), ("RuinColB", 0.92, -0.45, 1.48, -0.07)]:
        cyl(f"{col_name}_Base", 0.42, 0.36, 0.22, 8, m_stone, loc=(cx, cy, 0.11), bevel=0.03)
        cyl(f"{col_name}_Shaft", 0.30, 0.26, h_col, 12, m_stone, loc=(cx, cy, 0.22 + h_col * 0.5), rot=(tilt, tilt * 0.6, 0), bevel=0.025)
        for fi in range(6):
            fa = fi * math.tau / 6.0
            cyl(f"{col_name}_Flute{fi}", 0.06, 0.05, h_col * 0.88, 6, m_slate,
                loc=(cx + 0.25 * math.cos(fa), cy + 0.25 * math.sin(fa), 0.22 + h_col * 0.5),
                rot=(tilt, tilt * 0.6, 0), bevel=0.01)
    cyl("RuinCapA", 0.28, 0.40, 0.28, 8, m_stone, loc=(-0.82, 0.55, 2.65), rot=(0.14, -0.10, 0), bevel=0.03)

    # Hanging ivy vine clusters trailing down from the mossy overhang
    for i in range(6):
        a = i * math.tau / 6.0 + 0.35
        ca, sa = math.cos(a), math.sin(a)
        vlen = 1.65 + (i % 3) * 0.65
        pts = [
            Vector((2.65 * ca, 2.45 * sa, -0.15)),
            Vector((2.75 * ca + 0.14 * sa, 2.55 * sa - 0.14 * ca, -0.15 - vlen * 0.45)),
            Vector((2.45 * ca - 0.10 * sa, 2.25 * sa + 0.10 * ca, -0.15 - vlen)),
        ]
        sweep_tube(f"IvyVine_{i}", pts, [0.055, 0.038, 0.018], m_ivy, segs=6)
        for li in range(4):
            lt = (li + 0.6) / 4.5
            lp = pts[0].lerp(pts[2], lt)
            sphere(f"IvyLeafCluster_{i}_{li}", (0.20, 0.14, 0.08), m_ivy,
                   loc=(lp.x, lp.y, lp.z), rot=(0.25, 0.35, a + li), u=8, v=6)
    save("floating_spire_rock.glb")


def build_lantern_garland():
    clear()
    m_cord = mat("CordDark", (0.12, 0.08, 0.08), rough=0.6)
    m_glow = mat("GarlandGlow", (0.98, 0.58, 0.14), rough=0.25, em=(1.0, 0.58, 0.14), em_s=2.4)
    m_cap = mat("GarlandCap", (0.16, 0.09, 0.08), rough=0.45)

    for i in range(5):
        t = (i / 4.0) * 2.0 - 1.0
        x = t * 5.2
        z = -1.6 * (1.0 - t * t)
        cyl(f"Lantern{i}", 0.42, 0.36, 0.92, 10, m_glow, loc=(x, 0, z - 0.6), bevel=0.04)
        cyl(f"CapT{i}", 0.48, 0.28, 0.16, 10, m_cap, loc=(x, 0, z - 0.08), bevel=0.02)
        cyl(f"CapB{i}", 0.28, 0.44, 0.14, 10, m_cap, loc=(x, 0, z - 1.12), bevel=0.02)
    for i in range(8):
        t0 = (i / 8.0) * 2.0 - 1.0
        t1 = ((i + 1) / 8.0) * 2.0 - 1.0
        tm = 0.5 * (t0 + t1)
        x = tm * 5.6
        z = -1.6 * (1.0 - tm * tm)
        slope = math.atan2(3.2 * tm, 5.6)
        cyl(f"Cord{i}", 0.04, 0.04, 1.5, 6, m_cord, loc=(x, 0, z), rot=(0, math.radians(90) - slope, 0), bevel=0.0)
    save("lantern_garland.glb")


def build_hanging_chain_bell():
    clear()
    m_iron = mat("ChainIron", (0.14, 0.12, 0.16), rough=0.42, metal=0.82)
    m_brass = mat("ChainBrass", (0.68, 0.44, 0.14), rough=0.28, metal=0.88)
    for i in range(12):
        cyl(f"Link{i}", 0.24, 0.24, 1.05, 8, m_iron, loc=(0, 0, -i * 0.82),
            rot=(0, 0, math.radians(90 if i % 2 else 0)), bevel=0.05)
    cyl("BellCollar", 0.65, 0.45, 0.45, 12, m_brass, loc=(0, 0, -9.85), smooth=True, bevel=0.04)
    cyl("WeightBell", 1.38, 0.52, 1.95, 16, m_brass, loc=(0, 0, -10.95), smooth=True, bevel=0.06)
    save("hanging_chain_bell.glb")


if __name__ == "__main__":
    build_cloud_puff()
    build_floating_spire_rock()
    build_lantern_garland()
    build_hanging_chain_bell()
    print("[gen_scenery] Environmental storytelling scenery assets generated (garden_tree.glb preserved for gen_detail_props.py)!")
