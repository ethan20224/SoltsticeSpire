extends Node
## Global run state, active character selection, checkpoint tracking, Sun-Shards, and settings.

signal character_changed(char_id: String)
signal checkpoint_updated(checkpoint_id: String, world_idx: int, pos: Vector3)
signal world_entered(world_idx: int, world_name: String, subtitle: String)
signal shard_collected(total_shards: int, max_shards: int)
signal flow_changed(flow_value: float, streak: int)
signal altitude_updated(altitude_m: float, best_m: float)
signal fall_recorded(total_falls: int)
signal summit_reached(run_time: float, total_falls: int, shards: int, max_flow_streak: int)
signal game_started()

const CHARACTERS := {
	"pip": {
		"name": "Pip",
		"title": "The Lantern Pilgrim",
		"tagline": "Warm ember spirit wandering skyward with an heirloom lantern.",
		"model": "res://assets/models/characters/pip.glb",
		"trail_core": Color(1.0, 0.90, 0.45),
		"trail_edge": Color(0.95, 0.38, 0.16),
		"ring_color": Color(1.0, 0.88, 0.48, 0.92),
	},
	"koko": {
		"name": "Koko",
		"title": "The Clockwork Fox",
		"tagline": "Porcelain-and-brass automaton coiled with boundless kinetic spring.",
		"model": "res://assets/models/characters/koko.glb",
		"trail_core": Color(0.55, 0.96, 1.0),
		"trail_edge": Color(0.18, 0.62, 0.98),
		"ring_color": Color(0.45, 0.92, 1.0, 0.92),
	},
	"vesper": {
		"name": "Vesper",
		"title": "The Origami Moth",
		"tagline": "Folded paper-wing wanderer gliding through twilight drafts.",
		"model": "res://assets/models/characters/vesper.glb",
		"trail_core": Color(1.0, 0.86, 1.0),
		"trail_edge": Color(0.70, 0.34, 0.96),
		"ring_color": Color(0.95, 0.78, 1.0, 0.92),
	},
}

const WORLDS := [
	{"idx": 0, "name": "The Sunken Conservatory", "subtitle": "Sunlit Arches & Blooming Canopies", "y_min": 0.0, "y_max": 175.0},
	{"idx": 1, "name": "Foundry of Floating Bells", "subtitle": "Amber Gears & Resonant Bronze", "y_min": 175.0, "y_max": 355.0},
	{"idx": 2, "name": "The Origami Monsoon", "subtitle": "Frozen Rain & Unfolding Bridges", "y_min": 355.0, "y_max": 540.0},
	{"idx": 3, "name": "The Shattered Mirror Gallery", "subtitle": "Iridescent Prisms & Portal Frames", "y_min": 540.0, "y_max": 730.0},
	{"idx": 4, "name": "The Cloud-Whale Library", "subtitle": "Aurora Dreams & Luminous Tomes", "y_min": 730.0, "y_max": 920.0},
	{"idx": 5, "name": "The Crown of the Sun", "subtitle": "Stratosphere Monoliths & Summit", "y_min": 920.0, "y_max": 1120.0},
]

const TOTAL_SHARDS := 18
const SUMMIT_ALTITUDE := 1085.0

var selected_character: String = "pip"
var is_playing: bool = false
var is_paused: bool = false
var has_finished: bool = false

var current_checkpoint_id: String = "w1_start"
var current_checkpoint_pos: Vector3 = Vector3(0.0, 1.2, 0.0)
var current_checkpoint_yaw: float = 0.0
var current_world_idx: int = 0
var unlocked_worlds: Array[int] = [0]
var world_spawn_points: Dictionary = {}  # world_idx -> {"pos": Vector3, "yaw": float, "id": String}
var activated_checkpoints: Dictionary = {}

var collected_shards: Dictionary = {}
var run_time: float = 0.0
var total_falls: int = 0
var current_altitude: float = 0.0
var best_altitude: float = 0.0
var current_flow: float = 0.0
var current_streak: int = 0
var max_flow_streak: int = 0

var mouse_sensitivity: float = 0.0024
var invert_y: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.85


func _process(delta: float) -> void:
	if is_playing and not is_paused and not has_finished:
		run_time += delta


func set_character(char_id: String) -> void:
	if not CHARACTERS.has(char_id):
		return
	selected_character = char_id
	character_changed.emit(char_id)


func start_run() -> void:
	is_playing = true
	is_paused = false
	has_finished = false
	game_started.emit()


func reset_full_run() -> void:
	run_time = 0.0
	total_falls = 0
	current_altitude = 0.0
	best_altitude = 0.0
	current_flow = 0.0
	current_streak = 0
	max_flow_streak = 0
	has_finished = false
	collected_shards.clear()
	activated_checkpoints.clear()
	current_world_idx = 0
	if world_spawn_points.has(0):
		var sp: Dictionary = world_spawn_points[0]
		current_checkpoint_id = sp["id"]
		current_checkpoint_pos = sp["pos"]
		current_checkpoint_yaw = sp["yaw"]
	else:
		current_checkpoint_id = "w1_start"
		current_checkpoint_pos = Vector3(0.0, 1.2, 0.0)
		current_checkpoint_yaw = 0.0
	checkpoint_updated.emit(current_checkpoint_id, 0, current_checkpoint_pos)
	shard_collected.emit(0, TOTAL_SHARDS)


func register_world_spawn(world_idx: int, cp_id: String, pos: Vector3, yaw: float = 0.0) -> void:
	world_spawn_points[world_idx] = {"id": cp_id, "pos": pos, "yaw": yaw}
	if world_idx == 0 and current_checkpoint_id == "w1_start":
		current_checkpoint_pos = pos
		current_checkpoint_yaw = yaw


func activate_checkpoint(cp_id: String, world_idx: int, pos: Vector3, yaw: float = 0.0) -> bool:
	var is_new := not activated_checkpoints.has(cp_id)
	activated_checkpoints[cp_id] = true
	current_checkpoint_id = cp_id
	current_checkpoint_pos = pos
	current_checkpoint_yaw = yaw
	if not unlocked_worlds.has(world_idx):
		unlocked_worlds.append(world_idx)
		unlocked_worlds.sort()
	checkpoint_updated.emit(cp_id, world_idx, pos)
	return is_new


func update_altitude(y_pos: float) -> void:
	current_altitude = maxf(0.0, y_pos)
	if current_altitude > best_altitude:
		best_altitude = current_altitude
	altitude_updated.emit(current_altitude, best_altitude)

	var detected_world := 0
	for w in WORLDS:
		if y_pos >= w["y_min"] - 4.0:
			detected_world = w["idx"]
	if detected_world != current_world_idx:
		current_world_idx = detected_world
		if not unlocked_worlds.has(detected_world):
			unlocked_worlds.append(detected_world)
			unlocked_worlds.sort()
		var winfo: Dictionary = WORLDS[detected_world]
		world_entered.emit(detected_world, winfo["name"], winfo["subtitle"])


func update_flow(flow_val: float, streak: int) -> void:
	current_flow = clampf(flow_val, 0.0, 1.0)
	current_streak = streak
	if streak > max_flow_streak:
		max_flow_streak = streak
	flow_changed.emit(current_flow, current_streak)


func record_fall() -> void:
	total_falls += 1
	fall_recorded.emit(total_falls)


func collect_shard(shard_id: String) -> bool:
	if collected_shards.has(shard_id):
		return false
	collected_shards[shard_id] = true
	shard_collected.emit(collected_shards.size(), TOTAL_SHARDS)
	return true


func trigger_summit_victory() -> void:
	if has_finished:
		return
	has_finished = true
	summit_reached.emit(run_time, total_falls, collected_shards.size(), max_flow_streak)


func format_time(sec: float) -> String:
	var mins := int(floor(sec / 60.0))
	var rem := sec - float(mins * 60)
	return "%02d:%05.2f" % [mins, rem]
