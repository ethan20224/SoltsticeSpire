extends Node3D
class_name MomentumRamp
## Downhill Momentum Chute + Upward Launch Lip!
## Paradoxically dive DOWN 5-8m along a glossy chute to accelerate up to 26 m/s,
## then hit the glowing launch lip to catapult +20-26m across open sky!

@export var ramp_length: float = 13.0
@export var ramp_width: float = 3.6
@export var drop_height: float = 5.5
@export var launch_speed_fwd: float = 22.0
@export var launch_speed_up: float = 24.5
@export var accent_color: Color = Color(1.0, 0.80, 0.30)

var _launch_cd: float = 0.0
var _slide_players: Array[PlayerController] = []


func _ready() -> void:
	add_to_group("momentum_ramp")
	_build_chute()


func _build_chute() -> void:
	var slope_angle := atan2(drop_height, ramp_length)
	var hyp := sqrt(ramp_length * ramp_length + drop_height * drop_height)

	var deck_mat := StandardMaterial3D.new()
	deck_mat.albedo_color = accent_color.darkened(0.28)
	deck_mat.metallic = 0.45
	deck_mat.roughness = 0.16

	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color = accent_color.lightened(0.15)

	# 1. Sloped downhill deck (runs from local (0, 0, 0) down to (0, -drop_height, -ramp_length))
	var slope_body := StaticBody3D.new()
	slope_body.position = Vector3(0.0, -drop_height * 0.5, -ramp_length * 0.5)
	slope_body.rotation.x = -slope_angle
	var scol := CollisionShape3D.new()
	var sbx := BoxShape3D.new()
	sbx.size = Vector3(ramp_width, 0.45, hyp)
	scol.shape = sbx
	scol.position = Vector3(0.0, -0.225, 0.0)
	slope_body.add_child(scol)

	var smesh := MeshInstance3D.new()
	var sm_box := BoxMesh.new()
	sm_box.size = Vector3(ramp_width, 0.42, hyp)
	smesh.mesh = sm_box
	smesh.material_override = deck_mat
	smesh.position = Vector3(0.0, -0.21, 0.0)
	slope_body.add_child(smesh)

	# Glowing speed chevron strips along the chute
	var strip_box := BoxMesh.new()
	strip_box.size = Vector3(0.14, 0.06, hyp - 0.4)
	for side: float in [-1.0, 1.0]:
		var strip := MeshInstance3D.new()
		strip.mesh = strip_box
		strip.material_override = glow_mat
		strip.position = Vector3(side * (ramp_width * 0.5 - 0.14), 0.02, 0.0)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		slope_body.add_child(strip)
	add_child(slope_body)

	# Acceleration zone along the chute (pulls player into fast smooth slide-boost downhill!)
	var accel_area := Area3D.new()
	accel_area.collision_layer = 0
	accel_area.collision_mask = 2
	accel_area.position = slope_body.position
	accel_area.rotation = slope_body.rotation
	var acol := CollisionShape3D.new()
	var abx := BoxShape3D.new()
	abx.size = Vector3(ramp_width, 2.2, hyp)
	acol.shape = abx
	acol.position = Vector3(0.0, 1.0, 0.0)
	accel_area.add_child(acol)
	add_child(accel_area)
	accel_area.body_entered.connect(func(b: Node3D) -> void:
		if b is PlayerController and not _slide_players.has(b):
			_slide_players.append(b as PlayerController)
	)
	accel_area.body_exited.connect(func(b: Node3D) -> void:
		if b is PlayerController:
			_slide_players.erase(b as PlayerController)
	)

	# 2. Upward curved launch lip at bottom end (0, -drop_height, -ramp_length)
	var lip_pos := Vector3(0.0, -drop_height + 0.45, -ramp_length - 1.4)
	var lip_body := StaticBody3D.new()
	lip_body.position = lip_pos
	lip_body.rotation_degrees.x = 24.0
	var lcol := CollisionShape3D.new()
	var lbx := BoxShape3D.new()
	lbx.size = Vector3(ramp_width + 0.3, 0.45, 3.2)
	lcol.shape = lbx
	lcol.position = Vector3(0.0, -0.225, 0.0)
	lip_body.add_child(lcol)

	var lmesh := MeshInstance3D.new()
	var lm_box := BoxMesh.new()
	lm_box.size = Vector3(ramp_width + 0.3, 0.45, 3.2)
	lmesh.mesh = lm_box
	lmesh.material_override = glow_mat
	lmesh.position = Vector3(0.0, -0.225, 0.0)
	lip_body.add_child(lmesh)
	add_child(lip_body)

	# Launch trigger pad on the upward lip
	var launch_area := Area3D.new()
	launch_area.collision_layer = 0
	launch_area.collision_mask = 2
	launch_area.position = lip_pos + Vector3(0.0, 1.0, -0.4)
	var tcol := CollisionShape3D.new()
	var tbx := BoxShape3D.new()
	tbx.size = Vector3(ramp_width + 0.6, 2.6, 3.4)
	tcol.shape = tbx
	launch_area.add_child(tcol)
	add_child(launch_area)
	launch_area.body_entered.connect(_on_lip_entered)


func _on_lip_entered(body: Node3D) -> void:
	if _launch_cd > 0.0 or not (body is PlayerController):
		return
	_launch_cd = 0.45
	var pc := body as PlayerController
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length_squared() > 0.001 else Vector3.FORWARD
	var boost_vel := fwd * launch_speed_fwd + Vector3(0.0, launch_speed_up, 0.0)
	pc.apply_ramp_boost(boost_vel)
	GameState.emit_callout("MOMENTUM LAUNCH!", "CHUTE CATAPULT!", accent_color.lightened(0.2))


func _physics_process(delta: float) -> void:
	_launch_cd = maxf(0.0, _launch_cd - delta)
	if _slide_players.is_empty():
		return
	var down_dir := (-global_transform.basis.z * ramp_length + Vector3(0.0, -drop_height, 0.0)).normalized()
	for pc in _slide_players:
		if not is_instance_valid(pc):
			continue
		if pc.is_on_floor():
			pc.velocity += down_dir * (38.0 * delta)
			var h_spd := Vector2(pc.velocity.x, pc.velocity.z).length()
			if h_spd > 26.0:
				var scale_f := 26.0 / h_spd
				pc.velocity.x *= scale_f
				pc.velocity.z *= scale_f
			pc.add_flow(delta * 0.28, false)
