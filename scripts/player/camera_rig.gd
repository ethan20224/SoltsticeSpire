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
var _stick_ramp: float = 0.85
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	top_level = true
	spring_arm.spring_length = base_distance
	_sync_fov_from_settings()
	camera.fov = base_fov
	GameState.graphics_settings_changed.connect(_sync_fov_from_settings)


func _sync_fov_from_settings() -> void:
	base_fov = GameState.camera_fov
	max_flow_fov = GameState.camera_fov + 10.0


func _process(delta: float) -> void:
	if not GameState.is_playing or GameState.is_paused:
		_stick_ramp = 0.85
		return

	var sens: float = GameState.mouse_sensitivity
	var y_sign: float = 1.0 if GameState.invert_y else -1.0
	var r_stick := Vector2.ZERO
	var has_stick_source := false

	if PhoneController.is_active():
		has_stick_source = true
		var look_d: Vector2 = PhoneController.consume_look_delta()
		if look_d.length_squared() > 0.0001:
			yaw -= look_d.x * sens * 2.6
			pitch += look_d.y * sens * 2.6 * y_sign
		r_stick = PhoneController.get_look_stick()

	if InputManager.is_gamepad_active():
		has_stick_source = true
		var gp_stick: Vector2 = InputManager.get_look_stick()
		if gp_stick.length_squared() > r_stick.length_squared():
			r_stick = gp_stick

	if has_stick_source:
		var real_dt := delta / maxf(Engine.time_scale, 0.05)
		var mag: float = clampf(r_stick.length(), 0.0, 1.0)
		if mag > 0.001:
			if mag > 0.85:
				_stick_ramp = move_toward(_stick_ramp, 1.15, (0.30 / 0.18) * real_dt)
			else:
				_stick_ramp = move_toward(_stick_ramp, 0.85, (0.30 / 0.12) * real_dt)
			var dir: Vector2 = r_stick / mag
			var curved: float = lerpf(mag, mag * mag * mag, 0.55)
			var yaw_rate: float = sens * 2250.0 * _stick_ramp
			var pitch_rate: float = sens * 1650.0 * _stick_ramp
			yaw -= dir.x * curved * yaw_rate * real_dt
			pitch += dir.y * curved * pitch_rate * y_sign * real_dt
		else:
			_stick_ramp = 0.85

		pitch = clampf(pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	else:
		_stick_ramp = 0.85

	rotation = Vector3(pitch, yaw, _current_roll)


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
	var real_dt := delta / maxf(Engine.time_scale, 0.05)

	# Authentic Vertigo Edge-Look: peering steeply down from high altitudes widens perspective subtly!
	var vertigo_t := 0.0
	if target_pos.y > 55.0 and pitch < -0.50:
		vertigo_t = clampf((-pitch - 0.50) / 0.58, 0.0, 1.0) * clampf((target_pos.y - 55.0) / 360.0, 0.30, 1.0)

	# Smoothly follow target with subtle vertical responsiveness and landing dip spring
	_land_dip = lerpf(_land_dip, 0.0, clampf(real_dt * 12.0, 0.0, 1.0))
	var desired_pos := target_pos + Vector3(0.0, follow_height + _land_dip + vertigo_t * 0.32, 0.0)
	var follow_lerp := clampf(real_dt * 18.0, 0.0, 1.0)
	global_position = global_position.lerp(desired_pos, follow_lerp)

	# Smooth yaw/pitch/roll orientation
	target_roll = deg_to_rad(wall_roll_deg)
	_current_roll = lerpf(_current_roll, target_roll, clampf(real_dt * 10.0, 0.0, 1.0))
	rotation = Vector3(pitch, yaw, _current_roll)

	# Clean Speed, Vertigo Edge-Look, Fall-Rush & Victory Skydive FOV (NO jarring Flow walk distortion!)
	var horiz_spd := Vector2(player_vel.x, player_vel.z).length()
	var spd_t := clampf((horiz_spd - 8.0) / 14.0, 0.0, 1.0)
	var fall_fov := 0.0
	if player_vel.y < -18.0:
		fall_fov = clampf((-player_vel.y - 18.0) / 18.0, 0.0, 1.0) * 6.5
	var dive_bonus := 11.0 if GameState.victory_skydive_active else 0.0
	var focus_zoom := -4.5 if Engine.time_scale < 0.5 and not _hitstop_active else 0.0
	target_fov = base_fov + spd_t * 5.0 + flow * 1.8 + (4.5 if is_dashing else 0.0) + fall_fov + vertigo_t * 7.5 + dive_bonus + focus_zoom
	camera.fov = lerpf(camera.fov, target_fov, clampf(real_dt * 8.0, 0.0, 1.0))

	var target_dist := base_distance + spd_t * 0.65 + (0.5 if is_dashing else 0.0) + (1.6 if GameState.victory_skydive_active else 0.0)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, target_dist, clampf(real_dt * 6.0, 0.0, 1.0))

	# Trauma micro screen-shake
	if _shake_trauma > 0.001:
		var mag := _shake_trauma * _shake_trauma * 0.24
		camera.h_offset = _rng.randf_range(-mag, mag)
		camera.v_offset = _rng.randf_range(-mag, mag)
		_shake_trauma = maxf(0.0, _shake_trauma - real_dt * 2.8)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


func snap_to(target_pos: Vector3, new_yaw: float) -> void:
	yaw = new_yaw
	pitch = -0.22
	_stick_ramp = 0.85
	global_position = target_pos + Vector3(0.0, follow_height, 0.0)
	rotation = Vector3(pitch, yaw, 0.0)


func add_shake(amount: float) -> void:
	_shake_trauma = clampf(_shake_trauma + amount, 0.0, 1.0)


func add_land_dip(strength: float) -> void:
	_land_dip = clampf(_land_dip - strength, -0.35, 0.0)


func trigger_hitstop(duration: float = 0.028) -> void:
	# Never override active Sky Focus Slow-Mo!
	if _hitstop_active or Engine.time_scale < 0.5:
		return
	_hitstop_active = true
	Engine.time_scale = 0.08
	await get_tree().create_timer(duration, true, false, true).timeout
	if Engine.time_scale < 0.2:
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
