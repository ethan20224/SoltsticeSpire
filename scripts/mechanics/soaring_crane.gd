extends AnimatableBody3D
class_name SoaringCrane
## Giant rideable Origami Crane gliding smoothly along an ascending curved sky-loop.
## Uses sync_to_physics with a level top boarding deck so CharacterBody3D rides cleanly without slipping,
## while the crane visual banks, bobs, and trails golden wingtip stardust sparks.

@export var start_pos: Vector3 = Vector3.ZERO
@export var mid_pos: Vector3 = Vector3.ZERO
@export var end_pos: Vector3 = Vector3(0.0, 24.0, 0.0)
@export var crane_scale: float = 1.55
@export var flight_duration: float = 10.5
@export var pause_duration: float = 1.8
@export var bob_amplitude: float = 0.24
@export var bank_angle_deg: float = 11.5

enum Phase { PAUSE_START, ASCEND, PAUSE_END, DESCEND }

var _phase: Phase = Phase.PAUSE_START
var _phase_t: float = 0.0
var _time: float = 0.0
var _control_pos: Vector3 = Vector3.ZERO
var _visual_pivot: Node3D
var _boarding_area: Area3D
var _boarded_this_ride: bool = false
var _player_on_board: bool = false
var _leave_cooldown: float = 0.0
var _current_yaw: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	add_to_group("soaring_crane")

	# Compute quadratic Bezier control point so curve passes cleanly through mid_pos at t = 0.5
	var effective_mid := mid_pos
	if effective_mid == Vector3.ZERO:
		effective_mid = start_pos.lerp(end_pos, 0.5) + Vector3(0.0, 4.0, 0.0)
	_control_pos = effective_mid * 2.0 - (start_pos + end_pos) * 0.5

	position = start_pos
	var init_tan := _eval_tangent(0.02)
	_current_yaw = atan2(-init_tan.x, -init_tan.z)
	rotation = Vector3(0.0, _current_yaw, 0.0)

	_build_deck_collider()
	_build_visuals()
	_build_boarding_trigger()


func _build_deck_collider() -> void:
	var col := CollisionShape3D.new()
	col.name = "DeckCollider"
	var bx := BoxShape3D.new()
	bx.size = Vector3(4.6, 0.45, 4.2)
	col.shape = bx
	col.position = Vector3(0.0, 0.0, 0.0)
	add_child(col)


func _build_visuals() -> void:
	_visual_pivot = Node3D.new()
	_visual_pivot.name = "VisualPivot"
	add_child(_visual_pivot)

	var crane_path := "res://assets/models/world3_monsoon/origami_crane.glb"
	if ResourceLoader.exists(crane_path):
		var vis := WorldHelper.load_glb(crane_path)
		vis.name = "CraneMesh"
		vis.scale = Vector3.ONE * crane_scale
		vis.position = Vector3(0.0, -0.58, 0.0)
		WorldHelper.apply_paper_shader(vis, Color(0.99, 0.96, 0.89))
		_visual_pivot.add_child(vis)

	# Tactile vermilion-and-gold silk riding mat flush with top of deck collider (y = 0.225)
	var mat_deck := StandardMaterial3D.new()
	mat_deck.albedo_color = Color(0.76, 0.22, 0.18)
	mat_deck.roughness = 0.62
	mat_deck.emission_enabled = true
	mat_deck.emission = Color(0.95, 0.46, 0.16)
	mat_deck.emission_energy_multiplier = 0.24

	var saddle := MeshInstance3D.new()
	var saddle_box := BoxMesh.new()
	saddle_box.size = Vector3(3.8, 0.06, 3.4)
	saddle.mesh = saddle_box
	saddle.material_override = mat_deck
	saddle.position = Vector3(0.0, 0.20, 0.0)
	saddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_pivot.add_child(saddle)

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(1.0, 0.82, 0.34)
	gold_mat.metallic = 0.72
	gold_mat.roughness = 0.26
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(1.0, 0.78, 0.28)
	gold_mat.emission_energy_multiplier = 0.75

	var trim := MeshInstance3D.new()
	var trim_box := BoxMesh.new()
	trim_box.size = Vector3(4.15, 0.04, 3.75)
	trim.mesh = trim_box
	trim.material_override = gold_mat
	trim.position = Vector3(0.0, 0.185, 0.0)
	trim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_pivot.add_child(trim)

	# Warm guiding lantern glow & subtle beacon halo so boarding berth reads clearly in monsoon twilight
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.4, 0.0)
	light.light_color = Color(1.0, 0.82, 0.38)
	light.light_energy = 2.8
	light.omni_range = 14.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 75.0
	light.distance_fade_length = 25.0
	_visual_pivot.add_child(light)
	WorldHelper.add_lamp_halo(_visual_pivot, Vector3(0.0, 0.9, -2.4), Color(1.0, 0.84, 0.42), 2.1, 0.65)

	# Golden wingtip trail sparks on both origami wings
	var tip_x := 5.20 * crane_scale
	var tip_y := 1.72 * crane_scale - 0.58
	var tip_z := 0.32 * crane_scale
	_add_wingtip_sparks(Vector3(-tip_x, tip_y, tip_z))
	_add_wingtip_sparks(Vector3(tip_x, tip_y, tip_z))


func _add_wingtip_sparks(local_pos: Vector3) -> void:
	var gp := GPUParticles3D.new()
	gp.position = local_pos
	gp.amount = 28
	gp.lifetime = 1.45
	gp.local_coords = false
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gp.visibility_aabb = AABB(Vector3(-32.0, -24.0, -32.0), Vector3(64.0, 48.0, 64.0))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.22
	pm.direction = Vector3(0.0, 0.2, 0.0)
	pm.spread = 35.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0.0, -0.35, 0.0)
	pm.scale_min = 0.14
	pm.scale_max = 0.30
	gp.process_material = pm

	var sp := SphereMesh.new()
	sp.radius = 0.36
	sp.height = 0.72
	sp.radial_segments = 6
	sp.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.88, 0.44, 0.88)
	sp.material = mat
	gp.draw_pass_1 = sp
	_visual_pivot.add_child(gp)


func _build_boarding_trigger() -> void:
	_boarding_area = Area3D.new()
	_boarding_area.name = "BoardingArea"
	_boarding_area.collision_layer = 0
	_boarding_area.collision_mask = 2
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(4.8, 2.5, 4.4)
	col.shape = bx
	col.position = Vector3(0.0, 1.35, 0.0)
	_boarding_area.add_child(col)
	add_child(_boarding_area)
	_boarding_area.body_entered.connect(_on_body_entered)
	_boarding_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_player_on_board = true
	_leave_cooldown = 0.0
	if _boarded_this_ride:
		return
	_boarded_this_ride = true
	AudioDirector.play_sfx("shortcut_fanfare", -1.5, 1.02)
	AudioDirector.play_flow_chime(4, -3.5)
	GameState.emit_callout("SKY CRANE EXPRESS", "Ride to Upper Pagoda!", Color(1.0, 0.86, 0.42))
	if GameState.has_method("unlock_badge"):
		GameState.call("unlock_badge", "shortcut_daredevil")
	if body.has_method("add_flow"):
		body.add_flow(0.30, false)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_player_on_board = false
	_leave_cooldown = 2.5


func _eval_bezier(t: float) -> Vector3:
	var u := 1.0 - t
	return (u * u) * start_pos + (2.0 * u * t) * _control_pos + (t * t) * end_pos


func _eval_tangent(t: float) -> Vector3:
	var deriv := 2.0 * (1.0 - t) * (_control_pos - start_pos) + 2.0 * t * (end_pos - _control_pos)
	var flat := Vector3(deriv.x, 0.0, deriv.z)
	if flat.length_squared() < 0.0001:
		return Vector3.FORWARD
	return flat.normalized()


func _smootherstep(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * c * (c * (c * 6.0 - 15.0) + 10.0)


func _physics_process(delta: float) -> void:
	_time += delta
	if not _player_on_board and _boarded_this_ride:
		_leave_cooldown -= delta
		if _leave_cooldown <= 0.0:
			_boarded_this_ride = false

	var descend_duration := maxf(flight_duration * 0.86, 4.0)
	var path_t := 0.0
	var moving_dir := 1.0
	var speed_weight := 0.0

	match _phase:
		Phase.PAUSE_START:
			_phase_t += delta
			path_t = 0.0
			moving_dir = 1.0
			speed_weight = 0.0
			if _phase_t >= pause_duration:
				_phase = Phase.ASCEND
				_phase_t = 0.0
		Phase.ASCEND:
			_phase_t += delta
			var raw := clampf(_phase_t / maxf(flight_duration, 1.0), 0.0, 1.0)
			path_t = _smootherstep(raw)
			moving_dir = 1.0
			speed_weight = sin(raw * PI)
			if raw >= 1.0:
				_phase = Phase.PAUSE_END
				_phase_t = 0.0
		Phase.PAUSE_END:
			_phase_t += delta
			path_t = 1.0
			moving_dir = 1.0
			speed_weight = 0.0
			if _phase_t >= pause_duration:
				_phase = Phase.DESCEND
				_phase_t = 0.0
		Phase.DESCEND:
			_phase_t += delta
			var raw := clampf(_phase_t / descend_duration, 0.0, 1.0)
			path_t = 1.0 - _smootherstep(raw)
			moving_dir = -1.0
			speed_weight = sin(raw * PI)
			if raw >= 1.0:
				_phase = Phase.PAUSE_START
				_phase_t = 0.0

	var base_pos := _eval_bezier(path_t)
	var bob_y := sin(_time * 2.15) * bob_amplitude
	position = base_pos + Vector3(0.0, bob_y, 0.0)

	# Smooth yaw facing along horizontal travel direction (keeping deck collider level for slip-free riding)
	var sample_t := clampf(path_t, 0.02, 0.98)
	var tan_vec := _eval_tangent(sample_t) * moving_dir
	var target_yaw := atan2(-tan_vec.x, -tan_vec.z)
	var yaw_diff := wrapf(target_yaw - _current_yaw, -PI, PI)
	_current_yaw += yaw_diff * clampf(delta * 2.8, 0.0, 1.0)
	rotation = Vector3(0.0, _current_yaw, 0.0)

	# Graceful visual banking and buoyant pitch only on _visual_pivot (never tilts deck physics!)
	if is_instance_valid(_visual_pivot):
		var target_bank := deg_to_rad(bank_angle_deg) * speed_weight * moving_dir + sin(_time * 1.45) * 0.045
		var target_pitch := (0.095 if moving_dir > 0.0 else -0.075) * speed_weight + cos(_time * 2.15) * 0.025
		_visual_pivot.rotation.z = lerpf(_visual_pivot.rotation.z, target_bank, clampf(delta * 3.5, 0.0, 1.0))
		_visual_pivot.rotation.x = lerpf(_visual_pivot.rotation.x, target_pitch, clampf(delta * 3.5, 0.0, 1.0))
