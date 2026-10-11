class_name MutationSystem
extends RefCounted
## Jüri mutasyonları: belirli yemekler tadan jüriyi geçici olarak dönüştürür.
## Her jüride aynı anda en fazla bir mutasyon olabilir (sınırsız birikme yok).
## Normal maçta mutasyonlar tur sonunda etkinleşir ve maç bitince silinir.

const CATEGORY_NAMES := {"cosmetic": "Görsel", "taste": "Damak Değişimi", "chaos": "Kaos"}


static func chaos_level(dish: Dictionary) -> float:
	var s: Dictionary = dish["stats"]
	return (s["weird"] + s["magic"] + s["volatile"] + s["life"]) / 4.0


## Yemeğin tetikleyebileceği mutasyonu ve hedef jüriyi döndürür; yoksa boş sözlük.
## active: {judge_id: mutation_id}; scores: {judge_id: float}
static func check(dish: Dictionary, scores: Dictionary, active: Dictionary, ctx: Dictionary) -> Dictionary:
	var threshold := 31.0
	var rules: Array = ctx.get("rules", [])
	if rules.has("mutations_plus"):
		threshold = 21.0
	if ctx.get("is_player", false) and int(ctx.get("specs", {}).get("chaos", 0)) >= 2:
		threshold -= 6.0
	if chaos_level(dish) < threshold:
		return {}
	var tags: Array = dish.get("tags", [])
	var s: Dictionary = dish["stats"]
	var candidates: Array = []
	for mid in IngredientDatabase.mutation_order:
		var m: Dictionary = IngredientDatabase.mutations[mid]
		var rule: Dictionary = m.get("rule", {})
		var any: Array = rule.get("tags_any", [])
		if not any.is_empty():
			var ok := false
			for t in any:
				if tags.has(t):
					ok = true
					break
			if not ok:
				continue
		var mins: Dictionary = rule.get("min", {})
		var pass_all := true
		for k in mins.keys():
			if float(s.get(k, 0.0)) < float(mins[k]):
				pass_all = false
				break
		if pass_all:
			candidates.append(mid)
	if candidates.is_empty():
		return {}
	var h := FusionEngine.fnv(str(dish.get("id", "")) + str(ctx.get("round", 0)))
	var pick: String = candidates[h % candidates.size()]
	# En güçlü tepki veren ve henüz mutasyonu olmayan jüri
	var order: Array = []
	var idx := 0
	for j in IngredientDatabase.judges:
		order.append({"id": j["id"], "v": absf(float(scores.get(j["id"], 5.0)) - 5.0), "i": idx})
		idx += 1
	order.sort_custom(func(a, b):
		if absf(a["v"] - b["v"]) > 0.001:
			return a["v"] > b["v"]
		return a["i"] < b["i"])
	for o in order:
		if not active.has(o["id"]):
			return {"judge": o["id"], "mutation": pick}
	return {}


static func describe(mutation_id: String) -> String:
	return IngredientDatabase.mutations.get(mutation_id, {}).get("desc", "")


static func mutation_name(mutation_id: String) -> String:
	return IngredientDatabase.mutations.get(mutation_id, {}).get("name", mutation_id)
