class_name SurveyCard
extends RefCounted

static func add(parent: Control, s: Dictionary) -> void:
	var r: Dictionary = s["res"]
	var c := UI.card(parent)
	var h := UI.hbox(8)
	h.add_child(UI.lbl("%s · %s · n=%d" % ["Blind" if r["blind"] else "Branded", DB.country(r["country"])["name"], int(r["n"])], 21, UI.CREAM, "semi"))
	h.add_child(UI.expand(UI.spacer()))
	h.add_child(UI.lbl("v%d · %s" % [int(s["v"]) + 1, G.short_date(int(s["w"]))], 16, UI.MUTED))
	c.add_child(h)
	var g := UI.grid(2, 8)
	g.add_child(UI.stat("Liking", "%.1f / 10" % float(r["like"]), "± %.2f (95%%)" % float(r["moe"])))
	g.add_child(UI.stat("Would buy", G.pct(float(r["intent"])), "± %s" % G.pct(float(r["intent_moe"]), 1)))
	c.add_child(g)
	var lf: Array = r["long_fb"]
	var pf: Array = r["proj_fb"]
	var n := float(r["n"])
	c.add_child(UI.lbl("Longevity: %s too short · %s about right · %s very long" % [G.pct(float(lf[0]) / n), G.pct(float(lf[1]) / n), G.pct(float(lf[2]) / n)], 18, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
	c.add_child(UI.lbl("Projection: %s too soft · %s right · %s too loud" % [G.pct(float(pf[0]) / n), G.pct(float(pf[1]) / n), G.pct(float(pf[2]) / n)], 18, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
	UI.divider(c)
	c.add_child(UI.lbl("BY CONSUMER SEGMENT", 16, UI.GOLD, "semi"))
	for sg in r["segments"]:
		var sh := UI.hbox(8)
		var l := UI.lbl("%s (%d)" % [sg["seg"], int(sg["n"])], 18, UI.MUTED)
		l.custom_minimum_size.x = 300
		sh.add_child(l)
		sh.add_child(UI.bar((float(sg["like"]) - 1.0) / 9.0, UI.GOLD, 9))
		sh.add_child(UI.lbl("%.1f" % float(sg["like"]), 17, UI.TEXT))
		c.add_child(sh)
	var pa: Array = r.get("price_accept", [])
	if not pa.is_empty():
		UI.divider(c)
		c.add_child(UI.lbl("PRICE ACCEPTANCE", 16, UI.GOLD, "semi"))
		var bars: Array = []
		for x in pa:
			bars.append([G.money(float(x[0]), 0), float(x[1]) * 100.0, UI.GOLD2])
		var bc := BarChart.new()
		bc.custom_minimum_size = Vector2(0, 180)
		bc.set_data(bars, "pct")
		c.add_child(bc)
		c.add_child(UI.lbl("% of respondents who would consider buying at each price", 15, UI.DIM))
	if not r["comments"].is_empty():
		UI.divider(c)
		for cm in r["comments"]:
			c.add_child(UI.para(str(cm), 18, UI.TEXT))
