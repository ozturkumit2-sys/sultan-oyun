class_name TouchControls
extends Control
## Çoklu dokunmatik kontroller: sol tarafta sanal joystick, sağ tarafta kamera döndürme,
## iki parmakla yakınlaştırma. Düğmelerin üstündeki dokunuşlar arayüz tarafından tüketilir.

var player: PlayerController
var base_radius := 105.0
var _joy_index := -1
var _joy_center := Vector2.ZERO
var _joy_vec := Vector2.ZERO
var _cam_touches := {}   # index -> pos
var _pinch_dist := 0.0
var _show_hint := true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_show_hint = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func _default_center() -> Vector2:
	var vs := get_viewport_rect().size
	return Vector2(190.0, vs.y - 185.0)


func reset() -> void:
	_joy_index = -1
	_joy_vec = Vector2.ZERO
	_cam_touches.clear()
	if player:
		player.move_input = Vector2.ZERO
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	var vs := get_viewport_rect().size
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _joy_index == -1 and t.position.x < vs.x * 0.42 and t.position.y > vs.y * 0.3:
				_joy_index = t.index
				var dc := _default_center()
				_joy_center = dc if t.position.distance_to(dc) < base_radius * 1.3 else t.position
				_update_joy(t.position)
				get_viewport().set_input_as_handled()
			else:
				_cam_touches[t.index] = t.position
				if _cam_touches.size() == 2:
					var ps: Array = _cam_touches.values()
					_pinch_dist = (ps[0] as Vector2).distance_to(ps[1])
		else:
			if t.index == _joy_index:
				_joy_index = -1
				_joy_vec = Vector2.ZERO
				player.move_input = Vector2.ZERO
				queue_redraw()
			_cam_touches.erase(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_index:
			_update_joy(d.position)
			get_viewport().set_input_as_handled()
		elif _cam_touches.has(d.index):
			_cam_touches[d.index] = d.position
			if _cam_touches.size() >= 2:
				var ps2: Array = _cam_touches.values()
				var nd := (ps2[0] as Vector2).distance_to(ps2[1])
				if _pinch_dist > 0.0:
					player.zoom((_pinch_dist - nd) * 0.02)
				_pinch_dist = nd
			else:
				player.rotate_camera(d.relative * 0.0055)


func _update_joy(pos: Vector2) -> void:
	var v := pos - _joy_center
	if v.length() > base_radius:
		v = v.normalized() * base_radius
	_joy_vec = v / base_radius
	player.move_input = _joy_vec
	queue_redraw()


func _process(_d: float) -> void:
	if _joy_index == -1 and _show_hint:
		queue_redraw()
		set_process(false)


func _draw() -> void:
	if not _show_hint and _joy_index == -1:
		return
	var c := _joy_center if _joy_index != -1 else _default_center()
	var alpha := 0.55 if _joy_index != -1 else 0.3
	draw_circle(c, base_radius, Color(0.05, 0.08, 0.18, alpha * 0.8))
	draw_arc(c, base_radius, 0, TAU, 48, Color(UI.GOLD, alpha + 0.15), 3.0, true)
	for k in range(8):
		var a := TAU * float(k) / 8.0
		draw_line(c + Vector2(cos(a), sin(a)) * (base_radius - 14), c + Vector2(cos(a), sin(a)) * (base_radius - 4), Color(UI.GOLD, alpha), 2.0)
	var kp := c + _joy_vec * base_radius
	draw_circle(kp, 42.0, Color(UI.EMERALD, alpha + 0.25))
	draw_arc(kp, 42.0, 0, TAU, 32, Color(UI.GOLD2, alpha + 0.3), 3.0, true)
