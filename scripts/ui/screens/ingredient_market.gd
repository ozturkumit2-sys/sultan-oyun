extends Screen
## Raw material market: price indices, shortages, spot buying, supply contracts.

var tab := "prices"


func page_title() -> String:
	return "Ingredient market"


func hero_spec() -> Dictionary:
	return {"scene": "garden", "title": "Ingredient market", "sub": "Harvests, prices and supply contracts", "focus": Vector2(0.55, 0.65), "h": 250.0}


func build() -> void:
	var c := G.pc()
	body.add_child(UI.seg([["Prices", "prices"], ["Supply contracts", "contracts"], ["Deliveries", "deliveries"]], tab, func(v):
		tab = v
		rebuild()))
	match tab:
		"prices":
			var used := {}
			for p in G.company_products(G.pid(), ["active", "dev"]):
				for it in G.formula_version(p["formula"], int(p["fv"])).get("items", []):
					used[it[0]] = true
			var shorts: Array = []
			for id in DB.ing_order:
				if int(G.s["ing_market"][id].get("short", 0)) > 0:
					shorts.append(FormulaEngine.short_name(DB.ing(id)))
			if not shorts.is_empty():
				var w := UI.card(body, "warn")
				w.add_child(UI.para("Shortages: " + ", ".join(shorts), 20, UI.TEXT))
			UI.section(body, "Used in your products" if not used.is_empty() else "All materials")
			var ids: Array = used.keys() if not used.is_empty() else DB.ing_order.filter(func(x): return G.ing_available(G.pid(), x))
			for id in ids:
				_row(c, id)
			if not used.is_empty():
				UI.section(body, "Other available materials")
				for id in DB.ing_order:
					if not used.has(id) and G.ing_available(G.pid(), id):
						_row(c, id)
		"contracts":
			body.add_child(UI.para("Lock a price for a fixed weekly delivery. Protects against shortages and spikes — but you pay the contract price even if the market falls.", 20))
			var ks = G.s["contracts"].filter(func(k): return k["company"] == G.pid())
			if ks.is_empty():
				UI.empty(body, "No supply contracts.")
			for k in ks:
				UI.row_card(body, FormulaEngine.short_name(DB.ing(k["ing"])), "%.1f kg/week at %s/kg · %d weeks left" % [float(k["kg"]), G.money(float(k["price"])), int(k["weeks_left"])], G.money(float(k["kg"]) * float(k["price"])) + "/wk", Callable(), Art.ing_icon(k["ing"], 64))
			body.add_child(UI.btn("+ New supply contract", _new_contract, "primary", 22))
		"deliveries":
			var ds = G.s["deliveries"].filter(func(d): return d["company"] == G.pid())
			if ds.is_empty():
				UI.empty(body, "Nothing in transit.")
			for d in ds:
				UI.row_card(body, FormulaEngine.short_name(DB.ing(d["ing"])), "%.2f kg · arrives in %d week(s)" % [float(d["kg"]), int(d["weeks"])], G.money(float(d["value"])), Callable(), Art.ing_icon(d["ing"], 64))


func _row(c: Dictionary, id: String) -> void:
	var rec := DB.ing(id)
	var m: Dictionary = G.s["ing_market"][id]
	var idx := float(m["idx"])
	var hist: Array = m.get("hist", [])
	var prev := float(hist[maxi(0, hist.size() - 2)]) if hist.size() >= 2 else idx
	var arrow := "↑" if idx > prev * 1.01 else ("↓" if idx < prev * 0.99 else "→")
	var sub := "index %.2f %s · stock %.2f kg" % [idx, arrow, FinanceEngine.raw_kg(c, id)]
	if int(m["short"]) > 0:
		sub += " · SHORTAGE"
	UI.row_card(body, FormulaEngine.short_name(rec), sub, G.money(G.ing_price(id)) + "/kg", func(): BuyDialog.open(id), Art.ing_icon(id, 64), UI.RED if idx > 1.15 else UI.GOLD2)


func _new_contract() -> void:
	var opts: Array = []
	for id in DB.ing_order:
		if G.ing_available(G.pid(), id) and DB.ing(id)["role"] == "aromatic":
			opts.append([FormulaEngine.short_name(DB.ing(id)), id, G.money(G.ing_price(id)) + "/kg"])
	Router.pick("Material", opts, func(id):
		Router.number("kg per week (26 weeks)", 2.0, 0.5, 100.0, 0.5, func(kg):
			var e := IngredientMarket.sign_contract(G.pc(), id, kg, 26)
			Router.toast(e if e != "" else "Contract signed.", "bad" if e != "" else "good")
			G.touch(), func(x): return "%.1f kg/wk ≈ %s/wk" % [x, G.money(x * G.ing_price(id) * 1.04)]))
