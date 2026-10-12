class_name PartitionView
extends Node2D
## A low glass partition panel standing on one cell edge.

const H := 46.0
var a: Vector2
var b: Vector2


func setup(p: Array) -> void:
	if p[0] == "v":
		a = Vector2(p[1], p[2])
		b = Vector2(p[1], p[2] + 1)
	else:
		a = Vector2(p[1], p[2])
		b = Vector2(p[1] + 1, p[2])
	position = Iso.to_screen((a + b) * 0.5)


func _draw() -> void:
	var off := -position
	var pa := Iso.P(a.x, a.y) + off
	var pb := Iso.P(b.x, b.y) + off
	var up := Vector2(0, -H)
	# glass
	draw_colored_polygon(PackedVector2Array([pa + Vector2(0, -6), pb + Vector2(0, -6), pb + up, pa + up]), Color(0.78, 0.9, 0.97, 0.38))
	# frosted band
	draw_colored_polygon(PackedVector2Array([pa + Vector2(0, -20), pb + Vector2(0, -20), pb + Vector2(0, -28), pa + Vector2(0, -28)]), Color(1, 1, 1, 0.35))
	# shine
	var m := pa.lerp(pb, 0.3)
	draw_line(m + Vector2(0, -10), m + Vector2(6, -40), Color(1, 1, 1, 0.5), 1.5, true)
	# base strip + frame
	Iso.poly(self, PackedVector2Array([pa, pb, pb + Vector2(0, -6), pa + Vector2(0, -6)]), Color("aeb7c2"), Iso.INK_SOFT)
	draw_line(pa + up, pb + up, Color("8d99ae"), 2.4, true)
	draw_line(pa, pa + up, Color("8d99ae"), 2.0, true)
	draw_line(pb, pb + up, Color("8d99ae"), 2.0, true)
