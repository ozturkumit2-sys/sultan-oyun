class_name Delegation
extends RefCounted
## Optional managerial delegation. Each function can be Manual, Approval-required or Delegated.
## Managers act with their real skill on real company data; strategic decisions always stay with the player.

const FUNCS := {
	"purchasing": {"name": "Raw material purchasing", "role": "production_manager", "desc": "Keeps 4 weeks of materials for active products; buys when prices are favorable."},
	"production": {"name": "Production scheduling", "role": "production_manager", "desc": "Reorders products before they run out, using a sales forecast."},
	"pricing": {"name": "Local pricing (±10%)", "role": "sales_manager", "desc": "Nudges prices within ±10% of your launch price in response to stockouts and slow sales."},
	"marketing": {"name": "Marketing execution", "role": "marketing_manager", "desc": "Spends the marketing budget you set on the best-performing products."},
	"distribution": {"name": "Distribution", "role": "sales_manager", "desc": "Signs eligible retail partners in markets where you have offices."},
	"recruitment": {"name": "Recruitment proposals", "role": "hr_manager", "desc": "Proposes hires for empty key roles (you approve)."},
}


static func mode(c: Dictionary, fn: String) -> String:
	return str(c.get("delegation", {}).get(fn, "manual"))


static func available(c: Dictionary, fn: String) -> String:
	var t := DB.hq_tier(int(c["hq"]["tier"]))
	if not t["delegation"].has(fn):
		return "Requires a larger headquarters."
	if Staff.best_skill(c["id"], FUNCS[fn]["role"]) <= 0.0:
		return "Requires a %s." % DB.role(FUNCS[fn]["role"])["name"]
	return ""


static func weekly(rep: Dictionary) -> void:
	var c := G.pc()
	if c.is_empty():
		return
	for fn in FUNCS:
		var m := mode(c, fn)
		if m == "manual" or available(c, fn) != "":
			continue
		var sk := Staff.best_skill(c["id"], FUNCS[fn]["role"])
		match fn:
			"production":
				_production(c, sk, m == "approval")
			"purchasing":
				_purchasing(c, sk, m == "approval")
			"pricing":
				if G.week() % 2 == 0:
					_pricing(c, sk)
			"marketing":
				if G.week() % 4 == 0:
					_marketing(c, sk)
			"distribution":
				if G.week() % 8 == 0:
					_distribution(c, sk)
			"recruitment":
				if G.week() % 6 == 0:
					_recruitment(c)


static func _production(c: Dictionary, sk: float, approval: bool) -> void:
	var mf: String = c.get("default_mfr", "meridian")
	if ProductionEngine.has_factory(c["id"]):
		mf = "own"
	for p in G.company_products(c["id"]):
		if p.get("edition", {}).get("type", "regular") == "limited":
			continue
		var avg := Rivals.avg_units(p, 4)
		if avg <= 0.0:
			continue
		var fc := avg * (1.0 + G.rng.randfn(0.0, 0.25 * (1.0 - sk)))
		var pipe := Rivals.pipeline(p["id"])
		var lead := 3 + int(p.get("maturation", 0))
		var cover := float(int(p["inv"]) + pipe) / maxf(1.0, fc)
		if cover >= float(lead) + 3.0:
			continue
		var moq := int(ProductionEngine.mfr_info(c["id"], mf)["moq"])
		var qty := maxi(moq, int(fc * (float(lead) + 7.0)) - int(p["inv"]) - pipe)
		if approval:
			if _pending("prod_" + p["id"]):
				continue
			G.inbox_add({"type": "deleg_prod", "key": "prod_" + p["id"], "product": p["id"], "qty": qty, "mfr": mf,
				"title": "Production proposal: " + p["name"], "text": "Your production manager proposes %s units at %s (stock covers %.1f weeks)." % [G.group_int(qty), ProductionEngine.mfr_info(c["id"], mf)["name"], cover]})
		else:
			var err := ProductionEngine.place_order(c["id"], p["id"], qty, mf, {"maturation": int(p.get("maturation", 0)), "chill": true})
			if err == "":
				G.log_event("Delegated: production manager ordered %s × %s." % [G.group_int(qty), p["name"]], "info")


static func _pending(key: String) -> bool:
	for m in G.inbox_open():
		if m.get("key", "") == key:
			return true
	return false


static func _purchasing(c: Dictionary, sk: float, approval: bool) -> void:
	var need := {}
	for p in G.company_products(c["id"]):
		var avg := Rivals.avg_units(p, 4)
		if avg <= 0.0:
			continue
		var mats := ProductionEngine.materials_needed(p, int(avg * 4.0))
		for id in mats:
			need[id] = float(need.get(id, 0.0)) + float(mats[id])
	for id in need:
		var have := FinanceEngine.raw_kg(c, id)
		if have >= float(need[id]) or ProductionEngine._in_transit(c["id"], id):
			continue
		var idx := float(G.s["ing_market"][id]["idx"])
		if idx > 1.08 - 0.1 * sk and have > float(need[id]) * 0.3:
			continue
		var kg := float(need[id]) - have
		if approval:
			if not _pending("buy_" + id):
				G.inbox_add({"type": "deleg_buy", "key": "buy_" + id, "ing": id, "kg": kg, "title": "Purchase proposal: " + DB.ing(id)["name"],
					"text": "Your production manager proposes buying %.1f kg of %s at %s/kg (index %.2f) to cover about 4 weeks of production." % [kg, DB.ing(id)["name"], G.money(G.ing_price(id)), idx]})
			continue
		if ProductionEngine.buy_material(c, id, kg) == "":
			G.log_event("Delegated: bought %.1f kg of %s." % [kg, DB.ing(id)["name"]], "info")


static func _pricing(c: Dictionary, sk: float) -> void:
	for p in G.company_products(c["id"]):
		var base := float(p.get("base_price", p["price"]))
		p["base_price"] = base
		var wk: Array = p["wk"]
		if wk.size() < 2:
			continue
		var last: Array = wk[wk.size() - 1]
		var np := float(p["price"])
		if int(last[4]) > int(last[1]) * 0.1:
			np *= 1.0 + 0.02 + 0.02 * sk
		elif float(p["inv"]) > maxf(1.0, float(last[1])) * 20.0:
			np *= 1.0 - 0.02 - 0.02 * sk
		np = clampf(np, base * 0.9, base * 1.1)
		if absf(np - float(p["price"])) >= 0.5:
			p["price"] = snappedf(np, 1.0)
			CompanyEngine.plog(p, "Delegated pricing: price set to %s." % G.money(np))


static func _marketing(c: Dictionary, sk: float) -> void:
	var pct := float(c.get("mkt_pct", 0.0))
	if pct <= 0.0:
		return
	var rev := float(FinanceEngine.period(c, 4).get("revenue", 0.0)) / 4.0
	var weekly := rev * pct
	if weekly < 500.0:
		return
	var prods := G.company_products(c["id"])
	prods.sort_custom(func(a, b): return float(a["st"]["gp"]) > float(b["st"]["gp"]))
	var n := mini(prods.size(), 2 + int(sk * 2.0))
	for i in n:
		var p: Dictionary = prods[i]
		var busy := false
		for k in G.s["campaigns"]:
			if k["product"] == p["id"] and k["status"] == "active":
				busy = true
		if busy:
			continue
		var kind := "social" if weekly / float(n) < 6000.0 else ("magazine" if G.brand(p["brand"]).get("posit", "") in ["luxury", "niche"] else "billboard")
		if MarketingEngine.start(c["id"], kind, p["id"], p["brand"], p["markets"], snappedf(maxf(500.0, weekly / float(n)), 100.0), 4) == "":
			G.log_event("Delegated: marketing manager started a campaign for %s." % p["name"], "info")


static func _distribution(c: Dictionary, sk: float) -> void:
	for country in c["offices"]:
		for b in G.company_brands(c["id"]):
			for ch in ["marketplace", "beauty", "perfumery", "dept", "mass"]:
				var has := false
				for a in CompanyEngine.agreements(c["id"], country):
					if a["ch"] == ch:
						has = true
				if has or CompanyEngine.channel_requirements(c["id"], country, ch, b) != "":
					continue
				var off := CompanyEngine.channel_offer(c["id"], country, ch)
				if FinanceEngine.cash_of(c) > float(off["fee"]) * 4.0:
					if CompanyEngine.sign_channel(c, country, ch, off) == "":
						G.log_event("Delegated: signed %s in %s." % [DB.channels[ch]["name"], DB.country(country)["name"]], "info")
						return


static func _recruitment(c: Dictionary) -> void:
	for rid in ["chemist", "marketing_manager", "sales_manager", "production_manager"]:
		if Staff.count(c["id"], rid) > 0:
			continue
		for eid in G.s["candidates"]:
			var e := G.employee(eid)
			if not e.is_empty() and e["role"] == rid and not _pending("hire_" + eid):
				G.inbox_add({"type": "deleg_hire", "key": "hire_" + eid, "emp": eid, "title": "Hiring proposal: " + DB.role(rid)["name"],
					"text": "Your HR manager recommends %s (skill %d, asks %s/year)." % [e["name"], int(float(e["skill"]) * 100), G.money(float(e["salary"]))]})
				return
