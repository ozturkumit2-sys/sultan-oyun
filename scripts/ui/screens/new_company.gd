extends Screen
## Company creation.

const PALETTES := [["Gold & Onyx", "#c9a55a", "#1c1a20"], ["Rose & Ivory", "#d99aa5", "#f3ebdd"], ["Emerald & Gold", "#2f8a63", "#c9a55a"],
	["Sapphire & Silver", "#4a6fb3", "#c8ccd4"], ["Burgundy & Cream", "#8a2f45", "#f3ebdd"], ["Copper & Smoke", "#c27a4a", "#3a3a40"]]

var st := {"company": "Maison Lumière", "brand": "Lumière", "home": "TR", "pal": 0, "logo": 0, "posit": "premium", "difficulty": "normal"}
var name_edit: LineEdit
var brand_edit: LineEdit


func build() -> void:
	body.add_child(UI.spacer(10))
	var head := UI.hbox(14)
	head.add_child(UI.btn("‹", func(): Router.back(), "ghost", 40, 70))
	head.add_child(UI.title("Found your house", 40))
	body.add_child(head)
	var pv := UI.card(body, "gold")
	var ph := UI.hbox(18)
	var pal: Array = PALETTES[int(st["pal"])]
	var lg := LogoView.new().setup(int(st["logo"]), str(st["brand"]), Color(pal[1]))
	lg.custom_minimum_size = Vector2(130, 130)
	ph.add_child(lg)
	var pvv := UI.vbox(4)
	pvv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pvv.add_child(UI.title(str(st["company"]), 30))
	pvv.add_child(UI.lbl("%s · %s brand" % [DB.country(st["home"])["name"], DB.positionings[st["posit"]]["name"]], 20, UI.MUTED))
	pvv.add_child(UI.lbl("Starting capital: %s" % {"easy": "$150,000", "normal": "$100,000", "hard": "$75,000"}[st["difficulty"]], 20, UI.GOLD2, "semi"))
	ph.add_child(pvv)
	var bt := BottleView.new().setup({"shape": 0, "cap": 1, "glass": 0, "label": 1, "accent": pal[1]}, str(st["brand"]), "No. 1")
	bt.custom_minimum_size = Vector2(110, 170)
	ph.add_child(bt)
	pv.add_child(ph)
	UI.section(body, "Company name")
	name_edit = UI.line_edit(str(st["company"]), "Company name")
	name_edit.max_length = 28
	name_edit.text_changed.connect(func(t): st["company"] = t)
	name_edit.focus_exited.connect(func(): rebuild())
	body.add_child(name_edit)
	UI.section(body, "First brand")
	brand_edit = UI.line_edit(str(st["brand"]), "Brand name")
	brand_edit.max_length = 24
	brand_edit.text_changed.connect(func(t): st["brand"] = t)
	brand_edit.focus_exited.connect(func(): rebuild())
	body.add_child(brand_edit)
	UI.section(body, "Headquarters")
	var opts: Array = []
	for c in DB.countries:
		opts.append([c["name"], c["id"]])
	body.add_child(UI.seg(opts, st["home"], func(v): _setv("home", v)))
	var ct := DB.country(st["home"])
	body.add_child(UI.para("Weekly fragrance buyers: %s · Corporate tax %s · Purchasing power %s" % [G.group_int(int(float(ct["buyers"]) * 0.25)), G.pct(float(ct["tax"])), "%.0f%%" % (float(ct["ppp"]) * 100)], 19))
	UI.section(body, "Color scheme")
	var popts: Array = []
	for i in PALETTES.size():
		popts.append([PALETTES[i][0], i])
	body.add_child(UI.seg(popts, int(st["pal"]), func(v): _setv("pal", v)))
	UI.section(body, "Logo style")
	var lr := HFlowContainer.new()
	lr.add_theme_constant_override("h_separation", 10)
	for i in 6:
		var p := TapPanel.new()
		p.add_theme_stylebox_override("panel", UI.sb(UI.PANEL2 if i != int(st["logo"]) else Color(0.79, 0.65, 0.35, 0.2), 14, UI.GOLD if i == int(st["logo"]) else UI.LINE, 2 if i == int(st["logo"]) else 1, 8))
		var l := LogoView.new().setup(i, str(st["brand"]), Color(pal[1]))
		l.custom_minimum_size = Vector2(84, 84)
		p.add_child(l)
		var idx := i
		p.tapped = func(): _setv("logo", idx)
		lr.add_child(p)
	body.add_child(lr)
	UI.section(body, "Market positioning")
	var pos: Array = []
	for p in DB.biz["positionings"]:
		pos.append([p["name"], p["id"]])
	body.add_child(UI.seg(pos, st["posit"], func(v): _setv("posit", v)))
	body.add_child(UI.para({"budget": "Affordable everyday scents; volume over margin.", "mass": "Mainstream appeal with broad retail reach.",
		"premium": "Quality fragrances at accessible luxury prices.", "luxury": "Prestige, craftsmanship and high prices. Needs brand building.",
		"niche": "Artistic, unusual compositions for connoisseurs."}[st["posit"]], 20))
	UI.section(body, "Difficulty")
	body.add_child(UI.seg([["Easy", "easy"], ["Normal", "normal"], ["Hard", "hard"]], st["difficulty"], func(v): _setv("difficulty", v)))
	body.add_child(UI.para("Difficulty changes starting capital and rival strength. Fragrance chemistry is identical on every level.", 19))
	body.add_child(UI.spacer(10))
	body.add_child(UI.btn("Open my laboratory", _start, "primary", 26, 86))


func _setv(k: String, v: Variant) -> void:
	st[k] = v
	rebuild()


func _start() -> void:
	var cname := str(st["company"]).strip_edges()
	var bname := str(st["brand"]).strip_edges()
	if cname.length() < 2 or bname.length() < 2:
		Router.toast("Please enter a company and brand name.", "bad")
		return
	var pal: Array = PALETTES[int(st["pal"])]
	WorldGen.new_game({"company": cname, "brand": bname, "home": st["home"], "color": pal[1], "color2": pal[2],
		"logo": st["logo"], "posit": st["posit"], "difficulty": st["difficulty"]})
	Save.save_game("auto")
	Router.start_game()
