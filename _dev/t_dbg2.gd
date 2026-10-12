extends Node

func run(_args: Array) -> void:
	WorldGen.new_game({"company": "Test House", "brand": "Test", "home": "TR", "posit": "premium", "seed": 42})
	var ids: Array = G.s["products"].keys().slice(0, 6)
	for p in G.s["products"].values():
		if ids.has(p["id"]):
			print(p["name"], " seed_avg ", p.get("seed_avg"), " inv ", p["inv"], " launch ", p["launch_week"])
	for w in 10:
		Sim.advance()
		var line := "w%d " % G.week()
		for id in ids:
			var p: Dictionary = G.s["products"][id]
			var wk: Array = p["wk"]
			var last = wk[wk.size()-1] if not wk.is_empty() else [0,0,0,0,0]
			line += "| %s inv%d u%d lost%d pipe%d " % [p["status"].substr(0,3), p["inv"], last[1], last[4], Rivals.pipeline(id)]
		print(line)
	var c: Dictionary = G.s["companies"]["c1"]
	print("c1 cash ", G.money(FinanceEngine.cash_of(c)), " orders ", G.s["orders"].filter(func(o): return o["company"] == "c1").map(func(o): return [o["stage"], o["qty"], o.get("wait"), o.get("blocked", "")]))
