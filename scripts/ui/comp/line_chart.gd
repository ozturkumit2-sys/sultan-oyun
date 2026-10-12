class_name LineChart
extends Control
## Multi-series line chart with soft area fill, gridlines and formatted axis labels.
## series: [{"v": Array/PackedFloat32Array, "c": Color, "name": String}]

var series: Array = []
var xlabels: Array = []
var fmt := "money"     # money | int | hours | pct | raw
var fill := true
var min_zero := true
var markers: Array = []   # [[x_index, label]]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.y < 10:
		custom_minimum_size = Vector2(100, 240)


func set_data(s: Array, xl: Array = [], f := "money") -> void:
	series = s
	xlabels = xl
	fmt = f
	queue_redraw()


func _fmt(v: float) -> String:
	match fmt:
		"money":
			return G.money(v)
		"int":
			if absf(v) >= 1e6:
				return "%.1fM" % (v / 1e6)
			if absf(v) >= 1e4:
				return "%.0fK" % (v / 1e3)
			return G.group_int(int(round(v)))
		"hours":
			return "%.0fh" % v
		"pct":
			return "%.0f%%" % (v * 100.0)
	return "%.2f" % v


func _draw() -> void:
	var f := UI.font("body")
	var fs := 17
	var lw := 74.0
	var bh := 26.0 if not xlabels.is_empty() else 6.0
	var area := Rect2(Vector2(lw, 8), size - Vector2(lw + 8, 8 + bh))
	var lo := 0.0 if min_zero else 1e30
	var hi := -1e30
	var n := 0
	for s in series:
		var vals: Array = Array(s["v"])
		n = maxi(n, vals.size())
		for v in vals:
			hi = maxf(hi, float(v))
			lo = minf(lo, float(v))
	if n < 2 or hi <= -1e29:
		draw_string(f, Vector2(lw, size.y * 0.5), "Not enough data yet", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.DIM)
		return
	if hi <= lo:
		hi = lo + 1.0
	var pad := (hi - lo) * 0.08
	hi += pad
	if not min_zero:
		lo -= pad
	for gi in 4:
		var y := area.position.y + area.size.y * float(gi) / 3.0
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(1, 1, 1, 0.06), 1.0)
		var v := hi - (hi - lo) * float(gi) / 3.0
		draw_string(f, Vector2(0, y + 6), _fmt(v), HORIZONTAL_ALIGNMENT_RIGHT, lw - 8, fs, UI.MUTED)
	if lo < 0.0 and hi > 0.0:
		var y0 := area.position.y + area.size.y * (hi / (hi - lo))
		draw_line(Vector2(area.position.x, y0), Vector2(area.end.x, y0), Color(1, 1, 1, 0.18), 1.0)
	for si in series.size():
		var s: Dictionary = series[si]
		var vals: Array = Array(s["v"])
		var col: Color = s.get("c", UI.GOLD)
		var pts := PackedVector2Array()
		for i in vals.size():
			var x := area.position.x + area.size.x * float(i) / float(maxi(1, n - 1))
			var y := area.position.y + area.size.y * (1.0 - (float(vals[i]) - lo) / (hi - lo))
			pts.append(Vector2(x, y))
		if pts.size() < 2:
			continue
		if fill and si == 0:
			var poly := pts.duplicate()
			var base_y := area.end.y if lo >= 0.0 else area.position.y + area.size.y * (hi / (hi - lo))
			poly.append(Vector2(pts[pts.size() - 1].x, base_y))
			poly.append(Vector2(pts[0].x, base_y))
			var cols := PackedColorArray()
			for p in poly:
				cols.append(Color(col, 0.22 * (1.0 - (p.y - area.position.y) / maxf(1.0, area.size.y)) + 0.02))
			if Geometry2D.triangulate_polygon(poly).size() > 0:
				draw_polygon(poly, cols)
		draw_polyline(pts, col, 3.0, true)
		draw_circle(pts[pts.size() - 1], 5.0, col)
	for i in xlabels.size():
		if xlabels[i] == "":
			continue
		var x := area.position.x + area.size.x * float(i) / float(maxi(1, n - 1))
		var t: String = str(xlabels[i])
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(clampf(x - tw * 0.5, area.position.x - 20, size.x - tw), size.y - 4), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.MUTED)
	for m in markers:
		var x2 := area.position.x + area.size.x * float(m[0]) / float(maxi(1, n - 1))
		draw_dashed_line(Vector2(x2, area.position.y), Vector2(x2, area.end.y), Color(UI.GOLD, 0.5), 1.5, 6.0)
		draw_string(f, Vector2(x2 + 4, area.position.y + 16), str(m[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UI.GOLD2)
