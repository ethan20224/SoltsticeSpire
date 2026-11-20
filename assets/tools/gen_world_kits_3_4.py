"""
Blender 5.2.1 LTS Asset Kit Generator - Worlds 3 & 4
  World 3 (The Origami Monsoon): origami_crane, silk_parasol, pagoda_eave, folded_tile, paper_lantern
  World 4 (The Shattered Mirror Gallery): gilded_portal_frame, marble_stair_arch, crystal_prism, mirror_wall_panel, shatter_pane
"""

import os
import math
import bpy
import bmesh

OUT_W3 = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/world3_monsoon"
OUT_W4 = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/world4_mirrors"
os.makedirs(OUT_W3, exist_ok=True)
os.makedirs(OUT_W4, exist_ok=True)


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


def add_bm(name, bm, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.025):
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


def box(name, sz, m, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.035):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=sz, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=False, bevel=bevel)


def cyl(name, r1, r2, h, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.025):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel)


def save(out_dir, fname):
    p = os.path.join(out_dir, fname)
    bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[world_kits_3_4] Exported {p}")


# ==============================================================================
# WORLD 3 - THE ORIGAMI MONSOON
# ==============================================================================
def gen_w3():
    # 1. Giant Monumental Folded Origami Crane (wingspan ~10m, crisp sculptural facets!)
    clear()
    m_paper = mat("CranePaper", (0.97, 0.94, 0.87), rough=0.52)
    m_gold = mat("CraneGold", (0.96, 0.76, 0.28), rough=0.25, metal=0.82, em=(0.96, 0.72, 0.20), em_s=0.4)
    m_crimson = mat("CraneRed", (0.86, 0.24, 0.22), rough=0.45)

    # Faceted diamond origami body
    bm = bmesh.new()
    v_f = bm.verts.new((0, 2.2, 0.1))
    v_b = bm.verts.new((0, -2.0, 0.2))
    v_l = bm.verts.new((-1.2, 0.0, 0.0))
    v_r = bm.verts.new((1.2, 0.0, 0.0))
    v_t = bm.verts.new((0, 0.0, 1.0))
    v_d = bm.verts.new((0, 0.0, -0.85))
    for f in [(v_f, v_r, v_t), (v_r, v_b, v_t), (v_b, v_l, v_t), (v_l, v_f, v_t),
              (v_f, v_d, v_r), (v_r, v_d, v_b), (v_b, v_d, v_l), (v_l, v_d, v_f)]:
        bm.faces.new(f)
    add_bm("CraneBody", bm, m_paper, bevel=0.02)

    # Sweeping folded origami wings (L & R)
    for sx in (-1.0, 1.0):
        wb = bmesh.new()
        w0 = wb.verts.new((sx * 0.9, 1.2, 0.15))
        w1 = wb.verts.new((sx * 0.9, -1.2, 0.20))
        w2 = wb.verts.new((sx * 5.2, -0.4, 1.65))
        w3 = wb.verts.new((sx * 2.8, 0.3, 0.85))
        w_bot = wb.verts.new((sx * 2.8, 0.1, 0.45))
        wb.faces.new((w0, w3, w2))
        wb.faces.new((w3, w1, w2))
        wb.faces.new((w0, w1, w3))
        wb.faces.new((w0, w2, w_bot))
        wb.faces.new((w2, w1, w_bot))
        wb.faces.new((w1, w0, w_bot))
        add_bm(f"CraneWing{sx}", wb, m_paper, bevel=0.02)
    # Neck, folded head/beak & upright tail spire
    cyl("Neck", 0.35, 0.18, 2.8, 4, m_paper, loc=(0, 2.4, 1.2), rot=(math.radians(-35), 0, 0), bevel=0.02)
    cyl("HeadBeak", 0.22, 0.03, 1.3, 4, m_crimson, loc=(0, 3.6, 2.2), rot=(math.radians(-108), 0, 0), bevel=0.015)
    cyl("TailSpire", 0.42, 0.08, 3.2, 4, m_gold, loc=(0, -2.5, 1.4), rot=(math.radians(38), 0, 0), bevel=0.02)
    save(OUT_W3, "origami_crane.glb")

    # 2. Glowing Pleated Silk Parasol Bounce Pad (radius 2.4m, walkable canopy dome peak near Z=0)
    clear()
    m_silk = mat("ParasolVermilion", (0.88, 0.22, 0.20), rough=0.38, em=(0.82, 0.20, 0.16), em_s=0.45)
    m_cream = mat("ParasolCream", (0.98, 0.93, 0.82), rough=0.45, em=(0.95, 0.86, 0.62), em_s=0.35)
    m_gold = mat("ParasolGold", (0.94, 0.74, 0.28), rough=0.24, metal=0.86)
    m_wood = mat("ParasolBamboo", (0.36, 0.22, 0.12), rough=0.52)

    cyl("CanopyOuter", 2.45, 0.45, 0.65, 16, m_silk, loc=(0, 0, -0.32), bevel=0.03)
    cyl("CanopyCrown", 1.20, 0.20, 0.28, 16, m_cream, loc=(0, 0, -0.08), bevel=0.02)
    cyl("Finial", 0.16, 0.04, 0.32, 8, m_gold, loc=(0, 0, 0.14), bevel=0.01)
    cyl("Handle", 0.09, 0.09, 2.4, 8, m_wood, loc=(0, 0, -1.5), bevel=0.01)
    cyl("LanternBob", 0.26, 0.22, 0.42, 8, m_cream, loc=(0, 0, -2.7), bevel=0.02)
    save(OUT_W3, "silk_parasol.glb")

    # 3. Floating Pagoda Teahouse Roof Platform (5.6m × 5.6m walkable crown at Z=0!)
    clear()
    m_tile = mat("PagodaTeal", (0.12, 0.42, 0.48), rough=0.34, coat=0.45)
    m_red = mat("PagodaLacquer", (0.78, 0.20, 0.18), rough=0.30, coat=0.50)
    m_gold = mat("PagodaGold", (0.94, 0.76, 0.30), rough=0.24, metal=0.86)
    m_lantern = mat("PagodaGlow", (1.0, 0.82, 0.36), rough=0.2, em=(1.0, 0.72, 0.24), em_s=4.0)

    box("RoofDeck", (5.4, 5.4, 0.45), m_tile, loc=(0, 0, -0.225), bevel=0.05)
    box("LacquerFrame", (4.6, 4.6, 0.95), m_red, loc=(0, 0, -0.92), bevel=0.05)
    box("LowerEave", (6.2, 6.2, 0.26), m_tile, loc=(0, 0, -1.42), bevel=0.04)
    # 4 Upturned Corner Eave Spires + Glowing Hanging Paper Lanterns!
    for sx in (-2.75, 2.75):
        for sy in (-2.75, 2.75):
            box(f"Horn_{sx}_{sy}", (0.65, 0.65, 0.35), m_gold,
                loc=(sx, sy, 0.12), rot=(sy * 0.12, -sx * 0.12, 0), bevel=0.03)
            cyl(f"Lantern_{sx}_{sy}", 0.30, 0.24, 0.62, 8, m_lantern,
                loc=(sx * 0.98, sy * 0.98, -1.95), bevel=0.03)
    save(OUT_W3, "pagoda_eave.glb")

    # 4. Crisp Origami Folding Bridge Tile (3.5m × 3.5m × 0.28m, top at Z=0)
    clear()
    m_paper = mat("FoldPaper", (0.97, 0.94, 0.86), rough=0.50)
    m_gold = mat("FoldGold", (0.95, 0.75, 0.28), rough=0.26, metal=0.80, em=(0.95, 0.72, 0.24), em_s=0.45)

    box("PaperBase", (3.5, 3.5, 0.26), m_paper, loc=(0, 0, -0.13), bevel=0.03)
    box("GoldFoldA", (3.55, 0.14, 0.30), m_gold, loc=(0, 0, -0.13), rot=(0, 0, math.radians(45)), bevel=0.015)
    box("GoldFoldB", (3.55, 0.14, 0.30), m_gold, loc=(0, 0, -0.13), rot=(0, 0, math.radians(-45)), bevel=0.015)
    save(OUT_W3, "folded_tile.glb")

    # 5. Floating Festival Paper Lantern Landmark
    clear()
    m_glow = mat("FestGlow", (1.0, 0.78, 0.32), rough=0.25, em=(1.0, 0.68, 0.22), em_s=3.8)
    m_frame = mat("FestWood", (0.28, 0.14, 0.12), rough=0.48)
    m_gold = mat("FestGold", (0.94, 0.74, 0.28), rough=0.25, metal=0.85)

    cyl("Body", 0.95, 0.85, 2.2, 8, m_glow, loc=(0, 0, 0), bevel=0.05)
    cyl("CapTop", 1.15, 0.60, 0.36, 8, m_frame, loc=(0, 0, 1.24), bevel=0.03)
    cyl("CapBot", 0.60, 1.05, 0.32, 8, m_frame, loc=(0, 0, -1.22), bevel=0.03)
    cyl("Tassel", 0.12, 0.26, 0.95, 8, m_gold, loc=(0, 0, -1.85), bevel=0.02)
    save(OUT_W3, "paper_lantern.glb")


# ==============================================================================
# WORLD 4 - THE SHATTERED MIRROR GALLERY
# ==============================================================================
def gen_w4():
    # 1. Ornate Baroque Gilded Picture-Frame Portal (aperture 3.6m wide × 4.6m tall, base at Z=0!)
    clear()
    m_gold = mat("FrameGold", (0.96, 0.78, 0.30), rough=0.22, metal=0.90)
    m_rose = mat("FrameRose", (0.90, 0.56, 0.66), rough=0.28, metal=0.72)
    m_gem = mat("FrameGem", (0.78, 0.45, 1.0), rough=0.08, em=(0.72, 0.38, 1.0), em_s=4.0)

    # Outer ornate frame bars around (x in [-1.8, 1.8], z in [0, 4.6])
    box("BarBot", (4.7, 0.62, 0.52), m_gold, loc=(0, 0, -0.20), bevel=0.06)
    box("BarTop", (4.9, 0.68, 0.58), m_gold, loc=(0, 0, 4.85), bevel=0.06)
    box("BarL", (0.56, 0.62, 5.1), m_gold, loc=(-2.08, 0, 2.32), bevel=0.06)
    box("BarR", (0.56, 0.62, 5.1), m_gold, loc=(2.08, 0, 2.32), bevel=0.06)
    # Sculpted rose-gold inner molding & corner medallions
    for sx in (-2.15, 2.15):
        for sz in (-0.15, 4.88):
            cyl(f"Corner_{sx}_{sz}", 0.48, 0.48, 0.78, 8, m_rose,
                loc=(sx, 0, sz), rot=(math.radians(90), 0, 0), bevel=0.04)
    # Crown Crest & Floating Portal Amethyst Gem
    cyl("Crest", 0.85, 0.20, 0.85, 6, m_gold, loc=(0, 0, 5.55), bevel=0.04)
    cyl("Gem", 0.32, 0.02, 0.55, 6, m_gem, loc=(0, 0, 5.85), bevel=0.02)
    save(OUT_W4, "gilded_portal_frame.glb")

    # 2. Escher Fluted Marble & Rose-Gold Floating Balcony (4.6m × 4.6m walkable top at Z=0!)
    clear()
    m_marble = mat("EscherMarble", (0.94, 0.91, 0.96), rough=0.28, coat=0.45)
    m_lilac = mat("EscherLilac", (0.58, 0.42, 0.76), rough=0.40)
    m_gold = mat("EscherGold", (0.94, 0.75, 0.34), rough=0.22, metal=0.88)

    box("Deck", (4.6, 4.6, 0.48), m_marble, loc=(0, 0, -0.24), bevel=0.06)
    box("GoldTrim", (4.76, 4.76, 0.14), m_gold, loc=(0, 0, -0.10), bevel=0.03)
    # Inverted Escher staircase sculptural relief hanging beneath!
    for step in range(4):
        w = 3.8 - step * 0.75
        box(f"InvStep{step}", (w, w, 0.52), m_lilac if step % 2 else m_marble,
            loc=(0, 0, -0.74 - step * 0.50), bevel=0.04)
    save(OUT_W4, "marble_stair_arch.glb")

    # 3. Faceted Floating Rainbow Crystal Prism Landmark / Plinth
    clear()
    m_crystal = mat("PrismCrystal", (0.86, 0.76, 1.0), rough=0.08, em=(0.68, 0.48, 0.98), em_s=1.4, coat=0.9)
    m_gold = mat("PrismGold", (0.95, 0.78, 0.34), rough=0.20, metal=0.90)

    cyl("TopHalf", 1.85, 0.15, 2.8, 6, m_crystal, loc=(0, 0, 1.4), bevel=0.04)
    cyl("BotHalf", 0.15, 1.85, 2.8, 6, m_crystal, loc=(0, 0, -1.4), bevel=0.04)
    cyl("Belt", 2.02, 2.02, 0.24, 6, m_gold, loc=(0, 0, 0), bevel=0.03)
    save(OUT_W4, "crystal_prism.glb")

    # 4. Framed Iridescent Mirror Wall-Run Panel (length 9.0m X, height 4.4m Z, thickness 0.65m Y)
    clear()
    m_gold = mat("MirGold", (0.95, 0.78, 0.34), rough=0.22, metal=0.90)
    m_glass = mat("MirGlass", (0.76, 0.86, 1.0), rough=0.06, metal=0.55, em=(0.55, 0.72, 1.0), em_s=1.1, coat=0.95)
    m_chev = mat("MirChev", (1.0, 0.55, 0.88), rough=0.1, em=(1.0, 0.48, 0.85), em_s=3.4)

    box("MirrorGlass", (8.6, 0.45, 3.9), m_glass, loc=(0, 0, 0), bevel=0.03)
    box("FrameTop", (9.2, 0.76, 0.42), m_gold, loc=(0, 0, 2.12), bevel=0.05)
    box("FrameBot", (9.2, 0.76, 0.42), m_gold, loc=(0, 0, -2.12), bevel=0.05)
    box("FrameL", (0.45, 0.76, 4.5), m_gold, loc=(-4.42, 0, 0), bevel=0.05)
    box("FrameR", (0.45, 0.76, 4.5), m_gold, loc=(4.42, 0, 0), bevel=0.05)
    for i in range(-3, 4):
        box(f"ChevA{i}", (0.32, 0.56, 1.2), m_chev, loc=(i * 1.15, 0, 0), rot=(0, math.radians(22), 0), bevel=0.02)
    save(OUT_W4, "mirror_wall_panel.glb")

    # 5. Fragile Shattering Glass Tile (3.5m × 3.5m × 0.30m, top at Z=0)
    clear()
    m_glass = mat("ShatterGlass", (0.82, 0.88, 1.0), rough=0.08, em=(0.52, 0.72, 1.0), em_s=0.9, coat=0.9)
    m_gold = mat("ShatterTrim", (0.96, 0.78, 0.36), rough=0.22, metal=0.90)

    box("GlassPane", (3.3, 3.3, 0.24), m_glass, loc=(0, 0, -0.12), bevel=0.03)
    for sx in (-1.68, 1.68):
        box(f"EdgeX{sx}", (0.14, 3.5, 0.30), m_gold, loc=(sx, 0, -0.14), bevel=0.02)
    for sy in (-1.68, 1.68):
        box(f"EdgeY{sy}", (3.5, 0.14, 0.30), m_gold, loc=(0, sy, -0.14), bevel=0.02)
    save(OUT_W4, "shatter_pane.glb")


if __name__ == "__main__":
    gen_w3()
    gen_w4()
    print("[world_kits_3_4] Worlds 3 & 4 kits complete!")
