class_name ScentTimeline
extends Control
## Perceived strength on the blotter over time (log scale), with the detection line and "now" marker.

var mats: Array = []
var t_now := 0.0
var t_max := 36.0
var col := Color("#c4677f")
var _vals := PackedFloat32Array()
var _detect := 0.9
const N := 90


func _init() -> void:
	custom_minimum_size = Vector2(0, 170)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_mats(m: Array) -> void:
	mats = m
	_vals.resize(N)
	_detect = float(DB.bal["perf"]["detect"])
	for i in N:
		var t := _t_of(float(i) / float(N - 1))
		_vals[i] = float(FormulaEngine.blotter_at(mats, t)["total"])
	queue_redraw()


func _t_of(s: float) -> float:
	return t_max * pow(s, 2.2)


func _s_of(t: float) -> float:
	return pow(clampf(t / t_max, 0.0, 1.0), 1.0 / 2.2)


func _y(v: float, h: float) -> float:
	var lo := log(_detect * 0.25)
	var hi := log(maxf(_detect * 20.0, _vals[0] if _vals.size() > 0 else 10.0))
	return h - clampf((log(maxf(v, 1e-6)) - lo) / maxf(0.01, hi - lo), 0.0, 1.0) * (h - 24.0) - 4.0


func _draw() -> void:
	var w := size.x
	var h := size.y - 22.0
	draw_rect(Rect2(0, 0, w, h), Color(1, 0.99, 0.97, 0.9), true)
	if _vals.size() < 2:
		return
	var pts := PackedVector2Array()
	var area := PackedVector2Array([Vector2(0, h)])
	for i in N:
		var p := Vector2(w * float(i) / float(N - 1), _y(_vals[i], h))
		pts.append(p)
		area.append(p)
	area.append(Vector2(w, h))
	draw_colored_polygon(area, Color(col, 0.18))
	draw_polyline(pts, col, 3.0, true)
	# detection threshold: below it you no longer smell anything
	var dy := _y(_detect, h)
	var x := 0.0
	while x < w:
		draw_line(Vector2(x, dy), Vector2(minf(w, x + 8), dy), Color(UI.MUTED, 0.7), 1.5)
		x += 14.0
	var f := UI.font("medium")
	draw_string(f, Vector2(w - 92, dy - 6), "you stop smelling it", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.MUTED)
	# time ticks
	for tk in [0.0, 1.0, 3.0, 6.0, 12.0, 24.0, 36.0]:
		var tx := w * _s_of(tk)
		draw_line(Vector2(tx, h), Vector2(tx, h + 4), UI.DIM, 1.0)
		var lb := "%dh" % int(tk)
		var lw := f.get_string_size(lb, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(f, Vector2(clampf(tx - lw * 0.5, 0, w - lw), h + 18), lb, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UI.MUTED)
	# now
	var nx := w * _s_of(t_now)
	draw_line(Vector2(nx, 0), Vector2(nx, h), UI.BURGUNDY, 2.5)
	var cur := float(FormulaEngine.blotter_at(mats, t_now)["total"])
	draw_circle(Vector2(nx, _y(cur, h)), 7, UI.BURGUNDY)
	draw_circle(Vector2(nx, _y(cur, h)), 3.5, Color.WHITE)
