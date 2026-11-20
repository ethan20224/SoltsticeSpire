extends StaticBody3D
class_name CrumblingTile
## Fragile mossy flagstone (W1) or iridescent shattering crystal pane (W4/W6).
## Telegraphs visually with tremble + glowing cracks, shatters cleanly, and reforms after respawn_delay.

@export var break_delay: float = 0.85
@export var respawn_delay: float = 3.2
@export var is_crystal: bool = false
@export var tile_size: Vector3 = Vector3(3.4, 0.45, 3.4)

var _triggered: bool = false
var _broken: bool = false
var _timer: float = 0.0
var _visual: Node3D
var _col: CollisionShape3D
var _shader_mats: Array[ShaderMaterial] = []
var _base_vis_pos: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("crumbling_tile")
	_visual = get_node_or_null("Visual")
	_col = get_node_or_null("CollisionShape3D")
	if _visual:
		_base_vis_pos = _visual.position
		_collect_shader_mats(_visual)

	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var c := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(tile_size.x + 0.25, 0.8, tile_size.z + 0.25)
	c.shape = bx
	c.position = Vector3(0.0, tile_size.y * 0.5 + 0.28, 0.0)
	area.add_child(c)
	add_child(area)
	area.body_entered.connect(_on_stepped)


func _collect_shader_mats(n: Node) -> void:
	if n is MeshInstance3D:
		if n.material_override is ShaderMaterial:
			var dup := n.material_override.duplicate() as ShaderMaterial
			n.material_override = dup
			_shader_mats.append(dup)
	for ch in n.get_children():
		_collect_shader_mats(ch)


func _on_stepped(body: Node3D) -> void:
	if _triggered or _broken or not body.is_in_group("player"):
		return
	_triggered = true
	_timer = break_delay
	AudioDirector.play_sfx("crystal_crack" if is_crystal else "step_stone", -2.5, 1.05)


func _process(delta: float) -> void:
	if _triggered and not _broken:
		_timer -= delta
		var progress := clampf(1.0 - (_timer / maxf(break_delay, 0.05)), 0.0, 1.0)
		for sm in _shader_mats:
			sm.set_shader_parameter("crack_amount", progress)
		if _visual:
			var mag := progress * 0.14
			_visual.position = _base_vis_pos + Vector3(randf_range(-mag, mag), randf_range(-mag * 0.5, mag * 0.5), randf_range(-mag, mag))
		if _timer <= 0.0:
			_shatter()
	elif _broken:
		_timer -= delta
		if _timer <= 0.0:
			_reform()


func _shatter() -> void:
	_broken = true
	_triggered = false
	_timer = respawn_delay
	if _visual:
		_visual.visible = false
		_visual.position = _base_vis_pos
	if _col:
		_col.disabled = true
	AudioDirector.play_sfx("crystal_shatter" if is_crystal else "land_thud", -2.0, randf_range(0.92, 1.12))


func _reform() -> void:
	_broken = false
	for sm in _shader_mats:
		sm.set_shader_parameter("crack_amount", 0.0)
	if _visual:
		_visual.visible = true
		_visual.scale = Vector3(0.2, 0.2, 0.2)
		var tw := create_tween()
		tw.tween_property(_visual, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _col:
		_col.disabled = false
