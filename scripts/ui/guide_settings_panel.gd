extends Control
class_name GuideSettingsPanelUI
## Start-Screen "Guide & Settings" Modal matching the warm-walnut, cream-pill,
## amber-slider AAA design craft of PauseMenuUI, with Realm Direct-Launch (with progressive unlock state),
## complete updated Guide & Controls, 2x2 Look Sensitivity / Camera FOV / Music Volume / SFX Volume sliders,
## Graphics Quality (Low/Med/High), VSync, Fullscreen, Invert Y & Golden Crown toggles,
## 3-Mode Controller Selector (Keyboard / Controller PS5·Xbox·Switch Pro / iPhone Deck), and Credits launcher.

signal closed()
signal world_launch_requested(world_idx: int)
signal credits_requested()

const PairingPanelScript = preload("res://scripts/ui/phone_pairing_panel.gd")

var _card: PanelContainer
var _realm_section_lbl: Label
var _world_buttons: Array[Button] = []

var _kb_btn: Button
var _gp_btn: Button
var _phone_btn: Button
var _gp_style_row: HBoxContainer
var _style_ps5_btn: Button
var _style_xbox_btn: Button
var _style_switch_btn: Button

var _sens_slider: HSlider
var _fov_slider: HSlider
var _mus_slider: HSlider
var _sfx_slider: HSlider
var _sens_val_lbl: Label
var _fov_val_lbl: Label
var _mus_val_lbl: Label
var _sfx_val_lbl: Label

var _qual_low_btn: Button
var _qual_med_btn: Button
var _qual_high_btn: Button
var _vsync_btn: Button
var _fullscreen_btn: Button
var _invert_y_btn: Button
var _crown_btn: Button

var _syncing_ui: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_modal()
	InputManager.input_mode_changed.connect(func(_m: String): _refresh_ctrl_mode_buttons())
	InputManager.gamepad_changed.connect(func(_c: bool, _n: String, _s: String): _refresh_ctrl_mode_buttons())
	PhoneController.mode_changed.connect(func(_u: bool): _refresh_ctrl_mode_buttons())
	PhoneController.connection_changed.connect(func(_c: bool, _n: int, _d: String): _refresh_ctrl_mode_buttons())
	GameState.world_unlocked.connect(func(_w: int): _refresh_world_buttons())
	GameState.game_mode_changed.connect(func(_m: String): _refresh_world_buttons())
	GameState.cosmetic_changed.connect(func(): _refresh_toggles())


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
	if _fov_slider:
		_fov_slider.value = GameState.camera_fov
		_fov_val_lbl.text = "%d°" % int(round(GameState.camera_fov))
	if _mus_slider:
		_mus_slider.value = GameState.music_volume
		_mus_val_lbl.text = "%d%%" % int(round(GameState.music_volume * 100.0))
	if _sfx_slider:
		_sfx_slider.value = GameState.sfx_volume
		_sfx_val_lbl.text = "%d%%" % int(round(GameState.sfx_volume * 100.0))
	_syncing_ui = false
	_refresh_world_buttons()
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
	_card.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_SOLID, Color(0.96, 0.86, 0.70, 0.28), 26, 24, 16, 1))
	center.add_child(_card)

	var outer_v := VBoxContainer.new()
	outer_v.add_theme_constant_override("separation", 8)
	_card.add_child(outer_v)

	# Header
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 0)
	outer_v.add_child(header)

	var eyebrow := Label.new()
	eyebrow.text = "Guide & Settings"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(eyebrow, "semibold", 12, UITheme.INK_SECONDARY)
	header.add_child(eyebrow)

	var h := Label.new()
	h.text = "Solstice Spire"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(h, "heavy", 26, UITheme.INK_PRIMARY)
	header.add_child(h)

	# 2-Column Body
	var body_cols := HBoxContainer.new()
	body_cols.add_theme_constant_override("separation", 18)
	outer_v.add_child(body_cols)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 7)
	body_cols.add_child(v)

	# Primary CTA
	var done_b := Button.new()
	done_b.text = "Done — Back to Explorers"
	done_b.custom_minimum_size = Vector2(0, 40)
	UITheme.style_primary_cta(done_b, 15)
	done_b.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		close_panel()
	)
	v.add_child(done_b)

	# Realm Direct Launch (2x3)
	_realm_section_lbl = Label.new()
	_realm_section_lbl.text = "Launch Directly Into Realm"
	UITheme.apply_font(_realm_section_lbl, "bold", 12, UITheme.INK_SECONDARY)
	v.add_child(_realm_section_lbl)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 5)
	v.add_child(grid)

	_world_buttons.clear()
	for w in GameState.WORLDS:
		var wb := Button.new()
		wb.custom_minimum_size = Vector2(0, 32)
		wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var wi: int = int(w["idx"])
		wb.pressed.connect(func(): _on_world_button_pressed(wi))
		grid.add_child(wb)
		_world_buttons.append(wb)

	# How to Play & Quick Controls
	var inst_lbl := Label.new()
	inst_lbl.text = "How to Play & Quick Controls"
	UITheme.apply_font(inst_lbl, "bold", 12, UITheme.INK_SECONDARY)
	v.add_child(inst_lbl)

	var inst_box := PanelContainer.new()
	inst_box.add_theme_stylebox_override("panel", UITheme.glass_box(Color(0.06, 0.05, 0.065, 0.68), UITheme.BORDER_SUBTLE, 14, 12, 8, 1))
	v.add_child(inst_box)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	inst_box.add_child(cols)

	var how_v := VBoxContainer.new()
	how_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	how_v.add_theme_constant_override("separation", 3)
	cols.add_child(how_v)

	var how_title := Label.new()
	how_title.text = "Gameplay Guide"
	UITheme.apply_font(how_title, "extrabold", 11, UITheme.INK_PRIMARY)
	how_v.add_child(how_title)

	var how_data := [
		["The Dying Sun:", "The Sun-Heart at 1,085m has cracked. Disembark The Dawnbreaker & rekindle dawn!"],
		["Sky Shrines:", "Touch glowing shrines to save. Fall below one? Press R within 30s to rewind!"],
		["Purist Mode:", "Only Up! Zero shrines & zero rewind — awards the Purist Legend badge & halo."],
		["Sky Focus (Slow-Mo):", "Chain hops & pads to fill Resonance — press Tab / V / L1 mid-air for 1.5s slow-mo!"],
		["Sky-Dive & Meteor:", "Hold C / ○ / B mid-air to Sky-Dive; slam a Bounce Pad for a Meteor Bounce!"],
		["Explorers:", "Pip (ledge grace) · Koko (snappy dash/slide) · Vesper (hold Jump to flutter)."],
	]
	for item in how_data:
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 6)
		how_v.add_child(hrow)

		var hk := Label.new()
		hk.text = item[0]
		hk.custom_minimum_size = Vector2(114, 0)
		UITheme.apply_font(hk, "bold", 10, UITheme.ACCENT_AMBER)
		hrow.add_child(hk)

		var hv := Label.new()
		hv.text = item[1]
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hv.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.apply_font(hv, "semibold", 10, UITheme.INK_PRIMARY)
		hrow.add_child(hv)

	var vsep := VSeparator.new()
	vsep.modulate = Color(0.96, 0.88, 0.72, 0.25)
	cols.add_child(vsep)

	var inst_v := VBoxContainer.new()
	inst_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inst_v.add_theme_constant_override("separation", 3)
	cols.add_child(inst_v)

	var ctrl_title := Label.new()
	ctrl_title.text = "Controls (Mac / Controller / iPhone Deck)"
	UITheme.apply_font(ctrl_title, "extrabold", 11, UITheme.INK_PRIMARY)
	inst_v.add_child(ctrl_title)

	var controls_data := [
		["Move / Camera:", "WASD + Mouse  ·  L-Stick (Edge Sprint) + R-Stick"],
		["Jump / Wall-Kick:", "Space  ·  ✕ / A / B or R1 (Vesper: Hold to Flutter)"],
		["Air-Dash / Orb:", "Shift / E / RMB  ·  □ / X / Y or R2 Trigger"],
		["Sky Focus (Slow-Mo):", "Tab / V / Mid-Click  ·  L1 / R3 (1.5s Mid-Air Slow-Mo)"],
		["Slide / Sky-Dive:", "C / Ctrl  ·  ○ / B / A or L2 (Hold mid-air to Dive)"],
		["Rewind / Menu:", "R (30s) · F (Fullscreen) · Esc  ·  △ / Y / X · Options"],
	]
	for item in controls_data:
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 6)
		inst_v.add_child(crow)

		var k_lbl := Label.new()
		k_lbl.text = item[0]
		k_lbl.custom_minimum_size = Vector2(120, 0)
		UITheme.apply_font(k_lbl, "bold", 10, UITheme.ACCENT_AMBER)
		crow.add_child(k_lbl)

		var v_lbl := Label.new()
		v_lbl.text = item[1]
		v_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.apply_font(v_lbl, "semibold", 10, UITheme.INK_PRIMARY)
		crow.add_child(v_lbl)

	# 2-Column Slider Grid: Look Sensitivity | Camera FOV / Music Volume | SFX Volume
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

	var sliders_grid := GridContainer.new()
	sliders_grid.columns = 2
	sliders_grid.add_theme_constant_override("h_separation", 18)
	sliders_grid.add_theme_constant_override("v_separation", 6)
	v.add_child(sliders_grid)

	# 1. Look Sensitivity
	var s_row := HBoxContainer.new()
	s_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_row.add_theme_constant_override("separation", 8)
	sliders_grid.add_child(s_row)
	var sl := Label.new()
	sl.text = "Look Sens"
	sl.custom_minimum_size = Vector2(88, 0)
	UITheme.apply_font(sl, "semibold", 12, UITheme.INK_SECONDARY)
	s_row.add_child(sl)
	_sens_slider = _make_styled_slider(0.0008, 0.0060, 0.0002, GameState.mouse_sensitivity, track_bg, track_fill)
	s_row.add_child(_sens_slider)
	_sens_val_lbl = _make_slider_val_label("%.1fx" % (GameState.mouse_sensitivity / 0.0024))
	s_row.add_child(_sens_val_lbl)
	_sens_slider.value_changed.connect(func(val: float):
		if _syncing_ui:
			return
		GameState.mouse_sensitivity = val
		_sens_val_lbl.text = "%.1fx" % (val / 0.0024)
		GameState.save_persistent_data()
	)

	# 2. Camera FOV (65° - 90°)
	var f_row := HBoxContainer.new()
	f_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f_row.add_theme_constant_override("separation", 8)
	sliders_grid.add_child(f_row)
	var fl := Label.new()
	fl.text = "Camera FOV"
	fl.custom_minimum_size = Vector2(88, 0)
	UITheme.apply_font(fl, "semibold", 12, UITheme.INK_SECONDARY)
	f_row.add_child(fl)
	_fov_slider = _make_styled_slider(65.0, 90.0, 1.0, GameState.camera_fov, track_bg, track_fill)
	f_row.add_child(_fov_slider)
	_fov_val_lbl = _make_slider_val_label("%d°" % int(round(GameState.camera_fov)))
	f_row.add_child(_fov_val_lbl)
	_fov_slider.value_changed.connect(func(val: float):
		if _syncing_ui:
			return
		GameState.set_camera_fov(val, true)
		_fov_val_lbl.text = "%d°" % int(round(val))
	)

	# 3. Music Volume
	var m_row := HBoxContainer.new()
	m_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_row.add_theme_constant_override("separation", 8)
	sliders_grid.add_child(m_row)
	var ml := Label.new()
	ml.text = "Music Vol"
	ml.custom_minimum_size = Vector2(88, 0)
	UITheme.apply_font(ml, "semibold", 12, UITheme.INK_SECONDARY)
	m_row.add_child(ml)
	_mus_slider = _make_styled_slider(0.0, 1.0, 0.05, GameState.music_volume, track_bg, track_fill)
	m_row.add_child(_mus_slider)
	_mus_val_lbl = _make_slider_val_label("%d%%" % int(round(GameState.music_volume * 100.0)))
	m_row.add_child(_mus_val_lbl)
	_mus_slider.value_changed.connect(func(val: float):
		if _syncing_ui:
			return
		AudioDirector.set_music_volume(val, true)
		_mus_val_lbl.text = "%d%%" % int(round(val * 100.0))
	)

	# 4. SFX Volume
	var x_row := HBoxContainer.new()
	x_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	x_row.add_theme_constant_override("separation", 8)
	sliders_grid.add_child(x_row)
	var xl := Label.new()
	xl.text = "SFX Vol"
	xl.custom_minimum_size = Vector2(88, 0)
	UITheme.apply_font(xl, "semibold", 12, UITheme.INK_SECONDARY)
	x_row.add_child(xl)
	_sfx_slider = _make_styled_slider(0.0, 1.0, 0.05, GameState.sfx_volume, track_bg, track_fill)
	x_row.add_child(_sfx_slider)
	_sfx_val_lbl = _make_slider_val_label("%d%%" % int(round(GameState.sfx_volume * 100.0)))
	x_row.add_child(_sfx_val_lbl)
	_sfx_slider.value_changed.connect(func(val: float):
		if _syncing_ui:
			return
		AudioDirector.set_sfx_volume(val, true)
		_sfx_val_lbl.text = "%d%%" % int(round(val * 100.0))
	)

	# Graphics Quality (Low / Med / High) + VSync Row
	var gfx_row := HBoxContainer.new()
	gfx_row.add_theme_constant_override("separation", 8)
	v.add_child(gfx_row)

	var gfx_lbl := Label.new()
	gfx_lbl.text = "Graphics"
	gfx_lbl.custom_minimum_size = Vector2(72, 0)
	UITheme.apply_font(gfx_lbl, "semibold", 12, UITheme.INK_SECONDARY)
	gfx_row.add_child(gfx_lbl)

	_qual_low_btn = Button.new()
	_qual_low_btn.text = "Low"
	_qual_low_btn.custom_minimum_size = Vector2(0, 32)
	_qual_low_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_qual_low_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.0)
		GameState.set_graphics_quality("low", true)
		_refresh_toggles()
	)
	gfx_row.add_child(_qual_low_btn)

	_qual_med_btn = Button.new()
	_qual_med_btn.text = "Med"
	_qual_med_btn.custom_minimum_size = Vector2(0, 32)
	_qual_med_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_qual_med_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		GameState.set_graphics_quality("medium", true)
		_refresh_toggles()
	)
	gfx_row.add_child(_qual_med_btn)

	_qual_high_btn = Button.new()
	_qual_high_btn.text = "High"
	_qual_high_btn.custom_minimum_size = Vector2(0, 32)
	_qual_high_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_qual_high_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.1)
		GameState.set_graphics_quality("high", true)
		_refresh_toggles()
	)
	gfx_row.add_child(_qual_high_btn)

	_vsync_btn = Button.new()
	_vsync_btn.custom_minimum_size = Vector2(124, 32)
	_vsync_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		GameState.set_vsync_enabled(not GameState.vsync_enabled, true)
		_refresh_toggles()
	)
	gfx_row.add_child(_vsync_btn)

	# Fullscreen & Invert Camera Y & Optional Golden Crown Toggles Row
	var toggle_row := HBoxContainer.new()
	toggle_row.add_theme_constant_override("separation", 8)
	v.add_child(toggle_row)

	_fullscreen_btn = Button.new()
	_fullscreen_btn.custom_minimum_size = Vector2(0, 32)
	_fullscreen_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fullscreen_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		_toggle_fullscreen()
	)
	toggle_row.add_child(_fullscreen_btn)

	_invert_y_btn = Button.new()
	_invert_y_btn.custom_minimum_size = Vector2(0, 32)
	_invert_y_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_invert_y_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		GameState.invert_y = not GameState.invert_y
		GameState.save_persistent_data()
		_refresh_toggles()
	)
	toggle_row.add_child(_invert_y_btn)

	_crown_btn = Button.new()
	_crown_btn.custom_minimum_size = Vector2(0, 32)
	_crown_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crown_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.12)
		GameState.set_crown_equipped(not GameState.crown_equipped)
		_refresh_toggles()
	)
	toggle_row.add_child(_crown_btn)

	# Footer Row: Close + Credits + Quit Game
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	v.add_child(foot)

	var close_b := Button.new()
	close_b.text = "Close"
	close_b.custom_minimum_size = Vector2(0, 38)
	close_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_secondary_pill(close_b, false, 13)
	close_b.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		close_panel()
	)
	foot.add_child(close_b)

	var credits_b := Button.new()
	credits_b.text = "Credits"
	credits_b.custom_minimum_size = Vector2(138, 38)
	UITheme.style_secondary_pill(credits_b, false, 13)
	credits_b.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.08)
		credits_requested.emit()
	)
	foot.add_child(credits_b)

	var quit_b := Button.new()
	quit_b.text = "Quit Game"
	quit_b.custom_minimum_size = Vector2(132, 38)
	UITheme.style_secondary_pill(quit_b, false, 13)
	quit_b.pressed.connect(func(): get_tree().quit())
	foot.add_child(quit_b)

	# Right Column: 3-Button Controller Mode Selector + PS5/Xbox/Switch Pro Selector + Live QR Pairing Panel
	var right_v := VBoxContainer.new()
	right_v.custom_minimum_size = Vector2(296, 0)
	right_v.add_theme_constant_override("separation", 8)
	body_cols.add_child(right_v)

	var ctrl_mode_lbl := Label.new()
	ctrl_mode_lbl.text = "Controller Mode"
	UITheme.apply_font(ctrl_mode_lbl, "bold", 12, UITheme.INK_SECONDARY)
	right_v.add_child(ctrl_mode_lbl)

	var ctrl_mode_row := HBoxContainer.new()
	ctrl_mode_row.add_theme_constant_override("separation", 6)
	right_v.add_child(ctrl_mode_row)

	_kb_btn = Button.new()
	_kb_btn.text = "Keyboard"
	_kb_btn.custom_minimum_size = Vector2(0, 34)
	_kb_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kb_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.0)
		InputManager.set_input_mode("keyboard", true)
	)
	ctrl_mode_row.add_child(_kb_btn)

	_gp_btn = Button.new()
	_gp_btn.text = "Controller"
	_gp_btn.custom_minimum_size = Vector2(0, 34)
	_gp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gp_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.08)
		InputManager.set_input_mode("gamepad", true)
	)
	ctrl_mode_row.add_child(_gp_btn)

	_phone_btn = Button.new()
	_phone_btn.text = "iPhone Deck"
	_phone_btn.custom_minimum_size = Vector2(0, 34)
	_phone_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_phone_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.15)
		InputManager.set_input_mode("phone", true)
	)
	ctrl_mode_row.add_child(_phone_btn)

	# Compact PS5 / Xbox / Switch Pro style selector row
	_gp_style_row = HBoxContainer.new()
	_gp_style_row.add_theme_constant_override("separation", 6)
	right_v.add_child(_gp_style_row)

	_style_ps5_btn = Button.new()
	_style_ps5_btn.text = "PS5"
	_style_ps5_btn.custom_minimum_size = Vector2(0, 28)
	_style_ps5_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_ps5_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.06)
		InputManager.set_gamepad_style("ps5", true)
	)
	_gp_style_row.add_child(_style_ps5_btn)

	_style_xbox_btn = Button.new()
	_style_xbox_btn.text = "Xbox"
	_style_xbox_btn.custom_minimum_size = Vector2(0, 28)
	_style_xbox_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_xbox_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.06)
		InputManager.set_gamepad_style("xbox", true)
	)
	_gp_style_row.add_child(_style_xbox_btn)

	_style_switch_btn = Button.new()
	_style_switch_btn.text = "Switch Pro"
	_style_switch_btn.custom_minimum_size = Vector2(0, 28)
	_style_switch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_switch_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.06)
		InputManager.set_gamepad_style("switch", true)
	)
	_gp_style_row.add_child(_style_switch_btn)

	var qr_panel := PairingPanelScript.new(true)
	qr_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_v.add_child(qr_panel)

	_refresh_world_buttons()
	_refresh_toggles()
	_refresh_ctrl_mode_buttons()


func _make_styled_slider(min_v: float, max_v: float, step_v: float, init_v: float,
		track_bg: StyleBoxFlat, track_fill: StyleBoxFlat) -> HSlider:
	var sl := HSlider.new()
	sl.focus_mode = Control.FOCUS_NONE
	sl.min_value = min_v
	sl.max_value = max_v
	sl.step = step_v
	sl.value = init_v
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.add_theme_stylebox_override("slider", track_bg)
	sl.add_theme_stylebox_override("grabber_area", track_fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", track_fill)
	return sl


func _make_slider_val_label(init_txt: String) -> Label:
	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(42, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.text = init_txt
	UITheme.apply_font(lbl, "bold", 12, UITheme.INK_PRIMARY)
	return lbl


func _refresh_world_buttons() -> void:
	if _world_buttons.is_empty():
		return
	var is_purist := GameState.is_purist_mode()
	if _realm_section_lbl:
		if is_purist:
			_realm_section_lbl.text = "🔒 Fast-Travel Disabled in Purist Mode (Start at 0m)"
		else:
			_realm_section_lbl.text = "Launch Directly Into Realm"

	for i in range(mini(_world_buttons.size(), GameState.WORLDS.size())):
		var wb: Button = _world_buttons[i]
		var w: Dictionary = GameState.WORLDS[i]
		var wi: int = int(w["idx"])
		var short_name := str(w["name"]).replace("The ", "")
		var unlocked := GameState.is_world_unlocked(wi)
		if is_purist and wi > 0:
			wb.text = "🔒 %d. %s (Purist Mode)" % [wi + 1, short_name]
			wb.disabled = true
			UITheme.style_secondary_pill(wb, false, 12)
		elif unlocked:
			wb.text = "%d. %s" % [wi + 1, short_name]
			wb.disabled = false
			wb.tooltip_text = "Launch directly into %s" % str(w["name"])
			UITheme.style_secondary_pill(wb, false, 12)
		else:
			wb.text = "🔒 %d. %s (Reach %dm)" % [wi + 1, short_name, int(w["y_min"])]
			wb.disabled = false
			wb.tooltip_text = "Reach %dm during an ascent to unlock %s!" % [int(w["y_min"]), str(w["name"])]
			UITheme.style_secondary_pill(wb, false, 12)


func _on_world_button_pressed(wi: int) -> void:
	var w: Dictionary = GameState.WORLDS[clampi(wi, 0, GameState.WORLDS.size() - 1)]
	if GameState.is_purist_mode() and wi > 0:
		AudioDirector.play_sfx("ui_click", -4.0, 0.65)
		if _realm_section_lbl:
			_realm_section_lbl.text = "🔒 Fast-Travel Disabled in Purist Mode — Switch to Pilgrim Mode!"
		return
	if not GameState.is_world_unlocked(wi):
		AudioDirector.play_sfx("ui_click", -4.0, 0.65)
		var req_m := int(w["y_min"])
		if _realm_section_lbl:
			_realm_section_lbl.text = "🔒 Locked — Climb to %dm to unlock %s!" % [req_m, str(w["name"])]
		GameState.emit_callout("REALM LOCKED", "Reach %dm to unlock %s" % [req_m, str(w["name"])], Color(1.0, 0.68, 0.32))
		return
	AudioDirector.play_sfx("portal_warp", -3.0, 1.1)
	world_launch_requested.emit(wi)


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
	var q := GameState.graphics_quality
	if _qual_low_btn:
		UITheme.style_secondary_pill(_qual_low_btn, q == "low", 12)
	if _qual_med_btn:
		UITheme.style_secondary_pill(_qual_med_btn, q == "medium", 12)
	if _qual_high_btn:
		UITheme.style_secondary_pill(_qual_high_btn, q == "high", 12)
	if _vsync_btn:
		var vs_on := GameState.vsync_enabled
		_vsync_btn.text = "VSync: On" if vs_on else "VSync: Off"
		UITheme.style_secondary_pill(_vsync_btn, vs_on, 12)
	if _fullscreen_btn:
		var fs_on := _is_fullscreen()
		_fullscreen_btn.text = "Fullscreen: On" if fs_on else "Fullscreen: Off"
		UITheme.style_secondary_pill(_fullscreen_btn, fs_on, 12)
	if _invert_y_btn:
		var inv_on := GameState.invert_y
		_invert_y_btn.text = "Invert Camera Y: On" if inv_on else "Invert Camera Y: Off"
		UITheme.style_secondary_pill(_invert_y_btn, inv_on, 12)
	if _crown_btn:
		_crown_btn.visible = GameState.crown_unlocked
		if GameState.crown_unlocked:
			var cr_on := GameState.crown_equipped
			_crown_btn.text = "👑 Golden Crown: On" if cr_on else "👑 Golden Crown: Off"
			UITheme.style_secondary_pill(_crown_btn, cr_on, 12)


func _refresh_ctrl_mode_buttons() -> void:
	if _kb_btn == null or _gp_btn == null or _phone_btn == null:
		return
	var cur := InputManager.input_mode
	UITheme.style_secondary_pill(_kb_btn, cur == "keyboard", 12)
	UITheme.style_secondary_pill(_gp_btn, cur == "gamepad", 12)
	UITheme.style_secondary_pill(_phone_btn, cur == "phone", 12)

	if _gp_style_row:
		_gp_style_row.visible = (cur == "gamepad" or InputManager.gamepad_connected)
		var st := InputManager.gamepad_style
		UITheme.style_secondary_pill(_style_ps5_btn, st == "ps5", 11)
		UITheme.style_secondary_pill(_style_xbox_btn, st == "xbox", 11)
		UITheme.style_secondary_pill(_style_switch_btn, st == "switch", 11)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		AudioDirector.play_sfx("ui_click")
		close_panel()
		get_viewport().set_input_as_handled()
