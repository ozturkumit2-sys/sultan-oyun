class_name WorldMapView
extends Control
## Interactive offline world map: pan by dragging, zoom with buttons/pinch/wheel, tap a market.
## Supported countries are real (simplified) shapes; offices and sales presence are highlighted.

signal country_tapped(code: String)

var tex: Texture2D
var zoom := 1.7
var center := Vector2(0.55, 0.36)
var selected := ""
var status: Dictionary = {}   # code -> {"office": int, "sells": bool, "rivals": int}
var _down := false
var _moved := false
var _last := Vector2.ZERO
var _start := Vector2.ZERO
var _touches: Dictionary = {}
var _pinch0 := 0.0
var _zoom0 := 1.0


func _ready() -> void:
	tex = load("res://assets/map/world.png")
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _map_size() -> Vector2:
	var tw := size.x * zoom
	return Vector2(tw, tw / (float(tex.get_width()) / float(tex.get_height())))


func _origin() -> Vector2:
	var ms := _map_size()
	return size * 0.5 - center * ms


func uv_to_px(uv: Vector2) -> Vector2:
	return _origin() + uv * _map_size()


func country_uv(code: String) -> Vector2:
	var ct := DB.country(code)
	var wm: Dictionary = DB.world_map
	return Vector2((float(ct["lon"]) + 180.0) / 360.0, (float(wm["lat_top"]) - float(ct["lat"])) / (float(wm["lat_top"]) - float(wm["lat_bot"])))


func _clamp_center() -> void:
	var ms := _map_size()
	var half := size * 0.5 / ms
	center.x = clampf(center.x, minf(half.x, 0.5), maxf(1.0 - half.x, 0.5))
	center.y = clampf(center.y, minf(half.y, 0.5), maxf(1.0 - half.y, 0.5))


func set_zoom(z: float) -> void:
	zoom = clampf(z, 1.0, 6.0)
	_clamp_center()
	queue_redraw()


func focus(code: String) -> void:
	center = country_uv(code)
	_clamp_center()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#100d13"), true)
	var ms := _map_size()
	var o := _origin()
	draw_texture_rect(tex, Rect2(o, ms), false)
	var polys: Dictionary = DB.world_map.get("countries", {})
	for code in polys:
		var st: Dictionary = status.get(code, {})
		var fill := Color(0.79, 0.65, 0.35, 0.10)
		if int(st.get("office", 0)) > 0:
			fill = Color(0.79, 0.65, 0.35, 0.5)
		elif st.get("sells", false):
			fill = Color(0.79, 0.65, 0.35, 0.28)
		if code == selected:
			fill = Color(0.95, 0.88, 0.7, 0.55)
		for poly in polys[code]:
			var pts := PackedVector2Array()
			for uv in poly:
				pts.append(o + Vector2(float(uv[0]), float(uv[1])) * ms)
			if pts.size() >= 3:
				if Geometry2D.triangulate_polygon(pts).size() > 0:
					draw_colored_polygon(pts, fill)
				var ol := pts.duplicate()
				ol.append(pts[0])
				draw_polyline(ol, Color(0.95, 0.85, 0.6, 0.9) if code == selected else Color(0.85, 0.7, 0.4, 0.7), 2.0 if code == selected else 1.2, true)
	var f := UI.font("bold")
	for ct in DB.countries:
		var code: String = ct["id"]
		var p := uv_to_px(country_uv(code))
		var st2: Dictionary = status.get(code, {})
		var off := int(st2.get("office", 0))
		var r := 11.0 + 3.0 * float(off)
		draw_circle(p, r + 3, Color(0, 0, 0, 0.55))
		draw_circle(p, r, UI.GOLD if off > 0 else (UI.GOLD2 if st2.get("sells", false) else Color("#6f665d")))
		if off > 0:
			draw_rect(Rect2(p - Vector2(5, 6), Vector2(10, 12)), UI.INK, true)
		var t := code
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_rect(Rect2(p + Vector2(-tw * 0.5 - 6, r + 4), Vector2(tw + 12, 24)), Color(0, 0, 0, 0.6), true)
		draw_string(f, p + Vector2(-tw * 0.5, r + 22), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UI.CREAM if code != selected else UI.GOLD2)


func _hit(pos: Vector2) -> String:
	var best := ""
	var bd := 46.0
	for ct in DB.countries:
		var d := uv_to_px(country_uv(ct["id"])).distance_to(pos)
		if d < bd:
			bd = d
			best = ct["id"]
	if best != "":
		return best
	var ms := _map_size()
	var o := _origin()
	var polys: Dictionary = DB.world_map.get("countries", {})
	for code in polys:
		for poly in polys[code]:
			var pts := PackedVector2Array()
			for uv in poly:
				pts.append(o + Vector2(float(uv[0]), float(uv[1])) * ms)
			if Geometry2D.is_point_in_polygon(pos, pts):
				return code
	return ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touches[t.index] = t.position
		else:
			_touches.erase(t.index)
		if _touches.size() == 2:
			var ps: Array = _touches.values()
			_pinch0 = (ps[0] as Vector2).distance_to(ps[1])
			_zoom0 = zoom
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_touches[d.index] = d.position
		if _touches.size() == 2 and _pinch0 > 0.0:
			var ps2: Array = _touches.values()
			set_zoom(_zoom0 * (ps2[0] as Vector2).distance_to(ps2[1]) / _pinch0)
			_moved = true
			accept_event()
	elif event is InputEventMagnifyGesture:
		set_zoom(zoom * (event as InputEventMagnifyGesture).factor)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_zoom(zoom * 1.15)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_zoom(zoom / 1.15)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_down = true
				_moved = false
				_last = mb.position
				_start = mb.position
			else:
				if _down and not _moved and _touches.size() <= 1:
					var code := _hit(mb.position)
					if code != "":
						selected = code
						queue_redraw()
						country_tapped.emit(code)
				_down = false
	elif event is InputEventMouseMotion and _down:
		var mm := event as InputEventMouseMotion
		if _touches.size() >= 2:
			return
		if mm.position.distance_to(_start) > 10.0:
			_moved = true
		center -= (mm.position - _last) / _map_size()
		_last = mm.position
		_clamp_center()
		queue_redraw()
		accept_event()
