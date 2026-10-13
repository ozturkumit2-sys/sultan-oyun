class_name EventConditionEvaluator
extends RefCounted
## Evaluates data-driven conditions and score terms for the event system.
## A "who" reference is a role name from the context ("actor", "target", "self", ...),
## a literal npc id prefixed with "@" ("@ahmet"), or a variable "$name".

var w  # SimWorld


func _init(world) -> void:
	w = world


func who(ref, ctx: Dictionary) -> String:
	if ref == null:
		return ""
	var s := str(ref)
	if s.begins_with("@"):
		return s.substr(1)
	if s.begins_with("$"):
		return str(ctx.get("vars", {}).get(s.substr(1), ""))
	return str(ctx.get("roles", {}).get(s, ""))


func val(ref, ctx: Dictionary):
	if typeof(ref) == TYPE_STRING and ref.begins_with("$"):
		return ctx.get("vars", {}).get(ref.substr(1), "")
	return ref


## Flags can hold true/false, numbers, ids or results: "set" means non-empty and not false/0.
static func truthy(v) -> bool:
	match typeof(v):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return float(v) != 0.0
		TYPE_STRING, TYPE_STRING_NAME:
			return str(v) != ""
	return true


## Equality that never errors on mixed types (int/float compare by value).
static func eq(a, b) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	if (ta == TYPE_INT or ta == TYPE_FLOAT) and (tb == TYPE_INT or tb == TYPE_FLOAT):
		return float(a) == float(b)
	if ta != tb:
		return false
	return a == b


func _cmp(v: float, c: Dictionary) -> bool:
	if c.has("gt") and not (v > float(c["gt"])):
		return false
	if c.has("lt") and not (v < float(c["lt"])):
		return false
	if c.has("gte") and not (v >= float(c["gte"])):
		return false
	if c.has("lte") and not (v <= float(c["lte"])):
		return false
	return true


func all(conds: Array, ctx: Dictionary) -> bool:
	for c in conds:
		if not check(c, ctx):
			return false
	return true


func check(c: Dictionary, ctx: Dictionary) -> bool:
	var res := _check(c, ctx)
	if c.get("not", false):
		return not res
	return res


func _check(c: Dictionary, ctx: Dictionary) -> bool:
	var kind: String = c.get("c", "")
	match kind:
		"trait":
			var n = w.npc(who(c.get("who", "actor"), ctx))
			return n != null and _cmp(n.t(c["t"]), c)
		"rel":
			var a = w.npc(who(c.get("a", "actor"), ctx))
			var b := who(c.get("b", "target"), ctx)
			return a != null and b != "" and _cmp(a.get_rel(b, c["stat"]), c)
		"affinity":
			var a2 = w.npc(who(c.get("a", "actor"), ctx))
			var b2 := who(c.get("b", "target"), ctx)
			return a2 != null and b2 != "" and _cmp(a2.affinity(b2), c)
		"mood":
			var n2 = w.npc(who(c.get("who", "actor"), ctx))
			return n2 != null and _cmp(n2.mood, c)
		"stress":
			var n3 = w.npc(who(c.get("who", "actor"), ctx))
			return n3 != null and _cmp(n3.stress, c)
		"knows":
			var n4 = w.npc(who(c.get("who", "actor"), ctx))
			var f := str(val(c["fact"], ctx))
			return n4 != null and n4.knows(f)
		"fact_exists":
			return w.fact_exists(str(val(c["fact"], ctx)))
		"is":
			var id := who(c.get("who", "actor"), ctx)
			if c.has("in"):
				return id in c["in"]
			return id == c.get("id", "")
		"same":
			return who(c["a"], ctx) == who(c["b"], ctx)
		"present":
			var n5 = w.npc(who(c.get("who", "actor"), ctx))
			return n5 != null and n5.present
		"available":
			return w.available(who(c.get("who", "actor"), ctx))
		"near":
			var d: float = w.dist(who(c.get("a", "actor"), ctx), who(c.get("b", "target"), ctx))
			return d < float(c.get("lt", 3.0))
		"time":
			var m: float = w.minute
			if c.has("after") and m < C.hm(c["after"]):
				return false
			if c.has("before") and m > C.hm(c["before"]):
				return false
			return true
		"chance":
			return w.rng.randf() < float(c.get("p", 0.5))
		"goal":
			var n6 = w.npc(who(c.get("who", "actor"), ctx))
			if n6 == null:
				return false
			if c.has("in"):
				return n6.goal in c["in"]
			return n6.goal == c["goal"]
		"mem":
			var n7 = w.npc(who(c.get("who", "actor"), ctx))
			var ab := who(c["about"], ctx) if c.has("about") else ""
			var since: int = int(w.day) - int(c.get("days", 99))
			return n7 != null and n7.has_memory(c["kind"], ab, since)
		"memval":
			var n8 = w.npc(who(c.get("who", "actor"), ctx))
			return n8 != null and _cmp(n8.mem_bias(who(c["about"], ctx)), c)
		"day":
			return _cmp(float(w.day), c)
		"office":
			var v = C.dict_get_path(w.office.objects, c["key"])
			if c.has("eq"):
				return eq(v, c["eq"])
			return _cmp(float(v if v != null else 0), c)
		"flag":
			var fv = w.flags.get(c["key"], false)
			if c.has("eq"):
				return eq(fv, c["eq"])
			return truthy(fv)
		"dayflag":
			var dv = w.day_flags.get(c["key"], false)
			if c.has("eq"):
				return eq(dv, c["eq"])
			return truthy(dv)
		"npcflag":
			var n9 = w.npc(who(c.get("who", "actor"), ctx))
			return n9 != null and truthy(n9.today_flags.get(c["key"], false))
		"activity":
			var n10 = w.npc(who(c.get("who", "actor"), ctx))
			return n10 != null and n10.act in c["in"]
		"stat":
			return _cmp(float(w.stats.get_count(c["key"])), c)
		"var":
			var vv = ctx.get("vars", {}).get(c["key"], "")
			if c.has("in"):
				for x in c["in"]:
					if eq(vv, x):
						return true
				return false
			if c.has("eq"):
				return eq(vv, c["eq"])
			return _cmp(float(vv if typeof(vv) in [TYPE_INT, TYPE_FLOAT] else 0), c)
		"zone":
			var n11 = w.npc(who(c.get("who", "actor"), ctx))
			return n11 != null and w.zone_of(n11) in c["in"]
		"meeting":
			return eq(w.meeting.get(c["key"], false), c.get("eq", true))
		"work_left":
			var n12 = w.npc(who(c.get("who", "actor"), ctx))
			return n12 != null and _cmp(n12.work_left(), c)
		"discomfort":
			var n14 = w.npc(who(c.get("who", "actor"), ctx))
			return n14 != null and _cmp(w.discomfort(n14), c)
		"ghost":
			return _cmp(float(w.ghost_today), c)
		"rolefilled":
			return who(c.get("who", "target"), ctx) != ""
		"promoted":
			var n13 = w.npc(who(c.get("who", "actor"), ctx))
			return n13 != null and n13.promoted
		"sure":
			# how certain someone is about a fact (rumours heard second-hand are shaky)
			var ns = w.npc(who(c.get("who", "actor"), ctx))
			if ns == null:
				return false
			var cv: float = ns.certainty(str(val(c["fact"], ctx)))
			if not (c.has("gt") or c.has("lt") or c.has("gte") or c.has("lte")):
				return cv >= 0.7
			return cv > 0.0 and _cmp(cv, c)
		"truth":
			return eq(w.fact_true(str(val(c["fact"], ctx))), c.get("eq", true))
		"bond":
			var ba := who(c.get("a", "actor"), ctx)
			var bb = c.get("b", "target")
			if str(bb) == "*":
				return not w.bonds_of(ba, c["kind"]).is_empty()
			return w.has_bond(ba, who(bb, ctx), c["kind"])
		"plan":
			var np = w.npc(who(c.get("who", "actor"), ctx))
			if np == null:
				return false
			var pt := who(c["target"], ctx) if c.has("target") else ""
			return np.has_plan(c["kind"], pt)
		"morale":
			var nm = w.npc(who(c.get("who", "actor"), ctx))
			return nm != null and _cmp(nm.morale, c)
		"arc":
			return w.director.active_of(c["arc"]) > 0
		"picks":
			# true when a code-side picker finds someone/something (cheap pre-check for initiatives)
			var pv = w.pick_var(c["fn"], c, ctx)
			return pv != null and str(pv) != ""
		"can_arc":
			var cast := {}
			var cm: Dictionary = c.get("cast", {})
			for k in cm:
				cast[k] = who(cm[k], ctx)
			return w.director.can_start(c["arc"], cast)
		"in_story":
			return _cmp(float(w.director.busy_count(who(c.get("who", "actor"), ctx))), c)
		"fired":
			var days: Array = w.director.history.get(c["event"], [])
			var since := int(w.day) - int(c.get("days", 0))
			for dd in days:
				if int(dd) >= since:
					return true
			return false
		"result":
			var fv2 = w.flags.get("arc_%s_%s" % [c["arc"], c["result"]], null)
			return fv2 != null and int(fv2) >= int(w.day) - int(c.get("days", 99))
		"any":
			for sub in c["of"]:
				if check(sub, ctx):
					return true
			return false
		"all":
			return all(c["of"], ctx)
		_:
			push_warning("Unknown condition: %s" % kind)
			return false


func score(terms: Array, ctx: Dictionary) -> float:
	var s := 0.0
	for tm in terms:
		s += _term(tm, ctx)
	return s


func _term(tm: Dictionary, ctx: Dictionary) -> float:
	var wt := float(tm.get("w", 1.0))
	match tm.get("s", ""):
		"const":
			return float(tm.get("v", 0.0))
		"rand":
			return w.rng.randf() * float(tm.get("v", 1.0))
		"trait":
			var n = w.npc(who(tm.get("who", "actor"), ctx))
			return n.t(tm["t"]) * wt if n else 0.0
		"rel":
			var a = w.npc(who(tm.get("a", "actor"), ctx))
			return a.get_rel(who(tm.get("b", "target"), ctx), tm["stat"]) * wt if a else 0.0
		"affinity":
			var a2 = w.npc(who(tm.get("a", "actor"), ctx))
			return a2.affinity(who(tm.get("b", "target"), ctx)) * wt if a2 else 0.0
		"mood":
			var n2 = w.npc(who(tm.get("who", "actor"), ctx))
			return n2.mood * wt if n2 else 0.0
		"stress":
			var n3 = w.npc(who(tm.get("who", "actor"), ctx))
			return n3.stress * wt if n3 else 0.0
		"mem":
			var n4 = w.npc(who(tm.get("who", "actor"), ctx))
			return n4.mem_bias(who(tm["about"], ctx)) * wt if n4 else 0.0
		"dist":
			var d: float = w.dist(who(tm.get("a", "actor"), ctx), who(tm.get("b", "target"), ctx))
			return minf(d, 30.0) * wt
		"is":
			var id := who(tm.get("who", "actor"), ctx)
			if tm.has("in"):
				return float(tm.get("v", 1.0)) if id in tm["in"] else 0.0
			return float(tm.get("v", 1.0)) if id == tm.get("id", "") else 0.0
		"knows":
			var n5 = w.npc(who(tm.get("who", "actor"), ctx))
			return float(tm.get("v", 1.0)) if (n5 and n5.knows(str(val(tm["fact"], ctx)))) else 0.0
		"goal":
			var n6 = w.npc(who(tm.get("who", "actor"), ctx))
			return float(tm.get("v", 1.0)) if (n6 and n6.goal == tm["goal"]) else 0.0
		"favor":
			return float(w.favor.get(who(tm.get("who", "actor"), ctx), 0.0)) * wt
		"discomfort":
			var n7 = w.npc(who(tm.get("who", "actor"), ctx))
			return w.discomfort(n7) * wt if n7 else 0.0
		"if":
			return float(tm.get("v", 1.0)) if check(tm["cond"], ctx) else float(tm.get("else", 0.0))
		"morale":
			var n8 = w.npc(who(tm.get("who", "actor"), ctx))
			return n8.morale * wt if n8 else 0.0
		"plan":
			var n9 = w.npc(who(tm.get("who", "actor"), ctx))
			var pt := who(tm["target"], ctx) if tm.has("target") else ""
			return float(tm.get("v", 1.0)) if (n9 and n9.has_plan(tm["kind"], pt)) else 0.0
		"bond":
			return float(tm.get("v", 1.0)) if w.has_bond(who(tm.get("a", "actor"), ctx), who(tm.get("b", "target"), ctx), tm["kind"]) else 0.0
		"sure":
			var n10 = w.npc(who(tm.get("who", "actor"), ctx))
			return n10.certainty(str(val(tm["fact"], ctx))) * wt if n10 else 0.0
		"busy":
			return float(w.director.busy_count(who(tm.get("who", "actor"), ctx))) * wt
	return 0.0
