extends Node
## Geliştirme: harem/hanedan özelliklerinin oyun içi ekran görüntüleri.
var game: Node3D
var out := "/tmp/claude-0/shots/"


func snap(name: String, frames: int = 20) -> void:
	for i in range(frames):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")
	print("shot ", name)


func place_cam(pos: Vector3, yaw: float, pitch: float, dist: float) -> void:
	game.player.global_position = pos
	game.player.cam_yaw = yaw
	game.player.cam_pitch = pitch
	game.player.cam_dist = dist
	game.player.spring.spring_length = dist


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	GameState.new_game("Kayhan", 0)
	var gs := GameState
	# üç cariye, iki çocuk (biri 8, biri 5 yaşında)
	for i in range(3):
		HaremEngine.refresh_candidates(gs, true)
		HaremEngine.accept_cariye(gs, 0)
	var mothers: Array = []
	for id in HaremEngine.women(gs):
		if gs.ch(id).get("harem", false):
			mothers.append(id)
	gs.rng.seed = 7
	HaremEngine.birth(gs, mothers[0])
	HaremEngine.birth(gs, mothers[1])
	var kids := HaremEngine.living_children(gs)
	gs.ch(kids[0])["age"] = 8
	gs.ch(kids[1])["age"] = 5
	for k in kids:
		HaremEngine._update_child_profile(gs, k)
	print("kids: ", kids.map(func(k): return "%s %s %d" % [k, gs.ch(k)["full"], gs.ch(k)["age"]]))
	for e in EventEngine.pending(gs).duplicate():
		if e["tid"] == "dogum":
			EventEngine.resolve(gs, e["uid"], 0)
	var ps: PackedScene = load("res://scenes/game.tscn")
	game = ps.instantiate()
	add_child(game)
	while not game._ready_done:
		await get_tree().process_frame
	GameState.set_speed(0)
	# harem bahçesi, ikindi
	GameState.w["time"] = gs.get_day() * 1440 + 15 * 60 + 30
	GameState.update_all_schedules()
	game.npcs.refresh(true)
	for k in kids:
		print(k, " @", gs.ch(k)["location"], " ", gs.ch(k)["activity"], " node=", game.npcs.node_for(k) != null)
	for m in mothers:
		print(m, " @", gs.ch(m)["location"], " ", gs.ch(m)["activity"])
	place_cam(Vector3(45, 0, 30), PI, -0.22, 7.0)
	game.day_night.update_now()
	await snap("h01_harem_bahce", 30)
	# çocuğa yakın çekim
	var kn: Node3D = game.npcs.node_for(kids[0])
	if kn and kn.visible:
		place_cam(kn.global_position + Vector3(0, 0, 2.2), 0.0, -0.1, 2.6)
		await snap("h02_cocuk", 15)
	# Cafer Ağa ile harem işleri
	GameState.w["time"] = gs.get_day() * 1440 + 14 * 60
	GameState.update_all_schedules()
	game.npcs.refresh(true)
	await get_tree().process_frame
	var cn: Node3D = game.npcs.node_for("cafer")
	print("cafer @", gs.ch("cafer")["location"], " visible=", cn.visible)
	var fwd := Vector3(-sin(cn.model.rotation.y), 0, -cos(cn.model.rotation.y))
	game.player.global_position = cn.global_position + fwd * 1.6
	for i in range(5):
		await get_tree().physics_frame
	game.open_dialogue("cafer")
	await snap("h03_cafer", 50)
	var dp = game.hud.top_panel()
	dp._pick("harem", "aday")
	await snap("h04_adaylar", 10)
	dp._pick("hanedan", "")
	await snap("h05_hanedan", 10)
	dp.close_panel()
	await get_tree().process_frame
	# kadı ile yargı
	JusticeEngine.add_evidence(gs, "yusuf", "zimmet", 60.0, "Hazine defterlerinde açık")
	game.open_dialogue("nurettin")
	await snap("h06_dummy", 30)
	dp = game.hud.top_panel()
	dp._pick("yargi", "suc|yusuf|zimmet")
	await snap("h06_yargi", 10)
	dp._pick("yargi", "ceza|yusuf|zimmet|zindan")
	await snap("h07_fetva", 10)
	dp.close_panel()
	await get_tree().process_frame
	# aile ağacı
	game.open_state("hanedan")
	await snap("h08_aile", 12)
	game.hud.top_panel().close_panel()
	# gece
	GameState.w["time"] = gs.get_day() * 1440 + 21 * 60
	GameState.update_all_schedules()
	var inv := HaremEngine.invite(gs, mothers[2])
	print("davet: ", inv)
	if not inv["ok"]:
		gs.rel_add(mothers[2], "sultan", {"romantik": 40, "sevgi": 30})
		print("davet2: ", HaremEngine.invite(gs, mothers[2]))
	game._do_sleep(gs.get_day())
	await snap("h09_gece", 15)
	game.hud.top_panel().close_panel()
	await get_tree().process_frame
	if game.hud.top_panel():
		game.hud.top_panel().close_panel()
	# zaman atlama
	game.open_time_skip()
	await snap("h10_atla", 10)
	var tp = game.hud.top_panel()
	var t0 := Time.get_ticks_msec()
	tp._run(30)
	while is_instance_valid(tp) and tp._running:
		await get_tree().process_frame
	print("30 gün atlama ms=", Time.get_ticks_msec() - t0)
	await snap("h11_ozet", 10)
	get_tree().quit()
