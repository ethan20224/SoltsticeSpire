extends StaticBody3D
class_name FlowExpress
## Golden Flow-Express Bridge / Shortcut Pad!
## Shimmers as a translucent golden mirage when Flow is low; snaps into gleaming solid golden geometry
## whenever the player hits Solar Overdrive (or Flow >= 0.72), rewarding momentum with express sky-lines!

@export var pad_size: Vector3 = Vector3(3.8, 0.36, 9.5)
@export var flow_threshold: float = 0.72

var _col: CollisionShape3D
var _mesh: MeshInstance3D
var _solid_mat: StandardMaterial3D
var _ghost_mat: StandardMaterial3D
var _is_solid: bool = false
var _t: float = 0.0


func _ready() -> void:
	add_to_group("flow_express")
	_build_node()
	_apply_state(false, true)


func _build_node() -> void:
	_col = CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = pad_size
	_col.shape = bx
	_col.position = Vector3(0.0, -pad_size.y * 0.5, 0.0)
	add_child(_col)

	_solid_mat = StandardMaterial3D.new()
	_solid_mat.albedo_color = Color(1.0, 0.84, 0.30)
	_solid_mat.metallic = 0.75
	_solid_mat.roughness = 0.20
	_solid_mat.emission_enabled = true
	_solid_mat.emission = Color(1.0, 0.78, 0.22)
	_solid_mat.emission_energy_multiplier = 1.55

	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.albedo_color = Color(1.0, 0.84, 0.36, 0.16)

	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = pad_size
	_mesh.mesh = bm
	_mesh.position = Vector3(0.0, -pad_size.y * 0.5, 0.0)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)


func _apply_state(make_solid: bool, instant: bool = false) -> void:
	if _is_solid == make_solid and not instant:
		return
	_is_solid = make_solid
	collision_layer = 1 if make_solid else 0
	if _col:
		_col.disabled = not make_solid
	if _mesh:
		_mesh.material_override = _solid_mat if make_solid else _ghost_mat
		if make_solid and not instant:
			_mesh.scale = Vector3(1.0, 0.35, 1.0)
			var tw := create_tween()
			tw.tween_property(_mesh, "scale", Vector3.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	var want_solid := GameState.solar_overdrive_active or GameState.current_flow >= flow_threshold
	_apply_state(want_solid, false)
	if not _is_solid and _ghost_mat:
		_ghost_mat.albedo_color.a = 0.12 + 0.06 * sin(_t * 3.2)
