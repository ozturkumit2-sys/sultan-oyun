class_name Radar
extends Control
## Olfactive wheel: odor families around a circle; up to 3 overlaid profiles (opening/heart/dry-down).

var profiles: Array = []   # [[PackedFloat32Array, Color]]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.y < 10:
		custom_minimum_size = Vector2(300, 300)


func set_profiles(p: Array) -> void:
	profiles = p
	queue_redraw()


func _draw() -> void:
	var n := DB.dims.size()
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 46.0
	var f := UI.font("medium")
	for ring in [0.33, 0.66, 1.0]:
		var pts := PackedVector2Array()
		for i in n + 1:
			var a := -PI / 2 + TAU * float(i % n) / float(n)
			pts.append(c + Vector2(cos(a), sin(a)) * r * ring)
		draw_polyline(pts, Color(1, 1, 1, 0.08), 1.0, true)
	for i in n:
		var a := -PI / 2 + TAU * float(i) / float(n)
		draw_line(c, c + Vector2(cos(a), sin(a)) * r, Color(1, 1, 1, 0.05), 1.0)
		var d: String = DB.dims[i]
		var lp := c + Vector2(cos(a), sin(a)) * (r + 24)
		var t := d.capitalize()
		var fs := 15
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, lp - Vector2(tw * 0.5, -5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.dim_color(d).lightened(0.2))
	for pr in profiles:
		var v: PackedFloat32Array = pr[0]
		var col: Color = pr[1]
		var mx := 0.0
		for x in v:
			mx = maxf(mx, x)
		if mx <= 0.0:
			continue
		var pts2 := PackedVector2Array()
		for i in n:
			var a := -PI / 2 + TAU * float(i) / float(n)
			pts2.append(c + Vector2(cos(a), sin(a)) * r * (0.06 + 0.94 * sqrt(v[i] / mx)))
		var cols := PackedColorArray()
		for p in pts2:
			cols.append(Color(col, 0.18))
		if Geometry2D.triangulate_polygon(pts2).size() > 0:
			draw_polygon(pts2, cols)
		pts2.append(pts2[0])
		draw_polyline(pts2, col, 2.5, true)
