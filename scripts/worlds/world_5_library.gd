extends Node3D
class_name World5Library
## World 5: The Cloud-Whale Library (730m -> 920m)
## Signature Twist: Aurora Grind Rails, Zero-G "No-Floor" Orbital Tether + Dash-Prism Playgrounds,
## AND THE LIVING RIDEABLE CLOUD-WHALE LEVIATHAN — board its back, sprint up its glowing spine,
## and launch off its Spout Geyser into the Stratosphere!

const RIB := "res://assets/models/world5_library/opal_whale_rib.glb"
const SHELF := "res://assets/models/world5_library/floating_bookshelf.glb"
const TOME := "res://assets/models/world5_library/luminous_tome.glb"
const JELLY := "res://assets/models/world5_library/dream_jelly_pad.glb"
const GATE := "res://assets/models/common/world_gate.glb"
const CORE := "res://assets/models/tower_cores/w5_library_core.glb"
const CLUSTER := "res://assets/models/dressing/w5_reading_cluster.glb"

const STYLE := {
	"top": Color(0.28, 0.78, 0.88),
	"top_blend": 0.10,
	"rim": Color(0.45, 0.94, 1.0),
	"rim_s": 0.38,
	"shadow": Color(0.08, 0.12, 0.30),
	"tex": "wood_planks",
	"tex_scale": 0.38,
	"tex_blend": 0.70,
}


func build(start_pos: Vector3, audit: Array) -> Vector3:
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 730.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	for lvl in range(6):
		var ly := 730.0 + 21.5 + lvl * 30.0
		for b in range(4):
			var ba := b * 90.0 + rad_to_deg(lvl * 0.22)
			var bp := WorldHelper.spiral_pt(ba, 18.2, ly)
			WorldHelper.add_warm_light_pool(self, bp, Color(1.0, 0.72, 0.30), 4.0, 22.0, true, 2.6, (b % 2 == 0))

	WorldHelper.add_parallax_ring(self, 4, 795.0, 165.0, 260.0, 14, false, 5011)
	WorldHelper.add_parallax_ring(self, 4, 875.0, 270.0, 400.0, 16, true, 5012)

	# =========================================================================
	# ACT 13 (730m -> 791m): Aurora Rail #1 + Zero-G Dream Bubble "No-Floor" Playground!
	# =========================================================================
	var cp1 := start_pos + Vector3(-9.5, 2.0, 1.0)
	WorldHelper.add_static_box_platform(self, SHELF, cp1, Vector3(5.2, 0.5, 4.4), Vector3(1.25, 1.0, 1.25), Vector3(0.0, 10.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w5_cp1", 4, cp1, 75.0, true, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp1 + Vector3(-2.1, 0.0, 1.6), 30.0, STYLE, Color(1.0, 0.72, 0.30))

	var candle_spots := [
		cp1 + Vector3(2.2, 2.6, 1.4),
		Vector3(-23.0, 748.0, 1.0),
		Vector3(-14.5, 768.2, 21.5),
		Vector3(22.0, 794.2, 16.0),
		Vector3(20.5, 817.5, -17.0),
		Vector3(-24.5, 859.8, -10.5),
	]
	for idx in range(candle_spots.size()):
		var cpos: Vector3 = candle_spots[idx]
		WorldHelper.add_landmark(self, "res://assets/models/scenery/floating_candle_cluster.glb", cpos, Vector3(1.25, 1.25, 1.25), Vector3(0.0, idx * 60.0, 0.0), STYLE, 145.0, true)
		WorldHelper.add_warm_light_pool(self, cpos + Vector3(0.0, -1.2, 0.0), Color(1.0, 0.68, 0.28), 2.4, 16.0, false, 1.8)
		WorldHelper.add_lamp_halo(self, cpos + Vector3(0.0, 0.35, 0.0), Color(1.0, 0.68, 0.28), 1.65, 0.68)

	WorldHelper.add_catenary_lanterns(self, Vector3(-13.5, 771.5, 19.5), Vector3(-10.0, 772.5, 14.0), 5, 0.95, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(20.0, 797.5, 14.5), Vector3(14.0, 798.5, 10.5), 5, 0.95, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(18.5, 820.5, -15.5), Vector3(13.0, 821.5, -11.0), 5, 0.95, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(-22.5, 863.0, -9.5), Vector3(-15.5, 864.0, -7.0), 5, 0.95, Color(1.0, 0.66, 0.32))

	for i in range(7):
		var a := 72.0 - i * 44.0
		var rpos := WorldHelper.spiral_pt(a, 24.0, 738.0 + i * 26.0)
		WorldHelper.add_landmark(self, RIB, rpos, Vector3(1.5, 1.5, 1.5), Vector3(12.0, a + 90.0, -8.0), {})

	_spawn_floating_pages(Vector3(0.0, 825.0, 0.0))

	# AURORA GRIND RAIL #1 launching straight into Giant Zero-G Dream Bubble #1!
	WorldHelper.add_world_hint(self, cp1 + Vector3(-2.5, 2.5, 2.0), "AURORA RAIL -> ZERO-G CHAIN!", "Surf the Aurora Rail straight into Zero-G Prisms & Tether Orbs!")
	WorldHelper.add_grind_rail(self, PackedVector3Array([
		Vector3(-15.5, 732.0, -22.5),
		Vector3(-23.5, 737.5, -12.5),
		Vector3(-26.5, 743.0, 1.5),
	]), Color(0.38, 0.96, 1.0), 23.0, 11.5, audit)

	# ZERO-G "NO-FLOOR" AERIAL PLAYGROUND inside Bubble #1 (Dash-Prism -> Tether Orb -> Shelf!)
	WorldHelper.add_gravity_bubble(self, Vector3(-24.5, 752.0, 9.5), 15.5, audit)
	WorldHelper.add_dash_prism(self, Vector3(-24.5, 751.5, 10.5), Color(0.40, 0.98, 1.0), 10.5, audit)
	WorldHelper.add_tether_orb(self, Vector3(-20.0, 761.5, 17.5), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-24.5, 752.0, 10.5), Vector3(-14.5, 766.0, 21.5), 3.4, 5)

	var sh1 := Vector3(-14.5, 765.0, 21.5)
	WorldHelper.add_static_box_platform(self, SHELF, sh1, Vector3(5.2, 0.5, 4.4), Vector3.ONE, Vector3(0.0, 145.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, sh1 + Vector3(-1.6, 0.0, 1.2), 145.0, STYLE, Color(1.0, 0.72, 0.30))

	# SUN-SHARD TRIAL #5: Zero-G Tether Constellation Sprint (awards w5_s1!)
	WorldHelper.add_shard_trial(self, sh1 + Vector3(1.2, 0.0, 0.8), "w5_s1", "AURORA TETHER TRIAL", PackedVector3Array([
		Vector3(-9.0, 770.5, 24.5),
		Vector3(-4.5, 774.5, 25.5),
		Vector3(0.5, 777.0, 26.5),
		Vector3(4.5, 778.8, 26.5),
	]), 11.5)

	WorldHelper.add_tether_orb(self, Vector3(-5.0, 773.5, 25.5), audit)
	WorldHelper.add_static_box_platform(self, TOME, Vector3(4.5, 777.5, 26.5), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, -82.0, 0.0), STYLE, audit)
	WorldHelper.add_bounce_pad(self, JELLY, Vector3(13.5, 780.5, 23.5), 23.0, 2.5, Vector3(3.0, 0.0, -2.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(13.5, 781.5, 23.5), Vector3(22.0, 791.8, 16.0), 4.2, 4)

	# Checkpoint 2: Astral Reading Balcony (Y = 791m)
	var cp2 := Vector3(22.0, 791.0, 16.0)
	WorldHelper.add_static_box_platform(self, SHELF, cp2, Vector3(5.2, 0.5, 4.4), Vector3(1.2, 1.0, 1.2), Vector3(0.0, -135.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w5_cp2", 4, cp2, -30.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp2 + Vector3(1.8, 0.0, 1.5), -135.0, STYLE, Color(1.0, 0.72, 0.30))

	# =========================================================================
	# ACT 14 (791m -> 856.5m): Orbital Tether-Prism Constellation + Aurora Rail #2!
	# =========================================================================
	WorldHelper.add_gravity_bubble(self, Vector3(25.5, 804.5, -2.0), 17.0, audit)
	WorldHelper.add_tether_orb(self, Vector3(26.5, 799.5, 5.5), audit)
	WorldHelper.add_dash_prism(self, Vector3(27.5, 806.5, -1.5), Color(0.40, 0.96, 1.0), 10.6, audit)
	WorldHelper.add_tether_orb(self, Vector3(26.0, 811.0, -8.5), audit)
	WorldHelper.add_sun_shard(self, "w5_s2", Vector3(26.5, 815.5, -1.5))

	var sh2 := Vector3(20.5, 814.0, -17.0)
	WorldHelper.add_static_box_platform(self, SHELF, sh2, Vector3(5.2, 0.5, 4.4), Vector3.ONE, Vector3(0.0, -55.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, sh2 + Vector3(1.6, 0.0, -1.2), -55.0, STYLE, Color(1.0, 0.72, 0.30))

	# AURORA GRIND RAIL #2 weaving beneath the glowing Cloud-Whale Ribs!
	WorldHelper.add_grind_rail(self, PackedVector3Array([
		Vector3(15.0, 816.2, -21.5),
		Vector3(4.5, 824.0, -26.5),
		Vector3(-7.5, 833.0, -25.8),
	]), Color(0.55, 0.92, 1.0), 23.5, 11.2, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(15.0, 817.4, -21.5), Vector3(-7.5, 834.2, -25.8), 2.8, 5)

	WorldHelper.add_bounce_pad(self, JELLY, Vector3(-10.5, 835.5, -24.5), 23.5, 2.5, Vector3(-3.0, 0.0, 2.2), STYLE, audit)
	WorldHelper.add_tether_orb(self, Vector3(-18.5, 849.5, -18.5), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-18.5, 849.5, -18.5), Vector3(-24.5, 857.2, -10.5), 2.6, 3)

	# Checkpoint 3: Leviathan Crown Shelf (Y = 856.5m)
	var cp3 := Vector3(-24.5, 856.5, -10.5)
	WorldHelper.add_static_box_platform(self, SHELF, cp3, Vector3(5.2, 0.5, 4.4), Vector3(1.2, 1.0, 1.2), Vector3(0.0, 62.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w5_cp3", 4, cp3, 168.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp3 + Vector3(-1.8, 0.0, -1.4), 62.0, STYLE, Color(1.0, 0.72, 0.30))

	# Exposed Overlook #4
	WorldHelper.add_static_box_platform(self, SHELF, cp3 + Vector3(-6.4, 0.15, -2.75), Vector3(5.2, 0.5, 4.4), Vector3(0.25, 0.72, 2.55), Vector3(0.0, 66.8, 0.0), STYLE, [])
	WorldHelper.add_solar_mote_arc(self, cp3 + Vector3(-3.0, 1.0, -1.3), cp3 + Vector3(-10.4, 1.2, -4.45), 1.4, 3)
	WorldHelper.add_world_hint(self, cp3 + Vector3(-10.8, 2.1, -4.65), "CHRONICLE V — THE WHALE'S VIGIL", "857m above home. The Cloud-Whale kept the last aurora alive until you climbed.")

	# =========================================================================
	# ACT 15 (856.5m -> 919m): WORLD 5 CLIMAX — BOARD & RIDE THE LIVING CLOUD-WHALE!
	# Plus a parallel Zero-G Prism/Tether sky-line so speedrunners & whale-riders both soar!
	# =========================================================================
	WorldHelper.add_static_box_platform(self, TOME, Vector3(-27.0, 860.0, -1.0), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, 5.0, 0.0), STYLE, audit)
	WorldHelper.add_bounce_pad(self, JELLY, Vector3(-25.0, 863.5, 9.0), 24.5, 2.5, Vector3(2.0, 0.0, 3.0), STYLE, audit)

	# Whale Boarding Balcony right alongside the Cloud-Whale's R=27m orbit!
	var whale_dock := Vector3(-19.5, 879.0, 18.0)
	WorldHelper.add_static_box_platform(self, SHELF, whale_dock, Vector3(5.4, 0.5, 4.8), Vector3(1.15, 1.0, 1.15), Vector3(0.0, -45.0, 0.0), STYLE, audit)
	WorldHelper.add_world_hint(self, whale_dock + Vector3(1.5, 2.6, 1.5), "CLIMAX · RIDE THE CLOUD-WHALE!", "Leap onto the Leviathan's back -> sprint up its spine to the Spout Geyser!")

	# THE LIVING RIDEABLE CLOUD-WHALE LEVIATHAN (circles at Y = 882m, Spout launches +31m into World 6!)
	WorldHelper.add_rideable_whale(self, Vector3(0.0, 882.0, 0.0), 27.0, 0.27, 31.5, audit)
	# Also spawn a decorative high twin whale in the far outer sky for majesty
	WorldHelper.add_flow_express(self, Vector3(-11.0, 886.0, 23.5), -68.0, Vector3(3.8, 0.36, 10.0))

	# Stratosphere Zero-G Aerial Chain linking Whale Spout (and Dock) straight onto the Crown Gate!
	WorldHelper.add_gravity_bubble(self, Vector3(-7.0, 894.0, 25.5), 14.5, audit)
	WorldHelper.add_dash_prism(self, Vector3(-9.0, 892.5, 25.0), Color(0.45, 0.96, 1.0), 11.2, audit)
	WorldHelper.add_sun_shard(self, "w5_s3", Vector3(-9.0, 897.5, 25.0))
	WorldHelper.add_tether_orb(self, Vector3(3.0, 903.5, 26.5), audit)
	WorldHelper.add_tether_orb(self, Vector3(13.5, 911.0, 22.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(13.5, 911.0, 22.0), Vector3(22.5, 919.8, 14.0), 2.8, 4)

	# World 5 -> World 6 Crown of the Sun Ascension Gate (Y = 919m)
	var gate_pos := Vector3(22.5, 919.0, 14.0)
	WorldHelper.add_static_box_platform(self, SHELF, gate_pos, Vector3(5.4, 0.6, 4.6), Vector3(1.3, 1.0, 1.3), Vector3(0.0, -145.0, 0.0), STYLE, audit, "world_gate_pad")
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(1.5, 0.0, -3.5), Vector3.ONE, Vector3(0.0, -25.0, 0.0), STYLE)
	return gate_pos


func _spawn_floating_pages(center: Vector3) -> void:
	var gp := GPUParticles3D.new()
	gp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gp.position = center
	gp.amount = 140
	gp.lifetime = 8.0
	gp.visibility_aabb = AABB(Vector3(-46, -95, -46), Vector3(92, 190, 92))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(36.0, 85.0, 36.0)
	pm.direction = Vector3(0.25, 0.85, 0.18)
	pm.spread = 48.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.6
	pm.angular_velocity_min = -45.0
	pm.angular_velocity_max = 45.0
	pm.gravity = Vector3(0.0, 0.08, 0.0)
	gp.process_material = pm

	var m := BoxMesh.new()
	m.size = Vector3(0.32, 0.015, 0.44)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.90, 0.64, 0.90)
	mat.roughness = 0.68
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.78, 0.38)
	mat.emission_energy_multiplier = 0.75
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material = mat
	gp.draw_pass_1 = m
	add_child(gp)
