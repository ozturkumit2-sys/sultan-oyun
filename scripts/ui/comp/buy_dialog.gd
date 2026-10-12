class_name BuyDialog
extends RefCounted
## Spot purchase of a raw material.

static func open(id: String) -> void:
	var rec := DB.ing(id)
	var price := G.ing_price(id)
	Router.number("Buy %s" % FormulaEngine.short_name(rec), 5.0, 0.5, 500.0, 0.5, func(kg):
		var e := ProductionEngine.buy_material(G.pc(), id, kg)
		Router.toast(e if e != "" else "Ordered %.1f kg — arrives in %d week(s)." % [kg, ProductionEngine.lead_weeks(id)], "bad" if e != "" else "good")
		G.touch(), func(kg): return "%.1f kg · %s" % [kg, G.money(kg * price * (1.15 if kg < 2.0 else 1.0))],
		"Spot price %s/kg (+15%% for lots under 2 kg). Lead time %d week(s)." % [G.money(price), ProductionEngine.lead_weeks(id)])
