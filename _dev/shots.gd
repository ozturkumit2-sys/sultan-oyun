extends Node
## Geliştirme: farklı bakış açılarından ekran görüntüsü alır.
var game: Node3D
var out := "/tmp/claude-0/shots/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	GameState.new_game("Kayhan", 1)
	var ps: PackedScene = load("res://scenes/game.tscn")
	game = ps.instantiate()
	add_child(game)
	var t0 := Time.get_ticks_msec()
	while not game._ready_done:
		await get_tree().process_frame
		if Time.get_ticks_msec() - t0 > 120000:
			print("timeout"); get_tree().quit(); return
	print("game ready in ms=", Time.get_ticks_msec() - t0)
	GameState.set_speed(0)
	var shots := [
		["01_avlu", Vector3(0, 0, 9), PI, -0.25, 5.0, 10.0 * 60],
		["02_taht", Vector3(0, 0, -36), PI * 0.0 + 0.0, -0.2, 4.0, 10.0 * 60],
		["03_divan", Vector3(-36, 0, -18), PI * 0.5, -0.22, 4.0, 9.0 * 60],
		["04_harem", Vector3(34, 0, -15), PI * 0.4, -0.2, 4.0, 11.0 * 60],
		["05_bahce", Vector3(0, 0, 50), PI, -0.12, 5.0, 18.5 * 60],
		["06_kutuphane", Vector3(-41, 0, -36), -PI * 0.25 + PI, -0.25, 4.0, 10.0 * 60],
		["07_avlu_gece", Vector3(6, 0, 4), PI * 1.2, -0.15, 5.0, 22.0 * 60],
		["08_revak", Vector3(-27, 0, 8), 0.0, -0.1, 3.5, 15.0 * 60],
		["09_mutfak", Vector3(17, 0, 22), PI, -0.25, 4.0, 13.0 * 60],
	]
	var quick := OS.get_cmdline_user_args().has("quick")
	var ui_only := OS.get_cmdline_user_args().has("ui")
	if quick:
		shots = [shots[0], shots[2], shots[4]]
	if ui_only:
		shots = []
	for s in shots:
		GameState.w["time"] = int(s[5])
		GameState.update_all_schedules()
		game.npcs.refresh(true)
		game.player.global_position = s[1]
		game.player.cam_yaw = s[2]
		game.player.cam_pitch = s[3]
		game.player.cam_dist = s[4]
		game.player.spring.spring_length = s[4]
		game.day_night.update_now()
		for i in range(25):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out + s[0] + ".png")
		print("shot ", s[0], " fps=", Engine.get_frames_per_second())
	if quick:
		get_tree().quit()
		return
	# arayüz
	GameState.w["time"] = 9 * 60
	GameState.update_all_schedules()
	game.npcs.refresh(true)
	game.player.global_position = Vector3(0, 0, 6)
	game.player.cam_yaw = PI
	for i in range(10):
		await get_tree().process_frame
	var ln: Node3D = game.npcs.node_for("leyla")
	var fwd := Vector3(-sin(ln.model.rotation.y), 0, -cos(ln.model.rotation.y))
	game.player.global_position = ln.global_position + fwd * 1.6
	for i in range(5):
		await get_tree().physics_frame
	game.open_dialogue("leyla")
	for i in range(50):
		await get_tree().process_frame
	for i in range(10):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "10_diyalog.png")
	game.hud.top_panel().close_panel()
	game.open_map()
	for i in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "11_harita.png")
	game.hud.top_panel().close_panel()
	var dp := DivanPanel.new()
	game.hud.open_panel(dp)
	dp.open(game)
	for i in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "12_divan_panel.png")
	dp.close_panel()
	game.open_profile("feraye")
	for i in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "13_profil.png")
	game.hud.top_panel().close_panel()
	for i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "14_hud.png")
	print("done")
	get_tree().quit()
