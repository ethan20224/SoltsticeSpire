shader_type sky;

uniform vec4 zenith_color : source_color = vec4(0.16, 0.44, 0.78, 1.0);
uniform vec4 mid_sky_color : source_color = vec4(0.45, 0.72, 0.94, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.98, 0.86, 0.68, 1.0);
uniform vec4 abyss_color : source_color = vec4(0.70, 0.78, 0.88, 1.0);

uniform vec4 sun_color : source_color = vec4(1.0, 0.94, 0.76, 1.0);
uniform float sun_size : hint_range(0.005, 0.15) = 0.042;
uniform float sun_halo_strength : hint_range(0.0, 2.5) = 0.85;

uniform vec4 cloud_lit_color : source_color = vec4(1.0, 0.96, 0.90, 1.0);
uniform vec4 cloud_shadow_color : source_color = vec4(0.58, 0.66, 0.82, 1.0);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.46;

uniform float star_intensity : hint_range(0.0, 1.5) = 0.0;
uniform float aurora_intensity : hint_range(0.0, 1.5) = 0.0;
uniform vec4 aurora_color_a : source_color = vec4(0.20, 0.92, 0.78, 1.0);
uniform vec4 aurora_color_b : source_color = vec4(0.66, 0.35, 0.98, 1.0);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = rot * p * 2.02 + vec2(13.1, 7.4);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = dir.y;

	// Rich 4-stop Painterly Little Prince / Astro Bot sky dome gradient
	vec3 col;
	if (h >= 0.0) {
		float t_low = smoothstep(0.0, 0.28, h);
		float t_high = smoothstep(0.20, 0.84, h);
		col = mix(horizon_color.rgb, mid_sky_color.rgb, t_low);
		col = mix(col, zenith_color.rgb, t_high);
	} else {
		float t_down = smoothstep(0.0, -0.48, h);
		col = mix(horizon_color.rgb, abyss_color.rgb, t_down);
	}

	if (AT_CUBEMAP_PASS) {
		COLOR = col;
	} else {
		// Stylized sun disk & warm atmospheric Mie scatter glow
		vec3 sun_dir = normalize(LIGHT0_DIRECTION);
		float sun_dot = max(dot(dir, sun_dir), 0.0);
		float halo = pow(sun_dot, 5.0) * 0.44 + pow(sun_dot, 28.0) * 0.72;
		col += sun_color.rgb * halo * sun_halo_strength;
		// Warm golden horizon haze band on the sun-facing side
		float horiz_band = exp(-abs(h) * 8.5) * (0.35 + 0.65 * pow(sun_dot, 2.0));
		col = mix(col, mix(horizon_color.rgb, sun_color.rgb, 0.45), horiz_band * 0.28);
		float disk = smoothstep(1.0 - sun_size * 0.055, 1.0 - sun_size * 0.025, sun_dot);
		col = mix(col, sun_color.rgb * 2.5, disk);

		// Painterly high-altitude drifting cloud bands above horizon
		if (h > 0.02 && cloud_coverage > 0.01) {
			vec2 cuv = dir.xz / (h + 0.24) * 1.45 + vec2(TIME * 0.012, TIME * 0.006);
			float n = fbm(cuv);
			float c_mask = smoothstep(1.0 - cloud_coverage, 1.0 - cloud_coverage + 0.22, n);
			c_mask *= smoothstep(0.02, 0.14, h) * (1.0 - smoothstep(0.55, 0.92, h));
			float sun_rim = pow(sun_dot, 3.0) * 0.55 + 0.45;
			vec3 c_col = mix(cloud_shadow_color.rgb, cloud_lit_color.rgb, clamp(sun_rim * 0.72 + n * 0.48, 0.0, 1.0));
			c_col += sun_color.rgb * pow(sun_dot, 5.0) * 0.24;
			col = mix(col, c_col, c_mask * 0.80);
		}

		// Ethereal Aurora Ribbons (World 5 & 6)
		if (aurora_intensity > 0.01 && h > 0.06) {
			vec2 auv = dir.xz / (h + 0.35) * 2.1;
			float wave = sin(auv.x * 2.6 + TIME * 0.28 + fbm(auv * 0.8) * 3.5);
			float band = smoothstep(0.55, 0.96, abs(wave)) * smoothstep(0.08, 0.30, h) * (1.0 - smoothstep(0.58, 0.90, h));
			vec3 acol = mix(aurora_color_a.rgb, aurora_color_b.rgb, fbm(auv + vec2(0.0, TIME * 0.05)));
			col += acol * band * aurora_intensity * 0.9;
		}

		// Crisp High-Altitude Stars (World 5 & 6)
		if (star_intensity > 0.01 && h > 0.05) {
			vec2 suv = floor(dir.xz / (h + 0.35) * 165.0);
			float s = hash21(suv);
			if (s > 0.992) {
				float twinkle = 0.6 + 0.4 * sin(TIME * (2.5 + fract(s * 97.0) * 4.0) + s * 100.0);
				col += vec3(1.0, 0.96, 0.88) * twinkle * star_intensity * smoothstep(0.05, 0.35, h) * 1.4;
			}
		}

		COLOR = col;
	}
}
