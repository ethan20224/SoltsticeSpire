extends Node3D
class_name SpireWorld
## Builds and connects all 6 surreal ascending worlds continuously from Y = 0m to Y = 1,085m,
## manages smart altitude world streaming (keeping Apple M2 under 14ms everywhere),
## plus multi-tier volumetric cloud decks and biome-tinted Ghibli cumulus clusters.

var reachability_audit: Array = []
var summit_position: Vector3 = Vector3(0.0, 1084.5, 0.0)
var _world_nodes: Array[Node3D] = []
var _cloud_groups: Array[Node3D] = []
var _firefly_nodes: Array[GPUParticles3D] = []
var _focus_world: int = -1
var _showing_all_summit: bool = false
var _diorama_culled: bool = false
var _last_low_w1: bool = true
var _last_fast_fall: bool = false
var _player_ref: Node3D = null


func _process(_delta: float) -> void:
	if not is_instance_valid(_player_ref):
		var found := get_tree().get_first_node_in_group("player")
		if found is Node3D:
			_player_ref = found as Node3D
	if is_instance_valid(_player_ref):
		if GameState.is_playing:
			RenderingServer.global_shader_parameter_set("player_world_pos", _player_ref.global_position)
		else:
			RenderingServer.global_shader_parameter_set("player_world_pos", Vector3(99999.0, 99999.0, 99999.0))
		if not _diorama_culled and not _showing_all_summit and _player_ref is CharacterBody3D:
			var vel_y: float = (_player_ref as CharacterBody3D).velocity.y
			if vel_y < -10.0 and not _last_fast_fall and not _world_nodes.is_empty():
				var py: float = _player_ref.global_position.y
				set_focus_world(world_index_for_altitude(py), false, py, vel_y)


func build_all_worlds() -> void:
	reachability_audit.clear()
	_world_nodes.clear()
	_cloud_groups.clear()
	_firefly_nodes.clear()
	_spawn_cloud_decks()
	_spawn_stylized_cloud_clusters()
	_spawn_ambient_fireflies()

	var w1 := World1Conservatory.new()
	w1.name = "World1Conservatory"
	add_child(w1)
	var end1 := w1.build(reachability_audit)

	var w2 := World2Foundry.new()
	w2.name = "World2Foundry"
	add_child(w2)
	var end2 := w2.build(end1, reachability_audit)

	var w3 := World3Monsoon.new()
	w3.name = "World3Monsoon"
	add_child(w3)
	var end3 := w3.build(end2, reachability_audit)

	var w4 := World4Mirrors.new()
	w4.name = "World4Mirrors"
	add_child(w4)
	var end4 := w4.build(end3, reachability_audit)

	var w5 := World5Library.new()
	w5.name = "World5Library"
	add_child(w5)
	var end5 := w5.build(end4, reachability_audit)

	var w6 := World6Crown.new()
	w6.name = "World6Crown"
	add_child(w6)
	summit_position = w6.build(end5, reachability_audit)

	_world_nodes = [w1, w2, w3, w4, w5, w6]
	set_focus_world(0, false)


func set_diorama_cull(active: bool, origin: Vector3 = Vector3(0.0, 0.05, 25.5)) -> void:
	## During Character Select Diorama, hides W2..W6 and culls upper W1 props/lights > 46m from the diorama stage
	## while keeping the W1 Tower Core and horizon parallax rings visible!
	_diorama_culled = active
	if _world_nodes.is_empty():
		return
	if active:
		for i in range(1, _world_nodes.size()):
			_world_nodes[i].visible = false
		for i in range(1, _cloud_groups.size()):
			_cloud_groups[i].visible = false
		for i in range(1, _firefly_nodes.size()):
			_firefly_nodes[i].visible = false
		_world_nodes[0].visible = true
		_cloud_groups[0].visible = true
		_firefly_nodes[0].visible = true
		for ch in _world_nodes[0].get_children():
			if ch is Node3D:
				var n3 := ch as Node3D
				var is_core_or_ring := n3.position.length() < 0.5
				n3.visible = is_core_or_ring or (n3.position.distance_to(origin) <= 46.0)
		for ch in _cloud_groups[0].get_children():
			if ch is Node3D:
				var c3 := ch as Node3D
				c3.visible = c3.position.y <= 55.0
	else:
		for ch in _world_nodes[0].get_children():
			if ch is Node3D:
				(ch as Node3D).visible = true
		for ch in _cloud_groups[0].get_children():
			if ch is Node3D:
				(ch as Node3D).visible = true
		_focus_world = -1
		set_focus_world(0, false, 0.0)


func set_focus_world(idx: int, show_all_for_summit: bool = false, player_y: float = -1.0, fall_vel_y: float = 0.0) -> void:
	## Streams active worlds cleanly: keeps [idx-1, idx+1] visible during normal play
	## (and hides W2 while at the bottom half of W1 so W1 opening hits 60 FPS),
	## streams [idx-2, idx+1] when falling fast (vel_y < -10.0) to prevent invisible lower realms,
	## or shows all 6 realms for the Summit Look-Down vista with 90m detail culling on distant worlds!
	if _diorama_culled:
		return
	idx = clampi(idx, 0, _world_nodes.size() - 1)
	var eff_vel_y: float = fall_vel_y
	if eff_vel_y == 0.0 and is_instance_valid(_player_ref) and _player_ref is CharacterBody3D:
		eff_vel_y = (_player_ref as CharacterBody3D).velocity.y
	var fast_fall: bool = (not show_all_for_summit) and (eff_vel_y < -10.0)
	var low_w1: bool = (idx == 0 and not show_all_for_summit and not fast_fall and player_y < 92.0)
	if idx == _focus_world and show_all_for_summit == _showing_all_summit and low_w1 == _last_low_w1 and fast_fall == _last_fast_fall:
		return
	_focus_world = idx
	_showing_all_summit = show_all_for_summit
	_last_low_w1 = low_w1
	_last_fast_fall = fast_fall

	for i in range(_world_nodes.size()):
		var wn: Node3D = _world_nodes[i]
		if show_all_for_summit:
			wn.visible = true
			if i != idx:
				WorldHelper.set_detail_cull_range(wn, 90.0)
			else:
				WorldHelper.set_detail_cull_range(wn, 0.0)
		else:
			var in_window: bool
			if fast_fall:
				in_window = (i >= idx - 2 and i <= idx + 1)
			elif low_w1:
				in_window = (i == 0)
			else:
				in_window = (absi(i - idx) <= 1)
			wn.visible = in_window
			if in_window:
				WorldHelper.set_detail_cull_range(wn, 0.0 if i == idx else 130.0)
				for ch in wn.get_children():
					if ch is Node3D and ch.name.begins_with("ParallaxRing_"):
						(ch as Node3D).visible = (i == idx)

	for i in range(_cloud_groups.size()):
		var cg: Node3D = _cloud_groups[i]
		if show_all_for_summit:
			cg.visible = true
		elif fast_fall:
			cg.visible = (i >= idx - 2 and i <= idx + 1)
		elif low_w1:
			cg.visible = (i == 0)
		else:
			cg.visible = (absi(i - idx) <= 1)

	for i in range(_firefly_nodes.size()):
		var ff: GPUParticles3D = _firefly_nodes[i]
		if fast_fall:
			ff.visible = (i >= idx - 2 and i <= idx + 1)
		elif low_w1:
			ff.visible = (i == 0)
		else:
			ff.visible = (i == idx) or (absi(i - idx) <= 1 and not show_all_for_summit)


func world_index_for_altitude(y_pos: float) -> int:
	if y_pos < 172.0:
		return 0
	elif y_pos < 352.0:
		return 1
	elif y_pos < 536.0:
		return 2
	elif y_pos < 726.0:
		return 3
	elif y_pos < 916.0:
		return 4
	return 5


func _exit_tree() -> void:
	WorldHelper.clear_caches()


func _spawn_cloud_decks() -> void:
	var cloud_sh: Shader = load("res://assets/shaders/volumetric_cloud_sea.gdshader")
	var tiers: Array[Dictionary] = [
		{
			"y": -18.0, "size": 1500.0, "sub": 60, "op": 0.96,
			"crest": Color(1.0, 0.97, 0.90), "val": Color(0.56, 0.70, 0.90),
			"glow": Color(1.0, 0.88, 0.62), "billow": 8.2, "scale": 0.0085,
		},
	]
	for idx in range(tiers.size()):
		var t: Dictionary = tiers[idx]
		var mi := MeshInstance3D.new()
		mi.name = "CloudDeck_%d" % idx
		var pm := PlaneMesh.new()
		var sz: float = float(t["size"])
		var sub: int = int(t["sub"])
		pm.size = Vector2(sz, sz)
		pm.subdivide_width = sub
		pm.subdivide_depth = sub
		mi.mesh = pm
		mi.position = Vector3(0.0, float(t["y"]), 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := ShaderMaterial.new()
		mat.shader = cloud_sh
		mat.set_shader_parameter("crest_color", t["crest"])
		mat.set_shader_parameter("valley_color", t["val"])
		mat.set_shader_parameter("horizon_glow_color", t["glow"])
		mat.set_shader_parameter("opacity", float(t["op"]))
		mat.set_shader_parameter("billow_height", float(t["billow"]))
		mat.set_shader_parameter("cloud_scale", float(t["scale"]))
		mi.material_override = mat
		add_child(mi)


func _spawn_stylized_cloud_clusters() -> void:
	## Sculpted Ghibli billowy cumulus clouds grouped per realm for streaming & palette harmony!
	## Uses stylized_cloud_puff.gdshader with sunlit crests & sky-translucent valleys (zero brown mud!).
	var puff_path := "res://assets/models/scenery/cloud_puff.glb"
	var biome_tints := [
		{"y_min": -8.0, "y_max": 158.0, "col": Color(0.98, 0.96, 0.94), "rim": Color(1.0, 0.94, 0.78), "sh": Color(0.56, 0.70, 0.88), "cnt": 14},
		{"y_min": 182.0, "y_max": 332.0, "col": Color(1.0, 0.84, 0.62), "rim": Color(1.0, 0.78, 0.44), "sh": Color(0.52, 0.40, 0.58), "cnt": 12},
		{"y_min": 366.0, "y_max": 524.0, "col": Color(0.36, 0.60, 0.68), "rim": Color(1.0, 0.80, 0.46), "sh": Color(0.14, 0.30, 0.42), "cnt": 14},
		{"y_min": 552.0, "y_max": 716.0, "col": Color(0.88, 0.76, 0.94), "rim": Color(1.0, 0.82, 0.96), "sh": Color(0.44, 0.30, 0.58), "cnt": 12},
		{"y_min": 742.0, "y_max": 904.0, "col": Color(0.24, 0.50, 0.66), "rim": Color(0.52, 0.96, 0.92), "sh": Color(0.10, 0.22, 0.40), "cnt": 10},
		{"y_min": 935.0, "y_max": 1045.0, "col": Color(1.0, 0.86, 0.56), "rim": Color(1.0, 0.82, 0.42), "sh": Color(0.36, 0.28, 0.52), "cnt": 8},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261120
	for b_idx in range(biome_tints.size()):
		var bt: Dictionary = biome_tints[b_idx]
		var grp := Node3D.new()
		grp.name = "Clouds_W%d" % (b_idx + 1)
		add_child(grp)
		_cloud_groups.append(grp)
		for i in range(int(bt["cnt"])):
			var ang := rng.randf_range(0.0, 360.0)
			var rad := rng.randf_range(46.0, 92.0)
			var yy := rng.randf_range(float(bt["y_min"]), float(bt["y_max"]))
			var pos := WorldHelper.spiral_pt(ang, rad, yy)
			var sc := rng.randf_range(2.2, 4.4)
			var cl := WorldHelper.add_landmark(grp, puff_path, pos, Vector3(sc, sc * 0.72, sc), Vector3(0.0, rng.randf_range(0.0, 360.0), 0.0), {}, 0.0, true)
			WorldHelper.apply_soft_cloud_material(cl, bt["col"], bt["rim"], bt["sh"])


func _spawn_ambient_fireflies() -> void:
	var zones := [
		{"y": 35.0, "col": Color(1.0, 0.88, 0.48, 0.85), "cnt": 80},
		{"y": 240.0, "col": Color(1.0, 0.66, 0.24, 0.88), "cnt": 85},
		{"y": 440.0, "col": Color(1.0, 0.78, 0.38, 0.85), "cnt": 75},
		{"y": 630.0, "col": Color(0.95, 0.68, 1.0, 0.85), "cnt": 75},
		{"y": 820.0, "col": Color(1.0, 0.80, 0.40, 0.88), "cnt": 90},
		{"y": 1020.0, "col": Color(1.0, 0.84, 0.42, 0.90), "cnt": 90},
	]
	for z in zones:
		var gp := GPUParticles3D.new()
		gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gp.position = Vector3(0.0, float(z["y"]), 0.0)
		gp.amount = int(z["cnt"])
		gp.lifetime = 6.5
		gp.visibility_aabb = AABB(Vector3(-48, -85, -48), Vector3(96, 170, 96))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(36.0, 75.0, 36.0)
		pm.direction = Vector3(0.0, 1.0, 0.0)
		pm.spread = 45.0
		pm.initial_velocity_min = 0.4
		pm.initial_velocity_max = 1.4
		pm.gravity = Vector3.ZERO
		pm.scale_min = 0.08
		pm.scale_max = 0.18
		gp.process_material = pm

		var sp := SphereMesh.new()
		sp.radius = 0.55
		sp.height = 1.1
		sp.radial_segments = 6
		sp.rings = 4
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = z["col"]
		sp.material = mat
		gp.draw_pass_1 = sp
		add_child(gp)
		_firefly_nodes.append(gp)
