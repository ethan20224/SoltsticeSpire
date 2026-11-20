"""
Procedural AAA Stylized PBR Texture Suite Generator (runs inside Blender 5.2.1 NumPy Python)
Generates seamless tileable 512x512 Albedo + Tangent Normal + Roughness PNG maps for Godot 4.7 Forward+:
  1. stone_mosaic     - Warm carved travertine ashlar blocks with rich per-brick color variance & mortar relief
  2. terracotta_tile  - Glazed scalloped Tuscan/Ghibli clay tiles
  3. lush_moss        - Soft painterly Ghibli meadow moss & dappled clover turf (zero sandpaper mottling)
  4. wood_planks      - Warm Dalbit-Cafe cedar & walnut floorboards with beveled plank joints & wood grain
  5. hammered_brass   - True hammered peen-dimpled antique clockwork brass/copper with brushed sheen & patina
  6. veined_marble    - Cream Escher palace marble with delicate lavender-gold mineral veins
  7. washi_paper      - Handmade fibrous Japanese origami paper with delicate gold leaf specks
  8. obsidian_fluted  - Glossy volcanic stratosphere obsidian with fine gold mineral seams
  9. plush_felt       - Cozy tactile knitted/felted fleece micro-weave for adorable plush characters
 10. terrazzo_inlay   - Playful speckled artisan terrazzo stone inlay
 11. leaf_card_alpha  - Hand-painted RGBA stylized Ghibli botanical leaf-cluster silhouette card
 12. vesper_wing      - Illustrated ivory-gold veined moth wing with glowing cyan-lilac eyespot
"""

import os
import zlib
import struct
import math
import numpy as np

OUT_DIR = "/Users/ethanpeleg/Desktop/Dev/Parkour/assets/textures"
os.makedirs(OUT_DIR, exist_ok=True)
SZ = 512


def write_png(path, arr_u8):
    """Minimal zero-dependency fast PNG writer for Gray, RGB, or RGBA uint8 NumPy arrays."""
    h, w = arr_u8.shape[:2]
    if arr_u8.ndim == 2:
        color_type = 0
    elif arr_u8.shape[2] == 3:
        color_type = 2
    elif arr_u8.shape[2] == 4:
        color_type = 6
    else:
        raise ValueError(f"Unsupported PNG shape {arr_u8.shape}")
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # Filter None
        raw.extend(arr_u8[y].tobytes())
    comp = zlib.compress(bytes(raw), level=6)

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", w, h, 8, color_type, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", comp))
        f.write(chunk(b"IEND", b""))


def tileable_noise(res, period, seed=1):
    """Generates smooth seamless tileable value noise [0..1] at resolution `res` with `period` cells."""
    rng = np.random.default_rng(seed)
    grid = rng.random((period, period), dtype=np.float32)
    y = np.linspace(0, period, res, endpoint=False)
    x = np.linspace(0, period, res, endpoint=False)
    xi = np.floor(x).astype(np.int32)
    yi = np.floor(y).astype(np.int32)
    xf = x - xi
    yf = y - yi
    u = xf * xf * (3.0 - 2.0 * xf)
    v = yf * yf * (3.0 - 2.0 * yf)
    x0 = xi % period
    x1 = (xi + 1) % period
    y0 = yi % period
    y1 = (yi + 1) % period
    c00 = grid[np.ix_(y0, x0)]
    c10 = grid[np.ix_(y0, x1)]
    c01 = grid[np.ix_(y1, x0)]
    c11 = grid[np.ix_(y1, x1)]
    nx0 = c00 * (1.0 - u[None, :]) + c10 * u[None, :]
    nx1 = c01 * (1.0 - u[None, :]) + c11 * u[None, :]
    return nx0 * (1.0 - v[:, None]) + nx1 * v[:, None]


def fbm_tile(res, base_p=8, octaves=4, seed=1):
    acc = np.zeros((res, res), dtype=np.float32)
    amp = 0.5
    tot = 0.0
    p = base_p
    for i in range(octaves):
        acc += amp * tileable_noise(res, p, seed + i * 37)
        tot += amp
        amp *= 0.5
        p *= 2
    return acc / tot


def tileable_voronoi_dimples(res, cells=14, seed=77):
    """Seamless tileable hammered metal dimple distance field [0..1]."""
    rng = np.random.default_rng(seed)
    pts_x = (np.arange(cells)[None, :] + rng.uniform(0.15, 0.85, (cells, cells))) / cells
    pts_y = (np.arange(cells)[:, None] + rng.uniform(0.15, 0.85, (cells, cells))) / cells
    yy, xx = np.mgrid[0:res, 0:res].astype(np.float32) / res
    min_d2 = np.full((res, res), 10.0, dtype=np.float32)
    sec_d2 = np.full((res, res), 10.0, dtype=np.float32)
    cell_x = np.floor(xx * cells).astype(np.int32)
    cell_y = np.floor(yy * cells).astype(np.int32)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            nx = (cell_x + dx) % cells
            ny = (cell_y + dy) % cells
            px = pts_x[ny, nx]
            py = pts_y[ny, nx]
            ddx = xx - px
            ddy = yy - py
            ddx -= np.round(ddx)
            ddy -= np.round(ddy)
            d2 = (ddx * ddx + ddy * ddy) * (cells * cells)
            better = d2 < min_d2
            sec_d2 = np.where(better, min_d2, np.minimum(sec_d2, d2))
            min_d2 = np.where(better, d2, min_d2)
    f1 = np.sqrt(np.clip(min_d2, 0.0, 2.0))
    f2 = np.sqrt(np.clip(sec_d2, 0.0, 2.0))
    return np.clip(f1, 0.0, 1.0), np.clip(f2 - f1, 0.0, 1.0)


def height_to_normal(h, strength=3.2):
    """Converts seamless heightmap [0..1] to crisp tangent-space RGB normal map."""
    dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * strength
    dy = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * strength
    nz = np.ones_like(h)
    nx = -dx
    ny = -dy
    inv_l = 1.0 / np.sqrt(nx * nx + ny * ny + nz * nz + 1e-8)
    rgb = np.stack([
        (nx * inv_l * 0.5 + 0.5),
        (ny * inv_l * 0.5 + 0.5),
        (nz * inv_l * 0.5 + 0.5),
    ], axis=-1)
    return np.clip(rgb * 255.0, 0, 255).astype(np.uint8)


def save_pbr_set(name, albedo_f, height_f, rough_f, normal_strength=3.0):
    alb_u8 = np.clip(albedo_f * 255.0, 0, 255).astype(np.uint8)
    nrm_u8 = height_to_normal(height_f, strength=normal_strength)
    rgh_u8 = np.clip(rough_f * 255.0, 0, 255).astype(np.uint8)
    write_png(os.path.join(OUT_DIR, f"{name}_albedo.png"), alb_u8)
    write_png(os.path.join(OUT_DIR, f"{name}_normal.png"), nrm_u8)
    write_png(os.path.join(OUT_DIR, f"{name}_roughness.png"), rgh_u8)
    print(f"[gen_textures] Generated {name} PBR set (512x512)")


def make_leaf_card_alpha():
    """Hand-painted stylized Ghibli botanical leaf-cluster silhouette card (512x512 RGBA)."""
    res = 512
    yy, xx = np.mgrid[0:res, 0:res].astype(np.float32) / res
    u = xx * 2.0 - 1.0
    v = (1.0 - yy) * 2.0 - 1.0  # +v is up

    n_paint = fbm_tile(res, 10, 3, seed=211)
    rgb = np.zeros((res, res, 3), dtype=np.float32)
    alpha = np.zeros((res, res), dtype=np.float32)

    # 9 overlapping painterly botanical leaves forming a soft scalloped Ghibli foliage spray
    leaves = [
        # (cx, cy, ang_deg, len_a, wid_b, tone)
        (0.00, 0.36, 0.0, 0.44, 0.23, 0.92),
        (-0.34, 0.24, 34.0, 0.42, 0.22, 0.80),
        (0.34, 0.24, -34.0, 0.42, 0.22, 0.84),
        (-0.50, -0.06, 62.0, 0.40, 0.21, 0.65),
        (0.50, -0.06, -62.0, 0.40, 0.21, 0.70),
        (-0.26, -0.26, 44.0, 0.38, 0.22, 0.50),
        (0.26, -0.26, -44.0, 0.38, 0.22, 0.54),
        (0.00, 0.02, 4.0, 0.46, 0.26, 0.74),
        (0.00, -0.34, 0.0, 0.34, 0.22, 0.42),
    ]
    c_deep = np.array([0.11, 0.33, 0.14], dtype=np.float32)
    c_mid = np.array([0.22, 0.52, 0.19], dtype=np.float32)
    c_sun = np.array([0.46, 0.68, 0.24], dtype=np.float32)

    for cx, cy, ang_deg, la, wb, tone in leaves:
        rad = math.radians(ang_deg)
        ca, sa = math.cos(rad), math.sin(rad)
        dx = u - cx
        dy = v - cy
        lx = dx * ca + dy * sa
        ly = -dx * sa + dy * ca
        # Pointed botanical leaf profile
        taper = 1.0 - 0.32 * np.clip(ly / la, -1.0, 1.0)
        d = (lx / (wb * taper)) ** 2 + (ly / la) ** 2
        mask = np.clip((1.0 - d) * 10.0, 0.0, 1.0)
        tip_lit = np.clip((ly / la) * 0.5 + 0.5, 0.0, 1.0)
        vein = np.exp(-np.abs(lx) * 28.0) * 0.14
        col_base = c_deep * (1.0 - tone) + c_mid * tone
        col_leaf = col_base * (1.0 - tip_lit[:, :, None] * 0.45) + c_sun * (tip_lit[:, :, None] * 0.45)
        col_leaf *= (0.90 + n_paint[:, :, None] * 0.20 + vein[:, :, None])
        # Painterly front-to-back blend
        alpha_new = np.maximum(alpha, mask)
        rgb = np.where(mask[:, :, None] > 0.35, col_leaf, rgb)
        alpha = alpha_new

    rgba = np.concatenate([np.clip(rgb, 0.0, 1.0), np.clip(alpha[:, :, None], 0.0, 1.0)], axis=-1)
    write_png(os.path.join(OUT_DIR, "leaf_card_alpha.png"), (rgba * 255.0).astype(np.uint8))
    print("[gen_textures] Generated leaf_card_alpha.png (512x512 RGBA)")


def make_vesper_wing():
    """Delicate hand-illustrated origami-moth wing texture with gold veins, eyespot & felt fringe."""
    res = 512
    yy, xx = np.mgrid[0:res, 0:res].astype(np.float32) / res
    # xx: 0 at body root -> 1 at outer wingtip; yy: 0 at top leading edge -> 1 at bottom trailing fringe
    n_fib = fbm_tile(res, 16, 3, seed=313)
    c_ivory = np.array([0.95, 0.91, 0.84], dtype=np.float32)[None, None, :]
    c_lilac = np.array([0.66, 0.58, 0.82], dtype=np.float32)[None, None, :]
    c_indigo = np.array([0.16, 0.18, 0.36], dtype=np.float32)[None, None, :]
    c_gold = np.array([0.92, 0.72, 0.28], dtype=np.float32)[None, None, :]
    c_cyan = np.array([0.38, 0.86, 1.0], dtype=np.float32)[None, None, :]

    # Soft painterly gradient from ivory base to twilight-lilac wingtip
    tip_t = np.clip(xx * 0.85 + yy * 0.25 - 0.15, 0.0, 1.0)
    alb = c_ivory * (1.0 - tip_t[:, :, None] * 0.45) + c_lilac * (tip_t[:, :, None] * 0.45)
    alb *= (0.94 + n_fib[:, :, None] * 0.12)

    # Scalloped dark indigo outer border with delicate gold trim arc
    border_d = np.maximum(xx * 0.95, yy * 0.92) + np.sin(yy * 28.0) * 0.018 + np.sin(xx * 24.0) * 0.015
    border_mask = np.clip((border_d - 0.84) * 28.0, 0.0, 1.0)
    gold_piping = np.clip(1.0 - np.abs(border_d - 0.825) * 48.0, 0.0, 1.0)
    alb = alb * (1.0 - border_mask[:, :, None]) + c_indigo * border_mask[:, :, None]
    alb = alb * (1.0 - gold_piping[:, :, None]) + c_gold * gold_piping[:, :, None]

    # Delicate radial gold wing veins fanning from body root (0.05, 0.38)
    dx = xx - 0.04
    dy = yy - 0.36
    ang = np.arctan2(dy, np.maximum(dx, 0.001))
    vein_acc = np.zeros((res, res), dtype=np.float32)
    for va in (-0.42, -0.18, 0.05, 0.28, 0.52, 0.74):
        vein_acc = np.maximum(vein_acc, np.exp(-np.abs(ang - va) * 46.0))
    vein_mask = vein_acc * np.clip(1.0 - border_mask, 0.0, 1.0) * 0.72
    alb = alb * (1.0 - vein_mask[:, :, None]) + c_gold * vein_mask[:, :, None]

    # Luminous celestial moth eyespot at (0.56, 0.44)
    er = np.sqrt(((xx - 0.56) / 0.16) ** 2 + ((yy - 0.44) / 0.18) ** 2)
    ring_gold = np.clip(1.0 - np.abs(er - 0.92) * 14.0, 0.0, 1.0)
    ring_dark = np.clip((0.90 - er) * 18.0, 0.0, 1.0)
    core_cyan = np.clip((0.64 - er) * 16.0, 0.0, 1.0)
    spark = np.clip((0.24 - np.sqrt(((xx - 0.52) / 0.16) ** 2 + ((yy - 0.39) / 0.18) ** 2)) * 18.0, 0.0, 1.0)
    alb = alb * (1.0 - ring_dark[:, :, None]) + c_indigo * ring_dark[:, :, None]
    alb = alb * (1.0 - core_cyan[:, :, None]) + c_cyan * core_cyan[:, :, None]
    alb = alb * (1.0 - ring_gold[:, :, None]) + c_gold * ring_gold[:, :, None]
    alb = np.clip(alb + spark[:, :, None] * 0.65, 0.0, 1.0)

    write_png(os.path.join(OUT_DIR, "vesper_wing_albedo.png"), (alb * 255.0).astype(np.uint8))
    print("[gen_textures] Generated vesper_wing_albedo.png (512x512)")


def make_all():
    yy, xx = np.mgrid[0:SZ, 0:SZ].astype(np.float32) / SZ

    # 1. STONE MOSAIC (hand-laid Tuscan ashlar blocks with RICH per-brick warm color variance!)
    rows = 6
    cols = 4
    ry = yy * rows
    row_idx = np.floor(ry).astype(np.int32)
    rx = xx * cols + (row_idx % 2) * 0.5
    col_idx = np.floor(rx).astype(np.int32)
    fy = ry - np.floor(ry)
    fx = rx - np.floor(rx)
    grout_y = np.minimum(fy, 1.0 - fy)
    grout_x = np.minimum(fx, 1.0 - fx)
    edge = np.minimum(grout_x * 1.4, grout_y)
    bevel = np.clip((edge - 0.032) / 0.075, 0.0, 1.0)
    n_stone = fbm_tile(SZ, 10, 4, seed=11)
    n_chip = fbm_tile(SZ, 24, 3, seed=17)

    # Distinct warm artisan stone palette per brick (cream limestone, warm ochre, pale rose, soft sage-buff)
    palette = np.array([
        [0.88, 0.81, 0.69],
        [0.82, 0.71, 0.57],
        [0.86, 0.74, 0.64],
        [0.77, 0.72, 0.62],
        [0.90, 0.84, 0.74],
        [0.80, 0.66, 0.54],
    ], dtype=np.float32)
    brick_id = (row_idx * 7 + col_idx * 13) % len(palette)
    brick_rgb = palette[brick_id]
    b_hash = np.sin(row_idx * 12.9898 + col_idx * 78.233) * 43758.5453
    b_lum = 0.90 + (b_hash - np.floor(b_hash)) * 0.20

    h = bevel * (0.74 + (b_hash - np.floor(b_hash)) * 0.08) + n_stone * 0.18 + n_chip * 0.08
    grout_col = np.array([0.40, 0.35, 0.31], dtype=np.float32)[None, None, :]
    stone_c = brick_rgb * b_lum[:, :, None] * (0.91 + n_stone[:, :, None] * 0.18)
    alb = grout_col * (1.0 - bevel[:, :, None]) + stone_c * bevel[:, :, None]
    rgh = 0.58 + (1.0 - bevel) * 0.34 + (n_stone - 0.5) * 0.16
    save_pbr_set("stone_mosaic", alb, h, rgh, normal_strength=4.6)

    # 2. TERRACOTTA TILE (scalloped clay tiles with warm fired clay variation)
    tc_r, tc_c = 8, 8
    ty = yy * tc_r
    t_row = np.floor(ty).astype(np.int32)
    tx = xx * tc_c + (t_row % 2) * 0.5
    t_col = np.floor(tx).astype(np.int32)
    tfx = (tx - np.floor(tx)) * 2.0 - 1.0
    tfy = ty - np.floor(ty)
    arch_curve = np.sqrt(np.clip(1.0 - tfx * tfx * 0.85, 0.0, 1.0)) * 0.28
    scallop = np.clip((tfy + arch_curve - 0.12) * 3.5, 0.0, 1.0)
    n_clay = fbm_tile(SZ, 14, 4, seed=23)
    t_var = 0.88 + (((t_row * 5 + t_col * 11) % 7) / 6.0) * 0.24
    h = (1.0 - tfy * 0.55) * scallop * 0.75 + n_clay * 0.25
    c_clay = np.array([0.75, 0.35, 0.21], dtype=np.float32)[None, None, :]
    c_lip = np.array([0.44, 0.17, 0.10], dtype=np.float32)[None, None, :]
    alb = c_lip * (1.0 - scallop[:, :, None]) + c_clay * t_var[:, :, None] * (0.88 + n_clay[:, :, None] * 0.22) * scallop[:, :, None]
    rgh = 0.44 + (1.0 - scallop) * 0.30 + n_clay * 0.16
    save_pbr_set("terracotta_tile", alb, h, rgh, normal_strength=4.2)

    # 3. LUSH MOSS & PAINTED TURF (soft painterly Ghibli clover/moss strokes, ZERO sandpaper noise!)
    n_broad = fbm_tile(SZ, 6, 3, seed=31)
    n_med = fbm_tile(SZ, 14, 3, seed=39)
    # Soft brushstroke directional clover sweep (smooth low-medium freq, no high-freq grit!)
    sweep = np.sin((xx * 6.0 + yy * 4.0 + n_broad * 2.5) * math.pi) * 0.5 + 0.5
    c_deep = np.array([0.14, 0.38, 0.18], dtype=np.float32)[None, None, :]
    c_mid = np.array([0.26, 0.54, 0.22], dtype=np.float32)[None, None, :]
    c_sun = np.array([0.42, 0.66, 0.25], dtype=np.float32)[None, None, :]
    alb = c_deep * (1.0 - n_broad[:, :, None]) + c_mid * n_broad[:, :, None]
    sun_mask = np.clip((n_med * 0.65 + sweep * 0.35 - 0.42) * 2.2, 0.0, 1.0)[:, :, None]
    alb = alb * (1.0 - sun_mask * 0.55) + c_sun * (sun_mask * 0.55)
    # Gentle delicate wildflower clover dots (sparse soft blobs, not noisy static!)
    rng_f = np.random.default_rng(49)
    c_flw_w = np.array([0.96, 0.93, 0.78], dtype=np.float32)
    c_flw_y = np.array([0.96, 0.82, 0.34], dtype=np.float32)
    for i in range(42):
        fx0, fy0 = rng_f.uniform(0, SZ), rng_f.uniform(0, SZ)
        fr = rng_f.uniform(3.2, 5.8)
        y0, y1 = int(fy0 - 8), int(fy0 + 8)
        x0, x1 = int(fx0 - 8), int(fx0 + 8)
        ys = np.arange(y0, y1) % SZ
        xs = np.arange(x0, x1) % SZ
        d2 = ((np.arange(y0, y1) - fy0)[:, None] ** 2 + (np.arange(x0, x1) - fx0)[None, :] ** 2) / (fr * fr)
        fm = np.clip(1.0 - d2, 0.0, 1.0) ** 1.4
        fc = c_flw_y if i % 3 == 0 else c_flw_w
        alb[np.ix_(ys, xs)] = alb[np.ix_(ys, xs)] * (1.0 - fm[:, :, None] * 0.65) + fc[None, None, :] * (fm[:, :, None] * 0.65)
    h = n_broad * 0.65 + n_med * 0.35
    rgh = np.clip(0.86 + (0.5 - n_med) * 0.10, 0.80, 0.96)
    save_pbr_set("lush_moss", alb, h, rgh, normal_strength=1.5)

    # 4. WOOD PLANKS (cozy Dalbit-Cafe warm golden cedar floorboards with beveled seams & grain)
    planks = 8
    py = yy * planks
    p_idx = np.floor(py).astype(np.int32)
    pfy = py - np.floor(py)
    seam_y = np.clip((np.minimum(pfy, 1.0 - pfy) - 0.025) / 0.05, 0.0, 1.0)
    px = xx * 2.0 + (p_idx % 3) * 0.37
    pfx = px - np.floor(px)
    seam_x = np.clip((np.minimum(pfx, 1.0 - pfx) - 0.008) / 0.02, 0.0, 1.0)
    seam = np.minimum(seam_y, seam_x)
    n_grain = tileable_noise(SZ, 8, seed=55) * 0.55 + tileable_noise(SZ, 24, seed=59) * 0.45
    grain = np.sin((yy * 46.0 + n_grain * 1.4) * math.pi) * 0.5 + 0.5
    p_var = (np.sin(p_idx * 19.1) * 0.5 + 0.5) * 0.16 - 0.08
    c_w1 = np.array([0.56, 0.35, 0.20], dtype=np.float32)[None, None, :]
    c_w2 = np.array([0.42, 0.25, 0.14], dtype=np.float32)[None, None, :]
    c_seam = np.array([0.16, 0.09, 0.05], dtype=np.float32)[None, None, :]
    wood = (c_w2 * (1.0 - grain[:, :, None]) + c_w1 * grain[:, :, None]) * (1.0 + p_var[:, :, None])
    alb = c_seam * (1.0 - seam[:, :, None]) + wood * seam[:, :, None]
    h = seam * 0.94 + grain * 0.06
    rgh = 0.38 + (1.0 - seam) * 0.42 + (1.0 - grain) * 0.10
    save_pbr_set("wood_planks", alb, h, rgh, normal_strength=1.35)

    # 5. HAMMERED BRASS (TRUE peen-dimpled hammered clockwork brass/copper + aged verdigris-bronze patina!)
    dimple_f1, ridge_f = tileable_voronoi_dimples(SZ, cells=14, seed=67)
    n_pat = fbm_tile(SZ, 8, 4, seed=71)
    # Concave hammered cups (smooth dip in center of each Voronoi cell, crisp burnished rim between cells!)
    cup_h = np.clip(dimple_f1 * dimple_f1 * 0.85 + 0.15, 0.0, 1.0)
    brush = np.sin((xx * 180.0 + n_pat * 3.0)) * 0.04 + 0.96
    # Subtle antique verdigris/dark-bronze patina settling in low hammered pockets & patchy areas
    patina_mask = np.clip((1.0 - cup_h) * 0.72 + (n_pat - 0.56) * 1.4, 0.0, 1.0)
    patina_mask = np.clip((patina_mask - 0.42) * 2.2, 0.0, 0.72)

    c_br = np.array([0.90, 0.67, 0.28], dtype=np.float32)[None, None, :]
    c_cup = np.array([0.66, 0.44, 0.18], dtype=np.float32)[None, None, :]
    c_patina = np.array([0.24, 0.44, 0.38], dtype=np.float32)[None, None, :]  # subtle antique verdigris
    metal_col = (c_cup * (1.0 - cup_h[:, :, None]) + c_br * cup_h[:, :, None]) * brush[:, :, None]
    alb = metal_col * (1.0 - patina_mask[:, :, None] * 0.52) + c_patina * (patina_mask[:, :, None] * 0.52)
    h = cup_h * 0.82 + n_pat * 0.18
    rgh = np.clip(0.20 + (1.0 - cup_h) * 0.22 + patina_mask * 0.46, 0.16, 0.88)
    save_pbr_set("hammered_brass", alb, h, rgh, normal_strength=5.2)

    # 6. VEINED MARBLE (soft creamy alabaster-ivory marble with thin, low-contrast directional veins, ~24% opacity!)
    n_warp = fbm_tile(SZ, 4, 3, seed=81)
    n_det = fbm_tile(SZ, 12, 3, seed=85)
    # Directional diagonal veins (no closed orange topographic rings!)
    diag_coord = xx * 2.0 + yy * 1.0 + (n_warp - 0.5) * 0.55
    vein_a = np.exp(-np.abs(np.sin(diag_coord * math.pi)) * 18.0)
    diag_coord2 = xx * 1.0 - yy * 2.0 + (n_det - 0.5) * 0.40
    vein_b = np.exp(-np.abs(np.sin(diag_coord2 * math.pi)) * 26.0) * 0.55
    vein = np.clip(vein_a + vein_b, 0.0, 1.0) * 0.25  # Subtle ~25% opacity!
    c_mbase = np.array([0.96, 0.93, 0.94], dtype=np.float32)[None, None, :]
    c_mcloud = np.array([0.90, 0.86, 0.90], dtype=np.float32)[None, None, :]
    c_vgold = np.array([0.78, 0.73, 0.68], dtype=np.float32)[None, None, :]
    alb = c_mcloud * (1.0 - n_det[:, :, None]) + c_mbase * n_det[:, :, None]
    alb = alb * (1.0 - vein[:, :, None]) + c_vgold * vein[:, :, None]
    h = 0.78 + n_det * 0.08 - vein * 0.10
    rgh = 0.18 + vein * 0.12 + n_det * 0.08
    save_pbr_set("veined_marble", alb, h, rgh, normal_strength=1.1)

    # 7. WASHI PAPER (handmade Japanese origami fiber paper with warm sunlit gold leaf flecks)
    n_fib1 = fbm_tile(SZ, 20, 4, seed=91)
    n_fib2 = tileable_noise(SZ, 48, seed=97)
    fleck = np.clip((tileable_noise(SZ, 64, seed=103) - 0.90) * 10.0, 0.0, 1.0)
    c_p1 = np.array([0.95, 0.91, 0.82], dtype=np.float32)[None, None, :]
    c_p2 = np.array([0.86, 0.80, 0.70], dtype=np.float32)[None, None, :]
    c_fg = np.array([0.96, 0.76, 0.28], dtype=np.float32)[None, None, :]
    alb = c_p2 * (1.0 - n_fib1[:, :, None]) + c_p1 * n_fib1[:, :, None]
    alb = alb * (1.0 - fleck[:, :, None]) + c_fg * fleck[:, :, None]
    h = n_fib1 * 0.6 + n_fib2 * 0.4
    rgh = 0.64 - fleck * 0.40 + (n_fib2 - 0.5) * 0.10
    save_pbr_set("washi_paper", alb, h, rgh, normal_strength=2.2)

    # 8. OBSIDIAN FLUTED (glossy cosmic jet-indigo obsidian with luminous golden mineral cracks)
    n_obs = fbm_tile(SZ, 10, 4, seed=111)
    flute = np.sin(xx * 24.0 * 2.0 * math.pi) * 0.5 + 0.5
    crack_v = np.abs(np.sin((xx * 2.0 - yy * 3.0 + n_obs * 2.8) * math.pi))
    crack = np.power(1.0 - np.clip(crack_v, 0.0, 1.0), 15.0)
    c_o1 = np.array([0.09, 0.08, 0.16], dtype=np.float32)[None, None, :]
    c_o2 = np.array([0.16, 0.14, 0.25], dtype=np.float32)[None, None, :]
    c_og = np.array([0.96, 0.76, 0.28], dtype=np.float32)[None, None, :]
    alb = c_o1 * (1.0 - n_obs[:, :, None]) + c_o2 * n_obs[:, :, None]
    alb = alb * (1.0 - crack[:, :, None] * 0.86) + c_og * (crack[:, :, None] * 0.86)
    h = flute * 0.38 + n_obs * 0.42 - crack * 0.30
    rgh = 0.14 + (1.0 - flute) * 0.10 + n_obs * 0.08
    save_pbr_set("obsidian_fluted", alb, h, rgh, normal_strength=3.2)

    # 9. PLUSH FELT (cozy soft knitted wool/felt micro-weave for adorable plush heroes)
    weave = (np.sin(xx * 80.0 * math.pi) * np.sin(yy * 80.0 * math.pi)) * 0.5 + 0.5
    fuzz = fbm_tile(SZ, 24, 3, seed=121)
    h = weave * 0.45 + fuzz * 0.55
    alb = np.ones((SZ, SZ, 3), dtype=np.float32) * (0.90 + h[:, :, None] * 0.14)
    rgh = 0.80 + (1.0 - fuzz) * 0.14
    save_pbr_set("plush_felt", alb, h, rgh, normal_strength=2.0)

    # 10. TERRAZZO INLAY (playful warm cream stone inlaid with vibrant terracotta, sage, gold & cobalt chips)
    rng = np.random.default_rng(133)
    alb = np.ones((SZ, SZ, 3), dtype=np.float32) * np.array([0.88, 0.84, 0.76], dtype=np.float32)[None, None, :]
    n_t = fbm_tile(SZ, 12, 3, seed=139)
    alb *= (0.95 + n_t[:, :, None] * 0.10)
    h = 0.5 + n_t * 0.10
    rgh = np.full((SZ, SZ), 0.34, dtype=np.float32)
    chip_cols = [
        np.array([0.78, 0.34, 0.22], dtype=np.float32),
        np.array([0.22, 0.54, 0.46], dtype=np.float32),
        np.array([0.90, 0.68, 0.24], dtype=np.float32),
        np.array([0.28, 0.36, 0.58], dtype=np.float32),
        np.array([0.88, 0.52, 0.46], dtype=np.float32),
    ]
    for _ in range(180):
        cx, cy = rng.uniform(0, SZ), rng.uniform(0, SZ)
        rx, ry = rng.uniform(5, 16), rng.uniform(4, 13)
        ang = rng.uniform(0, math.pi)
        col = chip_cols[int(rng.integers(0, len(chip_cols)))]
        y0, y1 = int(cy - 20), int(cy + 20)
        x0, x1 = int(cx - 20), int(cx + 20)
        ys = np.arange(y0, y1) % SZ
        xs = np.arange(x0, x1) % SZ
        dy = (np.arange(y0, y1) - cy)[:, None]
        dx = (np.arange(x0, x1) - cx)[None, :]
        ca, sa = math.cos(ang), math.sin(ang)
        u = (dx * ca - dy * sa) / rx
        v = (dx * sa + dy * ca) / ry
        mask = (u * u + v * v) <= 1.0
        alb[np.ix_(ys, xs)] = np.where(mask[:, :, None], col[None, None, :], alb[np.ix_(ys, xs)])
        h[np.ix_(ys, xs)] = np.where(mask, 0.62, h[np.ix_(ys, xs)])
        rgh[np.ix_(ys, xs)] = np.where(mask, 0.20, rgh[np.ix_(ys, xs)])
    save_pbr_set("terrazzo_inlay", alb, h, rgh, normal_strength=2.2)

    # 11 & 12: Botanical leaf card alpha + Vesper illustrated moth wing
    make_leaf_card_alpha()
    make_vesper_wing()


if __name__ == "__main__":
    make_all()
    print("[gen_textures] Complete PBR texture library generated!")
