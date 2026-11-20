shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.72, 0.34, 1.0);
uniform float intensity : hint_range(0.1, 3.0) = 0.85;

void vertex() {
	// True view-aligned camera billboard preserving uniform node scale
	vec3 scale_v = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(INV_VIEW_MATRIX[0].xyz * scale_v.x, 0.0),
		vec4(INV_VIEW_MATRIX[1].xyz * scale_v.y, 0.0),
		vec4(INV_VIEW_MATRIX[2].xyz * scale_v.z, 0.0),
		MODEL_MATRIX[3]
	);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float core = exp(-r * r * 5.2);
	float halo = exp(-r * r * 1.8) * 0.42;
	float falloff = clamp((core + halo) * smoothstep(1.0, 0.65, r), 0.0, 1.0);
	ALBEDO = glow_color.rgb * intensity * falloff;
	ALPHA = falloff;
}
