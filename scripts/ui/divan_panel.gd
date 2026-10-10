class_name DivanPanel
extends BasePanel
## Divan-ı Hümayun: gündem kararları, bütçe ve vergi, eyalet yatırımları ve makam atamaları.

var game: Node
var tab := "gundem"
var content: VBoxContainer
var result_box: VBoxContainer
var _tab_btns := {}
var _expand_post := ""
var _expand_prov := ""
const TABS := [["gundem", "Gündem"], ["butce", "Bütçe ve Vergi"], ["eyalet", "Eyaletler"], ["makam", "Makamlar"]]


func open(g: Node, start_tab: String = "gundem") -> void:
	game = g
	tab = start_tab
	setup_frame("Divan-ı Hümayun", 0.96, 0.94)
	var tabs := UI.hbox(8)
	body.add_child(tabs)
	for t in TABS:
		var tid: String = t[0]
		var b := UI.button(t[1], func(): _set_tab(tid), 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		_tab_btns[tid] = b
	result_box = UI.vbox(4)
	body.add_child(result_box)
	var sc := UI.scroll()
	body.add_child(sc)
	content = UI.vbox(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	_build()


func _set_tab(t: String) -> void:
	tab = t
	UI.clear(result_box)
	_build()


func _show_result(text: String) -> void:
	UI.clear(result_box)
	if text == "":
		return
	var card := UI.card(Color(UI.EMERALD, 0.35), UI.GOLD)
	card.add_child(UI.wrap_label(text, 20, UI.CREAM))
	result_box.add_child(card)


func _build() -> void:
	for k in _tab_btns.keys():
		var b: Button = _tab_btns[k]
		if k == tab:
			b.add_theme_stylebox_override("normal", UI.sb(UI.EMERALD, UI.GOLD2, 2, 10, 14))
		else:
			b.remove_theme_stylebox_override("normal")
	UI.clear(content)
	match tab:
		"gundem":
			_build_gundem()
		"butce":
			_build_butce()
		"eyalet":
			_build_eyalet()
		"makam":
			_build_makam()


# ------------------------------------------------------------ gündem

func _build_gundem() -> void:
	var present: Array = []
	for pair in DivanEngine.council(GameState):
		var id: String = pair[1]
		var loc: String = GameState.ch(id)["location"]
		present.append("%s (%s)" % [GameState.short_name(id), "burada" if loc == "divan" else ("saray dışında" if loc == "disari" else PalaceLayout.room_short(loc))])
	content.add_child(UI.wrap_label("Divan üyeleri: " + ", ".join(PackedStringArray(present)), 18, UI.MUTED))
	var agenda: Array = DivanEngine.agenda(GameState)
	if agenda.is_empty():
		content.add_child(UI.wrap_label("Bugün Divan'ın önünde bekleyen bir mesele yok. Gündem her hafta ve acil durumlarda yenilenir. Bütçe, eyaletler ve makamlarla ilgili kararları diğer sekmelerden verebilirsiniz.", 20, UI.TEXT))
		return
	for item in agenda:
		var card := UI.card()
		var v := UI.vbox(8)
		card.add_child(v)
		v.add_child(UI.title(String(item["title"]), 28))
		v.add_child(UI.wrap_label(String(item["text"]), 20, UI.CREAM))
		for o in DivanEngine.options_for(GameState, item):
			var uid: String = item["uid"]
			var idx: int = o["idx"]
			var txt: String = o["text"]
			var b := UI.button(txt, func(): _decide(uid, idx), 54)
			b.disabled = not o["affordable"]
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(b)
			var views: Array = []
			for vw in o["views"]:
				var col := "#7fd18a" if vw["label"] == "Destekliyor" else ("#e07a6a" if vw["label"] == "Karşı" else "#c8c0a8")
				views.append("[color=%s]%s: %s[/color]" % [col, GameState.short_name(vw["who"]), vw["label"]])
			var vl := UI.rich("   " + "  •  ".join(PackedStringArray(views)), 17)
			v.add_child(vl)
		content.add_child(card)


func _decide(uid: String, idx: int) -> void:
	var res := DivanEngine.decide(GameState, uid, idx)
	_build()
	_show_result(res)


# ------------------------------------------------------------ bütçe

func _build_butce() -> void:
	var st: Dictionary = GameState.w["state"]
	var b: Dictionary = Economy.budget(GameState)
	var top := UI.card()
	var tv := UI.vbox(6)
	top.add_child(tv)
	tv.add_child(UI.title("Aylık Tahmin", 28))
	tv.add_child(UI.label("Hazine: %s" % GameState.fmt_money(GameState.treasury()), 22, UI.GOLD2))
	tv.add_child(UI.label("Tahmini aylık vergi geliri: %s" % GameState.fmt_money(float(b["gelir"])), 20))
	var ex: Dictionary = b["giderler"]
	tv.add_child(UI.label("Giderler: saray %s • ordu %s • maaşlar %s%s" % [GameState.fmt_money(float(ex["saray"])), GameState.fmt_money(float(ex["ordu"])), GameState.fmt_money(float(ex["maaslar"])), ((" • bakım " + GameState.fmt_money(float(ex["bakim"]))) if float(ex["bakim"]) > 0 else "") + ((" • harem " + GameState.fmt_money(float(ex.get("harem", 0.0)))) if float(ex.get("harem", 0.0)) > 0 else "")], 19, UI.MUTED))
	var net := float(b["net"])
	tv.add_child(UI.label("Net: %s / ay" % GameState.fmt_money(net), 22, UI.GREEN if net >= 0 else UI.RED))
	tv.add_child(UI.label("Tahıl fiyat endeksi: %.2f  •  Halk huzuru: %%%d" % [float(st["food_price"]), int(GameState.people_huzur())], 19, UI.MUTED))
	content.add_child(top)
	# vergi
	content.add_child(UI.title("Vergi Oranı", 26))
	content.add_child(UI.wrap_label("Yüksek vergi hazineyi doldurur ama refahı, istihdamı ve huzuru zincirleme düşürür; kadıasker ve halk hoşnutsuz olur. Düşük vergi huzur getirir, hazineyi zorlar.", 18, UI.MUTED))
	var row := UI.hbox(8)
	content.add_child(row)
	for i in range(ProvincesData.TAX_LEVELS.size()):
		var lv: Dictionary = ProvincesData.TAX_LEVELS[i]
		var ii := i
		var bt := UI.button("%s\n%%%d" % [lv["name"], int(float(lv["rate"]) * 100)], func(): _set_tax(ii), 64, i == int(st["tax_level"]))
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bt)
	# saray
	content.add_child(UI.title("Saray Harcamaları", 26))
	var row2 := UI.hbox(8)
	content.add_child(row2)
	for j in range(3):
		var jj := j
		var bt2 := UI.button("%s (%s)" % [ProvincesData.SPEND_LEVELS[j], GameState.fmt_money(Economy.PALACE_COST[j])], func(): _set_palace(jj), 56, j == int(st["palace_level"]))
		bt2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(bt2)
	content.add_child(UI.wrap_label("Görkemli saray prestiji ve Valide Sultan'ın memnuniyetini artırır; mütevazı saray hazineyi rahatlatır.", 18, UI.MUTED))
	# ordu
	content.add_child(UI.title("Ordu Harcamaları", 26))
	var row3 := UI.hbox(8)
	content.add_child(row3)
	for k in range(3):
		var kk := k
		var bt3 := UI.button(ProvincesData.ARMY_LEVELS[k], func(): _set_army(kk), 56, k == int(st["army_level"]))
		bt3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row3.add_child(bt3)
	content.add_child(UI.wrap_label("Ordu bütçesi eyaletlerin güvenliğini ve vergi toplama verimini etkiler; Serdar'ın memnuniyeti de buna bağlıdır.", 18, UI.MUTED))


func _set_tax(i: int) -> void:
	DivanEngine.set_tax(GameState, i)
	_build()
	_show_result("Vergi oranı değiştirildi. Etkileri ay sonundaki hesapta görülecek.")


func _set_palace(i: int) -> void:
	DivanEngine.set_palace(GameState, i)
	_build()


func _set_army(i: int) -> void:
	DivanEngine.set_army(GameState, i)
	_build()


# ------------------------------------------------------------ eyaletler

func _build_eyalet() -> void:
	var g := UI.grid(2, 12, 12)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(g)
	for p in GameState.w["provinces"]:
		var pid: String = p["id"]
		var card := UI.card()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(4)
		card.add_child(v)
		var h := UI.hbox(8)
		h.add_child(UI.title(String(p["name"]), 26))
		var inc := Economy.province_tax(GameState, p)
		var ex_txt := ""
		if int(p.get("exempt_until", -1)) > GameState.get_day():
			ex_txt = " (vergi muaf)"
		h.add_child(UI.label("%d bin nüfus • %s/ay%s" % [int(p["pop"]), GameState.fmt_money(inc), ex_txt], 17, UI.MUTED))
		v.add_child(h)
		v.add_child(UI.wrap_label("%s  Vali: %s." % [p["desc"], p["governor"]], 16, UI.MUTED))
		v.add_child(UI.stat_row("Huzur", float(p["huzur"]), _col(float(p["huzur"]))))
		v.add_child(UI.stat_row("Refah", float(p["refah"]), UI.GOLD))
		v.add_child(UI.stat_row("Güvenlik", float(p["guvenlik"]), UI.BLUE))
		v.add_child(UI.stat_row("Sadakat", float(p["sadakat"]), UI.EMERALD2))
		v.add_child(UI.label("Tahıl: %.1f ay  •  İşsizlik: %%%d  •  Altyapı %d  •  Sağlık %d%s" % [float(p["gida"]), int(p["issizlik"]), int(p["altyapi"]), int(p["saglik"]), "  •  KURAKLIK" if int(p.get("drought", 0)) > 0 else ""], 16, UI.TEXT))
		for proj in GameState.w["projects"]:
			if proj["prov"] == pid:
				var left := int(proj["done_month"]) - GameState.cal_month_index()
				v.add_child(UI.label("Yapım: %s (%d ay kaldı)" % [ProvincesData.PROJECTS[proj["type"]]["name"], maxi(left, 0)], 16, UI.GOLD2))
		var acts := UI.hbox(6)
		v.add_child(acts)
		var aid_cost := int(float(p["pop"]) * 60.0 / 100.0) * 100
		var b1 := UI.button("Tahıl Gönder\n%s" % GameState.fmt_money(aid_cost), func(): _aid(pid, aid_cost), 58)
		b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b1.disabled = GameState.treasury() < aid_cost
		b1.add_theme_font_size_override("font_size", 17)
		acts.add_child(b1)
		var b2 := UI.button("Yatırımlar", func(): _toggle_prov(pid), 58)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.add_theme_font_size_override("font_size", 17)
		acts.add_child(b2)
		if _expand_prov == pid:
			for type in ProvincesData.PROJECTS.keys():
				var def: Dictionary = ProvincesData.PROJECTS[type]
				if def.get("coastal", false) and not p.get("coastal", false):
					continue
				var ty: String = type
				var pb := UI.button("%s — %s, %d ay\n%s" % [def["name"], GameState.fmt_money(float(def["cost"])), int(def["months"]), def["desc"]], func(): _project(pid, ty), 64)
				pb.add_theme_font_size_override("font_size", 16)
				pb.disabled = GameState.treasury() < float(def["cost"])
				v.add_child(pb)
		g.add_child(card)


func _col(v: float) -> Color:
	if v < 30.0:
		return UI.RED
	if v < 50.0:
		return Color("d8a24e")
	return UI.GREEN


func _toggle_prov(pid: String) -> void:
	_expand_prov = "" if _expand_prov == pid else pid
	_build()


func _aid(pid: String, cost: int) -> void:
	if not GameState.spend(float(cost), "yardim"):
		return
	var p: Dictionary = GameState.province(pid)
	p["gida"] = clampf(float(p["gida"]) + 2.0, 0.0, 12.0)
	p["huzur"] = clampf(float(p["huzur"]) + 4.0, 0.0, 100.0)
	GameState.state_add("people_rep", 1.0)
	GameState.add_log("%s eyaletine hazineden tahıl gönderildi." % p["name"], "devlet", 1)
	_build()
	_show_result("%s ambarlarına iki aylık tahıl gönderildi. Halk minnettar." % p["name"])


func _project(pid: String, type: String) -> void:
	if Economy.start_project(GameState, pid, type):
		GameState.player_skill_add("yonetim", 0.5)
		_expand_prov = ""
		_build()
		_show_result("Yatırım başladı. Tamamlandığında eyaletin göstergeleri kalıcı olarak iyileşecek.")


# ------------------------------------------------------------ makamlar

func _build_makam() -> void:
	content.add_child(UI.wrap_label("Yetkin ama sadakatsiz bir devlet adamı işleri iyi yürütür ama siyasi risk taşır; sadık ama yetersiz biri devleti zayıflatır. Görevden alınanlar bunu unutmaz.", 18, UI.MUTED))
	for post in CharactersData.POSTS.keys():
		var pdef: Dictionary = CharactersData.POSTS[post]
		var holder: String = GameState.post_holder(post)
		var card := UI.card()
		var v := UI.vbox(6)
		card.add_child(v)
		var h := UI.hbox(12)
		v.add_child(h)
		if holder != "" and not GameState.ch(holder).is_empty():
			h.add_child(UI.portrait(holder, 60))
		var info := UI.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		info.add_child(UI.label(String(pdef["name"]), 22, UI.GOLD2, UI.font_semi))
		if holder == "" or GameState.ch(holder).get("gone", false):
			info.add_child(UI.label("Makam boş!", 20, UI.RED))
		else:
			var sk: float = GameState.skill_of(holder, pdef["skill"])
			info.add_child(UI.label("%s  •  %s: %d  •  Sadakat: %d  •  Size bakışı: %s" % [GameState.short_name(holder), CharactersData.SKILL_NAMES[pdef["skill"]], int(sk), int(GameState.trait_of(holder, "sadakat")), GameState.opinion_label(GameState.opinion(holder, GameState.PLAYER))], 18, UI.TEXT))
		var postk: String = post
		var cb := UI.button("Atama Yap" if holder == "" else "Değiştir", func(): _toggle_post(postk), 52)
		cb.custom_minimum_size.x = 160
		h.add_child(cb)
		if _expand_post == post:
			var cands := DivanEngine.candidates(GameState, post)
			if cands.is_empty():
				v.add_child(UI.label("Uygun aday yok.", 18, UI.MUTED))
			for cnd in cands:
				var cid: String = cnd["id"]
				var cur: String = cnd["current"]
				var lbl := "%s — %s %d, size bakışı %s%s" % [GameState.short_name(cid), CharactersData.SKILL_NAMES[pdef["skill"]], int(cnd["skill"]), GameState.opinion_label(float(cnd["opinion"])), (" (şu an: %s)" % CharactersData.POSTS[cur]["name"]) if cur != "" else ""]
				var ab := UI.button(lbl, func(): _appoint(postk, cid), 50)
				ab.add_theme_font_size_override("font_size", 17)
				v.add_child(ab)
		content.add_child(card)


func _toggle_post(post: String) -> void:
	_expand_post = "" if _expand_post == post else post
	_build()


func _appoint(post: String, who: String) -> void:
	var old: String = GameState.post_holder(post)
	if old != "" and EventEngine.is_present(GameState, old):
		EventEngine.dismiss_official(GameState, post, who)
	else:
		EventEngine.appoint(GameState, post, who)
	GameState.player_skill_add("yonetim", 0.5)
	_expand_post = ""
	_build()
	_show_result("%s, %s makamına atandı.%s" % [GameState.short_name(who), CharactersData.POSTS[post]["name"], (" %s görevden alındı ve bunu unutmayacak." % GameState.short_name(old)) if old != "" else ""])
