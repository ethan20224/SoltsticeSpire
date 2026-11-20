extends Node3D
class_name CameraRig
## Smooth 3rd-person orbit camera with dynamic Flow FOV, wall-run roll, micro hit-stop, and screen shake.

@export var follow_height: float = 1.65
@export var base_distance: float = 5.4
@export var base_fov: float = 72.0
@export var max_flow_fov: float = 82.0
@export var pitch_min_deg: float = -65.0
@export var pitch_max_deg: float = 58.0

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var yaw: float = 0.0
var pitch: float = -0.22
var target_roll: float = 0.0
var target_fov: float = 72.0
var _current_roll: float = 0.0
var _shake_trauma: float = 0.0
var _land_dip: float = 0.0
var _hitstop_active: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	top_level = true
	spring_arm.spring_length = base_distance
	camera.fov = base_fov


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_playing or GameState.is_paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := GameState.mouse_sensitivity
		yaw -= event.relative.x * sens
		var y_sign := 1.0 if GameState.invert_y else -1.0
		pitch += event.relative.y * sens * y_sign
		pitch = clampf(pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func update_rig(target_pos: Vector3, player_vel: Vector3, flow: float, wall_roll_deg: float, is_dashing: bool, delta: float) -> void:
	# Apply iPhone DualSense Right-Stick Orbit + Direct Touchpad/Thumb-Drag/Gyro Look Delta
	if GameState.is_playing and not GameState.is_paused and PhoneController.is_active():
		var sens_mult := GameState.mouse_sensitivity / 0.0024
		var y_sign := 1.0 if GameState.invert_y else -1.0
		var look_d := PhoneController.consume_look_delta()
		if look_d.length_squared() > 0.0001:
			var drag_sens := GameState.mouse_sensitivity * 1.45
			yaw -= look_d.x * drag_sens
			pitch += look_d.y * drag_sens * y_sign
		var r_stick := PhoneController.get_look_stick()
		if r_stick.length_squared() > 0.001:
			var sx := signf(r_stick.x) * pow(absf(r_stick.x), 1.55)
			var sy := signf(r_stick.y) * pow(absf(r_stick.y), 1.55)
			yaw -= sx * 3.1 * sens_mult * delta
			pitch += sy * 2.2 * sens_mult * y_sign * delta
		pitch = clampf(pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))

	# Smoothly follow target with subtle vertical responsiveness and landing dip spring
	_land_dip = lerpf(_land_dip, 0.0, clampf(delta * 12.0, 0.0, 1.0))
	var desired_pos := target_pos + Vector3(0.0, follow_height + _land_dip, 0.0)
	var follow_lerp := clampf(delta * 18.0, 0.0, 1.0)
	global_position = global_position.lerp(desired_pos, follow_lerp)

	# Smooth yaw/pitch/roll orientation
	target_roll = deg_to_rad(wall_roll_deg)
	_current_roll = lerpf(_current_roll, target_roll, clampf(delta * 10.0, 0.0, 1.0))
	rotation = Vector3(pitch, yaw, _current_roll)

	# Speed & Flow driven FOV + subtle pull-back
	var horiz_spd := Vector2(player_vel.x, player_vel.z).length()
	var spd_t := clampf((horiz_spd - 6.0) / 14.0, 0.0, 1.0)
	target_fov = base_fov + (max_flow_fov - base_fov) * maxf(flow * 0.85, spd_t * 0.75) + (5.5 if is_dashing else 0.0)
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 8.0, 0.0, 1.0))

	var target_dist := base_distance + spd_t * 0.75 + (0.6 if is_dashing else 0.0)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, target_dist, clampf(delta * 6.0, 0.0, 1.0))

	# Trauma micro screen-shake
	if _shake_trauma > 0.001:
		var mag := _shake_trauma * _shake_trauma * 0.24
		camera.h_offset = _rng.randf_range(-mag, mag)
		camera.v_offset = _rng.randf_range(-mag, mag)
		_shake_trauma = maxf(0.0, _shake_trauma - delta * 2.8)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func snap_to(target_pos: Vector3, new_yaw: float) -> void:
	yaw = new_yaw
	pitch = -0.22
	global_position = target_pos + Vector3(0.0, follow_height, 0.0)
	rotation = Vector3(pitch, yaw, 0.0)


func add_shake(amount: float) -> void:
	_shake_trauma = clampf(_shake_trauma + amount, 0.0, 1.0)


func add_land_dip(strength: float) -> void:
	_land_dip = clampf(_land_dip - strength, -0.35, 0.0)


func trigger_hitstop(duration: float = 0.028) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false


func get_forward_xz() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.FORWARD


func get_right_xz() -> Vector3:
	var r := global_transform.basis.x
	r.y = 0.0
	return r.normalized() if r.length_squared() > 0.0001 else Vector3.RIGHT
