class_name SimWorld
extends RefCounted
## The whole office simulation (GameManager core + TimeManager + CharacterManager).
## Pure logic: it runs identically with or without graphics, which is how the
## headless tests exercise many in-game days.

signal said(npc_id: String, text: String, to_id: String)
signal logged(entry: Dictionary)
signal office_changed(what: String)
signal day_ended(summary: Dictionary)
signal fx(kind: String, data: Dictionary)
signal sfx(id: String)
signal secret_discovered(fact_id: String)

var rng := RandomNumberGenerator.new()
var seed_value := 0
var day := 1
var minute := 0.0
var npcs: Dictionary = {}
var order: Array = []
var office: OfficeEnv
var events: EventManager
var director: StoryDirector
var dialogue: DialogueManager
var stats := DayStats.new()
var char_defs: Dictionary = {}
var fact_defs: Dictionary = {}
var dyn_facts: Dictionary = {}       # runtime rumors {kind, a, b, juicy, day, truth, origin, spreaders}
var rumor_defs: Dictionary = {}      # rumor kind -> {on_learn, twist, life}
var bonds: Dictionary = {}           # "a|b|kind" -> {since, by}  (feud, alliance, romance, mentor)
var rumor_counter := 0
var flags: Dictionary = {}
var day_flags: Dictionary = {}
var log_entries: Array = []
var discovered: Dictionary = {}      # facts the player has learned about
var meeting: Dictionary = {}
var favor: Dictionary = {}           # Ahmet's promotion favour per person
var favor_ghost: Dictionary = {}     # part of favour caused by the player's meddling
var promo_cycle := 1
var day_over := false
var ghost_today := 0
var total_interventions := 0
var pair_cool: Dictionary = {}
var _enc_t := 0.0
var _tick_t := 0.0
var _deadline_t := 0.0
var lunch_fired := false
var tr_fn: Callable                  # (key, args) -> String, injected (Loc.t)


func _init() -> void:
	office = OfficeEnv.new()
	events = EventManager.new(self)
	director = StoryDirector.new(self)


## Load static data (characters, facts, events, dialogue).
func load_data(chars: Array, facts: Dictionary, event_defs: Array, dialogue_data: Dictionary, translate: Callable) -> void:
	tr_fn = translate
	char_defs.clear()
	for c in chars:
		char_defs[c["id"]] = c
	fact_defs = facts
	events.load_defs(event_defs)
	dialogue = DialogueManager.new(self, dialogue_data)
	director.load_arcs([])


## Story arcs and rumour kinds (data/arcs.json, data/rumors.json).
func load_story(arc_defs_in: Array, rumors: Dictionary) -> void:
	rumor_defs = rumors
	director.load_arcs(arc_defs_in)


func T(key: String, args: Dictionary = {}) -> String:
	if tr_fn.is_valid():
		return tr_fn.call(key, args)
	return key


# =====================================================================
# New game / days
# =====================================================================

func new_game(seed_in := 0) -> void:
	seed_value = seed_in if seed_in != 0 else int(Time.get_unix_time_from_system()) ^ randi()
	rng.seed = seed_value
	day = 1
	minute = 0.0
	npcs.clear()
	order.clear()
	dyn_facts.clear()
	flags.clear()
	log_entries.clear()
	discovered.clear()
	stats = DayStats.new()
	office.reset_objects()
	events.cooldowns.clear()
	events.fired_total.clear()
	director.reset()
	bonds.clear()
	rumor_counter = 0
	total_interventions = 0
	promo_cycle = 1
	for id in C.NPC_IDS:
		var n := NPC.new()
		n.setup(char_defs[id])
		_jitter_traits(n)
		npcs[id] = n
		order.append(id)
	# relationships with randomized starting values (replayability)
	for id in order:
		var n2: NPC = npcs[id]
		var rels: Dictionary = char_defs[id].get("relations", {})
		for other in order:
			if other == id:
				continue
			var base: Dictionary = rels.get(other, char_defs[id].get("default_rel", {"trust": 15, "friendship": 10, "rivalry": 3}))
			var tr := float(base.get("trust", 15)) + rng.randf_range(-12, 12)
			var fr := float(base.get("friendship", 10)) + rng.randf_range(-12, 12)
			var rv := float(base.get("rivalry", 3)) + rng.randf_range(-6, 8)
			n2.rel[other] = {"trust": clampf(tr, -100, 100), "friendship": clampf(fr, -100, 100), "rivalry": clampf(rv, 0, 100)}
		# personal goal
		var goals: Array = char_defs[id].get("goals", [])
		n2.goal = _weighted_pick(goals)
		n2.mood = rng.randf_range(5, 35)
		n2.stress = rng.randf_range(8, 25)
	# secrets: which exist this game, and who knows them
	for fid in fact_defs:
		var f: Dictionary = fact_defs[fid]
		if rng.randf() > float(f.get("chance", 1.0)):
			continue
		flags["fact_" + fid] = true
		for k in f.get("knowers", {}):
			if rng.randf() <= float(f["knowers"][k]):
				npcs[k].known[fid] = 0
	favor = {}
	favor_ghost = {}
	for id in order:
		favor[id] = 35.0 + rng.randf_range(-6, 6)
	favor["selin"] = 54.0 + rng.randf_range(-8, 8)
	favor["deniz"] = 50.0 + rng.randf_range(-8, 8)
	# a few birthdays fall into the next couple of weeks
	var bday_people: Array = order.duplicate()
	shuffle(bday_people)
	var bday_days: Array = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	shuffle(bday_days)
	for i in 3:
		flags["bday_" + bday_people[i]] = bday_days[i]
	begin_day(1)


## Overnight, feelings drift slightly back toward each person's baseline (they never reset).
func _heal_relations(n: NPC) -> void:
	var rels: Dictionary = char_defs[n.id].get("relations", {})
	var defb: Dictionary = char_defs[n.id].get("default_rel", {"trust": 15, "friendship": 10, "rivalry": 3})
	for other in n.rel:
		var base: Dictionary = rels.get(other, defb)
		var r: Dictionary = n.rel[other]
		var feud := has_bond(n.id, other, "feud")
		for st in ["trust", "friendship", "rivalry"]:
			if feud and st != "trust":
				continue   # people who aren't speaking don't drift back to normal
			r[st] = float(r[st]) + (float(base.get(st, 0)) - float(r[st])) * 0.07


func _jitter_traits(n: NPC) -> void:
	for k in n.traits:
		n.traits[k] = clampf(float(n.traits[k]) + rng.randf_range(-0.07, 0.07), 0.0, 1.0)


func _weighted_pick(opts: Array) -> String:
	if opts.is_empty():
		return ""
	var tot := 0.0
	for o in opts:
		tot += float(o.get("w", 1.0))
	var r := rng.randf() * tot
	for o in opts:
		r -= float(o.get("w", 1.0))
		if r <= 0.0:
			return o["id"]
	return opts[0]["id"]


func begin_day(d: int) -> void:
	day = d
	minute = 0.0
	day_over = false
	ghost_today = 0
	lunch_fired = false
	day_flags.clear()
	pair_cool.clear()
	stats.reset()
	events.new_day()
	director.new_day()
	for id in order:
		if int(flags.get("bday_" + id, -1)) == d:
			day_flags["birthday"] = id
	_enc_t = 0.0
	_tick_t = 0.0
	_deadline_t = 0.0
	# office state that resets overnight
	office.objects["lights"]["on"] = true
	office.objects["lights"]["fixing"] = ""
	office.objects["promo"]["reviewed"] = false
	for k in ["coffee", "printer"]:
		office.objects[k]["fixing"] = ""
	for pid in office.place_order:
		office.places[pid]["occupant"] = ""
	# meeting of the day
	var mt: float = [90.0, 120.0, 120.0, 150.0][rng.randi() % 4]
	office.objects["board"]["time"] = mt
	office.objects["board"]["changed"] = false
	meeting = {"time": mt, "attendees": ["ahmet", "selin", "deniz", "mert", "zeynep", "ceren", "ece"], "started": false, "start_min": -1.0, "ended": false, "presented": 0}
	if rng.randf() < 0.5:
		meeting["attendees"].append("burak")
	for id in order:
		var n: NPC = npcs[id]
		n.present = false
		n.state = NPC.S.OUTSIDE
		n.pos = OfficeEnv.OUTSIDE
		n.act = ""
		n.phase = ""
		n.path = PackedVector2Array()
		n.hold_until = -1.0
		n.intents.clear()
		n.today_flags.clear()
		n.lunch_done = false
		n.reviewed_today = false
		n.coffee_count = 0
		n.pending_notif = ""
		n.meeting_state = ""
		n.meeting_belief = mt if id in meeting["attendees"] else -1.0
		n.expr = "normal"
		n.emote = ""
		if d > 1:
			n.decay_memories()
			n.decay_plans()
			_heal_relations(n)
			# overnight: stress eases, mood drifts back toward neutral
			n.stress = n.stress * 0.55 + 6.0
			n.mood = n.mood * 0.6 + 8.0
			n.coffee_need = 25.0
		NPCSchedule.plan_day(self, n)
	# rumors fade after a few days (juicy ones live longer)
	for fid in dyn_facts.keys():
		var life := int(rumor_defs.get(dyn_facts[fid]["kind"], {}).get("life", 3))
		if day - int(dyn_facts[fid]["day"]) > life:
			dyn_facts.erase(fid)
			for id in order:
				npcs[id].known.erase(fid)
	events.fire("day_start", {})


func _end_day() -> void:
	if day_over:
		return
	day_over = true
	for id in order:
		var n: NPC = npcs[id]
		if n.present:
			n.present = false
			n.state = NPC.S.GONE
	_update_morale()
	var sm := stats.summary(day)
	sm["interventions"] = stats.get_count("interventions")
	sm["arcs"] = story_summary()
	stats.history.append(sm)
	if stats.history.size() > 30:
		stats.history.pop_front()
	events.fire("day_end", {})
	day_ended.emit(sm)


func next_day() -> void:
	begin_day(day + 1)


## Job satisfaction moves slowly: today's average mood plus the big moments.
func _update_morale() -> void:
	var weights := {"praised": 2.5, "scolded": -3.0, "boss_snapped": -2.0, "credit_stolen": -4.0, "lost_promo": -5.0,
		"falsely_accused": -3.0, "sabotaged_promo": -4.0, "helped_me": 1.2, "defended_me": 2.0, "made_up": 1.5,
		"party": 3.0, "humiliated": -3.0, "recognized": 4.0, "overworked": -2.5, "betrayed": -3.0}
	for id in order:
		var n: NPC = npcs[id]
		var avg := n.mood
		if n.mood_time > 1.0:
			avg = n.mood_acc / n.mood_time
		var dm := (avg - 28.0) * 0.1
		for m in n.memories:
			if int(m["day"]) == day:
				dm += float(weights.get(m["kind"], 0.0))
		n.morale = clampf(n.morale + dm, 0.0, 100.0)
		var base := float(n.def.get("morale", 60.0))
		n.morale += (base - n.morale) * 0.03
		n.mood_acc = 0.0
		n.mood_time = 0.0


## Active and recently finished stories (for the newspaper and the board).
func story_summary() -> Array:
	var r: Array = []
	for inst in director.arcs:
		r.append({"arc": inst["arc"], "beat": story_beat(inst), "done": false, "chapter": inst["steps"].size() + 1})
	for f in director.finished:
		if int(f["day"]) == day:
			r.append({"arc": f["arc"], "beat": story_beat(f), "done": true, "result": f["result"], "chapter": int(f.get("steps", 1))})
	return r


## The latest line of a story — or its teaser if nothing has happened yet.
func story_beat(inst: Dictionary) -> String:
	var b: String = str(inst.get("beat", ""))
	if b != "":
		return b
	return dialogue.format(T("arc.%s.teaser" % inst["arc"]), {"roles": inst.get("cast", {}), "vars": {}})


# =====================================================================
# Main loop
# =====================================================================

func step(dt: float) -> void:
	if day_over:
		return
	var remaining := dt
	while remaining > 0.0001 and not day_over:
		var d := minf(remaining, 0.5)
		remaining -= d
		_substep(d)


func _substep(d: float) -> void:
	minute += d
	MeetingFlow.update(self, d)
	for id in order:
		var n: NPC = npcs[id]
		_update_needs(n, d)
	for id in order:
		NPCController.update(self, npcs[id], d)
	events.tick()
	_enc_t += d
	if _enc_t >= 1.0:
		_enc_t = 0.0
		_encounters()
	_tick_t += d
	if _tick_t >= 12.0:
		_tick_t = 0.0
		_ambient_tick()
	director.tick(d)
	_deadline_t += d
	if _deadline_t >= 5.0:
		_deadline_t = 0.0
		_check_deadlines()
	_check_lights(d)
	if minute >= C.DAY_LEN:
		_end_day()


func abs_now() -> float:
	return day * 10000.0 + minute


func _update_needs(n: NPC, d: float) -> void:
	if not n.present:
		return
	n.mood_acc += n.mood * d
	n.mood_time += d
	n.coffee_need = minf(100.0, n.coffee_need + d * 0.22 * (0.4 + float(n.prefs.get("coffee", 0.5))))
	n.social_need = minf(100.0, n.social_need + d * 0.16 * (0.3 + n.t("sociability")))
	# temperature comfort
	var disc := discomfort(n)
	var dark: bool = not office.objects["lights"]["on"]
	var ds := 0.0
	ds += disc * 0.0016
	if dark:
		ds += 0.05
	if n.coffee_need > 75.0:
		ds += 0.015
	if n.act in ["rest", "lunch", "coffee", "water", "chat"] and n.phase == "do":
		ds -= 0.09
	elif n.act == "work" and n.work_left() > 0.0:
		ds += 0.01
	else:
		ds -= 0.02
	n.stress = clampf(n.stress + ds * d * 10.0 * 0.1, 0.0, 100.0)
	# mood drifts toward a baseline set by stress
	var base := 22.0 - n.stress * 0.45 - disc * 0.15
	n.mood = C.clampf100(n.mood + (base - n.mood) * 0.006 * d)


func discomfort(n: NPC) -> float:
	var temp := float(office.objects["ac"]["temp"])
	var pref := float(n.prefs.get("temp", 22))
	return maxf(0.0, absf(temp - pref) - 3.0) * 8.0


# =====================================================================
# Queries
# =====================================================================

func npc(id: String) -> NPC:
	return npcs.get(id, null)


func present_ids() -> Array:
	var r: Array = []
	for id in order:
		if npcs[id].present:
			r.append(id)
	return r


func available(id: String) -> bool:
	var n := npc(id)
	if n == null or not n.present:
		return false
	if n.hold_until > minute:
		return false
	if n.act in ["leave", "arrive"]:
		return false
	return true


func dist(a: String, b: String) -> float:
	var na := npc(a)
	var nb := npc(b)
	if na == null or nb == null or not na.present or not nb.present:
		return 999.0
	return na.pos.distance_to(nb.pos)


func zone_of(n: NPC) -> String:
	return OfficeLayout.zone_of(OfficeEnv.cell_of(n.pos))


func shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func fact_exists(f: String) -> bool:
	return flags.get("fact_" + f, false) or dyn_facts.has(f)


func fact_true(f: String) -> bool:
	if dyn_facts.has(f):
		return bool(dyn_facts[f].get("truth", true))
	return fact_defs.has(f)


func fact_subject(f: String) -> String:
	if fact_defs.has(f):
		return fact_defs[f].get("subject", "")
	if dyn_facts.has(f):
		return dyn_facts[f].get("a", "")
	return ""


func fact_text(f: String) -> String:
	if fact_defs.has(f):
		return T("fact." + f)
	if dyn_facts.has(f):
		var r: Dictionary = dyn_facts[f]
		return T("rumor." + r["kind"], {"a": _nm(r["a"]), "b": _nm(r["b"])})
	return ""


func _nm(id: String) -> String:
	var n := npc(id)
	return n.name if n else ""


func display_var(k: String, v) -> String:
	match k:
		"item":
			return T("item." + str(v))
		"obj":
			return T("obj." + str(v))
		"gossip", "fact", "rumor":
			return fact_text(str(v))
		"time", "old_time", "new_time":
			return C.fmt(float(v))
		"temp":
			return "%d°C" % int(v)
		"topic":
			return T("topic." + str(v))
		"task":
			return T("task." + str(v))
		"loc":
			return T("loc." + str(v))
	if typeof(v) == TYPE_STRING and npcs.has(v):
		return npcs[v].name
	if typeof(v) == TYPE_STRING and (fact_defs.has(v) or dyn_facts.has(v)):
		return fact_text(str(v))
	return str(v)


func office_mood() -> float:
	var s := 0.0
	var c := 0
	for id in order:
		s += npcs[id].mood
		c += 1
	return s / maxf(1.0, c)


# =====================================================================
# Mutations used by events
# =====================================================================

func say(id: String, key: String, ctx: Dictionary, to := "") -> void:
	var n := npc(id)
	if n == null or not n.present:
		return
	var tmpl := dialogue.pick(key, id)
	if tmpl == "":
		return
	var text := dialogue.format(tmpl, ctx, id, to)
	n.speaking = 2.4
	if to != "":
		face_toward(n, to)
	# overhearing a line that names a secret means the player learns it too
	var g = ctx.get("vars", {}).get("gossip", "")
	if g != "" and tmpl.find("{gossip}") >= 0:
		reveal(str(g))
	said.emit(id, text, to)


func say_text(id: String, text: String, to := "") -> void:
	var n := npc(id)
	if n == null or not n.present:
		return
	n.speaking = 2.4
	said.emit(id, text, to)


func face_toward(n: NPC, other_id: String) -> void:
	var o := npc(other_id)
	if o == null or n.pose in ["sit", "type", "eat"]:
		return
	var dv := o.pos - n.pos
	var sx := dv.x - dv.y
	var sy := dv.x + dv.y
	if absf(sx) > 0.05:
		n.face_right = sx > 0.0
	n.face_front = sy >= -0.05


func change_rel(a: String, b: String, stat: String, d: float) -> void:
	var na := npc(a)
	if na == null or b == "" or a == b:
		return
	var before := na.get_rel(b, "friendship")
	var nb := npc(b)
	var before_back: float = nb.get_rel(a, "friendship") if nb else 0.0
	na.change_rel(b, stat, d)
	if stat == "friendship":
		var after := na.get_rel(b, "friendship")
		var fk := "friends|" + (a + "|" + b if a < b else b + "|" + a)
		# a "new friendship" = both now like each other well, and this crossed the line
		# (announced once per pair; it can be announced again only after they fell out)
		if before < 45.0 and after >= 45.0 and before_back >= 35.0 and not flags.get(fk, false):
			flags[fk] = true
			stats.add("new_friendships")
			log_event("log.new_friends", {"roles": {"actor": a, "target": b}}, 2, "friendship", [a, b])
		elif after < 15.0 and flags.get(fk, false):
			flags.erase(fk)


func remember(id: String, kind: String, about: String, val: float, wgt: float, text: String, ctx: Dictionary, imp := 1) -> void:
	var n := npc(id)
	if n == null:
		return
	var args := {}
	for r in ctx.get("roles", {}):
		args[r] = ctx["roles"][r]
	for v in ctx.get("vars", {}):
		var vv = ctx["vars"][v]
		if typeof(vv) in [TYPE_STRING, TYPE_INT, TYPE_FLOAT]:
			args[v] = vv
	n.remember(kind, about, val, wgt, text, args, day, minute, imp)


## Renders a stored memory line for the character file panel.
func memory_text(m: Dictionary) -> String:
	if m.get("text", "") == "":
		return ""
	var args: Dictionary = m.get("args", {})
	var named := {}
	for k in args:
		named[k] = display_var(k, args[k])
	return T(m["text"], named)


## Someone learns a fact. First-hand (no `from`) means certainty 1; hearsay is
## only as believable as the teller — and gets shakier every retelling.
func learn(id: String, fact: String, from := "", cert := -1.0) -> void:
	var n := npc(id)
	if n == null or not fact_exists(fact):
		return
	var c := cert
	if c < 0.0:
		if from == "" or from == id:
			c = 1.0
		else:
			var tl := npc(from)
			var tc := tl.certainty(fact) if tl else 0.6
			if tc <= 0.0:
				tc = 0.6
			c = clampf(tc * (0.6 + n.get_rel(from, "trust") / 250.0), 0.15, 0.95)
	if n.knows(fact):
		# hearing it again from someone else makes it more believable
		var old := n.certainty(fact)
		n.belief[fact] = clampf(1.0 - (1.0 - old) * (1.0 - c * 0.6), 0.0, 1.0)
		return
	n.known[fact] = day
	n.belief[fact] = c
	var subj := fact_subject(fact)
	if dyn_facts.has(fact) and from != "" and from != id:
		var sp: Array = dyn_facts[fact].get("spreaders", [])
		if not sp.has(from):
			sp.append(from)
		dyn_facts[fact]["spreaders"] = sp
	# data-driven reactions to learning a fact (weaker when it's just a rumour)
	var k := lerpf(0.45, 1.0, c)
	var fd: Dictionary = fact_defs.get(fact, {})
	if dyn_facts.has(fact):
		fd = _rumor_def(dyn_facts[fact])
	for eff in fd.get("on_learn", []):
		var who_ok := false
		var wsel: String = eff.get("who", "*")
		if wsel == "*":
			who_ok = id != subj
		elif wsel == "subject":
			who_ok = id == subj
		elif wsel.begins_with("@"):
			who_ok = id == wsel.substr(1)
		elif wsel == "b":
			who_ok = dyn_facts.has(fact) and id == dyn_facts[fact]["b"]
		if not who_ok:
			continue
		var about: String = subj
		if eff.get("about", "subject") == "b" and dyn_facts.has(fact):
			about = dyn_facts[fact]["b"]
		elif eff.get("about", "subject") == "a" and dyn_facts.has(fact):
			about = dyn_facts[fact]["a"]
		elif eff.get("about", "subject").begins_with("@"):
			about = eff["about"].substr(1)
		if eff.has("stat") and about != id:
			n.change_rel(about, eff["stat"], float(eff["d"]) * k)
		if eff.has("mood"):
			n.mood = C.clampf100(n.mood + float(eff["mood"]) * k)
		if eff.has("stress"):
			n.stress = clampf(n.stress + float(eff["stress"]) * k, 0, 100)
		if eff.has("favor"):
			favor[about] = clampf(float(favor.get(about, 40.0)) + float(eff["favor"]) * k, 0, 100)
	if from != "" and from != id:
		n.remember("heard", from, 0.05, 0.3, "", {}, day, minute)
	events.fire("fact_learned", {"actor": id, "fact": fact, "subject": subj})


## A false rumour is exposed: the listed people stop believing it and stop
## trusting whoever passed it around.
func debunk(fact: String, hearers: Array, by := "") -> void:
	if not dyn_facts.has(fact) or bool(dyn_facts[fact].get("truth", true)):
		return
	var r: Dictionary = dyn_facts[fact]
	if not r.get("debunked", false):
		stats.add("debunked")
	r["debunked"] = true
	var liars: Array = r.get("spreaders", []).duplicate()
	if r.get("origin", "") != "" and not liars.has(r["origin"]):
		liars.append(r["origin"])
	for id in hearers:
		var n := npc(id)
		if n == null:
			continue
		n.forget_fact(fact)
		for s2 in liars:
			if s2 != id and s2 != by:
				n.change_rel(s2, "trust", -6.0)


## A gossip "improves" a rumour while retelling it. Returns the new (false) rumour or "".
func distort(fact: String, teller: String, p := 1.0) -> String:
	if not dyn_facts.has(fact):
		return ""
	var r: Dictionary = dyn_facts[fact]
	var tw: String = rumor_defs.get(r["kind"], {}).get("twist", "")
	var n := npc(teller)
	if tw == "" or n == null:
		return ""
	var chance := p * (n.t("gossip") * 0.55 + (1.0 - n.t("honesty")) * 0.45 - 0.2)
	if rng.randf() > chance:
		return ""
	var nf := make_rumor(tw, r["a"], r["b"], minf(1.0, float(r.get("juicy", 0.5)) + 0.2), false, teller)
	n.known[nf] = day
	n.belief[nf] = 0.9
	return nf


func _rumor_def(r: Dictionary) -> Dictionary:
	if rumor_defs.has(r["kind"]):
		return rumor_defs[r["kind"]]
	var kinds: Dictionary = {
		"argument": [{"who": "*", "about": "a", "stat": "trust", "d": -2}],
		"refused_help": [{"who": "*", "about": "a", "stat": "friendship", "d": -4}],
		"scolded": [],
		"late": [],
		"blamed": [{"who": "*", "about": "a", "stat": "trust", "d": -3}],
		"credit_steal": [{"who": "*", "about": "a", "stat": "trust", "d": -8}, {"who": "b", "about": "a", "stat": "rivalry", "d": 22}, {"who": "b", "about": "a", "stat": "trust", "d": -25}, {"who": "@ahmet", "about": "a", "favor": -10}],
		"dislikes": [{"who": "b", "about": "a", "stat": "friendship", "d": -22}, {"who": "b", "about": "a", "stat": "trust", "d": -15}],
		"scheme": [{"who": "*", "about": "a", "stat": "trust", "d": -10}, {"who": "b", "about": "a", "stat": "rivalry", "d": 25}, {"who": "@ahmet", "about": "a", "favor": -18}],
		"secret_friends": [],
		"took_blame": [{"who": "*", "about": "a", "stat": "friendship", "d": 4}],
		"helped": [{"who": "*", "about": "a", "stat": "friendship", "d": 3}],
		"haunted": [],
		"couple": [],
	}
	return {"on_learn": kinds.get(r["kind"], [])}


func reveal(fact: String) -> void:
	if fact == "" or discovered.has(fact) or not fact_exists(fact):
		return
	discovered[fact] = day
	if fact_defs.has(fact) and fact_defs[fact].get("secret", false):
		stats.add("secrets_revealed")
		secret_discovered.emit(fact)


func make_rumor(kind: String, a: String, b: String, juicy: float, truth := true, origin := "") -> String:
	# reuse an identical rumor from today
	for fid in dyn_facts:
		var r: Dictionary = dyn_facts[fid]
		if r["kind"] == kind and r["a"] == a and r["b"] == b and int(r["day"]) == day and bool(r.get("truth", true)) == truth:
			return fid
	rumor_counter += 1
	var fid2 := "r%d" % rumor_counter
	dyn_facts[fid2] = {"kind": kind, "a": a, "b": b, "juicy": juicy, "day": day, "truth": truth, "origin": origin, "spreaders": []}
	return fid2


# =====================================================================
# Bonds: lasting states between two people (feud, alliance, romance, mentor)
# =====================================================================

static func _bk(a: String, b: String, kind: String) -> String:
	if a > b:
		return "%s|%s|%s" % [b, a, kind]
	return "%s|%s|%s" % [a, b, kind]


func has_bond(a: String, b: String, kind: String) -> bool:
	if a == "" or b == "" or a == b:
		return false
	return bonds.has(_bk(a, b, kind))


func set_bond(a: String, b: String, kind: String, on: bool, by := "") -> void:
	if a == "" or b == "" or a == b:
		return
	var k := _bk(a, b, kind)
	if on:
		if not bonds.has(k):
			bonds[k] = {"since": day, "by": by}
	else:
		bonds.erase(k)


func bonds_of(id: String, kind: String) -> Array:
	var r: Array = []
	for k in bonds:
		var p: PackedStringArray = k.split("|")
		if p[2] != kind:
			continue
		if p[0] == id:
			r.append(p[1])
		elif p[1] == id:
			r.append(p[0])
	return r


func fact_juice(f: String) -> float:
	if fact_defs.has(f):
		return float(fact_defs[f].get("juicy", 0.5))
	if dyn_facts.has(f):
		return float(dyn_facts[f].get("juicy", 0.4))
	return 0.0


func log_event(key: String, ctx: Dictionary, imp: int, cat: String, actors: Array) -> void:
	var text := dialogue.format(T(key), ctx)
	var entry := {"day": day, "minute": minute, "text": text, "imp": imp, "cat": cat, "actors": actors}
	director.on_logged(entry, ctx)
	log_entries.append(entry)
	if log_entries.size() > 260:
		log_entries.pop_front()
	if imp >= 2:
		stats.note(entry)
	logged.emit(entry)


func hold(ids: Array, dur: float) -> void:
	for id in ids:
		var n := npc(id)
		if n == null or not n.present:
			continue
		n.hold_until = maxf(n.hold_until, minute + dur)
		if n.pose == "walk":
			n.pose = "stand"
	if ids.size() >= 2:
		var a := npc(ids[0])
		if a:
			face_toward(a, ids[1])
		for i in range(1, ids.size()):
			var b := npc(ids[i])
			if b:
				face_toward(b, ids[0])


func on_argument(a: String, b: String) -> void:
	day_flags["last_argument_at"] = minute
	events.fire("argument", {"actor": a, "target": b})


func add_work(id: String, d: float) -> void:
	var n := npc(id)
	if n == null:
		return
	var tk := n.current_task()
	if tk.is_empty():
		return
	tk["left"] = clampf(float(tk["left"]) - d, 0.0, float(tk["total"]))


func force_activity(id: String, act: String, opts: Dictionary) -> void:
	var n := npc(id)
	if n == null or not n.present:
		return
	var spec := {"act": act, "prio": 70.0}
	for k in opts:
		spec[k] = opts[k]
	match act:
		"fix":
			spec["place"] = {"printer": "printer", "coffee": "coffee", "lights": "breaker"}.get(opts.get("obj", ""), "printer")
		"thermostat":
			spec["place"] = "thermostat"
		"away":
			spec["place"] = "entrance"
	NPCController.start(self, n, spec)


func on_event_fired(d: Dictionary, ctx: Dictionary) -> void:
	director.on_event_fired(d, ctx)


func pick_var(fn: String, spec: Dictionary, ctx: Dictionary):
	return WorldSpecials.pick(self, fn, spec, ctx)


func special(fn: String, e: Dictionary, ctx: Dictionary) -> void:
	WorldSpecials.run(self, fn, e, ctx)


# =====================================================================
# Periodic checks
# =====================================================================

func _encounters() -> void:
	var ids := present_ids()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: NPC = npcs[ids[i]]
			var b: NPC = npcs[ids[j]]
			var key: String = ids[i] + "|" + ids[j]
			if float(pair_cool.get(key, -1.0)) > minute:
				continue
			if a.hold_until > minute or b.hold_until > minute:
				continue
			var d := a.pos.distance_to(b.pos)
			var social_a := NPCController.is_social(a)
			var social_b := NPCController.is_social(b)
			if d < 1.7 and (social_a or social_b) and (social_a or b.phase == "walk") and (social_b or a.phase == "walk"):
				if a.act == "meeting" and meeting.get("started", false) and not meeting.get("ended", false):
					continue
				var p := 0.12 + 0.2 * (a.t("sociability") + b.t("sociability")) * 0.5
				if rng.randf() < p:
					var init: NPC = a
					var other: NPC = b
					if b.t("sociability") + b.t("gossip") * 0.5 + rng.randf() * 0.4 > a.t("sociability") + a.t("gossip") * 0.5 + rng.randf() * 0.4:
						init = b
						other = a
					var fired := events.fire("encounter", {"actor": init.id, "target": other.id})
					pair_cool[key] = minute + (34.0 if fired else 8.0)
				else:
					pair_cool[key] = minute + 4.0
			elif d < 3.4 and a.act == "work" and b.act == "work" and a.phase == "do" and b.phase == "do":
				if rng.randf() < 0.035:
					var init2: NPC = a if rng.randf() < 0.5 else b
					var other2: NPC = b if init2 == a else a
					var fired2 := events.fire("desk_chat", {"actor": init2.id, "target": other2.id})
					pair_cool[key] = minute + (35.0 if fired2 else 10.0)


func _ambient_tick() -> void:
	events.fire("tick", {})
	# the most uncomfortable person may complain about the temperature
	var worst := ""
	var wv := 22.0
	for id in present_ids():
		var dsc := discomfort(npcs[id])
		if dsc > wv and available(id):
			wv = dsc
			worst = id
	if worst != "" and rng.randf() < 0.6:
		events.fire("thermo_discomfort", {"actor": worst})
	# the most stressed person may vent
	var ms := ""
	var mv := 62.0
	for id in present_ids():
		if npcs[id].stress > mv and available(id):
			mv = npcs[id].stress
			ms = id
	if ms != "":
		events.fire("stressed", {"actor": ms})
	# forget stale "someone is fixing it" claims
	for k in ["coffee", "printer", "lights"]:
		var fx_id: String = office.objects[k].get("fixing", "")
		if fx_id == "":
			continue
		var fn := npc(fx_id)
		var busy := false
		if fn != null and fn.present:
			if fn.act == "fix":
				busy = true
			for it in fn.intents:
				if it.get("type", "") == "fix":
					busy = true
		if not busy:
			office.objects[k]["fixing"] = ""



func _check_deadlines() -> void:
	for id in present_ids():
		var n: NPC = npcs[id]
		for tk in n.tasks:
			if tk["left"] <= 0.0 or tk.get("missed", false):
				continue
			var dl := NPCSchedule.task_deadline(self, n, tk)
			if minute > dl:
				tk["missed"] = true
				events.fire("task_missed", {"actor": id, "task": tk["id"]})
			elif minute > dl - 50.0 and tk["left"] > 22.0 and not tk.get("crunch", false):
				tk["crunch"] = true
				events.fire("deadline_near", {"actor": id, "task": tk["id"]})


var _dark_t := 0.0


func _check_lights(d: float) -> void:
	var L: Dictionary = office.objects["lights"]
	if L["on"]:
		return
	_dark_t += d
	if _dark_t > 2.0:
		_dark_t = 0.0
		var ids := present_ids()
		shuffle(ids)
		var done := false
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				if not done and dist(ids[i], ids[j]) < 2.6:
					done = events.fire("dark_pair", {"actor": ids[i], "target": ids[j]})
	# safety net: if nobody is fixing it after a while, someone heads to the breaker
	if L.get("fixing", "") == "" and minute - float(L.get("off_at", minute)) > 14.0:
		for id in ["burak", "ceren", "ahmet", "ece", "mert", "selin", "zeynep", "deniz"]:
			if available(id):
				L["fixing"] = id
				force_activity(id, "fix", {"obj": "lights"})
				break


# =====================================================================
# Save / load
# =====================================================================

func to_dict() -> Dictionary:
	var n := {}
	for id in order:
		n[id] = npcs[id].to_dict()
	return {
		"version": C.SAVE_VERSION, "seed": seed_value, "day": day, "minute": minute,
		"npcs": n, "office": office.to_dict(), "events": events.to_dict(), "stats": stats.to_dict(),
		"director": director.to_dict(), "bonds": bonds.duplicate(true),
		"dyn_facts": dyn_facts.duplicate(true), "rumor_counter": rumor_counter, "flags": flags.duplicate(true),
		"day_flags": day_flags.duplicate(true), "log": log_entries.duplicate(true), "discovered": discovered.duplicate(),
		"meeting": meeting.duplicate(true), "favor": favor.duplicate(), "favor_ghost": favor_ghost.duplicate(),
		"promo_cycle": promo_cycle, "ghost_today": ghost_today, "total_interventions": total_interventions,
		"lunch_fired": lunch_fired, "day_over": day_over, "rng_state": rng.state,
	}


func from_dict(d: Dictionary) -> void:
	seed_value = int(d.get("seed", 1))
	rng.seed = seed_value
	if d.has("rng_state"):
		rng.state = int(d["rng_state"])
	day = int(d.get("day", 1))
	minute = float(d.get("minute", 0.0))
	npcs.clear()
	order.clear()
	for id in C.NPC_IDS:
		var n := NPC.new()
		n.setup(char_defs[id])
		var nd: Dictionary = d.get("npcs", {}).get(id, {})
		n.from_dict(nd)
		npcs[id] = n
		order.append(id)
	office.from_dict(d.get("office", {}))
	events.from_dict(d.get("events", {}))
	stats.from_dict(d.get("stats", {}))
	dyn_facts = d.get("dyn_facts", {})
	bonds = d.get("bonds", {})
	rumor_counter = int(d.get("rumor_counter", 0))
	flags = d.get("flags", {})
	day_flags = d.get("day_flags", {})
	log_entries = d.get("log", [])
	discovered = d.get("discovered", {})
	meeting = d.get("meeting", {})
	favor = d.get("favor", {})
	favor_ghost = d.get("favor_ghost", {})
	promo_cycle = int(d.get("promo_cycle", 1))
	ghost_today = int(d.get("ghost_today", 0))
	total_interventions = int(d.get("total_interventions", 0))
	lunch_fired = d.get("lunch_fired", false)
	day_over = d.get("day_over", false)
	director.from_dict(d.get("director", {}))
	# people in the office resume from where they stood
	for id in order:
		var n2: NPC = npcs[id]
		if n2.present:
			var c := OfficeEnv.cell_of(n2.pos)
			if not office.walkable(c):
				n2.pos = Vector2(office.nearest_walkable(c)) + Vector2(0.5, 0.5)
			n2.state = NPC.S.ACTING
			n2.pose = "stand"
