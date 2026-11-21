extends Control
class_name LoadingScreenUI
## Option A: Minimal Indie Elegance Loading Screen for Solstice Spire (ZERO AI Art).
## Features a resolution-independent custom _draw() canvas with a multi-stop twilight-to-amber
## vertical sky gradient, 45 twinkling starlight pinpricks, a soft radial golden sun-bloom,
## an animated geometric Golden Sun-Spire Astrolabe Emblem with 6 igniting realm diamond pips
## and a Solstice Sun-Crown at the peak, 32 fine rising golden dust specks, editorial lockup,
## and a 3px hairline golden altitude track.

signal loading_finished()

const WHISPERS: Array[String] = [
	"Awakening the sky shrines...",
	"Tuning the bronze bells...",
	"Charting the summit winds...",
]


class MinimalSpireEmblemCanvas extends Control:
	var _stars: Array[Dictionary] = []
	var _dust: Array[Dictionary] = []
	var _time: float = 0.0
	var progress: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261121

		# 45 subtle twinkling starlight pinpricks in upper sky
		for i in range(45):
			_stars.append({
				"x": rng.randf_range(0.03, 0.97),
				"y": rng.randf_range(0.03, 0.64),
				"r": rng.randf_range(0.85, 1.95),
				"alpha": rng.randf_range(0.24, 0.78),
				"freq": rng.randf_range(1.1, 2.9),
				"phase": rng.randf_range(0.0, TAU),
				"sparkle": (i % 7 == 0),
			})

		# 32 fine drifting golden dust specks (1.2px - 2.8px delicate rising motes)
		for i in range(32):
			_dust.append({
				"x": rng.randf_range(0.05, 0.95),
				"y": rng.randf_range(0.04, 0.96),
				"vy": rng.randf_range(0.018, 0.046),
				"sway_amp": rng.randf_range(0.005, 0.016),
				"sway_freq": rng.randf_range(0.55, 1.35),
				"phase": rng.randf_range(0.0, TAU),
				"radius": rng.randf_range(1.2, 2.8),
				"alpha": rng.randf_range(0.32, 0.76),
				"warmth": rng.randf(),
			})

	func advance(delta: float) -> void:
		_time += delta
		for d in _dust:
			var ny: float = float(d["y"]) - float(d["vy"]) * delta
			if ny < -0.04:
				ny = 1.04
			d["y"] = ny
		queue_redraw()

	func _draw() -> void:
		var sz := size
		if sz.x <= 2.0 or sz.y <= 2.0:
			return

		# 1. Silky Multi-Stop Twilight-to-Amber Vertical Sky Gradient
		# Deep cosmic indigo top (#0A0E1E) -> velvet plum-indigo mid (#191A34) -> warm solstice amber-rose horizon (#462A28)
		var col_top := Color(0.0392, 0.0549, 0.1176, 1.0)      # #0A0E1E
		var col_upper_mid := Color(0.068, 0.076, 0.162, 1.0)
		var col_mid := Color(0.0980, 0.1020, 0.2039, 1.0)      # #191A34
		var col_low_mid := Color(0.184, 0.132, 0.192, 1.0)
		var col_horizon := Color(0.2745, 0.1647, 0.1569, 1.0)  # #462A28
		var col_base := Color(0.135, 0.088, 0.102, 1.0)

		var stops_y := [0.0, 0.26, 0.50, 0.72, 0.88, 1.0]
		var stops_c := [col_top, col_upper_mid, col_mid, col_low_mid, col_horizon, col_base]
		for s_idx in range(stops_y.size() - 1):
			var y0: float = float(stops_y[s_idx]) * sz.y
			var y1: float = float(stops_y[s_idx + 1]) * sz.y
			var c0: Color = stops_c[s_idx]
			var c1: Color = stops_c[s_idx + 1]
			var pts := PackedVector2Array([
				Vector2(0.0, y0),
				Vector2(sz.x, y0),
				Vector2(sz.x, y1),
				Vector2(0.0, y1),
			])
			var cols := PackedColorArray([c0, c0, c1, c1])
			draw_polygon(pts, cols)

		# 2. 45 subtle twinkling starlight pinpricks in upper sky
		for st in _stars:
			var sx: float = float(st["x"]) * sz.x
			var sy: float = float(st["y"]) * sz.y
			var sr: float = float(st["r"])
			var tw := 0.62 + 0.38 * sin(_time * float(st["freq"]) + float(st["phase"]))
			var sa: float = float(st["alpha"]) * tw
			var spos := Vector2(sx, sy)
			draw_circle(spos, sr * 2.2, Color(0.92, 0.90, 1.0, sa * 0.18))
			draw_circle(spos, sr, Color(1.0, 0.97, 0.90, sa))
			if bool(st["sparkle"]):
				var arm := sr * 2.6 * tw
				var sp_col := Color(1.0, 0.95, 0.82, sa * 0.48)
				draw_line(spos + Vector2(-arm, 0.0), spos + Vector2(arm, 0.0), sp_col, 1.0, true)
				draw_line(spos + Vector2(0.0, -arm), spos + Vector2(0.0, arm), sp_col, 1.0, true)

		# 3. Animated Geometric Golden Sun-Spire Astrolabe Emblem
		var center := Vector2(sz.x * 0.5, sz.y * 0.43)
		var sc := clampf(minf(sz.x / 1600.0, sz.y / 900.0), 0.65, 1.4)
		var radius := 155.0 * sc

		# Soft radial golden sun-bloom behind the central emblem
		var bloom_boost := lerpf(0.75, 1.25, progress)
		for b_i in range(16, 0, -1):
			var u := float(b_i) / 16.0
			var br := radius * (0.18 + u * 1.85)
			var ba := (1.0 - u) * (1.0 - u) * 0.032 * bloom_boost
			draw_circle(center, br, Color(1.0, 0.74, 0.30, ba))

		var gold_soft := Color(0.96, 0.78, 0.40, 0.46)
		var gold_faint := Color(0.94, 0.74, 0.36, 0.20)
		var gold_crisp := Color(1.0, 0.84, 0.44, 0.82)
		var bronze_muted := Color(0.58, 0.44, 0.28, 0.42)

		# Outer whisper halo arc & meridian guide lines
		draw_arc(center, radius * 1.10, 0.0, TAU, 72, gold_faint, 1.0, true)
		draw_line(center + Vector2(-radius * 1.22, 0.0), center + Vector2(-radius * 0.74, 0.0), gold_faint, 1.0, true)
		draw_line(center + Vector2(radius * 0.74, 0.0), center + Vector2(radius * 1.22, 0.0), gold_faint, 1.0, true)

		# Outer celestial ring (72 segments, thin crisp gold with 12 compass tick marks) rotating gently clockwise
		draw_arc(center, radius, 0.0, TAU, 72, gold_soft, 1.6, true)
		var outer_rot := _time * 0.16
		for i in range(12):
			var ang := outer_rot + float(i) * (TAU / 12.0)
			var dir := Vector2(cos(ang), sin(ang))
			var is_cardinal := (i % 3 == 0)
			var tick_in := radius - (11.0 if is_cardinal else 6.0) * sc
			var tick_out := radius + (5.0 if is_cardinal else 2.5) * sc
			var tick_col := gold_crisp if is_cardinal else gold_soft
			draw_line(center + dir * tick_in, center + dir * tick_out, tick_col, 1.5 if is_cardinal else 1.1, true)

		# Inner concentric ring with 4 cardinal diamond nodes rotating counter-clockwise
		var inner_r := radius * 0.68
		draw_arc(center, inner_r, 0.0, TAU, 72, Color(0.96, 0.78, 0.40, 0.34), 1.25, true)
		var inner_rot := -_time * 0.22
		for i in range(4):
			var ang := inner_rot + float(i) * (PI * 0.5)
			var node_pos := center + Vector2(cos(ang), sin(ang)) * inner_r
			_draw_diamond(node_pos, 4.8 * sc, Color(0.98, 0.82, 0.42, 0.85), Color(1.0, 0.92, 0.66, 0.95), 1.1)

		# Subtle inner astrolabe crescent arcs
		draw_arc(center, radius * 0.42, inner_rot + 0.25, inner_rot + PI - 0.25, 36, gold_faint, 1.0, true)
		draw_arc(center, radius * 0.42, inner_rot + PI + 0.25, inner_rot + TAU - 0.25, 36, gold_faint, 1.0, true)

		# Vertical central Golden Spire Axis that draws smoothly upward as progress goes 0.0 -> 1.0
		var axis_bottom := center.y + radius * 0.82
		var axis_top := center.y - radius * 0.80
		var axis_cur := lerpf(axis_bottom, axis_top, clampf(progress, 0.0, 1.0))

		# Unlit bronze axis track
		draw_line(Vector2(center.x, axis_bottom), Vector2(center.x, axis_top), bronze_muted, 1.6, true)

		# Lit ascending golden Spire Axis
		if progress > 0.002:
			draw_line(Vector2(center.x, axis_bottom), Vector2(center.x, axis_cur), Color(1.0, 0.76, 0.28, 0.26), 6.0 * sc, true)
			draw_line(Vector2(center.x, axis_bottom), Vector2(center.x, axis_cur), Color(1.0, 0.90, 0.52, 0.96), 2.4 * sc, true)

		# 6 Geometric Diamond Realm Pips spaced along the vertical Spire Axis (Realms I -> VI)
		var pip_bot := axis_bottom - 12.0 * sc
		var pip_top := axis_top + 22.0 * sc
		for i in range(6):
			var u := float(i) / 5.0
			var py := lerpf(pip_bot, pip_top, u)
			var pip_pos := Vector2(center.x, py)
			var thresh_start := float(i) / 6.0
			var thresh_end := float(i + 1) / 6.0
			var ignite := smoothstep(thresh_start, lerpf(thresh_start, thresh_end, 0.72), progress)

			if ignite > 0.01:
				draw_circle(pip_pos, 17.5 * sc * ignite, Color(1.0, 0.76, 0.26, 0.20 * ignite))
				draw_circle(pip_pos, 10.0 * sc * ignite, Color(1.0, 0.86, 0.42, 0.36 * ignite))

			var pip_r := lerpf(5.6, 7.8, ignite) * sc
			var fill_c := Color(0.32, 0.24, 0.18, 0.86).lerp(Color(1.0, 0.92, 0.58, 1.0), ignite)
			var rim_c := Color(0.68, 0.52, 0.34, 0.62).lerp(Color(1.0, 0.80, 0.32, 1.0), ignite)
			_draw_diamond(pip_pos, pip_r, fill_c, rim_c, 1.4)

		# Peak of the Spire Axis: Geometric Solstice Sun-Crown (concentric sun disc + 8 tapered golden sun-rays)
		var crown_pos := Vector2(center.x, axis_top - 10.0 * sc)
		var crown_bloom := smoothstep(0.65, 0.98, progress)
		var crown_base_a := lerpf(0.36, 1.0, crown_bloom)

		if crown_bloom > 0.01:
			draw_circle(crown_pos, 32.0 * sc * crown_bloom, Color(1.0, 0.78, 0.28, 0.24 * crown_bloom))
			draw_circle(crown_pos, 19.0 * sc * crown_bloom, Color(1.0, 0.88, 0.48, 0.40 * crown_bloom))

		var ray_rot := _time * 0.12
		for r_idx in range(8):
			var r_ang := ray_rot + float(r_idx) * (TAU / 8.0)
			var is_major_ray := (r_idx % 2 == 0)
			var r_dir := Vector2(cos(r_ang), sin(r_ang))
			var r_perp := Vector2(-r_dir.y, r_dir.x)
			var r_inner := (8.5 if is_major_ray else 7.5) * sc
			var r_outer := (lerpf(14.5, 23.0, crown_bloom) if is_major_ray else lerpf(11.5, 17.5, crown_bloom)) * sc
			var half_w := (2.3 if is_major_ray else 1.6) * sc
			var ray_pts := PackedVector2Array([
				crown_pos + r_dir * r_inner - r_perp * half_w,
				crown_pos + r_dir * r_outer,
				crown_pos + r_dir * r_inner + r_perp * half_w,
			])
			var ray_col := Color(0.76, 0.58, 0.34, 0.45).lerp(Color(1.0, 0.90, 0.52, 0.96), crown_bloom)
			draw_colored_polygon(ray_pts, ray_col)

		draw_arc(crown_pos, 7.2 * sc, 0.0, TAU, 32, Color(1.0, 0.86, 0.46, crown_base_a), 1.4, true)
		draw_circle(crown_pos, 4.4 * sc, Color(0.72, 0.56, 0.34, 0.65).lerp(Color(1.0, 0.96, 0.76, 1.0), crown_bloom))

		# 4. 32 Fine Drifting Golden Dust Specks (1.2px - 2.8px delicate rising motes)
		for d in _dust:
			var dx: float = (float(d["x"]) + sin(_time * float(d["sway_freq"]) + float(d["phase"])) * float(d["sway_amp"])) * sz.x
			var dy: float = float(d["y"]) * sz.y
			var dr: float = float(d["radius"]) * sc
			var pulse := 0.72 + 0.28 * sin(_time * 2.2 + float(d["phase"]))
			var da: float = float(d["alpha"]) * pulse
			var w: float = float(d["warmth"])
			var dpos := Vector2(dx, dy)
			draw_circle(dpos, dr * 1.9, Color(1.0, lerpf(0.72, 0.88, w), 0.34, da * 0.24))
			draw_circle(dpos, dr, Color(1.0, 0.95, 0.76, da * 0.88))

	func _draw_diamond(c: Vector2, r: float, fill_col: Color, border_col: Color, border_w: float = 1.2) -> void:
		var pts := PackedVector2Array([
			c + Vector2(0.0, -r),
			c + Vector2(r, 0.0),
			c + Vector2(0.0, r),
			c + Vector2(-r, 0.0),
		])
		draw_colored_polygon(pts, fill_col)
		var loop := PackedVector2Array([
			pts[0], pts[1], pts[2], pts[3], pts[0]
		])
		draw_polyline(loop, border_col, border_w, true)


var _canvas: MinimalSpireEmblemCanvas
var _whisper_label: Label
var _altitude_label: Label
var _progress_bar: ProgressBar
var _glow_tip: ColorRect

var _running: bool = false
var _finishing: bool = false
var _elapsed: float = 0.0
var _duration: float = 3.8
var _last_eased: float = 0.0
var _current_whisper_idx: int = -1
var _fade_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func _build_ui() -> void:
	_canvas = MinimalSpireEmblemCanvas.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_canvas)

	# Bottom-left editorial title lockup
	var lockup := VBoxContainer.new()
	lockup.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lockup.offset_left = 48
	lockup.offset_right = 740
	lockup.offset_top = -204
	lockup.offset_bottom = -64
	lockup.alignment = BoxContainer.ALIGNMENT_END
	lockup.add_theme_constant_override("separation", 4)
	lockup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lockup)

	var eyebrow := Label.new()
	eyebrow.text = "Six ascending realms · 1,085m"
	UITheme.apply_font(eyebrow, "semibold", 13, UITheme.INK_EYEBROW, 0.36, 1)
	lockup.add_child(eyebrow)

	var title := Label.new()
	title.text = "Solstice Spire"
	UITheme.apply_font(title, "heavy", 54, UITheme.INK_PRIMARY, 0.38, 2)
	lockup.add_child(title)

	_whisper_label = Label.new()
	_whisper_label.text = WHISPERS[0]
	UITheme.apply_font(_whisper_label, "semibold", 16, UITheme.INK_SECONDARY, 0.34, 1)
	lockup.add_child(_whisper_label)

	# Sleek bottom hairline 3px golden altitude progress track + right-aligned altitude readout
	var track_dock := VBoxContainer.new()
	track_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	track_dock.offset_left = 48
	track_dock.offset_right = -48
	track_dock.offset_top = -54
	track_dock.offset_bottom = -22
	track_dock.add_theme_constant_override("separation", 7)
	track_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(track_dock)

	var meta_row := HBoxContainer.new()
	meta_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_dock.add_child(meta_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_row.add_child(spacer)

	_altitude_label = Label.new()
	_altitude_label.text = "0m  →  1,085m"
	_altitude_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.apply_font(_altitude_label, "bold", 14, UITheme.ACCENT_AMBER, 0.34, 1)
	meta_row.add_child(_altitude_label)

	var bar_holder := Control.new()
	bar_holder.custom_minimum_size = Vector2(0, 5)
	bar_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_dock.add_child(bar_holder)

	_progress_bar = ProgressBar.new()
	_progress_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_progress_bar.offset_top = 1
	_progress_bar.offset_bottom = -1
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var track_bg := StyleBoxFlat.new()
	track_bg.bg_color = Color(0.98, 0.94, 0.86, 0.16)
	track_bg.set_corner_radius_all(2)
	var track_fill := StyleBoxFlat.new()
	track_fill.bg_color = UITheme.ACCENT_AMBER
	track_fill.set_corner_radius_all(2)
	_progress_bar.add_theme_stylebox_override("background", track_bg)
	_progress_bar.add_theme_stylebox_override("fill", track_fill)
	bar_holder.add_child(_progress_bar)

	_glow_tip = ColorRect.new()
	_glow_tip.color = Color(1.0, 0.94, 0.68, 0.95)
	_glow_tip.custom_minimum_size = Vector2(6, 5)
	_glow_tip.size = Vector2(6, 5)
	_glow_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_holder.add_child(_glow_tip)
	_progress_bar.resized.connect(_update_glow_tip_pos)


func start_loading(duration_sec: float = 3.8) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	_duration = maxf(duration_sec, 0.2)
	_elapsed = 0.0
	_running = true
	_finishing = false
	_current_whisper_idx = -1
	visible = true
	modulate.a = 1.0
	_apply_progress(0.0)


func skip_immediate() -> void:
	_running = false
	_finishing = false
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	visible = false
	modulate.a = 0.0


func set_preview_progress(p: float) -> void:
	## Deterministic visual preview helper (used by GauntletRunner).
	_running = false
	_finishing = false
	visible = true
	modulate.a = 1.0
	_canvas.advance(1.6)
	_apply_progress(clampf(p, 0.0, 1.0))


func _process(delta: float) -> void:
	if not visible:
		return
	_canvas.advance(delta)
	if not _running or _finishing:
		return
	_elapsed += delta
	var lin_t := clampf(_elapsed / _duration, 0.0, 1.0)
	_apply_progress(lin_t)
	if lin_t >= 1.0:
		_complete_loading()


func _apply_progress(lin_t: float) -> void:
	# Cubic ease-in-out for altitude bar & Golden Spire Axis ascent
	var eased := (4.0 * lin_t * lin_t * lin_t) if lin_t < 0.5 else (1.0 - pow(-2.0 * lin_t + 2.0, 3.0) * 0.5)
	_last_eased = eased
	_progress_bar.value = eased
	_canvas.progress = eased
	_canvas.queue_redraw()

	var alt_m := int(round(eased * GameState.SUMMIT_ALTITUDE))
	_altitude_label.text = "%s  →  1,085m" % _format_meters(alt_m)

	_update_glow_tip_pos()

	# Poetic whisper stage
	var w_idx := 0 if lin_t < 0.34 else (1 if lin_t < 0.68 else 2)
	if w_idx != _current_whisper_idx:
		_current_whisper_idx = w_idx
		_whisper_label.text = WHISPERS[w_idx]
		_whisper_label.modulate.a = 0.0
		var wtw := _whisper_label.create_tween()
		wtw.tween_property(_whisper_label, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _update_glow_tip_pos() -> void:
	if _progress_bar == null or _glow_tip == null:
		return
	var bar_w := _progress_bar.size.x
	_glow_tip.position = Vector2(clampf(bar_w * _last_eased - 3.0, 0.0, maxf(bar_w - 6.0, 0.0)), 0.0)


func _format_meters(m: int) -> String:
	if m >= 1000:
		return "%d,%03dm" % [m / 1000, m % 1000]
	return "%dm" % m


func _complete_loading() -> void:
	_running = false
	_finishing = true
	loading_finished.emit()
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_callback(func():
		visible = false
		_finishing = false
	)
