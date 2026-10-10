class_name TimeSkipPanel
extends BasePanel
## Zamanı ileri sar: 1 gün, 1 hafta, 1 ay, 1 mevsim. Saray kendi işleyişinde sürer;
## önemli bir gelişmede (doğum, müjde, yeni bir hanedan/adalet meselesi, hazine açığı) durur.

const OPTIONS := [["1 gün", 1], ["1 hafta", 7], ["1 ay", 30], ["1 mevsim (3 ay)", 90]]
const STOP_CATS := ["hanedan", "adalet", "aile"]

var game: Node
var _status: Label
var _bar: ProgressBar
var _btns: Array = []
var _running := false
var _cancel := false


func open(g: Node) -> void:
	game = g
	setup_frame("Zamanı İlerlet", 0.66, 0.62)
	body.add_child(UI.wrap_label("Saray kendi işleyişinde devam eder: herkes rutinine göre yaşar, hamilelikler ilerler, çocuklar büyür, aylık hesaplar kapanır. Önemli bir gelişme olursa (doğum, müjde, adalet ya da hanedan meselesi, hazine açığı) zaman durur ve size haber verilir.", 19, UI.MUTED))
	body.add_child(UI.wrap_label("Bekleyen kararlar süresi dolunca kendiliğinden sonuçlanır.", 18, Color("e0b080")))
	var g2 := UI.grid(2, 12, 12)
	g2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(g2)
	for o in OPTIONS:
		var days: int = o[1]
		var b := UI.button(String(o[0]), func(): _run(days), 64, days >= 30)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 22)
		g2.add_child(b)
		_btns.append(b)
	_bar = UI.bar(0.0, 1.0, UI.GOLD, 14)
	_bar.visible = false
	body.add_child(_bar)
	_status = UI.label("", 19, UI.CREAM)
	body.add_child(_status)


func _run(days: int) -> void:
	if _running:
		return
	_running = true
	for b in _btns:
		b.disabled = true
	_bar.visible = true
	GameState.set_flag("stop_skip", false)
	HaremEngine.data(GameState)["night"] = {}   # bekleyen gece daveti zaman atlanınca iptal olur
	var start_day := GameState.get_day()
	var start_ev: Dictionary = {}
	for e in EventEngine.pending(GameState):
		start_ev[String(e["uid"])] = true
	game.begin_skip()
	var stop_reason := ""
	var done := 0
	for i in range(days):
		if _cancel or not is_inside_tree():
			break
		# bir sonraki sabah 07:00'ye
		var mins := (24 - GameState.get_hour() + 7) * 60 - GameState.get_minute()
		if mins > 24 * 60:
			mins -= 24 * 60
		GameState.advance_minutes(mins)
		done += 1
		_bar.value = float(done) / float(days)
		_status.text = "%s  •  %d / %d gün" % [GameState.date_string(), done, days]
		stop_reason = _stop_check(start_ev)
		if stop_reason != "":
			break
		await get_tree().process_frame
	GameState.set_flag("stop_skip", false)
	game.end_skip()
	_running = false
	if not is_inside_tree():
		return
	var summary := _summary(start_day, done, stop_reason)
	var gm := game
	super.close_panel()
	var sp := StoryPanel.new()
	gm.hud.open_panel(sp)
	sp.open("%d gün geçti" % done, summary)


func _stop_check(start_ev: Dictionary) -> String:
	if GameState.flag("stop_skip"):
		return "Hanedanda önemli bir gelişme var."
	for e in EventEngine.pending(GameState):
		if start_ev.has(String(e["uid"])):
			continue
		if String(e.get("cat", "")) in STOP_CATS:
			return "Yeni bir mesele kararınızı bekliyor: %s." % String(e["title"])
	if GameState.treasury() < 0.0:
		return "Hazine açık veriyor!"
	return ""


func _summary(start_day: int, done: int, reason: String) -> String:
	var lines: Array = []
	if reason != "":
		lines.append("[color=#f0c080][b]Durduruldu:[/b] %s[/color]\n" % reason)
	var n := 0
	for d in range(start_day, GameState.get_day() + 1):
		for e in GameState.log_for_day(d, 2):
			lines.append("• %d. gün — %s" % [d + 1, String(e["text"])])
			n += 1
	if n == 0:
		lines.append("Saray sakin günler geçirdi; kayda değer bir gelişme olmadı.")
	if lines.size() > 40:
		lines = lines.slice(lines.size() - 40)
		lines.push_front("(... daha eski kayıtlar Günlük'te)")
	lines.append("\nHazine: %s  •  Halk huzuru %%%d" % [GameState.fmt_money(GameState.treasury()), int(GameState.people_huzur())])
	return "\n".join(PackedStringArray(lines))


func close_panel() -> void:
	if _running:
		_cancel = true
		return
	super.close_panel()
