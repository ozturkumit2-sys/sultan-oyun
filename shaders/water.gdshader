shader_type spatial;
render_mode cull_disabled, shadows_disabled;
// Bosphorus water: gentle waves, sunset reflection band, sparkles.
uniform vec3 deep : source_color = vec3(0.12, 0.30, 0.42);
uniform vec3 shallow : source_color = vec3(0.24, 0.52, 0.60);
uniform vec3 sky_tint : source_color = vec3(1.0, 0.70, 0.55);
uniform vec3 sun_dir = vec3(-0.8, 0.3, 0.2);
varying vec3 wpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w = sin(wpos.x * 0.15 + TIME * 0.8) * 0.12 + sin(wpos.z * 0.21 + TIME * 1.1) * 0.1;
	VERTEX.y += w;
}

void fragment() {
	vec2 p = wpos.xz;
	float n1 = noise(p * 0.35 + vec2(TIME * 0.25, TIME * 0.1));
	float n2 = noise(p * 0.8 - vec2(TIME * 0.18, -TIME * 0.22));
	vec3 nrm = normalize(vec3((n1 - 0.5) * 0.5, 1.0, (n2 - 0.5) * 0.5));
	vec3 view = normalize(CAMERA_POSITION_WORLD - wpos);
	float fres = pow(1.0 - clamp(dot(nrm, view), 0.0, 1.0), 3.0);
	vec3 col = mix(deep, shallow, n1 * 0.5);
	col = mix(col, sky_tint, fres * 0.65);
	// sun glitter path
	vec3 sd = normalize(sun_dir);
	vec3 refl = reflect(-view, nrm);
	float g = pow(max(dot(refl, sd), 0.0), 60.0);
	float sparkle = step(0.82, noise(p * 3.0 + TIME * 0.7)) * pow(max(dot(refl, sd), 0.0), 6.0);
	col += vec3(1.0, 0.85, 0.6) * (g * 1.4 + sparkle * 0.9);
	// toon bands
	float stripes = smoothstep(0.62, 0.66, noise(p * 0.12 + vec2(0.0, TIME * 0.03))) * 0.06;
	col += stripes;
	ALBEDO = vec3(0.0);
	EMISSION = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
