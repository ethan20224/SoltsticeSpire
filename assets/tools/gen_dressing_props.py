"""
Blender 5.2.1 LTS Route Set-Dressing & MultiMesh Detail Props Generator (AAA Sculpted Polish)
Exports to assets/models/dressing/:
  - grass_tuft.glb (9 curved tapered grass blades + 2 tiny white-and-gold wildflowers in ONE unified mesh!)
  - wildflower_cluster.glb (colorful daisy/buttercup/clover lawn patch)
  - mossy_stone.glb (organic sculpted rounded mossy garden boulder)
  - w1_garden_cluster.glb
  - w2_forge_cluster.glb
  - w3_monsoon_cluster.glb
  - w4_gallery_cluster.glb
  - w5_reading_cluster.glb
  - w6_solar_brazier.glb (sculpted tripod gilded-bronze solar fire bowl with glowing flame core)
  - lantern_unit.glb
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector

OUT_DIR = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/dressing"
os.makedirs(OUT_DIR, exist_ok=True)


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, col, rough=0.55, metal=0.0, em=None, em_s=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*col, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if em and em_s > 0.0:
        b.inputs["Emission Color"].default_value = (*em, 1.0)
        b.inputs["Emission Strength"].default_value = em_s
    return m


def add_bm(name, bm, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True, bevel=0.0):
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
        bv.segments = 1
        bv.limit_method = "ANGLE"
        bv.angle_limit = math.radians(35)
    return obj


def box(name, sz, m, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.02):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=sz, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=False, bevel=bevel)


def cyl(name, r1, r2, h, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True, bevel=0.015):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel)


def sphere(name, rad, m, loc=(0, 0, 0), rot=(0, 0, 0), u=10, v=7):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=rad, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=True)


def torus(name, R, r, maj_s, min_s, m, loc=(0, 0, 0), rot=(0, 0, 0)):
    bm = bmesh.new()
    rings = []
    for i in range(maj_s):
        t = 2.0 * math.pi * i / maj_s
        ring = []
        for j in range(min_s):
            p = 2.0 * math.pi * j / min_s
            rad = R + r * math.cos(p)
            ring.append(bm.verts.new((rad * math.cos(t), rad * math.sin(t), r * math.sin(p))))
        rings.append(ring)
    for i in range(maj_s):
        inext = (i + 1) % maj_s
        for j in range(min_s):
            jnext = (j + 1) % min_s
            bm.faces.new((rings[i][j], rings[inext][j], rings[inext][jnext], rings[i][jnext]))
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=True)


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
    return add_bm(name, bm, m, smooth=True)


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


def join_all_into_single_mesh(name="UnifiedMesh"):
    objs = [o for o in bpy.data.objects if o.type == "MESH"]
    if len(objs) <= 1:
        return
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
    objs[0].name = name


def save(fname, merge_all=False):
    if merge_all:
        join_all_into_single_mesh()
    else:
        join_by_material()
    p = os.path.join(OUT_DIR, fname)
    bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[gen_dressing_props] Exported {p}")


def _add_curved_grass_blades(bm, count, r_spread=0.07, h_min=0.26, h_max=0.44, lean_min=0.10, lean_max=0.22):
    for i in range(count):
        a = i * math.tau / count + (0.24 if i % 2 else -0.08)
        ca, sa = math.cos(a), math.sin(a)
        px, py = -sa, ca
        t = (i % 3) / 2.0
        h = h_min + (h_max - h_min) * t
        lean = lean_min + (lean_max - lean_min) * ((i % 2) * 0.6 + 0.4 * t)
        w0 = 0.036
        r0 = r_spread * (0.4 + 0.6 * ((i * 3) % 4) / 3.0)
        # 3-segment curved blade tapering cleanly to a pointed tip
        p0 = Vector((ca * r0, sa * r0, 0.0))
        p1 = Vector((ca * (r0 + lean * 0.25), sa * (r0 + lean * 0.25), h * 0.38))
        p2 = Vector((ca * (r0 + lean * 0.68), sa * (r0 + lean * 0.68), h * 0.74))
        p3 = Vector((ca * (r0 + lean), sa * (r0 + lean), h))
        side = Vector((px, py, 0.0))
        v0l, v0r = bm.verts.new(p0 - side * w0), bm.verts.new(p0 + side * w0)
        v1l, v1r = bm.verts.new(p1 - side * (w0 * 0.80)), bm.verts.new(p1 + side * (w0 * 0.80))
        v2l, v2r = bm.verts.new(p2 - side * (w0 * 0.46)), bm.verts.new(p2 + side * (w0 * 0.46))
        v3 = bm.verts.new(p3)
        bm.faces.new((v0l, v0r, v1r, v1l))
        bm.faces.new((v1l, v1r, v2r, v2l))
        bm.faces.new((v2l, v2r, v3))


def build_grass_tuft():
    """Rich multi-blade curved cluster of 9 tapered grass blades + 2 tiny white-and-gold wildflowers in ONE unified mesh."""
    clear()
    m_grass = mat("TuftGrass", (0.20, 0.54, 0.20), rough=0.90)
    m_petal = mat("TuftFlowerWhite", (0.98, 0.96, 0.90), rough=0.62)
    m_gold = mat("TuftFlowerGold", (1.0, 0.82, 0.22), rough=0.48)

    bm = bmesh.new()
    _add_curved_grass_blades(bm, count=9, r_spread=0.06, h_min=0.25, h_max=0.44, lean_min=0.10, lean_max=0.22)
    add_bm("GrassBlades", bm, m_grass, smooth=True)

    # 2 Tiny white-and-gold wildflowers nestled among the 9 blades!
    for fi, (fx, fy, fz, tilt_x, tilt_y) in enumerate([
        (0.06, 0.04, 0.30, 0.24, -0.18),
        (-0.07, -0.04, 0.24, -0.22, 0.20),
    ]):
        stem_pts = [Vector((fx * 0.4, fy * 0.4, 0.0)), Vector((fx * 0.75, fy * 0.75, fz * 0.55)), Vector((fx, fy, fz))]
        sweep_tube(f"FlowerStem_{fi}", stem_pts, [0.012, 0.010, 0.008], m_grass, segs=5)
        sphere(f"FlowerCenter_{fi}", (0.026, 0.026, 0.018), m_gold, loc=(fx, fy, fz + 0.01), rot=(tilt_x, tilt_y, 0), u=8, v=5)
        for pi in range(5):
            pa = pi * math.tau / 5.0 + fi * 0.5
            sphere(f"FlowerPetal_{fi}_{pi}", (0.028, 0.016, 0.010), m_petal,
                   loc=(fx + 0.036 * math.cos(pa), fy + 0.036 * math.sin(pa), fz + 0.004),
                   rot=(tilt_x, tilt_y, pa), u=6, v=4)
    # Merge all into ONE mesh so WorldHelper._extract_first_mesh captures ALL 9 blades + 2 flowers!
    save("grass_tuft.glb", merge_all=True)


def build_wildflower_cluster():
    """Colorful tiny daisy, buttercup & 3-leaf clover patch for lawn dressing."""
    clear()
    m_clover = mat("PatchCloverLeaf", (0.16, 0.50, 0.18), rough=0.88)
    m_grass = mat("PatchGrass", (0.22, 0.56, 0.22), rough=0.88)
    m_white = mat("PatchDaisyWhite", (0.98, 0.96, 0.90), rough=0.58)
    m_gold = mat("PatchButtercupGold", (1.0, 0.80, 0.20), rough=0.45)
    m_coral = mat("PatchPinkBloom", (0.98, 0.52, 0.62), rough=0.52)

    bm_g = bmesh.new()
    _add_curved_grass_blades(bm_g, count=8, r_spread=0.14, h_min=0.18, h_max=0.34, lean_min=0.08, lean_max=0.18)
    add_bm("PatchGrassSprigs", bm_g, m_grass, smooth=True)

    # 4 Three-leaf clover rosettes nestled low on the turf
    for ci, (cx, cy, rot_z) in enumerate([(-0.14, 0.12, 0.2), (0.16, -0.10, 1.1), (-0.08, -0.16, 2.3), (0.12, 0.16, 0.7)]):
        for li in range(3):
            la = rot_z + li * math.tau / 3.0
            sphere(f"CloverLobe_{ci}_{li}", (0.048, 0.040, 0.014), m_clover,
                   loc=(cx + 0.042 * math.cos(la), cy + 0.042 * math.sin(la), 0.035),
                   rot=(0.15, 0, la), u=8, v=5)

    # Colorful tiny daisies, golden buttercups & coral blossoms
    blooms = [
        ((0.02, 0.03, 0.30), m_white, m_gold, 6, 0.045),
        ((-0.14, 0.06, 0.24), m_gold, m_coral, 5, 0.036),
        ((0.15, 0.08, 0.26), m_coral, m_gold, 5, 0.038),
        ((-0.05, -0.14, 0.22), m_white, m_gold, 6, 0.036),
        ((0.11, -0.13, 0.20), m_gold, m_gold, 5, 0.032),
    ]
    for bi, ((bx, by, bz), m_pet, m_ctr, n_pet, p_rad) in enumerate(blooms):
        s_pts = [Vector((bx * 0.5, by * 0.5, 0.0)), Vector((bx, by, bz))]
        sweep_tube(f"BloomStem_{bi}", s_pts, [0.012, 0.008], m_grass, segs=5)
        sphere(f"BloomCtr_{bi}", (p_rad * 0.55, p_rad * 0.55, p_rad * 0.35), m_ctr, loc=(bx, by, bz + 0.008), u=8, v=5)
        for pi in range(n_pet):
            pa = pi * math.tau / n_pet + bi * 0.4
            sphere(f"BloomPet_{bi}_{pi}", (p_rad * 0.72, p_rad * 0.42, p_rad * 0.22), m_pet,
                   loc=(bx + p_rad * 0.85 * math.cos(pa), by + p_rad * 0.85 * math.sin(pa), bz),
                   rot=(0.12, 0, pa), u=6, v=4)
    save("wildflower_cluster.glb")


def build_mossy_stone():
    """Organic sculpted rounded mossy garden boulder + companion pebble & moss blanket."""
    clear()
    m_stone = mat("BoulderStone", (0.64, 0.60, 0.52), rough=0.76)
    m_moss = mat("BoulderMoss", (0.16, 0.48, 0.18), rough=0.90)
    m_flower = mat("BoulderFlower", (1.0, 0.84, 0.30), rough=0.52)

    def rounded_boulder(name, radii, loc, seed):
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
        for v in bm.verts:
            p = v.co
            wobble = 1.0 + 0.14 * math.sin(p.x * 3.5 + seed) * math.cos(p.y * 3.2 - seed) + 0.08 * math.cos(p.z * 4.0 + seed)
            v.co.x = p.x * radii[0] * wobble
            v.co.y = p.y * radii[1] * wobble
            # Soft flat base so boulder sits naturally in turf
            z_raw = p.z * radii[2] * wobble
            v.co.z = max(z_raw, -radii[2] * 0.35) + radii[2] * 0.35
        return add_bm(name, bm, m_stone, loc=loc, smooth=True)

    rounded_boulder("MainBoulder", (0.62, 0.50, 0.42), (0.0, 0.0, 0.0), seed=4)
    rounded_boulder("SideStone", (0.34, 0.28, 0.24), (0.48, -0.22, 0.0), seed=9)
    # Velvet moss cap & side moss cushions draped over the boulder top
    moss_caps = [
        ((0.02, 0.02, 0.38), (0.48, 0.38, 0.14)),
        ((-0.24, 0.12, 0.30), (0.28, 0.24, 0.11)),
        ((0.22, -0.10, 0.28), (0.26, 0.22, 0.10)),
        ((0.46, -0.20, 0.22), (0.22, 0.18, 0.08)),
    ]
    for mi, (mloc, mrad) in enumerate(moss_caps):
        sphere(f"MossCap_{mi}", mrad, m_moss, loc=mloc, u=12, v=8)
    for fi, fp in enumerate([(-0.12, 0.18, 0.46), (0.14, -0.05, 0.45)]):
        sphere(f"MossBloom_{fi}", (0.045, 0.045, 0.028), m_flower, loc=fp, u=7, v=5)
    save("mossy_stone.glb")


def build_w1_garden_cluster():
    clear()
    m_terra = mat("ClustTerra", (0.58, 0.22, 0.12), rough=0.56)
    m_stone = mat("ClustStone", (0.70, 0.64, 0.54), rough=0.68)
    m_leaf = mat("ClustLeaf", (0.16, 0.48, 0.20), rough=0.88)
    m_bloom = mat("ClustBloom", (0.98, 0.68, 0.36), rough=0.52)
    m_glow = mat("ClustLanternGlow", (1.0, 0.74, 0.34), rough=0.14, em=(1.0, 0.70, 0.28), em_s=3.0)

    box("FlowerBox", (1.35, 0.55, 0.48), m_terra, loc=(0, 0, 0.24))
    for i in range(4):
        x = -0.45 + i * 0.30
        sphere(f"Bush_{i}", (0.24, 0.22, 0.20), m_leaf, loc=(x, 0.0, 0.56))
        sphere(f"Flower_{i}", (0.09, 0.09, 0.08), m_bloom, loc=(x + 0.04, 0.06, 0.72), u=7, v=5)
    cyl("LanternBase", 0.24, 0.16, 0.55, 8, m_stone, loc=(0.95, 0.05, 0.275), smooth=False)
    cyl("LanternCore", 0.14, 0.14, 0.28, 8, m_glow, loc=(0.95, 0.05, 0.68), smooth=False)
    cyl("LanternRoof", 0.34, 0.05, 0.24, 8, m_stone, loc=(0.95, 0.05, 0.92), smooth=False)
    save("w1_garden_cluster.glb")


def build_w2_forge_cluster():
    clear()
    m_copper = mat("ForgeCopper", (0.72, 0.36, 0.18), rough=0.34, metal=0.86)
    m_brass = mat("ForgeBrass", (0.86, 0.62, 0.22), rough=0.26, metal=0.90)
    m_iron = mat("ForgeIron", (0.18, 0.16, 0.20), rough=0.45, metal=0.78)
    m_banner = mat("ForgeBanner", (0.68, 0.16, 0.14), rough=0.75)
    m_ember = mat("ForgeEmberGlow", (1.0, 0.58, 0.16), rough=0.14, em=(1.0, 0.52, 0.12), em_s=3.4)

    cyl("Barrel", 0.36, 0.36, 0.85, 10, m_copper, loc=(-0.45, 0.0, 0.425))
    cyl("BarrelBand", 0.39, 0.39, 0.12, 10, m_brass, loc=(-0.45, 0.0, 0.62))
    cyl("BrazierStand", 0.26, 0.18, 0.68, 6, m_iron, loc=(0.45, 0.08, 0.34), smooth=False)
    cyl("BrazierBowl", 0.20, 0.38, 0.26, 8, m_brass, loc=(0.45, 0.08, 0.74))
    sphere("Embers", (0.28, 0.28, 0.18), m_ember, loc=(0.45, 0.08, 0.88))
    cyl("Pole", 0.05, 0.04, 2.8, 8, m_brass, loc=(-0.05, -0.25, 1.40))
    box("Crossbar", (0.85, 0.06, 0.06), m_brass, loc=(-0.05, -0.25, 2.55), bevel=0.008)
    box("Pennant", (0.72, 0.04, 1.45), m_banner, loc=(-0.05, -0.25, 1.80), bevel=0.006)
    save("w2_forge_cluster.glb")


def build_w3_monsoon_cluster():
    clear()
    m_wood = mat("MonWood", (0.24, 0.14, 0.10), rough=0.52)
    m_red = mat("MonRed", (0.74, 0.16, 0.14), rough=0.40)
    m_gold = mat("MonGold", (0.90, 0.70, 0.26), rough=0.26, metal=0.86)
    m_glow = mat("MonShojiGlow", (1.0, 0.66, 0.30), rough=0.22, em=(1.0, 0.62, 0.24), em_s=1.70)

    cyl("StandBase", 0.28, 0.18, 0.72, 8, m_wood, loc=(0.35, 0.0, 0.36), smooth=False)
    box("ShojiLamp", (0.38, 0.38, 0.52), m_glow, loc=(0.35, 0.0, 0.96), bevel=0.015)
    for side_a in (0.0, math.pi * 0.5):
        box(f"LampBar_{side_a}", (0.42, 0.42, 0.05), m_wood, loc=(0.35, 0.0, 0.96), rot=(0, 0, side_a), bevel=0.005)
    cyl("ShojiRoof", 0.48, 0.08, 0.26, 4, m_red, loc=(0.35, 0.0, 1.34), rot=(0, 0, math.pi * 0.25), smooth=False)
    cyl("RainBarrel", 0.34, 0.38, 0.65, 10, m_wood, loc=(-0.48, 0.10, 0.325))
    cyl("BannerPole", 0.045, 0.035, 2.6, 8, m_red, loc=(-0.10, -0.22, 1.30))
    box("WindBanner", (0.58, 0.04, 1.30), m_red, loc=(-0.10, -0.22, 1.75), bevel=0.005)
    box("BannerTrim", (0.60, 0.05, 0.12), m_gold, loc=(-0.10, -0.22, 1.12), bevel=0.005)
    save("w3_monsoon_cluster.glb")


def build_w4_gallery_cluster():
    clear()
    m_gold = mat("GalGold", (0.92, 0.72, 0.28), rough=0.22, metal=0.90)
    m_glass = mat("GalGlass", (0.76, 0.86, 1.0), rough=0.08, metal=0.55)
    m_crystal = mat("GalCrystal", (0.82, 0.66, 1.0), rough=0.10, em=(0.62, 0.42, 0.96), em_s=1.1)
    m_wax = mat("GalCandleWax", (0.90, 0.78, 0.56), rough=0.45)
    m_flame = mat("GalCandleGlow", (1.0, 0.66, 0.24), rough=0.10, em=(1.0, 0.62, 0.20), em_s=1.95)

    box("MirFrame", (0.88, 0.12, 1.75), m_gold, loc=(-0.38, 0.0, 0.95), rot=(0.08, 0, 0.15))
    box("MirGlass", (0.70, 0.14, 1.54), m_glass, loc=(-0.38, 0.0, 0.95), rot=(0.08, 0, 0.15), bevel=0.005)
    cyl("CandStand", 0.24, 0.06, 1.15, 8, m_gold, loc=(0.45, 0.05, 0.575))
    box("CandCross", (0.68, 0.07, 0.07), m_gold, loc=(0.45, 0.05, 1.12), bevel=0.01)
    for dx in (-0.28, 0.0, 0.28):
        cyl(f"Wax_{dx}", 0.045, 0.042, 0.22, 8, m_wax, loc=(0.45 + dx, 0.05, 1.24))
        sphere(f"Flame_{dx}", (0.04, 0.04, 0.09), m_flame, loc=(0.45 + dx, 0.05, 1.40))
    cyl("CryA", 0.22, 0.03, 0.85, 6, m_crystal, loc=(0.05, -0.32, 0.42), rot=(0.12, -0.18, 0), smooth=False)
    cyl("CryB", 0.16, 0.02, 0.58, 6, m_crystal, loc=(-0.14, -0.36, 0.28), rot=(-0.15, 0.22, 0), smooth=False)
    save("w4_gallery_cluster.glb")


def build_w5_reading_cluster():
    clear()
    m_wood = mat("ReadWood", (0.24, 0.14, 0.12), rough=0.45)
    m_brass = mat("ReadBrass", (0.88, 0.68, 0.26), rough=0.24, metal=0.90)
    m_b1 = mat("ReadBookRed", (0.66, 0.18, 0.22), rough=0.56)
    m_b2 = mat("ReadBookTeal", (0.16, 0.48, 0.54), rough=0.56)
    m_b3 = mat("ReadBookIndigo", (0.22, 0.24, 0.52), rough=0.56)
    m_glow = mat("ReadLampGlow", (0.98, 0.64, 0.26), rough=0.22, em=(0.98, 0.60, 0.22), em_s=1.65)

    for i, (m_b, rot_z) in enumerate([(m_b1, 0.12), (m_b2, -0.22), (m_b3, 0.35), (m_b1, -0.10), (m_b2, 0.28)]):
        box(f"Book_{i}", (0.62 - i * 0.04, 0.46 - i * 0.02, 0.14), m_b,
            loc=(-0.42, 0.05, 0.07 + i * 0.145), rot=(0, 0, rot_z), bevel=0.012)
    cyl("LampBase", 0.24, 0.14, 0.12, 10, m_brass, loc=(0.40, 0.0, 0.06))
    cyl("LampStem", 0.045, 0.038, 1.75, 8, m_brass, loc=(0.40, 0.0, 0.94))
    cyl("LampShade", 0.34, 0.18, 0.36, 16, m_glow, loc=(0.40, 0.0, 1.86))
    cyl("LampRimBot", 0.35, 0.35, 0.04, 16, m_brass, loc=(0.40, 0.0, 1.68))
    cyl("LampCap", 0.22, 0.04, 0.12, 16, m_brass, loc=(0.40, 0.0, 2.08))
    cyl("Stool", 0.26, 0.28, 0.52, 8, m_wood, loc=(0.0, -0.35, 0.26))
    sphere("Globe", (0.22, 0.22, 0.22), m_b2, loc=(0.0, -0.35, 0.78))
    save("w5_reading_cluster.glb")


def build_w6_solar_brazier():
    """Sculpted tripod gilded-bronze solar fire bowl with glowing flame core!"""
    clear()
    m_obs = mat("BrazObs", (0.09, 0.08, 0.15), rough=0.22, metal=0.42)
    m_bronze = mat("BrazBronze", (0.86, 0.62, 0.22), rough=0.22, metal=0.92)
    m_flame = mat("BrazFlameGlow", (1.0, 0.62, 0.18), rough=0.12, em=(1.0, 0.58, 0.16), em_s=2.1)

    # Central obsidian plinth ring & mid collar joining the 3 sculpted tripod legs
    cyl("CenterHub", 0.18, 0.22, 0.24, 12, m_obs, loc=(0, 0, 0.56), bevel=0.02)
    torus("HubRing", 0.23, 0.04, 18, 6, m_bronze, loc=(0, 0, 0.56))
    torus("BaseRing", 0.42, 0.035, 24, 6, m_bronze, loc=(0, 0, 0.10))

    # 3 Sculpted curved tripod bronze legs with lion-paw foot pads
    for i in range(3):
        a = i * math.tau / 3.0
        ca, sa = math.cos(a), math.sin(a)
        leg_pts = [
            Vector((0.48 * ca, 0.48 * sa, 0.04)),
            Vector((0.38 * ca, 0.38 * sa, 0.34)),
            Vector((0.20 * ca, 0.20 * sa, 0.58)),
            Vector((0.24 * ca, 0.24 * sa, 0.92)),
        ]
        sweep_tube(f"TripodLeg_{i}", leg_pts, [0.065, 0.052, 0.058, 0.048], m_bronze, segs=8)
        sphere(f"TripodPaw_{i}", (0.09, 0.07, 0.05), m_bronze, loc=(0.49 * ca, 0.49 * sa, 0.04), rot=(0, 0, a), u=8, v=6)

    # Scalloped gilded-bronze solar fire bowl + flared sun-ray rim points
    cyl("BowlFoot", 0.26, 0.18, 0.16, 12, m_obs, loc=(0, 0, 0.92), bevel=0.02)
    cyl("SolarBowl", 0.24, 0.56, 0.34, 16, m_bronze, loc=(0, 0, 1.15), bevel=0.02)
    torus("BowlRim", 0.56, 0.045, 24, 8, m_bronze, loc=(0, 0, 1.32))
    for i in range(8):
        a = i * math.tau / 8.0
        ca, sa = math.cos(a), math.sin(a)
        cyl(f"SunSpike_{i}", 0.055, 0.012, 0.20, 6, m_bronze,
            loc=(0.60 * ca, 0.60 * sa, 1.38), rot=(0, math.radians(-38), a), bevel=0.008)

    # Sculpted teardrop glowing flame core + delicate flame tongues
    bm_fl = bmesh.new()
    bmesh.ops.create_uvsphere(bm_fl, u_segments=12, v_segments=10, radius=1.0)
    for v in bm_fl.verts:
        t_z = (v.co.z + 1.0) * 0.5
        pinch = (1.0 - t_z) ** 0.58 if t_z > 0.22 else 1.0
        v.co.x *= 0.26 * pinch
        v.co.y *= 0.26 * pinch
        v.co.z *= 0.42
    add_bm("FireCore", bm_fl, m_flame, loc=(0, 0, 1.48), smooth=True)
    save("w6_solar_brazier.glb")


def build_lantern_unit():
    clear()
    m_glow = mat("LanUnitGlow", (1.0, 0.66, 0.32), rough=0.35, em=(1.0, 0.62, 0.26), em_s=1.75)
    bm = bmesh.new()
    segs = 16
    rings_p = [
        (0.02, -0.19), (0.11, -0.17), (0.15, -0.11), (0.165, -0.05),
        (0.158, 0.0), (0.168, 0.05), (0.15, 0.11), (0.11, 0.17), (0.02, 0.19),
    ]
    ring_verts = []
    for rad, zz in rings_p:
        rv = []
        for s in range(segs):
            a = s * math.tau / segs
            rv.append(bm.verts.new((rad * math.cos(a), rad * math.sin(a), zz)))
        ring_verts.append(rv)
    for i in range(len(rings_p) - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            bm.faces.new((ring_verts[i][s], ring_verts[i][sn], ring_verts[i + 1][sn], ring_verts[i + 1][s]))
    add_bm("UnifiedLanternGlobe", bm, m_glow, smooth=True)
    save("lantern_unit.glb")


if __name__ == "__main__":
    build_grass_tuft()
    build_wildflower_cluster()
    build_mossy_stone()
    build_w1_garden_cluster()
    build_w2_forge_cluster()
    build_w3_monsoon_cluster()
    build_w4_gallery_cluster()
    build_w5_reading_cluster()
    build_w6_solar_brazier()
    build_lantern_unit()
    print("[gen_dressing_props] All AAA route set-dressing & lawn props generated!")
