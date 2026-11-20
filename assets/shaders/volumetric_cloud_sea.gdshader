shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 crest_color : source_color = vec4(1.0, 0.97, 0.90, 1.0);
uniform vec4 valley_color : source_color = vec4(0.56, 0.70, 0.90, 1.0);
uniform vec4 horizon_glow_color : source_color = vec4(1.0, 0.88, 0.62, 1.0);
uniform vec3 sun_direction = vec3(0.45, 0.52, -0.72);
uniform float cloud_scale : hint_range(0.002, 0.05) = 0.0085;
uniform float billow_height : hint_range(0.5, 18.0) = 8.2;
uniform float drift_speed : hint_range(0.0, 0.2) = 0.015;
uniform float opacity : hint_range(0.1, 1.0) = 0.96;

varying float v_height_norm;
varying float v_sun_lit;
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

float billow_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.54;
	mat2 rot = mat2(vec2(0.80, 0.60), vec2(-0.60, 0.80));
	for (int i = 0; i < 4; i++) {
		float n = noise2(p);
		float puffy = mix(n, 1.0 - abs(n * 2.0 - 1.0), 0.36);
		v += a * puffy;
		p = rot * p * 2.06 + vec2(7.3, 11.9);
		a *= 0.48;
	}
	return v;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv = wp.xz * cloud_scale + vec2(TIME * drift_speed, TIME * drift_speed * 0.45);
	float h = billow_fbm(uv);
	VERTEX.y += (h - 0.46) * billow_height;

	float eps = 0.08;
	float hx = billow_fbm(uv + vec2(eps, 0.0));
	float hz = billow_fbm(uv + vec2(0.0, eps));
	vec3 nrm = normalize(vec3((h - hx) * 3.6, 0.34, (h - hz) * 3.6));
	vec3 sdir = normalize(sun_direction);
	v_sun_lit = clamp(dot(nrm, sdir) * 0.55 + 0.55, 0.0, 1.0);
	v_height_norm = h;
	v_world_xz = wp.xz;
}

void fragment() {
	float radial = length(v_world_xz);
	float dist_fade = 1.0 - smoothstep(320.0, 740.0, radial);

	float crest = smoothstep(0.30, 0.80, v_height_norm);
	vec3 cloud_col = mix(valley_color.rgb, crest_color.rgb, clamp(crest * 0.72 + v_sun_lit * 0.34, 0.0, 1.0));

	vec3 sdir = normalize(sun_direction);
	vec2 dir_xz = radial > 0.001 ? normalize(v_world_xz) : vec2(0.0, -1.0);
	float sun_horiz = pow(clamp(dot(dir_xz, normalize(sdir.xz)) * 0.5 + 0.5, 0.0, 1.0), 3.0);
	float rim_mask = smoothstep(140.0, 520.0, radial) * (0.45 + 0.55 * crest);
	cloud_col = mix(cloud_col, horizon_glow_color.rgb, sun_horiz * rim_mask * 0.48);
	cloud_col += horizon_glow_color.rgb * pow(crest, 2.2) * v_sun_lit * 0.14;

	ALBEDO = cloud_col;
	ALPHA = clamp(dist_fade * opacity * smoothstep(0.14, 0.44, v_height_norm + 0.18), 0.0, 1.0);
}
