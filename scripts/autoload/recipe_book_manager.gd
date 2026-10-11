extends Node
## RecipeBookManager — keşfedilen her tarifi saklar, dinamik tariflerin kayıt defterini yönetir,
## keşif ödüllerini ve gizli karakter kilitlerini tetikler.

signal discovered(item: Dictionary)

const HINT_PRICE := 30


func _ready() -> void:
	SaveManager.loaded.connect(_sync_registry)
	_sync_registry()


func _sync_registry() -> void:
	FusionEngine.load_registry(SaveManager.data.get("generic_reg", {}))
	FusionEngine.clear_cache()


func book() -> Dictionary:
	return SaveManager.data["recipes"]


func is_known(id: String) -> bool:
	return book().has(id)


## Yeni tarif keşfedildiyse true döner ve ödül verir.
func discover(it: Dictionary, source := "kitchen") -> bool:
	var id: String = it["id"]
	if it.get("kind", "") == "ingredient":
		return false
	if FusionEngine.is_generic(id):
		var e := FusionEngine.registry_entry(id)
		if not e.is_empty():
			SaveManager.data["generic_reg"][id] = {"inputs": e["inputs"], "method": e["method"]}
	var b := book()
	if b.has(id):
		var r: Dictionary = b[id]
		r["n"] = int(r.get("n", 1)) + 1
		SaveManager.mark_dirty()
		return false
	b[id] = {"n": 1, "t": int(Time.get_unix_time_from_system()), "best": 0.0, "src": source}
	var hand: bool = it.get("handcrafted", false)
	var reward := 8
	if hand:
		reward = 40 if it.get("kind", "") == "dish" else 25
	ProgressionManager.add_coins(reward, "discovery")
	var unlocks: String = it.get("unlocks", "")
	if unlocks != "":
		ProgressionManager.unlock_secret(unlocks)
	var total := b.size()
	if total >= 10:
		ProgressionManager.unlock_achievement("recipes_10")
	if total >= 25:
		ProgressionManager.unlock_achievement("recipes_25")
	if count_handcrafted() >= 10:
		ProgressionManager.unlock_achievement("special_10")
	SaveManager.mark_dirty(true)
	discovered.emit(it)
	return true


func record_score(id: String, score: float) -> void:
	var b := book()
	if b.has(id):
		b[id]["best"] = maxf(float(b[id].get("best", 0.0)), score)
		SaveManager.mark_dirty()


func best_score(id: String) -> float:
	return float(book().get(id, {}).get("best", 0.0))


func count_handcrafted() -> int:
	var c := 0
	for id in book().keys():
		if IngredientDatabase.recipes.has(id):
			c += 1
	return c


func count_all() -> int:
	return book().size()


## Kilerde malzeme olarak kullanılabilecek keşfedilmiş füzyonlar (el yapımı önce).
func known_fusions() -> Array:
	var hand: Array = []
	var gen: Array = []
	for id in IngredientDatabase.recipe_order:
		var r: Dictionary = IngredientDatabase.recipes[id]
		if r.get("kind", "") == "fusion" and is_known(id):
			hand.append(id)
	var gens: Array = []
	for id in book().keys():
		if str(id).begins_with("gf_") and FusionEngine.exists(id):
			gens.append({"id": id, "t": int(book()[id].get("t", 0))})
	gens.sort_custom(func(a, b): return a["t"] > b["t"])
	for g in gens:
		gen.append(g["id"])
		if gen.size() >= 24:
			break
	return hand + gen


func known_generic_dishes() -> Array:
	var res: Array = []
	for id in book().keys():
		if str(id).begins_with("gd_") and FusionEngine.exists(id):
			res.append({"id": id, "t": int(book()[id].get("t", 0))})
	res.sort_custom(func(a, b): return a["t"] > b["t"])
	var out: Array = []
	for r in res:
		out.append(r["id"])
	return out


func hint_visible(recipe_id: String) -> bool:
	if is_known(recipe_id):
		return true
	if SaveManager.data["hints_bought"].has(recipe_id):
		return true
	var r: Dictionary = IngredientDatabase.recipes.get(recipe_id, {})
	if r.get("secret", false):
		return ProgressionManager.league_done(1)
	for inp in r.get("inputs", []):
		if is_known(str(inp)):
			return true
	return false


func buy_hint(recipe_id: String) -> bool:
	if hint_visible(recipe_id):
		return true
	if not ProgressionManager.spend(HINT_PRICE):
		return false
	SaveManager.data["hints_bought"].append(recipe_id)
	SaveManager.mark_dirty(true)
	return true


## Tarifin tüm temel malzemeleri oyuncuda var mı?
func can_make(recipe_id: String) -> bool:
	var r: Dictionary = IngredientDatabase.recipes.get(recipe_id, {})
	for inp in r.get("inputs", []):
		var s := str(inp)
		if IngredientDatabase.ingredients.has(s):
			if ProgressionManager.ingredient_state(s) != "owned":
				return false
		elif IngredientDatabase.recipes.has(s):
			if not can_make(s):
				return false
	return true
