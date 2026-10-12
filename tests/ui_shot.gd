extends Node
## Drives the real UI and saves screenshots of every screen/panel.
var main: Node
var step := 0
var wait := 0
var shots := []
var out_dir := "/tmp/claude-0/ui"

func _ready():
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.delete_save()
	Game.set_setting("tips_seen", false)
	main = load("res://scripts/main.gd").new()
	add_child(main)

func _shot(name: String):
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("shot ", name)

func gs() -> GameScreen:
	return main.current as GameScreen

func _process(_d):
	wait += 1
	if wait < 30:
		return
	wait = 0
	step += 1
	match step:
		1: _shot("01_menu")
		2:
			main._start(true)
		3:
			var w := Game.world
			for i in 520: w.step(0.25)
			Interventions.apply(w, {"id": "break_printer", "needs": ""}, null)
		4: _shot("02_game")
		5: gs()._on_hotspot("coffee_machine")
		6: _shot("03_meddle_coffee")
		7:
			gs().menu.close()
			gs()._on_hotspot("ws_selin")
		8: _shot("04_meddle_desk")
		9:
			var acts := Interventions.actions_for(Game.world, "ws_selin")
			gs().menu._choose(acts[1])
		10: _shot("05_meddle_options")
		11:
			gs().menu.close()
			gs()._open_file("selin")
		12: _shot("06_file_selin")
		13:
			gs().file.close()
			gs().hud.open_staff.emit()
		14: _shot("07_staff")
		15:
			gs().staff.close()
			gs().hud.open_log.emit()
		16: _shot("08_gossip")
		17:
			gs().gossip.close()
			gs().hud.open_today.emit()
		18: _shot("09_today")
		19:
			gs().today.close()
			gs().hud.open_settings.emit()
		20: _shot("10_settings")
		21:
			gs().settings_sheet.close()
			var w := Game.world
			while not w.day_over: w.step(0.5)
		22: _shot("11_paper")
		23: get_tree().quit()
