extends Node
class_name GauntletRunner
## Automated Verification & Visual Review Gauntlet Harness (invoked via `-- --gauntlet`).
## 1. Runs ReachabilityAudit across all 6 worlds (0m -> 1,085m) and verifies 0 failures.
## 2. Captures real Forward+ GPU screenshots of Title Diorama, Character Portrait, World 1 HUD,
##    Pause Menu (clean with HUD faded), player-height 3rd-person mid-route shots for Worlds 2-6
##    PLUS establishing wide shots for Worlds 1-6, and the panoramic Summit Look-Down vista!
## 3. Measures BOTH vsync-enabled and VSYNC_DISABLED true GPU frame time / FPS on Apple M2!

const OUT_DIR := "/Users/ethanpeleg/.gemini/antigravity/brain/93e2aa3e-b03b-4c5f-b384-9c805a599d9c/scratch/gauntlet"


func execute(main_node: Node3D, spire: SpireWorld, atmo: Node3D, player: PlayerController,
		char_select: CharacterSelectUI, hud: GameHUD, pause_ui: PauseMenuUI,
		_diorama_models: Dictionary, diorama_cam: Camera3D) -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	print("================ SOLSTICE SPIRE GAUNTLET AUDIT ================")

	# 1. Automated Kinematics & Reachability Audit
	var report := ReachabilityAudit.run_audit(spire.reachability_audit)
	print("[GAUNTLET] Audited %d consecutive vertical links across 6 worlds." % report["total_links"])
	for w in report["warnings"]:
		print("  [WARN] %s" % w)
	for f in report["failures"]:
		print("  [FAIL] %s" % f)
	print("[GAUNTLET] Reachability Audit PASSED: %s" % str(report["passed"]))
	print("[GAUNTLET] World spawn points registered: %d / 6" % GameState.world_spawn_points.size())
	print("[GAUNTLET] Shrines placed: %d | Sun-Shards placed: %d" % [
		get_tree().get_nodes_in_group("checkpoint_shrine").size(),
		get_tree().get_nodes_in_group("sun_shard").size()
	])

	for _i in range(6):
		await get_tree().process_frame

	# Shot 1: Title & Live 3D Character Select Diorama (full UI)
	spire.set_diorama_cull(true, main_node.get_node("CharacterDiorama").global_position)
	if atmo.world_environment and atmo.world_environment.environment:
		atmo.world_environment.environment.volumetric_fog_length = 40.0
	diorama_cam.far = 260.0
	await _snap("01_title_diorama.png")
	var fps_diorama := await _measure_fps("TitleDiorama")

	# Shot 2: Tight Portrait Close-Up of ALL THREE heroes + Pip's glowing ember lantern!
	char_select.visible = false
	diorama_cam.far = 260.0
	diorama_cam.position = Vector3(0.0, 0.94, 4.15)
	diorama_cam.fov = 42.0
	diorama_cam.look_at(main_node.get_node("CharacterDiorama").global_position + Vector3(0.0, 0.78, 0.18), Vector3.UP)
	await _snap("02_characters_closeup.png")

	# Prepare review camera for establishing vistas
	var review_cam := Camera3D.new()
	review_cam.fov = 64.0
	review_cam.far = 1600.0
	main_node.add_child(review_cam)
	main_node.get_node("CharacterDiorama").visible = false

	# Shot 3: Live 3rd-Person Gameplay Framing in World 1 (with HUD + borderless toast!)
	if atmo.world_environment and atmo.world_environment.environment:
		atmo.world_environment.environment.volumetric_fog_length = 85.0
	spire.set_diorama_cull(false)
	spire.set_focus_world(0, false, 0.5)
	player.visible = true
	player.teleport_to_checkpoint(Vector3(0.0, 0.5, 25.0), 0.0)
	player.camera_rig.snap_to(Vector3(0.0, 0.5, 25.0), 0.0)
	player.camera_rig.camera.current = true
	hud.modulate.a = 1.0
	hud.visible = true
	hud.show_world_toast(0, GameState.WORLDS[0]["name"], GameState.WORLDS[0]["subtitle"])
	atmo.apply_for_altitude(12.0, true)
	await _snap("03_world1_gameplay_hud.png")
	var fps_w1 := await _measure_fps("World1Play")

	# Shot 11: Pause Menu UI Audit Capture (HUD faded out & toast hidden!)
	hud.hide_toast_immediate()
	hud.modulate.a = 0.0
	if pause_ui:
		pause_ui.visible = true
		await _snap("11_pause_menu.png")
		pause_ui.visible = false

	# Shot 4: World 1 - The Sunken Conservatory Establishing Vista (Greenhouse Core + Arches + Islets!)
	hud.visible = false
	review_cam.current = true
	await _shot_vista(review_cam, atmo, Vector3(-22.0, 34.0, 44.0), Vector3(4.0, 22.0, 0.0), 38.0, "04_world1_conservatory.png")

	# Shot 5: World 2 - Player-Height 3rd-Person Gameplay View on Mid-Route Foundry Catwalk!
	spire.set_focus_world(1, false)
	await _shot_player_height(player, atmo, Vector3(12.5, 198.2, -24.5), deg_to_rad(52.0), 215.0, "05_world2_foundry.png")
	var fps_w2 := await _measure_fps("World2Foundry")
	# Shot 5b: World 2 Establishing Wide Vista
	review_cam.current = true
	await _shot_vista(review_cam, atmo, Vector3(40.0, 218.0, 28.0), Vector3(2.0, 206.0, -8.0), 235.0, "05b_world2_establishing.png")

	# Shot 6: World 3 - Player-Height 3rd-Person View on Mid-Route Monsoon Pagoda Eave!
	spire.set_focus_world(2, false)
	await _shot_player_height(player, atmo, Vector3(-2.0, 377.7, -26.5), deg_to_rad(160.0), 405.0, "06_world3_monsoon.png")
	# Shot 6b: World 3 Establishing Wide Vista
	review_cam.current = true
	await _shot_vista(review_cam, atmo, Vector3(36.0, 404.0, 20.0), Vector3(0.0, 392.0, -10.0), 425.0, "06b_world3_establishing.png")

	# Shot 7: World 4 - Player-Height 3rd-Person View on Escher Marble Balcony by Rose Window & Portal!
	spire.set_focus_world(3, false)
	await _shot_player_height(player, atmo, Vector3(26.0, 557.7, -10.5), deg_to_rad(58.0), 590.0, "07_world4_mirrors.png")
	# Shot 7b: World 4 Establishing Wide Vista
	review_cam.current = true
	await _shot_vista(review_cam, atmo, Vector3(44.0, 576.0, 30.0), Vector3(4.0, 566.0, -4.0), 615.0, "07b_world4_establishing.png")

	# Shot 8: World 5 - Player-Height 3rd-Person View on Sky-Library Bookshelf Balcony facing the Spiral Library Core & Whale!
	spire.set_focus_world(4, false)
	await _shot_player_height(player, atmo, Vector3(-14.5, 765.2, 21.5), deg_to_rad(-34.0), 795.0, "08_world5_library.png")
	var fps_w5 := await _measure_fps("World5Library")
	# Shot 8b: World 5 Establishing Wide Vista (Spiral Library Core + Whale + Crystal Bubble!)
	review_cam.current = true
	await _shot_vista(review_cam, atmo, Vector3(-44.0, 774.0, 32.0), Vector3(-2.0, 764.0, 0.0), 805.0, "08b_world5_establishing.png")

	# Shot 9: World 6 - Player-Height 3rd-Person View on Summit Crown Sanctuary Overlook!
	spire.set_focus_world(5, false)
	await _shot_player_height(player, atmo, Vector3(-6.2, 1084.7, 4.8), deg_to_rad(-48.0), 1060.0, "09_world6_crown_summit.png")
	# Shot 9b: World 6 Establishing Wide Vista (Observatory Crown Core + Open-Work Armillary Rings!)
	review_cam.current = true
	await _shot_vista(review_cam, atmo, Vector3(-34.0, 1094.0, 32.0), Vector3(0.0, 1082.0, 0.0), 1060.0, "09b_world6_establishing.png")

	# Shot 10: Dramatic Summit Look-Down Overlook showing ALL 6 stacked worlds descending into the clouds!
	spire.set_focus_world(5, true)
	await _shot_vista(review_cam, atmo, Vector3(0.0, 1096.0, 16.0), Vector3(0.0, 620.0, 0.0), 1040.0, "10_summit_lookdown.png")
	var fps_summit := await _measure_fps("SummitLookdown")

	print("[GAUNTLET FPS SUMMARY VSYNC]    Diorama=%.1f | W1=%.1f | W2=%.1f | W5=%.1f | SummitLookdown=%.1f" % [
		fps_diorama["vsync_fps"], fps_w1["vsync_fps"], fps_w2["vsync_fps"], fps_w5["vsync_fps"], fps_summit["vsync_fps"]
	])
	print("[GAUNTLET FPS SUMMARY UNCAPPED] Diorama=%.1f (%.2fms) | W1=%.1f (%.2fms) | W2=%.1f (%.2fms) | W5=%.1f (%.2fms) | SummitLookdown=%.1f (%.2fms)" % [
		fps_diorama["raw_fps"], fps_diorama["raw_ms"],
		fps_w1["raw_fps"], fps_w1["raw_ms"],
		fps_w2["raw_fps"], fps_w2["raw_ms"],
		fps_w5["raw_fps"], fps_w5["raw_ms"],
		fps_summit["raw_fps"], fps_summit["raw_ms"],
	])
	print("================ GAUNTLET CAPTURE COMPLETE ================")
	get_tree().quit(0 if report["passed"] else 2)


func _measure_fps(label: String) -> Dictionary:
	# 1. Measure VSYNC-enabled pacing (20 frames)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	for _i in range(4):
		await get_tree().process_frame
	var t0 := Time.get_ticks_usec()
	var frames := 20
	for _i in range(frames):
		await get_tree().process_frame
	var dt_v := float(Time.get_ticks_usec() - t0) / 1000000.0
	var vsync_fps := float(frames) / maxf(dt_v, 0.001)

	# 2. Measure TRUE uncapped GPU frame time with VSYNC_DISABLED (24 frames)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for _i in range(4):
		await get_tree().process_frame
	var t1 := Time.get_ticks_usec()
	var raw_frames := 24
	for _i in range(raw_frames):
		await get_tree().process_frame
	var dt_r := float(Time.get_ticks_usec() - t1) / 1000000.0
	var raw_fps := float(raw_frames) / maxf(dt_r, 0.001)
	var raw_ms := (dt_r * 1000.0) / float(raw_frames)
	var draws := get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)

	print("[GAUNTLET FPS] %s: vsync=%.1f FPS | uncapped=%.1f FPS (%.2f ms/frame) | draws=%d" % [label, vsync_fps, raw_fps, raw_ms, draws])
	return {"vsync_fps": vsync_fps, "raw_fps": raw_fps, "raw_ms": raw_ms, "draws": draws}


func _shot_player_height(player: PlayerController, atmo: Node3D, pos: Vector3, yaw_rad: float, alt_y: float, fname: String) -> void:
	atmo.apply_for_altitude(alt_y, true)
	player.visible = true
	player.teleport_to_checkpoint(pos, yaw_rad)
	player.camera_rig.snap_to(pos, yaw_rad)
	player.camera_rig.camera.current = true
	await _snap(fname)


func _shot_vista(cam: Camera3D, atmo: Node3D, cam_pos: Vector3, look_target: Vector3, alt_y: float, fname: String) -> void:
	atmo.apply_for_altitude(alt_y, true)
	cam.global_position = cam_pos
	cam.look_at(look_target, Vector3.UP)
	await _snap(fname)


func _snap(fname: String) -> void:
	for _i in range(4):
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var full := "%s/%s" % [OUT_DIR, fname]
	img.save_png(full)
	print("[GAUNTLET] Saved %s (%dx%d)" % [fname, img.get_width(), img.get_height()])
