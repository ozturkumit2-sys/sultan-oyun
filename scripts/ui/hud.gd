class_name Hud
extends Control
## In-game HUD: desk calendar (day), clock card, office-mood sticky note, settings,
## and the bottom desk strip with Gossip Board / Staff / Today notes and time keys.

signal open_log
signal open_staff
signal open_today
signal open_settings
signal speed_changed(v: float)
signal toast_tapped(entry: Dictionary)
signal fit_pressed
signal open_journal

const PAD_TOP := 30.0
const BOTTOM_H := 150.0

var w: SimWorld
var top: Control
var bottom: Control
var btn_log: NoteButton
var btn_staff: NoteButton
var btn_today: NoteButton
var keys: Array = []
var btn_settings: NoteButton
var btn_fit: NoteButton
var btn_journal: NoteButton
var new_finds := 0
var toasts: Array = []          # {entry, node, life}
var toast_box: Control
var unread := 0
var tip: Control
var tip_life := 0.0
var _t := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func build(world: SimWorld) -> void:
	w = world
	top = Control.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size = Vector2(0, 130)
	top.draw.connect(_draw_top)
	add_child(top)
	var cal_btn := _invisible_button(Rect2(10, PAD_TOP, 100, 104))
	cal_btn.pressed.connect(func(): open_today.emit())
	top.add_child(cal_btn)
	var mood_btn := _invisible_button(Rect2(350, PAD_TOP, 266, 100))
	mood_btn.pressed.connect(func(): open_staff.emit())
	top.add_child(mood_btn)
	btn_settings = NoteButton.make("", "gear", "round", Color("fffdf5"), Vector2(66, 66))
	btn_settings.position = Vector2(638, PAD_TOP + 18)
	btn_settings.pressed.connect(func(): open_settings.emit())
	top.add_child(btn_settings)
	# bottom strip
	bottom = Control.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom.anchor_left = 0
	bottom.anchor_right = 1
	bottom.anchor_top = 1
	bottom.anchor_bottom = 1
	bottom.offset_top = -BOTTOM_H
	bottom.draw.connect(_draw_bottom)
	add_child(bottom)
	btn_log = _note(Loc.t("ui.log"), "pin", UiKit.sticky("pink"), Vector2(14, 24), -3.0)
	btn_log.pressed.connect(func():
		unread = 0
		btn_log.badge = 0
		btn_log.queue_redraw()
		open_log.emit())
	btn_staff = _note(Loc.t("ui.staff"), "people", UiKit.sticky("blue"), Vector2(168, 22), 2.0)
	btn_staff.pressed.connect(func(): open_staff.emit())
	btn_today = _note(Loc.t("ui.report"), "newspaper", UiKit.sticky("yellow"), Vector2(322, 24), -2.0)
	btn_today.pressed.connect(func(): open_today.emit())
	var icons := ["pause", "play", "fast"]
	var vals := [0.0, 1.0, 2.0]
	for i in 3:
		var k := NoteButton.make("", icons[i], "round", Color("f4f1ea"), Vector2(64, 64))
		k.position = Vector2(484 + i * 76, 44)
		var v: float = vals[i]
		k.pressed.connect(func(): speed_changed.emit(v))
		bottom.add_child(k)
		keys.append(k)
	set_speed_ui(Game.speed)
	btn_fit = NoteButton.make("", "zoom", "round", Color("fffdf5"), Vector2(58, 58))
	btn_fit.anchor_left = 1
	btn_fit.anchor_right = 1
	btn_fit.anchor_top = 1
	btn_fit.anchor_bottom = 1
	btn_fit.offset_left = -76
	btn_fit.offset_right = -18
	btn_fit.offset_top = -BOTTOM_H - 72
	btn_fit.offset_bottom = -BOTTOM_H - 14
	btn_fit.pressed.connect(func(): fit_pressed.emit())
	add_child(btn_fit)
	# the Discovery Journal: bottom-left, mirroring the zoom key
	btn_journal = NoteButton.make("", "book", "round", Color("e9dcb4"), Vector2(62, 62))
	btn_journal.anchor_top = 1
	btn_journal.anchor_bottom = 1
	btn_journal.offset_left = 16
	btn_journal.offset_right = 78
	btn_journal.offset_top = -BOTTOM_H - 76
	btn_journal.offset_bottom = -BOTTOM_H - 14
	btn_journal.pressed.connect(func():
		new_finds = 0
		btn_journal.badge = 0
		btn_journal.queue_redraw()
		open_journal.emit())
	add_child(btn_journal)
	w.discovery.found.connect(_on_found)
	toast_box = Control.new()
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(toast_box)
	w.logged.connect(_on_logged)


func _invisible_button(r: Rect2) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	b.modulate = Color(1, 1, 1, 0)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(func(): Audio.play("click", -4.0))
	return b


func _note(t: String, ic: String, c: Color, p: Vector2, tilt: float) -> NoteButton:
	var b := NoteButton.make(t, ic, "sticky", c, Vector2(146, 104))
	b.position = p
	b.tilt = tilt
	b.font_size = 24
	bottom.add_child(b)
	return b


func set_speed_ui(v: float) -> void:
	for i in keys.size():
		keys[i].active = absf([0.0, 1.0, 2.0][i] - v) < 0.01
		keys[i].queue_redraw()


func show_tip(text: String, secs := 14.0) -> void:
	if tip:
		tip.queue_free()
	tip = Control.new()
	tip.mouse_filter = Control.MOUSE_FILTER_STOP
	var vs := get_viewport_rect().size
	tip.position = Vector2(40, vs.y - BOTTOM_H - 150)
	tip.size = Vector2(vs.x - 150, 96)
	tip.set_meta("text", text)
	tip.draw.connect(func():
		var r := Rect2(Vector2.ZERO, tip.size)
		UiKit.draw_note(tip, r, UiKit.sticky("green"))
		UiKit.draw_tape(tip, Vector2(r.size.x * 0.5, 2), Vector2(70, 18), 0.05)
		Icons.draw(tip, "ghost", Vector2(38, 48), 48)
		tip.draw_multiline_string(UiKit.font("hand"), Vector2(70, 40), tip.get_meta("text"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 84, 22, 3, UiKit.INK))
	tip.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			tip_life = 0.0)
	add_child(tip)
	tip_life = secs


func _on_logged(e: Dictionary) -> void:
	if e.get("cat", "") == "player":
		return
	if int(e.get("imp", 1)) >= 2:
		unread += 1
		btn_log.badge = unread
		btn_log.queue_redraw()
	if int(e.get("imp", 1)) >= 3:
		_toast(e)


func _toast(e: Dictionary) -> void:
	var n := Control.new()
	n.mouse_filter = Control.MOUSE_FILTER_STOP
	var vs := get_viewport_rect().size
	n.size = Vector2(420, 80)
	n.position = Vector2(vs.x + 10, PAD_TOP + 120)
	var cat: String = e.get("cat", "misc")
	var colr := UiKit.sticky(UiKit.CAT_COLOR.get(cat, "yellow"))
	var text: String = e.get("text", "")
	n.draw.connect(func():
		var r := Rect2(Vector2.ZERO, n.size)
		UiKit.draw_note(n, r, colr)
		UiKit.draw_pin(n, Vector2(22, 14), UiKit.RED)
		n.draw_string(UiKit.font("type"), Vector2(38, 20), C.fmt(e.get("minute", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.3, 0.3, 0.35))
		n.draw_multiline_string(UiKit.font("hand"), Vector2(14, 44), text, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 26, 20, 2, UiKit.INK))
	n.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			toast_tapped.emit(e)
			for tt in toasts:
				if tt["node"] == n:
					tt["life"] = 0.0)
	toast_box.add_child(n)
	toasts.append({"entry": e, "node": n, "life": 4.8})
	while toasts.size() > 3:
		var old: Dictionary = toasts.pop_front()
		old["node"].queue_free()
	Audio.play("pop", -6.0)


func _process(delta: float) -> void:
	_t += delta
	top.queue_redraw()
	var vs := get_viewport_rect().size
	var y := PAD_TOP + 122.0
	for i in range(toasts.size() - 1, -1, -1):
		var tt: Dictionary = toasts[i]
		tt["life"] -= delta
		var n: Control = tt["node"]
		if tt["life"] <= 0.0:
			n.position.x = lerpf(n.position.x, vs.x + 30, minf(1.0, delta * 10))
			if n.position.x > vs.x:
				n.queue_free()
				toasts.remove_at(i)
	for tt in toasts:
		var n2: Control = tt["node"]
		if tt["life"] > 0.0:
			n2.position.x = lerpf(n2.position.x, vs.x - n2.size.x - 12, minf(1.0, delta * 12))
		n2.position.y = lerpf(n2.position.y, y, minf(1.0, delta * 12))
		y += n2.size.y + 8
	if tip:
		tip_life -= delta
		if tip_life <= 0.0:
			tip.modulate.a -= delta * 3.0
			if tip.modulate.a <= 0.0:
				tip.queue_free()
				tip = null


# ------------------------------------------------------------------ drawing

func _draw_top() -> void:
	if w == null:
		return
	var p := PAD_TOP
	# --- desk calendar (day)
	top.draw_set_transform(Vector2(60, p + 52), deg_to_rad(-3), Vector2.ONE)
	var cr := Rect2(-46, -48, 92, 98)
	top.draw_rect(Rect2(cr.position + Vector2(3, 5), cr.size), Color(0, 0, 0, 0.2))
	top.draw_rect(cr, UiKit.PAPER)
	top.draw_rect(Rect2(cr.position, Vector2(cr.size.x, 30)), UiKit.RED)
	for k in 4:
		top.draw_circle(Vector2(-33 + k * 22, -48), 3.5, Color("8d99ae"))
	top.draw_string(UiKit.font("slab"), Vector2(-46, -25), "DAY", HORIZONTAL_ALIGNMENT_CENTER, 92, 18, Color.WHITE)
	top.draw_string(UiKit.font("slab"), Vector2(-46, 36), str(w.day), HORIZONTAL_ALIGNMENT_CENTER, 92, 46 if w.day < 100 else 34, UiKit.INK)
	top.draw_rect(cr, UiKit.INK_SOFT, false, 1.2)
	# --- clock card
	top.draw_set_transform(Vector2(228, p + 50), deg_to_rad(1.5), Vector2.ONE)
	var kr := Rect2(-108, -42, 216, 86)
	top.draw_rect(Rect2(kr.position + Vector2(3, 5), kr.size), Color(0, 0, 0, 0.18))
	top.draw_rect(kr, Color("fffdf5"))
	top.draw_line(Vector2(-108, -24), Vector2(108, -24), Color(0.9, 0.35, 0.4, 0.45), 1.2)
	top.draw_string(UiKit.font("type"), Vector2(-108, 20), C.fmt(w.minute), HORIZONTAL_ALIGNMENT_CENTER, 216, 40, UiKit.INK)
	var status := ""
	if Game.speed == 0.0:
		status = Loc.t("ui.paused")
	elif Game.speed > 1.5:
		status = "FAST x2"
	top.draw_string(UiKit.font("hand"), Vector2(-100, -29), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.RED)
	# day progress line with a little sun
	var frac := clampf(w.minute / C.DAY_LEN, 0.0, 1.0)
	top.draw_line(Vector2(-88, 32), Vector2(88, 32), Color(0.3, 0.3, 0.35, 0.4), 2.0)
	var sp := Vector2(-88 + 176 * frac, 32)
	top.draw_circle(sp, 6, Color("f6c85f"))
	for k in 8:
		var a := TAU * k / 8.0 + _t
		top.draw_line(sp + Vector2(cos(a), sin(a)) * 8, sp + Vector2(cos(a), sin(a)) * 11, Color("f6a85f"), 1.4)
	top.draw_string(UiKit.font("hand"), Vector2(-106, 38), "9", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.3, 0.35))
	top.draw_string(UiKit.font("hand"), Vector2(92, 38), "18", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.3, 0.35))
	top.draw_rect(kr, UiKit.INK_SOFT, false, 1.2)
	# --- office mood sticky
	top.draw_set_transform(Vector2(483, p + 50), deg_to_rad(-1.5), Vector2.ONE)
	var mr := Rect2(-130, -46, 260, 92)
	var m := w.office_mood()
	var mood_col := UiKit.sticky("green") if m > 25 else (UiKit.sticky("yellow") if m > 0 else (UiKit.sticky("orange") if m > -25 else UiKit.sticky("pink")))
	UiKit.draw_note(top, mr, mood_col)
	UiKit.draw_tape(top, Vector2(0, -46), Vector2(60, 16), 0.04)
	_mood_face(top, Vector2(-88, 2), 30, m)
	top.draw_string(UiKit.font("hand"), Vector2(-48, -16), Loc.t("ui.office_mood"), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.25, 0.25, 0.3))
	top.draw_string(UiKit.font("marker"), Vector2(-48, 16), Loc.t(_office_word(m)), HORIZONTAL_ALIGNMENT_LEFT, 170, 24, UiKit.INK)
	UiKit.draw_scribble_bar(top, Rect2(-48, 24, 160, 10), (m + 100.0) / 200.0, Color("2a9d8f") if m > 0 else UiKit.RED)
	top.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


static func _office_word(m: float) -> String:
	if m > 35: return "office.great"
	if m > 12: return "office.good"
	if m > -8: return "office.ok"
	if m > -30: return "office.tense"
	return "office.bad"


static func _mood_face(ci: CanvasItem, c: Vector2, r: float, m: float) -> void:
	ci.draw_circle(c, r, Color("ffd166"))
	ci.draw_arc(c, r, 0, TAU, 28, UiKit.INK, 2.0, true)
	var ey := c.y - r * 0.2
	if m < -30:
		ci.draw_line(Vector2(c.x - r * 0.5, ey - 5), Vector2(c.x - r * 0.15, ey), UiKit.INK, 2.5, true)
		ci.draw_line(Vector2(c.x + r * 0.5, ey - 5), Vector2(c.x + r * 0.15, ey), UiKit.INK, 2.5, true)
	ci.draw_circle(Vector2(c.x - r * 0.33, ey + 2), r * 0.1, UiKit.INK)
	ci.draw_circle(Vector2(c.x + r * 0.33, ey + 2), r * 0.1, UiKit.INK)
	var my := c.y + r * 0.35
	if m > 12:
		ci.draw_arc(Vector2(c.x, my - r * 0.2), r * 0.42, 0.2, PI - 0.2, 12, UiKit.INK, 2.5, true)
	elif m > -8:
		ci.draw_line(Vector2(c.x - r * 0.3, my), Vector2(c.x + r * 0.3, my), UiKit.INK, 2.5, true)
	else:
		ci.draw_arc(Vector2(c.x, my + r * 0.25), r * 0.38, PI + 0.3, TAU - 0.3, 12, UiKit.INK, 2.5, true)


func _draw_bottom() -> void:
	var r := Rect2(Vector2.ZERO, bottom.size)
	# kraft paper desk strip with a torn top edge
	var pts := PackedVector2Array()
	var x := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	while x < r.size.x:
		pts.append(Vector2(x, 10 + rng.randf_range(-4, 4)))
		x += 14
	pts.append(Vector2(r.size.x, 10))
	pts.append(Vector2(r.size.x, r.size.y))
	pts.append(Vector2(0, r.size.y))
	var shadow := pts.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(0, -4)
	bottom.draw_colored_polygon(shadow, Color(0, 0, 0, 0.12))
	bottom.draw_colored_polygon(pts, UiKit.KRAFT)
	for k in 30:
		bottom.draw_circle(Vector2(rng.randf() * r.size.x, rng.randf_range(20, r.size.y)), rng.randf_range(0.6, 1.4), Color(0.5, 0.35, 0.15, 0.25))
	# slot behind the time keys (tape-recorder strip)
	Iso.rrect(bottom, Rect2(470, 34, 236, 84), 16, Color("3d4250"), Color(0, 0, 0, 0.4))


## Something new for the journal: a sparkle and a badge on the notebook.
func _on_found(kind: String, _id: String) -> void:
	new_finds += 1
	btn_journal.badge = new_finds
	btn_journal.queue_redraw()
	if kind == "iv" or kind == "arc":
		Audio.play("sparkle", -6.0)
