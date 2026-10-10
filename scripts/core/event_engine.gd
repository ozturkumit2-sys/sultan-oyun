class_name EventEngine
extends RefCounted
## Veri odaklı olay motoru: koşulları değerlendirir, olayları sıraya koyar,
## seçimlerin anlık ve gecikmeli etkilerini uygular.

const P := "sultan"
const MAX_PENDING := 7
const ROLE_GROUPS := {
	"hizmet": ["servant", "guard", "harem_staff", "clerk"],
}


static func on_new_game(gs: GameWorld) -> void:
	for tid in EventsData.STARTING:
		add_event(gs, tid, {})
	schedule(gs, "tolga_butce", 1, {})
	schedule(gs, "edric_hediye", 2, {})


static func tpl(tid: String) -> Dictionary:
	return EventsData.EVENTS.get(tid, {})


static func pending(gs: GameWorld) -> Array:
	return gs.w["events"]["pending"]


static func pending_for(gs: GameWorld, char_id: String) -> Array:
	var out: Array = []
	for e in pending(gs):
		if e.get("talk", "") == char_id:
			out.append(e)
	return out


static func is_present(gs: GameWorld, id: String) -> bool:
	var c: Dictionary = gs.ch(id)
	return not c.is_empty() and c.get("alive", true) and not c.get("gone", false)


# ------------------------------------------------------------ zamanlama

static func schedule(gs: GameWorld, tid: String, days: int, ctx: Dictionary, chance: float = 1.0) -> void:
	gs.w["events"]["scheduled"].append({"tid": tid, "day": gs.get_day() + days, "ctx": ctx, "chance": chance})
	if days <= 0:
		_process_scheduled(gs)


static func _process_scheduled(gs: GameWorld) -> void:
	var keep: Array = []
	for s in gs.w["events"]["scheduled"]:
		if int(s["day"]) <= gs.get_day():
			if gs.rng.randf() <= float(s.get("chance", 1.0)):
				add_event(gs, String(s["tid"]), s.get("ctx", {}))
		else:
			keep.append(s)
	gs.w["events"]["scheduled"] = keep


static func daily(gs: GameWorld) -> void:
	_process_scheduled(gs)
	_expire(gs)
	var pool: Array = EventsData.RANDOM_POOL.duplicate()
	pool.shuffle()
	var added := 0
	for tid in pool:
		if added >= 2 or pending(gs).size() >= MAX_PENDING:
			break
		if _eligible(gs, String(tid)):
			var t := tpl(String(tid))
			if gs.rng.randf() <= float(t.get("chance", 1.0)):
				if add_event(gs, String(tid), {}):
					added += 1
	_npc_requests(gs)
	_check_promises(gs)


static func _check_promises(gs: GameWorld) -> void:
	var sd = gs.w["flags"].get("soz_davud", null)
	if sd != null and typeof(sd) != TYPE_BOOL and gs.get_day() - int(sd) > 30 and not gs.flag("davud_acildi") and not gs.flag("soz_bozuldu"):
		gs.set_flag("soz_bozuldu", true)
		gs.rel_add("leyla", P, {"guven": -15.0, "sevgi": -8.0, "romantik": -8.0})
		gs.add_memory("leyla", "soz_bozuldu", [P], -45.0, "Hükümdar babamın davası için verdiği sözü tutmadı.", "dogrudan", true, {"key": "soz_bozuldu"})
		gs.add_log("Leyla Sultan, babasının davası için verdiğiniz sözün unutulduğunu düşünüyor.", "harem", 2)


static func hourly(gs: GameWorld) -> void:
	_process_scheduled(gs)
	check_randevu(gs)
	DialogueEngine.process_tasks(gs)
	if gs.get_hour() == 21:
		var fd = gs.w["flags"].get("feraye_randevu", null)
		if fd != null and typeof(fd) != TYPE_BOOL and int(fd) == gs.get_day() and not gs.flag("feraye_randevu_ok"):
			gs.w["flags"].erase("feraye_randevu")
			gs.rel_add("feraye", P, {"romantik": -6, "sevgi": -4})
			gs.add_memory("feraye", "kirginlik", [P], -30.0, "Köşkte saatlerce bekledim; gelmedi.", "dogrudan", true, {"key": "randevu_kacti"})
			gs.add_log("Feraye Sultan köşkte boşuna bekledi. Kırgın.", "harem", 2)


static func check_randevu(gs: GameWorld) -> void:
	var fd = gs.w["flags"].get("feraye_randevu", null)
	if fd == null or typeof(fd) == TYPE_BOOL:
		return
	if int(fd) != gs.get_day() or gs.flag("feraye_randevu_ok"):
		return
	var h: int = gs.get_hour()
	if h >= 18 and h < 21 and gs.player_room == "harem_bahce":
		gs.set_flag("feraye_randevu_ok", true)
		gs.w["flags"].erase("feraye_randevu")
		add_event(gs, "feraye_bulusma", {})
		gs.notify.emit("Feraye Sultan köşkte sizi bekliyor. Yanına gidip konuşun.", "harem")


static func _eligible(gs: GameWorld, tid: String) -> bool:
	var t := tpl(tid)
	if t.is_empty():
		return false
	var fired: Dictionary = gs.w["events"]["fired"]
	if t.get("once", false) and fired.has(tid):
		return false
	if fired.has(tid) and gs.get_day() - int(fired[tid]) < int(t.get("cooldown", 9999 if t.get("once", false) else 5)):
		return false
	for e in pending(gs):
		if e["tid"] == tid:
			return false
	if t.has("talk") and not is_present(gs, String(t["talk"])):
		return false
	return check(gs, t.get("cond", {}), {})


static func add_event(gs: GameWorld, tid: String, ctx: Dictionary) -> bool:
	var t := tpl(tid)
	if t.is_empty():
		return false
	if t.has("talk") and not is_present(gs, String(t["talk"])):
		return false
	for e in pending(gs):
		if e["tid"] == tid:
			return false
	var ev := {
		"uid": gs.next_id("e"), "tid": tid, "cat": t.get("cat", "saray"),
		"title": fmt(gs, String(t["title"]), ctx), "text": fmt(gs, String(t["text"]), ctx),
		"day": gs.get_day(), "expires": gs.get_day() + int(t.get("expires", 5)),
		"ctx": ctx, "talk": t.get("talk", ""), "seen": false,
	}
	pending(gs).append(ev)
	gs.w["events"]["fired"][tid] = gs.get_day()
	gs.events_changed.emit()
	if ev["talk"] != "":
		gs.notify.emit("%s sizinle görüşmek istiyor: %s" % [gs.short_name(ev["talk"]), ev["title"]], "gorusme")
	else:
		gs.notify.emit("Yeni olay: " + String(ev["title"]), String(ev["cat"]))
	return true


static func _expire(gs: GameWorld) -> void:
	var keep: Array = []
	for e in pending(gs).duplicate():
		if gs.get_day() > int(e["expires"]):
			var t := tpl(e["tid"])
			if t.has("default"):
				var res := resolve(gs, String(e["uid"]), int(t["default"]), true)
				gs.add_log("Karar verilmedi: \"%s\" kendiliğinden sonuçlandı. %s" % [e["title"], res], "olay", 2)
				continue
			if e.get("talk", "") != "":
				gs.rel_add(e["talk"], P, {"sevgi": -2.0, "saygi": -1.0})
				gs.add_memory(e["talk"], "ihmal", [P], -12.0, "Hükümdar görüşme isteğimi geri çevirdi.", "dogrudan", true, {"key": "ihmal:" + String(e["uid"])})
			gs.add_log("\"%s\" meselesi sahipsiz kaldı." % e["title"], "olay", 1)
		else:
			keep.append(e)
	gs.w["events"]["pending"] = keep
	gs.events_changed.emit()


## NPC'lerin kendi başlattığı görüşme istekleri
static func _npc_requests(gs: GameWorld) -> void:
	# özlem: gönül bağı yüksek ama uzun süredir konuşulmamış
	for id in ["leyla", "feraye"]:
		if not is_present(gs, id):
			continue
		var last := int(gs.w["dialogue"]["last_talk"].get(id, -99))
		if float(gs.rel_val(id, P, "romantik")) >= 45.0 and gs.get_day() - last >= 4:
			gs.adjust_mood(id, -6)
			gs.rel_add(id, P, {"romantik": -1.5})
			if not gs.flag("ozlem_log_%s_%d" % [id, gs.get_day() / 4]):
				gs.set_flag("ozlem_log_%s_%d" % [id, gs.get_day() / 4], true)
				gs.add_log("%s günlerdir sizi görmediğinden yakınıyor." % gs.short_name(id), "harem", 2)


# ------------------------------------------------------------ çözümleme

static func find(gs: GameWorld, uid: String) -> Dictionary:
	for e in pending(gs):
		if e["uid"] == uid:
			return e
	return {}


static func options_for(gs: GameWorld, ev: Dictionary) -> Array:
	var t := tpl(ev["tid"])
	var out: Array = []
	var opts: Array = t.get("options", [])
	for i in range(opts.size()):
		var o: Dictionary = opts[i]
		var ok := check(gs, o.get("cond", {}), ev.get("ctx", {}))
		var cost := fx_cost(o.get("fx", []), ev.get("ctx", {}))
		var afford: bool = cost <= gs.treasury()
		out.append({"idx": i, "text": fmt(gs, String(o["text"]), ev.get("ctx", {})), "available": ok, "affordable": afford, "cost": cost})
	return out


static func resolve(gs: GameWorld, uid: String, idx: int, silent: bool = false) -> String:
	var ev := find(gs, uid)
	if ev.is_empty():
		return ""
	var t := tpl(ev["tid"])
	var opts: Array = t.get("options", [])
	if idx < 0 or idx >= opts.size():
		return ""
	var o: Dictionary = opts[idx]
	pending(gs).erase(ev)
	apply_fx(gs, o.get("fx", []), ev.get("ctx", {}))
	var result := fmt(gs, String(o.get("result", "")), ev.get("ctx", {}))
	var hist: Array = gs.w["events"]["history"]
	hist.append({"tid": ev["tid"], "title": ev["title"], "choice": fmt(gs, String(o["text"]), ev.get("ctx", {})), "result": result, "day": gs.get_day()})
	if hist.size() > 120:
		hist.remove_at(0)
	if not silent:
		gs.add_log("%s — %s" % [ev["title"], result if result != "" else fmt(gs, String(o["text"]), {})], String(ev.get("cat", "olay")), 1)
	gs.events_changed.emit()
	gs.stats_changed.emit()
	return result


static func fx_cost(fx: Array, ctx: Dictionary) -> float:
	var cost := 0.0
	for e in fx:
		if e["op"] == "treasury":
			var v := _num(e["v"], ctx)
			if v < 0:
				cost -= v
		elif e["op"] == "project":
			cost += float(ProvincesData.PROJECTS[e["type"]]["cost"])
	return cost


# ------------------------------------------------------------ koşullar

static func check(gs: GameWorld, cond: Dictionary, ctx: Dictionary) -> bool:
	for k in cond.keys():
		var v = cond[k]
		match String(k):
			"min_day":
				if gs.get_day() < int(v):
					return false
			"max_day":
				if gs.get_day() > int(v):
					return false
			"flag":
				if not gs.flag(String(v)):
					return false
			"not_flag":
				if gs.flag(String(v)):
					return false
			"alive":
				if not is_present(gs, String(v)):
					return false
			"rel_gt":
				if not is_present(gs, v[0]) or gs.rel_val(v[0], v[1], v[2]) <= float(v[3]):
					return false
			"rel_lt":
				if not is_present(gs, v[0]) or gs.rel_val(v[0], v[1], v[2]) >= float(v[3]):
					return false
			"lore":
				if not int(v[1]) in gs.lore_unlocked(String(v[0])):
					return false
			"any_lore":
				var any := false
				for pair in v:
					if int(pair[1]) in gs.lore_unlocked(String(pair[0])):
						any = true
				if not any:
					return false
			"no_wife":
				if not gs.player().get("married_to", []).is_empty():
					return false
			"not_married":
				if String(v) in gs.player().get("married_to", []):
					return false
			"hour_lt":
				if gs.get_hour() >= int(v):
					return false
			"month_in":
				if not gs.get_month() in v:
					return false
			"prov_lt":
				var p: Dictionary = gs.province(String(v[0]))
				if p.is_empty() or float(p[v[1]]) >= float(v[2]):
					return false
			"tax_ge":
				if int(gs.w["state"]["tax_level"]) < int(v):
					return false
			"palace_ge":
				if int(gs.w["state"]["palace_level"]) < int(v):
					return false
			"food_price_gt":
				if float(gs.w["state"]["food_price"]) <= float(v):
					return false
			"treasury_lt":
				if gs.treasury() >= float(v):
					return false
			"treasury_gt":
				if gs.treasury() <= float(v):
					return false
	return true


# ------------------------------------------------------------ etkiler

static func _id(v, ctx: Dictionary) -> String:
	var s := String(v)
	if s.begins_with("$"):
		return String(ctx.get(s.substr(1), ""))
	return s


static func _num(v, ctx: Dictionary) -> float:
	if v is String:
		var s: String = v
		var neg := s.begins_with("-")
		if neg:
			s = s.substr(1)
		var r := 0.0
		if s.begins_with("$"):
			r = float(ctx.get(s.substr(1), 0))
		else:
			r = float(s)
		return -r if neg else r
	return float(v)


static func apply_fx(gs: GameWorld, fx: Array, ctx: Dictionary) -> void:
	for e in fx:
		var op: String = e["op"]
		match op:
			"treasury":
				gs.w["state"]["treasury"] = gs.treasury() + _num(e["v"], ctx)
			"rel":
				var a := _id(e["a"], ctx)
				var b := _id(e["b"], ctx)
				if is_present(gs, a) and (b == P or is_present(gs, b)):
					gs.rel_add(a, b, e["d"])
			"mem":
				var who := _id(e["who"], ctx)
				if not is_present(gs, who):
					continue
				if e.has("if_lore") and not int(e["if_lore"][1]) in gs.lore_unlocked(String(e["if_lore"][0])):
					continue
				var actors: Array = []
				for ac in e.get("actors", [P]):
					actors.append(_id(ac, ctx))
				gs.add_memory(who, String(e["type"]), actors, float(e["emo"]), fmt(gs, String(e["text"]), ctx), "dogrudan", true, {"key": e.get("key", "")})
			"flag":
				var fv = e.get("v", true)
				if fv is String and fv == "$day":
					fv = gs.get_day()
				gs.set_flag(String(e["k"]), fv)
			"unflag":
				gs.w["flags"].erase(String(e["k"]))
			"mod":
				gs.add_modifier(_id(e["prov"], ctx), String(e["stat"]), float(e["v"]), int(e["days"]), "olay")
			"state":
				gs.state_add(String(e["stat"]), float(e["v"]))
			"skill":
				gs.player_skill_add(String(e["s"]), float(e["v"]))
			"sched":
				var c2: Dictionary = ctx.duplicate()
				c2.merge(e.get("ctx", {}), true)
				schedule(gs, String(e["event"]), int(e["days"]), c2, float(e.get("chance", 1.0)))
			"gone":
				char_gone(gs, _id(e["who"], ctx), fmt(gs, String(e.get("text", "")), ctx))
			"resolve":
				gs.resolve_memories(_id(e["who"], ctx), String(e["type"]), P)
			"lore":
				var lw := _id(e["who"], ctx)
				var li := int(e["idx"])
				if gs.unlock_lore(lw, li):
					var lore: Array = gs.ch(lw).get("lore", [])
					if li < lore.size():
						gs.add_log("Öğrendiniz (%s): %s" % [gs.short_name(lw), lore[li]["t"]], "bilgi", 2)
			"nb":
				for nb in gs.w["neighbors"]:
					if nb["id"] == e["id"]:
						nb[e["stat"]] = clampf(float(nb[e["stat"]]) + float(e["v"]), 0.0, 100.0)
			"army":
				gs.w["state"]["army_level"] = clampi(int(e["v"]), 0, 2)
			"palace":
				gs.w["state"]["palace_level"] = clampi(int(gs.w["state"]["palace_level"]) + int(e["v"]), 0, 2)
			"tax":
				gs.w["state"]["tax_level"] = clampi(int(gs.w["state"]["tax_level"]) + int(e["v"]), 0, 4)
			"override":
				var ow := _id(e["who"], ctx)
				if is_present(gs, ow):
					gs.set_override(ow, String(e["room"]), String(e["activity"]), int(e["minutes"]))
			"mood":
				gs.adjust_mood(_id(e["who"], ctx), float(e["v"]))
			"moodall":
				for id in gs.npc_ids():
					gs.adjust_mood(id, float(e["v"]))
			"relall":
				var grp: String = e["group"]
				for id2 in gs.npc_ids():
					if grp == "hepsi" or gs.ch(id2)["role"] in ROLE_GROUPS.get(grp, []):
						gs.rel_add(id2, P, e["d"], false)
			"reveal":
				gs.reveal_gossip(int(e["n"]))
			"dismiss":
				var post: String = e["post"]
				var holder: String = gs.post_holder(post)
				if holder != "":
					dismiss_official(gs, post, "", fmt(gs, String(e.get("text", "")), ctx))
			"prov":
				var pid := _id(e["id"], ctx)
				var p: Dictionary = gs.province(pid)
				if p.is_empty():
					continue
				var stat: String = e["stat"]
				if stat == "pop":
					p["pop"] = float(p["pop"]) * (1.0 + float(e["v"]) / 100.0)
				else:
					var cap := 60.0 if stat == "issizlik" else 100.0
					p[stat] = clampf(float(p[stat]) + float(e["v"]), 0.0, cap)
			"gida":
				var pg: Dictionary = gs.province(_id(e["prov"], ctx))
				if not pg.is_empty():
					pg["gida"] = clampf(float(pg["gida"]) + float(e["v"]), 0.0, 12.0)
			"gida_all":
				for pa in gs.w["provinces"]:
					pa["gida"] = clampf(float(pa["gida"]) + float(e["v"]), 0.0, 12.0)
			"exempt":
				var pe: Dictionary = gs.province(_id(e["prov"], ctx))
				if not pe.is_empty():
					pe["exempt_until"] = gs.get_day() + int(e["months"]) * 30
			"governor":
				var pv: Dictionary = gs.province(_id(e["prov"], ctx))
				if not pv.is_empty():
					pv["governor"] = e["name"]
					gs.add_log("%s eyaletine %s atandı." % [pv["name"], e["name"]], "devlet", 1)
			"project":
				Economy.start_project(gs, _id(e["prov"], ctx), String(e["type"]))
			"project_free":
				var def: Dictionary = ProvincesData.PROJECTS[e["type"]]
				gs.w["projects"].append({"prov": _id(e["prov"], ctx), "type": e["type"], "start_month": gs.cal_month_index(), "done_month": gs.cal_month_index() + int(def["months"])})
			"log":
				gs.add_log(fmt(gs, String(e["text"]), ctx), String(e.get("kind", "olay")), int(e.get("imp", 1)))
			"marry":
				marry(gs, _id(e["who"], ctx))
			"crime":
				var cw := _id(e["who"], ctx)
				if is_present(gs, cw):
					JusticeEngine.add_evidence(gs, cw, String(e["type"]), _num(e["v"], ctx), fmt(gs, String(e.get("note", "")), ctx), bool(ctx.get("guilty", true)))
			"clearcase":
				JusticeEngine.clear_case(gs, _id(e["who"], ctx), String(e["type"]))
			"sched_if":
				var c3: Dictionary = ctx.duplicate()
				var ev_name: String = e["event_true"] if bool(ctx.get(String(e.get("key", "guilty")), false)) else e["event_false"]
				schedule(gs, ev_name, int(e["days"]), c3)
			"rename":
				HaremEngine.rename_child(gs, _id(e["who"], ctx), _id(e["name"], ctx))
			"announce":
				HaremEngine.announce(gs, _id(e["who"], ctx))
			"announce_quiet":
				var aw := _id(e["who"], ctx)
				gs.adjust_mood(aw, 15.0)
				gs.add_log("%s hamile; şimdilik yalnızca siz ve hekimbaşı biliyorsunuz." % gs.short_name(aw), "hanedan", 1)
	gs.stats_changed.emit()


static func marry(gs: GameWorld, bride: String) -> void:
	if not is_present(gs, bride) or gs.is_married_to_player(bride):
		return
	var pl: Dictionary = gs.player()
	pl["married_to"].append(bride)
	var c: Dictionary = gs.ch(bride)
	c["married_to"] = [P]
	var first: bool = pl["married_to"].size() == 1
	c["full"] = String(c["name"]) + (" Haseki Sultan" if first else " Sultan")
	c["title"] = "Haseki Sultan" if first else "Sultan"
	c["status"] = int(c["status"]) + 15
	if c.get("harem", false):
		c["rank"] = "haseki" if first else "kadin"
	gs.w["flags"].erase("nisan:" + bride)
	gs.rel_add(bride, P, {"romantik": 10.0, "sevgi": 10.0, "guven": 10.0})
	gs.add_memory(bride, "evlilik", [P], 60.0, "Hükümdarla evlendim.", "dogrudan", true, {"key": "evlilik:" + bride})
	gs.rel_add("mahinur", P, {"sevgi": 5.0, "siyasi_uyum": 5.0} if bride == "feraye" else {"sevgi": 2.0})
	for rid in gs.npc_ids():
		if rid != bride and gs.ch(rid).get("romanceable", false) and not gs.is_married_to_player(rid):
			gs.rel_add(rid, bride, {"kiskanclik": 15.0, "rekabet": 8.0})
			gs.rel_add(rid, P, {"romantik": -10.0})
	gs.set_flag("married:" + bride, true)
	gs.add_log("Sultan %s, %s ile evlendi." % [String(pl["name"]), String(c["name"])], "hanedan", 2)
	if gs.w.has("dynasty"):
		gs.w["dynasty"]["history"].append({"day": gs.get_day(), "text": "%s ile evlilik" % c["full"]})


static func char_gone(gs: GameWorld, who: String, text: String) -> void:
	var c: Dictionary = gs.ch(who)
	if c.is_empty():
		return
	var post: String = gs.post_of(who)
	if post != "":
		gs.w["posts"][post] = ""
	c["gone"] = true
	c["location"] = "disari"
	c["activity"] = "disarida"
	if text != "":
		gs.add_log(text, "saray", 2)
	gs.schedules_updated.emit()


const POST_OFFICE := {"sadrazam": "divan", "hazine": "hazine", "ordu": "muhafiz", "diplomasi": "elci", "adalet": "halk", "saray": "harem", "muhafiz": "muhafiz"}


## Makamdan alma ve (varsa) yerine atama
static func dismiss_official(gs: GameWorld, post: String, replacement: String, text: String = "") -> void:
	var holder: String = gs.post_holder(post)
	if holder != "" and is_present(gs, holder):
		var pname: String = CharactersData.POSTS[post]["name"]
		gs.add_memory(holder, "azil", [P], -70.0, "Hükümdar beni %s makamından azletti." % pname, "dogrudan", true, {"key": "azil:" + holder})
		gs.rel_add(holder, P, {"sevgi": -25, "saygi": -10, "siyasi_uyum": -30, "korku": 10})
		for wid in gs.npc_ids():
			if wid != holder and float(gs.rel_val(wid, holder, "siyasi_uyum")) > 65.0:
				gs.rel_add(wid, P, {"siyasi_uyum": -4}, false)
		gs.w["posts"][post] = ""
		if gs.ch(holder)["role"] == "official":
			char_gone(gs, holder, text if text != "" else "%s görevden alındı ve saraydan ayrıldı." % gs.full_name(holder))
		elif text != "":
			gs.add_log(text, "devlet", 2)
	if replacement != "":
		appoint(gs, post, replacement)


static func appoint(gs: GameWorld, post: String, who: String) -> void:
	var old_post: String = gs.post_of(who)
	if old_post != "":
		gs.w["posts"][old_post] = ""
	gs.w["posts"][post] = who
	var c: Dictionary = gs.ch(who)
	var pname: String = CharactersData.POSTS[post]["name"]
	if post in ["sadrazam", "hazine", "diplomasi", "adalet", "ordu"]:
		c["profile"] = "official"
		c["office"] = POST_OFFICE[post]
		c["role"] = "official" if c["role"] in ["scribe", "clerk", "official", "physician", "scholar"] else c["role"]
	elif post == "muhafiz":
		c["profile"] = "chief_guard"
	gs.add_memory(who, "terfi", [P], 55.0, "Hükümdar beni %s yaptı." % pname, "dogrudan", true, {"key": "terfi:" + who + ":" + post})
	gs.rel_add(who, P, {"sevgi": 10, "borcluluk": 25, "siyasi_uyum": 12})
	for wid in gs.npc_ids():
		if wid != who and float(gs.trait_of(wid, "hirs")) > 70.0 and float(gs.trait_of(wid, "kiskanclik")) > 45.0:
			gs.rel_add(wid, who, {"kiskanclik": 6, "rekabet": 5}, false)
	gs.add_log("%s, %s makamına atandı." % [gs.short_name(who), pname], "devlet", 2)
	gs.update_all_schedules()


# ------------------------------------------------------------ metin

static func fmt(gs: GameWorld, text: String, ctx: Dictionary) -> String:
	var s := text
	if s.contains("{sultan}"):
		s = s.replace("{sultan}", String(gs.player()["name"]))
	if s.contains("{treasury}"):
		s = s.replace("{treasury}", gs.fmt_money(gs.treasury()))
	for k in ctx.keys():
		if k == "prov":
			var pn: String = String(gs.province(String(ctx[k])).get("name", ctx[k]))
			s = s.replace("{prov:loc}", TR.loc(pn)).replace("{prov:abl}", TR.abl(pn)).replace("{prov:gen}", TR.gen(pn))
		var key := "{%s}" % k
		if not s.contains(key):
			continue
		var val = ctx[k]
		var disp := str(val)
		if k == "prov":
			var p: Dictionary = gs.province(String(val))
			disp = String(p.get("name", val))
		elif String(k).begins_with("cost"):
			disp = gs.fmt_money(float(val))
		elif val is float:
			disp = "%.1f" % val if absf(val) < 20.0 else str(int(round(val)))
		s = s.replace(key, disp)
	for k2 in ctx.keys():
		var nkey := "{%s_name}" % k2
		if s.contains(nkey) and not gs.ch(String(ctx[k2])).is_empty():
			s = s.replace(nkey, gs.short_name(String(ctx[k2])))
	return s
