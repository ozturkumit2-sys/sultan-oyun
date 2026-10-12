class_name NPCSchedule
extends RefCounted
## Daily plan per character: arrival, lunch, leaving, tasks; and the mandatory
## parts of the routine (arrive, meeting, lunch, leave, boss duties).


static func plan_day(w, n: NPC) -> void:
	var sch: Dictionary = n.def.get("schedule", {})
	var arr: Array = sch.get("arrive", [0, 8])
	n.arrive_at = w.rng.randf_range(float(arr[0]), float(arr[1]))
	# someone who had a terrible day yesterday may drag their feet
	if n.mood < -30.0:
		n.arrive_at += w.rng.randf_range(4, 14)
	var lu: Array = sch.get("lunch", [210, 240])
	n.lunch_at = w.rng.randf_range(float(lu[0]), float(lu[1]))
	var lv: Array = sch.get("leave", [520, 535])
	n.leave_at = w.rng.randf_range(float(lv[0]), float(lv[1]))
	n.tasks.clear()
	var pool: Array = n.def.get("tasks", [])
	if not pool.is_empty():
		var idxs: Array = range(pool.size())
		w.shuffle(idxs)
		var count := 1 if pool.size() == 1 else (2 if w.rng.randf() < 0.65 else 1)
		# meeting-deadline tasks are always on the list on meeting days
		for i in pool.size():
			if pool[i].get("deadline", "") == "meeting" and not idxs.slice(0, count).has(i):
				idxs.erase(i)
				idxs.push_front(i)
		for k in range(min(count, idxs.size())):
			var tp: Dictionary = pool[idxs[k]]
			var units: Array = tp.get("units", [30, 45])
			var tot: float = w.rng.randf_range(float(units[0]), float(units[1]))
			n.tasks.append({
				"id": tp["id"], "total": tot, "left": tot, "deadline": tp.get("deadline", "17:00"),
				"print": tp.get("print", false), "printed": false, "usb": tp.get("usb", false),
				"phone": tp.get("phone", false), "archive": tp.get("archive", false),
			})


static func task_deadline(w, n: NPC, tk: Dictionary) -> float:
	var dl: String = tk.get("deadline", "17:00")
	if dl == "meeting":
		var b := n.meeting_belief
		if b < 0.0:
			b = float(w.meeting.get("time", 120.0))
		return b
	return C.hm(dl)


## Returns a mandatory activity spec, or {} when the person is free to choose.
static func mandatory(w, n: NPC) -> Dictionary:
	var m: float = w.minute
	if not n.present:
		if n.state == NPC.S.OUTSIDE and m >= n.arrive_at and m < n.leave_at - 20.0:
			return {"act": "arrive", "place": "desk_" + n.id, "prio": 95.0}
		return {}
	if m >= n.leave_at and n.act != "leave":
		if not (n.act == "meeting" and w.meeting.get("started", false) and not w.meeting.get("ended", false)):
			return {"act": "leave", "prio": 95.0}
	# meeting
	if n.meeting_belief >= 0.0 and n.meeting_state == "" and not w.meeting.get("ended", false):
		var travel := n.pos.distance_to(Vector2(1.5, 1.5)) / C.WALK_SPEED + 1.5
		if m >= n.meeting_belief - travel and m < n.meeting_belief + 45.0:
			var seat := "m1" if n.id == "ahmet" else ""
			return {"act": "meeting", "place": seat, "prio": 85.0}
	# Ahmet's promotion announcement
	if n.id == "ahmet" and MeetingFlow.promotion_today(w) and not w.day_flags.get("promotion_done", false) and m >= C.hm("16:20"):
		return {"act": "announce", "place": "announce", "prio": 88.0}
	# lunch
	if not n.lunch_done and m >= n.lunch_at and m < n.lunch_at + 60.0:
		return {"act": "lunch", "prio": 40.0}
	return {}
