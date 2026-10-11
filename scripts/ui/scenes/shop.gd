extends BaseScreen
## Shop — Şef Parası ile malzeme, tabak, süsleme ve mutfak dekoru. Kazanmayı satın alan ürün yoktur;
## temel ilerleme hiçbir zaman reklama bağlı değildir.

var tab := "ing"
var grid: HFlowContainer
var _tabs: Dictionary = {}


func _ready() -> void:
	setup_screen("sunburst", Color("#7dffb0"), Color("#2fbf71"))
	make_header("DÜKKÂN", true, true)
	var tabs := UIKit.hbox(6)
	root_v.add_child(tabs)
	for t in [["ing", "Malzeme"], ["plates", "Tabak"], ["garnishes", "Süsleme"], ["decor", "Mutfak"]]:
		var b := UIKit.button(t[1], Color("#c9b8a6"), Vector2(0, 60), 22)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key: String = t[0]
		b.pressed.connect(func(): _set_tab(key))
		tabs.add_child(b)
		_tabs[key] = b
	var p := UIKit.panel(UIKit.CREAM, 26, UIKit.INK, 4, 14)
	grid = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	p.add_child(grid)
	var sc := UIKit.scroll(p)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(sc)
	_set_tab("ing")


func _set_tab(t: String) -> void:
	tab = t
	for k in _tabs.keys():
		UIKit.style_button(_tabs[k], UIKit.GREEN if k == t else Color("#c9b8a6"), 26, 22)
	for c in grid.get_children():
		c.queue_free()
	match t:
		"ing":
			# önce satın alınabilenler (ucuzdan pahalıya), sonra kilitliler, en sonda sahip olunanlar
			var rows: Array = []
			for id in IngredientDatabase.ingredient_order:
				var u: Dictionary = IngredientDatabase.ingredients[id].get("unlock", {})
				if u.get("type", "") == "special":
					continue
				var st := ProgressionManager.ingredient_state(id)
				var grp := 0 if st == "buyable" else (1 if st == "locked" else 2)
				rows.append([grp, int(u.get("league", 0)), ProgressionManager.ingredient_price(id), rows.size(), id])
			rows.sort()
			for row in rows:
				grid.add_child(_ing_card(row[4]))
		"plates":
			for pid in IngredientDatabase.plate_order:
				grid.add_child(_item_card("plates", pid))
		"garnishes":
			for gid in IngredientDatabase.garnish_order:
				grid.add_child(_item_card("garnishes", gid))
		"decor":
			for did in IngredientDatabase.decor_order:
				grid.add_child(_item_card("decor", did))


func _ing_card(id: String) -> Control:
	var st := ProgressionManager.ingredient_state(id)
	var ing: Dictionary = IngredientDatabase.ingredients[id]
	var card := TapCard.new()
	card.custom_minimum_size = Vector2(198, 250)
	var v := UIKit.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var ic := IngredientIcon.new()
	ic.custom_minimum_size = Vector2(120, 110)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.dim = st == "locked"
	ic.set_item(id)
	v.add_child(ic)
	v.add_child(UIKit.label(ing["name"], 21, UIKit.INK))
	var d := UIKit.wrap_label(ing.get("desc", ""), 15, Color("#6a4a3a"))
	d.custom_minimum_size.x = 176
	v.add_child(d)
	match st:
		"owned":
			v.add_child(UIKit.icon_label("check", "Sende", 20, UIKit.GREEN, 28))
		"buyable":
			v.add_child(UIKit.icon_label("coin", str(ProgressionManager.ingredient_price(id)), 22, Color("#c98a14"), 30))
			card.set_colors(Color("#fff2c4"), Color("#c98a14"))
		_:
			var u: Dictionary = ing.get("unlock", {})
			var txt := "Kilitli"
			if u.get("type", "") == "win":
				var m: Dictionary = IngredientDatabase.matches.get(u.get("match", ""), {})
				txt = ("Yen: %s" % IngredientDatabase.opponents.get(m.get("opponent", ""), {}).get("name", "?")) if not m.is_empty() else "Maç kazan"
			elif u.get("type", "") == "league":
				txt = "Lig %d'de açılır" % int(u.get("league", 0))
			v.add_child(UIKit.icon_label("lock", txt, 17, Color("#8a7a6a"), 26))
			card.disabled = true
	card.tapped.connect(func(): _buy_ing(id))
	return card


func _buy_ing(id: String) -> void:
	if ProgressionManager.ingredient_state(id) != "buyable":
		return
	var price := ProgressionManager.ingredient_price(id)
	var m := UIKit.modal(self, "Satın Al?", "%s — %d Şef Parası" % [IngredientDatabase.ingredients[id]["name"], price], [["Vazgeç", "no", UIKit.GRAY], ["Satın Al", "yes", UIKit.GREEN]])
	var ch: String = await m.closed
	if ch == "yes":
		if ProgressionManager.buy_ingredient(id):
			AudioManager.sfx("coins")
			GameManager.toast("%s kilerine eklendi!" % IngredientDatabase.ingredients[id]["name"], UIKit.GREEN, "check")
		else:
			GameManager.toast("Yeterli Şef Parası yok!", UIKit.RED, "coin")
		_set_tab(tab)


func _item_card(slot: String, id: String) -> Control:
	var def := ProgressionManager.item_def(slot, id)
	var owned := ProgressionManager.owns(slot, id)
	var card := TapCard.new()
	card.custom_minimum_size = Vector2(198, 200)
	var v := UIKit.vbox(4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(180, 100)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(holder)
	match slot:
		"plates":
			var dv := DishView.new()
			dv.setup({"visual": {"base": "cake", "c1": "#f2c05a", "c2": "#ff7ab8"}}, id)
			dv.scale = Vector2(0.55, 0.55)
			dv.position = Vector2(95, 78)
			holder.add_child(dv)
		"garnishes":
			var dv2 := DishView.new()
			dv2.setup({"visual": {"base": "souffle", "c1": "#f7d27a", "c2": "#ff9b3d"}}, "classic", id)
			dv2.scale = Vector2(0.5, 0.5)
			dv2.position = Vector2(95, 82)
			holder.add_child(dv2)
		"decor":
			var sw := DecorSwatch.new()
			sw.decor = def
			sw.set_anchors_preset(Control.PRESET_FULL_RECT)
			holder.add_child(sw)
	v.add_child(UIKit.label(def.get("name", id), 21, UIKit.INK))
	if owned:
		if slot == "decor":
			var active: bool = SaveManager.data.get("decor", "classic") == id
			v.add_child(UIKit.icon_label("check", "Kullanılıyor" if active else "Seç", 20, UIKit.GREEN if active else UIKit.BLUE, 28))
			card.selected = active
		else:
			v.add_child(UIKit.icon_label("check", "Sende", 20, UIKit.GREEN, 28))
	else:
		v.add_child(UIKit.icon_label("coin", str(int(def.get("price", 0))), 22, Color("#c98a14"), 30))
		card.set_colors(Color("#fff2c4"), Color("#c98a14"))
	card.tapped.connect(func(): _buy_item(slot, id))
	return card


func _buy_item(slot: String, id: String) -> void:
	if ProgressionManager.owns(slot, id):
		if slot == "decor":
			SaveManager.data["decor"] = id
			SaveManager.mark_dirty()
			AudioManager.sfx("pop")
			_set_tab(tab)
		return
	var def := ProgressionManager.item_def(slot, id)
	var m := UIKit.modal(self, "Satın Al?", "%s — %d Şef Parası" % [def.get("name", id), int(def.get("price", 0))], [["Vazgeç", "no", UIKit.GRAY], ["Satın Al", "yes", UIKit.GREEN]])
	var ch: String = await m.closed
	if ch == "yes":
		if ProgressionManager.buy(slot, id):
			AudioManager.sfx("coins")
			if slot == "decor":
				SaveManager.data["decor"] = id
				SaveManager.mark_dirty()
		else:
			GameManager.toast("Yeterli Şef Parası yok!", UIKit.RED, "coin")
		_set_tab(tab)


class DecorSwatch extends Control:
	var decor: Dictionary = {}

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2(10, 4), Vector2(size.x - 20, size.y - 8))
		DrawKit.fill(self, DrawKit.rrect(r, 14), Color(decor.get("wall", "#ffe7c2")), 0.1)
		for i in 4:
			DrawKit.fill(self, DrawKit.rrect(Rect2(r.position.x + 10 + i * (r.size.x - 20) / 4.0, r.position.y + 14, (r.size.x - 20) / 4.0 - 8, 30), 6), Color(decor.get("tile", "#fff6e8")))
		DrawKit.fill(self, DrawKit.rrect(Rect2(r.position.x, r.end.y - 34, r.size.x, 34), 10), Color(decor.get("counter", "#e8734a")), 0.15)
		DrawKit.outline(self, DrawKit.rrect(r, 14), UIKit.INK, 3.0)
