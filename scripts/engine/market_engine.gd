class_name MarketEngine
extends RefCounted
## Centralized deterministic weekly market: weighted consumer cohorts (country × segment × label group)
## choose among considered products with a multinomial logit including an outside option.
## Sales are capped by inventory; unmet demand is recorded as lost sales.


static func M(k: String) -> float:
	return float(DB.bal["market"].get(k, 0.0))


static func buyers(country: String, w: int) -> float:
	var ct := DB.country(country)
	var mm := float(DB.month_demand[G.month_of(w)])
	var gr := pow(1.0 + ConsumerEngine.C("growth_year"), float(w) / 52.0)
	var mkt: Dictionary = G.s["markets"].get(country, {})
	return float(ct["buyers"]) * M("buyers_scale") * mm * gr * float(mkt.get("size", 1.0))


static func avg_rate(country: String) -> float:
	var segw: Dictionary = DB.country(country)["seg"]
	var t := 0.0
	for sg in DB.segments:
		t += float(segw.get(sg["id"], 0.0)) * float(sg["rate"])
	return t


static func is_selling(p: Dictionary) -> bool:
	return p["status"] == "active" and p.get("launched", false)


static func product_ev(p: Dictionary) -> Dictionary:
	var key := "pev|" + str(p["id"]) + "|" + str(p["fv"]) + "|" + str(p.get("maturation", 0))
	if G.cache.has(key):
		return G.cache[key]
	var ev: Dictionary
	if p.get("kind", "") == "discovery" and not p.get("set", []).is_empty():
		ev = _discovery_ev(p)
	else:
		ev = FormulaEngine.evaluate_product(p)
	G.cache[key] = ev
	return ev


static func _discovery_ev(p: Dictionary) -> Dictionary:
	## A discovery set is judged by its best-matching member for each segment, plus curiosity value.
	var evs: Array = []
	for fid in p["set"]:
		var fv := G.formula_version(fid)
		if not fv.is_empty():
			evs.append(FormulaEngine.evaluate(fv["items"], p["fmt"], float(p["conc"])))
	if evs.is_empty():
		return {}
	var ev: Dictionary = evs[0].duplicate()
	var ns := DB.segments.size()
	var ap := PackedFloat32Array()
	var sa := PackedFloat32Array()
	ap.resize(ns)
	sa.resize(ns)
	for i in ns:
		var best_a := -99.0
		var best_s := -99.0
		for e in evs:
			var sb := ConsumerEngine.seg_base(e)
			best_a = maxf(best_a, float(sb["appeal"][i]))
			best_s = maxf(best_s, float(sb["sat"][i]))
		var sg: Dictionary = DB.segments[i]
		ap[i] = best_a + 0.4 * float(sg["novelty"]) + 0.2
		sa[i] = best_s
	ev["_seg"] = {"appeal": ap, "sat": sa}
	ev["complexity"] = 0.7
	return ev


## Country-independent utility parts per segment (cached for the week): appeal + brand + packaging.
static func _pbase(p: Dictionary, ev: Dictionary, b: Dictionary) -> PackedFloat32Array:
	var key := "pb|" + str(p["id"])
	if G.cache.has(key):
		return G.cache[key]
	var ns := DB.segments.size()
	var base := ConsumerEngine.seg_base(ev)
	var prestige := float(b.get("prestige", 0.3))
	var posit: String = b.get("posit", "mass")
	var ed: String = p.get("edition", {}).get("type", "regular")
	var small: bool = p.get("kind", "") == "travel" or p.get("kind", "") == "sample"
	var out := PackedFloat32Array()
	out.resize(ns)
	for i in ns:
		var sg: Dictionary = DB.segments[i]
		var u := float(base["appeal"][i])
		u += ConsumerEngine.brand_term(prestige, posit, sg)
		u += ConsumerEngine.pack_term(p["pack"], float(p["price"]), float(p["volume"]), sg, ed)
		if small:
			u += 0.25 * (1.0 - float(sg["brand_sens"]))
		out[i] = u
	G.cache[key] = out
	return out


## Value-for-money term per segment in a country.
static func value_terms(p: Dictionary, b: Dictionary, country: String) -> PackedFloat32Array:
	var ns := DB.segments.size()
	var out := PackedFloat32Array()
	out.resize(ns)
	var C := ConsumerEngine
	var pp := C.price_pp(float(p["price"]), float(p["volume"]))
	var ppp := float(DB.country(country).get("ppp", 1.0))
	var fm := float(DB.formats.get(p["fmt"], {}).get("ref_mult", 1.0))
	var posit: String = b.get("posit", "mass")
	var pa := float(DB.bal["consumer"]["posit_accept"].get(posit, 1.0))
	var common := (0.4 + 0.6 * ppp) * fm * pa * (0.75 + 0.5 * float(b.get("prestige", 0.3)))
	var gain := C.C("price_gain")
	var cheap := C.C("cheap_lux")
	for i in ns:
		var sg: Dictionary = DB.segments[i]
		var ref := float(sg["price_ref"]) * common
		var r := log(maxf(0.01, pp) / ref)
		var ps := float(sg["price_sens"])
		var t := -ps * r if r > 0.0 else -ps * gain * r
		if ps <= 0.6 and pp < 0.4 * ref:
			t -= cheap * (0.4 * ref / maxf(1.0, pp) - 1.0)
		out[i] = t
	return out


## Performance fit (longevity + projection) per segment in a country; depends only on the formula, so cached.
static func perf_terms(p: Dictionary, ev: Dictionary, country: String) -> PackedFloat32Array:
	var key := "pev|pf|%s|%s|%s|%s" % [p["id"], str(p["fv"]), str(p.get("maturation", 0)), country]
	if G.cache.has(key):
		return G.cache[key]
	var ns := DB.segments.size()
	var out := PackedFloat32Array()
	out.resize(ns)
	for i in ns:
		var pf := ConsumerEngine.perf_fit(ev, DB.segments[i], country)
		out[i] = float(pf["long"]) + float(pf["proj"])
	G.cache[key] = out
	return out


## Purchase utility for each segment of a product in a country (excluding label affinity and consideration).
static func utilities(p: Dictionary, ev: Dictionary, b: Dictionary, country: String, novelty: float, vt: PackedFloat32Array = PackedFloat32Array()) -> PackedFloat32Array:
	var ns := DB.segments.size()
	var pb := _pbase(p, ev, b)
	var adj := ConsumerEngine.country_adj(ev, country, G.week(), novelty)
	var v := value_terms(p, b, country)
	if vt.size() == ns:
		for i in ns:
			vt[i] = v[i]
	var m := CompanyEngine.mk(p, country)
	var rating: Dictionary = p["rating"]
	var rn := int(rating["n"])
	var ravg := float(rating["sum"]) / float(rn) if rn > 0 else 3.6
	var fam := clampf(float(m["triers"]) / maxf(1.0, buyers(country, G.week()) * 0.6), 0.0, 1.0)
	var C := ConsumerEngine
	var bz := C.C("buzz_k") * float(m["buzz"])
	var rv := C.C("review_k") * (ravg - 3.6) if rn >= 8 else 0.0
	var common := C.C("fam_k") * fam * (float(m["sat"]) - 0.5) + C.C("conv_k") * float(m["conv"])
	var ed: Dictionary = p.get("edition", {})
	if ed.get("type", "") == "seasonal":
		var sm := ConsumerEngine.summerness(country, G.week())
		var in_season := sm > 0.2 if ed.get("season", "summer") == "summer" else (G.month_of(G.week()) in [10, 11, 0])
		common += 0.35 if in_season else -1.2
	var out := PackedFloat32Array()
	out.resize(ns)
	for i in ns:
		var soc := float(DB.segments[i]["social"])
		out[i] = pb[i] + adj[i] + v[i] + bz * soc + rv * (0.5 + 0.5 * soc) + common
	return out


static func run_week(rep: Dictionary) -> void:
	var w := G.week()
	var ns := DB.segments.size()
	var prods: Array = []
	for p in G.s["products"].values():
		if is_selling(p):
			prods.append(p)
	var C := ConsumerEngine
	var sims := similar_map(prods)
	var D: Dictionary = {}          # pid -> {country: [new_demand, repeat_demand, seg_units(PackedFloat32Array), utils]}
	var share_tot: Dictionary = {}  # country -> {company: units}
	for ct in DB.countries:
		var cid: String = ct["id"]
		var plist: Array = []
		for p in prods:
			if p["markets"].has(cid) and int(p.get("inv", 0)) + int(_open_supply(p)) >= 0:
				plist.append(p)
		if plist.is_empty():
			continue
		var B := buyers(cid, w)
		var ar := avg_rate(cid)
		var segw: Dictionary = ct["seg"]
		var mkt: Dictionary = G.s["markets"][cid]
		var avgp := G.to_vec(mkt.get("avg", []))
		var u0 := C.C("outside") + C.C("competition_k") * (float(ct["competition"]) - 1.0)
		var e0 := exp(u0)
		var n := plist.size()
		var U: Array = []
		var CONS: Array = []
		var AUD: Array = []
		var VT: Array = []
		for p in plist:
			var ev := product_ev(p)
			var b := G.brand(p["brand"])
			var nov := 0.3
			if avgp.size() > 0:
				nov = clampf((1.0 - G.vcos(ev["profile"], avgp)) * M("novelty_k"), 0.0, 1.0)
			p["mk_nov_" + cid] = nov
			var vtp := PackedFloat32Array()
			vtp.resize(ns)
			var uu := utilities(p, ev, b, cid, nov, vtp)
			VT.append(vtp)
			var m := CompanyEngine.mk(p, cid)
			var aw_b := CompanyEngine.brand_aw(b, cid)
			var aw := 1.0 - (1.0 - float(m["aw"])) * (1.0 - M("brand_halo") * aw_b)
			var rch := CompanyEngine.reach(p["company"], cid, b.get("posit", "mass"))
			var cons := PackedFloat32Array()
			cons.resize(ns)
			for i in ns:
				cons[i] = aw * rch[i]
			U.append(uu)
			CONS.append(cons)
			AUD.append(p.get("audience", "any"))
		# loyal customers: a utility boost (they come back), weakened when similar products are preferred
		var UB := PackedFloat32Array()
		var CB := PackedFloat32Array()
		UB.resize(n)
		CB.resize(n)
		var idx_of: Dictionary = {}
		for k in n:
			idx_of[plist[k]["id"]] = k
			for i in ns:
				var wseg := float(segw.get(DB.segments[i]["id"], 0.0))
				UB[k] += float(U[k][i]) * wseg
				CB[k] += float(CONS[k][i]) * wseg
		var LB := PackedFloat32Array()
		LB.resize(n)
		for k in n:
			var p: Dictionary = plist[k]
			var m := CompanyEngine.mk(p, cid)
			var rival_pull := 0.0
			for oid in sims.get(p["id"], []):
				if idx_of.has(oid):
					var j: int = idx_of[oid]
					rival_pull += CB[j] * exp(clampf(UB[j] - UB[k], -20.0, 20.0))
			var retention := 1.0 / (1.0 + M("cannibal") * rival_pull)
			m["retention"] = retention
			LB[k] = C.C("loyal_k") * log(1.0 + float(m["loyal"]) / maxf(1.0, B * 0.02)) * retention
			for i in ns:
				U[k][i] = float(U[k][i]) + LB[k]
		var newd := PackedFloat32Array()
		newd.resize(n)
		var segu: Array = []
		var EB: Array = []          # consideration × exp(utility) per product, per segment
		for k in n:
			var z := PackedFloat32Array()
			z.resize(ns)
			segu.append(z)
			var eb := PackedFloat32Array()
			eb.resize(ns)
			for i in ns:
				var cs: float = CONS[k][i]
				eb[i] = cs * exp(clampf(float(U[k][i]), -20.0, 20.0)) if cs > 0.0 else 0.0
			EB.append(eb)
		var LF := {}
		for g in ["fem", "masc", "any"]:
			var lm: Dictionary = DB.label_matrix[g]
			var lf := PackedFloat32Array()
			lf.resize(n)
			for k in n:
				lf[k] = maxf(0.02, float(lm.get(AUD[k], 0.5)))
			LF[g] = lf
		var ex := PackedFloat32Array()
		ex.resize(n)
		var sim_cap := M("sim_cap")
		for i in ns:
			var sg: Dictionary = DB.segments[i]
			var Ds := B * float(segw.get(sg["id"], 0.0)) * float(sg["rate"]) / ar
			if Ds <= 0.0:
				continue
			var lab: Dictionary = sg["labels"]
			for g in ["fem", "masc", "any"]:
				var Dg := Ds * float(lab[g])
				var lf: PackedFloat32Array = LF[g]
				var tot_e := 0.0
				for k in n:
					var e: float = EB[k][i] * lf[k]
					ex[k] = e
					tot_e += e
				# other (unsimulated) brands grow with the category: simulated houses can't capture everyone
				var denom := maxf(e0, sim_cap * tot_e) + tot_e
				var f := Dg / denom
				for k in n:
					if ex[k] > 0.0:
						var q := ex[k] * f
						newd[k] += q
						segu[k][i] += q
		for k in n:
			var p: Dictionary = plist[k]
			if not D.has(p["id"]):
				D[p["id"]] = {}
			D[p["id"]][cid] = [newd[k], 0.0, segu[k], U[k], VT[k]]
	# ---- allocation by stock, revenue and finance
	var amap: Dictionary = {}
	for a in G.s["channels"]:
		amap[a["id"]] = a
	var by_company: Dictionary = {}
	for p in prods:
		if not D.has(p["id"]):
			continue
		var dm: Dictionary = D[p["id"]]
		var total := 0.0
		for cid in dm:
			total += float(dm[cid][0]) + float(dm[cid][1])
		var inv := int(p.get("inv", 0))
		var scale := 1.0 if total <= float(inv) else float(inv) / maxf(0.0001, total)
		var sold_total := 0
		var lost_total := 0.0
		var rev_total := 0.0
		var fees_total := 0.0
		var c := G.company(p["company"])
		var b := G.brand(p["brand"])
		var ev := product_ev(p)
		var cogs_unit := float(p["unit_cost"])
		var refunds := 0.0
		var ret_units := 0
		for cid in dm:
			var dd: Array = dm[cid]
			var want := float(dd[0]) + float(dd[1])
			var m := CompanyEngine.mk(p, cid)
			var q := want * scale + (float(m["carry"]) if scale >= 1.0 else 0.0)
			var sold := int(floor(q))
			sold = mini(sold, inv - sold_total)
			m["carry"] = clampf(q - float(sold), 0.0, 1.0) if scale >= 1.0 else 0.0
			var lost := maxf(0.0, want - float(sold)) if scale < 1.0 else 0.0
			m["lost"] = int(lost)
			m["last"] = sold
			m["u"] = int(m["u"]) + sold
			lost_total += lost
			sold_total += sold
			if sold <= 0:
				continue
			# channel economics
			var net := CompanyEngine.net_price(p, cid)
			var office := CompanyEngine.has_office(p["company"], cid)
			var r_c := 0.0
			var f_c := 0.0
			for chw in _cw(p["company"], cid, b.get("posit", "mass")):
				var u := float(sold) * float(chw["w"])
				if chw["ch"] == "dtc":
					var chd: Dictionary = DB.channels["dtc"]
					r_c += u * net
					f_c += u * (net * float(chd["fee_pct"]) + float(chd["unit_fee"]) + (0.0 if office else M("cross_border_fee")))
				else:
					r_c += u * net * (1.0 - float(chw["margin"]))
					var ag: Dictionary = amap.get(chw["a"], {})
					if not ag.is_empty():
						ag["units"] = int(ag.get("units", 0)) + int(round(u))
						ag["rev"] = float(ag.get("rev", 0.0)) + u * net * (1.0 - float(chw["margin"]))
			rev_total += r_c
			fees_total += f_c
			# experience: satisfaction of the actual buyers
			var segu: PackedFloat32Array = dd[2]
			var new_buyers := float(dd[0]) * scale
			var sat_acc := 0.0
			var wsum := 0.0
			var defect := float(p.get("defect", 0.0))
			var posit: String = b.get("posit", "mass")
			var vt_by: PackedFloat32Array = dd[4]
			var pft := perf_terms(p, ev, cid)
			var sb := ConsumerEngine.seg_base(ev)
			var sats: PackedFloat32Array = sb["sat"]
			for i in DB.segments.size():
				var bi := float(segu[i]) * scale
				if bi <= 0.0:
					continue
				var ps := C.p_sat(float(sats[i]) + pft[i] + 0.35 * vt_by[i] - 3.0 * defect)
				sat_acc += bi * ps
				wsum += bi
			var ps_avg := sat_acc / wsum if wsum > 0.0 else float(m["sat"])
			var old_w := minf(float(m["triers"]), 3000.0)
			m["sat"] = (float(m["sat"]) * old_w + ps_avg * new_buyers) / maxf(1.0, old_w + new_buyers)
			m["triers"] = float(m["triers"]) + new_buyers
			m["rep"] = mini(sold, int(float(m["loyal"]) * C.C("repurchase")))
			m["loyal"] = float(m["loyal"]) * (1.0 - 0.05 * (1.0 - float(m.get("retention", 1.0)))) + new_buyers * ps_avg * C.C("loyal_conv")
			var pop := buyers(cid, w) * M("pop_mult")
			var wom := C.C("wom_k") * float(sold) * (2.0 * ps_avg - 0.7) / maxf(1.0, pop)
			m["aw"] = clampf(float(m["aw"]) + maxf(0.0, wom), 0.0, 0.95)
			CompanyEngine.set_brand_aw(b, cid, CompanyEngine.brand_aw(b, cid) + maxf(0.0, wom) * C.C("brand_wom"))
			if not p.has("countries_sold"):
				p["countries_sold"] = {}
			p["countries_sold"][cid] = true
			# defects → returns
			if defect > 0.0:
				var ru := int(round(float(sold) * defect * C.C("return_rate")))
				if ru > 0:
					ret_units += ru
					refunds += float(ru) * r_c / float(sold)
					p["complaints"] = int(p.get("complaints", 0)) + ru
			# discovery sets: every buyer tries each fragrance in the box
			if p.get("kind", "") == "discovery":
				for dq in G.s["products"].values():
					if dq["company"] == p["company"] and dq.get("kind", "full") == "full" and dq["status"] == "active" and p.get("set", []).has(dq["formula"]) and dq["markets"].has(cid):
						var mq := CompanyEngine.mk(dq, cid)
						mq["triers"] = float(mq["triers"]) + float(sold) * 0.8
						mq["loyal"] = float(mq["loyal"]) + float(sold) * 0.8 * float(mq["sat"]) * 0.15
						mq["aw"] = clampf(float(mq["aw"]) + float(sold) * 0.8 / maxf(1.0, buyers(cid, w) * M("pop_mult")), 0.0, 0.95)
			# reviews
			_reviews(p, ev, cid, sold, segu, vt_by, defect)
			if not share_tot.has(cid):
				share_tot[cid] = {}
			share_tot[cid][p["company"]] = int(share_tot[cid].get(p["company"], 0)) + sold
		# post finance
		p["inv"] = inv - sold_total
		var cogs := float(sold_total) * cogs_unit
		if sold_total > 0:
			FinanceEngine.earn(c, "revenue", rev_total)
			FinanceEngine.pl(c, "cogs", -cogs)
			FinanceEngine.spend(c, "distribution", fees_total)
			if refunds > 0.0:
				FinanceEngine.spend(c, "returns", refunds)
		var st: Dictionary = p["st"]
		st["units"] = int(st["units"]) + sold_total
		st["rev"] = float(st["rev"]) + rev_total - refunds
		st["gp"] = float(st["gp"]) + rev_total - refunds - cogs
		st["cm"] = float(st.get("cm", 0.0)) + rev_total - refunds - cogs - fees_total
		st["lost"] = int(st["lost"]) + int(lost_total)
		st["returns"] = int(st["returns"]) + ret_units
		var vkey := str(p["fv"])
		if not st.has("by_v"):
			st["by_v"] = {}
		st["by_v"][vkey] = int(st["by_v"].get(vkey, 0)) + sold_total
		p["peak_week_units"] = maxi(int(p.get("peak_week_units", 0)), sold_total)
		var wk: Array = p["wk"]
		wk.append([w, sold_total, snappedf(rev_total - refunds, 0.01), snappedf(rev_total - refunds - cogs - fees_total, 0.01), int(lost_total)])
		while wk.size() > 104:
			wk.remove_at(0)
		var y := str(G.year_of(w))
		var yr: Array = p["yr"].get(y, [0, 0.0, 0.0])
		p["yr"][y] = [int(yr[0]) + sold_total, float(yr[1]) + rev_total - refunds, float(yr[2]) + rev_total - refunds - cogs - fees_total]
		if not by_company.has(p["company"]):
			by_company[p["company"]] = {"units": 0, "rev": 0.0, "lost": 0}
		by_company[p["company"]]["units"] += sold_total
		by_company[p["company"]]["rev"] += rev_total
		by_company[p["company"]]["lost"] += int(lost_total)
		if G.is_player(p["company"]) and lost_total > 5.0 and int(p["inv"]) <= 0:
			if not rep["stockouts"].has(p["name"]):
				rep["stockouts"].append(p["name"])
	rep["by_company"] = by_company
	# market shares and average profiles
	for cid in share_tot:
		var tot := 0
		for k in share_tot[cid]:
			tot += int(share_tot[cid][k])
		var mkt: Dictionary = G.s["markets"][cid]
		var sh: Dictionary = {}
		for k in share_tot[cid]:
			sh[k] = float(share_tot[cid][k]) / maxf(1.0, float(tot))
		mkt["share"] = sh
		mkt["units"] = tot
	if w % 4 == 0:
		update_avg_profiles(prods)


static func _cw(cid: String, country: String, posit: String) -> Array:
	var key := "cw|%s|%s|%s" % [cid, country, posit]
	if not G.cache.has(key):
		G.cache[key] = CompanyEngine.channel_weights(cid, country, posit)
	return G.cache[key]


static func similar_map(prods: Array) -> Dictionary:
	var out: Dictionary = {}
	var thr := M("similar_cos")
	var n := prods.size()
	var profs: Array = []
	for p in prods:
		profs.append(product_ev(p).get("profile", PackedFloat32Array()))
		out[p["id"]] = []
	for a in n:
		for b2 in range(a + 1, n):
			if G.vcos(profs[a], profs[b2]) >= thr:
				out[prods[a]["id"]].append(prods[b2]["id"])
				out[prods[b2]["id"]].append(prods[a]["id"])
	return out


static func _open_supply(_p: Dictionary) -> int:
	return 0


static func _reviews(p: Dictionary, ev: Dictionary, cid: String, sold: int, segu: PackedFloat32Array, vt_by: PackedFloat32Array, defect: float) -> void:
	var r := G.rng
	var nrev := 0
	if G.is_player(p["company"]):
		nrev = mini(3, int(float(sold) / M("review_rate")) + (1 if r.randf() < minf(1.0, float(sold) / 40.0) else 0))
	else:
		nrev = 1 if r.randf() < minf(0.25, float(sold) / 4000.0) else 0
	if nrev <= 0:
		return
	var tot := 0.0
	for x in segu:
		tot += x
	if tot <= 0.0:
		return
	var prev_sat := 0.0
	var has_prev := int(p["fv"]) > 0 and p.has("prev_sat")
	if has_prev:
		prev_sat = float(p["prev_sat"])
	for n in nrev:
		var u := r.randf() * tot
		var si := 0
		for i in segu.size():
			u -= segu[i]
			if u <= 0.0:
				si = i
				break
		var dk := ""
		if defect > 0.0 and r.randf() < defect * 2.0:
			dk = p.get("defect_kind", "")
		var vd := 0.0
		if has_prev and r.randf() < 0.35:
			var base := ConsumerEngine.seg_base(ev)
			vd = (float(base["sat"][si]) - prev_sat) * 2.0
		var rv := ReviewEngine.customer_review({"ev": ev, "si": si, "cid": cid, "value": vt_by[si], "defect_kind": dk,
			"version_delta": vd, "fv": int(p["fv"]), "novelty": float(p.get("mk_nov_" + cid, 0.3))}, r)
		var rt: Dictionary = p["rating"]
		rt["n"] = int(rt["n"]) + 1
		rt["sum"] = float(rt["sum"]) + float(rv["stars"])
		rt["d"][int(rv["stars"]) - 1] = int(rt["d"][int(rv["stars"]) - 1]) + 1
		if G.is_player(p["company"]) or p["reviews"].size() < 6:
			var rl: Array = p["reviews"]
			rl.append(rv)
			while rl.size() > (30 if G.is_player(p["company"]) else 6):
				rl.remove_at(0)


static func update_avg_profiles(prods: Array) -> void:
	for ct in DB.countries:
		var cid: String = ct["id"]
		var acc := PackedFloat32Array()
		acc.resize(DB.dims.size())
		var tot := 0.0
		for p in prods:
			if not p["markets"].has(cid):
				continue
			var m: Dictionary = p["mk"].get(cid, {})
			var u := float(m.get("last", 0)) + 1.0
			var ev := product_ev(p)
			var v: PackedFloat32Array = ev.get("profile", PackedFloat32Array())
			for i in mini(v.size(), acc.size()):
				acc[i] += v[i] * u
			tot += u
		if tot > 0.0:
			G.s["markets"][cid]["avg"] = Array(G.vnorm(acc))


## Weekly decay of awareness, buzz and search conversion for all products and brands.
static func decay() -> void:
	var C := ConsumerEngine
	var awd := C.C("aw_decay")
	var bd := C.C("buzz_decay")
	for p in G.s["products"].values():
		if p["status"] == "dev":
			continue
		for cid in p["mk"]:
			var m: Dictionary = p["mk"][cid]
			m["aw"] = float(m["aw"]) * (1.0 - awd)
			m["buzz"] = float(m["buzz"]) * (1.0 - bd)
			m["conv"] = float(m["conv"]) * 0.5
			m["loyal"] = float(m["loyal"]) * (1.0 - C.C("churn"))
			if p["status"] == "discontinued":
				m["loyal"] = float(m["loyal"]) * 0.9
	var ld := float(DB.bal["marketing"]["load_decay"])
	for holder in G.s["products"].values() + G.s["brands"].values():
		for k in holder.keys():
			if str(k).begins_with("load_"):
				holder[k] = float(holder[k]) * (1.0 - ld)
	var bdd := C.C("brand_aw_decay")
	for b in G.s["brands"].values():
		for cid in b["aw"]:
			b["aw"][cid] = float(b["aw"][cid]) * (1.0 - bdd)
