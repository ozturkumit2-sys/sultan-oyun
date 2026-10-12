extends Screen
## Weekly result history.

func page_title() -> String:
	return "Weekly reports"


func hero_spec() -> Dictionary:
	return {"scene": "office", "title": "Weekly reports", "sub": "How the house performed", "focus": Vector2(0.75, 0.5), "h": 250.0}


func build() -> void:
	var reps: Array = G.s["reports"]
	if reps.is_empty():
		UI.empty(body, "Reports appear after your first week.")
		return
	var c := G.pc()
	var bars: Array = []
	for r in reps.slice(maxi(0, reps.size() - 12)):
		bars.append([str(G.week_of_year(int(r["w"]))), float(r["rev"]), UI.GOLD])
	var cc := UI.card(body)
	cc.add_child(UI.lbl("REVENUE BY WEEK", 16, UI.GOLD, "semi"))
	var bc := BarChart.new()
	bc.set_data(bars)
	cc.add_child(bc)
	var m4 := FinanceEngine.summarize(FinanceEngine.period(c, 4))
	var y := FinanceEngine.summarize(FinanceEngine.period(c, 52))
	var g := UI.grid(2, 8)
	g.add_child(UI.stat("Month revenue", G.money(float(m4["revenue"]))))
	g.add_child(UI.stat("Month net", G.money(float(m4["net"])), "", UI.GREEN if float(m4["net"]) >= 0.0 else UI.RED))
	g.add_child(UI.stat("Year revenue", G.money(float(y["revenue"]))))
	g.add_child(UI.stat("Year net", G.money(float(y["net"])), "", UI.GREEN if float(y["net"]) >= 0.0 else UI.RED))
	body.add_child(g)
	for i in range(reps.size() - 1, -1, -1):
		var r: Dictionary = reps[i]
		var rc := UI.card(body, "flat", 4)
		var h := UI.hbox(8)
		h.add_child(UI.lbl(G.date_str(int(r["w"])), 20, UI.CREAM, "semi"))
		h.add_child(UI.expand(UI.spacer()))
		h.add_child(UI.lbl("%s · net %s" % [G.money(float(r["rev"])), G.money(float(r["net"]))], 19, UI.GREEN if float(r["net"]) >= 0.0 else UI.RED, "semi"))
		rc.add_child(h)
		rc.add_child(UI.lbl("%s units sold" % G.group_int(int(r["u"])), 17, UI.MUTED))
		for e in r.get("launch", []):
			rc.add_child(UI.lbl("Launched: " + str(e), 17, UI.GREEN))
		for e2 in r.get("ev", []):
			rc.add_child(UI.lbl("• " + str(e2), 17, UI.TEXT, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
