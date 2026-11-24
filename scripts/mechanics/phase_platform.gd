extends StaticBody3D
class_name PhasePlatform
## World 4 & World 6 Celeste/Mario-Galaxy Style Phase-Swap Crystal Platform!
## phase_id = 0 -> Rose Glass (solid when GameState.phase_state == 0)
## phase_id = 1 -> Cyan Glass (solid when GameState.phase_state == 1)
## Every Jump or Air-Dash flips Rose <-> Cyan instantaneously with crisp audio-visual feedback!

@export var phase_id: int = 0  # 0 = Rose, 1 = Cyan
@export var slab_size: Vector3 = Vector3(4.2, 0.42, 4.2)

var _col: CollisionShape3D
var _mesh: MeshInstance3D
var _outline: MeshInstance3D
var _solid_mat: StandardMaterial3D
var _ghost_mat: StandardMaterial3D
var _is_solid: bool = false


func _ready() -> void:
	add_to_group("phase_platform")
	_build_node()
	GameState.phase_toggled.connect(_on_phase_toggled)
	_apply_phase(GameState.phase_state, true)


func _build_node() -> void:
	var base_col := Color(0.98, 0.40, 0.80) if phase_id == 0 else Color(0.30, 0.90, 1.0)

	_col = CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = slab_size
	_col.shape = bx
	_col.position = Vector3(0.0, -slab_size.y * 0.5, 0.0)
	add_child(_col)

	_solid_mat = StandardMaterial3D.new()
	_solid_mat.albedo_color = base_col
	_solid_mat.metallic = 0.25
	_solid_mat.roughness = 0.14
	_solid_mat.emission_enabled = true
	_solid_mat.emission = base_col
	_solid_mat.emission_energy_multiplier = 1.45

	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.albedo_color = Color(base_col.r, base_col.g, base_col.b, 0.16)

	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = slab_size
	_mesh.mesh = bm
	_mesh.position = Vector3(0.0, -slab_size.y * 0.5, 0.0)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)

	# Glowing outer border frame so even ghostly inactive slabs remain 100% readable in 3D space!
	_outline = MeshInstance3D.new()
	var obm := BoxMesh.new()
	obm.size = Vector3(slab_size.x + 0.12, 0.10, slab_size.z + 0.12)
	_outline.mesh = obm
	var omat := StandardMaterial3D.new()
	omat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	omat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	omat.albedo_color = Color(base_col.r, base_col.g, base_col.b, 0.65)
	_outline.material_override = omat
	_outline.position = Vector3(0.0, -0.05, 0.0)
	_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_outline)


func _on_phase_toggled(new_phase: int) -> void:
	_apply_phase(new_phase, false)


func _apply_phase(cur_phase: int, instant: bool = false) -> void:
	var make_solid := (cur_phase == phase_id)
	if _is_solid == make_solid and not instant:
		return
	_is_solid = make_solid
	collision_layer = 1 if make_solid else 0
	if _col:
		_col.disabled = not make_solid
	if _mesh:
		_mesh.material_override = _solid_mat if make_solid else _ghost_mat
		if make_solid and not instant:
			_mesh.scale = Vector3(1.06, 0.45, 1.06)
			var tw := create_tween()
			tw.tween_property(_mesh, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
