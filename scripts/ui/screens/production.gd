extends Screen
## Production & inventory: orders pipeline, finished goods, raw materials, factory.

var tab := "orders"


func page_title() -> String:
	return "Production & inventory"


func hero_spec() -> Dictionary:
	return {"scene": "factory", "title": "Production & inventory", "sub": "Batches, quality control and stock", "focus": Vector2(0.5, 0.6), "h": 250.0}


func build() -> void:
	var c := G.pc()
	body.add_child(UI.seg([["Orders", "orders"], ["Finished goods", "fg"], ["Raw materials", "raw"], ["Factory", "factory"]], tab, func(v):
		tab = v
		rebuild()))
	match tab:
		"orders":
			var os = G.s["orders"].filter(func(o): return o["company"] == G.pid())
			if os.is_empty():
				UI.empty(body, "No production in progress. Order a batch from a product page.")
			for o in os:
				ProductionRow.add(body, o)
			var ds = G.s["deliveries"].filter(func(d): return d["company"] == G.pid())
			if not ds.is_empty():
				UI.section(body, "Materials in transit")
				var dc := UI.card(body, "flat", 4)
				for d in ds:
					UI.kv(dc, "%s · %.1f kg" % [FormulaEngine.short_name(DB.ing(d["ing"])), float(d["kg"])], "%d wk · %s" % [int(d["weeks"]), G.money(float(d["value"]))])
		"fg":
			var tot := 0.0
			for p in G.company_products(G.pid(), ["active", "dev", "discontinued"]):
				if int(p["inv"]) <= 0 and p["status"] != "active":
					continue
				var val := float(p["inv"]) * float(p["unit_cost"])
				tot += val
				var avg := Rivals.avg_units(p, 4) if not p["wk"].is_empty() else 0.0
				var pid: String = p["id"]
				UI.row_card(body, p["name"], "%s units · unit cost %s · %s" % [G.group_int(int(p["inv"])), G.money(float(p["unit_cost"]), 2), ("%.1f weeks cover" % (float(p["inv"]) / avg)) if avg > 0.0 else "no sales yet"],
					G.money(val), func(): Router.go("product_detail", {"id": pid}), _mini(p), UI.RED if int(p["inv"]) <= 0 else UI.GOLD2)
			UI.kv(body, "Finished goods inventory value", G.money(tot), UI.GOLD2)
		"raw":
			var raw: Dictionary = c["raw"]
			if raw.is_empty():
				UI.empty(body, "No raw materials in stock. Production orders can buy missing materials automatically.")
			var tot2 := 0.0
			var ids: Array = raw.keys()
			ids.sort()
			for id in ids:
				var a: Array = raw[id]
				tot2 += float(a[0]) * float(a[1])
				var iid: String = id
				UI.row_card(body, FormulaEngine.short_name(DB.ing(id)), "%.2f kg · avg cost %s/kg · market %s/kg" % [float(a[0]), G.money(float(a[1])), G.money(G.ing_price(id))], G.money(float(a[0]) * float(a[1])), func(): IngredientInfo.show(iid), Art.ing_icon(iid, 64))
			UI.kv(body, "Raw material inventory value", G.money(tot2), UI.GOLD2)
			body.add_child(UI.btn("Ingredient market", func(): Router.go("ingredient_market", {}), "secondary", 22))
		"factory":
			var f: Dictionary = c.get("factory", {})
			var fd: Dictionary = DB.biz["factory"]
			var fc := UI.card(body)
			fc.add_child(UI.icon("factory", 56))
			if f.is_empty():
				fc.add_child(UI.title("Build your own factory", 30))
				fc.add_child(UI.para("Owned production costs %s to build (%d weeks) and %s per week to run, but filling costs only %s per unit and capacity is %s units/week. Idle capacity still costs money — utilization matters." % [G.money(float(fd["cost"])), int(fd["weeks"]), G.money(float(fd["fixed"])), G.money(float(fd["fill"]), 2), G.group_int(int(fd["cap"]))], 20, UI.TEXT))
				fc.add_child(UI.btn("Build factory (%s)" % G.money(float(fd["cost"])), func(): Router.confirm("Build a factory?", "Invest %s. Construction takes %d weeks." % [G.money(float(fd["cost"])), int(fd["weeks"])], func():
					var e := ProductionEngine.build_factory(c)
					Router.toast(e if e != "" else "Construction started.", "bad" if e != "" else "good")
					G.touch()), "primary", 22))
			elif not f.get("built", false):
				fc.add_child(UI.title("Factory under construction", 30))
				fc.add_child(UI.lbl("%d weeks remaining" % int(f["weeks"]), 22, UI.GOLD2))
			else:
				fc.add_child(UI.title("Your factory", 30))
				UI.kv(fc, "Capacity", "%s units/week" % G.group_int(int(f["cap"])))
				UI.kv(fc, "Fixed running cost", "%s/week" % G.money(float(f["fixed"])))
				var u: Array = f.get("util", [])
				var avg_u := 0.0
				for x in u:
					avg_u += float(x)
				avg_u /= maxf(1.0, float(u.size()))
				UI.kv(fc, "Utilization (12 wks)", G.pct(avg_u), UI.RED if avg_u < 0.4 else UI.GREEN)
				fc.add_child(UI.bar(avg_u, UI.GREEN if avg_u >= 0.4 else UI.RED, 12))
				if avg_u < 0.4:
					fc.add_child(UI.para("Low utilization: fixed costs are spread over few units. Move production in-house or reduce capacity plans.", 19, UI.AMBER))
				if int(f["cap"]) < int(fd["upgrade_cap"]):
					fc.add_child(UI.btn("Expand to %s units/week (%s)" % [G.group_int(int(fd["upgrade_cap"])), G.money(float(fd["upgrade_cost"]))], func():
						var e2 := ProductionEngine.upgrade_factory(c)
						Router.toast(e2 if e2 != "" else "Factory expanded.", "bad" if e2 != "" else "good")
						G.touch(), "secondary", 21))
			UI.section(body, "Contract manufacturers")
			for m in DB.biz["manufacturers"]:
				var mc := UI.card(body, "flat", 4)
				mc.add_child(UI.lbl(m["name"], 21, UI.CREAM, "semi"))
				mc.add_child(UI.lbl("Fill %s/unit · min %s · %s/wk · lead %d wk · reliability %d%%" % [G.money(float(m["fill"]), 2), G.group_int(int(m["moq"])), G.group_int(int(m["cap"])), int(m["lead"]), int(float(m["rel"]) * 100)], 17, UI.MUTED))


func _mini(p: Dictionary) -> Control:
	var bv := BottleView.new().setup(p["bottle"], "", "", MarketEngine.product_ev(p).get("profile", PackedFloat32Array()))
	bv.show_label = false
	bv.vivid = true
	bv.custom_minimum_size = Vector2(56, 84)
	return bv
