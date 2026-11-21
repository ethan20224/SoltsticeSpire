extends Node
## Global run state, active character selection, checkpoint tracking, Sun-Shards, Solar Motes,
## persistent PB/ghost recording, world splits, rewind window, and settings.

signal character_changed(char_id: String)
signal checkpoint_updated(checkpoint_id: String, world_idx: int, pos: Vector3)
signal world_entered(world_idx: int, world_name: String, subtitle: String)
signal shard_collected(total_shards: int, max_shards: int)
signal solar_motes_changed(total: int)
signal rewind_window_changed(remaining_sec: float, active: bool)
signal pilgrim_assist_offer_changed(target_cp: Dictionary, active: bool)
signal gameplay_callout(title: String, subtitle: String, accent_color: Color)
signal solar_charge_changed(charged: bool)
signal flow_changed(flow_value: float, streak: int)
signal altitude_updated(altitude_m: float, best_m: float)
signal fall_recorded(total_falls: int)
signal summit_reached(run_time: float, total_falls: int, shards: int, max_flow_streak: int)
signal game_started()
signal game_mode_changed(mode: String)
signal graphics_settings_changed()
signal badge_unlocked(badge_id: String, title: String, desc: String)
signal cosmetic_changed()
signal world_unlocked(world_idx: int)

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
	{
		"idx": 0, "name": "The Sunken Conservatory", "subtitle": "Sunlit Arches & Blooming Canopies",
		"story": "Act I · The Dawnbreaker cannot climb past the conservatory gale. From here, you ascend on foot.",
		"y_min": 0.0, "y_max": 175.0,
	},
	{
		"idx": 1, "name": "Foundry of Floating Bells", "subtitle": "Amber Gears & Resonant Bronze",
		"story": "Act II · The bell-smiths fled when the Sun-Heart cracked. Strike their bronze bells to awaken the Spire.",
		"y_min": 175.0, "y_max": 355.0,
	},
	{
		"idx": 2, "name": "The Origami Monsoon", "subtitle": "Frozen Rain & Unfolding Bridges",
		"story": "Act III · A storm rose where the sun's warmth faded. Paper cranes still carry the valley's prayers skyward.",
		"y_min": 355.0, "y_max": 540.0,
	},
	{
		"idx": 3, "name": "The Shattered Mirror Gallery", "subtitle": "Iridescent Prisms & Portal Frames",
		"story": "Act IV · The cathedral lenses fractured from the shockwave. Tread lightly — the glass is giving way.",
		"y_min": 540.0, "y_max": 730.0,
	},
	{
		"idx": 4, "name": "The Cloud-Whale Library", "subtitle": "Aurora Dreams & Luminous Tomes",
		"story": "Act V · Above the storm, the ancient Cloud-Whale circles in the dark, guarding the last path to dawn.",
		"y_min": 730.0, "y_max": 920.0,
	},
	{
		"idx": 5, "name": "The Crown of the Sun", "subtitle": "Stratosphere Monoliths & Summit",
		"story": "Act VI · One thousand meters above home. The valley waits in twilight — rekindle the Solstice Crown!",
		"y_min": 920.0, "y_max": 1120.0,
	},
]

const ROMAN_NUMERALS := ["I", "II", "III", "IV", "V", "VI"]
const TOTAL_SHARDS := 18
const SUMMIT_ALTITUDE := 1085.0
const REWIND_WINDOW_MAX := 30.0
const SAVE_PATH := "user://solstice_spire_save.json"

const BADGE_INFO := {
	"summit_conqueror": {"title": "Summit Conqueror", "desc": "Reach the 1,085m Crown of the Sun.", "tag": "CROWN"},
	"purist_legend": {"title": "Purist Legend", "desc": "Summit in Purist Mode — zero shrines, zero rewind.", "tag": "PURIST"},
	"sun_collector": {"title": "Sun Collector", "desc": "Gather all 18 Sun-Shards in a single climb.", "tag": "18/18"},
	"untouchable_flow": {"title": "Untouchable Flow", "desc": "Chain a x12+ Flow streak.", "tag": "FLOW x12"},
	"shortcut_daredevil": {"title": "Shortcut Daredevil", "desc": "Conquer a high-risk Pro Shortcut.", "tag": "SKIP"},
	"meteor_master": {"title": "Meteor Master", "desc": "Trigger a Sky-Dive Meteor Super-Bounce.", "tag": "METEOR"},
}

var selected_character: String = "pip"
var game_mode: String = "pilgrim"  # "pilgrim" or "purist"
var is_playing: bool = false
var is_paused: bool = false
var is_cutscene: bool = false
var has_finished: bool = false
var victory_skydive_active: bool = false

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

var graphics_quality: String = "high"  # "low", "medium", "high"
var vsync_enabled: bool = true
var camera_fov: float = 72.0
var preferred_input_mode: String = "keyboard"  # "keyboard", "gamepad", "phone"
var preferred_gamepad_style: String = "ps5"  # "ps5", "xbox", "switch"

var unlocked_badges: Dictionary = {}
var crown_unlocked: bool = false
var crown_equipped: bool = true
var purist_halo_unlocked: bool = false
var purist_halo_equipped: bool = true
var leaderboard: Array = []
var last_victory_summary: Dictionary = {}
var all_checkpoints: Array[Dictionary] = []
var pilgrim_assist_active: bool = false
var pilgrim_assist_target: Dictionary = {}

var _last_saved_best_alt: float = 0.0


func _ready() -> void:
	_load_persistent_data()
	_apply_vsync()


func _process(delta: float) -> void:
	if is_playing and not is_paused and not is_cutscene and not has_finished:
		run_time += delta


func _apply_vsync() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)


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

	var loaded_mode := str(data.get("game_mode", game_mode))
	game_mode = "purist" if loaded_mode == "purist" else "pilgrim"
	var loaded_q := str(data.get("graphics_quality", graphics_quality))
	graphics_quality = loaded_q if loaded_q in ["low", "medium", "high"] else "high"
	vsync_enabled = bool(data.get("vsync_enabled", vsync_enabled))
	camera_fov = clampf(float(data.get("camera_fov", camera_fov)), 58.0, 96.0)
	var loaded_imode := str(data.get("preferred_input_mode", preferred_input_mode))
	preferred_input_mode = loaded_imode if loaded_imode in ["keyboard", "gamepad", "phone"] else "keyboard"
	var loaded_gstyle := str(data.get("preferred_gamepad_style", preferred_gamepad_style))
	preferred_gamepad_style = loaded_gstyle if loaded_gstyle in ["ps5", "xbox", "switch"] else "ps5"

	unlocked_worlds.clear()
	unlocked_worlds.append(0)
	var loaded_worlds: Variant = data.get("unlocked_worlds", [0])
	if typeof(loaded_worlds) == TYPE_ARRAY:
		for w: Variant in loaded_worlds as Array:
			var wi := clampi(int(w), 0, WORLDS.size() - 1)
			if not unlocked_worlds.has(wi):
				unlocked_worlds.append(wi)
	unlocked_worlds.sort()

	unlocked_badges.clear()
	var loaded_badges: Variant = data.get("unlocked_badges", {})
	if typeof(loaded_badges) == TYPE_DICTIONARY:
		for bk: Variant in (loaded_badges as Dictionary).keys():
			var b_id := str(bk)
			if BADGE_INFO.has(b_id) and bool((loaded_badges as Dictionary)[bk]):
				unlocked_badges[b_id] = true

	crown_unlocked = bool(data.get("crown_unlocked", crown_unlocked))
	crown_equipped = bool(data.get("crown_equipped", crown_equipped))
	purist_halo_unlocked = bool(data.get("purist_halo_unlocked", purist_halo_unlocked))
	purist_halo_equipped = bool(data.get("purist_halo_equipped", purist_halo_equipped))

	leaderboard.clear()
	var loaded_lb: Variant = data.get("leaderboard", [])
	if typeof(loaded_lb) == TYPE_ARRAY:
		for item: Variant in loaded_lb as Array:
			if typeof(item) == TYPE_DICTIONARY:
				leaderboard.append((item as Dictionary).duplicate(true))
		if leaderboard.size() > 8:
			leaderboard.resize(8)


func save_persistent_data() -> void:
	var splits_serializable: Dictionary = {}
	for k: Variant in best_world_splits.keys():
		splits_serializable[str(k)] = float(best_world_splits[k])
	var worlds_serializable: Array = []
	for w in unlocked_worlds:
		worlds_serializable.append(int(w))
	var payload := {
		"best_ever_altitude": snappedf(best_ever_altitude, 0.01),
		"best_run_time": snappedf(best_run_time, 0.01),
		"best_run_samples": best_run_samples,
		"best_world_splits": splits_serializable,
		"mouse_sensitivity": mouse_sensitivity,
		"invert_y": invert_y,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"game_mode": game_mode,
		"graphics_quality": graphics_quality,
		"vsync_enabled": vsync_enabled,
		"camera_fov": camera_fov,
		"preferred_input_mode": preferred_input_mode,
		"preferred_gamepad_style": preferred_gamepad_style,
		"unlocked_worlds": worlds_serializable,
		"unlocked_badges": unlocked_badges,
		"crown_unlocked": crown_unlocked,
		"crown_equipped": crown_equipped,
		"purist_halo_unlocked": purist_halo_unlocked,
		"purist_halo_equipped": purist_halo_equipped,
		"leaderboard": leaderboard,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload))
		_last_saved_best_alt = best_ever_altitude


func is_purist_mode() -> bool:
	return game_mode == "purist"


func set_game_mode(mode: String) -> void:
	var clean := "purist" if mode == "purist" else "pilgrim"
	if game_mode == clean:
		return
	game_mode = clean
	save_persistent_data()
	game_mode_changed.emit(game_mode)


func is_world_unlocked(world_idx: int) -> bool:
	return world_idx == 0 or unlocked_worlds.has(world_idx)


func set_graphics_quality(q: String, persist: bool = true) -> void:
	var clean := q if q in ["low", "medium", "high"] else "high"
	if graphics_quality == clean and not persist:
		return
	graphics_quality = clean
	if persist:
		save_persistent_data()
	graphics_settings_changed.emit()


func set_vsync_enabled(enabled: bool, persist: bool = true) -> void:
	vsync_enabled = enabled
	_apply_vsync()
	if persist:
		save_persistent_data()
	graphics_settings_changed.emit()


func set_camera_fov(fov: float, persist: bool = true) -> void:
	camera_fov = clampf(fov, 58.0, 96.0)
	if persist:
		save_persistent_data()
	graphics_settings_changed.emit()


func set_crown_equipped(enabled: bool) -> void:
	if crown_equipped == enabled:
		return
	crown_equipped = enabled
	save_persistent_data()
	cosmetic_changed.emit()


func set_purist_halo_equipped(enabled: bool) -> void:
	if purist_halo_equipped == enabled:
		return
	purist_halo_equipped = enabled
	save_persistent_data()
	cosmetic_changed.emit()


func unlock_badge(badge_id: String, show_callout: bool = true) -> bool:
	if not BADGE_INFO.has(badge_id) or unlocked_badges.has(badge_id):
		return false
	unlocked_badges[badge_id] = true
	var info: Dictionary = BADGE_INFO[badge_id]
	var title: String = str(info["title"])
	var desc: String = str(info["desc"])
	save_persistent_data()
	badge_unlocked.emit(badge_id, title, desc)
	if show_callout:
		emit_callout("BADGE UNLOCKED", title, Color(1.0, 0.86, 0.36))
	return true


func compute_rank(sec: float, falls: int, shards: int, mode: String) -> Dictionary:
	if mode == "purist" or (sec <= 720.0 and falls <= 2 and shards >= 12):
		return {"grade": "S+", "title": "Solstice Legend", "color": Color(1.0, 0.95, 0.72)}
	if sec <= 960.0 and falls <= 5:
		return {"grade": "S", "title": "Sun-Crowned", "color": Color(1.0, 0.78, 0.28)}
	if sec <= 1440.0 and falls <= 12:
		return {"grade": "A", "title": "Skyward Ace", "color": Color(0.98, 0.62, 0.46)}
	if sec <= 2100.0:
		return {"grade": "B", "title": "Cloud Climber", "color": Color(0.46, 0.88, 0.94)}
	return {"grade": "C", "title": "First Ascent", "color": Color(0.92, 0.88, 0.82)}


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


func register_checkpoint(cp_id: String, world_idx: int, pos: Vector3, yaw: float = 0.0, is_summit: bool = false) -> void:
	if is_summit:
		return
	for i in range(all_checkpoints.size()):
		if str(all_checkpoints[i].get("id", "")) == cp_id:
			all_checkpoints[i] = {"id": cp_id, "world_idx": world_idx, "pos": pos, "yaw": yaw}
			return
	all_checkpoints.append({"id": cp_id, "world_idx": world_idx, "pos": pos, "yaw": yaw})
	all_checkpoints.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a["pos"] as Vector3).y < (b["pos"] as Vector3).y
	)


func get_next_checkpoint_above(cur_y: float) -> Dictionary:
	for cp in all_checkpoints:
		var p: Vector3 = cp["pos"]
		if p.y > cur_y + 4.5:
			return cp
	return {}


func set_pilgrim_assist_offer(target_cp: Dictionary, active: bool) -> void:
	var next_id := str(target_cp.get("id", "")) if active else ""
	var prev_id := str(pilgrim_assist_target.get("id", "")) if pilgrim_assist_active else ""
	if pilgrim_assist_active == active and next_id == prev_id:
		return
	pilgrim_assist_active = active
	pilgrim_assist_target = target_cp.duplicate(true) if active else {}
	pilgrim_assist_offer_changed.emit(pilgrim_assist_target, pilgrim_assist_active)


func activate_checkpoint(cp_id: String, world_idx: int, pos: Vector3, yaw: float = 0.0) -> bool:
	var is_new := not activated_checkpoints.has(cp_id)
	activated_checkpoints[cp_id] = true
	current_checkpoint_id = cp_id
	current_checkpoint_pos = pos
	current_checkpoint_yaw = yaw
	var newly_unlocked_world := false
	if not unlocked_worlds.has(world_idx):
		unlocked_worlds.append(world_idx)
		unlocked_worlds.sort()
		newly_unlocked_world = true
	if newly_unlocked_world:
		save_persistent_data()
		world_unlocked.emit(world_idx)
	elif best_ever_altitude > _last_saved_best_alt:
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
			save_persistent_data()
			world_unlocked.emit(detected_world)
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
	if streak >= 12:
		unlock_badge("untouchable_flow")
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
	var shards_count := collected_shards.size()
	best_ever_altitude = maxf(best_ever_altitude, maxf(current_altitude, SUMMIT_ALTITUDE))
	var is_new_pb := best_run_time <= 0.0 or run_time < best_run_time
	if is_new_pb:
		best_run_time = run_time
		best_run_samples = current_run_samples.duplicate(true)
		best_world_splits = current_world_splits.duplicate(true)

	var rank := compute_rank(run_time, total_falls, shards_count, game_mode)
	var crown_just_unlocked := not crown_unlocked
	var halo_just_unlocked := false
	crown_unlocked = true

	var new_badges: Array[String] = []
	if unlock_badge("summit_conqueror", false):
		new_badges.append("summit_conqueror")
	if is_purist_mode():
		if not purist_halo_unlocked:
			halo_just_unlocked = true
		purist_halo_unlocked = true
		if unlock_badge("purist_legend", false):
			new_badges.append("purist_legend")
	if shards_count >= TOTAL_SHARDS:
		if unlock_badge("sun_collector", false):
			new_badges.append("sun_collector")

	var entry := {
		"time": snappedf(run_time, 0.01),
		"falls": total_falls,
		"shards": shards_count,
		"max_flow": max_flow_streak,
		"char": selected_character,
		"mode": game_mode,
		"rank": str(rank["grade"]),
		"rank_title": str(rank["title"]),
		"date": Time.get_date_string_from_system(),
	}
	leaderboard.append(entry)
	leaderboard.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da := a as Dictionary
		var db := b as Dictionary
		var a_purist := str(da.get("mode", "pilgrim")) == "purist"
		var b_purist := str(db.get("mode", "pilgrim")) == "purist"
		if a_purist != b_purist:
			return a_purist
		return float(da.get("time", 999999.0)) < float(db.get("time", 999999.0))
	)
	if leaderboard.size() > 8:
		leaderboard.resize(8)

	last_victory_summary = {
		"time": run_time,
		"falls": total_falls,
		"shards": shards_count,
		"max_flow": max_flow_streak,
		"char": selected_character,
		"mode": game_mode,
		"rank": str(rank["grade"]),
		"rank_title": str(rank["title"]),
		"rank_color": rank["color"],
		"is_new_pb": is_new_pb,
		"crown_just_unlocked": crown_just_unlocked,
		"halo_just_unlocked": halo_just_unlocked,
		"new_badges": new_badges,
	}

	save_persistent_data()
	if crown_just_unlocked or halo_just_unlocked:
		cosmetic_changed.emit()
	summit_reached.emit(run_time, total_falls, shards_count, max_flow_streak)


func format_time(sec: float) -> String:
	var mins := int(floor(sec / 60.0))
	var rem := sec - float(mins * 60)
	return "%02d:%05.2f" % [mins, rem]
