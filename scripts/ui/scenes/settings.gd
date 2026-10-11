extends BaseScreen
## Settings — müzik/efekt sesi (bağımsız), titreşim, hızlı animasyonlar, nasıl oynanır, kayıt sıfırlama, hakkında.


func _ready() -> void:
	setup_screen("sunburst", Color("#7fd3ff"), Color("#4a7dff"))
	make_header(Loc.t("AYARLAR"), true, false)
	var p := UIKit.panel(UIKit.CREAM, 28, UIKit.INK, 4, 20)
	var v := UIKit.vbox(16)
	p.add_child(v)
	var sc := UIKit.scroll(p)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(sc)
	v.add_child(_language_row())
	v.add_child(_slider_row("music", Loc.t("Müzik"), "music"))
	v.add_child(_slider_row("sfx", Loc.t("Efektler"), "sound"))
	v.add_child(_toggle_row("vibration", Loc.t("Titreşim"), "vibrate"))
	v.add_child(_toggle_row("fast", Loc.t("Hızlı animasyonlar"), "fast"))
	var help := UIKit.button(Loc.t("Nasıl Oynanır?"), UIKit.BLUE, Vector2(0, 80), 28, "info")
	help.pressed.connect(_help)
	v.add_child(help)
	var about := UIKit.button(Loc.t("Hakkında"), UIKit.PURPLE, Vector2(0, 80), 28, "chef")
	about.pressed.connect(_about)
	v.add_child(about)
	var reset := UIKit.button(Loc.t("İlerlemeyi Sıfırla"), UIKit.RED, Vector2(0, 80), 26, "trash")
	reset.pressed.connect(_reset)
	v.add_child(reset)
	v.add_child(UIKit.label(Loc.t("Sürüm %s · İçerik v%d") % [ProjectSettings.get_setting("application/config/version", "1.0"), IngredientDatabase.content_version], 20, Color("#8a6a50")))


func _language_row() -> Control:
	var row := UIKit.hbox(12)
	row.add_child(UIKit.icon("globe", 52))
	var l := UIKit.label(Loc.t("Dil"), 26, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var b := UIKit.button(Loc.NATIVE.get(Loc.lang, Loc.lang), UIKit.BLUE, Vector2(230, 64), 24)
	b.pressed.connect(_pick_language)
	row.add_child(b)
	return row


func _pick_language() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for code in Loc.LANGS:
		var bt := UIKit.button(Loc.NATIVE[code], UIKit.GREEN if code == Loc.lang else UIKit.ORANGE, Vector2(250, 70), 26)
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bt.pressed.connect(_choose_language.bind(code, grid))
		grid.add_child(bt)
	UIKit.modal(self, Loc.t("Dil"), "", [[Loc.t("Kapat"), "close", UIKit.GRAY]], grid)


func _choose_language(code: String, grid: Control) -> void:
	AudioManager.sfx("tap")
	if code == Loc.lang:
		var md := grid.get_parent()
		while md != null and not (md is Modal):
			md = md.get_parent()
		if md != null:
			(md as Modal).close("close")
		return
	Loc.set_language(code)
	GameManager.goto("settings", {}, false)


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
	var b := UIKit.button(Loc.t("AÇIK") if on else Loc.t("KAPALI"), UIKit.GREEN if on else UIKit.GRAY, Vector2(150, 64), 24)
	b.pressed.connect(func():
		var nv := not bool(SaveManager.setting(key, false))
		SaveManager.set_setting(key, nv)
		b.text = Loc.t("AÇIK") if nv else Loc.t("KAPALI")
		UIKit.style_button(b, UIKit.GREEN if nv else UIKit.GRAY, 26, 24)
		if key == "vibration" and nv:
			GameManager.vibrate(60))
	row.add_child(b)
	return row


func _help() -> void:
	var t := Loc.t("1) Kilerden malzemelere dokunarak kaseye ekle.\n2) KARIŞTIR ile füzyon yap: Şeker + Kurbağa Özü = Şeker Kurbağa! Füzyonları tekrar karıştırabilirsin.\n3) Bir pişirme yöntemi seç ve PİŞİR'e bas; zamanlama oyununda iyi dur.\n4) Canlı yemekler kaçabilir: yakala!\n5) Tabak ve süslemeyi temaya göre seç ve SUN.\n6) Üç jüri farklı şeylere bakar: Bruno lezzet, Mira yaratıcılık, Max sunum.\n7) Rakipler sabotaj yapar: Savun, Uyum Sağla ya da Riski Kabul Et.\n8) Bazı yemekler jüriyi mutasyona uğratır ve zevklerini değiştirir!")
	UIKit.modal(self, Loc.t("Nasıl Oynanır?"), t, [[Loc.t("Anladım!"), "close", UIKit.GREEN]])


func _about() -> void:
	var t := Loc.t("FUSE CHEF: Çılgın Mutfak Savaşı\nGodot 4 ile geliştirildi.\nTüm karakterler, görseller, müzik ve sesler bu oyun için özgün olarak üretildi.\nYazı tipi: Baloo 2 (SIL Open Font License).")
	UIKit.modal(self, Loc.t("Hakkında"), t, [[Loc.t("Tamam"), "close", UIKit.GREEN]])


func _reset() -> void:
	var m := UIKit.modal(self, Loc.t("Emin misin?"), Loc.t("Tüm ilerleme, paralar ve tarifler silinecek. Bu işlem geri alınamaz!"), [[Loc.t("Vazgeç"), "no", UIKit.GRAY], [Loc.t("Sil"), "yes", UIKit.RED]])
	var ch: String = await m.closed
	if ch != "yes":
		return
	var m2 := UIKit.modal(self, Loc.t("Son Onay"), Loc.t("Gerçekten her şeyi sıfırlamak istiyor musun?"), [[Loc.t("Hayır"), "no", UIKit.GREEN], [Loc.t("Evet, sıfırla"), "yes", UIKit.RED]])
	var ch2: String = await m2.closed
	if ch2 == "yes":
		SaveManager.reset_all()
		RecipeBookManager._sync_registry()
		AudioManager.apply_volumes()
		GameManager.reset_history()
		GameManager.goto("boot", {}, false)
