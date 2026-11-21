extends Node
class_name WorldHelper
## Shared modular factory for placing Blender-sculpted .glb platforms, custom tactile shaders,
## exact aligned collisions, surreal mechanics, landmarks, MultiMesh dressing, and reachability audit waypoints.

static var _glb_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}
static var _mat_cache: Dictionary = {}
static var _mesh_cache: Dictionary = {}
static var _tactile_shader: Shader
static var _crystal_shader: Shader
static var _paper_shader: Shader
static var _halo_shader: Shader
static var _leaf_card_shader: Shader
static var _pip_face_shader: Shader
static var _silhouette_shader: Shader
static var _cloud_puff_shader: Shader
static var _grass_shader: Shader
static var _halo_quad: QuadMesh


static func clear_caches() -> void:
	_glb_cache.clear()
	_tex_cache.clear()
	_mat_cache.clear()
	_mesh_cache.clear()
	_tactile_shader = null
	_crystal_shader = null
	_paper_shader = null
	_halo_shader = null
	_leaf_card_shader = null
	_pip_face_shader = null
	_silhouette_shader = null
	_cloud_puff_shader = null
	_grass_shader = null
	_halo_quad = null


static func load_glb(path: String) -> Node3D:
	if not _glb_cache.has(path):
		if ResourceLoader.exists(path):
			_glb_cache[path] = load(path)
		else:
			push_error("WorldHelper: Missing GLB %s" % path)
			return Node3D.new()
	return (_glb_cache[path] as PackedScene).instantiate()


static func _extract_first_mesh(path: String) -> Mesh:
	if _mesh_cache.has(path):
		return _mesh_cache[path]
	var inst := load_glb(path)
	var found := _find_mesh_rec(inst)
	inst.free()
	_mesh_cache[path] = found
	return found


static func _find_mesh_rec(n: Node) -> Mesh:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		return (n as MeshInstance3D).mesh
	for ch in n.get_children():
		var m := _find_mesh_rec(ch)
		if m:
			return m
	return null


static func _get_pbr_tex(tex_set_name: String) -> Dictionary:
	if _tex_cache.has(tex_set_name):
		return _tex_cache[tex_set_name]
	var base := "res://assets/textures/%s" % tex_set_name
	var d := {}
	if ResourceLoader.exists(base + "_albedo.png"):
		d["albedo"] = load(base + "_albedo.png")
		d["normal"] = load(base + "_normal.png")
		d["roughness"] = load(base + "_roughness.png")
	_tex_cache[tex_set_name] = d
	return d


static func _get_single_tex(filename: String) -> Texture2D:
	var key := "__single__" + filename
	if _tex_cache.has(key):
		return _tex_cache[key]
	var path := "res://assets/textures/%s" % filename
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[key] = t
	return t


static func _get_tactile_shader() -> Shader:
	if not _tactile_shader:
		_tactile_shader = load("res://assets/shaders/stylized_tactile.gdshader")
	return _tactile_shader


static func _get_crystal_shader() -> Shader:
	if not _crystal_shader:
		_crystal_shader = load("res://assets/shaders/iridescent_crystal.gdshader")
	return _crystal_shader


static func _get_paper_shader() -> Shader:
	if not _paper_shader:
		_paper_shader = load("res://assets/shaders/paper_unfold.gdshader")
	return _paper_shader


static func _get_halo_shader() -> Shader:
	if not _halo_shader:
		_halo_shader = load("res://assets/shaders/lamp_halo.gdshader")
	return _halo_shader


static func _get_leaf_card_shader() -> Shader:
	if not _leaf_card_shader:
		_leaf_card_shader = load("res://assets/shaders/leaf_card.gdshader")
	return _leaf_card_shader


static func _get_pip_face_shader() -> Shader:
	if not _pip_face_shader:
		_pip_face_shader = load("res://assets/shaders/pip_void_face.gdshader")
	return _pip_face_shader


static func _get_silhouette_shader() -> Shader:
	if not _silhouette_shader:
		_silhouette_shader = load("res://assets/shaders/distant_silhouette.gdshader")
	return _silhouette_shader


static func _get_cloud_puff_shader() -> Shader:
	if not _cloud_puff_shader:
		_cloud_puff_shader = load("res://assets/shaders/stylized_cloud_puff.gdshader")
	return _cloud_puff_shader


static func _get_grass_shader() -> Shader:
	if not _grass_shader:
		_grass_shader = load("res://assets/shaders/lush_grass.gdshader")
	return _grass_shader


static func disable_shadows(root: Node) -> void:
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for ch in root.get_children():
		disable_shadows(ch)


static func enhance_stylized_materials(root: Node, top_col: Color, top_blend: float, rim_col: Color,
		rim_strength: float = 0.28, shadow_tint: Color = Color(0.24, 0.22, 0.42),
		tex_set: String = "", tex_scale: float = 0.28, tex_blend: float = 0.68, wetness: float = 0.0) -> void:
	## Upgrades imported StandardMaterial3D surfaces on a GLB to our custom textured Triplanar PBR shader
	## using shared GPU-cached ShaderMaterials (zero duplicate shader states, smart shadow-casting culling!).
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		if mi.mesh:
			# Disable shadow casting for tiny sub-props (< 0.65m bounding diagonal) to save shadow-pass GPU ms!
			var diag := mi.mesh.get_aabb().size.length()
			if diag < 0.72:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			for s in range(mi.mesh.get_surface_count()):
				var src_mat := mi.get_active_material(s)
				if src_mat is StandardMaterial3D:
					var sm := src_mat as StandardMaterial3D
					var mname := sm.resource_name.to_lower()

					# Alpha-scissor stylized Ghibli tree silhouette leaf cards!
					if mname.contains("leafcard"):
						var lkey := "__leaf_card__"
						var lsh: ShaderMaterial
						if _mat_cache.has(lkey):
							lsh = _mat_cache[lkey]
						else:
							lsh = ShaderMaterial.new()
							lsh.shader = _get_leaf_card_shader()
							var ltex := _get_single_tex("leaf_card_alpha.png")
							if ltex:
								lsh.set_shader_parameter("leaf_tex", ltex)
							_mat_cache[lkey] = lsh
						mi.set_surface_override_material(s, lsh)
						mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
						continue

					# Keep emissive lamp bulbs, flames, furnaces, shoji windows saturated warm amber & shadow-free!
					# Darken base albedo_color so external sun/omni lights never add diffuse white on top of emission!
					if sm.emission_enabled and sm.emission_energy_multiplier >= 0.45:
						mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
						if mname.contains("rose") or mname.contains("ruby") or mname.contains("sapph") or mname.contains("ameth") or mname.contains("glassbot") or mname.contains("glassmid") or mname.contains("glasstop") or mname.contains("opal") or mname.contains("aurora"):
							var jkey := "__jewel_glass_v2__|%s|%.2f" % [sm.albedo_color.to_html(false), sm.emission_energy_multiplier]
							var jmat: StandardMaterial3D
							if _mat_cache.has(jkey):
								jmat = _mat_cache[jkey]
							else:
								jmat = StandardMaterial3D.new()
								jmat.albedo_color = Color(sm.albedo_color.r * 0.24, sm.albedo_color.g * 0.24, sm.albedo_color.b * 0.24)
								jmat.roughness = 0.16
								jmat.emission_enabled = true
								jmat.emission = sm.emission
								jmat.emission_energy_multiplier = clampf(sm.emission_energy_multiplier, 0.55, 1.15)
								_mat_cache[jkey] = jmat
							mi.set_surface_override_material(s, jmat)
							continue
						var is_furnace := mname.contains("furnace") or mname.contains("ember")
						var gkey := "__warm_bulb_v2__|%s" % ["f" if is_furnace else "a"]
						var gmat: StandardMaterial3D
						if _mat_cache.has(gkey):
							gmat = _mat_cache[gkey]
						else:
							gmat = StandardMaterial3D.new()
							gmat.albedo_color = Color(0.28, 0.12, 0.04) if is_furnace else Color(0.32, 0.18, 0.06)
							gmat.roughness = 0.24
							gmat.emission_enabled = true
							gmat.emission = Color(1.0, 0.46, 0.10) if is_furnace else Color(1.0, 0.64, 0.24)
							gmat.emission_energy_multiplier = 1.28
							_mat_cache[gkey] = gmat
						mi.set_surface_override_material(s, gmat)
						continue

					var chosen_tex := tex_set
					var local_norm := 0.46
					var local_rough := sm.roughness
					var local_blend := tex_blend
					var local_sheen := 0.0
					var local_macro := 0.14
					var local_grain := 0.012
					var local_wet := wetness
					var is_flower_petal := mname.contains("petal") or mname.contains("blossom") or mname.contains("pollen") or mname.contains("bloom") or mname.contains("flower")
					var is_delicate_col := is_flower_petal or mname.contains("ribbon") or mname.contains("tassel") or mname.contains("flame") or mname.contains("ember") or mname.contains("furnace") or mname.contains("bookspine") or mname.contains("jelly")
					var is_jewel_tint := mname.contains("sapph") or mname.contains("rose") or mname.contains("ruby") or mname.contains("ameth") or mname.contains("aurora")

					if is_jewel_tint:
						mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
						var jkey2 := "__jewel_glass_v3__|%s|%.2f" % [sm.albedo_color.to_html(false), sm.emission_energy_multiplier]
						var jmat2: StandardMaterial3D
						if _mat_cache.has(jkey2):
							jmat2 = _mat_cache[jkey2]
						else:
							jmat2 = StandardMaterial3D.new()
							jmat2.albedo_color = Color(sm.albedo_color.r * 0.34, sm.albedo_color.g * 0.34, sm.albedo_color.b * 0.34, 0.88)
							jmat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
							jmat2.roughness = 0.12
							jmat2.metallic = 0.10
							jmat2.emission_enabled = true
							jmat2.emission = sm.emission if sm.emission_enabled else sm.albedo_color
							jmat2.emission_energy_multiplier = clampf(maxf(sm.emission_energy_multiplier, 0.52), 0.50, 1.15)
							_mat_cache[jkey2] = jmat2
						mi.set_surface_override_material(s, jmat2)
						continue

					if mname.contains("glass") or mname.contains("stained") or mname.contains("pane") or mname.contains("crystal"):
						chosen_tex = ""
						local_rough = 0.12
						mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					elif is_flower_petal:
						chosen_tex = ""
						local_norm = 0.0
						local_rough = maxf(sm.roughness, 0.52)
						local_sheen = 0.34
						local_macro = 0.05
						local_grain = 0.004
						local_wet = 0.0
					elif mname.contains("ceramicroof"):
						chosen_tex = "terracotta_tile"
						local_norm = 0.30
						local_rough = 0.38
						local_blend = 0.32
					elif mname.contains("moss") or mname.contains("leaf") or mname.contains("canopy") or mname.contains("fern") or mname.contains("ivy") or mname.contains("tuft") or mname.contains("bush"):
						chosen_tex = "lush_moss"
						local_norm = 0.22
						local_rough = maxf(sm.roughness, 0.88)  # Pure matte velvety Ghibli foliage, ZERO wet pickle shine!
						local_blend = 0.62
						local_sheen = 0.28
						local_macro = 0.24
						local_grain = 0.006  # Zero sandpaper mottling!
						local_wet = 0.0
					elif mname.contains("terra") or mname.contains("pot") or mname.contains("urn"):
						chosen_tex = "terracotta_tile"
						local_norm = 0.48
					elif mname.contains("wood") or mname.contains("bark") or mname.contains("bamboo") or mname.contains("cedar") or mname.contains("walnut"):
						chosen_tex = "wood_planks"
						local_norm = 0.14
						local_blend = 0.42
					elif mname.contains("brass") or mname.contains("gold") or mname.contains("copper") or mname.contains("bronze") or sm.metallic >= 0.65:
						chosen_tex = "hammered_brass"
						local_norm = 0.56  # Crisp hammered peen dimples + patina relief!
						local_blend = 0.60
					elif mname.contains("marble") or mname.contains("lilac"):
						chosen_tex = "veined_marble"
						local_norm = 0.18
						local_blend = 0.42
					elif mname.contains("paper") or mname.contains("crane"):
						chosen_tex = "washi_paper"
						local_norm = 0.26
						local_blend = 0.48
					elif mname.contains("obs"):
						chosen_tex = "obsidian_fluted"
						local_norm = 0.42
						local_blend = 0.54

					var eff_top := top_blend if (sm.metallic < 0.5 and chosen_tex != "" and not mname.contains("ceramicroof") and not is_delicate_col) else 0.0
					var key := "%s|%.2f|%.2f|%s|%s|%.2f|%.2f|%s|%.2f|%.2f|%.2f|%.2f" % [
						sm.albedo_color.to_html(false), local_rough, sm.metallic,
						chosen_tex, top_col.to_html(false), eff_top, rim_strength,
						rim_col.to_html(false), tex_scale, local_macro, local_wet,
						sm.emission_energy_multiplier if sm.emission_enabled else 0.0
					]
					var sh: ShaderMaterial
					if _mat_cache.has(key):
						sh = _mat_cache[key]
					else:
						sh = ShaderMaterial.new()
						sh.shader = _get_tactile_shader()
						sh.set_shader_parameter("albedo_color", sm.albedo_color)
						sh.set_shader_parameter("roughness_val", local_rough)
						sh.set_shader_parameter("metallic_val", sm.metallic)
						sh.set_shader_parameter("top_color", top_col)
						sh.set_shader_parameter("top_blend", eff_top)
						sh.set_shader_parameter("rim_color", rim_col)
						sh.set_shader_parameter("rim_strength", rim_strength)
						sh.set_shader_parameter("shadow_warmth", shadow_tint)
						sh.set_shader_parameter("plush_sheen", local_sheen)
						sh.set_shader_parameter("macro_var_strength", local_macro)
						sh.set_shader_parameter("grain_strength", local_grain)
						sh.set_shader_parameter("wetness", local_wet)
						if chosen_tex != "":
							var pbr := _get_pbr_tex(chosen_tex)
							if not pbr.is_empty():
								sh.set_shader_parameter("use_textures", true)
								sh.set_shader_parameter("albedo_tex", pbr["albedo"])
								sh.set_shader_parameter("normal_tex", pbr["normal"])
								sh.set_shader_parameter("roughness_tex", pbr["roughness"])
								sh.set_shader_parameter("tex_scale", tex_scale)
								sh.set_shader_parameter("tex_blend", local_blend)
								sh.set_shader_parameter("normal_strength", local_norm)
						if sm.emission_enabled:
							sh.set_shader_parameter("emission_color", sm.emission)
							sh.set_shader_parameter("emission_strength", sm.emission_energy_multiplier)
						_mat_cache[key] = sh
					mi.set_surface_override_material(s, sh)
	for ch in root.get_children():
		enhance_stylized_materials(ch, top_col, top_blend, rim_col, rim_strength, shadow_tint, tex_set, tex_scale, tex_blend, wetness)


static func apply_plush_character_materials(root: Node, rim_col: Color = Color(1.0, 0.93, 0.78)) -> void:
	## Gives playable explorers cozy tactile plush felt weave, velvety rim sheen, Pip's gradient void face,
	## and Vesper's illustrated veined moth wings (all cached in _mat_cache so zero material RID leaks!).
	var felt := _get_pbr_tex("plush_felt")
	var brass := _get_pbr_tex("hammered_brass")
	_apply_plush_rec(root, felt, brass, rim_col)


static func _apply_plush_rec(n: Node, felt: Dictionary, brass: Dictionary, rim_col: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			if mi.mesh.get_aabb().size.length() < 0.28:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for s in range(mi.mesh.get_surface_count()):
				var src := mi.get_active_material(s)
				if src is StandardMaterial3D:
					var sm := src as StandardMaterial3D
					var mname := sm.resource_name.to_lower()

					# Pip's rich twilight-indigo to warm ember-bounce void face!
					if mname.contains("pipvoidface"):
						var pkey := "__pip_void_face__"
						var psh: ShaderMaterial
						if _mat_cache.has(pkey):
							psh = _mat_cache[pkey]
						else:
							psh = ShaderMaterial.new()
							psh.shader = _get_pip_face_shader()
							_mat_cache[pkey] = psh
						mi.set_surface_override_material(s, psh)
						continue

					# Vesper's illustrated UV-mapped gold-veined moth wings!
					if mname.contains("vesperwingpattern"):
						var wkey := "__vesper_wing_pat__"
						var wmat: StandardMaterial3D
						if _mat_cache.has(wkey):
							wmat = _mat_cache[wkey]
						else:
							wmat = StandardMaterial3D.new()
							wmat.albedo_texture = _get_single_tex("vesper_wing_albedo.png")
							wmat.roughness = 0.72
							wmat.rim_enabled = true
							wmat.rim = 0.35
							wmat.rim_tint = 0.65
							_mat_cache[wkey] = wmat
						mi.set_surface_override_material(s, wmat)
						continue

					# Keep shiny eyes, catchlights, rosy glows, flames, and cyan optical glows crisp!
					if sm.emission_enabled or mname.contains("eye") or mname.contains("catch") or mname.contains("nose"):
						continue

					var key := "__plush__|%s|%.2f|%.2f|%s" % [
						sm.albedo_color.to_html(false), sm.roughness, sm.metallic, rim_col.to_html(false)
					]
					var sh: ShaderMaterial
					if _mat_cache.has(key):
						sh = _mat_cache[key]
					else:
						sh = ShaderMaterial.new()
						sh.shader = _get_tactile_shader()
						sh.set_shader_parameter("albedo_color", sm.albedo_color)
						sh.set_shader_parameter("roughness_val", sm.roughness)
						sh.set_shader_parameter("metallic_val", sm.metallic)
						sh.set_shader_parameter("rim_color", rim_col)
						sh.set_shader_parameter("rim_strength", 0.32)
						sh.set_shader_parameter("shadow_warmth", Color(0.32, 0.20, 0.42))
						sh.set_shader_parameter("stylize_ramp", 0.30)
						sh.set_shader_parameter("macro_var_strength", 0.04)
						if sm.metallic >= 0.55 and not brass.is_empty():
							sh.set_shader_parameter("use_textures", true)
							sh.set_shader_parameter("albedo_tex", brass["albedo"])
							sh.set_shader_parameter("normal_tex", brass["normal"])
							sh.set_shader_parameter("roughness_tex", brass["roughness"])
							sh.set_shader_parameter("tex_scale", 1.8)
							sh.set_shader_parameter("tex_blend", 0.40)
							sh.set_shader_parameter("normal_strength", 0.58)
						elif not felt.is_empty():
							sh.set_shader_parameter("use_textures", true)
							sh.set_shader_parameter("albedo_tex", felt["albedo"])
							sh.set_shader_parameter("normal_tex", felt["normal"])
							sh.set_shader_parameter("roughness_tex", felt["roughness"])
							sh.set_shader_parameter("tex_scale", 2.6)
							sh.set_shader_parameter("tex_blend", 0.34)
							sh.set_shader_parameter("normal_strength", 0.62)
							sh.set_shader_parameter("plush_sheen", 0.85 if sm.roughness > 0.45 else 0.25)
						_mat_cache[key] = sh
					mi.set_surface_override_material(s, sh)
	for ch in n.get_children():
		_apply_plush_rec(ch, felt, brass, rim_col)


static func set_detail_cull_range(root: Node, max_dist: float = 155.0) -> void:
	## Keeps Apple M2 running at silky 55-60+ FPS by cleanly fading foreground props past max_dist!
	if root is GeometryInstance3D:
		var gi := root as GeometryInstance3D
		gi.visibility_range_end = max_dist
		gi.visibility_range_end_margin = 18.0 if max_dist > 0.0 else 0.0
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF if max_dist > 0.0 else GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	for ch in root.get_children():
		set_detail_cull_range(ch, max_dist)


static func add_lamp_halo(parent: Node3D, pos: Vector3, col: Color = Color(1.0, 0.72, 0.36),
		size: float = 1.9, intensity: float = 0.78) -> MeshInstance3D:
	## Soft additive radial bokeh halo billboard around practical warm lamps, candles, and furnaces!
	if not _halo_quad:
		_halo_quad = QuadMesh.new()
		_halo_quad.size = Vector2(1.0, 1.0)
	var key := "__halo__|%s|%.2f" % [col.to_html(false), intensity]
	var sh: ShaderMaterial
	if _mat_cache.has(key):
		sh = _mat_cache[key]
	else:
		sh = ShaderMaterial.new()
		sh.shader = _get_halo_shader()
		sh.set_shader_parameter("glow_color", col)
		sh.set_shader_parameter("intensity", intensity)
		_mat_cache[key] = sh
	var mi := MeshInstance3D.new()
	mi.mesh = _halo_quad
	mi.material_override = sh
	mi.position = pos
	mi.scale = Vector3.ONE * size
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 185.0
	mi.visibility_range_end_margin = 25.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mi)
	return mi


static func add_lamp_post(parent: Node3D, pos: Vector3, rot_y_deg: float = 0.0,
		light_col: Color = Color(1.0, 0.72, 0.34), energy: float = 3.8, light_range: float = 9.5) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees = Vector3(0.0, rot_y_deg, 0.0)
	var mesh := load_glb("res://assets/models/scenery/pendant_lamp_post.glb")
	enhance_stylized_materials(mesh, Color.WHITE, 0.0, Color(1.0, 0.86, 0.52), 0.30, Color(0.24, 0.18, 0.32), "hammered_brass", 0.8, 0.62)
	set_detail_cull_range(mesh, 165.0)
	holder.add_child(mesh)

	# Soft additive warm bokeh halo billboard right around the amber globe!
	add_lamp_halo(holder, Vector3(0.84, 2.94, 0.0), light_col, 1.95, 0.78)

	# Rich Dalbit-Cafe practical golden light pool visibly illuminating grass & stone below!
	var omni := OmniLight3D.new()
	omni.position = Vector3(0.84, 2.45, 0.0)
	omni.light_color = light_col
	omni.light_energy = energy
	omni.omni_range = light_range
	omni.omni_attenuation = 1.20
	omni.shadow_enabled = false
	omni.distance_fade_enabled = true
	omni.distance_fade_begin = 52.0
	omni.distance_fade_length = 18.0
	holder.add_child(omni)
	parent.add_child(holder)
	return holder


static func add_warm_light_pool(parent: Node3D, pos: Vector3, col: Color, energy: float = 3.6,
		radius: float = 16.0, with_halo: bool = false, halo_size: float = 2.6, spawn_omni: bool = true) -> OmniLight3D:
	if with_halo:
		add_lamp_halo(parent, pos, col, halo_size, 0.72)
	if not spawn_omni:
		return null
	var omni := OmniLight3D.new()
	omni.position = pos
	omni.light_color = col
	omni.light_energy = energy
	omni.omni_range = radius
	omni.omni_attenuation = 1.25
	omni.shadow_enabled = false
	omni.distance_fade_enabled = true
	omni.distance_fade_begin = 56.0
	omni.distance_fade_length = 20.0
	parent.add_child(omni)
	return omni


static func _extract_baked_mesh(path: String) -> ArrayMesh:
	var key := "__baked__" + path
	if _mesh_cache.has(key):
		return _mesh_cache[key] as ArrayMesh
	var inst := load_glb(path)
	var out := ArrayMesh.new()
	_bake_meshes_rec(inst, Transform3D.IDENTITY, out)
	inst.free()
	_mesh_cache[key] = out
	return out


static func _bake_meshes_rec(n: Node, parent_xform: Transform3D, out: ArrayMesh) -> void:
	var xform := parent_xform
	if n is Node3D:
		xform = parent_xform * (n as Node3D).transform
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			var nrm_basis := xform.basis.inverse().transposed()
			for s in range(mi.mesh.get_surface_count()):
				var mdt := MeshDataTool.new()
				var err := mdt.create_from_surface(mi.mesh, s)
				if err == OK:
					for vi in range(mdt.get_vertex_count()):
						mdt.set_vertex(vi, xform * mdt.get_vertex(vi))
						mdt.set_vertex_normal(vi, (nrm_basis * mdt.get_vertex_normal(vi)).normalized())
					mdt.commit_to_surface(out)
					var surf_idx := out.get_surface_count() - 1
					var mat := mi.get_active_material(s)
					if mat:
						out.surface_set_material(surf_idx, mat)
	for ch in n.get_children():
		_bake_meshes_rec(ch, xform, out)


static func _apply_lush_grass_surfaces(mesh: ArrayMesh, is_wildflower: bool = false) -> void:
	var applied_key := "__lush_applied__%s" % str(mesh.get_instance_id())
	if _mat_cache.has(applied_key):
		return
	for s in range(mesh.get_surface_count()):
		var src_mat := mesh.surface_get_material(s)
		var mname := src_mat.resource_name.to_lower() if src_mat else ""
		var base_col := Color(0.20, 0.54, 0.20)
		var rough := 0.88
		if src_mat is StandardMaterial3D:
			var sm := src_mat as StandardMaterial3D
			base_col = sm.albedo_color
			rough = sm.roughness

		var is_foliage := mname.contains("grass") or mname.contains("clover") or mname.contains("stem") or mname.contains("leaf") or mname == ""
		var key := "__lush_grass__|%s|%s|%s" % [mname, base_col.to_html(false), "wf" if is_wildflower else "gr"]
		var sh: ShaderMaterial
		if _mat_cache.has(key):
			sh = _mat_cache[key] as ShaderMaterial
		else:
			sh = ShaderMaterial.new()
			sh.shader = _get_grass_shader()
			if is_foliage:
				var is_clover := mname.contains("clover")
				sh.set_shader_parameter("root_color", Color(0.06, 0.28, 0.13) if is_clover else Color(0.08, 0.35, 0.14))
				sh.set_shader_parameter("tip_color", Color(0.26, 0.66, 0.24) if is_clover else Color(0.46, 0.82, 0.22))
				sh.set_shader_parameter("roughness_val", 0.88)
				sh.set_shader_parameter("rim_color", Color(1.0, 0.94, 0.66))
				sh.set_shader_parameter("rim_strength", 0.30)
			else:
				sh.set_shader_parameter("root_color", base_col.darkened(0.08))
				sh.set_shader_parameter("tip_color", base_col.lightened(0.14))
				sh.set_shader_parameter("roughness_val", maxf(rough, 0.55))
				sh.set_shader_parameter("rim_color", Color(1.0, 0.96, 0.84))
				sh.set_shader_parameter("rim_strength", 0.26)
			sh.set_shader_parameter("wind_strength", 0.075 if is_wildflower else 0.088)
			_mat_cache[key] = sh
		mesh.surface_set_material(s, sh)
	_mat_cache[applied_key] = true


static func add_grass_tuft_rim(parent: Node3D, center: Vector3, inner_r: float, outer_r: float,
		count: int = 44, seed_val: int = 101) -> MultiMeshInstance3D:
	## Single batched MultiMeshInstance3D scattering interactive wind-swaying clover & buttercup tufts around lawn edges!
	var mesh := _extract_baked_mesh("res://assets/models/dressing/grass_tuft.glb")
	if mesh.get_surface_count() == 0:
		return null
	_apply_lush_grass_surfaces(mesh, false)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in range(count):
		var ang := (float(i) / float(count)) * TAU + rng.randf_range(-0.14, 0.14)
		var rad := rng.randf_range(inner_r, outer_r)
		var sc := rng.randf_range(0.75, 1.38)
		var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(sc, sc * rng.randf_range(0.85, 1.25), sc))
		var p := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		mm.set_instance_transform(i, Transform3D(b, p))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.position = center
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 95.0
	mmi.visibility_range_end_margin = 16.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mmi)
	return mmi


static func add_lush_grass_carpet(parent: Node3D, center: Vector3, max_radius: float,
		count: int = 180, seed_val: int = 201, exclude_center_r: float = 0.0) -> MultiMeshInstance3D:
	## Scatters rich golden-emerald wind-swaying grass_tuft.glb clusters across the full walkable lawn
	## with Astro Bot player-bending lush_grass.gdshader!
	var mesh := _extract_baked_mesh("res://assets/models/dressing/grass_tuft.glb")
	if mesh.get_surface_count() == 0:
		return null
	_apply_lush_grass_surfaces(mesh, false)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var r_min_sq := exclude_center_r * exclude_center_r
	var r_max_sq := max_radius * max_radius
	for i in range(count):
		var ang := rng.randf_range(0.0, TAU)
		var rad := sqrt(rng.randf_range(r_min_sq, r_max_sq))
		var edge_t := clampf(rad / maxf(max_radius, 0.01), 0.0, 1.0)
		var sc := lerpf(rng.randf_range(0.55, 0.90), rng.randf_range(0.88, 1.38), edge_t)
		var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		b = b.rotated(Vector3.RIGHT, rng.randf_range(-0.08, 0.08)).scaled(Vector3(sc, sc * rng.randf_range(0.82, 1.24), sc))
		var p := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		mm.set_instance_transform(i, Transform3D(b, p))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.position = center
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 95.0
	mmi.visibility_range_end_margin = 16.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mmi)
	return mmi


static func add_wildflower_scatter(parent: Node3D, center: Vector3, inner_r: float, outer_r: float,
		count: int = 18, seed_val: int = 301) -> MultiMeshInstance3D:
	## Scatters colorful buttercup, daisy, pink-bloom & clover clusters while preserving every petal color!
	var mesh := _extract_baked_mesh("res://assets/models/dressing/wildflower_cluster.glb")
	if mesh.get_surface_count() == 0:
		return null
	_apply_lush_grass_surfaces(mesh, true)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var r_min_sq := inner_r * inner_r
	var r_max_sq := outer_r * outer_r
	for i in range(count):
		var ang := (float(i) / float(count)) * TAU + rng.randf_range(-0.24, 0.24)
		var rad := sqrt(rng.randf_range(r_min_sq, r_max_sq))
		var sc := rng.randf_range(0.85, 1.35)
		var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(sc, sc * rng.randf_range(0.90, 1.20), sc))
		var p := Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		mm.set_instance_transform(i, Transform3D(b, p))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.position = center
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 90.0
	mmi.visibility_range_end_margin = 16.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mmi)
	return mmi


static func add_mossy_stones(parent: Node3D, center: Vector3, radius: float,
		count: int = 5, seed_val: int = 401, skip_front_z: bool = false) -> void:
	## Scatters mossy_stone.glb boulders around terrace rims for Little Prince organic rock framing.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var stone_style := {
		"top": Color(0.18, 0.48, 0.20),
		"top_blend": 0.24,
		"rim": Color(1.0, 0.90, 0.62),
		"rim_s": 0.24,
		"shadow": Color(0.16, 0.24, 0.44),
		"tex": "stone_mosaic",
		"tex_scale": 0.45,
		"tex_blend": 0.55,
	}
	for i in range(count):
		var ang := (float(i) / float(count)) * TAU + rng.randf_range(-0.22, 0.22)
		if skip_front_z and sin(ang) > 0.55 and absf(cos(ang)) < 0.65:
			ang += PI * 0.45
		var rad := rng.randf_range(radius * 0.94, radius * 1.04)
		var pos := center + Vector3(cos(ang) * rad, -0.06, sin(ang) * rad)
		var sc := rng.randf_range(0.78, 1.18)
		var inst := load_glb("res://assets/models/dressing/mossy_stone.glb")
		inst.position = pos
		inst.rotation_degrees = Vector3(rng.randf_range(-4.0, 4.0), rng.randf_range(0.0, 360.0), rng.randf_range(-4.0, 4.0))
		inst.scale = Vector3(sc, sc * rng.randf_range(0.85, 1.15), sc)
		enhance_stylized_materials(inst, stone_style["top"], stone_style["top_blend"], stone_style["rim"],
				stone_style["rim_s"], stone_style["shadow"], stone_style["tex"], stone_style["tex_scale"], stone_style["tex_blend"])
		disable_shadows(inst)
		set_detail_cull_range(inst, 110.0)
		parent.add_child(inst)


static func add_solar_mote_arc(parent: Node3D, p_start: Vector3, p_end: Vector3,
		peak_lift: float = 2.6, count: int = 4) -> void:
	## Places gleaming SolarMote collectibles smoothly along a parabolic jump arc from p_start to p_end.
	for i in range(count):
		var u := float(i + 1) / float(count + 1)
		var pos := p_start.lerp(p_end, u)
		pos.y += 4.0 * peak_lift * u * (1.0 - u)
		var mote := SolarMote.new()
		mote.position = pos
		parent.add_child(mote)


static func add_catenary_lanterns(parent: Node3D, p_a: Vector3, p_b: Vector3,
		count: int = 6, sag: float = 1.1, glow_col: Color = Color(1.0, 0.66, 0.32)) -> MultiMeshInstance3D:
	## Overhead MultiMesh string of compact ribbed washi-paper festival lanterns (0.31m diameter, warm amber <= 1.80).
	var mesh := _extract_first_mesh("res://assets/models/dressing/lantern_unit.glb")
	if not mesh:
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var mid_pt := (p_a + p_b) * 0.5 - Vector3(0.0, sag, 0.0)
	for i in range(count):
		var u := (float(i) + 0.5) / float(count)
		var pos := p_a.lerp(p_b, u)
		pos.y -= 4.0 * sag * u * (1.0 - u)
		var b := Basis(Vector3.UP, u * TAU).scaled(Vector3.ONE * 0.90)
		mm.set_instance_transform(i, Transform3D(b, pos))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = 185.0
	mmi.visibility_range_end_margin = 25.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	var lkey := "__cat_lantern_v2__|%s" % glow_col.to_html(false)
	var lsh: ShaderMaterial
	if _mat_cache.has(lkey):
		lsh = _mat_cache[lkey]
	else:
		lsh = ShaderMaterial.new()
		lsh.shader = _get_tactile_shader()
		lsh.set_shader_parameter("albedo_color", Color(0.36, 0.20, 0.08))
		lsh.set_shader_parameter("roughness_val", 0.55)
		lsh.set_shader_parameter("emission_color", Color(1.0, 0.64, 0.26))
		lsh.set_shader_parameter("emission_strength", 1.35)
		var pbr := _get_pbr_tex("washi_paper")
		if not pbr.is_empty():
			lsh.set_shader_parameter("use_textures", true)
			lsh.set_shader_parameter("albedo_tex", pbr["albedo"])
			lsh.set_shader_parameter("normal_tex", pbr["normal"])
			lsh.set_shader_parameter("roughness_tex", pbr["roughness"])
			lsh.set_shader_parameter("tex_scale", 2.4)
			lsh.set_shader_parameter("tex_blend", 0.55)
			lsh.set_shader_parameter("normal_strength", 0.45)
		_mat_cache[lkey] = lsh
	mmi.material_override = lsh
	parent.add_child(mmi)
	# Warm practical glow pool & subtle halo right at the catenary midpoint!
	add_warm_light_pool(parent, mid_pt, Color(1.0, 0.68, 0.32), 2.6, 14.0, true, 1.55)
	return mmi


static func add_parallax_ring(parent: Node3D, world_idx: int, y_center: float, r_min: float, r_max: float,
		count: int, is_far_ring: bool, seed_val: int) -> MultiMeshInstance3D:
	## Biome-specific 3D-shaded atmospheric MultiMesh ring (sil_w1..w6.glb) blended into active horizon fog!
	var w_num := clampi(world_idx + 1, 1, 6)
	var mesh := _extract_first_mesh("res://assets/models/tower_cores/sil_w%d.glb" % w_num)
	if not mesh:
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in range(count):
		var ang := (float(i) / float(count)) * TAU + rng.randf_range(-0.18, 0.18)
		var rad := rng.randf_range(r_min, r_max)
		var yy := y_center + rng.randf_range(-34.0, 44.0)
		var sc := rng.randf_range(0.60, 1.60)
		var sc_y := sc * rng.randf_range(0.85, 1.32)
		var b := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(sc, sc_y, sc))
		mm.set_instance_transform(i, Transform3D(b, Vector3(cos(ang) * rad, yy, sin(ang) * rad)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ParallaxRing_%d_%d" % [world_idx, 1 if is_far_ring else 0]
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pal: Dictionary = BiomeAtmosphere.BIOME_PALETTES[clampi(world_idx, 0, 5)]
	var fog_col: Color = pal["fog_col"]
	var hor_col: Color = pal["horizon"]
	var sun_col: Color = pal["sun_col"]
	var body_col: Color = fog_col.darkened(0.28).lerp(hor_col.darkened(0.22), 0.45)
	var eff_fog: Color = fog_col.lerp(hor_col, 0.38)
	var fog_w: float = 0.75 if is_far_ring else 0.38
	var skey := "__sil_v2__|%d|%d" % [w_num, 1 if is_far_ring else 0]
	var sh: ShaderMaterial
	if _mat_cache.has(skey):
		sh = _mat_cache[skey]
	else:
		sh = ShaderMaterial.new()
		sh.shader = _get_silhouette_shader()
		sh.set_shader_parameter("body_color", body_col)
		sh.set_shader_parameter("fog_color", eff_fog)
		sh.set_shader_parameter("sun_tint", sun_col)
		sh.set_shader_parameter("fog_weight", fog_w)
		_mat_cache[skey] = sh
	mmi.material_override = sh
	parent.add_child(mmi)
	return mmi


static func add_dressing_cluster(parent: Node3D, glb_path: String, pos: Vector3, rot_y_deg: float,
		style: Dictionary, glow_col: Color = Color(1.0, 0.74, 0.34), add_pool: bool = true) -> Node3D:
	var inst := load_glb(glb_path)
	inst.position = pos
	inst.rotation_degrees = Vector3(0.0, rot_y_deg, 0.0)
	if not style.is_empty():
		enhance_stylized_materials(inst, style.get("top", Color.WHITE), 0.0,
				style.get("rim", Color.WHITE), style.get("rim_s", 0.28), style.get("shadow", Color(0.24, 0.22, 0.42)),
				style.get("tex", ""), style.get("tex_scale", 0.38), style.get("tex_blend", 0.58), style.get("wetness", 0.0))
	disable_shadows(inst)
	set_detail_cull_range(inst, 130.0)
	parent.add_child(inst)
	if add_pool:
		add_warm_light_pool(parent, pos + Vector3(0.0, 1.35, 0.0), glow_col, 2.8, 10.5, true, 1.45)
	return inst


static func apply_crystal_shader(root: Node, base_tint: Color = Color(0.84, 0.88, 1.0, 0.85)) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		var sh := ShaderMaterial.new()
		sh.shader = _get_crystal_shader()
		sh.set_shader_parameter("base_tint", base_tint)
		mi.material_override = sh
	for ch in root.get_children():
		apply_crystal_shader(ch, base_tint)


static func apply_paper_shader(root: Node, paper_col: Color = Color(0.97, 0.94, 0.86)) -> void:
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		var src := mi.get_active_material(0)
		if src is StandardMaterial3D and src.metallic > 0.5:
			return
		var sh := ShaderMaterial.new()
		sh.shader = _get_paper_shader()
		sh.set_shader_parameter("paper_color", paper_col)
		mi.material_override = sh
	for ch in root.get_children():
		apply_paper_shader(ch, paper_col)


static func apply_soft_cloud_material(root: Node, crest_col: Color, rim_col: Color, valley_col: Color) -> void:
	## Soft, radiant Studio Ghibli cumulus cloud puff shader with warm sunlit crests,
	## sky-translucent cool undersides, and zero muddy brown diffuse collapse!
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ckey := "__cloud_v2__|%s|%s|%s" % [crest_col.to_html(false), rim_col.to_html(false), valley_col.to_html(false)]
		var sh: ShaderMaterial
		if _mat_cache.has(ckey):
			sh = _mat_cache[ckey]
		else:
			sh = ShaderMaterial.new()
			sh.shader = _get_cloud_puff_shader()
			sh.set_shader_parameter("crest_color", crest_col)
			sh.set_shader_parameter("valley_color", valley_col)
			sh.set_shader_parameter("rim_color", rim_col)
			sh.set_shader_parameter("rim_strength", 0.45)
			_mat_cache[ckey] = sh
		mi.material_override = sh
	for ch in root.get_children():
		apply_soft_cloud_material(ch, crest_col, rim_col, valley_col)


static func add_static_cyl_platform(parent: Node3D, glb_path: String, pos: Vector3, radius: float,
		height: float = 0.6, scale_vec: Vector3 = Vector3.ONE, rot_deg: Vector3 = Vector3.ZERO,
		style: Dictionary = {}, audit: Array = [], note: String = "platform") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot_deg
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius * scale_vec.x
	cyl.height = height
	col.shape = cyl
	col.position = Vector3(0.0, -height * 0.5, 0.0)
	body.add_child(col)

	var vis := load_glb(glb_path)
	vis.name = "Visual"
	vis.scale = scale_vec
	if not style.is_empty():
		enhance_stylized_materials(vis, style.get("top", Color.WHITE), style.get("top_blend", 0.0),
				style.get("rim", Color.WHITE), style.get("rim_s", 0.28), style.get("shadow", Color(0.25, 0.22, 0.42)),
				style.get("tex", ""), style.get("tex_scale", 0.26), style.get("tex_blend", 0.68), style.get("wetness", 0.0))
	body.add_child(vis)
	parent.add_child(body)
	audit.append({"pos": pos, "kind": note, "radius": radius * scale_vec.x})
	return body


static func add_static_box_platform(parent: Node3D, glb_path: String, pos: Vector3, size: Vector3,
		scale_vec: Vector3 = Vector3.ONE, rot_deg: Vector3 = Vector3.ZERO,
		style: Dictionary = {}, audit: Array = [], note: String = "platform") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = rot_deg
	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(size.x * scale_vec.x, size.y * scale_vec.y, size.z * scale_vec.z)
	col.shape = bx
	col.position = Vector3(0.0, -bx.size.y * 0.5, 0.0)
	body.add_child(col)

	var vis := load_glb(glb_path)
	vis.name = "Visual"
	vis.scale = scale_vec
	if not style.is_empty():
		enhance_stylized_materials(vis, style.get("top", Color.WHITE), style.get("top_blend", 0.0),
				style.get("rim", Color.WHITE), style.get("rim_s", 0.28), style.get("shadow", Color(0.25, 0.22, 0.42)),
				style.get("tex", ""), style.get("tex_scale", 0.26), style.get("tex_blend", 0.68), style.get("wetness", 0.0))
	body.add_child(vis)
	parent.add_child(body)
	audit.append({"pos": pos, "kind": note, "radius": maxf(bx.size.x, bx.size.z) * 0.5})
	return body


static func add_bounce_pad(parent: Node3D, glb_path: String, pos: Vector3, bounce_up: float = 20.5,
		radius: float = 2.2, fwd_boost: Vector3 = Vector3.ZERO, style: Dictionary = {}, audit: Array = []) -> BouncePad:
	var bp := BouncePad.new()
	bp.position = pos
	bp.bounce_up_speed = bounce_up
	bp.forward_boost = fwd_boost
	bp.trigger_radius = radius

	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = radius
	cy.height = 0.45
	cs.shape = cy
	cs.position = Vector3(0.0, -0.25, 0.0)
	sb.add_child(cs)
	bp.add_child(sb)

	var vis := load_glb(glb_path)
	vis.name = "Visual"
	if not style.is_empty():
		enhance_stylized_materials(vis, style.get("top", Color.WHITE), 0.0, style.get("rim", Color.WHITE), 0.35,
				style.get("shadow", Color(0.24, 0.22, 0.42)), "", 0.26, 0.68, style.get("wetness", 0.0))
	bp.add_child(vis)
	parent.add_child(bp)
	audit.append({"pos": pos, "kind": "bounce", "radius": radius, "boost_y": (bounce_up * bounce_up) / (2.0 * 26.0)})
	return bp


static func add_crumbling_tile(parent: Node3D, glb_path: String, pos: Vector3, break_delay: float = 0.85,
		is_crystal: bool = false, rot_deg: Vector3 = Vector3.ZERO, audit: Array = []) -> CrumblingTile:
	var ct := CrumblingTile.new()
	ct.position = pos
	ct.rotation_degrees = rot_deg
	ct.break_delay = break_delay
	ct.is_crystal = is_crystal
	ct.tile_size = Vector3(3.45, 0.38, 3.45)

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var bx := BoxShape3D.new()
	bx.size = ct.tile_size
	col.shape = bx
	col.position = Vector3(0.0, -ct.tile_size.y * 0.5, 0.0)
	ct.add_child(col)

	var vis := load_glb(glb_path)
	vis.name = "Visual"
	if is_crystal:
		apply_crystal_shader(vis)
	ct.add_child(vis)
	parent.add_child(ct)
	audit.append({"pos": pos, "kind": "crumble", "radius": 1.8})
	return ct


static func add_wall_run(parent: Node3D, glb_path: String, pos: Vector3, rot_deg: Vector3,
		box_size: Vector3, is_bell: bool = false, bell_step: int = 0, audit: Array = []) -> WallRunSurface:
	var wr := WallRunSurface.new()
	wr.position = pos
	wr.rotation_degrees = rot_deg
	wr.is_musical_bell = is_bell
	wr.bell_note_step = bell_step

	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = box_size
	col.shape = bx
	wr.add_child(col)

	var vis := load_glb(glb_path)
	vis.name = "Visual"
	if is_bell:
		enhance_stylized_materials(vis, Color(0.92, 0.68, 0.24), 0.0, Color(1.0, 0.80, 0.40), 0.34, Color(0.32, 0.16, 0.28), "hammered_brass", 0.36, 0.68)
	wr.add_child(vis)
	parent.add_child(wr)
	audit.append({"pos": pos, "kind": "wall_run", "radius": maxf(box_size.x, box_size.z) * 0.5})
	return wr


static func add_spinning_gear(parent: Node3D, pos: Vector3, angular_spd_deg: float = 28.0,
		scale_val: float = 1.0, audit: Array = []) -> SpinningGear:
	var sg := SpinningGear.new()
	sg.position = pos
	sg.angular_speed_deg = angular_spd_deg

	var col := CollisionShape3D.new()
	var cy := CylinderShape3D.new()
	cy.radius = 4.25 * scale_val
	cy.height = 0.62 * scale_val
	col.shape = cy
	col.position = Vector3(0.0, -0.31 * scale_val, 0.0)
	sg.add_child(col)

	var vis := load_glb("res://assets/models/world2_foundry/brass_gear.glb")
	vis.scale = Vector3.ONE * scale_val
	enhance_stylized_materials(vis, Color(0.92, 0.68, 0.24), 0.10, Color(1.0, 0.80, 0.40), 0.34, Color(0.32, 0.16, 0.28), "hammered_brass", 0.36, 0.72)
	sg.add_child(vis)
	parent.add_child(sg)
	audit.append({"pos": pos, "kind": "gear", "radius": 4.25 * scale_val})
	return sg


static func add_pendulum(parent: Node3D, pivot_pos: Vector3, rot_y_deg: float = 0.0,
		swing_deg: float = 30.0, spd: float = 1.5, phase: float = 0.0) -> PendulumHazard:
	var pd := PendulumHazard.new()
	pd.position = pivot_pos
	pd.rotation_degrees = Vector3(0.0, rot_y_deg, 0.0)
	pd.swing_angle_deg = swing_deg
	pd.swing_speed = spd
	pd.phase_offset = phase

	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(4.2, 0.42, 2.4)
	col.shape = bx
	col.position = Vector3(0.0, -5.8, 0.0)
	pd.add_child(col)

	var vis := load_glb("res://assets/models/world2_foundry/pendulum_blade.glb")
	enhance_stylized_materials(vis, Color(0.92, 0.68, 0.24), 0.0, Color(1.0, 0.80, 0.40), 0.32, Color(0.32, 0.16, 0.28), "hammered_brass", 0.40, 0.68)
	pd.add_child(vis)
	parent.add_child(pd)
	return pd


static func add_folding_tile(parent: Node3D, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, audit: Array = []) -> FoldingBridge:
	var fb := FoldingBridge.new()
	fb.position = pos
	fb.rotation_degrees = rot_deg

	var col := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(3.55, 0.30, 3.55)
	col.shape = bx
	col.position = Vector3(0.0, -0.15, 0.0)
	fb.add_child(col)

	var vis := load_glb("res://assets/models/world3_monsoon/folded_tile.glb")
	apply_paper_shader(vis)
	fb.add_child(vis)
	parent.add_child(fb)
	audit.append({"pos": pos, "kind": "folding_tile", "radius": 1.8})
	return fb


static func add_portal_pair(parent: Node3D, entry_pos: Vector3, entry_yaw_deg: float,
		exit_pos: Vector3, exit_yaw_deg: float, launch_speed: float = 20.0, audit: Array = []) -> void:
	var exit_fwd := Vector3(-sin(deg_to_rad(exit_yaw_deg)), 0.38, -cos(deg_to_rad(exit_yaw_deg))).normalized()

	var p_in := PortalFrame.new()
	p_in.position = entry_pos
	p_in.rotation_degrees = Vector3(0.0, entry_yaw_deg, 0.0)
	p_in.exit_target_pos = exit_pos + Vector3(0.0, 2.2, 0.0) + exit_fwd * 1.4
	p_in.exit_launch_dir = exit_fwd
	p_in.exit_launch_speed = launch_speed
	p_in.add_child(load_glb("res://assets/models/world4_mirrors/gilded_portal_frame.glb"))
	parent.add_child(p_in)

	var p_out := PortalFrame.new()
	p_out.position = exit_pos
	p_out.rotation_degrees = Vector3(0.0, exit_yaw_deg, 0.0)
	p_out.is_exit_only = true
	p_out.add_child(load_glb("res://assets/models/world4_mirrors/gilded_portal_frame.glb"))
	parent.add_child(p_out)

	audit.append({"pos": entry_pos, "kind": "portal_in", "radius": 2.4, "portal_exit": exit_pos})
	audit.append({"pos": exit_pos, "kind": "portal_out", "radius": 2.4})


static func add_updraft(parent: Node3D, pos: Vector3, height: float = 16.0, radius: float = 2.8,
		color: Color = Color(0.72, 0.98, 0.88), audit: Array = []) -> UpdraftColumn:
	var ud := UpdraftColumn.new()
	ud.position = pos
	ud.column_height = height
	ud.column_radius = radius
	ud.stream_color = color
	parent.add_child(ud)
	audit.append({"pos": pos, "kind": "updraft_in", "radius": radius})
	audit.append({"pos": pos + Vector3(0.0, height * 0.90, 0.0), "kind": "updraft_out", "radius": radius, "boost_y": height})
	return ud


static func add_gravity_bubble(parent: Node3D, pos: Vector3, radius: float = 9.0, audit: Array = []) -> GravityBubble:
	var gb := GravityBubble.new()
	gb.position = pos
	gb.bubble_radius = radius
	parent.add_child(gb)
	audit.append({"pos": pos, "kind": "gravity_bubble", "radius": radius, "boost_y": 11.0})
	return gb


static func add_tether_orb(parent: Node3D, pos: Vector3, audit: Array = []) -> TetherOrb:
	var orb := TetherOrb.new()
	orb.position = pos
	parent.add_child(orb)
	audit.append({"pos": pos, "kind": "tether_orb", "radius": 2.0, "boost_y": 7.5})
	return orb


static func add_shrine(parent: Node3D, cp_id: String, world_idx: int, pos: Vector3,
		spawn_yaw_deg: float = 0.0, is_start: bool = false, is_summit: bool = false, audit: Array = [],
		spawn_off: Vector3 = Vector3(0.0, 0.8, 0.0)) -> CheckpointShrine:
	var sh := CheckpointShrine.new()
	sh.checkpoint_id = cp_id
	sh.world_idx = world_idx
	sh.position = pos
	sh.spawn_yaw_deg = spawn_yaw_deg
	sh.is_world_start = is_start
	sh.is_summit_crown = is_summit
	sh.spawn_offset = spawn_off
	parent.add_child(sh)
	audit.append({"pos": pos, "kind": "checkpoint", "id": cp_id, "radius": 3.0})
	return sh


static func add_sun_shard(parent: Node3D, shard_id: String, pos: Vector3) -> SunShard:
	var ss := SunShard.new()
	ss.shard_id = shard_id
	ss.position = pos
	parent.add_child(ss)
	return ss


static func add_landmark(parent: Node3D, glb_path: String, pos: Vector3,
		scale_vec: Vector3 = Vector3.ONE, rot_deg: Vector3 = Vector3.ZERO, style: Dictionary = {},
		cull_dist: float = 0.0, no_shadows: bool = false) -> Node3D:
	var inst := load_glb(glb_path)
	inst.position = pos
	inst.rotation_degrees = rot_deg
	inst.scale = scale_vec
	if not style.is_empty():
		enhance_stylized_materials(inst, style.get("top", Color.WHITE), style.get("top_blend", 0.0),
				style.get("rim", Color.WHITE), style.get("rim_s", 0.25), style.get("shadow", Color(0.24, 0.22, 0.42)),
				style.get("tex", ""), style.get("tex_scale", 0.26), style.get("tex_blend", 0.68), style.get("wetness", 0.0))
	if no_shadows:
		disable_shadows(inst)
	if cull_dist > 0.0:
		set_detail_cull_range(inst, cull_dist)
	parent.add_child(inst)
	return inst


static func spiral_pt(angle_deg: float, radius: float, y: float) -> Vector3:
	var rad := deg_to_rad(angle_deg)
	return Vector3(sin(rad) * radius, y, cos(rad) * radius)


static func add_soaring_crane(parent: Node3D, start_p: Vector3, mid_p: Vector3, end_p: Vector3,
		flight_dur: float = 9.5, scale_v: float = 1.55) -> SoaringCrane:
	var sc := SoaringCrane.new()
	sc.start_pos = start_p
	sc.mid_pos = mid_p
	sc.end_pos = end_p
	sc.flight_duration = flight_dur
	sc.crane_scale = scale_v
	parent.add_child(sc)
	return sc


static func add_swinging_bridge(parent: Node3D, pos: Vector3, rot_y_deg: float,
		length_m: float = 11.0, width_m: float = 1.45, sway_amp: float = 2.0,
		title: String = "THE FOUNDRY SKY-BEAM", sub: String = "Hold Your Nerve!") -> SwingingBridge:
	var sb := SwingingBridge.new()
	sb.position = pos
	sb.rotation_degrees = Vector3(0.0, rot_y_deg, 0.0)
	sb.bridge_length = length_m
	sb.bridge_width = width_m
	sb.sway_amplitude = sway_amp
	sb.callout_title = title
	sb.callout_subtitle = sub
	parent.add_child(sb)
	return sb


static func add_shortcut_beacon(parent: Node3D, pos: Vector3, rot_y_deg: float,
		title: String, sub: String, is_takeoff: bool = false) -> ShortcutBeacon:
	var b := ShortcutBeacon.new()
	b.position = pos
	b.rotation_degrees = Vector3(0.0, rot_y_deg, 0.0)
	b.callout_title = title
	b.callout_subtitle = sub
	b.is_takeoff_marker = is_takeoff
	parent.add_child(b)
	return b


static func add_world_hint(parent: Node3D, pos: Vector3, title: String, template_str: String) -> WorldHint:
	var wh := WorldHint.new()
	wh.position = pos
	wh.hint_title = title
	wh.hint_template = template_str
	parent.add_child(wh)
	return wh


static func add_summit_celebration(parent: Node3D, pos: Vector3) -> SummitCelebration:
	var sc := SummitCelebration.new()
	sc.position = pos
	parent.add_child(sc)
	return sc


static func add_docked_airship(parent: Node3D, pos: Vector3, rot_y_deg: float = -18.0) -> DockedAirship:
	var ship := DockedAirship.new()
	ship.position = pos
	ship.rotation_degrees = Vector3(0.0, rot_y_deg, 0.0)
	parent.add_child(ship)
	return ship


static func set_realm_lod_mode(root: Node, is_distant: bool) -> void:
	## Keeps ALL conquered lower realms 100% visible for jaw-dropping vertigo depth while
	## turning off shadow casting & distant omni-lights/particles on realms 2+ tiers below!
	if root is GeometryInstance3D:
		var gi := root as GeometryInstance3D
		if is_distant:
			gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			if gi is MeshInstance3D:
				var mi := gi as MeshInstance3D
				if mi.mesh and mi.mesh.get_aabb().size.length() >= 0.72:
					gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	elif root is OmniLight3D:
		(root as OmniLight3D).visible = not is_distant
	elif root is GPUParticles3D:
		(root as GPUParticles3D).visible = not is_distant
	for ch in root.get_children():
		set_realm_lod_mode(ch, is_distant)
