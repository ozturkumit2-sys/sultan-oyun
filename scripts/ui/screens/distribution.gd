extends Screen
## Retail distribution agreements by country.

var cid := ""


func page_title() -> String:
	return "Distribution"


func build() -> void:
	var c := G.pc()
	if cid == "":
		cid = params.get("country", c["home"])
	var co: Array = []
	for ct in DB.countries:
		co.append([ct["name"], ct["id"]])
	body.add_child(UI.seg(co, cid, func(v):
		cid = v
		rebuild(), 18))
	var ct := DB.country(cid)
	body.add_child(UI.para("Own online store: always available%s. Retailers buy at wholesale (they keep a margin) but reach far more shoppers. %s" % ["" if CompanyEngine.has_office(G.pid(), cid) else " with cross-border shipping", "" if CompanyEngine.has_office(G.pid(), cid) else "Most retail partners require a local office."], 19))
	UI.section(body, "Active agreements in %s" % ct["name"])
	var ags := CompanyEngine.agreements(G.pid(), cid)
	if ags.is_empty():
		UI.empty(body, "None yet.")
	for a in ags:
		var chd: Dictionary = DB.channels[a["ch"]]
		var cc := UI.card(body, "flat", 4)
		var h := UI.hbox(8)
		h.add_child(UI.lbl("%s · %s" % [a["partner"], chd["name"]], 21, UI.CREAM, "semi"))
		h.add_child(UI.expand(UI.spacer()))
		h.add_child(UI.lbl("margin %s" % G.pct(float(a["margin"])), 18, UI.GOLD2))
		cc.add_child(h)
		cc.add_child(UI.lbl("Reach quality %d · %s units · %s revenue · renews %s" % [int(float(a["q"]) * 100), G.group_int(int(a.get("units", 0))), G.money(float(a.get("rev", 0.0))), G.short_date(int(a["until"]))], 17, UI.MUTED))
		var aid: String = a["id"]
		cc.add_child(UI.btn("End agreement", func(): Router.confirm("End agreement?", "Stop selling through %s." % a["partner"], func():
			for x in G.s["channels"]:
				if x["id"] == aid:
					CompanyEngine.end_channel(x)
			G.touch(), "End", true), "ghost", 18, 50))
	UI.section(body, "Available channels")
	for ch in DB.channels:
		if ch == "dtc":
			continue
		var has := false
		for a in ags:
			if a["ch"] == ch:
				has = true
		if has:
			continue
		var chd2: Dictionary = DB.channels[ch]
		var off := CompanyEngine.channel_offer(G.pid(), cid, ch)
		var reasons: Array = []
		for b in G.company_brands(G.pid()):
			var rq := CompanyEngine.channel_requirements(G.pid(), cid, ch, b)
			if rq == "":
				reasons = []
				break
			reasons.append("%s: %s" % [b["name"], rq])
		var cc2 := UI.card(body)
		cc2.add_child(UI.lbl("%s — %s" % [chd2["name"], off["partner"]], 21, UI.CREAM, "semi"))
		cc2.add_child(UI.lbl("Retailer margin %s · listing fee %s · reach quality %d" % [G.pct(float(off["margin"])), G.money(float(off["fee"])), int(float(off["q"]) * 100)], 17, UI.MUTED))
		var pos: Array = chd2.get("posit", [])
		if not pos.is_empty():
			cc2.add_child(UI.lbl("Carries: " + ", ".join(pos.map(func(x): return DB.positionings[x]["name"])), 16, UI.DIM))
		if not reasons.is_empty():
			for rr in reasons:
				cc2.add_child(UI.para(str(rr), 17, UI.AMBER))
		else:
			var chid: String = ch
			cc2.add_child(UI.btn("Sign (%s)" % G.money(float(off["fee"])), func():
				var e := CompanyEngine.sign_channel(G.pc(), cid, chid, off)
				Router.toast(e if e != "" else "Agreement signed.", "bad" if e != "" else "good")
				G.touch(), "primary", 20, 62))
