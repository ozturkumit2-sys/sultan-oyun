class_name FurnitureArt
extends RefCounted
## Procedural cartoon art for every piece of furniture. All original.

const WOOD := Color("e9cfa6")
const WALNUT := Color("94603d")
const WHITE := Color("fbf8f2")
const METAL := Color("b7c1cc")
const DARK := Color("454a59")
const POT := Color("d9825b")
const LEAF1 := Color("6fb06a")
const LEAF2 := Color("4f9a57")
const LEAF3 := Color("8cc97f")
const PAPER := Color("fffdf7")

const OWNER_ACCENT := {
	"selin": Color("f28fa5"), "deniz": Color("b9a7e0"), "ece": Color("f6c85f"), "mert": Color("9cc5f0"),
	"zeynep": Color("f2a97e"), "burak": Color("8fd3c1"), "ceren": Color("7fb7be"), "ahmet": Color("a97b55"),
}


static func draw(ci: CanvasItem, f: Dictionary, off: Vector2, w, part := "") -> void:
	var c0: Array = f["cells"][0]
	var x: float = c0[0]
	var y: float = c0[1]
	match f["type"]:
		"desk": _desk(ci, f, off, w)
		"reception_desk": _reception(ci, f, off, w)
		"boss_desk": _boss_desk(ci, f, off, w)
		"meeting_table": _meeting_table(ci, off)
		"chair": _chair(ci, off, x + 0.5, y + 0.5, f.get("facing", "SE"), Color(f.get("color", "#b9a7e0")), part, false)
		"office_chair": _chair(ci, off, x + 0.5, y + 0.5, f.get("facing", "SE"), Color(f.get("color", "#9cc5f0")), part, true)
		"stool": _stool(ci, off, x + 0.5, y + 0.5, Color(f.get("color", "#f6c85f")))
		"boss_chair": _boss_chair(ci, off, f["seat"][0], f["seat"][1])
		"sofa": _sofa(ci, off, x, y, Color(f.get("color", "#e98a8a")))
		"armchair": _armchair(ci, off, x + 0.5, y + 0.5, Color(f.get("color", "#7fb7be")), part)
		"plant_tall": _plant(ci, off, x + 0.5, y + 0.5, true)
		"plant_small": _plant(ci, off, x + 0.5, y + 0.5, false)
		"printer": _printer(ci, off, x, y, w)
		"file_cabinet": _cabinet(ci, off, x, y)
		"shelf": _shelf(ci, off, x, y)
		"bookcase": _bookcase(ci, off, x, y)
		"boxes": _boxes(ci, off, x, y)
		"water_cooler": _water_cooler(ci, off, x, y)
		"coffee_table": _coffee_table(ci, off, x, y)
		"fridge": _fridge(ci, off, x, y)
		"coffee_counter": _coffee_counter(ci, off, x, y, w)
		"counter": _counter(ci, off, x, y, f.get("variant", ""))
		"round_table": _round_table(ci, off, x + 0.5, y + 0.5)
		"coat_rack": _coat_rack(ci, off, x + 0.5, y + 0.5)


# ------------------------------------------------------------------ helpers

static func _cyl(ci: CanvasItem, off: Vector2, gx: float, gy: float, r: float, h: float, z: float, col: Color, top := Color(0, 0, 0, 0)) -> void:
	var c := Iso.P(gx, gy, z) + off
	var rx := r * 45.25
	var ry := r * 22.63
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * float(i) / 12.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	for i in 13:
		var a2 := PI - PI * float(i) / 12.0
		pts.append(c + Vector2(cos(a2) * rx, sin(a2) * ry - h))
	Iso.poly(ci, pts, Iso.shade(col, 0.86))
	Iso.ellipse(ci, c + Vector2(0, -h), rx, ry, top if top.a > 0.0 else col.lightened(0.1))


static func _paper(ci: CanvasItem, p: Vector2, ang: float, s := 1.0, col := PAPER) -> void:
	var pts := PackedVector2Array()
	for v in [Vector2(-7, -4.5), Vector2(7, -4.5), Vector2(7, 4.5), Vector2(-7, 4.5)]:
		pts.append(p + (v * s).rotated(ang) * Vector2(1, 0.55))
	Iso.poly(ci, pts, col, Iso.INK_SOFT, 1.0)


static func _leaf(ci: CanvasItem, base: Vector2, tip: Vector2, wdt: float, col: Color) -> void:
	var d := tip - base
	var n := Vector2(-d.y, d.x).normalized() * wdt
	var pts := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		pts.append(base + d * t + n * sin(t * PI))
	for i in range(7, 0, -1):
		var t2 := float(i) / 8.0
		pts.append(base + d * t2 - n * sin(t2 * PI) * 0.75)
	Iso.poly(ci, pts, col, Iso.INK, 1.0)
	Iso.line(ci, base + d * 0.1, base + d * 0.85, Iso.shade(col, 0.75), 1.0)


# ------------------------------------------------------------------ desks

static func _desk(ci: CanvasItem, f: Dictionary, off: Vector2, w) -> void:
	var d0: Array = f["cells"][0]
	var x: float = d0[0]
	var y: float = d0[1]
	var owner: String = f.get("owner", "")
	var acc: Color = OWNER_ACCENT.get(owner, Color("cccccc"))
	var legc := Color("c9bba6")
	# legs
	for p in [[x + 0.08, y + 0.08], [x + 0.84, y + 0.08], [x + 0.84, y + 1.84], [x + 0.08, y + 1.84]]:
		Iso.cbox(ci, off, p[0], p[1], 0.08, 0.08, 27, 0, legc)
	# drawer pedestal under the far half
	Iso.box(ci, off, x + 0.14, y + 1.05, 0.72, 0.78, 26, 0, acc.lightened(0.3), acc.lightened(0.05), Iso.shade(acc, 0.85))
	for k in 3:
		var zz := 6.0 + k * 7.0
		Iso.line(ci, Iso.P(x + 0.86, y + 1.12, zz) + off, Iso.P(x + 0.86, y + 1.76, zz) + off, Iso.INK_SOFT)
		Iso.line(ci, Iso.P(x + 0.86, y + 1.38, zz + 3) + off, Iso.P(x + 0.86, y + 1.5, zz + 3) + off, Iso.INK, 1.6)
	# top
	Iso.box(ci, off, x, y, 1.0, 2.0, 4, 27, WHITE, Color("e9e2d6"), Color("d9cfc0"))
	# keyboard + mouse
	Iso.box(ci, off, x + 0.12, y + 0.28, 0.2, 0.46, 2, 31, Color("eceff3"), Color("cfd4dc"), Color("bcc2cc"))
	Iso.ellipse(ci, Iso.P(x + 0.24, y + 0.88, 32) + off, 3.5, 2.2, Color("dfe3ea"))
	# monitor (we see its back)
	Iso.cbox(ci, off, x + 0.56, y + 0.42, 0.12, 0.18, 9, 31, Color("8a90a0"))
	Iso.box(ci, off, x + 0.5, y + 0.12, 0.08, 0.76, 25, 39, Color("5b6070"), Color("4b5060"), Color("3e4352"))
	Iso.ellipse(ci, Iso.P(x + 0.58, y + 0.5, 52) + off, 2.2, 1.8, Color("9aa2b6"), Color(0, 0, 0, 0))
	if owner == "burak":
		Iso.box(ci, off, x + 0.5, y + 0.95, 0.08, 0.6, 20, 39, Color("5b6070"), Color("4b5060"), Color("3e4352"))
	# per-owner clutter on the far half
	match owner:
		"selin":
			for k in 4:
				Iso.box(ci, off, x + 0.2, y + 1.2, 0.5, 0.36, 1.2, 31 + k * 1.4, PAPER, Color("eee8dc"), Color("e2dbcd"), Iso.INK_SOFT)
			_cyl(ci, off, x + 0.75, y + 1.7, 0.08, 9, 31, Color("8e3b57"))
			for k in 3:
				Iso.line(ci, Iso.P(x + 0.75, y + 1.7, 40) + off, Iso.P(x + 0.75, y + 1.7, 40) + off + Vector2(-2 + k * 2, -7), [Color("e63946"), Color("2b6cb0"), Color("333333")][k], 1.6)
		"deniz":
			_cyl(ci, off, x + 0.6, y + 1.55, 0.09, 6, 31, Color("d4a017"))
			_cyl(ci, off, x + 0.6, y + 1.55, 0.05, 10, 37, Color("f2c94c"))
			Iso.ellipse(ci, Iso.P(x + 0.6, y + 1.55, 52) + off, 6, 4, Color("f2c94c"))
			Iso.box(ci, off, x + 0.15, y + 1.15, 0.35, 0.25, 1.5, 31, PAPER, Color("eee8dc"), Color("e2dbcd"), Iso.INK_SOFT)
		"ece":
			# plush bunny + sticky notes
			var bp := Iso.P(x + 0.55, y + 1.6, 31) + off
			Iso.ellipse(ci, bp + Vector2(0, -5), 6, 5, Color("f7c6d9"))
			Iso.ellipse(ci, bp + Vector2(0, -12), 5, 4.5, Color("f7c6d9"))
			Iso.capsule(ci, bp + Vector2(-2.5, -15), bp + Vector2(-3.5, -22), 1.6, Color("f7c6d9"))
			Iso.capsule(ci, bp + Vector2(2.5, -15), bp + Vector2(3.5, -22), 1.6, Color("f7c6d9"))
			ci.draw_circle(bp + Vector2(-1.8, -12.5), 0.9, Iso.INK)
			ci.draw_circle(bp + Vector2(1.8, -12.5), 0.9, Iso.INK)
			for k in 3:
				Iso.diamond(ci, off, x + 0.15 + k * 0.18, y + 1.15, 0.15, 0.15, 31.3, [Color("fff07a"), Color("ffb3c6"), Color("a8d8ff")][k], Iso.INK_SOFT)
		"mert":
			var ball := Iso.P(x + 0.55, y + 1.55, 31) + off + Vector2(0, -6)
			Iso.ellipse(ci, ball, 6.5, 6.5, Color("f08a3c"))
			Iso.line(ci, ball + Vector2(-6.5, 0), ball + Vector2(6.5, 0), Iso.INK, 1.0)
			Iso.line(ci, ball + Vector2(0, -6.5), ball + Vector2(0, 6.5), Iso.INK, 1.0)
			_cyl(ci, off, x + 0.25, y + 1.2, 0.07, 8, 31, Color("ffffff"))
		"zeynep":
			Iso.box(ci, off, x + 0.15, y + 1.15, 0.3, 0.42, 2.5, 31, Color("e8e8e8"), Color("cfcfcf"), Color("bdbdbd"))
			_cyl(ci, off, x + 0.68, y + 1.62, 0.08, 6, 31, POT)
			Iso.capsule(ci, Iso.P(x + 0.68, y + 1.62, 37) + off, Iso.P(x + 0.68, y + 1.62, 47) + off, 3.2, Color("6aa86a"))
			Iso.capsule(ci, Iso.P(x + 0.68, y + 1.62, 41) + off + Vector2(3, 0), Iso.P(x + 0.68, y + 1.62, 45) + off + Vector2(6, 0), 1.8, Color("6aa86a"))
		"burak":
			_cyl(ci, off, x + 0.28, y + 1.25, 0.06, 11, 31, Color("2a9d8f"))
			for k in 3:
				Iso.box(ci, off, x + 0.5, y + 1.55 - k * 0.04, 0.32, 0.22, 1.2, 31 + k * 1.3, PAPER, Color("eee8dc"), Color("e2dbcd"), Iso.INK_SOFT)
	# desk lamp for some
	if owner in ["selin", "zeynep", "deniz"]:
		var lb := Iso.P(x + 0.82, y + 1.15, 31) + off
		Iso.ellipse(ci, lb, 4, 2, Color("555b6b"))
		Iso.line(ci, lb, lb + Vector2(-2, -16), Color("555b6b"), 2.0)
		Iso.line(ci, lb + Vector2(-2, -16), lb + Vector2(-9, -12), Color("555b6b"), 2.0)
		Iso.poly(ci, PackedVector2Array([lb + Vector2(-14, -10), lb + Vector2(-6, -14), lb + Vector2(-4, -8), lb + Vector2(-11, -5)]), acc)
	# messed up!
	if w != null and w.office.objects["desks"].get(owner, {}).get("messed", false):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(owner)
		for k in 9:
			var gx := x - 0.4 + rng.randf() * 1.7
			var gy := y - 0.1 + rng.randf() * 2.3
			var zz := 31.5 if (gx > x and gx < x + 1 and gy > y and gy < y + 2) else 0.5
			_paper(ci, Iso.P(gx, gy, zz) + off, rng.randf() * TAU, 0.9)


static func _reception(ci: CanvasItem, f: Dictionary, off: Vector2, w) -> void:
	var x := 12.0
	var y := 8.0
	var body := Color("7fb7be")
	Iso.box(ci, off, x + 0.15, y + 0.05, 0.8, 1.9, 30, 0, Color("cfe6e8"), Iso.shade(body, 0.95), Iso.shade(body, 0.82))
	# raised front counter
	Iso.box(ci, off, x + 0.82, y - 0.05, 0.22, 2.1, 42, 0, Color("f6f1e7"), Color("e0d8ca"), Color("d0c6b6"))
	Iso.box(ci, off, x + 0.05, y, 0.95, 2.0, 4, 30, WHITE, Color("e9e2d6"), Color("d9cfc0"))
	# sign on the front
	var tf := Iso.wall_xform("L", 0, 0, Vector2.ZERO)
	var org := Iso.P(x + 1.04, y + 1.85, 34) + off
	ci.draw_set_transform_matrix(Transform2D(tf.x, tf.y, org))
	var font: Font = UiKit.font("slab")
	ci.draw_string(font, Vector2(10, 18), "RECEPTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("2b2d42"))
	ci.draw_set_transform_matrix(Transform2D())
	# monitor + bell + plant
	Iso.cbox(ci, off, x + 0.42, y + 0.42, 0.12, 0.18, 9, 34, Color("8a90a0"))
	Iso.box(ci, off, x + 0.36, y + 0.12, 0.08, 0.76, 25, 42, Color("5b6070"), Color("4b5060"), Color("3e4352"))
	Iso.ellipse(ci, Iso.P(x + 0.92, y + 1.2, 46) + off, 4, 2.5, Color("e0b12a"))
	ci.draw_circle(Iso.P(x + 0.92, y + 1.2, 50) + off, 1.4, Color("e0b12a"))
	_cyl(ci, off, x + 0.45, y + 1.6, 0.07, 6, 34, POT)
	for k in 5:
		_leaf(ci, Iso.P(x + 0.45, y + 1.6, 40) + off, Iso.P(x + 0.45, y + 1.6, 40) + off + Vector2(-9 + k * 4.5, -10 - (k % 2) * 3), 2.4, LEAF1 if k % 2 == 0 else LEAF3)


static func _boss_desk(ci: CanvasItem, f: Dictionary, off: Vector2, w) -> void:
	var x := 11.0
	var y := 2.0
	# heavy walnut desk with modesty panel facing the camera (SW)
	Iso.box(ci, off, x + 0.05, y + 0.1, 1.9, 0.8, 30, 0, Color("a06c45"), Color("8b5a37"), Color("74492b"))
	Iso.box(ci, off, x - 0.05, y + 0.02, 2.1, 0.96, 5, 30, Color("b47a4f"), Color("8b5a37"), Color("74492b"))
	# panel detail on SW face
	for k in 3:
		var xx := x + 0.25 + k * 0.6
		Iso.poly(ci, PackedVector2Array([Iso.P(xx, y + 0.9, 6) + off, Iso.P(xx + 0.45, y + 0.9, 6) + off, Iso.P(xx + 0.45, y + 0.9, 25) + off, Iso.P(xx, y + 0.9, 25) + off]), Color("7d5032"), Iso.INK_SOFT)
	# nameplate
	var np := Iso.P(x + 1.2, y + 0.85, 35) + off
	Iso.poly(ci, PackedVector2Array([np + Vector2(-12, 2), np + Vector2(10, 13), np + Vector2(10, 7), np + Vector2(-12, -4)]), Color("e0b12a"))
	# monitor on the left half
	Iso.cbox(ci, off, x + 0.42, y + 0.35, 0.18, 0.12, 9, 35, Color("8a90a0"))
	Iso.box(ci, off, x + 0.12, y + 0.3, 0.76, 0.08, 25, 43, Color("5b6070"), Color("4b5060"), Color("3e4352"))
	# banker lamp
	var lb := Iso.P(x + 1.82, y + 0.25, 35) + off
	Iso.ellipse(ci, lb, 4.5, 2.4, Color("c9a227"))
	Iso.line(ci, lb, lb + Vector2(0, -12), Color("c9a227"), 2.0)
	Iso.poly(ci, PackedVector2Array([lb + Vector2(-9, -12), lb + Vector2(9, -12), lb + Vector2(6, -18), lb + Vector2(-6, -18)]), Color("2e8b57"))
	# phone
	Iso.box(ci, off, x + 1.55, y + 0.55, 0.22, 0.25, 4, 35, Color("444955"), Color("353a45"), Color("2b2f39"))
	# the promotion file tray (glows when doctored)
	var altered: bool = w != null and w.office.objects["promo"].get("altered", false)
	Iso.box(ci, off, x + 1.05, y + 0.2, 0.42, 0.55, 3, 35, Color("d64545"), Color("b53a3a"), Color("9a3030"))
	Iso.diamond(ci, off, x + 1.1, y + 0.25, 0.32, 0.45, 38.4, PAPER, Iso.INK_SOFT)
	if altered:
		var gp := Iso.P(x + 1.26, y + 0.47, 40) + off
		ci.draw_circle(gp, 12, Color(0.7, 0.4, 1.0, 0.18))
		ci.draw_circle(gp, 7, Color(0.8, 0.5, 1.0, 0.22))


static func _meeting_table(ci: CanvasItem, off: Vector2) -> void:
	var x := 1.12
	var y := 1.12
	var wdt := 1.76
	var dep := 2.76
	Iso.cbox(ci, off, x + 0.75, y + 0.6, 0.26, 0.26, 24, 0, Color("b9976e"))
	Iso.cbox(ci, off, x + 0.75, y + 1.9, 0.26, 0.26, 24, 0, Color("b9976e"))
	Iso.box(ci, off, x, y, wdt, dep, 5, 24, Color("efd6ae"), Color("d8b88d"), Color("c6a47a"))
	# laptops, papers, glasses, centre plant
	for p in [[1.35, 1.45], [1.35, 2.6], [2.35, 1.6], [2.35, 2.9]]:
		Iso.box(ci, off, p[0], p[1], 0.32, 0.42, 1.5, 29, Color("d7dbe3"), Color("b8bec9"), Color("a7aebb"))
	for p in [[1.7, 3.3], [2.2, 2.2], [1.5, 2.0]]:
		_paper(ci, Iso.P(p[0], p[1], 29.5) + off, 0.3, 0.9)
	for p in [[1.85, 1.35], [2.5, 3.5]]:
		_cyl(ci, off, p[0], p[1], 0.05, 7, 29, Color(0.75, 0.9, 1.0, 0.85))
	_cyl(ci, off, 2.0, 2.5, 0.1, 7, 29, Color("f2f2f2"))
	for k in 6:
		var b := Iso.P(2.0, 2.5, 36) + off
		_leaf(ci, b, b + Vector2(-11 + k * 4.4, -9 - (k % 3) * 3), 2.6, [LEAF1, LEAF2, LEAF3][k % 3])


# ------------------------------------------------------------------ seating

## Chair. part "" = whole chair, "seat" = everything except a backrest in front, "back" = only that backrest.
static func _chair(ci: CanvasItem, off: Vector2, cx: float, cy: float, facing: String, col: Color, part: String, office: bool) -> void:
	var back_in_front := facing in ["NW", "NE"]
	var dx := 0.0
	var dy := 0.0
	match facing:
		"SE": dx = -1.0
		"NW": dx = 1.0
		"SW": dy = -1.0
		"NE": dy = 1.0
	var s := 0.26
	if part != "back":
		if office:
			# star base + gas lift
			var b := Iso.P(cx, cy, 2) + off
			for k in 5:
				var a := TAU * k / 5.0 + 0.3
				Iso.line(ci, b, b + Vector2(cos(a) * 13, sin(a) * 6.5), Color("3d4250"), 2.4)
				ci.draw_circle(b + Vector2(cos(a) * 13, sin(a) * 6.5), 1.8, Color("2b2f39"))
			Iso.line(ci, b, Iso.P(cx, cy, 14) + off, Color("6b7080"), 3.0)
		else:
			for p in [[-s, -s], [s, -s], [s, s], [-s, s]]:
				Iso.line(ci, Iso.P(cx + p[0] * 0.85, cy + p[1] * 0.85, 0) + off, Iso.P(cx + p[0] * 0.85, cy + p[1] * 0.85, 14) + off, Iso.shade(col, 0.55), 2.0)
		Iso.box(ci, off, cx - s, cy - s, s * 2, s * 2, 5, 14, col.lightened(0.15), Iso.shade(col, 0.88), Iso.shade(col, 0.76))
	if part == "seat" and back_in_front:
		return
	if part == "back" and not back_in_front:
		return
	# backrest slab on the side opposite to facing
	var bh := 26.0 if office else 20.0
	if dx != 0.0:
		var bx := cx + dx * s - (0.07 if dx > 0 else 0.0)
		Iso.box(ci, off, bx, cy - s, 0.07, s * 2, bh, 18, col.lightened(0.1), Iso.shade(col, 0.85), Iso.shade(col, 0.72))
	else:
		var by := cy + dy * s - (0.07 if dy > 0 else 0.0)
		Iso.box(ci, off, cx - s, by, s * 2, 0.07, bh, 18, col.lightened(0.1), Iso.shade(col, 0.85), Iso.shade(col, 0.72))


static func _stool(ci: CanvasItem, off: Vector2, cx: float, cy: float, col: Color) -> void:
	for p in [[-0.15, -0.15], [0.15, -0.15], [0.15, 0.15], [-0.15, 0.15]]:
		Iso.line(ci, Iso.P(cx + p[0], cy + p[1], 0) + off, Iso.P(cx + p[0] * 0.7, cy + p[1] * 0.7, 16) + off, Color("8a7a66"), 2.0)
	_cyl(ci, off, cx, cy, 0.24, 4, 16, col)


static func _boss_chair(ci: CanvasItem, off: Vector2, cx: float, cy: float) -> void:
	var col := Color("5b3a2e")
	var b := Iso.P(cx, cy, 2) + off
	for k in 5:
		var a := TAU * k / 5.0 + 0.3
		Iso.line(ci, b, b + Vector2(cos(a) * 15, sin(a) * 7.5), Color("2b2f39"), 2.6)
	Iso.line(ci, b, Iso.P(cx, cy, 15) + off, Color("6b7080"), 3.2)
	Iso.box(ci, off, cx - 0.3, cy - 0.3, 0.6, 0.6, 6, 15, col.lightened(0.15), Iso.shade(col, 0.9), Iso.shade(col, 0.78))
	# tall backrest behind (on -y side since facing SW)
	Iso.box(ci, off, cx - 0.32, cy - 0.36, 0.64, 0.1, 38, 19, col.lightened(0.12), Iso.shade(col, 0.88), Iso.shade(col, 0.74))
	for k in 3:
		ci.draw_circle(Iso.P(cx - 0.18 + k * 0.18, cy - 0.26, 45) + off, 1.3, Color("c9a227"))


static func _sofa(ci: CanvasItem, off: Vector2, x: float, y: float, col: Color) -> void:
	# two seats along y, facing SE (+x); backrest on -x side
	Iso.box(ci, off, x + 0.12, y + 0.08, 0.8, 1.84, 14, 0, col.lightened(0.12), Iso.shade(col, 0.88), Iso.shade(col, 0.76))
	Iso.box(ci, off, x + 0.05, y + 0.05, 0.25, 1.9, 34, 0, col.lightened(0.18), Iso.shade(col, 0.86), Iso.shade(col, 0.72))
	for k in 2:
		Iso.box(ci, off, x + 0.32, y + 0.12 + k * 0.92, 0.58, 0.84, 5, 14, col.lightened(0.25), Iso.shade(col, 0.95), Iso.shade(col, 0.82))
	# arms
	Iso.box(ci, off, x + 0.12, y + 0.02, 0.82, 0.14, 22, 0, col.lightened(0.1), Iso.shade(col, 0.84), Iso.shade(col, 0.72))
	Iso.box(ci, off, x + 0.12, y + 1.84, 0.82, 0.14, 22, 0, col.lightened(0.1), Iso.shade(col, 0.84), Iso.shade(col, 0.72))
	# cushion
	var cp := Iso.P(x + 0.32, y + 0.5, 26) + off
	Iso.rrect(ci, Rect2(cp + Vector2(-8, -8), Vector2(14, 12)), 4, Color("fff07a"))


static func _armchair(ci: CanvasItem, off: Vector2, cx: float, cy: float, col: Color, part: String) -> void:
	# facing NW: backrest on +x side (toward camera)
	if part != "back":
		Iso.box(ci, off, cx - 0.36, cy - 0.38, 0.72, 0.76, 15, 0, col.lightened(0.15), Iso.shade(col, 0.88), Iso.shade(col, 0.76))
		Iso.box(ci, off, cx - 0.36, cy - 0.42, 0.6, 0.1, 22, 0, col.lightened(0.1), Iso.shade(col, 0.85), Iso.shade(col, 0.72))
		Iso.box(ci, off, cx - 0.36, cy + 0.32, 0.6, 0.1, 22, 0, col.lightened(0.1), Iso.shade(col, 0.85), Iso.shade(col, 0.72))
	if part != "seat":
		Iso.box(ci, off, cx + 0.22, cy - 0.42, 0.16, 0.84, 34, 0, col.lightened(0.18), Iso.shade(col, 0.86), Iso.shade(col, 0.72))


# ------------------------------------------------------------------ plants & misc

static func _plant(ci: CanvasItem, off: Vector2, cx: float, cy: float, tall: bool) -> void:
	var r := 0.22 if tall else 0.17
	var h := 20.0 if tall else 14.0
	_cyl(ci, off, cx, cy, r, h, 0, POT, Color("8a5a3c"))
	Iso.ellipse(ci, Iso.P(cx, cy, h) + off, r * 45.25 * 0.85, r * 22.63 * 0.85, Color("6b4630"), Color(0, 0, 0, 0))
	var base := Iso.P(cx, cy, h) + off
	if tall:
		Iso.line(ci, base, base + Vector2(-3, -34), Color("5a7a3a"), 2.2)
		Iso.line(ci, base, base + Vector2(5, -40), Color("5a7a3a"), 2.2)
		var tips := [Vector2(-24, -30), Vector2(-16, -52), Vector2(2, -64), Vector2(18, -52), Vector2(24, -32), Vector2(-6, -40), Vector2(10, -36), Vector2(-18, -18), Vector2(16, -16)]
		for k in tips.size():
			var st: Vector2 = base + Vector2(0, -14 - (k % 3) * 6)
			_leaf(ci, st, base + tips[k], 6.5, [LEAF1, LEAF2, LEAF3][k % 3])
	else:
		var tips2 := [Vector2(-14, -12), Vector2(-6, -22), Vector2(6, -24), Vector2(14, -12), Vector2(0, -16)]
		for k in tips2.size():
			_leaf(ci, base + Vector2(0, -2), base + tips2[k], 4.5, [LEAF1, LEAF2, LEAF3][k % 3])


static func _printer(ci: CanvasItem, off: Vector2, x: float, y: float, w) -> void:
	var broken: bool = w != null and w.office.objects["printer"]["broken"]
	Iso.box(ci, off, x + 0.08, y + 0.1, 0.84, 0.8, 34, 0, Color("e6e8ee"), Color("d2d5de"), Color("bfc3ce"))
	for k in 2:
		Iso.line(ci, Iso.P(x + 0.12, y + 0.9, 10 + k * 11) + off, Iso.P(x + 0.88, y + 0.9, 10 + k * 11) + off, Iso.INK_SOFT)
	Iso.box(ci, off, x + 0.06, y + 0.06, 0.88, 0.86, 16, 34, Color("f0f1f5"), Color("dcdfe7"), Color("c8ccd7"))
	Iso.box(ci, off, x + 0.1, y + 0.12, 0.6, 0.72, 4, 50, Color("9aa0b0"), Color("858b9c"), Color("767c8d"))
	# control panel
	Iso.box(ci, off, x + 0.72, y + 0.55, 0.18, 0.32, 3, 50, Color("4c5566"), Color("3e4656"), Color("343b49"))
	var led := Iso.P(x + 0.81, y + 0.62, 53.5) + off
	ci.draw_circle(led, 2.2, Color("ff3b30") if broken else Color("34c759"))
	# output tray with paper
	Iso.box(ci, off, x + 0.92, y + 0.25, 0.2, 0.5, 2, 38, Color("e6e8ee"), Color("d2d5de"), Color("bfc3ce"))
	Iso.diamond(ci, off, x + 0.93, y + 0.3, 0.16, 0.38, 40.2, PAPER, Iso.INK_SOFT)
	if broken:
		# crumpled jammed paper sticking out
		var jp := Iso.P(x + 0.5, y + 0.92, 30) + off
		Iso.poly(ci, PackedVector2Array([jp + Vector2(-9, 0), jp + Vector2(-4, -6), jp + Vector2(2, -2), jp + Vector2(8, -8), jp + Vector2(10, 2), jp + Vector2(2, 6), jp + Vector2(-6, 5)]), PAPER)
		Iso.line(ci, jp + Vector2(-4, -6), jp + Vector2(0, 3), Iso.INK_SOFT)


static func _cabinet(ci: CanvasItem, off: Vector2, x: float, y: float) -> void:
	Iso.box(ci, off, x + 0.1, y + 0.1, 0.8, 0.78, 54, 0, Color("c7d0da"), Color("b2bdc9"), Color("9eaab8"))
	for k in 4:
		var z0 := 4.0 + k * 12.5
		var a := Iso.P(x + 0.16, y + 0.88, z0) + off
		var b := Iso.P(x + 0.84, y + 0.88, z0) + off
		Iso.poly(ci, PackedVector2Array([a, b, b + Vector2(0, -10.5), a + Vector2(0, -10.5)]), Color("bac4cf"), Iso.INK_SOFT)
		var hp := Iso.P(x + 0.5, y + 0.88, z0 + 6) + off
		Iso.line(ci, hp + Vector2(-5, -2.5), hp + Vector2(5, 2.5), Color("6b7584"), 2.2)
		Iso.diamond(ci, off, x + 0.4, y + 0.885, 0.2, 0.0, z0 + 8.5, Color("ffffff"))


static func _shelf(ci: CanvasItem, off: Vector2, x: float, y: float) -> void:
	var fr := Color("8e99a6")
	# back + sides
	Iso.box(ci, off, x + 0.1, y + 0.08, 0.8, 0.12, 74, 0, Color("c5ccd5"), Color("b2bac5"), Color("9fa8b4"))
	var colors := [Color("e63946"), Color("2b6cb0"), Color("f4a261"), Color("2a9d8f"), Color("8e3b57"), Color("e9c46a"), Color("457b9d")]
	for s in 3:
		var z := 2.0 + s * 24.0
		Iso.box(ci, off, x + 0.1, y + 0.08, 0.8, 0.78, 2, z, Color("d8dee6"), fr, Iso.shade(fr, 0.85))
		for k in 6:
			var bx := x + 0.16 + k * 0.12
			var hh := 15.0 + float((k * 7 + s * 3) % 5)
			Iso.box(ci, off, bx, y + 0.3, 0.1, 0.5, hh, z + 2, colors[(k + s * 2) % colors.size()].lightened(0.15), colors[(k + s * 2) % colors.size()], Iso.shade(colors[(k + s * 2) % colors.size()], 0.8), Iso.INK_SOFT)
	Iso.box(ci, off, x + 0.1, y + 0.08, 0.8, 0.78, 2, 72, Color("d8dee6"), fr, Iso.shade(fr, 0.85))
	for p in [[x + 0.1, y + 0.82], [x + 0.86, y + 0.82]]:
		Iso.box(ci, off, p[0], p[1], 0.05, 0.05, 74, 0, fr, fr, Iso.shade(fr, 0.85))


static func _bookcase(ci: CanvasItem, off: Vector2, x: float, y: float) -> void:
	var wd := Color("a97b55")
	Iso.box(ci, off, x + 0.05, y + 0.05, 1.9, 0.14, 80, 0, wd.lightened(0.1), Iso.shade(wd, 0.9), Iso.shade(wd, 0.8))
	var colors := [Color("2b6cb0"), Color("c0392b"), Color("27ae60"), Color("f39c12"), Color("8e44ad"), Color("16a085"), Color("d35400")]
	for s in 4:
		var z := 2.0 + s * 20.0
		Iso.box(ci, off, x + 0.05, y + 0.05, 1.9, 0.62, 2, z, wd.lightened(0.15), wd, Iso.shade(wd, 0.85))
		if s < 3:
			for k in 12:
				var bx := x + 0.12 + k * 0.145
				var hh := 12.0 + float((k * 5 + s * 3) % 5)
				if (k + s) % 7 == 3:
					continue
				var cc: Color = colors[(k * 3 + s) % colors.size()]
				Iso.box(ci, off, bx, y + 0.22, 0.12, 0.42, hh, z + 2, cc.lightened(0.15), cc, Iso.shade(cc, 0.8), Iso.INK_SOFT)
	Iso.box(ci, off, x + 0.05, y + 0.05, 1.9, 0.62, 2, 78, wd.lightened(0.15), wd, Iso.shade(wd, 0.85))
	# trophy on top
	_cyl(ci, off, x + 1.5, y + 0.35, 0.08, 6, 80, Color("d4a017"))
	Iso.ellipse(ci, Iso.P(x + 1.5, y + 0.35, 92) + off, 5.5, 4, Color("f2c94c"))


static func _boxes(ci: CanvasItem, off: Vector2, x: float, y: float) -> void:
	var c := Color("d9b37e")
	Iso.box(ci, off, x + 0.12, y + 0.12, 0.76, 0.76, 18, 0, c.lightened(0.1), Iso.shade(c, 0.9), Iso.shade(c, 0.8))
	Iso.box(ci, off, x + 0.22, y + 0.18, 0.56, 0.6, 15, 18, c.lightened(0.15), Iso.shade(c, 0.92), Iso.shade(c, 0.82))
	Iso.line(ci, Iso.P(x + 0.5, y + 0.18, 33) + off, Iso.P(x + 0.5, y + 0.78, 33) + off, Color("c99a5b"), 3.0)
	Iso.box(ci, off, x + 0.3, y + 0.28, 0.4, 0.4, 10, 33, Color("f2f2f2"), Color("dddddd"), Color("cccccc"))


static func _water_cooler(ci: CanvasItem, off: Vector2, x: float, y: float) -> void:
	Iso.box(ci, off, x + 0.25, y + 0.25, 0.5, 0.5, 34, 0, Color("f4f6f8"), Color("dfe3e8"), Color("cdd2d9"))
	# taps
	ci.draw_circle(Iso.P(x + 0.75, y + 0.42, 24) + off, 2.2, Color("e63946"))
	ci.draw_circle(Iso.P(x + 0.75, y + 0.58, 24) + off, 2.2, Color("2b6cb0"))
	_cyl(ci, off, x + 0.5, y + 0.5, 0.2, 26, 34, Color(0.62, 0.84, 0.97, 0.85), Color(0.75, 0.9, 1.0, 0.9))
	_cyl(ci, off, x + 0.5, y + 0.5, 0.06, 4, 60, Color("2b6cb0"))
	# cup stack
	_cyl(ci, off, x + 0.82, y + 0.85, 0.05, 10, 0, Color("ffffff"))


static func _coffee_table(ci: CanvasItem, off: Vector2, x: float, y: float) -> void:
	var c := Color("caa27a")
	Iso.box(ci, off, x + 0.2, y + 0.15, 0.6, 1.7, 3, 12, c.lightened(0.15), Iso.shade(c, 0.9), Iso.shade(c, 0.8))
	for p in [[x + 0.24, y + 0.2], [x + 0.72, y + 0.2], [x + 0.72, y + 1.78], [x + 0.24, y + 1.78]]:
		Iso.cbox(ci, off, p[0], p[1], 0.05, 0.05, 12, 0, Iso.shade(c, 0.7))
	Iso.box(ci, off, x + 0.3, y + 0.4, 0.35, 0.5, 1.5, 15, Color("ffb3c6"), Color("e899ad"), Color("d98ba0"), Iso.INK_SOFT)
	Iso.box(ci, off, x + 0.35, y + 1.1, 0.35, 0.5, 1.5, 15, Color("a8d8ff"), Color("90c4ea"), Color("80b4da"), Iso.INK_SOFT)


static func _fridge(ci: CanvasItem, off: Vector2, x: float, y: float) -> void:
	Iso.box(ci, off, x + 0.1, y + 0.08, 0.82, 0.84, 82, 0, Color("fbfbfb"), Color("eaeaea"), Color("d8d8d8"))
	# door split + handles on the SE face
	Iso.line(ci, Iso.P(x + 0.92, y + 0.08, 52) + off, Iso.P(x + 0.92, y + 0.92, 52) + off, Iso.INK_SOFT)
	Iso.line(ci, Iso.P(x + 0.925, y + 0.75, 56) + off, Iso.P(x + 0.925, y + 0.75, 70) + off, Color("9aa0aa"), 2.5)
	Iso.line(ci, Iso.P(x + 0.925, y + 0.75, 30) + off, Iso.P(x + 0.925, y + 0.75, 46) + off, Color("9aa0aa"), 2.5)
	# magnets + a doodle
	for m in [[0.3, 64, Color("e63946")], [0.5, 40, Color("f4a261")], [0.2, 36, Color("2a9d8f")]]:
		ci.draw_circle(Iso.P(x + 0.93, y + m[0], m[1]) + off, 2.2, m[2])
	var dp := Iso.P(x + 0.93, y + 0.45, 72) + off
	Iso.poly(ci, PackedVector2Array([dp, dp + Vector2(12, -6), dp + Vector2(12, 6), dp + Vector2(0, 12)]), PAPER, Iso.INK_SOFT)
	ci.draw_circle(dp + Vector2(6, 2), 2.6, Color("f6c85f"))


static func _counter_base(ci: CanvasItem, off: Vector2, x: float, y: float) -> void:
	var cab := Color("a9d6c0")
	Iso.box(ci, off, x + 0.05, y + 0.04, 0.84, 0.92, 30, 0, cab.lightened(0.1), Iso.shade(cab, 0.92), Iso.shade(cab, 0.8))
	Iso.line(ci, Iso.P(x + 0.89, y + 0.5, 3) + off, Iso.P(x + 0.89, y + 0.5, 27) + off, Iso.INK_SOFT)
	Iso.line(ci, Iso.P(x + 0.895, y + 0.4, 22) + off, Iso.P(x + 0.895, y + 0.4, 15) + off, Color("6b7584"), 2.0)
	Iso.line(ci, Iso.P(x + 0.895, y + 0.6, 22) + off, Iso.P(x + 0.895, y + 0.6, 15) + off, Color("6b7584"), 2.0)
	Iso.box(ci, off, x, y, 0.95, 1.0, 4, 30, Color("f3ede2"), Color("e1d8c9"), Color("d2c7b6"))


static func _coffee_counter(ci: CanvasItem, off: Vector2, x: float, y: float, w) -> void:
	_counter_base(ci, off, x, y)
	var broken: bool = w != null and w.office.objects["coffee"]["broken"]
	var body := Color("d9534f")
	Iso.box(ci, off, x + 0.15, y + 0.18, 0.55, 0.64, 26, 34, body.lightened(0.1), Iso.shade(body, 0.9), Iso.shade(body, 0.78))
	Iso.box(ci, off, x + 0.12, y + 0.15, 0.62, 0.7, 5, 60, Color("4a4e5c"), Color("3b3f4b"), Color("31353f"))
	# group head & cup
	Iso.box(ci, off, x + 0.7, y + 0.38, 0.12, 0.24, 6, 46, Color("c0c4cc"), Color("a8adb7"), Color("959aa5"))
	_cyl(ci, off, x + 0.8, y + 0.5, 0.06, 6, 34, Color("ffffff"))
	# dial
	ci.draw_circle(Iso.P(x + 0.71, y + 0.7, 52) + off, 3.0, Color("f2f2f2"))
	ci.draw_circle(Iso.P(x + 0.71, y + 0.7, 52) + off, 1.2, Color("ff3b30") if broken else Color("34c759"))
	if broken:
		var sp := Iso.P(x + 0.72, y + 0.25, 50) + off
		Iso.poly(ci, PackedVector2Array([sp + Vector2(-9, -9), sp + Vector2(9, -1), sp + Vector2(9, 11), sp + Vector2(-9, 3)]), Color("fff07a"))
		ci.draw_set_transform(sp + Vector2(-7, 1), 0.42, Vector2(1, 1))
		ci.draw_string(UiKit.font("marker"), Vector2(0, 0), "OUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("e63946"))
		ci.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# mugs on the counter
	_cyl(ci, off, x + 0.2, y + 0.9, 0.05, 6, 34, Color("9cc5f0"))


static func _counter(ci: CanvasItem, off: Vector2, x: float, y: float, variant: String) -> void:
	_counter_base(ci, off, x, y)
	match variant:
		"sink":
			Iso.diamond(ci, off, x + 0.2, y + 0.2, 0.55, 0.6, 34.2, Color("cfd6df"), Iso.INK_SOFT)
			Iso.diamond(ci, off, x + 0.26, y + 0.26, 0.43, 0.48, 34.4, Color("aeb8c4"))
			Iso.line(ci, Iso.P(x + 0.15, y + 0.5, 34) + off, Iso.P(x + 0.15, y + 0.5, 46) + off, Color("9aa0aa"), 2.5)
			Iso.line(ci, Iso.P(x + 0.15, y + 0.5, 46) + off, Iso.P(x + 0.35, y + 0.5, 44) + off, Color("9aa0aa"), 2.5)
		"microwave":
			Iso.box(ci, off, x + 0.15, y + 0.12, 0.6, 0.78, 18, 34, Color("f4f4f4"), Color("dedede"), Color("cccccc"))
			Iso.poly(ci, PackedVector2Array([Iso.P(x + 0.76, y + 0.2, 38) + off, Iso.P(x + 0.76, y + 0.62, 38) + off, Iso.P(x + 0.76, y + 0.62, 49) + off, Iso.P(x + 0.76, y + 0.2, 49) + off]), Color("3b3f4b"))
		"fruit":
			_cyl(ci, off, x + 0.45, y + 0.5, 0.17, 5, 34, Color("e9c46a"))
			for k in 4:
				ci.draw_circle(Iso.P(x + 0.38 + (k % 2) * 0.14, y + 0.45 + (k / 2) * 0.1, 42) + off, 3.6, [Color("e63946"), Color("f4a261"), Color("8ac926"), Color("ffca3a")][k])
			_cyl(ci, off, x + 0.8, y + 0.2, 0.09, 12, 34, Color("c0c4cc"))


static func _round_table(ci: CanvasItem, off: Vector2, cx: float, cy: float) -> void:
	_cyl(ci, off, cx, cy, 0.06, 22, 0, Color("8a7a66"))
	_cyl(ci, off, cx, cy, 0.4, 3, 22, Color("f1e3c8"))
	_cyl(ci, off, cx - 0.1, cy, 0.06, 6, 25, Color("ffffff"))
	_cyl(ci, off, cx + 0.12, cy + 0.08, 0.06, 6, 25, Color("f6c85f"))


static func _coat_rack(ci: CanvasItem, off: Vector2, cx: float, cy: float) -> void:
	var b := Iso.P(cx, cy, 0) + off
	Iso.ellipse(ci, b, 9, 4.5, Color("6b4630"))
	Iso.line(ci, b, b + Vector2(0, -72), Color("6b4630"), 3.4)
	for k in 4:
		var a := TAU * k / 4.0
		Iso.line(ci, b + Vector2(0, -66), b + Vector2(cos(a) * 8, -66 + sin(a) * 4), Color("6b4630"), 2.0)
	Iso.capsule(ci, b + Vector2(-6, -62), b + Vector2(-9, -36), 6, Color("c0392b"))
	Iso.capsule(ci, b + Vector2(6, -62), b + Vector2(8, -40), 5, Color("34495e"))
	Iso.ellipse(ci, b + Vector2(1, -74), 8, 4, Color("e9c46a"))
