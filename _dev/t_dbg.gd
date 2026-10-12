extends Node

func run(_args: Array) -> void:
	WorldGen.new_game({"company": "Test House", "brand": "Test", "home": "TR", "posit": "premium", "seed": 42})
	var cid := "US"
	var n := 0
	for p in G.s["products"].values():
		if not p["markets"].has(cid) or n > 12:
			continue
		n += 1
		var ev := MarketEngine.product_ev(p)
		var b := G.brand(p["brand"])
		var u := MarketEngine.utilities(p, ev, b, cid, 0.3)
		var rch := CompanyEngine.reach(p["company"], cid, b["posit"])
		var m: Dictionary = p["mk"][cid]
		var base := ConsumerEngine.seg_base(ev)
		print("%-22s %-8s %-14s $%4.0f %3.0fml %-7s aw %.2f baw %.2f inv %5d | U %s | appeal %s | reach %s | last %d" % [p["name"], b["posit"], ev["family"], p["price"], p["volume"], p["fmt"], m["aw"], CompanyEngine.brand_aw(b, cid), p["inv"],
			str(Array(u).map(func(x): return snappedf(x, 0.1))), str(Array(base["appeal"]).map(func(x): return snappedf(x, 0.1))), str(Array(rch).map(func(x): return snappedf(x, 0.01))), m.get("last", 0)])
	print("buyers US ", MarketEngine.buyers("US", 0))
