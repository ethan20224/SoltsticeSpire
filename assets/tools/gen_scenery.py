"""
Blender 5.2.1 LTS Environmental Storytelling Scenery Generator
Creates rich, sculpted stylized sky-scenery assets to populate all 6 ascending worlds:
  1. cloud_puff.glb             - Fluffy multi-lobe Ghibli stylized cumulus cloud cluster
  2. garden_tree.glb            - Stylized Conservatory bonsai/canopy tree in carved terracotta urn
  3. floating_spire_rock.glb    - Sculpted floating ruin islet with tapered rock spire & carved top
  4. lantern_garland.glb        - Graceful curved cord of 5 glowing festival paper lanterns (World 3)
  5. hanging_chain_bell.glb     - Dramatic suspended vertical brass foundry chain & ornament (World 2)
"""

import os
import math
import bpy
import bmesh

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


def sphere(name, radii, m, loc=(0, 0, 0), u=14, v=10, subsurf=1):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=radii, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, smooth=True, subsurf=subsurf)


def cyl(name, r1, r2, h, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.03):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel)


def save(fname):
    p = os.path.join(OUT_DIR, fname)
    bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[gen_scenery] Exported {p}")


def build_cloud_puff():
    clear()
    m_cloud = mat("CloudCream", (0.86, 0.88, 0.92), rough=0.88)
    # Sculpted Ghibli billowy flat-bottomed cumulus cloud cluster!
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
                v.co.z = -0.15 + (v.co.z + 0.15) * 0.28  # Soft flat cumulus cloud base!
            v.co.x *= rad[0]
            v.co.y *= rad[1]
            v.co.z *= rad[2]
        add_bm(f"Puff{i}", bm, m_cloud, loc=loc, smooth=True, subsurf=1)
    save("cloud_puff.glb")


def build_garden_tree():
    clear()
    m_terra = mat("UrnTerra", (0.52, 0.17, 0.09), rough=0.55)
    m_gold = mat("UrnGold", (0.72, 0.48, 0.14), rough=0.28, metal=0.82)
    m_bark = mat("TreeBark", (0.24, 0.13, 0.08), rough=0.72)
    m_leaf_d = mat("LeafDeep", (0.07, 0.30, 0.12), rough=0.62)
    m_leaf_l = mat("LeafSun", (0.14, 0.46, 0.16), rough=0.58)
    m_blossom = mat("BlossomGold", (0.94, 0.68, 0.18), rough=0.32, em=(0.85, 0.55, 0.12), em_s=0.45)

    # Carved terracotta planter urn
    cyl("UrnBody", 0.52, 0.72, 0.85, 8, m_terra, loc=(0, 0, 0.42), bevel=0.04)
    cyl("UrnLip", 0.78, 0.78, 0.16, 8, m_gold, loc=(0, 0, 0.88), bevel=0.03)
    # Sculpted curved trunk & branches
    cyl("TrunkA", 0.22, 0.14, 1.8, 8, m_bark, loc=(0, 0, 1.65), rot=(0.08, -0.06, 0), smooth=True, bevel=0.02)
    cyl("BranchL", 0.12, 0.07, 1.2, 6, m_bark, loc=(-0.45, 0.1, 2.55), rot=(0.15, -0.58, 0), smooth=True, bevel=0.01)
    cyl("BranchR", 0.12, 0.07, 1.1, 6, m_bark, loc=(0.48, -0.1, 2.45), rot=(-0.12, 0.62, 0), smooth=True, bevel=0.01)
    # Lush Ghibli layered canopy puffs!
    sphere("CanopyMain", (1.25, 1.15, 0.82), m_leaf_l, loc=(0.0, 0.0, 3.25))
    sphere("CanopyL", (0.92, 0.85, 0.62), m_leaf_d, loc=(-0.95, 0.22, 2.85))
    sphere("CanopyR", (0.88, 0.82, 0.58), m_leaf_d, loc=(0.95, -0.18, 2.75))
    sphere("CanopyTop", (0.78, 0.75, 0.55), m_leaf_l, loc=(0.12, 0.10, 3.85))
    for i, pos in enumerate([(-0.8, 0.5, 3.1), (0.7, 0.4, 3.0), (0.1, -0.6, 3.5), (-0.2, 0.6, 3.8)]):
        sphere(f"Blossom{i}", (0.18, 0.18, 0.16), m_blossom, loc=pos, u=8, v=6, subsurf=0)
    save("garden_tree.glb")


def build_floating_spire_rock():
    clear()
    m_stone = mat("IsletStone", (0.58, 0.52, 0.42), rough=0.68)
    m_terra = mat("IsletTerra", (0.52, 0.19, 0.11), rough=0.60)
    m_moss = mat("IsletMoss", (0.10, 0.38, 0.15), rough=0.72)

    cyl("TopCap", 2.8, 3.0, 0.55, 7, m_moss, loc=(0, 0, -0.28), bevel=0.06)
    cyl("MidRock", 1.9, 2.8, 2.2, 7, m_stone, loc=(0, 0, -1.65), bevel=0.08)
    cyl("DeepSpire", 0.25, 1.85, 4.6, 7, m_terra, loc=(0, 0, -5.0), bevel=0.06)
    # Miniature ruin column on top for silhouette storytelling
    cyl("RuinCol1", 0.32, 0.28, 2.4, 8, m_stone, loc=(-0.9, 0.5, 1.15), bevel=0.03)
    cyl("RuinCol2", 0.30, 0.26, 1.4, 8, m_stone, loc=(0.8, -0.4, 0.65), bevel=0.03)
    save("floating_spire_rock.glb")


def build_lantern_garland():
    clear()
    m_cord = mat("CordDark", (0.12, 0.08, 0.08), rough=0.6)
    m_glow = mat("GarlandGlow", (0.98, 0.58, 0.14), rough=0.25, em=(1.0, 0.58, 0.14), em_s=2.4)
    m_cap = mat("GarlandCap", (0.16, 0.09, 0.08), rough=0.45)

    for i in range(5):
        t = (i / 4.0) * 2.0 - 1.0  # -1..1
        x = t * 5.2
        z = -1.6 * (1.0 - t * t)
        cyl(f"Lantern{i}", 0.42, 0.36, 0.92, 8, m_glow, loc=(x, 0, z - 0.6), bevel=0.04)
        cyl(f"CapT{i}", 0.48, 0.28, 0.16, 8, m_cap, loc=(x, 0, z - 0.08), bevel=0.02)
        cyl(f"CapB{i}", 0.28, 0.44, 0.14, 8, m_cap, loc=(x, 0, z - 1.12), bevel=0.02)
    # Curved catenary cord segments
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
    build_garden_tree()
    build_floating_spire_rock()
    build_lantern_garland()
    build_hanging_chain_bell()
    print("[gen_scenery] All environmental storytelling scenery assets generated!")
