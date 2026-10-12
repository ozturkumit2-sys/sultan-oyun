extends Screen
## CEO dashboard: KPIs, guidance, charts, inbox, products and news.

func page_title() -> String:
	return G.pc().get("name", "Dashboard")


func build() -> void:
	var c := G.pc()
	if c.is_empty():
		return
	# hero
	var hero := UI.card(body, "gold")
	var hh := UI.hbox(16)
	var bs := G.company_brands(G.pid())
	var lg := LogoView.new().setup(int(c.get("logo", 0)), str(bs[0]["name"]) if not bs.is_empty() else c["name"], Color(str(c.get("color", "#c9a55a"))))
	lg.custom_minimum_size = Vector2(96, 96)
	hh.add_child(lg)
	var hv := UI.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UI.title(c["name"], 32))
	hv.add_child(UI.lbl("%s · %s" % [DB.hq_tier(int(c["hq"]["tier"]))["name"], DB.country(c["home"])["name"]], 19, UI.MUTED, "medium"))
	var rep := float(c.get("reputation", 0.3))
	var rr := UI.hbox(8)
	rr.add_child(UI.lbl("Reputation", 18, UI.MUTED))
	rr.add_child(UI.bar(rep, UI.GOLD, 10))
	rr.add_child(UI.lbl("%d" % int(rep * 100), 18, UI.GOLD2, "semi"))
	hv.add_child(rr)
	hh.add_child(hv)
	hero.add_child(hh)
	# KPIs
	var p4 := FinanceEngine.summarize(FinanceEngine.period(c, 4))
	var p4b := FinanceEngine.summarize(FinanceEngine.period(c, 4, 4))
	var g := UI.grid(2, 10)
	g.add_child(UI.stat("Cash", G.money(FinanceEngine.cash_of(c)), "Debt " + G.money(float(c["fin"]["debt"])) if float(c["fin"]["debt"]) > 0.0 else "No debt", UI.CREAM))
	g.add_child(UI.stat("Revenue (4 wks)", G.money(float(p4["revenue"])), UI.trend_text(float(p4["revenue"]), float(p4b["revenue"])), UI.CREAM, UI.GREEN if float(p4["revenue"]) >= float(p4b["revenue"]) else UI.RED))
	var net := float(p4["net"])
	g.add_child(UI.stat("Net result (4 wks)", G.money(net), "Gross margin " + G.pct(float(p4["margin"])), UI.GREEN if net >= 0.0 else UI.RED))
	g.add_child(UI.stat("Valuation", G.money(FinanceEngine.valuation(c)), "%d active products" % G.company_products(G.pid()).size(), UI.GOLD2))
	body.add_child(g)
	# tutorial / goals
	if not Tutorial.done():
		var st := Tutorial.step()
		var s: Array = Tutorial.STEPS[st]
		var tc := UI.card(body, "gold")
		var th := UI.hbox(10)
		th.add_child(UI.pill("STEP %d / %d" % [st + 1, Tutorial.STEPS.size()], UI.GOLD))
		th.add_child(UI.lbl("Your first launch", 20, UI.GOLD2, "semi"))
		tc.add_child(th)
		tc.add_child(UI.title(s[0], 30))
		tc.add_child(UI.para(s[1], 21, UI.TEXT))
		var bh := UI.hbox(10)
		match st:
			0:
				bh.add_child(UI.expand(UI.btn("Create a formula", func(): Router.go("formula_editor", {}), "primary", 22)))
			1:
				bh.add_child(UI.expand(UI.btn("Test it", func(): Router.go("tests", {}), "primary", 22)))
				bh.add_child(UI.expand(UI.btn("Skip", func():
					Tutorial.skip_test()
					rebuild(), "secondary", 22)))
			2:
				bh.add_child(UI.expand(UI.btn("Launch a perfume", func(): Router.go("launch", {}), "primary", 22)))
			_:
				bh.add_child(UI.expand(UI.btn("Next week ▸", func(): Router.next_week(), "primary", 22)))
		tc.add_child(bh)
	else:
		_goals()
	# chart
	var hist: Array = c["fin"]["hist"]
	if hist.size() >= 2:
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
	# inbox
	var open := G.inbox_open()
	UI.section(body, "Inbox", UI.btn("View all", func(): Router.go("inbox"), "ghost", 19, 44) if not open.is_empty() else null)
	if open.is_empty():
		UI.empty(body, "No pending decisions.")
	else:
		for m in open.slice(open.size() - mini(3, open.size())):
			var mid: String = m["id"]
			UI.row_card(body, str(m["title"]), str(m.get("text", "")).substr(0, 90) + ("…" if str(m.get("text", "")).length() > 90 else ""), "", func(): Inbox.open_item(mid))
	# products
	var prods := G.company_products(G.pid(), ["active", "dev"])
	UI.section(body, "Portfolio", UI.btn("All products", func(): Router.go_tab("products"), "ghost", 19, 44))
	if prods.is_empty():
		UI.empty(body, "No products yet. Create a formula in the Lab and launch your first perfume.")
	else:
		prods.sort_custom(func(a, b): return Rivals.avg_units(a, 1) > Rivals.avg_units(b, 1))
		for p in prods.slice(0, 4):
			ProductRow.add(body, p)
	# quick actions
	UI.section(body, "Quick actions")
	var qa := UI.grid(2, 10)
	qa.add_child(UI.btn("New formula", func(): Router.go("formula_editor", {}), "secondary", 21, 70))
	qa.add_child(UI.btn("Production", func(): Router.go("production"), "secondary", 21, 70))
	qa.add_child(UI.btn("Hire staff", func(): Router.go("recruit"), "secondary", 21, 70))
	qa.add_child(UI.btn("Marketing", func(): Router.go("marketing"), "secondary", 21, 70))
	body.add_child(qa)
	# news
	UI.section(body, "News")
	var lg2: Array = G.s["log"]
	if lg2.is_empty():
		UI.empty(body, "Industry news will appear here.")
	var nc := UI.card(body, "flat", 8)
	for i in range(lg2.size() - 1, maxi(-1, lg2.size() - 9), -1):
		var e: Dictionary = lg2[i]
		var col := UI.TEXT
		match e.get("k", "info"):
			"good":
				col = UI.GREEN
			"bad":
				col = UI.RED
			"warn":
				col = UI.AMBER
		var row := UI.hbox(10)
		row.add_child(UI.lbl(G.short_date(int(e["w"])), 16, UI.DIM))
		var l := UI.lbl(str(e["t"]), 19, col, "body", HORIZONTAL_ALIGNMENT_LEFT, true)
		row.add_child(l)
		nc.add_child(row)


func _goals() -> void:
	var c := G.pc()
	var goals: Array = []
	var t := FinanceEngine.ttm(c)
	var prods := G.company_products(G.pid()).size()
	if Staff.count(G.pid(), "perfumer") == 0:
		goals.append(["Hire your first perfumer", "Perfumers create formula proposals for you.", "recruit"])
	if prods < 3:
		goals.append(["Build a portfolio of 3 products", "%d / 3 active products" % prods, "launch"])
	if c["offices"].size() < 2:
		goals.append(["Open your first foreign office", "Unlocks retail partners abroad.", "world_map"])
	if int(c["hq"]["tier"]) < 2:
		goals.append(["Upgrade to a Regional Fragrance Company", "More staff, brands and project slots.", "hq"])
	if float(t["revenue"]) < 1e6:
		goals.append(["Reach $1M annual revenue", "%s over the last 52 weeks" % G.money(float(t["revenue"])), "finance"])
	elif float(t["revenue"]) < 4e7:
		goals.append(["Reach $40M revenue (IPO size)", "%s over the last 52 weeks" % G.money(float(t["revenue"])), "investors"])
	if goals.is_empty():
		return
	UI.section(body, "Goals")
	for gl in goals.slice(0, 3):
		var dest: String = gl[2]
		UI.row_card(body, gl[0], gl[1], "", func():
			if dest == "finance":
				Router.go_tab("finance")
			else:
				Router.go(dest, {}))
