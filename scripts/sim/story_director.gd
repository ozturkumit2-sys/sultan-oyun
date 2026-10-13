class_name StoryDirector
extends RefCounted
## StoryDirector: keeps the office alive without the player.
##  * Pacing — each day aims for a natural rhythm of small social moments,
##    a few medium incidents and one big story starting or moving forward.
##  * Initiative — characters start things themselves ("initiative" events):
##    who acts, and what they do, is scored from personality, goals, mood,
##    relationships, plans and memories.
##  * Story arcs — multi-stage chains that can span several days. Every stage
##    is an ordinary data event; its outcome decides the next stage, a detour
##    or the ending. Arc state is saved, so stories survive reloading.
##  * Meetups & gatherings — two (or more) people walk to the same corner of
##    the office and the scene plays when they are all there.

const MAX_ARCS := 4                 # stories running at the same time
const MAX_ARCS_PER_NPC := 2
const MAX_STARTS_PER_DAY := 2
const AREA_SPOTS := {
	"kitchen": ["hk1", "hk2", "hk3", "k4", "k1", "k2", "fridge"],
	"lounge": ["hl1", "hl2", "sofa1", "sofa2", "armchair"],
	"archive": ["ha1", "ha2", "archive"],
	"hall": ["hh1", "hh2", "w7"],
	"meeting": ["m2", "m6", "m3", "m7", "m4", "m8", "m5"],
	"boss": ["boss_guest", "boss_front"],
	"open": ["announce", "w0", "w1", "w2", "w3", "w4", "w5", "w6"],
}

var w  # SimWorld
var arc_defs: Dictionary = {}
var arcs: Array = []                # active story instances
var finished: Array = []            # recently concluded {uid, arc, result, day, cast, beat}
var arc_last_end: Dictionary = {}   # arc id -> day it last ended
var counter := 0
var starts_today := 0
var tiers: Dictionary = {}          # tier -> count today
var targets: Dictionary = {}        # tier -> today's natural target
var history: Dictionary = {}        # event id -> [days it fired] (novelty)
var meetups: Array = []
var initiative: Array = []          # event defs with trigger "initiative"
var _t_arc := 0.0
var _t_init := 0.0
var _running := ""                  # arc uid whose stage event is executing
var trace: Array = []               # recent story steps (debugging & tests; not saved)


func _trace(inst: Dictionary, what: String) -> void:
	trace.append("d%d %s %s/%s: %s" % [w.day, C.fmt(w.minute), inst["arc"], inst.get("stage", ""), what])
	if trace.size() > 400:
		trace.pop_front()


func _init(world) -> void:
	w = world


func load_arcs(defs: Array) -> void:
	arc_defs.clear()
	for a in defs:
		arc_defs[a["id"]] = a
	initiative.clear()
	for id in w.events.defs:
		var d: Dictionary = w.events.defs[id]
		var trigs = d.get("trigger", "")
		if typeof(trigs) != TYPE_ARRAY:
			trigs = [trigs]
		if "initiative" in trigs:
			initiative.append(d)


func reset() -> void:
	arcs.clear()
	finished.clear()
	arc_last_end.clear()
	counter = 0
	history.clear()
	meetups.clear()
	tiers.clear()


func new_day() -> void:
	tiers = {"small": 0, "medium": 0, "big": 0, "beat": 0}
	targets = {"small": w.rng.randi_range(5, 8), "medium": w.rng.randi_range(1, 3), "big": 1}
	starts_today = 0
	meetups.clear()
	_t_arc = 0.0
	_t_init = 0.0
	for inst in arcs:
		# yesterday's pending walk was interrupted by going home: re-issue today
		if inst["issued"]:
			inst["issued"] = false
			inst["stage_t0"] = -1.0
			inst["due"] = maxf(float(inst["due"]), w.abs_now() + 15.0)
	# forget very old history
	for k in history.keys():
		var days: Array = history[k]
		while not days.is_empty() and int(days[0]) < w.day - 4:
			days.pop_front()
		if days.is_empty():
			history.erase(k)


# =====================================================================
# Hooks from the event engine
# =====================================================================

func on_event_fired(d: Dictionary, ctx: Dictionary) -> void:
	var tier: String = d.get("tier", "")
	if tier != "":
		tiers[tier] = int(tiers.get(tier, 0)) + 1
	var id: String = d["id"]
	if not history.has(id):
		history[id] = []
	history[id].append(w.day)
	var uid: String = str(ctx.get("vars", {}).get("_arc", ""))
	if uid != "":
		_stage_ran(uid, d, ctx)


func fired_recently(id: String) -> int:
	var c := 0
	for dd in history.get(id, []):
		if int(dd) >= w.day - 1:
			c += 1
	return c


# =====================================================================
# Main tick
# =====================================================================

func tick(d: float) -> void:
	_check_meetups()
	_t_arc += d
	if _t_arc >= 2.0:
		_t_arc = 0.0
		_update_arcs()
	_t_init += d
	if _t_init >= 4.0:
		_t_init = 0.0
		_initiative()


# ---------------------------------------------------------------- pacing & initiative

## How much the day still "wants" of each tier right now.
func wants() -> Dictionary:
	var m: float = w.minute
	var frac: float = clampf((m - 20.0) / 470.0, 0.0, 1.0)
	var r := {}
	r["small"] = float(targets.get("small", 6)) * frac - float(tiers.get("small", 0))
	r["medium"] = float(targets.get("medium", 2)) * clampf((m - 60.0) / 400.0, 0.0, 1.0) - float(tiers.get("medium", 0))
	r["big"] = 1.0 if (int(tiers.get("big", 0)) == 0 and m > 50.0 and m < 430.0 and arcs.size() < MAX_ARCS and starts_today < MAX_STARTS_PER_DAY) else 0.0
	return r


func _initiative() -> void:
	var m: float = w.minute
	if m < 22.0 or m > 505.0 or initiative.is_empty():
		return
	# date-bound moments (a birthday) happen whatever the pacing says
	for d in initiative:
		if d.get("urgent", false) and w.events.day_ok(d):
			var best := ""
			var bs := -1e9
			for c in candidates_for(d):
				if float(c[0]) > bs:
					bs = float(c[0])
					best = c[2]
			if best != "" and w.events.try_initiative(d, best):
				return
	var wt := wants()
	var p: float = 0.02 + maxf(0.0, float(wt["small"])) * 0.22 + maxf(0.0, float(wt["medium"])) * 0.3 + float(wt["big"]) * 0.12
	if float(wt["small"]) < -1.0 and float(wt["medium"]) <= 0.0 and float(wt["big"]) <= 0.0:
		p = 0.01           # the office has had plenty going on — let it breathe
	if w.rng.randf() > p:
		return
	var order: Array = []
	if wt["big"] > 0.0 and w.rng.randf() < 0.45:
		order.append("big")
	if wt["medium"] > 0.35 and (wt["medium"] >= wt["small"] * 0.4 or w.rng.randf() < 0.4):
		order.append("medium")
	order.append("small")
	for tier in ["medium", "big", "small"]:
		if not order.has(tier):
			order.append(tier)
	for tier in order:
		if tier == "big" and wt["big"] <= 0.0:
			continue
		if _fire_initiative(tier):
			return


## Picks WHAT happens (fresh events are favoured, so days don't repeat), then WHO
## does it (the person with the strongest motive, from personality, goals, mood,
## relationships, plans and memories).
func _fire_initiative(tier: String) -> bool:
	var cands := candidates(tier)
	if cands.is_empty():
		return false
	# best motive per event
	var per_event := {}
	for c in cands:
		var id: String = c[1]["id"]
		if not per_event.has(id):
			per_event[id] = []
		per_event[id].append(c)
	var events: Array = per_event.keys()
	var tries := 0
	while not events.is_empty() and tries < 10:
		tries += 1
		var tot := 0.0
		var weights: Array = []
		for id in events:
			var wgt := _event_weight(per_event[id][0][1], per_event[id])
			weights.append(wgt)
			tot += wgt
		var r: float = w.rng.randf() * tot
		var k := 0
		for i in events.size():
			r -= float(weights[i])
			if r <= 0.0:
				k = i
				break
		var id2: String = events[k]
		events.remove_at(k)
		var actors: Array = per_event[id2]
		actors.sort_custom(func(a, b): return a[0] > b[0])
		for j in mini(2, actors.size()):
			if w.events.try_initiative(actors[j][1], actors[j][2]):
				return true
	return false


## How likely an event is to be picked today: its data weight, faded by how often
## it happened recently, nudged by how strongly the best candidate wants it.
func _event_weight(d: Dictionary, actors: Array) -> float:
	var best := 0.0
	for a in actors:
		best = maxf(best, float(a[0]))
	var recent := 0
	var horizon := 5 if d.get("tier", "small") == "big" else 2
	for dd in history.get(d["id"], []):
		if int(dd) >= w.day - horizon:
			recent += 1
	var wgt: float = float(d.get("weight", 1.0)) * pow(0.4, recent) * (0.55 + 0.45 * clampf(best / 3.0, 0.0, 1.5))
	if not history.has(d["id"]) and d.get("tier", "") == "big":
		wgt *= 1.6     # stories that haven't been told yet in this office
	return wgt


## [score, def, actor] for everyone who could plausibly start an event of this tier now.
func candidates(tier: String) -> Array:
	var out: Array = []
	for d in initiative:
		if d.get("tier", "small") != tier or d.get("urgent", false):
			continue
		if not w.events.day_ok(d):
			continue
		out.append_array(candidates_for(d))
	return out


## [score, def, actor] for everyone who could start this particular event right now.
func candidates_for(d: Dictionary) -> Array:
	var out: Array = []
	var ev: EventConditionEvaluator = w.events.ev
	var spec: Dictionary = {}
	for rs in d.get("roles", []):
		if rs["name"] == "actor":
			spec = rs
			break
	var novelty := -0.55 * fired_recently(d["id"])
	for id in w.present_ids():
		if not w.available(id):
			continue
		if not w.events.cool_ok(d, id):
			continue
		var sub := {"roles": {"self": id, "actor": id}, "vars": {}, "event": d["id"]}
		if not ev.all(spec.get("where", []), sub):
			continue
		var s: float = 1.0 + ev.score(spec.get("score", []), sub) + novelty + w.rng.randf() * 0.35
		out.append([s, d, id])
	return out


# =====================================================================
# Story arcs
# =====================================================================

## How many running stories this person plays a part in (the boss role doesn't count:
## Ahmet is in half the stories simply by being the boss).
func busy_count(id: String) -> int:
	var c := 0
	for inst in arcs:
		if inst["status"] != "active":
			continue
		for k in inst["cast"]:
			if k != "boss" and str(inst["cast"][k]) == id:
				c += 1
				break
	return c


func active_of(arc_id: String) -> int:
	var c := 0
	for inst in arcs:
		if inst["arc"] == arc_id and inst["status"] == "active":
			c += 1
	return c


func can_start(arc_id: String, cast: Dictionary) -> bool:
	var ad: Dictionary = arc_defs.get(arc_id, {})
	if ad.is_empty():
		return false
	if arcs.size() >= MAX_ARCS or starts_today >= MAX_STARTS_PER_DAY:
		return false
	if active_of(arc_id) >= int(ad.get("max_active", 1)):
		return false
	if arc_last_end.has(arc_id) and w.day - int(arc_last_end[arc_id]) < int(ad.get("cooldown_days", 3)):
		return false
	for k in cast:
		var id: String = str(cast[k])
		if k != "boss" and id != "" and busy_count(id) >= MAX_ARCS_PER_NPC:
			return false
	return true


func start_arc(arc_id: String, cast: Dictionary, vars: Dictionary = {}, stage := "", force := false) -> String:
	var ad: Dictionary = arc_defs.get(arc_id, {})
	if ad.is_empty():
		push_warning("Unknown arc " + arc_id)
		return ""
	if not force and not can_start(arc_id, cast):
		return ""
	counter += 1
	var uid := "s%d" % counter
	var st := stage if stage != "" else str(ad["first"])
	var inst := {
		"uid": uid, "arc": arc_id, "cast": cast.duplicate(), "vars": vars.duplicate(), "stage": st,
		"due": _first_due(ad["stages"][st]), "deadline": -1.0, "issued": false,
		"steps": [], "status": "active", "day0": w.day, "beat": "", "moved": false,
	}
	arcs.append(inst)
	starts_today += 1
	_trace(inst, "START " + str(cast))
	return uid


func find(uid: String) -> Dictionary:
	for inst in arcs:
		if inst["uid"] == uid:
			return inst
	return {}


func _wait_for(st: Dictionary, k := 1.0) -> float:
	var wt: Array = st.get("wait", [2, 10])
	return w.rng.randf_range(float(wt[0]), float(wt[1])) * k


func _first_due(st: Dictionary) -> float:
	if int(st.get("days", 0)) > 0:
		var win: Array = st.get("window", ["09:40", "16:30"])
		return float(w.day + int(st["days"])) * 10000.0 + C.hm(win[0]) + w.rng.randf_range(0.0, 50.0)
	return _norm_due(w.abs_now() + _wait_for(st))


## A time that falls after closing becomes "tomorrow morning".
func _norm_due(t: float) -> float:
	var d: float = floorf(t / 10000.0)
	var m: float = t - d * 10000.0
	if m > 515.0:
		return (d + 1.0) * 10000.0 + C.hm("09:35") + w.rng.randf_range(0.0, 40.0)
	return t


## Effect "arc_next": move a story on to another stage.
func arc_next(uid: String, stage: String, wait = null, days := 0) -> void:
	var inst := find(uid)
	if inst.is_empty() or inst["status"] != "active":
		return
	var ad: Dictionary = arc_defs[inst["arc"]]
	if not ad["stages"].has(stage):
		push_warning("arc %s has no stage %s" % [inst["arc"], stage])
		return
	inst["steps"].append(inst["stage"])
	inst["stage"] = stage
	inst["issued"] = false
	inst["moved"] = true
	inst["stage_t0"] = -1.0
	_trace(inst, "-> next")
	var st: Dictionary = ad["stages"][stage]
	if days > 0:
		var win: Array = st.get("window", ["09:40", "16:30"])
		inst["due"] = float(w.day + days) * 10000.0 + C.hm(win[0]) + w.rng.randf_range(0.0, 50.0)
	elif wait != null and typeof(wait) == TYPE_ARRAY:
		inst["due"] = _norm_due(w.abs_now() + w.rng.randf_range(float(wait[0]), float(wait[1])))
	else:
		inst["due"] = _norm_due(w.abs_now() + _wait_for(st))


## Effect "arc_end": the story is over (result is remembered as a world flag).
func arc_end(uid: String, result: String) -> void:
	var inst := find(uid)
	if inst.is_empty() or inst["status"] != "active":
		return
	inst["status"] = "done"
	inst["moved"] = true
	_trace(inst, "END " + result)
	inst["steps"].append(inst["stage"])
	arcs.erase(inst)
	arc_last_end[inst["arc"]] = w.day
	if result != "":
		w.flags["arc_%s_%s" % [inst["arc"], result]] = w.day
	w.flags["arc_%s_last" % inst["arc"]] = result
	finished.append({"uid": inst["uid"], "arc": inst["arc"], "result": result, "day": w.day, "cast": inst["cast"].duplicate(), "beat": inst.get("beat", ""), "steps": inst["steps"].size()})
	if finished.size() > 12:
		finished.pop_front()
	_cancel_intents(inst)


func _cancel_intents(inst: Dictionary) -> void:
	for id in inst["cast"].values():
		var n = w.npc(str(id))
		if n == null:
			continue
		for it in n.intents.duplicate():
			if str(it.get("vars", {}).get("_arc", "")) == inst["uid"]:
				n.intents.erase(it)


func _roles_for(inst: Dictionary) -> Dictionary:
	var r := {}
	for k in inst["cast"]:
		r[k] = inst["cast"][k]
	return r


func _vars_for(inst: Dictionary) -> Dictionary:
	var v: Dictionary = inst["vars"].duplicate(true)
	v["_arc"] = inst["uid"]
	return v


func _who(inst: Dictionary, ref) -> String:
	var s := str(ref)
	if s == "":
		return ""
	if s.begins_with("@"):
		return s.substr(1)
	if s.begins_with("$"):
		return str(inst["vars"].get(s.substr(1), ""))
	return str(inst["cast"].get(s, ""))


func _update_arcs() -> void:
	for inst in arcs.duplicate():
		if inst["status"] != "active":
			continue
		var ad: Dictionary = arc_defs[inst["arc"]]
		var st: Dictionary = ad["stages"][inst["stage"]]
		var now: float = w.abs_now()
		var ttl: float = float(st.get("ttl", 90.0))
		if inst["issued"]:
			if now > float(inst["deadline"]):
				_fail(inst, st)
			elif not _pending(inst, st):
				# the walk was interrupted (target busy, path blocked...): try again
				inst["issued"] = false
				inst["due"] = now + 2.0
			continue
		if now < float(inst["due"]):
			continue
		var win: Array = st.get("window", ["09:25", "17:20"])
		if w.minute < C.hm(win[0]):
			continue
		if w.minute > C.hm(win[1]):
			if now - float(inst["due"]) > ttl + 600.0:
				_fail(inst, st)
			continue
		var actor := _who(inst, st.get("actor", ""))
		var an = w.npc(actor)
		if an == null or not an.present or not w.available(actor):
			if now - float(inst["due"]) > ttl:
				_fail(inst, st)
			continue
		if not _issue(inst, st, actor):
			if now - float(inst["due"]) > ttl:
				_fail(inst, st)


## Starts the stage: either plays it right away or sends people walking.
func _issue(inst: Dictionary, st: Dictionary, actor: String) -> bool:
	var mode: String = st.get("mode", "now")
	var target := _who(inst, st.get("target", ""))
	var roles := _roles_for(inst)
	var vars := _vars_for(inst)
	var ttl := float(st.get("ttl", 90.0))
	var prio := float(st.get("prio", 62.0))
	var an = w.npc(actor)
	if target != "" and mode in ["visit", "meet"]:
		var tn = w.npc(target)
		if tn == null or not tn.present:
			return false
	inst["moved"] = false
	inst["await"] = st["event"]
	match mode:
		"now":
			_running = inst["uid"]
			var ok: bool = w.events.run_event(st["event"], roles, vars)
			_running = ""
			return ok
		"visit":
			an.add_intent({"type": "go_npc", "target": target, "event": st["event"], "prio": prio, "until": w.minute + ttl,
				"roles": roles, "vars": vars})
		"desk":
			an.add_intent({"type": "go_desk", "target": target, "event": st["event"], "prio": prio, "until": w.minute + ttl,
				"roles": roles, "vars": vars})
		"place":
			an.add_intent({"type": "go_place", "place": st.get("place", "announce"), "event": st["event"], "prio": prio,
				"until": w.minute + ttl, "dur": float(st.get("dur", 4.0)), "roles": roles, "vars": vars, "target": ""})
		"meet":
			if st.get("area", "") == "meeting" and _meeting_room_busy():
				return false
			if not meetup([actor, target], st.get("area", "kitchen"), st["event"], roles, vars, ttl, prio):
				return false
		"gather":
			var ids: Array = []
			if st.get("who", "all") == "all":
				for id in w.present_ids():
					if w.available(id) or id == actor:
						ids.append(id)
			else:
				for r in st["who"]:
					var id2 := _who(inst, r)
					if id2 != "" and w.npc(id2).present:
						ids.append(id2)
			if ids.size() < 2:
				return false
			var must: Array = []
			for r2 in st.get("must", []):
				var mid2 := _who(inst, r2)
				if mid2 != "":
					must.append(mid2)
					if not (mid2 in ids) and w.npc(mid2) != null and w.npc(mid2).present:
						ids.append(mid2)
			if not meetup(ids, st.get("area", "kitchen"), st["event"], roles, vars, ttl, prio, int(st.get("need", 3)), must):
				return false
		_:
			push_warning("unknown stage mode " + mode)
			return false
	inst["issued"] = true
	if float(inst.get("stage_t0", -1.0)) < 0.0:
		inst["stage_t0"] = w.abs_now()
	inst["deadline"] = float(inst["stage_t0"]) + ttl
	_trace(inst, "issued %s %s->%s" % [mode, actor, target])
	return true


## Is someone still on their way to play this stage?
func _pending(inst: Dictionary, st: Dictionary) -> bool:
	var uid: String = inst["uid"]
	for mu in meetups:
		if str(mu["vars"].get("_arc", "")) == uid:
			return true
	var actor := _who(inst, st.get("actor", ""))
	var n = w.npc(actor)
	if n == null or not n.present:
		return true    # out of the office for now; the deadline decides
	for it in n.intents:
		if str(it.get("vars", {}).get("_arc", "")) == uid:
			return true
	var cur: Dictionary = n.act_data.get("intent", {})
	if str(cur.get("vars", {}).get("_arc", "")) == uid and n.act != "":
		return true
	return false


func _meeting_room_busy() -> bool:
	var mt: Dictionary = w.meeting
	if mt.get("started", false) and not mt.get("ended", false):
		return true
	var t := float(mt.get("time", 120.0))
	return not mt.get("ended", false) and w.minute > t - 35.0 and w.minute < t + 40.0


func _fail(inst: Dictionary, st: Dictionary) -> void:
	_trace(inst, "FAIL -> " + str(st.get("fail", "")))
	_cancel_intents(inst)
	var f: String = st.get("fail", "end:fizzled")
	var ctx := {"roles": _roles_for(inst), "vars": _vars_for(inst)}
	if st.has("fail_log"):
		w.log_event(st["fail_log"], ctx, 2, "story", inst["cast"].values())
	if f.begins_with("end:"):
		arc_end(inst["uid"], f.substr(4))
	elif f.begins_with("retry"):
		inst["issued"] = false
		inst["due"] = float(w.day + 1) * 10000.0 + C.hm("09:50") + w.rng.randf_range(0, 60)
		inst["retries"] = int(inst.get("retries", 0)) + 1
		if int(inst["retries"]) > 2:
			arc_end(inst["uid"], "fizzled")
	else:
		arc_next(inst["uid"], f)


func _stage_ran(uid: String, d: Dictionary, ctx: Dictionary) -> void:
	var inst := find(uid)
	if inst.is_empty() or str(inst.get("await", "")) != d["id"]:
		return   # a side event chained from a stage — not the stage itself
	inst["await"] = ""
	# stories remember who got involved and what was decided along the way
	for r in ctx.get("roles", {}):
		var v: String = str(ctx["roles"][r])
		if r != "self" and v != "" and not inst["cast"].has(r):
			inst["cast"][r] = v
	for k in ctx.get("vars", {}):
		var vv = ctx["vars"][k]
		if str(k).begins_with("_") or k == "outcome" or k == "crowd":
			continue
		if typeof(vv) in [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL]:
			inst["vars"][k] = vv
	inst["vars"]["last_outcome"] = ctx.get("vars", {}).get("outcome", "")
	tiers["beat"] = int(tiers.get("beat", 0)) + 1
	if inst["status"] == "active" and not inst["moved"]:
		# a stage that doesn't say where the story goes next closes it
		var st: Dictionary = arc_defs[inst["arc"]]["stages"].get(inst["stage"], {})
		arc_end(uid, str(st.get("default_end", "done")))
	inst["moved"] = false


## Remembers the newest log line of a story (shown on the gossip board).
func on_logged(entry: Dictionary, ctx: Dictionary) -> void:
	var uid: String = str(ctx.get("vars", {}).get("_arc", ""))
	if uid == "":
		return
	entry["arc"] = uid
	var inst := find(uid)
	if not inst.is_empty():
		inst["beat"] = entry["text"]
	else:
		for f in finished:
			if f["uid"] == uid:
				f["beat"] = entry["text"]


# =====================================================================
# Meetups: people walk to the same corner, the scene plays when all arrive
# =====================================================================

func meetup(ids: Array, area: String, event: String, roles: Dictionary, vars: Dictionary, ttl: float, prio := 60.0, need := 0, must: Array = []) -> bool:
	var spots: Array = AREA_SPOTS.get(area, AREA_SPOTS["kitchen"]).duplicate()
	var o: OfficeEnv = w.office
	var free: Array = []
	for pid in spots:
		if o.places.has(pid) and (o.places[pid]["occupant"] == "" or o.places[pid]["occupant"] in ids):
			free.append(pid)
	var assign := {}
	if area == "boss" and "ahmet" in ids:
		assign["ahmet"] = "desk_ahmet"
	for id in ids:
		if assign.has(id):
			continue
		if free.is_empty():
			break
		assign[id] = free.pop_front()
	if assign.size() < mini(2, ids.size()):
		return false
	counter += 1
	var mid := "m%d" % counter
	var until: float = w.minute + ttl
	for id in assign:
		var n = w.npc(id)
		n.add_intent({"type": "go_place", "place": assign[id], "prio": prio + (4.0 if id != ids[0] else 0.0), "until": until,
			"dur": 16.0, "meetup": mid, "event": "", "target": "", "roles": {}, "vars": {"_arc": vars.get("_arc", "")}})
	meetups.append({"id": mid, "ids": assign.keys(), "places": assign, "event": event, "roles": roles, "vars": vars,
		"until": until, "arrived": [], "need": need if need > 0 else assign.size(), "first_at": -1.0, "must": must})
	return true


func meetup_arrived(mid: String, npc_id: String) -> void:
	for mu in meetups:
		if mu["id"] == mid and not (npc_id in mu["arrived"]):
			mu["arrived"].append(npc_id)
			if float(mu["first_at"]) < 0.0:
				mu["first_at"] = w.minute


func _at_spot(mu: Dictionary, id: String) -> bool:
	var n = w.npc(id)
	return n != null and n.present and n.act == "go_place" and n.phase == "do" and n.act_place == mu["places"].get(id, "")


func _check_meetups() -> void:
	if meetups.is_empty():
		return
	for mu in meetups.duplicate():
		var here: Array = []
		for id in mu["arrived"]:
			if _at_spot(mu, id):
				here.append(id)
		var need: int = mini(int(mu["need"]), mu["ids"].size())
		var waited: float = (w.minute - float(mu["first_at"])) if float(mu["first_at"]) >= 0.0 else 0.0
		var must_ok := true
		for m in mu.get("must", []):
			if not (m in here):
				must_ok = false
		var go := here.size() >= need and must_ok
		if not go and mu["ids"].size() > 2 and here.size() >= 2 and waited > (14.0 if not must_ok else 9.0):
			go = true    # a gathering starts with whoever showed up
		if go:
			meetups.erase(mu)
			var vars: Dictionary = mu["vars"].duplicate(true)
			vars["crowd"] = here.size()
			var uid: String = str(vars.get("_arc", ""))
			_running = uid
			w.events.run_event(mu["event"], mu["roles"], vars)
			_running = ""
			for id in here:
				var n = w.npc(id)
				# stay for the scene, then go back to normal life
				n.act_dur = n.act_t + 6.0
			continue
		if w.minute > float(mu["until"]) or (float(mu["first_at"]) >= 0.0 and waited > 15.0 and here.size() < need):
			meetups.erase(mu)
			for id in here:
				var n2 = w.npc(id)
				n2.act_dur = n2.act_t + 0.5
			if here.size() == 1 and mu["ids"].size() == 2:
				w.events.fire("stood_up", {"actor": here[0], "target": mu["ids"][1] if mu["ids"][0] == here[0] else mu["ids"][0]})


# =====================================================================
# Save / load
# =====================================================================

func to_dict() -> Dictionary:
	return {"arcs": arcs.duplicate(true), "finished": finished.duplicate(true), "arc_last_end": arc_last_end.duplicate(),
		"counter": counter, "starts_today": starts_today, "tiers": tiers.duplicate(), "targets": targets.duplicate(),
		"history": history.duplicate(true), "meetups": meetups.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	arcs = d.get("arcs", [])
	finished = d.get("finished", [])
	arc_last_end = d.get("arc_last_end", {})
	counter = int(d.get("counter", 0))
	starts_today = int(d.get("starts_today", 0))
	tiers = d.get("tiers", {"small": 0, "medium": 0, "big": 0, "beat": 0})
	targets = d.get("targets", {"small": 6, "medium": 2, "big": 1})
	history = d.get("history", {})
	meetups = d.get("meetups", [])
	# JSON turns ints into floats: normalise what we compare as ints
	for inst in arcs:
		inst["day0"] = int(inst.get("day0", 1))
	# intents were rebuilt from the save; pending walks are re-issued
	for inst in arcs:
		if inst["issued"]:
			var still := false
			for id in inst["cast"].values():
				var n = w.npc(str(id))
				if n == null:
					continue
				for it in n.intents:
					if str(it.get("vars", {}).get("_arc", "")) == inst["uid"]:
						still = true
			for mu in meetups:
				if str(mu["vars"].get("_arc", "")) == inst["uid"]:
					still = true
			if not still:
				inst["issued"] = false
