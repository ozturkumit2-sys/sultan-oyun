extends Screen
## Title screen.

func build() -> void:
	body.add_child(UI.spacer(70))
	var bt := BottleView.new()
	bt.custom_minimum_size = Vector2(0, 330)
	bt.setup({"shape": 6, "cap": 6, "glass": 8, "label": 2, "accent": "#c9a55a"}, "Maison", "Empire", PackedFloat32Array())
	bt.liquid = Color("#e8b968")
	body.add_child(bt)
	var t := UI.title("PERFUME EMPIRE", 58, UI.GOLD2)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(t)
	var s := UI.lbl("BUILD YOUR FRAGRANCE HOUSE", 20, UI.MUTED, "semi", HORIZONTAL_ALIGNMENT_CENTER)
	body.add_child(s)
	body.add_child(UI.spacer(30))
	var auto := Save.info("auto")
	if not auto.is_empty() and not auto.get("corrupt", false):
		body.add_child(UI.btn("Continue — %s" % auto["company"], func(): _load("auto"), "primary", 26, 84))
		body.add_child(UI.lbl(G.date_str(int(auto["week"])) + " · " + G.money(float(auto["cash"])), 19, UI.MUTED, "medium", HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(UI.btn("New fragrance house", func(): Router.go("new_company"), "secondary" if not auto.is_empty() else "primary", 26, 84))
	body.add_child(UI.btn("Load game", func(): Router.go("save_load", {"mode": "load"}), "secondary", 24, 76))
	body.add_child(UI.btn("Settings", func(): Router.go("settings"), "ghost", 24, 70))
	body.add_child(UI.spacer(30))
	body.add_child(UI.lbl("All companies, brands, people and regulations in this game are fictional.", 17, UI.DIM, "body", HORIZONTAL_ALIGNMENT_CENTER, true))
	body.add_child(UI.lbl("v1.0.0", 16, UI.DIM, "body", HORIZONTAL_ALIGNMENT_CENTER))


func _load(slot: String) -> void:
	var err := Save.load_game(slot)
	if err != "":
		Router.info("Could not load", err)
		return
	Router.start_game()
