extends Node
## DailyChallengeManager — çevrimdışı günlük meydan okuma.
## Her gün yerel tarih + içerik sürümünden üretilen tohumla aynı meydan okuma oluşur.
## Not: Cihaz saatine bağlıdır; çevrim içi sıralama yoktur (ileride eklenebilecek şekilde ayrık tutuldu).

const REWARD := 150
const TARGET := 18.0


func today_key() -> String:
	return Time.get_date_string_from_system()


func _usable_ingredients() -> Array:
	var res: Array = []
	for id in IngredientDatabase.ingredient_order:
		var u: Dictionary = IngredientDatabase.ingredients[id].get("unlock", {})
		if u.get("type", "") != "special":
			res.append(id)
	return res


func challenge(date := "") -> Dictionary:
	var key := date if date != "" else today_key()
	var base_seed := FusionEngine.fnv("daily:%s:v%d" % [key, IngredientDatabase.content_version])
	var rng := RandomNumberGenerator.new()
	var pool := _usable_ingredients()
	var basics: Array = []
	for id in pool:
		if IngredientDatabase.ingredients[id].get("unlock", {}).get("type", "") == "start":
			basics.append(id)
	var chosen: Array = []
	# Elle hazırlanmış en az bir tarifin yapılabildiği bir pick_set bulmaya çalış
	for attempt in 24:
		rng.seed = base_seed + attempt * 7919
		var pick_set: Array = []
		while pick_set.size() < 2:
			var b: String = basics[rng.randi() % basics.size()]
			if not pick_set.has(b):
				pick_set.append(b)
		while pick_set.size() < 5:
			var c: String = pool[rng.randi() % pool.size()]
			if not pick_set.has(c):
				pick_set.append(c)
		chosen = pick_set
		if _has_recipe(pick_set):
			break
	rng.seed = base_seed ^ 0xabcdef
	var theme_id: String = IngredientDatabase.theme_order[rng.randi() % IngredientDatabase.theme_order.size()]
	var judge: Dictionary = IngredientDatabase.judges[rng.randi() % IngredientDatabase.judges.size()]
	var muts: Array = []
	for m in IngredientDatabase.mutation_order:
		if IngredientDatabase.mutations[m].get("category", "") != "cosmetic":
			muts.append(m)
	var mut: String = muts[rng.randi() % muts.size()]
	return {"date": key, "ingredients": chosen, "theme": theme_id,
		"condition": {"judge": judge["id"], "mutation": mut}, "reward": REWARD, "target": TARGET, "rules": []}


func _has_recipe(pick_set: Array) -> bool:
	for rid in IngredientDatabase.recipe_order:
		var r: Dictionary = IngredientDatabase.recipes[rid]
		if r.get("kind", "") != "dish" or r.get("secret", false):
			continue
		if _resolvable(rid, pick_set, 3):
			return true
	return false


func _resolvable(id: String, pick_set: Array, depth: int) -> bool:
	if pick_set.has(id):
		return true
	if depth <= 0:
		return false
	var r: Dictionary = IngredientDatabase.recipes.get(id, {})
	if r.is_empty():
		return false
	for inp in r.get("inputs", []):
		if not _resolvable(str(inp), pick_set, depth - 1):
			return false
	return true


func _state() -> Dictionary:
	var dd: Dictionary = SaveManager.data["daily"]
	var today := today_key()
	if dd.get("date", "") != today:
		if dd.get("date", "") != "" and float(dd.get("best", 0.0)) > 0.0:
			dd["history"][dd["date"]] = dd["best"]
		dd["date"] = today
		dd["best"] = 0.0
		dd["claimed"] = false
		dd["plays"] = 0
		SaveManager.mark_dirty()
	return dd


func best_today() -> float:
	return float(_state().get("best", 0.0))


func claimed_today() -> bool:
	return bool(_state().get("claimed", false))


func plays_today() -> int:
	return int(_state().get("plays", 0))


func can_claim() -> bool:
	return not claimed_today() and best_today() >= TARGET


func record(score: float) -> Dictionary:
	var st := _state()
	var new_best := score > float(st["best"])
	if new_best:
		st["best"] = score
	st["plays"] = int(st.get("plays", 0)) + 1
	SaveManager.mark_dirty(true)
	return {"best": float(st["best"]), "new_best": new_best}


func claim() -> bool:
	if not can_claim():
		return false
	_state()["claimed"] = true
	ProgressionManager.add_coins(REWARD, "daily")
	ProgressionManager.unlock_achievement("daily_1")
	SaveManager.mark_dirty(true)
	return true


func history_best() -> Dictionary:
	return _state().get("history", {})
