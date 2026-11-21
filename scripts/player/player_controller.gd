extends CharacterBody3D
class_name PlayerController
## High-craft 3rd-person Parkour & Platformer Controller for Solstice Spire.
## Combines Nintendo/Astro Bot tightness (coyote, jump buffer, asymmetric gravity, apex hang,
## auto ledge-mantle, projected landing ring) with kinetic parkour adrenaline (slide-long-jump,
## auto wall-run + wall-kick, air-dash, sky-dive meteor bounce, rhythm jump chains, clutch saves,
## max-flow solar charge, tether-orb snap, momentum flow meter, <0.35s rewind respawn).

signal high_water_planted(pos: Vector3, alt_m: float)
signal high_water_passed(alt_m: float)
signal victory_skydive_landed()

enum State { GROUNDED, AIR, SLIDE, DASH, WALL_RUN, MANTLE, TETHER_ZIP, REWIND, SKY_DIVE, VICTORY_DIVE }

# Core Tuned Kinematics (tight, predictable — NO involuntary Flow speed sabotage!)
@export var walk_speed: float = 7.2
@export var sprint_speed: float = 11.4
@export var flow_speed_bonus: float = 0.0
@export var ground_accel: float = 52.0
@export var ground_decel: float = 48.0
@export var air_accel: float = 28.0
@export var air_decel: float = 8.0

@export var jump_velocity: float = 11.6
@export var double_jump_velocity: float = 10.8
@export var gravity_up: float = 26.0
@export var gravity_down: float = 37.5
@export var gravity_apex: float = 18.0
@export var apex_threshold: float = 2.2

@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.14

@export var dash_speed: float = 25.0
@export var dash_duration: float = 0.17
@export var slide_speed: float = 15.2
@export var slide_duration: float = 0.48
@export var wall_run_min_speed: float = 11.8
@export var wall_run_gravity: float = 4.2
@export var wall_kick_up: float = 12.2
@export var wall_kick_out: float = 10.2

@onready var camera_rig: CameraRig = $CameraRig
@onready var char_rig: CharacterRig = $CharacterRig
@onready var landing_ring: MeshInstance3D = $LandingRing
@onready var floor_ray: RayCast3D = $FloorRay
@onready var wall_ray_l: RayCast3D = $WallRayL
@onready var wall_ray_r: RayCast3D = $WallRayR
@onready var mantle_low_ray: RayCast3D = $MantleLowRay
@onready var mantle_high_ray: RayCast3D = $MantleHighRay
@onready var mantle_down_ray: RayCast3D = $MantleDownRay

var state: State = State.GROUNDED
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _has_double_jump: bool = true
var _has_air_dash: bool = true
var _has_solar_charge: bool = false
var _sky_focus_active: bool = false
var _sky_focus_real_timer: float = 0.0
var _prev_phone_focus_btn: bool = false
var _can_jump_cut: bool = false
var _bounce_arc_timer: float = 0.0

var _dash_timer: float = 0.0
var _dash_dir: Vector3 = Vector3.FORWARD
var _slide_timer: float = 0.0
var _slide_dir: Vector3 = Vector3.FORWARD

# Vesper Origami Flutter-Glide
var _flutter_timer: float = 0.0
var _is_fluttering: bool = false
var _was_fluttering: bool = false

# Sky-Dive & Meteor Super-Bounce grace
var _recent_sky_dive_timer: float = 0.0

# Viral Heart-Attack Fall Drama
var _air_start_y: float = 0.0
var _fall_wind_intensity: float = 0.0

# Wall-Run
var _wall_normal: Vector3 = Vector3.ZERO
var _wall_side: float = 0.0  # -1 left, +1 right
var _wall_run_timer: float = 0.0
var _wall_lose_grace: float = 0.0
var _wall_cooldown: float = 0.0
var _last_wall_obj: Object = null
var _wall_run_node: Node = null
var _last_wall_hit_pos: Vector3 = Vector3.ZERO

# Mantle
var _mantle_start: Vector3 = Vector3.ZERO
var _mantle_target: Vector3 = Vector3.ZERO
var _mantle_t: float = 0.0

# Tether Orb Zip
var _tether_target_orb: Node3D = null
var _tether_dest: Vector3 = Vector3.ZERO
var _hovered_tether_orb: Node3D = null

# Stylistic Instant Rewind Respawn & 30s Window
var _rewind_start: Vector3 = Vector3.ZERO
var _rewind_dest: Vector3 = Vector3.ZERO
var _rewind_t: float = 0.0
var _unrecoverable_sky_timer: float = 0.0
var _rewind_locked_out: bool = false

# Clutch Save, Rhythm Chain, High-Water Flag & Ghost Recording
var _peak_fall_speed: float = 0.0
var _landing_chain_timer: float = 0.0
var _pre_land_horiz_speed: float = 0.0
var _rhythm_chain_count: int = 0
var _had_chain_source: bool = false
var _run_peak_pos: Vector3 = Vector3.ZERO
var _run_peak_y: float = 0.0
var _high_water_active: bool = false
var _ghost_sample_timer: float = 0.0

# World Environmental Modifiers
var gravity_multiplier: float = 1.0
var external_updraft: Vector3 = Vector3.ZERO
var _portal_cooldown: float = 0.0

# Dopamine Flow Meter
var flow_value: float = 0.0
var flow_streak: int = 0
var _flow_decay_delay: float = 0.0
var _step_timer: float = 0.0
var _was_on_floor: bool = true
var _landing_ring_mat: ShaderMaterial

var _input_analog_mag: float = 1.0

var controls_enabled: bool = true


func _ready() -> void:
	add_to_group("player")
	_setup_landing_ring()
	GameState.character_changed.connect(_on_character_changed)
	_on_character_changed(GameState.selected_character)
	_run_peak_pos = global_position
	_run_peak_y = global_position.y
	_air_start_y = global_position.y
	camera_rig.snap_to(global_position, 0.0)


func _setup_landing_ring() -> void:
	landing_ring.top_level = true
	_landing_ring_mat = ShaderMaterial.new()
	_landing_ring_mat.shader = load("res://assets/shaders/landing_ring.gdshader")
	landing_ring.material_override = _landing_ring_mat


func _on_character_changed(char_id: String) -> void:
	if _landing_ring_mat and GameState.CHARACTERS.has(char_id):
		_landing_ring_mat.set_shader_parameter("ring_color", GameState.CHARACTERS[char_id]["ring_color"])
	_configure_mantle_probes(char_id)


func _configure_mantle_probes(char_id: String) -> void:
	if char_id == "pip":
		mantle_low_ray.target_position = Vector3(0.0, 0.0, -0.92)
		mantle_high_ray.position.y = 2.12
		mantle_high_ray.target_position = Vector3(0.0, 0.0, -0.96)
		mantle_down_ray.target_position = Vector3(0.0, -2.02, 0.0)
	else:
		mantle_low_ray.target_position = Vector3(0.0, 0.0, -0.78)
		mantle_high_ray.position.y = 1.76
		mantle_high_ray.target_position = Vector3(0.0, 0.0, -0.82)
		mantle_down_ray.target_position = Vector3(0.0, -1.65, 0.0)


func _get_effective_coyote_time() -> float:
	return 0.17 if GameState.selected_character == "pip" else coyote_time


func _get_effective_mantle_max_dy() -> float:
	return 1.75 if GameState.selected_character == "pip" else 1.45


func _get_effective_dash_speed() -> float:
	return 27.8 if GameState.selected_character == "koko" else dash_speed


func _get_effective_slide_speed() -> float:
	return 16.6 if GameState.selected_character == "koko" else slide_speed


func _get_effective_slide_jump_bonus() -> float:
	return 3.0 if GameState.selected_character == "koko" else 1.2


func _is_slide_held() -> bool:
	if Input.is_action_pressed("slide"):
		return true
	if InputManager.is_gamepad_active() and InputManager.is_slide_held():
		return true
	if PhoneController.has_method("is_slide_held"):
		return bool(PhoneController.call("is_slide_held"))
	return false


func _play_chirp(kind: String) -> void:
	if AudioDirector.has_method("play_character_chirp"):
		AudioDirector.call("play_character_chirp", GameState.selected_character, kind)


func _set_fall_wind(intensity: float) -> void:
	if AudioDirector.has_method("set_fall_wind_intensity"):
		AudioDirector.call("set_fall_wind_intensity", intensity)


func is_sky_dive_recent() -> bool:
	return state == State.SKY_DIVE or _recent_sky_dive_timer > 0.0


func is_sky_focus_active() -> bool:
	return _sky_focus_active


func _end_sky_focus() -> void:
	if not _sky_focus_active:
		return
	_sky_focus_active = false
	_sky_focus_real_timer = 0.0
	Engine.time_scale = 1.0


func _try_activate_sky_focus() -> void:
	if _sky_focus_active:
		_end_sky_focus()
		return
	if not _has_solar_charge or is_on_floor() or state in [State.REWIND, State.VICTORY_DIVE, State.MANTLE]:
		return
	_has_solar_charge = false
	GameState.solar_charge_changed.emit(false)
	char_rig.set_solar_charge_glow(false)
	_sky_focus_active = true
	_sky_focus_real_timer = 1.50
	Engine.time_scale = 0.32
	AudioDirector.play_flow_chime(7, -2.0)
	char_rig.emit_burst(Vector3(0.0, 0.55, 0.0))
	InputManager.rumble("clutch")
	PhoneController.send_haptic("tether")
	GameState.emit_callout("SKY FOCUS", "1.5s Slow-Motion Precision", Color(0.55, 0.94, 1.0))


func _exit_tree() -> void:
	if _sky_focus_active:
		Engine.time_scale = 1.0


func on_shrine_activated() -> void:
	_rewind_locked_out = false
	GameState.set_rewind_window(0.0, false)


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or not GameState.is_playing or GameState.is_paused or GameState.is_cutscene:
		return
	if event.is_action_pressed("reset_checkpoint") and state != State.REWIND:
		_try_manual_rewind()
	elif event is InputEventKey:
		var kev := event as InputEventKey
		if kev.pressed and not kev.echo and (kev.physical_keycode == KEY_TAB or kev.physical_keycode == KEY_V):
			_try_activate_sky_focus()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_MIDDLE:
			_try_activate_sky_focus()


func _try_manual_rewind() -> void:
	if GameState.is_purist_mode():
		AudioDirector.play_sfx("ui_click", -4.0, 0.62)
		GameState.emit_callout("PURIST MODE", "No Rewind — Climb Every Meter!", Color(1.0, 0.56, 0.32))
		return
	var cp_y := GameState.current_checkpoint_pos.y
	if _rewind_locked_out:
		if not is_on_floor() and velocity.y < -12.0 and global_position.y < cp_y - 8.0:
			_rewind_locked_out = false
			GameState.set_rewind_window(0.0, false)
			begin_rewind_respawn(false)
			return
		AudioDirector.play_sfx("ui_click", -4.0, 0.62)
		GameState.emit_callout("REWIND EXPIRED", "Climb back up or reach a Shrine!", Color(1.0, 0.56, 0.32))
		return

	var midair_below := (not is_on_floor()) and (global_position.y < cp_y - 1.5)
	var window_ok := GameState.rewind_window_active and GameState.rewind_window_remaining > 0.0
	var near_shrine := absf(global_position.y - cp_y) < 6.0
	if midair_below or window_ok or near_shrine:
		GameState.set_rewind_window(0.0, false)
		begin_rewind_respawn(false)
	else:
		AudioDirector.play_sfx("ui_click", -5.0, 0.72)


func _physics_process(delta: float) -> void:
	if not controls_enabled or not GameState.is_playing or GameState.is_paused or GameState.is_cutscene:
		_end_sky_focus()
		_fall_wind_intensity = 0.0
		_set_fall_wind(0.0)
		_was_fluttering = false
		camera_rig.update_rig(global_position, Vector3.ZERO, 0.0, 0.0, false, delta)
		char_rig.update_animation(Vector3.ZERO, Vector3.ZERO, true, "GROUNDED", 0.0, 0.0, delta)
		landing_ring.visible = false
		return

	# Tick Sky Focus in real unscaled seconds so 1.5s always feels crisp & never sticks!
	if _sky_focus_active:
		var real_dt := delta / maxf(Engine.time_scale, 0.05)
		_sky_focus_real_timer -= real_dt
		if _sky_focus_real_timer <= 0.0 or is_on_floor():
			_end_sky_focus()
	else:
		var phone_l1 := PhoneController.is_active() and PhoneController.is_sprint_active() and not is_on_floor()
		var phone_focus_edge := phone_l1 and not _prev_phone_focus_btn
		_prev_phone_focus_btn = phone_l1
		if InputManager.consume_focus_just_pressed() or phone_focus_edge:
			_try_activate_sky_focus()

	_portal_cooldown = maxf(0.0, _portal_cooldown - delta)
	_wall_cooldown = maxf(0.0, _wall_cooldown - delta)
	_recent_sky_dive_timer = maxf(0.0, _recent_sky_dive_timer - delta)
	_bounce_arc_timer = maxf(0.0, _bounce_arc_timer - delta)
	_is_fluttering = false

	# Count down active 30-second Shrine Rewind window (never active in Purist Mode)
	if GameState.is_purist_mode():
		if GameState.rewind_window_active:
			GameState.set_rewind_window(0.0, false)
	elif GameState.rewind_window_active:
		var next_rem := GameState.rewind_window_remaining - delta
		if next_rem <= 0.0:
			_rewind_locked_out = true
			GameState.set_rewind_window(0.0, false)
			GameState.emit_callout("REWIND EXPIRED", "Climb back up or reach a Shrine!", Color(1.0, 0.56, 0.32))
		else:
			GameState.set_rewind_window(next_rem, true)

	# Record Ghost Sample every 0.15s while actively climbing
	if not GameState.has_finished:
		_ghost_sample_timer += delta
		if _ghost_sample_timer >= 0.15:
			_ghost_sample_timer = 0.0
			GameState.current_run_samples.append({
				"t": snappedf(GameState.run_time, 0.01),
				"p": [
					snappedf(global_position.x, 0.02),
					snappedf(global_position.y, 0.02),
					snappedf(global_position.z, 0.02),
				],
				"y": snappedf(char_rig.rotation.y, 0.02),
			})

	if state == State.REWIND:
		_end_sky_focus()
		_fall_wind_intensity = 0.0
		_set_fall_wind(0.0)
		_process_rewind(delta)
		return

	if state == State.MANTLE:
		_fall_wind_intensity = 0.0
		_set_fall_wind(0.0)
		_process_mantle(delta)
		return

	if state == State.TETHER_ZIP:
		_fall_wind_intensity = 0.0
		_set_fall_wind(0.0)
		_process_tether_zip(delta)
		return

	if state == State.VICTORY_DIVE:
		_process_victory_dive(delta)
		return

	# True Vertical Fall Stakes: only auto-rewind in Cloud Sea (y < -14) or unrecoverable outer sky!
	# In Purist Mode, safely drops you back to the Awakening Terrace (0m, World 1 start) instead of void soft-lock.
	var radial := Vector2(global_position.x, global_position.z).length()
	if global_position.y < -14.0:
		begin_rewind_respawn(true)
		return
	if not is_on_floor() and velocity.y < -4.0 and radial > 44.0 and not floor_ray.is_colliding():
		_unrecoverable_sky_timer += delta
		if _unrecoverable_sky_timer >= 1.1:
			begin_rewind_respawn(true)
			return
	else:
		_unrecoverable_sky_timer = 0.0

	# Check remote Shrine Rewind button from iPhone DualSense or Physical Gamepad
	var remote_rewind := PhoneController.consume_rewind_just_pressed() or InputManager.consume_rewind_just_pressed()
	if remote_rewind and state != State.REWIND:
		_try_manual_rewind()
		if state == State.REWIND:
			return

	# Input sampling (Keyboard WASD + Physical Gamepad Left Stick + iPhone DualSense Left Stick)
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if InputManager.is_gamepad_active():
		var gp_vec := InputManager.get_move_vector()
		if gp_vec.length_squared() > input_vec.length_squared():
			input_vec = gp_vec
	if PhoneController.is_active():
		var p_vec := PhoneController.get_move_vector()
		if p_vec.length_squared() > input_vec.length_squared():
			input_vec = p_vec
	_input_analog_mag = clampf(input_vec.length(), 0.0, 1.0)
	var cam_fwd := camera_rig.get_forward_xz()
	var cam_right := camera_rig.get_right_xz()
	var move_dir := (cam_right * input_vec.x - cam_fwd * input_vec.y)
	if move_dir.length_squared() > 0.001:
		move_dir = move_dir.normalized()

	var phone_jump_pressed := PhoneController.consume_jump_just_pressed()
	var gp_jump_pressed := InputManager.consume_jump_just_pressed()
	if Input.is_action_just_pressed("jump") or phone_jump_pressed or gp_jump_pressed:
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	var slide_just_pressed := Input.is_action_just_pressed("slide") or PhoneController.consume_slide_just_pressed() or InputManager.consume_slide_just_pressed()

	# Refresh best tether orb in sight for HUD lock-on indicator & context-smart Dash/Tether input
	_hovered_tether_orb = _find_best_tether_orb()

	# Dash / Tether Zip Trigger (E, Q, Right-Click, Shift in mid-air, Gamepad X/□/R2, or iPhone □ / R2)
	var shift_air_dash := Input.is_action_just_pressed("sprint") and (not is_on_floor() or _hovered_tether_orb != null)
	var phone_dash_pressed := PhoneController.consume_dash_just_pressed()
	var gp_dash_pressed := InputManager.consume_dash_just_pressed()
	if Input.is_action_just_pressed("dash") or shift_air_dash or phone_dash_pressed or gp_dash_pressed:
		if _hovered_tether_orb != null:
			_start_tether_zip(_hovered_tether_orb)
			return
		elif _has_air_dash and state != State.DASH:
			_start_dash(move_dir if move_dir.length_squared() > 0.01 else cam_fwd, false)

	# Sky-Dive entry while airborne & past apex / descending
	if state == State.AIR and not is_on_floor() and velocity.y < 3.5 and _is_slide_held():
		state = State.SKY_DIVE
		_is_fluttering = false
		char_rig.trigger_squash(Vector3(0.78, 1.32, 0.78))

	# Track peak fall speed for Clutch Save
	if not is_on_floor():
		_peak_fall_speed = minf(_peak_fall_speed, velocity.y)

	# State processing
	match state:
		State.DASH:
			_process_dash(delta)
		State.SLIDE:
			_process_slide(move_dir, delta)
		State.WALL_RUN:
			_process_wall_run(move_dir, delta)
		State.SKY_DIVE:
			_process_sky_dive(move_dir, delta)
		_:
			_process_standard_move(move_dir, slide_just_pressed, delta)

	if _is_fluttering and not _was_fluttering:
		_play_chirp("hop")
	_was_fluttering = _is_fluttering

	if state == State.SKY_DIVE:
		_recent_sky_dive_timer = 0.14

	# Apply world updrafts smoothly
	if external_updraft.length_squared() > 0.001:
		if external_updraft.y > 0.1:
			_can_jump_cut = false
		velocity += external_updraft * delta
		velocity.y = minf(velocity.y, 19.5)
		external_updraft = Vector3.ZERO

	var pre_move_horiz := Vector2(velocity.x, velocity.z).length()
	var pre_move_state := state

	move_and_slide()

	# Landing detection, Viral Heart-Attack Fall Drama, Rhythm Jump Chain & 30s Shrine Rewind trigger
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = _get_effective_coyote_time()
		_has_double_jump = true
		_has_air_dash = true
		_can_jump_cut = false
		_bounce_arc_timer = 0.0
		_flutter_timer = 0.0
		_last_wall_obj = null
		_peak_fall_speed = 0.0

		if not _was_on_floor:
			var drop_m := _air_start_y - global_position.y
			var heart_drop := drop_m >= 25.0
			if heart_drop:
				AudioDirector.play_sfx("heart_drop", -2.5, 1.0)
				camera_rig.add_shake(0.34)
				InputManager.rumble("land")
				GameState.emit_callout(
					"-%.0fm DROP!" % drop_m,
					"%.0fm → %.0fm" % [maxf(0.0, _air_start_y), maxf(0.0, global_position.y)],
					Color(1.0, 0.44, 0.28)
				)

			# Rhythm Jump Chain window opens if landing fast or off an aerial move
			if pre_move_horiz > 9.5 or _had_chain_source:
				_landing_chain_timer = 0.16
				_pre_land_horiz_speed = pre_move_horiz
			else:
				_rhythm_chain_count = 0
			_had_chain_source = false

			if state != State.SLIDE:
				var heavy_dive := pre_move_state == State.SKY_DIVE
				state = State.GROUNDED
				char_rig.trigger_squash(Vector3(1.36, 0.64, 1.36) if heavy_dive else Vector3(1.24, 0.76, 1.24))
				char_rig.emit_burst(Vector3(0.0, 0.05, 0.0))
				camera_rig.add_land_dip(0.28 if heavy_dive else 0.18)
				if heavy_dive:
					camera_rig.add_shake(0.22)
				AudioDirector.play_sfx("land_thud", -3.5 if heavy_dive else -5.0, 0.84 if heavy_dive else randf_range(0.92, 1.08))
				PhoneController.send_haptic("land")
				if not heart_drop:
					InputManager.rumble("land")
		else:
			_landing_chain_timer = maxf(0.0, _landing_chain_timer - delta)
			if _landing_chain_timer <= 0.0 and state != State.SLIDE:
				_rhythm_chain_count = 0

		# High-Point Personal Best tracking (grounded safe high water)
		if global_position.y > _run_peak_y + 0.5:
			_run_peak_y = global_position.y
			_run_peak_pos = global_position
			if _high_water_active:
				_high_water_active = false
				high_water_passed.emit(_run_peak_y)
				GameState.emit_callout("HIGH POINT SURPASSED!", "%.0fm" % _run_peak_y, Color(1.0, 0.86, 0.34))

		# 30-second Shrine Rewind window check on safe landing (disabled in Purist Mode)
		if not GameState.is_purist_mode():
			var cp_y := GameState.current_checkpoint_pos.y
			if global_position.y <= cp_y - 6.0:
				if not GameState.rewind_window_active and not _rewind_locked_out:
					GameState.set_rewind_window(GameState.REWIND_WINDOW_MAX, true)
			elif global_position.y >= cp_y - 3.0:
				_rewind_locked_out = false
				if GameState.rewind_window_active:
					GameState.set_rewind_window(0.0, false)
	else:
		if _was_on_floor:
			_air_start_y = global_position.y
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
		_landing_chain_timer = 0.0
		if state == State.GROUNDED:
			state = State.AIR
		if not GameState.is_purist_mode() and global_position.y >= GameState.current_checkpoint_pos.y - 1.5:
			_rewind_locked_out = false
			if GameState.rewind_window_active:
				GameState.set_rewind_window(0.0, false)
		if _high_water_active and global_position.y > _run_peak_y + 0.5:
			_high_water_active = false
			_run_peak_y = global_position.y
			_run_peak_pos = global_position
			high_water_passed.emit(_run_peak_y)
			GameState.emit_callout("HIGH POINT SURPASSED!", "%.0fm" % _run_peak_y, Color(1.0, 0.86, 0.34))

	# Dynamic fall-rush + high-altitude vertigo edge-look wind intensity
	var vertigo_wind := 0.0
	if global_position.y > 60.0 and camera_rig.pitch < -0.50:
		vertigo_wind = clampf((-camera_rig.pitch - 0.50) / 0.55, 0.0, 1.0) * clampf((global_position.y - 60.0) / 340.0, 0.25, 1.0) * 0.42
	if not on_floor and velocity.y < -15.0:
		var target_wind := clampf((-velocity.y - 15.0) / 21.0, 0.0, 1.0)
		_fall_wind_intensity = lerpf(_fall_wind_intensity, maxf(target_wind, vertigo_wind), clampf(delta * 8.0, 0.0, 1.0))
	else:
		_fall_wind_intensity = lerpf(_fall_wind_intensity, vertigo_wind, clampf(delta * 6.0, 0.0, 1.0))
		if _fall_wind_intensity < 0.005:
			_fall_wind_intensity = 0.0
	_set_fall_wind(_fall_wind_intensity)

	# Plant High-Water Flag when falling > 10m below peak
	if not _high_water_active and _run_peak_y >= 12.0 and global_position.y < _run_peak_y - 10.0:
		_high_water_active = true
		high_water_planted.emit(_run_peak_pos, _run_peak_y)

	_was_on_floor = on_floor

	# Check Automatic Wall-Run & Auto Ledge-Mantle when airborne!
	if state == State.AIR:
		if _try_start_mantle(move_dir):
			return
		_try_start_wall_run(move_dir)

	# Flow Meter decay, speed-build & Max-Flow Solar Charge
	var horiz_spd := Vector2(velocity.x, velocity.z).length()
	if horiz_spd > 9.5 and (on_floor or state in [State.WALL_RUN, State.DASH, State.SLIDE]):
		flow_value = minf(1.0, flow_value + delta * 0.16)
		_flow_decay_delay = 1.6
	else:
		_flow_decay_delay = maxf(0.0, _flow_decay_delay - delta)
		if _flow_decay_delay <= 0.0:
			flow_value = maxf(0.0, flow_value - delta * 0.28)
			if flow_value <= 0.02:
				flow_streak = 0

	if flow_value >= 0.85 and flow_streak >= 3 and not _has_solar_charge:
		_has_solar_charge = true
		GameState.solar_charge_changed.emit(true)
		char_rig.set_solar_charge_glow(true)
		AudioDirector.play_flow_chime(6, -1.5)
		GameState.emit_callout("SKY FOCUS READY!", "Press %s mid-air for 1.5s Slow-Mo" % InputManager.get_glyph("focus"), Color(0.55, 0.94, 1.0))

	# Rhythmic Tactile Footsteps
	if on_floor and state == State.GROUNDED and horiz_spd > 1.8:
		_step_timer -= delta * (horiz_spd / 7.5)
		if _step_timer <= 0.0:
			_step_timer = 0.34
			AudioDirector.play_footstep(GameState.current_world_idx)

	GameState.update_altitude(global_position.y)
	GameState.update_flow(flow_value, flow_streak)

	# Sync visual probes, camera & expressive character animations
	_update_probes_orientation(move_dir)
	_update_landing_ring()
	var wall_roll := (-9.5 * _wall_side) if state == State.WALL_RUN else 0.0
	var anim_state := "FLUTTER" if _is_fluttering else str(State.keys()[state])
	camera_rig.update_rig(global_position, velocity, flow_value, wall_roll, state == State.DASH or state == State.SKY_DIVE, delta)
	char_rig.update_animation(velocity, move_dir, on_floor, anim_state, _wall_side, flow_value, delta)


func _process_standard_move(move_dir: Vector3, slide_pressed: bool, delta: float) -> void:
	# 100% predictable speed control: Flow (Solar Resonance) NEVER forces sprint or adds unwanted speed!
	var gp_sprint := InputManager.is_gamepad_active() and InputManager.is_sprint_held()
	var sprinting := Input.is_action_pressed("sprint") or gp_sprint or PhoneController.is_sprint_active()
	var base_spd := sprint_speed if sprinting else walk_speed
	var throttle := 1.0 if sprinting else clampf(_input_analog_mag, 0.20, 1.0)
	var max_spd := base_spd * throttle
	var eff_slide_speed := _get_effective_slide_speed()

	# Slide-Dive entry (C / Ctrl / Gamepad B/○/L2 / iPhone ○ or L2 while running!)
	if is_on_floor() and slide_pressed and (Vector2(velocity.x, velocity.z).length() > 4.2 or move_dir.length_squared() > 0.2):
		state = State.SLIDE
		_slide_timer = slide_duration
		_slide_dir = move_dir if move_dir.length_squared() > 0.01 else Vector3(velocity.x, 0.0, velocity.z).normalized()
		if _slide_dir.length_squared() < 0.01:
			_slide_dir = camera_rig.get_forward_xz()
		velocity.x = _slide_dir.x * eff_slide_speed
		velocity.z = _slide_dir.z * eff_slide_speed
		_had_chain_source = true
		char_rig.trigger_squash(Vector3(1.26, 0.68, 1.26))
		char_rig.emit_burst(Vector3(0.0, 0.1, 0.0))
		AudioDirector.play_sfx("slide", -4.0, randf_range(0.95, 1.08))
		PhoneController.send_haptic("slide")
		InputManager.rumble("slide")
		return

	# Horizontal acceleration/deceleration (crisp on ground, responsive in air)
	var accel := ground_accel if is_on_floor() else air_accel
	var decel := ground_decel if is_on_floor() else air_decel
	if move_dir.length_squared() > 0.001:
		var target_vx := move_dir.x * max_spd
		var target_vz := move_dir.z * max_spd
		# Preserve higher momentum (e.g. from Long-Jump / Portal / Bounce / Rhythm Chain!) when steering in air
		if not is_on_floor():
			var cur_h := Vector2(velocity.x, velocity.z)
			if cur_h.length() > max_spd and cur_h.normalized().dot(Vector2(move_dir.x, move_dir.z)) > 0.4:
				var keep := cur_h.length()
				target_vx = move_dir.x * keep
				target_vz = move_dir.z * keep
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)
		velocity.z = move_toward(velocity.z, target_vz, accel * delta)
	else:
		var eff_decel := (air_decel * 0.25) if (not is_on_floor() and _bounce_arc_timer > 0.0) else decel
		velocity.x = move_toward(velocity.x, 0.0, eff_decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, eff_decel * delta)

	# Jump & Double-Jump with Coyote Time + Jump Buffer + Rhythm Jump Chain
	if _jump_buffer_timer > 0.0:
		if _coyote_timer > 0.0:
			if _landing_chain_timer > 0.0 and move_dir.length_squared() > 0.01:
				var chain_spd := clampf(maxf(_pre_land_horiz_speed, Vector2(velocity.x, velocity.z).length()) + 1.0, sprint_speed, 17.5)
				velocity.x = move_dir.x * chain_spd
				velocity.z = move_dir.z * chain_spd
				_landing_chain_timer = 0.0
				_rhythm_chain_count += 1
				_had_chain_source = true
				add_flow(0.18, true)
				char_rig.emit_burst(Vector3(0.0, 0.12, 0.0))
				if _rhythm_chain_count >= 2:
					GameState.emit_callout("PERFECT CHAIN x%d" % _rhythm_chain_count, "MOMENTUM BOOST", Color(0.50, 0.95, 1.0))
			velocity.y = jump_velocity
			_coyote_timer = 0.0
			_jump_buffer_timer = 0.0
			_can_jump_cut = true
			_bounce_arc_timer = 0.0
			_flutter_timer = 0.0
			state = State.AIR
			char_rig.trigger_squash(Vector3(0.80, 1.26, 0.80))
			char_rig.emit_burst(Vector3(0.0, 0.08, 0.0))
			AudioDirector.play_sfx("jump", -3.0, randf_range(0.96, 1.06))
			_play_chirp("hop")
			PhoneController.send_haptic("jump")
			InputManager.rumble("jump")
		elif _has_double_jump:
			velocity.y = double_jump_velocity
			_has_double_jump = false
			_jump_buffer_timer = 0.0
			_can_jump_cut = false
			_bounce_arc_timer = 0.0
			_flutter_timer = 0.0
			state = State.AIR
			char_rig.trigger_double_jump_flip()
			AudioDirector.play_sfx("double_jump", -2.5, randf_range(0.98, 1.08))
			_play_chirp("hop")
			PhoneController.send_haptic("double_jump")
			InputManager.rumble("double_jump")

	# Asymmetric Crisp Gravity + Apex Hang-Time + Vesper Origami Flutter-Glide!
	if not is_on_floor():
		var gp_jump_held := InputManager.is_gamepad_active() and InputManager.is_jump_held()
		var jump_held := Input.is_action_pressed("jump") or gp_jump_held or PhoneController.is_jump_held()
		if GameState.selected_character == "vesper" and state == State.AIR and velocity.y < -1.5 and jump_held and _flutter_timer < 0.85:
			_is_fluttering = true
			_flutter_timer += delta
			if velocity.y < -4.2:
				velocity.y = move_toward(velocity.y, -4.2, 55.0 * delta)
			else:
				velocity.y = maxf(velocity.y - gravity_apex * 0.45 * gravity_multiplier * delta, -4.2)
			return

		if velocity.y <= 0.0:
			_can_jump_cut = false
		var g := gravity_up
		if absf(velocity.y) < apex_threshold:
			g = gravity_apex
		elif velocity.y < 0.0:
			g = gravity_down
		# Short-hop variable jump height ONLY for player ground jumps if Jump released early
		# (NEVER cut bounce pads, wall-kicks, double-jumps, updrafts, portals, or tether zips!)
		if _can_jump_cut and velocity.y > 4.0 and not jump_held:
			g *= 1.55
		velocity.y -= g * gravity_multiplier * delta
		velocity.y = maxf(velocity.y, -38.0)


func start_victory_skydive() -> void:
	## Launches the celebratory 1,085m -> 0m Victory Skydive past all 6 illuminated realms
	## right back to the Awakening Terrace beside The Dawnbreaker Airship!
	state = State.VICTORY_DIVE
	GameState.victory_skydive_active = true
	global_position = Vector3(0.0, 1085.5, 11.8)
	velocity = Vector3(0.0, 5.5, 16.5)
	_can_jump_cut = false
	_bounce_arc_timer = 0.0
	_peak_fall_speed = 0.0
	camera_rig.snap_to(global_position, PI)
	camera_rig.pitch = -0.68
	char_rig.clear_trail()
	char_rig.set_solar_charge_glow(true)
	char_rig.emit_burst(Vector3(0.0, 0.5, 0.0))
	AudioDirector.play_sfx("dash", -0.5, 1.15)
	_play_chirp("joy")
	GameState.emit_callout("VICTORY SKYDIVE!", "Soar 1,085m → 0m Back to The Dawnbreaker!", Color(1.0, 0.88, 0.36))


func _process_victory_dive(delta: float) -> void:
	# Responsive 3D aerial steering + flare-to-glide (Jump) + turbo-dive (Slide)
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if InputManager.is_gamepad_active():
		var gp_vec := InputManager.get_move_vector()
		if gp_vec.length_squared() > input_vec.length_squared():
			input_vec = gp_vec
	if PhoneController.is_active():
		var p_vec := PhoneController.get_move_vector()
		if p_vec.length_squared() > input_vec.length_squared():
			input_vec = p_vec

	var cam_fwd := camera_rig.get_forward_xz()
	var cam_right := camera_rig.get_right_xz()
	var steer_dir := cam_right * input_vec.x - cam_fwd * input_vec.y
	if steer_dir.length_squared() > 0.001:
		steer_dir = steer_dir.normalized()

	var gp_jump := InputManager.is_gamepad_active() and InputManager.is_jump_held()
	var flare_held := Input.is_action_pressed("jump") or gp_jump or PhoneController.is_jump_held()
	var fast_held := _is_slide_held()

	var target_fall := -24.0 if flare_held else (-60.0 if fast_held else -40.0)
	var steer_spd := 28.0 if flare_held else 24.0

	# Below Y = 110m, gently home toward the Awakening Terrace (0, 0.5, 26) for a heroic touchdown!
	var terrace_target := Vector3(0.0, 0.5, 26.0)
	if global_position.y < 110.0:
		var home_t := clampf((110.0 - global_position.y) / 95.0, 0.0, 1.0)
		var to_home := Vector3(terrace_target.x - global_position.x, 0.0, terrace_target.z - global_position.z)
		var desired_h := to_home * clampf(home_t * 2.2, 0.4, 2.2) + steer_dir * (steer_spd * (1.0 - home_t * 0.75))
		velocity.x = lerpf(velocity.x, clampf(desired_h.x, -30.0, 30.0), clampf(delta * 4.2, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, clampf(desired_h.z, -30.0, 30.0), clampf(delta * 4.2, 0.0, 1.0))
		target_fall = lerpf(target_fall, -12.0, home_t * home_t)
	else:
		if steer_dir.length_squared() > 0.001:
			velocity.x = move_toward(velocity.x, steer_dir.x * steer_spd, 36.0 * delta)
			velocity.z = move_toward(velocity.z, steer_dir.z * steer_spd, 36.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	velocity.y = move_toward(velocity.y, target_fall, 42.0 * delta)
	move_and_slide()

	var wind_t := clampf((-velocity.y - 14.0) / 38.0, 0.25, 1.0)
	_fall_wind_intensity = lerpf(_fall_wind_intensity, wind_t, clampf(delta * 6.0, 0.0, 1.0))
	_set_fall_wind(_fall_wind_intensity)

	GameState.update_altitude(global_position.y)
	_update_landing_ring()
	camera_rig.update_rig(global_position, velocity, 1.0, 0.0, fast_held, delta)
	char_rig.update_animation(velocity, steer_dir, false, "FLUTTER" if flare_held else "SKY_DIVE", 0.0, 1.0, delta)

	if global_position.y <= 1.25 or (global_position.y < 22.0 and is_on_floor()):
		global_position = Vector3(terrace_target.x, 0.65, terrace_target.z)
		velocity = Vector3.ZERO
		state = State.GROUNDED
		GameState.victory_skydive_active = false
		_fall_wind_intensity = 0.0
		_set_fall_wind(0.0)
		char_rig.set_solar_charge_glow(false)
		char_rig.trigger_squash(Vector3(1.42, 0.58, 1.42))
		char_rig.emit_burst(Vector3(0.0, 0.25, 0.0))
		camera_rig.add_shake(0.38)
		AudioDirector.play_sfx("summit_fanfare", -1.5, 1.08)
		AudioDirector.play_sfx("firework_pop", -1.0, 1.0)
		_play_chirp("joy")
		InputManager.rumble("summit")
		PhoneController.send_haptic("shard")
		GameState.emit_callout("HOME AGAIN!", "The Dawnbreaker Welcomes the Sun-Bringer", Color(1.0, 0.88, 0.40))
		victory_skydive_landed.emit()


func _process_sky_dive(move_dir: Vector3, delta: float) -> void:
	if not _is_slide_held():
		state = State.AIR
		return

	# Allow double-jump cancel out of Sky-Dive
	if _jump_buffer_timer > 0.0 and _has_double_jump:
		velocity.y = double_jump_velocity
		_has_double_jump = false
		_jump_buffer_timer = 0.0
		_flutter_timer = 0.0
		state = State.AIR
		char_rig.trigger_double_jump_flip()
		AudioDirector.play_sfx("double_jump", -2.5, randf_range(0.98, 1.08))
		PhoneController.send_haptic("double_jump")
		return

	var dive_max_spd := sprint_speed + 1.5
	var dive_accel := air_accel * 1.35
	if move_dir.length_squared() > 0.001:
		var target_vx := move_dir.x * dive_max_spd
		var target_vz := move_dir.z * dive_max_spd
		var cur_h := Vector2(velocity.x, velocity.z)
		if cur_h.length() > dive_max_spd and cur_h.normalized().dot(Vector2(move_dir.x, move_dir.z)) > 0.4:
			var keep := cur_h.length()
			target_vx = move_dir.x * keep
			target_vz = move_dir.z * keep
		velocity.x = move_toward(velocity.x, target_vx, dive_accel * delta)
		velocity.z = move_toward(velocity.z, target_vz, dive_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, air_decel * 0.65 * delta)
		velocity.z = move_toward(velocity.z, 0.0, air_decel * 0.65 * delta)

	velocity.y -= gravity_down * 1.55 * gravity_multiplier * delta
	velocity.y = maxf(velocity.y, -46.0)


func _process_slide(move_dir: Vector3, delta: float) -> void:
	_slide_timer -= delta
	var eff_slide_speed := _get_effective_slide_speed()
	# Allow subtle steering during slide
	if move_dir.length_squared() > 0.01:
		_slide_dir = _slide_dir.lerp(move_dir, clampf(delta * 4.5, 0.0, 1.0)).normalized()
	var spd := lerpf(eff_slide_speed, walk_speed * 0.9, 1.0 - clampf(_slide_timer / slide_duration, 0.0, 1.0))
	velocity.x = _slide_dir.x * spd
	velocity.z = _slide_dir.z * spd

	if not is_on_floor():
		velocity.y -= gravity_down * gravity_multiplier * delta

	# Slide → Long-Jump Momentum Chain!
	if _jump_buffer_timer > 0.0 and (_coyote_timer > 0.0 or is_on_floor()):
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_can_jump_cut = false
		_bounce_arc_timer = 0.0
		_flutter_timer = 0.0
		_had_chain_source = true
		state = State.AIR
		var long_spd := eff_slide_speed + _get_effective_slide_jump_bonus()
		velocity.x = _slide_dir.x * long_spd
		velocity.z = _slide_dir.z * long_spd
		velocity.y = jump_velocity * 0.92
		add_flow(0.22, true)
		char_rig.trigger_squash(Vector3(0.76, 1.32, 0.76))
		char_rig.emit_burst(Vector3(0.0, 0.12, 0.0))
		camera_rig.add_shake(0.22)
		AudioDirector.play_sfx("jump", -1.5, 1.18)
		PhoneController.send_haptic("jump")
		return

	if _slide_timer <= 0.0 or not is_on_floor():
		state = State.GROUNDED if is_on_floor() else State.AIR


func _start_dash(dir: Vector3, is_solar_dash: bool = false) -> void:
	state = State.DASH
	if not is_solar_dash:
		_has_air_dash = false
	_dash_timer = dash_duration
	_had_chain_source = true
	_dash_dir = Vector3(dir.x, 0.0, dir.z).normalized()
	if _dash_dir.length_squared() < 0.01:
		_dash_dir = camera_rig.get_forward_xz()
	var eff_dash := _get_effective_dash_speed() * (1.08 if is_solar_dash else 1.0)
	velocity = _dash_dir * eff_dash
	velocity.y = 2.2 if is_solar_dash else 1.4  # Tiny crisp anti-drop lift
	add_flow(0.18, false)
	char_rig.trigger_squash(Vector3(0.74, 0.82, 1.42))
	char_rig.emit_burst(Vector3(0.0, 0.65, 0.0))
	camera_rig.add_shake(0.36 if is_solar_dash else 0.32)
	camera_rig.trigger_hitstop(0.025)
	AudioDirector.play_sfx("dash", -1.0 if is_solar_dash else -1.5, 1.18 if is_solar_dash else randf_range(0.96, 1.06))
	PhoneController.send_haptic("dash")


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	var eff_dash := _get_effective_dash_speed()
	velocity.x = _dash_dir.x * eff_dash
	velocity.z = _dash_dir.z * eff_dash
	velocity.y = lerpf(velocity.y, 0.0, clampf(delta * 10.0, 0.0, 1.0))
	if _dash_timer <= 0.0:
		velocity.x = _dash_dir.x * (sprint_speed + 1.0)
		velocity.z = _dash_dir.z * (sprint_speed + 1.0)
		state = State.GROUNDED if is_on_floor() else State.AIR


func _try_trigger_clutch_save() -> void:
	if _peak_fall_speed <= -15.5:
		_peak_fall_speed = 0.0
		camera_rig.trigger_hitstop(0.035)
		char_rig.emit_burst(Vector3(0.0, 0.55, 0.0))
		add_flow(0.32, true)
		GameState.emit_callout("CLUTCH SAVE!", "+FLOW SURGE", Color(1.0, 0.85, 0.30))
		PhoneController.send_haptic("tether")
	else:
		_peak_fall_speed = 0.0


func _try_start_wall_run(move_dir: Vector3) -> void:
	if _wall_cooldown > 0.0 or velocity.y < -14.0 or move_dir.length_squared() < 0.1:
		return
	var hit_l := wall_ray_l.is_colliding()
	var hit_r := wall_ray_r.is_colliding()
	if not hit_l and not hit_r:
		return

	var ray := wall_ray_r if hit_r else wall_ray_l
	var side := 1.0 if hit_r else -1.0
	var collider := ray.get_collider()
	if collider == null or collider == _last_wall_obj:
		return
	var is_wall_runnable := false
	if collider is Node and (collider as Node).is_in_group("wall_run"):
		is_wall_runnable = true
	if not is_wall_runnable:
		return

	var n := ray.get_collision_normal()
	if absf(n.y) > 0.25:
		return  # Must be a near-vertical wall

	state = State.WALL_RUN
	_wall_normal = Vector3(n.x, 0.0, n.z).normalized()
	_wall_side = side
	_wall_run_timer = 1.65
	_wall_lose_grace = 0.14
	_last_wall_obj = collider
	_wall_run_node = collider as Node
	_last_wall_hit_pos = ray.get_collision_point()
	_has_air_dash = true
	_has_double_jump = true
	_flutter_timer = 0.0
	velocity.y = maxf(velocity.y, 2.8)
	_try_trigger_clutch_save()
	add_flow(0.20, false)
	char_rig.emit_burst(Vector3(0.0, 0.6, 0.0))
	if _wall_run_node and _wall_run_node.has_method("on_wall_run_contact"):
		_wall_run_node.on_wall_run_contact()


func _process_wall_run(_move_dir: Vector3, delta: float) -> void:
	_wall_run_timer -= delta
	var active_ray := wall_ray_r if _wall_side > 0.0 else wall_ray_l
	if active_ray.is_colliding():
		_wall_lose_grace = 0.14
		var n := active_ray.get_collision_normal()
		if absf(n.y) <= 0.35:
			_wall_normal = Vector3(n.x, 0.0, n.z).normalized()
		_last_wall_hit_pos = active_ray.get_collision_point()
	else:
		_wall_lose_grace -= delta

	if _wall_lose_grace <= 0.0 or _wall_run_timer <= 0.0 or is_on_floor():
		state = State.AIR
		_wall_cooldown = 0.20
		return

	# Tangent along wall matching forward facing
	var tangent := _wall_normal.cross(Vector3.UP)
	if tangent.dot(camera_rig.get_forward_xz()) < 0.0:
		tangent = -tangent
	tangent = tangent.normalized()

	var run_spd := maxf(Vector2(velocity.x, velocity.z).length(), wall_run_min_speed)
	velocity.x = tangent.x * run_spd - _wall_normal.x * 2.2
	velocity.z = tangent.z * run_spd - _wall_normal.z * 2.2
	velocity.y = maxf(velocity.y - wall_run_gravity * delta, -2.2)

	# Crunchy Musical Wall-Kick!
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer = 0.0
		state = State.AIR
		_wall_cooldown = 0.22
		_has_air_dash = true
		_has_double_jump = true
		_can_jump_cut = false
		_bounce_arc_timer = 0.0
		_flutter_timer = 0.0
		_had_chain_source = true
		velocity = tangent * (run_spd * 0.92) + _wall_normal * wall_kick_out + Vector3(0.0, wall_kick_up, 0.0)
		add_flow(0.28, true)
		char_rig.trigger_squash(Vector3(0.78, 1.30, 0.78))
		char_rig.emit_burst(Vector3(0.0, 0.5, 0.0))
		camera_rig.add_shake(0.32)
		camera_rig.trigger_hitstop(0.030)
		if _wall_run_node and _wall_run_node.has_method("on_wall_kick"):
			_wall_run_node.on_wall_kick(_last_wall_hit_pos)
		else:
			AudioDirector.play_sfx("wall_kick", -1.5, randf_range(0.96, 1.08))
		PhoneController.send_haptic("wall_kick")


func _try_start_mantle(move_dir: Vector3) -> bool:
	if velocity.y < -12.0 or move_dir.length_squared() < 0.05:
		return false
	if not mantle_low_ray.is_colliding() or mantle_high_ray.is_colliding():
		return false
	if not mantle_down_ray.is_colliding():
		return false
	var top_normal := mantle_down_ray.get_collision_normal()
	if top_normal.y < 0.72:
		return false
	var ledge_pt := mantle_down_ray.get_collision_point()
	var dy := ledge_pt.y - global_position.y
	if dy < 0.25 or dy > _get_effective_mantle_max_dy():
		return false

	state = State.MANTLE
	_mantle_start = global_position
	_mantle_target = ledge_pt + Vector3(0.0, 0.08, 0.0)
	_mantle_t = 0.0
	velocity = Vector3.ZERO
	_has_double_jump = true
	_has_air_dash = true
	_can_jump_cut = false
	_bounce_arc_timer = 0.0
	_flutter_timer = 0.0
	_try_trigger_clutch_save()
	char_rig.trigger_squash(Vector3(0.84, 1.22, 0.84))
	AudioDirector.play_sfx("jump", -5.0, 1.25)
	return true


func _process_mantle(delta: float) -> void:
	_mantle_t += delta / 0.17
	var t := clampf(_mantle_t, 0.0, 1.0)
	var ease_t := 1.0 - pow(1.0 - t, 3.0)
	var arc := Vector3(0.0, sin(t * PI) * 0.35, 0.0)
	global_position = _mantle_start.lerp(_mantle_target, ease_t) + arc
	if t >= 1.0:
		state = State.GROUNDED
		var fwd := camera_rig.get_forward_xz()
		velocity = fwd * 5.5


func _find_best_tether_orb() -> Node3D:
	var orbs := get_tree().get_nodes_in_group("tether_orb")
	if orbs.is_empty():
		return null
	var cam := camera_rig.camera
	var cam_pos := cam.global_position
	var cam_fwd := -cam.global_transform.basis.z
	var best: Node3D = null
	var best_score := -1.0
	for o in orbs:
		var orb := o as Node3D
		if orb == null or not orb.visible:
			continue
		var d_vec: Vector3 = orb.global_position - global_position
		var dist: float = d_vec.length()
		if dist < 2.5 or dist > 25.0:
			continue
		var dir_cam: Vector3 = (orb.global_position - cam_pos).normalized()
		var align: float = dir_cam.dot(cam_fwd)
		if align < 0.58:
			continue
		var score: float = align * 2.0 - (dist / 25.0) * 0.6
		if score > best_score:
			best_score = score
			best = orb
	return best


func get_hovered_tether_orb() -> Node3D:
	return _hovered_tether_orb


func _start_tether_zip(orb: Node3D) -> void:
	state = State.TETHER_ZIP
	_tether_target_orb = orb
	_tether_dest = orb.global_position + Vector3(0.0, 0.9, 0.0)
	_has_air_dash = true
	_has_double_jump = true
	_flutter_timer = 0.0
	_had_chain_source = true
	_try_trigger_clutch_save()
	add_flow(0.30, true)
	camera_rig.add_shake(0.32)
	camera_rig.trigger_hitstop(0.025)
	char_rig.emit_burst(Vector3(0.0, 0.6, 0.0))
	AudioDirector.play_sfx("tether_zip", -1.0, randf_range(0.96, 1.12))
	PhoneController.send_haptic("tether")
	if orb.has_method("pulse_activate"):
		orb.pulse_activate()


func _process_tether_zip(delta: float) -> void:
	var to_dest := _tether_dest - global_position
	var dist := to_dest.length()
	var step := 36.0 * delta
	if dist <= step + 0.45:
		global_position = _tether_dest
		var fwd := camera_rig.get_forward_xz()
		velocity = fwd * 12.5 + Vector3(0.0, 12.4, 0.0)
		_can_jump_cut = false
		_bounce_arc_timer = 0.0
		state = State.AIR
		char_rig.trigger_double_jump_flip()
		return
	velocity = to_dest.normalized() * 36.0
	move_and_slide()


func begin_rewind_respawn(count_as_fall: bool = true) -> void:
	if state == State.REWIND:
		return
	state = State.REWIND
	_unrecoverable_sky_timer = 0.0
	_rewind_locked_out = false
	GameState.set_rewind_window(0.0, false)
	if count_as_fall:
		GameState.record_fall()
	flow_value = 0.0
	flow_streak = 0
	if _has_solar_charge:
		_has_solar_charge = false
		GameState.solar_charge_changed.emit(false)
		char_rig.set_solar_charge_glow(false)
	GameState.update_flow(0.0, 0)
	_rewind_start = global_position
	_rewind_dest = GameState.current_checkpoint_pos + Vector3(0.0, 0.35, 0.0)
	_rewind_t = 0.0
	velocity = Vector3.ZERO
	AudioDirector.play_sfx("rewind", -2.0, 1.0)
	PhoneController.send_haptic("rewind")
	camera_rig.add_shake(0.25)


func _process_rewind(delta: float) -> void:
	_rewind_t += delta / 0.34
	var t := clampf(_rewind_t, 0.0, 1.0)
	var ease_t := t * t * (3.0 - 2.0 * t)
	var mid_lift := Vector3(0.0, sin(t * PI) * 4.5, 0.0)
	global_position = _rewind_start.lerp(_rewind_dest, ease_t) + mid_lift
	camera_rig.update_rig(global_position, Vector3.ZERO, 0.5, 0.0, true, delta)
	char_rig.update_animation(Vector3.UP * 8.0, Vector3.FORWARD, false, "REWIND", 0.0, 0.8, delta)
	landing_ring.visible = false
	if t >= 1.0:
		global_position = _rewind_dest
		velocity = Vector3.ZERO
		_has_double_jump = true
		_has_air_dash = true
		_flutter_timer = 0.0
		_peak_fall_speed = 0.0
		gravity_multiplier = 1.0
		state = State.GROUNDED
		char_rig.clear_trail()
		char_rig.trigger_squash(Vector3(1.22, 0.78, 1.22))
		char_rig.emit_burst(Vector3(0.0, 0.25, 0.0))


func apply_bounce(impulse: Vector3, reset_air: bool = true, is_meteor: bool = false) -> void:
	var meteor_active := is_meteor or is_sky_dive_recent()
	_recent_sky_dive_timer = 0.0
	_had_chain_source = true
	_can_jump_cut = false
	_bounce_arc_timer = 0.78
	_flutter_timer = 0.0

	if not meteor_active:
		_try_trigger_clutch_save()
	else:
		_peak_fall_speed = 0.0

	# Guide cleanly along the bounce pad's designed arc while preserving running momentum!
	var boost_h := Vector2(impulse.x, impulse.z)
	if boost_h.length_squared() > 0.01:
		var boost_len := boost_h.length()
		var boost_dir := boost_h.normalized()
		var cur_h := Vector2(velocity.x, velocity.z)
		var cur_spd := cur_h.length()
		if cur_spd > 1.2:
			var incoming_dir := cur_h.normalized()
			var align := incoming_dir.dot(boost_dir)
			var boost_weight := 0.65 if align > 0.2 else 0.78
			var blended_dir := boost_dir * boost_weight + incoming_dir * (1.0 - boost_weight)
			if blended_dir.length_squared() < 0.001:
				blended_dir = boost_dir
			else:
				blended_dir = blended_dir.normalized()
			var target_spd := clampf(maxf(cur_spd, maxf(boost_len, 6.8)), 6.8, 12.0)
			velocity.x = blended_dir.x * target_spd
			velocity.z = blended_dir.y * target_spd
		else:
			var target_spd := maxf(boost_len, 6.5)
			velocity.x = boost_dir.x * target_spd
			velocity.z = boost_dir.y * target_spd

	state = State.AIR
	velocity.y = minf(impulse.y * 1.35, 33.5) if meteor_active else impulse.y

	if reset_air:
		_has_double_jump = true
		_has_air_dash = true

	if meteor_active:
		add_flow(0.40, true)
		char_rig.trigger_squash(Vector3(0.66, 1.48, 0.66))
		char_rig.emit_burst(Vector3(0.0, 0.15, 0.0))
		camera_rig.add_shake(0.45)
		camera_rig.trigger_hitstop(0.040)
		GameState.emit_callout("METEOR BOUNCE!", "SUPER LAUNCH", Color(1.0, 0.78, 0.24))
		PhoneController.send_haptic("tether")
	else:
		add_flow(0.24, true)
		char_rig.trigger_squash(Vector3(0.74, 1.38, 0.74))
		char_rig.emit_burst(Vector3(0.0, 0.1, 0.0))
		camera_rig.add_shake(0.28)
		camera_rig.trigger_hitstop(0.028)


func apply_portal_warp(dest_pos: Vector3, exit_dir: Vector3, launch_speed: float) -> void:
	if _portal_cooldown > 0.0:
		return
	_portal_cooldown = 0.55
	global_position = dest_pos
	var dir := exit_dir.normalized()
	velocity = dir * maxf(velocity.length() * 1.15, launch_speed)
	velocity.y = maxf(velocity.y, 7.5)
	_has_double_jump = true
	_has_air_dash = true
	_can_jump_cut = false
	_bounce_arc_timer = 0.45
	_flutter_timer = 0.0
	_peak_fall_speed = 0.0
	_had_chain_source = true
	state = State.AIR
	add_flow(0.35, true)
	char_rig.clear_trail()
	char_rig.trigger_double_jump_flip()
	camera_rig.yaw = atan2(-dir.x, -dir.z)
	camera_rig.add_shake(0.40)
	camera_rig.trigger_hitstop(0.032)
	AudioDirector.play_sfx("portal_warp", -1.0, 1.0)


func teleport_to_checkpoint(pos: Vector3, yaw_rad: float = 0.0) -> void:
	_end_sky_focus()
	GameState.victory_skydive_active = false
	global_position = pos + Vector3(0.0, 0.35, 0.0)
	velocity = Vector3.ZERO
	_has_double_jump = true
	_has_air_dash = true
	_can_jump_cut = false
	_bounce_arc_timer = 0.0
	_flutter_timer = 0.0
	_peak_fall_speed = 0.0
	_unrecoverable_sky_timer = 0.0
	_rewind_locked_out = false
	_landing_chain_timer = 0.0
	_rhythm_chain_count = 0
	_had_chain_source = false
	_recent_sky_dive_timer = 0.0
	gravity_multiplier = 1.0
	state = State.GROUNDED
	if GameState.current_run_samples.is_empty():
		_run_peak_pos = global_position
		_run_peak_y = global_position.y
		_high_water_active = false
		_ghost_sample_timer = 0.0
		_has_solar_charge = false
		char_rig.set_solar_charge_glow(false)
		GameState.solar_charge_changed.emit(false)
	GameState.set_rewind_window(0.0, false)
	char_rig.clear_trail()
	camera_rig.snap_to(global_position, yaw_rad)


func add_flow(amount: float, play_chime: bool = true) -> void:
	flow_value = clampf(flow_value + amount, 0.0, 1.0)
	_flow_decay_delay = 2.4
	if play_chime:
		flow_streak += 1
		AudioDirector.play_flow_chime(flow_streak - 1)


func _update_probes_orientation(move_dir: Vector3) -> void:
	var fwd := move_dir if move_dir.length_squared() > 0.02 else camera_rig.get_forward_xz()
	var yaw := atan2(-fwd.x, -fwd.z)
	wall_ray_l.rotation.y = yaw
	wall_ray_r.rotation.y = yaw
	mantle_low_ray.rotation.y = yaw
	mantle_high_ray.rotation.y = yaw
	var is_pip := GameState.selected_character == "pip"
	var reach_fwd := 0.84 if is_pip else 0.72
	var down_y := 2.18 if is_pip else 1.82
	mantle_down_ray.position = Vector3(-sin(yaw) * reach_fwd, down_y, -cos(yaw) * reach_fwd)


func _update_landing_ring() -> void:
	if floor_ray.is_colliding():
		var hit_pt := floor_ray.get_collision_point()
		var dist := global_position.y - hit_pt.y
		landing_ring.visible = dist >= -0.2 and dist < 30.0
		landing_ring.global_position = hit_pt + Vector3(0.0, 0.04, 0.0)
		var h_fac := clampf(dist / 12.0, 0.0, 1.0)
		var ring_scale := lerpf(0.95, 1.55, h_fac)
		landing_ring.scale = Vector3(ring_scale, 1.0, ring_scale)
		if _landing_ring_mat:
			_landing_ring_mat.set_shader_parameter("height_factor", h_fac)
	else:
		landing_ring.visible = false
