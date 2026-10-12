class_name IngredientInfo
extends RefCounted
## Material dossier: odor, technical properties, regulation, market, supplier qualification.

static func show(id: String) -> void:
	var rec := DB.ing(id)
	var c := G.pc()
	Router.modal(rec["name"], func(v: VBoxContainer):
		var h := UI.hbox(8)
		h.add_child(UI.pill(str(rec["cat"]), UI.GOLD))
		h.add_child(UI.pill("Natural" if rec.get("nat", false) else "Synthetic", UI.GREEN if rec.get("nat", false) else UI.BLUE))
		if rec["role"] == "aromatic":
			h.add_child(UI.pill(str(rec["note"]).capitalize() + " note", UI.ROSE))
		v.add_child(h)
		v.add_child(UI.para(str(rec.get("desc", "")), 22, UI.TEXT))
		if rec["role"] == "aromatic":
			UI.section(v, "Odor profile")
			UI.dims_bars(v, rec["vec"], 4)
			UI.section(v, "Technical behavior")
			UI.kv(v, "Odor strength", _lvl(float(rec["str"]) / 3.0))
			UI.kv(v, "Volatility", _lvl(float(rec["vol"])))
			UI.kv(v, "Persistence on skin", "%.0f h time constant" % float(rec["ten"]))
			UI.kv(v, "Diffusion", _lvl(float(rec["diff"])))
			UI.kv(v, "Fixative effect", _lvl(float(rec["fix"])))
			UI.kv(v, "Ethanol solubility", _lvl(float(rec["sol"])))
			UI.kv(v, "Oxidation stability", _lvl(float(rec["stab"])))
			if float(rec.get("disc", 0)) > 0.1:
				UI.kv(v, "Discoloration tendency", _lvl(float(rec["disc"])), UI.AMBER)
			if rec.get("cryst", false):
				UI.kv(v, "Physical form", "Crystalline — needs solvent", UI.AMBER)
			if float(rec.get("anos", 0)) > 0.05:
				UI.kv(v, "Specific anosmia", "~%d%% of people barely smell it" % int(float(rec["anos"]) * 100), UI.AMBER)
		UI.section(v, "Regulation & sourcing")
		var reg: Dictionary = rec.get("reg", {})
		UI.kv(v, "FSC limit (fictional)", ("%.2f%% of finished product" % float(reg["max"])) if reg.get("max") != null else "None")
		UI.kv(v, "Allergen labeling", "Yes" if reg.get("allergen", false) else "No")
		if str(rec.get("origin", "")) != "":
			UI.kv(v, "Origin", str(rec["origin"]))
		if int(rec.get("harvest", 0)) > 0:
			UI.kv(v, "Harvest", G.MONTHS[int(rec["harvest"]) - 1])
		var m: Dictionary = G.s["ing_market"].get(id, {})
		UI.kv(v, "Current price", G.money(G.ing_price(id)) + "/kg", UI.GOLD2)
		UI.kv(v, "Market index", "%.2f×" % float(m.get("idx", 1.0)), UI.RED if float(m.get("idx", 1.0)) > 1.15 else UI.TEXT)
		if int(m.get("short", 0)) > 0:
			UI.kv(v, "Supply", "Shortage (~%d weeks)" % int(m["short"]), UI.RED)
		UI.kv(v, "In stock", "%.2f kg" % FinanceEngine.raw_kg(c, id))
		var hist: Array = m.get("hist", [])
		if hist.size() >= 3:
			var ch := LineChart.new()
			ch.custom_minimum_size = Vector2(0, 160)
			ch.min_zero = false
			ch.fill = false
			var vals: Array = []
			for x in hist:
				vals.append(float(x) * float(rec["cost"]))
			ch.set_data([{"v": vals, "c": UI.GOLD}], [], "money")
			v.add_child(ch)
		if not G.ing_available(G.pid(), id):
			var req := IngredientMarket.qualify_req(c, id)
			var q: Dictionary = c.get("qualifying", {})
			if q.has(id):
				v.add_child(UI.pill("Supplier qualification in progress (%d weeks)" % int(q[id]), UI.BLUE, 19))
			elif req != "":
				v.add_child(UI.para(req, 20, UI.AMBER))
			else:
				v.add_child(UI.btn("Qualify a supplier (%s)" % G.money(IngredientMarket.qualify_cost(id)), func():
					var e := IngredientMarket.start_qualify(c, id)
					Router.close_modal()
					Router.toast(e if e != "" else "Qualification started.", "bad" if e != "" else "good")
					G.touch(), "primary", 22))
		else:
			v.add_child(UI.btn("Buy material…", func():
				Router.close_modal()
				BuyDialog.open(id), "secondary", 22)), [])


static func _lvl(x: float) -> String:
	if x < 0.2:
		return "Very low"
	if x < 0.4:
		return "Low"
	if x < 0.6:
		return "Medium"
	if x < 0.8:
		return "High"
	return "Very high"
