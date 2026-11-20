extends Area3D
class_name SolarMote
## Gleaming Astro-Bot style multifaceted golden Solar Mote breadcrumb collectible.
## Guides players along parkour lines, feeds Flow (+0.07), plays ascending combo chimes,
## and resets cleanly on full run restart.

static var _shared_gem_mesh: ArrayMesh
static var _shared_halo_mesh: TorusMesh
static var _shared_gem_mat: StandardMaterial3D
static var _shared_halo_mat: StandardMaterial3D
static var _combo_count: int = 0
static var _last_collect_msec: int = 0

var _visual_root: Node3D
var _gem_inst: MeshInstance3D
var _halo_inst: MeshInstance3D
var _collected: bool = false
var _t: float = 0.0


func _ready() -> void:
	add_to_group("solar_mote")
	collision_layer = 0
	collision_mask = 2
	monitorable = false

	_ensure_shared_resources()
	_build_visuals()
	_build_collider()

	body_entered.connect(_on_body_entered)
	GameState.solar_motes_changed.connect(_on_solar_motes_changed)
	_t = randf() * TAU


static func _ensure_shared_resources() -> void:
	if _shared_gem_mesh == null:
		_shared_gem_mesh = _build_cut_gem_mesh()
	if _shared_halo_mesh == null:
		_shared_halo_mesh = TorusMesh.new()
		_shared_halo_mesh.inner_radius = 0.42
		_shared_halo_mesh.outer_radius = 0.48
		_shared_halo_mesh.rings = 20
		_shared_halo_mesh.ring_segments = 6
	if _shared_gem_mat == null:
		_shared_gem_mat = StandardMaterial3D.new()
		_shared_gem_mat.albedo_color = Color(1.0, 0.84, 0.24)
		_shared_gem_mat.metallic = 0.85
		_shared_gem_mat.roughness = 0.14
		_shared_gem_mat.emission_enabled = true
		_shared_gem_mat.emission = Color(1.0, 0.74, 0.16)
		_shared_gem_mat.emission_energy_multiplier = 1.45
	if _shared_halo_mat == null:
		_shared_halo_mat = StandardMaterial3D.new()
		_shared_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shared_halo_mat.albedo_color = Color(1.0, 0.94, 0.62, 0.88)
		_shared_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


static func _build_cut_gem_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 6
	var r := 0.28
	var h_top := 0.36
	var h_bot := -0.36
	var top := Vector3(0.0, h_top, 0.0)
	var bot := Vector3(0.0, h_bot, 0.0)

	for i in range(sides):
		var a0 := (float(i) / float(sides)) * TAU
		var a1 := (float(i + 1) / float(sides)) * TAU
		var p0 := Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0.0, sin(a1) * r)

		var n_top := (p1 - top).cross(p0 - top).normalized()
		st.set_normal(n_top)
		st.add_vertex(top)
		st.add_vertex(p1)
		st.add_vertex(p0)

		var n_bot := (p0 - bot).cross(p1 - bot).normalized()
		st.set_normal(n_bot)
		st.add_vertex(bot)
		st.add_vertex(p0)
		st.add_vertex(p1)

	return st.commit()


func _build_visuals() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	_gem_inst = MeshInstance3D.new()
	_gem_inst.mesh = _shared_gem_mesh
	_gem_inst.material_override = _shared_gem_mat
	_gem_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_root.add_child(_gem_inst)

	_halo_inst = MeshInstance3D.new()
	_halo_inst.mesh = _shared_halo_mesh
	_halo_inst.material_override = _shared_halo_mat
	_halo_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo_inst.rotation_degrees = Vector3(68.0, 0.0, 22.0)
	_visual_root.add_child(_halo_inst)


func _build_collider() -> void:
	var col := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 1.05
	col.shape = sp
	add_child(col)


func _on_solar_motes_changed(total: int) -> void:
	if total == 0 and _collected:
		reset_mote()


func reset_mote() -> void:
	_collected = false
	visible = true
	scale = Vector3.ONE
	if _visual_root:
		_visual_root.scale = Vector3.ONE
		_visual_root.position = Vector3.ZERO
	set_deferred("monitoring", true)
	set_process(true)


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	set_deferred("monitoring", false)
	set_process(false)

	var now := Time.get_ticks_msec()
	if now - _last_collect_msec <= 1800:
		_combo_count = mini(_combo_count + 1, 7)
	else:
		_combo_count = 0
	_last_collect_msec = now

	var pitch: float = AudioDirector.PENTATONIC_RATIOS[_combo_count]
	AudioDirector.play_sfx("flow_chime", -5.0, pitch)
	GameState.collect_solar_mote()
	if body.has_method("add_flow"):
		body.add_flow(0.07, false)
	PhoneController.send_haptic("jump")

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_visual_root, "scale", Vector3.ONE * 1.85, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_visual_root, "position:y", 0.75, 0.16)
	tw.chain().tween_property(_visual_root, "scale", Vector3.ONE * 0.02, 0.08)
	tw.chain().tween_callback(func():
		visible = false
	)


func _process(delta: float) -> void:
	_t += delta
	if _visual_root:
		_visual_root.position.y = sin(_t * 3.0) * 0.16
	if _gem_inst:
		_gem_inst.rotation.y += delta * 2.2
	if _halo_inst:
		_halo_inst.rotation.y -= delta * 2.8
		_halo_inst.rotation.z += delta * 1.4
