extends Node3D
class_name CheckpointShrine
## Living Sky Shrine Checkpoint - physically blooms its 4 stone petals, lifts its crystal core,
## ignites a sky beacon visible from higher worlds, and saves player respawn progress.

@export var checkpoint_id: String = "w1_cp1"
@export var world_idx: int = 0
@export var spawn_yaw_deg: float = 0.0
@export var is_world_start: bool = false
@export var is_summit_crown: bool = false
@export var spawn_offset: Vector3 = Vector3(0.0, 0.8, 0.0)

var _activated: bool = false
var _bloom_t: float = 0.0
var _time: float = 0.0
var _petals: Array[Node3D] = []
var _core: Node3D
var _beacon: MeshInstance3D
var _beacon_mat: StandardMaterial3D
var _omni: OmniLight3D


func _ready() -> void:
	add_to_group("checkpoint_shrine")
	_build_visuals()
	_build_trigger()
	if is_world_start:
		GameState.register_world_spawn(world_idx, checkpoint_id, global_position + spawn_offset, deg_to_rad(spawn_yaw_deg))


func _build_visuals() -> void:
	var model_path := "res://assets/models/common/sky_shrine.glb"
	if ResourceLoader.exists(model_path):
		var inst: Node3D = load(model_path).instantiate()
		add_child(inst)
		for i in range(4):
			var p := inst.find_child("ShrinePetal%d" % i, true, false) as Node3D
			if p:
				_petals.append(p)
		_core = inst.find_child("ShrineCore", true, false) as Node3D

	# Luminous vertical beacon column (unfolds skyward upon activation so you can see past checkpoints below!)
	_beacon = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.14
	cyl.bottom_radius = 0.34
	cyl.height = 42.0
	cyl.radial_segments = 12
	_beacon.mesh = cyl
	_beacon.position = Vector3(0.0, 22.0, 0.0)
	_beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beacon_mat = StandardMaterial3D.new()
	_beacon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beacon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beacon_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beacon_mat.albedo_color = Color(1.0, 0.84, 0.42, 0.0)
	_beacon.material_override = _beacon_mat
	_beacon.visible = false
	add_child(_beacon)

	_omni = OmniLight3D.new()
	_omni.position = Vector3(0.0, 2.2, 0.0)
	_omni.light_color = Color(1.0, 0.76, 0.36)
	_omni.light_energy = 3.2
	_omni.omni_range = 11.5
	_omni.omni_attenuation = 1.25
	_omni.distance_fade_enabled = true
	_omni.distance_fade_begin = 85.0
	_omni.distance_fade_length = 30.0
	add_child(_omni)
	WorldHelper.add_lamp_halo(self, Vector3(0.0, 2.1, 0.0), Color(1.0, 0.78, 0.38), 2.1, 0.75)


func _build_trigger() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 2.6 if not is_summit_crown else 4.2
	shape.height = 3.8
	col.shape = shape
	col.position = Vector3(0.0, 1.8, 0.0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if is_summit_crown:
		if not _activated:
			_activated = true
			_ignite_visuals()
			AudioDirector.play_sfx("summit_fanfare", 0.0, 1.0)
			GameState.trigger_summit_victory()
		return

	var spawn_pos := global_position + spawn_offset
	var is_new := GameState.activate_checkpoint(checkpoint_id, world_idx, spawn_pos, deg_to_rad(spawn_yaw_deg))
	if body.has_method("on_shrine_activated"):
		body.on_shrine_activated()
	if not _activated or is_new:
		_activated = true
		_ignite_visuals()
		AudioDirector.play_sfx("checkpoint", -1.0, 1.0)
		if body.has_method("add_flow"):
			body.add_flow(0.35, false)


func _ignite_visuals() -> void:
	_beacon.visible = true
	_omni.light_color = Color(1.0, 0.84, 0.40)
	_omni.light_energy = 3.8
	_omni.omni_range = 16.0


func _process(delta: float) -> void:
	_time += delta
	if _activated:
		_bloom_t = minf(1.0, _bloom_t + delta * 2.2)

	var ease_b := 1.0 - pow(1.0 - _bloom_t, 3.0)
	for i in range(_petals.size()):
		var p := _petals[i]
		# Each petal is oriented radially; tilting outward around local Y opens the lotus beautifully!
		p.rotation.y = lerpf(0.0, 0.62, ease_b)

	if _core:
		_core.rotation.y += delta * (1.0 + ease_b * 2.6)
		_core.position.y = 1.92 + ease_b * 0.55 + sin(_time * 2.6) * 0.14

	if _beacon and _beacon.visible:
		var pulse := 0.24 + 0.06 * sin(_time * 3.5)
		_beacon_mat.albedo_color = Color(1.0, 0.84, 0.42, pulse * ease_b)
