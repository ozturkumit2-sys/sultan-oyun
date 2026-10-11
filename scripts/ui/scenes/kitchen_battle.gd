extends Control
## KitchenBattle — yarışma mutfağı. Tur akışı: tanıtım → (hırsızlık sabotajı) → malzeme seçimi & füzyon →
## (pişirme öncesi sabotaj) → pişirme mini oyunu → yemek ortaya çıkar → (canlı yemek kaçışı) →
## (yerçekimi sabotajı) → sunum → (arındırma sabotajı) → jüriye.

const SCENE_H := 410.0

var station: KitchenStation
var scene_area: Control
var backdrop: Backdrop
var player_fig: CharacterFigure
var opp_fig: CharacterFigure
var opp_ctrl: CharacterAnimationController
var player_ctrl: CharacterAnimationController
var assistant: DishView
var dish_view: DishView
var opp_pot: DishView
var timer_ring: TimerRing
var round_label: Label
var round_sub: Label
var theme_name: Label
var theme_desc: Label
var chips_row: HFlowContainer
var score_label: Label
var phase := "intro"
var timer_left := 120.0
var timer_on := false
var _tick_last := -1
var _dish: Dictionary = {}
var _tutorial := false
var _tut_bubble: Control
var _last_inputs: Array = []
var _bubble_layer: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if not BattleManager.active:
		BattleManager.start_career("l1_m1")
	_build()
	AudioManager.music("boss" if BattleManager.match_data.get("boss", false) else "battle")
	_tutorial = not ProgressionManager.tutorial_done("kitchen") and not BattleManager.is_daily()
	if BattleManager.round_no == 1:
		await _vs_intro()
	_start_round()


# ------------------------------------------------------------------ arayüz kurulumu
func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#2a1b3d")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 0)
	add_child(v)
	# --- üst bilgi
	var hud := PanelContainer.new()
	var hs := UIKit.sb(Color("#3b2457"), 0, Color("#1f1033"), 0, 0, 12)
	hs.content_margin_top = 8 + GameManager.safe_top()
	hs.content_margin_bottom = 10
	hud.add_theme_stylebox_override("panel", hs)
	v.add_child(hud)
	var hv := UIKit.vbox(6)
	hud.add_child(hv)
	var r1 := UIKit.hbox(10)
	hv.add_child(r1)
	var pause := UIKit.icon_button("pause", UIKit.CREAM, 64)
	pause.pressed.connect(_pause_menu)
	r1.add_child(pause)
	var rv := UIKit.vbox(-6)
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r1.add_child(rv)
	round_label = UIKit.title(Loc.t("TUR 1/3"), 34, Color.WHITE, UIKit.INK, 8)
	rv.add_child(round_label)
	round_sub = UIKit.label("", 22, Color("#ffd23f"))
	rv.add_child(round_sub)
	timer_ring = TimerRing.new()
	timer_ring.custom_minimum_size = Vector2(76, 76)
	r1.add_child(timer_ring)
	var tcard := PanelContainer.new()
	tcard.add_theme_stylebox_override("panel", UIKit.sb(Color("#fff2c4"), 18, UIKit.INK, 3, 0, 12))
	hv.add_child(tcard)
	var tv := UIKit.vbox(0)
	tcard.add_child(tv)
	var trow := UIKit.hbox(8)
	tv.add_child(trow)
	trow.add_child(UIKit.label(Loc.t("TEMA:"), 22, Color("#a25cff")))
	theme_name = UIKit.label("", 26, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT)
	theme_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trow.add_child(theme_name)
	score_label = UIKit.label("", 21, Color("#8a4a2a"), true, HORIZONTAL_ALIGNMENT_RIGHT)
	trow.add_child(score_label)
	theme_desc = UIKit.label("", 19, Color("#6a4a3a"), false, HORIZONTAL_ALIGNMENT_LEFT)
	theme_desc.clip_text = true
	theme_desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(theme_desc)
	chips_row = HFlowContainer.new()
	chips_row.add_theme_constant_override("h_separation", 6)
	chips_row.add_theme_constant_override("v_separation", 4)
	tv.add_child(chips_row)
	# --- sahne
	scene_area = Control.new()
	scene_area.layout_direction = Control.LAYOUT_DIRECTION_LTR
	scene_area.custom_minimum_size = Vector2(0, SCENE_H)
	scene_area.clip_contents = true
	v.add_child(scene_area)
	backdrop = Backdrop.new()
	backdrop.kind = "kitchen"
	backdrop.counter_y = SCENE_H - 74
	scene_area.add_child(backdrop)
	var chars := Node2D.new()
	scene_area.add_child(chars)
	var w := GameManager.screen_size.x
	player_fig = CharacterFigure.new()
	player_fig.setup(CharacterFigure.chef_spec(ProgressionManager.chef()))
	player_fig.scale = Vector2(0.8, 0.8)
	player_fig.position = Vector2(w * 0.27, SCENE_H - 28)
	chars.add_child(player_fig)
	if not BattleManager.is_daily():
		opp_fig = CharacterFigure.new()
		opp_fig.setup(CharacterFigure.preset(BattleManager.opponent["id"]))
		opp_fig.scale = Vector2(0.64, 0.64)
		opp_fig.position = Vector2(w * 0.8, SCENE_H - 44)
		chars.add_child(opp_fig)
		opp_fig.set_pose("stir")
	# tezgâhın önü (karakterlerin alt kısmını örter)
	var counter_front := CounterFront.new()
	counter_front.top_y = SCENE_H - 74
	counter_front.color = backdrop.counter_color
	counter_front.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene_area.add_child(counter_front)
	if not BattleManager.is_daily():
		opp_pot = DishView.new()
		var pot_col := "#7cff6b" if BattleManager.opponent.get("id", "") in ["morgana", "zorp", "gulizar"] else "#ff9b3d"
		opp_pot.setup({"visual": {"base": "soup", "c1": pot_col, "c2": "#ffffff", "decor": ["steam", "bubbles"]}})
		opp_pot.scale = Vector2(0.48, 0.48)
		opp_pot.position = Vector2(w * 0.8, SCENE_H - 66)
		scene_area.add_child(opp_pot)
	if BattleManager.is_daily():
		var sign := UIKit.panel(Color("#2f3b2f"), 16, Color("#8a5a3b"), 8, 12)
		var sv := UIKit.vbox(0)
		sign.add_child(sv)
		sv.add_child(UIKit.label(Loc.t("GÜNÜN"), 24, Color("#fff1a8")))
		sv.add_child(UIKit.label(Loc.t("MEYDAN OKUMASI"), 22, Color.WHITE))
		sv.add_child(UIKit.label(DailyChallengeManager.today_key(), 18, Color("#c9e0c9")))
		sign.position = Vector2(w * 0.62, SCENE_H * 0.18)
		sign.rotation = 0.05
		scene_area.add_child(sign)
	var asst := ProgressionManager.assistant()
	if asst != "":
		assistant = DishView.new()
		assistant.setup(DishView.companion(asst))
		assistant.set_alive(true)
		assistant.scale = Vector2(0.42, 0.42)
		assistant.position = Vector2(w * 0.08, SCENE_H - 70)
		scene_area.add_child(assistant)
		var tw := assistant.create_tween().set_loops()
		tw.tween_property(assistant, "position:y", SCENE_H - 92, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(assistant, "position:y", SCENE_H - 70, 0.5).set_trans(Tween.TRANS_SINE)
	dish_view = DishView.new()
	dish_view.scale = Vector2(0.72, 0.72)
	dish_view.position = Vector2(w * 0.53, SCENE_H - 56)
	dish_view.visible = false
	scene_area.add_child(dish_view)
	_bubble_layer = Control.new()
	_bubble_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bubble_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(_bubble_layer)
	if opp_fig:
		opp_ctrl = CharacterAnimationController.attach(opp_fig, _bubble_layer, BattleManager.opponent.get("taunt", []))
		opp_ctrl.talk_tail = 0.6
		opp_ctrl.bubble_offset = Vector2(-150, -330)
		opp_ctrl.active = false
	player_ctrl = CharacterAnimationController.attach(player_fig, _bubble_layer, [])
	player_ctrl.talk_tail = -0.6
	player_ctrl.bubble_offset = Vector2(140, -270)
	player_ctrl.interval = Vector2(9.0, 15.0)
	# --- çalışma paneli
	var work := PanelContainer.new()
	var ws := UIKit.sb(UIKit.CREAM, 0, UIKit.INK, 0, 0, 12)
	ws.content_margin_top = 12
	ws.content_margin_bottom = 10 + GameManager.safe_bottom()
	ws.border_width_top = 5
	ws.border_color = UIKit.INK
	work.add_theme_stylebox_override("panel", ws)
	work.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(work)
	station = KitchenStation.new()
	station.mode = "daily" if BattleManager.is_daily() else "battle"
	work.add_child(station)
	station.cook_requested.connect(_on_cook)
	station.fused.connect(_on_fused)
	station.plating_changed.connect(_on_plating)
	station.serve_requested.connect(_on_serve)
	station.bowl_changed.connect(_on_bowl_changed)


# ------------------------------------------------------------------ tanıtım
func _vs_intro() -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = 90
	add_child(layer)
	var bd := Backdrop.new()
	bd.kind = "sunburst"
	bd.c1 = Color("#ff5fa2") if not BattleManager.match_data.get("boss", false) else Color("#7c3bd6")
	bd.c2 = Color("#7c3bd6") if not BattleManager.match_data.get("boss", false) else Color("#1f1033")
	layer.add_child(bd)
	var sz := GameManager.screen_size
	var holder := Node2D.new()
	layer.add_child(holder)
	var pf := CharacterFigure.new()
	pf.setup(CharacterFigure.chef_spec(ProgressionManager.chef()))
	pf.scale = Vector2(0.9, 0.9)
	pf.position = Vector2(-300, sz.y * 0.5)
	holder.add_child(pf)
	var pf_x := sz.x * (0.5 if BattleManager.is_daily() else 0.25)
	var of: CharacterFigure = null
	var title_text := Loc.t("GÜNLÜK MEYDAN OKUMA")
	if not BattleManager.is_daily():
		of = CharacterFigure.new()
		of.setup(CharacterFigure.preset(BattleManager.opponent["id"]))
		of.scale = Vector2(0.9, 0.9)
		of.position = Vector2(sz.x + 300, sz.y * 0.5)
		holder.add_child(of)
		title_text = BattleManager.league.get("name", "")
	var box := UIKit.vbox(10)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 40 + GameManager.safe_top()
	box.offset_left = 20
	box.offset_right = -20
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(box)
	box.add_child(UIKit.title(title_text, 36, Color("#fff1a8"), UIKit.INK, 10))
	if of != null:
		var mi: int = int(BattleManager.match_data.get("index", 0)) + 1
		box.add_child(UIKit.title(Loc.t("MAÇ %d%s") % [mi, Loc.t("  ·  BOSS") if BattleManager.match_data.get("boss", false) else ""], 30, Color.WHITE, UIKit.INK, 8))
		if BattleManager.rematch != "":
			var rv := BattleManager.rematch == "revenge"
			var badge := UIKit.title(Loc.t("İNTİKAM MAÇI!") if rv else Loc.t("RÖVANŞ!"), 34, Color("#ff5a6e") if rv else Color("#ffd23f"), UIKit.INK, 10)
			box.add_child(badge)
			badge.pivot_offset = Vector2(GameManager.screen_size.x * 0.5 - 20, 24)
			var btw := badge.create_tween().set_loops(4)
			btw.tween_property(badge, "scale", Vector2(1.08, 1.08), 0.25)
			btw.tween_property(badge, "scale", Vector2.ONE, 0.25)
	var vs := UIKit.title("VS" if of != null else "", 120, Color("#ffd23f"), UIKit.INK, 22)
	vs.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vs.position = Vector2(sz.x * 0.5 - 150, sz.y * 0.28)
	vs.size = Vector2(300, 140)
	vs.pivot_offset = Vector2(150, 70)
	vs.scale = Vector2.ZERO
	layer.add_child(vs)
	var info := UIKit.vbox(8)
	info.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_top = -330 - GameManager.safe_bottom()
	info.offset_left = 24
	info.offset_right = -24
	info.grow_vertical = Control.GROW_DIRECTION_BEGIN
	layer.add_child(info)
	var p := UIKit.panel(UIKit.CREAM, 28, UIKit.INK, 4, 18)
	info.add_child(p)
	var pv := UIKit.vbox(6)
	p.add_child(pv)
	if of != null:
		var o: Dictionary = BattleManager.opponent
		pv.add_child(UIKit.label(Loc.t("%s — %s") % [o["name"], o.get("title", "")], 28, UIKit.INK))
		if BattleManager.rematch != "":
			var rv2 := BattleManager.rematch == "revenge"
			pv.add_child(UIKit.wrap_label(Loc.t("Rakip geçen seferki yenilginin hesabını sormaya geldi: bu sefer daha güçlü!") if rv2
				else Loc.t("Geçen sefer kaybettin. Kazanırsan rövanş bonusu senin!"), 21, Color("#e0244f"), true))
		pv.add_child(UIKit.wrap_label(o.get("personality", ""), 21))
		var ab: Dictionary = o.get("ability", {})
		pv.add_child(UIKit.wrap_label(Loc.t("Özel yetenek: %s — %s") % [ab.get("name", ""), ab.get("desc", "")], 21, Color("#a23a5a"), true))
		var rules_row := HFlowContainer.new()
		rules_row.add_theme_constant_override("h_separation", 6)
		for r in BattleManager.rules:
			var rd: Dictionary = IngredientDatabase.rules.get(r, {})
			if not rd.is_empty():
				rules_row.add_child(UIKit.chip(rd["name"], UIKit.PURPLE, 18))
		pv.add_child(rules_row)
	else:
		var ch: Dictionary = BattleManager.daily
		var cond: Dictionary = ch.get("condition", {})
		pv.add_child(UIKit.label(Loc.t("Tek tur · Hedef %s puan") % UIKit.fmt(float(ch.get("target", 18))), 28))
		pv.add_child(UIKit.wrap_label(Loc.t("%s bugün %s!") % [IngredientDatabase.judge_map[cond["judge"]]["name"], MutationSystem.mutation_name(cond["mutation"])], 22, Color("#a23a5a"), true))
	var go := UIKit.button(Loc.t("BAŞLA!"), UIKit.GREEN, Vector2(0, 90), 36, "play")
	info.add_child(go)
	var tw := create_tween()
	tw.tween_property(pf, "position:x", pf_x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if of != null:
		tw.parallel().tween_property(of, "position:x", sz.x * 0.75, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(vs, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	AudioManager.sfx("whoosh")
	await tw.finished
	AudioManager.sfx("score_big")
	if of != null:
		of.react("smug")
		var lines: Array = BattleManager.opponent.get("intro", [])
		var intro_line: String = BattleManager.rematch_line() if BattleManager.rematch != "" else (str(lines[0]) if not lines.is_empty() else "")
		if intro_line != "":
			SpeechBubble.show_at(layer, Vector2(sz.x * 0.75, sz.y * 0.5 - 300 * 0.9), intro_line, 3.0, 0.4)
			of.talk(2.0)
	pf.react("cheer")
	await go.pressed
	var tw2 := create_tween()
	tw2.tween_property(layer, "modulate:a", 0.0, 0.25)
	await tw2.finished
	layer.queue_free()


# ------------------------------------------------------------------ tur
func _start_round() -> void:
	phase = "intro"
	var cur := BattleManager.begin_round()
	station.reset_for_round()
	station.max_slots = 3 if (ProgressionManager.has_third_slot() or BattleManager.is_daily()) else 2
	station.banned = BattleManager.banned_methods()
	station.fusion_limit = ProgressionManager.max_fusions_per_round()
	_refresh_pantry()
	dish_view.visible = false
	player_fig.set_pose("idle")
	player_fig.set_expression(player_fig.spec.get("expression", "happy"))
	_update_hud()
	timer_left = BattleManager.round_time()
	timer_ring.total = timer_left
	timer_ring.left = timer_left
	station.locked = true
	await _round_banner(cur)
	await _run_sabotages("round_start")
	_refresh_pantry()
	station.locked = false
	phase = "select"
	timer_on = true
	if opp_ctrl:
		opp_ctrl.active = true
	if _tutorial:
		_tut(Loc.t("Kilerdeki malzemelere dokunarak kaseye ekle. İpucu: Kurbağa Özü + Şeker = ?"))


func _refresh_pantry() -> void:
	var p := BattleManager.player_pantry()
	station.set_pantry(p["ingredients"], p["fusions"], BattleManager.cur.get("mystery", ""), BattleManager.cur.get("stolen", ""))


func _update_hud() -> void:
	var cur: Dictionary = BattleManager.cur
	if BattleManager.is_daily():
		round_label.text = Loc.t("GÜNLÜK")
	else:
		round_label.text = Loc.t("TUR %d/%d") % [BattleManager.round_no, BattleManager.max_rounds]
	round_sub.text = BattleManager.round_title()
	var th: Dictionary = cur.get("theme", {})
	theme_name.text = th.get("name", "")
	theme_desc.text = th.get("desc", "")
	for c in chips_row.get_children():
		c.queue_free()
	var target: Dictionary = th.get("target", {})
	for k in target.keys():
		var rng: Array = target[k]
		var nm: String = Loc.t(str(IngredientDatabase.STAT_NAMES.get(k, k)))
		var txt := Loc.t("%s %d+") % [nm, int(rng[0])] if float(rng[0]) > 0 else Loc.t("%s ≤%d") % [nm, int(rng[1])]
		if float(rng[0]) > 0 and float(rng[1]) < 100:
			txt = Loc.t("%s %d-%d") % [nm, int(rng[0]), int(rng[1])]
		chips_row.add_child(UIKit.chip(txt, IngredientDatabase.STAT_COLORS.get(k, UIKit.ORANGE), 16))
	for m in th.get("methods", []):
		chips_row.add_child(UIKit.chip(IngredientDatabase.method_name(m), KitchenStation.METHOD_COLORS.get(m, UIKit.GRAY), 16))
	var mys: String = cur.get("mystery", "")
	if mys != "":
		chips_row.add_child(UIKit.chip(Loc.t("Gizem: %s") % FusionEngine.item(mys)["name"], UIKit.PURPLE, 16))
	for j in BattleManager.mutations.keys():
		chips_row.add_child(UIKit.chip(Loc.t("%s: %s") % [IngredientDatabase.judge_map[j]["name"].split(" ")[-1], MutationSystem.mutation_name(BattleManager.mutations[j])], Color("#2fbf71"), 16))
	if BattleManager.is_daily():
		score_label.text = Loc.t("Hedef %s") % UIKit.fmt(float(BattleManager.daily.get("target", 18)))
	else:
		score_label.text = Loc.t("Sen %s · %s %s") % [UIKit.fmt(BattleManager.player_total), UIKit.fmt(BattleManager.opp_total), BattleManager.opponent["name"].split(" ")[-1]]


func _round_banner(cur: Dictionary) -> void:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.z_index = 60
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.05, 0.15, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var p := UIKit.panel(Color("#fff2c4"), 34, UIKit.INK, 5, 24)
	p.custom_minimum_size = Vector2(minf(620, GameManager.screen_size.x - 40), 0)
	center.add_child(p)
	var v := UIKit.vbox(10)
	p.add_child(v)
	var big := Loc.t("GÜNLÜK MEYDAN OKUMA") if BattleManager.is_daily() else Loc.t("TUR %d") % BattleManager.round_no
	v.add_child(UIKit.title(big, 58, Color("#ff9b3d"), UIKit.INK, 14))
	v.add_child(UIKit.label(BattleManager.round_title(), 30, UIKit.PURPLE))
	var th: Dictionary = cur.get("theme", {})
	v.add_child(UIKit.label(Loc.t("Tema: %s") % th.get("name", ""), 34, UIKit.INK))
	v.add_child(UIKit.wrap_label(th.get("desc", ""), 24))
	var mys: String = cur.get("mystery", "")
	if mys != "":
		var row := UIKit.hbox(10)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := IngredientIcon.new()
		ic.custom_minimum_size = Vector2(90, 90)
		ic.set_item(mys)
		row.add_child(ic)
		var mv := UIKit.vbox(0)
		mv.add_child(UIKit.label(Loc.t("GİZEMLİ MALZEME"), 22, UIKit.PURPLE))
		mv.add_child(UIKit.label(FusionEngine.item(mys)["name"], 30, UIKit.INK))
		mv.add_child(UIKit.label(Loc.t("Yemeğinde kullanmalısın!"), 20, Color("#a23a5a")))
		row.add_child(mv)
		v.add_child(row)
		AudioManager.sfx("magic")
	v.add_child(UIKit.label(Loc.t("Devam etmek için dokun"), 20, Color("#8a6a50"), false))
	UIKit.pop_in(p)
	AudioManager.sfx("score_big" if BattleManager.round_no == 3 else "whoosh")
	var tapped := [false]
	layer.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			tapped[0] = true)
	var t := 0.0
	while not tapped[0] and t < 4.5:
		if not is_inside_tree():
			return
		await get_tree().process_frame
		t += get_process_delta_time()
	var tw := create_tween()
	tw.tween_property(layer, "modulate:a", 0.0, 0.2)
	await tw.finished
	layer.queue_free()
	if opp_ctrl and BattleManager.round_no > 1:
		opp_ctrl.say(BattleManager.ai.line("taunt"))


# ------------------------------------------------------------------ zamanlayıcı
func _process(delta: float) -> void:
	if not timer_on:
		timer_ring.paused = phase != "select" and phase != "plating"
		return
	if get_tree().get_nodes_in_group("modal").size() > 0:
		timer_ring.paused = true
		return
	timer_ring.paused = false
	timer_left = maxf(0.0, timer_left - delta)
	timer_ring.left = timer_left
	var sec := int(ceil(timer_left))
	if sec <= 10 and sec != _tick_last and sec > 0:
		_tick_last = sec
		AudioManager.sfx("tick", 1.3 if sec <= 5 else 1.0)
	if timer_left <= 0.0:
		timer_on = false
		_on_timeout()


func _on_timeout() -> void:
	AudioManager.sfx("timeout")
	GameManager.toast(Loc.t("Süre doldu!"), UIKit.RED, "clock")
	if phase == "select":
		var inputs: Array = station.slots.duplicate()
		var p := BattleManager.player_pantry()
		var pool: Array = p["ingredients"]
		var mys: String = BattleManager.cur.get("mystery", "")
		if inputs.is_empty():
			if mys != "":
				inputs.append(mys)
			for id in pool:
				if inputs.size() >= 2:
					break
				if not inputs.has(id):
					inputs.append(id)
		var m := station.method
		if m == "" or BattleManager.banned_methods().has(m):
			for mm in KitchenStation.METHODS:
				if not BattleManager.banned_methods().has(mm):
					m = mm
					break
		_cook(inputs, m, 0.45)
	elif phase == "plating":
		var pl := station.current_plating()
		_on_serve(pl[0], pl[1])


# ------------------------------------------------------------------ kiler olayları
func _on_bowl_changed() -> void:
	if _tutorial and phase == "select" and station.slots.size() >= 2:
		_tut(Loc.t("Harika! KARIŞTIR ile füzyon yap ya da bir yöntem seçip PİŞİR'e bas."))


func _on_fused(it: Dictionary, is_new: bool) -> void:
	if is_new:
		_banner(Loc.t("YENİ FÜZYON!"), it["name"], UIKit.PURPLE)
		if opp_fig and randf() < 0.6:
			opp_fig.react("surprised")
	player_fig.react("jump")


# ------------------------------------------------------------------ pişirme
func _on_cook(inputs: Array, method: String) -> void:
	if phase != "select":
		return
	var probe := FusionEngine.cook(inputs, method)
	if not BattleManager.mystery_ok(probe):
		var m := UIKit.modal(self, Loc.t("Gizem Unutuldu!"), Loc.t("Bu turun gizemli malzemesi (%s) yemeğinde yok. Tema puanın düşer. Yine de pişirilsin mi?") % FusionEngine.item(BattleManager.cur["mystery"])["name"],
			[[Loc.t("Geri Dön"), "no", UIKit.GRAY], [Loc.t("Pişir"), "yes", UIKit.ORANGE]])
		var ch: String = await m.closed
		if ch != "yes":
			return
	_cook(inputs, method, -1.0)


func _cook(inputs: Array, method: String, forced_q: float) -> void:
	phase = "cooking"
	timer_on = false
	station.locked = true
	if opp_ctrl:
		opp_ctrl.active = false
	_last_inputs = inputs
	_clear_tut()
	player_fig.set_pose("stir")
	await _run_sabotages("before_cook")
	var mods := BattleManager.cooking_mods()
	var q := 0.7
	if forced_q >= 0.0:
		q = forced_q
	elif mods.has("auto"):
		q = float(mods["auto"])
		GameManager.toast(Loc.t("Otomatik pişirme: kalite %%%d") % int(q * 100), UIKit.BLUE, "gear")
		AudioManager.sfx("robot")
		await get_tree().create_timer(0.8).timeout
	else:
		if mods.has("dark"):
			backdrop.dark = 0.6 * float(mods["dark"])
			backdrop.queue_redraw()
		var mg := CookingMinigame.new()
		add_child(mg)
		mg.start(method, mods)
		q = await mg.finished
		backdrop.dark = 0.0
		backdrop.queue_redraw()
	var dish := FusionEngine.cook(inputs, method)
	var first := RecipeBookManager.discover(dish, "battle")
	dish = BattleManager.apply_phase("before_cook", dish)
	BattleManager.set_player_dish(dish, q, first)
	if q >= 0.95:
		ProgressionManager.add_stat("perfect_cooks")
	_dish = dish
	player_fig.set_pose("idle")
	await _reveal_dish(dish, first, q)
	if str(dish.get("living", "")) != "":
		await _living(dish)
	await _run_sabotages("before_plating")
	_dish = BattleManager.apply_phase("before_plating", _dish)
	BattleManager.set_player_dish_only(_dish)
	phase = "plating"
	station.show_plating(true)
	station.locked = false
	timer_on = timer_left > 0.0
	if opp_ctrl:
		opp_ctrl.active = true
	if _tutorial:
		_tut(Loc.t("Tabak ve süsleme seç: temaya ve yemeğe uyanlar sunum puanını artırır!"))


func _reveal_dish(dish: Dictionary, first: bool, q: float) -> void:
	dish_view.setup(dish, "", "none")
	dish_view.visible = true
	dish_view.set_alive(false)
	dish_view.scale = Vector2(0.1, 0.1)
	var tw := create_tween()
	tw.tween_property(dish_view, "scale", Vector2(0.72, 0.72), 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	FxBurst.spawn(scene_area, dish_view.position + Vector2(0, -50), "puff", 14, Color(1, 1, 1))
	FxBurst.spawn(scene_area, dish_view.position + Vector2(0, -50), "sparkles", 12, Color("#ffd23f"))
	AudioManager.sfx("discover" if first else "pop")
	if first:
		_banner(Loc.t("YENİ TARİF!") if not dish.get("secret", false) else Loc.t("GİZLİ TARİF!"), dish["name"], UIKit.PINK)
		player_fig.react("cheer")
		if opp_fig:
			opp_fig.react("surprised")
	else:
		_banner(dish["name"], Loc.t("Pişirme: %%%d") % int(q * 100), UIKit.ORANGE)
		player_fig.react("smug" if q >= 0.8 else "jump")
	if dish.get("tainted", "") != "" or dish.get("tags", []).has("cursed"):
		FxBurst.spawn(scene_area, dish_view.position + Vector2(0, -60), "smoke", 10, Color(0.6, 0.9, 0.4))
	await get_tree().create_timer(1.3 if not GameManager.fast() else 0.6).timeout


func _living(dish: Dictionary) -> void:
	dish_view.set_alive(true)
	AudioManager.sfx("boing")
	if opp_fig:
		opp_fig.react("surprised")
	await get_tree().create_timer(0.5).timeout
	dish_view.visible = false
	var lf := LivingFoodController.new()
	add_child(lf)
	lf.start(dish, dish["living"])
	var res: String = await lf.resolved
	BattleManager.set_living(res)
	dish_view.visible = true
	if res == "caught":
		dish_view.face_mood = "scared"
		player_fig.react("cheer")
	else:
		dish_view.face_mood = "happy"
		dish_view.rotation = 0.15
		player_fig.react("sad")
		if opp_fig:
			opp_fig.react("laugh")
	dish_view.redraw()


func _on_plating(plate: String, garnish: String) -> void:
	if phase != "plating":
		return
	dish_view.setup(_dish, plate, garnish)
	dish_view.set_alive(str(_dish.get("living", "")) != "" and BattleManager.cur["player"].get("living", "none") == "caught")


func _on_serve(plate: String, garnish: String) -> void:
	if phase != "plating":
		return
	phase = "serving"
	timer_on = false
	station.locked = true
	_clear_tut()
	BattleManager.set_plating(plate, garnish)
	await _run_sabotages("before_judging")
	_dish = BattleManager.apply_phase("before_judging", _dish)
	BattleManager.set_player_dish_only(_dish)
	dish_view.setup(_dish, plate, garnish)
	AudioManager.sfx("serve")
	player_fig.set_pose("present")
	player_fig.set_expression("grin", 1.0)
	if _tutorial:
		ProgressionManager.set_tutorial_done("kitchen")
		_tutorial = false
	if opp_ctrl:
		opp_ctrl.active = false
	var tw := create_tween()
	tw.tween_property(dish_view, "position:y", dish_view.position.y - 30, 0.25)
	tw.tween_property(dish_view, "position:y", dish_view.position.y, 0.2)
	await get_tree().create_timer(0.7).timeout
	GameManager.goto("judging")


# ------------------------------------------------------------------ sabotaj
func _run_sabotages(ph: String) -> void:
	for ab in BattleManager.sabotages_for_phase(ph):
		if opp_fig:
			opp_fig.set_pose("cast")
			opp_fig.set_expression("evil", 2.0)
			FxBurst.spawn(scene_area, opp_fig.position + Vector2(40, -240), "sparkles", 14, Color(SabotageSystem.ability(ab).get("color", "#ff4f5e")))
		AudioManager.sfx(_ability_sound(ab))
		await get_tree().create_timer(0.5).timeout
		var target := BattleManager.theft_target() if ab == "ingredient_theft" else ""
		var dlg := SabotageDialog.new()
		add_child(dlg)
		dlg.open(ab, BattleManager.opponent, target)
		var res: Dictionary = await dlg.done
		if opp_fig:
			opp_fig.set_pose("stir")
		await _sabotage_feedback(ab, res)


func _ability_sound(ab: String) -> String:
	match ab:
		"hex":
			return "hex"
		"precision_lock":
			return "robot"
		"rotten_surprise":
			return "jar"
		"midnight_kitchen":
			return "dark"
		"ingredient_theft":
			return "steal"
		"gravity_shift":
			return "gravity"
		"purify":
			return "purify"
		"confetti_prank":
			return "pop"
		"tail_whip":
			return "boing"
		"smoke_bomb":
			return "whoosh"
		"blizzard":
			return "freeze"
		"ancient_curse":
			return "ghost"
		"palace_protocol":
			return "page"
		"dragon_breath":
			return "sizzle"
	return "warning"


func _sabotage_feedback(ab: String, res: Dictionary) -> void:
	var result: String = res["result"]
	var col := UIKit.GREEN if result in ["blocked", "reflected", "backfire"] else (UIKit.ORANGE if result in ["half", "adapt"] else UIKit.RED)
	GameManager.toast(res["text"], col, "shield" if result in ["blocked", "reflected"] else ("fire" if result == "backfire" else "info"))
	match result:
		"blocked":
			AudioManager.sfx("shield")
			player_fig.react("smug")
			FxBurst.spawn(scene_area, player_fig.position + Vector2(0, -200), "sparkles", 16, Color("#8fb4ff"))
		"reflected", "backfire":
			AudioManager.sfx("backfire")
			if opp_fig:
				opp_fig.react("hit")
				var line: String = BattleManager.opponent.get("backfire", "")
				if line != "":
					opp_ctrl.say(line, 2.6)
			player_fig.react("laugh")
			ProgressionManager.unlock_achievement("backfire")
		"full", "half":
			player_fig.react("surprised")
			if opp_fig:
				opp_fig.react("laugh")
		"adapt":
			player_fig.react("smug")
	if ab == "ingredient_theft" and BattleManager.cur.get("stolen", "") != "":
		GameManager.toast(Loc.t("Çalındı: %s") % FusionEngine.item(BattleManager.cur["stolen"])["name"], UIKit.ORANGE, "cross")
	if ab == "tail_whip" and not BattleManager.cur.get("knocked", []).is_empty():
		var names: Array = []
		for k in BattleManager.cur["knocked"]:
			names.append(FusionEngine.item(k)["name"])
		GameManager.toast(Loc.t("Devrildi: %s") % Loc.list_sep().join(PackedStringArray(names)), UIKit.ORANGE, "cross")
	if ab == "gravity_shift" and result in ["full", "half", "adapt"] and dish_view.visible:
		var tw := create_tween()
		tw.tween_property(dish_view, "position:y", dish_view.position.y - 60, 0.6).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(dish_view, "rotation", 0.4, 0.6)
		tw.tween_property(dish_view, "position:y", dish_view.position.y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(dish_view, "rotation", 0.08 if result != "adapt" else 0.0, 0.5)
	await get_tree().create_timer(0.9 if not GameManager.fast() else 0.4).timeout


# ------------------------------------------------------------------ yardımcılar
func _banner(t1: String, t2: String, col: Color) -> void:
	var p := UIKit.panel(col, 26, UIKit.INK, 4, 14)
	var v := UIKit.vbox(0)
	p.add_child(v)
	v.add_child(UIKit.title(t1, 34, Color.WHITE, UIKit.INK, 8))
	if t2 != "":
		var l := UIKit.label(t2, 24, Color.WHITE)
		v.add_child(UIKit.outlined(l, col.darkened(0.5), 6))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(p)
	await get_tree().process_frame
	if not is_instance_valid(p):
		return
	p.position = Vector2((scene_area.size.x - p.size.x) * 0.5, SCENE_H * 0.52 - p.size.y * 0.5)
	UIKit.pop_in(p)
	var tw := p.create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)


func _tut(text: String) -> void:
	_clear_tut()
	var b := SpeechBubble.show_at(_bubble_layer, player_fig.position + Vector2(100, -215), text, 0.0, -0.6, Color("#fff2c4"), 400)
	_tut_bubble = b


func _clear_tut() -> void:
	if is_instance_valid(_tut_bubble):
		_tut_bubble.queue_free()
	_tut_bubble = null


func _pause_menu() -> void:
	var was := timer_on
	timer_on = false
	var m := UIKit.modal(self, Loc.t("DURAKLATILDI"), "", [[Loc.t("Devam Et"), "close", UIKit.GREEN], [Loc.t("Ses: %s") % (Loc.t("Açık") if float(SaveManager.setting("music", 0.7)) > 0.01 else Loc.t("Kapalı")), "sound", UIKit.BLUE], [Loc.t("Maçtan Çık"), "quit", UIKit.RED]])
	var ch: String = await m.closed
	if ch == "sound":
		var on := float(SaveManager.setting("music", 0.7)) > 0.01
		SaveManager.set_setting("music", 0.0 if on else 0.7)
		SaveManager.set_setting("sfx", 0.0 if on else 0.9)
		AudioManager.apply_volumes()
		timer_on = was
		return
	if ch == "quit":
		var m2 := UIKit.modal(self, Loc.t("Emin misin?"), Loc.t("Maçtan çıkarsan bu maçın ilerlemesi kaybolur."), [[Loc.t("Vazgeç"), "no", UIKit.GRAY], [Loc.t("Çık"), "yes", UIKit.RED]])
		var c2: String = await m2.closed
		if c2 == "yes":
			BattleManager.active = false
			GameManager.goto("daily" if BattleManager.is_daily() else "career", {}, false)
			return
	timer_on = was


func on_back() -> bool:
	if phase in ["select", "plating"]:
		_pause_menu()
	return true


class CounterFront extends Control:
	var top_y := 300.0
	var color := Color("#e8734a")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var top := Rect2(-10, top_y, size.x + 20, 26)
		DrawKit.shape(self, DrawKit.rrect(top, 10), color.lightened(0.15), 4.0, 0.1)
		var front := Rect2(-10, top_y + 22, size.x + 20, size.y - top_y)
		draw_polygon(DrawKit.rrect(front, 4), DrawKit._grad_colors(DrawKit.rrect(front, 4), color, 0.12))
		for k in 6:
			var dx := (k + 0.5) * size.x / 6.0
			draw_line(Vector2(dx, top_y + 34), Vector2(dx, size.y), Color(0, 0, 0, 0.08), 3.0, true)
