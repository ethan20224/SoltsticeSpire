extends Node3D
class_name DockedAirship
## 'The Dawnbreaker' — Stylized Sky-Airship that glides in and docks beside the Awakening Terrace!
## Features live opening-cutscene docking glide + animated lowering gangplank, buoyant sky-current bobbing,
## live spinning rear brass propeller, glowing amber cabin lanterns, and walkable deck + gangplank colliders.

const AIRSHIP_GLB := "res://assets/models/scenery/sky_airship.glb"

var _ship_pivot: Node3D
var _propeller: Node3D
var _gangplank_pivot: Node3D
var _t: float = 0.0
var _docking_t: float = 1.0


func _ready() -> void:
	add_to_group("docked_airship")
	_build_ship()
	_build_walkable_colliders()
	set_docking_progress(1.0)


func _build_ship() -> void:
	_ship_pivot = Node3D.new()
	_ship_pivot.name = "AirshipPivot"
	add_child(_ship_pivot)

	_gangplank_pivot = Node3D.new()
	_gangplank_pivot.name = "GangplankHinge"
	_gangplank_pivot.position = Vector3(1.35, 0.04, -0.9)
	_ship_pivot.add_child(_gangplank_pivot)

	if ResourceLoader.exists(AIRSHIP_GLB):
		var vis := WorldHelper.load_glb(AIRSHIP_GLB)
		vis.name = "AirshipVisual"
		_style_airship_parts(vis)
		_ship_pivot.add_child(vis)
		_propeller = vis.find_child("PropellerPivot", true, false) as Node3D

		# Reparent gangplank boards, posts & ropes onto the starboard hinge so it lowers smoothly on dock!
		var plank_nodes: Array[Node3D] = []
		_collect_gangplank_nodes(vis, plank_nodes)
		for pn in plank_nodes:
			var local_xf := _ship_pivot.global_transform.affine_inverse() * pn.global_transform if is_inside_tree() else pn.transform
			var parent_n := pn.get_parent()
			if parent_n:
				parent_n.remove_child(pn)
			_gangplank_pivot.add_child(pn)
			pn.transform = Transform3D(local_xf.basis, local_xf.origin - _gangplank_pivot.position)

	# Warm golden lantern glow at the bow & boarding deck
	WorldHelper.add_warm_light_pool(_ship_pivot, Vector3(0.0, 2.0, -3.55), Color(1.0, 0.74, 0.30), 3.6, 13.0, true, 1.85, true)
	WorldHelper.add_lamp_halo(_ship_pivot, Vector3(1.25, 1.0, 2.05), Color(1.0, 0.68, 0.24), 1.4, 0.65)
	WorldHelper.add_lamp_halo(_ship_pivot, Vector3(-1.25, 1.0, 2.05), Color(1.0, 0.68, 0.24), 1.4, 0.65)


func _style_airship_parts(node: Node) -> void:
	## Applies smooth cream/crimson fabric to the dirigible balloon & fins,
	## warm mahogany wood planks ONLY to hull/deck/cabin/gangplank, and burnished brass to metalwork!
	if node is MeshInstance3D:
		var nm: String = node.name
		if nm.begins_with("Balloon") or nm.begins_with("Fin") or nm.begins_with("Rudder"):
			WorldHelper.enhance_stylized_materials(
				node,
				Color.WHITE, 0.0,
				Color(1.0, 0.90, 0.62), 0.28,
				Color(0.22, 0.24, 0.44),
				"plush_felt", 1.2, 0.22, 0.0
			)
		elif nm.begins_with("Prop") or nm.begins_with("Nose") or nm.begins_with("SternCap") or nm.begins_with("Bowsprit") or nm.begins_with("Helm") or nm.begins_with("PlankPost") or nm.begins_with("CabinBrass"):
			WorldHelper.enhance_stylized_materials(
				node,
				Color.WHITE, 0.0,
				Color(1.0, 0.88, 0.52), 0.34,
				Color(0.22, 0.20, 0.38),
				"hammered_brass", 1.1, 0.42, 0.0
			)
		else:
			WorldHelper.enhance_stylized_materials(
				node,
				Color(1.0, 0.95, 0.84), 0.0,
				Color(1.0, 0.86, 0.54), 0.26,
				Color(0.20, 0.22, 0.40),
				"wood_planks", 0.45, 0.44, 0.0
			)
		return
	for ch in node.get_children():
		_style_airship_parts(ch)


func _collect_gangplank_nodes(node: Node, out: Array[Node3D]) -> void:
	if node is Node3D:
		var nm: String = node.name
		if nm.begins_with("Gangplank") or nm.begins_with("PlankPost") or nm.begins_with("PlankRope"):
			out.append(node as Node3D)
			return
	for ch in node.get_children():
		_collect_gangplank_nodes(ch, out)


func _build_walkable_colliders() -> void:
	# Static walkable gangplank & main wooden boat deck so players spawn aboard and walk right off!
	var sb := StaticBody3D.new()
	sb.name = "AirshipWalkCollider"
	add_child(sb)

	var plank_col := CollisionShape3D.new()
	var plank_bx := BoxShape3D.new()
	plank_bx.size = Vector3(5.4, 0.28, 1.85)
	plank_col.shape = plank_bx
	plank_col.position = Vector3(3.4, -0.02, -0.9)
	sb.add_child(plank_col)

	var deck_col := CollisionShape3D.new()
	var deck_bx := BoxShape3D.new()
	deck_bx.size = Vector3(3.5, 0.35, 8.2)
	deck_col.shape = deck_bx
	deck_col.position = Vector3(0.0, -0.02, -0.4)
	sb.add_child(deck_col)


func set_docking_progress(t: float) -> void:
	## 0.0 = gliding in through the western morning clouds; 1.0 = docked & gangplank lowered onto terrace!
	_docking_t = clampf(t, 0.0, 1.0)
	_apply_docking_transform()


func get_boarding_spawn() -> Dictionary:
	## Returns world-space spawn position & camera yaw right on The Dawnbreaker's open foredeck,
	## facing straight down the wooden gangplank onto the mossy Awakening Terrace & Spire!
	var local_spawn := Vector3(-0.15, 0.16, -1.10)
	var local_look := Vector3(6.5, 0.16, -1.05)
	var world_pos := global_transform * local_spawn
	var world_look := global_transform * local_look
	var dir := (world_look - world_pos)
	dir.y = 0.0
	dir = dir.normalized()
	var yaw := atan2(-dir.x, -dir.z)
	return {"pos": world_pos, "yaw": yaw}


func _apply_docking_transform() -> void:
	if _ship_pivot == null:
		return
	var approach_t := clampf(_docking_t / 0.82, 0.0, 1.0)
	var ease_in := 1.0 - pow(1.0 - approach_t, 3.0)
	var rem := 1.0 - ease_in
	var bob_y := sin(_t * 1.15) * 0.18 * ease_in
	var bob_rz := sin(_t * 0.82 + 0.6) * 0.024 * ease_in
	var bob_rx := cos(_t * 0.68) * 0.012 * ease_in

	_ship_pivot.position = Vector3(-22.0 * rem, 8.5 * rem + bob_y, 15.0 * rem)
	_ship_pivot.rotation = Vector3(-0.08 * rem + bob_rx, 0.24 * rem, 0.11 * rem + bob_rz)

	if _gangplank_pivot:
		var plank_t := smoothstep(0.72, 1.0, _docking_t)
		_gangplank_pivot.rotation.z = lerpf(1.16, 0.0, plank_t)


func _process(delta: float) -> void:
	_t += delta
	_apply_docking_transform()
	if _propeller and is_instance_valid(_propeller):
		var spin_rate := lerpf(22.0, 9.5, _docking_t)
		_propeller.rotate_z(delta * spin_rate)
