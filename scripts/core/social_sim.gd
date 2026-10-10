class_name SocialSim
extends RefCounted
## NPC'ler arası saatlik sosyal simülasyon (Utility AI).
## Aynı mekândaki karakterler sohbet eder, tartışır, söylenti yayar, ittifak kurar, barışır.
## Oyuncu görmese de saray yaşamı sürer.

const P := "sultan"


static func hourly(gs: GameWorld) -> void:
	var hour: int = gs.get_hour()
	if hour < 7 or hour > 22:
		return
	var rooms := {}
	for id in gs.social_ids():
		var c: Dictionary = gs.ch(id)
		if c["activity"] in ["uyku", "disarida"]:
			continue
		var loc: String = c["location"]
		if not rooms.has(loc):
			rooms[loc] = []
		rooms[loc].append(id)
	var rng: RandomNumberGenerator = gs.rng
	for room in rooms.keys():
		var ids: Array = rooms[room]
		if ids.size() < 2:
			continue
		var tries := mini(ids.size() / 2 + 1, 3)
		for t in range(tries):
			var a: String = ids[rng.randi() % ids.size()]
			var b: String = ids[rng.randi() % ids.size()]
			if a == b:
				continue
			var chance := 0.16 + (gs.trait_of(a, "sosyal") + gs.trait_of(b, "sosyal")) / 420.0
			if rng.randf() > chance:
				continue
			interact(gs, a, b, String(room))


static func _juicy_memory(gs: GameWorld, a: String, b: String) -> Dictionary:
	var best := {}
	var best_v := 0.0
	for m in gs.ch(a).get("memories", []):
		if String(m.get("key", "")) == "":
			continue
		if b in m["actors"]:
			continue
		if gs.knows_key(b, m["key"]):
			continue
		if gs.get_day() - int(m["day"]) > 20:
			continue
		var v := absf(float(m["emotion"])) * float(m["strength"])
		if v > best_v:
			best_v = v
			best = m
	return best


static func interact(gs: GameWorld, a: String, b: String, room: String) -> void:
	var rng: RandomNumberGenerator = gs.rng
	var ra: Dictionary = gs.rel(a, b)
	var juicy := _juicy_memory(gs, a, b)
	var argued: bool = gs.has_memory(a, "tartisma", b, true)
	var u := {}
	u["sohbet"] = 0.45 + (float(ra["sevgi"]) - 40.0) / 100.0 + float(ra["arkadaslik"]) / 200.0
	u["tartisma"] = (float(ra["rekabet"]) + float(ra["kiskanclik"])) / 140.0 + (50.0 - gs.trait_of(a, "sabir")) / 120.0 - 0.2 + (0.2 if argued else 0.0)
	u["soylenti"] = (gs.trait_of(a, "sosyal") / 160.0 + (45.0 - gs.trait_of(a, "durustluk")) / 200.0 + 0.1) if not juicy.is_empty() else -1.0
	u["ittifak"] = (float(ra["siyasi_uyum"]) - 58.0) / 50.0 + (gs.trait_of(a, "hirs") - 55.0) / 110.0
	u["ozur"] = (0.7 + (gs.trait_of(a, "merhamet") - 50.0) / 100.0) if argued else -1.0
	u["gonul"] = (float(ra["romantik"]) - 30.0) / 50.0 if float(ra["romantik"]) >= 30.0 else -1.0
	var best := "sohbet"
	var best_v := -99.0
	for k in u.keys():
		var v := float(u[k]) + rng.randf() * 0.3
		if v > best_v:
			best_v = v
			best = k
	var an: String = gs.short_name(a)
	var bn: String = gs.short_name(b)
	var rname: String = PalaceLayout.room_short(room)
	match best:
		"sohbet":
			var before := float(ra["arkadaslik"])
			gs.rel_add(a, b, {"arkadaslik": 1.6, "sevgi": 0.8}, false)
			gs.rel_add(b, a, {"arkadaslik": 1.3, "sevgi": 0.6}, false)
			gs.ch(a)["needs"]["sosyal"] = minf(100.0, float(gs.ch(a)["needs"]["sosyal"]) + 10.0)
			var dk := "dost:" + ("-".join(PackedStringArray([a, b] if a < b else [b, a])))
			if before < 60.0 and float(gs.rel(a, b)["arkadaslik"]) >= 60.0 and not gs.flag(dk):
				gs.set_flag(dk, true)
				gs.add_npc_event("%s ile %s arasında sıkı bir dostluk filizleniyor." % [an, bn], [a, b], room, "dostluk")
		"tartisma":
			gs.rel_add(a, b, {"sevgi": -3.0, "rekabet": 3.0}, false)
			gs.rel_add(b, a, {"sevgi": -2.5, "rekabet": 2.0}, false)
			var key := "tartisma:%s:%s:%d" % [a, b, gs.get_day()]
			gs.add_memory(a, "tartisma", [b], -18.0, "%s tartıştım." % TR.ins(bn), "dogrudan", true, {"key": key})
			gs.add_memory(b, "tartisma", [a], -18.0, "%s benimle tartıştı." % an, "dogrudan", true, {"key": key})
			for wid in gs.witnesses(room, [a, b]):
				gs.add_memory(wid, "tartisma_gozlem", [a, b], -4.0, "%s ile %s tartıştı." % [an, bn], "gozlem", true, {"key": key})
			gs.add_npc_event("%s ile %s sert bir tartışma yaşadı (%s)." % [an, bn, rname], [a, b], room, "tartisma")
		"soylenti":
			var m: Dictionary = juicy
			var truth: bool = m.get("truth", true)
			var text: String = m["text"]
			if gs.trait_of(a, "durustluk") < 40.0 and rng.randf() < 0.35:
				truth = false
				text = "Söylentiye göre " + text.substr(0, 1).to_lower() + text.substr(1)
			var emo := float(m["emotion"]) * 0.5
			gs.add_memory(b, String(m["type"]), m["actors"], emo, text, "soylenti", truth, {"key": m["key"], "from": a})
			if P in m["actors"]:
				# hükümdar hakkındaki söylenti, dinleyenin hükümdara bakışını etkiler
				var d := clampf(emo * 0.06, -3.0, 3.0)
				gs.rel_add(b, P, {"sevgi": d, "saygi": d * 0.6}, false)
			gs.rel_add(b, a, {"guven": -0.5 if not truth else 0.5}, false)
			gs.add_npc_event("%s, %s kulağına bir şeyler fısıldadı (%s)." % [an, TR.gen(bn), rname], [a, b], room, "soylenti")
		"ittifak":
			gs.rel_add(a, b, {"siyasi_uyum": 3.0, "guven": 1.5}, false)
			gs.rel_add(b, a, {"siyasi_uyum": 2.5, "guven": 1.0}, false)
			var fk := "ittifak:%s" % "-".join(PackedStringArray([a, b] if a < b else [b, a]))
			if not gs.flag(fk) and float(gs.rel(a, b)["siyasi_uyum"]) > 72.0 and float(gs.rel(b, a)["siyasi_uyum"]) > 65.0:
				gs.set_flag(fk, true)
				gs.add_npc_event("%s ile %s arasında bir ittifak kuruluyor gibi." % [an, bn], [a, b], room, "ittifak")
		"ozur":
			gs.resolve_memories(a, "tartisma", b)
			gs.resolve_memories(b, "tartisma", a)
			gs.rel_add(a, b, {"sevgi": 4.0, "rekabet": -2.0}, false)
			gs.rel_add(b, a, {"sevgi": 4.0, "rekabet": -2.0}, false)
			gs.add_npc_event("%s, %s özür diledi; aralarındaki gerginlik yumuşadı." % [an, TR.abl(bn)], [a, b], room, "barisma")
		"gonul":
			gs.rel_add(a, b, {"romantik": 2.0, "sevgi": 1.0}, false)
			if float(gs.rel(b, a)["sevgi"]) > 55.0:
				gs.rel_add(b, a, {"romantik": 1.5}, false)
			if float(gs.rel(a, b)["romantik"]) > 75.0 and float(gs.rel(b, a)["romantik"]) > 60.0 and not gs.flag("nisan:%s:%s" % [a, b]):
				gs.set_flag("nisan:%s:%s" % [a, b], true)
				gs.add_npc_event("%s ile %s birbirlerine gönül verdiği artık herkesin dilinde." % [an, TR.gen(bn)], [a, b], room, "gonul")
