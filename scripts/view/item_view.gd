class_name ItemView
extends Node2D
## A small movable belonging (glasses, USB stick, mug, planner, charger).

var item := ""
var w: SimWorld
var z := 0.0
var t := 0.0
var highlight := false


func setup(it: String, world: SimWorld) -> void:
	item = it
	w = world
	refresh()


func refresh() -> void:
	var loc: String = w.office.items[item]["at"]
	var sp := OfficeLayout.item_spot(loc)
	# spread multiple items on one spot a little
	var idx := w.office.items_at(loc).find(item)
	var jitter := Vector2(0.12 * idx, -0.1 * idx)
	position = Iso.to_screen(Vector2(sp[0], sp[1]) + jitter) + Vector2(0, 2)
	z = sp[2]
	queue_redraw()


func anchor() -> Vector2:
	return position + Vector2(0, -z - 4)


func _process(delta: float) -> void:
	t += delta
	if highlight:
		queue_redraw()


func _draw() -> void:
	var p := Vector2(0, -z - 2)
	if highlight:
		draw_circle(p + Vector2(0, -3), 11 + sin(t * 6) * 2, Color(1, 0.85, 0.2, 0.35))
	match item:
		"glasses":
			for k in [-1, 1]:
				Iso.ellipse(self, p + Vector2(k * 4.5, -2), 3.6, 2.6, Color(0.8, 0.92, 1.0, 0.8), Color("3b3346"), 1.4)
			draw_line(p + Vector2(-1, -2), p + Vector2(1, -2), Color("3b3346"), 1.4)
		"usb":
			Iso.rrect(self, Rect2(p + Vector2(-5, -5), Vector2(10, 5)), 1.5, Color("e63946"))
			draw_rect(Rect2(p + Vector2(5, -4), Vector2(3.5, 3)), Color("c0c4cc"))
		"mug":
			Iso.rrect(self, Rect2(p + Vector2(-4.5, -10), Vector2(9, 10)), 2, Color("f6c85f"))
			draw_arc(p + Vector2(5, -5), 3, -PI * 0.5, PI * 0.5, 6, Iso.INK, 1.4)
			draw_circle(p + Vector2(0, -5), 1.8, Color("e63946"))
		"planner":
			Iso.poly(self, PackedVector2Array([p + Vector2(-8, -2), p + Vector2(2, -7), p + Vector2(9, -3), p + Vector2(-1, 2)]), Color("2a9d8f"))
			Iso.poly(self, PackedVector2Array([p + Vector2(-8, -4), p + Vector2(2, -9), p + Vector2(9, -5), p + Vector2(-1, 0)]), Color("3fb8a8"))
		"charger":
			Iso.rrect(self, Rect2(p + Vector2(-5, -6), Vector2(8, 6)), 1.5, Color("eeeeee"))
			draw_polyline(PackedVector2Array([p + Vector2(3, -3), p + Vector2(8, -1), p + Vector2(6, 3), p + Vector2(10, 4)]), Color("eeeeee"), 1.6, true)
