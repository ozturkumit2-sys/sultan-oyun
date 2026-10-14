extends Node
## Runs every story arc (or arc=<id>) from its test cast with several seeds and
## reports how far each one gets and how it ends. trace=1 prints the director trace.
## Usage: godot --headless --path . res://tests/arc_probe.tscn -- [arc=id] [seeds=4] [trace=1]

func _ready() -> void:
	var only := ""
	var seeds := 4
	var tr := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("arc="):
			only = arg.substr(4)
		elif arg.begins_with("seeds="):
			seeds = int(arg.substr(6))
		elif arg == "trace=1":
			tr = true
	var w0: SimWorld = Game.create_world()
	w0.new_game(1)
	var total := 0
	var deep_arcs := 0
	var shallow: Array = []
	for arc_id in w0.director.arc_defs:
		if only != "" and arc_id != only:
			continue
		var cast: Dictionary = w0.director.arc_defs[arc_id].get("test", {})
		if cast.is_empty():
			cast = _legacy_cast(arc_id)
		var res := {}
		var best := 0
		var depth_sum := 0
		for s in seeds:
			var w: SimWorld = Game.create_world()
			w.new_game(500 + s * 17 + total)
			while w.minute < 40.0:
				w.step(0.25)
			var uid := w.director.start_arc(arc_id, cast, {}, "", true)
			var days := 0
			while days < 5 and not w.director.find(uid).is_empty():
				while not w.day_over and not w.director.find(uid).is_empty():
					w.step(0.5)
				if not w.director.find(uid).is_empty():
					w.next_day()
					days += 1
			var fin: Array = w.director.finished.filter(func(x): return x["uid"] == uid)
			var key := "STUCK" if fin.is_empty() else str(fin[0]["result"])
			var steps := 0 if fin.is_empty() else int(fin[0]["steps"])
			res[key] = int(res.get(key, 0)) + 1
			best = maxi(best, steps)
			depth_sum += steps
			if tr:
				for t in w.director.trace:
					if str(t).find(" " + arc_id + "/") >= 0:
						print("      ", t)
		total += 1
		if best >= 3:
			deep_arcs += 1
		else:
			shallow.append(arc_id)
		print("%-18s max %d  avg %.1f  %s" % [arc_id, best, float(depth_sum) / seeds, str(res)])
	print("\nARCS: %d probed, %d reached 3+ stages at least once. Shallow: %s" % [total, deep_arcs, str(shallow)])
	get_tree().quit()


func _legacy_cast(arc_id: String) -> Dictionary:
	var st = load("res://tests/story_test.gd")
	return st.CASTS.get(arc_id, {})
