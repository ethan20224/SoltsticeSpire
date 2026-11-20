extends Node3D
class_name BouncePad
## Elastic springy bounce pad (World 1 Botanical Lily Cap, World 3 Silk Parasol, World 5 Dream Jelly).
## Launches player along launch_velocity with squash recoil, chime, and full air-move reset.

@export var bounce_up_speed: float = 19.5
@export var forward_boost: Vector3 = Vector3.ZERO
@export var trigger_radius: float = 2.0
@export var pad_color: Color = Color(0.28, 0.78, 0.44)

var _visual_root: Node3D
var _recoil_t: float = 0.0
var _cooldown: float = 0.0


func _ready() -> void:
	add_to_group("bounce_pad")
	_visual_root = get_node_or_null("Visual")
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = trigger_radius
	cyl.height = 1.1
	col.shape = cyl
	col.position = Vector3(0.0, 0.45, 0.0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0 or not body.is_in_group("player"):
		return
	_cooldown = 0.22
	_recoil_t = 1.0
	var impulse := Vector3(forward_boost.x, bounce_up_speed, forward_boost.z)
	if body.has_method("apply_bounce"):
		body.apply_bounce(impulse, true)
	AudioDirector.play_sfx("bounce", -1.5, randf_range(0.95, 1.10))


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _recoil_t > 0.001:
		_recoil_t = maxf(0.0, _recoil_t - delta * 3.8)
		if _visual_root:
			var osc := sin(_recoil_t * PI * 3.0) * _recoil_t * 0.28
			_visual_root.scale = Vector3(1.0 + osc, 1.0 - osc * 1.4, 1.0 + osc)
	elif _visual_root:
		_visual_root.scale = Vector3.ONE
