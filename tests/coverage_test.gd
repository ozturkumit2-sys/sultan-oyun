extends Node
## Coverage & pacing: runs many seeds x days with NO player input (and some with
## random meddling) and reports which events/arcs actually happened, how far each
## story got, and how many small/medium/big moments a typical day has.
## Usage: godot --headless --path . res://tests/coverage_test.tscn -- seeds=8 days=10 meddle=0

var seeds := 8
var days := 10
var meddle := false
var meddled := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() == 2:
			match kv[0]:
				"seeds": seeds = int(kv[1])
				"days": days = int(kv[1])
				"meddle": meddle = kv[1] == "1"
	var t0 := Time.get_ticks_msec()
	var fired := {}
	var arc_started := {}
	var arc_results := {}
	var arc_depth := {}
	var arc_multi_day := {}
	var tier_days: Array = []
	var defs: Dictionary = {}
	var fails := {}
	var outcomes := {}
	var arc_ids: Array = []
	for s in seeds:
		var w: SimWorld = Game.create_world()
		w.new_game(1000 + s * 37)
		defs = w.events.defs
		arc_ids = w.director.arc_defs.keys()
		var rng := RandomNumberGenerator.new()
		rng.seed = s * 11 + 3
		for d in days:
			var next_meddle := rng.randf_range(30, 90)
			while not w.day_over:
				w.step(0.5)
				if meddle and w.minute >= next_meddle:
					next_meddle = w.minute + rng.randf_range(40, 90)
					_random_meddle(w, rng)
			for line in w.director.trace:
				if str(line).find("FAIL") >= 0:
					var key: String = str(line).split(" ")[2].trim_suffix(":")
					fails[key] = int(fails.get(key, 0)) + 1
			w.director.trace.clear()
			var t: Dictionary = w.director.tiers.duplicate()
			tier_days.append(t)
			w.next_day()
		for k in w.events.outcome_total:
			outcomes[k] = int(outcomes.get(k, 0)) + int(w.events.outcome_total[k])
		for k in w.events.fired_total:
			fired[k] = int(fired.get(k, 0)) + int(w.events.fired_total[k])
		for f in w.director.finished:
			arc_results[f["arc"] + ":" + f["result"]] = int(arc_results.get(f["arc"] + ":" + f["result"], 0)) + 1
			arc_depth[f["arc"]] = maxi(int(arc_depth.get(f["arc"], 0)), int(f.get("steps", 0)))
			if int(f["day"]) > 0:
				pass
		for k in w.flags:
			if str(k).ends_with("_last"):
				pass
		# arcs that were started (counter of instances that ever existed)
		for k in w.director.arc_last_end:
			arc_started[k] = int(arc_started.get(k, 0)) + 1
		for inst in w.director.arcs:
			arc_started[inst["arc"]] = int(arc_started.get(inst["arc"], 0)) + 1
			arc_depth[inst["arc"]] = maxi(int(arc_depth.get(inst["arc"], 0)), inst["steps"].size() + 1)
		for f in w.director.finished:
			var spans: bool = false
			arc_multi_day[f["arc"]] = arc_multi_day.get(f["arc"], false) or spans
	# --- report
	var new_ids: Array = []
	for id in defs:
		if not ORIGINAL.has(id):
			new_ids.append(id)
	new_ids.sort()
	var never: Array = []
	for id in new_ids:
		if not fired.has(id):
			never.append(id)
	print("\n=== NEW EVENTS: %d defined, %d fired at least once, %d never ===" % [new_ids.size(), new_ids.size() - never.size(), never.size()])
	print("never: " + ", ".join(never))
	var freq: Array = []
	for k in fired:
		freq.append([float(fired[k]) / float(seeds * days), k])
	freq.sort_custom(func(x, y): return x[0] > y[0])
	var top := ""
	for i in mini(30, freq.size()):
		top += "%s %.2f%s  " % [freq[i][1], freq[i][0], "[" + str(defs[freq[i][1]].get("tier", "")) + "]" if defs.has(freq[i][1]) else ""]
	print("per-day frequency (top): " + top)
	var orig_fired := 0
	for id in ORIGINAL:
		if fired.has(id):
			orig_fired += 1
	print("original events fired: %d/%d" % [orig_fired, ORIGINAL.size()])
	# independent NPC actions (initiatives) by domain
	var dom_all := {}
	var dom_fired := {}
	var init_never: Array = []
	for id in defs:
		var dd: Dictionary = defs[id]
		var tg = dd.get("trigger", "")
		if not ((typeof(tg) == TYPE_STRING and tg == "initiative") or (typeof(tg) == TYPE_ARRAY and "initiative" in tg)):
			continue
		var dm: String = str(dd.get("domain", "?"))
		dom_all[dm] = int(dom_all.get(dm, 0)) + 1
		if fired.has(id):
			dom_fired[dm] = int(dom_fired.get(dm, 0)) + 1
		else:
			init_never.append(id)
	var dl: Array = []
	var tot_i := 0
	var tot_f := 0
	for dm in dom_all:
		dl.append("%s %d/%d" % [dm, int(dom_fired.get(dm, 0)), int(dom_all[dm])])
		tot_i += int(dom_all[dm])
		tot_f += int(dom_fired.get(dm, 0))
	print("\n=== NPC ACTIONS: %d defined, %d happened on their own === %s" % [tot_i, tot_f, ", ".join(dl)])
	print("NPC actions that never happened: " + ", ".join(init_never))
	if meddle:
		print("interventions used by the random meddler: %d" % meddled.size())
	print("\n=== ARCS ===")
	arc_ids.sort()
	for a in arc_ids:
		var res: Array = []
		for k in arc_results:
			if k.begins_with(a + ":"):
				res.append("%s x%d" % [k.substr(a.length() + 1), arc_results[k]])
		print("  %-18s started~%d  deepest=%d  results: %s" % [a, int(arc_started.get(a, 0)), int(arc_depth.get(a, 0)), ", ".join(res)])
	var fl: Array = []
	for k in fails:
		fl.append("%s x%d" % [k, fails[k]])
	fl.sort()
	print("stage failures (timeouts/unmet): " + ", ".join(fl))
	# outcomes of new multi-outcome events that never happened
	var never_out: Array = []
	for id in new_ids:
		for o in defs[id].get("outcomes", []):
			var key: String = id + "/" + str(o.get("id", ""))
			if not outcomes.has(key):
				never_out.append(key)
	print("outcomes never taken (%d): %s" % [never_out.size(), ", ".join(never_out)])
	var sm := 0.0
	var md := 0.0
	var bg := 0.0
	var beats := 0.0
	var big_days := 0
	for t in tier_days:
		sm += float(t.get("small", 0))
		md += float(t.get("medium", 0))
		bg += float(t.get("big", 0))
		beats += float(t.get("beat", 0))
		if int(t.get("big", 0)) > 0 or int(t.get("beat", 0)) > 0:
			big_days += 1
	var n := float(tier_days.size())
	print("\n=== PACING (per day, %d days) === small %.1f  medium %.1f  big starts %.2f  story beats %.1f  days with a big story moving: %d%%" % [
		tier_days.size(), sm / n, md / n, bg / n, beats / n, int(100.0 * big_days / n)])
	print("elapsed %.1fs" % ((Time.get_ticks_msec() - t0) / 1000.0))
	get_tree().quit(0)


func _random_meddle(w: SimWorld, rng: RandomNumberGenerator) -> void:
	var spots: Array = []
	for o in w.iv.by_obj.keys():
		if o != "ws" and o != "item":
			spots.append(o)
	for id in C.NPC_IDS:
		spots.append("ws_" + id)
	for it in w.office.items:
		spots.append("item_" + it)
	var spot: String = spots[rng.randi() % spots.size()]
	var acts: Array = w.iv.actions_for(spot)
	var en: Array = acts.filter(func(a): return a["enabled"])
	if en.is_empty():
		return
	var act: Dictionary = en[rng.randi() % en.size()]
	act["spot"] = spot
	var val = null
	if str(act.get("needs", "")) != "":
		var opts: Array = w.iv.options_for(act).filter(func(o): return o["enabled"])
		if opts.is_empty():
			return
		val = opts[rng.randi() % opts.size()]["value"]
		if InterventionManager.two_step(act.get("def", {})):
			var second: Array = w.iv.options_for(act, val)
			val = second[rng.randi() % second.size()]["value"]
	if w.iv.apply(act, val):
		meddled[str(act.get("iv", ""))] = true


const ORIGINAL := ["printer_broken", "help_request", "lights_restored", "fix_done", "coffee_broken", "coffee_ghost", "thank_wrong_person", "it_patrol",
	"lights_off_panic", "ece_spill", "dark_scheme", "lights_on_ghost", "dark_bonding", "temp_changed", "thermo_complaint", "thermostat_war", "thermo_argument",
	"desk_messed", "ece_tidy_help", "ece_tidy_scene", "zeynep_knows", "accusation", "defense", "big_fight", "manager_outburst", "item_missing", "item_found",
	"foreign_item", "item_returned", "email_all_scene", "email_redirect_scene", "email_confront", "crush_exposed", "tease_crush", "board_noticed",
	"inform_boss_meeting", "board_changed", "meeting_start", "meeting_boss_late", "meeting_late", "meeting_wait_timeout", "meeting_absent", "boss_scold",
	"meeting_present", "credit_steal", "credit_fight", "meeting_opportunity", "meeting_banter", "promo_reviewed", "promo_reviewed_clean", "ceren_notices_promo",
	"ceren_tells_victim", "promotion", "promo_grudge", "notif_boss", "notif_food", "notif_cancel", "notif_admirer", "boss_confused", "no_food", "admirer_ask",
	"boss_learns_job_hunt", "job_hunt_talk", "nepotism_reveal", "review_shock", "secret_call", "gossip_share", "flirt", "couple_forms", "secret_friends_spotted",
	"jealousy", "reconciliation", "grudge_flare", "small_talk", "coffee_gift", "ceren_briefing", "deniz_pitch", "manager_check", "workload_vent",
	"unexpected_solidarity", "solidarity_help", "deadline_missed", "late_to_work", "office_ghost_theory", "clique_lunch"]
