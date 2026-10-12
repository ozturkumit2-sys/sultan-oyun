extends Screen
## Mergers & acquisitions.

func page_title() -> String:
	return "Acquisitions"


func hero_spec() -> Dictionary:
	return {"scene": "hq4", "title": "Mergers & acquisitions", "sub": "Buy a rival house — brands, people and all", "focus": Vector2(0.5, 0.35), "h": 250.0}


func build() -> void:
	var c := G.pc()
	body.add_child(UI.para("Buying a rival transfers its brands, products, formulas, stock, staff, offices, retail agreements, cash and debts — exactly once. Expect integration costs and some staff unrest.", 19))
	UI.kv(body, "Your cash", G.money(FinanceEngine.cash_of(c)), UI.GOLD2)
	UI.kv(body, "Credit limit (loans)", G.money(FinanceEngine.credit_limit(c)))
	for t in G.s["companies"].values():
		if t.get("is_player", false) or not t.get("active", true):
			continue
		var tt := FinanceEngine.ttm(t)
		var ask := Corporate.ask_price(t)
		var cc := UI.card(body, "gold" if params.get("target", "") == t["id"] else "dark")
		var h := UI.hbox(8)
		h.add_child(UI.lbl(t["name"], 23, UI.CREAM, "semi"))
		h.add_child(UI.expand(UI.spacer()))
		h.add_child(UI.lbl(G.money(FinanceEngine.valuation(t)), 21, UI.GOLD2, "title"))
		cc.add_child(h)
		cc.add_child(UI.lbl("Revenue %s · net %s · cash %s · debt %s" % [G.money(float(tt["revenue"])), G.money(float(tt["net"])), G.money(FinanceEngine.cash_of(t)), G.money(float(t["fin"]["debt"]))], 17, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
		cc.add_child(UI.lbl("%d brands · %d products · %d staff · %d offices" % [G.company_brands(t["id"]).size(), G.company_products(t["id"]).size(), Staff.count(t["id"]), t["offices"].size()], 17, UI.MUTED))
		cc.add_child(UI.lbl(Corporate.willingness(t), 18, UI.GOLD2))
		var tid: String = t["id"]
		var row := UI.hbox(8)
		row.add_child(UI.btn("Profile", func(): Router.go("competitor", {"id": tid}), "secondary", 19, 58))
		row.add_child(UI.btn("Make an offer", func(): _offer(tid, ask), "primary", 19, 58))
		cc.add_child(row)


func _offer(tid: String, ask: float) -> void:
	var t := G.company(tid)
	var val := FinanceEngine.valuation(t)
	Router.number("Offer for %s" % t["name"], snappedf(val * 1.1, 1000.0), snappedf(val * 0.5, 1000.0), snappedf(val * 2.0, 1000.0), snappedf(maxf(1000.0, val / 200.0), 1000.0), func(x):
		var r := Corporate.make_offer(G.pc(), t, x)
		if r["ok"]:
			Router.info("Acquisition complete", r["msg"] + " Its brands now appear in your portfolio as independent brands.")
		elif r.has("counter"):
			Router.confirm("Counter-offer", r["msg"], func():
				var r2 := Corporate.make_offer(G.pc(), t, float(r["counter"]))
				Router.toast(r2["msg"], "good" if r2["ok"] else "bad")
				G.touch(), "Accept %s" % G.money(float(r["counter"])))
		else:
			Router.toast(r["msg"], "bad")
		G.touch(), func(x): return G.money(x), "Estimated value %s. Owners usually want a premium; distressed companies sell for less." % G.money(val))
