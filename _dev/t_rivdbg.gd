extends Node

func run(args: Array) -> void:
	WorldGen.new_game({"company": "Auto House", "brand": "Auto", "home": "TR", "posit": "premium", "seed": 11})
	for y in int(args[0]) if args.size() > 0 else 4:
		for w in 52:
			Sim.advance()
		for cid in ["c1", "c4", "c2"]:
			var c := G.company(cid)
			var ps := G.company_products(cid)
			var u := 0.0
			var pr := 0.0
			var aw := 0.0
			var n := 0
			for p in ps:
				var a := Rivals.avg_units(p, 4)
				u += a
				pr += float(p["price"])
				for k in p["mk"]:
					aw += float(p["mk"][k]["aw"])
					n += 1
			var t := FinanceEngine.ttm(c)
			print("Y%d %-22s prods %2d units/wk %8.0f avg price %6.1f avg aw %.3f rev %s mkt %s offices %d" % [y + 1, c["name"], ps.size(), u, pr / maxf(1, ps.size()), aw / maxf(1, n), G.money(float(t["revenue"])), G.money(-float(FinanceEngine.period(c, 52).get("marketing", 0))), c["offices"].size()])
		var st := {}
		for o in G.s["orders"]:
			if o["company"] == "c1":
				st[o["stage"]] = int(st.get(o["stage"], 0)) + 1
		var inv := 0
		for p in G.company_products("c1"):
			inv += int(p["inv"])
		print("   c1 orders by stage ", st, " inventory ", inv, " factory cap ", G.company("c1")["factory"].get("cap"))
		var tot := 0
		for k in G.s["markets"]:
			tot += int(G.s["markets"][k].get("units", 0))
		var bt := 0.0
		for ct in DB.countries:
			bt += MarketEngine.buyers(ct["id"], G.week())
		print("   total simulated units/wk %d of %d buyers (%.1f%%)" % [tot, int(bt), 100.0 * tot / bt])
