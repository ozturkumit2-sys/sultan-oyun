extends Node
## Story-system tests (headless). Each test builds a fresh office with a fixed seed.
## Usage: godot --headless --path . res://tests/story_test.tscn

var results: Array = []


func _ready() -> void:
	_t("1. event fires when its conditions are met", _test_fires_when_met)
	_t("2. event does NOT fire when conditions are not met", _test_blocked_when_unmet)
	_t("3. one event triggers the next (chain + multi-stage story)", _test_chaining)
	_t("4. memories, beliefs, plans and stories carry over to the next day", _test_memory_next_day)
	_t("5. relationship changes change behaviour", _test_relationships_drive_behaviour)
	_t("6. save/load keeps ongoing stories going", _test_save_load_story)
	_t("7. things happen with NO player input", _test_autonomous_days)
	_t("8. rumours: hearsay is uncertain, false ones get debunked", _test_beliefs)
	_t("9. every story arc runs to an ending (no stuck stages)", _test_every_arc)
	var ok := 0
	for r in results:
		print(("PASS  " if r[1] else "FAIL  ") + r[0] + ("" if r[1] else "   -> " + r[2]))
		if r[1]:
			ok += 1
	print("\nSTORY TESTS: %d/%d passed" % [ok, results.size()])
	get_tree().quit(0 if ok == results.size() else 1)


var _why := ""


func _t(name: String, fn: Callable) -> void:
	_why = ""
	var passed: bool = fn.call()
	results.append([name, passed, _why])


func _fail(msg: String) -> bool:
	_why = msg
	return false


func _world(seed_v: int) -> SimWorld:
	var w: SimWorld = Game.create_world()
	w.new_game(seed_v)
	return w


func _run_until(w: SimWorld, minute: float) -> void:
	while w.minute < minute and not w.day_over:
		w.step(0.25)


func _wait_free(w: SimWorld, ids: Array, limit := 120.0) -> bool:
	var end := w.minute + limit
	while w.minute < end and not w.day_over:
		var all_free := true
		for id in ids:
			if not w.available(id):
				all_free = false
		if all_free:
			return true
		w.step(0.25)
	return false


# ---------------------------------------------------------------------------- 1
func _test_fires_when_met() -> bool:
	var w := _world(101)
	_run_until(w, 250.0)
	if not _wait_free(w, ["ece", "selin"]):
		return _fail("ece/selin never free")
	for id in w.order:
		w.npc(id).stress = 5.0
	w.npc("selin").stress = 70.0
	var before := w.npc("selin").get_rel("ece", "friendship")
	var d: Dictionary = w.events.defs["bring_snack"]
	if not w.events.try_initiative(d, "ece"):
		return _fail("bring_snack did not start although Ece is caring and Selin is stressed")
	var it: Array = w.npc("ece").intents.filter(func(i): return i.get("event", "") == "snack_scene")
	if it.is_empty() or it[0]["target"] != "selin":
		return _fail("Ece is not walking over to Selin: %s" % [w.npc("ece").intents])
	var n0 := int(w.events.fired_total.get("snack_scene", 0))
	var end := w.minute + 60.0
	while w.minute < end and int(w.events.fired_total.get("snack_scene", 0)) == n0:
		w.step(0.25)
	if int(w.events.fired_total.get("snack_scene", 0)) == n0:
		return _fail("the snack scene never played")
	if w.npc("selin").get_rel("ece", "friendship") <= before:
		return _fail("Selin's friendship towards Ece did not grow")
	if not w.npc("selin").has_memory("helped_me", "ece"):
		return _fail("Selin doesn't remember Ece's kindness")
	return true


# ---------------------------------------------------------------------------- 2
func _test_blocked_when_unmet() -> bool:
	var w := _world(102)
	_run_until(w, 250.0)
	_wait_free(w, ["ece"])
	for id in w.order:
		w.npc(id).stress = 0.0
	if w.events.try_initiative(w.events.defs["bring_snack"], "ece"):
		return _fail("bring_snack fired although nobody is stressed")
	# a story can't start twice, and the niece story needs the secret to exist
	w.flags.erase("fact_ece_relative")
	if w.events.try_initiative(w.events.defs["start_niece"], "ece"):
		return _fail("the niece story started without the secret existing")
	w.flags["fact_ece_relative"] = true
	var uid := w.director.start_arc("layoff_panic", {"ear": "zeynep", "boss": "ahmet"})
	if uid == "":
		return _fail("could not start layoff_panic for the check")
	if w.director.start_arc("layoff_panic", {"ear": "mert", "boss": "ahmet"}) != "":
		return _fail("a second layoff_panic started while one is running")
	# relationship condition: no feud -> no feud snub
	if w.events.run_event("feud_snub", {"actor": "mert", "target": "burak"}, {}):
		return _fail("feud_snub played between friends")
	return true


# ---------------------------------------------------------------------------- 3
func _test_chaining() -> bool:
	# (a) a false rumour is checked -> debunked -> its source gets confronted
	var w := _world(103)
	_run_until(w, 200.0)
	var f := w.make_rumor("slacker", "mert", "zeynep", 0.8, false, "zeynep")
	w.learn("zeynep", f, "", 0.9)
	w.learn("ceren", f, "zeynep")
	if not _wait_free(w, ["ceren", "mert"]):
		return _fail("ceren/mert never free")
	if not w.events.run_event("rumor_check_scene", {"actor": "ceren", "target": "mert"}, {"fact": f}):
		return _fail("rumor_check_scene did not run")
	var end := w.minute + 90.0
	while w.minute < end and int(w.events.fired_total.get("rumor_source_confront", 0)) == 0:
		w.step(0.25)
	if int(w.events.fired_total.get("hunt_rumor_source", 0)) == 0:
		return _fail("debunking did not make Mert hunt for the source")
	if int(w.events.fired_total.get("rumor_source_confront", 0)) == 0:
		return _fail("Mert never confronted the person who spread it")
	# (b) a multi-stage story moves through several stages on its own
	var w2 := _world(104)
	_run_until(w2, 70.0)
	var uid := w2.director.start_arc("stolen_idea", {"thief": "deniz", "victim": "selin", "boss": "ahmet"}, {}, "", true)
	if uid == "":
		return _fail("stolen_idea did not start")
	var stages_seen := {}
	var guard := 0
	while guard < 6 and not w2.director.find(uid).is_empty():
		while not w2.day_over and not w2.director.find(uid).is_empty():
			w2.step(0.25)
			var inst := w2.director.find(uid)
			if not inst.is_empty():
				stages_seen[inst["stage"]] = true
		if not w2.director.find(uid).is_empty():
			w2.next_day()
		guard += 1
	var fin: Array = w2.director.finished.filter(func(x): return x["uid"] == uid)
	if fin.is_empty():
		return _fail("the story never concluded; stages seen %s" % [stages_seen.keys()])
	if int(fin[0]["steps"]) < 3:
		return _fail("story ended after only %d stage(s): %s" % [int(fin[0]["steps"]), fin[0]])
	return true


# ---------------------------------------------------------------------------- 4
func _test_memory_next_day() -> bool:
	var w := _world(105)
	_run_until(w, 200.0)
	# an argument that turns into a feud, with a revenge plan and a rumour
	w.change_rel("selin", "deniz", "friendship", -80.0)
	w.change_rel("deniz", "selin", "friendship", -80.0)
	w.change_rel("selin", "deniz", "rivalry", 40.0)
	w.npc("selin").traits["forgiveness"] = 0.1
	w.events.cooldowns.clear()
	# isolate the overnight check: a same-day revenge story could legitimately end the feud in a truce
	w.director.arc_last_end["revenge_plot"] = w.day
	var ok := false
	for i in 20:   # the event has a 70% chance condition
		if w.events.run_event("feud_begins", {"actor": "selin", "target": "deniz"}, {}):
			ok = true
			break
	if not ok:
		return _fail("feud_begins did not fire")
	w.npc("selin").remember("argued", "deniz", -0.7, 0.9, "mem.argued", {"target": "deniz"}, w.day, w.minute, 3)
	var rid := w.make_rumor("argument", "selin", "deniz", 0.6, true, "selin")
	w.learn("zeynep", rid, "mert")
	while not w.day_over:
		w.step(0.5)
	# what she believes at the end of the day (she may have heard more during it)
	var c0 := w.npc("zeynep").certainty(rid)
	var day0 := w.day
	w.next_day()
	var s: NPC = w.npc("selin")
	if not s.has_memory("argued", "deniz"):
		return _fail("Selin forgot the argument overnight")
	if not w.has_bond("selin", "deniz", "feud"):
		return _fail("the feud did not survive the night")
	if not s.has_plan("revenge", "deniz"):
		return _fail("Selin's revenge plan vanished overnight")
	if not w.npc("zeynep").knows(rid) or absf(w.npc("zeynep").certainty(rid) - c0) > 0.001:
		return _fail("Zeynep's (uncertain) knowledge did not carry over")
	var feud_arc: Array = w.director.arcs.filter(func(x): return x["arc"] == "feud_mediation")
	if feud_arc.is_empty():
		return _fail("no mediation story was waiting for the next day")
	if w.day != day0 + 1:
		return _fail("day did not advance")
	# and the grudge shows: they snub each other on the new day
	_run_until(w, 60.0)
	_wait_free(w, ["selin", "deniz"])
	if not w.events.run_event("feud_snub", {"actor": "selin", "target": "deniz"}, {}):
		return _fail("no cold shoulder between feuding colleagues the next day")
	return true


# ---------------------------------------------------------------------------- 5
func _test_relationships_drive_behaviour() -> bool:
	var w := _world(106)
	_run_until(w, 250.0)
	var tries := 0
	while tries < 400 and not (w.available("mert") and w.available("burak") and w.npc("burak").act != "meeting" and w.npc("mert").act != "meeting"):
		w.step(0.25)
		tries += 1
	# (a) whom Burak chooses to chat with (time is frozen while sampling)
	var picks_before := _count_partner(w, "burak", "mert", 300)
	w.set_bond("mert", "burak", "feud", true)
	w.change_rel("burak", "mert", "friendship", -120.0)
	var picks_after := _count_partner(w, "burak", "mert", 300)
	print("    Burak picks Mert to chat: %d/300 as friends, %d/300 while feuding" % [picks_before, picks_after])
	if picks_before == 0:
		return _fail("baseline: Burak never chose his friend Mert")
	if picks_after != 0:
		return _fail("Burak still seeks out Mert during a feud (%d/300)" % picks_after)
	# (b) the same encounter plays out differently: friends chat, enemies go cold
	w.set_bond("mert", "burak", "feud", false)
	w.change_rel("burak", "mert", "friendship", -150.0)
	w.change_rel("burak", "mert", "trust", -150.0)
	w.events.cooldowns.clear()
	_wait_free(w, ["mert", "burak"])
	var cold0 := int(w.events.outcome_total.get("small_talk/cold", 0))
	w.events.run_event("small_talk", {"actor": "mert", "target": "burak"}, {})
	if int(w.events.outcome_total.get("small_talk/cold", 0)) != cold0 + 1:
		return _fail("an enemy didn't give the cold shoulder")
	# (c) people help those they like more readily (refusal rate)
	var refuse_friend := _refusals(w, 80.0, 60)
	var refuse_enemy := _refusals(w, -80.0, 60)
	if refuse_enemy <= refuse_friend:
		return _fail("enemies refuse help no more often than friends (%d vs %d)" % [refuse_enemy, refuse_friend])
	return true


func _count_partner(w: SimWorld, who: String, other: String, n: int) -> int:
	var c := 0
	for i in n:
		if NPCBrain._chat_partner(w, w.npc(who)) == other:
			c += 1
	return c


func _refusals(w: SimWorld, feeling: float, n: int) -> int:
	var d: Dictionary = w.events.defs["help_request"]
	var c := 0
	for i in n:
		var t: NPC = w.npc("ceren")
		t.rel["ece"] = {"trust": feeling, "friendship": feeling, "rivalry": 0.0 if feeling > 0 else 60.0}
		var ctx := {"roles": {"actor": "ece", "target": "ceren"}, "vars": {}}
		var best := ""
		var bs := -1e9
		for o in d["outcomes"]:
			var s: float = w.events.ev.score(o.get("score", []), ctx) + w.rng.randf() * 0.35
			if s > bs:
				bs = s
				best = o["id"]
		if best == "refuses":
			c += 1
	return c


# ---------------------------------------------------------------------------- 6
func _test_save_load_story() -> bool:
	var w := _world(107)
	_run_until(w, 60.0)
	var uid := w.director.start_arc("missing_contract", {"owner": "zeynep", "culprit": "ece", "boss": "ahmet"}, {}, "", true)
	if uid == "":
		return _fail("story did not start")
	var guard := 0
	while guard < 4000 and w.director.find(uid).get("steps", []).size() < 2 and not w.director.find(uid).is_empty():
		w.step(0.25)
		guard += 1
	var inst := w.director.find(uid)
	if inst.is_empty():
		return _fail("story ended before it could be saved")
	var stage_before: String = inst["stage"]
	var steps_before: int = inst["steps"].size()
	var w_mem := w.npc("zeynep").memories.size()
	var snap := JSON.stringify(w.to_dict())
	var w2: SimWorld = Game.create_world()
	w2.from_dict(JSON.parse_string(snap))
	var inst2 := w2.director.find(uid)
	if inst2.is_empty():
		return _fail("story missing after load")
	if inst2["stage"] != stage_before or inst2["steps"].size() != steps_before or inst2["cast"] != inst["cast"]:
		return _fail("story state changed by save/load: %s vs %s" % [inst2["stage"], stage_before])
	if w2.npc("zeynep").memories.size() != w_mem:
		return _fail("memories lost in save/load")
	var snap2 := JSON.stringify(w2.to_dict())
	var w3: SimWorld = Game.create_world()
	w3.from_dict(JSON.parse_string(snap2))
	if JSON.stringify(w3.to_dict()) != snap2:
		return _fail("save/load is not idempotent")
	# keep playing the loaded game: the story must move on
	var days := 0
	while days < 3 and not w2.director.find(uid).is_empty():
		while not w2.day_over and not w2.director.find(uid).is_empty():
			w2.step(0.25)
		if not w2.director.find(uid).is_empty():
			w2.next_day()
		days += 1
	var fin: Array = w2.director.finished.filter(func(x): return x["uid"] == uid)
	var cur := w2.director.find(uid)
	if fin.is_empty() and (cur.is_empty() or cur["steps"].size() <= steps_before):
		return _fail("the loaded story never moved on")
	return true


# ---------------------------------------------------------------------------- 7
func _test_autonomous_days() -> bool:
	var w := _world(108)
	var per_day: Array = []
	var arcs_started := 0
	for d in 4:
		var fired0: Dictionary = w.events.fired_total.duplicate()
		var log0 := w.log_entries.size()
		var c0 := w.director.counter
		while not w.day_over:
			w.step(0.5)
		var distinct := 0
		for k in w.events.fired_total:
			if int(w.events.fired_total[k]) > int(fired0.get(k, 0)) and not (k in ["small_talk", "manager_check", "meeting_start", "meeting_present", "promo_reviewed_clean", "clique_lunch", "meeting_banter"]):
				distinct += 1
		per_day.append([distinct, w.log_entries.size() - log0, w.director.tiers.duplicate()])
		arcs_started += w.director.counter - c0
		if w.stats.get_count("interventions") != 0 or w.total_interventions != 0:
			return _fail("test bug: interventions recorded")
		w.next_day()
	for i in per_day.size():
		var p: Array = per_day[i]
		print("    day %d: %d different events, %d gossip-board notes, tiers %s" % [i + 1, p[0], p[1], JSON.stringify(p[2])])
		if int(p[0]) < 8:
			return _fail("day %d only had %d different events" % [i + 1, int(p[0])])
	if w.director.finished.is_empty() and w.director.arcs.is_empty():
		return _fail("no story started in 4 days")
	var deep := false
	for f in w.director.finished:
		if int(f["steps"]) >= 3:
			deep = true
	if not deep:
		return _fail("no story went through 3+ stages in 4 days")
	return true


# ---------------------------------------------------------------------------- 8
func _test_beliefs() -> bool:
	var w := _world(109)
	_run_until(w, 150.0)
	var f := w.make_rumor("getting_fired", "burak", "zeynep", 0.8, false, "zeynep")
	w.learn("zeynep", f, "", 0.9)
	w.change_rel("ece", "zeynep", "trust", -30.0)
	w.learn("ece", f, "zeynep")
	var ce := w.npc("ece").certainty(f)
	if ce >= 0.9 or ce <= 0.0:
		return _fail("hearsay should be uncertain, Ece is %.2f sure" % ce)
	w.learn("mert", f, "ece")
	if w.npc("mert").certainty(f) >= ce:
		return _fail("a retold rumour should be less certain (%.2f vs %.2f)" % [w.npc("mert").certainty(f), ce])
	var trust_before := w.npc("ece").get_rel("zeynep", "trust")
	w.debunk(f, ["ece"], "burak")
	if w.npc("ece").knows(f):
		return _fail("Ece still believes a debunked rumour")
	if w.npc("ece").get_rel("zeynep", "trust") >= trust_before:
		return _fail("debunking didn't cost the gossip any trust")
	# a gossip may twist a true story into a false one
	var arg := w.make_rumor("argument", "selin", "deniz", 0.5, true, "")
	var twisted := ""
	for i in 40:
		twisted = w.distort(arg, "zeynep", 1.0)
		if twisted != "":
			break
	if twisted == "" or w.fact_true(twisted) or w.dyn_facts[twisted]["kind"] != "fistfight":
		return _fail("Zeynep never exaggerated an argument into a fistfight")
	return true


# ---------------------------------------------------------------------------- 9
const CASTS := {
	"stolen_idea": {"thief": "deniz", "victim": "selin", "boss": "ahmet"},
	"office_romance": {"lover": "mert", "crush": "ceren"},
	"headhunted": {"seeker": "burak", "boss": "ahmet"},
	"resignation": {"quitter": "burak", "friend": "mert", "boss": "ahmet"},
	"missing_contract": {"owner": "zeynep", "culprit": "ece", "boss": "ahmet"},
	"deleted_folder": {"culprit": "ece", "it": "burak", "boss": "ahmet"},
	"layoff_panic": {"ear": "zeynep", "boss": "ahmet"},
	"secret_alliance": {"schemer": "deniz", "partner": "zeynep", "mark": "selin", "boss": "ahmet"},
	"birthday": {"organizer": "ceren", "bday": "mert"},
	"blame_game": {"boss": "ahmet", "culprit": "mert"},
	"mentor_protect": {"mentor": "selin", "protege": "ece", "boss": "ahmet"},
	"promotion_push": {"climber": "selin", "boss": "ahmet"},
	"revenge_plot": {"avenger": "selin", "victim": "deniz", "accomplice": "ceren"},
	"feud_mediation": {"a": "selin", "b": "deniz"},
	"boss_clash": {"rebel": "burak", "boss": "ahmet"},
	"niece_secret": {"niece": "ece", "boss": "ahmet"},
}


func _test_every_arc() -> bool:
	var deep := 0
	var lines: Array = []
	var i := 0
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("arc="):
			only = arg.substr(4)
	var w0 := _world(1)
	var all_ids: Array = w0.director.arc_defs.keys()
	var n_arcs := 0
	for arc_id in all_ids:
		if only != "" and arc_id != only:
			continue
		n_arcs += 1
		i += 1
		var cast: Dictionary = CASTS.get(arc_id, w0.director.arc_defs[arc_id].get("test", {}))
		if cast.is_empty():
			return _fail("%s has no test cast" % arc_id)
		var w := _world(300 + i)
		_run_until(w, 40.0)
		var uid := w.director.start_arc(arc_id, cast, {}, "", true)
		if uid == "":
			return _fail("%s did not start" % arc_id)
		var days := 0
		while days < 5 and not w.director.find(uid).is_empty():
			while not w.day_over and not w.director.find(uid).is_empty():
				w.step(0.5)
			if not w.director.find(uid).is_empty():
				w.next_day()
				days += 1
		var fin: Array = w.director.finished.filter(func(x): return x["uid"] == uid)
		if fin.is_empty():
			var inst := w.director.find(uid)
			return _fail("%s still stuck at stage %s after 5 days" % [arc_id, inst.get("stage", "?")])
		var steps := int(fin[0]["steps"])
		if steps >= 3:
			deep += 1
		lines.append("%s: %d stage(s) -> %s" % [arc_id, steps, fin[0]["result"]])
	print("    " + "\n    ".join(lines))
	print("    %d stories, %d went 3+ stages deep" % [n_arcs, deep])
	if deep < int(n_arcs * 0.7):
		return _fail("only %d of %d stories went 3+ stages deep" % [deep, n_arcs])
	return true
