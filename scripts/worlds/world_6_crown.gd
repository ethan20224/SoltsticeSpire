extends Node3D
class_name World6Crown
## World 6: The Crown of the Sun (920m -> 1,085m)
## Signature Twist: THE MOVING ARMILLARY FINALE!
## 3 giant solid, walkable, counter-rotating Solar Armillary Rings with sweeping Solar Beams
## (jump low / slide mid), remixing Phase-Swap Glass, Dash-Prisms, Solar Grind Rails,
## Meteor Skylights, & Momentum Portals all the way to the 1,085m Summit Crown!

const MONOLITH := "res://assets/models/world6_crown/obsidian_monolith.glb"
const DAIS := "res://assets/models/world6_crown/obsidian_dais.glb"
const SUMMIT := "res://assets/models/world6_crown/summit_crown_altar.glb"
const SHATTER := "res://assets/models/world4_mirrors/shatter_pane.glb"
const JELLY := "res://assets/models/world5_library/dream_jelly_pad.glb"
const VENT := "res://assets/models/world2_foundry/steam_vent.glb"
const CORE := "res://assets/models/tower_cores/w6_crown_core.glb"
const BRAZIER := "res://assets/models/dressing/w6_solar_brazier.glb"

const STYLE := {
	"top": Color(1.0, 0.80, 0.30),
	"top_blend": 0.12,
	"rim": Color(1.0, 0.84, 0.42),
	"rim_s": 0.42,
	"shadow": Color(0.16, 0.08, 0.28),
	"tex": "obsidian_fluted",
	"tex_scale": 0.32,
	"tex_blend": 0.72,
}


func build(start_pos: Vector3, audit: Array) -> Vector3:
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 920.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	for lvl in range(4):
		var ly := 920.0 + 30.0 + lvl * 34.0
		for k in range(4):
			var ka := k * 90.0 + rad_to_deg(lvl * 0.55)
			var kp := WorldHelper.spiral_pt(ka, 20.4, ly)
			WorldHelper.add_warm_light_pool(self, kp, Color(1.0, 0.72, 0.28), 4.0, 22.0, true, 2.6, (k % 2 == 0))

	WorldHelper.add_parallax_ring(self, 5, 980.0, 170.0, 265.0, 14, false, 6011)
	WorldHelper.add_parallax_ring(self, 5, 1055.0, 275.0, 410.0, 16, true, 6012)

	# =========================================================================
	# ACT 16 (920m -> 976m): Phase-Swap Remix + WALKABLE ROTATING ARMILLARY RING #1!
	# =========================================================================
	var cp1 := start_pos + Vector3(3.5, 2.5, -8.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, cp1, 3.0, 0.8, Vector3(1.35, 1.0, 1.35), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w6_cp1", 5, cp1, 5.0, true, false, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, cp1 + Vector3(2.4, 0.0, 1.6), 0.0, STYLE, Color(1.0, 0.74, 0.28))

	WorldHelper.add_catenary_lanterns(self, Vector3(-24.0, 983.5, 6.0), Vector3(-16.0, 985.0, 4.0), 5, 0.95, Color(1.0, 0.68, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(9.5, 1040.5, -21.5), Vector3(6.5, 1042.0, -14.5), 5, 0.95, Color(1.0, 0.68, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(-19.5, 1068.0, -1.5), Vector3(-12.5, 1069.5, -1.0), 5, 0.95, Color(1.0, 0.68, 0.30))

	WorldHelper.add_wall_run(self, MONOLITH, Vector3(28.5, 924.4, -4.5), Vector3(0.0, -82.0, 0.0), Vector3(9.4, 4.6, 1.0), false, 0, audit)
	WorldHelper.add_phase_platform(self, Vector3(23.5, 929.5, -14.5), 0, Vector3(4.2, 0.42, 4.2), 0.0, audit)
	WorldHelper.add_phase_platform(self, Vector3(16.0, 934.0, -21.5), 1, Vector3(4.2, 0.42, 4.2), 0.0, audit)
	WorldHelper.add_dash_prism(self, Vector3(10.0, 939.5, -24.8), Color(1.0, 0.82, 0.30), 10.5, audit)
	WorldHelper.add_sun_shard(self, "w6_s1", Vector3(10.0, 943.5, -24.8))

	var p1_in := Vector3(3.5, 942.5, -26.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, p1_in, 3.0, 0.8, Vector3(1.05, 1.0, 1.05), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, p1_in + Vector3(1.8, 0.0, -1.6), 0.0, STYLE, Color(1.0, 0.74, 0.28))

	# SOLID WALKABLE ROTATING ARMILLARY RING #1 (Y = 962m, R = 25.5m, 2 sweeping Solar Beams!)
	var p1_out := Vector3(-12.5, 962.5, -22.2)
	WorldHelper.add_portal_pair(self, p1_in, 82.0, p1_out, 125.0, 17.5, audit, true, false)
	WorldHelper.add_world_hint(self, p1_out + Vector3(-2.5, 2.8, 2.0), "ARMILLARY RING I!", "Run the rotating Golden Ring — Jump Low Beams · Slide Mid Beams!")
	WorldHelper.add_armillary_ring(self, Vector3(0.0, 962.0, 0.0), 25.5, 3.8, 11.0, Vector3(3.5, 0.0, -3.0), 2, audit)

	WorldHelper.add_bounce_pad(self, VENT, Vector3(-26.5, 965.5, -4.0), 23.8, 2.4, Vector3(0.0, 0.0, 3.8), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-26.5, 966.5, -4.0), Vector3(-26.0, 976.8, 6.5), 4.0, 4)

	# Checkpoint 2: Solar Perigee Dais (Y = 976m)
	var cp2 := Vector3(-26.0, 976.0, 6.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, cp2, 3.0, 0.8, Vector3(1.35, 1.0, 1.35), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w6_cp2", 5, cp2, 145.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, cp2 + Vector3(-2.3, 0.0, 1.5), 90.0, STYLE, Color(1.0, 0.74, 0.28))

	# SUN-SHARD TRIAL #6: Stratosphere Rail & Prism Sprint (awards w6_s2!)
	WorldHelper.add_shard_trial(self, cp2 + Vector3(1.2, 0.0, 1.8), "w6_s2", "SOLAR PERIGEE TRIAL", PackedVector3Array([
		Vector3(-23.5, 980.0, 14.5),
		Vector3(-14.5, 988.0, 23.5),
		Vector3(-2.5, 994.0, 26.5),
		Vector3(8.5, 1001.5, 24.5),
	]), 12.0)

	# PRO SHORTCUT #5 + FLOW-EXPRESS BRIDGE
	WorldHelper.add_flow_express(self, Vector3(-29.5, 977.0, 11.0), -25.0, Vector3(3.6, 0.36, 8.5))
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-32.2, 977.5, 14.5), 26.2, 2.4, Vector3(6.5, 0.0, 6.5), STYLE, [])
	WorldHelper.add_tether_orb(self, Vector3(-16.0, 995.5, 27.5), [])
	WorldHelper.add_shortcut_beacon(self, Vector3(20.5, 1006.5, 17.5), -45.0, "SOLAR RING SKIP!", "STRATOSPHERE SHORTCUT")

	# =========================================================================
	# ACT 17 (976m -> 1,033m): Solar Grind Rail + Zero-G Tether + COUNTER-ROTATING ARMILLARY RING #2!
	# =========================================================================
	# High-speed Solar Grind Rail with Mid-Rail Slide-Duck Beam!
	WorldHelper.add_grind_rail(self, PackedVector3Array([
		Vector3(-23.5, 978.5, 14.5),
		Vector3(-13.5, 987.0, 24.0),
		Vector3(1.5, 995.0, 26.5),
	]), Color(1.0, 0.84, 0.30), 24.0, 11.5, audit)
	WorldHelper.add_slide_obstacle(self, Vector3(-13.5, 987.0, 24.0), -52.0, 4.6, Color(1.0, 0.44, 0.18))

	WorldHelper.add_gravity_bubble(self, Vector3(8.5, 998.0, 24.5), 12.5, audit)
	WorldHelper.add_tether_orb(self, Vector3(11.0, 1001.0, 23.5), audit)
	WorldHelper.add_dash_prism(self, Vector3(18.5, 1007.5, 19.0), Color(1.0, 0.84, 0.30), 10.6, audit)

	# SOLID WALKABLE COUNTER-ROTATING ARMILLARY RING #2 (Y = 1,012m, R = 25.5m, 3 Solar Beams!)
	WorldHelper.add_world_hint(self, Vector3(20.5, 1014.5, 16.5), "ARMILLARY RING II!", "Counter-rotating Solar Ring — surf the rim to the Obsidian Skylight!")
	WorldHelper.add_armillary_ring(self, Vector3(0.0, 1012.0, 0.0), 25.5, 3.6, -13.0, Vector3(-3.5, 30.0, 3.0), 3, audit)

	# Meteor-Slam Skylight right off Armillary Ring #2 -> launches to Tether Orb -> CP3!
	WorldHelper.add_meteor_trigger(self, Vector3(25.5, 1014.5, -4.0), "skylight", 27.5, Vector3(-3.5, 0.0, -7.2), "", audit)
	WorldHelper.add_tether_orb(self, Vector3(19.0, 1029.5, -16.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(19.0, 1029.5, -16.0), Vector3(10.5, 1033.8, -23.5), 2.4, 3)

	# Checkpoint 3: Last Threshold before the Summit Crown (Y = 1,033m)
	var cp3 := Vector3(10.5, 1033.0, -23.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, cp3, 3.0, 0.8, Vector3(1.35, 1.0, 1.35), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w6_cp3", 5, cp3, 68.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, cp3 + Vector3(2.2, 0.0, -1.6), -120.0, STYLE, Color(1.0, 0.74, 0.28))
	WorldHelper.add_world_hint(self, cp3 + Vector3(-1.8, 2.25, -2.0), "CHRONICLE VI — THE DYING SUN-HEART", "52m remain. Conquer the Final Armillary Ring & rekindle the Solstice Crown!")

	# =========================================================================
	# ACT 18 (1,033m -> 1,085m): GRAND ZENITH CLIMAX — PHASE + WALL + PRISM + ARMILLARY RING #3 -> CROWN!
	# =========================================================================
	WorldHelper.add_phase_platform(self, Vector3(1.5, 1036.2, -26.5), 0, Vector3(4.2, 0.42, 4.2), 88.0, audit)
	WorldHelper.add_phase_platform(self, Vector3(-7.0, 1039.5, -25.5), 1, Vector3(4.2, 0.42, 4.2), 68.0, audit)
	WorldHelper.add_wall_run(self, MONOLITH, Vector3(-18.5, 1042.5, -21.5), Vector3(0.0, 44.0, 0.0), Vector3(9.4, 4.6, 1.0), false, 0, audit)
	WorldHelper.add_dash_prism(self, Vector3(-23.5, 1048.5, -13.0), Color(1.0, 0.86, 0.34), 11.4, audit)

	# FINAL SOLID WALKABLE ARMILLARY RING #3 (Y = 1,058m, R = 22.0m, fast golden spin!)
	WorldHelper.add_armillary_ring(self, Vector3(0.0, 1058.0, 0.0), 22.0, 3.8, 15.0, Vector3(2.5, 0.0, -2.5), 2, audit)

	var pf_in := Vector3(-21.5, 1060.0, -1.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, pf_in, 3.0, 0.8, Vector3(1.1, 1.0, 1.1), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, pf_in + Vector3(-1.8, 0.0, 1.6), 30.0, STYLE, Color(1.0, 0.74, 0.28))
	var pf_out := Vector3(-15.0, 1077.5, 0.0)
	WorldHelper.add_portal_pair(self, pf_in, -85.0, pf_out, -90.0, 18.5, audit, true, false)
	WorldHelper.add_dash_prism(self, Vector3(-9.0, 1083.0, 0.0), Color(1.0, 0.88, 0.34), 10.2, audit)
	WorldHelper.add_sun_shard(self, "w6_s3", Vector3(-9.0, 1086.8, 0.0))
	WorldHelper.add_solar_mote_arc(self, pf_out + Vector3(1.5, 1.5, 0.0), Vector3(0.0, 1085.5, 0.0), 3.6, 5)

	# THE SUMMIT CROWN SANCTUARY OVERLOOK (Centered at (0, 1084.5, 0))
	var summit_pos := Vector3(0.0, 1084.5, 0.0)
	WorldHelper.add_static_cyl_platform(self, SUMMIT, summit_pos, 9.7, 1.2, Vector3.ONE, Vector3.ZERO, STYLE, audit, "summit_crown")
	WorldHelper.add_shrine(self, "summit_crown", 5, summit_pos + Vector3(0.0, 0.38, 0.0), 0.0, false, true, audit)
	WorldHelper.add_summit_celebration(self, summit_pos)

	WorldHelper.add_warm_light_pool(self, summit_pos + Vector3(0.0, 10.5, 0.0), Color(1.0, 0.84, 0.44), 6.5, 42.0, true, 5.2)
	for i in range(4):
		var ba := i * 90.0 + 45.0
		var bp := summit_pos + WorldHelper.spiral_pt(ba, 8.2, 1.6)
		WorldHelper.add_warm_light_pool(self, bp, Color(1.0, 0.72, 0.28), 3.6, 14.0, true, 2.0)

	return summit_pos
