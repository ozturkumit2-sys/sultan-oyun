class_name IngredientIcon
extends Control
## Malzeme ve füzyon ikonları. Malzemeler el yapımı prosedürel çizimlerle,
## füzyonlar ise küçük bir DishView olarak gösterilir. Tasarım alanı 100x100 (merkez 0,0).

const INK := Color("#3b2417")
const W := 3.2

var item_id := ""
var dim := false
var _dish: DishView = null
var _t := 0.0
var animate := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_item(id: String) -> void:
	item_id = id
	if _dish:
		_dish.queue_free()
		_dish = null
	if id != "" and not IngredientDatabase.ingredients.has(id) and FusionEngine.exists(id):
		_dish = DishView.new()
		_dish.show_shadow = false
		_dish.setup(FusionEngine.item(id))
		add_child(_dish)
	_layout_dish()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_dish()


func _layout_dish() -> void:
	if _dish:
		var s := minf(size.x, size.y) / 100.0
		_dish.scale = Vector2(s, s) * 0.62
		_dish.position = size * 0.5 + Vector2(0, 30 * s)
		_dish.modulate = Color(1, 1, 1, 0.35) if dim else Color.WHITE


func _process(delta: float) -> void:
	if animate:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if item_id == "" or _dish != null:
		return
	var s := minf(size.x, size.y) / 100.0
	draw_set_transform(size * 0.5, 0.0, Vector2(s, s))
	var ing: Dictionary = IngredientDatabase.ingredients.get(item_id, {})
	var c1 := Color(ing.get("color", "#cccccc"))
	var c2 := Color(ing.get("color2", "#999999"))
	DrawKit.shadow(self, Vector2(0, 40), 34, 8, 0.25)
	_paint(item_id, c1, c2)
	if dim:
		DrawKit.fill(self, DrawKit.rrect(Rect2(-50, -50, 100, 100), 20), Color(1, 0.97, 0.92, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------------ ortak şekiller
func _jar(liquid: Color, lid: Color, fill_h := 0.65) -> PackedVector2Array:
	var body := DrawKit.rrect(Rect2(-28, -26, 56, 66), 14)
	DrawKit.fill(self, body, Color(0.9, 0.96, 1.0, 0.6))
	var top_y := 40.0 - 66.0 * fill_h
	var liq := Geometry2D.intersect_polygons(PackedVector2Array([Vector2(-40, top_y), Vector2(40, top_y), Vector2(40, 50), Vector2(-40, 50)]), body)
	for p in liq:
		DrawKit.fill(self, p, liquid, 0.15)
	DrawKit.outline(self, body, INK, W)
	DrawKit.shape(self, DrawKit.rrect(Rect2(-31, -40, 62, 16), 6), lid, W, 0.2, INK)
	DrawKit.shine(self, Vector2(-17, -4), 4, 14, 0.55, 0.0)
	return body


func _bottle(liquid: Color, cork := Color("#a8743c")) -> PackedVector2Array:
	var body := DrawKit.smooth(PackedVector2Array([Vector2(-10, -24), Vector2(-32, 2), Vector2(-32, 38), Vector2(32, 38), Vector2(32, 2), Vector2(10, -24)]), 2)
	DrawKit.fill(self, body, Color(0.9, 0.96, 1.0, 0.55))
	var liq := Geometry2D.intersect_polygons(PackedVector2Array([Vector2(-40, 0), Vector2(40, 0), Vector2(40, 50), Vector2(-40, 50)]), body)
	for p in liq:
		DrawKit.fill(self, p, liquid, 0.15)
	DrawKit.outline(self, body, INK, W)
	DrawKit.shape(self, DrawKit.rrect(Rect2(-11, -40, 22, 20), 5), Color(0.9, 0.96, 1.0, 0.7), W, 0.0, INK)
	DrawKit.shape(self, DrawKit.rrect(Rect2(-9, -48, 18, 14), 4), cork, W, 0.15, INK)
	DrawKit.shine(self, Vector2(-18, 10), 4, 10, 0.6, 0.2)
	return body


func _sack(col: Color, mark: Color) -> void:
	var body := DrawKit.smooth(PackedVector2Array([Vector2(-20, -30), Vector2(-34, -6), Vector2(-36, 30), Vector2(-24, 42), Vector2(24, 42), Vector2(36, 30), Vector2(34, -6), Vector2(20, -30)]), 2)
	DrawKit.shape(self, body, col, W, 0.15, INK)
	DrawKit.shape(self, DrawKit.smooth(PackedVector2Array([Vector2(-22, -30), Vector2(-14, -44), Vector2(0, -38), Vector2(14, -44), Vector2(22, -30)]), 1), col.lightened(0.1), W, 0.1, INK)
	draw_line(Vector2(-20, -28), Vector2(20, -28), INK, 4.0, true)
	for k in 3:
		var y := 4.0 + k * 9.0
		DrawKit.fill(self, DrawKit.ellipse(Vector2(-6, y), 6, 3, 10, -0.6), mark)
		DrawKit.fill(self, DrawKit.ellipse(Vector2(6, y), 6, 3, 10, 0.6), mark)
	draw_line(Vector2(0, 0), Vector2(0, 32), mark, 2.5, true)


# ------------------------------------------------------------------ ikonlar
func _paint(id: String, c1: Color, c2: Color) -> void:
	match id:
		"sugar":
			for p in [Vector2(-16, 14), Vector2(16, 14), Vector2(0, -14)]:
				var cube := PackedVector2Array([p + Vector2(-16, -10), p + Vector2(0, -18), p + Vector2(16, -10), p + Vector2(16, 12), p + Vector2(0, 20), p + Vector2(-16, 12)])
				DrawKit.shape(self, cube, Color("#fffafc"), W, 0.12, INK)
				draw_line(p + Vector2(-16, -10), p + Vector2(0, -2), Color("#e3d6e0"), 2.0, true)
				draw_line(p + Vector2(16, -10), p + Vector2(0, -2), Color("#e3d6e0"), 2.0, true)
				draw_line(p + Vector2(0, -2), p + Vector2(0, 20), Color("#e3d6e0"), 2.0, true)
			DrawKit.fill(self, DrawKit.star_pts(Vector2(26, -26), 8, 2.5, 4), c2)
		"chocolate":
			var bar := DrawKit.rrect(Rect2(-30, -38, 60, 76), 6)
			DrawKit.shape(self, bar, c1, W, 0.2, INK)
			for i in 2:
				for j in 3:
					DrawKit.shape(self, DrawKit.rrect(Rect2(-24 + i * 26, -32 + j * 22, 22, 18), 4), c1.lightened(0.08), 2.0, 0.2, c1.darkened(0.35))
			var wrap := PackedVector2Array([Vector2(-32, 8), Vector2(32, -2), Vector2(32, 40), Vector2(-32, 40)])
			DrawKit.shape(self, wrap, Color("#e0444f"), W, 0.15, INK)
			draw_line(Vector2(-32, 18), Vector2(32, 8), Color("#ffd23f"), 4.0, true)
		"strawberry":
			var b := DrawKit.smooth(PackedVector2Array([Vector2(-32, -14), Vector2(0, -24), Vector2(32, -14), Vector2(24, 18), Vector2(0, 42), Vector2(-24, 18)]), 2)
			DrawKit.shape(self, b, c1, W, 0.2, INK)
			for p in [Vector2(-14, -4), Vector2(8, -6), Vector2(-4, 10), Vector2(16, 10), Vector2(-16, 18), Vector2(4, 26), Vector2(20, -2)]:
				DrawKit.fill(self, DrawKit.ellipse(p, 2.2, 3.2, 8), Color("#ffe58a"))
			for k in 5:
				var a := PI + PI * k / 4.0
				DrawKit.shape(self, DrawKit.ellipse(Vector2(cos(a) * 14, -24 + sin(a) * 4), 10, 5, 12, a), c2, 2.5, 0.1, INK)
			draw_line(Vector2(0, -26), Vector2(4, -40), Color("#3f8f2f"), 4.0, true)
			DrawKit.shine(self, Vector2(-16, -10), 6, 3, 0.5, -0.5)
		"lemon":
			var l := DrawKit.smooth(PackedVector2Array([Vector2(-42, 4), Vector2(-28, -22), Vector2(0, -30), Vector2(28, -22), Vector2(42, 4), Vector2(28, 26), Vector2(0, 32), Vector2(-28, 26)]), 2)
			DrawKit.shape(self, l, c1, W, 0.2, INK)
			DrawKit.shape(self, DrawKit.ellipse(Vector2(10, -34), 14, 7, 14, -0.4), c2, 2.5, 0.15, INK)
			DrawKit.shine(self, Vector2(-14, -12), 10, 5, 0.5, -0.3)
		"tomato":
			DrawKit.circle(self, Vector2(0, 6), 36, c1, W, 0.2)
			for k in 5:
				var a2 := TAU * k / 5.0 - PI / 2
				DrawKit.shape(self, DrawKit.ellipse(Vector2(cos(a2) * 10, -26 + sin(a2) * 4), 10, 4, 10, a2), c2, 2.0, 0.1, INK)
			DrawKit.shine(self, Vector2(-14, -6), 8, 5, 0.5, -0.5)
		"chili":
			var ch := DrawKit.smooth(PackedVector2Array([Vector2(-24, -26), Vector2(-6, -30), Vector2(10, -10), Vector2(26, 22), Vector2(30, 40), Vector2(14, 26), Vector2(-14, -2), Vector2(-28, -14)]), 2)
			DrawKit.shape(self, ch, c1, W, 0.2, INK)
			DrawKit.shape(self, DrawKit.ellipse(Vector2(-24, -28), 10, 7, 12, -0.6), c2, 2.5, 0.1, INK)
			draw_line(Vector2(-28, -32), Vector2(-36, -44), c2.darkened(0.2), 4.0, true)
			DrawKit.shine(self, Vector2(-6, -16), 8, 3, 0.5, 0.8)
		"cheese", "moon_cheese":
			if id == "moon_cheese":
				var outer := DrawKit.ellipse(Vector2(-4, 0), 40, 40, 40)
				var cut := DrawKit.ellipse(Vector2(20, -8), 32, 34, 40)
				for part in Geometry2D.clip_polygons(outer, cut):
					DrawKit.shape(self, part, c1, W, 0.15, INK)
				for p in [Vector2(-24, -8), Vector2(-20, 16), Vector2(-30, 4)]:
					DrawKit.shape(self, DrawKit.ellipse(p, 5, 4, 12), c2, 2.0, 0.0, c2.darkened(0.3))
				DrawKit.fill(self, DrawKit.star_pts(Vector2(28, -30), 7, 2.5, 4), Color("#fff1a8"))
			else:
				var w := PackedVector2Array([Vector2(-38, 22), Vector2(-30, -10), Vector2(36, -30), Vector2(40, 0), Vector2(36, 32), Vector2(-36, 34)])
				DrawKit.shape(self, w, c1, W, 0.15, INK)
				DrawKit.fill(self, PackedVector2Array([Vector2(-30, -10), Vector2(36, -30), Vector2(40, 0), Vector2(-38, 22)]), c1.lightened(0.15))
				for p in [Vector2(-10, 20), Vector2(14, 10), Vector2(26, 24), Vector2(4, -6)]:
					DrawKit.shape(self, DrawKit.ellipse(p, 6, 5, 12), c2, 2.0, 0.0, c2.darkened(0.3))
		"milk":
			var carton := PackedVector2Array([Vector2(-24, -16), Vector2(24, -16), Vector2(24, 40), Vector2(-24, 40)])
			DrawKit.shape(self, carton, Color("#f6f3ec"), W, 0.1, INK)
			DrawKit.shape(self, PackedVector2Array([Vector2(-24, -16), Vector2(0, -38), Vector2(24, -16)]), Color("#dfe9f5"), W, 0.1, INK)
			DrawKit.shape(self, DrawKit.rrect(Rect2(-6, -48, 12, 12), 3), c2, 2.5, 0.0, INK)
			DrawKit.fill(self, DrawKit.rrect(Rect2(-24, 4, 48, 20), 2), c2)
			DrawKit.fill(self, DrawKit.blob(Vector2(0, 14), 7, 3, 0.2, 6), Color.WHITE)
		"flour":
			_sack(c1, c2)
		"magic_flour":
			_sack(c1, c2)
			for p in [Vector2(-30, -34), Vector2(30, -22), Vector2(26, 30)]:
				DrawKit.fill(self, DrawKit.star_pts(p, 8, 2.5, 4), Color("#fff1a8"))
		"egg":
			var e := DrawKit.smooth(PackedVector2Array([Vector2(0, -40), Vector2(28, -20), Vector2(34, 12), Vector2(20, 38), Vector2(0, 42), Vector2(-20, 38), Vector2(-34, 12), Vector2(-28, -20)]), 2)
			DrawKit.shape(self, e, c1, W, 0.15, INK)
			DrawKit.shine(self, Vector2(-12, -14), 7, 12, 0.6, 0.3)
		"honey":
			var pot := DrawKit.smooth(PackedVector2Array([Vector2(-24, -20), Vector2(-36, 4), Vector2(-30, 34), Vector2(30, 34), Vector2(36, 4), Vector2(24, -20)]), 2)
			DrawKit.shape(self, pot, Color("#d98a2b"), W, 0.2, INK)
			DrawKit.shape(self, DrawKit.rrect(Rect2(-28, -28, 56, 12), 5), Color("#c06d1c"), W, 0.1, INK)
			DrawKit.shape(self, DrawKit.smooth(PackedVector2Array([Vector2(-26, -18), Vector2(-14, -18), Vector2(-14, -2), Vector2(-20, 4), Vector2(-26, -2)]), 1), c1, 2.5, 0.1, INK)
			draw_line(Vector2(10, -16), Vector2(26, -46), INK, 7.0, true)
			draw_line(Vector2(10, -16), Vector2(26, -46), Color("#c8955c"), 3.5, true)
			DrawKit.fill(self, DrawKit.rrect(Rect2(-24, 6, 48, 16), 4), c2)
		"frog_essence":
			_bottle(c1)
			DrawKit.circle(self, Vector2(-8, 18), 6, Color.WHITE, 2.0, 0.0)
			DrawKit.circle(self, Vector2(8, 18), 6, Color.WHITE, 2.0, 0.0)
			draw_circle(Vector2(-7, 19), 2.5, INK, true, -1.0, true)
			draw_circle(Vector2(9, 19), 2.5, INK, true, -1.0, true)
			DrawKit.poly_line(self, DrawKit.quad(Vector2(-8, 28), Vector2(0, 33), Vector2(8, 28)), INK, 2.5)
		"crunchy_beetle":
			for s in [-1.0, 1.0]:
				for k in 3:
					DrawKit.poly_line(self, PackedVector2Array([Vector2(s * 16, -8 + k * 14), Vector2(s * 34, -14 + k * 16), Vector2(s * 40, -4 + k * 16)]), INK, 3.5)
			DrawKit.circle(self, Vector2(0, -30), 12, Color("#2a3a35"), W, 0.1)
			var shell := DrawKit.ellipse(Vector2(0, 6), 26, 32, 28)
			DrawKit.shape(self, shell, c1, W, 0.25, INK)
			draw_line(Vector2(0, -24), Vector2(0, 36), INK, 3.0, true)
			for p in [Vector2(-12, 0), Vector2(12, 8), Vector2(-10, 20)]:
				draw_circle(p, 3.5, c2, true, -1.0, true)
			DrawKit.shine(self, Vector2(-12, -6), 4, 8, 0.5, 0.3)
		"ghost_dust":
			_jar(Color(c1, 0.7), Color("#7a86c9"), 0.8)
			var gp := Vector2(0, 8 + sin(_t * 3.0) * 2.0)
			var g := DrawKit.smooth(PackedVector2Array([gp + Vector2(-12, 14), gp + Vector2(-13, -6), gp + Vector2(0, -18), gp + Vector2(13, -6), gp + Vector2(12, 14), gp + Vector2(6, 9), gp + Vector2(0, 15), gp + Vector2(-6, 9)]), 1)
			DrawKit.shape(self, g, Color(1, 1, 1, 0.95), 2.5, 0.0, Color("#7a86c9"))
			draw_circle(gp + Vector2(-4, -4), 2.2, INK, true, -1.0, true)
			draw_circle(gp + Vector2(4, -4), 2.2, INK, true, -1.0, true)
		"rusty_bolt":
			draw_line(Vector2(-18, 24), Vector2(18, -18), INK, 18.0, true)
			draw_line(Vector2(-18, 24), Vector2(18, -18), c1, 11.0, true)
			for k in 4:
				var p := Vector2(-12, 17).lerp(Vector2(12, -11), k / 3.0)
				draw_line(p + Vector2(-6, -5), p + Vector2(6, 5), c1.darkened(0.3), 2.0, true)
			var hx := DrawKit.ellipse(Vector2(22, -24), 18, 18, 6, 0.3)
			DrawKit.shape(self, hx, c1, W, 0.25, INK)
			for p in [Vector2(-10, 14), Vector2(26, -30), Vector2(4, 0)]:
				DrawKit.fill(self, DrawKit.blob(p, 4, int(p.x), 0.4, 6), c2)
		"dragon_fire":
			_bottle(c1)
			var fh := 16.0 + 4.0 * sin(_t * 8.0)
			var fl := DrawKit.smooth(PackedVector2Array([Vector2(-10, 30), Vector2(-8, 18), Vector2(0, 30 - fh - 8), Vector2(8, 18), Vector2(10, 30)]), 2)
			DrawKit.fill(self, fl, c2)
			DrawKit.glow(self, Vector2(0, 14), 40, Color(1, 0.5, 0.1, 0.4))
		"alien_goo":
			var gb := DrawKit.blob(Vector2(0, 14), 36, 31, 0.15, 10)
			DrawKit.shape(self, gb, c1, W, 0.2, INK)
			DrawKit.shape(self, DrawKit.ellipse(Vector2(0, -14), 16, 18, 20), c1.lightened(0.1), W, 0.15, INK)
			DrawKit.circle(self, Vector2(0, -16), 8, Color.WHITE, 2.0, 0.0)
			draw_circle(Vector2(1, -15), 4, INK, true, -1.0, true)
			for p in [Vector2(-18, 18), Vector2(14, 26)]:
				draw_arc(p, 4, 0, TAU, 12, c2, 2.0, true)
		"bouncing_mushroom":
			DrawKit.shape(self, DrawKit.rrect(Rect2(-12, -2, 24, 40), 10), Color("#fff2e0"), W, 0.1, INK)
			var cap := DrawKit.smooth(PackedVector2Array([Vector2(-40, 4), Vector2(-34, -24), Vector2(0, -38), Vector2(34, -24), Vector2(40, 4)]), 2)
			DrawKit.shape(self, cap, c1, W, 0.2, INK)
			for p in [Vector2(-18, -14), Vector2(10, -24), Vector2(22, -6)]:
				DrawKit.shape(self, DrawKit.ellipse(p, 6, 5, 12), c2, 2.0, 0.0, INK)
			DrawKit.poly_line(self, PackedVector2Array([Vector2(-34, 40), Vector2(-24, 34), Vector2(-14, 40), Vector2(-4, 34)]), INK, 2.5)
		"vampire_rose":
			draw_line(Vector2(0, -2), Vector2(4, 44), Color("#2f6b33"), 6.0, true)
			for p in [Vector2(2, 14), Vector2(4, 30)]:
				DrawKit.fill(self, PackedVector2Array([p, p + Vector2(8, -2), p + Vector2(2, -6)]), Color("#2f6b33"))
			DrawKit.shape(self, DrawKit.ellipse(Vector2(14, 22), 12, 6, 14, -0.5), Color("#3f8f3f"), 2.5, 0.1, INK)
			DrawKit.circle(self, Vector2(0, -16), 24, c1, W, 0.2)
			DrawKit.poly_line(self, DrawKit.arc(Vector2(0, -16), 13, 13, 0.0, TAU * 0.85, 14), c1.darkened(0.35), 3.0)
			DrawKit.poly_line(self, DrawKit.arc(Vector2(0, -16), 6, 6, 1.0, TAU * 0.8, 10), c1.darkened(0.45), 2.5)
		"kraken_ink":
			_bottle(c1)
			var tp := DrawKit.bezier(Vector2(20, 30), Vector2(44, 20), Vector2(44, -10), Vector2(30, -20), 10)
			DrawKit.stroke(self, tp, c2, 7.0, INK, 2.5)
		"pirate_spice":
			var pouch := DrawKit.smooth(PackedVector2Array([Vector2(-16, -22), Vector2(-34, 8), Vector2(-28, 38), Vector2(28, 38), Vector2(34, 8), Vector2(16, -22)]), 2)
			DrawKit.shape(self, pouch, Color("#c8955c"), W, 0.15, INK)
			DrawKit.shape(self, DrawKit.smooth(PackedVector2Array([Vector2(-18, -22), Vector2(-10, -38), Vector2(0, -30), Vector2(10, -38), Vector2(18, -22)]), 1), c1, W, 0.15, INK)
			draw_line(Vector2(-18, -20), Vector2(18, -20), Color("#7a3a1a"), 4.0, true)
			DrawKit.circle(self, Vector2(0, 12), 11, Color("#f4f0e6"), 2.5, 0.0)
			draw_circle(Vector2(-4, 10), 2.5, INK, true, -1.0, true)
			draw_circle(Vector2(4, 10), 2.5, INK, true, -1.0, true)
		"night_berry":
			for p in [Vector2(-14, 8), Vector2(14, 8), Vector2(0, 28), Vector2(0, -10), Vector2(-20, 26), Vector2(20, 26)]:
				DrawKit.circle(self, p, 13, c1, W - 0.5, 0.25)
				DrawKit.shine(self, p + Vector2(-4, -4), 3, 2, 0.6)
			DrawKit.shape(self, DrawKit.ellipse(Vector2(8, -28), 14, 6, 14, -0.4), Color("#3f8f3f"), 2.5, 0.1, INK)
		"lightning_syrup":
			_bottle(c1)
			DrawKit.shape(self, PackedVector2Array([Vector2(4, 4), Vector2(-10, 20), Vector2(0, 20), Vector2(-6, 34), Vector2(10, 16), Vector2(0, 16)]), c2, 2.0, 0.0, INK)
		"nano_sprinkles":
			var sh := DrawKit.rrect(Rect2(-22, -20, 44, 58), 10)
			DrawKit.shape(self, sh, c1, W, 0.25, INK)
			DrawKit.shape(self, DrawKit.ellipse(Vector2(0, -24), 22, 10, 18), c1.lightened(0.15), W, 0.1, INK)
			for k in 3:
				draw_circle(Vector2(-8 + k * 8, -26), 2.0, INK, true, -1.0, true)
			var cols := [Color("#ff5fa2"), Color("#ffd23f"), Color("#4ad6ff")]
			for i in 6:
				var p := Vector2(-14 + (i % 3) * 14, 2 + (i / 3) * 16)
				draw_line(p + Vector2(-4, -3), p + Vector2(4, 3), cols[i % 3], 4.0, true)
		"ice_crystal":
			for p in [[Vector2(-18, 10), 0.8], [Vector2(18, 12), 0.75], [Vector2(0, 0), 1.0]]:
				var c: Vector2 = p[0]
				var sc: float = p[1]
				var cr := PackedVector2Array([c + Vector2(-11, 30) * sc, c + Vector2(-12, -10) * sc, c + Vector2(0, -36) * sc, c + Vector2(12, -10) * sc, c + Vector2(11, 30) * sc])
				DrawKit.shape(self, cr, c1, W, 0.3, Color("#2b7fb3"))
				draw_line(c + Vector2(0, -36) * sc, c + Vector2(0, 30) * sc, Color(1, 1, 1, 0.6), 2.0, true)
		"fairy_nectar":
			_bottle(c1, Color("#ff9fd0"))
			for s in [-1.0, 1.0]:
				DrawKit.shape(self, DrawKit.ellipse(Vector2(s * 30, -6), 16, 9, 14, s * 0.5), Color(0.8, 1.0, 0.95, 0.6), 2.0, 0.0, Color("#5ec8a8"))
		"black_truffle":
			var tr := DrawKit.blob(Vector2(0, 8), 34, 41, 0.14, 12)
			DrawKit.shape(self, tr, c1, W, 0.25, INK)
			for p in [Vector2(-12, 0), Vector2(10, 14), Vector2(4, -10), Vector2(-6, 22)]:
				draw_circle(p, 3.0, c2, true, -1.0, true)
			DrawKit.fill(self, DrawKit.star_pts(Vector2(26, -26), 7, 2.5, 4), Color("#f2c14e"))
		"star_dust":
			var sj := DrawKit.star_pts(Vector2(0, 6), 40, 18)
			DrawKit.shape(self, DrawKit.smooth(sj, 1), c1, W, 0.25, INK)
			DrawKit.glow(self, Vector2(0, 6), 50, Color(1, 1, 0.7, 0.5))
			DrawKit.circle(self, Vector2(0, 6), 8, c2, 2.0, 0.0)
		"eye_pickle":
			_jar(Color(c1, 0.75), Color("#6b7a3a"), 0.8)
			for p in [Vector2(-10, 10), Vector2(10, 22), Vector2(6, 0)]:
				DrawKit.circle(self, p, 7, Color("#f4f0e6"), 2.0, 0.0)
				draw_circle(p + Vector2(1, 0), 3, Color("#3a7a2a"), true, -1.0, true)
				draw_circle(p + Vector2(1, 0), 1.5, INK, true, -1.0, true)
		"moldy_spirit":
			var w2 := PackedVector2Array([Vector2(-36, 26), Vector2(-28, -4), Vector2(34, -22), Vector2(38, 4), Vector2(34, 32), Vector2(-34, 34)])
			DrawKit.shape(self, w2, c1, W, 0.15, INK)
			for p in [Vector2(-14, 18), Vector2(12, 10), Vector2(24, 24)]:
				DrawKit.fill(self, DrawKit.blob(p, 6, int(p.x + 3), 0.3, 6), c2)
			var gp2 := Vector2(4, -30 + sin(_t * 3.0) * 2.0)
			DrawKit.fill(self, DrawKit.ellipse(gp2, 14, 12, 14), Color(0.85, 1.0, 0.85, 0.7))
			draw_circle(gp2 + Vector2(-4, -2), 2, INK, true, -1.0, true)
			draw_circle(gp2 + Vector2(4, -2), 2, INK, true, -1.0, true)
		"century_pickle":
			_jar(Color(c2, 0.7), Color("#8a6a3a"), 0.85)
			var pk := DrawKit.smooth(PackedVector2Array([Vector2(-8, -12), Vector2(8, -12), Vector2(12, 26), Vector2(-12, 26)]), 2)
			DrawKit.shape(self, pk, c1, 2.5, 0.2, INK)
			for k in 3:
				draw_circle(Vector2(-3 + (k % 2) * 6, -2 + k * 9), 1.8, c1.darkened(0.3), true, -1.0, true)
		_:
			DrawKit.circle(self, Vector2.ZERO, 34, c1, W, 0.2)
			DrawKit.text(self, "?", Vector2(0, 0), 40, Color.WHITE, true, INK, 6)
