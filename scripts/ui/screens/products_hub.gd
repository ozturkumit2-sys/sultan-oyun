extends Screen
## Portfolio: the collection presented as a boutique — every perfume shown as its own bottle.

var filter := "active"
var brand_f := ""


func page_title() -> String:
	return "Products"


func env() -> String:
	return "products"


func build() -> void:
	var all := G.company_products(G.pid(), ["active", "dev", "discontinued"])
	var u4 := 0
	var inv := 0
	for p in all:
		inv += int(p["inv"])
		for x in p["wk"].slice(maxi(0, p["wk"].size() - 4)):
			u4 += int(x[1])
	var active := G.company_products(G.pid()).size()
	Art.hero(body, "boutique", "Your collection", "%d perfume%s on sale · %s sold in 4 weeks" % [active, "" if active == 1 else "s", G.group_int(u4)], 320, Vector2(0.5, 0.55))
	var g := UI.hbox(10)
	g.add_child(UI.kpi("bottle", "Active", str(active), UI.ROSE))
	g.add_child(UI.kpi("chart", "Units · 4 wks", G.group_int(u4), UI.GOLD, func(): Router.go("reports")))
	g.add_child(UI.kpi("factory", "In stock", G.group_int(inv), UI.PLUM, func(): Router.go("production")))
	body.add_child(g)
	body.add_child(UI.btn("+ Launch a new perfume", func(): Router.go("launch", {}), "primary", 23, 80))
	var rv := 0
	for p in all:
		rv += p["reviews"].size()
	var aw := 0
	for p in all:
		aw += p.get("awards", []).size()
	Art.grid2(body, [
		Art.card("factory", "Production", "Batches & stock", func(): Router.go("production"), 0, Vector2(0.5, 0.6), 120),
		Art.card("stilllife", "ScentNotes", "%s reviews" % G.group_int(rv), func(): Router.go("reviews"), 0, Vector2(0.5, 0.8), 120),
	])
	Art.grid2(body, [
		Art.tex_card("res://assets/art/misc/trophy.svg", "Awards", "%d won" % aw if aw > 0 else "Golden Flacon", func(): Router.go("awards"), Color("#f8ead2"), 120),
		Art.card("boutique", "Retail partners", "Where you sell", func(): Router.go("distribution"), 0, Vector2(0.5, 0.6), 120),
	])
	UI.section(body, "The collection")
	body.add_child(UI.seg([["Active", "active"], ["In development", "dev"], ["Discontinued", "discontinued"], ["All", "all"]], filter, func(v):
		filter = v
		rebuild()))
	var bs := G.company_brands(G.pid())
	if bs.size() > 1:
		var bo: Array = [["All brands", ""]]
		for b in bs:
			bo.append([b["name"], b["id"]])
		body.add_child(UI.seg(bo, brand_f, func(v):
			brand_f = v
			rebuild()))
	var list: Array = []
	for p in all:
		if (filter == "all" or p["status"] == filter) and (brand_f == "" or p["brand"] == brand_f):
			list.append(p)
	list.sort_custom(func(a, b): return float(a["st"]["rev"]) > float(b["st"]["rev"]))
	if list.is_empty():
		var e := Art.card("stilllife", "No perfumes here yet", "Launch your first perfume from a formula", func(): Router.go("launch", {}), 0, Vector2(0.5, 0.6), 220)
		body.add_child(e)
		return
	var grid := UI.grid(2, 12)
	for p in list:
		var card := ProductCard.make(p, 0.0, 360.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
	body.add_child(grid)
