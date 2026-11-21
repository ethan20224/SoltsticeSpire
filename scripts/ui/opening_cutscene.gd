extends Node3D
class_name OpeningCutscene
## ~10.5s "The Grand Descent" Opening Flythrough Cutscene for Solstice Spire.
## Sweeps down all 6 ascending realms via Catmull-Rom splines while dynamically streaming
## SpireWorld & BiomeAtmosphere, settling into a gentle living orbit over the Sunlit Terrace.

signal cutscene_finished()

const DESCENT_DURATION := 10.5
const LETTERBOX_H := 42.0

var _camera: Camera3D
var _canvas: CanvasLayer
var _overlay: Control
var _top_bar: ColorRect
var _bot_bar: ColorRect
var _realm_box: VBoxContainer
var _realm_eyebrow: Label
var _realm_title: Label
var _prompt_pill: PanelContainer
var _prompt_label: Label

var _spire_world: SpireWorld
var _atmosphere: Node3D
var _diorama_root: Node3D

var _waypoints: Array[Dictionary] = []
var _active: bool = false
var _advancing: bool = false
var _elapsed: float = 0.0
var _orbit_time: float = 0.0
var _last_realm_idx: int = -1
var _advance_tween: Tween
var _prompt_pulse_t: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_setup_camera_and_ui()
	PhoneController.connection_changed.connect(func(_c: bool, _cnt: int, _dev: String): _refresh_prompt_text())
	PhoneController.mode_changed.connect(func(_u: bool): _refresh_prompt_text())


func _setup_camera_and_ui() -> void:
	_camera = Camera3D.new()
	_camera.name = "CutsceneCamera"
	_camera.fov = 56.0
	_camera.near = 0.1
	_camera.far = 1600.0
	add_child(_camera)

	_canvas = CanvasLayer.new()
	_canvas.name = "CutsceneUILayer"
	_canvas.layer = 8
	_canvas.visible = false
	add_child(_canvas)

	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_overlay)

	# Warm espresso cinematic letterbox bars (42px tall)
	_top_bar = ColorRect.new()
	_top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = LETTERBOX_H
	_top_bar.color = Color(0.04, 0.03, 0.045, 0.96)
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_top_bar)

	_bot_bar = ColorRect.new()
	_bot_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bot_bar.offset_top = -LETTERBOX_H
	_bot_bar.color = Color(0.04, 0.03, 0.045, 0.96)
	_bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_bot_bar)

	# Soft top-left radial scrim + Realm subtitle whisper
	var tl_scrim := UITheme.make_radial_scrim(Vector2(480, 160), Vector2(0.28, 0.38), 0.48, Color(0.04, 0.03, 0.05))
	tl_scrim.position = Vector2(0, LETTERBOX_H)
	_overlay.add_child(tl_scrim)

	_realm_box = VBoxContainer.new()
	_realm_box.position = Vector2(44, LETTERBOX_H + 18.0)
	_realm_box.add_theme_constant_override("separation", 2)
	_realm_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_realm_box)

	_realm_eyebrow = Label.new()
	_realm_eyebrow.text = "The Grand Descent"
	UITheme.apply_font(_realm_eyebrow, "semibold", 12, UITheme.INK_EYEBROW, 0.36, 1)
	_realm_box.add_child(_realm_eyebrow)

	_realm_title = Label.new()
	_realm_title.text = "VI · The Crown of the Sun"
	UITheme.apply_font(_realm_title, "extrabold", 24, UITheme.INK_PRIMARY, 0.38, 2)
	_realm_box.add_child(_realm_title)

	# Bottom-center inviting Continue pill above bottom letterbox bar
	var bot_center := CenterContainer.new()
	bot_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot_center.offset_top = -LETTERBOX_H - 58.0
	bot_center.offset_bottom = -LETTERBOX_H - 14.0
	bot_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bot_center)

	_prompt_pill = PanelContainer.new()
	_prompt_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_pill.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.09, 0.075, 0.088, 0.84),
		Color(0.98, 0.78, 0.34, 0.56),
		999, 22, 8, 1
	))
	bot_center.add_child(_prompt_pill)

	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_prompt_label, "bold", 14, UITheme.INK_PRIMARY)
	_prompt_pill.add_child(_prompt_label)
	_refresh_prompt_text()


func _refresh_prompt_text() -> void:
	if _prompt_label == null:
		return
	var phone_on := PhoneController.is_connected or PhoneController.use_phone_controller
	if phone_on:
		_prompt_label.text = "Press Enter  ·  or ✕ on iPhone to Continue"
	else:
		_prompt_label.text = "Press Enter to Continue"


func _build_waypoints() -> void:
	var dio_origin := _diorama_root.global_position if _diorama_root else Vector3(0.0, 0.05, 25.5)
	var final_cam := dio_origin + Vector3(0.0, 1.24, 4.65)
	var final_look := dio_origin + Vector3(0.0, 0.82, 0.0)

	_waypoints = [
		{"t": 0.0,  "pos": Vector3(0.0, 1102.0, 24.0),   "look": Vector3(0.0, 1086.0, 0.0),  "fov": 56.0},
		{"t": 1.6,  "pos": Vector3(-26.0, 1086.0, 30.0), "look": Vector3(0.0, 1072.0, 0.0),  "fov": 56.0},
		{"t": 2.4,  "pos": Vector3(-48.0, 825.0, 24.0),  "look": Vector3(-2.0, 792.0, 0.0),  "fov": 57.0},
		{"t": 3.7,  "pos": Vector3(-42.0, 768.0, -28.0), "look": Vector3(-2.0, 762.0, 0.0),  "fov": 57.0},
		{"t": 4.6,  "pos": Vector3(50.0, 622.0, -32.0),  "look": Vector3(2.0, 594.0, -4.0),  "fov": 56.0},
		{"t": 5.5,  "pos": Vector3(50.0, 578.0, 28.0),   "look": Vector3(4.0, 568.0, -4.0),  "fov": 56.0},
		{"t": 6.4,  "pos": Vector3(-30.0, 445.0, 38.0),  "look": Vector3(0.0, 422.0, 0.0),   "fov": 56.0},
		{"t": 7.3,  "pos": Vector3(-44.0, 394.0, -20.0), "look": Vector3(0.0, 392.0, -4.0),  "fov": 55.0},
		{"t": 8.1,  "pos": Vector3(44.0, 255.0, -22.0),  "look": Vector3(0.0, 230.0, 0.0),   "fov": 55.0},
		{"t": 8.9,  "pos": Vector3(36.0, 206.0, 32.0),   "look": Vector3(2.0, 204.0, -4.0),  "fov": 54.0},
		{"t": 9.7,  "pos": Vector3(-22.0, 68.0, 38.0),   "look": Vector3(0.0, 28.0, 10.0),   "fov": 50.0},
		{"t": 10.5, "pos": final_cam,                    "look": final_look,                 "fov": 44.0},
	]


func start_descent(spire_world: SpireWorld, atmosphere: Node3D, diorama_root: Node3D) -> void:
	_spire_world = spire_world
	_atmosphere = atmosphere
	_diorama_root = diorama_root

	if _advance_tween and _advance_tween.is_valid():
		_advance_tween.kill()
	_advance_tween = null

	_build_waypoints()
	_active = true
	_advancing = false
	_elapsed = 0.0
	_orbit_time = 0.0
	_last_realm_idx = -1
	_prompt_pulse_t = 0.0

	visible = true
	_canvas.visible = true
	_overlay.modulate.a = 1.0
	_top_bar.offset_bottom = LETTERBOX_H
	_bot_bar.offset_top = -LETTERBOX_H
	_refresh_prompt_text()

	if _diorama_root:
		_diorama_root.visible = true
	if _spire_world:
		_spire_world.set_diorama_cull(false)
	if _atmosphere and _atmosphere.world_environment and _atmosphere.world_environment.environment:
		_atmosphere.world_environment.environment.volumetric_fog_length = 85.0

	_camera.current = true
	_set_airship_docking(0.0)
	_apply_cutscene_frame(0.0)


func seek_for_gauntlet(spire_world: SpireWorld, atmosphere: Node3D, diorama_root: Node3D, time_sec: float) -> void:
	## Deterministic frame seek for Gauntlet visual capture.
	_spire_world = spire_world
	_atmosphere = atmosphere
	_diorama_root = diorama_root
	_build_waypoints()
	_active = true
	_advancing = false
	_elapsed = clampf(time_sec, 0.0, DESCENT_DURATION)
	_orbit_time = 0.0
	_last_realm_idx = -1
	visible = true
	_canvas.visible = true
	_overlay.modulate.a = 1.0
	_top_bar.offset_bottom = LETTERBOX_H
	_bot_bar.offset_top = -LETTERBOX_H
	_refresh_prompt_text()
	if _diorama_root:
		_diorama_root.visible = true
	if _spire_world:
		_spire_world.set_diorama_cull(false)
	if _atmosphere and _atmosphere.world_environment and _atmosphere.world_environment.environment:
		_atmosphere.world_environment.environment.volumetric_fog_length = 85.0
	_camera.current = true
	_apply_cutscene_frame(_elapsed)


func skip_immediate() -> void:
	if _advance_tween and _advance_tween.is_valid():
		_advance_tween.kill()
	_advance_tween = null
	_active = false
	_advancing = false
	visible = false
	_canvas.visible = false
	_set_airship_docking(1.0)


func request_continue() -> void:
	if not _active or _advancing:
		return
	_advancing = true
	_set_airship_docking(1.0)
	AudioDirector.play_sfx("ui_click", -2.0, 1.12)

	var dio_origin := _diorama_root.global_position if _diorama_root else Vector3(0.0, 0.05, 25.5)
	var target_cam := dio_origin + Vector3(0.0, 1.24, 4.65)
	var target_look := dio_origin + Vector3(0.0, 0.82, 0.0)
	var target_basis := Transform3D(Basis(), target_cam).looking_at(target_look, Vector3.UP).basis

	if _advance_tween and _advance_tween.is_valid():
		_advance_tween.kill()
	_advance_tween = create_tween().set_parallel(true)
	_advance_tween.tween_property(_top_bar, "offset_bottom", 0.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_advance_tween.tween_property(_bot_bar, "offset_top", 0.0, 0.35).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_advance_tween.tween_property(_overlay, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_advance_tween.tween_property(_camera, "global_position", target_cam, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_advance_tween.tween_property(_camera, "fov", 44.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_advance_tween.tween_property(_camera, "global_basis", target_basis, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_advance_tween.chain().tween_callback(func():
		_active = false
		_advancing = false
		visible = false
		_canvas.visible = false
		cutscene_finished.emit()
	)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or _advancing:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc := (event as InputEventKey).keycode
		var pk := (event as InputEventKey).physical_keycode
		if kc == KEY_ENTER or kc == KEY_KP_ENTER or pk == KEY_ENTER or pk == KEY_KP_ENTER:
			request_continue()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _active:
		return

	_prompt_pulse_t += delta
	var pulse := 0.82 + 0.18 * sin(_prompt_pulse_t * 3.1)
	_prompt_pill.modulate = Color(1.0, 1.0, 1.0, pulse)

	if _advancing:
		return

	if _elapsed < DESCENT_DURATION:
		_elapsed = minf(_elapsed + delta, DESCENT_DURATION)
		_apply_cutscene_frame(_elapsed)
	else:
		_orbit_time += delta
		_apply_orbit_frame(_orbit_time)


func _apply_cutscene_frame(t_sec: float) -> void:
	# Smooth ease-in-out timing curve mapped gently over 10.5s
	var u := clampf(t_sec / DESCENT_DURATION, 0.0, 1.0)
	var eased_t := _ease_in_out_subtle(u) * DESCENT_DURATION
	var sample := _sample_spline(eased_t)
	var cam_pos: Vector3 = sample["pos"]
	var look_pos: Vector3 = sample["look"]
	var fov_val: float = float(sample["fov"])

	_camera.global_position = cam_pos
	_camera.fov = fov_val
	if cam_pos.distance_squared_to(look_pos) > 0.01:
		_camera.look_at(look_pos, Vector3.UP)

	var cam_y := cam_pos.y
	if _atmosphere:
		_atmosphere.apply_for_altitude(cam_y, true)
	if _spire_world:
		var w_idx := _spire_world.world_index_for_altitude(cam_y)
		_spire_world.set_focus_world(w_idx, cam_y >= 1040.0, cam_y)
		_update_realm_whisper(w_idx)
	# Live Docking Sequence: during final 2.6s of the descent, The Dawnbreaker glides in & lowers its gangplank!
	var dock_t := clampf((t_sec - 7.9) / 2.5, 0.0, 1.0)
	_set_airship_docking(dock_t)


func _set_airship_docking(t: float) -> void:
	if not is_inside_tree():
		return
	var ship := get_tree().get_first_node_in_group("docked_airship")
	if ship and ship.has_method("set_docking_progress"):
		ship.call("set_docking_progress", t)


func _apply_orbit_frame(orb_t: float) -> void:
	_set_airship_docking(1.0)
	var dio_origin := _diorama_root.global_position if _diorama_root else Vector3(0.0, 0.05, 25.5)
	var look_target := dio_origin + Vector3(0.0, 0.82, 0.0)
	var ramp := smoothstep(0.0, 1.2, orb_t)
	var yaw_offset := sin(orb_t * 0.42) * deg_to_rad(6.0) * ramp
	var y_float := sin(orb_t * 0.65) * 0.08 * ramp
	var base_off := Vector3(0.0, 0.42, 4.65).rotated(Vector3.UP, yaw_offset)
	var cam_pos := look_target + base_off + Vector3(0.0, y_float, 0.0)

	_camera.global_position = cam_pos
	_camera.fov = 44.0
	_camera.look_at(look_target, Vector3.UP)
	if _atmosphere:
		_atmosphere.apply_for_altitude(10.0, true)
	if _spire_world:
		_spire_world.set_focus_world(0, false, 10.0)
	_update_realm_whisper(0)


func _update_realm_whisper(w_idx: int) -> void:
	if w_idx == _last_realm_idx:
		return
	_last_realm_idx = w_idx
	var roman: String = GameState.ROMAN_NUMERALS[clampi(w_idx, 0, GameState.ROMAN_NUMERALS.size() - 1)]
	var w_name: String = GameState.WORLDS[clampi(w_idx, 0, GameState.WORLDS.size() - 1)]["name"]
	_realm_title.text = "%s · %s" % [roman, w_name]
	_realm_box.modulate.a = 0.0
	var tw := _realm_box.create_tween()
	tw.tween_property(_realm_box, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _ease_in_out_subtle(u: float) -> float:
	# Blend 35% smoothstep with 65% linear so descent sweeps briskly without lingering too long at endpoints
	var smooth := u * u * (3.0 - 2.0 * u)
	return lerpf(u, smooth, 0.35)


func _sample_spline(t_sec: float) -> Dictionary:
	var n := _waypoints.size()
	if n == 0:
		return {"pos": Vector3(0, 10, 30), "look": Vector3.ZERO, "fov": 56.0}
	if t_sec <= float(_waypoints[0]["t"]):
		return _waypoints[0]
	if t_sec >= float(_waypoints[n - 1]["t"]):
		return _waypoints[n - 1]

	var seg := 0
	for i in range(n - 1):
		if t_sec >= float(_waypoints[i]["t"]) and t_sec <= float(_waypoints[i + 1]["t"]):
			seg = i
			break

	var t1: float = float(_waypoints[seg]["t"])
	var t2: float = float(_waypoints[seg + 1]["t"])
	var u: float = clampf((t_sec - t1) / maxf(t2 - t1, 0.0001), 0.0, 1.0)

	var i0 := maxi(seg - 1, 0)
	var i1 := seg
	var i2 := mini(seg + 1, n - 1)
	var i3 := mini(seg + 2, n - 1)

	var pos := _catmull_rom_v3(_waypoints[i0]["pos"], _waypoints[i1]["pos"], _waypoints[i2]["pos"], _waypoints[i3]["pos"], u)
	var look := _catmull_rom_v3(_waypoints[i0]["look"], _waypoints[i1]["look"], _waypoints[i2]["look"], _waypoints[i3]["look"], u)
	var fov_v := lerpf(float(_waypoints[i1]["fov"]), float(_waypoints[i2]["fov"]), u)
	return {"pos": pos, "look": look, "fov": fov_v}


func _catmull_rom_v3(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2 := u * u
	var u3 := u2 * u
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * u +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3
	)
