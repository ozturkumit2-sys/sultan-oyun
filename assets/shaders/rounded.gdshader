shader_type canvas_item;
// Rounded-rectangle mask in local pixels (used for illustrated banners and portraits).
uniform vec2 rect_size = vec2(100.0, 100.0);
uniform float radius = 24.0;
uniform vec2 rect_pos = vec2(0.0, 0.0);
varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec2 h = rect_size * 0.5;
	vec2 p = abs(local_pos - rect_pos - h) - (h - vec2(radius));
	float d = length(max(p, vec2(0.0))) + min(max(p.x, p.y), 0.0) - radius;
	c.a *= clamp(0.5 - d, 0.0, 1.0);
	COLOR = c;
}
