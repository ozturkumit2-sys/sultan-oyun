class_name MeetingFlow
extends RefCounted
## The daily team meeting (who shows up when, based on what each person *believes*
## the meeting time is), the boss's review of the promotion file, and the
## promotion announcements.


static func check_board(w, n: NPC) -> void:
	var bt := float(w.office.objects["board"]["time"])
	if n.meeting_belief < 0.0 or w.meeting.get("ended", false):
		return
	if absf(n.meeting_belief - bt) < 0.5:
		return
	var p := 0.08 + n.t("diligence") * 0.22
	if n.id == "ceren":
		p = 0.85
	if w.rng.randf() < p:
		var old := n.meeting_belief
		n.meeting_belief = bt
		if n.meeting_state == "missed":
			return
		w.events.fire("board_noticed", {"actor": n.id, "old_time": old, "new_time": bt})


static func arrive(w, n: NPC) -> void:
	var mt: Dictionary = w.meeting
	n.pose = "sit"
	if mt.get("ended", false):
		n.meeting_state = "done"
		return
	if n.id == "ahmet":
		if not mt["started"]:
			mt["started"] = true
			mt["start_min"] = w.minute
			n.meeting_state = "in"
			var waited := 0.0
			for id in w.present_ids():
				var o: NPC = w.npc(id)
				if o.act == "meeting" and o.meeting_state == "waiting":
					o.meeting_state = "in"
					waited = maxf(waited, w.minute - o.meeting_wait)
			w.log_event("log.meeting_start", {"roles": {"actor": "ahmet"}}, 1, "meeting", ["ahmet"])
			if waited > 7.0:
				w.events.fire("meeting_boss_late", {"actor": "ahmet", "waited": int(waited)})
			else:
				w.events.fire("meeting_start", {"actor": "ahmet"})
		return
	if mt["started"]:
		n.meeting_state = "in"
		if w.minute - float(mt["start_min"]) > 3.0:
			n.today_flags["late_meeting"] = true
			w.stats.add("late_arrivals")
			w.events.fire("meeting_late", {"actor": n.id, "target": "ahmet", "late": int(w.minute - float(mt["start_min"]))})
	else:
		n.meeting_state = "waiting"
		n.meeting_wait = w.minute


static func should_leave(w, n: NPC) -> bool:
	var mt: Dictionary = w.meeting
	if mt.get("ended", false):
		n.meeting_state = "done"
		return true
	if n.meeting_state == "waiting" and w.minute - n.meeting_wait > 18.0:
		n.meeting_state = "missed"
		w.events.fire("meeting_wait_timeout", {"actor": n.id})
		return true
	if n.meeting_state in ["done", "missed"]:
		return true
	if n.meeting_belief == -2.0:
		return true
	return false


static func update(w, _d: float) -> void:
	var mt: Dictionary = w.meeting
	if mt.is_empty() or not mt.get("started", false) or mt.get("ended", false):
		return
	var el: float = w.minute - float(mt["start_min"])
	var presented: int = int(mt.get("presented", 0))
	if el > 6.0 and presented == 0:
		mt["presented"] = 1
		_present(w, 0)
	elif el > 15.0 and presented == 1:
		mt["presented"] = 2
		_present(w, 1)
	elif el > 22.0 and presented == 2:
		mt["presented"] = 3
		w.events.fire("meeting_banter", {"actor": "ahmet"})
	if el > 28.0 or (el > 10.0 and _count_in(w) == 0):
		_end_meeting(w)


static func _count_in(w) -> int:
	var c := 0
	for id in w.present_ids():
		if id == "ahmet":
			continue
		var n: NPC = w.npc(id)
		if n.act == "meeting" and n.meeting_state == "in" and n.phase == "do":
			c += 1
	return c


static func in_room(w) -> Array:
	var r: Array = []
	for id in w.present_ids():
		var n: NPC = w.npc(id)
		if n.act == "meeting" and n.meeting_state == "in" and n.phase == "do":
			r.append(id)
	return r


static func _present(w, slot: int) -> void:
	var room := in_room(w)
	if not ("ahmet" in room):
		return
	# who presents: people with a meeting deliverable, otherwise anyone
	var cands: Array = []
	for id in room:
		if id == "ahmet":
			continue
		var n: NPC = w.npc(id)
		for tk in n.tasks:
			if tk.get("deadline", "") == "meeting" and not n.today_flags.get("presented", false):
				cands.append(id)
				break
	if cands.is_empty():
		for id in room:
			if id != "ahmet" and not w.npc(id).today_flags.get("presented", false):
				cands.append(id)
	if cands.is_empty():
		return
	w.shuffle(cands)
	if slot == 0 and "selin" in cands:
		cands.erase("selin")
		cands.push_front("selin")
	var pid: String = cands[0]
	var pn: NPC = w.npc(pid)
	pn.today_flags["presented"] = true
	var prepared := true
	var has_usb := true
	for tk in pn.tasks:
		if tk.get("deadline", "") == "meeting":
			if tk["left"] > 0.0:
				prepared = false
			if tk.get("print", false) and not tk.get("printed", false):
				prepared = false
			if tk.get("usb", false):
				has_usb = w.office.items["usb"]["at"] == "desk_selin" or w.office.items["usb"]["at"] == "meeting"
	if not has_usb:
		prepared = false
	var rival := ""
	if pid == "selin" and "deniz" in room:
		rival = "deniz"
	elif pid == "deniz" and "selin" in room:
		rival = "selin"
	w.events.fire("meeting_present", {"actor": pid, "target": "ahmet", "other": rival, "prepared": prepared, "has_usb": has_usb})
	# a missing star presenter is an opportunity for someone cunning
	if slot == 0 and not ("selin" in room) and "deniz" in room and w.npc("selin") != null and w.npc("selin").present:
		w.events.fire("meeting_opportunity", {"actor": "deniz", "target": "ahmet", "victim": "selin"})


static func _end_meeting(w) -> void:
	var mt: Dictionary = w.meeting
	mt["ended"] = true
	var absent: Array = []
	for id in mt.get("attendees", []):
		var n: NPC = w.npc(id)
		if n == null or id == "ahmet":
			continue
		if n.present and not (n.act == "meeting" and n.meeting_state == "in"):
			absent.append(id)
	for id in w.present_ids():
		var n2: NPC = w.npc(id)
		if n2.act == "meeting":
			n2.meeting_state = "done"
		n2.meeting_belief = -1.0
	w.log_event("log.meeting_end", {"roles": {"actor": "ahmet"}}, 1, "meeting", ["ahmet"])
	for id in absent:
		w.events.fire("meeting_absent", {"actor": id, "target": "ahmet"})


# ------------------------------------------------------------------ promotion

static func promotion_today(w) -> bool:
	return w.day % 3 == 0


static func candidates(w) -> Array:
	if w.promo_cycle == 1:
		return ["selin", "deniz"]
	var r: Array = []
	for id in w.order:
		if id == "ahmet" or w.npc(id).promoted:
			continue
		r.append(id)
	return r


## Ahmet reads the promotion recommendation file at his desk.
static func promo_review(w, n: NPC) -> void:
	var pr: Dictionary = w.office.objects["promo"]
	if pr.get("reviewed", false):
		return
	pr["reviewed"] = true
	if pr.get("altered", false) and pr.get("credit", "") != "":
		var credited: String = pr["credit"]
		# who was the real front-runner?
		var cands := candidates(w)
		var orig := ""
		var bf := -1.0
		for c in cands:
			if c != credited and float(w.favor.get(c, 0.0)) > bf:
				bf = float(w.favor.get(c, 0.0))
				orig = c
		w.favor[credited] = clampf(float(w.favor.get(credited, 40.0)) + 22.0, 0, 100)
		w.favor_ghost[credited] = float(w.favor_ghost.get(credited, 0.0)) + 22.0
		if orig != "":
			w.favor[orig] = clampf(float(w.favor.get(orig, 40.0)) - 12.0, 0, 100)
			w.favor_ghost[orig] = float(w.favor_ghost.get(orig, 0.0)) - 12.0
		pr["altered"] = false
		w.flags["promo_tampered_cycle"] = w.promo_cycle
		w.events.fire("promo_reviewed", {"actor": n.id, "credited": credited, "victim": orig})
	else:
		w.events.fire("promo_reviewed_clean", {"actor": n.id})


static func announce(w, n: NPC) -> void:
	if w.day_flags.get("promotion_done", false):
		return
	w.day_flags["promotion_done"] = true
	var cands := candidates(w)
	var present: Array = []
	for c in cands:
		if w.npc(c).present:
			present.append(c)
	if present.is_empty():
		present = cands
	var winner := ""
	var bf := -1e9
	var honest_winner := ""
	var hb := -1e9
	for c in present:
		var f: float = float(w.favor.get(c, 0.0)) + w.rng.randf() * 3.0
		if f > bf:
			bf = f
			winner = c
		var fh := f - float(w.favor_ghost.get(c, 0.0))
		if fh > hb:
			hb = fh
			honest_winner = c
	var runner := ""
	var rb := -1e9
	for c in present:
		if c != winner and float(w.favor.get(c, 0.0)) > rb:
			rb = float(w.favor.get(c, 0.0))
			runner = c
	var rigged: bool = honest_winner != winner and w.flags.get("promo_tampered_cycle", -1) == w.promo_cycle
	var kind := "promotion" if w.promo_cycle == 1 else "award"
	var wn: NPC = w.npc(winner)
	if kind == "promotion":
		wn.promoted = true
		wn.title_override = w.T("title.team_lead")
	else:
		wn.title_override = w.T("title.employee_week")
	w.hold(w.present_ids(), 5.0)
	w.events.fire("promotion", {"actor": n.id, "winner": winner, "loser": runner, "rigged": rigged, "kind": kind, "honest": honest_winner})
	if rigged:
		w.stats.add("broken_promotions")
	# next cycle
	w.promo_cycle += 1
	w.favor_ghost.clear()
	if winner != "":
		w.favor[winner] = maxf(20.0, float(w.favor.get(winner, 40.0)) - 25.0)
