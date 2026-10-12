extends Screen
## Title screen.

func build() -> void:
	body.add_child(UI.spacer(6))
	var sh := Showcase.new().setup({"shape": 6, "cap": 6, "glass": 0, "label": 2, "accent": "#c9a55a", "tint": "rose"}, "Maison", "Empire")
	sh.custom_minimum_size = Vector2(0, 560)
	sh.bottle_scale = 0.62
	sh.bottle.idle_bubbles = true
	body.add_child(sh)
	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", -10)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in ["rose_absolute", "bergamot", "jasmine_abs", "vanilla_abs", "oud_natural", "lavender"]:
		strip.add_child(Art.ing_icon(id, 86))
	body.add_child(strip)
	var t := UI.title("PERFUME EMPIRE", 58, UI.BURGUNDY)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(t)
	var s := UI.lbl("BUILD YOUR FRAGRANCE HOUSE", 20, UI.MUTED, "semi", HORIZONTAL_ALIGNMENT_CENTER)
	body.add_child(s)
	body.add_child(UI.spacer(14))
	var auto := Save.info("auto")
	if not auto.is_empty() and not auto.get("corrupt", false):
		body.add_child(UI.btn("Continue — %s" % auto["company"], func(): _load("auto"), "primary", 26, 84))
		body.add_child(UI.lbl(G.date_str(int(auto["week"])) + " · " + G.money(float(auto["cash"])), 19, UI.MUTED, "medium", HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(UI.btn("New fragrance house", func(): Router.go("new_company"), "secondary" if not auto.is_empty() else "primary", 26, 84))
	body.add_child(UI.btn("Load game", func(): Router.go("save_load", {"mode": "load"}), "secondary", 24, 76))
	body.add_child(UI.btn("Settings", func(): Router.go("settings"), "ghost", 24, 70))
	body.add_child(UI.spacer(30))
	body.add_child(UI.lbl("All companies, brands, people and regulations in this game are fictional.", 17, UI.DIM, "body", HORIZONTAL_ALIGNMENT_CENTER, true))
	body.add_child(UI.lbl("v1.2.0", 16, UI.DIM, "body", HORIZONTAL_ALIGNMENT_CENTER))


func _load(slot: String) -> void:
	var err := Save.load_game(slot)
	if err != "":
		Router.info("Could not load", err)
		return
	Router.start_game()
