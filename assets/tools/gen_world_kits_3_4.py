"""
Blender 5.2.1 LTS Asset Kit Generator - Worlds 3 & 4 (AAA Sculpted Polish)
  World 3 (The Origami Monsoon): origami_crane, silk_parasol, pagoda_eave, folded_tile, paper_lantern
  World 4 (The Shattered Mirror Gallery): gilded_portal_frame, marble_stair_arch, crystal_prism, mirror_wall_panel, shatter_pane

Every walkable platform keeps its clean walkable top deck at Z=0 and preserves collision dimensions!
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector

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
    print(f"[world_kits_3_4] Exported {p}")


# ==============================================================================
# WORLD 3 - THE ORIGAMI MONSOON
# ==============================================================================
def gen_w3():
    # 1. Monumental Sculpted Origami Crane with Crisp Folds & Gold-Foil Geometric Trim
    clear()
    m_paper = mat("CranePaper", (0.97, 0.94, 0.87), rough=0.50)
    m_gold = mat("CraneGold", (0.96, 0.76, 0.28), rough=0.22, metal=0.88)
    m_crimson = mat("CraneRed", (0.86, 0.22, 0.20), rough=0.42)

    bm = bmesh.new()
    v_f = bm.verts.new((0, 2.35, 0.12))
    v_b = bm.verts.new((0, -2.15, 0.22))
    v_l = bm.verts.new((-1.15, 0.0, 0.0))
    v_r = bm.verts.new((1.15, 0.0, 0.0))
    v_t = bm.verts.new((0, 0.10, 1.05))
    v_d = bm.verts.new((0, 0.0, -0.82))
    for f in [(v_f, v_r, v_t), (v_r, v_b, v_t), (v_b, v_l, v_t), (v_l, v_f, v_t),
              (v_f, v_d, v_r), (v_r, v_d, v_b), (v_b, v_d, v_l), (v_l, v_d, v_f)]:
        bm.faces.new(f)
    add_bm("CraneBody", bm, m_paper, bevel=0.02)

    # Gold-foil spine diamond crest on crane back
    bm_crest = bmesh.new()
    c_f = bm_crest.verts.new((0, 1.35, 0.62))
    c_b = bm_crest.verts.new((0, -1.25, 0.68))
    c_l = bm_crest.verts.new((-0.55, 0.05, 0.54))
    c_r = bm_crest.verts.new((0.55, 0.05, 0.54))
    c_t = bm_crest.verts.new((0, 0.08, 1.14))
    for f in [(c_f, c_r, c_t), (c_r, c_b, c_t), (c_b, c_l, c_t), (c_l, c_f, c_t)]:
        bm_crest.faces.new(f)
    add_bm("SpineGoldCrest", bm_crest, m_gold, bevel=0.01)

    # Multi-pleated crisp origami wings + gold-foil leading-edge trim
    for sx in (-1.0, 1.0):
        wb = bmesh.new()
        w0 = wb.verts.new((sx * 0.85, 1.25, 0.16))
        w1 = wb.verts.new((sx * 0.85, -1.20, 0.22))
        w_mid_f = wb.verts.new((sx * 2.85, 0.75, 1.05))
        w_mid_c = wb.verts.new((sx * 2.95, 0.05, 0.70))
        w_mid_b = wb.verts.new((sx * 2.75, -0.75, 0.95))
        w_tip = wb.verts.new((sx * 5.35, -0.35, 1.78))
        w_bot = wb.verts.new((sx * 2.85, 0.05, 0.42))
        tris = [
            (w0, w_mid_c, w_mid_f), (w_mid_f, w_mid_c, w_tip),
            (w_mid_c, w1, w_mid_b), (w_mid_c, w_mid_b, w_tip),
            (w0, w1, w_mid_c),
            (w0, w_mid_f, w_bot), (w_mid_f, w_tip, w_bot),
            (w_tip, w_mid_b, w_bot), (w_mid_b, w1, w_bot), (w1, w0, w_bot),
        ]
        for t in tris:
            wb.faces.new(t if sx > 0 else t[::-1])
        add_bm(f"CraneWing{sx}", wb, m_paper, bevel=0.02)

        # Gold-foil leading-edge & wingtip geometric trim strips
        edge_pts = [
            Vector((sx * 0.90, 1.25, 0.18)),
            Vector((sx * 2.85, 0.75, 1.07)),
            Vector((sx * 5.35, -0.35, 1.80)),
        ]
        sweep_tube(f"WingGoldTrim{sx}", edge_pts, [0.06, 0.055, 0.035], m_gold, segs=4)

    cyl("Neck", 0.36, 0.18, 2.85, 4, m_paper, loc=(0, 2.45, 1.25), rot=(math.radians(-34), 0, 0), bevel=0.02)
    cyl("NeckGoldBand", 0.24, 0.20, 0.24, 4, m_gold, loc=(0, 3.05, 2.05), rot=(math.radians(-34), 0, 0), bevel=0.01)
    cyl("HeadBeak", 0.22, 0.03, 1.35, 4, m_crimson, loc=(0, 3.65, 2.25), rot=(math.radians(-108), 0, 0), bevel=0.015)
    cyl("TailSpire", 0.44, 0.06, 3.3, 4, m_gold, loc=(0, -2.55, 1.45), rot=(math.radians(38), 0, 0), bevel=0.02)
    save(OUT_W3, "origami_crane.glb")

    # 2. Graceful 16-Rib Scalloped Vermilion-and-Gold Oil-Paper Parasol Bounce Pad (radius ~2.4m, peak near Z=0)
    clear()
    m_silk = mat("ParasolVermilion", (0.88, 0.20, 0.18), rough=0.38, coat=0.35)
    m_cream = mat("ParasolCream", (0.98, 0.93, 0.82), rough=0.42, coat=0.25)
    m_gold = mat("ParasolGold", (0.94, 0.74, 0.28), rough=0.22, metal=0.88)
    m_bamboo = mat("ParasolBamboo", (0.44, 0.28, 0.14), rough=0.48)

    # Scalloped 16-rib domed canopy mesh (top near Z=0, outer radius 2.42m)
    bm_can = bmesh.new()
    rib_n = 16
    ring_radii = [0.06, 0.75, 1.45, 2.05, 2.42]
    ring_zs = [-0.02, -0.09, -0.24, -0.44, -0.62]
    can_rings = []
    for ri, (rr, rz) in enumerate(zip(ring_radii, ring_zs)):
        ring = []
        for s in range(rib_n * 2):
            a = s * math.tau / (rib_n * 2)
            # Every odd vertex is mid-gore (slightly tucked inward & arched up for scalloped umbrella folds!)
            is_mid = (s % 2 == 1)
            r_eff = rr * (0.94 if (is_mid and ri >= 2) else 1.0)
            z_eff = rz + (0.045 if (is_mid and ri >= 2) else 0.0)
            ring.append(bm_can.verts.new((r_eff * math.cos(a), r_eff * math.sin(a), z_eff)))
        can_rings.append(ring)
    for ri in range(len(can_rings) - 1):
        for s in range(rib_n * 2):
            sn = (s + 1) % (rib_n * 2)
            bm_can.faces.new((can_rings[ri][s], can_rings[ri][sn], can_rings[ri + 1][sn], can_rings[ri + 1][s]))
    bmesh.ops.solidify(bm_can, geom=bm_can.faces[:], thickness=0.045)
    add_bm("ScallopedCanopy", bm_can, m_silk, smooth=True, bevel=0.0)

    # Cream & gold concentric oil-paper crown medallion on top
    cyl("CanopyCrown", 0.92, 0.14, 0.14, 16, m_cream, loc=(0, 0, -0.04), smooth=True, bevel=0.02)
    torus("CrownGoldRing", 0.92, 0.04, 24, 6, m_gold, loc=(0, 0, -0.08))
    torus("OuterGoldBand", 2.05, 0.035, 32, 6, m_gold, loc=(0, 0, -0.43))

    # Brass lotus-bud finial on top
    cyl("FinialBase", 0.18, 0.12, 0.10, 12, m_gold, loc=(0, 0, 0.04), bevel=0.015)
    cyl("FinialSpire", 0.11, 0.02, 0.24, 12, m_gold, loc=(0, 0, 0.19), bevel=0.01)

    # 16 Delicate bamboo radial ribs + stretcher struts + bamboo handle + hanging tassel bob
    cyl("Handle", 0.075, 0.075, 2.35, 10, m_bamboo, loc=(0, 0, -1.35), bevel=0.01)
    cyl("RunnerHub", 0.16, 0.16, 0.18, 12, m_gold, loc=(0, 0, -0.82), bevel=0.02)
    for i in range(rib_n):
        a = i * math.tau / rib_n
        ca, sa = math.cos(a), math.sin(a)
        rib_pts = [Vector((0.08 * ca, 0.08 * sa, -0.08)), Vector((1.25 * ca, 1.25 * sa, -0.26)), Vector((2.38 * ca, 2.38 * sa, -0.64))]
        sweep_tube(f"BambooRib{i}", rib_pts, [0.022, 0.020, 0.016], m_bamboo, segs=5)
        strut_pts = [Vector((0.14 * ca, 0.14 * sa, -0.82)), Vector((1.15 * ca, 1.15 * sa, -0.28))]
        sweep_tube(f"BambooStrut{i}", strut_pts, [0.016, 0.014], m_bamboo, segs=5)
        # Tiny gold rib tips around scalloped rim
        cyl(f"RibTip{i}", 0.035, 0.015, 0.09, 6, m_gold, loc=(2.42 * ca, 2.42 * sa, -0.65), rot=(0, math.radians(108), a), bevel=0.005)
    cyl("LanternBob", 0.24, 0.18, 0.36, 12, m_cream, loc=(0, 0, -2.55), bevel=0.02)
    cyl("BobCap", 0.20, 0.10, 0.08, 10, m_gold, loc=(0, 0, -2.35), bevel=0.01)
    save(OUT_W3, "silk_parasol.glb")

    # 3. Floating Pagoda Teahouse Roof Platform (5.4m x 5.4m walkable center deck at Z=0!)
    clear()
    # 'CeramicRoof' in name triggers terracotta_tile glazed ceramic roof finish in world_helper.gd!
    m_tile = mat("PagodaCeramicRoofTeal", (0.12, 0.42, 0.48), rough=0.34, coat=0.50)
    m_red = mat("PagodaLacquer", (0.76, 0.18, 0.16), rough=0.28, coat=0.55)
    m_gold = mat("PagodaGold", (0.94, 0.76, 0.30), rough=0.22, metal=0.90)
    m_lantern = mat("PagodaGlow", (1.0, 0.80, 0.34), rough=0.2, em=(1.0, 0.70, 0.22), em_s=3.4)

    # Walkable flat center deck at Z=0
    box("RoofDeck", (4.8, 4.8, 0.42), m_tile, loc=(0, 0, -0.21), bevel=0.05)
    box("GoldDeckBorder", (4.96, 4.96, 0.12), m_gold, loc=(0, 0, -0.07), bevel=0.02)
    box("LacquerFrame", (4.3, 4.3, 0.88), m_red, loc=(0, 0, -0.86), bevel=0.05)

    # Sweeping curved upturned ceramic-tiled roof eaves surrounding the walkable deck!
    for side_idx in range(4):
        ang_z = side_idx * math.pi * 0.5
        ca, sa = math.cos(ang_z), math.sin(ang_z)
        # Curved eave skirt sweeping outward & gently turning upward at the rim
        bm_eave = bmesh.new()
        nx_s, ny_s = 6, 4
        grid = []
        for yi in range(ny_s):
            v = yi / (ny_s - 1)  # 0 inner -> 1 outer upturned tip
            y_loc = 2.25 + v * 1.15
            z_loc = -0.18 - 0.18 * v + 0.34 * (v ** 2.4)
            row = []
            for xi in range(nx_s):
                u = (xi / (nx_s - 1)) * 2.0 - 1.0  # -1..1 along edge
                x_loc = u * (2.35 + v * 1.15)
                # Corners swoop higher!
                corner_lift = (u * u) * (v ** 1.6) * 0.46
                p = Vector((x_loc * ca - y_loc * sa, x_loc * sa + y_loc * ca, z_loc + corner_lift))
                row.append(bm_eave.verts.new(p))
            grid.append(row)
        for yi in range(ny_s - 1):
            for xi in range(nx_s - 1):
                bm_eave.faces.new((grid[yi][xi], grid[yi][xi + 1], grid[yi + 1][xi + 1], grid[yi + 1][xi]))
        bmesh.ops.solidify(bm_eave, geom=bm_eave.faces[:], thickness=0.14)
        add_bm(f"CurvedEave_{side_idx}", bm_eave, m_tile, smooth=True, bevel=0.015)

        # Exposed crimson lacquered rafters underneath each eave
        for r_i in range(-2, 3):
            rx = r_i * 0.92
            p0 = Vector((rx * ca - 2.1 * sa, rx * sa + 2.1 * ca, -0.32))
            p1 = Vector((rx * 1.25 * ca - 3.25 * sa, rx * 1.25 * sa + 3.25 * ca, -0.22 + (r_i * r_i) * 0.04))
            sweep_tube(f"Rafter_{side_idx}_{r_i}", [p0, p1], [0.09, 0.07], m_red, segs=4)

    # Ornate curved corner finials + delicate hanging corner chime tassels!
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            fin_pts = [
                Vector((sx * 2.95, sy * 2.95, 0.25)),
                Vector((sx * 3.45, sy * 3.45, 0.56)),
                Vector((sx * 3.68, sy * 3.68, 0.96)),
                Vector((sx * 3.55, sy * 3.55, 1.22)),
            ]
            sweep_tube(f"CornerFinial_{sx}_{sy}", fin_pts, [0.16, 0.12, 0.08, 0.03], m_gold, segs=6)
            # Hanging brass chime bell + glowing paper lantern + crimson tassel beneath corner
            cx, cy = sx * 3.25, sy * 3.25
            cyl(f"ChimeCord_{sx}_{sy}", 0.025, 0.025, 0.65, 6, m_gold, loc=(cx, cy, -0.10), bevel=0.0)
            cyl(f"ChimeBell_{sx}_{sy}", 0.24, 0.12, 0.26, 10, m_gold, loc=(cx, cy, -0.45), bevel=0.02)
            cyl(f"CornerLantern_{sx}_{sy}", 0.22, 0.18, 0.48, 10, m_lantern, loc=(cx, cy, -0.84), bevel=0.02)
            cyl(f"ChimeTassel_{sx}_{sy}", 0.05, 0.12, 0.45, 8, m_red, loc=(cx, cy, -1.30), bevel=0.01)
    save(OUT_W3, "pagoda_eave.glb")

    # 4. Crisp Origami Folding Bridge Tile (3.5m x 3.5m x 0.28m, top at Z=0)
    clear()
    m_paper = mat("FoldPaper", (0.97, 0.94, 0.86), rough=0.48)
    m_gold = mat("FoldGold", (0.95, 0.75, 0.28), rough=0.22, metal=0.86)

    box("PaperBase", (3.44, 3.44, 0.26), m_paper, loc=(0, 0, -0.13), bevel=0.03)
    # Crisp gold-foil outer edge trim + intersecting diagonal & diamond origami fold ribs
    for sx in (-1.68, 1.68):
        box(f"EdgeGoldX{sx}", (0.10, 3.50, 0.29), m_gold, loc=(sx, 0, -0.13), bevel=0.015)
    for sy in (-1.68, 1.68):
        box(f"EdgeGoldY{sy}", (3.50, 0.10, 0.29), m_gold, loc=(0, sy, -0.13), bevel=0.015)
    box("GoldFoldA", (4.65, 0.11, 0.28), m_gold, loc=(0, 0, -0.13), rot=(0, 0, math.radians(45)), bevel=0.015)
    box("GoldFoldB", (4.65, 0.11, 0.28), m_gold, loc=(0, 0, -0.13), rot=(0, 0, math.radians(-45)), bevel=0.015)
    box("CenterDiamond", (1.45, 1.45, 0.29), m_gold, loc=(0, 0, -0.135), rot=(0, 0, math.radians(45)), bevel=0.02)
    box("CenterInnerPaper", (1.22, 1.22, 0.30), m_paper, loc=(0, 0, -0.14), rot=(0, 0, math.radians(45)), bevel=0.015)
    save(OUT_W3, "folded_tile.glb")

    # 5. Floating Festival Paper Lantern Landmark
    clear()
    m_glow = mat("FestGlow", (1.0, 0.78, 0.32), rough=0.25, em=(1.0, 0.68, 0.22), em_s=3.4)
    m_frame = mat("FestWood", (0.28, 0.14, 0.12), rough=0.48)
    m_gold = mat("FestGold", (0.94, 0.74, 0.28), rough=0.25, metal=0.85)

    cyl("Body", 0.95, 0.85, 2.2, 12, m_glow, loc=(0, 0, 0), bevel=0.05)
    cyl("CapTop", 1.15, 0.60, 0.36, 12, m_frame, loc=(0, 0, 1.24), bevel=0.03)
    cyl("CapBot", 0.60, 1.05, 0.32, 12, m_frame, loc=(0, 0, -1.22), bevel=0.03)
    cyl("Tassel", 0.12, 0.26, 0.95, 10, m_gold, loc=(0, 0, -1.85), bevel=0.02)
    save(OUT_W3, "paper_lantern.glb")


# ==============================================================================
# WORLD 4 - THE SHATTERED MIRROR GALLERY
# ==============================================================================
def gen_w4():
    # 1. Ornate Baroque Gilded Picture-Frame Portal (aperture 3.6m wide x 4.6m tall, base at Z=0!)
    clear()
    m_gold = mat("FrameGold", (0.96, 0.78, 0.30), rough=0.22, metal=0.90)
    m_rose = mat("FrameRose", (0.90, 0.56, 0.66), rough=0.28, metal=0.72)
    m_gem = mat("FrameGemAmeth", (0.78, 0.45, 1.0), rough=0.08, em=(0.72, 0.38, 1.0), em_s=1.2)

    box("BarBot", (4.7, 0.62, 0.52), m_gold, loc=(0, 0, -0.20), bevel=0.06)
    box("BarTop", (4.9, 0.68, 0.58), m_gold, loc=(0, 0, 4.85), bevel=0.06)
    box("BarL", (0.56, 0.62, 5.1), m_gold, loc=(-2.08, 0, 2.32), bevel=0.06)
    box("BarR", (0.56, 0.62, 5.1), m_gold, loc=(2.08, 0, 2.32), bevel=0.06)
    for sx in (-2.15, 2.15):
        for sz in (-0.15, 4.88):
            cyl(f"Corner_{sx}_{sz}", 0.48, 0.48, 0.78, 12, m_rose,
                loc=(sx, 0, sz), rot=(math.radians(90), 0, 0), bevel=0.04)
    cyl("Crest", 0.85, 0.20, 0.85, 8, m_gold, loc=(0, 0, 5.55), bevel=0.04)
    cyl("Gem", 0.32, 0.02, 0.55, 8, m_gem, loc=(0, 0, 5.85), bevel=0.02)
    save(OUT_W4, "gilded_portal_frame.glb")

    # 2. Molded Veined-Marble & Gilded-Brass Baroque Balcony with Delicate Balustrade Trims (4.6m x 4.6m, top at Z=0!)
    clear()
    m_marble = mat("EscherMarble", (0.94, 0.91, 0.96), rough=0.26, coat=0.50)
    m_lilac = mat("EscherLilac", (0.58, 0.42, 0.76), rough=0.38)
    m_gold = mat("EscherGold", (0.94, 0.75, 0.34), rough=0.20, metal=0.90)

    box("Deck", (4.58, 4.58, 0.42), m_marble, loc=(0, 0, -0.21), bevel=0.06)
    box("LowerCornice", (4.30, 4.30, 0.22), m_lilac, loc=(0, 0, -0.48), bevel=0.04)
    box("GoldTrim", (4.72, 4.72, 0.12), m_gold, loc=(0, 0, -0.09), bevel=0.03)
    # Inlaid brass mosaic floor diamond
    box("FloorInlayGold", (2.6, 2.6, 0.03), m_gold, loc=(0, 0, -0.01), rot=(0, 0, math.radians(45)), bevel=0.01)
    box("FloorInlayMarble", (2.25, 2.25, 0.035), m_marble, loc=(0, 0, -0.008), rot=(0, 0, math.radians(45)), bevel=0.01)

    # Delicate Baroque balustrade trims along ±X sides (leaving front/back Y open for smooth traversal!)
    for sx in (-2.16, 2.16):
        box(f"TopRail_{sx}", (0.16, 4.10, 0.10), m_gold, loc=(sx, 0, 0.62), bevel=0.02)
        box(f"BotPlinthRail_{sx}", (0.20, 4.10, 0.12), m_marble, loc=(sx, 0, 0.05), bevel=0.02)
        for sy in (-1.95, 1.95):
            box(f"NewelPost_{sx}_{sy}", (0.26, 0.26, 0.74), m_marble, loc=(sx, sy, 0.36), bevel=0.03)
            cyl(f"NewelUrn_{sx}_{sy}", 0.12, 0.04, 0.22, 10, m_gold, loc=(sx, sy, 0.84), bevel=0.01)
        for by in (-1.3, -0.65, 0.0, 0.65, 1.3):
            cyl(f"Baluster_{sx}_{by}", 0.075, 0.055, 0.48, 10, m_marble, loc=(sx, by, 0.35), bevel=0.015)
            torus(f"BalusterRing_{sx}_{by}", 0.078, 0.022, 12, 6, m_gold, loc=(sx, by, 0.35))

    # Inverted Escher staircase sculptural relief hanging beneath
    for step in range(4):
        w = 3.6 - step * 0.72
        box(f"InvStep{step}", (w, w, 0.48), m_lilac if step % 2 else m_marble,
            loc=(0, 0, -0.78 - step * 0.48), bevel=0.04)
    save(OUT_W4, "marble_stair_arch.glb")

    # 3. Faceted Floating Rainbow Crystal Prism Landmark / Plinth
    clear()
    m_crystal = mat("PrismCrystalOpal", (0.86, 0.76, 1.0), rough=0.08, em=(0.68, 0.48, 0.98), em_s=1.0, coat=0.9)
    m_gold = mat("PrismGold", (0.95, 0.78, 0.34), rough=0.20, metal=0.90)

    cyl("TopHalf", 1.85, 0.15, 2.8, 6, m_crystal, loc=(0, 0, 1.4), bevel=0.04)
    cyl("BotHalf", 0.15, 1.85, 2.8, 6, m_crystal, loc=(0, 0, -1.4), bevel=0.04)
    cyl("Belt", 2.02, 2.02, 0.24, 6, m_gold, loc=(0, 0, 0), bevel=0.03)
    save(OUT_W4, "crystal_prism.glb")

    # 4. Ornate Carved-Gold Beveled Mirror Wall Panel (9.0m X x 4.4m Z x ~0.65m Y)
    clear()
    m_gold = mat("MirGold", (0.95, 0.78, 0.34), rough=0.20, metal=0.92)
    m_rose = mat("MirRose", (0.88, 0.54, 0.66), rough=0.26, metal=0.76)
    m_glass = mat("MirGlass", (0.78, 0.88, 1.0), rough=0.05, metal=0.60, em=(0.55, 0.72, 1.0), em_s=0.35, coat=0.98)
    m_chev = mat("MirChevRose", (1.0, 0.52, 0.86), rough=0.10, em=(1.0, 0.45, 0.82), em_s=1.15)

    box("MirrorGlass", (8.6, 0.42, 3.88), m_glass, loc=(0, 0, 0), bevel=0.03)
    # Double-stepped Baroque carved gold frame moldings
    box("FrameTopOuter", (9.2, 0.74, 0.38), m_gold, loc=(0, 0, 2.12), bevel=0.05)
    box("FrameTopInner", (8.8, 0.60, 0.18), m_rose, loc=(0, 0, 1.92), bevel=0.03)
    box("FrameBotOuter", (9.2, 0.74, 0.38), m_gold, loc=(0, 0, -2.12), bevel=0.05)
    box("FrameBotInner", (8.8, 0.60, 0.18), m_rose, loc=(0, 0, -1.92), bevel=0.03)
    for sx in (-4.42, 4.42):
        box(f"FrameSide_{sx}", (0.44, 0.74, 4.48), m_gold, loc=(sx, 0, 0), bevel=0.05)
    # Triptych vertical mullions + Baroque corner cartouche medallions
    for mx in (-1.55, 1.55):
        box(f"TriptychMullion_{mx}", (0.18, 0.56, 3.92), m_gold, loc=(mx, 0, 0), bevel=0.025)
    for sx in (-4.38, 4.38):
        for sz in (-2.05, 2.05):
            cyl(f"Cartouche_{sx}_{sz}", 0.38, 0.38, 0.82, 10, m_rose, loc=(sx, 0, sz), rot=(math.radians(90), 0, 0), bevel=0.03)
    for i in range(-3, 4):
        box(f"ChevA{i}", (0.28, 0.52, 1.18), m_chev, loc=(i * 1.15, 0, 0), rot=(0, math.radians(22), 0), bevel=0.02)
    save(OUT_W4, "mirror_wall_panel.glb")

    # 5. Faceted Translucent Astro-Bot Crystal-Ice Hex/Beveled Prism Walkway Slab (top at Z=0, 3.45m x 3.45m)
    clear()
    # 'Sapph' in name triggers luminous __jewel_glass_v2__ sapphire-ice glass in world_helper.gd!
    m_crystal = mat("ShatterSapphGlass", (0.68, 0.88, 1.0), rough=0.06, em=(0.40, 0.78, 1.0), em_s=0.75, coat=0.95)
    m_ice_core = mat("ShatterGlassCore", (0.86, 0.95, 1.0), rough=0.08, em=(0.62, 0.86, 1.0), em_s=0.35, coat=0.9)
    m_gold = mat("ShatterIcyGold", (0.94, 0.80, 0.42), rough=0.20, metal=0.90)

    # Octagonal/hexagonal-chamfered beveled crystal prism slab fitting cleanly inside 3.45m x 3.45m!
    cyl("CrystalPrismTop", 1.78, 1.88, 0.16, 8, m_crystal, loc=(0, 0, -0.08), rot=(0, 0, math.radians(22.5)), bevel=0.035)
    cyl("CrystalPrismKeel", 0.82, 1.70, 0.34, 8, m_ice_core, loc=(0, 0, -0.32), rot=(0, 0, math.radians(22.5)), bevel=0.03)
    # Faceted inner star crystal facets on top surface (flush with Z=0)
    cyl("CenterFacetStar", 0.92, 0.96, 0.04, 6, m_ice_core, loc=(0, 0, -0.015), bevel=0.015)
    # Beveled icy-gold octagonal frame trim & corner prism clasps
    torus("IcyGoldRim", 1.84, 0.075, 8, 8, m_gold, loc=(0, 0, -0.10), rot=(0, 0, math.radians(22.5)))
    for i in range(8):
        a = i * math.tau / 8.0 + math.radians(22.5)
        box(f"PrismClasp_{i}", (0.18, 0.24, 0.22), m_gold,
            loc=(1.82 * math.cos(a), 1.82 * math.sin(a), -0.10), rot=(0, 0, a), bevel=0.02)
    save(OUT_W4, "shatter_pane.glb")


if __name__ == "__main__":
    gen_w3()
    gen_w4()
    print("[world_kits_3_4] Worlds 3 & 4 AAA kits complete!")
