class_name JusticeEngine
extends RefCounted
## Yargı: suç kayıtları (delil), Kadıasker'den fetva, cezalar (müsadere, sürgün, zindan, idam) ve sonuçları.
## Ağır cezalar ancak kadının fetvasıyla uygulanır. Kadı reddederse hükümdar baskı yapabilir; bunun bedeli ağırdır.

const P := "sultan"

const CRIMES := {
	"ihanet": {"name": "Devlete ihanet", "max": 4},
	"suikast": {"name": "Hükümdara suikast girişimi", "max": 4},
	"casusluk": {"name": "Yabancı bir devlet adına casusluk", "max": 4},
	"iftira": {"name": "Sahte delille ölüm fermanı çıkartmak", "max": 4},
	"zimmet": {"name": "Hazineyi zimmetine geçirmek", "max": 3},
	"rusvet": {"name": "Rüşvet almak", "max": 2},
	"hirsizlik": {"name": "Hırsızlık", "max": 3},
	"nizam": {"name": "Saray nizamını bozmak", "max": 2},
}

## [anahtar, ad, gereken en az delil, ağırlık]
const PUNISH := [
	["musadere", "Mal müsaderesi", 40.0, 1],
	["surgun", "Sürgün", 45.0, 2],
	["zindan", "Zindan", 55.0, 3],
	["idam", "İdam", 75.0, 4],
]

## Başlangıçta gizli olan suçlar: [suç, Rıza'nın soruşturmasıyla bulunabilecek delil]
const SECRETS := {"halil": ["iftira", 30.0], "yusuf": ["zimmet", 40.0], "feraye": ["casusluk", 15.0], "sumbul": ["hirsizlik", 35.0]}


static func default_data() -> Dictionary:
	return {"cases": {}, "prison": [], "exile": [], "found": {}, "pending_truth": []}


static func data(gs: GameWorld) -> Dictionary:
	if not gs.w.has("crimes"):
		gs.w["crimes"] = default_data()
	var d: Dictionary = gs.w["crimes"]
	for k in default_data().keys():
		if not d.has(k):
			d[k] = default_data()[k]
	return d


static func add_evidence(gs: GameWorld, who: String, type: String, amount: float, note: String = "", truth: bool = true) -> void:
	if gs.ch(who).is_empty() or not CRIMES.has(type):
		return
	var cases: Dictionary = data(gs)["cases"]
	if not cases.has(who):
		cases[who] = {}
	if not cases[who].has(type):
		cases[who][type] = {"ev": 0.0, "true": truth, "notes": []}
	var cs: Dictionary = cases[who][type]
	cs["ev"] = clampf(float(cs["ev"]) + amount, 0.0, 100.0)
	if truth:
		cs["true"] = true
	if note != "":
		cs["notes"].append(note)
		gs.add_log("Delil kaydı (%s): %s" % [gs.short_name(who), note], "adalet", 1)


static func clear_case(gs: GameWorld, who: String, type: String) -> void:
	var cases: Dictionary = data(gs)["cases"]
	if cases.has(who):
		cases[who].erase(type)
		if cases[who].is_empty():
			cases.erase(who)


static func evidence(gs: GameWorld, who: String, type: String) -> float:
	var cases: Dictionary = data(gs)["cases"]
	return float(cases.get(who, {}).get(type, {}).get("ev", 0.0))


static func ev_label(v: float) -> String:
	if v >= 75.0:
		return "kesin"
	if v >= 55.0:
		return "güçlü"
	if v >= 30.0:
		return "orta"
	if v > 0.0:
		return "zayıf"
	return "yok"


## Rıza Efendi'nin soruşturması gizli suçlara ışık tutar
static func investigate_secret(gs: GameWorld, who: String) -> String:
	if not SECRETS.has(who):
		return ""
	var found: Dictionary = data(gs)["found"]
	if found.has(who):
		return ""
	found[who] = true
	var s: Array = SECRETS[who]
	add_evidence(gs, who, String(s[0]), float(s[1]), "Rıza Efendi'nin soruşturması: %s şüphesi." % String(CRIMES[s[0]]["name"]).to_lower())
	return "Ayrıca bir şey daha var, Sultanım: %s hakkında %s şüphesi taşıyan kayıtlar buldum. Kadıasker'e iletilmek üzere deftere geçirdim." % [gs.short_name(who), String(CRIMES[s[0]]["name"]).to_lower()]


# ------------------------------------------------------------ yargıç

static func judge(gs: GameWorld, accused: String = "") -> String:
	var k := gs.post_holder("adalet")
	if k != "" and k != accused and EventEngine.is_present(gs, k):
		return k
	if accused != "sadik" and EventEngine.is_present(gs, "sadik"):
		return "sadik"
	return ""


static func can_be_accused(gs: GameWorld, id: String, judge_id: String) -> bool:
	if id == P or id == judge_id or id == "mahinur":
		return false
	var c: Dictionary = gs.ch(id)
	if c.is_empty() or c.get("royal", false) or int(c.get("age", 30)) < 16:
		return false
	return EventEngine.is_present(gs, id)


static func punish_name(gs: GameWorld, accused: String, key: String) -> String:
	if key == "surgun" and HaremEngine.is_harem_woman(gs, accused):
		return "Eski Saray'a gönderme"
	for p in PUNISH:
		if p[0] == key:
			return p[1]
	return key


static func _pun(key: String) -> Array:
	for p in PUNISH:
		if p[0] == key:
			return p
	return []


## Kadının hükmü: fetva verir mi?
static func verdict(gs: GameWorld, judge_id: String, accused: String, type: String, pun: String) -> Dictionary:
	var ev := evidence(gs, accused, type)
	var p := _pun(pun)
	var crime: Dictionary = CRIMES.get(type, {"name": "?", "max": 0})
	var eff := ev
	var bias := (gs.rel_val(judge_id, accused, "sevgi") + gs.rel_val(judge_id, accused, "arkadaslik")) * 0.5 - 50.0
	if bias > 10.0:
		eff -= bias * 0.3
	var honest := gs.trait_of(judge_id, "durustluk")
	var jn := gs.short_name(judge_id)
	if int(p[3]) > int(crime["max"]):
		return {"ok": false, "text": "(%s başını iki yana sallar.) %s suçuna %s cezası verilmez, Sultanım. Şeriat da kanun da buna izin vermez; böyle bir fetvayı mürekkebim yazmaz." % [jn, String(crime["name"]).to_lower(), punish_name(gs, accused, pun).to_lower()]}
	if eff < float(p[2]):
		var why := "elimizde delil yok"
		if ev > 0.0:
			why = "deliller %s; bu kadar ağır bir hükme yetmez" % ev_label(ev)
		if bias > 10.0 and ev >= float(p[2]):
			why = "deliller üzerinde iyice düşünmem gerek; acele bir hüküm vermem"
		return {"ok": false, "text": "(%s) Sultanım, %s. %s" % [jn, why, "Daha hafif bir ceza düşünün ya da soruşturmayı derinleştirin." if ev > 0.0 else "Delil olmadan kimseyi cezalandıramam."]}
	var fetva := "Deliller %s, Sultanım. %s %s cezasına çarptırılmasına fetva veriyorum." % [ev_label(ev), gs.short_name(accused), punish_name(gs, accused, pun).to_lower()]
	if pun == "idam":
		fetva = "(%s uzun bir sessizlikten sonra kalemi alır.) Deliller %s. Hükmün ağırlığını biliyorum, Sultanım... Fetva hazırdır. Allah hepimizi affetsin." % [jn, ev_label(ev)]
	if honest < 40.0 and eff >= float(p[2]):
		fetva += " (Kadının gözleri bir an hazine kesesine kayar gibi oldu.)"
	return {"ok": true, "text": fetva}


static func press_chance(gs: GameWorld, judge_id: String) -> float:
	var ch := 0.12 + gs.rel_val(judge_id, P, "korku") * 0.006 + (100.0 - gs.trait_of(judge_id, "durustluk")) * 0.004 + gs.rel_val(judge_id, P, "borcluluk") * 0.003
	if gs.trait_of(judge_id, "durustluk") >= 80.0:
		ch *= 0.4
	return clampf(ch, 0.03, 0.85)


static func press(gs: GameWorld, judge_id: String, accused: String) -> Dictionary:
	var jn := gs.short_name(judge_id)
	if gs.rng.randf() < press_chance(gs, judge_id):
		gs.rel_add(judge_id, P, {"saygi": -12.0, "sevgi": -10.0, "korku": 12.0})
		gs.add_memory(judge_id, "baski", [P, accused], -45.0, "Hükümdar beni vicdanıma aykırı bir fetvaya zorladı.", "dogrudan", true, {"key": "baski:" + accused})
		for wid in gs.witnesses(gs.ch(judge_id).get("location", ""), [judge_id]):
			gs.add_memory(wid, "baski_gozlem", [P, judge_id], -15.0, "Hükümdar kadıyı fetva için sıkıştırdı.", "gozlem", true, {"key": "baski:" + accused})
		return {"ok": true, "text": "(%s titreyen elleriyle mührünü basar.) Emriniz başım üstüne, Sultanım. Ama bu fetvanın vebali benim değil." % jn}
	gs.rel_add(judge_id, P, {"saygi": -4.0, "sevgi": -6.0, "korku": 6.0})
	gs.add_memory(judge_id, "baski", [P, accused], -30.0, "Hükümdar beni haksız bir fetvaya zorlamaya çalıştı.", "dogrudan", true, {"key": "baski_red:" + accused})
	if gs.trait_of(judge_id, "durustluk") >= 80.0:
		return {"ok": false, "text": "(%s ayağa kalkar.) Başımı isteyin, veririm Sultanım; ama vicdanımı veremem. Bu fetva benim elimden çıkmaz." % jn}
	return {"ok": false, "text": "(%s gözlerini kaçırır.) Bağışlayın, Sultanım... Bu delillerle mühür basamam." % jn}


# ------------------------------------------------------------ cezaların uygulanması

static func execute(gs: GameWorld, accused: String, type: String, pun: String, pressured: bool) -> String:
	var c: Dictionary = gs.ch(accused)
	if c.is_empty():
		return ""
	var name: String = c.get("full", accused)
	var sname: String = gs.short_name(accused)
	var cases: Dictionary = data(gs)["cases"]
	var truth: bool = bool(cases.get(accused, {}).get(type, {}).get("true", true))
	var harem := HaremEngine.is_harem_woman(gs, accused)
	# saraydakilerin tepkisi
	for id in gs.npc_ids():
		if id == accused:
			continue
		var close := maxf(gs.rel_val(id, accused, "sevgi"), gs.rel_val(id, accused, "arkadaslik"))
		var enemy := maxf(gs.rel_val(id, accused, "rekabet"), gs.rel_val(id, accused, "kiskanclik"))
		var sev := 6.0 if pun == "idam" else (3.0 if pun in ["zindan", "surgun"] else 1.5)
		gs.rel_add(id, P, {"korku": sev}, false)
		if close >= 60.0:
			gs.rel_add(id, P, {"sevgi": -sev * 2.5, "guven": -sev}, false)
			gs.add_memory(id, "ceza_yakin", [P, accused], -sev * 6.0, "Hükümdar %s cezalandırdı." % TR.acc(sname), "soylenti", true, {"key": "ceza:" + accused})
		elif enemy >= 55.0:
			gs.rel_add(id, P, {"sevgi": 3.0, "siyasi_uyum": 3.0}, false)
	var just := not pressured and truth
	var text := ""
	match pun:
		"idam":
			gs.kill_character(accused, "", "adalet")
			text = "%s, Kadıasker'in fetvasıyla idam edildi. Saray o gün sessizliğe gömüldü." % name
			gs.state_add("justice", 3.0 if just else -12.0)
			if not just:
				gs.state_add("legitimacy", -5.0)
			gs.state_add("prestige", 1.0)
		"zindan":
			c["prison"] = true
			data(gs)["prison"].append(accused)
			EventEngine.char_gone(gs, accused, "")
			text = "%s zindana atıldı." % name
			gs.state_add("justice", 2.0 if just else -8.0)
		"surgun":
			c["exile"] = true
			data(gs)["exile"].append(accused)
			EventEngine.char_gone(gs, accused, "")
			text = ("%s Eski Saray'a gönderildi." if harem else "%s sürgüne gönderildi.") % name
			gs.state_add("justice", 1.5 if just else -6.0)
			if gs.is_married_to_player(accused):
				gs.player()["married_to"].erase(accused)
		"musadere":
			var amount := float(c.get("status", 40)) * 90.0
			gs.earn(amount)
			c["status"] = maxi(10, int(c.get("status", 40)) - 20)
			gs.rel_add(accused, P, {"sevgi": -30.0, "korku": 20.0, "siyasi_uyum": -20.0})
			gs.add_memory(accused, "musadere", [P], -60.0, "Hükümdar malıma el koydu.", "dogrudan", true, {"key": "musadere:" + accused})
			text = "%s mallarına el konuldu; hazineye %s girdi." % [name, gs.fmt_money(amount)]
			gs.state_add("justice", 1.0 if just else -6.0)
	if pressured:
		gs.add_log("Saray, fetvanın baskıyla alındığını konuşuyor. Adalete olan güven sarsıldı.", "adalet", 2)
	clear_case(gs, accused, type)
	if not truth:
		data(gs)["pending_truth"].append({"who": accused, "name": name, "day": gs.get_day() + 12})
	gs.add_log(text, "adalet", 2)
	if harem:
		for oid in HaremEngine.women(gs):
			gs.rel_add(oid, P, {"korku": 6.0}, false)
		gs.rel_add("mahinur", P, {"saygi": 2.0 if just else -6.0})
	return text


static func release(gs: GameWorld, who: String) -> String:
	var d := data(gs)
	var c: Dictionary = gs.ch(who)
	if c.is_empty():
		return ""
	d["prison"].erase(who)
	d["exile"].erase(who)
	c.erase("prison")
	c.erase("exile")
	c["gone"] = false
	gs.rel_add(who, P, {"sevgi": 12.0, "borcluluk": 30.0, "korku": 10.0})
	gs.add_memory(who, "affedilme", [P], 40.0, "Hükümdar beni affedip saraya geri çağırdı.", "dogrudan", true, {"key": "af:" + who})
	gs.state_add("justice", 1.0)
	gs.add_log("%s affedildi ve saraya döndü." % String(c["full"]), "adalet", 2)
	gs.update_all_schedules()
	return "%s serbest bırakıldı." % String(c["full"])


# ------------------------------------------------------------ günlük

static func daily(gs: GameWorld) -> void:
	var d := data(gs)
	var keep: Array = []
	for t in d["pending_truth"]:
		if gs.get_day() >= int(t["day"]):
			gs.state_add("justice", -10.0)
			gs.state_add("legitimacy", -3.0)
			gs.add_log("Acı bir gerçek ortaya çıktı: %s aslında suçsuzdu. Halk bu hükmü unutmayacak." % String(t["name"]), "adalet", 2)
		else:
			keep.append(t)
	d["pending_truth"] = keep
	if gs.get_day() < 3 or EventEngine.pending(gs).size() >= EventEngine.MAX_PENDING:
		return
	if gs.rng.randf() > 0.06:
		return
	var kinds := ["rusvet_ihbar", "zehir_supheli", "harem_hirsizlik"]
	var kind: String = kinds[gs.rng.randi() % kinds.size()]
	var fired: Dictionary = gs.w["events"]["fired"]
	if fired.has(kind) and gs.get_day() - int(fired[kind]) < 25:
		return
	var who := _suspect(gs, kind)
	if who == "":
		return
	var guilty := false
	match kind:
		"rusvet_ihbar":
			guilty = gs.rng.randf() < 0.35 + (100.0 - gs.trait_of(who, "durustluk")) / 150.0
		"zehir_supheli":
			guilty = gs.opinion(who, P) < 28.0 and gs.rng.randf() < 0.7
		"harem_hirsizlik":
			guilty = gs.trait_of(who, "durustluk") < 50.0 and gs.rng.randf() < 0.75
	EventEngine.add_event(gs, kind, {"who": who, "guilty": guilty})


static func _suspect(gs: GameWorld, kind: String) -> String:
	var cands: Array = []
	for id in gs.npc_ids():
		var c: Dictionary = gs.ch(id)
		if c.get("royal", false) or int(c.get("age", 30)) < 16 or id in ["mahinur", "cafer", "arslan", "lokman", "bekir"]:
			continue
		if c.get("location", "") == "disari" and kind != "rusvet_ihbar":
			continue
		match kind:
			"rusvet_ihbar":
				if String(c["role"]) in ["guard", "clerk", "scribe", "servant", "official", "artist"] and gs.post_of(id) != "sadrazam":
					cands.append(id)
			"zehir_supheli":
				if String(c["role"]) != "envoy":
					cands.append([id, gs.opinion(id, P)])
			"harem_hirsizlik":
				if String(c["role"]) in ["harem", "harem_staff", "servant"] and not gs.is_married_to_player(id):
					cands.append(id)
	if cands.is_empty():
		return ""
	if kind == "zehir_supheli":
		cands.sort_custom(func(a, b): return float(a[1]) < float(b[1]))
		return String(cands[gs.rng.randi() % mini(3, cands.size())][0])
	return String(cands[gs.rng.randi() % cands.size()])


# ------------------------------------------------------------ diyalog (kadı ile)

static func _r(text: String, sub: Array = [], title: String = "") -> Dictionary:
	return {"text": text, "deltas": {}, "sub": sub, "end": false, "sub_title": title}


static func dialogue(gs: GameWorld, judge_id: String, arg: String) -> Dictionary:
	var parts := arg.split("|")
	var step: String = parts[0] if parts.size() > 0 else ""
	match step:
		"":
			var sub: Array = [{"id": "yargi", "arg": "ac", "label": "Bir dava aç"}]
			var pr: Array = data(gs)["prison"] + data(gs)["exile"]
			if not pr.is_empty():
				sub.append({"id": "yargi", "arg": "af", "label": "Zindandakiler ve sürgündekiler (%d)" % pr.size()})
			var known := _known_cases(gs, judge_id)
			var txt := "Divan-ı hümayunun adaleti emrinizde, Sultanım. Hangi meseleyi göreceğiz?"
			if not known.is_empty():
				txt += "\n\nDefterdeki açık dosyalar:"
				for k in known:
					txt += "\n• %s — %s (delil: %s)" % [gs.short_name(k[0]), String(CRIMES[k[1]]["name"]).to_lower(), ev_label(float(k[2]))]
			return _r(txt, sub, "Yargı")
		"ac":
			var sub2: Array = []
			var with_case: Array = []
			var others: Array = []
			for id in gs.npc_ids():
				if not can_be_accused(gs, id, judge_id):
					continue
				if data(gs)["cases"].has(id):
					with_case.append(id)
				else:
					others.append(id)
			for id2 in with_case:
				sub2.append({"id": "yargi", "arg": "kim|" + id2, "label": "%s (dosyası var)" % gs.short_name(id2)})
			for id3 in others:
				sub2.append({"id": "yargi", "arg": "kim|" + id3, "label": gs.short_name(id3)})
			return _r("Kimin davasını göreceğiz?", sub2, "Sanık")
		"kim":
			var who: String = parts[1]
			var sub3: Array = []
			var cases: Dictionary = data(gs)["cases"].get(who, {})
			for t in cases.keys():
				sub3.append({"id": "yargi", "arg": "suc|%s|%s" % [who, t], "label": "%s (delil: %s)" % [CRIMES[t]["name"], ev_label(float(cases[t]["ev"]))]})
			for t2 in CRIMES.keys():
				if not cases.has(t2):
					sub3.append({"id": "yargi", "arg": "suc|%s|%s" % [who, t2], "label": "%s (delilsiz)" % CRIMES[t2]["name"]})
			return _r("%s hangi suçla itham ediliyor?" % gs.short_name(who), sub3, "Suçlama")
		"suc":
			var who2: String = parts[1]
			var t3: String = parts[2]
			var sub4: Array = []
			for p in PUNISH:
				sub4.append({"id": "yargi", "arg": "ceza|%s|%s|%s" % [who2, t3, p[0]], "label": "%s iste" % punish_name(gs, who2, String(p[0]))})
			var ev := evidence(gs, who2, t3)
			var notes: Array = data(gs)["cases"].get(who2, {}).get(t3, {}).get("notes", [])
			var txt2 := "Dosyada %s hakkında %s suçlamasına dair %s delil var, Sultanım." % [gs.short_name(who2), String(CRIMES[t3]["name"]).to_lower(), ev_label(ev)]
			for n in notes:
				txt2 += "\n• " + String(n)
			return _r(txt2 + "\n\nNe hüküm istiyorsunuz?", sub4, "Ceza")
		"ceza":
			var who3: String = parts[1]
			var t4: String = parts[2]
			var pun: String = parts[3]
			gs.advance_minutes(20)
			var v := verdict(gs, judge_id, who3, t4, pun)
			if v["ok"]:
				return _r(v["text"], [
					{"id": "yargi", "arg": "infaz|%s|%s|%s|0" % [who3, t4, pun], "label": "Hüküm infaz edilsin"},
					{"id": "yargi", "arg": "vazgec|%s" % who3, "label": "Merhamet edeceğim; vazgeçtim"}], "Fetva")
			var sub5: Array = [{"id": "yargi", "arg": "suc|%s|%s" % [who3, t4], "label": "Daha hafif bir ceza iste"}]
			sub5.append({"id": "yargi", "arg": "baski|%s|%s|%s" % [who3, t4, pun], "label": "Kadıya baskı yap (tehlikeli)"})
			sub5.append({"id": "yargi", "arg": "vazgec|%s" % who3, "label": "Vazgeç"})
			return _r(v["text"], sub5, "Kadı reddetti")
		"baski":
			var res := press(gs, judge_id, parts[1])
			if res["ok"]:
				return _r(res["text"], [{"id": "yargi", "arg": "infaz|%s|%s|%s|1" % [parts[1], parts[2], parts[3]], "label": "Hüküm infaz edilsin"},
					{"id": "yargi", "arg": "vazgec|%s" % parts[1], "label": "Son anda vazgeç"}], "Baskıyla alınan fetva")
			return _r(res["text"])
		"infaz":
			var txt3 := execute(gs, parts[1], parts[2], parts[3], parts[4] == "1")
			return _r(txt3)
		"vazgec":
			var w: String = parts[1]
			if EventEngine.is_present(gs, w):
				gs.rel_add(w, P, {"borcluluk": 6.0})
			return _r("Merhamet de adaletin bir parçasıdır, Sultanım.")
		"af":
			var sub6: Array = []
			for id4 in data(gs)["prison"] + data(gs)["exile"]:
				var c4: Dictionary = gs.ch(id4)
				if c4.is_empty() or not c4.get("alive", true):
					continue
				sub6.append({"id": "yargi", "arg": "birak|" + String(id4), "label": "%s affedilsin (%s)" % [String(c4["full"]), "zindanda" if c4.get("prison", false) else "sürgünde"]})
			return _r("Zindanda ve sürgünde olanlar bunlar, Sultanım.", sub6, "Af")
		"birak":
			return _r(release(gs, parts[1]))
	return _r("...")


static func _known_cases(gs: GameWorld, judge_id: String) -> Array:
	var out: Array = []
	var cases: Dictionary = data(gs)["cases"]
	for who in cases.keys():
		if not EventEngine.is_present(gs, who) or who == judge_id:
			continue
		for t in cases[who].keys():
			out.append([who, t, float(cases[who][t]["ev"])])
	return out
