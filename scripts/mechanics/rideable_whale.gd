extends AnimatableBody3D
class_name RideableWhale
## World 5 Living Rideable Celestial Cloud-Whale Leviathan!
## Orbits gracefully around the Sky-Library spire with a broad, level, slip-free dorsal riding deck,
## glowing aurora spine lanterns, AND a Spout Geyser Launch Pad near its brow that blasts you
## straight skyward toward the Crown of the Sun!

@export var orbit_center: Vector3 = Vector3(0.0, 882.0, 0.0)
@export var orbit_radius: float = 28.0
@export var orbit_speed_rad: float = 0.24
@export var start_angle_rad: float = 0.0
@export var spout_launch_up: float = 31.0
@export var spout_launch_inward: float = 9.0
@export var whale_scale: float = 1.15

var _angle: float = 0.0
var _t: float = 0.0
var _visual_pivot: Node3D
var _boarded_callout: bool = false
var _spout_cd: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	add_to_group("rideable_whale")
	_angle = start_angle_rad
	_build_deck_and_visuals()
	_update_orbit_transform(0.0)


func _build_deck_and_visuals() -> void:
	# Generous slip-free level dorsal deck along the Whale's back (top flush at y = +2.2)
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(5.6, 0.65, 16.5)
	col.shape = bx
	col.position = Vector3(0.0, 1.88, 0.0)
	add_child(col)

	# Tail fluke stepping pad at rear so boarding is super forgiving
	var tail_col := CollisionShape3D.new()
	var tbx := BoxShape3D.new()
	tbx.size = Vector3(7.2, 0.55, 5.2)
	tail_col.shape = tbx
	tail_col.position = Vector3(0.0, 1.45, 9.6)
	add_child(tail_col)

	_visual_pivot = Node3D.new()
	add_child(_visual_pivot)

	var whale_path := "res://assets/models/tower_cores/cloud_whale_leviathan.glb"
	if ResourceLoader.exists(whale_path):
		var vis := WorldHelper.load_glb(whale_path)
		vis.scale = Vector3.ONE * whale_scale
		vis.position = Vector3(0.0, -0.4, 0.0)
		WorldHelper.disable_shadows(vis)
		_visual_pivot.add_child(vis)

	# Glowing Aurora Spine Runner Path along the whale's back so the player clearly sees "RIDE ME!"
	var deck_mat := StandardMaterial3D.new()
	deck_mat.albedo_color = Color(0.32, 0.88, 0.96)
	deck_mat.roughness = 0.28
	deck_mat.emission_enabled = true
	deck_mat.emission = Color(0.40, 0.94, 1.0)
	deck_mat.emission_energy_multiplier = 1.1

	var strip := MeshInstance3D.new()
	var sbox := BoxMesh.new()
	sbox.size = Vector3(3.4, 0.12, 14.5)
	strip.mesh = sbox
	strip.material_override = deck_mat
	strip.position = Vector3(0.0, 2.22, 0.0)
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_pivot.add_child(strip)

	# Glowing Spout Geyser Launch Ring near the whale's front brow (local z = -6.2)
	var spout_mat := StandardMaterial3D.new()
	spout_mat.albedo_color = Color(1.0, 0.88, 0.36)
	spout_mat.emission_enabled = true
	spout_mat.emission = Color(1.0, 0.82, 0.28)
	spout_mat.emission_energy_multiplier = 2.4

	var spout_ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 1.6
	tor.outer_radius = 2.15
	tor.rings = 24
	tor.ring_segments = 8
	spout_ring.mesh = tor
	spout_ring.material_override = spout_mat
	spout_ring.position = Vector3(0.0, 2.38, -6.2)
	spout_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_pivot.add_child(spout_ring)

	# Spout upward particle plume
	var gp := GPUParticles3D.new()
	gp.position = Vector3(0.0, 2.45, -6.2)
	gp.amount = 32
	gp.lifetime = 1.15
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 16.0
	pm.initial_velocity_min = 9.0
	pm.initial_velocity_max = 15.0
	pm.gravity = Vector3(0.0, -3.0, 0.0)
	pm.scale_min = 0.16
	pm.scale_max = 0.34
	gp.process_material = pm
	var sp := SphereMesh.new()
	sp.radius = 0.35
	sp.height = 0.7
	sp.radial_segments = 6
	sp.rings = 3
	sp.material = spout_mat
	gp.draw_pass_1 = sp
	_visual_pivot.add_child(gp)

	# Boarding callout trigger
	var board_area := Area3D.new()
	board_area.collision_layer = 0
	board_area.collision_mask = 2
	var bcol := CollisionShape3D.new()
	var bbx := BoxShape3D.new()
	bbx.size = Vector3(6.2, 2.8, 17.5)
	bcol.shape = bbx
	bcol.position = Vector3(0.0, 3.5, 0.0)
	board_area.add_child(bcol)
	add_child(board_area)
	board_area.body_entered.connect(_on_boarded)

	# Spout Geyser launch trigger at the whale's head
	var spout_area := Area3D.new()
	spout_area.collision_layer = 0
	spout_area.collision_mask = 2
	var scol := CollisionShape3D.new()
	var scy := CylinderShape3D.new()
	scy.radius = 2.55
	scy.height = 2.6
	scol.shape = scy
	scol.position = Vector3(0.0, 3.3, -6.2)
	spout_area.add_child(scol)
	add_child(spout_area)
	spout_area.body_entered.connect(_on_spout_entered)


func _on_boarded(body: Node3D) -> void:
	if not body.is_in_group("player") or _boarded_callout:
		return
	_boarded_callout = true
	AudioDirector.play_sfx("shortcut_fanfare", -1.5, 0.96)
	GameState.emit_callout("CLOUD-WHALE RIDER!", "Sprint Up Its Spine to the Spout Geyser!", Color(0.45, 0.96, 1.0))
	if body.has_method("add_flow"):
		body.call("add_flow", 0.35, true)


func _on_spout_entered(body: Node3D) -> void:
	if _spout_cd > 0.0 or not (body is PlayerController):
		return
	_spout_cd = 0.55
	var pc := body as PlayerController
	var to_center := Vector3(orbit_center.x - global_position.x, 0.0, orbit_center.z - global_position.z)
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	var launch_h := fwd.normalized() * 10.0 + to_center.normalized() * spout_launch_inward
	pc.apply_bounce(Vector3(launch_h.x, spout_launch_up, launch_h.z), true, true)
	AudioDirector.play_sfx("bounce", 2.0, 0.65)
	AudioDirector.play_sfx("flow_chime", -1.0, 1.5)
	GameState.emit_callout("LEVIATHAN SPOUT LAUNCH!", "Soaring into the Stratosphere!", Color(1.0, 0.88, 0.38))


func _update_orbit_transform(delta: float) -> void:
	_t += delta
	_angle += orbit_speed_rad * delta
	var px := sin(_angle) * orbit_radius
	var pz := cos(_angle) * orbit_radius
	var bob := sin(_t * 1.35) * 1.15
	position = orbit_center + Vector3(px, bob, pz)
	# Face tangent direction of orbit (-Z forward)
	var tang := Vector3(cos(_angle), 0.0, -sin(_angle)).normalized()
	rotation = Vector3(0.0, atan2(-tang.x, -tang.z), 0.0)
	if _visual_pivot:
		_visual_pivot.rotation.z = sin(_t * 0.9) * 0.06


func _physics_process(delta: float) -> void:
	_spout_cd = maxf(0.0, _spout_cd - delta)
	_update_orbit_transform(delta)
