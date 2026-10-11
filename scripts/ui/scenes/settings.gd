extends BaseScreen
## Settings — müzik/efekt sesi (bağımsız), titreşim, hızlı animasyonlar, nasıl oynanır, kayıt sıfırlama, hakkında.


func _ready() -> void:
	setup_screen("sunburst", Color("#7fd3ff"), Color("#4a7dff"))
	make_header("AYARLAR", true, false)
	var p := UIKit.panel(UIKit.CREAM, 28, UIKit.INK, 4, 20)
	var v := UIKit.vbox(16)
	p.add_child(v)
	var sc := UIKit.scroll(p)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(sc)
	v.add_child(_slider_row("music", "Müzik", "music"))
	v.add_child(_slider_row("sfx", "Efektler", "sound"))
	v.add_child(_toggle_row("vibration", "Titreşim", "vibrate"))
	v.add_child(_toggle_row("fast", "Hızlı animasyonlar", "fast"))
	var help := UIKit.button("Nasıl Oynanır?", UIKit.BLUE, Vector2(0, 80), 28, "info")
	help.pressed.connect(_help)
	v.add_child(help)
	var about := UIKit.button("Hakkında", UIKit.PURPLE, Vector2(0, 80), 28, "chef")
	about.pressed.connect(_about)
	v.add_child(about)
	var reset := UIKit.button("İlerlemeyi Sıfırla", UIKit.RED, Vector2(0, 80), 26, "trash")
	reset.pressed.connect(_reset)
	v.add_child(reset)
	v.add_child(UIKit.label("Sürüm %s · İçerik v%d" % [ProjectSettings.get_setting("application/config/version", "1.0"), IngredientDatabase.content_version], 20, Color("#8a6a50")))


func _slider_row(key: String, title_text: String, icon_name: String) -> Control:
	var row := UIKit.hbox(12)
	row.add_child(UIKit.icon(icon_name, 52))
	var l := UIKit.label(title_text, 26, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 150
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(SaveManager.setting(key, 0.8))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size.y = 50
	s.value_changed.connect(func(val: float):
		SaveManager.set_setting(key, val)
		AudioManager.apply_volumes()
		if key == "sfx":
			AudioManager.sfx("tap"))
	row.add_child(s)
	return row


func _toggle_row(key: String, title_text: String, icon_name: String) -> Control:
	var row := UIKit.hbox(12)
	row.add_child(UIKit.icon(icon_name, 52))
	var l := UIKit.label(title_text, 26, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var on := bool(SaveManager.setting(key, false))
	var b := UIKit.button("AÇIK" if on else "KAPALI", UIKit.GREEN if on else UIKit.GRAY, Vector2(150, 64), 24)
	b.pressed.connect(func():
		var nv := not bool(SaveManager.setting(key, false))
		SaveManager.set_setting(key, nv)
		b.text = "AÇIK" if nv else "KAPALI"
		UIKit.style_button(b, UIKit.GREEN if nv else UIKit.GRAY, 26, 24)
		if key == "vibration" and nv:
			GameManager.vibrate(60))
	row.add_child(b)
	return row


func _help() -> void:
	var t := "1) Kilerden malzemelere dokunarak kaseye ekle.\n2) KARIŞTIR ile füzyon yap: Şeker + Kurbağa Özü = Şeker Kurbağa! Füzyonları tekrar karıştırabilirsin.\n3) Bir pişirme yöntemi seç ve PİŞİR'e bas; zamanlama oyununda iyi dur.\n4) Canlı yemekler kaçabilir: yakala!\n5) Tabak ve süslemeyi temaya göre seç ve SUN.\n6) Üç jüri farklı şeylere bakar: Bruno lezzet, Mira yaratıcılık, Max sunum.\n7) Rakipler sabotaj yapar: Savun, Uyum Sağla ya da Riski Kabul Et.\n8) Bazı yemekler jüriyi mutasyona uğratır ve zevklerini değiştirir!"
	UIKit.modal(self, "Nasıl Oynanır?", t, [["Anladım!", "close", UIKit.GREEN]])


func _about() -> void:
	var t := "FUSE CHEF: Çılgın Mutfak Savaşı\nGodot 4 ile geliştirildi.\nTüm karakterler, görseller, müzik ve sesler bu oyun için özgün olarak üretildi.\nYazı tipi: Baloo 2 (SIL Open Font License)."
	UIKit.modal(self, "Hakkında", t, [["Tamam", "close", UIKit.GREEN]])


func _reset() -> void:
	var m := UIKit.modal(self, "Emin misin?", "Tüm ilerleme, paralar ve tarifler silinecek. Bu işlem geri alınamaz!", [["Vazgeç", "no", UIKit.GRAY], ["Sil", "yes", UIKit.RED]])
	var ch: String = await m.closed
	if ch != "yes":
		return
	var m2 := UIKit.modal(self, "Son Onay", "Gerçekten her şeyi sıfırlamak istiyor musun?", [["Hayır", "no", UIKit.GREEN], ["Evet, sıfırla", "yes", UIKit.RED]])
	var ch2: String = await m2.closed
	if ch2 == "yes":
		SaveManager.reset_all()
		RecipeBookManager._sync_registry()
		AudioManager.apply_volumes()
		GameManager.reset_history()
		GameManager.goto("boot", {}, false)
