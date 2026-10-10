class_name ProfilePanel
extends BasePanel
## Karakter profili: kimlik, hükümdara bakışı (10 ilişki boyutu), kişilik, beceriler,
## öğrenilen geçmiş, hedefler, hatırladıkları ve diğerleriyle ilişkileri.

var game: Node
var char_id := ""


func open(id: String, g: Node) -> void:
	char_id = id
	game = g
	var c: Dictionary = GameState.ch(id)
	setup_frame(GameState.full_name(id), 0.94, 0.92)
	var top := UI.hbox(16)
	body.add_child(top)
	top.add_child(UI.portrait(id, 96))
	var info := UI.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	var post: String = GameState.post_of(id)
	var post_txt: String = CharactersData.POSTS[post]["name"] if post != "" else "Makamı yok"
	info.add_child(UI.label("%d yaşında  •  %s" % [int(c["age"]), post_txt], 20, UI.TEXT))
	var where := "Saray dışında" if c.get("location", "") == "disari" else PalaceLayout.room_name(c.get("location", ""))
	if c.get("gone", false):
		where = "Zindanda" if c.get("prison", false) else ("Sürgünde" if c.get("exile", false) else "Saraydan ayrıldı")
	elif not NPCManager.visible_age(c):
		where = "Dadısının yanında, %s" % PalaceLayout.room_name(String(c.get("home", "harem")))
	info.add_child(UI.label("%s — %s  •  Ruh hâli: %s" % [where, GameState.activity_text(id), GameState.mood_label(float(c.get("mood", 0)))], 19, UI.MUTED))
	var fam := _family_line(id, c)
	if fam != "":
		info.add_child(UI.wrap_label(fam, 19, Color("e8b8c8")))
	info.add_child(UI.wrap_label(String(c.get("bio", "")), 19, UI.CREAM))
	var btns := UI.vbox(8)
	top.add_child(btns)
	if not c.get("gone", false) and c.get("location", "") != "disari" and NPCManager.visible_age(c):
		var go := UI.button("Yanına Git", _go, 52, true)
		go.custom_minimum_size.x = 190
		btns.add_child(go)
		var call_b := UI.button("Huzura Çağır", _summon, 52)
		call_b.custom_minimum_size.x = 190
		btns.add_child(call_b)
	var sc := UI.scroll()
	body.add_child(sc)
	var cols := UI.hbox(20)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(cols)
	var left := UI.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	# Hükümdara bakışı
	var op: float = GameState.opinion(id, GameState.PLAYER)
	left.add_child(UI.title("Size Bakışı: %s (%d)" % [GameState.opinion_label(op), int(op)], 26))
	var r: Dictionary = GameState.rel(id, GameState.PLAYER)
	for d in GameState.REL_DIMS:
		if d == "romantik" and not c.get("romanceable", false):
			continue
		var col := UI.GOLD
		if d in ["korku", "kiskanclik", "rekabet"]:
			col = UI.RED
		elif d == "romantik":
			col = Color("d76b8a")
		left.add_child(UI.stat_row(GameState.REL_NAMES[d], float(r.get(d, 0)), col))
	left.add_child(UI.sep_line())
	left.add_child(UI.title("Kişilik", 26))
	var t: Dictionary = c.get("traits", {})
	for k in CharactersData.TRAIT_NAMES.keys():
		left.add_child(UI.stat_row(CharactersData.TRAIT_NAMES[k], float(t.get(k, 50)), UI.EMERALD2))
	left.add_child(UI.sep_line())
	left.add_child(UI.title("Beceriler", 26))
	var s: Dictionary = c.get("skills", {})
	for k2 in CharactersData.SKILL_NAMES.keys():
		left.add_child(UI.stat_row(CharactersData.SKILL_NAMES[k2], float(s.get(k2, 30)), UI.BLUE))
	# Bilgiler
	right.add_child(UI.title("Bildikleriniz", 26))
	var lore: Array = c.get("lore", [])
	var unl: Array = GameState.lore_unlocked(id)
	if unl.is_empty():
		right.add_child(UI.wrap_label("Henüz bir şey bilmiyorsunuz. 'Kişisel konular' üzerine konuşarak ve güvenini kazanarak geçmişini öğrenebilirsiniz.", 19, UI.MUTED))
	for i in unl:
		if int(i) < lore.size():
			var card := UI.card()
			card.add_child(UI.wrap_label("• " + String(lore[int(i)]["t"]), 19, UI.CREAM))
			right.add_child(card)
	if unl.size() < lore.size():
		right.add_child(UI.label("(%d sır daha var; güven arttıkça açılır)" % (lore.size() - unl.size()), 17, UI.MUTED))
	right.add_child(UI.sep_line())
	right.add_child(UI.title("Hedefler ve Korkular", 26))
	if GameState.flag("hedef_bilinen:" + id):
		for gtxt in c.get("goals", []):
			right.add_child(UI.wrap_label("Hedef: " + String(gtxt), 19, UI.GREEN))
		for ftxt in c.get("fears", []):
			right.add_child(UI.wrap_label("Korku: " + String(ftxt), 19, Color("e0a080")))
	else:
		right.add_child(UI.wrap_label("Tüm geçmişini öğrendikten sonra kişisel sohbetlerde hedeflerini ve korkularını paylaşır.", 19, UI.MUTED))
	right.add_child(UI.sep_line())
	right.add_child(UI.title("Sizinle İlgili Hatırladıkları", 26))
	var mems: Array = GameState.memories_about(id, GameState.PLAYER)
	mems.sort_custom(func(a, b): return float(a["strength"]) * absf(float(a["emotion"])) > float(b["strength"]) * absf(float(b["emotion"])))
	if mems.is_empty():
		right.add_child(UI.label("Henüz önemli bir anı yok.", 19, UI.MUTED))
	var src_names := {"dogrudan": "yaşadı", "gozlem": "gördü", "soylenti": "duydu"}
	for i2 in range(mini(mems.size(), 8)):
		var m: Dictionary = mems[i2]
		var colm := UI.GREEN if float(m["emotion"]) > 0 else Color("e07a6a")
		var txt := "%s  [%s, %d. gün%s]" % [m["text"], src_names.get(m["source"], m["source"]), int(m["day"]) + 1, "" if m.get("truth", true) else ", gerçek değil"]
		right.add_child(UI.wrap_label(txt, 18, colm))
	right.add_child(UI.sep_line())
	right.add_child(UI.title("Saraydaki İlişkileri", 26))
	var others: Array = []
	for oid in GameState.npc_ids():
		if oid != id:
			others.append([oid, GameState.opinion(id, oid), GameState.rel_val(id, oid, "rekabet") + GameState.rel_val(id, oid, "kiskanclik")])
	others.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	var shown := 0
	for o in others:
		if shown >= 3:
			break
		right.add_child(UI.label("Yakın: %s (%s)" % [GameState.short_name(o[0]), GameState.opinion_label(float(o[1]))], 19, UI.TEXT))
		shown += 1
	others.sort_custom(func(a, b): return float(a[2]) > float(b[2]))
	for o2 in others:
		if float(o2[2]) < 50.0:
			break
		right.add_child(UI.label("Gergin: %s" % GameState.short_name(o2[0]), 19, Color("e0a080")))


func _family_line(id: String, c: Dictionary) -> String:
	var bits: Array = []
	if HaremEngine.is_harem_woman(GameState, id):
		var rk := HaremEngine.rank_name(GameState, id)
		if rk != "":
			bits.append(rk)
		if HaremEngine.pregnancy_known(GameState, id):
			bits.append("hamile")
		var tal: String = c.get("talent", "")
		for t in HaremData.TALENTS:
			if t[0] == tal:
				bits.append("yeteneği: " + String(t[1]))
	if String(c.get("role", "")) == "child":
		var m: String = c.get("mother", "")
		if m != "":
			bits.append("annesi " + GameState.short_name(m))
		if id == HaremEngine.heir(GameState):
			bits.append("veliaht")
		var edu: String = c.get("edu", "")
		if edu != "":
			bits.append("eğitimi: " + String(HaremData.EDU[edu]["name"]).to_lower())
	var kids := HaremEngine.children_of(GameState, id)
	if not kids.is_empty():
		var names: Array = []
		for k in kids:
			names.append(GameState.short_name(k))
		bits.append("çocukları: " + ", ".join(PackedStringArray(names)))
	return "  •  ".join(PackedStringArray(bits))


func _go() -> void:
	if game:
		game.walk_to_char(char_id)
	close_panel()


func _summon() -> void:
	if game:
		game.summon(char_id)
	close_panel()
