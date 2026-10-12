extends Screen
## Employee profile and HR actions.

func page_title() -> String:
	return G.employee(params.get("id", "")).get("name", "Employee")


func build() -> void:
	var e := G.employee(params["id"])
	if e.is_empty():
		return
	var mine: bool = e.get("employer", "") == G.pid()
	var hc := UI.card(body, "gold")
	var h := UI.hbox(14)
	var av := Avatar.new()
	av.seed_text = e["name"]
	av.fem = e.get("fem", false)
	av.custom_minimum_size = Vector2(110, 110)
	h.add_child(av)
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.title(e["name"], 30))
	v.add_child(UI.lbl(Staff.title_name(e), 20, UI.GOLD2, "semi"))
	var emp := G.company(e.get("employer", ""))
	v.add_child(UI.lbl(("at " + emp["name"]) if not emp.is_empty() else "Available", 18, UI.MUTED))
	v.add_child(UI.lbl("%d years of experience" % int(e["exp"]), 18, UI.MUTED))
	h.add_child(v)
	hc.add_child(h)
	UI.section(body, "Skills")
	var sc := UI.card(body)
	if e["role"] == "perfumer":
		for k in [["creativity", "Creativity"], ["technique", "Technical competence"], ["cost", "Cost awareness"], ["productivity", "Productivity"]]:
			_bar(sc, k[1], float(e["skills"].get(k[0], 0.5)), UI.GOLD)
		sc.add_child(UI.lbl("Specialties: " + ", ".join(e["spec"]), 18, UI.TEXT))
	else:
		_bar(sc, "Skill", float(e["skill"]), UI.GOLD)
		sc.add_child(UI.para(_effect(e["role"]), 18))
	_bar(sc, "Motivation", float(e["motivation"]), UI.GREEN if float(e["motivation"]) > 0.45 else UI.RED)
	_bar(sc, "Loyalty", float(e["loyalty"]), UI.BLUE)
	_bar(sc, "Reputation", float(e["reputation"]), UI.ROSE)
	UI.section(body, "Contract")
	var cc := UI.card(body, "flat", 6)
	UI.kv(cc, "Salary", G.money(float(e["salary"])) + "/year")
	UI.kv(cc, "Market value", G.money(Staff.market_value(e)) + "/year", UI.GOLD2)
	if int(e["contract_end"]) >= 0:
		UI.kv(cc, "Contract ends", G.date_str(int(e["contract_end"])))
	if e["role"] == "country_manager" and mine:
		UI.kv(cc, "Assigned country", DB.country(e.get("country", "")).get("name", "Unassigned"))
	if e["role"] == "perfumer":
		UI.kv(cc, "Formulas approved", str(int(e.get("formulas", 0))))
		UI.kv(cc, "Products launched", str(int(e.get("launches", 0))))
		var pj: Dictionary = e.get("project", {})
		if not pj.is_empty():
			UI.kv(cc, "Current project", "%s (%d wks left)" % [pj["brief"].get("family", "?"), int(pj["weeks_left"])])
	if mine:
		UI.section(body, "Actions")
		var a := UI.grid(2, 8)
		var eid: String = e["id"]
		a.add_child(UI.btn("Training", func():
			var r := Staff.train(G.pid(), eid)
			Router.toast(r if r != "" else "Training started (4 weeks).", "bad" if r != "" else "good")
			G.touch(), "secondary", 21, 68))
		a.add_child(UI.btn("Promote", func(): _promote(eid), "secondary", 21, 68))
		a.add_child(UI.btn("Adjust salary", func(): _salary(eid), "secondary", 21, 68))
		a.add_child(UI.btn("Renew contract", func(): _renew(eid), "secondary", 21, 68))
		if e["role"] == "perfumer":
			a.add_child(UI.btn("Commission brief", func(): Router.go("briefs"), "primary", 21, 68))
		if e["role"] == "country_manager":
			a.add_child(UI.btn("Assign country", func():
				var opts: Array = []
				for k in G.pc()["offices"]:
					opts.append([DB.country(k)["name"], k])
				Router.pick("Assign to office", opts, func(k):
					for k2 in G.pc()["offices"]:
						if G.pc()["offices"][k2].get("manager", "") == eid:
							G.pc()["offices"][k2]["manager"] = ""
					G.pc()["offices"][k]["manager"] = eid
					e["country"] = k
					G.cache.erase("reach")
					G.touch()), "primary", 21, 68))
		a.add_child(UI.btn("Dismiss", func(): Router.confirm("Dismiss %s?" % e["name"], "Severance: %s (8 weeks of salary). Colleagues' morale drops slightly." % G.money(float(e["salary"]) / 52.0 * 8.0), func():
			Staff.dismiss(G.pid(), eid)
			G.touch()
			Router.back(), "Dismiss", true), "danger", 21, 68))
		body.add_child(a)
	UI.section(body, "Career history")
	var hist: Array = e["history"]
	for i in range(hist.size() - 1, -1, -1):
		var row := UI.hbox(10)
		row.add_child(UI.lbl(G.short_date(int(hist[i][0])) if int(hist[i][0]) >= 0 else "Earlier", 16, UI.DIM))
		row.add_child(UI.lbl(str(hist[i][1]), 19, UI.TEXT, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
		body.add_child(row)


func _bar(parent: Control, name: String, v: float, col: Color) -> void:
	var h := UI.hbox(10)
	var l := UI.lbl(name, 19, UI.MUTED)
	l.custom_minimum_size.x = 250
	h.add_child(l)
	h.add_child(UI.bar(v, col, 10))
	h.add_child(UI.lbl(str(int(v * 100)), 18, UI.TEXT, "semi"))
	parent.add_child(h)


func _effect(role: String) -> String:
	return {"chemist": "Improves QC defect detection, lab measurement precision and rework success.",
		"research_manager": "Speeds up perfumer projects.",
		"production_manager": "Fewer filling defects and batch inconsistencies; required for delegated production and purchasing.",
		"marketing_manager": "Multiplies campaign effectiveness; required for delegated marketing.",
		"sales_manager": "Better retail terms (lower margins, higher reach); required for delegated pricing and distribution.",
		"finance_manager": "Lower interest rates and higher credit limits.",
		"hr_manager": "Lower recruitment fees, better motivation and retention, more effective training.",
		"country_manager": "Assigned to an office: increases distribution reach in that country.",
		"executive_manager": "Senior leadership for a growing group."}.get(role, "")


func _promote(eid: String) -> void:
	var e := G.employee(eid)
	Router.confirm("Promote %s?" % e["name"], "A new title raises salary by 12% and boosts motivation and loyalty.", func():
		var r2 := Staff.promote(G.pid(), eid)
		Router.toast(r2 if r2 != "" else "Promoted.", "bad" if r2 != "" else "good")
		G.touch())


func _salary(eid: String) -> void:
	var e := G.employee(eid)
	var fmt := func(x): return G.money(x)
	var apply := func(x):
		Staff.raise_salary(G.pid(), eid, x)
		G.touch()
	Router.number("Annual salary", float(e["salary"]), float(e["salary"]) * 0.8, float(e["salary"]) * 1.6, 500.0, apply, fmt, "Market value %s. Pay below value hurts motivation; raises help retention." % G.money(Staff.market_value(e)))


func _renew(eid: String) -> void:
	var e := G.employee(eid)
	var ask := Staff.market_value(e) * (1.05 - 0.15 * float(e["loyalty"]))
	Router.confirm("Renew for 3 years?", "%s asks for %s per year." % [e["name"], G.money(ask)], func():
		var r3 := Staff.renew(G.pid(), eid, maxf(ask, float(e["salary"])), 3)
		Router.toast(r3 if r3 != "" else "Contract renewed.", "bad" if r3 != "" else "good")
		G.touch())
