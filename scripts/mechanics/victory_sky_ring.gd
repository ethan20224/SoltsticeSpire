extends Area3D
class_name VictorySkyRing
## Giant glowing golden sky-ring placed along the 1,085m -> 0m Victory Skydive spiral!
## Flying through a ring triggers a rising musical chime, radiant spark burst, and gentle score flash.

@export var ring_index: int = 0
@export var ring_radius: float = 5.4

var _torus_mi: MeshInstance3D
var _inner_mi: MeshInstance3D
var _mat: StandardMaterial3D
var _passed: bool = false
var _t: float = 0.0


func _ready() -> void:
	add_to_group("victory_sky_ring")
	collision_layer = 0
	collision_mask = 2

	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = ring_radius + 1.2
	cyl.height = 3.2
	col.shape = cyl
	add_child(col)

	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.albedo_color = Color(1.0, 0.86, 0.34, 0.82)

	_torus_mi = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = ring_radius - 0.28
	tor.outer_radius = ring_radius
	tor.rings = 36
	tor.ring_segments = 10
	_torus_mi.mesh = tor
	_torus_mi.material_override = _mat
	_torus_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_torus_mi)

	_inner_mi = MeshInstance3D.new()
	var itor := TorusMesh.new()
	itor.inner_radius = ring_radius - 0.52
	itor.outer_radius = ring_radius - 0.38
	itor.rings = 28
	itor.ring_segments = 8
	_inner_mi.mesh = itor
	var imat := StandardMaterial3D.new()
	imat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	imat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	imat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	imat.albedo_color = Color(1.0, 0.96, 0.72, 0.56)
	_inner_mi.material_override = imat
	_inner_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_inner_mi)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _passed or not body.is_in_group("player"):
		return
	_passed = true
	AudioDirector.play_flow_chime(ring_index % 8, -1.5)
	AudioDirector.play_sfx("sun_shard", -5.5, 1.05 + float(ring_index % 6) * 0.06)
	PhoneController.send_haptic("shard")
	InputManager.rumble("shard")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.42, 1.42, 1.42), 0.36).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mat, "albedo_color:a", 0.0, 0.36)
	tw.chain().tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	if not _passed:
		rotate_y(delta * 0.55)
		if _torus_mi:
			var sc := 1.0 + sin(_t * 3.0 + float(ring_index)) * 0.03
			_torus_mi.scale = Vector3(sc, 1.0, sc)
