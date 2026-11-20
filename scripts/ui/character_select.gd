extends Control
class_name CharacterSelectUI
## Airy, Tactile Title & Live 3D Character Select Overlay.
## Uses OFL Nunito typography, soft left-side radial scrim (zero harsh outlines!),
## warm cream selected chip vs sole honey-amber primary CTA, leaving 85%+ of the diorama unobstructed!

signal character_highlighted(char_id: String)
signal ascent_started()

const ORDER := ["pip", "koko", "vesper"]

var _card_buttons: Dictionary = {}
var _name_label: Label
var _title_label: Label
var _tagline_label: Label
var _hero_block: VBoxContainer
var _bottom_dock: VBoxContainer
var _selected_id: String = "pip"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_select_character(GameState.selected_character, false)


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

	# BOTTOM AIRY FLOATING SELECTOR DOCK
	_bottom_dock = VBoxContainer.new()
	_bottom_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_dock.offset_left = 180
	_bottom_dock.offset_right = -180
	_bottom_dock.offset_top = -172
	_bottom_dock.offset_bottom = -28
	_bottom_dock.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_dock.add_theme_constant_override("separation", 12)
	add_child(_bottom_dock)

	# Sleek floating explorer caption pill
	var caption_center := CenterContainer.new()
	_bottom_dock.add_child(caption_center)

	var caption_pill := PanelContainer.new()
	caption_pill.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_GLASS, UITheme.BORDER_SUBTLE, 999, 24, 9, 1))
	caption_center.add_child(caption_pill)

	var cap_row := HBoxContainer.new()
	cap_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cap_row.add_theme_constant_override("separation", 10)
	caption_pill.add_child(cap_row)

	_name_label = Label.new()
	UITheme.apply_font(_name_label, "heavy", 19, UITheme.INK_PRIMARY)
	cap_row.add_child(_name_label)

	_title_label = Label.new()
	UITheme.apply_font(_title_label, "bold", 15, UITheme.ACCENT_AMBER)
	cap_row.add_child(_title_label)

	_tagline_label = Label.new()
	UITheme.apply_font(_tagline_label, "medium", 14, UITheme.INK_SECONDARY)
	cap_row.add_child(_tagline_label)

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
	UITheme.animate_enter(_bottom_dock, 0.06, 0.24)


func _select_character(cid: String, play_sound: bool) -> void:
	_selected_id = cid
	if GameState.selected_character != cid:
		GameState.set_character(cid)
	var info: Dictionary = GameState.CHARACTERS[cid]
	_name_label.text = info["name"]
	_title_label.text = info["title"]
	_tagline_label.text = info["tagline"]

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
	if not visible:
		return
	if event.is_action_pressed("character_1"):
		_select_character("pip", true)
	elif event.is_action_pressed("character_2"):
		_select_character("koko", true)
	elif event.is_action_pressed("character_3"):
		_select_character("vesper", true)
	elif event.is_action_pressed("ui_accept"):
		_on_begin_pressed()
