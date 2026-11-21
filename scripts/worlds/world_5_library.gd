extends Node3D
class_name World5Library
## World 5: The Cloud-Whale Library (730m -> 920m)
## Deep velvet night & aurora borealis, colossal Spiral Library Tower Core with warm candlelit reading nooks,
## circling luminous Celestial Cloud-Whale, opal whale-ribs, floating bookshelves, and crystal-clear Gravity Bubbles!

const RIB := "res://assets/models/world5_library/opal_whale_rib.glb"
const SHELF := "res://assets/models/world5_library/floating_bookshelf.glb"
const TOME := "res://assets/models/world5_library/luminous_tome.glb"
const JELLY := "res://assets/models/world5_library/dream_jelly_pad.glb"
const GATE := "res://assets/models/common/world_gate.glb"
const CORE := "res://assets/models/tower_cores/w5_library_core.glb"
const WHALE := "res://assets/models/tower_cores/cloud_whale_leviathan.glb"
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

var _whale_pivot: Node3D


func build(start_pos: Vector3, audit: Array) -> Vector3:
	# =========================================================================
	# CENTRAL SOLSTICE SPIRE CORE (World 5: Spiral Sky-Library Tower + Cloud-Whale!)
	# =========================================================================
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 730.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	# Warm Dalbit-Cafe amber reading-nook pools radiating out from every library balcony story!
	for lvl in range(6):
		var ly := 730.0 + 21.5 + lvl * 30.0
		for b in range(4):
			var ba := b * 90.0 + rad_to_deg(lvl * 0.22)
			var bp := WorldHelper.spiral_pt(ba, 18.2, ly)
			WorldHelper.add_warm_light_pool(self, bp, Color(1.0, 0.72, 0.30), 4.0, 22.0, true, 2.6, (b % 2 == 0))

	# Circling Celestial Cloud-Whale Leviathan swimming gracefully around the Aurora Sky-Library!
	_whale_pivot = Node3D.new()
	_whale_pivot.position = Vector3(0.0, 774.0, 0.0)
	add_child(_whale_pivot)
	var whale := WorldHelper.add_landmark(_whale_pivot, WHALE, Vector3(44.0, 0.0, -18.0), Vector3(1.15, 1.15, 1.15), Vector3(6.0, 12.0, -8.0), {}, 0.0, true)
	WorldHelper.add_warm_light_pool(whale, Vector3(0.0, 2.0, 6.0), Color(0.42, 0.94, 0.96), 4.2, 26.0, true, 3.2)

	# 2 Biome-Specific Deep Midnight-Aurora Distant Parallax Silhouette Rings (165-400m out!)
	WorldHelper.add_parallax_ring(self, 4, 795.0, 165.0, 260.0, 14, false, 5011)
	WorldHelper.add_parallax_ring(self, 4, 875.0, 270.0, 400.0, 16, true, 5012)

	# =========================================================================
	# ACT 13 (730m -> 792m): Under the Opal Whale-Ribs & First Dream Gravity Bubble
	# =========================================================================
	var cp1 := start_pos + Vector3(-9.5, 2.0, 1.0)
	WorldHelper.add_static_box_platform(self, SHELF, cp1, Vector3(5.2, 0.5, 4.4), Vector3(1.25, 1.0, 1.25), Vector3(0.0, 10.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w5_cp1", 4, cp1, 75.0, true, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp1 + Vector3(-2.1, 0.0, 1.6), 30.0, STYLE, Color(1.0, 0.72, 0.30))

	# Enchanted Warm Floating Candle Clusters casting rich golden pools across the nocturnal Sky-Library!
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

	# High overhead golden lantern catenaries linking the Spiral Library Core to reading balconies (>= 5.5m above shelves!)
	WorldHelper.add_catenary_lanterns(self, Vector3(-13.5, 771.5, 19.5), Vector3(-10.0, 772.5, 14.0), 5, 0.95, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(20.0, 797.5, 14.5), Vector3(14.0, 798.5, 10.5), 5, 0.95, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(18.5, 820.5, -15.5), Vector3(13.0, 821.5, -11.0), 5, 0.95, Color(1.0, 0.66, 0.32))
	WorldHelper.add_catenary_lanterns(self, Vector3(-22.5, 863.0, -9.5), Vector3(-15.5, 864.0, -7.0), 5, 0.95, Color(1.0, 0.66, 0.32))

	# Monumental Levitating Opal Cloud-Whale Rib Cage arching gracefully across the aurora sky
	for i in range(7):
		var a := 72.0 - i * 44.0
		var rpos := WorldHelper.spiral_pt(a, 24.0, 738.0 + i * 26.0)
		WorldHelper.add_landmark(self, RIB, rpos, Vector3(1.5, 1.5, 1.5), Vector3(12.0, a + 90.0, -8.0), {})

	# Drifting golden floating storybook pages across the midnight Sky-Library!
	_spawn_floating_pages(Vector3(0.0, 825.0, 0.0))

	WorldHelper.add_static_box_platform(self, TOME, Vector3(-18.0, 733.5, -20.5), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, 48.0, 0.0), STYLE, audit)
	WorldHelper.add_static_box_platform(self, TOME, Vector3(-24.0, 736.8, -13.0), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, 22.0, 0.0), STYLE, audit)

	# Dream Gravity Bubble #1 (now crystal-clear Fresnel soap-bubble shader!)
	WorldHelper.add_gravity_bubble(self, Vector3(-25.5, 747.5, 4.5), 13.0, audit)
	WorldHelper.add_static_box_platform(self, TOME, Vector3(-26.5, 744.5, 3.5), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, -10.0, 0.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-24.0, 737.5, -13.0), Vector3(-26.5, 745.2, 3.5), 3.4, 4)
	WorldHelper.add_sun_shard(self, "w5_s1", Vector3(-25.5, 753.0, 4.5))

	WorldHelper.add_bounce_pad(self, JELLY, Vector3(-22.5, 752.5, 13.5), 23.0, 2.5, Vector3(2.5, 0.0, 2.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-22.5, 753.5, 13.5), Vector3(-14.5, 765.8, 21.5), 4.2, 4)
	var sh1 := Vector3(-14.5, 765.0, 21.5)
	WorldHelper.add_static_box_platform(self, SHELF, sh1, Vector3(5.2, 0.5, 4.4), Vector3.ONE, Vector3(0.0, 145.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, sh1 + Vector3(-1.6, 0.0, 1.2), 145.0, STYLE, Color(1.0, 0.72, 0.30))

	WorldHelper.add_tether_orb(self, Vector3(-5.0, 773.5, 25.5), audit)
	WorldHelper.add_solar_mote_arc(self, sh1 + Vector3(1.5, 1.0, 1.0), Vector3(-5.0, 773.5, 25.5), 2.5, 3)
	WorldHelper.add_solar_mote_arc(self, Vector3(-5.0, 773.5, 25.5), Vector3(4.5, 778.2, 26.5), 2.5, 3)
	WorldHelper.add_static_box_platform(self, TOME, Vector3(4.5, 777.5, 26.5), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, -82.0, 0.0), STYLE, audit)
	WorldHelper.add_bounce_pad(self, JELLY, Vector3(13.5, 780.5, 23.5), 23.0, 2.5, Vector3(3.0, 0.0, -2.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(13.5, 781.5, 23.5), Vector3(22.0, 791.8, 16.0), 4.2, 4)

	# Checkpoint 2: Astral Reading Balcony (Y = 791m)
	var cp2 := Vector3(22.0, 791.0, 16.0)
	WorldHelper.add_static_box_platform(self, SHELF, cp2, Vector3(5.2, 0.5, 4.4), Vector3(1.2, 1.0, 1.2), Vector3(0.0, -135.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w5_cp2", 4, cp2, -30.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp2 + Vector3(1.8, 0.0, 1.5), -135.0, STYLE, Color(1.0, 0.72, 0.30))

	# =========================================================================
	# ACT 14 (791m -> 858m): Tether-Orb Constellation & Rippling Book Cascade
	# =========================================================================
	WorldHelper.add_tether_orb(self, Vector3(26.5, 799.5, 5.5), audit)
	WorldHelper.add_solar_mote_arc(self, cp2 + Vector3(1.5, 1.2, -2.0), Vector3(26.5, 799.5, 5.5), 2.4, 3)
	WorldHelper.add_tether_orb(self, Vector3(26.0, 809.0, -6.5), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(26.5, 799.5, 5.5), Vector3(26.0, 809.0, -6.5), 2.8, 3)
	var sh2 := Vector3(20.5, 814.0, -17.0)
	WorldHelper.add_static_box_platform(self, SHELF, sh2, Vector3(5.2, 0.5, 4.4), Vector3.ONE, Vector3(0.0, -55.0, 0.0), STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, sh2 + Vector3(1.6, 0.0, -1.2), -55.0, STYLE, Color(1.0, 0.72, 0.30))
	WorldHelper.add_sun_shard(self, "w5_s2", Vector3(26.5, 813.5, -0.5))

	WorldHelper.add_gravity_bubble(self, Vector3(9.0, 824.0, -23.5), 16.0, audit)
	WorldHelper.add_static_box_platform(self, TOME, Vector3(13.5, 819.5, -22.0), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, 68.0, 0.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(13.5, 820.2, -22.0), Vector3(4.0, 828.2, -26.0), 3.6, 4)
	WorldHelper.add_static_box_platform(self, TOME, Vector3(4.0, 827.5, -26.0), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, 86.0, 0.0), STYLE, audit)

	WorldHelper.add_bounce_pad(self, JELLY, Vector3(-6.5, 833.5, -26.0), 23.5, 2.5, Vector3(-3.0, 0.0, 1.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-6.5, 834.5, -26.0), Vector3(-17.5, 849.5, -19.0), 4.2, 4)
	WorldHelper.add_tether_orb(self, Vector3(-17.5, 849.5, -19.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-17.5, 849.5, -19.0), Vector3(-24.5, 857.2, -10.5), 2.6, 3)

	# Checkpoint 3: Leviathan Crown Shelf (Y = 857m)
	var cp3 := Vector3(-24.5, 856.5, -10.5)
	WorldHelper.add_static_box_platform(self, SHELF, cp3, Vector3(5.2, 0.5, 4.4), Vector3(1.2, 1.0, 1.2), Vector3(0.0, 62.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w5_cp3", 4, cp3, 168.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp3 + Vector3(-1.8, 0.0, -1.4), 62.0, STYLE, Color(1.0, 0.72, 0.30))

	# EXPOSED OVER-THE-VOID OVERLOOK #4: Aurora Reading Plank jutting 11.2m over 857m of starry abyss!
	WorldHelper.add_static_box_platform(self, SHELF, cp3 + Vector3(-6.4, 0.15, -2.75), Vector3(5.2, 0.5, 4.4), Vector3(0.25, 0.72, 2.55), Vector3(0.0, 66.8, 0.0), STYLE, [])
	WorldHelper.add_solar_mote_arc(self, cp3 + Vector3(-3.0, 1.0, -1.3), cp3 + Vector3(-10.4, 1.2, -4.45), 1.4, 3)
	WorldHelper.add_world_hint(self, cp3 + Vector3(-10.8, 2.1, -4.65), "CHRONICLE V — THE WHALE'S VIGIL", "857m above home. The Cloud-Whale kept the last aurora alive until you climbed.")

	# =========================================================================
	# ACT 15 (857m -> 920m): Aurora Dream Ascent to the Stratosphere
	# =========================================================================
	WorldHelper.add_static_box_platform(self, TOME, Vector3(-27.0, 860.0, -1.0), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, 5.0, 0.0), STYLE, audit)
	WorldHelper.add_bounce_pad(self, JELLY, Vector3(-25.0, 863.5, 9.0), 24.5, 2.5, Vector3(2.0, 0.0, 3.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-25.0, 864.5, 9.0), Vector3(-17.5, 882.5, 19.5), 4.6, 4)
	WorldHelper.add_gravity_bubble(self, Vector3(-17.0, 876.5, 19.5), 13.0, audit)
	WorldHelper.add_tether_orb(self, Vector3(-17.5, 882.5, 19.5), audit)
	WorldHelper.add_sun_shard(self, "w5_s3", Vector3(-16.5, 889.5, 20.0))

	WorldHelper.add_static_box_platform(self, TOME, Vector3(-7.0, 889.5, 25.5), Vector3(3.8, 0.4, 2.9), Vector3.ONE, Vector3(0.0, -68.0, 0.0), STYLE, audit)
	WorldHelper.add_bounce_pad(self, JELLY, Vector3(3.0, 893.0, 26.5), 25.0, 2.5, Vector3(5.0, 0.0, -2.0), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(3.0, 894.0, 26.5), Vector3(13.5, 910.0, 22.0), 4.6, 4)
	WorldHelper.add_tether_orb(self, Vector3(13.5, 910.0, 22.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(13.5, 910.0, 22.0), Vector3(22.5, 919.8, 14.0), 2.8, 4)

	# World 5 -> World 6 Crown of the Sun Ascension Gate (Y = 919m)
	var gate_pos := Vector3(22.5, 919.0, 14.0)
	WorldHelper.add_static_box_platform(self, SHELF, gate_pos, Vector3(5.4, 0.6, 4.6), Vector3(1.3, 1.0, 1.3), Vector3(0.0, -145.0, 0.0), STYLE, audit, "world_gate_pad")
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(1.5, 0.0, -3.5), Vector3.ONE, Vector3(0.0, -25.0, 0.0), STYLE)
	return gate_pos


func _spawn_floating_pages(center: Vector3) -> void:
	## Drifting golden storybook pages fluttering gently through the Cloud-Whale Library!
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


func _process(delta: float) -> void:
	if is_instance_valid(_whale_pivot):
		_whale_pivot.rotate_y(delta * 0.14)
