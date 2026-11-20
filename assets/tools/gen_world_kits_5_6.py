"""
Blender 5.2.1 LTS Asset Kit Generator - Worlds 5 & 6 (v2 Polish)
  World 5 (The Cloud-Whale Library): opal_whale_rib, floating_bookshelf, luminous_tome, dream_jelly_pad
  World 6 (The Crown of the Sun): obsidian_monolith, obsidian_dais, delicate open-work brass solar_ring, summit_crown_altar
"""

import os
import math
import bpy
import bmesh

OUT_W5 = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/world5_library"
OUT_W6 = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/world6_crown"
os.makedirs(OUT_W5, exist_ok=True)
os.makedirs(OUT_W6, exist_ok=True)


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, col, rough=0.45, metal=0.0, em=None, em_s=0.0, coat=0.0):
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


def add_bm(name, bm, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.03):
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
    return obj


def box(name, sz, m, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.04):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=sz, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=False, bevel=bevel)


def cyl(name, r1, r2, h, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.03):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel)


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
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=True, bevel=0.0)


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


def save(out_dir, fname):
    join_by_material()
    p = os.path.join(out_dir, fname)
    bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[world_kits_5_6] Exported {p}")


def gen_w5():
    # 1. Colossal Continuous Tapered Opal Levitating Cloud-Whale Rib Arch
    clear()
    m_opal = mat("WhaleOpal", (0.42, 0.74, 0.84), rough=0.18, em=(0.12, 0.44, 0.62), em_s=0.45, coat=0.85)
    m_aurora = mat("WhaleAurora", (0.18, 0.86, 0.76), rough=0.12, em=(0.14, 0.78, 0.72), em_s=1.35)

    bm = bmesh.new()
    segs = 26
    rad_segs = 10
    rings = []
    for i in range(segs + 1):
        u = i / segs
        t = math.pi * (0.05 + 0.90 * u)
        cx = 10.2 * math.cos(t)
        cz = 11.8 * math.sin(t)
        tx, tz = -10.2 * math.sin(t), 11.8 * math.cos(t)
        tl = math.hypot(tx, tz)
        nx, nz = tz / tl, -tx / tl
        r_local = 0.22 + 0.72 * math.sin(u * math.pi)
        ring = []
        for s in range(rad_segs):
            ang = 2.0 * math.pi * s / rad_segs
            ox = nx * math.cos(ang) * r_local
            oz = nz * math.cos(ang) * r_local
            oy = math.sin(ang) * r_local * 0.68
            ring.append(bm.verts.new((cx + ox, oy, cz + oz)))
        rings.append(ring)
    for i in range(segs):
        for s in range(rad_segs):
            sn = (s + 1) % rad_segs
            bm.faces.new((rings[i][s], rings[i][sn], rings[i + 1][sn], rings[i + 1][s]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[-1])
    add_bm("WhaleRibSweep", bm, m_opal, smooth=True, bevel=0.0)

    for i in (7, 10, 13, 16, 19):
        u = i / segs
        t = math.pi * (0.05 + 0.90 * u)
        cx, cz = 10.2 * math.cos(t), 11.8 * math.sin(t)
        cyl(f"SpineCrystal{i}", 0.28, 0.03, 1.45, 6, m_aurora, loc=(cx, 0, cz + 0.85), rot=(0, math.pi * 0.5 - t, 0), bevel=0.02)
    save(OUT_W5, "opal_whale_rib.glb")

    # 2. Floating Curved Sky-Library Balcony & Bookshelf
    clear()
    m_wood = mat("LibWood", (0.24, 0.14, 0.12), rough=0.42, coat=0.30)
    m_brass = mat("LibBrass", (0.90, 0.72, 0.30), rough=0.25, metal=0.88)
    m_carpet = mat("LibIndigo", (0.16, 0.20, 0.44), rough=0.72)
    book_mats = [
        mat("BookRed", (0.72, 0.20, 0.24), rough=0.5),
        mat("BookTeal", (0.16, 0.54, 0.58), rough=0.5),
        mat("BookGold", (0.82, 0.62, 0.22), rough=0.38, metal=0.45),
        mat("BookPlum", (0.42, 0.24, 0.52), rough=0.5),
    ]

    box("FloorDeck", (5.2, 4.4, 0.48), m_wood, loc=(0, 0, -0.24), bevel=0.05)
    box("Carpet", (4.3, 3.5, 0.06), m_carpet, loc=(0, 0, -0.01), bevel=0.02)
    box("BrassTrim", (5.35, 4.55, 0.14), m_brass, loc=(0, 0, -0.08), bevel=0.02)
    box("ShelfBack", (4.8, 0.42, 4.2), m_wood, loc=(0, -1.95, 2.0), bevel=0.04)
    for row in range(4):
        rz = 0.55 + row * 0.95
        box(f"Shelf{row}", (4.6, 0.62, 0.14), m_brass, loc=(0, -1.80, rz), bevel=0.02)
        for bi in range(11):
            bx = -2.0 + bi * 0.40
            bh = 0.58 + ((bi * 7 + row * 3) % 4) * 0.07
            bm_sel = book_mats[(bi + row * 2) % len(book_mats)]
            box(f"Book_{row}_{bi}", (0.28, 0.42, bh), bm_sel, loc=(bx, -1.78, rz + bh * 0.5 + 0.06), bevel=0.015)
    save(OUT_W5, "floating_bookshelf.glb")

    # 3. Giant Open Luminous Tome Platform
    clear()
    m_cover = mat("TomeCover", (0.18, 0.15, 0.36), rough=0.40, coat=0.35)
    m_page = mat("TomePages", (0.98, 0.95, 0.86), rough=0.55, em=(0.88, 0.86, 0.74), em_s=0.30)
    m_gold = mat("TomeGold", (0.96, 0.76, 0.28), rough=0.24, metal=0.88)
    m_rune = mat("TomeRune", (1.0, 0.78, 0.34), rough=0.1, em=(1.0, 0.72, 0.26), em_s=2.8)

    box("CoverL", (1.92, 2.85, 0.22), m_cover, loc=(-0.98, 0, -0.26), rot=(0, math.radians(-4), 0), bevel=0.03)
    box("CoverR", (1.92, 2.85, 0.22), m_cover, loc=(0.98, 0, -0.26), rot=(0, math.radians(4), 0), bevel=0.03)
    box("Spine", (0.36, 2.88, 0.28), m_gold, loc=(0, 0, -0.32), bevel=0.03)
    box("PagesL", (1.76, 2.60, 0.24), m_page, loc=(-0.92, 0, -0.10), rot=(0, math.radians(-3), 0), bevel=0.03)
    box("PagesR", (1.76, 2.60, 0.24), m_page, loc=(0.92, 0, -0.10), rot=(0, math.radians(3), 0), bevel=0.03)
    box("RuneLineL", (1.1, 0.14, 0.04), m_rune, loc=(-0.92, 0.3, 0.03), bevel=0.01)
    box("RuneLineR", (1.1, 0.14, 0.04), m_rune, loc=(0.92, -0.2, 0.03), bevel=0.01)
    save(OUT_W5, "luminous_tome.glb")

    # 4. Translucent Bioluminescent Cloud-Jellyfish Bounce Pad
    clear()
    m_bell = mat("JellyBell", (0.16, 0.56, 0.84), rough=0.14, em=(0.10, 0.45, 0.78), em_s=0.65, coat=0.9)
    m_core = mat("JellyCore", (0.62, 0.28, 0.92), rough=0.12, em=(0.56, 0.24, 0.88), em_s=1.4)

    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=12, radius=1.0)
    for v in bm.verts:
        if v.co.z < 0.0:
            v.co.z *= 0.22
        v.co.x *= 2.4
        v.co.y *= 2.4
        v.co.z *= 0.85
    add_bm("BellDome", bm, m_bell, loc=(0, 0, -0.45), smooth=True, bevel=0.0)
    torus("BellRim", 2.25, 0.16, 24, 8, m_core, loc=(0, 0, -0.52))
    for i in range(6):
        a = i * math.pi / 3.0
        cyl(f"Tendril{i}", 0.08, 0.16, 2.6, 8, m_core,
            loc=(1.1 * math.cos(a), 1.1 * math.sin(a), -1.8), smooth=True, bevel=0.01)
    save(OUT_W5, "dream_jelly_pad.glb")


def gen_w6():
    # 1. Fluted Obsidian & Liquid-Gold Wall-Run Monolith
    clear()
    m_obs = mat("Obsidian", (0.09, 0.08, 0.14), rough=0.18, metal=0.35, coat=0.85)
    m_gold = mat("LiquidGold", (1.0, 0.78, 0.28), rough=0.16, metal=0.92, em=(1.0, 0.70, 0.20), em_s=2.4)

    box("MonolithBody", (9.4, 0.78, 4.5), m_obs, loc=(0, 0, 0), bevel=0.08)
    box("CrownBar", (9.7, 0.96, 0.36), m_gold, loc=(0, 0, 2.28), bevel=0.04)
    box("BaseBar", (9.7, 0.96, 0.36), m_gold, loc=(0, 0, -2.28), bevel=0.04)
    for i in range(-3, 4):
        box(f"GoldStripe{i}", (0.28, 0.88, 3.8), m_gold, loc=(i * 1.25, 0, 0), rot=(0, math.radians(15), 0), bevel=0.02)
    save(OUT_W6, "obsidian_monolith.glb")

    # 2. Stepped Obsidian & Liquid-Gold Sundial Dais
    clear()
    m_obs = mat("DaisObs", (0.10, 0.09, 0.16), rough=0.20, metal=0.35, coat=0.80)
    m_gold = mat("DaisGold", (1.0, 0.78, 0.28), rough=0.18, metal=0.92, em=(1.0, 0.70, 0.22), em_s=1.8)

    cyl("TopDisc", 2.95, 3.05, 0.44, 12, m_obs, loc=(0, 0, -0.22), bevel=0.05)
    torus("OuterGold", 2.95, 0.10, 32, 8, m_gold, loc=(0, 0, -0.02))
    torus("InnerGold", 1.55, 0.06, 24, 8, m_gold, loc=(0, 0, -0.01))
    cyl("LowerTier", 1.75, 2.55, 1.15, 12, m_obs, loc=(0, 0, -1.00), bevel=0.05)
    cyl("UnderPoint", 0.30, 1.55, 1.85, 8, m_obs, loc=(0, 0, -2.45), bevel=0.04)
    save(OUT_W6, "obsidian_dais.glb")

    # 3. OVERHAULED Delicate Open-Work Filigreed Astronomical Brass Armillary Ring
    # (Replaces the bulky dark brown "baton" tube in Shot 09 completely!)
    clear()
    m_brass = mat("ArmillaryBrass", (0.86, 0.64, 0.22), rough=0.22, metal=0.92)
    m_copper = mat("ArmillaryCopper", (0.72, 0.40, 0.18), rough=0.28, metal=0.86)
    m_gem = mat("ArmillarySunGem", (1.0, 0.78, 0.32), rough=0.10, em=(1.0, 0.72, 0.24), em_s=3.0)

    # Twin slender open-work meridian rails separated by engraved degree ticks!
    torus("OuterRail", 18.8, 0.16, 64, 8, m_brass, loc=(0, 0, 0.32))
    torus("InnerRail", 18.8, 0.16, 64, 8, m_brass, loc=(0, 0, -0.32))
    torus("EquatorWire", 17.8, 0.10, 64, 6, m_copper, loc=(0, 0, 0.0))

    # 32 delicate open-work astronomical degree ticks + 8 gilded compass finials with glowing sun-gems!
    for i in range(32):
        a = i * math.tau / 32.0
        ca, sa = math.cos(a), math.sin(a)
        if i % 4 == 0:
            # Ornate slender compass medallion & glowing amber jewel
            torus(f"CompassRing_{i}", 0.82, 0.10, 18, 6, m_brass, loc=(18.8 * ca, 18.8 * sa, 0), rot=(math.radians(90), 0, a))
            cyl(f"CompassSpire_{i}", 0.22, 0.02, 2.6, 6, m_brass, loc=(18.8 * ca, 18.8 * sa, 1.65), bevel=0.01)
            cyl(f"CompassDrop_{i}", 0.02, 0.22, 2.2, 6, m_brass, loc=(18.8 * ca, 18.8 * sa, -1.45), bevel=0.01)
            bm_g = bmesh.new()
            bmesh.ops.create_icosphere(bm_g, subdivisions=1, radius=0.45)
            add_bm(f"SunGem_{i}", bm_g, m_gem, loc=(18.8 * ca, 18.8 * sa, 0), smooth=False, bevel=0.0)
        else:
            box(f"Tick_{i}", (0.14, 0.14, 0.68), m_copper, loc=(18.8 * ca, 18.8 * sa, 0), rot=(0, 0, a), bevel=0.01)
            box(f"Strut_{i}", (0.95, 0.09, 0.09), m_brass, loc=(18.3 * ca, 18.3 * sa, 0), rot=(0, 0, a), bevel=0.01)
    save(OUT_W6, "solar_ring.glb")

    # 4. Summit Crown Sanctuary Altar (radius 9.5m terraced overlook + fire-grated amber temple braziers!)
    clear()
    m_marble = mat("SummitMarble", (0.78, 0.74, 0.66), rough=0.28, coat=0.45)
    m_obs = mat("SummitObs", (0.07, 0.06, 0.13), rough=0.20, metal=0.40, coat=0.80)
    m_gold = mat("SummitGold", (0.88, 0.65, 0.20), rough=0.16, metal=0.95, em=(0.90, 0.62, 0.16), em_s=0.45)
    m_sun = mat("SummitSunGlow", (1.0, 0.66, 0.24), rough=0.12, em=(1.0, 0.60, 0.18), em_s=1.85)

    cyl("OuterTerrace", 9.6, 9.8, 0.85, 16, m_obs, loc=(0, 0, -0.425), bevel=0.08)
    cyl("InnerTerrace", 6.8, 7.0, 0.38, 16, m_marble, loc=(0, 0, 0.19), bevel=0.05)
    torus("GoldRimOuter", 9.65, 0.18, 48, 10, m_gold, loc=(0, 0, 0.02))
    torus("GoldRimInner", 6.85, 0.14, 36, 10, m_gold, loc=(0, 0, 0.38))
    cyl("UnderBase", 2.2, 8.6, 4.5, 16, m_obs, loc=(0, 0, -3.1), bevel=0.08)

    # 8 Slender Celestial Crown Spires + Grated Warm Amber Temple Braziers between spires!
    for i in range(8):
        a = i * math.pi * 0.25 + math.pi * 0.125
        rx, ry = 8.4 * math.cos(a), 8.4 * math.sin(a)
        cyl(f"Spire{i}", 0.48, 0.10, 7.6, 6, m_obs, loc=(rx, ry, 3.8), bevel=0.04)
        cyl(f"SpireGold{i}", 0.24, 0.03, 2.2, 6, m_gold, loc=(rx, ry, 8.4), bevel=0.02)
        ba = a + math.pi * 0.125
        bx, by = 8.3 * math.cos(ba), 8.3 * math.sin(ba)
        cyl(f"BrazBase{i}", 0.36, 0.24, 0.95, 8, m_obs, loc=(bx, by, 0.48), bevel=0.02)
        cyl(f"BrazCup{i}", 0.24, 0.48, 0.30, 10, m_gold, loc=(bx, by, 1.05), bevel=0.02)
        bm_f = bmesh.new()
        bmesh.ops.create_icosphere(bm_f, subdivisions=1, radius=0.26)
        add_bm(f"BrazFlame{i}", bm_f, m_sun, loc=(bx, by, 1.28), smooth=True, bevel=0.0)
        # Dark obsidian fire-cage ribs + cap around the flame so it never looks like a white ball!
        for r_i in range(4):
            ra = r_i * math.pi * 0.5
            box(f"BrazRib_{i}_{r_i}", (0.06, 0.06, 0.44), m_obs,
                loc=(bx + 0.28 * math.cos(ra), by + 0.28 * math.sin(ra), 1.32), rot=(0, 0, ra))
        cyl(f"BrazCap_{i}", 0.34, 0.08, 0.16, 8, m_gold, loc=(bx, by, 1.56), bevel=0.01)

    torus("SummitHaloA", 5.5, 0.14, 48, 8, m_gold, loc=(0, 0, 10.5), rot=(math.radians(15), 0, 0))
    torus("SummitHaloB", 3.8, 0.11, 40, 8, m_gold, loc=(0, 0, 10.5), rot=(math.radians(-22), math.radians(30), 0))
    bm_s = bmesh.new()
    bmesh.ops.create_icosphere(bm_s, subdivisions=2, radius=1.25)
    add_bm("SummitSunOrb", bm_s, m_sun, loc=(0, 0, 10.5), smooth=True, bevel=0.0)
    save(OUT_W6, "summit_crown_altar.glb")


if __name__ == "__main__":
    gen_w5()
    gen_w6()
    print("[world_kits_5_6] Worlds 5 & 6 kits complete!")
