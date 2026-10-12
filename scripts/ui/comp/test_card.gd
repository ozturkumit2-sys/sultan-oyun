class_name TestCard
extends RefCounted
## Lab test result card.

static func add(parent: Control, t: Dictionary) -> void:
	var r: Dictionary = t["res"]
	var c := UI.card(parent)
	var h := UI.hbox(8)
	h.add_child(UI.lbl(Lab.TESTS[r["kind"]]["name"], 22, UI.CREAM, "semi"))
	h.add_child(UI.expand(UI.spacer()))
	h.add_child(UI.lbl("v%d · %s %.0f%% · %s" % [int(t["v"]) + 1, DB.formats[t["fmt"]]["name"], float(t["conc"]), G.short_date(int(t["w"]))], 16, UI.MUTED))
	c.add_child(h)
	if r.has("longevity"):
		var g := UI.grid(3, 8)
		g.add_child(UI.stat("Longevity", "%.1fh" % float(r["longevity"]), "%.1f–%.1fh" % [float(r["long_lo"]), float(r["long_hi"])]))
		g.add_child(UI.stat("Projection", FormulaEngine.projection_label(float(r["projection"])), "sillage %.1fh" % float(r["sillage"])))
		g.add_child(UI.stat("Strength", "%d" % int(float(r["intensity"]) * 100), "initial"))
		c.add_child(g)
		var ch := LineChart.new()
		ch.custom_minimum_size = Vector2(0, 200)
		var xl: Array = []
		for x in FormulaEngine.T_POINTS:
			xl.append(("%dh" % int(x)) if x in [0.0, 4.0, 8.0, 12.0, 24.0, 36.0] else "")
		var series := [{"v": r["curve"], "c": UI.GOLD, "name": "Intensity"}]
		if r.has("pcurve"):
			series.append({"v": r["pcurve"], "c": UI.ROSE, "name": "Projection"})
		var thr: Array = []
		for x in FormulaEngine.T_POINTS:
			thr.append(float(DB.bal["perf"]["detect"]))
		series.append({"v": thr, "c": Color(1, 1, 1, 0.3)})
		ch.fill = true
		ch.set_data(series, xl, "raw")
		c.add_child(ch)
		var lg := UI.hbox(12)
		lg.add_child(UI.lbl("● Perceived intensity", 16, UI.GOLD))
		if r.has("pcurve"):
			lg.add_child(UI.lbl("● Projection", 16, UI.ROSE))
		lg.add_child(UI.lbl("— detection", 16, UI.MUTED))
		c.add_child(lg)
		if r.has("anosmia") and float(r["anosmia"]) > 0.05:
			c.add_child(UI.para("About %d%% of the dry-down comes from materials some people cannot smell well." % int(float(r["anosmia"]) * 100), 18, UI.AMBER))
		if not r.get("interactions", []).is_empty():
			c.add_child(UI.para("Material interactions: " + ", ".join(r["interactions"]), 18, UI.GOLD2))
	if r.has("stability"):
		var st: Dictionary = r["stability"]
		c.add_child(UI.lbl("Stability: " + str(r["stab_label"]), 21, UI.GREEN if r["stab_label"] == "Stable" else (UI.AMBER if r["stab_label"] == "Monitor" else UI.RED), "semi"))
		for k in [["oxidation", "Oxidation (needs antioxidant?)"], ["discolor", "Discoloration"], ["cloud", "Haze / cloudiness"], ["crystal", "Crystallization"], ["sticky", "Sticky residue"]]:
			var hh := UI.hbox(10)
			var l := UI.lbl(k[1], 18, UI.MUTED)
			l.custom_minimum_size.x = 300
			hh.add_child(l)
			var val := float(st.get(k[0], 0.0))
			hh.add_child(UI.bar(val, UI.GREEN if val < 0.25 else (UI.AMBER if val < 0.5 else UI.RED), 10))
			c.add_child(hh)
	if r.has("violations"):
		if r["violations"].is_empty():
			c.add_child(UI.lbl("✓ Complies with the (fictional) FSC standard", 20, UI.GREEN, "semi"))
		for vv in r["violations"]:
			c.add_child(UI.para("✕ %s %.2f%% > limit %.2f%%" % [FormulaEngine.short_name(DB.ing(vv["id"])), float(vv["pct"]), float(vv["max"])], 19, UI.RED))
		if not r["allergens"].is_empty():
			c.add_child(UI.para("Label allergens: " + ", ".join(r["allergens"].map(func(a): return FormulaEngine.short_name(DB.ing(a)))), 18, UI.MUTED))
		c.add_child(UI.lbl("Natural content: %s" % G.pct(float(r["natural"])), 18, UI.MUTED))
		c.add_child(UI.para("Game simulation only — not a real safety assessment.", 15, UI.DIM))
