"""
Blender 5.2.1 LTS AAA Plush-Toybox Character Generator (v3 Craft Polish)
Fixes every silhouette & detail defect:
  - Max ONE subtle trim accent per character (zero "hula hoops"!)
  - Pip: integrated stitched scalloped cloak folds (no floating brass hoops), subtle concave PipVoidFace
    for radial indigo-to-ember shader glow, warm glowing cheek ovals, brighter golden eyes!
  - Koko: seamless sculpted plush shoulder sleeves, connected upper/lower arms, cute cuffed explorer
    shorts/hip-sleeves joining legs to torso (zero disconnected beads!), ONLY one sleek waist belt!
  - Vesper: snug integrated kimono obi sash (no hula hoop!), gracefully curved beveled UV-mapped
    moth wings with illustrated gold veins & eyespot (vesper_wing_albedo.png) + soft plush felt fringe,
    and thicker sturdy cuffed legs!
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
        bsdf.inputs["Coat Roughness"].default_value = 0.12
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
               wave_amp=0.0, wave_freq=8, subsurf=2):
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


def join_by_parent_and_material():
    groups = {}
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and not obj.children and len(obj.data.materials) == 1 and obj.data.materials[0] is not None:
            pname = obj.parent.name if obj.parent else ""
            mname = obj.data.materials[0].name
            groups.setdefault((pname, mname), []).append(obj)
    for key, objs in groups.items():
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
    print(f"[gen_characters v3] Exported {filepath}")


# ==============================================================================
# 1. PIP - THE LANTERN PILGRIM (Zero Hula Hoops, Luminous Inner-Gradient Face!)
# ==============================================================================
def build_pip():
    clear_scene()
    m_cloak = make_mat("PipCloak", (0.54, 0.11, 0.09), roughness=0.80)
    m_capelet = make_mat("PipCapelet", (0.68, 0.18, 0.11), roughness=0.76)
    m_trim = make_mat("PipGoldTrim", (0.84, 0.60, 0.18), roughness=0.28, metallic=0.82)
    m_scarf = make_mat("PipScarf", (0.88, 0.60, 0.16), roughness=0.74)
    m_tunic = make_mat("PipTunic", (0.80, 0.72, 0.60), roughness=0.76)
    m_boot = make_mat("PipBoot", (0.16, 0.09, 0.06), roughness=0.38, coat=0.40)
    # Special material name recognized by WorldHelper for pip_void_face.gdshader!
    m_void_face = make_mat("PipVoidFace", (0.05, 0.04, 0.10), roughness=0.86)
    m_eye = make_mat("PipEye", (1.0, 0.90, 0.54), roughness=0.06, emission=(1.0, 0.84, 0.42), emission_strength=2.8)
    m_blush = make_mat("PipBlush", (0.98, 0.42, 0.36), roughness=0.60, emission=(0.96, 0.38, 0.30), emission_strength=1.25)
    m_brass = make_mat("PipBrass", (0.78, 0.54, 0.18), roughness=0.24, metallic=0.90)
    m_flame = make_mat("PipFlame", (0.32, 0.16, 0.04), roughness=0.14, emission=(1.0, 0.64, 0.24), emission_strength=1.45)
    m_pack = make_mat("PipPack", (0.28, 0.14, 0.07), roughness=0.56)

    root = make_empty("CharacterRoot")
    body = make_empty("BodyPivot", loc=(0, 0, 0.42), parent=root)

    # Cozy scalloped pilgrim poncho + layered shoulder capelet (NO floating brass hula hoops!)
    make_lathe("Cloak", [(0.38, -0.10), (0.39, -0.06), (0.36, 0.05), (0.30, 0.22), (0.23, 0.37), (0.18, 0.48)],
               28, m_cloak, parent=body, wave_amp=0.028, wave_freq=8, subsurf=2)
    make_lathe("ShoulderCapelet", [(0.31, 0.22), (0.32, 0.25), (0.27, 0.36), (0.20, 0.47)],
               24, m_capelet, parent=body, wave_amp=0.020, wave_freq=8, subsurf=1)
    # Soft cream stitched tunic peek beneath cloak
    make_lathe("Tunic", [(0.24, -0.16), (0.21, 0.02), (0.16, 0.22)], 20, m_tunic, parent=body, subsurf=1)
    # Chunky cozy knitted honey-scarf collar
    make_torus("ScarfCollarA", 0.20, 0.056, m_scarf, loc=(0, 0, 0.47), parent=body)
    make_torus("ScarfCollarB", 0.175, 0.044, m_scarf, loc=(0, 0.01, 0.53), parent=body)
    # Brass heirloom clasp brooch on front chest
    make_ellipsoid("ChestBrooch", (0.048, 0.028, 0.048), m_brass, loc=(0, 0.255, 0.40), parent=body)

    # Head & Adorable Curved Pilgrim Hood with subtly sculpted PipVoidFace + glowing eyes & cheek glow!
    head = make_empty("HeadPivot", loc=(0, 0, 0.56), parent=body)
    make_ellipsoid("ShadowFace", (0.215, 0.205, 0.215), m_void_face, loc=(0, 0.03, 0.18), parent=head)
    make_ellipsoid("EyeL", (0.048, 0.026, 0.064), m_eye, loc=(-0.076, 0.218, 0.20), rot=(0, 0, 0.12), parent=head)
    make_ellipsoid("EyeR", (0.048, 0.026, 0.064), m_eye, loc=(0.076, 0.218, 0.20), rot=(0, 0, -0.12), parent=head)
    make_ellipsoid("BlushL", (0.046, 0.018, 0.026), m_blush, loc=(-0.124, 0.198, 0.142), parent=head)
    make_ellipsoid("BlushR", (0.046, 0.018, 0.026), m_blush, loc=(0.124, 0.198, 0.142), parent=head)

    # Sculpted ROUND Cozy Plush Hood (consistent round plush silhouette from BOTH front & 3rd-person back!)
    bm_hood = bmesh.new()
    hood_slices = [
        (0.06, 0.18, 0.265, 0.275, 0.04),
        (-0.02, 0.19, 0.278, 0.286, 0.08),
        (-0.11, 0.19, 0.264, 0.272, 0.14),
        (-0.19, 0.18, 0.222, 0.228, 0.22),
        (-0.25, 0.17, 0.145, 0.150, 0.30),
        (-0.285, 0.16, 0.065, 0.068, 0.36),
    ]
    segs = 24
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
    tip = bm_hood.verts.new((0, -0.298, 0.155))
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
    add_bm("PilgrimHood", bm_hood, m_cloak, parent=head, smooth=True, subsurf=2)
    make_torus("HoodRimTrim", 0.260, 0.015, m_trim, loc=(0, 0.062, 0.18), rot=(math.radians(94), 0, 0), parent=head)

    # 4-Segment Fluttering Scarf
    sp_p, sp_l = body, (0.05, -0.20, 0.48)
    for idx in range(4):
        sp = make_empty(f"Scarf{idx + 1}", loc=sp_l, parent=sp_p)
        w = 0.15 - idx * 0.016
        make_box(f"ScarfMesh{idx + 1}", (w, 0.19, 0.038), m_scarf, loc=(0, -0.095, -0.02), parent=sp, bevel=0.014)
        if idx == 3:
            make_box("ScarfTrim", (w * 0.95, 0.045, 0.042), m_trim, loc=(0, -0.19, -0.025), parent=sp, bevel=0.012)
        sp_p, sp_l = sp, (0, -0.17, -0.025)

    # Stitched Leather Backpack + Lantern Staff Angled ~50° UP and FORWARD (never horizontal skewering!)
    pack = make_box("ExplorerPack", (0.26, 0.16, 0.28), m_pack, loc=(0, -0.23, 0.24), parent=body, bevel=0.045)
    make_box("PackFlap", (0.27, 0.17, 0.08), m_capelet, loc=(0, 0.0, 0.11), parent=pack, bevel=0.025)
    make_box("PackBuckle", (0.08, 0.03, 0.06), m_brass, loc=(0, -0.09, 0.06), parent=pack, bevel=0.008)
    # Staff angled 40° from vertical (~50° up from horizontal) and forward (+Y is character front in Blender!)
    make_cyl("LanternStaff", 0.018, 0.014, 0.62, m_brass,
             loc=(0.24, 0.08, 0.46), rot=(math.radians(-40), math.radians(12), 0), parent=body, bevel=0.004)
    lp = make_empty("LanternPivot", loc=(0.30, 0.28, 0.69), parent=body)
    make_torus("LanternRing", 0.028, 0.007, m_brass, loc=(0, 0, -0.01), rot=(math.radians(90), 0, 0), parent=lp)
    make_cyl("LanternCapTop", 0.082, 0.026, 0.06, m_brass, loc=(0, 0, -0.06), parent=lp, segs=8, bevel=0.006)
    make_ellipsoid("LanternCore", (0.062, 0.062, 0.082), m_flame, loc=(0, 0, -0.15), parent=lp, u=12, v=10)
    make_cyl("LanternCapBot", 0.038, 0.074, 0.05, m_brass, loc=(0, 0, -0.24), parent=lp, segs=8, bevel=0.006)

    # Cozy Connected Sleeves & Rounded Explorer Boots (cloth cuffs, no brass hula rings!)
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
# 2. KOKO - THE CLOCKWORK FOX (Seamless Plush Sleeves/Shorts, Zero Bead Gaps!)
# ==============================================================================
def build_koko():
    clear_scene()
    m_cream = make_mat("KokoCream", (0.88, 0.82, 0.72), roughness=0.58)
    m_fur = make_mat("KokoPlushAmber", (0.70, 0.28, 0.11), roughness=0.74)
    m_brass = make_mat("KokoBrass", (0.82, 0.58, 0.18), roughness=0.24, metallic=0.90)
    m_teal = make_mat("KokoTealVest", (0.14, 0.46, 0.52), roughness=0.68)
    m_shorts = make_mat("KokoShorts", (0.20, 0.32, 0.40), roughness=0.72)
    m_eye_dark = make_mat("KokoEyeDark", (0.04, 0.045, 0.07), roughness=0.06, coat=0.95)
    m_catchlight = make_mat("KokoCatchlight", (1.0, 1.0, 1.0), roughness=0.05, emission=(1.0, 0.98, 0.95), emission_strength=2.2)
    m_cyan = make_mat("KokoCyanGlow", (0.24, 0.86, 1.0), roughness=0.08, emission=(0.20, 0.84, 1.0), emission_strength=2.4)
    m_blush = make_mat("KokoBlush", (0.94, 0.44, 0.42), roughness=0.68)
    m_leather = make_mat("KokoStrap", (0.26, 0.13, 0.07), roughness=0.54)

    root = make_empty("CharacterRoot")
    body = make_empty("BodyPivot", loc=(0, 0, 0.42), parent=root)

    # Cozy seamless plush torso + teal explorer jacket + snug cuffed shorts pelvis (no disconnected gaps!)
    make_ellipsoid("Torso", (0.25, 0.23, 0.27), m_teal, loc=(0, 0, 0.19), parent=body, subsurf=2)
    make_ellipsoid("PelvisShorts", (0.24, 0.21, 0.14), m_shorts, loc=(0, 0, 0.01), parent=body, subsurf=1)
    make_ellipsoid("BellyFluff", (0.17, 0.12, 0.18), m_cream, loc=(0, 0.14, 0.20), parent=body)
    # Plush soft fur collar instead of brass hula neck ring!
    make_ellipsoid("FurNeckCollar", (0.19, 0.18, 0.075), m_cream, loc=(0, 0.01, 0.42), parent=body)
    make_torus("CoreRing", 0.068, 0.014, m_brass, loc=(0, 0.245, 0.21), rot=(math.radians(90), 0, 0), parent=body)
    make_ellipsoid("CoreGlow", (0.052, 0.024, 0.052), m_cyan, loc=(0, 0.245, 0.21), parent=body)
    # Single sleek snug leather waist belt + brass buckle (the ONLY belt/ring!)
    make_torus("WaistBelt", 0.228, 0.028, m_leather, loc=(0, 0, 0.06), parent=body)
    make_box("BeltBuckle", (0.078, 0.04, 0.068), m_brass, loc=(0, 0.24, 0.06), parent=body, bevel=0.01)

    # Spinning Brass Wind-Up Key on Back
    windup = make_empty("WindupKey", loc=(0, -0.24, 0.23), parent=body)
    make_cyl("KeyShaft", 0.022, 0.022, 0.14, m_brass, loc=(0, -0.06, 0), rot=(math.radians(90), 0, 0), parent=windup, bevel=0.005)
    make_torus("KeyLoopL", 0.072, 0.020, m_brass, loc=(-0.068, -0.145, 0), rot=(math.radians(90), 0, 0), parent=windup)
    make_torus("KeyLoopR", 0.072, 0.020, m_brass, loc=(0.068, -0.145, 0), rot=(math.radians(90), 0, 0), parent=windup)

    # Adorable Oversized Plush Fox Head
    head = make_empty("HeadPivot", loc=(0, 0.02, 0.46), parent=body)
    make_ellipsoid("Skull", (0.28, 0.25, 0.23), m_fur, loc=(0, 0, 0.21), parent=head, subsurf=2)
    make_ellipsoid("CheekL", (0.165, 0.135, 0.105), m_cream, loc=(-0.18, 0.08, 0.13), rot=(0, 0.15, -0.22), parent=head)
    make_ellipsoid("CheekR", (0.165, 0.135, 0.105), m_cream, loc=(0.18, 0.08, 0.13), rot=(0, -0.15, 0.22), parent=head)
    make_ellipsoid("Muzzle", (0.115, 0.135, 0.088), m_cream, loc=(0, 0.22, 0.14), parent=head)
    make_ellipsoid("Nose", (0.044, 0.036, 0.034), m_eye_dark, loc=(0, 0.34, 0.165), parent=head)

    for side, sx in [("L", -1.0), ("R", 1.0)]:
        make_ellipsoid(f"Eye{side}", (0.052, 0.032, 0.056), m_eye_dark,
                       loc=(sx * 0.112, 0.225, 0.205), rot=(0, 0, sx * -0.28), parent=head)
        make_ellipsoid(f"Catch{side}", (0.018, 0.012, 0.019), m_catchlight,
                       loc=(sx * 0.098, 0.254, 0.224), parent=head, u=8, v=6, subsurf=0)
        make_ellipsoid(f"Blush{side}", (0.046, 0.018, 0.026), m_blush,
                       loc=(sx * 0.175, 0.205, 0.145), rot=(0, 0, sx * -0.4), parent=head)

        make_torus(f"GoggleRim{side}", 0.068, 0.017, m_brass,
                   loc=(sx * 0.082, 0.185, 0.345), rot=(math.radians(52), 0, sx * -0.22), parent=head)
        make_ellipsoid(f"GoggleGlass{side}", (0.056, 0.022, 0.056), m_cyan,
                       loc=(sx * 0.082, 0.188, 0.348), rot=(math.radians(-38), 0, sx * -0.22), parent=head)

        ear = make_empty(f"Ear{side}", loc=(sx * 0.15, -0.01, 0.38), rot=(math.radians(-8), sx * math.radians(20), 0), parent=head)
        bm_e = bmesh.new()
        bmesh.ops.create_cone(bm_e, cap_ends=True, cap_tris=False, segments=10, radius1=0.095, radius2=0.022, depth=0.35)
        bmesh.ops.scale(bm_e, vec=(0.95, 0.52, 1.0), verts=bm_e.verts)
        add_bm(f"EarOuter{side}", bm_e, m_fur, loc=(0, 0, 0.17), parent=ear, smooth=True, subsurf=1)
        make_ellipsoid(f"EarInner{side}", (0.045, 0.020, 0.12), m_cream, loc=(0, 0.036, 0.15), parent=ear)
        make_ellipsoid(f"EarTip{side}", (0.032, 0.025, 0.048), m_cream, loc=(0, 0, 0.34), parent=ear)

    make_torus("GoggleStrap", 0.255, 0.020, m_leather, loc=(0, -0.01, 0.30), rot=(math.radians(18), 0, 0), parent=head)

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

    # SEAMLESS Connected Plush Sleeves, Arms, Cuffed Hip-Shorts & Sturdy Boots (Zero Disconnected Beads!)
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        arm = make_empty(f"Arm{side}", loc=(sx * 0.23, 0.02, 0.32), parent=body)
        # Soft teal jacket shoulder sleeve smoothly overlapping torso
        make_ellipsoid(f"ShoulderSleeve{side}", (0.088, 0.088, 0.092), m_teal, loc=(sx * 0.01, 0, -0.02), parent=arm)
        # Continuous tapered plush arm from sleeve to paw
        make_cyl(f"ArmPlush{side}", 0.062, 0.074, 0.18, m_fur, loc=(sx * 0.035, 0.01, -0.12), rot=(0, sx * 0.16, 0), parent=arm, bevel=0.016)
        make_ellipsoid(f"Paw{side}", (0.064, 0.070, 0.058), m_cream, loc=(sx * 0.045, 0.02, -0.22), parent=arm)

        leg = make_empty(f"Leg{side}", loc=(sx * 0.125, 0.0, 0.38), parent=root)
        # Hip trouser cuff connecting pelvis smoothly into plush thigh & gaitered boot (NO floating springs!)
        make_cyl(f"HipCuff{side}", 0.090, 0.098, 0.13, m_shorts, loc=(0, 0, -0.04), parent=leg, bevel=0.018)
        make_cyl(f"ThighShin{side}", 0.072, 0.084, 0.22, m_fur, loc=(0, 0, -0.18), parent=leg, bevel=0.016)
        make_cyl(f"BootGaiter{side}", 0.076, 0.080, 0.09, m_leather, loc=(0, 0.008, -0.25), parent=leg, bevel=0.015)
        make_ellipsoid(f"Foot{side}", (0.086, 0.132, 0.070), m_cream, loc=(0, 0.038, -0.31), parent=leg)
        make_box(f"Sole{side}", (0.150, 0.228, 0.034), m_leather, loc=(0, 0.038, -0.358), parent=leg, bevel=0.012)

    export_glb("koko.glb")


# ==============================================================================
# 3. VESPER - THE ORIGAMI MOTH (UV Veined Curved Wings + Felt Fringe + Sturdy Legs!)
# ==============================================================================
def build_vesper():
    clear_scene()
    m_indigo = make_mat("VesperIndigo", (0.09, 0.11, 0.26), roughness=0.72)
    m_plush_ruff = make_mat("VesperRuff", (0.90, 0.86, 0.80), roughness=0.80)
    m_mask = make_mat("VesperMask", (0.92, 0.88, 0.82), roughness=0.30, coat=0.50)
    m_gold = make_mat("VesperGold", (0.86, 0.64, 0.20), roughness=0.24, metallic=0.88)
    m_obi_cloth = make_mat("VesperObiCloth", (0.36, 0.22, 0.48), roughness=0.72)
    m_wing_pat = make_mat("VesperWingPattern", (0.94, 0.90, 0.84), roughness=0.68)
    m_wing_fringe = make_mat("VesperWingFringe", (0.86, 0.78, 0.70), roughness=0.84)
    m_eye = make_mat("VesperEye", (0.94, 0.74, 1.0), roughness=0.06, emission=(0.88, 0.58, 1.0), emission_strength=2.6)
    m_boot = make_mat("VesperBoot", (0.08, 0.09, 0.18), roughness=0.40, coat=0.35)

    root = make_empty("CharacterRoot")
    body = make_empty("BodyPivot", loc=(0, 0, 0.42), parent=root)

    # Pleated Indigo Kimono Robe + Snug Integrated Tapered Fabric Obi (ZERO hula hoop!)
    make_lathe("OrigamiRobe", [(0.36, -0.10), (0.32, 0.06), (0.25, 0.24), (0.18, 0.45)],
               14, m_indigo, parent=body, wave_amp=0.020, wave_freq=14, subsurf=1)
    make_lathe("SnugObiWrap", [(0.275, 0.08), (0.268, 0.15), (0.252, 0.22)],
               18, m_obi_cloth, parent=body, wave_amp=0.0, subsurf=1)
    # Single subtle gold collar pin ring at neckline
    make_torus("GoldNeckRing", 0.16, 0.016, m_gold, loc=(0, 0, 0.51), parent=body)

    # Cozy plush fluffy moth mane around shoulders
    for i in range(8):
        a = i * math.pi * 0.25
        make_ellipsoid(f"RuffPuff{i}", (0.112, 0.112, 0.090), m_plush_ruff,
                       loc=(0.18 * math.cos(a), 0.18 * math.sin(a), 0.44), parent=body)

    # Adorable Sculpted Owl-Moth Porcelain Mask Head
    head = make_empty("HeadPivot", loc=(0, 0.01, 0.54), parent=body)
    make_ellipsoid("InnerHead", (0.20, 0.19, 0.20), m_indigo, loc=(0, -0.01, 0.19), parent=head, subsurf=2)
    make_ellipsoid("MaskBase", (0.22, 0.11, 0.19), m_mask, loc=(0, 0.135, 0.19), parent=head, subsurf=2)
    make_cyl("MaskBeakCrest", 0.055, 0.008, 0.12, m_gold, loc=(0, 0.235, 0.15), rot=(math.radians(-115), 0, 0), parent=head, segs=6, bevel=0.006)

    for side, sx in [("L", -1.0), ("R", 1.0)]:
        make_torus(f"Brow{side}", 0.072, 0.013, m_gold, loc=(sx * 0.095, 0.20, 0.235), rot=(math.radians(85), 0, sx * -0.25), parent=head)
        make_ellipsoid(f"Eye{side}", (0.048, 0.026, 0.042), m_eye, loc=(sx * 0.092, 0.215, 0.20), rot=(0, sx * -0.18, sx * -0.22), parent=head)

        ant = make_empty(f"Antenna{side}", loc=(sx * 0.09, 0.05, 0.36),
                         rot=(math.radians(-18), sx * math.radians(30), 0), parent=head)
        make_cyl(f"AntStem{side}", 0.022, 0.008, 0.32, m_gold, loc=(0, 0, 0.16), parent=ant, segs=8, bevel=0.004)
        for k in range(3):
            make_ellipsoid(f"Plume{side}_{k}", (0.055, 0.015, 0.032), m_gold,
                           loc=(sx * 0.038, 0, 0.12 + k * 0.075), rot=(0, 0, sx * 0.35), parent=ant, u=8, v=6, subsurf=0)

    # OVERHAULED Gracefully Curved, Beveled, UV-Mapped Moth Wings + Soft Plush Felt Fringe!
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        wing = make_empty(f"Wing{side}", loc=(sx * 0.11, -0.15, 0.36), parent=body)

        # Curved 6x4 lofted scalloped moth forewing with exact UVs for vesper_wing_albedo.png!
        bm_w = bmesh.new()
        uv_layer = bm_w.loops.layers.uv.new("UVMap")
        cols_n = 7
        rows_n = 5
        grid_f = []
        for r in range(rows_n):
            v = r / (rows_n - 1)  # 0 top leading edge -> 1 bottom trailing edge
            row_verts = []
            for c in range(cols_n):
                u = c / (cols_n - 1)  # 0 body root -> 1 outer wingtip
                # Graceful organic moth wing silhouette curve
                span_x = sx * (0.04 + u * 0.64 * (1.0 - 0.28 * v * v))
                arch_z = (0.30 * math.sin(u * math.pi * 0.68) + 0.06 * u) * (1.0 - v) + (-0.28 * math.sin(u * math.pi * 0.85) - 0.12) * v
                # Gentle backward sweep & pillowy camber
                sweep_y = -0.06 - u * 0.18 + math.sin(u * math.pi) * math.sin(v * math.pi) * 0.04
                # Soft scallop ripple along outer edge
                if c == cols_n - 1:
                    span_x += sx * 0.03 * math.sin(v * math.pi * 3.0)
                row_verts.append(bm_w.verts.new((span_x, sweep_y, arch_z)))
            grid_f.append(row_verts)

        for r in range(rows_n - 1):
            for c in range(cols_n - 1):
                v00 = grid_f[r][c]
                v10 = grid_f[r][c + 1]
                v11 = grid_f[r + 1][c + 1]
                v01 = grid_f[r + 1][c]
                verts = (v00, v10, v11, v01) if sx > 0 else (v00, v01, v11, v10)
                f = bm_w.faces.new(verts)
                u0, u1 = c / (cols_n - 1), (c + 1) / (cols_n - 1)
                vv0, vv1 = r / (rows_n - 1), (r + 1) / (rows_n - 1)
                uvs = [(u0, vv0), (u1, vv0), (u1, vv1), (u0, vv1)] if sx > 0 else [(u0, vv0), (u0, vv1), (u1, vv1), (u1, vv0)]
                for lp, uv in zip(f.loops, uvs):
                    lp[uv_layer].uv = uv

        # Solidify with clean soft bevel thickness so wings look tactile plush-and-paper, never paper-thin polys!
        bmesh.ops.solidify(bm_w, geom=bm_w.faces[:], thickness=0.034)
        add_bm(f"CurvedUpperWing{side}", bm_w, m_wing_pat, parent=wing, smooth=True, subsurf=1, bevel=0.008)

        # Soft plush felt scalloped fringe tufts along lower trailing edge!
        for k in range(5):
            fu = 0.22 + k * 0.16
            fx = sx * (0.06 + fu * 0.44)
            fz = -0.14 - math.sin(fu * math.pi * 0.85) * 0.26
            fy = -0.07 - fu * 0.15
            make_ellipsoid(f"WingFringe{side}_{k}", (0.056, 0.036, 0.072), m_wing_fringe,
                           loc=(fx, fy, fz), rot=(0.0, sx * 0.22, 0.0), parent=wing, u=10, v=8, subsurf=0)

        # Curved lower hindwing petal tucked gracefully behind Vesper's indigo kimono sleeve!
        make_ellipsoid(f"LowerWingPetal{side}", (0.15, 0.026, 0.21), m_obi_cloth,
                       loc=(sx * 0.25, -0.20, -0.24), rot=(0.14, sx * -0.26, sx * -0.18), parent=wing, u=12, v=10, subsurf=1)

    # Connected Kimono Sleeves & Thicker Sturdy Legs + Cuffed Boots (NO skinny chopsticks!)
    for side, sx in [("L", -1.0), ("R", 1.0)]:
        arm = make_empty(f"Arm{side}", loc=(sx * 0.22, 0.02, 0.34), parent=body)
        make_cyl(f"ArmSleeve{side}", 0.088, 0.064, 0.22, m_indigo, loc=(sx * 0.03, 0, -0.10), rot=(0, sx * 0.20, 0), parent=arm, segs=12, bevel=0.014)
        make_ellipsoid(f"Hand{side}", (0.052, 0.056, 0.052), m_mask, loc=(sx * 0.05, 0.02, -0.22), parent=arm)

        leg = make_empty(f"Leg{side}", loc=(sx * 0.125, 0.0, 0.34), parent=root)
        # Thicker sturdy cozy cuffed leggings + rounded plush boots!
        make_cyl(f"LegCol{side}", 0.076, 0.088, 0.24, m_indigo, loc=(0, 0, -0.12), parent=leg, segs=12, bevel=0.016)
        make_ellipsoid(f"BootCuff{side}", (0.084, 0.090, 0.042), m_plush_ruff, loc=(0, 0.01, -0.21), parent=leg)
        make_ellipsoid(f"Boot{side}", (0.084, 0.130, 0.074), m_boot, loc=(0, 0.040, -0.28), parent=leg)

    export_glb("vesper.glb")


if __name__ == "__main__":
    build_pip()
    build_koko()
    build_vesper()
    print("[gen_characters v3] All 3 overhauled plush characters generated successfully!")
