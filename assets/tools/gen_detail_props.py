"""
Blender 5.2.1 LTS AAA Detail Props & Monumental Framing Landmarks Generator (v3 AAA Polish)
Exports to assets/models/scenery/:
  - pendant_lamp_post.glb
  - pip_diorama_lantern.glb
  - potted_fern.glb
  - garden_tree.glb (lush LeafCard alpha-scissor canopy + coral-pink & sunlit-gold blossoms + fluted twisted roots + fluted terracotta planter)
  - brass_astrolabe_sphere.glb
  - torii_sky_gate.glb
  - rose_window_arch.glb (ornate Gothic Cathedral Rose Window with trefoil stone tracery + multi-ring ruby/gold/amethyst/sapphire stained glass + pointed finial spires)
  - floating_candle_cluster.glb (multi-height tapered beeswax candles + wax drips + ornate brass saucers + teardrop flames)
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


def sphere(name, rad, m, loc=(0, 0, 0), rot=(0, 0, 0), u=14, v=10, subsurf=1):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=rad, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=True, subsurf=subsurf)


def lumpy_foliage_blob(name, rad, m, loc=(0, 0, 0), seed=1):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
    for v in bm.verts:
        p = v.co
        bump = (
            0.16 * math.sin(p.x * 4.2 + seed * 1.7) * math.cos(p.y * 3.8 + seed)
            + 0.12 * math.sin(p.z * 5.1 - seed * 0.9) * math.cos(p.x * 4.5)
            + 0.08 * math.cos((p.x + p.y + p.z) * 6.0 + seed * 2.3)
        )
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


def sweep_tube(name, points, radii, m, segs=8, cap=True):
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


def save(fname):
    join_by_material()
    p = os.path.join(OUT_DIR, fname)
    bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[gen_detail_props] Exported {p}")


def build_pendant_lamp_post():
    clear()
    m_iron = mat("LampIron", (0.14, 0.16, 0.18), rough=0.36, metal=0.84)
    m_brass = mat("LampBrass", (0.78, 0.56, 0.18), rough=0.25, metal=0.90)
    m_glow = mat("LampGlow", (1.0, 0.74, 0.38), rough=0.14, em=(1.0, 0.70, 0.34), em_s=3.2)

    cyl("Base", 0.34, 0.24, 0.28, 10, m_iron, loc=(0, 0, 0.14), smooth=False, bevel=0.03)
    torus("BaseRing", 0.25, 0.045, 18, 8, m_brass, loc=(0, 0, 0.30))
    cyl("Post", 0.11, 0.075, 3.1, 12, m_iron, loc=(0, 0, 1.85), bevel=0.01)
    torus("MidRing", 0.12, 0.035, 16, 8, m_brass, loc=(0, 0, 2.55))

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

    cyl("ShadeCap", 0.36, 0.10, 0.22, 14, m_brass, loc=(0.84, 0, 3.22), bevel=0.02)
    sphere("LanternGlobe", (0.24, 0.24, 0.28), m_glow, loc=(0.84, 0, 2.94), u=14, v=10, subsurf=1)
    torus("LanternRim", 0.26, 0.025, 18, 8, m_brass, loc=(0.84, 0, 2.86))
    cyl("BottomFinial", 0.08, 0.015, 0.16, 8, m_brass, loc=(0.84, 0, 2.60), bevel=0.01)
    save("pendant_lamp_post.glb")


def build_pip_diorama_lantern():
    clear()
    m_brass = mat("PipLanBrass", (0.82, 0.58, 0.20), rough=0.24, metal=0.90)
    m_stone = mat("PipLanCoaster", (0.64, 0.58, 0.48), rough=0.68)
    m_glow = mat("PipLanGlow", (1.0, 0.72, 0.30), rough=0.10, em=(1.0, 0.68, 0.24), em_s=3.6)

    cyl("Coaster", 0.34, 0.32, 0.08, 12, m_stone, loc=(0, 0, 0.04), smooth=False, bevel=0.015)
    cyl("LanBase", 0.22, 0.19, 0.09, 10, m_brass, loc=(0, 0, 0.12), smooth=False, bevel=0.012)
    sphere("EmberCore", (0.145, 0.145, 0.18), m_glow, loc=(0, 0, 0.33), u=12, v=10)
    for i in range(4):
        a = i * math.pi * 0.5 + math.pi * 0.25
        cyl(f"Strut_{i}", 0.018, 0.018, 0.36, 6, m_brass, loc=(0.175 * math.cos(a), 0.175 * math.sin(a), 0.33), bevel=0.004)
    cyl("LanCap", 0.25, 0.08, 0.16, 10, m_brass, loc=(0, 0, 0.57), smooth=False, bevel=0.015)
    torus("HandleRing", 0.085, 0.018, 16, 8, m_brass, loc=(0, 0, 0.71), rot=(math.radians(90), 0, 0))
    save("pip_diorama_lantern.glb")


def build_potted_fern():
    clear()
    m_pot = mat("PotTerra", (0.58, 0.22, 0.12), rough=0.52)
    m_rim = mat("PotRim", (0.78, 0.56, 0.20), rough=0.30, metal=0.75)
    m_soil = mat("PotSoil", (0.14, 0.09, 0.06), rough=0.92)
    m_leaf_a = mat("FernLeafA", (0.11, 0.42, 0.16), rough=0.88)
    m_leaf_b = mat("FernLeafB", (0.18, 0.54, 0.20), rough=0.86)

    cyl("PotBase", 0.42, 0.58, 0.72, 14, m_pot, loc=(0, 0, 0.36), smooth=False, bevel=0.03)
    torus("PotLip", 0.59, 0.075, 18, 8, m_pot, loc=(0, 0, 0.72))
    torus("PotBand", 0.53, 0.030, 18, 8, m_rim, loc=(0, 0, 0.52))
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
    """Astro-Bot x Ghibli Conservatory Tree: LeafCards + coral-pink & sunlit-gold blossoms + fluted twisted roots + fluted terracotta planter!"""
    clear()
    m_stone = mat("PlanterStone", (0.66, 0.60, 0.50), rough=0.60)
    m_terra = mat("PlanterTerra", (0.58, 0.21, 0.11), rough=0.52)
    m_gold = mat("PlanterBrass", (0.82, 0.58, 0.18), rough=0.24, metal=0.90)
    m_soil = mat("PlanterSoil", (0.16, 0.10, 0.06), rough=0.92)
    m_bark = mat("TreeBarkV3", (0.26, 0.14, 0.08), rough=0.78)
    m_l1 = mat("CanopyDeep", (0.09, 0.34, 0.14), rough=0.92)
    m_l2 = mat("CanopyMid", (0.16, 0.48, 0.18), rough=0.90)
    m_l3 = mat("CanopySun", (0.28, 0.60, 0.21), rough=0.88)
    # Preserved LeafCard alpha-scissor material!
    m_card = mat("LeafCard", (0.22, 0.54, 0.20), rough=0.92)
    # Non-emissive / low-emissive (<0.45) so world_helper keeps vibrant coral-pink & sunlit-gold hues!
    m_coral = mat("BlossomCoralPink", (0.98, 0.42, 0.52), rough=0.42, coat=0.20)
    m_sun_bloom = mat("BlossomSunGold", (1.0, 0.80, 0.24), rough=0.38, em=(0.98, 0.72, 0.18), em_s=0.30)
    m_lantern = mat("FairyLanternGlow", (1.0, 0.74, 0.34), rough=0.14, em=(1.0, 0.70, 0.28), em_s=3.2)

    # Carved fluted terracotta planter with brass rim
    cyl("PlanterBase", 0.90, 0.98, 0.28, 16, m_stone, loc=(0, 0, 0.14), smooth=False, bevel=0.03)
    cyl("PlanterMid", 0.78, 0.86, 0.60, 16, m_terra, loc=(0, 0, 0.56), smooth=False, bevel=0.03)
    for fi in range(12):
        fa = fi * math.tau / 12.0
        cyl(f"PlanterFlute_{fi}", 0.065, 0.075, 0.52, 6, m_terra,
            loc=(0.83 * math.cos(fa), 0.83 * math.sin(fa), 0.56), bevel=0.012)
    torus("PlanterRim", 0.88, 0.072, 24, 8, m_gold, loc=(0, 0, 0.88))
    torus("PlanterSubBand", 0.80, 0.035, 24, 6, m_gold, loc=(0, 0, 0.32))
    cyl("PlanterSoilDisc", 0.80, 0.80, 0.06, 16, m_soil, loc=(0, 0, 0.86), bevel=0.01)

    # Sculpted curved trunk + 5 fluted twisted bark roots gripping the planter soil!
    trunk_pts = [Vector((0.0, 0.0, 0.86)), Vector((0.04, -0.02, 1.45)), Vector((-0.06, 0.06, 2.25)), Vector((-0.02, 0.04, 3.05))]
    sweep_tube("CurvedTrunk", trunk_pts, [0.30, 0.24, 0.19, 0.14], m_bark, segs=12)
    for ri in range(5):
        ra = ri * math.tau / 5.0 + 0.2
        ca, sa = math.cos(ra), math.sin(ra)
        tx_p, ty_p = -sa, ca
        r_pts = [
            Vector((0.18 * ca, 0.18 * sa, 1.32)),
            Vector((0.36 * ca + 0.10 * tx_p, 0.36 * sa + 0.10 * ty_p, 1.06)),
            Vector((0.58 * ca + 0.04 * tx_p, 0.58 * sa + 0.04 * ty_p, 0.91)),
            Vector((0.72 * ca - 0.04 * tx_p, 0.72 * sa - 0.04 * ty_p, 0.86)),
        ]
        sweep_tube(f"TwistedRoot_{ri}", r_pts, [0.11, 0.085, 0.055, 0.025], m_bark, segs=7)

    limbs = [
        ((-0.65, 0.20, 2.75), (0.15, -0.78, 0.2), 1.35),
        ((0.68, -0.18, 2.65), (-0.12, 0.82, -0.15), 1.30),
        ((0.15, 0.62, 3.05), (0.72, 0.18, 0.1), 1.15),
        ((-0.22, -0.58, 2.95), (-0.68, -0.22, 0.0), 1.10),
    ]
    for idx, (loc, rot, ln) in enumerate(limbs):
        cyl(f"Limb{idx}", 0.13, 0.06, ln, 8, m_bark, loc=loc, rot=rot, bevel=0.01)

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

    # 72 Outward-Facing Painted Alpha-Scissor Leaf Cards
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
        v0 = bm_cards.verts.new(center - r_rot * sz - u_rot * sz)
        v1 = bm_cards.verts.new(center + r_rot * sz - u_rot * sz)
        v2 = bm_cards.verts.new(center + r_rot * sz + u_rot * sz + n_dir * (sz * 0.18))
        v3 = bm_cards.verts.new(center - r_rot * sz + u_rot * sz + n_dir * (sz * 0.18))
        face = bm_cards.faces.new((v0, v1, v2, v3))
        uvs = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
        for loop, uv in zip(face.loops, uvs):
            loop[uv_layer].uv = uv
    add_bm("SilhouetteLeafCards", bm_cards, m_card, smooth=True)

    # Vibrant Astro-Bot coral-pink & sunlit-gold 5-petal blossom clusters nestled across the canopy!
    blossom_spots = [
        (-1.35, 0.45, 3.55), (1.28, -0.22, 3.45), (0.18, 0.96, 3.82),
        (-0.48, -0.88, 3.65), (0.42, 0.25, 4.46), (-0.82, 0.72, 3.72),
        (0.92, 0.58, 3.78), (-1.58, 0.55, 3.18), (1.55, -0.05, 3.35),
    ]
    for bi, (bx, by, bz) in enumerate(blossom_spots):
        m_pet = m_coral if bi % 2 == 0 else m_sun_bloom
        m_ctr = m_sun_bloom if bi % 2 == 0 else m_coral
        sphere(f"BlossomCtr_{bi}", (0.065, 0.065, 0.055), m_ctr, loc=(bx, by, bz), u=8, v=6, subsurf=0)
        for pi in range(5):
            pa = pi * math.tau / 5.0 + bi * 0.4
            sphere(f"BlossomPet_{bi}_{pi}", (0.075, 0.055, 0.045), m_pet,
                   loc=(bx + 0.095 * math.cos(pa), by + 0.095 * math.sin(pa), bz - 0.01),
                   rot=(0, 0, pa), u=8, v=6, subsurf=0)

    # 2 Hanging brass fairy lanterns
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
    """Ornate Gothic Cathedral Rose Window: gilded-brass & carved-stone rings, 12 trefoil stone tracery spokes,
    multi-ring faceted ruby/gold/amethyst/sapphire stained-glass petals, and pointed finial spires!"""
    clear()
    m_marble = mat("RoseMarble", (0.86, 0.80, 0.90), rough=0.28, coat=0.45)
    m_gold = mat("RoseGold", (0.88, 0.66, 0.22), rough=0.22, metal=0.92)
    m_lead = mat("RoseLead", (0.16, 0.13, 0.20), rough=0.38, metal=0.82)
    # All jewel-glass names contain 'rose'/'ruby'/'sapph'/'ameth' so world_helper applies __jewel_glass_v2__!
    m_ruby = mat("RoseRubyGlass", (0.88, 0.16, 0.38), rough=0.12, em=(0.86, 0.14, 0.36), em_s=1.05, coat=0.95)
    m_gold_glass = mat("RoseGoldGlass", (0.98, 0.68, 0.16), rough=0.12, em=(0.98, 0.62, 0.14), em_s=1.10, coat=0.95)
    m_ameth = mat("RoseAmethGlass", (0.64, 0.24, 0.92), rough=0.12, em=(0.58, 0.20, 0.88), em_s=1.05, coat=0.95)
    m_sapph = mat("RoseSapphGlass", (0.20, 0.54, 0.98), rough=0.12, em=(0.16, 0.48, 0.96), em_s=1.05, coat=0.95)

    # Sculpted layered gilded-brass & carved-stone outer rings
    torus("OuterStone", 8.35, 0.66, 48, 12, m_marble, rot=(math.radians(90), 0, 0))
    torus("OuterStoneMold", 9.02, 0.24, 48, 8, m_marble, rot=(math.radians(90), 0, 0))
    torus("OuterGoldRing", 7.62, 0.24, 48, 8, m_gold, rot=(math.radians(90), 0, 0))
    torus("MidStoneRing", 4.55, 0.22, 36, 8, m_marble, rot=(math.radians(90), 0, 0))
    torus("MidGoldRing", 4.25, 0.14, 36, 8, m_gold, rot=(math.radians(90), 0, 0))
    torus("InnerGoldRing", 1.75, 0.16, 28, 8, m_gold, rot=(math.radians(90), 0, 0))
    # Central rose jewel medallion
    cyl("CenterJewel", 1.55, 1.55, 0.16, 12, m_ruby, rot=(math.radians(90), 0, 0), smooth=False, bevel=0.02)
    torus("CenterBossGold", 0.58, 0.11, 18, 6, m_gold, rot=(math.radians(90), 0, 0))

    # 12 Trefoil stone tracery spokes & multi-ring faceted jewel petals!
    outer_glass = [m_ruby, m_gold_glass, m_ameth, m_sapph]
    for i in range(12):
        a = i * math.tau / 12.0
        ca, sa = math.cos(a), math.sin(a)
        # Carved stone tracery spoke with gilded inner rib
        box(f"StoneSpoke_{i}", (0.24, 0.34, 6.2), m_marble, loc=(4.65 * ca, 0, 4.65 * sa), rot=(0, math.pi * 0.5 - a, 0), bevel=0.03)
        box(f"GoldSpoke_{i}", (0.10, 0.42, 6.1), m_gold, loc=(4.65 * ca, 0, 4.65 * sa), rot=(0, math.pi * 0.5 - a, 0), bevel=0.01)

        # Trefoil Gothic tracery arch cusps at outer end of each spoke bay
        am = a + math.tau / 24.0
        cam, sam = math.cos(am), math.sin(am)
        for tref_off in (-0.28, 0.28):
            ta = am + tref_off * 0.35
            torus(f"TrefoilLobe_{i}_{tref_off}", 0.52, 0.08, 16, 6, m_marble,
                  loc=(6.85 * math.cos(ta), 0, 6.85 * math.sin(ta)), rot=(math.radians(90), 0, 0))
        torus(f"TrefoilCrown_{i}", 0.48, 0.08, 16, 6, m_gold,
              loc=(7.15 * cam, 0, 7.15 * sam), rot=(math.radians(90), 0, 0))

        # Inner ring: 12 faceted diamond/lancet stained-glass petals
        ir = 2.95
        bm_in = bmesh.new()
        p0 = bm_in.verts.new((0, 0, -0.95))
        p1 = bm_in.verts.new((0.52, 0, 0.15))
        p2 = bm_in.verts.new((0, 0, 1.05))
        p3 = bm_in.verts.new((-0.52, 0, 0.15))
        bm_in.faces.new((p0, p1, p2, p3))
        bmesh.ops.solidify(bm_in, geom=bm_in.faces[:], thickness=0.12)
        add_bm(f"InnerPetal_{i}", bm_in, m_sapph if i % 2 == 0 else m_gold_glass,
               loc=(ir * cam, -0.06, ir * sam), rot=(0, math.pi * 0.5 - am, 0), smooth=False, bevel=0.015)

        # Outer ring: 12 faceted multi-lobed stained-glass rose petals framed in dark lead
        px, pz = 5.88 * cam, 5.88 * sam
        cyl(f"OuterPetal_{i}", 1.10, 1.10, 0.14, 8, outer_glass[i % 4],
            loc=(px, 0, pz), rot=(math.radians(90), 0, am), smooth=False, bevel=0.02)
        torus(f"OuterPetalLead_{i}", 1.12, 0.085, 16, 6, m_lead, loc=(px, 0, pz), rot=(math.radians(90), 0, 0))
        # Delicate lead quatrefoil tracery bars inside each outer medallion
        box(f"QuatBarA_{i}", (2.15, 0.20, 0.08), m_lead, loc=(px, 0, pz), rot=(0, am, 0))
        box(f"QuatBarB_{i}", (0.08, 0.20, 2.15), m_lead, loc=(px, 0, pz), rot=(0, am, 0))

    # Gothic pointed flanking buttress piers & delicate pointed finial spires!
    for sx in (-9.65, 9.65):
        box(f"ButtressPier_{sx}", (1.15, 1.25, 12.5), m_marble, loc=(sx, 0, -2.5), bevel=0.06)
        box(f"ButtressGoldBand_{sx}", (1.28, 1.38, 0.35), m_gold, loc=(sx, 0, 3.65), bevel=0.03)
        cyl(f"FinialSpire_{sx}", 0.56, 0.04, 4.2, 6, m_marble, loc=(sx, 0, 5.95), bevel=0.02)
        cyl(f"FinialGoldTip_{sx}", 0.16, 0.01, 0.95, 6, m_gold, loc=(sx, 0, 8.35), bevel=0.01)
    # Central crown Gothic finial spire atop the rose arch
    cyl("CrownPedestal", 0.72, 0.56, 1.1, 8, m_marble, loc=(0, 0, 9.65), bevel=0.04)
    cyl("CrownSpire", 0.48, 0.03, 3.4, 6, m_gold, loc=(0, 0, 11.85), bevel=0.02)
    save("rose_window_arch.glb")


def build_floating_candle_cluster():
    """Multi-height sculpted tapered beeswax candles + wax drips + ornate brass saucers + teardrop glowing flames!"""
    clear()
    m_wax = mat("CandleWax", (0.88, 0.75, 0.52), rough=0.46, coat=0.15)
    m_flame = mat("CandleFlameGlow", (1.0, 0.64, 0.22), rough=0.10, em=(1.0, 0.58, 0.16), em_s=2.0)
    m_brass = mat("CandleDish", (0.82, 0.58, 0.18), rough=0.22, metal=0.90)

    specs = [
        ((0.0, 0.0, 0.06), 0.135, 0.86),
        ((-0.35, 0.22, 0.20), 0.105, 0.58),
        ((0.34, 0.18, -0.14), 0.115, 0.70),
        ((0.14, -0.35, 0.28), 0.095, 0.50),
        ((-0.26, -0.28, -0.22), 0.105, 0.64),
        ((-0.05, 0.38, -0.06), 0.088, 0.44),
        ((0.40, -0.22, 0.12), 0.092, 0.54),
    ]
    for i, ((x, y, z), rad, h) in enumerate(specs):
        base_z = z - h * 0.5
        top_z = z + h * 0.5
        # Ornate turned brass saucer base with flared rim & finger loop handle
        cyl(f"SaucerFoot_{i}", rad * 1.15, rad * 0.85, 0.045, 14, m_brass, loc=(x, y, base_z - 0.025), bevel=0.008)
        cyl(f"SaucerBowl_{i}", rad * 1.15, rad * 1.75, 0.055, 16, m_brass, loc=(x, y, base_z + 0.02), bevel=0.01)
        torus(f"SaucerRim_{i}", rad * 1.74, 0.018, 18, 6, m_brass, loc=(x, y, base_z + 0.045))
        torus(f"SaucerHandle_{i}", 0.042, 0.010, 12, 6, m_brass,
              loc=(x + rad * 1.85, y, base_z + 0.03), rot=(math.radians(90), 0, 0))

        # Sculpted tapered beeswax pillar with gently melted top rim
        cyl(f"Wax_{i}", rad, rad * 0.90, h, 14, m_wax, loc=(x, y, z), bevel=0.02)
        torus(f"WaxPoolRim_{i}", rad * 0.82, 0.024, 16, 6, m_wax, loc=(x, y, top_z - 0.01))

        # Sculpted wax drips running down the candle sides
        for di in range(3):
            da = di * math.tau / 3.0 + i * 1.1
            drip_len = 0.14 + ((i + di) % 3) * 0.09
            r_d = rad * 0.91
            drip_pts = [
                Vector((x + r_d * math.cos(da), y + r_d * math.sin(da), top_z - 0.02)),
                Vector((x + (r_d + 0.012) * math.cos(da), y + (r_d + 0.012) * math.sin(da), top_z - drip_len * 0.5)),
                Vector((x + (r_d + 0.016) * math.cos(da), y + (r_d + 0.016) * math.sin(da), top_z - drip_len)),
            ]
            sweep_tube(f"WaxDrip_{i}_{di}", drip_pts, [0.020, 0.015, 0.024], m_wax, segs=6)

        # Sculpted teardrop glowing flame!
        bm_fl = bmesh.new()
        bmesh.ops.create_uvsphere(bm_fl, u_segments=10, v_segments=8, radius=1.0)
        for v in bm_fl.verts:
            t_z = (v.co.z + 1.0) * 0.5  # 0 bottom -> 1 tip
            pinch = (1.0 - t_z) ** 0.55 if t_z > 0.25 else 1.0
            v.co.x *= rad * 0.44 * pinch
            v.co.y *= rad * 0.44 * pinch
            v.co.z *= rad * 1.18
        add_bm(f"TeardropFlame_{i}", bm_fl, m_flame, loc=(x, y, top_z + rad * 1.05), smooth=True)
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
