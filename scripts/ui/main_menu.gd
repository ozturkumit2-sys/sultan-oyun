class_name MainMenu
extends Node
## Title screen: a live demo office in the background, sticky-note title and index-card buttons.

signal start_game(new_game: bool)

var demo: SimWorld
var view: OfficeView
var ui: Control
var layer: CanvasLayer
var settings_sheet
var info
var confirm
var _t := 0.0
var title_notes: Array = []


func _ready() -> void:
	demo = Game.create_world()
	demo.new_game(int(Time.get_unix_time_from_system()) % 100000 + 1)
	# skip ahead so the office is busy
	for i in 300:
		demo.step(0.25)
	view = OfficeView.new()
	add_child(view)
	view.build(demo)
	view.interactive = false
	view.hints.strength = 0.0
	view.cam.zoom = Vector2(1.15, 1.15)
	layer = CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var shade := ColorRect.new()
	shade.color = Color(0.97, 0.93, 0.85, 0.42)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	var title := Control.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.draw.connect(_draw_title.bind(title))
	ui.add_child(title)
	title_notes.append(title)
	_build_buttons()
	settings_sheet = Boards.SettingsSheet.new()
	info = Boards.InfoSheet.new()
	confirm = Boards.ConfirmSheet.new()
	layer.add_child(settings_sheet)
	layer.add_child(info)
	layer.add_child(confirm)
	settings_sheet.how_to.connect(func():
		settings_sheet.close()
		info.open_text(Loc.t("ui.how_to"), Loc.t("ui.how_to_text")))
	settings_sheet.credits.connect(func():
		settings_sheet.close()
		info.open_text(Loc.t("ui.credits"), Loc.t("ui.credits_text")))
	confirm.answered.connect(func(yes):
		if yes:
			start_game.emit(true))
	get_tree().root.go_back_requested.connect(_on_back)


func _exit_tree() -> void:
	if get_tree() and get_tree().root.go_back_requested.is_connected(_on_back):
		get_tree().root.go_back_requested.disconnect(_on_back)


func _build_buttons() -> void:
	var vs := ui.get_viewport_rect().size
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.position = Vector2(vs.x * 0.5 - 170, vs.y * 0.5 + 10)
	col.size = Vector2(340, 400)
	ui.add_child(col)
	var has := Game.has_save()
	if has:
		var b := NoteButton.make(Loc.t("ui.continue_day", {"day": Game.save_day()}), "", "card", Color("fffdf5"), Vector2(340, 78))
		b.font_kind = "marker"
		b.font_size = 28
		b.tilt = -1.5
		b.pressed.connect(func(): start_game.emit(false))
		col.add_child(b)
	var nb := NoteButton.make(Loc.t("ui.new_game"), "", "card", Color("fff7d6") if has else Color("fffdf5"), Vector2(340, 78))
	nb.font_kind = "marker"
	nb.font_size = 28
	nb.tilt = 1.2
	nb.pressed.connect(func():
		if Game.has_save():
			confirm.ask(Loc.t("ui.new_game_confirm"))
		else:
			start_game.emit(true))
	col.add_child(nb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var hb := NoteButton.make(Loc.t("ui.how_to"), "help", "sticky", UiKit.sticky("blue"), Vector2(164, 96))
	hb.tilt = -3
	hb.font_size = 21
	hb.pressed.connect(func(): info.open_text(Loc.t("ui.how_to"), Loc.t("ui.how_to_text")))
	var sb := NoteButton.make(Loc.t("ui.settings"), "gear", "sticky", UiKit.sticky("green"), Vector2(164, 96))
	sb.tilt = 2.5
	sb.font_size = 21
	sb.pressed.connect(func(): settings_sheet.open_settings(false))
	row.add_child(hb)
	row.add_child(sb)
	col.add_child(row)
	var ver := Sheet.label(Loc.t("ui.version", {"v": ProjectSettings.get_setting("application/config/version", "1.0")}), 16, "type", Color(0.3, 0.3, 0.35), false)
	ver.position = Vector2(14, vs.y - 34)
	ui.add_child(ver)


func _draw_title(c: Control) -> void:
	var vs := c.size
	var cx := vs.x * 0.5
	var y0 := vs.y * 0.18
	var wob := sin(_t * 1.6) * 1.2
	# OFFICE
	var mk := UiKit.font("marker")
	c.draw_set_transform(Vector2(cx - 90, y0), deg_to_rad(-6 + wob), Vector2.ONE)
	UiKit.draw_note(c, Rect2(-170, -70, 340, 130), UiKit.sticky("yellow"))
	UiKit.draw_tape(c, Vector2(0, -70), Vector2(110, 26), 0.06)
	c.draw_string(mk, Vector2(-170, 34), "OFFICE", HORIZONTAL_ALIGNMENT_CENTER, 340, 84, UiKit.INK)
	# POLTERGEIST (the brand stays the same in every language)
	c.draw_set_transform(Vector2(cx + 30, y0 + 140), deg_to_rad(4 - wob), Vector2.ONE)
	UiKit.draw_note(c, Rect2(-250, -66, 500, 124), UiKit.sticky("pink"))
	UiKit.draw_tape(c, Vector2(-220, -58), Vector2(80, 24), -0.7)
	var fs := UiKit.fit_size(mk, "POLTERGEIST", 470, 80, 0.5)
	c.draw_string(mk, Vector2(-250, 22 + fs * 0.12), "POLTERGEIST", HORIZONTAL_ALIGNMENT_CENTER, 500, fs, UiKit.RED)
	# subtitle on a strip of paper
	c.draw_set_transform(Vector2(cx, y0 + 250), deg_to_rad(-1.5), Vector2.ONE)
	c.draw_rect(Rect2(-250, -26, 500, 48), Color(0, 0, 0, 0.15))
	c.draw_rect(Rect2(-254, -30, 500, 48), UiKit.PAPER)
	c.draw_string(UiKit.font("type"), Vector2(-250, 2), Loc.t("ui.subtitle"), HORIZONTAL_ALIGNMENT_CENTER, 500, UiKit.fit_size(UiKit.font("type"), Loc.t("ui.subtitle"), 488, 19, 0.7), UiKit.INK)
	# little ghost peeking
	c.draw_set_transform(Vector2(cx + 220, y0 - 30 + sin(_t * 2.2) * 6), 0.15, Vector2.ONE)
	Icons.draw(c, "ghost", Vector2.ZERO, 70)
	c.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _process(delta: float) -> void:
	_t += delta
	demo.step(delta * C.MIN_PER_SEC)
	if demo.day_over:
		demo.next_day()
	# slow drifting camera
	view.cam.position = Iso.P(7.0 + sin(_t * 0.07) * 2.5, 7.0 + cos(_t * 0.05) * 2.0, 40)
	for t in title_notes:
		t.queue_redraw()


func _on_back() -> void:
	for s in [info, settings_sheet, confirm]:
		if s.is_open:
			s.close()
			return
	get_tree().quit()
