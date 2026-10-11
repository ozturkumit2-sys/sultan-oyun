class_name DrawKit
extends RefCounted
## Prosedürel çizgi film çizim yardımcıları: degradeli dolgu, kenar yumuşatmalı kontur,
## yumuşak gölge, eğriler ve hazır şekiller. Tüm karakterler, yemekler ve ikonlar bununla çizilir.

const INK := Color("#3b2417")
const WHITE := Color(1, 1, 1)

static var _radial: GradientTexture2D = null
static var _glow: GradientTexture2D = null


static func radial_tex() -> GradientTexture2D:
	if _radial == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 1))
		g.set_color(1, Color(0, 0, 0, 0))
		g.add_point(0.55, Color(0, 0, 0, 0.55))
		_radial = GradientTexture2D.new()
		_radial.gradient = g
		_radial.fill = GradientTexture2D.FILL_RADIAL
		_radial.fill_from = Vector2(0.5, 0.5)
		_radial.fill_to = Vector2(1.0, 0.5)
		_radial.width = 64
		_radial.height = 64
	return _radial


static func glow_tex() -> GradientTexture2D:
	if _glow == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.3, Color(1, 1, 1, 0.7))
		_glow = GradientTexture2D.new()
		_glow.gradient = g
		_glow.fill = GradientTexture2D.FILL_RADIAL
		_glow.fill_from = Vector2(0.5, 0.5)
		_glow.fill_to = Vector2(1.0, 0.5)
		_glow.width = 64
		_glow.height = 64
	return _glow


# ------------------------------------------------------------------ nokta üreteçleri
static func ellipse(c: Vector2, rx: float, ry: float, n := 40, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cr := cos(rot)
	var sr := sin(rot)
	for i in n:
		var a := TAU * i / n
		var x := cos(a) * rx
		var y := sin(a) * ry
		pts.append(c + Vector2(x * cr - y * sr, x * sr + y * cr))
	return pts


static func arc(c: Vector2, rx: float, ry: float, a0: float, a1: float, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func rrect(r: Rect2, rad: float, n := 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var corners := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	var starts := [-PI / 2, 0.0, PI / 2, PI]
	for k in 4:
		for i in n + 1:
			var a: float = starts[k] + (PI / 2) * float(i) / n
			pts.append(corners[k] + Vector2(cos(a), sin(a)) * rad)
	return pts


static func bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, n := 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var u := 1.0 - t
		pts.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	return pts


static func quad(p0: Vector2, p1: Vector2, p2: Vector2, n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var u := 1.0 - t
		pts.append(p0 * u * u + p1 * 2.0 * u * t + p2 * t * t)
	return pts


## Chaikin köşe yuvarlatma: birkaç kontrol noktasından organik kapalı şekil üretir.
static func smooth(pts: PackedVector2Array, iterations := 2, closed := true) -> PackedVector2Array:
	var cur := pts
	for it in iterations:
		var nxt := PackedVector2Array()
		var n := cur.size()
		var count := n if closed else n - 1
		if not closed:
			nxt.append(cur[0])
		for i in count:
			var a := cur[i]
			var b := cur[(i + 1) % n]
			nxt.append(a.lerp(b, 0.25))
			nxt.append(a.lerp(b, 0.75))
		if not closed:
			nxt.append(cur[n - 1])
		cur = nxt
	return cur


static func star_pts(c: Vector2, ro: float, ri: float, n := 5, rot := -PI / 2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var r := ro if i % 2 == 0 else ri
		var a := rot + PI * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func blob(c: Vector2, r: float, seed_v: int, wob := 0.12, n := 10) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in n:
		var a := TAU * i / n
		var rr := r * (1.0 + rng.randf_range(-wob, wob))
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	return smooth(pts, 2)


static func heart_pts(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * s / 16.0)
	return pts


static func transform_pts(pts: PackedVector2Array, offset: Vector2, scale := Vector2.ONE, rot := 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var cr := cos(rot)
	var sr := sin(rot)
	for p in pts:
		var q := p * scale
		out.append(Vector2(q.x * cr - q.y * sr, q.x * sr + q.y * cr) + offset)
	return out


static func mirror_x(pts: PackedVector2Array, cx := 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(pts.size() - 1, -1, -1):
		var p := pts[i]
		out.append(Vector2(2.0 * cx - p.x, p.y))
	return out


# ------------------------------------------------------------------ çizim
static func _grad_colors(pts: PackedVector2Array, col: Color, grad: float) -> PackedColorArray:
	var cols := PackedColorArray()
	var miny := INF
	var maxy := -INF
	for p in pts:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var h := maxf(1.0, maxy - miny)
	var top := col.lightened(grad)
	var bot := col.darkened(grad * 0.9)
	top.a = col.a
	bot.a = col.a
	for p in pts:
		cols.append(top.lerp(bot, (p.y - miny) / h))
	return cols


## Ardışık yinelenen noktaları temizler (üçgenleme hatalarını önler).
static func clean(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		if out.is_empty() or out[out.size() - 1].distance_squared_to(p) > 0.25:
			out.append(p)
	while out.size() > 2 and out[0].distance_squared_to(out[out.size() - 1]) <= 0.25:
		out.remove_at(out.size() - 1)
	return out


static func fill(ci: CanvasItem, pts: PackedVector2Array, col: Color, grad := 0.0) -> void:
	var p := clean(pts)
	if p.size() < 3:
		return
	if Geometry2D.triangulate_polygon(p).is_empty():
		# Kendi kendini kesen çokgen: birleşim ile basit parçalara ayır
		for part in Geometry2D.merge_polygons(p, PackedVector2Array()):
			if part.size() >= 3 and not Geometry2D.is_polygon_clockwise(part) and not Geometry2D.triangulate_polygon(part).is_empty():
				_fill_raw(ci, part, col, grad)
			elif part.size() >= 3 and not Geometry2D.triangulate_polygon(part).is_empty():
				_fill_raw(ci, part, col, grad)
		return
	_fill_raw(ci, p, col, grad)


static func _fill_raw(ci: CanvasItem, pts: PackedVector2Array, col: Color, grad: float) -> void:
	if grad <= 0.001:
		ci.draw_colored_polygon(pts, col)
	else:
		ci.draw_polygon(pts, _grad_colors(pts, col, grad))


static func outline(ci: CanvasItem, pts: PackedVector2Array, col := INK, w := 4.0, closed := true) -> void:
	if pts.size() < 2 or w <= 0.0:
		return
	var p := pts
	if closed:
		p = pts.duplicate()
		p.append(pts[0])
		if pts.size() > 1:
			p.append(pts[1])
	ci.draw_polyline(p, col, w, true)


static func shape(ci: CanvasItem, pts: PackedVector2Array, col: Color, w := 4.0, grad := 0.16, ink := INK) -> void:
	fill(ci, pts, col, grad)
	outline(ci, pts, ink, w, true)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(a, b, col, w, true)
	ci.draw_circle(a, w * 0.5, col, true, -1.0, true)
	ci.draw_circle(b, w * 0.5, col, true, -1.0, true)


static func poly_line(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, caps := true) -> void:
	if pts.size() < 2:
		return
	ci.draw_polyline(pts, col, w, true)
	if caps:
		ci.draw_circle(pts[0], w * 0.5, col, true, -1.0, true)
		ci.draw_circle(pts[pts.size() - 1], w * 0.5, col, true, -1.0, true)


## Konturlu kalın çizgi (kollar, saplar): önce koyu kalın, sonra renkli ince.
static func stroke(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, ink := INK, ow := 4.0) -> void:
	poly_line(ci, pts, ink, w + ow * 2.0)
	poly_line(ci, pts, col, w)


static func circle(ci: CanvasItem, c: Vector2, r: float, col: Color, w := 4.0, grad := 0.16, ink := INK) -> void:
	shape(ci, ellipse(c, r, r, maxi(16, int(r * 0.9))), col, w, grad, ink)


static func dot(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r, col, true, -1.0, true)


static func shadow(ci: CanvasItem, c: Vector2, rx: float, ry: float, alpha := 0.28) -> void:
	ci.draw_texture_rect(radial_tex(), Rect2(c - Vector2(rx, ry), Vector2(rx, ry) * 2.0), false, Color(1, 1, 1, alpha))


static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_texture_rect(glow_tex(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


static func shine(ci: CanvasItem, c: Vector2, rx: float, ry: float, alpha := 0.55, rot := -0.5) -> void:
	fill(ci, ellipse(c, rx, ry, 18, rot), Color(1, 1, 1, alpha))


static func text(ci: CanvasItem, s: String, pos: Vector2, size: int, col: Color, center := true, outline_col := Color(0, 0, 0, 0), ow := 0) -> void:
	var f: Font = GameManager.font_bold if GameManager.font_bold != null else ThemeDB.fallback_font
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos - Vector2(w * 0.5, -size * 0.35) if center else pos
	if ow > 0:
		ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ow, outline_col)
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func darker(c: Color, a := 0.25) -> Color:
	return c.darkened(a)


static func lighter(c: Color, a := 0.25) -> Color:
	return c.lightened(a)


static func ink_for(c: Color) -> Color:
	## Kontur rengi: dolgu renginin çok koyu tonu (saf siyah yerine sıcak)
	return c.darkened(0.72).lerp(INK, 0.5)
