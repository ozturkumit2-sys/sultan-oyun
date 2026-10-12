extends Screen
## Financial statements (P&L by period, balance sheet, cash flow summary).

var period := "month"
var offset := 0


func page_title() -> String:
	return "Financial statements"


func build() -> void:
	var c := G.pc()
	body.add_child(UI.seg([["Week", "week"], ["Month", "month"], ["Quarter", "quarter"], ["Year (52 wks)", "year"], ["By calendar year", "cal"], ["Balance sheet", "bs"]], period, func(v):
		period = v
		offset = 0
		rebuild(), 19))
	if period == "bs":
		_bs(c)
		return
	if period == "cal":
		_years(c)
		return
	var n: int = {"week": 1, "month": 4, "quarter": 13, "year": 52}[period]
	var hist: Array = c["fin"]["hist"]
	var nav := UI.hbox(8)
	nav.add_child(UI.btn("‹ Earlier", func():
		offset += n
		rebuild(), "secondary", 19, 56))
	var end_i := hist.size() - offset
	var start_i := maxi(0, end_i - n)
	var label := "%s – %s" % [G.short_date(int(hist[start_i]["w"])), G.short_date(int(hist[end_i - 1]["w"]))] if end_i > start_i and end_i <= hist.size() and start_i < hist.size() else "No data"
	nav.add_child(UI.lbl(label, 19, UI.TEXT, "semi", HORIZONTAL_ALIGNMENT_CENTER))
	var later := UI.btn("Later ›", func():
		offset = maxi(0, offset - n)
		rebuild(), "secondary", 19, 56)
	later.disabled = offset == 0
	nav.add_child(later)
	body.add_child(nav)
	_pl(FinanceEngine.period(c, n, offset))


func _pl(p: Dictionary) -> void:
	var s := FinanceEngine.summarize(p)
	var cc := UI.card(body)
	cc.add_child(UI.lbl("INCOME STATEMENT", 16, UI.GOLD, "semi"))
	_line(cc, "Revenue", float(s["revenue"]), true)
	_line(cc, "Returns & refunds", float(s["returns"]))
	_line(cc, "Cost of goods sold", float(s["cogs"]))
	_line(cc, "Gross profit", float(s["gross"]), true)
	cc.add_child(UI.lbl("Gross margin %s" % G.pct(float(s["margin"])), 17, UI.MUTED))
	UI.divider(cc)
	for k in FinanceEngine.OPEX:
		if absf(float(p.get(k, 0.0))) > 0.005:
			_line(cc, FinanceEngine.CAT_NAMES[k], float(p.get(k, 0.0)))
	_line(cc, "Operating profit", float(s["operating"]), true)
	_line(cc, "EBITDA", float(s["ebitda"]))
	UI.divider(cc)
	for k in ["interest", "other_income"]:
		if absf(float(p.get(k, 0.0))) > 0.005:
			_line(cc, FinanceEngine.CAT_NAMES[k], float(p.get(k, 0.0)))
	_line(cc, "Profit before tax", float(s["pretax"]), true)
	_line(cc, "Taxes (simplified rule)", float(p.get("tax", 0.0)))
	_line(cc, "Net result", float(s["net"]), true)
	cc.add_child(UI.lbl("Units sold: %s" % G.group_int(int(p.get("u", 0))), 17, UI.MUTED))


func _line(parent: Control, name: String, v: float, bold := false) -> void:
	var h := UI.hbox(10)
	var l := UI.lbl(name, 21 if bold else 20, UI.CREAM if bold else UI.MUTED, "semi" if bold else "body")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(UI.lbl(G.money(v), 21 if bold else 20, (UI.GREEN if v >= 0.0 else UI.RED) if bold else UI.TEXT, "semi" if bold else "body", HORIZONTAL_ALIGNMENT_RIGHT))
	parent.add_child(h)


func _bs(c: Dictionary) -> void:
	var f: Dictionary = c["fin"]
	var cc := UI.card(body)
	cc.add_child(UI.lbl("BALANCE SHEET — " + G.date_str(), 16, UI.GOLD, "semi"))
	_line(cc, "Cash", float(f["cash"]))
	_line(cc, "Raw materials", FinanceEngine.raw_value(c))
	_line(cc, "Materials in transit", ProductionEngine.transit_value(c["id"]))
	_line(cc, "Work in progress", FinanceEngine.wip_value(c["id"]))
	_line(cc, "Finished goods", FinanceEngine.fg_value(c["id"]))
	_line(cc, "Property & equipment", float(f["ppe"]))
	_line(cc, "Goodwill", float(f["goodwill"]))
	_line(cc, "Total assets", FinanceEngine.assets(c), true)
	UI.divider(cc)
	_line(cc, "Debt", -float(f["debt"]))
	_line(cc, "Paid-in capital", float(f["paid_in"]))
	_line(cc, "Retained earnings", float(f["retained"]))
	_line(cc, "Total equity", FinanceEngine.equity(c), true)
	var gap := FinanceEngine.balance_gap(c)
	cc.add_child(UI.lbl("Assets − liabilities − equity = %s" % G.money(gap, 2), 16, UI.GREEN if absf(gap) < 1.0 else UI.RED))
	var t := FinanceEngine.ttm(c)
	var cf := UI.card(body)
	cf.add_child(UI.lbl("CASH FLOW (52 WEEKS, SIMPLIFIED)", 16, UI.GOLD, "semi"))
	var hist: Array = f["hist"]
	var start_cash := float(hist[maxi(0, hist.size() - 52)]["cash"]) if not hist.is_empty() else float(f["cash"])
	_line(cf, "Net result", float(t["net"]))
	_line(cf, "Change in cash", float(f["cash"]) - start_cash, true)


func _years(c: Dictionary) -> void:
	var ys: Dictionary = c["fin"]["years"]
	var ks: Array = ys.keys()
	ks.sort()
	ks.reverse()
	for y in ks:
		var s := FinanceEngine.summarize(ys[y])
		var cc := UI.card(body, "flat", 4)
		cc.add_child(UI.lbl(str(y), 24, UI.GOLD2, "title"))
		_line(cc, "Revenue", float(s["revenue"]))
		_line(cc, "Gross profit", float(s["gross"]))
		_line(cc, "Operating profit", float(s["operating"]))
		_line(cc, "Net result", float(s["net"]), true)
		cc.add_child(UI.lbl("Units sold %s" % G.group_int(int(ys[y].get("u", 0))), 17, UI.MUTED))
