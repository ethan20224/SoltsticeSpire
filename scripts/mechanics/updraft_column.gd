extends Area3D
class_name UpdraftColumn
## Swirling vertical thermal / wind updraft (World 1 Glasshouse Currents & World 3 Paper Crane Thermals).

@export var lift_accel: float = 52.0
@export var column_radius: float = 2.6
@export var column_height: float = 16.0
@export var stream_color: Color = Color(0.75, 0.98, 0.88)

var _bodies_inside: Array[Node3D] = []


func _ready() -> void:
	add_to_group("updraft_column")
	collision_layer = 0
	collision_mask = 2
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = column_radius
	cyl.height = column_height
	col.shape = cyl
	col.position = Vector3(0.0, column_height * 0.5, 0.0)
	add_child(col)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_build_particles()


func _build_particles() -> void:
	var gp := GPUParticles3D.new()
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gp.amount = 34
	gp.lifetime = maxf(0.8, column_height / 14.0)
	gp.position = Vector3(0.0, 0.5, 0.0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_radius = column_radius * 0.82
	pm.emission_ring_inner_radius = column_radius * 0.35
	pm.emission_ring_height = 1.0
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 8.0
	pm.initial_velocity_min = 12.0
	pm.initial_velocity_max = 16.5
	pm.gravity = Vector3.ZERO
	pm.tangential_accel_min = 4.0
	pm.tangential_accel_max = 7.0
	pm.scale_min = 0.08
	pm.scale_max = 0.18
	gp.process_material = pm

	var box := BoxMesh.new()
	box.size = Vector3(0.14, 1.35, 0.14)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(stream_color.r, stream_color.g, stream_color.b, 0.58)
	box.material = mat
	gp.draw_pass_1 = box
	add_child(gp)


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player") and not _bodies_inside.has(body):
		_bodies_inside.append(body)
		if body is PlayerController:
			body._has_air_dash = true
			body._has_double_jump = true


func _on_exit(body: Node3D) -> void:
	_bodies_inside.erase(body)


func _physics_process(_delta: float) -> void:
	for b in _bodies_inside:
		if is_instance_valid(b) and b is PlayerController:
			b.external_updraft += Vector3(0.0, lift_accel, 0.0)
