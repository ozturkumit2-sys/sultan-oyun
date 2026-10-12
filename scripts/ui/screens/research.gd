extends Screen
## Consumer research: blind and branded surveys sampled from the same preference model as real sales.

var st := {}


func page_title() -> String:
	return "Consumer research"


func hero_spec() -> Dictionary:
	return {"scene": "office", "title": "Consumer research", "sub": "Blind and branded surveys", "focus": Vector2(0.3, 0.4), "h": 250.0}


func setup(p: Dictionary) -> void:
	params = p
	var c := G.pc()
	st = {"src": "formula", "fid": p.get("fid", ""), "v": int(p.get("v", -1)), "fmt": p.get("fmt", "edp"), "conc": float(p.get("conc", 18.0)),
		"pid": p.get("product", ""), "country": c["home"], "n": 250, "blind": true, "price": 60.0, "volume": 50.0, "brand": "", "audience": "any"}
	if st["pid"] != "":
		var pr := G.product(st["pid"])
		st["src"] = "product"
		st["fid"] = pr["formula"]
		st["v"] = int(pr["fv"])
		st["fmt"] = pr["fmt"]
		st["conc"] = float(pr["conc"])
		st["price"] = float(pr["price"])
		st["volume"] = float(pr["volume"])
		st["brand"] = pr["brand"]
		st["audience"] = pr["audience"]
		st["blind"] = false
	elif st["fid"] == "":
		var forms = G.s["formulas"].values().filter(func(f): return f["company"] == G.pid() and not f.get("accord", false))
		if not forms.is_empty():
			st["fid"] = forms[forms.size() - 1]["id"]
	if st["fid"] != "" and st["v"] < 0:
		st["v"] = G.formula(st["fid"])["versions"].size() - 1
	var bs := G.company_brands(G.pid())
	if st["brand"] == "" and not bs.is_empty():
		st["brand"] = bs[0]["id"]
	_make()
	_pre_build()
	build()


func build() -> void:
	if st["fid"] == "":
		UI.empty(body, "Create a formula first.")
		return
	var c := G.pc()
	var f := G.formula(st["fid"])
	var hc := UI.card(body, "gold")
	hc.add_child(UI.title(G.product(st["pid"]).get("name", f["name"]) if st["pid"] != "" else f["name"], 30))
	hc.add_child(UI.lbl("Formula v%d · %s %.0f%%" % [int(st["v"]) + 1, DB.formats[st["fmt"]]["name"], float(st["conc"])], 18, UI.MUTED))
	if st["pid"] == "":
		var forms = G.s["formulas"].values().filter(func(x): return x["company"] == G.pid() and not x.get("accord", false) and not x.get("archived", false))
		var opts: Array = []
		for x in forms:
			opts.append([x["name"], x["id"]])
		hc.add_child(UI.seg(opts, st["fid"], func(x):
			st["fid"] = x
			st["v"] = G.formula(x)["versions"].size() - 1
			st["fmt"] = G.formula(x).get("fmt", "edp")
			st["conc"] = float(G.formula(x).get("conc", 18.0))
			rebuild(), 19))
	UI.section(body, "Test type")
	body.add_child(UI.seg([["Blind test", true], ["Branded test", false]], st["blind"], func(x):
		st["blind"] = x
		rebuild()))
	body.add_child(UI.para("Blind: respondents smell and wear it without brand, bottle or price. Branded: they see your brand, packaging and price, and tell you whether they would buy.", 18))
	UI.section(body, "Market")
	var co: Array = []
	for ct in DB.countries:
		co.append([ct["name"], ct["id"]])
	body.add_child(UI.seg(co, st["country"], func(x):
		st["country"] = x
		rebuild(), 19))
	UI.section(body, "Sample size")
	body.add_child(UI.seg([["50 people", 50], ["250 people", 250], ["1,000 people", 1000]], st["n"], func(x):
		st["n"] = x
		rebuild()))
	if not st["blind"]:
		UI.section(body, "Branded concept")
		var pl := UI.lbl("Price %s · %d ml" % [G.money(float(st["price"]), 0), int(st["volume"])], 20, UI.GOLD2, "semi")
		body.add_child(pl)
		body.add_child(UI.slider(5, 400, 1, float(st["price"]), func(x):
			st["price"] = x
			pl.text = "Price %s · %d ml" % [G.money(x, 0), int(st["volume"])]))
		var bo: Array = []
		for b in G.company_brands(G.pid()):
			bo.append([b["name"], b["id"]])
		body.add_child(UI.seg(bo, st["brand"], func(x):
			st["brand"] = x
			rebuild(), 19))
		body.add_child(UI.seg([["Feminine", "fem"], ["Masculine", "masc"], ["Unisex", "any"]], st["audience"], func(x):
			st["audience"] = x
			rebuild(), 19))
	var cost := ConsumerEngine.survey_cost(int(st["n"]), st["country"])
	body.add_child(UI.btn("Run survey · %s" % G.money(cost), _run, "primary", 23, 80))
	body.add_child(UI.para("Surveys never perfectly predict sales: real buyers also need to discover your product, find it in stores and compare it with competitors.", 17, UI.DIM))
	var svs = G.s["surveys"].filter(func(s): return s["company"] == G.pid() and s["formula"] == st["fid"])
	if not svs.is_empty():
		UI.section(body, "Results")
		for i in range(svs.size() - 1, maxi(-1, svs.size() - 5), -1):
			SurveyCard.add(body, svs[i])


func _run() -> void:
	var b := G.brand(st["brand"])
	var fv := G.formula_version(st["fid"], int(st["v"]))
	var spec := {"items": fv["items"], "fmt": st["fmt"], "conc": st["conc"], "price": st["price"], "volume": st["volume"],
		"pack": G.product(st["pid"]).get("pack", "standard") if st["pid"] != "" else "standard", "audience": st["audience"],
		"posit": b.get("posit", "premium"), "prestige": float(b.get("prestige", 0.2)), "label": G.formula(st["fid"])["name"], "formula": st["fid"], "v": st["v"]}
	var r := Lab.run_survey(G.pid(), spec, st["country"], int(st["n"]), st["blind"])
	if r.has("error"):
		Router.toast(r["error"], "bad")
		return
	G.touch()
	Router.toast("Survey complete.", "good")
