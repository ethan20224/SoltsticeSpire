extends Node3D
## Root Game Orchestrator for Solstice Spire.
## Connects SpireWorld (6 continuous realms with smart altitude streaming), BiomeAtmosphere,
## Live 3D Character Select Diorama (with Pip's warm ember lantern & Golden Solstice Crown!),
## PlayerController, UI, CreditsOverlayUI (with Summit Sanctuary orbital glide), and GauntletRunner.

@onready var atmosphere: Node3D = $BiomeAtmosphere
@onready var spire_world: SpireWorld = $SpireWorld
@onready var player: PlayerController = $Player
@onready var diorama_root: Node3D = $CharacterDiorama
@onready var diorama_cam: Camera3D = $CharacterDiorama/DioramaCamera

var _hud: GameHUD
var _char_select: CharacterSelectUI
var _guide_settings: GuideSettingsPanelUI
var _pause_menu: PauseMenuUI
var _summit_ui: SummitVictoryUI
var _credits_overlay: CreditsOverlayUI
var _loading_screen: LoadingScreenUI
var _opening_cutscene: OpeningCutscene
var _high_water_flag: HighWaterFlag
var _ghost_runner: GhostRunner
var _summit_glide_cam: Camera3D
var _summit_glide_active: bool = false
var _summit_glide_time: float = 0.0
var _diorama_models: Dictionary = {}
var _diorama_crowns: Dictionary = {}
var _diorama_time: float = 0.0
var _gauntlet_mode: bool = false


func _ready() -> void:
	_gauntlet_mode = OS.get_cmdline_user_args().has("--gauntlet")
	_apply_clean_window_branding()
	call_deferred("_apply_clean_window_branding")
	_apply_graphics_quality()

	# Build all 6 continuous surreal ascending worlds (0m -> 1,085m)
	spire_world.build_all_worlds()

	# Spawn live 3D Character Select Diorama standing right on World 1's Sunlit Terrace!
	_build_character_diorama()

	# Spawn High-Water Flag & Personal-Best Ghost Runner
	_high_water_flag = HighWaterFlag.new()
	_high_water_flag.name = "HighWaterFlag"
	add_child(_high_water_flag)
	player.high_water_planted.connect(_high_water_flag.plant_at)
	player.high_water_passed.connect(func(_alt_m: float): _high_water_flag.celebrate_surpassed())

	_ghost_runner = GhostRunner.new()
	_ghost_runner.name = "GhostRunner"
	add_child(_ghost_runner)

	_summit_glide_cam = Camera3D.new()
	_summit_glide_cam.name = "SummitGlideCamera"
	_summit_glide_cam.fov = 52.0
	_summit_glide_cam.near = 0.1
	_summit_glide_cam.far = 1600.0
	add_child(_summit_glide_cam)

	# Create UI Layer (layer 10 sits cleanly over OpeningCutscene layer 8)
	var canvas := CanvasLayer.new()
	canvas.name = "UILayer"
	canvas.layer = 10
	add_child(canvas)

	_hud = GameHUD.new()
	_hud.player_ref = player
	_hud.visible = false
	canvas.add_child(_hud)

	_char_select = CharacterSelectUI.new()
	_char_select.character_highlighted.connect(_on_diorama_highlight)
	_char_select.ascent_started.connect(func(): _start_gameplay(0))
	_char_select.guide_settings_requested.connect(_open_guide_settings)
	_char_select.visible = false
	canvas.add_child(_char_select)

	_guide_settings = GuideSettingsPanelUI.new()
	_guide_settings.closed.connect(_on_guide_settings_closed)
	_guide_settings.world_launch_requested.connect(_on_guide_world_launch)
	_guide_settings.credits_requested.connect(func():
		_credits_overlay.open_credits(false)
	)
	canvas.add_child(_guide_settings)

	_pause_menu = PauseMenuUI.new()
	_pause_menu.resume_requested.connect(_resume_from_pause)
	_pause_menu.world_teleport_requested.connect(_teleport_to_world)
	_pause_menu.restart_requested.connect(_restart_full_climb)
	canvas.add_child(_pause_menu)

	_summit_ui = SummitVictoryUI.new()
	_summit_ui.victory_skydive_requested.connect(_start_victory_skydive)
	_summit_ui.explore_summit_requested.connect(func():
		_stop_summit_credits_glide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
	_summit_ui.credits_glide_requested.connect(func():
		_start_summit_credits_glide()
		_credits_overlay.open_credits(true)
	)
	_summit_ui.climb_again_requested.connect(_restart_full_climb)
	canvas.add_child(_summit_ui)
	player.victory_skydive_landed.connect(_on_victory_skydive_landed)

	_credits_overlay = CreditsOverlayUI.new()
	_credits_overlay.closed.connect(_on_credits_closed)
	canvas.add_child(_credits_overlay)

	_loading_screen = LoadingScreenUI.new()
	_loading_screen.loading_finished.connect(_start_opening_cutscene)
	canvas.add_child(_loading_screen)

	_opening_cutscene = OpeningCutscene.new()
	_opening_cutscene.name = "OpeningCutscene"
	_opening_cutscene.cutscene_finished.connect(_on_cutscene_finished)
	add_child(_opening_cutscene)

	GameState.summit_reached.connect(_on_summit_reached)
	GameState.graphics_settings_changed.connect(_apply_graphics_quality)
	GameState.cosmetic_changed.connect(_refresh_diorama_cosmetics)
	GameState.shard_collected.connect(func(_cur: int, _tot: int): PhoneController.send_haptic("shard"))
	GameState.checkpoint_updated.connect(func(_id: String, _w: int, _p: Vector3): PhoneController.send_haptic("shard"))
	GameState.character_changed.connect(func(cid: String):
		if diorama_root.visible:
			_on_diorama_highlight(cid)
	)

	InputManager.ui_pause_pressed.connect(func():
		if _credits_overlay and _credits_overlay.visible:
			_credits_overlay.close_credits()
			return
		if _guide_settings and _guide_settings.visible:
			_guide_settings.close_panel()
			return
		_toggle_pause()
	)
	InputManager.ui_confirm_pressed.connect(func():
		if GameState.is_cutscene and _opening_cutscene:
			_opening_cutscene.request_continue()
	)
	InputManager.ui_cancel_pressed.connect(func():
		if _credits_overlay and _credits_overlay.visible:
			_credits_overlay.close_credits()
		elif _guide_settings and _guide_settings.visible:
			_guide_settings.close_panel()
		elif GameState.is_playing and GameState.is_paused:
			_resume_from_pause()
	)

	PhoneController.remote_continue_cutscene.connect(func():
		if GameState.is_cutscene:
			_opening_cutscene.request_continue()
	)
	PhoneController.remote_toggle_pause.connect(_toggle_pause)
	PhoneController.remote_resume.connect(func():
		if GameState.is_playing and GameState.is_paused:
			_resume_from_pause()
	)
	PhoneController.remote_restart_climb.connect(func():
		if GameState.is_playing:
			_restart_full_climb()
	)
	PhoneController.remote_teleport_world.connect(func(w_idx: int):
		if GameState.is_playing:
			_teleport_to_world(w_idx)
	)

	if _gauntlet_mode:
		_enter_diorama_mode()
		var runner := GauntletRunner.new()
		runner.name = "GauntletRunner"
		add_child(runner)
		runner.execute(self, spire_world, atmosphere, player, _char_select, _hud, _pause_menu, _diorama_models, diorama_cam, _loading_screen, _opening_cutscene, _guide_settings, _summit_ui)
	else:
		_enter_loading_mode()


func _apply_clean_window_branding() -> void:
	get_window().title = "Solstice Spire"
	DisplayServer.window_set_title("Solstice Spire")
	if ResourceLoader.exists("res://assets/icon.png"):
		var tex := load("res://assets/icon.png") as Texture2D
		if tex and tex.get_image():
			DisplayServer.set_icon(tex.get_image())


func _apply_graphics_quality() -> void:
	var vp := get_viewport()
	var env: Environment = null
	var sun: DirectionalLight3D = null
	if atmosphere:
		if atmosphere.world_environment:
			env = atmosphere.world_environment.environment
		sun = atmosphere.sun_light

	match GameState.graphics_quality:
		"low":
			if vp:
				vp.scaling_3d_scale = 0.65
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			if env:
				env.ssao_enabled = false
				env.volumetric_fog_enabled = false
			if sun:
				sun.shadow_enabled = true
				sun.directional_shadow_max_distance = 45.0
		"medium":
			if vp:
				vp.scaling_3d_scale = 0.76
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			if env:
				env.ssao_enabled = false
				env.volumetric_fog_enabled = false
			if sun:
				sun.shadow_enabled = true
				sun.directional_shadow_max_distance = 68.0
		_:  # "high"
			if vp:
				vp.scaling_3d_scale = 0.86
				vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			if env:
				env.ssao_enabled = true
				env.volumetric_fog_enabled = true
			if sun:
				sun.shadow_enabled = true
				sun.directional_shadow_max_distance = 92.0


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
	_diorama_crowns.clear()
	for cid in ["pip", "koko", "vesper"]:
		var slot := Node3D.new()
		slot.name = "Slot_%s" % cid
		slot.position = offsets[cid]
		slot.rotation_degrees.y = 180.0
		var m_inst := WorldHelper.load_glb(GameState.CHARACTERS[cid]["model"])
		WorldHelper.apply_plush_character_materials(m_inst)
		slot.add_child(m_inst)

		var head := m_inst.find_child("HeadPivot", true, false) as Node3D
		var crown := CharacterRig.build_golden_crown_mesh(cid)
		if head != null:
			head.add_child(crown)
		else:
			m_inst.add_child(crown)
		_diorama_crowns[cid] = crown

		diorama_root.add_child(slot)
		_diorama_models[cid] = slot

	_refresh_diorama_cosmetics()

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

	diorama_cam.far = 1500.0
	diorama_cam.position = Vector3(0.0, 1.24, 4.65)
	diorama_cam.look_at(center + Vector3(0.0, 0.82, 0.0), Vector3.UP)


func _refresh_diorama_cosmetics() -> void:
	var show_crown := GameState.crown_unlocked and GameState.crown_equipped
	for cid in _diorama_crowns:
		var cr: Node3D = _diorama_crowns[cid]
		if cr and is_instance_valid(cr):
			cr.visible = show_crown


func _start_summit_credits_glide() -> void:
	_summit_glide_active = true
	_summit_glide_time = 0.0
	_hud.visible = false
	player.controls_enabled = false
	spire_world.set_focus_world(5, true)
	atmosphere.apply_for_altitude(1085.0, true)
	if _summit_glide_cam:
		_summit_glide_cam.current = true
		_update_summit_glide_camera(0.0)


func _stop_summit_credits_glide() -> void:
	if not _summit_glide_active:
		return
	_summit_glide_active = false
	if GameState.is_playing:
		_hud.visible = true
		player.controls_enabled = true
		player.camera_rig.camera.current = true


func _update_summit_glide_camera(delta: float) -> void:
	_summit_glide_time += delta
	var anchor := spire_world.summit_position if spire_world else Vector3(0.0, 1084.5, 0.0)
	var look_pt := anchor + Vector3(0.0, 2.4, 0.0)
	var ang := _summit_glide_time * 0.24
	var rad := 23.5 + sin(_summit_glide_time * 0.35) * 3.0
	var cam_y := anchor.y + 8.0 + sin(_summit_glide_time * 0.42) * 2.4
	var cam_pos := Vector3(anchor.x + cos(ang) * rad, cam_y, anchor.z + sin(ang) * rad)
	_summit_glide_cam.global_position = cam_pos
	_summit_glide_cam.look_at(look_pt, Vector3.UP)


func _on_credits_closed() -> void:
	if _summit_glide_active:
		_stop_summit_credits_glide()
		_summit_ui.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _enter_loading_mode() -> void:
	_stop_summit_credits_glide()
	GameState.is_playing = false
	GameState.is_paused = false
	GameState.is_cutscene = false
	player.controls_enabled = false
	player.visible = false
	diorama_root.visible = true
	_char_select.visible = false
	_char_select.input_blocked = false
	_guide_settings.visible = false
	_credits_overlay.visible = false
	_hud.visible = false
	_pause_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_loading_screen.start_loading(3.8)
	AudioDirector.play_loading_ambience()


func _start_opening_cutscene() -> void:
	GameState.is_cutscene = true
	AudioDirector.swell_into_cutscene()
	_opening_cutscene.start_descent(spire_world, atmosphere, diorama_root)


func _on_cutscene_finished() -> void:
	GameState.is_cutscene = false
	_enter_diorama_mode()


func _enter_diorama_mode() -> void:
	_stop_summit_credits_glide()
	GameState.is_playing = false
	GameState.is_paused = false
	GameState.is_cutscene = false
	player.controls_enabled = false
	player.visible = false
	diorama_root.visible = true
	diorama_cam.current = true
	_char_select.visible = true
	_char_select.input_blocked = false
	_guide_settings.visible = false
	_credits_overlay.visible = false
	if not _gauntlet_mode:
		_char_select.play_intro_stagger()
	_hud.visible = false
	_pause_menu.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	spire_world.set_diorama_cull(true, diorama_root.global_position)
	atmosphere.apply_for_altitude(10.0, true)
	if atmosphere.world_environment and atmosphere.world_environment.environment:
		atmosphere.world_environment.environment.volumetric_fog_length = 40.0
	_apply_graphics_quality()
	_refresh_diorama_cosmetics()


func _open_guide_settings() -> void:
	_char_select.input_blocked = true
	_guide_settings.open_animated()


func _on_guide_settings_closed() -> void:
	_char_select.input_blocked = false


func _on_guide_world_launch(world_idx: int) -> void:
	_guide_settings.visible = false
	_char_select.input_blocked = false
	_start_gameplay(world_idx)


func _on_diorama_highlight(char_id: String) -> void:
	for cid in _diorama_models:
		var slot: Node3D = _diorama_models[cid]
		var target_z := 0.58 if cid == char_id else 0.14
		var target_scale := Vector3.ONE * (1.12 if cid == char_id else 0.94)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(slot, "position:z", target_z, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(slot, "scale", target_scale, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _start_gameplay(start_world_idx: int = 0) -> void:
	_stop_summit_credits_glide()
	_loading_screen.skip_immediate()
	_opening_cutscene.skip_immediate()
	_credits_overlay.visible = false
	GameState.is_cutscene = false
	diorama_root.visible = false
	_char_select.visible = false
	_char_select.input_blocked = false
	_guide_settings.visible = false
	_hud.modulate.a = 1.0
	_hud.visible = true
	player.visible = true
	player.controls_enabled = true
	player.camera_rig.camera.current = true
	if _ghost_runner:
		_ghost_runner.reset_ghost()
	if _high_water_flag:
		_high_water_flag.visible = false

	GameState.reset_full_run()
	GameState.start_run()

	if atmosphere.world_environment and atmosphere.world_environment.environment:
		atmosphere.world_environment.environment.volumetric_fog_length = 85.0
	_apply_graphics_quality()
	spire_world.clear_victory_sky_rings()
	spire_world.set_solstice_rekindled(false)
	spire_world.set_diorama_cull(false)

	var allow_direct_world := start_world_idx > 0 and not GameState.is_purist_mode() and GameState.world_spawn_points.has(start_world_idx)
	if allow_direct_world:
		var sp: Dictionary = GameState.world_spawn_points[start_world_idx]
		GameState.activate_checkpoint(sp["id"], start_world_idx, sp["pos"], sp["yaw"])
		GameState.current_world_idx = start_world_idx
		player.teleport_to_checkpoint(sp["pos"], sp["yaw"])
		spire_world.set_focus_world(start_world_idx, false, sp["pos"].y)
		atmosphere.apply_for_altitude(sp["pos"].y, true)
		AudioDirector.set_biome_immediate(start_world_idx)
		var w: Dictionary = GameState.WORLDS[start_world_idx]
		_hud.show_world_toast(start_world_idx, w["name"], w["subtitle"])
	else:
		_spawn_player_aboard_airship()
		spire_world.set_focus_world(0, false, 0.0)
		atmosphere.apply_for_altitude(0.0, true)
		AudioDirector.set_biome_immediate(0)
		_hud.show_world_toast(0, GameState.WORLDS[0]["name"], GameState.WORLDS[0]["subtitle"])
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _spawn_player_aboard_airship() -> void:
	## Spawns the explorer aboard The Dawnbreaker's wooden deck facing straight down the gangplank
	## onto the mossy Awakening Terrace & towering 1,085m Spire!
	var ship := get_tree().get_first_node_in_group("docked_airship")
	if ship and ship.has_method("set_docking_progress"):
		ship.call("set_docking_progress", 1.0)
	if ship and ship.has_method("get_boarding_spawn"):
		var b: Dictionary = ship.call("get_boarding_spawn")
		player.teleport_to_checkpoint(b["pos"], float(b["yaw"]))
	else:
		player.teleport_to_checkpoint(GameState.current_checkpoint_pos, GameState.current_checkpoint_yaw)


func _start_victory_skydive() -> void:
	_stop_summit_credits_glide()
	_summit_ui.visible = false
	_credits_overlay.visible = false
	_hud.visible = true
	_hud.modulate.a = 1.0
	player.visible = true
	player.controls_enabled = true
	player.camera_rig.camera.current = true
	spire_world.set_solstice_rekindled(true)
	spire_world.set_focus_world(5, true)
	spire_world.spawn_victory_sky_rings()
	player.start_victory_skydive()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_victory_skydive_landed() -> void:
	spire_world.clear_victory_sky_rings()
	spire_world.set_focus_world(0, false, 0.5)
	atmosphere.apply_for_altitude(8.0, true)
	AudioDirector.set_biome_immediate(5)
	# Let the player savor the celebratory Dawnbreaker homecoming burst for 2.2s, then invite the Credits Glide!
	var tw := create_tween()
	tw.tween_interval(2.2)
	tw.tween_callback(func():
		if GameState.is_playing and GameState.has_finished and not GameState.victory_skydive_active:
			_summit_ui.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)


func _resume_from_pause() -> void:
	GameState.is_paused = false
	_pause_menu.visible = false
	_hud.set_paused_hidden(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _teleport_to_world(world_idx: int) -> void:
	if GameState.is_purist_mode() or not GameState.is_world_unlocked(world_idx):
		return
	if GameState.world_spawn_points.has(world_idx):
		var sp: Dictionary = GameState.world_spawn_points[world_idx]
		GameState.activate_checkpoint(sp["id"], world_idx, sp["pos"], sp["yaw"])
		player.teleport_to_checkpoint(sp["pos"], sp["yaw"])
		if atmosphere.world_environment and atmosphere.world_environment.environment:
			atmosphere.world_environment.environment.volumetric_fog_length = 85.0
		_apply_graphics_quality()
		spire_world.set_diorama_cull(false)
		spire_world.set_focus_world(world_idx, false, sp["pos"].y)
		atmosphere.apply_for_altitude(sp["pos"].y, true)
		AudioDirector.set_biome_immediate(world_idx)
		var w: Dictionary = GameState.WORLDS[world_idx]
		_hud.show_world_toast(world_idx, w["name"], w["subtitle"])
	_resume_from_pause()


func _restart_full_climb() -> void:
	_stop_summit_credits_glide()
	_credits_overlay.visible = false
	if _ghost_runner:
		_ghost_runner.reset_ghost()
	if _high_water_flag:
		_high_water_flag.visible = false
	GameState.reset_full_run()
	spire_world.clear_victory_sky_rings()
	spire_world.set_solstice_rekindled(false)
	_spawn_player_aboard_airship()
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
	spire_world.set_solstice_rekindled(true)
	spire_world.set_focus_world(5, true)
	_summit_ui.show_stats(run_time, falls, shards, max_streak)


func _unhandled_input(event: InputEvent) -> void:
	if _gauntlet_mode:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F or event.keycode == KEY_F or event.keycode == KEY_F11:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return
	if not GameState.is_playing or GameState.is_cutscene:
		return
	if event.is_action_pressed("ui_cancel"):
		if _credits_overlay and _credits_overlay.visible:
			_credits_overlay.close_credits()
			return
		_toggle_pause()


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _toggle_pause() -> void:
	if not GameState.is_playing:
		return
	if _summit_glide_active and _credits_overlay and _credits_overlay.visible:
		_credits_overlay.close_credits()
		return
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
	if _summit_glide_active:
		_update_summit_glide_camera(delta)
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
		var show_summit := py >= 1068.0 or GameState.victory_skydive_active
		spire_world.set_focus_world(spire_world.world_index_for_altitude(py), show_summit, py, player.velocity.y)
