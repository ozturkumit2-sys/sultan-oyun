class_name Interventions
extends RefCounted
## InteractionManager: everything the invisible player can do to the office.
## Most meddling is *latent*: it only has consequences when a character
## actually runs into it (uses the printer, opens their email, sits at their desk...).

const NOTIF_KINDS := ["boss", "food", "cancel", "admirer"]
const TEMPS := [16, 19, 22, 25, 29]
const MEETING_SHIFTS := [-60, -30, 30, 60]


## Actions offered for a tapped hotspot. Each: {id, needs, enabled, reason}
static func actions_for(w, hotspot: String) -> Array:
	var o: OfficeEnv = w.office
	var r: Array = []
	match hotspot:
		"coffee_machine":
			var broken: bool = o.objects["coffee"]["broken"]
			r.append({"id": "break_coffee", "needs": "", "enabled": not broken, "reason": "act.reason_broken"})
			r.append({"id": "fix_coffee", "needs": "", "enabled": broken, "reason": "act.reason_working"})
		"printer":
			r.append({"id": "break_printer", "needs": "", "enabled": not o.objects["printer"]["broken"], "reason": "act.reason_broken"})
		"meeting_board":
			var ok: bool = not w.meeting.get("started", false) and not w.meeting.get("ended", false)
			r.append({"id": "move_meeting", "needs": "time", "enabled": ok, "reason": "act.reason_meeting_over"})
		"ac":
			r.append({"id": "set_temp", "needs": "temp", "enabled": true, "reason": ""})
		"lights":
			var on: bool = o.objects["lights"]["on"]
			r.append({"id": "lights_off", "needs": "", "enabled": on, "reason": "act.reason_dark"})
			r.append({"id": "lights_on", "needs": "", "enabled": not on, "reason": "act.reason_lit"})
		"promo_file":
			r.append({"id": "edit_promo", "needs": "credit", "enabled": not o.objects["promo"].get("altered", false), "reason": "act.reason_promo_pending"})
		_:
			if hotspot.begins_with("ws_"):
				var owner := hotspot.substr(3)
				var pending: bool = o.objects["email"].has(owner)
				r.append({"id": "email_all", "needs": "", "enabled": not pending, "reason": "act.reason_email_pending", "owner": owner})
				r.append({"id": "email_redirect", "needs": "person", "enabled": not pending, "reason": "act.reason_email_pending", "owner": owner})
				var messed: bool = o.objects["desks"].get(owner, {}).get("messed", false)
				r.append({"id": "shuffle_files", "needs": "", "enabled": not messed, "reason": "act.reason_messed", "owner": owner})
				var pn: NPC = w.npc(owner)
				r.append({"id": "fake_notif", "needs": "notif", "enabled": pn != null and pn.present, "reason": "act.reason_absent", "owner": owner})
				for item in o.items_at("desk_" + owner):
					r.append({"id": "move_item", "needs": "dest", "enabled": true, "reason": "", "item": item})
			elif hotspot.begins_with("item_"):
				r.append({"id": "move_item", "needs": "dest", "enabled": true, "reason": "", "item": hotspot.substr(5)})
	return r


## Options for a parameterised action. Each: {value, label_key, args, enabled}
static func options_for(w, action: Dictionary) -> Array:
	var o: OfficeEnv = w.office
	var r: Array = []
	match action["needs"]:
		"time":
			var bt := float(o.objects["board"]["time"])
			for s in MEETING_SHIFTS:
				var nt: float = bt + float(s)
				var ok: bool = nt > w.minute + 5.0 and nt >= 30.0 and nt <= 420.0
				r.append({"value": nt, "label": "opt.meeting_at", "args": {"time": C.fmt(nt)}, "enabled": ok})
		"temp":
			for t in TEMPS:
				r.append({"value": t, "label": "opt.temp_%d" % t, "args": {}, "enabled": int(o.objects["ac"]["temp"]) != t})
		"credit":
			for c in MeetingFlow.candidates(w):
				r.append({"value": c, "label": "opt.credit", "args": {"name": w.npc(c).name}, "enabled": true})
		"person":
			var owner: String = action.get("owner", "")
			for id in w.order:
				if id == owner:
					continue
				r.append({"value": id, "label": "opt.person", "args": {"name": w.npc(id).name}, "enabled": true})
		"notif":
			var owner2: String = action.get("owner", "")
			var on: NPC = w.npc(owner2)
			for k in NOTIF_KINDS:
				var ok2 := true
				if k == "cancel":
					ok2 = on != null and on.meeting_belief >= 0.0 and not w.meeting.get("ended", false)
				if k == "boss":
					ok2 = owner2 != "ahmet" and w.npc("ahmet").present
				r.append({"value": k, "label": "opt.notif_" + k, "args": {}, "enabled": ok2})
		"dest":
			var item: String = action.get("item", "")
			var cur: String = o.items[item]["at"] if o.items.has(item) else ""
			for loc in OfficeLayout.item_locations():
				if loc == cur:
					continue
				var lab: String = "loc." + str(loc)
				r.append({"value": loc, "label": lab, "args": {}, "enabled": true})
	return r


static func apply(w, action: Dictionary, value = null) -> bool:
	var o: OfficeEnv = w.office
	var id: String = action["id"]
	var ctx := {"roles": {}, "vars": {}}
	var owner: String = action.get("owner", "")
	if owner != "":
		ctx["roles"]["actor"] = owner
	match id:
		"break_coffee":
			o.objects["coffee"]["broken"] = true
			o.objects["coffee"]["ghost_fixed"] = false
			o.objects["coffee"]["discovered"] = false
		"fix_coffee":
			o.objects["coffee"]["broken"] = false
			o.objects["coffee"]["ghost_fixed"] = true
			o.objects["coffee"]["fixing"] = ""
		"break_printer":
			o.objects["printer"]["broken"] = true
			o.objects["printer"]["discovered"] = false
		"move_meeting":
			var old := float(o.objects["board"]["time"])
			o.objects["board"]["time"] = float(value)
			o.objects["board"]["changed"] = true
			ctx["vars"]["old_time"] = old
			ctx["vars"]["new_time"] = float(value)
		"set_temp":
			ctx["vars"]["temp"] = int(value)
			o.objects["ac"]["temp"] = int(value)
			o.objects["ac"]["set_by"] = "ghost"
		"lights_off":
			o.objects["lights"]["on"] = false
			o.objects["lights"]["off_at"] = w.minute
			o.objects["lights"]["fixing"] = ""
		"lights_on":
			o.objects["lights"]["on"] = true
			o.objects["lights"]["fixing"] = ""
		"edit_promo":
			o.objects["promo"]["credit"] = str(value)
			o.objects["promo"]["altered"] = true
			if w.npc("ahmet").reviewed_today:
				o.objects["promo"]["reviewed"] = false
				w.npc("ahmet").reviewed_today = false
			ctx["roles"]["target"] = str(value)
		"email_all":
			o.objects["email"][owner] = {"mode": "all", "to": ""}
			_hurry_email(w, owner)
		"email_redirect":
			o.objects["email"][owner] = {"mode": "redirect", "to": str(value)}
			ctx["roles"]["target"] = str(value)
			_hurry_email(w, owner)
		"shuffle_files":
			o.objects["desks"][owner]["messed"] = true
		"fake_notif":
			ctx["vars"]["kind"] = str(value)
		"move_item":
			var item: String = action.get("item", "")
			if not o.items.has(item):
				return false
			ctx["vars"]["item"] = item
			ctx["vars"]["loc"] = str(value)
			ctx["vars"]["from"] = o.items[item]["at"]
			ctx["roles"]["owner"] = o.items[item]["owner"]
			o.items[item]["at"] = str(value)
		_:
			return false
	w.total_interventions += 1
	w.stats.add("interventions")
	w.ghost_today += 1
	w.log_event("log.player." + id, ctx, 1, "player", [])
	w.office_changed.emit(id)
	w.sfx.emit("meddle")
	w.fx.emit("meddle", {"action": id, "owner": owner, "item": action.get("item", "")})
	# immediate consequences
	match id:
		"lights_off":
			w.sfx.emit("lights_off")
			w.events.fire("lights_off", {})
		"lights_on":
			w.events.fire("lights_on_ghost", {})
		"fake_notif":
			w.sfx.emit("phone")
			var n: NPC = w.npc(owner)
			if n and n.present:
				n.set_emote("phone", 2.5)
				w.events.fire("notif", {"actor": owner, "kind": str(value)})
		"set_temp":
			w.events.fire("temp_changed", {"temp": int(value)})
		"shuffle_files":
			var n2: NPC = w.npc(owner)
			if n2 and n2.present and n2.act in ["work", "arrive"] and n2.phase == "do" and n2.act_place == "desk_" + owner:
				o.objects["desks"][owner]["messed"] = false
				w.events.fire("desk_messed", {"actor": owner, "live": true})
		"move_meeting":
			w.events.fire("board_changed", {})
		"move_item":
			# someone sitting right next to the destination desk will spot it soon
			var loc := str(value)
			if loc.begins_with("desk_"):
				var dn: NPC = w.npc(loc.substr(5))
				if dn and dn.present and dn.act_place == loc and dn.phase == "do":
					dn.last_desk_check = -100.0
	return true


static func _hurry_email(w, owner: String) -> void:
	var n: NPC = w.npc(owner)
	if n and n.present and n.act == "work" and n.phase == "do" and n.act_place == "desk_" + owner:
		n.act_data["email_at"] = n.act_t + w.rng.randf_range(0.8, 2.5)
