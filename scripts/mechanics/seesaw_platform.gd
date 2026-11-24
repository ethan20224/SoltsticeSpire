extends AnimatableBody3D
class_name SeesawPlatform
## World 1 Living Conservatory See-Saw Slab!
## Pivots smoothly under the player's foot weight: sprinting across keeps it level,
## lingering tips it steeply, and jumping off the rising end gives a springy seesaw pop!

@export var plank_length: float = 9.2
@export var plank_width: float = 3.2
@export var max_tilt_deg: float = 24.0
@export var accent_color: Color = Color(0.26, 0.68, 0.34)

var _base_basis: Basis
var _angle_rad: float = 0.0
var _ang_vel: float = 0.0
var _player_on: PlayerController = null


func _ready() -> void:
	sync_to_physics = true
	add_to_group("seesaw_platform")
	_base_basis = Basis.from_euler(rotation)
	_build_visual_and_collider()


func _build_visual_and_collider() -> void:
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(plank_width, 0.45, plank_length)
	col.shape = bx
	col.position = Vector3(0.0, -0.225, 0.0)
	add_child(col)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.84, 0.66, 0.48)
	stone_mat.roughness = 0.65

	var moss_mat := StandardMaterial3D.new()
	moss_mat.albedo_color = accent_color
	moss_mat.roughness = 0.78

	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.92, 0.72, 0.28)
	brass_mat.metallic = 0.80
	brass_mat.roughness = 0.28
	brass_mat.emission_enabled = true
	brass_mat.emission = Color(1.0, 0.76, 0.28)
	brass_mat.emission_energy_multiplier = 0.55

	var deck := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(plank_width, 0.42, plank_length)
	deck.mesh = dbox
	deck.material_override = stone_mat
	deck.position = Vector3(0.0, -0.21, 0.0)
	add_child(deck)

	var top_trim := MeshInstance3D.new()
	var tbox := BoxMesh.new()
	tbox.size = Vector3(plank_width - 0.3, 0.06, plank_length - 0.3)
	top_trim.mesh = tbox
	top_trim.material_override = moss_mat
	top_trim.position = Vector3(0.0, 0.02, 0.0)
	top_trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(top_trim)

	# Central brass fulcrum axle so player immediately reads "this tilts!"
	var axle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.34
	cyl.bottom_radius = 0.34
	cyl.height = plank_width + 0.9
	cyl.radial_segments = 14
	axle.mesh = cyl
	axle.material_override = brass_mat
	axle.rotation_degrees.z = 90.0
	axle.position = Vector3(0.0, -0.42, 0.0)
	add_child(axle)

	var sensor := Area3D.new()
	sensor.collision_layer = 0
	sensor.collision_mask = 2
	var scol := CollisionShape3D.new()
	var sbx := BoxShape3D.new()
	sbx.size = Vector3(plank_width + 0.4, 2.0, plank_length + 0.4)
	scol.shape = sbx
	scol.position = Vector3(0.0, 0.9, 0.0)
	sensor.add_child(scol)
	add_child(sensor)
	sensor.body_entered.connect(func(b: Node3D) -> void:
		if b is PlayerController:
			_player_on = b as PlayerController
	)
	sensor.body_exited.connect(func(b: Node3D) -> void:
		if b == _player_on:
			_player_on = null
	)


func _physics_process(delta: float) -> void:
	var torque := -_angle_rad * 4.2  # Gentle restoring spring
	if _player_on != null and is_instance_valid(_player_on) and _player_on.is_on_floor():
		var local_p := to_local(_player_on.global_position)
		var lever := clampf(local_p.z / maxf(plank_length * 0.5, 0.5), -1.0, 1.0)
		# Positive local Z weight pitches nose down (+X rotation)
		torque += lever * 5.8
	_ang_vel += torque * delta
	_ang_vel *= exp(-3.6 * delta)
	_angle_rad += _ang_vel * delta
	var max_r := deg_to_rad(max_tilt_deg)
	if absf(_angle_rad) > max_r:
		_angle_rad = clampf(_angle_rad, -max_r, max_r)
		_ang_vel *= -0.22
	basis = _base_basis * Basis(Vector3.RIGHT, _angle_rad)
