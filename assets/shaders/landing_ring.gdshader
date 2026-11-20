shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, depth_test_disabled;

uniform vec4 ring_color : source_color = vec4(1.0, 0.94, 0.72, 0.92);
uniform vec4 shadow_color : source_color = vec4(0.05, 0.06, 0.12, 0.52);
uniform float height_factor : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);

	// Soft drop shadow core underneath feet
	float shadow = smoothstep(0.75, 0.15, r) * shadow_color.a * (1.0 - height_factor * 0.45);
	// Crisp glowing landing aim ring that tightens as player approaches floor
	float ring_radius = mix(0.62, 0.84, height_factor);
	float ring = smoothstep(0.09, 0.02, abs(r - ring_radius));
	float center_pip = smoothstep(0.14, 0.05, r) * 0.65 * height_factor;

	float glow_alpha = (ring * 0.85 + center_pip) * ring_color.a;
	vec3 col = mix(shadow_color.rgb, ring_color.rgb, clamp(glow_alpha / max(shadow + glow_alpha, 0.001), 0.0, 1.0));
	ALBEDO = col;
	ALPHA = clamp(max(shadow, glow_alpha), 0.0, 0.95);
}
