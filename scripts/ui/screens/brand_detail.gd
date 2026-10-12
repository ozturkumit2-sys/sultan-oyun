extends Screen
## Brand management: identity, positioning, budget, markets, products, sale/discontinuation.

func page_title() -> String:
	return G.brand(params.get("id", "")).get("name", "Brand")


func build() -> void:
	var b := G.brand(params["id"])
	if b.is_empty():
		return
	var mine: bool = b["company"] == G.pid()
	var hc := UI.card(body, "gold")
	var h := UI.hbox(14)
	var lg := LogoView.new().setup(int(b.get("logo", 0)), b["name"], Color(str(b["color"])))
	lg.custom_minimum_size = Vector2(110, 110)
	h.add_child(lg)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.title(b["name"], 32))
	v.add_child(UI.lbl(DB.positionings[b["posit"]]["name"] + (" · independent brand" if b.get("independent", false) else ""), 19, UI.GOLD2, "semi"))
	var pr := UI.hbox(8)
	pr.add_child(UI.lbl("Prestige", 18, UI.MUTED))
	pr.add_child(UI.bar(float(b["prestige"]), UI.GOLD, 10))
	pr.add_child(UI.lbl(str(int(float(b["prestige"]) * 100)), 18, UI.TEXT))
	v.add_child(pr)
	v.add_child(UI.lbl("Estimated brand value %s" % G.money(Corporate.brand_value(b)), 18, UI.MUTED))
	h.add_child(v)
	hc.add_child(h)
	UI.section(body, "Awareness by market")
	var ac := UI.card(body, "flat", 4)
	for ct in DB.countries:
		var aw := CompanyEngine.brand_aw(b, ct["id"])
		if aw < 0.0005 and not b["markets"].has(ct["id"]):
			continue
		var hh := UI.hbox(8)
		var l := UI.lbl(ct["name"], 18, UI.MUTED)
		l.custom_minimum_size.x = 250
		hh.add_child(l)
		hh.add_child(UI.bar(aw / 0.5, UI.GOLD, 8))
		hh.add_child(UI.lbl(G.pct(aw, 1), 17, UI.TEXT))
		ac.add_child(hh)
	if mine:
		UI.section(body, "Always-on brand marketing")
		var bl := UI.lbl("%s per week" % G.money(float(b.get("budget", 0.0))), 21, UI.GOLD2, "semi")
		body.add_child(bl)
		body.add_child(UI.slider(0, 50000, 500, float(b.get("budget", 0.0)), func(x):
			b["budget"] = x
			bl.text = "%s per week" % G.money(x)))
		body.add_child(UI.para("Spent every week across the brand's markets to build brand awareness (which helps every product of the brand).", 18))
		UI.section(body, "Brand markets")
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		for ct2 in DB.countries:
			var id: String = ct2["id"]
			flow.add_child(UI.chip(ct2["name"], b["markets"].has(id), func():
				if b["markets"].has(id):
					if b["markets"].size() > 1:
						b["markets"].erase(id)
				else:
					b["markets"].append(id)
				rebuild()))
		body.add_child(flow)
	UI.section(body, "Products")
	var ps := Corporate.brand_products(b["id"])
	if ps.is_empty():
		UI.empty(body, "No products yet.")
	for p in ps:
		ProductRow.add(body, p)
	if mine:
		UI.section(body, "Portfolio decisions")
		var a := UI.grid(2, 8)
		a.add_child(UI.btn("Rename", func(): Router.text_input("Brand name", b["name"], func(s):
			if s.length() >= 2:
				b["name"] = s
				G.touch()), "secondary", 20, 64))
		a.add_child(UI.btn("Reposition", func():
			var opts: Array = []
			for p in DB.biz["positionings"]:
				opts.append([p["name"], p["id"]])
			Router.pick("New positioning", opts, func(x):
				b["posit"] = x
				b["prestige"] = minf(float(b["prestige"]), float(DB.positionings[x]["prestige_cap"]))
				G.cache.clear()
				G.touch()), "secondary", 20, 64))
		a.add_child(UI.btn("Sell brand", func():
			Router.confirm("Sell %s?" % b["name"], "A rival would pay about %s. Its products, formulas and stock go with it." % G.money(Corporate.brand_value(b)), func():
				var r := Corporate.sell_brand(G.pc(), b)
				Router.toast(r if r != "" else "Brand sold.", "bad" if r != "" else "good")
				G.touch()
				if r == "":
					Router.back(), "Sell", true), "danger", 20, 64))
		a.add_child(UI.btn("Discontinue", func():
			Router.confirm("Discontinue %s?" % b["name"], "All its products stop selling; remaining stock is cleared at a loss.", func():
				var r2 := Corporate.discontinue_brand(G.pc(), b)
				Router.toast(r2 if r2 != "" else "Brand discontinued.", "bad" if r2 != "" else "good")
				G.touch(), "Discontinue", true), "danger", 20, 64))
		body.add_child(a)
