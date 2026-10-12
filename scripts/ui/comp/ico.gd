class_name Ico
extends Control
## Small vector icons drawn in code (no image assets needed).

var kind := "home":
	set(v):
		kind = v
		queue_redraw()
var color := Color("#c9a55a"):
	set(v):
		color = v
		queue_redraw()
var badge := 0:
	set(v):
		badge = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var w := maxf(2.0, s * 0.075)
	var c := color
	var P := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	match kind:
		"home":
			draw_polyline(PackedVector2Array([P.call(0.15, 0.5), P.call(0.5, 0.18), P.call(0.85, 0.5)]), c, w, true)
			draw_polyline(PackedVector2Array([P.call(0.25, 0.42), P.call(0.25, 0.85), P.call(0.75, 0.85), P.call(0.75, 0.42)]), c, w, true)
			draw_rect(Rect2(P.call(0.43, 0.6), Vector2(0.14, 0.25) * s), c, false, w)
		"lab":
			draw_polyline(PackedVector2Array([P.call(0.38, 0.12), P.call(0.38, 0.42), P.call(0.16, 0.84), P.call(0.84, 0.84), P.call(0.62, 0.42), P.call(0.62, 0.12)]), c, w, true)
			draw_line(P.call(0.3, 0.12), P.call(0.7, 0.12), c, w, true)
			draw_colored_polygon(PackedVector2Array([P.call(0.27, 0.64), P.call(0.73, 0.64), P.call(0.84, 0.84), P.call(0.16, 0.84)]), Color(c, 0.5))
		"bottle":
			draw_rect(Rect2(P.call(0.42, 0.1), Vector2(0.16, 0.14) * s), c, true)
			draw_rect(Rect2(P.call(0.46, 0.24), Vector2(0.08, 0.08) * s), c, true)
			var r := Rect2(P.call(0.22, 0.32), Vector2(0.56, 0.56) * s)
			draw_rect(r, c, false, w)
			draw_rect(Rect2(P.call(0.32, 0.5), Vector2(0.36, 0.2) * s), Color(c, 0.6), true)
		"company":
			draw_rect(Rect2(P.call(0.18, 0.3), Vector2(0.36, 0.56) * s), c, false, w)
			draw_rect(Rect2(P.call(0.54, 0.48), Vector2(0.28, 0.38) * s), c, false, w)
			for i in 3:
				draw_rect(Rect2(P.call(0.27, 0.38 + i * 0.14), Vector2(0.06, 0.06) * s), c, true)
				draw_rect(Rect2(P.call(0.39, 0.38 + i * 0.14), Vector2(0.06, 0.06) * s), c, true)
			draw_line(P.call(0.1, 0.86), P.call(0.9, 0.86), c, w, true)
		"finance":
			draw_polyline(PackedVector2Array([P.call(0.12, 0.72), P.call(0.36, 0.48), P.call(0.54, 0.6), P.call(0.86, 0.26)]), c, w * 1.2, true)
			draw_polyline(PackedVector2Array([P.call(0.68, 0.26), P.call(0.86, 0.26), P.call(0.86, 0.44)]), c, w * 1.2, true)
			draw_line(P.call(0.12, 0.86), P.call(0.88, 0.86), c, w, true)
		"globe":
			draw_arc(P.call(0.5, 0.5), s * 0.36, 0, TAU, 40, c, w, true)
			draw_line(P.call(0.14, 0.5), P.call(0.86, 0.5), c, w * 0.8, true)
			draw_arc(P.call(0.5, 0.5), s * 0.36, -PI / 2, PI / 2, 20, c, w * 0.8, true)
			var pts := PackedVector2Array()
			for i in 21:
				var a := -PI / 2 + PI * float(i) / 20.0
				pts.append(P.call(0.5, 0.5) + Vector2(cos(a) * s * 0.16, sin(a) * s * 0.36))
			draw_polyline(pts, c, w * 0.8, true)
		"users":
			draw_circle(P.call(0.38, 0.36), s * 0.12, c)
			draw_arc(P.call(0.38, 0.86), s * 0.26, PI, TAU, 20, c, w * 1.4, true)
			draw_circle(P.call(0.68, 0.32), s * 0.09, Color(c, 0.7))
			draw_arc(P.call(0.7, 0.74), s * 0.2, PI * 1.05, TAU * 0.98, 16, Color(c, 0.7), w * 1.2, true)
		"megaphone":
			draw_colored_polygon(PackedVector2Array([P.call(0.18, 0.42), P.call(0.66, 0.2), P.call(0.66, 0.8), P.call(0.18, 0.58)]), c)
			draw_line(P.call(0.3, 0.6), P.call(0.36, 0.84), c, w * 1.4, true)
			draw_arc(P.call(0.7, 0.5), s * 0.18, -0.9, 0.9, 10, c, w, true)
		"cog":
			draw_arc(P.call(0.5, 0.5), s * 0.22, 0, TAU, 30, c, w * 1.4, true)
			for i in 8:
				var a := TAU * float(i) / 8.0
				draw_line(P.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.28, P.call(0.5, 0.5) + Vector2(cos(a), sin(a)) * s * 0.4, c, w * 1.6, true)
		"back":
			draw_polyline(PackedVector2Array([P.call(0.62, 0.18), P.call(0.3, 0.5), P.call(0.62, 0.82)]), c, w * 1.3, true)
		"next":
			draw_colored_polygon(PackedVector2Array([P.call(0.3, 0.2), P.call(0.78, 0.5), P.call(0.3, 0.8)]), c)
		"plus":
			draw_line(P.call(0.5, 0.18), P.call(0.5, 0.82), c, w * 1.3, true)
			draw_line(P.call(0.18, 0.5), P.call(0.82, 0.5), c, w * 1.3, true)
		"minus":
			draw_line(P.call(0.18, 0.5), P.call(0.82, 0.5), c, w * 1.3, true)
		"check":
			draw_polyline(PackedVector2Array([P.call(0.18, 0.52), P.call(0.42, 0.76), P.call(0.84, 0.26)]), c, w * 1.4, true)
		"close":
			draw_line(P.call(0.22, 0.22), P.call(0.78, 0.78), c, w * 1.3, true)
			draw_line(P.call(0.78, 0.22), P.call(0.22, 0.78), c, w * 1.3, true)
		"mail":
			draw_rect(Rect2(P.call(0.14, 0.26), Vector2(0.72, 0.5) * s), c, false, w)
			draw_polyline(PackedVector2Array([P.call(0.14, 0.26), P.call(0.5, 0.56), P.call(0.86, 0.26)]), c, w, true)
		"star":
			var pts2 := PackedVector2Array()
			for i in 10:
				var a := -PI / 2 + TAU * float(i) / 10.0
				var rr := 0.4 if i % 2 == 0 else 0.17
				pts2.append(P.call(0.5, 0.52) + Vector2(cos(a), sin(a)) * s * rr)
			draw_colored_polygon(pts2, c)
		"trophy":
			draw_colored_polygon(PackedVector2Array([P.call(0.28, 0.16), P.call(0.72, 0.16), P.call(0.66, 0.46), P.call(0.5, 0.56), P.call(0.34, 0.46)]), c)
			draw_arc(P.call(0.28, 0.3), s * 0.1, PI * 0.5, PI * 1.5, 10, c, w, true)
			draw_arc(P.call(0.72, 0.3), s * 0.1, -PI * 0.5, PI * 0.5, 10, c, w, true)
			draw_line(P.call(0.5, 0.56), P.call(0.5, 0.74), c, w * 1.4, true)
			draw_rect(Rect2(P.call(0.32, 0.74), Vector2(0.36, 0.1) * s), c, true)
		"factory":
			draw_colored_polygon(PackedVector2Array([P.call(0.12, 0.86), P.call(0.12, 0.5), P.call(0.36, 0.36), P.call(0.36, 0.5), P.call(0.6, 0.36), P.call(0.6, 0.5), P.call(0.88, 0.36), P.call(0.88, 0.86)]), Color(c, 0.85))
			draw_rect(Rect2(P.call(0.7, 0.12), Vector2(0.1, 0.3) * s), c, true)
		"truck":
			draw_rect(Rect2(P.call(0.1, 0.3), Vector2(0.5, 0.38) * s), c, false, w)
			draw_polyline(PackedVector2Array([P.call(0.6, 0.4), P.call(0.78, 0.4), P.call(0.9, 0.54), P.call(0.9, 0.68), P.call(0.6, 0.68)]), c, w, true)
			draw_circle(P.call(0.28, 0.74), s * 0.07, c)
			draw_circle(P.call(0.74, 0.74), s * 0.07, c)
		"crown":
			draw_colored_polygon(PackedVector2Array([P.call(0.14, 0.76), P.call(0.18, 0.3), P.call(0.36, 0.5), P.call(0.5, 0.22), P.call(0.64, 0.5), P.call(0.82, 0.3), P.call(0.86, 0.76)]), c)
		"bank":
			draw_colored_polygon(PackedVector2Array([P.call(0.12, 0.36), P.call(0.5, 0.14), P.call(0.88, 0.36)]), c)
			for i in 4:
				draw_rect(Rect2(P.call(0.2 + i * 0.17, 0.42), Vector2(0.08, 0.32) * s), c, true)
			draw_rect(Rect2(P.call(0.12, 0.78), Vector2(0.76, 0.08) * s), c, true)
		"deal":
			draw_arc(P.call(0.36, 0.5), s * 0.22, 0, TAU, 24, c, w, true)
			draw_arc(P.call(0.64, 0.5), s * 0.22, 0, TAU, 24, c, w, true)
		"chart":
			for i in 4:
				var hh = [0.3, 0.5, 0.4, 0.66][i]
				draw_rect(Rect2(P.call(0.14 + i * 0.19, 0.86 - hh), Vector2(0.13, hh) * s), c, true)
		"save":
			draw_rect(Rect2(P.call(0.16, 0.16), Vector2(0.68, 0.68) * s), c, false, w)
			draw_rect(Rect2(P.call(0.3, 0.16), Vector2(0.4, 0.22) * s), c, true)
			draw_rect(Rect2(P.call(0.28, 0.56), Vector2(0.44, 0.28) * s), Color(c, 0.5), true)
		_:
			draw_circle(P.call(0.5, 0.5), s * 0.3, c)
	if badge > 0:
		var bc := o + Vector2(s * 0.82, s * 0.18)
		draw_circle(bc, s * 0.2, Color("#e5786e"))
		var f := UI.font("bold")
		var t := str(badge) if badge < 10 else "9+"
		var fs := int(s * 0.26)
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, bc + Vector2(-tw * 0.5, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
