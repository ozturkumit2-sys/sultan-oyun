class_name WorldGen
extends RefCounted
## Creates a new world: the player's startup, rival fragrance houses with real formulas,
## media personalities, a candidate pool and market conditions. A short warm-up lets
## established rival products build loyal customers and ratings before week 1.

const BASE_PP := {"budget": 28.0, "mass": 58.0, "premium": 120.0, "luxury": 230.0, "niche": 260.0}


static func skeleton() -> Dictionary:
	return {
		"version": G.SAVE_VERSION, "seed": 1, "rng_state": "", "week": 0, "next_id": 1, "player_id": "c0",
		"difficulty": "normal", "companies": {}, "brands": {}, "products": {}, "formulas": {}, "employees": {},
		"candidates": [], "orders": [], "deliveries": [], "proposals": [], "campaigns": [], "media": {}, "channels": [],
		"markets": {}, "ing_market": {}, "events": {"cool": {}, "active": []}, "inbox": [], "log": [], "awards": [],
		"loans": [], "tests": [], "surveys": [], "contracts": [], "accords": [], "board": {}, "tutorial": {"step": 0, "done": false},
		"reports": [], "deals": [], "stats": {"weeks": 0}, "regs": {},
	}


static func new_game(opts: Dictionary) -> void:
	DB.load_all()
	G.clear_cache()
	G.s = skeleton()
	var seed_val := int(opts.get("seed", Time.get_unix_time_from_system()))
	G.seed_world(seed_val)
	var r := G.rng
	var diff: String = opts.get("difficulty", "normal")
	G.s["difficulty"] = diff
	var dmul: Array = {"easy": [150000.0, 0.8], "normal": [100000.0, 1.0], "hard": [75000.0, 1.2]}.get(diff, [100000.0, 1.0])
	G.s["rival_mult"] = dmul[1]
	# markets
	for ct in DB.countries:
		var tr := PackedFloat32Array(ct["trend"])
		for i in tr.size():
			tr[i] += r.randfn(0.0, 0.02)
		G.s["markets"][ct["id"]] = {"trend": Array(tr), "avg": [], "size": 1.0, "share": {}, "units": 0}
	for id in DB.ing_order:
		var rec := DB.ing(id)
		G.s["ing_market"][id] = {"idx": snappedf(1.0 + r.randfn(0.0, 0.04), 0.001), "avail": float(rec.get("avail", 0.95)), "short": 0, "hist": []}
	# rivals first (ids c1..)
	var n := 1
	for rv in DB.rivals:
		_make_rival(rv, "c%d" % n, r, float(dmul[1]))
		n += 1
	G.s["media"] = MarketingEngine.gen_media(r)
	_warmup(r)
	# player
	var home: String = opts.get("home", "TR")
	var pc := CompanyEngine.make_company("c0", opts.get("company", "Maison Nouvelle"), home, true, float(dmul[0]))
	pc["color"] = opts.get("color", "#c9a55a")
	pc["color2"] = opts.get("color2", "#1c1a20")
	pc["logo"] = int(opts.get("logo", 0))
	pc["reputation"] = 0.25
	G.s["companies"]["c0"] = pc
	var posit: String = opts.get("posit", "premium")
	var b := CompanyEngine.make_brand("c0", opts.get("brand", pc["name"]), posit, pc["color"], minf(0.15, float(DB.positionings[posit]["prestige_cap"])), int(opts.get("logo", 0)))
	b["markets"] = [home]
	CompanyEngine.set_brand_aw(b, home, 0.004)
	Staff.refresh_candidates(true)
	G.s["week"] = 0
	G.inbox_add({"type": "welcome", "title": "Welcome to your fragrance house",
		"text": "You have %s, a small laboratory and access to a contract manufacturer. Create your first formula in the Lab, launch it, and watch the market respond." % G.money(float(dmul[0]))})
	G.log_event("%s was founded in %s." % [pc["name"], DB.country(home)["name"]], "good")
	G.store_rng()
	G.clear_cache()


static func _make_rival(rv: Dictionary, cid: String, r: RandomNumberGenerator, mult: float) -> void:
	var cash := float(rv["cash"]) * mult
	var c := CompanyEngine.make_company(cid, rv["name"], rv["home"], false, cash)
	c["hq"]["tier"] = 4 if cash > 30e6 else (3 if cash > 9e6 else 2)
	c["depts"] = {"lab": 2, "executive": 2, "production": 2, "marketing": 2, "sales": 2, "finance": 2, "hr": 2}
	c["reputation"] = r.randf_range(0.45, 0.75)
	c["ai"] = {"style": rv["style"], "mkt": float(rv["mkt"]) * mult, "risk": float(rv["risk"]), "key": rv["id"],
		"next_launch": r.randi_range(6, 30), "offset": r.randi_range(0, 3), "disc": 1.0, "war": {}, "cash0": cash}
	c["color"] = rv["brands"][0]["color"]
	for k in DB.ing_order:
		c["unlocked"][k] = true
	# established houses own production capacity sized to their scale
	var fcap: int = {4: 220000, 3: 90000, 2: 40000}.get(int(c["hq"]["tier"]), 40000)
	c["factory"] = {"built": true, "weeks": 0, "cap": fcap, "fixed": 22000.0 * float(fcap) / 25000.0 * 0.6, "used": 0, "util": []}
	G.s["companies"][cid] = c
	var markets: Array = rv["offices"].duplicate()
	for o in rv["offices"]:
		if o != rv["home"]:
			c["offices"][o] = {"level": r.randi_range(1, 2), "since": -100, "manager": "", "hq": false}
	var others: Array = DB.country_by_id.keys().filter(func(x): return not markets.has(x))
	others.shuffle()
	for i in r.randi_range(1, 2):
		if i < others.size():
			markets.append(others[i])
			_agree(cid, others[i], "distributor", r)
			_agree(cid, others[i], "marketplace", r)
	# channels in office markets
	var posits: Array = []
	for bd in rv["brands"]:
		posits.append(bd["posit"])
	for o in rv["offices"]:
		var chs := ["marketplace"]
		for ps in posits:
			match ps:
				"luxury", "niche":
					chs += ["dept", "perfumery"]
				"premium":
					chs += ["dept", "perfumery", "beauty"]
				"mass":
					chs += ["beauty", "mass"]
				"budget":
					chs += ["mass"]
		var seen := {}
		for ch in chs:
			if not seen.has(ch):
				seen[ch] = true
				_agree(cid, o, ch, r)
	# perfumers
	var best := {}
	var lvl := 0.62 if rv["style"] in ["luxury", "niche"] else 0.52
	for i in r.randi_range(2, 4):
		var e := Staff.make_person("perfumer", r, lvl + r.randf_range(0.0, 0.2), rv["home"] if r.randf() < 0.5 else "")
		e["employer"] = cid
		e["status"] = "active"
		e["hired"] = -r.randi_range(20, 400)
		e["contract_end"] = r.randi_range(26, 200)
		G.s["employees"][e["id"]] = e
		if best.is_empty() or Staff.perfumer_skill(e) > Staff.perfumer_skill(best):
			best = e
	for rid in ["marketing_manager", "production_manager", "sales_manager"]:
		var e2 := Staff.make_person(rid, r, 0.55 + r.randf() * 0.2)
		e2["employer"] = cid
		e2["status"] = "active"
		e2["contract_end"] = r.randi_range(26, 200)
		G.s["employees"][e2["id"]] = e2
	var avail: Array = DB.ing_order.duplicate()
	for bd in rv["brands"]:
		var b := CompanyEngine.make_brand(cid, bd["name"], bd["posit"], bd["color"], float(bd["prestige"]), r.randi_range(0, 5))
		b["markets"] = markets.duplicate()
		b["budget"] = 0.0
		for m in markets:
			var aw := float(bd["aw"]) * float(DB.bal["rivals"]["aw_mult"]) * (1.0 if m == rv["home"] else (0.7 if rv["offices"].has(m) else 0.2))
			CompanyEngine.set_brand_aw(b, m, aw * r.randf_range(0.8, 1.15))
		for k in int(bd["n"]):
			var prod := rival_product(c, b, bd["family"], best, avail, r, markets)
			prod["launch_week"] = -r.randi_range(6, 420)
			prod["status"] = "active"
			prod["launched"] = true
			for m in markets:
				var mk := CompanyEngine.mk(prod, m)
				mk["aw"] = CompanyEngine.brand_aw(b, m) * r.randf_range(0.35, 0.9)
				mk["sat"] = 0.55
			var cb := CompanyEngine.cost_breakdown(prod, _mfr_for(b["posit"]))
			prod["unit_cost"] = float(cb["total"])
			prod["inv"] = 2500 + r.randi_range(0, 3000)


static func _agree(cid: String, country: String, ch: String, r: RandomNumberGenerator) -> void:
	var chd: Dictionary = DB.channels[ch]
	G.s["channels"].append({"id": G.new_id("a"), "company": cid, "country": country, "ch": ch,
		"partner": G.pick(DB.names["partners"].get(ch, ["Partner"]), r), "q": snappedf(r.randf_range(0.9, 1.15), 0.01),
		"margin": float(chd["margin"]), "fee": 0.0, "since": -100, "until": 52 + r.randi_range(0, 52), "active": true, "units": 0, "rev": 0.0})


static func _mfr_for(posit: String) -> String:
	match posit:
		"luxury", "niche":
			return "grasse"
		"premium":
			return "meridian"
	return "massblend"


static func fmt_for(posit: String, r: RandomNumberGenerator) -> String:
	var opts: Dictionary = {"budget": ["mist", "edt", "edt", "edc"], "mass": ["edt", "edp", "edt", "mist"], "premium": ["edp", "edt", "edp"],
		"luxury": ["edp", "extrait", "edp"], "niche": ["edp", "extrait", "oil", "edp"]}
	return str(G.pick(opts.get(posit, ["edp"]), r))


static func audience_for(profile: PackedFloat32Array, r: RandomNumberGenerator) -> String:
	var f := 0.0
	var m := 0.0
	for d in ["floral", "fruity", "gourmand", "powdery"]:
		f += profile[DB.dim_index(d)]
	for d in ["woody", "aromatic", "spicy", "animalic", "aquatic"]:
		m += profile[DB.dim_index(d)]
	var x := f - m + r.randfn(0.0, 0.15)
	if x > 0.18:
		return "fem"
	if x < -0.18:
		return "masc"
	return "any"


static func rival_price(posit: String, fmt: String, vol: float, r: RandomNumberGenerator) -> float:
	var pp := float(BASE_PP.get(posit, 60.0)) * float(DB.formats[fmt]["ref_mult"]) * r.randf_range(0.85, 1.2)
	return maxf(4.0, round(pp * pow(vol / 100.0, 0.8)))


static func rival_product(c: Dictionary, b: Dictionary, fams: Array, perf: Dictionary, avail: Array, r: RandomNumberGenerator, markets: Array, target_override := {}) -> Dictionary:
	var target := {}
	if target_override.is_empty():
		target[fams[0]] = 1.0
		target[fams[r.randi_range(0, fams.size() - 1)]] = float(target.get(fams[r.randi_range(0, fams.size() - 1)], 0.0)) + 0.6
		target[DB.dims[r.randi_range(0, DB.dims.size() - 1)]] = 0.25
	else:
		target = target_override
	var posit: String = b["posit"]
	var fmt := fmt_for(posit, r)
	var skill := {"creativity": 0.6, "technique": 0.7, "cost": 0.8 if posit in ["budget", "mass"] else 0.35}
	if not perf.is_empty():
		skill = perf["skills"].duplicate()
		if posit in ["budget", "mass"]:
			skill["cost"] = maxf(float(skill["cost"]), 0.75)
	var gen := PerfumerAI.generate({"target": target, "fmt": fmt, "posit": posit}, skill, avail, r)
	var vol: float = G.pick({"budget": [100.0, 200.0, 75.0], "mass": [50.0, 100.0, 100.0], "premium": [50.0, 100.0], "luxury": [50.0, 100.0, 75.0], "niche": [50.0, 100.0, 30.0]}.get(posit, [50.0]), r)
	if fmt == "oil":
		vol = 15.0 if r.randf() < 0.5 else 30.0
	var name := PerfumerAI.name_for(gen["ev"], r)
	var f := CompanyEngine.make_formula(c["id"], name, gen["items"], perf.get("id", ""), "Original")
	var pack: String = {"budget": "basic", "mass": "standard", "premium": "premium", "luxury": "luxury", "niche": "premium"}.get(posit, "standard")
	var prod := CompanyEngine.make_product(c["id"], {"brand": b["id"], "name": name, "formula": f["id"], "fv": 0, "fmt": fmt,
		"conc": float(gen["conc"]), "volume": vol, "pack": pack, "audience": audience_for(gen["ev"]["profile"], r),
		"price": rival_price(posit, fmt, vol, r), "markets": markets.duplicate(), "bottle": CompanyEngine.default_bottle(r, b["color"]),
		"perfumer": perf.get("id", "")})
	prod["base_price"] = float(prod["price"])
	return prod


static func _warmup(r: RandomNumberGenerator) -> void:
	var weeks := 12
	G.s["week"] = 0
	for i in weeks:
		var rep := Sim.empty_report()
		for c in G.s["companies"].values():
			Rivals.production(c, true)
		ProductionEngine.weekly(rep)
		MarketEngine.run_week(rep)
		MarketEngine.decay()
		if i % 4 == 0:
			IngredientMarket.weekly(r)
	# Reset ledgers: rivals start the game with their stated cash and current inventory.
	G.s["loans"] = []
	for c in G.s["companies"].values():
		var f: Dictionary = c["fin"]
		f["cash"] = float(c["ai"].get("cash0", f["cash"]))
		f["debt"] = 0.0
		f["wk"] = {}
		f["hist"] = []
		f["years"] = {}
		f["lifetime"] = {}
		f["tax_cf"] = 0.0
		f["retained"] = 0.0
		f["paid_in"] = 0.0
		f["paid_in"] = FinanceEngine.assets(c) - float(f["debt"])
	for p in G.s["products"].values():
		var tot := 0
		for wkr in p["wk"]:
			tot += int(wkr[1])
		var avgw := float(tot) / float(maxi(1, p["wk"].size()))
		var age := -int(p["launch_week"])
		p["st"]["units"] = int(avgw * float(age) * 0.7)
		p["st"]["rev"] = float(p["st"]["units"]) * CompanyEngine.net_price(p, p["markets"][0]) * 0.7
		p["st"]["gp"] = float(p["st"]["rev"]) * 0.6
		p["st"]["lost"] = 0
		p["seed_avg"] = avgw
		p["wk"] = []
		p["yr"] = {}
	for ct in G.s["markets"].values():
		ct["share"] = {}
	G.s["log"] = []
	G.s["inbox"] = []
