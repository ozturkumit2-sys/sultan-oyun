extends Screen
## Finance overview.

func page_title() -> String:
	return "Finance"


func build() -> void:
	var c := G.pc()
	var t := FinanceEngine.ttm(c)
	var f: Dictionary = c["fin"]
	var g := UI.grid(2, 10)
	g.add_child(UI.stat("Cash", G.money(float(f["cash"]))))
	g.add_child(UI.stat("Debt", G.money(float(f["debt"])), "", UI.RED if float(f["debt"]) > 0.0 else UI.CREAM))
	g.add_child(UI.stat("Revenue (52 wks)", G.money(float(t["revenue"]))))
	g.add_child(UI.stat("Net result (52 wks)", G.money(float(t["net"])), "", UI.GREEN if float(t["net"]) >= 0.0 else UI.RED))
	g.add_child(UI.stat("Equity", G.money(FinanceEngine.equity(c))))
	g.add_child(UI.stat("Valuation", G.money(FinanceEngine.valuation(c)), "your stake %s" % G.pct(Corporate.founder_pct(c)), UI.GOLD2))
	body.add_child(g)
	var hist: Array = f["hist"]
	if hist.size() >= 2:
		var cc := UI.card(body)
		cc.add_child(UI.lbl("CASH", 16, UI.GOLD, "semi"))
		var ch := LineChart.new()
		var vals: Array = []
		var xl: Array = []
		var sl := hist.slice(maxi(0, hist.size() - 52))
		for i in sl.size():
			vals.append(float(sl[i]["cash"]))
			xl.append(G.short_date(int(sl[i]["w"])) if i % 13 == 0 else "")
		ch.min_zero = false
		ch.set_data([{"v": vals, "c": UI.GOLD}], xl)
		cc.add_child(ch)
	var g2 := UI.grid(2, 12)
	UI.tile(g2, "finance", "Financial statements", "P&L, balance sheet, cash flow", func(): Router.go("statements"))
	UI.tile(g2, "bank", "Loans & credit", "%d active loans" % FinanceEngine.company_loans(G.pid()).size(), func(): Router.go("loans"))
	UI.tile(g2, "deal", "Investors & board", "Funding, IPO, dividends", func(): Router.go("investors"))
	UI.tile(g2, "chart", "Weekly reports", "Recent results", func(): Router.go("reports"))
	UI.tile(g2, "mail", "Inbox", "%d open" % G.inbox_open().size(), func(): Router.go("inbox"))
	UI.tile(g2, "save", "Save / load", "Manual save slots", func(): Router.go("save_load", {"mode": "save"}))
	UI.tile(g2, "cog", "Settings", "Audio, autosave", func(): Router.go("settings"))
	UI.tile(g2, "trophy", "Awards", "Annual industry awards", func(): Router.go("awards"))
	body.add_child(g2)
