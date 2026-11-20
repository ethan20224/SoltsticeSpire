extends StaticBody3D
class_name WallRunSurface
## Tagged runnable wall surface (World 2 Musical Bronze Bells, World 4 Mirror Panels, World 6 Obsidian Monoliths).
## Responds to wall-run contact & wall-kicks with physical ring sway and musical chimes!

@export var is_musical_bell: bool = false
@export var bell_note_step: int = 0

var _visual: Node3D
var _sway_t: float = 0.0


func _ready() -> void:
	add_to_group("wall_run")
	_visual = get_node_or_null("Visual")


func on_wall_run_contact() -> void:
	if is_musical_bell:
		_sway_t = 0.5
		AudioDirector.play_bell_ring(bell_note_step)


func on_wall_kick() -> void:
	_sway_t = 1.0
	if is_musical_bell:
		AudioDirector.play_bell_ring(bell_note_step + 2)
	else:
		AudioDirector.play_sfx("wall_kick", -1.0, randf_range(0.98, 1.12))


func _process(delta: float) -> void:
	if _sway_t > 0.001:
		_sway_t = maxf(0.0, _sway_t - delta * 2.2)
		if _visual and is_musical_bell:
			_visual.rotation.z = sin(_sway_t * PI * 5.0) * _sway_t * 0.14
	elif _visual and is_musical_bell:
		_visual.rotation.z = 0.0
