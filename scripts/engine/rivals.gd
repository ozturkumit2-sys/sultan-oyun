class_name Rivals
extends RefCounted
## Lightweight strategic AI for rival fragrance houses. Rivals obey the same market, production
## and finance rules as the player: they pay for materials, campaigns and staff, and can get into trouble.


static func avg_units(p: Dictionary, n := 4) -> float:
	var wk: Array = p["wk"]
	if wk.is_empty():
		return float(p.get("seed_avg", 600.0))
	var t := 0.0
	var k := 0
	for i in range(maxi(0, wk.size() - n), wk.size()):
		t += float(wk[i][1]) + float(wk[i][4])
		k += 1
	return t / float(maxi(1, k))


static func mfr_for(p: Dictionary) -> String:
	var b := G.brand(p["brand"])
	var c := G.company(p["company"])
	if ProductionEngine.has_factory(c["id"]):
		return "own"
	return WorldGen._mfr_for(b.get("posit", "mass"))


static func pipeline(pid: String) -> int:
	var n := 0
	for o in G.s["orders"]:
		if o["product"] == pid:
			n += int(o["qty"])
	return n


static func production(c: Dictionary, _warm := false) -> void:
	if c.get("is_player", false) or not c.get("active", true):
		return
	var need := 0.0
	for p in G.company_products(c["id"], ["active", "dev"]):
		var avg := avg_units(p)
		if p["status"] == "dev":
			avg = maxf(avg, 400.0)
		need += avg
		var waiting := false
		for o in G.s["orders"]:
			if o["product"] == p["id"] and o["stage"] == "materials":
				waiting = true
		if waiting:
			continue
		var pipe := pipeline(p["id"])
		var cover := float(int(p["inv"]) + pipe) / maxf(1.0, avg)
		if cover < 8.0:
			var mf := mfr_for(p)
			var moq := int(ProductionEngine.mfr_info(c["id"], mf)["moq"])
			var cap := int(ProductionEngine.mfr_info(c["id"], mf)["cap"])
			var qty := clampi(int(avg * 9.0) - int(p["inv"]) - pipe, moq, maxi(moq, cap * 3))
			ProductionEngine.place_order(c["id"], p["id"], qty, mf, {"maturation": 0, "chill": true})
	# grow owned capacity when demand outpaces it
	var f: Dictionary = c.get("factory", {})
	if f.get("built", false) and need > float(f["cap"]) * 0.85 and FinanceEngine.cash_of(c) > 5e6:
		var add := int(float(f["cap"]) * 0.5)
		FinanceEngine.capex(c, float(add) * 40.0)
		f["cap"] = int(f["cap"]) + add
		f["fixed"] = float(f["fixed"]) * 1.4


## Rivals do not simulate every salesperson and office clerk: a fixed share of revenue covers that overhead.
static func overhead(c: Dictionary) -> void:
	if c.get("is_player", false):
		return
	var rev := float(c["fin"]["wk"].get("revenue", 0.0))
	FinanceEngine.spend(c, "admin", rev * float(DB.bal["rivals"]["overhead"]) + float(DB.bal["rivals"]["fixed"]) * float(c["hq"]["tier"]))


static func weekly(c: Dictionary, r: RandomNumberGenerator, rep: Dictionary) -> void:
	if c.get("is_player", false) or not c.get("active", true):
		return
	var ai: Dictionary = c["ai"]
	production(c)
	var w := G.week()
	if (w + int(ai.get("offset", 0))) % 4 != 0:
		return
	var cash := FinanceEngine.cash_of(c)
	var rev4 := float(FinanceEngine.period(c, 4).get("revenue", 0.0)) / 4.0
	# financial discipline
	var disc := 1.0
	if cash < 0.0:
		disc = 0.3
	elif cash < rev4 * 4.0:
		disc = 0.6
	ai["disc"] = disc
	_marketing(c, rev4 * float(ai["mkt"]) * float(DB.bal["rivals"]["mkt_mult"]) * disc, r)
	_pricing(c, r)
	# owners take surplus cash out each quarter (keeps a war chest of ~half a year of revenue)
	if int((w + int(ai.get("offset", 0))) / 4) % 3 == 0:
		var keep := maxf(float(ai.get("cash0", 0.0)) * 0.5, rev4 * 26.0)
		if cash > keep * 1.2:
			FinanceEngine.dividend(c, (cash - keep) * float(DB.bal["rivals"].get("payout", 0.6)))
	_portfolio(c, r)
	if w >= int(ai.get("next_launch", 999)) and disc >= 0.6:
		_launch(c, r)
		ai["next_launch"] = w + int(r.randi_range(18, 46) * (1.4 - float(ai["risk"])))
	if w % 26 == int(ai.get("offset", 0)) and disc >= 1.0:
		_expand(c, r)
		_hire(c, r)
	_price_war_check(c, r)


static func _marketing(c: Dictionary, weekly: float, r: RandomNumberGenerator) -> void:
	var brands := G.company_brands(c["id"])
	if brands.is_empty():
		return
	var per := weekly / float(brands.size())
	for b in brands:
		b["budget"] = snappedf(per * 0.6, 100.0)
		var prods := G.company_products(c["id"]).filter(func(p): return p["brand"] == b["id"])
		if prods.is_empty():
			continue
		prods.sort_custom(func(a, b2): return avg_units(a) > avg_units(b2))
		var top: Dictionary = prods[0]
		var active := false
		for k in G.s["campaigns"]:
			if k["product"] == top["id"] and k["status"] == "active":
				active = true
		if active:
			continue
		var kinds: Dictionary = {"budget": ["social", "display"], "mass": ["social", "tv", "billboard"], "premium": ["social", "magazine", "billboard"],
			"luxury": ["magazine", "billboard", "social"], "niche": ["pr", "social", "magazine"]}
		var kind: String = G.pick(kinds.get(b["posit"], ["social"]), r)
		var t: Dictionary = DB.campaigns[kind]
		var budget := per * 0.4
		if budget < float(t["min"]):
			kind = "social"
			budget = maxf(500.0, budget)
		MarketingEngine.start(c["id"], kind, top["id"], b["id"], top["markets"], snappedf(budget, 100.0), 4)


static func _pricing(c: Dictionary, r: RandomNumberGenerator) -> void:
	for p in G.company_products(c["id"]):
		var wk: Array = p["wk"]
		if wk.size() < 4:
			continue
		var lost := 0.0
		var sold := 0.0
		for i in range(wk.size() - 4, wk.size()):
			sold += float(wk[i][1])
			lost += float(wk[i][4])
		var base := float(p.get("base_price", p["price"]))
		p["base_price"] = base
		var floor_p := maxf(float(p["unit_cost"]) * 2.2, base * 0.7)
		var cap := base * 1.2
		var np := float(p["price"])
		if lost > sold * 0.25:
			np *= 1.03
		elif float(p["inv"]) > maxf(1.0, sold / 4.0) * 18.0:
			np *= 0.95
		elif lost < sold * 0.02:
			np += (base - np) * 0.1
		var war: Dictionary = c["ai"].get("war", {})
		if war.has(p["id"]):
			if int(war[p["id"]]) < G.week():
				war.erase(p["id"])
			else:
				continue
		p["price"] = round(clampf(np, floor_p, cap))


static func _portfolio(c: Dictionary, r: RandomNumberGenerator) -> void:
	var prods := G.company_products(c["id"])
	var tot := 0.0
	for p in prods:
		tot += avg_units(p, 8)
	var mean := tot / maxf(1.0, float(prods.size()))
	for p in prods:
		var age := G.week() - int(p["launch_week"])
		if age < 52:
			continue
		var a := avg_units(p, 8)
		var seed := float(p.get("seed_avg", a))
		if a < maxf(60.0, mean * 0.12) or (a < seed * 0.25 and age > 104):
			_discontinue(c, p, r)
	# keep each brand's range focused
	var cap := int(DB.bal["rivals"]["max_per_brand"])
	for b in G.company_brands(c["id"]):
		var bp := G.company_products(c["id"]).filter(func(x): return x["brand"] == b["id"] and G.week() - int(x["launch_week"]) > 26)
		if bp.size() > cap:
			bp.sort_custom(func(x, y): return avg_units(x, 8) < avg_units(y, 8))
			for i in bp.size() - cap:
				_discontinue(c, bp[i], r)


static func _discontinue(c: Dictionary, p: Dictionary, r: RandomNumberGenerator) -> void:
	p["status"] = "discontinued"
	p["disc_week"] = G.week()
	CompanyEngine.plog(p, "Discontinued by %s." % c["name"])
	if r.randf() < 0.3:
		G.log_event("Industry: %s discontinued %s." % [c["name"], p["name"]], "info", "*")


static func _launch(c: Dictionary, r: RandomNumberGenerator) -> void:
	var brands := G.company_brands(c["id"])
	if brands.is_empty():
		return
	var b: Dictionary = G.pick(brands, r)
	var perfs := G.company_employees(c["id"], "perfumer")
	var perf: Dictionary = {}
	for e in perfs:
		if perf.is_empty() or Staff.perfumer_skill(e) > Staff.perfumer_skill(perf):
			perf = e
	var rv: Dictionary = {}
	for x in DB.rivals:
		if x["id"] == c["ai"].get("key", ""):
			rv = x
	var fams: Array = ["floral", "woody"]
	for bd in rv.get("brands", []):
		if bd["name"] == b["name"]:
			fams = bd["family"]
	# follow the home market trend
	var target := {fams[0]: 1.0, fams[r.randi_range(0, fams.size() - 1)]: 0.5}
	var tr := G.to_vec(G.s["markets"][c["home"]]["trend"])
	var best := 0
	for i in tr.size():
		if tr[i] > tr[best]:
			best = i
	target[DB.dims[best]] = float(target.get(DB.dims[best], 0.0)) + 0.4
	var markets: Array = b.get("markets", [c["home"]])
	var p := WorldGen.rival_product(c, b, fams, perf, DB.ing_order, r, markets, target)
	p["launch_budget"] = maxf(20000.0, float(FinanceEngine.period(c, 4).get("revenue", 0.0)) * 0.05)
	var mf := mfr_for(p)
	var moq := int(ProductionEngine.mfr_info(c["id"], mf)["moq"])
	ProductionEngine.place_order(c["id"], p["id"], maxi(moq, 6000), mf, {"maturation": 0, "chill": true})
	G.log_event("Industry: %s is preparing a new launch, %s." % [b["name"], p["name"]], "info", "*")


static func _expand(c: Dictionary, r: RandomNumberGenerator) -> void:
	var t := FinanceEngine.ttm(c)
	if float(t["net"]) <= 0.0:
		return
	var cands: Array = []
	for ct in DB.countries:
		if not c["offices"].has(ct["id"]) and FinanceEngine.cash_of(c) > float(ct["office_setup"]) * 6.0:
			cands.append(ct["id"])
	if cands.is_empty() or r.randf() > float(c["ai"]["risk"]):
		return
	var cid: String = G.pick(cands, r)
	var cap := int(DB.hq_tier(int(c["hq"]["tier"]))["offices"])
	if c["offices"].size() - 1 >= cap:
		return
	CompanyEngine.open_office(c, cid)
	for ch in ["marketplace", "beauty", "dept", "perfumery", "mass"]:
		var has := false
		for a in CompanyEngine.agreements(c["id"], cid):
			if a["ch"] == ch:
				has = true
		if not has:
			WorldGen._agree(c["id"], cid, ch, r)
	for b in G.company_brands(c["id"]):
		if not b["markets"].has(cid):
			b["markets"].append(cid)
		CompanyEngine.set_brand_aw(b, cid, maxf(CompanyEngine.brand_aw(b, cid), 0.03))
	for p in G.company_products(c["id"]):
		if not p["markets"].has(cid):
			p["markets"].append(cid)
	G.cache.erase("reach")
	G.log_event("Industry: %s expands into %s." % [c["name"], DB.country(cid)["name"]], "info", "*")


static func _hire(c: Dictionary, r: RandomNumberGenerator) -> void:
	if Staff.count(c["id"], "perfumer") >= 4:
		return
	for e in G.s["employees"].values():
		if e["role"] == "perfumer" and e.get("employer", "") == "" and e.get("status", "") == "free" and float(e["skill"]) > 0.5:
			Staff.transfer(e, c["id"], Staff.market_value(e), 3)
			return


## If the player's products take share from a rival's similar product, the rival may cut prices.
static func _price_war_check(c: Dictionary, r: RandomNumberGenerator) -> void:
	var cool: Dictionary = G.s["events"]["cool"]
	if int(cool.get("pricewar", -99)) > G.week():
		return
	var mine := G.company_products(G.pid())
	if mine.is_empty():
		return
	for p in G.company_products(c["id"]):
		var trend := avg_units(p, 4) / maxf(1.0, avg_units(p, 16))
		if trend > 0.75:
			continue
		var evp = MarketEngine.product_ev(p)
		for q in mine:
			var evq = MarketEngine.product_ev(q)
			if evp.is_empty() or evq.is_empty():
				continue
			if G.vcos(evp["profile"], evq["profile"]) > 0.9 and avg_units(q, 4) > avg_units(p, 4) * 0.4 and r.randf() < 0.35:
				p["price"] = round(float(p["price"]) * 0.85)
				c["ai"]["war"][p["id"]] = G.week() + 10
				cool["pricewar"] = G.week() + 20
				G.inbox_add({"type": "info", "title": "Price war: " + c["name"],
					"text": "%s cut the price of %s by 15%% after %s took share from it. Expect pressure on %s's sales for about 10 weeks." % [c["name"], p["name"], q["name"], q["name"]]})
				return


static func ranking() -> Array:
	var out: Array = []
	for c in G.s["companies"].values():
		if not c.get("active", true):
			continue
		var t := FinanceEngine.ttm(c)
		var units := 0
		for p in G.company_products(c["id"]):
			for wk in p["wk"].slice(maxi(0, p["wk"].size() - 52)):
				units += int(wk[1])
		var prest := 0.0
		for b in G.company_brands(c["id"]):
			prest = maxf(prest, float(b["prestige"]))
		out.append({"id": c["id"], "name": c["name"], "rev": float(t["revenue"]), "net": float(t["net"]), "units": units,
			"val": FinanceEngine.valuation(c), "prestige": prest, "products": G.company_products(c["id"]).size(), "player": c.get("is_player", false)})
	var tot_u := 0
	for x in out:
		tot_u += int(x["units"])
	for x in out:
		x["share"] = float(x["units"]) / maxf(1.0, float(tot_u))
	out.sort_custom(func(a, b): return float(a["rev"]) > float(b["rev"]))
	return out
