extends Area3D
class_name MonsoonWindZone
## World 3 Telegraphed Monsoon Storm Wind Zone!
## Cycles rhythmically: CALM -> TELEGRAPH (1.6s whistling wind + tilted rain + HUD banner) -> GUST!
## Jump WITH a tailwind to soar across giant gaps, or shelter behind Torii pillars / walls during crosswinds!

@export var zone_size: Vector3 = Vector3(58.0, 48.0, 58.0)
@export var wind_direction: Vector3 = Vector3(1.0, 0.12, 0.0)
@export var gust_force: float = 24.0
@export var calm_duration: float = 3.8
@export var telegraph_duration: float = 1.6
@export var gust_duration: float = 3.4

enum WindPhase { CALM, TELEGRAPH, GUST }

var _phase: WindPhase = WindPhase.CALM
var _timer: float = 0.0
var _player_inside: PlayerController = null
var _streak_particles: GPUParticles3D
var _streak_pm: ParticleProcessMaterial


func _ready() -> void:
	add_to_group("monsoon_wind_zone")
	collision_layer = 0
	collision_mask = 2
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = zone_size
	col.shape = bx
	add_child(col)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_build_wind_streaks()


func _build_wind_streaks() -> void:
	_streak_particles = GPUParticles3D.new()
	_streak_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_streak_particles.amount = 90
	_streak_particles.lifetime = 1.35
	_streak_particles.emitting = false
	_streak_particles.visibility_aabb = AABB(-zone_size * 0.6, zone_size * 1.2)

	_streak_pm = ParticleProcessMaterial.new()
	_streak_pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_streak_pm.emission_box_extents = zone_size * 0.45
	_streak_pm.direction = wind_direction.normalized()
	_streak_pm.spread = 6.0
	_streak_pm.initial_velocity_min = 18.0
	_streak_pm.initial_velocity_max = 30.0
	_streak_pm.gravity = Vector3.ZERO
	_streak_particles.process_material = _streak_pm

	var bm := BoxMesh.new()
	bm.size = Vector3(0.08, 0.08, 2.8)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.68, 0.96, 1.0, 0.55)
	bm.material = mat
	_streak_particles.draw_pass_1 = bm
	add_child(_streak_particles)


func _on_enter(body: Node3D) -> void:
	if body is PlayerController:
		_player_inside = body as PlayerController
		_sync_hud_state()


func _on_exit(body: Node3D) -> void:
	if body == _player_inside:
		_player_inside = null
		GameState.set_monsoon_wind("calm", Vector3.ZERO, 0.0)


func _sync_hud_state() -> void:
	if _player_inside == null:
		return
	var pname := "calm"
	var str_val := 0.0
	if _phase == WindPhase.TELEGRAPH:
		pname = "telegraph"
		str_val = 0.4
	elif _phase == WindPhase.GUST:
		pname = "gust"
		str_val = 1.0
	GameState.set_monsoon_wind(pname, wind_direction.normalized(), str_val)


func _is_player_sheltered(pc: PlayerController) -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return false
	var wdir := wind_direction.normalized()
	var origin := pc.global_position + Vector3(0.0, 0.85, 0.0)
	var q := PhysicsRayQueryParameters3D.create(origin, origin - wdir * 4.2, 1, [pc.get_rid()])
	var hit := space.intersect_ray(q)
	return not hit.is_empty()


func _physics_process(delta: float) -> void:
	_timer += delta
	var prev_phase := _phase
	match _phase:
		WindPhase.CALM:
			if _timer >= calm_duration:
				_timer = 0.0
				_phase = WindPhase.TELEGRAPH
		WindPhase.TELEGRAPH:
			if _timer >= telegraph_duration:
				_timer = 0.0
				_phase = WindPhase.GUST
		WindPhase.GUST:
			if _timer >= gust_duration:
				_timer = 0.0
				_phase = WindPhase.CALM

	if _phase != prev_phase:
		if _streak_particles:
			_streak_particles.emitting = (_phase != WindPhase.CALM)
		if _player_inside != null:
			_sync_hud_state()
			if _phase == WindPhase.GUST:
				AudioDirector.play_sfx("dash", -4.5, 0.62)

	if _player_inside != null and is_instance_valid(_player_inside):
		if _phase == WindPhase.GUST:
			if not _is_player_sheltered(_player_inside):
				_player_inside.external_wind += wind_direction.normalized() * gust_force
		elif _phase == WindPhase.TELEGRAPH:
			if not _is_player_sheltered(_player_inside):
				_player_inside.external_wind += wind_direction.normalized() * (gust_force * 0.22)
