class_name GameScreen
extends Node
## In-game screen: runs the simulation in real time and wires the office view, speech
## bubbles, HUD and panels together. Saves automatically.

signal quit_to_menu

var w: SimWorld
var view: OfficeView
var bubbles: BubbleLayer
var hud: Hud
var menu: InterventionMenu
var file: CharacterFile
var staff
var gossip
var today
var settings_sheet
var info
var paper: DayPaper
var ui_layer: CanvasLayer
var _save_t := 0.0
var _speed_before := 1.0


func _ready() -> void:
	w = Game.world
	view = OfficeView.new()
	add_child(view)
	view.build(w)
	var bl := CanvasLayer.new()
	bl.layer = 5
	add_child(bl)
	bubbles = BubbleLayer.new()
	bubbles.view = view
	bl.add_child(bubbles)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	hud = Hud.new()
	ui_layer.add_child(hud)
	hud.build(w)
	menu = InterventionMenu.new()
	file = CharacterFile.new()
	staff = Boards.StaffBoard.new()
	gossip = Boards.GossipBoard.new()
	today = Boards.TodayCard.new()
	settings_sheet = Boards.SettingsSheet.new()
	info = Boards.InfoSheet.new()
	paper = DayPaper.new()
	for s in [menu, file, staff, gossip, today, settings_sheet, info, paper]:
		ui_layer.add_child(s)
	for s in [menu, file, staff, gossip, today, settings_sheet, info]:
		s.closed.connect(_on_sheet_closed)
	# wiring
	view.tapped_hotspot.connect(_on_hotspot)
	view.tapped_item.connect(func(it): _on_hotspot("item_" + it))
	view.tapped_npc.connect(_open_file)
	view.tapped_empty.connect(func(): view.select_npc(""))
	view.ui_block = _ui_covers
	menu.meddled.connect(_on_meddled)
	file.locate.connect(_locate_npc)
	staff.pick.connect(func(id):
		staff.close()
		_open_file(id))
	gossip.focus_event.connect(_focus_entry)
	hud.open_log.connect(func(): _open_sheet(gossip, func(): gossip.open_for(w)))
	hud.open_staff.connect(func(): _open_sheet(staff, func(): staff.open_for(w)))
	hud.open_today.connect(func(): _open_sheet(today, func(): today.open_for(w)))
	hud.open_settings.connect(func(): _open_sheet(settings_sheet, func(): settings_sheet.open_settings(true)))
	hud.speed_changed.connect(_set_speed)
	hud.toast_tapped.connect(_focus_entry)
	hud.fit_pressed.connect(_toggle_fit)
	settings_sheet.to_menu.connect(_to_menu)
	settings_sheet.how_to.connect(func():
		settings_sheet.close()
		info.open_text(Loc.t("ui.how_to"), Loc.t("ui.how_to_text")))
	settings_sheet.credits.connect(func():
		settings_sheet.close()
		info.open_text(Loc.t("ui.credits"), Loc.t("ui.credits_text")))
	paper.next_day.connect(_next_day)
	w.said.connect(_on_said)
	w.sfx.connect(_on_sfx)
	w.day_ended.connect(_on_day_ended)
	w.secret_discovered.connect(func(_f): Audio.play("sparkle", -4.0))
	_set_speed(Game.speed if Game.speed > 0.0 else 1.0)
	if not Game.settings.get("tips_seen", false):
		hud.show_tip(Loc.t("ui.tap_hint"), 16.0)
		Game.set_setting("tips_seen", true)
	view.hints.strength = 1.0
	if w.day_over:
		_on_day_ended(w.stats.history[-1] if not w.stats.history.is_empty() else w.stats.summary(w.day))
	get_tree().root.go_back_requested.connect(_on_back)


func _exit_tree() -> void:
	if get_tree() and get_tree().root.go_back_requested.is_connected(_on_back):
		get_tree().root.go_back_requested.disconnect(_on_back)


func _ui_covers(p: Vector2) -> bool:
	var vs := get_viewport().get_visible_rect().size
	if p.y < Hud.PAD_TOP + 108.0 or p.y > vs.y - Hud.BOTTOM_H + 8.0:
		return true
	if Rect2(vs.x - 82, vs.y - Hud.BOTTOM_H - 78, 70, 70).has_point(p):
		return true
	for t in hud.toasts:
		if (t["node"] as Control).get_global_rect().has_point(p):
			return true
	if hud.tip and hud.tip.get_global_rect().has_point(p):
		return true
	return false


func _any_sheet_open() -> bool:
	for s in [menu, file, staff, gossip, today, settings_sheet, info]:
		if s.is_open:
			return true
	return paper.visible


func _open_sheet(s, opener: Callable) -> void:
	for o in [menu, file, staff, gossip, today, settings_sheet, info]:
		if o != s and o.is_open:
			o.close()
	opener.call()
	view.interactive = false


func _on_sheet_closed() -> void:
	if not _any_sheet_open():
		view.interactive = true
		view.select_hotspot("")


## Pan so a point ends up at `frac` of the screen height (above an opening sheet).
func _frame_point(p: Vector2, frac: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	view.focus_on(p + Vector2(0, (0.5 - frac) * vs.y / view.cam.zoom.y))


func _on_hotspot(id: String) -> void:
	view.select_npc("")
	view.select_hotspot(id)
	var a := view.hotspot_anchor(id)
	if a != Vector2.ZERO:
		_frame_point(a, 0.27)
	_open_sheet(menu, func(): menu.open_for(w, id))


func _open_file(id: String) -> void:
	view.select_npc(id)
	var cv: CharacterView = view.chars.get(id)
	if cv and cv.visible:
		_frame_point(cv.position + Vector2(0, -40), 0.14)
	_open_sheet(file, func(): file.open_for(w, id))


func _on_meddled(_a: Dictionary) -> void:
	view.hints.strength = maxf(0.35, view.hints.strength - 0.15)


func _locate_npc(id: String) -> void:
	var cv: CharacterView = view.chars.get(id)
	if cv and cv.visible:
		view.focus_on(cv.position + Vector2(0, -40))
		view.select_npc(id)


func _focus_entry(e: Dictionary) -> void:
	var actors: Array = e.get("actors", [])
	for a in actors:
		if view.chars.has(a) and view.chars[a].visible:
			_locate_npc(a)
			return


func _toggle_fit() -> void:
	if view.cam.zoom.x < 0.95:
		view._fit_camera()
	else:
		view.fit_all()


func _set_speed(v: float) -> void:
	Game.speed = v
	hud.set_speed_ui(v)


func _on_said(id: String, text: String, to: String) -> void:
	bubbles.add(id, text, to)


func _on_sfx(id: String) -> void:
	var map := {"meddle": "meddle", "coffee": "coffee", "printer": "printer", "printer_fail": "printer_fail", "phone": "phone",
		"email": "email", "gasp": "gasp", "argue": "argue", "thump": "thump", "splash": "splash", "papers": "papers",
		"fixed": "fixed", "lights_off": "lights_off", "lights_on": "lights_on", "crowd": "crowd", "slam": "slam"}
	if map.has(id):
		Audio.play(map[id], -3.0 if id in ["coffee", "printer"] else 0.0)


func _process(delta: float) -> void:
	if w == null or w.day_over:
		return
	if Game.speed > 0.0:
		w.step(delta * C.MIN_PER_SEC * Game.speed)
	_save_t += delta
	if _save_t > 20.0:
		_save_t = 0.0
		Game.save_game()


func _on_day_ended(sm: Dictionary) -> void:
	bubbles.clear_all()
	for s in [menu, file, staff, gossip, today, settings_sheet, info]:
		if s.is_open:
			s.close()
	view.interactive = false
	Game.save_game()
	paper.show_day(w, sm)


func _next_day() -> void:
	w.next_day()
	view.interactive = true
	view._on_office_changed("day")
	Game.save_game()


func _to_menu() -> void:
	Game.save_game()
	quit_to_menu.emit()


func _on_back() -> void:
	# Android back: close the top panel, otherwise open settings
	for s in [info, menu, file, staff, gossip, today, settings_sheet]:
		if s.is_open:
			s.close()
			return
	if paper.visible:
		return
	_open_sheet(settings_sheet, func(): settings_sheet.open_settings(true))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if w != null:
			Game.save_game()
