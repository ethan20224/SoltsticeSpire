extends AnimatableBody3D
class_name SwingingBridge
## Dramatic riveted Foundry Brass Sky-Beam suspended on golden-iron chains above the molten abyss.
## Rocks smoothly side-to-side with sync_to_physics for pure precarious high-altitude parkour tension.

@export var bridge_length: float = 11.0
@export var bridge_width: float = 1.45
@export var sway_amplitude: float = 2.2
@export var sway_roll_deg: float = 11.5
@export var sway_speed: float = 1.15
@export var phase_offset: float = 0.0
@export var chain_height: float = 15.0
@export var callout_title: String = "THE FOUNDRY SKY-BEAM"
@export var callout_subtitle: String = "Hold Your Nerve!"

var _anchor_pos: Vector3 = Vector3.ZERO
var _base_basis: Basis = Basis.IDENTITY
var _t: float = 0.0
var _callout_fired: bool = false


func _ready() -> void:
	sync_to_physics = true
	add_to_group("swinging_bridge")
	_anchor_pos = position
	_base_basis = Basis.from_euler(rotation)

	_build_collider()
	_build_brass_beam_visuals()
	_build_approach_trigger()


func _build_collider() -> void:
	var col := CollisionShape3D.new()
	col.name = "BeamCollider"
	var bx := BoxShape3D.new()
	bx.size = Vector3(bridge_width, 0.40, bridge_length)
	col.shape = bx
	col.position = Vector3(0.0, -0.20, 0.0)
	add_child(col)


func _build_brass_beam_visuals() -> void:
	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.84, 0.62, 0.26)
	brass_mat.metallic = 0.78
	brass_mat.roughness = 0.34

	var dark_iron_mat := StandardMaterial3D.new()
	dark_iron_mat.albedo_color = Color(0.24, 0.20, 0.22)
	dark_iron_mat.metallic = 0.72
	dark_iron_mat.roughness = 0.44

	var chain_mat := StandardMaterial3D.new()
	chain_mat.albedo_color = Color(0.70, 0.50, 0.22)
	chain_mat.metallic = 0.84
	chain_mat.roughness = 0.36

	var ember_mat := StandardMaterial3D.new()
	ember_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_mat.albedo_color = Color(1.0, 0.68, 0.22)

	# Top flanged brass walkway deck (top flush at y = 0.0)
	var top_deck := MeshInstance3D.new()
	var top_box := BoxMesh.new()
	top_box.size = Vector3(bridge_width, 0.14, bridge_length)
	top_deck.mesh = top_box
	top_deck.material_override = brass_mat
	top_deck.position = Vector3(0.0, -0.07, 0.0)
	add_child(top_deck)

	# Recessed dark-iron central I-beam spine
	var web := MeshInstance3D.new()
	var web_box := BoxMesh.new()
	web_box.size = Vector3(bridge_width * 0.34, 0.42, bridge_length - 0.15)
	web.mesh = web_box
	web.material_override = dark_iron_mat
	web.position = Vector3(0.0, -0.35, 0.0)
	add_child(web)

	# Lower structural brass I-beam flange
	var bot_flange := MeshInstance3D.new()
	var bot_box := BoxMesh.new()
	bot_box.size = Vector3(bridge_width * 0.86, 0.12, bridge_length - 0.1)
	bot_flange.mesh = bot_box
	bot_flange.material_override = brass_mat
	bot_flange.position = Vector3(0.0, -0.60, 0.0)
	add_child(bot_flange)

	# Glowing amber ember edge-strips along left & right edges for high contrast over the abyss
	var strip_box := BoxMesh.new()
	strip_box.size = Vector3(0.07, 0.06, bridge_length - 0.18)
	for side in [-1.0, 1.0]:
		var strip := MeshInstance3D.new()
		strip.mesh = strip_box
		strip.material_override = ember_mat
		strip.position = Vector3(side * (bridge_width * 0.5 - 0.05), -0.015, 0.0)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(strip)

	# Rivet rows along both deck margins (single MultiMesh draw call!)
	var rivet_pairs := int(maxf(4.0, floor(bridge_length / 0.85)))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var r_cyl := CylinderMesh.new()
	r_cyl.top_radius = 0.045
	r_cyl.bottom_radius = 0.055
	r_cyl.height = 0.04
	r_cyl.radial_segments = 8
	mm.mesh = r_cyl
	mm.instance_count = rivet_pairs * 2
	var idx := 0
	for i in range(rivet_pairs):
		var z: float = lerpf(-bridge_length * 0.46, bridge_length * 0.46, float(i) / float(max(rivet_pairs - 1, 1)))
		for side: float in [-1.0, 1.0]:
			var x: float = side * (bridge_width * 0.5 - 0.16)
			mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, Vector3(x, 0.012, z)))
			idx += 1
	var rivets := MultiMeshInstance3D.new()
	rivets.multimesh = mm
	rivets.material_override = dark_iron_mat
	rivets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rivets)

	# Hanging golden-iron suspension chains & forged brass end-yokes
	var chain_cyl := CylinderMesh.new()
	chain_cyl.top_radius = 0.055
	chain_cyl.bottom_radius = 0.065
	chain_cyl.height = chain_height
	chain_cyl.radial_segments = 8

	var collar_torus := TorusMesh.new()
	collar_torus.inner_radius = 0.09
	collar_torus.outer_radius = 0.16
	collar_torus.rings = 12
	collar_torus.ring_segments = 6

	var yoke_z: float = bridge_length * 0.40
	var yoke_x: float = bridge_width * 0.52
	for z_sign: float in [-1.0, 1.0]:
		var cz: float = z_sign * yoke_z
		# Transverse shackle bar beneath deck
		var bar := MeshInstance3D.new()
		var bar_box := BoxMesh.new()
		bar_box.size = Vector3(bridge_width + 0.34, 0.14, 0.24)
		bar.mesh = bar_box
		bar.material_override = dark_iron_mat
		bar.position = Vector3(0.0, -0.14, cz)
		add_child(bar)

		# Overhead suspension spreader beam
		var top_bar := MeshInstance3D.new()
		var top_bar_box := BoxMesh.new()
		top_bar_box.size = Vector3(bridge_width + 0.65, 0.24, 0.32)
		top_bar.mesh = top_bar_box
		top_bar.material_override = brass_mat
		top_bar.position = Vector3(0.0, chain_height, cz)
		add_child(top_bar)

		for x_sign: float in [-1.0, 1.0]:
			var cx: float = x_sign * yoke_x
			var rod := MeshInstance3D.new()
			rod.mesh = chain_cyl
			rod.material_override = chain_mat
			rod.position = Vector3(cx, chain_height * 0.5 - 0.10, cz)
			rod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(rod)

			var collar := MeshInstance3D.new()
			collar.mesh = collar_torus
			collar.material_override = ember_mat
			collar.position = Vector3(cx, 0.36, cz)
			collar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(collar)

	# Warm forge light pool along the center of the beam
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.1, 0.0)
	light.light_color = Color(1.0, 0.66, 0.24)
	light.light_energy = 2.6
	light.omni_range = 12.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 70.0
	light.distance_fade_length = 25.0
	add_child(light)


func _build_approach_trigger() -> void:
	var area := Area3D.new()
	area.name = "ApproachTrigger"
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(bridge_width + 2.6, 3.6, bridge_length + 3.4)
	col.shape = bx
	col.position = Vector3(0.0, 1.5, 0.0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _callout_fired or not body.is_in_group("player"):
		return
	_callout_fired = true
	GameState.emit_callout(callout_title, callout_subtitle, Color(1.0, 0.68, 0.28))
	AudioDirector.play_sfx("bell_ring", -7.5, 0.72)


func _physics_process(delta: float) -> void:
	_t += delta
	var sway := sin(_t * sway_speed + phase_offset)
	var arc_angle := sway * 0.15
	var lateral := _base_basis.x * (sway * sway_amplitude)
	var lift := Vector3.UP * ((1.0 - cos(arc_angle)) * (chain_height * 0.45))
	position = _anchor_pos + lateral + lift

	var roll_rad := deg_to_rad(-sway * sway_roll_deg)
	basis = _base_basis * Basis(Vector3.BACK, roll_rad)
