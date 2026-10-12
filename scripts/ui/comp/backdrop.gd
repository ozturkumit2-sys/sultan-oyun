class_name Backdrop
extends Control
## Subtle luxurious background glow.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := Vector2(size.x * 0.85, size.y * 0.08)
	for i in 14:
		var r := size.x * (0.9 - i * 0.055)
		draw_circle(c, r, Color(0.79, 0.65, 0.35, 0.012))
	var c2 := Vector2(size.x * 0.05, size.y * 0.9)
	for i in 10:
		draw_circle(c2, size.x * (0.6 - i * 0.05), Color(0.6, 0.35, 0.5, 0.012))
