extends Control
class_name LoadingScreenUI
## Bespoke 3.8s Storybook Loading Screen for Solstice Spire.
## Crossfades two 16:9 painterly key-art paintings with Ken Burns drift, soft radial/linear
## vignette scrims, procedural golden bokeh ember motes, editorial typography, and an altitude track.

signal loading_finished()

const ART_1_PATH := "res://assets/textures/loading/loading_art_1.png"
const ART_2_PATH := "res://assets/textures/loading/loading_art_2.png"
const WHISPERS: Array[String] = [
	"Awakening the sky shrines...",
	"Tuning the bronze bells...",
	"Charting the summit winds...",
]


class EmberMotesLayer extends Control:
	var _motes: Array[Dictionary] = []
	var _time: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261121
		for i in range(28):
			_motes.append({
				"x": rng.randf(),
				"y": rng.randf(),
				"vy": rng.randf_range(0.022, 0.058),
				"sway_amp": rng.randf_range(0.008, 0.024),
				"sway_freq": rng.randf_range(0.6, 1.4),
				"phase": rng.randf_range(0.0, TAU),
				"radius": rng.randf_range(3.5, 11.5),
				"alpha": rng.randf_range(0.28, 0.72),
				"warmth": rng.randf(),
			})

	func advance(delta: float) -> void:
		_time += delta
		for m in _motes:
			var ny: float = float(m["y"]) - float(m["vy"]) * delta
			if ny < -0.06:
				ny = 1.06
			m["y"] = ny
		queue_redraw()

	func _draw() -> void:
		var sz := size
		if sz.x <= 1.0 or sz.y <= 1.0:
			return
		for m in _motes:
			var px: float = (float(m["x"]) + sin(_time * float(m["sway_freq"]) + float(m["phase"])) * float(m["sway_amp"])) * sz.x
			var py: float = float(m["y"]) * sz.y
			var r: float = float(m["radius"])
			var pulse := 0.75 + 0.25 * sin(_time * 2.1 + float(m["phase"]))
			var a: float = float(m["alpha"]) * pulse
			var warmth: float = float(m["warmth"])
			var halo_col := Color(1.0, lerpf(0.68, 0.86, warmth), lerpf(0.22, 0.44, warmth), a * 0.20)
			var mid_col := Color(1.0, lerpf(0.76, 0.90, warmth), lerpf(0.30, 0.54, warmth), a * 0.46)
			var core_col := Color(1.0, 0.96, 0.78, a * 0.90)
			draw_circle(Vector2(px, py), r * 2.1, halo_col)
			draw_circle(Vector2(px, py), r * 1.05, mid_col)
			draw_circle(Vector2(px, py), maxf(r * 0.36, 1.4), core_col)


var _art_clip: Control
var _art1_rect: TextureRect
var _art2_rect: TextureRect
var _whisper_label: Label
var _altitude_label: Label
var _progress_bar: ProgressBar
var _glow_tip: ColorRect
var _embers: EmberMotesLayer

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
	var base_bg := ColorRect.new()
	base_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base_bg.color = Color(0.05, 0.04, 0.06, 1.0)
	add_child(base_bg)

	_art_clip = Control.new()
	_art_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art_clip.clip_contents = true
	_art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_clip)

	_art1_rect = _make_art_layer(ART_1_PATH, 1.0)
	_art_clip.add_child(_art1_rect)

	_art2_rect = _make_art_layer(ART_2_PATH, 0.0)
	_art_clip.add_child(_art2_rect)

	# Soft top linear vignette scrim
	var top_scrim := _make_linear_scrim(Color(0.04, 0.03, 0.05, 0.56), Color(0.04, 0.03, 0.05, 0.0))
	top_scrim.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_scrim.offset_bottom = 220
	add_child(top_scrim)

	# Soft bottom linear vignette scrim
	var bot_scrim := _make_linear_scrim(Color(0.04, 0.03, 0.05, 0.0), Color(0.04, 0.03, 0.05, 0.86))
	bot_scrim.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot_scrim.offset_top = -340
	add_child(bot_scrim)

	# Soft radial corner scrim behind bottom-left editorial lockup
	var corner_scrim := UITheme.make_radial_scrim(Vector2(760, 320), Vector2(0.28, 0.70), 0.62, Color(0.04, 0.03, 0.05))
	corner_scrim.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	corner_scrim.offset_left = 0
	corner_scrim.offset_top = -320
	corner_scrim.offset_right = 760
	corner_scrim.offset_bottom = 0
	add_child(corner_scrim)

	# Drifting golden bokeh firefly motes
	_embers = EmberMotesLayer.new()
	_embers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_embers)

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

	# Sleek bottom golden altitude progress track + right-aligned altitude readout
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
	bar_holder.custom_minimum_size = Vector2(0, 8)
	bar_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_dock.add_child(bar_holder)

	_progress_bar = ProgressBar.new()
	_progress_bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_progress_bar.offset_top = 2
	_progress_bar.offset_bottom = -2
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var track_bg := StyleBoxFlat.new()
	track_bg.bg_color = Color(0.98, 0.94, 0.86, 0.16)
	track_bg.set_corner_radius_all(3)
	var track_fill := StyleBoxFlat.new()
	track_fill.bg_color = UITheme.ACCENT_AMBER
	track_fill.set_corner_radius_all(3)
	_progress_bar.add_theme_stylebox_override("background", track_bg)
	_progress_bar.add_theme_stylebox_override("fill", track_fill)
	bar_holder.add_child(_progress_bar)

	_glow_tip = ColorRect.new()
	_glow_tip.color = Color(1.0, 0.94, 0.68, 0.95)
	_glow_tip.custom_minimum_size = Vector2(8, 8)
	_glow_tip.size = Vector2(8, 8)
	_glow_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_holder.add_child(_glow_tip)
	_progress_bar.resized.connect(_update_glow_tip_pos)


func _make_art_layer(res_path: String, init_alpha: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.modulate.a = init_alpha
	if ResourceLoader.exists(res_path):
		tr.texture = load(res_path) as Texture2D
	return tr


func _make_linear_scrim(top_col: Color, bot_col: Color) -> TextureRect:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([top_col, bot_col])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 64
	tex.height = 128

	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


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
	_embers.advance(1.6)
	_apply_progress(clampf(p, 0.0, 1.0))


func _process(delta: float) -> void:
	if not visible:
		return
	_embers.advance(delta)
	if not _running or _finishing:
		return
	_elapsed += delta
	var lin_t := clampf(_elapsed / _duration, 0.0, 1.0)
	_apply_progress(lin_t)
	if lin_t >= 1.0:
		_complete_loading()


func _apply_progress(lin_t: float) -> void:
	# Cubic ease-in-out for altitude bar & smooth Ken Burns drift
	var eased := (4.0 * lin_t * lin_t * lin_t) if lin_t < 0.5 else (1.0 - pow(-2.0 * lin_t + 2.0, 3.0) * 0.5)
	_last_eased = eased
	_progress_bar.value = eased

	var alt_m := int(round(eased * GameState.SUMMIT_ALTITUDE))
	_altitude_label.text = "%s  →  1,085m" % _format_meters(alt_m)

	_update_glow_tip_pos()

	# Ken Burns zoom & gentle crossfade from Art 1 -> Art 2 around halfway
	var blend_2 := smoothstep(0.38, 0.62, lin_t)
	_art1_rect.modulate.a = 1.0 - blend_2
	_art2_rect.modulate.a = blend_2

	_art1_rect.pivot_offset = _art1_rect.size * 0.5
	_art1_rect.scale = Vector2.ONE * lerpf(1.00, 1.07, lin_t)
	_art1_rect.position = Vector2(lerpf(-6.0, 8.0, lin_t), lerpf(4.0, -5.0, lin_t))

	_art2_rect.pivot_offset = _art2_rect.size * 0.5
	_art2_rect.scale = Vector2.ONE * lerpf(1.02, 1.08, maxf(0.0, lin_t - 0.25) / 0.75)
	_art2_rect.position = Vector2(lerpf(8.0, -6.0, lin_t), lerpf(-4.0, 4.0, lin_t))

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
	_glow_tip.position = Vector2(clampf(bar_w * _last_eased - 4.0, 0.0, maxf(bar_w - 8.0, 0.0)), 0.0)


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
