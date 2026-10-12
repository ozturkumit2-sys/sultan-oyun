extends Node
## Multi-year accelerated validation with a heuristic auto-player and integrity checks.

var issues: Array = []
var p_ids: Array = []


func run(args: Array) -> void:
	var years := int(args[0]) if args.size() > 0 else 10
	var seed_v := int(args[1]) if args.size() > 1 else 11
	WorldGen.new_game({"company": "Auto House", "brand": "Auto", "home": "TR", "posit": "premium", "seed": seed_v})
	var c := G.pc()
	_launch("Woody Amber", 600, "quickfill", 6000.0)
	var t0 := Time.get_ticks_msec()
	for w in years * 52:
		_auto(w)
		Sim.advance()
		_check()
		if G.week() % 52 == 0:
			_report()
	for r0 in Rivals.ranking():
		print("RANKING %s rev %s net %s cash %s" % [r0["name"], G.money(float(r0["rev"])), G.money(float(r0["net"])), G.money(FinanceEngine.cash_of(G.company(r0["id"])) if r0.has("id") else 0.0)])
	print("ms/week avg: %.1f" % (float(Time.get_ticks_msec() - t0) / float(years * 52)))
	print("ISSUES (%d): %s" % [issues.size(), str(issues.slice(0, 12))])
	Save.save_game("slot3")
	var sz := FileAccess.get_file_as_bytes(Save.path("slot3")).size()
	print("save size: %d KB, products %d, employees %d, reviews total %d" % [sz / 1024, G.s["products"].size(), G.s["employees"].size(), _count_reviews()])
	var e := Save.load_game("slot3")
	print("reload: ", "ok" if e == "" else e)
	var gap := FinanceEngine.balance_gap(G.pc())
	print("post-load gap %.2f, advancing 4 weeks…" % gap)
	for i in 4:
		Sim.advance()
		_check()
	print("post-load issues: ", issues.size())


func _count_reviews() -> int:
	var n := 0
	for p in G.s["products"].values():
		n += p["reviews"].size()
	return n


func _launch(fam: String, qty: int, mfr: String, budget: float) -> void:
	var c := G.pc()
	var avail: Array = DB.ing_order.filter(func(x): return G.ing_available(G.pid(), x))
	var gen := PerfumerAI.generate({"target": PerfumerAI.family_target(fam), "fmt": "edp", "posit": "premium"}, {"creativity": 0.5, "technique": 0.7, "cost": 0.5}, avail, G.rng)
	var f := CompanyEngine.make_formula(G.pid(), fam, gen["items"], "ceo")
	var b: Dictionary = G.company_brands(G.pid())[0]
	var p := CompanyEngine.make_product(G.pid(), {"brand": b["id"], "name": fam + " " + str(p_ids.size() + 1), "formula": f["id"], "fmt": "edp", "conc": gen["conc"], "volume": 50.0,
		"pack": "standard", "audience": "any", "price": 49.0, "markets": c["offices"].keys(), "launch_budget": budget})
	var err := ProductionEngine.place_order(G.pid(), p["id"], qty, mfr, {"chill": true})
	if err != "":
		print("launch order failed: ", err)
	p_ids.append(p["id"])


func _auto(w: int) -> void:
	var c := G.pc()
	var cash := FinanceEngine.cash_of(c)
	for pid in p_ids:
		var p := G.product(pid)
		if p["status"] == "discontinued":
			continue
		var avg := maxf(20.0, Rivals.avg_units(p, 4)) if not p["wk"].is_empty() else 50.0
		if float(int(p["inv"]) + Rivals.pipeline(pid)) < avg * 5.0:
			var mf := "meridian" if avg * 10.0 >= 1000.0 else "quickfill"
			if ProductionEngine.has_factory(G.pid()):
				mf = "own"
			ProductionEngine.place_order(G.pid(), pid, maxi(int(avg * 10.0), 1000 if mf == "meridian" else 100), mf, {"chill": true})
	if w % 4 == 0 and cash > 15000.0:
		for pid in p_ids:
			var p2 := G.product(pid)
			if p2["status"] == "active":
				var busy := false
				for k in G.s["campaigns"]:
					if k["product"] == pid and k["status"] == "active":
						busy = true
				if not busy:
					MarketingEngine.start(G.pid(), "social", pid, p2["brand"], p2["markets"], clampf(cash * 0.02, 500.0, 30000.0), 4)
	if w % 26 == 13 and cash > 400000.0:
		for cid in ["DE", "FR", "US", "GB", "AE"]:
			if not c["offices"].has(cid):
				if CompanyEngine.open_office(c, cid) == "":
					for pid in p_ids:
						G.product(pid)["markets"].append(cid)
				break
		for cid in c["offices"]:
			for ch in ["marketplace", "beauty", "perfumery", "dept"]:
				var b: Dictionary = G.company_brands(G.pid())[0]
				var has := false
				for a in CompanyEngine.agreements(G.pid(), cid):
					if a["ch"] == ch:
						has = true
				if not has and CompanyEngine.channel_requirements(G.pid(), cid, ch, b) == "":
					CompanyEngine.sign_channel(c, cid, ch, CompanyEngine.channel_offer(G.pid(), cid, ch))
	# sign home retail partners once eligible
	if w % 8 == 4:
		var bh: Dictionary = G.company_brands(G.pid())[0]
		for ch in ["marketplace", "beauty", "perfumery"]:
			var has2 := false
			for a in CompanyEngine.agreements(G.pid(), c["home"]):
				if a["ch"] == ch:
					has2 = true
			var off := CompanyEngine.channel_offer(G.pid(), c["home"], ch)
			if not has2 and CompanyEngine.channel_requirements(G.pid(), c["home"], ch, bh) == "" and cash > float(off["fee"]) * 2.5:
				CompanyEngine.sign_channel(c, c["home"], ch, off)
	# grow the range early with own formulas
	if w > 20 and w % 26 == 0 and cash > 60000.0 and p_ids.size() < 4:
		_launch(["Fresh Citrus", "Floral Bouquet", "Gourmand"][p_ids.size() % 3], 500, "quickfill", 5000.0)
	if Staff.count(G.pid(), "perfumer") == 0 and cash > 100000.0:
		for id in G.s["candidates"]:
			if G.employee(id)["role"] == "perfumer":
				Staff.hire(G.pid(), id, float(G.employee(id)["salary"]) * 1.05, 3)
				break
	if Staff.count(G.pid(), "chemist") == 0 and cash > 250000.0:
		for id in G.s["candidates"]:
			if G.employee(id)["role"] == "chemist":
				Staff.hire(G.pid(), id, float(G.employee(id)["salary"]) * 1.05, 3)
				break
	for pr in G.s["proposals"]:
		if pr["company"] == G.pid() and pr["status"] == "open":
			if cash > 200000.0 and p_ids.size() < 12:
				var f := Lab.approve(pr)
				var b2: Dictionary = G.company_brands(G.pid())[0]
				var p3 := CompanyEngine.make_product(G.pid(), {"brand": b2["id"], "name": pr["name"], "formula": f["id"], "fmt": pr["fmt"], "conc": pr["conc"], "volume": 50.0,
					"pack": "premium", "audience": pr["audience"], "price": 85.0, "markets": c["offices"].keys(), "launch_budget": 20000.0})
				if ProductionEngine.place_order(G.pid(), p3["id"], 1000, "meridian", {"chill": true}) == "":
					p_ids.append(p3["id"])
			else:
				Lab.reject(pr)
	for m in G.inbox_open():
		match m.get("type", ""):
			"qc":
				var o := ProductionEngine.find_order(m["order"])
				if not o.is_empty() and o["stage"] == "qc_hold":
					ProductionEngine.rework(o)
				G.inbox_resolve(m["id"])
			"recall":
				ProductionEngine.recall(G.product(m["product"]))
				G.inbox_resolve(m["id"])
			"poach":
				Staff.resolve_poach(m["id"], true)
			_:
				G.inbox_resolve(m["id"])
	if int(c["hq"]["tier"]) == 1 and cash > 700000.0:
		CompanyEngine.hq_upgrade(c)
	elif int(c["hq"]["tier"]) == 2 and cash > 4000000.0:
		CompanyEngine.hq_upgrade(c)


func _check() -> void:
	var w := G.week()
	for c in G.s["companies"].values():
		var gap := FinanceEngine.balance_gap(c)
		if absf(gap) > 2.0:
			issues.append("w%d %s gap %.2f" % [w, c["name"], gap])
		for k in ["cash", "ppe", "goodwill", "debt", "paid_in", "retained"]:
			var v := float(c["fin"][k])
			if is_nan(v) or is_inf(v):
				issues.append("w%d %s %s NaN" % [w, c["name"], k])
		if not c.get("active", true) and absf(FinanceEngine.assets(c)) > 1.0:
			issues.append("w%d acquired %s still has assets" % [w, c["name"]])
		for k in c["raw"]:
			if float(c["raw"][k][0]) < -0.0001:
				issues.append("negative raw " + k)
	for p in G.s["products"].values():
		if int(p["inv"]) < 0:
			issues.append("w%d negative inventory %s" % [w, p["name"]])
		if is_nan(float(p["unit_cost"])):
			issues.append("NaN unit cost " + p["name"])
		var comp := G.company(p["company"])
		if not comp.get("active", true):
			issues.append("product owned by inactive company " + p["name"])
	for e in G.s["employees"].values():
		var emp: String = e.get("employer", "")
		if emp != "" and not G.company(emp).get("active", true):
			issues.append("employee at inactive company " + e["name"])
		if emp != "" and G.s["candidates"].has(e["id"]):
			issues.append("employed candidate " + e["name"])
	if w % 13 == 0:
		for f in G.s["formulas"].values():
			for v in f["versions"]:
				var tot := 0.0
				for it in v["items"]:
					tot += float(it[1])
				if absf(tot - 100.0) > 0.06:
					issues.append("formula %s total %.2f" % [f["name"], tot])


func _report() -> void:
	var c := G.pc()
	var t := FinanceEngine.ttm(c)
	var rk := Rivals.ranking()
	var rank := 0
	for i in rk.size():
		if rk[i]["player"]:
			rank = i + 1
	var top: Dictionary = rk[0]
	print("Y%d cash %9s rev %9s net %9s val %9s rank %d/%d prods %d staff %d tier %d offices %d | top: %s %s (net %s) | rivals cash total %s" % [G.week() / 52, G.money(FinanceEngine.cash_of(c)), G.money(float(t["revenue"])), G.money(float(t["net"])),
		G.money(FinanceEngine.valuation(c)), rank, rk.size(), G.company_products(G.pid()).size(), Staff.count(G.pid()), int(c["hq"]["tier"]), c["offices"].size(), top["name"], G.money(float(top["rev"])), G.money(float(top["net"])), G.money(_rival_cash())])


func _rival_cash() -> float:
	var t := 0.0
	for c in G.s["companies"].values():
		if not c.get("is_player", false) and c.get("active", true):
			t += FinanceEngine.cash_of(c)
	return t
