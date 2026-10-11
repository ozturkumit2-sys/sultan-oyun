extends Node
## ProgressionManager — Şef Parası, deneyim/seviye, uzmanlıklar, kilitler, kariyer yıldızları,
## başarımlar, gizli karakterler ve mutasyon koleksiyonu. Tüm veri SaveManager.data içinde saklanır.

signal coins_changed(value: int)
signal level_up(level: int)
signal achievement_unlocked(id: String)
signal secret_unlocked(id: String)
signal item_unlocked(kind: String, id: String)

const COSMETIC_SLOTS := ["hair", "expression", "hat", "jacket", "apron", "accessory"]

var _pending_toasts: Array = []


func d() -> Dictionary:
	return SaveManager.data


# ------------------------------------------------------------------ para
func coins() -> int:
	return int(d()["coins"])


func add_coins(n: int, _reason := "") -> void:
	if n == 0:
		return
	d()["coins"] = maxi(0, coins() + n)
	if n > 0:
		d()["stats"]["coins_earned"] = int(d()["stats"]["coins_earned"]) + n
	coins_changed.emit(coins())
	SaveManager.mark_dirty()


func spend(n: int) -> bool:
	if n < 0 or coins() < n:
		return false
	d()["coins"] = coins() - n
	coins_changed.emit(coins())
	SaveManager.mark_dirty(true)
	return true


# ------------------------------------------------------------------ seviye
func level() -> int:
	return int(d()["level"])


func xp() -> int:
	return int(d()["xp"])


func xp_needed(lvl: int) -> int:
	return 100 + 55 * (lvl - 1)


func add_xp(n: int) -> int:
	var gained := 0
	var x := xp() + n
	var l := level()
	while x >= xp_needed(l) and l < 30:
		x -= xp_needed(l)
		l += 1
		gained += 1
	d()["xp"] = x
	d()["level"] = l
	if gained > 0:
		d()["skill_points"] = int(d()["skill_points"]) + gained
		level_up.emit(l)
	SaveManager.mark_dirty()
	return gained


func skill_points() -> int:
	return int(d()["skill_points"])


func spec_tier(id: String) -> int:
	return int(d()["specs"].get(id, 0))


func specs() -> Dictionary:
	return d()["specs"].duplicate()


func can_upgrade(id: String) -> bool:
	return skill_points() > 0 and spec_tier(id) < 3


func upgrade_spec(id: String) -> bool:
	if not can_upgrade(id):
		return false
	d()["specs"][id] = spec_tier(id) + 1
	d()["skill_points"] = skill_points() - 1
	SaveManager.mark_dirty(true)
	return true


# ------------------------------------------------------------------ mutfak kapasitesi
func has_third_slot() -> bool:
	return league_done(1)


func max_fusions_per_round() -> int:
	return 2 + (1 if spec_tier("fusion") >= 2 else 0)


func max_chain_depth() -> int:
	return 2 + (1 if spec_tier("fusion") >= 2 else 0)


# ------------------------------------------------------------------ malzemeler
func ingredient_state(id: String) -> String:
	var ing: Dictionary = IngredientDatabase.ingredients.get(id, {})
	if ing.is_empty():
		return "locked"
	var u: Dictionary = ing.get("unlock", {})
	var t: String = u.get("type", "start")
	if t == "start" or d()["ingredients"].has(id):
		return "owned"
	if t == "league" and league_unlocked(int(u.get("league", 99))):
		return "buyable"
	return "locked"


func ingredient_price(id: String) -> int:
	return int(IngredientDatabase.ingredients.get(id, {}).get("unlock", {}).get("price", 0))


func owned_ingredients() -> Array:
	var res: Array = []
	for id in IngredientDatabase.ingredient_order:
		if ingredient_state(id) == "owned":
			res.append(id)
	return res


func unlock_ingredient(id: String) -> bool:
	if d()["ingredients"].has(id):
		return false
	d()["ingredients"].append(id)
	item_unlocked.emit("ingredient", id)
	SaveManager.mark_dirty()
	return true


func buy_ingredient(id: String) -> bool:
	if ingredient_state(id) != "buyable":
		return false
	if not spend(ingredient_price(id)):
		return false
	unlock_ingredient(id)
	return true


# ------------------------------------------------------------------ kozmetik & eşyalar
func _list_for(slot: String) -> Array:
	match slot:
		"plates":
			return IngredientDatabase.content.get("plates", [])
		"garnishes":
			return IngredientDatabase.content.get("garnishes", [])
		"decor":
			return IngredientDatabase.content.get("decor", [])
	return IngredientDatabase.cosmetic_list(slot)


func item_def(slot: String, id: String) -> Dictionary:
	for c in _list_for(slot):
		if c["id"] == id:
			return c
	return {}


func owns(slot: String, id: String) -> bool:
	var c := item_def(slot, id)
	if c.is_empty():
		return false
	if c.has("secret"):
		return d()["secrets"].has(c["secret"])
	if int(c.get("price", 0)) == 0:
		return true
	return d()["owned"].get(slot, []).has(id)


func price(slot: String, id: String) -> int:
	return int(item_def(slot, id).get("price", 0))


func buy(slot: String, id: String) -> bool:
	if owns(slot, id):
		return true
	var c := item_def(slot, id)
	if c.is_empty() or c.has("secret"):
		return false
	if not spend(int(c.get("price", 0))):
		return false
	if not d()["owned"].has(slot):
		d()["owned"][slot] = []
	d()["owned"][slot].append(id)
	SaveManager.mark_dirty(true)
	return true


func owned_list(slot: String) -> Array:
	var res: Array = []
	for c in _list_for(slot):
		if owns(slot, c["id"]):
			res.append(c["id"])
	return res


func chef() -> Dictionary:
	return d()["chef"]


func set_chef_value(key: String, value: Variant) -> void:
	d()["chef"][key] = value
	SaveManager.mark_dirty()


# ------------------------------------------------------------------ kariyer
func match_record(mid: String) -> Dictionary:
	var m: Dictionary = d()["career"]["matches"]
	if not m.has(mid):
		return {"stars": [false, false, false], "best": 0.0, "wins": 0, "plays": 0}
	var r: Dictionary = m[mid]
	var stars: Array = r.get("stars", [false, false, false])
	while stars.size() < 3:
		stars.append(false)
	return {"stars": stars, "best": float(r.get("best", 0.0)), "wins": int(r.get("wins", 0)), "plays": int(r.get("plays", 0))}


func match_stars(mid: String) -> int:
	var c := 0
	for s in match_record(mid)["stars"]:
		if s:
			c += 1
	return c


func total_stars() -> int:
	var t := 0
	for mid in IngredientDatabase.match_order:
		t += match_stars(mid)
	return t


func league_done(lid: int) -> bool:
	return d()["career"]["leagues_done"].has(lid)


func league_unlocked(lid: int) -> bool:
	return lid <= 1 or league_done(lid - 1)


func highest_league() -> int:
	var h := 1
	for l in IngredientDatabase.leagues:
		if league_unlocked(int(l["id"])):
			h = maxi(h, int(l["id"]))
	return h


func is_match_unlocked(mid: String) -> bool:
	var m: Dictionary = IngredientDatabase.matches.get(mid, {})
	if m.is_empty():
		return false
	var lid := int(m["league"])
	if not league_unlocked(lid):
		return false
	var idx := int(m["index"])
	if idx == 0:
		return true
	var lg: Dictionary = IngredientDatabase.league(lid)
	var prev: String = lg["matches"][idx - 1]["id"]
	return match_record(prev)["wins"] > 0


func next_match() -> String:
	for mid in IngredientDatabase.match_order:
		if is_match_unlocked(mid) and match_record(mid)["wins"] == 0:
			return mid
	return ""


## Maç sonucunu kaydeder; yeni kazanılan yıldız sayısını ve lig tamamlanmasını döndürür.
func record_match(mid: String, won: bool, total: float, stars: Array) -> Dictionary:
	var rec := match_record(mid)
	var new_stars := 0
	var merged: Array = []
	for i in 3:
		var had: bool = rec["stars"][i]
		var now: bool = stars[i] if i < stars.size() else false
		if now and not had:
			new_stars += 1
		merged.append(had or now)
	rec["stars"] = merged
	rec["best"] = maxf(float(rec["best"]), total)
	rec["plays"] = int(rec["plays"]) + 1
	if won:
		rec["wins"] = int(rec["wins"]) + 1
	d()["career"]["matches"][mid] = rec
	var league_completed := 0
	var m: Dictionary = IngredientDatabase.matches[mid]
	var lid := int(m["league"])
	if won and not league_done(lid):
		var all_won := true
		for mm in IngredientDatabase.league(lid)["matches"]:
			if match_record(mm["id"])["wins"] == 0:
				all_won = false
		if all_won:
			d()["career"]["leagues_done"].append(lid)
			league_completed = lid
	if won:
		d()["stats"]["wins"] = int(d()["stats"]["wins"]) + 1
	else:
		d()["stats"]["losses"] = int(d()["stats"]["losses"]) + 1
	d()["stats"]["matches"] = int(d()["stats"]["matches"]) + 1
	SaveManager.mark_dirty(true)
	check_star_secrets()
	return {"new_stars": new_stars, "league_completed": league_completed}


# ------------------------------------------------------------------ başarımlar & gizliler
func has_achievement(id: String) -> bool:
	return d()["achievements"].has(id)


func unlock_achievement(id: String) -> bool:
	if has_achievement(id) or not IngredientDatabase.achievements.has(id):
		return false
	d()["achievements"].append(id)
	add_coins(int(IngredientDatabase.achievements[id].get("coins", 0)), "achievement")
	achievement_unlocked.emit(id)
	SaveManager.mark_dirty()
	return true


func has_secret(id: String) -> bool:
	return d()["secrets"].has(id)


func unlock_secret(id: String) -> bool:
	if has_secret(id) or not IngredientDatabase.secrets.has(id):
		return false
	d()["secrets"].append(id)
	secret_unlocked.emit(id)
	unlock_achievement("secret_1")
	SaveManager.mark_dirty(true)
	return true


func see_mutation(id: String) -> bool:
	if d()["mutations_seen"].has(id):
		return false
	d()["mutations_seen"].append(id)
	unlock_achievement("mutation_1")
	if d()["mutations_seen"].size() >= IngredientDatabase.mutation_order.size():
		unlock_achievement("mutation_all")
	for sid in IngredientDatabase.secrets.keys():
		var s: Dictionary = IngredientDatabase.secrets[sid]
		if s.get("how", "") == "mutations" and d()["mutations_seen"].size() >= int(s.get("value", 99)):
			unlock_secret(sid)
	SaveManager.mark_dirty()
	return true


func check_star_secrets() -> void:
	var stars := total_stars()
	for sid in IngredientDatabase.secrets.keys():
		var s: Dictionary = IngredientDatabase.secrets[sid]
		if s.get("how", "") == "stars" and stars >= int(s.get("value", 999)):
			unlock_secret(sid)


func stat(key: String) -> int:
	return int(d()["stats"].get(key, 0))


func add_stat(key: String, n := 1) -> int:
	var v := stat(key) + n
	d()["stats"][key] = v
	SaveManager.mark_dirty()
	match key:
		"living_caught":
			if v >= 1:
				unlock_achievement("living_catch")
			if v >= 5:
				unlock_achievement("living_5")
		"backfires":
			unlock_achievement("backfire")
		"perfect_cooks":
			unlock_achievement("perfect_cook")
		"fusions":
			unlock_achievement("first_fusion")
	return v


func tutorial_done(key: String) -> bool:
	return bool(d()["tutorial"].get(key, false))


func set_tutorial_done(key: String) -> void:
	d()["tutorial"][key] = true
	SaveManager.mark_dirty()


func assistant() -> String:
	var a: String = d()["chef"].get("assistant", "")
	if a != "" and has_secret(a):
		return a
	return ""
