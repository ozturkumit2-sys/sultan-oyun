class_name BottleView
extends Control
## Procedural perfume bottle: 10 glass shapes, 8 caps, 10 glass tints, 6 label styles and
## a liquid colored by the formula's odor profile. Every product therefore looks distinct.

var design: Dictionary = {"shape": 0, "cap": 0, "glass": 0, "label": 0, "accent": "#c9a55a"}
var brand_name := ""
var product_name := ""
var liquid := Color("#f1dfa0")
var show_label := true
var shadow := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(d: Dictionary, brand := "", pname := "", profile: PackedFloat32Array = PackedFloat32Array()) -> BottleView:
	design = d
	brand_name = brand
	product_name = pname
	if profile.size() == DB.dims.size():
		liquid = liquid_color(profile)
	queue_redraw()
	return self


static func liquid_color(profile: PackedFloat32Array) -> Color:
	var base := Color("#f4e8b8")
	var mix := Color(0, 0, 0, 0)
	var tot := 0.0
	for i in profile.size():
		var c := UI.dim_color(DB.dims[i])
		mix.r += c.r * profile[i]
		mix.g += c.g * profile[i]
		mix.b += c.b * profile[i]
		tot += profile[i]
	if tot <= 0.0:
		return base
	mix = Color(mix.r / tot, mix.g / tot, mix.b / tot)
	var warm := profile[DB.dim_index("amber")] + profile[DB.dim_index("gourmand")] + profile[DB.dim_index("animalic")]
	var c2 := base.lerp(mix, 0.35)
	return c2.lerp(Color("#c47a2c"), clampf(warm * 0.8, 0.0, 0.5))


func _body(shape: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var top := 0.5
	var bot := 1.52
	match shape:
		3:  # faceted
			return PackedVector2Array([Vector2(0.36, 0.5), Vector2(0.64, 0.5), Vector2(0.84, 0.68), Vector2(0.84, 1.36), Vector2(0.64, 1.54), Vector2(0.36, 1.54), Vector2(0.16, 1.36), Vector2(0.16, 0.68)])
		4:  # orb
			for i in 48:
				var a := TAU * float(i) / 48.0
				pts.append(Vector2(0.5 + cos(a) * 0.4, 1.1 + sin(a) * 0.42))
			return pts
	var steps := 24
	var hw := func(t: float) -> float: return 0.34
	match shape:
		0:
			hw = func(t: float) -> float: return 0.34 - 0.06 * pow(maxf(0.0, 0.08 - t) / 0.08, 2.0)
		1:
			hw = func(t: float) -> float: return 0.14 + 0.26 * pow(sin(PI * clampf(t * 0.85 + 0.12, 0.0, 1.0)), 0.7)
		2:
			top = 0.42
			hw = func(t: float) -> float: return 0.21
		5:
			top = 0.62
			hw = func(t: float) -> float: return 0.4
		6:
			hw = func(t: float) -> float: return 0.06 + 0.36 * pow(sin(PI * clampf(t * 0.62 + 0.04, 0.0, 1.0)), 0.9)
		7:
			hw = func(t: float) -> float: return 0.1 + 0.25 * clampf(t / 0.14, 0.0, 1.0)
		8:
			hw = func(t: float) -> float: return 0.18 + 0.17 * t
		9:
			hw = func(t: float) -> float: return 0.1 + 0.34 * pow(t, 0.6)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / float(steps)
		var y := lerpf(top, bot, t)
		var w: float = hw.call(t)
		left.append(Vector2(0.5 - w, y))
		right.append(Vector2(0.5 + w, y))
	for p in right:
		pts.append(p)
	if shape == 9:
		for k in range(1, 6):
			var x := lerpf(0.5 + 0.44, 0.5 - 0.44, float(k) / 6.0)
			pts.append(Vector2(x, bot + 0.035 * (1 if k % 2 == 1 else 0)))
	left.reverse()
	for p in left:
		pts.append(p)
	return pts


func _draw() -> void:
	var asp := 1.62
	var s := minf(size.x, size.y / asp)
	var o := Vector2((size.x - s) * 0.5, (size.y - s * asp) * 0.5)
	var T := func(p: Vector2) -> Vector2: return o + p * s
	var shape := int(design.get("shape", 0)) % 10
	var glass_arr: Array = DB.biz["glass"][int(design.get("glass", 0)) % DB.biz["glass"].size()]
	var gcol := Color(glass_arr[1])
	var accent := Color(str(design.get("accent", "#c9a55a")))
	var opaque := int(design.get("glass", 0)) == 7
	if shadow:
		var sh := PackedVector2Array()
		for i in 32:
			var a := TAU * float(i) / 32.0
			sh.append(T.call(Vector2(0.5 + cos(a) * 0.42, 1.565 + sin(a) * 0.035)))
		draw_colored_polygon(sh, Color(0, 0, 0, 0.35))
	var body := _body(shape)
	var bp := PackedVector2Array()
	for p in body:
		bp.append(T.call(p))
	var miny := 99.0
	var maxy := -99.0
	for p in body:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	# glass
	var cols := PackedColorArray()
	for p in body:
		var f := (p.y - miny) / maxf(0.01, maxy - miny)
		var c := gcol.lightened(0.25 * (1.0 - f))
		c.a = 0.95 if opaque else 0.42
		cols.append(c)
	if Geometry2D.triangulate_polygon(bp).size() > 0:
		draw_polygon(bp, cols)
	# liquid
	if not opaque:
		var inner := Geometry2D.offset_polygon(bp, -s * 0.035)
		if not inner.is_empty():
			var lvl := lerpf(miny, maxy, 0.22)
			var cut := PackedVector2Array([T.call(Vector2(-1, lvl)), T.call(Vector2(2, lvl)), T.call(Vector2(2, 3)), T.call(Vector2(-1, 3))])
			for poly in Geometry2D.intersect_polygons(inner[0], cut):
				var lc := PackedColorArray()
				for p in poly:
					var f2 := (p.y - o.y) / (s * asp)
					var c3 := liquid.lerp(gcol, 0.35)
					c3 = c3.darkened(0.25 * f2)
					c3.a = 0.82
					lc.append(c3)
				if Geometry2D.triangulate_polygon(poly).size() > 0:
					draw_polygon(poly, lc)
				var surf_y := lvl * s + o.y
				draw_line(Vector2(poly[0].x, surf_y), Vector2(poly[0].x, surf_y), Color(1, 1, 1, 0.3), 2.0)
	# highlight
	var hl := Geometry2D.intersect_polygons(bp, PackedVector2Array([T.call(Vector2(0.18, 0)), T.call(Vector2(0.28, 0)), T.call(Vector2(0.28, 2)), T.call(Vector2(0.18, 2))]))
	for poly in hl:
		if Geometry2D.triangulate_polygon(poly).size() > 0:
			draw_colored_polygon(poly, Color(1, 1, 1, 0.16))
	var outline := bp.duplicate()
	outline.append(bp[0])
	draw_polyline(outline, Color(1, 1, 1, 0.45) if not opaque else accent, maxf(1.5, s * 0.008), true)
	# neck & collar
	var neck_top := miny - 0.07
	draw_rect(Rect2(T.call(Vector2(0.43, neck_top)), Vector2(0.14, 0.08) * s), accent.darkened(0.2), true)
	draw_rect(Rect2(T.call(Vector2(0.41, neck_top + 0.035)), Vector2(0.18, 0.03) * s), accent.lightened(0.2), true)
	_cap(T, s, int(design.get("cap", 0)) % 8, neck_top, accent)
	if show_label:
		_label(T, s, miny, maxy, int(design.get("label", 0)) % 6, accent, opaque)


func _metal(base: Color) -> Array:
	return [base.lightened(0.35), base, base.darkened(0.3)]


func _cap(T: Callable, s: float, cap: int, bottom: float, accent: Color) -> void:
	var m := _metal(accent)
	var cx := 0.5
	match cap:
		0:
			_grad_rect(T, s, Rect2(cx - 0.17, bottom - 0.3, 0.34, 0.3), m)
		1:
			var c = T.call(Vector2(cx, bottom - 0.16))
			draw_circle(c, s * 0.16, m[1])
			draw_circle(c + Vector2(-s * 0.05, -s * 0.05), s * 0.06, Color(m[0], 0.7))
		2:
			_grad_rect(T, s, Rect2(cx - 0.12, bottom - 0.34, 0.24, 0.34), m)
			draw_circle(T.call(Vector2(cx, bottom - 0.34)), s * 0.002, m[0])
		3:
			var pts := PackedVector2Array([T.call(Vector2(cx - 0.12, bottom)), T.call(Vector2(cx - 0.15, bottom - 0.2)), T.call(Vector2(cx - 0.08, bottom - 0.4)),
				T.call(Vector2(cx + 0.08, bottom - 0.4)), T.call(Vector2(cx + 0.15, bottom - 0.2)), T.call(Vector2(cx + 0.12, bottom))])
			draw_colored_polygon(pts, m[1])
			draw_colored_polygon(PackedVector2Array([pts[1], pts[2], T.call(Vector2(cx, bottom - 0.4)), T.call(Vector2(cx, bottom))]), m[0])
		4:
			var wood := Color("#6b4a2e")
			_grad_rect(T, s, Rect2(cx - 0.17, bottom - 0.27, 0.34, 0.27), [wood.lightened(0.2), wood, wood.darkened(0.3)])
			for k in 4:
				var y := bottom - 0.24 + k * 0.06
				draw_line(T.call(Vector2(cx - 0.15, y)), T.call(Vector2(cx + 0.15, y + 0.01)), Color(0, 0, 0, 0.2), 1.5)
		5:
			var pts2 := PackedVector2Array()
			for i in 25:
				var a := PI + PI * float(i) / 24.0
				pts2.append(T.call(Vector2(cx + cos(a) * 0.19, bottom + sin(a) * 0.24)))
			draw_colored_polygon(pts2, m[1])
			draw_arc(T.call(Vector2(cx, bottom)), s * 0.14, PI * 1.15, PI * 1.45, 8, m[0], s * 0.02)
		6:
			var cr := PackedVector2Array([T.call(Vector2(cx - 0.18, bottom)), T.call(Vector2(cx - 0.2, bottom - 0.24)), T.call(Vector2(cx - 0.09, bottom - 0.14)),
				T.call(Vector2(cx, bottom - 0.3)), T.call(Vector2(cx + 0.09, bottom - 0.14)), T.call(Vector2(cx + 0.2, bottom - 0.24)), T.call(Vector2(cx + 0.18, bottom))])
			draw_colored_polygon(cr, m[1])
			draw_circle(T.call(Vector2(cx, bottom - 0.31)), s * 0.025, m[0])
		7:
			var c2 = T.call(Vector2(cx, bottom - 0.13))
			draw_circle(c2, s * 0.13, m[1])
			draw_line(c2 + Vector2(s * 0.1, 0), c2 + Vector2(s * 0.24, s * 0.2), m[2], s * 0.012)
			draw_colored_polygon(PackedVector2Array([c2 + Vector2(s * 0.22, s * 0.2), c2 + Vector2(s * 0.27, s * 0.2), c2 + Vector2(s * 0.3, s * 0.38), c2 + Vector2(s * 0.19, s * 0.38)]), m[1])


func _grad_rect(T: Callable, s: float, r: Rect2, m: Array) -> void:
	var p0: Vector2 = T.call(r.position)
	var sz := r.size * s
	var pts := PackedVector2Array([p0, p0 + Vector2(sz.x, 0), p0 + sz, p0 + Vector2(0, sz.y)])
	draw_polygon(pts, PackedColorArray([m[0], m[1], m[2], m[1]]))
	draw_rect(Rect2(p0 + Vector2(sz.x * 0.12, 0), Vector2(sz.x * 0.1, sz.y)), Color(1, 1, 1, 0.18), true)


func _label(T: Callable, s: float, miny: float, maxy: float, style: int, accent: Color, opaque: bool) -> void:
	var cy := lerpf(miny, maxy, 0.55)
	var w := 0.46
	var h := 0.3
	var r := Rect2(T.call(Vector2(0.5 - w * 0.5, cy - h * 0.5)), Vector2(w, h) * s)
	var ink := Color("#1b1720")
	var paper := Color("#f3ebdd")
	match style:
		0:
			ink = accent.lightened(0.3) if not opaque else accent
		1:
			draw_rect(r, paper, true)
			draw_rect(r.grow(-s * 0.012), accent, false, maxf(1.0, s * 0.006))
		2:
			draw_rect(r, Color("#17131b"), true)
			draw_rect(r.grow(-s * 0.01), accent, false, maxf(1.0, s * 0.008))
			for k in 3:
				draw_arc(r.position + Vector2(r.size.x * 0.5, r.size.y), r.size.y * (0.25 + k * 0.12), PI * 1.2, PI * 1.8, 10, Color(accent, 0.5), 1.0)
			ink = accent.lightened(0.3)
		3:
			draw_rect(r, Color(paper, 0.9), true)
			ink = Color("#3b2a20")
		4:
			var c := r.get_center()
			draw_circle(c, r.size.y * 0.62, accent)
			draw_arc(c, r.size.y * 0.55, 0, TAU, 32, Color("#17131b"), 1.5)
			ink = Color("#17131b")
		5:
			draw_rect(r, Color("#e8efe0"), true)
			for k in 3:
				draw_arc(r.position + Vector2(-r.size.x * 0.05, r.size.y * (0.2 + k * 0.3)), r.size.y * 0.25, -0.6, 0.6, 8, Color("#5f7f52"), 1.5)
			ink = Color("#2f4a2a")
	var fb := UI.font("semi")
	var ft := UI.font("title")
	var bfs := maxi(8, int(s * 0.04))
	var pfs := maxi(9, int(s * 0.062))
	var bt := brand_name.to_upper()
	var pt := product_name
	var bw := fb.get_string_size(bt, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs).x
	while bw > r.size.x * 0.92 and bfs > 7:
		bfs -= 1
		bw = fb.get_string_size(bt, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs).x
	var pw := ft.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs).x
	while pw > r.size.x * 0.92 and pfs > 8:
		pfs -= 1
		pw = ft.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs).x
	var c2 := r.get_center()
	if pt != "":
		draw_string(ft, Vector2(c2.x - pw * 0.5, c2.y + pfs * 0.15), pt, HORIZONTAL_ALIGNMENT_LEFT, -1, pfs, ink)
	if bt != "":
		draw_string(fb, Vector2(c2.x - bw * 0.5, c2.y + pfs * 0.15 + bfs * 1.5), bt, HORIZONTAL_ALIGNMENT_LEFT, -1, bfs, Color(ink, 0.8))
