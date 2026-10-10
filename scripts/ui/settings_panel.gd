class_name SettingsPanel
extends BasePanel
## Ayarlar: grafik kalitesi, ses, kamera hassasiyeti, otomatik kayıt.

var on_apply: Callable


func open(apply_cb: Callable = Callable()) -> void:
	on_apply = apply_cb
	pause_time = true
	setup_frame("Ayarlar", 0.7, 0.86)
	var sc := UI.scroll()
	body.add_child(sc)
	var v := UI.vbox(14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	v.add_child(UI.label("Grafik kalitesi", 22, UI.GOLD2, UI.font_semi))
	var q := UI.hbox(8)
	v.add_child(q)
	for i in range(3):
		var ii := i
		var b := UI.button(Settings.QUALITY_NAMES[i], func(): _set_q(ii), 54, i == Settings.quality)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		q.add_child(b)
	v.add_child(UI.wrap_label("Düşük: gölgesiz, düşük çözünürlük (zayıf telefonlar). Orta: önerilen. Yüksek: kenar yumuşatma ve uzak gölgeler.", 17, UI.MUTED))
	v.add_child(_slider("Müzik", Settings.music_vol, func(x): Settings.set_value("music_vol", x)))
	v.add_child(_slider("Efektler", Settings.sfx_vol, func(x): Settings.set_value("sfx_vol", x)))
	v.add_child(_slider("Kamera hassasiyeti", Settings.cam_sens / 2.0, func(x): Settings.set_value("cam_sens", maxf(0.2, x * 2.0))))
	v.add_child(_check("Kamerada dikey ekseni ters çevir", Settings.invert_y, func(x): Settings.set_value("invert_y", x)))
	v.add_child(_check("Kare hızını (FPS) göster", Settings.show_fps, func(x): Settings.set_value("show_fps", x)))
	v.add_child(_check("Otomatik kayıt (her sabah ve uygulamadan çıkarken)", Settings.autosave, func(x): Settings.set_value("autosave", x)))


func _set_q(i: int) -> void:
	Settings.set_value("quality", i)
	if on_apply.is_valid():
		on_apply.call()
	close_panel()


func _slider(name: String, val: float, cb: Callable) -> Control:
	var h := UI.hbox(12)
	var l := UI.label(name, 20)
	l.custom_minimum_size = Vector2(240, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = val
	s.custom_minimum_size = Vector2(0, 48)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(cb)
	h.add_child(s)
	return h


func _check(name: String, val: bool, cb: Callable) -> Control:
	var c := CheckButton.new()
	c.text = name
	c.button_pressed = val
	c.custom_minimum_size = Vector2(0, 52)
	c.focus_mode = Control.FOCUS_NONE
	c.toggled.connect(cb)
	return c
