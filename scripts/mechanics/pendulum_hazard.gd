extends AnimatableBody3D
class_name PendulumHazard
## World 2 Cathedral Swinging Pendulum - sweeps smoothly on a harmonic arc;
## can be jumped over or daringly ridden across its top beam.

@export var swing_angle_deg: float = 34.0
@export var swing_speed: float = 1.65
@export var phase_offset: float = 0.0
@export var swing_axis: Vector3 = Vector3(0.0, 0.0, 1.0)

var _t: float = 0.0
var _base_rot: Vector3


func _ready() -> void:
	sync_to_physics = true
	_base_rot = rotation


func _physics_process(delta: float) -> void:
	_t += delta
	var ang := sin(_t * swing_speed + phase_offset) * deg_to_rad(swing_angle_deg)
	rotation = _base_rot + swing_axis.normalized() * ang
