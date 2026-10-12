extends Node
## Headless multi-day simulation test. Runs several in-game days with random
## player meddling, checks invariants, exercises save/load, prints coverage.
## Usage: godot --headless --path . res://tests/sim_test.tscn -- days=6 seed=7 meddle=1

var days := 6
var seed_v := 7
var meddle := true
var errors: Array = []
var said_count := 0
var log_count := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			match kv[0]:
				"days": days = int(kv[1])
				"seed": seed_v = int(kv[1])
				"meddle": meddle = kv[1] == "1"
	var t0 := Time.get_ticks_msec()
	var w: SimWorld = Game.create_world()
	# every place must be reachable from the entrance
	var reach := w.office.reachable_from(Vector2i(13, 11))
	for pid in w.office.place_order:
		if not reach.has(w.office.place_cell(pid)):
			errors.append("place %s at %s unreachable" % [pid, w.office.place_cell(pid)])
	var walk_cnt := 0
	for y in C.GRID_H:
		for x in C.GRID_W:
			if w.office.walkable(Vector2i(x, y)):
				walk_cnt += 1
				if not reach.has(Vector2i(x, y)):
					errors.append("walkable cell %s unreachable" % Vector2i(x, y))
	print("walkable cells: %d, reachable: %d" % [walk_cnt, reach.size()])
	w.said.connect(func(_i, _t, _to): said_count += 1)
	w.logged.connect(func(_e): log_count += 1)
	w.new_game(seed_v)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v * 31 + 5
	var summaries: Array = []
	w.day_ended.connect(func(s): summaries.append(s))
	var loaded_once := false
	for d in days:
		var next_meddle := rng.randf_range(15, 60)
		var steps := 0
		while not w.day_over:
			w.step(0.25)
			steps += 1
			if meddle and w.minute >= next_meddle:
				next_meddle = w.minute + rng.randf_range(12, 45)
				_random_meddle(w, rng)
			if steps % 40 == 0:
				_check(w)
			if not loaded_once and d == 1 and w.minute > 200.0:
				loaded_once = true
				var snap := JSON.stringify(w.to_dict())
				var w2: SimWorld = Game.create_world()
				w2.from_dict(JSON.parse_string(snap))
				var snap2 := JSON.stringify(w2.to_dict())
				var w3: SimWorld = Game.create_world()
				w3.from_dict(JSON.parse_string(snap2))
				var snap3 := JSON.stringify(w3.to_dict())
				if snap2 != snap3:
					errors.append("save/load not idempotent %d vs %d" % [snap2.length(), snap3.length()])
				if w2.day != w.day or absf(w2.minute - w.minute) > 0.01 or absf(w2.npc("selin").mood - w.npc("selin").mood) > 0.01:
					errors.append("save/load lost state")
				w = w2
				w.said.connect(func(_i, _t, _to): said_count += 1)
				w.logged.connect(func(_e): log_count += 1)
				w.day_ended.connect(func(s): summaries.append(s))
				print("  [save/load roundtrip ok, %d bytes]" % snap.length())
			if steps > 4000:
				errors.append("day %d did not end" % w.day)
				break
		var s: Dictionary = summaries[-1] if summaries.size() > 0 else {}
		print("DAY %d %s chaos=%.1f counts=%s" % [w.day, Loc.t(s.get("headline", "")), float(s.get("chaos", 0)), JSON.stringify(s.get("counts", {}))])
		for st in s.get("stories", []):
			print("    * [%d] %s" % [st["imp"], st["text"]])
		if d < days - 1:
			w.next_day()
	print("\n--- events fired (all days) ---")
	var keys: Array = w.events.fired_total.keys()
	keys.sort()
	var line := ""
	for k in keys:
		line += "%s:%d  " % [k, w.events.fired_total[k]]
	print(line)
	var never: Array = []
	for k in w.events.defs:
		if not w.events.fired_total.has(k):
			never.append(k)
	print("never fired (%d): %s" % [never.size(), ", ".join(never)])
	print("speech lines: %d, log entries: %d, distinct events fired: %d/%d" % [said_count, log_count, keys.size(), w.events.defs.size()])
	print("relationships sample: selin->deniz %s | mert->ceren %s" % [JSON.stringify(w.npc("selin").r("deniz")), JSON.stringify(w.npc("mert").r("ceren"))])
	for id in w.order:
		var n: NPC = w.npc(id)
		print("  %-7s mood=%5.1f stress=%5.1f goal=%s mems=%d known=%d favor=%.0f" % [id, n.mood, n.stress, n.goal, n.memories.size(), n.known.size(), float(w.favor.get(id, 0))])
	print("elapsed %.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	if errors.is_empty():
		print("RESULT: OK")
	else:
		print("RESULT: %d ERRORS" % errors.size())
		for e in errors.slice(0, 30):
			print("  ! " + str(e))
	get_tree().quit(0 if errors.is_empty() else 1)


func _random_meddle(w: SimWorld, rng: RandomNumberGenerator) -> void:
	var spots := ["coffee_machine", "printer", "meeting_board", "ac", "lights", "promo_file"]
	for id in C.NPC_IDS:
		spots.append("ws_" + id)
	for it in w.office.items:
		spots.append("item_" + it)
	var spot: String = spots[rng.randi() % spots.size()]
	var acts := Interventions.actions_for(w, spot)
	var en: Array = acts.filter(func(a): return a["enabled"])
	if en.is_empty():
		return
	var act: Dictionary = en[rng.randi() % en.size()]
	var val = null
	if act["needs"] != "":
		var opts: Array = Interventions.options_for(w, act).filter(func(o): return o["enabled"])
		if opts.is_empty():
			return
		val = opts[rng.randi() % opts.size()]["value"]
	Interventions.apply(w, act, val)


func _check(w: SimWorld) -> void:
	for id in w.order:
		var n: NPC = w.npc(id)
		if not n.present:
			continue
		if n.pos.x < -0.5 or n.pos.y < -0.5 or n.pos.x > 16.0 or n.pos.y > 14.5:
			errors.append("%s out of bounds at %s (act %s)" % [id, n.pos, n.act])
		if is_nan(n.mood) or is_nan(n.stress):
			errors.append("%s NaN stats" % id)
		var c := OfficeEnv.cell_of(n.pos)
		if w.office.in_bounds(c) and not w.office.walkable(c) and n.phase == "walk":
			errors.append("%s walking through blocked cell %s act=%s" % [id, c, n.act])
