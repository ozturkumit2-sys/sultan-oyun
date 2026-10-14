extends Node
## Save/load of the v1.2 data: waiting consequences (traps), intervention reuse
## bookkeeping, the discovery journal, stories started by a secret combination,
## the extended relationship values and the richer memories — and that a loaded
## game carries on (the story still reaches an ending across days).
## Usage: godot --headless --path . res://tests/save_test.tscn

var fails: Array = []


func _ready() -> void:
	var w: SimWorld = Game.create_world()
	w.new_game(4242)
	while w.minute < C.hm("10:10"):
		w.step(0.5)
	# 1) a waiting consequence (desk trap) + a secret combination that starts a story
	_apply(w, "meeting_table", "C15", null)   # waits for the next presentation
	_apply(w, "ws_mert", "I09", "zeynep")
	_apply(w, "ws_mert", "B07", "zeynep")
	w.step(1.0)
	_apply(w, "ws_mert", "J02", null)
	for k in 10:
		w.step(1.0)
	w.change_rel("selin", "deniz", "respect", -30.0)
	w.change_rel("burak", "ceren", "romance", 12.0)
	w.change_rel("zeynep", "mert", "suspicion", 40.0)
	w.change_rel("deniz", "selin", "resentment", 25.0)
	w.npc("ece").remember("praised", "selin", 0.6, 0.8, "mem.praised", {"target": "selin"}, w.day, w.minute, 2, {"emo": "grateful", "cert": 0.6, "src": "heard"})
	var before := {
		"traps": w.traps.size(),
		"used": w.iv.used.size(),
		"found": w.discovery.ivs.size(),
		"story": w.director.arcs.filter(func(x): return x["arc"] == "coffee_date_mixup").size(),
		"respect": w.npc("selin").get_rel("deniz", "respect"),
		"romance": w.npc("burak").get_rel("ceren", "romance"),
		"suspicion": w.npc("zeynep").get_rel("mert", "suspicion"),
		"resentment": w.npc("deniz").get_rel("selin", "resentment"),
		"mem": w.npc("ece").memories.back().duplicate(),
		"cool": w.iv.cool.size(),
		"hist": w.director.actor_hist.size(),
	}
	if before["traps"] == 0:
		fails.append("no trap was planted before saving")
	if before["story"] == 0:
		fails.append("the secret combination did not start its story")
	var snap := JSON.stringify(w.to_dict())
	var w2: SimWorld = Game.create_world()
	w2.from_dict(JSON.parse_string(snap))
	_eq("traps", before["traps"], w2.traps.size())
	_eq("intervention uses", before["used"], w2.iv.used.size())
	_eq("journal entries", before["found"], w2.discovery.ivs.size())
	_eq("story running", before["story"], w2.director.arcs.filter(func(x): return x["arc"] == "coffee_date_mixup").size())
	_eq("respect", before["respect"], w2.npc("selin").get_rel("deniz", "respect"))
	_eq("romance", before["romance"], w2.npc("burak").get_rel("ceren", "romance"))
	_eq("suspicion", before["suspicion"], w2.npc("zeynep").get_rel("mert", "suspicion"))
	_eq("resentment", before["resentment"], w2.npc("deniz").get_rel("selin", "resentment"))
	_eq("cooldowns", before["cool"], w2.iv.cool.size())
	_eq("director novelty memory", before["hist"], w2.director.actor_hist.size())
	var m2: Dictionary = w2.npc("ece").memories.back()
	for k in ["emo", "cert", "src", "about", "day"]:
		if str(m2.get(k, "")) != str(before["mem"].get(k, "")):
			fails.append("memory field %s changed: %s -> %s" % [k, before["mem"].get(k, ""), m2.get(k, "")])
	# idempotent
	var snap2 := JSON.stringify(w2.to_dict())
	var w3: SimWorld = Game.create_world()
	w3.from_dict(JSON.parse_string(snap2))
	if JSON.stringify(w3.to_dict()) != snap2:
		fails.append("save/load is not idempotent")
	# the loaded game carries on: the story reaches an ending, over days if needed
	var days := 0
	while days < 4 and w2.director.finished.filter(func(x): return x["arc"] == "coffee_date_mixup").is_empty():
		while not w2.day_over:
			w2.step(0.5)
		w2.next_day()
		days += 1
	var fin: Array = w2.director.finished.filter(func(x): return x["arc"] == "coffee_date_mixup")
	if fin.is_empty():
		fails.append("story did not finish after loading")
	else:
		print("  story ended after load: %s (%d stages, day %d)" % [fin[0]["result"], int(fin[0]["steps"]), int(fin[0]["day"])])
	if not w2.discovery.arcs.has("coffee_date_mixup"):
		fails.append("finished story not recorded in the journal")
	for f in fails:
		print("FAIL " + f)
	print("SAVE TEST: %s" % ("PASS" if fails.is_empty() else "FAIL (%d)" % fails.size()))
	get_tree().quit(0 if fails.is_empty() else 1)


func _apply(w: SimWorld, spot: String, iv_id: String, value) -> void:
	for a in w.iv.actions_for(spot):
		if a.get("iv", "") == iv_id:
			if not a["enabled"]:
				fails.append("%s not available on %s: %s" % [iv_id, spot, a.get("reason", "")])
				return
			a["spot"] = spot
			if not w.iv.apply(a, value):
				fails.append("%s failed to apply" % iv_id)
			return
	fails.append("%s not listed on %s" % [iv_id, spot])


func _eq(what: String, a, b) -> void:
	if str(a) != str(b):
		fails.append("%s changed by save/load: %s -> %s" % [what, a, b])
