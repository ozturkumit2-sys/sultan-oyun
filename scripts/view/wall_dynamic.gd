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
	draw_string(hand, Vector2(5, 12), "MEETING", HORIZONTAL_ALIGNMENT_LEFT, wd - 8, 9, Color("2b6cb0"))
	var mt_text := C.fmt(float(o["board"]["time"]))
	if w.meeting.get("ended", false):
		mt_text = "DONE!"
	elif w.meeting.get("started", false):
		mt_text = "NOW!"
	draw_string(hand, Vector2(8, 34), mt_text, HORIZONTAL_ALIGNMENT_LEFT, wd - 10, 17, Color("e63946") if o["board"].get("changed", false) else Color("2b2d42"))
	if o["board"].get("changed", false) and not w.meeting.get("ended", false):
		draw_line(Vector2(6, 38), Vector2(wd - 8, 36), Color(0.9, 0.2, 0.25, 0.6), 1.5)
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
	var total := w.minute + C.DAY_START_HOUR * 60.0
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
