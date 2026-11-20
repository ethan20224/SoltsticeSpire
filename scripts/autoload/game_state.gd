extends Node
## Global run state, active character selection, checkpoint tracking, Sun-Shards, Solar Motes,
## persistent PB/ghost recording, world splits, rewind window, and settings.

signal character_changed(char_id: String)
signal checkpoint_updated(checkpoint_id: String, world_idx: int, pos: Vector3)
signal world_entered(world_idx: int, world_name: String, subtitle: String)
signal shard_collected(total_shards: int, max_shards: int)
signal solar_motes_changed(total: int)
signal rewind_window_changed(remaining_sec: float, active: bool)
signal gameplay_callout(title: String, subtitle: String, accent_color: Color)
signal solar_charge_changed(charged: bool)
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
		"perk_title": "Ember Grace",
		"perk_desc": "Forgiving edge-jumps & higher auto-mantle reach.",
		"model": "res://assets/models/characters/pip.glb",
		"trail_core": Color(1.0, 0.90, 0.45),
		"trail_edge": Color(0.95, 0.38, 0.16),
		"ring_color": Color(1.0, 0.88, 0.48, 0.92),
	},
	"koko": {
		"name": "Koko",
		"title": "The Clockwork Fox",
		"tagline": "Porcelain-and-brass automaton coiled with boundless kinetic spring.",
		"perk_title": "Clockwork Surge",
		"perk_desc": "Snappier air-dash burst & faster slide-long-jump.",
		"model": "res://assets/models/characters/koko.glb",
		"trail_core": Color(0.55, 0.96, 1.0),
		"trail_edge": Color(0.18, 0.62, 0.98),
		"ring_color": Color(0.45, 0.92, 1.0, 0.92),
	},
	"vesper": {
		"name": "Vesper",
		"title": "The Origami Moth",
		"tagline": "Folded paper-wing wanderer gliding through twilight drafts.",
		"perk_title": "Origami Flutter",
		"perk_desc": "Hold Jump mid-air for a brief gentle wing-glide.",
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

const ROMAN_NUMERALS := ["I", "II", "III", "IV", "V", "VI"]
const TOTAL_SHARDS := 18
const SUMMIT_ALTITUDE := 1085.0
const REWIND_WINDOW_MAX := 30.0
const SAVE_PATH := "user://solstice_spire_save.json"

var selected_character: String = "pip"
var is_playing: bool = false
var is_paused: bool = false
var is_cutscene: bool = false
var has_finished: bool = false

var current_checkpoint_id: String = "w1_start"
var current_checkpoint_pos: Vector3 = Vector3(0.0, 1.2, 0.0)
var current_checkpoint_yaw: float = 0.0
var current_world_idx: int = 0
var unlocked_worlds: Array[int] = [0]
var world_spawn_points: Dictionary = {}  # world_idx -> {"pos": Vector3, "yaw": float, "id": String}
var activated_checkpoints: Dictionary = {}

var collected_shards: Dictionary = {}
var solar_motes: int = 0
var run_time: float = 0.0
var total_falls: int = 0
var current_altitude: float = 0.0
var best_altitude: float = 0.0
var best_ever_altitude: float = 0.0
var best_run_time: float = 0.0
var best_run_samples: Array = []
var current_run_samples: Array = []
var best_world_splits: Dictionary = {}
var current_world_splits: Dictionary = {}

var rewind_window_remaining: float = 0.0
var rewind_window_active: bool = false

var current_flow: float = 0.0
var current_streak: int = 0
var max_flow_streak: int = 0

var mouse_sensitivity: float = 0.0024
var invert_y: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.85
var sfx_volume: float = 1.0

var _last_saved_best_alt: float = 0.0


func _ready() -> void:
	_load_persistent_data()


func _process(delta: float) -> void:
	if is_playing and not is_paused and not is_cutscene and not has_finished:
		run_time += delta


func _load_persistent_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed as Dictionary
	best_ever_altitude = float(data.get("best_ever_altitude", 0.0))
	_last_saved_best_alt = best_ever_altitude
	best_run_time = float(data.get("best_run_time", 0.0))
	var loaded_samples: Variant = data.get("best_run_samples", [])
	if typeof(loaded_samples) == TYPE_ARRAY:
		best_run_samples = (loaded_samples as Array).duplicate(true)
	var loaded_splits: Variant = data.get("best_world_splits", {})
	if typeof(loaded_splits) == TYPE_DICTIONARY:
		best_world_splits.clear()
		for k: Variant in (loaded_splits as Dictionary).keys():
			best_world_splits[int(k)] = float((loaded_splits as Dictionary)[k])
	mouse_sensitivity = clampf(float(data.get("mouse_sensitivity", mouse_sensitivity)), 0.0004, 0.01)
	invert_y = bool(data.get("invert_y", invert_y))
	music_volume = clampf(float(data.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", sfx_volume)), 0.0, 1.0)


func save_persistent_data() -> void:
	var splits_serializable: Dictionary = {}
	for k: Variant in best_world_splits.keys():
		splits_serializable[str(k)] = float(best_world_splits[k])
	var payload := {
		"best_ever_altitude": snappedf(best_ever_altitude, 0.01),
		"best_run_time": snappedf(best_run_time, 0.01),
		"best_run_samples": best_run_samples,
		"best_world_splits": splits_serializable,
		"mouse_sensitivity": mouse_sensitivity,
		"invert_y": invert_y,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload))
		_last_saved_best_alt = best_ever_altitude


func set_character(char_id: String) -> void:
	if is_playing:
		return
	if not CHARACTERS.has(char_id):
		return
	selected_character = char_id
	character_changed.emit(char_id)


func start_run() -> void:
	is_playing = true
	is_paused = false
	is_cutscene = false
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
	solar_motes = 0
	has_finished = false
	collected_shards.clear()
	activated_checkpoints.clear()
	current_run_samples.clear()
	current_world_splits.clear()
	rewind_window_active = false
	rewind_window_remaining = 0.0
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
	solar_motes_changed.emit(0)
	rewind_window_changed.emit(0.0, false)
	solar_charge_changed.emit(false)


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
	if best_ever_altitude > _last_saved_best_alt:
		save_persistent_data()
	checkpoint_updated.emit(cp_id, world_idx, pos)
	return is_new


func update_altitude(y_pos: float) -> void:
	current_altitude = maxf(0.0, y_pos)
	if current_altitude > best_altitude:
		best_altitude = current_altitude
	if current_altitude > best_ever_altitude:
		best_ever_altitude = current_altitude
		if best_ever_altitude >= _last_saved_best_alt + 4.0:
			save_persistent_data()
	altitude_updated.emit(current_altitude, best_altitude)

	var detected_world := 0
	for w in WORLDS:
		if y_pos >= float(w["y_min"]) - 4.0:
			detected_world = int(w["idx"])
	if detected_world != current_world_idx:
		var entered_higher := detected_world > current_world_idx
		current_world_idx = detected_world
		if not unlocked_worlds.has(detected_world):
			unlocked_worlds.append(detected_world)
			unlocked_worlds.sort()
		var winfo: Dictionary = WORLDS[detected_world]
		world_entered.emit(detected_world, winfo["name"], winfo["subtitle"])
		if entered_higher and detected_world > 0 and not current_world_splits.has(detected_world):
			record_world_split(detected_world)


func record_world_split(world_idx: int) -> void:
	if world_idx <= 0 or current_world_splits.has(world_idx):
		return
	current_world_splits[world_idx] = run_time
	var roman: String = ROMAN_NUMERALS[clampi(world_idx, 0, ROMAN_NUMERALS.size() - 1)]
	var title := "REALM %s SPLIT" % roman
	var has_best := best_world_splits.has(world_idx) or best_world_splits.has(str(world_idx))
	if has_best:
		var best_val: float = float(best_world_splits.get(world_idx, best_world_splits.get(str(world_idx), run_time)))
		var delta_s := run_time - best_val
		if delta_s <= 0.0:
			emit_callout(title, "-%.1fs AHEAD" % absf(delta_s), Color(0.45, 0.96, 0.58))
		else:
			emit_callout(title, "+%.1fs BEHIND" % delta_s, Color(1.0, 0.72, 0.30))
	else:
		emit_callout(title, format_time(run_time), Color(1.0, 0.84, 0.38))


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


func collect_solar_mote() -> void:
	solar_motes += 1
	solar_motes_changed.emit(solar_motes)


func emit_callout(title: String, subtitle: String = "", accent: Color = Color(1.0, 0.82, 0.34)) -> void:
	gameplay_callout.emit(title, subtitle, accent)


func set_rewind_window(rem: float, active: bool) -> void:
	rewind_window_remaining = maxf(0.0, rem)
	rewind_window_active = active
	rewind_window_changed.emit(rewind_window_remaining, rewind_window_active)


func trigger_summit_victory() -> void:
	if has_finished:
		return
	has_finished = true
	best_ever_altitude = maxf(best_ever_altitude, maxf(current_altitude, SUMMIT_ALTITUDE))
	if best_run_time <= 0.0 or run_time < best_run_time:
		best_run_time = run_time
		best_run_samples = current_run_samples.duplicate(true)
		best_world_splits = current_world_splits.duplicate(true)
	save_persistent_data()
	summit_reached.emit(run_time, total_falls, collected_shards.size(), max_flow_streak)


func format_time(sec: float) -> String:
	var mins := int(floor(sec / 60.0))
	var rem := sec - float(mins * 60)
	return "%02d:%05.2f" % [mins, rem]
