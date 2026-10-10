class_name LogPanel
extends BasePanel
## Günlük: gün gün saray, devlet ve kulis gelişmeleri. Sabah özeti de bu pencereyi kullanır.

var content: VBoxContainer
var mode := "hepsi"
var summary_day := -1


func open(_g: Node, morning_summary_day: int = -1) -> void:
	summary_day = morning_summary_day
	var title := "Günlük"
	if summary_day >= 0:
		title = "Sabah Özeti — %s" % GameState.date_string()
	setup_frame(title, 0.9, 0.88, "Kapat" if summary_day < 0 else "Güne Başla")
	if summary_day < 0:
		var tabs := UI.hbox(8)
		body.add_child(tabs)
		for f in [["hepsi", "Tümü"], ["onemli", "Önemli"], ["kulis", "Kulis"], ["bilgi", "Öğrendikleriniz"]]:
			var fid: String = f[0]
			var b := UI.button(f[1], func(): _set_mode(fid), 48)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tabs.add_child(b)
	var sc := UI.scroll()
	body.add_child(sc)
	content = UI.vbox(6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	_build()


func _set_mode(m: String) -> void:
	mode = m
	_build()


func _build() -> void:
	UI.clear(content)
	var lg: Array = GameState.w["log"]
	if summary_day >= 0:
		var items := GameState.log_for_day(summary_day, 1)
		content.add_child(UI.title("Dün sarayda olanlar", 26))
		if items.is_empty():
			content.add_child(UI.label("Sakin bir gündü.", 20, UI.MUTED))
		for e in items:
			content.add_child(_entry(e))
		content.add_child(UI.sep_line())
		content.add_child(UI.title("Bugün", 26))
		var pend := EventEngine.pending(GameState).size()
		content.add_child(UI.label("Bekleyen olay: %d  •  Divan gündemi: %d  •  Dilekçe: %d" % [pend, DivanEngine.agenda(GameState).size(), PetitionEngine.list(GameState).size()], 20))
		var div := "bugün Divan toplanıyor (08:00-12:00)" if GameState.is_divan_day() else "bugün Divan toplanmıyor"
		content.add_child(UI.label("%s, %s." % [GameState.weekday_name(), div], 19, UI.MUTED))
		return
	var last_day := -1
	for i in range(lg.size() - 1, -1, -1):
		var e2: Dictionary = lg[i]
		if mode == "onemli" and int(e2["imp"]) < 2:
			continue
		if mode == "kulis" and not String(e2["kind"]) in ["kulis", "tartisma", "dostluk", "ittifak", "barisma", "gonul", "soylenti"]:
			continue
		if mode == "bilgi" and String(e2["kind"]) != "bilgi":
			continue
		if int(e2["day"]) != last_day:
			last_day = int(e2["day"])
			content.add_child(UI.label("— %d. gün —" % (last_day + 1), 19, UI.GOLD))
		content.add_child(_entry(e2))


func _entry(e: Dictionary) -> Control:
	var t := int(e["t"]) % 1440
	var col := UI.TEXT
	match String(e["kind"]):
		"devlet", "adalet":
			col = Color("a8c8f0")
		"harem", "aile", "hanedan":
			col = Color("f0b8cc")
		"kulis", "tartisma", "soylenti":
			col = Color("d8c890")
		"bilgi":
			col = Color("a8e0b8")
		"uyari":
			col = Color("f0a090")
	var l := UI.wrap_label("%02d:%02d  %s" % [t / 60, t % 60, e["text"]], 19, col)
	return l
