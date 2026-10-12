class_name OfficeView
extends Node2D
## Builds and renders the isometric office from the simulation; handles the
## camera (drag to pan, pinch / wheel to zoom) and tap hit-testing.

signal tapped_npc(id: String)
signal tapped_hotspot(id: String)
signal tapped_item(item: String)
signal tapped_empty

var w: SimWorld
var sorter: Node2D
var backdrop: OfficeBackdrop
var walls: WallDynamic
var fx: FxLayer
var hints: HintLayer
var cam: Camera2D
var modulate_node: CanvasModulate
var highlight: Node2D
var chars: Dictionary = {}       # id -> CharacterView
var items: Dictionary = {}       # item -> ItemView
var furn: Array = []             # FurnitureView list (redraw on change)
var lights: Array = []
var hotspots: Array = []         # {id, poly: PackedVector2Array, anchor: Vector2}
var selected_hotspot := ""
var interactive := true
var ui_block: Callable          # (screen_pos) -> bool : true when the point is covered by HUD
var _touches := {}
var _tap_start := Vector2.ZERO
var _tap_time := 0.0
var _moved := false
var _pinch_d := 0.0
var _vel := Vector2.ZERO
var _focus_target = null
var _dark_k := 0.0
var _t := 0.0


func build(world: SimWorld) -> void:
	w = world
	var desk := DeskSurface.new()
	add_child(desk)
	backdrop = OfficeBackdrop.new()
	add_child(backdrop)
	walls = WallDynamic.new()
	walls.w = w
	add_child(walls)
	sorter = Node2D.new()
	sorter.y_sort_enabled = true
	add_child(sorter)
	for f in OfficeLayout.furniture():
		var fv := FurnitureView.new()
		var two_part: bool = f["type"] in ["chair", "office_chair", "armchair"] and f.get("facing", "SE") in ["NW", "NE"]
		fv.setup(f, w, "seat" if two_part else "")
		sorter.add_child(fv)
		furn.append(fv)
		if two_part:
			var fb := FurnitureView.new()
			fb.setup(f, w, "back")
			sorter.add_child(fb)
	for p in OfficeLayout.partitions():
		var pv := PartitionView.new()
		pv.setup(p)
		sorter.add_child(pv)
	for it in w.office.items:
		var iv := ItemView.new()
		iv.setup(it, w)
		sorter.add_child(iv)
		items[it] = iv
	for id in w.order:
		var cv := CharacterView.new()
		cv.setup(w.npc(id), w)
		sorter.add_child(cv)
		chars[id] = cv
	fx = FxLayer.new()
	fx.w = w
	add_child(fx)
	highlight = Node2D.new()
	highlight.z_index = 44
	highlight.draw.connect(_draw_highlight)
	add_child(highlight)
	hints = HintLayer.new()
	add_child(hints)
	modulate_node = CanvasModulate.new()
	modulate_node.color = Color(1, 1, 1)
	add_child(modulate_node)
	_make_lights()
	_build_hotspots()
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	_fit_camera()
	w.office_changed.connect(_on_office_changed)
	w.fx.connect(_on_fx)


func _make_lights() -> void:
	var tex := GradientTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = g
	var spots := [[6.5, 5.5], [6.5, 8.5], [6.5, 11.5], [9.5, 5.5], [9.5, 8.5], [9.5, 11.5], [12.4, 8.4], [11.5, 2.4]]
	for s in spots:
		var l := PointLight2D.new()
		l.texture = tex
		l.color = Color(0.6, 0.85, 1.0)
		l.energy = 0.0
		l.texture_scale = 1.6
		l.position = Iso.P(s[0], s[1], 46)
		add_child(l)
		lights.append(l)
	# emergency exit sign glow near the entrance
	var ex := PointLight2D.new()
	ex.texture = tex
	ex.color = Color(0.4, 1.0, 0.55)
	ex.energy = 0.0
	ex.texture_scale = 1.3
	ex.position = Iso.P(13.6, 11.5, 40)
	add_child(ex)
	lights.append(ex)


func _fit_camera() -> void:
	var vp := get_viewport_rect().size
	var office_w := (C.GRID_W + C.GRID_H) * Iso.TW * 0.5 + 40.0
	# start close enough to read faces; pinch out to see the whole floor
	var z := clampf(vp.x / (office_w * 0.62), 0.45, 2.2)
	cam.zoom = Vector2(z, z)
	cam.position = Iso.P(7.2, 7.4, 30)


func fit_all() -> void:
	var vp := get_viewport_rect().size
	var office_w := (C.GRID_W + C.GRID_H) * Iso.TW * 0.5 + 40.0
	var z := clampf(vp.x / office_w, 0.45, 2.2)
	cam.zoom = Vector2(z, z)
	_focus_target = Iso.P(C.GRID_W * 0.5, C.GRID_H * 0.5, 40) + Vector2(0, 24)


# ------------------------------------------------------------------ hotspots

func _build_hotspots() -> void:
	hotspots.clear()
	for h in OfficeLayout.hotspots():
		var poly := PackedVector2Array()
		var anchor := Vector2.ZERO
		if h.has("cells"):
			var pts: Array = []
			for c in h["cells"]:
				for d in [[0, 0], [1, 0], [1, 1], [0, 1]]:
					pts.append(Iso.P(c[0] + d[0], c[1] + d[1], 0))
					pts.append(Iso.P(c[0] + d[0], c[1] + d[1], h["h"]))
			poly = Geometry2D.convex_hull(PackedVector2Array(pts))
			var cs: Array = h["cells"]
			var cx := 0.0
			var cy := 0.0
			for c in cs:
				cx += c[0] + 0.5
				cy += c[1] + 0.5
			anchor = Iso.P(cx / cs.size(), cy / cs.size(), h["h"] + 10)
		else:
			var a: float = h["a"]
			var b: float = h["b"]
			if h["wall"] == "R":
				poly = PackedVector2Array([Iso.P(a, 0, h["z0"]), Iso.P(b, 0, h["z0"]), Iso.P(b, 0, h["z1"]), Iso.P(a, 0, h["z1"])])
				anchor = Iso.P((a + b) * 0.5, 0, h["z1"] + 6)
			else:
				poly = PackedVector2Array([Iso.P(0, a, h["z0"]), Iso.P(0, b, h["z0"]), Iso.P(0, b, h["z1"]), Iso.P(0, a, h["z1"])])
				anchor = Iso.P(0, (a + b) * 0.5, h["z1"] + 6)
		hotspots.append({"id": h["id"], "poly": poly, "anchor": anchor})
	_refresh_hints()


func _refresh_hints() -> void:
	var anchors: Array = []
	for h in hotspots:
		anchors.append(h["anchor"])
	for it in items:
		anchors.append(items[it].anchor() + Vector2(0, -8))
	hints.anchors = anchors


func hotspot_anchor(id: String) -> Vector2:
	if id.begins_with("item_"):
		var iv: ItemView = items.get(id.substr(5))
		return iv.anchor() if iv else Vector2.ZERO
	for h in hotspots:
		if h["id"] == id:
			return h["anchor"]
	return Vector2.ZERO


func hit_test(p: Vector2) -> Dictionary:
	# characters first (front-most wins)
	var best := ""
	var by := -1e9
	for id in chars:
		var cv: CharacterView = chars[id]
		if not cv.visible:
			continue
		var r := Rect2(cv.position + Vector2(-16, -82), Vector2(32, 86))
		if r.has_point(p) and cv.position.y > by:
			by = cv.position.y
			best = id
	if best != "":
		return {"type": "npc", "id": best}
	for it in items:
		if items[it].anchor().distance_to(p) < 16.0:
			return {"type": "item", "id": it}
	# smaller hotspots first so a desk item/promo file beats a big desk
	var hs := hotspots.duplicate()
	hs.sort_custom(func(a, b): return _area(a["poly"]) < _area(b["poly"]))
	for h in hs:
		if Geometry2D.is_point_in_polygon(p, h["poly"]):
			return {"type": "hotspot", "id": h["id"]}
	return {}


func _area(poly: PackedVector2Array) -> float:
	var s := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		s += a.x * b.y - b.x * a.y
	return absf(s) * 0.5


func select_hotspot(id: String) -> void:
	selected_hotspot = id
	for it in items:
		items[it].highlight = id == "item_" + it
		items[it].queue_redraw()
	highlight.queue_redraw()


func select_npc(id: String) -> void:
	for k in chars:
		chars[k].selected = k == id


func _draw_highlight() -> void:
	if selected_hotspot == "" or selected_hotspot.begins_with("item_"):
		return
	for h in hotspots:
		if h["id"] == selected_hotspot:
			var poly: PackedVector2Array = h["poly"]
			var closed := poly.duplicate()
			closed.append(poly[0])
			var a := 0.55 + 0.35 * sin(_t * 6.0)
			highlight.draw_colored_polygon(poly, Color(1, 0.9, 0.3, 0.12 * a))
			highlight.draw_polyline(closed, Color(1, 0.85, 0.2, a), 2.5, true)


# ------------------------------------------------------------------ updates

func _on_office_changed(what: String) -> void:
	for f in furn:
		f.queue_redraw()
	for it in items:
		items[it].refresh()
	_refresh_hints()


func _on_fx(kind: String, data: Dictionary) -> void:
	var npc_id: String = data.get("npc", "")
	match kind:
		"meddle":
			var spot := ""
			var action: String = data.get("action", "")
			if action in ["break_coffee", "fix_coffee"]:
				spot = "coffee_machine"
			elif action == "break_printer":
				spot = "printer"
			elif action == "move_meeting":
				spot = "meeting_board"
			elif action == "set_temp":
				spot = "ac"
			elif action in ["lights_off", "lights_on"]:
				spot = "lights"
			elif action == "edit_promo":
				spot = "promo_file"
			elif action == "move_item":
				spot = "item_" + str(data.get("item", ""))
			elif data.get("owner", "") != "":
				spot = "ws_" + str(data["owner"])
			var p := hotspot_anchor(spot)
			if p != Vector2.ZERO:
				fx.burst("meddle", p, 18)
		"spill":
			if chars.has(npc_id):
				fx.burst("spill", chars[npc_id].position + Vector2(0, -40), 12)
				chars[npc_id].stain = 25.0
		"anger":
			if chars.has(npc_id):
				fx.burst("anger", chars[npc_id].position + Vector2(0, -70), 8)
		"shake":
			if chars.has(npc_id):
				chars[npc_id].react = 0.35


func focus_on(world_pos: Vector2) -> void:
	_focus_target = world_pos


func _process(delta: float) -> void:
	if w == null:
		return
	_t += delta
	highlight.queue_redraw()
	# darkness & temperature tint
	var dark_goal := 0.0 if w.office.objects["lights"]["on"] else 1.0
	_dark_k = move_toward(_dark_k, dark_goal, delta * 3.0)
	var base := Color(1, 1, 1)
	var temp := int(w.office.objects["ac"]["temp"])
	if temp <= 19:
		base = Color(0.9, 0.95, 1.0) if temp > 16 else Color(0.84, 0.92, 1.0)
	elif temp >= 25:
		base = Color(1.0, 0.95, 0.88) if temp < 29 else Color(1.0, 0.9, 0.8)
	var dark_col := Color(0.36, 0.38, 0.56)
	modulate_node.color = base.lerp(dark_col, _dark_k)
	for l in lights:
		l.energy = _dark_k * 0.95
		l.enabled = _dark_k > 0.01
	# camera inertia & focus
	if _focus_target != null:
		cam.position = cam.position.lerp(_focus_target, minf(1.0, delta * 5.0))
		if cam.position.distance_to(_focus_target) < 2.0:
			_focus_target = null
	elif _touches.is_empty() and _vel.length() > 5.0:
		cam.position += _vel * delta
		_vel = _vel.lerp(Vector2.ZERO, minf(1.0, delta * 5.0))
	_clamp_camera()


func _clamp_camera() -> void:
	var minp := Iso.P(0, C.GRID_H) + Vector2(-60, -200)
	var maxp := Iso.P(C.GRID_W, 0) + Vector2(60, 0)
	var top := Iso.P(0, 0, 140).y
	var bottom := Iso.P(C.GRID_W, C.GRID_H).y + 60
	cam.position.x = clampf(cam.position.x, minp.x, maxp.x)
	cam.position.y = clampf(cam.position.y, top, bottom)


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touches.is_empty() and ui_block.is_valid() and ui_block.call(event.position):
				return
			_touches[event.index] = event.position
			_focus_target = null
			if _touches.size() == 1:
				_tap_start = event.position
				_tap_time = Time.get_ticks_msec() / 1000.0
				_moved = false
				_vel = Vector2.ZERO
			elif _touches.size() == 2:
				_moved = true
				var ks := _touches.keys()
				_pinch_d = (_touches[ks[0]] as Vector2).distance_to(_touches[ks[1]])
		else:
			_touches.erase(event.index)
			if _touches.is_empty() and not _moved and Time.get_ticks_msec() / 1000.0 - _tap_time < 0.6:
				_tap(event.position)
	elif event is InputEventScreenDrag:
		if not _touches.has(event.index):
			return
		_touches[event.index] = event.position
		if _touches.size() == 1:
			if event.position.distance_to(_tap_start) > 14.0:
				_moved = true
			if _moved:
				cam.position -= event.relative / cam.zoom.x
				_vel = -event.velocity / cam.zoom.x * 0.6
		elif _touches.size() >= 2:
			var ks2 := _touches.keys()
			var a: Vector2 = _touches[ks2[0]]
			var b: Vector2 = _touches[ks2[1]]
			var d := a.distance_to(b)
			if _pinch_d > 10.0:
				_zoom_at((a + b) * 0.5, d / _pinch_d)
			_pinch_d = d
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(event.position, 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(event.position, 1.0 / 1.12)


func _zoom_at(screen_p: Vector2, factor: float) -> void:
	var before := _screen_to_world(screen_p)
	var z := clampf(cam.zoom.x * factor, 0.45, 2.4)
	cam.zoom = Vector2(z, z)
	var after := _screen_to_world(screen_p)
	cam.position += before - after


func _screen_to_world(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * p


func _tap(screen_p: Vector2) -> void:
	if ui_block.is_valid() and ui_block.call(screen_p):
		return
	var wp := _screen_to_world(screen_p)
	var hit := hit_test(wp)
	match hit.get("type", ""):
		"npc":
			tapped_npc.emit(hit["id"])
		"item":
			tapped_item.emit(hit["id"])
		"hotspot":
			tapped_hotspot.emit(hit["id"])
		_:
			tapped_empty.emit()


func world_to_screen(p: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * p
