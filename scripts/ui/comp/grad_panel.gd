class_name GradPanel
extends TapPanel
## Rounded card with a soft vertical (or diagonal) gradient, border and drop shadow.
## Tappable when `tapped` is set (inherits TapPanel).

var top := Color("#fffaf4")
var bottom := Color("#f6ebe0")
var border := Color(0.55, 0.38, 0.36, 0.16)
var radius := 22.0
var shadow := 0.10
var pad := 16.0


func _init() -> void:
	var e := StyleBoxEmpty.new()
	e.content_margin_left = pad
	e.content_margin_right = pad
	e.content_margin_top = pad
	e.content_margin_bottom = pad
	add_theme_stylebox_override("panel", e)


func set_pad(p: float) -> GradPanel:
	pad = p
	var e := StyleBoxEmpty.new()
	e.content_margin_left = p
	e.content_margin_right = p
	e.content_margin_top = p
	e.content_margin_bottom = p
	add_theme_stylebox_override("panel", e)
	return self


func colors(a: Color, b: Color) -> GradPanel:
	top = a
	bottom = b
	queue_redraw()
	return self


func _ready() -> void:
	super._ready()
	if not tapped.is_valid():
		mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)


func _draw() -> void:
	var r := minf(radius, minf(size.x, size.y) * 0.5)
	if shadow > 0.0:
		for i in 6:
			var g := float(6 - i)
			var pts := _rr(Rect2(Vector2(-g * 0.6, 3.0 + g * 0.2 - g * 0.6), size + Vector2(g * 1.2, g * 1.2)), r + g)
			draw_colored_polygon(pts, Color(0.42, 0.22, 0.28, shadow * 0.18))
	var poly := _rr(Rect2(Vector2.ZERO, size), r)
	var cols := PackedColorArray()
	for p in poly:
		cols.append(top.lerp(bottom, clampf(p.y / maxf(1.0, size.y), 0.0, 1.0)))
	draw_polygon(poly, cols)
	if border.a > 0.0:
		var ol := poly.duplicate()
		ol.append(poly[0])
		draw_polyline(ol, border, 1.5, true)


static func _rr(rect: Rect2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [[rect.position + Vector2(rect.size.x - r, r), -PI / 2], [rect.end - Vector2(r, r), 0.0],
		[rect.position + Vector2(r, rect.size.y - r), PI / 2], [rect.position + Vector2(r, r), PI]]
	for c in corners:
		for k in 7:
			var a: float = float(c[1]) + PI / 2 * float(k) / 6.0
			pts.append((c[0] as Vector2) + Vector2(cos(a), sin(a)) * r)
	return pts
