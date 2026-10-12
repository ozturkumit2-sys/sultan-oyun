class_name EventManager
extends RefCounted
## EventManager: data-driven event engine.
## Each event definition has a trigger, filters, conditions, role selection,
## priority, cooldowns, delays and branching outcomes (see data/events.json).

const ROLE_NAMES := ["actor", "target", "helper", "other", "self", "boss", "victim", "credited", "winner", "loser",
	"subject", "sender", "owner", "defender", "fixer", "requester", "listener", "joker", "crush", "spotter", "speaker"]

var w  # SimWorld
var ev: EventConditionEvaluator
var res: EventConsequenceResolver
var defs: Dictionary = {}           # id -> def
var by_trigger: Dictionary = {}     # trigger -> [defs sorted by priority desc]
var queue: Array = []               # {at, effects, ctx}
var cooldowns: Dictionary = {}      # key -> abs time when ready
var day_counts: Dictionary = {}     # event id -> count today
var fired_total: Dictionary = {}    # event id -> count ever (for tests/diagnostics)


func _init(world) -> void:
	w = world
	ev = EventConditionEvaluator.new(world)
	res = EventConsequenceResolver.new(world, ev)


func load_defs(arr: Array) -> void:
	defs.clear()
	by_trigger.clear()
	for d in arr:
		defs[d["id"]] = d
		var trigs = d.get("trigger", "")
		if typeof(trigs) != TYPE_ARRAY:
			trigs = [trigs]
		for t in trigs:
			if t == "":
				continue
			if not by_trigger.has(t):
				by_trigger[t] = []
			by_trigger[t].append(d)
	for t in by_trigger:
		by_trigger[t].sort_custom(func(a, b): return float(a.get("priority", 50)) > float(b.get("priority", 50)))


func new_day() -> void:
	day_counts.clear()
	queue.clear()


## Fire a trigger from the simulation. Picks the highest priority event that
## passes all checks, plus any listener events marked "also". Returns true if something fired.
func fire(trigger: String, payload: Dictionary = {}) -> bool:
	if not by_trigger.has(trigger):
		return false
	var fired := false
	for d in by_trigger[trigger]:
		var also: bool = d.get("also", false)
		if fired and not also:
			continue
		if _try(d, payload):
			if not also:
				fired = true
	return fired


## Run a specific event directly (used by intents and chains). Roles given explicitly.
func run_event(id: String, roles: Dictionary, vars: Dictionary = {}) -> bool:
	if not defs.has(id):
		push_warning("Unknown event id %s" % id)
		return false
	var payload := roles.duplicate()
	payload["_vars"] = vars
	return _try(defs[id], payload, true)


func _try(d: Dictionary, payload: Dictionary, direct := false) -> bool:
	var ctx := {"event": d["id"], "roles": {}, "vars": {}}
	# payload: npc ids for known role names go to roles, everything else to vars
	for k in payload:
		if k == "_vars":
			for vk in payload[k]:
				ctx["vars"][vk] = payload[k][vk]
		elif k in ROLE_NAMES:
			ctx["roles"][k] = payload[k]
		else:
			ctx["vars"][k] = payload[k]
	# filters on vars
	var flt: Dictionary = d.get("filter", {})
	for k in flt:
		var want = flt[k]
		var have = ctx["vars"].get(k, ctx["roles"].get(k, null))
		if typeof(want) == TYPE_ARRAY:
			var ok := false
			for x in want:
				if EventConditionEvaluator.eq(have, x):
					ok = true
			if not ok:
				return false
		elif not EventConditionEvaluator.eq(have, want):
			return false
	# daily cap & chance
	if d.has("max_day") and int(day_counts.get(d["id"], 0)) >= int(d["max_day"]):
		return false
	if not direct and d.has("chance") and w.rng.randf() > float(d["chance"]):
		return false
	# cooldown (checked with initial roles)
	var ck := _cool_key(d, ctx)
	if not direct and cooldowns.has(ck) and float(cooldowns[ck]) > w.abs_now():
		return false
	# role binding
	for rs in d.get("roles", []):
		var rname: String = rs["name"]
		if ctx["roles"].has(rname) and ctx["roles"][rname] != "":
			continue
		var picked := _pick_role(rs, ctx)
		if picked == "":
			if rs.get("optional", false):
				ctx["roles"][rname] = ""
				continue
			return false
		ctx["roles"][rname] = picked
	# computed variables
	for vs in d.get("vars", []):
		var v = w.pick_var(vs["fn"], vs, ctx)
		if (v == null or str(v) == "") and not vs.get("optional", false):
			return false
		ctx["vars"][vs["name"]] = v if v != null else ""
	# all referenced actors must exist & be present unless allowed
	if not d.get("allow_absent", false):
		for rname in ctx["roles"]:
			var id: String = ctx["roles"][rname]
			if id == "":
				continue
			var n = w.npc(id)
			if n == null or not n.present:
				return false
	if not ev.all(d.get("conditions", []), ctx):
		return false
	# outcome selection
	var effects: Array = d.get("effects", [])
	if d.has("outcomes"):
		var best: Dictionary = {}
		var best_s := -1e18
		var noise := float(d.get("noise", 0.35))
		for o in d["outcomes"]:
			if not ev.all(o.get("when", []), ctx):
				continue
			var s: float = ev.score(o.get("score", []), ctx) + w.rng.randf() * noise
			if s > best_s:
				best_s = s
				best = o
		if best.is_empty():
			return false
		ctx["vars"]["outcome"] = best.get("id", "")
		effects = effects + best.get("effects", [])
	# commit
	day_counts[d["id"]] = int(day_counts.get(d["id"], 0)) + 1
	fired_total[d["id"]] = int(fired_total.get(d["id"], 0)) + 1
	if d.has("cooldown"):
		cooldowns[_cool_key(d, ctx)] = w.abs_now() + float(d["cooldown"])
	var delay0 := float(d.get("delay", 0.0))
	if delay0 > 0.0:
		var shifted: Array = []
		for e in effects:
			var e2: Dictionary = e.duplicate(true)
			e2["delay"] = float(e.get("delay", 0.0)) + delay0
			shifted.append(e2)
		effects = shifted
	res.apply_list(effects, ctx)
	w.on_event_fired(d, ctx)
	return true


func _cool_key(d: Dictionary, ctx: Dictionary) -> String:
	match d.get("scope", "global"):
		"actor":
			return "%s|%s" % [d["id"], ctx["roles"].get("actor", "")]
		"pair":
			var a: String = ctx["roles"].get("actor", "")
			var b: String = ctx["roles"].get("target", "")
			if a > b:
				var t := a
				a = b
				b = t
			return "%s|%s|%s" % [d["id"], a, b]
	return d["id"]


func _pick_role(rs: Dictionary, ctx: Dictionary) -> String:
	var excl: Array = []
	for x in rs.get("exclude", ["actor", "target"]):
		var id := ev.who(x, ctx)
		if id != "":
			excl.append(id)
	var pool: Array = []
	var source: String = rs.get("pool", "present")
	if source == "all":
		pool = C.NPC_IDS.duplicate()
	else:
		pool = w.present_ids()
	var best := ""
	var best_s := -1e18
	var cands: Array = []
	for id in pool:
		if id in excl:
			continue
		var sub := ctx.duplicate(true)
		sub["roles"]["self"] = id
		if rs.has("near"):
			if w.dist(id, ev.who(rs["near"], ctx)) > float(rs.get("r", 5.0)):
				continue
		if rs.get("available", false) and not w.available(id):
			continue
		if not ev.all(rs.get("where", []), sub):
			continue
		var s: float = ev.score(rs.get("score", []), sub) + w.rng.randf() * float(rs.get("noise", 0.3))
		cands.append([id, s])
		if s > best_s:
			best_s = s
			best = id
	if cands.is_empty():
		return ""
	if rs.get("pick", "best") == "random":
		return cands[w.rng.randi() % cands.size()][0]
	return best


## Queue effects to happen later. Each effect keeps its own "delay" in game minutes.
func schedule(effects: Array, ctx: Dictionary) -> void:
	for e in effects:
		var e2: Dictionary = e.duplicate(true)
		var dl := float(e2.get("delay", 0.0))
		e2.erase("delay")
		queue.append({"at": w.minute + dl, "effects": [e2], "ctx": ctx.duplicate(true)})


func tick() -> void:
	if queue.is_empty():
		return
	var due: Array = []
	var keep: Array = []
	for q in queue:
		if float(q["at"]) <= w.minute:
			due.append(q)
		else:
			keep.append(q)
	queue = keep
	due.sort_custom(func(a, b): return a["at"] < b["at"])
	for q in due:
		# drop speech / scene effects of people who already left
		for e in q["effects"]:
			res.apply(e, q["ctx"])


func to_dict() -> Dictionary:
	return {"queue": queue.duplicate(true), "cooldowns": cooldowns.duplicate(), "day_counts": day_counts.duplicate(), "fired_total": fired_total.duplicate()}


func from_dict(d: Dictionary) -> void:
	queue = d.get("queue", [])
	cooldowns = d.get("cooldowns", {})
	day_counts = d.get("day_counts", {})
	fired_total = d.get("fired_total", {})
