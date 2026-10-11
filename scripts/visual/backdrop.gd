class_name Backdrop
extends Control
## Prosedürel sahne arka planları: sunburst, mutfak, sahne (jüri), laboratuvar, harita, degrade.

var kind := "sunburst"
var c1 := Color("#ffb35c")
var c2 := Color("#ff8a3d")
var counter_y := -1.0        # mutfak tezgâhının üst çizgisi (piksel); <0 ise çizilmez
var counter_color := Color("#e8734a")
var spin := true
var dark := 0.0
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _bokeh: Array = []
var decor: Dictionary = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_rng.seed = 77
	for i in 14:
		_bokeh.append({"p": Vector2(_rng.randf(), _rng.randf()), "r": _rng.randf_range(20, 70), "s": _rng.randf_range(0.01, 0.04), "a": _rng.randf_range(0.06, 0.16)})
	if kind == "kitchen":
		var did: String = SaveManager.data.get("decor", "classic")
		decor = IngredientDatabase.decor.get(did, IngredientDatabase.decor.get("classic", {}))
		counter_color = Color(decor.get("counter", "#e8734a"))


func _process(delta: float) -> void:
	if kind == "sunburst" or kind == "lab" or kind == "stage" or kind == "map":
		_t += delta
		queue_redraw()


func _draw() -> void:
	match kind:
		"sunburst":
			_sunburst()
		"kitchen":
			_kitchen()
		"stage":
			_stage()
		"lab":
			_lab()
		"map":
			_map()
		_:
			_gradient(c1, c2)
	if dark > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.02, 0.1, dark))


func _gradient(top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


func _sunburst() -> void:
	_gradient(c1, c2)
	var ctr := Vector2(size.x * 0.5, size.y * 0.32)
	var rays := 18
	var rot := _t * 0.08 if spin else 0.0
	var big := size.length()
	for i in rays:
		var a0 := rot + TAU * i / rays
		var a1 := a0 + TAU / rays * 0.5
		draw_colored_polygon(PackedVector2Array([ctr, ctr + Vector2(cos(a0), sin(a0)) * big, ctr + Vector2(cos(a1), sin(a1)) * big]), Color(1, 1, 1, 0.09))
	for b in _bokeh:
		var p: Vector2 = b["p"]
		var y := fposmod(p.y - _t * b["s"], 1.2) - 0.1
		DrawKit.glow(self, Vector2(p.x * size.x, y * size.y), b["r"], Color(1, 1, 1, b["a"]))


func _kitchen() -> void:
	var wall := Color(decor.get("wall", "#ffe7c2"))
	var wall2 := Color(decor.get("wall2", "#ffd59a"))
	var tile := Color(decor.get("tile", "#fff6e8"))
	var h := counter_y if counter_y > 0 else size.y
	_gradient(wall, wall2)
	# fayans
	var ts := 46.0
	var y := h - ts * 3.2
	while y < h:
		var x := -ts * 0.5 if int(y / ts) % 2 == 0 else 0.0
		while x < size.x:
			DrawKit.fill(self, DrawKit.rrect(Rect2(x + 3, y + 3, ts - 6, ts - 6), 8), tile)
			x += ts
		y += ts
	# pencere
	var wr := Rect2(size.x * 0.32, h * 0.12, size.x * 0.36, h * 0.36)
	DrawKit.shape(self, DrawKit.rrect(wr.grow(10), 18), Color("#c8955c"), 4.0, 0.1)
	var sky := DrawKit.rrect(wr, 12)
	draw_polygon(sky, DrawKit._grad_colors(sky, Color("#8fd3ff"), 0.25))
	for cl in [Vector2(0.3, 0.35), Vector2(0.7, 0.6)]:
		var cc: Vector2 = wr.position + wr.size * cl
		for k in 3:
			draw_circle(cc + Vector2(-18 + k * 18, sin(k * 2.0) * 6), 16, Color(1, 1, 1, 0.9), true, -1.0, true)
	draw_line(Vector2(wr.get_center().x, wr.position.y), Vector2(wr.get_center().x, wr.end.y), Color("#c8955c"), 8.0, true)
	draw_line(Vector2(wr.position.x, wr.get_center().y), Vector2(wr.end.x, wr.get_center().y), Color("#c8955c"), 8.0, true)
	for s in [-1.0, 1.0]:
		var cx: float = wr.get_center().x + s * (wr.size.x * 0.5 + 6)
		var cur := DrawKit.smooth(PackedVector2Array([Vector2(cx - s * 4, wr.position.y - 14), Vector2(cx + s * 34, wr.position.y - 14),
			Vector2(cx + s * 26, wr.get_center().y), Vector2(cx + s * 40, wr.end.y + 10), Vector2(cx - s * 4, wr.end.y + 10)]), 2)
		DrawKit.shape(self, cur, Color("#ff7a8a"), 4.0, 0.15)
	# raflar
	for side in [0, 1]:
		var sx := 18.0 if side == 0 else size.x * 0.74
		var sw := size.x * 0.24
		for row in 2:
			var sy := h * (0.22 + row * 0.26)
			DrawKit.shape(self, DrawKit.rrect(Rect2(sx, sy, sw, 12), 4), Color("#a8743c"), 3.5, 0.1)
			for k in 3:
				var jx := sx + 16 + k * (sw - 30) / 3.0
				var jc: Color = [Color("#ff7ab8"), Color("#7cff6b"), Color("#ffd23f"), Color("#4ad6ff"), Color("#a25cff")][(k + row * 2 + side) % 5]
				var jr := Rect2(jx, sy - 44, 30, 44)
				DrawKit.fill(self, DrawKit.rrect(jr, 8), Color(0.92, 0.96, 1.0, 0.85))
				DrawKit.fill(self, DrawKit.rrect(Rect2(jx, sy - 26, 30, 26), 8), jc, 0.15)
				DrawKit.outline(self, DrawKit.rrect(jr, 8), DrawKit.INK, 3.0)
				DrawKit.shape(self, DrawKit.rrect(Rect2(jx - 2, sy - 52, 34, 10), 4), Color("#c8955c"), 3.0, 0.1)
	# asılı tavalar
	for k in 3:
		var px := size.x * (0.08 + k * 0.08)
		draw_line(Vector2(px, 0), Vector2(px, h * 0.07), DrawKit.INK, 3.0, true)
		DrawKit.circle(self, Vector2(px, h * 0.07 + 18), 18, Color("#9aa6b2"), 3.5)
	# tezgâh
	if counter_y > 0:
		var top := Rect2(-10, counter_y, size.x + 20, 26)
		DrawKit.shape(self, DrawKit.rrect(top, 10), counter_color.lightened(0.15), 4.0, 0.1)
		var front := Rect2(-10, counter_y + 22, size.x + 20, size.y - counter_y)
		draw_polygon(DrawKit.rrect(front, 4), DrawKit._grad_colors(DrawKit.rrect(front, 4), counter_color, 0.12))
		for k in 6:
			var dx := (k + 0.5) * size.x / 6.0
			draw_line(Vector2(dx, counter_y + 34), Vector2(dx, size.y), Color(0, 0, 0, 0.08), 3.0, true)


func _stage() -> void:
	_gradient(Color("#3a1f5c"), Color("#1f1033"))
	# arka ışıklar
	for i in 12:
		var x := size.x * (i + 0.5) / 12.0
		var on := int(_t * 2.0 + i) % 4 != 0
		DrawKit.glow(self, Vector2(x, size.y * 0.08), 26, Color(1.0, 0.85, 0.4, 0.75 if on else 0.3))
		draw_circle(Vector2(x, size.y * 0.08), 6, Color("#fff1a8") if on else Color("#8a7a50"), true, -1.0, true)
	# spot ışıkları
	for s in [-1.0, 1.0]:
		var src := Vector2(size.x * 0.5 + s * size.x * 0.42, -20)
		var sway := sin(_t * 0.7 + s) * 30.0
		var tgt := Vector2(size.x * 0.5 + s * 60 + sway, size.y * 0.62)
		var cone := PackedVector2Array([src + Vector2(-14, 0), src + Vector2(14, 0), tgt + Vector2(130, 0), tgt + Vector2(-130, 0)])
		draw_polygon(cone, PackedColorArray([Color(1, 0.95, 0.7, 0.22), Color(1, 0.95, 0.7, 0.22), Color(1, 0.95, 0.7, 0.0), Color(1, 0.95, 0.7, 0.0)]))
	# perdeler
	for s in [-1.0, 1.0]:
		var edge: float = size.x * 0.5 + s * size.x * 0.5
		var inner: float = size.x * 0.5 + s * size.x * 0.36
		var cur := PackedVector2Array([Vector2(edge, 0), Vector2(inner, 0), Vector2(inner + s * 30, size.y * 0.45), Vector2(inner - s * 10, size.y * 0.75), Vector2(edge, size.y * 0.75)])
		DrawKit.shape(self, cur, Color("#c4223a"), 4.0, 0.25)
		for k in 4:
			var fx := lerpf(edge, inner, (k + 0.5) / 4.0)
			draw_line(Vector2(fx, 0), Vector2(fx + s * 10, size.y * 0.7), Color(0.4, 0.0, 0.1, 0.35), 6.0, true)
	var val := PackedVector2Array()
	for i in 13:
		var x2 := size.x * i / 12.0
		val.append(Vector2(x2, 30 + (18.0 if i % 2 == 1 else 0.0) + 20))
	val.append(Vector2(size.x, 0))
	val.append(Vector2(0, 0))
	DrawKit.shape(self, DrawKit.smooth(val, 1), Color("#a8162e"), 4.0, 0.2)
	draw_rect(Rect2(0, 0, size.x, 22), Color("#f2c14e"))
	# sahne zemini
	var fy := size.y * 0.74
	var floor_p := PackedVector2Array([Vector2(0, fy), Vector2(size.x, fy), size, Vector2(0, size.y)])
	draw_polygon(floor_p, PackedColorArray([Color("#8a5a3b"), Color("#8a5a3b"), Color("#5a3622"), Color("#5a3622")]))
	for k in 8:
		var yy := fy + (size.y - fy) * pow(k / 8.0, 1.3)
		draw_line(Vector2(0, yy), Vector2(size.x, yy), Color(0, 0, 0, 0.15), 2.0, true)


func _lab() -> void:
	_gradient(Color("#3b2a5c"), Color("#1d1433"))
	var bw := 64.0
	var bh := 30.0
	var y := 0.0
	var row := 0
	while y < size.y * 0.7:
		var x := -bw * 0.5 if row % 2 == 0 else 0.0
		while x < size.x:
			DrawKit.outline(self, DrawKit.rrect(Rect2(x + 3, y + 3, bw - 6, bh - 6), 6), Color(1, 1, 1, 0.05), 2.0)
			x += bw
		y += bh
		row += 1
	for side in [0, 1]:
		var sx := 16.0 if side == 0 else size.x * 0.72
		for r in 2:
			var sy := size.y * (0.2 + r * 0.22)
			DrawKit.shape(self, DrawKit.rrect(Rect2(sx, sy, size.x * 0.26, 10), 4), Color("#6b4a8a"), 3.0, 0.1)
			for k in 3:
				var fx := sx + 22 + k * size.x * 0.08
				var fc: Color = [Color("#7cff6b"), Color("#ff5fa2"), Color("#4ad6ff"), Color("#ffd23f")][(k + r + side) % 4]
				var glow_a := 0.35 + 0.15 * sin(_t * 2.0 + k + r * 2)
				DrawKit.glow(self, Vector2(fx + 12, sy - 18), 34, Color(fc, glow_a))
				var fl := DrawKit.ellipse(Vector2(fx + 12, sy - 16), 15, 15, 20)
				DrawKit.fill(self, fl, Color(fc, 0.9), 0.2)
				DrawKit.outline(self, fl, DrawKit.INK, 3.0)
				DrawKit.shape(self, DrawKit.rrect(Rect2(fx + 6, sy - 44, 12, 16), 3), Color(0.85, 0.9, 1.0, 0.7), 3.0, 0.0)
	for k in 3:
		var px := size.x * (0.3 + k * 0.2)
		draw_line(Vector2(px, 0), Vector2(px, size.y * 0.12), Color("#9aa6b2"), 10.0, true)
		draw_circle(Vector2(px, size.y * 0.12), 9, Color("#9aa6b2"), true, -1.0, true)
	if counter_y > 0:
		var top := Rect2(-10, counter_y, size.x + 20, 24)
		DrawKit.shape(self, DrawKit.rrect(top, 8), Color("#7a5ca8"), 4.0, 0.1)
		var front := Rect2(-10, counter_y + 20, size.x + 20, size.y - counter_y)
		draw_polygon(DrawKit.rrect(front, 4), DrawKit._grad_colors(DrawKit.rrect(front, 4), Color("#4b3470"), 0.12))


func _map() -> void:
	_gradient(Color("#ffe9c7"), Color("#ffd29a"))
	var step := 60.0
	var y := fposmod(_t * 6.0, step) - step
	while y < size.y:
		var x := 0.0
		while x < size.x:
			draw_circle(Vector2(x + (step * 0.5 if int((y + 1000) / step) % 2 == 0 else 0.0), y), 3.5, Color(0.6, 0.4, 0.2, 0.12), true, -1.0, true)
			x += step
		y += step
