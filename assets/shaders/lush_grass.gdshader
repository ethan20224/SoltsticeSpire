shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

global uniform vec3 player_world_pos;

uniform vec4 root_color : source_color = vec4(0.08, 0.36, 0.15, 1.0);
uniform vec4 tip_color : source_color = vec4(0.48, 0.84, 0.22, 1.0);
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float wind_strength : hint_range(0.0, 0.35) = 0.085;
uniform float wind_speed : hint_range(0.1, 4.0) = 1.75;
uniform float bend_radius : hint_range(0.4, 3.5) = 1.8;
uniform float bend_strength : hint_range(0.0, 1.2) = 0.52;
uniform float roughness_val : hint_range(0.2, 1.0) = 0.88;
uniform vec4 rim_color : source_color = vec4(1.0, 0.94, 0.66, 1.0);
uniform float rim_strength : hint_range(0.0, 1.5) = 0.30;
uniform vec4 shadow_warmth : source_color = vec4(0.14, 0.28, 0.44, 1.0);

varying float v_height;
varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = smoothstep(0.05, 0.45, VERTEX.y);

	// Dual-frequency organic wind wave sway across world XZ
	float w1 = sin(TIME * wind_speed + world_pos.x * 0.82 + world_pos.z * 0.64);
	float w2 = cos(TIME * (wind_speed * 1.65) + world_pos.x * 1.68 - world_pos.z * 1.42);
	vec2 wind_off = vec2(w1 * 0.68 + w2 * 0.32, w2 * 0.56 - w1 * 0.28) * wind_strength * h;

	// Astro Bot interactive lawn: bend blades gracefully away from player within 1.8m
	vec3 to_blade = world_pos - player_world_pos;
	float flat_dist = length(to_blade.xz);
	float vert_prox = 1.0 - smoothstep(1.2, 2.6, abs(to_blade.y));
	float push = (1.0 - smoothstep(0.12, bend_radius, flat_dist)) * vert_prox * h;
	vec2 push_dir = flat_dist > 0.001 ? normalize(to_blade.xz) : vec2(1.0, 0.0);
	vec3 world_disp = vec3(
		wind_off.x + push_dir.x * push * bend_strength,
		-push * 0.24,
		wind_off.y + push_dir.y * push * bend_strength
	);

	// Transform world-space displacement back into blade-local space cleanly
	vec3 local_disp = inverse(mat3(MODEL_MATRIX)) * world_disp;
	VERTEX += local_disp;

	v_height = clamp(h, 0.0, 1.0);
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float patch_var = sin(v_world_pos.x * 0.36 + 0.7) * cos(v_world_pos.z * 0.42 - 0.4) * 0.5 + 0.5;
	vec3 grad_col = mix(root_color.rgb, tip_color.rgb, pow(v_height, 0.85)) * tint_color.rgb;
	grad_col *= mix(0.90, 1.12, patch_var * v_height);

	ALBEDO = clamp(grad_col, vec3(0.02), vec3(1.0));
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;

	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - ndotv, 2.5);
	EMISSION = rim_color.rgb * fresnel * rim_strength * (0.30 + 0.70 * v_height);
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float wrap_lit = clamp((ndotl + 0.36) / 1.36, 0.0, 1.0) * ATTENUATION;
	float sss = pow(clamp(dot(-LIGHT, VIEW), 0.0, 1.0), 2.4) * 0.26 * v_height * ATTENUATION;
	vec3 diff = ALBEDO * (LIGHT_COLOR / 3.14159265) * (wrap_lit * 0.95 + sss);
	diff += shadow_warmth.rgb * ALBEDO * (1.0 - wrap_lit) * 0.14;
	DIFFUSE_LIGHT += diff;
}
