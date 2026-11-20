shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 base_tint : source_color = vec4(0.84, 0.88, 0.98, 0.82);
uniform float iridescence_strength : hint_range(0.0, 2.5) = 1.15;
uniform float crack_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 crack_glow : source_color = vec4(1.0, 0.45, 0.72, 1.0);

varying vec3 v_world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndotv, 2.4);

	// Thin-film spectral rainbow iridescence
	vec3 rainbow = 0.55 + 0.45 * cos(6.28318 * (fres * 0.85 + vec3(0.0, 0.33, 0.67) + TIME * 0.08));
	ALBEDO = mix(base_tint.rgb, rainbow, fres * 0.65);
	ROUGHNESS = 0.08;
	METALLIC = 0.35;

	// Crack telegraph pattern when shattering crystal is stepped on
	vec2 cell = v_world_pos.xz * 2.8;
	float edge = abs(fract(cell.x + sin(cell.y * 2.1) * 0.35) - 0.5) * abs(fract(cell.y + cos(cell.x * 1.9) * 0.35) - 0.5);
	float crack_line = smoothstep(0.045 * crack_amount, 0.005, edge) * step(0.01, crack_amount);

	EMISSION = rainbow * fres * iridescence_strength + crack_glow.rgb * crack_line * (2.5 + crack_amount * 4.0);
	ALPHA = clamp(base_tint.a + fres * 0.25 + crack_line * 0.4, 0.35, 1.0);
}
