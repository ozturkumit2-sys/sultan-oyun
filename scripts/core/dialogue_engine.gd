class_name DialogueEngine
extends RefCounted
## Dallanan, koşullu ve veri odaklı diyalog sistemi. İnternet veya harici yapay zekâ gerektirmez.
## Her konuşma seçeneğinin etkisi; karakterin kişiliğine, ruh hâline, ilişkiye ve geçmişe göre değişir.

const P := "sultan"
const GOSSIPS := ["riza", "bekir", "sumbul", "gulbahar", "dogan", "nergis"]
const STATE_ROLES := ["official", "scribe", "envoy", "valide"]


static func hitap(gs: GameWorld, id: String) -> String:
	if gs.is_married_to_player(id):
		return "Sultanım"
	return DialogueData.HITAP.get(gs.ch(id).get("role", ""), "Sultanım")


static func _today(gs: GameWorld, id: String, topic: String) -> int:
	var t: Dictionary = gs.w["dialogue"]["today"]
	return int(t.get(id, {}).get(topic, 0))


static func _bump(gs: GameWorld, id: String, topic: String) -> void:
	var t: Dictionary = gs.w["dialogue"]["today"]
	if not t.has(id):
		t[id] = {}
	t[id][topic] = int(t[id].get(topic, 0)) + 1


# ------------------------------------------------------------ satır seçimi

static func _specificity(c: Dictionary) -> float:
	var s := 0.0
	for k in c.keys():
		if k == "id":
			s += 4.0
		elif k == "role":
			s += 2.0
		else:
			s += 1.0
	return s


static func _match(gs: GameWorld, id: String, c: Dictionary, extra: Dictionary) -> bool:
	var ch: Dictionary = gs.ch(id)
	var op: float = gs.opinion(id, P)
	for k in c.keys():
		var v = c[k]
		match String(k):
			"id":
				if not id in v:
					return false
			"notid":
				if id in v:
					return false
			"role":
				if not ch["role"] in v:
					return false
			"op_min":
				if op < float(v):
					return false
			"op_max":
				if op > float(v):
					return false
			"mood_min":
				if float(ch["mood"]) < float(v):
					return false
			"mood_max":
				if float(ch["mood"]) > float(v):
					return false
			"rom_min":
				if gs.rel_val(id, P, "romantik") < float(v):
					return false
			"rom_max":
				if gs.rel_val(id, P, "romantik") > float(v):
					return false
			"tr":
				for t in v.keys():
					var tv: float = gs.trait_of(id, String(t))
					if tv < float(v[t][0]) or tv > float(v[t][1]):
						return false
			"part":
				if not gs.day_part() in v:
					return false
			"married":
				if gs.is_married_to_player(id) != bool(v):
					return false
			"price_gt":
				if float(gs.w["state"]["food_price"]) <= float(v):
					return false
			"net_lt":
				if float(Economy.budget(gs)["net"]) >= float(v):
					return false
			"treasury_gt":
				if gs.treasury() <= float(v):
					return false
			"special":
				if extra.get("special", "") != v:
					return false
	return true


static func pick_line(gs: GameWorld, id: String, pool: String, extra: Dictionary = {}) -> String:
	var lines: Array = DialogueData.LINES.get(pool, [])
	var recent: Array = gs.w["dialogue"]["recent"].get(id, [])
	var cands: Array = []
	for i in range(lines.size()):
		var l: Dictionary = lines[i]
		if not _match(gs, id, l["c"], extra):
			continue
		var key := "%s:%d" % [pool, i]
		var sc := _specificity(l["c"])
		if key in recent:
			sc -= 3.0
		cands.append([sc, key, l["t"]])
	if cands.is_empty():
		return ""
	cands.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	var top := float(cands[0][0])
	var band: Array = []
	for cnd in cands:
		if float(cnd[0]) >= top - 0.5:
			band.append(cnd)
	var chosen: Array = band[gs.rng.randi() % band.size()]
	recent.append(chosen[1])
	while recent.size() > 10:
		recent.pop_front()
	gs.w["dialogue"]["recent"][id] = recent
	return fill(gs, id, String(chosen[2]), extra)


static func fill(gs: GameWorld, id: String, t: String, extra: Dictionary = {}) -> String:
	var s := t
	var h := hitap(gs, id)
	if s.begins_with("{hitap}"):
		s = h.substr(0, 1).to_upper() + h.substr(1) + s.substr(7)
	s = s.replace("{hitap}", h)
	s = s.replace("{sultan}", String(gs.player()["name"]))
	if s.contains("{treasury}"):
		s = s.replace("{treasury}", gs.fmt_money(gs.treasury()))
	for k in extra.keys():
		s = s.replace("{%s}" % k, str(extra[k]))
	return s


# ------------------------------------------------------------ açılış ve konular

static func greeting(gs: GameWorld, id: String) -> String:
	var mem: Dictionary = gs.strongest_memory_about(id, P, 10)
	if not mem.is_empty() and absf(float(mem["emotion"])) * float(mem["strength"]) >= 18.0 and gs.rng.randf() < 0.6:
		var h := hitap(gs, id)
		var e := float(mem["emotion"])
		var mt: String = mem["type"]
		if e > 0:
			match mt:
				"hediye":
					return "Hediyeniz için yeniden teşekkür ederim, %s. Hâlâ gözümün önünde." % h
				"affedilme":
					return "Bağışlayıcılığınızı ömrüm boyunca unutmayacağım, %s." % h
				"terfi":
					return "%s! Bana gösterdiğiniz güvene layık olmak için gece gündüz çalışıyorum." % h.capitalize()
				"jest":
					return "(Gülümser.) Sizi düşünüyordum, %s." % h
				"adalet":
					return "(Gözleri dolar.) %s... Babam için yaptıklarınızı nasıl ödeyeceğim?" % h.capitalize()
				_:
					return "Sizi görmek iyi geldi, %s. Son konuşmamızı düşünüp duruyordum." % h
		else:
			match mt:
				"haksizlik":
					return "(Soğuk bir sesle) Buyurun, %s." % h
				"hakaret":
					return "(Size bakmadan eğilir.) %s." % h.capitalize()
				"ret", "divan_karsi":
					return "Buyurun, %s. Yine mi sözümü dinlemeyeceksiniz?" % h
				"kiskanclik":
					if id in ["leyla", "feraye"]:
						return "(İğneleyici) Leyla'yla mı, Feraye'yle mi... kiminle vakit geçirdiniz bugün, %s?" % h
					return "(İğneleyici) Bugün haremde kimin kapısını çaldınız, %s?" % h if gs.ch(id)["romanceable"] else "Buyurun, %s." % h
				"kirginlik":
					return "(Gözlerini kaçırır.) Beni beklettiğiniz akşamı unutmadım, %s." % h
				"ihmal":
					return "Demek sonunda vakit bulabildiniz, %s." % h
				_:
					return "(Gergin) Buyurun, %s." % h
	return pick_line(gs, id, "greet")


static func topics(gs: GameWorld, id: String) -> Array:
	var c: Dictionary = gs.ch(id)
	var role: String = c["role"]
	var out: Array = []
	for ev in EventEngine.pending_for(gs, id):
		out.append({"id": "ev:" + String(ev["uid"]), "label": "» " + String(ev["title"]), "kind": "event"})
	if role == "child":
		# çocuklarla yalnız yaşa uygun, sıcak konuşmalar
		out.append({"id": "hal", "label": "Hal hatır sor"})
		out.append({"id": "aile", "label": "Annesini sor"})
		out.append({"id": "iltifat", "label": "Aferin de"})
		out.append({"id": "hediye", "label": "Hediye ver"})
		return out
	if id == HaremEngine.CHAMBERLAIN or (id == "gulbahar" and not EventEngine.is_present(gs, HaremEngine.CHAMBERLAIN)):
		out.append({"id": "harem", "label": "Harem işleri", "kind": "special"})
		out.append({"id": "hanedan", "label": "Hanedan ve şehzadeler", "kind": "special"})
	if id == JusticeEngine.judge(gs):
		out.append({"id": "yargi", "label": "Davalar ve cezalar (fetva)", "kind": "special"})
	if HaremEngine.is_harem_woman(gs, id) and (c.get("harem", false) or gs.is_married_to_player(id)):
		out.append({"id": "gece", "label": "Bu gece dairene davet et"})
	out.append({"id": "hal", "label": "Hal hatır sor"})
	out.append({"id": "kisisel", "label": "Kişisel konular"})
	out.append({"id": "aile", "label": "Ailesini sor"})
	if role in STATE_ROLES or id == "feraye" or gs.post_of(id) != "":
		out.append({"id": "devlet", "label": "Devlet meseleleri"})
	out.append({"id": "tavsiye", "label": "Tavsiye iste"})
	if c.get("romanceable", false):
		out.append({"id": "gonul", "label": "Gönlünü kazanmaya çalış"})
	out.append({"id": "iltifat", "label": "Övgüyle karşıla"})
	out.append({"id": "hediye", "label": "Hediye ver"})
	if not _tasks(gs, id).is_empty():
		out.append({"id": "gorev", "label": "Görev ver"})
	if not _threads(gs, id).is_empty():
		out.append({"id": "ozel", "label": "Özel mesele", "kind": "special"})
	if not _rivals(gs, id).is_empty():
		out.append({"id": "anlasmazlik", "label": "Anlaşmazlığı çöz"})
	if id in GOSSIPS:
		out.append({"id": "dedikodu", "label": "Kulis haberleri"})
	if c.get("romanceable", false) and not gs.is_married_to_player(id) and gs.rel_val(id, P, "romantik") >= 55.0:
		out.append({"id": "evlilik", "label": "Evlilik teklif et", "kind": "special"})
	out.append({"id": "azarla", "label": "Azarla"})
	return out


static func _res(text: String, deltas: Dictionary = {}, sub: Array = [], end: bool = false, sub_title: String = "") -> Dictionary:
	return {"text": text, "deltas": deltas, "sub": sub, "end": end, "sub_title": sub_title}


static func _apply(gs: GameWorld, id: String, d: Dictionary) -> Dictionary:
	var clean := {}
	for k in d.keys():
		if absf(float(d[k])) >= 0.05:
			clean[k] = d[k]
	return gs.rel_add(id, P, clean, true)


static func start(gs: GameWorld, id: String) -> void:
	gs.w["dialogue"]["last_talk"][id] = gs.get_day()


## Ana giriş noktası
static func choose(gs: GameWorld, id: String, topic: String, arg: String = "") -> Dictionary:
	var r: Dictionary
	if topic.begins_with("ev:"):
		r = _event(gs, id, topic.substr(3), arg)
	else:
		match topic:
			"hal":
				r = _hal(gs, id)
			"kisisel":
				r = _kisisel(gs, id)
			"aile":
				r = _aile(gs, id)
			"devlet":
				r = _devlet(gs, id)
			"iltifat":
				r = _iltifat(gs, id)
			"gonul":
				r = _gonul(gs, id)
			"hediye":
				r = _hediye(gs, id, arg)
			"tavsiye":
				r = _tavsiye(gs, id, arg)
			"gorev":
				r = _gorev(gs, id, arg)
			"ozel":
				r = _ozel(gs, id, arg)
			"anlasmazlik":
				r = _anlasmazlik(gs, id, arg)
			"dedikodu":
				r = _dedikodu(gs, id)
			"evlilik":
				r = _evlilik(gs, id)
			"azarla":
				r = _azarla(gs, id)
			"harem":
				r = _harem(gs, id, arg)
			"hanedan":
				r = _hanedan(gs, id, arg)
			"yargi":
				r = JusticeEngine.dialogue(gs, id, arg)
			"gece":
				r = _gece(gs, id)
			"veda":
				r = _res(pick_line(gs, id, "veda"), {}, [], true)
			_:
				r = _res("...")
	if r["sub"].is_empty() and topic != "veda":
		gs.advance_minutes(10)
	return r


# ------------------------------------------------------------ konular

static func _hal(gs: GameWorld, id: String) -> Dictionary:
	var n := _today(gs, id, "hal")
	_bump(gs, id, "hal")
	var f := 1.0 / (1.0 + n)
	var soc: float = gs.trait_of(id, "sosyal")
	var d := {"sevgi": 1.5 * (0.7 + soc / 100.0 * 0.6) * f, "arkadaslik": 1.5 * f}
	if float(gs.ch(id)["mood"]) < -20.0:
		d["guven"] = 1.5 * f
		gs.adjust_mood(id, 6.0 * f)
	gs.ch(id)["needs"]["sosyal"] = minf(100.0, float(gs.ch(id)["needs"]["sosyal"]) + 10.0)
	return _res(pick_line(gs, id, "hal"), _apply(gs, id, d))


static func _next_lore(gs: GameWorld, id: String) -> int:
	var lore: Array = gs.ch(id).get("lore", [])
	var unlocked: Array = gs.lore_unlocked(id)
	var guven: float = gs.rel_val(id, P, "guven")
	for i in range(lore.size()):
		if i in unlocked:
			continue
		if float(lore[i]["trust"]) <= guven:
			return i
		return -2
	return -1


static func _kisisel(gs: GameWorld, id: String) -> Dictionary:
	var n := _today(gs, id, "kisisel")
	_bump(gs, id, "kisisel")
	var idx := _next_lore(gs, id)
	if idx >= 0 and n < 2:
		gs.unlock_lore(id, idx)
		var lore: Array = gs.ch(id)["lore"]
		var intro := pick_line(gs, id, "kisisel_acik")
		var d := _apply(gs, id, {"guven": 2.0, "arkadaslik": 2.0})
		gs.add_log("Öğrendiniz (%s): %s" % [gs.short_name(id), lore[idx]["t"]], "bilgi", 1)
		return _res("%s\n\n[i]%s[/i]" % [intro, lore[idx]["t"]], d)
	if idx == -1:
		# tüm geçmiş biliniyor: hedefler ve korkular
		var c: Dictionary = gs.ch(id)
		var goals: Array = c.get("goals", [])
		var fears: Array = c.get("fears", [])
		gs.set_flag("hedef_bilinen:" + id, true)
		var line := ""
		if gs.rng.randf() < 0.5 and not goals.is_empty():
			line = "En çok istediğim şey mi, %s? %s." % [hitap(gs, id), goals[gs.rng.randi() % goals.size()]]
		elif not fears.is_empty():
			line = "Gece uykumu kaçıran şey... %s. Bunu size söylediğime inanamıyorum." % String(fears[gs.rng.randi() % fears.size()]).to_lower()
		else:
			line = "Size anlatacak sırrım kalmadı, %s." % hitap(gs, id)
		return _res(line, _apply(gs, id, {"arkadaslik": 1.5 / (1.0 + n)}))
	return _res(pick_line(gs, id, "kisisel_kapali"), _apply(gs, id, {"sevgi": 0.5 / (1.0 + n)}))


static func _aile(gs: GameWorld, id: String) -> Dictionary:
	var n := _today(gs, id, "aile")
	_bump(gs, id, "aile")
	var f := 1.0 / (1.0 + n)
	var line := pick_line(gs, id, "aile")
	if id == "leyla" and 1 in gs.lore_unlocked("leyla") and gs.rng.randf() < 0.5:
		line = "Babam hain değildi, Sultanım. Bunu ölene kadar söyleyeceğim."
	var d := {"sevgi": 2.0 * (0.6 + gs.trait_of(id, "merhamet") / 100.0 * 0.8) * f, "arkadaslik": 1.0 * f}
	return _res(line, _apply(gs, id, d))


static func _devlet(gs: GameWorld, id: String) -> Dictionary:
	var n := _today(gs, id, "devlet")
	_bump(gs, id, "devlet")
	var c: Dictionary = gs.ch(id)
	if not (c["role"] in STATE_ROLES or id == "feraye" or gs.post_of(id) != ""):
		return _res(pick_line(gs, id, "devlet_yok"), _apply(gs, id, {"sevgi": 0.5}))
	var text := _state_talk(gs, id)
	var d := {"saygi": (1.5 if gs.trait_of(id, "ozguven") > 60.0 else 1.0) / (1.0 + n), "siyasi_uyum": 1.0 / (1.0 + n)}
	return _res(text, _apply(gs, id, d))


static func _worst_prov(gs: GameWorld, stat: String) -> Dictionary:
	var low := {}
	for p in gs.w["provinces"]:
		if low.is_empty() or float(p[stat]) < float(low[stat]):
			low = p
	return low


static func _state_talk(gs: GameWorld, id: String) -> String:
	var b := Economy.budget(gs)
	var h := hitap(gs, id)
	var post: String = gs.post_of(id)
	var worst := _worst_prov(gs, "huzur")
	match post:
		"sadrazam":
			return "%s, hazinede %s var; aylık net %s. Beni en çok %s kaygılandırıyor: halkın huzuru %%%d. %s" % [h.capitalize(), gs.fmt_money(gs.treasury()), gs.fmt_money(float(b["net"])), worst["name"], int(worst["huzur"]), "Divan'da bu meseleyi konuşmalıyız." if float(worst["huzur"]) < 45 else "Ama devlet yerli yerinde."]
		"hazine":
			var tail := "Bu gidişle hazine eriyecek; vergi ya da saray masrafı yeniden düşünülmeli." if float(b["net"]) < 0 else "Hazine fazla veriyor; yatırım için uygun bir dönem."
			return "Aylık gelirimiz %s, giderimiz %s, %s. %s" % [gs.fmt_money(float(b["gelir"])), gs.fmt_money(float(b["giderler"]["toplam"])), h, tail]
		"ordu":
			var korv := _nb(gs, "korvath")
			return "Korvath sınırda bekliyor, %s (tutumları %d/100). Ordunun ihtiyacı belli: daha fazla akçe, daha fazla asker. %s" % [h, int(korv["attitude"]), "Şimdiki bütçeyle sınırı ancak tutarız." if int(gs.w["state"]["army_level"]) < 2 else "Bütçe artırıldı; askerin morali yerinde."]
		"diplomasi":
			var parts: Array = []
			for nb in gs.w["neighbors"]:
				parts.append("%s %d" % [nb["name"].split(" ")[0], int(nb["attitude"])])
			return "Komşuların bize bakışı şöyle, %s: %s. Korvath'a dikkat, Varenya'yı ticaretle kazanabiliriz." % [h, ", ".join(PackedStringArray(parts))]
		"adalet":
			return "Adalet itibarımız %%%d, %s. Halk Kabul Salonu'nda %d dilekçe bekliyor. Halk, hükümdarın kendisini dinlediğini görmek ister." % [int(gs.w["state"]["justice"]), h, PetitionEngine.list(gs).size()]
	match id:
		"mahinur":
			return "Divan'da kim ne konuşuyor, ben bu daireden bile duyarım, oğlum. Halil Paşa'ya fazla yüz verme; Kemal dürüsttür ama korkaktır. Tolga'yı ise bir savaşla oyalamazsan o seni oyalar."
		"feraye":
			return "Sahmir'den gelen tüccarlar sınırda gümrüğün ağırlaştığını söylüyor, Sultanım. Sahmir ticareti kaybedersek, Güneyyurt aç kalır. %s" % ("Korvath ise sessizliğini korumuyor." if _nb(gs, "korvath")["attitude"] < 35 else "")
		"riza":
			return "Divan kayıtlarına göre bu hafta en çok şikâyet %s geldi, %s. Ve tahıl fiyatı endeksi %.2f." % [TR.abl(String(worst["name"])), h, float(gs.w["state"]["food_price"])]
		"edric":
			return "Kralım barıştan yana, Majesteleri. Demirkapı geçidi genişlerse iki ülke de kazanır. Ama Korvath'ın niyetinden biz de emin değiliz."
	return "Devlet işleri ağır işlerdir, %s. Elimden geldiğince takip ediyorum." % h


static func _nb(gs: GameWorld, nid: String) -> Dictionary:
	for nb in gs.w["neighbors"]:
		if nb["id"] == nid:
			return nb
	return {"attitude": 50, "name": "?"}


static func _iltifat(gs: GameWorld, id: String) -> Dictionary:
	var n := _today(gs, id, "iltifat")
	_bump(gs, id, "iltifat")
	if n >= 2:
		return _res(pick_line(gs, id, "iltifat_fazla"), _apply(gs, id, {"saygi": -2.0, "sevgi": -1.0}))
	var soc: float = gs.trait_of(id, "sosyal")
	var oz: float = gs.trait_of(id, "ozguven")
	var d := {"sevgi": 3.0 * (1.0 + (soc - 50.0) / 100.0 - (oz - 50.0) / 150.0) / (1.0 + n)}
	if oz > 80.0:
		d["saygi"] = -0.5
	gs.adjust_mood(id, 4.0)
	return _res(pick_line(gs, id, "iltifat"), _apply(gs, id, d))


static func _romance_rivals(gs: GameWorld, id: String) -> Array:
	var out: Array = []
	for oid in gs.npc_ids():
		if oid != id and gs.ch(oid).get("romanceable", false):
			out.append(oid)
	return out


static func _jealousy(gs: GameWorld, id: String, amount: float, what: String) -> void:
	var room: String = gs.ch(id)["location"]
	for oid in _romance_rivals(gs, id):
		if gs.ch(oid)["location"] == room and not gs.ch(oid)["activity"] in ["uyku", "disarida"]:
			gs.rel_add(oid, id, {"kiskanclik": amount, "rekabet": amount * 0.6})
			gs.rel_add(oid, P, {"romantik": -amount * 0.3})
			gs.add_memory(oid, "kiskanclik", [P, id], -amount * 3.0, "Hükümdarın %s %s gördüm." % [TR.ins(gs.short_name(id)), what], "gozlem", true, {"key": "kiskan:%s:%d" % [id, gs.get_day()]})


static func _gonul(gs: GameWorld, id: String) -> Dictionary:
	var n := _today(gs, id, "gonul")
	_bump(gs, id, "gonul")
	var sev: float = gs.rel_val(id, P, "sevgi")
	var guv: float = gs.rel_val(id, P, "guven")
	if sev < 35.0 or guv < 25.0:
		return _res(pick_line(gs, id, "gonul_ret"), _apply(gs, id, {"romantik": 1.0, "saygi": -1.0}))
	if n >= 2:
		return _res("(Gülümser.) Bugün yeterince güzel söz duydum, Sultanım. Biraz da yarına kalsın.", _apply(gs, id, {"romantik": 0.5}))
	var personal := 1.0
	if id == "leyla":
		personal += (gs.player_skill("ilim") - 50.0) / 100.0
	elif id == "feraye":
		personal += (float(gs.w["state"]["prestige"]) - 50.0) / 100.0
	var d := {"romantik": 4.0 * (0.6 + sev / 120.0) * personal / (1.0 + n), "sevgi": 1.5}
	gs.adjust_mood(id, 8.0)
	_jealousy(gs, id, 4.0, "yakın ilgisini")
	for wid in gs.witnesses(gs.ch(id)["location"], [id]):
		gs.add_memory(wid, "gonul_gozlem", [P, id], 0.0, "Hükümdar, %s gönül eğlendiriyordu." % TR.ins(gs.short_name(id)), "gozlem", true, {"key": "gonul:%s:%d" % [id, gs.get_day()]})
	return _res(pick_line(gs, id, "gonul"), _apply(gs, id, d))


static func _hediye(gs: GameWorld, id: String, arg: String) -> Dictionary:
	if arg == "":
		var sub: Array = []
		for g in DialogueData.GIFTS:
			sub.append({"id": "hediye", "arg": g["id"], "label": "%s (%s)" % [g["name"], gs.fmt_money(float(g["cost"]))], "disabled": gs.treasury() < float(g["cost"])})
		return _res("", {}, sub, false, "Hangi hediyeyi vereceksiniz?")
	if _today(gs, id, "hediye") >= 1:
		return _res("Bugün zaten bir hediye verdiniz, %s. Bu kadar cömertlik dikkat çeker." % hitap(gs, id))
	var gift := {}
	for g in DialogueData.GIFTS:
		if g["id"] == arg:
			gift = g
	if gift.is_empty():
		return _res("...")
	var c: Dictionary = gs.ch(id)
	if arg == "altin" and gs.trait_of(id, "durustluk") >= 85.0:
		_bump(gs, id, "hediye")
		return _res("Bağışlayın, %s; görevim için ayrıca altın alamam. Bu, rüşvet gibi durur." % hitap(gs, id), _apply(gs, id, {"saygi": 3.0, "sevgi": 1.0}))
	if not gs.spend(float(gift["cost"]), "hediye"):
		return _res("Hazinede bu hediye için yeterli akçe yok.")
	_bump(gs, id, "hediye")
	var liked: bool = arg in c.get("likes", [])
	var val := float(gift["value"])
	var greed := 1.0
	if arg in ["altin", "mucevher"]:
		greed = 0.7 + gs.trait_of(id, "hirs") / 100.0 * 0.6
	var d := {"sevgi": val * (1.6 if liked else 1.0) * greed, "borcluluk": val * 1.5}
	if c.get("romanceable", false) and gs.rel_val(id, P, "sevgi") > 40.0:
		d["romantik"] = val * 0.5 * (1.4 if liked else 1.0)
	var key := "hediye:%s:%d" % [id, gs.get_day()]
	gs.add_memory(id, "hediye", [P], 10.0 + val * 5.0 * (1.4 if liked else 1.0), "Hükümdar bana %s hediye etti." % String(gift["name"]).to_lower(), "dogrudan", true, {"key": key})
	gs.adjust_mood(id, 10.0)
	if c.get("romanceable", false):
		_jealousy(gs, id, 6.0, "hediye verdiğini")
	var line: String
	if id == "mahinur":
		line = "Oğlum, hediyeye gerek yok. Ama... yine de çok güzel."
	elif liked:
		line = "Bu... tam da istediğim şeydi! Nereden bildiniz, %s?" % hitap(gs, id)
	elif greed > 1.05:
		line = "(Gözleri parlar.) Cömertliğiniz dillere destan olacak, %s." % hitap(gs, id)
	else:
		line = "Ne zarif bir hediye. Teşekkür ederim, %s." % hitap(gs, id)
	return _res(line, _apply(gs, id, d))


static func _tavsiye(gs: GameWorld, id: String, arg: String) -> Dictionary:
	if arg == "":
		var sub: Array = []
		for t in DialogueData.ADVICE_TOPICS:
			sub.append({"id": "tavsiye", "arg": t["id"], "label": t["name"]})
		return _res("", {}, sub, false, "Hangi konuda tavsiye istiyorsunuz?")
	var n := _today(gs, id, "tavsiye")
	_bump(gs, id, "tavsiye")
	gs.player_skill_add("yonetim", 0.3)
	var text := _advice(gs, id, arg)
	return _res(text, _apply(gs, id, {"saygi": 1.5 / (1.0 + n), "siyasi_uyum": 1.0 / (1.0 + n)}))


static func _advice(gs: GameWorld, id: String, topic: String) -> String:
	var h := hitap(gs, id)
	var b := Economy.budget(gs)
	match topic:
		"hazine":
			if gs.skill_of(id, "ekonomi") < 45.0:
				return "Hazine işleri benim aklımın almayacağı kadar karışık, %s. Kemal Bey'e sorun." % h
			var net := float(b["net"])
			var line := ""
			if net < 0:
				var months := int(gs.treasury() / maxf(-net, 1.0))
				line = "Aylık %s açık veriyoruz; bu gidişle hazine yaklaşık %d ayda tükenir. Ya vergi artmalı ya saray ve ordu masrafı kısılmalı." % [gs.fmt_money(-net), months]
			else:
				var best := {}
				for p in gs.w["provinces"]:
					if best.is_empty() or float(p["ticaret"]) + float(p["altyapi"]) * 0.5 > float(best["ticaret"]) + float(best["altyapi"]) * 0.5:
						best = p
				line = "Hazine ayda %s fazla veriyor. Bu fazlayı yatırıma çevirin; %s pazar ya da yol yatırımı kendini çabuk öder." % [gs.fmt_money(net), TR.dat(String(best["name"]))]
			if id == "tolga":
				line += " Ama unutmayın: hazine ordu içindir."
			elif id == "mahinur":
				line += " Yalnız saray masrafını kısma; görkem de bir güçtür."
			return line
		"halk":
			if gs.skill_of(id, "yonetim") < 45.0 and gs.skill_of(id, "adalet") < 50.0:
				return "Halk ekmek ve adalet ister, %s. İkisi varsa sesini çıkarmaz." % h
			var w := _worst_prov(gs, "huzur")
			var why := "valisi gözden geçirilmeli."
			if float(w["gida"]) < 2.0:
				why = "ambarları boş; yardım gönderilmeli."
			elif int(gs.w["state"]["tax_level"]) >= 3:
				why = "vergiler halkın belini büküyor."
			elif float(w["guvenlik"]) < 50.0:
				why = "yolları güvensiz; eşkıya at koşturuyor."
			return "En huzursuz eyaletimiz %s (huzur %%%d). Bence %s Ortalama halk huzuru %%%d." % [w["name"], int(w["huzur"]), why, int(gs.people_huzur())]
		"saray":
			var worst_pair := []
			var worst_v := 0.0
			for a in gs.social_ids():
				for c2 in gs.social_ids():
					if a == c2:
						continue
					var v := gs.rel_val(a, c2, "rekabet") + gs.rel_val(a, c2, "kiskanclik")
					if v > worst_v:
						worst_v = v
						worst_pair = [a, c2]
			if worst_pair.is_empty() or worst_v < 60.0:
				return "Sarayda şimdilik sular durgun, %s." % h
			if id in GOSSIPS or gs.trait_of(id, "sosyal") > 70.0 or id == "mahinur":
				return "%s, %s karşı derin bir kin besliyor, %s. Bu iş bir gün patlayacak." % [gs.short_name(worst_pair[0]), TR.dat(gs.short_name(worst_pair[1])), h]
			return "Saray işlerine pek karışmam, %s. Ama koridorlarda gerginlik var; bunu herkes hissediyor." % h
		"guven":
			var best_id := ""
			var best_g := -1.0
			var low_id := ""
			var low_o := 999.0
			for oid in gs.social_ids():
				if oid == id:
					continue
				var g := gs.rel_val(id, oid, "guven")
				if g > best_g:
					best_g = g
					best_id = oid
				var o: float = gs.opinion(id, oid)
				if o < low_o:
					low_o = o
					low_id = oid
			if gs.rel_val(id, P, "guven") < 35.0:
				return "Kime güveneceğinizi bana sormanız ne tuhaf, %s. Kimseye." % h
			return "Ben olsam %s güvenirdim, %s. %s ise... ondan uzak durun." % [TR.dat(gs.short_name(best_id)), h, gs.short_name(low_id)]
		"sinir":
			if gs.skill_of(id, "askeri") < 45.0 and gs.skill_of(id, "diplomasi") < 60.0:
				return "Askerlikten anlamam, %s. Ama Karaburç'tan gelen haberler iç açıcı değil." % h
			var k := _nb(gs, "korvath")
			var kar: Dictionary = gs.province("karaburc")
			var comment := "Karaburç'un savunması zayıf; takviye şart." if float(kar["guvenlik"]) < 65.0 else "Karaburç sağlam; şimdilik endişe yok."
			if id == "selim":
				comment += " Yine de diplomasi kılıçtan ucuzdur."
			elif id == "tolga":
				comment += " Bir sefer, Korvath'a haddini bildirir."
			return "Korvath'ın bize bakışı %d/100, %s. %s" % [int(k["attitude"]), h, comment]
	return "Bu konuda söyleyecek pek bir şeyim yok, %s." % h


# ------------------------------------------------------------ görevler

static func _tasks(gs: GameWorld, id: String) -> Array:
	var out: Array = []
	match id:
		"riza":
			out.append({"id": "gorev", "arg": "arastir", "label": "Birini araştır"})
		"arslan":
			if not gs.flag("guvenlik_sikilasti"):
				out.append({"id": "gorev", "arg": "nobet", "label": "Saray nöbetlerini sıklaştır (ayda 400 akçe)"})
		"sadik":
			out.append({"id": "gorev", "arg": "ders", "label": "Bana ders ver (2 saat)", "disabled": _today(gs, id, "ders") > 0})
		"kemal":
			if not gs.flag("denetim") and not gs.flag("denetim_bitti"):
				out.append({"id": "gorev", "arg": "denetim", "label": "Hazineyi denetle"})
		"nurettin":
			if 1 in gs.lore_unlocked("leyla") and not gs.flag("davud_acildi") and not gs.flag("davud_temize") and not gs.flag("davud_muhurlendi"):
				out.append({"id": "gorev", "arg": "davud", "label": "Davud Bey davasını yeniden incele"})
		"selim":
			out.append({"id": "gorev", "arg": "elci", "label": "Bir komşuya elçi gönder (1.500 akçe)"})
		"omer":
			out.append({"id": "gorev", "arg": "bahce", "label": "Bahçeleri güzelleştir (800 akçe)", "disabled": gs.get_day() - int(gs.w["flags"].get("bahce_gun", -99)) < 10})
		"bekir":
			out.append({"id": "gorev", "arg": "sofra", "label": "Bu akşam özel bir sofra hazırla (300 akçe)"})
		"kamil":
			if not gs.flag("portre"):
				out.append({"id": "gorev", "arg": "portre", "label": "Portremi yap (2.000 akçe)"})
		"gulbahar":
			out.append({"id": "gorev", "arg": "huzur", "label": "Haremde huzuru sağla", "disabled": gs.get_day() - int(gs.w["flags"].get("harem_huzur_gun", -99)) < 7})
		"tolga":
			out.append({"id": "gorev", "arg": "talim", "label": "Bir talim gösterisi düzenle (1 saat)", "disabled": _today(gs, id, "talim") > 0})
		"edric":
			out.append({"id": "gorev", "arg": "mektup", "label": "Kralına dostluk mektubu ilet"})
	return out


static func _gorev(gs: GameWorld, id: String, arg: String) -> Dictionary:
	if arg == "":
		return _res("", {}, _tasks(gs, id), false, "Hangi görevi vereceksiniz?")
	var h := hitap(gs, id)
	if arg.begins_with("arastir"):
		var parts := arg.split(":")
		if parts.size() < 2:
			var sub: Array = []
			for oid in gs.social_ids():
				if oid != "riza":
					sub.append({"id": "gorev", "arg": "arastir:" + oid, "label": gs.short_name(oid)})
			return _res("", {}, sub, false, "Kimi araştırsın?")
		var target: String = parts[1]
		if not gs.w.has("tasks"):
			gs.w["tasks"] = []
		gs.w["tasks"].append({"type": "riza_rapor", "target": target, "due": gs.total_minutes() + 18 * 60})
		return _res("Yarın bu saatlere kadar %s hakkında bilmeniz gereken her şey masanızda olacak, %s." % [gs.short_name(target), h], _apply(gs, id, {"saygi": 1.0, "borcluluk": -1.0}))
	match arg:
		"nobet":
			gs.set_flag("guvenlik_sikilasti", true)
			gs.w["flags"]["upkeep_nobet"] = 400
			return _res("Bu geceden itibaren hazine ve harem kapılarında çift nöbet olacak, Hünkârım. Kuş uçurtmayız.", _apply(gs, id, {"saygi": 2.0, "guven": 2.0}))
		"ders":
			_bump(gs, id, "ders")
			gs.advance_minutes(110)
			var skills := ["ilim", "diplomasi", "yonetim", "adalet", "ekonomi"]
			var s1: String = skills[gs.rng.randi() % skills.size()]
			gs.player_skill_add("ilim", 1.5)
			gs.player_skill_add(s1, 1.0)
			var topic: String = {"ilim": "gökbilim ve eski hekimler", "diplomasi": "eski elçilik mektupları", "yonetim": "büyük vezirlerin hataları", "adalet": "kadı sicillerinden örnekler", "ekonomi": "akçenin değeri ve tağşiş"}[s1]
			return _res("İki saat boyunca Molla Sadık size %s üzerine ders verdi. \"Bir hükümdarın en büyük hazinesi sorabileceği doğru sorulardır,\" dedi. (İlim ve %s gelişti.)" % [topic, CharactersData.SKILL_NAMES[s1]], _apply(gs, id, {"sevgi": 2.0, "arkadaslik": 2.0}))
		"denetim":
			gs.set_flag("denetim", true)
			if EventEngine.is_present(gs, "yusuf"):
				EventEngine.schedule(gs, "denetim_sonuc", 4, {})
			return _res("Defterleri satır satır inceleyeceğim, Sultanım. Dört gün içinde size kesin bilgi getiririm.", _apply(gs, id, {"guven": 5.0, "saygi": 3.0}))
		"davud":
			gs.set_flag("davud_acildi", true)
			EventEngine.schedule(gs, "davud_sonuc", 7, {})
			gs.rel_add("halil", P, {"korku": 8.0, "siyasi_uyum": -5.0})
			gs.add_memory("halil", "tehdit", [P], -25.0, "Hükümdar Davud dosyasını yeniden açtırdı.", "soylenti", true, {"key": "davud_acildi"})
			return _res("(Uzun bir sessizlik.) Bu davayı yıllardır bekliyordum, Sultanım. Yedi gün içinde gerçeği önünüze koyacağım.", _apply(gs, id, {"saygi": 8.0, "sevgi": 5.0}))
		"elci":
			var sub2: Array = []
			for nb in gs.w["neighbors"]:
				sub2.append({"id": "gorev", "arg": "elci_" + String(nb["id"]), "label": "%s (tutum %d)" % [nb["name"], int(nb["attitude"])], "disabled": gs.treasury() < 1500.0})
			return _res("", {}, sub2, false, "Hangi ülkeye elçi gönderilsin?")
		"bahce":
			if not gs.spend(800.0, "bahce"):
				return _res("Hazine yetersiz.")
			gs.w["flags"]["bahce_gun"] = gs.get_day()
			for nid in gs.npc_ids():
				gs.adjust_mood(nid, 3.0)
			gs.state_add("prestige", 1.0)
			return _res("Yarın sabah bahçelerde yeni çiçekler göreceksiniz, Sultanım. Leylaklar, sümbüller, bir de Acem güllerinden.", _apply(gs, id, {"sevgi": 3.0, "saygi": 1.0}))
		"sofra":
			var sub3: Array = []
			for gid in ["mahinur", "leyla", "feraye"]:
				if EventEngine.is_present(gs, gid):
					sub3.append({"id": "gorev", "arg": "sofra_" + gid, "label": gs.short_name(gid), "disabled": gs.treasury() < 300.0})
			return _res("", {}, sub3, false, "Sofraya kimi davet edeceksiniz?")
		"portre":
			if not gs.spend(2000.0, "portre"):
				return _res("Hazine yetersiz.")
			gs.set_flag("portre", true)
			gs.state_add("prestige", 1.0)
			return _res("(Kâmil Usta'nın gözleri parlar.) Ömrümün eseri olacak, Sultanım! Yarın sabah ilk ışıkla başlıyorum.", _apply(gs, id, {"sevgi": 8.0, "borcluluk": 8.0}))
		"huzur":
			gs.w["flags"]["harem_huzur_gun"] = gs.get_day()
			for pair in [["sumbul", "nergis"], ["nergis", "sumbul"], ["leyla", "feraye"], ["feraye", "leyla"]]:
				if EventEngine.is_present(gs, pair[0]) and EventEngine.is_present(gs, pair[1]):
					gs.rel_add(pair[0], pair[1], {"rekabet": -6.0, "kiskanclik": -4.0}, false)
			return _res("Merak etmeyin, Sultanım. Haremde kim kime yan bakarsa önce benimle karşılaşır.", _apply(gs, id, {"saygi": 2.0}))
		"talim":
			_bump(gs, id, "talim")
			gs.advance_minutes(50)
			gs.state_add("prestige", 1.0)
			gs.player_skill_add("askeri", 1.0)
			return _res("Avluda sipahiler at koşturdu, okçular nişan tahtalarını deldi. Tolga Paşa'nın gözleri gururla parlıyordu. (Askerlik gelişti.)", _apply(gs, id, {"sevgi": 4.0, "siyasi_uyum": 3.0}))
		"mektup":
			if _today(gs, id, "mektup") > 0:
				return _res("Mektubunuz zaten yolda, Majesteleri.")
			_bump(gs, id, "mektup")
			for nb in gs.w["neighbors"]:
				if nb["id"] == "varenya":
					nb["attitude"] = clampf(float(nb["attitude"]) + 3.0, 0.0, 100.0)
			return _res("Kralım bu mektubu çerçeveletir, Majesteleri. Dostluğunuzu kelimesi kelimesine aktaracağım.", _apply(gs, id, {"sevgi": 3.0}))
	if arg.begins_with("elci_"):
		var nid := arg.substr(5)
		if not gs.spend(1500.0, "elci"):
			return _res("Hazine yetersiz.")
		for nb2 in gs.w["neighbors"]:
			if nb2["id"] == nid:
				nb2["attitude"] = clampf(float(nb2["attitude"]) + 4.0 + gs.skill_of("selim", "diplomasi") / 40.0, 0.0, 100.0)
				gs.add_log("%s sarayına hediyelerle bir elçi gönderildi." % nb2["name"], "diplomasi", 1)
		gs.player_skill_add("diplomasi", 0.5)
		return _res("En yetenekli kâtiplerimden birini hediyelerle yola çıkaracağım, %s." % h, _apply(gs, id, {"saygi": 2.0, "siyasi_uyum": 2.0}))
	if arg.begins_with("sofra_"):
		var guest := arg.substr(6)
		if not gs.spend(300.0, "sofra"):
			return _res("Hazine yetersiz.")
		var gd := {"sevgi": 5.0}
		if gs.ch(guest).get("romanceable", false):
			gd["romantik"] = 4.0
			_jealousy(gs, guest, 4.0, "akşam yemeği yediğini")
		gs.rel_add(guest, P, gd)
		gs.add_memory(guest, "jest", [P], 25.0, "Hükümdar beni özel bir akşam sofrasına davet etti.", "dogrudan", true, {"key": "sofra:%s:%d" % [guest, gs.get_day()]})
		gs.add_log("Akşam %s ile özel bir sofra kuruldu." % gs.short_name(guest), "saray", 1)
		return _res("Lüferi ızgara, kuzuyu fırında yaparım, Efendimiz. %s bu akşamı unutmayacak!" % gs.short_name(guest), _apply(gs, id, {"sevgi": 2.0}))
	return _res("...")


## Saatlik görev işleme (EventEngine.hourly çağırır)
static func process_tasks(gs: GameWorld) -> void:
	if not gs.w.has("tasks"):
		gs.w["tasks"] = []
		return
	var keep: Array = []
	for t in gs.w["tasks"]:
		if gs.total_minutes() >= int(t["due"]):
			if t["type"] == "riza_rapor":
				_riza_report(gs, String(t["target"]))
		else:
			keep.append(t)
	gs.w["tasks"] = keep


static func _riza_report(gs: GameWorld, target: String) -> void:
	if gs.ch(target).is_empty():
		return
	var lines: Array = []
	var lore: Array = gs.ch(target).get("lore", [])
	for i in range(lore.size()):
		if not i in gs.lore_unlocked(target):
			if gs.rng.randf() < 0.75 or i == 0:
				gs.unlock_lore(target, i)
				lines.append(lore[i]["t"])
			break
	var best := ""
	var bv := -1.0
	var worst := ""
	var wv := 999.0
	for oid in gs.social_ids():
		if oid == target:
			continue
		var o: float = gs.opinion(target, oid)
		if o > bv:
			bv = o
			best = oid
		if o < wv:
			wv = o
			worst = oid
	lines.append("En yakın olduğu kişi: %s. En az sevdiği: %s." % [gs.short_name(best), gs.short_name(worst)])
	lines.append("Hükümdara bakışı: %s." % gs.opinion_label(gs.opinion(target, P)).to_lower())
	var secret := JusticeEngine.investigate_secret(gs, target)
	if secret != "":
		lines.append(secret)
	gs.add_log("Rıza Efendi'nin raporu (%s): %s" % [gs.short_name(target), " ".join(PackedStringArray(lines))], "bilgi", 2)


# ------------------------------------------------------------ özel meseleler

static func _threads(gs: GameWorld, id: String) -> Array:
	var out: Array = []
	var lu: Array = gs.lore_unlocked(id)
	match id:
		"leyla":
			if 1 in lu and not gs.flag("soz_davud") and not gs.flag("davud_acildi") and not gs.flag("davud_temize"):
				out.append({"id": "ozel", "arg": "davud_soz", "label": "Babanın davasını yeniden açtıracağım"})
				out.append({"id": "ozel", "arg": "davud_birak", "label": "Geçmişi geride bırakmalısın"})
		"halil":
			if 2 in lu and gs.post_of("halil") != "" and not gs.flag("davud_temize") and not gs.flag("halil_yuzlesme"):
				out.append({"id": "ozel", "arg": "halil_hesap", "label": "Davud Bey'in hesabını vereceksin"})
				out.append({"id": "ozel", "arg": "halil_borc", "label": "Bu sır aramızda kalacak... şimdilik"})
		"mahinur":
			if 2 in lu and not gs.flag("valide_itiraf"):
				out.append({"id": "ozel", "arg": "valide_itiraf", "label": "Babamın son yıllarında devleti sen mi yönettin?"})
		"arslan":
			if 1 in lu and not 2 in lu:
				out.append({"id": "ozel", "arg": "arslan_kardes", "label": "Tolga Paşa ile aranızda ne var?"})
		"feraye":
			if 2 in gs.lore_unlocked("feraye") and not gs.flag("feraye_ag") and not gs.flag("feraye_yuzlesme"):
				out.append({"id": "ozel", "arg": "feraye_mektup", "label": "Sahmir'e yazdığın mektuplar"})
		"nergis":
			if 1 in gs.lore_unlocked("leyla") and not 2 in gs.lore_unlocked("leyla"):
				out.append({"id": "ozel", "arg": "nergis_sir", "label": "Leyla'nın sakladığı bir şey var mı?"})
		"riza":
			if 2 in lu and not gs.flag("davud_acildi") and not gs.flag("davud_kapandi") and not gs.flag("davud_gizli"):
				out.append({"id": "ozel", "arg": "riza_dosya", "label": "Sakladığın belgeleri getir"})
	return out


static func _ozel(gs: GameWorld, id: String, arg: String) -> Dictionary:
	if arg == "":
		return _res("", {}, _threads(gs, id), false, "Hangi meseleyi açacaksınız?")
	match arg:
		"davud_soz":
			gs.set_flag("soz_davud", gs.get_day())
			gs.add_memory("leyla", "soz", [P], 35.0, "Hükümdar babamın davasını yeniden açtıracağına söz verdi.", "dogrudan", true, {"key": "soz_davud"})
			return _res("(Leyla'nın elleri titrer.) Bunu... bunu yıllardır birinin söylemesini bekledim, Sultanım. Sözünüzü unutmayacağım. Lütfen siz de unutmayın.", _apply(gs, id, {"guven": 10.0, "sevgi": 5.0, "romantik": 4.0}))
		"davud_birak":
			gs.add_memory("leyla", "ret", [P], -20.0, "Hükümdar babamın davasını unutmamı istedi.", "dogrudan", true, {"key": "davud_birak"})
			return _res("(Gözlerini kaçırır.) Geçmiş, Sultanım, bazılarımız için hiç geçmez.", _apply(gs, id, {"guven": -6.0, "sevgi": -3.0}))
		"halil_hesap":
			gs.set_flag("halil_yuzlesme", true)
			gs.set_flag("davud_acildi", true)
			EventEngine.schedule(gs, "davud_sonuc", 5, {})
			gs.add_memory("halil", "tehdit", [P], -40.0, "Hükümdar Davud Bey'in hesabını soracağını yüzüme söyledi.", "dogrudan", true, {"key": "halil_yuzlesme"})
			return _res("(Halil Paşa'nın yüzü bembeyaz kesilir.) Devletlüm... O gün devletin bekası söz konusuydu. Kadıasker'in hükmüne razıyım.", _apply(gs, id, {"korku": 15.0, "siyasi_uyum": -8.0}))
		"halil_borc":
			gs.set_flag("halil_yuzlesme", true)
			gs.set_flag("halil_borclu", true)
			gs.add_memory("halil", "tehdit", [P], -20.0, "Hükümdar Davud sırrını biliyor ve bunu bana karşı saklıyor.", "dogrudan", true, {"key": "halil_borc"})
			return _res("(Uzun bir sessizlik.) Anlaşıldı, Devletlüm. Bundan sonra bu ihtiyar kulunuzun mührü sizin mührünüzdür.", _apply(gs, id, {"borcluluk": 25.0, "korku": 10.0, "siyasi_uyum": 5.0}))
		"valide_itiraf":
			gs.set_flag("valide_itiraf", true)
			return _res("(Valide Sultan pencereye döner.) Baban son iki yılında kalemi tutamıyordu, oğlum. Biri o mektupları yazmak zorundaydı. Halil bunu biliyor. Şimdi sen de biliyorsun; ve artık ikimizin arasında sır kalmadı.", _apply(gs, id, {"guven": 8.0, "sevgi": 3.0}))
		"arslan_kardes":
			if gs.rel_val(id, P, "guven") >= 65.0:
				gs.unlock_lore("arslan", 2)
				gs.unlock_lore("tolga", 2)
				return _res("(Arslan Ağa uzun süre susar.) Yedi yıl önce Karaburç'ta, Tolga erken geri çekilme emri verdi. Kardeşim Kaya o tepede kaldı, Hünkârım. Tolga'nın kararı belki doğruydu. Ama ben onu hiç affetmedim.", _apply(gs, id, {"guven": 4.0, "arkadaslik": 4.0}))
			return _res("Bir gün anlatırım, Hünkârım. Ama bugün değil.", _apply(gs, id, {"saygi": 1.0}))
		"feraye_mektup":
			gs.set_flag("feraye_yuzlesme", true)
			if gs.rel_val(id, P, "romantik") >= 50.0 or gs.rel_val(id, P, "guven") >= 60.0:
				gs.set_flag("feraye_ag", true)
				for nb in gs.w["neighbors"]:
					if nb["id"] == "sahmir":
						nb["attitude"] = clampf(float(nb["attitude"]) + 4.0, 0.0, 100.0)
				return _res("(Feraye bir an donar, sonra gözlerinizin içine bakar.) Evet, Sultanım. Kuzenim Sahmir sarayında kâtip. Bana oradaki her fısıltıyı yazıyor. Bunu kendim için yapıyordum... ama artık bu ağ sizin.", _apply(gs, id, {"guven": 6.0, "korku": 4.0}))
			return _res("(Soğukkanlılıkla) Kuzenime yazıyorum, Sultanım. Bir yetimin ailesine yazması da mı suç oldu?", _apply(gs, id, {"guven": -5.0, "korku": 8.0}))
		"nergis_sir":
			if gs.rel_val(id, P, "guven") >= 55.0:
				gs.unlock_lore("leyla", 2)
				gs.unlock_lore("nergis", 1)
				return _res("(Nergis etrafına bakınır.) Hanımım... babasının idam fermanını kimin hazırlattığını biliyor, Sultanım. Halil Paşa. Bunu ona söylediğimi bilmesin, ne olur.", _apply(gs, id, {"guven": 3.0}))
			return _res("(Başını iki yana sallar.) Hanımımın sırları benim değil, Sultanım.", _apply(gs, id, {"saygi": 2.0}))
		"riza_dosya":
			EventEngine.add_event(gs, "davud_dosyasi", {})
			return _res("(Rıza Efendi yutkunur.) Peki, Devletlüm. Kütüphanenin en arka rafında. Hemen getiriyorum.", _apply(gs, id, {"guven": 2.0}))
	return _res("...")


# ------------------------------------------------------------ anlaşmazlıklar

static func _rivals(gs: GameWorld, id: String) -> Array:
	var out: Array = []
	for oid in gs.npc_ids():
		if oid == id:
			continue
		if gs.rel_val(id, oid, "rekabet") >= 55.0 or gs.rel_val(id, oid, "kiskanclik") >= 55.0:
			out.append(oid)
	return out


static func _anlasmazlik(gs: GameWorld, id: String, arg: String) -> Dictionary:
	if arg == "":
		var sub: Array = []
		for oid in _rivals(gs, id):
			var nm: String = gs.short_name(oid)
			sub.append({"id": "anlasmazlik", "arg": oid + ":baris", "label": "%s barışın" % TR.ins(nm)})
			sub.append({"id": "anlasmazlik", "arg": oid + ":taraf", "label": "%s karşı haklısın" % TR.dat(nm)})
			sub.append({"id": "anlasmazlik", "arg": oid + ":rakip", "label": "Bu meselede %s haklı" % nm})
		return _res("", {}, sub, false, "Hangi anlaşmazlık?")
	var parts := arg.split(":")
	var oid2: String = parts[0]
	var mode: String = parts[1]
	var nm2: String = gs.short_name(oid2)
	match mode:
		"baris":
			var chance: float = 0.35 + gs.player_skill("diplomasi") / 150.0 + (gs.trait_of(id, "sabir") + gs.trait_of(oid2, "sabir") - 100.0) / 250.0
			if gs.rng.randf() < chance:
				gs.rel_add(id, oid2, {"rekabet": -10.0, "kiskanclik": -6.0, "sevgi": 4.0})
				gs.rel_add(oid2, id, {"rekabet": -8.0, "kiskanclik": -5.0, "sevgi": 3.0})
				gs.player_skill_add("diplomasi", 1.0)
				gs.add_log("%s ile %s, hükümdarın aracılığıyla barıştı." % [gs.short_name(id), nm2], "saray", 1)
				return _res("(Bir süre düşünür.) Sizin hatırınız için, %s. %s eli uzatırsa ben de uzatırım." % [hitap(gs, id), nm2], _apply(gs, id, {"saygi": 3.0}))
			return _res("Bağışlayın, %s. Bazı yaralar bir sözle kapanmaz." % hitap(gs, id), _apply(gs, id, {"saygi": -1.0}))
		"taraf":
			gs.rel_add(oid2, P, {"sevgi": -5.0, "siyasi_uyum": -4.0})
			gs.add_memory(oid2, "ret", [P, id], -20.0, "Hükümdar %s tarafını tuttu." % TR.gen(gs.short_name(id)), "soylenti", true, {"key": "taraf:%s:%s" % [id, oid2]})
			gs.rel_add(id, oid2, {"rekabet": 3.0})
			return _res("Bunu sizden duymak... Teşekkür ederim, %s. Gerçeği gördüğünüzü biliyordum." % hitap(gs, id), _apply(gs, id, {"sevgi": 5.0, "siyasi_uyum": 4.0}))
		"rakip":
			gs.rel_add(oid2, P, {"sevgi": 4.0, "siyasi_uyum": 3.0})
			gs.add_memory(id, "ret", [P, oid2], -20.0, "Hükümdar %s tarafını tuttu." % TR.gen(nm2), "dogrudan", true, {"key": "rakip:%s:%s" % [id, oid2]})
			return _res("(Dudaklarını büzer.) Peki, %s. Siz öyle diyorsanız." % hitap(gs, id), _apply(gs, id, {"sevgi": -5.0, "siyasi_uyum": -4.0}))
	return _res("...")


static func _dedikodu(gs: GameWorld, id: String) -> Dictionary:
	var n := _today(gs, id, "dedikodu")
	_bump(gs, id, "dedikodu")
	if n >= 2:
		return _res("Bugünlük bu kadar, %s. Kulaklarım da dinlenmeli." % hitap(gs, id))
	var items: Array = gs.reveal_gossip(2 if n == 0 else 1)
	if items.is_empty():
		return _res(pick_line(gs, id, "dedikodu_yok"), _apply(gs, id, {"arkadaslik": 0.5}))
	var txt := pick_line(gs, id, "dedikodu_var")
	for it in items:
		txt += "\n• " + String(it["text"])
	return _res(txt, _apply(gs, id, {"arkadaslik": 1.0, "guven": 0.5}))


static func _evlilik(gs: GameWorld, id: String) -> Dictionary:
	var last := int(gs.w["flags"].get("teklif:" + id, -99))
	if gs.get_day() - last < 10:
		return _res("Size cevabımı verdim, Sultanım. Lütfen biraz zaman tanıyın.")
	gs.w["flags"]["teklif:" + id] = gs.get_day()
	var rom := gs.rel_val(id, P, "romantik")
	var score := rom * 0.5 + gs.rel_val(id, P, "sevgi") * 0.25 + gs.rel_val(id, P, "guven") * 0.25 + (gs.trait_of(id, "hirs") - 50.0) * 0.3
	var wives: Array = gs.player().get("married_to", [])
	score -= wives.size() * 6.0 * gs.trait_of(id, "kiskanclik") / 50.0
	var special := ""
	if id == "leyla" and not gs.flag("davud_temize"):
		score -= 15.0
		special = "davud"
	if score >= 58.0:
		gs.set_flag("nisan:" + id, true)
		EventEngine.schedule(gs, "dugun", 2, {"bride": id})
		gs.add_memory(id, "nisan", [P], 50.0, "Hükümdar bana evlenme teklif etti ve kabul ettim.", "dogrudan", true, {"key": "nisan:" + id})
		gs.add_log("%s evlilik teklifinizi kabul etti! Düğün hazırlıkları başladı." % gs.short_name(id), "harem", 2)
		for rid in _romance_rivals(gs, id):
			gs.rel_add(rid, id, {"kiskanclik": 12.0, "rekabet": 8.0})
			gs.rel_add(rid, P, {"romantik": -8.0})
			gs.add_memory(rid, "kiskanclik", [P, id], -35.0, "Hükümdar %s evleniyor." % TR.ins(gs.short_name(id)), "soylenti", true, {"key": "nisan:" + id})
		return _res(pick_line(gs, id, "evlilik_evet"), _apply(gs, id, {"romantik": 8.0, "sevgi": 6.0}))
	var line := pick_line(gs, id, "evlilik_hayir", {"special": special})
	return _res(line, _apply(gs, id, {"romantik": -3.0}))


static func _azarla(gs: GameWorld, id: String) -> Dictionary:
	var deserved: bool = gs.has_memory(id, "uyari", P) or gs.flag("suclu:" + id)
	if deserved:
		return _res(pick_line(gs, id, "azarla_hakli"), _apply(gs, id, {"korku": 6.0, "sevgi": -2.0, "saygi": 1.0}))
	gs.add_memory(id, "hakaret", [P], -25.0, "Hükümdar beni sebepsiz yere azarladı.", "dogrudan", true, {"key": "hakaret:%s:%d" % [id, gs.get_day()]})
	for wid in gs.witnesses(gs.ch(id)["location"], [id]):
		gs.add_memory(wid, "hakaret_gozlem", [P, id], -6.0, "Hükümdar %s herkesin önünde azarladı." % TR.acc(gs.short_name(id)), "gozlem", true, {"key": "hakaret:%s:%d" % [id, gs.get_day()]})
	return _res(pick_line(gs, id, "azarla_haksiz"), _apply(gs, id, {"korku": 7.0, "sevgi": -5.0, "saygi": -3.0}))


# ------------------------------------------------------------ görüşme talepleri (olaylar)

static func _event(gs: GameWorld, id: String, uid: String, arg: String) -> Dictionary:
	var ev: Dictionary = EventEngine.find(gs, uid)
	if ev.is_empty():
		return _res("Bu mesele artık kapandı.")
	if arg == "":
		var sub: Array = []
		for o in EventEngine.options_for(gs, ev):
			if not o["available"]:
				continue
			var label: String = o["text"]
			if float(o["cost"]) > 0:
				label += " (%s)" % gs.fmt_money(float(o["cost"]))
			sub.append({"id": "ev:" + uid, "arg": str(o["idx"]), "label": label, "disabled": not o["affordable"]})
		return _res(String(ev["text"]), {}, sub, false, String(ev["title"]))
	var before := gs.rel(id, P).duplicate()
	var result := EventEngine.resolve(gs, uid, int(arg))
	var after: Dictionary = gs.rel(id, P)
	var deltas := {}
	for k in after.keys():
		var d := float(after[k]) - float(before.get(k, after[k]))
		if absf(d) >= 0.5:
			deltas[k] = d
	return _res(result if result != "" else "...", deltas)


# ------------------------------------------------------------ Hasodabaşı: harem işleri

static func _harem(gs: GameWorld, id: String, arg: String) -> Dictionary:
	var parts := arg.split("|")
	var step: String = parts[0] if arg != "" else ""
	var h := hitap(gs, id)
	match step:
		"":
			var sub: Array = [
				{"id": "harem", "arg": "aday", "label": "Yeni cariye adayları"},
				{"id": "harem", "arg": "soylu", "label": "Soylu bir ailede eş arayın"},
				{"id": "harem", "arg": "davet", "label": "Bu gece için davet gönder"},
			]
			if not HaremEngine.nikah_candidates(gs).is_empty():
				sub.append({"id": "harem", "arg": "nikah", "label": "Bir hanımla nikâh kıy"})
			if not HaremEngine.azat_candidates(gs).is_empty():
				sub.append({"id": "harem", "arg": "azat", "label": "Bir cariyeyi azat et"})
			var txt := HaremEngine.report(gs)
			var props: Array = HaremEngine.data(gs)["proposals"]
			if not props.is_empty():
				var fams: Array = []
				for pr in props:
					fams.append(String(pr["noble"]["house"]["family"]))
				txt += "\n\nCevabı beklenen evlilik teklifleri: " + ", ".join(PackedStringArray(fams)) + "."
			return _res(txt, {}, sub, false, "Harem işleri")
		"aday":
			var cands: Array = HaremEngine.refresh_candidates(gs)
			var full: bool = HaremEngine.women(gs).size() >= HaremEngine.capacity(gs)
			var txt2 := "Kethüda Gülbahar Hatun'la birlikte görüştüğümüz, saraya gelmeye razı olmuş adaylar bunlar, %s:" % h
			var sub2: Array = []
			for i in range(cands.size()):
				var cd: Dictionary = cands[i]
				txt2 += "\n\n[b]%d)[/b] %s\nSaraya geliş masrafı: %s" % [i + 1, String(cd["desc"]), gs.fmt_money(float(cd["price"]))]
				sub2.append({"id": "harem", "arg": "al|%d" % i, "label": "%s hareme alınsın (%s)" % [String(cd["proto"]["name"]), gs.fmt_money(float(cd["price"]))], "disabled": full or gs.treasury() < float(cd["price"])})
			if cands.is_empty():
				txt2 = "Şimdilik başka aday yok, %s." % h
			if full:
				txt2 += "\n\n[color=#e0a070]Harem dolu (%d/%d). Saray genişletilmeden yeni kimse alınamaz.[/color]" % [HaremEngine.women(gs).size(), HaremEngine.capacity(gs)]
			sub2.append({"id": "harem", "arg": "yenile", "label": "Başka adaylar bulun (300 akçe)", "disabled": gs.treasury() < 300.0})
			return _res(txt2, {}, sub2, false, "Cariye adayları")
		"al":
			var t := HaremEngine.accept_cariye(gs, int(parts[1]) if parts.size() > 1 else -1)
			return _res(t, _apply(gs, id, {"saygi": 0.5}))
		"yenile":
			if not gs.spend(300.0, "harem"):
				return _res("Hazinede yeterli akçe yok, %s." % h)
			HaremEngine.refresh_candidates(gs, true)
			return _harem(gs, id, "aday")
		"soylu":
			var arr: Array = HaremEngine.refresh_nobles(gs)
			if arr.is_empty():
				return _res("Şu an evlilik için uygun bir soylu aday yok, %s. Gelecek ay yeniden soruştururum." % h)
			var txt3 := "Soylu ailelerden eş adayları, %s. Teklif elçilerle ve mehirle gider; aile kabul ederse gelin saraya gelir, düğün yapılır:" % h
			var sub3: Array = []
			for i2 in range(arr.size()):
				var nb: Dictionary = arr[i2]
				var ch_v := float(nb["chance"])
				var ch_t := "yüksek" if ch_v >= 0.7 else ("orta" if ch_v >= 0.45 else "düşük")
				txt3 += "\n\n[b]%d)[/b] %s\nKabul ihtimali: %s" % [i2 + 1, String(nb["desc"]), ch_t]
				var dw := float(nb["house"]["dowry"])
				sub3.append({"id": "harem", "arg": "teklif|%d" % i2, "label": "%s için elçi gönder (%s)" % [String(nb["proto"]["name"]), gs.fmt_money(dw)], "disabled": gs.treasury() < dw})
			return _res(txt3, {}, sub3, false, "Soylu eş adayları")
		"teklif":
			return _res(HaremEngine.propose_noble(gs, int(parts[1]) if parts.size() > 1 else -1), _apply(gs, id, {"saygi": 0.5}))
		"davet":
			var g := HaremEngine.night_guest(gs)
			if g != "" and int(HaremEngine.data(gs)["night"]["day"]) == HaremEngine.night_day(gs):
				return _res("Bu gece için %s davet edildi, %s. Yatağınıza çekildiğinizde gece başlar." % [gs.short_name(g), h])
			var sub4: Array = []
			for wid in HaremEngine.women(gs):
				var why := HaremEngine.invite_reason(gs, wid)
				var tag := HaremEngine.rank_name(gs, wid)
				if HaremEngine.pregnancy_known(gs, wid):
					tag += ", hamile"
				sub4.append({"id": "harem", "arg": "cagir|" + String(wid), "label": "%s (%s)" % [gs.short_name(wid), tag], "disabled": why != ""})
			if sub4.is_empty():
				return _res("Haremde davet edilecek kimse yok, %s." % h)
			return _res("Bu gece kimi dairenize çağırayım, %s?" % h, {}, sub4, false, "Gece daveti")
		"cagir":
			var r: Dictionary = HaremEngine.invite(gs, parts[1])
			return _res(String(r["text"]), {})
		"nikah":
			var sub5: Array = []
			for nid in HaremEngine.nikah_candidates(gs):
				sub5.append({"id": "harem", "arg": "nikahla|" + String(nid), "label": "%s ile nikâh" % gs.short_name(nid)})
			return _res("Nikâh, bir cariyeyi eşiniz yapar, %s. Haremde dengeler değişir; kıskançlık da olur." % h, {}, sub5, false, "Nikâh")
		"nikahla":
			return _res(HaremEngine.nikah(gs, parts[1]))
		"azat":
			var sub6: Array = []
			for aid in HaremEngine.azat_candidates(gs):
				sub6.append({"id": "harem", "arg": "azatet|" + String(aid), "label": "%s azat edilsin (1.500 akçe çeyiz)" % gs.short_name(aid), "disabled": gs.treasury() < 1500.0})
			return _res("Azat edilen cariye çeyiziyle saraydan ayrılır, %s; kendi hayatını kurar." % h, {}, sub6, false, "Azat")
		"azatet":
			return _res(HaremEngine.azat(gs, parts[1]))
	return _res("...")


static func _hanedan(gs: GameWorld, id: String, arg: String) -> Dictionary:
	var parts := arg.split("|")
	var step: String = parts[0] if arg != "" else ""
	var h := hitap(gs, id)
	match step:
		"":
			var sub: Array = []
			var school: Array = []
			for cid in HaremEngine.living_children(gs):
				if int(gs.ch(cid).get("age", 0)) >= 5:
					school.append(cid)
			if not school.is_empty():
				sub.append({"id": "hanedan", "arg": "egitim", "label": "Çocukların eğitimi"})
			var sons: Array = HaremEngine.sons(gs)
			if sons.size() > 1 or (sons.size() == 1 and HaremEngine.heir(gs) == ""):
				sub.append({"id": "hanedan", "arg": "veliaht", "label": "Veliaht ilan et"})
			var last := int(gs.w["flags"].get("hekim_serbet", -999))
			sub.append({"id": "hanedan", "arg": "hekim", "label": "Hekimbaşı haremin sağlığını gözetsin (600 akçe)", "disabled": gs.get_day() - last < 30 or gs.treasury() < 600.0})
			var txt := HaremEngine.dynasty_report(gs)
			var expecting: Array = []
			for wid in HaremEngine.women(gs):
				if HaremEngine.pregnancy_known(gs, wid):
					expecting.append(gs.short_name(wid))
			if not expecting.is_empty():
				txt += "\n\nÇocuk bekleyenler: %s." % ", ".join(PackedStringArray(expecting))
			if HaremEngine.sons(gs).is_empty():
				txt += "\n\nBir şehzade için haremden dilediğinizi dairenize davet edebilirsiniz, %s. Hekimbaşı'nın bakımı da bereketi artırır." % h
			return _res(txt, {}, sub, false, "Hanedan")
		"egitim":
			var sub2: Array = []
			for cid2 in HaremEngine.living_children(gs):
				var c2: Dictionary = gs.ch(cid2)
				if int(c2.get("age", 0)) >= 5:
					var cur: String = c2.get("edu", "")
					sub2.append({"id": "hanedan", "arg": "egit|" + String(cid2), "label": "%s (%s)" % [String(c2["full"]), "eğitim seçilmedi" if cur == "" else String(HaremData.EDU[cur]["name"]).to_lower()]})
			return _res("Hangi çocuğun eğitimine karar vereceksiniz, %s?" % h, {}, sub2, false, "Eğitim")
		"egit":
			var sub3: Array = []
			for f in HaremData.EDU.keys():
				sub3.append({"id": "hanedan", "arg": "odak|%s|%s" % [parts[1], f], "label": String(HaremData.EDU[f]["name"])})
			return _res("%s hangi alanda yetişsin?" % String(gs.ch(parts[1])["full"]), {}, sub3, false, "Eğitim odağı")
		"odak":
			return _res(HaremEngine.set_edu(gs, parts[1], parts[2]))
		"veliaht":
			var sub4: Array = []
			var cur_h := HaremEngine.heir(gs)
			for sid in HaremEngine.sons(gs):
				var cs: Dictionary = gs.ch(sid)
				sub4.append({"id": "hanedan", "arg": "ilan|" + String(sid), "label": "%s (%d yaşında, annesi %s)" % [String(cs["full"]), int(cs["age"]), gs.short_name(String(cs.get("mother", "")))], "disabled": sid == cur_h})
			return _res("Veliahtı değiştirmek annelerin arasında derin kırgınlıklara yol açar, %s. Yine de karar sizindir." % h, {}, sub4, false, "Veliaht")
		"ilan":
			return _res(HaremEngine.set_heir(gs, parts[1]))
		"hekim":
			if not gs.spend(600.0, "hekim"):
				return _res("Hazinede yeterli akçe yok, %s." % h)
			gs.w["flags"]["hekim_serbet"] = gs.get_day()
			for wid2 in HaremEngine.women(gs):
				gs.adjust_mood(wid2, 3.0)
			return _res("Lokman Efendi bir ay boyunca her sabah haremi dolaşacak, %s: şifalı şerbetler, perhizler, dinlenme. Hanedanın bereketi için elden ne gelirse." % h)
	return _res("...")


static func _gece(gs: GameWorld, id: String) -> Dictionary:
	var why := HaremEngine.invite_reason(gs, id)
	if why != "":
		return _res(why)
	var r: Dictionary = HaremEngine.invite(gs, id)
	if r["ok"]:
		return _res("(Gözlerini indirir, hafifçe gülümser.) Bu akşam dairenizde olacağım, Sultanım.", _apply(gs, id, {"romantik": 1.0}))
	return _res(String(r["text"]))
