extends Control
## On-screen controls: floating joystick (left), jump + pounce medallions (right),
## free swipe on the right side orbits the camera. Multi-touch aware.

var joy_finger := -1
var joy_center := Vector2.ZERO
var joy_pos := Vector2.ZERO
var look_finger := -1
var look_last := Vector2.ZERO
var btn_fingers := {}   # finger -> action
var joy_radius := 95.0
var pressed_vis := {"jump": 0.0, "dash": 0.0}
var show_always := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or show_always


func _vp() -> Vector2:
	return get_viewport_rect().size


func _jump_rect() -> Dictionary:
	var s := _vp()
	var r: float = clamp(s.y * 0.115, 62.0, 96.0)
	return {"c": Vector2(s.x - r * 1.45, s.y - r * 1.45), "r": r}


func _dash_rect() -> Dictionary:
	var j := _jump_rect()
	var r: float = j["r"] * 0.72
	return {"c": j["c"] + Vector2(-j["r"] * 2.05, j["r"] * 0.35), "r": r}


func _hit(action: String, p: Vector2) -> bool:
	var d := _jump_rect() if action == "jump" else _dash_rect()
	return p.distance_to(d["c"]) <= d["r"] * 1.25


func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			if _hit("jump", p):
				btn_fingers[event.index] = "jump"
				Input.action_press("jump")
				pressed_vis["jump"] = 1.0
			elif _hit("dash", p):
				btn_fingers[event.index] = "dash"
				Input.action_press("dash")
				pressed_vis["dash"] = 1.0
			elif p.x < _vp().x * 0.45 and p.y > _vp().y * 0.18 and joy_finger == -1:
				joy_finger = event.index
				joy_center = p
				joy_pos = p
			elif look_finger == -1 and p.y > _vp().y * 0.14:
				look_finger = event.index
				look_last = p
		else:
			if btn_fingers.has(event.index):
				Input.action_release(btn_fingers[event.index])
				btn_fingers.erase(event.index)
			if event.index == joy_finger:
				joy_finger = -1
				GameState.touch_move = Vector2.ZERO
			if event.index == look_finger:
				look_finger = -1
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == joy_finger:
			joy_pos = event.position
			var d: Vector2 = joy_pos - joy_center
			if d.length() > joy_radius:
				# drag the base along (floating stick)
				joy_center = joy_pos - d.normalized() * joy_radius
				d = joy_pos - joy_center
			var v := d / joy_radius
			if v.length() < 0.12:
				v = Vector2.ZERO
			GameState.touch_move = v
			queue_redraw()
		elif event.index == look_finger:
			GameState.touch_look += event.position - look_last
			look_last = event.position


func _process(delta: float) -> void:
	if not visible:
		return
	for k in pressed_vis.keys():
		pressed_vis[k] = max(0.0, pressed_vis[k] - delta * 5.0)
	queue_redraw()


func release_all() -> void:
	for f in btn_fingers.keys():
		Input.action_release(btn_fingers[f])
	btn_fingers.clear()
	joy_finger = -1
	look_finger = -1
	GameState.touch_move = Vector2.ZERO


func _draw() -> void:
	# joystick
	var base_c := joy_center if joy_finger != -1 else Vector2(_vp().x * 0.13, _vp().y * 0.74)
	var knob := joy_pos if joy_finger != -1 else base_c
	var a := 0.85 if joy_finger != -1 else 0.45
	draw_circle(base_c, joy_radius + 6, Color(UIKit.NAVY, 0.25 * a))
	draw_circle(base_c, joy_radius, Color(UIKit.CREAM, 0.16 * a))
	draw_arc(base_c, joy_radius, 0, TAU, 48, Color(UIKit.COBALT, 0.8 * a), 5.0, true)
	for i in 8:  # tile-like ornament dots
		var ang := TAU * i / 8.0
		draw_circle(base_c + Vector2(cos(ang), sin(ang)) * (joy_radius - 16), 4.0, Color(UIKit.TURQ, 0.7 * a))
	draw_circle(knob, 44, Color(UIKit.NAVY, 0.3 * a))
	draw_circle(knob, 40, Color(UIKit.CREAM, 0.95 * a))
	draw_arc(knob, 40, 0, TAU, 32, Color(UIKit.COBALT, a), 5.0, true)
	draw_circle(knob, 14, Color(UIKit.TURQ, a))
	# buttons
	_draw_medallion(_jump_rect(), UIKit.COBALT, "jump")
	_draw_medallion(_dash_rect(), UIKit.CORAL, "dash")


func _draw_medallion(d: Dictionary, col: Color, action: String) -> void:
	var c: Vector2 = d["c"]
	var r: float = d["r"]
	var pv: float = pressed_vis[action]
	var held := Input.is_action_pressed(action)
	var s := 0.92 if held else 1.0
	r *= s
	draw_circle(c + Vector2(0, 6), r, Color(UIKit.NAVY, 0.35))
	draw_circle(c, r, Color(col, 0.82))
	draw_arc(c, r - 3, 0, TAU, 48, Color(UIKit.CREAM, 0.9), 5.0, true)
	draw_arc(c, r * 0.78, 0, TAU, 48, Color(UIKit.CREAM, 0.35), 2.0, true)
	for i in 12:
		var ang := TAU * i / 12.0
		draw_circle(c + Vector2(cos(ang), sin(ang)) * r * 0.89, r * 0.035, Color(UIKit.CREAM, 0.6))
	if action == "jump":
		UIKit.draw_paw(self, c + Vector2(0, r * 0.05), r * 0.75, UIKit.CREAM, Color(UIKit.NAVY, 0.0))
	else:
		# pounce: double chevron
		for k in 2:
			var o := Vector2(-r * 0.18 + k * r * 0.3, 0)
			var pts := PackedVector2Array([c + o + Vector2(-r * 0.18, -r * 0.32), c + o + Vector2(r * 0.14, 0), c + o + Vector2(-r * 0.18, r * 0.32)])
			draw_polyline(pts, UIKit.CREAM, r * 0.13, true)
	if pv > 0.0:
		draw_arc(c, r + 10 * (1.0 - pv), 0, TAU, 48, Color(UIKit.CREAM, pv), 4.0, true)
