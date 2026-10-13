class_name NPCController
extends RefCounted
## NPCController: executes activities — walking along paths, using objects,
## sitting, working — and fires the simulation hooks that events listen to.

const SOCIAL_ACTS := ["coffee", "water", "lunch", "rest", "wander", "idle", "chat"]
const DEFAULT_DUR := {
	"arrive": 1.0, "work": 40.0, "coffee": 4.0, "water": 3.0, "chat": 1.0, "print": 3.0, "archive": 6.0,
	"phone": 6.0, "rest": 9.0, "patrol": 1.0, "meeting": 70.0, "lunch": 38.0, "leave": 1.0, "review": 14.0,
	"wander": 2.0, "thermostat": 1.0, "fix": 7.0, "go_npc": 0.6, "go_place": 2.0, "search": 1.2,
	"idle": 2.0, "announce": 6.0, "return_item": 0.6, "gift_coffee": 3.0, "go_desk": 0.8, "away": 0.5,
}


static func is_social(n: NPC) -> bool:
	if not n.present or n.phase != "do":
		return false
	if n.act in SOCIAL_ACTS:
		return true
	return n.act == "meeting" and n.meeting_state == "waiting"


static func cur_prio(n: NPC) -> float:
	if n.act == "":
		return -1.0
	return float(n.act_data.get("prio", 10.0))


static func update(w, n: NPC, d: float) -> void:
	var secs := d / C.MIN_PER_SEC
	if n.expr_timer > 0.0:
		n.expr_timer -= secs
		if n.expr_timer <= 0.0:
			n.expr = "normal"
	if n.emote_timer > 0.0:
		n.emote_timer -= secs
		if n.emote_timer <= 0.0:
			n.emote = ""
	if n.speaking > 0.0:
		n.speaking -= secs
	if not n.present:
		if n.state == NPC.S.OUTSIDE:
			var mand := NPCSchedule.mandatory(w, n)
			if not mand.is_empty():
				start(w, n, mand)
		return
	if n.hold_until > w.minute:
		if n.pose == "walk":
			n.pose = "stand"
		return
	# interrupts: mandatory routine and urgent intentions
	var mand2 := NPCSchedule.mandatory(w, n)
	if not mand2.is_empty() and mand2["act"] != n.act and float(mand2["prio"]) > cur_prio(n):
		start(w, n, mand2)
		return
	var it := n.top_intent(w.minute)
	if not it.is_empty() and float(it["prio"]) > cur_prio(n) + 5.0 and n.act_data.get("intent", {}) != it:
		start_intent(w, n, it)
		return
	match n.phase:
		"walk":
			_walk(w, n, d)
		"do":
			_do(w, n, d)
		_:
			choose(w, n)


static func choose(w, n: NPC) -> void:
	var mand := NPCSchedule.mandatory(w, n)
	if not mand.is_empty():
		start(w, n, mand)
		return
	var it := n.top_intent(w.minute)
	if not it.is_empty():
		start_intent(w, n, it)
		return
	start(w, n, NPCBrain.choose(w, n))


static func start_intent(w, n: NPC, it: Dictionary) -> void:
	n.remove_intent(it)
	var tgt: String = it.get("target", "")
	if tgt != "" and not w.available(tgt) and it["type"] == "go_npc":
		# can't reach them right now; try later if still relevant
		if float(it.get("until", 0.0)) > w.minute + 5.0 and w.npc(tgt) != null and w.npc(tgt).present:
			it["wait_until"] = w.minute + 3.0
			n.add_intent(it)
		if n.act == "":
			start(w, n, NPCBrain.choose(w, n))
		return
	var spec := {"prio": float(it["prio"]), "intent": it}
	match it["type"]:
		"go_npc":
			spec["act"] = "go_npc"
			spec["target"] = tgt
		"go_place":
			spec["act"] = "go_place"
			spec["place"] = it.get("place", "")
			spec["dur"] = float(it.get("dur", 2.0))
		"fix":
			spec["act"] = "fix"
			spec["obj"] = it.get("obj", "printer")
			spec["place"] = {"printer": "printer", "coffee": "coffee", "lights": "breaker"}.get(spec["obj"], "printer")
			spec["requester"] = it.get("roles", {}).get("requester", "")
		"search":
			spec["act"] = "search"
			spec["item"] = it.get("vars", {}).get("item", "")
		"thermostat":
			spec["act"] = "thermostat"
			spec["place"] = "thermostat"
		"return_item":
			spec["act"] = "return_item"
			spec["target"] = tgt
			spec["item"] = it.get("vars", {}).get("item", "")
		"gift_coffee":
			spec["act"] = "gift_coffee"
			spec["place"] = "coffee"
			spec["target"] = tgt
		"go_desk":
			spec["act"] = "go_desk"
			spec["owner"] = tgt
			spec["target"] = ""
		_:
			spec["act"] = "go_place"
			spec["place"] = it.get("place", "")
	start(w, n, spec)


static func _place_for(w, n: NPC, spec: Dictionary) -> String:
	var o: OfficeEnv = w.office
	var act: String = spec["act"]
	var p: String = spec.get("place", "")
	if p != "" and act != "meeting":
		return p
	match act:
		"arrive", "work", "review":
			return "desk_" + n.id
		"coffee", "gift_coffee":
			return "coffee"
		"water":
			return "water"
		"print":
			return "printer"
		"archive":
			return "archive"
		"thermostat":
			return "thermostat"
		"rest":
			return o.free_place_with_tag("rest", w.rng, null, n.id)
		"phone":
			if spec.get("at_desk", false):
				return "desk_" + n.id
			return o.free_place_with_tag("phone", w.rng, null, n.id)
		"wander", "idle":
			return o.free_place_with_tag("wander", w.rng, null, n.id)
		"meeting":
			if n.id == "ahmet" and (o.places["m1"]["occupant"] == "" or o.places["m1"]["occupant"] == "ahmet"):
				return "m1"
			for i in range(2, 9):
				var pid := "m%d" % i
				if o.places[pid]["occupant"] == "" or o.places[pid]["occupant"] == n.id:
					return pid
			return ""
		"lunch":
			return _lunch_place(w, n)
		"leave":
			return "entrance"
		"search":
			return ""
	return ""


static func _lunch_place(w, n: NPC) -> String:
	var o: OfficeEnv = w.office
	if n.id in ["burak", "selin"] and w.rng.randf() < 0.5:
		return "desk_" + n.id
	var best := ""
	var bs := -1e9
	for pid in o.places_with_tag("lunch"):
		var occ: String = o.places[pid]["occupant"]
		if occ != "" and occ != n.id:
			continue
		var s: float = w.rng.randf() * 10.0
		# sit near people you like, away from people you dislike
		for other in w.present_ids():
			if other == n.id:
				continue
			var on: NPC = w.npc(other)
			if on.act == "lunch" and on.act_place != "":
				var dd: float = o.place_pos(pid).distance_to(o.place_pos(on.act_place))
				if dd < 2.6:
					s += n.affinity(other) * 0.4
					if w.has_bond(n.id, other, "feud"):
						s -= 40.0
					elif w.has_bond(n.id, other, "romance") or w.has_bond(n.id, other, "alliance"):
						s += 25.0
		if s > bs:
			bs = s
			best = pid
	if best == "":
		return "desk_" + n.id
	return best


static func start(w, n: NPC, spec: Dictionary) -> void:
	var o: OfficeEnv = w.office
	if n.act_place != "":
		o.release(n.act_place, n.id)
	n.act = spec.get("act", "idle")
	n.act_data = spec.duplicate(true)
	if not n.act_data.has("prio"):
		n.act_data["prio"] = 10.0
	n.act_t = 0.0
	n.act_dur = float(spec.get("dur", DEFAULT_DUR.get(n.act, 3.0)))
	n.act_target = spec.get("target", "")
	n.act_data["walk_t"] = 0.0
	n.current_activity_label = n.act
	var place := _place_for(w, n, spec)
	if place != "" and o.places.has(place):
		var occ: String = o.places[place]["occupant"]
		if occ != "" and occ != n.id:
			# taken: look for a free place with the same tag
			var tags: Array = o.places[place]["tags"]
			var alt := ""
			if not tags.is_empty() and not ("desk" in tags):
				alt = o.free_place_with_tag(tags[0], w.rng, o.place_pos(place), n.id)
			if alt == "":
				if n.act in ["work", "review", "arrive"]:
					place = ""   # someone sits at my desk?! just stand nearby
				else:
					n.act = "idle"
					n.act_dur = 1.5
					place = o.free_place_with_tag("wander", w.rng, n.pos, n.id)
			else:
				place = alt
	n.act_place = place
	if place != "":
		o.reserve(place, n.id)
	# --- path
	if n.act == "arrive":
		n.present = true
		n.state = NPC.S.WALKING
		n.pos = OfficeEnv.OUTSIDE
		n.path = PackedVector2Array([Vector2(13.6, 11.5)])
		n.path.append_array(o.find_path(Vector2(13.5, 11.5), o.place_cell(place), o.place_pos(place)))
	elif n.act == "leave" or n.act == "away":
		if place != "":
			o.release(place, n.id)
			n.act_place = ""
		n.path = o.find_path(n.pos, o.place_cell("entrance"))
		n.path.append(Vector2(14.2, 11.5))
		n.path.append(OfficeEnv.OUTSIDE)
	elif n.act == "go_desk":
		n.path = o.find_path(n.pos, _desk_side(w, n, str(n.act_data.get("owner", ""))))
	elif n.act_target != "" and place == "":
		n.path = _path_to_npc(w, n, n.act_target)
	elif n.act == "search":
		_setup_search(w, n)
		return
	elif n.act == "patrol":
		_setup_patrol(w, n)
		return
	elif place != "":
		n.path = o.find_path(n.pos, o.place_cell(place), o.place_pos(place))
	else:
		n.path = PackedVector2Array()
	n.path_i = 0
	n.phase = "walk"
	n.state = NPC.S.WALKING
	if n.path.is_empty() or (n.path.size() == 1 and n.pos.distance_to(n.path[0]) < 0.05):
		_arrive(w, n)
	else:
		n.pose = "walk"


## A free cell right next to someone's desk chair (to talk to them, snoop, leave a note...).
static func _desk_side(w, n: NPC, owner: String) -> Vector2i:
	var o: OfficeEnv = w.office
	var pid := "desk_" + owner
	if not o.places.has(pid):
		return OfficeEnv.cell_of(n.pos)
	var tc := o.place_cell(pid)
	var best := tc
	var bd := 1e9
	for off in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var c: Vector2i = tc + off
		if not o.walkable(c):
			continue
		var dd := (Vector2(c) + Vector2(0.5, 0.5)).distance_to(n.pos)
		if dd < bd:
			bd = dd
			best = c
	return best


static func _path_to_npc(w, n: NPC, tid: String) -> PackedVector2Array:
	var t: NPC = w.npc(tid)
	if t == null:
		return PackedVector2Array()
	var o: OfficeEnv = w.office
	var tc := OfficeEnv.cell_of(t.pos)
	# stand on a free neighbouring cell, preferring the side facing us
	var best := tc
	var bd := 1e9
	for off in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var c: Vector2i = tc + off
		if not o.walkable(c):
			continue
		var dd := (Vector2(c) + Vector2(0.5, 0.5)).distance_to(n.pos)
		if dd < bd:
			bd = dd
			best = c
	return o.find_path(n.pos, best)


static func _walk(w, n: NPC, d: float) -> void:
	n.act_data["walk_t"] = float(n.act_data.get("walk_t", 0.0)) + d
	var speed := C.WALK_SPEED * float(n.def.get("speed", 1.0))
	if not w.office.objects["lights"]["on"]:
		speed *= 0.6
	var step := speed * d
	# chasing a person: re-path periodically, stop when close
	if n.act_target != "" and n.act_place == "" and not (n.act in ["search", "patrol"]):
		var t: NPC = w.npc(n.act_target)
		if t == null or not t.present or float(n.act_data["walk_t"]) > 25.0:
			_end(w, n)
			return
		if n.pos.distance_to(t.pos) < 1.35:
			_arrive(w, n)
			return
		n.repath_t += d
		if n.repath_t > 1.2:
			n.repath_t = 0.0
			n.path = _path_to_npc(w, n, n.act_target)
			n.path_i = 0
	if float(n.act_data["walk_t"]) > 45.0:
		# hopelessly stuck — teleport-free recovery: give up
		_end(w, n)
		return
	while step > 0.0 and n.path_i < n.path.size():
		var tgt: Vector2 = n.path[n.path_i]
		var v := tgt - n.pos
		var dist := v.length()
		if dist > 0.001:
			var sx := v.x - v.y
			var sy := v.x + v.y
			if absf(sx) > 0.02:
				n.face_right = sx > 0.0
			n.face_front = sy >= 0.0
		if dist <= step:
			n.pos = tgt
			step -= dist
			n.path_i += 1
		else:
			n.pos += v / dist * step
			step = 0.0
	n.pose = "walk"
	if n.path_i >= n.path.size():
		if n.act_target != "" and n.act_place == "" and not (n.act in ["search", "patrol"]):
			var t2: NPC = w.npc(n.act_target)
			if t2 and n.pos.distance_to(t2.pos) < 2.2:
				_arrive(w, n)
			else:
				n.path = _path_to_npc(w, n, n.act_target)
				n.path_i = 0
				if n.path.is_empty():
					_arrive(w, n)
		else:
			_arrive(w, n)


static func _arrive(w, n: NPC) -> void:
	n.phase = "do"
	n.state = NPC.S.ACTING
	var o: OfficeEnv = w.office
	if n.act_place != "" and o.places.has(n.act_place):
		var p: Dictionary = o.places[n.act_place]
		n.pos = o.place_pos(n.act_place)
		var f: String = p.get("facing", "SE")
		n.face_front = f in ["SE", "SW"]
		n.face_right = f in ["SE", "NE"]
		n.pose = "sit" if p.get("pose", "stand") == "sit" else "stand"
	else:
		n.pose = "stand"
	if n.act_target != "":
		w.face_toward(n, n.act_target)
	_begin(w, n)


# ---------------------------------------------------------------- activity begin hooks

static func _begin(w, n: NPC) -> void:
	var o: OfficeEnv = w.office
	match n.act:
		"arrive":
			n.pose = "sit"
			if n.today_flags.has("away"):
				var why: String = str(n.today_flags["away"])
				n.today_flags.erase("away")
				w.events.fire("returned", {"actor": n.id, "reason": why})
			elif w.minute > 22.0 and not n.today_flags.get("late_work", false):
				n.today_flags["late_work"] = true
				w.events.fire("late_to_work", {"actor": n.id, "late": int(w.minute)})
			_desk_checks(w, n)
		"work":
			if n.act_place != "desk_" + n.id:
				n.pose = "stand"
			else:
				n.pose = "type"
				_desk_checks(w, n)
				if o.objects["email"].has(n.id):
					n.act_data["email_at"] = w.rng.randf_range(0.6, 2.0)
			n.act_data["board_t"] = 0.0
		"review":
			if o.items["glasses"]["at"] != "desk_ahmet":
				n.act_dur = 0.5
				_need_item(w, n, "glasses")
			else:
				n.pose = "read"
		"coffee":
			var c: Dictionary = o.objects["coffee"]
			if c["broken"]:
				n.act_dur = 1.6
				n.today_flags["coffee_failed"] = true
				c["discovered"] = true
				w.events.fire("object_failed", {"actor": n.id, "obj": "coffee"})
				if not w.day_flags.get("coffee_found", false):
					w.stats.add("breakdowns")
					w.day_flags["coffee_found"] = true
			elif n.id == "mert" and o.items["mug"]["at"] != "desk_mert" and not n.today_flags.get("searching_mug", false):
				n.act_dur = 0.5
				_need_item(w, n, "mug")
			else:
				n.pose = "coffee"
				if c.get("ghost_fixed", false):
					c["ghost_fixed"] = false
					w.events.fire("coffee_ghost", {"actor": n.id})
				c["last_user"] = n.id
				w.sfx.emit("coffee")
		"gift_coffee":
			var c2: Dictionary = o.objects["coffee"]
			if c2["broken"]:
				n.act_dur = 1.0
				n.act_data.erase("target")
				n.act_target = ""
			else:
				n.pose = "coffee"
		"print":
			var pr: Dictionary = o.objects["printer"]
			if pr["broken"]:
				n.act_dur = 1.6
				pr["discovered"] = true
				w.events.fire("object_failed", {"actor": n.id, "obj": "printer"})
				if not w.day_flags.get("printer_found", false):
					w.stats.add("breakdowns")
					w.day_flags["printer_found"] = true
			else:
				pr["last_user"] = n.id
				w.sfx.emit("printer")
		"fix":
			var obj: String = n.act_data.get("obj", "printer")
			var broken := false
			if obj == "lights":
				broken = not o.objects["lights"]["on"]
			else:
				broken = o.objects[obj]["broken"]
			if not broken:
				n.act_dur = 0.4
			else:
				o.objects[obj]["fixing"] = n.id
				n.pose = "fix"
				n.act_dur = 1.6 if obj == "lights" else w.rng.randf_range(5.0, 8.0)
		"thermostat":
			# stubborn people set their own favourite, everyone else restores "normal"
			var pref := int(n.prefs.get("temp", 22)) if n.t("temper") > 0.65 else 22
			var prev := int(o.objects["ac"]["temp"])
			if prev != pref:
				o.objects["ac"]["temp"] = pref
				o.objects["ac"]["set_by"] = n.id
				w.office_changed.emit("ac")
				w.events.fire("thermostat_changed", {"actor": n.id, "temp": pref, "prev": prev})
		"phone":
			n.pose = "phone"
			if n.act_data.get("secret", false):
				n.today_flags["calls"] = int(n.today_flags.get("calls", 0)) + 1
				w.events.fire("secret_call", {"actor": n.id})
		"archive":
			n.pose = "search"
		"rest":
			n.pose = "sit" if n.pose == "sit" else "stand"
		"lunch":
			n.lunch_done = true
			if str(n.today_flags.get("lunch_stolen", "")) != "":
				var thief: String = str(n.today_flags["lunch_stolen"])
				n.today_flags.erase("lunch_stolen")
				w.events.fire("lunch_stolen", {"actor": thief, "target": n.id})
			n.pose = "eat" if n.pose == "sit" else "eat"
			if not w.lunch_fired:
				w.lunch_fired = true
				w.events.fire("lunch_start", {"actor": n.id})
		"meeting":
			MeetingFlow.arrive(w, n)
		"announce":
			MeetingFlow.announce(w, n)
		"go_npc":
			var it: Dictionary = n.act_data.get("intent", {})
			var tgt: String = n.act_target
			if it.get("event", "") != "" and w.available(tgt):
				var roles: Dictionary = {"actor": n.id, "target": tgt}
				for k in it.get("roles", {}):
					if not roles.has(k):
						roles[k] = it["roles"][k]
				w.events.run_event(it["event"], roles, it.get("vars", {}))
			elif it.get("event", "") != "" and w.npc(tgt) != null and w.npc(tgt).present and float(it.get("until", 0.0)) > w.minute + 2.0 \
					and int(it.get("retries", 0)) < 5:
				# they're busy talking to someone else: wait a moment, then try again
				var again: Dictionary = it.duplicate(true)
				again["retries"] = int(it.get("retries", 0)) + 1
				again["wait_until"] = w.minute + 1.5
				n.add_intent(again)
				n.act_dur = 1.2
		"go_place":
			var it2: Dictionary = n.act_data.get("intent", {})
			if str(it2.get("meetup", "")) != "":
				w.director.meetup_arrived(str(it2["meetup"]), n.id)
			elif it2.get("event", "") != "":
				var roles2: Dictionary = {"actor": n.id}
				for k in it2.get("roles", {}):
					roles2[k] = it2["roles"][k]
				if it2.get("target", "") != "":
					roles2["target"] = it2["target"]
				w.events.run_event(it2["event"], roles2, it2.get("vars", {}))
		"go_desk":
			var owner: String = str(n.act_data.get("owner", ""))
			var dp := "desk_" + owner
			if w.office.places.has(dp):
				var dv: Vector2 = w.office.place_pos(dp) - n.pos
				if absf(dv.x - dv.y) > 0.05:
					n.face_right = (dv.x - dv.y) > 0.0
				n.face_front = (dv.x + dv.y) >= -0.05
			var it3: Dictionary = n.act_data.get("intent", {})
			if it3.get("event", "") != "":
				var roles3: Dictionary = {"actor": n.id, "target": owner}
				for k in it3.get("roles", {}):
					if not roles3.has(k):
						roles3[k] = it3["roles"][k]
				w.events.run_event(it3["event"], roles3, it3.get("vars", {}))
		"away":
			# steps out of the building for a while (interview, "dentist", errand)
			n.today_flags["late_work"] = true
			n.today_flags["away"] = str(n.act_data.get("reason", "out"))
			n.arrive_at = w.minute + float(n.act_data.get("minutes", 40.0))
			w.office.release_all(n.id)
			n.present = false
			n.state = NPC.S.OUTSIDE
			n.pos = OfficeEnv.OUTSIDE
			n.act = ""
			n.phase = ""
			n.act_place = ""
			w.events.fire("went_out", {"actor": n.id, "reason": n.today_flags["away"]})
		"return_item":
			var item: String = n.act_data.get("item", "")
			if item != "" and o.items.has(item):
				o.items[item]["at"] = o.items[item]["home"]
				w.office_changed.emit("items")
				w.events.run_event("item_returned", {"actor": n.id, "target": n.act_target}, {"item": item})
		"leave":
			_exit(w, n)
		"wander", "idle":
			n.pose = "stand"
		"search":
			n.pose = "search"
		"patrol":
			var tg: Array = n.act_data.get("targets", [])
			var ti := int(n.act_data.get("ti", -1))
			if ti >= 0 and ti < tg.size():
				w.face_toward(n, tg[ti])
		"chat":
			n.act_dur = 1.0
			if w.available(n.act_target):
				w.events.fire("chat", {"actor": n.id, "target": n.act_target})


static func _exit(w, n: NPC) -> void:
	w.office.release_all(n.id)
	n.present = false
	n.state = NPC.S.GONE
	n.act = ""
	n.phase = ""
	n.act_place = ""


static func _desk_checks(w, n: NPC) -> void:
	if w.minute - n.last_desk_check < 3.0:
		return
	n.last_desk_check = w.minute
	var o: OfficeEnv = w.office
	var desks: Dictionary = o.objects["desks"]
	if desks.has(n.id) and desks[n.id]["messed"]:
		desks[n.id]["messed"] = false
		w.office_changed.emit("desks")
		w.events.fire("desk_messed", {"actor": n.id})
		return
	for item in o.items_at("desk_" + n.id):
		if o.items[item]["owner"] != n.id:
			w.events.fire("foreign_item", {"actor": n.id, "owner": o.items[item]["owner"], "item": item})
			return
	var mine := o.item_owned_by(n.id)
	if mine != "" and mine in ["charger", "planner", "usb"] and o.items[mine]["at"] != o.items[mine]["home"]:
		if mine != "usb" or n.current_task().get("usb", false) or n.task_needing_print().get("usb", false):
			_need_item(w, n, mine)


static func _need_item(w, n: NPC, item: String) -> void:
	if n.today_flags.get("searching_" + item, false):
		return
	if w.office.items[item]["at"] == w.office.items[item]["home"]:
		return
	n.today_flags["searching_" + item] = true
	w.events.fire("item_missing", {"actor": n.id, "item": item})


# ---------------------------------------------------------------- per-minute work

static func _do(w, n: NPC, d: float) -> void:
	n.act_t += d
	var o: OfficeEnv = w.office
	match n.act:
		"work":
			if n.act_place == "desk_" + n.id:
				var rate := (0.55 + n.t("diligence") * 0.75) * (1.0 - n.stress / 230.0)
				if not o.objects["lights"]["on"]:
					rate *= 0.15
					n.pose = "stand"
				else:
					n.pose = "phone" if n.current_task().get("phone", false) and fmod(n.act_t, 12.0) > 7.0 else "type"
				if n.coffee_need > 80.0:
					rate *= 0.75
				if n.id == "mert" and n.goal != "hit_sales" and w.minute < 330.0:
					rate *= 0.55
				w.add_work(n.id, rate * d)
				n.act_data["board_t"] = float(n.act_data.get("board_t", 0.0)) + d
				if n.act_data["board_t"] > 8.0:
					n.act_data["board_t"] = 0.0
					MeetingFlow.check_board(w, n)
				if n.act_data.has("email_at") and n.act_t >= float(n.act_data["email_at"]):
					n.act_data.erase("email_at")
					if o.objects["email"].has(n.id):
						WorldSpecials.send_email(w, n.id)
				# finished everything and needs to print?
				if n.current_task().is_empty() and n.act_t > 3.0:
					n.act_dur = minf(n.act_dur, n.act_t + 0.5)
		"meeting":
			if MeetingFlow.should_leave(w, n):
				_end(w, n)
				return
		"lunch":
			n.stress = maxf(0.0, n.stress - 0.25 * d)
			n.social_need = maxf(0.0, n.social_need - 0.6 * d)
		"rest":
			n.stress = maxf(0.0, n.stress - 0.35 * d)
		"chat":
			n.social_need = maxf(0.0, n.social_need - 3.0 * d)
		"fix":
			if n.act_data.get("obj", "") == "lights" and o.objects["lights"]["on"]:
				n.act_t = n.act_dur
	if n.act_t >= n.act_dur:
		_finish(w, n)


static func _finish(w, n: NPC) -> void:
	var o: OfficeEnv = w.office
	match n.act:
		"coffee":
			if n.pose == "coffee":
				n.coffee_need = 0.0
				n.coffee_count += 1
				n.stress = maxf(0.0, n.stress - 7.0)
				n.mood = C.clampf100(n.mood + 6.0)
		"gift_coffee":
			if n.act_target != "" and w.available(n.act_target):
				var it := {"type": "go_npc", "target": n.act_target, "event": "coffee_gift", "prio": 55.0, "until": w.minute + 30.0, "roles": {}, "vars": {}}
				_end(w, n)
				start_intent(w, n, it)
				return
		"water":
			n.social_need = maxf(0.0, n.social_need - 8.0)
			n.mood = C.clampf100(n.mood + 2.0)
		"print":
			if not o.objects["printer"]["broken"]:
				var tk := n.task_needing_print()
				if not tk.is_empty():
					tk["printed"] = true
		"archive":
			var tk2 := n.current_task()
			if tk2.get("archive", false):
				w.add_work(n.id, 12.0)
		"review":
			if n.pose == "read" and not n.reviewed_today:
				n.reviewed_today = true
				MeetingFlow.promo_review(w, n)
		"fix":
			var obj: String = n.act_data.get("obj", "printer")
			var was_broken := false
			if obj == "lights":
				was_broken = not o.objects["lights"]["on"]
				o.objects["lights"]["on"] = true
			else:
				was_broken = o.objects[obj]["broken"]
				o.objects[obj]["broken"] = false
			o.objects[obj]["fixing"] = ""
			if was_broken:
				w.office_changed.emit(obj)
				w.sfx.emit("fixed" if obj != "lights" else "lights_on")
				w.events.fire("fix_done", {"actor": n.id, "obj": obj, "requester": n.act_data.get("requester", "")})
		"search":
			if _search_next(w, n):
				return
		"patrol":
			if _patrol_next(w, n):
				return
		"announce":
			pass
	_end(w, n)


static func _end(w, n: NPC) -> void:
	if n.act_place != "":
		w.office.release(n.act_place, n.id)
	n.act = ""
	n.phase = ""
	n.act_place = ""
	n.act_target = ""
	if n.pose != "sit":
		n.pose = "stand"


# ---------------------------------------------------------------- search & patrol

static func _setup_search(w, n: NPC) -> void:
	var item: String = n.act_data.get("item", "")
	var o: OfficeEnv = w.office
	if not o.items.has(item):
		_end(w, n)
		return
	var stops: Array = []
	var cands := ["kitchen", "meeting", "lounge", "archive", "desk_" + n.id]
	w.shuffle(cands)
	for c in cands:
		if c != o.items[item]["at"] and stops.size() < 2:
			stops.append(c)
	stops.append(o.items[item]["at"])
	n.act_data["stops"] = stops
	n.act_data["stop_i"] = -1
	n.set_emote("question", 3.0)
	_search_next(w, n)


static func _search_next(w, n: NPC) -> bool:
	var stops: Array = n.act_data.get("stops", [])
	var i := int(n.act_data.get("stop_i", -1))
	var o: OfficeEnv = w.office
	var item: String = n.act_data.get("item", "")
	if i >= 0 and i < stops.size():
		# looked here
		if o.items.has(item) and o.items[item]["at"] == stops[i]:
			var at: String = stops[i]
			var at_owner := ""
			if at.begins_with("desk_"):
				at_owner = at.substr(5)
			o.items[item]["at"] = o.items[item]["home"]
			w.office_changed.emit("items")
			n.today_flags["searching_" + item] = false
			_end(w, n)
			w.events.fire("item_found", {"actor": n.id, "item": item, "loc": at, "owner": at_owner if at_owner != n.id else ""})
			return true
	i += 1
	if i >= stops.size() or not o.items.has(item):
		return false
	# item may have been returned meanwhile
	if o.items[item]["at"] == o.items[item]["home"] and i > 0:
		n.today_flags["searching_" + item] = false
		return false
	n.act_data["stop_i"] = i
	var place := OfficeLayout.item_pick_place(stops[i])
	if stops[i] == o.items[item]["at"]:
		pass
	var cell := o.place_cell(place)
	var c2 := cell
	if place.begins_with("desk_") and place != "desk_" + n.id:
		# stand next to someone else's desk rather than on their chair
		c2 = o.nearest_walkable(cell + Vector2i(0, 1))
		if not o.walkable(c2):
			c2 = cell
	n.path = o.find_path(n.pos, c2)
	n.path_i = 0
	n.phase = "walk"
	n.pose = "walk"
	n.act_t = 0.0
	n.act_dur = 1.3
	n.act_place = ""
	return true


static func _setup_patrol(w, n: NPC) -> void:
	var targets: Array = []
	for id in w.present_ids():
		if id == n.id:
			continue
		var t: NPC = w.npc(id)
		if t.act in ["work", "coffee", "chat", "water", "rest", "phone", "wander"]:
			targets.append(id)
	w.shuffle(targets)
	n.act_data["targets"] = targets.slice(0, 2)
	n.act_data["ti"] = -1
	if not _patrol_next(w, n):
		_end(w, n)


static func _patrol_next(w, n: NPC) -> bool:
	var targets: Array = n.act_data.get("targets", [])
	var i := int(n.act_data.get("ti", -1))
	if i >= 0 and i < targets.size():
		var tid: String = targets[i]
		if w.available(tid) and w.dist(n.id, tid) < 2.4:
			w.events.fire("patrol_check", {"actor": n.id, "target": tid})
	i += 1
	while i < targets.size() and not w.available(targets[i]):
		i += 1
	if i >= targets.size():
		return false
	n.act_data["ti"] = i
	n.path = _path_to_npc(w, n, targets[i])
	n.path_i = 0
	n.phase = "walk"
	n.pose = "walk"
	n.act_t = 0.0
	n.act_dur = 1.2
	n.act_data["walk_t"] = 0.0
	n.act_place = ""
	return true
