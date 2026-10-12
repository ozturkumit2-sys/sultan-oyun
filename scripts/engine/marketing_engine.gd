class_name MarketingEngine
extends RefCounted
## Fictional in-game advertising: campaigns, influencers, celebrity ambassadors, launch PR and critics.
## Spending raises awareness with diminishing returns; awareness does not guarantee conversion.


static func K(k: String) -> float:
	return float(DB.bal["marketing"].get(k, 0.0))


## Segment-weight vector describing who a product appeals to in a country (softmax of appeal × market weights).
static func audience_weights(p: Dictionary, country: String) -> PackedFloat32Array:
	var ev = MarketEngine.product_ev(p)
	var ns := DB.segments.size()
	var out := PackedFloat32Array()
	out.resize(ns)
	if ev.is_empty():
		out.fill(1.0 / float(ns))
		return out
	var base := ConsumerEngine.seg_base(ev)
	var segw: Dictionary = DB.country(country)["seg"]
	var tot := 0.0
	for i in ns:
		var v := float(segw.get(DB.segments[i]["id"], 0.0)) * exp(clampf(float(base["appeal"][i]), -5.0, 5.0))
		out[i] = v
		tot += v
	for i in ns:
		out[i] /= maxf(0.0001, tot)
	return out


static func attr_fit(p: Dictionary, country: String, attr: String) -> float:
	if attr == "none" or p.is_empty():
		return 1.0
	var w := audience_weights(p, country)
	var f := 0.0
	var mean := 0.0
	for i in DB.segments.size():
		f += w[i] * float(DB.segments[i].get(attr, 0.5))
		mean += float(DB.segments[i].get(attr, 0.5)) / float(DB.segments.size())
	return clampf(0.55 + 0.45 * f / maxf(0.05, mean), 0.4, 1.6)


static func media_fit(p: Dictionary, country: String, md: Dictionary) -> float:
	var w := audience_weights(p, country)
	var aud: Dictionary = md["aud"]
	var f := 0.0
	for i in DB.segments.size():
		f += w[i] * float(aud.get(DB.segments[i]["id"], 0.0))
	return clampf(0.3 + f * 4.0, 0.2, 1.8)


static func power(cid: String) -> float:
	var integ := 0.9 if int(G.company(cid).get("integrating", 0)) > 0 else 1.0
	return integ * (1.0 + K("mm_k") * Staff.best_skill(cid, "marketing_manager") + K("dept_k") * float(CompanyEngine.dept_level(cid, "marketing") - 1))


static func start(cid: String, kind: String, pid: String, brand_id: String, markets: Array, weekly: float, weeks: int, media_id := "") -> String:
	var c := G.company(cid)
	var t: Dictionary = DB.campaigns.get(kind, {})
	if kind != "influencer" and kind != "celebrity":
		if t.is_empty():
			return "Unknown campaign type."
		if weekly < float(t["min"]):
			return "Minimum budget for %s is %s per week." % [t["name"], G.money(float(t["min"]))]
	if markets.is_empty():
		return "Choose at least one market."
	var upfront := 0.0
	if kind == "influencer":
		var md: Dictionary = G.s["media"].get(media_id, {})
		if md.is_empty() or (md.get("contract", {}).get("company", "") != "" and int(md["contract"].get("until", 0)) > G.week()):
			return "Not available."
		upfront = float(md["fee"])
		weeks = 4
		weekly = upfront / 4.0
	if kind == "celebrity":
		var md2: Dictionary = G.s["media"].get(media_id, {})
		if md2.is_empty() or (md2.get("contract", {}).get("company", "") != "" and int(md2["contract"].get("until", 0)) > G.week()):
			return "Not available."
		weekly = float(md2["fee"])
		upfront = weekly * 4.0
		md2["contract"] = {"company": cid, "until": G.week() + weeks, "brand": brand_id, "product": pid}
	if G.is_player(cid) and FinanceEngine.cash_of(c) < maxf(upfront, weekly):
		return "Not enough cash."
	if kind == "influencer":
		FinanceEngine.spend(c, "marketing", upfront)
		G.s["media"][media_id]["contract"] = {"company": cid, "until": G.week() + 4, "brand": brand_id, "product": pid}
	if kind == "celebrity":
		FinanceEngine.spend(c, "marketing", upfront)
	var camp := {"id": G.new_id("k"), "company": cid, "kind": kind, "product": pid, "brand": brand_id, "markets": markets,
		"weekly": weekly, "weeks_left": weeks, "weeks": weeks, "spent": upfront, "start": G.week(), "media": media_id,
		"contrib": {}, "attr_rev": 0.0, "attr_gp": 0.0, "status": "active", "reach": 0.0}
	G.s["campaigns"].append(camp)
	if pid != "":
		var p := G.product(pid)
		p["campaigns"].append(camp["id"])
		if G.is_player(cid):
			CompanyEngine.plog(p, "%s campaign started (%s/week, %d weeks)." % [kind_name(camp), G.money(weekly), weeks])
	return ""


static func kind_name(camp: Dictionary) -> String:
	if camp["kind"] == "influencer":
		return "Influencer (%s)" % G.s["media"].get(camp["media"], {}).get("handle", "?")
	if camp["kind"] == "celebrity":
		return "Ambassador (%s)" % G.s["media"].get(camp["media"], {}).get("name", "?")
	return DB.campaigns.get(camp["kind"], {}).get("name", camp["kind"])


static func stop(camp: Dictionary) -> void:
	camp["status"] = "ended"
	camp["weeks_left"] = 0
	if camp["kind"] == "celebrity":
		var md: Dictionary = G.s["media"].get(camp["media"], {})
		if not md.is_empty():
			var c := G.company(camp["company"])
			FinanceEngine.spend(c, "marketing", float(md["fee"]) * 4.0)
			md["contract"] = {}


static func weekly(rep: Dictionary) -> void:
	for camp in G.s["campaigns"]:
		if camp["status"] != "active":
			_decay_contrib(camp)
			continue
		var c := G.company(camp["company"])
		if c.is_empty() or not c.get("active", true):
			camp["status"] = "ended"
			continue
		var weekly_cost := float(camp["weekly"])
		var first := int(camp["start"]) == G.week() - 1 or int(camp["start"]) == G.week()
		if camp["kind"] == "influencer":
			weekly_cost = 0.0   # paid upfront
		elif camp["kind"] == "celebrity" and first:
			weekly_cost = 0.0
		if weekly_cost > 0.0:
			FinanceEngine.spend(c, "marketing", weekly_cost)
			camp["spent"] = float(camp["spent"]) + weekly_cost
		_apply(camp, c)
		camp["weeks_left"] = int(camp["weeks_left"]) - 1
		if int(camp["weeks_left"]) <= 0:
			camp["status"] = "ended"
			if camp["kind"] == "celebrity":
				var md: Dictionary = G.s["media"].get(camp["media"], {})
				if not md.is_empty():
					md["contract"] = {}
				G.log_event("Ambassador contract with %s ended." % md.get("name", "?"), "info", camp["company"])
		_attribute(camp)
	# brand always-on budgets
	for b in G.s["brands"].values():
		if b.get("status", "active") != "active" or float(b.get("budget", 0.0)) <= 0.0:
			continue
		var c := G.company(b["company"])
		var bud := float(b["budget"])
		if FinanceEngine.cash_of(c) < bud * 2.0 and G.is_player(c["id"]):
			continue
		FinanceEngine.spend(c, "marketing", bud)
		var mk: Array = b.get("markets", [])
		if mk.is_empty():
			mk = [c["home"]]
		var tot_b := 0.0
		for cid in mk:
			tot_b += MarketEngine.buyers(cid, G.week())
		for cid in mk:
			var B = MarketEngine.buyers(cid, G.week())
			var S = bud * B / maxf(1.0, tot_b)
			var X = S * 0.8 * power(c["id"]) / (float(DB.country(cid)["opcost"]) * B * MarketEngine.M("aw_cost"))
			var aw := CompanyEngine.brand_aw(b, cid)
			CompanyEngine.set_brand_aw(b, cid, aw + (1.0 - aw) * (1.0 - exp(-X)) * 0.8)


static func _apply(camp: Dictionary, c: Dictionary) -> void:
	var p := G.product(camp["product"]) if camp["product"] != "" else {}
	var b := G.brand(camp["brand"]) if camp["brand"] != "" else (G.brand(p.get("brand", "")) if not p.is_empty() else {})
	var t: Dictionary = DB.campaigns.get(camp["kind"], {})
	var pw := power(c["id"])
	var markets: Array = camp["markets"]
	var tot_b := 0.0
	for cid in markets:
		tot_b += MarketEngine.buyers(cid, G.week())
	var md: Dictionary = G.s["media"].get(camp.get("media", ""), {})
	for cid in markets:
		var B = MarketEngine.buyers(cid, G.week())
		var S = float(camp["weekly"]) * B / maxf(1.0, tot_b)
		var ct := DB.country(cid)
		var eff := float(t.get("eff", 1.0))
		var fit := 1.0
		var buzz_k := float(t.get("buzz", 0.0))
		var X := 0.0
		if camp["kind"] == "influencer" or camp["kind"] == "celebrity":
			if not md["markets"].has(cid):
				continue
			fit = media_fit(p, cid, md) if not p.is_empty() else 1.0
			var share := 1.0 / float(md["markets"].size())
			var exposure := float(md["followers"]) * share * float(md["engagement"]) * float(md["reputation"])
			X = exposure / (B * MarketEngine.M("pop_mult")) * K("influencer_k") * (1.0 if camp["kind"] == "influencer" else K("celeb_aw"))
			buzz_k = 0.5 if camp["kind"] == "influencer" else 0.35
		else:
			if not p.is_empty():
				fit = attr_fit(p, cid, t.get("attr", "none"))
			X = S * eff * pw / (float(ct["opcost"]) * B * MarketEngine.M("aw_cost"))
		# diminishing returns from saturation
		var load_key = "load_" + cid
		var holder: Dictionary = p if not p.is_empty() else b
		var load := float(holder.get(load_key, 0.0))
		X /= 1.0 + load * K("load_k")
		holder[load_key] = load + S / maxf(1.0, B * 10.0)
		var gain := 0.0
		if not p.is_empty():
			var m := CompanyEngine.mk(p, cid)
			var aw := float(m["aw"])
			gain = (1.0 - aw) * (1.0 - exp(-X)) * fit
			m["aw"] = clampf(aw + gain, 0.0, 0.95)
			m["buzz"] = clampf(float(m["buzz"]) + buzz_k * (1.0 - exp(-3.0 * X)) * fit, 0.0, 1.0)
			var conv := float(t.get("conv", 0.0))
			if conv > 0.0:
				m["conv"] = maxf(float(m["conv"]), conv * (1.0 - exp(-S / maxf(1.0, B * 0.3))))
			if t.get("trial", false):
				var samples = S / 1.0
				m["triers"] = float(m["triers"]) + samples * 0.5
				var ev = MarketEngine.product_ev(p)
				var ps := 0.0
				var w := audience_weights(p, cid)
				for i in DB.segments.size():
					ps += w[i] * ConsumerEngine.p_sat(ConsumerEngine.satisfaction_full(ev, i, cid, 0.0, 0.0))
				m["loyal"] = float(m["loyal"]) + samples * 0.5 * ps * 0.2
				m["sat"] = lerpf(float(m["sat"]), ps, 0.1)
		if not b.is_empty():
			var baw := CompanyEngine.brand_aw(b, cid)
			var bg := (1.0 - baw) * (1.0 - exp(-X)) * (0.4 if not p.is_empty() else 1.0)
			CompanyEngine.set_brand_aw(b, cid, baw + bg)
			var pr := float(t.get("prestige", 0.0))
			if camp["kind"] == "celebrity":
				pr = K("celeb_prestige") * (float(md["reputation"]) - 0.4) * 2.0 * (1.5 if float(md["followers"]) > 5e6 else 1.0)
			if pr != 0.0:
				var cap := float(DB.positionings[b["posit"]]["prestige_cap"])
				var scale := minf(1.0, S / maxf(1.0, float(t.get("min", 1000.0))))
				b["prestige"] = clampf(float(b["prestige"]) + pr * scale * (1.0 if float(b["prestige"]) < cap else -0.5), 0.0, cap)
			if gain == 0.0:
				gain = bg * 0.3
		var cb: Dictionary = camp["contrib"]
		cb[cid] = float(cb.get(cid, 0.0)) + gain
		camp["reach"] = float(camp["reach"]) + (1.0 - exp(-X)) * B * MarketEngine.M("pop_mult")


static func _decay_contrib(camp: Dictionary) -> void:
	var cb: Dictionary = camp.get("contrib", {})
	var any := false
	for k in cb:
		cb[k] = float(cb[k]) * (1.0 - ConsumerEngine.C("aw_decay"))
		if float(cb[k]) > 0.0005:
			any = true
	if any:
		_attribute(camp)


## Estimated revenue influence: product revenue × share of current awareness created by this campaign.
static func _attribute(camp: Dictionary) -> void:
	var p := G.product(camp["product"])
	if p.is_empty():
		return
	var cb: Dictionary = camp["contrib"]
	var wk: Array = p["wk"]
	if wk.is_empty():
		return
	var last: Array = wk[wk.size() - 1]
	# attribute each week of sales once (marketing runs before the market in the weekly order)
	if int(last[0]) <= int(camp.get("attr_w", -1)) or int(last[0]) < G.week() - 1:
		return
	camp["attr_w"] = int(last[0])
	var units_tot := maxf(1.0, float(last[1]))
	for cid in cb:
		var m: Dictionary = p["mk"].get(cid, {})
		var aw := float(m.get("aw", 0.0))
		if aw <= 0.0:
			continue
		var share := clampf(float(cb[cid]) / aw, 0.0, 1.0)
		var frac := float(m.get("last", 0)) / units_tot
		camp["attr_rev"] = float(camp["attr_rev"]) + float(last[2]) * frac * share
		camp["attr_gp"] = float(camp["attr_gp"]) + float(last[3]) * frac * share


static func roi(camp: Dictionary) -> float:
	var sp := float(camp["spent"])
	if sp <= 0.0:
		return 0.0
	return (float(camp["attr_gp"]) - sp) / sp


static func on_launch(p: Dictionary) -> void:
	var c := G.company(p["company"])
	var budget := float(p.get("launch_budget", 0.0))
	if budget > 0.0:
		var weekly := budget / 4.0
		var split: Array = DB.bal["marketing"]["launch_split"]
		var pr_w := weekly * float(split[1])
		if pr_w >= float(DB.campaigns["pr"]["min"]):
			start(p["company"], "social", p["id"], p["brand"], p["markets"], maxf(500.0, weekly - pr_w), 4)
			start(p["company"], "pr", p["id"], p["brand"], p["markets"], pr_w, 4)
		else:
			start(p["company"], "social", p["id"], p["brand"], p["markets"], maxf(500.0, weekly), 4)
		p["launch_budget"] = 0.0
	# critics may review new launches
	var b := G.brand(p["brand"])
	var r := G.rng
	var pr := false
	for camp in G.s["campaigns"]:
		if camp["product"] == p["id"] and (camp["kind"] == "pr" or camp["kind"] == "event"):
			pr = true
	var chance := K("critic_base") + 0.5 * float(b.get("prestige", 0.0)) + (0.35 if pr else 0.0)
	var ev = MarketEngine.product_ev(p)
	if ev.is_empty():
		return
	for critic in DB.names["critics"]:
		if r.randf() < chance:
			var cr := ReviewEngine.critic_review(critic, ev, float(p.get("mk_nov_" + str(p["markets"][0]), 0.35)), r)
			p["critics"].append(cr)
			for cid in p["markets"]:
				var m := CompanyEngine.mk(p, cid)
				m["buzz"] = clampf(float(m["buzz"]) + (float(cr["score"]) - 6.0) * 0.03, 0.0, 1.0)
	if G.is_player(p["company"]) and not p["critics"].is_empty():
		G.log_event("%d critics reviewed %s." % [p["critics"].size(), p["name"]], "info")


# ---------------------------------------------------------------- media roster
static func gen_media(r: RandomNumberGenerator) -> Dictionary:
	var out := {}
	var tiers := [["Micro", 10000, 90000, 800, 3500], ["Mid-tier", 100000, 600000, 4000, 15000], ["Macro", 700000, 3500000, 18000, 60000], ["Superstar", 5000000, 40000000, 90000, 350000]]
	var counts := [12, 10, 7, 3]
	var countries: Array = DB.country_by_id.keys()
	var seg_ids: Array = []
	for sg in DB.segments:
		seg_ids.append(sg["id"])
	for ti in tiers.size():
		for n in counts[ti]:
			var tier: Array = tiers[ti]
			var fol := int(r.randf_range(float(tier[1]), float(tier[2])))
			var home: String = G.pick(countries, r)
			var mk := [home]
			if ti >= 2:
				for k in r.randi_range(1, 3):
					var x: String = G.pick(countries, r)
					if not mk.has(x):
						mk.append(x)
			var aud := {}
			var focus: Array = [G.pick(seg_ids, r), G.pick(seg_ids, r)]
			for sid in seg_ids:
				aud[sid] = 0.04 + (0.25 if focus.has(sid) else 0.0) + r.randf() * 0.04
			var handle := "@%s%s" % [G.pick(DB.names["handles_a"], r), G.pick(DB.names["handles_b"], r)]
			var pnat: Dictionary = DB.names["people"].get(home, DB.names["people"]["US"])
			var nm := "%s %s" % [G.pick(pnat["f"] if r.randf() < 0.6 else pnat["m"], r), G.pick(pnat["l"], r)]
			var eng := r.randf_range(0.02, 0.09) * (1.4 if ti == 0 else 1.0)
			var id := "md%d_%d" % [ti, n]
			out[id] = {"id": id, "kind": "influencer", "name": nm, "handle": handle, "tier": tier[0], "followers": fol,
				"markets": mk, "aud": aud, "engagement": snappedf(eng, 0.001), "reputation": snappedf(r.randf_range(0.55, 0.95), 0.01),
				"fee": snappedf(r.randf_range(float(tier[3]), float(tier[4])), 100.0), "contract": {}, "focus": focus}
	var celebs: Array = DB.names["celebs"]
	for i in celebs.size():
		var home2: String = G.pick(countries, r)
		var mk2 := [home2]
		for k in r.randi_range(2, 5):
			var x2: String = G.pick(countries, r)
			if not mk2.has(x2):
				mk2.append(x2)
		var aud2 := {}
		for sid in seg_ids:
			aud2[sid] = 0.06 + r.randf() * 0.12
		aud2["luxury"] = float(aud2["luxury"]) + 0.1
		aud2["trend"] = float(aud2["trend"]) + 0.1
		var id2 := "cel%d" % i
		var fol2 := int(r.randf_range(3e6, 80e6))
		out[id2] = {"id": id2, "kind": "celebrity", "name": celebs[i], "handle": str(G.pick(DB.names["celeb_roles"], r)), "tier": "Celebrity",
			"followers": fol2, "markets": mk2, "aud": aud2, "engagement": snappedf(r.randf_range(0.01, 0.04), 0.001),
			"reputation": snappedf(r.randf_range(0.6, 0.95), 0.01), "fee": snappedf(float(fol2) / 1e6 * r.randf_range(900.0, 1600.0) + 8000.0, 500.0),
			"contract": {}, "volatility": snappedf(r.randf_range(0.002, 0.012), 0.001)}
	return out


## Celebrity reputation drifts; rare scandals affect associated brands.
static func media_weekly(r: RandomNumberGenerator) -> void:
	for md in G.s["media"].values():
		md["reputation"] = clampf(float(md["reputation"]) + r.randfn(0.0, 0.004) + (0.7 - float(md["reputation"])) * 0.01, 0.05, 0.99)
		var ct: Dictionary = md.get("contract", {})
		if md["kind"] == "celebrity" and r.randf() < float(md.get("volatility", 0.005)):
			md["reputation"] = clampf(float(md["reputation"]) - r.randf_range(0.2, 0.4), 0.05, 0.99)
			if not ct.is_empty() and int(ct.get("until", 0)) > G.week():
				var b := G.brand(ct.get("brand", ""))
				if not b.is_empty():
					b["prestige"] = clampf(float(b["prestige"]) - 0.03, 0.0, 1.0)
					if G.is_player(ct["company"]):
						G.inbox_add({"type": "scandal", "media": md["id"], "title": "Controversy: " + md["name"],
							"text": "%s is at the center of a public controversy. Your brand %s is associated with them. Terminate the contract (penalty: 4 weeks of fees) or stand by them?" % [md["name"], b["name"]]})
			elif G.is_player(G.pid()) and r.randf() < 0.3:
				G.log_event("Media: %s faces a public controversy." % md["name"], "info", "*")
