class_name CompanyEngine
extends RefCounted
## Companies, brands, formulas, products, headquarters, offices and distribution reach.


static func make_company(id: String, name: String, home: String, is_player: bool, cash: float) -> Dictionary:
	var c := {
		"id": id, "name": name, "home": home, "is_player": is_player, "active": true, "acquired_by": "",
		"founded": G.week(), "color": "#c9a55a", "color2": "#1c1a20", "logo": 0,
		"fin": FinanceEngine.new_fin(cash), "raw": {}, "unlocked": {}, "qualifying": {},
		"hq": {"tier": 1, "build_to": 0, "weeks_left": 0}, "depts": {"lab": 1, "executive": 1},
		"offices": {home: {"level": 1, "since": G.week(), "manager": "", "hq": true}},
		"factory": {}, "delegation": {}, "reputation": 0.3, "shares": 10000000, "public": false,
		"holders": [{"name": "Founder (you)" if is_player else "Owners", "pct": 1.0, "kind": "founder"}],
		"stats": {"units": 0, "launches": 0}, "ai": {}, "market_share": {}, "integrating": 0,
	}
	return c


static func make_brand(cid: String, name: String, posit: String, color: String, prestige: float, logo := 0) -> Dictionary:
	var b := {"id": G.new_id("b"), "company": cid, "name": name, "posit": posit, "color": color, "logo": logo,
		"prestige": prestige, "aw": {}, "budget": 0.0, "created": G.week(), "status": "active", "independent": false,
		"rev": {}, "markets": [], "origin": cid}
	G.s["brands"][b["id"]] = b
	return b


static func make_formula(cid: String, name: String, items: Array, author: String, note := "Original") -> Dictionary:
	var f := {"id": G.new_id("f"), "company": cid, "name": name, "author": author, "created": G.week(),
		"versions": [{"v": 1, "items": items, "w": G.week(), "note": note}], "accord": false, "archived": false}
	G.s["formulas"][f["id"]] = f
	return f


static func add_version(fid: String, items: Array, note: String) -> int:
	var f := G.formula(fid)
	var vs: Array = f["versions"]
	vs.append({"v": vs.size() + 1, "items": items, "w": G.week(), "note": note})
	return vs.size() - 1


static func default_bottle(r: RandomNumberGenerator, color := "") -> Dictionary:
	return {"shape": r.randi_range(0, DB.biz["shapes"].size() - 1), "cap": r.randi_range(0, DB.biz["caps"].size() - 1),
		"glass": r.randi_range(0, DB.biz["glass"].size() - 1), "label": r.randi_range(0, DB.biz["labels"].size() - 1),
		"accent": color if color != "" else "#c9a55a"}


static func make_product(cid: String, spec: Dictionary) -> Dictionary:
	var p := {
		"id": G.new_id("p"), "company": cid, "brand": spec.get("brand", ""), "name": spec.get("name", "Untitled"),
		"formula": spec.get("formula", ""), "fv": int(spec.get("fv", 0)), "kind": spec.get("kind", "full"),
		"parent": spec.get("parent", ""), "fmt": spec.get("fmt", "edp"), "conc": float(spec.get("conc", 18.0)),
		"volume": float(spec.get("volume", 50.0)), "maturation": int(spec.get("maturation", 0)),
		"bottle": spec.get("bottle", {"shape": 0, "cap": 0, "glass": 0, "label": 0, "accent": "#c9a55a"}),
		"pack": spec.get("pack", "standard"), "audience": spec.get("audience", "any"), "price": float(spec.get("price", 60.0)),
		"markets": spec.get("markets", []), "status": "dev", "created": G.week(), "launch_week": -1, "disc_week": -1,
		"inv": 0, "unit_cost": 0.0, "defect": 0.0, "defect_kind": "",
		"edition": spec.get("edition", {"type": "regular"}), "perfumer": spec.get("perfumer", "ceo"), "set": spec.get("set", []),
		"st": {"units": 0, "rev": 0.0, "gp": 0.0, "lost": 0, "returns": 0, "cm": 0.0},
		"wk": [], "yr": {}, "mk": {}, "rating": {"n": 0, "sum": 0.0, "d": [0, 0, 0, 0, 0]}, "reviews": [], "critics": [],
		"log": [], "tags": [], "awards": [], "versions": [[int(spec.get("fv", 0)), G.week()]], "campaigns": [],
		"launch_budget": float(spec.get("launch_budget", 0.0)), "peak_week_units": 0, "auto_reorder": false,
	}
	G.s["products"][p["id"]] = p
	plog(p, "Product created.")
	return p


static func plog(p: Dictionary, text: String) -> void:
	var lg: Array = p["log"]
	lg.append([G.week(), text])
	if lg.size() > 60:
		lg.remove_at(0)


static func pack_cost(pack_id: String, volume: float) -> float:
	var base := float(DB.packaging.get(pack_id, DB.packaging["standard"])["cost50"])
	return base * pow(maxf(2.0, volume) / 50.0, 0.55)


static func juice_ml_cost(p: Dictionary) -> float:
	if p.get("kind", "") == "discovery":
		var t := 0.0
		var set_ids: Array = p.get("set", [])
		for fid in set_ids:
			var fv := G.formula_version(fid)
			t += FormulaEngine.juice_cost_ml(fv["items"], p["fmt"], float(p["conc"]))
		return t / maxf(1.0, float(set_ids.size()))
	var fv2 := G.formula_version(p["formula"], int(p["fv"]))
	if fv2.is_empty():
		return 0.0
	return FormulaEngine.juice_cost_ml(fv2["items"], p["fmt"], float(p["conc"]))


static func cost_breakdown(p: Dictionary, mfr_id := "meridian") -> Dictionary:
	var vol := float(p["volume"])
	var juice := juice_ml_cost(p) * vol
	if p.get("kind", "") == "discovery":
		juice = juice_ml_cost(p) * vol * float(p.get("set", []).size())
	var pack := pack_cost(p["pack"], vol)
	if p.get("kind", "") == "discovery":
		pack = pack_cost(p["pack"], 30.0) + 0.6 * float(p.get("set", []).size())
	var mf: Dictionary = DB.manufacturers.get(mfr_id, DB.manufacturers["meridian"])
	var fill := float(mf["fill"]) * (0.5 + 0.5 * pow(vol / 50.0, 0.3))
	return {"juice": juice, "pack": pack, "fill": fill, "total": juice + pack + fill}


static func net_price(p: Dictionary, country: String) -> float:
	return float(p["price"]) / (1.0 + float(DB.country(country).get("vat", 0.2)))


# ---------------------------------------------------------------- offices & reach
static func has_office(cid: String, country: String) -> bool:
	return G.company(cid).get("offices", {}).has(country)


static func office_level(cid: String, country: String) -> int:
	var o: Dictionary = G.company(cid).get("offices", {}).get(country, {})
	return int(o.get("level", 0))


static func agreements(cid: String, country := "") -> Array:
	var out: Array = []
	for a in G.s["channels"]:
		if a["company"] == cid and a.get("active", true) and (country == "" or a["country"] == country):
			out.append(a)
	return out


static func sells_in(cid: String, country: String) -> bool:
	return true   # own online store ships everywhere (cross-border without an office)


## Reach of a company's distribution for each consumer segment in a country, for a brand positioning.
static func reach(cid: String, country: String, posit: String) -> PackedFloat32Array:
	var key := "%s|%s|%s" % [cid, country, posit]
	var rc: Dictionary = G.cache.get("reach", {})
	if rc.has(key):
		return rc[key]
	var ns := DB.segments.size()
	var miss := PackedFloat32Array()
	miss.resize(ns)
	miss.fill(1.0)
	var office := office_level(cid, country)
	var ol: Array = DB.biz["office_levels"]
	var obonus := float(ol[clampi(office - 1, 0, 2)]["reach_bonus"]) if office > 0 else 0.0
	var cm := 0.0
	var o: Dictionary = G.company(cid).get("offices", {}).get(country, {})
	if o.get("manager", "") != "":
		var e := G.employee(o["manager"])
		if not e.is_empty():
			cm = Staff.eff(e)
	var dtc_q := 1.0 if office > 0 else 0.55
	var D: Dictionary = DB.bal["market"]
	for i in ns:
		var sg: Dictionary = DB.segments[i]
		var ch: Dictionary = sg["ch"]
		var r_dtc := dtc_q * (float(D["dtc_base"]) + float(D["dtc_online"]) * float(ch.get("online", 0.0)))
		miss[i] *= 1.0 - clampf(r_dtc, 0.0, 0.95)
	for a in agreements(cid, country):
		var chd: Dictionary = DB.channels.get(a["ch"], {})
		var ok_pos: Array = chd.get("posit", [])
		if not ok_pos.is_empty() and not ok_pos.has(posit):
			continue
		var q := float(a.get("q", 1.0)) * (1.0 + obonus + 0.15 * cm)
		for i in ns:
			var ch2: Dictionary = DB.segments[i]["ch"]
			var rr := 0.0
			if a["ch"] == "distributor":
				var mx := maxf(float(ch2.get("beauty", 0.0)), maxf(float(ch2.get("perf", 0.0)), float(ch2.get("mass", 0.0))))
				rr = float(chd["reach"]) * q * mx
			else:
				rr = float(chd["reach"]) * q * float(ch2.get(chd["pref"], 0.0))
			miss[i] *= 1.0 - clampf(rr, 0.0, 0.95)
	var out := PackedFloat32Array()
	out.resize(ns)
	for i in ns:
		out[i] = 1.0 - miss[i]
	rc[key] = out
	G.cache["reach"] = rc
	return out


## Units sold in a market are split across channels in proportion to their reach contribution.
static func channel_weights(cid: String, country: String, posit: String) -> Array:
	var segw: Dictionary = DB.country(country)["seg"]
	var D: Dictionary = DB.bal["market"]
	var office := office_level(cid, country)
	var dtc_q := 1.0 if office > 0 else 0.55
	var out: Array = []
	var w_dtc := 0.0
	for sg in DB.segments:
		w_dtc += float(segw.get(sg["id"], 0.0)) * dtc_q * (float(D["dtc_base"]) + float(D["dtc_online"]) * float(sg["ch"].get("online", 0.0)))
	out.append({"ch": "dtc", "w": w_dtc, "margin": 0.0, "a": ""})
	for a in agreements(cid, country):
		var chd: Dictionary = DB.channels.get(a["ch"], {})
		var ok_pos: Array = chd.get("posit", [])
		if not ok_pos.is_empty() and not ok_pos.has(posit):
			continue
		var wv := 0.0
		for sg in DB.segments:
			var chs: Dictionary = sg["ch"]
			var pr := 0.0
			if a["ch"] == "distributor":
				pr = maxf(float(chs.get("beauty", 0.0)), maxf(float(chs.get("perf", 0.0)), float(chs.get("mass", 0.0))))
			else:
				pr = float(chs.get(chd["pref"], 0.0))
			wv += float(segw.get(sg["id"], 0.0)) * float(chd["reach"]) * float(a.get("q", 1.0)) * pr
		out.append({"ch": a["ch"], "w": wv, "margin": float(a["margin"]), "a": a["id"]})
	var tot := 0.0
	for x in out:
		tot += float(x["w"])
	for x in out:
		x["w"] = float(x["w"]) / maxf(0.0001, tot)
	return out


static func brand_aw(b: Dictionary, country: String) -> float:
	return float(b.get("aw", {}).get(country, 0.0))


static func set_brand_aw(b: Dictionary, country: String, v: float) -> void:
	b["aw"][country] = clampf(v, 0.0, 0.95)


static func mk(p: Dictionary, country: String) -> Dictionary:
	var m: Dictionary = p["mk"]
	if not m.has(country):
		m[country] = {"aw": 0.0, "buzz": 0.0, "loyal": 0.0, "triers": 0.0, "sat": 0.5, "u": 0, "carry": 0.0, "conv": 0.0, "last": 0, "lost": 0}
	return m[country]


# ---------------------------------------------------------------- headquarters
static func hq_upgrade(c: Dictionary) -> String:
	var t := int(c["hq"]["tier"])
	if t >= 4:
		return "Already at the highest tier."
	if int(c["hq"].get("weeks_left", 0)) > 0:
		return "Construction already in progress."
	var nx := DB.hq_tier(t + 1)
	var cost := float(nx["cost"])
	if FinanceEngine.cash_of(c) < cost:
		return "Requires %s." % G.money(cost)
	FinanceEngine.capex(c, cost)
	c["hq"]["build_to"] = t + 1
	c["hq"]["weeks_left"] = int(nx["weeks"])
	c["hq"]["capex_" + str(t + 1)] = cost
	G.log_event("Construction of %s started (%d weeks)." % [nx["name"], int(nx["weeks"])], "info", c["id"])
	return ""


static func dept_upgrade(c: Dictionary, dept: String) -> String:
	var lvl := int(c["depts"].get(dept, 0))
	var d: Dictionary = DB.biz["departments"][dept]
	var ups: Array = d["upgrades"]
	if not DB.hq_tier(int(c["hq"]["tier"]))["depts"].has(dept):
		return "Your headquarters has no space for this department yet."
	if lvl >= ups.size():
		return "Fully upgraded."
	var cost := float(ups[lvl]) if lvl > 0 else 0.0
	if lvl == 0:
		c["depts"][dept] = 1
		return ""
	if FinanceEngine.cash_of(c) < cost:
		return "Requires %s." % G.money(cost)
	FinanceEngine.capex(c, cost)
	c["depts"][dept] = lvl + 1
	G.log_event("%s upgraded to level %d." % [d["name"], lvl + 1], "good", c["id"])
	return ""


static func dept_level(cid: String, dept: String) -> int:
	return int(G.company(cid).get("depts", {}).get(dept, 0))


static func open_office(c: Dictionary, country: String) -> String:
	if c["offices"].has(country):
		return "Office already open."
	var foreign = c["offices"].size() - 1
	var cap := int(DB.hq_tier(int(c["hq"]["tier"]))["offices"])
	if foreign >= cap:
		return "Your headquarters can coordinate %d foreign offices. Upgrade to expand." % cap
	var ct := DB.country(country)
	var cost := float(ct["office_setup"])
	if FinanceEngine.cash_of(c) < cost:
		return "Requires %s." % G.money(cost)
	FinanceEngine.capex(c, cost * 0.7)
	FinanceEngine.spend(c, "facilities", cost * 0.3)
	c["offices"][country] = {"level": 1, "since": G.week(), "manager": "", "hq": false}
	G.cache.erase("reach")
	G.log_event("Opened a sales office in %s." % ct["name"], "good", c["id"])
	return ""


static func upgrade_office(c: Dictionary, country: String) -> String:
	var o: Dictionary = c["offices"].get(country, {})
	if o.is_empty():
		return "No office."
	var lvl := int(o["level"])
	if lvl >= 3:
		return "Already a country headquarters."
	var ct := DB.country(country)
	var cost := float(ct["office_setup"]) * float(DB.biz["office_levels"][lvl]["upgrade"])
	if FinanceEngine.cash_of(c) < cost:
		return "Requires %s." % G.money(cost)
	FinanceEngine.capex(c, cost)
	o["level"] = lvl + 1
	G.cache.erase("reach")
	G.log_event("%s office upgraded to %s." % [ct["name"], DB.biz["office_levels"][lvl]["name"]], "good", c["id"])
	return ""


static func close_office(c: Dictionary, country: String) -> String:
	var o: Dictionary = c["offices"].get(country, {})
	if o.is_empty() or o.get("hq", false):
		return "Cannot close headquarters."
	var ct := DB.country(country)
	var sev := float(ct["office_week"]) * 8.0
	FinanceEngine.spend(c, "facilities", sev)
	c["offices"].erase(country)
	for a in agreements(c["id"], country):
		var chd: Dictionary = DB.channels[a["ch"]]
		if chd.get("needs_office", false):
			a["active"] = false
	if o.get("manager", "") != "":
		var e := G.employee(o["manager"])
		if not e.is_empty():
			e["country"] = ""
	G.cache.erase("reach")
	G.log_event("Closed the %s office (restructuring cost %s)." % [ct["name"], G.money(sev)], "warn", c["id"])
	return ""


static func office_weekly(c: Dictionary) -> float:
	var t := 0.0
	for k in c["offices"]:
		var o: Dictionary = c["offices"][k]
		if o.get("hq", false):
			continue
		var lvl := int(o["level"])
		t += float(DB.country(k)["office_week"]) * float(DB.biz["office_levels"][lvl - 1]["mult"])
	return t


static func hq_weekly(c: Dictionary) -> float:
	return float(DB.hq_tier(int(c["hq"]["tier"]))["upkeep"])


# ---------------------------------------------------------------- distribution agreements
static func channel_offer(cid: String, country: String, ch: String) -> Dictionary:
	var chd: Dictionary = DB.channels[ch]
	var r := G.drng("offer|%s|%s|%s|%d" % [cid, country, ch, int(G.week() / 13)])
	var partners: Array = DB.names["partners"].get(ch, ["Partner"])
	var sm := Staff.best_skill(cid, "sales_manager")
	var q := clampf(0.85 + r.randf() * 0.25 + 0.1 * sm, 0.7, 1.3)
	var margin := clampf(float(chd["margin"]) - 0.04 * sm + r.randf_range(-0.02, 0.03), 0.0, 0.7)
	var fee := float(chd["listing"]) * (0.6 + 0.4 * float(DB.country(country)["opcost"])) * (1.0 - 0.2 * sm)
	return {"partner": G.pick(partners, r), "q": snappedf(q, 0.01), "margin": snappedf(margin, 0.005), "fee": snappedf(fee, 100.0)}


static func channel_requirements(cid: String, country: String, ch: String, b: Dictionary) -> String:
	var chd: Dictionary = DB.channels[ch]
	if chd.get("needs_office", false) and not has_office(cid, country):
		return "Requires an office in %s." % DB.country(country)["name"]
	if float(b.get("prestige", 0.0)) < float(chd["min_prestige"]):
		return "Brand prestige too low (needs %d)." % int(float(chd["min_prestige"]) * 100)
	if brand_aw(b, country) < float(chd["min_aw"]):
		return "Brand awareness in this market too low (needs %s)." % G.pct(float(chd["min_aw"]), 0)
	var pos: Array = chd.get("posit", [])
	if not pos.is_empty() and not pos.has(b["posit"]):
		return "Does not carry %s brands." % DB.positionings[b["posit"]]["name"]
	return ""


static func sign_channel(c: Dictionary, country: String, ch: String, offer: Dictionary) -> String:
	for a in agreements(c["id"], country):
		if a["ch"] == ch:
			return "Already have this channel here."
	if FinanceEngine.cash_of(c) < float(offer["fee"]):
		return "Listing fee %s exceeds cash." % G.money(float(offer["fee"]))
	FinanceEngine.spend(c, "distribution", float(offer["fee"]))
	G.s["channels"].append({"id": G.new_id("a"), "company": c["id"], "country": country, "ch": ch, "partner": offer["partner"],
		"q": float(offer["q"]), "margin": float(offer["margin"]), "fee": float(offer["fee"]), "since": G.week(),
		"until": G.week() + 52, "active": true, "units": 0, "rev": 0.0})
	G.cache.erase("reach")
	G.log_event("Signed with %s (%s) in %s." % [offer["partner"], DB.channels[ch]["name"], DB.country(country)["name"]], "good", c["id"])
	return ""


static func end_channel(a: Dictionary) -> void:
	a["active"] = false
	G.cache.erase("reach")
