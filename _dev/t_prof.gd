extends Node

func run(_args: Array) -> void:
	WorldGen.new_game({"company": "Test House", "brand": "Test", "home": "TR", "posit": "premium", "seed": 42})
	for i in 3:
		Sim.advance()
	var rep := Sim.empty_report()
	var r := G.rng
	var t := Time.get_ticks_usec()
	var marks := []
	G.clear_cache(false)
	Delegation.weekly(rep); marks.append(["deleg", Time.get_ticks_usec()])
	for c in Sim._companies(): Lab.weekly(c, rep)
	marks.append(["lab", Time.get_ticks_usec()])
	ProductionEngine.weekly(rep); marks.append(["prod", Time.get_ticks_usec()])
	MarketingEngine.weekly(rep); marks.append(["mkt", Time.get_ticks_usec()])
	for c in Sim._companies(): Rivals.weekly(c, r, rep)
	marks.append(["rivals", Time.get_ticks_usec()])
	MarketEngine.run_week(rep); marks.append(["market", Time.get_ticks_usec()])
	for c in Sim._companies():
		Staff.weekly(c)
		FinanceEngine.service_loans(c)
		Corporate.weekly(c, rep)
		FinanceEngine.close_week(c, 0)
	marks.append(["fin", Time.get_ticks_usec()])
	for c in Sim._companies(): Corporate.reputation(c)
	marks.append(["rep", Time.get_ticks_usec()])
	IngredientMarket.weekly(r); Events.weekly(r, rep); MarketEngine.decay(); marks.append(["events", Time.get_ticks_usec()])
	var prev := t
	for m in marks:
		print("%-8s %6.1f ms" % [m[0], (m[1] - prev) / 1000.0])
		prev = m[1]
	print("products ", G.s["products"].size())
