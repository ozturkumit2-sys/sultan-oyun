extends Screen
## Interactive world map with market panel.

var map: WorldMapView
var panel: VBoxContainer
var sel := ""


func page_title() -> String:
	return "World markets"


func _make() -> void:
	var v := UI.vbox(0)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(v)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 470)
	holder.clip_contents = true
	v.add_child(holder)
	map = WorldMapView.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(map)
	map.country_tapped.connect(func(code):
		sel = code
		rebuild())
	var zb := UI.vbox(8)
	zb.position = Vector2(10, 10)
	var zi := UI.btn("+", func(): map.set_zoom(map.zoom * 1.3), "dark", 30, 60)
	zi.custom_minimum_size.x = 60
	var zo := UI.btn("−", func(): map.set_zoom(map.zoom / 1.3), "dark", 30, 60)
	zo.custom_minimum_size.x = 60
	zb.add_child(zi)
	zb.add_child(zo)
	holder.add_child(zb)
	scroll = DragScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.get_v_scroll_bar().modulate = Color(1, 1, 1, 0)
	v.add_child(scroll)
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k in ["left", "right"]:
		m.add_theme_constant_override("margin_" + k, 22)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 40)
	scroll.add_child(m)
	body = UI.vbox(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(body)
	sel = params.get("country", G.pc()["home"])
	map.selected = sel


func build() -> void:
	var c := G.pc()
	var st := {}
	for ct in DB.countries:
		var id: String = ct["id"]
		var sells := false
		for p in G.company_products(G.pid()):
			if p["markets"].has(id):
				sells = true
		st[id] = {"office": CompanyEngine.office_level(G.pid(), id), "sells": sells}
	map.status = st
	map.selected = sel
	map.queue_redraw()
	if sel == "":
		body.add_child(UI.para("Tap a market on the map.", 20))
		return
	CountryPanel.build(body, sel)
