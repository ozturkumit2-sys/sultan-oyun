extends BaseScreen
## ChefCustomization — şef oluşturma ve özelleştirme: görünüm, kıyafet, uzmanlık ağacı, asistan.

var first_run := false
var preview: CharacterFigure
var tab := "look"
var content: VBoxContainer
var name_edit: LineEdit
var _tab_btns: Dictionary = {}
var _sp_label: Label


func _ready() -> void:
	first_run = bool(GameManager.params.get("first", false))
	setup_screen("sunburst", Color("#7fd3ff"), Color("#a25cff"))
	make_header(Loc.t("ŞEF OLUŞTUR") if first_run else Loc.t("ŞEFİM"), not first_run, true)
	# önizleme
	var top := UIKit.hbox(12)
	root_v.add_child(top)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(300, 330)
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	top.add_child(stage)
	var n := Node2D.new()
	stage.add_child(n)
	preview = CharacterFigure.new()
	preview.scale = Vector2(0.95, 0.95)
	preview.position = Vector2(150, 330)
	n.add_child(preview)
	stage.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			preview.react(["cheer", "laugh", "love", "smug", "surprised"][randi() % 5]))
	var info := UIKit.vbox(8)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	info.add_child(UIKit.label(Loc.t("Şef Adı"), 22, Color.WHITE))
	name_edit = LineEdit.new()
	name_edit.text = SaveManager.player_name()
	name_edit.max_length = 14
	name_edit.custom_minimum_size = Vector2(0, 64)
	name_edit.text_changed.connect(func(t: String):
		SaveManager.data["profile"]["name"] = t.strip_edges() if t.strip_edges() != "" else "Şef"
		SaveManager.mark_dirty())
	info.add_child(name_edit)
	var lv := UIKit.label(Loc.t("Seviye %d") % ProgressionManager.level(), 26, Color.WHITE)
	info.add_child(UIKit.outlined(lv, UIKit.INK, 6))
	_sp_label = UIKit.label("", 22, Color("#fff1a8"))
	info.add_child(UIKit.outlined(_sp_label, UIKit.INK, 6))
	var rnd := UIKit.button(Loc.t("Rastgele"), UIKit.PINK, Vector2(0, 64), 24, "refresh")
	rnd.pressed.connect(_randomize)
	info.add_child(rnd)
	# sekmeler
	var tabs := UIKit.hbox(6)
	root_v.add_child(tabs)
	for t in [["look", Loc.t("Görünüm")], ["outfit", Loc.t("Kıyafet")], ["spec", Loc.t("Uzmanlık")], ["assist", Loc.t("Asistan")]]:
		var b := UIKit.button(t[1], Color("#c9b8a6"), Vector2(0, 60), 22)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key: String = t[0]
		b.pressed.connect(func(): _set_tab(key))
		tabs.add_child(b)
		_tab_btns[key] = b
	var panel := UIKit.panel(UIKit.CREAM, 26, UIKit.INK, 4, 14)
	content = UIKit.vbox(12)
	panel.add_child(content)
	var sc := UIKit.scroll(panel)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(sc)
	if first_run:
		var go := UIKit.button(Loc.t("BAŞLA!"), UIKit.GREEN, Vector2(0, 92), 36, "play")
		go.pressed.connect(func():
			SaveManager.data["profile"]["created"] = true
			SaveManager.mark_dirty(true)
			GameManager.toast(Loc.t("Hoş geldin, %s!") % SaveManager.player_name(), UIKit.GREEN, "chef")
			GameManager.goto("career", {}, false))
		root_v.add_child(go)
	_refresh_preview()
	_set_tab("look")


func _refresh_preview() -> void:
	preview.setup(CharacterFigure.chef_spec(ProgressionManager.chef()))
	_sp_label.text = Loc.t("Uzmanlık puanı: %d") % ProgressionManager.skill_points()


func _set_tab(t: String) -> void:
	tab = t
	for k in _tab_btns.keys():
		UIKit.style_button(_tab_btns[k], UIKit.ORANGE if k == t else Color("#c9b8a6"), 26, 22)
	for c in content.get_children():
		c.queue_free()
	match t:
		"look":
			_swatches(Loc.t("Ten Rengi"), "skin", IngredientDatabase.content.get("skin_tones", []))
			_options(Loc.t("Saç Modeli"), "hair")
			_swatches(Loc.t("Saç Rengi"), "hair_color", IngredientDatabase.content.get("hair_colors", []))
			_options(Loc.t("İfade"), "expression")
		"outfit":
			_options(Loc.t("Şapka"), "hat")
			_options(Loc.t("Ceket"), "jacket")
			_options(Loc.t("Önlük"), "apron")
			_options(Loc.t("Aksesuar"), "accessory")
		"spec":
			_specs()
		"assist":
			_assistants()


func _section(title_text: String) -> void:
	content.add_child(UIKit.label(title_text, 26, Color("#8a5a3b"), true, HORIZONTAL_ALIGNMENT_LEFT))


func _swatches(title_text: String, key: String, colors: Array) -> void:
	_section(title_text)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	content.add_child(flow)
	var cur := int(ProgressionManager.chef().get(key, 0))
	for i in colors.size():
		var card := TapCard.new()
		card.custom_minimum_size = Vector2(70, 70)
		card.set_colors(Color(colors[i]))
		card.selected = i == cur
		var ii := i
		card.tapped.connect(func():
			ProgressionManager.set_chef_value(key, ii)
			_refresh_preview()
			preview.react("jump")
			_set_tab(tab))
		flow.add_child(card)


func _options(title_text: String, slot: String) -> void:
	_section(title_text)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	content.add_child(flow)
	var cur: String = ProgressionManager.chef().get(slot, "")
	for c in IngredientDatabase.cosmetic_list(slot):
		var id: String = c["id"]
		var owned := ProgressionManager.owns(slot, id)
		if c.has("secret") and not owned:
			continue
		var card := TapCard.new()
		card.custom_minimum_size = Vector2(160, 64)
		var h := UIKit.hbox(6)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(h)
		if c.has("color") and str(c["color"]) != "":
			var dot := ColorRect.new()
			dot.color = Color(c["color"])
			dot.custom_minimum_size = Vector2(22, 22)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(dot)
		var l := UIKit.label(c["name"], 19, UIKit.INK)
		h.add_child(l)
		if not owned:
			h.add_child(UIKit.icon("coin", 24))
			h.add_child(UIKit.label(str(int(c.get("price", 0))), 18, Color("#c98a14")))
			card.set_colors(Color("#efe4d6"))
		card.selected = id == cur
		card.tapped.connect(func(): _pick(slot, id))
		flow.add_child(card)


func _pick(slot: String, id: String) -> void:
	if not ProgressionManager.owns(slot, id):
		var price := ProgressionManager.price(slot, id)
		var prev: String = ProgressionManager.chef().get(slot, "")
		ProgressionManager.chef()[slot] = id
		_refresh_preview()
		var m := UIKit.modal(self, Loc.t("Satın Al?"), Loc.t("%s — %d Şef Parası") % [ProgressionManager.item_def(slot, id).get("name", id), price],
			[[Loc.t("Vazgeç"), "no", UIKit.GRAY], [Loc.t("Satın Al"), "yes", UIKit.GREEN]])
		var ch: String = await m.closed
		if ch != "yes" or not ProgressionManager.buy(slot, id):
			ProgressionManager.chef()[slot] = prev
			if ch == "yes":
				GameManager.toast(Loc.t("Yeterli Şef Parası yok!"), UIKit.RED, "coin")
			_refresh_preview()
			_set_tab(tab)
			return
		AudioManager.sfx("coins")
	ProgressionManager.set_chef_value(slot, id)
	_refresh_preview()
	preview.react("cheer")
	_set_tab(tab)


func _specs() -> void:
	content.add_child(UIKit.wrap_label(Loc.t("Her seviye atlayışında 1 uzmanlık puanı kazanırsın. Yetenekler oyunu kolaylaştırır ama tek başına kazandırmaz."), 22, Color("#6a4a3a")))
	for sp in IngredientDatabase.specializations:
		var col := Color(sp.get("color", "#ff9b3d"))
		var p := UIKit.panel(col.lightened(0.8), 22, col.darkened(0.3), 4, 12)
		content.add_child(p)
		var v := UIKit.vbox(6)
		p.add_child(v)
		var head := UIKit.hbox(8)
		head.add_child(UIKit.icon("s_" + str(sp["id"]), 48))
		var hl := UIKit.label(sp["name"], 28, col.darkened(0.4), true, HORIZONTAL_ALIGNMENT_LEFT)
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(hl)
		var tier := ProgressionManager.spec_tier(sp["id"])
		head.add_child(UIKit.stars(tier, 3, 32))
		v.add_child(head)
		var tiers: Array = sp.get("tiers", [])
		for i in tiers.size():
			var got := i < tier
			var row := UIKit.hbox(8)
			var ic := UIKit.icon("check" if got else "lock", 30)
			row.add_child(ic)
			var tl := UIKit.wrap_label(Loc.t("%s: %s") % [tiers[i]["name"], tiers[i]["desc"]], 20, UIKit.INK if got else Color("#8a7a6a"), got, HORIZONTAL_ALIGNMENT_LEFT)
			tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(tl)
			v.add_child(row)
		if tier < 3:
			var b := UIKit.button(Loc.t("Geliştir (1 puan)"), col, Vector2(0, 62), 24, "levelup")
			b.disabled = ProgressionManager.skill_points() <= 0
			var sid: String = sp["id"]
			b.pressed.connect(func():
				if ProgressionManager.upgrade_spec(sid):
					AudioManager.sfx("levelup")
					preview.react("cheer")
					_refresh_preview()
					_set_tab("spec"))
			v.add_child(b)


func _assistants() -> void:
	content.add_child(UIKit.wrap_label(Loc.t("Gizli karakterler mutfakta sana eşlik eden asistanlara dönüşür. Kilidi açmak için Tarif Kitabı'ndaki ipuçlarını takip et!"), 22, Color("#6a4a3a")))
	var cur := ProgressionManager.assistant()
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	content.add_child(flow)
	var none := TapCard.new()
	none.custom_minimum_size = Vector2(200, 200)
	none.add_child(UIKit.label(Loc.t("Asistan yok"), 22))
	none.selected = cur == ""
	none.tapped.connect(func():
		ProgressionManager.set_chef_value("assistant", "")
		_set_tab("assist"))
	flow.add_child(none)
	for sid in IngredientDatabase.secrets.keys():
		var s: Dictionary = IngredientDatabase.secrets[sid]
		if s.get("type", "") != "assistant":
			continue
		var card := TapCard.new()
		card.custom_minimum_size = Vector2(200, 200)
		var v := UIKit.vbox(2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(v)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(180, 120)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(holder)
		var unlocked := ProgressionManager.has_secret(sid)
		var dv := DishView.new()
		dv.setup(DishView.companion(sid))
		dv.set_alive(unlocked)
		dv.scale = Vector2(0.55, 0.55)
		dv.position = Vector2(90, 110)
		if not unlocked:
			dv.modulate = Color(0.1, 0.05, 0.1, 0.8)
		holder.add_child(dv)
		v.add_child(UIKit.label(s["name"] if unlocked else "???", 20))
		card.selected = cur == sid
		var s2: String = sid
		card.tapped.connect(func():
			if not ProgressionManager.has_secret(s2):
				GameManager.toast(Loc.t("İpucu: ") + str(IngredientDatabase.secrets[s2].get("hint", "")), UIKit.PURPLE, "bulb")
				return
			ProgressionManager.set_chef_value("assistant", s2)
			_set_tab("assist"))
		flow.add_child(card)


func _randomize() -> void:
	var c := ProgressionManager.chef()
	c["skin"] = randi() % IngredientDatabase.content.get("skin_tones", [1]).size()
	c["hair_color"] = randi() % IngredientDatabase.content.get("hair_colors", [1]).size()
	for slot in ["hair", "expression", "hat", "jacket", "apron", "accessory"]:
		var owned := ProgressionManager.owned_list(slot)
		if not owned.is_empty():
			c[slot] = owned[randi() % owned.size()]
	SaveManager.mark_dirty()
	_refresh_preview()
	preview.react("surprised")
	_set_tab(tab)


func on_back() -> bool:
	if first_run:
		return true
	GameManager.go_back()
	return true
