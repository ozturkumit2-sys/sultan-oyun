extends Control
## Ana menü: devam et, yeni oyun, kayıt yükle, ayarlar, hakkında.

var menu_box: VBoxContainer
var layer: Control


func _ready() -> void:
	theme = UI.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	GameState.active = false
	GameState.clear_pauses()
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/menu_bg.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.02, 0.03, 0.08, 0.85))
	grad.set_color(1, Color(0.02, 0.03, 0.08, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0.5)
	gt.fill_to = Vector2(0.75, 0.5)
	gt.width = 256
	gt.height = 16
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var v := UI.vbox(10)
	v.position = Vector2(80, 60)
	v.custom_minimum_size = Vector2(520, 0)
	add_child(v)
	UI.fonts()
	var t := UI.label("SULTAN", 92, UI.GOLD2, UI.font_logo)
	t.add_theme_constant_override("shadow_offset_x", 3)
	t.add_theme_constant_override("shadow_offset_y", 3)
	v.add_child(t)
	var st := UI.label("Hanedanın Kaderi", 44, UI.CREAM, UI.font_title)
	v.add_child(st)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 26)
	v.add_child(sp)
	menu_box = UI.vbox(12)
	v.add_child(menu_box)
	layer = Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	var ver := UI.label("Sürüm %s — Zehrâni İmparatorluğu tamamen kurgusaldır." % GameState.GAME_VERSION, 16, UI.MUTED)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.offset_left = 20
	ver.offset_top = -34
	add_child(ver)
	_build_menu()
	AudioManager.play_music("theme")
	AudioManager.set_ambient("")


func _build_menu() -> void:
	UI.clear(menu_box)
	if SaveSystem.has_any_save():
		var last := SaveSystem.latest_slot()
		var hd := SaveSystem.read_header(last)
		var cont := UI.button("Devam Et  —  %s" % hd.get("summary", ""), func(): _load(last), 66, true)
		cont.custom_minimum_size.x = 520
		menu_box.add_child(cont)
	for item in [["Yeni Saltanat", _new_game_panel], ["Kayıt Yükle", _load_panel], ["Ayarlar", _settings], ["Hakkında", _about], ["Çıkış", func(): get_tree().quit()]]:
		var b := UI.button(item[0], item[1], 62)
		b.custom_minimum_size.x = 520
		menu_box.add_child(b)


func _new_game_panel() -> void:
	var p := NewGamePanel.new()
	layer.add_child(p)
	p.open(self)


func _load_panel() -> void:
	var p := SaveLoadPanel.new()
	p.pause_time = false
	layer.add_child(p)
	p.open(false)
	p.loaded.connect(_load)


func _settings() -> void:
	var p := SettingsPanel.new()
	layer.add_child(p)
	p.open()


func _about() -> void:
	var p := AboutPanel.new()
	layer.add_child(p)
	p.open()


func start_new(sultan_name: String, difficulty: int) -> void:
	GameState.new_game(sultan_name, difficulty)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _load(slot: String) -> void:
	if SaveSystem.load_game(slot):
		get_tree().change_scene_to_file("res://scenes/game.tscn")


class NewGamePanel:
	extends BasePanel
	var menu: Node
	var name_edit: LineEdit
	var diff := 1
	var diff_btns: Array = []
	var desc: Label

	func open(m: Node) -> void:
		menu = m
		pause_time = false
		setup_frame("Yeni Saltanat", 0.62, 0.86)
		body.add_child(UI.wrap_label("Babanız Sultan Cem'in ani ölümünün ardından, yirmi yedi yaşında Zehrâni tahtına çıkıyorsunuz. Başkent Şahriyar'daki saray; entrikaları, sırları ve sadakatleriyle sizi bekliyor.", 20, UI.CREAM))
		body.add_child(UI.label("Hükümdarın adı", 20, UI.GOLD2))
		name_edit = LineEdit.new()
		name_edit.text = "Kayhan"
		name_edit.max_length = 18
		name_edit.custom_minimum_size = Vector2(0, 58)
		body.add_child(name_edit)
		body.add_child(UI.label("Zorluk", 20, UI.GOLD2))
		var row := UI.hbox(8)
		body.add_child(row)
		var names := ["Kolay", "Normal", "Zor"]
		for i in range(3):
			var ii := i
			var b := UI.button(names[i], func(): _set_diff(ii), 56)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)
			diff_btns.append(b)
		desc = UI.wrap_label("", 18, UI.MUTED)
		body.add_child(desc)
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.add_child(spacer)
		body.add_child(UI.button("Saltanatı Başlat", _start, 66, true))
		_set_diff(1)

	func _set_diff(i: int) -> void:
		diff = i
		for k in range(diff_btns.size()):
			var b: Button = diff_btns[k]
			if k == i:
				b.add_theme_stylebox_override("normal", UI.sb(UI.EMERALD, UI.GOLD2, 2, 10, 14))
			else:
				b.remove_theme_stylebox_override("normal")
		desc.text = ["Dolu bir hazine (240.000 akçe) ve huzurlu eyaletler.", "Dengeli bir başlangıç (160.000 akçe).", "Boşalmış bir hazine (95.000 akçe), aç ve huzursuz eyaletler."][i]

	func _start() -> void:
		var n := name_edit.text.strip_edges()
		if n == "":
			n = "Kayhan"
		menu.start_new(n, diff)


class AboutPanel:
	extends BasePanel

	func open() -> void:
		pause_time = false
		setup_frame("Hakkında", 0.7, 0.84)
		var sc := UI.scroll()
		body.add_child(sc)
		var v := UI.vbox(10)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(v)
		v.add_child(UI.wrap_label("SULTAN: Hanedanın Kaderi — Osmanlı saray kültüründen esinlenen, tamamen kurgusal Zehrâni İmparatorluğu'nda geçen bir saray ve hanedan simülasyonu.", 20, UI.CREAM))
		v.add_child(UI.wrap_label("Godot 4 ile geliştirildi. Saray mimarisi, dokular, karakter modelleri, sesler ve müzik bu oyun için prosedürel olarak sıfırdan üretilmiştir.", 19, UI.TEXT))
		v.add_child(UI.wrap_label("Yazı tipleri: Fira Sans, Cormorant Garamond ve Cinzel Decorative — SIL Open Font License ile.", 18, UI.MUTED))
		v.add_child(UI.wrap_label("İnsan modelleri MakeHuman projesinin CC0 (kamu malı) taban ağı, iskeleti ve gövde hedeflerinden üretildi; kıyafetler, başlıklar ve dokular bu oyun için özgün olarak hazırlandı.", 18, UI.MUTED))
		v.add_child(UI.wrap_label("Tüm karakterler, devletler ve olaylar hayal ürünüdür.", 18, UI.MUTED))
