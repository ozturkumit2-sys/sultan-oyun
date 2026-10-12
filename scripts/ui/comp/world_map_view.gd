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


var _pill_sb: StyleBoxFlat
var _pill_sel: StyleBoxFlat


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#dcebef"), true)
	var ms := _map_size()
	var o := _origin()
	draw_texture_rect(tex, Rect2(o, ms), false)
	var polys: Dictionary = DB.world_map.get("countries", {})
	for code in polys:
		var st: Dictionary = status.get(code, {})
		var fill := Color(UI.GOLD, 0.16)
		if int(st.get("office", 0)) > 0:
			fill = Color(UI.BURGUNDY, 0.34)
		elif st.get("sells", false):
			fill = Color(UI.ROSE, 0.3)
		if code == selected:
			fill = fill.lerp(Color(UI.GOLD, 0.5), 0.5)
		for poly in polys[code]:
			var pts := PackedVector2Array()
			for uv in poly:
				pts.append(o + Vector2(float(uv[0]), float(uv[1])) * ms)
			if pts.size() >= 3:
				if Geometry2D.triangulate_polygon(pts).size() > 0:
					draw_colored_polygon(pts, fill)
				var ol := pts.duplicate()
				ol.append(pts[0])
				draw_polyline(ol, UI.BURGUNDY if code == selected else Color(UI.BURGUNDY, 0.45), 3.0 if code == selected else 1.4, true)
	# expansion routes from the home market to every office
	var home: String = G.pc().get("home", "") if G.has_game() else ""
	if home != "":
		var hp := uv_to_px(country_uv(home))
		for ct in DB.countries:
			var code2: String = ct["id"]
			if code2 == home or int(status.get(code2, {}).get("office", 0)) <= 0:
				continue
			_route(hp, uv_to_px(country_uv(code2)))
	if _pill_sb == null:
		_pill_sb = UI.shadowed(UI.sb(Color(1, 0.995, 0.985, 0.95), 999, Color(UI.BURGUNDY, 0.25), 1, 0), 6)
		_pill_sel = UI.shadowed(UI.sb(UI.BURGUNDY, 999, Color(1, 1, 1, 0.9), 2, 0), 6)
	var f := UI.font("semi")
	for ct in DB.countries:
		var code: String = ct["id"]
		var p := uv_to_px(country_uv(code))
		var st2: Dictionary = status.get(code, {})
		var off := int(st2.get("office", 0))
		var sells: bool = st2.get("sells", false)
		if off > 0:
			_pin(p, 15.0 + 2.0 * float(off), UI.BURGUNDY, code == home, off)
		elif sells:
			_pin(p, 13.0, UI.ROSE, false, 0)
		else:
			draw_circle(p, 9, Color(1, 1, 1, 0.9))
			draw_circle(p, 6, Color("#a8958a"))
		var t: String = ct["name"] if zoom >= 4.0 else code
		var fs := 17
		var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var r := Rect2(p + Vector2(-tw * 0.5 - 10, 10), Vector2(tw + 20, 28))
		draw_style_box(_pill_sel if code == selected else _pill_sb, r)
		draw_string(f, r.position + Vector2(10, 20), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if code == selected else UI.BURGUNDY)


## Map pin: a teardrop with a small building glyph (offices) or a dot (sales only).
func _pin(p: Vector2, r: float, col: Color, hq: bool, level: int) -> void:
	var tip := p + Vector2(0, 2)
	var c := p - Vector2(0, r * 1.5)
	draw_circle(tip + Vector2(0, 2), r * 0.45, Color(0, 0, 0, 0.12))
	var pts := PackedVector2Array()
	for i in 25:
		var a := PI * 0.8 + (TAU - PI * 0.6) * float(i) / 24.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	pts.append(tip)
	draw_colored_polygon(pts, col)
	var ol := pts.duplicate()
	ol.append(pts[0])
	draw_polyline(ol, Color(1, 1, 1, 0.95), 2.5, true)
	if level > 0:
		var w := r * 0.9
		draw_rect(Rect2(c + Vector2(-w * 0.5, -w * 0.15), Vector2(w, w * 0.62)), Color.WHITE, true)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.62, -w * 0.12), c + Vector2(0, -w * 0.62), c + Vector2(w * 0.62, -w * 0.12)]), Color.WHITE)
		draw_rect(Rect2(c + Vector2(-w * 0.12, w * 0.12), Vector2(w * 0.24, w * 0.35)), col, true)
	else:
		draw_circle(c, r * 0.38, Color.WHITE)
	if hq:
		var sc := c + Vector2(r * 0.95, -r * 0.95)
		draw_circle(sc, r * 0.55, UI.GOLD)
		draw_circle(sc, r * 0.32, Color("#fff6dc"))


## Dashed flight path between two markets.
func _route(a: Vector2, b: Vector2) -> void:
	var mid := (a + b) * 0.5 + Vector2(0, -minf(160.0, a.distance_to(b) * 0.28))
	var prev := a
	var n := 40
	for i in range(1, n + 1):
		var t := float(i) / float(n)
		var q := a.lerp(mid, t).lerp(mid.lerp(b, t), t)
		if i % 2 == 0:
			draw_line(prev, q, Color(UI.BURGUNDY, 0.65), 3.0, true)
		prev = q


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
