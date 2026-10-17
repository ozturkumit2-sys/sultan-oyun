extends Node3D
## Title screen: Tarçın sits on a Galata rooftop at sunset while the camera drifts.

var cam: Camera3D
var cat: CatVisual
var t := 0.0
var ui: CanvasLayer
var main_box: VBoxContainer
var settings_panel: Control
var howto_panel: Control
var title: Label
var city: City


func _ready() -> void:
	var q: int = GameState.settings["quality"]
	WorldEnv.make_environment(self, q)
	WorldEnv.make_sea(self)
	city = City.new(self, 3)
	city.ground_fn = func(z: float) -> float: return 0.0 if z > 0.0 else min(8.0, -z * 0.12)
	_build_scene()
	WorldEnv.make_skyline(city)
	city.commit(self)
	cat = CatVisual.new()
	add_child(cat)
	cat.position = Vector3(0.6, 9.0, 3.0)
	cat.rotation.y = PI * 0.12
	cat.sitting = true
	cat.scale = Vector3.ONE * 1.1
	cam = Camera3D.new()
	cam.fov = 50
	cam.far = 900
	add_child(cam)
	_build_ui()
	Sfx.play_music("res://assets/audio/music_menu.ogg", -8.0)
	Sfx.stop_ambience()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if settings_panel and settings_panel.visible:
			settings_panel.visible = false
		elif howto_panel and howto_panel.visible:
			howto_panel.visible = false
		else:
			GameState.save_data()
			get_tree().quit()


func _build_scene() -> void:
	# a rooftop for the cat, and the hill rising towards Galata Tower
	city.house(0.0, 0.0, 9.0, 7.0, 9.0, {"hex": "f0c9a8", "detail": true})
	city.water_tank(Vector3(-2.8, 9.0, -1.5), false)
	city.antenna(Vector3(3.0, 9.0, -2.0))
	city.clothesline(Vector3(-4.0, 10.4, 2.5), Vector3(-4.0, 10.4, -2.8), false, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 70:
		var x := rng.randf_range(-70, 70)
		var z := rng.randf_range(-90, -8)
		if abs(x) < 6 and z > -14:
			continue
		var top := city.ground(z) + rng.randf_range(6, 12)
		city.house(x, z, rng.randf_range(6, 9), rng.randf_range(6, 9), top, {"roof": ["hip", "flat", "gable_x"][i % 3], "detail": abs(x) < 35, "collide": false, "props": true})
	# Galata Tower silhouette in the distance
	var c := Vector3(-14.0, 8.0, -70.0)
	city.at(c)
	city.mb("stone").cylinder(c, 5.0, 24.0, City.lin("cdbfae"), 24, false)
	city.mb("stone").cylinder(c + Vector3(0, 23.6, 0), 6.4, 0.45, City.lin("e3d7c7"), 24)
	city.mb("stone").cylinder(c + Vector3(0, 24.0, 0), 4.3, 3.6, City.lin("e8ddd0"), 24, false)
	for k in 12:
		var a := TAU * k / 12.0
		var n := Vector3(cos(a), 0, sin(a))
		var p := c + Vector3(0, 25.6, 0) + n * 4.32
		var u := n.cross(Vector3.UP).normalized()
		city.mb("lit").quad(p - u * 0.4 - Vector3(0, 0.9, 0), p + u * 0.4 - Vector3(0, 0.9, 0), p + u * 0.4 + Vector3(0, 0.9, 0), p - u * 0.4 + Vector3(0, 0.9, 0), City.lin("ffcf7a"))
	city.mb("roof").cone(c + Vector3(0, 27.6, 0), 4.6, 9.0, City.lin("6f7e8f"), 24)


func _process(delta: float) -> void:
	t += delta
	var a := 0.35 + sin(t * 0.08) * 0.28
	var target := cat.position + Vector3(0, 0.75, 0)
	cam.position = target + Vector3(sin(a) * 4.3, 0.9 + sin(t * 0.13) * 0.2, cos(a) * 4.3)
	cam.look_at(target + Vector3(0, 0.6, 0))
	cam.h_offset = -1.55
	cam.v_offset = 0.25
	if title:
		title.pivot_offset = title.size * 0.5
		title.rotation = sin(t * 1.2) * 0.012


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	# soft gradient for legibility on the left
	var grad := TextureRect.new()
	var gt := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color(UIKit.NAVY, 0.55))
	g.set_color(1, Color(UIKit.NAVY, 0.0))
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	grad.texture = gt
	grad.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	grad.custom_minimum_size = Vector2(760, 0)
	grad.size = Vector2(760, 720)
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(grad)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	root.add_child(margin)
	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 14)
	main_box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(main_box)
	var small := UIKit.label("İSTANBUL", 30, UIKit.GOLD, 800, 10, UIKit.NAVY)
	main_box.add_child(small)
	title = UIKit.label("Çatı Kedisi", 104, UIKit.CREAM, 800, 26, UIKit.COBALT)
	main_box.add_child(title)
	var sub := UIKit.label("Tarçın'la Galata'nın çatılarında koş, zıpla,\nkayıp yavruları kurtar.", 26, UIKit.CREAM, 600, 8, UIKit.NAVY)
	main_box.add_child(sub)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 16)
	main_box.add_child(sp)
	var play := UIKit.button("Oyna", UIKit.CORAL, 44, 320)
	play.pressed.connect(_play)
	main_box.add_child(play)
	var howto := UIKit.button("Nasıl Oynanır?", UIKit.COBALT, 30, 320)
	howto.pressed.connect(func(): howto_panel.visible = true)
	main_box.add_child(howto)
	var sett := UIKit.button("Ayarlar", UIKit.TURQ, 30, 320)
	sett.pressed.connect(func(): settings_panel.visible = true)
	main_box.add_child(sett)
	var best: Dictionary = GameState.best.get("galata", {})
	if not best.is_empty():
		var rec := UIKit.label("En iyi: %d balık · %d/5 yavru · %s" % [best.get("fish", 0), best.get("kittens", 0), GameState.format_time(best.get("time", 0.0))], 24, UIKit.SAND, 700, 8, UIKit.NAVY)
		main_box.add_child(rec)
	settings_panel = _panel_settings()
	root.add_child(settings_panel)
	howto_panel = _panel_howto()
	root.add_child(howto_panel)


func _overlay() -> Array:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	var dim := ColorRect.new()
	dim.color = Color(UIKit.NAVY, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(cc)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.panel_style())
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	return [c, v]


func _panel_settings() -> Control:
	var o := _overlay()
	var v: VBoxContainer = o[1]
	var t := UIKit.label("Ayarlar", 50, UIKit.COBALT, 800)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(UIKit.slider_row("Müzik", GameState.settings["music"], func(x):
		GameState.settings["music"] = x
		GameState.apply_audio()))
	v.add_child(UIKit.slider_row("Efektler", GameState.settings["sfx"], func(x):
		GameState.settings["sfx"] = x
		GameState.apply_audio()
		Sfx.play("fish", 1.0, -6.0)))
	v.add_child(UIKit.slider_row("Kamera hızı", GameState.settings["cam_sens"] / 2.0, func(x):
		GameState.settings["cam_sens"] = max(0.2, x * 2.0)))
	v.add_child(UIKit.toggle_row("Titreşim", GameState.settings["vibration"], func(on):
		GameState.settings["vibration"] = on))
	v.add_child(UIKit.toggle_row("Yüksek grafik", GameState.settings["quality"] > 0, func(on):
		GameState.settings["quality"] = 1 if on else 0))
	var close := UIKit.button("Tamam", UIKit.CORAL, 32, 220)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func():
		GameState.save_data()
		o[0].visible = false)
	v.add_child(close)
	return o[0]


func _panel_howto() -> Control:
	var o := _overlay()
	var v: VBoxContainer = o[1]
	var t := UIKit.label("Nasıl Oynanır?", 48, UIKit.COBALT, 800)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var lines := [
		"Sol tarafta parmağını kaydır: Tarçın koşar.",
		"Pati düğmesi: zıpla. Havadayken tekrar bas: çift zıplama.",
		"Ok düğmesi: atıl. Uzak boşlukları geçer, martıları kovalar.",
		"Duvara doğru düşerken zıpla: duvar zıplaması.",
		"Sağ tarafta kaydır: kamerayı çevir.",
		"Balıkları topla, 5 kayıp yavruyu bul, Galata Kulesi'ne çık!",
	]
	for l in lines:
		var lb := UIKit.label("•  " + l, 26, UIKit.NAVY, 600)
		v.add_child(lb)
	var close := UIKit.button("Anladım", UIKit.CORAL, 32, 220)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func(): o[0].visible = false)
	v.add_child(close)
	return o[0]


func _play() -> void:
	Sfx.play("whoosh", 1.0, -4.0)
	var fade := ColorRect.new()
	fade.color = Color(UIKit.NAVY, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.45)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")
