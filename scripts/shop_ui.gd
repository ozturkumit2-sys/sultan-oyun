extends Control
class_name ShopUI
## Şapkacı Dede's shop: try on, buy and equip accessories with collected fish.

signal closed
signal preview_changed(eq: Dictionary)

const TABS := [["head", "Şapka"], ["eyes", "Gözlük"], ["scarf", "Atkı"]]
const DEDE_LINES := [
	"Hoş geldin evlat! Balığın varsa şapkam da var.",
	"Bu fes sana pek yakışır, Tarçın!",
	"Galata'nın en şık kedisi sen olacaksın.",
	"Taç mı? Önce biraz daha balık topla bakalım.",
	"Vapurcu şapkası tam Boğaz havası!",
]

var tab := "head"
var preview := {}
var list_box: VBoxContainer
var bank_label: Label
var say_label: Label
var tab_buttons := {}
var selected := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	var st := UIKit.panel_style(UIKit.CREAM, UIKit.COBALT, 28, 5)
	st.content_margin_left = 18
	st.content_margin_right = 18
	panel.add_theme_stylebox_override("panel", st)
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -560
	panel.offset_right = -20
	panel.offset_top = 20
	panel.offset_bottom = -20
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	var title := UIKit.label("Şapkacı Dede", 40, UIKit.COBALT, 800)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var fish_ic := Control.new()
	fish_ic.custom_minimum_size = Vector2(54, 44)
	fish_ic.draw.connect(func(): UIKit.draw_fish(fish_ic, Vector2(27, 22), 46, Color("bfe3ee")))
	top.add_child(fish_ic)
	bank_label = UIKit.label("0", 34, UIKit.NAVY, 800)
	top.add_child(bank_label)
	say_label = UIKit.label(DEDE_LINES[randi() % DEDE_LINES.size()], 22, UIKit.TURQ, 700)
	say_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(say_label)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	for t in TABS:
		var b := UIKit.button(t[1], UIKit.COBALT, 26, 150)
		var slot: String = t[0]
		b.pressed.connect(func(): _set_tab(slot))
		tabs.add_child(b)
		tab_buttons[slot] = b
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(list_box)
	var close := UIKit.button("Kapat", UIKit.CORAL, 30, 200)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func():
		preview = GameState.equipped.duplicate()
		preview_changed.emit(preview)
		closed.emit())
	v.add_child(close)
	GameState.bank_changed.connect(func(_b): _refresh())


func open() -> void:
	visible = true
	preview = GameState.equipped.duplicate()
	selected = ""
	say_label.text = DEDE_LINES[randi() % DEDE_LINES.size()]
	_set_tab(tab)


func _set_tab(slot: String) -> void:
	tab = slot
	for k in tab_buttons.keys():
		(tab_buttons[k] as Button).modulate = Color(1, 1, 1) if k == slot else Color(1, 1, 1, 0.55)
	_refresh()


func _refresh() -> void:
	if bank_label == null:
		return
	bank_label.text = str(GameState.bank)
	for c in list_box.get_children():
		c.queue_free()
	for id in Accessories.ORDER:
		var it: Dictionary = Accessories.ITEMS[id]
		if it["slot"] != tab:
			continue
		list_box.add_child(_row(id, it))


func _row(id: String, it: Dictionary) -> Control:
	var owned := Accessories.is_owned(id)
	var equipped: bool = GameState.equipped.get(it["slot"], "") == id
	var row := PanelContainer.new()
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color("fbe9cc") if id == selected else Color("f6e3c4")
	rs.border_color = UIKit.TURQ if id == selected else Color("e6cfa8")
	rs.set_border_width_all(3)
	rs.set_corner_radius_all(18)
	rs.content_margin_left = 10
	rs.content_margin_right = 10
	rs.content_margin_top = 6
	rs.content_margin_bottom = 6
	row.add_theme_stylebox_override("panel", rs)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)
	var ic := Control.new()
	ic.custom_minimum_size = Vector2(70, 62)
	ic.draw.connect(func():
		ic.draw_circle(Vector2(35, 31), 29, Color("fff8ec"))
		ic.draw_arc(Vector2(35, 31), 29, 0, TAU, 32, UIKit.COBALT, 2.0, true)
		Accessories.draw_icon(ic, id, Vector2(35, 31), 52))
	h.add_child(ic)
	var name_l := UIKit.label(it["name"], 26, UIKit.NAVY, 800)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(name_l)
	var btn: Button
	if equipped:
		btn = UIKit.button("Çıkar" if it["slot"] != "scarf" else "Takılı", UIKit.NAVY, 24, 150)
		if it["slot"] == "scarf":
			btn.disabled = true
		btn.pressed.connect(func(): _unequip(id))
	elif owned:
		btn = UIKit.button("Tak", UIKit.TURQ, 24, 150)
		btn.pressed.connect(func(): _equip(id))
	else:
		var price: int = it["price"]
		btn = UIKit.button("%d balık" % price, UIKit.CORAL if GameState.bank >= price else Color("a89a8e"), 24, 150)
		btn.pressed.connect(func(): _buy(id))
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	# tapping the row tries the item on
	row.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
			_try(id))
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	return row


func _try(id: String) -> void:
	selected = id
	var slot: String = Accessories.ITEMS[id]["slot"]
	preview = GameState.equipped.duplicate()
	preview[slot] = id
	preview_changed.emit(preview)
	Sfx.play("click", 1.2, -6.0)
	_refresh()


func _buy(id: String) -> void:
	var price: int = Accessories.ITEMS[id]["price"]
	if GameState.bank < price:
		say_label.text = "Kumbarada %d balık lazım evlat, sende %d var. Çatılara geri dön!" % [price, GameState.bank]
		Sfx.play("hurt", 1.4, -10.0)
		_try(id)
		return
	if GameState.spend(price):
		GameState.owned.append(id)
		Sfx.play("fish_gold", 1.0, -2.0)
		GameState.vibrate(30)
		say_label.text = "Güle güle kullan! %s tam sana göre." % Accessories.ITEMS[id]["name"]
		_equip(id)


func _equip(id: String) -> void:
	var slot: String = Accessories.ITEMS[id]["slot"]
	GameState.equip(slot, id)
	preview = GameState.equipped.duplicate()
	selected = id
	preview_changed.emit(preview)
	Sfx.play("checkpoint", 1.3, -8.0)
	_refresh()


func _unequip(id: String) -> void:
	var slot: String = Accessories.ITEMS[id]["slot"]
	if slot == "scarf":
		return
	GameState.equip(slot, "")
	preview = GameState.equipped.duplicate()
	preview_changed.emit(preview)
	_refresh()
