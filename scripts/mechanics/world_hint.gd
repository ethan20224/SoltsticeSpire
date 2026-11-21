extends Node3D
class_name WorldHint
## Tasteful floating 3D in-world onboarding prompt with Y-billboarded crisp typography,
## gentle vertical hover, proximity & climb-past fade, and live InputManager glyph substitution.

const FALLBACK_GLYPHS := {
	"move": "WASD",
	"jump": "SPACE",
	"dash": "E / RMB",
	"slide": "C / CTRL",
	"sprint": "SHIFT",
	"rewind": "R",
}

@export var hint_title: String = ""
@export var hint_template: String = ""
@export var fade_in_dist: float = 15.0
@export var fade_out_dist: float = 19.0
@export var climb_hide_dy: float = 12.0

var _pivot: Node3D
var _title_label: Label3D
var _body_label: Label3D
var _player_ref: Node3D
var _t: float = 0.0
var _alpha: float = 0.0


func _ready() -> void:
	add_to_group("world_hint")
	_build_labels()
	refresh_prompt()
	_bind_input_manager()
	_apply_alpha(0.0)


func _build_labels() -> void:
	_pivot = Node3D.new()
	_pivot.name = "HintPivot"
	add_child(_pivot)

	_title_label = Label3D.new()
	_title_label.position = Vector3(0.0, 0.24, 0.0)
	_title_label.font = UITheme.font("extrabold")
	_title_label.font_size = 34
	_title_label.pixel_size = 0.0040
	_title_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_title_label.shaded = false
	_title_label.no_depth_test = false
	_title_label.outline_size = 9
	_title_label.modulate = Color(1.0, 0.88, 0.46, 0.0)
	_title_label.outline_modulate = Color(0.11, 0.07, 0.04, 0.0)
	_pivot.add_child(_title_label)

	_body_label = Label3D.new()
	_body_label.position = Vector3(0.0, 0.0, 0.0)
	_body_label.font = UITheme.font("semibold")
	_body_label.font_size = 24
	_body_label.pixel_size = 0.0038
	_body_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_body_label.shaded = false
	_body_label.no_depth_test = false
	_body_label.outline_size = 7
	_body_label.modulate = Color(0.99, 0.96, 0.89, 0.0)
	_body_label.outline_modulate = Color(0.10, 0.06, 0.04, 0.0)
	_pivot.add_child(_body_label)


func _bind_input_manager() -> void:
	var im := get_node_or_null("/root/InputManager")
	if im == null:
		return
	_connect_input_signal(im, "input_mode_changed")
	_connect_input_signal(im, "gamepad_changed")


func _connect_input_signal(im: Node, sig_name: String) -> void:
	if not im.has_signal(sig_name):
		return
	var arg_count := 0
	for sig_info_v: Variant in im.get_signal_list():
		var sig_info: Dictionary = sig_info_v as Dictionary
		if str(sig_info.get("name", "")) == sig_name:
			var args_v: Variant = sig_info.get("args", [])
			if typeof(args_v) == TYPE_ARRAY:
				arg_count = (args_v as Array).size()
			break
	match arg_count:
		0:
			im.connect(sig_name, func() -> void: refresh_prompt())
		1:
			im.connect(sig_name, func(_a: Variant) -> void: refresh_prompt())
		2:
			im.connect(sig_name, func(_a: Variant, _b: Variant) -> void: refresh_prompt())
		_:
			im.connect(sig_name, func(_a: Variant, _b: Variant, _c: Variant) -> void: refresh_prompt())


func _resolve_glyph(action_key: String) -> String:
	var im := get_node_or_null("/root/InputManager")
	if im != null and im.has_method("get_glyph"):
		var val: Variant = im.call("get_glyph", action_key)
		var glyph := str(val).strip_edges()
		if not glyph.is_empty():
			return glyph
	return str(FALLBACK_GLYPHS.get(action_key, action_key.to_upper()))


func refresh_prompt() -> void:
	if is_instance_valid(_title_label):
		_title_label.text = hint_title
		_title_label.visible = not hint_title.is_empty()
	if is_instance_valid(_body_label):
		var resolved := hint_template
		for key_v: Variant in FALLBACK_GLYPHS.keys():
			var action_key := str(key_v)
			var token := "{%s}" % action_key
			if resolved.contains(token):
				resolved = resolved.replace(token, _resolve_glyph(action_key))
		_body_label.text = resolved


func _apply_alpha(a: float) -> void:
	var clamped := clampf(a, 0.0, 1.0)
	if is_instance_valid(_pivot):
		_pivot.visible = clamped > 0.01
	if is_instance_valid(_title_label):
		_title_label.modulate = Color(1.0, 0.88, 0.46, clamped)
		_title_label.outline_modulate = Color(0.11, 0.07, 0.04, clamped * 0.90)
	if is_instance_valid(_body_label):
		_body_label.modulate = Color(0.99, 0.96, 0.89, clamped * 0.96)
		_body_label.outline_modulate = Color(0.10, 0.06, 0.04, clamped * 0.88)


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_pivot):
		_pivot.position.y = sin(_t * 1.85) * 0.11

	if not is_instance_valid(_player_ref):
		var found := get_tree().get_first_node_in_group("player")
		if found is Node3D:
			_player_ref = found as Node3D

	var target_alpha := 0.0
	if is_instance_valid(_player_ref) and not GameState.is_cutscene:
		var gameplay_visible := GameState.is_playing or _player_ref.visible
		if gameplay_visible:
			var ppos := _player_ref.global_position
			var climbed_past := ppos.y > global_position.y + climb_hide_dy
			if not climbed_past:
				var dist := ppos.distance_to(global_position)
				if dist <= fade_in_dist:
					target_alpha = 1.0
				elif dist < fade_out_dist:
					var span := maxf(fade_out_dist - fade_in_dist, 0.1)
					target_alpha = 1.0 - clampf((dist - fade_in_dist) / span, 0.0, 1.0)
				# Softly fade if directly inside the player's camera lens or far off-center
				if dist < 3.0:
					target_alpha *= clampf((dist - 1.2) / 1.8, 0.0, 1.0)

	_alpha = lerpf(_alpha, target_alpha, clampf(delta * 5.5, 0.0, 1.0))
	_apply_alpha(_alpha)
