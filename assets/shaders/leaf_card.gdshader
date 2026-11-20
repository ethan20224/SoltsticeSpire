shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform vec4 tint_sun : source_color = vec4(1.04, 1.02, 0.88, 1.0);
uniform vec4 tint_shade : source_color = vec4(0.72, 0.86, 0.82, 1.0);
uniform vec4 rim_color : source_color = vec4(0.96, 0.90, 0.58, 1.0);

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sway = sin(TIME * 1.9 + wp.x * 0.7 + wp.z * 0.6) * 0.045;
	VERTEX.x += sway * (1.0 - UV.y);
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec4 tex = texture(leaf_tex, UV);
	if (tex.a < 0.46) {
		discard;
	}
	float up_k = clamp(v_world_normal.y * 0.5 + 0.5, 0.0, 1.0);
	ALBEDO = clamp(tex.rgb * mix(tint_shade.rgb, tint_sun.rgb, up_k), vec3(0.02), vec3(1.0));
	ROUGHNESS = 0.92;
	METALLIC = 0.0;
	float fres = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 2.8);
	EMISSION = rim_color.rgb * fres * 0.14 * up_k;
}

void light() {
	float ndotl = abs(dot(NORMAL, LIGHT)) * 0.35 + max(dot(NORMAL, LIGHT), 0.0) * 0.65;
	float wrap_lit = clamp((ndotl + 0.25) / 1.25, 0.0, 1.0) * ATTENUATION;
	DIFFUSE_LIGHT += ALBEDO * (LIGHT_COLOR / 3.14159265) * wrap_lit * 0.94;
}
