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
