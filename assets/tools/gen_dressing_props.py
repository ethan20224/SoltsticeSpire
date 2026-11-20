"""
Blender 5.2.1 LTS Route Set-Dressing & MultiMesh Detail Props Generator
Creates compact, richly beveled themed prop clusters for every 3rd platform across all 6 worlds,
plus grass/clover tufts for W1 lawn rims and glowing lantern units for MultiMesh catenary strings!
"""

import os
import math
import bpy
import bmesh

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


def sphere(name, rad, m, loc=(0, 0, 0), u=10, v=7):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=rad, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, smooth=True)


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
    print(f"[gen_dressing_props] Exported {p}")


def build_grass_tuft():
    """Single compact stylized clover/grass + wildflower tuft for W1 MultiMesh rim scatter."""
    clear()
    m_grass = mat("TuftGrass", (0.20, 0.52, 0.20), rough=0.90)
    m_flower = mat("TuftButtercup", (0.98, 0.86, 0.34), rough=0.72)

    bm = bmesh.new()
    for i in range(6):
        a = i * math.pi / 3.0 + (0.2 if i % 2 else 0.0)
        ca, sa = math.cos(a), math.sin(a)
        px, py = -sa, ca
        h = 0.28 + (i % 3) * 0.07
        lean = 0.14 + (i % 2) * 0.06
        w = 0.055
        v0 = bm.verts.new((ca * 0.04 - px * w, sa * 0.04 - py * w, 0.0))
        v1 = bm.verts.new((ca * 0.04 + px * w, sa * 0.04 + py * w, 0.0))
        v2 = bm.verts.new((ca * (0.05 + lean * 0.5) + px * w * 0.7, sa * (0.05 + lean * 0.5) + py * w * 0.7, h * 0.55))
        v3 = bm.verts.new((ca * (0.05 + lean * 0.5) - px * w * 0.7, sa * (0.05 + lean * 0.5) - py * w * 0.7, h * 0.55))
        v4 = bm.verts.new((ca * (0.06 + lean), sa * (0.06 + lean), h))
        bm.faces.new((v0, v1, v2, v3))
        bm.faces.new((v3, v2, v4))
    add_bm("GrassBlades", bm, m_grass, smooth=False)
    sphere("Blossom", (0.055, 0.055, 0.035), m_flower, loc=(0.04, 0.02, 0.28), u=6, v=5)
    save("grass_tuft.glb")


def build_w1_garden_cluster():
    """Terracotta flower box + miniature stone garden lantern + blossoms."""
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
    # Cozy miniature stone garden lantern beside the flower box
    cyl("LanternBase", 0.24, 0.16, 0.55, 6, m_stone, loc=(0.95, 0.05, 0.275), smooth=False)
    cyl("LanternCore", 0.14, 0.14, 0.28, 6, m_glow, loc=(0.95, 0.05, 0.68), smooth=False)
    cyl("LanternRoof", 0.34, 0.05, 0.24, 6, m_stone, loc=(0.95, 0.05, 0.92), smooth=False)
    save("w1_garden_cluster.glb")


def build_w2_forge_cluster():
    """Riveted copper steam barrel + miniature forge brazier + crimson pennant banner."""
    clear()
    m_copper = mat("ForgeCopper", (0.72, 0.36, 0.18), rough=0.34, metal=0.86)
    m_brass = mat("ForgeBrass", (0.86, 0.62, 0.22), rough=0.26, metal=0.90)
    m_iron = mat("ForgeIron", (0.18, 0.16, 0.20), rough=0.45, metal=0.78)
    m_banner = mat("ForgeBanner", (0.68, 0.16, 0.14), rough=0.75)
    m_ember = mat("ForgeEmberGlow", (1.0, 0.58, 0.16), rough=0.14, em=(1.0, 0.52, 0.12), em_s=3.4)

    cyl("Barrel", 0.36, 0.36, 0.85, 10, m_copper, loc=(-0.45, 0.0, 0.425))
    cyl("BarrelBand", 0.39, 0.39, 0.12, 10, m_brass, loc=(-0.45, 0.0, 0.62))
    # Glowing coal brazier bowl on iron tripod
    cyl("BrazierStand", 0.26, 0.18, 0.68, 6, m_iron, loc=(0.45, 0.08, 0.34), smooth=False)
    cyl("BrazierBowl", 0.20, 0.38, 0.26, 8, m_brass, loc=(0.45, 0.08, 0.74))
    sphere("Embers", (0.28, 0.28, 0.18), m_ember, loc=(0.45, 0.08, 0.88))
    # Tall brass banner pole with crimson foundry pennant
    cyl("Pole", 0.05, 0.04, 2.8, 8, m_brass, loc=(-0.05, -0.25, 1.40))
    box("Crossbar", (0.85, 0.06, 0.06), m_brass, loc=(-0.05, -0.25, 2.55), bevel=0.008)
    box("Pennant", (0.72, 0.04, 1.45), m_banner, loc=(-0.05, -0.25, 1.80), bevel=0.006)
    save("w2_forge_cluster.glb")


def build_w3_monsoon_cluster():
    """Warm glowing shoji wooden lantern pedestal + cedar rain barrel + wind banner."""
    clear()
    m_wood = mat("MonWood", (0.24, 0.14, 0.10), rough=0.52)
    m_red = mat("MonRed", (0.74, 0.16, 0.14), rough=0.40)
    m_gold = mat("MonGold", (0.90, 0.70, 0.26), rough=0.26, metal=0.86)
    m_glow = mat("MonShojiGlow", (1.0, 0.66, 0.30), rough=0.22, em=(1.0, 0.62, 0.24), em_s=1.70)

    cyl("StandBase", 0.28, 0.18, 0.72, 8, m_wood, loc=(0.35, 0.0, 0.36), smooth=False)
    box("ShojiLamp", (0.38, 0.38, 0.52), m_glow, loc=(0.35, 0.0, 0.96), bevel=0.015)
    # Dark wood shoji grid bars over the lantern box
    for side_a in (0.0, math.pi * 0.5):
        box(f"LampBar_{side_a}", (0.42, 0.42, 0.05), m_wood, loc=(0.35, 0.0, 0.96), rot=(0, 0, side_a), bevel=0.005)
    cyl("ShojiRoof", 0.48, 0.08, 0.26, 4, m_red, loc=(0.35, 0.0, 1.34), rot=(0, 0, math.pi * 0.25), smooth=False)
    cyl("RainBarrel", 0.34, 0.38, 0.65, 10, m_wood, loc=(-0.48, 0.10, 0.325))
    cyl("BannerPole", 0.045, 0.035, 2.6, 8, m_red, loc=(-0.10, -0.22, 1.30))
    box("WindBanner", (0.58, 0.04, 1.30), m_red, loc=(-0.10, -0.22, 1.75), bevel=0.005)
    box("BannerTrim", (0.60, 0.05, 0.12), m_gold, loc=(-0.10, -0.22, 1.12), bevel=0.005)
    save("w3_monsoon_cluster.glb")


def build_w4_gallery_cluster():
    """Gilded standing mirror + baroque warm glowing candelabra + lavender crystal spire."""
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
    """Stacked antique leather books + warm brass reading floor lamp + celestial desk globe."""
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
    """Obsidian & liquid-gold temple brazier with fire grate & radiant warm amber fire bowl."""
    clear()
    m_obs = mat("BrazObs", (0.09, 0.08, 0.16), rough=0.22, metal=0.40)
    m_gold = mat("BrazGold", (0.92, 0.70, 0.24), rough=0.20, metal=0.92)
    m_flame = mat("BrazFlameGlow", (1.0, 0.62, 0.20), rough=0.14, em=(1.0, 0.58, 0.16), em_s=1.85)

    cyl("PedBase", 0.42, 0.28, 0.26, 8, m_obs, loc=(0, 0, 0.13), smooth=False)
    cyl("PedShaft", 0.22, 0.16, 0.82, 8, m_obs, loc=(0, 0, 0.65), smooth=False)
    cyl("Bowl", 0.22, 0.54, 0.34, 12, m_gold, loc=(0, 0, 1.18))
    sphere("FireCore", (0.28, 0.28, 0.34), m_flame, loc=(0, 0, 1.42))
    for k in range(4):
        a = k * math.pi * 0.5
        box(f"CageRib_{k}", (0.06, 0.06, 0.42), m_obs, loc=(0.32 * math.cos(a), 0.32 * math.sin(a), 1.46), rot=(0, -0.25 if k % 2 == 0 else 0.25, a))
    save("w6_solar_brazier.glb")


def build_lantern_unit():
    """Compact 0.34m 16-segment ribbed washi-paper lantern globe + dark finials for MultiMesh strings."""
    clear()
    m_glow = mat("LanUnitGlow", (1.0, 0.66, 0.32), rough=0.35, em=(1.0, 0.62, 0.26), em_s=1.75)
    bm = bmesh.new()
    # 16-segment ribbed paper lantern (~0.32m diameter, 0.36m tall)
    segs = 16
    rings_p = [
        (0.02, -0.19),
        (0.11, -0.17),
        (0.15, -0.11),
        (0.165, -0.05),
        (0.158, 0.0),   # subtle rib indentation
        (0.168, 0.05),
        (0.15, 0.11),
        (0.11, 0.17),
        (0.02, 0.19),
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
    build_w1_garden_cluster()
    build_w2_forge_cluster()
    build_w3_monsoon_cluster()
    build_w4_gallery_cluster()
    build_w5_reading_cluster()
    build_w6_solar_brazier()
    build_lantern_unit()
    print("[gen_dressing_props] All route set-dressing props generated!")
