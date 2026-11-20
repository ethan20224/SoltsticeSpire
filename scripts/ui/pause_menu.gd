extends Control
class_name PauseMenuUI
## Tactile Warm-Walnut Pause Overlay with OFL Nunito typography, Live Explorer Swap,
## Realm Fast-Travel, iPhone 15 DualSense QR Pairing Dock, live Sensitivity/Volume sliders,
## and clean 200ms TRANS_EXPO reveal.

signal resume_requested()
signal world_teleport_requested(world_idx: int)
signal restart_requested()
signal title_requested()

const PairingPanelScript = preload("res://scripts/ui/phone_pairing_panel.gd")

var _card: PanelContainer
var _char_btns: Dictionary = {}
var _kb_btn: Button
var _phone_btn: Button
var _sens_val_lbl: Label
var _mus_val_lbl: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_menu()
	GameState.character_changed.connect(func(_c): _refresh_char_buttons())
	PhoneController.mode_changed.connect(func(_u): _refresh_ctrl_mode_buttons())
	PhoneController.connection_changed.connect(func(_c, _n, _d): _refresh_ctrl_mode_buttons())


func open_animated() -> void:
	visible = true
	_refresh_char_buttons()
	_refresh_ctrl_mode_buttons()
	UITheme.animate_enter(_card, 0.0, 0.20)


func _build_menu() -> void:
	# Elevated dim backdrop (0.58) so the pause card owns focus cleanly without noisy background bleed!
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.035, 0.055, 0.58)
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

	# Header: Clean tracked eyebrow (no pill clutter!) + Heavy Nunito Title
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 1)
	outer_v.add_child(header)

	var eyebrow := Label.new()
	eyebrow.text = "Paused"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(eyebrow, "semibold", 13, UITheme.INK_SECONDARY)
	header.add_child(eyebrow)

	var h := Label.new()
	h.text = "Solstice Spire"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(h, "heavy", 28, UITheme.INK_PRIMARY)
	header.add_child(h)

	# Main 2-Column Body: Left = Game & Realm Controls | Right = iPhone 15 DualSense QR Pairing Dock
	var body_cols := HBoxContainer.new()
	body_cols.add_theme_constant_override("separation", 20)
	outer_v.add_child(body_cols)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	body_cols.add_child(v)

	var resume_b := Button.new()
	resume_b.text = "Resume Ascent"
	resume_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_primary_cta(resume_b, 16)
	resume_b.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		resume_requested.emit()
	)
	v.add_child(resume_b)

	# Explorer Switcher (warm cream active chip vs sleek dark unselected!)
	var c_lbl := Label.new()
	c_lbl.text = "Switch Explorer"
	UITheme.apply_font(c_lbl, "bold", 13, UITheme.INK_SECONDARY)
	v.add_child(c_lbl)

	var c_row := HBoxContainer.new()
	c_row.add_theme_constant_override("separation", 10)
	v.add_child(c_row)
	for cid in ["pip", "koko", "vesper"]:
		var cb := Button.new()
		cb.text = GameState.CHARACTERS[cid]["name"]
		cb.custom_minimum_size = Vector2(0, 38)
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.pressed.connect(func():
			GameState.set_character(cid)
			AudioDirector.play_sfx("ui_click", -2.0, 1.1)
		)
		c_row.add_child(cb)
		_char_btns[cid] = cb
	_refresh_char_buttons()

	# Realm Fast-Travel (hover = border brighten only, zero stray highlight!)
	var w_lbl := Label.new()
	w_lbl.text = "Realm Fast-Travel"
	UITheme.apply_font(w_lbl, "bold", 13, UITheme.INK_SECONDARY)
	v.add_child(w_lbl)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for w in GameState.WORLDS:
		var wb := Button.new()
		wb.text = "%d. %s" % [w["idx"] + 1, w["name"].replace("The ", "")]
		wb.custom_minimum_size = Vector2(0, 36)
		wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_secondary_pill(wb, false, 13)
		var wi: int = w["idx"]
		wb.pressed.connect(func():
			AudioDirector.play_sfx("portal_warp", -3.0, 1.1)
			world_teleport_requested.emit(wi)
		)
		grid.add_child(wb)

	# Instructions & Quick Controls Panel (2-Column: How to Play + Quick Controls)
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

	# LEFT COLUMN: Gameplay Instructions (How to Play)
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
		["Sky Shrines:", "Touch glowing white-gold shrines to save your checkpoint."],
		["Sun-Shards:", "Collect 18 floating golden crystals (3 per realm)."],
		["Flow State:", "Chain jumps, pads & wall-kicks to build speed & music."],
		["Bounce & Orbs:", "Pads & cyan Spirit-Orbs (□ / R2 / RMB) refresh Air-Dash."],
		["Realms & Walls:", "Ride wind columns, leap Portal Frames & wall-run bells."],
	]
	for item in how_data:
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 6)
		how_v.add_child(hrow)

		var hk := Label.new()
		hk.text = item[0]
		hk.custom_minimum_size = Vector2(92, 0)
		UITheme.apply_font(hk, "bold", 11, UITheme.ACCENT_AMBER)
		hrow.add_child(hk)

		var hv := Label.new()
		hv.text = item[1]
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_font(hv, "semibold", 11, UITheme.INK_PRIMARY)
		hrow.add_child(hv)

	var vsep := VSeparator.new()
	vsep.modulate = Color(0.96, 0.88, 0.72, 0.25)
	cols.add_child(vsep)

	# RIGHT COLUMN: Quick Controls (Mac + iPhone DualSense)
	var inst_v := VBoxContainer.new()
	inst_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inst_v.add_theme_constant_override("separation", 4)
	cols.add_child(inst_v)

	var ctrl_title := Label.new()
	ctrl_title.text = "Controls (Mac / iPhone Deck)"
	UITheme.apply_font(ctrl_title, "extrabold", 12, UITheme.INK_PRIMARY)
	inst_v.add_child(ctrl_title)

	var controls_data := [
		["Move / Camera:", "WASD + Mouse  ·  L-Stick + R-Stick / Touchpad"],
		["Jump / Wall-Kick:", "Space  ·  ✕ Cross or R1 Bumper"],
		["Air-Dash / Orb:", "Shift / E / RMB  ·  □ Square or R2 Trigger"],
		["Slide / Long-Jump:", "C / Ctrl  ·  ○ Circle or L2 Trigger"],
		["Rewind to Shrine:", "R  ·  △ Triangle or Top Shrine Pill"],
		["Swap / Fullscreen:", "1-3 / F (Full Screen) / Esc  ·  Explorer Chips"],
	]
	for item in controls_data:
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 6)
		inst_v.add_child(crow)

		var k_lbl := Label.new()
		k_lbl.text = item[0]
		k_lbl.custom_minimum_size = Vector2(114, 0)
		UITheme.apply_font(k_lbl, "bold", 11, UITheme.ACCENT_AMBER)
		crow.add_child(k_lbl)

		var v_lbl := Label.new()
		v_lbl.text = item[1]
		v_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_font(v_lbl, "semibold", 11, UITheme.INK_PRIMARY)
		crow.add_child(v_lbl)

	# Sensitivity & Music Sliders WITH visible track grooves & right-aligned value readouts!
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
	var sens_slider := HSlider.new()
	sens_slider.focus_mode = Control.FOCUS_NONE
	sens_slider.min_value = 0.0008
	sens_slider.max_value = 0.0060
	sens_slider.step = 0.0002
	sens_slider.value = GameState.mouse_sensitivity
	sens_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sens_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sens_slider.add_theme_stylebox_override("slider", track_bg)
	sens_slider.add_theme_stylebox_override("grabber_area", track_fill)
	sens_slider.add_theme_stylebox_override("grabber_area_highlight", track_fill)
	s_row.add_child(sens_slider)
	_sens_val_lbl = Label.new()
	_sens_val_lbl.custom_minimum_size = Vector2(48, 0)
	_sens_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sens_val_lbl.text = "%.1fx" % (GameState.mouse_sensitivity / 0.0024)
	UITheme.apply_font(_sens_val_lbl, "bold", 13, UITheme.INK_PRIMARY)
	s_row.add_child(_sens_val_lbl)
	sens_slider.value_changed.connect(func(val: float):
		GameState.mouse_sensitivity = val
		_sens_val_lbl.text = "%.1fx" % (val / 0.0024)
	)

	var m_row := HBoxContainer.new()
	m_row.add_theme_constant_override("separation", 12)
	v.add_child(m_row)
	var ml := Label.new()
	ml.text = "Music Volume"
	ml.custom_minimum_size = Vector2(148, 0)
	UITheme.apply_font(ml, "semibold", 14, UITheme.INK_SECONDARY)
	m_row.add_child(ml)
	var mus_slider := HSlider.new()
	mus_slider.focus_mode = Control.FOCUS_NONE
	mus_slider.min_value = 0.0
	mus_slider.max_value = 1.0
	mus_slider.step = 0.05
	mus_slider.value = GameState.music_volume
	mus_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mus_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mus_slider.add_theme_stylebox_override("slider", track_bg)
	mus_slider.add_theme_stylebox_override("grabber_area", track_fill)
	mus_slider.add_theme_stylebox_override("grabber_area_highlight", track_fill)
	m_row.add_child(mus_slider)
	_mus_val_lbl = Label.new()
	_mus_val_lbl.custom_minimum_size = Vector2(48, 0)
	_mus_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mus_val_lbl.text = "%d%%" % int(round(GameState.music_volume * 100.0))
	UITheme.apply_font(_mus_val_lbl, "bold", 13, UITheme.INK_PRIMARY)
	m_row.add_child(_mus_val_lbl)
	mus_slider.value_changed.connect(func(val: float):
		GameState.music_volume = val
		_mus_val_lbl.text = "%d%%" % int(round(val * 100.0))
	)

	# Footer actions ("Restart Climb", "Change Explorer", "Quit Game")
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	v.add_child(foot)

	var rest_b := Button.new()
	rest_b.text = "Restart Climb"
	rest_b.custom_minimum_size = Vector2(0, 42)
	rest_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_secondary_pill(rest_b, false, 14)
	rest_b.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		restart_requested.emit()
	)
	foot.add_child(rest_b)

	var title_b := Button.new()
	title_b.text = "Change Explorer"
	title_b.custom_minimum_size = Vector2(0, 42)
	title_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_secondary_pill(title_b, false, 14)
	title_b.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		title_requested.emit()
	)
	foot.add_child(title_b)

	var quit_b := Button.new()
	quit_b.text = "Quit Game"
	quit_b.custom_minimum_size = Vector2(116, 42)
	UITheme.style_secondary_pill(quit_b, false, 14)
	quit_b.pressed.connect(func(): get_tree().quit())
	foot.add_child(quit_b)

	# RIGHT SIDE COLUMN: Controller Mode Selector + Live Scannable QR Pairing Panel
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


func _refresh_char_buttons() -> void:
	for cid in _char_btns:
		var cb: Button = _char_btns[cid]
		var active: bool = (str(cid) == GameState.selected_character)
		UITheme.style_secondary_pill(cb, active, 14)


func _refresh_ctrl_mode_buttons() -> void:
	if _kb_btn == null or _phone_btn == null:
		return
	var phone_on := PhoneController.use_phone_controller
	UITheme.style_secondary_pill(_kb_btn, not phone_on, 13)
	UITheme.style_secondary_pill(_phone_btn, phone_on, 13)
