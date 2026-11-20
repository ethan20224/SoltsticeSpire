shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 paper_color : source_color = vec4(0.97, 0.94, 0.86, 1.0);
uniform vec4 crease_color : source_color = vec4(0.84, 0.77, 0.66, 1.0);
uniform vec4 glow_edge_color : source_color = vec4(1.0, 0.78, 0.36, 1.0);
uniform float glow_strength : hint_range(0.0, 3.0) = 0.22;

varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	// Subtle geometric origami crease pattern & warm backlit rim
	float diag1 = abs(fract((v_local_pos.x + v_local_pos.z) * 1.2) - 0.5);
	float diag2 = abs(fract((v_local_pos.x - v_local_pos.z) * 1.2) - 0.5);
	float crease = 1.0 - smoothstep(0.0, 0.04, min(diag1, diag2));

	ALBEDO = mix(paper_color.rgb, crease_color.rgb, crease * 0.55);
	ROUGHNESS = 0.62;
	METALLIC = 0.0;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.8);
	EMISSION = glow_edge_color.rgb * (fres * glow_strength + crease * glow_strength * 0.4);
}
