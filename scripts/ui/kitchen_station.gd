class_name KitchenStation
extends VBoxContainer
## Mutfak çalışma paneli: kiler (malzeme/füzyon), karıştırma kasesi, füzyon, pişirme yöntemi seçimi
## ve sunum (tabak + süsleme). Hem Kariyer/Günlük maçlarında hem Kaos Lab'da kullanılır.

signal cook_requested(inputs: Array, method: String)
signal fused(item: Dictionary, is_new: bool)
signal plating_changed(plate: String, garnish: String)
signal serve_requested(plate: String, garnish: String)
signal bowl_changed

const METHODS := ["bake", "fry", "freeze", "boil", "grill", "magic"]
const METHOD_COLORS := {"bake": Color("#e8734a"), "fry": Color("#ffb020"), "freeze": Color("#4ad6ff"),
	"boil": Color("#4a7dff"), "grill": Color("#7d6b5d"), "magic": Color("#a25cff")}
const METHOD_VERBS := {"bake": "FIRINLA!", "fry": "KIZART!", "freeze": "DONDUR!", "boil": "KAYNAT!", "grill": "IZGARALA!", "magic": "BÜYÜLE!"}  # i18n

var mode := "battle"
var slots: Array = []
var max_slots := 2
var method := ""
var banned: Array = []
var mystery := ""
var pantry_ing: Array = []
var pantry_fus: Array = []
var stolen := ""
var fusion_limit := -1
var fusions_used := 0
var locked := false
var new_fusions: Array = []

var _slot_nodes: Array = []
var _slot_row: HBoxContainer
var _fuse_btn: Button
var _clear_btn: Button
var _info: Label
var _method_btns: Dictionary = {}
var _cook_btn: Button
var _tab_ing: Button
var _tab_fus: Button
var _grid: GridContainer
var _scroll: ScrollContainer
var _tab := "ing"
var _work: VBoxContainer
var _plating: VBoxContainer
var _plate := "classic"
var _garnish := "none"
var _plate_cards: Dictionary = {}
var _garnish_cards: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_work()
	_build_plating()
	_plating.visible = false


# ------------------------------------------------------------------ kurulum
func _build_work() -> void:
	_work = UIKit.vbox(10)
	_work.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_work)
	var row := UIKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_work.add_child(row)
	_slot_row = UIKit.hbox(6)
	_slot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_slot_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_slot_row)
	var col := UIKit.vbox(8)
	row.add_child(col)
	_fuse_btn = UIKit.button(Loc.t("KARIŞTIR"), UIKit.PURPLE, Vector2(176, 66), 24, "fuse")
	_fuse_btn.pressed.connect(do_fuse)
	col.add_child(_fuse_btn)
	_clear_btn = UIKit.button(Loc.t("Boşalt"), Color("#c9b8a6"), Vector2(176, 44), 20, "trash")
	_clear_btn.pressed.connect(clear_bowl)
	col.add_child(_clear_btn)
	_info = UIKit.label("", 21, UIKit.INK, true)
	_info.custom_minimum_size.y = 28
	_info.clip_text = true
	_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_work.add_child(_info)
	var mrow := UIKit.hbox(6)
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	_work.add_child(mrow)
	for m in METHODS:
		var b := UIKit.icon_button("m_" + m, UIKit.CREAM, 74)
		b.toggle_mode = false
		var mm: String = m
		b.pressed.connect(func(): select_method(mm))
		mrow.add_child(b)
		_method_btns[m] = b
	_cook_btn = UIKit.button(Loc.t("PİŞİR!"), UIKit.ORANGE, Vector2(0, 80), 28, "fire")
	_cook_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cook_btn.pressed.connect(request_cook)
	mrow.add_child(_cook_btn)
	var tabs := UIKit.hbox(8)
	_work.add_child(tabs)
	_tab_ing = UIKit.button(Loc.t("Malzemeler"), UIKit.ORANGE, Vector2(0, 52), 22)
	_tab_ing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_ing.pressed.connect(func(): _set_tab("ing"))
	tabs.add_child(_tab_ing)
	_tab_fus = UIKit.button(Loc.t("Füzyonlar"), Color("#c9b8a6"), Vector2(0, 52), 22)
	_tab_fus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_fus.pressed.connect(func(): _set_tab("fus"))
	tabs.add_child(_tab_fus)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll = UIKit.scroll(_grid)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size.y = 150
	_work.add_child(_scroll)
	_rebuild_slots()
	_update_ui()


func _build_plating() -> void:
	_plating = UIKit.vbox(10)
	_plating.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_plating)
	_plating.add_child(UIKit.label(Loc.t("SUNUM ZAMANI"), 30, UIKit.INK))
	_plating.add_child(UIKit.label(Loc.t("Tabak"), 22, Color("#8a6a50"), true, HORIZONTAL_ALIGNMENT_LEFT))
	var prow := UIKit.hbox(8)
	var ps := UIKit.scroll(prow, true)
	ps.custom_minimum_size.y = 128
	_plating.add_child(ps)
	for pid in IngredientDatabase.plate_order:
		var card := TapCard.new()
		card.custom_minimum_size = Vector2(118, 118)
		var v := UIKit.vbox(0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(v)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(100, 70)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(holder)
		var dv := DishView.new()
		dv.setup({"visual": {"base": "none"}}, pid)
		dv.scale = Vector2(0.4, 0.4)
		dv.position = Vector2(51, 44)
		dv.show_shadow = false
		holder.add_child(dv)
		var nm := UIKit.label(IngredientDatabase.plates[pid]["name"], 15, UIKit.INK)
		nm.autowrap_mode = UIKit.wrap_mode()
		nm.custom_minimum_size.x = 100
		v.add_child(nm)
		var p2: String = pid
		card.tapped.connect(func(): _pick_plate(p2))
		prow.add_child(card)
		_plate_cards[pid] = card
	_plating.add_child(UIKit.label(Loc.t("Süsleme"), 22, Color("#8a6a50"), true, HORIZONTAL_ALIGNMENT_LEFT))
	var grow := HFlowContainer.new()
	grow.add_theme_constant_override("h_separation", 8)
	grow.add_theme_constant_override("v_separation", 8)
	var gs := UIKit.scroll(grow)
	gs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gs.custom_minimum_size.y = 110
	_plating.add_child(gs)
	for gid in IngredientDatabase.garnish_order:
		var card2 := TapCard.new()
		card2.custom_minimum_size = Vector2(160, 54)
		var l := UIKit.label(IngredientDatabase.garnishes[gid]["name"], 19, UIKit.INK)
		card2.add_child(l)
		var g2: String = gid
		card2.tapped.connect(func(): _pick_garnish(g2))
		grow.add_child(card2)
		_garnish_cards[gid] = card2
	var serve := UIKit.button(Loc.t("SUN!"), UIKit.GREEN, Vector2(0, 88), 34, "plate")
	serve.pressed.connect(func():
		if locked:
			return
		serve_requested.emit(_plate, _garnish))
	_plating.add_child(serve)


# ------------------------------------------------------------------ kiler
func set_pantry(ings: Array, fusions: Array, mystery_id := "", stolen_id := "") -> void:
	pantry_ing = ings
	pantry_fus = fusions
	mystery = mystery_id
	stolen = stolen_id
	for i in range(slots.size() - 1, -1, -1):
		if slots[i] == stolen and stolen != "":
			slots.remove_at(i)
	refresh_pantry()
	_rebuild_slots()


func _set_tab(t: String) -> void:
	_tab = t
	UIKit.style_button(_tab_ing, UIKit.ORANGE if t == "ing" else Color("#c9b8a6"), 26, 22)
	UIKit.style_button(_tab_fus, UIKit.PURPLE if t == "fus" else Color("#c9b8a6"), 26, 22)
	refresh_pantry()


func refresh_pantry() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var list: Array = pantry_ing if _tab == "ing" else pantry_fus
	_tab_fus.text = Loc.t("Füzyonlar (%d)") % pantry_fus.size()
	if list.is_empty():
		var l := UIKit.wrap_label(Loc.t("Henüz füzyon yok. İki malzemeyi kaseye koyup KARIŞTIR'a bas!") if _tab == "fus" else Loc.t("Kiler boş!"), 22, Color("#8a6a50"))
		l.custom_minimum_size.x = 640
		_grid.add_child(l)
		return
	for id in list:
		_grid.add_child(_pantry_card(id))


func _pantry_card(id: String) -> TapCard:
	var card := TapCard.new()
	card.custom_minimum_size = Vector2(106, 132)
	var it := FusionEngine.item(id)
	var v := UIKit.vbox(0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var ic := IngredientIcon.new()
	ic.custom_minimum_size = Vector2(84, 80)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	ic.set_item(id)
	var nm := UIKit.label(it["name"], 15, UIKit.INK)
	nm.autowrap_mode = UIKit.wrap_mode()
	nm.custom_minimum_size = Vector2(94, 38)
	nm.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	nm.max_lines_visible = 2
	v.add_child(nm)
	if id == mystery:
		card.set_colors(Color("#e9d6ff"), UIKit.PURPLE)
		var tag := UIKit.chip(Loc.t("GİZEM"), UIKit.PURPLE, 14)
		tag.position = Vector2(2, -6)
		card.add_child(tag)
		tag.top_level = false
	elif new_fusions.has(id):
		card.set_colors(Color("#fff2c4"))
	if it.get("handcrafted", false) and it.get("kind", "") == "fusion":
		card.set_colors(Color("#ffe8f3"), Color("#c2407a"))
	var depth := int(it.get("depth", 0))
	if depth >= ProgressionManager.max_chain_depth() and it.get("kind", "") != "ingredient":
		card.tooltip_text = Loc.t("Zincir sınırında: sadece pişirilebilir")
	var idc: String = id
	card.tapped.connect(func(): add_to_bowl(idc, card))
	return card


# ------------------------------------------------------------------ kase
func _rebuild_slots() -> void:
	for c in _slot_row.get_children():
		c.queue_free()
	_slot_nodes.clear()
	for i in max_slots:
		if i > 0:
			var plus := UIKit.label("+", 34, Color(0.23, 0.14, 0.09, 0.5))
			_slot_row.add_child(plus)
		var s := BowlSlot.new()
		s.custom_minimum_size = Vector2(104, 104)
		s.index = i
		s.item_id = slots[i] if i < slots.size() else ""
		s.mystery = s.item_id != "" and s.item_id == mystery
		var ii := i
		s.tapped.connect(func(): remove_slot(ii))
		_slot_row.add_child(s)
		_slot_nodes.append(s)
	_update_ui()


func add_to_bowl(id: String, from: Control = null) -> void:
	if locked:
		return
	if slots.size() >= max_slots:
		GameManager.toast(Loc.t("Kase dolu! Bir malzemeyi çıkarmak için ona dokun."), UIKit.ORANGE, "info")
		AudioManager.sfx("fail", 1.4, -8.0)
		return
	if slots.has(id) and IngredientDatabase.ingredients.has(id):
		pass
	slots.append(id)
	AudioManager.sfx_r("pop", 0.1)
	_rebuild_slots()
	if from != null and _slot_nodes.size() >= slots.size():
		var target: Control = _slot_nodes[slots.size() - 1]
		_fly_icon(id, from, target)
	bowl_changed.emit()


func _fly_icon(id: String, from: Control, to: Control) -> void:
	var ic := IngredientIcon.new()
	ic.size = Vector2(80, 80)
	ic.set_item(id)
	ic.top_level = true
	ic.z_index = 60
	add_child(ic)
	ic.global_position = from.global_position + from.size * 0.5 - Vector2(40, 40)
	var tw := ic.create_tween()
	var dest := to.global_position + to.size * 0.5 - Vector2(40, 40)
	tw.tween_property(ic, "global_position", dest, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ic, "scale", Vector2(0.7, 0.7), 0.28)
	tw.tween_callback(ic.queue_free)


func remove_slot(i: int) -> void:
	if locked or i >= slots.size():
		return
	slots.remove_at(i)
	AudioManager.sfx("tap", 0.8)
	_rebuild_slots()
	bowl_changed.emit()


func clear_bowl() -> void:
	if locked:
		return
	slots.clear()
	_rebuild_slots()
	bowl_changed.emit()


func set_slots(arr: Array) -> void:
	slots = arr.duplicate()
	_rebuild_slots()


func can_fuse() -> bool:
	if slots.size() < 2:
		return false
	if fusion_limit >= 0 and fusions_used >= fusion_limit:
		return false
	for s in slots:
		if int(FusionEngine.item(s).get("depth", 0)) >= ProgressionManager.max_chain_depth():
			return false
	return true


func do_fuse() -> void:
	if locked:
		return
	if slots.size() < 2:
		GameManager.toast(Loc.t("Füzyon için kasede en az iki malzeme olmalı."), UIKit.PURPLE, "info")
		return
	for s in slots:
		if int(FusionEngine.item(s).get("depth", 0)) >= ProgressionManager.max_chain_depth():
			GameManager.toast(Loc.t("%s zincir sınırında; artık sadece pişirilebilir.") % FusionEngine.item(s)["name"], UIKit.PURPLE, "info")
			return
	if fusion_limit >= 0 and fusions_used >= fusion_limit:
		GameManager.toast(Loc.t("Bu turdaki füzyon hakkın bitti. Şimdi pişirme zamanı!"), UIKit.PURPLE, "info")
		return
	var it := FusionEngine.fuse(slots)
	fusions_used += 1
	ProgressionManager.add_stat("fusions")
	var is_new := RecipeBookManager.discover(it, mode)
	if is_new:
		new_fusions.append(it["id"])
	if not pantry_fus.has(it["id"]):
		pantry_fus.push_front(it["id"])
	slots = [it["id"]]
	AudioManager.sfx("fuse_special" if it.get("handcrafted", false) else "fuse")
	GameManager.vibrate(30)
	_rebuild_slots()
	if _slot_nodes.size() > 0:
		var s0: Control = _slot_nodes[0]
		FxBurst.spawn(s0, s0.size * 0.5, "sparkles", 16, Color("#ffd23f"))
		UIKit.pop_in(s0)
	if _tab == "fus" or is_new:
		refresh_pantry()
	fused.emit(it, is_new)
	bowl_changed.emit()


func select_method(m: String) -> void:
	if locked:
		return
	if banned.has(m):
		GameManager.toast(Loc.t("%s bu maçta yasak!") % IngredientDatabase.method_name(m), UIKit.RED, "cross")
		AudioManager.sfx("fail", 1.3, -8.0)
		return
	method = m
	AudioManager.sfx_r("tap", 0.1)
	_update_ui()
	bowl_changed.emit()


func request_cook() -> void:
	if locked:
		return
	if slots.is_empty():
		GameManager.toast(Loc.t("Önce kaseye malzeme koy!"), UIKit.ORANGE, "info")
		AudioManager.sfx("fail", 1.4, -8.0)
		return
	if method == "":
		GameManager.toast(Loc.t("Bir pişirme yöntemi seç!"), UIKit.ORANGE, "info")
		AudioManager.sfx("fail", 1.4, -8.0)
		var tw := create_tween()
		for b in _method_btns.values():
			tw.parallel().tween_property(b, "scale", Vector2(1.12, 1.12), 0.12)
		for b in _method_btns.values():
			tw.chain().tween_property(b, "scale", Vector2.ONE, 0.12)
		return
	cook_requested.emit(slots.duplicate(), method)


func _update_ui() -> void:
	if _info == null:
		return
	for m in _method_btns.keys():
		var b: Button = _method_btns[m]
		var c: Color = METHOD_COLORS[m] if m == method else UIKit.CREAM
		if banned.has(m):
			c = Color("#d8cbbb")
		UIKit.style_button(b, c, 24, 24)
		b.modulate = Color(1, 1, 1, 0.45) if banned.has(m) else Color.WHITE
	_cook_btn.text = Loc.t(str(METHOD_VERBS.get(method, Loc.t("PİŞİR!"))))
	_fuse_btn.disabled = not can_fuse()
	var txt := ""
	if slots.size() >= 2:
		var rid := FusionEngine.peek_recipe(slots, "")
		var known := rid != "" and RecipeBookManager.is_known(rid)
		if known:
			txt = Loc.t("Karıştır → %s") % IngredientDatabase.recipes[rid]["name"]
		elif rid != "" and ProgressionManager.spec_tier("fusion") >= 3:
			txt = Loc.t("Radar: Bu karışım gizli bir tarif!")
	if method != "" and not slots.is_empty():
		var rid2 := FusionEngine.peek_recipe(slots, method)
		if rid2 != "" and RecipeBookManager.is_known(rid2):
			txt = Loc.t("%s → %s") % [IngredientDatabase.method_name(method), IngredientDatabase.recipes[rid2]["name"]]
		elif rid2 != "" and ProgressionManager.spec_tier("fusion") >= 3:
			txt = Loc.t("Radar: %s ile özel bir tarif çıkacak!") % IngredientDatabase.method_name(method)
		elif txt == "":
			txt = Loc.t("%s · %d malzeme") % [IngredientDatabase.method_name(method), slots.size()]
	if txt == "":
		if fusion_limit >= 0:
			txt = Loc.t("Füzyon hakkı: %d") % maxi(0, fusion_limit - fusions_used)
		else:
			txt = Loc.t("Malzemelere dokun, kaseye ekle")
	_info.text = txt


# ------------------------------------------------------------------ sunum
func show_plating(on: bool) -> void:
	_work.visible = not on
	_plating.visible = on
	if on:
		_pick_plate(_plate if ProgressionManager.owns("plates", _plate) else "classic", true)
		_pick_garnish(_garnish if ProgressionManager.owns("garnishes", _garnish) else "none", true)
		for pid in _plate_cards.keys():
			var c: TapCard = _plate_cards[pid]
			c.disabled = not ProgressionManager.owns("plates", pid)
		for gid in _garnish_cards.keys():
			var c2: TapCard = _garnish_cards[gid]
			c2.disabled = not ProgressionManager.owns("garnishes", gid)


func _pick_plate(pid: String, silent := false) -> void:
	if not ProgressionManager.owns("plates", pid):
		GameManager.toast(Loc.t("%s dükkânda %d paraya satılıyor.") % [IngredientDatabase.plates[pid]["name"], ProgressionManager.price("plates", pid)], UIKit.ORANGE, "lock")
		return
	_plate = pid
	for k in _plate_cards.keys():
		var c: TapCard = _plate_cards[k]
		c.selected = k == pid
	if not silent:
		AudioManager.sfx_r("serve", 0.1, -6.0)
	plating_changed.emit(_plate, _garnish)


func _pick_garnish(gid: String, silent := false) -> void:
	if not ProgressionManager.owns("garnishes", gid):
		GameManager.toast(Loc.t("%s dükkânda %d paraya satılıyor.") % [IngredientDatabase.garnishes[gid]["name"], ProgressionManager.price("garnishes", gid)], UIKit.ORANGE, "lock")
		return
	_garnish = gid
	for k in _garnish_cards.keys():
		var c: TapCard = _garnish_cards[k]
		c.selected = k == gid
	if not silent:
		AudioManager.sfx_r("pop", 0.1, -4.0)
	plating_changed.emit(_plate, _garnish)


func current_plating() -> Array:
	return [_plate, _garnish]


func reset_for_round() -> void:
	slots.clear()
	method = ""
	fusions_used = 0
	locked = false
	show_plating(false)
	_rebuild_slots()
