shader_type spatial;
render_mode unshaded, cull_disabled;
// Swirling "doorway" into a level. locked=1 makes it a dim, slowly drifting stone grey.
uniform vec3 col_a : source_color = vec3(0.15, 0.66, 0.63);
uniform vec3 col_b : source_color = vec3(0.98, 0.78, 0.36);
uniform vec3 col_c : source_color = vec3(0.12, 0.31, 0.61);
uniform float locked = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 p = UV - vec2(0.5, 0.55);
	float r = length(p);
	float a = atan(p.y, p.x);
	float t = TIME * (locked > 0.5 ? 0.15 : 0.6);
	float sw = sin(a * 3.0 + r * 14.0 - t * 4.0) * 0.5 + 0.5;
	float n = noise(vec2(a * 2.0 + t, r * 6.0 - t * 2.0));
	vec3 c = mix(col_c, col_a, sw);
	c = mix(c, col_b, smoothstep(0.55, 0.9, n) * (1.0 - r * 1.2));
	c += vec3(1.0, 0.9, 0.7) * smoothstep(0.18, 0.0, r) * 0.6;
	if (locked > 0.5) {
		float g = dot(c, vec3(0.33));
		c = mix(vec3(g), vec3(0.35, 0.33, 0.38), 0.6);
	}
	ALBEDO = c;
}
