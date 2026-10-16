extends Node
## Bot player: drives the real GameScreen UI for several days with random meddling,
## opens every panel, advances days through the newspaper, saves & reloads.
var main: Node
var rng := RandomNumberGenerator.new()
var frame := 0
var days_done := 0
var target_days := 3
var actions := 0
var reloads := 0

func _ready():
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2 and kv[0] == "days": target_days = int(kv[1])
		if kv.size() == 2 and kv[0] == "lang": Game.change_language(kv[1])
	rng.seed = 99
	Game.delete_save()
	main = load("res://scripts/main.gd").new()
	add_child(main)
	await get_tree().process_frame
	main._start(true)

func gs() -> GameScreen:
	return main.current as GameScreen

func _process(_d):
	frame += 1
	var g := gs()
	if g == null or g.w == null:
		return
	# fast-forward the simulation
	if not g.w.day_over:
		g.w.step(1.5)
	if g.paper.visible:
		if frame % 20 == 0:
			days_done += 1
			print("day ", g.w.day, " done: ", JSON.stringify(g.w.stats.counts), " actions=", actions)
			if days_done >= target_days:
				print("BOT DONE days=%d actions=%d reloads=%d" % [days_done, actions, reloads])
				get_tree().quit()
				return
			g.paper._go()
		return
	if frame % 7 == 0:
		_random_ui(g)
	if frame % 400 == 0:
		# save, go to menu, continue
		g._to_menu()
		await get_tree().process_frame
		await get_tree().process_frame
		main._start(false)
		reloads += 1

func _random_ui(g: GameScreen):
	var r := rng.randi() % 11
	if g.menu.is_open:
		# pick an enabled action in the menu (the menu's own list, all tabs)
		var acts: Array = g.w.iv.actions_for(g.menu.spot).filter(func(a): return a["enabled"])
		if acts.is_empty():
			g.menu.close(); return
		var a: Dictionary = acts[rng.randi() % acts.size()]
		if str(a.get("needs", "")) == "":
			g.menu._choose(a)
		else:
			var opts: Array = g.w.iv.options_for(a).filter(func(o): return o["enabled"])
			if opts.is_empty():
				g.menu.close(); return
			g.menu._choose(a)
			var v = opts[rng.randi() % opts.size()]["value"]
			if not a.has("legacy") and InterventionManager.two_step(a.get("def", {})):
				var second: Array = g.w.iv.options_for(a, v)
				v = second[rng.randi() % second.size()]["value"]
			g.menu._apply(a, v)
		actions += 1
		return
	for s in [g.file, g.staff, g.gossip, g.today, g.settings_sheet, g.info, g.journal]:
		if s.is_open:
			s.close(); return
	match r:
		0, 1, 2, 3:
			var spots: Array = []
			for h in OfficeLayout.hotspots(): spots.append(h["id"])
			for it in g.w.office.items: spots.append("item_" + it)
			g._on_hotspot(spots[rng.randi() % spots.size()])
			if spots.size() > 0 and g.menu.is_open and g.menu.spot.begins_with("ws_"):
				g.menu.tab = ["pc", "mail", "phone", "papers"][rng.randi() % 4]
				g.menu._build_actions()
		4: g._open_file(C.NPC_IDS[rng.randi() % 8])
		5: g.hud.open_staff.emit()
		6: g.hud.open_log.emit()
		7: g.hud.open_today.emit()
		8: g.hud.speed_changed.emit([0.0, 1.0, 2.0][rng.randi() % 3])
		9: g._toggle_fit()
		10:
			g.hud.open_journal.emit()
			g.journal.page = ["meddles", "stories", "moments", "records"][rng.randi() % 4]
			g.journal.cat = "ABCDEFGHIJ"[rng.randi() % 10] if rng.randf() < 0.5 else ""
			g.journal._build()
