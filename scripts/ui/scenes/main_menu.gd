extends BaseScreen
## MainMenu — oyunun merkezi: kariyer, kaos lab, günlük meydan okuma, tarif kitabı, dükkân, şef ve ayarlar.

var chef_fig: CharacterFigure
var pot: DishView


func _ready() -> void:
	GameManager.reset_history()
	setup_screen("sunburst", Color("#ffb35c"), Color("#ff5f8f"))
	AudioManager.music("menu")
	# üst çubuk
	var top := UIKit.hbox(10)
	root_v.add_child(top)
	var lvl := UIKit.panel(Color(0.23, 0.14, 0.09, 0.82), 30, Color(0, 0, 0, 0), 0, 10)
	var lv := UIKit.vbox(2)
	lvl.add_child(lv)
	var lt := UIKit.label(Loc.t("Seviye %d") % ProgressionManager.level(), 24, Color("#fff1a8"))
	lv.add_child(lt)
	lv.add_child(UIKit.bar(ProgressionManager.xp(), ProgressionManager.xp_needed(ProgressionManager.level()), UIKit.GREEN, 14, 150))
	top.add_child(lvl)
	if ProgressionManager.skill_points() > 0:
		var sp := UIKit.chip(Loc.t("+%d puan") % ProgressionManager.skill_points(), UIKit.GREEN, 18)
		top.add_child(sp)
	top.add_child(UIKit.expander())
	top.add_child(coin_badge())
	var gear := UIKit.icon_button("gear", UIKit.CREAM, 70)
	gear.pressed.connect(func(): GameManager.goto("settings"))
	top.add_child(gear)
	# logo
	var logo := UIKit.title(Loc.t("FUSE CHEF"), 88, Color("#fff1a8"), UIKit.INK, 20)
	root_v.add_child(logo)
	var sub := UIKit.title(Loc.t("ÇILGIN MUTFAK SAVAŞI"), 30, Color.WHITE, UIKit.INK, 9)
	root_v.add_child(sub)
	# şef sahnesi
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 300)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	root_v.add_child(stage)
	var n := Node2D.new()
	stage.add_child(n)
	chef_fig = CharacterFigure.new()
	chef_fig.setup(CharacterFigure.chef_spec(ProgressionManager.chef()))
	n.add_child(chef_fig)
	pot = DishView.new()
	pot.setup({"id": "menu_pot", "visual": {"base": "soup", "c1": "#7cff6b", "c2": "#ff5fa2", "decor": ["steam", "bubbles", "sparkles"]}})
	n.add_child(pot)
	var asst := ProgressionManager.assistant()
	var companion: DishView = null
	if asst != "":
		companion = DishView.new()
		companion.setup(DishView.companion(asst))
		companion.set_alive(true)
		n.add_child(companion)
	stage.resized.connect(func():
		var h := stage.size.y
		var s := clampf(h / 380.0, 0.6, 1.1)
		chef_fig.scale = Vector2(s, s)
		chef_fig.position = Vector2(stage.size.x * 0.36, h)
		pot.scale = Vector2(s * 0.75, s * 0.75)
		pot.position = Vector2(stage.size.x * 0.72, h - 10)
		if companion:
			companion.scale = Vector2(s * 0.4, s * 0.4)
			companion.position = Vector2(stage.size.x * 0.1, h - 40))
	stage.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			chef_fig.react(["cheer", "laugh", "love", "surprised", "jump"][randi() % 5]))
	# düğmeler
	var nm := ProgressionManager.next_match()
	var career := UIKit.button(Loc.t("KARİYER"), UIKit.ORANGE, Vector2(0, 108), 44, "map")
	career.pressed.connect(func(): GameManager.goto("career"))
	root_v.add_child(career)
	if nm != "":
		var m: Dictionary = IngredientDatabase.matches[nm]
		var nl := UIKit.label(Loc.t("Sıradaki: %s · %s") % [IngredientDatabase.league(int(m["league"]))["name"], IngredientDatabase.opponents[m["opponent"]]["name"]], 20, Color.WHITE)
		root_v.add_child(UIKit.outlined(nl, UIKit.INK, 6))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root_v.add_child(grid)
	var items := [[Loc.t("Kaos Lab"), UIKit.PURPLE, "flask", "lab"], [Loc.t("Günlük"), UIKit.PINK, "calendar", "daily"],
		[Loc.t("Tarif Kitabı"), UIKit.BLUE, "book", "book"], [Loc.t("Dükkân"), UIKit.GREEN, "bag", "shop"]]
	for it in items:
		var b := UIKit.button(it[0], it[1], Vector2(0, 90), 32, it[2])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key: String = it[3]
		b.pressed.connect(func(): GameManager.goto(key))
		grid.add_child(b)
		if key == "daily" and DailyChallengeManager.can_claim():
			var badge := UIKit.chip("!", UIKit.RED, 22)
			b.add_child(badge)
			badge.position = Vector2(8, -8)
	var chefb := UIKit.button(Loc.t("Şefim"), Color("#ffc928"), Vector2(0, 80), 30, "chef")
	chefb.pressed.connect(func(): GameManager.goto("chef"))
	root_v.add_child(chefb)
	UIKit.pop_in(logo, 0.05)
	UIKit.pop_in(career, 0.15)


func on_back() -> bool:
	confirm_quit()
	return true


func confirm_quit() -> void:
	var m := UIKit.modal(self, Loc.t("Çıkış"), Loc.t("Oyundan çıkmak istiyor musun? İlerlemen kaydedildi."), [[Loc.t("Kal"), "no", UIKit.GREEN], [Loc.t("Çık"), "yes", UIKit.RED]])
	var ch: String = await m.closed
	if ch == "yes":
		SaveManager.save_now()
		get_tree().quit()
