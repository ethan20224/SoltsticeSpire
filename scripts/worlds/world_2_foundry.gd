extends Node3D
class_name World2Foundry
## World 2: Foundry of Floating Bells (175m -> 355m)
## Signature Twist: Musical Bell Shockwaves that awaken drawbridges & steam cannons,
## Active Knockback Pendulums & Slide-Under Sweeping Beams, Brass Pipe Grind Rails with mid-rail ducking,
## Cross-Spire Forge Pipe, Meteor Bellows, & the 2-Bell Great Carillon Arena Climax!

const GEAR := "res://assets/models/world2_foundry/brass_gear.glb"
const BELL := "res://assets/models/world2_foundry/curved_bell.glb"
const VENT := "res://assets/models/world2_foundry/steam_vent.glb"
const CATWALK := "res://assets/models/world2_foundry/foundry_catwalk.glb"
const GATE := "res://assets/models/common/world_gate.glb"
const CORE := "res://assets/models/tower_cores/w2_foundry_core.glb"
const CLUSTER := "res://assets/models/dressing/w2_forge_cluster.glb"

const STYLE := {
	"top": Color(0.95, 0.72, 0.30),
	"top_blend": 0.14,
	"rim": Color(1.0, 0.76, 0.38),
	"rim_s": 0.36,
	"shadow": Color(0.32, 0.16, 0.30),
	"tex": "hammered_brass",
	"tex_scale": 0.36,
	"tex_blend": 0.72,
}


func build(start_pos: Vector3, audit: Array) -> Vector3:
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 175.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	for lvl in range(5):
		var ly := 175.0 + 29.0 + lvl * 34.0
		for f in range(4):
			var fa := f * 90.0 + rad_to_deg(lvl * 0.4)
			var fp := WorldHelper.spiral_pt(fa, 18.2, ly)
			WorldHelper.add_warm_light_pool(self, fp, Color(1.0, 0.56, 0.16), 4.2, 22.0, true, 2.6, (f % 2 == 0))

	WorldHelper.add_parallax_ring(self, 1, 245.0, 160.0, 250.0, 14, false, 2011)
	WorldHelper.add_parallax_ring(self, 1, 310.0, 260.0, 390.0, 16, true, 2012)

	# =========================================================================
	# ACT 4 (175m -> 236m): Sweeping Pistons, Resonant Bell Drawbridge & Duck-Under Forge Rail!
	# =========================================================================
	var cp1 := start_pos + Vector3(5.5, 2.0, -5.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cp1, Vector3(3.4, 0.5, 5.6), Vector3(1.5, 1.2, 1.3), Vector3(0.0, -45.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w2_cp1", 1, cp1, -45.0, true, false, audit)
	WorldHelper.add_lamp_post(self, cp1 + Vector3(-1.8, 0.0, 1.8), -45.0, Color(1.0, 0.70, 0.28), 3.8, 13.0)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp1 + Vector3(1.6, 0.0, -1.6), 45.0, STYLE, Color(1.0, 0.60, 0.20))

	WorldHelper.add_landmark(self, "res://assets/models/scenery/brass_astrolabe_sphere.glb", Vector3(-4.0, 212.0, -34.0), Vector3(1.45, 1.45, 1.45), Vector3(12.0, 25.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, "res://assets/models/scenery/brass_astrolabe_sphere.glb", Vector3(12.0, 305.0, -30.0), Vector3(1.65, 1.65, 1.65), Vector3(-16.0, 80.0, 0.0), STYLE)
	WorldHelper.add_warm_light_pool(self, Vector3(19.0, 192.0, -18.5), Color(1.0, 0.64, 0.20), 4.2, 22.0, true, 2.6)
	WorldHelper.add_warm_light_pool(self, Vector3(2.5, 203.0, -26.0), Color(0.35, 0.88, 1.0), 3.4, 18.0, true, 2.2)

	var bg_gear1 := WorldHelper.add_spinning_gear(self, Vector3(0.0, 215.0, -44.0), 9.0, 3.2, [])
	bg_gear1.rotation_degrees.x = 90.0
	var bg_gear2 := WorldHelper.add_spinning_gear(self, Vector3(-44.0, 285.0, 10.0), -7.0, 3.4, [])
	bg_gear2.rotation_degrees.z = 90.0
	var bg_gear3 := WorldHelper.add_spinning_gear(self, Vector3(42.0, 255.0, -28.0), 11.0, 2.6, [])
	bg_gear3.rotation_degrees = Vector3(72.0, 35.0, 0.0)
	for i in range(8):
		var ca := i * 45.0 + 15.0
		var cp := WorldHelper.spiral_pt(ca, 38.0, 196.0 + i * 20.0)
		WorldHelper.add_landmark(self, "res://assets/models/scenery/hanging_chain_bell.glb", cp, Vector3(1.4, 1.4, 1.4), Vector3(0.0, ca, 0.0), STYLE)

	WorldHelper.add_catenary_lanterns(self, Vector3(11.0, 205.5, -21.5), Vector3(7.0, 207.5, -14.5), 5, 0.95, Color(1.0, 0.66, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(-7.5, 209.5, -23.0), Vector3(-5.0, 211.5, -15.5), 5, 0.95, Color(1.0, 0.66, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(-13.5, 243.5, 20.0), Vector3(-9.5, 246.0, 13.5), 5, 1.0, Color(1.0, 0.66, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(-19.0, 299.5, -15.5), Vector3(-12.5, 302.0, -10.5), 5, 1.0, Color(1.0, 0.66, 0.30))

	# Gears + Sweeping Slide-Under Piston Beam + Active Pendulum!
	WorldHelper.add_spinning_gear(self, Vector3(24.5, 178.0, 9.5), 28.0, 1.05, audit)
	WorldHelper.add_slide_obstacle(self, Vector3(24.5, 178.0, 9.5), 10.0, 4.4, Color(1.0, 0.56, 0.18), 1.8, 2.0)
	WorldHelper.add_spinning_gear(self, Vector3(27.0, 181.5, -0.5), -34.0, 1.05, audit)
	WorldHelper.add_pendulum(self, Vector3(26.0, 190.5, -5.5), 80.0, 32.0, 1.75, 0.0)
	WorldHelper.add_spinning_gear(self, Vector3(24.5, 185.0, -10.5), 36.0, 1.0, audit)

	# Meteor-Slam Forge Bellows launches straight to the Musical Bell Catwalk!
	WorldHelper.add_meteor_trigger(self, Vector3(19.0, 188.0, -18.5), "bellows", 27.5, Vector3(-3.0, 0.0, -3.5), "", audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(19.0, 189.2, -18.5), Vector3(12.5, 198.8, -24.5), 4.4, 4)

	# RESONANT BRONZE BELL #1 -> Shockwave materializes the Golden Brass Drawbridge!
	var cw1 := Vector3(12.5, 198.0, -24.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cw1, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, 62.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cw1 + Vector3(1.1, 0.0, -1.6), 62.0, STYLE, Color(1.0, 0.62, 0.20))
	WorldHelper.add_world_hint(self, Vector3(8.5, 200.6, -26.2), "RESONANT BRONZE BELL", "Wall-Kick the bell to send a shockwave that awakens the Golden Bridge!")
	WorldHelper.add_wall_run(self, BELL, Vector3(2.5, 201.0, -29.2), Vector3(0.0, 8.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 0, audit, "w2_bridge_1", 8.5)
	WorldHelper.add_resonant_target(self, Vector3(-3.2, 201.8, -27.2), 78.0, "bridge", "w2_bridge_1", Vector3(3.6, 0.42, 8.8), 24.0, Vector3.ZERO, PackedStringArray(), false, audit)
	var cw2 := Vector3(-10.5, 202.0, -25.2)
	WorldHelper.add_static_box_platform(self, CATWALK, cw2, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, 105.0, 0.0), STYLE, audit)
	WorldHelper.add_lamp_post(self, cw2 + Vector3(-1.1, 0.0, -1.5), 115.0, Color(1.0, 0.70, 0.28), 3.6, 11.0)

	# SUN-SHARD TRIAL #2: Bronze Sky-Ring Sprint (awards w2_s1!)
	WorldHelper.add_dash_prism(self, Vector3(-4.0, 206.5, -31.5), Color(1.0, 0.80, 0.28), 10.4, [])
	WorldHelper.add_shard_trial(self, cw2 + Vector3(0.8, 0.0, -1.6), "w2_s1", "CARILLON RING TRIAL", PackedVector3Array([
		Vector3(-6.5, 205.5, -29.5),
		Vector3(-1.5, 207.5, -31.5),
		Vector3(4.5, 206.5, -30.5),
		Vector3(9.5, 202.5, -26.5),
	]), 12.0)

	# PRO SHORTCUT #2: Swinging Foundry Sky-Beam + Flow-Express
	WorldHelper.add_swinging_bridge(self, Vector3(-18.5, 204.2, -16.5), -42.0, 11.2, 1.45, 2.0, "THE FOUNDRY SKY-BEAM", "Hold Your Nerve!")
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-24.5, 207.0, -7.5), 25.8, 2.3, Vector3(2.2, 0.0, 8.2), STYLE, [])
	WorldHelper.add_tether_orb(self, Vector3(-21.0, 223.5, 8.5), [])
	WorldHelper.add_shortcut_beacon(self, Vector3(-15.5, 236.0, 22.5), 130.0, "FOUNDRY SKY-BEAM!", "BELL-FORGE PRO SKIP")

	# BRASS FORGE PIPE GRIND RAIL #1 WITH MID-RAIL DUCK-UNDER BEAM!
	WorldHelper.add_world_hint(self, Vector3(-17.5, 206.5, -19.5), "FORGE PIPE GRIND · DUCK!", "Grind the Brass Pipe — hold {slide} to DUCK under the forge girder!")
	WorldHelper.add_grind_rail(self, PackedVector3Array([
		Vector3(-17.0, 204.5, -20.0),
		Vector3(-25.5, 212.5, -9.5),
		Vector3(-27.5, 221.0, 4.5),
		Vector3(-21.0, 230.5, 16.5),
	]), Color(1.0, 0.72, 0.24), 22.5, 11.8, audit)
	# Low girder right across the middle of the grind rail -> duck with Slide while grinding!
	WorldHelper.add_slide_obstacle(self, Vector3(-27.5, 221.0, 4.5), 172.0, 4.4, Color(1.0, 0.44, 0.16))
	WorldHelper.add_solar_mote_arc(self, Vector3(-17.0, 205.8, -20.0), Vector3(-27.5, 222.0, 4.5), 2.4, 5)

	# Checkpoint 2: Clockmaker's Overlook (Y = 236m)
	var cp2 := Vector3(-15.5, 236.0, 22.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cp2, Vector3(3.4, 0.5, 5.6), Vector3(1.5, 1.2, 1.3), Vector3(0.0, 130.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w2_cp2", 1, cp2, 130.0, false, false, audit)
	WorldHelper.add_lamp_post(self, cp2 + Vector3(-1.6, 0.0, 1.6), 45.0, Color(1.0, 0.70, 0.28), 3.8, 12.0)

	# =========================================================================
	# ACT 5 (236m -> 292m): Active Pendulum + Slide Gauntlet, Bell-Cannon & Cross-Spire Pipe!
	# =========================================================================
	WorldHelper.add_static_box_platform(self, CATWALK, Vector3(-6.5, 239.0, 26.5), Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, -105.0, 0.0), STYLE, audit)
	WorldHelper.add_pendulum(self, Vector3(0.0, 248.2, 27.5), 0.0, 32.0, 1.65, 0.0)
	var cw4 := Vector3(3.5, 242.0, 27.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cw4, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, -90.0, 0.0), STYLE, audit)
	WorldHelper.add_slide_obstacle(self, cw4, -90.0, 3.8, Color(1.0, 0.52, 0.18), 1.4, 2.2)
	WorldHelper.add_pendulum(self, Vector3(10.0, 251.2, 26.5), 18.0, 34.0, 1.75, 1.8)
	WorldHelper.add_static_box_platform(self, CATWALK, Vector3(13.5, 245.0, 24.5), Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, -68.0, 0.0), STYLE, audit)

	# Twin Musical Bells that power the Resonant Forge Cannon at (25.5, 255.0, -4.5)!
	WorldHelper.add_wall_run(self, BELL, Vector3(23.5, 247.5, 16.5), Vector3(0.0, -52.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 1, audit, "w2_cannon_1", 9.0)
	WorldHelper.add_wall_run(self, BELL, Vector3(22.5, 251.5, 6.0), Vector3(0.0, -88.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 3, audit, "w2_cannon_1", 9.0)
	WorldHelper.add_sun_shard(self, "w2_s2", Vector3(24.5, 254.0, 11.5))
	WorldHelper.add_resonant_target(self, Vector3(25.5, 255.0, -4.5), 0.0, "cannon", "w2_cannon_1", Vector3(4.0, 0.5, 4.0), 27.5, Vector3(-4.2, 0.0, -7.8), PackedStringArray(), false, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(25.5, 256.5, -4.5), Vector3(19.5, 269.5, -17.5), 4.8, 4)

	var launch_deck := Vector3(19.5, 268.5, -17.5)
	WorldHelper.add_static_box_platform(self, CATWALK, launch_deck, Vector3(3.4, 0.5, 5.4), Vector3(1.15, 1.0, 1.15), Vector3(0.0, 45.0, 0.0), STYLE, audit)

	# SPATIAL ARCHETYPE SHIFT: Cross-Spire Forge Pipe cutting straight past the glowing Furnace Core!
	WorldHelper.add_grind_rail(self, PackedVector3Array([
		Vector3(14.5, 270.8, -19.5),
		Vector3(4.0, 277.0, -21.0),
		Vector3(-7.0, 283.5, -20.5),
		Vector3(-16.5, 289.0, -18.5),
	]), Color(1.0, 0.66, 0.22), 23.0, 10.6, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(14.5, 272.0, -19.5), Vector3(-16.5, 290.5, -18.5), 3.0, 5)

	# Checkpoint 3: Belfry Spire (Y = 292m)
	var cp3 := Vector3(-21.5, 292.0, -17.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cp3, Vector3(3.4, 0.5, 5.6), Vector3(1.5, 1.2, 1.3), Vector3(0.0, 35.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w2_cp3", 1, cp3, 210.0, false, false, audit)
	WorldHelper.add_lamp_post(self, cp3 + Vector3(-1.6, 0.0, -1.4), 25.0, Color(1.0, 0.70, 0.28), 3.6, 12.0)

	# Exposed Void Overlook #1
	WorldHelper.add_static_box_platform(self, CATWALK, cp3 + Vector3(-5.8, 0.15, -4.7), Vector3(3.2, 0.5, 5.4), Vector3(0.36, 0.85, 2.15), Vector3(0.0, 50.9, 0.0), STYLE, [])
	WorldHelper.add_solar_mote_arc(self, cp3 + Vector3(-2.8, 1.0, -2.3), cp3 + Vector3(-9.8, 1.2, -8.0), 1.4, 3)
	WorldHelper.add_world_hint(self, cp3 + Vector3(-10.2, 2.1, -8.3), "CHRONICLE II — THE SILENT FOUNDRY", "When the Sun-Heart cracked, the bell-smiths fled. Look down — the valley darkens.")

	# =========================================================================
	# ACT 6 (292m -> 353m): WORLD 2 CLIMAX — METEOR BELLOWS + 2-BELL GREAT CARILLON ARENA!
	# =========================================================================
	WorldHelper.add_meteor_trigger(self, Vector3(-25.5, 294.5, -8.5), "bellows", 28.0, Vector3(-0.5, 0.0, 8.2), "", audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-25.5, 296.0, -8.5), Vector3(-24.5, 309.5, 5.5), 4.6, 4)

	var mid_cat := Vector3(-24.5, 308.5, 5.5)
	WorldHelper.add_static_box_platform(self, CATWALK, mid_cat, Vector3(3.4, 0.5, 5.4), Vector3.ONE, Vector3(0.0, -15.0, 0.0), STYLE, audit)

	# Aerial Dash-Prism Chain swinging into the Great Carillon Arena!
	WorldHelper.add_dash_prism(self, Vector3(-19.5, 314.0, 15.0), Color(1.0, 0.80, 0.28), 10.6, audit)
	WorldHelper.add_dash_prism(self, Vector3(-11.0, 319.5, 22.5), Color(0.45, 0.96, 1.0), 10.8, audit)

	# CLIMAX MINI-ARENA PUZZLE: Ring BOTH Carillon Bells in one unbroken Flow chain to fire the Great Foundry Lift!
	var arena := Vector3(-1.0, 323.0, 26.5)
	WorldHelper.add_static_box_platform(self, CATWALK, arena, Vector3(5.4, 0.6, 6.2), Vector3(1.5, 1.1, 1.3), Vector3(0.0, -85.0, 0.0), STYLE, audit)
	WorldHelper.add_world_hint(self, arena + Vector3(0.5, 2.6, 0.0), "CLIMAX · THE GREAT CARILLON!", "Wall-Kick BOTH Bronze Bells ahead to awaken the Great Foundry Cannon!")

	WorldHelper.add_wall_run(self, BELL, Vector3(7.5, 326.5, 29.5), Vector3(0.0, -25.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 4, audit, "w2_clim_a", 12.0)
	WorldHelper.add_dash_prism(self, Vector3(13.5, 329.0, 24.5), Color(1.0, 0.82, 0.30), 9.6, audit)
	WorldHelper.add_sun_shard(self, "w2_s3", Vector3(13.5, 333.5, 24.5))
	WorldHelper.add_wall_run(self, BELL, Vector3(19.5, 329.5, 19.5), Vector3(0.0, -52.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 5, audit, "w2_clim_b", 12.0)

	# The Carillon Lock Cannon! Awakens permanently once w2_clim_a + w2_clim_b are both rung!
	var carillon_cannon_pos := Vector3(23.0, 331.5, 10.0)
	WorldHelper.add_resonant_target(
		self, carillon_cannon_pos, 0.0, "carillon_lock", "", Vector3(4.2, 0.6, 4.2),
		29.5, Vector3(1.8, 0.0, -9.2), PackedStringArray(["w2_clim_a", "w2_clim_b"]), true, audit
	)
	WorldHelper.add_solar_mote_arc(self, carillon_cannon_pos + Vector3(0.0, 2.0, 0.0), Vector3(25.0, 353.5, -4.5), 5.6, 5)

	# World 2 -> World 3 Monsoon Ascension Gate (Y = 352.5m)
	var gate_pos := Vector3(25.0, 352.5, -4.5)
	WorldHelper.add_static_box_platform(self, CATWALK, gate_pos, Vector3(3.6, 0.6, 5.8), Vector3(1.6, 1.3, 1.4), Vector3.ZERO, STYLE, audit, "world_gate_pad")
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(-1.5, 0.0, -3.5), Vector3.ONE, Vector3(0.0, 15.0, 0.0), STYLE)
	WorldHelper.add_lamp_post(self, gate_pos + Vector3(1.6, 0.0, 1.8), -90.0, Color(1.0, 0.70, 0.28), 3.6, 12.0)
	return gate_pos
