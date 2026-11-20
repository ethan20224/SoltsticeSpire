shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 crest_color : source_color = vec4(0.98, 0.88, 0.72, 1.0);
uniform vec4 valley_color : source_color = vec4(0.42, 0.56, 0.76, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.86, 0.54, 1.0);
uniform vec3 sun_dir = vec3(0.35, 0.78, 0.42);

varying vec3 v_world_normal;
varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// Painterly Ghibli cumulus cloud: warm sunlit crest, cool sky-translucent valley (never brown mud!),
	// plus a luminous backlit solar rim so clouds look airy from both below AND Summit Lookdown!
	vec3 s_dir = normalize(sun_dir);
	float up_grad = smoothstep(-0.55, 0.65, v_world_normal.y * 0.75 + dot(v_world_normal, s_dir) * 0.45);
	vec3 base = mix(valley_color.rgb, crest_color.rgb, up_grad);

	float ndotv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = pow(1.0 - ndotv, 2.2);
	float sun_rim = clamp(dot(v_world_normal, s_dir) * 0.5 + 0.5, 0.0, 1.0);

	ALBEDO = base;
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
	// Self-illuminated atmospheric scattering keeps valley soft sky-hued instead of dark shadow mud!
	EMISSION = base * 0.36 + rim_color.rgb * fres * (0.32 + 0.36 * sun_rim);
}

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float wrap = clamp((ndotl + 0.55) / 1.55, 0.32, 1.0);
	DIFFUSE_LIGHT += ALBEDO * (LIGHT_COLOR / 3.14159265) * wrap * 0.68;
}
