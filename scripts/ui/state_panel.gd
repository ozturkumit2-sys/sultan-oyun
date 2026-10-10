class_name StatePanel
extends BasePanel
## Devlet Defteri: genel durum, hazine geçmişi, eyalet özeti, diplomasi ve hanedan tarihi.
## Kararlar Divan Salonu'nda verilir; burası bilgi ekranıdır.

var game: Node
var tab := "genel"
var content: VBoxContainer
var _tab_btns := {}
const TABS := [["genel", "Genel Durum"], ["eyalet", "Eyaletler"], ["diplomasi", "Diplomasi"], ["hanedan", "Hanedan"]]


func open(g: Node, start_tab: String = "genel") -> void:
	game = g
	tab = start_tab
	setup_frame("Devlet Defteri", 0.95, 0.93)
	var tabs := UI.hbox(8)
	body.add_child(tabs)
	for t in TABS:
		var tid: String = t[0]
		var b := UI.button(t[1], func(): _set_tab(tid), 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		_tab_btns[tid] = b
	var sc := UI.scroll()
	body.add_child(sc)
	content = UI.vbox(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	_build()


func _set_tab(t: String) -> void:
	tab = t
	_build()


func _build() -> void:
	for k in _tab_btns.keys():
		var b: Button = _tab_btns[k]
		if k == tab:
			b.add_theme_stylebox_override("normal", UI.sb(UI.EMERALD, UI.GOLD2, 2, 10, 14))
		else:
			b.remove_theme_stylebox_override("normal")
	UI.clear(content)
	match tab:
		"genel":
			_genel()
		"eyalet":
			_eyalet()
		"diplomasi":
			_diplomasi()
		"hanedan":
			_hanedan()


func _genel() -> void:
	var st: Dictionary = GameState.w["state"]
	var b := Economy.budget(GameState)
	var row := UI.hbox(12)
	content.add_child(row)
	var c1 := UI.card()
	c1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v1 := UI.vbox(4)
	c1.add_child(v1)
	v1.add_child(UI.title("Hazine", 26))
	v1.add_child(UI.label(GameState.fmt_money(GameState.treasury()), 28, UI.GOLD2, UI.font_semi))
	v1.add_child(UI.label("Aylık gelir (tahmini): %s" % GameState.fmt_money(float(b["gelir"])), 18))
	v1.add_child(UI.label("Aylık gider: %s" % GameState.fmt_money(float(b["giderler"]["toplam"])), 18))
	var net := float(b["net"])
	v1.add_child(UI.label("Net: %s" % GameState.fmt_money(net), 20, UI.GREEN if net >= 0 else UI.RED))
	v1.add_child(UI.label("Vergi: %s • Saray: %s • Ordu: %s" % [ProvincesData.TAX_LEVELS[int(st["tax_level"])]["name"], ProvincesData.SPEND_LEVELS[int(st["palace_level"])], ProvincesData.ARMY_LEVELS[int(st["army_level"])]], 17, UI.MUTED))
	row.add_child(c1)
	var c2 := UI.card()
	c2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v2 := UI.vbox(4)
	c2.add_child(v2)
	v2.add_child(UI.title("İmparatorluk", 26))
	v2.add_child(UI.stat_row("Halk huzuru", GameState.people_huzur(), UI.GREEN))
	v2.add_child(UI.stat_row("Prestij", float(st["prestige"]), UI.GOLD))
	v2.add_child(UI.stat_row("Meşruiyet", float(st["legitimacy"]), UI.BLUE))
	v2.add_child(UI.stat_row("Adalet itibarı", float(st["justice"]), UI.EMERALD2))
	v2.add_child(UI.stat_row("Halk gözünde Sultan", float(st["people_rep"]), Color("d8a24e")))
	v2.add_child(UI.label("Nüfus: %s bin  •  Tahıl fiyatı: %.2f" % [str(int(GameState.total_pop())), float(st["food_price"])], 17, UI.MUTED))
	row.add_child(c2)
	var c3 := UI.card()
	c3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v3 := UI.vbox(4)
	c3.add_child(v3)
	v3.add_child(UI.title("Hükümdar", 26))
	var pl: Dictionary = GameState.player()
	v3.add_child(UI.label("%s, %d yaşında" % [GameState.full_name(GameState.PLAYER), int(pl["age"])], 18))
	for sk in CharactersData.SKILL_NAMES.keys():
		v3.add_child(UI.stat_row(CharactersData.SKILL_NAMES[sk], GameState.player_skill(sk), UI.BLUE))
	row.add_child(c3)
	var hist: Array = st.get("history", [])
	content.add_child(UI.title("Hazine Geçmişi", 26))
	if hist.size() < 2:
		content.add_child(UI.wrap_label("Aylık hesaplar her ayın başında kapanır. Grafik birkaç ay sonra anlam kazanacak.", 18, UI.MUTED))
	var chart := LineChart.new()
	chart.custom_minimum_size = Vector2(0, 220)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var series_t: Array = []
	var series_h: Array = []
	var labels: Array = []
	for hrec in hist:
		series_t.append(float(hrec["hazine"]))
		series_h.append(float(hrec["huzur"]))
		labels.append(String(hrec.get("label", "")))
	if series_t.is_empty():
		series_t = [GameState.treasury()]
		series_h = [GameState.people_huzur()]
		labels = [GameState.MONTHS[GameState.get_month()].substr(0, 3)]
	chart.series = [{"name": "Hazine", "values": series_t, "color": UI.GOLD}]
	chart.series2 = {"name": "Huzur (%)", "values": series_h, "color": UI.GREEN}
	chart.labels = labels
	content.add_child(chart)
	var rep: Dictionary = st.get("last_report", {})
	if not rep.is_empty():
		content.add_child(UI.title("Son Aylık Rapor", 24))
		for n in rep.get("notlar", []):
			content.add_child(UI.wrap_label("• " + String(n), 18, UI.CREAM))
	content.add_child(UI.button("Divan Salonu'na Git (kararlar orada verilir)", _go_divan, 56, true))


func _go_divan() -> void:
	if game:
		game.walk_to_room("divan")
	close_panel()


func _eyalet() -> void:
	var g := UI.grid(3, 10, 10)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(g)
	for p in GameState.w["provinces"]:
		var card := UI.card()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(3)
		card.add_child(v)
		v.add_child(UI.label(String(p["name"]), 22, UI.GOLD2, UI.font_semi))
		v.add_child(UI.stat_row("Huzur", float(p["huzur"]), UI.GREEN if float(p["huzur"]) >= 50 else (Color("d8a24e") if float(p["huzur"]) >= 30 else UI.RED)))
		v.add_child(UI.stat_row("Refah", float(p["refah"]), UI.GOLD))
		v.add_child(UI.label("Tahıl %.1f ay • Vergi %s" % [float(p["gida"]), GameState.fmt_money(Economy.province_tax(GameState, p))], 16, UI.MUTED))
		g.add_child(card)


func _diplomasi() -> void:
	content.add_child(UI.wrap_label("Komşu devletlerle ilişkiler. Elçi göndermek için Reisülküttap Selim Efendi'ye görev verebilir, Divan'da sınır meselelerine karar verebilirsiniz. Savaş ve stratejik sefer sistemi geliştirme yol haritasının 6. aşamasındadır.", 18, UI.MUTED))
	for nb in GameState.w["neighbors"]:
		var card := UI.card()
		var v := UI.vbox(4)
		card.add_child(v)
		v.add_child(UI.title(String(nb["name"]), 26))
		v.add_child(UI.label("Hükümdar: %s" % nb["ruler"], 18))
		v.add_child(UI.wrap_label(String(nb["desc"]), 17, UI.MUTED))
		var att := float(nb["attitude"])
		v.add_child(UI.stat_row("Bize tutumu", att, UI.GREEN if att >= 55 else (Color("d8a24e") if att >= 35 else UI.RED)))
		v.add_child(UI.stat_row("Askerî güç", float(nb["strength"]), UI.RED))
		v.add_child(UI.stat_row("Ticaret ilgisi", float(nb["trade"]), UI.GOLD))
		content.add_child(card)


func _hanedan() -> void:
	var dyn: Dictionary = GameState.w.get("dynasty", {})
	content.add_child(UI.title("Zehrâni Hanedanı", 30))
	var tree := FamilyTree.new()
	tree.custom_minimum_size = Vector2(0, 300)
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(tree)
	content.add_child(UI.title("Hanedan Tarihi", 26))
	var hist: Array = dyn.get("history", [])
	for i in range(hist.size() - 1, -1, -1):
		var e: Dictionary = hist[i]
		content.add_child(UI.label("%d. gün — %s" % [int(e["day"]) + 1, e["text"]], 18, UI.CREAM))
	content.add_child(UI.wrap_label("Harem, eş arayışı, gece davetleri ve şehzadelerin eğitimi Hasodabaşı Cafer Ağa üzerinden yürür. Davalar ve cezalar için Kadıasker'le konuşun.", 17, UI.MUTED))
