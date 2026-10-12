extends Node
## Prints performance model results for archetype formulas (calibration aid).

func run(_a: Array) -> void:
	await get_tree().process_frame
	G.s = {"ing_market": {}}
	var tests := {
		"Citrus cologne EDC": [[["bergamot",35],["lemon",15],["orange",10],["lavender",8],["neroli",4],["linalool",10],["hedione",10],["galaxolide",5],["dpg",3]], "edc", 4.0],
		"Fresh aquatic EDT": [[["bergamot",15],["dihydromyrcenol",15],["calone",1.5],["hedione",20],["iso_e_super",20],["cedarwood",10],["galaxolide",15],["ambroxan",1.5],["bht",0.5],["dpg",1.5]], "edt", 10.0],
		"Rose EDP": [[["rose_absolute",6],["pea",15],["citronellol",10],["geraniol",4],["geranium",5],["hedione",15],["ionones",5],["patchouli",8],["galaxolide",15],["ethylene_brassylate",10],["benzyl_salicylate",7]], "edp", 18.0],
		"Vanilla gourmand EDP": [[["mandarin",8],["ethyl_maltol",2],["vanillin",12],["tonka_abs",6],["amber_accord",15],["benzoin",10],["sandalwood_nat",5],["galaxolide",15],["peach_lactone",5],["iso_e_super",12],["benzyl_benzoate",10]], "edp", 18.0],
		"Oud extrait": [[["oud_natural",3],["oud_accord",15],["rose_absolute",5],["saffron_x",0],["safraleine",2],["labdanum",10],["amber_accord",15],["patchouli",10],["ambroxan",3],["iso_e_super",17],["benzyl_benzoate",20]], "extrait", 25.0],
		"Woody amber EDP": [[["bergamot",10],["pink_pepper",3],["iso_e_super",35],["ambroxan",4],["cedarwood",12],["vetiver",6],["cashmeran",10],["hedione",10],["galaxolide",10]], "edp", 18.0],
		"Body mist fruity": [[["orange",20],["cassis_base",10],["peach_lactone",10],["ethyl_maltol",1],["pea",20],["hedione",14],["galaxolide",20],["dpg",5]], "mist", 2.0],
		"Musk oil": [[["muscenone",10],["galaxolide",30],["ethylene_brassylate",30],["ambrette",3],["iso_e_super",17],["hedione",10]], "oil", 20.0],
	}
	for name in tests:
		var t: Array = tests[name]
		var items: Array = []
		for it in t[0]:
			if float(it[1]) > 0: items.append(it)
		items = FormulaEngine.normalize_items(items)
		var r: Dictionary = FormulaEngine.evaluate(items, t[1], t[2])
		print("%-22s %-15s long %5.1fh  sill %5.1fh  int %.2f proj %.2f cx %.2f ten %.2f harsh %.2f sweet %.2f clo %.2f  $%.0f/kg $%.3f/ml  %s %s" % [name, r["family"], r["longevity"], r["sillage"], r["intensity"], r["projection"], r["complexity"], r["tension"], r["harsh"], r["sweet"], r["cloying"], r["cost_kg"], r["cost_ml"], FormulaEngine.stability_label(r["stability"]), str(r["errors"])])
		print("    curve ", Array(r["curve"]).map(func(x): return snappedf(x, 0.1)))
