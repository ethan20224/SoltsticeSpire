extends RefCounted
class_name UITheme
## Cohesive AAA-Indie UI Design System for Solstice Spire.
## Legally ships OFL Nunito variable font (Black/ExtraBold display, SemiBold/Medium body),
## warm espresso-ivory-amber palette, soft radial scrims (zero harsh outlines), and crisp 110-220ms TRANS_EXPO motion.

const FONT_NUNITO := "res://assets/fonts/Nunito.ttf"
const AXIS_WGHT := 0x77676874  # OpenType 'wght' tag for variable Nunito font

# Warm Toybox-Dreamcore Palette (warm walnut-espresso + soft cream ivory + sunlit honey-amber)
const SURFACE_GLASS := Color(0.09, 0.075, 0.088, 0.78)
const SURFACE_SOLID := Color(0.10, 0.085, 0.100, 0.94)
const SURFACE_HOVER := Color(0.13, 0.112, 0.128, 0.86)
const SURFACE_CREAM := Color(0.98, 0.95, 0.89, 0.96)
const SURFACE_CREAM_HOVER := Color(1.0, 0.98, 0.94, 0.98)
const BORDER_SUBTLE := Color(0.96, 0.88, 0.72, 0.22)
const BORDER_HOVER := Color(0.98, 0.92, 0.80, 0.56)
const BORDER_CREAM_LIP := Color(0.76, 0.71, 0.62, 1.0)

const INK_PRIMARY := Color(0.99, 0.97, 0.93, 1.0)
const INK_SECONDARY := Color(0.87, 0.83, 0.77, 0.92)
const INK_EYEBROW := Color(1.0, 0.82, 0.44, 0.95)
const INK_DARK := Color(0.12, 0.08, 0.05, 1.0)

const ACCENT_AMBER := Color(0.98, 0.74, 0.24, 1.0)
const ACCENT_AMBER_HOVER := Color(1.0, 0.82, 0.40, 1.0)
const ACCENT_AMBER_LIP := Color(0.72, 0.46, 0.10, 1.0)
const ACCENT_PILL_BG := Color(0.96, 0.70, 0.24, 0.96)

static var _base_font: FontFile
static var _font_cache: Dictionary = {}


static func clear_caches() -> void:
	_font_cache.clear()
	_base_font = null


static func font(weight: String = "semibold") -> Font:
	if _font_cache.has(weight):
		return _font_cache[weight]
	if _base_font == null and ResourceLoader.exists(FONT_NUNITO):
		_base_font = load(FONT_NUNITO) as FontFile
	if _base_font == null:
		return ThemeDB.fallback_font

	var wght := 600
	match weight:
		"heavy", "black":
			wght = 900
		"extrabold":
			wght = 800
		"bold":
			wght = 700
		"semibold":
			wght = 600
		"medium":
			wght = 500

	var fv := FontVariation.new()
	fv.base_font = _base_font
	fv.variation_opentype = {AXIS_WGHT: wght}
	_font_cache[weight] = fv
	return fv


static func apply_font(ctrl: Control, weight: String, size: int, color: Color = INK_PRIMARY,
		shadow_alpha: float = 0.0, shadow_y: int = 2) -> void:
	## Clean typographic hierarchy: soft subtle shadow (alpha <= 0.38, ZERO jaggy outline!)
	ctrl.add_theme_font_override("font", font(weight))
	ctrl.add_theme_font_size_override("font_size", size)
	ctrl.add_theme_color_override("font_color", color)
	if shadow_alpha > 0.0 and ctrl is Label:
		ctrl.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.06, minf(shadow_alpha, 0.40)))
		ctrl.add_theme_constant_override("shadow_offset_y", shadow_y)
		ctrl.add_theme_constant_override("shadow_offset_x", 0)
		ctrl.add_theme_constant_override("shadow_outline_size", 0)


static func make_radial_scrim(size_px: Vector2, center_uv: Vector2 = Vector2(0.5, 0.5),
		max_alpha: float = 0.50, tint: Color = Color(0.05, 0.04, 0.07)) -> TextureRect:
	## Soft atmospheric gradient scrim fading strictly to alpha=0 before box bounds (ZERO visible rectangle edge!)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 0.94])
	grad.colors = PackedColorArray([
		Color(tint.r, tint.g, tint.b, max_alpha),
		Color(tint.r, tint.g, tint.b, max_alpha * 0.40),
		Color(tint.r, tint.g, tint.b, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = center_uv
	var rad_uv := minf(minf(center_uv.x, 1.0 - center_uv.x), minf(center_uv.y, 1.0 - center_uv.y))
	tex.fill_to = Vector2(center_uv.x + maxf(rad_uv * 0.96, 0.24), center_uv.y)
	tex.width = 256
	tex.height = 128

	var scrim_rect := TextureRect.new()
	scrim_rect.texture = tex
	scrim_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim_rect.stretch_mode = TextureRect.STRETCH_SCALE
	scrim_rect.custom_minimum_size = size_px
	scrim_rect.size = size_px
	scrim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return scrim_rect


static func glass_box(bg: Color = SURFACE_GLASS, border: Color = BORDER_SUBTLE,
		radius: int = 18, pad_x: int = 18, pad_y: int = 10, border_w: int = 1, bottom_lip: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = border_w
	sb.border_width_right = border_w
	sb.border_width_top = border_w
	sb.border_width_bottom = bottom_lip if bottom_lip > 0 else border_w
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	sb.shadow_color = Color(0.04, 0.03, 0.05, 0.30)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	return sb


static func make_realm_pill(text_str: String) -> PanelContainer:
	## THE SOLE uppercase pill badge in the UI: used exclusively for the Realm Numeral (REALM I..VI)!
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = ACCENT_PILL_BG
	sb.set_corner_radius_all(999)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0.05, 0.04, 0.06, 0.24)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	p.add_theme_stylebox_override("panel", sb)

	var l := Label.new()
	l.name = "BadgeLabel"
	l.text = text_str
	apply_font(l, "extrabold", 11, INK_DARK)
	p.add_child(l)
	return p


static func style_primary_cta(btn: Button, font_size: int = 16) -> void:
	## Sole honey-amber tactile CTA with 3D bottom lip & dark espresso ink!
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", font("extrabold"))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", INK_DARK)
	btn.add_theme_color_override("font_hover_color", INK_DARK)
	btn.add_theme_color_override("font_pressed_color", INK_DARK)
	btn.add_theme_stylebox_override("normal", glass_box(ACCENT_AMBER, ACCENT_AMBER_LIP, 999, 26, 12, 1, 4))
	btn.add_theme_stylebox_override("hover", glass_box(ACCENT_AMBER_HOVER, ACCENT_AMBER_LIP, 999, 26, 12, 1, 4))
	btn.add_theme_stylebox_override("pressed", glass_box(Color(0.88, 0.64, 0.18), ACCENT_AMBER_LIP, 999, 26, 13, 1, 2))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	attach_tactile_motion(btn)


static func style_secondary_pill(btn: Button, active: bool = false, font_size: int = 15) -> void:
	## Clear visual hierarchy:
	## - Active/selected chip: light warm cream fill + dark espresso ink (never competes with amber CTA!)
	## - Unselected hover: subtle border brighten only (never mimics selected state!)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_override("font", font("extrabold" if active else "semibold"))
	btn.add_theme_font_size_override("font_size", font_size)
	if active:
		btn.add_theme_color_override("font_color", INK_DARK)
		btn.add_theme_color_override("font_hover_color", INK_DARK)
		btn.add_theme_color_override("font_pressed_color", INK_DARK)
		btn.add_theme_stylebox_override("normal", glass_box(SURFACE_CREAM, BORDER_CREAM_LIP, 999, 20, 11, 1, 3))
		btn.add_theme_stylebox_override("hover", glass_box(SURFACE_CREAM_HOVER, BORDER_CREAM_LIP, 999, 20, 11, 1, 3))
		btn.add_theme_stylebox_override("pressed", glass_box(Color(0.90, 0.86, 0.79, 0.96), BORDER_CREAM_LIP, 999, 20, 12, 1, 2))
	else:
		btn.add_theme_color_override("font_color", INK_SECONDARY)
		btn.add_theme_color_override("font_hover_color", INK_PRIMARY)
		btn.add_theme_color_override("font_pressed_color", INK_PRIMARY)
		btn.add_theme_stylebox_override("normal", glass_box(SURFACE_GLASS, BORDER_SUBTLE, 999, 20, 11, 1, 2))
		btn.add_theme_stylebox_override("hover", glass_box(SURFACE_HOVER, BORDER_HOVER, 999, 20, 11, 1, 2))
		btn.add_theme_stylebox_override("pressed", glass_box(SURFACE_SOLID, BORDER_HOVER, 999, 20, 11, 1, 1))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	attach_tactile_motion(btn)


static func attach_tactile_motion(btn: Button) -> void:
	## Tactile button press: scale(0.96) in 100ms ease-out-expo, subtle hover lift!
	if btn.has_meta("_tactile_bound"):
		return
	btn.set_meta("_tactile_bound", true)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.022, 1.022), 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.02, 1.02) if btn.is_hovered() else Vector2.ONE, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	)


static func animate_enter(ctrl: Control, delay_s: float = 0.0, dur_s: float = 0.24) -> void:
	## Natural scale(0.95) + opacity 0 -> 1.0 entrance (never scale(0), never ease-in!)
	ctrl.pivot_offset = ctrl.size * 0.5
	ctrl.scale = Vector2(0.95, 0.95)
	ctrl.modulate.a = 0.0
	var tw := ctrl.create_tween().set_parallel(true)
	if delay_s > 0.0:
		tw.tween_interval(delay_s)
	tw.chain().tween_property(ctrl, "scale", Vector2.ONE, dur_s).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ctrl, "modulate:a", 1.0, dur_s * 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
