class_name Inbox
extends RefCounted
## Opens an inbox message with the decisions it requires.

static func find(mid: String) -> Dictionary:
	for m in G.s["inbox"]:
		if m["id"] == mid:
			return m
	return {}


static func open_item(mid: String) -> void:
	var m := find(mid)
	if m.is_empty():
		return
	var t: String = m.get("type", "info")
	var text: String = m.get("text", "")
	match t:
		"qc":
			var o := ProductionEngine.find_order(m["order"])
			if o.is_empty() or o["stage"] != "qc_hold":
				G.inbox_resolve(mid)
				Router.info(m["title"], text + "\n\nThis batch has already been handled.")
				return
			Router.modal(m["title"], func(v: VBoxContainer):
				v.add_child(UI.para(text, 22, UI.TEXT))
				v.add_child(UI.para("Rework costs about %s and takes a week; success depends on your chemist. Releasing sends defective units to customers (returns, complaints, reviews). Rejecting writes off the batch value of %s." % [G.money(float(o["value"]) * 0.15 + 500.0), G.money(float(o["value"]))], 20)),
				[["Reject", func(): _done(mid, func(): ProductionEngine.reject(o)), "danger"],
				["Release", func(): _done(mid, func(): ProductionEngine.release(o, true)), "secondary"],
				["Rework", func():
					var e := ProductionEngine.rework(o)
					if e != "":
						Router.toast(e, "bad")
					else:
						_done(mid, Callable()), "primary"]])
		"recall":
			var p := G.product(m["product"])
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["Keep selling", func():
					var b := G.brand(p["brand"])
					b["prestige"] = clampf(float(b["prestige"]) - 0.03, 0.0, 1.0)
					p["complaints"] = int(int(p.get("complaints", 0)) * 0.5)
					_done(mid, Callable()), "secondary"],
				["Recall", func(): _done(mid, func(): ProductionEngine.recall(p)), "primary"]])
		"contract":
			var e := G.employee(m["emp"])
			if e.is_empty() or e.get("employer", "") != G.pid():
				G.inbox_resolve(mid)
				return
			var ask := Staff.market_value(e) * (1.05 - 0.15 * float(e["loyalty"]))
			Router.modal(m["title"], func(v: VBoxContainer):
				v.add_child(UI.para(text, 22, UI.TEXT))
				UI.kv(v, "Current salary", G.money(float(e["salary"])))
				UI.kv(v, "Asks to renew", G.money(ask), UI.GOLD2),
				[["Let go", func(): _done(mid, Callable()), "secondary"],
				["Renew 2 years", func():
					var err := Staff.renew(G.pid(), e["id"], ask, 2)
					if err != "":
						Router.toast(err, "bad")
					_done(mid, Callable()), "primary"]])
		"poach":
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["Let them go", func():
					Router.toast(Staff.resolve_poach(mid, false))
					G.touch(), "secondary"],
				["Counter-offer", func():
					Router.toast(Staff.resolve_poach(mid, true), "good")
					G.touch(), "primary"]])
		"scandal":
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["Stand by them", func(): _done(mid, Callable()), "secondary"],
				["Terminate", func():
					for k in G.s["campaigns"]:
						if k.get("media", "") == m["media"] and k["status"] == "active" and k["company"] == G.pid():
							MarketingEngine.stop(k)
					_done(mid, Callable()), "danger"]])
		"deleg_prod":
			var p2 := G.product(m["product"])
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["Decline", func(): _done(mid, Callable()), "secondary"],
				["Approve", func():
					var err2 := ProductionEngine.place_order(G.pid(), p2["id"], int(m["qty"]), m["mfr"], {"maturation": int(p2.get("maturation", 0)), "chill": true})
					if err2 != "":
						Router.toast(err2, "bad")
					_done(mid, Callable()), "primary"]])
		"deleg_buy":
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["Decline", func(): _done(mid, Callable()), "secondary"],
				["Approve", func():
					var err4 := ProductionEngine.buy_material(G.pc(), m["ing"], float(m["kg"]))
					if err4 != "":
						Router.toast(err4, "bad")
					_done(mid, Callable()), "primary"]])
		"deleg_hire":
			var e2 := G.employee(m["emp"])
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["Decline", func(): _done(mid, Callable()), "secondary"],
				["Hire", func():
					var err3 := Staff.hire(G.pid(), e2["id"], float(e2["salary"]), 2) if not e2.is_empty() else "No longer available."
					Router.toast(err3 if err3 != "" else "Hired %s." % e2["name"], "bad" if err3 != "" else "good")
					_done(mid, Callable()), "primary"]])
		"shortage":
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["Dismiss", func(): _done(mid, Callable()), "secondary"], ["Ingredient market", func():
					_done(mid, Callable())
					Router.go("ingredient_market", {"ing": m.get("ing", "")}), "primary"]])
		"regulation":
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["OK", func(): _done(mid, Callable()), "secondary"], ["Formulas", func():
					_done(mid, Callable())
					Router.go("formulas"), "primary"]])
		"distress":
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)),
				[["OK", func(): _done(mid, Callable()), "secondary"], ["Finance", func():
					_done(mid, Callable())
					Router.go_tab("finance"), "primary"]])
		_:
			Router.modal(m["title"], func(v: VBoxContainer): v.add_child(UI.para(text, 22, UI.TEXT)), [["OK", func(): _done(mid, Callable()), "primary"]])


static func _done(mid: String, action: Callable) -> void:
	if action.is_valid():
		action.call()
	G.inbox_resolve(mid)
	G.touch()
