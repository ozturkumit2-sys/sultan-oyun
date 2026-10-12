class_name HintLayer
extends Node2D
## Soft pulsing sparkles marking things the player can meddle with.

var anchors: Array = []     # world positions
var strength := 1.0
var t := 0.0


func _ready() -> void:
	z_index = 45


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	if strength <= 0.01:
		return
	for i in anchors.size():
		var p: Vector2 = anchors[i]
		var ph := t * 2.2 + i * 0.9
		var a := (0.35 + 0.35 * sin(ph)) * strength
		var s := 4.0 + 1.5 * sin(ph)
		var pts := PackedVector2Array()
		for k in 8:
			var r := s if k % 2 == 0 else s * 0.38
			var ang := PI * 0.25 * k + t * 0.6
			pts.append(p + Vector2(cos(ang), sin(ang)) * r)
		draw_colored_polygon(pts, Color(1, 0.97, 0.75, a))
		draw_circle(p, s * 0.45, Color(1, 1, 1, a))
