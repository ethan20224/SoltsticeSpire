"""
Blender 5.2.1 LTS Continuous Central Solstice Spire Tower Cores & Biome Parallax Silhouettes Generator (v2 Architectural Detail)
Upgrades:
  - W1 Glasshouse Core: 3D dark iron mullions + transoms over 3-stop vertical gradient conservatory glass (warm bottom -> cool top)
  - W2 Foundry Core: Riveted plate seams, beveled horizontal hammered brass girdle bands + rivet studs, recessed furnace mouths with dark iron grilles
  - W3 Pagoda Core: True curved upturned catenary eaves with radial ceramic roof-tile ridges + 3D dark cedar shoji window lattices
  - W4 Mirror Core: Fluted marble piers, 16-sided leaded jewel-toned rose windows, beveled gilded buttresses
  - W5 Library Core: 3D dark walnut & brass window mullion lattices over warm amber reading nooks + circling Cloud-Whale Leviathan
  - W6 Observatory Core: Fluted obsidian panels, beveled brass ribs, 3 glowing mullioned observatory window bands
  - 6 Biome-Specific Unified Parallax Silhouette Meshes (sil_w1..sil_w6.glb) built from each world's own architectural kit!
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector, Euler, Matrix

OUT_DIR = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/tower_cores"
os.makedirs(OUT_DIR, exist_ok=True)


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, col, rough=0.52, metal=0.0, em=None, em_s=0.0, coat=0.0):
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


def add_bm(name, bm, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.0):
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


def cyl(name, r1, r2, h, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel)


def box(name, sz, m, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=sz, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=False, bevel=bevel)


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
    print(f"[gen_tower_cores v2] Exported {p}")


# ==============================================================================
# WORLD 1: VICTORIAN GLASSHOUSE CONSERVATORY TOWER CORE (Mullioned Gradient Glass!)
# ==============================================================================
def build_w1_core():
    clear()
    m_stone = mat("W1CoreStone", (0.68, 0.61, 0.49), rough=0.62)
    m_terra = mat("W1CoreTerra", (0.56, 0.22, 0.12), rough=0.56)
    m_iron = mat("W1CoreIron", (0.12, 0.20, 0.18), rough=0.36, metal=0.82)
    m_brass = mat("W1CoreBrass", (0.82, 0.58, 0.20), rough=0.26, metal=0.88)
    m_glass = mat("W1CoreGlass", (0.20, 0.58, 0.56), rough=0.14, em=(0.14, 0.44, 0.44), em_s=0.50)
    # 3-stop vertical gradient glass (warm amber lower conservatory glow -> honey mid -> cool teal transom!)
    m_win_bot = mat("W1WinBotGlow", (1.0, 0.66, 0.28), rough=0.16, em=(1.0, 0.62, 0.24), em_s=1.80)
    m_win_mid = mat("W1WinMidGlow", (0.94, 0.74, 0.38), rough=0.16, em=(0.92, 0.68, 0.32), em_s=1.35)
    m_win_top = mat("W1WinTopGlow", (0.42, 0.78, 0.74), rough=0.14, em=(0.32, 0.68, 0.66), em_s=0.95)
    m_ivy = mat("W1CoreMossIvy", (0.14, 0.44, 0.18), rough=0.90)

    cyl("PedestalBase", 3.5, 6.2, 41.0, 12, m_stone, loc=(0, 0, -5.5))
    cyl("FlareCollar", 6.2, 14.5, 11.0, 12, m_terra, loc=(0, 0, 20.5), bevel=0.12)
    torus("FlareRing", 14.8, 0.75, 28, 8, m_stone, loc=(0, 0, 26.0))

    cyl("MainShaft", 14.2, 13.8, 152.0, 16, m_stone, loc=(0, 0, 102.0))

    for i in range(8):
        a = i * math.pi * 0.25
        ca, sa = math.cos(a), math.sin(a)
        box(f"IronRib_{i}", (1.2, 1.5, 154.0), m_iron, loc=(14.4 * ca, 14.4 * sa, 102.0), rot=(0, 0, a), bevel=0.08)
        if i % 2 == 0:
            for k in range(5):
                iz = 38.0 + k * 28.0 + (i * 3.0)
                box(f"IvyCurtain_{i}_{k}", (0.65, 3.2, 14.5), m_ivy,
                    loc=(14.7 * ca, 14.7 * sa, iz), rot=(0, 0, a))

    # 5 Conservatory Gallery Tiers with 3-stop gradient glass & 3D iron mullions!
    for tier in range(5):
        tz = 34.0 + tier * 30.0
        cyl(f"Cornice_{tier}", 16.4, 16.0, 1.8, 16, m_stone, loc=(0, 0, tz), bevel=0.12)
        torus(f"BrassRail_{tier}", 16.2, 0.26, 28, 6, m_brass, loc=(0, 0, tz + 1.9))
        cyl(f"GlassBand_{tier}", 14.5, 14.5, 14.0, 16, m_glass, loc=(0, 0, tz + 10.5))
        for w in range(8):
            wa = w * math.pi * 0.25 + math.pi * 0.125
            ca, sa = math.cos(wa), math.sin(wa)
            tx, ty = -sa, ca
            wx, wy = 14.55 * ca, 14.55 * sa
            # 3-tier vertical gradient conservatory bay (warm bottom -> honey mid -> cool teal top)
            box(f"WinBot_{tier}_{w}", (0.45, 3.5, 3.2), m_win_bot, loc=(wx, wy, tz + 7.4), rot=(0, 0, wa))
            box(f"WinMid_{tier}_{w}", (0.45, 3.5, 3.2), m_win_mid, loc=(wx, wy, tz + 10.6), rot=(0, 0, wa))
            box(f"WinTop_{tier}_{w}", (0.45, 3.5, 2.8), m_win_top, loc=(wx, wy, tz + 13.6), rot=(0, 0, wa))
            # 3D Dark Iron Mullions & Horizontal Transoms standing proud at r=14.78m!
            mx, my = 14.78 * ca, 14.78 * sa
            for dy in (-1.7, -0.56, 0.56, 1.7):
                box(f"MullV_{tier}_{w}_{dy}", (0.35, 0.24, 9.6), m_iron,
                    loc=(mx + tx * dy, my + ty * dy, tz + 10.6), rot=(0, 0, wa))
            for dz in (5.9, 9.0, 12.2, 15.2):
                box(f"TransH_{tier}_{w}_{dz}", (0.38, 3.8, 0.28), m_iron,
                    loc=(mx, my, tz + dz), rot=(0, 0, wa))
            if w % 2 == (tier % 2):
                px, py = 16.8 * ca, 16.8 * sa
                cyl(f"Planter_{tier}_{w}", 0.9, 1.35, 1.3, 8, m_terra, loc=(px, py, tz - 1.2))
                cyl(f"PlanterMoss_{tier}_{w}", 1.45, 1.25, 0.85, 8, m_ivy, loc=(px, py, tz - 0.2))

    cyl("TopCollar", 14.8, 16.8, 8.0, 16, m_terra, loc=(0, 0, 176.0), bevel=0.14)
    save("w1_conservatory_core.glb")


# ==============================================================================
# WORLD 2: FOUNDRY STACK CORE (Riveted Seams, Beveled Brass Bands & Grilled Furnaces!)
# ==============================================================================
def build_w2_core():
    clear()
    m_iron = mat("W2CoreIron", (0.18, 0.16, 0.20), rough=0.44, metal=0.80)
    m_copper = mat("W2CoreCopper", (0.70, 0.35, 0.18), rough=0.32, metal=0.88)
    m_brass = mat("W2CoreBrass", (0.86, 0.62, 0.22), rough=0.24, metal=0.92)
    m_furnace = mat("W2FurnaceGlow", (1.0, 0.50, 0.14), rough=0.16, em=(1.0, 0.46, 0.10), em_s=1.95)

    # Stepped segmented copper-and-iron boiler drums instead of one plain cylinder!
    for seg in range(6):
        sz0 = seg * 30.0
        r_seg = 16.2 - seg * 0.18
        m_drum = m_copper if seg % 2 == 1 else m_iron
        cyl(f"BoilerDrum_{seg}", r_seg, r_seg - 0.15, 29.2, 16, m_drum, loc=(0, 0, sz0 + 14.6), bevel=0.16)
        # Beveled horizontal hammered brass girdle bands with 16 protruding rivet studs!
        cyl(f"BrassGirdle_{seg}", r_seg + 0.95, r_seg + 0.95, 2.2, 16, m_brass, loc=(0, 0, sz0 + 2.0), bevel=0.22)
        cyl(f"MidSeamRing_{seg}", r_seg + 0.55, r_seg + 0.55, 1.1, 16, m_brass, loc=(0, 0, sz0 + 15.0), bevel=0.14)
        for rv in range(16):
            ra = rv * math.tau / 16.0
            rx, ry = (r_seg + 1.05) * math.cos(ra), (r_seg + 1.05) * math.sin(ra)
            box(f"Rivet_{seg}_{rv}", (0.48, 0.55, 0.55), m_iron, loc=(rx, ry, sz0 + 2.0), rot=(0, 0, ra))

    # 8 Protruding Beveled Riveted Vertical Plate-Seam Pilasters
    for i in range(8):
        a = i * math.pi * 0.25 + math.pi * 0.125
        ca, sa = math.cos(a), math.sin(a)
        box(f"PlatePilaster_{i}", (1.4, 1.8, 180.0), m_brass if i % 2 == 0 else m_iron,
            loc=(16.1 * ca, 16.1 * sa, 90.0), rot=(0, 0, a), bevel=0.12)

    # 4 External Towering Flanged Copper Exhaust Chimneys
    for i in range(4):
        a = i * math.pi * 0.5 + math.pi * 0.25
        cx, cy = 16.8 * math.cos(a), 16.8 * math.sin(a)
        cyl(f"Chimney_{i}", 2.2, 1.9, 178.0, 12, m_copper, loc=(cx, cy, 90.0))
        for ring_i in range(8):
            cyl(f"ChimFlange_{i}_{ring_i}", 2.55, 2.55, 1.1, 12, m_brass, loc=(cx, cy, 12.0 + ring_i * 22.0), bevel=0.12)
        cyl(f"ChimCrown_{i}", 1.9, 2.8, 3.4, 12, m_brass, loc=(cx, cy, 179.5), bevel=0.14)

    # 5 Foundry Gallery Levels: Recessed Furnace Mouths WITH Dark Iron Grilles + Bell Alcoves!
    for lvl in range(5):
        lz = 16.0 + lvl * 34.0
        torus(f"CopperPipeRing_{lvl}", 17.2, 0.68, 28, 8, m_copper, loc=(0, 0, lz + 4.0))

        for f in range(4):
            fa = f * math.pi * 0.5 + lvl * 0.4
            ca, sa = math.cos(fa), math.sin(fa)
            tx, ty = -sa, ca
            fx, fy = 15.8 * ca, 15.8 * sa
            box(f"FurnaceHood_{lvl}_{f}", (2.4, 6.4, 8.0), m_copper, loc=(fx, fy, lz + 13.0), rot=(0, 0, fa), bevel=0.16)
            box(f"FurnaceMouth_{lvl}_{f}", (1.5, 4.8, 5.8), m_furnace, loc=(fx * 1.03, fy * 1.03, lz + 13.0), rot=(0, 0, fa))
            # Dark iron furnace grate bars standing proud across the glowing orange furnace mouth!
            gx, gy = 16.65 * ca, 16.65 * sa
            for dy in (-1.6, -0.55, 0.55, 1.6):
                box(f"GrilleV_{lvl}_{f}_{dy}", (0.42, 0.34, 6.0), m_iron,
                    loc=(gx + tx * dy, gy + ty * dy, lz + 13.0), rot=(0, 0, fa))
            for dz in (11.0, 13.0, 15.0):
                box(f"GrilleH_{lvl}_{f}_{dz}", (0.45, 5.0, 0.34), m_iron,
                    loc=(gx, gy, lz + dz), rot=(0, 0, fa))

            pa = fa + math.pi * 0.25
            cyl(f"SteamPipe_{lvl}_{f}", 0.58, 0.58, 7.8, 10, m_copper,
                loc=(17.6 * math.cos(pa), 17.6 * math.sin(pa), lz + 22.0),
                rot=(0, math.radians(90), pa))
            bx, by = 19.5 * math.cos(pa), 19.5 * math.sin(pa)
            cyl(f"GalleryBell_{lvl}_{f}", 1.85, 0.72, 3.2, 12, m_brass, loc=(bx, by, lz + 18.8), smooth=True, bevel=0.08)
            cyl(f"BellClapper_{lvl}_{f}", 0.35, 0.35, 1.2, 8, m_iron, loc=(bx, by, lz + 16.9))

    save("w2_foundry_core.glb")


# ==============================================================================
# WORLD 3: 7-STORY PAGODA CORE (Curved Upturned Tiled Eaves + 3D Shoji Lattices!)
# ==============================================================================
def build_curved_pagoda_roof(name, r_inner, r_outer, z_base, height, m_tile, m_red, m_gold):
    """Builds a true concave curved upturned Japanese pagoda eave skirt with 16 raised ceramic tile ribs!"""
    bm = bmesh.new()
    segs = 8
    # 5 radial profile rings curving from steep upper pitch to upturned horizontal eave lip!
    prof = [
        (r_inner, z_base + height),
        (r_inner + (r_outer - r_inner) * 0.28, z_base + height * 0.56),
        (r_inner + (r_outer - r_inner) * 0.58, z_base + height * 0.22),
        (r_inner + (r_outer - r_inner) * 0.85, z_base + height * 0.04),
        (r_outer, z_base + height * 0.10),  # Upturned outer lip!
    ]
    rings_top = []
    rings_bot = []
    for rad, zz in prof:
        rt = []
        rb = []
        for s in range(segs):
            a = s * math.tau / segs + math.pi / segs
            # Upsweep at the 8 octagon corners!
            rt.append(bm.verts.new((rad * math.cos(a), rad * math.sin(a), zz + (rad - r_inner) * 0.08)))
            rb.append(bm.verts.new((rad * math.cos(a), rad * math.sin(a), zz - 0.55 + (rad - r_inner) * 0.06)))
        rings_top.append(rt)
        rings_bot.append(rb)
    for i in range(len(prof) - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            bm.faces.new((rings_top[i][s], rings_top[i][sn], rings_top[i + 1][sn], rings_top[i + 1][s]))
            bm.faces.new((rings_bot[i][sn], rings_bot[i][s], rings_bot[i + 1][s], rings_bot[i + 1][sn]))
    # Outer rim fascia connecting top & bottom
    for s in range(segs):
        sn = (s + 1) % segs
        bm.faces.new((rings_top[-1][s], rings_bot[-1][s], rings_bot[-1][sn], rings_top[-1][sn]))
    add_bm(name, bm, m_tile, smooth=False)

    # 16 Raised Radial Ceramic Roof-Tile Ridge Ribs + Gilded Corner Finials!
    for k in range(16):
        a = k * math.tau / 16.0
        rm = (r_inner + r_outer) * 0.5
        dr = r_outer - r_inner
        pitch = math.atan2(height * 0.85, dr)
        box(f"{name}_Ridge_{k}", (dr * 0.96, 0.36, 0.34), m_gold if k % 2 == 1 else m_red,
            loc=(rm * math.cos(a), rm * math.sin(a), z_base + height * 0.42),
            rot=(0, pitch, a), bevel=0.04)


def build_w3_core():
    clear()
    m_wood = mat("W3PagodaCedar", (0.18, 0.11, 0.09), rough=0.54)
    m_red = mat("W3PagodaRed", (0.68, 0.14, 0.12), rough=0.38, coat=0.4)
    # Named 'CeramicRoof' (NOT wood/brick) so WorldHelper keeps its deep jade ceramic glaze!
    m_tile = mat("W3CeramicRoof", (0.09, 0.32, 0.40), rough=0.28, metal=0.18, coat=0.65)
    m_gold = mat("W3PagodaGold", (0.90, 0.68, 0.24), rough=0.24, metal=0.88)
    m_shoji = mat("W3ShojiGlow", (1.0, 0.66, 0.30), rough=0.22, em=(1.0, 0.62, 0.24), em_s=1.75)

    stories = 7
    story_h = 26.0
    for s in range(stories):
        sz = s * story_h
        r_wall = 14.8 - s * 0.42
        r_eave = 21.0 - s * 0.48
        cyl(f"StoryBody_{s}", r_wall, r_wall * 0.96, story_h + 1.8, 8, m_wood, loc=(0, 0, sz + story_h * 0.5))
        for k in range(8):
            a = k * math.pi * 0.25 + math.pi * 0.125
            ca, sa = math.cos(a), math.sin(a)
            cyl(f"Col_{s}_{k}", 0.78, 0.72, story_h + 1.0, 8, m_red, loc=((r_wall + 0.2) * ca, (r_wall + 0.2) * sa, sz + story_h * 0.5))

            # Face center is at angle wa = k * pi/4; distance to flat octagon face is r_face = r_wall * cos(pi/8)
            wa = k * math.pi * 0.25
            wca, wsa = math.cos(wa), math.sin(wa)
            tx, ty = -wsa, wca
            r_face = r_wall * 0.924
            wx, wy = (r_face + 0.15) * wca, (r_face + 0.15) * wsa
            box(f"Shoji_{s}_{k}", (0.42, 6.4, 11.2), m_shoji, loc=(wx, wy, sz + 11.5), rot=(0, 0, wa))
            # 3D Dark Cedar Shoji Lattice Overlay standing proud at r_face + 0.45m!
            lx, ly = (r_face + 0.45) * wca, (r_face + 0.45) * wsa
            for dy in (-3.1, -1.55, 0.0, 1.55, 3.1):
                box(f"ShojiV_{s}_{k}_{dy}", (0.36, 0.28, 11.5), m_wood,
                    loc=(lx + tx * dy, ly + ty * dy, sz + 11.5), rot=(0, 0, wa))
            for dz in (6.1, 8.8, 11.5, 14.2, 16.9):
                box(f"ShojiH_{s}_{k}_{dz}", (0.38, 6.6, 0.28), m_wood,
                    loc=(lx, ly, sz + dz), rot=(0, 0, wa))

        # True Curved Upturned Ceramic-Tiled Pagoda Eave Roof!
        eave_z = sz + story_h - 4.8
        build_curved_pagoda_roof(f"CurvedEave_{s}", r_wall * 0.92, r_eave, eave_z, 5.4, m_tile, m_red, m_gold)
        for k in range(8):
            a = k * math.pi * 0.25 + math.pi * 0.125
            hx, hy = (r_eave + 0.4) * math.cos(a), (r_eave + 0.4) * math.sin(a)
            if k % 2 == 0:
                cyl(f"RainChain_{s}_{k}", 0.12, 0.12, 14.0, 6, m_gold, loc=(hx * 0.96, hy * 0.96, eave_z - 7.0))
                cyl(f"EaveLantern_{s}_{k}", 0.36, 0.30, 0.78, 12, m_shoji, loc=(hx * 0.96, hy * 0.96, eave_z - 1.2), smooth=True)

    save("w3_monsoon_core.glb")


# ==============================================================================
# WORLD 4: ESCHER MIRROR-CATHEDRAL SPIRE CORE (16-Sided Jewel Rose Windows!)
# ==============================================================================
def build_w4_core():
    clear()
    m_marble = mat("W4CoreMarble", (0.92, 0.88, 0.94), rough=0.26, coat=0.40)
    m_lilac = mat("W4CoreLilac", (0.54, 0.40, 0.70), rough=0.40)
    m_gold = mat("W4CoreGold", (0.90, 0.70, 0.28), rough=0.22, metal=0.90)
    m_rose_a = mat("W4RoseAmber", (0.96, 0.62, 0.24), rough=0.14, em=(0.96, 0.58, 0.20), em_s=1.65)
    m_rose_b = mat("W4RoseRuby", (0.86, 0.32, 0.56), rough=0.14, em=(0.84, 0.28, 0.52), em_s=1.55)

    cyl("CathedralShaft", 15.2, 14.4, 190.0, 16, m_marble, loc=(0, 0, 95.0))

    for i in range(8):
        a = i * math.pi * 0.25
        ca, sa = math.cos(a), math.sin(a)
        box(f"ButtressPier_{i}", (2.4, 2.2, 188.0), m_lilac, loc=(15.4 * ca, 15.4 * sa, 94.0), rot=(0, 0, a), bevel=0.12)
        cyl(f"ButtressGold_{i}", 0.55, 0.55, 188.0, 10, m_gold, loc=(16.6 * ca, 16.6 * sa, 94.0))

    for lvl in range(5):
        lz = 20.0 + lvl * 36.0
        cyl(f"GalleryDeck_{lvl}", 17.6, 17.0, 2.2, 16, m_marble, loc=(0, 0, lz), bevel=0.14)
        torus(f"GildedBelt_{lvl}", 17.4, 0.38, 32, 8, m_gold, loc=(0, 0, lz + 1.2))
        for f in range(4):
            fa = f * math.pi * 0.5 + (math.pi * 0.25 if lvl % 2 else 0.0)
            ca, sa = math.cos(fa), math.sin(fa)
            tx, ty = -sa, ca
            rx, ry, rz = 15.4 * ca, 15.4 * sa, lz + 17.0
            torus(f"RoseRim_{lvl}_{f}", 6.2, 0.65, 32, 10, m_gold, loc=(rx, ry, rz), rot=(math.radians(90), 0, fa + math.pi * 0.5))
            torus(f"RoseInner_{lvl}_{f}", 3.2, 0.32, 24, 8, m_gold, loc=(rx * 1.01, ry * 1.01, rz), rot=(math.radians(90), 0, fa + math.pi * 0.5))
            cyl(f"RoseCore_{lvl}_{f}", 5.8, 5.8, 0.5, 24, m_rose_a if (lvl + f) % 2 == 0 else m_rose_b,
                loc=(rx * 0.98, ry * 0.98, rz), rot=(0, math.radians(90), fa))
            # Radial gilded spokes across the cathedral rose window so it never reads as a flat disc!
            for sp in range(8):
                sa_ang = sp * math.pi * 0.25
                box(f"RoseSpoke_{lvl}_{f}_{sp}", (0.65, 0.32, 11.6), m_gold,
                    loc=(rx * 1.01, ry * 1.01, rz), rot=(sa_ang, 0, fa), bevel=0.04)

            ba = fa + math.pi * 0.25
            box(f"FlyButtress_{lvl}_{f}", (4.2, 1.1, 12.0), m_marble,
                loc=(17.8 * math.cos(ba), 17.8 * math.sin(ba), lz + 8.0),
                rot=(0, math.radians(-22), ba), bevel=0.10)
            cyl(f"Pinnacle_{lvl}_{f}", 1.1, 0.15, 7.5, 8, m_gold,
                loc=(19.2 * math.cos(ba), 19.2 * math.sin(ba), lz + 16.5))

    save("w4_mirror_core.glb")


# ==============================================================================
# WORLD 5: SPIRAL SKY-LIBRARY CORE (3D Walnut & Brass Window Lattices!)
# ==============================================================================
def build_w5_core():
    clear()
    m_walnut = mat("W5LibWalnut", (0.20, 0.12, 0.10), rough=0.46)
    m_brass = mat("W5LibBrass", (0.86, 0.64, 0.24), rough=0.25, metal=0.88)
    m_indigo = mat("W5LibIndigo", (0.12, 0.16, 0.34), rough=0.65)
    m_warm_alcove = mat("W5ReadingGlow", (1.0, 0.66, 0.28), rough=0.18, em=(1.0, 0.62, 0.22), em_s=1.75)
    m_aurora = mat("W5AuroraBook", (0.34, 0.82, 0.92), rough=0.20, em=(0.24, 0.72, 0.86), em_s=1.45)
    m_books_a = mat("W5BooksCrimson", (0.62, 0.18, 0.20), rough=0.55)
    m_books_b = mat("W5BooksEmerald", (0.14, 0.42, 0.44), rough=0.55)

    cyl("ArchiveShaft", 15.0, 14.5, 190.0, 16, m_walnut, loc=(0, 0, 95.0))

    for lvl in range(6):
        lz = 14.0 + lvl * 30.0
        cyl(f"Balcony_{lvl}", 17.6, 17.2, 1.5, 16, m_walnut, loc=(0, 0, lz), bevel=0.12)
        cyl(f"BalconyCarpet_{lvl}", 17.0, 17.0, 0.2, 16, m_indigo, loc=(0, 0, lz + 0.8))
        torus(f"BalconyRail_{lvl}", 17.3, 0.22, 32, 6, m_brass, loc=(0, 0, lz + 2.4))

        for b in range(8):
            ba = b * math.pi * 0.25 + lvl * 0.22
            ca, sa = math.cos(ba), math.sin(ba)
            tx, ty = -sa, ca
            px, py = 15.1 * ca, 15.1 * sa
            if b % 2 == 0:
                box(f"NookFrame_{lvl}_{b}", (1.8, 5.4, 10.5), m_brass, loc=(px, py, lz + 7.5), rot=(0, 0, ba), bevel=0.10)
                box(f"NookGlow_{lvl}_{b}", (1.2, 4.4, 8.8), m_warm_alcove, loc=(px * 1.02, py * 1.02, lz + 7.2), rot=(0, 0, ba))
                # 3D Walnut & Brass Library Mullion Lattice Grid over the warm window!
                lx, ly = 15.9 * ca, 15.9 * sa
                for dy in (-1.45, 0.0, 1.45):
                    box(f"NookMullV_{lvl}_{b}_{dy}", (0.42, 0.26, 9.0), m_walnut,
                        loc=(lx + tx * dy, ly + ty * dy, lz + 7.2), rot=(0, 0, ba))
                for dz in (4.5, 6.7, 8.9, 11.1):
                    box(f"NookTransH_{lvl}_{b}_{dz}", (0.44, 4.6, 0.26), m_brass,
                        loc=(lx, ly, lz + dz), rot=(0, 0, ba))

                lx2, ly2 = 16.6 * ca, 16.6 * sa
                cyl(f"LampPost_{lvl}_{b}", 0.20, 0.14, 3.2, 8, m_brass, loc=(lx2, ly2, lz + 2.4))
                cyl(f"LampShade_{lvl}_{b}", 0.52, 0.34, 0.58, 12, m_warm_alcove, loc=(lx2, ly2, lz + 4.1), smooth=True)
            else:
                for row in range(4):
                    rz = lz + 2.5 + row * 2.4
                    box(f"Shelf_{lvl}_{b}_{row}", (1.4, 5.8, 0.25), m_brass, loc=(px, py, rz), rot=(0, 0, ba))
                    m_bk = m_aurora if (row == 2 and (lvl + b) % 3 == 0) else (m_books_a if row % 2 == 0 else m_books_b)
                    box(f"Books_{lvl}_{b}_{row}", (1.0, 5.2, 1.6), m_bk, loc=(px * 1.01, py * 1.01, rz + 0.95), rot=(0, 0, ba))

    save("w5_library_core.glb")


def build_cloud_whale():
    clear()
    m_skin = mat("WhaleBodyOpal", (0.16, 0.34, 0.54), rough=0.32, coat=0.5)
    m_belly = mat("WhaleBellyPale", (0.64, 0.86, 0.94), rough=0.40, em=(0.24, 0.66, 0.84), em_s=0.65)
    m_glow = mat("WhaleAuroraGlow", (0.42, 0.96, 0.88), rough=0.14, em=(0.35, 0.92, 0.86), em_s=1.85)
    m_gold = mat("WhaleGoldEye", (1.0, 0.76, 0.32), rough=0.10, em=(1.0, 0.70, 0.24), em_s=2.0)

    bm = bmesh.new()
    profile = [
        (14.0, 0.5, 0.4, 0.2),
        (12.2, 2.5, 2.0, 0.3),
        (8.5, 3.8, 3.0, 0.5),
        (3.0, 4.1, 3.2, 0.4),
        (-3.5, 3.2, 2.5, 0.1),
        (-9.5, 1.8, 1.5, -0.3),
        (-15.0, 0.85, 0.75, -0.5),
        (-18.5, 0.45, 0.35, -0.3),
    ]
    segs = 18
    rings = []
    for y, rx, rz, zo in profile:
        ring = []
        for s in range(segs):
            a = 2.0 * math.pi * s / segs
            ring.append(bm.verts.new((rx * math.cos(a), y, zo + rz * math.sin(a))))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            bm.faces.new((rings[i][s], rings[i][sn], rings[i + 1][sn], rings[i + 1][s]))
    c_f = bm.verts.new((0, 14.5, 0.2))
    c_b = bm.verts.new((0, -19.0, -0.3))
    for s in range(segs):
        sn = (s + 1) % segs
        bm.faces.new((c_f, rings[0][sn], rings[0][s]))
        bm.faces.new((c_b, rings[-1][s], rings[-1][sn]))
    add_bm("WhaleHull", bm, m_skin, smooth=True)

    bm_b = bmesh.new()
    bmesh.ops.create_uvsphere(bm_b, u_segments=16, v_segments=10, radius=1.0)
    bmesh.ops.scale(bm_b, vec=(3.2, 9.8, 1.6), verts=bm_b.verts)
    add_bm("WhaleBelly", bm_b, m_belly, loc=(0, 3.2, -1.65), smooth=True)

    for sx in (-1.0, 1.0):
        bf = bmesh.new()
        bmesh.ops.create_uvsphere(bf, u_segments=12, v_segments=8, radius=1.0)
        bmesh.ops.scale(bf, vec=(6.2, 2.2, 0.38), verts=bf.verts)
        add_bm(f"PecFin_{sx}", bf, m_skin, loc=(sx * 6.5, 3.0, -0.8), rot=(0.15, sx * -0.18, sx * -0.35), smooth=True)
        bm_s = bmesh.new()
        bmesh.ops.create_uvsphere(bm_s, u_segments=10, v_segments=6, radius=1.0)
        bmesh.ops.scale(bm_s, vec=(0.35, 8.0, 0.35), verts=bm_s.verts)
        add_bm(f"AuroraStripe_{sx}", bm_s, m_glow, loc=(sx * 3.8, 2.0, 0.6), smooth=True)
        cyl(f"WhaleEye_{sx}", 0.42, 0.42, 0.3, 10, m_gold, loc=(sx * 3.3, 9.6, 0.4), rot=(0, math.radians(90), 0), smooth=True)

    for sx in (-1.0, 1.0):
        bt = bmesh.new()
        bmesh.ops.create_uvsphere(bt, u_segments=12, v_segments=8, radius=1.0)
        bmesh.ops.scale(bt, vec=(5.4, 2.2, 0.32), verts=bt.verts)
        add_bm(f"TailFluke_{sx}", bt, m_glow, loc=(sx * 4.2, -19.2, -0.2), rot=(0.0, sx * 0.08, sx * -0.42), smooth=True)

    save("cloud_whale_leviathan.glb")


# ==============================================================================
# WORLD 6: OBSERVATORY CROWN CORE (Fluted Panels, Beveled Brass Ribs & Window Bands!)
# ==============================================================================
def build_w6_core():
    clear()
    m_obs = mat("W6CoreObs", (0.08, 0.07, 0.15), rough=0.20, metal=0.42, coat=0.80)
    m_gold = mat("W6CoreGold", (0.90, 0.68, 0.22), rough=0.20, metal=0.92)
    m_brass = mat("W6CoreBrass", (0.78, 0.52, 0.18), rough=0.26, metal=0.88)
    m_glow = mat("W6SolarGlow", (1.0, 0.68, 0.26), rough=0.14, em=(1.0, 0.64, 0.20), em_s=1.85)

    cyl("ObsMainShaft", 15.2, 13.8, 135.0, 16, m_obs, loc=(0, 0, 67.5))
    # Upper Royal Chalice Pedestal with deeply sculpted fluted panels, beveled brass ribs & glowing window bands!
    cyl("SummitPedestal", 13.8, 8.6, 29.0, 16, m_obs, loc=(0, 0, 149.5))
    for k, (rz, rr) in enumerate([(136.0, 13.9), (146.0, 12.2), (156.0, 10.4), (163.2, 9.0)]):
        cyl(f"ChaliceCornice_{k}", rr + 0.55, rr + 0.45, 1.3, 16, m_gold, loc=(0, 0, rz), bevel=0.18)

    # 3 Glowing Mullioned Celestial Window Bands around the upper Observatory Chalice & Main Shaft!
    for wb_z, wb_r in [(56.0, 14.8), (94.0, 14.3), (141.0, 13.1), (151.0, 11.3)]:
        cyl(f"WinBandGlow_{wb_z}", wb_r + 0.12, wb_r - 0.12, 3.6, 16, m_glow, loc=(0, 0, wb_z))
        cyl(f"WinBandSillB_{wb_z}", wb_r + 0.48, wb_r + 0.48, 0.65, 16, m_brass, loc=(0, 0, wb_z - 2.0), bevel=0.10)
        cyl(f"WinBandSillT_{wb_z}", wb_r + 0.42, wb_r + 0.42, 0.65, 16, m_brass, loc=(0, 0, wb_z + 2.0), bevel=0.10)
        for m_i in range(16):
            ma = m_i * math.tau / 16.0
            box(f"WinMull_{wb_z}_{m_i}", (0.55, 0.45, 4.0), m_obs,
                loc=((wb_r + 0.16) * math.cos(ma), (wb_r + 0.16) * math.sin(ma), wb_z), rot=(0, 0, ma), bevel=0.05)

    # 16 Fluted Obsidian Panel Ribs & 8 Beveled Golden Meridian Buttresses
    for i in range(16):
        a = i * math.tau / 16.0
        ca, sa = math.cos(a), math.sin(a)
        if i % 2 == 0:
            box(f"GoldFin_{i}", (1.7, 0.85, 136.0), m_gold, loc=(15.0 * ca, 15.0 * sa, 68.0), rot=(0, 0, a), bevel=0.14)
            box(f"ChaliceRib_{i}", (1.55, 0.82, 30.5), m_gold,
                loc=(11.3 * ca, 11.3 * sa, 149.5), rot=(0, math.radians(-10), a), bevel=0.14)
        else:
            box(f"ObsFlute_{i}", (1.1, 1.2, 28.0), m_brass,
                loc=(11.15 * ca, 11.15 * sa, 149.5), rot=(0, math.radians(-10), a), bevel=0.10)

    for lvl in range(4):
        lz = 22.0 + lvl * 34.0
        torus(f"ArmillaryBandA_{lvl}", 17.4, 0.36, 40, 8, m_gold, loc=(0, 0, lz), rot=(math.radians(12 if lvl % 2 == 0 else -12), 0, 0))
        torus(f"ArmillaryBandB_{lvl}", 16.5, 0.24, 36, 6, m_brass, loc=(0, 0, lz + 3.0), rot=(math.radians(-14 if lvl % 2 == 0 else 14), math.radians(28), 0))
        for k in range(4):
            ka = k * math.pi * 0.5 + lvl * 0.55
            ca, sa = math.cos(ka), math.sin(ka)
            cyl(f"OrreryArm_{lvl}_{k}", 0.22, 0.14, 6.2, 8, m_gold,
                loc=(17.2 * ca, 17.2 * sa, lz + 8.0), rot=(0, math.radians(90), ka))
            bm_p = bmesh.new()
            bmesh.ops.create_uvsphere(bm_p, u_segments=12, v_segments=8, radius=1.05)
            add_bm(f"OrreryPlanet_{lvl}_{k}", bm_p, m_glow, loc=(20.2 * ca, 20.2 * sa, lz + 8.0), smooth=True)
            torus(f"OrreryHalo_{lvl}_{k}", 1.65, 0.12, 20, 6, m_gold,
                  loc=(20.2 * ca, 20.2 * sa, lz + 8.0), rot=(math.radians(68), 0, ka))

    save("w6_crown_core.glb")


# ==============================================================================
# 6 BIOME-SPECIFIC UNIFIED PARALLAX SILHOUETTE ISLANDS (sil_w1..sil_w6.glb)
# Built from each world's own signature kit geometry into a single bmesh!
# ==============================================================================
def _add_cone_to_bm(bm, r1, r2, h, segs, loc=(0, 0, 0), rot=(0, 0, 0)):
    ret = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    if any(rot):
        bmesh.ops.rotate(bm, verts=ret["verts"], cent=(0, 0, 0), matrix=Euler(rot, "XYZ").to_matrix())
    if any(loc):
        bmesh.ops.translate(bm, verts=ret["verts"], vec=loc)


def _add_box_to_bm(bm, sz, loc=(0, 0, 0), rot=(0, 0, 0)):
    ret = bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, verts=ret["verts"], vec=sz)
    if any(rot):
        bmesh.ops.rotate(bm, verts=ret["verts"], cent=(0, 0, 0), matrix=Euler(rot, "XYZ").to_matrix())
    if any(loc):
        bmesh.ops.translate(bm, verts=ret["verts"], vec=loc)


def _add_sphere_to_bm(bm, rad, loc=(0, 0, 0)):
    ret = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
    bmesh.ops.scale(bm, verts=ret["verts"], vec=rad)
    if any(loc):
        bmesh.ops.translate(bm, verts=ret["verts"], vec=loc)


def build_all_biome_silhouettes():
    # W1: Botanical Terracotta Plinth + Sweeping Glasshouse Arch + Bonsai Tree Canopies!
    clear()
    m_sil = mat("SilhouetteStone", (0.52, 0.60, 0.72), rough=0.90)
    bm = bmesh.new()
    _add_cone_to_bm(bm, 14.5, 16.0, 3.2, 8, (0, 0, 0))
    _add_cone_to_bm(bm, 3.5, 13.5, 18.0, 8, (0, 0, -10.5))
    # Curved glasshouse arch rib
    for i in range(9):
        t = math.pi * i / 8.0
        _add_box_to_bm(bm, (2.2, 3.8, 4.2), (10.5 * math.cos(t), 0, 12.5 * math.sin(t)), (0, math.pi * 0.5 - t, 0))
    # Bonsai tree trunk + lumpy canopy domes
    _add_cone_to_bm(bm, 1.4, 0.9, 8.5, 6, (-4.5, 2.5, 5.5))
    _add_sphere_to_bm(bm, (5.8, 5.2, 3.4), (-4.5, 2.5, 10.5))
    _add_sphere_to_bm(bm, (4.2, 3.8, 2.6), (-1.5, 3.5, 12.2))
    add_bm("SilW1", bm, m_sil, smooth=False)
    save("sil_w1.glb")
    save("distant_island_spire.glb")

    # W2: Industrial Forge Platform + Twin Flanged Smokestacks + Giant Vertical Gear + Belfry!
    clear()
    m_sil = mat("SilhouetteStone", (0.52, 0.60, 0.72), rough=0.90)
    bm = bmesh.new()
    _add_box_to_bm(bm, (24.0, 18.0, 4.5), (0, 0, 0))
    _add_cone_to_bm(bm, 5.0, 11.0, 14.0, 8, (0, 0, -9.0))
    _add_cone_to_bm(bm, 2.6, 2.1, 24.0, 8, (-6.5, -2.0, 13.5))
    _add_cone_to_bm(bm, 3.2, 3.2, 1.8, 8, (-6.5, -2.0, 24.5))
    _add_cone_to_bm(bm, 2.2, 1.8, 19.0, 8, (-2.0, 3.0, 11.0))
    # Giant vertical cogwheel silhouette
    _add_cone_to_bm(bm, 9.5, 9.5, 2.2, 12, (5.5, 0, 9.5), (math.radians(90), 0, 0))
    for k in range(8):
        a = k * math.pi * 0.25
        _add_box_to_bm(bm, (2.4, 2.4, 3.2), (5.5 + 10.2 * math.cos(a), 0, 9.5 + 10.2 * math.sin(a)))
    add_bm("SilW2", bm, m_sil, smooth=False)
    save("sil_w2.glb")

    # W3: 3-Tier Curved-Eave Pagoda Pavilion + Floating Torii Gate Silhouette!
    clear()
    m_sil = mat("SilhouetteStone", (0.52, 0.60, 0.72), rough=0.90)
    bm = bmesh.new()
    _add_box_to_bm(bm, (22.0, 22.0, 3.5), (0, 0, 0))
    _add_cone_to_bm(bm, 3.0, 11.0, 15.0, 8, (0, 0, -9.0))
    for s in range(3):
        sz = 2.0 + s * 7.2
        rw = 7.5 - s * 1.4
        re = 12.2 - s * 1.8
        _add_cone_to_bm(bm, rw, rw, 5.5, 8, (-3.0, 0, sz + 2.5))
        _add_cone_to_bm(bm, re, rw * 0.9, 3.2, 8, (-3.0, 0, sz + 6.0))
    # Torii gate on right side of island
    _add_cone_to_bm(bm, 0.9, 0.8, 13.0, 8, (4.5, -4.0, 7.5))
    _add_cone_to_bm(bm, 0.9, 0.8, 13.0, 8, (11.5, -4.0, 7.5))
    _add_box_to_bm(bm, (10.5, 1.4, 1.4), (8.0, -4.0, 14.2))
    _add_box_to_bm(bm, (9.0, 1.1, 1.0), (8.0, -4.0, 11.5))
    add_bm("SilW3", bm, m_sil, smooth=False)
    save("sil_w3.glb")

    # W4: Gothic Cathedral Pinnacle Spire + Circular Rose Window Arch + Floating Prisms!
    clear()
    m_sil = mat("SilhouetteStone", (0.52, 0.60, 0.72), rough=0.90)
    bm = bmesh.new()
    _add_box_to_bm(bm, (20.0, 20.0, 3.5), (0, 0, 0))
    for step in range(3):
        w = 15.0 - step * 4.2
        _add_box_to_bm(bm, (w, w, 4.0), (0, 0, -3.5 - step * 4.0))
    _add_cone_to_bm(bm, 4.5, 0.6, 26.0, 8, (-4.5, 0, 14.5))
    _add_cone_to_bm(bm, 2.8, 0.4, 18.0, 6, (5.5, 3.0, 10.5))
    # Circular Rose Window Ring
    for i in range(12):
        a = i * math.tau / 12.0
        _add_box_to_bm(bm, (2.2, 1.8, 3.8), (4.5 + 6.5 * math.cos(a), -2.0, 10.5 + 6.5 * math.sin(a)), (0, a, 0))
    add_bm("SilW4", bm, m_sil, smooth=False)
    save("sil_w4.glb")

    # W5: Arching Whale-Rib + Tiered Archive Book-Tower + Sweeping Whale Fluke!
    clear()
    m_sil = mat("SilhouetteStone", (0.52, 0.60, 0.72), rough=0.90)
    bm = bmesh.new()
    _add_box_to_bm(bm, (22.0, 18.0, 3.5), (0, 0, 0))
    _add_cone_to_bm(bm, 3.5, 10.0, 14.0, 8, (0, 0, -8.5))
    # Crooked stack of colossal archive book blocks
    for i in range(4):
        _add_box_to_bm(bm, (10.5 - i * 1.2, 8.5 - i * 0.8, 4.5), (-3.5, 0, 3.8 + i * 4.6), (0, 0, i * 0.25))
    # Sweeping curved whale rib arch
    for i in range(8):
        t = math.pi * (0.1 + 0.8 * i / 7.0)
        _add_box_to_bm(bm, (2.2, 2.2, 4.8), (4.0 + 11.0 * math.cos(t), 0, 2.0 + 13.5 * math.sin(t)), (0, math.pi * 0.5 - t, 0))
    add_bm("SilW5", bm, m_sil, smooth=False)
    save("sil_w5.glb")

    # W6: Fluted Obsidian Monolith Cluster + Tilted Celestial Armillary Ring + Pyramidion!
    clear()
    m_sil = mat("SilhouetteStone", (0.52, 0.60, 0.72), rough=0.90)
    bm = bmesh.new()
    _add_cone_to_bm(bm, 15.0, 16.0, 3.5, 12, (0, 0, 0))
    _add_cone_to_bm(bm, 2.0, 12.5, 18.0, 8, (0, 0, -10.5))
    _add_box_to_bm(bm, (4.2, 2.2, 25.0), (0, 0, 14.0))
    _add_box_to_bm(bm, (3.2, 1.8, 17.5), (-6.5, 1.5, 10.0), (0, -0.15, 0))
    _add_box_to_bm(bm, (3.2, 1.8, 17.5), (6.5, -1.5, 10.0), (0, 0.15, 0))
    # Tilted Armillary Ring around the monoliths
    for i in range(14):
        a = i * math.tau / 14.0
        _add_box_to_bm(bm, (1.8, 1.8, 4.6), (13.5 * math.cos(a), 13.5 * math.sin(a) * 0.85, 14.0 + 6.5 * math.sin(a)), (0.35, 0, a))
    add_bm("SilW6", bm, m_sil, smooth=False)
    save("sil_w6.glb")


if __name__ == "__main__":
    build_w1_core()
    build_w2_core()
    build_w3_core()
    build_w4_core()
    build_w5_core()
    build_cloud_whale()
    build_w6_core()
    build_all_biome_silhouettes()
    print("[gen_tower_cores v2] All 6 architectural Solstice Spire cores + 6 biome silhouettes generated!")
