class_name EventConsequenceResolver
extends RefCounted
## Applies data-driven event effects to the world.

var w  # SimWorld
var ev: EventConditionEvaluator


func _init(world, evaluator: EventConditionEvaluator) -> void:
	w = world
	ev = evaluator


func _ids(ref, ctx: Dictionary) -> Array:
	var r: Array = []
	if typeof(ref) == TYPE_ARRAY:
		for x in ref:
			var id := ev.who(x, ctx)
			if id != "":
				r.append(id)
	else:
		var id2 := ev.who(ref, ctx)
		if id2 != "":
			r.append(id2)
	return r


## Applies a list of effects; ones with a "delay" (game minutes) are queued.
func apply_list(list: Array, ctx: Dictionary) -> void:
	var delayed: Array = []
	for se in list:
		if float(se.get("delay", 0.0)) > 0.0:
			delayed.append(se)
		else:
			apply(se, ctx)
	if not delayed.is_empty():
		w.events.schedule(delayed, ctx)


func apply(e: Dictionary, ctx: Dictionary) -> void:
	if e.has("when") and not ev.all(e["when"], ctx):
		return
	if e.has("p") and w.rng.randf() > float(e["p"]):
		return
	match e.get("e", ""):
		"say":
			for id in _ids(e.get("who", "actor"), ctx):
				var line = e["line"]
				if typeof(line) == TYPE_ARRAY:
					line = line[w.rng.randi() % line.size()]
				w.say(id, str(line), ctx, ev.who(e.get("to", ""), ctx))
		"emote":
			for id in _ids(e.get("who", "actor"), ctx):
				var n = w.npc(id)
				if n:
					n.set_emote(e["v"], float(e.get("secs", 2.6)))
		"expr":
			for id in _ids(e.get("who", "actor"), ctx):
				var n2 = w.npc(id)
				if n2:
					n2.set_expr(e["v"], float(e.get("secs", 5.0)))
		"rel":
			var a_ids := _ids(e.get("a", "actor"), ctx)
			var b_ids := _ids(e.get("b", "target"), ctx)
			for a in a_ids:
				for b in b_ids:
					w.change_rel(a, b, e["stat"], float(e["d"]))
					if e.get("both", false):
						w.change_rel(b, a, e["stat"], float(e["d"]) * float(e.get("both_k", 1.0)))
		"mood":
			for id in _ids(e.get("who", "actor"), ctx):
				var n3 = w.npc(id)
				if n3:
					n3.mood = C.clampf100(n3.mood + float(e["d"]))
		"stress":
			for id in _ids(e.get("who", "actor"), ctx):
				var n4 = w.npc(id)
				if n4:
					n4.stress = clampf(n4.stress + float(e["d"]), 0.0, 100.0)
		"mem":
			var about := ev.who(e.get("about", ""), ctx)
			for id in _ids(e.get("who", "actor"), ctx):
				w.remember(id, e["kind"], about, float(e.get("val", 0.0)), float(e.get("w", 0.6)), e.get("text", ""), ctx, int(e.get("imp", 1)))
		"learn":
			var fact := str(ev.val(e["fact"], ctx))
			if fact != "":
				for id in _ids(e.get("who", "actor"), ctx):
					w.learn(id, fact, ev.who(e.get("from", ""), ctx), float(e.get("c", -1.0)))
		"reveal":
			var f2 := str(ev.val(e["fact"], ctx))
			if f2 != "":
				w.reveal(f2)
		"log":
			w.log_event(e["text"], ctx, int(e.get("imp", 1)), e.get("cat", "misc"), _ids(e.get("who", "actor"), ctx))
		"stat":
			w.stats.add(e["key"], int(e.get("n", 1)))
			if e["key"] == "arguments":
				var a2 := ev.who(e.get("a", "actor"), ctx)
				var b2 := ev.who(e.get("b", "target"), ctx)
				w.on_argument(a2, b2)
		"hold":
			var ids := _ids(e.get("who", ["actor", "target"]), ctx)
			w.hold(ids, float(e.get("dur", 4.0)))
		"intent":
			var who_id := ev.who(e.get("who", "actor"), ctx)
			var n5 = w.npc(who_id)
			if n5 == null or not n5.present:
				return
			var it := {
				"type": e.get("type", "go_npc"),
				"target": ev.who(e.get("target", ""), ctx),
				"place": str(ev.val(e.get("place", ""), ctx)),
				"event": e.get("event", ""),
				"prio": float(e.get("prio", 60)),
				"until": w.minute + float(e.get("ttl", 90)),
				"obj": str(ev.val(e.get("obj", ""), ctx)),
				"dur": float(e.get("dur", 6)),
				"label": e.get("label", ""),
				"roles": {},
				"vars": ctx.get("vars", {}).duplicate(true),
			}
			var rmap: Dictionary = e.get("roles", {})
			for k in rmap:
				it["roles"][k] = ev.who(rmap[k], ctx)
			n5.add_intent(it)
		"cancel":
			for id in _ids(e.get("who", "actor"), ctx):
				var n6 = w.npc(id)
				if n6:
					for it2 in n6.intents.duplicate():
						if e.get("type", "") == "" or it2["type"] == e["type"]:
							n6.intents.erase(it2)
		"chain":
			var roles := {}
			var rm: Dictionary = e.get("roles", {"actor": "actor", "target": "target"})
			for k in rm:
				roles[k] = ev.who(rm[k], ctx)
			w.events.run_event(e["event"], roles, ctx.get("vars", {}).duplicate(true))
		"witness":
			var center := ev.who(e.get("near", "actor"), ctx)
			var excl := _ids(e.get("exclude", ["actor", "target"]), ctx)
			var radius := float(e.get("r", 4.5))
			var mx := int(e.get("max", 8))
			var cnt := 0
			for id in w.present_ids():
				if id in excl or id == center:
					continue
				if w.dist(id, center) > radius:
					continue
				var sub := ctx.duplicate(true)
				sub["roles"]["self"] = id
				apply_list(e["effects"], sub)
				cnt += 1
				if cnt >= mx:
					break
		"each":
			var excl2 := _ids(e.get("exclude", []), ctx)
			var k2 := 0
			var stagger := float(e.get("stagger", 0.0))
			var pool: Array = w.present_ids()
			if e.get("shuffle", true):
				pool = pool.duplicate()
				w.shuffle(pool)
			for id in pool:
				if id in excl2:
					continue
				var sub2 := ctx.duplicate(true)
				sub2["roles"]["self"] = id
				if e.has("where") and not ev.all(e["where"], sub2):
					continue
				var delay := stagger * k2
				k2 += 1
				for se in e["effects"]:
					if delay > 0.0 or se.has("delay"):
						var se2: Dictionary = se.duplicate(true)
						se2["delay"] = float(se.get("delay", 0.0)) + delay
						w.events.schedule([se2], sub2)
					else:
						apply(se, sub2)
		"rumor":
			var truth: bool = e.get("truth", true)
			var origin := ev.who(e.get("origin", "actor"), ctx)
			var fid: String = w.make_rumor(e["kind"], ev.who(e.get("a", "actor"), ctx), ev.who(e.get("b", "target"), ctx), float(e.get("juicy", 0.5)), truth, origin)
			ctx["vars"][e.get("key", "rumor")] = fid
			for id in _ids(e.get("knowers", []), ctx):
				w.learn(id, fid, "", float(e.get("c", -1.0)))
		"debunk":
			var df := str(ev.val(e.get("fact", "$rumor"), ctx))
			w.debunk(df, _ids(e.get("who", []), ctx), ev.who(e.get("by", "actor"), ctx))
		"forget":
			var ff := str(ev.val(e["fact"], ctx))
			for id in _ids(e.get("who", "actor"), ctx):
				var nf = w.npc(id)
				if nf:
					nf.forget_fact(ff)
		"distort":
			# a gossip with loose lips "improves" the story while passing it on
			var src := str(ev.val(e.get("fact", "$gossip"), ctx))
			var teller := ev.who(e.get("who", "actor"), ctx)
			var nf2: String = w.distort(src, teller, float(e.get("p", 1.0)))
			if nf2 != "" and nf2 != src:
				ctx["vars"][e.get("key", "gossip")] = nf2
				ctx["vars"]["twisted"] = true
		"bond":
			var ba := ev.who(e.get("a", "actor"), ctx)
			var bb := ev.who(e.get("b", "target"), ctx)
			w.set_bond(ba, bb, e["kind"], e.get("v", true), ev.who(e.get("by", "actor"), ctx))
		"plan":
			var pt := ev.who(e.get("target", ""), ctx)
			for id in _ids(e.get("who", "actor"), ctx):
				var npl = w.npc(id)
				if npl == null:
					continue
				if e.get("v", true):
					npl.add_plan(e["kind"], pt, w.day, float(e.get("heat", 1.0)))
				else:
					npl.drop_plan(e["kind"], pt)
		"morale":
			for id in _ids(e.get("who", "actor"), ctx):
				var nmo = w.npc(id)
				if nmo:
					nmo.morale = clampf(nmo.morale + float(e["d"]), 0.0, 100.0)
		"arc_start":
			var cast := {}
			var cm: Dictionary = e.get("cast", {})
			for k in cm:
				cast[k] = ev.who(cm[k], ctx)
			var avars := {}
			var vm: Dictionary = e.get("vars", {})
			for k in vm:
				avars[k] = ev.val(vm[k], ctx)
			var uid: String = w.director.start_arc(e["arc"], cast, avars, e.get("stage", ""), e.get("force", false))
			if uid != "":
				ctx["vars"]["started_arc"] = uid
		"arc_next":
			var auid := str(ctx.get("vars", {}).get("_arc", ""))
			if auid != "":
				w.director.arc_next(auid, e["stage"], e.get("wait", null), int(e.get("days", 0)))
		"arc_end":
			var euid := str(ctx.get("vars", {}).get("_arc", ""))
			if euid != "":
				w.director.arc_end(euid, e.get("result", "done"))
		"meetup":
			var mids: Array = []
			if str(e.get("who", "")) == "all":
				var first := ev.who("actor", ctx)
				if first != "":
					mids.append(first)
				for pid in w.present_ids():
					if pid != first and w.available(pid):
						mids.append(pid)
			else:
				mids = _ids(e.get("who", ["actor", "target"]), ctx)
			var mroles := {}
			var mrm: Dictionary = e.get("roles", {"actor": "actor", "target": "target"})
			for k in mrm:
				mroles[k] = ev.who(mrm[k], ctx)
			var mvars: Dictionary = ctx.get("vars", {}).duplicate(true)
			w.director.meetup(mids, e.get("area", "kitchen"), e["event"], mroles, mvars, float(e.get("ttl", 40)), float(e.get("prio", 58)), int(e.get("need", 0)))
		"away":
			for id in _ids(e.get("who", "actor"), ctx):
				w.force_activity(id, "away", {"minutes": float(e.get("minutes", 40)), "reason": e.get("reason", ""), "prio": 80.0})
		"favor":
			var ab2 := ev.who(e.get("about", "actor"), ctx)
			if ab2 != "":
				w.favor[ab2] = clampf(float(w.favor.get(ab2, 40.0)) + float(e["d"]), 0.0, 100.0)
		"obj":
			var o: Dictionary = w.office.objects.get(e["obj"], {})
			o[e["key"]] = ev.val(e["v"], ctx)
			w.office_changed.emit(e["obj"])
		"item_home":
			var item := str(ev.val(e.get("item", "$item"), ctx))
			if w.office.items.has(item):
				w.office.items[item]["at"] = w.office.items[item]["home"]
				w.office_changed.emit("items")
		"meet":
			for id in _ids(e.get("who", "actor"), ctx):
				var n7 = w.npc(id)
				if n7 == null:
					continue
				match e.get("v", "board"):
					"board":
						n7.meeting_belief = float(w.office.objects["board"]["time"])
					"cancel":
						n7.meeting_belief = -2.0
		"goal":
			for id in _ids(e.get("who", "actor"), ctx):
				var n8 = w.npc(id)
				if n8:
					n8.goal = e["v"]
		"flag":
			if e.get("day", false):
				w.day_flags[e["key"]] = ev.val(e.get("v", true), ctx)
			else:
				w.flags[e["key"]] = ev.val(e.get("v", true), ctx)
		"npcflag":
			for id in _ids(e.get("who", "actor"), ctx):
				var n9 = w.npc(id)
				if n9:
					n9.today_flags[e["key"]] = e.get("v", true)
		"sfx":
			w.sfx.emit(e["id"])
		"fx":
			var at := ev.who(e.get("who", "actor"), ctx)
			w.fx.emit(e["v"], {"npc": at, "obj": e.get("obj", "")})
		"ghost":
			w.ghost_today += int(e.get("d", 1))
		"work":
			for id in _ids(e.get("who", "actor"), ctx):
				w.add_work(id, float(e["d"]))
		"act":
			for id in _ids(e.get("who", "actor"), ctx):
				w.force_activity(id, e["act"], {"obj": str(ev.val(e.get("obj", ""), ctx)), "target": ev.who(e.get("target", ""), ctx), "place": str(ev.val(e.get("place", ""), ctx)), "dur": float(e.get("dur", 6))})
		"call":
			w.special(e["fn"], e, ctx)
		"trigger":
			var payload := {}
			var tr: Dictionary = e.get("roles", {"actor": "actor", "target": "target"})
			for k in tr:
				payload[k] = ev.who(tr[k], ctx)
			var tv: Dictionary = e.get("vars", {})
			for k in tv:
				payload[k] = ev.val(tv[k], ctx)
			w.events.fire(e["name"], payload)
		"set":
			if e.has("who"):
				ctx["vars"][e["key"]] = ev.who(e["who"], ctx)
			else:
				ctx["vars"][e["key"]] = ev.val(e["v"], ctx)
		"pick":
			# choose one of several effect lists at random (weights optional)
			var opts: Array = e["of"]
			var chosen: Array = opts[w.rng.randi() % opts.size()]
			apply_list(chosen, ctx)
		_:
			push_warning("Unknown effect: %s" % e.get("e", ""))
