extends Node3D
class_name ShardTrial
## 10-Second Sun-Shard Micro-Challenge!
## Touch the gleaming Trial Bell to ignite a timed line of golden spectral sky-rings (and optional Dash Prisms).
## Clear all rings before the clock hits zero to claim the Sun-Shard!
## Also houses a real SunShard child so the 18/18 shard count stays exact & verifiable.

@export var shard_id: String = "w1_s1"
@export var trial_title: String = "SUN-SHARD TRIAL"
@export var time_limit: float = 11.0
@export var ring_positions: PackedVector3Array = PackedVector3Array()

var _active: bool = false
var _completed: bool = false
var _time_left: float = 0.0
var _collected_count: int = 0
var _starter_mesh: MeshInstance3D
var _ring_nodes: Array[Node3D] = []
var _ring_hit: Array[bool] = []
var _shard_node: SunShard
var _t: float = 0.0


func _ready() -> void:
	add_to_group("shard_trial")
	_build_starter_bell()
	_build_rings()
	_build_hidden_shard()
	GameState.game_started.connect(_reset_trial_state)


func _reset_trial_state() -> void:
	_active = false
	_completed = GameState.collected_shards.has(shard_id)
	_time_left = 0.0
	_collected_count = 0
	for i in range(_ring_nodes.size()):
		_ring_nodes[i].visible = false
		_ring_hit[i] = false
	if _starter_mesh:
		_starter_mesh.visible = not _completed
	if _shard_node and is_instance_valid(_shard_node):
		_shard_node.visible = false
		_shard_node.set_process(false)


func _build_starter_bell() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.28)
	mat.metallic = 0.85
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.18)
	mat.emission_energy_multiplier = 1.9

	_starter_mesh = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.05
	tor.outer_radius = 1.28
	tor.rings = 24
	tor.ring_segments = 8
	_starter_mesh.mesh = tor
	_starter_mesh.material_override = mat
	_starter_mesh.position = Vector3(0.0, 1.65, 0.0)
	_starter_mesh.rotation_degrees.x = 90.0
	_starter_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_starter_mesh)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 2.0
	col.shape = sp
	col.position = Vector3(0.0, 1.65, 0.0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_start_entered)


func _build_rings() -> void:
	var tor := TorusMesh.new()
	tor.inner_radius = 1.35
	tor.outer_radius = 1.56
	tor.rings = 24
	tor.ring_segments = 8

	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rmat.albedo_color = Color(1.0, 0.88, 0.34, 0.92)

	for i in range(ring_positions.size()):
		var world_p := ring_positions[i]
		var holder := Node3D.new()
		holder.top_level = true
		holder.position = world_p
		holder.visible = false

		var mi := MeshInstance3D.new()
		mi.mesh = tor
		mi.material_override = rmat
		mi.rotation_degrees.x = 90.0
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)

		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		var col := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 2.25
		col.shape = sp
		area.add_child(col)
		holder.add_child(area)
		var ring_idx := i
		area.body_entered.connect(func(b: Node3D) -> void: _on_ring_entered(ring_idx, b))

		add_child(holder)
		_ring_nodes.append(holder)
		_ring_hit.append(false)


func _build_hidden_shard() -> void:
	# Keep a real SunShard child (parked hidden until claimed) so get_nodes_in_group("sun_shard") counts all 18!
	_shard_node = SunShard.new()
	_shard_node.shard_id = shard_id
	_shard_node.position = Vector3(0.0, 2.2, 0.0)
	_shard_node.visible = false
	add_child(_shard_node)
	_shard_node.set_process(false)
	for ch in _shard_node.get_children():
		if ch is Area3D:
			(ch as Area3D).set_deferred("monitoring", false)


func _on_start_entered(body: Node3D) -> void:
	if _completed or _active or not body.is_in_group("player"):
		return
	if ring_positions.is_empty():
		return
	_active = true
	_time_left = time_limit
	_collected_count = 0
	for i in range(_ring_nodes.size()):
		_ring_hit[i] = false
		_ring_nodes[i].visible = true
		_ring_nodes[i].scale = Vector3.ONE
	AudioDirector.play_sfx("bell_ring", -2.0, 1.25)
	GameState.emit_callout(trial_title, "Clear %d Sky-Rings in %.0fs for a Sun-Shard!" % [_ring_nodes.size(), time_limit], Color(1.0, 0.86, 0.32))
	GameState.emit_trial_state(true, trial_title, 0, _ring_nodes.size(), _time_left)


func _on_ring_entered(idx: int, body: Node3D) -> void:
	if not _active or _ring_hit[idx] or not body.is_in_group("player"):
		return
	_ring_hit[idx] = true
	_collected_count += 1
	_ring_nodes[idx].visible = false
	AudioDirector.play_flow_chime(mini(_collected_count, 7), -1.5)
	if body is PlayerController:
		var pc := body as PlayerController
		pc.refill_air_moves()
		pc.add_flow(0.24, false)
	PhoneController.send_haptic("jump")
	GameState.emit_trial_state(true, trial_title, _collected_count, _ring_nodes.size(), _time_left)

	if _collected_count >= _ring_nodes.size():
		_complete_trial(body)


func _complete_trial(body: Node3D) -> void:
	_active = false
	_completed = true
	if _starter_mesh:
		_starter_mesh.visible = false
	GameState.emit_trial_state(false, "", 0, 0, 0.0)
	if GameState.collect_shard(shard_id):
		AudioDirector.play_sfx("sun_shard", -0.5, 1.05)
		AudioDirector.play_sfx("shortcut_fanfare", -1.5, 1.12)
	if body is PlayerController:
		(body as PlayerController).add_flow(0.55, true)
	GameState.emit_callout("TRIAL CONQUERED!", "SUN-SHARD EARNED!", Color(1.0, 0.90, 0.36))


func _fail_trial() -> void:
	_active = false
	for r in _ring_nodes:
		r.visible = false
	GameState.emit_trial_state(false, "", 0, 0, 0.0)
	AudioDirector.play_sfx("ui_click", -3.0, 0.65)
	GameState.emit_callout("TRIAL EXPIRED", "Touch the Trial Ring to Retry!", Color(1.0, 0.56, 0.34))


func _process(delta: float) -> void:
	_t += delta
	if _starter_mesh and _starter_mesh.visible:
		_starter_mesh.rotation.y += delta * 1.4
		_starter_mesh.position.y = 1.65 + sin(_t * 2.6) * 0.16

	if _active:
		_time_left -= delta
		GameState.emit_trial_state(true, trial_title, _collected_count, _ring_nodes.size(), _time_left)
		for i in range(_ring_nodes.size()):
			if not _ring_hit[i]:
				_ring_nodes[i].rotation.y += delta * 2.2
		if _time_left <= 0.0:
			_fail_trial()
