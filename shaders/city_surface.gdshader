shader_type spatial;
// One shader for all procedural city surfaces; the look is chosen per vertex
// (COLOR.a * 10): 0 plaster, 1 roof tiles, 2 stone, 3 cobbles, 4 wood, 5 plain, 6 glass, 7 terrace tiles
uniform int force_pattern = -1;
varying float v_gloss;
uniform vec3 shade_color : source_color = vec3(0.42, 0.30, 0.58);
uniform float rim_strength = 0.12;
uniform float gloss = 0.0;
uniform float far_fade = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec3 c = COLOR.rgb;
	vec2 uv = UV;
	int pattern = force_pattern >= 0 ? force_pattern : int(COLOR.a * 10.0 + 0.5);
	v_gloss = pattern == 6 ? 0.9 : 0.0;
	if (pattern == 0) {
		float n = noise(uv * 1.7) * 0.6 + noise(uv * 6.0) * 0.4;
		c *= 0.93 + n * 0.12;
	} else if (pattern == 1) {
		// rows of barrel tiles: uv.y runs down the slope
		vec2 t = uv * vec2(2.6, 3.2);
		float aa = smoothstep(0.25, 0.7, length(fwidth(t)));
		float row = floor(t.y);
		t.x += mod(row, 2.0) * 0.5;
		vec2 f = fract(t);
		float edge = smoothstep(0.0, 0.12, f.y) * (0.75 + 0.25 * smoothstep(0.0, 0.5, f.y));
		float bump = 0.82 + 0.18 * sin(f.x * 3.14159);
		float var = 0.9 + 0.2 * hash(vec2(floor(t.x), row));
		c *= mix(edge * bump * var, 0.8, aa);
	} else if (pattern == 2) {
		vec2 t = uv * vec2(1.1, 2.2);
		float aa = smoothstep(0.25, 0.7, length(fwidth(t)));
		float row = floor(t.y);
		t.x += mod(row, 2.0) * 0.5;
		vec2 f = fract(t);
		float m = smoothstep(0.0, 0.05, f.x) * smoothstep(1.0, 0.95, f.x) * smoothstep(0.0, 0.08, f.y) * smoothstep(1.0, 0.92, f.y);
		float var = 0.88 + 0.22 * hash(floor(t));
		c *= mix(mix(0.62, var, m), 0.9, aa);
	} else if (pattern == 3) {
		vec2 t = uv * 2.4;
		float aa = smoothstep(0.25, 0.7, length(fwidth(t)));
		float row = floor(t.y);
		t.x += mod(row, 2.0) * 0.5;
		vec2 f = fract(t) - 0.5;
		float d = length(f * vec2(1.0, 1.25));
		float m = smoothstep(0.5, 0.36, d);
		float var = 0.85 + 0.25 * hash(floor(t));
		c *= mix(mix(0.55, var, m), 0.82, aa);
	} else if (pattern == 7) {
		vec2 t = uv * 1.6;
		float aa = smoothstep(0.15, 0.5, length(fwidth(t)));
		vec2 f = fract(t);
		float m = smoothstep(0.0, 0.04, f.x) * smoothstep(1.0, 0.96, f.x) * smoothstep(0.0, 0.04, f.y) * smoothstep(1.0, 0.96, f.y);
		float var = 0.92 + 0.12 * hash(floor(t));
		c *= mix(mix(0.78, var, m), 0.95, aa);
	} else if (pattern == 4) {
		vec2 t = uv * vec2(0.5, 4.0);
		float aa = smoothstep(0.25, 0.7, fwidth(t.y));
		float f = fract(t.y);
		float m = smoothstep(0.0, 0.08, f) * smoothstep(1.0, 0.92, f);
		float grain = 0.9 + 0.1 * sin(uv.x * 9.0 + noise(uv * vec2(1.0, 8.0)) * 4.0);
		c *= mix(mix(0.6, grain, m), 0.85, aa);
	}
	ALBEDO = c;
	ROUGHNESS = 0.9;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.02, 0.12, ndl) * ATTENUATION * mix(0.6, 1.0, smoothstep(0.08, 0.55, ndl));
	vec3 shade = mix(shade_color * 0.6, vec3(1.0), lit);
	DIFFUSE_LIGHT += shade * LIGHT_COLOR / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	DIFFUSE_LIGHT += rim * rim_strength * LIGHT_COLOR / PI * clamp(ndl + 0.5, 0.0, 1.0);
	float g = max(gloss, v_gloss);
	if (g > 0.0) {
		vec3 h = normalize(LIGHT + VIEW);
		SPECULAR_LIGHT += smoothstep(0.9, 0.94, dot(NORMAL, h)) * g * LIGHT_COLOR * lit;
	}
}
