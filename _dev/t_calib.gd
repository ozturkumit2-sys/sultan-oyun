extends Node
## Calibration probe: rival share of buyers and a hypothetical new player product's weekly units.

func run(args: Array) -> void:
	WorldGen.new_game({"company": "Probe", "brand": "Probe", "home": "TR", "posit": "premium", "seed": 11})
	var items := FormulaEngine.normalize_items([["bergamot",10],["iso_e_super",32],["cedarwood",14],["patchouli",6],["amber_accord",14],["hedione",10],["galaxolide",12],["dpg",2]])
	var f := CompanyEngine.make_formula(G.pid(), "Probe", items, "ceo")
	var b: Dictionary = G.company_brands(G.pid())[0]
	var p := CompanyEngine.make_product(G.pid(), {"brand": b["id"], "name": "Probe", "formula": f["id"], "fmt": "edp", "conc": 18.0, "volume": 50.0, "pack": "standard", "audience": "any", "price": 65.0, "markets": DB.country_by_id.keys()})
	p["status"] = "active"
	p["launched"] = true
	p["inv"] = 1000000
	var C := ConsumerEngine
	var e0 := exp(C.C("outside"))
	for aw in [0.01, 0.05, 0.15]:
		var tot_units := 0.0
		var line := ""
		for cid in DB.country_by_id.keys():
			CompanyEngine.mk(p, cid)["aw"] = aw
			var ct := DB.country(cid)
			var B := MarketEngine.buyers(cid, 10)
			var segw: Dictionary = ct["seg"]
			var ar := MarketEngine.avg_rate(cid)
			var player_u := 0.0
			var rival_u := 0.0
			var sum_tot := 0.0
			var cnt := 0
			var prods: Array = G.s["products"].values().filter(func(x): return MarketEngine.is_selling(x) and x["markets"].has(cid))
			var U: Array = []
			var CONS: Array = []
			for q in prods:
				var ev := MarketEngine.product_ev(q)
				var bq := G.brand(q["brand"])
				U.append(MarketEngine.utilities(q, ev, bq, cid, 0.3))
				var m := CompanyEngine.mk(q, cid)
				var awe := 1.0 - (1.0 - float(m["aw"])) * (1.0 - 0.35 * CompanyEngine.brand_aw(bq, cid))
				var rch := CompanyEngine.reach(q["company"], cid, bq.get("posit", "mass"))
				var cs := PackedFloat32Array()
				for i in DB.segments.size():
					cs.append(awe * rch[i])
				CONS.append(cs)
			for i in DB.segments.size():
				var sg: Dictionary = DB.segments[i]
				var Ds := B * float(segw.get(sg["id"], 0.0)) * float(sg["rate"]) / ar
				for g in ["fem", "masc", "any"]:
					var Dg := Ds * float(sg["labels"][g])
					var tot := 0.0
					var mine := 0.0
					for k in prods.size():
						var e := float(CONS[k][i]) * exp(float(U[k][i]) + C.label_ln(g, prods[k]["audience"]))
						tot += e
						if prods[k]["id"] == p["id"]:
							mine = e
					var denom := maxf(e0, MarketEngine.M("sim_cap") * tot) + tot
					player_u += Dg * mine / denom
					rival_u += Dg * (tot - mine) / denom
					sum_tot += tot - mine
					cnt += 1
			tot_units += player_u
			line += "%s: rivals %.1f%% tot %.1f player %.0f | " % [cid, 100.0 * rival_u / B, sum_tot / cnt, player_u]
		print("aw %.2f player total %.0f/wk  %s" % [aw, tot_units, line])
	print("e0 = ", e0)
