shader_type spatial;
// Gerçekçi ten: paylaşılan detay + maske dokuları, karakter başına renk parametreleri
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D detail : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D masks : filter_linear_mipmap, repeat_disable;
uniform vec3 skin_color : source_color = vec3(0.80, 0.62, 0.50);
uniform vec3 hair_color : source_color = vec3(0.10, 0.07, 0.05);
uniform vec3 lip_color : source_color = vec3(0.62, 0.32, 0.30);
uniform float stubble = 0.0;      // 0 = tıraşlı, 1 = koyu sakal gölgesi
uniform float brow = 1.0;
uniform float scalp_shadow = 0.0; // tıraşlı kafada saç kökü gölgesi
uniform float age = 0.0;          // 0..1: yaşlılıkta daha mat ve hafif solgun

void fragment() {
	vec3 d = texture(detail, UV).rgb * 1.2;
	vec4 m = texture(masks, UV);
	vec3 c = skin_color * d;
	c = mix(c, mix(skin_color, lip_color, 0.6) * d, m.b * 0.6);
	c = mix(c, c * mix(vec3(1.0), hair_color * 2.2 + 0.25, 0.55), m.g * stubble);
	c = mix(c, c * (hair_color * 2.0 + 0.4), m.a * scalp_shadow);
	c = mix(c, hair_color, clamp(m.r * brow * 1.3, 0.0, 1.0));
	c = mix(c, c * vec3(0.97, 0.96, 0.96), age * 0.4);
	ALBEDO = c;
	ROUGHNESS = mix(0.58, 0.42, m.b) + age * 0.08;
	SPECULAR = 0.32;
	// ince deri: ışığın arkadan sızması (SSS benzetimi)
	BACKLIGHT = skin_color * vec3(0.55, 0.22, 0.15) * 0.35;
	RIM = 0.15;
	RIM_TINT = 0.6;
}
