extends Area3D
class_name GravityBubble
## World 5 Translucent Iridescent Dream Gravity Bubble.
## Smoothly lowers gravity inside for dreamy soaring leaps, then snaps back to crisp physics outside!

@export var bubble_radius: float = 8.5
@export var gravity_scale: float = 0.42

var _sphere_mesh: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	add_to_group("gravity_bubble")
	collision_layer = 0
	collision_mask = 2
	var col := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = bubble_radius
	col.shape = sp
	add_child(col)

	_sphere_mesh = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = bubble_radius
	mesh.height = bubble_radius * 2.0
	mesh.radial_segments = 28
	mesh.rings = 16
	_sphere_mesh.mesh = mesh
	_sphere_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/gravity_bubble.gdshader")
	_sphere_mesh.material_override = mat
	add_child(_sphere_mesh)

	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if body is PlayerController:
		body.gravity_multiplier = gravity_scale
		body._has_double_jump = true
		body._has_air_dash = true
		AudioDirector.play_sfx("flow_chime", -4.0, 1.5)


func _on_exit(body: Node3D) -> void:
	if body is PlayerController:
		body.gravity_multiplier = 1.0


func _process(delta: float) -> void:
	_t += delta
	var s := 1.0 + sin(_t * 1.8) * 0.025
	if _sphere_mesh:
		_sphere_mesh.scale = Vector3(s, s, s)
		_sphere_mesh.rotation.y += delta * 0.18
