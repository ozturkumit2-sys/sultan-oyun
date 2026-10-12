extends Screen
## Marketing: campaigns with spend, reach and estimated ROI; influencer & celebrity contracts.

var tab := "campaigns"


func page_title() -> String:
	return "Marketing"


func build() -> void:
	var c := G.pc()
	var spend4 := -float(FinanceEngine.period(c, 4).get("marketing", 0.0))
	var g := UI.hbox(10)
	g.add_child(UI.stat("Spent (4 wks)", G.money(spend4)))
	g.add_child(UI.stat("Active campaigns", str(G.s["campaigns"].filter(func(k): return k["company"] == G.pid() and k["status"] == "active").size())))
	body.add_child(g)
	body.add_child(UI.btn("+ New campaign", func(): Router.go("campaign_new", {}), "primary", 22))
	body.add_child(UI.seg([["Campaigns", "campaigns"], ["Influencers", "influencers"], ["Celebrities", "celebs"], ["Brand budgets", "budgets"]], tab, func(v):
		tab = v
		rebuild()))
	match tab:
		"campaigns":
			var ks = G.s["campaigns"].filter(func(k): return k["company"] == G.pid())
			if ks.is_empty():
				UI.empty(body, "No campaigns yet.")
			for i in range(ks.size() - 1, maxi(-1, ks.size() - 30), -1):
				_camp(ks[i])
		"influencers", "celebs":
			var kind := "influencer" if tab == "influencers" else "celebrity"
			body.add_child(UI.para("All personalities are fictional. Fit with the product's audience, their reputation and engagement determine impact." if kind == "influencer" else "Ambassador contracts run for months and lift brand prestige — but celebrities can become controversial.", 18))
			var ms: Array = G.s["media"].values().filter(func(m): return m["kind"] == kind)
			ms.sort_custom(func(a, b): return float(a["followers"]) > float(b["followers"]))
			for m in ms:
				MediaRow.add(body, m)
		"budgets":
			body.add_child(UI.para("Always-on brand budgets are set on each brand page.", 18))
			for b in G.company_brands(G.pid()):
				var bid: String = b["id"]
				UI.row_card(body, b["name"], DB.positionings[b["posit"]]["name"], G.money(float(b.get("budget", 0.0))) + "/wk", func(): Router.go("brand_detail", {"id": bid}))
			var c2 := UI.card(body, "flat")
			c2.add_child(UI.lbl("Delegated marketing budget", 21, UI.CREAM, "semi"))
			c2.add_child(UI.para("When marketing is delegated, your manager spends this share of revenue on campaigns.", 18))
			var pl := UI.lbl("%s of revenue" % G.pct(float(c.get("mkt_pct", 0.0))), 20, UI.GOLD2, "semi")
			c2.add_child(pl)
			c2.add_child(UI.slider(0.0, 0.4, 0.01, float(c.get("mkt_pct", 0.0)), func(x):
				c["mkt_pct"] = x
				pl.text = "%s of revenue" % G.pct(x)))


func _camp(k: Dictionary) -> void:
	var cc := UI.card(body, "flat", 4)
	var h := UI.hbox(8)
	h.add_child(UI.lbl(MarketingEngine.kind_name(k), 21, UI.CREAM, "semi"))
	h.add_child(UI.expand(UI.spacer()))
	h.add_child(UI.pill("Active" if k["status"] == "active" else "Ended", UI.GREEN if k["status"] == "active" else UI.DIM))
	cc.add_child(h)
	var target = G.product(k["product"]).get("name", "") if k["product"] != "" else G.brand(k["brand"]).get("name", "brand")
	cc.add_child(UI.lbl("%s · %s · %s" % [target, ", ".join(k["markets"]), ("%d wks left" % int(k["weeks_left"])) if k["status"] == "active" else G.short_date(int(k["start"]))], 17, UI.MUTED))
	var roi := MarketingEngine.roi(k)
	cc.add_child(UI.lbl("Spent %s · reached ~%s people · attributed revenue %s · est. ROI %s" % [G.money(float(k["spent"])), G.group_int(int(k["reach"])), G.money(float(k["attr_rev"])), ("%+.0f%%" % (roi * 100.0))], 17, UI.GREEN if roi >= 0.0 else UI.AMBER, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
	if k["status"] == "active":
		var kid: String = k["id"]
		cc.add_child(UI.btn("Stop", func():
			for x in G.s["campaigns"]:
				if x["id"] == kid:
					MarketingEngine.stop(x)
			G.touch(), "ghost", 18, 48))
