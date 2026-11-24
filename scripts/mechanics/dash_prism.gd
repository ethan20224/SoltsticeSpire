extends Area3D
class_name DashPrism
## Interactive mid-air Dash-Break / Reset Prism (Crystal, Floating Bell, or Lantern Orb).
## Air-Dashing through it (or touching while airborne) shatters it in a hitstop burst,
## INSTANTLY resetting Air-Dash + Double-Jump and launching you into "floor is lava" aerial chains!

@export var accent_color: Color = Color(0.45, 0.96, 1.0)
@export var boost_up: float = 10.2
@export var respawn_delay: float = 2.6
@export var require_dash: bool = false  # False allows generous mid-air touch while strongly rewarding Dash magnetism

var _visual_root: Node3D
var _core_mesh: MeshInstance3D
var _ring_mesh: MeshInstance3D
var _light: OmniLight3D
var _broken: bool = false
var _respawn_timer: float = 0.0
var _t: float = 0.0

static var _shared_gem: ArrayMesh
static var _shared_ring: TorusMesh
static var _shared_spark: SphereMesh


func _ready() -> void:
	add_to_group("dash_prism")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_t = randf() * TAU
	_ensure_shared_meshes()
	_build_visuals()
	_build_collider()
	body_entered.connect(_on_body_entered)


func is_available() -> bool:
	return not _broken


static func _ensure_shared_meshes() -> void:
	if _shared_gem == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var sides := 6
		var r := 0.72
		var h := 1.05
		var top := Vector3(0.0, h, 0.0)
		var bot := Vector3(0.0, -h, 0.0)
		for i in range(sides):
			var a0 := (float(i) / float(sides)) * TAU
			var a1 := (float(i + 1) / float(sides)) * TAU
			var p0 := Vector3(cos(a0) * r, 0.0, sin(a0) * r)
			var p1 := Vector3(cos(a1) * r, 0.0, sin(a1) * r)
			var nt := (p1 - top).cross(p0 - top).normalized()
			st.set_normal(nt)
			st.add_vertex(top)
			st.add_vertex(p1)
			st.add_vertex(p0)
			var nb := (p0 - bot).cross(p1 - bot).normalized()
			st.set_normal(nb)
			st.add_vertex(bot)
			st.add_vertex(p0)
			st.add_vertex(p1)
		_shared_gem = st.commit()
	if _shared_ring == null:
		_shared_ring = TorusMesh.new()
		_shared_ring.inner_radius = 0.96
		_shared_ring.outer_radius = 1.08
		_shared_ring.rings = 24
		_shared_ring.ring_segments = 8
	if _shared_spark == null:
		_shared_spark = SphereMesh.new()
		_shared_spark.radius = 0.14
		_shared_spark.height = 0.28
		_shared_spark.radial_segments = 6
		_shared_spark.rings = 3


func _build_visuals() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = accent_color.lightened(0.18)
	core_mat.metallic = 0.35
	core_mat.roughness = 0.12
	core_mat.emission_enabled = true
	core_mat.emission = accent_color
	core_mat.emission_energy_multiplier = 2.1

	_core_mesh = MeshInstance3D.new()
	_core_mesh.mesh = _shared_gem
	_core_mesh.material_override = core_mat
	_core_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_root.add_child(_core_mesh)

	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring_mat.albedo_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.85)

	_ring_mesh = MeshInstance3D.new()
	_ring_mesh.mesh = _shared_ring
	_ring_mesh.material_override = ring_mat
	_ring_mesh.rotation_degrees = Vector3(65.0, 0.0, 20.0)
	_ring_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_root.add_child(_ring_mesh)

	_light = OmniLight3D.new()
	_light.light_color = accent_color
	_light.light_energy = 2.4
	_light.omni_range = 9.0
	_light.distance_fade_enabled = true
	_light.distance_fade_begin = 60.0
	_light.distance_fade_length = 22.0
	_visual_root.add_child(_light)


func _build_collider() -> void:
	var col := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 1.95
	col.shape = sp
	add_child(col)


func _on_body_entered(body: Node3D) -> void:
	if _broken or not body.is_in_group("player"):
		return
	if require_dash and body is PlayerController and not (body as PlayerController).is_dashing_or_recent():
		return
	_shatter(body)


func _shatter(body: Node3D) -> void:
	_broken = true
	_respawn_timer = respawn_delay
	if _visual_root:
		_visual_root.visible = false

	var is_dash := body is PlayerController and (body as PlayerController).is_dashing_or_recent()
	var eff_boost := boost_up + (1.6 if is_dash else 0.0)
	if body.has_method("on_dash_prism_shatter"):
		body.call("on_dash_prism_shatter", global_position, eff_boost)

	AudioDirector.play_sfx("crystal_shatter", -2.5, randf_range(1.12, 1.30))
	AudioDirector.play_flow_chime(mini(GameState.current_streak, 7), -3.0)
	if is_dash:
		GameState.emit_callout("PRISM SHATTER!", "AIR-DASH & JUMP RESET!", accent_color.lightened(0.15))

	_spawn_shatter_fx()


func _spawn_shatter_fx() -> void:
	var gp := GPUParticles3D.new()
	gp.one_shot = true
	gp.explosiveness = 0.96
	gp.amount = 22
	gp.lifetime = 0.52
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.4, 0.0)
	pm.spread = 180.0
	pm.initial_velocity_min = 5.0
	pm.initial_velocity_max = 11.5
	pm.gravity = Vector3(0.0, -7.0, 0.0)
	pm.scale_min = 0.7
	pm.scale_max = 1.4
	gp.process_material = pm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = accent_color.lightened(0.25)
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 2.6
	gp.material_override = mat
	gp.draw_pass_1 = _shared_spark
	add_child(gp)
	gp.emitting = true

	var ring := MeshInstance3D.new()
	ring.mesh = _shared_ring
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rmat.albedo_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.95)
	ring.material_override = rmat
	add_child(ring)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE * 3.4, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(rmat, "albedo_color:a", 0.0, 0.34)
	tw.chain().tween_callback(ring.queue_free)

	var t := get_tree().create_timer(0.65)
	t.timeout.connect(func() -> void:
		if is_instance_valid(gp):
			gp.queue_free()
	)


func _process(delta: float) -> void:
	_t += delta
	if _broken:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_broken = false
			if _visual_root:
				_visual_root.visible = true
				_visual_root.scale = Vector3(0.15, 0.15, 0.15)
				var tw := create_tween()
				tw.tween_property(_visual_root, "scale", Vector3.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		return
	if _core_mesh:
		_core_mesh.rotation.y += delta * 2.1
		_core_mesh.position.y = sin(_t * 2.8) * 0.18
	if _ring_mesh:
		_ring_mesh.rotation.y -= delta * 2.9
		_ring_mesh.rotation.z += delta * 1.4
