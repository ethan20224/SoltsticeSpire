extends Node3D
class_name SummitCelebration
## Summit Crown Sanctuary celebratory finale:
## Ignites a soaring 120m golden sunbeam into the stratosphere, launches 6 staggered firework waves
## in Solstice Gold, Rose, Cyan-Aurora, and Warm Ivory with pops & pentatonic chimes,
## and settles into a persistent golden starlight shimmer while exploring the Summit.

const FIREWORK_PALETTE := [
	Color(1.0, 0.84, 0.30),  # Solstice Gold
	Color(1.0, 0.52, 0.74),  # Solstice Rose
	Color(0.42, 0.96, 1.0),  # Cyan-Aurora
	Color(1.0, 0.96, 0.86),  # Warm Ivory
]

var _sunbeam_pivot: Node3D
var _beam_core_mat: StandardMaterial3D
var _beam_halo_mat: StandardMaterial3D
var _shimmer_particles: GPUParticles3D
var _summit_flash_light: OmniLight3D
var _celebration_tween: Tween
var _active: bool = false
var _t: float = 0.0
var _beam_intensity: float = 0.0


func _ready() -> void:
	add_to_group("summit_celebration")
	_build_sunbeam()
	_build_starlight_shimmer()

	GameState.summit_reached.connect(_on_summit_reached)
	GameState.game_started.connect(_reset_celebration)


func _build_sunbeam() -> void:
	_sunbeam_pivot = Node3D.new()
	_sunbeam_pivot.name = "SunbeamColumn"
	_sunbeam_pivot.visible = false
	_sunbeam_pivot.scale = Vector3(1.0, 0.02, 1.0)
	add_child(_sunbeam_pivot)

	# Inner radiant ivory-gold sunbeam core rising 120m from the Summit Altar
	var core := MeshInstance3D.new()
	var core_cyl := CylinderMesh.new()
	core_cyl.bottom_radius = 1.15
	core_cyl.top_radius = 2.85
	core_cyl.height = 120.0
	core_cyl.radial_segments = 20
	core.mesh = core_cyl
	core.position = Vector3(0.0, 60.0, 0.0)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam_core_mat = StandardMaterial3D.new()
	_beam_core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_core_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_core_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_core_mat.albedo_color = Color(1.0, 0.95, 0.72, 0.0)
	core.material_override = _beam_core_mat
	_sunbeam_pivot.add_child(core)

	# Wide translucent Solstice Gold outer column halo
	var halo := MeshInstance3D.new()
	var halo_cyl := CylinderMesh.new()
	halo_cyl.bottom_radius = 2.6
	halo_cyl.top_radius = 6.8
	halo_cyl.height = 120.0
	halo_cyl.radial_segments = 20
	halo.mesh = halo_cyl
	halo.position = Vector3(0.0, 60.0, 0.0)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam_halo_mat = StandardMaterial3D.new()
	_beam_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_halo_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_halo_mat.albedo_color = Color(1.0, 0.80, 0.30, 0.0)
	halo.material_override = _beam_halo_mat
	_sunbeam_pivot.add_child(halo)

	_summit_flash_light = OmniLight3D.new()
	_summit_flash_light.position = Vector3(0.0, 12.0, 0.0)
	_summit_flash_light.light_color = Color(1.0, 0.88, 0.48)
	_summit_flash_light.light_energy = 0.0
	_summit_flash_light.omni_range = 48.0
	_summit_flash_light.visible = false
	add_child(_summit_flash_light)


func _build_starlight_shimmer() -> void:
	_shimmer_particles = GPUParticles3D.new()
	_shimmer_particles.name = "SummitStarlightShimmer"
	_shimmer_particles.position = Vector3(0.0, 4.5, 0.0)
	_shimmer_particles.amount = 110
	_shimmer_particles.lifetime = 4.6
	_shimmer_particles.emitting = false
	_shimmer_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shimmer_particles.visibility_aabb = AABB(Vector3(-24.0, -4.0, -24.0), Vector3(48.0, 42.0, 48.0))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_height = 6.0
	pm.emission_ring_radius = 13.5
	pm.emission_ring_inner_radius = 2.0
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 22.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 3.2
	pm.gravity = Vector3(0.0, 0.25, 0.0)
	pm.scale_min = 0.14
	pm.scale_max = 0.34
	_shimmer_particles.process_material = pm

	var sp := SphereMesh.new()
	sp.radius = 0.34
	sp.height = 0.68
	sp.radial_segments = 6
	sp.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.90, 0.52, 0.86)
	sp.material = mat
	_shimmer_particles.draw_pass_1 = sp
	add_child(_shimmer_particles)


func _on_summit_reached(_run_time: float, _total_falls: int, _shards: int, _max_streak: int) -> void:
	trigger_celebration()


func _reset_celebration() -> void:
	_active = false
	_beam_intensity = 0.0
	if _celebration_tween and _celebration_tween.is_valid():
		_celebration_tween.kill()
	_celebration_tween = null
	if is_instance_valid(_sunbeam_pivot):
		_sunbeam_pivot.visible = false
		_sunbeam_pivot.scale = Vector3(1.0, 0.02, 1.0)
	if is_instance_valid(_summit_flash_light):
		_summit_flash_light.visible = false
		_summit_flash_light.light_energy = 0.0
	if is_instance_valid(_shimmer_particles):
		_shimmer_particles.emitting = false


func trigger_celebration() -> void:
	_active = true
	if _celebration_tween and _celebration_tween.is_valid():
		_celebration_tween.kill()

	# Ignite soaring 120m golden sunbeam into the stratosphere
	if is_instance_valid(_sunbeam_pivot):
		_sunbeam_pivot.visible = true
		_sunbeam_pivot.scale = Vector3(0.65, 0.02, 0.65)
	if is_instance_valid(_summit_flash_light):
		_summit_flash_light.visible = true
		_summit_flash_light.light_energy = 9.0

	var beam_tw := create_tween().set_parallel(true)
	beam_tw.tween_property(_sunbeam_pivot, "scale", Vector3.ONE, 1.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	beam_tw.tween_method(_set_beam_intensity, 0.0, 1.0, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	beam_tw.tween_property(_summit_flash_light, "light_energy", 3.6, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if is_instance_valid(_shimmer_particles):
		_shimmer_particles.emitting = true

	# Launch 6 staggered celebratory firework waves with pops & rising pentatonic chimes!
	_celebration_tween = create_tween()
	var wave_delays: Array[float] = [0.18, 0.68, 0.65, 0.62, 0.58, 0.72]
	for wave_idx in range(6):
		_celebration_tween.tween_interval(wave_delays[wave_idx])
		_celebration_tween.tween_callback(_launch_firework_wave.bind(wave_idx))

	# Gently settle sunbeam to persistent golden exploration glow after finale
	_celebration_tween.tween_interval(1.8)
	_celebration_tween.tween_method(_set_beam_intensity, 1.0, 0.48, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_beam_intensity(val: float) -> void:
	_beam_intensity = clampf(val, 0.0, 1.2)


func _launch_firework_wave(wave_idx: int) -> void:
	var bursts_in_wave := 3 if wave_idx == 5 else 2
	for b in range(bursts_in_wave):
		var angle := deg_to_rad(float(wave_idx * 58 + b * 124 + 18))
		var radius := 12.0 + float((wave_idx + b) % 3) * 4.8
		var height := 15.0 + float(wave_idx) * 2.8 + float(b) * 3.6
		var burst_pos := Vector3(sin(angle) * radius, height, cos(angle) * radius)
		var col: Color = FIREWORK_PALETTE[(wave_idx + b) % FIREWORK_PALETTE.size()]
		var pitch := randf_range(0.90, 1.16)
		_spawn_firework_burst(burst_pos, col, 96 if wave_idx == 5 else 68)
		AudioDirector.play_sfx("firework_pop", -1.2 if b == 0 else -2.8, pitch)
	AudioDirector.play_flow_chime(clampi(wave_idx + 1, 0, 7), -2.5)


func _spawn_firework_burst(local_pos: Vector3, color: Color, amount: int) -> void:
	var gp := GPUParticles3D.new()
	gp.position = local_pos
	gp.one_shot = true
	gp.explosiveness = 0.96
	gp.amount = amount
	gp.lifetime = 2.05
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gp.visibility_aabb = AABB(Vector3(-22.0, -22.0, -22.0), Vector3(44.0, 44.0, 44.0))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 7.5
	pm.initial_velocity_max = 17.5
	pm.gravity = Vector3(0.0, -4.6, 0.0)
	pm.damping_min = 1.6
	pm.damping_max = 3.2
	pm.scale_min = 0.22
	pm.scale_max = 0.48
	gp.process_material = pm

	var sp := SphereMesh.new()
	sp.radius = 0.36
	sp.height = 0.72
	sp.radial_segments = 6
	sp.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(color.r, color.g, color.b, 0.96)
	sp.material = mat
	gp.draw_pass_1 = sp
	add_child(gp)
	gp.emitting = true

	# Transient celebratory sky flash at burst apex
	var flash := OmniLight3D.new()
	flash.position = local_pos
	flash.light_color = color
	flash.light_energy = 6.5
	flash.omni_range = 34.0
	add_child(flash)

	var ftw := create_tween()
	ftw.tween_property(flash, "light_energy", 0.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ftw.tween_callback(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)

	var timer := get_tree().create_timer(2.45)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(gp):
			gp.queue_free()
	)


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	var pulse := 1.0 + sin(_t * 2.4) * 0.12
	if is_instance_valid(_beam_core_mat):
		_beam_core_mat.albedo_color = Color(1.0, 0.95, 0.74, clampf(0.42 * _beam_intensity * pulse, 0.0, 0.72))
	if is_instance_valid(_beam_halo_mat):
		_beam_halo_mat.albedo_color = Color(1.0, 0.80, 0.30, clampf(0.20 * _beam_intensity * pulse, 0.0, 0.45))
	if is_instance_valid(_sunbeam_pivot):
		_sunbeam_pivot.rotation.y += delta * 0.22
