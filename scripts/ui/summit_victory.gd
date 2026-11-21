extends Control
class_name SummitVictoryUI
## Celebratory Summit Crown Victory Card framing the panoramic overlook across all 6 worlds below.
## Features a custom _draw() octagonal/sunburst RankCrestControl, run stats with NEW PERSONAL BEST badge,
## Golden Solstice Crown & Achievement Badge chips, a compact Top Runs Scoreboard, and 3 action buttons.

signal explore_summit_requested()
signal climb_again_requested()
signal credits_glide_requested()
signal victory_skydive_requested()


class RankCrestControl extends Control:
	var grade: String = "S"
	var accent_color: Color = Color(1.0, 0.82, 0.34)
	var _time: float = 0.0
	var _grade_lbl: Label

	func _ready() -> void:
		custom_minimum_size = Vector2(96, 96)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_grade_lbl = Label.new()
		_grade_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_grade_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_grade_lbl.text = grade
		UITheme.apply_font(_grade_lbl, "heavy", 32, Color(0.14, 0.09, 0.04), 0.25, 1)
		add_child(_grade_lbl)

	func set_rank(new_grade: String, new_col: Color) -> void:
		grade = new_grade
		accent_color = new_col
		_time = 0.0
		if _grade_lbl:
			_grade_lbl.text = grade
			UITheme.apply_font(_grade_lbl, "heavy", 29 if grade.length() > 1 else 34, Color(0.14, 0.09, 0.04))
		queue_redraw()

	func advance(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.44
		if r <= 4.0:
			return

		# Animated expanding golden ring pulse
		var pulse_u := fmod(_time * 0.65, 1.0)
		var pulse_r := r * lerpf(0.95, 1.32, pulse_u)
		var pulse_a := (1.0 - pulse_u) * 0.48
		draw_arc(c, pulse_r, 0.0, TAU, 48, Color(accent_color.r, accent_color.g, accent_color.b, pulse_a), 2.0, true)

		# Soft warm radial glow behind medal
		draw_circle(c, r * 1.16, Color(accent_color.r, accent_color.g, accent_color.b, 0.16))

		# 16-point rotating sunburst star polygon
		var star_pts := PackedVector2Array()
		var rot := _time * 0.22
		for i in range(32):
			var ang := rot + float(i) * (TAU / 32.0)
			var sr := r * (1.04 if (i % 2 == 0) else 0.84)
			star_pts.append(c + Vector2(cos(ang), sin(ang)) * sr)
		draw_colored_polygon(star_pts, Color(0.86, 0.62, 0.18, 0.92))

		# Outer octagonal heraldic plate
		var oct_outer := PackedVector2Array()
		var oct_loop := PackedVector2Array()
		for i in range(8):
			var ang := PI / 8.0 + float(i) * (TAU / 8.0)
			var pt := c + Vector2(cos(ang), sin(ang)) * (r * 0.86)
			oct_outer.append(pt)
			oct_loop.append(pt)
		oct_loop.append(oct_outer[0])
		draw_colored_polygon(oct_outer, accent_color.lerp(Color(1.0, 0.86, 0.38), 0.45))
		draw_polyline(oct_loop, Color(1.0, 0.96, 0.78, 0.95), 2.0, true)

		# Inner octagonal inset plate
		var oct_inner := PackedVector2Array()
		var oct_in_loop := PackedVector2Array()
		for i in range(8):
			var ang := PI / 8.0 + float(i) * (TAU / 8.0)
			var pt := c + Vector2(cos(ang), sin(ang)) * (r * 0.70)
			oct_inner.append(pt)
			oct_in_loop.append(pt)
		oct_in_loop.append(oct_inner[0])
		draw_colored_polygon(oct_inner, Color(1.0, 0.92, 0.62, 0.96))
		draw_polyline(oct_in_loop, Color(0.68, 0.44, 0.12, 0.85), 1.4, true)


var _dock: PanelContainer
var _crest: RankCrestControl
var _rank_title_lbl: Label
var _pb_badge: PanelContainer
var _val_time: Label
var _val_mode: Label
var _val_falls: Label
var _val_shards: Label
var _val_flow: Label
var _crown_banner: PanelContainer
var _crown_banner_lbl: Label
var _badges_flow: HBoxContainer
var _leaderboard_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func _process(delta: float) -> void:
	if visible and _crest:
		_crest.advance(delta)


func _build_ui() -> void:
	_dock = PanelContainer.new()
	_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dock.offset_left = 210
	_dock.offset_right = -210
	_dock.offset_top = -470
	_dock.offset_bottom = -24
	_dock.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_SOLID, Color(0.98, 0.78, 0.34, 0.50), 26, 28, 18, 1))
	add_child(_dock)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	_dock.add_child(v)

	# Top Hero Row: Heraldic Rank Medal Crest + Summit Title + Rank Title + PB Badge
	var top_hero := HBoxContainer.new()
	top_hero.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hero.add_theme_constant_override("separation", 20)
	v.add_child(top_hero)

	_crest = RankCrestControl.new()
	top_hero.add_child(_crest)

	var title_col := VBoxContainer.new()
	title_col.alignment = BoxContainer.ALIGNMENT_CENTER
	title_col.add_theme_constant_override("separation", 2)
	top_hero.add_child(title_col)

	var eyebrow_row := HBoxContainer.new()
	eyebrow_row.add_theme_constant_override("separation", 10)
	title_col.add_child(eyebrow_row)

	var eyebrow := Label.new()
	eyebrow.text = "1,085m Summit Reached"
	UITheme.apply_font(eyebrow, "semibold", 13, UITheme.INK_SECONDARY)
	eyebrow_row.add_child(eyebrow)

	_pb_badge = PanelContainer.new()
	_pb_badge.visible = false
	_pb_badge.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.18, 0.38, 0.22, 0.94),
		Color(0.46, 0.98, 0.64, 0.92),
		999, 10, 2, 1
	))
	var pb_lbl := Label.new()
	pb_lbl.text = "★ NEW PERSONAL BEST!"
	UITheme.apply_font(pb_lbl, "extrabold", 11, Color(0.76, 1.0, 0.84))
	_pb_badge.add_child(pb_lbl)
	eyebrow_row.add_child(_pb_badge)

	var title := Label.new()
	title.text = "The Crown of the Sun"
	UITheme.apply_font(title, "heavy", 32, UITheme.INK_PRIMARY)
	title_col.add_child(title)

	_rank_title_lbl = Label.new()
	_rank_title_lbl.text = "Rank S · Sun-Crowned"
	UITheme.apply_font(_rank_title_lbl, "extrabold", 15, UITheme.ACCENT_AMBER)
	title_col.add_child(_rank_title_lbl)

	# Run Stats Row
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 32)
	v.add_child(stats)
	_val_time = _add_stat(stats, "Time", "00:00.00")
	_val_mode = _add_stat(stats, "Ascent Mode", "PILGRIM")
	_val_falls = _add_stat(stats, "Falls", "0")
	_val_shards = _add_stat(stats, "Sun-Shards", "0 / 18")
	_val_flow = _add_stat(stats, "Peak Flow", "x0")

	# Newly Unlocked Rewards & Achievement Badges Banner
	var rewards_col := VBoxContainer.new()
	rewards_col.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_col.add_theme_constant_override("separation", 6)
	v.add_child(rewards_col)

	var crown_center := CenterContainer.new()
	rewards_col.add_child(crown_center)

	_crown_banner = PanelContainer.new()
	_crown_banner.add_theme_stylebox_override("panel", UITheme.glass_box(
		Color(0.24, 0.16, 0.05, 0.92),
		Color(1.0, 0.82, 0.34, 0.90),
		999, 18, 4, 1
	))
	crown_center.add_child(_crown_banner)

	_crown_banner_lbl = Label.new()
	_crown_banner_lbl.text = "👑 GOLDEN SOLSTICE CROWN UNLOCKED!"
	_crown_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_crown_banner_lbl, "extrabold", 12, Color(1.0, 0.90, 0.46))
	_crown_banner.add_child(_crown_banner_lbl)

	var badges_center := CenterContainer.new()
	rewards_col.add_child(badges_center)

	_badges_flow = HBoxContainer.new()
	_badges_flow.alignment = BoxContainer.ALIGNMENT_CENTER
	_badges_flow.add_theme_constant_override("separation", 6)
	badges_center.add_child(_badges_flow)

	# Compact Top Runs Scoreboard (up to top 4-5 rows from GameState.leaderboard)
	var lb_panel := PanelContainer.new()
	lb_panel.add_theme_stylebox_override("panel", UITheme.glass_box(Color(0.06, 0.05, 0.07, 0.72), UITheme.BORDER_SUBTLE, 14, 16, 8, 1))
	v.add_child(lb_panel)

	_leaderboard_box = VBoxContainer.new()
	_leaderboard_box.add_theme_constant_override("separation", 3)
	lb_panel.add_child(_leaderboard_box)

	# 4 Action Buttons: Victory Skydive (Hero CTA!) | Explore Summit | Credits Glide | Climb Again
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)

	var dive_btn := Button.new()
	dive_btn.text = "✦ Victory Skydive (1,085m → 0m)"
	dive_btn.custom_minimum_size = Vector2(270, 48)
	UITheme.style_primary_cta(dive_btn, 15)
	dive_btn.pressed.connect(func():
		AudioDirector.play_sfx("dash", -1.0, 1.25)
		visible = false
		victory_skydive_requested.emit()
	)
	row.add_child(dive_btn)

	var explore_btn := Button.new()
	explore_btn.text = "Explore Summit"
	explore_btn.custom_minimum_size = Vector2(154, 46)
	UITheme.style_secondary_pill(explore_btn, false, 14)
	explore_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		visible = false
		explore_summit_requested.emit()
	)
	row.add_child(explore_btn)

	var credits_btn := Button.new()
	credits_btn.text = "Credits Glide"
	credits_btn.custom_minimum_size = Vector2(146, 46)
	UITheme.style_secondary_pill(credits_btn, true, 14)
	credits_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click", -2.0, 1.08)
		visible = false
		credits_glide_requested.emit()
	)
	row.add_child(credits_btn)

	var replay_btn := Button.new()
	replay_btn.text = "Climb Again"
	replay_btn.custom_minimum_size = Vector2(142, 46)
	UITheme.style_secondary_pill(replay_btn, false, 14)
	replay_btn.pressed.connect(func():
		AudioDirector.play_sfx("ui_click")
		visible = false
		climb_again_requested.emit()
	)
	row.add_child(replay_btn)


func _add_stat(parent: HBoxContainer, lbl: String, init_val: String) -> Label:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	var vl := Label.new()
	vl.text = init_val
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(vl, "bold", 20, UITheme.INK_PRIMARY)
	var kl := Label.new()
	kl.text = lbl
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(kl, "medium", 11, UITheme.INK_SECONDARY)
	box.add_child(vl)
	box.add_child(kl)
	parent.add_child(box)
	return vl


func show_stats(run_time: float, falls: int, shards: int, max_streak: int) -> void:
	var summary: Dictionary = GameState.last_victory_summary
	var mode_str := str(summary.get("mode", GameState.game_mode))
	var rank_info := GameState.compute_rank(run_time, falls, shards, mode_str)
	var grade := str(summary.get("rank", rank_info["grade"]))
	var rank_title := str(summary.get("rank_title", rank_info["title"]))
	var rank_col: Color = summary.get("rank_color", rank_info["color"]) as Color
	var is_new_pb := bool(summary.get("is_new_pb", false))

	_crest.set_rank(grade, rank_col)
	_rank_title_lbl.text = "Rank %s  ·  %s" % [grade, rank_title]
	_rank_title_lbl.add_theme_color_override("font_color", rank_col)
	_pb_badge.visible = is_new_pb

	_val_time.text = GameState.format_time(run_time)
	_val_mode.text = "🔥 PURIST" if mode_str == "purist" else "✦ PILGRIM"
	_val_mode.add_theme_color_override("font_color", UITheme.ACCENT_AMBER if mode_str == "purist" else UITheme.INK_PRIMARY)
	_val_falls.text = str(falls)
	_val_shards.text = "%d / 18" % shards
	_val_flow.text = "x%d" % max_streak

	if mode_str == "purist":
		_crown_banner_lbl.text = "👑 GOLDEN SOLSTICE CROWN & PURIST HALO UNLOCKED!"
	else:
		_crown_banner_lbl.text = "👑 GOLDEN SOLSTICE CROWN UNLOCKED!"
	_crown_banner.visible = true

	_rebuild_badge_chips()
	_rebuild_leaderboard()

	visible = true
	AudioDirector.play_sfx("medal_chime", -1.0, 1.0)
	UITheme.animate_enter(_dock, 0.0, 0.28)


func _rebuild_badge_chips() -> void:
	if _badges_flow == null:
		return
	for ch in _badges_flow.get_children():
		ch.queue_free()

	var badge_order := [
		"summit_conqueror",
		"purist_legend",
		"sun_collector",
		"untouchable_flow",
		"shortcut_daredevil",
		"meteor_master",
	]
	for b_id: String in badge_order:
		if not GameState.BADGE_INFO.has(b_id):
			continue
		var earned: bool = GameState.unlocked_badges.has(b_id) or (b_id == "summit_conqueror")
		var b_info: Dictionary = GameState.BADGE_INFO[b_id]
		var chip := PanelContainer.new()
		chip.tooltip_text = "%s — %s" % [str(b_info["title"]), str(b_info["desc"])]
		if earned:
			chip.add_theme_stylebox_override("panel", UITheme.glass_box(
				Color(0.24, 0.16, 0.05, 0.90),
				Color(1.0, 0.80, 0.28, 0.88),
				999, 10, 3, 1
			))
		else:
			chip.add_theme_stylebox_override("panel", UITheme.glass_box(
				Color(0.08, 0.07, 0.09, 0.52),
				Color(0.96, 0.88, 0.72, 0.14),
				999, 10, 3, 1
			))
		var lbl := Label.new()
		lbl.text = ("✦ %s" if earned else "· %s") % str(b_info["title"])
		UITheme.apply_font(
			lbl,
			"extrabold" if earned else "semibold",
			11,
			Color(1.0, 0.88, 0.44) if earned else Color(0.68, 0.64, 0.58, 0.55)
		)
		chip.add_child(lbl)
		_badges_flow.add_child(chip)


func _rebuild_leaderboard() -> void:
	if _leaderboard_box == null:
		return
	for ch in _leaderboard_box.get_children():
		ch.queue_free()

	var head := Label.new()
	head.text = "TOP SUMMIT ASCENTS"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(head, "extrabold", 11, UITheme.ACCENT_AMBER)
	_leaderboard_box.add_child(head)

	var rows := GameState.leaderboard
	var max_rows := mini(rows.size(), 4)
	if max_rows == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "First Summit Recorded!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UITheme.apply_font(empty_lbl, "semibold", 11, UITheme.INK_SECONDARY)
		_leaderboard_box.add_child(empty_lbl)
		return

	for i in range(max_rows):
		var entry: Dictionary = rows[i] as Dictionary
		var r_row := HBoxContainer.new()
		r_row.alignment = BoxContainer.ALIGNMENT_CENTER
		r_row.add_theme_constant_override("separation", 18)
		_leaderboard_box.add_child(r_row)

		var rank_str := str(entry.get("rank", "S"))
		var mode_str := "PURIST" if str(entry.get("mode", "pilgrim")) == "purist" else "PILGRIM"
		var char_id := str(entry.get("char", "pip"))
		var char_name := str(GameState.CHARACTERS.get(char_id, {"name": "Pip"})["name"])
		var t_str := GameState.format_time(float(entry.get("time", 0.0)))
		var f_cnt := int(entry.get("falls", 0))
		var sh_cnt := int(entry.get("shards", 0))

		var line_lbl := Label.new()
		line_lbl.text = "#%d   [%s]   %s   ·   %s   ·   %s   ·   %d Falls   ·   ✦ %d/18" % [
			i + 1, rank_str, mode_str, char_name, t_str, f_cnt, sh_cnt
		]
		line_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UITheme.apply_font(
			line_lbl,
			"bold" if i == 0 else "semibold",
			11,
			UITheme.INK_PRIMARY if i == 0 else UITheme.INK_SECONDARY
		)
		r_row.add_child(line_lbl)
