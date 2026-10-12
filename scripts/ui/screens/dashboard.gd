extends Screen
## Home: the player's fragrance house at a glance — illustrated headquarters with the flagship
## perfume, key figures, CEO notices, portfolio carousel, activity cards, expansion progress.

func page_title() -> String:
	return G.pc().get("name", "Home")


func env() -> String:
	return "home"


func build() -> void:
	var c := G.pc()
	if c.is_empty():
		return
	_hero(c)
	_kpis(c)
	if not Tutorial.done():
		_tutorial()
	_notices()
	_portfolio()
	_activities(c)
	_expansion(c)
	if Tutorial.done():
		_goals()
	_chart(c)
	_news()


# ---------------------------------------------------------------- hero
func _flagship() -> Dictionary:
	var prods := G.company_products(G.pid(), ["active", "dev"])
	if prods.is_empty():
		return {}
	prods.sort_custom(func(a, b): return float(a["st"]["rev"]) + Rivals.avg_units(a, 4) > float(b["st"]["rev"]) + Rivals.avg_units(b, 4))
	return prods[0]


func _hero(c: Dictionary) -> void:
	var tier := int(c["hq"]["tier"])
	var hero := Control.new()
	hero.custom_minimum_size = Vector2(0, 440)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(hero)
	var sv := Art.banner(Art.hq_scene(tier), 440, c["name"], 28)
	sv.set_anchors_preset(Control.PRESET_FULL_RECT)
	sv.focus = Vector2(0.5, 0.3)
	sv.fade = 0.55
	hero.add_child(sv)
	var tap := TapPanel.new()
	tap.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.tapped = func(): Router.go("hq")
	hero.add_child(tap)
	# identity chip
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", UI.shadowed(UI.sb(Color(1, 0.99, 0.97, 0.9), 20, Color(1, 1, 1, 0.9), 1, 12), 8))
	chip.position = Vector2(14, 14)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ch := UI.hbox(10)
	chip.add_child(ch)
	var bs := G.company_brands(G.pid())
	var lg := LogoView.new().setup(int(c.get("logo", 0)), str(bs[0]["name"]) if not bs.is_empty() else c["name"], UI.BURGUNDY)
	lg.custom_minimum_size = Vector2(58, 58)
	ch.add_child(lg)
	var cv := UI.vbox(0)
	cv.add_child(UI.lbl(DB.hq_tier(tier)["name"], 19, UI.BURGUNDY, "semi"))
	cv.add_child(UI.lbl(DB.country(c["home"])["name"] + "  ·  " + _rep_stars(float(c.get("reputation", 0.3))), 17, UI.MUTED, "medium"))
	ch.add_child(cv)
	hero.add_child(chip)
	# flagship bottle
	var fp := _flagship()
	var glow := Glow.new()
	glow.color = Color("#fffaf0")
	glow.strength = 1.6
	_anchor_br(glow, -270, -330, 10, -30)
	hero.add_child(glow)
	var bv := BottleView.new()
	if fp.is_empty():
		bv.setup({"shape": 6, "cap": 6, "glass": 0, "label": 1, "accent": "#c9a55a"}, str(bs[0]["name"]) if not bs.is_empty() else "", "Your first", PackedFloat32Array())
		bv.liquid = Color("#f3e3b0")
	else:
		bv.setup(fp["bottle"], G.brand(fp["brand"]).get("name", ""), fp["name"], MarketEngine.product_ev(fp).get("profile", PackedFloat32Array()))
	bv.vivid = true
	_anchor_br(bv, -220, -330, -40, -40)
	hero.add_child(bv)
	# caption
	var cap := UI.vbox(0)
	cap.anchor_top = 1.0
	cap.anchor_bottom = 1.0
	cap.offset_left = 24
	cap.offset_right = 470
	cap.offset_top = -116
	cap.offset_bottom = -20
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(UI.lbl("FLAGSHIP" if not fp.is_empty() else "YOUR HOUSE", 16, Color("#f3dca0"), "semi"))
	var nm := UI.title(fp.get("name", "Compose your first perfume"), 34 if not fp.is_empty() else 30, Color("#fffaf3"))
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cap.add_child(nm)
	if not fp.is_empty():
		var wk: Array = fp["wk"]
		var u := int(wk[wk.size() - 1][1]) if not wk.is_empty() else 0
		var rt: Dictionary = fp["rating"]
		var stars := ("  ·  ★ %.1f" % (float(rt["sum"]) / float(rt["n"]))) if int(rt["n"]) > 0 else ""
		cap.add_child(UI.lbl("%s units last week%s" % [G.group_int(u), stars], 19, Color("#f6e6dc"), "medium"))
	else:
		cap.add_child(UI.lbl("Start in the Laboratory", 19, Color("#f6e6dc"), "medium"))
	hero.add_child(cap)


static func _anchor_br(n: Control, l: float, t: float, r: float, b: float) -> void:
	n.anchor_left = 1.0
	n.anchor_right = 1.0
	n.anchor_top = 1.0
	n.anchor_bottom = 1.0
	n.offset_left = l
	n.offset_top = t
	n.offset_right = r
	n.offset_bottom = b


func _rep_stars(r: float) -> String:
	var n := clampi(int(round(r * 5.0)), 0, 5)
	var s := ""
	for i in 5:
		s += "★" if i < n else "☆"
	return s


# ---------------------------------------------------------------- figures
func _kpis(c: Dictionary) -> void:
	var p4 := FinanceEngine.summarize(FinanceEngine.period(c, 4))
	var p4b := FinanceEngine.summarize(FinanceEngine.period(c, 4, 4))
	var h := UI.hbox(10)
	var cash := FinanceEngine.cash_of(c)
	h.add_child(_kpi("finance", "Cash", G.money(cash), "Debt " + G.money(float(c["fin"]["debt"])) if float(c["fin"]["debt"]) > 0.0 else "No debt", UI.BURGUNDY, func(): Router.go_tab("finance")))
	var rv := float(p4["revenue"])
	h.add_child(_kpi("chart", "Revenue · 4 wks", G.money(rv), UI.trend_text(rv, float(p4b["revenue"])), UI.GOLD, func(): Router.go("reports")))
	var net := float(p4["net"])
	h.add_child(_kpi("star", "Net · 4 wks", G.money(net), "margin " + G.pct(float(p4["margin"])), UI.GREEN if net >= 0.0 else UI.RED, func(): Router.go("statements")))
	body.add_child(h)


func _kpi(ic: String, label: String, value: String, sub: String, col: Color, cb: Callable) -> Control:
	var p := GradPanel.new().colors(Color("#fffdf9"), Color("#f8efe6")).set_pad(12)
	p.tapped = cb
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(2)
	p.add_child(v)
	var top := UI.hbox(6)
	top.add_child(UI.icon_bubble(ic, col, 34))
	var l := UI.lbl(label, 15, UI.MUTED, "semi")
	l.clip_text = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(l)
	v.add_child(top)
	var vl := UI.lbl(value, 27, col if col != UI.GOLD else UI.CREAM, "title")
	vl.clip_text = true
	v.add_child(vl)
	if sub != "":
		var sl := UI.lbl(sub, 15, UI.MUTED, "medium")
		sl.clip_text = true
		v.add_child(sl)
	return p


# ---------------------------------------------------------------- guidance
func _tutorial() -> void:
	var st := Tutorial.step()
	var s: Array = Tutorial.STEPS[st]
	var tc := GradPanel.new().colors(Color("#fdf3e3"), Color("#f7e2dc")).set_pad(18)
	tc.border = Color(UI.GOLD, 0.5)
	body.add_child(tc)
	var outer := UI.vbox(12)
	tc.add_child(outer)
	var row := UI.hbox(14)
	outer.add_child(row)
	var art_name: String = ["lab", "lab", "boutique", "hq1"][clampi(st, 0, 3)]
	var thumb := Art.banner(art_name, 150, "", 18)
	thumb.custom_minimum_size = Vector2(150, 150)
	thumb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	thumb.focus = Vector2(0.6, 0.6)
	row.add_child(thumb)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UI.pill("STEP %d / %d · YOUR FIRST LAUNCH" % [st + 1, Tutorial.STEPS.size()], UI.BURGUNDY, 15))
	v.add_child(UI.lbl(s[0], 26, UI.CREAM, "title", HORIZONTAL_ALIGNMENT_LEFT, true))
	v.add_child(UI.para(s[1], 18, UI.TEXT))
	var bh := UI.hbox(10)
	match st:
		0:
			bh.add_child(UI.btn("Create a formula", func(): Router.go("formula_editor", {}), "primary", 21, 64))
		1:
			bh.add_child(UI.btn("Test it", func(): Router.go("tests", {}), "primary", 21, 64))
			bh.add_child(UI.btn("Skip", func():
				Tutorial.skip_test()
				rebuild(), "secondary", 21, 64))
		2:
			bh.add_child(UI.btn("Launch a perfume", func(): Router.go("launch", {}), "primary", 21, 64))
		_:
			bh.add_child(UI.btn("Next week ▸", func(): Router.next_week(), "primary", 21, 64))
	outer.add_child(bh)


func _notices() -> void:
	var open := G.inbox_open()
	if open.is_empty():
		return
	UI.section(body, "CEO desk · %d decision%s" % [open.size(), "" if open.size() == 1 else "s"], UI.btn("View all", func(): Router.go("inbox"), "ghost", 19, 44))
	for m in open.slice(open.size() - mini(2, open.size())):
		var mid: String = m["id"]
		var p := GradPanel.new().colors(Color("#fffaf6"), Color("#fbefe9")).set_pad(14)
		p.border = Color(UI.ROSE, 0.35)
		p.tapped = func(): Inbox.open_item(mid)
		var h := UI.hbox(12)
		p.add_child(h)
		var kind: String = m.get("type", "")
		var col := UI.ROSE
		var ic := "mail"
		match kind:
			"recall", "scandal", "distress", "shortage":
				col = UI.RED
			"qc":
				col = UI.AMBER
			"poach", "deleg_hire":
				col = UI.PLUM
				ic = "users"
		h.add_child(UI.icon_bubble(ic, col, 46))
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t := UI.lbl(str(m["title"]), 21, UI.TEXT, "semi")
		t.clip_text = true
		t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(t)
		var tx := str(m.get("text", ""))
		v.add_child(UI.lbl(tx.substr(0, 80) + ("…" if tx.length() > 80 else ""), 17, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
		h.add_child(v)
		h.add_child(UI.lbl("›", 34, UI.DIM, "title"))
		body.add_child(p)


# ---------------------------------------------------------------- portfolio carousel
func _portfolio() -> void:
	var prods := G.company_products(G.pid(), ["active", "dev"])
	prods.sort_custom(func(a, b): return Rivals.avg_units(a, 1) > Rivals.avg_units(b, 1))
	UI.section(body, "Your perfumes", UI.btn("All", func(): Router.go_tab("products"), "ghost", 19, 44))
	var sc := DragScroll.new()
	sc.horizontal = true
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.custom_minimum_size = Vector2(0, 340)
	var row := UI.hbox(14)
	sc.add_child(row)
	for p in prods.slice(0, 10):
		row.add_child(ProductCard.make(p, 196, 326))
	row.add_child(_new_card())
	row.add_child(UI.spacer(4, 4))
	body.add_child(sc)


func _new_card() -> Control:
	var p := GradPanel.new().colors(Color("#f3effa"), Color("#eadff3")).set_pad(12)
	p.border = Color(UI.PLUM, 0.25)
	p.tapped = func(): Router.go("formula_editor", {})
	p.custom_minimum_size = Vector2(196, 326)
	var v := UI.vbox(10)
	p.add_child(v)
	var th := Art.banner("lab", 180, "", 16)
	th.focus = Vector2(0.75, 0.5)
	v.add_child(th)
	v.add_child(UI.lbl("+ New perfume", 22, UI.PLUM, "semi", HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.lbl("Compose a formula in the laboratory", 16, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER, true))
	return p


# ---------------------------------------------------------------- activities
func _activities(c: Dictionary) -> void:
	UI.section(body, "Your company")
	var g := UI.grid(2, 12)
	var forms: int = G.s["formulas"].values().filter(func(f): return f["company"] == G.pid() and not f.get("archived", false)).size()
	var props: int = G.s["proposals"].filter(func(p): return p["company"] == G.pid() and p["status"] == "open").size()
	var orders: int = G.s["orders"].filter(func(o): return o["company"] == G.pid()).size()
	var camps: int = G.s["campaigns"].filter(func(k): return k["company"] == G.pid() and k["status"] == "active").size()
	var offices: int = c["offices"].size()
	var ag := _agreements()
	g.add_child(_activity("lab", "Laboratory", "%d formulas · %d proposal%s" % [forms, props, "" if props == 1 else "s"], func(): Router.go_tab("lab"), props))
	g.add_child(_activity("factory", "Production", ("%d batch%s in progress" % [orders, "" if orders == 1 else "es"]) if orders > 0 else "No batches running", func(): Router.go("production")))
	g.add_child(_activity("studio", "Marketing", ("%d campaign%s live" % [camps, "" if camps == 1 else "s"]) if camps > 0 else "No campaigns running", func(): Router.go("marketing")))
	g.add_child(_activity("world", "World markets", "%d of %d markets" % [offices, DB.countries.size()], func(): Router.go("world_map")))
	g.add_child(_activity("office", "People", "%d employee%s" % [Staff.count(G.pid()), "" if Staff.count(G.pid()) == 1 else "s"], func(): Router.go("staff")))
	g.add_child(_activity("boutique", "Retail", "%d retail partner%s" % [ag, "" if ag == 1 else "s"], func(): Router.go("distribution")))
	body.add_child(g)


func _agreements() -> int:
	return G.s["channels"].filter(func(a): return a["company"] == G.pid() and a.get("active", true)).size()


func _activity(art: String, title: String, sub: String, cb: Callable, badge := 0) -> Control:
	var p := GradPanel.new().colors(Color("#fffdf9"), Color("#f8eee6")).set_pad(10)
	p.tapped = cb
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(6)
	p.add_child(v)
	var th := Art.banner(art, 150, "", 16)
	th.focus = Vector2(0.5, 0.55)
	v.add_child(th)
	var tr := UI.hbox(6)
	var t := UI.lbl(title, 22, UI.CREAM, "semi")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr.add_child(t)
	if badge > 0:
		tr.add_child(UI.pill(str(badge), UI.RED, 15))
	v.add_child(tr)
	var s := UI.lbl(sub, 16, UI.MUTED, "medium")
	s.clip_text = true
	s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(s)
	return p


# ---------------------------------------------------------------- expansion
func _expansion(c: Dictionary) -> void:
	UI.section(body, "House expansion")
	var p := GradPanel.new().colors(Color("#fffdf9"), Color("#f6ece2")).set_pad(18)
	p.tapped = func(): Router.go("hq")
	body.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	var tier := int(c["hq"]["tier"])
	var steps := TierPath.new()
	steps.tier = tier
	steps.custom_minimum_size = Vector2(0, 128)
	v.add_child(steps)
	if tier < 4:
		var nt := DB.hq_tier(tier + 1)
		v.add_child(UI.lbl("Next: %s · %s" % [nt["name"], G.money(float(nt["cost"]))], 19, UI.BURGUNDY, "semi", HORIZONTAL_ALIGNMENT_LEFT, true))
	else:
		v.add_child(UI.lbl("Your house has reached the top tier.", 19, UI.BURGUNDY, "semi"))
	var t := DB.hq_tier(tier)
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 8)
	f.add_theme_constant_override("v_separation", 8)
	f.add_child(UI.pill("Markets %d / %d" % [c["offices"].size(), DB.countries.size()], UI.BLUE, 17))
	f.add_child(UI.pill("Staff %d / %d" % [Staff.count(G.pid()), int(t.get("staff", 0))], UI.PLUM, 17))
	f.add_child(UI.pill("Brands %d / %d" % [G.company_brands(G.pid()).size(), int(t.get("brands", 1))], UI.ROSE, 17))
	f.add_child(UI.pill("Perfumes %d" % G.company_products(G.pid()).size(), UI.GOLD, 17))
	v.add_child(f)


func _goals() -> void:
	var c := G.pc()
	var goals: Array = []
	var t := FinanceEngine.ttm(c)
	var prods := G.company_products(G.pid()).size()
	if Staff.count(G.pid(), "perfumer") == 0:
		goals.append(["Hire your first perfumer", "Perfumers create formula proposals for you.", "recruit", "users"])
	if prods < 3:
		goals.append(["Build a portfolio of 3 products", "%d / 3 active products" % prods, "launch", "bottle"])
	if c["offices"].size() < 2:
		goals.append(["Open your first foreign office", "Unlocks retail partners abroad.", "world_map", "globe"])
	if int(c["hq"]["tier"]) < 2:
		goals.append(["Upgrade to a Regional Fragrance Company", "More staff, brands and project slots.", "hq", "company"])
	if float(t["revenue"]) < 1e6:
		goals.append(["Reach $1M annual revenue", "%s over the last 52 weeks" % G.money(float(t["revenue"])), "finance", "chart"])
	elif float(t["revenue"]) < 4e7:
		goals.append(["Reach $40M revenue (IPO size)", "%s over the last 52 weeks" % G.money(float(t["revenue"])), "investors", "chart"])
	if goals.is_empty():
		return
	UI.section(body, "Goals")
	for gl in goals.slice(0, 3):
		var dest: String = gl[2]
		UI.row_card(body, gl[0], gl[1], "", func():
			if dest == "finance":
				Router.go_tab("finance")
			else:
				Router.go(dest, {}), UI.icon_bubble(gl[3], UI.GOLD, 46))


# ---------------------------------------------------------------- chart & news
func _chart(c: Dictionary) -> void:
	var hist: Array = c["fin"]["hist"]
	if hist.size() < 2:
		return
	UI.section(body, "Weekly revenue & net result")
	var cc := UI.card(body)
	var ch := LineChart.new()
	var rv: Array = []
	var nt: Array = []
	var xl: Array = []
	var sl := hist.slice(maxi(0, hist.size() - 26))
	for i in sl.size():
		rv.append(float(sl[i].get("revenue", 0.0)))
		nt.append(float(sl[i].get("net", 0.0)))
		xl.append(G.short_date(int(sl[i]["w"])) if i % 6 == 0 else "")
	ch.min_zero = false
	ch.set_data([{"v": rv, "c": UI.GOLD}, {"v": nt, "c": UI.ROSE}], xl)
	cc.add_child(ch)
	var lgd := UI.hbox(16)
	lgd.add_child(UI.lbl("● Revenue", 18, UI.GOLD))
	lgd.add_child(UI.lbl("● Net result", 18, UI.ROSE))
	cc.add_child(lgd)


func _news() -> void:
	UI.section(body, "Industry news")
	var lg2: Array = G.s["log"]
	if lg2.is_empty():
		UI.empty(body, "Industry news will appear here.")
		return
	var nc := UI.card(body, "dark", 10)
	for i in range(lg2.size() - 1, maxi(-1, lg2.size() - 8), -1):
		var e: Dictionary = lg2[i]
		var col := UI.TEXT
		var dot := UI.DIM
		match e.get("k", "info"):
			"good":
				col = UI.GREEN
				dot = UI.GREEN
			"bad":
				col = UI.RED
				dot = UI.RED
			"warn":
				col = UI.AMBER
				dot = UI.AMBER
		var row := UI.hbox(10)
		row.add_child(UI.lbl("●", 14, dot))
		var l := UI.lbl(str(e["t"]), 18, col, "body", HORIZONTAL_ALIGNMENT_LEFT, true)
		row.add_child(l)
		row.add_child(UI.lbl(G.short_date(int(e["w"])), 15, UI.DIM))
		nc.add_child(row)
