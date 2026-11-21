extends Area3D
class_name ShortcutBeacon
## Glowing slender golden-emerald archway/ring marker placed at Pro Shortcut takeoffs & landings.
## Features a gently rotating floating faceted diamond, subtle vertical light shimmer, and crisp Flow reward.

@export var callout_title: String = "PRO SHORTCUT!"
@export var callout_subtitle: String = "SKY-SKIP DISCOVERED"
@export var accent_color: Color = Color(1.0, 0.84, 0.34)
@export var is_takeoff_marker: bool = false
@export var trigger_radius: float = 2.6
@export var ring_radius: float = 1.95

var _diamond: MeshInstance3D
var _outer_ring: MeshInstance3D
var _inner_ring: MeshInstance3D
var _shimmer_col: MeshInstance3D
var _shimmer_mat: StandardMaterial3D
var _t: float = 0.0
var _pulse: float = 0.0
var _triggered: bool = false
var _cooldown: float = 0.0


func _ready() -> void:
	add_to_group("shortcut_beacon")
	collision_layer = 0
	collision_mask = 2

	_build_trigger_shape()
	_build_visuals()

	body_entered.connect(_on_body_entered)
	GameState.game_started.connect(_on_game_started)


func _on_game_started() -> void:
	_triggered = false
	_cooldown = 0.0


func _build_trigger_shape() -> void:
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = trigger_radius
	cyl.height = 4.6
	col.shape = cyl
	col.position = Vector3(0.0, 2.1, 0.0)
	add_child(col)


func _build_visuals() -> void:
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(1.0, 0.84, 0.34)
	gold_mat.metallic = 0.86
	gold_mat.roughness = 0.22
	gold_mat.emission_enabled = true
	gold_mat.emission = Color(1.0, 0.78, 0.26)
	gold_mat.emission_energy_multiplier = 0.9

	var emerald_mat := StandardMaterial3D.new()
	emerald_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	emerald_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	emerald_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	emerald_mat.albedo_color = Color(0.32, 0.98, 0.72, 0.86)

	# Slender upright golden archway ring
	_outer_ring = MeshInstance3D.new()
	var outer_torus := TorusMesh.new()
	outer_torus.inner_radius = ring_radius - 0.085
	outer_torus.outer_radius = ring_radius
	outer_torus.rings = 32
	outer_torus.ring_segments = 10
	_outer_ring.mesh = outer_torus
	_outer_ring.material_override = gold_mat
	_outer_ring.position = Vector3(0.0, ring_radius + 0.15, 0.0)
	_outer_ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_outer_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_outer_ring)

	# Luminous emerald-gold inner energy ring
	_inner_ring = MeshInstance3D.new()
	var inner_torus := TorusMesh.new()
	inner_torus.inner_radius = ring_radius - 0.20
	inner_torus.outer_radius = ring_radius - 0.13
	inner_torus.rings = 28
	inner_torus.ring_segments = 8
	_inner_ring.mesh = inner_torus
	_inner_ring.material_override = emerald_mat
	_inner_ring.position = Vector3(0.0, ring_radius + 0.15, 0.0)
	_inner_ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	_inner_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_inner_ring)

	# Gently rotating floating faceted diamond marker at the archway crown
	_diamond = MeshInstance3D.new()
	_diamond.mesh = _make_diamond_mesh(0.38, 0.72)
	var dia_mat := StandardMaterial3D.new()
	dia_mat.albedo_color = Color(0.56, 1.0, 0.82)
	dia_mat.metallic = 0.25
	dia_mat.roughness = 0.12
	dia_mat.emission_enabled = true
	dia_mat.emission = Color(0.74, 0.96, 0.56)
	dia_mat.emission_energy_multiplier = 2.0
	_diamond.material_override = dia_mat
	_diamond.position = Vector3(0.0, ring_radius * 2.0 + 0.65, 0.0)
	_diamond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_diamond)

	# Subtle vertical golden-emerald light shimmer column
	_shimmer_col = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.10
	cyl.bottom_radius = 0.42
	cyl.height = 14.0 if is_takeoff_marker else 18.0
	cyl.radial_segments = 10
	_shimmer_col.mesh = cyl
	_shimmer_col.position = Vector3(0.0, cyl.height * 0.5 + 0.2, 0.0)
	_shimmer_col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shimmer_mat = StandardMaterial3D.new()
	_shimmer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shimmer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shimmer_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_shimmer_mat.albedo_color = Color(0.68, 0.98, 0.62, 0.14 if is_takeoff_marker else 0.20)
	_shimmer_col.material_override = _shimmer_mat
	add_child(_shimmer_col)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, ring_radius + 0.4, 0.0)
	light.light_color = Color(0.66, 0.98, 0.64)
	light.light_energy = 1.9 if is_takeoff_marker else 2.5
	light.omni_range = 9.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 60.0
	light.distance_fade_length = 25.0
	add_child(light)


func _make_diamond_mesh(radius: float, half_h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0.0, half_h, 0.0)
	var bot := Vector3(0.0, -half_h, 0.0)
	var ring_pts: Array[Vector3] = [
		Vector3(radius, 0.0, 0.0),
		Vector3(0.0, 0.0, radius),
		Vector3(-radius, 0.0, 0.0),
		Vector3(0.0, 0.0, -radius),
	]
	for i in range(4):
		var a := ring_pts[i]
		var b := ring_pts[(i + 1) % 4]
		var n_up := (a - top).cross(b - top).normalized()
		st.set_normal(n_up)
		st.add_vertex(top)
		st.add_vertex(a)
		st.add_vertex(b)

		var n_dn := (b - bot).cross(a - bot).normalized()
		st.set_normal(n_dn)
		st.add_vertex(bot)
		st.add_vertex(b)
		st.add_vertex(a)
	return st.commit()


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if _cooldown > 0.0:
		return

	if is_takeoff_marker:
		_cooldown = 4.0
		_pulse = 0.85
		AudioDirector.play_flow_chime(2, -4.5)
		if body.has_method("add_flow"):
			body.add_flow(0.15, false)
		_spawn_spark_burst(14)
		return

	if _triggered:
		return
	_triggered = true
	_cooldown = 8.0
	_pulse = 1.35

	AudioDirector.play_sfx("shortcut_fanfare", -1.5, 1.05)
	GameState.emit_callout(callout_title, callout_subtitle, accent_color)
	if GameState.has_method("unlock_badge"):
		GameState.call("unlock_badge", "shortcut_daredevil")
	if body.has_method("add_flow"):
		body.add_flow(0.35, true)
	_spawn_spark_burst(28)


func _spawn_spark_burst(count: int) -> void:
	var gp := GPUParticles3D.new()
	gp.one_shot = true
	gp.explosiveness = 0.92
	gp.amount = count
	gp.lifetime = 0.68
	gp.position = Vector3(0.0, ring_radius + 0.2, 0.0)
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 115.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 9.5
	pm.gravity = Vector3(0.0, -6.5, 0.0)
	pm.scale_min = 0.10
	pm.scale_max = 0.24
	gp.process_material = pm

	var sp := SphereMesh.new()
	sp.radius = 0.40
	sp.height = 0.80
	sp.radial_segments = 6
	sp.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.86, 1.0, 0.54, 0.92)
	sp.material = mat
	gp.draw_pass_1 = sp
	add_child(gp)
	gp.emitting = true

	var timer := get_tree().create_timer(0.85)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(gp):
			gp.queue_free()
	)


func _process(delta: float) -> void:
	_t += delta
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _pulse > 0.001:
		_pulse = maxf(0.0, _pulse - delta * 2.4)

	if is_instance_valid(_diamond):
		_diamond.rotation.y += delta * (1.7 + _pulse * 5.0)
		_diamond.position.y = ring_radius * 2.0 + 0.65 + sin(_t * 2.8) * 0.16
		var ds := 1.0 + _pulse * 0.35
		_diamond.scale = Vector3(ds, ds, ds)

	if is_instance_valid(_outer_ring) and is_instance_valid(_inner_ring):
		var rs := 1.0 + _pulse * 0.16 + sin(_t * 2.2) * 0.015
		_outer_ring.scale = Vector3(rs, rs, rs)
		_inner_ring.scale = Vector3(rs, rs, rs)

	if is_instance_valid(_shimmer_mat):
		var base_a := 0.12 if is_takeoff_marker else 0.18
		var a := base_a + sin(_t * 3.1) * 0.035 + _pulse * 0.22
		_shimmer_mat.albedo_color = Color(0.68, 0.98, 0.62, clampf(a, 0.0, 0.65))
