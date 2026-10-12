extends Screen
## Finance: the house treasury — valuation front and centre, figures, cash curve and money matters.

func page_title() -> String:
	return "Finance"


func env() -> String:
	return "finance"


func build() -> void:
	var c := G.pc()
	var t := FinanceEngine.ttm(c)
	var f: Dictionary = c["fin"]
	Art.hero(body, "skyline", G.money(FinanceEngine.valuation(c)), "Company valuation · your stake %s" % G.pct(Corporate.founder_pct(c)), 300, Vector2(0.5, 0.45))
	var g := UI.grid(2, 10)
	g.add_child(UI.kpi("finance", "Cash", G.money(float(f["cash"])), UI.BURGUNDY))
	g.add_child(UI.kpi("bank", "Debt", G.money(float(f["debt"])), UI.RED if float(f["debt"]) > 0.0 else UI.SAGE, func(): Router.go("loans")))
	g.add_child(UI.kpi("chart", "Revenue · 52 wks", G.money(float(t["revenue"])), UI.GOLD, func(): Router.go("statements")))
	g.add_child(UI.kpi("star", "Net result · 52 wks", G.money(float(t["net"])), UI.GREEN if float(t["net"]) >= 0.0 else UI.RED, func(): Router.go("statements")))
	g.add_child(UI.kpi("company", "Equity", G.money(FinanceEngine.equity(c)), UI.PLUM))
	g.add_child(UI.kpi("deal", "Owners", "%s you" % G.pct(Corporate.founder_pct(c)), UI.ROSE, func(): Router.go("investors")))
	body.add_child(g)
	var hist: Array = f["hist"]
	if hist.size() >= 2:
		UI.section(body, "Cash over the last year")
		var cc := UI.card(body)
		var ch := LineChart.new()
		var vals: Array = []
		var xl: Array = []
		var sl := hist.slice(maxi(0, hist.size() - 52))
		for i in sl.size():
			vals.append(float(sl[i]["cash"]))
			xl.append(G.short_date(int(sl[i]["w"])) if i % 13 == 0 else "")
		ch.min_zero = false
		ch.set_data([{"v": vals, "c": UI.BURGUNDY}], xl)
		cc.add_child(ch)
	UI.section(body, "Money matters")
	Art.grid2(body, [
		Art.card("office", "Statements", "P&L, balance sheet, cash flow", func(): Router.go("statements"), 0, Vector2(0.75, 0.5), 130),
		Art.card("hq2", "Loans & credit", "%d active loan%s" % [FinanceEngine.company_loans(G.pid()).size(), "" if FinanceEngine.company_loans(G.pid()).size() == 1 else "s"], func(): Router.go("loans"), 0, Vector2(0.5, 0.4), 130),
		Art.card("hq4", "Investors & board", "Funding, IPO, dividends", func(): Router.go("investors"), 0, Vector2(0.5, 0.3), 130),
		Art.card("office", "Weekly reports", "Recent results", func(): Router.go("reports"), 0, Vector2(0.2, 0.4), 130),
	])
	UI.section(body, "Desk")
	var n_open := G.inbox_open().size()
	UI.row_card(body, "Inbox", "%d decision%s waiting" % [n_open, "" if n_open == 1 else "s"], "", func(): Router.go("inbox"), UI.icon_bubble("mail", UI.ROSE, 48))
	UI.row_card(body, "Save / load", "Manual save slots (autosave every week)", "", func(): Router.go("save_load", {"mode": "save"}), UI.icon_bubble("save", UI.PLUM, 48))
	UI.row_card(body, "Settings", "Music, sounds, autosave", "", func(): Router.go("settings"), UI.icon_bubble("cog", UI.SAGE, 48))
