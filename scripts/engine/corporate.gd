class_name Corporate
extends RefCounted
## Ownership and capital markets: investor rounds, board of directors, IPO and share price,
## dividends, acquisitions (assets and liabilities transferred exactly once), brand sales,
## reputation, and financial distress with recovery paths.

const BOARD_FOCUS := ["profitability", "debt", "growth", "expansion", "share"]


static func founder_pct(c: Dictionary) -> float:
	for h in c["holders"]:
		if h["kind"] == "founder":
			return float(h["pct"])
	return 0.0


static func outside_pct(c: Dictionary) -> float:
	return 1.0 - founder_pct(c)


static func _dilute(c: Dictionary, new_pct: float, holder: Dictionary) -> void:
	for h in c["holders"]:
		h["pct"] = float(h["pct"]) * (1.0 - new_pct)
	holder["pct"] = new_pct
	c["holders"].append(holder)
	c["shares"] = int(float(c["shares"]) / (1.0 - new_pct))


# ---------------------------------------------------------------- investors
static func investor_offers(c: Dictionary) -> Array:
	var t := FinanceEngine.ttm(c)
	if c.get("public", false) or float(t["revenue"]) < 300000.0:
		return []
	var r := G.drng("inv|%s|%d" % [c["id"], int(G.week() / 13)])
	var val := FinanceEngine.valuation(c)
	var conf := float(G.s.get("board", {}).get("confidence", 60.0))
	var out: Array = []
	for pct in [0.1, 0.2, 0.3]:
		var pre := val * r.randf_range(0.8, 1.1) * (0.85 + 0.003 * conf)
		var amt := snappedf(pre * pct / (1.0 - pct), 1000.0)
		out.append({"fund": G.pick(DB.names["funds"], r), "pct": pct, "amount": amt, "pre": pre})
	return out


static func accept_investment(c: Dictionary, offer: Dictionary) -> void:
	FinanceEngine.raise_equity(c, float(offer["amount"]))
	_dilute(c, float(offer["pct"]), {"name": offer["fund"], "pct": 0.0, "kind": "investor"})
	G.log_event("%s invested %s for %s of the company." % [offer["fund"], G.money(float(offer["amount"])), G.pct(float(offer["pct"]))], "good")
	G.s["deals"].append({"w": G.week(), "kind": "investment", "text": "%s: %s for %s" % [offer["fund"], G.money(float(offer["amount"])), G.pct(float(offer["pct"]))]})
	ensure_board(c)


static func ensure_board(c: Dictionary) -> void:
	if outside_pct(c) < 0.2 and not c.get("public", false):
		return
	var bd: Dictionary = G.s["board"]
	if not bd.is_empty():
		return
	var r := G.drng("board|" + c["id"])
	var names: Array = DB.names["board"].duplicate()
	var members: Array = []
	for i in 4:
		var nm: String = names[r.randi_range(0, names.size() - 1)]
		names.erase(nm)
		members.append({"name": nm, "focus": BOARD_FOCUS[i % BOARD_FOCUS.size()] if i < 4 else "growth"})
	G.s["board"] = {"members": members, "confidence": 60.0, "targets": [], "since": G.week(), "history": []}
	_set_targets(c)
	G.inbox_add({"type": "info", "title": "A board of directors is formed",
		"text": "Outside shareholders now own %s. The board will set quarterly objectives; meeting them builds confidence, improving financing terms and the share price." % G.pct(outside_pct(c))})


static func _set_targets(c: Dictionary) -> void:
	var bd: Dictionary = G.s["board"]
	var t := FinanceEngine.ttm(c)
	var targets: Array = []
	for m in bd["members"]:
		match m["focus"]:
			"profitability":
				var cur := float(t["net"]) / maxf(1.0, float(t["revenue"]))
				targets.append({"k": "margin", "label": "Net margin ≥ %s" % G.pct(maxf(0.05, cur + 0.02)), "v": maxf(0.05, cur + 0.02), "by": m["name"]})
			"debt":
				targets.append({"k": "lev", "label": "Debt ≤ 2.5× annual EBITDA", "v": 2.5, "by": m["name"]})
			"growth":
				targets.append({"k": "growth", "label": "Quarterly revenue growth ≥ 5%", "v": 0.05, "by": m["name"]})
			"expansion":
				var n = c["offices"].size()
				targets.append({"k": "offices", "label": "Operate in ≥ %d countries" % (n + 1), "v": n + 1, "by": m["name"]})
			"share":
				targets.append({"k": "rank", "label": "Improve revenue rank (now #%d)" % _rank(c), "v": _rank(c), "by": m["name"]})
	bd["targets"] = targets
	bd["due"] = G.week() + 13


static func _rank(c: Dictionary) -> int:
	var rk := Rivals.ranking()
	for i in rk.size():
		if rk[i]["id"] == c["id"]:
			return i + 1
	return rk.size()


static func _board_review(c: Dictionary) -> void:
	var bd: Dictionary = G.s["board"]
	var t := FinanceEngine.ttm(c)
	var met := 0
	var res: Array = []
	for tg in bd["targets"]:
		var ok := false
		match tg["k"]:
			"margin":
				ok = float(t["net"]) / maxf(1.0, float(t["revenue"])) >= float(tg["v"])
			"lev":
				ok = float(c["fin"]["debt"]) <= maxf(1.0, float(t["ebitda"])) * float(tg["v"])
			"growth":
				ok = FinanceEngine.growth(c) >= float(tg["v"])
			"offices":
				ok = c["offices"].size() >= int(tg["v"])
			"rank":
				ok = _rank(c) < int(tg["v"]) or _rank(c) == 1
		res.append([tg["label"], ok])
		if ok:
			met += 1
	var delta := float(met) * 9.0 - float(res.size() - met) * 10.0
	bd["confidence"] = clampf(float(bd["confidence"]) + delta, 0.0, 100.0)
	bd["history"].append({"w": G.week(), "res": res, "conf": bd["confidence"]})
	while bd["history"].size() > 12:
		bd["history"].remove_at(0)
	var txt := "Board review: %d of %d objectives met. Confidence %d/100." % [met, res.size(), int(bd["confidence"])]
	if float(bd["confidence"]) < 30.0:
		txt += " The board is concerned: fundraising terms will be worse until results improve."
	G.inbox_add({"type": "info", "title": "Quarterly board review", "text": txt})
	_set_targets(c)


# ---------------------------------------------------------------- IPO
static func ipo_requirements(c: Dictionary) -> Array:
	var t := FinanceEngine.ttm(c)
	return [
		["Headquarters: International HQ or higher", int(c["hq"]["tier"]) >= 3],
		["Trailing revenue ≥ $40M", float(t["revenue"]) >= 4e7],
		["Profitable over the last year", float(t["net"]) > 0.0],
		["At least 3 active products", G.company_products(c["id"]).size() >= 3],
	]


static func can_ipo(c: Dictionary) -> bool:
	if c.get("public", false):
		return false
	for x in ipo_requirements(c):
		if not x[1]:
			return false
	return true


static func do_ipo(c: Dictionary, pct: float) -> void:
	var val := FinanceEngine.valuation(c) * 0.92
	var amt := val * pct / (1.0 - pct)
	var fees := amt * 0.05
	FinanceEngine.raise_equity(c, amt)
	FinanceEngine.spend(c, "admin", fees)
	_dilute(c, pct, {"name": "Public shareholders", "pct": 0.0, "kind": "public"})
	c["public"] = true
	c["ipo_week"] = G.week()
	c["share_price"] = (val + amt) / float(c["shares"])
	ensure_board(c)
	G.log_event("IPO completed! Raised %s at a %s valuation." % [G.money(amt), G.money(val)], "good")
	G.s["deals"].append({"w": G.week(), "kind": "ipo", "text": "IPO: raised %s" % G.money(amt)})


static func pay_dividend(c: Dictionary, amt: float) -> String:
	if amt <= 0.0 or amt > FinanceEngine.cash_of(c) * 0.5:
		return "Dividends are limited to half of available cash."
	if FinanceEngine.equity(c) <= amt:
		return "Not enough retained equity."
	FinanceEngine.dividend(c, amt)
	var bd: Dictionary = G.s["board"]
	if not bd.is_empty():
		bd["confidence"] = clampf(float(bd["confidence"]) + 3.0, 0.0, 100.0)
	G.log_event("Paid a dividend of %s (you received %s)." % [G.money(amt), G.money(amt * founder_pct(c))], "good")
	return ""


# ---------------------------------------------------------------- weekly
static func weekly(c: Dictionary, _rep: Dictionary) -> void:
	if int(c.get("integrating", 0)) > 0:
		c["integrating"] = int(c["integrating"]) - 1
	if not G.is_player(c["id"]):
		return
	var bd: Dictionary = G.s["board"]
	if not bd.is_empty() and int(bd.get("due", 0)) <= G.week():
		_board_review(c)
	if c.get("public", false):
		var val := FinanceEngine.valuation(c)
		var conf := float(bd.get("confidence", 60.0))
		var target := val / float(c["shares"]) * (0.85 + 0.003 * conf)
		var sp := float(c.get("share_price", target))
		c["share_price"] = maxf(0.01, sp + (target - sp) * 0.15 + G.rng.randfn(0.0, sp * 0.015))
		var sh: Array = c.get("price_hist", [])
		sh.append(snappedf(float(c["share_price"]), 0.01))
		while sh.size() > 104:
			sh.remove_at(0)
		c["price_hist"] = sh
	_distress(c)


static func _distress(c: Dictionary) -> void:
	var od := 0.0
	for ln in G.s["loans"]:
		if ln["company"] == c["id"] and ln["kind"] == "overdraft":
			od = float(ln["left"])
	var limit := FinanceEngine.credit_limit(c)
	if od > limit and FinanceEngine.equity(c) < 0.0:
		c["distress"] = int(c.get("distress", 0)) + 1
		if int(c["distress"]) == 1 or int(c["distress"]) % 8 == 0:
			G.inbox_add({"type": "distress", "title": "Financial distress",
				"text": "Emergency credit (%s) exceeds your credit limit and equity is negative. Recover by cutting costs, selling a brand, raising investor capital, or liquidating stock. After 26 weeks the bank will force a restructuring." % G.money(od)})
		if int(c["distress"]) >= 26:
			restructure(c)
	else:
		c["distress"] = 0


## Forced restructuring: the bank converts emergency debt into equity; the founder keeps a minority stake.
static func restructure(c: Dictionary) -> void:
	for ln in G.s["loans"].duplicate():
		if ln["company"] == c["id"] and ln["kind"] == "overdraft":
			var amt := float(ln["left"])
			c["fin"]["debt"] = maxf(0.0, float(c["fin"]["debt"]) - amt)
			c["fin"]["paid_in"] = float(c["fin"]["paid_in"]) + amt
			G.s["loans"].erase(ln)
	_dilute(c, 0.6, {"name": "Creditor bank (restructuring)", "pct": 0.0, "kind": "investor"})
	c["distress"] = 0
	ensure_board(c)
	G.inbox_add({"type": "info", "title": "Restructuring completed",
		"text": "Creditors converted the emergency debt into a 60% ownership stake. You remain CEO with a smaller share. Rebuild profitability to regain control."})


static func reputation(c: Dictionary) -> void:
	var bs := G.company_brands(c["id"])
	var pr := 0.0
	for b in bs:
		pr = maxf(pr, float(b["prestige"]))
	var rt := 0.0
	var n := 0
	for p in G.company_products(c["id"]):
		if int(p["rating"]["n"]) > 5:
			rt += Awards.rating_avg(p)
			n += 1
	var ravg := rt / float(n) if n > 0 else 3.5
	var scale := clampf(log(1.0 + float(FinanceEngine.ttm(c)["revenue"]) / 1e5) / log(1.0 + 1e4), 0.0, 1.0)
	var target := 0.35 * pr + 0.35 * (ravg - 1.0) / 4.0 + 0.3 * scale
	c["reputation"] = lerpf(float(c.get("reputation", 0.3)), target, 0.02)
	# brand prestige drifts toward what its products and positioning justify
	for b in bs:
		var cap := float(DB.positionings[b["posit"]]["prestige_cap"])
		var bp := 0.0
		var bn := 0
		var price_ok := 0.0
		for p in G.company_products(c["id"]):
			if p["brand"] != b["id"]:
				continue
			bn += 1
			bp += Awards.rating_avg(p)
			var pp := ConsumerEngine.price_pp(float(p["price"]), float(p["volume"]))
			price_ok += clampf(pp / (float(WorldGen.BASE_PP.get(b["posit"], 60.0)) * 0.8), 0.3, 1.2)
		if bn == 0:
			continue
		var tgt := minf(cap, (0.2 + 0.5 * (bp / float(bn) - 2.5) / 2.5) * minf(1.0, price_ok / float(bn)) * cap + 0.1)
		if tgt < float(b["prestige"]):
			b["prestige"] = lerpf(float(b["prestige"]), tgt, 0.01)
		else:
			b["prestige"] = lerpf(float(b["prestige"]), tgt, 0.004)


# ---------------------------------------------------------------- acquisitions
static func ask_price(target: Dictionary) -> float:
	var val := FinanceEngine.valuation(target)
	var t := FinanceEngine.ttm(target)
	var distressed := FinanceEngine.cash_of(target) < 0.0 or float(t["net"]) < 0.0
	return val * (1.08 if distressed else 1.3)


static func willingness(target: Dictionary) -> String:
	var t := FinanceEngine.ttm(target)
	if FinanceEngine.cash_of(target) < 0.0 or float(t["net"]) < 0.0:
		return "Open to offers (financial pressure)"
	if FinanceEngine.growth(target) < 0.0:
		return "Listening (sales declining)"
	return "Reluctant (healthy and growing)"


static func make_offer(buyer: Dictionary, target: Dictionary, price: float) -> Dictionary:
	var key = "mna_" + target["id"]
	var tries: Dictionary = G.s["events"].get("mna", {})
	var tr: Array = tries.get(target["id"], [0, 0])
	if int(tr[1]) > G.week() and int(tr[0]) >= 3:
		return {"ok": false, "msg": "The owners have stopped talking for now. Try again after week %d." % int(tr[1])}
	if int(tr[1]) <= G.week():
		tr = [0, G.week() + 26]
	tr[0] = int(tr[0]) + 1
	tries[target["id"]] = tr
	G.s["events"]["mna"] = tries
	if not target.get("active", true):
		return {"ok": false, "msg": "Company no longer independent."}
	if FinanceEngine.cash_of(buyer) < price:
		return {"ok": false, "msg": "You need %s in cash to close this deal (consider a loan or investors)." % G.money(price)}
	var ask := ask_price(target)
	if price >= ask:
		execute(buyer, target, price)
		return {"ok": true, "msg": "Deal! %s accepted %s." % [target["name"], G.money(price)]}
	if price >= ask * 0.85:
		return {"ok": false, "msg": "Counter-offer: the owners would accept %s." % G.money(ask), "counter": ask}
	return {"ok": false, "msg": "Rejected. The owners consider the offer far too low."}


## Transfers ownership of all assets and liabilities exactly once.
static func execute(buyer: Dictionary, target: Dictionary, price: float) -> void:
	var bid: String = buyer["id"]
	var tid: String = target["id"]
	var tf: Dictionary = target["fin"]
	var net_assets := FinanceEngine.assets(target) - float(tf["debt"])
	# pay sellers
	FinanceEngine.cash(buyer, -price)
	# cash, PP&E, debt
	FinanceEngine.cash(buyer, float(tf["cash"]))
	buyer["fin"]["ppe"] = float(buyer["fin"]["ppe"]) + float(tf["ppe"])
	buyer["fin"]["goodwill"] = float(buyer["fin"]["goodwill"]) + float(tf["goodwill"])
	buyer["fin"]["debt"] = float(buyer["fin"]["debt"]) + float(tf["debt"])
	var gw := price - net_assets
	if gw >= 0.0:
		buyer["fin"]["goodwill"] = float(buyer["fin"]["goodwill"]) + gw
	else:
		FinanceEngine.pl(buyer, "other_income", -gw)
	# raw inventory
	for id in target["raw"]:
		var a: Array = target["raw"][id]
		FinanceEngine.add_raw(buyer, id, float(a[0]), float(a[0]) * float(a[1]))
	target["raw"] = {}
	for k in ["cash", "ppe", "goodwill", "debt", "paid_in", "retained"]:
		tf[k] = 0.0
	# operational records
	for b in G.s["brands"].values():
		if b["company"] == tid:
			b["company"] = bid
			b["independent"] = true
			b["acquired"] = G.week()
	for p in G.s["products"].values():
		if p["company"] == tid:
			p["company"] = bid
			CompanyEngine.plog(p, "Now owned by %s." % buyer["name"])
	for f in G.s["formulas"].values():
		if f["company"] == tid:
			f["company"] = bid
	for o in G.s["orders"]:
		if o["company"] == tid:
			o["company"] = bid
	for d in G.s["deliveries"]:
		if d["company"] == tid:
			d["company"] = bid
	for k in G.s["campaigns"]:
		if k["company"] == tid:
			k["company"] = bid
	for ln in G.s["loans"]:
		if ln["company"] == tid:
			ln["company"] = bid
	for k in G.s["contracts"]:
		if k["company"] == tid:
			k["company"] = bid
	for md in G.s["media"].values():
		if md.get("contract", {}).get("company", "") == tid:
			md["contract"]["company"] = bid
	var moved := 0
	for e in G.s["employees"].values():
		if e.get("employer", "") == tid:
			e["employer"] = bid
			e["motivation"] = clampf(float(e["motivation"]) - 0.1, 0.0, 1.0)
			Staff.note(e, "Became part of %s after the acquisition." % buyer["name"])
			moved += 1
	for cid in target["offices"]:
		var o: Dictionary = target["offices"][cid]
		if buyer["offices"].has(cid):
			buyer["offices"][cid]["level"] = maxi(int(buyer["offices"][cid]["level"]), int(o["level"]))
		else:
			o["hq"] = false
			buyer["offices"][cid] = o
	target["offices"] = {}
	var seen := {}
	for a in G.s["channels"]:
		if a["company"] == bid and a.get("active", true):
			seen[a["country"] + a["ch"]] = a
	for a in G.s["channels"]:
		if a["company"] == tid:
			a["company"] = bid
			var k2: String = a["country"] + a["ch"]
			if seen.has(k2):
				if float(a["q"]) > float(seen[k2]["q"]):
					seen[k2]["active"] = false
					seen[k2] = a
				else:
					a["active"] = false
			else:
				seen[k2] = a
	for id in target["unlocked"]:
		buyer["unlocked"][id] = true
	target["active"] = false
	target["acquired_by"] = bid
	FinanceEngine.spend(buyer, "integration", price * 0.03)
	buyer["integrating"] = 12
	G.cache.erase("reach")
	G.s["deals"].append({"w": G.week(), "kind": "acquisition", "text": "%s acquired %s for %s" % [buyer["name"], target["name"], G.money(price)]})
	if G.is_player(bid):
		G.log_event("Acquisition complete: %s is now part of %s (%d employees joined)." % [target["name"], buyer["name"], moved], "good")
		if Staff.count(bid) > Staff.capacity(buyer):
			G.inbox_add({"type": "info", "title": "Headquarters over capacity",
				"text": "After the acquisition you employ %d people but your headquarters is designed for %d. Upgrade or restructure; overcrowding lowers motivation." % [Staff.count(bid), Staff.capacity(buyer)]})
	else:
		G.log_event("Industry: %s acquired %s." % [buyer["name"], target["name"]], "info", "*")


# ---------------------------------------------------------------- brands
static func brand_value(b: Dictionary) -> float:
	var rev := 0.0
	for p in G.s["products"].values():
		if p["brand"] == b["id"]:
			for x in p["wk"].slice(maxi(0, p["wk"].size() - 52)):
				rev += float(x[2])
	var aw := 0.0
	for k in b["aw"]:
		aw += float(b["aw"][k])
	return maxf(50000.0, rev * (1.0 + 2.0 * float(b["prestige"])) + aw * 4e5)


static func brand_products(bid: String) -> Array:
	return G.s["products"].values().filter(func(p): return p["brand"] == bid)


static func create_brand(c: Dictionary, name: String, posit: String, color: String, logo: int) -> String:
	var cap := int(DB.hq_tier(int(c["hq"]["tier"]))["brands"])
	if G.company_brands(c["id"]).size() >= cap:
		return "Your headquarters supports %d brands. Upgrade to add more." % cap
	var cost := 50000.0
	if FinanceEngine.cash_of(c) < cost:
		return "Creating a brand costs %s (identity, trademarks)." % G.money(cost)
	if name.strip_edges().length() < 2:
		return "Enter a brand name."
	FinanceEngine.spend(c, "marketing", cost)
	var b := CompanyEngine.make_brand(c["id"], name.strip_edges(), posit, color, 0.1, logo)
	b["markets"] = [c["home"]]
	CompanyEngine.set_brand_aw(b, c["home"], 0.003)
	G.log_event("New brand created: %s (%s)." % [b["name"], DB.positionings[posit]["name"]], "good")
	return ""


static func sell_brand(c: Dictionary, b: Dictionary) -> String:
	if G.company_brands(c["id"]).size() <= 1:
		return "You cannot sell your only brand."
	var price := brand_value(b)
	var buyer: Dictionary = {}
	for rc in G.s["companies"].values():
		if not rc.get("is_player", false) and rc.get("active", true) and FinanceEngine.cash_of(rc) > price * 1.3:
			if buyer.is_empty() or FinanceEngine.cash_of(rc) > FinanceEngine.cash_of(buyer):
				buyer = rc
	if buyer.is_empty():
		return "No rival can currently afford %s." % G.money(price)
	var book := 0.0
	for p in brand_products(b["id"]):
		book += float(p["inv"]) * float(p["unit_cost"])
		for o in G.s["orders"]:
			if o["product"] == p["id"] and o["stage"] != "done":
				book += float(o["value"])
	FinanceEngine.cash(c, price)
	FinanceEngine.pl(c, "other_income", price - book)
	FinanceEngine.cash(buyer, -price)
	buyer["fin"]["goodwill"] = float(buyer["fin"]["goodwill"]) + (price - book)
	for p in brand_products(b["id"]):
		p["company"] = buyer["id"]
		for o in G.s["orders"]:
			if o["product"] == p["id"]:
				o["company"] = buyer["id"]
		var f := G.formula(p["formula"])
		if not f.is_empty():
			f["company"] = buyer["id"]
	for k in G.s["campaigns"]:
		if k["brand"] == b["id"]:
			k["status"] = "ended"
	b["company"] = buyer["id"]
	b["budget"] = 0.0
	G.s["deals"].append({"w": G.week(), "kind": "brand_sale", "text": "Sold %s to %s for %s" % [b["name"], buyer["name"], G.money(price)]})
	G.log_event("Sold brand %s to %s for %s." % [b["name"], buyer["name"], G.money(price)], "good")
	return ""


static func discontinue_brand(c: Dictionary, b: Dictionary) -> String:
	if G.company_brands(c["id"]).size() <= 1:
		return "You cannot discontinue your only brand."
	for p in brand_products(b["id"]):
		if p["status"] != "discontinued":
			p["status"] = "discontinued"
			p["disc_week"] = G.week()
		var inv := int(p["inv"])
		if inv > 0:
			# clearance to discounters at 40% of cost
			var val := float(inv) * float(p["unit_cost"])
			FinanceEngine.cash(c, val * 0.4)
			FinanceEngine.pl(c, "writeoff", -val * 0.6)
			p["inv"] = 0
	b["status"] = "discontinued"
	b["budget"] = 0.0
	G.log_event("Brand %s discontinued; remaining stock cleared." % b["name"], "warn")
	return ""


## Rare rival consolidation: a cash-rich rival buys a distressed one.
static func rival_mna(r: RandomNumberGenerator) -> void:
	if G.week() < 260 or r.randf() > 0.25:
		return
	var weak: Array = []
	var rich: Array = []
	for c in G.s["companies"].values():
		if c.get("is_player", false) or not c.get("active", true):
			continue
		var t := FinanceEngine.ttm(c)
		if float(t["net"]) < 0.0:
			weak.append(c)
		elif FinanceEngine.cash_of(c) > 2e7:
			rich.append(c)
	if weak.is_empty() or rich.is_empty():
		return
	var tgt: Dictionary = G.pick(weak, r)
	var buyer: Dictionary = G.pick(rich, r)
	var price := ask_price(tgt)
	if FinanceEngine.cash_of(buyer) > price * 1.5:
		execute(buyer, tgt, price)
