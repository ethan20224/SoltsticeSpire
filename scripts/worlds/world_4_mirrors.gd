extends Node3D
class_name World4Mirrors
## World 4: The Shattered Mirror Gallery (540m -> 730m)
## Signature Twist: Jump/Dash Phase-Swap Crystal Platforms (Rose <-> Cyan),
## True Momentum Drop-Portals (fall into floor portal -> fling across spire!),
## Meteor-Slam Cracked Skylights, Dash-Prism Chains, & Triple-Portal Kaleidoscope Climax!

const FRAME := "res://assets/models/world4_mirrors/gilded_portal_frame.glb"
const MARBLE := "res://assets/models/world4_mirrors/marble_stair_arch.glb"
const PRISM := "res://assets/models/world4_mirrors/crystal_prism.glb"
const MIRROR := "res://assets/models/world4_mirrors/mirror_wall_panel.glb"
const SHATTER := "res://assets/models/world4_mirrors/shatter_pane.glb"
const GATE := "res://assets/models/common/world_gate.glb"
const CORE := "res://assets/models/tower_cores/w4_mirror_core.glb"
const CLUSTER := "res://assets/models/dressing/w4_gallery_cluster.glb"

const STYLE := {
	"top": Color(0.95, 0.78, 0.94),
	"top_blend": 0.14,
	"rim": Color(1.0, 0.74, 0.94),
	"rim_s": 0.38,
	"shadow": Color(0.28, 0.14, 0.42),
	"tex": "veined_marble",
	"tex_scale": 0.30,
	"tex_blend": 0.74,
}


func build(start_pos: Vector3, audit: Array) -> Vector3:
	WorldHelper.add_landmark(self, CORE, Vector3(0.0, 540.0, 0.0), Vector3.ONE, Vector3.ZERO, STYLE)
	for lvl in range(5):
		var ly := 540.0 + 37.0 + lvl * 36.0
		for f in range(4):
			var fa := f * 90.0 + (45.0 if lvl % 2 else 0.0)
			var fp := WorldHelper.spiral_pt(fa, 18.0, ly)
			var wcol := Color(1.0, 0.72, 0.34) if (lvl + f) % 2 == 0 else Color(0.96, 0.56, 0.88)
			WorldHelper.add_warm_light_pool(self, fp, wcol, 3.8, 22.0, true, 2.6, (f % 2 == 0))

	WorldHelper.add_parallax_ring(self, 3, 605.0, 160.0, 255.0, 14, false, 4011)
	WorldHelper.add_parallax_ring(self, 3, 685.0, 265.0, 395.0, 16, true, 4012)

	# =========================================================================
	# ACT 10 (540m -> 594m): Meteor Skylight, Phase-Swap Glass Corridor & Drop-Portal Fling!
	# =========================================================================
	var cp1 := start_pos + Vector3(8.5, 2.5, -2.5)
	WorldHelper.add_static_box_platform(self, MARBLE, cp1, Vector3(4.8, 0.5, 4.8), Vector3(1.3, 1.0, 1.3), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w4_cp1", 3, cp1, -55.0, true, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp1 + Vector3(-2.1, 0.0, -2.0), 40.0, STYLE, Color(1.0, 0.76, 0.38))

	WorldHelper.add_landmark(self, "res://assets/models/scenery/rose_window_arch.glb", Vector3(24.0, 566.0, -18.0), Vector3(1.4, 1.4, 1.4), Vector3(0.0, 32.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, "res://assets/models/scenery/rose_window_arch.glb", Vector3(-18.0, 622.0, 24.0), Vector3(1.6, 1.6, 1.6), Vector3(0.0, -45.0, 0.0), STYLE)
	WorldHelper.add_landmark(self, "res://assets/models/scenery/rose_window_arch.glb", Vector3(14.0, 692.0, 16.0), Vector3(1.5, 1.5, 1.5), Vector3(0.0, -20.0, 0.0), STYLE)
	WorldHelper.add_warm_light_pool(self, Vector3(26.0, 562.0, -4.0), Color(1.0, 0.74, 0.38), 4.2, 24.0, true, 2.8)
	WorldHelper.add_warm_light_pool(self, Vector3(19.5, 547.0, 16.5), Color(1.0, 0.76, 0.40), 3.8, 20.0, true, 2.4)

	WorldHelper.add_catenary_lanterns(self, Vector3(23.5, 566.0, -9.5), Vector3(16.0, 567.5, -7.0), 5, 0.95, Color(1.0, 0.68, 0.34))
	WorldHelper.add_catenary_lanterns(self, Vector3(-20.0, 601.5, 14.5), Vector3(-13.5, 603.5, 10.5), 5, 0.95, Color(1.0, 0.68, 0.34))
	WorldHelper.add_catenary_lanterns(self, Vector3(24.0, 633.5, -3.5), Vector3(16.5, 635.5, -2.5), 5, 0.95, Color(1.0, 0.68, 0.34))
	WorldHelper.add_catenary_lanterns(self, Vector3(-24.0, 668.5, -5.5), Vector3(-16.5, 670.5, -4.0), 5, 0.95, Color(1.0, 0.68, 0.34))

	for i in range(8):
		var a := i * 45.0
		var pos := WorldHelper.spiral_pt(a, 38.0, 560.0 + i * 21.0)
		var pr := WorldHelper.add_landmark(self, PRISM, pos, Vector3(2.0, 2.4, 2.0), Vector3(14.0, a, 12.0), {}, 0.0, true)
		WorldHelper.apply_crystal_shader(pr, Color(0.88, 0.78, 1.0, 0.86))

	# Cracked Mirror Skylight (Meteor-Slam launches straight up onto the Escher Balcony!)
	var p1_in := Vector3(19.5, 543.0, 16.5)
	WorldHelper.add_static_box_platform(self, MARBLE, p1_in, Vector3(4.6, 0.5, 4.6), Vector3.ONE, Vector3(0.0, -45.0, 0.0), STYLE, audit)
	WorldHelper.add_meteor_trigger(self, Vector3(25.0, 545.2, 6.0), "skylight", 27.5, Vector3(1.0, 0.0, -8.5), "", audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(25.0, 546.5, 6.0), Vector3(26.0, 558.5, -10.5), 4.6, 5)

	var balc1 := Vector3(26.0, 557.5, -10.5)
	WorldHelper.add_static_box_platform(self, MARBLE, balc1, Vector3(4.6, 0.5, 4.6), Vector3(1.2, 1.0, 1.2), Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, balc1 + Vector3(1.9, 0.0, -1.6), -90.0, STYLE, Color(1.0, 0.76, 0.38))

	# SIGNATURE MECHANIC: JUMP/DASH PHASE-SWAP CRYSTAL CORRIDOR (Rose <-> Cyan!)
	WorldHelper.add_world_hint(self, balc1 + Vector3(-1.5, 2.6, -2.5), "PHASE-SWAP GLASS!", "Every {jump} or {dash} flips ROSE <-> CYAN solid! Plan each hop!")
	var phase_run := [
		Vector3(21.5, 560.5, -18.0),
		Vector3(14.5, 563.5, -23.5),
		Vector3(6.0, 566.5, -26.5),
		Vector3(-2.5, 569.5, -27.0),
	]
	for idx in range(phase_run.size()):
		WorldHelper.add_phase_platform(self, phase_run[idx], idx % 2, Vector3(4.2, 0.42, 4.2), idx * 15.0, audit)
	WorldHelper.add_solar_mote_arc(self, Vector3(21.5, 561.2, -18.0), Vector3(-2.5, 570.2, -27.0), 3.0, 5)

	var balc2 := Vector3(-11.0, 572.5, -24.5)
	WorldHelper.add_static_box_platform(self, MARBLE, balc2, Vector3(4.6, 0.5, 4.6), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, balc2 + Vector3(-1.5, 0.0, -1.6), 45.0, STYLE, Color(1.0, 0.76, 0.38))

	# SUN-SHARD TRIAL #4: Kaleidoscope Phase-Ring Sprint (awards w4_s1!)
	WorldHelper.add_shard_trial(self, balc2 + Vector3(0.0, 0.0, 1.2), "w4_s1", "MIRROR PHASE TRIAL", PackedVector3Array([
		Vector3(-16.5, 576.0, -22.5),
		Vector3(-21.5, 578.0, -19.0),
		Vector3(-25.0, 581.5, -14.5),
		Vector3(-26.0, 585.5, -10.0),
	]), 11.5)

	WorldHelper.add_wall_run(self, MIRROR, Vector3(-21.0, 576.5, -21.0), Vector3(0.0, 42.0, 0.0), Vector3(9.0, 4.4, 0.9), false, 0, audit)

	# TRUE MOMENTUM DROP-PORTAL! Climb onto high dive ledge -> Sky-Dive 12m DOWN into horizontal floor portal -> rocket diagonally across to CP2!
	var dive_ledge := Vector3(-26.0, 583.0, -10.0)
	WorldHelper.add_static_box_platform(self, MARBLE, dive_ledge, Vector3(4.6, 0.5, 4.6), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	WorldHelper.add_world_hint(self, dive_ledge + Vector3(0.0, 2.5, 2.2), "MOMENTUM DROP-PORTAL!", "Sky-Dive ({slide}) DOWN into the floor vortex -> SLINGSHOT out the wall!")
	var drop_in := Vector3(-26.0, 571.0, -3.5)
	var drop_out := Vector3(-25.5, 594.0, 5.5)
	WorldHelper.add_portal_pair(self, drop_in, 175.0, drop_out, 162.0, 23.0, audit, true, true, 0.44)
	WorldHelper.add_solar_mote_arc(self, drop_out + Vector3(1.0, 1.5, 1.5), Vector3(-22.0, 594.2, 16.0), 2.6, 3)

	# Checkpoint 2: Escher Hallway Terrace (Y = 593.5m)
	var cp2 := Vector3(-22.0, 593.5, 16.0)
	WorldHelper.add_static_box_platform(self, MARBLE, cp2, Vector3(4.8, 0.5, 4.8), Vector3(1.3, 1.0, 1.3), Vector3(0.0, -35.0, 0.0), STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w4_cp2", 3, cp2, 130.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp2 + Vector3(-2.1, 0.0, 1.9), -35.0, STYLE, Color(1.0, 0.76, 0.38))

	# PRO SHORTCUT #4 + FLOW-EXPRESS BRIDGE
	var razor := WorldHelper.add_static_box_platform(self, MARBLE, Vector3(-28.0, 594.2, 22.0), Vector3(4.6, 0.5, 4.6), Vector3(0.25, 0.9, 2.7), Vector3(0.0, -45.0, 0.0), STYLE, [])
	WorldHelper.apply_crystal_shader(razor, Color(0.95, 0.78, 1.0, 0.88))
	WorldHelper.add_flow_express(self, Vector3(-28.0, 594.4, 22.0), -45.0, Vector3(3.4, 0.32, 11.5))
	var secret_in := Vector3(-33.0, 595.0, 27.0)
	WorldHelper.add_static_box_platform(self, MARBLE, secret_in, Vector3(4.6, 0.5, 4.6), Vector3(0.65, 1.0, 0.65), Vector3(0.0, -45.0, 0.0), STYLE, [])
	var secret_out := Vector3(23.5, 626.2, 1.5)
	WorldHelper.add_portal_pair(self, secret_in, 135.0, secret_out, 180.0, 18.5, [], true, false)
	WorldHelper.add_shortcut_beacon(self, Vector3(26.5, 625.5, -3.5), 0.0, "RAZOR-BEAM WARP!", "MIRROR GALLERY PRO SKIP")

	# =========================================================================
	# ACT 11 (593.5m -> 660.5m): Twin Mirror Wall + Dash-Prism Chain & Pacing-Pressure Phase Sprint!
	# =========================================================================
	WorldHelper.add_phase_platform(self, Vector3(-14.5, 596.5, 22.5), 0, Vector3(4.2, 0.42, 4.2), 0.0, audit)
	WorldHelper.add_wall_run(self, MIRROR, Vector3(-5.0, 599.2, 28.5), Vector3(0.0, -10.0, 0.0), Vector3(9.0, 4.4, 0.9), false, 0, audit)
	WorldHelper.add_dash_prism(self, Vector3(2.5, 603.2, 26.5), Color(0.98, 0.46, 0.84), 10.6, audit)
	WorldHelper.add_sun_shard(self, "w4_s2", Vector3(2.5, 607.2, 26.5))
	WorldHelper.add_wall_run(self, MIRROR, Vector3(9.5, 604.2, 24.5), Vector3(0.0, 18.0, 0.0), Vector3(9.0, 4.4, 0.9), false, 0, audit)

	# Second Momentum Drop-Portal slingshotting up to Balcony 2!
	var p3_ledge := Vector3(17.5, 610.5, 21.0)
	WorldHelper.add_static_box_platform(self, MARBLE, p3_ledge, Vector3(4.6, 0.5, 4.6), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	var p3_in := Vector3(22.5, 603.5, 14.5)
	var p3_out := Vector3(26.0, 626.0, 8.0)
	WorldHelper.add_portal_pair(self, p3_in, -45.0, p3_out, -8.0, 22.5, audit, true, true, 0.42)

	WorldHelper.add_static_box_platform(self, MARBLE, Vector3(26.5, 625.5, -3.5), Vector3(4.6, 0.5, 4.6), Vector3(1.15, 1.0, 1.15), Vector3.ZERO, STYLE, audit)

	# PACING PRESSURE CORRIDOR: Fast-Shattering Crystal Panes (0.58s) alternating with Phase-Swap Slabs!
	WorldHelper.add_world_hint(self, Vector3(25.0, 628.5, -8.5), "SHATTER-PHASE SPRINT!", "Glass cracks in 0.5s — keep chaining jumps without stopping!")
	WorldHelper.add_crumbling_tile(self, SHATTER, Vector3(24.0, 628.8, -12.0), 0.58, true, Vector3(0.0, -25.0, 0.0), audit)
	WorldHelper.add_phase_platform(self, Vector3(18.5, 632.0, -19.5), 1, Vector3(4.2, 0.42, 4.2), -42.0, audit)
	WorldHelper.add_crumbling_tile(self, SHATTER, Vector3(11.0, 635.2, -24.5), 0.58, true, Vector3(0.0, -60.0, 0.0), audit)
	WorldHelper.add_phase_platform(self, Vector3(2.5, 638.5, -26.5), 0, Vector3(4.2, 0.42, 4.2), -78.0, audit)

	var p4_in := Vector3(-6.5, 641.5, -26.0)
	WorldHelper.add_static_box_platform(self, MARBLE, p4_in, Vector3(4.6, 0.5, 4.6), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	var p4_out := Vector3(-21.0, 661.0, -16.0)
	WorldHelper.add_portal_pair(self, p4_in, 75.0, p4_out, 138.0, 18.0, audit, true, false)

	# Checkpoint 3: Prism Rotunda (Y = 660.5m)
	var cp3 := Vector3(-26.5, 660.5, -6.0)
	WorldHelper.add_static_box_platform(self, MARBLE, cp3, Vector3(4.8, 0.5, 4.8), Vector3(1.3, 1.0, 1.3), Vector3.ZERO, STYLE, audit, "checkpoint_pad")
	WorldHelper.add_shrine(self, "w4_cp3", 3, cp3, 175.0, false, false, audit)
	WorldHelper.add_dressing_cluster(self, CLUSTER, cp3 + Vector3(-2.1, 0.0, -1.9), 80.0, STYLE, Color(1.0, 0.76, 0.38))

	# Exposed Crystal Overlook #3
	var glass_overlook := WorldHelper.add_static_box_platform(self, MARBLE, cp3 + Vector3(-6.8, 0.15, -1.55), Vector3(4.6, 0.5, 4.6), Vector3(0.26, 0.65, 2.45), Vector3(0.0, 77.2, 0.0), STYLE, [])
	WorldHelper.apply_crystal_shader(glass_overlook, Color(0.92, 0.80, 1.0, 0.78))
	WorldHelper.add_solar_mote_arc(self, cp3 + Vector3(-3.2, 1.0, -0.75), cp3 + Vector3(-11.0, 1.2, -2.5), 1.4, 3)
	WorldHelper.add_world_hint(self, cp3 + Vector3(-11.4, 2.1, -2.6), "CHRONICLE IV — THE SHATTERED LENS", "Look straight through the glass — 661m of open sky down to the glowing valley city.")

	# =========================================================================
	# ACT 12 (660.5m -> 728m): WORLD 4 CLIMAX — TRIPLE-PORTAL KALEIDOSCOPE SLINGSHOT CASCADE!
	# =========================================================================
	WorldHelper.add_world_hint(self, Vector3(-27.5, 663.5, 1.0), "CLIMAX · KALEIDOSCOPE CASCADE!", "Chain 3 Momentum Portals + Dash-Prisms non-stop into the Aurora Night!")
	WorldHelper.add_wall_run(self, MIRROR, Vector3(-29.0, 663.2, 4.0), Vector3(0.0, 82.0, 0.0), Vector3(9.0, 4.4, 0.9), false, 0, audit)
	WorldHelper.add_phase_platform(self, Vector3(-23.5, 667.5, 13.5), 0, Vector3(4.2, 0.42, 4.2), 0.0, audit)
	WorldHelper.add_phase_platform(self, Vector3(-16.5, 670.8, 20.5), 1, Vector3(4.2, 0.42, 4.2), 0.0, audit)

	# Portal Cascade #1
	var p5_in := Vector3(-8.5, 673.8, 25.0)
	WorldHelper.add_static_box_platform(self, MARBLE, p5_in, Vector3(4.6, 0.5, 4.6), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	var p5_out := Vector3(10.0, 692.0, 24.0)
	WorldHelper.add_portal_pair(self, p5_in, -70.0, p5_out, -58.0, 20.0, audit, true, false)
	WorldHelper.add_dash_prism(self, Vector3(18.0, 695.5, 18.5), Color(0.98, 0.46, 0.84), 10.6, audit)

	# Portal Cascade #2
	var p6_in := Vector3(24.0, 697.5, 10.5)
	WorldHelper.add_static_box_platform(self, MARBLE, p6_in, Vector3(4.6, 0.5, 4.6), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	var p6_out := Vector3(26.5, 712.0, -2.5)
	WorldHelper.add_portal_pair(self, p6_in, -12.0, p6_out, 15.0, 20.0, audit, true, false)
	WorldHelper.add_dash_prism(self, Vector3(23.5, 715.5, -11.5), Color(0.42, 0.96, 1.0), 10.6, audit)
	WorldHelper.add_sun_shard(self, "w4_s3", Vector3(23.5, 719.5, -11.5))

	# Portal Cascade #3 -> Heroic launch straight onto World 5 Ascension Gate!
	var p7_in := Vector3(18.5, 714.5, -19.0)
	WorldHelper.add_static_box_platform(self, MARBLE, p7_in, Vector3(4.6, 0.5, 4.6), Vector3.ONE, Vector3.ZERO, STYLE, audit)
	var p7_out := Vector3(9.5, 728.5, -25.0)
	WorldHelper.add_portal_pair(self, p7_in, 42.0, p7_out, 78.0, 17.5, audit, true, false)
	WorldHelper.add_solar_mote_arc(self, p7_out + Vector3(-1.5, 1.5, -0.5), Vector3(0.0, 728.8, -27.0), 2.2, 3)

	# World 4 -> World 5 Cloud-Whale Library Ascension Gate (Y = 728m)
	var gate_pos := Vector3(0.0, 728.0, -27.0)
	WorldHelper.add_static_box_platform(self, MARBLE, gate_pos, Vector3(5.0, 0.6, 5.0), Vector3(1.35, 1.0, 1.35), Vector3.ZERO, STYLE, audit, "world_gate_pad")
	WorldHelper.add_landmark(self, GATE, gate_pos + Vector3(-3.5, 0.0, 0.0), Vector3.ONE, Vector3(0.0, 85.0, 0.0), STYLE)
	return gate_pos
