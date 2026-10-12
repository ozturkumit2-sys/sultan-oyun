extends Node
## Screenshot tour (run under xvfb with a real renderer).

func snap(name: String) -> void:
	for i in 6:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://_dev/shots/%s.png" % name)
	print("shot ", name)


func run(args: Array) -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await snap("00_menu")
	var which: String = args[0] if args.size() > 0 else "basic"
	if which == "bottles":
		var bg := ColorRect.new()
		bg.color = Color("#f6efe6")
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		get_tree().root.add_child(bg)
		var tints := ["natural", "blush", "gold", "sapphire", "emerald", "violet", "amber", "rose", "clear", "noir"]
		for i in 20:
			var bv := BottleView.new()
			var prof := PackedFloat32Array()
			prof.resize(DB.dims.size())
			prof[i % DB.dims.size()] = 1.0
			prof[(i * 3 + 1) % DB.dims.size()] = 0.5
			bv.setup({"shape": i % 10, "cap": i % 8, "glass": [0, 1, 3, 9, 2, 5, 6, 8, 4, 7][i % 10], "label": i % 6, "accent": ["#c9a55a", "#b8b8c0", "#7b2742", "#2f2a33"][i % 4], "tint": tints[i % 10] if i >= 10 else "natural"}, "Lumière", "No. %d" % i, prof)
			bv.position = Vector2((i % 5) * 140 + 10, int(i / 5) * 300 + 20)
			bv.size = Vector2(130, 280)
			bg.add_child(bv)
			if i == 3:
				bv.stir(1.0)
		await snap("bottles")
		return
	if which == "newco":
		Router.go("new_company")
		await snap("01_newco")
		return
	WorldGen.new_game({"company": "Maison Lumière", "brand": "Lumière", "home": "TR", "posit": "premium", "seed": 7})
	Router.start_game()
	await snap("02_dashboard")
	match which:
		"basic":
			Router.go("formula_editor", {"items": FormulaEngine.normalize_items([["bergamot",10],["pink_pepper",0],["iso_e_super",32],["cedarwood",14],["patchouli",6],["amber_accord",14],["hedione",10],["galaxolide",12],["dpg",2]].filter(func(x): return float(x[1]) > 0)), "name": "Ember Dune", "fmt": "edp"})
			await snap("03_editor")
			var sc: ScrollContainer = Router.current().scroll
			sc.scroll_vertical = 2200
			await snap("04_editor_preview")
			Router.go_tab("lab")
			await snap("05_lab")
		"launch":
			var f := CompanyEngine.make_formula(G.pid(), "Ember Dune", FormulaEngine.normalize_items([["bergamot",10],["iso_e_super",32],["cedarwood",14],["patchouli",6],["amber_accord",14],["hedione",10],["galaxolide",12],["dpg",2]]), "ceo")
			var l: Screen = Router.go("launch", {"fid": f["id"]})
			await snap("10_launch0")
			l.step = 1
			l.rebuild()
			await snap("11_launch1")
			l.step = 2
			l.rebuild()
			await snap("12_launch2")
			l.step = 3
			l.rebuild()
			await snap("13_launch3")
			l._confirm()
			await snap("14_product")
			for i in 5:
				Sim.advance()
			G.touch()
			await snap("15_product_sales")
			Router.go_tab("home")
			await snap("16_dash_after")
		"lab":
			var av = load("res://_dev/t_validate.gd").new()
			av._launch("Woody Amber", 600, "quickfill", 6000.0)
			for w in 12:
				av._auto(w)
				Sim.advance()
			G.touch()
			Router.go_tab("lab")
			await snap("70_lab_hub")
			Router.current().scroll.scroll_vertical = 900
			await snap("71_lab_hub2")
			Router.current().scroll.scroll_vertical = 2000
			await snap("72_lab_hub3")
			var fid0: String = G.s["formulas"].keys()[0]
			var ed: Screen = Router.go("formula_editor", {"fid": fid0})
			await snap("73_editor")
			ed.items.append(["rose_absolute", 4.0])
			ed._build_rows()
			ed._refresh_preview()
			await get_tree().create_timer(0.3).timeout
			await snap("74_editor_pour")
			ed.scroll.scroll_vertical = 700
			await snap("75_editor_rows")
			Router.go("launch", {"fid": fid0})
			Router.current().step = 1
			Router.current().rebuild()
			await snap("76_launch_bottle")
			var pid0: String = G.company_products(G.pid())[0]["id"]
			Router.go("product_detail", {"id": pid0})
			await snap("77_product")
		"modals":
			var av = load("res://_dev/t_validate.gd").new()
			av._launch("Woody Amber", 600, "quickfill", 6000.0)
			for w in 8:
				av._auto(w)
				Sim.advance()
			G.touch()
			Router.next_week()
			await get_tree().create_timer(1.0).timeout
			await snap("80_report")
			Router.close_all_modals()
			IngredientPicker.open(func(id): pass)
			await snap("81_picker")
			Router.close_all_modals()
			IngredientInfo.show("rose_absolute")
			await snap("82_ing_info")
			Router.close_all_modals()
			Router.go("hq")
			Router.current().scroll.scroll_vertical = 1200
			await snap("83_hq_next")
			Router.go("world_map", {})
			Router.current().map.set_zoom(3.0)
			Router.current().map.focus("FR")
			await snap("84_map_zoom")
		"tour":
			var av = load("res://_dev/t_validate.gd").new()
			av._launch("Woody Amber", 600, "quickfill", 6000.0)
			for w in int(args[1]) if args.size() > 1 else 70:
				av._auto(w)
				Sim.advance()
			G.touch()
			var p0: Dictionary = G.company_products(G.pid())[0]
			var e0 := ""
			for e in G.s["employees"].values():
				if e.get("employer", "") == G.pid():
					e0 = e["id"]
			var rv: String = G.s["companies"].keys().filter(func(k): return k != G.pid())[0]
			var plan := [["home", ""], ["lab", ""], ["products", ""], ["company", ""], ["finance", ""],
				["", "world_map"], ["", "hq"], ["", "staff"], ["", "transfer"], ["", "marketing"], ["", "competitors"],
				["", "statements"], ["", "reports"], ["", "inbox"], ["", "ingredient_market"], ["", "research"],
				["", "brands"], ["", "acquisitions"], ["", "awards"], ["", "distribution"], ["", "delegation"], ["", "investors"], ["", "loans"],
				["", "production"], ["", "reviews"], ["", "formulas"], ["", "tests"], ["", "proposals"], ["", "briefs"], ["", "ingredients"], ["", "recruit"], ["", "discovery"]]
			var i := 20
			for st in plan:
				if st[0] != "":
					Router.go_tab(st[0])
				else:
					Router.go_tab("home")
					Router.go(st[1], {})
				await snap("%02d_%s" % [i, st[0] if st[0] != "" else st[1]])
				i += 1
			Router.go_tab("products")
			Router.go("product_detail", {"id": p0["id"]})
			await snap("60_product_detail")
			Router.current().scroll.scroll_vertical = 1400
			await snap("61_product_detail2")
			if e0 != "":
				Router.go("employee", {"id": e0})
				await snap("62_employee")
			Router.go("competitor", {"id": rv})
			await snap("63_competitor")
			Router.go("brand_detail", {"id": G.company_brands(G.pid())[0]["id"]})
			await snap("64_brand")
			Router.go("campaign_new", {})
			await snap("65_campaign_new")
			Router.go("settings", {})
			await snap("66_settings")
			Router.go("save_load", {})
			await snap("67_saveload")
		"home":
			var av = load("res://_dev/t_validate.gd").new()
			av._launch("Woody Amber", 600, "quickfill", 6000.0)
			for w in int(args[1]) if args.size() > 1 else 40:
				av._auto(w)
				Sim.advance()
			G.touch()
			Router.go_tab("home")
			await snap("30_home_a")
			for k in 4:
				Router.current().scroll.scroll_vertical = 1000 * (k + 1)
				await snap("30_home_%s" % ["b", "c", "d", "e"][k])
