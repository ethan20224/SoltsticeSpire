extends Node3D
class_name World2Foundry
## World 2: Foundry of Floating Bells (175m -> 355m)
## Radiant golden-hour riveted Foundry Stack Core, furnace light pools, brass gears,
## colossal musical bronze wall-run bells, cathedral pendulums, and pressurized steam-vent launches.

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
	# =========================================================================
	# CENTRAL SOLSTICE SPIRE CORE (World 2: Riveted Copper & Iron Foundry Stack!)
	# =========================================================================
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 175.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	# Glowing amber furnace mouth OmniLight pools & bokeh halos on every foundry level!
	for lvl in range(5):
		var ly := 175.0 + 29.0 + lvl * 34.0
		for f in range(4):
			var fa := f * 90.0 + rad_to_deg(lvl * 0.4)
			var fp := WorldHelper.spiral_pt(fa, 18.2, ly)
			WorldHelper.add_warm_light_pool(self, fp, Color(1.0, 0.56, 0.16), 4.2, 22.0, true, 2.6, (f % 2 == 0))

	# 2 Biome-Specific Golden-Amber Distant Parallax Silhouette Rings (160-390m out!)
	WorldHelper.add_parallax_ring(self, 1, 245.0, 160.0, 250.0, 14, false, 2011)
	WorldHelper.add_parallax_ring(self, 1, 310.0, 260.0, 390.0, 16, true, 2012)

	# =========================================================================
	# ACT 4 (175m -> 235m): Interlocking Clockwork Gears & First Musical Bell Run
	# =========================================================================
	var cp1 := start_pos + Vector3(5.5, 2.0, -5.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cp1, Vector3(3.4, 0.5, 5.6), Vector3(1.5, 1.2, 1.3), Vector3(0.0, -45.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w2_cp1", 1, cp1, -45.0, true, false, audit)
	WorldHelper.add_lamp_post(self, cp1 + Vector3(-1.8, 0.0, 1.8), -45.0, Color(1.0, 0.70, 0.28), 3.8, 13.0)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp1 + Vector3(1.6, 0.0, -1.6), 45.0, STYLE, Color(1.0, 0.60, 0.20))

	# Monumental Celestial Brass Astrolabe Spheres + Giant Background Gears + Forged Bell Chains
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

	# High overhead catenary forge lantern strings linking the Foundry Stack Core to upper struts (>= 5m above decks!)
	WorldHelper.add_catenary_lanterns(self, Vector3(11.0, 205.5, -21.5), Vector3(7.0, 207.5, -14.5), 5, 0.95, Color(1.0, 0.66, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(-7.5, 209.5, -23.0), Vector3(-5.0, 211.5, -15.5), 5, 0.95, Color(1.0, 0.66, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(-13.5, 243.5, 20.0), Vector3(-9.5, 246.0, 13.5), 5, 1.0, Color(1.0, 0.66, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(-19.0, 299.5, -15.5), Vector3(-12.5, 302.0, -10.5), 5, 1.0, Color(1.0, 0.66, 0.30))

	# Trio of counter-rotating giant brass gears rising cleanly in steps
	WorldHelper.add_spinning_gear(self, Vector3(24.5, 178.0, 9.5), 24.0, 1.05, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(24.5, 178.8, 9.5), Vector3(27.0, 182.3, -0.5), 2.2, 3)
	WorldHelper.add_spinning_gear(self, Vector3(27.0, 181.5, -0.5), -30.0, 1.05, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(27.0, 182.3, -0.5), Vector3(24.5, 185.8, -10.5), 2.2, 3)
	WorldHelper.add_spinning_gear(self, Vector3(24.5, 185.0, -10.5), 34.0, 1.0, audit)

	WorldHelper.add_bounce_pad(self, VENT, Vector3(19.0, 188.0, -18.5), 23.0, 2.3, Vector3(-2.5, 0.0, -2.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(19.0, 189.0, -18.5), Vector3(12.5, 198.8, -24.5), 4.0, 4)

	# First Iconic Musical Bronze Bell Wall-Run
	var cw1 := Vector3(12.5, 198.0, -24.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cw1, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, 62.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cw1 + Vector3(1.1, 0.0, -1.6), 62.0, STYLE, Color(1.0, 0.62, 0.20))
	WorldHelper.add_world_hint(self, Vector3(8.5, 200.4, -26.2), "MUSICAL BELL WALL-RUN", "Jump along Bronze Bells to Wall-Run & {jump} Wall-Kick!")
	WorldHelper.add_wall_run(self, BELL, Vector3(2.5, 201.0, -29.2), Vector3(0.0, 8.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 0, audit)
	WorldHelper.add_solar_mote_arc(self, cw1 + Vector3(-2.0, 1.0, -1.5), Vector3(-8.5, 202.8, -26.0), 2.4, 4)
	var cw2 := Vector3(-8.5, 202.0, -26.0)
	WorldHelper.add_static_box_platform(self, CATWALK, cw2, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, 105.0, 0.0), STYLE, audit)
	WorldHelper.add_lamp_post(self, cw2 + Vector3(-1.1, 0.0, -1.5), 115.0, Color(1.0, 0.70, 0.28), 3.6, 11.0)

	# SET-PIECE / PRO SHORTCUT #2: "The Foundry Swinging Sky-Beam" (Precarious swinging brass girder + high-pressure vent skip!)
	WorldHelper.add_swinging_bridge(self, Vector3(-18.5, 204.2, -16.5), -42.0, 11.2, 1.45, 2.0, "THE FOUNDRY SKY-BEAM", "Hold Your Nerve!")
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-24.5, 207.0, -7.5), 25.8, 2.3, Vector3(2.2, 0.0, 8.2), STYLE, [])
	WorldHelper.add_solar_mote_arc(self, Vector3(-24.5, 208.0, -7.5), Vector3(-21.0, 223.5, 8.5), 4.0, 4)
	WorldHelper.add_tether_orb(self, Vector3(-21.0, 223.5, 8.5), [])
	WorldHelper.add_solar_mote_arc(self, Vector3(-21.0, 223.5, 8.5), Vector3(-15.5, 236.8, 22.5), 3.2, 4)
	WorldHelper.add_shortcut_beacon(self, Vector3(-15.5, 236.0, 22.5), 130.0, "FOUNDRY SKY-BEAM!", "BELL-FORGE PRO SKIP")

	WorldHelper.add_sun_shard(self, "w2_s1", Vector3(2.5, 205.5, -27.5))

	WorldHelper.add_spinning_gear(self, Vector3(-17.5, 205.5, -21.0), -28.0, 1.05, audit)
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-24.0, 209.0, -13.0), 23.5, 2.3, Vector3(-1.5, 0.0, 3.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-24.0, 210.0, -13.0), Vector3(-26.5, 220.2, -4.0), 4.0, 4)
	var cw3 := Vector3(-26.5, 219.5, -4.0)
	WorldHelper.add_static_box_platform(self, CATWALK, cw3, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, 175.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cw3 + Vector3(-1.1, 0.0, 1.5), -15.0, STYLE, Color(1.0, 0.62, 0.20))
	WorldHelper.add_spinning_gear(self, Vector3(-26.5, 223.0, 6.0), 32.0, 1.0, audit)
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-23.0, 226.5, 15.0), 22.5, 2.3, Vector3(2.5, 0.0, 2.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-23.0, 227.5, 15.0), Vector3(-15.5, 236.8, 22.5), 3.8, 4)

	# Checkpoint 2: Clockmaker's Overlook (Y = 236m)
	var cp2 := Vector3(-15.5, 236.0, 22.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cp2, Vector3(3.4, 0.5, 5.6), Vector3(1.5, 1.2, 1.3), Vector3(0.0, 130.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w2_cp2", 1, cp2, 130.0, false, false, audit)
	WorldHelper.add_lamp_post(self, cp2 + Vector3(-1.6, 0.0, 1.6), 45.0, Color(1.0, 0.70, 0.28), 3.8, 12.0)

	# =========================================================================
	# ACT 5 (236m -> 295m): Cathedral Pendulum Gauntlet & Twin Musical Bells
	# =========================================================================
	WorldHelper.add_static_box_platform(self, CATWALK, Vector3(-6.5, 239.0, 26.5), Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, -105.0, 0.0), STYLE, audit)
	WorldHelper.add_pendulum(self, Vector3(0.0, 248.5, 27.5), 0.0, 30.0, 1.55, 0.0)
	var cw4 := Vector3(3.5, 242.0, 27.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cw4, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, -90.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cw4 + Vector3(0.0, 0.0, 1.3), 180.0, STYLE, Color(1.0, 0.62, 0.20))
	WorldHelper.add_pendulum(self, Vector3(10.0, 251.5, 26.5), 18.0, 32.0, 1.65, 1.8)
	WorldHelper.add_static_box_platform(self, CATWALK, Vector3(13.5, 245.0, 24.5), Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, -68.0, 0.0), STYLE, audit)

	WorldHelper.add_wall_run(self, BELL, Vector3(23.5, 247.5, 16.5), Vector3(0.0, -52.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 1, audit)
	WorldHelper.add_wall_run(self, BELL, Vector3(22.5, 251.5, 6.0), Vector3(0.0, -88.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 3, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(13.5, 246.0, 24.5), Vector3(23.5, 249.5, 16.5), 2.2, 3)
	WorldHelper.add_solar_mote_arc(self, Vector3(23.5, 249.5, 16.5), Vector3(25.5, 255.8, -4.5), 2.4, 4)
	WorldHelper.add_spinning_gear(self, Vector3(25.5, 255.0, -4.5), -34.0, 1.1, audit)
	WorldHelper.add_sun_shard(self, "w2_s2", Vector3(24.5, 254.0, 11.5))

	WorldHelper.add_bounce_pad(self, VENT, Vector3(22.0, 258.5, -14.0), 24.5, 2.3, Vector3(-2.5, 0.0, -2.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(22.0, 259.5, -14.0), Vector3(14.5, 270.8, -21.5), 4.2, 4)
	WorldHelper.add_spinning_gear(self, Vector3(14.5, 270.0, -21.5), 30.0, 1.05, audit)
	WorldHelper.add_spinning_gear(self, Vector3(5.0, 274.0, -25.5), -36.0, 1.0, audit)
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-4.5, 277.5, -26.5), 24.0, 2.3, Vector3(-3.0, 0.0, 1.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-4.5, 278.5, -26.5), Vector3(-13.5, 289.2, -23.5), 4.0, 4)
	var cw5 := Vector3(-13.5, 288.5, -23.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cw5, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, 58.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cw5 + Vector3(-1.2, 0.0, -1.2), 45.0, STYLE, Color(1.0, 0.62, 0.20))

	# Checkpoint 3: Belfry Spire (Y = 293m)
	var cp3 := Vector3(-21.5, 292.0, -17.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cp3, Vector3(3.4, 0.5, 5.6), Vector3(1.5, 1.2, 1.3), Vector3(0.0, 35.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w2_cp3", 1, cp3, 210.0, false, false, audit)
	WorldHelper.add_lamp_post(self, cp3 + Vector3(-1.6, 0.0, -1.4), 25.0, Color(1.0, 0.70, 0.28), 3.6, 12.0)

	# EXPOSED OVER-THE-VOID OVERLOOK #1: Narrow Brass Foundry Beam jutting 11.6m over 292m of sheer sky!
	WorldHelper.add_static_box_platform(self, CATWALK, cp3 + Vector3(-5.8, 0.15, -4.7), Vector3(3.2, 0.5, 5.4), Vector3(0.36, 0.85, 2.15), Vector3(0.0, 50.9, 0.0), STYLE, [])
	WorldHelper.add_solar_mote_arc(self, cp3 + Vector3(-2.8, 1.0, -2.3), cp3 + Vector3(-9.8, 1.2, -8.0), 1.4, 3)
	WorldHelper.add_world_hint(self, cp3 + Vector3(-10.2, 2.1, -8.3), "CHRONICLE II — THE SILENT FOUNDRY", "When the Sun-Heart cracked, the bell-smiths fled. Look down — the valley darkens.")

	# =========================================================================
	# ACT 6 (293m -> 355m): The Great Carillon Finale Sprint
	# =========================================================================
	WorldHelper.add_wall_run(self, BELL, Vector3(-28.5, 295.0, -8.5), Vector3(0.0, 82.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 2, audit)
	WorldHelper.add_solar_mote_arc(self, cp3 + Vector3(-2.0, 1.0, 2.0), Vector3(-26.5, 300.2, 1.5), 2.6, 4)
	WorldHelper.add_spinning_gear(self, Vector3(-26.5, 299.5, 1.5), 38.0, 1.05, audit)
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-23.0, 303.0, 11.0), 24.5, 2.3, Vector3(2.0, 0.0, 2.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-23.0, 304.0, 11.0), Vector3(-17.0, 315.2, 18.5), 4.2, 4)
	var cw6 := Vector3(-17.0, 314.5, 18.5)
	WorldHelper.add_static_box_platform(self, CATWALK, cw6, Vector3(3.2, 0.5, 5.4), Vector3.ONE, Vector3(0.0, -45.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cw6 + Vector3(-1.2, 0.0, 1.2), -45.0, STYLE, Color(1.0, 0.62, 0.20))

	WorldHelper.add_wall_run(self, BELL, Vector3(-8.5, 317.4, 25.5), Vector3(0.0, -20.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 4, audit)
	WorldHelper.add_solar_mote_arc(self, cw6 + Vector3(2.0, 1.0, 2.0), Vector3(1.5, 323.2, 25.5), 2.6, 4)
	WorldHelper.add_spinning_gear(self, Vector3(1.5, 322.5, 25.5), -38.0, 1.1, audit)
	WorldHelper.add_sun_shard(self, "w2_s3", Vector3(1.5, 328.5, 25.5))
	WorldHelper.add_bounce_pad(self, VENT, Vector3(11.0, 326.0, 23.0), 26.2, 2.4, Vector3(4.5, 0.0, -3.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(11.0, 327.0, 23.0), Vector3(21.0, 338.8, 15.5), 4.5, 4)
	WorldHelper.add_wall_run(self, BELL, Vector3(21.0, 337.2, 15.5), Vector3(0.0, -55.0, 0.0), Vector3(8.8, 4.4, 1.0), true, 5, audit)
	WorldHelper.add_bounce_pad(self, VENT, Vector3(25.5, 342.5, 6.0), 22.0, 2.3, Vector3(0.0, 0.0, -3.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(25.5, 343.5, 6.0), Vector3(25.0, 353.2, -4.5), 4.0, 4)

	# World 2 -> World 3 Monsoon Ascension Gate (Y = 353m)
	var gate_pos := Vector3(25.0, 352.5, -4.5)
	WorldHelper.add_static_box_platform(self, CATWALK, gate_pos, Vector3(3.6, 0.6, 5.8), Vector3(1.6, 1.3, 1.4), Vector3(0.0, 0.0, 0.0), STYLE, audit, "world_gate_pad")
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(-1.5, 0.0, -3.5), Vector3.ONE, Vector3(0.0, 15.0, 0.0), STYLE)
	WorldHelper.add_lamp_post(self, gate_pos + Vector3(1.6, 0.0, 1.8), -90.0, Color(1.0, 0.70, 0.28), 3.6, 12.0)
	return gate_pos
