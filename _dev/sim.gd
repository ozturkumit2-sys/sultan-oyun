extends Node
## Geliştirme: oyun mantığını görsel olmadan test eder (füzyon, puanlama, rakip YZ, kariyer dengesi).

var bot_rng := RandomNumberGenerator.new()
var fails := 0


func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)


func _ready() -> void:
	await get_tree().process_frame
	print("data errors: ", IngredientDatabase.load_errors)
	print("ingredients=%d recipes=%d themes=%d opponents=%d matches=%d" % [IngredientDatabase.ingredients.size(),
		IngredientDatabase.recipes.size(), IngredientDatabase.themes.size(), IngredientDatabase.opponents.size(), IngredientDatabase.matches.size()])
	SaveManager.data = SaveManager.default_data()
	# --- determinism & order independence
	var a := FusionEngine.fuse(["frog_essence", "sugar"])
	var b := FusionEngine.fuse(["sugar", "frog_essence"])
	check(a["id"] == b["id"] and a["id"] == "candy_frog", "candy frog order")
	var c := FusionEngine.fuse(["candy_frog", "chocolate"])
	check(c["id"] == "chocolate_frog", "chocolate frog")
	var v := FusionEngine.cook(["dragon_fire", "chocolate_frog"], "bake")
	check(v["id"] == "volcanic_frog_cake", "volcanic")
	print("volcanic: ", v["name"], " depth=", v["depth"], " stats=", v["stats"], " living=", v["living"])
	var g1 := FusionEngine.cook(["lemon", "chili"], "fry")
	var g2 := FusionEngine.cook(["chili", "lemon"], "fry")
	check(g1["id"] == g2["id"], "generic order")
	print("generic: ", g1["id"], " ", g1["name"], " ", g1["visual"])
	var g3 := FusionEngine.fuse(["lemon", "frog_essence"])
	print("generic fusion: ", g3["id"], " ", g3["name"], " adj=", g3["adj"])
	var g4 := FusionEngine.cook([g3["id"], "honey"], "magic")
	print("chain dish: ", g4["name"], " depth=", g4["depth"], " living=", g4["living"])
	# every handcrafted recipe resolves
	for rid in IngredientDatabase.recipe_order:
		var it := FusionEngine.item(rid)
		check(it["name"] != "???", "recipe resolves " + rid)
	# names for a bunch of generics
	var ids: Array = IngredientDatabase.ingredient_order
	bot_rng.seed = 7
	for i in 12:
		var x: String = ids[bot_rng.randi() % ids.size()]
		var y: String = ids[bot_rng.randi() % ids.size()]
		if x == y:
			continue
		var m: String = IngredientDatabase.METHOD_ORDER[bot_rng.randi() % 6]
		var d := FusionEngine.cook([x, y], m)
		var ev := JudgeSystem.evaluate(d, {"theme": IngredientDatabase.theme("sweet_dream"), "quality": 0.75})
		var jr := JudgeSystem.judge_all(d, ev, {}, {})
		print("  %-38s %-6s total=%.1f axes=%s living=%s" % [d["name"], m, jr["total"], _ax(ev["axes"]), d["living"]])
	# handcrafted dish scores
	print("--- handcrafted dishes (q=0.8, best plating, theme none)")
	for rid in IngredientDatabase.recipe_order:
		var r: Dictionary = IngredientDatabase.recipes[rid]
		if r["kind"] != "dish":
			continue
		var d := FusionEngine.item(rid)
		var ai := OpponentAI.new(IngredientDatabase.opponents["morgana"], 1, 1)
		var pl := ai.best_plating(d, {}, false)
		var ev := JudgeSystem.evaluate(d, {"theme": {}, "quality": 0.8, "plate": pl["plate"], "garnish": pl["garnish"], "first": true, "living": "caught" if d["living"] != "" else "none"})
		var jr := JudgeSystem.judge_all(d, ev, {}, {"first": true})
		var sc := []
		for j in jr["judges"].keys():
			sc.append("%s=%.1f" % [j, jr["judges"][j]["score"]])
		print("  %-28s total=%.1f %s axes=%s" % [d["name"], jr["total"], " ".join(sc), _ax(ev["axes"])])
	# --- career simulation
	print("--- career sim")
	var stats := {}
	for trial in 3:
		SaveManager.data = SaveManager.default_data()
		RecipeBookManager._sync_registry()
		bot_rng.seed = 100 + trial
		var plays := 0
		var skill: float = [0.72, 0.82, 0.9][trial]
		while ProgressionManager.next_match() != "" and plays < 70:
			var mid := ProgressionManager.next_match()
			plays += 1
			var res := _play_match(mid, skill)
			if not stats.has(mid):
				stats[mid] = {"w": 0, "n": 0, "p": 0.0, "o": 0.0}
			stats[mid]["n"] += 1
			stats[mid]["p"] += res["player_total"]
			stats[mid]["o"] += res["opp_total"]
			if res["won"]:
				stats[mid]["w"] += 1
			# bot buys things with coins: plates & ingredients
			for iid in IngredientDatabase.ingredient_order:
				if ProgressionManager.ingredient_state(iid) == "buyable":
					ProgressionManager.buy_ingredient(iid)
			for pid in IngredientDatabase.plate_order:
				ProgressionManager.buy("plates", pid)
			for gid in IngredientDatabase.garnish_order:
				ProgressionManager.buy("garnishes", gid)
			for sp in ["fusion", "artist", "chaos", "defender"]:
				ProgressionManager.upgrade_spec(sp)
		print("trial %d skill=%.2f plays=%d coins=%d level=%d stars=%d recipes=%d leagues=%s" % [trial, skill, plays, ProgressionManager.coins(), ProgressionManager.level(), ProgressionManager.total_stars(), RecipeBookManager.count_all(), SaveManager.data["career"]["leagues_done"]])
	for mid in IngredientDatabase.match_order:
		if stats.has(mid):
			var s: Dictionary = stats[mid]
			print("  %s winrate=%d/%d avgP=%.1f avgO=%.1f" % [mid, s["w"], s["n"], s["p"] / s["n"], s["o"] / s["n"]])
	# daily
	var ch := DailyChallengeManager.challenge("2026-10-11")
	var ch2 := DailyChallengeManager.challenge("2026-10-11")
	check(ch == ch2, "daily deterministic")
	print("daily: ", ch)
	# save roundtrip
	SaveManager.save_now()
	var before := JSON.stringify(SaveManager.data)
	SaveManager.load_game()
	print("save roundtrip coins=", SaveManager.data["coins"], " ok=", SaveManager.loaded_from)
	print("FAILS=", fails)
	get_tree().quit()


func _ax(ax: Dictionary) -> String:
	return "F%.1f C%.1f T%.1f P%.1f Y%.1f" % [ax["flavor"], ax["cooking"], ax["theme"], ax["presentation"], ax["creativity"]]


func _bot_choose(state: Dictionary) -> Dictionary:
	var p := BattleManager.player_pantry()
	var pool: Array = p["ingredients"] + p["fusions"]
	var mys: String = state["mystery"]
	var best := {}
	var best_v := -1.0
	var cands: Array = []
	for rid in IngredientDatabase.recipe_order:
		var r: Dictionary = IngredientDatabase.recipes[rid]
		if r["kind"] != "dish":
			continue
		if not RecipeBookManager.is_known(rid) and bot_rng.randf() < 0.6:
			continue
		var ok := true
		for inp in r["inputs"]:
			if not pool.has(inp) and not (IngredientDatabase.recipes.has(inp) and RecipeBookManager.can_make(inp)):
				ok = false
		if ok and not BattleManager.banned_methods().has(r["method"]):
			cands.append({"inputs": r["inputs"], "method": r["method"]})
	for i in 25:
		var n := 3 if ProgressionManager.has_third_slot() and bot_rng.randf() < 0.3 else 2
		var inputs: Array = []
		if mys != "":
			inputs.append(mys)
		while inputs.size() < n:
			var x: String = pool[bot_rng.randi() % pool.size()]
			if not inputs.has(x):
				inputs.append(x)
		var meths: Array = []
		for m in IngredientDatabase.METHOD_ORDER:
			if not BattleManager.banned_methods().has(m):
				meths.append(m)
		cands.append({"inputs": inputs, "method": meths[bot_rng.randi() % meths.size()]})
	for c in cands:
		var d := FusionEngine.cook(c["inputs"], c["method"])
		if mys != "" and not FusionEngine.contains_ingredient(d["id"], mys):
			continue
		if BattleManager.served.has(d["id"]):
			continue
		var ev := JudgeSystem.evaluate(d, {"theme": state["theme"], "quality": 0.8, "first": not RecipeBookManager.is_known(d["id"])})
		var jr := JudgeSystem.judge_all(d, ev, BattleManager.mutations, {})
		if jr["total"] > best_v:
			best_v = jr["total"]
			best = d
	return best


func _play_match(mid: String, skill: float) -> Dictionary:
	BattleManager.start_career(mid)
	while not BattleManager.is_over():
		var cur := BattleManager.begin_round()
		for ab in BattleManager.sabotages_for_phase("round_start"):
			BattleManager.resolve_sabotage(ab, ["defend", "adapt", "accept"][bot_rng.randi() % 3], bot_rng.randi_range(1, 3), bot_rng.randf() < 0.3)
		var dish := _bot_choose(cur)
		# make intermediate fusions known (as if player fused them)
		for inp in dish["inputs"]:
			if IngredientDatabase.recipes.has(inp) or FusionEngine.is_generic(inp):
				RecipeBookManager.discover(FusionEngine.item(inp))
		for ab in BattleManager.sabotages_for_phase("before_cook"):
			BattleManager.resolve_sabotage(ab, ["defend", "adapt", "accept"][bot_rng.randi() % 3], bot_rng.randi_range(1, 3), bot_rng.randf() < 0.3)
		var q := clampf(bot_rng.randfn(skill, 0.1), 0.2, 1.0)
		if BattleManager.cooking_mods().has("auto"):
			q = 0.7
		dish = BattleManager.apply_phase("before_cook", dish)
		var first := RecipeBookManager.discover(dish)
		BattleManager.set_player_dish(dish, q, first)
		if dish["living"] != "":
			BattleManager.set_living("caught" if bot_rng.randf() < 0.7 else "escaped")
		for ab in BattleManager.sabotages_for_phase("before_plating"):
			BattleManager.resolve_sabotage(ab, "adapt")
		dish = BattleManager.apply_phase("before_plating", dish)
		var ai := OpponentAI.new(IngredientDatabase.opponents["morgana"], 1, 3)
		var pl := ai.best_plating(dish, cur["theme"], false)
		BattleManager.set_plating(pl["plate"] if ProgressionManager.owns("plates", pl["plate"]) else "classic", pl["garnish"] if ProgressionManager.owns("garnishes", pl["garnish"]) else "none")
		for ab in BattleManager.sabotages_for_phase("before_judging"):
			BattleManager.resolve_sabotage(ab, "accept")
		dish = BattleManager.apply_phase("before_judging", dish)
		BattleManager.set_player_dish_only(dish)
		var j := BattleManager.judge_round()
		if j["player"]["argument"]:
			BattleManager.apply_argument(["defend", "retaste", "explain", "end"][bot_rng.randi() % 4])
		BattleManager.finish_round()
	return BattleManager.finalize()
