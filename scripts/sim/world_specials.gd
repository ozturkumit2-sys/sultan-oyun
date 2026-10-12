class_name WorldSpecials
extends RefCounted
## Code-side helpers that events call by name: variable pickers (who gets blamed,
## which gossip to share), email consequences, and a few multi-step effects.

const TOPICS := ["weekend", "weather", "football", "traffic", "series", "food", "vacation", "cats", "gym", "music", "phones", "lottery"]


static func pick(w, fn: String, spec: Dictionary, ctx: Dictionary):
	var ev: EventConditionEvaluator = w.events.ev
	match fn:
		"suspect":
			var victim := ev.who(spec.get("of", "actor"), ctx)
			var loc := str(ev.val(spec.get("loc", ""), ctx))
			if spec.get("desk", false):
				loc = "desk_" + victim
			return suspect_for(w, victim, ev.who(spec.get("not", ""), ctx), loc)
		"gossip_fact":
			var have = ctx.get("vars", {}).get("fact", "")
			if have != "" and w.fact_exists(str(have)):
				var tgt := ev.who("target", ctx)
				var tn = w.npc(tgt)
				if tn and not tn.knows(str(have)) and w.fact_subject(str(have)) != tgt:
					return have
			return gossip_for(w, ev.who("actor", ctx), ev.who("target", ctx))
		"topic":
			return TOPICS[w.rng.randi() % TOPICS.size()]
		"item_owner":
			var item := str(ctx.get("vars", {}).get("item", ""))
			if w.office.items.has(item):
				return w.office.items[item]["owner"]
			return ""
		"board_time":
			return float(w.office.objects["board"]["time"])
		"own_item":
			return w.office.item_owned_by(ev.who("actor", ctx))
		"crush_target":
			return "ceren"
	return ""


## Who does the victim blame? Based on rivalry, distrust, bad memories and who was around.
static func suspect_for(w, victim: String, exclude: String, loc: String) -> String:
	var vn: NPC = w.npc(victim)
	if vn == null:
		return ""
	var spot := Vector2(-100, -100)
	if loc != "":
		spot = w.office.place_pos(OfficeLayout.item_pick_place(loc)) if loc != "printer" and loc != "coffee" else w.office.place_pos(loc)
	var best := ""
	var bs := -1e9
	for id in w.order:
		if id == victim or id == exclude:
			continue
		var o: NPC = w.npc(id)
		var s := vn.get_rel(id, "rivalry") * 0.03 - vn.get_rel(id, "trust") * 0.014 - vn.get_rel(id, "friendship") * 0.008
		s -= vn.mem_bias(id) * 0.5
		if o.present and spot.x > -50.0 and o.pos.distance_to(spot) < 4.0:
			s += 0.5
		if not o.present:
			s -= 0.6
		s += o.t("humor") * 0.25 + o.t("cunning") * 0.2   # pranksters & schemers look guilty
		s += w.rng.randf() * 0.7
		if s > bs:
			bs = s
			best = id
	return best


## Juiciest fact `who` knows that `to` doesn't, isn't about `to`, and `who` is willing to share.
static func gossip_for(w, who_id: String, to: String) -> String:
	var a: NPC = w.npc(who_id)
	var b: NPC = w.npc(to)
	if a == null or b == null:
		return ""
	var best := ""
	var bs := 0.18
	for f in a.known:
		if b.knows(f) or not w.fact_exists(f):
			continue
		var subj: String = w.fact_subject(f)
		if subj == to or subj == who_id:
			continue
		# people don't spread their own secrets, and protect close friends
		var s: float = w.fact_juice(f) * (0.4 + a.t("gossip"))
		if subj != "":
			s -= a.affinity(subj) * 0.006
		if w.dyn_facts.has(f):
			var r: Dictionary = w.dyn_facts[f]
			if r["b"] == to:
				s += 0.25   # "you should know what they said about you"
		if s > bs:
			bs = s
			best = f
	return best


static func best_gossip(w, who_id: String) -> Dictionary:
	var best := {}
	var bs := 0.0
	for id in w.present_ids():
		if id == who_id or not w.available(id):
			continue
		var f := gossip_for(w, who_id, id)
		if f == "":
			continue
		var s: float = w.fact_juice(f) + w.npc(who_id).affinity(id) * 0.004 + w.rng.randf() * 0.2
		if s > bs:
			bs = s
			best = {"fact": f, "to": id, "juice": w.fact_juice(f)}
	return best


static func run(w, fn: String, e: Dictionary, ctx: Dictionary) -> void:
	var ev: EventConditionEvaluator = w.events.ev
	var actor := ev.who(e.get("who", "actor"), ctx)
	var n: NPC = w.npc(actor)
	match fn:
		"search_item":
			if n == null:
				return
			n.add_intent({"type": "search", "target": "", "prio": float(e.get("prio", 58)), "until": w.minute + 120.0, "vars": {"item": ctx["vars"].get("item", "")}, "roles": {}})
		"return_item":
			if n == null:
				return
			var item := str(ctx["vars"].get("item", ""))
			var owner: String = w.office.items[item]["owner"] if w.office.items.has(item) else ""
			if owner == "" or not w.npc(owner).present:
				# just put it back on their desk
				if w.office.items.has(item):
					w.office.items[item]["at"] = w.office.items[item]["home"]
					w.office_changed.emit("items")
				return
			n.add_intent({"type": "return_item", "target": owner, "prio": 52.0, "until": w.minute + 60.0, "vars": {"item": item}, "roles": {}})
		"scold":
			var tgt := ev.who(e.get("target", "target"), ctx)
			var boss: NPC = w.npc("ahmet")
			if boss == null or not boss.present or tgt == "":
				return
			boss.add_intent({"type": "go_npc", "target": tgt, "event": "boss_scold", "prio": float(e.get("prio", 62)), "until": w.minute + 90.0, "vars": {"reason": e.get("reason", ctx["vars"].get("reason", "general"))}, "roles": {}})
		"summon":
			var tgt2 := ev.who(e.get("target", "target"), ctx)
			var t: NPC = w.npc(tgt2)
			if t == null or not t.present:
				return
			t.add_intent({"type": "go_place", "place": "boss_front", "event": e.get("event", "boss_talk"), "prio": float(e.get("prio", 72)), "until": w.minute + 60.0, "target": "", "vars": ctx["vars"].duplicate(true), "roles": {"target": "ahmet"}})
		"share_board":
			var tgt3 := ev.who(e.get("target", "target"), ctx)
			var t3: NPC = w.npc(tgt3)
			if n and t3 and n.meeting_belief >= 0.0 and t3.meeting_belief >= 0.0 and t3.meeting_state == "":
				t3.meeting_belief = n.meeting_belief
		"spread_all":
			var f := str(ev.val(e.get("fact", "$fact"), ctx))
			for id in w.order:
				w.learn(id, f, actor)
		"cliques":
			_cliques(w)
		"lights_fixer":
			var L: Dictionary = w.office.objects["lights"]
			if L["on"] or L.get("fixing", "") != "":
				return
			if n == null:
				return
			L["fixing"] = actor
			w.force_activity(actor, "fix", {"obj": "lights", "prio": 75.0})
		"fix_intent":
			if n == null:
				return
			var obj := str(ev.val(e.get("obj", "$obj"), ctx))
			var req := ev.who(e.get("requester", "actor"), ctx)
			if w.office.objects.has(obj) and w.office.objects[obj].get("fixing", "") == "":
				w.office.objects[obj]["fixing"] = actor
				n.add_intent({"type": "fix", "obj": obj, "prio": float(e.get("prio", 64)), "until": w.minute + 90.0, "roles": {"requester": req}, "vars": {}})
		"meeting_cancel_belief":
			if n:
				n.meeting_belief = -2.0
		"give_up_printing":
			if n:
				n.today_flags["printer_gave_up"] = true
		"thermostat_intent":
			if n:
				n.add_intent({"type": "thermostat", "prio": float(e.get("prio", 50)), "until": w.minute + 40.0, "roles": {}, "vars": {}})
		"npc_move_item":
			var it_id := str(e.get("item", ""))
			if w.office.items.has(it_id):
				w.office.items[it_id]["at"] = str(e.get("to", ""))
				w.office_changed.emit("items")
		"ghost_theory":
			w.flags["ghost_belief"] = int(w.flags.get("ghost_belief", 0)) + 1
		_:
			push_warning("Unknown special: " + fn)


static func _cliques(w) -> void:
	# two people are "close" when they like each other; split the room into camps
	var ids: Array = w.present_ids()
	if ids.size() < 4:
		return
	var groups: Array = []
	var seen := {}
	for id in ids:
		if seen.has(id):
			continue
		var grp: Array = [id]
		seen[id] = true
		var k := 0
		while k < grp.size():
			var a: NPC = w.npc(grp[k])
			for other in ids:
				if seen.has(other):
					continue
				if a.affinity(other) > 32.0 and w.npc(other).affinity(grp[k]) > 32.0:
					grp.append(other)
					seen[other] = true
			k += 1
		if grp.size() >= 2:
			groups.append(grp)
	if groups.size() < 2:
		return
	groups.sort_custom(func(x, y): return x.size() > y.size())
	var g1: Array = groups[0]
	var g2: Array = groups[1]
	# are the camps hostile?
	var hostile := 0.0
	for a in g1:
		for b in g2:
			hostile += w.npc(a).affinity(b)
	hostile /= float(g1.size() * g2.size())
	if hostile > -5.0:
		return
	var names1 := ", ".join(g1.map(func(x): return w.npc(x).name))
	var names2 := ", ".join(g2.map(func(x): return w.npc(x).name))
	w.stats.add("cliques")
	w.log_event("log.cliques", {"roles": {"actor": g1[0], "target": g2[0]}, "vars": {"g1": names1, "g2": names2}}, 3, "cliques", g1 + g2)


# =====================================================================
# Email mishaps (wrong email to everyone / redirected recipient)
# =====================================================================

## Picks what the sender's email actually contains, from their data-defined drafts.
static func email_content(w, sender: String, private_msg: bool) -> Dictionary:
	var n: NPC = w.npc(sender)
	var drafts: Array = n.def.get("drafts", [])
	var valid: Array = []
	for dr in drafts:
		var tp: String = dr["type"]
		match tp:
			"secret":
				var f: String = dr["fact"]
				if w.fact_exists(f) and n.knows(f) and not w.discovered.has(f):
					valid.append({"type": "secret", "fact": f, "about": w.fact_subject(f)})
			"gossip_digest":
				var g := ""
				var gb := 0.0
				for f2 in n.known:
					if not w.fact_defs.has(f2) or w.discovered.has(f2):
						continue
					var subj: String = w.fact_subject(f2)
					if subj == sender or subj == "":
						continue
					if w.fact_juice(f2) > gb:
						gb = w.fact_juice(f2)
						g = f2
				if g != "":
					valid.append({"type": "gossip_digest", "fact": g, "about": w.fact_subject(g)})
			"rant":
				var worst := ""
				var wv := 1e9
				for id in w.order:
					if id == sender:
						continue
					if n.affinity(id) < wv:
						wv = n.affinity(id)
						worst = id
				if worst != "":
					valid.append({"type": "rant", "about": worst})
			"love":
				if w.fact_exists("mert_crush"):
					valid.append({"type": "love", "fact": "mert_crush", "about": "ceren"})
			"complaint_boss":
				valid.append({"type": "complaint_boss", "about": "ahmet"})
			"complaint_team":
				valid.append({"type": "complaint_team", "about": ""})
			"scheme":
				valid.append({"type": "scheme", "about": "selin"})
	if valid.is_empty():
		valid.append({"type": "rant", "about": "ahmet" if sender != "ahmet" else "mert"})
	var pick: Dictionary = valid[0] if w.rng.randf() < 0.7 else valid[w.rng.randi() % valid.size()]
	return pick


## The confidant someone would normally write private messages to.
static func confidant(w, sender: String) -> String:
	var n: NPC = w.npc(sender)
	var best := ""
	var bs := -1e9
	for id in w.order:
		if id == sender:
			continue
		if n.affinity(id) > bs:
			bs = n.affinity(id)
			best = id
	return best


static func send_email(w, sender: String) -> void:
	var o: OfficeEnv = w.office
	if not o.objects["email"].has(sender):
		return
	var sab: Dictionary = o.objects["email"][sender]
	o.objects["email"].erase(sender)
	w.office_changed.emit("email")
	var mode: String = sab.get("mode", "all")
	var content := email_content(w, sender, mode == "redirect")
	var tp: String = content["type"]
	var about: String = content.get("about", "")
	var fact: String = content.get("fact", "")
	var to: String = sab.get("to", "")
	var intended := confidant(w, sender)
	if mode == "redirect" and to == intended:
		intended = ""
	w.stats.add("emails")
	w.sfx.emit("email")
	var ctx := {"roles": {"actor": sender, "target": to, "subject": about}, "vars": {"etype": tp, "intended": intended}}
	if fact != "":
		ctx["vars"]["fact"] = fact
	# who actually reads it
	var readers: Array = []
	if mode == "all":
		for id in w.order:
			if id != sender:
				readers.append(id)
	else:
		readers = [to]
	# --- what readers learn
	match tp:
		"secret", "gossip_digest", "love":
			for id in readers:
				w.learn(id, fact, sender)
			if mode == "all" or to != "":
				w.reveal(fact)
		"rant":
			var rid: String = w.make_rumor("dislikes", sender, about, 0.7)
			ctx["vars"]["rumor"] = rid
			for id in readers:
				w.learn(id, rid, sender)
			w.reveal(rid)
		"scheme":
			var sid: String = w.make_rumor("scheme", sender, about, 0.9)
			ctx["vars"]["rumor"] = sid
			for id in readers:
				w.learn(id, sid, sender)
			w.reveal(sid)
		"complaint_boss":
			if "ahmet" in readers:
				w.change_rel("ahmet", sender, "trust", -22.0)
				w.change_rel("ahmet", sender, "friendship", -12.0)
				w.favor[sender] = clampf(float(w.favor.get(sender, 40.0)) - 10.0, 0, 100)
			for id in readers:
				if id != "ahmet":
					w.change_rel(id, sender, "friendship", 4.0)   # secretly agree
		"complaint_team":
			for id in readers:
				w.change_rel(id, "ahmet", "friendship", -10.0)
				w.change_rel(id, "ahmet", "trust", -6.0)
				var rn: NPC = w.npc(id)
				rn.mood = C.clampf100(rn.mood - 8.0)
	var sn: NPC = w.npc(sender)
	sn.stress = clampf(sn.stress + (22.0 if mode == "all" else 12.0), 0, 100)
	sn.mood = C.clampf100(sn.mood - 14.0)
	# --- log & scene
	var key := "log.email_all.%s" % tp if mode == "all" else "log.email_redirect.%s" % tp
	w.log_event(key, ctx, 4 if mode == "all" else 3, "email", [sender, to, about].filter(func(x): return x != ""))
	var ev_id := "email_all_scene" if mode == "all" else "email_redirect_scene"
	w.events.run_event(ev_id, {"actor": sender, "target": to, "subject": about}, ctx["vars"])
