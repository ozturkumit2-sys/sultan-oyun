class_name ReviewEngine
extends RefCounted
## Builds review text from the actual drivers of a simulated consumer experience.
## Every sentence is chosen because a model component (liking, longevity, projection, price,
## sweetness, defects, version change) pushed the experience up or down.


static func T(k: String) -> Variant:
	return DB.texts.get(k, [])


static func _p(arr: Variant, r: RandomNumberGenerator) -> String:
	if arr is Array and not arr.is_empty():
		return str(arr[r.randi_range(0, arr.size() - 1)])
	return ""


static func dim_phrase(v: PackedFloat32Array, r: RandomNumberGenerator) -> String:
	var tops := FormulaEngine.top_dims(v, 2)
	if tops.is_empty():
		return "composition"
	return _p(T("dim_words")[tops[0]], r)


## One survey respondent's free-text comment.
static func respondent_comment(ev: Dictionary, sg: Dictionary, pf: Dictionary, score: float, r: RandomNumberGenerator, blind: bool) -> String:
	var parts: Array = []
	var pref: PackedFloat32Array = sg["pref"]
	var lo := G.dot(pref, ev["open"])
	var ld := G.dot(pref, ev["dry"])
	if lo > 0.15:
		parts.append("Nice %s at first." % dim_phrase(ev["open"], r))
	elif lo < -0.05:
		parts.append("Didn't enjoy the %s opening." % dim_phrase(ev["open"], r))
	if ld > 0.15:
		parts.append("Lovely %s later on." % dim_phrase(ev["dry"], r))
	elif ld < -0.05:
		parts.append("The %s dry-down isn't my style." % dim_phrase(ev["dry"], r))
	if float(pf["long"]) < -0.3:
		parts.append("Faded faster than I'd like.")
	elif float(pf["L"]) > float(pf["E"]) * 1.5:
		parts.append("Lasted a very long time.")
	if pf.get("too_loud", false):
		parts.append("Too strong for everyday.")
	if float(ev["sweet"]) > float(sg["sweet_tol"]) + 0.1:
		parts.append("A bit too sweet.")
	if float(ev["harsh"]) > 0.35:
		parts.append("Slightly sharp opening.")
	if parts.is_empty():
		parts.append("Pleasant, nothing special." if score < 7.0 else "Really enjoyed wearing it.")
	var who: String = sg["name"]
	return "\"%s\" — %s respondent, %.0f/10" % [" ".join(parts.slice(0, 2)), who, score]


## Full customer review for a sale. ctx: {ev, si, cid, psat, value, defect_kind, version_delta, product}
static func customer_review(ctx: Dictionary, r: RandomNumberGenerator) -> Dictionary:
	var ev: Dictionary = ctx["ev"]
	var si: int = ctx["si"]
	var sg: Dictionary = DB.segments[si]
	var cid: String = ctx["cid"]
	var skin := exp(r.randfn(0.0, 0.3))
	var anos := false
	if float(ev.get("anosmia", 0.0)) > 0.05 and r.randf() < float(ev["anosmia"]) * 0.6:
		skin *= 0.55
		anos = true
	var pf := ConsumerEngine.perf_fit(ev, sg, cid, skin, r.randfn(0.0, 0.08))
	var base := ConsumerEngine.seg_base(ev)
	var sat := float(base["sat"][si]) + float(pf["long"]) + float(pf["proj"]) + 0.35 * float(ctx.get("value", 0.0)) + r.randfn(0.0, 0.6)
	var dk: String = ctx.get("defect_kind", "")
	if dk != "":
		sat -= 2.5
	sat += float(ctx.get("version_delta", 0.0)) * 0.5
	var ps := ConsumerEngine.p_sat(sat)
	var stars := clampi(int(round(ConsumerEngine.stars(ps) + r.randfn(0.0, 0.35))), 1, 5)
	var pref: PackedFloat32Array = sg["pref"]
	var lo := G.dot(pref, ev["open"])
	var ld := G.dot(pref, ev["dry"])
	var bits: Array = []
	bits.append(_p(T("stars_intro")[str(stars)], r))
	var s1 := ""
	if lo >= ld:
		s1 = (_p(T("open_pos"), r) if lo > 0.05 else _p(T("open_neg"), r))
	else:
		var d := _p(T("dry_pos"), r) if ld > 0.05 else _p(T("dry_neg"), r)
		s1 = d.substr(0, 1).to_upper() + d.substr(1)
	var s2 := ""
	if float(pf["long"]) < -0.35:
		s2 = _p(T("long_short"), r)
	elif pf.get("too_loud", false):
		s2 = _p(T("proj_loud"), r)
	elif float(pf["P"]) < float(sg["proj_pref"]) - float(sg["proj_tol"]) - 0.05:
		s2 = _p(T("proj_soft"), r)
	elif float(pf["long"]) > 0.15:
		s2 = _p(T("long_good"), r)
	elif stars >= 4:
		s2 = _p(T("proj_good"), r)
	bits.append(s1 + ((" — " + s2) if s2 != "" else "") + ".")
	if anos and r.randf() < 0.6:
		bits.append(_p(T("anosmic"), r))
	if dk != "":
		bits.append(str(T("defect").get(dk, "")))
	elif float(ev["sweet"]) > float(sg["sweet_tol"]) + 0.12 and r.randf() < 0.7:
		bits.append(_p(T("sweet_bad"), r))
	elif float(ev["harsh"]) > 0.3 and r.randf() < 0.6:
		bits.append(_p(T("harsh"), r))
	elif float(ev["tension"]) > 0.3 and r.randf() < 0.6:
		bits.append(_p(T("tension"), r))
	var vt := float(ctx.get("value", 0.0))
	if vt < -0.6:
		bits.append(_p(T("price_bad"), r))
	elif vt > 0.35 and stars >= 3:
		bits.append(_p(T("price_good"), r))
	var vd := float(ctx.get("version_delta", 0.0))
	if absf(vd) > 0.2 and r.randf() < 0.7:
		bits.append(_p(T("version_worse"), r) if vd < 0.0 else _p(T("version_better"), r))
	if float(sg["novelty"]) > 0.5 and float(ctx.get("novelty", 0.0)) > 0.45 and stars >= 4:
		bits.append(_p(T("novel_pos"), r))
	return {
		"w": G.week(), "stars": stars, "text": " ".join(bits.filter(func(x): return str(x) != "")),
		"by": "%s%d" % [_p(T("reviewer_names"), r), r.randi_range(1, 99)], "seg": sg["name"], "c": cid,
		"long": float(pf["L"]), "fv": int(ctx.get("fv", 0)),
	}


## Expert critic review for a launch (one per critic per product).
static func critic_review(critic: Dictionary, ev: Dictionary, novelty: float, r: RandomNumberGenerator) -> Dictionary:
	var bias: Dictionary = critic["bias"]
	var bv := PackedFloat32Array()
	bv.resize(DB.dims.size())
	for k in bias:
		var di := DB.dim_index(k)
		if di >= 0:
			bv[di] = float(bias[k])
	var like := G.dot(bv, ev["profile"]) * 3.0
	like += float(critic["complexity"]) * (float(ev["complexity"]) - 0.45) * 2.0
	like += (novelty - 0.3) * 1.5 - float(ev["tension"]) * 1.5 - float(ev["harsh"]) * 2.0 - float(ev["cloying"]) * 1.2
	like += r.randfn(0.0, 0.5)
	var score := clampf(6.0 + 1.6 * like, 1.0, 10.0)
	var line := _p(T("critic_open"), r)
	var tops := FormulaEngine.top_dims(ev["profile"], 2)
	var desc := "a %s %s" % [str(ev["family"]).to_lower(), "with " + _p(T("dim_words")[tops[1]], r) if tops.size() > 1 else ""]
	var verdict := ""
	if score >= 8.0:
		verdict = "Highly recommended."
	elif score >= 6.5:
		verdict = "Worth sampling."
	elif score >= 5.0:
		verdict = "Competent, but forgettable."
	else:
		verdict = "Hard to recommend."
	if float(ev["longevity"]) < 4.0:
		verdict += " Longevity is modest."
	elif float(ev["longevity"]) > 12.0:
		verdict += " Remarkable tenacity."
	return {"w": G.week(), "critic": critic["name"], "outlet": critic["outlet"], "score": snappedf(score, 0.1),
		"text": "%s %s — %s %s" % [line, "Opens as " + desc.strip_edges() + ".", "Dries down to " + dim_phrase(ev["dry"], r) + ".", verdict]}
