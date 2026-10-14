extends Node
## Checks that every independent NPC action (initiative event) can really happen:
## for each one, a fresh office runs for a few days and, every few minutes, every
## free character is asked to try it (normal conditions, roles and cooldowns apply —
## only the day's pacing is skipped). Reports per domain and lists any that never fire.
## Usage: godot --headless --path . res://tests/npc_action_test.tscn [-- only=id1,id2 seeds=3 days=3]

func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var seeds := int(args.get("seeds", "3"))
	var days := int(args.get("days", "3"))
	var only: Array = []
	if args.has("only"):
		only = Array(str(args["only"]).split(","))
	var w0: SimWorld = Game.create_world()
	w0.new_game(1)
	var ids: Array = []
	for d in w0.director.initiative:
		if only.is_empty() or d["id"] in only:
			ids.append(d["id"])
	ids.sort()
	var ok_dom := {}
	var all_dom := {}
	var never: Array = []
	var t0 := Time.get_ticks_msec()
	for id in ids:
		var dom: String = str(w0.events.defs[id].get("domain", "?"))
		all_dom[dom] = int(all_dom.get(dom, 0)) + 1
		var fired_at := ""
		for s in seeds:
			fired_at = _probe(id, 7000 + s * 131, days)
			if fired_at != "":
				break
		if fired_at != "":
			ok_dom[dom] = int(ok_dom.get(dom, 0)) + 1
			if args.get("verbose", "0") == "1":
				print("OK    %-26s %s" % [id, fired_at])
		else:
			never.append(id)
			print("NEVER %-26s (%s)" % [id, dom])
	var parts: Array = []
	var n_ok := 0
	for dm in all_dom:
		parts.append("%s %d/%d" % [dm, int(ok_dom.get(dm, 0)), int(all_dom[dm])])
		n_ok += int(ok_dom.get(dm, 0))
	print("\nNPC ACTIONS: %d/%d can happen  (%s)  [%.1fs]" % [n_ok, ids.size(), ", ".join(parts), (Time.get_ticks_msec() - t0) / 1000.0])
	get_tree().quit(0 if never.is_empty() else 1)


## Returns "day N hh:mm by X" the first time the initiative succeeds, or "".
func _probe(id: String, seed_v: int, days: int) -> String:
	var w: SimWorld = Game.create_world()
	w.new_game(seed_v)
	var d: Dictionary = w.events.defs[id]
	var setup: Array = d.get("test", {}).get("setup", [])
	for day in days:
		for e in setup:
			w.events.res.apply(e, {"roles": {}, "vars": {}})
		var next_try := 15.0
		while not w.day_over:
			w.step(1.0)
			if w.minute < next_try:
				continue
			next_try = w.minute + 6.0
			for actor in w.present_ids():
				if not w.available(actor):
					continue
				# start-of-story initiatives may be refused by story limits; give them room
				if w.events.try_initiative(d, actor):
					return "day %d %s by %s" % [w.day, C.fmt(w.minute), actor]
		w.next_day()
	return ""
