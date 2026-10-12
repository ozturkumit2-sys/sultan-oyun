class_name TierPath
extends Control
## Headquarters progression: four illustrated building medallions joined by a path.

var tier := 1
const NAMES := ["Startup", "Regional", "International", "Global"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var n := 4
	var r := minf(size.y * 0.32, size.x / float(n) * 0.32)
	var y := r + 4
	var xs: Array = []
	for i in n:
		xs.append(size.x * (float(i) + 0.5) / float(n))
	for i in n - 1:
		var col := UI.BURGUNDY if i + 1 < tier else Color(UI.BURGUNDY, 0.18)
		draw_line(Vector2(xs[i] + r, y), Vector2(xs[i + 1] - r, y), col, 4.0, true)
	var f := UI.font("semi")
	for i in n:
		var done := i + 1 <= tier
		var cur := i + 1 == tier
		var c := Vector2(xs[i], y)
		if cur:
			draw_circle(c, r + 7, Color(UI.ROSE, 0.22))
		draw_circle(c, r, Color("#fffaf4"))
		var t := Art.scene("hq%d" % (i + 1))
		if t != null:
			# draw the building as a small medallion: crop the scene's centre into the circle
			var pts := PackedVector2Array()
			var uvs := PackedVector2Array()
			var ts := t.get_size()
			var crop := Rect2(ts.x * 0.28, ts.y * 0.08, ts.x * 0.44, ts.x * 0.44)
			for k in 40:
				var a := TAU * float(k) / 40.0
				var d := Vector2(cos(a), sin(a))
				pts.append(c + d * (r - 3))
				uvs.append((crop.position + crop.size * (Vector2(0.5, 0.5) + d * 0.5)) / ts)
			var cols := PackedColorArray()
			cols.resize(pts.size())
			cols.fill(Color(1, 1, 1, 1.0) if done else Color(1, 1, 1, 0.35))
			draw_polygon(pts, cols, uvs, t)
		draw_arc(c, r, 0, TAU, 48, UI.BURGUNDY if done else Color(UI.BURGUNDY, 0.25), 3.0 if cur else 2.0, true)
		var label: String = NAMES[i]
		var fs := 16
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(c.x - w * 0.5, y + r + 26), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.BURGUNDY if done else UI.MUTED)
