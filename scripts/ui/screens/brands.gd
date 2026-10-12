extends Screen
## Brand portfolio (multi-brand holding).

func page_title() -> String:
	return "Brands"


func hero_spec() -> Dictionary:
	return {"scene": "boutique", "title": "Your brands", "sub": "Each brand has its own positioning and prestige", "focus": Vector2(0.5, 0.45), "h": 250.0}


func build() -> void:
	var c := G.pc()
	var bs := G.company_brands(G.pid())
	var cap := int(DB.hq_tier(int(c["hq"]["tier"]))["brands"])
	body.add_child(UI.para("%d of %d brands (headquarters limit). Brands share your infrastructure but compete for the same customers when positioned alike." % [bs.size(), cap], 19))
	for b in bs:
		var bid: String = b["id"]
		var lg := LogoView.new().setup(int(b.get("logo", 0)), b["name"], Color(str(b["color"])))
		lg.custom_minimum_size = Vector2(70, 70)
		var n := Corporate.brand_products(bid).filter(func(p): return p["status"] == "active").size()
		var sub := "%s · prestige %d · %d active products%s" % [DB.positionings[b["posit"]]["name"], int(float(b["prestige"]) * 100), n, " · independent" if b.get("independent", false) else ""]
		UI.row_card(body, b["name"], sub, G.money(Corporate.brand_value(b)), func(): Router.go("brand_detail", {"id": bid}), lg)
	body.add_child(UI.btn("+ Create a new brand ($50,000)", _create, "primary", 22))
	var old = G.s["brands"].values().filter(func(b): return b.get("origin", "") == G.pid() and b["company"] != G.pid() or (b["company"] == G.pid() and b.get("status", "") == "discontinued"))
	if not old.is_empty():
		UI.section(body, "Former brands")
		for b in old:
			UI.row_card(body, b["name"], "Owned by %s" % G.company(b["company"]).get("name", "?") if b["company"] != G.pid() else "Discontinued", "", Callable())


func _create() -> void:
	var st := {"name": "", "posit": "mass", "logo": 0, "color": "#d99aa5"}
	Router.modal("New brand", func(v: VBoxContainer):
		var e := UI.line_edit("", "Brand name")
		e.max_length = 24
		e.text_changed.connect(func(t): st["name"] = t)
		v.add_child(e)
		var pos: Array = []
		for p in DB.biz["positionings"]:
			pos.append([p["name"], p["id"]])
		v.add_child(UI.lbl("Positioning", 19, UI.MUTED))
		var sg := UI.seg(pos, st["posit"], func(x): pass)
		for b in sg.get_children():
			var btn := b as Button
			btn.pressed.connect(func():
				for p in DB.biz["positionings"]:
					if p["name"] == btn.text:
						st["posit"] = p["id"]
				for b2 in sg.get_children():
					UI.style_btn(b2 as Button, "chip_on" if b2 == btn else "chip", 21))
		v.add_child(sg)
		v.add_child(UI.lbl("Color", 19, UI.MUTED))
		var cols := [["Rose", "#d99aa5"], ["Gold", "#c9a55a"], ["Emerald", "#2f8a63"], ["Sapphire", "#4a6fb3"], ["Burgundy", "#8a2f45"], ["Copper", "#c27a4a"], ["Silver", "#c8ccd4"]]
		var cs := UI.seg(cols, st["color"], func(x): pass)
		for b3 in cs.get_children():
			var btn3 := b3 as Button
			btn3.pressed.connect(func():
				for cc in cols:
					if cc[0] == btn3.text:
						st["color"] = cc[1]
				for b4 in cs.get_children():
					UI.style_btn(b4 as Button, "chip_on" if b4 == btn3 else "chip", 21))
		v.add_child(cs), [["Cancel", Callable(), "secondary"], ["Create", func():
			var r := Corporate.create_brand(G.pc(), str(st["name"]), st["posit"], st["color"], G.rng.randi_range(0, 5))
			Router.toast(r if r != "" else "Brand created.", "bad" if r != "" else "good")
			G.touch(), "primary"]])
