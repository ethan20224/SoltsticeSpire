extends AnimatableBody3D
class_name FoldingBridge
## World 3 Surreal Origami Folding Tile - hovers folded edge-on until the player draws near,
## then snaps flat into walkable existence one beat before landing with crisp paper kinetics!

@export var unfold_distance: float = 16.5
@export var folded_pitch_deg: float = 36.0
@export var folded_drop_y: float = -0.55
@export var domino_mode: bool = false
@export var domino_is_starter: bool = false
@export var domino_collapse_delay: float = 1.65

var next_domino_tile: FoldingBridge = null

var _base_pos: Vector3
var _base_rot: Vector3
var _unfold_t: float = 0.0
var _was_open: bool = false
var _player: Node3D = null
var _domino_open_timer: float = 0.0
var _domino_propagated: bool = false


func _ready() -> void:
	sync_to_physics = true
	_base_pos = position
	_base_rot = rotation
	if domino_mode:
		folded_pitch_deg = 74.0
		folded_drop_y = -0.95
		if domino_is_starter:
			_domino_open_timer = 9999.0
			_unfold_t = 1.0
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		var col := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(3.8, 1.6, 3.8)
		col.shape = bx
		col.position = Vector3(0.0, 0.7, 0.0)
		area.add_child(col)
		add_child(area)
		area.body_entered.connect(_on_domino_stepped)


func _on_domino_stepped(body: Node3D) -> void:
	if not domino_mode or not body.is_in_group("player"):
		return
	if domino_is_starter:
		_trigger_next_domino()
	else:
		_domino_open_timer = maxf(_domino_open_timer, domino_collapse_delay)
		_trigger_next_domino()


func trigger_domino_open(open_duration: float = 2.6) -> void:
	_domino_open_timer = maxf(_domino_open_timer, open_duration)
	_domino_propagated = false


func _trigger_next_domino() -> void:
	if _domino_propagated or next_domino_tile == null or not is_instance_valid(next_domino_tile):
		return
	_domino_propagated = true
	var t := get_tree().create_timer(0.18)
	t.timeout.connect(func() -> void:
		if is_instance_valid(next_domino_tile):
			next_domino_tile.trigger_domino_open(2.8)
	)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_player = players[0] as Node3D
	var should_open := false
	if domino_mode:
		if domino_is_starter:
			should_open = true
			if _player and global_position.distance_to(_player.global_position) > 14.0:
				_domino_propagated = false
		else:
			if _domino_open_timer > 0.0:
				_domino_open_timer -= delta
				should_open = true
			elif _player and global_position.distance_to(_player.global_position) <= 6.2:
				# Safety grace if player jumps straight onto an unopened domino tile!
				_domino_open_timer = 2.2
				should_open = true
				_trigger_next_domino()
	elif _player:
		should_open = global_position.distance_to(_player.global_position) <= unfold_distance

	var target := 1.0 if should_open else 0.0
	_unfold_t = move_toward(_unfold_t, target, delta * (6.2 if domino_mode and should_open else (4.6 if should_open else 2.2)))

	if should_open and not _was_open and _unfold_t > 0.35:
		_was_open = true
		AudioDirector.play_sfx("step_paper", -6.0, randf_range(1.12, 1.38))
	elif not should_open and _unfold_t < 0.1:
		_was_open = false

	var e := 1.0 - pow(1.0 - _unfold_t, 3.0)
	position = _base_pos + Vector3(0.0, lerpf(folded_drop_y, 0.0, e), 0.0)
	rotation = _base_rot + Vector3(deg_to_rad(lerpf(folded_pitch_deg, 0.0, e)), 0.0, 0.0)
