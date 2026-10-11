extends Node

func _ready() -> void:
	var lang := "tr"
	if OS.get_cmdline_user_args().size() > 0:
		lang = OS.get_cmdline_user_args()[0]
	Loc._load(lang)
	IngredientDatabase.apply_language()
	FusionEngine.clear_cache()
	for m in ["fry", "magic", ""]:
		var d := FusionEngine.cook(["flour", "frog_essence", "chili", "ghost_dust"], m) if m != "" else FusionEngine.fuse(["flour", "frog_essence", "chili"])
		print(m, " | ", d["name"], " | ", d["desc"])
	var ids: Array = IngredientDatabase.ingredient_order
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var methods := ["bake", "fry", "freeze", "boil", "grill", "magic"]
	var seen := {}
	for i in 14:
		var inp: Array = []
		var n := 2 + (i % 3)
		while inp.size() < n:
			var x: String = ids[rng.randi() % 36]
			if not inp.has(x):
				inp.append(x)
		var d := FusionEngine.cook(inp, methods[rng.randi() % 6])
		print(inp.size(), " | ", d["name"], " | ", d["desc"])
	# dağılım
	var cnt := 0
	for i in 2000:
		var inp2: Array = []
		while inp2.size() < 3:
			var x2: String = ids[rng.randi() % ids.size()]
			if not inp2.has(x2):
				inp2.append(x2)
		var d2 := FusionEngine.cook(inp2, methods[rng.randi() % 6])
		seen[d2["name"]] = true
		cnt += 1
	print("farklı isim: ", seen.size(), " / ", cnt)
	get_tree().quit()
