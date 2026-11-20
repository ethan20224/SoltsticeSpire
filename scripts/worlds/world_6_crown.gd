extends Node3D
class_name World6Crown
## World 6: The Crown of the Sun (920m -> 1,090m)
## Cosmic stratosphere, soaring brass-and-obsidian Observatory Crown Core with orrery planetary arms,
## delicate open-work Solar Armillary Rings, warm glowing Solar Braziers, and the Summit Crown Sanctuary!

const MONOLITH := "res://assets/models/world6_crown/obsidian_monolith.glb"
const DAIS := "res://assets/models/world6_crown/obsidian_dais.glb"
const RING := "res://assets/models/world6_crown/solar_ring.glb"
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

var _orbit_rings: Array[Node3D] = []


func build(start_pos: Vector3, audit: Array) -> Vector3:
	# =========================================================================
	# CENTRAL SOLSTICE SPIRE CORE (World 6: Celestial Brass & Obsidian Observatory!)
	# Tapers directly into the underside of the Summit Crown Sanctuary at Y = 1,084.5m!
	# =========================================================================
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 920.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	# Warm glowing orrery sun-planet pools & halos along the Observatory Spire!
	for lvl in range(4):
		var ly := 920.0 + 30.0 + lvl * 34.0
		for k in range(4):
			var ka := k * 90.0 + rad_to_deg(lvl * 0.55)
			var kp := WorldHelper.spiral_pt(ka, 20.4, ly)
			WorldHelper.add_warm_light_pool(self, kp, Color(1.0, 0.72, 0.28), 4.0, 22.0, true, 2.6, (k % 2 == 0))

	# 2 Biome-Specific Cosmic Twilight-Gold Distant Parallax Silhouette Rings (170-410m out!)
	WorldHelper.add_parallax_ring(self, 5, 980.0, 170.0, 265.0, 14, false, 6011)
	WorldHelper.add_parallax_ring(self, 5, 1055.0, 275.0, 410.0, 16, true, 6012)

	# =========================================================================
	# ACT 16 (920m -> 978m): Stratosphere Entry & Obsidian Wall-Run Ring
	# =========================================================================
	var cp1 := start_pos + Vector3(3.5, 2.5, -8.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, cp1, 3.0, 0.8, Vector3(1.35, 1.0, 1.35), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w6_cp1", 5, cp1, 5.0, true, false, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, cp1 + Vector3(2.4, 0.0, 1.6), 0.0, STYLE, Color(1.0, 0.74, 0.28))

	# Delicate Open-Work Filigreed Astronomical Armillary Rings (zero chunky baton tube!)
	var r1 := WorldHelper.add_landmark(self, RING, Vector3(0.0, 965.0, 0.0), Vector3(2.2, 2.2, 2.2), Vector3(14.0, 0.0, 10.0), {}, 0.0, true)
	var r2 := WorldHelper.add_landmark(self, RING, Vector3(0.0, 1025.0, 0.0), Vector3(2.35, 2.35, 2.35), Vector3(-16.0, 45.0, -12.0), {}, 0.0, true)
	var r3 := WorldHelper.add_landmark(self, RING, Vector3(0.0, 1072.0, 0.0), Vector3(1.65, 1.65, 1.65), Vector3(8.0, 90.0, 14.0), {}, 0.0, true)
	_orbit_rings = [r1, r2, r3]

	# High overhead celestial lantern garlands linking key obsidian daises to the Observatory Core!
	WorldHelper.add_catenary_lanterns(self, Vector3(-24.0, 983.5, 6.0), Vector3(-16.0, 985.0, 4.0), 5, 0.95, Color(1.0, 0.68, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(9.5, 1040.5, -21.5), Vector3(6.5, 1042.0, -14.5), 5, 0.95, Color(1.0, 0.68, 0.30))
	WorldHelper.add_catenary_lanterns(self, Vector3(-19.5, 1068.0, -1.5), Vector3(-12.5, 1069.5, -1.0), 5, 0.95, Color(1.0, 0.68, 0.30))

	WorldHelper.add_wall_run(self, MONOLITH, Vector3(28.5, 924.4, -4.5), Vector3(0.0, -82.0, 0.0), Vector3(9.4, 4.6, 1.0), false, 0, audit)
	WorldHelper.add_crumbling_tile(self, SHATTER, Vector3(23.5, 929.5, -14.5), 0.80, true, Vector3.ZERO, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(23.5, 930.2, -14.5), Vector3(14.0, 938.5, -22.5), 3.0, 4)
	WorldHelper.add_tether_orb(self, Vector3(14.0, 938.5, -22.5), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(14.0, 938.5, -22.5), Vector3(3.5, 943.2, -26.5), 2.4, 3)
	WorldHelper.add_sun_shard(self, "w6_s1", Vector3(14.0, 943.5, -22.5))

	var p1_in := Vector3(3.5, 942.5, -26.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, p1_in, 3.0, 0.8, Vector3(1.05, 1.0, 1.05), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, p1_in + Vector3(1.8, 0.0, -1.6), 0.0, STYLE, Color(1.0, 0.74, 0.28))
	var p1_out := Vector3(-14.0, 963.0, -22.0)
	WorldHelper.add_portal_pair(self, p1_in, 82.0, p1_out, 125.0, 17.5, audit)
	WorldHelper.add_solar_mote_arc(self, p1_out + Vector3(-1.5, 1.5, 1.0), Vector3(-22.5, 963.2, -13.5), 2.2, 3)

	var d2 := Vector3(-22.5, 962.5, -13.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, d2, 3.0, 0.8, Vector3(1.1, 1.0, 1.1), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, d2 + Vector3(-1.9, 0.0, -1.5), 45.0, STYLE, Color(1.0, 0.74, 0.28))
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-26.5, 965.5, -4.0), 23.5, 2.4, Vector3(0.0, 0.0, 3.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-26.5, 966.5, -4.0), Vector3(-26.0, 976.8, 6.5), 4.0, 4)

	# Checkpoint 2: Solar Perigee Dais (Y = 976m)
	var cp2 := Vector3(-26.0, 976.0, 6.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, cp2, 3.0, 0.8, Vector3(1.35, 1.0, 1.35), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w6_cp2", 5, cp2, 145.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, cp2 + Vector3(-2.3, 0.0, 1.5), 90.0, STYLE, Color(1.0, 0.74, 0.28))

	# =========================================================================
	# ACT 17 (976m -> 1,034m): The Golden Remix Gauntlet
	# =========================================================================
	WorldHelper.add_wall_run(self, MONOLITH, Vector3(-22.5, 978.6, 17.5), Vector3(0.0, 54.0, 0.0), Vector3(9.4, 4.6, 1.0), false, 0, audit)
	WorldHelper.add_spinning_gear(self, Vector3(-13.0, 983.5, 24.5), 40.0, 1.05, audit)
	WorldHelper.add_crumbling_tile(self, SHATTER, Vector3(-3.0, 987.0, 26.5), 0.80, true, Vector3.ZERO, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-3.0, 987.8, 26.5), Vector3(11.0, 1001.0, 23.5), 3.6, 4)

	WorldHelper.add_gravity_bubble(self, Vector3(8.5, 998.0, 24.5), 11.5, audit)
	WorldHelper.add_tether_orb(self, Vector3(11.0, 1001.0, 23.5), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(11.0, 1001.0, 23.5), Vector3(20.5, 1007.2, 17.5), 2.5, 3)
	WorldHelper.add_sun_shard(self, "w6_s2", Vector3(8.5, 1007.5, 24.5))

	var d3 := Vector3(20.5, 1006.5, 17.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, d3, 3.0, 0.8, Vector3(1.05, 1.0, 1.05), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, d3 + Vector3(1.8, 0.0, 1.5), -45.0, STYLE, Color(1.0, 0.74, 0.28))
	WorldHelper.add_wall_run(self, MONOLITH, Vector3(28.5, 1011.0, 7.5), Vector3(0.0, -78.0, 0.0), Vector3(9.4, 4.6, 1.0), false, 0, audit)
	WorldHelper.add_bounce_pad(self, JELLY, Vector3(26.0, 1014.5, -3.5), 24.5, 2.5, Vector3(-1.5, 0.0, -3.5), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(26.0, 1015.5, -3.5), Vector3(19.0, 1029.5, -16.0), 4.5, 4)
	WorldHelper.add_tether_orb(self, Vector3(19.0, 1029.5, -16.0), audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(19.0, 1029.5, -16.0), Vector3(10.5, 1033.8, -23.5), 2.4, 3)

	# Checkpoint 3: Last Threshold before the Summit Crown (Y = 1,033m)
	var cp3 := Vector3(10.5, 1033.0, -23.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, cp3, 3.0, 0.8, Vector3(1.35, 1.0, 1.35), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w6_cp3", 5, cp3, 68.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, cp3 + Vector3(2.2, 0.0, -1.6), -120.0, STYLE, Color(1.0, 0.74, 0.28))

	# =========================================================================
	# ACT 18 (1,033m -> 1,085m): Final Zenith Leap to The Crown of the Sun!
	# =========================================================================
	WorldHelper.add_folding_tile(self, Vector3(1.5, 1036.2, -26.5), Vector3(0.0, 88.0, 0.0), audit)
	WorldHelper.add_crumbling_tile(self, SHATTER, Vector3(-7.0, 1039.5, -25.5), 0.80, true, Vector3.ZERO, audit)
	WorldHelper.add_wall_run(self, MONOLITH, Vector3(-18.5, 1042.5, -21.5), Vector3(0.0, 44.0, 0.0), Vector3(9.4, 4.6, 1.0), false, 0, audit)
	WorldHelper.add_bounce_pad(self, VENT, Vector3(-24.5, 1047.5, -11.5), 26.6, 2.5, Vector3(3.0, 0.0, 5.2), STYLE, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(-24.5, 1048.5, -11.5), Vector3(-21.0, 1060.8, -1.5), 4.6, 5)

	var pf_in := Vector3(-21.0, 1060.0, -1.5)
	WorldHelper.add_static_cyl_platform(self, DAIS, pf_in, 3.0, 0.8, Vector3(1.1, 1.0, 1.1), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, BRAZIER, pf_in + Vector3(-1.8, 0.0, 1.6), 30.0, STYLE, Color(1.0, 0.74, 0.28))
	var pf_out := Vector3(-14.5, 1078.0, 0.0)
	WorldHelper.add_portal_pair(self, pf_in, -85.0, pf_out, -90.0, 16.5, audit)
	WorldHelper.add_solar_mote_arc(self, pf_out + Vector3(1.5, 1.5, 0.0), Vector3(0.0, 1085.5, 0.0), 3.6, 5)
	WorldHelper.add_sun_shard(self, "w6_s3", Vector3(-9.5, 1086.5, 0.0))

	# THE SUMMIT CROWN SANCTUARY OVERLOOK (Centered at (0, 1084.5, 0))
	var summit_pos := Vector3(0.0, 1084.5, 0.0)
	WorldHelper.add_static_cyl_platform(self, SUMMIT, summit_pos, 9.7, 1.2, Vector3.ONE, Vector3.ZERO, STYLE, audit, "summit_crown")
	WorldHelper.add_shrine(self, "summit_crown", 5, summit_pos + Vector3(0.0, 0.38, 0.0), 0.0, false, true, audit)

	# Radiant Golden Summit Sun Light + Warm Perimeter Brazier Light Pools & Bokeh Halos!
	WorldHelper.add_warm_light_pool(self, summit_pos + Vector3(0.0, 10.5, 0.0), Color(1.0, 0.84, 0.44), 6.5, 42.0, true, 5.2)
	for i in range(4):
		var ba := i * 90.0 + 45.0
		var bp := summit_pos + WorldHelper.spiral_pt(ba, 8.2, 1.6)
		WorldHelper.add_warm_light_pool(self, bp, Color(1.0, 0.72, 0.28), 3.6, 14.0, true, 2.0)

	return summit_pos


func _process(delta: float) -> void:
	for i in range(_orbit_rings.size()):
		var r := _orbit_rings[i]
		if is_instance_valid(r):
			var spd := (0.14 if i % 2 == 0 else -0.18) * (1.0 + i * 0.15)
			r.rotate_y(delta * spd)
