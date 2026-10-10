class_name PetitionEngine
extends RefCounted
## Halk Kabul Salonu'ndaki dilekçeler. Her üç günde bir yenilenir.

const P := "sultan"


static func list(gs: GameWorld) -> Array:
	return gs.w["petitions"]["list"]


static func daily(gs: GameWorld) -> void:
	refresh(gs, false)


static func refresh(gs: GameWorld, force: bool) -> void:
	var pt: Dictionary = gs.w["petitions"]
	if not force and gs.get_day() < int(pt["next_refresh"]):
		return
	var current: Array = []
	for p in list(gs):
		if gs.get_day() - int(p["day"]) < 6:
			current.append(p)
	pt["list"] = current
	var pool: Array = DivanData.PETITIONS.keys()
	pool.shuffle()
	for tid in pool:
		if list(gs).size() >= 3:
			break
		var dup := false
		for p2 in list(gs):
			if p2["tid"] == tid:
				dup = true
		if dup:
			continue
		var ctx := {"name": DivanData.PETITIONERS[gs.rng.randi() % DivanData.PETITIONERS.size()], "prov": _pick_province(gs)}
		var t: Dictionary = DivanData.PETITIONS[tid]
		list(gs).append({"uid": gs.next_id("p"), "tid": tid, "ctx": ctx, "day": gs.get_day(), "text": EventEngine.fmt(gs, String(t["text"]), ctx)})
	pt["next_refresh"] = gs.get_day() + 3


static func _pick_province(gs: GameWorld) -> String:
	# huzuru düşük eyaletlerden gelen dilekçe daha olası
	var total := 0.0
	var ws: Array = []
	for p in gs.w["provinces"]:
		var wt := 1.0 + maxf(0.0, 60.0 - float(p["huzur"])) / 10.0
		ws.append([p["id"], wt])
		total += wt
	var r: float = gs.rng.randf() * total
	for pw in ws:
		r -= float(pw[1])
		if r <= 0.0:
			return String(pw[0])
	return "sahriyar"


static func find(gs: GameWorld, uid: String) -> Dictionary:
	for p in list(gs):
		if p["uid"] == uid:
			return p
	return {}


static func options_for(gs: GameWorld, pet: Dictionary) -> Array:
	var t: Dictionary = DivanData.PETITIONS[pet["tid"]]
	var out: Array = []
	var opts: Array = t["options"]
	for i in range(opts.size()):
		var cost := EventEngine.fx_cost(opts[i]["fx"], pet["ctx"])
		out.append({"idx": i, "text": EventEngine.fmt(gs, String(opts[i]["text"]), pet["ctx"]), "cost": cost, "affordable": cost <= gs.treasury()})
	return out


static func decide(gs: GameWorld, uid: String, idx: int) -> String:
	var pet := find(gs, uid)
	if pet.is_empty():
		return ""
	var t: Dictionary = DivanData.PETITIONS[pet["tid"]]
	var o: Dictionary = t["options"][idx]
	if EventEngine.fx_cost(o["fx"], pet["ctx"]) > gs.treasury():
		gs.notify.emit("Hazine bu karar için yetersiz.", "uyari")
		return ""
	EventEngine.apply_fx(gs, o["fx"], pet["ctx"])
	var j := int(o.get("j", 0))
	gs.state_add("justice", j * 0.5)
	gs.state_add("people_rep", j * 0.5)
	var adl: String = gs.post_holder("adalet")
	if adl != "" and j != 0:
		gs.rel_add(adl, P, {"saygi": j * 1.0})
	gs.player_skill_add("adalet", 0.5)
	list(gs).erase(pet)
	gs.w["petitions"]["heard"] = int(gs.w["petitions"].get("heard", 0)) + 1
	var choice := EventEngine.fmt(gs, String(o["text"]), pet["ctx"])
	gs.add_log("Dilekçe (%s): %s" % [String(pet["ctx"]["name"]), choice], "adalet", 1)
	# halk kabulünde bulunanlar tanık olur
	var key := "dilekce:" + String(pet["uid"])
	for wid in gs.witnesses("halk"):
		gs.add_memory(wid, "adalet_gozlem", [P], j * 8.0, "Hükümdar halkın dilekçesini dinledi: %s" % choice, "gozlem", true, {"key": key})
	gs.advance_minutes(20)
	var reaction := "Dilekçe sahibi eğilerek huzurdan çekildi."
	if j > 0:
		reaction = "Dilekçe sahibi gözyaşları içinde teşekkür etti. Salondakiler kararınızı fısıldaşıyor."
	elif j < 0:
		reaction = "Dilekçe sahibi başını önüne eğip sessizce çıktı."
	return reaction
