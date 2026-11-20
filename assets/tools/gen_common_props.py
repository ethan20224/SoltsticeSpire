"""
Blender 5.2.1 LTS Procedural Asset Generator - Common Hero Props
Generates sculpted, beveled .glb models shared across all 6 ascending worlds:
  1. sky_shrine.glb  - Living Checkpoint Shrine (stepped plinth, 4 blooming petal arches, floating crystal bell core)
  2. sun_shard.glb   - High-skill collectible star-octahedron with twin brass astrolabe rings
  3. tether_orb.glb  - Luminous grapple/snap spirit orb with filigree halos
  4. world_gate.glb  - Monumental Ascension Archway marking transitions between surreal worlds
  5. bounce_ring.glb - Stylized tactile spring pad frame used across biomes
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector, Euler

OUT_DIR = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/common"
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_mat(name, color, roughness=0.42, metallic=0.0, emission=None, emission_strength=0.0, coat=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if coat > 0.0 and "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = coat
        bsdf.inputs["Coat Roughness"].default_value = 0.15
    if emission is not None and emission_strength > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def make_empty(name, loc=(0, 0, 0), rot=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    if parent:
        obj.parent = parent
    obj.location = loc
    obj.rotation_euler = rot
    return obj


def add_bm(name, bm, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None, smooth=True, bevel=0.02, subsurf=0):
    mesh = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    if parent:
        obj.parent = parent
    obj.location = loc
    obj.rotation_euler = rot
    obj.data.materials.append(mat)
    if smooth:
        for p in obj.data.polygons:
            p.use_smooth = True
    if bevel > 0.0:
        bev = obj.modifiers.new("Bevel", "BEVEL")
        bev.width = bevel
        bev.segments = 2
        bev.limit_method = "ANGLE"
        bev.angle_limit = math.radians(32)
    if subsurf > 0:
        sub = obj.modifiers.new("Subsurf", "SUBSURF")
        sub.levels = subsurf
        sub.render_levels = subsurf
    return obj


def add_cyl(name, r1, r2, h, segs, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None, smooth=True, bevel=0.02):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, mat, loc=loc, rot=rot, parent=parent, smooth=smooth, bevel=bevel)


def add_torus(name, R, r, maj_s, min_s, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None):
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
    return add_bm(name, bm, mat, loc=loc, rot=rot, parent=parent, smooth=True, bevel=0.0)


def export_glb(filename):
    path = os.path.join(OUT_DIR, filename)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[gen_common_props] Exported {path}")


def build_sky_shrine():
    clear_scene()
    m_stone = make_mat("ShrineStone", (0.58, 0.52, 0.43), roughness=0.62)
    m_dark_stone = make_mat("ShrineDarkStone", (0.24, 0.23, 0.28), roughness=0.68)
    m_gold = make_mat("ShrineGold", (0.78, 0.56, 0.16), roughness=0.25, metallic=0.88)
    m_core = make_mat("ShrineCore", (0.32, 0.84, 1.0), roughness=0.1, emission=(0.24, 0.78, 1.0), emission_strength=2.2, coat=0.7)

    root = make_empty("SkyShrineRoot")
    # Stepped Octagonal Carved Base
    add_cyl("BaseLower", 1.35, 1.25, 0.24, 8, m_dark_stone, loc=(0, 0, 0.12), parent=root, smooth=False, bevel=0.03)
    add_cyl("BaseUpper", 1.05, 0.92, 0.26, 8, m_stone, loc=(0, 0, 0.36), parent=root, smooth=False, bevel=0.03)
    add_torus("BaseGoldRing", 0.98, 0.045, 24, 10, m_gold, loc=(0, 0, 0.49), parent=root)
    # Central Pedestal Column
    add_cyl("Pedestal", 0.36, 0.28, 0.75, 8, m_stone, loc=(0, 0, 0.86), parent=root, smooth=False, bevel=0.025)
    add_torus("PedestalRim", 0.34, 0.04, 16, 8, m_gold, loc=(0, 0, 1.24), parent=root)

    # 4 Articulated Blooming Petal Arches (ShrinePetal0..3) that open outward on checkpoint activation!
    for i in range(4):
        ang = i * math.pi * 0.5
        pivot = make_empty(f"ShrinePetal{i}", loc=(0.55 * math.cos(ang), 0.55 * math.sin(ang), 0.52),
                           rot=(0, 0, ang), parent=root)
        bm = bmesh.new()
        # Curved lotus-arch rib profile extruded along petal curve
        pts = [
            (0.0, 0.0, 0.16, 0.06),
            (0.18, 0.55, 0.22, 0.07),
            (0.10, 1.15, 0.18, 0.06),
            (-0.18, 1.65, 0.09, 0.04),
            (-0.42, 1.90, 0.02, 0.02),
        ]
        rings = []
        for rx, rz, hw, ht in pts:
            r = [
                bm.verts.new((rx - ht, -hw, rz)),
                bm.verts.new((rx + ht, -hw, rz)),
                bm.verts.new((rx + ht, hw, rz)),
                bm.verts.new((rx - ht, hw, rz)),
            ]
            rings.append(r)
        for k in range(len(rings) - 1):
            for s in range(4):
                sn = (s + 1) % 4
                bm.faces.new((rings[k][s], rings[k][sn], rings[k + 1][sn], rings[k + 1][s]))
        bm.faces.new(rings[0][::-1])
        bm.faces.new(rings[-1])
        add_bm(f"PetalBody{i}", bm, m_stone, parent=pivot, smooth=False, bevel=0.018)
        # Gold crest fin on petal tip
        add_cyl(f"PetalTip{i}", 0.07, 0.01, 0.28, 6, m_gold, loc=(-0.38, 0, 1.98), rot=(0, math.radians(-24), 0), parent=pivot, smooth=False, bevel=0.008)

    # Floating Faceted Resonance Crystal Core (rotates and rises on activation!)
    core_pivot = make_empty("ShrineCore", loc=(0, 0, 1.92), parent=root)
    bm_c = bmesh.new()
    bmesh.ops.create_cone(bm_c, cap_ends=True, segments=6, radius1=0.28, radius2=0.01, depth=0.46)
    bm_c2 = bmesh.new()
    bmesh.ops.create_cone(bm_c2, cap_ends=True, segments=6, radius1=0.01, radius2=0.28, depth=0.38)
    for v in bm_c.verts:
        v.co.z += 0.23
    for v in bm_c2.verts:
        v.co.z -= 0.19
    add_bm("CrystalTop", bm_c, m_core, parent=core_pivot, smooth=False, bevel=0.012)
    add_bm("CrystalBot", bm_c2, m_core, parent=core_pivot, smooth=False, bevel=0.012)
    add_torus("CoreHalo", 0.44, 0.025, 24, 8, m_gold, rot=(math.radians(68), 0, 0), parent=core_pivot)

    export_glb("sky_shrine.glb")


def build_sun_shard():
    clear_scene()
    m_gold = make_mat("ShardGold", (1.0, 0.80, 0.26), roughness=0.18, metallic=0.88, emission=(1.0, 0.72, 0.18), emission_strength=1.2)
    m_core = make_mat("ShardCore", (1.0, 0.96, 0.72), roughness=0.05, emission=(1.0, 0.90, 0.45), emission_strength=4.5)

    root = make_empty("SunShardRoot")
    # Faceted double-pyramid star core
    bm = bmesh.new()
    v_top = bm.verts.new((0, 0, 0.55))
    v_bot = bm.verts.new((0, 0, -0.55))
    mid = []
    for i in range(8):
        ang = i * math.pi * 0.25
        rad = 0.30 if i % 2 == 0 else 0.15
        mid.append(bm.verts.new((rad * math.cos(ang), rad * math.sin(ang), 0)))
    for i in range(8):
        inext = (i + 1) % 8
        bm.faces.new((v_top, mid[i], mid[inext]))
        bm.faces.new((v_bot, mid[inext], mid[i]))
    add_bm("StarCore", bm, m_core, parent=root, smooth=False, bevel=0.008)
    add_torus("AstrolabeOuter", 0.58, 0.030, 28, 8, m_gold, rot=(math.radians(72), 0, 0), parent=root)
    add_torus("AstrolabeInner", 0.45, 0.024, 24, 8, m_gold, rot=(math.radians(72), math.radians(60), 0), parent=root)

    export_glb("sun_shard.glb")


def build_tether_orb():
    clear_scene()
    m_pearl = make_mat("OrbPearl", (0.76, 0.95, 1.0), roughness=0.10, emission=(0.48, 0.86, 1.0), emission_strength=3.6, coat=0.8)
    m_gold = make_mat("OrbGold", (0.95, 0.76, 0.30), roughness=0.22, metallic=0.9)

    root = make_empty("TetherOrbRoot")
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.45)
    add_bm("PearlCore", bm, m_pearl, parent=root, smooth=True, bevel=0.0)
    ring1 = make_empty("OrbRing1", parent=root)
    add_torus("HaloA", 0.72, 0.036, 28, 8, m_gold, rot=(math.radians(65), 0, 0), parent=ring1)
    ring2 = make_empty("OrbRing2", parent=root)
    add_torus("HaloB", 0.88, 0.028, 28, 8, m_gold, rot=(math.radians(-55), math.radians(40), 0), parent=ring2)

    export_glb("tether_orb.glb")


def build_world_gate():
    clear_scene()
    m_stone = make_mat("GateStone", (0.62, 0.56, 0.46), roughness=0.58)
    m_accent = make_mat("GateDark", (0.20, 0.19, 0.26), roughness=0.52)
    m_gold = make_mat("GateGold", (0.80, 0.56, 0.16), roughness=0.24, metallic=0.88, emission=(0.82, 0.58, 0.14), emission_strength=0.45)

    root = make_empty("WorldGateRoot")
    # Twin sculpted stepped pillars flanking an 8m-wide monumental archway
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        add_cyl(f"PillarBase{side}", 1.15, 0.95, 0.8, 8, m_accent, loc=(sx * 4.2, 0, 0.4), parent=root, smooth=False, bevel=0.04)
        add_cyl(f"PillarShaft{side}", 0.78, 0.62, 6.4, 8, m_stone, loc=(sx * 4.2, 0, 4.0), parent=root, smooth=False, bevel=0.04)
        add_torus(f"PillarCollar{side}", 0.78, 0.11, 16, 8, m_gold, loc=(sx * 4.2, 0, 7.1), parent=root)
        add_cyl(f"PillarCap{side}", 0.98, 0.45, 0.85, 8, m_stone, loc=(sx * 4.2, 0, 7.6), parent=root, smooth=False, bevel=0.04)

    # Grand Sweeping Semicircular Arch Span (segments of beveled arch stones)
    arch_segs = 14
    for i in range(arch_segs):
        t0 = math.pi * i / arch_segs
        t1 = math.pi * (i + 1) / arch_segs
        tm = 0.5 * (t0 + t1)
        x = 4.2 * math.cos(tm)
        z = 7.2 + 3.8 * math.sin(tm)
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=(0.95, 1.15, 1.05), verts=bm.verts)
        mat = m_gold if (i == 6 or i == 7) else m_stone
        add_bm(f"ArchStone{i}", bm, mat, loc=(x, 0, z), rot=(0, tm - math.pi * 0.5, 0), parent=root, smooth=False, bevel=0.05)

    # Floating Celestial Crown Halo hovering above the keystone
    add_torus("CrownHalo", 1.65, 0.12, 32, 10, m_gold, loc=(0, 0, 12.1), rot=(math.radians(90), 0, 0), parent=root)
    export_glb("world_gate.glb")


if __name__ == "__main__":
    build_sky_shrine()
    build_sun_shard()
    build_tether_orb()
    build_world_gate()
    print("[gen_common_props] All common hero props generated successfully.")
