extends Screen
## Plan a marketing campaign, influencer collaboration or celebrity ambassadorship.

var st := {}


func page_title() -> String:
	return "New campaign"


func setup(p: Dictionary) -> void:
	params = p
	var c := G.pc()
	var prods := G.company_products(G.pid(), ["active", "dev"])
	st = {"kind": "social", "product": p.get("product", prods[0]["id"] if not prods.is_empty() else ""), "markets": p.get("markets", []).duplicate(),
		"weekly": 2000.0, "weeks": 4, "media": p.get("media", ""), "contract": 26}
	if st["media"] != "":
		st["kind"] = G.s["media"][st["media"]]["kind"]
		if st["kind"] == "celebrity":
			st["kind"] = "celebrity"
	if st["markets"].is_empty():
		var pr := G.product(st["product"])
		st["markets"] = pr.get("markets", [c["home"]]).duplicate()
	_make()
	build()


func build() -> void:
	var c := G.pc()
	var prods := G.company_products(G.pid(), ["active", "dev"])
	UI.section(body, "Type")
	var ko: Array = []
	for k in DB.biz["campaigns"]:
		ko.append([k["name"], k["id"]])
	ko.append(["Influencer", "influencer"])
	ko.append(["Celebrity ambassador", "celebrity"])
	body.add_child(UI.seg(ko, st["kind"], func(v):
		st["kind"] = v
		st["media"] = "" if not (v == "influencer" or v == "celebrity") else st["media"]
		var t: Dictionary = DB.campaigns.get(v, {})
		if not t.is_empty():
			st["weekly"] = maxf(float(st["weekly"]), float(t["min"]))
			if t.get("oneoff", false):
				st["weeks"] = 1
		rebuild(), 18))
	var t: Dictionary = DB.campaigns.get(st["kind"], {})
	if not t.is_empty():
		body.add_child(UI.para(str(t["desc"]), 18))
	UI.section(body, "Promote")
	var po: Array = [["Brand only", ""]]
	for p in prods:
		po.append([p["name"], p["id"]])
	body.add_child(UI.seg(po, st["product"], func(v):
		st["product"] = v
		rebuild(), 18))
	var b: Dictionary = G.brand(G.product(st["product"]).get("brand", "")) if st["product"] != "" else G.company_brands(G.pid())[0]
	UI.section(body, "Markets")
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for ct in DB.countries:
		var id: String = ct["id"]
		flow.add_child(UI.chip(ct["name"], st["markets"].has(id), func():
			if st["markets"].has(id):
				st["markets"].erase(id)
			else:
				st["markets"].append(id)
			rebuild()))
	body.add_child(flow)
	if st["kind"] == "influencer" or st["kind"] == "celebrity":
		_media(b)
		return
	UI.section(body, "Budget")
	var wl := UI.lbl("", 22, UI.GOLD2, "semi")
	body.add_child(wl)
	var est := UI.vbox(4)
	var upd := func():
		wl.text = "%s per week × %d week(s) = %s" % [G.money(float(st["weekly"])), int(st["weeks"]), G.money(float(st["weekly"]) * float(st["weeks"]))]
		for ch in est.get_children():
			ch.queue_free()
		if st["markets"].is_empty():
			return
		var tot_b := 0.0
		for cid in st["markets"]:
			tot_b += MarketEngine.buyers(cid, G.week())
		var p := G.product(st["product"])
		for cid in st["markets"]:
			var B = MarketEngine.buyers(cid, G.week())
			var S = float(st["weekly"]) * B / maxf(1.0, tot_b)
			var X = S * float(t["eff"]) * MarketingEngine.power(G.pid()) / (float(DB.country(cid)["opcost"]) * B * MarketEngine.M("aw_cost"))
			var fit := MarketingEngine.attr_fit(p, cid, t.get("attr", "none")) if not p.is_empty() else 1.0
			var aw := float(p["mk"].get(cid, {}).get("aw", 0.0)) if not p.is_empty() else CompanyEngine.brand_aw(b, cid)
			est.add_child(UI.lbl("%s: ≈ +%s awareness in week 1 (now %s) · audience fit %d%%" % [DB.country(cid)["name"], G.pct((1.0 - aw) * (1.0 - exp(-X)) * fit, 2), G.pct(aw, 1), int(fit * 100)], 17, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
		est.add_child(UI.para("Returns diminish as a market saturates with your ads. Awareness creates consideration, not guaranteed sales.", 16, UI.DIM))
	body.add_child(UI.slider(float(t["min"]), maxf(float(t["min"]) * 20.0, 100000.0), 100.0, float(st["weekly"]), func(x):
		st["weekly"] = x
		upd.call()))
	if not t.get("oneoff", false):
		body.add_child(UI.seg([["2 wks", 2], ["4 wks", 4], ["8 wks", 8], ["12 wks", 12]], st["weeks"], func(v):
			st["weeks"] = v
			upd.call()))
	body.add_child(est)
	upd.call()
	body.add_child(UI.btn("Start campaign", func():
		var e := MarketingEngine.start(G.pid(), st["kind"], st["product"], b.get("id", ""), st["markets"], float(st["weekly"]), int(st["weeks"]))
		Router.toast(e if e != "" else "Campaign started.", "bad" if e != "" else "good")
		G.touch()
		if e == "":
			Router.back(), "primary", 23, 80))


func _media(b: Dictionary) -> void:
	var kind: String = st["kind"]
	var p := G.product(st["product"])
	if st["media"] == "" or not G.s["media"].has(st["media"]) or G.s["media"][st["media"]]["kind"] != kind:
		UI.section(body, "Choose a personality")
		var ms: Array = G.s["media"].values().filter(func(m): return m["kind"] == kind)
		ms.sort_custom(func(a, b2): return _fit(p, a) > _fit(p, b2))
		for m in ms:
			var mid: String = m["id"]
			MediaRow.add(body, m, func():
				st["media"] = mid
				rebuild())
		return
	var m2: Dictionary = G.s["media"][st["media"]]
	UI.section(body, "Selected")
	MediaRow.add(body, m2, func():
		st["media"] = ""
		rebuild())
	var mc := UI.card(body)
	UI.kv(mc, "Audience fit with this product", "%d%%" % int(_fit(p, m2) * 100))
	UI.kv(mc, "Engagement", G.pct(float(m2["engagement"]), 1))
	UI.kv(mc, "Reputation", "%d/100" % int(float(m2["reputation"]) * 100))
	var overlap: Array = []
	for cid in st["markets"]:
		if m2["markets"].has(cid):
			overlap.append(cid)
	UI.kv(mc, "Reach in your selected markets", ", ".join(overlap) if not overlap.is_empty() else "None — choose their markets", UI.RED if overlap.is_empty() else UI.TEXT)
	if kind == "celebrity":
		body.add_child(UI.seg([["26 weeks", 26], ["52 weeks", 52], ["104 weeks", 104]], st["contract"], func(v):
			st["contract"] = v
			rebuild()))
		body.add_child(UI.para("Weekly fee %s (first 4 weeks paid upfront). Ending early costs 4 weeks of fees." % G.money(float(m2["fee"])), 18))
	else:
		body.add_child(UI.para("Package fee %s for a 4-week collaboration." % G.money(float(m2["fee"])), 18))
	body.add_child(UI.btn("Sign %s" % m2["name"], func():
		var e := MarketingEngine.start(G.pid(), kind, st["product"], b.get("id", ""), overlap, float(m2["fee"]), int(st["contract"]) if kind == "celebrity" else 4, st["media"])
		Router.toast(e if e != "" else "Signed %s!" % m2["name"], "bad" if e != "" else "good")
		G.touch()
		if e == "":
			Router.back(), "primary", 23, 80))


func _fit(p: Dictionary, m: Dictionary) -> float:
	if p.is_empty():
		return 1.0
	var cid: String = p["markets"][0] if not p["markets"].is_empty() else G.pc()["home"]
	return MarketingEngine.media_fit(p, cid, m)
