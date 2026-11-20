extends Node3D
class_name BouncePad
## Elastic springy bounce pad (World 1 Botanical Lily Cap, World 3 Silk Parasol, World 5 Dream Jelly).
## Launches player along launch_velocity with squash recoil, chime, expanding shockwave ring,
## pollen/spark burst, Meteor Super-Bounce support, and full air-move reset.

@export var bounce_up_speed: float = 19.5
@export var forward_boost: Vector3 = Vector3.ZERO
@export var trigger_radius: float = 2.0
@export var pad_color: Color = Color(0.28, 0.78, 0.44)

var _visual_root: Node3D
var _recoil_t: float = 0.0
var _cooldown: float = 0.0
var _ring_mesh: TorusMesh
var _spark_mesh: SphereMesh


func _ready() -> void:
	add_to_group("bounce_pad")
	_visual_root = get_node_or_null("Visual")

	_ring_mesh = TorusMesh.new()
	_ring_mesh.inner_radius = 0.78
	_ring_mesh.outer_radius = 1.0
	_ring_mesh.rings = 24
	_ring_mesh.ring_segments = 8

	_spark_mesh = SphereMesh.new()
	_spark_mesh.radius = 0.12
	_spark_mesh.height = 0.24
	_spark_mesh.radial_segments = 6
	_spark_mesh.rings = 3

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = trigger_radius
	cyl.height = 1.1
	col.shape = cyl
	col.position = Vector3(0.0, 0.45, 0.0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0 or not body.is_in_group("player"):
		return
	_cooldown = 0.22
	_recoil_t = 1.0

	var is_meteor := false
	if body is PlayerController:
		var pc := body as PlayerController
		is_meteor = pc.is_sky_dive_recent()

	var impulse := Vector3(forward_boost.x, bounce_up_speed, forward_boost.z)
	if body.has_method("apply_bounce"):
		body.apply_bounce(impulse, true, is_meteor)

	if is_meteor:
		AudioDirector.play_sfx("bounce", 1.5, 0.62)
		AudioDirector.play_sfx("bounce", -0.5, 1.24)
		AudioDirector.play_sfx("dash", -2.0, 0.78)
	else:
		AudioDirector.play_sfx("bounce", -1.5, randf_range(0.95, 1.10))

	_spawn_shockwave_ring(is_meteor)
	_spawn_pollen_burst(is_meteor)


func _spawn_shockwave_ring(is_meteor: bool) -> void:
	var ring := MeshInstance3D.new()
	ring.mesh = _ring_mesh
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0.0, 0.22, 0.0)
	ring.scale = Vector3(0.5, 0.35, 0.5)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var col := Color(1.0, 0.86, 0.34, 0.92) if is_meteor else pad_color.lerp(Color(1.0, 0.90, 0.45), 0.68)
	col.a = 0.92 if is_meteor else 0.78
	mat.albedo_color = col
	ring.material_override = mat
	add_child(ring)

	var max_scale := (trigger_radius * 2.5) if is_meteor else (trigger_radius * 1.55)
	var dur := 0.42 if is_meteor else 0.32
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(max_scale, 0.18, max_scale), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "position:y", 0.55 if is_meteor else 0.38, dur)
	tw.tween_property(mat, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(ring.queue_free)


func _spawn_pollen_burst(is_meteor: bool) -> void:
	var gp := GPUParticles3D.new()
	gp.one_shot = true
	gp.explosiveness = 0.94
	gp.amount = 26 if is_meteor else 14
	gp.lifetime = 0.58 if is_meteor else 0.45
	gp.position = Vector3(0.0, 0.35, 0.0)

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 82.0
	pm.initial_velocity_min = 5.5 if is_meteor else 3.2
	pm.initial_velocity_max = 11.5 if is_meteor else 6.8
	pm.gravity = Vector3(0.0, -9.0, 0.0)
	pm.scale_min = 0.7
	pm.scale_max = 1.6 if is_meteor else 1.2
	pm.damping_min = 1.5
	pm.damping_max = 3.0
	gp.process_material = pm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.88, 0.38) if is_meteor else pad_color.lerp(Color(1.0, 0.92, 0.50), 0.72)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 2.6 if is_meteor else 1.9
	gp.material_override = mat
	gp.draw_pass_1 = _spark_mesh
	add_child(gp)
	gp.emitting = true

	var timer := get_tree().create_timer(0.75)
	timer.timeout.connect(func():
		if is_instance_valid(gp):
			gp.queue_free()
	)


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _recoil_t > 0.001:
		_recoil_t = maxf(0.0, _recoil_t - delta * 3.8)
		if _visual_root:
			var osc := sin(_recoil_t * PI * 3.0) * _recoil_t * 0.28
			_visual_root.scale = Vector3(1.0 + osc, 1.0 - osc * 1.4, 1.0 + osc)
	elif _visual_root:
		_visual_root.scale = Vector3.ONE
