extends Node3D
class_name GhostRunner
## Translucent glowing golden-amber spirit orb + flowing golden ribbon trail that replays
## GameState.best_run_samples smoothly at GameState.run_time during gameplay.

const MAX_TRAIL_PTS := 20

var _orb: MeshInstance3D
var _aura: MeshInstance3D
var _ribbon_inst: MeshInstance3D
var _ribbon_mesh: ImmediateMesh
var _ribbon_mat: ShaderMaterial
var _trail_pts: Array[Vector3] = []
var _trail_timer: float = 0.0
var _sample_idx: int = 0
var _last_run_time: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	visible = false
	_build_visuals()
	_build_ribbon()


func _build_visuals() -> void:
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	core_mat.albedo_color = Color(1.0, 0.90, 0.44, 0.86)

	var sp := SphereMesh.new()
	sp.radius = 0.28
	sp.height = 0.56
	sp.radial_segments = 14
	sp.rings = 8
	_orb = MeshInstance3D.new()
	_orb.mesh = sp
	_orb.material_override = core_mat
	_orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_orb)

	var aura_mat := StandardMaterial3D.new()
	aura_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	aura_mat.albedo_color = Color(1.0, 0.72, 0.20, 0.34)

	var aura_sp := SphereMesh.new()
	aura_sp.radius = 0.48
	aura_sp.height = 0.96
	aura_sp.radial_segments = 12
	aura_sp.rings = 6
	_aura = MeshInstance3D.new()
	_aura.mesh = aura_sp
	_aura.material_override = aura_mat
	_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_aura)


func _build_ribbon() -> void:
	_ribbon_mesh = ImmediateMesh.new()
	_ribbon_inst = MeshInstance3D.new()
	_ribbon_inst.mesh = _ribbon_mesh
	_ribbon_inst.top_level = true
	_ribbon_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ribbon_mat = ShaderMaterial.new()
	_ribbon_mat.shader = load("res://assets/shaders/flow_ribbon.gdshader")
	_ribbon_mat.set_shader_parameter("core_color", Color(1.0, 0.90, 0.46))
	_ribbon_mat.set_shader_parameter("edge_color", Color(0.98, 0.62, 0.14))
	_ribbon_mat.set_shader_parameter("intensity", 1.55)
	_ribbon_inst.material_override = _ribbon_mat
	add_child(_ribbon_inst)


func reset_ghost() -> void:
	_sample_idx = 0
	_last_run_time = 0.0
	_trail_pts.clear()
	if _ribbon_mesh:
		_ribbon_mesh.clear_surfaces()


func _process(delta: float) -> void:
	var samples := GameState.best_run_samples
	var can_show := GameState.is_playing and not GameState.has_finished and samples.size() >= 2
	if not can_show:
		if visible:
			visible = false
			reset_ghost()
		return

	if not visible:
		visible = true

	var rt := GameState.run_time
	if rt < _last_run_time - 0.1:
		reset_ghost()
	_last_run_time = rt

	var n := samples.size()
	while _sample_idx < n - 2:
		var next_s: Dictionary = samples[_sample_idx + 1] as Dictionary
		if float(next_s.get("t", 0.0)) <= rt:
			_sample_idx += 1
		else:
			break

	var s0: Dictionary = samples[_sample_idx] as Dictionary
	var s1: Dictionary = samples[mini(_sample_idx + 1, n - 1)] as Dictionary
	var t0 := float(s0.get("t", 0.0))
	var t1 := float(s1.get("t", t0 + 0.15))
	var frac := 0.0
	if t1 > t0:
		frac = clampf((rt - t0) / (t1 - t0), 0.0, 1.0)

	var p0_arr: Array = s0.get("p", [0.0, 0.0, 0.0]) as Array
	var p1_arr: Array = s1.get("p", p0_arr) as Array
	var p0 := Vector3(float(p0_arr[0]), float(p0_arr[1]), float(p0_arr[2]))
	var p1 := Vector3(float(p1_arr[0]), float(p1_arr[1]), float(p1_arr[2]))
	var target_pos := p0.lerp(p1, frac) + Vector3(0.0, 0.95, 0.0)

	_t += delta
	target_pos.y += sin(_t * 4.2) * 0.12
	global_position = target_pos

	var y0 := float(s0.get("y", 0.0))
	var y1 := float(s1.get("y", y0))
	rotation.y = lerp_angle(y0, y1, frac)

	if _aura:
		var pulse := 1.0 + sin(_t * 5.5) * 0.14
		_aura.scale = Vector3.ONE * pulse

	_update_ribbon(delta)


func _update_ribbon(delta: float) -> void:
	_trail_timer += delta
	if _trail_timer >= 0.02:
		_trail_timer = 0.0
		_trail_pts.push_front(global_position)
		if _trail_pts.size() > MAX_TRAIL_PTS:
			_trail_pts.pop_back()

	_ribbon_mesh.clear_surfaces()
	if _trail_pts.size() < 3:
		return

	var cam := get_viewport().get_camera_3d()
	var cam_pos := cam.global_position if cam else global_position + Vector3(0.0, 3.0, 5.0)
	_ribbon_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var cnt := _trail_pts.size()
	for i in range(cnt):
		var u := float(i) / float(cnt - 1)
		var pt := _trail_pts[i]
		var tang: Vector3
		if i < cnt - 1:
			tang = (_trail_pts[i + 1] - pt).normalized()
		else:
			tang = (pt - _trail_pts[i - 1]).normalized()
		var to_cam := (cam_pos - pt).normalized()
		var side := tang.cross(to_cam).normalized()
		if side.length_squared() < 0.01:
			side = Vector3.UP
		var half_w := 0.24 * (1.0 - u) * 0.5
		_ribbon_mesh.surface_set_uv(Vector2(u, 0.0))
		_ribbon_mesh.surface_add_vertex(pt - side * half_w)
		_ribbon_mesh.surface_set_uv(Vector2(u, 1.0))
		_ribbon_mesh.surface_add_vertex(pt + side * half_w)
	_ribbon_mesh.surface_end()
