extends Node3D
class_name HighWaterFlag
## Personal-Best High-Point Flag planted whenever the player falls >10m below a climb peak.
## Features a golden staff, fluttering pennant ribbon, glowing orb finial, and altitude label.

var _staff: MeshInstance3D
var _finial: MeshInstance3D
var _pennant: MeshInstance3D
var _label: Label3D
var _burst_particles: GPUParticles3D
var _t: float = 0.0


func _ready() -> void:
	visible = false
	_build_flag()


func _build_flag() -> void:
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(1.0, 0.82, 0.30)
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.22
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(1.0, 0.72, 0.18)
	gold_mat.emission_energy_multiplier = 0.85

	_staff = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.06
	cyl.height = 3.2
	cyl.radial_segments = 10
	_staff.mesh = cyl
	_staff.position = Vector3(0.0, 1.6, 0.0)
	_staff.material_override = gold_mat
	_staff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_staff)

	_finial = MeshInstance3D.new()
	var orb := SphereMesh.new()
	orb.radius = 0.18
	orb.height = 0.36
	orb.radial_segments = 12
	orb.rings = 6
	var orb_mat := StandardMaterial3D.new()
	orb_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orb_mat.albedo_color = Color(1.0, 0.94, 0.56)
	_finial.mesh = orb
	_finial.position = Vector3(0.0, 3.28, 0.0)
	_finial.material_override = orb_mat
	_finial.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_finial)

	# Stylized fluttering pennant triangle ribbon
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.BACK)
	st.add_vertex(Vector3(0.0, 0.42, 0.0))
	st.add_vertex(Vector3(1.55, 0.14, 0.0))
	st.add_vertex(Vector3(0.0, -0.42, 0.0))
	var pen_mat := StandardMaterial3D.new()
	pen_mat.albedo_color = Color(1.0, 0.74, 0.22)
	pen_mat.emission_enabled = true
	pen_mat.emission = Color(1.0, 0.65, 0.18)
	pen_mat.emission_energy_multiplier = 1.2
	pen_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_pennant = MeshInstance3D.new()
	_pennant.mesh = st.commit()
	_pennant.material_override = pen_mat
	_pennant.position = Vector3(0.03, 2.74, 0.0)
	_pennant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pennant)

	_label = Label3D.new()
	_label.position = Vector3(0.0, 3.85, 0.0)
	_label.text = "BEST · 0m"
	_label.font_size = 44
	_label.pixel_size = 0.0085
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1.0, 0.92, 0.54)
	_label.outline_modulate = Color(0.14, 0.08, 0.02, 0.9)
	_label.outline_size = 10
	_label.no_depth_test = false
	add_child(_label)

	_burst_particles = GPUParticles3D.new()
	_burst_particles.one_shot = true
	_burst_particles.explosiveness = 0.92
	_burst_particles.amount = 24
	_burst_particles.lifetime = 0.65
	_burst_particles.emitting = false
	_burst_particles.position = Vector3(0.0, 2.2, 0.0)

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 110.0
	pm.initial_velocity_min = 3.5
	pm.initial_velocity_max = 8.0
	pm.gravity = Vector3(0.0, -7.5, 0.0)
	pm.scale_min = 0.1
	pm.scale_max = 0.22
	_burst_particles.process_material = pm

	var sp := SphereMesh.new()
	sp.radius = 0.4
	sp.height = 0.8
	var sp_mat := StandardMaterial3D.new()
	sp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sp_mat.albedo_color = Color(1.0, 0.90, 0.40)
	sp.material = sp_mat
	_burst_particles.draw_pass_1 = sp
	add_child(_burst_particles)


func plant_at(pos: Vector3, alt_m: float) -> void:
	global_position = pos
	_label.text = "BEST · %dm" % int(round(alt_m))
	visible = true
	scale = Vector3(0.2, 0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func celebrate_surpassed() -> void:
	if not visible:
		return
	_burst_particles.restart()
	_burst_particles.emitting = true
	AudioDirector.play_sfx("checkpoint", -2.5, 1.24)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.25, 1.25, 1.25), 0.12)
	tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.22)
	tw.tween_callback(func():
		visible = false
		scale = Vector3.ONE
	)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _pennant:
		_pennant.rotation.y = sin(_t * 5.2) * 0.26
		_pennant.rotation.z = cos(_t * 3.8) * 0.06
	if _finial:
		var pulse := 1.0 + sin(_t * 4.5) * 0.12
		_finial.scale = Vector3.ONE * pulse
