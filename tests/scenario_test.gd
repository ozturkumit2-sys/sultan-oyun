extends Node
## Scenario tests: apply ONE specific intervention in a fresh office and check
## that the expected consequence chain actually happens (no player-side fakery).

var results: Array = []


func _ready() -> void:
	var scenarios := [
		{"name": "Jam printer -> someone finds it", "at": 20, "spot": "printer", "act": "break_printer", "expect": ["printer_broken"]},
		{"name": "Break coffee machine", "at": 15, "spot": "coffee_machine", "act": "break_coffee", "expect": ["coffee_broken"]},
		{"name": "Secretly fix coffee -> wrong credit / spooky", "at": 15, "spot": "coffee_machine", "act": "break_coffee", "then": {"at": 16, "spot": "coffee_machine", "act": "fix_coffee"}, "expect": ["coffee_ghost"]},
		{"name": "Burak's email to everyone", "at": 30, "spot": "ws_burak", "act": "email_all", "expect": ["email_all_scene"]},
		{"name": "Mert's email redirected to Ceren", "at": 30, "spot": "ws_mert", "act": "email_redirect", "value": "ceren", "expect": ["email_redirect_scene"]},
		{"name": "Meeting moved earlier", "at": 25, "spot": "meeting_board", "act": "move_meeting", "value": -30, "expect": ["board_noticed"], "any": ["meeting_late", "meeting_absent", "meeting_wait_timeout", "meeting_boss_late", "inform_boss_meeting"]},
		{"name": "Meeting moved later", "at": 25, "spot": "meeting_board", "act": "move_meeting", "value": 60, "expect": [], "any": ["meeting_wait_timeout", "meeting_boss_late", "meeting_late", "meeting_absent", "board_noticed"]},
		{"name": "Promotion file doctored", "at": 30, "spot": "promo_file", "act": "edit_promo", "value": "mert", "expect": ["promo_reviewed"]},
		{"name": "Selin's desk messed up", "at": 20, "spot": "ws_selin", "act": "shuffle_files", "expect": ["desk_messed"]},
		{"name": "Fake boss summons", "at": 60, "spot": "ws_mert", "act": "fake_notif", "value": "boss", "expect": ["notif_boss"], "any": ["boss_confused"]},
		{"name": "Fake free cake", "at": 60, "spot": "ws_zeynep", "act": "fake_notif", "value": "food", "expect": ["notif_food", "no_food"]},
		{"name": "Fake meeting cancellation", "at": 40, "spot": "ws_selin", "act": "fake_notif", "value": "cancel", "expect": ["notif_cancel"], "any": ["meeting_absent", "meeting_opportunity", "boss_scold"]},
		{"name": "Fake secret admirer", "at": 60, "spot": "ws_ece", "act": "fake_notif", "value": "admirer", "expect": ["notif_admirer"]},
		{"name": "Sauna temperature", "at": 30, "spot": "ac", "act": "set_temp", "value": 29, "expect": ["temp_changed"], "any": ["thermo_complaint", "thermostat_war"]},
		{"name": "Blackout", "at": 70, "spot": "lights", "act": "lights_off", "expect": ["lights_off_panic", "lights_restored"]},
		{"name": "Blackout + ghost lights on", "at": 70, "spot": "lights", "act": "lights_off", "then": {"at": 71, "spot": "lights", "act": "lights_on"}, "expect": ["lights_off_panic", "lights_on_ghost"]},
		{"name": "Selin's USB moved to Deniz's desk", "at": 20, "item": "usb", "value": "desk_deniz", "expect": [], "any": ["item_missing", "foreign_item", "item_found"]},
		{"name": "Ahmet's glasses hidden in archive", "at": 20, "item": "glasses", "value": "archive", "expect": ["item_missing"]},
	]
	var passed := 0
	for sc in scenarios:
		var ok := _run(sc)
		if ok:
			passed += 1
	print("\nSCENARIOS: %d/%d passed" % [passed, scenarios.size()])
	get_tree().quit(0 if passed == scenarios.size() else 1)


func _apply(w: SimWorld, spot: String, act_id: String, value, item := "") -> bool:
	var acts: Array
	if item != "":
		acts = Interventions.actions_for(w, "item_" + item)
	else:
		acts = Interventions.actions_for(w, spot)
	for a in acts:
		if a["id"] == act_id or (item != "" and a["id"] == "move_item"):
			if not a["enabled"]:
				return false
			var v = value
			if act_id == "move_meeting":
				v = float(w.office.objects["board"]["time"]) + float(value)
			return Interventions.apply(w, a, v)
	return false


func _run(sc: Dictionary) -> bool:
	var best_ok := false
	var detail := ""
	for seed_v in [3, 17, 29]:
		var w: SimWorld = Game.create_world()
		w.new_game(seed_v)
		var applied := false
		var applied2 := not sc.has("then")
		var stories: Array = []
		w.logged.connect(func(e): if e["imp"] >= 2 and e["cat"] != "player": stories.append(C.fmt(e["minute"]) + " " + e["text"]))
		while not w.day_over:
			w.step(0.25)
			if not applied and w.minute >= float(sc["at"]):
				applied = _apply(w, sc.get("spot", ""), sc.get("act", "move_item"), sc.get("value"), sc.get("item", ""))
				if not applied:
					detail = "could not apply"
					break
			if applied and not applied2 and w.minute >= float(sc["then"]["at"]):
				applied2 = _apply(w, sc["then"]["spot"], sc["then"]["act"], sc["then"].get("value"))
		var fired: Dictionary = w.events.fired_total
		var ok := applied and applied2
		var missing: Array = []
		for e in sc["expect"]:
			if not fired.has(e):
				ok = false
				missing.append(e)
		if sc.has("any"):
			var anyok := false
			for e in sc["any"]:
				if fired.has(e):
					anyok = true
			if not anyok:
				ok = false
				missing.append("any of " + str(sc["any"]))
		if ok:
			best_ok = true
			var rel: Array = []
			for e in sc["expect"] + sc.get("any", []):
				if fired.has(e):
					rel.append("%s×%d" % [e, fired[e]])
			detail = "seed %d: %s" % [seed_v, ", ".join(rel)]
			print("PASS  %-45s %s" % [sc["name"], detail])
			for st in stories.slice(0, 4):
				print("        %s" % st)
			break
		else:
			detail = "seed %d missing %s" % [seed_v, str(missing)]
	if not best_ok:
		print("FAIL  %-45s %s" % [sc["name"], detail])
	return best_ok
