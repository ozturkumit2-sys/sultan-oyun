extends Node
## Geliştirme: gerçek sahneleri sırayla açar, düğmelere basar ve ekran görüntüleri alır.

var out := "/tmp/claude-0/shots/"
var mode := "menus"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	if args.size() > 1:
		var lg: String = args[1]
		out = "/tmp/claude-0/shots_%s/" % lg
		Loc._load(lg)
		IngredientDatabase.apply_language()
		FusionEngine.clear_cache()
		GameManager.apply_fonts()
	DirAccess.make_dir_recursive_absolute(out)
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	await get_tree().create_timer(0.3).timeout
	SaveManager.data = SaveManager.default_data()
	SaveManager.data["profile"]["created"] = true
	SaveManager.data["coins"] = 1500
	SaveManager.data["settings"]["music"] = 0.0
	SaveManager.data["settings"]["sfx"] = 0.0
	RecipeBookManager._sync_registry()
	match mode:
		"menus":
			await _menus()
		"battle":
			await _battle()
		"lab":
			await _lab()
		"judging":
			await _judging()
		"daily":
			await _daily()
		"minis":
			await _minis()
		"first":
			await _first()
		"soak":
			await _soak()
	print("FLOW DONE")
	get_tree().quit()


func shot(name: String, wait := 0.6) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out + name + ".png")
	print("shot ", name)


func go(key: String, p := {}) -> void:
	GameManager.goto(key, p, false)
	await get_tree().create_timer(1.0).timeout


func find_button(text: String) -> Button:
	return _find(get_tree().root, text)


func _find(n: Node, text: String) -> Button:
	if n is Button and n.visible and (text in n.text or Loc.t(text) in n.text):
		return n
	for c in n.get_children():
		var r := _find(c, text)
		if r:
			return r
	return null


func press(text: String) -> bool:
	var b := find_button(text)
	if b:
		b.pressed.emit()
		return true
	print("button not found: ", text)
	return false


func find_type(n: Node, cls: String) -> Node:
	if n.get_script() and n.get_script().get_global_name() == cls:
		return n
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := find_type(c, cls)
		if r:
			return r
	return null


func _menus() -> void:
	await go("boot")
	await shot("01_boot", 0.6)
	await get_tree().create_timer(2.0).timeout
	await go("menu")
	await shot("02_menu", 0.8)
	await go("chef", {"first": true})
	await shot("03_chef", 0.6)
	press("Kıyafet")
	await shot("03b_chef_outfit", 0.4)
	press("Uzmanlık")
	await shot("03c_chef_spec", 0.4)
	await go("career")
	await shot("04_career", 1.0)
	await go("shop")
	await shot("05_shop", 0.6)
	press("Tabak")
	await shot("05b_shop_plates", 0.5)
	await go("book")
	await shot("06_book", 0.8)
	press("Mutasyonlar")
	await shot("06b_book_mut", 0.5)
	await go("daily")
	await shot("07_daily", 0.8)
	await go("settings")
	await shot("08_settings", 0.5)
	await go("lab")
	await shot("09_lab", 0.8)


func _battle() -> void:
	BattleManager.start_career("l1_m1")
	await go("kitchen")
	await shot("10_vs", 1.2)
	press("BAŞLA!")
	await get_tree().create_timer(1.0).timeout
	await shot("11_round_banner", 0.3)
	var kb := get_tree().current_scene
	kb.gui_input.emit(InputEventMouseButton.new())
	# banner'ı kapatmak için dokunma simülasyonu
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	for c in kb.get_children():
		if c is Control and c.z_index == 60:
			c.gui_input.emit(ev)
	await get_tree().create_timer(1.2).timeout
	# sabotaj diyaloğu varsa savunma yerine uyum seç
	await _handle_sabotage()
	BattleManager.cur["sabotages"] = ["hex", "gravity_shift"]
	await shot("12_kitchen", 0.5)
	var st: KitchenStation = kb.station
	st.add_to_bowl("frog_essence")
	st.add_to_bowl("sugar")
	await shot("13_bowl", 0.4)
	st.do_fuse()
	await shot("14_fused", 0.6)
	st.clear_bowl()
	st.add_to_bowl("frog_essence")
	st.add_to_bowl("egg")
	st.select_method("bake")
	await shot("15_method", 0.3)
	st.request_cook()
	await get_tree().create_timer(0.8).timeout
	await _handle_sabotage()
	await get_tree().create_timer(0.6).timeout
	await shot("16_minigame", 0.8)
	var mg := find_type(get_tree().root, "CookingMinigame")
	if mg:
		for i in 3:
			mg._tap_timing()
			await get_tree().create_timer(0.3).timeout
	await get_tree().create_timer(1.5).timeout
	await shot("17_dish_reveal", 0.2)
	await get_tree().create_timer(1.2).timeout
	var lf := find_type(get_tree().root, "LivingFoodController")
	if lf:
		await shot("17b_living", 0.6)
		lf._resolve(true)
		await get_tree().create_timer(1.8).timeout
	for i in 20:
		await _handle_sabotage()
		if kb.phase == "plating":
			break
		await get_tree().create_timer(0.5).timeout
	await shot("18_plating", 0.8)
	press("SUN!")
	await get_tree().create_timer(1.5).timeout
	await _handle_sabotage()
	await get_tree().create_timer(2.0).timeout
	await shot("19_judging_present", 0.5)
	await get_tree().create_timer(4.0).timeout
	await shot("20_judging_scores", 0.2)
	# jüri akışını bitir
	for i in 40:
		await get_tree().create_timer(0.5).timeout
		var b := find_button("Tartışmayı Bitir")
		if b:
			await shot("21_argument", 0.2)
			b.pressed.emit()
		if find_button("SONRAKİ TUR") or find_button("SONUÇLAR"):
			break
	await shot("22_round_summary", 0.4)
	# kalan iki turu mantık üzerinden hızla oynat ve sonuç ekranına geç
	press("SONRAKİ TUR")
	await get_tree().create_timer(1.5).timeout
	BattleManager.cur["player"] = {}
	while not BattleManager.is_over():
		if BattleManager.cur.get("player", {}).is_empty():
			var d := FusionEngine.cook(["strawberry", "milk"], "freeze")
			BattleManager.set_player_dish(d, 0.85, RecipeBookManager.discover(d))
			BattleManager.set_plating("porcelain", "mint")
		BattleManager.judge_round()
		BattleManager.finish_round()
		if not BattleManager.is_over():
			BattleManager.begin_round()
			BattleManager.cur["player"] = {}
	BattleManager.finalize()
	await go("results")
	await shot("23_results", 2.5)


func _handle_sabotage() -> void:
	for i in 3:
		var sd := find_type(get_tree().root, "SabotageDialog")
		if sd == null:
			return
		await shot("sab_%s" % sd.ability, 0.4)
		if sd.ability == "hex":
			sd._choose("defend")
			await get_tree().create_timer(1.2).timeout
			await shot("sab_defend", 0.1)
			await get_tree().create_timer(4.0).timeout
			continue
		sd._choose("adapt" if sd.ability != "rotten_surprise" else "accept")
		await get_tree().create_timer(1.6).timeout


func _lab() -> void:
	await go("lab")
	var lab := get_tree().current_scene
	var st: KitchenStation = lab.station
	lab.quick = true
	st.add_to_bowl("frog_essence")
	st.add_to_bowl("egg")
	st.select_method("bake")
	st.request_cook()
	await shot("30_lab_dish", 1.2)
	st.add_to_bowl("dragon_fire")
	st.add_to_bowl("milk")
	st.select_method("freeze")
	st.request_cook()
	await shot("31_lab_dish2", 1.2)


func _pick_dish() -> Dictionary:
	var ids: Array = IngredientDatabase.ingredient_order
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 4000:
		var a: String = ids[rng.randi() % ids.size()]
		var b: String = ids[rng.randi() % ids.size()]
		if a == b:
			continue
		var m: String = IngredientDatabase.METHOD_ORDER[rng.randi() % 6]
		var d := FusionEngine.cook([a, b], m)
		var ev := JudgeSystem.evaluate(d, {"theme": BattleManager.cur["theme"], "quality": 0.8, "plate": "classic", "garnish": "none"})
		var jr := JudgeSystem.judge_all(d, ev, BattleManager.mutations, {"is_player": true})
		var mu := MutationSystem.check(d, {"bruno": jr["judges"]["bruno"]["score"], "mira": jr["judges"]["mira"]["score"], "max": jr["judges"]["max"]["score"]}, {}, {"rules": [], "round": BattleManager.round_no})
		if JudgeSystem.disagreement(jr["judges"]) >= 4.0 and not mu.is_empty():
			print("picked ", d["name"], " ", mu)
			return d
	return FusionEngine.cook(["frog_essence", "eye_pickle"], "magic")


func _judging() -> void:
	BattleManager.start_career("l1_m2")
	BattleManager.begin_round()
	var d := _pick_dish()
	BattleManager.set_player_dish(d, 0.8, true)
	BattleManager.set_plating("classic", "none")
	await go("judging")
	for i in 60:
		await get_tree().create_timer(0.5).timeout
		if find_type(get_tree().root, "PanelContainer") and i == 10:
			await shot("40_judge_a", 0.0)
		var b := find_button("Tartışmayı Bitir")
		if b:
			await shot("41_argument", 0.2)
			press("Yemeği Savun")
			await shot("42_argument_result", 1.0)
		for c in get_tree().root.get_children():
			pass
		if find_button("SONRAKİ TUR"):
			await shot("43_summary", 0.3)
			break
		if i % 4 == 0:
			await shot("44_judge_%02d" % i, 0.0)


func _daily() -> void:
	var ch := DailyChallengeManager.challenge()
	BattleManager.start_daily(ch)
	await go("kitchen")
	await shot("50_daily_intro", 1.2)
	press("BAŞLA!")
	await get_tree().create_timer(1.5).timeout
	var kb := get_tree().current_scene
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	for c in kb.get_children():
		if c is Control and c.z_index == 60:
			c.gui_input.emit(ev)
	await shot("51_daily_kitchen", 1.0)
	var d := FusionEngine.cook([ch["ingredients"][0], ch["ingredients"][1]], "bake")
	BattleManager.set_player_dish(d, 0.9, RecipeBookManager.discover(d))
	BattleManager.set_plating("classic", "none")
	BattleManager.judge_round()
	BattleManager.finish_round()
	BattleManager.finalize()
	await go("results")
	await shot("52_daily_results", 2.0)


func _minis() -> void:
	await go("menu")
	var root := get_tree().current_scene
	for m in ["boil", "magic", "fry"]:
		var mg := CookingMinigame.new()
		root.add_child(mg)
		mg.start(m, {"dark": 1.0} if m == "fry" else ({"speed": 1.6, "zone": 0.6, "jitter": true} if m == "magic" else {}))
		await get_tree().create_timer(1.6).timeout
		if m == "boil":
			mg._holding = true
		await shot("60_mini_%s" % m, 0.6)
		mg.queue_free()
	for beh in ["hide", "float", "steal", "change", "run"]:
		var lf := LivingFoodController.new()
		root.add_child(lf)
		lf.start(FusionEngine.item("running_pizza" if beh == "run" else ("spaghetti_monster" if beh == "hide" else ("ghost_cake" if beh == "float" else ("robot_cupcake" if beh == "steal" else "galaxy_pudding")))), beh)
		await shot("61_living_%s" % beh, 1.4 if beh != "hide" else 2.6)
		lf.queue_free()


func _first() -> void:
	SaveManager.data["profile"]["created"] = false
	await go("boot")
	await shot("70_boot", 1.6)
	await get_tree().create_timer(2.5).timeout
	await shot("71_after_boot", 0.5)


var rng := RandomNumberGenerator.new()


func _soak() -> void:
	rng.seed = 42
	Engine.time_scale = 4.0
	var list := ["l3_m2", "l1_m3", "l5_m3", "l2_m1"]
	for mid in list:
		# kilitleri aç (test için)
		while GameManager.busy:
			await get_tree().create_timer(0.1).timeout
		BattleManager.start_career(mid)
		await go("kitchen")
		var t0 := Time.get_ticks_msec()
		var guard := 0
		while guard < 3000:
			guard += 1
			await get_tree().create_timer(0.1).timeout
			var cs := get_tree().current_scene
			if cs == null:
				continue
			if GameManager.busy:
				continue
			var key := GameManager.current_key
			if key == "results":
				print("match ", mid, " done in ", (Time.get_ticks_msec() - t0) / 1000.0, "s won=", BattleManager.results.get("won"), " ", BattleManager.results.get("player_total"), "-", BattleManager.results.get("opp_total"))
				break
			if GameManager.busy:
				continue
			if key == "kitchen":
				await _bot_kitchen(cs)
			elif key == "judging":
				_bot_judging()
		if guard >= 3000:
			print("SOAK TIMEOUT in ", mid, " scene=", GameManager.current_key)
	Engine.time_scale = 1.0


func _bot_kitchen(kb: Node) -> void:
	if find_button("BAŞLA!"):
		press("BAŞLA!")
		return
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	for c in kb.get_children():
		if c is Control and c.z_index == 60:
			c.gui_input.emit(ev)
	var sd := find_type(get_tree().root, "SabotageDialog")
	if sd and not sd._busy:
		var ch: String = ["defend", "adapt", "accept"][rng.randi() % 3]
		sd._choose(ch)
		return
	if sd and sd._busy:
		var card := find_type(sd, "TapCard")
		if card:
			card.tapped.emit()
		return
	var dm := find_type(get_tree().root, "DefendMinigame")
	if dm and not dm._done:
		var area: Rect2 = dm._area()
		for r in dm._runes:
			var age: float = dm._t - float(r["t0"])
			if r["hit"] < 0.0 and age >= 0.1 and rng.randf() < 0.5:
				var e2 := InputEventMouseButton.new()
				e2.button_index = MOUSE_BUTTON_LEFT
				e2.pressed = true
				e2.position = area.position + r["p"] * area.size
				dm._gui_input(e2)
		return
	var jar := find_type(get_tree().root, "TapCard")
	var mg := find_type(get_tree().root, "CookingMinigame")
	if mg and not mg._done:
		match mg.kind:
			"timing":
				if rng.randf() < 0.3:
					mg._tap_timing()
			"hold":
				mg._holding = mg._level < mg._band_c
			"runes":
				for r in mg._runes:
					var age2: float = mg._t - float(r["t0"])
					if r["hit"] < 0.0 and age2 > 0.2 and rng.randf() < 0.6:
						var e3 := InputEventMouseButton.new()
						e3.button_index = MOUSE_BUTTON_LEFT
						e3.pressed = true
						e3.position = mg._area.position + r["p"] * mg._area.size
						mg._gui_input(e3)
		return
	var lf := find_type(get_tree().root, "LivingFoodController")
	if lf:
		if lf.state == LivingFoodController.State.ESCAPE and lf._t > 1.0:
			lf._resolve(rng.randf() < 0.6)
		return
	var modal := find_type(get_tree().root, "Modal")
	if modal:
		if find_button("Pişir"):
			press("Pişir")
		elif find_button("Devam Et"):
			press("Devam Et")
		return
	var st: KitchenStation = kb.station
	if kb.phase == "select" and not st.locked:
		st.clear_bowl()
		var p := BattleManager.player_pantry()
		var pool: Array = p["ingredients"] + p["fusions"]
		var mys: String = BattleManager.cur.get("mystery", "")
		if mys != "":
			st.add_to_bowl(mys)
		while st.slots.size() < mini(st.max_slots, 2 + rng.randi() % 2):
			var x: String = pool[rng.randi() % pool.size()]
			if not st.slots.has(x):
				st.add_to_bowl(x)
		if rng.randf() < 0.4 and st.can_fuse():
			st.do_fuse()
			if rng.randf() < 0.5:
				var y: String = pool[rng.randi() % pool.size()]
				st.add_to_bowl(y)
		var meths: Array = []
		for m in KitchenStation.METHODS:
			if not st.banned.has(m):
				meths.append(m)
		st.select_method(meths[rng.randi() % meths.size()])
		st.request_cook()
	elif kb.phase == "plating" and not st.locked:
		var pl: Array = IngredientDatabase.plate_order
		st._pick_plate(pl[rng.randi() % 3], true)
		press("SUN!")


func _bot_judging() -> void:
	for t in ["Yemeği Savun", "Tekrar Tattır", "Tarifi Açıkla", "Tartışmayı Bitir"]:
		if find_button(t):
			press(["Yemeği Savun", "Tekrar Tattır", "Tarifi Açıkla", "Tartışmayı Bitir"][rng.randi() % 4])
			return
	if find_button("SONRAKİ TUR"):
		press("SONRAKİ TUR")
	elif find_button("SONUÇLAR"):
		press("SONUÇLAR")
