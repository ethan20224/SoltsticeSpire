"""
Blender 5.2.1 LTS AAA Astro Bot x Pixar-Plush Character Generator (v4 AAA Polish)
Preserves ALL exact pivot/node names and special material names:
  - Pip: BodyPivot, HeadPivot, Scarf1..4, LanternPivot, ArmL/R, LegL/R + PipVoidFace, PipEye, PipEyeCatch
  - Koko: BodyPivot, HeadPivot, WindupKey, EarL/R, Tail1..3, ArmL/R, LegL/R + KokoEyeGlass, KokoEyeDark, KokoCatchlight
  - Vesper: BodyPivot, HeadPivot, AntennaL/R, WingL/R, ArmL/R, LegL/R + VesperWingPattern, VesperEye
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector, Euler

OUT_DIR = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/models/characters"
os.makedirs(OUT_DIR, exist_ok=True)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def make_mat(name, color, roughness=0.48, metallic=0.0, emission=None, emission_strength=0.0, coat=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if coat > 0.0 and "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = coat
        bsdf.inputs["Coat Roughness"].default_value = 0.08
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


def add_bm(name, bm, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None, smooth=True, subsurf=0, bevel=0.0):
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


def make_lathe(name, profile_rz, segments, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None,
               wave_amp=0.0, wave_freq=8, subsurf=2, cap_ends=True):
    bm = bmesh.new()
    rings = []
    for idx, (r, z) in enumerate(profile_rz):
        ring = []
        t = idx / max(1, len(profile_rz) - 1)
        for s in range(segments):
            ang = 2.0 * math.pi * s / segments
            rr = r + (wave_amp * (1.0 - t) * math.sin(ang * wave_freq) if wave_amp > 0.0 else 0.0)
            ring.append(bm.verts.new((rr * math.cos(ang), rr * math.sin(ang), z)))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for s in range(segments):
            sn = (s + 1) % segments
            bm.faces.new((rings[i][s], rings[i][sn], rings[i + 1][sn], rings[i + 1][s]))
    if cap_ends:
        for end_idx, flip in [(0, True), (-1, False)]:
            if profile_rz[end_idx][0] > 0.001:
                c = bm.verts.new((0, 0, profile_rz[end_idx][1]))
                for s in range(segments):
                    sn = (s + 1) % segments
                    bm.faces.new((c, rings[end_idx][sn], rings[end_idx][s]) if flip else (c, rings[end_idx][s], rings[end_idx][sn]))
    return add_bm(name, bm, mat, loc=loc, rot=rot, parent=parent, smooth=True, subsurf=subsurf)


def make_ellipsoid(name, radii, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None, u=20, v=14, subsurf=1):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    bmesh.ops.scale(bm, vec=radii, verts=bm.verts)
    return add_bm(name, bm, mat, loc=loc, rot=rot, parent=parent, smooth=True, subsurf=subsurf)


def make_box(name, size, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None, bevel=0.02):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    return add_bm(name, bm, mat, loc=loc, rot=rot, parent=parent, smooth=True, bevel=bevel)


def make_cyl(name, r1, r2, h, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None, segs=16, bevel=0.012):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=h)
    return add_bm(name, bm, mat, loc=loc, rot=rot, parent=parent, smooth=True, bevel=bevel)


def make_torus(name, R, r, mat, loc=(0, 0, 0), rot=(0, 0, 0), parent=None, maj_s=28, min_s=12):
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
    return add_bm(name, bm, mat, loc=loc, rot=rot, parent=parent, smooth=True)


def make_tube_curve(name, points, radii, mat, parent=None, segs=10, cap=True):
    """Sweeps a smooth circular profile along a list of 3D Vector points with varying radii."""
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
            offset = (side * math.cos(a) + up * math.sin(a)) * r
            ring.append(bm.verts.new(pt + offset))
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
    return add_bm(name, bm, mat, parent=parent, smooth=True)


def join_by_parent_and_material():
    groups = {}
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and not obj.children and len(obj.data.materials) == 1 and obj.data.materials[0] is not None:
            pname = obj.parent.name if obj.parent else ""
            mname = obj.data.materials[0].name
            groups.setdefault((pname, mname), []).append(obj)
    for _, objs in groups.items():
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


def export_glb(filename):
    join_by_parent_and_material()
    filepath = os.path.join(OUT_DIR, filename)
    bpy.ops.export_scene.gltf(filepath=filepath, export_format="GLB", export_apply=True, export_yup=True)
    print(f"[gen_characters v4] Exported {filepath}")


# ==============================================================================
# 1. PIP - THE LANTERN PILGRIM (Astro Bot x Pixar-Plush Polish)
# ==============================================================================
def build_pip():
    clear_scene()
    m_cloak = make_mat("PipCloak", (0.54, 0.11, 0.09), roughness=0.78)
    m_capelet = make_mat("PipCapelet", (0.68, 0.18, 0.11), roughness=0.74)
    m_trim = make_mat("PipGoldTrim", (0.86, 0.62, 0.20), roughness=0.26, metallic=0.84)
    m_scarf = make_mat("PipScarf", (0.88, 0.60, 0.16), roughness=0.72)
    m_tunic = make_mat("PipTunic", (0.82, 0.74, 0.62), roughness=0.74)
    m_boot = make_mat("PipBoot", (0.16, 0.09, 0.06), roughness=0.36, coat=0.45)
    # Special material name recognized by WorldHelper for pip_void_face.gdshader!
    m_void_face = make_mat("PipVoidFace", (0.05, 0.04, 0.10), roughness=0.86)
    # Glossy rounded eye domes + tiny warm specular catchlight highlights (contain 'eye'/'catch')
    m_eye = make_mat("PipEye", (1.0, 0.88, 0.48), roughness=0.04, emission=(1.0, 0.82, 0.38), emission_strength=2.4, coat=0.95)
    m_catch = make_mat("PipEyeCatch", (1.0, 0.99, 0.94), roughness=0.02, emission=(1.0, 0.98, 0.92), emission_strength=3.2, coat=1.0)
    m_blush = make_mat("PipBlush", (0.98, 0.42, 0.36), roughness=0.58, emission=(0.96, 0.38, 0.30), emission_strength=1.20)
    m_brass = make_mat("PipBrass", (0.80, 0.56, 0.18), roughness=0.22, metallic=0.92)
    m_flame = make_mat("PipFlame", (0.36, 0.18, 0.04), roughness=0.12, emission=(1.0, 0.66, 0.24), emission_strength=1.65)
    m_pack = make_mat("PipPack", (0.28, 0.14, 0.07), roughness=0.54)

    root = make_empty("CharacterRoot")
    body = make_empty("BodyPivot", loc=(0, 0, 0.42), parent=root)

    # Cozy scalloped pilgrim poncho + layered shoulder capelet + subtle gold hem trim
    make_lathe("Cloak", [(0.39, -0.11), (0.395, -0.06), (0.36, 0.05), (0.30, 0.22), (0.23, 0.37), (0.18, 0.48)],
               32, m_cloak, parent=body, wave_amp=0.032, wave_freq=10, subsurf=1)
    # Gold-stitched undulating hem trim following scalloped cloak edge
    bm_hem = bmesh.new()
    hem_pts = []
    hem_segs = 40
    for s in range(hem_segs):
        ang = 2.0 * math.pi * s / hem_segs
        rr = 0.395 + 0.030 * math.sin(ang * 10)
        hem_pts.append(Vector((rr * math.cos(ang), rr * math.sin(ang), -0.105)))
    hem_rings = []
    for s in range(hem_segs):
        p0 = hem_pts[s]
        rad_dir = Vector((p0.x, p0.y, 0.0)).normalized()
        up_dir = Vector((0, 0, 1))
        ring = []
        for j in range(6):
            pa = 2.0 * math.pi * j / 6
            ring.append(bm_hem.verts.new(p0 + rad_dir * (0.011 * math.cos(pa)) + up_dir * (0.011 * math.sin(pa))))
        hem_rings.append(ring)
    for s in range(hem_segs):
        r0 = hem_rings[s]
        r1 = hem_rings[(s + 1) % hem_segs]
        for j in range(6):
            jn = (j + 1) % 6
            bm_hem.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
    add_bm("CloakGoldHem", bm_hem, m_trim, parent=body, smooth=True)

    make_lathe("ShoulderCapelet", [(0.315, 0.21), (0.325, 0.25), (0.27, 0.36), (0.20, 0.47)],
               28, m_capelet, parent=body, wave_amp=0.024, wave_freq=10, subsurf=1)
    # Soft cream stitched tunic peek beneath cloak
    make_lathe("Tunic", [(0.245, -0.17), (0.215, 0.02), (0.16, 0.22)], 22, m_tunic, parent=body, subsurf=1)
    # Chunky cozy knitted honey-scarf collar
    make_torus("ScarfCollarA", 0.202, 0.056, m_scarf, loc=(0, 0, 0.47), parent=body, maj_s=32, min_s=12)
    make_torus("ScarfCollarB", 0.176, 0.044, m_scarf, loc=(0, 0.01, 0.53), parent=body, maj_s=28, min_s=12)
    # Brass heirloom clasp brooch on front chest
    make_torus("BroochRim", 0.048, 0.010, m_brass, loc=(0, 0.252, 0.40), rot=(math.radians(85), 0, 0), parent=body, maj_s=18, min_s=8)
    make_ellipsoid("ChestBrooch", (0.036, 0.020, 0.036), m_flame, loc=(0, 0.256, 0.40), parent=body, u=12, v=8, subsurf=0)

    # Head & Adorable Curved Pilgrim Hood with subtly sculpted PipVoidFace + glossy eye domes & catchlights
    head = make_empty("HeadPivot", loc=(0, 0, 0.56), parent=body)
    make_ellipsoid("ShadowFace", (0.215, 0.205, 0.215), m_void_face, loc=(0, 0.03, 0.18), parent=head, u=24, v=16)
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        make_ellipsoid(f"Eye{side}", (0.050, 0.030, 0.066), m_eye,
                       loc=(sx * 0.076, 0.216, 0.200), rot=(0, 0, sx * -0.12), parent=head, u=16, v=12, subsurf=1)
        make_ellipsoid(f"EyeCatch{side}", (0.016, 0.012, 0.018), m_catch,
                       loc=(sx * 0.062, 0.243, 0.226), parent=head, u=10, v=8, subsurf=0)
        make_ellipsoid(f"Blush{side}", (0.046, 0.018, 0.026), m_blush,
                       loc=(sx * 0.124, 0.198, 0.142), parent=head, u=12, v=8)

    # High-resolution Smooth Plush Hood with gold-stitched hood border
    bm_hood = bmesh.new()
    hood_slices = [
        (0.062, 0.18, 0.268, 0.278, 0.04),
        (-0.02, 0.19, 0.282, 0.290, 0.08),
        (-0.11, 0.19, 0.268, 0.275, 0.14),
        (-0.19, 0.18, 0.225, 0.230, 0.22),
        (-0.25, 0.17, 0.148, 0.152, 0.30),
        (-0.285, 0.16, 0.066, 0.070, 0.36),
    ]
    segs = 28
    hrings = []
    for cy, cz, rx, rz, tx in hood_slices:
        ring = []
        for s in range(segs):
            ang = 2.0 * math.pi * s / segs
            p = Vector((rx * math.cos(ang), 0.0, rz * math.sin(ang)))
            p.rotate(Euler((tx, 0, 0), "XYZ"))
            ring.append(bm_hood.verts.new((p.x, p.y + cy, p.z + cz)))
        hrings.append(ring)
    for i in range(len(hrings) - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            bm_hood.faces.new((hrings[i][s], hrings[i][sn], hrings[i + 1][sn], hrings[i + 1][s]))
    tip = bm_hood.verts.new((0, -0.302, 0.155))
    for s in range(segs):
        sn = (s + 1) % segs
        bm_hood.faces.new((tip, hrings[-1][s], hrings[-1][sn]))
    inner_front = []
    for s in range(segs):
        ang = 2.0 * math.pi * s / segs
        p = Vector((0.215 * math.cos(ang), 0.0, 0.225 * math.sin(ang)))
        p.rotate(Euler((0.04, 0, 0), "XYZ"))
        inner_front.append(bm_hood.verts.new((p.x, p.y + 0.03, p.z + 0.18)))
    for s in range(segs):
        sn = (s + 1) % segs
        bm_hood.faces.new((hrings[0][sn], hrings[0][s], inner_front[s], inner_front[sn]))
    add_bm("PilgrimHood", bm_hood, m_cloak, parent=head, smooth=True, subsurf=1)

    # Gold-stitched hood border: sleek inner piping + stitched gold dashes around the face opening
    make_torus("HoodRimTrim", 0.258, 0.013, m_trim, loc=(0, 0.062, 0.18), rot=(math.radians(94), 0, 0), parent=head, maj_s=32, min_s=8)
    for st in range(18):
        a = 2.0 * math.pi * st / 18
        p_st = Vector((0.268 * math.cos(a), 0.0, 0.276 * math.sin(a)))
        p_st.rotate(Euler((0.04, 0, 0), "XYZ"))
        make_ellipsoid(f"HoodStitch_{st}", (0.014, 0.009, 0.008), m_trim,
                       loc=(p_st.x, p_st.y + 0.048, p_st.z + 0.18),
                       rot=(0, -a, 0), parent=head, u=8, v=6, subsurf=0)

    # 4-Segment Warm Embroidered Scarf (plush pillowed segments + gold embroidery bands)
    sp_p, sp_l = body, (0.05, -0.20, 0.48)
    for idx in range(4):
        sp = make_empty(f"Scarf{idx + 1}", loc=sp_l, parent=sp_p)
        w = 0.082 - idx * 0.008
        make_ellipsoid(f"ScarfMesh{idx + 1}", (w, 0.105, 0.026), m_scarf, loc=(0, -0.092, -0.015), parent=sp, u=14, v=10, subsurf=1)
        # Embroidered gold geometric cross-band near each segment end
        make_box(f"ScarfEmb{idx + 1}", (w * 1.48, 0.026, 0.046), m_trim, loc=(0, -0.145, -0.018), parent=sp, bevel=0.008)
        if idx == 3:
            make_box("ScarfTrim", (w * 1.55, 0.042, 0.044), m_trim, loc=(0, -0.185, -0.022), parent=sp, bevel=0.010)
            for ti in (-1, 0, 1):
                make_cyl(f"ScarfTassel_{ti}", 0.014, 0.006, 0.055, m_trim,
                         loc=(ti * 0.032, -0.215, -0.032), rot=(math.radians(78), 0, 0), parent=sp, segs=8, bevel=0.003)
        sp_p, sp_l = sp, (0, -0.17, -0.022)

    # Stitched Leather Backpack + Contoured Shoulder Straps + Brass Buckles
    make_box("ExplorerPack", (0.26, 0.16, 0.28), m_pack, loc=(0, -0.23, 0.24), parent=body, bevel=0.045)
    make_box("PackFlap", (0.275, 0.175, 0.085), m_capelet, loc=(0, -0.23, 0.35), parent=body, bevel=0.025)
    make_box("PackBuckle", (0.085, 0.032, 0.062), m_brass, loc=(0, -0.32, 0.30), parent=body, bevel=0.008)
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        strap_pts = [
            Vector((sx * 0.11, -0.16, 0.35)),
            Vector((sx * 0.17, -0.02, 0.42)),
            Vector((sx * 0.16, 0.14, 0.34)),
            Vector((sx * 0.15, 0.16, 0.18)),
            Vector((sx * 0.15, -0.14, 0.15)),
        ]
        make_tube_curve(f"PackStrap{side}", strap_pts, [0.022, 0.022, 0.022, 0.020, 0.020], m_pack, parent=body, segs=8)
        make_box(f"StrapBuckle{side}", (0.048, 0.024, 0.044), m_brass, loc=(sx * 0.162, 0.152, 0.26), parent=body, bevel=0.006)

    # Lantern Staff Angled ~50° UP and FORWARD + Intricately Framed Brass Heirloom Lantern
    make_cyl("LanternStaff", 0.018, 0.014, 0.62, m_brass,
             loc=(0.24, 0.08, 0.46), rot=(math.radians(-40), math.radians(12), 0), parent=body, bevel=0.004)
    make_torus("StaffCollar", 0.024, 0.007, m_brass, loc=(0.30, 0.26, 0.67), rot=(math.radians(50), 0, 0), parent=body, maj_s=14, min_s=6)
    lp = make_empty("LanternPivot", loc=(0.30, 0.28, 0.69), parent=body)
    make_torus("LanternRing", 0.028, 0.007, m_brass, loc=(0, 0, -0.01), rot=(math.radians(90), 0, 0), parent=lp, maj_s=16, min_s=6)
    make_cyl("LanternFinialTop", 0.022, 0.006, 0.032, m_brass, loc=(0, 0, -0.025), parent=lp, segs=8, bevel=0.004)
    make_cyl("LanternCapTop", 0.088, 0.028, 0.056, m_brass, loc=(0, 0, -0.062), parent=lp, segs=8, bevel=0.007)
    make_torus("LanternTopRim", 0.086, 0.009, m_brass, loc=(0, 0, -0.090), parent=lp, maj_s=16, min_s=6)
    make_ellipsoid("LanternCore", (0.060, 0.060, 0.082), m_flame, loc=(0, 0, -0.155), parent=lp, u=14, v=10, subsurf=0)
    make_torus("LanternWaistRing", 0.082, 0.008, m_brass, loc=(0, 0, -0.155), parent=lp, maj_s=16, min_s=6)
    for ri in range(4):
        ra = ri * math.pi * 0.5 + math.pi * 0.25
        make_cyl(f"LanternRib_{ri}", 0.009, 0.009, 0.138, m_brass,
                 loc=(0.078 * math.cos(ra), 0.078 * math.sin(ra), -0.155), parent=lp, segs=6, bevel=0.003)
    make_torus("LanternBotRim", 0.080, 0.009, m_brass, loc=(0, 0, -0.220), parent=lp, maj_s=16, min_s=6)
    make_cyl("LanternCapBot", 0.038, 0.078, 0.048, m_brass, loc=(0, 0, -0.245), parent=lp, segs=8, bevel=0.006)
    make_cyl("LanternFinialBot", 0.006, 0.022, 0.035, m_brass, loc=(0, 0, -0.280), parent=lp, segs=8, bevel=0.003)

    # Cozy Connected Sleeves & Rounded Explorer Boots
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        arm = make_empty(f"Arm{side}", loc=(sx * 0.24, 0.04, 0.34), parent=body)
        make_ellipsoid(f"Sleeve{side}", (0.086, 0.086, 0.148), m_capelet, loc=(sx * 0.04, 0.02, -0.09), rot=(0, sx * 0.30, 0), parent=arm)
        make_ellipsoid(f"CuffCloth{side}", (0.068, 0.068, 0.035), m_scarf, loc=(sx * 0.07, 0.03, -0.19), parent=arm)
        make_ellipsoid(f"Mitten{side}", (0.058, 0.062, 0.058), m_boot, loc=(sx * 0.08, 0.04, -0.23), parent=arm)

        leg = make_empty(f"Leg{side}", loc=(sx * 0.125, 0.0, 0.34), parent=root)
        make_cyl(f"Shin{side}", 0.066, 0.074, 0.22, m_tunic, loc=(0, 0, -0.13), parent=leg, bevel=0.014)
        make_ellipsoid(f"Boot{side}", (0.084, 0.132, 0.076), m_boot, loc=(0, 0.038, -0.275), parent=leg)
        make_ellipsoid(f"BootFold{side}", (0.074, 0.082, 0.038), m_scarf, loc=(0, 0.008, -0.205), parent=leg)

    export_glb("pip.glb")


# ==============================================================================
# 2. KOKO - THE CLOCKWORK FOX (Aviator Jacket, Fluffy Cheeks, Notched Key!)
# ==============================================================================
def build_koko():
    clear_scene()
    m_cream = make_mat("KokoCream", (0.89, 0.83, 0.73), roughness=0.56)
    m_fur = make_mat("KokoPlushAmber", (0.72, 0.29, 0.11), roughness=0.72)
    m_brass = make_mat("KokoBrass", (0.84, 0.60, 0.20), roughness=0.22, metallic=0.92)
    m_teal = make_mat("KokoTealVest", (0.14, 0.46, 0.54), roughness=0.56, coat=0.20)
    m_shorts = make_mat("KokoShorts", (0.20, 0.32, 0.40), roughness=0.70)
    m_eye_dark = make_mat("KokoEyeDark", (0.03, 0.035, 0.055), roughness=0.04, coat=1.0)
    m_catchlight = make_mat("KokoCatchlight", (1.0, 1.0, 1.0), roughness=0.04, emission=(1.0, 0.98, 0.95), emission_strength=2.6)
    m_cyan = make_mat("KokoCyanGlow", (0.24, 0.86, 1.0), roughness=0.08, emission=(0.20, 0.84, 1.0), emission_strength=2.2)
    # Material containing both 'eye' and 'glass' so apply_plush_character_materials keeps it glossy!
    m_goggle_glass = make_mat("KokoEyeGlass", (0.26, 0.88, 1.0), roughness=0.05, metallic=0.12,
                              emission=(0.16, 0.74, 0.96), emission_strength=0.65, coat=1.0)
    m_blush = make_mat("KokoBlush", (0.94, 0.44, 0.42), roughness=0.66)
    m_leather = make_mat("KokoStrap", (0.26, 0.13, 0.07), roughness=0.46, coat=0.25)

    root = make_empty("CharacterRoot")
    body = make_empty("BodyPivot", loc=(0, 0, 0.42), parent=root)

    # Sleek porcelain-and-riveted-brass aviator jacket torso + stitched collar + sculpted shoulder pads
    make_ellipsoid("Torso", (0.252, 0.232, 0.272), m_teal, loc=(0, 0, 0.19), parent=body, u=22, v=16, subsurf=1)
    make_ellipsoid("PelvisShorts", (0.242, 0.212, 0.142), m_shorts, loc=(0, 0, 0.01), parent=body, subsurf=1)
    make_ellipsoid("BellyFluff", (0.165, 0.12, 0.18), m_cream, loc=(0, 0.145, 0.20), parent=body)
    # Stitched aviator jacket front trim panels & brass rivets
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        make_box(f"JacketLapel{side}", (0.072, 0.042, 0.12), m_leather,
                 loc=(sx * 0.105, 0.195, 0.365), rot=(math.radians(-18), sx * math.radians(16), sx * math.radians(-14)), parent=body, bevel=0.012)
        make_ellipsoid(f"JacketRivet{side}_A", (0.014, 0.010, 0.014), m_brass,
                       loc=(sx * 0.115, 0.218, 0.34), parent=body, u=8, v=6, subsurf=0)
        make_ellipsoid(f"JacketRivet{side}_B", (0.014, 0.010, 0.014), m_brass,
                       loc=(sx * 0.095, 0.232, 0.27), parent=body, u=8, v=6, subsurf=0)
        # Sculpted aviator shoulder pads with riveted brass edge band
        make_ellipsoid(f"ShoulderPad{side}", (0.096, 0.105, 0.056), m_leather,
                       loc=(sx * 0.215, 0.015, 0.368), rot=(0, sx * math.radians(22), 0), parent=body, u=14, v=10, subsurf=1)
        make_ellipsoid(f"PadRivet{side}", (0.014, 0.014, 0.010), m_brass,
                       loc=(sx * 0.255, 0.015, 0.405), parent=body, u=8, v=6, subsurf=0)

    # Cozy cream shearling aviator collar + stitched leather neck band
    make_ellipsoid("FurNeckCollar", (0.195, 0.185, 0.075), m_cream, loc=(0, 0.01, 0.425), parent=body)
    make_torus("CoreRing", 0.068, 0.015, m_brass, loc=(0, 0.246, 0.21), rot=(math.radians(90), 0, 0), parent=body, maj_s=24, min_s=8)
    make_ellipsoid("CoreGlow", (0.052, 0.024, 0.052), m_cyan, loc=(0, 0.246, 0.21), parent=body)
    # Single sleek snug leather waist belt + brass buckle
    make_torus("WaistBelt", 0.230, 0.028, m_leather, loc=(0, 0, 0.06), parent=body, maj_s=28, min_s=10)
    make_box("BeltBuckle", (0.082, 0.042, 0.070), m_brass, loc=(0, 0.242, 0.06), parent=body, bevel=0.012)

    # Detailed Notched Clockwork Brass Wind-Up Key on Back
    windup = make_empty("WindupKey", loc=(0, -0.24, 0.23), parent=body)
    make_cyl("KeyEscutcheon", 0.056, 0.042, 0.036, m_brass, loc=(0, -0.015, 0), rot=(math.radians(90), 0, 0), parent=windup, segs=12, bevel=0.008)
    make_cyl("KeyShaft", 0.024, 0.024, 0.14, m_brass, loc=(0, -0.065, 0), rot=(math.radians(90), 0, 0), parent=windup, bevel=0.005)
    make_torus("KeyNotchCollar", 0.036, 0.010, m_brass, loc=(0, -0.085, 0), rot=(math.radians(90), 0, 0), parent=windup, maj_s=16, min_s=6)
    make_box("KeyBridge", (0.145, 0.022, 0.034), m_brass, loc=(0, -0.145, 0), parent=windup, bevel=0.006)
    for side_x in (-0.072, 0.072):
        make_torus(f"KeyLoop_{side_x}", 0.072, 0.020, m_brass, loc=(side_x, -0.145, 0), rot=(math.radians(90), 0, 0), parent=windup, maj_s=24, min_s=10)
        # Decorative clockwork gear notches on outer bow
        for ni in (-1, 0, 1):
            na = ni * 0.45
            sx_dir = -1.0 if side_x < 0 else 1.0
            make_box(f"KeyNotch_{side_x}_{ni}", (0.022, 0.024, 0.022), m_brass,
                     loc=(side_x + sx_dir * 0.088 * math.cos(na), -0.145, 0.088 * math.sin(na)),
                     rot=(0, sx_dir * -na, 0), parent=windup, bevel=0.004)

    # Adorable Oversized Plush Fox Head with Fluffy Multi-Lobe Cheeks & Glossy Button Nose
    head = make_empty("HeadPivot", loc=(0, 0.02, 0.46), parent=body)
    make_ellipsoid("Skull", (0.278, 0.248, 0.228), m_fur, loc=(0, 0, 0.21), parent=head, u=24, v=16, subsurf=1)
    # Fluffy multi-lobe cheeks (main cheek + upper fluff tuft + lower whisker tuft)
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        make_ellipsoid(f"CheekMain{side}", (0.155, 0.130, 0.098), m_cream,
                       loc=(sx * 0.175, 0.085, 0.130), rot=(0, sx * -0.15, sx * 0.22), parent=head, u=16, v=12, subsurf=1)
        make_ellipsoid(f"CheekTuftTop{side}", (0.075, 0.055, 0.048), m_cream,
                       loc=(sx * 0.275, 0.030, 0.165), rot=(0, sx * -0.25, sx * 0.35), parent=head, u=12, v=8)
        make_ellipsoid(f"CheekTuftLow{side}", (0.068, 0.050, 0.042), m_cream,
                       loc=(sx * 0.245, 0.045, 0.102), rot=(0, sx * 0.18, sx * 0.20), parent=head, u=12, v=8)
    make_ellipsoid("Muzzle", (0.114, 0.138, 0.086), m_cream, loc=(0, 0.222, 0.138), parent=head, u=18, v=12, subsurf=1)
    make_ellipsoid("ChinFluff", (0.074, 0.070, 0.044), m_cream, loc=(0, 0.210, 0.086), parent=head, u=12, v=8)
    # Glossy dark button nose + subtle specular catchlight
    make_ellipsoid("Nose", (0.045, 0.036, 0.034), m_eye_dark, loc=(0, 0.348, 0.162), parent=head, u=14, v=10, subsurf=1)
    make_ellipsoid("NoseCatch", (0.012, 0.008, 0.009), m_catchlight, loc=(-0.012, 0.380, 0.178), parent=head, u=8, v=6, subsurf=0)

    for side, sx in [("L", -1.0), ("R", 1.0)]:
        make_ellipsoid(f"Eye{side}", (0.052, 0.032, 0.056), m_eye_dark,
                       loc=(sx * 0.112, 0.226, 0.205), rot=(0, 0, sx * -0.28), parent=head, u=16, v=12)
        make_ellipsoid(f"Catch{side}", (0.018, 0.012, 0.019), m_catchlight,
                       loc=(sx * 0.098, 0.256, 0.224), parent=head, u=8, v=6, subsurf=0)
        make_ellipsoid(f"Blush{side}", (0.046, 0.018, 0.026), m_blush,
                       loc=(sx * 0.175, 0.206, 0.145), rot=(0, 0, sx * -0.4), parent=head)

        # Gleaming brass goggles with beveled rims, side bolts, and glassy cyan lenses!
        make_torus(f"GoggleRim{side}", 0.070, 0.018, m_brass,
                   loc=(sx * 0.084, 0.186, 0.346), rot=(math.radians(52), 0, sx * -0.22), parent=head, maj_s=24, min_s=10)
        make_torus(f"GoggleOuterBevel{side}", 0.076, 0.008, m_brass,
                   loc=(sx * 0.084, 0.178, 0.340), rot=(math.radians(52), 0, sx * -0.22), parent=head, maj_s=24, min_s=6)
        make_ellipsoid(f"GoggleGlass{side}", (0.056, 0.022, 0.056), m_goggle_glass,
                       loc=(sx * 0.084, 0.192, 0.350), rot=(math.radians(-38), 0, sx * -0.22), parent=head, u=16, v=12)
        make_cyl(f"GoggleBolt{side}", 0.014, 0.014, 0.026, m_brass,
                 loc=(sx * 0.156, 0.155, 0.335), rot=(0, math.radians(90), 0), parent=head, segs=8, bevel=0.003)

        ear = make_empty(f"Ear{side}", loc=(sx * 0.15, -0.01, 0.38), rot=(math.radians(-8), sx * math.radians(20), 0), parent=head)
        bm_e = bmesh.new()
        bmesh.ops.create_cone(bm_e, cap_ends=True, cap_tris=False, segments=12, radius1=0.095, radius2=0.022, depth=0.35)
        bmesh.ops.scale(bm_e, vec=(0.95, 0.52, 1.0), verts=bm_e.verts)
        add_bm(f"EarOuter{side}", bm_e, m_fur, loc=(0, 0, 0.17), parent=ear, smooth=True, subsurf=1)
        make_ellipsoid(f"EarInner{side}", (0.045, 0.020, 0.12), m_cream, loc=(0, 0.036, 0.15), parent=ear)
        make_ellipsoid(f"EarTip{side}", (0.032, 0.025, 0.048), m_cream, loc=(0, 0, 0.34), parent=ear)

    make_box("GoggleBridge", (0.048, 0.022, 0.024), m_brass, loc=(0, 0.212, 0.342), rot=(math.radians(52), 0, 0), parent=head, bevel=0.005)
    make_torus("GoggleStrap", 0.256, 0.020, m_leather, loc=(0, -0.01, 0.30), rot=(math.radians(18), 0, 0), parent=head, maj_s=28, min_s=8)

    # Big Fluffy 3-Segment Fox Tail
    t_p, t_l = body, (0, -0.20, 0.07)
    for idx, (rad, m_t, off) in enumerate([
        ((0.098, 0.145, 0.098), m_fur, (0, -0.11, 0.03)),
        ((0.140, 0.175, 0.140), m_fur, (0, -0.15, 0.05)),
        ((0.118, 0.175, 0.118), m_cream, (0, -0.15, 0.05)),
    ]):
        tp = make_empty(f"Tail{idx + 1}", loc=t_l, parent=t_p)
        make_ellipsoid(f"TailSeg{idx + 1}", rad, m_t, loc=off, parent=tp)
        t_p, t_l = tp, (0, -0.23, 0.06)

    # Seamless Connected Sleeves & Cuffed Aviator Boots
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        arm = make_empty(f"Arm{side}", loc=(sx * 0.23, 0.02, 0.32), parent=body)
        make_ellipsoid(f"ShoulderSleeve{side}", (0.088, 0.088, 0.092), m_teal, loc=(sx * 0.01, 0, -0.02), parent=arm)
        make_cyl(f"ArmPlush{side}", 0.062, 0.074, 0.18, m_fur, loc=(sx * 0.035, 0.01, -0.12), rot=(0, sx * 0.16, 0), parent=arm, bevel=0.016)
        make_ellipsoid(f"WristCuff{side}", (0.068, 0.068, 0.030), m_leather, loc=(sx * 0.042, 0.015, -0.185), parent=arm, u=12, v=8)
        make_ellipsoid(f"Paw{side}", (0.064, 0.070, 0.058), m_cream, loc=(sx * 0.045, 0.02, -0.22), parent=arm)

        leg = make_empty(f"Leg{side}", loc=(sx * 0.125, 0.0, 0.38), parent=root)
        make_cyl(f"HipCuff{side}", 0.090, 0.098, 0.13, m_shorts, loc=(0, 0, -0.04), parent=leg, bevel=0.018)
        make_cyl(f"ThighShin{side}", 0.072, 0.084, 0.18, m_fur, loc=(0, 0, -0.15), parent=leg, bevel=0.016)
        # Cuffed aviator boot: plush shearling fold + leather boot shaft + brass buckle + rounded boot toe & sole
        make_ellipsoid(f"BootShearlingCuff{side}", (0.086, 0.092, 0.036), m_cream, loc=(0, 0.006, -0.215), parent=leg, u=14, v=8)
        make_cyl(f"BootGaiter{side}", 0.078, 0.082, 0.10, m_leather, loc=(0, 0.010, -0.265), parent=leg, bevel=0.015)
        make_box(f"BootBuckle{side}", (0.036, 0.024, 0.028), m_brass, loc=(sx * 0.065, 0.024, -0.260), parent=leg, bevel=0.005)
        make_ellipsoid(f"Foot{side}", (0.086, 0.132, 0.070), m_leather, loc=(0, 0.038, -0.312), parent=leg)
        make_box(f"Sole{side}", (0.152, 0.232, 0.034), m_cream, loc=(0, 0.038, -0.358), parent=leg, bevel=0.012)

    export_glb("koko.glb")


# ==============================================================================
# 3. VESPER - THE ORIGAMI MOTH (Porcelain Mask, Brow Plumes, Layered Wing Tails!)
# ==============================================================================
def build_vesper():
    clear_scene()
    m_indigo = make_mat("VesperIndigo", (0.09, 0.11, 0.26), roughness=0.70)
    m_plush_ruff = make_mat("VesperRuff", (0.91, 0.87, 0.81), roughness=0.78)
    m_mask = make_mat("VesperMask", (0.94, 0.90, 0.84), roughness=0.22, coat=0.65)
    m_gold = make_mat("VesperGold", (0.88, 0.66, 0.22), roughness=0.22, metallic=0.90)
    m_obi_cloth = make_mat("VesperObiCloth", (0.36, 0.22, 0.48), roughness=0.70)
    # Preserved special material name for vesper_wing_albedo.png!
    m_wing_pat = make_mat("VesperWingPattern", (0.94, 0.90, 0.84), roughness=0.68)
    m_wing_fringe = make_mat("VesperWingFringe", (0.86, 0.78, 0.70), roughness=0.82)
    m_eye = make_mat("VesperEye", (0.94, 0.74, 1.0), roughness=0.04, emission=(0.88, 0.58, 1.0), emission_strength=2.5, coat=0.95)
    m_boot = make_mat("VesperBoot", (0.08, 0.09, 0.18), roughness=0.38, coat=0.40)

    root = make_empty("CharacterRoot")
    body = make_empty("BodyPivot", loc=(0, 0, 0.42), parent=root)

    # Crisp Pleated Indigo-Velvet Tunic with Gold-Embroidered Hem Trim
    make_lathe("OrigamiRobe", [(0.37, -0.11), (0.33, 0.06), (0.25, 0.24), (0.18, 0.45)],
               16, m_indigo, parent=body, wave_amp=0.024, wave_freq=16, subsurf=1)
    # Gold-embroidered pleated hem trim following the 16-pleat edge
    bm_vhem = bmesh.new()
    vhem_rings = []
    vhem_segs = 48
    for s in range(vhem_segs):
        ang = 2.0 * math.pi * s / vhem_segs
        rr = 0.330 + 0.014 * math.sin(ang * 16)
        p0 = Vector((rr * math.cos(ang), rr * math.sin(ang), -0.092))
        rad_dir = Vector((math.cos(ang), math.sin(ang), 0.0))
        up_dir = Vector((0, 0, 1))
        ring = []
        for j in range(6):
            pa = 2.0 * math.pi * j / 6
            ring.append(bm_vhem.verts.new(p0 + rad_dir * (0.011 * math.cos(pa)) + up_dir * (0.011 * math.sin(pa))))
        vhem_rings.append(ring)
    for s in range(vhem_segs):
        r0 = vhem_rings[s]
        r1 = vhem_rings[(s + 1) % vhem_segs]
        for j in range(6):
            jn = (j + 1) % 6
            bm_vhem.faces.new((r0[j], r0[jn], r1[jn], r1[j]))
    add_bm("RobeGoldHem", bm_vhem, m_gold, parent=body, smooth=True)

    make_lathe("SnugObiWrap", [(0.278, 0.08), (0.270, 0.15), (0.252, 0.22)],
               22, m_obi_cloth, parent=body, wave_amp=0.0, subsurf=1)
    make_torus("ObiGoldCord", 0.272, 0.011, m_gold, loc=(0, 0, 0.15), parent=body, maj_s=28, min_s=8)
    make_torus("GoldNeckRing", 0.16, 0.016, m_gold, loc=(0, 0, 0.51), parent=body, maj_s=24, min_s=8)

    # Fluffy Multi-Tuft Plush Ruff Collar (12 layered varied puffs)
    for i in range(12):
        a = i * math.tau / 12.0
        sc = 1.0 + 0.16 * (1 if i % 2 == 0 else -1)
        z_off = 0.44 + (0.022 if i % 2 == 0 else -0.010)
        make_ellipsoid(f"RuffPuff{i}", (0.098 * sc, 0.098 * sc, 0.082 * sc), m_plush_ruff,
                       loc=(0.185 * math.cos(a), 0.185 * math.sin(a), z_off), parent=body, u=14, v=10)
    make_ellipsoid("RuffClasp", (0.036, 0.022, 0.036), m_gold, loc=(0, 0.242, 0.44), parent=body, u=10, v=8, subsurf=0)

    # Sculpted Smooth Porcelain Owl-Moth Face Mask + Expressive Golden Brow Plumes
    head = make_empty("HeadPivot", loc=(0, 0.01, 0.54), parent=body)
    make_ellipsoid("InnerHead", (0.202, 0.192, 0.202), m_indigo, loc=(0, -0.01, 0.19), parent=head, u=22, v=16, subsurf=1)
    make_ellipsoid("MaskBase", (0.215, 0.105, 0.188), m_mask, loc=(0, 0.135, 0.188), parent=head, u=22, v=16, subsurf=1)
    make_cyl("MaskBeakCrest", 0.052, 0.008, 0.125, m_gold, loc=(0, 0.236, 0.148), rot=(math.radians(-115), 0, 0), parent=head, segs=6, bevel=0.006)

    for side, sx in [("L", -1.0), ("R", 1.0)]:
        # Sculpted porcelain owl-disc cheek plates framing the eyes
        make_ellipsoid(f"MaskCheek{side}", (0.105, 0.068, 0.115), m_mask,
                       loc=(sx * 0.092, 0.155, 0.182), rot=(0, sx * -0.14, sx * 0.12), parent=head, u=16, v=12, subsurf=1)
        make_ellipsoid(f"Eye{side}", (0.048, 0.026, 0.042), m_eye,
                       loc=(sx * 0.092, 0.216, 0.198), rot=(0, sx * -0.18, sx * -0.22), parent=head, u=14, v=10)
        # Expressive golden brow plumes (3 layered sweeping feather crests per side!)
        for bi in range(3):
            bf = bi * 0.045
            make_ellipsoid(f"BrowPlume{side}_{bi}", (0.052 - bi * 0.008, 0.016, 0.022), m_gold,
                           loc=(sx * (0.072 + bf), 0.212 - bi * 0.016, 0.244 + bi * 0.020),
                           rot=(math.radians(15), sx * math.radians(-26 - bi * 10), sx * math.radians(-14)),
                           parent=head, u=10, v=6, subsurf=0)

        # Feathered Golden Antennae (5 feather barbs along an arched stem)
        ant = make_empty(f"Antenna{side}", loc=(sx * 0.09, 0.05, 0.36),
                         rot=(math.radians(-18), sx * math.radians(30), 0), parent=head)
        stem_pts = [Vector((0, 0, 0)), Vector((sx * 0.018, -0.01, 0.11)), Vector((sx * 0.048, -0.025, 0.22)), Vector((sx * 0.082, -0.045, 0.32))]
        make_tube_curve(f"AntStem{side}", stem_pts, [0.020, 0.015, 0.011, 0.006], m_gold, parent=ant, segs=8)
        for k in range(5):
            t = (k + 1) / 5.5
            px = sx * (0.012 + t * 0.068)
            pz = 0.07 + k * 0.056
            py = -0.01 - k * 0.008
            w_p = 0.054 * (1.0 - k * 0.10)
            make_ellipsoid(f"Plume{side}_{k}", (w_p, 0.012, 0.024), m_gold,
                           loc=(px + sx * 0.032, py, pz), rot=(0, sx * -0.25, sx * 0.32), parent=ant, u=8, v=6, subsurf=0)

    # Multi-layered Beveled Moth Wings (UV-preserved VesperWingPattern!) + Curled Lower Wing Tails
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        wing = make_empty(f"Wing{side}", loc=(sx * 0.11, -0.15, 0.36), parent=body)

        # Curved 7x5 lofted scalloped moth forewing with exact UVs for vesper_wing_albedo.png!
        bm_w = bmesh.new()
        uv_layer = bm_w.loops.layers.uv.new("UVMap")
        cols_n = 7
        rows_n = 5
        grid_f = []
        for r in range(rows_n):
            v = r / (rows_n - 1)
            row_verts = []
            for c in range(cols_n):
                u = c / (cols_n - 1)
                span_x = sx * (0.04 + u * 0.64 * (1.0 - 0.28 * v * v))
                arch_z = (0.30 * math.sin(u * math.pi * 0.68) + 0.06 * u) * (1.0 - v) + (-0.28 * math.sin(u * math.pi * 0.85) - 0.12) * v
                sweep_y = -0.06 - u * 0.18 + math.sin(u * math.pi) * math.sin(v * math.pi) * 0.04
                if c == cols_n - 1:
                    span_x += sx * 0.03 * math.sin(v * math.pi * 3.0)
                row_verts.append(bm_w.verts.new((span_x, sweep_y, arch_z)))
            grid_f.append(row_verts)

        for r in range(rows_n - 1):
            for c in range(cols_n - 1):
                v00, v10, v11, v01 = grid_f[r][c], grid_f[r][c + 1], grid_f[r + 1][c + 1], grid_f[r + 1][c]
                verts = (v00, v10, v11, v01) if sx > 0 else (v00, v01, v11, v10)
                f = bm_w.faces.new(verts)
                u0, u1 = c / (cols_n - 1), (c + 1) / (cols_n - 1)
                vv0, vv1 = r / (rows_n - 1), (r + 1) / (rows_n - 1)
                uvs = [(u0, vv0), (u1, vv0), (u1, vv1), (u0, vv1)] if sx > 0 else [(u0, vv0), (u0, vv1), (u1, vv1), (u1, vv0)]
                for lp, uv in zip(f.loops, uvs):
                    lp[uv_layer].uv = uv

        bmesh.ops.solidify(bm_w, geom=bm_w.faces[:], thickness=0.034)
        add_bm(f"CurvedUpperWing{side}", bm_w, m_wing_pat, parent=wing, smooth=True, subsurf=1, bevel=0.008)

        # Soft plush felt scalloped fringe tufts along lower trailing edge
        for k in range(5):
            fu = 0.22 + k * 0.16
            fx = sx * (0.06 + fu * 0.44)
            fz = -0.14 - math.sin(fu * math.pi * 0.85) * 0.26
            fy = -0.07 - fu * 0.15
            make_ellipsoid(f"WingFringe{side}_{k}", (0.056, 0.036, 0.072), m_wing_fringe,
                           loc=(fx, fy, fz), rot=(0.0, sx * 0.22, 0.0), parent=wing, u=10, v=8, subsurf=0)

        # Secondary overlapping layered hindwing + delicate curled luna-moth lower wing tail!
        make_ellipsoid(f"LowerWingPetal{side}", (0.155, 0.026, 0.215), m_obi_cloth,
                       loc=(sx * 0.24, -0.20, -0.23), rot=(0.14, sx * -0.26, sx * -0.18), parent=wing, u=14, v=10, subsurf=1)
        make_ellipsoid(f"LowerWingInnerLayer{side}", (0.115, 0.020, 0.165), m_wing_fringe,
                       loc=(sx * 0.22, -0.18, -0.20), rot=(0.14, sx * -0.24, sx * -0.16), parent=wing, u=12, v=8, subsurf=1)
        # Delicate S-curled lower wing tail sweeping cleanly from the hindwing tip
        tail_pts = [
            Vector((sx * 0.22, -0.21, -0.39)),
            Vector((sx * 0.26, -0.25, -0.49)),
            Vector((sx * 0.34, -0.28, -0.57)),
            Vector((sx * 0.40, -0.24, -0.62)),
            Vector((sx * 0.36, -0.19, -0.64)),
        ]
        make_tube_curve(f"WingTail{side}", tail_pts, [0.024, 0.018, 0.014, 0.011, 0.016], m_obi_cloth, parent=wing, segs=8)
        make_ellipsoid(f"WingTailGoldTip{side}", (0.024, 0.020, 0.024), m_gold,
                       loc=(sx * 0.36, -0.19, -0.64), parent=wing, u=10, v=8, subsurf=0)

    # Connected Kimono Sleeves & Sturdy Cuffed Legs
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        arm = make_empty(f"Arm{side}", loc=(sx * 0.22, 0.02, 0.34), parent=body)
        make_cyl(f"ArmSleeve{side}", 0.088, 0.064, 0.22, m_indigo, loc=(sx * 0.03, 0, -0.10), rot=(0, sx * 0.20, 0), parent=arm, segs=12, bevel=0.014)
        make_ellipsoid(f"Hand{side}", (0.052, 0.056, 0.052), m_mask, loc=(sx * 0.05, 0.02, -0.22), parent=arm)

        leg = make_empty(f"Leg{side}", loc=(sx * 0.125, 0.0, 0.34), parent=root)
        make_cyl(f"LegCol{side}", 0.076, 0.088, 0.24, m_indigo, loc=(0, 0, -0.12), parent=leg, segs=12, bevel=0.016)
        make_ellipsoid(f"BootCuff{side}", (0.084, 0.090, 0.042), m_plush_ruff, loc=(0, 0.01, -0.21), parent=leg)
        make_ellipsoid(f"Boot{side}", (0.084, 0.130, 0.074), m_boot, loc=(0, 0.040, -0.28), parent=leg)

    export_glb("vesper.glb")


if __name__ == "__main__":
    build_pip()
    build_koko()
    build_vesper()
    print("[gen_characters v4] All 3 AAA Astro Bot x Pixar-Plush characters generated successfully!")
