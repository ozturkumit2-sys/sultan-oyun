class_name DialogueManager
extends RefCounted
## Picks situation-based lines from the dialogue database (no network, no generation).
## Lines are keyed by situation; each key has generic variants ("_") and optional
## per-character variants. Recently used lines are avoided so speech stays fresh.
## Future: a smarter dialogue backend can replace pick() without touching events.

var w
var lines: Dictionary = {}
var recent: Array = []          # recently used "key#index" strings
const RECENT_MAX := 90


func _init(world, data: Dictionary) -> void:
	w = world
	lines = data


func has_key(key: String) -> bool:
	return lines.has(key)


func pick(key: String, speaker: String) -> String:
	if not lines.has(key):
		return ""
	var entry = lines[key]
	var pool: Array = []   # [tag, text]
	if typeof(entry) == TYPE_ARRAY:
		for i in entry.size():
			pool.append(["_%d" % i, entry[i]])
	else:
		var own: Array = entry.get(speaker, [])
		var gen: Array = entry.get("_", [])
		for i in own.size():
			pool.append(["%s%d" % [speaker, i], own[i]])
			pool.append(["%s%d" % [speaker, i], own[i]])   # character lines are twice as likely
		for i in gen.size():
			pool.append(["_%d" % i, gen[i]])
	if pool.is_empty():
		return ""
	var fresh: Array = []
	for p in pool:
		if not recent.has(key + "#" + p[0]):
			fresh.append(p)
	if fresh.is_empty():
		# everything used recently: forget this key's history
		for i in range(recent.size() - 1, -1, -1):
			if recent[i].begins_with(key + "#"):
				recent.remove_at(i)
		fresh = pool
	var chosen: Array = fresh[w.rng.randi() % fresh.size()]
	recent.append(key + "#" + chosen[0])
	if recent.size() > RECENT_MAX:
		recent.pop_front()
	return chosen[1]


## Fills {role} and {var} placeholders from an event context.
func format(tmpl: String, ctx: Dictionary, speaker := "", to := "") -> String:
	if tmpl.find("{") < 0:
		return tmpl
	var roles: Dictionary = ctx.get("roles", {})
	var vars: Dictionary = ctx.get("vars", {})
	return Loc.fill_with(tmpl, func(k: String):
		if roles.has(k):
			var n = w.npc(str(roles[k]))
			return n.name if n else null
		if k == "to" and to != "":
			var tn = w.npc(to)
			return tn.name if tn else null
		if k == "me" and speaker != "":
			var sn = w.npc(speaker)
			return sn.name if sn else null
		if vars.has(k):
			return w.display_var(k, vars[k])
		return null)
