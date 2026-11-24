extends AnimatableBody3D
class_name PendulumHazard
## World 2 Cathedral Swinging Pendulum - sweeps smoothly on a harmonic arc;
## can be jumped over or daringly ridden across its top beam.

@export var swing_angle_deg: float = 34.0
@export var swing_speed: float = 1.65
@export var phase_offset: float = 0.0
@export var swing_axis: Vector3 = Vector3(0.0, 0.0, 1.0)
@export var knockback_force: float = 13.5

var _t: float = 0.0
var _base_rot: Vector3
var _prev_ang: float = 0.0
var _ang_vel: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	_base_rot = rotation
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(4.3, 1.05, 2.5)
	col.shape = bx
	col.position = Vector3(0.0, -5.85, 0.0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_blade_hit)


func _on_blade_hit(body: Node3D) -> void:
	if not (body is PlayerController):
		return
	var pc := body as PlayerController
	# Allow riding the very top of the blade if clearly above its sweep center
	var local_p := to_local(pc.global_position)
	if local_p.y > -5.52 and pc.velocity.y <= 0.5:
		return
	var swing_dir := global_transform.basis.x * (1.0 if _ang_vel >= 0.0 else -1.0)
	swing_dir.y = 0.0
	swing_dir = swing_dir.normalized() if swing_dir.length_squared() > 0.01 else Vector3.RIGHT
	pc.apply_knockback(swing_dir * knockback_force + Vector3(0.0, 5.5, 0.0))
	AudioDirector.play_sfx("bell_ring", -3.0, 0.62)


func _physics_process(delta: float) -> void:
	_t += delta
	var ang := sin(_t * swing_speed + phase_offset) * deg_to_rad(swing_angle_deg)
	_ang_vel = (ang - _prev_ang) / maxf(delta, 0.001)
	_prev_ang = ang
	rotation = _base_rot + swing_axis.normalized() * ang
