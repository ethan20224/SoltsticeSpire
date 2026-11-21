extends Node
## Unified Input Manager for Solstice Spire.
## Supports Keyboard & Mouse, Physical Gamepads (PS5 DualSense, Xbox, Nintendo Switch Pro)
## with edge-latched 60Hz sampling, radial deadzones, haptic rumble, UI navigation signals,
## and live iPhone Web Controller synchronization.

signal input_mode_changed(mode: String)
signal gamepad_changed(connected: bool, device_name: String, style: String)
signal ui_confirm_pressed()
signal ui_cancel_pressed()
signal ui_pause_pressed()
signal ui_nav_pressed(dir: int)

const LEFT_DEADZONE := 0.15
const RIGHT_DEADZONE := 0.14
const TRIGGER_THRESHOLD := 0.35

var input_mode: String = "keyboard"  # "keyboard", "gamepad", "phone"
var gamepad_style: String = "ps5"  # "ps5", "xbox", "switch"
var gamepad_connected: bool = false
var gamepad_name: String = ""
var active_joy_id: int = -1

var _move_vec: Vector2 = Vector2.ZERO
var _look_stick: Vector2 = Vector2.ZERO
var _sprint_held: bool = false
var _jump_held: bool = false
var _dash_held: bool = false
var _slide_held: bool = false
var _rewind_held: bool = false

var _jump_just_pressed_latch: bool = false
var _dash_just_pressed_latch: bool = false
var _slide_just_pressed_latch: bool = false
var _rewind_just_pressed_latch: bool = false
var _focus_just_pressed_latch: bool = false
var _assist_yes_just_pressed_latch: bool = false
var _assist_no_just_pressed_latch: bool = false
var _prev_focus_btn: bool = false
var _prev_dpad_u: bool = false
var _prev_dpad_d: bool = false

var _prev_a: bool = false
var _prev_b: bool = false
var _prev_start: bool = false
var _prev_dpad_l: bool = false
var _prev_dpad_r: bool = false
var _last_stick_nav_dir: int = 0
var _nav_repeat_timer: float = 0.0

var _gamepad_touched: bool = false
var _syncing_phone: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var pref_mode := GameState.preferred_input_mode
	input_mode = pref_mode if pref_mode in ["keyboard", "gamepad", "phone"] else "keyboard"
	var pref_style := GameState.preferred_gamepad_style
	gamepad_style = pref_style if pref_style in ["ps5", "xbox", "switch"] else "ps5"

	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	PhoneController.mode_changed.connect(_on_phone_mode_changed)
	GameState.shard_collected.connect(_on_shard_collected)

	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		active_joy_id = pads[0]
		gamepad_connected = true
		gamepad_name = Input.get_joy_name(active_joy_id)
		gamepad_style = _detect_style_from_name(gamepad_name)
		GameState.preferred_gamepad_style = gamepad_style

	if PhoneController.use_phone_controller:
		input_mode = "phone"
	elif input_mode == "phone":
		_syncing_phone = true
		PhoneController.set_phone_mode(true)
		_syncing_phone = false
	elif input_mode == "gamepad" and not gamepad_connected:
		input_mode = "keyboard"


func _on_shard_collected(total_shards: int, _max_shards: int) -> void:
	if total_shards > 0:
		rumble("shard")


func _detect_style_from_name(joy_name: String) -> String:
	var low := joy_name.to_lower()
	if low.contains("nintendo") or low.contains("switch") or low.contains("pro controller") or low.contains("joy-con"):
		return "switch"
	if low.contains("dualsense") or low.contains("dualshock") or low.contains("playstation") or low.contains("ps5") or low.contains("ps4") or low.contains("sony"):
		return "ps5"
	return "xbox"


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		active_joy_id = device
		gamepad_connected = true
		gamepad_name = Input.get_joy_name(device)
		gamepad_style = _detect_style_from_name(gamepad_name)
		GameState.preferred_gamepad_style = gamepad_style
		gamepad_changed.emit(true, gamepad_name, gamepad_style)
		if input_mode == "keyboard":
			set_input_mode("gamepad", false)
	else:
		if device == active_joy_id:
			var pads := Input.get_connected_joypads()
			if not pads.is_empty():
				active_joy_id = pads[0]
				gamepad_connected = true
				gamepad_name = Input.get_joy_name(active_joy_id)
				gamepad_style = _detect_style_from_name(gamepad_name)
				gamepad_changed.emit(true, gamepad_name, gamepad_style)
			else:
				active_joy_id = -1
				gamepad_connected = false
				gamepad_name = ""
				_clear_gamepad_state()
				gamepad_changed.emit(false, "", gamepad_style)
				if input_mode == "gamepad":
					set_input_mode("keyboard", false)


func _on_phone_mode_changed(use_phone: bool) -> void:
	if _syncing_phone:
		return
	if use_phone:
		if input_mode != "phone":
			input_mode = "phone"
			_gamepad_touched = false
			GameState.preferred_input_mode = "phone"
			input_mode_changed.emit("phone")
	else:
		if input_mode == "phone":
			var fallback := "gamepad" if gamepad_connected else "keyboard"
			input_mode = fallback
			GameState.preferred_input_mode = fallback
			input_mode_changed.emit(fallback)


func set_input_mode(mode: String, persist: bool = true) -> void:
	var clean_mode := mode if mode in ["keyboard", "gamepad", "phone"] else "keyboard"
	var changed := input_mode != clean_mode
	input_mode = clean_mode
	if clean_mode != "gamepad":
		_gamepad_touched = false

	_syncing_phone = true
	PhoneController.set_phone_mode(clean_mode == "phone")
	_syncing_phone = false

	if persist:
		GameState.preferred_input_mode = clean_mode
		GameState.save_persistent_data()

	if changed or persist:
		input_mode_changed.emit(input_mode)


func set_gamepad_style(style: String, persist: bool = true) -> void:
	var clean_style := style if style in ["ps5", "xbox", "switch"] else "xbox"
	gamepad_style = clean_style
	if persist:
		GameState.preferred_gamepad_style = clean_style
		GameState.save_persistent_data()
	gamepad_changed.emit(gamepad_connected, gamepad_name, gamepad_style)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.pressed:
			_claim_active_joypad(jb.device)
			_gamepad_touched = true
			if input_mode == "keyboard":
				set_input_mode("gamepad", false)
	elif event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		if absf(jm.axis_value) > 0.28:
			_claim_active_joypad(jm.device)
			_gamepad_touched = true
			if input_mode == "keyboard":
				set_input_mode("gamepad", false)
	elif event is InputEventKey:
		var kev := event as InputEventKey
		if kev.pressed and not kev.echo and input_mode == "gamepad":
			var pk := kev.physical_keycode
			if pk in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE]:
				_gamepad_touched = false
				set_input_mode("keyboard", false)


func _claim_active_joypad(device: int) -> void:
	if device < 0:
		return
	if not gamepad_connected or active_joy_id != device:
		active_joy_id = device
		gamepad_connected = true
		gamepad_name = Input.get_joy_name(device)
		gamepad_style = _detect_style_from_name(gamepad_name)
		gamepad_changed.emit(true, gamepad_name, gamepad_style)


func _process(delta: float) -> void:
	if _nav_repeat_timer > 0.0:
		_nav_repeat_timer = maxf(0.0, _nav_repeat_timer - delta)
	_sample_gamepad()


func _physics_process(_delta: float) -> void:
	_sample_gamepad()


func _clear_gamepad_state() -> void:
	_move_vec = Vector2.ZERO
	_look_stick = Vector2.ZERO
	_sprint_held = false
	_jump_held = false
	_dash_held = false
	_slide_held = false
	_rewind_held = false
	_jump_just_pressed_latch = false
	_dash_just_pressed_latch = false
	_slide_just_pressed_latch = false
	_rewind_just_pressed_latch = false
	_focus_just_pressed_latch = false
	_assist_yes_just_pressed_latch = false
	_assist_no_just_pressed_latch = false
	_prev_focus_btn = false
	_prev_dpad_u = false
	_prev_dpad_d = false
	_prev_a = false
	_prev_b = false
	_prev_start = false
	_prev_dpad_l = false
	_prev_dpad_r = false
	_last_stick_nav_dir = 0
	_nav_repeat_timer = 0.0
	_gamepad_touched = false


func _sample_gamepad() -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		if gamepad_connected:
			active_joy_id = -1
			gamepad_connected = false
			gamepad_name = ""
			_clear_gamepad_state()
			gamepad_changed.emit(false, "", gamepad_style)
			if input_mode == "gamepad":
				set_input_mode("keyboard", false)
		return

	var jid := active_joy_id
	if jid < 0 or not pads.has(jid):
		jid = pads[0]
		active_joy_id = jid
		if not gamepad_connected:
			gamepad_connected = true
			gamepad_name = Input.get_joy_name(jid)
			gamepad_style = _detect_style_from_name(gamepad_name)
			gamepad_changed.emit(true, gamepad_name, gamepad_style)

	# Left Stick: radial deadzone 0.15, rescaled (mag - 0.15) / 0.85, gentle curve
	var raw_l := Vector2(
		Input.get_joy_axis(jid, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(jid, JOY_AXIS_LEFT_Y)
	)
	var mag_l := raw_l.length()
	if mag_l > LEFT_DEADZONE:
		var norm_l := clampf((mag_l - LEFT_DEADZONE) / (1.0 - LEFT_DEADZONE), 0.0, 1.0)
		var curved_l := lerpf(norm_l, norm_l * norm_l, 0.25)
		_move_vec = (raw_l / mag_l) * curved_l
	else:
		_move_vec = Vector2.ZERO

	# Right Stick: radial deadzone 0.14, rescaled (mag - 0.14) / 0.86
	var raw_r := Vector2(
		Input.get_joy_axis(jid, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(jid, JOY_AXIS_RIGHT_Y)
	)
	var mag_r := raw_r.length()
	if mag_r > RIGHT_DEADZONE:
		var norm_r := clampf((mag_r - RIGHT_DEADZONE) / (1.0 - RIGHT_DEADZONE), 0.0, 1.0)
		_look_stick = (raw_r / mag_r) * norm_r
	else:
		_look_stick = Vector2.ZERO

	var trig_l := Input.get_joy_axis(jid, JOY_AXIS_TRIGGER_LEFT)
	var trig_r := Input.get_joy_axis(jid, JOY_AXIS_TRIGGER_RIGHT)

	var btn_a := Input.is_joy_button_pressed(jid, JOY_BUTTON_A)
	var btn_b := Input.is_joy_button_pressed(jid, JOY_BUTTON_B)
	var btn_x := Input.is_joy_button_pressed(jid, JOY_BUTTON_X)
	var btn_y := Input.is_joy_button_pressed(jid, JOY_BUTTON_Y)
	var btn_lb := Input.is_joy_button_pressed(jid, JOY_BUTTON_LEFT_SHOULDER)
	var btn_rb := Input.is_joy_button_pressed(jid, JOY_BUTTON_RIGHT_SHOULDER)
	var btn_l3 := Input.is_joy_button_pressed(jid, JOY_BUTTON_LEFT_STICK)
	var btn_r3 := Input.is_joy_button_pressed(jid, JOY_BUTTON_RIGHT_STICK)
	var btn_start := Input.is_joy_button_pressed(jid, JOY_BUTTON_START)
	var btn_dpad_l := Input.is_joy_button_pressed(jid, JOY_BUTTON_DPAD_LEFT)
	var btn_dpad_r := Input.is_joy_button_pressed(jid, JOY_BUTTON_DPAD_RIGHT)
	var btn_dpad_u := Input.is_joy_button_pressed(jid, JOY_BUTTON_DPAD_UP)
	var btn_dpad_d := Input.is_joy_button_pressed(jid, JOY_BUTTON_DPAD_DOWN)

	var new_jump := btn_a or btn_rb
	var new_dash := btn_x or (trig_r > TRIGGER_THRESHOLD)
	var new_slide := btn_b or (trig_l > TRIGGER_THRESHOLD)
	var new_rewind := btn_y
	var new_focus := btn_r3 or btn_lb
	var new_sprint := btn_l3 or btn_lb or (mag_l > 0.90)

	if mag_l > 0.22 or mag_r > 0.22 or new_jump or new_dash or new_slide or new_rewind or btn_start or btn_dpad_l or btn_dpad_r:
		_gamepad_touched = true
		if input_mode == "keyboard":
			set_input_mode("gamepad", false)

	if btn_start and not _prev_start:
		ui_pause_pressed.emit()

	var in_victory_modal := GameState.has_finished and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	var actively_playing := GameState.is_playing and not GameState.is_paused and not GameState.is_cutscene and not in_victory_modal

	if actively_playing:
		if new_jump and not _jump_held:
			_jump_just_pressed_latch = true
		if new_dash and not _dash_held:
			_dash_just_pressed_latch = true
		if new_slide and not _slide_held:
			_slide_just_pressed_latch = true
		if new_rewind and not _rewind_held:
			_rewind_just_pressed_latch = true
		if new_focus and not _prev_focus_btn:
			_focus_just_pressed_latch = true
		if btn_dpad_u and not _prev_dpad_u:
			_assist_yes_just_pressed_latch = true
		if btn_dpad_d and not _prev_dpad_d:
			_assist_no_just_pressed_latch = true
		_last_stick_nav_dir = 0
		_nav_repeat_timer = 0.0
	else:
		_jump_just_pressed_latch = false
		_dash_just_pressed_latch = false
		_slide_just_pressed_latch = false
		_rewind_just_pressed_latch = false

		if btn_a and not _prev_a:
			ui_confirm_pressed.emit()
		if btn_b and not _prev_b:
			ui_cancel_pressed.emit()
		if btn_dpad_l and not _prev_dpad_l:
			ui_nav_pressed.emit(-1)
		if btn_dpad_r and not _prev_dpad_r:
			ui_nav_pressed.emit(1)

		if absf(raw_l.x) > 0.58:
			var stick_dir := -1 if raw_l.x < 0.0 else 1
			if _last_stick_nav_dir != stick_dir or _nav_repeat_timer <= 0.0:
				_last_stick_nav_dir = stick_dir
				_nav_repeat_timer = 0.26
				ui_nav_pressed.emit(stick_dir)
		elif absf(raw_l.x) < 0.28:
			_last_stick_nav_dir = 0
			_nav_repeat_timer = 0.0

	_jump_held = new_jump
	_dash_held = new_dash
	_slide_held = new_slide
	_rewind_held = new_rewind
	_sprint_held = new_sprint
	_prev_focus_btn = new_focus

	_prev_a = btn_a
	_prev_b = btn_b
	_prev_start = btn_start
	_prev_dpad_l = btn_dpad_l
	_prev_dpad_r = btn_dpad_r
	_prev_dpad_u = btn_dpad_u
	_prev_dpad_d = btn_dpad_d


func is_gamepad_active() -> bool:
	return gamepad_connected and (input_mode == "gamepad" or _gamepad_touched)


func get_move_vector() -> Vector2:
	return _move_vec


func get_look_stick() -> Vector2:
	return _look_stick


func is_sprint_held() -> bool:
	return _sprint_held


func is_jump_held() -> bool:
	return _jump_held


func is_slide_held() -> bool:
	return _slide_held


func consume_jump_just_pressed() -> bool:
	if _jump_just_pressed_latch:
		_jump_just_pressed_latch = false
		return true
	return false


func consume_dash_just_pressed() -> bool:
	if _dash_just_pressed_latch:
		_dash_just_pressed_latch = false
		return true
	return false


func consume_slide_just_pressed() -> bool:
	if _slide_just_pressed_latch:
		_slide_just_pressed_latch = false
		return true
	return false


func consume_rewind_just_pressed() -> bool:
	if _rewind_just_pressed_latch:
		_rewind_just_pressed_latch = false
		return true
	return false


func consume_focus_just_pressed() -> bool:
	if _focus_just_pressed_latch:
		_focus_just_pressed_latch = false
		return true
	return false


func consume_assist_yes_just_pressed() -> bool:
	if _assist_yes_just_pressed_latch:
		_assist_yes_just_pressed_latch = false
		return true
	return false


func consume_assist_no_just_pressed() -> bool:
	if _assist_no_just_pressed_latch:
		_assist_no_just_pressed_latch = false
		return true
	return false


func rumble(kind: String) -> void:
	if not gamepad_connected or active_joy_id < 0 or not is_gamepad_active():
		return
	var weak := 0.20
	var strong := 0.12
	var dur := 0.06
	match kind:
		"jump":
			weak = 0.22; strong = 0.08; dur = 0.055
		"double_jump":
			weak = 0.34; strong = 0.14; dur = 0.070
		"dash":
			weak = 0.48; strong = 0.30; dur = 0.095
		"slide":
			weak = 0.22; strong = 0.12; dur = 0.075
		"wall_kick":
			weak = 0.42; strong = 0.28; dur = 0.080
		"bounce":
			weak = 0.46; strong = 0.34; dur = 0.100
		"meteor":
			weak = 0.78; strong = 0.65; dur = 0.165
		"clutch":
			weak = 0.62; strong = 0.45; dur = 0.125
		"land":
			weak = 0.28; strong = 0.36; dur = 0.080
		"shard":
			weak = 0.38; strong = 0.18; dur = 0.110
		"summit":
			weak = 0.72; strong = 0.56; dur = 0.320
		"rewind":
			weak = 0.35; strong = 0.22; dur = 0.140
		_:
			return
	Input.start_joy_vibration(active_joy_id, weak, strong, dur)


func get_glyph(action: String) -> String:
	if input_mode == "phone":
		match action:
			"move": return "L-Stick"
			"look": return "R-Stick"
			"jump": return "✕ / R1"
			"dash": return "□ / R2"
			"slide": return "○ / L2"
			"sprint": return "Edge Push"
			"focus": return "L1 (Air)"
			"rewind": return "△"
			"pause": return "≡"
			"confirm": return "✕"
			"assist_yes": return "Y"
			"assist_no": return "N"
			_: return action.to_upper()

	if input_mode == "gamepad":
		if gamepad_style == "xbox":
			match action:
				"move": return "LS"
				"look": return "RS"
				"jump": return "A / RB"
				"dash": return "X / RT"
				"slide": return "B / LT"
				"sprint": return "LB / LS"
				"focus": return "LB / RS"
				"rewind": return "Y"
				"pause": return "Menu"
				"confirm": return "A"
				"assist_yes": return "D-Pad ↑"
				"assist_no": return "D-Pad ↓"
				_: return action.to_upper()
		elif gamepad_style == "switch":
			match action:
				"move": return "L-Stick"
				"look": return "R-Stick"
				"jump": return "B / R"
				"dash": return "Y / ZR"
				"slide": return "A / ZL"
				"sprint": return "L / L3"
				"focus": return "L / R3"
				"rewind": return "X"
				"pause": return "+"
				"confirm": return "B"
				"assist_yes": return "D-Pad ↑"
				"assist_no": return "D-Pad ↓"
				_: return action.to_upper()
		else:  # "ps5"
			match action:
				"move": return "L-Stick"
				"look": return "R-Stick"
				"jump": return "✕ / R1"
				"dash": return "□ / R2"
				"slide": return "○ / L2"
				"sprint": return "L1 / L3"
				"focus": return "L1 / R3"
				"rewind": return "△"
				"pause": return "Options"
				"confirm": return "✕"
				"assist_yes": return "D-Pad ↑"
				"assist_no": return "D-Pad ↓"
				_: return action.to_upper()

	# Default: "keyboard"
	match action:
		"move": return "WASD"
		"look": return "Mouse"
		"jump": return "Space"
		"dash": return "Shift / E / RMB"
		"slide": return "C / Ctrl"
		"sprint": return "Shift"
		"focus": return "Tab / V"
		"rewind": return "R"
		"pause": return "Esc"
		"confirm": return "Enter"
		"assist_yes": return "Y"
		"assist_no": return "N"
		_: return action.to_upper()
