extends AnimatableBody3D
class_name ArmillaryRing
## World 6 Solid, Walkable Rotating Solar Armillary Ring!
## Giant golden orbital track circling the Stratosphere Spire with smooth segmented box colliders
## AND sweeping golden Solar Beam Hazards (jump over low beam / slide under mid beam)!

@export var ring_radius: float = 25.5
@export var rim_width: float = 3.4
@export var spin_speed_deg: float = 13.0
@export var tilt_deg: Vector3 = Vector3(5.0, 0.0, -4.0)
@export var beam_count: int = 2
@export var ring_color: Color = Color(1.0, 0.80, 0.30)

var _base_basis: Basis
var _spin_rad: float = 0.0
var _beam_hit_cd: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	add_to_group("armillary_ring")
	_base_basis = Basis.from_euler(Vector3(deg_to_rad(tilt_deg.x), deg_to_rad(tilt_deg.y), deg_to_rad(tilt_deg.z)))
	_build_ring_geometry()
	_build_solar_beams()


func _build_ring_geometry() -> void:
	var segs := 24
	var arc_len := (TAU * ring_radius / float(segs)) * 1.06

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = ring_color
	gold_mat.metallic = 0.82
	gold_mat.roughness = 0.24
	gold_mat.emission_enabled = true
	gold_mat.emission = ring_color
	gold_mat.emission_energy_multiplier = 0.52

	var trim_mat := StandardMaterial3D.new()
	trim_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trim_mat.albedo_color = Color(1.0, 0.94, 0.62)

	var seg_box := BoxMesh.new()
	seg_box.size = Vector3(rim_width, 0.48, arc_len)

	var trim_box := BoxMesh.new()
	trim_box.size = Vector3(0.14, 0.08, arc_len)

	for i in range(segs):
		var a := (float(i) / float(segs)) * TAU
		var pos := Vector3(cos(a) * ring_radius, 0.0, sin(a) * ring_radius)
		var rot_y := -a

		var col := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(rim_width, 0.48, arc_len)
		col.shape = bx
		col.position = pos + Vector3(0.0, -0.24, 0.0)
		col.rotation.y = rot_y
		add_child(col)

		var mi := MeshInstance3D.new()
		mi.mesh = seg_box
		mi.material_override = gold_mat
		mi.position = pos + Vector3(0.0, -0.24, 0.0)
		mi.rotation.y = rot_y
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

		# Glowing edge rails for crystal readability in cosmic stratosphere
		for side: float in [-1.0, 1.0]:
			var tr := MeshInstance3D.new()
			tr.mesh = trim_box
			tr.material_override = trim_mat
			var radial_dir := Vector3(cos(a), 0.0, sin(a))
			tr.position = pos + radial_dir * (side * (rim_width * 0.5 - 0.12)) + Vector3(0.0, 0.04, 0.0)
			tr.rotation.y = rot_y
			tr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(tr)


func _build_solar_beams() -> void:
	if beam_count <= 0:
		return
	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.albedo_color = Color(1.0, 0.42, 0.20)

	for i in range(beam_count):
		var a := (float(i) / float(beam_count)) * TAU + 0.6
		var is_low_jump := (i % 2 == 0)
		var beam_y := 0.52 if is_low_jump else 1.24  # Low = Jump Over, Mid = Slide Under!
		var pos := Vector3(cos(a) * ring_radius, beam_y, sin(a) * ring_radius)

		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(rim_width + 0.5, 0.26, 0.28)
		mi.mesh = bm
		mi.material_override = beam_mat
		mi.position = pos
		mi.rotation.y = -a
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		area.position = pos
		area.rotation.y = -a
		var col := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(rim_width + 0.4, 0.45, 0.55)
		col.shape = bx
		area.add_child(col)
		add_child(area)
		var captured_low := is_low_jump
		area.body_entered.connect(func(b: Node3D) -> void: _on_beam_hit(b, captured_low, area.global_position))


func _on_beam_hit(body: Node3D, is_low_jump: bool, beam_world_pos: Vector3) -> void:
	if _beam_hit_cd > 0.0 or not (body is PlayerController):
		return
	var pc := body as PlayerController
	# Sliding cleanly dodges mid-height beams!
	if not is_low_jump and pc.is_sliding_or_ducking():
		pc.add_flow(0.24, true)
		GameState.emit_callout("SOLAR SLIDE DODGE!", "+FLOW SURGE", Color(1.0, 0.88, 0.36))
		return
	_beam_hit_cd = 0.55
	var push := (pc.global_position - beam_world_pos)
	push.y = 0.0
	push = (push.normalized() if push.length_squared() > 0.01 else Vector3.UP) * 8.5 + Vector3(0.0, 6.5, 0.0)
	pc.apply_knockback(push)
	GameState.emit_callout("SOLAR PULSE!", "Jump Low Beams · Slide Mid Beams!", Color(1.0, 0.46, 0.24))


func _physics_process(delta: float) -> void:
	_beam_hit_cd = maxf(0.0, _beam_hit_cd - delta)
	_spin_rad += deg_to_rad(spin_speed_deg) * delta
	basis = _base_basis * Basis(Vector3.UP, _spin_rad)
