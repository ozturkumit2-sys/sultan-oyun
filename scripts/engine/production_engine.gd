class_name ProductionEngine
extends RefCounted
## Raw materials, production orders (materials → compounding → maturation → filtration & filling → QC),
## defects derived from formula/process attributes, rework, rejection, recalls and owned factories.

const GLASS_VIS := [0.9, 0.7, 0.3, 0.6, 0.4, 0.3, 0.35, 0.05, 0.5, 0.55]


static func concentrate_kg(p: Dictionary, qty: int) -> float:
	var vol := float(p["volume"])
	if p.get("kind", "") == "discovery":
		vol *= float(p.get("set", []).size())
	return float(qty) * vol * float(p["conc"]) / 100.0 / 1000.0


static func materials_needed(p: Dictionary, qty: int) -> Dictionary:
	var out := {}
	var kg := concentrate_kg(p, qty)
	var forms: Array = []
	if p.get("kind", "") == "discovery":
		for fid in p.get("set", []):
			forms.append(G.formula_version(fid))
		kg /= maxf(1.0, float(forms.size()))
	else:
		forms.append(G.formula_version(p["formula"], int(p["fv"])))
	for fv in forms:
		if fv.is_empty():
			continue
		for it in fv["items"]:
			out[it[0]] = float(out.get(it[0], 0.0)) + kg * float(it[1]) / 100.0
	# diluent for the finished product
	var dil := "jojoba" if DB.formats[p["fmt"]]["base"] == "oil" else "ethanol"
	var vol_total := float(qty) * float(p["volume"]) * (float(p.get("set", []).size()) if p.get("kind", "") == "discovery" else 1.0) / 1000.0
	out[dil] = float(out.get(dil, 0.0)) + vol_total * (1.0 - float(p["conc"]) / 100.0)
	return out


## Per-company index of materials reserved by waiting orders and materials in transit (rebuilt lazily).
static func _idx(cid: String) -> Dictionary:
	var all: Dictionary = G.cache.get("prod_idx", {})
	if all.has(cid):
		return all[cid]
	var res := {}
	var tr := {}
	for o in G.s["orders"]:
		if o["company"] == cid and o["stage"] == "materials":
			var nd: Dictionary = o.get("need", {})
			for k in nd:
				res[k] = float(res.get(k, 0.0)) + float(nd[k])
	for d in G.s["deliveries"]:
		if d["company"] == cid:
			tr[d["ing"]] = float(tr.get(d["ing"], 0.0)) + float(d["kg"])
	var ix := {"res": res, "tr": tr}
	all[cid] = ix
	G.cache["prod_idx"] = all
	return ix


static func _idx_reset() -> void:
	G.cache.erase("prod_idx")


## Materials already committed to orders that have not started compounding.
static func reserved(cid: String, ing_id: String) -> float:
	return float(_idx(cid)["res"].get(ing_id, 0.0))


static func free_kg(c: Dictionary, ing_id: String) -> float:
	return maxf(0.0, FinanceEngine.raw_kg(c, ing_id) + _transit_kg(c["id"], ing_id) - reserved(c["id"], ing_id))


static func _transit_kg(cid: String, ing_id: String) -> float:
	return float(_idx(cid)["tr"].get(ing_id, 0.0))


static func mfr_info(cid: String, mfr_id: String) -> Dictionary:
	if mfr_id == "own":
		var c := G.company(cid)
		var f: Dictionary = c.get("factory", {})
		var fd: Dictionary = DB.biz["factory"]
		var pm := Staff.best_skill(cid, "production_manager")
		return {"id": "own", "name": "Own factory", "fill": float(fd["fill"]), "setup": 300.0, "moq": 100,
			"cap": int(f.get("cap", 0)), "lead": 1, "rel": minf(0.995, float(fd["rel"]) + 0.02 * pm), "qc": float(fd["qc"])}
	return DB.manufacturers.get(mfr_id, DB.manufacturers["meridian"])


static func has_factory(cid: String) -> bool:
	var f: Dictionary = G.company(cid).get("factory", {})
	return f.get("built", false)


static func load_on(cid: String, mfr_id: String) -> int:
	var n := 0
	for o in G.s["orders"]:
		if o["company"] == cid and o["mfr"] == mfr_id and o["stage"] in ["materials", "compounding", "maturing", "filling"]:
			n += int(o["qty"])
	return n


static func quote(cid: String, p: Dictionary, qty: int, mfr_id: String, opts: Dictionary) -> Dictionary:
	var c := G.company(cid)
	var mf := mfr_info(cid, mfr_id)
	var need := materials_needed(p, qty)
	var buy_cost := 0.0
	var wait := 0
	var short: Array = []
	for id in need:
		var have := free_kg(c, id)
		var miss := float(need[id]) - have
		if miss > 0.0001:
			if not G.ing_available(cid, id):
				short.append(DB.ing(id).get("name", id))
				continue
			var pr := G.ing_price(id) * (1.15 if miss < 2.0 else 1.0)
			buy_cost += miss * pr
			wait = maxi(wait, lead_weeks(id))
	var vol := float(p["volume"])
	var pack := CompanyEngine.pack_cost(p["pack"], vol)
	if p.get("kind", "") == "discovery":
		pack = CompanyEngine.pack_cost(p["pack"], 30.0) + 0.6 * float(p.get("set", []).size())
	var fill := float(mf["fill"]) * (0.5 + 0.5 * pow(vol / 50.0, 0.3))
	var chill := 0.04 if opts.get("chill", true) else 0.0
	var conv := float(qty) * (pack + fill + chill) + float(mf["setup"])
	var load := load_on(cid, mfr_id)
	var cap := maxi(1, int(mf["cap"]))
	var fill_weeks := int(mf["lead"]) + int(float(qty + load) / float(cap))
	var mat_value := 0.0
	for id in need:
		var cur: Array = c["raw"].get(id, [0.0, 0.0])
		mat_value += minf(float(cur[0]), float(need[id])) * float(cur[1])
	return {"need": need, "buy_cost": buy_cost, "wait": wait, "short": short, "conv": conv, "fill_weeks": fill_weeks,
		"weeks": wait + 1 + int(opts.get("maturation", 0)) + fill_weeks,
		"unit_est": (buy_cost + mat_value + conv) / maxf(1.0, float(qty)), "total_cash": buy_cost + conv, "moq": int(mf["moq"])}


static func lead_weeks(ing_id: String) -> int:
	var rec := DB.ing(ing_id)
	var t := int(rec.get("tier", 0))
	var base := int(DB.biz["supplier_tiers"][t]["lead"])
	var m: Dictionary = G.s["ing_market"].get(ing_id, {})
	return base + (2 if int(m.get("short", 0)) > 0 else 0)


## Spot-purchase raw material. Delivery after lead time. Returns "" or error.
static func buy_material(c: Dictionary, ing_id: String, kg: float, reserve_for := "") -> String:
	if kg <= 0.0:
		return "Invalid quantity."
	if not G.ing_available(c["id"], ing_id):
		return "Supplier not qualified for this material."
	var m: Dictionary = G.s["ing_market"].get(ing_id, {})
	var avail := float(m.get("avail", 1.0))
	var price := G.ing_price(ing_id) * (1.15 if kg < 2.0 else 1.0)
	if int(m.get("short", 0)) > 0 and kg > 5.0:
		# scarce material: large lots carry an allocation premium
		price *= 1.0 + 0.5 * (1.0 - avail)
	var cost := price * kg
	if FinanceEngine.cash_of(c) < cost and G.is_player(c["id"]):
		return "Not enough cash (%s)." % G.money(cost)
	FinanceEngine.cash(c, -cost)
	G.s["deliveries"].append({"id": G.new_id("d"), "company": c["id"], "ing": ing_id, "kg": kg, "value": cost,
		"weeks": lead_weeks(ing_id), "for": reserve_for})
	var ix := _idx(c["id"])
	ix["tr"][ing_id] = float(ix["tr"].get(ing_id, 0.0)) + kg
	return ""


static func transit_value(cid: String) -> float:
	var t := 0.0
	for d in G.s["deliveries"]:
		if d["company"] == cid:
			t += float(d["value"])
	return t


## Places a production order. Missing materials are purchased at spot price when auto_buy is set.
static func place_order(cid: String, pid: String, qty: int, mfr_id: String, opts: Dictionary) -> String:
	var c := G.company(cid)
	var p := G.product(pid)
	if p.is_empty():
		return "Unknown product."
	if p["status"] == "discontinued":
		return "Product is discontinued."
	var ev = MarketEngine.product_ev(p)
	if ev.is_empty():
		return "Formula missing."
	if not ev.get("violations", []).is_empty():
		return "Formula violates the (fictional) FSC safety standard. Reformulate first."
	if not ev.get("errors", []).is_empty():
		return str(ev["errors"][0])
	var ed: Dictionary = p.get("edition", {})
	if ed.get("type", "") == "limited":
		var left := int(ed.get("limit", 0)) - int(ed.get("made", 0))
		if left <= 0:
			return "Limited edition run is complete."
		qty = mini(qty, left)
	var mf := mfr_info(cid, mfr_id)
	if mfr_id == "own" and not has_factory(cid):
		return "You do not own a factory yet."
	if qty < int(mf["moq"]):
		return "%s requires at least %d units." % [mf["name"], int(mf["moq"])]
	var q := quote(cid, p, qty, mfr_id, opts)
	if not q["short"].is_empty():
		return "Missing supplier access for: " + ", ".join(q["short"])
	if G.is_player(cid) and FinanceEngine.cash_of(c) < float(q["total_cash"]):
		return "Not enough cash: needs %s." % G.money(float(q["total_cash"]))
	var oid := G.new_id("o")
	var need: Dictionary = q["need"]
	if float(q["buy_cost"]) > 0.0:
		for id in need:
			var miss := float(need[id]) - free_kg(c, id)
			if miss > 0.0001:
				var err := buy_material(c, id, miss * 1.0005, oid)
				if err != "" and G.is_player(cid):
					return err
	# conversion costs (packaging, filling, setup) are paid now and capitalized into the batch
	var conv := float(q["conv"])
	FinanceEngine.cash(c, -conv)
	var o := {"id": oid, "company": cid, "product": pid, "qty": qty, "mfr": mfr_id, "stage": "materials",
		"wait": int(q["wait"]), "mat_left": int(opts.get("maturation", p.get("maturation", 0))), "fill_left": int(q["fill_weeks"]),
		"value": conv, "chill": bool(opts.get("chill", true)), "created": G.week(), "defects": {}, "detected": {}, "rework": 0, "need": need}
	G.s["orders"].append(o)
	var ix2 := _idx(cid)
	for k in need:
		ix2["res"][k] = float(ix2["res"].get(k, 0.0)) + float(need[k])
	p["maturation"] = int(o["mat_left"])
	if ed.get("type", "") == "limited":
		ed["made"] = int(ed.get("made", 0)) + qty
	if G.is_player(cid):
		CompanyEngine.plog(p, "Production order: %s units at %s." % [G.group_int(qty), mf["name"]])
	return ""


static func weekly(rep: Dictionary) -> void:
	_idx_reset()
	# deliveries
	var keep: Array = []
	for d in G.s["deliveries"]:
		d["weeks"] = int(d["weeks"]) - 1
		if int(d["weeks"]) <= 0:
			var c := G.company(d["company"])
			if c.is_empty():
				continue
			FinanceEngine.add_raw(c, d["ing"], float(d["kg"]), float(d["value"]))
		else:
			keep.append(d)
	G.s["deliveries"] = keep
	# orders
	var still: Array = []
	for o in G.s["orders"]:
		_advance(o, rep)
		if o["stage"] != "done":
			still.append(o)
	G.s["orders"] = still
	_idx_reset()


static func _advance(o: Dictionary, rep: Dictionary) -> void:
	var c := G.company(o["company"])
	var p := G.product(o["product"])
	if c.is_empty() or p.is_empty():
		o["stage"] = "done"
		return
	match o["stage"]:
		"materials":
			if int(o["wait"]) > 0:
				o["wait"] = int(o["wait"]) - 1
				if int(o["wait"]) > 0:
					return
			var need := materials_needed(p, int(o["qty"]))
			for id in need:
				if FinanceEngine.raw_kg(c, id) + 0.0005 < float(need[id]):
					if _in_transit(o["company"], id):
						return
					if G.is_player(o["company"]):
						var miss := float(need[id]) - FinanceEngine.raw_kg(c, id)
						if buy_material(c, id, miss * 1.0005, o["id"]) != "":
							o["blocked"] = DB.ing(id).get("name", id)
							return
						return
					buy_material(c, id, (float(need[id]) - FinanceEngine.raw_kg(c, id)) * 1.0005, o["id"])
					return
			o.erase("blocked")
			for id in need:
				o["value"] = float(o["value"]) + FinanceEngine.take_raw(c, id, float(need[id]))
			o["stage"] = "compounding"
		"compounding":
			o["stage"] = "maturing" if int(o["mat_left"]) > 0 else "filling"
		"maturing":
			o["mat_left"] = int(o["mat_left"]) - 1
			if int(o["mat_left"]) <= 0:
				o["stage"] = "filling"
		"filling", "rework":
			o["fill_left"] = int(o["fill_left"]) - 1
			if int(o["fill_left"]) <= 0:
				_qc(o, c, p, rep)
		"qc_hold":
			o["hold"] = int(o.get("hold", 0)) + 1
			if not G.is_player(o["company"]) or int(o["hold"]) > 8:
				release(o, true)


static func _in_transit(cid: String, ing_id: String) -> bool:
	return _transit_kg(cid, ing_id) > 0.0


static func _qc(o: Dictionary, c: Dictionary, p: Dictionary, rep: Dictionary) -> void:
	var cid: String = c["id"]
	var ev = MarketEngine.product_ev(p)
	var st: Dictionary = ev.get("stability", {})
	var mf := mfr_info(cid, o["mfr"])
	var r := G.rng
	var chem := Staff.best_skill(cid, "chemist")
	var pm := Staff.best_skill(cid, "production_manager")
	var lab := CompanyEngine.dept_level(cid, "lab")
	var prod := CompanyEngine.dept_level(cid, "production")
	var rw := 0.5 if int(o.get("rework", 0)) > 0 else 1.0
	var gi := int(p["bottle"].get("glass", 0))
	var risks := {
		"cloud": float(st.get("cloud", 0.0)) * (0.4 if o.get("chill", true) else 1.0) * rw,
		"crystal": float(st.get("crystal", 0.0)) * rw,
		"discolor": float(st.get("discolor", 0.0)) * GLASS_VIS[clampi(gi, 0, GLASS_VIS.size() - 1)] * 0.6,
		"oxidation": float(st.get("oxidation", 0.0)) * (0.5 + 0.1 * float(p.get("maturation", 0))) * rw,
		"fill": (1.0 - float(mf["rel"])) * (1.6 if p["pack"] == "luxury" else 1.0) * (1.0 - 0.3 * pm) * 3.0,
		"lot": float(ev.get("natural", 0.0)) * 0.12 * (1.0 - 0.5 * chem) * (1.0 - 0.3 * pm),
	}
	var defects := {}
	var detected := {}
	for k in risks:
		var rk := float(risks[k])
		if rk <= 0.0:
			continue
		if r.randf() < rk * 0.6:
			var share := clampf(0.05 + rk * 0.4 + r.randf() * 0.1, 0.03, 0.6)
			defects[k] = share
			var det := clampf(float(mf["qc"]) + 0.25 * chem + 0.05 * float(lab + prod - 2) + (0.1 if k == "fill" else 0.0), 0.05, 0.97)
			if r.randf() < det:
				detected[k] = share
	o["defects"] = defects
	o["detected"] = detected
	if detected.is_empty():
		release(o, true)
		return
	o["stage"] = "qc_hold"
	o["hold"] = 0
	if G.is_player(cid):
		var names: Array = []
		for k in detected:
			names.append("%s (%s of units)" % [defect_name(k), G.pct(float(detected[k]))])
		G.inbox_add({"type": "qc", "order": o["id"], "title": "Quality control: " + p["name"],
			"text": "QC flagged %s in a batch of %s units. Rework, release anyway or reject the batch?" % [", ".join(names), G.group_int(int(o["qty"]))]})
		rep["events"].append("QC issue on %s" % p["name"])
	else:
		rework(o)


static func defect_name(k: String) -> String:
	return {"cloud": "cloudiness", "crystal": "crystallization", "discolor": "discoloration", "oxidation": "oxidized off-notes",
		"fill": "packaging/filling faults", "lot": "batch inconsistency"}.get(k, k)


## Releases a batch to finished goods. If release_all, undetected (or accepted) defects go to market.
static func release(o: Dictionary, include_defects: bool) -> void:
	var p := G.product(o["product"])
	var c := G.company(o["company"])
	var qty := int(o["qty"])
	var val := float(o["value"])
	var inv := int(p["inv"])
	var nu := inv + qty
	p["unit_cost"] = (float(inv) * float(p["unit_cost"]) + val) / float(maxi(1, nu))
	o["value"] = 0.0
	var dshare := 0.0
	var dkind := ""
	if include_defects:
		for k in o["defects"]:
			if float(o["defects"][k]) > dshare:
				dshare = float(o["defects"][k])
				dkind = k
	p["defect"] = (float(inv) * float(p.get("defect", 0.0)) + float(qty) * dshare) / float(maxi(1, nu))
	if dshare > 0.0 and dkind != "":
		p["defect_kind"] = dkind
	p["inv"] = nu
	o["stage"] = "done"
	if G.is_player(o["company"]):
		CompanyEngine.plog(p, "Batch of %s units released (unit cost %s)." % [G.group_int(qty), G.money(val / float(qty))])
	# first batch triggers the launch
	if p["status"] == "dev":
		launch(p)
	c["stats"]["units_made"] = int(c["stats"].get("units_made", 0)) + qty


static func rework(o: Dictionary) -> String:
	var c := G.company(o["company"])
	var cost := float(o["value"]) * 0.15 + 500.0
	if G.is_player(o["company"]) and FinanceEngine.cash_of(c) < cost:
		return "Rework costs %s." % G.money(cost)
	FinanceEngine.cash(c, -cost)
	o["value"] = float(o["value"]) + cost
	o["rework"] = int(o.get("rework", 0)) + 1
	o["stage"] = "rework"
	o["fill_left"] = 1
	return ""


static func reject(o: Dictionary) -> void:
	var c := G.company(o["company"])
	var p := G.product(o["product"])
	FinanceEngine.pl(c, "writeoff", -float(o["value"]))
	o["value"] = 0.0
	o["stage"] = "done"
	var ed: Dictionary = p.get("edition", {})
	if ed.get("type", "") == "limited":
		ed["made"] = maxi(0, int(ed.get("made", 0)) - int(o["qty"]))
	CompanyEngine.plog(p, "Batch of %s units rejected and written off." % G.group_int(int(o["qty"])))


static func find_order(oid: String) -> Dictionary:
	for o in G.s["orders"]:
		if o["id"] == oid:
			return o
	return {}


## Launch: product goes on sale when its first batch arrives.
static func launch(p: Dictionary) -> void:
	p["status"] = "active"
	p["launched"] = true
	p["launch_week"] = G.week()
	var c := G.company(p["company"])
	c["stats"]["launches"] = int(c["stats"].get("launches", 0)) + 1
	CompanyEngine.plog(p, "Launched in %s." % ", ".join(p["markets"].map(func(x): return DB.country(x)["name"])))
	for cid in p["markets"]:
		var m := CompanyEngine.mk(p, cid)
		var b := G.brand(p["brand"])
		m["aw"] = maxf(float(m["aw"]), CompanyEngine.brand_aw(b, cid) * 0.25)
	if G.is_player(p["company"]):
		G.log_event("%s launched!" % p["name"], "good")
		var perf: String = p.get("perfumer", "ceo")
		if perf != "ceo" and not G.employee(perf).is_empty():
			var e := G.employee(perf)
			e["launches"] = int(e.get("launches", 0)) + 1
			Staff.note(e, "Created %s, launched by %s." % [p["name"], c["name"]])
	MarketingEngine.on_launch(p)


## Factory construction (owned production).
static func build_factory(c: Dictionary) -> String:
	var fd: Dictionary = DB.biz["factory"]
	if int(c["hq"]["tier"]) < int(fd["min_hq"]):
		return "Requires headquarters tier %d." % int(fd["min_hq"])
	var f: Dictionary = c.get("factory", {})
	if f.get("built", false) or int(f.get("weeks", 0)) > 0:
		return "Factory already built or under construction."
	var cost := float(fd["cost"])
	if FinanceEngine.cash_of(c) < cost:
		return "Requires %s." % G.money(cost)
	FinanceEngine.capex(c, cost)
	c["factory"] = {"built": false, "weeks": int(fd["weeks"]), "cap": int(fd["cap"]), "fixed": float(fd["fixed"]), "used": 0, "util": []}
	G.log_event("Factory construction started (%d weeks)." % int(fd["weeks"]), "info", c["id"])
	return ""


static func upgrade_factory(c: Dictionary) -> String:
	var fd: Dictionary = DB.biz["factory"]
	var f: Dictionary = c.get("factory", {})
	if not f.get("built", false):
		return "No factory."
	if int(f["cap"]) >= int(fd["upgrade_cap"]):
		return "Already expanded."
	var cost := float(fd["upgrade_cost"])
	if FinanceEngine.cash_of(c) < cost:
		return "Requires %s." % G.money(cost)
	FinanceEngine.capex(c, cost)
	f["cap"] = int(fd["upgrade_cap"])
	f["fixed"] = float(fd["upgrade_fixed"])
	G.log_event("Factory expanded to %s units/week." % G.group_int(int(f["cap"])), "good", c["id"])
	return ""


static func factory_weekly(c: Dictionary) -> void:
	var f: Dictionary = c.get("factory", {})
	if f.is_empty():
		return
	if not f.get("built", false):
		f["weeks"] = int(f["weeks"]) - 1
		if int(f["weeks"]) <= 0:
			f["built"] = true
			G.log_event("Your factory is operational (%s units/week)." % G.group_int(int(f["cap"])), "good", c["id"])
		return
	FinanceEngine.spend(c, "production", float(f["fixed"]))
	var used := 0
	for o in G.s["orders"]:
		if o["company"] == c["id"] and o["mfr"] == "own" and o["stage"] == "filling":
			used += int(o["qty"])
	var util := clampf(float(used) / maxf(1.0, float(f["cap"])), 0.0, 1.0)
	var u: Array = f.get("util", [])
	u.append(util)
	while u.size() > 12:
		u.remove_at(0)
	f["util"] = u


static func recall(p: Dictionary) -> void:
	## Pulls defective stock and refunds affected customers.
	var c := G.company(p["company"])
	var inv := int(p["inv"])
	var bad := int(round(float(inv) * float(p.get("defect", 0.0))))
	var wo := float(bad) * float(p["unit_cost"])
	if bad > 0:
		p["inv"] = inv - bad
		FinanceEngine.pl(c, "writeoff", -wo)
	var refund := float(p.get("complaints", 0)) * float(p["price"]) * 0.4
	FinanceEngine.spend(c, "returns", refund)
	FinanceEngine.spend(c, "admin", 15000.0)
	p["defect"] = 0.0
	p["complaints"] = 0
	CompanyEngine.plog(p, "Product recall: %d units withdrawn." % bad)
	var b := G.brand(p["brand"])
	b["prestige"] = clampf(float(b["prestige"]) - 0.02, 0.0, 1.0)
