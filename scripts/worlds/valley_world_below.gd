extends Node3D
class_name ValleyWorldBelow
## Sunlit miniature living valley, winding cerulean river, terracotta riverfront city,
## arched stone bridges, forest groves, and snow-capped alpine mountain ring at Y = -205m.
## Engineered for <= 7 draw calls total with SHADOW_CASTING_SETTING_OFF (< 0.5ms GPU cost).

const GRID_RES: int = 74
const WORLD_SIZE: float = 2900.0
const HALF_SIZE: float = 1450.0
const VALLEY_BASE_Y: float = -205.0
const RIVER_SURFACE_Y: float = -210.5
const RIVER_BED_Y: float = -213.5
const RIVER_HALF_WIDTH: float = 26.0

var _terrain_mat: ShaderMaterial = null
var _river_mat: ShaderMaterial = null
var _building_mat: ShaderMaterial = null
var _landmark_mat: ShaderMaterial = null
var _tree_mat: ShaderMaterial = null
var _pedestal_mat: ShaderMaterial = null
var _lights_mat: ShaderMaterial = null
var _rekindled: bool = false


func _ready() -> void:
	if get_child_count() == 0:
		build()


func build() -> void:
	for ch in get_children():
		ch.queue_free()

	_create_materials()
	_build_terrain_and_mountain_ring()
	_build_cerulean_river()
	_build_spire_foundation_pedestal()
	_build_miniature_city_and_bridges()
	_build_forest_groves()
	update_atmosphere(0.0, Color(0.68, 0.82, 0.95), Color(1.0, 0.95, 0.84))


static func river_x(z: float) -> float:
	return sin(z * 0.0055) * 140.0 + 48.0


static func river_dx_dz(z: float) -> float:
	return cos(z * 0.0055) * 0.0055 * 140.0


static func get_terrain_y(x: float, z: float) -> float:
	var radial: float = sqrt(x * x + z * z)
	var r_center: float = river_x(z)
	var r_dist: float = absf(x - r_center)

	# Rolling sunlit emerald & golden-meadow hills (-205m .. -168m)
	var hill_w1: float = sin(x * 0.011 + 0.4) * cos(z * 0.011 - 0.3)
	var hill_w2: float = sin((x + z) * 0.018 + 1.2) * 0.55 + cos((x - z) * 0.015 - 0.7) * 0.45
	var hill_raw: float = clampf((hill_w1 * 0.55 + hill_w2 * 0.45) * 0.5 + 0.5, 0.0, 1.0)
	# Keep riverbanks & inner urban basin gently terraced, let outer valley hills roll up to -168m
	var urban_flat: float = smoothstep(140.0, 310.0, radial)
	var bank_clear: float = smoothstep(32.0, 95.0, r_dist)
	var hill_height: float = (4.5 + 32.5 * hill_raw * (0.28 + 0.72 * urban_flat)) * bank_clear

	var y: float = VALLEY_BASE_Y + hill_height

	# Winding river valley channel (half-width 26m, Y = -213.5m with warm sandy banks)
	var river_reach: float = 1.0 - smoothstep(460.0, 620.0, absf(z))
	if r_dist < 58.0 and river_reach > 0.001:
		var channel_t: float = smoothstep(RIVER_HALF_WIDTH * 0.55, 54.0, r_dist)
		var channel_y: float = lerpf(RIVER_BED_Y, y, channel_t)
		y = lerpf(y, channel_y, river_reach)

	# Grand encircling Mountain Range Ring (radial = 420m .. 1380m, seamless to horizon from 1,096m Summit!)
	if radial > 400.0:
		var m_env: float = smoothstep(410.0, 780.0, radial) * (1.0 - 0.35 * smoothstep(1150.0, 1440.0, radial))
		var ang: float = atan2(z, x)
		var ridge_a: float = 1.0 - absf(sin(ang * 7.0 + sin(radial * 0.012) * 1.4))
		var ridge_b: float = 1.0 - absf(cos(ang * 13.0 - cos(radial * 0.016) * 1.1))
		var ridge_c: float = 0.5 + 0.5 * sin(ang * 5.0 + 1.7)
		var peak_shape: float = pow(clampf(ridge_a * 0.54 + ridge_b * 0.30 + ridge_c * 0.16, 0.0, 1.0), 1.28)
		var mountain_rise: float = m_env * (74.0 + 164.0 * peak_shape)
		# Keep a dramatic river gorge pass where the river enters/exits the mountains
		var gorge_mask: float = 1.0 - 0.55 * (1.0 - smoothstep(28.0, 96.0, r_dist)) * (1.0 - smoothstep(440.0, 680.0, radial))
		y += mountain_rise * gorge_mask

	return y


func set_solstice_rekindled(active: bool) -> void:
	_rekindled = active


func update_atmosphere(altitude_m: float, haze_col: Color, sun_col: Color) -> void:
	var eff_haze := haze_col.lerp(Color(1.0, 0.84, 0.56), 0.36) if _rekindled else haze_col
	var eff_sun := sun_col.lerp(Color(1.0, 0.94, 0.72), 0.55) if _rekindled else sun_col
	var haze_boost: float = clampf(0.24 + smoothstep(0.0, 950.0, altitude_m) * 0.24, 0.20, 0.52)
	if _rekindled:
		haze_boost *= 0.78
	for mat in [_terrain_mat, _building_mat, _landmark_mat, _tree_mat, _pedestal_mat]:
		if mat != null:
			mat.set_shader_parameter("haze_color", eff_haze)
			mat.set_shader_parameter("sun_color", eff_sun)
			mat.set_shader_parameter("haze_strength", haze_boost)
	if _river_mat != null:
		_river_mat.set_shader_parameter("haze_color", eff_haze)
		_river_mat.set_shader_parameter("sun_color", eff_sun)
	if _lights_mat != null:
		# Morning glint 0.18 at 0m -> glittering twilight city constellation 1.0 past 320m -> blazing dawn 1.45 when rekindled!
		var glow: float = lerpf(0.18, 1.0, smoothstep(25.0, 340.0, altitude_m))
		if _rekindled:
			glow = maxf(glow, 1.45)
		_lights_mat.set_shader_parameter("glow_intensity", glow)


func _create_materials() -> void:
	var terrain_sh := Shader.new()
	terrain_sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec4 haze_color : source_color = vec4(0.68, 0.82, 0.95, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.95, 0.84, 1.0);
uniform vec3 sun_direction = vec3(0.42, 0.64, -0.64);
uniform float haze_strength = 0.28;

varying vec3 v_world_pos;
varying vec3 v_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_normal);
	vec3 sdir = normalize(sun_direction);
	float ndotl = clamp(dot(n, sdir), 0.0, 1.0);
	float sky_fill = clamp(n.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 lit = COLOR.rgb * (vec3(0.42, 0.48, 0.58) * sky_fill + sun_color.rgb * (0.28 + 0.68 * ndotl));

	float radial = length(v_world_pos.xz);
	float dist_haze = smoothstep(140.0, 920.0, radial);
	float valley_mist = (1.0 - smoothstep(-212.0, -145.0, v_world_pos.y)) * 0.22;
	float h_factor = clamp(dist_haze * (0.48 + haze_strength) + valley_mist + haze_strength * 0.35, 0.0, 0.84);
	ALBEDO = mix(lit, haze_color.rgb, h_factor);
}
"""
	_terrain_mat = ShaderMaterial.new()
	_terrain_mat.shader = terrain_sh

	_pedestal_mat = _terrain_mat.duplicate() as ShaderMaterial
	_tree_mat = _terrain_mat.duplicate() as ShaderMaterial

	var building_sh := Shader.new()
	building_sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec4 haze_color : source_color = vec4(0.68, 0.82, 0.95, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.95, 0.84, 1.0);
uniform vec3 sun_direction = vec3(0.42, 0.64, -0.64);
uniform float haze_strength = 0.26;

varying vec3 v_world_pos;
varying vec3 v_normal;
varying vec2 v_uv;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_uv = UV;
}

void fragment() {
	vec3 n = normalize(v_normal);
	vec3 sdir = normalize(sun_direction);
	float ndotl = clamp(dot(n, sdir), 0.0, 1.0);

	// UV.y > 0.5 encodes roof geometry; UV.y <= 0.5 encodes stucco facade with window bands
	vec3 terracotta = mix(vec3(0.78, 0.34, 0.22), vec3(0.32, 0.40, 0.50), step(0.75, COLOR.a));
	vec3 wall_col = COLOR.rgb;
	if (v_uv.y < 0.48 && abs(n.y) < 0.35) {
		float wx = step(0.32, fract(v_uv.x * 4.0));
		float wy = step(0.38, fract(v_uv.y * 8.0));
		float win_mask = wx * wy;
		wall_col = mix(wall_col * 0.48, wall_col, 1.0 - (1.0 - win_mask) * 0.55);
	}
	vec3 base_col = mix(wall_col, terracotta, step(0.5, v_uv.y));
	vec3 lit = base_col * (vec3(0.46, 0.50, 0.58) + sun_color.rgb * (0.30 + 0.64 * ndotl));

	float radial = length(v_world_pos.xz);
	float h_factor = clamp(smoothstep(160.0, 760.0, radial) * 0.55 + haze_strength * 0.38, 0.0, 0.78);
	ALBEDO = mix(lit, haze_color.rgb, h_factor);
}
"""
	_building_mat = ShaderMaterial.new()
	_building_mat.shader = building_sh
	_landmark_mat = _building_mat.duplicate() as ShaderMaterial

	var river_sh := Shader.new()
	river_sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 deep_color : source_color = vec4(0.08, 0.46, 0.68, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.24, 0.76, 0.82, 1.0);
uniform vec4 haze_color : source_color = vec4(0.68, 0.82, 0.95, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.95, 0.84, 1.0);

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float r_center = sin(v_world_pos.z * 0.0055) * 140.0 + 48.0;
	float r_dist = abs(v_world_pos.x - r_center);
	float bank_t = clamp(r_dist / 26.0, 0.0, 1.0);

	float flow = v_world_pos.z * 0.09 - TIME * 1.8;
	float ripple1 = sin(flow + sin(v_world_pos.x * 0.25 + TIME * 1.2) * 1.6);
	float ripple2 = cos(v_world_pos.z * 0.22 + v_world_pos.x * 0.35 - TIME * 2.4);
	float shimmer = smoothstep(0.52, 0.95, ripple1 * 0.55 + ripple2 * 0.45);

	vec3 water = mix(deep_color.rgb, shallow_color.rgb, smoothstep(0.25, 0.92, bank_t));
	float foam = smoothstep(0.76, 0.98, bank_t) * (0.55 + 0.45 * sin(v_world_pos.z * 0.25 - TIME * 2.2));
	water = mix(water, vec3(0.92, 0.98, 1.0), foam * 0.65);
	water += sun_color.rgb * shimmer * (0.28 + 0.22 * (1.0 - bank_t));

	float radial = length(v_world_pos.xz);
	float h_factor = clamp(smoothstep(180.0, 720.0, radial) * 0.58 + 0.14, 0.0, 0.78);
	ALBEDO = mix(water, haze_color.rgb, h_factor);
}
"""
	_river_mat = ShaderMaterial.new()
	_river_mat.shader = river_sh

	var lights_sh := Shader.new()
	lights_sh.code = """
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform float glow_intensity = 0.18;

void fragment() {
	ALBEDO = COLOR.rgb * (0.35 + glow_intensity * 1.85);
	ALPHA = clamp(COLOR.a * (0.22 + glow_intensity * 0.78), 0.0, 1.0);
}
"""
	_lights_mat = ShaderMaterial.new()
	_lights_mat.shader = lights_sh


func _build_terrain_and_mountain_ring() -> void:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var indices := PackedInt32Array()

	var row_len: int = GRID_RES + 1
	var step_sz: float = WORLD_SIZE / float(GRID_RES)
	verts.resize(row_len * row_len)
	norms.resize(row_len * row_len)
	cols.resize(row_len * row_len)

	for iz in range(row_len):
		var z: float = -HALF_SIZE + float(iz) * step_sz
		for ix in range(row_len):
			var x: float = -HALF_SIZE + float(ix) * step_sz
			var y: float = get_terrain_y(x, z)
			var idx: int = iz * row_len + ix
			verts[idx] = Vector3(x, y, z)

			# Finite-difference normal for crisp faceted alpine peaks & rolling hills
			var eps: float = 6.0
			var hx: float = get_terrain_y(x + eps, z) - get_terrain_y(x - eps, z)
			var hz: float = get_terrain_y(x, z + eps) - get_terrain_y(x, z - eps)
			var nrm := Vector3(-hx, 2.0 * eps, -hz).normalized()
			norms[idx] = nrm
			cols[idx] = _compute_terrain_vertex_color(x, y, z, nrm)

	indices.resize(GRID_RES * GRID_RES * 6)
	var ptr: int = 0
	for iz in range(GRID_RES):
		for ix in range(GRID_RES):
			var i00: int = iz * row_len + ix
			var i10: int = i00 + 1
			var i01: int = (iz + 1) * row_len + ix
			var i11: int = i01 + 1
			indices[ptr] = i00
			indices[ptr + 1] = i10
			indices[ptr + 2] = i01
			indices[ptr + 3] = i10
			indices[ptr + 4] = i11
			indices[ptr + 5] = i01
			ptr += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = indices

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.name = "ValleyTerrainAndMountains"
	mi.mesh = arr_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _terrain_mat
	add_child(mi)


func _compute_terrain_vertex_color(x: float, y: float, z: float, nrm: Vector3) -> Color:
	var radial: float = sqrt(x * x + z * z)
	var r_dist: float = absf(x - river_x(z))

	# Riverbed & warm sandy stone banks
	if radial < 560.0 and r_dist < 46.0:
		if r_dist < RIVER_HALF_WIDTH:
			return Color(0.16, 0.44, 0.52)
		var bank_blend: float = smoothstep(RIVER_HALF_WIDTH, 46.0, r_dist)
		var sand_col := Color(0.78, 0.70, 0.54)
		var meadow_edge := Color(0.34, 0.62, 0.30)
		return sand_col.lerp(meadow_edge, bank_blend)

	# Patchwork sunlit emerald & golden-meadow hills + warm stone urban district terraces
	var patch_a: float = sin(x * 0.016 + 0.5) * cos(z * 0.016 - 0.8) * 0.5 + 0.5
	var patch_b: float = sin((x - z) * 0.024 + 1.4) * 0.5 + 0.5
	var emerald := Color(0.24, 0.56, 0.28)
	var golden_meadow := Color(0.56, 0.68, 0.28)
	var orchard := Color(0.34, 0.62, 0.32)
	var valley_col: Color = emerald.lerp(golden_meadow, patch_a * 0.72).lerp(orchard, patch_b * 0.45)

	# Subtle warm cobblestone plaza tint inside the riverfront city districts
	if radial > 54.0 and radial < 305.0 and r_dist > 30.0 and r_dist < 175.0:
		var city_mask: float = (1.0 - smoothstep(230.0, 305.0, radial)) * (1.0 - smoothstep(125.0, 175.0, r_dist))
		valley_col = valley_col.lerp(Color(0.64, 0.58, 0.48), city_mask * 0.45)

	# Encircling Mountain Range Ring: pine lower slopes -> slate-blue granite cliffs -> snow-capped peaks
	if radial > 400.0 or y > -165.0:
		var m_blend: float = smoothstep(400.0, 490.0, radial)
		var pine_col := Color(0.15, 0.36, 0.24)
		var granite_col := Color(0.38, 0.45, 0.56)
		var snow_col := Color(0.97, 0.96, 0.93)

		var rock_t: float = smoothstep(-152.0, -95.0, y)
		var snow_t: float = smoothstep(-62.0, -14.0, y) * smoothstep(0.38, 0.72, nrm.y)
		var alpine_col: Color = pine_col.lerp(granite_col, rock_t).lerp(snow_col, snow_t)
		return valley_col.lerp(alpine_col, m_blend)

	return valley_col


func _build_cerulean_river() -> void:
	# Winding ribbon mesh along river_x(z) at Y = -210.5m (sits cleanly inside the -213.5m channel)
	var segs_z: int = 90
	var z_min: float = -560.0
	var z_max: float = 560.0
	var half_w: float = 34.0

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var indices := PackedInt32Array()
	verts.resize((segs_z + 1) * 2)
	norms.resize((segs_z + 1) * 2)
	indices.resize(segs_z * 6)

	for i in range(segs_z + 1):
		var z: float = lerpf(z_min, z_max, float(i) / float(segs_z))
		var rx: float = river_x(z)
		verts[i * 2] = Vector3(rx - half_w, RIVER_SURFACE_Y, z)
		verts[i * 2 + 1] = Vector3(rx + half_w, RIVER_SURFACE_Y, z)
		norms[i * 2] = Vector3.UP
		norms[i * 2 + 1] = Vector3.UP

	var ptr: int = 0
	for i in range(segs_z):
		var b: int = i * 2
		indices[ptr] = b
		indices[ptr + 1] = b + 1
		indices[ptr + 2] = b + 2
		indices[ptr + 3] = b + 1
		indices[ptr + 4] = b + 3
		indices[ptr + 5] = b + 2
		ptr += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = indices

	var r_mesh := ArrayMesh.new()
	r_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.name = "CeruleanRiver"
	mi.mesh = r_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _river_mat
	add_child(mi)


func _build_spire_foundation_pedestal() -> void:
	# Fluted stone-and-moss foundation column descending smoothly from inside the Spire core (r = 13.8m) to Y = -212m
	var sides: int = 20
	var rings: int = 10
	var y_top: float = -12.0
	var y_bot: float = -212.0

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var indices := PackedInt32Array()

	for ir in range(rings + 1):
		var v: float = float(ir) / float(rings)
		var y: float = lerpf(y_top, y_bot, v)
		var base_r: float = lerpf(13.8, 36.0, pow(v, 1.45))
		for iside in range(sides):
			var ang: float = (float(iside) / float(sides)) * TAU
			var flute: float = 1.0 + 0.08 * cos(ang * 8.0) + 0.05 * pow(v, 1.2) * cos(ang * 4.0)
			var r: float = base_r * flute
			var x: float = cos(ang) * r
			var z: float = sin(ang) * r
			verts.append(Vector3(x, y, z))
			norms.append(Vector3(cos(ang), 0.18, sin(ang)).normalized())
			var stone_col := Color(0.54, 0.50, 0.44)
			var moss_col := Color(0.24, 0.46, 0.28)
			var moss_t: float = clampf(v * 0.72 + (0.5 + 0.5 * sin(ang * 4.0 + v * 6.0)) * 0.28, 0.0, 1.0)
			cols.append(stone_col.lerp(moss_col, moss_t * 0.76))

	for ir in range(rings):
		for iside in range(sides):
			var next_s: int = (iside + 1) % sides
			var i00: int = ir * sides + iside
			var i10: int = ir * sides + next_s
			var i01: int = (ir + 1) * sides + iside
			var i11: int = (ir + 1) * sides + next_s
			indices.append(i00)
			indices.append(i01)
			indices.append(i10)
			indices.append(i10)
			indices.append(i01)
			indices.append(i11)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = indices

	var p_mesh := ArrayMesh.new()
	p_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.name = "SpireFoundationPedestal"
	mi.mesh = p_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _pedestal_mat
	add_child(mi)


func _build_miniature_city_and_bridges() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261121

	var house_xf: Array[Transform3D] = []
	var house_cols: Array[Color] = []
	var landmark_xf: Array[Transform3D] = []
	var landmark_cols: Array[Color] = []
	var light_xf: Array[Transform3D] = []
	var light_cols: Array[Color] = []

	var stucco_palette: Array[Color] = [
		Color(0.95, 0.89, 0.78, 0.2), # Warm cream stucco + terracotta roof
		Color(0.92, 0.82, 0.66, 0.2), # Sunlit ochre sandstone + terracotta roof
		Color(0.88, 0.76, 0.62, 0.2), # Honey limestone + terracotta roof
		Color(0.90, 0.86, 0.82, 0.9), # Pale stone + slate roof
		Color(0.86, 0.72, 0.58, 0.2), # Siena plaster + terracotta roof
	]

	# 1. 4 Arched Stone Bridges spanning the winding river
	var bridge_z_list: Array[float] = [-215.0, -78.0, 82.0, 220.0]
	for bz in bridge_z_list:
		var rx: float = river_x(bz)
		var dxdz: float = river_dx_dz(bz)
		var river_yaw: float = atan2(dxdz, 1.0)
		var by: float = VALLEY_BASE_Y - 1.5
		var b_basis := Basis(Vector3.UP, river_yaw).scaled(Vector3(58.0, 6.5, 9.5))
		landmark_xf.append(Transform3D(b_basis, Vector3(rx, by, bz)))
		landmark_cols.append(Color(0.84, 0.78, 0.68, 0.9))
		# Bridge lantern pairs along the span
		for s in range(-3, 4):
			var span_off: float = float(s) * 8.2
			var lx: float = rx + cos(river_yaw) * span_off
			var lz: float = bz - sin(river_yaw) * span_off
			var l_basis := Basis.IDENTITY.scaled(Vector3(2.2, 2.2, 2.2))
			light_xf.append(Transform3D(l_basis, Vector3(lx, by + 6.8, lz)))
			light_cols.append(Color(1.0, 0.84, 0.44, 0.95))

	# 2. Curved avenue blocks & riverfront districts along both riverbanks (radial = 54m .. 340m)
	var radii: Array[float] = [62.0, 80.0, 100.0, 122.0, 145.0, 170.0, 196.0, 224.0, 254.0, 286.0, 320.0]
	for r_idx in range(radii.size()):
		var rad: float = radii[r_idx]
		var circum: float = TAU * rad
		var slot_step: float = 15.5 + float(r_idx) * 0.45
		var steps: int = int(floor(circum / slot_step))
		for s in range(steps):
			# Leave periodic radial avenue boulevards clear
			if s % 9 == 0:
				continue
			var ang: float = (float(s) / float(steps)) * TAU + float(r_idx) * 0.17
			var x: float = cos(ang) * rad + rng.randf_range(-2.2, 2.2)
			var z: float = sin(ang) * rad + rng.randf_range(-2.2, 2.2)
			var r_center: float = river_x(z)
			var r_dist: float = absf(x - r_center)

			# Stay outside river channel (34m) and cluster within 230m of the river corridor
			if r_dist < 33.5 or r_dist > 235.0:
				continue
			if house_xf.size() >= 430:
				break

			var ty: float = get_terrain_y(x, z)
			# Align riverfront rows parallel to the river, outer districts tangent to curved avenues
			var yaw: float = atan2(river_dx_dz(z), 1.0) if r_dist < 62.0 else (ang + PI * 0.5)
			yaw += rng.randf_range(-0.12, 0.12)

			# Place ~36 tall clocktowers & civic domes at major avenue corners & riverfront plazas
			var is_landmark_corner: bool = (s % 9 == 1 or (r_dist < 46.0 and s % 7 == 0)) and landmark_xf.size() < 40
			if is_landmark_corner:
				var tw: float = rng.randf_range(6.8, 9.5)
				var th: float = rng.randf_range(18.5, 29.0)
				var td: float = rng.randf_range(6.8, 9.5)
				var l_basis := Basis(Vector3.UP, yaw).scaled(Vector3(tw, th, td))
				landmark_xf.append(Transform3D(l_basis, Vector3(x, ty - 1.2, z)))
				landmark_cols.append(Color(0.94, 0.86, 0.74, 0.2 if rng.randf() < 0.65 else 0.9))

				# Clocktower lantern beacon at top
				var b_sc := Basis.IDENTITY.scaled(Vector3(3.0, 3.0, 3.0))
				light_xf.append(Transform3D(b_sc, Vector3(x, ty + th * 0.88, z)))
				light_cols.append(Color(1.0, 0.88, 0.52, 1.0))
			else:
				var bw: float = rng.randf_range(6.2, 11.8)
				var bh: float = rng.randf_range(6.5, 14.2) * (1.12 if r_dist < 85.0 else 0.92)
				var bd: float = rng.randf_range(5.8, 10.2)
				var h_basis := Basis(Vector3.UP, yaw).scaled(Vector3(bw, bh, bd))
				house_xf.append(Transform3D(h_basis, Vector3(x, ty - 1.0, z)))
				var pal_col: Color = stucco_palette[rng.randi_range(0, stucco_palette.size() - 1)]
				var shade: float = rng.randf_range(0.92, 1.06)
				house_cols.append(Color(pal_col.r * shade, pal_col.g * shade, pal_col.b * shade, pal_col.a))

				# Warm streetlamp & glowing window specks along avenues and riverfront quays
				if light_xf.size() < 385 and (r_dist < 54.0 or rng.randf() < 0.78):
					var lamp_off := Vector3(cos(yaw) * (bw * 0.58), bh * rng.randf_range(0.45, 0.75), sin(yaw) * (bd * 0.58))
					var l_sc: float = rng.randf_range(1.6, 2.5)
					light_xf.append(Transform3D(Basis.IDENTITY.scaled(Vector3(l_sc, l_sc, l_sc)), Vector3(x, ty, z) + lamp_off))
					var warm_gold := Color(1.0, rng.randf_range(0.76, 0.90), rng.randf_range(0.36, 0.56), rng.randf_range(0.80, 1.0))
					light_cols.append(warm_gold)

	# Batch 1: Townhouses & Urban Blocks MultiMeshInstance3D
	var mm_houses := MultiMesh.new()
	mm_houses.transform_format = MultiMesh.TRANSFORM_3D
	mm_houses.use_colors = true
	mm_houses.mesh = _create_townhouse_mesh()
	mm_houses.instance_count = house_xf.size()
	for i in range(house_xf.size()):
		mm_houses.set_instance_transform(i, house_xf[i])
		mm_houses.set_instance_color(i, house_cols[i])

	var mmi_houses := MultiMeshInstance3D.new()
	mmi_houses.name = "CityTownhousesBatch"
	mmi_houses.multimesh = mm_houses
	mmi_houses.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi_houses.material_override = _building_mat
	add_child(mmi_houses)

	# Batch 2: Clocktowers, Civic Domes & 4 Arched Bridges MultiMeshInstance3D
	var mm_landmarks := MultiMesh.new()
	mm_landmarks.transform_format = MultiMesh.TRANSFORM_3D
	mm_landmarks.use_colors = true
	mm_landmarks.mesh = _create_townhouse_mesh()
	mm_landmarks.instance_count = landmark_xf.size()
	for i in range(landmark_xf.size()):
		mm_landmarks.set_instance_transform(i, landmark_xf[i])
		mm_landmarks.set_instance_color(i, landmark_cols[i])

	var mmi_landmarks := MultiMeshInstance3D.new()
	mmi_landmarks.name = "CityLandmarksAndBridgesBatch"
	mmi_landmarks.multimesh = mm_landmarks
	mmi_landmarks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi_landmarks.material_override = _landmark_mat
	add_child(mmi_landmarks)

	# Batch 3: Warm Golden City Streetlights & Window Specks MultiMeshInstance3D
	var mm_lights := MultiMesh.new()
	mm_lights.transform_format = MultiMesh.TRANSFORM_3D
	mm_lights.use_colors = true
	var light_box := BoxMesh.new()
	light_box.size = Vector3(1.0, 1.0, 1.0)
	mm_lights.mesh = light_box
	mm_lights.instance_count = light_xf.size()
	for i in range(light_xf.size()):
		mm_lights.set_instance_transform(i, light_xf[i])
		mm_lights.set_instance_color(i, light_cols[i])

	var mmi_lights := MultiMeshInstance3D.new()
	mmi_lights.name = "CityGoldenLightsBatch"
	mmi_lights.multimesh = mm_lights
	mmi_lights.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi_lights.material_override = _lights_mat
	add_child(mmi_lights)


func _build_forest_groves() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261122

	var tree_xf: Array[Transform3D] = []
	var tree_cols: Array[Color] = []
	var foliage_palette: Array[Color] = [
		Color(0.18, 0.48, 0.24, 1.0),
		Color(0.24, 0.54, 0.26, 1.0),
		Color(0.32, 0.58, 0.24, 1.0),
		Color(0.14, 0.38, 0.22, 1.0),
		Color(0.46, 0.58, 0.22, 1.0),
	]

	var attempts: int = 0
	while tree_xf.size() < 600 and attempts < 2400:
		attempts += 1
		var rad: float = rng.randf_range(58.0, 620.0)
		var ang: float = rng.randf_range(0.0, TAU)
		var x: float = cos(ang) * rad
		var z: float = sin(ang) * rad
		var r_dist: float = absf(x - river_x(z))

		# Avoid river channel and dense inner city blocks (leave riverside parks & outer hills lush)
		if r_dist < 35.0:
			continue
		if rad < 275.0 and r_dist < 185.0 and rng.randf() < 0.82:
			continue

		var ty: float = get_terrain_y(x, z)
		if ty > -48.0:
			continue

		var sc_xz: float = rng.randf_range(3.6, 7.2)
		var sc_y: float = rng.randf_range(6.5, 13.5)
		var yaw: float = rng.randf_range(0.0, TAU)
		var t_basis := Basis(Vector3.UP, yaw).scaled(Vector3(sc_xz, sc_y, sc_xz))
		tree_xf.append(Transform3D(t_basis, Vector3(x, ty - 0.5, z)))
		var col: Color = foliage_palette[rng.randi_range(0, foliage_palette.size() - 1)]
		if rad > 410.0:
			col = col.lerp(Color(0.12, 0.32, 0.22, 1.0), 0.55)
		tree_cols.append(col)

	var mm_trees := MultiMesh.new()
	mm_trees.transform_format = MultiMesh.TRANSFORM_3D
	mm_trees.use_colors = true
	mm_trees.mesh = _create_stylized_tree_mesh()
	mm_trees.instance_count = tree_xf.size()
	for i in range(tree_xf.size()):
		mm_trees.set_instance_transform(i, tree_xf[i])
		mm_trees.set_instance_color(i, tree_cols[i])

	var mmi_trees := MultiMeshInstance3D.new()
	mmi_trees.name = "ValleyForestGrovesBatch"
	mmi_trees.multimesh = mm_trees
	mmi_trees.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi_trees.material_override = _tree_mat
	add_child(mmi_trees)


func _create_townhouse_mesh() -> ArrayMesh:
	# Unit townhouse: walls from Y = 0..0.72 (UV.y in 0..0.45), pitched gable roof Y = 0.72..1.05 (UV.y = 0.75)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var w: float = 0.5
	var d: float = 0.5
	var h_wall: float = 0.72
	var h_roof: float = 1.05
	var r_over: float = 0.55

	# 4 Stucco Walls (UV.y in 0.05..0.44 for window band shader)
	_add_quad(st, Vector3(-w, 0.0, d), Vector3(w, 0.0, d), Vector3(w, h_wall, d), Vector3(-w, h_wall, d), Vector3(0, 0, 1), Vector2(0.0, 0.05), Vector2(1.0, 0.44))
	_add_quad(st, Vector3(w, 0.0, -d), Vector3(-w, 0.0, -d), Vector3(-w, h_wall, -d), Vector3(w, h_wall, -d), Vector3(0, 0, -1), Vector2(0.0, 0.05), Vector2(1.0, 0.44))
	_add_quad(st, Vector3(w, 0.0, d), Vector3(w, 0.0, -d), Vector3(w, h_wall, -d), Vector3(w, h_wall, d), Vector3(1, 0, 0), Vector2(0.0, 0.05), Vector2(1.0, 0.44))
	_add_quad(st, Vector3(-w, 0.0, -d), Vector3(-w, 0.0, d), Vector3(-w, h_wall, d), Vector3(-w, h_wall, -d), Vector3(-1, 0, 0), Vector2(0.0, 0.05), Vector2(1.0, 0.44))

	# Pitched Terracotta/Slate Roof Slopes (UV.y = 0.75 so shader renders roof tint)
	var n_east := Vector3(0.55, 0.83, 0.0).normalized()
	var n_west := Vector3(-0.55, 0.83, 0.0).normalized()
	_add_quad(st, Vector3(r_over, h_wall, r_over), Vector3(r_over, h_wall, -r_over), Vector3(0.0, h_roof, -r_over), Vector3(0.0, h_roof, r_over), n_east, Vector2(0.0, 0.75), Vector2(1.0, 0.85))
	_add_quad(st, Vector3(-r_over, h_wall, -r_over), Vector3(-r_over, h_wall, r_over), Vector3(0.0, h_roof, r_over), Vector3(0.0, h_roof, -r_over), n_west, Vector2(0.0, 0.75), Vector2(1.0, 0.85))

	# Front & Back Roof Gables
	_add_tri(st, Vector3(-r_over, h_wall, r_over), Vector3(r_over, h_wall, r_over), Vector3(0.0, h_roof, r_over), Vector3(0, 0.2, 0.98).normalized(), Vector2(0.5, 0.75))
	_add_tri(st, Vector3(r_over, h_wall, -r_over), Vector3(-r_over, h_wall, -r_over), Vector3(0.0, h_roof, -r_over), Vector3(0, 0.2, -0.98).normalized(), Vector2(0.5, 0.75))

	return st.commit()


func _create_stylized_tree_mesh() -> ArrayMesh:
	# Low-poly 6-sided two-tier stylized alpine/deciduous tree crown
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides: int = 6
	var tiers: Array[Dictionary] = [
		{"y0": 0.15, "y1": 0.68, "r": 0.52},
		{"y0": 0.46, "y1": 1.00, "r": 0.38},
	]
	for t in tiers:
		var y0: float = float(t["y0"])
		var y1: float = float(t["y1"])
		var r: float = float(t["r"])
		var apex := Vector3(0.0, y1, 0.0)
		for i in range(sides):
			var a0: float = (float(i) / float(sides)) * TAU
			var a1: float = (float(i + 1) / float(sides)) * TAU
			var p0 := Vector3(cos(a0) * r, y0, sin(a0) * r)
			var p1 := Vector3(cos(a1) * r, y0, sin(a1) * r)
			var mid_a: float = (a0 + a1) * 0.5
			var nrm := Vector3(cos(mid_a) * 0.75, 0.66, sin(mid_a) * 0.75).normalized()
			_add_tri(st, p0, apex, p1, nrm, Vector2(0.5, 0.5))
	return st.commit()


func _add_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, nrm: Vector3, uv0: Vector2, uv1: Vector2) -> void:
	st.set_normal(nrm)
	st.set_uv(uv0)
	st.add_vertex(p0)
	st.set_normal(nrm)
	st.set_uv(Vector2(uv1.x, uv0.y))
	st.add_vertex(p1)
	st.set_normal(nrm)
	st.set_uv(uv1)
	st.add_vertex(p2)

	st.set_normal(nrm)
	st.set_uv(uv0)
	st.add_vertex(p0)
	st.set_normal(nrm)
	st.set_uv(uv1)
	st.add_vertex(p2)
	st.set_normal(nrm)
	st.set_uv(Vector2(uv0.x, uv1.y))
	st.add_vertex(p3)


func _add_tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, nrm: Vector3, uv: Vector2) -> void:
	st.set_normal(nrm)
	st.set_uv(uv)
	st.add_vertex(p0)
	st.set_normal(nrm)
	st.set_uv(uv)
	st.add_vertex(p1)
	st.set_normal(nrm)
	st.set_uv(uv)
	st.add_vertex(p2)
