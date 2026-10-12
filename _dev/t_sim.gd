extends Node
## Multi-year headless simulation with integrity checks.

func run(args: Array) -> void:
	var years := float(args[0]) if args.size() > 0 else 1.0
	var t0 := Time.get_ticks_msec()
	WorldGen.new_game({"company": "Test House", "brand": "Test", "home": "TR", "posit": "premium", "seed": 42})
	print("new game ms: ", Time.get_ticks_msec() - t0)
	_report_rivals()
	var c := G.pc()
	var b: Dictionary = G.company_brands(G.pid())[0]
	var items := FormulaEngine.normalize_items([["bergamot",10],["pink_pepper",3],["iso_e_super",30],["ambroxan",3],["cedarwood",12],["vetiver",0],["hedione",12],["galaxolide",15],["amber_accord",10],["dpg",5]])
	items = items.filter(func(x): return G.ing_available(G.pid(), x[0]))
	items = FormulaEngine.normalize_items(items)
	var f := CompanyEngine.make_formula(G.pid(), "Ember Dune", items, "ceo")
	var p := CompanyEngine.make_product(G.pid(), {"brand": b["id"], "name": "Ember Dune", "formula": f["id"], "fmt": "edp", "conc": 18.0, "volume": 50.0, "pack": "standard", "audience": "any", "price": 65.0, "markets": ["TR"], "launch_budget": 8000.0})
	var err := ProductionEngine.place_order(G.pid(), p["id"], 800, "quickfill", {"maturation": 0, "chill": true})
	print("order: ", err if err != "" else "ok", "  cash ", G.money(FinanceEngine.cash_of(c)))
	var weeks := int(years * 52)
	var t1 := Time.get_ticks_msec()
	var issues: Array = []
	for i in weeks:
		var rep := Sim.advance()
		if int(p["inv"]) < 200 and p["status"] == "active":
			ProductionEngine.place_order(G.pid(), p["id"], 1500, "meridian", {"chill": true})
		for cc in G.s["companies"].values():
			var gap := FinanceEngine.balance_gap(cc)
			if absf(gap) > 1.0:
				issues.append("week %d %s balance gap %.2f" % [G.week(), cc["name"], gap])
			if is_nan(FinanceEngine.cash_of(cc)):
				issues.append("NaN cash " + cc["name"])
		for pp in G.s["products"].values():
			if int(pp["inv"]) < 0:
				issues.append("negative inventory " + pp["name"])
		if i < 6 or i % 13 == 12:
			var wk: Array = p["wk"]
			var last = wk[wk.size()-1] if not wk.is_empty() else [0,0,0,0,0]
			print("w%3d %-8s cash %10s  units %5d rev %9s  inv %5d aw %.3f loyal %.0f rating %.2f(%d) %s" % [G.week(), p["status"], G.money(FinanceEngine.cash_of(c)), int(last[1]), G.money(float(last[2])), int(p["inv"]), float(p["mk"].get("TR", {}).get("aw", 0)), float(p["mk"].get("TR", {}).get("loyal", 0)), Awards.rating_avg(p), int(p["rating"]["n"]), str(rep["events"])])
	print("sim ms/week: ", float(Time.get_ticks_msec() - t1) / weeks)
	_report_rivals()
	print("issues: ", issues.size(), " ", issues.slice(0, 8))
	var e: Dictionary = {}
	for id in G.s["employees"]:
		var em: Dictionary = G.s["employees"][id]
		if em.get("employer", "") != "":
			e[id] = true
	print("employees employed: ", e.size())
	if p["reviews"].size() > 0:
		for rv in p["reviews"].slice(0, 4):
			print("  ", rv["stars"], "★ ", rv["text"])
	var sv := ConsumerEngine.survey({"items": items, "fmt": "edp", "conc": 18.0, "price": 65.0, "volume": 50.0, "posit": "premium", "prestige": 0.15}, "TR", 250, false, "t")
	print("survey like %.2f ±%.2f intent %.2f long_fb %s proj_fb %s" % [sv["like"], sv["moe"], sv["intent"], str(sv["long_fb"]), str(sv["proj_fb"])])
	for cm in sv["comments"].slice(0, 3):
		print("   ", cm)
	var t2 := Time.get_ticks_msec()
	Save.save_game("slot3")
	var err2 := Save.load_game("slot3")
	print("save/load: ", err2 if err2 != "" else "ok", " ms ", Time.get_ticks_msec() - t2, " size ", FileAccess.get_file_as_bytes(Save.path("slot3")).size())
	Sim.advance()
	print("after load advance ok, week ", G.week())

func _report_rivals() -> void:
	for x in Rivals.ranking():
		print("  %-26s rev %10s net %10s units %7d val %10s share %.3f prods %d" % [x["name"], G.money(x["rev"]), G.money(x["net"]), x["units"], G.money(x["val"]), x["share"], x["products"]])
