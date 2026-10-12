extends Screen
## Discovery set builder: minis of several of your fragrances in one box.

var sel: Array = []
var price := 39.0


func page_title() -> String:
	return "Discovery set"


func hero_spec() -> Dictionary:
	return {"scene": "stilllife", "title": "Discovery set", "sub": "Miniatures that turn testers into customers", "focus": Vector2(0.5, 0.7), "h": 250.0}


func build() -> void:
	var c := G.pc()
	var b := G.brand(params.get("brand", G.company_brands(G.pid())[0]["id"]))
	body.add_child(UI.para("Choose 3–6 fragrances. Explorers love discovery sets, and every buyer gets to try each fragrance — some convert into full-size customers.", 19))
	var prods := G.company_products(G.pid()).filter(func(p): return p["brand"] == b["id"] and p.get("kind", "full") == "full")
	if prods.size() < 3:
		UI.empty(body, "%s needs at least 3 active full-size products." % b["name"])
		return
	for p in prods:
		var fid: String = p["formula"]
		body.add_child(UI.chip(("✓ " if sel.has(fid) else "") + p["name"], sel.has(fid), func():
			if sel.has(fid):
				sel.erase(fid)
			elif sel.size() < 6:
				sel.append(fid)
			rebuild()))
	var pl := UI.lbl("Price %s for %d × 5 ml" % [G.money(price, 0), sel.size()], 21, UI.GOLD2, "semi")
	body.add_child(pl)
	body.add_child(UI.slider(10, 200, 1, price, func(x):
		price = x
		pl.text = "Price %s for %d × 5 ml" % [G.money(x, 0), sel.size()]))
	var ok := sel.size() >= 3
	var bt := UI.btn("Create & produce 500 sets", func():
		var p := CompanyEngine.make_product(G.pid(), {"brand": b["id"], "name": "%s Discovery Set" % b["name"], "formula": sel[0], "fv": G.formula(sel[0])["versions"].size() - 1,
			"fmt": "edp", "conc": 18.0, "volume": 5.0, "pack": "premium", "audience": "any", "price": price, "markets": prods[0]["markets"].duplicate(),
			"bottle": prods[0]["bottle"].duplicate(), "kind": "discovery", "set": sel.duplicate(), "launch_budget": 0.0})
		var e := ProductionEngine.place_order(G.pid(), p["id"], 500, "quickfill", {"chill": true})
		Router.toast(e if e != "" else "Discovery set in production.", "bad" if e != "" else "good")
		G.touch()
		Router.replace("product_detail", {"id": p["id"]}), "primary", 22)
	bt.disabled = not ok
	body.add_child(bt)
