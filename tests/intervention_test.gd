extends Node
## Runtime check of EVERY intervention in data/interventions.json:
##  1. it can be reached from its object's menu (hidden ones once their ingredients are done),
##  2. applying it really changes the game state,
##  3. a reaction actually plays in the simulation afterwards (someone runs into it).
## Usage: godot --headless --path . res://tests/intervention_test.tscn [-- only=A02,B05 seeds=3 verbose=1]

var args := {}
var verbose := false
var bad_text: Dictionary = {}     # text with unresolved {placeholders} or raw keys
var _pref_owner := ""            # combos: ingredients often have to hit the same desk / person
var _pref_target := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	verbose = args.get("verbose", "0") == "1"
	var only: Array = []
	if args.has("only"):
		only = Array(str(args["only"]).split(","))
	var seeds := int(args.get("seeds", "4"))
	var defs: Array = Game.iv_data.get("list", [])
	var known := {}
	for d0 in defs:
		known[d0["id"]] = true
	for oid in only:
		if not known.has(oid):
			print("FAIL %s: no such intervention in data" % oid)
			get_tree().quit(1)
			return
	var fails: Array = []
	var weak: Array = []
	var cats := {}
	var t0 := Time.get_ticks_msec()
	for d in defs:
		if not only.is_empty() and not (d["id"] in only):
			continue
		var best := {}
		var reacted := 0
		for s in seeds:
			var r := _run(d, 1000 + s * 7919)
			if best.is_empty() or (r["ok"] and not best["ok"]):
				best = r
			if r["reacted"]:
				reacted += 1
			if r["ok"] and reacted >= 2:
				break
		var ok: bool = best.get("ok", false)
		var cat: String = d["cat"]
		if not cats.has(cat):
			cats[cat] = [0, 0]
		cats[cat][1] += 1
		if ok:
			cats[cat][0] += 1
		var line := "%s %-6s %-22s menu:%s state:%s reaction:%s %s" % ["PASS" if ok else "FAIL", d["id"], d["key"],
			"Y" if best.get("reached", false) else "N", "Y" if best.get("changed", false) else "N",
			"Y" if best.get("reacted", false) else "N", best.get("note", "")]
		if not ok:
			fails.append(line)
		elif reacted < 2 and seeds >= 3:
			weak.append(d["id"])
		if verbose or not ok:
			print(line)
	print("")
	for c in "ABCDEFGHIJ":
		if cats.has(c):
			print("  %s: %d/%d working" % [c, cats[c][0], cats[c][1]])
	if not weak.is_empty():
		print("  reacted in only one seed: " + ", ".join(weak))
	if not bad_text.is_empty():
		print("  TEXT PROBLEMS:")
		for k in bad_text.keys().slice(0, 40):
			print("    " + k)
	print("INTERVENTIONS: %d/%d pass (%.1fs)" % [defs.size() - fails.size() if only.is_empty() else only.size() - fails.size(),
		defs.size() if only.is_empty() else only.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	get_tree().quit(1 if not fails.is_empty() else 0)


func _check_text(ivid: String, text: String) -> void:
	if text.find("{") >= 0 or text.find("log.") == 0 or text.find("iv.") == 0 or text.find("mem.") == 0 or text.strip_edges() == "":
		bad_text[ivid + ": " + text] = true


func _snapshot(w: SimWorld) -> String:
	var people := {}
	for id in w.order:
		var n: NPC = w.npc(id)
		people[id] = [n.rel, n.known, n.plans, n.leave_at, n.lunch_at, n.tasks, n.meeting_belief, n.intents.size(), n.today_flags]
	return JSON.stringify([w.office.objects, w.office.items, w.traps, w.meeting, w.flags, w.dyn_facts, w.favor, people, w.events.queue.size()])


## Gets the action for this intervention from its object's menu, doing the
## ingredients of a hidden combination first if needed.
func _reach(w: SimWorld, d: Dictionary, depth := 0) -> Dictionary:
	var spots: Array = []
	if d["obj"] == "ws":
		var owners: Array = d.get("owners", [])
		for id in w.order:
			if owners.is_empty() or id in owners:
				spots.append("ws_" + id)
		w.shuffle(spots)
		if _pref_owner != "" and spots.has("ws_" + _pref_owner):
			spots.erase("ws_" + _pref_owner)
			spots.push_front("ws_" + _pref_owner)
	elif d["obj"] == "item":
		for it in w.office.items:
			spots.append("item_" + it)
	else:
		spots.append(d["obj"])
	for sp in spots:
		for a in w.iv.actions_for(sp):
			if a.get("iv", "") == d["id"] and a["enabled"]:
				a["spot"] = sp
				return a
	if depth == 0 and d.get("combo", []).size() > 0:
		for cid in d["combo"]:
			var cd: Dictionary = w.iv.by_id.get(cid, {})
			if cd.is_empty():
				continue
			var ca := _reach(w, cd, 1)
			if ca.is_empty():
				return {}
			var cv = _option(w, ca)
			if str(cv) == "__none__" or not w.iv.apply(ca, cv):
				return {}
			if _pref_owner == "" and str(ca.get("owner", "")) != "":
				_pref_owner = str(ca["owner"])
			if _pref_target == "":
				if typeof(cv) == TYPE_ARRAY:
					_pref_target = str(cv[0])
				elif str(ca.get("needs", "")) == "person" and cv != null:
					_pref_target = str(cv)
			for k in 3:
				w.step(1.0)
		return _reach(w, d, 1)
	return {}


func _option(w: SimWorld, a: Dictionary):
	if str(a.get("needs", "")) == "":
		return null
	var opts: Array = w.iv.options_for(a)
	var en: Array = []
	for o in opts:
		if o["enabled"]:
			en.append(o)
	if en.is_empty():
		return "__none__"
	var v = en[w.rng.randi() % en.size()]["value"]
	if str(a.get("needs", "")) == "person":
		for want in [_pref_target, _pref_owner]:
			if want == "":
				continue
			for o in en:
				if str(o["value"]) == want:
					v = o["value"]
					break
			if str(v) == want:
				break
	if InterventionManager.two_step(a.get("def", {})):
		var second: Array = w.iv.options_for(a, v)
		return second[w.rng.randi() % second.size()]["value"]
	return v


func _run(d: Dictionary, seed_v: int) -> Dictionary:
	var w: SimWorld = Game.create_world()
	w.new_game(seed_v)
	w.said.connect(func(_id, text, _to): _check_text(d["id"], text))
	w.logged.connect(func(entry): _check_text(d["id"], entry["text"]))
	var test: Dictionary = d.get("test", {})
	var at := C.hm(str(test.get("at", "10:05")))
	for dd in int(test.get("day", 0)):
		while not w.day_over:
			w.step(5.0)
		w.next_day()
	while w.minute < at:
		w.step(1.0)
	for e in test.get("setup", []):
		w.events.res.apply(e, {"roles": {}, "vars": {}})
	_pref_owner = ""
	_pref_target = str(test.get("prefer", ""))
	var arc_id: String = str(d.get("arc", ""))
	var arcs_before := _arc_count(w, arc_id)
	var res := {"ok": false, "reached": false, "changed": false, "reacted": false, "note": ""}
	if d.get("hidden", false) and _visible_anywhere(w, d):
		res["note"] = "hidden combination visible before its ingredients"
		return res
	var a := _reach(w, d)
	if a.is_empty():
		# a few need the right moment: try again a little later
		for k in 6:
			for m in 20:
				w.step(1.0)
			a = _reach(w, d)
			if not a.is_empty():
				break
	if a.is_empty():
		res["note"] = "not reachable"
		return res
	res["reached"] = true
	var val = _option(w, a)
	if str(val) == "__none__":
		res["note"] = "no enabled option"
		return res
	var before_fired: Dictionary = w.events.fired_total.duplicate()
	var snap := _snapshot(w)
	var cid_before: int = w.iv.counter
	if not w.iv.apply(a, val):
		res["note"] = "apply() returned false"
		return res
	res["changed"] = _snapshot(w) != snap
	if not res["changed"]:
		res["note"] = "no state change"
	var watch: Array = d.get("watch", [])
	var cid := "c%d" % (cid_before + 1)
	var limit: float = float(test.get("minutes", 200))
	var waited := 0.0
	var days_more := int(test.get("days", 1))
	var fired_ids: Array = []
	while waited < limit or days_more > 0:
		if w.day_over:
			if days_more <= 0:
				break
			days_more -= 1
			w.next_day()
			limit = waited + float(test.get("minutes", 200))
		w.step(1.0)
		waited += 1.0
		var casc: int = int(w.discovery.cascades.get(cid, {}).get("count", 0))
		fired_ids.clear()
		for wid in watch:
			if int(w.events.fired_total.get(wid, 0)) > int(before_fired.get(wid, 0)):
				fired_ids.append(wid)
		var arc_ok := arc_id == "" or _arc_count(w, arc_id) > arcs_before
		if (casc > 0 or not fired_ids.is_empty()) and arc_ok:
			res["reacted"] = true
			# let it play a little so follow-ups run too
			for k in 20:
				w.step(1.0)
			break
	if res["reacted"]:
		var fired2: Array = []
		for wid in watch:
			if int(w.events.fired_total.get(wid, 0)) > int(before_fired.get(wid, 0)):
				fired2.append(wid)
		res["note"] = "fired: " + ",".join(fired2.slice(0, 4)) + ((" | story: " + arc_id) if arc_id != "" else "")
	elif res["note"] == "":
		res["note"] = "nothing happened within %d min" % int(waited)
	res["ok"] = res["reached"] and res["changed"] and res["reacted"]
	return res


## How many times a story has been started in this world so far (running + finished).
func _arc_count(w: SimWorld, arc_id: String) -> int:
	if arc_id == "":
		return 0
	var n := 0
	for inst in w.director.arcs:
		if inst["arc"] == arc_id:
			n += 1
	for f in w.director.finished:
		if f["arc"] == arc_id:
			n += 1
	return n


## Is this intervention listed in any menu right now (enabled or not)?
func _visible_anywhere(w: SimWorld, d: Dictionary) -> bool:
	var spots: Array = []
	if d["obj"] == "ws":
		for id in w.order:
			spots.append("ws_" + id)
	else:
		spots.append(d["obj"])
	for sp in spots:
		for a in w.iv.actions_for(sp):
			if a.get("iv", "") == d["id"]:
				return true
	return false
