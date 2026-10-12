class_name HQView
extends Control
## Headquarters illustration that changes with the company's tier.

var tier := 1
var name_text := ""
var accent := Color("#c9a55a")
var building := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size.y < 10:
		custom_minimum_size = Vector2(300, 300)


func _draw() -> void:
	var w := size.x
	var h := size.y
	# dusk sky
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([Color("#241c33"), Color("#2b2140"), Color("#5a3b4a"), Color("#4a3242")]))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 30:
		draw_circle(Vector2(rng.randf() * w, rng.randf() * h * 0.4), rng.randf_range(0.6, 1.6), Color(1, 1, 1, rng.randf_range(0.2, 0.6)))
	var ground := h * 0.86
	draw_rect(Rect2(0, ground, w, h - ground), Color("#17131b"), true)
	match tier:
		1:
			_shop(w, h, ground)
		2:
			_house(w, h, ground)
		3:
			_tower(w, h, ground, false)
		_:
			_tower(w, h, ground, true)
	if building:
		var f := UI.font("semi")
		draw_rect(Rect2(w * 0.08, h * 0.08, w * 0.84, 44), Color(0, 0, 0, 0.5), true)
		draw_string(f, Vector2(w * 0.1, h * 0.08 + 31), "Under construction — next tier", HORIZONTAL_ALIGNMENT_LEFT, w * 0.8, 20, UI.GOLD2)


func _windows(r: Rect2, cols: int, rows: int, lit: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 13 + r.size.y)
	var cw := r.size.x / float(cols)
	var rh := r.size.y / float(rows)
	for y in rows:
		for x in cols:
			var on := rng.randf() < lit
			var c := Color("#f6d98b") if on else Color("#2a2433")
			draw_rect(Rect2(r.position + Vector2(x * cw + cw * 0.22, y * rh + rh * 0.2), Vector2(cw * 0.56, rh * 0.6)), c, true)


func _sign(x: float, y: float, w: float) -> void:
	var f := UI.font("title")
	var fs := 22
	var t := name_text
	var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	while tw > w * 0.9 and fs > 12:
		fs -= 1
		tw = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_rect(Rect2(x, y, w, fs + 14), Color("#17131b"), true)
	draw_rect(Rect2(x, y, w, fs + 14), accent, false, 2.0)
	draw_string(f, Vector2(x + (w - tw) * 0.5, y + fs + 3), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, accent)


func _shop(w: float, h: float, g: float) -> void:
	var r := Rect2(w * 0.25, g - h * 0.42, w * 0.5, h * 0.42)
	draw_rect(r, Color("#3a3040"), true)
	draw_rect(Rect2(r.position.x - 10, r.position.y - 16, r.size.x + 20, 18), Color("#2a2230"), true)
	for i in 8:
		var c := accent if i % 2 == 0 else Color("#efe6d6")
		draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + i * r.size.x / 8.0, r.position.y + h * 0.12), Vector2(r.position.x + (i + 1) * r.size.x / 8.0, r.position.y + h * 0.12),
			Vector2(r.position.x + (i + 1) * r.size.x / 8.0 + 4, r.position.y + h * 0.18), Vector2(r.position.x + i * r.size.x / 8.0 + 4, r.position.y + h * 0.18)]), c)
	draw_rect(Rect2(r.position.x + r.size.x * 0.1, r.position.y + h * 0.22, r.size.x * 0.5, h * 0.16), Color("#f6d98b"), true)
	for i in 5:
		draw_rect(Rect2(r.position.x + r.size.x * (0.14 + i * 0.09), r.position.y + h * 0.29, 8, 16), Color(0.6, 0.3 + i * 0.1, 0.5, 0.9), true)
	draw_rect(Rect2(r.position.x + r.size.x * 0.68, r.position.y + h * 0.22, r.size.x * 0.2, h * 0.2), Color("#5a3b2a"), true)
	_sign(r.position.x + r.size.x * 0.1, r.position.y + 8, r.size.x * 0.8)


func _house(w: float, h: float, g: float) -> void:
	var r := Rect2(w * 0.18, g - h * 0.6, w * 0.64, h * 0.6)
	draw_rect(r, Color("#d9cbb4"), true)
	draw_rect(Rect2(r.position.x - 8, r.position.y - 14, r.size.x + 16, 16), Color("#a8987f"), true)
	_windows(Rect2(r.position.x + 10, r.position.y + 60, r.size.x - 20, r.size.y - 140), 5, 3, 0.7)
	draw_rect(Rect2(r.position.x + r.size.x * 0.42, g - h * 0.16, r.size.x * 0.16, h * 0.16), Color("#3a2a20"), true)
	draw_rect(Rect2(r.position.x + r.size.x * 0.4, g - h * 0.17, r.size.x * 0.2, 6), accent, true)
	_sign(r.position.x + r.size.x * 0.12, r.position.y + 10, r.size.x * 0.76)
	for x in [w * 0.08, w * 0.88]:
		draw_rect(Rect2(x, g - 40, 6, 40), Color("#3a2a20"), true)
		draw_circle(Vector2(x + 3, g - 50), 22, Color("#2f4a33"))


func _tower(w: float, h: float, g: float, big: bool) -> void:
	if big:
		var r2 := Rect2(w * 0.06, g - h * 0.55, w * 0.26, h * 0.55)
		draw_rect(r2, Color("#2d3a4f"), true)
		_windows(r2.grow(-8), 4, 9, 0.55)
	var r := Rect2(w * (0.36 if big else 0.3), g - h * (0.78 if big else 0.7), w * (0.3 if big else 0.4), h * (0.78 if big else 0.7))
	draw_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]),
		PackedColorArray([Color("#3d5a7a"), Color("#2c4560"), Color("#1d2c3f"), Color("#26394f")]))
	_windows(Rect2(r.position + Vector2(8, 50), r.size - Vector2(16, 70)), 5 if big else 6, 12, 0.6)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 6), accent, true)
	_sign(r.position.x + 6, r.position.y + 12, r.size.x - 12)
	var r3 := Rect2(w * (0.68 if big else 0.72), g - h * 0.32, w * (0.26 if big else 0.2), h * 0.32)
	draw_rect(r3, Color("#cfc2ab"), true)
	_windows(r3.grow(-8), 4, 3, 0.75)
	if big:
		draw_rect(Rect2(w * 0.02, g - 6, w * 0.96, 6), Color("#2f4a33"), true)
		for i in 7:
			draw_circle(Vector2(w * (0.05 + i * 0.15), g - 16), 14, Color("#355a3b"))
		draw_rect(Rect2(r.position.x + r.size.x * 0.45, r.position.y - 40, 4, 40), Color("#9aa"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + r.size.x * 0.45 + 4, r.position.y - 40), Vector2(r.position.x + r.size.x * 0.45 + 34, r.position.y - 32), Vector2(r.position.x + r.size.x * 0.45 + 4, r.position.y - 24)]), accent)
