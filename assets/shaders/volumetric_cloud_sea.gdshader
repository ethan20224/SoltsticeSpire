shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 crest_color : source_color = vec4(1.0, 0.96, 0.90, 1.0);
uniform vec4 valley_color : source_color = vec4(0.68, 0.77, 0.90, 1.0);
uniform float cloud_scale : hint_range(0.002, 0.05) = 0.0095;
uniform float billow_height : hint_range(0.5, 16.0) = 6.5;
uniform float drift_speed : hint_range(0.0, 0.2) = 0.014;
uniform float opacity : hint_range(0.1, 1.0) = 0.92;

varying float v_height_norm;
varying vec2 v_world_xz;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.5);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

float cloud_fbm(vec2 p) {
	float v = 0.0;
	v += 0.55 * noise2(p);
	v += 0.30 * noise2(p * 2.1 + vec2(5.2, 1.3));
	v += 0.15 * noise2(p * 4.3 + vec2(2.1, 9.7));
	return v;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = wp.xz * cloud_scale + vec2(TIME * drift_speed, TIME * drift_speed * 0.5);
	float h = cloud_fbm(uv);
	VERTEX.y += (h - 0.45) * billow_height;
	v_height_norm = h;
	v_world_xz = wp.xz;
}

void fragment() {
	float dist_fade = 1.0 - smoothstep(260.0, 620.0, length(v_world_xz));
	float crest = smoothstep(0.28, 0.78, v_height_norm);
	ALBEDO = mix(valley_color.rgb, crest_color.rgb, crest);
	ALPHA = clamp(dist_fade * opacity * smoothstep(0.18, 0.42, v_height_norm + 0.15), 0.0, 1.0);
}
