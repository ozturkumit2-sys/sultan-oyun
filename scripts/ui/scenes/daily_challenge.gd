extends BaseScreen
## DailyChallenge — yerel tarihten deterministik üretilen günlük meydan okuma.
## Aynı tarih + içerik sürümü = aynı malzemeler, tema ve jüri koşulu. Ödül günde bir kez alınır.


func _ready() -> void:
	setup_screen("sunburst", Color("#ff9fd0"), Color("#a25cff"))
	make_header("GÜNLÜK", true, true)
	var ch := DailyChallengeManager.challenge()
	var p := UIKit.panel(UIKit.CREAM, 28, UIKit.INK, 4, 18)
	var v := UIKit.vbox(12)
	p.add_child(v)
	var sc := UIKit.scroll(p)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(sc)
	v.add_child(UIKit.label(_pretty_date(ch["date"]), 26, UIKit.PURPLE))
	var th: Dictionary = IngredientDatabase.theme(ch["theme"])
	v.add_child(UIKit.title(th.get("name", ""), 46, Color("#ff9b3d"), UIKit.INK, 12))
	v.add_child(UIKit.wrap_label(th.get("desc", ""), 22))
	v.add_child(UIKit.label("Bugünün 5 malzemesi", 24, Color("#8a5a3b")))
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 8)
	v.add_child(row)
	for id in ch["ingredients"]:
		var cv := UIKit.vbox(0)
		var ic := IngredientIcon.new()
		ic.custom_minimum_size = Vector2(110, 100)
		ic.set_item(id)
		cv.add_child(ic)
		var l := UIKit.label(IngredientDatabase.ingredients[id]["name"], 16)
		l.custom_minimum_size.x = 110
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(l)
		row.add_child(cv)
	var cond: Dictionary = ch["condition"]
	var jrow := UIKit.hbox(10)
	v.add_child(jrow)
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(160, 170)
	portrait.clip_contents = true
	jrow.add_child(portrait)
	var n := Node2D.new()
	portrait.add_child(n)
	var f := CharacterFigure.new()
	f.setup(CharacterFigure.preset(cond["judge"]))
	f.set_mutation(cond["mutation"])
	f.scale = Vector2(0.5, 0.5)
	f.position = Vector2(80, 230)
	n.add_child(f)
	var jv := UIKit.vbox(4)
	jv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jrow.add_child(jv)
	jv.add_child(UIKit.label("Jüri koşulu", 22, Color("#8a5a3b"), true, HORIZONTAL_ALIGNMENT_LEFT))
	jv.add_child(UIKit.wrap_label("%s bugün %s!" % [IngredientDatabase.judge_map[cond["judge"]]["name"], MutationSystem.mutation_name(cond["mutation"])], 24, UIKit.PURPLE, true, HORIZONTAL_ALIGNMENT_LEFT))
	jv.add_child(UIKit.wrap_label(MutationSystem.describe(cond["mutation"]), 19, UIKit.INK, false, HORIZONTAL_ALIGNMENT_LEFT))
	var stats := UIKit.hbox(16)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(stats)
	stats.add_child(UIKit.icon_label("trophy", "En iyi: %s" % UIKit.fmt(DailyChallengeManager.best_today()), 24, UIKit.INK, 40))
	stats.add_child(UIKit.icon_label("star", "Hedef: %s" % UIKit.fmt(float(ch["target"])), 24, UIKit.INK, 40))
	var rew := UIKit.icon_label("coin", "Ödül: %d (günde bir kez)" % int(ch["reward"]), 22, Color("#c98a14"), 36)
	v.add_child(rew)
	if DailyChallengeManager.can_claim():
		var claim := UIKit.button("ÖDÜLÜ AL!", UIKit.YELLOW, Vector2(0, 80), 30, "coin")
		claim.pressed.connect(func():
			if DailyChallengeManager.claim():
				AudioManager.sfx("coins")
				claim.disabled = true
				claim.text = "ALINDI!")
		v.add_child(claim)
	elif DailyChallengeManager.claimed_today():
		v.add_child(UIKit.label("Bugünün ödülü alındı!", 22, UIKit.GREEN))
	var hist: Dictionary = DailyChallengeManager.history_best()
	if not hist.is_empty():
		var keys: Array = hist.keys()
		keys.sort()
		keys.reverse()
		var hs: Array = []
		for k in keys.slice(0, 5):
			hs.append("%s: %s" % [k, UIKit.fmt(float(hist[k]))])
		v.add_child(UIKit.wrap_label("Geçmiş: " + " · ".join(PackedStringArray(hs)), 18, Color("#8a6a50")))
	v.add_child(UIKit.wrap_label("Not: Günlük meydan okuma cihaz saatine göre çalışır ve tamamen çevrimdışıdır.", 16, Color("#9d8b78")))
	var go := UIKit.button("BAŞLA!", UIKit.GREEN, Vector2(0, 92), 36, "play")
	go.pressed.connect(func():
		BattleManager.start_daily(ch)
		GameManager.goto("kitchen"))
	root_v.add_child(go)


func _pretty_date(d: String) -> String:
	var parts := d.split("-")
	if parts.size() != 3:
		return d
	var months := ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
	return "%d %s %s" % [int(parts[2]), months[clampi(int(parts[1]) - 1, 0, 11)], parts[0]]
