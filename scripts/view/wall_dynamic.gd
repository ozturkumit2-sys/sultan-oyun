class_name WallDynamic
extends Node2D
## Wall details that change: meeting board time, clock, AC display, breaker state.

var w: SimWorld
var _t := 0.0


func _ready() -> void:
	z_index = -19


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _decor(type: String) -> Dictionary:
	for d in OfficeLayout.wall_decor():
		if d["type"] == type:
			return d
	return {}


func _wall_xf(side: String, a: float, b: float, z_top: float) -> float:
	var along := a if side == "R" else b
	draw_set_transform_matrix(Iso.wall_xform(side, along, z_top, Vector2.ZERO))
	return (b - a) * Iso.WALL_UNIT


func _draw() -> void:
	if w == null:
		return
	var o := w.office.objects
	# --- meeting board
	var bd := _decor("board")
	var wd := _wall_xf(bd["side"], bd["a"], bd["b"], 88)
	var hand := UiKit.font("marker")
	draw_string(hand, Vector2(5, 12), Loc.t("wall.meeting"), HORIZONTAL_ALIGNMENT_LEFT, wd - 8, 9, Color("2b6cb0"))
	var mt_text := C.fmt(float(o["board"]["time"]))
	if w.meeting.get("ended", false):
		mt_text = Loc.t("wall.done")
	elif w.meeting.get("started", false):
		mt_text = Loc.t("wall.now")
	draw_string(hand, Vector2(8, 34), mt_text, HORIZONTAL_ALIGNMENT_LEFT, wd - 10, 17, Color("e63946") if o["board"].get("changed", false) else Color("2b2d42"))
	if o["board"].get("changed", false) and not w.meeting.get("ended", false):
		draw_line(Vector2(6, 38), Vector2(wd - 8, 36), Color(0.9, 0.2, 0.25, 0.6), 1.5)
	# what the ghost wrote on the board: a title, the agenda, a 'chair'
	var extra := ""
	if str(o["board"].get("title", "")) != "":
		extra = Loc.t("board.t." + str(o["board"]["title"]))
	elif str(o["board"].get("agenda", "")) != "":
		extra = Loc.t("wall.agenda", {"text": Loc.t("board.agenda." + str(o["board"]["agenda"]))})
	elif str(o["board"].get("chair", "")) != "" and w.npc(str(o["board"]["chair"])) != null:
		extra = Loc.t("wall.chair", {"name": Loc.upper(w.npc(str(o["board"]["chair"])).name)})
	if extra != "":
		draw_string(hand, Vector2(wd * 0.45, 12), extra, HORIZONTAL_ALIGNMENT_LEFT, wd * 0.55 - 4, 7, Color("e63946"))
	# --- fire alarm panel lamp
	var al := _decor("alarm")
	if not al.is_empty():
		_wall_xf(al["side"], al["a"], al["b"], 84)
		var ring: bool = o.get("alarm", {}).get("on", false)
		var lit := ring and fmod(_t, 0.5) < 0.25
		draw_circle(Vector2(8, 8), 3.4, Color("ff3b30") if lit else Color("7a1f1f"))
		if ring:
			for k in 2:
				draw_arc(Vector2(8, 8), 6.0 + k * 3.0 + fmod(_t * 10.0, 3.0), -0.9, 0.9, 6, Color(1, 0.3, 0.3, 0.7), 1.2)
				draw_arc(Vector2(8, 8), 6.0 + k * 3.0 + fmod(_t * 10.0, 3.0), PI - 0.9, PI + 0.9, 6, Color(1, 0.3, 0.3, 0.7), 1.2)
	# --- speaker: floating notes while music plays
	var sp := _decor("speaker")
	if not sp.is_empty():
		var wsp := _wall_xf(sp["side"], sp["a"], sp["b"], 88)
		if str(o.get("music", {}).get("genre", "")) != "":
			for k in 3:
				var ph := fmod(_t * 0.7 + k * 0.33, 1.0)
				var np := Vector2(wsp * 0.5 + sin(ph * 6.0 + k) * 6.0, 10.0 - ph * 26.0)
				var nc := Color(0.17, 0.18, 0.26, 1.0 - ph)
				draw_circle(np, 2.0, nc)
				draw_line(np + Vector2(1.8, 0), np + Vector2(1.8, -6), nc, 1.0)
	# --- notes pinned on the cork board (around the poster)
	var pins: Array = o.get("notice", {}).get("pins", [])
	if not pins.is_empty():
		var po := _decor("poster")
		var wp := _wall_xf(po["side"], po["a"], po["b"], 92)
		var cols := [Color("fff07a"), Color("ffb3c6"), Color("a8d8ff"), Color("b8f2a0"), Color("ffcf96"), Color("d9c8ff")]
		for i in mini(pins.size(), 6):
			var px := -6.0 + (i % 3) * (wp * 0.5 + 3.0)
			var py := 32.0 + (i / 3) * 9.0
			draw_rect(Rect2(px, py, 8, 7), cols[i % cols.size()])
			draw_circle(Vector2(px + 4, py + 1), 1.0, Color("e63946"))
	# --- AC unit display + airflow
	var ac := _decor("ac")
	var wa := _wall_xf(ac["side"], ac["a"], ac["b"], 100)
	var temp := int(o["ac"]["temp"])
	var led := Color("2b9bd8") if temp < 21 else (Color("e63946") if temp > 24 else Color("34c759"))
	draw_circle(Vector2(wa - 12, 10), 2.6, led)
	var flow := 0.4 + 0.6 * absf(sin(_t * 2.0))
	if temp != 22:
		for k in 3:
			var yy := 30.0 + k * 6.0 + fmod(_t * 14.0 + k * 5.0, 18.0)
			var col := Color(0.55, 0.8, 1.0, 0.5 * flow) if temp < 22 else Color(1.0, 0.55, 0.4, 0.5 * flow)
			draw_line(Vector2(10 + k * 12, yy), Vector2(22 + k * 12, yy + 2), col, 2.0, true)
	# thermostat digits
	var th := _decor("thermostat")
	_wall_xf(th["side"], th["a"], th["b"], 70)
	draw_rect(Rect2(2, 3, 7.5, 9), Color("1f3b2d"))
	draw_string(UiKit.font("slab"), Vector2(2.4, 10.5), str(temp), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, led.lightened(0.3))
	# --- clock (real game time)
	var ck := _decor("clock")
	var wc := _wall_xf(ck["side"], ck["a"], ck["b"], 92)
	var cc := Vector2(wc * 0.5, 15)
	draw_circle(cc, 13, Color("ffffff"))
	draw_arc(cc, 13, 0, TAU, 28, Iso.INK, 1.6, true)
	for k in 12:
		var aa := TAU * k / 12.0
		draw_line(cc + Vector2(cos(aa), sin(aa)) * 10.5, cc + Vector2(cos(aa), sin(aa)) * 12.0, Iso.INK, 1.0)
	var total := w.minute + float(o.get("clock", {}).get("offset", 0)) + C.DAY_START_HOUR * 60.0
	var hr := fmod(total / 60.0, 12.0)
	var mn := fmod(total, 60.0)
	var ah := TAU * hr / 12.0 - PI * 0.5
	var am := TAU * mn / 60.0 - PI * 0.5
	draw_line(cc, cc + Vector2(cos(ah), sin(ah)) * 6.5, Iso.INK, 2.0, true)
	draw_line(cc, cc + Vector2(cos(am), sin(am)) * 10.0, Color("e63946"), 1.3, true)
	draw_circle(cc, 1.4, Iso.INK)
	# --- breaker lever + lamp
	var br := _decor("breaker")
	_wall_xf(br["side"], br["a"], br["b"], 76)
	var on: bool = o["lights"]["on"]
	draw_rect(Rect2(8, 14, 6, 14), Color("4a4e5c"))
	draw_rect(Rect2(6, 14 if on else 22, 10, 6), Color("e63946") if not on else Color("e9ecef"))
	var blink := not on and fmod(_t, 0.8) < 0.4
	draw_circle(Vector2(19, 19), 2.2, Color("ff3b30") if blink else (Color("34c759") if on else Color("5a2020")))
	draw_set_transform_matrix(Transform2D())
