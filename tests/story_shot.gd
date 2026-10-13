extends Node
## Screenshots of the story layer in the real UI: gossip board storylines,
## personnel file (ties, beliefs, morale), newspaper, and an emote close-up.
var main: Node
var step := 0
var wait := 0
var out_dir := "/tmp/claude-0/ui"
var focus_id := ""

func _ready():
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.delete_save()
	Game.set_setting("tips_seen", true)
	main = load("res://scripts/main.gd").new()
	add_child(main)

func _shot(name: String):
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("shot ", name)

func gs() -> GameScreen:
	return main.current as GameScreen

func _busiest() -> String:
	var w := Game.world
	var best := "selin"
	var bs := -1
	for id in w.order:
		var n: NPC = w.npc(id)
		var s: int = n.plans.size() * 2 + w.bonds_of(id, "feud").size() * 3 + w.bonds_of(id, "alliance").size() * 3 + w.bonds_of(id, "romance").size() * 3
		for f in n.known:
			if w.dyn_facts.has(f):
				s += 1
		if s > bs and n.present:
			bs = s
			best = id
	return best

func _process(_d):
	wait += 1
	if wait < 30:
		return
	wait = 0
	step += 1
	var w := Game.world
	match step:
		1:
			main._start(true)
		2:
			Game.speed = 0.0
			# play a day and a half with nobody meddling
			while not w.day_over:
				w.step(0.5)
			w.next_day()
			gs().paper.visible = false
			while w.minute < 150.0 or (w.director.arcs.is_empty() and w.minute < 480.0):
				w.step(0.5)
		3:
			gs().hud.open_log.emit()
		4: _shot("21_board_storylines")
		5:
			gs().gossip.close()
			focus_id = _busiest()
			gs()._open_file(focus_id)
		6: _shot("22_file_" + focus_id)
		7:
			for c in gs().file.find_children("*", "ScrollContainer", true, false):
				(c as ScrollContainer).scroll_vertical = 100000
		77: pass
		8:
			_shot("22b_file_beliefs")
			gs().file.close()
			# find someone mid-whisper / mid-cheer and zoom on them
			var who := ""
			for i in 400:
				w.step(0.25)
				for id in w.present_ids():
					var n: NPC = w.npc(id)
					if n.emote in ["whisper", "cheer"] and n.emote_timer > 1.0:
						who = id
				if who != "":
					break
			focus_id = who
			if who != "":
				gs().view.focus_on(gs().view.chars[who].position + Vector2(0, -40))
				print("emote on ", who, " ", w.npc(who).emote)
		9:
			if focus_id != "":
				var cv: CharacterView = gs().view.chars[focus_id]
				var sp: Vector2 = get_viewport().get_canvas_transform() * cv.global_position
				var img := get_viewport().get_texture().get_image()
				var r := Rect2i(int(sp.x) - 180, int(sp.y) - 260, 360, 360).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
				var crop := img.get_region(r)
				crop.resize(r.size.x * 2, r.size.y * 2, Image.INTERPOLATE_NEAREST)
				crop.save_png("%s/23_emote_closeup.png" % out_dir)
				print("shot 23_emote_closeup")
		10:
			while not w.day_over:
				w.step(0.5)
		11: _shot("24_paper_storylines")
		12: get_tree().quit()
