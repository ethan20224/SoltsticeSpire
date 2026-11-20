extends Control
class_name GuideSettingsPanelUI
## Start-Screen "Guide & Settings" Modal matching the warm-walnut, cream-pill,
## amber-slider AAA design craft of PauseMenuUI, with Realm Direct-Launch,
## complete updated Guide & Controls, Sensitivity/Music sliders, Fullscreen & Invert Y toggles,
## and live iPhone 15 DualSense QR Deck.

signal closed()
signal world_launch_requested(world_idx: int)

const PairingPanelScript = preload("res://scripts/ui/phone_pairing_panel.gd")

var _card: PanelContainer
var _kb_btn: Button
var _phone_btn: Button
var _sens_slider: HSlider
var _mus_slider: HSlider
var _sens_val_lbl: Label
var _mus_val_lbl: Label
var _fullscreen_btn: Button
var _invert_y_btn: Button
var _syncing_ui: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_modal()
	PhoneController.mode_changed.connect(func(_u: bool): _refresh_ctrl_mode_buttons())
	PhoneController.connection_changed.connect(func(_c: bool, _n: int, _d: String): _refresh_ctrl_mode_buttons())


func open_animated() -> void:
	visible = true
	_sync_controls_from_state()
	UITheme.animate_enter(_card, 0.0, 0.20)


func close_panel() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _sync_controls_from_state() -> void:
	_syncing_ui = true
	if _sens_slider:
		_sens_slider.value = GameState.mouse_sensitivity
		_sens_val_lbl.text = "%.1fx" % (GameState.mouse_sensitivity / 0.0024)
	if _mus_slider:
		_mus_slider.value = GameState.music_volume
		_mus_val_lbl.text = "%d%%" % int(round(GameState.music_volume * 100.0))
	_syncing_ui = false
	_refresh_toggles()
	_refresh_ctrl_mode_buttons()


func _build_modal() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.035, 0.055, 0.62)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(1080, 0)
	_card.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_SOLID, Color(0.96, 0.86, 0.70, 0.28), 26, 26, 20, 1))
	center.add_child(_card)

	var outer_v := VBoxContainer.new()
	outer_v.add_theme_constant_override("separation", 12)
	_card.add_child(outer_v)

	# Header
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 1)
	outer_v.add_child(header)

	var eyebrow := Label.new()
	eyebrow.text = "Guide & Settings"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(eyebrow, "semibold", 13, UITheme.INK_SECONDARY)
	header.add_child(eyebrow)

	var h := Label.new()
	h.text = "Solstice Spire"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(h, "heavy", 28, UITheme.INK_PRIMARY)
	header.add_child(h)

	# 2-Column Body
	var body_cols := HBoxContainer.new()
	body_cols.add_theme_constant_override("separation", 20)
	outer_v.add_child(body_cols)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	body_cols.add_child(v)

	# Primary CTA
	var done_b := Button.new()
	done_b.text = "Done — Back to Explorers"
	done_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_primary_cta(done_b, 16)
	done_b.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		close_panel()
	)
	v.add_child(done_b)

	# Realm Direct Launch (2x3)
	var w_lbl := Label.new()
	w_lbl.text = "Launch Directly Into Realm"
	UITheme.apply_font(w_lbl, "bold", 13, UITheme.INK_SECONDARY)
	v.add_child(w_lbl)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for w in GameState.WORLDS:
		var wb := Button.new()
		wb.text = "%d. %s" % [int(w["idx"]) + 1, str(w["name"]).replace("The ", "")]
		wb.custom_minimum_size = Vector2(0, 36)
		wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_secondary_pill(wb, false, 13)
		var wi: int = int(w["idx"])
		wb.pressed.connect(func():
			AudioDirector.play_sfx("portal_warp", -3.0, 1.1)
			world_launch_requested.emit(wi)
		)
		grid.add_child(wb)

	# How to Play & Quick Controls
	var inst_lbl := Label.new()
	inst_lbl.text = "How to Play & Quick Controls"
	UITheme.apply_font(inst_lbl, "bold", 13, UITheme.INK_SECONDARY)
	v.add_child(inst_lbl)

	var inst_box := PanelContainer.new()
	inst_box.add_theme_stylebox_override("panel", UITheme.glass_box(Color(0.06, 0.05, 0.065, 0.68), UITheme.BORDER_SUBTLE, 14, 14, 10, 1))
	v.add_child(inst_box)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	inst_box.add_child(cols)

	var how_v := VBoxContainer.new()
	how_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	how_v.add_theme_constant_override("separation", 4)
	cols.add_child(how_v)

	var how_title := Label.new()
	how_title.text = "Gameplay Guide"
	UITheme.apply_font(how_title, "extrabold", 12, UITheme.INK_PRIMARY)
	how_v.add_child(how_title)

	var how_data := [
		["Goal:", "Climb 0m to 1,085m across 6 realms to the Summit Crown."],
		["Sky Shrines:", "Touch glowing shrines to save. Land below one? Press R within 30s to rewind!"],
		["Sun-Shards & Motes:", "Collect 18 golden Sun-Shards & glowing Solar Mote trails."],
		["Flow & Solar Charge:", "Chain bunny-hops, pads & wall-kicks; Max Flow grants a bonus Air-Dash!"],
		["Sky-Dive & Meteor:", "Hold C / ○ mid-air to Sky-Dive; slam a Bounce Pad for a Meteor Bounce!"],
		["Explorers:", "Pip (warm ledge grace) · Koko (zippy dash/slide) · Vesper (hold Jump to flutter)."],
	]
	for item in how_data:
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 6)
		how_v.add_child(hrow)

		var hk := Label.new()
		hk.text = item[0]
		hk.custom_minimum_size = Vector2(118, 0)
		UITheme.apply_font(hk, "bold", 11, UITheme.ACCENT_AMBER)
		hrow.add_child(hk)

		var hv := Label.new()
		hv.text = item[1]
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.apply_font(hv, "semibold", 11, UITheme.INK_PRIMARY)
		hrow.add_child(hv)

	var vsep := VSeparator.new()
	vsep.modulate = Color(0.96, 0.88, 0.72, 0.25)
	cols.add_child(vsep)

	var inst_v := VBoxContainer.new()
	inst_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inst_v.add_theme_constant_override("separation", 4)
	cols.add_child(inst_v)

	var ctrl_title := Label.new()
	ctrl_title.text = "Controls (Mac / iPhone Deck)"
	UITheme.apply_font(ctrl_title, "extrabold", 12, UITheme.INK_PRIMARY)
	inst_v.add_child(ctrl_title)

	var controls_data := [
		["Move / Camera:", "WASD + Mouse  ·  L-Stick (Edge Sprint) + R-Stick"],
		["Jump / Wall-Kick:", "Space  ·  ✕ Cross or R1 (Vesper: Hold to Flutter)"],
		["Air-Dash / Orb:", "Shift / E / RMB  ·  □ Square or R2 Trigger"],
		["Slide / Sky-Dive:", "C / Ctrl  ·  ○ Circle or L2 (Hold mid-air to Dive)"],
		["Rewind (30s Window):", "R  ·  △ Triangle or Top Shrine Pill"],
		["Fullscreen / Menu:", "F (Fullscreen) / Esc  ·  ≡ Menu Pill"],
	]
	for item in controls_data:
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 6)
		inst_v.add_child(crow)

		var k_lbl := Label.new()
		k_lbl.text = item[0]
		k_lbl.custom_minimum_size = Vector2(124, 0)
		UITheme.apply_font(k_lbl, "bold", 11, UITheme.ACCENT_AMBER)
		crow.add_child(k_lbl)

		var v_lbl := Label.new()
		v_lbl.text = item[1]
		v_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.apply_font(v_lbl, "semibold", 11, UITheme.INK_PRIMARY)
		crow.add_child(v_lbl)

	# Sensitivity & Music Sliders
	var track_bg := StyleBoxFlat.new()
	track_bg.bg_color = Color(0.96, 0.88, 0.74, 0.28)
	track_bg.content_margin_top = 4
	track_bg.content_margin_bottom = 4
	track_bg.set_corner_radius_all(4)
	var track_fill := StyleBoxFlat.new()
	track_fill.bg_color = UITheme.ACCENT_AMBER
	track_fill.content_margin_top = 4
	track_fill.content_margin_bottom = 4
	track_fill.set_corner_radius_all(4)

	var s_row := HBoxContainer.new()
	s_row.add_theme_constant_override("separation", 12)
	v.add_child(s_row)
	var sl := Label.new()
	sl.text = "Look Sensitivity"
	sl.custom_minimum_size = Vector2(148, 0)
	UITheme.apply_font(sl, "semibold", 14, UITheme.INK_SECONDARY)
	s_row.add_child(sl)
	_sens_slider = HSlider.new()
	_sens_slider.focus_mode = Control.FOCUS_NONE
	_sens_slider.min_value = 0.0008
	_sens_slider.max_value = 0.0060
	_sens_slider.step = 0.0002
	_sens_slider.value = GameState.mouse_sensitivity
	_sens_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sens_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sens_slider.add_theme_stylebox_override("slider", track_bg)
	_sens_slider.add_theme_stylebox_override("grabber_area", track_fill)
	_sens_slider.add_theme_stylebox_override("grabber_area_highlight", track_fill)
	s_row.add_child(_sens_slider)
	_sens_val_lbl = Label.new()
	_sens_val_lbl.custom_minimum_size = Vector2(48, 0)
	_sens_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sens_val_lbl.text = "%.1fx" % (GameState.mouse_sensitivity / 0.0024)
	UITheme.apply_font(_sens_val_lbl, "bold", 13, UITheme.INK_PRIMARY)
	s_row.add_child(_sens_val_lbl)
	_sens_slider.value_changed.connect(func(val: float):
		if _syncing_ui:
			return
		GameState.mouse_sensitivity = val
		_sens_val_lbl.text = "%.1fx" % (val / 0.0024)
		GameState.save_persistent_data()
	)

	var m_row := HBoxContainer.new()
	m_row.add_theme_constant_override("separation", 12)
	v.add_child(m_row)
	var ml := Label.new()
	ml.text = "Music Volume"
	ml.custom_minimum_size = Vector2(148, 0)
	UITheme.apply_font(ml, "semibold", 14, UITheme.INK_SECONDARY)
	m_row.add_child(ml)
	_mus_slider = HSlider.new()
	_mus_slider.focus_mode = Control.FOCUS_NONE
	_mus_slider.min_value = 0.0
	_mus_slider.max_value = 1.0
	_mus_slider.step = 0.05
	_mus_slider.value = GameState.music_volume
	_mus_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mus_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mus_slider.add_theme_stylebox_override("slider", track_bg)
	_mus_slider.add_theme_stylebox_override("grabber_area", track_fill)
	_mus_slider.add_theme_stylebox_override("grabber_area_highlight", track_fill)
	m_row.add_child(_mus_slider)
	_mus_val_lbl = Label.new()
	_mus_val_lbl.custom_minimum_size = Vector2(48, 0)
	_mus_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mus_val_lbl.text = "%d%%" % int(round(GameState.music_volume * 100.0))
	UITheme.apply_font(_mus_val_lbl, "bold", 13, UITheme.INK_PRIMARY)
	m_row.add_child(_mus_val_lbl)
	_mus_slider.value_changed.connect(func(val: float):
		if _syncing_ui:
			return
		AudioDirector.set_music_volume(val, true)
		_mus_val_lbl.text = "%d%%" % int(round(val * 100.0))
	)

	# Fullscreen & Invert Camera Y Toggles Row
	var toggle_row := HBoxContainer.new()
	toggle_row.add_theme_constant_override("separation", 10)
	v.add_child(toggle_row)

	_fullscreen_btn = Button.new()
	_fullscreen_btn.custom_minimum_size = Vector2(0, 36)
	_fullscreen_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fullscreen_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		_toggle_fullscreen()
	)
	toggle_row.add_child(_fullscreen_btn)

	_invert_y_btn = Button.new()
	_invert_y_btn.custom_minimum_size = Vector2(0, 36)
	_invert_y_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_invert_y_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		GameState.invert_y = not GameState.invert_y
		GameState.save_persistent_data()
		_refresh_toggles()
	)
	toggle_row.add_child(_invert_y_btn)
	_refresh_toggles()

	# Footer Row: Close + Quit Game (NO Restart Climb / Change Explorer on Start Screen!)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	v.add_child(foot)

	var close_b := Button.new()
	close_b.text = "Close"
	close_b.custom_minimum_size = Vector2(0, 42)
	close_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_secondary_pill(close_b, false, 14)
	close_b.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		close_panel()
	)
	foot.add_child(close_b)

	var quit_b := Button.new()
	quit_b.text = "Quit Game"
	quit_b.custom_minimum_size = Vector2(140, 42)
	UITheme.style_secondary_pill(quit_b, false, 14)
	quit_b.pressed.connect(func(): get_tree().quit())
	foot.add_child(quit_b)

	# Right Column: Controller Mode + Live Scannable QR Pairing Panel
	var right_v := VBoxContainer.new()
	right_v.custom_minimum_size = Vector2(285, 0)
	right_v.add_theme_constant_override("separation", 10)
	body_cols.add_child(right_v)

	var ctrl_mode_lbl := Label.new()
	ctrl_mode_lbl.text = "Controller Mode"
	UITheme.apply_font(ctrl_mode_lbl, "bold", 13, UITheme.INK_SECONDARY)
	right_v.add_child(ctrl_mode_lbl)

	var ctrl_mode_row := HBoxContainer.new()
	ctrl_mode_row.add_theme_constant_override("separation", 8)
	right_v.add_child(ctrl_mode_row)

	_kb_btn = Button.new()
	_kb_btn.text = "Keyboard"
	_kb_btn.custom_minimum_size = Vector2(0, 36)
	_kb_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kb_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.0)
		PhoneController.set_phone_mode(false)
	)
	ctrl_mode_row.add_child(_kb_btn)

	_phone_btn = Button.new()
	_phone_btn.text = "iPhone Deck"
	_phone_btn.custom_minimum_size = Vector2(0, 36)
	_phone_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_phone_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.15)
		PhoneController.set_phone_mode(true)
	)
	ctrl_mode_row.add_child(_phone_btn)

	var qr_panel := PairingPanelScript.new(true)
	qr_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_v.add_child(qr_panel)

	_refresh_ctrl_mode_buttons()


func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _toggle_fullscreen() -> void:
	if _is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_refresh_toggles()


func _refresh_toggles() -> void:
	if _fullscreen_btn:
		var fs_on := _is_fullscreen()
		_fullscreen_btn.text = "Fullscreen: On" if fs_on else "Fullscreen: Off"
		UITheme.style_secondary_pill(_fullscreen_btn, fs_on, 13)
	if _invert_y_btn:
		var inv_on := GameState.invert_y
		_invert_y_btn.text = "Invert Camera Y: On" if inv_on else "Invert Camera Y: Off"
		UITheme.style_secondary_pill(_invert_y_btn, inv_on, 13)


func _refresh_ctrl_mode_buttons() -> void:
	if _kb_btn == null or _phone_btn == null:
		return
	var phone_on := PhoneController.use_phone_controller
	UITheme.style_secondary_pill(_kb_btn, not phone_on, 13)
	UITheme.style_secondary_pill(_phone_btn, phone_on, 13)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		AudioDirector.play_sfx("ui_click")
		close_panel()
		get_viewport().set_input_as_handled()
