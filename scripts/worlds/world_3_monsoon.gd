extends Node3D
class_name World3Monsoon
## World 3: The Origami Monsoon (355m -> 540m)
## Signature Twist: Telegraphed Monsoon Wind Gusts (ride tailwinds / shelter behind Torii gates!),
## Domino Origami Sprints (unfold ahead, collapse behind!), Paper-Ribbon Grind Rail,
## Multi-Crane Mid-Flight Relay, Downhill Rain-Roof Chute, & Storm-Gale Prism Climax!

const CRANE := "res://assets/models/world3_monsoon/origami_crane.glb"
const PARASOL := "res://assets/models/world3_monsoon/silk_parasol.glb"
const PAGODA := "res://assets/models/world3_monsoon/pagoda_eave.glb"
const LANTERN := "res://assets/models/world3_monsoon/paper_lantern.glb"
const GATE := "res://assets/models/common/world_gate.glb"
const CORE := "res://assets/models/tower_cores/w3_monsoon_core.glb"
const CLUSTER := "res://assets/models/dressing/w3_monsoon_cluster.glb"

const STYLE := {
	"top": Color(0.20, 0.56, 0.62),
	"top_blend": 0.14,
	"rim": Color(0.65, 0.96, 1.0),
	"rim_s": 0.34,
	"shadow": Color(0.08, 0.20, 0.32),
	"tex": "wood_planks",
	"tex_scale": 0.38,
	"tex_blend": 0.62,
	"wetness": 0.75,
}


func build(start_pos: Vector3, audit: Array) -> Vector3:
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 355.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	for story in range(7):
		var sy := 355.0 + story * 26.0 + 12.0
		for w in range(4):
			var wa := w * 90.0 + story * 22.5
			var wp := WorldHelper.spiral_pt(wa, 17.5, sy)
			WorldHelper.add_warm_light_pool(self, wp, Color(1.0, 0.72, 0.30), 3.8, 20.0, true, 2.4, (w % 2 == 0))

	WorldHelper.add_parallax_ring(self, 2, 420.0, 160.0, 250.0, 14, false, 3011)
	WorldHelper.add_parallax_ring(self, 2, 495.0, 260.0, 390.0, 16, true, 3012)

	# =========================================================================
	# ACT 7 (355m -> 412m): Monsoon Tailwinds, Torii Slide-Gate & Domino Paper Sprint!
	# =========================================================================
	var cp1 := start_pos + Vector3(-2.0, 2.5, -8.5)
	WorldHelper.add_static_box_platform(self, PAGODA, cp1, Vector3(5.6, 0.6, 5.6), Vector3(1.25, 1.0, 1.25), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w3_cp1", 2, cp1, 20.0, true, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp1 + Vector3(2.4, 0.0, -2.0), -35.0, STYLE, Color(1.0, 0.74, 0.34))

	# Telegraphed Monsoon Storm Wind Zone #1 (sweeping tailwind across the north rim!)
	WorldHelper.add_monsoon_wind(self, Vector3(0.0, 382.0, -18.0), Vector3(68.0, 56.0, 42.0), Vector3(-0.92, 0.14, 0.25), 21.0)

	WorldHelper.add_landmark(self, "res://assets/models/scenery/torii_sky_gate.glb", Vector3(-2.0, 376.5, -26.5), Vector3(1.15, 1.15, 1.15), Vector3(0.0, 18.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, "res://assets/models/scenery/torii_sky_gate.glb", Vector3(11.5, 436.5, 25.0), Vector3(1.2, 1.2, 1.2), Vector3(0.0, -60.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, "res://assets/models/scenery/torii_sky_gate.glb", Vector3(-1.0, 475.0, -26.5), Vector3(1.15, 1.15, 1.15), Vector3(0.0, 80.0, 0.0), STYLE)
	WorldHelper.add_warm_light_pool(self, Vector3(-2.0, 384.0, -26.5), Color(1.0, 0.72, 0.28), 4.6, 24.0, true, 3.0)
	WorldHelper.add_warm_light_pool(self, Vector3(-21.5, 390.0, -13.5), Color(1.0, 0.74, 0.32), 3.8, 20.0, true, 2.4)

	WorldHelper.add_landmark(self, CRANE, Vector3(6.0, 388.0, -34.0), Vector3(1.6, 1.6, 1.6), Vector3(8.0, 35.0, -10.0), {"tex": "washi_paper", "tex_scale": 0.45, "tex_blend": 0.65, "rim": Color(0.85, 0.98, 1.0), "rim_s": 0.32})
	WorldHelper.add_landmark(self, CRANE, Vector3(-38.0, 445.0, 6.0), Vector3(1.8, 1.8, 1.8), Vector3(-6.0, 130.0, 8.0), {"tex": "washi_paper", "tex_scale": 0.45, "tex_blend": 0.65, "rim": Color(0.85, 0.98, 1.0), "rim_s": 0.32})
	WorldHelper.add_landmark(self, CRANE, Vector3(18.0, 505.0, 32.0), Vector3(1.9, 1.9, 1.9), Vector3(10.0, -110.0, -12.0), {"tex": "washi_paper", "tex_scale": 0.45, "tex_blend": 0.65, "rim": Color(0.85, 0.98, 1.0), "rim_s": 0.32})
	for i in range(12):
		var ang := i * 30.0
		var lpos := WorldHelper.spiral_pt(ang, 32.0, 368.0 + i * 14.5)
		WorldHelper.add_landmark(self, LANTERN, lpos, Vector3(1.3, 1.3, 1.3), Vector3(0.0, ang, 0.0), {}, 180.0, true)
		if i % 2 == 0:
			WorldHelper.add_warm_light_pool(self, lpos, Color(1.0, 0.70, 0.26), 3.4, 18.0, true, 2.2)

	WorldHelper.add_catenary_lanterns(self, Vector3(-2.0, 388.5, -24.5), Vector3(-1.5, 385.0, -17.5), 5, 1.0, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(-21.0, 418.5, 12.5), Vector3(-14.5, 416.0, 9.5), 5, 1.0, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(10.5, 446.5, 23.0), Vector3(8.0, 443.0, 16.5), 5, 1.0, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(-1.0, 486.0, -24.5), Vector3(-1.0, 483.0, -16.5), 5, 1.0, Color(1.0, 0.66, 0.32))

	for i in range(7):
		var ga := i * 52.0 - 15.0
		var gp := WorldHelper.spiral_pt(ga, 24.0, 384.0 + i * 23.0)
		WorldHelper.add_landmark(self, "res://assets/models/scenery/lantern_garland.glb", gp, Vector3(1.45, 1.45, 1.45), Vector3(0.0, ga + 90.0, 0.0), {}, 175.0, true)

	_spawn_monsoon_rain(Vector3(0.0, 445.0, 0.0))

	WorldHelper.add_world_hint(self, cp1 + Vector3(-2.5, 2.6, -3.5), "MONSOON GUSTS", "Watch the storm swell — ride tailwinds across huge gaps!")
	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(17.0, 358.5, -20.5), 22.0, 2.4, Vector3(-3.0, 0.0, -2.0), STYLE, audit)
	WorldHelper.add_dash_prism(self, Vector3(8.5, 369.5, -26.0), Color(0.50, 0.96, 1.0), 11.2, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(8.5, 370.0, -26.0), Vector3(-2.0, 378.5, -26.5), 3.2, 4)

	var pg1 := Vector3(-2.0, 377.5, -26.5)
	WorldHelper.add_static_box_platform(self, PAGODA, pg1, Vector3(5.4, 0.6, 5.4), Vector3.ONE, Vector3(0.0, 18.0, 0.0), STYLE, audit)
	WorldHelper.add_slide_obstacle(self, pg1, 108.0, 4.6, Color(0.98, 0.42, 0.30))

	# DOMINO ORIGAMI BRIDGE #1 (snaps open one beat ahead, folds shut behind — DON'T STOP!)
	WorldHelper.add_world_hint(self, Vector3(-8.5, 382.5, -24.5), "DOMINO PAPER SPRINT!", "Tiles unfold ahead & fold shut behind — keep sprinting!")
	var bridge1_pts := [
		Vector3(-10.0, 380.2, -24.0),
		Vector3(-16.5, 383.0, -19.5),
		Vector3(-21.5, 386.0, -13.5),
		Vector3(-25.0, 389.0, -6.5),
	]
	var prev_domino: FoldingBridge = null
	for idx in range(bridge1_pts.size()):
		var tile := WorldHelper.add_folding_tile(self, bridge1_pts[idx], Vector3(0.0, 52.0 - idx * 14.0, 0.0), audit, true, idx == 0)
		if prev_domino != null:
			prev_domino.next_domino_tile = tile
		prev_domino = tile
	WorldHelper.add_solar_mote_arc(self, Vector3(-10.0, 381.0, -24.0), Vector3(-25.0, 389.8, -6.5), 2.8, 5)

	var ud1 := Vector3(-26.5, 391.5, 2.0)
	WorldHelper.add_static_box_platform(self, PAGODA, ud1, Vector3(5.4, 0.6, 5.4), Vector3(0.95, 1.0, 0.95), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, ud1 + Vector3(-1.8, 0.0, -1.6), 95.0, STYLE, Color(1.0, 0.74, 0.34))

	# SUN-SHARD TRIAL #3: Monsoon Updraft Sky-Rings (awards w3_s1!)
	WorldHelper.add_shard_trial(self, ud1 + Vector3(-0.5, 0.0, 1.2), "w3_s1", "MONSOON THERMAL TRIAL", PackedVector3Array([
		ud1 + Vector3(0.5, 5.5, 4.5),
		ud1 + Vector3(0.5, 11.5, 5.5),
		ud1 + Vector3(1.0, 17.5, 7.5),
		Vector3(-24.0, 413.0, 11.5),
	]), 11.5)

	WorldHelper.add_updraft(self, ud1 + Vector3(0.5, 0.5, 4.5), 21.0, 3.2, Color(0.52, 0.96, 1.0), audit)
	WorldHelper.add_solar_mote_arc(self, ud1 + Vector3(0.5, 2.5, 4.5), Vector3(-23.0, 412.2, 13.5), 4.6, 4)

	# Checkpoint 2: Twilight Teahouse Eave (Y = 411.5m)
	var cp2 := Vector3(-23.0, 411.5, 13.5)
	WorldHelper.add_static_box_platform(self, PAGODA, cp2, Vector3(5.6, 0.6, 5.6), Vector3(1.2, 1.0, 1.2), Vector3(0.0, -30.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w3_cp2", 2, cp2, 135.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp2 + Vector3(-2.1, 0.0, 1.9), -30.0, STYLE, Color(1.0, 0.74, 0.34))

	# =========================================================================
	# ACT 8 (411.5m -> 476m): MULTI-CRANE MID-FLIGHT RELAY + PAPER-RIBBON GRIND RAIL!
	# =========================================================================
	WorldHelper.add_soaring_crane(self, Vector3(-28.2, 412.2, 19.5), Vector3(-11.5, 427.5, 34.5), Vector3(11.5, 438.2, 31.2), 9.0, 1.55)
	# Second Soaring Crane chaining from Upper Pagoda around the storm rim!
	WorldHelper.add_soaring_crane(self, Vector3(16.5, 438.5, 25.5), Vector3(31.0, 452.5, 1.5), Vector3(18.5, 463.5, -21.5), 9.5, 1.55)
	WorldHelper.add_world_hint(self, Vector3(-26.0, 414.2, 17.5), "MULTI-CRANE SKY RELAY", "Ride Giant Origami Cranes mid-flight — or sprint the Domino Bridges!")

	WorldHelper.add_folding_tile(self, Vector3(-16.5, 414.5, 20.5), Vector3(0.0, -48.0, 0.0), audit, true, true)
	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(-9.0, 417.5, 25.5), 23.0, 2.4, Vector3(3.5, 0.0, 1.0), STYLE, audit)
	WorldHelper.add_dash_prism(self, Vector3(1.5, 429.0, 27.5), Color(1.0, 0.78, 0.34), 11.2, audit)
	var pg2 := Vector3(11.5, 437.5, 25.0)
	WorldHelper.add_static_box_platform(self, PAGODA, pg2, Vector3(5.4, 0.6, 5.4), Vector3.ONE, Vector3(0.0, -60.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, pg2 + Vector3(1.9, 0.0, 1.8), -60.0, STYLE, Color(1.0, 0.74, 0.34))

	# Domino Origami Sprint #2 (fast alternative to Crane #2)
	var bridge2_pts := [
		Vector3(19.0, 440.5, 19.5),
		Vector3(24.0, 443.8, 12.5),
		Vector3(26.5, 447.0, 4.5),
		Vector3(26.5, 450.2, -4.0),
		Vector3(23.5, 453.5, -12.0),
	]
	var prev_d2: FoldingBridge = null
	for idx in range(bridge2_pts.size()):
		var t2 := WorldHelper.add_folding_tile(self, bridge2_pts[idx], Vector3(0.0, -85.0 - idx * 14.0, 0.0), audit, true, idx == 0)
		if prev_d2 != null:
			prev_d2.next_domino_tile = t2
		prev_d2 = t2
	WorldHelper.add_sun_shard(self, "w3_s2", Vector3(26.5, 453.0, 4.5))

	# PAPER-RIBBON GRIND RAIL curving from the eastern eaves straight into CP3!
	WorldHelper.add_grind_rail(self, PackedVector3Array([
		Vector3(18.5, 456.8, -19.0),
		Vector3(11.5, 464.5, -25.0),
		Vector3(4.0, 471.5, -27.2),
		Vector3(-1.0, 476.6, -26.5),
	]), Color(0.98, 0.88, 0.72), 23.0, 9.8, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(18.5, 458.0, -19.0), Vector3(4.0, 472.5, -27.2), 2.4, 5)

	# Checkpoint 3: Crane-Nest Pagoda (Y = 476m)
	var cp3 := Vector3(-1.0, 476.0, -26.5)
	WorldHelper.add_static_box_platform(self, PAGODA, cp3, Vector3(5.6, 0.6, 5.6), Vector3(1.2, 1.0, 1.2), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w3_cp3", 2, cp3, 80.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp3 + Vector3(2.1, 0.0, -2.0), 0.0, STYLE, Color(1.0, 0.74, 0.34))

	# Exposed Overlook #2
	WorldHelper.add_static_box_platform(self, PAGODA, cp3 + Vector3(0.0, 0.15, -6.5), Vector3(5.4, 0.6, 5.4), Vector3(0.24, 0.72, 2.05), Vector3.ZERO, STYLE, [])
	WorldHelper.add_solar_mote_arc(self, cp3 + Vector3(0.0, 1.0, -3.5), cp3 + Vector3(0.0, 1.2, -10.8), 1.4, 3)
	WorldHelper.add_world_hint(self, cp3 + Vector3(0.0, 2.1, -11.2), "CHRONICLE III — THE MONSOON PRAYERS", "Every paper crane carries a wish from 476m below. Step to the edge and look down.")

	# =========================================================================
	# ACT 9 (476m -> 539m): WORLD 3 CLIMAX — DOWNHILL RAIN CHUTE + 3-PRISM STORM RELAY!
	# =========================================================================
	WorldHelper.add_monsoon_wind(self, Vector3(-14.0, 514.0, 14.0), Vector3(58.0, 58.0, 54.0), Vector3(0.85, 0.18, 0.45), 22.0)

	# Downhill Wet-Pagoda Momentum Chute -> launches straight into a Mid-Air Prism & Upper Eave!
	WorldHelper.add_world_hint(self, Vector3(-7.0, 478.6, -24.5), "CLIMAX · STORM CHUTE LAUNCH!", "Slide DOWN the wet pagoda chute to soar into the Storm Prism Chain!")
	WorldHelper.add_momentum_ramp(self, Vector3(-8.0, 476.8, -24.8), 128.0, 13.0, 4.6, 21.5, 25.5, Color(0.52, 0.96, 1.0), audit)
	WorldHelper.add_dash_prism(self, Vector3(-24.8, 491.5, -11.5), Color(0.52, 0.96, 1.0), 11.4, audit)
	var pg3 := Vector3(-26.5, 500.2, -3.5)
	WorldHelper.add_static_box_platform(self, PAGODA, pg3, Vector3(5.4, 0.6, 5.4), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, pg3 + Vector3(-1.9, 0.0, -1.8), 90.0, STYLE, Color(1.0, 0.74, 0.34))

	# CLIMAX "FLOOR IS LAVA" 3-PRISM STORM CHAIN riding the Monsoon Tailwind straight to the Mirror Gate!
	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(-25.5, 505.5, 6.0), 23.0, 2.4, Vector3(2.2, 0.0, 4.2), STYLE, audit)
	WorldHelper.add_dash_prism(self, Vector3(-20.0, 515.0, 15.5), Color(0.55, 0.98, 1.0), 10.6, audit)
	WorldHelper.add_dash_prism(self, Vector3(-13.0, 520.5, 22.0), Color(1.0, 0.84, 0.34), 10.6, audit)
	WorldHelper.add_sun_shard(self, "w3_s3", Vector3(-13.0, 524.5, 22.0))
	WorldHelper.add_dash_prism(self, Vector3(-5.0, 525.5, 25.8), Color(0.55, 0.98, 1.0), 10.6, audit)
	WorldHelper.add_updraft(self, Vector3(-2.5, 522.0, 26.5), 18.0, 3.4, Color(1.0, 0.82, 0.45), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-2.5, 524.0, 26.5), Vector3(3.5, 539.5, 26.5), 4.0, 4)

	# World 3 -> World 4 Mirror Gallery Ascension Gate (Y = 538.5m)
	var gate_pos := Vector3(3.5, 538.5, 26.5)
	WorldHelper.add_static_box_platform(self, PAGODA, gate_pos, Vector3(5.8, 0.6, 5.8), Vector3(1.3, 1.0, 1.3), Vector3(0.0, -80.0, 0.0), STYLE, audit, "world_gate_pad")
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(3.5, 0.0, -1.0), Vector3.ONE, Vector3(0.0, -75.0, 0.0), STYLE)
	return gate_pos


func _spawn_monsoon_rain(center: Vector3) -> void:
	var gp := GPUParticles3D.new()
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gp.position = center
	gp.amount = 240
	gp.lifetime = 3.2
	gp.visibility_aabb = AABB(Vector3(-48, -90, -48), Vector3(96, 180, 96))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(38.0, 82.0, 38.0)
	pm.direction = Vector3(0.08, -1.0, 0.05)
	pm.spread = 4.0
	pm.initial_velocity_min = 9.0
	pm.initial_velocity_max = 15.0
	pm.gravity = Vector3.ZERO
	gp.process_material = pm

	var m := BoxMesh.new()
	m.size = Vector3(0.045, 1.35, 0.045)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.72, 0.96, 1.0, 0.58)
	m.material = mat
	gp.draw_pass_1 = m
	add_child(gp)
