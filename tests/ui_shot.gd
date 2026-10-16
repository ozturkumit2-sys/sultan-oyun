extends Node
## Drives the real UI and saves screenshots of every screen/panel.
var main: Node
var step := 0
var wait := 0
var shots := []
var out_dir := "/tmp/claude-0/ui"

func _ready():
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2 and kv[0] == "lang":
			Game.change_language(kv[1])
			out_dir = "/tmp/claude-0/ui_" + kv[1]
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
			var acts: Array = Game.world.iv.actions_for("ws_selin")
			for a in acts:
				if a["enabled"] and str(a.get("needs", "")) == "person":
					gs().menu.tab = str(a.get("tab", "pc"))
					gs().menu._build_actions()
					gs().menu._choose(a)
					break
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
		20:
			_shot("10_settings")
			gs().settings_sheet._pick_language()
		21:
			_shot("10b_language")
			gs().settings_sheet.close()
			# line up a secret combination on Mert's desk: love note to the wrong person + fake 1:1 invite
			var w := Game.world
			for a in w.iv.actions_for("ws_mert"):
				if a.get("iv", "") == "I09" and a["enabled"]:
					a["spot"] = "ws_mert"
					w.iv.apply(a, "zeynep")
			for a in w.iv.actions_for("ws_mert"):
				if a.get("iv", "") == "B07" and a["enabled"]:
					a["spot"] = "ws_mert"
					w.iv.apply(a, "zeynep")
			gs()._on_hotspot("ws_mert")
		22: _shot("11_secret_combo")
		23:
			gs().menu.close()
			gs()._on_hotspot("fridge")
		24: _shot("12_meddle_fridge")
		25:
			gs().menu.close()
			var w := Game.world
			w.office.objects["lights"]["party"] = true
			w.office.objects["music"]["genre"] = "disco"
			gs().hud.open_journal.emit()
		26: _shot("13_journal")
		27:
			gs().journal.cat = "J"
			gs().journal._build()
		28: _shot("14_journal_secrets")
		29:
			gs().journal.page = "stories"
			gs().journal._build()
		30: _shot("15_journal_stories")
		31:
			gs().journal.page = "records"
			gs().journal._build()
		32: _shot("16_journal_records")
		33:
			gs().journal.close()
		34: _shot("17_party_lights")
		35:
			var w := Game.world
			while not w.day_over: w.step(0.5)
		36: _shot("18_paper")
		37: get_tree().quit()
