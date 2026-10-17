extends CanvasLayer
## In-game HUD: fish counter, paws (health), rescued kittens, banners, pause & results.

signal restart_requested
signal menu_requested

var root: Control
var fish_label: Label
var fish_total_label: Label
var icons: Control
var banner: PanelContainer
var banner_label: Label
var fade: ColorRect
var pause_panel: Control
var results_panel: Control
var touch: Control
var pause_btn: Button
var hint_label: Label
var _fish_pop := 0.0
var _kitten_pop := 0.0
var _health_pop := 0.0
var _banner_t := 0.0


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

	# icon layer (drawn)
	icons = Control.new()
	icons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.draw.connect(_draw_icons)
	root.add_child(icons)

	fish_label = UIKit.label("0", 44, UIKit.CREAM, 800, 12, UIKit.NAVY)
	fish_label.position = Vector2(96, 10)
	root.add_child(fish_label)
	fish_total_label = UIKit.label("/0", 24, UIKit.SAND, 700, 8, UIKit.NAVY)
	root.add_child(fish_total_label)

	hint_label = UIKit.label("", 26, UIKit.CREAM, 700, 10, UIKit.NAVY)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint_label)

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

	# banner
	banner = PanelContainer.new()
	var bs := UIKit.panel_style(UIKit.COBALT, UIKit.CREAM, 30, 5)
	bs.content_margin_left = 36
	bs.content_margin_right = 36
	bs.content_margin_top = 10
	bs.content_margin_bottom = 12
	banner.add_theme_stylebox_override("panel", bs)
	banner_label = UIKit.label("", 34, UIKit.CREAM, 800)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(banner_label)
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner)

	fade = ColorRect.new()
	fade.color = Color(UIKit.NAVY, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)

	_build_pause()
	_build_results()

	GameState.fish_changed.connect(func(n):
		fish_label.text = str(n)
		_fish_pop = 1.0)
	GameState.kittens_changed.connect(func(_n):
		_kitten_pop = 1.0)
	GameState.health_changed.connect(func(_h):
		_health_pop = 1.0)
	GameState.message.connect(show_banner)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if results_panel and not results_panel.visible:
			toggle_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if results_panel and not results_panel.visible and not get_tree().paused:
			toggle_pause()


func set_totals(total: int) -> void:
	fish_total_label.text = "/%d" % total


func _process(delta: float) -> void:
	_fish_pop = max(0.0, _fish_pop - delta * 4.0)
	_kitten_pop = max(0.0, _kitten_pop - delta * 2.0)
	_health_pop = max(0.0, _health_pop - delta * 3.0)
	var s := 1.0 + 0.25 * sin(_fish_pop * PI)
	fish_label.pivot_offset = fish_label.size * 0.5
	fish_label.scale = Vector2(s, s)
	fish_total_label.position = fish_label.position + Vector2(fish_label.size.x + 4, 18)
	if _banner_t > 0.0:
		_banner_t -= delta
		if _banner_t <= 0.0:
			var tw := create_tween()
			tw.tween_property(banner, "modulate:a", 0.0, 0.35)
	var vp := get_viewport().get_visible_rect().size
	root.size = vp
	pause_btn.position = Vector2(vp.x - 104, 14)
	banner.position = Vector2((vp.x - banner.size.x) * 0.5, 104)
	icons.queue_redraw()
	if Input.is_action_just_pressed("pause") and not results_panel.visible:
		toggle_pause()


func _draw_icons() -> void:
	var s := 1.0 + 0.3 * sin(_fish_pop * PI)
	UIKit.draw_fish(icons, Vector2(56, 44), 62 * s, Color("bfe3ee"))
	# health paws
	for i in GameState.max_health:
		var full := i < GameState.health
		var c := UIKit.CORAL if full else Color(UIKit.NAVY, 0.35)
		var ps := 30.0 * (1.0 + (0.25 * sin(_health_pop * PI) if i == GameState.health else 0.0))
		UIKit.draw_paw(icons, Vector2(42 + i * 46, 108), ps, c, Color(UIKit.CREAM, 0.95) if full else Color(UIKit.CREAM, 0.4))
	# kittens
	var n := GameState.KITTEN_TOTAL
	var w := get_viewport().get_visible_rect().size.x
	var cx := w * 0.5 - (n - 1) * 30.0
	var coats := ["duman", "komur", "pamuk", "tekir", "bal"]
	var cols := {"duman": Color("9aa3ad"), "komur": Color("3a3540"), "pamuk": Color("fbf7f0"), "tekir": Color("a27a52"), "bal": Color("e8c27a")}
	for i in n:
		var found := i < GameState.kittens_found.size()
		var col: Color = cols[coats[i]] if found else Color(UIKit.NAVY, 0.3)
		var pop := 1.0 + (0.35 * sin(_kitten_pop * PI) if found and i == GameState.kittens_found.size() - 1 else 0.0)
		UIKit.draw_cat_head(icons, Vector2(cx + i * 60, 44), 40 * pop, col, Color(UIKit.CREAM, 0.95) if found else Color(UIKit.CREAM, 0.35), found)


func show_banner(text: String, _kind := "") -> void:
	banner_label.text = text
	banner.reset_size()
	banner.modulate.a = 1.0
	banner.pivot_offset = banner.size * 0.5
	banner.scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_t = 2.6


func show_hint(text: String) -> void:
	hint_label.text = text
	hint_label.reset_size()
	var vp := get_viewport().get_visible_rect().size
	hint_label.position.x = (vp.x - hint_label.size.x) * 0.5
	hint_label.position.y = vp.y - 150
	hint_label.modulate.a = 1.0


func hide_hint() -> void:
	var tw := create_tween()
	tw.tween_property(hint_label, "modulate:a", 0.0, 0.4)


func fade_out_in(t := 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, t)
	await tw.finished
	await get_tree().create_timer(0.15).timeout
	var tw2 := create_tween()
	tw2.tween_property(fade, "color:a", 0.0, t)


func fade_to(a: float, t := 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", a, t)
	await tw.finished


# ---------------------------------------------------------------- pause
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
	var t := UIKit.label("Mola", 52, UIKit.COBALT, 800)
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
	if results_panel.visible:
		return
	var on := not get_tree().paused
	get_tree().paused = on
	pause_panel.visible = on
	touch.release_all()
	if not on:
		GameState.save_data()


# ---------------------------------------------------------------- results
var res_fish: Label
var res_kittens: Label
var res_time: Label
var res_title: Label


func _build_results() -> void:
	results_panel = Control.new()
	results_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_panel.visible = false
	root.add_child(results_panel)
	var dim := ColorRect.new()
	dim.color = Color(UIKit.NAVY, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_panel.add_child(center)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.panel_style())
	center.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	res_title = UIKit.label("Galata'nın Zirvesinde!", 50, UIKit.COBALT, 800)
	res_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(res_title)
	var sub := UIKit.label("Tarçın kulenin tepesine ulaştı.", 26, UIKit.NAVY, 600)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	res_fish = UIKit.label("", 34, UIKit.NAVY, 800)
	res_kittens = UIKit.label("", 34, UIKit.NAVY, 800)
	res_time = UIKit.label("", 34, UIKit.NAVY, 800)
	for l in [res_fish, res_kittens, res_time]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var teaser := UIKit.label("Sıradaki durak: Kapalıçarşı (yakında)", 22, UIKit.TURQ, 700)
	teaser.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(teaser)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var again := UIKit.button("Tekrar Oyna", UIKit.TURQ, 30, 230)
	again.pressed.connect(func():
		get_tree().paused = false
		restart_requested.emit())
	row.add_child(again)
	var menu := UIKit.button("Ana Menü", UIKit.CORAL, 30, 200)
	menu.pressed.connect(func():
		get_tree().paused = false
		menu_requested.emit())
	row.add_child(menu)


func show_results(info: Dictionary) -> void:
	touch.release_all()
	touch.visible = false
	pause_btn.visible = false
	res_fish.text = "Balık: %d / %d" % [GameState.fish, GameState.fish_total]
	res_kittens.text = "Kurtarılan yavru: %d / %d" % [GameState.kittens_found.size(), GameState.KITTEN_TOTAL]
	res_time.text = "Süre: %s%s" % [GameState.format_time(GameState.run_time), "  —  Yeni rekor!" if info.get("record", false) else ""]
	results_panel.visible = true
	results_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(results_panel, "modulate:a", 1.0, 0.5)
