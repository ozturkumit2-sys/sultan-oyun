extends Screen
## Ingredient catalog.

var f := "all"


func page_title() -> String:
	return "Ingredient catalog"


func env() -> String:
	return "lab"


func build() -> void:
	var c := G.pc()
	var n_av := 0
	for id in DB.ing_order:
		if G.ing_available(G.pid(), id):
			n_av += 1
	var bn := Art.banner("garden", 250, "", 26)
	bn.caption = "The perfumer's palette"
	bn.caption_sub = "Naturals from the fields, molecules from the lab"
	bn.fade = 0.8
	body.add_child(bn)
	body.add_child(UI.para("%d of %d materials available. Qualify suppliers to unlock more — premium naturals need a larger headquarters." % [n_av, DB.ing_order.size()], 20))
	body.add_child(UI.seg(IngredientPicker.FILTERS + [["Locked", "locked"]], f, func(v):
		f = v
		rebuild(), 19))
	var grid := UI.grid(3, 10)
	body.add_child(grid)
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
		var iid: String = id
		var m: Dictionary = G.s["ing_market"].get(id, {})
		var tag := ""
		if int(m.get("short", 0)) > 0:
			tag = "Shortage"
		elif c["qualifying"].has(id):
			tag = "Qualifying…"
		grid.add_child(IngredientCard.make(id, func(): IngredientInfo.show(iid), 0.0, tag))
