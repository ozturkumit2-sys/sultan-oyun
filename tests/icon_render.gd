extends Node2D
## Renders the launcher icon layers at 4x for downsampling.
var mode := "full"
var frames := 0
func _ready():
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2 and kv[0] == "mode": mode = kv[1]
	if mode == "fg":
		get_viewport().transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0) if mode == "fg" else Color("f2e3c6"))

func _draw():
	var S := get_viewport_rect().size.x
	var k := S / 432.0
	if mode != "fg":
		draw_rect(Rect2(0, 0, S, S), Color("f2e3c6"))
		for y in range(0, int(S), int(36 * k)):
			for x in range(0, int(S), int(36 * k)):
				draw_circle(Vector2(x + 18 * k, y + 18 * k), 2.2 * k, Color("dcc8a2"))
	if mode == "bg":
		return
	var c := Vector2(S * 0.5, S * 0.5)
	if mode == "fg":
		k *= 0.78
	# sticky note
	draw_set_transform(c + Vector2(-18, -40) * k, deg_to_rad(-8), Vector2(k, k))
	UiKit.draw_note(self, Rect2(-118, -96, 236, 196), UiKit.sticky("yellow"))
	UiKit.draw_tape(self, Vector2(0, -96), Vector2(90, 26), 0.08)
	draw_string(UiKit.font("marker"), Vector2(-118, -26), "OFFICE", HORIZONTAL_ALIGNMENT_CENTER, 236, 52, UiKit.INK)
	draw_string(UiKit.font("marker"), Vector2(-118, 40), "CHAOS!", HORIZONTAL_ALIGNMENT_CENTER, 236, 56, UiKit.RED)
	# ghost
	draw_set_transform(c + Vector2(92, 92) * k, deg_to_rad(10), Vector2(k, k))
	Icons.draw(self, "ghost", Vector2.ZERO, 150, UiKit.INK)
	draw_circle(Vector2(-30, 8), 7, Color(1, 0.5, 0.55, 0.45))
	draw_circle(Vector2(30, 8), 7, Color(1, 0.5, 0.55, 0.45))
	draw_arc(Vector2(0, 10), 10, 0.3, PI - 0.3, 10, UiKit.INK, 3.5, true)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _process(_d):
	frames += 1
	if frames == 8:
		get_viewport().get_texture().get_image().save_png("/tmp/claude-0/icon_%s.png" % mode)
		get_tree().quit()
