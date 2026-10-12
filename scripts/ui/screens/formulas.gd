extends Screen
## Formula library with versions and accords.

var show := "formulas"


func page_title() -> String:
	return "Formula library"


func hero_spec() -> Dictionary:
	return {"scene": "stilllife", "title": "Formula library", "sub": "Your formulas, versions and accords", "focus": Vector2(0.5, 0.65), "h": 250.0}


func build() -> void:
	body.add_child(UI.seg([["Formulas", "formulas"], ["Accords", "accords"], ["Archived", "archived"]], show, func(v):
		show = v
		rebuild()))
	body.add_child(UI.btn("+ New formula" if show != "accords" else "+ New accord", func(): Router.go("formula_editor", {"accord": show == "accords"}), "primary", 22, 72))
	var forms: Array = []
	for f in G.s["formulas"].values():
		if f["company"] != G.pid():
			continue
		if show == "accords" and f.get("accord", false):
			forms.append(f)
		elif show == "formulas" and not f.get("accord", false) and not f.get("archived", false):
			forms.append(f)
		elif show == "archived" and f.get("archived", false):
			forms.append(f)
	forms.sort_custom(func(a, b): return int(a["created"]) > int(b["created"]))
	if forms.is_empty():
		UI.empty(body, "Nothing here yet." if show != "accords" else "Accords are reusable building blocks. Save part of a formula as an accord and insert it into future formulas.")
	for f in forms:
		var fv: Dictionary = f["versions"][f["versions"].size() - 1]
		var ev := FormulaEngine.evaluate(fv["items"], f.get("fmt", "edp"), float(f.get("conc", 18.0)))
		var author = "You" if f["author"] == "ceo" or f["author"] == "" else G.employee(f["author"]).get("name", "Former perfumer")
		var used := 0
		for p in G.company_products(G.pid(), ["dev", "active", "discontinued"]):
			if p["formula"] == f["id"]:
				used += 1
		var fid: String = f["id"]
		var sub := "%s · v%d · %d materials · by %s" % [ev.get("family", "?"), f["versions"].size(), fv["items"].size(), author]
		if used > 0:
			sub += " · %d product%s" % [used, "s" if used > 1 else ""]
		var look := {"shape": absi(hash(fid)) % 10, "cap": absi(hash(fid + "c")) % 8, "glass": 0, "label": 0, "accent": "#c9a55a", "tint": "natural"}
		for k in f.get("look", {}):
			look[k] = f["look"][k]
		var bv := BottleView.new().setup(look, "", "", ev.get("profile", PackedFloat32Array()))
		bv.show_label = false
		bv.vivid = true
		bv.custom_minimum_size = Vector2(56, 88)
		UI.row_card(body, f["name"], sub, G.money(float(ev.get("cost_kg", 0.0))) + "/kg", func(): Router.go("formula_editor", {"fid": fid}), bv)
