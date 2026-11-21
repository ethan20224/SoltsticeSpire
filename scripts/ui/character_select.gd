extends Control
class_name CharacterSelectUI
## Airy, Tactile Title & Live 3D Character Select Overlay.
## Uses OFL Nunito typography, soft left-side radial scrim (zero harsh outlines!),
## warm cream selected chip vs sole honey-amber primary CTA, leaving 85%+ of the diorama unobstructed!
## Includes top-right 3-Mode Controller Selector (Mac Keyboard, Physical Controller PS5/Xbox/Switch Pro,
## and iPhone 15 DualSense QR Deck) plus bottom Ascent Mode Toggle Pill (Pilgrim vs Purist Mode).

signal character_highlighted(char_id: String)
signal ascent_started()
signal guide_settings_requested()

const ORDER := ["pip", "koko", "vesper"]
const STYLE_CYCLE := ["ps5", "xbox", "switch"]
const PairingPanelScript = preload("res://scripts/ui/phone_pairing_panel.gd")

var input_blocked: bool = false

var _card_buttons: Dictionary = {}
var _name_label: Label
var _title_label: Label
var _tagline_label: Label
var _perk_label: Label
var _hero_block: VBoxContainer
var _bottom_dock: VBoxContainer
var _ctrl_dock: VBoxContainer
var _guide_btn: Button
var _kb_mode_btn: Button
var _gamepad_mode_btn: Button
var _gamepad_style_btn: Button
var _phone_mode_btn: Button
var _pairing_panel: PanelContainer
var _pilgrim_btn: Button
var _purist_btn: Button
var _mode_caption_label: Label
var _selected_id: String = "pip"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_select_character(GameState.selected_character, false)
	_refresh_ascent_mode_ui()
	GameState.character_changed.connect(func(cid: String):
		if cid != _selected_id:
			_select_character(cid, true)
	)
	GameState.game_mode_changed.connect(func(_m: String):
		_refresh_ascent_mode_ui()
	)
	InputManager.input_mode_changed.connect(_on_input_mode_changed)
	InputManager.gamepad_changed.connect(func(_c: bool, _n: String, _s: String):
		_refresh_controller_mode_buttons()
	)
	InputManager.ui_nav_pressed.connect(_on_ui_nav_pressed)
	InputManager.ui_confirm_pressed.connect(_on_ui_confirm_pressed)
	PhoneController.mode_changed.connect(_on_phone_mode_changed)
	PhoneController.connection_changed.connect(func(_c: bool, _cnt: int, _dev: String):
		_refresh_controller_mode_buttons()
	)
	PhoneController.remote_begin_ascent.connect(func():
		if visible and not input_blocked:
			_on_begin_pressed()
	)


func _build_ui() -> void:
	# Soft left-side radial vignette scrim behind full title + subtitle lockup for >8:1 contrast against bright morning sky!
	var scrim := UITheme.make_radial_scrim(Vector2(620, 260), Vector2(0.35, 0.40), 0.68, Color(0.04, 0.03, 0.06))
	scrim.position = Vector2(0, 0)
	add_child(scrim)

	# TOP-LEFT EDITORIAL TITLE LOCKUP (weight/color hierarchy, sentence-case eyebrow, zero harsh outline!)
	_hero_block = VBoxContainer.new()
	_hero_block.position = Vector2(46, 36)
	_hero_block.add_theme_constant_override("separation", 4)
	add_child(_hero_block)

	var eyebrow := Label.new()
	eyebrow.text = "Six ascending realms · 1,085m"
	UITheme.apply_font(eyebrow, "semibold", 13, UITheme.INK_SECONDARY, 0.34, 1)
	_hero_block.add_child(eyebrow)

	var logo := Label.new()
	logo.text = "Solstice Spire"
	UITheme.apply_font(logo, "heavy", 58, UITheme.INK_PRIMARY, 0.36, 2)
	_hero_block.add_child(logo)

	var lead := Label.new()
	lead.text = "Choose your explorer and climb above the clouds."
	UITheme.apply_font(lead, "semibold", 18, UITheme.INK_PRIMARY, 0.38, 2)
	_hero_block.add_child(lead)

	# TOP-RIGHT GUIDE & SETTINGS + 3-MODE CONTROLLER SELECTOR + EXPANDABLE IPHONE QR PAIRING CARD
	_ctrl_dock = VBoxContainer.new()
	_ctrl_dock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_ctrl_dock.offset_left = -880
	_ctrl_dock.offset_right = -42
	_ctrl_dock.offset_top = 34
	_ctrl_dock.offset_bottom = 520
	_ctrl_dock.add_theme_constant_override("separation", 10)
	_ctrl_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ctrl_dock)

	var top_bar := HBoxContainer.new()
	top_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_bar.alignment = BoxContainer.ALIGNMENT_END
	top_bar.add_theme_constant_override("separation", 10)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ctrl_dock.add_child(top_bar)

	_guide_btn = Button.new()
	_guide_btn.text = "Guide & Settings"
	_guide_btn.custom_minimum_size = Vector2(162, 50)
	UITheme.style_secondary_pill(_guide_btn, false, 14)
	_guide_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		guide_settings_requested.emit()
	)
	top_bar.add_child(_guide_btn)

	var mode_pill := PanelContainer.new()
	mode_pill.size_flags_horizontal = Control.SIZE_SHRINK_END
	mode_pill.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_GLASS, UITheme.BORDER_SUBTLE, 999, 14, 8, 1))
	top_bar.add_child(mode_pill)

	var mode_row := HBoxContainer.new()
	mode_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_row.add_theme_constant_override("separation", 6)
	mode_pill.add_child(mode_row)

	var mode_lbl := Label.new()
	mode_lbl.text = "Controls"
	UITheme.apply_font(mode_lbl, "bold", 12, UITheme.INK_SECONDARY)
	mode_row.add_child(mode_lbl)

	_kb_mode_btn = Button.new()
	_kb_mode_btn.text = "Mac Keyboard"
	_kb_mode_btn.custom_minimum_size = Vector2(118, 34)
	_kb_mode_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.0)
		InputManager.set_input_mode("keyboard", true)
	)
	mode_row.add_child(_kb_mode_btn)

	_gamepad_mode_btn = Button.new()
	_gamepad_mode_btn.text = "Controller"
	_gamepad_mode_btn.custom_minimum_size = Vector2(126, 34)
	_gamepad_mode_btn.tooltip_text = "Select Controller mode (click again to cycle PS5 · Xbox · Switch Pro glyphs)"
	_gamepad_mode_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.08)
		if InputManager.input_mode != "gamepad":
			InputManager.set_input_mode("gamepad", true)
		else:
			_cycle_gamepad_style()
	)
	mode_row.add_child(_gamepad_mode_btn)

	_gamepad_style_btn = Button.new()
	_gamepad_style_btn.text = "PS5 · Xbox · Switch"
	_gamepad_style_btn.custom_minimum_size = Vector2(96, 34)
	_gamepad_style_btn.tooltip_text = "Cycle controller prompt style: PS5 → Xbox → Switch Pro"
	_gamepad_style_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.14)
		if InputManager.input_mode != "gamepad":
			InputManager.set_input_mode("gamepad", true)
		_cycle_gamepad_style()
	)
	mode_row.add_child(_gamepad_style_btn)

	_phone_mode_btn = Button.new()
	_phone_mode_btn.text = "iPhone Controller"
	_phone_mode_btn.custom_minimum_size = Vector2(138, 34)
	_phone_mode_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.15)
		if InputManager.input_mode == "phone" and _pairing_panel.visible:
			_pairing_panel.visible = false
			var fallback := "gamepad" if InputManager.gamepad_connected else "keyboard"
			InputManager.set_input_mode(fallback, true)
		else:
			InputManager.set_input_mode("phone", true)
			_pairing_panel.visible = true
			UITheme.animate_enter(_pairing_panel, 0.0, 0.22)
	)
	mode_row.add_child(_phone_mode_btn)

	_pairing_panel = PairingPanelScript.new(false)
	_pairing_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	_pairing_panel.custom_minimum_size = Vector2(310, 0)
	_pairing_panel.visible = (InputManager.input_mode == "phone" or PhoneController.use_phone_controller)
	_ctrl_dock.add_child(_pairing_panel)

	_refresh_controller_mode_buttons()

	# BOTTOM AIRY FLOATING SELECTOR DOCK
	_bottom_dock = VBoxContainer.new()
	_bottom_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_dock.offset_left = 120
	_bottom_dock.offset_right = -120
	_bottom_dock.offset_top = -236
	_bottom_dock.offset_bottom = -22
	_bottom_dock.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_dock.add_theme_constant_override("separation", 10)
	add_child(_bottom_dock)

	# Sleek floating explorer caption pill with signature perk chip
	var caption_center := CenterContainer.new()
	_bottom_dock.add_child(caption_center)

	var caption_pill := PanelContainer.new()
	caption_pill.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_GLASS, UITheme.BORDER_SUBTLE, 24, 24, 9, 1))
	caption_center.add_child(caption_pill)

	var cap_v := VBoxContainer.new()
	cap_v.alignment = BoxContainer.ALIGNMENT_CENTER
	cap_v.add_theme_constant_override("separation", 3)
	caption_pill.add_child(cap_v)

	var cap_row := HBoxContainer.new()
	cap_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cap_row.add_theme_constant_override("separation", 10)
	cap_v.add_child(cap_row)

	_name_label = Label.new()
	UITheme.apply_font(_name_label, "heavy", 19, UITheme.INK_PRIMARY)
	cap_row.add_child(_name_label)

	_title_label = Label.new()
	UITheme.apply_font(_title_label, "bold", 15, UITheme.ACCENT_AMBER)
	cap_row.add_child(_title_label)

	_tagline_label = Label.new()
	UITheme.apply_font(_tagline_label, "medium", 14, UITheme.INK_SECONDARY)
	cap_row.add_child(_tagline_label)

	_perk_label = Label.new()
	_perk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_perk_label, "bold", 13, UITheme.ACCENT_AMBER)
	cap_v.add_child(_perk_label)

	# Sleek Ascent Mode Toggle Pill Row (Pilgrim Mode vs Purist Mode)
	var mode_center := CenterContainer.new()
	_bottom_dock.add_child(mode_center)

	var ascent_pill := PanelContainer.new()
	ascent_pill.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_GLASS, UITheme.BORDER_SUBTLE, 999, 14, 5, 1))
	mode_center.add_child(ascent_pill)

	var ascent_row := HBoxContainer.new()
	ascent_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ascent_row.add_theme_constant_override("separation", 8)
	ascent_pill.add_child(ascent_row)

	_pilgrim_btn = Button.new()
	_pilgrim_btn.text = "✦ Pilgrim Mode"
	_pilgrim_btn.custom_minimum_size = Vector2(138, 32)
	_pilgrim_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.04)
		var next_mode := "purist" if GameState.game_mode == "pilgrim" else "pilgrim"
		GameState.set_game_mode(next_mode)
	)
	ascent_row.add_child(_pilgrim_btn)

	_purist_btn = Button.new()
	_purist_btn.text = "🔥 Purist Mode"
	_purist_btn.custom_minimum_size = Vector2(138, 32)
	_purist_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.12)
		var next_mode := "pilgrim" if GameState.game_mode == "purist" else "purist"
		GameState.set_game_mode(next_mode)
	)
	ascent_row.add_child(_purist_btn)

	_mode_caption_label = Label.new()
	_mode_caption_label.text = "Shrines + 30s Rewind"
	UITheme.apply_font(_mode_caption_label, "semibold", 12, UITheme.INK_SECONDARY)
	ascent_row.add_child(_mode_caption_label)

	# Floating Pill Row: Warm Cream Selected Explorer + Sole Honey-Amber Begin Ascent CTA
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_bottom_dock.add_child(row)

	for cid in ORDER:
		var cinfo: Dictionary = GameState.CHARACTERS[cid]
		var btn := Button.new()
		btn.text = cinfo["name"]
		btn.custom_minimum_size = Vector2(138, 50)
		btn.pressed.connect(func(): _select_character(cid, true))
		row.add_child(btn)
		_card_buttons[cid] = btn

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(12, 1)
	row.add_child(spacer)

	var start_btn := Button.new()
	start_btn.text = "Begin Ascent"
	start_btn.custom_minimum_size = Vector2(206, 52)
	UITheme.style_primary_cta(start_btn, 17)
	start_btn.pressed.connect(_on_begin_pressed)
	row.add_child(start_btn)


func play_intro_stagger() -> void:
	UITheme.animate_enter(_hero_block, 0.0, 0.24)
	UITheme.animate_enter(_ctrl_dock, 0.04, 0.24)
	UITheme.animate_enter(_bottom_dock, 0.08, 0.24)


func _cycle_gamepad_style() -> void:
	var cur := InputManager.gamepad_style
	var idx := STYLE_CYCLE.find(cur)
	var next_style: String = STYLE_CYCLE[(idx + 1) % STYLE_CYCLE.size()]
	InputManager.set_gamepad_style(next_style, true)
	_refresh_controller_mode_buttons()


func _on_input_mode_changed(mode: String) -> void:
	_refresh_controller_mode_buttons()
	if mode == "phone" and not _pairing_panel.visible:
		_pairing_panel.visible = true
		UITheme.animate_enter(_pairing_panel, 0.0, 0.22)
	elif mode != "phone":
		_pairing_panel.visible = false


func _on_phone_mode_changed(use_phone: bool) -> void:
	_refresh_controller_mode_buttons()
	if use_phone and not _pairing_panel.visible:
		_pairing_panel.visible = true
		UITheme.animate_enter(_pairing_panel, 0.0, 0.22)
	elif not use_phone:
		_pairing_panel.visible = false


func _get_gamepad_label(style: String, active_or_connected: bool) -> String:
	var prefix := "● " if active_or_connected else ""
	match style:
		"xbox":
			return "%sXbox Controller" % prefix
		"switch":
			return "%sSwitch Pro" % prefix
		_:
			return "%sPS5 Controller" % prefix


func _get_style_pill_text(style: String) -> String:
	match style:
		"xbox":
			return "Xbox · AXBY"
		"switch":
			return "Switch · BYAX"
		_:
			return "PS5 · ✕□○△"


func _refresh_controller_mode_buttons() -> void:
	if _kb_mode_btn == null or _gamepad_mode_btn == null or _phone_mode_btn == null:
		return
	var cur_mode := InputManager.input_mode
	var kb_active := (cur_mode == "keyboard")
	var gp_active := (cur_mode == "gamepad")
	var phone_active := (cur_mode == "phone")

	UITheme.style_secondary_pill(_kb_mode_btn, kb_active, 13)
	UITheme.style_secondary_pill(_gamepad_mode_btn, gp_active, 13)
	UITheme.style_secondary_pill(_phone_mode_btn, phone_active, 13)

	if gp_active or InputManager.gamepad_connected:
		_gamepad_mode_btn.text = _get_gamepad_label(InputManager.gamepad_style, true)
		_gamepad_style_btn.visible = true
		_gamepad_style_btn.text = _get_style_pill_text(InputManager.gamepad_style)
		UITheme.style_secondary_pill(_gamepad_style_btn, false, 12)
	else:
		_gamepad_mode_btn.text = "Controller"
		_gamepad_style_btn.visible = false

	if PhoneController.is_connected:
		_phone_mode_btn.text = "● iPhone Connected"
	else:
		_phone_mode_btn.text = "iPhone Controller"


func _refresh_ascent_mode_ui() -> void:
	if _pilgrim_btn == null or _purist_btn == null or _mode_caption_label == null:
		return
	var is_purist := GameState.is_purist_mode()
	UITheme.style_secondary_pill(_pilgrim_btn, not is_purist, 13)
	UITheme.style_secondary_pill(_purist_btn, is_purist, 13)
	if is_purist:
		_mode_caption_label.text = "Only Up! — Zero Shrines, Zero Rewind, Crown Prestige"
		_mode_caption_label.add_theme_color_override("font_color", UITheme.ACCENT_AMBER)
	else:
		_mode_caption_label.text = "Shrines + 30s Rewind"
		_mode_caption_label.add_theme_color_override("font_color", UITheme.INK_SECONDARY)


func _on_ui_nav_pressed(dir: int) -> void:
	if not visible or input_blocked:
		return
	var cur_idx := ORDER.find(_selected_id)
	if cur_idx < 0:
		cur_idx = 0
	var next_idx := (cur_idx + dir + ORDER.size()) % ORDER.size()
	_select_character(ORDER[next_idx], true)


func _on_ui_confirm_pressed() -> void:
	if not visible or input_blocked:
		return
	_on_begin_pressed()


func _select_character(cid: String, play_sound: bool) -> void:
	_selected_id = cid
	if GameState.selected_character != cid:
		GameState.set_character(cid)
	var info: Dictionary = GameState.CHARACTERS[cid]
	_name_label.text = info["name"]
	_title_label.text = info["title"]
	_tagline_label.text = info["tagline"]
	_perk_label.text = "✦ %s: %s" % [info["perk_title"], info["perk_desc"]]

	for k in ORDER:
		var btn: Button = _card_buttons[k]
		var active: bool = (str(k) == cid)
		UITheme.style_secondary_pill(btn, active, 16)

	if play_sound:
		var p_idx := ORDER.find(cid)
		AudioDirector.play_flow_chime(p_idx * 2, -3.0)
	character_highlighted.emit(cid)


func _on_begin_pressed() -> void:
	AudioDirector.play_sfx("checkpoint", -2.0, 1.05)
	ascent_started.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or input_blocked:
		return
	if event.is_action_pressed("character_1"):
		_select_character("pip", true)
	elif event.is_action_pressed("character_2"):
		_select_character("koko", true)
	elif event.is_action_pressed("character_3"):
		_select_character("vesper", true)
	elif event.is_action_pressed("ui_accept"):
		_on_begin_pressed()
