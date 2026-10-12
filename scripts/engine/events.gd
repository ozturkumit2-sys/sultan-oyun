class_name Events
extends RefCounted
## Causal business events with cooldowns: recalls from accumulated complaints, distribution failures,
## fictional regulatory changes, global scent trends and viral moments. Each needs a real trigger.

const TRENDS := [
	["Gourmand wave", {"gourmand": 0.12, "fruity": 0.05}],
	["Clean musk minimalism", {"musk": 0.12, "aquatic": 0.04, "gourmand": -0.05}],
	["Oud goes mainstream", {"animalic": 0.08, "amber": 0.08}],
	["Citrus revival", {"citrus": 0.12, "aromatic": 0.05}],
	["Green & botanical", {"green": 0.12, "floral": 0.03}],
	["Powdery nostalgia", {"powdery": 0.12, "floral": 0.04}],
	["Spice route", {"spicy": 0.1, "woody": 0.05}],
	["Woody-amber boom", {"woody": 0.08, "amber": 0.08}],
]


static func cool_ok(key: String) -> bool:
	return int(G.s["events"]["cool"].get(key, -999)) <= G.week()


static func set_cool(key: String, weeks: int) -> void:
	G.s["events"]["cool"][key] = G.week() + weeks


static func weekly(r: RandomNumberGenerator, rep: Dictionary) -> void:
	_recalls(rep)
	_distribution(r, rep)
	_regulation(r, rep)
	_global_trend(r)
	_viral(r, rep)
	_reg_deadlines()


static func _recalls(rep: Dictionary) -> void:
	for p in G.company_products(G.pid()):
		var comp := int(p.get("complaints", 0))
		var recent := 0
		for x in p["wk"].slice(maxi(0, p["wk"].size() - 8)):
			recent += int(x[1])
		if comp > maxi(25, int(recent * 0.04)) and cool_ok("recall_" + p["id"]):
			set_cool("recall_" + p["id"], 26)
			G.inbox_add({"type": "recall", "product": p["id"], "title": "Customer complaints: " + p["name"],
				"text": "%d customers complained about %s (%s). Recall the defective stock and refund customers, or continue selling and accept reputational risk?" % [comp, p["name"], ProductionEngine.defect_name(p.get("defect_kind", "fill"))]})
			rep["events"].append("Complaints about %s" % p["name"])


static func _distribution(r: RandomNumberGenerator, rep: Dictionary) -> void:
	for a in CompanyEngine.agreements(G.pid()):
		if a["ch"] == "dtc":
			continue
		var reliab := 0.0025 * (1.3 - float(a.get("q", 1.0)))
		if r.randf() < reliab and cool_ok("dist_" + a["id"]):
			set_cool("dist_" + a["id"], 40)
			var weeks := r.randi_range(3, 8)
			a["q_saved"] = a["q"]
			a["q"] = float(a["q"]) * 0.3
			a["recover"] = G.week() + weeks
			G.cache.erase("reach")
			G.inbox_add({"type": "info", "title": "Distribution disruption",
				"text": "%s (%s, %s) has a logistics breakdown. Your reach through them is reduced for about %d weeks." % [a["partner"], DB.channels[a["ch"]]["name"], DB.country(a["country"])["name"], weeks]})
			rep["events"].append("Distribution disruption at " + str(a["partner"]))
	for a in G.s["channels"]:
		if a.has("recover") and int(a["recover"]) <= G.week():
			a["q"] = float(a.get("q_saved", 1.0))
			a.erase("recover")
			G.cache.erase("reach")
		# renewals
		if a.get("active", true) and int(a.get("until", 9999)) <= G.week():
			if G.is_player(a["company"]):
				var c := G.company(a["company"])
				var fee := float(a.get("fee", 0.0)) * 0.5
				if FinanceEngine.cash_of(c) > fee and float(a.get("rev", 0.0)) > fee:
					FinanceEngine.spend(c, "distribution", fee)
					a["until"] = G.week() + 52
					G.log_event("Renewed agreement with %s (%s)." % [a["partner"], G.money(fee)], "info")
				else:
					a["active"] = false
					G.cache.erase("reach")
					G.log_event("Agreement with %s expired (not renewed: sales did not cover the renewal fee)." % a["partner"], "warn")
			else:
				a["until"] = G.week() + 52


static func _regulation(r: RandomNumberGenerator, rep: Dictionary) -> void:
	if G.week() < 60 or not cool_ok("regulation") or r.randf() > 0.012:
		return
	set_cool("regulation", 120)
	var cands: Array = []
	for id in DB.ing_order:
		var rec := DB.ing(id)
		if rec["role"] == "aromatic" and rec.get("reg", {}).get("allergen", false):
			cands.append(id)
	if cands.is_empty():
		return
	var id: String = G.pick(cands, r)
	var rec := DB.ing(id)
	var old: Variant = rec["reg"].get("max")
	var new_max := snappedf((float(old) * 0.6) if old != null else r.randf_range(0.8, 2.5), 0.05)
	G.s["regs"][id] = {"max": new_max, "deadline": G.week() + 26}
	apply_regs()
	var affected: Array = []
	for p in G.company_products(G.pid(), ["active", "dev"]):
		var ev := FormulaEngine.evaluate_product(p)
		for v in ev.get("violations", []):
			if v["id"] == id:
				affected.append(p["name"])
	G.inbox_add({"type": "regulation", "ing": id, "title": "New FSC rule: " + rec["name"],
		"text": "The (fictional) Fragrance Safety Council limits %s to %.2f%% of the finished product. %s Products above the limit cannot be produced; existing stock may be sold for 26 weeks." % [rec["name"], new_max,
		("Affected: " + ", ".join(affected) + ". Reformulate them.") if not affected.is_empty() else "None of your products are affected."]})
	rep["events"].append("Regulatory change: " + rec["name"])
	G.log_event("Regulation: %s restricted to %.2f%% (fictional FSC rule)." % [rec["name"], new_max], "warn", "*")


static func apply_regs() -> void:
	for id in G.s.get("regs", {}):
		var rec := DB.ing(id)
		if not rec.is_empty():
			rec["reg"]["max"] = float(G.s["regs"][id]["max"])
	G.cache.erase("eval")


static func _reg_deadlines() -> void:
	for id in G.s.get("regs", {}):
		var rg: Dictionary = G.s["regs"][id]
		if int(rg.get("deadline", -1)) == G.week():
			for p in G.s["products"].values():
				if p["status"] != "active":
					continue
				var ev := FormulaEngine.evaluate_product(p)
				for v in ev.get("violations", []):
					if v["id"] == id:
						var lost := int(p["inv"])
						var c := G.company(p["company"])
						FinanceEngine.pl(c, "writeoff", -float(lost) * float(p["unit_cost"]))
						p["inv"] = 0
						if G.is_player(p["company"]):
							G.log_event("%s: non-compliant stock (%d units) withdrawn after the FSC deadline." % [p["name"], lost], "bad")


static func _global_trend(r: RandomNumberGenerator) -> void:
	var ev: Dictionary = G.s["events"]
	if int(ev.get("trend_until", 0)) > G.week():
		return
	if ev.has("trend_name") and ev["trend_name"] != "":
		G.log_event("Trend fading: %s." % ev["trend_name"], "info", "*")
		ev["trend_name"] = ""
		ev["global_trend"] = []
		set_cool("gtrend", 20)
		return
	if not cool_ok("gtrend") or r.randf() > 0.03:
		return
	var t: Array = TRENDS[r.randi_range(0, TRENDS.size() - 1)]
	var v := PackedFloat32Array()
	v.resize(DB.dims.size())
	for k in t[1]:
		v[DB.dim_index(k)] = float(t[1][k])
	ev["global_trend"] = Array(v)
	ev["trend_name"] = t[0]
	ev["trend_until"] = G.week() + r.randi_range(26, 60)
	G.log_event("Trend: \"%s\" is sweeping the fragrance world." % t[0], "info", "*")


static func _viral(r: RandomNumberGenerator, rep: Dictionary) -> void:
	if not cool_ok("viral"):
		return
	for p in G.s["products"].values():
		if p["status"] != "active":
			continue
		var rt: Dictionary = p["rating"]
		if int(rt["n"]) < 10:
			continue
		var avg := float(rt["sum"]) / float(rt["n"])
		for cid in p["mk"]:
			var m: Dictionary = p["mk"][cid]
			var nov := float(p.get("mk_nov_" + cid, 0.3))
			var chance := 0.0015 * float(m["buzz"]) * 4.0 * (0.5 + nov) * maxf(0.0, avg - 3.4)
			if r.randf() < chance:
				m["buzz"] = clampf(float(m["buzz"]) + 0.55, 0.0, 1.0)
				m["aw"] = clampf(float(m["aw"]) + 0.04, 0.0, 0.95)
				set_cool("viral", 10)
				G.log_event("%s went viral on social media in %s!" % [p["name"], DB.country(cid)["name"]], "good" if G.is_player(p["company"]) else "info", "*")
				if G.is_player(p["company"]):
					rep["events"].append("%s went viral in %s" % [p["name"], DB.country(cid)["name"]])
				return
