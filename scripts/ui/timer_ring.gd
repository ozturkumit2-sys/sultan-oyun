class_name TimerRing
extends Control
## Dairesel geri sayım göstergesi.

var total := 120.0
var left := 120.0:
	set(v):
		left = v
		queue_redraw()
var paused := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(84, 84)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 6
	var k := clampf(left / maxf(1.0, total), 0.0, 1.0)
	var col := Color("#3ddc84") if k > 0.4 else (Color("#ffd23f") if k > 0.15 else Color("#ff4f5e"))
	draw_circle(c, r + 4, UIKit.INK, true, -1.0, true)
	draw_circle(c, r, Color("#fff7ea"), true, -1.0, true)
	if k > 0.0:
		draw_arc(c, r - 7, -PI / 2, -PI / 2 + TAU * k, 48, col, 12.0, true)
	var txt := str(int(ceil(left)))
	DrawKit.text(self, txt, c + Vector2(0, -2), 30 if left < 100 else 26, UIKit.INK)
	if paused:
		draw_rect(Rect2(c + Vector2(-9, 16), Vector2(6, 12)), UIKit.INK)
		draw_rect(Rect2(c + Vector2(3, 16), Vector2(6, 12)), UIKit.INK)
