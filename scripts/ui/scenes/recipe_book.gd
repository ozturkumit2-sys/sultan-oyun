extends BaseScreen
## RecipeBook — keşfedilen tarifler, gizli tarif ipuçları, deneyler, gizli karakterler, mutasyon koleksiyonu, başarımlar.

var tab := "recipes"
var content: Control
var holder: VBoxContainer
var _tabs: Dictionary = {}


func _ready() -> void:
	setup_screen("sunburst", Color("#8fb4ff"), Color("#5b4bd6"))
	make_header(Loc.t("TARİF KİTABI"), true, true)
	var info := UIKit.label(Loc.t("%d tarif · %d / %d özel tarif") % [RecipeBookManager.count_all(), RecipeBookManager.count_handcrafted(), IngredientDatabase.recipes.size()], 22, Color.WHITE)
	root_v.add_child(UIKit.outlined(info, UIKit.INK, 6))
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	tabs.alignment = FlowContainer.ALIGNMENT_CENTER
	root_v.add_child(tabs)
	for t in [["recipes", Loc.t("Tarifler")], ["experiments", Loc.t("Deneyler")], ["secrets", Loc.t("Karakterler")], ["mutations", Loc.t("Mutasyonlar")], ["achievements", Loc.t("Başarımlar")]]:
		var b := UIKit.button(t[1], Color("#c9b8a6"), Vector2(134, 54), 19)
		var key: String = t[0]
		b.pressed.connect(func(): _set_tab(key))
		tabs.add_child(b)
		_tabs[key] = b
	var p := UIKit.panel(UIKit.CREAM, 26, UIKit.INK, 4, 12)
	holder = UIKit.vbox(10)
	p.add_child(holder)
	var sc := UIKit.scroll(p)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(sc)
	_set_tab("recipes")


func _set_tab(t: String) -> void:
	tab = t
	AudioManager.sfx("page")
	for k in _tabs.keys():
		UIKit.style_button(_tabs[k], UIKit.BLUE if k == t else Color("#c9b8a6"), 26, 19)
	for c in holder.get_children():
		c.queue_free()
	match t:
		"recipes":
			_recipes()
		"experiments":
			_experiments()
		"secrets":
			_secrets()
		"mutations":
			_mutations()
		"achievements":
			_achievements()


func _flow() -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 8)
	f.add_theme_constant_override("v_separation", 8)
	holder.add_child(f)
	return f


func _recipes() -> void:
	holder.add_child(UIKit.label(Loc.t("Füzyonlar"), 26, Color("#8a5a3b"), true, HORIZONTAL_ALIGNMENT_LEFT))
	var f1 := _flow()
	var f2: HFlowContainer
	var dishes_started := false
	for rid in IngredientDatabase.recipe_order:
		var r: Dictionary = IngredientDatabase.recipes[rid]
		if r.get("kind", "") == "dish" and not dishes_started:
			dishes_started = true
			holder.add_child(UIKit.label(Loc.t("Yemekler"), 26, Color("#8a5a3b"), true, HORIZONTAL_ALIGNMENT_LEFT))
			f2 = _flow()
		var card := _recipe_card(rid)
		if dishes_started:
			f2.add_child(card)
		else:
			f1.add_child(card)


func _recipe_card(rid: String) -> Control:
	var r: Dictionary = IngredientDatabase.recipes[rid]
	var known := RecipeBookManager.is_known(rid)
	var card := TapCard.new()
	card.custom_minimum_size = Vector2(318, 0)
	if r.get("secret", false):
		card.set_colors(Color("#f3e6ff") if known else Color("#e6dcef"), UIKit.PURPLE)
	var h := UIKit.hbox(8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(h)
	var pic := Control.new()
	pic.custom_minimum_size = Vector2(110, 110)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(pic)
	var dv := DishView.new()
	dv.setup(FusionEngine.item(rid))
	dv.scale = Vector2(0.48, 0.48)
	dv.position = Vector2(55, 96)
	dv.show_shadow = known
	if not known:
		dv.modulate = Color(0.15, 0.1, 0.18, 0.85)
	pic.add_child(dv)
	var v := UIKit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(UIKit.label(r["name"] if known else "???", 21, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT))
	if known:
		var ins := UIKit.hbox(2)
		ins.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for inp in r.get("inputs", []):
			var ic := IngredientIcon.new()
			ic.custom_minimum_size = Vector2(38, 38)
			ic.set_item(str(inp))
			ins.add_child(ic)
		var m: Variant = r.get("method")
		if m is String:
			ins.add_child(UIKit.icon("m_" + str(m), 34))
		v.add_child(ins)
		var best := RecipeBookManager.best_score(rid)
		if best > 0:
			v.add_child(UIKit.label(Loc.t("En iyi: %s") % UIKit.fmt(best), 17, Color("#8a5a3b"), false, HORIZONTAL_ALIGNMENT_LEFT))
	elif RecipeBookManager.hint_visible(rid):
		var hl := UIKit.wrap_label(Loc.t("İpucu: ") + str(r.get("hint", "")), 17, UIKit.PURPLE, false, HORIZONTAL_ALIGNMENT_LEFT)
		hl.custom_minimum_size.x = 180
		v.add_child(hl)
	else:
		v.add_child(UIKit.icon_label("bulb", Loc.t("İpucu al (%d)") % RecipeBookManager.HINT_PRICE, 17, Color("#c98a14"), 26))
	card.tapped.connect(func(): _recipe_tap(rid))
	return card


func _recipe_tap(rid: String) -> void:
	if RecipeBookManager.is_known(rid):
		_details(FusionEngine.item(rid))
		return
	if RecipeBookManager.hint_visible(rid):
		return
	var m := UIKit.modal(self, Loc.t("İpucu Al?"), Loc.t("%d Şef Parası karşılığında bu tarifin ipucunu görebilirsin.") % RecipeBookManager.HINT_PRICE, [[Loc.t("Vazgeç"), "no", UIKit.GRAY], [Loc.t("Al"), "yes", UIKit.GREEN]])
	var ch: String = await m.closed
	if ch == "yes":
		if RecipeBookManager.buy_hint(rid):
			AudioManager.sfx("unlock")
		else:
			GameManager.toast(Loc.t("Yeterli Şef Parası yok!"), UIKit.RED, "coin")
		_set_tab("recipes")


func _details(it: Dictionary) -> void:
	var extra := UIKit.vbox(8)
	var pic := Control.new()
	pic.custom_minimum_size = Vector2(0, 170)
	extra.add_child(pic)
	var dv := DishView.new()
	dv.setup(it, "classic" if it.get("kind", "") == "dish" else "")
	dv.set_alive(str(it.get("living", "")) != "")
	dv.scale = Vector2(0.8, 0.8)
	dv.position = Vector2(270, 150)
	pic.add_child(dv)
	extra.add_child(UIKit.wrap_label(it.get("desc", ""), 22))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	extra.add_child(grid)
	for k in IngredientDatabase.STAT_KEYS:
		var l := UIKit.label(Loc.t(str(IngredientDatabase.STAT_NAMES[k])), 19, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT)
		l.custom_minimum_size.x = 130
		grid.add_child(l)
		var b := UIKit.bar(it["stats"][k], 100, IngredientDatabase.STAT_COLORS[k], 16, 320)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	var meta := []
	if it.get("method", "") != "":
		meta.append(IngredientDatabase.method_name(it["method"]))
	meta.append(Loc.t("Zincir: %d adım") % int(it.get("depth", 1)))
	if str(it.get("living", "")) != "":
		meta.append(Loc.t("Canlı yemek!"))
	extra.add_child(UIKit.label(" · ".join(PackedStringArray(meta)), 19, UIKit.PURPLE))
	UIKit.modal(self, it.get("name", ""), "", [[Loc.t("Kapat"), "close", UIKit.GREEN]], extra)


func _experiments() -> void:
	var fus: Array = []
	for id in RecipeBookManager.book().keys():
		if str(id).begins_with("gf_") and FusionEngine.exists(id):
			fus.append(id)
	var dishes := RecipeBookManager.known_generic_dishes()
	if fus.is_empty() and dishes.is_empty():
		holder.add_child(UIKit.wrap_label(Loc.t("Henüz deney yok. Kaos Lab'da malzemeleri serbestçe birleştir!"), 24, Color("#8a6a50")))
		return
	holder.add_child(UIKit.label(Loc.t("Deneysel Yemekler (%d)") % dishes.size(), 24, Color("#8a5a3b"), true, HORIZONTAL_ALIGNMENT_LEFT))
	var f := _flow()
	for id in dishes.slice(0, 60):
		f.add_child(_small_card(id))
	holder.add_child(UIKit.label(Loc.t("Deneysel Füzyonlar (%d)") % fus.size(), 24, Color("#8a5a3b"), true, HORIZONTAL_ALIGNMENT_LEFT))
	var f2 := _flow()
	for id in fus.slice(0, 60):
		f2.add_child(_small_card(id))


func _small_card(id: String) -> Control:
	var it := FusionEngine.item(id)
	var card := TapCard.new()
	card.custom_minimum_size = Vector2(206, 180)
	var v := UIKit.vbox(0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var pic := Control.new()
	pic.custom_minimum_size = Vector2(190, 110)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(pic)
	var dv := DishView.new()
	dv.setup(it)
	dv.scale = Vector2(0.45, 0.45)
	dv.position = Vector2(95, 100)
	pic.add_child(dv)
	var l := UIKit.label(it["name"], 17, UIKit.INK)
	l.autowrap_mode = UIKit.wrap_mode()
	l.custom_minimum_size.x = 190
	v.add_child(l)
	card.tapped.connect(func(): _details(it))
	return card


func _secrets() -> void:
	var f := _flow()
	for sid in IngredientDatabase.secrets.keys():
		var s: Dictionary = IngredientDatabase.secrets[sid]
		var got := ProgressionManager.has_secret(sid)
		var card := TapCard.new()
		card.custom_minimum_size = Vector2(318, 0)
		var h := UIKit.hbox(8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(h)
		var pic := Control.new()
		pic.custom_minimum_size = Vector2(110, 120)
		pic.clip_contents = true
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(pic)
		if s.get("type", "") == "assistant":
			var dv := DishView.new()
			dv.setup(DishView.companion(sid))
			dv.set_alive(got)
			dv.scale = Vector2(0.45, 0.45)
			dv.position = Vector2(55, 110)
			pic.add_child(dv)
			if not got:
				dv.modulate = Color(0.1, 0.05, 0.1, 0.85)
		else:
			var n := Node2D.new()
			pic.add_child(n)
			var fig := CharacterFigure.new()
			var spec := CharacterFigure.chef_spec(ProgressionManager.chef())
			if sid == "ghost_chef":
				spec["hat"] = "ghost_sheet"
			if sid == "golden_chef":
				spec["body_color"] = Color("#f2c14e")
				spec["hat"] = "crown"
			fig.setup(spec)
			fig.scale = Vector2(0.36, 0.36)
			fig.position = Vector2(55, 150)
			n.add_child(fig)
			if not got:
				pic.modulate = Color(0.1, 0.05, 0.1, 0.85)
		var v := UIKit.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(v)
		v.add_child(UIKit.label(s["name"] if got else "???", 22, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT))
		var d := UIKit.wrap_label(s["desc"] if got else Loc.t("İpucu: ") + str(s.get("hint", "")), 17, UIKit.INK if got else UIKit.PURPLE, false, HORIZONTAL_ALIGNMENT_LEFT)
		d.custom_minimum_size.x = 180
		v.add_child(d)
		f.add_child(card)


func _mutations() -> void:
	var seen: Array = SaveManager.data["mutations_seen"]
	holder.add_child(UIKit.label(Loc.t("Koleksiyon: %d / %d") % [seen.size(), IngredientDatabase.mutation_order.size()], 24, Color("#8a5a3b")))
	var f := _flow()
	var judges := ["bruno", "mira", "max"]
	var i := 0
	for mid in IngredientDatabase.mutation_order:
		var m: Dictionary = IngredientDatabase.mutations[mid]
		var got := seen.has(mid)
		var card := TapCard.new()
		card.custom_minimum_size = Vector2(318, 0)
		var h := UIKit.hbox(8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(h)
		var pic := Control.new()
		pic.custom_minimum_size = Vector2(110, 130)
		pic.clip_contents = true
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(pic)
		var n := Node2D.new()
		pic.add_child(n)
		var fig := CharacterFigure.new()
		fig.setup(CharacterFigure.preset(judges[i % 3]))
		if got:
			fig.set_mutation(mid)
		fig.scale = Vector2(0.36, 0.36)
		fig.position = Vector2(55, 170)
		n.add_child(fig)
		if not got:
			pic.modulate = Color(0.1, 0.05, 0.1, 0.85)
		var v := UIKit.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(v)
		v.add_child(UIKit.label(m["name"] if got else "???", 21, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT))
		v.add_child(UIKit.chip(Loc.t(str(MutationSystem.CATEGORY_NAMES.get(m.get("category", ""), ""))), Color("#2fbf71") if m.get("category", "") == "taste" else (UIKit.PINK if m.get("category", "") == "chaos" else UIKit.BLUE), 15))
		if got:
			var d := UIKit.wrap_label(m.get("desc", ""), 16, UIKit.INK, false, HORIZONTAL_ALIGNMENT_LEFT)
			d.custom_minimum_size.x = 180
			v.add_child(d)
		f.add_child(card)
		i += 1


func _achievements() -> void:
	for aid in IngredientDatabase.achievement_order:
		var a: Dictionary = IngredientDatabase.achievements[aid]
		var got := ProgressionManager.has_achievement(aid)
		var row := UIKit.hbox(10)
		row.add_child(UIKit.icon("trophy" if got else "lock", 48))
		var v := UIKit.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		v.add_child(UIKit.label(a["name"], 24, UIKit.INK if got else Color("#8a7a6a"), true, HORIZONTAL_ALIGNMENT_LEFT))
		v.add_child(UIKit.label(a["desc"], 19, Color("#6a4a3a"), false, HORIZONTAL_ALIGNMENT_LEFT))
		row.add_child(UIKit.icon_label("coin", str(int(a.get("coins", 0))), 20, Color("#c98a14"), 28))
		holder.add_child(row)
