class_name BarChart
extends Control
## Vertical bar chart. bars: [[label, value, color]]

var bars: Array = []
var fmt := "money"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.y < 10:
		custom_minimum_size = Vector2(100, 220)


func set_data(b: Array, f := "money") -> void:
	bars = b
	fmt = f
	queue_redraw()


func _draw() -> void:
	if bars.is_empty():
		return
	var f := UI.font("body")
	var hi := 0.0
	var lo := 0.0
	for b in bars:
		hi = maxf(hi, float(b[1]))
		lo = minf(lo, float(b[1]))
	if hi - lo <= 0.0:
		hi = lo + 1.0
	var top := 28.0
	var bottom := size.y - 30.0
	var zero_y := top + (bottom - top) * (hi / (hi - lo))
	var w := size.x / float(bars.size())
	for i in bars.size():
		var b: Array = bars[i]
		var v := float(b[1])
		var y := top + (bottom - top) * ((hi - v) / (hi - lo))
		var x := w * float(i) + w * 0.18
		var r := Rect2(x, minf(y, zero_y), w * 0.64, absf(zero_y - y))
		var c: Color = b[2] if b.size() > 2 else UI.GOLD
		draw_rect(r, c, true)
		var t := G.money(v) if fmt == "money" else (G.group_int(int(v)) if fmt == "int" else ("%.0f%%" % v if fmt == "pct" else "%.1f" % v))
		var fs := 15
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(x + w * 0.32 - tw * 0.5, minf(y, zero_y) - 6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.MUTED)
		var lb := str(b[0])
		var lw := f.get_string_size(lb, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(f, Vector2(x + w * 0.32 - lw * 0.5, size.y - 6), lb, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UI.MUTED)
	draw_line(Vector2(0, zero_y), Vector2(size.x, zero_y), Color(1, 1, 1, 0.15), 1.0)
