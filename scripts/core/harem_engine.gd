class_name HaremEngine
extends RefCounted
## Harem, eşler, gece davetleri, hamilelik, doğum ve hanedan çocukları.
## Romantik içerik açık değildir: gece "perde iner" biçiminde anlatılır.
## Hareme yalnız yetişkinler (18+) katılır; çocuk karakterler hiçbir romantik sisteme girmez.

const P := "sultan"
const CHAMBERLAIN := "cafer"


static func default_data() -> Dictionary:
	return {"candidates": [], "cand_day": -99, "nobles": [], "noble_day": -99, "proposals": [], "night": {},
		"heir": "", "children": [], "used_houses": []}


static func data(gs: GameWorld) -> Dictionary:
	if not gs.w.has("harem"):
		gs.w["harem"] = default_data()
	var h: Dictionary = gs.w["harem"]
	for k in default_data().keys():
		if not h.has(k):
			h[k] = default_data()[k]
	return h


# ------------------------------------------------------------ sorgular

static func is_harem_woman(gs: GameWorld, id: String) -> bool:
	var c: Dictionary = gs.ch(id)
	if c.is_empty() or String(c.get("gender", "")) != "f" or id == P:
		return false
	if int(c.get("age", 0)) < HaremData.MIN_AGE or c.get("royal", false):
		return false
	if not EventEngine.is_present(gs, id):
		return false
	return c.get("harem", false) or c.get("romanceable", false) or gs.is_married_to_player(id)


static func women(gs: GameWorld) -> Array:
	var out: Array = []
	for id in gs.npc_ids():
		if is_harem_woman(gs, id):
			out.append(id)
	out.sort_custom(func(a, b): return int(gs.ch(a).get("status", 0)) > int(gs.ch(b).get("status", 0)))
	return out


static func capacity(gs: GameWorld) -> int:
	return HaremData.CAPACITY[clampi(int(gs.w["state"]["palace_level"]), 0, 2)]


static func rank_name(gs: GameWorld, id: String) -> String:
	var c: Dictionary = gs.ch(id)
	if gs.is_married_to_player(id):
		var wives: Array = gs.player().get("married_to", [])
		return "Haseki Sultan (eş)" if not wives.is_empty() and wives[0] == id else "Eş"
	var r: String = c.get("rank", "")
	if r == "":
		return "Hanım Sultan" if c.get("romanceable", false) else ""
	return HaremData.RANK_NAMES.get(r, r)


static func children_of(gs: GameWorld, mother: String) -> Array:
	var out: Array = []
	for cid in data(gs)["children"]:
		var c: Dictionary = gs.ch(cid)
		if not c.is_empty() and c.get("alive", true) and String(c.get("mother", "")) == mother:
			out.append(cid)
	return out


static func living_children(gs: GameWorld) -> Array:
	var out: Array = []
	for cid in data(gs)["children"]:
		if gs.ch(cid).get("alive", true):
			out.append(cid)
	return out


static func sons(gs: GameWorld) -> Array:
	var out: Array = []
	for cid in living_children(gs):
		if String(gs.ch(cid).get("gender", "")) == "m":
			out.append(cid)
	return out


static func heir(gs: GameWorld) -> String:
	var hid: String = data(gs).get("heir", "")
	if hid != "" and gs.ch(hid).get("alive", true):
		return hid
	return ""


static func pregnancy_known(gs: GameWorld, id: String) -> bool:
	var pg: Dictionary = gs.ch(id).get("pregnancy", {})
	return not pg.is_empty() and pg.get("known", false)


static func _fert_age(age: int) -> float:
	if age < 18:
		return 0.0
	if age <= 30:
		return 1.0
	if age <= 35:
		return 0.7
	if age <= 40:
		return 0.35
	if age <= 44:
		return 0.1
	return 0.0


# ------------------------------------------------------------ adaylar

static func _used_names(gs: GameWorld) -> Array:
	var out: Array = []
	for id in gs.w["characters"].keys():
		out.append(String(gs.ch(id).get("name", "")))
	for c in data(gs)["candidates"]:
		out.append(String(c["proto"]["name"]))
	return out


static func _pick_name(gs: GameWorld, pool: Array) -> String:
	var used := _used_names(gs)
	var free: Array = []
	for n in pool:
		if not n in used:
			free.append(n)
	if free.is_empty():
		free = pool
	return free[gs.rng.randi() % free.size()]


static func _traits(gs: GameWorld, temper: Dictionary, base: Dictionary = {}) -> Dictionary:
	var t := {}
	for k in CharactersData.TRAIT_NAMES.keys():
		var v := float(base.get(k, 50)) + float(temper.get("tr", {}).get(k, 0)) + gs.rng.randf_range(-12.0, 12.0)
		t[k] = int(clampf(v, 8.0, 95.0))
	return t


const GOALS := ["Hükümdarın gözüne girmek", "Haremde huzur içinde yaşamak", "Bir gün kendi dairesine sahip olmak",
	"Ailesine haber gönderebilmek", "Sarayda saygın bir yer edinmek", "Yeteneğiyle tanınmak"]
const SECRETS := ["Haseki olmak", "Valide Sultan'ın gözdesi olmak", "Bir gün azat edilip memleketine dönmek",
	"Haremde kendi hizbini kurmak", "Saraydaki eski bir tanıdığını bulmak"]
const FEARS := ["Unutulmak", "Haremde yalnız kalmak", "Eski Saray'a gönderilmek", "Kıskançlıkların hedefi olmak"]


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


static func gen_cariye(gs: GameWorld) -> Dictionary:
	var rng := gs.rng
	var origin: Dictionary = HaremData.ORIGINS[rng.randi() % HaremData.ORIGINS.size()]
	var talent: Array = HaremData.TALENTS[rng.randi() % HaremData.TALENTS.size()]
	var temper: Dictionary = HaremData.TEMPERS[rng.randi() % HaremData.TEMPERS.size()]
	var age := rng.randi_range(HaremData.MIN_AGE, 25)
	var name := _pick_name(gs, HaremData.CARIYE_NAMES)
	var skills := {}
	for s in CharactersData.SKILL_NAMES.keys():
		skills[s] = rng.randi_range(12, 30) + int(talent[3].get(s, 0))
	var robe: String = HaremData.ROBE_COLORS[rng.randi() % HaremData.ROBE_COLORS.size()]
	var hotoz: String = HaremData.HOTOZ_COLORS[rng.randi() % HaremData.HOTOZ_COLORS.size()]
	var secret: String = SECRETS[rng.randi() % SECRETS.size()]
	var proto := {
		"name": name, "title": "Hatun", "full": name + " Hatun", "gender": "f", "age": age, "role": "harem",
		"status": HaremData.RANK_STATUS["cariye"], "profile": "cariye", "home": "harem", "post": "",
		"harem": true, "rank": "cariye", "romanceable": true, "talent": talent[0], "origin": origin["t"],
		"fertility": rng.randf_range(0.75, 1.15), "nights": 0,
		"traits": _traits(gs, temper), "skills": skills,
		"goals": [GOALS[rng.randi() % GOALS.size()]], "secret_goal": secret, "fears": [FEARS[rng.randi() % FEARS.size()]],
		"likes": [talent[2], "cicek" if rng.randf() < 0.5 else "kumas"],
		"look": {"robe": robe, "accent": "d8b45a", "outer": robe, "head": "hotoz", "hotoz_color": hotoz, "skin": int(origin["skin"])},
		"bio": "%s gelen %s yaşında bir genç kadın; %s. Kendisi %s biri." % [origin["t"], age, talent[1], temper["t"]],
		"lore": [
			{"trust": 0, "t": "%s geldi; saraya geldiğinde Kethüda Gülbahar Hatun'un yanında harem usullerini öğrendi." % _cap(String(origin["t"]))},
			{"trust": 45, "t": "Geride bıraktığı ailesini hâlâ özlüyor; geceleri onlar için mektup yazıp gönderemediği bir sandıkta saklıyor."},
			{"trust": 70, "t": "En büyük arzusu: %s." % secret.to_lower()},
		],
		"rel_to_player": {"sevgi": rng.randi_range(35, 50), "guven": rng.randi_range(30, 45), "saygi": rng.randi_range(65, 80), "romantik": rng.randi_range(5, 18)},
	}
	var price := 1200 + rng.randi_range(0, 8) * 150
	var desc := "%s, %d yaşında. %s gelmiş; %s. Tabiatı %s." % [proto["full"], age, _cap(String(origin["t"])), talent[1], temper["t"]]
	return {"proto": proto, "price": price, "desc": desc}


static func refresh_candidates(gs: GameWorld, force: bool = false) -> Array:
	var h := data(gs)
	if force or h["candidates"].is_empty() or gs.get_day() - int(h["cand_day"]) >= 12:
		h["cand_day"] = gs.get_day()
		h["candidates"] = []
		for i in range(3):
			h["candidates"].append(gen_cariye(gs))
	return h["candidates"]


static func accept_cariye(gs: GameWorld, idx: int) -> String:
	var h := data(gs)
	var cands: Array = h["candidates"]
	if idx < 0 or idx >= cands.size():
		return "Bu aday artık sarayda değil."
	if women(gs).size() >= capacity(gs):
		return "Harem dolu, Hünkârım (%d kişilik). Sarayı genişletmeden yeni birini alamayız." % capacity(gs)
	var cand: Dictionary = cands[idx]
	if not gs.spend(float(cand["price"]), "harem"):
		return "Hazinede yeterli akçe yok."
	cands.remove_at(idx)
	var id := gs.add_character(cand["proto"], "h")
	var c: Dictionary = gs.ch(id)
	gs.add_memory(id, "saraya_gelis", [P], 20.0, "Saraya geldim; harem artık evim.", "dogrudan", true, {"key": "gelis:" + id})
	gs.set_rel_values(id, "mahinur", {"saygi": 80, "korku": 35, "sevgi": 40})
	gs.set_rel_values(id, "gulbahar", {"saygi": 75, "korku": 25})
	gs.set_rel_values("mahinur", id, {"sevgi": 40, "guven": 35})
	for oid in women(gs):
		if oid != id:
			gs.rel_add(oid, id, {"kiskanclik": 5.0 + gs.trait_of(oid, "kiskanclik") / 20.0, "rekabet": 4.0}, false)
	gs.add_log("%s hareme katıldı." % String(c["full"]), "harem", 2)
	return "%s yarın sabahtan itibaren haremde, Hünkârım. Kethüda Gülbahar Hatun onu yerleştirdi." % String(c["full"])


# ------------------------------------------------------------ soylu eş adayları

static func refresh_nobles(gs: GameWorld) -> Array:
	var h := data(gs)
	if h["nobles"].is_empty() or gs.get_day() - int(h["noble_day"]) >= 30:
		h["noble_day"] = gs.get_day()
		var houses: Array = []
		for hs in HaremData.NOBLE_HOUSES:
			if not hs["id"] in h["used_houses"]:
				houses.append(hs)
		houses.shuffle()
		var arr: Array = []
		for i in range(mini(2, houses.size())):
			arr.append(_gen_noble(gs, houses[i]))
		h["nobles"] = arr
	return h["nobles"]


static func _gen_noble(gs: GameWorld, house: Dictionary) -> Dictionary:
	var rng := gs.rng
	var temper: Dictionary = HaremData.TEMPERS[rng.randi() % HaremData.TEMPERS.size()]
	var name := _pick_name(gs, HaremData.NOBLE_NAMES)
	var age := rng.randi_range(HaremData.MIN_AGE + 1, 26)
	var talent: Array = HaremData.TALENTS[rng.randi() % HaremData.TALENTS.size()]
	var skills := {}
	for s in CharactersData.SKILL_NAMES.keys():
		skills[s] = rng.randi_range(25, 45) + int(talent[3].get(s, 0))
	var robe: String = HaremData.ROBE_COLORS[rng.randi() % HaremData.ROBE_COLORS.size()]
	var proto := {
		"name": name, "title": "Hanım", "full": name + " Hanım", "gender": "f", "age": age, "role": "harem",
		"status": 65, "profile": "harem_lady", "home": "harem", "post": "", "harem": true, "rank": "",
		"romanceable": true, "talent": talent[0], "origin": house["family"], "house": house["id"],
		"fertility": rng.randf_range(0.8, 1.1), "nights": 0,
		"traits": _traits(gs, temper, {"ozguven": 60, "diplomasi": 58}), "skills": skills,
		"goals": ["Ailesinin itibarını korumak", "Sarayda söz sahibi olmak"], "secret_goal": "Haseki olmak",
		"fears": ["Ailesini utandırmak"], "likes": ["mucevher", talent[2]],
		"look": {"robe": robe, "accent": "e0c070", "outer": robe, "head": "hotoz", "hotoz_color": HaremData.HOTOZ_COLORS[rng.randi() % HaremData.HOTOZ_COLORS.size()], "skin": int(house["skin"])},
		"bio": "%s. %d yaşında; %s. Tabiatı %s." % [house["family"], age, talent[1], temper["t"]],
		"lore": [
			{"trust": 0, "t": "%s; evlilik için saraya geldi." % house["family"]},
			{"trust": 50, "t": "Ailesi ondan sarayda güçlü bir yer edinmesini bekliyor; mektuplarla sık sık öğüt yağdırıyorlar."},
			{"trust": 70, "t": "Aslında bu evliliği kendisi seçmedi; ama artık burada kalmaya, sevmeyi öğrenmeye kararlı."},
		],
		"rel_to_player": {"sevgi": 35, "guven": 35, "saygi": 75, "romantik": 12},
	}
	var chance := 0.55 + (float(gs.w["state"]["prestige"]) - 50.0) / 80.0 + (float(gs.w["state"]["legitimacy"]) - 50.0) / 160.0
	if house.has("nb"):
		chance += (float(_nb(gs, house["nb"]).get("attitude", 50)) - 50.0) / 90.0
	var desc := "%s %s (%d). %s. Mehir ve elçilik hediyeleri: %s." % [house["family"], name, age, _benefit_text(gs, house), gs.fmt_money(float(house["dowry"]))]
	return {"proto": proto, "house": house, "chance": clampf(chance, 0.15, 0.95), "desc": desc}


static func _nb(gs: GameWorld, nid: String) -> Dictionary:
	for nb in gs.w["neighbors"]:
		if nb["id"] == nid:
			return nb
	return {}


static func _benefit_text(gs: GameWorld, house: Dictionary) -> String:
	match String(house["fx"]):
		"prov":
			var pn: String = String(gs.province(String(house["prov"])).get("name", house["prov"]))
			return "%s eyaletinin %s artar" % [pn, "sadakati" if house["stat"] == "sadakat" else "güvenliği"]
		"nb":
			return "%s ile ilişkiler büyük ölçüde iyileşir" % String(_nb(gs, house["nb"]).get("name", house["nb"]))
		"treasury":
			return "aile hazineye %s çeyiz getirir" % gs.fmt_money(float(house["v"]))
	return ""


static func propose_noble(gs: GameWorld, idx: int) -> String:
	var h := data(gs)
	var arr: Array = h["nobles"]
	if idx < 0 or idx >= arr.size():
		return "Bu teklif artık geçerli değil."
	if gs.player().get("married_to", []).size() + _pending_brides(gs) >= HaremData.MAX_WIVES:
		return "Dört eşten fazlası şer'an mümkün değil, Hünkârım."
	if women(gs).size() >= capacity(gs):
		return "Harem dolu, Hünkârım. Sarayı genişletmeden yeni bir gelin alamayız."
	var nob: Dictionary = arr[idx]
	var cost := float(nob["house"]["dowry"])
	if not gs.spend(cost, "mehir"):
		return "Mehir ve hediyeler için hazinede yeterli akçe yok."
	arr.remove_at(idx)
	h["used_houses"].append(nob["house"]["id"])
	h["proposals"].append({"noble": nob, "due": gs.get_day() + 4, "cost": cost})
	gs.add_log("%s için elçiler yola çıktı." % String(nob["house"]["family"]), "hanedan", 1)
	return "Elçiler ve hediyeler yarın yola çıkıyor, Hünkârım. Dört gün içinde cevap gelir."


static func _pending_brides(gs: GameWorld) -> int:
	var n := 0
	for id in women(gs):
		if gs.flag("nisan:" + id) and not gs.is_married_to_player(id):
			n += 1
	return n + data(gs)["proposals"].size()


static func _resolve_proposal(gs: GameWorld, pr: Dictionary) -> void:
	var nob: Dictionary = pr["noble"]
	var house: Dictionary = nob["house"]
	if gs.rng.randf() > float(nob["chance"]):
		gs.earn(float(pr["cost"]) * 0.5)
		gs.state_add("prestige", -1.0)
		if house.has("nb"):
			_nb(gs, house["nb"])["attitude"] = clampf(float(_nb(gs, house["nb"]).get("attitude", 50)) - 3.0, 0.0, 100.0)
		gs.add_log("%s evlilik teklifinizi nazikçe geri çevirdi. Hediyelerin yarısı iade edildi." % String(house["family"]), "hanedan", 2)
		return
	var id := gs.add_character(nob["proto"], "h")
	gs.set_flag("nisan:" + id, true)
	match String(house["fx"]):
		"prov":
			var p: Dictionary = gs.province(String(house["prov"]))
			if not p.is_empty():
				p[house["stat"]] = clampf(float(p[house["stat"]]) + float(house["v"]), 0.0, 100.0)
		"nb":
			var nb := _nb(gs, house["nb"])
			if not nb.is_empty():
				nb["attitude"] = clampf(float(nb["attitude"]) + float(house["v"]), 0.0, 100.0)
		"treasury":
			gs.earn(float(house["v"]))
	gs.state_add("prestige", 2.0)
	gs.set_rel_values(id, "mahinur", {"saygi": 80, "korku": 25, "sevgi": 45})
	gs.set_rel_values("mahinur", id, {"sevgi": 50, "guven": 40, "saygi": 55})
	for oid in women(gs):
		if oid != id:
			gs.rel_add(oid, id, {"kiskanclik": 10.0, "rekabet": 8.0}, false)
	gs.add_log("%s teklifi kabul etti! %s saraya geldi; düğün hazırlıkları başlıyor." % [String(house["family"]), String(gs.ch(id)["full"])], "hanedan", 2)
	EventEngine.schedule(gs, "dugun", 1, {"bride": id})


# ------------------------------------------------------------ nikâh, azat, veliaht

static func nikah_candidates(gs: GameWorld) -> Array:
	var out: Array = []
	for id in women(gs):
		var c: Dictionary = gs.ch(id)
		if gs.is_married_to_player(id) or gs.flag("nisan:" + id):
			continue
		if not c.get("harem", false):
			continue   # Leyla ve Feraye kendi gönülleriyle karar verir (onlarla konuşun)
		if String(c.get("rank", "")) in ["ikbal", "kadin"] or not children_of(gs, id).is_empty():
			out.append(id)
	return out


static func nikah(gs: GameWorld, id: String) -> String:
	if gs.player().get("married_to", []).size() + _pending_brides(gs) >= HaremData.MAX_WIVES:
		return "Dört eşten fazlası şer'an mümkün değil, Hünkârım."
	var rom := gs.rel_val(id, P, "romantik")
	var score := rom * 0.6 + gs.rel_val(id, P, "sevgi") * 0.3 + gs.trait_of(id, "hirs") * 0.2
	if score < 50.0:
		gs.rel_add(id, P, {"romantik": -2.0})
		return "%s bu teklifi duyunca uzun uzun sustu, Hünkârım; gönlü henüz hazır değil gibi. Biraz zaman tanıyın." % gs.short_name(id)
	gs.set_flag("nisan:" + id, true)
	gs.add_memory(id, "nisan", [P], 55.0, "Hükümdar benimle nikâh kıymak istedi.", "dogrudan", true, {"key": "nisan:" + id})
	for oid in women(gs):
		if oid != id:
			gs.rel_add(oid, id, {"kiskanclik": 10.0, "rekabet": 6.0}, false)
	EventEngine.schedule(gs, "dugun", 1, {"bride": id})
	gs.add_log("%s ile nikâh hazırlıkları başladı." % gs.short_name(id), "hanedan", 2)
	return "Müjdeyi bizzat ben götürdüm, Hünkârım. %s sevinç gözyaşlarını görmeliydiniz. Yarın düğün hazırlıkları başlıyor." % TR.gen(gs.short_name(id))


static func azat_candidates(gs: GameWorld) -> Array:
	var out: Array = []
	for id in women(gs):
		var c: Dictionary = gs.ch(id)
		if c.get("harem", false) and String(c.get("rank", "")) in ["cariye", "gozde"] and children_of(gs, id).is_empty() and not gs.is_married_to_player(id):
			out.append(id)
	return out


static func azat(gs: GameWorld, id: String) -> String:
	if not gs.spend(1500.0, "cehiz"):
		return "Çeyiz için hazinede 1.500 akçe yok."
	var c: Dictionary = gs.ch(id)
	var wanted: bool = String(c.get("secret_goal", "")).contains("azat")
	gs.rel_add(id, P, {"sevgi": 25.0 if wanted else 5.0, "borcluluk": 40.0})
	gs.state_add("justice", 1.0)
	EventEngine.char_gone(gs, id, "%s çeyiziyle azat edildi; Şahriyar'da hayırlı bir evlilik yapacak." % String(c["full"]))
	if wanted:
		return "Azat kâğıdını eline verdiğimde ellerinizi öpmek istedi, Hünkârım. Hayır dualarıyla gitti."
	return "%s azat edildi. Biraz şaşırdı ama çeyizini görünce gönlü ferahladı." % gs.short_name(id)


static func set_heir(gs: GameWorld, cid: String) -> String:
	var h := data(gs)
	var old := heir(gs)
	h["heir"] = cid
	var c: Dictionary = gs.ch(cid)
	var mother: String = c.get("mother", "")
	if mother != "" and EventEngine.is_present(gs, mother):
		gs.rel_add(mother, P, {"sevgi": 10.0, "siyasi_uyum": 12.0})
		gs.ch(mother)["status"] = int(gs.ch(mother)["status"]) + 8
	if old != "" and old != cid:
		var om: String = gs.ch(old).get("mother", "")
		if om != "" and EventEngine.is_present(gs, om):
			gs.rel_add(om, P, {"sevgi": -15.0, "siyasi_uyum": -15.0})
			gs.add_memory(om, "ret", [P], -45.0, "Oğlumun veliahtlığı elinden alındı.", "dogrudan", true, {"key": "veliaht:" + cid})
			if mother != "":
				gs.rel_add(om, mother, {"kiskanclik": 20.0, "rekabet": 25.0}, false)
	gs.state_add("legitimacy", 2.0)
	gs.w["dynasty"]["history"].append({"day": gs.get_day(), "text": "%s veliaht ilan edildi." % String(c["full"])})
	gs.add_log("%s veliaht ilan edildi." % String(c["full"]), "hanedan", 2)
	return "Ferman yazıldı, Hünkârım: %s artık tahtın varisi." % String(c["full"])


static func set_edu(gs: GameWorld, cid: String, focus: String) -> String:
	gs.ch(cid)["edu"] = focus
	return "%s bundan sonra %s üzerine yoğunlaşacak. Molla Sadık ve lalası her gün başında olacak." % [String(gs.ch(cid)["full"]), String(HaremData.EDU[focus]["name"]).to_lower()]


# ------------------------------------------------------------ gece daveti

static func night_day(gs: GameWorld) -> int:
	return gs.get_day() - 1 if gs.get_hour() < 6 else gs.get_day()


static func invite_reason(gs: GameWorld, id: String) -> String:
	if not is_harem_woman(gs, id):
		return "Bu mümkün değil."
	var h := data(gs)
	if not h["night"].is_empty() and int(h["night"]["day"]) == night_day(gs):
		return "Bu gece için zaten %s davet edildi." % gs.short_name(String(h["night"]["who"]))
	if gs.ch(id).get("location", "") == "disari":
		return "%s şu an saray dışında." % gs.short_name(id)
	if gs.get_hour() >= 1 and gs.get_hour() < 6:
		return "Gece çok ilerledi, Hünkârım."
	return ""


static func willingness(gs: GameWorld, id: String) -> float:
	var c: Dictionary = gs.ch(id)
	var w := gs.rel_val(id, P, "romantik") * 0.45 + gs.rel_val(id, P, "sevgi") * 0.3 + float(c.get("mood", 0)) * 0.15
	w += {"cariye": 15.0, "gozde": 17.0, "ikbal": 19.0, "kadin": 19.0}.get(String(c.get("rank", "")), 0.0)
	if gs.is_married_to_player(id):
		w += 22.0
	if not c.get("harem", false) and not gs.is_married_to_player(id):
		w -= 25.0   # Leyla ve Feraye gibi soylu hanımlar nikâhsız davete sıcak bakmaz
	return w


static func invite(gs: GameWorld, id: String) -> Dictionary:
	var why := invite_reason(gs, id)
	if why != "":
		return {"ok": false, "text": why}
	var c: Dictionary = gs.ch(id)
	var pg: Dictionary = c.get("pregnancy", {})
	if not pg.is_empty() and gs.get_day() - int(pg["start"]) > 150:
		return {"ok": false, "text": "Hekimbaşı Lokman Efendi, %s için dinlenmeyi öğütledi, Hünkârım. Doğuma kadar yorulmamalı." % gs.short_name(id)}
	if willingness(gs, id) < 30.0:
		gs.rel_add(id, P, {"romantik": -0.5})
		if not c.get("harem", false) and not gs.is_married_to_player(id):
			return {"ok": false, "text": "%s nazik ama kesin bir dille cevap verdi: nikâhsız bir davete icabet edemeyeceğini bildirdi." % gs.short_name(id)}
		return {"ok": false, "text": "%s bu gece rahatsız olduğunu bildirdi, Hünkârım; affınızı diliyor." % gs.short_name(id)}
	data(gs)["night"] = {"who": id, "day": night_day(gs)}
	if gs.get_hour() >= 20 or gs.get_hour() < 1:
		gs.set_override(id, "hukumdar", "dinlenme", 6 * 60)
	gs.add_memory(id, "davet", [P], 15.0, "Hükümdar beni bu gece dairesine davet etti.", "dogrudan", true, {"key": "davet:%s:%d" % [id, gs.get_day()]})
	gs.adjust_mood(id, 10.0)
	return {"ok": true, "text": "%s bu akşam dairenizde olacak, Hünkârım. Yatağınıza çekildiğinizde... gerisi sizin bileceğiniz iş." % gs.short_name(id)}


static func night_ready(gs: GameWorld) -> bool:
	var n: Dictionary = data(gs)["night"]
	if n.is_empty() or int(n["day"]) != night_day(gs):
		return false
	var h := gs.get_hour()
	return (h >= 19 or h < 6) and EventEngine.is_present(gs, String(n["who"]))


static func night_guest(gs: GameWorld) -> String:
	var n: Dictionary = data(gs)["night"]
	return "" if n.is_empty() else String(n["who"])


static func do_night(gs: GameWorld) -> Dictionary:
	var h := data(gs)
	if h["night"].is_empty():
		return {}
	var id: String = h["night"]["who"]
	h["night"] = {}
	var c: Dictionary = gs.ch(id)
	c["nights"] = int(c.get("nights", 0)) + 1
	gs.rel_add(id, P, {"romantik": 7.0, "sevgi": 4.0, "guven": 2.0})
	gs.adjust_mood(id, 15.0)
	gs.add_memory(id, "gece", [P], 30.0, "Hükümdarla geceyi geçirdim.", "dogrudan", true, {"key": "gece:%s:%d" % [id, gs.get_day()]})
	var promo := ""
	var rank: String = c.get("rank", "")
	if c.get("harem", false) and not gs.is_married_to_player(id):
		if rank == "cariye":
			c["rank"] = "gozde"
			promo = "gozde"
		elif rank == "gozde" and (int(c["nights"]) >= 3 or gs.rel_val(id, P, "romantik") >= 55.0):
			c["rank"] = "ikbal"
			promo = "ikbal"
		if promo != "":
			c["status"] = maxi(int(c["status"]), int(HaremData.RANK_STATUS[promo]))
			gs.add_log("%s artık haremde %s." % [String(c["full"]), String(HaremData.RANK_NAMES[promo]).to_lower()], "harem", 1)
	for oid in women(gs):
		if oid == id:
			continue
		if gs.rng.randf() < 0.6:
			gs.rel_add(oid, id, {"kiskanclik": 3.0 + gs.trait_of(oid, "kiskanclik") / 25.0}, false)
			if gs.rel_val(oid, P, "romantik") > 30.0:
				gs.rel_add(oid, P, {"romantik": -1.0}, false)
	# hamilelik
	var pregnant := false
	if c.get("pregnancy", {}).is_empty():
		var p := 0.2 * _fert_age(int(c.get("age", 30))) * float(c.get("fertility", 1.0))
		if gs.get_day() - int(gs.w["flags"].get("hekim_serbet", -999)) <= 30:
			p *= 1.35
		if gs.rng.randf() < p:
			c["pregnancy"] = {"start": gs.get_day(), "due": gs.get_day() + 262 + gs.rng.randi_range(0, 14), "known": false}
			pregnant = true
	var talent: String = c.get("talent", "")
	var scene := "Mumlar bir bir söndü; perde indi."
	match talent:
		"ud":
			scene = "Gece, %s ud nağmeleri arasında geçti. Mumlar bir bir söndü; perde indi." % TR.gen(gs.short_name(id))
		"siir":
			scene = "%s size yeni yazdığı bir gazeli okudu. Gece ilerledi; perde indi." % gs.short_name(id)
		"hikaye":
			scene = "%s anlattığı hikâyelerle sizi güldürdü. Mumlar söndü; perde indi." % gs.short_name(id)
		"satranc":
			scene = "Bir satranç oyunuyla başlayan gece, uzun bir sohbetle sürdü. Perde indi."
	gs.add_log("Gece, hükümdar dairesinde %s ile geçti." % gs.short_name(id), "harem", 1)
	gs.set_flag("son_gece", id)
	return {"who": id, "text": scene, "promo": promo, "pregnant": pregnant}


static func _check_missed_night(gs: GameWorld) -> void:
	var h := data(gs)
	var n: Dictionary = h["night"]
	if n.is_empty():
		return
	if night_day(gs) > int(n["day"]):
		var id: String = n["who"]
		h["night"] = {}
		if EventEngine.is_present(gs, id):
			gs.rel_add(id, P, {"romantik": -4.0, "sevgi": -3.0})
			gs.adjust_mood(id, -12.0)
			gs.add_memory(id, "kirginlik", [P], -25.0, "Hükümdarın dairesinde gece boyunca bekledim; gelmedi.", "dogrudan", true, {"key": "bekledi:%s:%d" % [id, int(n["day"])]})
			gs.add_log("%s dün gece dairenizde boşuna bekledi. Kırgın." % gs.short_name(id), "harem", 2)


# ------------------------------------------------------------ zaman

static func hourly(gs: GameWorld) -> void:
	var h := data(gs)
	var n: Dictionary = h["night"]
	if not n.is_empty() and int(n["day"]) == gs.get_day() and gs.get_hour() == 20:
		var id: String = n["who"]
		if EventEngine.is_present(gs, id):
			gs.set_override(id, "hukumdar", "dinlenme", 6 * 60)
			gs.notify.emit("%s dairenizde sizi bekliyor. Yatağınıza çekildiğinizde gece başlar." % gs.short_name(id), "harem")
	if gs.get_hour() == 6:
		_check_missed_night(gs)


static func daily(gs: GameWorld) -> void:
	var h := data(gs)
	# evlilik teklifleri
	var keep: Array = []
	for pr in h["proposals"]:
		if gs.get_day() >= int(pr["due"]):
			_resolve_proposal(gs, pr)
		else:
			keep.append(pr)
	h["proposals"] = keep
	# hamilelikler
	for id in gs.npc_ids():
		var c: Dictionary = gs.ch(id)
		var pg: Dictionary = c.get("pregnancy", {})
		if pg.is_empty():
			continue
		var d := gs.get_day() - int(pg["start"])
		if not pg.get("known", false) and d >= 35:
			pg["known"] = true
			if not (EventEngine.is_present(gs, "lokman") and EventEngine.add_event(gs, "hamile_mujde", {"mother": id})):
				_announce(gs, id)
			gs.set_flag("stop_skip", true)
		if gs.get_day() >= int(pg["due"]):
			birth(gs, id)
	# çocukların büyüme evreleri
	for cid in living_children(gs):
		_update_child_profile(gs, cid)
	_maybe_quarrel(gs)


## Birbirini kıskanan iki harem hanımı arasında kavga çıkabilir (Kethüda haber verir)
static func _maybe_quarrel(gs: GameWorld) -> void:
	if not EventEngine.is_present(gs, "gulbahar") or EventEngine.pending(gs).size() >= EventEngine.MAX_PENDING:
		return
	var fired: Dictionary = gs.w["events"]["fired"]
	if fired.has("harem_kavga") and gs.get_day() - int(fired["harem_kavga"]) < 15:
		return
	if gs.rng.randf() > 0.05:
		return
	var ws := women(gs)
	var best: Array = []
	var bv := 0.0
	for a in ws:
		for b in ws:
			if a == b:
				continue
			var v := gs.rel_val(a, b, "kiskanclik") + gs.rel_val(b, a, "kiskanclik")
			if gs.rel_val(a, b, "kiskanclik") >= 40.0 and gs.rel_val(b, a, "kiskanclik") >= 30.0 and v > bv:
				bv = v
				best = [a, b]
	if best.is_empty() or bv < 85.0:
		return
	EventEngine.add_event(gs, "harem_kavga", {"a": best[0], "b": best[1]})


static func _announce(gs: GameWorld, id: String) -> void:
	var c: Dictionary = gs.ch(id)
	c["status"] = int(c["status"]) + 6
	gs.adjust_mood(id, 20.0)
	gs.rel_add("mahinur", id, {"sevgi": 10.0, "saygi": 6.0}, false)
	for oid in women(gs):
		if oid != id:
			gs.rel_add(oid, id, {"kiskanclik": 10.0, "rekabet": 6.0}, false)
	gs.add_log("Müjde! %s hamile. Saray bir varis bekliyor." % gs.short_name(id), "hanedan", 2)


static func announce(gs: GameWorld, id: String) -> void:
	_announce(gs, id)


static func birth(gs: GameWorld, mother: String) -> void:
	var mc: Dictionary = gs.ch(mother)
	mc.erase("pregnancy")
	var boy := gs.rng.randf() < 0.5
	var pool: Array = HaremData.SON_NAMES if boy else HaremData.DAUGHTER_NAMES
	var names: Array = []
	var used := _used_names(gs)
	var shuffled: Array = pool.duplicate()
	shuffled.shuffle()
	for n in shuffled:
		if not n in used:
			names.append(n)
		if names.size() >= 3:
			break
	while names.size() < 3:
		names.append(pool[gs.rng.randi() % pool.size()])
	var name: String = names[0]
	var pl: Dictionary = gs.player()
	var traits := {}
	for k in CharactersData.TRAIT_NAMES.keys():
		var v := (float(mc["traits"].get(k, 50)) + float(pl["traits"].get(k, 50))) * 0.5 + gs.rng.randf_range(-15.0, 15.0)
		traits[k] = int(clampf(v, 5.0, 95.0))
	var robe: String = HaremData.ROBE_COLORS[gs.rng.randi() % HaremData.ROBE_COLORS.size()]
	var proto := {
		"name": name, "title": "Şehzade" if boy else "Sultan", "full": ("Şehzade " + name) if boy else (name + " Sultan"),
		"gender": "m" if boy else "f", "age": 0, "role": "child", "royal": true, "status": 75 if boy else 65,
		"profile": "infant", "home": "sehzade" if boy else String(mc.get("home", "harem")),
		"mother": mother, "father": P, "romanceable": false, "post": "", "harem": false, "edu": "",
		"traits": traits, "skills": {"yonetim": 3, "ekonomi": 2, "askeri": 3, "diplomasi": 2, "adalet": 2, "ilim": 3},
		"likes": ["cicek", "kitap"],
		"look": {"robe": robe, "accent": "e0c070", "outer": robe, "head": "sarik_small" if boy else "", "skin": int(mc.get("look", {}).get("skin", 1))},
		"bio": "Sultan %s ile %s %s." % [String(pl["name"]), TR.gen(String(mc["name"])), "oğlu" if boy else "kızı"],
		"rel_to_player": {"sevgi": 80, "guven": 70, "saygi": 70},
	}
	var cid := gs.add_character(proto, "c")
	gs.set_rel_values(cid, mother, {"sevgi": 95, "guven": 90})
	gs.set_rel_values(mother, cid, {"sevgi": 100, "guven": 90})
	gs.set_rel_values("mahinur", cid, {"sevgi": 85})
	var h := data(gs)
	h["children"].append(cid)
	# annenin konumu
	if not gs.is_married_to_player(mother) and mc.get("harem", false):
		mc["rank"] = "kadin"
		mc["title"] = "Kadın"
		mc["full"] = String(mc["name"]) + " Kadın"
		mc["status"] = maxi(int(mc["status"]), int(HaremData.RANK_STATUS["kadin"]))
	else:
		mc["status"] = int(mc["status"]) + 8
	gs.rel_add(mother, P, {"sevgi": 10.0, "guven": 6.0})
	gs.add_memory(mother, "dogum", [P], 60.0, "%s dünyaya geldi." % String(gs.ch(cid)["full"]), "dogrudan", true, {"key": "dogum:" + cid})
	gs.rel_add("mahinur", P, {"sevgi": 8.0})
	gs.rel_add("mahinur", mother, {"sevgi": 12.0, "saygi": 8.0}, false)
	for oid in women(gs):
		if oid != mother:
			gs.rel_add(oid, mother, {"kiskanclik": 12.0, "rekabet": 10.0}, false)
	for nid in gs.npc_ids():
		gs.adjust_mood(nid, 5.0)
	var first_son := boy and sons(gs).size() == 1
	if boy and heir(gs) == "":
		h["heir"] = cid
	if first_son:
		gs.state_add("legitimacy", 6.0)
		gs.state_add("prestige", 3.0)
	else:
		gs.state_add("prestige", 1.0)
	gs.w["dynasty"]["history"].append({"day": gs.get_day(), "text": "%s doğdu (annesi %s)." % [String(gs.ch(cid)["full"]), String(mc["name"])]})
	gs.add_log("%s dünyaya geldi! Annesi %s." % [String(gs.ch(cid)["full"]), gs.short_name(mother)], "hanedan", 2)
	EventEngine.add_event(gs, "dogum", {"child": cid, "mother": mother, "n1": names[0], "n2": names[1], "n3": names[2],
		"cocuk": "bir şehzade" if boy else "bir kız, bir sultan", "ilk": " Bu, hanedanın ilk şehzadesi!" if first_son else ""})
	gs.set_flag("stop_skip", true)


static func rename_child(gs: GameWorld, cid: String, name: String) -> void:
	var c: Dictionary = gs.ch(cid)
	if c.is_empty():
		return
	var old: String = c["full"]
	c["name"] = name
	c["full"] = ("Şehzade " + name) if String(c["gender"]) == "m" else (name + " Sultan")
	for e in gs.w["dynasty"]["history"]:
		e["text"] = String(e["text"]).replace(old, String(c["full"]))


static func _update_child_profile(gs: GameWorld, cid: String) -> void:
	var c: Dictionary = gs.ch(cid)
	var age := int(c.get("age", 0))
	var want := "infant"
	if age >= 7:
		want = "child"
	elif age >= 5:
		want = "child_small"
	if String(c.get("profile", "")) != want:
		c["profile"] = want


static func yearly(gs: GameWorld) -> void:
	for cid in living_children(gs):
		var c: Dictionary = gs.ch(cid)
		var age := int(c.get("age", 0))
		if age < 5:
			continue
		var sk: Dictionary = c["skills"]
		var focus: String = c.get("edu", "")
		var gain: Dictionary = HaremData.EDU.get(focus, {}).get("skills", {})
		var tutor := 1.0 + (gs.skill_of("sadik", "ilim") - 60.0) / 100.0 if EventEngine.is_present(gs, "sadik") else 0.8
		for s in sk.keys():
			var g := 1.0 + float(gain.get(s, 0)) * tutor
			sk[s] = clampf(float(sk[s]) + g, 0.0, 100.0)
		_update_child_profile(gs, cid)
		if age == 5:
			gs.add_log("%s beş yaşına girdi; artık sarayın bahçelerinde görülebilir." % String(c["full"]), "hanedan", 1)
		elif age == 7:
			gs.add_log("%s yedi yaşında; Molla Sadık'ın derslerine başladı." % String(c["full"]), "hanedan", 1)


# ------------------------------------------------------------ raporlar

static func report(gs: GameWorld) -> String:
	var lines: Array = []
	lines.append("Haremde %d / %d kişi var, Hünkârım." % [women(gs).size(), capacity(gs)])
	for id in women(gs):
		var c: Dictionary = gs.ch(id)
		var bits: Array = [rank_name(gs, id)]
		bits.append(gs.mood_label(float(c.get("mood", 0))).to_lower())
		bits.append("size bakışı: %s" % gs.opinion_label(gs.opinion(id, P)).to_lower())
		if pregnancy_known(gs, id):
			bits.append("[color=#f0b8cc]hamile[/color]")
		var kids := children_of(gs, id)
		if not kids.is_empty():
			bits.append("%d çocuk" % kids.size())
		lines.append("• %s — %s" % [String(c["full"]), ", ".join(PackedStringArray(bits))])
	var hid := heir(gs)
	if hid != "":
		lines.append("\nVeliaht: %s (%d yaşında)." % [String(gs.ch(hid)["full"]), int(gs.ch(hid)["age"])])
	return "\n".join(PackedStringArray(lines))


static func dynasty_report(gs: GameWorld) -> String:
	var kids := living_children(gs)
	if kids.is_empty():
		return "Henüz bir şehzade ya da sultan dünyaya gelmedi, Hünkârım. Hanedanın geleceği hepimizin duasında."
	var lines: Array = []
	for cid in kids:
		var c: Dictionary = gs.ch(cid)
		var edu: String = c.get("edu", "")
		var e_txt := "" if edu == "" else ", eğitimi: " + String(HaremData.EDU[edu]["name"]).to_lower()
		var tag := " [color=#e0c070](veliaht)[/color]" if cid == heir(gs) else ""
		lines.append("• %s%s — %d yaşında, annesi %s%s" % [String(c["full"]), tag, int(c["age"]), gs.short_name(String(c.get("mother", ""))), e_txt])
	return "\n".join(PackedStringArray(lines))
