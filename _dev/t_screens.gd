extends Node
## Smoke test: builds every screen (and common modals) in a populated world.

func run(args: Array) -> void:
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	WorldGen.new_game({"company": "Test House", "brand": "Test", "home": "FR", "posit": "premium", "seed": 3})
	var c := G.pc()
	FinanceEngine.raise_equity(c, 2000000.0)
	var items := FormulaEngine.normalize_items([["bergamot",10],["iso_e_super",32],["cedarwood",14],["patchouli",6],["amber_accord",14],["hedione",10],["galaxolide",12],["dpg",2]])
	var f := CompanyEngine.make_formula(G.pid(), "Ember Dune", items, "ceo")
	var b: Dictionary = G.company_brands(G.pid())[0]
	var p := CompanyEngine.make_product(G.pid(), {"brand": b["id"], "name": "Ember Dune", "formula": f["id"], "fmt": "edp", "conc": 18.0, "volume": 50.0, "pack": "standard", "audience": "any", "price": 75.0, "markets": ["FR", "DE"], "launch_budget": 8000.0})
	print("order: ", ProductionEngine.place_order(G.pid(), p["id"], 2000, "meridian", {"chill": true}))
	Staff.refresh_candidates(true)
	for rid in ["perfumer", "chemist", "marketing_manager", "production_manager", "sales_manager", "hr_manager"]:
		for id in G.s["candidates"].duplicate():
			var e := G.employee(id)
			if e["role"] == rid:
				print("hire ", rid, ": ", Staff.hire(G.pid(), id, float(e["salary"]) * 1.1, 2))
				break
	Lab.run_test(G.pid(), f["id"], 0, "edp", 18.0, "full")
	Lab.run_survey(G.pid(), {"items": items, "fmt": "edp", "conc": 18.0, "price": 75.0, "volume": 50.0, "posit": "premium", "prestige": 0.2, "label": "Ember", "formula": f["id"], "v": 0}, "FR", 250, false)
	MarketingEngine.start(G.pid(), "social", p["id"], b["id"], ["FR"], 3000.0, 6)
	CompanyEngine.open_office(c, "DE")
	Corporate.create_brand(c, "Second Brand", "mass", "#d99aa5", 1)
	var wk := int(args[0]) if args.size() > 0 else 30
	for i in wk:
		Sim.advance()
		if int(p["inv"]) < 300 and Rivals.pipeline(p["id"]) == 0:
			ProductionEngine.place_order(G.pid(), p["id"], 2000, "meridian", {"chill": true})
	print("week ", G.week(), " cash ", G.money(FinanceEngine.cash_of(c)), " units ", p["st"]["units"], " proposals ", G.s["proposals"].size(), " inbox ", G.inbox_open().size())
	Router.start_game()
	await get_tree().process_frame
	var rival: String = "c1"
	var cand: String = G.s["candidates"][0] if not G.s["candidates"].is_empty() else ""
	var emp: String = G.company_employees(G.pid())[0]["id"]
	var media: String = G.s["media"].keys()[0]
	var screens := [["dashboard", {}], ["lab_hub", {}], ["formulas", {}], ["formula_editor", {"fid": f["id"]}], ["formula_editor", {}], ["ingredients", {}],
		["ingredient_market", {}], ["tests", {"fid": f["id"], "v": 0}], ["research", {"fid": f["id"]}], ["research", {"product": p["id"]}], ["proposals", {}], ["briefs", {}],
		["products_hub", {}], ["product_detail", {"id": p["id"]}], ["launch", {"fid": f["id"]}], ["launch", {"parent": p["id"], "kind": "travel"}], ["production", {}],
		["reviews", {}], ["awards", {}], ["company_hub", {}], ["hq", {}], ["staff", {}], ["employee", {"id": emp}], ["recruit", {}], ["transfer", {}],
		["world_map", {}], ["brands", {}], ["brand_detail", {"id": b["id"]}], ["marketing", {}], ["campaign_new", {"product": p["id"]}], ["campaign_new", {"media": media}],
		["distribution", {"country": "DE"}], ["competitors", {}], ["competitor", {"id": rival}], ["acquisitions", {}], ["delegation", {}], ["finance_hub", {}],
		["statements", {}], ["loans", {}], ["investors", {}], ["reports", {}], ["inbox", {}], ["settings", {}], ["save_load", {"mode": "save"}], ["discovery", {"brand": b["id"]}]]
	for sc in screens:
		var s: Screen = Router.go(sc[0], sc[1])
		await get_tree().process_frame
		if s != null and s.has_method("rebuild"):
			# exercise tab variants where present
			for prop in ["tab", "show", "scope", "filter", "period", "sort"]:
				if prop in s:
					var cur = s.get(prop)
					var variants := {"tab": ["overview", "sales", "reviews", "history", "orders", "fg", "raw", "factory", "prices", "contracts", "deliveries", "campaigns", "influencers", "celebs", "budgets"],
						"show": ["open", "revising", "postponed", "decided", "formulas", "accords", "archived"], "scope": ["mine", "all", "critics"], "filter": ["active", "dev", "discontinued", "all"],
						"period": ["week", "month", "quarter", "year", "cal", "bs"], "sort": ["rev", "net", "units", "val", "prestige"]}
					for v in variants[prop]:
						s.set(prop, v)
						s.rebuild()
						await get_tree().process_frame
					s.set(prop, cur)
		if sc[0] == "launch":
			for st in [1, 2, 3]:
				s.step = st
				s.rebuild()
				await get_tree().process_frame
		print("ok ", sc[0])
		Router.back()
		await get_tree().process_frame
	for m in G.inbox_open().slice(0, 6):
		Inbox.open_item(m["id"])
		await get_tree().process_frame
		Router.close_modal()
	IngredientInfo.show("rose_absolute")
	await get_tree().process_frame
	Router.close_modal()
	IngredientPicker.open(func(x): pass)
	await get_tree().process_frame
	Router.close_modal()
	OrderDialog.open(p)
	await get_tree().process_frame
	Router.close_modal()
	Router.show_report(Sim.advance())
	await get_tree().process_frame
	Router.close_modal()
	print("screens done")
