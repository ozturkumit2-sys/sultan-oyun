class_name InterventionManager
extends RefCounted
## InterventionManager + InterventionDatabase: every way the invisible player can
## meddle, loaded from data/interventions.json. One shared pipeline handles all of
## them: per-object menus, activation conditions (InterventionConditionEvaluator =
## the event condition evaluator + intervention terms), real state changes and
## reactions (InterventionEffectResolver = the event effect resolver: traps,
## chains, intents, rumours, memories...), reuse rules and discovery.
## The 13 original interventions keep their hand-written code (Interventions) and
## are listed in the same database as "legacy" entries.

const WS_TABS := ["pc", "mail", "phone", "papers"]

var w  # SimWorld
var defs: Array = []
var by_id: Dictionary = {}
var by_key: Dictionary = {}
var by_obj: Dictionary = {}          # object id ("ws" for any workstation) -> [defs]
var by_legacy: Dictionary = {}       # legacy action id -> def
var used: Array = []                 # {id, owner, target, day, minute, cid}
var cool: Dictionary = {}            # cooldown key -> abs time when usable again
var day_uses: Dictionary = {}        # scope key -> uses today
var counter := 0


func _init(world) -> void:
	w = world


func load_defs(data) -> void:
	defs.clear()
	by_id.clear()
	by_key.clear()
	by_obj.clear()
	by_legacy.clear()
	if typeof(data) != TYPE_DICTIONARY:
		return
	for d in data.get("list", []):
		defs.append(d)
		by_id[d["id"]] = d
		by_key[d["key"]] = d
		var o: String = d.get("obj", "")
		if not by_obj.has(o):
			by_obj[o] = []
		by_obj[o].append(d)
		if d.get("legacy", "") != "":
			by_legacy[d["legacy"]] = d


func new_day() -> void:
	day_uses.clear()
	# only the last few days of usage matter for combos and the journal
	var keep: Array = []
	for u in used:
		if int(u["day"]) >= w.day - 2:
			keep.append(u)
	used = keep


## Which object family a tapped hotspot belongs to.
static func obj_of(spot: String) -> String:
	if spot.begins_with("ws_"):
		return "ws"
	if spot.begins_with("item_"):
		return "item"
	return spot


static func owner_of(spot: String) -> String:
	if spot.begins_with("ws_"):
		return spot.substr(3)
	return ""


# =====================================================================
# Menus
# =====================================================================

## Everything that can be done to this object right now (plus what can't, and why).
## Hidden combinations only appear once their ingredients are in place.
func actions_for(spot: String) -> Array:
	var out: Array = []
	var owner := owner_of(spot)
	# legacy entries keep their own availability logic
	for la in Interventions.actions_for(w, spot):
		var d: Dictionary = by_legacy.get(la["id"], {})
		var a: Dictionary = la.duplicate()
		a["legacy"] = la.duplicate()
		a["def"] = d
		a["iv"] = d.get("id", la["id"])
		a["tab"] = d.get("tab", "")
		a["hidden"] = false
		if a["enabled"]:
			var rr := _reuse_reason(d, la.get("owner", owner), "")
			if rr != "":
				a["enabled"] = false
				a["reason"] = rr
		out.append(a)
	for d in by_obj.get(obj_of(spot), []):
		if d.get("legacy", "") != "":
			continue
		var owners: Array = d.get("owners", [])
		if not owners.is_empty() and not (owner in owners):
			continue
		var ctx := ctx_for(d, owner, null)
		var why := reason(d, ctx)
		if d.get("hidden", false) and why != "":
			continue          # secret combinations stay invisible until possible
		out.append({"id": d["key"], "iv": d["id"], "def": d, "needs": d.get("needs", ""), "enabled": why == "",
			"reason": why, "owner": owner, "tab": d.get("tab", ""), "hidden": d.get("hidden", false)})
	return out


## Does this intervention ask for a person AND then a choice?
static func two_step(d: Dictionary) -> bool:
	return d.get("needs", "") == "person" and not d.get("choices", []).is_empty()


## Choices for a parameterised intervention. For two-step ones, call again with
## the picked person to get the second list (values become [person, choice]).
func options_for(action: Dictionary, picked = null) -> Array:
	if action.has("legacy"):
		return Interventions.options_for(w, action["legacy"])
	var d: Dictionary = action["def"]
	var owner: String = action.get("owner", "")
	var r: Array = []
	if picked != null and two_step(d):
		for c in d.get("choices", []):
			r.append({"value": [picked, c["v"]], "label": c.get("label", "opt." + str(c["v"])), "args": {}, "enabled": true})
		return r
	match d.get("needs", ""):
		"person":
			var ev: EventConditionEvaluator = w.events.ev
			for id in w.order:
				if id == owner:
					continue
				var ctx := ctx_for(d, owner, id)
				ctx["roles"]["self"] = id
				var ok: bool = ev.all(d.get("pick", []), ctx)
				if ok and not d.get("absent_ok", false) and not w.npc(id).present:
					ok = false
				r.append({"value": id, "label": "opt.person", "args": {"name": w.npc(id).name}, "enabled": ok})
		"choice":
			for c in d.get("choices", []):
				var ctx2 := ctx_for(d, owner, c["v"])
				var ok2: bool = w.events.ev.all(c.get("when", []), ctx2)
				r.append({"value": c["v"], "label": c.get("label", "opt." + str(c["v"])), "args": {}, "enabled": ok2})
		"time":
			var bt := float(w.office.objects["board"]["time"])
			for s in [-60, -30, 30, 60]:
				var nt: float = bt + float(s)
				var ok3: bool = nt > w.minute + 5.0 and nt >= 30.0 and nt <= 420.0
				r.append({"value": nt, "label": "opt.meeting_at", "args": {"time": C.fmt(nt)}, "enabled": ok3})
	return r


# =====================================================================
# Conditions (InterventionConditionEvaluator)
# =====================================================================

func ctx_for(d: Dictionary, owner: String, value) -> Dictionary:
	var roles := {}
	if owner != "":
		roles["owner"] = owner
		roles["actor"] = owner
	var obj: String = d.get("obj", "")
	var vars := {"iv": d.get("id", ""), "spot": obj, "spot_id": ("ws_" + owner) if obj == "ws" else obj}
	if typeof(value) == TYPE_ARRAY and value.size() == 2:
		roles["target"] = str(value[0])
		vars["choice"] = str(value[1])
	elif d.get("needs", "") == "person" and value != null and str(value) != "":
		roles["target"] = str(value)
	if value != null and typeof(value) != TYPE_ARRAY:
		vars["value"] = value
		if d.get("needs", "") == "choice":
			vars["choice"] = str(value)
	# a few interventions pick their own subject (e.g. "the person with a secret job application")
	for vs in d.get("vars", []):
		var v = w.pick_var(vs["fn"], vs, {"roles": roles, "vars": vars})
		if v != null and str(v) != "":
			if vs.get("role", false):
				roles[vs["name"]] = str(v)
			else:
				vars[vs["name"]] = v
	return {"event": "iv:" + d.get("id", ""), "roles": roles, "vars": vars}


## "" when usable, otherwise the translation key saying why not.
func reason(d: Dictionary, ctx: Dictionary) -> String:
	var ev: EventConditionEvaluator = w.events.ev
	for vs in d.get("vars", []):
		if not vs.get("optional", false):
			var have = ctx["roles"].get(vs["name"], ctx["vars"].get(vs["name"], ""))
			if str(have) == "":
				return str(vs.get("why", d.get("why", "why.not_now")))
	if d.get("owner_present", d.get("obj", "") == "ws" and d.get("tab", "") != "papers"):
		var on = w.npc(ctx["roles"].get("owner", ""))
		if on != null and not on.present and not d.get("absent_ok", false):
			return "why.owner_absent"
	for c in d.get("conds", []):
		if not ev.check(c, ctx):
			return str(c.get("why", d.get("why", "why.not_now")))
	return _reuse_reason(d, ctx["roles"].get("owner", ""), "")


func _scope_key(d: Dictionary, owner: String, target: String) -> String:
	match d.get("reuse", {}).get("per", "owner" if owner != "" else "global"):
		"owner":
			return "%s|%s" % [d.get("id", ""), owner]
		"target":
			return "%s|%s" % [d.get("id", ""), target]
	return str(d.get("id", ""))


func _reuse_reason(d: Dictionary, owner: String, target: String) -> String:
	if d.is_empty():
		return ""
	var ru: Dictionary = d.get("reuse", {})
	var k := _scope_key(d, owner, target)
	if cool.has(k) and float(cool[k]) > w.abs_now():
		return "why.cooldown"
	if ru.has("day") and int(day_uses.get(k, 0)) >= int(ru["day"]):
		return "why.used_today"
	return ""


func used_recently(id: String, days := 0, owner := "", target := "") -> bool:
	for u in used:
		if u["id"] != id or int(u["day"]) < w.day - days:
			continue
		if owner != "" and u.get("owner", "") != owner and u.get("target", "") != owner:
			continue
		if target != "" and u.get("target", "") != target and u.get("owner", "") != target:
			continue
		return true
	return false


# =====================================================================
# Applying (InterventionEffectResolver)
# =====================================================================

func apply(action: Dictionary, value = null) -> bool:
	var d: Dictionary = action.get("def", {})
	counter += 1
	var cid := "c%d" % counter
	var owner: String = action.get("owner", "")
	var target := ""
	var ok := false
	if action.has("legacy"):
		w.current_cid = cid
		ok = Interventions.apply(w, action["legacy"], value)
		w.current_cid = ""
		if action["legacy"]["id"] == "email_redirect" and value != null:
			target = str(value)
	else:
		var ctx := ctx_for(d, owner, value)
		if reason(d, ctx) != "":
			return false
		ctx["vars"]["_iv"] = cid
		ctx["vars"]["_ivid"] = d["id"]
		target = str(ctx["roles"].get("target", ""))
		var res: EventConsequenceResolver = w.events.res
		res.apply_list(d.get("state", []), ctx)
		res.apply_list(d.get("react", []), ctx)
		w.total_interventions += 1
		w.stats.add("interventions")
		w.ghost_today += 1
		var who: Array = []
		for k in ["owner", "target"]:
			if str(ctx["roles"].get(k, "")) != "":
				who.append(ctx["roles"][k])
		if d.get("log", "") != "":
			w.log_event(d["log"], ctx, int(d.get("imp", 2)), "player", who)
		w.office_changed.emit("iv")
		w.sfx.emit(d.get("sfx", "meddle"))
		w.fx.emit("meddle", {"action": d["key"], "spot": action.get("spot", ""), "owner": owner, "item": ""})
		ok = true
	if not ok:
		return false
	# reuse bookkeeping
	if not d.is_empty():
		var ru: Dictionary = d.get("reuse", {})
		var k := _scope_key(d, owner, target)
		if ru.has("cool"):
			cool[k] = w.abs_now() + float(ru["cool"])
		day_uses[k] = int(day_uses.get(k, 0)) + 1
	var rec := {"id": d.get("id", action.get("id", "")), "owner": owner, "target": target, "day": w.day, "minute": w.minute, "cid": cid}
	used.append(rec)
	if used.size() > 80:
		used.pop_front()
	w.discovery.on_apply(rec, d)
	return true


# =====================================================================
# Save
# =====================================================================

func to_dict() -> Dictionary:
	return {"used": used.duplicate(true), "cool": cool.duplicate(), "day_uses": day_uses.duplicate(), "counter": counter}


func from_dict(d: Dictionary) -> void:
	used = d.get("used", [])
	cool = d.get("cool", {})
	day_uses = d.get("day_uses", {})
	counter = int(d.get("counter", 0))
	for u in used:
		u["day"] = int(u.get("day", 1))
