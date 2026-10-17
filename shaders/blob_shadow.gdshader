shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float alpha = 0.5;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = (1.0 - smoothstep(0.55, 1.0, d)) * alpha;
	ALBEDO = vec3(0.16, 0.08, 0.14);
	ALPHA = a;
}
