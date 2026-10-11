class_name OpponentAI
extends RefCounted
## Rakip şef yapay zekâsı. Kararlarını maç koşullarına göre verir:
## temaya, jüri mutasyonlarına, skor durumuna ve kendi karakterine uygun yemekleri tahmin eder ve seçer.
## Tüm rastgelelik maç tohumundan türetildiği için aynı maç aynı kararları üretir.

const BASIC := ["sugar", "chocolate", "strawberry", "lemon", "tomato", "chili", "cheese", "milk", "flour", "egg", "honey", "frog_essence"]

var data: Dictionary
var id: String
var difficulty := 1
var skill := 0.6
var skill_sd := 0.1
var smart := 0.5
var rng := RandomNumberGenerator.new()
var line_rng := RandomNumberGenerator.new()   # sadece kozmetik replikler için; oyun kararlarını etkilemez
var used_dishes: Array = []
var sabotage_count := 0
var last_abilities: Array = []
var known_recipes: Array = []
const PLATE_BUDGET := [0, 60, 150, 220, 9999]


func _init(opp: Dictionary, diff: int, seed_value: int) -> void:
	data = opp
	id = opp["id"]
	difficulty = clampi(diff, 1, 5)
	skill = clampf(float(opp.get("skill", 0.6)) - 0.06 + (difficulty - 1) * 0.045, 0.3, 0.95)
	skill_sd = float(opp.get("skill_sd", 0.1))
	smart = clampf(float(opp.get("smart", 0.5)) - 0.1 + (difficulty - 1) * 0.07, 0.1, 0.95)
	rng.seed = seed_value
	# Rakibin bildiği el yapımı tarifler zorlukla artar (maç başına deterministik)
	var know := 0.16 + 0.14 * difficulty
	if difficulty == 1:
		skill -= 0.04
	for rid in IngredientDatabase.recipe_order:
		if rng.randf() < know:
			known_recipes.append(rid)
	line_rng.seed = seed_value ^ 0x5bd1e995


func pantry(mystery: String) -> Array:
	var p: Array = []
	for i in data.get("preferred", []):
		if not p.has(i) and IngredientDatabase.ingredients.has(i):
			p.append(i)
	for i in BASIC:
		if not p.has(i):
			p.append(i)
	if mystery != "" and not p.has(mystery):
		p.append(mystery)
	return p


func _resolvable(item_id: String, pantry_ids: Array, depth: int) -> bool:
	if pantry_ids.has(item_id):
		return true
	if depth <= 0:
		return false
	var r: Dictionary = IngredientDatabase.recipes.get(item_id, {})
	if r.is_empty() or r.get("method") is String:
		return false
	for inp in r.get("inputs", []):
		if not _resolvable(str(inp), pantry_ids, depth - 1):
			return false
	return true


func _fusions_available(pantry_ids: Array) -> Array:
	var res: Array = []
	for rid in IngredientDatabase.recipe_order:
		var r: Dictionary = IngredientDatabase.recipes[rid]
		if r.get("kind", "") == "fusion" and _resolvable(rid, pantry_ids, 2):
			res.append(rid)
	return res


## Bu tur için yemek planla. state: {theme, mutations, round, mystery, banned, rules, player_total, opp_total}
func plan_dish(state: Dictionary) -> Dictionary:
	var mystery: String = state.get("mystery", "")
	var banned: Array = state.get("banned", [])
	var p := pantry(mystery)
	var fusions := _fusions_available(p)
	var pool: Array = p + fusions
	var methods: Array = []
	for m in IngredientDatabase.METHOD_ORDER:
		if not banned.has(m):
			methods.append(m)
	var pref_methods: Array = []
	for m in data.get("methods", []):
		if methods.has(m):
			pref_methods.append(m)
	if pref_methods.is_empty():
		pref_methods = methods.duplicate()
	var cands: Array = []   # [{inputs, method}]
	# 1) Ulaşılabilen el yapımı tarifler (gizli tarifler oyuncunun keşfi için ayrılır)
	for rid in IngredientDatabase.recipe_order:
		var r: Dictionary = IngredientDatabase.recipes[rid]
		if r.get("kind", "") != "dish" or r.get("secret", false) or not known_recipes.has(rid):
			continue
		var m: String = r.get("method", "")
		if banned.has(m):
			continue
		var ok := true
		for inp in r.get("inputs", []):
			if not _resolvable(str(inp), p, 2):
				ok = false
				break
		if ok:
			cands.append({"inputs": r["inputs"].duplicate(), "method": m})
	# 2) Rastgele denemeler
	var tries := 16 + difficulty * 4
	for t in tries:
		var n := 2
		if difficulty >= 4 and rng.randf() < 0.3:
			n = 3
		var inputs: Array = []
		if mystery != "":
			inputs.append(mystery)
		var guard := 0
		while inputs.size() < n and guard < 20:
			guard += 1
			var pick: String = pool[rng.randi() % pool.size()]
			if not inputs.has(pick):
				inputs.append(pick)
		var meth: String = pref_methods[rng.randi() % pref_methods.size()] if rng.randf() < 0.75 else methods[rng.randi() % methods.size()]
		cands.append({"inputs": inputs, "method": meth})
	# Değerlendir
	var scored: Array = []
	var behind: bool = float(state.get("opp_total", 0.0)) < float(state.get("player_total", 0.0)) - 2.0
	var likes: Array = data.get("likes_tags", [])
	for c in cands:
		var dish := FusionEngine.cook(c["inputs"], c["method"])
		if mystery != "" and not FusionEngine.contains_ingredient(dish["id"], mystery):
			continue
		if used_dishes.has(dish["id"]):
			continue
		var plating := best_plating(dish, state.get("theme", {}), false)
		var ctx := {"theme": state.get("theme", {}), "quality": skill, "plate": plating["plate"], "garnish": plating["garnish"],
			"living": "caught" if dish.get("living", "") != "" and skill > 0.7 else "none", "rules": state.get("rules", []),
			"round": state.get("round", 1)}
		var ev := JudgeSystem.evaluate(dish, ctx)
		var jr := JudgeSystem.judge_all(dish, ev, state.get("mutations", {}), {"rules": state.get("rules", []), "round": state.get("round", 1)})
		var est: float = jr["total"]
		var pref := 0
		for t in likes:
			if dish["tags"].has(t):
				pref += 1
		var sort_v := est + minf(1.2, pref * 0.6)
		if behind:
			sort_v += ev["axes"]["creativity"] * 0.15
		scored.append({"dish": dish, "inputs": c["inputs"], "method": c["method"], "est": est, "v": sort_v})
	if scored.is_empty():
		var fallback := FusionEngine.cook([p[0], p[1]], pref_methods[0])
		return {"dish": fallback, "inputs": [p[0], p[1]], "method": pref_methods[0], "est": 0.0}
	scored.sort_custom(func(a, b):
		if absf(a["v"] - b["v"]) > 0.0001:
			return a["v"] > b["v"]
		return str(a["dish"]["id"]) < str(b["dish"]["id"]))
	var idx := 0
	if rng.randf() > smart:
		idx = rng.randi() % mini(8 - difficulty, scored.size())
	var choice: Dictionary = scored[idx]
	used_dishes.append(choice["dish"]["id"])
	return choice


func cook_quality(rules: Array) -> float:
	var sd := skill_sd
	if rules.has("precise_cooking") and id == "x3000":
		sd *= 0.5
	return clampf(rng.randfn(skill, sd), 0.3, 0.97)


func best_plating(dish: Dictionary, theme: Dictionary, use_rng := true) -> Dictionary:
	var best := {"plate": "classic", "garnish": "none", "v": -99.0}
	var all: Array = []
	var budget: int = PLATE_BUDGET[difficulty - 1]
	for pid in IngredientDatabase.plate_order:
		if int(IngredientDatabase.plates[pid].get("price", 0)) > budget:
			continue
		for gid in IngredientDatabase.garnish_order:
			if int(IngredientDatabase.garnishes[gid].get("price", 0)) > budget:
				continue
			var ev := JudgeSystem.evaluate(dish, {"theme": theme, "quality": 0.7, "plate": pid, "garnish": gid})
			var v: float = ev["axes"]["presentation"]
			all.append({"plate": pid, "garnish": gid, "v": v})
	all.sort_custom(func(a, b):
		if absf(a["v"] - b["v"]) > 0.0001:
			return a["v"] > b["v"]
		return str(a["plate"]) + str(a["garnish"]) < str(b["plate"]) + str(b["garnish"]))
	best = all[0]
	if use_rng and rng.randf() > smart:
		best = all[rng.randi() % mini(6, all.size())]
	return best


func living_result(dish: Dictionary) -> String:
	if str(dish.get("living", "")) == "":
		return "none"
	return "caught" if rng.randf() < 0.5 + skill * 0.45 else "escaped"


## Tur başında sabotaj kararı. Döndürür: yetenek kimlikleri listesi (boş olabilir).
func decide_sabotage(round_no: int, state: Dictionary) -> Array:
	var rules: Array = state.get("rules", [])
	var ab: String = data.get("ability", {}).get("id", "")
	var prob: float = [0.45, 0.6, 0.7, 0.8, 0.88][difficulty - 1]
	var lead: float = float(state.get("player_total", 0.0)) - float(state.get("opp_total", 0.0))
	if lead > 2.0:
		prob += 0.25
	elif lead < -4.0:
		prob -= 0.25
	var force := rules.has("sabotage_every_round") or rules.has("double_ability")
	if round_no >= 2 and sabotage_count == 0:
		force = true
	var roll := rng.randf()
	if not force and roll > prob:
		return []
	var res: Array = []
	if ab == "shadow_combo":
		var count := 1
		if rules.has("double_ability") and round_no >= 2:
			count = 2
		var pool: Array = SabotageSystem.OBSCURA_POOL.duplicate()
		for a in last_abilities:
			pool.erase(a)
		var used_phases: Array = []
		while res.size() < count and not pool.is_empty():
			var pick: String = pool[rng.randi() % pool.size()]
			pool.erase(pick)
			var ph := SabotageSystem.phase_of(pick)
			if used_phases.has(ph):
				continue
			used_phases.append(ph)
			res.append(pick)
	else:
		res.append(ab)
	last_abilities = res.duplicate()
	sabotage_count += res.size()
	return res


func line(kind: String) -> String:
	var arr: Array = data.get(kind, [])
	if arr is Array and not arr.is_empty():
		return arr[line_rng.randi() % arr.size()]
	var s: Variant = data.get(kind, "")
	return s if s is String else ""
