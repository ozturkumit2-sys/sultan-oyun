class_name DivanEngine
extends RefCounted
## Divan gündemi: eyalet ve devlet durumundan türeyen meseleler, devlet adamlarının
## kişiliklerine göre tutumları ve kararların zincirleme etkileri.

const P := "sultan"
const COUNCIL := ["sadrazam", "hazine", "ordu", "diplomasi", "adalet"]
const URGENT := ["isyan_riski", "kuraklik", "huzursuzluk", "ekmek_fiyati"]


static func tpl(tid: String) -> Dictionary:
	return DivanData.AGENDA.get(tid, {})


static func agenda(gs: GameWorld) -> Array:
	return gs.w["divan"]["agenda"]


static func daily(gs: GameWorld) -> void:
	var dv: Dictionary = gs.w["divan"]
	if gs.get_day() >= int(dv["next_refresh"]) or agenda(gs).size() < 2:
		refresh_agenda(gs, false)
	# acil meseleler bekletilmez
	for tid in URGENT:
		if agenda(gs).size() >= 4:
			break
		_try_add(gs, tid)


static func refresh_agenda(gs: GameWorld, force: bool) -> void:
	var dv: Dictionary = gs.w["divan"]
	if not force and gs.get_day() < int(dv["next_refresh"]) and agenda(gs).size() >= 2:
		return
	# geçerliliğini yitirenleri temizle
	var keep: Array = []
	for item in agenda(gs):
		if gs.get_day() - int(item["day"]) < 14:
			keep.append(item)
	dv["agenda"] = keep
	for tid in URGENT:
		_try_add(gs, tid)
	var pool: Array = DivanData.AGENDA.keys()
	pool.shuffle()
	for tid2 in pool:
		if agenda(gs).size() >= 3:
			break
		_try_add(gs, String(tid2))
	dv["next_refresh"] = gs.get_day() + 7


static func _try_add(gs: GameWorld, tid: String) -> bool:
	var t := tpl(tid)
	if t.is_empty():
		return false
	for item in agenda(gs):
		if item["tid"] == tid:
			return false
	for dec in gs.w["divan"]["decided"]:
		if dec["tid"] == tid and gs.get_day() - int(dec["day"]) < 12:
			return false
	if not EventEngine.check(gs, t.get("cond", {}), {}):
		return false
	var ctx = bind(gs, t)
	if ctx == null:
		return false
	var item := {"uid": gs.next_id("d"), "tid": tid, "ctx": ctx, "day": gs.get_day(),
		"title": EventEngine.fmt(gs, String(t["title"]), ctx), "text": EventEngine.fmt(gs, String(t["text"]), ctx)}
	agenda(gs).append(item)
	return true


static func bind(gs: GameWorld, t: Dictionary):
	var b: Dictionary = t.get("bind", {})
	var ctx := {}
	var st: Dictionary = gs.w["state"]
	ctx["fiyat"] = "%.2f" % float(st["food_price"])
	ctx["cost_grain"] = 8000
	if b.get("prov_where", "") == "kuraklik":
		var best := {}
		for p in gs.w["provinces"]:
			if int(p.get("drought", 0)) > 0 or float(p["gida"]) < 1.6:
				if best.is_empty() or float(p["gida"]) < float(best["gida"]):
					best = p
		if best.is_empty():
			return null
		ctx["prov"] = best["id"]
		ctx["gida"] = snappedf(float(best["gida"]), 0.1)
		ctx["cost_food"] = int(float(best["pop"]) * 80.0 / 100.0) * 100
	if b.has("prov_lowest"):
		var stat: String = b["prov_lowest"]
		var low := {}
		for p in gs.w["provinces"]:
			if low.is_empty() or float(p[stat]) < float(low[stat]):
				low = p
		if low.is_empty() or float(low[stat]) >= float(b.get("below", 100)):
			return null
		ctx["prov"] = low["id"]
		ctx[stat] = int(round(float(low[stat])))
	return ctx


static func council(gs: GameWorld) -> Array:
	var out: Array = []
	for post in COUNCIL:
		var h: String = gs.post_holder(post)
		if h != "" and EventEngine.is_present(gs, h):
			out.append([post, h])
	return out


static func stance(gs: GameWorld, opt: Dictionary, who: String, post: String) -> float:
	var s := 0.0
	var st: Dictionary = opt.get("stance", {})
	for t in st.keys():
		s += (gs.trait_of(who, String(t)) - 50.0) * float(st[t])
	s += float(opt.get("roles", {}).get(post, 0))
	return s


static func stance_label(v: float) -> String:
	if v > 12.0:
		return "Destekliyor"
	if v < -12.0:
		return "Karşı"
	return "Çekimser"


static func find(gs: GameWorld, uid: String) -> Dictionary:
	for item in agenda(gs):
		if item["uid"] == uid:
			return item
	return {}


static func options_for(gs: GameWorld, item: Dictionary) -> Array:
	var t := tpl(item["tid"])
	var out: Array = []
	var opts: Array = t["options"]
	for i in range(opts.size()):
		var o: Dictionary = opts[i]
		var views: Array = []
		for pair in council(gs):
			var v := stance(gs, o, pair[1], pair[0])
			views.append({"post": pair[0], "who": pair[1], "score": v, "label": stance_label(v)})
		var cost := EventEngine.fx_cost(o["fx"], item["ctx"])
		out.append({"idx": i, "text": EventEngine.fmt(gs, String(o["text"]), item["ctx"]), "views": views, "cost": cost, "affordable": cost <= gs.treasury()})
	return out


static func decide(gs: GameWorld, uid: String, idx: int) -> String:
	var item := find(gs, uid)
	if item.is_empty():
		return ""
	var t := tpl(item["tid"])
	var o: Dictionary = t["options"][idx]
	var cost := EventEngine.fx_cost(o["fx"], item["ctx"])
	if cost > gs.treasury():
		gs.notify.emit("Hazine bu karar için yetersiz.", "uyari")
		return ""
	EventEngine.apply_fx(gs, o["fx"], item["ctx"])
	var choice := EventEngine.fmt(gs, String(o["text"]), item["ctx"])
	var supporters: Array = []
	var opponents: Array = []
	for pair in council(gs):
		var who: String = pair[1]
		var v := stance(gs, o, who, pair[0])
		var key := "divan:%s" % item["uid"]
		if v > 12.0:
			gs.rel_add(who, P, {"saygi": 2.0, "siyasi_uyum": 4.0})
			gs.add_memory(who, "divan_destek", [P], 10.0, "Divan'da önerimi kabul etti: %s" % item["title"], "dogrudan", true, {"key": key})
			supporters.append(gs.short_name(who))
		elif v < -12.0:
			gs.rel_add(who, P, {"siyasi_uyum": -4.0, "saygi": -1.0})
			gs.add_memory(who, "divan_karsi", [P], -10.0, "Divan'da görüşümü dinlemedi: %s" % item["title"], "dogrudan", true, {"key": key})
			opponents.append(gs.short_name(who))
	gs.player_skill_add("yonetim", 0.6)
	agenda(gs).erase(item)
	gs.w["divan"]["decided"].append({"tid": item["tid"], "day": gs.get_day(), "choice": choice, "title": item["title"]})
	gs.add_log("Divan kararı — %s: %s" % [item["title"], choice], "devlet", 1)
	gs.advance_minutes(30)
	var res := "Karar mühürlendi."
	if not supporters.is_empty():
		res += " Memnun olanlar: " + ", ".join(PackedStringArray(supporters)) + "."
	if not opponents.is_empty():
		res += " Hoşnutsuz olanlar: " + ", ".join(PackedStringArray(opponents)) + "."
	gs.stats_changed.emit()
	return res


## Vergi / bütçe kararları — ilgili devlet adamlarının tepkileriyle
static func set_tax(gs: GameWorld, level: int) -> void:
	var old := int(gs.w["state"]["tax_level"])
	level = clampi(level, 0, 4)
	if level == old:
		return
	gs.w["state"]["tax_level"] = level
	var up := level > old
	var hz: String = gs.post_holder("hazine")
	var adl: String = gs.post_holder("adalet")
	if hz != "":
		gs.rel_add(hz, P, {"siyasi_uyum": 3.0 if up else -2.0})
	if adl != "":
		gs.rel_add(adl, P, {"siyasi_uyum": -3.0 if up else 2.0})
	gs.add_modifier("*", "huzur", -4.0 if up else 3.0, 60, "vergi")
	gs.add_log("Vergi oranı '%s' olarak belirlendi." % ProvincesData.TAX_LEVELS[level]["name"], "devlet", 1)
	gs.stats_changed.emit()


static func set_palace(gs: GameWorld, level: int) -> void:
	gs.w["state"]["palace_level"] = clampi(level, 0, 2)
	gs.add_log("Saray harcamaları '%s' düzeyine ayarlandı." % ProvincesData.SPEND_LEVELS[clampi(level, 0, 2)], "devlet", 1)
	if level == 0:
		gs.rel_add("mahinur", P, {"siyasi_uyum": -4.0})
	gs.stats_changed.emit()


static func set_army(gs: GameWorld, level: int) -> void:
	gs.w["state"]["army_level"] = clampi(level, 0, 2)
	var o: String = gs.post_holder("ordu")
	if o != "":
		gs.rel_add(o, P, {"siyasi_uyum": (level - 1) * 4.0})
	gs.add_log("Ordu harcamaları '%s' düzeyine ayarlandı." % ProvincesData.ARMY_LEVELS[clampi(level, 0, 2)], "devlet", 1)
	gs.stats_changed.emit()


## Makam adayları
static func candidates(gs: GameWorld, post: String) -> Array:
	var skill: String = CharactersData.POSTS[post]["skill"]
	var out: Array = []
	for id in gs.npc_ids():
		var c: Dictionary = gs.ch(id)
		if c["role"] in ["envoy", "valide"]:
			continue
		if gs.post_holder(post) == id:
			continue
		var sk: float = gs.skill_of(id, skill)
		if sk < 35.0:
			continue
		out.append({"id": id, "skill": sk, "opinion": gs.opinion(id, P), "current": gs.post_of(id)})
	out.sort_custom(func(a, b): return float(a["skill"]) > float(b["skill"]))
	return out
