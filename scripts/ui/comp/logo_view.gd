class_name LogoView
extends Control
## Brand monogram in six styles.

var style := 0
var text := "PE"
var color := Color("#c9a55a")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(st: int, name: String, col: Color) -> LogoView:
	style = st
	color = col
	var parts := name.strip_edges().split(" ", false)
	text = ""
	for p in parts:
		if text.length() < 2 and p.length() > 0 and p[0] == p[0].to_upper():
			text += p[0]
	if text == "" and name.length() > 0:
		text = name.substr(0, 1).to_upper()
	queue_redraw()
	return self


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var r := s * 0.46
	var w := maxf(1.5, s * 0.03)
	match style % 6:
		0:
			draw_arc(c, r, 0, TAU, 48, color, w, true)
		1:
			draw_polyline(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0), c + Vector2(0, -r)]), color, w, true)
		2:
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.85), c + Vector2(r * 0.8, -r * 0.85), c + Vector2(r * 0.8, r * 0.1), c + Vector2(0, r), c + Vector2(-r * 0.8, r * 0.1), c + Vector2(-r * 0.8, -r * 0.85)]), color, w, true)
		3:
			draw_arc(c, r, 0, TAU, 48, color, w, true)
			draw_arc(c, r * 0.84, 0, TAU, 48, color, w * 0.6, true)
		4:
			for k in 5:
				draw_arc(c + Vector2(0, r * 0.6), r * (0.5 + k * 0.12), PI * 1.15, PI * 1.85, 12, Color(color, 0.35 + k * 0.1), w * 0.6, true)
		5:
			draw_line(c + Vector2(-r, r * 0.75), c + Vector2(r, r * 0.75), color, w, true)
	var f := UI.font("title_bold")
	var fs := int(s * (0.42 if text.length() > 1 else 0.52))
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, c + Vector2(-tw * 0.5, fs * 0.34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
