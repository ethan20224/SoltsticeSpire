extends Node3D
class_name MeteorTrigger
## Interactive Sky-Dive Meteor-Slam Target (Sun-Flower Bud in W1, Brass Bellows in W2, Cracked Skylight in W4).
## Walking onto it gives a playful wobble + telegraph prompt; Sky-Dive slamming onto it bursts it open,
## launching the player skyward with massive force AND triggering any linked resonant world group!

signal meteor_slammed()

@export var theme_style: String = "bud"  # "bud", "bellows", "skylight"
@export var trigger_radius: float = 2.6
@export var launch_up: float = 28.5
@export var launch_fwd: Vector3 = Vector3.ZERO
@export var linked_group: String = ""
@export var linked_duration: float = 8.0
@export var bloom_reset_delay: float = 4.2

var _visual_root: Node3D
var _petals: Array[Node3D] = []
var _chevron_ring: MeshInstance3D
var _slammed: bool = false
var _reset_timer: float = 0.0
var _wobble_t: float = 0.0
var _hint_cd: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	add_to_group("meteor_trigger")
	_build_body()
	_build_visuals()
	_build_area()


func _build_body() -> void:
	var sb := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = trigger_radius
	cy.height = 0.55
	col.shape = cy
	col.position = Vector3(0.0, -0.275, 0.0)
	sb.add_child(col)
	add_child(sb)


func _build_visuals() -> void:
	_visual_root = Node3D.new()
	add_child(_visual_root)

	var base_col := Color(0.24, 0.62, 0.30)
	var accent_col := Color(1.0, 0.78, 0.24)
	if theme_style == "bellows":
		base_col = Color(0.72, 0.44, 0.20)
		accent_col = Color(1.0, 0.52, 0.16)
	elif theme_style == "skylight":
		base_col = Color(0.84, 0.66, 0.96)
		accent_col = Color(0.55, 0.94, 1.0)

	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = base_col
	base_mat.roughness = 0.32
	base_mat.metallic = 0.55 if theme_style == "bellows" else 0.15

	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = accent_col
	glow_mat.emission_enabled = true
	glow_mat.emission = accent_col
	glow_mat.emission_energy_multiplier = 2.0
	glow_mat.roughness = 0.20

	# Base drum
	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = trigger_radius * 0.96
	cyl.bottom_radius = trigger_radius * 1.06
	cyl.height = 0.56
	cyl.radial_segments = 20
	base.mesh = cyl
	base.material_override = base_mat
	base.position = Vector3(0.0, -0.28, 0.0)
	_visual_root.add_child(base)

	# Glowing central bullseye core
	var core := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = trigger_radius * 0.46
	cc.bottom_radius = trigger_radius * 0.52
	cc.height = 0.14
	cc.radial_segments = 16
	core.mesh = cc
	core.material_override = glow_mat
	core.position = Vector3(0.0, 0.04, 0.0)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_root.add_child(core)

	# 6 hinged petals / bellows flanges / crystal shards that fold closed & burst open when slammed!
	var petal_box := BoxMesh.new()
	petal_box.size = Vector3(trigger_radius * 0.48, 0.16, trigger_radius * 0.72)
	for i in range(6):
		var a := float(i) * (TAU / 6.0)
		var pivot := Node3D.new()
		pivot.position = Vector3(cos(a) * (trigger_radius * 0.76), 0.04, sin(a) * (trigger_radius * 0.76))
		pivot.rotation.y = -a + PI * 0.5
		var pm := MeshInstance3D.new()
		pm.mesh = petal_box
		pm.material_override = base_mat if i % 2 == 0 else glow_mat
		pm.position = Vector3(0.0, 0.12, -trigger_radius * 0.28)
		pm.rotation_degrees.x = 34.0
		pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(pm)
		_visual_root.add_child(pivot)
		_petals.append(pivot)

	# Hovering downward-pulsing target ring signaling "SKY-DIVE SLAM HERE!"
	_chevron_ring = MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = trigger_radius * 0.62
	tor.outer_radius = trigger_radius * 0.72
	tor.rings = 24
	tor.ring_segments = 8
	_chevron_ring.mesh = tor
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rmat.albedo_color = Color(accent_col.r, accent_col.g, accent_col.b, 0.82)
	_chevron_ring.material_override = rmat
	_chevron_ring.position = Vector3(0.0, 1.35, 0.0)
	_chevron_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_root.add_child(_chevron_ring)


func _build_area() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var col := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = trigger_radius + 0.35
	cy.height = 1.65
	col.shape = cy
	col.position = Vector3(0.0, 0.72, 0.0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	var pc := body as PlayerController
	if pc == null:
		return
	if pc.is_sky_dive_recent() or pc.velocity.y < -22.0:
		_trigger_meteor_slam(pc)
	else:
		_wobble_t = 1.0
		if _hint_cd <= 0.0 and not _slammed:
			_hint_cd = 2.6
			var glyph := InputManager.get_glyph("slide")
			GameState.emit_callout("METEOR SLAM TARGET!", "Jump & Hold %s Mid-Air to Slam Open!" % glyph, Color(1.0, 0.84, 0.34))
			AudioDirector.play_sfx("bounce", -6.0, 0.72)


func _trigger_meteor_slam(pc: PlayerController) -> void:
	_slammed = true
	_reset_timer = bloom_reset_delay
	_wobble_t = 1.2

	# Animate petals bursting wide open!
	for p in _petals:
		var tw := create_tween()
		tw.tween_property(p, "rotation_degrees:x", -58.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var imp := Vector3(launch_fwd.x, launch_up, launch_fwd.z)
	pc.apply_bounce(imp, true, true)
	GameState.unlock_badge("meteor_master")

	if not linked_group.is_empty():
		GameState.emit_bell_resonance(linked_group, linked_duration)
		GameState.emit_callout("METEOR SLAM!", "Path Awakened + Super Launch!", Color(1.0, 0.86, 0.32))
	else:
		var title := "SUN-BUD BLOOM!" if theme_style == "bud" else ("BELLOWS BLAST!" if theme_style == "bellows" else "SKYLIGHT SHATTER!")
		GameState.emit_callout(title, "SUPER CATAPULT LAUNCH!", Color(1.0, 0.82, 0.28))

	AudioDirector.play_sfx("bounce", 1.5, 0.58)
	AudioDirector.play_sfx("crystal_shatter" if theme_style == "skylight" else "firework_pop", -1.5, 0.92)
	meteor_slammed.emit()


func _process(delta: float) -> void:
	_t += delta
	_hint_cd = maxf(0.0, _hint_cd - delta)
	if _wobble_t > 0.001:
		_wobble_t = maxf(0.0, _wobble_t - delta * 3.5)
		var osc := sin(_wobble_t * PI * 3.0) * _wobble_t * 0.18
		_visual_root.scale = Vector3(1.0 + osc, 1.0 - osc * 1.2, 1.0 + osc)
	else:
		_visual_root.scale = Vector3.ONE

	if _chevron_ring:
		var pulse_y := fmod(_t * 1.4, 1.0)
		_chevron_ring.position.y = lerpf(2.2, 0.35, pulse_y)
		var s := lerpf(1.15, 0.68, pulse_y)
		_chevron_ring.scale = Vector3(s, 1.0, s)
		_chevron_ring.visible = not _slammed

	if _slammed:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_slammed = false
			for p in _petals:
				var tw := create_tween()
				tw.tween_property(p, "rotation_degrees:x", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
