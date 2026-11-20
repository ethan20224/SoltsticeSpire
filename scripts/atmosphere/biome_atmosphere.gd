extends Node3D
class_name BiomeAtmosphere
## Altitude-driven Atmosphere, Sky, Sun, Volumetric Fog & Cloud Sea Conductor.
## Smoothly morphs the entire visual mood across all 6 surreal ascending worlds.

@export var world_environment: WorldEnvironment
@export var sun_light: DirectionalLight3D
@export var cloud_sea_mesh: MeshInstance3D
@export var ambient_particles: GPUParticles3D

var _sky_mat: ShaderMaterial
var _cloud_mat: ShaderMaterial
var _current_y: float = 0.0

# Curated AAA-indie color palettes anchored at each world's midpoint altitude
# Tuned for sculpted shadow depth (~18% lower ambient) + volumetric god-ray haze + warm practical contrast!
const BIOME_PALETTES := [
	# 0: Sunken Conservatory - Astro Bot Vivid Cerulean-Turquoise Sky & Golden Little Prince Horizon
	{
		"y": 40.0,
		"zenith": Color(0.06, 0.32, 0.74),
		"mid_sky": Color(0.18, 0.62, 0.92),
		"horizon": Color(0.98, 0.88, 0.64),
		"abyss": Color(0.56, 0.72, 0.88),
		"sun_col": Color(1.0, 0.94, 0.76),
		"sun_energy": 1.55,
		"sun_rot": Vector3(-36.0, 34.0, 0.0),
		"fog_col": Color(0.64, 0.80, 0.94),
		"fog_density": 0.00075,
		"vol_fog_density": 0.0018,
		"ambient_col": Color(0.30, 0.50, 0.76),
		"ambient_energy": 0.40,
		"cloud_crest": Color(1.0, 0.97, 0.90),
		"cloud_valley": Color(0.54, 0.68, 0.88),
		"cloud_cov": 0.46,
		"stars": 0.0,
		"aurora": 0.0,
		"glow": 0.32,
	},
	# 1: Foundry of Floating Bells - Molten Bronze & Burnished Amber Sunset Drama
	{
		"y": 240.0,
		"zenith": Color(0.12, 0.14, 0.38),
		"mid_sky": Color(0.58, 0.26, 0.32),
		"horizon": Color(1.0, 0.58, 0.22),
		"abyss": Color(0.42, 0.24, 0.30),
		"sun_col": Color(1.0, 0.76, 0.38),
		"sun_energy": 1.50,
		"sun_rot": Vector3(-22.0, 56.0, 0.0),
		"fog_col": Color(0.76, 0.46, 0.30),
		"fog_density": 0.00095,
		"vol_fog_density": 0.0028,
		"ambient_col": Color(0.42, 0.26, 0.38),
		"ambient_energy": 0.38,
		"cloud_crest": Color(1.0, 0.78, 0.48),
		"cloud_valley": Color(0.38, 0.24, 0.42),
		"cloud_cov": 0.50,
		"stars": 0.0,
		"aurora": 0.0,
		"glow": 0.34,
	},
	# 2: The Origami Monsoon - Luminous Jade-Teal Lantern Twilight & Wet Sheen Contrast
	{
		"y": 430.0,
		"zenith": Color(0.03, 0.11, 0.24),
		"mid_sky": Color(0.07, 0.32, 0.46),
		"horizon": Color(0.26, 0.58, 0.62),
		"abyss": Color(0.09, 0.21, 0.30),
		"sun_col": Color(0.86, 0.96, 1.0),
		"sun_energy": 1.26,
		"sun_rot": Vector3(-30.0, -35.0, 0.0),
		"fog_col": Color(0.14, 0.36, 0.46),
		"fog_density": 0.0010,
		"vol_fog_density": 0.0034,
		"ambient_col": Color(0.20, 0.42, 0.54),
		"ambient_energy": 0.42,
		"cloud_crest": Color(0.62, 0.84, 0.88),
		"cloud_valley": Color(0.12, 0.26, 0.40),
		"cloud_cov": 0.56,
		"stars": 0.25,
		"aurora": 0.0,
		"glow": 0.36,
	},
	# 3: The Shattered Mirror Gallery - Luminous Jewel-Rose Dusk & Iridescent Lavender
	{
		"y": 620.0,
		"zenith": Color(0.10, 0.06, 0.30),
		"mid_sky": Color(0.40, 0.18, 0.56),
		"horizon": Color(0.92, 0.48, 0.68),
		"abyss": Color(0.24, 0.13, 0.40),
		"sun_col": Color(1.0, 0.86, 0.92),
		"sun_energy": 1.36,
		"sun_rot": Vector3(-28.0, 115.0, 0.0),
		"fog_col": Color(0.50, 0.28, 0.58),
		"fog_density": 0.0009,
		"vol_fog_density": 0.0032,
		"ambient_col": Color(0.42, 0.26, 0.58),
		"ambient_energy": 0.40,
		"cloud_crest": Color(0.96, 0.72, 0.90),
		"cloud_valley": Color(0.26, 0.16, 0.44),
		"cloud_cov": 0.40,
		"stars": 0.60,
		"aurora": 0.30,
		"glow": 0.36,
	},
	# 4: The Cloud-Whale Library - Vivid Starry Aurora Night & Cozy Amber Reading Nooks
	{
		"y": 810.0,
		"zenith": Color(0.02, 0.035, 0.12),
		"mid_sky": Color(0.05, 0.13, 0.34),
		"horizon": Color(0.14, 0.42, 0.60),
		"abyss": Color(0.03, 0.07, 0.18),
		"sun_col": Color(0.78, 0.94, 1.0),
		"sun_energy": 1.15,
		"sun_rot": Vector3(-42.0, -70.0, 0.0),
		"fog_col": Color(0.08, 0.22, 0.38),
		"fog_density": 0.0008,
		"vol_fog_density": 0.0044,
		"ambient_col": Color(0.18, 0.34, 0.56),
		"ambient_energy": 0.38,
		"cloud_crest": Color(0.38, 0.80, 0.86),
		"cloud_valley": Color(0.06, 0.12, 0.28),
		"cloud_cov": 0.28,
		"stars": 1.40,
		"aurora": 1.35,
		"glow": 0.38,
	},
	# 5: The Crown of the Sun - Transcendent Cosmic-Gold Summit
	{
		"y": 1000.0,
		"zenith": Color(0.015, 0.02, 0.085),
		"mid_sky": Color(0.13, 0.09, 0.32),
		"horizon": Color(0.96, 0.66, 0.26),
		"abyss": Color(0.09, 0.06, 0.22),
		"sun_col": Color(1.0, 0.88, 0.52),
		"sun_energy": 1.56,
		"sun_rot": Vector3(-20.0, 24.0, 0.0),
		"fog_col": Color(0.52, 0.36, 0.22),
		"fog_density": 0.00065,
		"vol_fog_density": 0.0030,
		"ambient_col": Color(0.38, 0.30, 0.34),
		"ambient_energy": 0.40,
		"cloud_crest": Color(0.98, 0.80, 0.46),
		"cloud_valley": Color(0.18, 0.12, 0.34),
		"cloud_cov": 0.20,
		"stars": 1.50,
		"aurora": 0.65,
		"glow": 0.38,
	},
]


func _ready() -> void:
	_ensure_sky_and_env()
	apply_for_altitude(0.0, true)


func _ensure_sky_and_env() -> void:
	if not world_environment:
		world_environment = get_node_or_null("WorldEnvironment")
	if not sun_light:
		sun_light = get_node_or_null("SunLight")
	if not cloud_sea_mesh:
		cloud_sea_mesh = get_node_or_null("CloudSea")
	if not cloud_sea_mesh and get_parent():
		var sw_deck := get_parent().get_node_or_null("SpireWorld/CloudDeck_0")
		if sw_deck is MeshInstance3D:
			cloud_sea_mesh = sw_deck as MeshInstance3D

	if world_environment and world_environment.environment:
		var env := world_environment.environment
		if env.sky and env.sky.sky_material is ShaderMaterial:
			_sky_mat = env.sky.sky_material
			env.sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
		else:
			var sky := Sky.new()
			_sky_mat = ShaderMaterial.new()
			_sky_mat.shader = load("res://assets/shaders/stylized_sky.gdshader")
			sky.sky_material = _sky_mat
			sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
			env.sky = sky
			env.background_mode = Environment.BG_SKY

	if cloud_sea_mesh and cloud_sea_mesh.material_override is ShaderMaterial:
		_cloud_mat = cloud_sea_mesh.material_override


func apply_for_altitude(y_pos: float, instant: bool = false) -> void:
	_current_y = y_pos if instant else lerpf(_current_y, y_pos, 0.08)

	var idx_a := 0
	var idx_b := 0
	var t := 0.0
	for i in range(BIOME_PALETTES.size() - 1):
		var ya: float = BIOME_PALETTES[i]["y"]
		var yb: float = BIOME_PALETTES[i + 1]["y"]
		if _current_y <= ya:
			idx_a = i
			idx_b = i
			t = 0.0
			break
		elif _current_y <= yb:
			idx_a = i
			idx_b = i + 1
			t = smoothstep(ya, yb, _current_y)
			break
		else:
			idx_a = i + 1
			idx_b = i + 1
			t = 0.0

	var a: Dictionary = BIOME_PALETTES[idx_a]
	var b: Dictionary = BIOME_PALETTES[idx_b]

	if _sky_mat:
		_sky_mat.set_shader_parameter("zenith_color", a["zenith"].lerp(b["zenith"], t))
		_sky_mat.set_shader_parameter("mid_sky_color", a["mid_sky"].lerp(b["mid_sky"], t))
		_sky_mat.set_shader_parameter("horizon_color", a["horizon"].lerp(b["horizon"], t))
		_sky_mat.set_shader_parameter("abyss_color", a["abyss"].lerp(b["abyss"], t))
		_sky_mat.set_shader_parameter("sun_color", a["sun_col"].lerp(b["sun_col"], t))
		_sky_mat.set_shader_parameter("cloud_lit_color", a["cloud_crest"].lerp(b["cloud_crest"], t))
		_sky_mat.set_shader_parameter("cloud_shadow_color", a["cloud_valley"].lerp(b["cloud_valley"], t))
		_sky_mat.set_shader_parameter("cloud_coverage", lerpf(a["cloud_cov"], b["cloud_cov"], t))
		_sky_mat.set_shader_parameter("star_intensity", lerpf(a["stars"], b["stars"], t))
		_sky_mat.set_shader_parameter("aurora_intensity", lerpf(a["aurora"], b["aurora"], t))

	if not _cloud_mat:
		_ensure_sky_and_env()

	if _cloud_mat:
		_cloud_mat.set_shader_parameter("crest_color", a["cloud_crest"].lerp(b["cloud_crest"], t))
		_cloud_mat.set_shader_parameter("valley_color", a["cloud_valley"].lerp(b["cloud_valley"], t))
		_cloud_mat.set_shader_parameter("horizon_glow_color", a["horizon"].lerp(b["horizon"], t))

	if sun_light:
		sun_light.light_color = a["sun_col"].lerp(b["sun_col"], t)
		sun_light.light_energy = lerpf(a["sun_energy"], b["sun_energy"], t)
		var rot_deg: Vector3 = a["sun_rot"].lerp(b["sun_rot"], t)
		sun_light.rotation_degrees = rot_deg
		if _cloud_mat:
			var sun_dir := sun_light.global_transform.basis.z.normalized()
			_cloud_mat.set_shader_parameter("sun_direction", sun_dir)

	if world_environment and world_environment.environment:
		var env := world_environment.environment
		env.ambient_light_color = a["ambient_col"].lerp(b["ambient_col"], t)
		env.ambient_light_energy = lerpf(a["ambient_energy"], b["ambient_energy"], t)
		env.fog_light_color = a["fog_col"].lerp(b["fog_col"], t)
		env.fog_density = lerpf(a["fog_density"], b["fog_density"], t)
		env.glow_intensity = lerpf(a["glow"], b["glow"], t)
		env.volumetric_fog_density = lerpf(a["vol_fog_density"], b["vol_fog_density"], t)
		env.volumetric_fog_albedo = a["sun_col"].lerp(b["sun_col"], t)
		env.volumetric_fog_emission = a["ambient_col"].lerp(b["ambient_col"], t) * 0.25
		env.volumetric_fog_anisotropy = 0.68

	if ambient_particles:
		ambient_particles.global_position.y = _current_y + 8.0
