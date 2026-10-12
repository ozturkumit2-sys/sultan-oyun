extends Screen
## Rival company profile.

func page_title() -> String:
	return G.company(params.get("id", "")).get("name", "Company")


func build() -> void:
	var c := G.company(params["id"])
	if c.is_empty():
		return
	var t := FinanceEngine.ttm(c)
	var hc := UI.card(body, "gold")
	hc.add_child(UI.title(c["name"], 32))
	hc.add_child(UI.lbl("%s · %s · founded long before 2027" % [DB.country(c["home"])["name"], DB.hq_tier(int(c["hq"]["tier"]))["name"]], 18, UI.MUTED))
	var g := UI.grid(2, 8)
	g.add_child(UI.stat("Revenue (52 wks)", G.money(float(t["revenue"]))))
	g.add_child(UI.stat("Net result", G.money(float(t["net"])), "", UI.GREEN if float(t["net"]) >= 0.0 else UI.RED))
	g.add_child(UI.stat("Valuation", G.money(FinanceEngine.valuation(c))))
	g.add_child(UI.stat("Cash", G.money(FinanceEngine.cash_of(c))))
	hc.add_child(g)
	hc.add_child(UI.lbl("Offices: " + ", ".join(c["offices"].keys().map(func(k): return DB.country(k)["name"])), 18, UI.TEXT, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
	hc.add_child(UI.lbl("Acquisition stance: " + Corporate.willingness(c), 18, UI.GOLD2))
	UI.section(body, "Brands")
	for b in G.company_brands(c["id"]):
		var bid: String = b["id"]
		var lg := LogoView.new().setup(int(b.get("logo", 0)), b["name"], Color(str(b["color"])))
		lg.custom_minimum_size = Vector2(60, 60)
		UI.row_card(body, b["name"], "%s · prestige %d" % [DB.positionings[b["posit"]]["name"], int(float(b["prestige"]) * 100)], "", func(): Router.go("brand_detail", {"id": bid}), lg)
	UI.section(body, "Products")
	var ps := G.company_products(c["id"])
	ps.sort_custom(func(a, b2): return Rivals.avg_units(a) > Rivals.avg_units(b2))
	for p in ps:
		ProductRow.add(body, p)
	UI.section(body, "Perfumers")
	for e in G.company_employees(c["id"], "perfumer"):
		EmpRow.add(body, e, func(): Router.go("transfer"), "Approach")
	body.add_child(UI.btn("Consider acquisition", func(): Router.go("acquisitions", {"target": c["id"]}), "secondary", 22))
