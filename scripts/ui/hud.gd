extends Control
class_name GameHUD
## Clean, Tactile Indie HUD crafted with OFL Nunito typography & surgical visual restraint.
## Borderless centered Realm Arrival banner over a soft radial scrim (2.5s auto-fade),
## keycap bar auto-fading after 6.0s, crisp top-left readout without pill clutter, zero harsh outlines.

var _alt_label: Label
var _world_label: Label
var _alt_bar: ProgressBar
var _timer_label: Label
var _falls_label: Label
var _shards_label: Label
var _motes_label: Label

var _flow_container: VBoxContainer
var _flow_bar: ProgressBar
var _flow_fill_style: StyleBoxFlat
var _flow_label: Label
var _solar_charged: bool = false

var _toast_root: Control
var _toast_badge_label: Label
var _toast_title: Label
var _toast_sub: Label
var _toast_timer: float = 0.0

var _callout_center: CenterContainer
var _callout_pill: PanelContainer
var _callout_title: Label
var _callout_sub: Label
var _callout_tween: Tween

var _rewind_center: CenterContainer
var _rewind_pill: PanelContainer
var _rewind_label: Label
var _rewind_active: bool = false
var _rewind_rem: float = 0.0
var _rewind_pulse_t: float = 0.0
var _rewind_fade_tween: Tween

var _tether_reticle: PanelContainer
var _tether_label: Label
var _whisper_panel: PanelContainer
var _whisper_row: HBoxContainer
var _whisper_timer: float = 6.0

var player_ref: PlayerController


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	GameState.altitude_updated.connect(_on_altitude)
	GameState.world_entered.connect(_on_world_entered)
	GameState.flow_changed.connect(_on_flow)
	GameState.shard_collected.connect(_on_shards)
	GameState.solar_motes_changed.connect(_on_solar_motes)
	GameState.solar_charge_changed.connect(_on_solar_charge_changed)
	GameState.rewind_window_changed.connect(_on_rewind_window_changed)
	GameState.gameplay_callout.connect(_on_gameplay_callout)
	GameState.fall_recorded.connect(_on_falls)
	PhoneController.connection_changed.connect(func(_c: bool, _cnt: int, _dev: String):
		_refresh_control_hints(true)
	)
	PhoneController.mode_changed.connect(func(_u: bool):
		_refresh_control_hints(true)
	)


func _build_hud() -> void:
	# Subtle soft corner scrim behind Top-Left Altitude Readout (clean contrast on bright sky!)
	var tl_scrim := UITheme.make_radial_scrim(Vector2(340, 150), Vector2(0.22, 0.30), 0.44, Color(0.05, 0.04, 0.07))
	tl_scrim.position = Vector2(0, 0)
	add_child(tl_scrim)

	# TOP-LEFT: Clean tracked realm eyebrow + heavy altitude readout (NO pill eyebrow clutter!)
	var tl := VBoxContainer.new()
	tl.position = Vector2(30, 24)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_theme_constant_override("separation", 3)
	add_child(tl)

	_world_label = Label.new()
	_world_label.text = "The Sunken Conservatory"
	UITheme.apply_font(_world_label, "semibold", 13, UITheme.INK_SECONDARY, 0.35, 1)
	tl.add_child(_world_label)

	var alt_row := HBoxContainer.new()
	alt_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alt_row.add_theme_constant_override("separation", 6)
	tl.add_child(alt_row)

	_alt_label = Label.new()
	_alt_label.text = "0m"
	UITheme.apply_font(_alt_label, "heavy", 36, UITheme.INK_PRIMARY, 0.36, 2)
	alt_row.add_child(_alt_label)

	var goal_l := Label.new()
	goal_l.text = "/ 1,085m"
	goal_l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	UITheme.apply_font(goal_l, "semibold", 15, Color(0.96, 0.93, 0.86, 0.88), 0.34, 1)
	alt_row.add_child(goal_l)

	_alt_bar = ProgressBar.new()
	_alt_bar.max_value = GameState.SUMMIT_ALTITUDE
	_alt_bar.show_percentage = false
	_alt_bar.custom_minimum_size = Vector2(184, 5)
	_alt_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var fill := StyleBoxFlat.new()
	fill.bg_color = UITheme.ACCENT_AMBER
	fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.06, 0.09, 0.45)
	bg.set_corner_radius_all(3)
	_alt_bar.add_theme_stylebox_override("fill", fill)
	_alt_bar.add_theme_stylebox_override("background", bg)
	tl.add_child(_alt_bar)

	# TOP-RIGHT: Compact Warm Translucent Speedrun & Collectibles Capsule
	var top_right := PanelContainer.new()
	top_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	top_right.offset_left = -28
	top_right.offset_right = -28
	top_right.offset_top = 24
	top_right.offset_bottom = 66
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_right.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_GLASS, UITheme.BORDER_SUBTLE, 999, 20, 8, 1))
	add_child(top_right)

	var trh := HBoxContainer.new()
	trh.alignment = BoxContainer.ALIGNMENT_CENTER
	trh.add_theme_constant_override("separation", 16)
	top_right.add_child(trh)

	_timer_label = Label.new()
	_timer_label.text = "00:00.00"
	UITheme.apply_font(_timer_label, "bold", 16, UITheme.INK_PRIMARY)
	trh.add_child(_timer_label)

	_shards_label = Label.new()
	_shards_label.text = "✦ 0/18"
	UITheme.apply_font(_shards_label, "bold", 15, UITheme.ACCENT_AMBER)
	trh.add_child(_shards_label)

	_motes_label = Label.new()
	_motes_label.text = "☀ 0"
	UITheme.apply_font(_motes_label, "bold", 15, Color(1.0, 0.88, 0.44))
	trh.add_child(_motes_label)

	_falls_label = Label.new()
	_falls_label.text = "0 Falls"
	UITheme.apply_font(_falls_label, "semibold", 14, UITheme.INK_SECONDARY)
	trh.add_child(_falls_label)

	# BOTTOM-CENTER: 30-Second Shrine Rewind Countdown Pill (above Flow bar)
	_rewind_center = CenterContainer.new()
	_rewind_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_rewind_center.offset_top = -134
	_rewind_center.offset_bottom = -94
	_rewind_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rewind_center.visible = false
	_rewind_center.modulate.a = 0.0
	add_child(_rewind_center)

	_rewind_pill = PanelContainer.new()
	_rewind_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rewind_pill.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.14, 0.09, 0.05, 0.88),
		Color(1.0, 0.76, 0.28, 0.86),
		999, 18, 6, 1
	))
	_rewind_center.add_child(_rewind_pill)

	_rewind_label = Label.new()
	_rewind_label.text = "⟲  R · Rewind to Shrine  (30s)"
	_rewind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_rewind_label, "extrabold", 13, Color(1.0, 0.88, 0.48))
	_rewind_pill.add_child(_rewind_label)

	# BOTTOM-CENTER: Kinetic Flow Momentum Bar (appears smoothly only while chaining Flow or Solar Charged!)
	var flow_center := CenterContainer.new()
	flow_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	flow_center.offset_top = -88
	flow_center.offset_bottom = -36
	flow_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flow_center)

	_flow_container = VBoxContainer.new()
	_flow_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_flow_container.add_theme_constant_override("separation", 4)
	_flow_container.modulate.a = 0.0
	_flow_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow_center.add_child(_flow_container)

	_flow_label = Label.new()
	_flow_label.text = "FLOW x1"
	_flow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_flow_label, "bold", 13, UITheme.ACCENT_AMBER, 0.35, 1)
	_flow_container.add_child(_flow_label)

	_flow_bar = ProgressBar.new()
	_flow_bar.max_value = 1.0
	_flow_bar.show_percentage = false
	_flow_bar.custom_minimum_size = Vector2(260, 6)
	_flow_fill_style = StyleBoxFlat.new()
	_flow_fill_style.bg_color = UITheme.ACCENT_AMBER
	_flow_fill_style.set_corner_radius_all(3)
	var fbg := StyleBoxFlat.new()
	fbg.bg_color = Color(0.08, 0.06, 0.09, 0.50)
	fbg.set_corner_radius_all(3)
	_flow_bar.add_theme_stylebox_override("fill", _flow_fill_style)
	_flow_bar.add_theme_stylebox_override("background", fbg)
	_flow_container.add_child(_flow_bar)

	# CLEAN KEYCAP HINT BAR (auto-fades cleanly after 6.0s of play!)
	var whisper_center := CenterContainer.new()
	whisper_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	whisper_center.offset_top = -48
	whisper_center.offset_bottom = -14
	whisper_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(whisper_center)

	_whisper_panel = PanelContainer.new()
	_whisper_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_whisper_panel.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_GLASS, UITheme.BORDER_SUBTLE, 999, 18, 6, 1))
	whisper_center.add_child(_whisper_panel)

	_whisper_row = HBoxContainer.new()
	_whisper_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_whisper_row.add_theme_constant_override("separation", 18)
	_whisper_panel.add_child(_whisper_row)

	# BORDERLESS CENTERED REALM ARRIVAL BANNER OVER SOFT RADIAL SCRIM (no clunky dark box!)
	_toast_root = Control.new()
	_toast_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast_root.offset_top = 42
	_toast_root.offset_bottom = 178
	_toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_root.modulate.a = 0.0
	add_child(_toast_root)

	var toast_center := CenterContainer.new()
	toast_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_root.add_child(toast_center)

	var scrim_holder := Control.new()
	scrim_holder.custom_minimum_size = Vector2(560, 126)
	scrim_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_center.add_child(scrim_holder)

	var toast_scrim := UITheme.make_radial_scrim(Vector2(560, 126), Vector2(0.5, 0.5), 0.50, Color(0.05, 0.04, 0.07))
	scrim_holder.add_child(toast_scrim)

	var tv := VBoxContainer.new()
	tv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_theme_constant_override("separation", 4)
	scrim_holder.add_child(tv)

	var badge_c := CenterContainer.new()
	badge_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(badge_c)
	var tb := UITheme.make_realm_pill("Realm I")
	_toast_badge_label = tb.get_node("BadgeLabel") as Label
	badge_c.add_child(tb)

	_toast_title = Label.new()
	_toast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_toast_title, "heavy", 32, UITheme.INK_PRIMARY, 0.36, 2)
	tv.add_child(_toast_title)

	_toast_sub = Label.new()
	_toast_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_toast_sub, "semibold", 14, Color(0.95, 0.91, 0.85, 0.92), 0.34, 1)
	tv.add_child(_toast_sub)

	# PUNCHY UPPER-CENTER DOPAMINE CALLOUT BANNER
	_callout_center = CenterContainer.new()
	_callout_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_callout_center.offset_top = 182
	_callout_center.offset_bottom = 250
	_callout_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_callout_center.visible = false
	_callout_center.modulate.a = 0.0
	add_child(_callout_center)

	_callout_pill = PanelContainer.new()
	_callout_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_callout_pill.resized.connect(func(): _callout_pill.pivot_offset = _callout_pill.size * 0.5)
	_callout_pill.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.08, 0.065, 0.08, 0.88),
		UITheme.ACCENT_AMBER,
		999, 26, 8, 2
	))
	_callout_center.add_child(_callout_pill)

	var cal_v := VBoxContainer.new()
	cal_v.alignment = BoxContainer.ALIGNMENT_CENTER
	cal_v.add_theme_constant_override("separation", 1)
	cal_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_callout_pill.add_child(cal_v)

	_callout_title = Label.new()
	_callout_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_callout_title, "heavy", 20, UITheme.ACCENT_AMBER, 0.34, 1)
	cal_v.add_child(_callout_title)

	_callout_sub = Label.new()
	_callout_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_callout_sub, "bold", 12, UITheme.INK_PRIMARY)
	cal_v.add_child(_callout_sub)

	# DYNAMIC TETHER ORB LOCK-ON RETICLE
	_tether_reticle = PanelContainer.new()
	_tether_reticle.visible = false
	_tether_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tether_reticle.add_theme_stylebox_override("panel", UITheme.glass_box(Color(0.08, 0.16, 0.24, 0.86), Color(0.45, 0.94, 1.0, 0.92), 999, 14, 6, 2))
	_tether_label = Label.new()
	_tether_label.text = "E / RMB  Snap"
	UITheme.apply_font(_tether_label, "bold", 12, Color(0.68, 0.98, 1.0))
	_tether_reticle.add_child(_tether_label)
	add_child(_tether_reticle)

	_refresh_control_hints(false)


func _refresh_control_hints(reset_timer: bool) -> void:
	if _whisper_row == null:
		return
	for ch in _whisper_row.get_children():
		ch.queue_free()
	var use_phone := PhoneController.is_connected or PhoneController.use_phone_controller
	var pairs := (
		[["✕ / R1", "Jump / Flutter"], ["○ / L2", "Slide / Sky-Dive"], ["□ / R2", "Air-Dash / Orb"], ["△", "30s Rewind"], ["≡", "Menu"]]
		if use_phone else
		[["Space", "Jump / Flutter"], ["C", "Slide / Sky-Dive"], ["E / RMB", "Air-Dash / Orb"], ["R", "30s Rewind"], ["Esc", "Menu"]]
	)
	for pair in pairs:
		var pair_h := HBoxContainer.new()
		pair_h.add_theme_constant_override("separation", 6)
		var kl := Label.new()
		kl.text = pair[0]
		UITheme.apply_font(kl, "bold", 12, UITheme.ACCENT_AMBER)
		var vl := Label.new()
		vl.text = pair[1]
		UITheme.apply_font(vl, "medium", 12, UITheme.INK_SECONDARY)
		pair_h.add_child(kl)
		pair_h.add_child(vl)
		_whisper_row.add_child(pair_h)
	if _tether_label:
		_tether_label.text = "□ / R2  Snap" if use_phone else "E / RMB  Snap"
	_update_rewind_text()
	if reset_timer:
		_whisper_timer = 6.0
		_whisper_panel.modulate.a = 1.0


func show_world_toast(idx: int, wname: String, sub: String) -> void:
	var numerals: Array[String] = ["Realm I", "Realm II", "Realm III", "Realm IV", "Realm V", "Realm VI"]
	_toast_badge_label.text = numerals[clampi(idx, 0, 5)]
	_toast_title.text = wname
	_toast_sub.text = sub
	_world_label.text = wname
	_toast_timer = 2.5
	_toast_root.visible = true
	_toast_root.modulate.a = 1.0
	_world_label.modulate.a = 0.0
	_toast_root.pivot_offset = _toast_root.size * 0.5
	_toast_root.scale = Vector2(0.96, 0.96)
	var tw := create_tween()
	tw.tween_property(_toast_root, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func hide_toast_immediate() -> void:
	_toast_timer = 0.0
	_toast_root.modulate.a = 0.0
	_world_label.modulate.a = 1.0
	_toast_root.visible = false


func set_paused_hidden(is_paused_flag: bool) -> void:
	if is_paused_flag:
		hide_toast_immediate()
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_altitude(alt: float, _best: float) -> void:
	_alt_label.text = "%dm" % int(round(alt))
	_alt_bar.value = alt


func _on_world_entered(idx: int, wname: String, sub: String) -> void:
	show_world_toast(idx, wname, sub)


func _on_flow(fv: float, streak: int) -> void:
	_flow_bar.value = fv
	if _solar_charged:
		_flow_label.text = "✦ SOLAR CHARGE · BONUS DASH"
	else:
		_flow_label.text = ("FLOW x%d" % streak) if streak > 0 else "MOMENTUM"


func _on_solar_charge_changed(charged: bool) -> void:
	_solar_charged = charged
	if charged:
		_flow_label.text = "✦ SOLAR CHARGE · BONUS DASH"
		_flow_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42))
		if _flow_fill_style:
			_flow_fill_style.bg_color = Color(1.0, 0.92, 0.40)
	else:
		_flow_label.text = ("FLOW x%d" % GameState.current_streak) if GameState.current_streak > 0 else "MOMENTUM"
		_flow_label.add_theme_color_override("font_color", UITheme.ACCENT_AMBER)
		if _flow_fill_style:
			_flow_fill_style.bg_color = UITheme.ACCENT_AMBER


func _on_shards(cur: int, tot: int) -> void:
	_shards_label.text = "✦ %d/%d" % [cur, tot]


func _on_solar_motes(total: int) -> void:
	if _motes_label:
		_motes_label.text = "☀ %d" % total


func _on_falls(cnt: int) -> void:
	_falls_label.text = "1 Fall" if cnt == 1 else "%d Falls" % cnt


func _update_rewind_text() -> void:
	if _rewind_label == null:
		return
	var use_phone := PhoneController.is_connected or PhoneController.use_phone_controller
	var secs := int(ceil(_rewind_rem))
	if use_phone:
		_rewind_label.text = "⟲  △ · Rewind to Shrine  (%ds)" % secs
	else:
		_rewind_label.text = "⟲  R · Rewind to Shrine  (%ds)" % secs


func _on_rewind_window_changed(remaining_sec: float, active: bool) -> void:
	_rewind_rem = remaining_sec
	var was_active := _rewind_active
	_rewind_active = active
	_update_rewind_text()
	if active and not was_active:
		if _rewind_fade_tween and _rewind_fade_tween.is_valid():
			_rewind_fade_tween.kill()
		_rewind_center.visible = true
		_rewind_pulse_t = 0.0
		_rewind_fade_tween = create_tween()
		_rewind_fade_tween.tween_property(_rewind_center, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	elif not active and was_active:
		if _rewind_fade_tween and _rewind_fade_tween.is_valid():
			_rewind_fade_tween.kill()
		_rewind_fade_tween = create_tween()
		_rewind_fade_tween.tween_property(_rewind_center, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_rewind_fade_tween.tween_callback(func(): _rewind_center.visible = false)


func _on_gameplay_callout(title: String, subtitle: String, accent_color: Color) -> void:
	if _callout_center == null:
		return
	if _callout_tween and _callout_tween.is_valid():
		_callout_tween.kill()
	_callout_title.text = title
	_callout_title.add_theme_color_override("font_color", accent_color)
	_callout_sub.text = subtitle
	_callout_sub.visible = not subtitle.is_empty()
	_callout_pill.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.08, 0.065, 0.08, 0.90),
		Color(accent_color.r, accent_color.g, accent_color.b, 0.85),
		999, 26, 8, 2
	))

	_callout_center.visible = true
	_callout_center.modulate.a = 0.0
	_callout_pill.pivot_offset = _callout_pill.size * 0.5
	_callout_pill.scale = Vector2(0.84, 0.84)

	_callout_tween = create_tween()
	_callout_tween.set_parallel(true)
	_callout_tween.tween_property(_callout_pill, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_callout_tween.tween_property(_callout_center, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_callout_tween.chain().tween_interval(1.6)
	_callout_tween.chain().tween_property(_callout_center, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_callout_tween.chain().tween_callback(func(): _callout_center.visible = false)


func _process(delta: float) -> void:
	if not visible:
		return
	_timer_label.text = GameState.format_time(GameState.run_time)

	var target_flow_a := 1.0 if (GameState.current_flow > 0.06 or _solar_charged) else 0.0
	_flow_container.modulate.a = lerpf(_flow_container.modulate.a, target_flow_a, clampf(delta * 8.0, 0.0, 1.0))

	if _rewind_active and _rewind_center.visible:
		if _rewind_rem < 8.0:
			_rewind_pulse_t += delta
			_rewind_pill.modulate.a = 0.65 + 0.35 * sin(_rewind_pulse_t * 7.5)
		else:
			_rewind_pill.modulate.a = 1.0

	if _toast_timer > 0.0:
		_toast_timer = maxf(0.0, _toast_timer - delta)
		var a := minf(1.0, _toast_timer * 1.8) if _toast_timer < 0.6 else 1.0
		_toast_root.modulate.a = clampf(a, 0.0, 1.0)
		_world_label.modulate.a = clampf(1.0 - _toast_root.modulate.a, 0.0, 1.0)
	else:
		_toast_root.modulate.a = 0.0
		_world_label.modulate.a = 1.0

	if _whisper_timer > 0.0:
		_whisper_timer -= delta
		if _whisper_timer < 1.5:
			_whisper_panel.modulate.a = clampf(_whisper_timer / 1.5, 0.0, 1.0)
	else:
		_whisper_panel.modulate.a = 0.0

	if player_ref and is_instance_valid(player_ref):
		var orb := player_ref.get_hovered_tether_orb()
		PhoneController.set_orb_locked(orb != null)
		var cam := get_viewport().get_camera_3d()
		if orb and cam and not cam.is_position_behind(orb.global_position):
			var sp := cam.unproject_position(orb.global_position)
			_tether_reticle.visible = true
			_tether_reticle.position = sp - _tether_reticle.size * 0.5 + Vector2(0.0, -34.0)
		else:
			_tether_reticle.visible = false
