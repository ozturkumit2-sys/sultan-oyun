class_name ProgressBarDraw
extends Control
## Yuvarlatılmış, konturlu ilerleme çubuğu.

var value := 0.0:
	set(v):
		value = v
		queue_redraw()
var max_value := 100.0
var color := Color("#3ddc84")
var back := Color("#e8d6bd")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := size.y * 0.5
	var rect := Rect2(Vector2.ZERO, size)
	DrawKit.fill(self, DrawKit.rrect(rect, r), back)
	var k := clampf(value / maxf(0.0001, max_value), 0.0, 1.0)
	if k > 0.0:
		var w := maxf(size.y, size.x * k)
		DrawKit.fill(self, DrawKit.rrect(Rect2(Vector2.ZERO, Vector2(w, size.y)), r), color, 0.2)
		DrawKit.fill(self, DrawKit.rrect(Rect2(Vector2(r * 0.5, size.y * 0.18), Vector2(maxf(0, w - r), size.y * 0.22)), size.y * 0.11), Color(1, 1, 1, 0.35))
	DrawKit.outline(self, DrawKit.rrect(rect, r), Color("#3b2417"), 3.0)
