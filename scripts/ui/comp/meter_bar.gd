class_name MeterBar
extends Control
## Rounded progress / meter bar.

var value := 0.0:
	set(v):
		value = v
		queue_redraw()
var color := Color("#c9a55a")
var bg := Color(0.45, 0.28, 0.33, 0.1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := size.y * 0.5
	_rounded(Rect2(Vector2.ZERO, size), bg, r)
	if value > 0.0:
		_rounded(Rect2(Vector2.ZERO, Vector2(maxf(size.y, size.x * value), size.y)), color, r)


func _rounded(rect: Rect2, c: Color, r: float) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(int(r))
	s.anti_aliasing = true
	draw_style_box(s, rect)
