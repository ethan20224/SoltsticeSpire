extends AnimatableBody3D
class_name SpinningGear
## Rotating clockwork gear platform that carries the player seamlessly using sync_to_physics.

@export var angular_speed_deg: float = 28.0
@export var spin_axis: Vector3 = Vector3.UP


func _ready() -> void:
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	rotate(spin_axis.normalized(), deg_to_rad(angular_speed_deg) * delta)
