extends Node3D
class_name SlideObstacle
## Low Slide-Under Gate or Sweeping Foundry Beam positioned at y = 1.08m above deck.
## Standing/running players hit the bar with tactile knockback; Sliding players zip cleanly underneath
## for a "CLOSE SHAVE! +FLOW" speed burst straight into a Slide-Long-Jump!

@export var gate_width: float = 4.6
@export var beam_height_y: float = 1.12
@export var accent_color: Color = Color(1.0, 0.68, 0.24)
@export var sweep_amplitude: float = 0.0  # > 0 makes the low beam sweep back & forth along local Z!
@export var sweep_speed: float = 1.8

var _beam_pivot: Node3D
var _t: float = 0.0
var _shave_cd: float = 0.0
var _hit_cd: float = 0.0


func _ready() -> void:
	add_to_group("slide_obstacle")
	_build_structure()


func _build_structure() -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.24, 0.20, 0.22)
	frame_mat.metallic = 0.68
	frame_mat.roughness = 0.36

	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color = accent_color

	# Side pillars (visual framing only so edges never snag player)
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.32, 2.35, 0.32)
	for side: float in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.mesh = post_mesh
		post.material_override = frame_mat
		post.position = Vector3(side * (gate_width * 0.5 + 0.16), 1.18, 0.0)
		add_child(post)

	_beam_pivot = Node3D.new()
	_beam_pivot.position = Vector3(0.0, beam_height_y, 0.0)
	add_child(_beam_pivot)

	# Solid low crossbar collider (bottom edge sits at beam_height_y - 0.16 = 0.96m > crouched 0.78m, < standing 1.46m!)
	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(gate_width, 0.42, 0.44)
	col.shape = bx
	col.position = Vector3(0.0, 0.16, 0.0)
	sb.add_child(col)
	_beam_pivot.add_child(sb)

	# Visual Crossbar + glowing warning stripe
	var bar := MeshInstance3D.new()
	var bar_m := BoxMesh.new()
	bar_m.size = Vector3(gate_width + 0.3, 0.40, 0.44)
	bar.mesh = bar_m
	bar.material_override = frame_mat
	bar.position = Vector3(0.0, 0.16, 0.0)
	_beam_pivot.add_child(bar)

	var stripe := MeshInstance3D.new()
	var st_m := BoxMesh.new()
	st_m.size = Vector3(gate_width + 0.34, 0.10, 0.48)
	stripe.mesh = st_m
	stripe.material_override = glow_mat
	stripe.position = Vector3(0.0, -0.02, 0.0)
	stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam_pivot.add_child(stripe)

	# Upper hit trigger (catches standing players who slam into the bar and knocks them back)
	var hit_area := Area3D.new()
	hit_area.collision_layer = 0
	hit_area.collision_mask = 2
	var hcol := CollisionShape3D.new()
	var hbx := BoxShape3D.new()
	hbx.size = Vector3(gate_width, 0.52, 0.85)
	hcol.shape = hbx
	hcol.position = Vector3(0.0, 0.20, 0.0)
	hit_area.add_child(hcol)
	_beam_pivot.add_child(hit_area)
	hit_area.body_entered.connect(_on_hit_beam)

	# Lower "Close Shave" reward tunnel right underneath the beam!
	var shave_area := Area3D.new()
	shave_area.collision_layer = 0
	shave_area.collision_mask = 2
	var scol := CollisionShape3D.new()
	var sbx := BoxShape3D.new()
	sbx.size = Vector3(gate_width, 0.82, 1.15)
	scol.shape = sbx
	scol.position = Vector3(0.0, -beam_height_y * 0.55, 0.0)
	shave_area.add_child(scol)
	_beam_pivot.add_child(shave_area)
	shave_area.body_entered.connect(_on_slide_under)


func _on_hit_beam(body: Node3D) -> void:
	if _hit_cd > 0.0 or not body.is_in_group("player"):
		return
	var pc := body as PlayerController
	if pc == null or pc.is_sliding_or_ducking():
		return
	_hit_cd = 0.55
	var push := (pc.global_position - _beam_pivot.global_position)
	push.y = 0.0
	if push.length_squared() < 0.01:
		push = global_transform.basis.z
	push = push.normalized() * 8.5 + Vector3(0.0, 4.2, 0.0)
	pc.apply_knockback(push)
	var glyph := InputManager.get_glyph("slide")
	GameState.emit_callout("LOW BEAM!", "Press %s to Slide Underneath!" % glyph, accent_color)


func _on_slide_under(body: Node3D) -> void:
	if _shave_cd > 0.0 or not body.is_in_group("player"):
		return
	var pc := body as PlayerController
	if pc == null or not pc.is_sliding_or_ducking():
		return
	_shave_cd = 1.4
	pc.add_flow(0.26, true)
	var fwd := Vector3(pc.velocity.x, 0.0, pc.velocity.z)
	if fwd.length_squared() > 0.1:
		var boosted := fwd.normalized() * maxf(fwd.length() + 3.2, 17.5)
		pc.velocity.x = boosted.x
		pc.velocity.z = boosted.z
	AudioDirector.play_flow_chime(mini(GameState.current_streak + 1, 7), -2.5)
	GameState.emit_callout("CLOSE SHAVE!", "+FLOW SPEED SURGE", Color(0.50, 0.98, 1.0))


func _process(delta: float) -> void:
	_t += delta
	_shave_cd = maxf(0.0, _shave_cd - delta)
	_hit_cd = maxf(0.0, _hit_cd - delta)
	if sweep_amplitude > 0.01 and _beam_pivot:
		_beam_pivot.position.z = sin(_t * sweep_speed) * sweep_amplitude
