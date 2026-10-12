class_name PerfumerAI
extends RefCounted
## Autonomous formulation used by employee perfumers and rival companies.
## It composes real ingredient formulas and evaluates them with the SAME FormulaEngine as the player.
## Skill changes how consistently a brief is met; it never guarantees commercial success.


static func target_vec(target: Dictionary) -> PackedFloat32Array:
	var v := PackedFloat32Array()
	v.resize(DB.dims.size())
	for k in target:
		var i := DB.dim_index(k)
		if i >= 0:
			v[i] = float(target[k])
	return G.vnorm(v)


static func family_target(fam: String) -> Dictionary:
	return DB.bal["families"].get(fam, {"floral": 1.0})


## brief: {target(dict dims), fmt, conc?, posit, cost_kg_max?, longevity_min?}
## skill: {creativity, technique, cost}
static func generate(brief: Dictionary, skill: Dictionary, avail: Array, r: RandomNumberGenerator) -> Dictionary:
	var tech := float(skill.get("technique", 0.5))
	var tries := 1 + int(round(tech * 4.0))
	var best: Dictionary = {}
	for i in tries:
		var cand := _compose(brief, skill, avail, r)
		if cand.is_empty():
			continue
		if best.is_empty() or float(cand["fit"]) > float(best["fit"]):
			best = cand
	return best


static func _compose(brief: Dictionary, skill: Dictionary, avail: Array, r: RandomNumberGenerator) -> Dictionary:
	var creat := float(skill.get("creativity", 0.5))
	var tech := float(skill.get("technique", 0.5))
	var costw := float(skill.get("cost", 0.5))
	var tv := target_vec(brief.get("target", {"floral": 1.0}))
	# creative twist: an unexpected facet
	var twist := tv.duplicate()
	if r.randf() < creat:
		var d := r.randi_range(0, twist.size() - 1)
		twist[d] += creat * 0.35 * r.randf()
		twist = G.vnorm(twist)
	var posit: String = brief.get("posit", "premium")
	var budget := float(brief.get("cost_kg_max", DB.bal["ai"]["budget_ref"].get(posit, 200)))
	var fmt: String = brief.get("fmt", "edp")
	var f: Dictionary = DB.formats[fmt]
	var conc := float(brief.get("conc", float(f["def"]) + r.randf_range(-1.0, 1.0) * (float(f["max"]) - float(f["min"])) * 0.25))
	conc = clampf(conc, float(f["min"]), float(f["max"]))
	var layers := {"top": [], "heart": [], "base": []}
	for id in avail:
		var rec := DB.ing(id)
		if rec.is_empty() or rec["role"] != "aromatic":
			continue
		var sim := G.vcos(rec["vec"], twist)
		var sc := sim + creat * r.randf() * 0.45
		var cst := float(rec["cost"])
		sc -= costw * maxf(0.0, log(cst / maxf(5.0, budget))) * 0.22
		if (posit == "luxury" or posit == "niche") and rec.get("nat", false):
			sc += 0.08
		if sim < 0.15 and r.randf() > creat * 0.5:
			continue
		layers[rec["note"]].append([sc, id])
	var fresh := tv[DB.dim_index("citrus")] + tv[DB.dim_index("aromatic")] + tv[DB.dim_index("green")] + tv[DB.dim_index("aquatic")]
	var warm := tv[DB.dim_index("amber")] + tv[DB.dim_index("woody")] + tv[DB.dim_index("musk")] + tv[DB.dim_index("animalic")] + tv[DB.dim_index("gourmand")]
	var top_share := clampf(0.12 + 0.3 * fresh + r.randf_range(-0.03, 0.03), 0.08, 0.42)
	var base_share := clampf(0.28 + 0.25 * warm + float(brief.get("longevity_min", 0.0)) * 0.01, 0.22, 0.6)
	var solvent := r.randf_range(0.0, 0.06)
	var heart_share := maxf(0.15, 1.0 - top_share - base_share - solvent)
	var counts := {"top": 2 + r.randi_range(0, 1 + int(creat * 1.5)), "heart": 2 + r.randi_range(0, 2 + int(creat * 1.5)), "base": 3 + r.randi_range(0, 1 + int(creat * 1.5))}
	var shares := {"top": top_share, "heart": heart_share, "base": base_share}
	var items: Array = []
	var temp := float(DB.bal["ai"]["temp"]) * (1.15 - 0.6 * tech)
	for layer in layers:
		var cands: Array = layers[layer]
		if cands.is_empty():
			continue
		var chosen := _softpick(cands, int(counts[layer]), temp, r)
		var wsum := 0.0
		var ws: Array = []
		for id in chosen:
			var rec := DB.ing(id)
			var wv := maxf(0.08, G.vcos(rec["vec"], twist) + 0.2 + r.randf() * 0.3) / pow(maxf(0.15, float(rec["str"])), 0.6)
			ws.append(wv)
			wsum += wv
		for k in chosen.size():
			items.append([chosen[k], float(shares[layer]) * float(ws[k]) / wsum * 100.0])
	if items.is_empty():
		return {}
	# technique: respect potency, regulations and stabilizers
	var c := conc / 100.0
	for it in items:
		var rec := DB.ing(it[0])
		if float(rec["str"]) >= 2.4:
			var cap := 1.5 if it[0] == "calone" else (2.5 if it[0] == "ethyl_maltol" else 4.0)
			if r.randf() < 0.4 + tech:
				it[1] = minf(float(it[1]), cap)
		var mx: Variant = rec.get("reg", {}).get("max")
		if mx != null and r.randf() < 0.55 + tech:
			it[1] = minf(float(it[1]), float(mx) / c * 0.95)
	var citrus := 0.0
	var cryst := 0.0
	var resin := 0.0
	for it in items:
		var rec := DB.ing(it[0])
		if rec["cat"] == "Citrus oil" or it[0] == "aldehyde_c12":
			citrus += float(it[1])
		if rec.get("cryst", false):
			cryst += float(it[1])
		if float(rec.get("sol", 1.0)) < 0.75:
			resin += float(it[1])
	if citrus > 8.0 and r.randf() < tech + 0.2:
		items.append(["bht", 0.2])
	if (cryst > 10.0 or resin > 10.0) and r.randf() < tech + 0.2:
		items.append(["benzyl_benzoate", 4.0 + (cryst + resin) * 0.2])
	var tot := 0.0
	for it in items:
		tot += float(it[1])
	if tot < 100.0:
		items.append(["dpg", 100.0 - tot])
	items = FormulaEngine.normalize_items(_merge(items))
	var ev := FormulaEngine.evaluate(items, fmt, conc)
	var fit := G.vcos(ev["profile"], tv) - 0.6 * maxf(0.0, float(ev["cost_kg"]) / budget - 1.0) - 0.4 * float(ev["tension"]) - 0.5 * float(ev["harsh"])
	if brief.has("longevity_min"):
		fit -= 0.08 * maxf(0.0, float(brief["longevity_min"]) - float(ev["longevity"]))
	if not ev["violations"].is_empty():
		fit -= 0.3
	return {"items": items, "fmt": fmt, "conc": snappedf(conc, 0.5), "ev": ev, "fit": fit, "cost_kg": ev["cost_kg"]}


static func _softpick(cands: Array, k: int, temp: float, r: RandomNumberGenerator) -> Array:
	var pool := cands.duplicate()
	var out: Array = []
	for n in mini(k, pool.size()):
		var tot := 0.0
		var ws: Array = []
		for c in pool:
			var wv := exp(float(c[0]) / maxf(0.05, temp))
			ws.append(wv)
			tot += wv
		var u := r.randf() * tot
		var pick := 0
		for i in ws.size():
			u -= float(ws[i])
			if u <= 0.0:
				pick = i
				break
		out.append(pool[pick][1])
		pool.remove_at(pick)
	return out


static func _merge(items: Array) -> Array:
	var d := {}
	var order: Array = []
	for it in items:
		if not d.has(it[0]):
			d[it[0]] = 0.0
			order.append(it[0])
		d[it[0]] = float(d[it[0]]) + float(it[1])
	var out: Array = []
	for id in order:
		if float(d[id]) > 0.009:
			out.append([id, float(d[id])])
	return out


static func name_for(ev: Dictionary, r: RandomNumberGenerator) -> String:
	var nw: Dictionary = DB.names["name_words"]
	var key := {"citrus": "Citrus", "aromatic": "Lavande", "green": "Fig", "aquatic": "Tide", "floral": "Rose", "fruity": "Peach",
		"gourmand": "Vanille", "spicy": "Saffron", "woody": "Cedar", "amber": "Amber", "musk": "Musk", "powdery": "Iris", "animalic": "Oud"}
	var tops := FormulaEngine.top_dims(ev.get("profile", PackedFloat32Array()), 1)
	var k: String = key.get(tops[0], "Essence") if not tops.is_empty() else "Essence"
	match r.randi_range(0, 5):
		0:
			return "%s %s" % [G.pick(nw["adj"], r), G.pick(nw["noun"], r)]
		1:
			return str(G.pick(nw["single"], r))
		2:
			return "%s %s" % [G.pick(nw["adj"], r), k]
		3:
			return "%s de %s" % [G.pick(nw["french"], r), G.pick(nw["french"], r)]
		4:
			return "%s No. %d" % [G.pick(nw["noun"], r), r.randi_range(1, 99)]
	return "%s %s" % [k, G.pick(nw["noun"], r)]


static func concept_line(ev: Dictionary, fam: String, r: RandomNumberGenerator) -> String:
	var tops := FormulaEngine.top_dims(ev["profile"], 3)
	var words: Array = []
	for d in tops:
		words.append(ReviewEngine._p(DB.texts["dim_words"][d], r))
	var notes: Dictionary = ev["notes"]
	var hero := ""
	for k in ["heart", "base", "top"]:
		if not notes[k].is_empty():
			hero = notes[k][0]
			break
	return "A %s built around %s: %s." % [fam.to_lower(), hero, ", ".join(words)]
