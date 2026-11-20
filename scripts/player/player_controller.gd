extends CharacterBody3D
class_name PlayerController
## High-craft 3rd-person Parkour & Platformer Controller for Solstice Spire.
## Combines Nintendo/Astro Bot tightness (coyote, jump buffer, asymmetric gravity, apex hang,
## auto ledge-mantle, projected landing ring) with kinetic parkour adrenaline (slide-long-jump,
## auto wall-run + wall-kick, air-dash, tether-orb snap, momentum flow meter, <0.4s rewind respawn).

enum State { GROUNDED, AIR, SLIDE, DASH, WALL_RUN, MANTLE, TETHER_ZIP, REWIND }

# Core Tuned Kinematics (identical across Pip, Koko, and Vesper)
@export var walk_speed: float = 7.2
@export var sprint_speed: float = 11.4
@export var flow_speed_bonus: float = 2.0
@export var ground_accel: float = 52.0
@export var ground_decel: float = 48.0
@export var air_accel: float = 28.0
@export var air_decel: float = 8.0

@export var jump_velocity: float = 11.8
@export var double_jump_velocity: float = 10.6
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

var _dash_timer: float = 0.0
var _dash_dir: Vector3 = Vector3.FORWARD
var _slide_timer: float = 0.0
var _slide_dir: Vector3 = Vector3.FORWARD

# Wall-Run
var _wall_normal: Vector3 = Vector3.ZERO
var _wall_side: float = 0.0  # -1 left, +1 right
var _wall_run_timer: float = 0.0
var _wall_cooldown: float = 0.0
var _last_wall_obj: Object = null
var _wall_run_node: Node = null

# Mantle
var _mantle_start: Vector3
var _mantle_target: Vector3
var _mantle_t: float = 0.0

# Tether Orb Zip
var _tether_target_orb: Node3D = null
var _tether_dest: Vector3 = Vector3.ZERO
var _hovered_tether_orb: Node3D = null

# Stylistic Instant Rewind Respawn (< 0.36s!)
var _rewind_start: Vector3
var _rewind_dest: Vector3
var _rewind_t: float = 0.0
var _last_safe_y: float = 0.0

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

var controls_enabled: bool = true


func _ready() -> void:
	add_to_group("player")
	_setup_landing_ring()
	GameState.character_changed.connect(_on_character_changed)
	_on_character_changed(GameState.selected_character)
	_last_safe_y = global_position.y
	camera_rig.snap_to(global_position, 0.0)


func _setup_landing_ring() -> void:
	landing_ring.top_level = true
	_landing_ring_mat = ShaderMaterial.new()
	_landing_ring_mat.shader = load("res://assets/shaders/landing_ring.gdshader")
	landing_ring.material_override = _landing_ring_mat


func _on_character_changed(char_id: String) -> void:
	if _landing_ring_mat and GameState.CHARACTERS.has(char_id):
		_landing_ring_mat.set_shader_parameter("ring_color", GameState.CHARACTERS[char_id]["ring_color"])


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or not GameState.is_playing or GameState.is_paused:
		return
	if event.is_action_pressed("character_1"):
		GameState.set_character("pip")
		AudioDirector.play_sfx("ui_click", -2.0, 1.0)
	elif event.is_action_pressed("character_2"):
		GameState.set_character("koko")
		AudioDirector.play_sfx("ui_click", -2.0, 1.15)
	elif event.is_action_pressed("character_3"):
		GameState.set_character("vesper")
		AudioDirector.play_sfx("ui_click", -2.0, 1.3)
	elif event.is_action_pressed("reset_checkpoint") and state != State.REWIND:
		begin_rewind_respawn(false)


func _physics_process(delta: float) -> void:
	if not controls_enabled or not GameState.is_playing or GameState.is_paused:
		camera_rig.update_rig(global_position, Vector3.ZERO, 0.0, 0.0, false, delta)
		char_rig.update_animation(Vector3.ZERO, Vector3.ZERO, true, "GROUNDED", 0.0, 0.0, delta)
		landing_ring.visible = false
		return

	_portal_cooldown = maxf(0.0, _portal_cooldown - delta)
	_wall_cooldown = maxf(0.0, _wall_cooldown - delta)

	if state == State.REWIND:
		_process_rewind(delta)
		return

	if state == State.MANTLE:
		_process_mantle(delta)
		return

	if state == State.TETHER_ZIP:
		_process_tether_zip(delta)
		return

	# Check fall kill threshold (dynamic to last checkpoint & safe height - generous but sharp!)
	var fall_limit := minf(GameState.current_checkpoint_pos.y, _last_safe_y) - 24.0
	if global_position.y < fall_limit:
		begin_rewind_respawn(true)
		return

	# Input sampling
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_fwd := camera_rig.get_forward_xz()
	var cam_right := camera_rig.get_right_xz()
	var move_dir := (cam_right * input_vec.x - cam_fwd * input_vec.y)
	if move_dir.length_squared() > 0.001:
		move_dir = move_dir.normalized()

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(0.0, _jump_buffer_timer - delta)

	# Refresh best tether orb in sight for HUD lock-on indicator & context-smart Dash/Tether input
	_hovered_tether_orb = _find_best_tether_orb()

	# Dash / Tether Zip Trigger (E, Q, Right-Click, or Shift in mid-air / locked onto a tether orb)
	var shift_air_dash := Input.is_action_just_pressed("sprint") and (not is_on_floor() or _hovered_tether_orb != null)
	if Input.is_action_just_pressed("dash") or shift_air_dash:
		if _hovered_tether_orb != null:
			_start_tether_zip(_hovered_tether_orb)
			return
		elif _has_air_dash and state != State.DASH:
			_start_dash(move_dir if move_dir.length_squared() > 0.01 else cam_fwd)

	# State processing
	match state:
		State.DASH:
			_process_dash(delta)
		State.SLIDE:
			_process_slide(move_dir, delta)
		State.WALL_RUN:
			_process_wall_run(move_dir, delta)
		_:
			_process_standard_move(move_dir, delta)

	# Apply world updrafts smoothly
	if external_updraft.length_squared() > 0.001:
		velocity += external_updraft * delta
		velocity.y = minf(velocity.y, 19.5)
		external_updraft = Vector3.ZERO

	move_and_slide()

	# Landing detection & tactile feedback
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = coyote_time
		_has_double_jump = true
		_has_air_dash = true
		_last_wall_obj = null
		_last_safe_y = global_position.y
		if not _was_on_floor and state != State.SLIDE:
			state = State.GROUNDED
			char_rig.trigger_squash(Vector3(1.24, 0.76, 1.24))
			char_rig.emit_burst(Vector3(0.0, 0.05, 0.0))
			camera_rig.add_land_dip(0.18)
			AudioDirector.play_sfx("land_thud", -5.0, randf_range(0.92, 1.08))
	else:
		_coyote_timer = maxf(0.0, _coyote_timer - delta)
		if state == State.GROUNDED:
			state = State.AIR

	_was_on_floor = on_floor

	# Check Automatic Wall-Run & Auto Ledge-Mantle when airborne!
	if state == State.AIR:
		if _try_start_mantle(move_dir):
			return
		_try_start_wall_run(move_dir)

	# Flow Meter decay & speed-build
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
	camera_rig.update_rig(global_position, velocity, flow_value, wall_roll, state == State.DASH, delta)
	char_rig.update_animation(velocity, move_dir, on_floor, State.keys()[state], _wall_side, flow_value, delta)


func _process_standard_move(move_dir: Vector3, delta: float) -> void:
	var sprinting := Input.is_action_pressed("sprint") or flow_value > 0.45
	var max_spd := (sprint_speed if sprinting else walk_speed) + flow_value * flow_speed_bonus

	# Slide-Dive entry (C / Ctrl while running!)
	if is_on_floor() and Input.is_action_just_pressed("slide") and Vector2(velocity.x, velocity.z).length() > 5.0:
		state = State.SLIDE
		_slide_timer = slide_duration
		_slide_dir = move_dir if move_dir.length_squared() > 0.01 else Vector3(velocity.x, 0.0, velocity.z).normalized()
		velocity.x = _slide_dir.x * slide_speed
		velocity.z = _slide_dir.z * slide_speed
		char_rig.trigger_squash(Vector3(1.26, 0.68, 1.26))
		char_rig.emit_burst(Vector3(0.0, 0.1, 0.0))
		AudioDirector.play_sfx("slide", -4.0, randf_range(0.95, 1.08))
		return

	# Horizontal acceleration/deceleration (crisp on ground, responsive in air)
	var accel := ground_accel if is_on_floor() else air_accel
	var decel := ground_decel if is_on_floor() else air_decel
	if move_dir.length_squared() > 0.001:
		var target_vx := move_dir.x * max_spd
		var target_vz := move_dir.z * max_spd
		# Preserve higher momentum (e.g. from Long-Jump / Portal / Bounce!) when steering in air
		if not is_on_floor():
			var cur_h := Vector2(velocity.x, velocity.z)
			if cur_h.length() > max_spd and cur_h.normalized().dot(Vector2(move_dir.x, move_dir.z)) > 0.4:
				var keep := cur_h.length()
				target_vx = move_dir.x * keep
				target_vz = move_dir.z * keep
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)
		velocity.z = move_toward(velocity.z, target_vz, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)

	# Jump & Double-Jump with Coyote Time + Jump Buffer
	if _jump_buffer_timer > 0.0:
		if _coyote_timer > 0.0:
			velocity.y = jump_velocity
			_coyote_timer = 0.0
			_jump_buffer_timer = 0.0
			state = State.AIR
			char_rig.trigger_squash(Vector3(0.80, 1.26, 0.80))
			char_rig.emit_burst(Vector3(0.0, 0.08, 0.0))
			AudioDirector.play_sfx("jump", -3.0, randf_range(0.96, 1.06))
		elif _has_double_jump:
			velocity.y = double_jump_velocity
			_has_double_jump = false
			_jump_buffer_timer = 0.0
			state = State.AIR
			char_rig.trigger_double_jump_flip()
			AudioDirector.play_sfx("double_jump", -2.5, randf_range(0.98, 1.08))

	# Asymmetric Crisp Gravity + Apex Hang-Time!
	if not is_on_floor():
		var g := gravity_up
		if absf(velocity.y) < apex_threshold:
			g = gravity_apex
		elif velocity.y < 0.0:
			g = gravity_down
		# Short-hop variable jump height if Jump released early
		if velocity.y > 4.0 and not Input.is_action_pressed("jump"):
			g *= 1.55
		velocity.y -= g * gravity_multiplier * delta
		velocity.y = maxf(velocity.y, -38.0)


func _process_slide(move_dir: Vector3, delta: float) -> void:
	_slide_timer -= delta
	# Allow subtle steering during slide
	if move_dir.length_squared() > 0.01:
		_slide_dir = _slide_dir.lerp(move_dir, clampf(delta * 4.5, 0.0, 1.0)).normalized()
	var spd := lerpf(slide_speed, walk_speed * 0.9, 1.0 - clampf(_slide_timer / slide_duration, 0.0, 1.0))
	velocity.x = _slide_dir.x * spd
	velocity.z = _slide_dir.z * spd

	if not is_on_floor():
		velocity.y -= gravity_down * gravity_multiplier * delta

	# Slide → Long-Jump Momentum Chain!
	if _jump_buffer_timer > 0.0 and (_coyote_timer > 0.0 or is_on_floor()):
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		state = State.AIR
		velocity.x = _slide_dir.x * (slide_speed + 1.2)
		velocity.z = _slide_dir.z * (slide_speed + 1.2)
		velocity.y = jump_velocity * 0.92
		add_flow(0.22, true)
		char_rig.trigger_squash(Vector3(0.76, 1.32, 0.76))
		char_rig.emit_burst(Vector3(0.0, 0.12, 0.0))
		camera_rig.add_shake(0.22)
		AudioDirector.play_sfx("jump", -1.5, 1.18)
		return

	if _slide_timer <= 0.0 or not is_on_floor():
		state = State.GROUNDED if is_on_floor() else State.AIR


func _start_dash(dir: Vector3) -> void:
	state = State.DASH
	_has_air_dash = false
	_dash_timer = dash_duration
	_dash_dir = Vector3(dir.x, 0.0, dir.z).normalized()
	if _dash_dir.length_squared() < 0.01:
		_dash_dir = camera_rig.get_forward_xz()
	velocity = _dash_dir * dash_speed
	velocity.y = 1.4  # Tiny crisp anti-drop lift
	add_flow(0.18, false)
	char_rig.trigger_squash(Vector3(0.74, 0.82, 1.42))
	char_rig.emit_burst(Vector3(0.0, 0.65, 0.0))
	camera_rig.add_shake(0.32)
	camera_rig.trigger_hitstop(0.025)
	AudioDirector.play_sfx("dash", -1.5, randf_range(0.96, 1.06))


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity.x = _dash_dir.x * dash_speed
	velocity.z = _dash_dir.z * dash_speed
	velocity.y = lerpf(velocity.y, 0.0, clampf(delta * 10.0, 0.0, 1.0))
	if _dash_timer <= 0.0:
		velocity.x = _dash_dir.x * (sprint_speed + flow_value * flow_speed_bonus + 1.5)
		velocity.z = _dash_dir.z * (sprint_speed + flow_value * flow_speed_bonus + 1.5)
		state = State.GROUNDED if is_on_floor() else State.AIR


func _try_start_wall_run(move_dir: Vector3) -> void:
	if _wall_cooldown > 0.0 or move_dir.length_squared() < 0.1:
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
	if collider is Node and collider.is_in_group("wall_run"):
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
	_last_wall_obj = collider
	_wall_run_node = collider as Node
	_has_air_dash = true
	_has_double_jump = true
	velocity.y = maxf(velocity.y, 2.8)
	add_flow(0.20, false)
	char_rig.emit_burst(Vector3(0.0, 0.6, 0.0))
	if _wall_run_node and _wall_run_node.has_method("on_wall_run_contact"):
		_wall_run_node.on_wall_run_contact()


func _process_wall_run(_move_dir: Vector3, delta: float) -> void:
	_wall_run_timer -= delta
	var active_ray := wall_ray_r if _wall_side > 0.0 else wall_ray_l
	if not active_ray.is_colliding() or _wall_run_timer <= 0.0 or is_on_floor():
		state = State.AIR
		_wall_cooldown = 0.20
		return

	var n := active_ray.get_collision_normal()
	_wall_normal = Vector3(n.x, 0.0, n.z).normalized()
	# Tangent along wall matching forward facing
	var tangent := _wall_normal.cross(Vector3.UP)
	if tangent.dot(camera_rig.get_forward_xz()) < 0.0:
		tangent = -tangent
	tangent = tangent.normalized()

	var run_spd := maxf(Vector2(velocity.x, velocity.z).length(), wall_run_min_speed + flow_value * 2.2)
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
		velocity = tangent * (run_spd * 0.92) + _wall_normal * wall_kick_out + Vector3(0.0, wall_kick_up, 0.0)
		add_flow(0.28, true)
		char_rig.trigger_squash(Vector3(0.78, 1.30, 0.78))
		char_rig.emit_burst(Vector3(0.0, 0.5, 0.0))
		camera_rig.add_shake(0.32)
		camera_rig.trigger_hitstop(0.030)
		if _wall_run_node and _wall_run_node.has_method("on_wall_kick"):
			_wall_run_node.on_wall_kick()
		else:
			AudioDirector.play_sfx("wall_kick", -1.5, randf_range(0.96, 1.08))


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
	if dy < 0.25 or dy > 1.65:
		return false

	state = State.MANTLE
	_mantle_start = global_position
	_mantle_target = ledge_pt + Vector3(0.0, 0.08, 0.0)
	_mantle_t = 0.0
	velocity = Vector3.ZERO
	_has_double_jump = true
	_has_air_dash = true
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
		if dist < 2.5 or dist > 22.0:
			continue
		var dir_cam: Vector3 = (orb.global_position - cam_pos).normalized()
		var align: float = dir_cam.dot(cam_fwd)
		if align < 0.68:
			continue
		var score: float = align * 2.0 - (dist / 22.0) * 0.6
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
	add_flow(0.30, true)
	camera_rig.add_shake(0.32)
	camera_rig.trigger_hitstop(0.025)
	char_rig.emit_burst(Vector3(0.0, 0.6, 0.0))
	AudioDirector.play_sfx("tether_zip", -1.0, randf_range(0.96, 1.12))
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
		state = State.AIR
		char_rig.trigger_double_jump_flip()
		return
	velocity = to_dest.normalized() * 36.0
	move_and_slide()


func begin_rewind_respawn(count_as_fall: bool = true) -> void:
	if state == State.REWIND:
		return
	state = State.REWIND
	if count_as_fall:
		GameState.record_fall()
	flow_value = 0.0
	flow_streak = 0
	GameState.update_flow(0.0, 0)
	_rewind_start = global_position
	_rewind_dest = GameState.current_checkpoint_pos + Vector3(0.0, 0.35, 0.0)
	_rewind_t = 0.0
	velocity = Vector3.ZERO
	AudioDirector.play_sfx("rewind", -2.0, 1.0)
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
		_last_safe_y = global_position.y
		_has_double_jump = true
		_has_air_dash = true
		gravity_multiplier = 1.0
		state = State.GROUNDED
		char_rig.clear_trail()
		char_rig.trigger_squash(Vector3(1.22, 0.78, 1.22))
		char_rig.emit_burst(Vector3(0.0, 0.25, 0.0))


func apply_bounce(impulse: Vector3, reset_air: bool = true) -> void:
	state = State.AIR
	velocity.y = impulse.y
	if Vector2(impulse.x, impulse.z).length_squared() > 0.01:
		velocity.x = impulse.x
		velocity.z = impulse.z
	if reset_air:
		_has_double_jump = true
		_has_air_dash = true
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
	state = State.AIR
	add_flow(0.35, true)
	char_rig.clear_trail()
	char_rig.trigger_double_jump_flip()
	camera_rig.yaw = atan2(-dir.x, -dir.z)
	camera_rig.add_shake(0.40)
	camera_rig.trigger_hitstop(0.032)
	AudioDirector.play_sfx("portal_warp", -1.0, 1.0)


func teleport_to_checkpoint(pos: Vector3, yaw_rad: float = 0.0) -> void:
	global_position = pos + Vector3(0.0, 0.35, 0.0)
	velocity = Vector3.ZERO
	_last_safe_y = global_position.y
	_has_double_jump = true
	_has_air_dash = true
	gravity_multiplier = 1.0
	state = State.GROUNDED
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
	mantle_down_ray.position = Vector3(-sin(yaw) * 0.72, 1.72, -cos(yaw) * 0.72)


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
