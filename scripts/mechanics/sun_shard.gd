extends Node3D
class_name SunShard
## Optional high-skill daredevil collectible floating along riskier lines across all 6 worlds.

@export var shard_id: String = "w1_s1"

var _visual: Node3D
var _collected: bool = false
var _t: float = 0.0


func _ready() -> void:
	add_to_group("sun_shard")
	var path := "res://assets/models/common/sun_shard.glb"
	if ResourceLoader.exists(path):
		_visual = load(path).instantiate()
		WorldHelper.disable_shadows(_visual)
		add_child(_visual)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.76, 0.32)
	light.light_energy = 2.2
	light.omni_range = 8.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 65.0
	light.distance_fade_length = 25.0
	add_child(light)
	WorldHelper.add_lamp_halo(self, Vector3(0.0, 0.0, 0.0), Color(1.0, 0.78, 0.34), 1.6, 0.70)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 1.55
	col.shape = sp
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_enter)


func _on_enter(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	if GameState.collect_shard(shard_id):
		AudioDirector.play_sfx("sun_shard", -1.0, 1.0)
		if body.has_method("add_flow"):
			body.add_flow(0.45, false)
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_t += delta
	if _visual:
		_visual.rotation.y += delta * 1.9
		_visual.position.y = sin(_t * 3.2) * 0.24
