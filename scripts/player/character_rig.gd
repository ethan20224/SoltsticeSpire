extends Node3D
class_name CharacterRig
## Loads the active sculpted character (.glb) and drives expressive 60fps animations,
## squash-and-stretch, secondary physics (scarf, ears, wings, lantern), and kinetic Flow ribbons.

var _model_root: Node3D
var _body: Node3D
var _head: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D

# Character-specific secondary motion chains
var _scarf_segs: Array[Node3D] = []
var _lantern: Node3D
var _ear_l: Node3D
var _ear_r: Node3D
var _tail_segs: Array[Node3D] = []
var _windup_key: Node3D
var _wing_l: Node3D
var _wing_r: Node3D
var _ant_l: Node3D
var _ant_r: Node3D

var _char_id: String = "pip"
var _anim_time: float = 0.0
var _stride_phase: float = 0.0
var _squash_vec: Vector3 = Vector3.ONE
var _flip_angle: float = 0.0
var _visual_yaw: float = 0.0
var _solar_charged: bool = false

# Dynamic 3D Flow Ribbon Trail
var _ribbon_mesh_inst: MeshInstance3D
var _ribbon_mesh: ImmediateMesh
var _ribbon_mat: ShaderMaterial
var _trail_points: Array[Vector3] = []
const MAX_TRAIL_PTS := 22
var _trail_timer: float = 0.0

# Burst Particles
var _burst_particles: GPUParticles3D
var _burst_mat: StandardMaterial3D


func _ready() -> void:
	_setup_ribbon()
	_setup_burst_particles()
	load_character(GameState.selected_character)
	GameState.character_changed.connect(load_character)


func _setup_ribbon() -> void:
	_ribbon_mesh = ImmediateMesh.new()
	_ribbon_mesh_inst = MeshInstance3D.new()
	_ribbon_mesh_inst.mesh = _ribbon_mesh
	_ribbon_mesh_inst.top_level = true
	_ribbon_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ribbon_mat = ShaderMaterial.new()
	_ribbon_mat.shader = load("res://assets/shaders/flow_ribbon.gdshader")
	_ribbon_mesh_inst.material_override = _ribbon_mat
	add_child(_ribbon_mesh_inst)


func _setup_burst_particles() -> void:
	_burst_particles = GPUParticles3D.new()
	_burst_particles.one_shot = true
	_burst_particles.explosiveness = 0.92
	_burst_particles.amount = 18
	_burst_particles.lifetime = 0.42
	_burst_particles.emitting = false

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 0.5, 0.0)
	pm.spread = 115.0
	pm.initial_velocity_min = 2.6
	pm.initial_velocity_max = 6.2
	pm.gravity = Vector3(0.0, -7.0, 0.0)
	pm.scale_min = 0.09
	pm.scale_max = 0.22
	pm.damping_min = 2.0
	pm.damping_max = 4.0
	_burst_particles.process_material = pm

	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.9
	sphere.radial_segments = 8
	sphere.rings = 4
	_burst_mat = StandardMaterial3D.new()
	_burst_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_burst_mat.albedo_color = Color(1.0, 0.90, 0.50)
	_burst_mat.emission_enabled = true
	_burst_mat.emission = Color(1.0, 0.85, 0.45)
	_burst_mat.emission_energy_multiplier = 2.4
	sphere.material = _burst_mat
	_burst_particles.draw_pass_1 = sphere
	add_child(_burst_particles)


func load_character(char_id: String) -> void:
	if not GameState.CHARACTERS.has(char_id):
		return
	if _char_id == char_id and _model_root and is_instance_valid(_model_root):
		return
	_char_id = char_id
	if _model_root and is_instance_valid(_model_root):
		remove_child(_model_root)
		_model_root.queue_free()
		_model_root = null

	_body = null
	_head = null
	_leg_l = null
	_leg_r = null
	_arm_l = null
	_arm_r = null
	_scarf_segs.clear()
	_lantern = null
	_ear_l = null
	_ear_r = null
	_tail_segs.clear()
	_windup_key = null
	_wing_l = null
	_wing_r = null
	_ant_l = null
	_ant_r = null

	var info: Dictionary = GameState.CHARACTERS[char_id]
	var scene_res: Variant = load(str(info["model"]))
	if scene_res is PackedScene:
		_model_root = (scene_res as PackedScene).instantiate()
		WorldHelper.apply_plush_character_materials(_model_root)
		add_child(_model_root)
		_cache_rig_nodes(_model_root)

	_apply_trail_colors()
	_trail_points.clear()
	trigger_squash(Vector3(1.22, 0.80, 1.22))


func _apply_trail_colors() -> void:
	if not GameState.CHARACTERS.has(_char_id):
		return
	var info: Dictionary = GameState.CHARACTERS[_char_id]
	var core_col: Color = info["trail_core"]
	var edge_col: Color = info["trail_edge"]
	if _solar_charged:
		core_col = core_col.lerp(Color(1.0, 0.96, 0.56), 0.72)
		edge_col = edge_col.lerp(Color(1.0, 0.64, 0.14), 0.72)
	if _ribbon_mat:
		_ribbon_mat.set_shader_parameter("core_color", core_col)
		_ribbon_mat.set_shader_parameter("edge_color", edge_col)
	if _burst_mat:
		_burst_mat.albedo_color = core_col
		_burst_mat.emission = core_col


func set_solar_charge_glow(enabled: bool) -> void:
	if _solar_charged == enabled:
		return
	_solar_charged = enabled
	_apply_trail_colors()
	if enabled:
		emit_burst(Vector3(0.0, 0.65, 0.0))


func _cache_rig_nodes(root: Node) -> void:
	_body = root.find_child("BodyPivot", true, false) as Node3D
	_head = root.find_child("HeadPivot", true, false) as Node3D
	_leg_l = root.find_child("LegL", true, false) as Node3D
	_leg_r = root.find_child("LegR", true, false) as Node3D
	_arm_l = root.find_child("ArmL", true, false) as Node3D
	_arm_r = root.find_child("ArmR", true, false) as Node3D

	for i in range(1, 5):
		var s := root.find_child("Scarf%d" % i, true, false) as Node3D
		if s:
			_scarf_segs.append(s)
	_lantern = root.find_child("LanternPivot", true, false) as Node3D

	_ear_l = root.find_child("EarL", true, false) as Node3D
	_ear_r = root.find_child("EarR", true, false) as Node3D
	for i in range(1, 4):
		var t := root.find_child("Tail%d" % i, true, false) as Node3D
		if t:
			_tail_segs.append(t)
	_windup_key = root.find_child("WindupKey", true, false) as Node3D

	_wing_l = root.find_child("WingL", true, false) as Node3D
	_wing_r = root.find_child("WingR", true, false) as Node3D
	_ant_l = root.find_child("AntennaL", true, false) as Node3D
	_ant_r = root.find_child("AntennaR", true, false) as Node3D


func trigger_squash(target_scale: Vector3) -> void:
	_squash_vec = target_scale


func trigger_double_jump_flip() -> void:
	_flip_angle = TAU
	trigger_squash(Vector3(0.80, 1.28, 0.80))
	emit_burst(Vector3(0.0, 0.35, 0.0))


func emit_burst(local_offset: Vector3 = Vector3.ZERO) -> void:
	if not _burst_particles:
		return
	_burst_particles.position = local_offset
	_burst_particles.restart()
	_burst_particles.emitting = true


func update_animation(vel: Vector3, move_dir: Vector3, is_floor: bool, state_name: String,
		wall_side: float, flow: float, delta: float) -> void:
	_anim_time += delta
	var horiz_vel := Vector3(vel.x, 0.0, vel.z)
	var spd := horiz_vel.length()
	var spd_norm := clampf(spd / 12.0, 0.0, 1.2)

	# Smooth facing rotation toward velocity/input direction (model forward is -Z!)
	var look_vec := horiz_vel if spd > 0.6 else move_dir
	if look_vec.length_squared() > 0.02:
		var target_yaw := atan2(-look_vec.x, -look_vec.z)
		_visual_yaw = lerp_angle(_visual_yaw, target_yaw, clampf(delta * 14.0, 0.0, 1.0))

	# Springy squash-and-stretch recovery
	_squash_vec = _squash_vec.lerp(Vector3.ONE, clampf(delta * 14.0, 0.0, 1.0))
	scale = _squash_vec

	# Double-jump celebratory front-flip decay
	if _flip_angle > 0.01:
		_flip_angle = maxf(0.0, _flip_angle - delta * 15.5)

	# Compute body pitch/roll posture per movement state
	var body_pitch := -spd_norm * 0.22
	var body_roll := 0.0
	var bob_y := 0.0

	if state_name == "SLIDE":
		body_pitch = 0.65
		bob_y = -0.22
	elif state_name == "SKY_DIVE":
		body_pitch = -1.05
	elif state_name == "FLUTTER":
		body_pitch = 0.06
	elif state_name == "DASH" or state_name == "TETHER_ZIP":
		body_pitch = -0.45
	elif state_name == "WALL_RUN":
		body_pitch = -0.24
		body_roll = -wall_side * 0.44
	elif state_name == "MANTLE":
		body_pitch = -0.35
	elif not is_floor:
		body_pitch = clampf(vel.y * -0.025, -0.32, 0.28)
	else:
		if spd > 0.4:
			_stride_phase += delta * (6.0 + spd * 1.05)
			bob_y = absf(sin(_stride_phase)) * 0.085 * spd_norm
		else:
			bob_y = sin(_anim_time * 2.6) * 0.022

	rotation.y = _visual_yaw
	if _model_root:
		_model_root.position.y = lerpf(_model_root.position.y, bob_y, clampf(delta * 18.0, 0.0, 1.0))
		_model_root.rotation.x = lerpf(_model_root.rotation.x, body_pitch - _flip_angle, clampf(delta * 18.0, 0.0, 1.0))
		_model_root.rotation.z = lerpf(_model_root.rotation.z, body_roll, clampf(delta * 14.0, 0.0, 1.0))

	# Expressive Limbs
	var leg_swing := 0.0
	var arm_swing := 0.0
	var arm_spread := 0.14 + (0.45 if not is_floor else 0.0)
	if is_floor and spd > 0.45 and state_name != "SLIDE":
		leg_swing = sin(_stride_phase) * 0.78 * clampf(spd_norm, 0.25, 1.0)
		arm_swing = -sin(_stride_phase) * 0.62 * clampf(spd_norm, 0.25, 1.0)
	elif state_name == "WALL_RUN":
		_stride_phase += delta * 17.0
		leg_swing = sin(_stride_phase) * 0.72
		arm_swing = -sin(_stride_phase) * 0.55
	elif state_name == "SLIDE":
		leg_swing = 0.65
		arm_swing = -0.75
	elif state_name == "SKY_DIVE":
		leg_swing = 0.55
		arm_swing = -1.35
		arm_spread = 0.22
	elif state_name == "FLUTTER":
		leg_swing = 0.24
		arm_swing = -0.15
		arm_spread = 0.72
	elif not is_floor:
		leg_swing = 0.36
		arm_swing = -0.45

	if _leg_l:
		var target_leg_l := leg_swing if state_name != "SKY_DIVE" else 0.55
		_leg_l.rotation.x = lerpf(_leg_l.rotation.x, target_leg_l, clampf(delta * 16.0, 0.0, 1.0))
	if _leg_r:
		var target_leg_r := leg_swing if state_name == "SKY_DIVE" else -leg_swing
		_leg_r.rotation.x = lerpf(_leg_r.rotation.x, target_leg_r, clampf(delta * 16.0, 0.0, 1.0))
	if _arm_l:
		_arm_l.rotation.x = lerpf(_arm_l.rotation.x, arm_swing, clampf(delta * 14.0, 0.0, 1.0))
		_arm_l.rotation.z = lerpf(_arm_l.rotation.z, arm_spread, clampf(delta * 10.0, 0.0, 1.0))
	if _arm_r:
		var target_arm_r := arm_swing if state_name == "SKY_DIVE" else -arm_swing
		_arm_r.rotation.x = lerpf(_arm_r.rotation.x, target_arm_r, clampf(delta * 14.0, 0.0, 1.0))
		_arm_r.rotation.z = lerpf(_arm_r.rotation.z, -arm_spread, clampf(delta * 10.0, 0.0, 1.0))

	# Character-Specific Alive Secondary Motion!
	# 1. Pip's fluttering 4-segment scarf & dangling brass lantern
	for idx in range(_scarf_segs.size()):
		var seg := _scarf_segs[idx]
		var wave_spd := 4.5 + spd * 1.15 + (6.0 if state_name == "SKY_DIVE" else 0.0)
		var amp := 0.08 + spd_norm * 0.22 + (0.14 if state_name == "SKY_DIVE" else 0.0)
		seg.rotation.x = -0.12 - spd_norm * 0.18 + sin(_anim_time * wave_spd - idx * 0.9) * amp
		seg.rotation.y = cos(_anim_time * (wave_spd * 0.7) - idx * 1.1) * amp * 0.75
	if _lantern:
		_lantern.rotation.x = sin(_anim_time * 3.4) * 0.14
		_lantern.rotation.z = 0.0

	# 2. Koko's swept-back hinged ears, wagging tail & spinning wind-up key
	var ear_back := -0.18 - spd_norm * 0.52 - (0.35 if state_name in ["DASH", "SKY_DIVE"] else 0.0)
	if _ear_l:
		_ear_l.rotation.x = lerpf(_ear_l.rotation.x, ear_back + sin(_anim_time * 5.0) * 0.05, clampf(delta * 12.0, 0.0, 1.0))
	if _ear_r:
		_ear_r.rotation.x = lerpf(_ear_r.rotation.x, ear_back + cos(_anim_time * 5.0) * 0.05, clampf(delta * 12.0, 0.0, 1.0))
	for idx in range(_tail_segs.size()):
		var tseg := _tail_segs[idx]
		tseg.rotation.y = sin(_anim_time * (5.0 + spd * 0.6) - idx * 0.8) * (0.18 + spd_norm * 0.15)
		tseg.rotation.x = 0.12 - spd_norm * 0.14
	if _windup_key:
		_windup_key.rotation.z += delta * (1.8 + spd * 0.95 + flow * 6.0 + (4.5 if _solar_charged else 0.0))

	# 3. Vesper's articulated origami wings & feathered antennae!
	var wing_spread := 0.22 if is_floor else 0.78
	var flap_freq := 4.0 if is_floor else 14.0
	var flap_amp := 0.08 if is_floor else 0.28
	if state_name == "FLUTTER":
		wing_spread = 1.25
		flap_freq = 26.0
		flap_amp = 0.36
	elif state_name == "DASH" or state_name == "TETHER_ZIP":
		wing_spread = 1.05
	elif state_name == "SKY_DIVE":
		wing_spread = 0.34
		flap_freq = 18.0
		flap_amp = 0.12
	var flap := sin(_anim_time * flap_freq) * flap_amp
	if _wing_l:
		_wing_l.rotation.y = lerpf(_wing_l.rotation.y, -wing_spread + flap, clampf(delta * 14.0, 0.0, 1.0))
	if _wing_r:
		_wing_r.rotation.y = lerpf(_wing_r.rotation.y, wing_spread - flap, clampf(delta * 14.0, 0.0, 1.0))
	if _ant_l:
		_ant_l.rotation.x = -0.35 - spd_norm * 0.35 + sin(_anim_time * 6.0) * 0.08
	if _ant_r:
		_ant_r.rotation.x = -0.35 - spd_norm * 0.35 + cos(_anim_time * 6.0) * 0.08

	_update_ribbon_trail(spd, flow, state_name, delta)


func _update_ribbon_trail(spd: float, flow: float, state_name: String, delta: float) -> void:
	var active := spd > 7.5 or flow > 0.22 or _solar_charged or state_name in ["DASH", "WALL_RUN", "TETHER_ZIP", "REWIND", "SKY_DIVE", "FLUTTER"]
	_trail_timer += delta
	if _trail_timer >= 0.016:
		_trail_timer = 0.0
		if active:
			_trail_points.push_front(global_position + Vector3(0.0, 0.75, 0.0))
			if _trail_points.size() > MAX_TRAIL_PTS:
				_trail_points.pop_back()
		elif _trail_points.size() > 0:
			_trail_points.pop_back()

	_ribbon_mesh.clear_surfaces()
	if _trail_points.size() < 3:
		return

	var cam := get_viewport().get_camera_3d()
	var cam_pos := cam.global_position if cam else global_position + Vector3(0.0, 3.0, 5.0)
	var extra_w := 0.20 if state_name in ["DASH", "TETHER_ZIP", "REWIND"] else (0.26 if state_name == "SKY_DIVE" else 0.0)
	if _solar_charged:
		extra_w += 0.14
	var base_w := 0.16 + flow * 0.24 + extra_w
	var extra_i := 1.2 if state_name == "DASH" else (1.55 if state_name == "SKY_DIVE" else 0.0)
	if _solar_charged:
		extra_i += 1.15
	_ribbon_mat.set_shader_parameter("intensity", 1.1 + flow * 1.4 + extra_i)

	_ribbon_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var cnt := _trail_points.size()
	for i in range(cnt):
		var u := float(i) / float(cnt - 1)
		var pt := _trail_points[i]
		var tang: Vector3
		if i < cnt - 1:
			tang = (_trail_points[i + 1] - pt).normalized()
		else:
			tang = (pt - _trail_points[i - 1]).normalized()
		var to_cam := (cam_pos - pt).normalized()
		var side := tang.cross(to_cam).normalized()
		if side.length_squared() < 0.01:
			side = Vector3.UP
		var half_w := base_w * (1.0 - u) * 0.5
		_ribbon_mesh.surface_set_uv(Vector2(u, 0.0))
		_ribbon_mesh.surface_add_vertex(pt - side * half_w)
		_ribbon_mesh.surface_set_uv(Vector2(u, 1.0))
		_ribbon_mesh.surface_add_vertex(pt + side * half_w)
	_ribbon_mesh.surface_end()


func clear_trail() -> void:
	_trail_points.clear()
	if _ribbon_mesh:
		_ribbon_mesh.clear_surfaces()
