extends Node3D
class_name World1Conservatory
## World 1: The Sunken Conservatory (0m -> 175m)
## Signature Twist: Living Physics (Tilting See-Saws), Meteor-Slam Sun-Buds, Vine Grind Rails,
## Downhill Moss Momentum Chute, Interior Glasshouse Wall-Kick Chimney, & Triple-Bud Climax Slingshot!

const PLINTH := "res://assets/models/world1_conservatory/terracotta_plinth.glb"
const ARCH := "res://assets/models/world1_conservatory/aqueduct_arch.glb"
const LILY := "res://assets/models/world1_conservatory/lily_pad_cap.glb"
const DOME := "res://assets/models/world1_conservatory/glass_dome_rib.glb"
const FLAG := "res://assets/models/world1_conservatory/mossy_flagstone.glb"
const GATE := "res://assets/models/common/world_gate.glb"
const TREE := "res://assets/models/scenery/garden_tree.glb"
const FERN := "res://assets/models/scenery/potted_fern.glb"
const ISLET := "res://assets/models/scenery/floating_spire_rock.glb"
const CORE := "res://assets/models/tower_cores/w1_conservatory_core.glb"
const CLUSTER := "res://assets/models/dressing/w1_garden_cluster.glb"
const BELL := "res://assets/models/world2_foundry/curved_bell.glb"
const MIRROR := "res://assets/models/world4_mirrors/mirror_wall_panel.glb"

const STYLE := {
	"top": Color(0.18, 0.48, 0.20),
	"top_blend": 0.34,
	"rim": Color(1.0, 0.90, 0.62),
	"rim_s": 0.26,
	"shadow": Color(0.16, 0.24, 0.44),
	"tex": "stone_mosaic",
	"tex_scale": 0.30,
	"tex_blend": 0.74,
}

const TERRACE_STYLE := {
	"top": Color(0.18, 0.48, 0.20),
	"top_blend": 0.22,
	"rim": Color(1.0, 0.92, 0.68),
	"rim_s": 0.24,
	"shadow": Color(0.16, 0.24, 0.44),
	"tex": "terrazzo_inlay",
	"tex_scale": 0.34,
	"tex_blend": 0.68,
}


func build(audit: Array) -> Vector3:
	# =========================================================================
	# CENTRAL SOLSTICE SPIRE CORE (World 1: Victorian Glasshouse Rotunda Tower!)
	# =========================================================================
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 0.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	for tier in range(5):
		var ty := 44.5 + tier * 30.0
		for w in range(4):
			var wa := w * 90.0 + tier * 22.0 + 22.5
			var wp := WorldHelper.spiral_pt(wa, 16.0, ty)
			WorldHelper.add_warm_light_pool(self, wp, Color(1.0, 0.72, 0.34), 3.6, 20.0, true, 2.4, (w % 2 == 0))

	WorldHelper.add_parallax_ring(self, 0, 45.0, 155.0, 240.0, 14, false, 1011)
	WorldHelper.add_parallax_ring(self, 0, 115.0, 250.0, 380.0, 16, true, 1012)

	# =========================================================================
	# ACT 1 (0m -> 54m): Awakening Terrace, Slide-Arch, Living See-Saw, Meteor Bud & Vine Rail!
	# =========================================================================
	var p_start := Vector3(0.0, 0.0, 26.0)
	WorldHelper.add_static_cyl_platform(self, PLINTH, p_start, 2.6, 1.0, Vector3(2.5, 1.3, 2.5), Vector3.ZERO, TERRACE_STYLE, audit, "start")
	WorldHelper.add_lush_grass_carpet(self, p_start, 5.75, 240, 1011, 0.0)
	WorldHelper.add_grass_tuft_rim(self, p_start, 4.4, 5.9, 64, 1001)
	WorldHelper.add_wildflower_scatter(self, p_start, 2.2, 5.6, 24, 1021)
	WorldHelper.add_mossy_stones(self, p_start, 5.6, 5, 1031, true)
	WorldHelper.add_shrine(self, "w1_cp1", 0, p_start + Vector3(-5.0, 0.0, -3.5), 0.0, true, false, audit, Vector3(5.0, 0.8, 3.1))

	WorldHelper.add_docked_airship(self, p_start + Vector3(-10.2, 0.08, 2.0), -18.0)
	WorldHelper.add_world_hint(self, p_start + Vector3(-7.8, 2.35, 1.6), "THE DAWNBREAKER — DOCKED", "The Sun-Heart at 1,085m is dying. Walk the gangplank & ascend.")
	WorldHelper.add_landmark(self, TREE, p_start + Vector3(4.2, 0.0, -2.5), Vector3(1.12, 1.12, 1.12), Vector3(0.0, -28.0, 0.0), STYLE, 190.0)
	WorldHelper.add_landmark(self, TREE, p_start + Vector3(-4.2, 0.0, 4.4), Vector3(0.95, 0.95, 0.95), Vector3(0.0, 42.0, 0.0), STYLE, 190.0)
	WorldHelper.add_landmark(self, FERN, p_start + Vector3(3.1, 0.0, -3.9), Vector3(0.95, 0.95, 0.95), Vector3(0.0, 18.0, 0.0), STYLE, 140.0, true)
	WorldHelper.add_landmark(self, FERN, p_start + Vector3(-2.6, 0.0, -4.1), Vector3(0.85, 0.85, 0.85), Vector3(0.0, -42.0, 0.0), STYLE, 140.0, true)
	WorldHelper.add_landmark(self, FERN, p_start + Vector3(4.6, 0.0, 1.4), Vector3(1.05, 1.05, 1.05), Vector3(0.0, 85.0, 0.0), STYLE, 140.0, true)
	WorldHelper.add_lamp_post(self, p_start + Vector3(-3.3, 0.0, -0.4), 18.0, Color(1.0, 0.72, 0.34), 3.8, 10.5)
	WorldHelper.add_lamp_post(self, p_start + Vector3(3.4, 0.0, -0.8), 165.0, Color(1.0, 0.72, 0.34), 3.8, 10.5)
	WorldHelper.add_catenary_lanterns(self, Vector3(4.5, 9.2, 16.5), Vector3(11.5, 11.8, 6.5), 5, 0.95, Color(1.0, 0.66, 0.32))

	WorldHelper.add_landmark(self, DOME, Vector3(0.0, -2.0, 14.0), Vector3(1.45, 1.45, 1.45), Vector3(0.0, 0.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, DOME, Vector3(13.0, 4.0, 2.0), Vector3(1.35, 1.35, 1.35), Vector3(0.0, -48.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, DOME, Vector3(-16.0, 28.0, -10.0), Vector3(1.6, 1.6, 1.6), Vector3(0.0, 52.0, 6.0), STYLE)
	WorldHelper.add_landmark(self, DOME, Vector3(22.0, 92.0, -12.0), Vector3(1.7, 1.7, 1.7), Vector3(0.0, -38.0, -6.0), STYLE)

	var scenic_islets := [
		Vector3(-22.0, 5.0, 16.0), Vector3(26.0, 13.0, 14.0), Vector3(-32.0, 40.0, -20.0),
		Vector3(34.0, 66.0, -16.0), Vector3(-36.0, 118.0, 14.0), Vector3(32.0, 148.0, 20.0),
	]
	for idx in range(scenic_islets.size()):
		var ip: Vector3 = scenic_islets[idx]
		var sc := 1.15 + float(idx % 3) * 0.32
		WorldHelper.add_landmark(self, ISLET, ip, Vector3(sc, sc, sc), Vector3(0.0, idx * 55.0, 0.0), STYLE)
		WorldHelper.add_landmark(self, TREE, ip + Vector3(0.4, 0.0, -0.3), Vector3(sc * 0.85, sc * 0.85, sc * 0.85), Vector3(0.0, idx * 42.0, 0.0), STYLE, 200.0)
		WorldHelper.add_landmark(self, FERN, ip + Vector3(-1.2, 0.0, 0.8), Vector3(0.95, 0.95, 0.95), Vector3(0.0, idx * 80.0, 0.0), STYLE, 130.0, true)

	# Opening Aqueduct with Slide-Under Vine Arch -> teaches Slide & Slide-Long-Jump right away!
	WorldHelper.add_world_hint(self, Vector3(0.0, 2.4, 21.2), "SLIDE-UNDER ARCH", "Sprint & press {slide} to zip under low beams -> {jump} to Long-Jump!")
	var p := Vector3(0.0, 1.5, 16.5)
	WorldHelper.add_static_box_platform(self, ARCH, p, Vector3(3.6, 0.6, 6.8), Vector3(1.05, 1.0, 1.05), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_slide_obstacle(self, p + Vector3(0.0, 0.0, -0.4), 0.0, 3.8, Color(0.42, 0.94, 0.56))
	WorldHelper.add_solar_mote_arc(self, p + Vector3(0.0, 0.6, -2.5), Vector3(5.5, 4.6, 8.5), 2.4, 4)

	p = Vector3(5.5, 4.0, 8.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, p, 2.6, 0.8, Vector3(1.1, 1.0, 1.1), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_grass_tuft_rim(self, p, 2.0, 2.6, 22, 1002)

	# LIVING CONSERVATORY SEE-SAW #1 (tips smoothly under weight — keep moving!)
	WorldHelper.add_world_hint(self, Vector3(10.5, 7.6, 5.2), "LIVING SEE-SAW", "Tilts under your weight — sprint fast or jump off the rising lip!")
	WorldHelper.add_seesaw(self, Vector3(13.0, 6.5, 2.2), -42.0, 9.2, 3.3, Color(0.28, 0.72, 0.36), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(13.0, 7.4, 2.2), Vector3(19.5, 9.8, -3.5), 2.2, 4)

	# First Giant Botanical Meteor-Slam Sun-Bud + Standard Lily Pad option!
	WorldHelper.add_world_hint(self, Vector3(16.5, 10.6, -0.5), "METEOR-SLAM SUN-BUD", "Jump & hold {slide} mid-air to SLAM the bud open for a Super-Launch!")
	WorldHelper.add_meteor_trigger(self, Vector3(19.5, 9.2, -3.5), "bud", 27.5, Vector3(2.2, 0.0, -7.2), "", audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(19.5, 10.5, -3.5), Vector3(21.5, 18.6, -12.0), 4.6, 5)

	p = Vector3(21.5, 17.8, -12.0)
	WorldHelper.add_static_box_platform(self, ARCH, p, Vector3(3.4, 0.6, 6.6), Vector3.ONE, Vector3(0.0, -18.0, 0.0), STYLE, audit)

	# SUN-SHARD TRIAL #1: 10-Second Canopy Dash-Prism Sprint (awards w1_s1!)
	WorldHelper.add_dash_prism(self, Vector3(27.5, 21.5, -14.0), Color(0.45, 0.96, 1.0), 10.5, [])
	WorldHelper.add_dash_prism(self, Vector3(31.0, 24.5, -19.5), Color(1.0, 0.84, 0.34), 10.5, [])
	WorldHelper.add_shard_trial(self, p + Vector3(1.2, 0.0, -1.8), "w1_s1", "CANOPY PRISM TRIAL", PackedVector3Array([
		Vector3(25.0, 20.5, -13.0),
		Vector3(28.5, 22.8, -15.5),
		Vector3(31.0, 25.0, -19.5),
		Vector3(24.0, 24.5, -20.5),
	]), 12.0)

	# CURVED VINE GRIND RAIL #1 (high-speed 22 m/s canopy surf replacing 4 dull circular steps!)
	WorldHelper.add_world_hint(self, Vector3(18.5, 20.4, -17.5), "VINE GRIND RAIL", "Jump onto the glowing vine to surf at 22 m/s! Press {jump} to leap off!")
	WorldHelper.add_grind_rail(self, PackedVector3Array([
		Vector3(17.5, 19.6, -18.5),
		Vector3(10.0, 23.5, -24.5),
		Vector3(0.0, 27.5, -26.0),
		Vector3(-9.5, 31.5, -22.5),
	]), Color(0.40, 0.95, 0.48), 22.0, 11.8, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(17.5, 20.8, -18.5), Vector3(0.0, 28.8, -26.0), 2.5, 5)
	WorldHelper.add_solar_mote_arc(self, Vector3(0.0, 28.8, -26.0), Vector3(-9.5, 32.8, -22.5), 2.2, 4)

	# Living See-Saw #2 -> Dash-Prism "Floor Is Lava" Aerial Combo to CP2!
	WorldHelper.add_seesaw(self, Vector3(-15.5, 35.8, -17.5), 48.0, 9.0, 3.2, Color(0.32, 0.76, 0.42), audit)
	WorldHelper.add_world_hint(self, Vector3(-18.5, 39.0, -13.5), "DASH-BREAK PRISMS", "Air-Dash ({dash}) through crystals to shatter & RESET your Dash + Jump!")
	WorldHelper.add_dash_prism(self, Vector3(-20.5, 41.2, -11.5), Color(0.45, 0.96, 1.0), 10.6, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-20.5, 41.5, -11.5), Vector3(-24.0, 47.0, -6.5), 2.4, 3)
	WorldHelper.add_dash_prism(self, Vector3(-24.0, 46.8, -6.5), Color(1.0, 0.86, 0.34), 10.6, audit)

	# PRO SHORTCUT #1 + FLOW-EXPRESS OVERDRIVE BRIDGE
	WorldHelper.add_static_box_platform(self, ARCH, Vector3(-29.0, 49.0, -4.5), Vector3(3.4, 0.6, 6.6), Vector3(0.42, 1.0, 1.15), Vector3(0.0, -35.0, 0.0), STYLE, [])
	WorldHelper.add_flow_express(self, Vector3(-31.0, 52.0, 2.5), -20.0, Vector3(3.4, 0.36, 9.2))
	WorldHelper.add_bounce_pad(self, LILY, Vector3(-32.5, 52.5, 7.5), 26.0, 2.3, Vector3(5.5, 0.0, 7.5), STYLE, [])
	WorldHelper.add_tether_orb(self, Vector3(-22.0, 66.5, 16.5), [])
	WorldHelper.add_tether_orb(self, Vector3(-10.0, 74.5, 22.5), [])
	WorldHelper.add_shortcut_beacon(self, Vector3(1.5, 78.5, 24.5), -65.0, "SUN-ARCH SKY-SKIP!", "+28m FLOW SHORTCUT")

	# Checkpoint 2 Sanctuary Terrace (Y = 51m)
	var cp2 := Vector3(-26.0, 51.0, -1.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, cp2, 2.6, 1.0, Vector3(1.75, 1.2, 1.75), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w1_cp2", 0, cp2, 165.0, false, false, audit)
	WorldHelper.add_lush_grass_carpet(self, cp2, 4.1, 96, 1012, 1.2)
	WorldHelper.add_grass_tuft_rim(self, cp2, 3.2, 4.2, 36, 1004)
	WorldHelper.add_wildflower_scatter(self, cp2, 2.0, 4.0, 14, 1028)
	WorldHelper.add_mossy_stones(self, cp2, 4.1, 3, 1032)
	WorldHelper.add_lamp_post(self, cp2 + Vector3(-2.6, 0.0, -1.8), 45.0, Color(1.0, 0.72, 0.34), 3.6, 10.0)
	WorldHelper.add_catenary_lanterns(self, cp2 + Vector3(2.2, 6.5, 0.0), Vector3(-15.5, 58.5, -1.0), 5, 1.0, Color(1.0, 0.66, 0.32))

	# =========================================================================
	# ACT 2 (51m -> 109m): DOWNHILL MOMENTUM CHUTE + INTERIOR GLASSHOUSE CHIMNEY!
	# Breaks the R=26m spiral by diving DOWN to launch UP, then ducking INSIDE the spire core!
	# =========================================================================
	WorldHelper.add_world_hint(self, Vector3(-24.5, 53.5, 4.5), "MOMENTUM SLIDE CHUTE", "Dive DOWN the glossy chute to catapult +22m across the sky!")
	WorldHelper.add_momentum_ramp(self, Vector3(-24.2, 51.2, 5.2), 220.0, 13.0, 5.0, 21.5, 25.5, Color(0.45, 0.95, 0.56), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-16.5, 48.0, 17.5), Vector3(-7.0, 66.5, 25.5), 5.0, 5)

	var ud_deck := Vector3(-7.0, 65.5, 25.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, ud_deck, 2.6, 0.8, Vector3(1.3, 1.0, 1.3), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, ud_deck + Vector3(-1.6, 0.0, 1.4), 35.0, STYLE)

	# SPATIAL ARCHETYPE SHIFT: Interior Conservatory Wall-Kick Chimney (cuts inward to R = 17m -> 19m!)
	WorldHelper.add_world_hint(self, Vector3(1.0, 70.5, 20.5), "GLASSHOUSE CHIMNEY", "Bounce left-right off the interior glass walls & burst out the roof!")
	var chim_in := Vector3(1.5, 68.5, 21.0)
	WorldHelper.add_static_box_platform(self, ARCH, chim_in, Vector3(3.4, 0.6, 6.6), Vector3.ONE, Vector3(0.0, -52.0, 0.0), STYLE, audit)
	WorldHelper.add_wall_run(self, MIRROR, Vector3(10.0, 73.5, 19.5), Vector3(0.0, -45.0, 0.0), Vector3(8.8, 4.6, 0.9), false, 0, audit)
	WorldHelper.add_dash_prism(self, Vector3(13.5, 79.0, 14.5), Color(0.45, 0.96, 1.0), 10.8, audit)
	WorldHelper.add_wall_run(self, MIRROR, Vector3(18.5, 83.0, 12.0), Vector3(0.0, -72.0, 0.0), Vector3(8.8, 4.6, 0.9), false, 0, audit)
	WorldHelper.add_updraft(self, Vector3(20.5, 85.0, 5.5), 20.0, 3.2, Color(0.65, 1.0, 0.82), audit)
	WorldHelper.add_sun_shard(self, "w1_s2", Vector3(20.5, 98.5, 5.5))
	WorldHelper.add_solar_mote_arc(self, Vector3(20.5, 88.0, 5.5), Vector3(23.5, 103.5, -2.5), 3.6, 4)

	var chim_out := Vector3(23.5, 102.5, -2.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, chim_out, 2.6, 0.8, Vector3(1.2, 1.0, 1.2), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, chim_out + Vector3(1.7, 0.0, -0.5), -85.0, STYLE)

	# Living See-Saw #3 + Crumbling Flagstone Dash into CP3!
	WorldHelper.add_seesaw(self, Vector3(19.5, 105.0, -12.5), 32.0, 9.2, 3.3, Color(0.28, 0.72, 0.36), audit)
	WorldHelper.add_crumbling_tile(self, FLAG, Vector3(14.5, 107.2, -21.5), 0.72, false, Vector3(0.0, -45.0, 0.0), audit)

	# Checkpoint 3 Canopy Overlook (Y = 108.5m)
	var cp3 := Vector3(6.5, 108.5, -26.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, cp3, 2.6, 1.0, Vector3(1.75, 1.2, 1.75), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w1_cp3", 0, cp3, 75.0, false, false, audit)
	WorldHelper.add_lush_grass_carpet(self, cp3, 4.1, 96, 1013, 1.2)
	WorldHelper.add_grass_tuft_rim(self, cp3, 3.2, 4.2, 34, 1005)
	WorldHelper.add_wildflower_scatter(self, cp3, 2.0, 4.0, 14, 1029)
	WorldHelper.add_mossy_stones(self, cp3, 4.1, 3, 1033)
	WorldHelper.add_lamp_post(self, cp3 + Vector3(2.4, 0.0, -2.0), -135.0, Color(1.0, 0.72, 0.34), 3.6, 10.0)

	# =========================================================================
	# ACT 3 (108.5m -> 175m): WORLD 1 CLIMAX — VINE SURF + TRIPLE SUN-BUD METEOR SLINGSHOT!
	# =========================================================================
	var slide_arch := Vector3(-3.0, 111.5, -27.0)
	WorldHelper.add_static_box_platform(self, ARCH, slide_arch, Vector3(3.6, 0.6, 6.8), Vector3(1.05, 1.0, 1.05), Vector3(0.0, 85.0, 0.0), STYLE, audit)
	WorldHelper.add_slide_obstacle(self, slide_arch, 85.0, 3.8, Color(1.0, 0.80, 0.30))

	# Sweeping High-Speed Vine Grind Rail #2 curving skyward!
	WorldHelper.add_grind_rail(self, PackedVector3Array([
		Vector3(-11.0, 113.0, -24.5),
		Vector3(-22.0, 121.0, -16.5),
		Vector3(-27.5, 129.0, -3.5),
		Vector3(-25.0, 134.5, 8.5),
	]), Color(0.55, 0.98, 0.44), 23.0, 11.2, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-11.0, 114.2, -24.5), Vector3(-27.5, 130.2, -3.5), 2.6, 5)

	var high_plinth := Vector3(-23.0, 136.5, 14.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, high_plinth, 2.6, 0.8, Vector3(1.25, 1.0, 1.25), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, high_plinth + Vector3(-1.7, 0.0, -0.5), 95.0, STYLE)

	# CLIMAX SET-PIECE: Meteor Sun-Bud -> Double Dash-Prism Aerial Combo -> Final Meteor Bud to W2 Gate!
	WorldHelper.add_world_hint(self, high_plinth + Vector3(1.5, 2.4, 2.5), "CLIMAX · SUN-BUD SLINGSHOT!", "Meteor-Slam the Sun-Buds & shatter mid-air prisms to reach World II!")
	WorldHelper.add_meteor_trigger(self, Vector3(-16.5, 139.0, 20.5), "bud", 27.5, Vector3(6.5, 0.0, 3.8), "", audit)
	WorldHelper.add_dash_prism(self, Vector3(-8.5, 151.5, 24.5), Color(0.45, 0.96, 1.0), 10.6, audit)
	WorldHelper.add_sun_shard(self, "w1_s3", Vector3(-8.5, 155.5, 24.5))
	WorldHelper.add_dash_prism(self, Vector3(-0.5, 157.5, 25.8), Color(1.0, 0.86, 0.34), 10.4, audit)
	WorldHelper.add_meteor_trigger(self, Vector3(6.0, 159.5, 25.2), "bud", 28.5, Vector3(5.8, 0.0, -1.8), "", audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(6.0, 161.0, 25.2), Vector3(13.5, 174.2, 23.0), 5.0, 5)

	# World 1 -> World 2 Monumental Ascension Gate
	var gate_pos := Vector3(13.5, 173.0, 23.0)
	WorldHelper.add_static_cyl_platform(self, PLINTH, gate_pos, 2.6, 1.0, Vector3(2.1, 1.2, 2.1), Vector3.ZERO, STYLE, audit, "world_gate_pad")
	WorldHelper.add_lush_grass_carpet(self, gate_pos, 4.9, 110, 1014, 1.0)
	WorldHelper.add_wildflower_scatter(self, gate_pos, 2.2, 4.8, 16, 1030)
	WorldHelper.add_mossy_stones(self, gate_pos, 4.9, 4, 1034)
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(2.0, 0.0, -2.0), Vector3.ONE, Vector3(0.0, -45.0, 0.0), STYLE)
	WorldHelper.add_lamp_post(self, gate_pos + Vector3(-2.6, 0.0, 2.2), 15.0, Color(1.0, 0.72, 0.34), 3.6, 12.0)
	return gate_pos
