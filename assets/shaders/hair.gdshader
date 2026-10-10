shader_type spatial;
// Saç: dikey tel dokusu (opak), anizotropik parlamaya benzer ışık şeridi
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 hair_color : source_color = vec3(0.08, 0.05, 0.03);
uniform sampler2D strands : filter_linear_mipmap, repeat_enable;

varying vec3 rest_pos;

void vertex() {
	rest_pos = CUSTOM0.xyz;
}

void fragment() {
	vec2 uv = vec2(atan(rest_pos.x, rest_pos.z + 0.02) * 1.6, rest_pos.y * 0.25);
	float s = texture(strands, uv).r;
	float s2 = texture(strands, uv * vec2(2.7, 0.6) + 0.37).r;
	ALBEDO = hair_color * mix(0.55, 1.35, s * 0.6 + s2 * 0.4);
	ROUGHNESS = 0.5;
	SPECULAR = 0.55;
	RIM = 0.3;
	RIM_TINT = 0.8;
}
