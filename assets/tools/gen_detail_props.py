"""
Blender 5.2.1 LTS AAA Detail Props & Monumental Framing Landmarks Generator (v2 Polish)
Upgrades:
  - pendant_lamp_post.glb: warm honey-amber LampGlow (never white-clipping!)
  - garden_tree.glb: lumpy sculpted organic foliage clusters (matte roughness >= 0.90) + 36 UV-mapped
    alpha-scissor silhouette LeafCards (kills glossy pickle-ellipsoids!)
  - pip_diorama_lantern.glb: ornate heirloom brass ember lantern placed beside Pip in the Diorama!
  - potted_fern.glb, brass_astrolabe_sphere.glb, torii_sky_gate.glb, rose_window_arch.glb, floating_candle_cluster.glb
"""

import os
import math
import random
import bpy
import bmesh
from mathutils import Vector, Euler

OUT_DIR = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/scenery"
os.makedirs(OUT_DIR, exist_ok=True)


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, col, rough=0.48, metal=0.0, em=None, em_s=0.0, coat=0.0):
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


def add_bm(name, bm, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True, bevel=0.0, subsurf=0):
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


def box(name, sz, m, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.03):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=sz, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=False, bevel=bevel)


def cyl(name, r1, r2, h, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=True, bevel=0.02):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel)


def sphere(name, rad, m, loc=(0, 0, 0), u=14, v=10, subsurf=1):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=rad, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, smooth=True, subsurf=subsurf)


def lumpy_foliage_blob(name, rad, m, loc=(0, 0, 0), seed=1):
    """Organic bumpy sculpted Ghibli canopy clump (replaces smooth pickle ellipsoids!)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
    for v in bm.verts:
        p = v.co
        bump = (
            0.16 * math.sin(p.x * 4.2 + seed * 1.7) * math.cos(p.y * 3.8 + seed)
            + 0.12 * math.sin(p.z * 5.1 - seed * 0.9) * math.cos(p.x * 4.5)
            + 0.08 * math.cos((p.x + p.y + p.z) * 6.0 + seed * 2.3)
        )
        # Flatten bottom slightly like sunlit cumulus/bonsai foliage pads
        z_scale = 0.72 if p.z < 0.0 else 1.05
        v.co.x = p.x * (1.0 + bump) * rad[0]
        v.co.y = p.y * (1.0 + bump) * rad[1]
        v.co.z = p.z * (1.0 + bump) * rad[2] * z_scale
    return add_bm(name, bm, m, loc=loc, smooth=True, bevel=0.0, subsurf=0)


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


def join_by_material():
    by_mat = {}
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and len(obj.data.materials) == 1 and obj.data.materials[0] is not None:
            mname = obj.data.materials[0].name
            by_mat.setdefault(mname, []).append(obj)
    for mname, objs in by_mat.items():
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
    print(f"[gen_detail_props] Exported {p}")


def build_pendant_lamp_post():
    clear()
    m_iron = mat("LampIron", (0.14, 0.16, 0.18), rough=0.36, metal=0.84)
    m_brass = mat("LampBrass", (0.78, 0.56, 0.18), rough=0.25, metal=0.90)
    # Rich warm honey-amber emission (stays saturated gold under AgX, never clips flat white!)
    m_glow = mat("LampGlow", (1.0, 0.74, 0.38), rough=0.14, em=(1.0, 0.70, 0.34), em_s=3.2)

    cyl("Base", 0.34, 0.24, 0.28, 8, m_iron, loc=(0, 0, 0.14), smooth=False, bevel=0.03)
    torus("BaseRing", 0.25, 0.045, 16, 8, m_brass, loc=(0, 0, 0.30))
    cyl("Post", 0.11, 0.075, 3.1, 10, m_iron, loc=(0, 0, 1.85), bevel=0.01)
    torus("MidRing", 0.12, 0.035, 14, 8, m_brass, loc=(0, 0, 2.55))

    bm = bmesh.new()
    segs = 14
    r_segs = 8
    rings = []
    for i in range(segs + 1):
        u = i / segs
        ang = math.pi * u
        cx = 0.42 - 0.42 * math.cos(ang)
        cz = 3.35 + 0.46 * math.sin(ang)
        tx = 0.42 * math.sin(ang)
        tz = 0.46 * math.cos(ang)
        tl = math.hypot(tx, tz)
        nx, nz = tz / tl, -tx / tl
        rad = 0.055 - u * 0.015
        ring = []
        for s in range(r_segs):
            a = 2.0 * math.pi * s / r_segs
            ring.append(bm.verts.new((cx + nx * math.cos(a) * rad, math.sin(a) * rad, cz + nz * math.cos(a) * rad)))
        rings.append(ring)
    for i in range(segs):
        for s in range(r_segs):
            sn = (s + 1) % r_segs
            bm.faces.new((rings[i][s], rings[i][sn], rings[i + 1][sn], rings[i + 1][s]))
    add_bm("CrookArm", bm, m_iron, smooth=True)

    cyl("ShadeCap", 0.36, 0.10, 0.22, 12, m_brass, loc=(0.84, 0, 3.22), bevel=0.02)
    sphere("LanternGlobe", (0.24, 0.24, 0.28), m_glow, loc=(0.84, 0, 2.94), u=14, v=10, subsurf=1)
    torus("LanternRim", 0.26, 0.025, 16, 8, m_brass, loc=(0.84, 0, 2.86))
    cyl("BottomFinial", 0.08, 0.015, 0.16, 8, m_brass, loc=(0.84, 0, 2.60), bevel=0.01)
    save("pendant_lamp_post.glb")


def build_pip_diorama_lantern():
    """Ornate heirloom brass ember lantern sitting beside Pip in the Character Select Diorama."""
    clear()
    m_brass = mat("PipLanBrass", (0.82, 0.58, 0.20), rough=0.24, metal=0.90)
    m_stone = mat("PipLanCoaster", (0.64, 0.58, 0.48), rough=0.68)
    m_glow = mat("PipLanGlow", (1.0, 0.72, 0.30), rough=0.10, em=(1.0, 0.68, 0.24), em_s=3.6)

    cyl("Coaster", 0.34, 0.32, 0.08, 10, m_stone, loc=(0, 0, 0.04), smooth=False, bevel=0.015)
    cyl("LanBase", 0.22, 0.19, 0.09, 8, m_brass, loc=(0, 0, 0.12), smooth=False, bevel=0.012)
    sphere("EmberCore", (0.145, 0.145, 0.18), m_glow, loc=(0, 0, 0.33), u=12, v=10)
    for i in range(4):
        a = i * math.pi * 0.5 + math.pi * 0.25
        cyl(f"Strut_{i}", 0.018, 0.018, 0.36, 6, m_brass, loc=(0.175 * math.cos(a), 0.175 * math.sin(a), 0.33), bevel=0.004)
    cyl("LanCap", 0.25, 0.08, 0.16, 8, m_brass, loc=(0, 0, 0.57), smooth=False, bevel=0.015)
    torus("HandleRing", 0.085, 0.018, 16, 8, m_brass, loc=(0, 0, 0.71), rot=(math.radians(90), 0, 0))
    save("pip_diorama_lantern.glb")


def build_potted_fern():
    clear()
    m_pot = mat("PotTerra", (0.58, 0.22, 0.12), rough=0.52)
    m_rim = mat("PotRim", (0.78, 0.56, 0.20), rough=0.30, metal=0.75)
    m_soil = mat("PotSoil", (0.14, 0.09, 0.06), rough=0.92)
    m_leaf_a = mat("FernLeafA", (0.11, 0.42, 0.16), rough=0.88)
    m_leaf_b = mat("FernLeafB", (0.18, 0.54, 0.20), rough=0.86)

    cyl("PotBase", 0.42, 0.58, 0.72, 12, m_pot, loc=(0, 0, 0.36), smooth=False, bevel=0.03)
    torus("PotLip", 0.59, 0.075, 16, 8, m_pot, loc=(0, 0, 0.72))
    torus("PotBand", 0.53, 0.030, 16, 8, m_rim, loc=(0, 0, 0.52))
    cyl("Soil", 0.52, 0.52, 0.08, 12, m_soil, loc=(0, 0, 0.68), bevel=0.01)

    for idx in range(14):
        tier = 0 if idx < 8 else 1
        ang = (idx * (2.0 * math.pi / 8.0)) if tier == 0 else ((idx - 8) * (2.0 * math.pi / 6.0) + 0.4)
        length = 1.05 if tier == 0 else 0.85
        bm = bmesh.new()
        rows = []
        for k in range(6):
            u = k / 5.0
            dist = u * length
            arch_z = math.sin(u * math.pi * 0.72) * (0.55 if tier == 0 else 0.72) + u * (0.25 if tier == 1 else -0.05)
            w = math.sin(u * math.pi) * (0.22 if tier == 0 else 0.18) + 0.02
            v_l = bm.verts.new((dist, -w, arch_z))
            v_c = bm.verts.new((dist, 0.0, arch_z + 0.03))
            v_r = bm.verts.new((dist, w, arch_z))
            rows.append((v_l, v_c, v_r))
        for k in range(5):
            r0, r1 = rows[k], rows[k + 1]
            bm.faces.new((r0[0], r0[1], r1[1], r1[0]))
            bm.faces.new((r0[1], r0[2], r1[2], r1[1]))
        bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.025)
        add_bm(f"Leaf_{idx}", bm, m_leaf_a if idx % 2 == 0 else m_leaf_b,
               loc=(0.08 * math.cos(ang), 0.08 * math.sin(ang), 0.70),
               rot=(0, 0, ang), smooth=True)
    save("potted_fern.glb")


def build_garden_tree_v3():
    """Overhauled organic Ghibli Conservatory Bonsai Tree: lumpy foliage clusters + alpha-scissor LeafCards!"""
    clear()
    m_stone = mat("PlanterStone", (0.64, 0.58, 0.48), rough=0.60)
    m_terra = mat("PlanterTerra", (0.56, 0.20, 0.11), rough=0.54)
    m_gold = mat("PlanterGold", (0.78, 0.56, 0.16), rough=0.26, metal=0.86)
    m_bark = mat("TreeBarkV3", (0.26, 0.14, 0.08), rough=0.78)
    m_l1 = mat("CanopyDeep", (0.09, 0.34, 0.14), rough=0.92)
    m_l2 = mat("CanopyMid", (0.16, 0.48, 0.18), rough=0.90)
    m_l3 = mat("CanopySun", (0.28, 0.60, 0.21), rough=0.88)
    m_card = mat("LeafCard", (0.22, 0.54, 0.20), rough=0.92)
    m_blossom = mat("BlossomWarm", (0.98, 0.76, 0.42), rough=0.35, em=(0.95, 0.68, 0.24), em_s=0.65)
    m_lantern = mat("FairyLanternGlow", (1.0, 0.74, 0.34), rough=0.14, em=(1.0, 0.70, 0.28), em_s=3.2)

    cyl("PlanterBase", 0.88, 0.96, 0.34, 8, m_stone, loc=(0, 0, 0.17), smooth=False, bevel=0.03)
    cyl("PlanterMid", 0.78, 0.84, 0.55, 8, m_terra, loc=(0, 0, 0.58), smooth=False, bevel=0.03)
    torus("PlanterRim", 0.86, 0.07, 16, 8, m_gold, loc=(0, 0, 0.88))

    cyl("TrunkLow", 0.32, 0.22, 1.35, 10, m_bark, loc=(0, 0, 1.45), rot=(0.10, -0.08, 0), bevel=0.02)
    cyl("TrunkMid", 0.22, 0.15, 1.25, 10, m_bark, loc=(-0.08, 0.08, 2.55), rot=(-0.12, 0.14, 0), bevel=0.02)
    limbs = [
        ((-0.65, 0.20, 2.75), (0.15, -0.78, 0.2), 1.35),
        ((0.68, -0.18, 2.65), (-0.12, 0.82, -0.15), 1.30),
        ((0.15, 0.62, 3.05), (0.72, 0.18, 0.1), 1.15),
        ((-0.22, -0.58, 2.95), (-0.68, -0.22, 0.0), 1.10),
    ]
    for idx, (loc, rot, ln) in enumerate(limbs):
        cyl(f"Limb{idx}", 0.13, 0.06, ln, 8, m_bark, loc=loc, rot=rot, bevel=0.01)

    # Organic sculpted bumpy foliage clumps (matte velvety, zero smooth plastic pickle balls!)
    foliage = [
        ((0.0, 0.0, 3.85), (1.05, 0.98, 0.68), m_l2),
        ((0.28, 0.24, 4.22), (0.78, 0.74, 0.54), m_l3),
        ((-1.22, 0.34, 3.05), (0.92, 0.84, 0.60), m_l1),
        ((-1.52, 0.50, 3.35), (0.64, 0.60, 0.46), m_l3),
        ((1.20, -0.32, 2.95), (0.88, 0.80, 0.58), m_l2),
        ((1.46, -0.14, 3.28), (0.62, 0.58, 0.44), m_l3),
        ((0.26, 1.08, 3.35), (0.82, 0.74, 0.54), m_l1),
        ((-0.36, -1.00, 3.25), (0.78, 0.72, 0.52), m_l2),
        ((-0.55, 0.72, 3.68), (0.74, 0.70, 0.52), m_l2),
        ((0.66, 0.56, 3.64), (0.70, 0.66, 0.48), m_l3),
    ]
    for i, (loc, rad, m_f) in enumerate(foliage):
        lumpy_foliage_blob(f"LeafClump{i}", rad, m_f, loc=loc, seed=i + 3)

    # 72 Outward-Facing Painted Alpha-Scissor Leaf Cards creating lush layered Ghibli canopy volume!
    rng = random.Random(2026)
    bm_cards = bmesh.new()
    uv_layer = bm_cards.loops.layers.uv.new("UVMap")
    for idx in range(72):
        clump_loc, clump_rad, _ = foliage[idx % len(foliage)]
        theta = rng.uniform(0.0, math.tau)
        phi = rng.uniform(-0.35, 0.92)
        n_dir = Vector((math.cos(theta) * math.cos(phi), math.sin(theta) * math.cos(phi), math.sin(phi))).normalized()
        center = Vector(clump_loc) + Vector((n_dir.x * clump_rad[0] * 0.94, n_dir.y * clump_rad[1] * 0.94, n_dir.z * clump_rad[2] * 0.94))
        up_ref = Vector((0, 0, 1)) if abs(n_dir.z) < 0.85 else Vector((1, 0, 0))
        right = n_dir.cross(up_ref).normalized()
        up = right.cross(n_dir).normalized()
        sz = rng.uniform(0.52, 0.92)
        roll = rng.uniform(-0.55, 0.55)
        cr, sr = math.cos(roll), math.sin(roll)
        r_rot = right * cr + up * sr
        u_rot = -right * sr + up * cr
        # Slight V-fold quad for 3D botanical silhouette from every camera angle!
        v0 = bm_cards.verts.new(center - r_rot * sz - u_rot * sz)
        v1 = bm_cards.verts.new(center + r_rot * sz - u_rot * sz)
        v2 = bm_cards.verts.new(center + r_rot * sz + u_rot * sz + n_dir * (sz * 0.18))
        v3 = bm_cards.verts.new(center - r_rot * sz + u_rot * sz + n_dir * (sz * 0.18))
        face = bm_cards.faces.new((v0, v1, v2, v3))
        uvs = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
        for loop, uv in zip(face.loops, uvs):
            loop[uv_layer].uv = uv
    add_bm("SilhouetteLeafCards", bm_cards, m_card, smooth=True)

    # Warm glowing blossom clusters & 2 hanging brass fairy lanterns
    for i, p in enumerate([(-1.3, 0.4, 3.5), (1.2, -0.2, 3.4), (0.1, 0.8, 3.8), (-0.4, -0.8, 3.6), (0.3, 0.1, 4.4)]):
        sphere(f"Blossom{i}", (0.15, 0.15, 0.12), m_blossom, loc=p, u=8, v=6, subsurf=0)
    for i, lp in enumerate([(-1.15, 0.25, 2.42), (1.12, -0.24, 2.34)]):
        cyl(f"Cord{i}", 0.015, 0.015, 0.42, 6, m_gold, loc=(lp[0], lp[1], lp[2] + 0.22), bevel=0.0)
        sphere(f"FairyOrb{i}", (0.14, 0.14, 0.18), m_lantern, loc=lp, u=10, v=8, subsurf=0)
        cyl(f"FairyCap{i}", 0.17, 0.05, 0.08, 8, m_gold, loc=(lp[0], lp[1], lp[2] + 0.15), bevel=0.01)
    save("garden_tree.glb")


def build_brass_astrolabe_sphere():
    clear()
    m_brass = mat("AstroBrass", (0.78, 0.54, 0.18), rough=0.24, metal=0.90)
    m_copper = mat("AstroCopper", (0.62, 0.28, 0.15), rough=0.32, metal=0.84)
    m_sun = mat("AstroSunGlow", (1.0, 0.74, 0.30), rough=0.10, em=(1.0, 0.68, 0.22), em_s=2.8)

    torus("RingA", 8.5, 0.32, 48, 10, m_brass, rot=(0, 0, 0))
    torus("RingB", 7.4, 0.26, 44, 10, m_copper, rot=(math.radians(58), math.radians(24), 0))
    torus("RingC", 6.2, 0.22, 40, 8, m_brass, rot=(math.radians(-48), math.radians(72), 0))
    torus("RingD", 4.6, 0.16, 32, 8, m_copper, rot=(math.radians(90), math.radians(15), 0))
    cyl("AxisRod", 0.18, 0.18, 19.5, 10, m_brass, rot=(math.radians(22), 0, 0), bevel=0.02)
    sphere("SunCore", (1.35, 1.35, 1.35), m_sun, u=18, v=12, subsurf=1)
    save("brass_astrolabe_sphere.glb")


def build_torii_sky_gate():
    clear()
    m_red = mat("ToriiVermilion", (0.68, 0.11, 0.09), rough=0.32, coat=0.55)
    m_dark = mat("ToriiObs", (0.09, 0.10, 0.14), rough=0.38)
    m_gold = mat("ToriiGold", (0.86, 0.64, 0.20), rough=0.24, metal=0.88)
    m_glow = mat("ToriiLanternGlow", (1.0, 0.74, 0.34), rough=0.18, em=(1.0, 0.68, 0.24), em_s=3.2)

    for sx in (-4.4, 4.4):
        cyl(f"Base{sx}", 0.78, 0.62, 1.1, 12, m_dark, loc=(sx, 0, 0.55), bevel=0.04)
        cyl(f"Pillar{sx}", 0.52, 0.44, 9.2, 14, m_red, loc=(sx, 0, 5.4), bevel=0.03)
        torus(f"Collar{sx}", 0.54, 0.09, 16, 8, m_gold, loc=(sx, 0, 8.2))
    box("Nuki", (11.2, 0.52, 0.65), m_red, loc=(0, 0, 8.2), bevel=0.05)
    box("CenterPlaque", (1.35, 0.62, 1.65), m_dark, loc=(0, 0, 9.15), bevel=0.04)
    box("PlaqueGold", (1.05, 0.68, 1.30), m_gold, loc=(0, 0, 9.15), bevel=0.02)

    for i in range(9):
        t = (i / 8.0) * 2.0 - 1.0
        x = t * 6.4
        z = 10.1 + (t * t) * 0.95
        tilt = math.atan2(1.9 * t, 6.4)
        box(f"KasagiRed{i}", (1.75, 1.05, 0.55), m_red, loc=(x, 0, z), rot=(0, -tilt, 0), bevel=0.04)
        box(f"KasagiCap{i}", (1.85, 1.25, 0.28), m_dark, loc=(x, 0, z + 0.38), rot=(0, -tilt, 0), bevel=0.03)
    for sx in (-2.6, 2.6):
        cyl(f"Lantern{sx}", 0.52, 0.44, 1.15, 10, m_glow, loc=(sx, 0, 7.0), bevel=0.04)
        cyl(f"LCap{sx}", 0.58, 0.25, 0.22, 10, m_dark, loc=(sx, 0, 7.65), bevel=0.02)
    save("torii_sky_gate.glb")


def build_rose_window_arch():
    clear()
    m_marble = mat("RoseMarble", (0.86, 0.80, 0.90), rough=0.30, coat=0.45)
    m_gold = mat("RoseGold", (0.86, 0.64, 0.22), rough=0.22, metal=0.90)
    m_lead = mat("RoseLead", (0.18, 0.14, 0.22), rough=0.38, metal=0.80)
    # Jewel-toned stained glass (HDR < 1.8 so zero flat pink/white octagons!)
    m_glass_a = mat("RoseRuby", (0.82, 0.26, 0.50), rough=0.14, em=(0.78, 0.22, 0.44), em_s=1.40, coat=0.9)
    m_glass_b = mat("RoseAmber", (0.94, 0.58, 0.22), rough=0.14, em=(0.90, 0.52, 0.18), em_s=1.50, coat=0.9)

    torus("OuterStone", 8.2, 0.72, 48, 10, m_marble, rot=(math.radians(90), 0, 0))
    torus("InnerGold", 7.4, 0.26, 48, 8, m_gold, rot=(math.radians(90), 0, 0))
    torus("MidGold", 4.2, 0.20, 36, 8, m_gold, rot=(math.radians(90), 0, 0))
    torus("CenterRing", 1.5, 0.18, 24, 8, m_gold, rot=(math.radians(90), 0, 0))
    for i in range(12):
        a = i * math.pi / 6.0
        box(f"Spoke{i}", (0.24, 0.32, 7.4), m_gold, loc=(3.8 * math.cos(a), 0, 3.8 * math.sin(a)),
            rot=(0, math.pi * 0.5 - a, 0), bevel=0.02)
        px, pz = 5.7 * math.cos(a + 0.26), 5.7 * math.sin(a + 0.26)
        # 16-sided circular stained-glass medallion with dark lead rim & crossed mullions!
        cyl(f"Petal{i}", 0.90, 0.90, 0.14, 16, m_glass_a if i % 2 == 0 else m_glass_b,
            loc=(px, 0, pz), rot=(math.radians(90), 0, 0), smooth=True, bevel=0.01)
        torus(f"PetalLead_{i}", 0.92, 0.08, 20, 6, m_lead, loc=(px, 0, pz), rot=(math.radians(90), 0, 0))
        box(f"PetalCrossA_{i}", (1.75, 0.20, 0.08), m_lead, loc=(px, 0, pz), rot=(0, a, 0))
        box(f"PetalCrossB_{i}", (0.08, 0.20, 1.75), m_lead, loc=(px, 0, pz), rot=(0, a, 0))
    save("rose_window_arch.glb")


def build_floating_candle_cluster():
    clear()
    # Warm honey-beeswax candle wax (never bleaches white under lights!)
    m_wax = mat("CandleWax", (0.86, 0.72, 0.50), rough=0.52)
    m_flame = mat("CandleFlameGlow", (1.0, 0.64, 0.22), rough=0.12, em=(1.0, 0.58, 0.16), em_s=1.95)
    m_brass = mat("CandleDish", (0.78, 0.56, 0.18), rough=0.25, metal=0.88)

    specs = [
        ((0.0, 0.0, 0.0), 0.13, 0.78),
        ((-0.34, 0.22, 0.18), 0.10, 0.56),
        ((0.32, 0.18, -0.14), 0.11, 0.66),
        ((0.12, -0.34, 0.28), 0.095, 0.50),
        ((-0.24, -0.26, -0.22), 0.10, 0.60),
    ]
    for i, ((x, y, z), rad, h) in enumerate(specs):
        cyl(f"Dish{i}", rad * 1.5, rad * 1.2, 0.06, 12, m_brass, loc=(x, y, z - h * 0.5), bevel=0.01)
        cyl(f"Wax{i}", rad, rad * 0.94, h, 12, m_wax, loc=(x, y, z), bevel=0.02)
        sphere(f"Flame{i}", (rad * 0.45, rad * 0.45, rad * 1.05), m_flame, loc=(x, y, z + h * 0.5 + rad * 0.95), u=8, v=6, subsurf=0)
    save("floating_candle_cluster.glb")


if __name__ == "__main__":
    build_pendant_lamp_post()
    build_pip_diorama_lantern()
    build_potted_fern()
    build_garden_tree_v3()
    build_brass_astrolabe_sphere()
    build_torii_sky_gate()
    build_rose_window_arch()
    build_floating_candle_cluster()
    print("[gen_detail_props] All AAA detail props & landmarks generated!")
