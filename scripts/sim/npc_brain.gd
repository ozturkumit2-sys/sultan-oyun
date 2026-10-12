class_name NPCBrain
extends RefCounted
## Utility-based choice of the next free-time activity. Every option is scored
## from the daily schedule, personality, current needs, relationships, goals and
## memories, so no two characters behave alike.


static func choose(w, n: NPC) -> Dictionary:
	var o: OfficeEnv = w.office
	var m: float = w.minute
	var opts: Array = []   # [score, spec]
	var tk := n.current_task()
	var dil := n.t("diligence")
	var soc := n.t("sociability")
	var noise := 0.25

	# --- work
	var work := 0.35 + dil * 0.9
	if tk.is_empty():
		work = 0.18 + dil * 0.15
	else:
		var dl := NPCSchedule.task_deadline(w, n, tk)
		var left: float = tk["left"]
		var slack := (dl - m) - left * 1.1
		if slack < 30.0:
			work += 0.9
		elif slack < 90.0:
			work += 0.35
	if n.id == "mert" and n.goal != "hit_sales" and m < 300.0:
		work *= 0.6   # last-minute guy
	if n.stress > 70.0:
		work *= 0.8
	if not o.objects["lights"]["on"]:
		work *= 0.2
	opts.append([work, {"act": "work", "dur": w.rng.randf_range(22.0, 48.0)}])

	# --- printing finished work
	var pt := n.task_needing_print()
	if not pt.is_empty() and not n.today_flags.get("printer_gave_up", false):
		var urgency := 1.3
		if o.objects["printer"]["broken"] and n.has_memory("printer_broken", "", w.day):
			urgency = 0.35
		opts.append([urgency, {"act": "print"}])

	# --- coffee
	var coffee_love := float(n.prefs.get("coffee", 0.5))
	var cof := n.coffee_need / 100.0 * (0.5 + coffee_love) * 1.3
	if n.today_flags.get("coffee_failed", false) and o.objects["coffee"]["broken"]:
		cof *= 0.15
	opts.append([cof, {"act": "coffee", "dur": w.rng.randf_range(3.5, 5.5)}])
	opts.append([0.05 + n.social_need * 0.004, {"act": "water", "dur": w.rng.randf_range(2.0, 4.0)}])

	# --- socialise
	var partner := _chat_partner(w, n)
	if partner != "":
		var sc := n.social_need / 100.0 * (0.25 + soc) * 1.1 + float(n.affinity(partner)) * 0.004
		opts.append([sc, {"act": "chat", "target": partner}])

	# --- gossip (Zeynep & co.)
	if n.t("gossip") > 0.4:
		var g = WorldSpecials.best_gossip(w, n.id)
		if not g.is_empty():
			opts.append([n.t("gossip") * 0.42 + float(g["juice"]) * 0.22, {"act": "chat", "target": g["to"], "gossip": g["fact"]}])

	# --- rest when stressed
	opts.append([n.stress / 100.0 * (1.15 - dil * 0.6), {"act": "rest", "dur": w.rng.randf_range(6.0, 11.0)}])

	# --- wander / stretch legs
	opts.append([0.1 + (1.0 - dil) * 0.12, {"act": "wander", "dur": w.rng.randf_range(1.0, 3.0)}])

	# --- temperature
	if w.discomfort(n) > 30.0:
		opts.append([0.25 + n.t("temper") * 0.6, {"act": "thermostat"}])

	# --- role specific routines
	match n.id:
		"ahmet":
			opts.append([0.3 + (0.12 if n.goal == "keep_control" else 0.0), {"act": "patrol"}])
			if not n.reviewed_today and m > C.hm("13:45") and m < C.hm("16:15"):
				opts.append([1.25, {"act": "review"}])
			opts.append([0.35, {"act": "phone", "at_desk": true, "dur": w.rng.randf_range(4.0, 8.0)}])
		"burak":
			if n.goal == "find_new_job" and int(n.today_flags.get("calls", 0)) < 3:
				opts.append([0.2, {"act": "phone", "secret": true, "dur": w.rng.randf_range(4.0, 7.0)}])
		"mert":
			opts.append([0.2, {"act": "phone", "at_desk": true, "dur": w.rng.randf_range(3.0, 6.0)}])
		"zeynep":
			opts.append([0.22, {"act": "archive", "dur": w.rng.randf_range(4.0, 7.0)}])
		"selin":
			opts.append([0.1, {"act": "archive", "dur": w.rng.randf_range(4.0, 7.0)}])
		"ceren":
			opts.append([0.18, {"act": "archive", "dur": w.rng.randf_range(4.0, 6.0)}])
			if w.available("ahmet") and not n.today_flags.get("briefed", false) and m > 60.0:
				opts.append([0.4, {"act": "go_npc", "target": "ahmet", "prio": 20.0, "intent": {"event": "ceren_briefing", "roles": {}, "vars": {}}}])
		"ece":
			if n.goal == "be_liked" and n.coffee_count < 3 and not o.objects["coffee"]["broken"]:
				var fav := _gift_target(w, n)
				if fav != "":
					opts.append([0.32, {"act": "gift_coffee", "target": fav}])
		"deniz":
			if w.available("ahmet") and m > 90.0 and not n.today_flags.get("sucked_up", false):
				opts.append([0.35 + n.t("cunning") * 0.2, {"act": "go_npc", "target": "ahmet", "prio": 20.0, "intent": {"event": "deniz_pitch", "roles": {}, "vars": {}}}])
	if n.task_needing_print().get("archive", false):
		opts.append([0.6, {"act": "archive"}])
	if tk.get("archive", false):
		opts.append([0.7, {"act": "archive", "dur": 6.0}])

	var best: Array = []
	var bs := -1e9
	for op in opts:
		var s: float = float(op[0]) + w.rng.randf() * noise
		if s > bs:
			bs = s
			best = op
	var spec: Dictionary = best[1]
	if spec["act"] == "chat" and spec.has("gossip"):
		spec["intent"] = {"event": "gossip_share", "roles": {}, "vars": {"fact": spec["gossip"]}}
		spec["act"] = "go_npc"
		spec["prio"] = 15.0
	return spec


static func _chat_partner(w, n: NPC) -> String:
	var best := ""
	var bs := -1e9
	for id in w.present_ids():
		if id == n.id or not w.available(id):
			continue
		var t: NPC = w.npc(id)
		if t.act == "meeting" or t.act == "leave":
			continue
		var s: float = n.affinity(id) * 0.02 - n.pos.distance_to(t.pos) * 0.06 + w.rng.randf() * 0.8
		if n.id == "mert" and id == "ceren" and n.goal == "win_ceren":
			s += 1.2
		if NPCController.is_social(t):
			s += 0.6
		if n.affinity(id) < -25.0:
			s -= 2.0
		if s > bs:
			bs = s
			best = id
	return best


static func _gift_target(w, n: NPC) -> String:
	var best := ""
	var bs := -1e9
	for id in w.present_ids():
		if id == n.id or not w.available(id):
			continue
		var t: NPC = w.npc(id)
		# people she wants to win over: grumpy ones and the boss
		var s: float = -t.mood * 0.01 + w.rng.randf() + (0.6 if id == "ahmet" else 0.0) - n.affinity(id) * 0.005
		if s > bs:
			bs = s
			best = id
	return best
