extends Screen
## Bank loans and credit.

func page_title() -> String:
	return "Loans & credit"


func build() -> void:
	var c := G.pc()
	var lim := FinanceEngine.credit_limit(c)
	var used := float(c["fin"]["debt"])
	var rate := FinanceEngine.base_rate(c)
	var g := UI.grid(2, 10)
	g.add_child(UI.stat("Debt", G.money(used)))
	g.add_child(UI.stat("Credit limit", G.money(lim)))
	g.add_child(UI.stat("Offered rate", G.pct(rate, 1), "a finance manager lowers it"))
	g.add_child(UI.stat("Available", G.money(maxf(0.0, lim - used))))
	body.add_child(g)
	var bank: String = DB.names["banks"][hash(c["name"]) % DB.names["banks"].size()]
	body.add_child(UI.btn("Apply for a loan at %s" % bank, func():
		var avail := maxf(0.0, lim - used)
		if avail < 10000.0:
			Router.toast("The bank will not lend more right now.", "bad")
			return
		var st := {"amt": snappedf(minf(avail, 50000.0), 1000.0), "weeks": 104}
		Router.modal("New loan", func(v: VBoxContainer):
			var al := UI.lbl("", 26, UI.GOLD2, "title")
			v.add_child(al)
			var pl := UI.lbl("", 19, UI.MUTED)
			var upd := func():
				al.text = G.money(float(st["amt"]))
				var wr := rate / 52.0
				var pay := float(st["amt"]) * wr / (1.0 - pow(1.0 + wr, -int(st["weeks"])))
				pl.text = "%d weeks · %s interest · weekly payment %s" % [int(st["weeks"]), G.pct(rate, 1), G.money(pay)]
			v.add_child(UI.slider(10000.0, maxf(10001.0, avail), 1000.0, float(st["amt"]), func(x):
				st["amt"] = x
				upd.call()))
			v.add_child(UI.seg([["1 year", 52], ["2 years", 104], ["3 years", 156], ["5 years", 260]], 104, func(x):
				st["weeks"] = x
				upd.call()))
			v.add_child(pl)
			upd.call(), [["Cancel", Callable(), "secondary"], ["Take loan", func():
				FinanceEngine.take_loan(c, float(st["amt"]), int(st["weeks"]), rate)
				G.log_event("Loan of %s from %s at %s." % [G.money(float(st["amt"])), bank, G.pct(rate, 1)], "info")
				G.touch(), "primary"]]), "primary", 22))
	UI.section(body, "Active loans")
	var ls := FinanceEngine.company_loans(G.pid())
	if ls.is_empty():
		UI.empty(body, "No loans.")
	for ln in ls:
		var cc := UI.card(body, "flat", 4)
		cc.add_child(UI.lbl("%s — %s left" % ["Emergency credit line" if ln["kind"] == "overdraft" else "Term loan", G.money(float(ln["left"]))], 21, UI.CREAM, "semi"))
		cc.add_child(UI.lbl("Rate %s · %s" % [G.pct(float(ln["rate"]), 1), ("weekly payment %s · %d weeks left" % [G.money(float(ln["pay"])), int(ln["weeks_left"])]) if ln["kind"] != "overdraft" else "repaid automatically when cash allows"], 17, UI.MUTED))
		var lid: String = ln["id"]
		cc.add_child(UI.btn("Repay early", func():
			for l2 in G.s["loans"]:
				if l2["id"] == lid:
					var amt := minf(float(l2["left"]), FinanceEngine.cash_of(c) - 1000.0)
					if amt <= 0.0:
						Router.toast("Not enough cash.", "bad")
						return
					FinanceEngine.repay(c, amt)
					l2["left"] = float(l2["left"]) - amt
					if float(l2["left"]) <= 0.5:
						G.s["loans"].erase(l2)
					G.touch()
					return, "ghost", 18, 50))
