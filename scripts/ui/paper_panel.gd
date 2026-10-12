class_name PaperPanel
extends Control
## Background drawer for stationery panels. The `content` margin container holds children.

var style := "clipboard"     # clipboard, manila, cork, newspaper, card, sticky, lined
var tab_text := ""
var col := Color("fff07a")
var tilt := 0.0
var content: MarginContainer
var _noise: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	content = MarginContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(content)


func set_style(s: String) -> void:
	style = s
	var m := {"l": 22, "t": 22, "r": 22, "b": 18}
	match s:
		"clipboard": m = {"l": 30, "t": 74, "r": 30, "b": 24}
		"manila": m = {"l": 26, "t": 60, "r": 26, "b": 18}
		"cork": m = {"l": 26, "t": 56, "r": 26, "b": 22}
		"newspaper": m = {"l": 24, "t": 20, "r": 24, "b": 20}
	content.add_theme_constant_override("margin_left", m["l"])
	content.add_theme_constant_override("margin_top", m["t"])
	content.add_theme_constant_override("margin_right", m["r"])
	content.add_theme_constant_override("margin_bottom", m["b"])
	if s == "cork" and _noise.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		for i in 900:
			_noise.append([Vector2(rng.randf(), rng.randf()), rng.randf_range(0.8, 2.2), rng.randf()])
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	match style:
		"clipboard":
			draw_rect(Rect2(r.position + Vector2(5, 8), r.size), Color(0, 0, 0, 0.22))
			UiKit.draw_note(self, r, Color("b07a4a"), false, false)
			draw_rect(r, Color("8a5a32"), false, 2.0)
			var pr := r.grow(-14)
			pr.position.y += 22
			pr.size.y -= 22
			draw_rect(pr, UiKit.PAPER)
			draw_rect(Rect2(pr.position, Vector2(pr.size.x, 40)), Color(0.96, 0.94, 0.88))
			# metal clip
			var cx := r.size.x * 0.5
			draw_rect(Rect2(cx - 70, 4, 140, 34), Color("aeb7c2"))
			draw_rect(Rect2(cx - 70, 4, 140, 34), Color("6b7584"), false, 2.0)
			draw_rect(Rect2(cx - 40, 28, 80, 18), Color("c7ced8"))
			draw_rect(Rect2(cx - 40, 28, 80, 18), Color("6b7584"), false, 2.0)
			draw_circle(Vector2(cx, 16), 6, Color("6b7584"))
		"manila":
			var tabw := 210.0
			draw_rect(Rect2(r.position + Vector2(5, 8), r.size), Color(0, 0, 0, 0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(20, 0), Vector2(20 + tabw, 0), Vector2(36 + tabw, 30), Vector2(r.size.x, 30), Vector2(r.size.x, r.size.y), Vector2(0, r.size.y), Vector2(0, 30), Vector2(4, 30)]), UiKit.MANILA)
			draw_polyline(PackedVector2Array([Vector2(0, 30), Vector2(4, 30), Vector2(20, 0), Vector2(20 + tabw, 0), Vector2(36 + tabw, 30), Vector2(r.size.x, 30)]), Color(0.55, 0.4, 0.2, 0.5), 1.5, true)
			draw_rect(Rect2(0, 30, r.size.x, r.size.y - 30), Color(0.55, 0.4, 0.2, 0.4), false, 1.5)
			if tab_text != "":
				draw_string(UiKit.font("type"), Vector2(36, 22), tab_text, HORIZONTAL_ALIGNMENT_LEFT, tabw - 20, 18, UiKit.INK)
			# inner paper sheet peeking
			draw_rect(Rect2(14, 42, r.size.x - 28, r.size.y - 52), Color(1, 0.99, 0.95))
			draw_rect(Rect2(14, 42, r.size.x - 28, r.size.y - 52), Color(0.55, 0.4, 0.2, 0.25), false, 1.0)
		"cork":
			draw_rect(Rect2(r.position + Vector2(5, 8), r.size), Color(0, 0, 0, 0.22))
			draw_rect(r, Color("a0703f"))
			var ir := r.grow(-12)
			draw_rect(ir, UiKit.CORK)
			for n in _noise:
				var p: Vector2 = ir.position + n[0] * ir.size
				draw_circle(p, n[1], Color(0.55, 0.38, 0.2, 0.25 + n[2] * 0.2))
			draw_rect(ir, Color(0.4, 0.25, 0.1, 0.5), false, 2.0)
			if tab_text != "":
				var tr := Rect2(Vector2(r.size.x * 0.5 - 150, 14), Vector2(300, 38))
				UiKit.draw_note(self, tr, UiKit.PAPER, true, false)
				draw_string(UiKit.font("marker"), tr.position + Vector2(0, 28), tab_text, HORIZONTAL_ALIGNMENT_CENTER, tr.size.x, 22, UiKit.INK)
				UiKit.draw_tape(self, tr.position + Vector2(18, 4), Vector2(48, 16), -0.4)
				UiKit.draw_tape(self, Vector2(tr.end.x - 18, tr.position.y + 4), Vector2(48, 16), 0.4)
		"newspaper":
			draw_rect(Rect2(r.position + Vector2(6, 9), r.size), Color(0, 0, 0, 0.25))
			draw_rect(r, Color("f4efe1"))
			draw_rect(r, Color(0.3, 0.25, 0.2, 0.4), false, 1.5)
		"card":
			draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.18))
			UiKit.draw_lined_paper(self, r, UiKit.PAPER, 28.0, false)
			draw_line(Vector2(0, 46), Vector2(r.size.x, 46), Color(0.9, 0.3, 0.35, 0.5), 1.4)
			draw_rect(r, UiKit.INK_SOFT, false, 1.2)
		"lined":
			draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.18))
			UiKit.draw_lined_paper(self, r)
			draw_rect(r, UiKit.INK_SOFT, false, 1.2)
		"sticky":
			UiKit.draw_note(self, r, col)
