extends CanvasLayer
## HUD for Kedi Evi: fish bank, rescued kittens, context action button, pause, shop.

signal menu_requested

var root: Control
var touch: Control
var icons: Control
var bank_label: Label
var action_btn: Button
var _action_cb: Callable
var banner: PanelContainer
var banner_label: Label
var _banner_t := 0.0
var fade: ColorRect
var pause_panel: Control
var pause_btn: Button
var shop: ShopUI
var kitten_coats: Array = []
var kitten_total := 5


func _ready() -> void:
	layer = 10
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	touch = preload("res://scripts/touch_controls.gd").new()
	root.add_child(touch)
	icons = Control.new()
	icons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.draw.connect(_draw_icons)
	root.add_child(icons)
	bank_label = UIKit.label(str(GameState.bank), 44, UIKit.CREAM, 800, 12, UIKit.NAVY)
	bank_label.position = Vector2(96, 10)
	root.add_child(bank_label)
	GameState.bank_changed.connect(func(b): bank_label.text = str(b))

	action_btn = UIKit.button("", UIKit.CORAL, 32, 340)
	action_btn.visible = false
	action_btn.pressed.connect(func():
		if _action_cb.is_valid():
			_action_cb.call())
	root.add_child(action_btn)

	pause_btn = Button.new()
	pause_btn.flat = true
	pause_btn.custom_minimum_size = Vector2(84, 84)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.draw.connect(func():
		var c := Vector2(42, 42)
		pause_btn.draw_circle(c + Vector2(0, 4), 36, Color(UIKit.NAVY, 0.4))
		pause_btn.draw_circle(c, 36, UIKit.CREAM)
		pause_btn.draw_arc(c, 33, 0, TAU, 40, UIKit.COBALT, 5.0, true)
		pause_btn.draw_rect(Rect2(c + Vector2(-12, -14), Vector2(8, 28)), UIKit.COBALT)
		pause_btn.draw_rect(Rect2(c + Vector2(4, -14), Vector2(8, 28)), UIKit.COBALT))
	pause_btn.pressed.connect(toggle_pause)
	root.add_child(pause_btn)

	banner = PanelContainer.new()
	var bs := UIKit.panel_style(UIKit.COBALT, UIKit.CREAM, 30, 5)
	bs.content_margin_left = 36
	bs.content_margin_right = 36
	bs.content_margin_top = 10
	bs.content_margin_bottom = 12
	banner.add_theme_stylebox_override("panel", bs)
	banner_label = UIKit.label("", 32, UIKit.CREAM, 800)
	banner.add_child(banner_label)
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner)

	shop = ShopUI.new()
	shop.visible = false
	root.add_child(shop)

	fade = ColorRect.new()
	fade.color = Color(UIKit.NAVY, 1.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.6)
	_build_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if shop and shop.visible:
			shop.closed.emit()
		else:
			toggle_pause()


func _process(delta: float) -> void:
	var vp := get_viewport().get_visible_rect().size
	root.size = vp
	pause_btn.position = Vector2(vp.x - 104, 14)
	action_btn.reset_size()
	action_btn.position = Vector2((vp.x - action_btn.size.x) * 0.5, vp.y - action_btn.size.y - 34)
	banner.position = Vector2((vp.x - banner.size.x) * 0.5, 110)
	if _banner_t > 0.0:
		_banner_t -= delta
		if _banner_t <= 0.0:
			create_tween().tween_property(banner, "modulate:a", 0.0, 0.35)
	icons.queue_redraw()
	if Input.is_action_just_pressed("pause") and not shop.visible:
		toggle_pause()


func _draw_icons() -> void:
	UIKit.draw_fish(icons, Vector2(56, 44), 62, Color("bfe3ee"))
	var w := get_viewport().get_visible_rect().size.x
	var n := kitten_total
	var cx := w * 0.5 - (n - 1) * 30.0
	var cols := {"duman": Color("9aa3ad"), "komur": Color("3a3540"), "pamuk": Color("fbf7f0"), "tekir": Color("a27a52"), "bal": Color("e8c27a")}
	for i in n:
		var found := i < kitten_coats.size()
		var col: Color = cols.get(kitten_coats[i], Color.WHITE) if found else Color(UIKit.NAVY, 0.3)
		UIKit.draw_cat_head(icons, Vector2(cx + i * 60, 44), 40, col, Color(UIKit.CREAM, 0.95) if found else Color(UIKit.CREAM, 0.35), found)


func set_action(text: String, cb: Callable, color := UIKit.CORAL) -> void:
	if action_btn.visible and action_btn.text == text:
		return
	action_btn.text = text
	action_btn.add_theme_stylebox_override("normal", UIKit._btn_style(color, 22, color.darkened(0.3)))
	action_btn.add_theme_stylebox_override("hover", UIKit._btn_style(color.lightened(0.08), 22, color.darkened(0.3)))
	_action_cb = cb
	action_btn.visible = true
	action_btn.pivot_offset = action_btn.size * 0.5
	action_btn.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(action_btn, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func clear_action() -> void:
	action_btn.visible = false
	_action_cb = Callable()


func show_banner(text: String) -> void:
	banner_label.text = text
	banner.reset_size()
	banner.modulate.a = 1.0
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_t = 2.4


func set_gameplay_ui(on: bool) -> void:
	touch.visible = on and (DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"))
	pause_btn.visible = on
	if not on:
		touch.release_all()
		clear_action()


func fade_out_in(t := 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, t)
	await tw.finished
	await get_tree().create_timer(0.15).timeout
	create_tween().tween_property(fade, "color:a", 0.0, t)


func fade_to(a: float, t := 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, t)
	await tw.finished


func _build_pause() -> void:
	pause_panel = Control.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	root.add_child(pause_panel)
	var dim := ColorRect.new()
	dim.color = Color(UIKit.NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.panel_style())
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	var t := UIKit.label("Kedi Evi", 52, UIKit.COBALT, 800)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(UIKit.slider_row("Müzik", GameState.settings["music"], func(x):
		GameState.settings["music"] = x
		GameState.apply_audio()))
	v.add_child(UIKit.slider_row("Efektler", GameState.settings["sfx"], func(x):
		GameState.settings["sfx"] = x
		GameState.apply_audio()))
	v.add_child(UIKit.slider_row("Kamera hızı", GameState.settings["cam_sens"] / 2.0, func(x):
		GameState.settings["cam_sens"] = max(0.2, x * 2.0)))
	v.add_child(UIKit.toggle_row("Titreşim", GameState.settings["vibration"], func(on):
		GameState.settings["vibration"] = on))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var cont := UIKit.button("Devam", UIKit.TURQ, 30, 200)
	cont.pressed.connect(toggle_pause)
	row.add_child(cont)
	var menu := UIKit.button("Ana Menü", UIKit.CORAL, 30, 200)
	menu.pressed.connect(func():
		get_tree().paused = false
		GameState.save_data()
		menu_requested.emit())
	row.add_child(menu)


func toggle_pause() -> void:
	var on := not get_tree().paused
	get_tree().paused = on
	pause_panel.visible = on
	touch.release_all()
	if not on:
		GameState.save_data()
