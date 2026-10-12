class_name Avatar
extends Control
## Simple stylized portrait generated from a name.

var seed_text := "x"
var fem := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(seed_text)
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var bgs := [Color("#3a2f45"), Color("#2f3a45"), Color("#45362f"), Color("#2f4538"), Color("#45302f")]
	draw_circle(c, s * 0.5, bgs[r.randi_range(0, bgs.size() - 1)])
	var skins := [Color("#f1d3b8"), Color("#e2b48f"), Color("#c68a5e"), Color("#9a6440"), Color("#6e4428")]
	var skin: Color = skins[r.randi_range(0, skins.size() - 1)]
	var hairs := [Color("#2a1d16"), Color("#5a3a22"), Color("#a8743f"), Color("#d8c08a"), Color("#888080"), Color("#141010")]
	var hair: Color = hairs[r.randi_range(0, hairs.size() - 1)]
	# shoulders
	var bgp := _circle(c, s * 0.5)
	var sh_col := Color("#c9a55a").darkened(r.randf() * 0.5)
	for poly in Geometry2D.intersect_polygons(_circle(c + Vector2(0, s * 0.52), s * 0.36), bgp):
		draw_colored_polygon(poly, sh_col)
	if fem and r.randf() < 0.8:
		draw_circle(c + Vector2(0, s * 0.02), s * 0.25, hair)
		var hr := PackedVector2Array([c + Vector2(-s * 0.25, 0), c + Vector2(s * 0.25, 0), c + Vector2(s * 0.25, s * 0.22), c + Vector2(-s * 0.25, s * 0.22)])
		for poly in Geometry2D.intersect_polygons(hr, bgp):
			draw_colored_polygon(poly, hair)
	draw_circle(c + Vector2(0, -s * 0.02), s * 0.2, skin)
	if not fem or r.randf() < 0.2:
		draw_arc(c + Vector2(0, -s * 0.05), s * 0.2, PI * 1.05, PI * 1.95, 12, hair, s * 0.09)
	else:
		draw_arc(c + Vector2(0, -s * 0.04), s * 0.21, PI * 1.0, PI * 2.0, 12, hair, s * 0.1)
	draw_circle(c + Vector2(-s * 0.07, -s * 0.03), s * 0.022, Color("#1b1720"))
	draw_circle(c + Vector2(s * 0.07, -s * 0.03), s * 0.022, Color("#1b1720"))
	draw_arc(c + Vector2(0, s * 0.04), s * 0.06, 0.3, PI - 0.3, 8, Color("#7a3a3a"), 2.0)


func _circle(center: Vector2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * float(i) / 40.0
		pts.append(center + Vector2(cos(a), sin(a)) * rad)
	return pts
