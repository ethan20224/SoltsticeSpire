extends Node3D
## Root Game Orchestrator for Solstice Spire.
## Connects SpireWorld (6 continuous realms with smart altitude streaming), BiomeAtmosphere,
## Live 3D Character Select Diorama (with Pip's warm ember lantern!), PlayerController, UI, and GauntletRunner.

@onready var atmosphere: Node3D = $BiomeAtmosphere
@onready var spire_world: SpireWorld = $SpireWorld
@onready var player: PlayerController = $Player
@onready var diorama_root: Node3D = $CharacterDiorama
@onready var diorama_cam: Camera3D = $CharacterDiorama/DioramaCamera

var _hud: GameHUD
var _char_select: CharacterSelectUI
var _pause_menu: PauseMenuUI
var _summit_ui: SummitVictoryUI
var _diorama_models: Dictionary = {}
var _diorama_time: float = 0.0
var _gauntlet_mode: bool = false


func _ready() -> void:
	_gauntlet_mode = OS.get_cmdline_user_args().has("--gauntlet")
	_apply_clean_window_branding()
	call_deferred("_apply_clean_window_branding")

	# Build all 6 continuous surreal ascending worlds (0m -> 1,085m)
	spire_world.build_all_worlds()

	# Spawn live 3D Character Select Diorama standing right on World 1's Sunlit Terrace!
	_build_character_diorama()

	# Create UI Layer
	var canvas := CanvasLayer.new()
	canvas.name = "UILayer"
	add_child(canvas)

	_hud = GameHUD.new()
	_hud.player_ref = player
	_hud.visible = false
	canvas.add_child(_hud)

	_char_select = CharacterSelectUI.new()
	_char_select.character_highlighted.connect(_on_diorama_highlight)
	_char_select.ascent_started.connect(_start_gameplay)
	canvas.add_child(_char_select)

	_pause_menu = PauseMenuUI.new()
	_pause_menu.resume_requested.connect(_resume_from_pause)
	_pause_menu.world_teleport_requested.connect(_teleport_to_world)
	_pause_menu.restart_requested.connect(_restart_full_climb)
	_pause_menu.title_requested.connect(_return_to_diorama)
	canvas.add_child(_pause_menu)

	_summit_ui = SummitVictoryUI.new()
	_summit_ui.explore_summit_requested.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
	_summit_ui.climb_again_requested.connect(_restart_full_climb)
	canvas.add_child(_summit_ui)

	GameState.summit_reached.connect(_on_summit_reached)

	# Position cleanly at World 1 Diorama
	_enter_diorama_mode()

	if _gauntlet_mode:
		var runner := GauntletRunner.new()
		runner.name = "GauntletRunner"
		add_child(runner)
		runner.execute(self, spire_world, atmosphere, player, _char_select, _hud, _pause_menu, _diorama_models, diorama_cam)


func _apply_clean_window_branding() -> void:
	get_window().title = "Solstice Spire"
	DisplayServer.window_set_title("Solstice Spire")
	if ResourceLoader.exists("res://assets/icon.png"):
		var tex := load("res://assets/icon.png") as Texture2D
		if tex and tex.get_image():
			DisplayServer.set_icon(tex.get_image())


func _exit_tree() -> void:
	UITheme.clear_caches()


func _build_character_diorama() -> void:
	# Place Pip, Koko, and Vesper cleanly spaced so all 3 fit frame-to-frame in Title & Portrait Close-Up!
	var center := Vector3(0.0, 0.05, 25.5)
	diorama_root.global_position = center
	var offsets := {
		"pip": Vector3(-1.45, 0.0, 0.25),
		"koko": Vector3(0.0, 0.0, 0.0),
		"vesper": Vector3(1.45, 0.0, 0.25),
	}
	for cid in ["pip", "koko", "vesper"]:
		var slot := Node3D.new()
		slot.name = "Slot_%s" % cid
		slot.position = offsets[cid]
		slot.rotation_degrees.y = 180.0
		var m_inst := WorldHelper.load_glb(GameState.CHARACTERS[cid]["model"])
		WorldHelper.apply_plush_character_materials(m_inst)
		slot.add_child(m_inst)
		diorama_root.add_child(slot)
		_diorama_models[cid] = slot

	# Ornate heirloom glowing ember lantern right beside Pip (matches Pip's bio & casts warm bounce on face!)
	var pip_lantern := WorldHelper.load_glb("res://assets/models/scenery/pip_diorama_lantern.glb")
	pip_lantern.position = Vector3(-0.92, -0.02, 0.62)
	WorldHelper.enhance_stylized_materials(pip_lantern, Color.WHITE, 0.0, Color(1.0, 0.86, 0.50), 0.30, Color(0.24, 0.16, 0.30), "hammered_brass", 1.2, 0.55)
	WorldHelper.disable_shadows(pip_lantern)
	diorama_root.add_child(pip_lantern)
	WorldHelper.add_lamp_halo(diorama_root, Vector3(-0.92, 0.34, 0.62), Color(1.0, 0.72, 0.32), 0.95, 0.82)

	var lantern_bounce := OmniLight3D.new()
	lantern_bounce.position = Vector3(-0.92, 0.42, 0.72)
	lantern_bounce.light_color = Color(1.0, 0.70, 0.30)
	lantern_bounce.light_energy = 2.6
	lantern_bounce.omni_range = 4.2
	lantern_bounce.omni_attenuation = 1.4
	diorama_root.add_child(lantern_bounce)

	# 3-Point Cozy Plush Diorama Lighting: Warm Amber Key + Soft Cool Sky Rim!
	var key := OmniLight3D.new()
	key.position = Vector3(-2.4, 2.3, 3.6)
	key.light_color = Color(1.0, 0.84, 0.58)
	key.light_energy = 1.85
	key.omni_range = 12.0
	diorama_root.add_child(key)

	var rim := OmniLight3D.new()
	rim.position = Vector3(2.8, 2.6, -2.0)
	rim.light_color = Color(0.56, 0.86, 1.0)
	rim.light_energy = 1.35
	rim.omni_range = 10.0
	diorama_root.add_child(rim)

	diorama_cam.far = 260.0
	diorama_cam.position = Vector3(0.0, 1.24, 4.65)
	diorama_cam.look_at(center + Vector3(0.0, 0.82, 0.0), Vector3.UP)


func _enter_diorama_mode() -> void:
	GameState.is_playing = false
	GameState.is_paused = false
	player.controls_enabled = false
	player.visible = false
	diorama_root.visible = true
	diorama_cam.current = true
	_char_select.visible = true
	if not _gauntlet_mode:
		_char_select.play_intro_stagger()
	_hud.visible = false
	_pause_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	spire_world.set_diorama_cull(true, diorama_root.global_position)
	atmosphere.apply_for_altitude(10.0, true)
	if atmosphere.world_environment and atmosphere.world_environment.environment:
		atmosphere.world_environment.environment.volumetric_fog_length = 40.0


func _on_diorama_highlight(char_id: String) -> void:
	for cid in _diorama_models:
		var slot: Node3D = _diorama_models[cid]
		var target_z := 0.58 if cid == char_id else 0.14
		var target_scale := Vector3.ONE * (1.12 if cid == char_id else 0.94)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(slot, "position:z", target_z, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(slot, "scale", target_scale, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _start_gameplay() -> void:
	diorama_root.visible = false
	_char_select.visible = false
	_hud.modulate.a = 1.0
	_hud.visible = true
	player.visible = true
	player.controls_enabled = true
	player.camera_rig.camera.current = true
	GameState.reset_full_run()
	GameState.start_run()
	player.teleport_to_checkpoint(GameState.current_checkpoint_pos, GameState.current_checkpoint_yaw)
	if atmosphere.world_environment and atmosphere.world_environment.environment:
		atmosphere.world_environment.environment.volumetric_fog_length = 85.0
	spire_world.set_diorama_cull(false)
	spire_world.set_focus_world(0, false, 0.0)
	AudioDirector.set_biome_immediate(0)
	_hud.show_world_toast(0, GameState.WORLDS[0]["name"], GameState.WORLDS[0]["subtitle"])
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _resume_from_pause() -> void:
	GameState.is_paused = false
	_pause_menu.visible = false
	_hud.set_paused_hidden(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _teleport_to_world(world_idx: int) -> void:
	if GameState.world_spawn_points.has(world_idx):
		var sp: Dictionary = GameState.world_spawn_points[world_idx]
		GameState.activate_checkpoint(sp["id"], world_idx, sp["pos"], sp["yaw"])
		player.teleport_to_checkpoint(sp["pos"], sp["yaw"])
		if atmosphere.world_environment and atmosphere.world_environment.environment:
			atmosphere.world_environment.environment.volumetric_fog_length = 85.0
		spire_world.set_diorama_cull(false)
		spire_world.set_focus_world(world_idx, false, sp["pos"].y)
		atmosphere.apply_for_altitude(sp["pos"].y, true)
		AudioDirector.set_biome_immediate(world_idx)
		var w: Dictionary = GameState.WORLDS[world_idx]
		_hud.show_world_toast(world_idx, w["name"], w["subtitle"])
	_resume_from_pause()


func _restart_full_climb() -> void:
	GameState.reset_full_run()
	player.teleport_to_checkpoint(GameState.current_checkpoint_pos, GameState.current_checkpoint_yaw)
	spire_world.set_diorama_cull(false)
	spire_world.set_focus_world(0, false, 0.0)
	atmosphere.apply_for_altitude(0.0, true)
	AudioDirector.set_biome_immediate(0)
	_summit_ui.visible = false
	_resume_from_pause()


func _return_to_diorama() -> void:
	_enter_diorama_mode()


func _on_summit_reached(run_time: float, falls: int, shards: int, max_streak: int) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	spire_world.set_focus_world(5, true)
	_summit_ui.show_stats(run_time, falls, shards, max_streak)


func _unhandled_input(event: InputEvent) -> void:
	if _gauntlet_mode or not GameState.is_playing:
		return
	if event.is_action_pressed("ui_cancel"):
		if GameState.is_paused:
			_resume_from_pause()
		else:
			GameState.is_paused = true
			_hud.set_paused_hidden(true)
			_pause_menu.open_animated()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if _gauntlet_mode:
		return
	if diorama_root.visible:
		_diorama_time += delta
		for cid in _diorama_models:
			var slot: Node3D = _diorama_models[cid]
			var is_sel: bool = (str(cid) == GameState.selected_character)
			slot.position.y = sin(_diorama_time * (3.2 if is_sel else 2.2)) * (0.07 if is_sel else 0.03)
			if is_sel:
				slot.rotation_degrees.y = 180.0 + sin(_diorama_time * 1.1) * 14.0
			else:
				slot.rotation_degrees.y = lerpf(slot.rotation_degrees.y, 180.0, clampf(delta * 4.0, 0.0, 1.0))
	elif GameState.is_playing:
		var py := player.global_position.y
		atmosphere.apply_for_altitude(py, false)
		var show_summit := py >= 1068.0
		spire_world.set_focus_world(spire_world.world_index_for_altitude(py), show_summit, py)
