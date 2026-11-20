"""
Blender 5.2.1 LTS Asset Kit Generator - Worlds 1 & 2
  World 1 (The Sunken Conservatory): terracotta_plinth, aqueduct_arch, lily_pad_cap, glass_dome_rib, mossy_flagstone
  World 2 (Foundry of Floating Bells): brass_gear, curved_bell, pendulum_blade, steam_vent, foundry_catwalk

Every walkable platform has its clean walkable top deck at Z=0 (Godot Y=0) for exact collision alignment!
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector, Euler

OUT_W1 = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/world1_conservatory"
OUT_W2 = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/world2_foundry"
os.makedirs(OUT_W1, exist_ok=True)
os.makedirs(OUT_W2, exist_ok=True)


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


def save(out_dir, fname):
    p = os.path.join(out_dir, fname)
    bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[world_kits_1_2] Exported {p}")


# ==============================================================================
# WORLD 1 - THE SUNKEN CONSERVATORY
# ==============================================================================
def gen_w1():
    # 1. Terracotta Plinth Island (rich warm limestone & deep Tuscan terracotta!)
    clear()
    m_stone = mat("W1Stone", (0.64, 0.57, 0.45), rough=0.64)
    m_terra = mat("W1Terracotta", (0.52, 0.18, 0.09), rough=0.58)
    m_moss = mat("W1Moss", (0.10, 0.40, 0.16), rough=0.72)
    m_gold = mat("W1Brass", (0.76, 0.52, 0.14), rough=0.28, metal=0.86)

    cyl("TopSlab", 2.55, 2.65, 0.36, 8, m_stone, loc=(0, 0, -0.18), bevel=0.04)
    cyl("MossTrim", 2.30, 2.30, 0.06, 8, m_moss, loc=(0, 0, -0.01), bevel=0.02)
    torus("GoldInlay", 2.42, 0.055, 24, 8, m_gold, loc=(0, 0, -0.04))
    cyl("TerraCore", 1.85, 2.38, 0.85, 8, m_terra, loc=(0, 0, -0.78), bevel=0.04)
    cyl("UnderSpire", 0.45, 1.65, 1.45, 8, m_stone, loc=(0, 0, -1.92), bevel=0.04)
    for k in range(8):
        a = k * math.pi * 0.25
        box(f"Corbel{k}", (0.36, 0.55, 0.72), m_stone,
            loc=(2.12 * math.cos(a), 2.12 * math.sin(a), -0.68), rot=(0, 0, a), bevel=0.03)
    save(OUT_W1, "terracotta_plinth.glb")

    # 2. Aqueduct Bridge Arch (walkable deck 6.5m along Y, 3.4m wide X, top at Z=0)
    clear()
    m_stone = mat("W1ArchStone", (0.66, 0.59, 0.47), rough=0.62)
    m_terra = mat("W1ArchTerra", (0.52, 0.19, 0.10), rough=0.55)
    m_moss = mat("W1ArchMoss", (0.12, 0.42, 0.17), rough=0.74)
    m_gold = mat("W1ArchBrass", (0.78, 0.54, 0.14), rough=0.26, metal=0.86)

    box("Deck", (3.4, 6.6, 0.42), m_stone, loc=(0, 0, -0.21), bevel=0.05)
    box("CenterRunner", (1.6, 6.5, 0.05), m_terra, loc=(0, 0, -0.01), bevel=0.02)
    for sx in (-1.55, 1.55):
        box(f"Curb{sx}", (0.28, 6.5, 0.32), m_terra, loc=(sx, 0, 0.14), bevel=0.03)
        for py in (-2.9, 0.0, 2.9):
            box(f"Post_{sx}_{py}", (0.38, 0.38, 0.56), m_stone, loc=(sx, py, 0.28), bevel=0.03)
            cyl(f"Finial_{sx}_{py}", 0.14, 0.04, 0.18, 8, m_gold, loc=(sx, py, 0.64), bevel=0.01)
    # Sculpted Hanging Arch Piers Beneath
    for sy in (-2.5, 2.5):
        box(f"Pier{sy}", (2.9, 1.1, 2.4), m_stone, loc=(0, sy, -1.6), bevel=0.05)
    for k in range(7):
        ang = math.pi * (k + 0.5) / 7.0
        y = 2.0 * math.cos(ang)
        z = -2.2 + 1.5 * math.sin(ang)
        box(f"Voussoir{k}", (3.1, 0.65, 0.48), m_terra, loc=(0, y, z), rot=(ang - math.pi * 0.5, 0, 0), bevel=0.03)
    box("MossPatch", (2.8, 1.8, 0.08), m_moss, loc=(0.2, 1.2, -0.01), bevel=0.02)
    save(OUT_W1, "aqueduct_arch.glb")

    # 3. Giant Springy Lily-Pad Bounce Cap (radius 2.2m, top at Z=0)
    clear()
    m_leaf = mat("LilyLeaf", (0.22, 0.68, 0.36), rough=0.38, coat=0.35)
    m_rim = mat("LilyRim", (0.45, 0.86, 0.42), rough=0.32, em=(0.25, 0.78, 0.32), em_s=0.45)
    m_petal = mat("LilyPetal", (1.0, 0.88, 0.78), rough=0.36, coat=0.25)
    m_pollen = mat("LilyPollen", (1.0, 0.84, 0.22), rough=0.20, em=(1.0, 0.76, 0.18), em_s=2.4)

    cyl("PadDisk", 1.85, 2.25, 0.42, 16, m_leaf, loc=(0, 0, -0.21), smooth=True, bevel=0.05)
    torus("PadLip", 2.18, 0.14, 24, 10, m_rim, loc=(0, 0, -0.04))
    cyl("StemBase", 0.32, 0.85, 1.2, 10, m_leaf, loc=(0, 0, -0.95), smooth=True, bevel=0.03)
    # Blooming lotus petals around the spring center
    for i in range(8):
        a = i * math.pi * 0.25
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=10, v_segments=6, radius=1.0)
        bmesh.ops.scale(bm, vec=(0.45, 0.85, 0.14), verts=bm.verts)
        add_bm(f"Petal{i}", bm, m_petal, loc=(1.15 * math.cos(a), 1.15 * math.sin(a), 0.04),
               rot=(math.radians(-12), 0, a - math.pi * 0.5), smooth=True, bevel=0.0)
    cyl("PollenCushion", 0.78, 0.68, 0.22, 12, m_pollen, loc=(0, 0, 0.06), smooth=True, bevel=0.04)
    save(OUT_W1, "lily_pad_cap.glb")

    # 4. Monumental Sweeping Continuous Shattered Glasshouse Cathedral Arch (span 20m, height 13.5m!)
    clear()
    m_iron = mat("GlassIron", (0.11, 0.20, 0.19), rough=0.34, metal=0.82)
    m_brass = mat("GlassBrass", (0.76, 0.52, 0.16), rough=0.26, metal=0.88)
    m_glass = mat("StainedGlass", (0.18, 0.64, 0.60), rough=0.10, em=(0.14, 0.52, 0.50), em_s=0.55, coat=0.85)

    # True continuous swept curved twin iron ribs using connected bmesh rings (zero floating blocks!)
    segs = 28
    for sy in (-1.35, 1.35):
        bm_rib = bmesh.new()
        rings = []
        for i in range(segs + 1):
            t = math.pi * i / segs
            cx = 10.0 * math.cos(t)
            cz = 13.0 * math.sin(t)
            # Outward radial & tangent vectors along the ellipse
            tx = -10.0 * math.sin(t)
            tz = 13.0 * math.cos(t)
            tlen = math.hypot(tx, tz)
            nx, nz = tz / tlen, -tx / tlen
            hr, hy = 0.36, 0.28
            ring = [
                bm_rib.verts.new((cx - nx * hr, sy - hy, cz - nz * hr)),
                bm_rib.verts.new((cx + nx * hr, sy - hy, cz + nz * hr)),
                bm_rib.verts.new((cx + nx * hr, sy + hy, cz + nz * hr)),
                bm_rib.verts.new((cx - nx * hr, sy + hy, cz - nz * hr)),
            ]
            rings.append(ring)
        for i in range(segs):
            for s in range(4):
                sn = (s + 1) % 4
                bm_rib.faces.new((rings[i][s], rings[i][sn], rings[i + 1][sn], rings[i + 1][s]))
        bm_rib.faces.new(rings[0][::-1])
        bm_rib.faces.new(rings[-1])
        add_bm(f"SweptRib_{sy}", bm_rib, m_iron, smooth=False, bevel=0.04)

    # Continuous curved stained-glass vaulted ribbon between ribs (with an artful sunlit sky break at apex!)
    for span_start, span_end, tag in [(1, 11, "L"), (17, 27, "R")]:
        bm_g = bmesh.new()
        grings = []
        for i in range(span_start, span_end + 1):
            t = math.pi * i / segs
            cx = 10.0 * math.cos(t)
            cz = 13.0 * math.sin(t)
            tx, tz = -10.0 * math.sin(t), 13.0 * math.cos(t)
            tlen = math.hypot(tx, tz)
            nx, nz = tz / tlen, -tx / tlen
            ht = 0.08
            grings.append([
                bm_g.verts.new((cx - nx * ht, -1.15, cz - nz * ht)),
                bm_g.verts.new((cx + nx * ht, -1.15, cz + nz * ht)),
                bm_g.verts.new((cx + nx * ht, 1.15, cz + nz * ht)),
                bm_g.verts.new((cx - nx * ht, 1.15, cz - nz * ht)),
            ])
        for i in range(len(grings) - 1):
            for s in range(4):
                sn = (s + 1) % 4
                bm_g.faces.new((grings[i][s], grings[i][sn], grings[i + 1][sn], grings[i + 1][s]))
        add_bm(f"GlassVault_{tag}", bm_g, m_glass, smooth=False, bevel=0.01)

    # Ornate brass cross-mullions every 2 segments + stone arch base plinths
    for i in range(0, segs + 1, 2):
        t = math.pi * i / segs
        cx, cz = 10.0 * math.cos(t), 13.0 * math.sin(t)
        box(f"Mullion{i}", (0.28, 3.0, 0.28), m_brass, loc=(cx, 0, cz), rot=(0, math.pi * 0.5 - t, 0), bevel=0.02)
    for sx in (-10.0, 10.0):
        cyl(f"ArchFoot{sx}", 1.25, 0.95, 1.8, 8, m_iron, loc=(sx, 0, -0.8), bevel=0.04)
    save(OUT_W1, "glass_dome_rib.glb")

    # 5. Mossy Crumbling Flagstone (3.4m × 3.4m × 0.45m, top at Z=0)
    clear()
    m_stone = mat("FlagStone", (0.84, 0.78, 0.66), rough=0.68)
    m_moss = mat("FlagMoss", (0.30, 0.64, 0.34), rough=0.72)
    m_rim = mat("FlagGold", (0.86, 0.64, 0.26), rough=0.35, metal=0.75)

    box("Slab", (3.35, 3.35, 0.42), m_stone, loc=(0, 0, -0.21), bevel=0.06)
    box("TopInlay", (2.65, 2.65, 0.05), m_moss, loc=(0, 0, -0.01), bevel=0.02)
    for sx in (-1.52, 1.52):
        box(f"TrimX{sx}", (0.14, 3.1, 0.14), m_rim, loc=(sx, 0, -0.05), bevel=0.02)
    for sy in (-1.52, 1.52):
        box(f"TrimY{sy}", (3.1, 0.14, 0.14), m_rim, loc=(0, sy, -0.05), bevel=0.02)
    save(OUT_W1, "mossy_flagstone.glb")


# ==============================================================================
# WORLD 2 - FOUNDRY OF FLOATING BELLS
# ==============================================================================
def gen_w2():
    # 1. Giant Interlocking Clockwork Brass Gear (radius 4.2m walkable top at Z=0!)
    clear()
    m_brass = mat("GearBrass", (0.86, 0.62, 0.24), rough=0.28, metal=0.88)
    m_copper = mat("GearCopper", (0.72, 0.36, 0.22), rough=0.34, metal=0.82)
    m_iron = mat("GearIron", (0.24, 0.22, 0.26), rough=0.45, metal=0.75)
    m_core = mat("GearAmber", (1.0, 0.74, 0.24), rough=0.15, em=(1.0, 0.68, 0.18), em_s=2.6)

    cyl("GearDisc", 3.65, 3.65, 0.56, 24, m_brass, loc=(0, 0, -0.28), bevel=0.04)
    cyl("InnerPlate", 2.75, 2.75, 0.60, 16, m_iron, loc=(0, 0, -0.30), bevel=0.03)
    torus("RimRing", 3.45, 0.18, 32, 10, m_copper, loc=(0, 0, -0.10))
    cyl("Hub", 0.95, 0.85, 0.74, 12, m_brass, loc=(0, 0, -0.30), bevel=0.04)
    cyl("HubGlow", 0.55, 0.55, 0.18, 12, m_core, loc=(0, 0, 0.02), bevel=0.02)
    # 12 chunky beveled gear teeth extending out to radius 4.45m
    for i in range(12):
        a = i * 2.0 * math.pi / 12.0
        box(f"Tooth{i}", (0.92, 0.85, 0.54), m_brass,
            loc=(3.95 * math.cos(a), 3.95 * math.sin(a), -0.28), rot=(0, 0, a), bevel=0.05)
    # 6 decorative brass radial spokes
    for i in range(6):
        a = i * math.pi / 3.0
        box(f"Spoke{i}", (2.6, 0.38, 0.64), m_copper,
            loc=(1.75 * math.cos(a), 1.75 * math.sin(a), -0.31), rot=(0, 0, a), bevel=0.03)
    save(OUT_W2, "brass_gear.glb")

    # 2. Colossal Wall-Runnable Musical Bronze Bell (length 8.5m along X, height 4.4m Z, wall face along ±Y)
    clear()
    m_bronze = mat("BellBronze", (0.76, 0.52, 0.24), rough=0.30, metal=0.86)
    m_gold = mat("BellGold", (0.96, 0.78, 0.32), rough=0.22, metal=0.92)
    m_rune = mat("BellRune", (0.36, 0.92, 1.0), rough=0.1, em=(0.28, 0.88, 1.0), em_s=3.4)

    # Sculpted curved acoustic wall-plate shaped like an elongated cathedral bell chord-slab
    box("BellMainWall", (8.6, 0.85, 4.2), m_bronze, loc=(0, 0, 0), bevel=0.08)
    box("BellTopFlange", (9.1, 1.25, 0.45), m_gold, loc=(0, 0, 2.15), bevel=0.05)
    box("BellLipFlare", (9.2, 1.35, 0.50), m_gold, loc=(0, 0, -2.15), bevel=0.06)
    # Ornate bronze bell crown hanging above center + glowing directional acoustic chevrons on BOTH sides!
    cyl("BellCrown", 1.35, 0.65, 1.45, 12, m_bronze, loc=(0, 0, 2.95), smooth=True, bevel=0.05)
    torus("CrownRing", 0.55, 0.14, 16, 8, m_gold, loc=(0, 0, 3.85), rot=(math.radians(90), 0, 0))
    for i in range(-3, 4):
        box(f"ChevronF{i}", (0.42, 0.16, 1.35), m_rune, loc=(i * 1.15, 0.44, 0), rot=(0, math.radians(18), 0), bevel=0.02)
        box(f"ChevronB{i}", (0.42, 0.16, 1.35), m_rune, loc=(i * 1.15, -0.44, 0), rot=(0, math.radians(-18), 0), bevel=0.02)
    save(OUT_W2, "curved_bell.glb")

    # 3. Cathedral Swinging Pendulum (pivot at Z=0, hangs down to Z=-7.5m with gleaming gold sun-bob!)
    clear()
    m_iron = mat("PendIron", (0.22, 0.20, 0.25), rough=0.38, metal=0.82)
    m_brass = mat("PendBrass", (0.90, 0.68, 0.26), rough=0.24, metal=0.90)
    m_glow = mat("PendGlow", (1.0, 0.78, 0.26), rough=0.1, em=(1.0, 0.72, 0.22), em_s=3.2)

    cyl("PivotAxle", 0.65, 0.65, 1.4, 12, m_brass, loc=(0, 0, 0), rot=(math.radians(90), 0, 0), bevel=0.04)
    box("Shaft", (0.36, 0.36, 7.2), m_iron, loc=(0, 0, -3.6), bevel=0.04)
    # Ornate crescent blade bob & walkable crossbar platform at bottom!
    cyl("BobDisc", 1.85, 1.85, 0.55, 20, m_brass, loc=(0, 0, -7.2), rot=(math.radians(90), 0, 0), bevel=0.06)
    torus("BobRing", 1.55, 0.14, 24, 8, m_glow, loc=(0, 0, -7.2), rot=(math.radians(90), 0, 0))
    box("RideBar", (4.2, 2.4, 0.36), m_brass, loc=(0, 0, -5.8), bevel=0.05)
    save(OUT_W2, "pendulum_blade.glb")

    # 4. Riveted Brass Steam Vent Plinth (radius 2.2m, top at Z=0)
    clear()
    m_copper = mat("VentCopper", (0.76, 0.40, 0.24), rough=0.34, metal=0.84)
    m_brass = mat("VentBrass", (0.90, 0.70, 0.28), rough=0.25, metal=0.90)
    m_glow = mat("VentCore", (1.0, 0.82, 0.44), rough=0.15, em=(1.0, 0.74, 0.28), em_s=3.0)

    cyl("ChimneyBody", 1.75, 2.20, 1.55, 12, m_copper, loc=(0, 0, -0.78), bevel=0.05)
    torus("NozzleRim", 2.18, 0.22, 24, 10, m_brass, loc=(0, 0, -0.06))
    cyl("CoreLight", 1.65, 1.65, 0.14, 12, m_glow, loc=(0, 0, -0.10), bevel=0.02)
    for k in range(-2, 3):
        box(f"Grate{k}", (3.4, 0.20, 0.12), m_brass, loc=(0, k * 0.62, -0.04), bevel=0.02)
    save(OUT_W2, "steam_vent.glb")

    # 5. Foundry Ornate Sky-Catwalk (5.4m × 3.2m, walkable top at Z=0)
    clear()
    m_iron = mat("CatIron", (0.28, 0.25, 0.28), rough=0.44, metal=0.78)
    m_brass = mat("CatBrass", (0.88, 0.64, 0.24), rough=0.28, metal=0.88)
    m_copper = mat("CatCopper", (0.74, 0.38, 0.22), rough=0.35, metal=0.82)

    box("Deck", (3.2, 5.4, 0.36), m_iron, loc=(0, 0, -0.18), bevel=0.04)
    for sx in (-1.52, 1.52):
        box(f"SideBeam{sx}", (0.28, 5.5, 0.56), m_brass, loc=(sx, 0, -0.22), bevel=0.03)
    for py in (-2.2, -1.1, 0.0, 1.1, 2.2):
        box(f"CrossRib{py}", (3.3, 0.24, 0.26), m_copper, loc=(0, py, -0.46), bevel=0.02)
    save(OUT_W2, "foundry_catwalk.glb")


if __name__ == "__main__":
    gen_w1()
    gen_w2()
    print("[world_kits_1_2] Worlds 1 & 2 kits complete!")
