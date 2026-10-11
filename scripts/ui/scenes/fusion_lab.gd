extends Control
## FusionLab (Kaos Laboratuvarı) — rakipsiz, süresiz serbest deney alanı. Kariyerle aynı füzyon motorunu kullanır.
## Keşifler Tarif Kitabı'na yazılır; kariyer ilerlemesi kaybolmaz.

const SCENE_H := 380.0

var station: KitchenStation
var scene_area: Control
var player_fig: CharacterFigure
var dish_view: DishView
var info_box: VBoxContainer
var count_label: Label
var quick := false
var _quick_btn: Button
var _busy := false
var _bubble_layer: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	AudioManager.music("lab")
	var bg := ColorRect.new()
	bg.color = Color("#1d1433")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 0)
	add_child(v)
	var hud := PanelContainer.new()
	var hs := UIKit.sb(Color("#3b2a5c"), 0, Color(0, 0, 0, 0), 0, 0, 12)
	hs.content_margin_top = 10 + GameManager.safe_top()
	hs.content_margin_bottom = 10
	hud.add_theme_stylebox_override("panel", hs)
	v.add_child(hud)
	var hr := UIKit.hbox(10)
	hud.add_child(hr)
	var back := UIKit.icon_button("back", UIKit.CREAM, 68)
	back.pressed.connect(func(): on_back())
	hr.add_child(back)
	var tv := UIKit.vbox(-4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hr.add_child(tv)
	tv.add_child(UIKit.title(Loc.t("KAOS LAB"), 38, Color("#7cff6b"), UIKit.INK, 10))
	count_label = UIKit.label("", 20, Color("#e9d6ff"))
	tv.add_child(count_label)
	_quick_btn = UIKit.button(Loc.t("Mini oyun: AÇIK"), UIKit.BLUE, Vector2(200, 60), 20)
	_quick_btn.pressed.connect(func():
		quick = not quick
		_quick_btn.text = Loc.t("Mini oyun: KAPALI") if quick else Loc.t("Mini oyun: AÇIK")
		UIKit.style_button(_quick_btn, UIKit.GRAY if quick else UIKit.BLUE, 26, 20))
	hr.add_child(_quick_btn)
	scene_area = Control.new()
	scene_area.custom_minimum_size = Vector2(0, SCENE_H)
	scene_area.clip_contents = true
	v.add_child(scene_area)
	var bd := Backdrop.new()
	bd.kind = "lab"
	bd.counter_y = SCENE_H - 70
	scene_area.add_child(bd)
	var n := Node2D.new()
	scene_area.add_child(n)
	var w := GameManager.screen_size.x
	player_fig = CharacterFigure.new()
	var spec := CharacterFigure.chef_spec(ProgressionManager.chef())
	spec["acc"] = spec.get("acc", []) + ["glasses"] if not spec.get("acc", []).has("glasses") else spec.get("acc", [])
	player_fig.setup(spec)
	player_fig.scale = Vector2(0.74, 0.74)
	player_fig.position = Vector2(w * 0.25, SCENE_H - 24)
	n.add_child(player_fig)
	var front := LabFront.new()
	front.top_y = SCENE_H - 70
	front.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene_area.add_child(front)
	dish_view = DishView.new()
	dish_view.scale = Vector2(0.6, 0.6)
	dish_view.position = Vector2(w * 0.62, SCENE_H - 56)
	dish_view.visible = false
	scene_area.add_child(dish_view)
	_bubble_layer = Control.new()
	_bubble_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bubble_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_area.add_child(_bubble_layer)
	var tap := Control.new()
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.mouse_filter = Control.MOUSE_FILTER_PASS
	scene_area.add_child(tap)
	tap.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and dish_view.visible and dish_view.alive:
			dish_view.wobble = -0.25
			var tw := create_tween()
			tw.tween_property(dish_view, "wobble", 0.0, 0.3)
			tw.parallel().tween_property(dish_view, "position:y", dish_view.position.y - 40, 0.15)
			tw.tween_property(dish_view, "position:y", SCENE_H - 56, 0.2)
			AudioManager.sfx_r("boing", 0.2))
	var work := PanelContainer.new()
	var ws := UIKit.sb(UIKit.CREAM, 0, UIKit.INK, 0, 0, 12)
	ws.border_width_top = 5
	ws.border_color = UIKit.INK
	ws.content_margin_top = 12
	ws.content_margin_bottom = 10 + GameManager.safe_bottom()
	work.add_theme_stylebox_override("panel", ws)
	work.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(work)
	var wv := UIKit.vbox(8)
	work.add_child(wv)
	info_box = UIKit.vbox(6)
	info_box.visible = false
	wv.add_child(info_box)
	station = KitchenStation.new()
	station.mode = "lab"
	wv.add_child(station)
	station.max_slots = 3
	station.fusion_limit = -1
	station.cook_requested.connect(_on_cook)
	station.fused.connect(_on_fused)
	_refresh()
	if not ProgressionManager.tutorial_done("lab"):
		ProgressionManager.set_tutorial_done("lab")
		SpeechBubble.show_at(_bubble_layer, player_fig.position + Vector2(100, -200), Loc.t("Burada süre yok, rakip yok! Her şeyi karıştır, bakalım ne çıkacak."), 4.0, -0.6, Color("#e9d6ff"), 380)


func _refresh() -> void:
	var ings := ProgressionManager.owned_ingredients()
	for f in SabotageSystem.FERMENTED:
		if not ings.has(f):
			ings.append(f)
	station.set_pantry(ings, RecipeBookManager.known_fusions())
	count_label.text = Loc.t("%d tarif keşfedildi · %d özel") % [RecipeBookManager.count_all(), RecipeBookManager.count_handcrafted()]


func _on_fused(it: Dictionary, is_new: bool) -> void:
	player_fig.react("cheer" if is_new else "jump")
	if is_new:
		SpeechBubble.show_at(_bubble_layer, player_fig.position + Vector2(100, -200), Loc.t("Yeni füzyon: %s!") % it["name"], 2.2, -0.6)
	_refresh()


func _on_cook(inputs: Array, method: String) -> void:
	if _busy:
		return
	_busy = true
	station.locked = true
	info_box.visible = false
	var q := 0.8
	if not quick:
		var mg := CookingMinigame.new()
		add_child(mg)
		mg.start(method, {})
		q = await mg.finished
	else:
		AudioManager.sfx("cook_start")
	var dish := FusionEngine.cook(inputs, method)
	var first := RecipeBookManager.discover(dish, "lab")
	if q >= 0.95:
		ProgressionManager.add_stat("perfect_cooks")
	dish_view.setup(dish, "classic")
	dish_view.visible = true
	dish_view.set_alive(str(dish.get("living", "")) != "")
	dish_view.scale = Vector2(0.1, 0.1)
	var tw := create_tween()
	tw.tween_property(dish_view, "scale", Vector2(0.6, 0.6), 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	FxBurst.spawn(scene_area, dish_view.position + Vector2(0, -50), "puff", 14)
	FxBurst.spawn(scene_area, dish_view.position + Vector2(0, -50), "sparkles", 14, Color("#7cff6b"))
	AudioManager.sfx("discover" if first else "pop")
	player_fig.react("cheer" if first else "smug")
	_show_info(dish, first, q)
	_refresh()
	station.clear_bowl()
	station.locked = false
	_busy = false


func _show_info(dish: Dictionary, first: bool, q: float) -> void:
	for c in info_box.get_children():
		c.queue_free()
	info_box.visible = true
	var head := UIKit.hbox(8)
	info_box.add_child(head)
	var nm := UIKit.label(dish["name"], 26, UIKit.PURPLE, true, HORIZONTAL_ALIGNMENT_LEFT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(nm)
	if first:
		head.add_child(UIKit.chip(Loc.t("YENİ!"), UIKit.PINK, 18))
	if dish.get("handcrafted", false):
		head.add_child(UIKit.chip(Loc.t("ÖZEL"), UIKit.PURPLE, 18))
	if str(dish.get("living", "")) != "":
		head.add_child(UIKit.chip(Loc.t("CANLI"), UIKit.GREEN, 18))
	var close := UIKit.icon_button("cross", UIKit.CREAM, 50)
	close.pressed.connect(func(): info_box.visible = false)
	head.add_child(close)
	var d := UIKit.label(dish.get("desc", ""), 18, Color("#6a4a3a"), false, HORIZONTAL_ALIGNMENT_LEFT)
	d.clip_text = true
	d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info_box.add_child(d)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 2)
	info_box.add_child(grid)
	for k in ["sweet", "spicy", "fresh", "weird", "magic", "toxic"]:
		var l := UIKit.label(Loc.t(str(IngredientDatabase.STAT_NAMES[k])).substr(0, 5), 15, UIKit.INK, true, HORIZONTAL_ALIGNMENT_LEFT)
		l.custom_minimum_size.x = 62
		grid.add_child(l)
		grid.add_child(UIKit.bar(dish["stats"][k], 100, IngredientDatabase.STAT_COLORS[k], 12, 140))
	var ev := JudgeSystem.evaluate(dish, {"theme": {}, "quality": q, "plate": "classic", "garnish": "none", "first": false})
	var jr := JudgeSystem.judge_all(dish, ev, {}, {})
	var jt := []
	for j in IngredientDatabase.judges:
		jt.append(Loc.t("%s %s") % [j["name"].split(" ")[-1], UIKit.fmt(jr["judges"][j["id"]]["score"])])
	info_box.add_child(UIKit.label(Loc.t("Jüri tahmini (temasız): ") + " · ".join(PackedStringArray(jt)) + " = " + UIKit.fmt(jr["total"]), 18, UIKit.INK))


func on_back() -> bool:
	if _busy:
		return true
	GameManager.go_back()
	return true


class LabFront extends Control:
	var top_y := 300.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var top := Rect2(-10, top_y, size.x + 20, 24)
		DrawKit.shape(self, DrawKit.rrect(top, 8), Color("#7a5ca8"), 4.0, 0.1)
		var front := Rect2(-10, top_y + 20, size.x + 20, size.y - top_y)
		draw_polygon(DrawKit.rrect(front, 4), DrawKit._grad_colors(DrawKit.rrect(front, 4), Color("#4b3470"), 0.12))
		for k in 5:
			var x := (k + 0.5) * size.x / 5.0
			DrawKit.circle(self, Vector2(x, top_y + 60), 8, Color("#7cff6b") if k % 2 == 0 else Color("#ff5fa2"), 3.0, 0.1)
