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
var vivid := false   # denser glass & liquid for busy or tinted backgrounds


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(idle_bubbles or _slosh > 0.0 or not _bubbles.is_empty())


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
	# saturate the mixed profile colour so juices read as distinct, jewel-like colours
	var h := mix.h
	var sat := clampf(mix.s * 1.35 + 0.12, 0.25, 0.78)
	var val := clampf(mix.v * 1.02 + 0.04, 0.55, 0.97)
	var c2 := base.lerp(Color.from_hsv(h, sat, val), 0.72)
	return c2.lerp(Color("#c47a2c"), clampf(warm * 0.7, 0.0, 0.45))


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
	if s <= 4.0:
		return
	var o := Vector2((size.x - s) * 0.5, (size.y - s * asp) * 0.5)
	var T := func(p: Vector2) -> Vector2: return o + p * s
	var shape := int(design.get("shape", 0)) % 10
	var glass_arr: Array = DB.biz["glass"][int(design.get("glass", 0)) % DB.biz["glass"].size()]
	var gcol := Color(glass_arr[1])
	var accent := Color(str(design.get("accent", "#c9a55a")))
	var opaque := int(design.get("glass", 0)) == 7
	var liq := tint_for(design, liquid)
	_liq_now = liq
	var body := _body(shape)
	var miny := 99.0
	var maxy := -99.0
	for p in body:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	if shadow:
		for k in 6:
			var sh := PackedVector2Array()
			var gw := 0.5 - k * 0.06
			var gh := 0.055 - k * 0.006
			for i in 32:
				var a := TAU * float(i) / 32.0
				sh.append(T.call(Vector2(0.5 + cos(a) * gw, maxy + 0.03 + sin(a) * gh)))
			draw_colored_polygon(sh, Color(0.35, 0.18, 0.24, 0.06))
		if not opaque:
			# light passing through the juice paints a soft coloured pool on the table
			var pool := PackedVector2Array()
			for i in 32:
				var a2 := TAU * float(i) / 32.0
				pool.append(T.call(Vector2(0.62 + cos(a2) * 0.34, maxy + 0.05 + sin(a2) * 0.035)))
			draw_colored_polygon(pool, Color(liq, 0.18))
	var bp := PackedVector2Array()
	for p in body:
		bp.append(T.call(p))
	var rows := _rows(body, 34)
	# glass body: darker, denser edges and a clear centre give the glass volume
	var g_edge := gcol.darkened(0.18)
	g_edge.a = 0.97 if opaque else (0.62 if vivid else 0.5)
	var g_mid := gcol.lightened(0.55)
	g_mid.a = 0.97 if opaque else (0.3 if vivid else 0.2)
	if opaque:
		g_edge = gcol.lightened(0.05)
		g_mid = gcol.lightened(0.28)
	_mesh(T, rows, [0.0, 0.1, 0.32, 0.5, 0.68, 0.9, 1.0], func(u: float, f: float) -> Color:
		var e := absf(u - 0.42) / 0.58
		var c := g_mid.lerp(g_edge, pow(clampf(e, 0.0, 1.0), 1.6))
		return c.darkened(0.08 * f))
	# liquid
	if not opaque:
		var lvl := lerpf(miny, maxy, 0.24)
		var inset := 0.034
		var lrows: Array = []
		for r in _rows(body, 34, lvl, maxy - 0.03):
			var xl: float = float(r[1]) + inset
			var xr: float = float(r[2]) - inset
			if xr - xl > 0.02:
				lrows.append([r[0], xl, xr])
		if lrows.size() >= 2:
			var wave := _slosh * 0.035
			var l_edge := liq.darkened(0.22)
			l_edge.a = 0.92
			var l_mid := liq.lightened(0.18)
			l_mid.a = 0.82
			var top_y: float = float(lrows[0][0])
			_mesh(T, lrows, [0.0, 0.12, 0.3, 0.5, 0.7, 0.88, 1.0], func(u: float, f: float) -> Color:
				var e := absf(u - 0.4) / 0.6
				var c := l_mid.lerp(l_edge, pow(clampf(e, 0.0, 1.0), 1.4))
				return c.darkened(0.18 * f), wave, _phase)
			# meniscus: a bright line across the surface
			var r0: Array = lrows[0]
			var pts := PackedVector2Array()
			for k in 9:
				var u2 := float(k) / 8.0
				var x := lerpf(float(r0[1]), float(r0[2]), u2)
				pts.append(T.call(Vector2(x, top_y + wave * sin(_phase + u2 * 5.0))))
			draw_polyline(pts, Color(1, 1, 1, 0.55), maxf(1.2, s * 0.008), true)
			# bubbles
			for b in _bubbles:
				var by: float = lerpf(maxy - 0.06, top_y + 0.02, float(b[1]))
				var row := _row_at(lrows, by)
				if row.is_empty():
					continue
				var bx := lerpf(float(row[1]) + 0.02, float(row[2]) - 0.02, float(b[0]))
				var br := float(b[2]) * s
				draw_circle(T.call(Vector2(bx, by)), br, Color(1, 1, 1, 0.22))
				draw_arc(T.call(Vector2(bx, by)), br, 0, TAU, 12, Color(1, 1, 1, 0.6), maxf(1.0, s * 0.004), true)
	# highlights: a long soft reflection on the left, a thin one on the right
	_streak(T, rows, 0.16, 0.27, 0.5 if not opaque else 0.22)
	_streak(T, rows, 0.78, 0.83, 0.26 if not opaque else 0.12)
	var outline := bp.duplicate()
	outline.append(bp[0])
	var rim := gcol.darkened(0.55)
	draw_polyline(outline, Color(rim, 0.5) if not opaque else accent.darkened(0.2), maxf(1.5, s * 0.012), true)
	var inner_ol := Geometry2D.offset_polygon(bp, -s * 0.014)
	if not inner_ol.is_empty() and not opaque:
		var io: PackedVector2Array = inner_ol[0].duplicate()
		io.append(io[0])
		draw_polyline(io, Color(1, 1, 1, 0.6), maxf(1.0, s * 0.006), true)
	# thick glass base
	var base_rows := _rows(body, 3, maxy - 0.06, maxy - 0.005)
	if base_rows.size() >= 2 and not opaque:
		_mesh(T, base_rows, [0.0, 0.5, 1.0], func(u: float, f: float) -> Color:
			return Color(1, 1, 1, 0.22 + 0.2 * (1.0 - absf(u - 0.5) * 2.0)))
	# neck & collar
	var neck_top := miny - 0.07
	var m := _metal(accent)
	_grad_rect(T, s, Rect2(0.43, neck_top, 0.14, 0.08), m)
	_grad_rect(T, s, Rect2(0.405, neck_top + 0.032, 0.19, 0.032), [m[0].lightened(0.2), m[0], m[1]])
	_cap(T, s, int(design.get("cap", 0)) % 8, neck_top, accent)
	if show_label:
		_label(T, s, miny, maxy, int(design.get("label", 0)) % 6, accent, opaque)


## Liquid tint: "natural" follows the scent profile; named tints colour the juice.
const TINTS := {"natural": "", "clear": "#f6f1e2", "blush": "#f4a9bb", "rose": "#df5a7c", "gold": "#e9b949", "amber": "#c8792a",
	"sapphire": "#5a8bd6", "emerald": "#45a878", "violet": "#9a72c9", "noir": "#4a2a3d"}


static func tint_for(d: Dictionary, natural: Color) -> Color:
	var t := str(d.get("tint", "natural"))
	if TINTS.has(t) and TINTS[t] != "":
		return Color(TINTS[t])
	return natural


## Stir the juice: the surface sloshes and bubbles rise (formula changes, launches).
func stir(strength := 1.0) -> void:
	_slosh = clampf(_slosh + strength, 0.0, 1.4)
	var r := RandomNumberGenerator.new()
	r.randomize()
	for i in int(6 + 8 * strength):
		_bubbles.append([r.randf(), r.randf() * 0.3, r.randf_range(0.008, 0.02), r.randf_range(0.25, 0.6)])
	set_process(true)


var _liq_now := Color("#f1dfa0")
var _slosh := 0.0
var _phase := 0.0
var _bubbles: Array = []   # [x 0..1, height 0..1, radius, speed]
var idle_bubbles := false:
	set(v):
		idle_bubbles = v
		if v and is_inside_tree():
			set_process(true)


func _process(delta: float) -> void:
	_phase += delta * 7.0
	_slosh = maxf(0.0, _slosh - delta * 0.9)
	for b in _bubbles:
		b[1] = float(b[1]) + delta * float(b[3])
	_bubbles = _bubbles.filter(func(b): return float(b[1]) < 1.0)
	if idle_bubbles and _bubbles.size() < 4 and randf() < delta * 1.5:
		_bubbles.append([randf(), 0.0, randf_range(0.006, 0.014), randf_range(0.12, 0.25)])
	queue_redraw()
	if _slosh <= 0.0 and _bubbles.is_empty() and not idle_bubbles:
		set_process(false)


## Horizontal spans of a polygon (unit coordinates): [[y, x_left, x_right], ...] from top to bottom.
static func _rows(poly: PackedVector2Array, n: int, y0 := -INF, y1 := INF) -> Array:
	var miny := 99.0
	var maxy := -99.0
	for p in poly:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var a := maxf(miny + 0.002, y0)
	var b := minf(maxy - 0.002, y1)
	var out: Array = []
	if b <= a:
		return out
	for i in n + 1:
		var y := lerpf(a, b, float(i) / float(n))
		var xl := 99.0
		var xr := -99.0
		var cnt := poly.size()
		for k in cnt:
			var p0 := poly[k]
			var p1 := poly[(k + 1) % cnt]
			if (p0.y <= y and p1.y >= y) or (p1.y <= y and p0.y >= y):
				if absf(p1.y - p0.y) < 0.00001:
					xl = minf(xl, minf(p0.x, p1.x))
					xr = maxf(xr, maxf(p0.x, p1.x))
				else:
					var x := p0.x + (y - p0.y) * (p1.x - p0.x) / (p1.y - p0.y)
					xl = minf(xl, x)
					xr = maxf(xr, x)
		if xr > xl:
			out.append([y, xl, xr])
	return out


static func _row_at(rows: Array, y: float) -> Array:
	for i in rows.size() - 1:
		if float(rows[i][0]) <= y and float(rows[i + 1][0]) >= y:
			return rows[i]
	return []


## Triangle mesh over row spans with per-vertex colours col(u across 0..1, f down 0..1).
## The first row can ripple (wave amplitude in unit coordinates).
func _mesh(T: Callable, rows: Array, us: Array, col: Callable, wave := 0.0, phase := 0.0) -> void:
	if rows.size() < 2:
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var nc := us.size()
	var y_top: float = float(rows[0][0])
	var y_bot: float = float(rows[rows.size() - 1][0])
	for ri in rows.size():
		var r: Array = rows[ri]
		var f := (float(r[0]) - y_top) / maxf(0.001, y_bot - y_top)
		for ci in nc:
			var u: float = us[ci]
			var x := lerpf(float(r[1]), float(r[2]), u)
			var y := float(r[0])
			if ri == 0 and wave != 0.0:
				y += wave * sin(phase + u * 5.0)
			pts.append(T.call(Vector2(x, y)))
			cols.append(col.call(u, f))
	for ri in rows.size() - 1:
		for ci in nc - 1:
			var a := ri * nc + ci
			var b := a + 1
			var c := a + nc
			var d := c + 1
			idx.append_array([a, b, d, a, d, c])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)


func _streak(T: Callable, rows: Array, u0: float, u1: float, alpha: float) -> void:
	if rows.size() < 4:
		return
	var sub := rows.slice(int(rows.size() * 0.08), int(rows.size() * 0.92))
	_mesh(T, sub, [u0, (u0 + u1) * 0.5, u1], func(u: float, f: float) -> Color:
		var mid := 1.0 - absf((u - u0) / maxf(0.001, u1 - u0) - 0.5) * 2.0
		var fade := sin(PI * clampf(f, 0.0, 1.0))
		return Color(1, 1, 1, alpha * mid * fade))


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
			if opaque:
				ink = accent
			else:
				ink = Color("#3b2433") if _liq_now.get_luminance() > 0.5 else Color("#fff8ec")
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
