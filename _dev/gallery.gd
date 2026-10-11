extends Node2D
## Geliştirme: karakterleri, yemekleri ve ikonları bir arada çizip ekran görüntüsü alır.

var mode := "chars"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	RenderingServer.set_default_clear_color(Color("#f6e7d2"))
	match mode:
		"chars":
			var ids := ["bruno", "mira", "max", "morgana", "x3000", "gulizar", "velvet", "barbunya", "zorp", "lila", "obscura", "player"]
			for i in ids.size():
				var f := CharacterFigure.new()
				var sp: Dictionary
				if ids[i] == "player":
					sp = CharacterFigure.chef_spec(SaveManager.default_data()["chef"])
				else:
					sp = CharacterFigure.preset(ids[i])
				f.setup(sp)
				f.scale = Vector2(0.52, 0.52)
				f.position = Vector2(120 + (i % 4) * 160, 260 + (i / 4) * 330)
				f.idle_enabled = false
				add_child(f)
		"expr":
			var ex := ["happy", "laugh", "love", "surprised", "disgust", "angry", "sad", "cry", "dizzy", "smug", "goofy", "wink"]
			for i in ex.size():
				var f := CharacterFigure.new()
				f.setup(CharacterFigure.preset("bruno" if i % 3 == 0 else ("mira" if i % 3 == 1 else "max")))
				f.set_expression(ex[i])
				if i == 4: f.set_mutation("frog")
				if i == 5: f.set_mutation("flaming_hair")
				if i == 6: f.set_mutation("robot_eyes")
				if i == 7: f.set_mutation("giant_ears")
				if i == 8: f.set_mutation("alien_antennas")
				if i == 9: f.set_mutation("vampire_teeth")
				if i == 10: f.set_mutation("giant_tongue")
				if i == 11: f.set_mutation("ghost_form")
				f.set_pose(["idle", "up", "present", "point", "wave", "hips"][i % 6])
				f.scale = Vector2(0.48, 0.48)
				f.position = Vector2(120 + (i % 4) * 160, 260 + (i / 4) * 330)
				f.idle_enabled = false
				add_child(f)
		"dishes":
			var ids: Array = []
			for rid in IngredientDatabase.recipe_order:
				ids.append(rid)
			var plates: Array = IngredientDatabase.plate_order
			var start := int(OS.get_cmdline_user_args()[1]) if OS.get_cmdline_user_args().size() > 1 else 0
			ids = ids.slice(start)
			for i in mini(ids.size(), 30):
				var d := DishView.new()
				d.setup(FusionEngine.item(ids[i]), plates[i % plates.size()], IngredientDatabase.garnish_order[i % IngredientDatabase.garnish_order.size()])
				d.scale = Vector2(0.5, 0.5)
				d.position = Vector2(80 + (i % 5) * 140, 120 + (i / 5) * 200)
				if i % 7 == 3: d.set_alive(true)
				add_child(d)
		"icons":
			var ids: Array = IngredientDatabase.ingredient_order
			for i in ids.size():
				var ic := IngredientIcon.new()
				ic.size = Vector2(92, 92)
				ic.position = Vector2(8 + (i % 7) * 101, 14 + (i / 7) * 156)
				ic.set_item(ids[i])
				add_child(ic)
				var l := Label.new()
				l.text = IngredientDatabase.ingredients[ids[i]]["name"]
				l.position = ic.position + Vector2(0, 92)
				l.add_theme_font_size_override("font_size", 13)
				add_child(l)
	await get_tree().create_timer(0.6).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/claude-0/shots/gallery_%s%s.png" % [mode, "_" + OS.get_cmdline_user_args()[1] if OS.get_cmdline_user_args().size() > 1 else ""])
	print("saved ", mode)
	get_tree().quit()
