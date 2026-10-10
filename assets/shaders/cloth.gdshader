shader_type spatial;
// Kumaş: dinlenme pozundaki konumdan üç düzlemli desen (dikişsiz), astar rengi, ipek parlaklığı
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D patterns : filter_linear_mipmap, repeat_enable;
uniform sampler2D weave : filter_linear_mipmap, repeat_enable;
uniform vec3 base_color : source_color = vec3(0.5, 0.1, 0.1);
uniform vec3 pattern_color : source_color = vec3(0.8, 0.65, 0.3);
uniform vec3 lining_color : source_color = vec3(0.75, 0.7, 0.6);
uniform vec4 pattern_sel = vec4(0.0);      // R lale ağı, G çintemani, B kutnu çizgi, A yıldız
uniform float pattern_scale = 3.0;         // metre başına tekrar
uniform float roughness = 0.75;
uniform float sheen = 0.25;
uniform float metallic_pattern = 0.0;      // sırma (altın tel) desen

varying vec3 rest_pos;
varying vec3 rest_nrm;

void vertex() {
	rest_pos = CUSTOM0.xyz;
	rest_nrm = CUSTOM1.xyz;
}

vec4 tri(sampler2D t, vec3 p, vec3 w) {
	return texture(t, p.zy) * w.x + texture(t, p.xz) * w.y + texture(t, vec2(p.x, -p.y)) * w.z;
}

void fragment() {
	vec3 w = pow(abs(rest_nrm) + 0.001, vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 p = rest_pos * pattern_scale;
	vec4 pm = tri(patterns, p, w);
	float m = clamp(dot(pm, pattern_sel), 0.0, 1.0);
	float wv = tri(weave, rest_pos * 9.0, w).r;
	vec3 c = mix(base_color, pattern_color, m);
	c *= mix(0.9, 1.08, wv);
	if (!FRONT_FACING) {
		c = lining_color * mix(0.85, 1.0, wv);
	}
	ALBEDO = c;
	METALLIC = m * metallic_pattern;
	ROUGHNESS = clamp(roughness + (wv - 0.5) * 0.15 - m * metallic_pattern * 0.35, 0.05, 1.0);
	SPECULAR = 0.4;
	RIM = sheen;
	RIM_TINT = 0.7;
}
