extends Node
## Harem / hanedan / yargı sistemleri için duman testi (dışa aktarılmaz).

var fails := 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok  ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func topic_ids(id: String) -> Array:
	var out: Array = []
	for t in DialogueEngine.topics(GameState, id):
		out.append(t["id"])
	return out


func goto_hour(h: int) -> void:
	var mins := (h - GameState.get_hour()) * 60 - GameState.get_minute()
	if mins <= 0:
		mins += 1440
	GameState.advance_minutes(mins)


func _ready() -> void:
	GameState.new_game("Test", 0)
	var gs := GameState
	print("== karakterler")
	ok(not gs.ch("cafer").is_empty(), "Cafer Ağa var")
	ok("harem" in topic_ids("cafer") and "hanedan" in topic_ids("cafer"), "Cafer'de harem/hanedan konuları")
	ok("yargi" in topic_ids("nurettin"), "Kadıasker'de yargı konusu")
	ok(not "yargi" in topic_ids("halil"), "Sadrazam'da yargı konusu yok")
	print("  harem başta: ", HaremEngine.women(gs), " kapasite ", HaremEngine.capacity(gs))

	print("== cariye")
	var r := DialogueEngine.choose(gs, "cafer", "harem", "")
	ok(r["sub"].size() >= 3, "harem menüsü")
	r = DialogueEngine.choose(gs, "cafer", "harem", "aday")
	ok(r["sub"].size() == 4, "3 aday + yenile")
	print("  ", String(r["text"]).substr(0, 220).replace("\n", " "))
	var before := HaremEngine.women(gs).size()
	r = DialogueEngine.choose(gs, "cafer", "harem", "al|0")
	print("  ", r["text"])
	ok(HaremEngine.women(gs).size() == before + 1, "cariye eklendi")
	var cid := ""
	for id in HaremEngine.women(gs):
		if gs.ch(id).get("harem", false):
			cid = id
	ok(cid != "", "yeni cariye id " + cid)
	var c: Dictionary = gs.ch(cid)
	ok(int(c["age"]) >= 18, "cariye yetişkin (%d)" % int(c["age"]))
	ok(c["profile"] == "cariye" and c["location"] != "", "rutin: %s @ %s" % [c["activity"], c["location"]])
	ok("gece" in topic_ids(cid), "cariyede gece daveti konusu")
	var look := CharacterLooks.for_character(c, cid)
	ok(look["outfit"].size() >= 5, "cariye görünüşü (%d parça)" % look["outfit"].size())
	# doldur
	for i in range(8):
		DialogueEngine.choose(gs, "cafer", "harem", "yenile")
		var rr := DialogueEngine.choose(gs, "cafer", "harem", "al|0")
	ok(HaremEngine.women(gs).size() <= HaremEngine.capacity(gs), "kapasite aşılmadı (%d/%d)" % [HaremEngine.women(gs).size(), HaremEngine.capacity(gs)])
	print("  ", DialogueEngine.choose(gs, "cafer", "harem", "al|0")["text"])

	print("== soylu eş")
	r = DialogueEngine.choose(gs, "cafer", "harem", "soylu")
	print("  ", String(r["text"]).substr(0, 200).replace("\n", " "))
	# kapasite dolu olabilir: bir cariyeyi azat et
	var az := HaremEngine.azat_candidates(gs)
	ok(not az.is_empty(), "azat adayı var")
	print("  ", DialogueEngine.choose(gs, "cafer", "harem", "azatet|" + String(az[0]))["text"])
	ok(not EventEngine.is_present(gs, az[0]), "azat edilen gitti")
	if az[0] == cid:
		for id2 in HaremEngine.women(gs):
			if gs.ch(id2).get("harem", false) and String(gs.ch(id2).get("rank", "")) == "cariye":
				cid = id2
		c = gs.ch(cid)
		print("  yeni test cariyesi: ", cid)
	r = DialogueEngine.choose(gs, "cafer", "harem", "soylu")
	if r["sub"].size() > 0:
		print("  ", DialogueEngine.choose(gs, "cafer", "harem", "teklif|0")["text"])
		ok(HaremEngine.data(gs)["proposals"].size() == 1, "teklif yolda")
		for d in range(5):
			gs.advance_minutes(1440)
		ok(HaremEngine.data(gs)["proposals"].is_empty(), "teklif sonuçlandı")
		for e in gs.w["log"].slice(-12):
			if String(e["kind"]) == "hanedan":
				print("  log: ", e["text"])

	print("== gece daveti")
	goto_hour(18)
	r = DialogueEngine.choose(gs, "cafer", "harem", "davet")
	ok(r["sub"].size() > 0, "davet listesi")
	r = DialogueEngine.choose(gs, "cafer", "harem", "cagir|" + cid)
	print("  ", r["text"])
	if HaremEngine.night_guest(gs) == "":
		# isteksizse romantik ilişkiyi artır ve yeniden dene
		gs.rel_add(cid, "sultan", {"romantik": 40, "sevgi": 30})
		r = DialogueEngine.choose(gs, "cafer", "harem", "cagir|" + cid)
		print("  ", r["text"])
	ok(HaremEngine.night_guest(gs) == cid, "davet kabul")
	goto_hour(20)
	ok(gs.ch(cid)["location"] == "hukumdar", "hükümdar dairesinde bekliyor")
	goto_hour(22)
	ok(HaremEngine.night_ready(gs), "gece hazır")
	var night := HaremEngine.do_night(gs)
	print("  gece: ", night)
	ok(String(gs.ch(cid)["rank"]) == "gozde", "rütbe gözde")
	gs.sleep_until_morning()

	print("== hamilelik ve doğum")
	gs.ch(cid)["pregnancy"] = {"start": gs.get_day() - 34, "due": gs.get_day() + 6, "known": false}
	gs.advance_minutes(1440)
	ok(HaremEngine.pregnancy_known(gs, cid), "hamilelik biliniyor")
	var mujde := false
	for e in EventEngine.pending(gs).duplicate():
		if e["tid"] == "hamile_mujde":
			mujde = true
			var rr2 := DialogueEngine.choose(gs, "lokman", "ev:" + String(e["uid"]), "1")
			print("  müjde: ", rr2["text"])
	ok(mujde, "hekimbaşı müjdesi")
	for d in range(7):
		gs.advance_minutes(1440)
	var kids := HaremEngine.living_children(gs)
	ok(kids.size() == 1, "çocuk doğdu")
	if kids.size() > 0:
		var kid: String = kids[0]
		var kc: Dictionary = gs.ch(kid)
		print("  ", kc["full"], " anne=", kc["mother"], " profil=", kc["profile"], " yer=", kc["location"], " ", kc["activity"])
		ok(kc["profile"] == "infant" and kc["activity"] == "uyku", "bebek sahnede değil")
		ok(gs.ch(cid)["rank"] == "kadin", "anne Kadın Efendi")
		for e in EventEngine.pending(gs).duplicate():
			if e["tid"] == "dogum":
				print("  ad: ", EventEngine.resolve(gs, e["uid"], 1))
		print("  yeni ad: ", gs.ch(kid)["full"])
		ok(not "gonul" in topic_ids(kid) and not "evlilik" in topic_ids(kid) and not "gece" in topic_ids(kid), "çocukta romantik konu yok")
		print("  çocuk konuları: ", topic_ids(kid))
		ok(not kid in gs.social_ids(), "bebek kulise katılmaz")
		ok(not JusticeEngine.can_be_accused(gs, kid, "nurettin"), "çocuk yargılanamaz")
		# büyüt
		kc["age"] = 6
		HaremEngine._update_child_profile(gs, kid)
		ok(kc["profile"] == "child_small", "6 yaş profili")
		var cl := CharacterLooks.for_character(kc, kid)
		print("  çocuk ölçek=", cl.get("scale"), " baş=", cl.get("head_scale"), " şekiller=", cl["shapes"].keys())
		ok(not cl["shapes"].has("female") and float(cl.get("scale", 1.0)) < 0.7, "çocuk görünüşü")
		var fig := HumanFigure.new()
		add_child(fig)
		fig.build(cl)
		ok(fig.scale.x < 0.7, "figür küçültüldü")
		fig.queue_free()
		r = DialogueEngine.choose(gs, "cafer", "hanedan", "")
		print("  hanedan: ", String(r["text"]).replace("\n", " | "))
		print("  ", DialogueEngine.choose(gs, "cafer", "hanedan", "odak|%s|askeri" % kid)["text"])
		for t in DialogueEngine.topics(gs, kid):
			var rt := DialogueEngine.choose(gs, kid, t["id"], "")
			if rt["sub"].is_empty():
				print("  çocuk[", t["id"], "]: ", rt["text"])
		ok(HaremEngine.heir(gs) == kid or gs.ch(kid)["gender"] == "f", "ilk oğul veliaht")

	print("== yargı")
	var j := JusticeEngine.judge(gs)
	ok(j == "nurettin", "yargıç Kadıasker")
	r = DialogueEngine.choose(gs, j, "yargi", "")
	print("  ", String(r["text"]).replace("\n", " | "))
	r = DialogueEngine.choose(gs, j, "yargi", "ac")
	ok(r["sub"].size() > 5, "sanık listesi (%d)" % r["sub"].size())
	r = DialogueEngine.choose(gs, j, "yargi", "ceza|yusuf|zimmet|idam")
	print("  zimmete idam: ", r["text"])
	ok(r["sub_title"] == "Kadı reddetti", "zimmete idam reddedildi")
	r = DialogueEngine.choose(gs, j, "yargi", "ceza|yusuf|zimmet|zindan")
	ok(r["sub_title"] == "Kadı reddetti", "delilsiz zindan reddedildi")
	# Rıza soruşturması
	DialogueEngine._riza_report(gs, "yusuf")
	ok(JusticeEngine.evidence(gs, "yusuf", "zimmet") >= 40.0, "Rıza zimmet delili buldu")
	JusticeEngine.add_evidence(gs, "yusuf", "zimmet", 20.0, "Kemal Bey'in denetimi")
	r = DialogueEngine.choose(gs, j, "yargi", "ceza|yusuf|zimmet|zindan")
	print("  ", r["text"])
	ok(r["sub_title"] == "Fetva", "zindan fetvası")
	r = DialogueEngine.choose(gs, j, "yargi", "infaz|yusuf|zimmet|zindan|0")
	print("  ", r["text"])
	ok(not EventEngine.is_present(gs, "yusuf") and "yusuf" in JusticeEngine.data(gs)["prison"], "Yusuf zindanda")
	r = DialogueEngine.choose(gs, j, "yargi", "af")
	ok(r["sub"].size() == 1, "af listesi")
	print("  ", DialogueEngine.choose(gs, j, "yargi", "birak|yusuf")["text"])
	ok(EventEngine.is_present(gs, "yusuf"), "Yusuf affedildi")
	# idam
	JusticeEngine.add_evidence(gs, "edric", "casusluk", 85.0, "Mühürlü mektuplar ele geçti")
	r = DialogueEngine.choose(gs, j, "yargi", "ceza|edric|casusluk|idam")
	print("  ", r["text"])
	if r["sub_title"] == "Fetva":
		print("  ", DialogueEngine.choose(gs, j, "yargi", "infaz|edric|casusluk|idam|0")["text"])
		ok(not gs.ch("edric")["alive"], "idam uygulandı")
	# baskı
	JusticeEngine.add_evidence(gs, "sumbul", "hirsizlik", 20.0, "Kayıp bilezik")
	r = DialogueEngine.choose(gs, j, "yargi", "ceza|sumbul|hirsizlik|surgun")
	ok(r["sub_title"] == "Kadı reddetti", "zayıf delille sürgün reddi")
	r = DialogueEngine.choose(gs, j, "yargi", "baski|sumbul|hirsizlik|surgun")
	print("  baskı: ", r["text"])

	print("== zaman (120 gün)")
	var t0 := Time.get_ticks_msec()
	for d in range(120):
		gs.advance_minutes(1440)
		for ev2 in EventEngine.pending(gs).duplicate():
			if gs.rng.randf() < 0.5:
				var o2 := EventEngine.options_for(gs, ev2)
				var pick := gs.rng.randi() % o2.size()
				if o2[pick]["available"] and o2[pick]["affordable"]:
					EventEngine.resolve(gs, ev2["uid"], pick)
	print("  120 gün ", Time.get_ticks_msec() - t0, " ms; hazine=", int(gs.treasury()), " harem gideri=", Economy.expenses(gs)["harem"])
	var kinds := {}
	for e in gs.w["events"]["history"]:
		kinds[e.get("tid", "?")] = true
	print("  görülen olaylar: ", kinds.keys().filter(func(k): return String(k) in ["harem_kavga", "rusvet_ihbar", "zehir_supheli", "harem_hirsizlik", "dugun", "hamile_mujde", "dogum"]))

	print("== kayıt / göç")
	ok(SaveSystem.save_game("haremtest"), "kaydedildi")
	var nchars: int = gs.w["characters"].size()
	ok(SaveSystem.load_game("haremtest"), "yüklendi")
	ok(GameState.w["characters"].size() == nchars, "karakter sayısı korundu (%d)" % nchars)
	var old: Dictionary = GameState.w.duplicate(true)
	old["characters"].erase("cafer")
	old.erase("harem")
	old.erase("crimes")
	var mig := SaveSystem._migrate(old, 1)
	ok(mig["characters"].has("cafer") and mig.has("harem") and mig.has("crimes"), "eski kayıt göçü")
	SaveSystem.delete_slot("haremtest")

	print("== tüm diyaloglar")
	var n := 0
	for id in GameState.npc_ids():
		DialogueEngine.greeting(GameState, id)
		for t in DialogueEngine.topics(GameState, id):
			var rr3 := DialogueEngine.choose(GameState, id, t["id"], "")
			n += 1
			for s0 in rr3["sub"].slice(0, 2):
				if not s0.get("disabled", false) and not String(s0.get("arg", "")).begins_with("infaz") and not String(s0.get("arg", "")).begins_with("azatet"):
					DialogueEngine.choose(GameState, id, s0["id"], s0.get("arg", ""))
	print("  ", n, " konu denendi")
	print("SONUÇ: ", "BAŞARILI" if fails == 0 else "%d HATA" % fails)
	get_tree().quit()
