extends Control
## JudgingStage — jüri sahnesi. Her yemek için: sunum → tadım (eğilme + çiğneme) → tepki →
## puan kartları ve gerekçeler → (mutasyon) → (tartışma) → toplam. En sonda tur özeti.

const JUDGE_IDS := ["bruno", "mira", "max"]

var judges: Dictionary = {}
var cards: Dictionary = {}
var plates: Dictionary = {}
var table_y := 0.0
var res: Dictionary = {}
var panel_v: VBoxContainer
var bottom: PanelContainer
var stage: Node2D
var bubble_layer: Control
var top_label: Label
var dish: DishView
var contestant: CharacterFigure
var _fast := false
var _skip := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if not BattleManager.active or BattleManager.cur.is_empty() or BattleManager.cur.get("player", {}).is_empty():
		GameManager.goto("menu", {}, false)
		return
	_fast = GameManager.fast()
	res = BattleManager.judge_round()
	_build()
	AudioManager.music("judging")
	await get_tree().create_timer(0.3).timeout
	await _run()


# ------------------------------------------------------------------ kurulum
func _build() -> void:
	var sz := GameManager.screen_size
	var bd := Backdrop.new()
	bd.kind = "stage"
	add_child(bd)
	table_y = sz.y * 0.5
	stage = Node2D.new()
	add_child(stage)
	for i in 3:
		var jid: String = JUDGE_IDS[i]
		var f := CharacterFigure.new()
		f.setup(CharacterFigure.preset(jid))
		f.scale = Vector2(0.76, 0.76)
		f.position = Vector2(sz.x * (0.19 + 0.31 * i), table_y + 58)
		var m: String = res.get("mutations_before", BattleManager.mutations).get(jid, "")
		if m != "":
			f.set_mutation(m)
		stage.add_child(f)
		judges[jid] = f
	var table := JudgeTable.new()
	table.top = table_y
	table.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(table)
	for i in 3:
		var jid2: String = JUDGE_IDS[i]
		var plate := UIKit.panel(Color("#fff2c4"), 12, UIKit.INK, 3, 6)
		var l := UIKit.label(IngredientDatabase.judge_map[jid2]["name"], 18, UIKit.INK)
		plate.add_child(l)
		add_child(plate)
		plate.position = Vector2(sz.x * (0.19 + 0.31 * i) - 90, table_y + 80)
		plate.custom_minimum_size = Vector2(180, 0)
		plates[jid2] = plate
	dish = DishView.new()
	dish.position = Vector2(sz.x * 0.5, table_y + 34)
	dish.scale = Vector2(0.62, 0.62)
	dish.visible = false
	add_child(dish)
	var cl := Control.new()
	cl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cl)
	var cstage := Node2D.new()
	cl.add_child(cstage)
	contestant = CharacterFigure.new()
	contestant.scale = Vector2(0.62, 0.62)
	contestant.visible = false
	cstage.add_child(contestant)
	for i in 3:
		var jid3: String = JUDGE_IDS[i]
		var card := ScoreCard.new()
		card.position = Vector2(sz.x * (0.19 + 0.31 * i) - 106, maxf(110.0 + GameManager.safe_top(), table_y - 0.76 * 420.0 - 150.0))
		card.size = Vector2(212, 142)
		card.visible = false
		add_child(card)
		cards[jid3] = card
	bubble_layer = Control.new()
	bubble_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble_layer)
	# üst çubuk
	var topbar := UIKit.hbox(10)
	topbar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	topbar.offset_top = 30 + GameManager.safe_top()
	topbar.offset_left = 16
	topbar.offset_right = -16
	add_child(topbar)
	top_label = UIKit.title("JÜRİ DEĞERLENDİRMESİ", 30, Color("#fff1a8"), UIKit.INK, 8)
	top_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topbar.add_child(top_label)
	var ff := UIKit.icon_button("fast", UIKit.CREAM, 64)
	ff.pressed.connect(func():
		_fast = true
		_skip = true
		GameManager.toast("Hızlı mod", UIKit.BLUE, "fast"))
	topbar.add_child(ff)
	# alt panel
	bottom = PanelContainer.new()
	var bs := UIKit.sb(UIKit.CREAM, 30, UIKit.INK, 5, 0, 18)
	bs.content_margin_bottom = 18 + GameManager.safe_bottom()
	bottom.add_theme_stylebox_override("panel", bs)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -(sz.y - table_y - 178)
	bottom.offset_left = 8
	bottom.offset_right = -8
	bottom.offset_bottom = 10
	add_child(bottom)
	panel_v = UIKit.vbox(10)
	bottom.add_child(panel_v)
	if res.get("mutations_cleared", false):
		GameManager.toast("Arındırma: jüri mutasyonları silindi!", Color("#ff7ab8"), "leaf")


func _wait(t: float) -> void:
	await get_tree().create_timer(t * (0.45 if _fast else 1.0)).timeout


func _clear_panel() -> void:
	for c in panel_v.get_children():
		c.queue_free()


func _say(text: String, size := 26, col := UIKit.INK) -> Label:
	var l := UIKit.wrap_label(text, size, col, true)
	panel_v.add_child(l)
	return l


# ------------------------------------------------------------------ akış
func _run() -> void:
	for who in res["order"]:
		await _present(who)
		await _taste(who)
		var r: Dictionary = res[who]
		if not r.get("mutation", {}).is_empty():
			await _mutation(r["mutation"])
		if r.get("argument", false):
			if who == "player":
				await _argument_player()
			else:
				await _argument_banter(r)
		await _totals(who)
		_hide_cards()
	await _summary()


func _present(who: String) -> void:
	var sz := GameManager.screen_size
	var r: Dictionary = res[who]
	_clear_panel()
	var is_player := who == "player"
	if is_player:
		contestant.setup(CharacterFigure.chef_spec(ProgressionManager.chef()))
	else:
		contestant.setup(CharacterFigure.preset(BattleManager.opponent["id"]))
	contestant.set_mutation("")
	contestant.visible = true
	var from_x := -200.0 if is_player else sz.x + 200.0
	var to_x := sz.x * 0.5
	var base_y := table_y + 250
	contestant.position = Vector2(from_x, base_y)
	contestant.set_pose("present")
	var dv := DishView.new()
	dv.setup(r["dish"], r["plate"], r["garnish"])
	dv.scale = Vector2(0.4, 0.4)
	contestant.hold(dv)
	var name_txt: String = ProgressionManager.d()["profile"].get("name", "Şef") if is_player else BattleManager.opponent["name"]
	top_label.text = "%s sunuyor" % name_txt
	_say("%s" % r["dish"]["name"], 32, UIKit.PURPLE)
	var desc: String = r["dish"].get("desc", "")
	if desc != "":
		_say(desc, 22, Color("#6a4a3a"))
	var tags := HFlowContainer.new()
	tags.add_theme_constant_override("h_separation", 6)
	tags.alignment = FlowContainer.ALIGNMENT_CENTER
	panel_v.add_child(tags)
	tags.add_child(UIKit.chip(IngredientDatabase.method_name(r["dish"].get("method", "")), KitchenStation.METHOD_COLORS.get(r["dish"].get("method", ""), UIKit.GRAY), 18))
	tags.add_child(UIKit.chip("Pişirme %%%d" % int(float(r["quality"]) * 100), UIKit.ORANGE, 18))
	if r.get("first", false):
		tags.add_child(UIKit.chip("İLK KEŞİF", UIKit.PINK, 18))
	if r["dish"].get("handcrafted", false):
		tags.add_child(UIKit.chip("ÖZEL TARİF", UIKit.PURPLE, 18))
	if r.get("living", "none") == "caught":
		tags.add_child(UIKit.chip("CANLI & YAKALANDI", UIKit.GREEN, 18))
	elif r.get("living", "none") == "escaped":
		tags.add_child(UIKit.chip("DAĞINIK (KAÇTI)", UIKit.RED, 18))
	if r.get("mystery_missing", false):
		tags.add_child(UIKit.chip("GİZEM KULLANILMADI", UIKit.RED, 18))
	if r.get("repeat", false):
		tags.add_child(UIKit.chip("TEKRAR", UIKit.GRAY, 18))
	for pen in r.get("penalized", []):
		tags.add_child(UIKit.chip("Geri tepme: " + SabotageSystem.ability(pen).get("name", ""), UIKit.RED, 18))
	AudioManager.sfx("whoosh")
	var tw := create_tween()
	tw.tween_property(contestant, "position:x", to_x, 0.6 * (0.5 if _fast else 1.0)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not is_player and BattleManager.ai:
		var gp := contestant.position + Vector2(0, -330 * 0.62)
		SpeechBubble.show_at(bubble_layer, gp, BattleManager.ai.line("taunt"), 1.6, 0.5)
		contestant.talk(1.2)
	contestant.hold(null)
	dish.setup(r["dish"], r["plate"], r["garnish"])
	dish.visible = true
	dish.rotation = 0.0
	dish.set_alive(r.get("living", "none") == "caught")
	dish.position = Vector2(to_x, base_y - 170)
	var tw2 := create_tween()
	tw2.tween_property(dish, "position", Vector2(sz.x * 0.5, table_y + 34), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw2.finished
	AudioManager.sfx("serve")
	contestant.set_pose("idle")
	var tw_out := create_tween()
	tw_out.tween_property(contestant, "position:x", from_x, 0.5 * (0.5 if _fast else 1.0)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw_out.tween_callback(func(): contestant.visible = false)
	if r.get("living", "none") == "escaped":
		await _living_chaos()
	elif r.get("living", "none") == "caught":
		var tw3 := dish.create_tween().set_loops(3)
		tw3.tween_property(dish, "position:y", table_y + 14, 0.15)
		tw3.tween_property(dish, "position:y", table_y + 34, 0.15)
		AudioManager.sfx("boing", 1.2)
	await _wait(0.6)


func _living_chaos() -> void:
	var target: String = JUDGE_IDS[randi() % 3]
	var jf: CharacterFigure = judges[target]
	var head := jf.position + Vector2(0, -300 * jf.scale.y)
	var home := dish.position
	dish.set_alive(true)
	AudioManager.sfx("boing")
	var tw := create_tween()
	tw.tween_property(dish, "position", head, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	jf.react("surprised")
	await _wait(0.6)
	var tw2 := create_tween()
	tw2.tween_property(dish, "position", home, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw2.parallel().tween_property(dish, "rotation", 0.18, 0.35)
	await tw2.finished
	dish.set_alive(false)


func _taste(who: String) -> void:
	var r: Dictionary = res[who]
	top_label.text = "Jüri tadıyor..."
	AudioManager.sfx("drumroll", 1.0, -6.0)
	for jid in JUDGE_IDS:
		var f: CharacterFigure = judges[jid]
		f.react("taste")
	await _wait(0.5)
	for jid in JUDGE_IDS:
		var f2: CharacterFigure = judges[jid]
		f2.react("chew")
	await _wait(1.2)
	_clear_panel()
	_say("Jüri yorumları", 26, UIKit.PURPLE)
	for i in 3:
		var jid2: String = JUDGE_IDS[i]
		var jr: Dictionary = r["judges"][jid2]
		var f3: CharacterFigure = judges[jid2]
		var reaction: String = jr.get("reaction", "cheer")
		var d := f3.react(reaction)
		var card: ScoreCard = cards[jid2]
		card.show_score(jr["score"], jr.get("reason", ""))
		AudioManager.sfx("score_big" if jr["score"] >= 9.0 else "tick", 1.0, 0.0 if jr["score"] >= 9.0 else -2.0)
		var line := UIKit.wrap_label("%s: \"%s\"" % [IngredientDatabase.judge_map[jid2]["name"], jr.get("quip", "")], 21, UIKit.INK, false, HORIZONTAL_ALIGNMENT_LEFT)
		panel_v.add_child(line)
		var gp := f3.position + Vector2(0, -250 * f3.scale.y)
		SpeechBubble.show_at(bubble_layer, gp, jr.get("quip", ""), 1.1 * (0.6 if _fast else 1.0), 0.0, Color.WHITE, 230)
		await _wait(minf(d, 1.3) + 0.2)
	await _wait(0.5)


func _hide_cards() -> void:
	for c in cards.values():
		c.visible = false


func _mutation(mu: Dictionary) -> void:
	var jid: String = mu["judge"]
	var mid: String = mu["mutation"]
	var f: CharacterFigure = judges[jid]
	await _wait(0.3)
	f.react("transform")
	await get_tree().create_timer(0.25).timeout
	f.set_mutation(mid)
	ProgressionManager.see_mutation(mid)
	var m: Dictionary = IngredientDatabase.mutations.get(mid, {})
	var layer := PanelContainer.new()
	layer.add_theme_stylebox_override("panel", UIKit.sb(Color("#2fbf71"), 26, UIKit.INK, 4, 0, 16))
	var v := UIKit.vbox(2)
	layer.add_child(v)
	v.add_child(UIKit.title("MUTASYON!", 44, Color.WHITE, UIKit.INK, 10))
	v.add_child(UIKit.outlined(UIKit.label("%s: %s" % [IngredientDatabase.judge_map[jid]["name"], m.get("name", mid)], 28, Color.WHITE), Color("#1f6b3a"), 6))
	var d := UIKit.wrap_label(m.get("desc", ""), 22, Color.WHITE, true)
	d.custom_minimum_size.x = 520
	v.add_child(UIKit.outlined(d, Color("#1f6b3a"), 5))
	if BattleManager.round_no < BattleManager.max_rounds and not BattleManager.persistent.has(jid):
		v.add_child(UIKit.outlined(UIKit.label("(Sonraki turdan itibaren etkili · %s)" % MutationSystem.CATEGORY_NAMES.get(m.get("category", ""), ""), 18, Color("#eaffdf")), Color("#1f6b3a"), 4))
	layer.z_index = 50
	add_child(layer)
	await get_tree().process_frame
	layer.position = Vector2((size.x - layer.size.x) * 0.5, table_y - 160)
	UIKit.pop_in(layer)
	await _wait(2.6)
	var tw := create_tween()
	tw.tween_property(layer, "modulate:a", 0.0, 0.25)
	tw.tween_callback(layer.queue_free)


func _argument_banter(r: Dictionary) -> void:
	var lo := ""
	var hi := ""
	for k in r["judges"].keys():
		if lo == "" or r["judges"][k]["score"] < r["judges"][lo]["score"]:
			lo = k
		if hi == "" or r["judges"][k]["score"] > r["judges"][hi]["score"]:
			hi = k
	_clear_panel()
	_say("TARTIŞMA ÇIKTI!", 34, UIKit.RED)
	await _judge_line(hi, IngredientDatabase.judge_map[hi].get("argue_high", ""))
	await _judge_line(lo, IngredientDatabase.judge_map[lo].get("argue_low", ""))
	_say("Rakip omuz silkti. Puanlar değişmedi.", 22, Color("#6a4a3a"))
	await _wait(1.0)


func _judge_line(jid: String, text: String) -> void:
	var f: CharacterFigure = judges[jid]
	f.talk(1.4)
	f.set_expression("angry" if "felaket" in text or "hakaret" in text or "ezber" in text else "laugh", 1.6)
	var gp := f.position + Vector2(0, -330 * f.scale.y)
	SpeechBubble.show_at(bubble_layer, gp + Vector2(0, 150), text, 2.0 * (0.6 if _fast else 1.0), 0.0, Color("#fff2c4"), 230)
	AudioManager.sfx_r("surprise" if randf() < 0.5 else "yuck", 0.1, -4.0)
	await _wait(1.5)


func _argument_player() -> void:
	var r: Dictionary = res["player"]
	var lo := ""
	var hi := ""
	for k in r["judges"].keys():
		if lo == "" or r["judges"][k]["score"] < r["judges"][lo]["score"]:
			lo = k
		if hi == "" or r["judges"][k]["score"] > r["judges"][hi]["score"]:
			hi = k
	_clear_panel()
	_say("JÜRİ BİRBİRİNE GİRDİ!", 34, UIKit.RED)
	await _judge_line(lo, IngredientDatabase.judge_map[lo].get("argue_low", ""))
	await _judge_line(hi, IngredientDatabase.judge_map[hi].get("argue_high", ""))
	var third := ""
	for k in JUDGE_IDS:
		if k != lo and k != hi:
			third = k
	if third != "":
		await _judge_line(third, "Ben ikinize de katılmıyorum!")
	_clear_panel()
	_say("Ne yapacaksın?", 30, UIKit.INK)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	panel_v.add_child(grid)
	var chosen := [""]
	var opts := [["Yemeği Savun", "defend", UIKit.BLUE], ["Tekrar Tattır", "retaste", UIKit.ORANGE], ["Tarifi Açıkla", "explain", UIKit.PURPLE], ["Tartışmayı Bitir", "end", UIKit.GRAY]]
	for o in opts:
		var b := UIKit.button(o[0], o[2], Vector2(0, 76), 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cid: String = o[1]
		b.pressed.connect(func(): chosen[0] = cid)
		grid.add_child(b)
	while chosen[0] == "":
		await get_tree().process_frame
	var out := BattleManager.apply_argument(chosen[0])
	_clear_panel()
	_say(out["text"], 24, UIKit.INK)
	var delta: Dictionary = out["delta"]
	for k in delta.keys():
		var dv: float = delta[k]
		if absf(dv) < 0.01:
			continue
		var card: ScoreCard = cards[k]
		card.show_score(r["judges"][k]["score"], r["judges"][k].get("reason", ""), dv)
		var f: CharacterFigure = judges[k]
		f.react("cheer" if dv > 0 else "disgust")
	AudioManager.sfx("unlock" if not delta.is_empty() else "tap")
	await _wait(1.8)


func _totals(who: String) -> void:
	var r: Dictionary = res[who]
	_clear_panel()
	var name_txt: String = "SEN" if who == "player" else BattleManager.opponent["name"]
	var tl := UIKit.title("%s: %s / 30" % [name_txt, UIKit.fmt(r["total"])], 40, Color("#ff9b3d") if who == "player" else Color("#a25cff"), UIKit.INK, 10)
	panel_v.add_child(tl)
	UIKit.pop_in(tl)
	AudioManager.sfx("coins" if r["total"] >= 20 else "tick")
	var ax: Dictionary = r["ev"]["axes"]
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	panel_v.add_child(grid)
	for k in JudgeSystem.AXES:
		var l := UIKit.label(JudgeSystem.AXIS_NAMES[k], 21, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT)
		l.custom_minimum_size.x = 150
		grid.add_child(l)
		var b := UIKit.bar(ax[k], 10.0, JudgeSystem.AXIS_COLORS[k], 20, 360)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
		grid.add_child(UIKit.label(UIKit.fmt(snappedf(ax[k], 0.1)), 21))
	await _wait(2.4)


func _summary() -> void:
	var p: Dictionary = res["player"]
	_clear_panel()
	var winner := BattleManager.finish_round()
	var last_round := BattleManager.is_over()
	if BattleManager.is_daily():
		top_label.text = "GÜNLÜK SKORUN"
		panel_v.add_child(UIKit.title(UIKit.fmt(p["total"]) + " / 30", 54, Color("#ff9b3d"), UIKit.INK, 12))
	else:
		top_label.text = "TUR %d SONUCU" % (BattleManager.round_no - 1)
		var row := UIKit.hbox(20)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		panel_v.add_child(row)
		row.add_child(UIKit.title("SEN %s" % UIKit.fmt(p["total"]), 38, Color("#ff9b3d"), UIKit.INK, 10))
		row.add_child(UIKit.title("–", 38, Color.WHITE, UIKit.INK, 10))
		row.add_child(UIKit.title("%s %s" % [UIKit.fmt(res["opp"]["total"]), BattleManager.opponent["name"].split(" ")[-1].to_upper()], 38, Color("#a25cff"), UIKit.INK, 10))
		var wt := "TURU KAZANDIN!" if winner == "player" else ("TURU KAYBETTİN" if winner == "opp" else "BERABERE!")
		var wl := UIKit.title(wt, 44, Color("#3ddc84") if winner == "player" else (Color("#ff6b6b") if winner == "opp" else Color("#ffd23f")), UIKit.INK, 12)
		panel_v.add_child(wl)
		UIKit.pop_in(wl)
		panel_v.add_child(UIKit.label("Toplam: Sen %s · Rakip %s" % [UIKit.fmt(BattleManager.player_total), UIKit.fmt(BattleManager.opp_total)], 24))
		if winner == "player":
			AudioManager.sfx("cheer")
			for f in judges.values():
				f.react("cheer")
		elif winner == "opp":
			AudioManager.sfx("aww")
	contestant.visible = false
	var btn := UIKit.button("SONUÇLAR" if last_round else "SONRAKİ TUR", UIKit.GREEN, Vector2(0, 88), 32, "arrow")
	panel_v.add_child(btn)
	await btn.pressed
	if last_round:
		BattleManager.finalize()
		GameManager.goto("results", {}, false)
	else:
		GameManager.goto("kitchen", {}, false)


func on_back() -> bool:
	_fast = true
	return true


# ------------------------------------------------------------------ iç sınıflar
class ScoreCard extends Control:
	var score := 0.0
	var reason := ""
	var delta := 0.0
	var _lbl: Label
	var _rsn: Label

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 20

	func show_score(s: float, r: String, d := 0.0) -> void:
		score = s
		reason = r
		delta = d
		visible = true
		if _lbl == null:
			_lbl = UIKit.title("", 54, Color.WHITE, UIKit.INK, 12)
			_lbl.position = Vector2(0, 2)
			_lbl.size = Vector2(size.x, 64)
			add_child(_lbl)
			_rsn = UIKit.wrap_label("", 15, UIKit.INK, true)
			_rsn.position = Vector2(8, 68)
			_rsn.size = Vector2(size.x - 16, 70)
			_rsn.max_lines_visible = 3
			add_child(_rsn)
		_lbl.text = UIKit.fmt(s)
		var col := Color("#3ddc84") if s >= 7.5 else (Color("#ffd23f") if s >= 4.5 else Color("#ff6b6b"))
		_lbl.add_theme_color_override("font_color", col)
		_rsn.text = r
		if d != 0.0:
			_rsn.text = ("+%s" % UIKit.fmt(d) if d > 0 else UIKit.fmt(d)) + "  " + r
		pivot_offset = Vector2(size.x * 0.5, size.y * 0.5)
		scale = Vector2(1.0, 0.0)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		DrawKit.shadow(self, Vector2(size.x * 0.5, size.y + 4), size.x * 0.5, 12, 0.3)
		DrawKit.shape(self, DrawKit.rrect(r, 18), Color("#fff7ea"), 4.0, 0.05)
		DrawKit.fill(self, DrawKit.rrect(Rect2(6, 6, size.x - 12, 58), 14), Color("#3b2457"))


class JudgeTable extends Control:
	var top := 500.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var top_r := PackedVector2Array([Vector2(20, top), Vector2(w - 20, top), Vector2(w + 10, top + 40), Vector2(-10, top + 40)])
		DrawKit.shape(self, top_r, Color("#fbf6ee"), 4.0, 0.08)
		var front := Rect2(-10, top + 38, w + 20, 130)
		DrawKit.shape(self, DrawKit.rrect(front, 6), Color("#c4223a"), 4.0, 0.2)
		var scal := PackedVector2Array()
		for i in 25:
			var x := -10.0 + (w + 20) * i / 24.0
			scal.append(Vector2(x, top + 52 + (10.0 if i % 2 == 1 else 0.0)))
		scal.append(Vector2(w + 10, top + 38))
		scal.append(Vector2(-10, top + 38))
		DrawKit.fill(self, scal, Color("#fbf6ee"))
		draw_line(Vector2(-10, top + 150), Vector2(w + 10, top + 150), Color("#f2c14e"), 6.0, true)
