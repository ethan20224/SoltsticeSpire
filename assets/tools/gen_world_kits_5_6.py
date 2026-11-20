"""
Blender 5.2.1 LTS Asset Kit Generator - Worlds 5 & 6 (v3 AAA Sculpted Polish)
  World 5 (The Cloud-Whale Library): opal_whale_rib, floating_bookshelf, luminous_tome, dream_jelly_pad
  World 6 (The Crown of the Sun): obsidian_monolith, obsidian_dais, solar_ring, summit_crown_altar

Every walkable platform keeps its walkable top deck at Z=0 (and inner shrine pedestal at Z=0.38 on summit_crown_altar)
and preserves all collision dimensions!
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector

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
    return add_bm(name, bm, m, smooth=True, bevel=0.0)


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


def save(out_dir, fname):
    join_by_material()
    p = os.path.join(out_dir, fname)
    bpy.ops.export_scene.gltf(filepath=p, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[world_kits_5_6] Exported {p}")


def gen_w5():
    # 1. Colossal Continuous Tapered Opal Levitating Cloud-Whale Rib Arch
    clear()
    m_opal = mat("WhaleOpal", (0.42, 0.74, 0.84), rough=0.18, em=(0.12, 0.44, 0.62), em_s=0.48, coat=0.85)
    m_aurora = mat("WhaleAurora", (0.18, 0.86, 0.76), rough=0.12, em=(0.14, 0.78, 0.72), em_s=1.10)

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

    # 2. Ornate Dark-Walnut Arched Library Balcony & Varied Tilted Bookshelf (5.2m x 4.4m, top at Z=0)
    clear()
    m_wood = mat("LibWalnut", (0.20, 0.11, 0.09), rough=0.40, coat=0.35)
    m_brass = mat("LibBrass", (0.90, 0.72, 0.30), rough=0.22, metal=0.90)
    m_carpet = mat("LibIndigo", (0.15, 0.19, 0.44), rough=0.78)
    m_carpet_trim = mat("LibCarpetGold", (0.86, 0.64, 0.22), rough=0.36, metal=0.65)
    book_mats = [
        mat("BookRed", (0.68, 0.18, 0.22), rough=0.52),
        mat("BookTeal", (0.14, 0.50, 0.56), rough=0.52),
        mat("BookForest", (0.16, 0.44, 0.24), rough=0.52),
        mat("BookPlum", (0.42, 0.22, 0.52), rough=0.52),
    ]
    m_spine_gold = mat("BookSpineGold", (0.94, 0.74, 0.26), rough=0.22, metal=0.88)

    box("FloorDeck", (5.16, 4.36, 0.46), m_wood, loc=(0, 0, -0.23), bevel=0.05)
    # Cozy inlaid indigo library rug with golden woven border (flush at Z=0!)
    box("CarpetBorder", (4.35, 3.45, 0.045), m_carpet_trim, loc=(0, 0.12, -0.015), bevel=0.015)
    box("Carpet", (4.05, 3.15, 0.05), m_carpet, loc=(0, 0.12, -0.012), bevel=0.015)
    box("BrassTrim", (5.30, 4.50, 0.14), m_brass, loc=(0, 0, -0.09), bevel=0.025)

    # 4 Carved dark-walnut corbel brackets beneath the balcony floor
    for cx in (-1.95, -0.65, 0.65, 1.95):
        corbel_pts = [Vector((cx, -1.75, -0.98)), Vector((cx, -1.15, -0.78)), Vector((cx, -0.20, -0.58)), Vector((cx, 1.55, -0.44))]
        sweep_tube(f"Corbel_{cx}", corbel_pts, [0.22, 0.20, 0.17, 0.12], m_wood, segs=6)

    # Arched dark-walnut bookcase canopy & fluted side pilasters
    box("ShelfBack", (4.84, 0.36, 3.95), m_wood, loc=(0, -1.96, 1.92), bevel=0.04)
    for sx in (-2.38, 2.38):
        box(f"Pilaster_{sx}", (0.34, 0.68, 4.15), m_wood, loc=(sx, -1.80, 2.00), bevel=0.03)
        box(f"PilasterCap_{sx}", (0.42, 0.76, 0.18), m_brass, loc=(sx, -1.80, 4.05), bevel=0.02)
    # Curved arched crown molding atop the bookcase
    arch_pts = [Vector((2.6 * math.cos(math.pi * i / 12), -1.78, 3.95 + 0.85 * math.sin(math.pi * i / 12))) for i in range(13)]
    sweep_tube("BookcaseArchCrown", arch_pts, [0.22] * len(arch_pts), m_wood, segs=6)
    arch_gold_pts = [Vector((2.45 * math.cos(math.pi * i / 12), -1.62, 3.95 + 0.78 * math.sin(math.pi * i / 12))) for i in range(13)]
    sweep_tube("BookcaseArchTrim", arch_gold_pts, [0.06] * len(arch_gold_pts), m_brass, segs=6)

    # 4 Shelf tiers populated with varied-height, varied-thickness & slightly tilted sculpted leather books + gold spine bands!
    for row in range(4):
        rz = 0.52 + row * 0.88
        box(f"Shelf{row}", (4.56, 0.62, 0.12), m_wood, loc=(0, -1.78, rz), bevel=0.02)
        box(f"ShelfLip{row}", (4.56, 0.08, 0.08), m_brass, loc=(0, -1.46, rz), bevel=0.01)
        x_cursor = -2.02
        bi = 0
        while x_cursor < 1.96:
            h_var = 0.50 + ((bi * 7 + row * 5) % 5) * 0.055
            w_var = 0.22 + ((bi * 3 + row * 2) % 3) * 0.055
            # Lean every 5th book slightly at the end of a group for natural cozy library character!
            lean = 0.0
            if bi % 5 == 4 and x_cursor < 1.75:
                lean = 0.16
                x_cursor += 0.06
            bx = x_cursor + w_var * 0.5
            bz = rz + 0.06 + h_var * 0.5
            bm_sel = book_mats[(bi + row * 2) % len(book_mats)]
            box(f"Book_{row}_{bi}", (w_var * 0.88, 0.42, h_var), bm_sel, loc=(bx, -1.76, bz), rot=(0, lean, 0), bevel=0.018)
            # Gold-embossed horizontal spine bands on the front spine (+Y)
            for band_z in (-h_var * 0.28, h_var * 0.28):
                dx_b = -band_z * math.sin(lean)
                dz_b = band_z * math.cos(lean)
                box(f"BookBand_{row}_{bi}_{band_z:.2f}", (w_var * 0.90, 0.04, 0.045), m_spine_gold,
                    loc=(bx + dx_b, -1.55, bz + dz_b), rot=(0, lean, 0), bevel=0.008)
            x_cursor += w_var + (0.04 if lean > 0 else 0.01)
            bi += 1
    save(OUT_W5, "floating_bookshelf.glb")

    # 3. Sculpted Open Leather-and-Gold Storybook with Curved Page Spreads & Silk Bookmark Ribbon (3.8m x 2.9m, top near Z=0)
    clear()
    m_cover = mat("TomeCover", (0.18, 0.14, 0.36), rough=0.38, coat=0.38)
    m_page = mat("TomePages", (0.98, 0.94, 0.85), rough=0.56, em=(0.86, 0.82, 0.70), em_s=0.18)
    m_gold = mat("TomeGold", (0.94, 0.74, 0.28), rough=0.22, metal=0.90)
    m_ribbon = mat("TomeSilkRibbon", (0.98, 0.72, 0.22), rough=0.32, em=(0.94, 0.64, 0.16), em_s=0.85)

    # Leather covers + gold spine & corner metal guards
    box("CoverL", (1.92, 2.86, 0.18), m_cover, loc=(-0.98, 0, -0.26), rot=(0, math.radians(-3.5), 0), bevel=0.03)
    box("CoverR", (1.92, 2.86, 0.18), m_cover, loc=(0.98, 0, -0.26), rot=(0, math.radians(3.5), 0), bevel=0.03)
    cyl("Spine", 0.22, 0.22, 2.90, 12, m_gold, loc=(0, 0, -0.28), rot=(math.radians(90), 0, 0), bevel=0.02)
    for sx in (-1.86, 1.86):
        for sy in (-1.34, 1.34):
            box(f"CornerGuard_{sx}_{sy}", (0.24, 0.24, 0.21), m_gold, loc=(sx, sy, -0.21), bevel=0.02)

    # Sculpted curved open page spreads (L & R) with deckled layered page edges!
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        # Stepped lower page block
        box(f"PageBlock{side}", (1.72, 2.58, 0.16), m_page, loc=(sx * 0.92, 0, -0.14), rot=(0, sx * math.radians(3), 0), bevel=0.025)
        # Gracefully arched top page sheet curving out from center gutter
        bm_pg = bmesh.new()
        u_n, v_n = 9, 4
        grid = []
        for ui in range(u_n):
            u = ui / (u_n - 1)  # 0 spine gutter -> 1 outer page edge
            px = sx * (0.04 + u * 1.76)
            # Gentle open-book S-arch settling cleanly near Z=0 for smooth landing!
            pz = -0.06 + math.sin(u * math.pi) * 0.095 - 0.02 * u
            row = []
            for vi in range(v_n):
                py = -1.26 + (vi / (v_n - 1)) * 2.52
                row.append(bm_pg.verts.new((px, py, pz)))
            grid.append(row)
        for ui in range(u_n - 1):
            for vi in range(v_n - 1):
                verts = (grid[ui][vi], grid[ui + 1][vi], grid[ui + 1][vi + 1], grid[ui][vi + 1])
                bm_pg.faces.new(verts if sx > 0 else verts[::-1])
        bmesh.ops.solidify(bm_pg, geom=bm_pg.faces[:], thickness=0.055)
        add_bm(f"CurvedPageSheet{side}", bm_pg, m_page, smooth=True, bevel=0.01)

    # Subtle glowing golden calligraphy lines on pages
    for ly in (0.65, 0.25, -0.15, -0.55):
        box(f"RuneL_{ly}", (1.15, 0.08, 0.02), m_gold, loc=(-0.92, ly, 0.03), bevel=0.005)
        box(f"RuneR_{ly}", (1.15, 0.08, 0.02), m_gold, loc=(0.92, ly, 0.03), bevel=0.005)

    # Glowing golden silk bookmark ribbon draped down the spine gutter and trailing over the front edge
    rib_pts = [
        Vector((0.0, 1.25, -0.03)),
        Vector((0.02, 0.35, -0.04)),
        Vector((-0.02, -0.65, -0.04)),
        Vector((0.04, -1.32, -0.08)),
        Vector((0.08, -1.48, -0.45)),
        Vector((0.12, -1.40, -0.92)),
    ]
    sweep_tube("SilkBookmarkRibbon", rib_pts, [0.06, 0.06, 0.06, 0.065, 0.055, 0.075], m_ribbon, segs=6)
    save(OUT_W5, "luminous_tome.glb")

    # 4. Domed Ribbed Translucent Aurora Jellyfish Bounce Pad (radius ~2.4m, top near Z=0!)
    clear()
    # 'Aurora' in name triggers luminous __jewel_glass_v2__ translucent sheen in world_helper.gd!
    m_bell = mat("JellyBellAurora", (0.18, 0.62, 0.88), rough=0.12, em=(0.12, 0.56, 0.86), em_s=0.72, coat=0.95)
    m_rib = mat("JellyRibAurora", (0.42, 0.90, 0.96), rough=0.10, em=(0.36, 0.84, 0.96), em_s=1.05)
    m_core = mat("JellyCoreAurora", (0.70, 0.34, 0.98), rough=0.12, em=(0.64, 0.28, 0.94), em_s=1.10)

    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=14, radius=1.0)
    for v in bm.verts:
        if v.co.z < 0.0:
            v.co.z *= 0.20
        v.co.x *= 2.38
        v.co.y *= 2.38
        v.co.z *= 0.72
    add_bm("BellDome", bm, m_bell, loc=(0, 0, -0.52), smooth=True, bevel=0.0)
    torus("BellRim", 2.26, 0.15, 28, 10, m_core, loc=(0, 0, -0.58))
    # 12 Raised radial glowing ribs arching across the jellyfish dome
    for i in range(12):
        a = i * math.tau / 12.0
        ca, sa = math.cos(a), math.sin(a)
        rib_pts = []
        for s in range(6):
            t = s / 5.0
            rr = 0.20 + t * 2.12
            zz = -0.52 + 0.70 * math.cos(t * math.pi * 0.5)
            rib_pts.append(Vector((rr * ca, rr * sa, zz)))
        sweep_tube(f"DomeRib_{i}", rib_pts, [0.055, 0.060, 0.055, 0.050, 0.045, 0.065], m_rib, segs=6)

    # 8 Graceful S-curled glowing tentacles underneath
    for i in range(8):
        a = i * math.tau / 8.0
        ca, sa = math.cos(a), math.sin(a)
        tx_p, ty_p = -sa, ca
        r_root = 1.05 + (i % 2) * 0.42
        t_pts = [
            Vector((r_root * ca, r_root * sa, -0.64)),
            Vector(((r_root + 0.16) * ca + 0.18 * tx_p, (r_root + 0.16) * sa + 0.18 * ty_p, -1.35)),
            Vector(((r_root - 0.12) * ca - 0.22 * tx_p, (r_root - 0.12) * sa - 0.22 * ty_p, -2.15)),
            Vector(((r_root + 0.10) * ca + 0.14 * tx_p, (r_root + 0.10) * sa + 0.14 * ty_p, -2.95)),
            Vector(((r_root - 0.05) * ca, (r_root - 0.05) * sa, -3.55)),
        ]
        sweep_tube(f"CurledTentacle_{i}", t_pts, [0.11, 0.085, 0.065, 0.042, 0.018], m_core if i % 2 == 0 else m_rib, segs=6)
    save(OUT_W5, "dream_jelly_pad.glb")


def gen_w6():
    # 1. Fluted Beveled Obsidian Wall-Run Monolith with Inlaid Glowing Gold Astronomical Runes (9.4m x 4.5m x ~0.85m)
    clear()
    m_obs = mat("Obsidian", (0.08, 0.07, 0.13), rough=0.18, metal=0.38, coat=0.88)
    m_bronze = mat("MonolithBronze", (0.76, 0.52, 0.18), rough=0.26, metal=0.90)
    m_gold = mat("LiquidGold", (1.0, 0.78, 0.28), rough=0.16, metal=0.92, em=(1.0, 0.70, 0.20), em_s=2.0)

    box("MonolithBody", (9.35, 0.76, 4.45), m_obs, loc=(0, 0, 0), bevel=0.08)
    # Ornate bronze & gold stepped cornice beams top & bottom
    box("CrownBar", (9.65, 0.96, 0.34), m_bronze, loc=(0, 0, 2.26), bevel=0.045)
    box("BaseBar", (9.65, 0.96, 0.34), m_bronze, loc=(0, 0, -2.26), bevel=0.045)
    box("CrownGoldLip", (9.45, 0.88, 0.14), m_gold, loc=(0, 0, 2.02), bevel=0.02)
    box("BaseGoldLip", (9.45, 0.88, 0.14), m_gold, loc=(0, 0, -2.02), bevel=0.02)

    # Fluted obsidian pilasters & inlaid glowing gold astronomical runes on both ±Y faces
    for px in (-3.6, -1.8, 0.0, 1.8, 3.6):
        box(f"FlutePilaster_{px}", (0.34, 0.88, 4.05), m_obs, loc=(px, 0, 0), bevel=0.04)
        box(f"PilasterGoldTrim_{px}", (0.12, 0.91, 3.85), m_bronze, loc=(px, 0, 0), bevel=0.015)
    for cx in (-2.7, -0.9, 0.9, 2.7):
        for sy in (-0.39, 0.39):
            torus(f"AstroRing_{cx}_{sy}", 0.56, 0.045, 20, 6, m_gold, loc=(cx, sy, 0.0), rot=(math.radians(90), 0, 0))
            torus(f"AstroInner_{cx}_{sy}", 0.26, 0.032, 16, 6, m_gold, loc=(cx, sy, 0.22), rot=(math.radians(90), 0, 0))
            box(f"AstroAxis_{cx}_{sy}", (0.07, 0.06, 2.65), m_gold, loc=(cx, sy, 0.0), bevel=0.01)
            box(f"AstroDiagA_{cx}_{sy}", (0.06, 0.06, 1.25), m_gold, loc=(cx, sy, 0.0), rot=(0, math.radians(45), 0), bevel=0.01)
            box(f"AstroDiagB_{cx}_{sy}", (0.06, 0.06, 1.25), m_gold, loc=(cx, sy, 0.0), rot=(0, math.radians(-45), 0), bevel=0.01)
    save(OUT_W6, "obsidian_monolith.glb")

    # 2. Fluted Beveled Obsidian Sundial Dais with Inlaid Gold Astronomical Runes & Bronze Trim (radius 3.0m, top at Z=0)
    clear()
    m_obs = mat("DaisObs", (0.09, 0.08, 0.15), rough=0.18, metal=0.38, coat=0.85)
    m_bronze = mat("DaisBronze", (0.76, 0.52, 0.18), rough=0.26, metal=0.90)
    m_gold = mat("DaisGold", (1.0, 0.78, 0.28), rough=0.16, metal=0.92, em=(1.0, 0.70, 0.22), em_s=1.8)

    cyl("TopDisc", 2.94, 3.02, 0.42, 16, m_obs, loc=(0, 0, -0.21), bevel=0.05)
    torus("OuterBronzeRim", 2.98, 0.11, 36, 8, m_bronze, loc=(0, 0, -0.04))
    torus("OuterGold", 2.74, 0.055, 36, 8, m_gold, loc=(0, 0, -0.01))
    torus("InnerGold", 1.48, 0.05, 28, 8, m_gold, loc=(0, 0, -0.008))
    # 12 Astronomical sundial rays & degree markers inlaid flush on top deck
    for i in range(12):
        a = i * math.tau / 12.0
        box(f"SundialRay_{i}", (1.20, 0.08, 0.03), m_gold, loc=(2.10 * math.cos(a), 2.10 * math.sin(a), -0.008), rot=(0, 0, a), bevel=0.008)
        # Fluted vertical obsidian ribs around the lower drum
        box(f"DrumFlute_{i}", (0.28, 0.28, 1.08), m_obs, loc=(2.18 * math.cos(a), 2.18 * math.sin(a), -0.96), rot=(0, 0, a), bevel=0.03)
    cyl("LowerTier", 1.75, 2.52, 1.12, 16, m_obs, loc=(0, 0, -0.98), bevel=0.05)
    torus("MidBronzeRing", 2.15, 0.08, 32, 8, m_bronze, loc=(0, 0, -1.48))
    cyl("UnderPoint", 0.30, 1.55, 1.85, 12, m_obs, loc=(0, 0, -2.44), bevel=0.04)
    save(OUT_W6, "obsidian_dais.glb")

    # 3. Delicate Open-Work Filigreed Astronomical Brass Armillary Ring
    clear()
    m_brass = mat("ArmillaryBrass", (0.86, 0.64, 0.22), rough=0.22, metal=0.92)
    m_copper = mat("ArmillaryCopper", (0.72, 0.40, 0.18), rough=0.28, metal=0.86)
    m_gem = mat("ArmillarySunGem", (1.0, 0.78, 0.32), rough=0.10, em=(1.0, 0.72, 0.24), em_s=3.0)

    torus("OuterRail", 18.8, 0.16, 64, 8, m_brass, loc=(0, 0, 0.32))
    torus("InnerRail", 18.8, 0.16, 64, 8, m_brass, loc=(0, 0, -0.32))
    torus("EquatorWire", 17.8, 0.10, 64, 6, m_copper, loc=(0, 0, 0.0))

    for i in range(32):
        a = i * math.tau / 32.0
        ca, sa = math.cos(a), math.sin(a)
        if i % 4 == 0:
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

    # 4. Summit Crown Sanctuary Altar (radius 9.7m, outer sunburst floor at Z=0, stepped inner shrine plinth at Z=0.38)
    clear()
    m_marble = mat("SummitMarble", (0.82, 0.77, 0.68), rough=0.26, coat=0.48)
    m_obs = mat("SummitObs", (0.07, 0.06, 0.13), rough=0.18, metal=0.42, coat=0.85)
    m_gold = mat("SummitGold", (0.92, 0.68, 0.22), rough=0.16, metal=0.94, em=(0.90, 0.62, 0.16), em_s=0.35)
    m_sun = mat("SummitSunGlow", (1.0, 0.66, 0.22), rough=0.12, em=(1.0, 0.60, 0.18), em_s=2.0)

    # Outer dais floor (radius 9.7m, top at Z=0!)
    cyl("OuterTerrace", 9.60, 9.72, 0.85, 24, m_obs, loc=(0, 0, -0.425), bevel=0.06)
    cyl("UnderBase", 2.40, 8.80, 4.5, 20, m_obs, loc=(0, 0, -3.10), bevel=0.08)
    torus("GoldRimOuter", 9.66, 0.16, 48, 10, m_gold, loc=(0, 0, -0.04))
    torus("SunburstRingMid", 7.85, 0.08, 48, 8, m_gold, loc=(0, 0, -0.01))

    # Layered concentric golden sunburst mosaic rays on outer dais floor (flush at Z=0!)
    for i in range(16):
        a = i * math.tau / 16.0
        ray_w = 0.26 if i % 2 == 0 else 0.14
        box(f"SunRay_{i}", (2.90, ray_w, 0.03), m_gold, loc=(8.10 * math.cos(a), 8.10 * math.sin(a), -0.01), rot=(0, 0, a), bevel=0.008)

    # Stepped gilded rim stairs rising smoothly to inner sanctuary pedestal (top at Z=0.38 so Summit Shrine sits flush!)
    cyl("StepTerraceA", 7.20, 7.25, 0.14, 24, m_obs, loc=(0, 0, 0.06), bevel=0.03)
    torus("StepRimGoldA", 7.22, 0.06, 48, 8, m_gold, loc=(0, 0, 0.12))
    cyl("StepTerraceB", 6.85, 6.90, 0.14, 24, m_obs, loc=(0, 0, 0.19), bevel=0.03)
    torus("StepRimGoldB", 6.87, 0.06, 48, 8, m_gold, loc=(0, 0, 0.25))
    cyl("InnerTerrace", 6.50, 6.55, 0.14, 24, m_marble, loc=(0, 0, 0.31), bevel=0.03)
    torus("GoldRimInner", 6.52, 0.09, 44, 8, m_gold, loc=(0, 0, 0.37))
    # Concentric sunburst mosaic rings on inner marble floor (flush at Z=0.38)
    for rr in (4.6, 2.8, 1.3):
        torus(f"InnerMosaic_{rr}", rr, 0.055, 36, 6, m_gold, loc=(0, 0, 0.38))
    for i in range(12):
        a = i * math.tau / 12.0
        box(f"InnerSunRay_{i}", (4.80, 0.13, 0.025), m_gold, loc=(3.80 * math.cos(a), 3.80 * math.sin(a), 0.38), rot=(0, 0, a), bevel=0.005)

    # 8 Fluted Beveled Gold-Inlaid Obsidian Obelisks crowned by floating golden crystalline octahedrons!
    for i in range(8):
        a = i * math.pi * 0.25 + math.pi * 0.125
        rx, ry = 8.45 * math.cos(a), 8.45 * math.sin(a)
        # Beveled obsidian plinth base
        box(f"ObeliskPlinth_{i}", (1.12, 1.12, 0.62), m_obs, loc=(rx, ry, 0.31), rot=(0, 0, a), bevel=0.05)
        box(f"ObeliskPlinthGold_{i}", (1.18, 1.18, 0.12), m_gold, loc=(rx, ry, 0.58), rot=(0, 0, a), bevel=0.02)
        # Tapered 4-sided chamfered/fluted obsidian obelisk shaft
        cyl(f"ObeliskShaft_{i}", 0.52, 0.28, 6.6, 8, m_obs, loc=(rx, ry, 3.88), rot=(0, 0, a), bevel=0.04)
        # Gold inlay strips along the 4 cardinal faces of the obelisk + gold collar bands
        for fi in range(4):
            fa = a + fi * math.pi * 0.5
            box(f"ObeliskInlay_{i}_{fi}", (0.09, 0.06, 5.8), m_gold,
                loc=(rx + 0.39 * math.cos(fa), ry + 0.39 * math.sin(fa), 3.85),
                rot=(0, -math.radians(2.1) if fi % 2 == 0 else math.radians(2.1), fa), bevel=0.01)
        for cz_o, cr_o in [(2.2, 0.48), (4.6, 0.40), (6.8, 0.32)]:
            torus(f"ObeliskCollar_{i}_{cz_o}", cr_o, 0.045, 16, 6, m_gold, loc=(rx, ry, cz_o))
        # Pointed pyramidion cap
        cyl(f"ObeliskTip_{i}", 0.30, 0.02, 1.15, 4, m_gold, loc=(rx, ry, 7.72), rot=(0, 0, a + math.pi * 0.25), bevel=0.015)
        # Floating golden crystalline octahedron hovering above each obelisk!
        bm_oct = bmesh.new()
        vo_t = bm_oct.verts.new((0, 0, 0.58))
        vo_b = bm_oct.verts.new((0, 0, -0.58))
        vo_ring = [bm_oct.verts.new((0.36 * math.cos(k * math.pi * 0.5), 0.36 * math.sin(k * math.pi * 0.5), 0)) for k in range(4)]
        for k in range(4):
            kn = (k + 1) % 4
            bm_oct.faces.new((vo_ring[k], vo_ring[kn], vo_t))
            bm_oct.faces.new((vo_ring[kn], vo_ring[k], vo_b))
        add_bm(f"CrystalOct_{i}", bm_oct, m_sun, loc=(rx, ry, 8.95), rot=(0, 0, a), bevel=0.015)

        # Ornate Scalloped Golden Fire Braziers between obelisks
        ba = a + math.pi * 0.125
        bx, by = 8.40 * math.cos(ba), 8.40 * math.sin(ba)
        cyl(f"BrazBase_{i}", 0.42, 0.26, 0.92, 12, m_obs, loc=(bx, by, 0.46), bevel=0.03)
        torus(f"BrazCollar_{i}", 0.28, 0.055, 16, 6, m_gold, loc=(bx, by, 0.92))
        # Scalloped 12-petal gilded fire bowl
        for pi in range(12):
            pa = pi * math.tau / 12.0
            box(f"BrazPetal_{i}_{pi}", (0.18, 0.16, 0.30), m_gold,
                loc=(bx + 0.34 * math.cos(pa), by + 0.34 * math.sin(pa), 1.06),
                rot=(0, math.radians(-32), pa), bevel=0.02)
        cyl(f"BrazCup_{i}", 0.24, 0.46, 0.26, 12, m_gold, loc=(bx, by, 1.04), bevel=0.02)
        bm_f = bmesh.new()
        bmesh.ops.create_icosphere(bm_f, subdivisions=1, radius=0.25)
        add_bm(f"BrazFlame_{i}", bm_f, m_sun, loc=(bx, by, 1.24), smooth=True, bevel=0.0)
        for r_i in range(4):
            ra = r_i * math.pi * 0.5
            rib_pts = [
                Vector((bx + 0.36 * math.cos(ra), by + 0.36 * math.sin(ra), 1.12)),
                Vector((bx + 0.32 * math.cos(ra), by + 0.32 * math.sin(ra), 1.38)),
                Vector((bx + 0.12 * math.cos(ra), by + 0.12 * math.sin(ra), 1.56)),
            ]
            sweep_tube(f"BrazRib_{i}_{r_i}", rib_pts, [0.032, 0.028, 0.024], m_obs, segs=6)
        cyl(f"BrazFinial_{i}", 0.14, 0.02, 0.20, 8, m_gold, loc=(bx, by, 1.66), bevel=0.01)

    torus("SummitHaloA", 5.5, 0.14, 48, 8, m_gold, loc=(0, 0, 10.5), rot=(math.radians(15), 0, 0))
    torus("SummitHaloB", 3.8, 0.11, 40, 8, m_gold, loc=(0, 0, 10.5), rot=(math.radians(-22), math.radians(30), 0))
    bm_s = bmesh.new()
    bmesh.ops.create_icosphere(bm_s, subdivisions=2, radius=1.25)
    add_bm("SummitSunOrb", bm_s, m_sun, loc=(0, 0, 10.5), smooth=True, bevel=0.0)
    save(OUT_W6, "summit_crown_altar.glb")


if __name__ == "__main__":
    gen_w5()
    gen_w6()
    print("[world_kits_5_6] Worlds 5 & 6 AAA kits complete!")
