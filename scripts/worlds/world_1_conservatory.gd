extends Node3D
class_name World1Conservatory
## World 1: The Sunken Conservatory (0m -> 175m)
## Sunlit morning terracotta viaducts, Victorian glasshouse spire core, broken stained-glass domes,
## clover-fringed mossy flagstones, giant springy lily pads, and shimmering glasshouse wind updrafts.

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
	# Warm glowing conservatory gallery light pools & halos radiating from the tower windows!
	for tier in range(5):
		var ty := 44.5 + tier * 30.0
		for w in range(4):
			var wa := w * 90.0 + tier * 22.0 + 22.5
			var wp := WorldHelper.spiral_pt(wa, 16.0, ty)
			WorldHelper.add_warm_light_pool(self, wp, Color(1.0, 0.72, 0.34), 3.6, 20.0, true, 2.4, (w % 2 == 0))

	# 2 Biome-Specific Distant Parallax Horizon Silhouette Rings (155-380m out, 3D-shaded into morning fog!)
	WorldHelper.add_parallax_ring(self, 0, 45.0, 155.0, 240.0, 14, false, 1011)
	WorldHelper.add_parallax_ring(self, 0, 115.0, 250.0, 380.0, 16, true, 1012)

	# =========================================================================
	# ACT 1 (0m -> 58m): Awakening Terrace & Botanical Lily Ascent
	# =========================================================================
	var p_start := Vector3(0.0, 0.0, 26.0)
	WorldHelper.add_static_cyl_platform(self, PLINTH, p_start, 2.6, 1.0, Vector3(2.5, 1.3, 2.5), Vector3.ZERO, TERRACE_STYLE, audit, "start")
	# Lush interactive wind-swaying grass carpet, colorful wildflowers & mossy terrace rim stones!
	WorldHelper.add_lush_grass_carpet(self, p_start, 5.75, 240, 1011, 0.0)
	WorldHelper.add_grass_tuft_rim(self, p_start, 4.4, 5.9, 64, 1001)
	WorldHelper.add_wildflower_scatter(self, p_start, 2.2, 5.6, 24, 1021)
	WorldHelper.add_mossy_stones(self, p_start, 5.6, 5, 1031, true)
	WorldHelper.add_shrine(self, "w1_cp1", 0, p_start + Vector3(-5.0, 0.0, -3.5), 0.0, true, false, audit, Vector3(5.0, 0.8, 3.1))

	# Cozy Conservatory Sanctuary Dressing + Docked 'Dawnbreaker' Sky-Airship Arrival Pier!
	WorldHelper.add_docked_airship(self, p_start + Vector3(-10.2, 0.08, 2.0), -18.0)
	WorldHelper.add_world_hint(self, p_start + Vector3(-7.8, 2.35, 1.6), "THE DAWNBREAKER — DOCKED", "The Sun-Heart at 1,085m is dying. Walk the gangplank & ascend.")
	WorldHelper.add_landmark(self, TREE, p_start + Vector3(4.2, 0.0, -2.5), Vector3(1.12, 1.12, 1.12), Vector3(0.0, -28.0, 0.0), STYLE, 190.0)
	WorldHelper.add_landmark(self, TREE, p_start + Vector3(-4.2, 0.0, 4.4), Vector3(0.95, 0.95, 0.95), Vector3(0.0, 42.0, 0.0), STYLE, 190.0)
	WorldHelper.add_landmark(self, FERN, p_start + Vector3(3.1, 0.0, -3.9), Vector3(0.95, 0.95, 0.95), Vector3(0.0, 18.0, 0.0), STYLE, 140.0, true)
	WorldHelper.add_landmark(self, FERN, p_start + Vector3(-2.6, 0.0, -4.1), Vector3(0.85, 0.85, 0.85), Vector3(0.0, -42.0, 0.0), STYLE, 140.0, true)
	WorldHelper.add_landmark(self, FERN, p_start + Vector3(4.6, 0.0, 1.4), Vector3(1.05, 1.05, 1.05), Vector3(0.0, 85.0, 0.0), STYLE, 140.0, true)
	WorldHelper.add_lamp_post(self, p_start + Vector3(-3.3, 0.0, -0.4), 18.0, Color(1.0, 0.72, 0.34), 3.8, 10.5)
	WorldHelper.add_lamp_post(self, p_start + Vector3(3.4, 0.0, -0.8), 165.0, Color(1.0, 0.72, 0.34), 3.8, 10.5)
	# Overhead catenary lantern garland draped high above the inner glasshouse arch (out of camera runway!)
	WorldHelper.add_catenary_lanterns(self, Vector3(4.5, 9.2, 16.5), Vector3(11.5, 11.8, 6.5), 5, 0.95, Color(1.0, 0.66, 0.32))

	# Sweeping continuous glasshouse cathedral arches forming a vaulted sunlit gallery!
	WorldHelper.add_landmark(self, DOME, Vector3(0.0, -2.0, 14.0), Vector3(1.45, 1.45, 1.45), Vector3(0.0, 0.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, DOME, Vector3(13.0, 4.0, 2.0), Vector3(1.35, 1.35, 1.35), Vector3(0.0, -48.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, DOME, Vector3(-16.0, 28.0, -10.0), Vector3(1.6, 1.6, 1.6), Vector3(0.0, 52.0, 6.0), STYLE)
	WorldHelper.add_landmark(self, DOME, Vector3(22.0, 92.0, -12.0), Vector3(1.7, 1.7, 1.7), Vector3(0.0, -38.0, -6.0), STYLE)

	# Floating botanical ruin islets with sculpted trees & ferns populating the surrounding morning sky!
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

	# Opening joyful sprint-and-jump cadence along sunlit aqueduct arches spiraling clockwise
	WorldHelper.add_world_hint(self, Vector3(0.0, 2.35, 21.6), "BEGIN THE ASCENT", "{move} Move  ·  {jump} Jump  ·  Double-Jump mid-air")
	var p := Vector3(0.0, 1.5, 16.5)
	WorldHelper.add_static_box_platform(self, ARCH, p, Vector3(3.4, 0.6, 6.6), Vector3.ONE, Vector3(0.0, 0.0, 0.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, p + Vector3(0.0, 0.6, -2.5), Vector3(5.5, 4.6, 8.5), 2.4, 4)
	WorldHelper.add_world_hint(self, Vector3(2.6, 3.85, 12.8), "SPRINT & AIR-DASH", "Hold {sprint} to Sprint  ·  {dash} mid-air to Air-Dash")

	p = Vector3(5.5, 4.0, 8.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, p, 2.6, 0.8, Vector3(1.1, 1.0, 1.1), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_grass_tuft_rim(self, p, 2.0, 2.6, 22, 1002)
	WorldHelper.add_wildflower_scatter(self, p, 1.3, 2.5, 8, 1022)

	p = Vector3(13.0, 6.8, 3.0)
	WorldHelper.add_static_cyl_platform(self, PLINTH, p, 2.6, 0.8, Vector3(1.0, 1.0, 1.0), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_wildflower_scatter(self, p, 1.2, 2.3, 8, 1023)
	WorldHelper.add_dressing_cluster(self, CLUSTER, p + Vector3(1.5, 0.0, 0.8), -45.0, STYLE)
	WorldHelper.add_solar_mote_arc(self, Vector3(13.0, 7.5, 3.0), Vector3(19.5, 9.9, -3.5), 2.2, 4)
	WorldHelper.add_world_hint(self, Vector3(16.0, 9.25, 0.0), "SUN-FLOWER BOUNCE", "Step on Petals to Soar  ·  Hold {slide} mid-air for METEOR BOUNCE!")

	# First Giant Botanical Lily Pad Bounce (L111 -> L114)
	p = Vector3(19.5, 9.2, -3.5)
	WorldHelper.add_bounce_pad(self, LILY, p, 23.4, 2.3, Vector3(2.0, 0.0, -6.2), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(19.5, 10.2, -3.5), Vector3(21.5, 18.2, -11.5), 4.2, 5)

	p = Vector3(21.5, 17.5, -11.5)
	WorldHelper.add_static_box_platform(self, ARCH, p, Vector3(3.4, 0.6, 6.6), Vector3.ONE, Vector3(0.0, -18.0, 0.0), STYLE, audit)
	WorldHelper.add_world_hint(self, Vector3(20.0, 19.9, -15.2), "FLOW & SKY SHRINES", "Chain hops for Flow  ·  Touch glowing Shrines to save")

	var shard1_pad := Vector3(30.5, 19.5, -14.0)
	WorldHelper.add_bounce_pad(self, LILY, shard1_pad, 19.0, 2.1, Vector3(-5.0, 0.0, -2.0), STYLE, [])
	WorldHelper.add_sun_shard(self, "w1_s1", shard1_pad + Vector3(0.0, 4.2, 0.0))

	var act1_steps := [
		Vector3(17.5, 21.0, -20.5),
		Vector3(10.0, 24.5, -24.0),
		Vector3(2.0, 28.0, -25.0),
	]
	for idx in range(act1_steps.size()):
		var sp: Vector3 = act1_steps[idx]
		WorldHelper.add_static_cyl_platform(self, PLINTH, sp, 2.6, 0.8, Vector3(1.05, 1.0, 1.05), Vector3.ZERO, STYLE, audit)
		WorldHelper.add_wildflower_scatter(self, sp, 1.2, 2.4, 6, 1024 + idx)
		if idx == 1:
			WorldHelper.add_dressing_cluster(self, CLUSTER, sp + Vector3(0.0, 0.0, -1.7), 180.0, STYLE)
			WorldHelper.add_grass_tuft_rim(self, sp, 1.9, 2.5, 20, 1003)

	WorldHelper.add_bounce_pad(self, LILY, Vector3(-6.5, 30.5, -23.0), 22.0, 2.3, Vector3(-3.0, 0.0, 2.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-6.5, 31.5, -23.0), Vector3(-14.5, 39.8, -18.0), 4.2, 4)
	WorldHelper.add_bounce_pad(self, LILY, Vector3(-14.5, 39.0, -18.0), 22.0, 2.3, Vector3(-2.5, 0.0, 3.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-14.5, 40.0, -18.0), Vector3(-21.0, 48.2, -11.0), 4.2, 4)

	p = Vector3(-21.0, 47.5, -11.0)
	WorldHelper.add_static_box_platform(self, ARCH, p, Vector3(3.4, 0.6, 6.6), Vector3.ONE, Vector3(0.0, 45.0, 0.0), STYLE, audit)

	# SET-PIECE / PRO SHORTCUT #1: "Sun-Arch Sky-Skip" (Daring outer narrow beam + Super-Bloom flower + Tether chain skipping to Y=81m!)
	WorldHelper.add_static_box_platform(self, ARCH, Vector3(-28.0, 49.0, -4.5), Vector3(3.4, 0.6, 6.6), Vector3(0.42, 1.0, 1.15), Vector3(0.0, -35.0, 0.0), STYLE, [])
	WorldHelper.add_bounce_pad(self, LILY, Vector3(-32.5, 51.5, 4.0), 25.4, 2.3, Vector3(5.0, 0.0, 7.2), STYLE, [])
	WorldHelper.add_solar_mote_arc(self, Vector3(-32.5, 52.5, 4.0), Vector3(-25.0, 64.5, 12.5), 3.8, 4)
	WorldHelper.add_tether_orb(self, Vector3(-25.0, 64.5, 12.5), [])
	WorldHelper.add_solar_mote_arc(self, Vector3(-25.0, 64.5, 12.5), Vector3(-12.0, 73.5, 21.5), 3.0, 4)
	WorldHelper.add_tether_orb(self, Vector3(-12.0, 73.5, 21.5), [])
	WorldHelper.add_solar_mote_arc(self, Vector3(-12.0, 73.5, 21.5), Vector3(0.5, 78.8, 24.5), 2.6, 3)
	WorldHelper.add_static_cyl_platform(self, PLINTH, Vector3(0.5, 78.2, 24.5), 2.6, 0.8, Vector3(0.88, 1.0, 0.88), Vector3.ZERO, STYLE, [])
	WorldHelper.add_shortcut_beacon(self, Vector3(0.5, 78.2, 24.5), -65.0, "SUN-ARCH SKY-SKIP!", "+30m PRO SHORTCUT")

	# Checkpoint 2 Sanctuary Terrace (Y = 54m)
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
	# ACT 2 (54m -> 115m): Crumbling Flagstone Cascade & First Glasshouse Updraft
	# =========================================================================
	var crumble_run := [
		Vector3(-25.0, 53.2, 8.0),
		Vector3(-21.5, 56.0, 16.5),
		Vector3(-15.5, 59.0, 23.0),
		Vector3(-7.5, 62.0, 26.5),
	]
	for idx in range(crumble_run.size()):
		WorldHelper.add_crumbling_tile(self, FLAG, crumble_run[idx], 1.05, false, Vector3(0.0, idx * 20.0, 0.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-25.0, 54.0, 8.0), Vector3(-15.5, 59.8, 23.0), 2.8, 4)
	WorldHelper.add_solar_mote_arc(self, Vector3(-15.5, 59.8, 23.0), Vector3(1.5, 65.2, 27.5), 2.6, 4)

	var ud1_base := Vector3(1.5, 64.5, 27.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, ud1_base, 2.6, 0.8, Vector3(1.25, 1.0, 1.25), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, ud1_base + Vector3(-1.6, 0.0, 1.4), 35.0, STYLE)
	WorldHelper.add_updraft(self, ud1_base + Vector3(3.5, 0.5, -2.5), 18.0, 3.0, Color(0.65, 1.0, 0.82), audit)
	WorldHelper.add_solar_mote_arc(self, ud1_base + Vector3(3.5, 2.0, -2.5), Vector3(11.5, 81.8, 23.0), 4.5, 4)
	WorldHelper.add_sun_shard(self, "w1_s2", ud1_base + Vector3(5.0, 15.5, -3.5))

	WorldHelper.add_static_box_platform(self, ARCH, Vector3(11.5, 81.0, 23.0), Vector3(3.4, 0.6, 6.6), Vector3.ONE, Vector3(0.0, -52.0, 0.0), STYLE, audit)
	WorldHelper.add_static_cyl_platform(self, PLINTH, Vector3(19.5, 84.0, 16.5), 2.6, 0.8, Vector3(1.0, 1.0, 1.0), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_crumbling_tile(self, FLAG, Vector3(25.0, 87.0, 9.0), 0.95, false, Vector3(0.0, 15.0, 0.0), audit)
	WorldHelper.add_bounce_pad(self, LILY, Vector3(27.5, 89.5, 0.5), 22.5, 2.3, Vector3(0.0, 0.0, -3.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(27.5, 90.5, 0.5), Vector3(26.5, 99.2, -8.5), 4.2, 4)
	var mid_plinth := Vector3(26.5, 98.5, -8.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, mid_plinth, 2.6, 0.8, Vector3(1.15, 1.0, 1.15), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, mid_plinth + Vector3(1.7, 0.0, -0.5), -85.0, STYLE)
	WorldHelper.add_crumbling_tile(self, FLAG, Vector3(22.0, 101.8, -16.5), 0.95, false, Vector3(0.0, -25.0, 0.0), audit)
	WorldHelper.add_crumbling_tile(self, FLAG, Vector3(15.0, 105.0, -22.5), 0.95, false, Vector3(0.0, -45.0, 0.0), audit)

	# Checkpoint 3 Canopy Overlook (Y = 109m)
	var cp3 := Vector3(6.5, 108.5, -26.5)
	WorldHelper.add_static_cyl_platform(self, PLINTH, cp3, 2.6, 1.0, Vector3(1.75, 1.2, 1.75), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w1_cp3", 0, cp3, 75.0, false, false, audit)
	WorldHelper.add_lush_grass_carpet(self, cp3, 4.1, 96, 1013, 1.2)
	WorldHelper.add_grass_tuft_rim(self, cp3, 3.2, 4.2, 34, 1005)
	WorldHelper.add_wildflower_scatter(self, cp3, 2.0, 4.0, 14, 1029)
	WorldHelper.add_mossy_stones(self, cp3, 4.1, 3, 1033)
	WorldHelper.add_lamp_post(self, cp3 + Vector3(2.4, 0.0, -2.0), -135.0, Color(1.0, 0.72, 0.34), 3.6, 10.0)

	# =========================================================================
	# ACT 3 (109m -> 175m): Conservatory Sky-Sprint & Ascension Gate to World 2
	# =========================================================================
	WorldHelper.add_static_box_platform(self, ARCH, Vector3(-3.0, 111.5, -27.0), Vector3(3.4, 0.6, 6.6), Vector3.ONE, Vector3(0.0, 85.0, 0.0), STYLE, audit)
	WorldHelper.add_bounce_pad(self, LILY, Vector3(-12.5, 114.0, -24.5), 22.0, 2.3, Vector3(-3.0, 0.0, 2.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-12.5, 115.0, -24.5), Vector3(-20.0, 123.2, -18.5), 4.0, 4)
	WorldHelper.add_crumbling_tile(self, FLAG, Vector3(-20.0, 122.5, -18.5), 0.90, false, Vector3(0.0, 35.0, 0.0), audit)
	WorldHelper.add_bounce_pad(self, LILY, Vector3(-25.5, 125.0, -10.5), 22.5, 2.3, Vector3(-1.0, 0.0, 3.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-25.5, 126.0, -10.5), Vector3(-27.0, 134.8, -1.0), 4.2, 4)
	var high_plinth := Vector3(-27.0, 134.0, -1.0)
	WorldHelper.add_static_cyl_platform(self, PLINTH, high_plinth, 2.6, 0.8, Vector3(1.15, 1.0, 1.15), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, high_plinth + Vector3(-1.7, 0.0, -0.5), 95.0, STYLE)

	WorldHelper.add_updraft(self, Vector3(-25.5, 134.5, 7.5), 18.0, 3.0, Color(0.85, 0.96, 0.62), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-25.5, 136.0, 7.5), Vector3(-20.0, 151.8, 14.5), 4.5, 4)
	WorldHelper.add_static_cyl_platform(self, PLINTH, Vector3(-20.0, 151.0, 14.5), 2.6, 0.8, Vector3(1.2, 1.0, 1.2), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_sun_shard(self, "w1_s3", Vector3(-12.0, 157.0, 16.5))

	WorldHelper.add_crumbling_tile(self, FLAG, Vector3(-13.0, 154.5, 20.5), 0.90, false, Vector3.ZERO, audit)
	WorldHelper.add_bounce_pad(self, LILY, Vector3(-5.0, 157.5, 24.5), 25.2, 2.4, Vector3(5.5, 0.0, 0.8), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-5.0, 158.5, 24.5), Vector3(4.5, 168.8, 25.5), 4.5, 5)
	WorldHelper.add_static_box_platform(self, ARCH, Vector3(4.5, 168.0, 25.5), Vector3(3.4, 0.6, 6.6), Vector3.ONE, Vector3(0.0, -78.0, 0.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(4.5, 168.8, 25.5), Vector3(13.5, 173.8, 23.0), 2.5, 4)

	# World 1 -> World 2 Monumental Ascension Gate
	var gate_pos := Vector3(13.5, 173.0, 23.0)
	WorldHelper.add_static_cyl_platform(self, PLINTH, gate_pos, 2.6, 1.0, Vector3(2.1, 1.2, 2.1), Vector3.ZERO, STYLE, audit, "world_gate_pad")
	WorldHelper.add_lush_grass_carpet(self, gate_pos, 4.9, 110, 1014, 1.0)
	WorldHelper.add_wildflower_scatter(self, gate_pos, 2.2, 4.8, 16, 1030)
	WorldHelper.add_mossy_stones(self, gate_pos, 4.9, 4, 1034)
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(2.0, 0.0, -2.0), Vector3.ONE, Vector3(0.0, -45.0, 0.0), STYLE)
	WorldHelper.add_lamp_post(self, gate_pos + Vector3(-2.6, 0.0, 2.2), 15.0, Color(1.0, 0.72, 0.34), 3.6, 12.0)
	return gate_pos
