class_name HUD
extends CanvasLayer
## Saray HUD'u: konum, tarih/saat, zaman kontrolü, hazine ve huzur, hızlı erişim düğmeleri,
## bağlamsal etkileşim düğmesi, bildirimler ve dokunmatik kontroller.

var game: Node
var root: Control
var panel_layer: Control
var touch: TouchControls
var loc_label: Label
var date_label: Label
var speed_btns: Array = []
var treasury_label: Label
var huzur_label: Label
var interact_btn: Button
var run_btn: Button
var events_btn: Button
var toast_box: VBoxContainer
var fps_label: Label
var _clock_t := 0.0
var mute_toasts := false
var _safe := Rect2()


func setup(g: Node) -> void:
	game = g
	layer = 5
	root = Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	add_child(root)
	touch = TouchControls.new()
	touch.player = game.player
	root.add_child(touch)
	_apply_safe_area()
	_build_top_left()
	_build_top_right()
	_build_right_column()
	_build_bottom_right()
	toast_box = UI.vbox(6)
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.position = Vector2(-330, 96)
	toast_box.custom_minimum_size = Vector2(660, 0)
	toast_box.size = Vector2(660, 10)
	toast_box.anchor_left = 0.5
	toast_box.anchor_right = 0.5
	toast_box.offset_left = -330
	toast_box.offset_right = 330
	toast_box.offset_top = 96 + _safe.position.y
	root.add_child(toast_box)
	fps_label = UI.label("", 16, UI.MUTED)
	fps_label.position = Vector2(_safe.position.x + 16, get_viewport().get_visible_rect().size.y - 30)
	fps_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fps_label.offset_top = -30
	fps_label.offset_left = 16
	root.add_child(fps_label)
	panel_layer = Control.new()
	panel_layer.name = "Panels"
	panel_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_layer)
	GameState.stats_changed.connect(_update_stats)
	GameState.events_changed.connect(_update_events)
	GameState.notify.connect(toast)
	GameState.speed_changed.connect(func(_i): _update_speed())
	game.player.target_changed.connect(_on_target)
	game.player.room_changed.connect(_on_room)
	_update_stats()
	_update_events()
	_update_speed()
	_update_clock()
	_on_target({})


func _apply_safe_area() -> void:
	var vp := get_viewport().get_visible_rect().size
	var ws := DisplayServer.window_get_size()
	var sa := DisplayServer.get_display_safe_area()
	if ws.x > 0 and ws.y > 0 and sa.size.x > 0 and OS.has_feature("mobile"):
		var sx := vp.x / float(ws.x)
		var sy := vp.y / float(ws.y)
		_safe = Rect2(Vector2(sa.position.x * sx, sa.position.y * sy), Vector2(sa.size.x * sx, sa.size.y * sy))
		# yalnızca kenar boşluklarını kullan
		_safe = Rect2(Vector2(minf(_safe.position.x, 60.0), minf(_safe.position.y, 40.0)), _safe.size)
	else:
		_safe = Rect2(Vector2.ZERO, vp)


func _panel_style() -> StyleBoxFlat:
	return UI.sb(Color(UI.NAVY, 0.78), Color(UI.GOLD, 0.55), 2, 12, 12)


func _build_top_left() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	p.position = Vector2(14 + _safe.position.x, 10 + _safe.position.y)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(p)
	var v := UI.vbox(2)
	p.add_child(v)
	loc_label = UI.title("Avlu", 28)
	v.add_child(loc_label)
	date_label = UI.label("", 18, UI.CREAM)
	v.add_child(date_label)
	var row := UI.hbox(6)
	v.add_child(row)
	for i in range(GameState.SPEEDS.size()):
		var ii := i
		var b := UI.button(GameState.SPEED_LABELS[i], func(): GameState.set_speed(ii), 44)
		b.custom_minimum_size = Vector2(62, 44)
		b.add_theme_font_size_override("font_size", 18)
		row.add_child(b)
		speed_btns.append(b)
	var sk := UI.button("Atla", func(): game.open_time_skip(), 44)
	sk.custom_minimum_size = Vector2(78, 44)
	sk.add_theme_font_size_override("font_size", 18)
	sk.add_theme_stylebox_override("normal", UI.sb(Color(0.3, 0.12, 0.28, 0.95), UI.GOLD, 2, 10, 8))
	row.add_child(sk)


func _build_top_right() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.offset_right = -14
	p.offset_top = 10 + _safe.position.y
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(p)
	var h := UI.hbox(14)
	p.add_child(h)
	var v := UI.vbox(0)
	h.add_child(v)
	treasury_label = UI.label("", 22, UI.GOLD2, UI.font_semi)
	v.add_child(treasury_label)
	huzur_label = UI.label("", 17, UI.CREAM)
	v.add_child(huzur_label)
	var menu := UI.button("Menü", func(): game.open_pause(), 56)
	menu.custom_minimum_size.x = 100
	h.add_child(menu)


func _build_right_column() -> void:
	var v := UI.vbox(8)
	v.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	v.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.offset_right = -14
	v.offset_top = -170
	v.offset_bottom = 120
	root.add_child(v)
	var items := [["Harita", func(): game.open_map()], ["Saray Halkı", func(): game.open_people()], ["Devlet", func(): game.open_state()], ["Olaylar", func(): game.open_events()], ["Günlük", func(): game.open_log()]]
	for it in items:
		var b := UI.button(it[0], it[1], 54)
		b.custom_minimum_size = Vector2(156, 54)
		b.add_theme_font_size_override("font_size", 19)
		v.add_child(b)
		if it[0] == "Olaylar":
			events_btn = b


func _build_bottom_right() -> void:
	interact_btn = UI.button("", func(): game.player.do_interact(), 84, true)
	interact_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	interact_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	interact_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	interact_btn.offset_right = -18
	interact_btn.offset_bottom = -18
	interact_btn.custom_minimum_size = Vector2(300, 84)
	interact_btn.add_theme_font_size_override("font_size", 24)
	root.add_child(interact_btn)
	var row := UI.hbox(8)
	row.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_right = -18
	row.offset_bottom = -112
	root.add_child(row)
	var zi := UI.button("−", func(): game.player.zoom(0.8), 58)
	zi.custom_minimum_size = Vector2(58, 58)
	row.add_child(zi)
	var zo := UI.button("+", func(): game.player.zoom(-0.8), 58)
	zo.custom_minimum_size = Vector2(58, 58)
	row.add_child(zo)
	run_btn = UI.button("Koş", _toggle_run, 58)
	run_btn.custom_minimum_size = Vector2(110, 58)
	row.add_child(run_btn)


func _toggle_run() -> void:
	game.player.run_toggle = not game.player.run_toggle
	run_btn.text = "Yürü" if game.player.run_toggle else "Koş"


func _on_target(t: Dictionary) -> void:
	if t.is_empty():
		interact_btn.visible = false
	else:
		interact_btn.visible = true
		interact_btn.text = String(t.get("label", ""))


func _on_room(r: String) -> void:
	loc_label.text = PalaceLayout.room_short(r)


func _process(delta: float) -> void:
	_clock_t -= delta
	if _clock_t <= 0.0:
		_clock_t = 0.5
		_update_clock()
		if Settings.show_fps:
			fps_label.text = "FPS %d" % Engine.get_frames_per_second()
		else:
			fps_label.text = ""


func _update_clock() -> void:
	if not GameState.active:
		return
	date_label.text = "%s, %s  •  %s" % [GameState.weekday_name(), GameState.date_string(), GameState.time_string()]


func _update_speed() -> void:
	for i in range(speed_btns.size()):
		var b: Button = speed_btns[i]
		if i == GameState.speed_idx:
			b.add_theme_stylebox_override("normal", UI.sb(UI.EMERALD, UI.GOLD2, 2, 10, 8))
		else:
			b.remove_theme_stylebox_override("normal")


func _update_stats() -> void:
	if not GameState.active:
		return
	treasury_label.text = GameState.fmt_money(GameState.treasury())
	treasury_label.add_theme_color_override("font_color", UI.GOLD2 if GameState.treasury() >= 0 else UI.RED)
	huzur_label.text = "Halk huzuru %%%d  •  Prestij %d" % [int(GameState.people_huzur()), int(GameState.w["state"]["prestige"])]


func _update_events() -> void:
	if events_btn == null:
		return
	var n := EventEngine.pending(GameState).size()
	var unseen := 0
	for e in EventEngine.pending(GameState):
		if not e.get("seen", false):
			unseen += 1
	events_btn.text = "Olaylar (%d)" % n if n > 0 else "Olaylar"
	if unseen > 0:
		events_btn.add_theme_stylebox_override("normal", UI.sb(Color("7a2a2a"), UI.GOLD2, 2, 10, 14))
	else:
		events_btn.remove_theme_stylebox_override("normal")


func toast(text: String, kind: String = "bilgi") -> void:
	if toast_box == null or mute_toasts:
		return
	while toast_box.get_child_count() >= 3:
		var old := toast_box.get_child(0)
		toast_box.remove_child(old)
		old.queue_free()
	var col := Color(UI.NAVY, 0.92)
	match kind:
		"uyari":
			col = Color(0.4, 0.1, 0.1, 0.92)
		"gorusme", "harem":
			col = Color(0.3, 0.12, 0.28, 0.92)
		"devlet":
			col = Color(0.08, 0.22, 0.38, 0.92)
		"bilgi":
			col = Color(0.08, 0.28, 0.2, 0.92)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.sb(col, Color(UI.GOLD, 0.7), 2, 10, 12))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.wrap_label(text, 19, UI.CREAM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	toast_box.add_child(p)
	AudioManager.play_ui("notify")
	var tw := p.create_tween()
	tw.tween_interval(4.5)
	tw.tween_property(p, "modulate:a", 0.0, 0.8)
	tw.tween_callback(p.queue_free)


func open_panel(p: Control) -> void:
	touch.reset()
	game.player.move_input = Vector2.ZERO
	panel_layer.add_child(p)


func top_panel() -> Control:
	var n := panel_layer.get_child_count()
	if n == 0:
		return null
	return panel_layer.get_child(n - 1)
