class_name PortraitIcon
extends Control
## Karakterin görünüm verisinden çizilen küçük stilize portre.

var char_id := ""


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var c: Dictionary = GameState.ch(char_id) if GameState.active else {}
	var look: Dictionary = c.get("look", {})
	var s := minf(size.x, size.y)
	var ctr := Vector2(size.x * 0.5, size.y * 0.5)
	var r := s * 0.5
	draw_circle(ctr, r, UI.NAVY3)
	var outer := Color(String(look.get("outer", "604030")))
	var robe := Color(String(look.get("robe", "c0b090")))
	var skin: Color = Humanoid.SKINS[clampi(int(look.get("skin", 1)), 0, 2)]
	var head_t: String = look.get("head", "takke")
	var female: bool = c.get("gender", "m") == "f"
	# omuzlar
	var pts := PackedVector2Array()
	for i in range(17):
		var a := PI + PI * float(i) / 16.0
		pts.append(ctr + Vector2(cos(a) * r * 0.78, r * 0.98 + sin(a) * r * 0.55))
	draw_colored_polygon(pts, outer)
	draw_rect(Rect2(ctr + Vector2(-r * 0.1, r * 0.45), Vector2(r * 0.2, r * 0.6)), robe)
	# başörtüsü/peçe arka
	if head_t in ["scarf_dark", "scarf_light", "valide"]:
		var sc := Color(0.25, 0.25, 0.3) if head_t == "scarf_dark" else (robe.lightened(0.35) if head_t == "scarf_light" else Color(0.95, 0.93, 0.9))
		draw_circle(ctr + Vector2(0, -r * 0.05), r * 0.42, sc)
	elif head_t.begins_with("hotoz"):
		draw_circle(ctr + Vector2(0, -r * 0.08), r * 0.36, Color(0.15, 0.09, 0.05))
		draw_rect(Rect2(ctr + Vector2(-r * 0.3, -r * 0.05), Vector2(r * 0.6, r * 0.55)), Color(0.15, 0.09, 0.05))
	# yüz
	draw_circle(ctr + Vector2(0, -r * 0.1), r * 0.3, skin)
	draw_circle(ctr + Vector2(-r * 0.1, -r * 0.12), r * 0.035, Color(0.1, 0.07, 0.05))
	draw_circle(ctr + Vector2(r * 0.1, -r * 0.12), r * 0.035, Color(0.1, 0.07, 0.05))
	var beard: String = look.get("beard", "")
	if beard != "" and not female:
		var bc: Color = Humanoid.BEARDS.get(beard, Humanoid.BEARDS["short"])
		var bp := PackedVector2Array()
		var long := beard in ["long", "grey", "white"]
		for i in range(13):
			var a2 := PI * float(i) / 12.0
			bp.append(ctr + Vector2(cos(a2) * r * 0.27, -r * 0.04 + sin(a2) * r * (0.32 if long else 0.2)))
		draw_colored_polygon(bp, bc)
	# başlık
	var white := Color(0.96, 0.95, 0.9)
	match head_t:
		"sultan":
			draw_circle(ctr + Vector2(0, -r * 0.42), r * 0.36, white)
			draw_rect(Rect2(ctr + Vector2(-r * 0.08, -r * 0.82), Vector2(r * 0.16, r * 0.14)), Color(0.65, 0.1, 0.12))
			draw_line(ctr + Vector2(0, -r * 0.62), ctr + Vector2(r * 0.05, -r * 0.98), white, 3.0)
			draw_circle(ctr + Vector2(0, -r * 0.42), r * 0.06, Color(0.1, 0.7, 0.4))
		"vezir":
			draw_rect(Rect2(ctr + Vector2(-r * 0.3, -r * 0.92), Vector2(r * 0.6, r * 0.55)), white)
			draw_rect(Rect2(ctr + Vector2(-r * 0.31, -r * 0.42), Vector2(r * 0.62, r * 0.06)), UI.GOLD)
		"sarik", "sarik_small", "kadi":
			var tr := 0.36 if head_t == "kadi" else (0.3 if head_t == "sarik" else 0.27)
			draw_circle(ctr + Vector2(0, -r * 0.4), r * tr, white)
			if head_t == "kadi":
				draw_rect(Rect2(ctr + Vector2(-r * 0.36, -r * 0.34), Vector2(r * 0.72, r * 0.06)), Color(0.15, 0.4, 0.25))
		"bork":
			draw_rect(Rect2(ctr + Vector2(-r * 0.22, -r * 1.0), Vector2(r * 0.44, r * 0.62)), white)
			draw_rect(Rect2(ctr + Vector2(-r * 0.06, -r * 0.8), Vector2(r * 0.12, r * 0.3)), UI.GOLD)
		"cook":
			draw_rect(Rect2(ctr + Vector2(-r * 0.25, -r * 0.72), Vector2(r * 0.5, r * 0.32)), white)
		"foreign_hat":
			draw_rect(Rect2(ctr + Vector2(-r * 0.45, -r * 0.42), Vector2(r * 0.9, r * 0.06)), Color(0.1, 0.1, 0.14))
			draw_rect(Rect2(ctr + Vector2(-r * 0.2, -r * 0.68), Vector2(r * 0.4, r * 0.28)), Color(0.1, 0.1, 0.14))
		"valide":
			draw_rect(Rect2(ctr + Vector2(-r * 0.2, -r * 0.82), Vector2(r * 0.4, r * 0.42)), outer)
			draw_rect(Rect2(ctr + Vector2(-r * 0.21, -r * 0.46), Vector2(r * 0.42, r * 0.06)), UI.GOLD)
		"hotoz_blue", "hotoz_red":
			var capc := Color(0.2, 0.32, 0.6) if head_t == "hotoz_blue" else Color(0.62, 0.12, 0.18)
			draw_rect(Rect2(ctr + Vector2(-r * 0.15, -r * 0.62), Vector2(r * 0.3, r * 0.22)), capc)
			draw_rect(Rect2(ctr + Vector2(-r * 0.16, -r * 0.43), Vector2(r * 0.32, r * 0.05)), UI.GOLD)
		"scarf_dark", "scarf_light":
			pass
		_:
			draw_circle(ctr + Vector2(0, -r * 0.36), r * 0.26, outer.darkened(0.15))
	draw_arc(ctr, r - 1.5, 0, TAU, 40, UI.GOLD, 3.0, true)
	if c.get("gone", false):
		draw_line(ctr + Vector2(-r * 0.6, -r * 0.6), ctr + Vector2(r * 0.6, r * 0.6), Color(0.8, 0.2, 0.2), 4.0)
