shader_type spatial;
// Coat colours come from uniforms; vertex colour channels are masks (G = stripe, B = white).
uniform vec3 base_color : source_color = vec3(0.95, 0.58, 0.24);
uniform vec3 stripe_color : source_color = vec3(0.78, 0.36, 0.12);
uniform vec3 white_color : source_color = vec3(1.0, 0.96, 0.9);
uniform vec3 shade_color : source_color = vec3(0.42, 0.30, 0.55);
uniform float rim_strength = 0.55;
uniform float flash = 0.0;          // white hit flash
uniform float use_masks = 1.0;      // 0 -> plain base colour

void fragment() {
	vec3 c = base_color;
	if (use_masks > 0.5) {
		float st = smoothstep(0.3, 0.6, COLOR.g);
		float wh = smoothstep(0.35, 0.65, COLOR.b);
		c = mix(base_color, stripe_color, st);
		c = mix(c, white_color, wh);
	}
	ALBEDO = mix(c, vec3(1.0), flash);
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.02, 0.10, ndl) * ATTENUATION * mix(0.62, 1.0, smoothstep(0.08, 0.55, ndl));
	vec3 shade = mix(shade_color * 0.55, vec3(1.0), lit);
	DIFFUSE_LIGHT += shade * LIGHT_COLOR / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	rim = smoothstep(0.25, 0.5, rim) * rim_strength * clamp(ndl + 0.6, 0.0, 1.0);
	DIFFUSE_LIGHT += rim * LIGHT_COLOR / PI;
}
