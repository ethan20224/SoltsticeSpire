shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform vec4 body_color : source_color = vec4(0.46, 0.60, 0.76, 1.0);
uniform vec4 fog_color : source_color = vec4(0.58, 0.72, 0.86, 1.0);
uniform vec4 sun_tint : source_color = vec4(0.98, 0.84, 0.60, 1.0);
uniform float fog_weight : hint_range(0.0, 1.0) = 0.45;

varying float v_local_y;
varying vec3 v_world_n;

void vertex() {
	v_local_y = VERTEX.y;
	v_world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Simple N.L top/sun term so distant silhouettes have 3D form while sitting inside the biome fog!
	vec3 sun_dir = normalize(vec3(0.38, 0.82, 0.42));
	float ndotl = clamp(dot(v_world_n, sun_dir), 0.0, 1.0);
	float top_mask = smoothstep(0.15, 0.85, v_world_n.y);
	float h = clamp((v_local_y + 18.0) / 38.0, 0.0, 1.0);

	vec3 shaded = mix(body_color.rgb * 0.82, mix(body_color.rgb, sun_tint.rgb, 0.38), ndotl * 0.65 + top_mask * 0.35);
	shaded = mix(fog_color.rgb, shaded, h * 0.35 + 0.65);
	vec3 final_col = mix(shaded, fog_color.rgb, fog_weight);
	ALBEDO = final_col;
}
