extends Node
## Tracks one player product over time with steady marketing to understand its lifecycle.

func run(args: Array) -> void:
	WorldGen.new_game({"company": "Probe", "brand": "Probe", "home": "TR", "posit": "premium", "seed": 11})
	for a in args.slice(2):
		var kv: PackedStringArray = str(a).split("=")
		var path: PackedStringArray = kv[0].split(".")
		DB.bal[path[0]][path[1]] = float(kv[1])
	var items := FormulaEngine.normalize_items([["bergamot",10],["iso_e_super",32],["cedarwood",14],["patchouli",6],["amber_accord",14],["hedione",10],["galaxolide",12],["dpg",2]])
	var f := CompanyEngine.make_formula(G.pid(), "Probe", items, "ceo")
	var b: Dictionary = G.company_brands(G.pid())[0]
	var p := CompanyEngine.make_product(G.pid(), {"brand": b["id"], "name": "Probe", "formula": f["id"], "fmt": "edp", "conc": 18.0, "volume": 50.0, "pack": "standard", "audience": "any", "price": float(args[0]) if args.size() > 0 else 49.0, "markets": ["TR"], "launch_budget": 6000.0})
	ProductionEngine.place_order(G.pid(), p["id"], 1000, "quickfill", {"chill": true})
	FinanceEngine.raise_equity(G.pc(), 500000.0)
	var ev := MarketEngine.product_ev(p)
	var base := ConsumerEngine.seg_base(ev)
	print("appeal ", Array(base["appeal"]).map(func(x): return snappedf(x, 0.1)), " sat ", Array(base["sat"]).map(func(x): return snappedf(x, 0.1)), " long ", ev["longevity"], " proj ", ev["projection"])
	for w in (int(args[1]) if args.size() > 1 else 156):
		var avg := maxf(60.0, Rivals.avg_units(p, 4))
		if int(p["inv"]) + Rivals.pipeline(p["id"]) < avg * 6.0:
			ProductionEngine.place_order(G.pid(), p["id"], int(avg * 8.0), "quickfill", {"chill": true})
		if w == 3:
			print("sign marketplace: ", CompanyEngine.sign_channel(G.pc(), "TR", "marketplace", CompanyEngine.channel_offer(G.pid(), "TR", "marketplace")))
		if w % 4 == 0 and w > 4:
			MarketingEngine.start(G.pid(), "social", p["id"], b["id"], ["TR"], 1500.0, 4)
		Sim.advance()
		if w % 8 == 7:
			var m: Dictionary = p["mk"].get("TR", {})
			var u := MarketEngine.utilities(p, ev, b, "TR", float(p.get("mk_nov_TR", 0.3)))
			var wk: Array = p["wk"]
			var pp := FinanceEngine.period(G.pc(), 8)
			var sm := FinanceEngine.summarize(pp)
			print("   PL/wk rev %.0f gross %.0f mkt %.0f pay %.0f fac %.0f dist %.0f prod %.0f admin %.0f net %.0f  cash %.0f unitcost %.2f" % [sm["revenue"]/8, sm["gross"]/8, float(pp.get("marketing",0))/8, float(pp.get("payroll",0))/8, float(pp.get("facilities",0))/8, float(pp.get("distribution",0))/8, float(pp.get("production",0))/8, float(pp.get("admin",0))/8, sm["net"]/8, FinanceEngine.cash_of(G.pc()), float(p["unit_cost"])])
			print("w%3d units %4d aw %.3f buzz %.2f sat %.2f loyal %5.0f triers %6.0f retention %.2f rating %.2f nov %.2f U %s brandaw %.3f prestige %.2f" % [w, int(wk[wk.size() - 1][1]) if not wk.is_empty() else 0, float(m.get("aw", 0)), float(m.get("buzz", 0)), float(m.get("sat", 0)), float(m.get("loyal", 0)), float(m.get("triers", 0)), float(m.get("retention", 1)), Awards.rating_avg(p), float(p.get("mk_nov_TR", 0)), str(Array(u).map(func(x): return snappedf(x, 0.1))), CompanyEngine.brand_aw(b, "TR"), float(b["prestige"])])
