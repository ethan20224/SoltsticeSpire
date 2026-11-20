shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 albedo_color : source_color = vec4(0.88, 0.82, 0.74, 1.0);
uniform bool use_textures = false;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D roughness_tex : filter_linear_mipmap, repeat_enable;
uniform float tex_scale : hint_range(0.05, 4.0) = 0.24;
uniform float tex_blend : hint_range(0.0, 1.0) = 0.65;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.55;

uniform vec4 top_color : source_color = vec4(0.22, 0.52, 0.24, 1.0);
uniform float top_blend : hint_range(0.0, 1.0) = 0.0;
uniform float top_sharpness : hint_range(1.0, 12.0) = 4.5;

uniform float roughness_val : hint_range(0.04, 1.0) = 0.45;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.0;
uniform float grain_strength : hint_range(0.0, 0.15) = 0.015;
uniform float grain_scale : hint_range(0.2, 8.0) = 1.2;

// Macro low-frequency variation noise (kills flat plastic lawns & stone slabs!)
uniform float macro_var_strength : hint_range(0.0, 0.45) = 0.14;
uniform float macro_scale : hint_range(0.01, 0.25) = 0.045;
uniform vec4 macro_tint : source_color = vec4(0.86, 0.96, 0.78, 1.0);

// Rain-slicked puddle sheen for World 3 Monsoon!
uniform float wetness : hint_range(0.0, 1.0) = 0.0;

uniform vec4 rim_color : source_color = vec4(1.0, 0.92, 0.74, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.28;
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform float plush_sheen : hint_range(0.0, 1.0) = 0.0;

uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0) = 0.0;

uniform vec4 shadow_warmth : source_color = vec4(0.26, 0.22, 0.44, 1.0);
uniform float stylize_ramp : hint_range(0.0, 1.0) = 0.36;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	return mix(nxy0, nxy1, f.z);
}

vec3 triplanar_sample(sampler2D tex, vec3 p, vec3 weights) {
	vec3 sx = texture(tex, p.zy).rgb;
	vec3 sy = texture(tex, p.xz).rgb;
	vec3 sz = texture(tex, p.xy).rgb;
	return sx * weights.x + sy * weights.y + sz * weights.z;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 w_abs = pow(abs(v_world_normal), vec3(4.0));
	vec3 tri_w = w_abs / max(w_abs.x + w_abs.y + w_abs.z, 0.0001);

	float n1 = noise3(v_world_pos * grain_scale);
	float painterly = n1 - 0.5;
	float macro_n = noise3(v_world_pos * macro_scale) * 0.65 + noise3(v_world_pos * macro_scale * 2.3 + vec3(11.7, 3.1, 7.9)) * 0.35;

	vec3 base = albedo_color.rgb;
	float rough = roughness_val;

	if (use_textures) {
		vec3 tp = v_world_pos * tex_scale;
		vec3 t_alb = triplanar_sample(albedo_tex, tp, tri_w);
		float t_rgh = triplanar_sample(roughness_tex, tp, tri_w).r;
		vec3 tinted_tex = t_alb * (albedo_color.rgb * 1.18 + vec3(0.07));
		base = mix(base, tinted_tex, tex_blend);
		rough = mix(rough, clamp(t_rgh, 0.14, 0.96), tex_blend * 0.68);

		// True Derivative Triplanar Normal Perturbation (damped inside wet puddles so wet wood looks smooth, not liquid ripples!)
		float wet_damp = 1.0 - clamp(wetness * 0.65, 0.0, 0.65);
		vec3 nx = texture(normal_tex, tp.zy).rgb * 2.0 - 1.0;
		vec3 ny = texture(normal_tex, tp.xz).rgb * 2.0 - 1.0;
		vec3 nz = texture(normal_tex, tp.xy).rgb * 2.0 - 1.0;
		vec3 w_delta = (
			vec3(0.0, nx.y, nx.x) * tri_w.x +
			vec3(ny.x, 0.0, ny.y) * tri_w.y +
			vec3(nz.x, nz.y, 0.0) * tri_w.z
		) * (normal_strength * 0.56 * wet_damp);
		vec3 perturbed_world = normalize(v_world_normal + w_delta);
		NORMAL = normalize((VIEW_MATRIX * vec4(perturbed_world, 0.0)).xyz);
	}

	float up_mask = clamp(pow(max(v_world_normal.y + (macro_n - 0.5) * 0.22, 0.0), top_sharpness), 0.0, 1.0) * top_blend;
	vec3 rich_top = top_color.rgb * mix(vec3(0.84, 0.90, 0.88), vec3(1.16, 1.12, 0.94), macro_n);
	base = mix(base, rich_top, up_mask);

	// Broad painterly macro color sweep across architecture and lawns
	base = mix(base, base * macro_tint.rgb * (0.86 + macro_n * 0.30), macro_var_strength);
	base *= 1.0 + painterly * grain_strength;

	// Rain-slicked puddle sheen for Monsoon rooftops & bridges
	float puddle = 0.0;
	if (wetness > 0.01) {
		float pn = noise3(v_world_pos * 0.32 + vec3(4.1, 0.0, 9.2));
		puddle = smoothstep(0.42, 0.68, pn) * smoothstep(0.55, 0.85, v_world_normal.y) * wetness;
		base *= mix(1.0, 0.78, puddle * 0.65);
		rough = mix(rough, 0.11, puddle);
	}

	ALBEDO = clamp(base, vec3(0.02), vec3(1.0));
	ROUGHNESS = clamp(rough + painterly * 0.025, 0.09, 0.98);
	METALLIC = clamp(metallic_val * (1.0 - puddle * 0.25), 0.0, 1.0);

	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, rim_power);
	float rim_up = smoothstep(-0.35, 0.65, v_world_normal.y);
	float velvet = pow(1.0 - ndotv, 1.8) * plush_sheen;
	vec3 rim = rim_color.rgb * fresnel * (rim_strength + puddle * 0.32) * (0.45 + 0.55 * rim_up)
		+ mix(ALBEDO, vec3(1.0, 0.95, 0.86), 0.45) * velvet * 0.26;
	EMISSION = emission_color.rgb * emission_strength + rim;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float raw_lit = clamp(ndotl, 0.0, 1.0) * ATTENUATION;
	float wrap_lit = clamp((ndotl + 0.16) / 1.16, 0.0, 1.0) * ATTENUATION;
	float cel_step = smoothstep(0.05, 0.30, wrap_lit) * 0.72 + smoothstep(0.45, 0.76, wrap_lit) * 0.28;
	float lit = mix(raw_lit, cel_step, stylize_ramp);

	float terminator = smoothstep(-0.18, 0.10, ndotl) * (1.0 - smoothstep(0.10, 0.38, ndotl)) * ATTENUATION;
	vec3 diff = ALBEDO * (LIGHT_COLOR / 3.14159265) * (lit * 0.96);
	diff += shadow_warmth.rgb * ALBEDO * terminator * 0.18;
	DIFFUSE_LIGHT += diff;

	vec3 h = normalize(LIGHT + VIEW);
	float spec_exp = mix(128.0, 14.0, ROUGHNESS * ROUGHNESS);
	// Completely suppress wet specular sparkle on matte foliage/moss (ROUGHNESS >= 0.82),
	// while making hammered brass/gold & wet Monsoon roofs gleam cleanly!
	float spec_gate = smoothstep(0.82, 0.18, ROUGHNESS);
	float spec_boost = mix(0.45, 0.86, METALLIC);
	float spec = pow(max(dot(NORMAL, h), 0.0), spec_exp) * spec_gate * spec_boost * lit;
	vec3 spec_col = mix(LIGHT_COLOR, mix(LIGHT_COLOR, ALBEDO * LIGHT_COLOR, 0.72), METALLIC);
	SPECULAR_LIGHT += spec_col * spec;
}
