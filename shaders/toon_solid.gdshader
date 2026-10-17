shader_type spatial;
// Generic toon shading. Albedo = color uniform * vertex colour (if use_vertex).
uniform vec3 color : source_color = vec3(1.0);
uniform float use_vertex = 0.0;
uniform vec3 shade_color : source_color = vec3(0.42, 0.30, 0.55);
uniform float rim_strength = 0.25;
uniform float gloss = 0.0;          // toon specular blob (eyes, glossy plastics)
uniform float emission_amount = 0.0;
uniform float flash = 0.0;

void fragment() {
	vec3 c = color;
	if (use_vertex > 0.5) {
		c *= COLOR.rgb;
	}
	ALBEDO = mix(c, vec3(1.0), flash);
	EMISSION = c * emission_amount;
	ROUGHNESS = 0.8;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.02, 0.10, ndl) * ATTENUATION * mix(0.62, 1.0, smoothstep(0.08, 0.55, ndl));
	vec3 shade = mix(shade_color * 0.55, vec3(1.0), lit);
	DIFFUSE_LIGHT += shade * LIGHT_COLOR / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	rim = smoothstep(0.3, 0.55, rim) * rim_strength * clamp(ndl + 0.6, 0.0, 1.0);
	DIFFUSE_LIGHT += rim * LIGHT_COLOR / PI;
	if (gloss > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.92, 0.95, dot(NORMAL, h)) * lit;
		SPECULAR_LIGHT += s * gloss * LIGHT_COLOR;
	}
}
