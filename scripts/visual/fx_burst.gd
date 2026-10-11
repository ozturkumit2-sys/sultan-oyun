class_name FxBurst
extends Node2D
## Hafif, dokusuz parçacık efekti. Türler: confetti, hearts, stars, tears, smoke, sparkles,
## bubbles, flames, puff, text, coins, notes, sweat. Kendini bitince siler.

var kind := "confetti"
var parts: Array = []
var gravity := 600.0
var life := 1.4
var _t := 0.0
var text_value := ""
var text_color := Color.WHITE
var base_color := Color.WHITE
var rng := RandomNumberGenerator.new()
const CONFETTI := [Color("#ff5fa2"), Color("#ffd23f"), Color("#3ddc84"), Color("#4a9dff"), Color("#a25cff"), Color("#ff9b3d")]


static func spawn(parent: Node, pos: Vector2, k: String, count := 16, color := Color.WHITE, txt := "") -> FxBurst:
	var f := FxBurst.new()
	f.kind = k
	f.position = pos
	f.base_color = color
	f.text_value = txt
	f.z_index = 50
	parent.add_child(f)
	f._init_parts(count)
	return f


func _init_parts(count: int) -> void:
	rng.randomize()
	match kind:
		"confetti":
			gravity = 500.0
			life = 2.2
			for i in count:
				var a := rng.randf_range(-PI * 0.9, -PI * 0.1)
				var sp := rng.randf_range(250, 650)
				parts.append({"p": Vector2.ZERO, "v": Vector2(cos(a), sin(a)) * sp, "r": rng.randf() * TAU,
					"rv": rng.randf_range(-10, 10), "c": CONFETTI[i % CONFETTI.size()], "s": rng.randf_range(6, 11)})
		"hearts", "notes":
			gravity = -60.0
			life = 1.8
			for i in count:
				parts.append({"p": Vector2(rng.randf_range(-40, 40), rng.randf_range(-10, 10)),
					"v": Vector2(rng.randf_range(-40, 40), rng.randf_range(-160, -90)), "r": 0.0,
					"rv": rng.randf_range(-1, 1), "c": Color("#ff4f7a") if kind == "hearts" else base_color,
					"s": rng.randf_range(9, 15), "ph": rng.randf() * TAU})
		"stars", "sparkles", "coins":
			gravity = 220.0 if kind != "sparkles" else 0.0
			life = 1.2
			for i in count:
				var a := rng.randf() * TAU
				var sp := rng.randf_range(120, 340)
				parts.append({"p": Vector2.ZERO, "v": Vector2(cos(a), sin(a)) * sp, "r": rng.randf() * TAU,
					"rv": rng.randf_range(-6, 6), "c": base_color if base_color != Color.WHITE else Color("#ffd23f"),
					"s": rng.randf_range(7, 13)})
		"tears":
			gravity = 700.0
			life = 1.0
			for i in count:
				var side := -1.0 if i % 2 == 0 else 1.0
				parts.append({"p": Vector2(side * 28, 0), "v": Vector2(side * rng.randf_range(60, 160), rng.randf_range(-160, -60)),
					"r": 0.0, "rv": 0.0, "c": Color("#7fd3ff"), "s": rng.randf_range(5, 8), "delay": i * 0.06})
		"smoke", "puff":
			gravity = -40.0
			life = 1.3 if kind == "smoke" else 0.8
			for i in count:
				var a := rng.randf() * TAU
				var sp := rng.randf_range(20, 90) if kind == "smoke" else rng.randf_range(120, 220)
				parts.append({"p": Vector2(rng.randf_range(-8, 8), 0), "v": Vector2(cos(a), sin(a) - 0.6) * sp, "r": 0.0, "rv": 0.0,
					"c": base_color if base_color != Color.WHITE else Color(0.75, 0.75, 0.78), "s": rng.randf_range(10, 20)})
		"bubbles":
			gravity = -120.0
			life = 1.6
			for i in count:
				parts.append({"p": Vector2(rng.randf_range(-40, 40), rng.randf_range(-6, 6)), "v": Vector2(rng.randf_range(-20, 20), rng.randf_range(-80, -30)),
					"r": 0.0, "rv": 0.0, "c": base_color, "s": rng.randf_range(4, 10), "ph": rng.randf() * TAU})
		"flames":
			gravity = -300.0
			life = 0.9
			for i in count:
				parts.append({"p": Vector2(rng.randf_range(-30, 30), 0), "v": Vector2(rng.randf_range(-30, 30), rng.randf_range(-120, -40)),
					"r": 0.0, "rv": 0.0, "c": Color("#ff8a1a"), "s": rng.randf_range(8, 16)})
		"sweat":
			gravity = 500.0
			life = 0.9
			for i in count:
				parts.append({"p": Vector2(40, -10), "v": Vector2(rng.randf_range(40, 120), rng.randf_range(-200, -120)), "r": 0.0, "rv": 0.0,
					"c": Color("#9fe3ff"), "s": 7.0})
		"text":
			gravity = 0.0
			life = 1.3
			parts.append({"p": Vector2.ZERO, "v": Vector2(0, -70), "r": 0.0, "rv": 0.0, "c": text_color, "s": 1.0})


func _process(delta: float) -> void:
	_t += delta
	for p in parts:
		var d: float = p.get("delay", 0.0)
		if _t < d:
			continue
		p["v"] += Vector2(0, gravity) * delta
		if kind == "confetti":
			p["v"] *= 0.985
		p["p"] += p["v"] * delta
		p["r"] += p["rv"] * delta
	queue_redraw()
	if _t >= life:
		queue_free()


func _draw() -> void:
	var k := clampf(1.0 - _t / life, 0.0, 1.0)
	for p in parts:
		var d: float = p.get("delay", 0.0)
		if _t < d:
			continue
		var pos: Vector2 = p["p"]
		var c: Color = p["c"]
		var s: float = p["s"]
		match kind:
			"confetti":
				var cc := c
				cc.a = minf(1.0, k * 2.0)
				var w := s * absf(cos(p["r"] * 1.7))
				draw_set_transform(pos, p["r"], Vector2.ONE)
				draw_rect(Rect2(-w * 0.5, -s * 0.35, maxf(1.5, w), s * 0.7), cc)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"hearts":
				var hp := pos + Vector2(sin(_t * 4.0 + p["ph"]) * 10.0, 0)
				var hc := c
				hc.a = k
				DrawKit.fill(self, DrawKit.heart_pts(hp, s), hc)
				DrawKit.outline(self, DrawKit.heart_pts(hp, s), Color(0.4, 0.05, 0.15, k), 2.0)
			"notes":
				var np := pos + Vector2(sin(_t * 4.0 + p["ph"]) * 10.0, 0)
				var nc := c
				nc.a = k
				draw_circle(np, s * 0.45, nc, true, -1.0, true)
				draw_line(np + Vector2(s * 0.4, 0), np + Vector2(s * 0.4, -s * 1.4), nc, 3.0, true)
			"stars", "coins":
				var sc := c
				sc.a = k
				if kind == "coins":
					draw_circle(pos, s, Color("#f2b632", k), true, -1.0, true)
					draw_circle(pos, s * 0.65, Color("#ffe17a", k), true, -1.0, true)
				else:
					DrawKit.fill(self, DrawKit.star_pts(pos, s, s * 0.45, 5, p["r"]), sc)
			"sparkles":
				var spc := c
				spc.a = k
				var r := s * (0.6 + 0.4 * sin(_t * 12.0 + s))
				DrawKit.fill(self, DrawKit.star_pts(pos, r, r * 0.25, 4, p["r"]), spc)
			"tears":
				var tc := c
				tc.a = k
				draw_circle(pos, s, tc, true, -1.0, true)
				DrawKit.fill(self, PackedVector2Array([pos + Vector2(-s * 0.9, -s * 0.3), pos + Vector2(0, -s * 2.2), pos + Vector2(s * 0.9, -s * 0.3)]), tc)
			"smoke", "puff":
				var mc := c
				mc.a = k * 0.85
				draw_circle(pos, s * (1.0 + _t * 1.6), mc, true, -1.0, true)
			"bubbles":
				var bc := c
				bc.a = k * 0.9
				var bp := pos + Vector2(sin(_t * 5.0 + p["ph"]) * 6.0, 0)
				draw_arc(bp, s, 0, TAU, 18, bc, 2.0, true)
				draw_circle(bp + Vector2(-s * 0.35, -s * 0.35), s * 0.25, Color(1, 1, 1, k), true, -1.0, true)
			"flames":
				var fc := Color("#ffd23f").lerp(Color("#ff4f1a"), 1.0 - k)
				fc.a = k
				DrawKit.fill(self, DrawKit.ellipse(pos, s * 0.6 * k + 2, s * k + 2, 12), fc)
			"sweat":
				var wc := c
				wc.a = k
				draw_circle(pos, s, wc, true, -1.0, true)
			"text":
				var tcol := text_color
				tcol.a = minf(1.0, k * 2.0)
				var sz := 44 + int(10.0 * sin(minf(_t * 8.0, PI)))
				DrawKit.text(self, text_value, pos, sz, tcol, true, Color(0.2, 0.1, 0.1, tcol.a), 10)
