extends Screen
## ScentNotes — the fictional fragrance community: customer reviews and critics across the market.

var scope := "mine"


func page_title() -> String:
	return "ScentNotes"


func build() -> void:
	body.add_child(UI.seg([["My products", "mine"], ["Whole market", "all"], ["Critics", "critics"]], scope, func(v):
		scope = v
		rebuild()))
	if scope == "critics":
		var all: Array = []
		for p in G.s["products"].values():
			for cr in p.get("critics", []):
				all.append([cr, p])
		all.sort_custom(func(a, b): return int(a[0]["w"]) > int(b[0]["w"]))
		if all.is_empty():
			UI.empty(body, "Critics review new launches — PR and brand prestige make that more likely.")
		for x in all.slice(0, 25):
			var cr: Dictionary = x[0]
			var cc := UI.card(body, "flat", 4)
			cc.add_child(UI.lbl("%s on %s (%s)" % [cr["critic"], x[1]["name"], G.brand(x[1]["brand"]).get("name", "")], 19, UI.GOLD2, "semi"))
			cc.add_child(UI.lbl("%.1f/10 · %s · %s" % [float(cr["score"]), cr["outlet"], G.short_date(int(cr["w"]))], 17, UI.MUTED))
			cc.add_child(UI.para(str(cr["text"]), 18, UI.TEXT))
		return
	var prods: Array = []
	for p in G.s["products"].values():
		if int(p["rating"]["n"]) > 0 and (scope == "all" or G.is_player(p["company"])):
			prods.append(p)
	prods.sort_custom(func(a, b): return Awards.rating_avg(a) > Awards.rating_avg(b))
	UI.section(body, "Top rated")
	for p in prods.slice(0, 12):
		var pid: String = p["id"]
		UI.row_card(body, p["name"], "%s · %d reviews · %s" % [G.brand(p["brand"]).get("name", ""), int(p["rating"]["n"]), G.company(p["company"])["name"]], "★ %.2f" % Awards.rating_avg(p), func(): Router.go("product_detail", {"id": pid}))
	if scope == "mine":
		var revs: Array = []
		for p in prods:
			for rv in p["reviews"]:
				revs.append([rv, p])
		revs.sort_custom(func(a, b): return int(a[0]["w"]) > int(b[0]["w"]))
		UI.section(body, "Latest reviews")
		for x in revs.slice(0, 20):
			body.add_child(UI.lbl(x[1]["name"], 18, UI.GOLD2, "semi"))
			ReviewCard.add(body, x[0])
