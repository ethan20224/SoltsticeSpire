"""
Blender 5.2.1 LTS Asset Kit Generator - Worlds 1 & 2 (AAA Sculpted Polish)
  World 1 (The Sunken Conservatory): terracotta_plinth, aqueduct_arch, lily_pad_cap, glass_dome_rib, mossy_flagstone
  World 2 (Foundry of Floating Bells): brass_gear, curved_bell, pendulum_blade, steam_vent, foundry_catwalk

Every walkable platform has its clean walkable top deck at Z=0 (Godot Y=0) and preserves outer collision dimensions!
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


def add_bm(name, bm, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.03, subsurf=0):
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


def box(name, sz, m, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.04):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=sz, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=False, bevel=bevel)


def cyl(name, r1, r2, h, segs, m, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False, bevel=0.03):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=smooth, bevel=bevel)


def sphere(name, rad, m, loc=(0, 0, 0), rot=(0, 0, 0), u=12, v=8, subsurf=0):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=rad, verts=bm.verts)
    return add_bm(name, bm, m, loc=loc, rot=rot, smooth=True, bevel=0.0, subsurf=subsurf)


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
    print(f"[world_kits_1_2] Exported {p}")


# ==============================================================================
# WORLD 1 - THE SUNKEN CONSERVATORY
# ==============================================================================
def gen_w1():
    # 1. Terracotta Plinth Island (16-sided carved limestone & Tuscan terracotta terrace, top at Z=0, radius ~2.6m)
    clear()
    m_stone = mat("W1Stone", (0.68, 0.61, 0.49), rough=0.62)
    m_terra = mat("W1Terracotta", (0.55, 0.20, 0.10), rough=0.56)
    m_moss = mat("W1Moss", (0.14, 0.44, 0.18), rough=0.86)
    m_gold = mat("W1Brass", (0.80, 0.56, 0.16), rough=0.26, metal=0.88)
    m_vine = mat("W1VineLeaf", (0.18, 0.48, 0.18), rough=0.86)

    # 16-sided beveled limestone coping & lower cornice lip
    cyl("TopCoping", 2.58, 2.66, 0.24, 16, m_stone, loc=(0, 0, -0.12), smooth=False, bevel=0.04)
    cyl("CopingSub", 2.44, 2.54, 0.16, 16, m_stone, loc=(0, 0, -0.32), smooth=False, bevel=0.03)
    # Recessed mossy garden center deck (sits +0.008m cleanly above TopCoping to eliminate grazing-angle Z-fighting!)
    cyl("MossDeck", 2.18, 2.20, 0.06, 16, m_moss, loc=(0, 0, -0.022), smooth=False, bevel=0.012)
    # Inlaid brass-mosaic border ring + 16 brass mosaic keystone tiles
    torus("GoldInlayOuter", 2.34, 0.042, 32, 8, m_gold, loc=(0, 0, -0.018))
    torus("GoldInlayInner", 2.18, 0.032, 32, 8, m_gold, loc=(0, 0, -0.015))
    for i in range(16):
        a = i * math.tau / 16.0
        box(f"MosaicTile{i}", (0.14, 0.18, 0.035), m_gold,
            loc=(2.26 * math.cos(a), 2.26 * math.sin(a), -0.014), rot=(0, 0, a), bevel=0.008)

    # Tuscan terracotta drum core + recessed relief frieze ring
    cyl("TerraCore", 1.98, 2.38, 0.78, 16, m_terra, loc=(0, 0, -0.78), smooth=False, bevel=0.04)
    torus("TerraBelt", 2.26, 0.065, 32, 8, m_terra, loc=(0, 0, -0.52))

    # 8 sculpted arched stone corbel brackets under the coping
    for k in range(8):
        a = k * math.pi * 0.25
        ca, sa = math.cos(a), math.sin(a)
        corbel_pts = [
            Vector((1.88 * ca, 1.88 * sa, -1.12)),
            Vector((2.18 * ca, 2.18 * sa, -0.86)),
            Vector((2.36 * ca, 2.36 * sa, -0.56)),
            Vector((2.46 * ca, 2.46 * sa, -0.34)),
        ]
        sweep_tube(f"ArchCorbel{k}", corbel_pts, [0.14, 0.18, 0.21, 0.23], m_stone, segs=6, cap=True)

    # Organic layered rocky mossy underside crags
    bm_rock = bmesh.new()
    bmesh.ops.create_icosphere(bm_rock, subdivisions=2, radius=1.0)
    for v in bm_rock.verts:
        p = v.co
        # Flatten top to tuck cleanly inside terracotta drum, taper downward into sculpted rocky crags
        ang = math.atan2(p.y, p.x)
        crag = 1.0 + 0.20 * math.sin(ang * 5.0 + p.z * 3.0) + 0.12 * math.cos(ang * 3.0 - p.z * 4.0)
        z_norm = (p.z + 1.0) * 0.5  # 0 at bottom, 1 at top
        rad_z = 0.25 + 0.75 * (z_norm ** 0.72)
        v.co.x = p.x * 1.95 * rad_z * crag
        v.co.y = p.y * 1.95 * rad_z * crag
        v.co.z = -1.05 - (1.0 - z_norm) * 1.65
    add_bm("RockyUnderside", bm_rock, m_stone, smooth=False, bevel=0.03)

    # Mossy overhang tufts & subtle hanging vine tendrils around rim
    for k in range(8):
        a = k * math.pi * 0.25 + 0.22
        ca, sa = math.cos(a), math.sin(a)
        sphere(f"MossOverhang{k}", (0.34, 0.28, 0.14), m_moss,
               loc=(2.38 * ca, 2.38 * sa, -0.22), rot=(0, 0, a), u=10, v=6)
        if k % 2 == 0:
            vlen = 0.85 + (k % 3) * 0.28
            v_pts = [
                Vector((2.48 * ca, 2.48 * sa, -0.24)),
                Vector((2.54 * ca + 0.08 * sa, 2.54 * sa - 0.08 * ca, -0.24 - vlen * 0.45)),
                Vector((2.42 * ca - 0.06 * sa, 2.42 * sa + 0.06 * ca, -0.24 - vlen)),
            ]
            sweep_tube(f"VineTendril{k}", v_pts, [0.040, 0.028, 0.012], m_vine, segs=6)
            for li in range(3):
                lt = (li + 1) / 3.5
                lp = v_pts[0].lerp(v_pts[2], lt)
                sphere(f"VineLeaf_{k}_{li}", (0.11, 0.06, 0.03), m_vine,
                       loc=(lp.x, lp.y, lp.z), rot=(0.2, 0.3, a + li * 0.7), u=8, v=6)
    save(OUT_W1, "terracotta_plinth.glb")

    # 2. Aqueduct Bridge Arch (walkable deck 6.5m along Y, 3.4m wide X, top at Z=0)
    clear()
    m_stone = mat("W1ArchStone", (0.66, 0.59, 0.47), rough=0.62)
    m_terra = mat("W1ArchTerra", (0.52, 0.19, 0.10), rough=0.55)
    m_moss = mat("W1ArchMoss", (0.12, 0.42, 0.17), rough=0.84)
    m_gold = mat("W1ArchBrass", (0.78, 0.54, 0.14), rough=0.26, metal=0.86)

    box("Deck", (3.4, 6.6, 0.42), m_stone, loc=(0, 0, -0.21), bevel=0.05)
    box("CenterRunner", (1.6, 6.5, 0.05), m_terra, loc=(0, 0, -0.01), bevel=0.02)
    for sx in (-1.55, 1.55):
        box(f"Curb{sx}", (0.28, 6.5, 0.32), m_terra, loc=(sx, 0, 0.14), bevel=0.03)
        for py in (-2.9, 0.0, 2.9):
            box(f"Post_{sx}_{py}", (0.38, 0.38, 0.56), m_stone, loc=(sx, py, 0.28), bevel=0.03)
            cyl(f"Finial_{sx}_{py}", 0.14, 0.04, 0.18, 10, m_gold, loc=(sx, py, 0.64), bevel=0.01)
    for sy in (-2.5, 2.5):
        box(f"Pier{sy}", (2.9, 1.1, 2.4), m_stone, loc=(0, sy, -1.6), bevel=0.05)
    for k in range(7):
        ang = math.pi * (k + 0.5) / 7.0
        y = 2.0 * math.cos(ang)
        z = -2.2 + 1.5 * math.sin(ang)
        box(f"Voussoir{k}", (3.1, 0.65, 0.48), m_terra, loc=(0, y, z), rot=(ang - math.pi * 0.5, 0, 0), bevel=0.03)
    box("MossPatch", (2.8, 1.8, 0.08), m_moss, loc=(0.2, 1.2, -0.01), bevel=0.02)
    save(OUT_W1, "aqueduct_arch.glb")

    # 3. Giant Blooming Sun-Flower Bounce Pad (Astro-Bot inspired, radius ~2.3m, top cushion at Z=0!)
    clear()
    m_leaf = mat("LilyLeaf", (0.16, 0.56, 0.24), rough=0.68)
    m_calyx = mat("LilyCalyx", (0.12, 0.44, 0.18), rough=0.72)
    m_petal_gold = mat("LilyPetalGold", (0.98, 0.72, 0.24), rough=0.38, coat=0.25)
    m_petal_cream = mat("LilyPetalCream", (1.0, 0.89, 0.70), rough=0.36, coat=0.25)
    m_pollen = mat("LilyPollen", (1.0, 0.78, 0.20), rough=0.20, em=(1.0, 0.72, 0.18), em_s=1.85)

    # Tufted glowing amber-gold pollen dome (top at Z=0!)
    bm_dome = bmesh.new()
    bmesh.ops.create_uvsphere(bm_dome, u_segments=20, v_segments=10, radius=1.0)
    for v in bm_dome.verts:
        if v.co.z < 0.0:
            v.co.z *= 0.35
        v.co.x *= 0.94
        v.co.y *= 0.94
        v.co.z *= 0.28
    add_bm("PollenDome", bm_dome, m_pollen, loc=(0, 0, -0.22), smooth=True, bevel=0.0)
    # Tufted golden pollen bumps around dome crown
    for ring_r, count, z_h in [(0.42, 6, -0.04), (0.72, 10, -0.08)]:
        for i in range(count):
            a = i * math.tau / count + (0.2 if count == 10 else 0.0)
            sphere(f"PollenTuft_{count}_{i}", (0.13, 0.13, 0.075), m_pollen,
                   loc=(ring_r * math.cos(a), ring_r * math.sin(a), z_h), u=8, v=6)

    # 16 Plump Layered Curved Petals in two staggered rings (8 outer golden-apricot + 8 inner warm-cream)
    def add_sculpted_petal(name, angle, length, width, z_base, lift, pitch, m_p):
        bm_p = bmesh.new()
        u_n, v_n = 7, 5
        grid = []
        for ui in range(u_n):
            u = ui / (u_n - 1)  # 0 inner root -> 1 outer tip
            r_dist = 0.72 + u * length
            # Plump curved spoon profile
            w_local = width * math.sin(u * math.pi * 0.88 + 0.12)
            z_arch = z_base + math.sin(u * math.pi) * lift - (u * u) * pitch
            row = []
            for vi in range(v_n):
                v = (vi / (v_n - 1)) * 2.0 - 1.0  # -1..1 across petal width
                cup = (1.0 - v * v) * -0.055 * math.sin(u * math.pi)
                row.append(bm_p.verts.new((r_dist, v * w_local, z_arch + cup)))
            grid.append(row)
        for ui in range(u_n - 1):
            for vi in range(v_n - 1):
                bm_p.faces.new((grid[ui][vi], grid[ui + 1][vi], grid[ui + 1][vi + 1], grid[ui][vi + 1]))
        bmesh.ops.solidify(bm_p, geom=bm_p.faces[:], thickness=0.11)
        add_bm(name, bm_p, m_p, rot=(0, 0, angle), smooth=True, bevel=0.015, subsurf=0)

    for i in range(8):
        a_out = i * math.tau / 8.0
        add_sculpted_petal(f"OuterPetal{i}", a_out, length=1.62, width=0.52, z_base=-0.10, lift=0.06, pitch=0.18, m_p=m_petal_gold)
        a_in = a_out + math.tau / 16.0
        add_sculpted_petal(f"InnerPetal{i}", a_in, length=1.36, width=0.46, z_base=-0.03, lift=0.08, pitch=0.10, m_p=m_petal_cream)

    # 8 Lush Scalloped Emerald Calyx Leaves cradling beneath the blossom
    for i in range(8):
        a_cal = i * math.tau / 8.0 + math.tau / 16.0
        add_sculpted_petal(f"CalyxLeaf{i}", a_cal, length=1.55, width=0.44, z_base=-0.26, lift=0.04, pitch=0.36, m_p=m_calyx)
    cyl("ReceptacleCup", 0.56, 1.15, 0.36, 16, m_leaf, loc=(0, 0, -0.34), smooth=True, bevel=0.04)

    # Curved botanical vine stem beneath with tiny leaf buds
    stem_pts = [
        Vector((0.0, 0.0, -0.45)),
        Vector((0.18, -0.10, -0.88)),
        Vector((0.08, 0.14, -1.35)),
        Vector((-0.22, 0.20, -1.78)),
    ]
    sweep_tube("BotanicalStem", stem_pts, [0.34, 0.24, 0.18, 0.12], m_leaf, segs=10)
    sphere("StemBudA", (0.28, 0.16, 0.08), m_calyx, loc=(0.30, -0.14, -0.92), rot=(0.2, -0.4, 0.5), u=10, v=6)
    sphere("StemBudB", (0.24, 0.14, 0.07), m_calyx, loc=(-0.08, 0.28, -1.35), rot=(-0.2, 0.3, 1.8), u=10, v=6)
    save(OUT_W1, "lily_pad_cap.glb")

    # 4. Monumental Smooth 24-Segment Wrought-Iron & Hammered-Brass Conservatory Cathedral Rib
    clear()
    m_iron = mat("GlassIron", (0.11, 0.20, 0.19), rough=0.34, metal=0.82)
    m_brass = mat("GlassBrass", (0.80, 0.56, 0.18), rough=0.24, metal=0.90)
    m_glass = mat("StainedGlass", (0.20, 0.68, 0.64), rough=0.08, em=(0.14, 0.52, 0.50), em_s=0.35, coat=0.90)

    segs = 24
    for sy in (-1.35, 1.35):
        bm_rib = bmesh.new()
        rings = []
        for i in range(segs + 1):
            t = math.pi * i / segs
            cx, cz = 10.0 * math.cos(t), 13.0 * math.sin(t)
            tx, tz = -10.0 * math.sin(t), 13.0 * math.cos(t)
            tl = math.hypot(tx, tz)
            nx, nz = tz / tl, -tx / tl
            hr, hy = 0.32, 0.24
            rings.append([
                bm_rib.verts.new((cx - nx * hr, sy - hy, cz - nz * hr)),
                bm_rib.verts.new((cx + nx * hr, sy - hy, cz + nz * hr)),
                bm_rib.verts.new((cx + nx * hr, sy + hy, cz + nz * hr)),
                bm_rib.verts.new((cx - nx * hr, sy + hy, cz - nz * hr)),
            ])
        for i in range(segs):
            for s in range(4):
                sn = (s + 1) % 4
                bm_rib.faces.new((rings[i][s], rings[i][sn], rings[i + 1][sn], rings[i + 1][s]))
        bm_rib.faces.new(rings[0][::-1])
        bm_rib.faces.new(rings[-1])
        add_bm(f"SweptRib_{sy}", bm_rib, m_iron, smooth=True, bevel=0.03)

        # Inner hammered-brass arch flange molding running parallel inside each iron rib
        flange_pts = [Vector((9.52 * math.cos(math.pi * i / segs), sy * 0.92, 12.52 * math.sin(math.pi * i / segs))) for i in range(segs + 1)]
        sweep_tube(f"BrassInnerFlange_{sy}", flange_pts, [0.11] * len(flange_pts), m_brass, segs=6)

    # Continuous curved stained-glass vaulted ribbons (with open sunlit oculus apex!)
    for span_start, span_end, tag in [(1, 9, "L"), (15, 23, "R")]:
        bm_g = bmesh.new()
        grings = []
        for i in range(span_start, span_end + 1):
            t = math.pi * i / segs
            cx, cz = 10.0 * math.cos(t), 13.0 * math.sin(t)
            tx, tz = -10.0 * math.sin(t), 13.0 * math.cos(t)
            tl = math.hypot(tx, tz)
            nx, nz = tz / tl, -tx / tl
            ht = 0.06
            grings.append([
                bm_g.verts.new((cx - nx * ht, -1.20, cz - nz * ht)),
                bm_g.verts.new((cx + nx * ht, -1.20, cz + nz * ht)),
                bm_g.verts.new((cx + nx * ht, 1.20, cz + nz * ht)),
                bm_g.verts.new((cx - nx * ht, 1.20, cz - nz * ht)),
            ])
        for i in range(len(grings) - 1):
            for s in range(4):
                sn = (s + 1) % 4
                bm_g.faces.new((grings[i][s], grings[i][sn], grings[i + 1][sn], grings[i + 1][s]))
        add_bm(f"GlassVault_{tag}", bm_g, m_glass, smooth=True, bevel=0.01)

        # Longitudinal brass window mullions dividing the stained glass into graceful conservatory panes
        for my in (-0.55, 0.0, 0.55):
            mull_pts = [Vector((10.0 * math.cos(math.pi * i / segs), my, 13.0 * math.sin(math.pi * i / segs))) for i in range(span_start, span_end + 1)]
            sweep_tube(f"LongMullion_{tag}_{my}", mull_pts, [0.065] * len(mull_pts), m_brass, segs=6)

    # Slender arched brass cross-mullions & decorative floral spandrel scrollwork (NO chunky yellow rectangles!)
    for i in range(1, segs, 2):
        t = math.pi * i / segs
        cx, cz = 10.0 * math.cos(t), 13.0 * math.sin(t)
        m_pts = [Vector((cx, -1.35, cz)), Vector((cx, 0.0, cz)), Vector((cx, 1.35, cz))]
        sweep_tube(f"CrossMullion_{i}", m_pts, [0.085, 0.095, 0.085], m_brass, segs=6)

    # Decorative floral spandrel scrollwork & iron rosettes near both arch springings + apex oculus ring
    for sx in (-1.0, 1.0):
        cyl(f"ArchFoot{sx}", 1.25, 0.92, 1.8, 12, m_iron, loc=(sx * 10.0, 0, -0.8), bevel=0.04)
        torus(f"FootBrassCollar{sx}", 0.98, 0.08, 16, 6, m_brass, loc=(sx * 10.0, 0, 0.08))
        for sy in (-1.35, 1.35):
            # Delicate S-scroll filigree & brass rosette rings in the lower spandrel
            scroll_pts = [
                Vector((sx * 9.5, sy, 0.5)),
                Vector((sx * 8.6, sy, 1.4)),
                Vector((sx * 8.3, sy, 2.3)),
                Vector((sx * 8.9, sy, 3.1)),
                Vector((sx * 9.3, sy, 2.5)),
            ]
            sweep_tube(f"SpandrelScroll_{sx}_{sy}", scroll_pts, [0.075, 0.065, 0.055, 0.050, 0.040], m_brass, segs=6)
            torus(f"FloralRosette_{sx}_{sy}", 0.42, 0.055, 16, 6, m_brass,
                  loc=(sx * 8.9, sy, 1.85), rot=(math.radians(90), 0, 0))
    # Apex oculus finial crest
    torus("ApexRosette", 0.55, 0.08, 20, 8, m_brass, loc=(0, 0, 13.3), rot=(math.radians(90), 0, 0))
    save(OUT_W1, "glass_dome_rib.glb")

    # 5. Mossy Crumbling Flagstone (3.4m x 3.4m x 0.45m, top at Z=0)
    clear()
    m_stone = mat("FlagStone", (0.84, 0.78, 0.66), rough=0.68)
    m_moss = mat("FlagMoss", (0.28, 0.62, 0.32), rough=0.86)
    m_rim = mat("FlagGold", (0.84, 0.62, 0.24), rough=0.32, metal=0.80)

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
    # 1. Giant Interlocking Clockwork Brass Gear (radius ~4.2m, walkable top at Z=0!)
    clear()
    m_brass = mat("GearBrass", (0.86, 0.62, 0.24), rough=0.26, metal=0.90)
    m_copper = mat("GearCopper", (0.72, 0.36, 0.22), rough=0.32, metal=0.84)
    m_iron = mat("GearIron", (0.22, 0.20, 0.25), rough=0.44, metal=0.78)
    m_core = mat("GearAmber", (1.0, 0.72, 0.22), rough=0.14, em=(1.0, 0.66, 0.18), em_s=2.2)

    cyl("GearDisc", 3.62, 3.62, 0.56, 32, m_brass, loc=(0, 0, -0.28), bevel=0.04)
    cyl("InnerPlate", 2.75, 2.75, 0.60, 24, m_iron, loc=(0, 0, -0.30), bevel=0.03)
    torus("RimRingOuter", 3.45, 0.15, 36, 10, m_copper, loc=(0, 0, -0.08))
    torus("HubBoltRing", 1.32, 0.11, 28, 8, m_brass, loc=(0, 0, -0.02))
    cyl("Hub", 0.98, 0.88, 0.72, 16, m_brass, loc=(0, 0, -0.32), bevel=0.04)
    cyl("HubGlow", 0.54, 0.54, 0.12, 16, m_core, loc=(0, 0, -0.02), bevel=0.02)
    # 16 crisp trapezoidal beveled gear teeth extending out to radius 4.42m
    for i in range(16):
        a = i * math.tau / 16.0
        bm_t = bmesh.new()
        # Tapered trapezoidal tooth in local X (radial) & Y (width)
        hx0, hx1 = -0.45, 0.45
        hy0, hy1 = 0.36, 0.24
        hz = 0.25
        v = [
            bm_t.verts.new((hx0, -hy0, -hz)), bm_t.verts.new((hx1, -hy1, -hz)),
            bm_t.verts.new((hx1, hy1, -hz)), bm_t.verts.new((hx0, hy0, -hz)),
            bm_t.verts.new((hx0, -hy0, hz)), bm_t.verts.new((hx1, -hy1, hz)),
            bm_t.verts.new((hx1, hy1, hz)), bm_t.verts.new((hx0, hy0, hz)),
        ]
        for f in [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]:
            bm_t.faces.new([v[idx] for idx in f])
        add_bm(f"Tooth{i}", bm_t, m_brass, loc=(3.92 * math.cos(a), 3.92 * math.sin(a), -0.27), rot=(0, 0, a), bevel=0.035)
    # 12 concentric hub bolts + 6 beveled radial copper spokes
    for i in range(12):
        a = i * math.tau / 12.0
        cyl(f"HubBolt{i}", 0.085, 0.075, 0.14, 6, m_copper, loc=(1.32 * math.cos(a), 1.32 * math.sin(a), 0.04), bevel=0.01)
    for i in range(6):
        a = i * math.pi / 3.0
        box(f"Spoke{i}", (2.5, 0.38, 0.64), m_copper,
            loc=(1.85 * math.cos(a), 1.85 * math.sin(a), -0.31), rot=(0, 0, a), bevel=0.03)
    save(OUT_W2, "brass_gear.glb")

    # 2. Sculpted Thick Curved Cast-Bronze Foundry Resonance Wall-Bell
    # Preserves ~8.8m width (X) x 4.4m height (Z) x ~1.0m depth (Y) for exact wall-run box alignment!
    clear()
    m_bronze = mat("BellBronze", (0.64, 0.42, 0.20), rough=0.32, metal=0.86)
    m_brass = mat("BellBrass", (0.88, 0.66, 0.24), rough=0.22, metal=0.92)
    m_iron = mat("BellIron", (0.18, 0.16, 0.20), rough=0.44, metal=0.80)
    # Material name contains 'furnace' + 'ember' so world_helper.gd gives rich molten-ember amber-orange!
    m_ember = mat("BellFurnaceEmber", (1.0, 0.48, 0.12), rough=0.14, em=(1.0, 0.46, 0.10), em_s=2.4)

    # Gently curved thick cast-bronze acoustic wall shell (8.6m wide, 4.1m tall, ~0.88m thick)
    bm_wall = bmesh.new()
    nx_segs = 16
    nz_segs = 6
    front_grid = []
    back_grid = []
    for zi in range(nz_segs + 1):
        vz = -2.0 + 4.0 * (zi / nz_segs)
        # Subtle bell flare toward bottom & slight inward waist near top
        flare = 0.44 + 0.08 * math.exp(-((vz + 1.8) * 1.4) ** 2)
        f_row, b_row = [], []
        for xi in range(nx_segs + 1):
            u = (xi / nx_segs) * 2.0 - 1.0  # -1..1
            vx = u * 4.30
            camber_y = 0.16 * (1.0 - u * u)  # gentle acoustic arc
            f_row.append(bm_wall.verts.new((vx, camber_y + flare, vz)))
            b_row.append(bm_wall.verts.new((vx, camber_y - flare, vz)))
        front_grid.append(f_row)
        back_grid.append(b_row)
    for zi in range(nz_segs):
        for xi in range(nx_segs):
            bm_wall.faces.new((front_grid[zi][xi], front_grid[zi][xi + 1], front_grid[zi + 1][xi + 1], front_grid[zi + 1][xi]))
            bm_wall.faces.new((back_grid[zi][xi + 1], back_grid[zi][xi], back_grid[zi + 1][xi], back_grid[zi + 1][xi + 1]))
    for xi in range(nx_segs):
        bm_wall.faces.new((back_grid[0][xi], back_grid[0][xi + 1], front_grid[0][xi + 1], front_grid[0][xi]))
        bm_wall.faces.new((front_grid[-1][xi], front_grid[-1][xi + 1], back_grid[-1][xi + 1], back_grid[-1][xi]))
    for zi in range(nz_segs):
        bm_wall.faces.new((back_grid[zi][0], front_grid[zi][0], front_grid[zi + 1][0], back_grid[zi + 1][0]))
        bm_wall.faces.new((front_grid[zi][-1], back_grid[zi][-1], back_grid[zi + 1][-1], front_grid[zi + 1][-1]))
    add_bm("CurvedBronzeWall", bm_wall, m_bronze, smooth=True, bevel=0.05)

    # Beveled riveted brass cornice top & bottom beams following the wall camber
    for z_beam, beam_h in [(2.12, 0.36), (-2.12, 0.42)]:
        for bi in range(8):
            u = ((bi + 0.5) / 8.0) * 2.0 - 1.0
            bx = u * 4.35
            by = 0.16 * (1.0 - u * u)
            ang_z = math.atan(-0.32 * u / 4.35)
            box(f"Cornice_{z_beam}_{bi}", (1.16, 1.18, beam_h), m_brass, loc=(bx, by, z_beam), rot=(0, 0, ang_z), bevel=0.04)
            for sy in (-0.58, 0.58):
                cyl(f"CorniceRivet_{z_beam}_{bi}_{sy}", 0.065, 0.055, 0.08, 8, m_iron,
                    loc=(bx, by + sy, z_beam), rot=(math.radians(90), 0, 0), bevel=0.01)

    # Recessed glowing molten-ember furnace louvers & ornamental cast relief panels on BOTH sides
    for px in (-2.45, 0.0, 2.45):
        u_p = px / 4.30
        cy_p = 0.16 * (1.0 - u_p * u_p)
        ang_p = math.atan(-0.32 * u_p / 4.30)
        for side_y in (-1.0, 1.0):
            fy = cy_p + side_y * 0.46
            # Ornamental cast brass relief frame
            box(f"ReliefFrame_{px}_{side_y}", (1.72, 0.14, 2.35), m_iron, loc=(px, fy, 0.0), rot=(0, 0, ang_p), bevel=0.025)
            # Glowing molten-ember furnace core plate
            box(f"EmberPanel_{px}_{side_y}", (1.42, 0.18, 2.02), m_ember, loc=(px, fy + side_y * 0.01, 0.0), rot=(0, 0, ang_p), bevel=0.01)
            # 5 angled bronze furnace louver slats across the glowing recess
            for li in range(-2, 3):
                box(f"Louver_{px}_{side_y}_{li}", (1.50, 0.18, 0.11), m_brass,
                    loc=(px, fy + side_y * 0.09, li * 0.36), rot=(side_y * math.radians(28), 0, ang_p), bevel=0.015)

    # Vertical bronze acoustic ribs framing the panels
    for rx in (-3.85, -1.25, 1.25, 3.85):
        u_r = rx / 4.30
        cy_r = 0.16 * (1.0 - u_r * u_r)
        box(f"AcousticRib{rx}", (0.28, 1.04, 3.9), m_brass, loc=(rx, cy_r, 0.0), bevel=0.03)

    # Arched cast-bronze suspension yoke with hanging resonance bell crown on top!
    yoke_pts = [
        Vector((-2.6, 0.10, 2.25)),
        Vector((-2.1, 0.12, 3.35)),
        Vector((-1.1, 0.14, 4.15)),
        Vector((0.0, 0.16, 4.42)),
        Vector((1.1, 0.14, 4.15)),
        Vector((2.1, 0.12, 3.35)),
        Vector((2.6, 0.10, 2.25)),
    ]
    sweep_tube("SuspensionYoke", yoke_pts, [0.22, 0.20, 0.20, 0.24, 0.20, 0.20, 0.22], m_iron, segs=8)
    for sx in (-2.6, 2.6):
        cyl(f"YokeMount_{sx}", 0.36, 0.28, 0.38, 10, m_brass, loc=(sx, 0.10, 2.32), bevel=0.03)
    # Sculpted hanging resonance bell crown suspended from the yoke apex
    cyl("BellHanger", 0.18, 0.18, 0.55, 10, m_iron, loc=(0, 0.16, 4.15), bevel=0.02)
    cyl("BellCrownDome", 1.15, 0.58, 1.25, 20, m_bronze, loc=(0, 0.16, 3.25), smooth=True, bevel=0.05)
    torus("BellSoundRim", 1.18, 0.13, 24, 8, m_brass, loc=(0, 0.16, 2.62))
    torus("BellYokeRing", 0.42, 0.10, 18, 8, m_brass, loc=(0, 0.16, 4.68), rot=(math.radians(90), 0, 0))
    save(OUT_W2, "curved_bell.glb")

    # 3. Cathedral Swinging Pendulum (pivot at Z=0, hangs down to Z=-7.5m with gleaming gold sun-bob!)
    clear()
    m_iron = mat("PendIron", (0.22, 0.20, 0.25), rough=0.38, metal=0.82)
    m_brass = mat("PendBrass", (0.90, 0.68, 0.26), rough=0.24, metal=0.90)
    m_glow = mat("PendGlow", (1.0, 0.78, 0.26), rough=0.1, em=(1.0, 0.72, 0.22), em_s=3.2)

    cyl("PivotAxle", 0.65, 0.65, 1.4, 16, m_brass, loc=(0, 0, 0), rot=(math.radians(90), 0, 0), bevel=0.04)
    box("Shaft", (0.36, 0.36, 7.2), m_iron, loc=(0, 0, -3.6), bevel=0.04)
    cyl("BobDisc", 1.85, 1.85, 0.55, 24, m_brass, loc=(0, 0, -7.2), rot=(math.radians(90), 0, 0), bevel=0.06)
    torus("BobRing", 1.55, 0.14, 28, 8, m_glow, loc=(0, 0, -7.2), rot=(math.radians(90), 0, 0))
    box("RideBar", (4.2, 2.4, 0.36), m_brass, loc=(0, 0, -5.8), bevel=0.05)
    save(OUT_W2, "pendulum_blade.glb")

    # 4. Glowing Copper-Iron Steam Vent Plinth with Valve Wheel Accents & Molten Amber Core (radius ~2.2m, top at Z=0)
    clear()
    m_copper = mat("VentCopper", (0.74, 0.38, 0.22), rough=0.32, metal=0.86)
    m_iron = mat("VentIron", (0.20, 0.19, 0.24), rough=0.44, metal=0.80)
    m_brass = mat("VentBrass", (0.90, 0.70, 0.28), rough=0.24, metal=0.90)
    m_ember = mat("VentEmberCore", (1.0, 0.56, 0.14), rough=0.14, em=(1.0, 0.52, 0.12), em_s=2.6)

    cyl("ChimneyBody", 1.75, 2.18, 1.55, 16, m_copper, loc=(0, 0, -0.78), smooth=True, bevel=0.05)
    cyl("ChimneyBaseBand", 1.86, 1.86, 0.26, 16, m_iron, loc=(0, 0, -1.42), bevel=0.03)
    torus("NozzleRim", 2.18, 0.20, 28, 10, m_brass, loc=(0, 0, -0.08))
    cyl("CoreLight", 1.78, 1.78, 0.14, 16, m_ember, loc=(0, 0, -0.14), bevel=0.02)
    for k in range(-2, 3):
        box(f"Grate{k}", (3.45, 0.18, 0.12), m_iron, loc=(0, k * 0.62, -0.06), bevel=0.02)
    box("CrossGrate", (0.22, 3.45, 0.12), m_brass, loc=(0, 0, -0.06), bevel=0.02)
    # Side brass pressure pipes & valve handwheels
    for sx in (-1.0, 1.0):
        pipe_pts = [Vector((sx * 1.85, 0, -1.35)), Vector((sx * 2.28, 0, -1.05)), Vector((sx * 2.28, 0, -0.45)), Vector((sx * 2.02, 0, -0.25))]
        sweep_tube(f"PressPipe_{sx}", pipe_pts, [0.14, 0.13, 0.13, 0.14], m_brass, segs=8)
        torus(f"ValveWheel_{sx}", 0.34, 0.055, 18, 6, m_brass, loc=(sx * 2.48, 0, -0.78), rot=(0, math.radians(90), 0))
        box(f"ValveSpokeA_{sx}", (0.05, 0.64, 0.05), m_iron, loc=(sx * 2.48, 0, -0.78), bevel=0.008)
        box(f"ValveSpokeB_{sx}", (0.05, 0.05, 0.64), m_iron, loc=(sx * 2.48, 0, -0.78), bevel=0.008)
    save(OUT_W2, "steam_vent.glb")

    # 5. Machined Riveted Dark-Iron & Hammered-Brass Foundry Sky-Catwalk (3.2m x 5.4m, top at Z=0!)
    clear()
    m_iron = mat("CatIron", (0.22, 0.20, 0.24), rough=0.42, metal=0.80)
    m_brass = mat("CatBrass", (0.88, 0.64, 0.24), rough=0.25, metal=0.90)
    m_copper = mat("CatCopper", (0.72, 0.36, 0.20), rough=0.34, metal=0.84)
    m_ember = mat("CatForgeEmber", (1.0, 0.50, 0.14), rough=0.14, em=(1.0, 0.48, 0.12), em_s=2.2)

    box("Deck", (3.18, 5.38, 0.34), m_iron, loc=(0, 0, -0.17), bevel=0.04)
    # Recessed glowing amber forge floor grates down the center spine (flush under top Z=0)
    for gy in (-1.65, 0.0, 1.65):
        box(f"ForgeGlow_{gy}", (1.35, 1.05, 0.06), m_ember, loc=(0, gy, -0.04), bevel=0.01)
        for sx_g in (-0.42, 0.0, 0.42):
            box(f"GrateBar_{gy}_{sx_g}", (0.09, 1.10, 0.05), m_iron, loc=(sx_g, gy, -0.025), bevel=0.008)
        for sy_g in (-0.30, 0.30):
            box(f"GrateCross_{gy}_{sy_g}", (1.40, 0.09, 0.05), m_brass, loc=(0, gy + sy_g, -0.025), bevel=0.008)

    # Beveled brass side girder rails + bolted corner rivets
    for sx in (-1.52, 1.52):
        box(f"SideBeam{sx}", (0.26, 5.46, 0.54), m_brass, loc=(sx, 0, -0.23), bevel=0.035)
        box(f"LowerChord{sx}", (0.22, 5.20, 0.18), m_iron, loc=(sx, 0, -1.05), bevel=0.02)
        for ry in (-2.4, -1.6, -0.8, 0.0, 0.8, 1.6, 2.4):
            cyl(f"Rivet_{sx}_{ry}", 0.048, 0.042, 0.06, 8, m_copper, loc=(sx, ry, 0.055), bevel=0.008)
        # Riveted steel diagonal truss bracing underneath side girders
        for ty_a, ty_b in [(-2.4, -0.8), (-0.8, 0.8), (0.8, 2.4)]:
            ym = 0.5 * (ty_a + ty_b)
            box(f"TrussA_{sx}_{ym}", (0.12, 1.68, 0.12), m_iron, loc=(sx, ym, -0.74), rot=(math.radians(24), 0, 0), bevel=0.01)
            box(f"TrussB_{sx}_{ym}", (0.12, 1.68, 0.12), m_iron, loc=(sx, ym, -0.74), rot=(math.radians(-24), 0, 0), bevel=0.01)
    for py in (-2.2, -1.1, 0.0, 1.1, 2.2):
        box(f"CrossRib{py}", (3.24, 0.22, 0.24), m_copper, loc=(0, py, -0.46), bevel=0.02)
    save(OUT_W2, "foundry_catwalk.glb")


if __name__ == "__main__":
    gen_w1()
    gen_w2()
    print("[world_kits_1_2] Worlds 1 & 2 AAA kits complete!")
