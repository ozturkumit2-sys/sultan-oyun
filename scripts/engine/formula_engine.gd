class_name FormulaEngine
extends RefCounted
## Generic fragrance model built from ingredient properties.
## A formula is a list of [ingredient_id, percent_of_concentrate]. The concentrate is diluted to `conc`%
## in the finished product (ethanol for alcohol formats, carrier oil for oil formats).
## The model computes time-based evaporation, perceived intensity, projection, odor character over time,
## stability risks, fictional regulatory checks and cost. It never produces a "quality" score.

const T_POINTS: Array[float] = [0.0, 0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 16.0, 20.0, 24.0, 30.0, 36.0]
const NOTE_T := {"open": 0.25, "heart": 2.0}


static func short_name(rec: Dictionary) -> String:
	var n: String = rec.get("name", "?")
	for cut in [" (", " Oil", " Absolute", " CO2", " Resinoid", " Accord", " Base", " Extract"]:
		var i := n.find(cut)
		if i > 0:
			n = n.substr(0, i)
	return n


static func items_key(items: Array, fmt_id: String, conc: float, mat: int) -> String:
	var parts: PackedStringArray = []
	for it in items:
		parts.append("%s:%.3f" % [it[0], float(it[1])])
	return "%s|%s|%.2f|%d" % [",".join(parts), fmt_id, conc, mat]


static func evaluate(items: Array, fmt_id: String, conc: float, opts: Dictionary = {}) -> Dictionary:
	var mat := int(opts.get("maturation", 0))
	var key := items_key(items, fmt_id, conc, mat)
	var ec: Dictionary = G.cache.get("eval", {})
	if ec.has(key):
		var r: Dictionary = ec[key]
		r["cost_kg"] = concentrate_cost(items)
		r["cost_ml"] = juice_cost_ml(items, fmt_id, conc)
		return r
	var res := _evaluate(items, fmt_id, conc, mat)
	if ec.size() > 600:
		ec.clear()
	ec[key] = res
	G.cache["eval"] = ec
	res["cost_kg"] = concentrate_cost(items)
	res["cost_ml"] = juice_cost_ml(items, fmt_id, conc)
	return res


static func concentrate_cost(items: Array) -> float:
	var t := 0.0
	for it in items:
		t += float(it[1]) / 100.0 * G.ing_price(str(it[0]))
	return t


static func juice_cost_ml(items: Array, fmt_id: String, conc: float) -> float:
	var fmt: Dictionary = DB.formats.get(fmt_id, DB.formats["edp"])
	var c := conc / 100.0
	var dil := G.ing_price("jojoba") if fmt["base"] == "oil" else G.ing_price("ethanol")
	return (c * concentrate_cost(items) + (1.0 - c) * dil) / 1000.0


static func _evaluate(items: Array, fmt_id: String, conc: float, mat: int) -> Dictionary:
	var P: Dictionary = DB.bal["perf"]
	var fmt: Dictionary = DB.formats.get(fmt_id, DB.formats["edp"])
	var c := clampf(conc, 0.5, 40.0) / 100.0
	var oil: bool = fmt["base"] == "oil"
	var nd := DB.dims.size()
	var errors: Array = []
	var warnings: Array = []
	var total := 0.0
	var frac: Dictionary = {}           # id -> fraction of concentrate
	var arom: Array = []                # [rec, p]
	var F := 0.0
	for it in items:
		var id := str(it[0])
		var pv := float(it[1])
		if pv <= 0.0:
			continue
		total += pv
		var rec := DB.ing(id)
		if rec.is_empty():
			errors.append("Unknown material: " + id)
			continue
		var p := pv / 100.0
		frac[id] = float(frac.get(id, 0.0)) + p
		F += float(rec["fix"]) * p
		if rec["role"] == "aromatic" or float(rec.get("str", 0.0)) > 0.0:
			arom.append([rec, p])
	if absf(total - 100.0) > 0.05:
		errors.append("Concentrate totals %.2f%% — it must equal 100%%." % total)
	if arom.is_empty():
		errors.append("The formula contains no odorous materials.")
	if frac.has("ethanol"):
		warnings.append("Ethanol inside the concentrate only dilutes it further; the finished product is diluted automatically.")
	if not oil and (float(frac.get("jojoba", 0.0)) > 0.02):
		warnings.append("Jojoba oil does not mix well with alcohol: expect haze.")
	# ---- modifiers from auxiliaries
	var dpg := float(frac.get("dpg", 0.0))
	var tec := float(frac.get("tec", 0.0))
	var bb := float(frac.get("benzyl_benzoate", 0.0))
	var ipm := float(frac.get("ipm", 0.0)) + float(frac.get("jojoba", 0.0))
	var gly := float(frac.get("glycerin", 0.0))
	var bht := float(frac.get("bht", 0.0))
	var uv := float(frac.get("uv_absorber", 0.0))
	var arom_total := 0.0
	for a in arom:
		arom_total += float(a[1])
	if arom_total < 0.35 and arom_total > 0.0:
		warnings.append("Only %.0f%% of the concentrate is odorous: the perfume will be weak." % (arom_total * 100.0))
	var dmod := 1.0
	if oil:
		dmod *= float(P["oil_diffusion"])
	elif ipm > 0.0:
		dmod *= 1.0 - minf(0.6, ipm * float(P["ipm_damp"]))
	var gly_fin := gly * c * 100.0      # % of finished product
	var sticky := clampf((gly_fin - float(P["gly_ok"])) / 3.0, 0.0, 1.0)
	if sticky > 0.0:
		dmod *= 1.0 - 0.3 * sticky
		warnings.append("Glycerin at %.1f%% of the finished product feels sticky and dampens diffusion; it does not add longevity." % gly_fin)
	# ---- interactions (data driven)
	var tags: Array = []
	var odor_add := PackedFloat32Array()
	odor_add.resize(nd)
	var harmony := 0.0
	var inter_names: Array = []
	for ia in DB.bal.get("interactions", []):
		if _inter_ok(ia, frac):
			dmod *= 1.0 + float(ia.get("diffusion", 0.0))
			harmony += float(ia.get("harmony", 0.0))
			var od: Dictionary = ia.get("odor", {})
			for k in od:
				var di := DB.dim_index(k)
				if di >= 0:
					odor_add[di] += float(od[k])
			if ia.has("tag"):
				tags.append(ia["tag"])
			inter_names.append(ia["name"])
	# ---- evaporation model
	var skin_a := float(P["skin_a"])
	var skin_b := float(P["skin_b"])
	var fixk := float(P["fix_k"])
	var mats: Array = []     # [rec, x(finished fraction), tau]
	for a in arom:
		var rec: Dictionary = a[0]
		var p: float = a[1]
		var ten := maxf(0.2, float(rec["ten"]))
		var nv := clampf(log(1.0 + ten) / log(31.0), 0.0, 1.0)
		var tau := skin_a * pow(ten, skin_b) * (1.0 + minf(float(P["fix_cap"]), fixk * F * (1.0 - nv)))
		if oil:
			tau *= float(P["oil_tau"])
		mats.append([rec, p * c, tau])
	var nt := T_POINTS.size()
	var curve := PackedFloat32Array()
	var pcurve := PackedFloat32Array()
	curve.resize(nt)
	pcurve.resize(nt)
	var bloom := 0.0 if oil else float(P["bloom"])
	for ti in nt:
		var t: float = T_POINTS[ti]
		var I := 0.0
		var Pj := 0.0
		for m in mats:
			var rec: Dictionary = m[0]
			var ou := float(rec["str"]) * 100.0 * float(m[1]) * exp(-t / float(m[2]))
			I += ou
			Pj += ou * float(rec["diff"])
		curve[ti] = I
		pcurve[ti] = Pj * dmod * (1.0 + bloom * exp(-t / 0.35))
	var thr := float(P["detect"])
	var longevity := _cross_time(curve, thr)
	var sillage := _cross_time(pcurve, float(P["proj_thr"]))
	var I0 := curve[1]
	var proj0 := _at(pcurve, 0.5)
	var dry_t := clampf(longevity * 0.7, 2.5, 8.0)
	var v_open := _profile_at(mats, 0.25, odor_add)
	var v_heart := _profile_at(mats, 2.0, odor_add)
	var v_dry := _profile_at(mats, dry_t, odor_add)
	var v_all := PackedFloat32Array()
	v_all.resize(nd)
	for i in nd:
		v_all[i] = 0.25 * v_open[i] + 0.35 * v_heart[i] + 0.4 * v_dry[i]
	# ---- sensory descriptors (not quality judgements)
	var sweet := v_all[DB.dim_index("gourmand")] + 0.4 * v_all[DB.dim_index("fruity")]
	var em := float(frac.get("ethyl_maltol", 0.0))
	var cloying := clampf((em - 0.02) * 15.0 + maxf(0.0, sweet - 0.55) * 1.5, 0.0, 1.0)
	var fresh := v_open[DB.dim_index("citrus")] + v_open[DB.dim_index("aromatic")] + v_open[DB.dim_index("green")] + v_open[DB.dim_index("aquatic")]
	var warm := v_all[DB.dim_index("amber")] + v_all[DB.dim_index("gourmand")] + v_all[DB.dim_index("animalic")] + v_all[DB.dim_index("spicy")] + 0.5 * v_all[DB.dim_index("woody")]
	# complexity: effective number of perceptible materials at the heart + spread across odor families
	var I2 := 0.0
	var shares: Array = []
	for m in mats:
		var ou2 := float(m[0]["str"]) * 100.0 * float(m[1]) * exp(-2.0 / float(m[2]))
		shares.append(ou2)
		I2 += ou2
	var H := 0.0
	if I2 > 0.0:
		for o in shares:
			var q := float(o) / I2
			if q > 0.0:
				H -= q * log(q)
	var n_eff := exp(H)
	var Hd := 0.0
	for v in v_all:
		if v > 0.0:
			Hd -= v * log(v)
	Hd /= log(float(nd))
	var complexity := clampf(0.55 * (1.0 - exp(-(n_eff - 1.0) / 6.0)) + 0.45 * Hd, 0.0, 1.0)
	# tension between clashing families
	var tension := 0.0
	for cl in DB.bal.get("clash", []):
		var ia := DB.dim_index(cl[0])
		var ib := DB.dim_index(cl[1])
		tension += float(cl[2]) * v_all[ia] * v_all[ib]
	tension = clampf(tension * float(P["tension_k"]) - harmony, 0.0, 1.0)
	# roughness (softened by maturation only where rough materials are present) and dominance
	var harsh := 0.0
	var I_open := maxf(0.0001, _at(curve, 0.25))
	var mat_f := exp(-float(mat) / float(P["mat_weeks"]))
	var dom := 0.0
	var anos := 0.0
	var I_dry := 0.0
	for m in mats:
		var rec: Dictionary = m[0]
		var ou_o := float(rec["str"]) * 100.0 * float(m[1]) * exp(-0.25 / float(m[2]))
		harsh += float(rec.get("rough", 0.0)) * ou_o / I_open * 1.6 * mat_f
		dom = maxf(dom, ou_o / I_open)
		var ou_d := float(rec["str"]) * 100.0 * float(m[1]) * exp(-dry_t / float(m[2]))
		anos += float(rec.get("anos", 0.0)) * ou_d
		I_dry += ou_d
	harsh += maxf(0.0, dom - 0.5) * 0.6
	var overdose := 0.0
	for m in mats:
		var rec: Dictionary = m[0]
		if float(rec["str"]) >= 2.4 and float(m[1]) * 100.0 > 1.2:
			overdose += (float(m[1]) * 100.0 - 1.2) * 0.08
	harsh = clampf(harsh + overdose, 0.0, 1.0)
	anos = anos / maxf(0.0001, I_dry)
	# ---- stability and compatibility
	var oxid := 0.0
	var disc := 0.0
	var cloud_d := 0.0
	var cryst := 0.0
	var nat := 0.0
	for a in arom:
		var rec: Dictionary = a[0]
		var p: float = a[1]
		oxid += (1.0 - float(rec.get("stab", 0.8))) * p
		disc += float(rec.get("disc", 0.0)) * p
		cloud_d += (1.0 - float(rec.get("sol", 0.95))) * p
		if rec.get("cryst", false):
			cryst += p
		if rec.get("nat", false):
			nat += p
	oxid = clampf(oxid * 2.2 * (1.0 - 0.65 * minf(1.0, bht / 0.002)), 0.0, 1.0)
	disc = clampf(disc * 2.5 * (1.0 - 0.5 * minf(1.0, uv / 0.003)), 0.0, 1.0)
	cloud_d += gly * 0.5 + (0.0 if oil else ipm * 0.15)
	var solv := bb + tec + dpg * 0.5
	var cloud := clampf(cloud_d * c / maxf(0.02, 0.05 + 0.4 * solv) - 0.3, 0.0, 1.0)
	if oil:
		cloud *= 0.5
	var crystal := clampf((cryst - (0.15 + 0.8 * (dpg + bb + tec))) * 3.0 * (0.5 + c), 0.0, 1.0)
	var natural_share := nat / maxf(0.0001, arom_total)
	# ---- fictional regulatory standard (simplified game rule, not real safety certification)
	var violations: Array = []
	var allergens: Array = []
	for id in frac:
		var rec := DB.ing(id)
		var fin := float(frac[id]) * c * 100.0
		var reg: Dictionary = rec.get("reg", {})
		if reg.get("max") != null and fin > float(reg["max"]) + 0.0001:
			violations.append({"id": id, "pct": fin, "max": float(reg["max"])})
		if reg.get("allergen", false) and fin > 0.01:
			allergens.append(id)
	# ---- note pyramid
	var notes := {"top": [], "heart": [], "base": []}
	var ranked: Array = []
	for m in mats:
		var rec: Dictionary = m[0]
		if rec["role"] != "aromatic":
			continue
		ranked.append([float(rec["str"]) * float(m[1]), rec])
	ranked.sort_custom(func(a, b): return a[0] > b[0])
	for r in ranked:
		var rec: Dictionary = r[1]
		var nt_key: String = rec.get("note", "heart")
		if notes.has(nt_key) and notes[nt_key].size() < 4:
			notes[nt_key].append(short_name(rec))
	var res := {
		"valid": errors.is_empty() and violations.is_empty(),
		"errors": errors, "warnings": warnings, "total": total,
		"fmt": fmt_id, "conc": conc, "maturation": mat,
		"t": T_POINTS, "curve": curve, "pcurve": pcurve,
		"longevity": longevity, "sillage": sillage,
		"intensity": 1.0 - exp(-I0 / float(P["int_scale"])),
		"projection": 1.0 - exp(-proj0 / float(P["proj_scale"])),
		"open": v_open, "heart": v_heart, "dry": v_dry, "profile": v_all,
		"sweet": sweet, "cloying": cloying, "fresh": fresh, "warm": warm,
		"complexity": complexity, "tension": tension, "harsh": harsh, "anosmia": anos,
		"stability": {"oxidation": oxid, "discolor": disc, "cloud": cloud, "crystal": crystal, "sticky": sticky},
		"violations": violations, "allergens": allergens, "natural": natural_share,
		"tags": tags, "interactions": inter_names, "notes": notes,
		"aromatic_share": arom_total,
	}
	var v_fam := PackedFloat32Array()
	v_fam.resize(nd)
	for i in nd:
		v_fam[i] = 0.35 * v_open[i] + 0.35 * v_heart[i] + 0.3 * v_dry[i]
	res["family"] = family_name(v_fam, tags, frac)
	if not violations.is_empty():
		for v in violations:
			errors.append("%s at %.2f%% exceeds the FSC limit of %.2f%% (fictional rule)." % [short_name(DB.ing(v["id"])), v["pct"], v["max"]])
	return res


static func _inter_ok(ia: Dictionary, frac: Dictionary) -> bool:
	for g in ia.get("groups", []):
		var ok := false
		if g is Dictionary:
			var tot := 0.0
			for id in g["sum"]:
				tot += float(frac.get(id, 0.0))
			ok = tot >= float(g["min"])
		else:
			for alt in g:
				if float(frac.get(str(alt[0]), 0.0)) >= float(alt[1]):
					ok = true
					break
		if not ok:
			return false
	return true


static func _profile_at(mats: Array, t: float, add: PackedFloat32Array) -> PackedFloat32Array:
	var nd := DB.dims.size()
	var v := PackedFloat32Array()
	v.resize(nd)
	var tot := 0.0
	for m in mats:
		var rec: Dictionary = m[0]
		var ou := float(rec["str"]) * 100.0 * float(m[1]) * exp(-t / float(m[2]))
		tot += ou
		var vec: PackedFloat32Array = rec["vec"]
		for i in nd:
			v[i] += ou * vec[i]
	for i in nd:
		v[i] += add[i] * tot
	return G.vnorm(v)


static func _at(curve: PackedFloat32Array, t: float) -> float:
	for i in range(1, T_POINTS.size()):
		if t <= T_POINTS[i]:
			var t0: float = T_POINTS[i - 1]
			var t1: float = T_POINTS[i]
			var f := (t - t0) / maxf(0.0001, t1 - t0)
			return lerpf(curve[i - 1], curve[i], f)
	return curve[curve.size() - 1]


static func _cross_time(curve: PackedFloat32Array, thr: float) -> float:
	## Time (hours) when the curve last falls below thr; log-linear interpolation between samples.
	var n := curve.size()
	if curve[0] < thr and curve[1] < thr:
		return 0.0
	for i in range(1, n):
		if curve[i] < thr:
			var a := maxf(1e-6, curve[i - 1])
			var b2 := maxf(1e-6, curve[i])
			var f := (log(a) - log(thr)) / maxf(1e-6, log(a) - log(b2))
			return lerpf(T_POINTS[i - 1], T_POINTS[i], clampf(f, 0.0, 1.0))
	return T_POINTS[n - 1]


static func family_name(v: PackedFloat32Array, tags: Array, frac: Dictionary) -> String:
	if tags.has("chypre"):
		return "Chypre"
	if tags.has("fougere"):
		return "Aromatic Fougère"
	var idx: Array = []
	for i in v.size():
		idx.append(i)
	idx.sort_custom(func(a, b): return v[a] > v[b])
	var d1: String = DB.dims[idx[0]]
	var d2: String = DB.dims[idx[1]]
	var second := v[idx[1]] > 0.14
	var oud: float = float(frac.get("oud_natural", 0.0)) + float(frac.get("oud_accord", 0.0))
	match d1:
		"citrus":
			return "Citrus Aromatic" if (second and d2 == "aromatic") else ("Citrus Woody" if second and d2 == "woody" else "Citrus")
		"aromatic":
			return "Aromatic Woody" if second and d2 == "woody" else "Aromatic"
		"green":
			return "Green Floral" if second and d2 == "floral" else "Green"
		"aquatic":
			return "Fresh Aquatic"
		"floral":
			if second:
				match d2:
					"fruity": return "Floral Fruity"
					"powdery": return "Floral Powdery"
					"woody": return "Floral Woody"
					"musk": return "Floral Musky"
					"gourmand": return "Floral Gourmand"
					"green": return "Green Floral"
					"citrus": return "Floral Citrus"
					"animalic": return "White Floral"
			return "Floral"
		"fruity":
			return "Fruity Gourmand" if second and d2 == "gourmand" else ("Fruity Floral" if second and d2 == "floral" else "Fruity")
		"gourmand":
			return "Amber Gourmand" if second and d2 == "amber" else "Gourmand"
		"spicy":
			return "Spicy Woody" if second and d2 == "woody" else "Spicy"
		"woody":
			if oud > 0.02:
				return "Woody Oud"
			if second:
				match d2:
					"amber": return "Woody Amber"
					"spicy": return "Woody Spicy"
					"aromatic": return "Aromatic Woody"
					"animalic": return "Woody Leather"
					"musk": return "Woody Musky"
					"floral": return "Floral Woody"
			return "Woody"
		"amber":
			if second and d2 == "spicy":
				return "Amber Spicy"
			if second and d2 == "woody":
				return "Woody Amber"
			return "Amber"
		"musk":
			return "Musky Floral" if second and d2 == "floral" else "Musky"
		"powdery":
			return "Powdery Floral" if second and d2 == "floral" else "Powdery"
		"animalic":
			return "Oud" if oud > 0.02 else "Leather"
	return "Abstract"


static func top_dims(v: PackedFloat32Array, n := 3) -> Array:
	var idx: Array = []
	for i in v.size():
		idx.append(i)
	idx.sort_custom(func(a, b): return v[a] > v[b])
	var out: Array = []
	for i in mini(n, idx.size()):
		if v[idx[i]] > 0.04:
			out.append(DB.dims[idx[i]])
	return out


static func stability_label(st: Dictionary) -> String:
	var worst := 0.0
	for k in ["oxidation", "discolor", "cloud", "crystal"]:
		worst = maxf(worst, float(st.get(k, 0.0)))
	if worst < 0.25:
		return "Stable"
	if worst < 0.5:
		return "Monitor"
	return "At risk"


static func projection_label(p: float) -> String:
	if p < 0.25:
		return "Intimate"
	if p < 0.45:
		return "Moderate"
	if p < 0.65:
		return "Strong"
	if p < 0.82:
		return "Very strong"
	return "Enormous"


static func longevity_label(h: float) -> String:
	if h >= 36.0:
		return "36h+"
	return "%.1fh" % h


static func evaluate_product(p: Dictionary) -> Dictionary:
	var fv := G.formula_version(p["formula"], int(p.get("fv", -1)))
	if fv.is_empty():
		return {}
	return evaluate(fv["items"], p.get("fmt", "edp"), float(p.get("conc", 18.0)), {"maturation": int(p.get("maturation", 0))})


## Summed odor vector of a formula's raw composition (for search/similarity before evaluation).
static func raw_vector(items: Array) -> PackedFloat32Array:
	var v := PackedFloat32Array()
	v.resize(DB.dims.size())
	for it in items:
		var rec := DB.ing(str(it[0]))
		if rec.is_empty() or rec["role"] != "aromatic":
			continue
		var vec: PackedFloat32Array = rec["vec"]
		var w := float(it[1]) * float(rec["str"])
		for i in v.size():
			v[i] += vec[i] * w
	return G.vnorm(v)


static func normalize_items(items: Array, filler := "") -> Array:
	## Scales items to total 100%. If filler is given, the missing remainder is added as that material instead.
	var tot := 0.0
	for it in items:
		tot += float(it[1])
	var out: Array = []
	if tot <= 0.0:
		return out
	if filler != "" and tot < 100.0:
		for it in items:
			out.append([it[0], float(it[1])])
		var found := false
		for it in out:
			if it[0] == filler:
				it[1] = float(it[1]) + 100.0 - tot
				found = true
		if not found:
			out.append([filler, 100.0 - tot])
		return out
	for it in items:
		out.append([it[0], snappedf(float(it[1]) * 100.0 / tot, 0.01)])
	var t2 := 0.0
	for it in out:
		t2 += float(it[1])
	if out.size() > 0:
		out[0][1] = snappedf(float(out[0][1]) + 100.0 - t2, 0.01)
	return out


# ---------------------------------------------------------------- blotter (scent bar)
const PAPER := 1.7   # a paper blotter holds a scent noticeably longer than skin does

## Evaporation on a paper blotter, using the same material model as evaluate():
## [[rec, x (fraction of the finished product), tau (hours)]] for every odorous material.
static func blotter_mats(items: Array, fmt_id: String, conc: float) -> Array:
	var P: Dictionary = DB.bal["perf"]
	var fmt: Dictionary = DB.formats.get(fmt_id, DB.formats["edp"])
	var c := clampf(conc, 0.5, 40.0) / 100.0
	var oil: bool = fmt["base"] == "oil"
	var tot := 0.0
	for it in items:
		tot += maxf(0.0, float(it[1]))
	if tot <= 0.0:
		return []
	var F := 0.0
	var arom: Array = []
	for it in items:
		var rec := DB.ing(str(it[0]))
		if rec.is_empty() or float(it[1]) <= 0.0:
			continue
		var p := float(it[1]) / tot
		F += float(rec["fix"]) * p
		if rec["role"] == "aromatic" or float(rec.get("str", 0.0)) > 0.0:
			arom.append([rec, p])
	var out: Array = []
	for a in arom:
		var rec2: Dictionary = a[0]
		var ten := maxf(0.2, float(rec2["ten"]))
		var nv := clampf(log(1.0 + ten) / log(31.0), 0.0, 1.0)
		var tau := float(P["skin_a"]) * pow(ten, float(P["skin_b"])) * (1.0 + minf(float(P["fix_cap"]), float(P["fix_k"]) * F * (1.0 - nv))) * PAPER
		if oil:
			tau *= float(P["oil_tau"])
		out.append([rec2, float(a[1]) * c, tau])
	return out


## What a blotter smells like t hours after dipping: total odour units, materials by strength, profile.
static func blotter_at(mats: Array, t: float) -> Dictionary:
	var nd := DB.dims.size()
	var v := PackedFloat32Array()
	v.resize(nd)
	var per: Array = []
	var tot := 0.0
	for m in mats:
		var rec: Dictionary = m[0]
		var ou := float(rec["str"]) * 100.0 * float(m[1]) * exp(-t / float(m[2]))
		tot += ou
		per.append([rec["id"], ou])
		var vec: PackedFloat32Array = rec["vec"]
		for i in nd:
			v[i] += ou * vec[i]
	per.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	return {"total": tot, "per": per, "profile": G.vnorm(v), "detect": float(DB.bal["perf"]["detect"])}
