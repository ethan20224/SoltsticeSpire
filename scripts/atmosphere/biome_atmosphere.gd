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
	# 0: Sunken Conservatory - Vivid Ghibli Azure Sky, Warm Sunlit Gold & Cool Cobalt Shadows
	{
		"y": 40.0,
		"zenith": Color(0.05, 0.22, 0.60),
		"mid_sky": Color(0.17, 0.50, 0.84),
		"horizon": Color(0.92, 0.78, 0.56),
		"abyss": Color(0.42, 0.58, 0.76),
		"sun_col": Color(1.0, 0.91, 0.70),
		"sun_energy": 1.32,
		"sun_rot": Vector3(-36.0, 34.0, 0.0),
		"fog_col": Color(0.56, 0.72, 0.86),
		"fog_density": 0.0011,
		"vol_fog_density": 0.0028,
		"ambient_col": Color(0.26, 0.42, 0.66),
		"ambient_energy": 0.34,
		"cloud_crest": Color(0.96, 0.92, 0.84),
		"cloud_valley": Color(0.45, 0.60, 0.78),
		"cloud_cov": 0.48,
		"stars": 0.0,
		"aurora": 0.0,
		"glow": 0.28,
	},
	# 1: Foundry of Floating Bells - Dramatic Golden Hour Burnt Amber & Deep Plum Twilight
	{
		"y": 240.0,
		"zenith": Color(0.10, 0.12, 0.34),
		"mid_sky": Color(0.52, 0.25, 0.32),
		"horizon": Color(0.96, 0.56, 0.24),
		"abyss": Color(0.38, 0.22, 0.28),
		"sun_col": Color(1.0, 0.74, 0.36),
		"sun_energy": 1.42,
		"sun_rot": Vector3(-22.0, 56.0, 0.0),
		"fog_col": Color(0.72, 0.44, 0.30),
		"fog_density": 0.0012,
		"vol_fog_density": 0.0038,
		"ambient_col": Color(0.38, 0.24, 0.34),
		"ambient_energy": 0.34,
		"cloud_crest": Color(0.96, 0.74, 0.48),
		"cloud_valley": Color(0.34, 0.22, 0.36),
		"cloud_cov": 0.52,
		"stars": 0.0,
		"aurora": 0.0,
		"glow": 0.32,
	},
	# 2: The Origami Monsoon - Lush Deep Jade-Teal Twilight & Warm Paper-Lantern Glow
	{
		"y": 430.0,
		"zenith": Color(0.025, 0.09, 0.19),
		"mid_sky": Color(0.06, 0.26, 0.38),
		"horizon": Color(0.22, 0.50, 0.56),
		"abyss": Color(0.07, 0.17, 0.25),
		"sun_col": Color(0.84, 0.94, 0.98),
		"sun_energy": 1.18,
		"sun_rot": Vector3(-30.0, -35.0, 0.0),
		"fog_col": Color(0.12, 0.32, 0.40),
		"fog_density": 0.0013,
		"vol_fog_density": 0.0044,
		"ambient_col": Color(0.18, 0.38, 0.48),
		"ambient_energy": 0.38,
		"cloud_crest": Color(0.56, 0.78, 0.84),
		"cloud_valley": Color(0.09, 0.21, 0.32),
		"cloud_cov": 0.58,
		"stars": 0.20,
		"aurora": 0.0,
		"glow": 0.34,
	},
	# 3: The Shattered Mirror Gallery - Rich Velvet Plum, Rose Dusk & Iridescent Lavender
	{
		"y": 620.0,
		"zenith": Color(0.09, 0.05, 0.25),
		"mid_sky": Color(0.34, 0.16, 0.48),
		"horizon": Color(0.84, 0.44, 0.62),
		"abyss": Color(0.20, 0.11, 0.34),
		"sun_col": Color(1.0, 0.84, 0.90),
		"sun_energy": 1.28,
		"sun_rot": Vector3(-28.0, 115.0, 0.0),
		"fog_col": Color(0.46, 0.26, 0.52),
		"fog_density": 0.0012,
		"vol_fog_density": 0.0042,
		"ambient_col": Color(0.38, 0.24, 0.52),
		"ambient_energy": 0.38,
		"cloud_crest": Color(0.90, 0.68, 0.86),
		"cloud_valley": Color(0.22, 0.14, 0.38),
		"cloud_cov": 0.42,
		"stars": 0.55,
		"aurora": 0.25,
		"glow": 0.35,
	},
	# 4: The Cloud-Whale Library - Deep Midnight Indigo, Radiant Aurora & Cozy Amber Reading Nooks
	{
		"y": 810.0,
		"zenith": Color(0.015, 0.025, 0.09),
		"mid_sky": Color(0.04, 0.10, 0.26),
		"horizon": Color(0.12, 0.34, 0.50),
		"abyss": Color(0.025, 0.05, 0.14),
		"sun_col": Color(0.76, 0.92, 1.0),
		"sun_energy": 1.08,
		"sun_rot": Vector3(-42.0, -70.0, 0.0),
		"fog_col": Color(0.07, 0.18, 0.32),
		"fog_density": 0.0010,
		"vol_fog_density": 0.0060,
		"ambient_col": Color(0.16, 0.30, 0.50),
		"ambient_energy": 0.36,
		"cloud_crest": Color(0.32, 0.72, 0.78),
		"cloud_valley": Color(0.04, 0.09, 0.20),
		"cloud_cov": 0.30,
		"stars": 1.30,
		"aurora": 1.25,
		"glow": 0.38,
	},
	# 5: The Crown of the Sun - Deep Cosmic Indigo Zenith & Burnished Celestial Gold Horizon
	{
		"y": 1000.0,
		"zenith": Color(0.012, 0.015, 0.068),
		"mid_sky": Color(0.10, 0.07, 0.25),
		"horizon": Color(0.88, 0.60, 0.22),
		"abyss": Color(0.07, 0.05, 0.17),
		"sun_col": Color(1.0, 0.86, 0.50),
		"sun_energy": 1.48,
		"sun_rot": Vector3(-20.0, 24.0, 0.0),
		"fog_col": Color(0.46, 0.32, 0.20),
		"fog_density": 0.0008,
		"vol_fog_density": 0.0042,
		"ambient_col": Color(0.34, 0.28, 0.30),
		"ambient_energy": 0.38,
		"cloud_crest": Color(0.92, 0.74, 0.42),
		"cloud_valley": Color(0.14, 0.10, 0.26),
		"cloud_cov": 0.20,
		"stars": 1.45,
		"aurora": 0.55,
		"glow": 0.36,
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

	if _cloud_mat:
		_cloud_mat.set_shader_parameter("crest_color", a["cloud_crest"].lerp(b["cloud_crest"], t))
		_cloud_mat.set_shader_parameter("valley_color", a["cloud_valley"].lerp(b["cloud_valley"], t))

	if sun_light:
		sun_light.light_color = a["sun_col"].lerp(b["sun_col"], t)
		sun_light.light_energy = lerpf(a["sun_energy"], b["sun_energy"], t)
		var rot_deg: Vector3 = a["sun_rot"].lerp(b["sun_rot"], t)
		sun_light.rotation_degrees = rot_deg

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
