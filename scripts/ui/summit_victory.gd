extends Control
class_name SummitVictoryUI
## Celebratory Summit Crown Victory Card framing the panoramic overlook across all 6 worlds below.

signal explore_summit_requested()
signal climb_again_requested()

var _dock: PanelContainer
var _val_time: Label
var _val_falls: Label
var _val_shards: Label
var _val_flow: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()


func _build_ui() -> void:
	_dock = PanelContainer.new()
	_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dock.offset_left = 340
	_dock.offset_right = -340
	_dock.offset_top = -265
	_dock.offset_bottom = -34
	_dock.add_theme_stylebox_override("panel", UITheme.glass_box(UITheme.SURFACE_SOLID, Color(0.98, 0.78, 0.34, 0.45), 26, 30, 22, 1))
	add_child(_dock)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	_dock.add_child(v)

	var eyebrow := Label.new()
	eyebrow.text = "1,085m Summit Reached"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(eyebrow, "semibold", 13, UITheme.INK_SECONDARY)
	v.add_child(eyebrow)

	var title := Label.new()
	title.text = "The Crown of the Sun"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(title, "heavy", 36, UITheme.INK_PRIMARY)
	v.add_child(title)

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 38)
	v.add_child(stats)
	_val_time = _add_stat(stats, "Time", "00:00.00")
	_val_falls = _add_stat(stats, "Falls", "0")
	_val_shards = _add_stat(stats, "Sun-Shards", "0 / 18")
	_val_flow = _add_stat(stats, "Peak Flow", "x0")

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)

	var explore_btn := Button.new()
	explore_btn.text = "Explore Summit"
	explore_btn.custom_minimum_size = Vector2(196, 48)
	UITheme.style_secondary_pill(explore_btn, false, 15)
	explore_btn.pressed.connect(func():
		visible = false
		explore_summit_requested.emit()
	)
	row.add_child(explore_btn)

	var replay_btn := Button.new()
	replay_btn.text = "Climb Again"
	replay_btn.custom_minimum_size = Vector2(196, 48)
	UITheme.style_primary_cta(replay_btn, 16)
	replay_btn.pressed.connect(func():
		visible = false
		climb_again_requested.emit()
	)
	row.add_child(replay_btn)


func _add_stat(parent: HBoxContainer, lbl: String, init_val: String) -> Label:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	var vl := Label.new()
	vl.text = init_val
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(vl, "bold", 22, UITheme.INK_PRIMARY)
	var kl := Label.new()
	kl.text = lbl
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(kl, "medium", 12, UITheme.INK_SECONDARY)
	box.add_child(vl)
	box.add_child(kl)
	parent.add_child(box)
	return vl


func show_stats(run_time: float, falls: int, shards: int, max_streak: int) -> void:
	_val_time.text = GameState.format_time(run_time)
	_val_falls.text = str(falls)
	_val_shards.text = "%d / 18" % shards
	_val_flow.text = "x%d" % max_streak
	visible = true
	UITheme.animate_enter(_dock, 0.0, 0.28)
