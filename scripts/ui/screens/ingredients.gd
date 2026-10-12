extends Screen
## Ingredient catalog.

var f := "all"


func page_title() -> String:
	return "Ingredient catalog"


func build() -> void:
	var c := G.pc()
	var n_av := 0
	for id in DB.ing_order:
		if G.ing_available(G.pid(), id):
			n_av += 1
	body.add_child(UI.para("%d of %d materials available. Qualify suppliers to unlock more — premium naturals need a larger headquarters." % [n_av, DB.ing_order.size()], 20))
	body.add_child(UI.seg(IngredientPicker.FILTERS + [["Locked", "locked"]], f, func(v):
		f = v
		rebuild(), 19))
	for id in DB.ing_order:
		var rec := DB.ing(id)
		var avail := G.ing_available(G.pid(), id)
		var ok := true
		match f:
			"top", "heart", "base":
				ok = rec["role"] == "aromatic" and rec["note"] == f
			"nat":
				ok = rec.get("nat", false) and rec["role"] == "aromatic"
			"syn":
				ok = not rec.get("nat", false) and rec["role"] == "aromatic" and rec["cat"] != "Accord"
			"accord":
				ok = rec["cat"] == "Accord"
			"aux":
				ok = rec["role"] != "aromatic"
			"locked":
				ok = not avail
		if not ok:
			continue
		var tops := FormulaEngine.top_dims(rec["vec"], 2)
		var dot := ColorRect.new()
		dot.color = UI.dim_color(tops[0]) if not tops.is_empty() else UI.BLUE
		dot.custom_minimum_size = Vector2(8, 56)
		var m: Dictionary = G.s["ing_market"].get(id, {})
		var sub := "%s · %s" % [rec["cat"], ", ".join(tops.map(func(d): return str(d).capitalize()))]
		if int(m.get("short", 0)) > 0:
			sub += " · ⚠ shortage"
		if c["qualifying"].has(id):
			sub += " · qualifying…"
		var iid: String = id
		UI.row_card(body, rec["name"], sub, (G.money(G.ing_price(id)) + "/kg") if avail else "Locked", func(): IngredientInfo.show(iid), dot, UI.GOLD2 if avail else UI.DIM)
