class_name FxLayer
extends Node2D
## World-space particles: meddling sparkles, printer smoke, coffee sparks,
## coffee spills, anger puffs, cold snowflakes and heat shimmer.

var w: SimWorld
var parts: Array = []      # {p, v, life, max, kind, size, col}
var _acc := 0.0


func _ready() -> void:
	z_index = 40


func burst(kind: String, at: Vector2, n := 14) -> void:
	for i in n:
		var a := randf() * TAU
		var sp := randf_range(30, 90)
		match kind:
			"meddle":
				parts.append({"p": at, "v": Vector2(cos(a), sin(a) * 0.6) * sp, "life": 0.0, "max": randf_range(0.6, 1.1), "kind": "spark", "size": randf_range(2.5, 5.0), "col": [Color("b388ff"), Color("7ee8fa"), Color("fff07a")][i % 3]})
			"spill":
				parts.append({"p": at, "v": Vector2(cos(a) * sp * 0.6, -absf(sin(a)) * sp), "life": 0.0, "max": randf_range(0.5, 0.8), "kind": "drop", "size": randf_range(2.0, 3.5), "col": Color(0.45, 0.28, 0.15, 0.9)})
			"anger":
				parts.append({"p": at, "v": Vector2(cos(a), -absf(sin(a))) * sp * 0.6, "life": 0.0, "max": randf_range(0.5, 0.9), "kind": "puff", "size": randf_range(4, 7), "col": Color(0.55, 0.55, 0.6, 0.6)})
			"confetti":
				parts.append({"p": at, "v": Vector2(cos(a) * sp, -absf(sin(a)) * sp * 1.5), "life": 0.0, "max": randf_range(1.0, 1.6), "kind": "confetti", "size": randf_range(2.5, 4.0), "col": [Color("e63946"), Color("2a9d8f"), Color("f6c85f"), Color("5b8def"), Color("f28fa5")][i % 5]})


func _process(delta: float) -> void:
	if w == null:
		return
	var o := w.office.objects
	_acc += delta
	if _acc > 0.12:
		_acc = 0.0
		# printer smoke
		if o["printer"]["broken"] and randf() < 0.6:
			var pp := Iso.P(6.5, 0.5, 52)
			parts.append({"p": pp + Vector2(randf_range(-6, 6), 0), "v": Vector2(randf_range(-6, 6), -22), "life": 0.0, "max": 1.6, "kind": "smoke", "size": randf_range(4, 7), "col": Color(0.45, 0.45, 0.5, 0.45)})
		# coffee machine sparks
		if o["coffee"]["broken"] and randf() < 0.35:
			var cp := Iso.P(0.6, 10.5, 58)
			for k in 2:
				var a := randf() * TAU
				parts.append({"p": cp, "v": Vector2(cos(a), sin(a)) * 50, "life": 0.0, "max": 0.35, "kind": "spark", "size": 2.0, "col": Color("ffd166")})
		elif not o["coffee"]["broken"] and randf() < 0.12:
			parts.append({"p": Iso.P(0.75, 10.4, 62), "v": Vector2(randf_range(-3, 3), -16), "life": 0.0, "max": 1.4, "kind": "smoke", "size": 3.0, "col": Color(1, 1, 1, 0.5)})
		# water cooler leaking
		if o.get("water", {}).get("broken", false) and randf() < 0.5:
			parts.append({"p": Iso.P(0.6, 5.5, 30) + Vector2(randf_range(-4, 4), 0), "v": Vector2(randf_range(-4, 4), 30), "life": 0.0, "max": 0.7, "kind": "drop", "size": 2.2, "col": Color(0.45, 0.7, 1.0, 0.85)})
		# broken microwave smoke
		if o.get("microwave", {}).get("broken", false) and randf() < 0.45:
			parts.append({"p": Iso.P(0.5, 12.5, 46) + Vector2(randf_range(-5, 5), 0), "v": Vector2(randf_range(-5, 5), -20), "life": 0.0, "max": 1.4, "kind": "smoke", "size": randf_range(3, 6), "col": Color(0.35, 0.35, 0.38, 0.45)})
		# disco: sparkles drifting over the floor
		if o["lights"].get("party", false) and o["lights"]["on"] and randf() < 0.7:
			var dp := Vector2(randf_range(-400, 400), randf_range(-40, 380))
			parts.append({"p": dp, "v": Vector2(randf_range(-10, 10), randf_range(-10, 10)), "life": 0.0, "max": 0.9, "kind": "spark", "size": randf_range(2, 4), "col": Color.from_hsv(randf(), 0.6, 1.0, 0.9)})
		# temperature
		var temp := int(o["ac"]["temp"])
		if temp <= 19 and randf() < (0.8 if temp <= 16 else 0.4):
			var gp := Vector2(randf_range(-420, 420), randf_range(-60, 380))
			parts.append({"p": gp, "v": Vector2(randf_range(-8, 8), 22), "life": 0.0, "max": 3.0, "kind": "snow", "size": randf_range(1.5, 3.0), "col": Color(1, 1, 1, 0.85)})
		elif temp >= 25 and randf() < (0.8 if temp >= 29 else 0.35):
			var hp := Vector2(randf_range(-420, 420), randf_range(-40, 400))
			parts.append({"p": hp, "v": Vector2(0, -26), "life": 0.0, "max": 1.5, "kind": "heat", "size": randf_range(6, 10), "col": Color(1.0, 0.55, 0.3, 0.35)})
	for i in range(parts.size() - 1, -1, -1):
		var q: Dictionary = parts[i]
		q["life"] += delta
		if q["life"] >= q["max"]:
			parts.remove_at(i)
			continue
		q["p"] += q["v"] * delta
		match q["kind"]:
			"drop", "confetti":
				q["v"] += Vector2(0, 260) * delta
			"spark":
				q["v"] *= 0.92
	queue_redraw()


func _draw() -> void:
	for q in parts:
		var k: float = 1.0 - q["life"] / q["max"]
		var c: Color = q["col"]
		c.a *= k
		match q["kind"]:
			"spark":
				var s: float = q["size"]
				var pts := PackedVector2Array()
				for i in 8:
					var r := s if i % 2 == 0 else s * 0.35
					var a: float = PI * 0.25 * i + float(q["life"]) * 4.0
					pts.append(q["p"] + Vector2(cos(a), sin(a)) * r)
				draw_colored_polygon(pts, c)
			"smoke", "puff":
				draw_circle(q["p"], q["size"] * (1.0 + (1.0 - k) * 1.2), c)
			"drop":
				draw_circle(q["p"], q["size"], c)
			"snow":
				draw_circle(q["p"] + Vector2(sin(q["life"] * 3.0) * 6.0, 0), q["size"], c)
			"heat":
				var p0: Vector2 = q["p"]
				draw_polyline(PackedVector2Array([p0, p0 + Vector2(3, -4), p0 + Vector2(0, -8), p0 + Vector2(3, -12)]), c, 1.6, true)
			"confetti":
				draw_rect(Rect2(q["p"], Vector2(q["size"], q["size"] * 0.6)), c)
