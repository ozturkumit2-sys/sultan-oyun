shader_type sky;
// Stylised İstanbul sunset: banded gradient, soft sun with halo, drifting toon clouds.
uniform vec3 top_color : source_color = vec3(0.22, 0.24, 0.52);
uniform vec3 mid_color : source_color = vec3(0.93, 0.52, 0.55);
uniform vec3 horizon_color : source_color = vec3(1.0, 0.78, 0.45);
uniform vec3 below_color : source_color = vec3(0.55, 0.42, 0.55);
uniform vec3 sun_color : source_color = vec3(1.0, 0.86, 0.55);
uniform vec3 cloud_color : source_color = vec3(1.0, 0.72, 0.68);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.42, 0.62);
uniform float sun_size = 0.035;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col;
	if (h > 0.0) {
		float t1 = smoothstep(0.0, 0.18, h);
		float t2 = smoothstep(0.12, 0.65, h);
		col = mix(horizon_color, mid_color, t1);
		col = mix(col, top_color, t2);
	} else {
		col = mix(horizon_color, below_color, smoothstep(0.0, -0.2, h));
	}
	vec3 sd = LIGHT0_DIRECTION;
	float sdot = dot(d, sd);
	float sun = smoothstep(1.0 - sun_size * 0.06, 1.0 - sun_size * 0.04, sdot);
	float halo = pow(max(sdot, 0.0), 24.0) * 0.6 + pow(max(sdot, 0.0), 4.0) * 0.18;
	col += sun_color * halo;
	// clouds on a flat layer
	if (h > 0.01) {
		vec2 uv = d.xz / (h + 0.08) * 0.9;
		uv.x += TIME * 0.004;
		float n = fbm(uv * 1.4);
		float c = smoothstep(0.52, 0.62, n) * smoothstep(0.01, 0.12, h) * (1.0 - smoothstep(0.35, 0.7, h));
		float lit = smoothstep(0.45, 0.75, fbm(uv * 1.4 + vec2(0.06, 0.02)) - n + 0.6);
		vec3 cc = mix(cloud_shade, cloud_color, lit) + sun_color * pow(max(sdot, 0.0), 6.0) * 0.4;
		col = mix(col, cc, c * 0.85);
	}
	col = mix(col, sun_color * 1.6, sun);
	COLOR = col;
}
