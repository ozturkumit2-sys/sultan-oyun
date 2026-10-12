class_name ConsumerEngine
extends RefCounted
## Consumer preference engine shared by sales, surveys, reviews and perfumer intuition.
## Segments are overlapping archetypes; every market contains all of them in different proportions.
## Purchase appeal (sniffing in store / online buzz) differs from satisfaction (wearing it for weeks).


static func C(k: String) -> float:
	return float(DB.bal["consumer"].get(k, 0.0))


static func fmt_long(fmt_id: String) -> float:
	return float(DB.bal["consumer"]["fmt_long"].get(fmt_id, 1.0))


static func climate(cid: String) -> Array:
	return DB.bal["consumer"]["climate"].get(cid, [1.0, 1.0])


## Formula-only components per segment (cached inside the evaluation dict).
static func seg_base(ev: Dictionary) -> Dictionary:
	if ev.has("_seg"):
		return ev["_seg"]
	var ns := DB.segments.size()
	var ap := PackedFloat32Array()
	var sa := PackedFloat32Array()
	ap.resize(ns)
	sa.resize(ns)
	var lk := C("like_k")
	for i in ns:
		var sg: Dictionary = DB.segments[i]
		var pref: PackedFloat32Array = sg["pref"]
		var lo := G.dot(pref, ev["open"])
		var lh := G.dot(pref, ev["heart"])
		var ld := G.dot(pref, ev["dry"])
		var common := C("complexity_k") * float(sg["complexity"]) * (float(ev["complexity"]) - 0.45)
		common -= C("tension_k") * float(ev["tension"]) * (1.0 - 0.7 * maxf(0.0, float(sg["novelty"])))
		common -= C("cloy_k") * maxf(0.0, float(ev["sweet"]) - float(sg["sweet_tol"])) * (1.0 + float(ev["cloying"]))
		var appeal := lk * (C("open_w") * lo + C("heart_w") * lh + C("dry_w") * ld) + common
		appeal -= C("harsh_k") * 0.6 * float(ev["harsh"])
		appeal += C("store_proj_k") * (float(ev["projection"]) - 0.4) * (1.0 if float(sg["proj_pref"]) >= 0.5 else 0.3)
		var sat := lk * (C("sat_open") * lo + C("sat_heart") * lh + C("sat_dry") * ld) + common
		sat -= C("harsh_k") * 0.35 * float(ev["harsh"])
		ap[i] = appeal
		sa[i] = sat
	var out := {"appeal": ap, "sat": sa}
	ev["_seg"] = out
	return out


static func perf_fit(ev: Dictionary, sg: Dictionary, cid := "", skin := 1.0, proj_shift := 0.0) -> Dictionary:
	var cl := climate(cid) if cid != "" else [1.0, 1.0]
	var L := float(ev["longevity"]) * float(cl[0]) * skin
	var E := float(sg["long_exp"]) * fmt_long(ev.get("fmt", "edp"))
	var gap := (L - E) / maxf(0.5, E)
	var lf := C("long_short_k") * gap if gap < 0.0 else C("long_over_k") * minf(gap, 1.0)
	var pr := clampf(float(ev["projection"]) * float(cl[1]), 0.0, 1.0)
	var d := absf(pr - (float(sg["proj_pref"]) + proj_shift)) - float(sg["proj_tol"])
	var pf := -C("proj_k") * d if d > 0.0 else 0.0
	return {"long": lf, "proj": pf, "L": L, "E": E, "P": pr, "too_loud": pr > float(sg["proj_pref"]) + proj_shift + float(sg["proj_tol"])}


## Season factor: +1 at the height of summer, -1 in winter (hemisphere aware).
static func summerness(cid: String, w: int) -> float:
	var x := cos((float(w % 52) - 28.0) / 52.0 * TAU)
	return -x if DB.country(cid).get("south", false) else x


static func country_adj(ev: Dictionary, cid: String, w: int, novelty: float) -> PackedFloat32Array:
	var ns := DB.segments.size()
	var out := PackedFloat32Array()
	out.resize(ns)
	var mk: Dictionary = G.s["markets"].get(cid, {})
	var tr := G.to_vec(mk.get("trend", []))
	var t_like := G.dot(tr, ev["profile"]) if tr.size() > 0 else 0.0
	var sm := summerness(cid, w)
	var season := C("season_k") * sm * (float(ev["fresh"]) - float(ev["warm"]))
	for i in ns:
		var sg: Dictionary = DB.segments[i]
		out[i] = C("trend_k") * float(sg.get("trend_mult", 1.0)) * t_like + season + C("novelty_k") * float(sg["novelty"]) * (novelty - 0.3)
	return out


## Price per 100 ml equivalent: smaller bottles carry a higher acceptable price per ml.
static func price_pp(price: float, volume: float) -> float:
	return price / pow(maxf(1.0, volume) / 100.0, 0.8)


static func price_ref(sg: Dictionary, cid: String, fmt_id: String, posit: String, prestige: float) -> float:
	var ppp := float(DB.country(cid).get("ppp", 1.0))
	var fm := float(DB.formats.get(fmt_id, {}).get("ref_mult", 1.0))
	var pa := float(DB.bal["consumer"]["posit_accept"].get(posit, 1.0))
	return float(sg["price_ref"]) * (0.4 + 0.6 * ppp) * fm * pa * (0.75 + 0.5 * prestige)


static func price_term(price: float, volume: float, fmt_id: String, posit: String, prestige: float, sg: Dictionary, cid: String) -> float:
	var pp := price_pp(price, volume)
	var ref := price_ref(sg, cid, fmt_id, posit, prestige)
	var r := log(maxf(0.01, pp) / ref)
	var t := -float(sg["price_sens"]) * r if r > 0.0 else -float(sg["price_sens"]) * C("price_gain") * r
	if float(sg["price_sens"]) <= 0.6 and pp < 0.4 * ref:
		t -= C("cheap_lux") * (0.4 * ref / maxf(1.0, pp) - 1.0)
	return t


static func brand_term(prestige: float, posit: String, sg: Dictionary) -> float:
	return C("brand_k") * float(sg["brand_sens"]) * (prestige - 0.35) + float(sg["posit"].get(posit, 0.0))


static func pack_term(pack_id: String, price: float, volume: float, sg: Dictionary, edition: String) -> float:
	var pv := float(DB.packaging.get(pack_id, {}).get("value", 0.35))
	var pp := price_pp(price, volume)
	var expected := clampf(log(maxf(1.0, pp) / 40.0) / log(8.0), 0.0, 1.0)
	var t := C("pack_k") * float(sg["pack"]) * (pv - expected)
	if edition == "limited" and (sg["id"] == "luxury" or sg["id"] == "niche"):
		t += 0.3
	return t


static func label_ln(group: String, audience: String) -> float:
	return log(maxf(0.02, float(DB.label_matrix[group].get(audience, 0.5))))


static func p_sat(sat: float) -> float:
	return G.sigmoid(C("sat_slope") * (sat - C("sat_s0")))


## Full satisfaction for a segment in a country (formula + performance + value for money + defects).
static func satisfaction_full(ev: Dictionary, si: int, cid: String, value_term: float, defect := 0.0) -> float:
	var sg: Dictionary = DB.segments[si]
	var base: Dictionary = seg_base(ev)
	var pf := perf_fit(ev, sg, cid)
	return float(base["sat"][si]) + float(pf["long"]) + float(pf["proj"]) + 0.35 * value_term - 3.0 * defect


## Expected star rating (1..5) from satisfaction probability.
static func stars(psat: float) -> float:
	return clampf(1.0 + 4.0 * pow(psat, 0.8), 1.0, 5.0)


# ---------------------------------------------------------------- consumer research
## Runs a survey by sampling individual respondents from the same preference model used by sales.
## spec = {items, fmt, conc, maturation, price, volume, pack, audience, brand(optional), posit, prestige}
static func survey(spec: Dictionary, cid: String, n: int, blind: bool, key: String) -> Dictionary:
	var r := G.drng("survey|" + key)
	var ev := FormulaEngine.evaluate(spec["items"], spec["fmt"], float(spec["conc"]), {"maturation": int(spec.get("maturation", 0))})
	var base := seg_base(ev)
	var adj := country_adj(ev, cid, G.week(), 0.35)
	var ctry := DB.country(cid)
	var segw: Dictionary = ctry["seg"]
	var seg_ids: Array = []
	var seg_cum: Array = []
	var acc := 0.0
	for sg in DB.segments:
		acc += float(segw.get(sg["id"], 0.0)) * float(sg["rate"])
		seg_ids.append(sg["idx"])
		seg_cum.append(acc)
	var likes: Array = []
	var by_seg: Dictionary = {}
	var long_fb := [0, 0, 0]     # too short / about right / longer than needed
	var proj_fb := [0, 0, 0]     # too soft / right / too loud
	var intents := 0
	var comments: Array = []
	var price: float = float(spec.get("price", 60.0))
	var vol: float = float(spec.get("volume", 50.0))
	var posit: String = spec.get("posit", "premium")
	var prestige: float = float(spec.get("prestige", 0.3))
	var price_points := [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
	var accept := [0, 0, 0, 0, 0, 0]
	for i in n:
		var u := r.randf() * acc
		var si := 0
		for k in seg_cum.size():
			if u <= seg_cum[k]:
				si = seg_ids[k]
				break
		var sg: Dictionary = DB.segments[si]
		var noise := r.randfn(0.0, 0.55)
		var skin := exp(r.randfn(0.0, 0.3))
		if float(ev.get("anosmia", 0.0)) > 0.05 and r.randf() < float(ev["anosmia"]) * 0.8:
			skin *= 0.55
		var pf := perf_fit(ev, sg, cid, skin, r.randfn(0.0, 0.1))
		var exp_like := float(base["appeal"][si]) * 0.45 + float(base["sat"][si]) * 0.55 + adj[si] + float(pf["long"]) * 0.6 + float(pf["proj"]) * 0.6 + noise
		var score := clampf(5.6 + 1.7 * exp_like, 1.0, 10.0)
		likes.append(score)
		if not by_seg.has(si):
			by_seg[si] = [0.0, 0]
		by_seg[si][0] += score
		by_seg[si][1] += 1
		var L: float = pf["L"]
		var E: float = pf["E"]
		if L < E * 0.8:
			long_fb[0] += 1
		elif L > E * 1.5:
			long_fb[2] += 1
		else:
			long_fb[1] += 1
		var ppv: float = pf["P"]
		if ppv < float(sg["proj_pref"]) - float(sg["proj_tol"]):
			proj_fb[0] += 1
		elif pf["too_loud"]:
			proj_fb[2] += 1
		else:
			proj_fb[1] += 1
		var util := exp_like
		if not blind:
			util += brand_term(prestige, posit, sg) + pack_term(spec.get("pack", "standard"), price, vol, sg, "regular") + price_term(price, vol, spec["fmt"], posit, prestige, sg, cid)
			util += label_ln(_label_group(r, sg), spec.get("audience", "any"))
			for k in price_points.size():
				var pt := price_term(price * price_points[k], vol, spec["fmt"], posit, prestige, sg, cid)
				if exp_like + pt + brand_term(prestige, posit, sg) > C("intent_thr") - 0.4:
					accept[k] += 1
		if util + r.randfn(0.0, 0.4) > C("intent_thr"):
			intents += 1
		if comments.size() < 8 and r.randf() < 8.0 / float(n) * 1.6:
			comments.append(ReviewEngine.respondent_comment(ev, sg, pf, score, r, blind))
	var mean := 0.0
	for x in likes:
		mean += x
	mean /= maxf(1.0, float(n))
	var sd := 0.0
	for x in likes:
		sd += (x - mean) * (x - mean)
	sd = sqrt(sd / maxf(1.0, float(n - 1)))
	var segs: Array = []
	for si in by_seg:
		segs.append({"seg": DB.segments[si]["name"], "n": by_seg[si][1], "like": by_seg[si][0] / float(by_seg[si][1])})
	segs.sort_custom(func(a, b2): return a["like"] > b2["like"])
	var intent_p := float(intents) / float(n)
	var acc_curve: Array = []
	for k in price_points.size():
		acc_curve.append([price * price_points[k], float(accept[k]) / float(n)])
	return {
		"n": n, "country": cid, "blind": blind, "week": G.week(),
		"like": mean, "sd": sd, "moe": 1.96 * sd / sqrt(float(n)),
		"intent": intent_p, "intent_moe": 1.96 * sqrt(intent_p * (1.0 - intent_p) / float(n)),
		"segments": segs, "long_fb": long_fb, "proj_fb": proj_fb, "comments": comments,
		"price_accept": acc_curve if not blind else [], "price": price,
	}


static func _label_group(r: RandomNumberGenerator, sg: Dictionary) -> String:
	var l: Dictionary = sg["labels"]
	var u := r.randf()
	if u < float(l["fem"]):
		return "fem"
	if u < float(l["fem"]) + float(l["masc"]):
		return "masc"
	return "any"


static func survey_cost(n: int, cid: String) -> float:
	var base := {50: 1500.0, 250: 6000.0, 1000: 20000.0}
	return float(base.get(n, 3000.0)) * (0.6 + 0.4 * float(DB.country(cid).get("opcost", 1.0)))
