extends Screen
## Ownership, investor funding, board of directors, IPO and dividends.

func page_title() -> String:
	return "Investors & board"


func build() -> void:
	var c := G.pc()
	UI.section(body, "Ownership")
	var oc := UI.card(body)
	for h in c["holders"]:
		var row := UI.hbox(8)
		var l := UI.lbl(str(h["name"]), 20, UI.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(UI.lbl(G.pct(float(h["pct"]), 1), 20, UI.GOLD2, "semi"))
		oc.add_child(row)
	UI.kv(oc, "Company valuation", G.money(FinanceEngine.valuation(c)), UI.GOLD2)
	UI.kv(oc, "Value of your stake", G.money(FinanceEngine.valuation(c) * Corporate.founder_pct(c)))
	if c.get("public", false):
		UI.kv(oc, "Share price", G.money(float(c.get("share_price", 0.0)), 2))
		var ph: Array = c.get("price_hist", [])
		if ph.size() > 2:
			var ch := LineChart.new()
			ch.min_zero = false
			ch.set_data([{"v": ph, "c": UI.GOLD}], [], "money")
			oc.add_child(ch)
	var bd: Dictionary = G.s["board"]
	if not bd.is_empty():
		UI.section(body, "Board of directors")
		var bc := UI.card(body)
		var conf := float(bd["confidence"])
		var row2 := UI.hbox(8)
		row2.add_child(UI.lbl("Confidence", 20, UI.MUTED))
		row2.add_child(UI.bar(conf / 100.0, UI.GREEN if conf >= 50.0 else (UI.AMBER if conf >= 30.0 else UI.RED), 12))
		row2.add_child(UI.lbl(str(int(conf)), 20, UI.TEXT, "semi"))
		bc.add_child(row2)
		for m in bd["members"]:
			bc.add_child(UI.lbl("%s — focus: %s" % [m["name"], m["focus"]], 18, UI.TEXT))
		bc.add_child(UI.lbl("Objectives for the quarter (review %s):" % G.short_date(int(bd.get("due", 0))), 18, UI.GOLD2, "semi"))
		for t in bd["targets"]:
			bc.add_child(UI.para("• %s (%s)" % [t["label"], t["by"]], 18, UI.TEXT))
		var hs: Array = bd.get("history", [])
		if not hs.is_empty():
			var last: Dictionary = hs[hs.size() - 1]
			bc.add_child(UI.para("Last review: " + ", ".join(last["res"].map(func(x): return ("✓ " if x[1] else "✕ ") + str(x[0]))), 17, UI.MUTED))
	if not c.get("public", false):
		UI.section(body, "Raise capital from investors")
		var offers := Corporate.investor_offers(c)
		if offers.is_empty():
			UI.empty(body, "Investors need to see traction first (about $300K in annual revenue).")
		for o in offers:
			var cc := UI.card(body, "flat", 6)
			cc.add_child(UI.lbl("%s offers %s for %s" % [o["fund"], G.money(float(o["amount"])), G.pct(float(o["pct"]))], 21, UI.CREAM, "semi"))
			cc.add_child(UI.lbl("Pre-money valuation %s. Outside owners above 20%% form a board." % G.money(float(o["pre"])), 17, UI.MUTED))
			var oo: Dictionary = o
			cc.add_child(UI.btn("Accept investment", func(): Router.confirm("Accept?", "You give up %s of the company for %s." % [G.pct(float(oo["pct"])), G.money(float(oo["amount"]))], func():
				Corporate.accept_investment(c, oo)
				G.touch()), "secondary", 20, 60))
		UI.section(body, "Initial public offering")
		var ic := UI.card(body)
		for r in Corporate.ipo_requirements(c):
			ic.add_child(UI.lbl(("✓ " if r[1] else "✕ ") + str(r[0]), 19, UI.GREEN if r[1] else UI.MUTED))
		if Corporate.can_ipo(c):
			ic.add_child(UI.btn("Go public (sell 25% new shares)", func(): Router.confirm("Launch IPO?", "Sell 25% new shares to the public at about %s company value. Bank fees 5%%. A board will oversee you." % G.money(FinanceEngine.valuation(c) * 0.92), func():
				Corporate.do_ipo(c, 0.25)
				G.touch()), "primary", 22))
	UI.section(body, "Dividends")
	var dc := UI.card(body, "flat")
	dc.add_child(UI.para("Pay out cash to shareholders. You receive your ownership share; the board likes dividends, your growth budget does not.", 18))
	dc.add_child(UI.btn("Pay a dividend…", func():
		var mx := FinanceEngine.cash_of(c) * 0.5
		if mx < 1000.0:
			Router.toast("Not enough cash.", "bad")
			return
		Router.number("Dividend", snappedf(mx * 0.2, 100.0), 1000.0, mx, 100.0, func(x):
			var r := Corporate.pay_dividend(c, x)
			Router.toast(r if r != "" else "Dividend paid.", "bad" if r != "" else "good")
			G.touch(), func(x): return G.money(x)), "secondary", 20, 62))
	UI.section(body, "Real-world support (optional)")
	var mc := UI.card(body, "flat")
	if Monet.ads_available():
		mc.add_child(UI.btn("Watch an ad for a small research grant", func():
			if not Monet.show_rewarded():
				Router.toast("No ad available right now."), "secondary", 20, 60))
	else:
		mc.add_child(UI.para("Optional ads and purchases are not available in this build. The full game is playable offline for free.", 17, UI.DIM))
