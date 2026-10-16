class_name NoteButton
extends BaseButton
## A stationery button: sticky note, index card, round key or paper tab.

var text := ""
var sub := ""
var icon := ""
var kind := "sticky"          # sticky, card, round, tab, row
var col := Color("fff07a")
var tilt := 0.0               # degrees
var font_size := 24
var font_kind := "hand"
var badge := 0
var tag := ""                 # small pill in the corner of a row ("NEW")
var active := false
var text_col := UiKit.INK
var _press_k := 0.0


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	pressed.connect(func(): Audio.play("click", -4.0, randf_range(0.95, 1.08)))


static func make(t: String, ic := "", k := "sticky", c := Color("fff07a"), min_size := Vector2(140, 64)) -> NoteButton:
	var b := NoteButton.new()
	b.text = t
	b.icon = ic
	b.kind = k
	b.col = c
	b.custom_minimum_size = min_size
	return b


func _process(delta: float) -> void:
	var goal := 1.0 if (is_pressed() and is_hovered()) or button_pressed else 0.0
	if kind == "round" and active:
		goal = 1.0
	var nk := move_toward(_press_k, goal, delta * 12.0)
	if nk != _press_k:
		_press_k = nk
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var c := r.size * 0.5
	var dis := disabled
	var fill := col
	if dis:
		fill = fill.lerp(Color("d8d4cc"), 0.6)
	var press := Vector2(0, 2.5 * _press_k)
	draw_set_transform(c + press, deg_to_rad(tilt), Vector2.ONE)
	var rr := Rect2(-c, r.size)
	match kind:
		"sticky":
			UiKit.draw_note(self, rr.grow(-2), fill, _press_k < 0.5, true)
		"card":
			draw_rect(Rect2(rr.position + Vector2(3, 5), rr.size), Color(0, 0, 0, 0.16 * (1.0 - _press_k)))
			draw_rect(rr, fill)
			draw_line(rr.position + Vector2(0, 14), Vector2(rr.end.x, rr.position.y + 14), Color(0.9, 0.35, 0.4, 0.45), 1.2)
			draw_rect(rr, UiKit.INK_SOFT, false, 1.2)
		"round":
			var rad := minf(rr.size.x, rr.size.y) * 0.5 - 2
			draw_circle(Vector2(1.5, 4.0 - 2.5 * _press_k), rad, Color(0, 0, 0, 0.2))
			draw_circle(Vector2.ZERO, rad, fill.darkened(0.15) if active else fill)
			draw_arc(Vector2.ZERO, rad, 0, TAU, 28, UiKit.INK, 2.0, true)
			if active:
				draw_arc(Vector2.ZERO, rad - 4, 0, TAU, 28, Color(1, 1, 1, 0.6), 2.0, true)
		"tab":
			var p := PackedVector2Array([rr.position + Vector2(8, 0), Vector2(rr.end.x - 8, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y)])
			draw_colored_polygon(p, fill)
			draw_polyline(p + PackedVector2Array([p[0]]), UiKit.INK_SOFT, 1.2, true)
		"row":
			draw_rect(Rect2(rr.position + Vector2(2, 4), rr.size), Color(0, 0, 0, 0.1 * (1.0 - _press_k)))
			draw_rect(rr, fill)
			draw_rect(rr, UiKit.INK_SOFT, false, 1.0)
	var tc := text_col if not dis else Color(0.4, 0.4, 0.45)
	var font := UiKit.font(font_kind)
	if kind == "round":
		if icon != "":
			Icons.draw(self, icon, Vector2.ZERO, minf(rr.size.x, rr.size.y) * 0.62, tc)
	elif kind == "row":
		var x0 := -c.x + 14.0
		if icon != "":
			draw_circle(Vector2(x0 + 22, 0), 22, Color(1, 1, 1, 0.7))
			Icons.draw(self, icon, Vector2(x0 + 22, 0), 34, tc)
			x0 += 54.0
		var tw := rr.size.x - (x0 + c.x) - 12.0
		var fs := UiKit.fit_size(font, text, tw, font_size)
		if sub != "":
			draw_string(font, Vector2(x0, -6), text, HORIZONTAL_ALIGNMENT_LEFT, tw, fs, tc)
			draw_multiline_string(UiKit.font("hand"), Vector2(x0, 18), sub, HORIZONTAL_ALIGNMENT_LEFT, tw, 18, 2, Color(tc.r, tc.g, tc.b, 0.75))
		else:
			draw_string(font, Vector2(x0, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, tw, fs, tc)
	else:
		var ty := font_size * 0.35
		if icon != "":
			var isz := minf(rr.size.y * 0.5, 34.0)
			if text != "":
				Icons.draw(self, icon, Vector2(0, -rr.size.y * 0.16), isz, tc)
				ty = rr.size.y * 0.28
			else:
				Icons.draw(self, icon, Vector2.ZERO, isz, tc)
		if text != "":
			var avail := rr.size.x - 12.0
			var fs2 := UiKit.fit_size(font, text, avail, font_size, 0.72)
			if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x > avail and (text.find(" ") > 0 or Loc.is_cjk()):
				# too long for one line even when smaller: two lines
				var fs3 := int(font_size * 0.8)
				var lh := fs3 + 2.0
				draw_multiline_string(font, Vector2(-c.x + 6, ty - lh * 0.5), text, HORIZONTAL_ALIGNMENT_CENTER, avail, fs3, 2, tc)
			else:
				draw_string(font, Vector2(-c.x + 6, ty), text, HORIZONTAL_ALIGNMENT_CENTER, avail, fs2, tc)
	if tag != "" and kind == "row":
		var tf := UiKit.font("slab")
		var tw2 := tf.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 14.0
		var tp := Vector2(c.x - tw2 - 8, -c.y + 6)
		draw_rect(Rect2(tp, Vector2(tw2, 20)), UiKit.RED)
		draw_string(tf, tp + Vector2(7, 15), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	if badge > 0:
		var bp := Vector2(c.x - 10, -c.y + 8)
		draw_circle(bp, 13, UiKit.RED)
		draw_string(UiKit.font("slab"), bp + Vector2(-12, 6), str(mini(badge, 99)), HORIZONTAL_ALIGNMENT_CENTER, 24, 15, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
