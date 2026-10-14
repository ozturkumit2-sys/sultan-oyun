class_name OfficeBackdrop
extends Node2D
## Floor slab, zoned floors (wood, carpet, tiles), back walls, windows and wall decor.
## Static: drawn once. Dynamic wall details live in WallDynamic.

const WALL_H := 108.0
const SLAB := 16.0

const WALL_R := Color("eef4ef")
const WALL_L := Color("dde9e2")
const TRIM := Color("c9b497")


func _ready() -> void:
	z_index = -20


func _draw() -> void:
	var off := Vector2.ZERO
	_draw_slab(off)
	_draw_floor(off)
	_draw_walls(off)
	for d in OfficeLayout.wall_decor():
		_draw_decor(d, off)
	_draw_window_light(off)


func _draw_slab(off: Vector2) -> void:
	var W := float(C.GRID_W)
	var H := float(C.GRID_H)
	var down := Vector2(0, SLAB)
	# front-left side (y = H edge) and front-right side (x = W edge)
	var a := Iso.P(0, H) + off
	var b := Iso.P(W, H) + off
	var c := Iso.P(W, 0) + off
	Iso.poly(self, PackedVector2Array([a, b, b + down, a + down]), Color("c9a27a"), Iso.INK)
	Iso.poly(self, PackedVector2Array([b, c, c + down, b + down]), Color("b38b62"), Iso.INK)
	# plank lines on the slab sides
	for k in range(1, int(W)):
		var p := Iso.P(k, H) + off
		draw_line(p, p + down, Color(0, 0, 0, 0.12), 1.0)
	for k in range(1, int(H)):
		var p2 := Iso.P(W, k) + off
		draw_line(p2, p2 + down, Color(0, 0, 0, 0.12), 1.0)


func _tile_color(zone: String, x: int, y: int) -> Array:
	# returns [fill, detail kind]
	var hv := float((x * 73856093) ^ (y * 19349663)) / 1e9
	var jitter := fmod(absf(hv), 1.0) * 0.04 - 0.02
	match zone:
		"meeting":
			return [Color("d8d0f0").lightened(jitter), "carpet"]
		"boss":
			return [Color("cfe2cf").lightened(jitter), "carpet"]
		"kitchen":
			return [Color("f6f1e7") if (x + y) % 2 == 0 else Color("e6dfd0"), "tile"]
		"reception":
			return [Color("efe6da").lightened(jitter), "marble"]
	return [Color("e9cba0").lightened(jitter), "wood"]


func _draw_floor(off: Vector2) -> void:
	for y in C.GRID_H:
		for x in C.GRID_W:
			var zone := OfficeLayout.zone_of(Vector2i(x, y))
			var td := _tile_color(zone, x, y)
			var col: Color = td[0]
			Iso.diamond(self, off, x, y, 1, 1, 0, col)
			match td[1]:
				"wood":
					for k in range(1, 3):
						var t := k / 3.0
						draw_line(Iso.P(x, y + t) + off, Iso.P(x + 1, y + t) + off, Color(0.6, 0.42, 0.25, 0.22), 1.0)
					var seam := 0.25 + fmod(float(x * 7 + y * 3), 3.0) * 0.25
					draw_line(Iso.P(x + seam, y) + off, Iso.P(x + seam, y + 0.333) + off, Color(0.6, 0.42, 0.25, 0.22), 1.0)
					draw_line(Iso.P(x + fmod(seam + 0.5, 1.0), y + 0.333) + off, Iso.P(x + fmod(seam + 0.5, 1.0), y + 0.667) + off, Color(0.6, 0.42, 0.25, 0.22), 1.0)
				"tile":
					Iso.poly(self, PackedVector2Array([Iso.P(x, y) + off, Iso.P(x + 1, y) + off, Iso.P(x + 1, y + 1) + off, Iso.P(x, y + 1) + off]), Color(0, 0, 0, 0), Color(0.5, 0.45, 0.4, 0.25), 1.0)
				"carpet":
					var c := Iso.P(x + 0.5, y + 0.5) + off
					draw_circle(c, 1.2, Color(1, 1, 1, 0.35))
				"marble":
					if (x * 5 + y * 3) % 4 == 0:
						draw_line(Iso.P(x + 0.2, y + 0.3) + off, Iso.P(x + 0.7, y + 0.8) + off, Color(0.6, 0.55, 0.5, 0.25), 1.0)
					Iso.poly(self, PackedVector2Array([Iso.P(x, y) + off, Iso.P(x + 1, y) + off, Iso.P(x + 1, y + 1) + off, Iso.P(x, y + 1) + off]), Color(0, 0, 0, 0), Color(0.6, 0.55, 0.5, 0.18), 1.0)
	# rugs
	Iso.floor_ellipse(self, off, 1.4, 6.9, 1.35, 0.2, Color("f2c6b4"), Color(0.6, 0.35, 0.3, 0.5))
	Iso.floor_ellipse(self, off, 1.4, 6.9, 1.05, 0.3, Color("f7d9cb"))
	Iso.diamond(self, off, 10.2, 1.1, 3.4, 2.6, 0.2, Color("b7cfb9"), Color(0.35, 0.5, 0.38, 0.6))
	Iso.diamond(self, off, 10.4, 1.3, 3.0, 2.2, 0.3, Color("c6dac7"))
	# welcome mat at the entrance
	Iso.diamond(self, off, 12.85, 10.75, 1.0, 1.5, 0.3, Color("8e5a4c"), Iso.INK_SOFT)
	var tf := Transform2D(Vector2(1, 0.5), Vector2(-1, 0.5), Iso.P(13.05, 11.0, 0.3) + off)
	draw_set_transform_matrix(tf)
	draw_string(UiKit.font("slab"), Vector2(2, 14), "HELLO", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f3d9a4"))
	draw_set_transform_matrix(Transform2D())
	# zone outlines (soft) so rooms read clearly
	Iso.poly(self, PackedVector2Array([Iso.P(0, 0) + off, Iso.P(5, 0) + off, Iso.P(5, 5) + off, Iso.P(0, 5) + off]), Color(0, 0, 0, 0), Color(0.4, 0.3, 0.6, 0.35), 1.4)
	Iso.poly(self, PackedVector2Array([Iso.P(9, 0) + off, Iso.P(14, 0) + off, Iso.P(14, 5) + off, Iso.P(9, 5) + off]), Color(0, 0, 0, 0), Color(0.3, 0.5, 0.35, 0.35), 1.4)
	Iso.poly(self, PackedVector2Array([Iso.P(0, 9) + off, Iso.P(5, 9) + off, Iso.P(5, 14) + off, Iso.P(0, 14) + off]), Color(0, 0, 0, 0), Color(0.5, 0.45, 0.4, 0.3), 1.4)
	# floor outline
	Iso.poly(self, PackedVector2Array([Iso.P(0, 0) + off, Iso.P(C.GRID_W, 0) + off, Iso.P(C.GRID_W, C.GRID_H) + off, Iso.P(0, C.GRID_H) + off]), Color(0, 0, 0, 0), Iso.INK, 1.6)


func _draw_walls(off: Vector2) -> void:
	var W := float(C.GRID_W)
	var H := float(C.GRID_H)
	var up := Vector2(0, -WALL_H)
	var t := 0.14
	# left wall (x=0), right wall (y=0)
	Iso.poly(self, PackedVector2Array([Iso.P(0, H) + off, Iso.P(0, 0) + off, Iso.P(0, 0) + off + up, Iso.P(0, H) + off + up]), WALL_L, Iso.INK)
	Iso.poly(self, PackedVector2Array([Iso.P(0, 0) + off, Iso.P(W, 0) + off, Iso.P(W, 0) + off + up, Iso.P(0, 0) + off + up]), WALL_R, Iso.INK)
	# subtle vertical panel lines
	for k in range(1, int(W)):
		draw_line(Iso.P(k, 0, 8) + off, Iso.P(k, 0, WALL_H - 4) + off, Color(0.4, 0.5, 0.45, 0.07), 1.0)
	for k in range(1, int(H)):
		draw_line(Iso.P(0, k, 8) + off, Iso.P(0, k, WALL_H - 4) + off, Color(0.4, 0.5, 0.45, 0.07), 1.0)
	# baseboards
	Iso.poly(self, PackedVector2Array([Iso.P(0, H, 0) + off, Iso.P(0, 0, 0) + off, Iso.P(0, 0, 7) + off, Iso.P(0, H, 7) + off]), Iso.shade(TRIM, 0.92), Color(0, 0, 0, 0))
	Iso.poly(self, PackedVector2Array([Iso.P(0, 0, 0) + off, Iso.P(W, 0, 0) + off, Iso.P(W, 0, 7) + off, Iso.P(0, 0, 7) + off]), TRIM, Color(0, 0, 0, 0))
	# top caps (wall thickness)
	Iso.poly(self, PackedVector2Array([Iso.P(-t, -t, WALL_H) + off, Iso.P(W, -t, WALL_H) + off, Iso.P(W, 0, WALL_H) + off, Iso.P(0, 0, WALL_H) + off]), Color("f9fbf8"), Iso.INK)
	Iso.poly(self, PackedVector2Array([Iso.P(-t, -t, WALL_H) + off, Iso.P(0, 0, WALL_H) + off, Iso.P(0, H, WALL_H) + off, Iso.P(-t, H, WALL_H) + off]), Color("f3f6f2"), Iso.INK)
	# wall end faces at the front
	Iso.poly(self, PackedVector2Array([Iso.P(W, 0, 0) + off, Iso.P(W, -t, 0) + off, Iso.P(W, -t, WALL_H) + off, Iso.P(W, 0, WALL_H) + off]), Color("cfd9d2"), Iso.INK)
	Iso.poly(self, PackedVector2Array([Iso.P(0, H, 0) + off, Iso.P(-t, H, 0) + off, Iso.P(-t, H, WALL_H) + off, Iso.P(0, H, WALL_H) + off]), Color("c4d1c9"), Iso.INK)
	# entrance door frame on the front-right edge (x = W, y 10.85..12.2) drawn as a floor threshold
	Iso.diamond(self, off, W - 0.08, 10.8, 0.16, 1.4, 0.4, Color("8a7a66"))


## Applies the wall plane transform; returns local width in px.
func _wall(side: String, a: float, b: float, z_top: float, off: Vector2) -> float:
	var along := a if side == "R" else b
	draw_set_transform_matrix(Iso.wall_xform(side, along, z_top, off))
	return (b - a) * Iso.WALL_UNIT


func _draw_decor(d: Dictionary, off: Vector2) -> void:
	var side: String = d["side"]
	var a: float = d["a"]
	var b: float = d["b"]
	match d["type"]:
		"window":
			var wd := _wall(side, a, b, 94, off)
			var hh := 60.0
			draw_rect(Rect2(-3, -3, wd + 6, hh + 6), Color("ffffff"))
			# sky
			for i in 12:
				var tt := i / 12.0
				draw_rect(Rect2(0, hh * tt, wd, hh / 12.0 + 0.5), Color("a9d6f2").lerp(Color("e8f6fd"), tt))
			# city skyline + cloud
			var rng := RandomNumberGenerator.new()
			rng.seed = int(a * 100)
			var bx := 0.0
			while bx < wd:
				var bw := rng.randf_range(8, 16)
				var bh := rng.randf_range(10, 28)
				draw_rect(Rect2(bx, hh - bh, minf(bw, wd - bx), bh), Color(0.72, 0.82, 0.88, 0.9))
				for wy in range(int(hh - bh + 4), int(hh - 3), 6):
					draw_rect(Rect2(bx + 2, wy, 2, 2), Color(1, 1, 1, 0.7))
				bx += bw + 1
			draw_circle(Vector2(wd * 0.3, 14), 7, Color(1, 1, 1, 0.9))
			draw_circle(Vector2(wd * 0.3 + 8, 12), 9, Color(1, 1, 1, 0.9))
			draw_circle(Vector2(wd * 0.3 + 17, 15), 6, Color(1, 1, 1, 0.9))
			# glass shine
			draw_colored_polygon(PackedVector2Array([Vector2(wd * 0.55, 0), Vector2(wd * 0.68, 0), Vector2(wd * 0.45, hh), Vector2(wd * 0.32, hh)]), Color(1, 1, 1, 0.25))
			# mullions & frame
			draw_rect(Rect2(wd * 0.5 - 1.5, 0, 3, hh), Color("ffffff"))
			draw_rect(Rect2(0, hh * 0.45, wd, 3), Color("ffffff"))
			draw_rect(Rect2(-3, -3, wd + 6, hh + 6), Iso.INK, false, 1.3)
			draw_rect(Rect2(-6, hh + 3, wd + 12, 5), Color("f4efe6"))
			draw_rect(Rect2(-6, hh + 3, wd + 12, 5), Iso.INK, false, 1.0)
		"board":
			var wd2 := _wall(side, a, b, 88, off)
			draw_rect(Rect2(-2, -2, wd2 + 4, 48), Color("c9ced6"))
			draw_rect(Rect2(1, 1, wd2 - 2, 42), Color("ffffff"))
			draw_rect(Rect2(-2, -2, wd2 + 4, 48), Iso.INK, false, 1.2)
			draw_rect(Rect2(6, 46, wd2 - 12, 4), Color("aab0ba"))
			draw_rect(Rect2(10, 44, 9, 3), Color("e63946"))
			draw_rect(Rect2(22, 44, 9, 3), Color("2b6cb0"))
		"sign":
			var wd3 := _wall(side, a, b, 96, off)
			draw_rect(Rect2(0, 0, wd3, 16), Color("fff07a"))
			draw_rect(Rect2(0, 0, wd3, 16), Iso.INK, false, 1.0)
			draw_string(UiKit.font("marker"), Vector2(2, 7), "PLEASE DON'T", HORIZONTAL_ALIGNMENT_LEFT, wd3 - 3, 6, Color("e63946"))
			draw_string(UiKit.font("marker"), Vector2(2, 14), "KICK PRINTER", HORIZONTAL_ALIGNMENT_LEFT, wd3 - 3, 6, Color("e63946"))
		"ac":
			var wd4 := _wall(side, a, b, 100, off)
			draw_rect(Rect2(0, 0, wd4, 22), Color("fbfbfb"))
			draw_rect(Rect2(0, 22, wd4, 5), Color("dfe3e8"))
			for k in 6:
				draw_line(Vector2(6, 25 + k * 0.0), Vector2(wd4 - 6, 25), Color(0.5, 0.55, 0.6, 0.4), 1.0)
			for k in 3:
				draw_line(Vector2(8, 8 + k * 4), Vector2(wd4 - 22, 8 + k * 4), Color(0.6, 0.65, 0.7, 0.35), 1.0)
			draw_rect(Rect2(0, 0, wd4, 27), Iso.INK, false, 1.2)
		"thermostat":
			var wd5 := _wall(side, a, b, 70, off)
			draw_rect(Rect2(0, 0, wd5, 16), Color("f4f4f4"))
			draw_rect(Rect2(0, 0, wd5, 16), Iso.INK, false, 1.0)
		"clock":
			pass
		"alarm":
			var wda := _wall(side, a, b, 84, off)
			draw_rect(Rect2(0, 0, wda, 26), Color("d62828"))
			draw_rect(Rect2(3, 14, wda - 6, 9), Color("f8f9fa"))
			draw_string(UiKit.font("slab"), Vector2(4, 22), "FIRE", HORIZONTAL_ALIGNMENT_LEFT, wda - 6, 6, Color("d62828"))
			draw_rect(Rect2(0, 0, wda, 26), Iso.INK, false, 1.2)
		"speaker":
			var wds := _wall(side, a, b, 90, off)
			draw_rect(Rect2(2, 0, wds - 4, 30), Color("2b2d42"))
			draw_circle(Vector2(wds * 0.5, 11), 6.5, Color("4a4e69"))
			draw_circle(Vector2(wds * 0.5, 11), 3.0, Color("22223b"))
			draw_circle(Vector2(wds * 0.5, 24), 3.0, Color("4a4e69"))
			draw_rect(Rect2(2, 0, wds - 4, 30), Iso.INK, false, 1.2)
		"poster":
			var wd6 := _wall(side, a, b, 92, off)
			draw_rect(Rect2(0, 0, wd6, 30), Color("2b2d42"))
			draw_rect(Rect2(2, 2, wd6 - 4, 18), Color("f4a261"))
			draw_circle(Vector2(wd6 * 0.5, 11), 5, Color("fff07a"))
			draw_string(UiKit.font("slab"), Vector2(2, 27), "TEAMWORK", HORIZONTAL_ALIGNMENT_LEFT, wd6 - 2, 5, Color("ffffff"))
			draw_rect(Rect2(0, 0, wd6, 30), Iso.INK, false, 1.0)
		"breaker":
			var wd7 := _wall(side, a, b, 76, off)
			draw_rect(Rect2(0, 0, wd7, 32), Color("9aa5b1"))
			draw_rect(Rect2(3, 3, wd7 - 6, 26), Color("b7c1cc"))
			draw_rect(Rect2(0, 0, wd7, 32), Iso.INK, false, 1.2)
			draw_string(UiKit.font("slab"), Vector2(4, 11), "POWER", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("2b2d42"))
		"cabinets":
			var wd8 := _wall(side, a, b, 100, off)
			# backsplash tiles
			for ty in 4:
				for tx in int(wd8 / 8.0):
					draw_rect(Rect2(tx * 8 + (ty % 2) * 4, 44 + ty * 8, 7, 7), Color("ffffff") if (tx + ty) % 3 else Color("d7eee2"))
			# upper cabinets
			var n := int(wd8 / 30.0)
			var cw := wd8 / n
			for k in n:
				draw_rect(Rect2(k * cw + 1, 0, cw - 2, 34), Color("b9e0cd"))
				draw_rect(Rect2(k * cw + 1, 0, cw - 2, 34), Iso.INK, false, 1.0)
				draw_line(Vector2(k * cw + cw - 6, 22), Vector2(k * cw + cw - 6, 28), Color("6b7584"), 2.0)
	draw_set_transform_matrix(Transform2D())


func _draw_window_light(off: Vector2) -> void:
	# warm light patches on the floor below the windows
	for d in OfficeLayout.wall_decor():
		if d["type"] != "window":
			continue
		var a: float = d["a"]
		var b: float = d["b"]
		var pts: PackedVector2Array
		if d["side"] == "R":
			pts = PackedVector2Array([Iso.P(a, 0) + off, Iso.P(b, 0) + off, Iso.P(b + 0.8, 2.2) + off, Iso.P(a + 0.8, 2.2) + off])
		else:
			pts = PackedVector2Array([Iso.P(0, a) + off, Iso.P(0, b) + off, Iso.P(2.2, b + 0.8) + off, Iso.P(2.2, a + 0.8) + off])
		draw_colored_polygon(pts, Color(1, 0.98, 0.85, 0.16))
