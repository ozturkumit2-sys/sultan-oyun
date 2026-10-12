class_name CountryPanel
extends RefCounted
## Market facts, company presence and actions for one country.

static func build(body: VBoxContainer, cid: String) -> void:
	var c := G.pc()
	var ct := DB.country(cid)
	var mk: Dictionary = G.s["markets"][cid]
	var h := UI.hbox(10)
	h.add_child(UI.title(ct["name"], 34))
	h.add_child(UI.expand(UI.spacer()))
	var lvl := CompanyEngine.office_level(G.pid(), cid)
	h.add_child(UI.pill(("Headquarters" if c["offices"][cid].get("hq", false) else DB.biz["office_levels"][lvl - 1]["name"]) if lvl > 0 else "No office", UI.GOLD if lvl > 0 else UI.DIM))
	body.add_child(h)
	var g := UI.grid(2, 8)
	g.add_child(UI.stat("Weekly buyers", G.group_int(int(MarketEngine.buyers(cid, G.week())))))
	g.add_child(UI.stat("Purchasing power", "%d%%" % int(float(ct["ppp"]) * 100)))
	g.add_child(UI.stat("VAT / sales tax", G.pct(float(ct["vat"]))))
	g.add_child(UI.stat("Competition", ["Low", "Moderate", "High", "Intense"][clampi(int((float(ct["competition"]) - 0.75) * 6.0), 0, 3)]))
	body.add_child(g)
	var tr := G.to_vec(mk["trend"])
	var tops: Array = []
	var idx: Array = []
	for i in tr.size():
		idx.append(i)
	idx.sort_custom(func(a, b): return tr[a] > tr[b])
	for i in idx.slice(0, 3):
		if tr[i] > 0.01:
			tops.append(str(DB.dims[i]).capitalize())
	var lows: Array = []
	for i in idx.slice(idx.size() - 2):
		if tr[i] < -0.01:
			lows.append(str(DB.dims[i]).capitalize())
	body.add_child(UI.para("Trending: %s%s" % [", ".join(tops) if not tops.is_empty() else "nothing in particular", (" · Cooling: " + ", ".join(lows)) if not lows.is_empty() else ""], 19, UI.GOLD2))
	UI.section(body, "Consumer segments")
	var segw: Dictionary = ct["seg"]
	var sc := UI.card(body, "flat", 4)
	for sg in DB.segments:
		var hh := UI.hbox(8)
		var l := UI.lbl(sg["name"], 17, UI.MUTED)
		l.custom_minimum_size.x = 270
		hh.add_child(l)
		hh.add_child(UI.bar(float(segw.get(sg["id"], 0.0)) / 0.18, UI.ROSE, 8))
		hh.add_child(UI.lbl(G.pct(float(segw.get(sg["id"], 0.0))), 16, UI.TEXT))
		sc.add_child(hh)
	body.add_child(UI.para("Every market contains every type of buyer; only the proportions differ.", 16, UI.DIM))
	# presence
	UI.section(body, "Your presence")
	var pc := UI.card(body)
	var units := 0
	var rev := 0.0
	for p in G.company_products(G.pid(), ["active", "discontinued"]):
		var m: Dictionary = p["mk"].get(cid, {})
		units += int(m.get("last", 0))
		rev += float(m.get("last", 0)) * CompanyEngine.net_price(p, cid)
	UI.kv(pc, "Units last week", G.group_int(units))
	UI.kv(pc, "Retail value last week", G.money(rev))
	for b in G.company_brands(G.pid()):
		UI.kv(pc, "Awareness of %s" % b["name"], G.pct(CompanyEngine.brand_aw(b, cid), 1))
	var ags := CompanyEngine.agreements(G.pid(), cid)
	UI.kv(pc, "Retail partners", ", ".join(ags.map(func(a): return "%s (%s)" % [a["partner"], DB.channels[a["ch"]]["name"]])) if not ags.is_empty() else "Online store only" + ("" if lvl > 0 else " (cross-border)"))
	var share: Dictionary = mk.get("share", {})
	UI.kv(pc, "Market share (simulated houses)", G.pct(float(share.get(G.pid(), 0.0)), 1))
	if lvl > 0 and not c["offices"][cid].get("hq", false):
		var oc := float(ct["office_week"]) * float(DB.biz["office_levels"][lvl - 1]["mult"])
		UI.kv(pc, "Office cost", G.money(oc) + "/week")
		var mgr := G.employee(c["offices"][cid].get("manager", ""))
		UI.kv(pc, "Country manager", mgr.get("name", "None"))
	var a := UI.grid(2, 8)
	if lvl == 0:
		a.add_child(UI.btn("Open office (%s)" % G.money(float(ct["office_setup"])), func(): Router.confirm("Open an office in %s?" % ct["name"], "Setup %s, then %s per week. Enables retail partners that require local presence, lowers shipping costs and raises reach." % [G.money(float(ct["office_setup"])), G.money(float(ct["office_week"]))], func():
			var e := CompanyEngine.open_office(c, cid)
			Router.toast(e if e != "" else "Office opened!", "bad" if e != "" else "good")
			G.touch()), "primary", 20, 68))
	else:
		if lvl < 3 and not c["offices"][cid].get("hq", false):
			var cost := float(ct["office_setup"]) * float(DB.biz["office_levels"][lvl]["upgrade"])
			a.add_child(UI.btn("Upgrade (%s)" % G.money(cost), func():
				var e2 := CompanyEngine.upgrade_office(c, cid)
				Router.toast(e2 if e2 != "" else "Office upgraded.", "bad" if e2 != "" else "good")
				G.touch(), "secondary", 20, 68))
		a.add_child(UI.btn("Hire country manager", func(): Router.go("recruit", {"role": "country_manager"}), "secondary", 20, 68))
	a.add_child(UI.btn("Distribution", func(): Router.go("distribution", {"country": cid}), "secondary", 20, 68))
	a.add_child(UI.btn("Regional advertising", func(): Router.go("campaign_new", {"markets": [cid]}), "secondary", 20, 68))
	if lvl > 0 and not c["offices"][cid].get("hq", false):
		a.add_child(UI.btn("Close office", func(): Router.confirm("Close the %s office?" % ct["name"], "Restructuring costs %s. Retail partners that need an office will end." % G.money(float(ct["office_week"]) * 8.0), func():
			CompanyEngine.close_office(c, cid)
			G.touch(), "Close", true), "danger", 20, 68))
	body.add_child(a)
	# competitors
	UI.section(body, "Who sells here")
	var rows: Array = []
	for k in share:
		rows.append([k, float(share[k])])
	rows.sort_custom(func(x, y): return x[1] > y[1])
	if rows.is_empty():
		UI.empty(body, "Market data appears after the first week.")
	for r in rows.slice(0, 8):
		var hh2 := UI.hbox(8)
		var l2 := UI.lbl(G.company(r[0]).get("name", "?"), 18, UI.GOLD2 if r[0] == G.pid() else UI.TEXT)
		l2.custom_minimum_size.x = 280
		hh2.add_child(l2)
		hh2.add_child(UI.bar(float(r[1]), UI.GOLD if r[0] == G.pid() else UI.BLUE, 8))
		hh2.add_child(UI.lbl(G.pct(float(r[1]), 1), 16, UI.TEXT))
		body.add_child(hh2)
