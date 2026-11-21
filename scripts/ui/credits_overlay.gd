extends Control
class_name CreditsOverlayUI
## Joyful, minimalist editorial Credits overlay for Solstice Spire.
## Supports both Start Screen modal mode (backdrop alpha 0.78) and Summit Sanctuary
## orbital glide mode (backdrop alpha 0.48 so 3D Summit Sanctuary & fireworks shine behind it).

signal closed()

var _backdrop: ColorRect
var _clip_frame: Control
var _scroll_vbox: VBoxContainer
var _close_btn: Button
var _scroll_y: float = 0.0
var _scroll_speed: float = 34.0
var _as_summit_glide: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.04, 0.035, 0.055, 0.78)
	add_child(_backdrop)

	# Soft central radial scrim for crisp typography contrast even over bright summit fireworks
	var scrim := UITheme.make_radial_scrim(Vector2(900, 740), Vector2(0.5, 0.5), 0.44, Color(0.04, 0.03, 0.06))
	scrim.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	scrim.offset_left = -450
	scrim.offset_right = 450
	scrim.offset_top = -370
	scrim.offset_bottom = 370
	add_child(scrim)

	_clip_frame = Control.new()
	_clip_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clip_frame.offset_top = 48
	_clip_frame.offset_bottom = -96
	_clip_frame.clip_contents = true
	_clip_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip_frame)

	_scroll_vbox = VBoxContainer.new()
	_scroll_vbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_scroll_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_scroll_vbox.add_theme_constant_override("separation", 24)
	_scroll_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_frame.add_child(_scroll_vbox)

	# Hero Title Block
	var hero := VBoxContainer.new()
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.add_theme_constant_override("separation", 6)
	_scroll_vbox.add_child(hero)

	var eyebrow := Label.new()
	eyebrow.text = "A Vertical Ascent Across Six Surreal Realms · 0m → 1,085m"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(eyebrow, "semibold", 14, UITheme.INK_EYEBROW, 0.36, 1)
	hero.add_child(eyebrow)

	var main_title := Label.new()
	main_title.text = "Solstice Spire"
	main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(main_title, "heavy", 54, UITheme.INK_PRIMARY, 0.38, 2)
	hero.add_child(main_title)

	var subtitle := Label.new()
	subtitle.text = "✦  Above the Cloud Sea  ✦"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(subtitle, "bold", 15, UITheme.ACCENT_AMBER, 0.34, 1)
	hero.add_child(subtitle)

	_add_credit_section(
		"Direction & Design",
		"Solstice Spire Studio",
		"Vertical Parkour Architecture · Tactile Toybox-Dreamcore Direction · Kinetic Flow Systems"
	)

	_add_credit_section(
		"The Six Ascending Realms",
		"I · The Sunken Conservatory     II · Foundry of Floating Bells\nIII · The Origami Monsoon     IV · The Shattered Mirror Gallery\nV · The Cloud-Whale Library     VI · The Crown of the Sun",
		"Seamless 1,085m Continuous World Streaming & Altitude Atmosphere"
	)

	_add_credit_section(
		"Explorers: Pip · Koko · Vesper",
		"Pip — The Lantern Pilgrim  (Ember Grace)\nKoko — The Clockwork Fox  (Clockwork Surge)\nVesper — The Origami Moth  (Origami Flutter)",
		"Sculpted Plush Felt, Porcelain-Brass & Washi-Paper Character Rigs"
	)

	_add_credit_section(
		"Original Adaptive Score & Living Soundscape",
		"Six-Realm Vertical Harmonic Stems & Dynamic Flow Swells",
		"Pentatonic Bronze Bells · Biome Wind Beds · Expressive Explorer Chirps"
	)

	_add_credit_section(
		"Built with Godot 4.7 & Blender",
		"Forward+ Custom Triplanar Shaders · Procedural Blender 3D Pipeline\nMac Keyboard · PS5 DualSense · Xbox · Switch Pro · iPhone 15 Web Deck",
		"OFL Nunito Typography · 60fps Apple Silicon & Desktop Optimization"
	)

	var finale_box := VBoxContainer.new()
	finale_box.alignment = BoxContainer.ALIGNMENT_CENTER
	finale_box.add_theme_constant_override("separation", 8)
	_scroll_vbox.add_child(finale_box)

	var ornament := Label.new()
	ornament.text = "✦   👑   ✦"
	ornament.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(ornament, "heavy", 22, UITheme.ACCENT_AMBER, 0.36, 1)
	finale_box.add_child(ornament)

	var thanks := Label.new()
	thanks.text = "Thank You for Climbing Above the Clouds"
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(thanks, "heavy", 28, UITheme.INK_PRIMARY, 0.38, 2)
	finale_box.add_child(thanks)

	var blessing := Label.new()
	blessing.text = "May the Solstice winds carry you skyward."
	blessing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(blessing, "semibold", 15, UITheme.INK_SECONDARY, 0.34, 1)
	finale_box.add_child(blessing)

	# Bottom centered Close / Skip button
	var bot_center := CenterContainer.new()
	bot_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot_center.offset_top = -80
	bot_center.offset_bottom = -24
	add_child(bot_center)

	_close_btn = Button.new()
	_close_btn.text = "Close / Skip  ·  Esc"
	_close_btn.custom_minimum_size = Vector2(236, 46)
	UITheme.style_secondary_pill(_close_btn, true, 15)
	_close_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		close_credits()
	)
	bot_center.add_child(_close_btn)


func _add_credit_section(heading_text: String, primary_text: String, detail_text: String) -> void:
	var sec := VBoxContainer.new()
	sec.alignment = BoxContainer.ALIGNMENT_CENTER
	sec.add_theme_constant_override("separation", 4)
	_scroll_vbox.add_child(sec)

	var h := Label.new()
	h.text = heading_text
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(h, "extrabold", 14, UITheme.ACCENT_AMBER, 0.34, 1)
	sec.add_child(h)

	var p := Label.new()
	p.text = primary_text
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(p, "bold", 18, UITheme.INK_PRIMARY, 0.36, 2)
	sec.add_child(p)

	if not detail_text.is_empty():
		var d := Label.new()
		d.text = detail_text
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UITheme.apply_font(d, "semibold", 13, UITheme.INK_SECONDARY, 0.32, 1)
		sec.add_child(d)


func open_credits(as_summit_glide: bool = false) -> void:
	_as_summit_glide = as_summit_glide
	var target_alpha := 0.48 if as_summit_glide else 0.78
	_backdrop.color = Color(0.04, 0.035, 0.055, target_alpha)
	visible = true
	modulate.a = 0.0
	var view_h := size.y if size.y > 100.0 else 900.0
	_scroll_y = view_h * 0.28
	_scroll_vbox.position.y = _scroll_y
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func close_credits() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_scroll_y -= _scroll_speed * delta
	var content_h := maxf(_scroll_vbox.size.y, 760.0)
	var frame_h := maxf(_clip_frame.size.y, 720.0)
	if _scroll_y < -content_h - 40.0:
		_scroll_y = frame_h * 0.65
	_scroll_vbox.position.y = _scroll_y


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		AudioDirector.play_sfx("ui_click", -2.0, 1.05)
		close_credits()
		get_viewport().set_input_as_handled()
