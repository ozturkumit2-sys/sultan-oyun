class_name Economy
extends RefCounted
## Aylık ekonomi simülasyonu. Rastgelelik yok: tüm sonuçlar eyalet verilerinden ve
## devlet kararlarından tutarlı formüllerle türetilir.

## Hasat çarpanı (Ocak..Aralık). Ortalama ~1.0
const HARVEST := [0.55, 0.55, 0.75, 0.95, 1.1, 1.3, 1.5, 1.6, 1.45, 1.05, 0.7, 0.55]
const PALACE_COST := [5000.0, 8500.0, 13500.0]
const ARMY_MULT := [0.75, 1.0, 1.35]


static func tax_rate(gs: GameWorld) -> float:
	return float(ProvincesData.TAX_LEVELS[int(gs.w["state"]["tax_level"])]["rate"])


static func official_skill(gs: GameWorld, post: String, skill: String) -> float:
	var holder: String = gs.post_holder(post)
	if holder == "" or gs.ch(holder).is_empty():
		return 30.0
	return gs.skill_of(holder, skill)


static func province_output(p: Dictionary) -> float:
	var base := float(p["uretim"]) * 0.9 + float(p["ticaret"]) * 1.2 + float(p["tarim"]) * 0.6
	return float(p["pop"]) * base * (0.6 + float(p["altyapi"]) / 250.0) * (1.0 - float(p["issizlik"]) / 150.0)


static func collection_eff(gs: GameWorld, p: Dictionary) -> float:
	var hz := official_skill(gs, "hazine", "ekonomi")
	var e := clampf(0.5 + 0.22 * float(p["guvenlik"]) / 100.0 + 0.2 * hz / 100.0, 0.4, 1.0)
	return e * (0.7 + 0.3 * float(p["sadakat"]) / 100.0)


static func province_tax(gs: GameWorld, p: Dictionary) -> float:
	if int(p.get("exempt_until", -1)) > gs.get_day():
		return 0.0
	return province_output(p) * tax_rate(gs) * collection_eff(gs, p)


static func expenses(gs: GameWorld) -> Dictionary:
	var st: Dictionary = gs.w["state"]
	var palace: float = PALACE_COST[int(st["palace_level"])] * (0.85 + float(st["food_price"]) * 0.15)
	var asker := 0.0
	for p in gs.w["provinces"]:
		asker += float(p["asker"])
	var army: float = (3000.0 + asker * 18.0) * ARMY_MULT[int(st["army_level"])]
	var salaries := 2800.0
	var upkeep := 0.0
	for k in gs.w["flags"].keys():
		if String(k).begins_with("upkeep_"):
			upkeep += float(gs.w["flags"][k])
	# sonradan hareme katılanların ve hanedan çocuklarının giderleri
	var harem := 0.0
	for id in gs.npc_ids():
		var c: Dictionary = gs.ch(id)
		if c.get("harem", false):
			harem += HaremData.UPKEEP_PER_WOMAN
		elif String(c.get("role", "")) == "child":
			harem += HaremData.UPKEEP_PER_WOMAN * 0.5
	return {"saray": palace, "ordu": army, "maaslar": salaries, "bakim": upkeep, "harem": harem, "toplam": palace + army + salaries + upkeep + harem}


static func budget(gs: GameWorld) -> Dictionary:
	var income := 0.0
	var by_prov := {}
	for p in gs.w["provinces"]:
		var t := province_tax(gs, p)
		by_prov[p["id"]] = t
		income += t
	var ex := expenses(gs)
	return {"gelir": income, "eyaletler": by_prov, "giderler": ex, "net": income - float(ex["toplam"])}


static func monthly_tick(gs: GameWorld) -> Dictionary:
	var w: Dictionary = gs.w
	var st: Dictionary = w["state"]
	var month: int = gs.get_month()
	var harvest: float = HARVEST[month]
	var provs: Array = w["provinces"]
	var notes: Array = []
	# 1) gıda üretimi ve tüketimi
	for p in provs:
		var drought := int(p.get("drought", 0))
		var dfac := 1.0
		if drought > 0:
			dfac = 0.55 if int(p.get("ambar", 0)) > 0 else 0.35
			p["drought"] = drought - 1
		var prod := (float(p["tarim"]) / 50.0) * harvest * dfac
		p["gida"] = clampf(float(p["gida"]) + (prod - 1.0) * 0.8, 0.0, 12.0)
	# iç ticaret: fazlası olan eyaletlerden açık olanlara tahıl akar
	var tot := 0.0
	var pop := 0.0
	for p in provs:
		tot += float(p["gida"]) * float(p["pop"])
		pop += float(p["pop"])
	var avg := tot / maxf(pop, 1.0)
	for p in provs:
		var k := clampf((float(p["ticaret"]) + float(p["altyapi"])) / 500.0, 0.05, 0.4)
		p["gida"] = clampf(float(p["gida"]) + (avg - float(p["gida"])) * k, 0.0, 12.0)
	var price := clampf(1.0 + (4.0 - avg) * 0.12, 0.7, 2.2)
	st["food_price"] = price
	# 2) gelir
	var income := 0.0
	var by_prov := {}
	for p in provs:
		var t := province_tax(gs, p)
		by_prov[p["id"]] = t
		income += t
	# 3) eyalet göstergeleri
	var rate := tax_rate(gs)
	var sadr := official_skill(gs, "sadrazam", "yonetim")
	var adl := official_skill(gs, "adalet", "adalet")
	var army_level := int(st["army_level"])
	for p in provs:
		var id: String = p["id"]
		var refah_t := 25.0 + float(p["uretim"]) * 0.2 + float(p["ticaret"]) * 0.2 + float(p["tarim"]) * 0.1 + float(p["altyapi"]) * 0.1
		refah_t -= (rate - 0.12) * 180.0 + (price - 1.0) * 35.0 + float(p["issizlik"]) * 0.3
		refah_t += gs.modifier_sum(id, "refah")
		p["refah"] = float(p["refah"]) + (clampf(refah_t, 0.0, 100.0) - float(p["refah"])) * 0.25
		var issiz_t := 25.0 - float(p["uretim"]) * 0.12 - float(p["ticaret"]) * 0.08 + (rate - 0.12) * 60.0 + maxf(0.0, 1.5 - float(p["gida"])) * 4.0
		issiz_t += gs.modifier_sum(id, "issizlik")
		p["issizlik"] = float(p["issizlik"]) + (clampf(issiz_t, 2.0, 60.0) - float(p["issizlik"])) * 0.2
		var hunger := 25.0 if float(p["gida"]) < 1.0 else (10.0 if float(p["gida"]) < 2.0 else 0.0)
		var huzur_t := float(p["refah"]) * 0.5 + float(p["guvenlik"]) * 0.25 + float(p["sadakat"]) * 0.15 + float(st["justice"]) * 0.1
		huzur_t += (sadr - 50.0) * 0.1 - hunger - maxf(0.0, rate - 0.16) * 120.0 + (float(st["prestige"]) - 50.0) * 0.08
		huzur_t += gs.modifier_sum(id, "huzur")
		p["huzur"] = float(p["huzur"]) + (clampf(huzur_t, 0.0, 100.0) - float(p["huzur"])) * 0.3
		var sad_t := 50.0 + (float(p["huzur"]) - 50.0) * 0.4 + (adl - 50.0) * 0.1 + gs.modifier_sum(id, "sadakat")
		p["sadakat"] = float(p["sadakat"]) + (clampf(sad_t, 0.0, 100.0) - float(p["sadakat"])) * 0.15
		var guv_t := float(p["asker"]) * 0.55 + 22.0 + army_level * 8.0 - (15.0 if float(p["huzur"]) < 30.0 else 0.0) + gs.modifier_sum(id, "guvenlik")
		p["guvenlik"] = float(p["guvenlik"]) + (clampf(guv_t, 0.0, 100.0) - float(p["guvenlik"])) * 0.2
		var sag_t := 40.0 + float(p["altyapi"]) * 0.2 + float(p["refah"]) * 0.2 + gs.modifier_sum(id, "saglik")
		p["saglik"] = float(p["saglik"]) + (clampf(sag_t, 0.0, 100.0) - float(p["saglik"])) * 0.1
		var growth := (float(p["refah"]) - 40.0) * 0.00008 + (float(p["saglik"]) - 50.0) * 0.00005 - (0.004 if float(p["gida"]) < 1.0 else 0.0)
		p["pop"] = float(p["pop"]) * (1.0 + growth)
		if float(p["gida"]) < 1.0:
			notes.append("%s'da tahıl tükeniyor; halk aç." % p["name"])
		if float(p["huzur"]) < 25.0:
			notes.append("%s'da huzursuzluk tehlikeli boyutta." % p["name"])
	# 4) kamu yatırımları
	var keep: Array = []
	for proj in w["projects"]:
		if int(proj["done_month"]) <= gs.cal_month_index():
			var p2: Dictionary = gs.province(proj["prov"])
			var def: Dictionary = ProvincesData.PROJECTS[proj["type"]]
			for stat in def["effects"].keys():
				if stat == "ambar":
					p2["ambar"] = 1
				elif stat == "gida":
					p2["gida"] = clampf(float(p2["gida"]) + float(def["effects"][stat]), 0.0, 12.0)
				else:
					var cap := 60.0 if stat == "issizlik" else 100.0
					p2[stat] = clampf(float(p2[stat]) + float(def["effects"][stat]), 0.0, cap)
			notes.append("%s: %s tamamlandı." % [p2["name"], def["name"]])
			gs.add_log("%s eyaletinde %s tamamlandı." % [p2["name"], def["name"]], "devlet", 2)
		else:
			keep.append(proj)
	w["projects"] = keep
	# 5) hazine
	var ex := expenses(gs)
	var net := income - float(ex["toplam"])
	st["treasury"] = float(st["treasury"]) + net
	if float(st["treasury"]) < 0.0:
		# borç: sarraflara faiz, ödenmeyen maaşlar, itibar kaybı
		var faiz := -float(st["treasury"]) * 0.03
		st["treasury"] = float(st["treasury"]) - faiz
		st["prestige"] = clampf(float(st["prestige"]) - 3.0, 0.0, 100.0)
		st["legitimacy"] = clampf(float(st["legitimacy"]) - 2.0, 0.0, 100.0)
		gs.add_modifier("*", "huzur", -4.0, 35, "borc")
		for pair in [["hazine", 4.0], ["ordu", 6.0], ["sadrazam", 3.0]]:
			var h: String = gs.post_holder(pair[0])
			if h != "":
				gs.rel_add(h, "sultan", {"saygi": -float(pair[1]), "siyasi_uyum": -float(pair[1])})
		notes.append("Hazine borçta! Sarraflara %s faiz ödendi; maaşlar gecikiyor." % gs.fmt_money(faiz))
		gs.add_log("Hazine borçta. Maaşlar gecikiyor, sarraflar faiz istiyor.", "uyari", 2)
	var hist: Array = st["history"]
	hist.append({"m": gs.cal_month_index(), "label": "%s %d" % [GameState.MONTHS[month].substr(0, 3), gs.get_year()], "gelir": income, "gider": float(ex["toplam"]), "hazine": float(st["treasury"]), "huzur": gs.people_huzur(), "fiyat": price})
	while hist.size() > 24:
		hist.remove_at(0)
	# prestij: sarayın görkemi ve hazine sağlığı
	var target_pres := 45.0 + int(st["palace_level"]) * 8.0 + (6.0 if float(st["treasury"]) > 80000.0 else -6.0)
	st["prestige"] = clampf(float(st["prestige"]) + (target_pres - float(st["prestige"])) * 0.1, 0.0, 100.0)
	var report := {"gelir": income, "eyaletler": by_prov, "giderler": ex, "net": net, "fiyat": price, "notlar": notes}
	st["last_report"] = report
	gs.add_log("Aylık hesap: gelir %s, gider %s, net %s." % [gs.fmt_money(income), gs.fmt_money(float(ex["toplam"])), gs.fmt_money(net)], "devlet", 2 if net < 0 else 1)
	return report


static func start_project(gs: GameWorld, prov_id: String, type: String) -> bool:
	var def: Dictionary = ProvincesData.PROJECTS[type]
	var p: Dictionary = gs.province(prov_id)
	if p.is_empty():
		return false
	if def.get("coastal", false) and not p.get("coastal", false):
		gs.notify.emit("Liman ancak kıyı eyaletlerinde yapılabilir.", "uyari")
		return false
	for proj in gs.w["projects"]:
		if proj["prov"] == prov_id and proj["type"] == type:
			gs.notify.emit("Bu yatırım zaten sürüyor.", "uyari")
			return false
	if not gs.spend(float(def["cost"]), def["name"]):
		return false
	gs.w["projects"].append({"prov": prov_id, "type": type, "start_month": gs.cal_month_index(), "done_month": gs.cal_month_index() + int(def["months"])})
	gs.add_log("%s eyaletinde %s yapımı başladı (%d ay)." % [p["name"], def["name"], int(def["months"])], "devlet", 1)
	gs.add_modifier(prov_id, "huzur", 3.0, int(def["months"]) * 30, "yatirim")
	return true
