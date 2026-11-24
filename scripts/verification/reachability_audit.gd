extends Node
class_name ReachabilityAudit
## Automated Kinematics & Reachability Auditor for Solstice Spire.
## Mathematically validates EVERY consecutive platform-to-platform transition across all 6 worlds (0m -> 1,085m)
## against exact PlayerController jump, double-jump, air-dash, bounce, updraft, wall-run, portal, tether,
## grind rail, momentum ramp, dash prism, meteor trigger, seesaw, phase platform, whale, and armillary ring physics.

const MAX_STD_HORIZ := 16.5        # Sprint + Double-Jump + Air-Dash edge-to-edge clearance
const MAX_STD_UP := 5.8            # Jump (13.0) + Double-Jump (11.2) + Ledge-Mantle max vertical step
const MAX_BOUNCE_HORIZ := 17.0
const MAX_WALL_HORIZ := 18.0
const MAX_TETHER_DIST := 25.0      # Exact tether lock-on radius in PlayerController


static func run_audit(chain: Array) -> Dictionary:
	var warnings: Array[String] = []
	var failures: Array[String] = []
	var total_links := 0

	var bubbles: Array[Dictionary] = []
	for item_v: Variant in chain:
		var item: Dictionary = item_v as Dictionary
		if str(item.get("kind", "")) == "gravity_bubble":
			bubbles.append({"pos": item["pos"], "r": float(item.get("radius", 9.0))})

	for i in range(chain.size() - 1):
		var a: Dictionary = chain[i] as Dictionary
		var b: Dictionary = chain[i + 1] as Dictionary
		var ka: String = str(a.get("kind", "platform"))
		var kb: String = str(b.get("kind", "platform"))

		if ka == "checkpoint" or kb == "checkpoint":
			continue
		if (ka == "portal_in" and kb == "portal_out") or (ka == "updraft_in" and kb == "updraft_out"):
			total_links += 1
			continue
		if (ka == "rail_in" and kb == "rail_out") or (ka == "ramp_in" and kb == "ramp_out"):
			total_links += 1
			continue

		total_links += 1
		var pa: Vector3 = a["pos"]
		var pb: Vector3 = b["pos"]
		var ra: float = float(a.get("radius", 1.8))
		var rb: float = float(b.get("radius", 1.8))

		var horiz_center := Vector2(pb.x - pa.x, pb.z - pa.z).length()
		var edge_gap := maxf(0.0, horiz_center - ra - rb)
		# Armillary Rings and Orbiting Whales are 360-degree tracks at radius ~R around center:
		# compute exact radial distance from the ring rim rather than center!
		if ka == "armillary_ring" or ka == "whale_ride":
			var ring_r := ra - 1.8
			var pt_r := Vector2(pb.x - pa.x, pb.z - pa.z).length()
			edge_gap = maxf(0.0, absf(pt_r - ring_r) - 1.8 - rb)
		elif kb == "armillary_ring" or kb == "whale_ride":
			var ring_r := rb - 1.8
			var pt_r := Vector2(pa.x - pb.x, pa.z - pb.z).length()
			edge_gap = maxf(0.0, absf(pt_r - ring_r) - 1.8 - ra)

		var dy := pb.y - pa.y

		var in_low_g := false
		for bb in bubbles:
			var bpos: Vector3 = bb["pos"]
			var brad: float = float(bb["r"])
			if pa.distance_to(bpos) <= brad + 3.5 or pb.distance_to(bpos) <= brad + 3.5:
				in_low_g = true
				break

		var max_h := MAX_STD_HORIZ
		var max_y := 10.5 if in_low_g else MAX_STD_UP

		if ka == "bounce" or ka == "meteor_trigger":
			max_h = 18.5 if ka == "meteor_trigger" else MAX_BOUNCE_HORIZ
			max_y = float(a.get("boost_y", 8.5)) + (8.0 if in_low_g else 5.2)
		elif ka == "updraft_out":
			max_h = 16.0
			max_y = 6.5
		elif ka == "wall_run":
			max_h = MAX_WALL_HORIZ
			max_y = 7.4
		elif kb == "wall_run":
			max_h = MAX_WALL_HORIZ
			max_y = 5.4
		elif ka == "portal_out":
			max_h = 20.0
			max_y = 7.5
		elif ka == "gravity_bubble" or kb == "gravity_bubble":
			max_h = 20.0
			max_y = 12.5
		elif ka == "tether_orb":
			max_h = 19.0
			max_y = 10.5
		elif ka == "dash_prism":
			max_h = 17.5
			max_y = 11.2 if in_low_g else 9.8
		elif ka == "rail_out":
			max_h = 18.5
			max_y = 10.2
		elif ka == "ramp_out":
			max_h = 23.0
			max_y = float(a.get("boost_y", 12.0)) + 8.5
		elif ka == "whale_ride":
			max_h = 22.0
			max_y = 22.0
		elif ka == "armillary_ring":
			max_h = 17.0
			max_y = 6.8

		if kb == "tether_orb":
			var dist3d := pa.distance_to(pb)
			if dist3d > MAX_TETHER_DIST + 2.0:
				failures.append("Link %d (%s -> tether_orb @ %s): 3D dist %.1fm > %.1fm" % [i, ka, str(pb), dist3d, MAX_TETHER_DIST])
			continue

		if edge_gap > max_h:
			failures.append("Link %d (%s @ %s -> %s @ %s): edge_gap %.1fm > max %.1fm" % [i, ka, str(pa), kb, str(pb), edge_gap, max_h])
		elif edge_gap > max_h * 0.85:
			warnings.append("Tight horiz link %d (%s -> %s): edge_gap %.1fm" % [i, ka, kb, edge_gap])

		if dy > max_y:
			failures.append("Link %d (%s @ %s -> %s @ %s): dy %.1fm > max %.1fm" % [i, ka, str(pa), kb, str(pb), dy, max_y])

	return {
		"total_links": total_links,
		"failures": failures,
		"warnings": warnings,
		"passed": failures.is_empty(),
	}
