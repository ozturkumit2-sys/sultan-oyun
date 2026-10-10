class_name MapPanel
extends BasePanel
## Saray haritası: bir mekâna dokunun, hükümdar oraya yürüsün.

var game: Node
var canvas: PalaceMapCanvas
var info: Label


func open(g: Node) -> void:
	game = g
	setup_frame("Saray Haritası", 0.96, 0.95)
	var row := UI.hbox(12)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	canvas = PalaceMapCanvas.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.size_flags_stretch_ratio = 2.6
	canvas.room_tapped.connect(_on_room)
	row.add_child(canvas)
	var side := UI.vbox(8)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(side)
	side.add_child(UI.label("Şu an: " + PalaceLayout.room_name(GameState.player_room), 20, UI.GOLD2, UI.font_semi))
	info = UI.wrap_label("Gitmek istediğiniz yere dokunun. Hükümdar oraya kendiliğinden yürür; joystick'e dokunduğunuzda yürüyüş durur.", 18, UI.MUTED)
	side.add_child(info)
	var sc := UI.scroll()
	side.add_child(sc)
	var quick := UI.vbox(6)
	quick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(quick)
	for rid in PalaceLayout.MAP_ORDER:
		var r: String = rid
		var b := UI.button(PalaceLayout.room_short(r), func(): _go(r), 46)
		b.add_theme_font_size_override("font_size", 18)
		quick.add_child(b)


func _on_room(rid: String) -> void:
	var here := GameState.chars_in_room(rid)
	var names: Array = []
	for id in here:
		names.append(GameState.short_name(id))
	info.text = "%s\nBurada: %s" % [PalaceLayout.room_name(rid), ", ".join(PackedStringArray(names)) if not names.is_empty() else "kimse yok"]
	_go(rid)


func _go(rid: String) -> void:
	game.walk_to_room(rid)
	close_panel()


class PalaceMapCanvas:
	extends Control
	signal room_tapped(rid: String)
	var _bounds := Rect2(-62, -57, 124, 139)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(queue_redraw)

	func _xf() -> Array:
		var sc := minf(size.x / _bounds.size.x, size.y / _bounds.size.y)
		var off := (size - _bounds.size * sc) * 0.5
		return [sc, off]

	func w2s(x: float, z: float) -> Vector2:
		var t := _xf()
		return Vector2((x - _bounds.position.x) * float(t[0]), (z - _bounds.position.y) * float(t[0])) + (t[1] as Vector2)

	func _draw() -> void:
		UI.fonts()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14, 0.9))
		for rid in PalaceLayout.ROOMS.keys():
			var room: Dictionary = PalaceLayout.ROOMS[rid]
			var r: Array = room["rect"]
			var a := w2s(r[0], r[1])
			var b := w2s(r[2], r[3])
			var col: Color = PalaceLayout.CAT_COLORS.get(room["cat"], Color(0.4, 0.4, 0.4))
			if rid == GameState.player_room:
				col = col.lightened(0.3)
			draw_rect(Rect2(a, b - a), Color(col, 0.85))
			draw_rect(Rect2(a, b - a), Color(UI.GOLD, 0.5), false, 1.5)
			if room["kind"] != "corridor":
				var fs := 13 if (b - a).x < 70 else 15
				draw_string(UI.font_semi, a + Vector2(4, (b - a).y * 0.5 + 5), String(room["short"]), HORIZONTAL_ALIGNMENT_CENTER, (b - a).x - 8, fs, UI.CREAM)
		for d in PalaceLayout.DOORS:
			var p: Vector3 = PalaceLayout.door_point(d)
			draw_circle(w2s(p.x, p.z), 3.0, UI.GOLD2)
		# karakterler
		for id in GameState.npc_ids():
			var c: Dictionary = GameState.ch(id)
			if c["location"] == "disari" or c["activity"] == "uyku":
				continue
			var rr := PalaceLayout.rect(c["location"])
			var h := float(absi(hash(id)) % 1000) / 1000.0
			var h2 := float(absi(hash(id + "z")) % 1000) / 1000.0
			var pos := w2s(rr.position.x + rr.size.x * (0.2 + 0.6 * h), rr.position.y + rr.size.y * (0.2 + 0.6 * h2))
			var op: float = GameState.opinion(id, GameState.PLAYER)
			var cc := UI.GREEN if op >= 55 else (Color("d8a24e") if op >= 35 else UI.RED)
			draw_circle(pos, 5.0, cc)
		var pp := GameState.player_pos
		var ps := w2s(pp.x, pp.z)
		draw_circle(ps, 9.0, UI.GOLD2)
		draw_arc(ps, 13.0, 0, TAU, 24, UI.CREAM, 2.0)

	func _gui_input(event: InputEvent) -> void:
		var pos := Vector2(-1, -1)
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pos = event.position
		if pos.x < 0:
			return
		var t := _xf()
		var sc: float = t[0]
		var off: Vector2 = t[1]
		var wx := (pos.x - off.x) / sc + _bounds.position.x
		var wz := (pos.y - off.y) / sc + _bounds.position.y
		var rid := PalaceLayout.room_at(wx, wz)
		if rid != "":
			accept_event()
			room_tapped.emit(rid)
