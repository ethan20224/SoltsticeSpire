shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 inner_color : source_color = vec4(1.0, 0.88, 0.52, 1.0);
uniform vec4 mid_color : source_color = vec4(0.68, 0.30, 0.96, 1.0);
uniform vec4 outer_color : source_color = vec4(0.14, 0.08, 0.28, 1.0);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float swirl = sin(ang * 5.0 - r * 9.0 + TIME * 4.5) * 0.5 + 0.5;
	float rings = sin(r * 14.0 - TIME * 5.2) * 0.5 + 0.5;
	float core = smoothstep(0.85, 0.05, r);

	vec3 col = mix(outer_color.rgb, mid_color.rgb, smoothstep(0.15, 0.85, swirl * 0.6 + rings * 0.4));
	col = mix(col, inner_color.rgb * 1.9, pow(core, 1.8) * (0.65 + 0.35 * swirl));
	float border = smoothstep(0.98, 0.82, max(abs(p.x), abs(p.y)));
	ALBEDO = col;
	ALPHA = clamp(border * 0.92, 0.0, 1.0);
}
