class_name Glow
extends Control
## Soft radial light (behind bottles, highlights).

var color := Color("#fff4dc")
var strength := 0.6


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	for i in 14:
		draw_circle(c, r * (1.0 - i * 0.068), Color(color, strength * 0.075))
