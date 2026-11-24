extends StaticBody3D
class_name WallRunSurface
## Tagged runnable wall surface (World 2 Musical Bronze Bells, World 4 Mirror Panels, World 6 Obsidian Monoliths).
## Responds to wall-run contact & wall-kicks with physical ring sway, metallic/crystal spark bursts, and musical chimes!

@export var is_musical_bell: bool = false
@export var bell_note_step: int = 0
@export var resonance_group: String = ""
@export var resonance_duration: float = 8.0

var _visual: Node3D
var _sway_t: float = 0.0
var _spark_mesh: SphereMesh


func _ready() -> void:
	add_to_group("wall_run")
	_visual = get_node_or_null("Visual")
	_spark_mesh = SphereMesh.new()
	_spark_mesh.radius = 0.08
	_spark_mesh.height = 0.16
	_spark_mesh.radial_segments = 6
	_spark_mesh.rings = 3


func on_wall_run_contact() -> void:
	if is_musical_bell:
		_sway_t = 0.5
		AudioDirector.play_bell_ring(bell_note_step)
		if not resonance_group.is_empty():
			_emit_resonance_shockwave()


func on_wall_kick(hit_pos: Vector3 = Vector3.ZERO) -> void:
	_sway_t = 1.0
	if is_musical_bell:
		AudioDirector.play_bell_ring(bell_note_step + 2)
		if not resonance_group.is_empty():
			_emit_resonance_shockwave()
	else:
		AudioDirector.play_sfx("wall_kick", -1.0, randf_range(0.98, 1.12))
	_spawn_kick_sparks(hit_pos)


func _emit_resonance_shockwave() -> void:
	GameState.emit_bell_resonance(resonance_group, resonance_duration)
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.2
	tor.outer_radius = 1.45
	tor.rings = 28
	tor.ring_segments = 8
	ring.mesh = tor
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.84, 0.30, 0.92)
	ring.material_override = mat
	add_child(ring)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE * 14.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.65)
	tw.chain().tween_callback(ring.queue_free)


func _spawn_kick_sparks(hit_pos: Vector3) -> void:
	var gp := GPUParticles3D.new()
	gp.one_shot = true
	gp.explosiveness = 0.94
	gp.amount = 14
	gp.lifetime = 0.38
	gp.top_level = true

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.4, 0.0)
	pm.spread = 110.0
	pm.initial_velocity_min = 3.2
	pm.initial_velocity_max = 6.8
	pm.gravity = Vector3(0.0, -8.0, 0.0)
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	pm.damping_min = 2.0
	pm.damping_max = 4.0
	gp.process_material = pm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var spark_col := Color(1.0, 0.80, 0.34) if is_musical_bell else Color(0.76, 0.92, 1.0)
	mat.albedo_color = spark_col
	mat.emission_enabled = true
	mat.emission = spark_col
	mat.emission_energy_multiplier = 2.4
	gp.material_override = mat
	gp.draw_pass_1 = _spark_mesh
	add_child(gp)
	gp.global_position = hit_pos if hit_pos != Vector3.ZERO else global_position
	gp.emitting = true

	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(func():
		if is_instance_valid(gp):
			gp.queue_free()
	)


func _process(delta: float) -> void:
	if _sway_t > 0.001:
		_sway_t = maxf(0.0, _sway_t - delta * 2.2)
		if _visual and is_musical_bell:
			_visual.rotation.z = sin(_sway_t * PI * 5.0) * _sway_t * 0.14
	elif _visual and is_musical_bell:
		_visual.rotation.z = 0.0
