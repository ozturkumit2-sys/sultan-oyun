class_name LineChart
extends Control
## Basit çizgi grafik: sol eksende ana seri, sağ eksende 0-100 ikincil seri.

var series: Array = []
var series2: Dictionary = {}
var labels: Array = []


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	UI.fonts()
	var r := Rect2(Vector2(70, 14), size - Vector2(130, 44))
	draw_rect(Rect2(Vector2.ZERO, size), Color(UI.NAVY2, 0.6), true)
	var mx := 1.0
	var mn := 0.0
	for s in series:
		for v in s["values"]:
			mx = maxf(mx, float(v))
			mn = minf(mn, float(v))
	var span := maxf(mx - mn, 1.0)
	for i in range(5):
		var y := r.position.y + r.size.y * float(i) / 4.0
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(1, 1, 1, 0.08), 1.0)
		var val := mx - span * float(i) / 4.0
		draw_string(UI.font_body, Vector2(4, y + 6), _short(val), HORIZONTAL_ALIGNMENT_LEFT, 64, 14, UI.MUTED)
		if not series2.is_empty():
			draw_string(UI.font_body, Vector2(r.end.x + 8, y + 6), str(100 - i * 25), HORIZONTAL_ALIGNMENT_LEFT, 50, 14, Color(series2["color"], 0.8))
	for s2 in series:
		_plot(s2["values"], s2["color"], r, mn, span)
	if not series2.is_empty():
		_plot(series2["values"], series2["color"], r, 0.0, 100.0)
	var n := labels.size()
	for i2 in range(n):
		var x := r.position.x + (r.size.x * float(i2) / maxf(n - 1, 1))
		if n > 8 and i2 % 2 == 1:
			continue
		draw_string(UI.font_body, Vector2(x - 24, size.y - 8), String(labels[i2]), HORIZONTAL_ALIGNMENT_CENTER, 60, 13, UI.MUTED)
	var lx := r.position.x + 8
	for s3 in series:
		draw_rect(Rect2(Vector2(lx, r.position.y + 4), Vector2(14, 4)), s3["color"])
		draw_string(UI.font_body, Vector2(lx + 18, r.position.y + 11), String(s3["name"]), HORIZONTAL_ALIGNMENT_LEFT, 120, 14, UI.TEXT)
		lx += 120
	if not series2.is_empty():
		draw_rect(Rect2(Vector2(lx, r.position.y + 4), Vector2(14, 4)), series2["color"])
		draw_string(UI.font_body, Vector2(lx + 18, r.position.y + 11), String(series2["name"]), HORIZONTAL_ALIGNMENT_LEFT, 140, 14, UI.TEXT)


func _plot(vals: Array, col: Color, r: Rect2, mn: float, span: float) -> void:
	var n := vals.size()
	if n == 0:
		return
	var pts := PackedVector2Array()
	for i in range(n):
		var x := r.position.x + (r.size.x * float(i) / maxf(n - 1, 1)) if n > 1 else r.position.x + r.size.x * 0.5
		var y := r.end.y - (float(vals[i]) - mn) / span * r.size.y
		pts.append(Vector2(x, y))
	if n > 1:
		draw_polyline(pts, col, 3.0, true)
	for p in pts:
		draw_circle(p, 4.0, col)


func _short(v: float) -> String:
	if absf(v) >= 1000000.0:
		return "%.1fM" % (v / 1000000.0)
	if absf(v) >= 1000.0:
		return "%dB" % int(v / 1000.0)
	return str(int(v))
