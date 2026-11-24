extends Control
class_name GameHUD
## Clean, Tactile Indie HUD crafted with OFL Nunito typography & surgical visual restraint.
## Borderless centered Realm Arrival banner over a soft radial scrim (2.5s auto-fade),
## keycap bar auto-fading after 6.0s with live InputManager glyphs (Keyboard / PS5 / Xbox / Switch Pro / iPhone),
## crisp top-left readout with Purist Mode badge, and a subtle edge-of-screen wind-rush vignette during steep falls.


class WindRushVignetteControl extends Control:
	var intensity: float = 0.0
	var focus_tint: float = 0.0
	var _time: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_intensity(val: float, delta: float, focus_val: float = 0.0) -> void:
		_time += delta
		var next_i := clampf(val, 0.0, 1.0)
		var next_f := clampf(focus_val, 0.0, 1.0)
		if absf(next_i - intensity) > 0.002 or next_i > 0.005 or absf(next_f - focus_tint) > 0.002 or next_f > 0.005:
			intensity = next_i
			focus_tint = next_f
			queue_redraw()

	func _draw() -> void:
		var eff := maxf(intensity, focus_tint)
		if eff <= 0.005:
			return
		var sz := size
		if sz.x <= 2.0 or sz.y <= 2.0:
			return
		var band_x := sz.x * (0.14 if focus_tint > intensity else 0.12)
		var band_y := sz.y * (0.15 if focus_tint > intensity else 0.13)
		var pulse := 0.88 + 0.12 * sin(_time * (8.0 if focus_tint > 0.1 else 18.0))
		var edge_a := eff * (0.38 if focus_tint > intensity else 0.34) * pulse
		var base_rgb := Color(0.92, 0.96, 1.0).lerp(Color(0.54, 0.94, 1.0), focus_tint)
		var edge_col := Color(base_rgb.r, base_rgb.g, base_rgb.b, edge_a)
		var zero_col := Color(base_rgb.r, base_rgb.g, base_rgb.b, 0.0)

		# Left border gradient
		draw_polygon(
			PackedVector2Array([Vector2(0, 0), Vector2(band_x, 0), Vector2(band_x, sz.y), Vector2(0, sz.y)]),
			PackedColorArray([edge_col, zero_col, zero_col, edge_col])
		)
		# Right border gradient
		draw_polygon(
			PackedVector2Array([Vector2(sz.x - band_x, 0), Vector2(sz.x, 0), Vector2(sz.x, sz.y), Vector2(sz.x - band_x, sz.y)]),
			PackedColorArray([zero_col, edge_col, edge_col, zero_col])
		)
		# Top border gradient
		draw_polygon(
			PackedVector2Array([Vector2(0, 0), Vector2(sz.x, 0), Vector2(sz.x, band_y), Vector2(0, band_y)]),
			PackedColorArray([edge_col, edge_col, zero_col, zero_col])
		)
		# Bottom border gradient
		draw_polygon(
			PackedVector2Array([Vector2(0, sz.y - band_y), Vector2(sz.x, sz.y - band_y), Vector2(sz.x, sz.y), Vector2(0, sz.y)]),
			PackedColorArray([zero_col, zero_col, edge_col, edge_col])
		)

		# Subtle peripheral upward wind-streak hairlines along left & right edges
		var center := sz * 0.5
		var max_r := center.length()
		for i in range(18):
			var ang := float(i) * (TAU / 18.0) + sin(_time * 4.5 + float(i)) * 0.04
			var dir := Vector2(cos(ang), sin(ang))
			var p_in := center + dir * (max_r * (0.68 - 0.04 * sin(_time * 14.0 + float(i) * 1.7)))
			var p_out := center + dir * (max_r * 0.98)
			var streak_a := intensity * (0.14 + 0.08 * sin(_time * 16.0 + float(i) * 2.3))
			draw_line(p_in, p_out, Color(1.0, 0.97, 0.90, streak_a), 1.4, true)


var _wind_vignette: WindRushVignetteControl
var _wind_vignette_alpha: float = 0.0
var _focus_vignette_alpha: float = 0.0
var _alt_label: Label
var _world_label: Label
var _purist_badge: PanelContainer
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
var _toast_story: Label
var _toast_timer: float = 0.0

var _skydive_center: CenterContainer
var _skydive_label: Label
var _assist_center: CenterContainer
var _assist_label: Label
var _assist_yes_btn: Button
var _assist_no_btn: Button

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
var _context_pill_center: CenterContainer
var _context_pill: PanelContainer
var _context_pill_label: Label
var _trial_active: bool = false
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
	GameState.solar_overdrive_changed.connect(_on_solar_overdrive_changed)
	GameState.phase_toggled.connect(_on_phase_toggled)
	GameState.monsoon_wind_changed.connect(_on_monsoon_wind_changed)
	GameState.trial_state_changed.connect(_on_trial_state_changed)
	GameState.rewind_window_changed.connect(_on_rewind_window_changed)
	GameState.pilgrim_assist_offer_changed.connect(_on_pilgrim_assist_offer_changed)
	GameState.gameplay_callout.connect(_on_gameplay_callout)
	GameState.fall_recorded.connect(_on_falls)
	GameState.game_mode_changed.connect(func(_m: String):
		_refresh_purist_badge()
		_refresh_control_hints(false)
	)
	GameState.game_started.connect(func():
		_refresh_purist_badge()
		_refresh_control_hints(true)
	)
	InputManager.input_mode_changed.connect(func(_m: String):
		_refresh_control_hints(true)
	)
	InputManager.gamepad_changed.connect(func(_c: bool, _n: String, _s: String):
		_refresh_control_hints(true)
	)
	PhoneController.connection_changed.connect(func(_c: bool, _cnt: int, _dev: String):
		_refresh_control_hints(true)
	)
	PhoneController.mode_changed.connect(func(_u: bool):
		_refresh_control_hints(true)
	)


func _build_hud() -> void:
	# Subtle edge-of-screen radial/border wind-rush vignette during steep falls (vel.y < -18.0)
	_wind_vignette = WindRushVignetteControl.new()
	_wind_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_wind_vignette)

	# Subtle soft corner scrim behind Top-Left Altitude Readout (clean contrast on bright sky!)
	var tl_scrim := UITheme.make_radial_scrim(Vector2(380, 150), Vector2(0.22, 0.30), 0.44, Color(0.05, 0.04, 0.07))
	tl_scrim.position = Vector2(0, 0)
	add_child(tl_scrim)

	# TOP-LEFT: Clean tracked realm eyebrow + 🔥 PURIST MODE badge pill + heavy altitude readout
	var tl := VBoxContainer.new()
	tl.position = Vector2(30, 24)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_theme_constant_override("separation", 3)
	add_child(tl)

	var world_row := HBoxContainer.new()
	world_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_row.add_theme_constant_override("separation", 8)
	tl.add_child(world_row)

	_world_label = Label.new()
	_world_label.text = "The Sunken Conservatory"
	UITheme.apply_font(_world_label, "semibold", 13, UITheme.INK_SECONDARY, 0.35, 1)
	world_row.add_child(_world_label)

	_purist_badge = PanelContainer.new()
	_purist_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_purist_badge.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.22, 0.08, 0.04, 0.90),
		Color(1.0, 0.56, 0.22, 0.92),
		999, 10, 2, 1
	))
	var purist_lbl := Label.new()
	purist_lbl.text = "🔥 PURIST MODE"
	UITheme.apply_font(purist_lbl, "extrabold", 11, Color(1.0, 0.78, 0.40))
	_purist_badge.add_child(purist_lbl)
	world_row.add_child(_purist_badge)
	_refresh_purist_badge()

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

	# BORDERLESS CENTERED REALM ARRIVAL BANNER OVER SOFT RADIAL SCRIM (with 1-line story beat!)
	_toast_root = Control.new()
	_toast_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast_root.offset_top = 36
	_toast_root.offset_bottom = 194
	_toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_root.modulate.a = 0.0
	add_child(_toast_root)

	var toast_center := CenterContainer.new()
	toast_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_root.add_child(toast_center)

	var scrim_holder := Control.new()
	scrim_holder.custom_minimum_size = Vector2(680, 152)
	scrim_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_center.add_child(scrim_holder)

	var toast_scrim := UITheme.make_radial_scrim(Vector2(680, 152), Vector2(0.5, 0.5), 0.54, Color(0.05, 0.04, 0.07))
	scrim_holder.add_child(toast_scrim)

	var tv := VBoxContainer.new()
	tv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_theme_constant_override("separation", 3)
	scrim_holder.add_child(tv)

	var badge_c := CenterContainer.new()
	badge_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(badge_c)
	var tb := UITheme.make_realm_pill("Realm I")
	_toast_badge_label = tb.get_node("BadgeLabel") as Label
	badge_c.add_child(tb)

	_toast_title = Label.new()
	_toast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_toast_title, "heavy", 31, UITheme.INK_PRIMARY, 0.36, 2)
	tv.add_child(_toast_title)

	_toast_sub = Label.new()
	_toast_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_toast_sub, "semibold", 14, Color(0.95, 0.91, 0.85, 0.92), 0.34, 1)
	tv.add_child(_toast_sub)

	_toast_story = Label.new()
	_toast_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font(_toast_story, "semibold", 12, Color(1.0, 0.88, 0.58, 0.94), 0.36, 1)
	tv.add_child(_toast_story)

	# VICTORY SKYDIVE STEERING BAR (bottom-center during 1,085m -> 0m Victory Skydive!)
	_skydive_center = CenterContainer.new()
	_skydive_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_skydive_center.offset_top = -54
	_skydive_center.offset_bottom = -16
	_skydive_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skydive_center.visible = false
	add_child(_skydive_center)

	var skydive_pill := PanelContainer.new()
	skydive_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skydive_pill.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.11, 0.08, 0.05, 0.88),
		Color(1.0, 0.82, 0.36, 0.88),
		999, 22, 7, 1
	))
	_skydive_center.add_child(skydive_pill)

	_skydive_label = Label.new()
	_skydive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_skydive_label, "bold", 13, Color(1.0, 0.92, 0.62))
	skydive_pill.add_child(_skydive_label)

	# PILGRIM GRACE 30s INTERACTIVE PROMPT (Yes / Not Now — clickable OR instant Y/N / D-Pad ↑↓!)
	_assist_center = CenterContainer.new()
	_assist_center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_assist_center.offset_top = -182
	_assist_center.offset_bottom = -134
	_assist_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_assist_center.visible = false
	add_child(_assist_center)

	var assist_pill := PanelContainer.new()
	assist_pill.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.11, 0.085, 0.05, 0.92),
		Color(1.0, 0.82, 0.36, 0.90),
		999, 18, 7, 1
	))
	_assist_center.add_child(assist_pill)

	var assist_row := HBoxContainer.new()
	assist_row.alignment = BoxContainer.ALIGNMENT_CENTER
	assist_row.add_theme_constant_override("separation", 12)
	assist_pill.add_child(assist_row)

	_assist_label = Label.new()
	_assist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_assist_label, "extrabold", 13, Color(1.0, 0.92, 0.62))
	assist_row.add_child(_assist_label)

	_assist_yes_btn = Button.new()
	_assist_yes_btn.custom_minimum_size = Vector2(0, 28)
	UITheme.style_primary_cta(_assist_yes_btn, 12)
	_assist_yes_btn.pressed.connect(func():
		if player_ref and is_instance_valid(player_ref):
			player_ref.accept_pilgrim_assist()
	)
	assist_row.add_child(_assist_yes_btn)

	_assist_no_btn = Button.new()
	_assist_no_btn.custom_minimum_size = Vector2(0, 28)
	UITheme.style_secondary_pill(_assist_no_btn, false, 12)
	_assist_no_btn.pressed.connect(func():
		if player_ref and is_instance_valid(player_ref):
			player_ref.dismiss_pilgrim_assist()
	)
	assist_row.add_child(_assist_no_btn)

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
	_tether_label.text = "%s  Snap" % InputManager.get_glyph("dash")
	UITheme.apply_font(_tether_label, "bold", 12, Color(0.68, 0.98, 1.0))
	_tether_reticle.add_child(_tether_label)
	add_child(_tether_reticle)

	# CONTEXTUAL REALM / TRIAL STATUS PILL (Phase-Swap Glass, Monsoon Wind Gust, 10s Sun-Shard Trial)
	_context_pill_center = CenterContainer.new()
	_context_pill_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_context_pill_center.offset_top = 82
	_context_pill_center.offset_bottom = 122
	_context_pill_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_context_pill_center.visible = false
	add_child(_context_pill_center)

	_context_pill = PanelContainer.new()
	_context_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_context_pill.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.10, 0.08, 0.14, 0.88),
		Color(0.95, 0.56, 0.90, 0.90),
		999, 18, 6, 1
	))
	_context_pill_center.add_child(_context_pill)

	_context_pill_label = Label.new()
	_context_pill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_context_pill_label, "extrabold", 13, Color(1.0, 0.92, 0.96))
	_context_pill.add_child(_context_pill_label)

	_refresh_control_hints(false)


func _refresh_purist_badge() -> void:
	if _purist_badge != null:
		_purist_badge.visible = GameState.is_purist_mode()


func _refresh_control_hints(reset_timer: bool) -> void:
	if _whisper_row == null:
		return
	for ch in _whisper_row.get_children():
		ch.queue_free()

	var pairs: Array = [
		[InputManager.get_glyph("jump"), "Jump / Double-Jump"],
		[InputManager.get_glyph("dash"), "Air-Dash / Orb"],
		[InputManager.get_glyph("focus"), "Sky Focus (Slow-Mo)"],
		[InputManager.get_glyph("slide"), "Slide / Sky-Dive"],
		[InputManager.get_glyph("rewind"), "30s Rewind"],
		[InputManager.get_glyph("pause"), "Menu"],
	]
	for pair in pairs:
		var pair_h := HBoxContainer.new()
		pair_h.add_theme_constant_override("separation", 6)
		var kl := Label.new()
		kl.text = str(pair[0])
		UITheme.apply_font(kl, "bold", 12, UITheme.ACCENT_AMBER)
		var vl := Label.new()
		vl.text = str(pair[1])
		UITheme.apply_font(vl, "medium", 12, UITheme.INK_SECONDARY)
		pair_h.add_child(kl)
		pair_h.add_child(vl)
		_whisper_row.add_child(pair_h)
	_update_tether_reticle()
	_update_rewind_text()
	_update_skydive_text()
	_refresh_pilgrim_assist_buttons()
	if _solar_charged:
		_flow_label.text = "✦ SKY FOCUS READY · %s (Mid-Air)" % InputManager.get_glyph("focus")
	if reset_timer:
		_whisper_timer = 6.0
		_whisper_panel.modulate.a = 1.0


func _update_skydive_text() -> void:
	if _skydive_label != null:
		_skydive_label.text = "✦ VICTORY SKYDIVE · Steer through the Golden Rings  ·  Hold %s to Glide  ·  Hold %s for Speed" % [
			InputManager.get_glyph("jump"),
			InputManager.get_glyph("slide"),
		]


func _update_tether_reticle() -> void:
	if _tether_label != null:
		_tether_label.text = "%s  Snap" % InputManager.get_glyph("dash")


func show_world_toast(idx: int, wname: String, sub: String) -> void:
	var numerals: Array[String] = ["Realm I", "Realm II", "Realm III", "Realm IV", "Realm V", "Realm VI"]
	var c_idx := clampi(idx, 0, 5)
	_toast_badge_label.text = numerals[c_idx]
	_toast_title.text = wname
	_toast_sub.text = sub
	if _toast_story != null:
		var story_txt: String = str(GameState.WORLDS[c_idx].get("story", ""))
		_toast_story.text = story_txt
		_toast_story.visible = not story_txt.is_empty()
	_world_label.text = wname
	_refresh_purist_badge()
	_toast_timer = 4.2
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
	if not _trial_active:
		if idx == 3 or idx == 5:
			_on_phase_toggled(GameState.phase_state)
		else:
			_set_context_pill(false)


func _on_flow(fv: float, streak: int) -> void:
	_flow_bar.value = fv
	if player_ref and is_instance_valid(player_ref) and player_ref.is_sky_focus_active():
		_flow_label.text = "✦ SKY FOCUS · SLOW-MOTION"
	elif GameState.solar_overdrive_active:
		_flow_label.text = "☀ SOLAR OVERDRIVE · 2x DASH · %s SLOW-MO" % InputManager.get_glyph("focus")
	elif _solar_charged:
		_flow_label.text = "✦ SKY FOCUS READY · %s (Mid-Air)" % InputManager.get_glyph("focus")
	else:
		_flow_label.text = ("RESONANCE x%d" % streak) if streak > 0 else "SKY RESONANCE"


func _on_solar_overdrive_changed(active: bool) -> void:
	if active:
		_flow_label.text = "☀ SOLAR OVERDRIVE · 2x DASH · %s SLOW-MO" % InputManager.get_glyph("focus")
		_flow_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.36))
		if _flow_fill_style:
			_flow_fill_style.bg_color = Color(1.0, 0.84, 0.24)
	else:
		_on_solar_charge_changed(_solar_charged)


func _set_context_pill(show: bool, text: String = "", accent: Color = Color(1.0, 0.84, 0.36)) -> void:
	if _context_pill_center == null or _context_pill == null or _context_pill_label == null:
		return
	_context_pill_center.visible = show
	if not show:
		return
	_context_pill_label.text = text
	_context_pill_label.add_theme_color_override("font_color", accent.lightened(0.24))
	_context_pill.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.08, 0.07, 0.11, 0.88),
		Color(accent.r, accent.g, accent.b, 0.92),
		999, 18, 6, 1
	))


func _on_phase_toggled(new_phase: int) -> void:
	if _trial_active:
		return
	if GameState.current_world_idx == 3 or GameState.current_world_idx == 5:
		if new_phase == 0:
			_set_context_pill(true, "◆ PHASE: ROSE GLASS SOLID  ·  Jump/Dash to Swap", Color(0.98, 0.45, 0.82))
		else:
			_set_context_pill(true, "◇ PHASE: CYAN GLASS SOLID  ·  Jump/Dash to Swap", Color(0.35, 0.92, 1.0))


func _on_monsoon_wind_changed(phase_name: String, _dir: Vector3, _strength: float) -> void:
	if _trial_active:
		return
	if GameState.current_world_idx != 2:
		if _context_pill_center and _context_pill_center.visible and _context_pill_label.text.contains("MONSOON"):
			_set_context_pill(false)
		return
	if phase_name == "telegraph":
		_set_context_pill(true, "〰 MONSOON GUST BUILDING  ·  Use Cover or Ride Tailwind!", Color(0.55, 0.94, 1.0))
	elif phase_name == "gust":
		_set_context_pill(true, "💨 MONSOON GALE ACTIVE!  ·  Ride the Wind or Shelter!", Color(1.0, 0.82, 0.36))
	else:
		_set_context_pill(false)


func _on_trial_state_changed(active: bool, title: String, collected: int, total: int, time_left: float) -> void:
	_trial_active = active
	if active:
		var col := Color(1.0, 0.42, 0.30) if time_left < 3.0 else Color(1.0, 0.86, 0.34)
		_set_context_pill(true, "✦ %s  ·  %d/%d RINGS  ·  %.1fs" % [title, collected, total, maxf(0.0, time_left)], col)
	else:
		_set_context_pill(false)


func _on_solar_charge_changed(charged: bool) -> void:
	_solar_charged = charged
	if charged:
		_flow_label.text = "✦ SKY FOCUS READY · %s (Mid-Air)" % InputManager.get_glyph("focus")
		_flow_label.add_theme_color_override("font_color", Color(0.62, 0.96, 1.0))
		if _flow_fill_style:
			_flow_fill_style.bg_color = Color(0.56, 0.94, 1.0)
	else:
		_flow_label.text = ("RESONANCE x%d" % GameState.current_streak) if GameState.current_streak > 0 else "SKY RESONANCE"
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
	var secs := int(ceil(_rewind_rem))
	_rewind_label.text = "⟲  %s · Rewind to Shrine  (%ds)" % [InputManager.get_glyph("rewind"), secs]


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


func _refresh_pilgrim_assist_buttons() -> void:
	if _assist_yes_btn != null:
		_assist_yes_btn.text = "Yes (%s)" % InputManager.get_glyph("assist_yes")
	if _assist_no_btn != null:
		_assist_no_btn.text = "No (%s)" % InputManager.get_glyph("assist_no")


func _on_pilgrim_assist_offer_changed(target_cp: Dictionary, active: bool) -> void:
	if _assist_center == null or _assist_label == null:
		return
	_assist_center.visible = active
	if active:
		var cp_pos: Vector3 = target_cp.get("pos", Vector3.ZERO)
		var alt_m := int(round(cp_pos.y))
		_assist_label.text = "✦ Stuck here? Teleport to Next Shrine (%dm)?" % alt_m
		_refresh_pilgrim_assist_buttons()


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

	var real_dt := delta / maxf(Engine.time_scale, 0.05)
	var focus_now := player_ref != null and is_instance_valid(player_ref) and player_ref.is_sky_focus_active()
	var target_flow_a := 1.0 if (GameState.current_flow > 0.06 or _solar_charged or focus_now) else 0.0
	if GameState.victory_skydive_active:
		target_flow_a = 0.0
	_flow_container.modulate.a = lerpf(_flow_container.modulate.a, target_flow_a, clampf(real_dt * 8.0, 0.0, 1.0))
	if focus_now:
		_flow_label.text = "✦ SKY FOCUS · SLOW-MOTION"
		_flow_label.add_theme_color_override("font_color", Color(0.62, 0.96, 1.0))

	if _skydive_center:
		_skydive_center.visible = GameState.victory_skydive_active
		if GameState.victory_skydive_active:
			_whisper_panel.modulate.a = 0.0

	if _rewind_active and _rewind_center.visible:
		if _rewind_rem < 8.0:
			_rewind_pulse_t += real_dt
			_rewind_pill.modulate.a = 0.65 + 0.35 * sin(_rewind_pulse_t * 7.5)
		else:
			_rewind_pill.modulate.a = 1.0

	if _toast_timer > 0.0:
		_toast_timer = maxf(0.0, _toast_timer - real_dt)
		var a := minf(1.0, _toast_timer * 1.6) if _toast_timer < 0.7 else 1.0
		_toast_root.modulate.a = clampf(a, 0.0, 1.0)
		_world_label.modulate.a = clampf(1.0 - _toast_root.modulate.a, 0.0, 1.0)
	else:
		_toast_root.modulate.a = 0.0
		_world_label.modulate.a = 1.0

	if not GameState.victory_skydive_active:
		if _whisper_timer > 0.0:
			_whisper_timer -= real_dt
			if _whisper_timer < 1.5:
				_whisper_panel.modulate.a = clampf(_whisper_timer / 1.5, 0.0, 1.0)
		else:
			_whisper_panel.modulate.a = 0.0

	var target_wind_v := 0.0
	if player_ref and is_instance_valid(player_ref):
		if not player_ref.is_on_floor() and player_ref.velocity.y < -18.0:
			target_wind_v = clampf((-player_ref.velocity.y - 18.0) / 18.0, 0.0, 1.0)

		var orb := player_ref.get_hovered_tether_orb()
		PhoneController.set_orb_locked(orb != null)
		var cam := get_viewport().get_camera_3d()
		if orb and cam and not cam.is_position_behind(orb.global_position):
			var sp := cam.unproject_position(orb.global_position)
			_update_tether_reticle()
			_tether_reticle.visible = true
			_tether_reticle.position = sp - _tether_reticle.size * 0.5 + Vector2(0.0, -34.0)
		else:
			_tether_reticle.visible = false

	_wind_vignette_alpha = lerpf(_wind_vignette_alpha, target_wind_v, clampf(real_dt * 8.0, 0.0, 1.0))
	_focus_vignette_alpha = lerpf(_focus_vignette_alpha, 1.0 if focus_now else 0.0, clampf(real_dt * 12.0, 0.0, 1.0))
	if _wind_vignette:
		_wind_vignette.set_intensity(_wind_vignette_alpha, real_dt, _focus_vignette_alpha)
