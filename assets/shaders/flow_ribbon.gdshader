shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 core_color : source_color = vec4(1.0, 0.88, 0.45, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.48, 0.20, 1.0);
uniform float intensity : hint_range(0.0, 4.0) = 1.6;

void fragment() {
	float along = 1.0 - UV.x;
	float across = 1.0 - abs(UV.y * 2.0 - 1.0);
	float taper = smoothstep(0.0, 0.25, along) * pow(along, 1.4);
	float ribbon = pow(across, 1.6) * taper;
	float pulse = 0.85 + 0.15 * sin(UV.x * 16.0 - TIME * 12.0);
	ALBEDO = mix(edge_color.rgb, core_color.rgb, across) * intensity * pulse;
	ALPHA = clamp(ribbon * 0.9, 0.0, 1.0);
}
