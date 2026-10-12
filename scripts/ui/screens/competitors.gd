extends Screen
## Company rankings by measurable performance.

var sort := "rev"


func page_title() -> String:
	return "Competitors"


func hero_spec() -> Dictionary:
	return {"scene": "skyline", "title": "The fragrance industry", "sub": "Rival houses and the rankings", "focus": Vector2(0.5, 0.5), "h": 250.0}


func build() -> void:
	body.add_child(UI.seg([["Revenue", "rev"], ["Profit", "net"], ["Units", "units"], ["Valuation", "val"], ["Prestige", "prestige"]], sort, func(v):
		sort = v
		rebuild(), 19))
	var rk := Rivals.ranking()
	rk.sort_custom(func(a, b): return float(a[sort]) > float(b[sort]))
	for i in rk.size():
		var x: Dictionary = rk[i]
		var cid: String = x["id"]
		var val := ""
		match sort:
			"rev":
				val = G.money(float(x["rev"]))
			"net":
				val = G.money(float(x["net"]))
			"units":
				val = G.group_int(int(x["units"]))
			"val":
				val = G.money(float(x["val"]))
			"prestige":
				val = str(int(float(x["prestige"]) * 100))
		var sub := "%d products · share %s · %s" % [int(x["products"]), G.pct(float(x["share"]), 1), DB.country(G.company(cid)["home"])["name"]]
		var rank := UI.lbl("#%d" % (i + 1), 26, UI.GOLD if x["player"] else UI.MUTED, "title")
		rank.custom_minimum_size.x = 56
		UI.row_card(body, x["name"] + (" (you)" if x["player"] else ""), sub, val, func(): Router.go("competitor", {"id": cid}) if not x["player"] else Router.go_tab("finance"), rank)
	var gone = G.s["companies"].values().filter(func(c): return not c.get("active", true))
	if not gone.is_empty():
		UI.section(body, "Acquired companies")
		for c in gone:
			UI.row_card(body, c["name"], "Acquired by %s" % G.company(c.get("acquired_by", "")).get("name", "?"), "", Callable())
	var deals: Array = G.s["deals"]
	if not deals.is_empty():
		UI.section(body, "Deal history")
		for i in range(deals.size() - 1, maxi(-1, deals.size() - 10), -1):
			body.add_child(UI.para("%s — %s" % [G.short_date(int(deals[i]["w"])), deals[i]["text"]], 18, UI.TEXT))
