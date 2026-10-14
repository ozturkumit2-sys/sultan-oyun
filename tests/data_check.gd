extends Node
## Static check of the game data AS THE ENGINE LOADS IT (complements _dev/data_src/build_data.py):
##  - intervention count per category, unique ids/keys, every one has a state change + a reaction
##  - every effect / condition / special / picker used in the data is implemented by the engine
##    (the names are read straight out of the GDScript sources)
##  - every event an effect points to exists; every story arc has >= 3 stages, a valid first
##    stage and no unreachable stage; hidden combinations name their ingredients
##  - NPC actions (initiatives) per domain
## Usage: godot --headless --path . res://tests/data_check.tscn

var errors: Array = []


func _ready() -> void:
	var ivd: Dictionary = Game.iv_data
	var events: Dictionary = {}
	for e in _json("res://data/events.json"):
		events[e["id"]] = e
	var arcs: Array = _json("res://data/arcs.json")
	var eff_impl := _labels("res://scripts/sim/event_consequences.gd", "func apply(", "\nfunc ")
	var cond_impl := _labels("res://scripts/sim/event_conditions.gd", "func _check(", "\nfunc ")
	var spec_impl := _labels("res://scripts/sim/world_specials.gd", "static func run(", "\nstatic func ")
	var pick_impl := _labels("res://scripts/sim/world_specials.gd", "static func pick(", "\nstatic func ")
	# ---------------------------------------------------------------- interventions
	var cats := {}
	var ids := {}
	var keys := {}
	var list: Array = ivd.get("list", [])
	for d in list:
		var tag: String = "iv " + str(d["id"])
		if ids.has(d["id"]):
			errors.append(tag + ": duplicate id")
		if keys.has(d["key"]):
			errors.append(tag + ": duplicate key")
		ids[d["id"]] = true
		keys[d["key"]] = true
		cats[d["cat"]] = int(cats.get(d["cat"], 0)) + 1
		if d.get("legacy", "") == "":
			if d.get("state", []).is_empty():
				errors.append(tag + ": no state change")
			if d.get("react", []).is_empty() and d.get("watch", []).is_empty():
				errors.append(tag + ": no reaction")
		for v in d.get("vars", []):
			if not (str(v["fn"]) in pick_impl):
				errors.append(tag + ": picker '%s' not implemented" % v["fn"])
		_walk_eff(d.get("state", []) + d.get("react", []), tag, eff_impl, cond_impl, spec_impl, pick_impl, events)
		_walk_cond(d.get("conds", []) + d.get("pick", []), tag, cond_impl, pick_impl)
		if d.get("hidden", false):
			for c in d.get("combo", []):
				if not ids.has(c) and list.filter(func(x): return x["id"] == c).is_empty():
					errors.append(tag + ": unknown ingredient " + str(c))
		if d.get("arc", "") != "" and arcs.filter(func(a): return a["id"] == d["arc"]).is_empty():
			errors.append(tag + ": starts unknown story " + str(d["arc"]))
	# ---------------------------------------------------------------- events
	var dom := {}
	var n_init := 0
	for id in events:
		var e: Dictionary = events[id]
		var tag: String = "event " + str(id)
		var effs: Array = e.get("effects", []).duplicate()
		for o in e.get("outcomes", []):
			effs += o.get("effects", [])
			_walk_cond(o.get("when", []), tag, cond_impl, pick_impl)
		_walk_eff(effs, tag, eff_impl, cond_impl, spec_impl, pick_impl, events)
		_walk_cond(e.get("conditions", []), tag, cond_impl, pick_impl)
		for r in e.get("roles", []):
			_walk_cond(r.get("where", []), tag, cond_impl, pick_impl)
			if r.has("fn") and not (str(r["fn"]) in pick_impl):
				errors.append(tag + ": role picker '%s' not implemented" % r["fn"])
		for v in e.get("vars", []):
			if not (str(v["fn"]) in pick_impl):
				errors.append(tag + ": picker '%s' not implemented" % v["fn"])
		var tg = e.get("trigger", "")
		if (typeof(tg) == TYPE_STRING and tg == "initiative") or (typeof(tg) == TYPE_ARRAY and "initiative" in tg):
			n_init += 1
			dom[str(e.get("domain", "?"))] = int(dom.get(str(e.get("domain", "?")), 0)) + 1
	# ---------------------------------------------------------------- arcs
	var max_stages := 0
	for a in arcs:
		var st: Dictionary = a["stages"]
		max_stages = maxi(max_stages, st.size())
		if st.size() < 3:
			errors.append("arc %s: only %d stages" % [a["id"], st.size()])
		if not st.has(a["first"]):
			errors.append("arc %s: first stage missing" % a["id"])
		# reachability through arc_next effects of the stage events and fail routes
		var seen := {}
		var todo: Array = [a["first"]]
		while not todo.is_empty():
			var cur: String = todo.pop_back()
			if seen.has(cur) or not st.has(cur):
				continue
			seen[cur] = true
			var ev: Dictionary = events.get(st[cur]["event"], {})
			if ev.is_empty():
				errors.append("arc %s/%s: event %s missing" % [a["id"], cur, st[cur]["event"]])
				continue
			for nx in _arc_nexts(ev):
				todo.append(nx)
			var f := str(st[cur].get("fail", ""))
			if st.has(f):
				todo.append(f)
		for sid in st:
			if not seen.has(sid):
				errors.append("arc %s: stage %s unreachable" % [a["id"], sid])
	# ---------------------------------------------------------------- report
	var cl: Array = []
	var total := 0
	for c in "ABCDEFGHIJ":
		cl.append("%s=%d" % [c, int(cats.get(c, 0))])
		total += int(cats.get(c, 0))
		if int(cats.get(c, 0)) < 20:
			errors.append("category %s has only %d interventions" % [c, int(cats.get(c, 0))])
	var dl: Array = []
	for k in dom:
		dl.append("%s=%d" % [k, dom[k]])
	print("INTERVENTIONS: %d unique (%s)" % [total, ", ".join(cl)])
	print("NPC ACTIONS:   %d (%s)" % [n_init, ", ".join(dl)])
	print("STORY ARCS:    %d (up to %d stages each), %d events in total" % [arcs.size(), max_stages, events.size()])
	print("ENGINE:        %d effect types, %d condition types, %d specials, %d pickers implemented" % [eff_impl.size(), cond_impl.size(), spec_impl.size(), pick_impl.size()])
	if total < 200:
		errors.append("fewer than 200 interventions")
	if n_init < 100:
		errors.append("fewer than 100 NPC actions")
	if arcs.size() < 50:
		errors.append("fewer than 50 story arcs")
	for e in errors.slice(0, 60):
		print("ERROR " + str(e))
	print("DATA CHECK: %s (%d problems)" % ["OK" if errors.is_empty() else "FAILED", errors.size()])
	get_tree().quit(0 if errors.is_empty() else 1)


func _json(path: String):
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## The quoted labels of a GDScript `match` block: '\t\t"name":' or '\t\t"a", "b":'.
func _labels(path: String, from: String, until: String) -> Array:
	var src := FileAccess.get_file_as_string(path)
	var i := src.find(from)
	if i < 0:
		errors.append("cannot find %s in %s" % [from, path])
		return []
	var j := src.find(until, i + from.length())
	var body := src.substr(i, (j - i) if j > 0 else -1)
	var out: Array = []
	var re := RegEx.new()
	re.compile("(?m)^\\t\\t((?:\"[a-z_0-9]+\"(?:, )?)+):")
	for m in re.search_all(body):
		for part in m.get_string(1).split(","):
			out.append(part.strip_edges().trim_prefix("\"").trim_suffix("\""))
	return out


func _arc_nexts(ev: Dictionary) -> Array:
	var r: Array = []
	var effs: Array = ev.get("effects", []).duplicate()
	for o in ev.get("outcomes", []):
		effs += o.get("effects", [])
	for f in effs:
		if f.get("e", "") == "arc_next":
			r.append(str(f["stage"]))
	return r


func _walk_eff(effs: Array, tag: String, eff_impl: Array, cond_impl: Array, spec_impl: Array, pick_impl: Array, events: Dictionary) -> void:
	for f in effs:
		var k := str(f.get("e", ""))
		if not (k in eff_impl):
			errors.append("%s: effect '%s' not implemented by the engine" % [tag, k])
		if f.has("when"):
			_walk_cond(f["when"], tag, cond_impl, pick_impl)
		if k == "call":
			var fn := str(f.get("fn", ""))
			if not (fn in spec_impl):
				errors.append("%s: special '%s' not implemented" % [tag, fn])
			if fn == "pick_role" and not (str(f.get("pfn", "")) in pick_impl):
				errors.append("%s: picker '%s' not implemented" % [tag, f.get("pfn", "")])
		if k in ["chain", "trap", "intent", "meetup", "hunt"] and str(f.get("event", "")) != "" and not events.has(f["event"]):
			errors.append("%s: points to missing event %s" % [tag, f["event"]])
		if f.has("effects"):
			_walk_eff(f["effects"], tag, eff_impl, cond_impl, spec_impl, pick_impl, events)
		if k == "pick":
			for opt in f.get("of", []):
				_walk_eff(opt, tag, eff_impl, cond_impl, spec_impl, pick_impl, events)


func _walk_cond(conds: Array, tag: String, cond_impl: Array, pick_impl: Array) -> void:
	for c in conds:
		var k := str(c.get("c", ""))
		if not (k in cond_impl):
			errors.append("%s: condition '%s' not implemented by the engine" % [tag, k])
		if k == "picks" and not (str(c.get("fn", "")) in pick_impl):
			errors.append("%s: picker '%s' not implemented" % [tag, c.get("fn", "")])
		if k in ["any", "all"]:
			_walk_cond(c.get("of", []), tag, cond_impl, pick_impl)
