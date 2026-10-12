class_name IngredientMarket
extends RefCounted
## Raw material prices and availability: mean-reverting fluctuation, harvest seasons for naturals,
## harvest/plant shortages with real consequences (price spikes, longer lead times, small-lot limits),
## supplier qualification and fixed-price supply contracts.


static func weekly(r: RandomNumberGenerator) -> void:
	var w := G.week()
	var month := G.month_of(w)
	for id in DB.ing_order:
		var rec := DB.ing(id)
		var m: Dictionary = G.s["ing_market"].get(id, {})
		if m.is_empty():
			continue
		var nat: bool = rec.get("nat", false)
		var idx := float(m["idx"])
		var sd := 0.018 if nat else 0.007
		var target := 1.0
		if nat and int(rec.get("harvest", 0)) > 0:
			var hm := int(rec["harvest"]) - 1
			var dist := absi(month - hm)
			dist = mini(dist, 12 - dist)
			target = 0.94 + 0.03 * float(dist)
		if int(m["short"]) > 0:
			m["short"] = int(m["short"]) - 1
			target = float(m.get("peak", 1.6))
			if int(m["short"]) == 0:
				m["avail"] = float(rec.get("avail", 0.95))
				G.log_event("Supply of %s is back to normal." % rec["name"], "info", "*")
		elif r.randf() < (0.0035 if nat else 0.0015) * (1.6 - float(rec.get("avail", 0.95))):
			var weeks := r.randi_range(4, 16)
			m["short"] = weeks
			m["peak"] = 1.0 + r.randf_range(0.3, 0.9)
			m["avail"] = r.randf_range(0.1, 0.4)
			var why := "harvest shortfall" if nat else "production outage at a major plant"
			G.log_event("Market: %s %s — prices rising, deliveries delayed (~%d weeks)." % [rec["name"], why, weeks], "warn", "*")
			_notify_users(id, why)
		idx += (target - idx) * 0.08 + r.randfn(0.0, sd)
		m["idx"] = snappedf(clampf(idx, 0.5, 3.5), 0.001)
		if w % 4 == 0:
			var h: Array = m.get("hist", [])
			h.append(m["idx"])
			while h.size() > 26:
				h.remove_at(0)
			m["hist"] = h
	_contracts()
	_qualify()


static func _notify_users(id: String, why: String) -> void:
	for p in G.company_products(G.pid(), ["active", "dev"]):
		var fv := G.formula_version(p["formula"], int(p["fv"]))
		for it in fv.get("items", []):
			if it[0] == id:
				G.inbox_add({"type": "shortage", "ing": id, "title": "Supply alert: " + DB.ing(id)["name"],
					"text": "%s (%s). %s uses it. Consider stocking up, a supply contract, or reformulating with a substitute." % [DB.ing(id)["name"], why, p["name"]]})
				return


static func qualify_cost(id: String) -> float:
	return float(DB.biz["supplier_tiers"][int(DB.ing(id).get("tier", 0))]["cost"])


static func qualify_req(c: Dictionary, id: String) -> String:
	var t := int(DB.ing(id).get("tier", 0))
	if t >= 2 and int(c["hq"]["tier"]) < t:
		return "Requires headquarters tier %d (premium supplier network)." % t
	return ""


static func start_qualify(c: Dictionary, id: String) -> String:
	if G.ing_available(c["id"], id):
		return "Already qualified."
	if c["qualifying"].has(id):
		return "Qualification in progress."
	var req := qualify_req(c, id)
	if req != "":
		return req
	var cost := qualify_cost(id)
	if FinanceEngine.cash_of(c) < cost:
		return "Requires %s." % G.money(cost)
	FinanceEngine.spend(c, "rnd", cost)
	c["qualifying"][id] = int(DB.biz["supplier_tiers"][int(DB.ing(id).get("tier", 0))]["lead"]) + 1
	return ""


static func _qualify() -> void:
	for c in G.s["companies"].values():
		var q: Dictionary = c.get("qualifying", {})
		for id in q.keys():
			q[id] = int(q[id]) - 1
			if int(q[id]) <= 0:
				q.erase(id)
				c["unlocked"][id] = true
				G.log_event("Supplier qualified: %s is now in your catalog." % DB.ing(id)["name"], "good", c["id"])


static func sign_contract(c: Dictionary, id: String, kg_week: float, weeks: int) -> String:
	if not G.ing_available(c["id"], id):
		return "Qualify a supplier first."
	var price := G.ing_price(id) * 1.04
	var m: Dictionary = G.s["ing_market"][id]
	if int(m["short"]) > 0:
		price *= 1.15
	G.s["contracts"].append({"id": G.new_id("sc"), "company": c["id"], "ing": id, "kg": kg_week, "price": snappedf(price, 0.01),
		"weeks_left": weeks, "weeks": weeks, "start": G.week()})
	G.log_event("Supply contract: %.1f kg/week of %s at %s/kg for %d weeks." % [kg_week, DB.ing(id)["name"], G.money(price), weeks], "info", c["id"])
	return ""


static func _contracts() -> void:
	var keep: Array = []
	for k in G.s["contracts"]:
		var c := G.company(k["company"])
		if c.is_empty():
			continue
		var cost := float(k["kg"]) * float(k["price"])
		FinanceEngine.buy_raw(c, k["ing"], float(k["kg"]), cost)
		k["weeks_left"] = int(k["weeks_left"]) - 1
		if int(k["weeks_left"]) > 0:
			keep.append(k)
		else:
			G.log_event("Supply contract for %s completed." % DB.ing(k["ing"])["name"], "info", k["company"])
	G.s["contracts"] = keep


## Ingredients with a similar odor role (for substitution suggestions).
static func alternatives(id: String, cid: String, n := 5) -> Array:
	var rec := DB.ing(id)
	var out: Array = []
	for oid in DB.ing_order:
		if oid == id:
			continue
		var o := DB.ing(oid)
		if o["role"] != "aromatic":
			continue
		var sim := G.vcos(rec["vec"], o["vec"])
		if sim < 0.6:
			continue
		out.append({"id": oid, "sim": sim, "price": G.ing_price(oid), "ok": G.ing_available(cid, oid)})
	out.sort_custom(func(a, b): return float(a["sim"]) > float(b["sim"]))
	return out.slice(0, n)
