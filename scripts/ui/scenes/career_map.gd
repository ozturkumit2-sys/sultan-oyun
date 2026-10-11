extends BaseScreen
## CareerMap — beş lig, her ligde üç maç. Yıldızlar, kilitler, boss rozetleri ve maç detay penceresi.

var list: VBoxContainer
var scroll: ScrollContainer


func _ready() -> void:
	setup_screen("map", Color("#ffe9c7"), Color("#ffd29a"))
	make_header(Loc.t("KARİYER"), true, true)
	AudioManager.music("menu")
	var info := UIKit.hbox(12)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	root_v.add_child(info)
	info.add_child(UIKit.icon_label("star", Loc.t("%d / %d") % [ProgressionManager.total_stars(), IngredientDatabase.match_order.size() * 3], 28, UIKit.INK, 44))
	info.add_child(UIKit.icon_label("book", Loc.t("%d tarif") % RecipeBookManager.count_all(), 26, UIKit.INK, 40))
	list = UIKit.vbox(18)
	scroll = UIKit.scroll(list)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(scroll)
	var focus_node: Control = null
	for l in IngredientDatabase.leagues:
		var node := _league_block(l)
		list.add_child(node)
		if ProgressionManager.league_unlocked(int(l["id"])) and not ProgressionManager.league_done(int(l["id"])) and focus_node == null:
			focus_node = node
	list.add_child(UIKit.spacer(40))
	if focus_node:
		await get_tree().process_frame
		await get_tree().process_frame
		scroll.scroll_vertical = int(maxf(0.0, focus_node.position.y - 20))


func _league_block(l: Dictionary) -> Control:
	var lid := int(l["id"])
	var unlocked := ProgressionManager.league_unlocked(lid)
	var done := ProgressionManager.league_done(lid)
	var col := Color(l.get("color", "#ff9b3d"))
	var col2 := Color(l.get("color2", "#ffd166"))
	var p := UIKit.panel(col.lightened(0.72) if unlocked else Color("#d8cbbb"), 30, col.darkened(0.35) if unlocked else Color("#9d8b78"), 5, 16)
	var v := UIKit.vbox(10)
	p.add_child(v)
	var head := UIKit.hbox(10)
	v.add_child(head)
	var badge := UIKit.title(str(lid), 46, Color.WHITE, col.darkened(0.4), 12)
	badge.custom_minimum_size = Vector2(60, 60)
	head.add_child(badge)
	var hv := UIKit.vbox(0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(UIKit.label(l["name"].to_upper(), 30, col.darkened(0.45) if unlocked else Color("#7a6a5a"), true, HORIZONTAL_ALIGNMENT_LEFT))
	hv.add_child(UIKit.wrap_label(l.get("desc", ""), 19, Color("#6a4a3a"), false, HORIZONTAL_ALIGNMENT_LEFT))
	if done:
		head.add_child(UIKit.icon("trophy", 56))
	elif not unlocked:
		head.add_child(UIKit.icon("lock", 52))
	var row := UIKit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for m in l.get("matches", []):
		row.add_child(_match_node(m, col, col2))
	if not unlocked:
		v.add_child(UIKit.label(Loc.t("Önceki ligi tamamlayınca açılır"), 20, Color("#7a6a5a")))
	else:
		v.add_child(UIKit.icon_label("coin", Loc.t("Lig ödülü: %d") % int(l.get("reward", 0)), 20, Color("#8a5a3b"), 28))
	return p


func _match_node(m: Dictionary, col: Color, col2: Color) -> Control:
	var mid: String = m["id"]
	var unlocked := ProgressionManager.is_match_unlocked(mid)
	var rec := ProgressionManager.match_record(mid)
	var card := TapCard.new()
	card.custom_minimum_size = Vector2(206, 250)
	card.set_colors(col2.lightened(0.5) if unlocked else Color("#e3d8ca"), col.darkened(0.3) if unlocked else Color("#9d8b78"))
	var v := UIKit.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(190, 150)
	portrait.clip_contents = true
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(portrait)
	var n := Node2D.new()
	portrait.add_child(n)
	var f := CharacterFigure.new()
	f.setup(CharacterFigure.preset(m["opponent"]))
	f.scale = Vector2(0.5, 0.5)
	f.position = Vector2(95, 200)
	f.idle_enabled = unlocked
	n.add_child(f)
	if not unlocked:
		portrait.modulate = Color(0.25, 0.2, 0.25, 0.9)
		var lk := UIKit.icon("lock", 60)
		lk.position = Vector2(65, 45)
		portrait.add_child(lk)
	if m.get("boss", false):
		var b := UIKit.chip(Loc.t("BOSS"), UIKit.RED, 16)
		b.position = Vector2(4, 4)
		portrait.add_child(b)
	var nm := UIKit.label(IngredientDatabase.opponents[m["opponent"]]["name"] if unlocked else "???", 19, UIKit.INK)
	nm.clip_text = true
	nm.custom_minimum_size.x = 190
	v.add_child(nm)
	v.add_child(UIKit.stars(ProgressionManager.match_stars(mid), 3, 30))
	card.tapped.connect(func(): _open_match(mid))
	if unlocked and rec["wins"] == 0:
		var tw := card.create_tween().set_loops()
		tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(card, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	return card


func _open_match(mid: String) -> void:
	if not ProgressionManager.is_match_unlocked(mid):
		GameManager.toast(Loc.t("Önce önceki maçı kazan!"), UIKit.ORANGE, "lock")
		AudioManager.sfx("fail", 1.3, -8.0)
		return
	var m: Dictionary = IngredientDatabase.matches[mid]
	var o: Dictionary = IngredientDatabase.opponents[m["opponent"]]
	var lg: Dictionary = IngredientDatabase.league(int(m["league"]))
	var rec := ProgressionManager.match_record(mid)
	var extra := UIKit.vbox(8)
	var top := UIKit.hbox(10)
	extra.add_child(top)
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(170, 190)
	portrait.clip_contents = true
	top.add_child(portrait)
	var n := Node2D.new()
	portrait.add_child(n)
	var f := CharacterFigure.new()
	f.setup(CharacterFigure.preset(m["opponent"]))
	f.scale = Vector2(0.55, 0.55)
	f.position = Vector2(85, 240)
	n.add_child(f)
	var tv := UIKit.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	tv.add_child(UIKit.label(o.get("title", ""), 22, UIKit.PURPLE, true, HORIZONTAL_ALIGNMENT_LEFT))
	tv.add_child(UIKit.wrap_label(o.get("personality", ""), 19, UIKit.INK, false, HORIZONTAL_ALIGNMENT_LEFT))
	tv.add_child(UIKit.wrap_label(Loc.t("Strateji: %s") % o.get("strategy", ""), 19, Color("#6a4a3a"), false, HORIZONTAL_ALIGNMENT_LEFT))
	var ab: Dictionary = o.get("ability", {})
	extra.add_child(UIKit.wrap_label(Loc.t("Yetenek — %s: %s") % [ab.get("name", ""), ab.get("desc", "")], 20, Color("#a23a5a"), true, HORIZONTAL_ALIGNMENT_LEFT))
	var rules: Array = m.get("rules", []).duplicate()
	if m.get("boss", false) and not rules.has(o.get("boss_rule", "")):
		rules.append(o.get("boss_rule", ""))
	for r in rules:
		var rd: Dictionary = IngredientDatabase.rules.get(r, {})
		if not rd.is_empty():
			extra.add_child(UIKit.wrap_label(Loc.t("• %s: %s") % [rd["name"], rd["desc"]], 19, UIKit.INK, false, HORIZONTAL_ALIGNMENT_LEFT))
	var themes := []
	for t in m.get("themes", []):
		themes.append(IngredientDatabase.theme(t).get("name", t))
	extra.add_child(UIKit.wrap_label(Loc.t("Temalar: %s") % Loc.list_sep().join(PackedStringArray(themes)), 19, Color("#6a4a3a"), false, HORIZONTAL_ALIGNMENT_LEFT))
	var star_texts := [Loc.t("Maçı kazan"), Loc.t("Toplam %d+ puan al") % int(lg.get("score_star", 60)), m.get("challenge", {}).get("text", "")]
	for i in 3:
		var row := UIKit.hbox(8)
		row.add_child(UIKit.icon("star" if rec["stars"][i] else "star_empty", 34))
		row.add_child(UIKit.label(star_texts[i], 21, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT))
		extra.add_child(row)
	if rec["plays"] > 0:
		extra.add_child(UIKit.label(Loc.t("En iyi skor: %s · Oynanma: %d") % [UIKit.fmt(rec["best"]), rec["plays"]], 19, Color("#6a4a3a")))
	var md := UIKit.modal(self, o["name"], "", [[Loc.t("Kapat"), "close", UIKit.GRAY], [Loc.t("BAŞLA!"), "go", UIKit.GREEN]], extra)
	var ch: String = await md.closed
	if ch == "go":
		BattleManager.start_career(mid)
		GameManager.goto("kitchen")
