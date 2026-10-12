class_name Awards
extends RefCounted
## Annual fictional industry awards (multi-criteria, never guaranteed) and earned product statuses.

const CATS := ["Best New Launch", "Best Niche Fragrance", "Most Innovative Composition", "Best Luxury Brand", "Best Emerging Fragrance House", "Consumer Favorite"]


static func critic_avg(p: Dictionary) -> float:
	var cr: Array = p.get("critics", [])
	if cr.is_empty():
		return 5.5
	var t := 0.0
	for x in cr:
		t += float(x["score"])
	return t / float(cr.size())


static func rating_avg(p: Dictionary) -> float:
	var rt: Dictionary = p["rating"]
	return float(rt["sum"]) / float(rt["n"]) if int(rt["n"]) > 0 else 3.0


static func units_year(p: Dictionary) -> int:
	return int(p["yr"].get(str(G.year_of(G.week())), [0])[0])


static func run(r: RandomNumberGenerator, rep: Dictionary) -> void:
	var year := G.year_of(G.week())
	var prods: Array = []
	for p in G.s["products"].values():
		if p["status"] == "active" and p.get("kind", "full") == "full":
			prods.append(p)
	if prods.is_empty():
		return
	var max_u := 1.0
	for p in prods:
		max_u = maxf(max_u, float(units_year(p)))
	var results: Array = []
	for cat in CATS:
		var best: Dictionary = {}
		var best_s := -99.0
		if cat == "Best Luxury Brand" or cat == "Best Emerging Fragrance House":
			var win := _org_award(cat, r)
			if not win.is_empty():
				results.append(win)
			continue
		for p in prods:
			var age := G.week() - int(p["launch_week"])
			var b := G.brand(p["brand"])
			var ev = MarketEngine.product_ev(p)
			if ev.is_empty():
				continue
			var nov := float(p.get("mk_nov_" + str(p["markets"][0]), 0.3))
			var sc := -99.0
			match cat:
				"Best New Launch":
					if age <= 52:
						sc = 0.4 * critic_avg(p) / 10.0 + 0.25 * rating_avg(p) / 5.0 + 0.2 * float(units_year(p)) / max_u + 0.15 * nov
				"Best Niche Fragrance":
					if b.get("posit", "") == "niche":
						sc = 0.45 * critic_avg(p) / 10.0 + 0.3 * rating_avg(p) / 5.0 + 0.25 * float(ev["complexity"])
				"Most Innovative Composition":
					sc = 0.45 * nov + 0.3 * float(ev["complexity"]) + 0.25 * critic_avg(p) / 10.0 - 0.3 * float(ev["tension"])
				"Consumer Favorite":
					if int(p["rating"]["n"]) >= 20:
						sc = 0.6 * rating_avg(p) / 5.0 + 0.4 * float(units_year(p)) / max_u
			if sc <= -90.0:
				continue
			sc += r.randfn(0.0, 0.04)
			if sc > best_s:
				best_s = sc
				best = p
		if best.is_empty():
			continue
		results.append({"cat": cat, "product": best["id"], "company": best["company"], "name": best["name"], "brand": best["brand"]})
	for w in results:
		w["year"] = year
		G.s["awards"].append(w)
		var b2 := G.brand(w.get("brand", ""))
		if not b2.is_empty():
			var cap := float(DB.positionings[b2["posit"]]["prestige_cap"])
			b2["prestige"] = clampf(float(b2["prestige"]) + 0.04, 0.0, cap)
		if w.has("product") and w["product"] != "":
			var p := G.product(w["product"])
			p["awards"].append("%s %d" % [w["cat"], year])
			for cid in p["mk"]:
				p["mk"][cid]["buzz"] = clampf(float(p["mk"][cid]["buzz"]) + 0.3, 0.0, 1.0)
			CompanyEngine.plog(p, "Won %s %d." % [w["cat"], year])
		var who = G.company(w["company"])["name"]
		if G.is_player(w["company"]):
			rep["events"].append("Award: %s — %s" % [w["cat"], w["name"]])
			G.log_event("🏆 %s won %s %d!" % [w["name"], w["cat"], year], "good")
		else:
			G.log_event("Awards %d: %s — %s (%s)." % [year, w["cat"], w["name"], who], "info", "*")


static func _org_award(cat: String, r: RandomNumberGenerator) -> Dictionary:
	var best: Dictionary = {}
	var best_s := -99.0
	if cat == "Best Luxury Brand":
		for b in G.s["brands"].values():
			if b.get("status", "active") != "active" or not (b["posit"] in ["luxury", "niche"]):
				continue
			var rev := 0.0
			var rt := 0.0
			var n := 0
			for p in G.company_products(b["company"]):
				if p["brand"] == b["id"]:
					rev += float(p["yr"].get(str(G.year_of(G.week())), [0, 0.0])[1])
					rt += rating_avg(p)
					n += 1
			if n == 0:
				continue
			var sc := 0.5 * float(b["prestige"]) + 0.3 * (rt / float(n)) / 5.0 + 0.2 * minf(1.0, rev / 2e7) + r.randfn(0.0, 0.04)
			if sc > best_s:
				best_s = sc
				best = {"cat": cat, "product": "", "company": b["company"], "name": b["name"], "brand": b["id"]}
	else:
		for c in G.s["companies"].values():
			if not c.get("active", true):
				continue
			var age := G.week() - int(c.get("founded", -1000))
			if age > 260 and not c.get("is_player", false):
				continue
			if age > 260 and c.get("is_player", false) and G.week() > 260:
				continue
			var g := FinanceEngine.growth(c)
			var t := FinanceEngine.ttm(c)
			if float(t["revenue"]) < 50000.0:
				continue
			var sc := 0.5 * clampf(g, 0.0, 1.0) + 0.3 * float(c.get("reputation", 0.3)) + 0.2 * minf(1.0, float(t["revenue"]) / 5e6) + r.randfn(0.0, 0.04)
			if sc > best_s:
				best_s = sc
				var bs := G.company_brands(c["id"])
				best = {"cat": cat, "product": "", "company": c["id"], "name": c["name"], "brand": bs[0]["id"] if not bs.is_empty() else ""}
	return best


## Earned statuses from historical performance: Emerging hit, Bestseller, Cult classic, Iconic, Revival.
static func statuses() -> void:
	var prods: Array = []
	for p in G.s["products"].values():
		if p["status"] == "active" and p.get("kind", "full") == "full":
			prods.append(p)
	if prods.size() < 3:
		return
	var recent: Array = []
	for p in prods:
		var u := 0
		for x in p["wk"].slice(maxi(0, p["wk"].size() - 52)):
			u += int(x[1])
		recent.append([u, p])
	recent.sort_custom(func(a, b): return a[0] > b[0])
	var top5 := {}
	for i in mini(5, recent.size()):
		top5[recent[i][1]["id"]] = true
	var thr_hit: int = recent[mini(recent.size() - 1, maxi(0, int(recent.size() * 0.1)))][0]
	for x in recent:
		var p: Dictionary = x[1]
		var age := G.week() - int(p["launch_week"])
		var tags: Array = []
		var u52: int = x[0]
		if age <= 52 and u52 >= thr_hit and u52 > 0:
			tags.append("Emerging hit")
		if top5.has(p["id"]) and age > 26:
			tags.append("Bestseller")
		var loyal := 0.0
		for cid in p["mk"]:
			loyal += float(p["mk"][cid]["loyal"])
		if age >= 104 and rating_avg(p) >= 4.1 and int(p["rating"]["n"]) >= 25 and loyal >= float(u52) * 0.2 and not top5.has(p["id"]):
			tags.append("Cult classic")
		if age >= 260 and int(p["st"]["units"]) >= 400000 and rating_avg(p) >= 3.7:
			tags.append("Iconic")
		var wk: Array = p["wk"]
		if age >= 156 and wk.size() >= 52:
			var now := 0
			var then := 0
			for i in range(wk.size() - 8, wk.size()):
				now += int(wk[i][1])
			for i in range(wk.size() - 52, wk.size() - 44):
				then += int(wk[i][1])
			if now > then * 1.5 and now > 200:
				tags.append("Revival")
		for t in tags:
			if not p["tags"].has(t):
				CompanyEngine.plog(p, "Earned status: %s." % t)
				if G.is_player(p["company"]):
					G.log_event("%s is now considered a%s %s." % [p["name"], "n" if t[0] in "AEIOU" else "", t], "good")
		var keep: Array = []
		for t in p["tags"]:
			if t == "Iconic" or t == "Cult classic" or tags.has(t):
				keep.append(t)
		for t in tags:
			if not keep.has(t):
				keep.append(t)
		p["tags"] = keep
