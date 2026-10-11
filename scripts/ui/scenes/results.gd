extends BaseScreen
## Results — maç sonu: kazanan duyurusu, tur tablosu, beraberlik bozucu, yıldızlar, ödüller ve açılan içerikler.

var r: Dictionary = {}


func _ready() -> void:
	r = BattleManager.results
	if r.is_empty():
		GameManager.goto("menu", {}, false)
		return
	var won: bool = r.get("won", false)
	setup_screen("sunburst", Color("#ffb35c") if won else Color("#7c6bd6"), Color("#ff5fa2") if won else Color("#2a1b3d"))
	AudioManager.stop_music(0.3)
	if r.get("mode", "") == "daily":
		_build_daily()
	else:
		_build_career()


func _figures(area: Control, h: float, won: bool) -> void:
	var n := Node2D.new()
	area.add_child(n)
	var w := GameManager.screen_size.x - 36
	var pf := CharacterFigure.new()
	pf.setup(CharacterFigure.chef_spec(ProgressionManager.chef()))
	pf.scale = Vector2(0.8, 0.8)
	pf.position = Vector2(w * (0.28 if r.get("opponent", "") != "" else 0.5), h)
	n.add_child(pf)
	var of: CharacterFigure = null
	if r.get("opponent", "") != "":
		of = CharacterFigure.new()
		of.setup(CharacterFigure.preset(r["opponent"]))
		of.scale = Vector2(0.7, 0.7)
		of.position = Vector2(w * 0.74, h)
		n.add_child(of)
	await get_tree().create_timer(0.4).timeout
	if won:
		pf.react("cheer")
		pf.set_pose("up")
		if of:
			of.react("sad")
		AudioManager.sfx("fanfare")
		FxBurst.spawn(area, Vector2(w * 0.5, 40), "confetti", 50)
	else:
		pf.react("sad")
		if of:
			of.react("laugh")
			of.set_pose("up")
		AudioManager.sfx("sad_trombone")
	if of and r.get("line", "") != "":
		SpeechBubble.show_at(area, Vector2(w * 0.74, h - 270 * 0.7), r["line"], 4.0, 0.5, Color.WHITE, 330)
		of.talk(2.0)


func _build_career() -> void:
	var won: bool = r["won"]
	var t := UIKit.title(Loc.t("KAZANDIN!") if won else Loc.t("KAYBETTİN"), 70, Color("#fff1a8") if won else Color("#ffd0d0"), UIKit.INK, 16)
	root_v.add_child(t)
	UIKit.pop_in(t, 0.2)
	var fig_area := Control.new()
	fig_area.custom_minimum_size = Vector2(0, 280)
	fig_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_v.add_child(fig_area)
	_figures(fig_area, 280, won)
	var p := UIKit.panel(UIKit.CREAM, 28, UIKit.INK, 4, 16)
	var content := UIKit.vbox(10)
	p.add_child(content)
	var sc := UIKit.scroll(p)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	content.add_child(grid)
	for h in [Loc.t("Tur"), Loc.t("Sen"), BattleManager.opponent_name().split(" ")[-1] if r.get("opponent", "") != "" else Loc.t("Rakip")]:
		grid.add_child(UIKit.label(h, 22, Color("#8a6a50")))
	for rr in r["rounds"]:
		grid.add_child(UIKit.label(str(rr["round"]), 24))
		var pl := UIKit.label(UIKit.fmt(rr["player"]), 26, UIKit.GREEN if rr["winner"] == "player" else UIKit.INK)
		pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(pl)
		var ol := UIKit.label(UIKit.fmt(rr["opp"]), 26, UIKit.RED if rr["winner"] == "opp" else UIKit.INK)
		ol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(ol)
	grid.add_child(UIKit.label(Loc.t("TOPLAM"), 24, UIKit.PURPLE))
	grid.add_child(UIKit.label(UIKit.fmt(r["player_total"]), 30, UIKit.PURPLE))
	grid.add_child(UIKit.label(UIKit.fmt(r["opp_total"]), 30, UIKit.PURPLE))
	if r.get("tiebreak", "") != "":
		content.add_child(UIKit.wrap_label(r["tiebreak"], 22, Color("#a23a5a"), true))
	# yıldızlar
	var lg: Dictionary = IngredientDatabase.league(int(IngredientDatabase.matches[r["match_id"]]["league"]))
	var star_texts := [Loc.t("Maçı kazan"), Loc.t("Toplam %d+ puan") % int(lg.get("score_star", 60)), r.get("challenge", "")]
	var srow := UIKit.hbox(8)
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(srow)
	for i in 3:
		var cv := UIKit.vbox(2)
		cv.custom_minimum_size.x = 196
		var got: bool = r["stars"][i]
		var st := UIKit.icon("star" if got else "star_empty", 76)
		st.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cv.add_child(st)
		var l := UIKit.wrap_label(star_texts[i], 18, UIKit.INK if got else Color("#9d8b78"), true)
		cv.add_child(l)
		srow.add_child(cv)
		if got:
			_star_anim(st, 0.6 + i * 0.35)
	# ödüller
	var rew := UIKit.hbox(18)
	rew.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(rew)
	rew.add_child(UIKit.icon_label("coin", "+%d" % int(r["coins"]), 32, Color("#c98a14"), 48))
	rew.add_child(UIKit.icon_label("levelup", Loc.t("+%d XP") % int(r["xp"]), 30, UIKit.GREEN, 44))
	if int(r.get("levels", 0)) > 0:
		content.add_child(UIKit.wrap_label(Loc.t("SEVİYE ATLADIN! Seviye %d · Uzmanlık puanını Şefim ekranında kullan.") % ProgressionManager.level(), 22, UIKit.GREEN, true))
	if int(r.get("rematch_bonus", 0)) > 0:
		var rt := Loc.t("İNTİKAM DURDURULDU! +%d bonus para") if r.get("rematch", "") == "revenge" else Loc.t("RÖVANŞ ALINDI! +%d bonus para")
		content.add_child(UIKit.wrap_label(rt % int(r["rematch_bonus"]), 26, Color("#e0244f"), true))
	if int(r.get("league_completed", 0)) > 0:
		content.add_child(UIKit.wrap_label(Loc.t("LİG TAMAMLANDI! +%d bonus para") % int(r.get("league_bonus", 0)), 26, UIKit.PURPLE, true))
	for u in r.get("unlocked", []):
		var row := UIKit.hbox(10)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		match u["kind"]:
			"ingredient":
				var ic := IngredientIcon.new()
				ic.custom_minimum_size = Vector2(64, 64)
				ic.set_item(u["id"])
				row.add_child(ic)
				row.add_child(UIKit.label(Loc.t("Yeni malzeme: %s") % IngredientDatabase.ingredients[u["id"]]["name"], 24, UIKit.INK))
			"feature":
				row.add_child(UIKit.icon("plus", 52))
				row.add_child(UIKit.wrap_label(Loc.t("Üçüncü kase yuvası açıldı! Artık 3 malzemeli tarifler yapabilirsin."), 22, UIKit.INK, true))
			"league":
				row.add_child(UIKit.icon("map", 52))
				row.add_child(UIKit.label(Loc.t("Yeni lig açıldı: %s") % IngredientDatabase.league(int(u["id"])).get("name", ""), 24, UIKit.INK))
		content.add_child(row)
	ProgressionManager.add_coins(0)
	var btns := UIKit.hbox(10)
	root_v.add_child(btns)
	var again := UIKit.button(Loc.t("Tekrar"), UIKit.ORANGE, Vector2(0, 86), 26, "refresh")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func():
		BattleManager.start_career(r["match_id"])
		GameManager.goto("kitchen", {}, false))
	btns.add_child(again)
	var cont := UIKit.button(Loc.t("Devam"), UIKit.GREEN, Vector2(0, 86), 30, "map")
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.pressed.connect(func(): GameManager.goto("career", {}, false))
	btns.add_child(cont)


func _star_anim(st: Control, delay: float) -> void:
	st.pivot_offset = Vector2(38, 38)
	st.scale = Vector2.ZERO
	var tw := st.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): AudioManager.sfx("star"))
	tw.tween_property(st, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(st, "scale", Vector2.ONE, 0.15)


func _build_daily() -> void:
	var won: bool = r["won"]
	var t := UIKit.title(Loc.t("GÜNLÜK SKOR"), 60, Color("#fff1a8"), UIKit.INK, 14)
	root_v.add_child(t)
	var fig_area := Control.new()
	fig_area.custom_minimum_size = Vector2(0, 280)
	fig_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_v.add_child(fig_area)
	_figures(fig_area, 280, won)
	var p := UIKit.panel(UIKit.CREAM, 28, UIKit.INK, 4, 18)
	root_v.add_child(p)
	var v := UIKit.vbox(10)
	p.add_child(v)
	v.add_child(UIKit.title(UIKit.fmt(r["player_total"]) + " / 30", 60, Color("#ff9b3d"), UIKit.INK, 12))
	if r.get("new_best", false):
		var nb := UIKit.chip(Loc.t("YENİ KİŞİSEL REKOR!"), UIKit.PINK, 26)
		nb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(nb)
	v.add_child(UIKit.label(Loc.t("Bugünkü en iyi: %s · Hedef: %s") % [UIKit.fmt(r["best"]), UIKit.fmt(float(r["target"]))], 24))
	v.add_child(UIKit.icon_label("levelup", Loc.t("+%d XP") % int(r["xp"]), 26, UIKit.GREEN, 40))
	if DailyChallengeManager.can_claim():
		var claim := UIKit.button(Loc.t("ÖDÜLÜ AL (+%d)") % DailyChallengeManager.REWARD, UIKit.YELLOW, Vector2(0, 86), 30, "coin")
		claim.pressed.connect(func():
			if DailyChallengeManager.claim():
				AudioManager.sfx("coins")
				FxBurst.spawn(claim, claim.size * 0.5, "coins", 20)
				claim.disabled = true
				claim.text = Loc.t("ALINDI!"))
		v.add_child(claim)
	elif DailyChallengeManager.claimed_today():
		v.add_child(UIKit.label(Loc.t("Bugünün ödülü alındı. Yarın yeni meydan okuma!"), 22, Color("#6a4a3a")))
	else:
		v.add_child(UIKit.wrap_label(Loc.t("Ödül için en az %s puan gerekli. Tekrar deneyebilirsin!") % UIKit.fmt(float(r["target"])), 22, Color("#a23a5a"), true))
	root_v.add_child(UIKit.expander())
	var btns := UIKit.hbox(10)
	root_v.add_child(btns)
	var again := UIKit.button(Loc.t("Tekrar"), UIKit.ORANGE, Vector2(0, 86), 26, "refresh")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func():
		BattleManager.start_daily(DailyChallengeManager.challenge())
		GameManager.goto("kitchen", {}, false))
	btns.add_child(again)
	var cont := UIKit.button(Loc.t("Tamam"), UIKit.GREEN, Vector2(0, 86), 30, "check")
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cont.pressed.connect(func(): GameManager.goto("daily", {}, false))
	btns.add_child(cont)


func on_back() -> bool:
	GameManager.goto("daily" if r.get("mode", "") == "daily" else "career", {}, false)
	return true
