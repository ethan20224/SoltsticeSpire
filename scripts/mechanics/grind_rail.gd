extends Node3D
class_name GrindRail
## Curved high-speed kinetic Grind / Surf Rail (Vine Tendrils W1, Brass Forge Pipes W2,
## Paper Ribbons W3, Aurora Rails W5, Solar Beams W6).
## Jumping near the rail snaps the player smoothly into State.GRIND at 21-24 m/s with spark trails,
## jump-off momentum, slide-ducking under hazards, and a heroic catapult launch off the end!

@export var rail_points: PackedVector3Array = PackedVector3Array()
@export var rail_speed: float = 22.0
@export var end_boost_up: float = 11.2
@export var rail_color: Color = Color(1.0, 0.82, 0.34)
@export var rail_radius: float = 0.22
@export var snap_radius: float = 1.85

var _curve: Curve3D
var _total_len: float = 0.0
var _player_ref: PlayerController = null
var _t: float = 0.0
var _pulse_rings: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group("grind_rail")
	_build_curve()
	if _total_len > 1.0:
		_build_tube_mesh()
		_build_speed_rings()


func _build_curve() -> void:
	_curve = Curve3D.new()
	_curve.bake_interval = 0.35
	if rail_points.size() < 2:
		return
	var n := rail_points.size()
	for i in range(n):
		var p := rail_points[i]
		var prev_p := rail_points[maxi(0, i - 1)]
		var next_p := rail_points[mini(n - 1, i + 1)]
		var tang := (next_p - prev_p) * 0.22
		if i == 0:
			_curve.add_point(p, Vector3.ZERO, (next_p - p) * 0.30)
		elif i == n - 1:
			_curve.add_point(p, (prev_p - p) * 0.30, Vector3.ZERO)
		else:
			_curve.add_point(p, -tang, tang)
	_total_len = _curve.get_baked_length()


func _build_tube_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := clampi(int(ceil(_total_len / 1.1)), 8, 64)
	var sides := 8
	var rings_pts: Array[Array] = []
	var rings_nrms: Array[Array] = []

	for i in range(steps + 1):
		var d := (float(i) / float(steps)) * _total_len
		var c_pt := _curve.sample_baked(d, true)
		var next_d := minf(d + 0.25, _total_len)
		var prev_d := maxf(d - 0.25, 0.0)
		var fwd := (_curve.sample_baked(next_d, true) - _curve.sample_baked(prev_d, true)).normalized()
		if fwd.length_squared() < 0.001:
			fwd = Vector3.FORWARD
		var up := Vector3.UP
		if absf(fwd.dot(up)) > 0.95:
			up = Vector3.RIGHT
		var right := fwd.cross(up).normalized()
		var real_up := right.cross(fwd).normalized()

		var pts: Array[Vector3] = []
		var nrms: Array[Vector3] = []
		for s in range(sides):
			var a := (float(s) / float(sides)) * TAU
			var n := (right * cos(a) + real_up * sin(a)).normalized()
			pts.append(c_pt + n * rail_radius)
			nrms.append(n)
		rings_pts.append(pts)
		rings_nrms.append(nrms)

	for i in range(steps):
		var r0: Array = rings_pts[i]
		var r1: Array = rings_pts[i + 1]
		var n0: Array = rings_nrms[i]
		var n1: Array = rings_nrms[i + 1]
		for s in range(sides):
			var sn := (s + 1) % sides
			st.set_normal(n0[s])
			st.add_vertex(r0[s])
			st.set_normal(n1[s])
			st.add_vertex(r1[s])
			st.set_normal(n1[sn])
			st.add_vertex(r1[sn])

			st.set_normal(n0[s])
			st.add_vertex(r0[s])
			st.set_normal(n1[sn])
			st.add_vertex(r1[sn])
			st.set_normal(n0[sn])
			st.add_vertex(r0[sn])

	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = rail_color
	mat.metallic = 0.65
	mat.roughness = 0.22
	mat.emission_enabled = true
	mat.emission = rail_color
	mat.emission_energy_multiplier = 1.25
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_speed_rings() -> void:
	var count := clampi(int(floor(_total_len / 7.5)), 2, 7)
	var tor := TorusMesh.new()
	tor.inner_radius = 0.44
	tor.outer_radius = 0.52
	tor.rings = 16
	tor.ring_segments = 6
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rmat.albedo_color = Color(rail_color.r, rail_color.g, rail_color.b, 0.72)

	for i in range(count):
		var mi := MeshInstance3D.new()
		mi.mesh = tor
		mi.material_override = rmat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_pulse_rings.append(mi)


func get_rail_length() -> float:
	return _total_len


func get_end_boost_up() -> float:
	return end_boost_up


func sample_at_distance(dist: float) -> Dictionary:
	var d := clampf(dist, 0.0, _total_len)
	var p := to_global(_curve.sample_baked(d, true))
	var d0 := maxf(0.0, d - 0.35)
	var d1 := minf(_total_len, d + 0.35)
	var t_local := (_curve.sample_baked(d1, true) - _curve.sample_baked(d0, true)).normalized()
	var t_world := (global_transform.basis * t_local).normalized()
	return {"pos": p, "tangent": t_world}


func _physics_process(_delta: float) -> void:
	if _total_len <= 1.0 or not is_visible_in_tree():
		return
	if _player_ref == null or not is_instance_valid(_player_ref):
		var p := get_tree().get_first_node_in_group("player")
		if p is PlayerController:
			_player_ref = p as PlayerController
	if _player_ref == null or not GameState.is_playing:
		return
	if _player_ref.state in [PlayerController.State.GRIND, PlayerController.State.REWIND, PlayerController.State.VICTORY_DIVE]:
		return

	var local_p := to_local(_player_ref.global_position)
	var closest_d := _curve.get_closest_offset(local_p)
	# Never immediately snap onto the very last 1.4m tip so you don't insta-launch backward
	if closest_d > _total_len - 1.4:
		return
	var closest_pt := _curve.sample_baked(closest_d, true)
	var diff := local_p - closest_pt
	if diff.length() <= snap_radius and diff.y >= -0.75:
		# Snap onto rail going forward along curve direction (unless moving clearly backward)
		var sample := sample_at_distance(closest_d)
		var tang: Vector3 = sample["tangent"]
		var pvel_h := Vector3(_player_ref.velocity.x, 0.0, _player_ref.velocity.z)
		var dir_sign := 1.0
		if pvel_h.length() > 2.0 and pvel_h.normalized().dot(Vector3(tang.x, 0.0, tang.z).normalized()) < -0.55 and closest_d > 3.5:
			dir_sign = -1.0
		_player_ref.start_grind_rail(self, closest_d, dir_sign, rail_speed)


func _process(delta: float) -> void:
	if _total_len <= 1.0 or _pulse_rings.is_empty():
		return
	_t += delta
	var n := _pulse_rings.size()
	for i in range(n):
		var ring := _pulse_rings[i]
		var frac := fmod((float(i) / float(n)) + _t * (4.2 / maxf(_total_len, 4.0)), 1.0)
		var d := frac * _total_len
		var p := _curve.sample_baked(d, true)
		var d0 := maxf(0.0, d - 0.3)
		var d1 := minf(_total_len, d + 0.3)
		var tang := (_curve.sample_baked(d1, true) - _curve.sample_baked(d0, true)).normalized()
		ring.position = p
		if tang.length_squared() > 0.01:
			var up := Vector3.UP if absf(tang.dot(Vector3.UP)) < 0.92 else Vector3.RIGHT
			var b := Basis.looking_at(tang, up)
			ring.basis = b * Basis(Vector3.RIGHT, PI * 0.5)
