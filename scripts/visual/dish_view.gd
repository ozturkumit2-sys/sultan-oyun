class_name DishView
extends Node2D
## Yemek görseli: tabak + süsleme + yemek tabanı + dekor + (canlıysa) yüz.
## Görsel veri FusionEngine'in "visual" sözlüğünden gelir: base, c1, c2, decor.

const INK := Color("#3b2417")
const W := 4.0

var item: Dictionary = {}
var plate := ""
var garnish := "none"
var alive := false
var face_mood := "happy"
var look := Vector2.ZERO
var show_shadow := true
var wobble := 0.0
var color_shift := 0.0
var _rig: Node2D
var _t := 0.0
var _blink := 0.0
var _blink_t := 2.0
var _anim := false


func _init() -> void:
	_rig = Node2D.new()
	add_child(_rig)
	_rig.draw.connect(_draw_rig)


## Gizli asistan karakterlerin görsel tanımları.
static func companion(id: String) -> Dictionary:
	match id:
		"cookie_wizard":
			return {"id": "a_cw", "name": "Kurabiye Büyücüsü", "visual": {"base": "cookie_wizard", "c1": "#e0a85a", "c2": "#7a4bd6", "decor": ["wizard_hat"]}}
		"toaster_bot":
			return {"id": "a_tb", "name": "Tost Robotu", "visual": {"base": "toast", "c1": "#d9a35a", "c2": "#9aa6b2", "decor": ["antenna", "bolts"]}}
		"jelly_dragon":
			return {"id": "a_jd", "name": "Jöle Ejderi", "visual": {"base": "jelly", "c1": "#7cff6b", "c2": "#ff6a1a", "decor": ["flames"]}}
	return {"id": "a", "visual": {"base": "dough", "c1": "#f2c05a", "c2": "#ff7ab8"}}


func setup(it: Dictionary, plate_id := "", garnish_id := "none") -> void:
	item = it
	plate = plate_id
	garnish = garnish_id
	_anim = _needs_anim()
	redraw()


func set_alive(v: bool) -> void:
	alive = v
	_anim = _needs_anim()
	redraw()


func redraw() -> void:
	_rig.queue_redraw()


func rig() -> Node2D:
	return _rig


func _needs_anim() -> bool:
	if alive:
		return true
	var dec: Array = item.get("visual", {}).get("decor", [])
	for d in ["flames", "ghost_wisps", "sparkles", "tentacles", "steam", "bubbles", "lightning"]:
		if dec.has(d):
			return true
	if item.get("visual", {}).get("base", "") == "jelly":
		return true
	if garnish == "stardust":
		return true
	return false


func _process(delta: float) -> void:
	_t += delta
	if alive:
		_blink_t -= delta
		if _blink_t <= 0.0:
			_blink = 0.12
			_blink_t = randf_range(1.5, 4.0)
		if _blink > 0.0:
			_blink -= delta
		look = Vector2(sin(_t * 1.3), cos(_t * 0.9) * 0.5)
	if _anim:
		_rig.queue_redraw()


func top_y() -> float:
	return _top_y(str(item.get("visual", {}).get("base", "cake")))


static func _top_y(base: String) -> float:
	match base:
		"cake":
			return -108.0
		"pie":
			return -44.0
		"souffle":
			return -114.0
		"cupcake":
			return -122.0
		"cookie":
			return -44.0
		"fritter":
			return -88.0
		"icecream":
			return -130.0
		"sorbet":
			return -112.0
		"jelly":
			return -104.0
		"soup":
			return -74.0
		"pasta":
			return -72.0
		"skewer":
			return -86.0
		"toast":
			return -120.0
		"potion":
			return -124.0
		"pizza":
			return -34.0
		"candy":
			return -86.0
		"frog_candy":
			return -98.0
		"dough":
			return -88.0
		"cookie_wizard":
			return -120.0
	return -74.0


func _c(key: String, def: String) -> Color:
	var v: Variant = item.get("visual", {}).get(key, def)
	var c := Color(str(v))
	if color_shift > 0.0:
		c.h = fposmod(c.h + color_shift, 1.0)
	return c


# ------------------------------------------------------------------ çizim
func _draw_rig() -> void:
	var r := _rig
	var vis: Dictionary = item.get("visual", {})
	var base: String = vis.get("base", "cake")
	var c1 := _c("c1", "#f2c05a")
	var c2 := _c("c2", "#ff7ab8")
	var decor: Array = vis.get("decor", [])
	if show_shadow:
		DrawKit.shadow(r, Vector2(0, 14), 130 if plate != "" else 80, 34 if plate != "" else 22, 0.35)
	if plate != "":
		_plate(r, plate)
		_garnish_plate(r)
	var sq := 1.0 + wobble
	if absf(wobble) > 0.001:
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / sq, sq))
	_base(r, base, c1, c2)
	_decor(r, base, decor, c1, c2)
	_garnish_dish(r, base)
	if alive:
		_face(r, base)
	if absf(wobble) > 0.001:
		r.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _plate(r: CanvasItem, pid: String) -> void:
	var p: Dictionary = IngredientDatabase.plates.get(pid, {"color": "#f4f4f0", "rim": "#d9d9d2"})
	var pc := Color(p.get("color", "#f4f4f0"))
	var rc := Color(p.get("rim", "#d9d9d2"))
	match pid:
		"wood":
			var board := DrawKit.smooth(PackedVector2Array([Vector2(-128, 18), Vector2(-112, -28), Vector2(112, -28), Vector2(128, 18)]), 1)
			DrawKit.shape(r, board, pc, W, 0.15, INK)
			for i in 4:
				var y := -18.0 + i * 9.0
				DrawKit.poly_line(r, DrawKit.quad(Vector2(-100, y), Vector2(0, y + 4 * sin(i)), Vector2(100, y)), Color(rc, 0.5), 2.0, false)
			DrawKit.shape(r, DrawKit.rrect(Rect2(124, -8, 34, 16), 8), pc.darkened(0.1), W, 0.1, INK)
		"slate":
			var sl := PackedVector2Array([Vector2(-132, 12), Vector2(-118, -30), Vector2(-40, -34), Vector2(60, -31), Vector2(124, -28), Vector2(134, 14), Vector2(40, 20), Vector2(-60, 18)])
			DrawKit.shape(r, sl, pc, W, 0.1, INK)
			DrawKit.outline(r, DrawKit.transform_pts(sl, Vector2(0, -2), Vector2(0.94, 0.86)), Color(1, 1, 1, 0.12), 2.0)
		"leaf":
			var lf := DrawKit.smooth(PackedVector2Array([Vector2(-140, 0), Vector2(-60, -36), Vector2(60, -36), Vector2(140, -4), Vector2(60, 26), Vector2(-60, 26)]), 2)
			DrawKit.shape(r, lf, pc, W, 0.15, INK)
			r.draw_line(Vector2(-130, 0), Vector2(130, -4), rc, 3.0, true)
			for i in 5:
				var x := -90.0 + i * 45.0
				r.draw_line(Vector2(x, -1), Vector2(x + 26, -22), rc, 2.0, true)
				r.draw_line(Vector2(x, -1), Vector2(x + 26, 18), rc, 2.0, true)
		_:
			var outer := DrawKit.ellipse(Vector2(0, 2), 120, 42, 48)
			var inner := DrawKit.ellipse(Vector2(0, 0), 92, 29, 44)
			var rim_col := rc if pid == "gold" or pid == "cosmic" or pid == "porcelain" else pc.darkened(0.06)
			if pid == "crystal":
				DrawKit.fill(r, outer, Color(pc, 0.7))
				DrawKit.outline(r, outer, Color("#5ec8ff"), 3.5)
				DrawKit.fill(r, inner, Color(1, 1, 1, 0.35))
				for i in 6:
					var a := TAU * i / 6.0
					r.draw_line(Vector2(cos(a) * 92, sin(a) * 29), Vector2(cos(a) * 118, sin(a) * 40), Color(1, 1, 1, 0.6), 2.0, true)
				return
			DrawKit.shape(r, outer, rim_col, W, 0.1, INK)
			if pid == "porcelain":
				for i in 16:
					var a2 := TAU * i / 16.0
					r.draw_circle(Vector2(cos(a2) * 106, sin(a2) * 36 + 1), 3.5, Color("#ffffff"), true, -1.0, true)
			DrawKit.fill(r, inner, pc, 0.06)
			DrawKit.outline(r, inner, pc.darkened(0.18), 2.5)
			if pid == "gold":
				DrawKit.outline(r, DrawKit.ellipse(Vector2(0, 0), 86, 27, 44), Color("#e2b33c"), 2.0)
			if pid == "cosmic":
				var rng := RandomNumberGenerator.new()
				rng.seed = 5
				for i in 14:
					var p2 := Vector2(rng.randf_range(-80, 80), rng.randf_range(-22, 22))
					if (p2.x * p2.x) / (88.0 * 88.0) + (p2.y * p2.y) / (27.0 * 27.0) < 1.0:
						r.draw_circle(p2, rng.randf_range(1.2, 2.6), Color(1, 1, 0.85, 0.9), true, -1.0, true)
			DrawKit.poly_line(r, DrawKit.arc(Vector2(0, 2), 108, 36, PI * 1.15, PI * 1.45, 10), Color(1, 1, 1, 0.55), 4.0)


func _garnish_plate(r: CanvasItem) -> void:
	match garnish:
		"mint":
			for k in 2:
				var c := Vector2(76 + k * 16, 4 - k * 8)
				var lf := DrawKit.ellipse(c, 16, 8, 16, -0.5 + k * 0.6)
				DrawKit.shape(r, lf, Color("#3ddc84"), 2.5, 0.2, Color("#1f6b3a"))
				r.draw_line(c + Vector2(-12, 6).rotated(-0.5 + k * 0.6), c + Vector2(12, -6).rotated(-0.5 + k * 0.6), Color("#1f6b3a"), 1.5, true)
		"sauce":
			for i in 7:
				var a := PI * 0.2 + PI * 0.6 * i / 6.0
				r.draw_circle(Vector2(cos(a) * 80, sin(a) * 22 + 2), 5.0 - absf(i - 3) * 0.6, Color("#9b2d2d"), true, -1.0, true)
			DrawKit.poly_line(r, DrawKit.arc(Vector2(0, 2), 86, 24, PI * 1.05, PI * 1.35, 10), Color("#9b2d2d"), 4.0)
		"flower":
			var fc := Vector2(-78, 6)
			for k in 5:
				var a := TAU * k / 5.0
				DrawKit.circle(r, fc + Vector2(cos(a), sin(a) * 0.6) * 9, 7, Color("#ff7ab8"), 2.0, 0.1)
			r.draw_circle(fc, 5, Color("#ffd23f"), true, -1.0, true)
		"chili_flakes":
			var rng := RandomNumberGenerator.new()
			rng.seed = 21
			for i in 16:
				var a := rng.randf() * TAU
				r.draw_circle(Vector2(cos(a) * rng.randf_range(70, 100), sin(a) * rng.randf_range(20, 30)), 2.5, Color("#d92b1c"), true, -1.0, true)
		"cobweb":
			var ctr := Vector2(-96, -6)
			for k in 5:
				var a := -0.9 + k * 0.45
				r.draw_line(ctr, ctr + Vector2(cos(a), sin(a) * 0.5) * 60, Color(1, 1, 1, 0.75), 1.5, true)
			for ring in [18.0, 34.0, 50.0]:
				var pts := PackedVector2Array()
				for k in 5:
					var a2 := -0.9 + k * 0.45
					pts.append(ctr + Vector2(cos(a2), sin(a2) * 0.5) * ring)
				r.draw_polyline(pts, Color(1, 1, 1, 0.75), 1.5, true)
		"sprinkles":
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 9
			var cols := [Color("#ff5fa2"), Color("#ffd23f"), Color("#4a9dff"), Color("#3ddc84")]
			for i in 14:
				var a3 := rng2.randf() * TAU
				var p := Vector2(cos(a3) * rng2.randf_range(80, 104), sin(a3) * rng2.randf_range(24, 34))
				var d := Vector2(cos(i * 1.3), sin(i * 1.3)) * 4.0
				r.draw_line(p - d, p + d, cols[i % 4], 3.0, true)


func _garnish_dish(r: CanvasItem, base: String) -> void:
	var top := _top_y(base)
	match garnish:
		"gold_leaf":
			for p in [Vector2(-14, top + 4), Vector2(10, top - 2), Vector2(22, top + 10)]:
				DrawKit.shape(r, PackedVector2Array([p + Vector2(-6, 0), p + Vector2(0, -7), p + Vector2(7, -1), p + Vector2(2, 6)]), Color("#f2c14e"), 1.5, 0.2, Color("#a0761c"))
		"stardust":
			for k in 6:
				var a := TAU * k / 6.0 + _t * 0.8
				var p2 := Vector2(cos(a) * 80, top * 0.5 + sin(a) * 40)
				var s := 6.0 + 3.0 * sin(_t * 6.0 + k)
				DrawKit.fill(r, DrawKit.star_pts(p2, s, s * 0.3, 4), Color("#fff1a8"))
		"sprinkles":
			var cols := [Color("#ff5fa2"), Color("#ffd23f"), Color("#4a9dff"), Color("#3ddc84")]
			for i in 8:
				var p3 := Vector2(-28 + i * 8, top + 6 + (i % 3) * 4)
				var d := Vector2(cos(i * 1.7), sin(i * 1.7)) * 3.5
				r.draw_line(p3 - d, p3 + d, cols[i % 4], 3.0, true)
		"chili_flakes":
			for i in 6:
				r.draw_circle(Vector2(-20 + i * 8, top + 8 + (i % 2) * 5), 2.4, Color("#d92b1c"), true, -1.0, true)
		"mint":
			var lf := DrawKit.ellipse(Vector2(8, top - 4), 12, 6, 14, -0.7)
			DrawKit.shape(r, lf, Color("#3ddc84"), 2.0, 0.2, Color("#1f6b3a"))


# ------------------------------------------------------------------ yemek tabanları
func _base(r: CanvasItem, base: String, c1: Color, c2: Color) -> void:
	var ink := INK
	match base:
		"none":
			pass
		"cake":
			var body := PackedVector2Array([Vector2(-62, -82), Vector2(-62, -2)])
			body.append_array(DrawKit.arc(Vector2(0, -2), 62, 18, PI, 0.0, 20))
			body.append(Vector2(62, -82))
			DrawKit.shape(r, body, c1.darkened(0.08), W, 0.12, ink)
			var band := PackedVector2Array([Vector2(-62, -50)])
			band.append_array(DrawKit.arc(Vector2(0, -50), 62, 16, PI, 0.0, 16))
			band.append(Vector2(62, -40))
			band.append_array(DrawKit.arc(Vector2(0, -40), 62, 16, 0.0, PI, 16))
			DrawKit.fill(r, band, c2.lightened(0.35))
			var top := DrawKit.ellipse(Vector2(0, -84), 66, 20, 36)
			var drip := PackedVector2Array()
			for i in 13:
				var a := PI * i / 12.0
				var x := cos(a) * 66
				var y := -84 + sin(a) * 20
				var dl := 14.0 + 12.0 * float((i * 7) % 3)
				drip.append(Vector2(x, y + (dl if i % 2 == 1 else 4.0)))
			var frost := DrawKit.arc(Vector2(0, -84), 66, 20, PI, TAU, 18)
			frost.append_array(DrawKit.smooth(drip, 1, false))
			DrawKit.shape(r, frost, c2, W, 0.12, ink)
			DrawKit.shine(r, Vector2(-30, -90), 18, 6, 0.5, -0.1)
		"pie":
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, -6), 86, 28, 40), Color("#d0904a"), W, 0.1, ink)
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, -20), 84, 26, 40), Color("#e8b064"), W, 0.12, ink)
			var fill_e := DrawKit.ellipse(Vector2(0, -22), 68, 19, 36)
			DrawKit.fill(r, fill_e, c1, 0.15)
			for i in 5:
				var x := -48.0 + i * 24.0
				_clip_line(r, Vector2(x - 20, -40), Vector2(x + 20, -4), fill_e, Color("#f2c27a"), 7.0)
				_clip_line(r, Vector2(x + 20, -40), Vector2(x - 20, -4), fill_e, Color("#f2c27a"), 7.0)
			DrawKit.outline(r, fill_e, ink, 3.0)
			for p in [Vector2(-30, -26), Vector2(16, -18), Vector2(38, -28)]:
				r.draw_circle(p, 5, c2, true, -1.0, true)
		"souffle":
			var cup := PackedVector2Array([Vector2(-56, -52), Vector2(-56, -2)])
			cup.append_array(DrawKit.arc(Vector2(0, -2), 56, 16, PI, 0.0, 16))
			cup.append(Vector2(56, -52))
			DrawKit.shape(r, cup, Color("#f6f2ea"), W, 0.12, ink)
			for i in 7:
				var x2 := -42.0 + i * 14.0
				r.draw_line(Vector2(x2, -46), Vector2(x2, -6 + absf(x2) * 0.1), Color("#d8d0c4"), 2.5, true)
			var puff := DrawKit.smooth(PackedVector2Array([Vector2(-60, -50), Vector2(-62, -78), Vector2(-40, -106), Vector2(0, -116),
				Vector2(40, -106), Vector2(62, -78), Vector2(60, -50), Vector2(0, -40)]), 2)
			DrawKit.shape(r, puff, c1, W, 0.2, ink)
			DrawKit.poly_line(r, DrawKit.arc(Vector2(0, -80), 34, 14, PI * 1.1, PI * 1.9, 10), c2, 5.0)
			DrawKit.shine(r, Vector2(-26, -96), 14, 6, 0.5, -0.4)
		"cupcake":
			var wrap := PackedVector2Array([Vector2(-58, -52), Vector2(58, -52), Vector2(44, -2), Vector2(-44, -2)])
			DrawKit.shape(r, wrap, c2, W, 0.12, ink)
			for i in 6:
				var x3 := -40.0 + i * 16.0
				r.draw_line(Vector2(x3 * 1.3, -50), Vector2(x3, -4), c2.darkened(0.2), 3.0, true)
			for k in 3:
				var cy := -66.0 - k * 22.0
				var rx := 62.0 - k * 15.0
				DrawKit.shape(r, DrawKit.ellipse(Vector2(0, cy), rx, 20 - k * 2.0, 32), c1, W, 0.2, ink)
			DrawKit.shape(r, DrawKit.smooth(PackedVector2Array([Vector2(-10, -126), Vector2(0, -140), Vector2(10, -126)]), 1), c1, W, 0.1, ink)
		"cookie":
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, -12), 78, 30, 40), c1.darkened(0.15), W, 0.1, ink)
			var ck := DrawKit.ellipse(Vector2(0, -20), 76, 28, 40)
			DrawKit.shape(r, ck, c1, W, 0.15, ink)
			var rng := RandomNumberGenerator.new()
			rng.seed = 3
			for i in 9:
				var p := Vector2(rng.randf_range(-56, 56), rng.randf_range(-36, -6))
				if Geometry2D.is_point_in_polygon(p, ck):
					DrawKit.fill(r, DrawKit.blob(p, 6, i, 0.3, 6), c2)
		"fritter":
			for p in [Vector2(-20, -58), Vector2(22, -56), Vector2(-42, -24), Vector2(0, -22), Vector2(42, -24)]:
				DrawKit.circle(r, p, 30, c1, W, 0.25, ink)
				DrawKit.poly_line(r, DrawKit.arc(p + Vector2(0, -4), 18, 10, PI * 1.1, PI * 1.9, 8), c2, 5.0)
				DrawKit.shine(r, p + Vector2(-12, -12), 7, 4, 0.5, -0.5)
		"icecream":
			var bowl := DrawKit.smooth(PackedVector2Array([Vector2(-74, -46), Vector2(74, -46), Vector2(50, -6), Vector2(-50, -6)]), 1)
			DrawKit.shape(r, bowl, Color(0.95, 0.97, 1.0, 0.85), W, 0.1, ink)
			DrawKit.circle(r, Vector2(-28, -64), 30, c1, W, 0.2, ink)
			DrawKit.circle(r, Vector2(28, -64), 30, c2, W, 0.2, ink)
			DrawKit.circle(r, Vector2(0, -98), 32, c1.lightened(0.15), W, 0.2, ink)
			DrawKit.poly_line(r, DrawKit.quad(Vector2(-24, -110), Vector2(0, -96), Vector2(26, -112)), c2.darkened(0.2), 5.0)
			DrawKit.shape(r, DrawKit.rrect(Rect2(30, -138, 12, 46), 5).duplicate(), Color("#e8b064"), 3.0, 0.1, ink)
			DrawKit.shine(r, Vector2(-14, -110), 9, 5, 0.6, -0.4)
		"sorbet":
			r.draw_line(Vector2(0, -6), Vector2(0, -40), INK, 12.0, true)
			r.draw_line(Vector2(0, -6), Vector2(0, -40), Color(0.92, 0.96, 1.0), 6.0, true)
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, -4), 34, 9, 24), Color(0.92, 0.96, 1.0, 0.95), 3.0, 0.0, ink)
			var cp := DrawKit.smooth(PackedVector2Array([Vector2(-76, -66), Vector2(76, -66), Vector2(40, -40), Vector2(-40, -40)]), 1)
			DrawKit.shape(r, cp, Color(0.92, 0.96, 1.0, 0.9), W, 0.0, ink)
			var sc := DrawKit.blob(Vector2(0, -86), 40, 4, 0.08, 12)
			DrawKit.shape(r, sc, c1, W, 0.2, ink)
			DrawKit.poly_line(r, DrawKit.arc(Vector2(0, -88), 24, 12, PI * 0.9, PI * 1.9, 10), c2, 5.0)
			DrawKit.shine(r, Vector2(-16, -102), 10, 5, 0.55, -0.4)
		"jelly":
			var pts := PackedVector2Array()
			for i in 24:
				var a := PI + PI * i / 23.0
				var wob := 1.0 + 0.04 * sin(_t * 6.0 + i * 0.7)
				pts.append(Vector2(cos(a) * 72 * wob, -6 + sin(a) * 98 * wob))
			var jc := c1
			jc.a = 0.88
			DrawKit.shape(r, pts, jc, W, 0.2, ink)
			var lower := PackedVector2Array()
			for p in pts:
				if p.y > -40:
					lower.append(p)
			if lower.size() > 2:
				DrawKit.fill(r, lower, Color(c2, 0.7))
			DrawKit.shine(r, Vector2(-30, -70), 12, 22, 0.45, 0.3)
			r.draw_circle(Vector2(20, -40), 6, Color(1, 1, 1, 0.35), true, -1.0, true)
		"soup", "blob":
			var rim_y := -54.0 if base == "soup" else -46.0
			var rx2 := 86.0 if base == "soup" else 70.0
			var bowl2 := DrawKit.arc(Vector2(0, rim_y), rx2, 54 if base == "soup" else 42, 0.0, PI, 24)
			DrawKit.shape(r, bowl2, Color("#f4ede4"), W, 0.15, ink)
			DrawKit.poly_line(r, DrawKit.arc(Vector2(0, rim_y), rx2 - 2, 40 if base == "soup" else 30, PI * 0.18, PI * 0.82, 14), c2.darkened(0.1), 6.0, false)
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, rim_y), rx2, 22, 40), Color("#fbf7f0"), W, 0.0, ink)
			var surf := DrawKit.ellipse(Vector2(0, rim_y + 1), rx2 - 12, 16, 36)
			if base == "blob":
				DrawKit.fill(r, surf, c1)
				var sw := PackedVector2Array()
				for i in 30:
					var a2 := i * 0.42
					sw.append(Vector2(cos(a2), sin(a2) * 0.3) * (4.0 + i * 1.7) + Vector2(0, rim_y))
				DrawKit.poly_line(r, sw, c2, 6.0)
			else:
				DrawKit.fill(r, surf, c1, 0.1)
				for i in 4:
					var bp := Vector2(-40 + i * 26, rim_y + (i % 2) * 6 - 2)
					r.draw_arc(bp, 5.0 + (i % 2) * 2.0, 0, TAU, 14, c1.lightened(0.35), 2.5, true)
		"pasta":
			var mound := DrawKit.smooth(PackedVector2Array([Vector2(-80, -8), Vector2(-66, -46), Vector2(-24, -70), Vector2(24, -70), Vector2(66, -46), Vector2(80, -8), Vector2(0, 4)]), 2)
			DrawKit.shape(r, mound, c1, W, 0.15, ink)
			for i in 9:
				var y2 := -56.0 + i * 6.0
				var sq := PackedVector2Array()
				for k in 9:
					var x4 := -60.0 + k * 15.0 + float(i % 2) * 6.0
					sq.append(Vector2(x4, y2 + sin(k * 1.4 + i) * 5.0))
				_clip_poly_line(r, sq, mound, c1.darkened(0.2), 3.0)
			var sauce := DrawKit.blob(Vector2(0, -56), 34, 12, 0.18, 10)
			DrawKit.shape(r, sauce, c2, 3.5, 0.15, ink)
		"skewer":
			DrawKit.line(r, Vector2(-92, -6), Vector2(92, -82), INK, 12.0)
			DrawKit.line(r, Vector2(-92, -6), Vector2(92, -82), Color("#c8955c"), 6.0)
			for i in 4:
				var t := 0.18 + i * 0.21
				var p3 := Vector2(-92, -6).lerp(Vector2(92, -82), t)
				var chunk := DrawKit.rrect(Rect2(-22, -20, 44, 40), 12)
				chunk = DrawKit.transform_pts(chunk, p3, Vector2.ONE, -0.39)
				DrawKit.shape(r, chunk, c1 if i % 2 == 0 else c2, W, 0.2, ink)
				for k in 2:
					var o := Vector2(-8 + k * 14, 0).rotated(-0.39)
					r.draw_line(p3 + o + Vector2(-4, -12), p3 + o + Vector2(4, 12), Color(0.2, 0.1, 0.05, 0.6), 3.0, true)
		"toast":
			var slice := DrawKit.smooth(PackedVector2Array([Vector2(-62, -2), Vector2(-64, -72), Vector2(-76, -96), Vector2(-46, -120), Vector2(0, -124),
				Vector2(46, -120), Vector2(76, -96), Vector2(64, -72), Vector2(62, -2)]), 2)
			DrawKit.shape(r, slice, c1.darkened(0.3), W, 0.12, ink)
			var inner := DrawKit.transform_pts(slice, Vector2(0, -4), Vector2(0.84, 0.88))
			DrawKit.fill(r, inner, c1.lightened(0.1), 0.1)
			var top_poly := PackedVector2Array()
			for p4 in inner:
				if p4.y < -70:
					top_poly.append(p4)
			var melt := PackedVector2Array([Vector2(-50, -96), Vector2(-40, -112), Vector2(0, -116), Vector2(40, -112), Vector2(52, -96), Vector2(44, -70),
				Vector2(34, -84), Vector2(20, -60), Vector2(6, -82), Vector2(-14, -66), Vector2(-26, -86), Vector2(-42, -74)])
			DrawKit.shape(r, DrawKit.smooth(melt, 1), c2, 3.5, 0.15, ink)
		"potion":
			var flask := DrawKit.ellipse(Vector2(0, -50), 48, 46, 36)
			DrawKit.fill(r, flask, Color(0.9, 0.95, 1.0, 0.55))
			_clip_fill(r, PackedVector2Array([Vector2(-60, -56 + sin(_t * 3.0) * 3.0), Vector2(60, -56 - sin(_t * 3.0) * 3.0), Vector2(60, 10), Vector2(-60, 10)]), flask, c1)
			DrawKit.glow(r, Vector2(0, -40), 60, Color(c1, 0.35))
			for i in 3:
				var by := -20.0 - fmod(_t * 30.0 + i * 14.0, 40.0)
				r.draw_circle(Vector2(-14 + i * 14, by), 4, c2.lightened(0.3), true, -1.0, true)
			DrawKit.outline(r, flask, INK, W)
			DrawKit.shape(r, DrawKit.rrect(Rect2(-16, -112, 32, 26), 6), Color(0.9, 0.95, 1.0, 0.7), W, 0.0, ink)
			DrawKit.shape(r, DrawKit.rrect(Rect2(-13, -128, 26, 20), 6), Color("#a8743c"), W, 0.15, ink)
			DrawKit.shine(r, Vector2(-22, -66), 8, 14, 0.6, 0.3)
		"pizza":
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, -10), 94, 34, 44), Color("#e8b064"), W, 0.12, ink)
			DrawKit.fill(r, DrawKit.ellipse(Vector2(0, -12), 82, 28, 40), Color("#d94a2b"))
			DrawKit.fill(r, DrawKit.transform_pts(DrawKit.blob(Vector2.ZERO, 70, 8, 0.12, 12), Vector2(0, -12), Vector2(1.0, 0.36)), c2)
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 6
			for i in 7:
				var pp := Vector2(rng2.randf_range(-56, 56), rng2.randf_range(-28, 4))
				DrawKit.shape(r, DrawKit.ellipse(pp, 10, 5, 14), c1.darkened(0.1) if c1.get_luminance() < 0.6 else Color("#c0392b"), 2.0, 0.1, ink)
			for k in 3:
				var a3 := PI * k / 3.0
				r.draw_line(Vector2(cos(a3) * 80, sin(a3) * 26 - 12), Vector2(-cos(a3) * 80, -sin(a3) * 26 - 12), Color(0.5, 0.25, 0.1, 0.5), 2.0, true)
		"candy":
			for p5 in [Vector2(0, -58), Vector2(-34, -26), Vector2(34, -26)]:
				DrawKit.circle(r, p5, 28, c1, W, 0.25, ink)
				DrawKit.poly_line(r, PackedVector2Array([p5 + Vector2(-18, -6), p5 + Vector2(-6, -14), p5 + Vector2(6, -4), p5 + Vector2(18, -12)]), c2, 4.0)
				DrawKit.shine(r, p5 + Vector2(-10, -12), 7, 4, 0.5, -0.5)
		"frog_candy":
			var bd := DrawKit.ellipse(Vector2(0, -36), 62, 38, 36)
			DrawKit.shape(r, bd, c1, W, 0.2, ink)
			for s in [-1.0, 1.0]:
				DrawKit.shape(r, DrawKit.ellipse(Vector2(s * 50, -10), 22, 12, 18), c1.darkened(0.08), W, 0.1, ink)
				DrawKit.circle(r, Vector2(s * 26, -76), 18, c1, W, 0.15, ink)
				if not alive:
					DrawKit.circle(r, Vector2(s * 26, -78), 11, Color.WHITE, 3.0, 0.0, ink)
					r.draw_circle(Vector2(s * 26 + 2, -77), 5, INK, true, -1.0, true)
			if not alive:
				DrawKit.poly_line(r, DrawKit.quad(Vector2(-26, -42), Vector2(0, -28), Vector2(26, -42)), ink, 4.0)
			for p6 in [Vector2(-30, -26), Vector2(20, -20), Vector2(36, -44), Vector2(-10, -52), Vector2(4, -14)]:
				r.draw_circle(p6, 4, c2, true, -1.0, true)
		"dough":
			var db := DrawKit.blob(Vector2(0, -40), 52, 17, 0.08, 10)
			DrawKit.shape(r, db, c1, W, 0.18, ink)
			for p7 in [Vector2(-20, -50), Vector2(14, -30), Vector2(24, -60), Vector2(-8, -20)]:
				r.draw_circle(p7, 3, c2, true, -1.0, true)
			DrawKit.shine(r, Vector2(-20, -64), 14, 7, 0.4, -0.4)
		"cookie_wizard":
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, -46), 50, 46, 32), c1, W, 0.18, ink)
			for p8 in [Vector2(-20, -30), Vector2(18, -24), Vector2(4, -64)]:
				DrawKit.fill(r, DrawKit.blob(p8, 5, int(p8.x), 0.3, 6), Color("#6b3a1e"))
		_:
			DrawKit.shape(r, DrawKit.blob(Vector2(0, -40), 50, 2, 0.1, 10), c1, W, 0.18, ink)


func _clip_fill(r: CanvasItem, poly: PackedVector2Array, clip: PackedVector2Array, col: Color) -> void:
	for p in Geometry2D.intersect_polygons(poly, clip):
		if p.size() >= 3:
			r.draw_colored_polygon(p, col)


func _clip_line(r: CanvasItem, a: Vector2, b: Vector2, clip: PackedVector2Array, col: Color, w: float) -> void:
	var res := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), clip)
	for seg in res:
		if seg.size() >= 2:
			r.draw_polyline(seg, col, w, true)


func _clip_poly_line(r: CanvasItem, pts: PackedVector2Array, clip: PackedVector2Array, col: Color, w: float) -> void:
	for seg in Geometry2D.intersect_polyline_with_polygon(pts, clip):
		if seg.size() >= 2:
			r.draw_polyline(seg, col, w, true)


# ------------------------------------------------------------------ dekor
func _decor(r: CanvasItem, base: String, decor: Array, c1: Color, c2: Color) -> void:
	var top := _top_y(base)
	for d in decor:
		match d:
			"flames":
				for i in 3:
					var bx := -26.0 + i * 26.0
					var h := 34.0 + 10.0 * sin(_t * 10.0 + i * 2.0)
					var b := Vector2(bx, top + 6)
					var fl := DrawKit.smooth(PackedVector2Array([b + Vector2(-12, 0), b + Vector2(-8, -h * 0.55), b + Vector2(0, -h), b + Vector2(8, -h * 0.55), b + Vector2(12, 0)]), 2)
					DrawKit.fill(r, fl, Color(1.0, 0.42, 0.1, 0.95))
					DrawKit.fill(r, DrawKit.transform_pts(fl, b * 0.45, Vector2(0.55, 0.6)) , Color(1.0, 0.86, 0.25, 0.95))
				DrawKit.glow(r, Vector2(0, top - 10), 70, Color(1.0, 0.5, 0.1, 0.3))
			"ghost_wisps":
				for i in 2:
					var a := _t * 1.6 + i * PI
					var gp := Vector2(cos(a) * 78, top * 0.6 + sin(a * 2.0) * 14)
					var g := DrawKit.smooth(PackedVector2Array([gp + Vector2(-12, 10), gp + Vector2(-12, -6), gp + Vector2(0, -16), gp + Vector2(12, -6), gp + Vector2(12, 10),
						gp + Vector2(6, 6), gp + Vector2(0, 12), gp + Vector2(-6, 6)]), 1)
					DrawKit.shape(r, g, Color(0.95, 0.97, 1.0, 0.92), 2.5, 0.0, Color("#7a86c9"))
					r.draw_circle(gp + Vector2(-4, -4), 2.2, INK, true, -1.0, true)
					r.draw_circle(gp + Vector2(4, -4), 2.2, INK, true, -1.0, true)
			"frog_eyes":
				if not alive:
					for s in [-1.0, 1.0]:
						var ep := Vector2(s * 22, top - 8)
						DrawKit.circle(r, ep, 13, Color("#7fdc5f"), 3.0)
						DrawKit.circle(r, ep + Vector2(0, -1), 8, Color.WHITE, 2.0, 0.0)
						r.draw_circle(ep + Vector2(1, 0), 4, INK, true, -1.0, true)
			"bolts":
				for p in [Vector2(-34, top + 14), Vector2(30, top + 4)]:
					DrawKit.line(r, p, p + Vector2(0, -22), INK, 9.0)
					DrawKit.line(r, p, p + Vector2(0, -22), Color("#9aa6b2"), 4.5)
					var hx := DrawKit.ellipse(p + Vector2(0, -24), 9, 9, 6)
					DrawKit.shape(r, hx, Color("#b8c2cc"), 2.5, 0.2, INK)
			"beetle_legs":
				for s in [-1.0, 1.0]:
					for k in 3:
						var lp := Vector2(s * 56, -16 - k * 12)
						DrawKit.poly_line(r, PackedVector2Array([lp, lp + Vector2(s * 16, -6), lp + Vector2(s * 22, 6)]), Color("#2a3a35"), 3.5)
			"stars":
				for i in 4:
					var a2 := TAU * i / 4.0 + _t * 0.3
					var sp := Vector2(cos(a2) * 70, top * 0.6 + sin(a2) * 30)
					DrawKit.shape(r, DrawKit.star_pts(sp, 10, 4.5), Color("#ffd23f"), 2.0, 0.0, Color("#a0761c"))
			"lightning":
				for s in [-1.0, 1.0]:
					var lb := Vector2(s * 62, top * 0.7)
					var on := int(_t * 6.0 + (1 if s > 0 else 0)) % 3 != 0
					if on:
						DrawKit.poly_line(r, PackedVector2Array([lb, lb + Vector2(s * 10, 12), lb + Vector2(0, 18), lb + Vector2(s * 12, 34)]), Color("#fff36b"), 5.0)
			"ice_shards":
				for p in [Vector2(-30, top + 6), Vector2(0, top - 4), Vector2(28, top + 8)]:
					var cr := PackedVector2Array([p + Vector2(-7, 6), p + Vector2(0, -22), p + Vector2(7, 6)])
					DrawKit.shape(r, cr, Color("#bff3ff"), 2.5, 0.3, Color("#2b7fb3"))
			"flowers":
				for p in [Vector2(-22, top + 4), Vector2(18, top - 2)]:
					for k in 5:
						var a3 := TAU * k / 5.0
						r.draw_circle(p + Vector2(cos(a3), sin(a3)) * 6, 5, Color("#ffd6f3"), true, -1.0, true)
					r.draw_circle(p, 4, Color("#ffd23f"), true, -1.0, true)
			"roses":
				var rp := Vector2(0, top - 6)
				DrawKit.circle(r, rp, 16, Color("#8e1236"), 3.0)
				DrawKit.poly_line(r, DrawKit.arc(rp, 9, 9, 0.0, TAU * 0.8, 12), Color("#5a0b22"), 3.0)
				DrawKit.shape(r, DrawKit.ellipse(rp + Vector2(18, 8), 10, 5, 12, 0.4), Color("#2f7a3a"), 2.0, 0.0, INK)
			"tentacles":
				for s in [-1.0, 1.0]:
					var tb := Vector2(s * 50, -30)
					var sw := sin(_t * 2.5 + s) * 12.0
					var tp := DrawKit.bezier(tb, tb + Vector2(s * 40, -10), tb + Vector2(s * 50 + sw, -60), tb + Vector2(s * 20 + sw, -70), 12)
					DrawKit.stroke(r, tp, Color("#7a5cd6"), 9.0, INK, 3.0)
			"sparkles":
				for i in 4:
					var a4 := TAU * i / 4.0 + 0.6
					var sp2 := Vector2(cos(a4) * 64, top * 0.5 + sin(a4) * 40)
					var s2 := 5.0 + 4.0 * absf(sin(_t * 4.0 + i))
					DrawKit.fill(r, DrawKit.star_pts(sp2, s2, s2 * 0.28, 4), Color(1, 1, 0.8, 0.95))
			"sprinkles":
				var cols := [Color("#ff5fa2"), Color("#ffd23f"), Color("#4a9dff"), Color("#3ddc84"), Color("#ffffff")]
				for i in 10:
					var p2 := Vector2(-34 + i * 7.5, top + 8 + (i * 5 % 9))
					var dd := Vector2(cos(i * 2.1), sin(i * 2.1)) * 3.5
					r.draw_line(p2 - dd, p2 + dd, cols[i % 5], 3.0, true)
			"gold_leaf":
				for p in [Vector2(-10, top + 2), Vector2(14, top + 8)]:
					DrawKit.shape(r, PackedVector2Array([p + Vector2(-7, 0), p + Vector2(0, -8), p + Vector2(8, -1), p + Vector2(2, 7)]), Color("#f2c14e"), 1.5, 0.2, Color("#a0761c"))
			"bubbles":
				for i in 4:
					var by := top - fmod(_t * 26.0 + i * 12.0, 46.0)
					r.draw_arc(Vector2(-24 + i * 16, by), 4.0 + (i % 2) * 2.0, 0, TAU, 14, Color(c2.lightened(0.3), 0.85), 2.0, true)
			"drizzle":
				for i in 4:
					var x := -40.0 + i * 26.0
					DrawKit.poly_line(r, PackedVector2Array([Vector2(x, top + 8), Vector2(x + 3, top + 24 + (i % 2) * 10)]), c2.darkened(0.15), 5.0)
			"steam":
				for i in 3:
					var x2 := -20.0 + i * 20.0
					var pts := PackedVector2Array()
					for k in 8:
						var y := top - 8 - k * 6.0
						pts.append(Vector2(x2 + sin(_t * 3.0 + k * 0.8 + i) * 5.0, y))
					r.draw_polyline(pts, Color(1, 1, 1, 0.55), 3.0, true)
			"cherry":
				DrawKit.poly_line(r, DrawKit.quad(Vector2(0, top - 8), Vector2(4, top - 26), Vector2(14, top - 32)), Color("#3f8f2f"), 3.0)
				DrawKit.circle(r, Vector2(0, top - 4), 11, Color("#d9203a"), 3.0)
				DrawKit.shine(r, Vector2(-4, top - 8), 3, 2, 0.8)
			"meatballs":
				for p in [Vector2(-26, -50), Vector2(24, -46), Vector2(0, -66)]:
					DrawKit.circle(r, p, 12, Color("#7a4426"), 3.0)
			"wizard_hat":
				var hb := Vector2(0, top + 4)
				DrawKit.shape(r, DrawKit.ellipse(hb, 30, 8, 20), Color("#4b3bb5"), 3.0, 0.1, INK)
				DrawKit.shape(r, PackedVector2Array([hb + Vector2(-18, -2), hb + Vector2(6, -50), hb + Vector2(18, -2)]), Color("#5b4bd6"), 3.0, 0.2, INK)
				DrawKit.fill(r, DrawKit.star_pts(hb + Vector2(4, -22), 6, 2.5), Color("#ffd23f"))
			"antenna":
				var ab := Vector2(10, top + 2)
				DrawKit.line(r, ab, ab + Vector2(6, -30), INK, 6.0)
				DrawKit.circle(r, ab + Vector2(6, -34), 6, Color("#ff4f5e"), 2.5)


# ------------------------------------------------------------------ canlı yüz
func _face(r: CanvasItem, base: String) -> void:
	var top := _top_y(base)
	var fy := top * 0.5
	if base == "pizza" or base == "cookie" or base == "pie":
		fy = -22.0
	elif base == "frog_candy":
		fy = -50.0
	elif base == "potion":
		fy = -44.0
	elif base == "skewer":
		fy = -50.0
	var ex := 18.0
	for s in [-1.0, 1.0]:
		var c := Vector2(s * ex, fy - 8)
		if base == "frog_candy":
			c = Vector2(s * 26, -78)
		if _blink > 0.0:
			r.draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), INK, 4.0, true)
			continue
		DrawKit.shape(r, DrawKit.ellipse(c, 10, 12, 20), Color.WHITE, 3.0, 0.0, INK)
		r.draw_circle(c + look * 3.5, 5.0, INK, true, -1.0, true)
		r.draw_circle(c + look * 3.5 + Vector2(1.5, -2), 1.8, Color.WHITE, true, -1.0, true)
	var mc := Vector2(0, fy + 12)
	if base == "frog_candy":
		mc = Vector2(0, -40)
	match face_mood:
		"scared":
			DrawKit.shape(r, DrawKit.ellipse(mc, 7, 9, 14), Color("#6b1f2a"), 3.0, 0.0, INK)
		"angry":
			DrawKit.poly_line(r, DrawKit.quad(mc + Vector2(-10, 4), mc + Vector2(0, -4), mc + Vector2(10, 4)), INK, 4.0)
		_:
			var mp := PackedVector2Array([mc + Vector2(-12, -2), mc + Vector2(12, -2)])
			mp.append_array(DrawKit.quad(mc + Vector2(12, -2), mc + Vector2(0, 14), mc + Vector2(-12, -2), 10))
			DrawKit.shape(r, mp, Color("#6b1f2a"), 3.0, 0.0, INK)
			DrawKit.fill(r, DrawKit.ellipse(mc + Vector2(0, 7), 5, 3, 10), Color("#ff7a8a"))
