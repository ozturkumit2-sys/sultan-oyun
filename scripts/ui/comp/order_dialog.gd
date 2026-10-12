class_name OrderDialog
extends RefCounted
## Re-order production for an existing product.

static func open(p: Dictionary) -> void:
	var st := {"mfr": "own" if ProductionEngine.has_factory(G.pid()) else G.pc().get("default_mfr", "meridian"), "qty": 0, "mat": int(p.get("maturation", 0)), "chill": true}
	var avg := Rivals.avg_units(p, 4) if not p["wk"].is_empty() else 50.0
	Router.modal("Produce %s" % p["name"], func(v: VBoxContainer):
		var mfrs: Array = []
		if ProductionEngine.has_factory(G.pid()):
			mfrs.append(["Own factory", "own"])
		for m in DB.biz["manufacturers"]:
			mfrs.append([m["name"], m["id"]])
		var quote := UI.vbox(6)
		var ql := UI.lbl("", 24, UI.GOLD2, "semi")
		var sl_holder := {}
		var redo := func():
			for ch in quote.get_children():
				ch.queue_free()
			var mf := ProductionEngine.mfr_info(G.pid(), st["mfr"])
			var q := ProductionEngine.quote(G.pid(), p, int(st["qty"]), st["mfr"], {"maturation": st["mat"], "chill": st["chill"]})
			ql.text = "%s units (min %s)" % [G.group_int(int(st["qty"])), G.group_int(int(mf["moq"]))]
			UI.kv(quote, "Materials to buy", G.money(float(q["buy_cost"])))
			UI.kv(quote, "Packaging, filling & setup", G.money(float(q["conv"])))
			UI.kv(quote, "Unit cost", G.money(float(q["unit_est"]), 2), UI.GOLD2)
			UI.kv(quote, "Cash now", G.money(float(q["total_cash"])), UI.RED if float(q["total_cash"]) > FinanceEngine.cash_of(G.pc()) else UI.GREEN)
			UI.kv(quote, "Ready in", "%d week(s)" % int(q["weeks"]))
			UI.kv(quote, "Covers about", "%.0f weeks of recent sales" % (float(st["qty"]) / maxf(1.0, avg)))
		var seg := UI.seg(mfrs, st["mfr"], func(x): pass, 19)
		for b in seg.get_children():
			var btn := b as Button
			var val: String = ""
			for m2 in mfrs:
				if m2[0] == btn.text:
					val = m2[1]
			btn.pressed.connect(func():
				st["mfr"] = val
				var moq := int(ProductionEngine.mfr_info(G.pid(), val)["moq"])
				for b2 in seg.get_children():
					UI.style_btn(b2 as Button, "chip_on" if b2 == btn else "chip", 19)
				var sl: HSlider = sl_holder["s"]
				sl.min_value = moq
				if sl.value < moq:
					sl.value = moq
				redo.call())
		v.add_child(seg)
		var moq0 := int(ProductionEngine.mfr_info(G.pid(), st["mfr"])["moq"])
		st["qty"] = maxi(moq0, int(snappedf(avg * 8.0, 50.0)))
		var ed: Dictionary = p.get("edition", {})
		var mx := maxf(float(moq0) * 20.0, avg * 40.0)
		if ed.get("type", "") == "limited":
			mx = float(int(ed.get("limit", 0)) - int(ed.get("made", 0)))
			st["qty"] = mini(int(st["qty"]), int(mx))
		v.add_child(ql)
		var sl2 := UI.slider(float(moq0), maxf(float(moq0) + 1.0, mx), 50.0, float(st["qty"]), func(x):
			st["qty"] = int(x)
			redo.call())
		sl_holder["s"] = sl2
		v.add_child(sl2)
		v.add_child(quote)
		redo.call(), [["Cancel", Callable(), "secondary"], ["Place order", func():
			var e := ProductionEngine.place_order(G.pid(), p["id"], int(st["qty"]), st["mfr"], {"maturation": st["mat"], "chill": st["chill"]})
			Router.toast(e if e != "" else "Production order placed.", "bad" if e != "" else "good")
			G.pc()["default_mfr"] = st["mfr"] if st["mfr"] != "own" else G.pc().get("default_mfr", "meridian")
			G.touch(), "primary"]])
