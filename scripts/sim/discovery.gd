class_name DiscoveryManager
extends RefCounted
## DiscoveryManager: the player's collection — which interventions they have
## found, which different outcomes they have seen, special moments, finished
## stories (and their alternative endings) and the longest chain reaction a
## single meddle ever caused. Nothing here is a quest; it only records.

signal found(kind: String, id: String)

var w  # SimWorld
var ivs: Dictionary = {}        # intervention id -> {"day", "uses", "out": {"event/outcome": day}}
var specials: Dictionary = {}   # event id -> day first seen
var special_text: Dictionary = {} # event id -> the log line that described it
var special_ref: Dictionary = {}  # event id -> recipe of that line (re-rendered in another language)
var arcs: Dictionary = {}       # arc id -> {"results": {result: day}, "count": n}
var biggest: Dictionary = {}    # {"iv", "count", "day", "text", "arcs"}
var cascades: Dictionary = {}   # cascade id -> {"iv", "count", "day", "text", "arcs"} (recent only)
var watch: Dictionary = {}      # event id -> [intervention ids whose consequence it is]
var special_ids: Dictionary = {}


func _init(world) -> void:
	w = world


## Built from data: which reaction events belong to which intervention.
func setup(iv_defs: Array, event_defs: Dictionary) -> void:
	watch.clear()
	for d in iv_defs:
		for e in d.get("watch", []):
			if not watch.has(e):
				watch[e] = []
			watch[e].append(d["id"])
	special_ids.clear()
	for id in event_defs:
		var ed: Dictionary = event_defs[id]
		if ed.get("special", false) or ed.get("tier", "") == "big":
			special_ids[id] = true


func on_apply(rec: Dictionary, d: Dictionary) -> void:
	var id: String = rec["id"]
	if not ivs.has(id):
		ivs[id] = {"day": w.day, "uses": 0, "out": {}}
		found.emit("iv", id)
	ivs[id]["uses"] = int(ivs[id]["uses"]) + 1
	cascades[rec["cid"]] = {"iv": id, "count": 0, "day": w.day, "text": "", "arcs": []}
	if cascades.size() > 40:
		var ks := cascades.keys()
		ks.sort_custom(func(a, b): return int(str(a).substr(1)) < int(str(b).substr(1)))
		cascades.erase(ks[0])


## Every event that fires reports here (EventManager commit).
func on_event(d: Dictionary, ctx: Dictionary) -> void:
	var eid: String = d["id"]
	var vars: Dictionary = ctx.get("vars", {})
	var out: String = str(vars.get("outcome", ""))
	var key := eid + ("/" + out if out != "" else "")
	# alternative outcomes of interventions
	var ivid: String = str(vars.get("_ivid", ""))
	var targets: Array = watch.get(eid, [])
	if ivid != "" and not targets.has(ivid) and ivs.has(ivid):
		targets = targets + [ivid]
	for iid in targets:
		if ivs.has(iid) and not ivs[iid]["out"].has(key):
			ivs[iid]["out"][key] = w.day
	# special moments
	if special_ids.has(eid) and not specials.has(eid):
		specials[eid] = w.day
		found.emit("special", eid)
	# chain reactions
	var cid: String = str(vars.get("_iv", ""))
	if cid != "" and cascades.has(cid):
		var c: Dictionary = cascades[cid]
		c["count"] = int(c["count"]) + 1
		if int(c["count"]) >= int(biggest.get("count", 0)) and int(c["count"]) >= 2:
			biggest = {"iv": c["iv"], "count": c["count"], "day": c["day"], "text": c["text"], "text_ref": c.get("text_ref", {}), "arcs": c["arcs"].duplicate()}


func on_log(entry: Dictionary, ctx: Dictionary) -> void:
	var eid := str(ctx.get("event", ""))
	if eid != "" and specials.has(eid) and not special_text.has(eid):
		special_text[eid] = entry["text"]
		special_ref[eid] = entry.get("ref", {})
	var cid: String = str(ctx.get("vars", {}).get("_iv", ""))
	if cid != "" and cascades.has(cid):
		cascades[cid]["text"] = entry["text"]
		cascades[cid]["text_ref"] = entry.get("ref", {})
		if biggest.get("iv", "") == cascades[cid]["iv"] and int(biggest.get("count", 0)) == int(cascades[cid]["count"]):
			biggest["text"] = entry["text"]
			biggest["text_ref"] = entry.get("ref", {})


func on_arc_start(arc_id: String, vars: Dictionary) -> void:
	var cid: String = str(vars.get("_iv", ""))
	if cid != "" and cascades.has(cid):
		cascades[cid]["arcs"].append(arc_id)
		cascades[cid]["count"] = int(cascades[cid]["count"]) + 2
		if int(cascades[cid]["count"]) >= int(biggest.get("count", 0)):
			var c: Dictionary = cascades[cid]
			biggest = {"iv": c["iv"], "count": c["count"], "day": c["day"], "text": c["text"], "text_ref": c.get("text_ref", {}), "arcs": c["arcs"].duplicate()}


func on_arc_end(arc_id: String, result: String) -> void:
	if not arcs.has(arc_id):
		arcs[arc_id] = {"results": {}, "count": 0}
		found.emit("arc", arc_id)
	arcs[arc_id]["count"] = int(arcs[arc_id]["count"]) + 1
	if not arcs[arc_id]["results"].has(result):
		arcs[arc_id]["results"][result] = w.day


# ------------------------------------------------------------------ persistence

func to_dict() -> Dictionary:
	return {"ivs": ivs.duplicate(true), "specials": specials.duplicate(), "special_text": special_text.duplicate(), "special_ref": special_ref.duplicate(true), "arcs": arcs.duplicate(true),
		"biggest": biggest.duplicate(true), "cascades": cascades.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	ivs = d.get("ivs", {})
	specials = d.get("specials", {})
	special_text = d.get("special_text", {})
	special_ref = d.get("special_ref", {})
	arcs = d.get("arcs", {})
	biggest = d.get("biggest", {})
	cascades = d.get("cascades", {})


## The journal is a lifetime collection: merge another record into this one.
func merge(d: Dictionary) -> void:
	for id in d.get("ivs", {}):
		var o: Dictionary = d["ivs"][id]
		if not ivs.has(id):
			ivs[id] = o.duplicate(true)
		else:
			ivs[id]["uses"] = maxi(int(ivs[id]["uses"]), int(o.get("uses", 0)))
			for k in o.get("out", {}):
				ivs[id]["out"][k] = o["out"][k]
	for id in d.get("specials", {}):
		if not specials.has(id):
			specials[id] = d["specials"][id]
	for id in d.get("special_text", {}):
		if not special_text.has(id):
			special_text[id] = d["special_text"][id]
			if d.get("special_ref", {}).has(id):
				special_ref[id] = d["special_ref"][id]
	for id in d.get("arcs", {}):
		var a: Dictionary = d["arcs"][id]
		if not arcs.has(id):
			arcs[id] = a.duplicate(true)
		else:
			arcs[id]["count"] = maxi(int(arcs[id]["count"]), int(a.get("count", 0)))
			for r in a.get("results", {}):
				arcs[id]["results"][r] = a["results"][r]
	if int(d.get("biggest", {}).get("count", 0)) > int(biggest.get("count", 0)):
		biggest = d["biggest"].duplicate(true)


## After a language switch: show the remembered lines in the new language.
func relocalize(render: Callable) -> void:
	for id in special_ref:
		var t: String = render.call(special_ref[id])
		if t != "":
			special_text[id] = t
	for c in cascades.values() + [biggest]:
		if typeof(c) == TYPE_DICTIONARY and c.has("text_ref"):
			var t2: String = render.call(c["text_ref"])
			if t2 != "":
				c["text"] = t2


# ------------------------------------------------------------------ journal numbers

## How many different outcomes have been seen across all interventions.
func outcomes_seen() -> int:
	var n := 0
	for id in ivs:
		n += ivs[id].get("out", {}).size()
	return n


## How many different story endings have been seen.
func endings_seen() -> int:
	var n := 0
	for a in arcs:
		n += arcs[a].get("results", {}).size()
	return n
