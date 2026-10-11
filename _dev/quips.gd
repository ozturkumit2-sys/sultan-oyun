extends Node
## Jüri replik testi: bağlamlara göre çeşitlilik ve yer tutucu kontrolü.

func _ready() -> void:
	var ids: Array = IngredientDatabase.ingredient_order
	var methods := ["bake", "fry", "freeze", "boil", "grill", "magic"]
	var seen := {"bruno": {}, "mira": {}, "max": {}}
	var bad := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var muts: Array = IngredientDatabase.mutation_order
	for i in 3000:
		var a: String = ids[rng.randi() % ids.size()]
		var b: String = ids[rng.randi() % ids.size()]
		if a == b:
			continue
		var dish := FusionEngine.cook([a, b], methods[rng.randi() % methods.size()])
		var ctx := {"theme": {}, "quality": rng.randf(), "plate": "classic", "garnish": "none"}
		var ev := JudgeSystem.evaluate(dish, ctx)
		var m := {}
		if rng.randf() < 0.3:
			m[["bruno", "mira", "max"][rng.randi() % 3]] = muts[rng.randi() % muts.size()]
		var jr := JudgeSystem.judge_all(dish, ev, m, {"round": 1})
		var lv: String = ["none", "none", "caught", "escaped"][rng.randi() % 4]
		JudgeSystem.assign_quips(jr["judges"], dish, {"mutations": m, "living": lv, "first": rng.randf() < 0.3,
			"repeat": rng.randf() < 0.1, "mystery": a if rng.randf() < 0.2 else ""})
		for jid in jr["judges"].keys():
			var q: String = jr["judges"][jid]["quip"]
			if q.contains("{") or q == "" or q == "...":
				bad += 1
				print("BAD ", jid, " ", q)
			seen[jid][q] = true
			if i < 6:
				print(jid, " [", jr["judges"][jid]["tier"], "] ", q)
	for jid in seen.keys():
		var total := 0
		var pools: Dictionary = IngredientDatabase.judge_lines[jid]
		print(jid, " farklı replik: ", seen[jid].size())
	print("bad ", bad)
	var js: Node = load("res://scripts/ui/scenes/judging_stage.gd").new()
	for jid in ["bruno", "mira", "max"]:
		for key in ["argue_high", "argue_low", "argue_third"]:
			var got := {}
			for n in 8:
				got[js._line(jid, key)] = true
			print(jid, " ", key, " ", got.size(), " e.g. ", got.keys()[0])
	js.free()
	get_tree().quit()
