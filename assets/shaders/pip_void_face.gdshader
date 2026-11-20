shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 center_color : source_color = vec4(0.04, 0.035, 0.09, 1.0);
uniform vec4 rim_color : source_color = vec4(0.24, 0.12, 0.22, 1.0);
uniform vec4 ember_bounce : source_color = vec4(0.95, 0.56, 0.24, 1.0);

varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float edge = pow(1.0 - ndotv, 1.8);
	// Soft warm ember bounce rising gently from Pip's lantern below the chin
	float chin_bounce = smoothstep(0.08, -0.18, v_local_pos.y) * 0.45;
	vec3 col = mix(center_color.rgb, rim_color.rgb, edge * 0.85);
	col += ember_bounce.rgb * (chin_bounce * 0.32 + edge * 0.10);
	ALBEDO = col;
	ROUGHNESS = 0.84;
	METALLIC = 0.0;
	EMISSION = rim_color.rgb * edge * 0.28 + ember_bounce.rgb * chin_bounce * 0.26;
}
