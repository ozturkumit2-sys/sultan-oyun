class_name JudgeSystem
extends RefCounted
## Yemekleri gerçek özelliklerine ve oyuncu kararlarına göre puanlar.
## Beş eksen (0-10): Lezzet, Pişirme, Tema, Sunum, Yaratıcılık. Her jüri bunları kendi ağırlıklarıyla toplar.

const AXES := ["flavor", "cooking", "theme", "presentation", "creativity"]
const AXIS_NAMES := {"flavor": "Lezzet", "cooking": "Pişirme", "theme": "Tema", "presentation": "Sunum", "creativity": "Yaratıcılık"}
const AXIS_COLORS := {"flavor": Color("#ff6b5a"), "cooking": Color("#ffb020"), "theme": Color("#4a9dff"),
	"presentation": Color("#ff5fa2"), "creativity": Color("#a25cff")}


static func harmony(dish: Dictionary) -> float:
	var m: String = dish.get("method", "")
	if m == "":
		return 0.0
	var md: Dictionary = IngredientDatabase.methods.get(m, {})
	var tags: Array = dish.get("tags", [])
	var likes := 0
	var dislikes := 0
	for t in md.get("likes", []):
		if tags.has(t):
			likes += 1
	for t in md.get("dislikes", []):
		if tags.has(t):
			dislikes += 1
	return clampf(likes * 0.5 - dislikes * 0.7, -1.5, 1.5)


static func theme_score(dish: Dictionary, theme: Dictionary) -> float:
	if theme.is_empty():
		return 5.0
	var s: Dictionary = dish["stats"]
	var target: Dictionary = theme.get("target", {})
	var stat_score := 0.0
	var n := 0
	for k in target.keys():
		var rng: Array = target[k]
		var v: float = s.get(k, 0.0)
		var lo := float(rng[0])
		var hi := float(rng[1])
		var dist := 0.0
		if v < lo:
			dist = lo - v
		elif v > hi:
			dist = v - hi
		stat_score += maxf(0.0, 1.0 - dist / 35.0)
		n += 1
	stat_score = stat_score / n if n > 0 else 0.5
	var tags: Array = dish.get("tags", [])
	var matches := 0
	for t in theme.get("tags", []):
		if tags.has(t):
			matches += 1
	var tag_score := minf(1.0, matches / 2.0)
	var methods: Array = theme.get("methods", [])
	var method_score := 0.5
	if not methods.is_empty():
		method_score = 1.0 if methods.has(dish.get("method", "")) else 0.0
	return 10.0 * (0.5 * stat_score + 0.35 * tag_score + 0.15 * method_score)


## ctx anahtarları: theme(Dictionary), quality(0..1), plate, garnish, living ("none"/"caught"/"escaped"),
## first(bool), repeat(bool), specs(Dictionary), rules(Array), mods(Dictionary: flavor/cooking/presentation/creativity)
static func evaluate(dish: Dictionary, ctx: Dictionary) -> Dictionary:
	var s: Dictionary = dish["stats"]
	var tags: Array = dish.get("tags", [])
	var q: float = clampf(float(ctx.get("quality", 0.7)), 0.0, 1.0)
	var specs: Dictionary = ctx.get("specs", {})
	var rules: Array = ctx.get("rules", [])
	var mods: Dictionary = ctx.get("mods", {})
	var theme: Dictionary = ctx.get("theme", {})
	var h := harmony(dish)
	var hand: bool = dish.get("handcrafted", false)
	var notes: Array = []

	# --- Lezzet
	var peak := maxf(s["sweet"], s["spicy"])
	var flavor: float = 1.6 + peak * 0.035 + s["fresh"] * 0.028 - s["toxic"] * 0.065 - maxf(0.0, s["volatile"] - 60.0) * 0.03
	flavor += h * 0.8 + (q - 0.6) * 2.0
	if s["sweet"] > 55.0 and s["spicy"] > 55.0 and not hand:
		flavor -= 1.0
		notes.append("clash")
	if hand:
		flavor += 1.2
		if int(specs.get("fusion", 0)) >= 1:
			flavor += 0.5
	flavor += float(mods.get("flavor", 0.0))

	# --- Pişirme
	var cooking: float = 1.0 + q * 8.0 + h * 0.5 + float(mods.get("cooking", 0.0))

	# --- Tema
	var theme_v := theme_score(dish, theme)

	# --- Sunum
	var pres: float = 2.0 + q * 1.5 + s["rarity"] * 0.012
	var plate: Dictionary = IngredientDatabase.plates.get(ctx.get("plate", "classic"), {})
	pres += float(plate.get("elegance", 1.0))
	var theme_tags: Array = theme.get("tags", [])
	for t in plate.get("tags", []):
		if tags.has(t) or theme_tags.has(t):
			pres += 0.8
			notes.append("plate_match")
			break
	var g: Dictionary = IngredientDatabase.garnishes.get(ctx.get("garnish", "none"), {})
	if not g.is_empty() and g["id"] != "none":
		var good := 0
		var bad := 0
		for t in g.get("tags", []):
			if tags.has(t) or theme_tags.has(t):
				good += 1
		for t in g.get("bad", []):
			if tags.has(t):
				bad += 1
		if bad > 0:
			pres -= 1.0
			notes.append("garnish_bad")
		elif good > 0:
			pres += 1.2
			if int(specs.get("artist", 0)) >= 2:
				pres += 0.5
			notes.append("garnish_good")
		else:
			pres += 0.3
	var living: String = ctx.get("living", "none")
	if living == "caught":
		pres += 1.2
		if int(specs.get("artist", 0)) >= 3:
			pres += 0.5
	elif living == "escaped":
		pres -= 1.5
	if int(specs.get("artist", 0)) >= 1:
		pres += 0.5
	pres += float(mods.get("presentation", 0.0))

	# --- Yaratıcılık
	var cre: float = 1.2 + s["weird"] * 0.032 + s["magic"] * 0.026 + s["rarity"] * 0.03 + float(dish.get("depth", 1)) * 0.55
	if ctx.get("first", false):
		cre += 1.5
		if int(specs.get("fusion", 0)) >= 3:
			cre += 0.5
	if str(dish.get("living", "")) != "":
		cre += 0.8
		if rules.has("living_bonus"):
			cre += 1.0
	if dish.get("inputs", []).size() >= 3:
		cre += 0.4
	if ctx.get("repeat", false):
		cre -= 2.5
	if tags.has("classic"):
		cre -= 0.5
	cre += float(mods.get("creativity", 0.0))

	var axes := {
		"flavor": clampf(flavor, 0.0, 10.0),
		"cooking": clampf(cooking, 0.0, 10.0),
		"theme": clampf(theme_v, 0.0, 10.0),
		"presentation": clampf(pres, 0.0, 10.0),
		"creativity": clampf(cre, 0.0, 10.0),
	}
	return {"axes": axes, "harmony": h, "notes": notes}


static func _weights(judge: Dictionary, mutation: Dictionary, rules: Array) -> Dictionary:
	var w: Dictionary = judge["weights"].duplicate()
	for k in AXES:
		w[k] = float(w.get(k, 0.0))
	var shift: Dictionary = mutation.get("weight_shift", {})
	for k in shift.keys():
		w[k] = maxf(0.0, float(w.get(k, 0.0)) + float(shift[k]))
	if rules.has("precise_cooking"):
		w["cooking"] += 0.12
	var total := 0.0
	for k in AXES:
		total += w[k]
	if total <= 0.0:
		total = 1.0
	for k in AXES:
		w[k] = w[k] / total
	return w


## Bir jürinin puanını ve gerekçesini hesaplar.
## ctx: rules, specs, is_player, charmed(bool), judge_mods(Dictionary), first, repeat, living
static func judge_score(judge: Dictionary, ev: Dictionary, dish: Dictionary, mutation_id: String, ctx: Dictionary) -> Dictionary:
	var rules: Array = ctx.get("rules", [])
	var mutation: Dictionary = IngredientDatabase.mutations.get(mutation_id, {}) if mutation_id != "" else {}
	var w := _weights(judge, mutation, rules)
	var ax: Dictionary = ev["axes"].duplicate()
	if mutation.has("amplify"):
		ax["flavor"] = clampf(5.0 + (ax["flavor"] - 5.0) * float(mutation["amplify"]), 0.0, 10.0)
	var base := 0.0
	var contrib := {}
	for k in AXES:
		base += w[k] * ax[k]
		contrib[k] = w[k] * (ax[k] - 5.0)
	var tags: Array = dish.get("tags", [])
	var s: Dictionary = dish["stats"]
	var bonus := 0.0
	var pen := 0.0
	var reason_keys: Array = []
	var likes := 0
	for t in judge.get("likes", []):
		if tags.has(t):
			likes += 1
	var dislikes := 0
	for t in judge.get("dislikes", []):
		if tags.has(t):
			dislikes += 1
	bonus += minf(1.2, likes * 0.4)
	pen += minf(1.5, dislikes * 0.5)
	if judge["id"] == "bruno" and s["toxic"] > 40.0:
		pen += (s["toxic"] - 40.0) * 0.03
		reason_keys.append("toxic")
	var mut_effect := 0.0
	if not mutation.is_empty():
		for t in mutation.get("likes", []):
			if tags.has(t):
				mut_effect += float(mutation.get("like_bonus", 0.0))
				break
		for t in mutation.get("dislikes", []):
			if tags.has(t):
				mut_effect -= 1.0
				break
		if ctx.get("is_player", false) and int(ctx.get("specs", {}).get("chaos", 0)) >= 2:
			mut_effect += 0.3
	if ctx.get("charmed", false) and judge["id"] == "max":
		bonus += 0.5
	var extra: float = float(ctx.get("judge_mods", {}).get(judge["id"], 0.0))
	var raw := base + bonus - pen + mut_effect + extra
	var score := clampf(raw, 0.0, 10.0)
	score = roundf(score * 2.0) / 2.0

	# --- gerekçe
	var best_k := ""
	var best_v := 0.0
	for k in AXES:
		if absf(contrib[k]) > absf(best_v):
			best_v = contrib[k]
			best_k = k
	if best_k != "":
		reason_keys.push_front(best_k + ("_hi" if best_v >= 0.0 else "_lo"))
	if ctx.get("first", false) and judge["id"] == "mira":
		reason_keys.append("first")
	if ctx.get("repeat", false) and judge["id"] == "mira":
		reason_keys.push_front("repeat")
	if judge["id"] == "max":
		if ctx.get("living", "none") == "escaped":
			reason_keys.push_front("messy")
		elif ctx.get("living", "none") == "caught":
			reason_keys.append("living_ok")
	var pre_score := clampf(base + bonus - pen + mut_effect, 0.0, 10.0)
	if likes > 0 and pre_score >= 5.0:
		reason_keys.append("like")
	if dislikes > 0 and pre_score < 7.5:
		reason_keys.append("dislike")
	var reasons: Dictionary = judge.get("reasons", {})
	var texts: Array = []
	for rk in reason_keys:
		var tx := ""
		if reasons.has(rk):
			tx = reasons[rk]
		else:
			tx = _generic_reason(rk)
		if tx != "" and not texts.has(tx):
			texts.append(tx)
		if texts.size() >= 2:
			break
	if not mutation.is_empty() and absf(mut_effect) > 0.05:
		texts.append("(Mutasyon etkisi: %s%.1f)" % ["+" if mut_effect > 0 else "", mut_effect])
	var tier := "high" if score >= 7.5 else ("mid" if score >= 4.5 else "low")
	var lines: Array = judge.get("lines", {}).get(tier, ["..."])
	var h := FusionEngine.fnv(str(dish.get("id", "")) + str(judge["id"]) + str(ctx.get("round", 0)))
	var quip: String = lines[h % lines.size()]
	return {"score": score, "raw": raw, "reason": " ".join(PackedStringArray(texts)), "quip": quip, "tier": tier,
		"weights": w, "axes": ax, "mutation_effect": mut_effect,
		"reaction": pick_reaction(judge, score, dish, likes > 0)}


static func _generic_reason(key: String) -> String:
	var parts := key.split("_")
	if parts.size() != 2:
		return ""
	var ax: String = AXIS_NAMES.get(parts[0], "")
	if ax == "":
		return ""
	return "%s %s." % [ax, "çok iyi" if parts[1] == "hi" else "zayıf"]


static func pick_reaction(judge: Dictionary, score: float, dish: Dictionary, liked: bool) -> String:
	var s: Dictionary = dish["stats"]
	var h := FusionEngine.fnv(str(dish.get("id", "")) + str(judge["id"]))
	if score >= 9.0:
		return "love" if liked or h % 2 == 0 else "cry"
	if s["magic"] >= 72.0 and score >= 6.0:
		return "float"
	if score >= 7.5:
		return "laugh" if s["weird"] >= 50.0 or h % 3 == 0 else "cheer"
	if score >= 5.5:
		if s["weird"] >= 55.0:
			return "surprised"
		return "laugh" if str(dish.get("living", "")) != "" else "cheer"
	if score >= 3.0:
		if s["spicy"] >= 70.0 or s["toxic"] >= 40.0:
			return "cough"
		return "disgust" if h % 3 != 0 else "surprised"
	return "faint"


## Bütün jüri için puanlama. Döndürür: {judges: {id: result}, total, ev}
static func judge_all(dish: Dictionary, ev: Dictionary, mutations: Dictionary, ctx: Dictionary) -> Dictionary:
	var out := {}
	var total := 0.0
	for j in IngredientDatabase.judges:
		var r := judge_score(j, ev, dish, str(mutations.get(j["id"], "")), ctx)
		out[j["id"]] = r
		total += r["score"]
	return {"judges": out, "total": total, "ev": ev}


## Jüri puanları arasındaki fark tartışma eşiğini aşıyor mu?
static func disagreement(results: Dictionary) -> float:
	var mn := 99.0
	var mx := -99.0
	for k in results.keys():
		var sc: float = results[k]["score"]
		mn = minf(mn, sc)
		mx = maxf(mx, sc)
	return mx - mn
