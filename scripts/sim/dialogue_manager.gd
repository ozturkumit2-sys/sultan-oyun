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
	var out := tmpl
	var roles: Dictionary = ctx.get("roles", {})
	for r in roles:
		var n = w.npc(roles[r])
		if n:
			out = out.replace("{" + r + "}", n.name)
	if to != "":
		var tn = w.npc(to)
		if tn:
			out = out.replace("{to}", tn.name)
	if speaker != "":
		var sn = w.npc(speaker)
		if sn:
			out = out.replace("{me}", sn.name)
	var vars: Dictionary = ctx.get("vars", {})
	for k in vars:
		var key := "{" + str(k) + "}"
		if out.find(key) < 0:
			continue
		out = out.replace(key, w.display_var(str(k), vars[k]))
	return out
