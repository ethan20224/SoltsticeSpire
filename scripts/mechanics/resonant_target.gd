extends Node3D
class_name ResonantTarget
## World 2 Foundry Resonant World Element!
## Awakens when a linked Musical Bronze Bell (or Meteor Bellows) sends its golden shockwave!
## Modes:
## - "bridge": Materializes/extends a glowing brass drawbridge for `duration` seconds
## - "cannon": Activates a super-powered golden Forge Steam Cannon launch pad
## - "carillon_lock": Multi-bell arena puzzle — strike all `required_groups` bells in sequence
##                    to awaken a massive Foundry Ascent Lift / Cannon permanently for the run!

@export var listen_group: String = "w2_bell_a"
@export var target_mode: String = "bridge"  # "bridge", "cannon", "carillon_lock"
@export var required_groups: PackedStringArray = PackedStringArray()
@export var bridge_size: Vector3 = Vector3(3.8, 0.45, 10.5)
@export var cannon_up: float = 28.0
@export var cannon_fwd: Vector3 = Vector3.ZERO
@export var stay_permanent_on_unlock: bool = false

var _active: bool = false
var _timer: float = 0.0
var _rung_groups: Dictionary = {}
var _body: StaticBody3D
var _col: CollisionShape3D
var _mesh: MeshInstance3D
var _solid_mat: StandardMaterial3D
var _dormant_mat: StandardMaterial3D
var _launch_area: Area3D
var _launch_cd: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	add_to_group("resonant_target")
	_build_visuals()
	GameState.bell_resonated.connect(_on_bell_resonated)
	GameState.game_started.connect(_reset_state)
	_apply_active(false, true)


func _reset_state() -> void:
	_rung_groups.clear()
	_timer = 0.0
	_apply_active(false, true)


func _build_visuals() -> void:
	_solid_mat = StandardMaterial3D.new()
	_solid_mat.albedo_color = Color(1.0, 0.80, 0.28)
	_solid_mat.metallic = 0.82
	_solid_mat.roughness = 0.22
	_solid_mat.emission_enabled = true
	_solid_mat.emission = Color(1.0, 0.68, 0.16)
	_solid_mat.emission_energy_multiplier = 1.65

	_dormant_mat = StandardMaterial3D.new()
	_dormant_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dormant_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dormant_mat.albedo_color = Color(0.95, 0.68, 0.26, 0.18)

	_body = StaticBody3D.new()
	_col = CollisionShape3D.new()
	if target_mode == "bridge":
		var bx := BoxShape3D.new()
		bx.size = bridge_size
		_col.shape = bx
		_col.position = Vector3(0.0, -bridge_size.y * 0.5, 0.0)
		_mesh = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = bridge_size
		_mesh.mesh = bm
		_mesh.position = Vector3(0.0, -bridge_size.y * 0.5, 0.0)
	else:
		var cy := CylinderShape3D.new()
		cy.radius = 2.8
		cy.height = 0.6
		_col.shape = cy
		_col.position = Vector3(0.0, -0.3, 0.0)
		_mesh = MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 2.8
		cm.bottom_radius = 3.1
		cm.height = 0.6
		cm.radial_segments = 20
		_mesh.mesh = cm
		_mesh.position = Vector3(0.0, -0.3, 0.0)

	_body.add_child(_col)
	add_child(_body)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)

	if target_mode == "cannon" or target_mode == "carillon_lock":
		_launch_area = Area3D.new()
		_launch_area.collision_layer = 0
		_launch_area.collision_mask = 2
		var lcol := CollisionShape3D.new()
		var lcy := CylinderShape3D.new()
		lcy.radius = 2.95
		lcy.height = 1.8
		lcol.shape = lcy
		lcol.position = Vector3(0.0, 0.85, 0.0)
		_launch_area.add_child(lcol)
		add_child(_launch_area)
		_launch_area.body_entered.connect(_on_cannon_entered)


func _on_bell_resonated(bell_group: String, duration: float) -> void:
	if target_mode == "carillon_lock":
		if required_groups.has(bell_group):
			_rung_groups[bell_group] = true
			var done := _rung_groups.size()
			var tot := required_groups.size()
			if done >= tot:
				_timer = 9999.0 if stay_permanent_on_unlock else maxf(duration, 14.0)
				_apply_active(true, false)
				AudioDirector.play_sfx("shortcut_fanfare", -1.0, 1.06)
				GameState.emit_callout("CARILLON AWAKENED!", "Forge Cannon Unlocked — Launch Skyward!", Color(1.0, 0.86, 0.30))
			else:
				_timer = maxf(_timer, duration)
				AudioDirector.play_flow_chime(done + 2, -2.0)
				GameState.emit_callout("BELL RESONANCE %d/%d" % [done, tot], "Strike Remaining Bronze Bells!", Color(1.0, 0.78, 0.30))
		return

	if bell_group == listen_group:
		_timer = 9999.0 if stay_permanent_on_unlock else duration
		_apply_active(true, false)


func _apply_active(make_active: bool, instant: bool = false) -> void:
	_active = make_active
	if target_mode == "bridge":
		_body.collision_layer = 1 if make_active else 0
		if _col:
			_col.disabled = not make_active
	else:
		# Cannon base pad is always walkable so you can stand on it; launch activates when awakened!
		_body.collision_layer = 1
		if _col:
			_col.disabled = false

	if _mesh:
		_mesh.material_override = _solid_mat if make_active else _dormant_mat
		if make_active and not instant:
			_mesh.scale = Vector3(1.0, 0.3, 1.0)
			var tw := create_tween()
			tw.tween_property(_mesh, "scale", Vector3.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_cannon_entered(body: Node3D) -> void:
	if _launch_cd > 0.0 or not (body is PlayerController):
		return
	if not _active:
		if target_mode == "carillon_lock":
			GameState.emit_callout("CARILLON SEALED (%d/%d)" % [_rung_groups.size(), required_groups.size()], "Wall-Kick the Surrounding Bronze Bells!", Color(1.0, 0.74, 0.28))
		else:
			GameState.emit_callout("FORGE CANNON DORMANT", "Wall-Kick the Bronze Bell to Power It!", Color(1.0, 0.74, 0.28))
		return
	_launch_cd = 0.45
	var pc := body as PlayerController
	pc.apply_bounce(Vector3(cannon_fwd.x, cannon_up, cannon_fwd.z), true, true)
	AudioDirector.play_sfx("bounce", 1.5, 0.68)
	AudioDirector.play_sfx("bell_ring", -1.5, 1.25)


func _process(delta: float) -> void:
	_t += delta
	_launch_cd = maxf(0.0, _launch_cd - delta)
	if _active and not stay_permanent_on_unlock:
		_timer -= delta
		if _timer <= 1.6 and _solid_mat:
			var blink := 0.5 + 0.5 * sin(_t * 18.0)
			_solid_mat.emission_energy_multiplier = lerpf(0.6, 2.2, blink)
		if _timer <= 0.0:
			_rung_groups.clear()
			_apply_active(false, false)
	elif not _active and target_mode == "carillon_lock" and _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			_rung_groups.clear()
