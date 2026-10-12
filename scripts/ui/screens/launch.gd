extends Screen
## Launch wizard: fragrance → bottle & format → price, markets & edition → first production batch.

const ACCENTS := [["Gold", "#c9a55a"], ["Silver", "#c8ccd4"], ["Rose gold", "#d9a08f"], ["Black", "#2a262e"], ["Ivory", "#efe6d6"], ["Copper", "#c27a4a"], ["Emerald", "#2f8a63"], ["Sapphire", "#3b5fae"]]

var step := 0
var st := {}


func page_title() -> String:
	return "Launch a perfume"


func setup(p: Dictionary) -> void:
	params = p
	var c := G.pc()
	var bs := G.company_brands(G.pid())
	var b: Dictionary = bs[0] if not bs.is_empty() else {}
	var fmt: String = p.get("fmt", "edp")
	st = {"fid": p.get("fid", ""), "v": int(p.get("v", -1)), "name": "", "brand": b.get("id", ""), "audience": "any", "fmt": fmt,
		"conc": float(p.get("conc", DB.formats[fmt]["def"])), "volume": 50.0, "pack": "standard",
		"bottle": {"shape": 0, "cap": 0, "glass": 0, "label": 1, "accent": c.get("color", "#c9a55a")},
		"price": 0.0, "markets": [c["home"]], "edition": "regular", "limit": 1000, "season": "summer",
		"budget": 5000.0, "mfr": "quickfill", "qty": 500, "mat": 0, "chill": true, "kind": p.get("kind", "full"), "parent": p.get("parent", "")}
	if st["fid"] != "":
		var f := G.formula(st["fid"])
		st["name"] = f["name"]
		if st["v"] < 0:
			st["v"] = f["versions"].size() - 1
		st["audience"] = f.get("audience", "any")
		var lk: Dictionary = f.get("look", {})
		for k in ["shape", "cap", "tint"]:
			if lk.has(k):
				st["bottle"][k] = lk[k]
	if st["parent"] != "":
		var par := G.product(st["parent"])
		for k in ["brand", "audience", "fmt", "conc", "pack", "markets"]:
			st[k] = par[k] if not (par[k] is Array) else par[k].duplicate()
		st["bottle"] = par["bottle"].duplicate()
		st["fid"] = par["formula"]
		st["v"] = int(par["fv"])
		match st["kind"]:
			"travel":
				st["name"] = par["name"] + " Travel"
				st["volume"] = 10.0
			"sample":
				st["name"] = par["name"] + " Sample"
				st["volume"] = 2.0
				st["pack"] = "basic"
			_:
				st["name"] = par["name"] + " " + ("Limited Edition" if p.get("edition", "") == "limited" else "Intense")
				st["volume"] = float(par["volume"])
		if p.get("edition", "") != "":
			st["edition"] = p["edition"]
		st["budget"] = 0.0
		step = 1
	_make()
	build()


func _temp_product() -> Dictionary:
	return {"id": "tmp", "volume": st["volume"], "kind": st["kind"], "set": [], "conc": st["conc"], "fmt": st["fmt"],
		"formula": st["fid"], "fv": st["v"], "pack": st["pack"], "price": st["price"], "bottle": st["bottle"]}


func build() -> void:
	var steps := ["Fragrance", "Bottle", "Price & markets", "Production"]
	var sh := UI.hbox(6)
	for i in steps.size():
		var pl := UI.pill("%d %s" % [i + 1, steps[i]], UI.GOLD if i == step else (UI.GREEN if i < step else UI.DIM), 16)
		sh.add_child(pl)
	body.add_child(sh)
	match step:
		0:
			_step_fragrance()
		1:
			_step_bottle()
		2:
			_step_price()
		3:
			_step_production()


func _nav(next_ok: bool, next_text := "Continue") -> void:
	var h := UI.hbox(10)
	if step > 0:
		h.add_child(UI.expand(UI.btn("Back", func():
			step -= 1
			rebuild(), "secondary", 22)))
	var nb := UI.btn(next_text, func():
		step += 1
		rebuild(), "primary", 22)
	nb.disabled = not next_ok
	h.add_child(UI.expand(nb))
	body.add_child(h)


func _step_fragrance() -> void:
	UI.section(body, "Choose a formula")
	var forms: Array = G.s["formulas"].values().filter(func(f): return f["company"] == G.pid() and not f.get("accord", false) and not f.get("archived", false))
	if forms.is_empty():
		UI.empty(body, "You have no formulas yet. Compose one in the Lab first.")
		body.add_child(UI.btn("Open formula editor", func(): Router.replace("formula_editor", {}), "primary", 22))
		return
	if st["fid"] == "":
		st["fid"] = forms[forms.size() - 1]["id"]
		st["v"] = G.formula(st["fid"])["versions"].size() - 1
		st["name"] = G.formula(st["fid"])["name"]
	var opts: Array = []
	for f in forms:
		opts.append([f["name"], f["id"]])
	body.add_child(UI.seg(opts, st["fid"], func(v):
		st["fid"] = v
		var f := G.formula(v)
		st["v"] = f["versions"].size() - 1
		st["name"] = f["name"]
		st["fmt"] = f.get("fmt", st["fmt"])
		st["conc"] = float(f.get("conc", DB.formats[st["fmt"]]["def"]))
		rebuild(), 20))
	var f2 := G.formula(st["fid"])
	if f2["versions"].size() > 1:
		var vopts: Array = []
		for i in f2["versions"].size():
			vopts.append(["Version %d" % (i + 1), i])
		body.add_child(UI.seg(vopts, st["v"], func(v):
			st["v"] = v
			rebuild()))
	var fv: Dictionary = f2["versions"][st["v"]]
	var ev := FormulaEngine.evaluate(fv["items"], st["fmt"], st["conc"])
	var pc := UI.card(body)
	pc.add_child(UI.title(str(ev["family"]), 28, UI.GOLD2))
	UI.dims_bars(pc, ev["profile"], 4)
	if not ev["valid"]:
		for e in ev["errors"]:
			pc.add_child(UI.para("• " + str(e), 19, UI.RED))
	UI.section(body, "Product name")
	var ne := UI.line_edit(st["name"], "Product name")
	ne.max_length = 26
	ne.text_changed.connect(func(t): st["name"] = t)
	body.add_child(ne)
	UI.section(body, "Brand")
	var bopts: Array = []
	for b in G.company_brands(G.pid()):
		bopts.append(["%s (%s)" % [b["name"], DB.positionings[b["posit"]]["name"]], b["id"]])
	body.add_child(UI.seg(bopts, st["brand"], func(v):
		st["brand"] = v
		rebuild()))
	UI.section(body, "Intended audience")
	body.add_child(UI.seg([["Feminine", "fem"], ["Masculine", "masc"], ["Unisex", "any"]], st["audience"], func(v):
		st["audience"] = v
		rebuild()))
	body.add_child(UI.para("The audience label changes who considers the product on the shelf; the scent itself is what wins or loses them.", 18))
	_nav(ev["valid"] and str(st["name"]).strip_edges().length() >= 2)


func _step_bottle() -> void:
	var b := G.brand(st["brand"])
	var fv := G.formula_version(st["fid"], st["v"])
	var ev := FormulaEngine.evaluate(fv["items"], st["fmt"], st["conc"])
	var sh := Showcase.new().setup(st["bottle"], b.get("name", ""), st["name"], ev["profile"])
	sh.custom_minimum_size = Vector2(0, 460)
	body.add_child(sh)
	UI.section(body, "Juice colour")
	var topts: Array = []
	for t in BottleView.TINTS.keys():
		topts.append([str(t).capitalize(), t])
	body.add_child(UI.seg(topts, st["bottle"].get("tint", "natural"), func(v):
		st["bottle"]["tint"] = v
		rebuild(), 19))
	if st["kind"] == "full":
		UI.section(body, "Format")
		var fopts: Array = []
		for fm in DB.biz["formats"]:
			fopts.append([fm["name"], fm["id"]])
		body.add_child(UI.seg(fopts, st["fmt"], func(v):
			st["fmt"] = v
			st["conc"] = float(DB.formats[v]["def"])
			rebuild(), 19))
		var fd: Dictionary = DB.formats[st["fmt"]]
		var cr := UI.hbox(10)
		var cl := UI.lbl("%.1f%% concentrate" % st["conc"], 20, UI.GOLD2, "semi")
		cl.custom_minimum_size.x = 230
		cr.add_child(cl)
		cr.add_child(UI.slider(float(fd["min"]), float(fd["max"]), 0.5, st["conc"], func(x):
			st["conc"] = x
			cl.text = "%.1f%% concentrate" % x))
		body.add_child(cr)
		UI.section(body, "Volume")
		var vopts: Array = []
		for vv in DB.biz["volumes"]:
			if float(vv) >= 10.0:
				vopts.append(["%d ml" % int(vv), float(vv)])
		body.add_child(UI.seg(vopts, st["volume"], func(v):
			st["volume"] = v
			rebuild()))
	UI.section(body, "Bottle shape")
	_design_seg("shape", DB.biz["shapes"])
	UI.section(body, "Cap")
	_design_seg("cap", DB.biz["caps"])
	UI.section(body, "Glass")
	var gopts: Array = []
	for i in DB.biz["glass"].size():
		gopts.append([DB.biz["glass"][i][0], i])
	body.add_child(UI.seg(gopts, int(st["bottle"]["glass"]), func(v):
		st["bottle"]["glass"] = v
		rebuild(), 19))
	UI.section(body, "Label")
	_design_seg("label", DB.biz["labels"])
	UI.section(body, "Metal accent")
	var aopts: Array = []
	for a in ACCENTS:
		aopts.append([a[0], a[1]])
	body.add_child(UI.seg(aopts, st["bottle"]["accent"], func(v):
		st["bottle"]["accent"] = v
		rebuild(), 19))
	UI.section(body, "Packaging quality")
	var pk: Array = []
	for p in DB.biz["packaging"]:
		pk.append(["%s · %s" % [p["name"], G.money(CompanyEngine.pack_cost(p["id"], st["volume"]), 2)], p["id"]])
	body.add_child(UI.seg(pk, st["pack"], func(v):
		st["pack"] = v
		rebuild(), 19))
	body.add_child(UI.para(DB.packaging[st["pack"]]["desc"] + " Clear glass shows discoloration; colored or opaque glass hides it.", 18))
	_nav(true)


func _design_seg(key: String, names: Array) -> void:
	var o: Array = []
	for i in names.size():
		o.append([names[i], i])
	body.add_child(UI.seg(o, int(st["bottle"][key]), func(v):
		st["bottle"][key] = v
		rebuild(), 19))


func _step_price() -> void:
	var c := G.pc()
	var b := G.brand(st["brand"])
	var tp := _temp_product()
	var cb := CompanyEngine.cost_breakdown(tp, st["mfr"])
	var unit := float(cb["total"])
	var ref := float(WorldGen.BASE_PP.get(b["posit"], 60.0)) * float(DB.formats[st["fmt"]]["ref_mult"]) * pow(float(st["volume"]) / 100.0, 0.8)
	ref *= 0.4 + 0.6 * float(DB.country(c["home"])["ppp"])
	if float(st["price"]) <= 0.0:
		st["price"] = maxf(round(unit * 3.0), round(ref))
	var cc := UI.card(body)
	cc.add_child(UI.lbl("ESTIMATED UNIT COST", 16, UI.GOLD, "semi"))
	UI.kv(cc, "Fragrance juice", G.money(float(cb["juice"]), 2))
	UI.kv(cc, "Bottle & packaging", G.money(float(cb["pack"]), 2))
	UI.kv(cc, "Filling (%s)" % DB.manufacturers.get(st["mfr"], {}).get("name", "contract"), G.money(float(cb["fill"]), 2))
	UI.kv(cc, "Total per unit", G.money(unit, 2), UI.GOLD2)
	UI.section(body, "Retail price (incl. VAT)")
	var pl := UI.title(G.money(float(st["price"]), 0), 44, UI.GOLD2)
	body.add_child(pl)
	var mlab := UI.para("", 19)
	var upd := func():
		var net := float(st["price"]) / (1.0 + float(DB.country(c["home"])["vat"]))
		var dtc := net * 0.97 - 5.0 - unit
		var ret := net * 0.55 - unit
		pl.text = G.money(float(st["price"]), 0)
		mlab.text = "Per unit in %s: own store ≈ %s margin · retail partner ≈ %s margin. Typical %s price for this size: about %s." % [DB.country(c["home"])["name"], G.money(dtc), G.money(ret), DB.positionings[b["posit"]]["name"].to_lower(), G.money(ref, 0)]
	upd.call()
	body.add_child(UI.slider(maxf(3.0, round(unit * 1.2)), maxf(60.0, round(ref * 4.0)), 1.0, float(st["price"]), func(x):
		st["price"] = x
		upd.call()))
	body.add_child(mlab)
	UI.section(body, "Launch markets")
	var mk: Array = st["markets"]
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for ct in DB.countries:
		var id: String = ct["id"]
		var on := mk.has(id)
		var txt = ct["name"] + ("" if CompanyEngine.has_office(G.pid(), id) else " ✈")
		flow.add_child(UI.chip(txt, on, func():
			if mk.has(id):
				if mk.size() > 1:
					mk.erase(id)
			else:
				mk.append(id)
			rebuild()))
	body.add_child(flow)
	body.add_child(UI.para("✈ = no office yet: customers can order from your online store (cross-border shipping, lower reach). Open offices to sign retail partners.", 18))
	if st["kind"] == "full":
		UI.section(body, "Edition")
		body.add_child(UI.seg([["Regular", "regular"], ["Limited (numbered)", "limited"], ["Seasonal", "seasonal"]], st["edition"], func(v):
			st["edition"] = v
			rebuild()))
		if st["edition"] == "limited":
			var ll := UI.lbl("%s numbered bottles" % G.group_int(int(st["limit"])), 20, UI.GOLD2, "semi")
			body.add_child(ll)
			body.add_child(UI.slider(200, 20000, 100, float(st["limit"]), func(x):
				st["limit"] = int(x)
				ll.text = "%s numbered bottles" % G.group_int(int(x))))
			body.add_child(UI.para("Limited runs appeal to collectors but are not guaranteed to sell out; once made, no more can be produced.", 18))
		elif st["edition"] == "seasonal":
			body.add_child(UI.seg([["Summer", "summer"], ["Winter holidays", "winter"]], st["season"], func(v):
				st["season"] = v
				rebuild()))
	UI.section(body, "Launch marketing")
	var cash := FinanceEngine.cash_of(c)
	var bl := UI.lbl("%s over 4 weeks" % G.money(float(st["budget"])), 20, UI.GOLD2, "semi")
	body.add_child(bl)
	body.add_child(UI.slider(0.0, maxf(2000.0, snappedf(cash * 0.4, 500.0)), 500.0, float(st["budget"]), func(x):
		st["budget"] = x
		bl.text = "%s over 4 weeks" % G.money(x)))
	body.add_child(UI.para("Social ads and PR start when the product goes on sale. Awareness helps customers discover it; whether they buy depends on the perfume, price and reach.", 18))
	_nav(not mk.is_empty())


func _step_production() -> void:
	var c := G.pc()
	var tp := _temp_product()
	UI.section(body, "Manufacturer")
	var mfrs: Array = DB.biz["manufacturers"].duplicate()
	if ProductionEngine.has_factory(G.pid()):
		mfrs.push_front(ProductionEngine.mfr_info(G.pid(), "own"))
	for m in mfrs:
		var id: String = m["id"]
		var on: bool = id == st["mfr"]
		var p := TapPanel.new()
		p.add_theme_stylebox_override("panel", UI.sb(Color(0.79, 0.65, 0.35, 0.14) if on else UI.PANEL, 16, UI.GOLD if on else UI.LINE, 2 if on else 1, 14))
		p.tapped = func():
			st["mfr"] = id
			st["qty"] = maxi(int(st["qty"]), int(m["moq"]))
			rebuild()
		var v := UI.vbox(2)
		v.add_child(UI.lbl(m["name"], 22, UI.CREAM, "semi"))
		v.add_child(UI.lbl("Filling %s/unit · setup %s · min %s · %s/wk · lead %d wk" % [G.money(float(m["fill"]), 2), G.money(float(m["setup"])), G.group_int(int(m["moq"])), G.group_int(int(m["cap"])), int(m["lead"])], 17, UI.MUTED))
		v.add_child(UI.lbl("Reliability %d%% · QC detection %d%%" % [int(float(m["rel"]) * 100), int(float(m["qc"]) * 100)], 17, UI.MUTED))
		if m.has("desc"):
			v.add_child(UI.para(str(m["desc"]), 17))
		p.add_child(v)
		body.add_child(p)
	var mf := ProductionEngine.mfr_info(G.pid(), st["mfr"])
	var moq := int(mf["moq"])
	if st["edition"] == "limited":
		st["qty"] = mini(int(st["qty"]), int(st["limit"]))
	UI.section(body, "First batch")
	var ql := UI.lbl("%s units" % G.group_int(int(st["qty"])), 22, UI.GOLD2, "semi")
	body.add_child(ql)
	var qmax := maxi(moq * 20, 5000)
	if st["edition"] == "limited":
		qmax = int(st["limit"])
	var quote_box := UI.vbox(6)
	var redo := func():
		for ch in quote_box.get_children():
			ch.queue_free()
		var q := ProductionEngine.quote(G.pid(), tp, int(st["qty"]), st["mfr"], {"maturation": st["mat"], "chill": st["chill"]})
		var qc := UI.card(quote_box)
		UI.kv(qc, "Raw materials to buy", G.money(float(q["buy_cost"])))
		UI.kv(qc, "Packaging, filling & setup", G.money(float(q["conv"])))
		UI.kv(qc, "Estimated unit cost", G.money(float(q["unit_est"]), 2), UI.GOLD2)
		UI.kv(qc, "Launch marketing", G.money(float(st["budget"])))
		var total := float(q["total_cash"]) + float(st["budget"])
		UI.kv(qc, "Cash needed now", G.money(total), UI.RED if total > FinanceEngine.cash_of(c) else UI.GREEN)
		UI.kv(qc, "On sale in about", "%d week(s)" % int(q["weeks"]))
		if not q["short"].is_empty():
			qc.add_child(UI.para("Missing supplier access: " + ", ".join(q["short"]), 18, UI.RED))
	body.add_child(UI.slider(float(moq), float(qmax), float(maxi(50, moq / 10)), float(st["qty"]), func(x):
		st["qty"] = int(x)
		ql.text = "%s units" % G.group_int(int(x))
		redo.call()))
	UI.section(body, "Process")
	var ml := UI.lbl("Maturation: %d week(s)" % int(st["mat"]), 20, UI.TEXT, "semi")
	body.add_child(ml)
	body.add_child(UI.slider(0, 6, 1, float(st["mat"]), func(x):
		st["mat"] = int(x)
		ml.text = "Maturation: %d week(s)" % int(x)
		redo.call()))
	body.add_child(UI.para("Resting softens rough natural materials and fresh aldehydes. It does not make every perfume better and delays the launch.", 18))
	body.add_child(UI.chip("Chill filtration (+$0.04/unit) " + ("ON" if st["chill"] else "OFF"), st["chill"], func():
		st["chill"] = not st["chill"]
		rebuild()))
	body.add_child(quote_box)
	redo.call()
	var h := UI.hbox(10)
	h.add_child(UI.expand(UI.btn("Back", func():
		step -= 1
		rebuild(), "secondary", 22)))
	h.add_child(UI.expand(UI.btn("Launch & produce", _confirm, "primary", 22)))
	body.add_child(h)


func _confirm() -> void:
	var c := G.pc()
	var tp := _temp_product()
	var q := ProductionEngine.quote(G.pid(), tp, int(st["qty"]), st["mfr"], {"maturation": st["mat"], "chill": st["chill"]})
	if float(q["total_cash"]) + float(st["budget"]) > FinanceEngine.cash_of(c):
		Router.toast("Not enough cash for this batch and launch budget.", "bad")
		return
	var ed := {"type": st["edition"]}
	if st["edition"] == "limited":
		ed["limit"] = int(st["limit"])
		ed["made"] = 0
	elif st["edition"] == "seasonal":
		ed["season"] = st["season"]
	var p := CompanyEngine.make_product(G.pid(), {"brand": st["brand"], "name": str(st["name"]).strip_edges(), "formula": st["fid"], "fv": st["v"],
		"fmt": st["fmt"], "conc": st["conc"], "volume": st["volume"], "maturation": st["mat"], "bottle": st["bottle"], "pack": st["pack"],
		"audience": st["audience"], "price": float(st["price"]), "markets": st["markets"].duplicate(), "edition": ed, "launch_budget": float(st["budget"]),
		"perfumer": G.formula(st["fid"]).get("author", "ceo"), "kind": st["kind"], "parent": st["parent"]})
	p["base_price"] = float(st["price"])
	var b := G.brand(st["brand"])
	for m in st["markets"]:
		if not b["markets"].has(m):
			b["markets"].append(m)
	var err := ProductionEngine.place_order(G.pid(), p["id"], int(st["qty"]), st["mfr"], {"maturation": st["mat"], "chill": st["chill"]})
	if err != "":
		Router.toast(err, "bad")
		CompanyEngine.plog(p, "First production order failed: " + err)
	else:
		Router.toast("%s is in production!" % p["name"], "good")
	Tutorial.check()
	G.touch()
	Router.replace("product_detail", {"id": p["id"]})
