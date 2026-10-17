shader_type spatial;
render_mode cull_disabled;
// Laundry / awning cloth: vertex colour albedo, sways in the breeze (UV.y = 0 at the line).
uniform float sway = 0.12;
uniform vec3 shade_color : source_color = vec3(0.42, 0.30, 0.58);

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float k = UV.y;
	VERTEX.x += sin(TIME * 2.3 + w.x * 0.9 + w.z * 0.7) * sway * k;
	VERTEX.z += cos(TIME * 1.9 + w.x * 0.6) * sway * k;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = abs(dot(NORMAL, LIGHT));
	float lit = smoothstep(-0.02, 0.12, ndl) * ATTENUATION * mix(0.6, 1.0, smoothstep(0.08, 0.55, ndl));
	DIFFUSE_LIGHT += mix(shade_color * 0.6, vec3(1.0), lit) * LIGHT_COLOR / PI;
}
