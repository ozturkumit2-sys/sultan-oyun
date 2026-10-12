class_name Sim
extends RefCounted
## The single weekly turn processor. Fixed processing order keeps results consistent and reproducible.


static func empty_report() -> Dictionary:
	return {"w": G.week(), "events": [], "stockouts": [], "launches": [], "by_company": {}, "top": []}


static func advance() -> Dictionary:
	var rep := empty_report()
	var w := G.week()
	var r := G.rng
	var pc := G.pc()
	var cash0 := FinanceEngine.cash_of(pc)
	var launched_before := {}
	for p in G.company_products(G.pid(), ["active"]):
		launched_before[p["id"]] = true
	G.clear_cache(false)
	# 0. delegated managers act on company data
	Delegation.weekly(rep)
	# 1. research and perfumer projects
	for c in _companies():
		Lab.weekly(c, rep)
	# 2-3. manufacturing, deliveries, quality control, construction
	ProductionEngine.weekly(rep)
	for c in _companies():
		_construction(c)
		ProductionEngine.factory_weekly(c)
	# 4. advertising
	MarketingEngine.weekly(rep)
	MarketingEngine.media_weekly(r)
	# 5. competitor strategies
	for c in _companies():
		Rivals.weekly(c, r, rep)
	# 6-8. demand, sales allocation, customer experience
	MarketEngine.run_week(rep)
	# 9. finance and payroll
	for c in _companies():
		Rivals.overhead(c)
		Staff.weekly(c)
		FinanceEngine.spend(c, "facilities", CompanyEngine.hq_weekly(c) + CompanyEngine.office_weekly(c))
		var ppe := float(c["fin"]["ppe"])
		if ppe > 0.0:
			var dep := ppe / 520.0
			c["fin"]["ppe"] = ppe - dep
			FinanceEngine.pl(c, "depreciation", -dep)
		FinanceEngine.service_loans(c)
		Corporate.weekly(c, rep)
		FinanceEngine.liquidity(c)
		var units := int(rep["by_company"].get(c["id"], {}).get("units", 0))
		var rec := FinanceEngine.close_week(c, units)
		if G.is_player(c["id"]):
			rep["fin"] = rec
	# 10. reputation
	for c in _companies():
		Corporate.reputation(c)
	# 11. market events, trends, employees
	IngredientMarket.weekly(r)
	Events.weekly(r, rep)
	_trends(r)
	Staff.rival_poach(r)
	Staff.refresh_candidates()
	MarketEngine.decay()
	if G.week_of_year(w) == 50:
		Awards.run(r, rep)
	if w % 13 == 12:
		Awards.statuses()
	if G.week_of_year(w) == 26:
		Corporate.rival_mna(r)
		_trim()
	# 12. reports
	for p in G.company_products(G.pid(), ["active"]):
		if not launched_before.has(p["id"]):
			rep["launches"].append(p["name"])
	var tops: Array = []
	for p in G.company_products(G.pid(), ["active", "discontinued"]):
		var wk: Array = p["wk"]
		if not wk.is_empty() and int(wk[wk.size() - 1][0]) == w:
			tops.append([p["name"], int(wk[wk.size() - 1][1]), float(wk[wk.size() - 1][2]), p["id"]])
	tops.sort_custom(func(a, b): return a[1] > b[1])
	rep["top"] = tops
	rep["cash"] = FinanceEngine.cash_of(pc)
	rep["cash_delta"] = FinanceEngine.cash_of(pc) - cash0
	G.s["week"] = w + 1
	G.s["stats"]["weeks"] = int(G.s["stats"].get("weeks", 0)) + 1
	var reps: Array = G.s["reports"]
	reps.append({"w": w, "rev": float(rep.get("fin", {}).get("revenue", 0.0)), "net": float(rep.get("fin", {}).get("net", 0.0)),
		"u": int(rep["by_company"].get(G.pid(), {}).get("units", 0)), "ev": rep["events"].slice(0, 6), "launch": rep["launches"]})
	while reps.size() > 26:
		reps.remove_at(0)
	Tutorial.after_week(rep)
	G.store_rng()
	G.clear_cache(false)
	return rep


static func _companies() -> Array:
	var out: Array = []
	for c in G.s["companies"].values():
		if c.get("active", true):
			out.append(c)
	return out


static func _construction(c: Dictionary) -> void:
	var hq: Dictionary = c["hq"]
	if int(hq.get("weeks_left", 0)) <= 0:
		return
	hq["weeks_left"] = int(hq["weeks_left"]) - 1
	if int(hq["weeks_left"]) <= 0:
		hq["tier"] = int(hq["build_to"])
		var t := DB.hq_tier(int(hq["tier"]))
		for d in t["depts"]:
			if int(c["depts"].get(d, 0)) == 0:
				c["depts"][d] = 1
		G.log_event("Your new %s is complete!" % t["name"], "good", c["id"])
		G.cache.erase("reach")


static func _trends(r: RandomNumberGenerator) -> void:
	for ct in DB.countries:
		var mk: Dictionary = G.s["markets"][ct["id"]]
		var tr := G.to_vec(mk["trend"])
		var base: PackedFloat32Array = ct["trend"]
		var glob: Array = G.s["events"].get("global_trend", [])
		for i in tr.size():
			var gb := float(glob[i]) if i < glob.size() else 0.0
			tr[i] += (base[i] + gb - tr[i]) * 0.03 + r.randfn(0.0, 0.006)
			tr[i] = clampf(tr[i], -0.3, 0.3)
		mk["trend"] = Array(tr)


## Keeps saves compact: long-discontinued products keep their identity, totals and recent history only.
static func _trim() -> void:
	for p in G.s["products"].values():
		if p["status"] != "discontinued" or G.week() - int(p.get("disc_week", G.week())) < 52:
			continue
		if p["wk"].size() > 26:
			p["wk"] = p["wk"].slice(p["wk"].size() - 26)
		if p["reviews"].size() > 5:
			p["reviews"] = p["reviews"].slice(p["reviews"].size() - 5)
		if p["log"].size() > 20:
			p["log"] = p["log"].slice(p["log"].size() - 20)
		for cid in p["mk"]:
			p["mk"][cid]["loyal"] = 0.0
