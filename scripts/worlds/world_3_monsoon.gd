extends Node3D
class_name World3Monsoon
## World 3: The Origami Monsoon (355m -> 540m)
## Teal twilight clouds, soaring 7-story Japanese Pagoda Core with glowing shoji windows & rain chains,
## wet puddle-sheen rooftops, festival lantern catenaries, giant origami cranes, and unfolding paper bridges.

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
	# =========================================================================
	# CENTRAL SOLSTICE SPIRE CORE (World 3: 7-Story Cloud-Pagoda Tower!)
	# =========================================================================
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 355.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	# Warm glowing golden shoji window pools & halos around every story of the Pagoda!
	for story in range(7):
		var sy := 355.0 + story * 26.0 + 12.0
		for w in range(4):
			var wa := w * 90.0 + story * 22.5
			var wp := WorldHelper.spiral_pt(wa, 17.5, sy)
			WorldHelper.add_warm_light_pool(self, wp, Color(1.0, 0.72, 0.30), 3.8, 20.0, true, 2.4, (w % 2 == 0))

	# 2 Biome-Specific Deep Jade-Teal Distant Parallax Silhouette Rings (160-390m out!)
	WorldHelper.add_parallax_ring(self, 2, 420.0, 160.0, 250.0, 14, false, 3011)
	WorldHelper.add_parallax_ring(self, 2, 495.0, 260.0, 390.0, 16, true, 3012)

	# =========================================================================
	# ACT 7 (355m -> 415m): Pagoda Arrival & Silk Parasol Bounce Chain
	# =========================================================================
	var cp1 := start_pos + Vector3(-2.0, 2.5, -8.5)
	WorldHelper.add_static_box_platform(self, PAGODA, cp1, Vector3(5.6, 0.6, 5.6), Vector3(1.25, 1.0, 1.25), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w3_cp1", 2, cp1, 20.0, true, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp1 + Vector3(2.4, 0.0, -2.0), -35.0, STYLE, Color(1.0, 0.74, 0.34))

	# Monumental Vermilion & Gold Floating Japanese Torii Sky-Gates framing the Twilight Monsoon
	WorldHelper.add_landmark(self, "res://assets/models/scenery/torii_sky_gate.glb", Vector3(-2.0, 376.5, -26.5), Vector3(1.15, 1.15, 1.15), Vector3(0.0, 18.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, "res://assets/models/scenery/torii_sky_gate.glb", Vector3(11.5, 436.5, 25.0), Vector3(1.2, 1.2, 1.2), Vector3(0.0, -60.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, "res://assets/models/scenery/torii_sky_gate.glb", Vector3(-1.0, 475.0, -26.5), Vector3(1.15, 1.15, 1.15), Vector3(0.0, 80.0, 0.0), STYLE)
	WorldHelper.add_warm_light_pool(self, Vector3(-2.0, 384.0, -26.5), Color(1.0, 0.72, 0.28), 4.6, 24.0, true, 3.0)
	WorldHelper.add_warm_light_pool(self, Vector3(-21.5, 390.0, -13.5), Color(1.0, 0.74, 0.32), 3.8, 20.0, true, 2.4)

	# Surreal Giant Origami Cranes & Glowing Festival Lanterns drifting around the spire
	WorldHelper.add_landmark(self, CRANE, Vector3(6.0, 388.0, -34.0), Vector3(1.6, 1.6, 1.6), Vector3(8.0, 35.0, -10.0), {"tex": "washi_paper", "tex_scale": 0.45, "tex_blend": 0.65, "rim": Color(0.85, 0.98, 1.0), "rim_s": 0.32})
	WorldHelper.add_landmark(self, CRANE, Vector3(-38.0, 445.0, 6.0), Vector3(1.8, 1.8, 1.8), Vector3(-6.0, 130.0, 8.0), {"tex": "washi_paper", "tex_scale": 0.45, "tex_blend": 0.65, "rim": Color(0.85, 0.98, 1.0), "rim_s": 0.32})
	WorldHelper.add_landmark(self, CRANE, Vector3(18.0, 505.0, 32.0), Vector3(1.9, 1.9, 1.9), Vector3(10.0, -110.0, -12.0), {"tex": "washi_paper", "tex_scale": 0.45, "tex_blend": 0.65, "rim": Color(0.85, 0.98, 1.0), "rim_s": 0.32})
	for i in range(12):
		var ang := i * 30.0
		var lpos := WorldHelper.spiral_pt(ang, 32.0, 368.0 + i * 14.5)
		WorldHelper.add_landmark(self, LANTERN, lpos, Vector3(1.3, 1.3, 1.3), Vector3(0.0, ang, 0.0), {}, 180.0, true)
		if i % 2 == 0:
			WorldHelper.add_warm_light_pool(self, lpos, Color(1.0, 0.70, 0.26), 3.4, 18.0, true, 2.2)

	# High overhead MultiMesh catenary paper lantern strings draping between Pagoda eaves (>= 6m above platforms!)
	WorldHelper.add_catenary_lanterns(self, Vector3(-2.0, 388.5, -24.5), Vector3(-1.5, 385.0, -17.5), 5, 1.0, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(-21.0, 418.5, 12.5), Vector3(-14.5, 416.0, 9.5), 5, 1.0, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(10.5, 446.5, 23.0), Vector3(8.0, 443.0, 16.5), 5, 1.0, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(-1.0, 486.0, -24.5), Vector3(-1.0, 483.0, -16.5), 5, 1.0, Color(1.0, 0.66, 0.32))

	for i in range(7):
		var ga := i * 52.0 - 15.0
		var gp := WorldHelper.spiral_pt(ga, 24.0, 384.0 + i * 23.0)
		WorldHelper.add_landmark(self, "res://assets/models/scenery/lantern_garland.glb", gp, Vector3(1.45, 1.45, 1.45), Vector3(0.0, ga + 90.0, 0.0), {}, 175.0, true)

	# Monsoon raindrop streaks + suspended slow-motion shimmering rain!
	_spawn_monsoon_rain(Vector3(0.0, 445.0, 0.0))

	# Joyful Silk Parasol Aerial Bounce Cascade
	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(17.0, 358.5, -20.5), 22.0, 2.4, Vector3(-3.0, 0.0, -2.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(17.0, 359.5, -20.5), Vector3(8.5, 369.0, -26.0), 4.0, 4)
	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(8.5, 368.0, -26.0), 22.5, 2.4, Vector3(-3.5, 0.0, 0.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(8.5, 369.0, -26.0), Vector3(-2.0, 378.2, -26.5), 4.2, 4)
	var pg1 := Vector3(-2.0, 377.5, -26.5)
	WorldHelper.add_static_box_platform(self, PAGODA, pg1, Vector3(5.4, 0.6, 5.4), Vector3.ONE, Vector3(0.0, 18.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, pg1 + Vector3(-1.9, 0.0, -1.9), 20.0, STYLE, Color(1.0, 0.74, 0.34))

	# First Surreal Unfolding Origami Bridge
	var bridge1 := [
		Vector3(-10.0, 380.2, -24.0),
		Vector3(-16.5, 383.0, -19.5),
		Vector3(-21.5, 386.0, -13.5),
		Vector3(-25.0, 389.0, -6.5),
	]
	for idx in range(bridge1.size()):
		WorldHelper.add_folding_tile(self, bridge1[idx], Vector3(0.0, 52.0 - idx * 14.0, 0.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-10.0, 381.0, -24.0), Vector3(-25.0, 389.8, -6.5), 2.8, 5)

	WorldHelper.add_sun_shard(self, "w3_s1", Vector3(-19.0, 389.0, -16.5))

	var ud1 := Vector3(-26.5, 391.5, 2.0)
	WorldHelper.add_static_box_platform(self, PAGODA, ud1, Vector3(5.4, 0.6, 5.4), Vector3(0.9, 1.0, 0.9), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, ud1 + Vector3(-1.8, 0.0, -1.6), 95.0, STYLE, Color(1.0, 0.74, 0.34))
	WorldHelper.add_updraft(self, ud1 + Vector3(0.5, 0.5, 4.5), 21.0, 3.2, Color(0.52, 0.96, 1.0), audit)
	WorldHelper.add_solar_mote_arc(self, ud1 + Vector3(0.5, 2.5, 4.5), Vector3(-23.0, 412.2, 13.5), 4.6, 4)
	WorldHelper.add_landmark(self, CRANE, ud1 + Vector3(-5.0, 12.0, 8.0), Vector3(0.95, 0.95, 0.95), Vector3(12.0, 15.0, 0.0), {})

	# Checkpoint 2: Twilight Teahouse Eave (Y = 412m)
	var cp2 := Vector3(-23.0, 411.5, 13.5)
	WorldHelper.add_static_box_platform(self, PAGODA, cp2, Vector3(5.6, 0.6, 5.6), Vector3(1.2, 1.0, 1.2), Vector3(0.0, -30.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w3_cp2", 2, cp2, 135.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp2 + Vector3(-2.1, 0.0, 1.9), -30.0, STYLE, Color(1.0, 0.74, 0.34))

	# =========================================================================
	# ACT 8 (412m -> 476m): Monsoon Parasol Hop & High-Speed Origami Ribbon
	# =========================================================================
	WorldHelper.add_folding_tile(self, Vector3(-16.5, 414.5, 20.5), Vector3(0.0, -48.0, 0.0), audit)
	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(-9.0, 417.5, 25.5), 23.0, 2.4, Vector3(3.5, 0.0, 1.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-9.0, 418.5, 25.5), Vector3(1.5, 428.5, 27.5), 4.2, 4)
	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(1.5, 427.5, 27.5), 23.0, 2.4, Vector3(3.5, 0.0, -1.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(1.5, 428.5, 27.5), Vector3(11.5, 438.2, 25.0), 4.2, 4)
	var pg2 := Vector3(11.5, 437.5, 25.0)
	WorldHelper.add_static_box_platform(self, PAGODA, pg2, Vector3(5.4, 0.6, 5.4), Vector3.ONE, Vector3(0.0, -60.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, pg2 + Vector3(1.9, 0.0, 1.8), -60.0, STYLE, Color(1.0, 0.74, 0.34))

	var bridge2 := [
		Vector3(19.0, 440.5, 19.5),
		Vector3(24.0, 443.8, 12.5),
		Vector3(26.5, 447.0, 4.5),
		Vector3(26.5, 450.2, -4.0),
		Vector3(23.5, 453.5, -12.0),
	]
	for idx in range(bridge2.size()):
		WorldHelper.add_folding_tile(self, bridge2[idx], Vector3(0.0, -85.0 - idx * 14.0, 0.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(19.0, 441.2, 19.5), Vector3(23.5, 454.2, -12.0), 3.0, 5)
	WorldHelper.add_sun_shard(self, "w3_s2", Vector3(26.5, 453.0, 4.5))

	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(18.0, 456.5, -19.5), 24.0, 2.4, Vector3(-3.0, 0.0, -2.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(18.0, 457.5, -19.5), Vector3(9.5, 468.0, -25.0), 4.4, 4)
	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(9.5, 467.0, -25.0), 22.0, 2.4, Vector3(-3.5, 0.0, 0.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(9.5, 468.0, -25.0), Vector3(-1.0, 476.8, -26.5), 4.0, 4)

	# Checkpoint 3: Crane-Nest Pagoda (Y = 476m)
	var cp3 := Vector3(-1.0, 476.0, -26.5)
	WorldHelper.add_static_box_platform(self, PAGODA, cp3, Vector3(5.6, 0.6, 5.6), Vector3(1.2, 1.0, 1.2), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w3_cp3", 2, cp3, 80.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp3 + Vector3(2.1, 0.0, -2.0), 0.0, STYLE, Color(1.0, 0.74, 0.34))

	# =========================================================================
	# ACT 9 (476m -> 540m): Upward Waterfall Thermal & Origami Sky-Sprint
	# =========================================================================
	WorldHelper.add_folding_tile(self, Vector3(-9.5, 479.0, -24.5), Vector3(0.0, 72.0, 0.0), audit)
	WorldHelper.add_folding_tile(self, Vector3(-17.0, 482.2, -20.0), Vector3(0.0, 52.0, 0.0), audit)
	WorldHelper.add_updraft(self, Vector3(-23.0, 483.0, -13.0), 22.0, 3.4, Color(0.55, 0.95, 1.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-23.0, 485.0, -13.0), Vector3(-26.5, 504.2, -4.5), 4.6, 4)
	var pg3 := Vector3(-26.5, 503.5, -4.5)
	WorldHelper.add_static_box_platform(self, PAGODA, pg3, Vector3(5.4, 0.6, 5.4), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, pg3 + Vector3(-1.9, 0.0, -1.8), 90.0, STYLE, Color(1.0, 0.74, 0.34))

	WorldHelper.add_bounce_pad(self, PARASOL, Vector3(-25.5, 506.5, 5.5), 23.0, 2.4, Vector3(1.5, 0.0, 3.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-25.5, 507.5, 5.5), Vector3(-21.0, 516.8, 15.0), 4.2, 4)
	WorldHelper.add_folding_tile(self, Vector3(-21.0, 516.0, 15.0), Vector3(0.0, -35.0, 0.0), audit)
	WorldHelper.add_folding_tile(self, Vector3(-14.5, 519.2, 21.5), Vector3(0.0, -50.0, 0.0), audit)
	WorldHelper.add_sun_shard(self, "w3_s3", Vector3(-14.5, 524.5, 21.5))
	WorldHelper.add_updraft(self, Vector3(-6.5, 520.0, 25.5), 20.0, 3.3, Color(1.0, 0.80, 0.45), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-6.5, 522.0, 25.5), Vector3(3.5, 539.2, 26.5), 4.5, 4)

	# World 3 -> World 4 Mirror Gallery Ascension Gate (Y = 539m)
	var gate_pos := Vector3(3.5, 538.5, 26.5)
	WorldHelper.add_static_box_platform(self, PAGODA, gate_pos, Vector3(5.8, 0.6, 5.8), Vector3(1.3, 1.0, 1.3), Vector3(0.0, -80.0, 0.0), STYLE, audit, "world_gate_pad")
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(3.5, 0.0, -1.0), Vector3.ONE, Vector3(0.0, -75.0, 0.0), STYLE)
	return gate_pos


func _spawn_monsoon_rain(center: Vector3) -> void:
	# Shimmering monsoon rain streaks falling gently through the lantern-lit twilight sky!
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
