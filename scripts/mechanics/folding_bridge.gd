extends AnimatableBody3D
class_name FoldingBridge
## World 3 Surreal Origami Folding Tile - hovers folded edge-on until the player draws near,
## then snaps flat into walkable existence one beat before landing with crisp paper kinetics!

@export var unfold_distance: float = 16.5
@export var folded_pitch_deg: float = 36.0
@export var folded_drop_y: float = -0.55

var _base_pos: Vector3
var _base_rot: Vector3
var _unfold_t: float = 0.0
var _was_open: bool = false
var _player: Node3D = null


func _ready() -> void:
	sync_to_physics = true
	_base_pos = position
	_base_rot = rotation


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_player = players[0] as Node3D
	var should_open := false
	if _player:
		should_open = global_position.distance_to(_player.global_position) <= unfold_distance

	var target := 1.0 if should_open else 0.0
	_unfold_t = move_toward(_unfold_t, target, delta * (4.6 if should_open else 1.8))

	if should_open and not _was_open and _unfold_t > 0.35:
		_was_open = true
		AudioDirector.play_sfx("step_paper", -7.0, randf_range(1.1, 1.35))
	elif not should_open and _unfold_t < 0.1:
		_was_open = false

	var e := 1.0 - pow(1.0 - _unfold_t, 3.0)
	position = _base_pos + Vector3(0.0, lerpf(folded_drop_y, 0.0, e), 0.0)
	rotation = _base_rot + Vector3(deg_to_rad(lerpf(folded_pitch_deg, 0.0, e)), 0.0, 0.0)
