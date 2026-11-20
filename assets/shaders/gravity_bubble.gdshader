shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

uniform vec4 rim_color_a : source_color = vec4(0.32, 0.92, 1.0, 1.0);
uniform vec4 rim_color_b : source_color = vec4(0.76, 0.44, 1.0, 1.0);
uniform float center_alpha : hint_range(0.0, 0.25) = 0.035;
uniform float rim_alpha : hint_range(0.1, 0.9) = 0.56;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndotv, 2.8);
	float swirl = 0.5 + 0.5 * sin(v_world_pos.y * 0.8 + v_world_pos.x * 0.5 + TIME * 1.1);
	vec3 irid = mix(rim_color_a.rgb, rim_color_b.rgb, swirl);
	float ring_sparkle = pow(1.0 - ndotv, 6.0);
	ALBEDO = irid;
	ROUGHNESS = 0.05;
	EMISSION = irid * (fres * 1.35 + ring_sparkle * 1.4);
	ALPHA = clamp(center_alpha + fres * rim_alpha, 0.02, 0.72);
}
