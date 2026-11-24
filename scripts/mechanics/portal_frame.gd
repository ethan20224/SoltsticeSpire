extends Node3D
class_name PortalFrame
## World 4 Surreal Baroque Gilded Picture-Frame Momentum Portal.
## Jumping through an Entry Frame warps & slingshots the player out of the Exit Frame with boosted momentum!

@export var exit_target_pos: Vector3 = Vector3.ZERO
@export var exit_launch_dir: Vector3 = Vector3(0.0, 0.45, -1.0)
@export var exit_launch_speed: float = 22.0
@export var is_exit_only: bool = false
@export var preserve_entry_momentum: bool = false
@export var is_horizontal_floor: bool = false
@export var frame_size: Vector2 = Vector2(3.6, 4.6)

var _vortex_mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("portal_frame")
	_build_vortex()
	if not is_exit_only:
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		var col := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		if is_horizontal_floor:
			bx.size = Vector3(frame_size.x + 0.8, 1.8, frame_size.y + 0.8)
			col.position = Vector3(0.0, 0.45, 0.0)
		else:
			bx.size = Vector3(frame_size.x, frame_size.y, 1.4)
			col.position = Vector3(0.0, frame_size.y * 0.5, 0.0)
		col.shape = bx
		area.add_child(col)
		add_child(area)
		area.body_entered.connect(_on_body_entered)


func _build_vortex() -> void:
	_vortex_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = frame_size
	_vortex_mesh.mesh = quad
	if is_horizontal_floor:
		_vortex_mesh.position = Vector3(0.0, 0.12, 0.0)
		_vortex_mesh.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	else:
		_vortex_mesh.position = Vector3(0.0, frame_size.y * 0.5, 0.0)
	_vortex_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/portal_vortex.gdshader")
	if is_exit_only:
		mat.set_shader_parameter("inner_color", Color(0.55, 0.98, 1.0))
		mat.set_shader_parameter("mid_color", Color(0.24, 0.58, 0.98))
	elif preserve_entry_momentum:
		mat.set_shader_parameter("inner_color", Color(1.0, 0.80, 0.34))
		mat.set_shader_parameter("mid_color", Color(0.98, 0.42, 0.78))
	_vortex_mesh.material_override = mat
	add_child(_vortex_mesh)


func _on_body_entered(body: Node3D) -> void:
	if is_exit_only or not body.is_in_group("player"):
		return
	if body.has_method("apply_portal_warp"):
		body.apply_portal_warp(exit_target_pos, exit_launch_dir, exit_launch_speed, preserve_entry_momentum)
