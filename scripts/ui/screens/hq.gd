extends Screen
## Headquarters: visual building, tier upgrades, departments and staffing.

func page_title() -> String:
	return "Headquarters"


func build() -> void:
	var c := G.pc()
	var tier := int(c["hq"]["tier"])
	var t := DB.hq_tier(tier)
	var hero := Art.hero(body, Art.hq_scene(tier), t["name"], "Your headquarters · %s" % DB.country(c["home"])["name"], 440, Vector2(0.5, 0.35), c["name"])
	if int(c["hq"].get("weeks_left", 0)) > 0:
		var pill := UI.pill("Construction · %d weeks left" % int(c["hq"]["weeks_left"]), UI.AMBER, 17)
		pill.position = Vector2(16, 16)
		hero.add_child(pill)
	var ep := GradPanel.new().colors(Color("#fffdf9"), Color("#f2f4ea")).set_pad(16)
	var tpth := TierPath.new()
	tpth.tier = tier
	tpth.custom_minimum_size = Vector2(0, 128)
	ep.add_child(tpth)
	body.add_child(ep)
	var hcp := GradPanel.new().colors(Color("#fffdf9"), Color("#f7efe4")).set_pad(18)
	body.add_child(hcp)
	var hc := UI.vbox(10)
	hcp.add_child(hc)
	hc.add_child(UI.lbl("WHAT YOUR BUILDING GIVES YOU", 16, UI.GOLD, "semi"))
	UI.kv(hc, "Staff capacity", "%d / %d" % [Staff.count(G.pid()), int(t["cap"])])
	UI.kv(hc, "Perfumer project slots", str(t["slots"]))
	UI.kv(hc, "Foreign offices", "%d / %d" % [c["offices"].size() - 1, int(t["offices"])])
	UI.kv(hc, "Brands", "%d / %d" % [G.company_brands(G.pid()).size(), int(t["brands"])])
	UI.kv(hc, "Lab test level", str(t["test"]))
	UI.kv(hc, "Upkeep", "%s/week" % G.money(float(t["upkeep"])))
	if t["delegation"].is_empty():
		UI.kv(hc, "Delegation", "Not available")
	else:
		UI.kv(hc, "Delegation", "%d functions" % t["delegation"].size())
	if int(c["hq"].get("weeks_left", 0)) > 0:
		var nx := DB.hq_tier(int(c["hq"]["build_to"]))
		var bc := UI.card(body, "flat")
		bc.add_child(UI.lbl("Building %s · %d weeks left" % [nx["name"], int(c["hq"]["weeks_left"])], 22, UI.GOLD2, "semi"))
		bc.add_child(UI.bar(1.0 - float(c["hq"]["weeks_left"]) / float(nx["weeks"]), UI.GOLD, 12))
	elif tier < 4:
		var nx2 := DB.hq_tier(tier + 1)
		UI.section(body, "Your next home")
		var up := GradPanel.new().colors(Color("#fdf6ee"), Color("#f6e6dc")).set_pad(12)
		up.border = Color(UI.GOLD, 0.45)
		body.add_child(up)
		var uc := UI.vbox(10)
		up.add_child(uc)
		var prev := Art.banner(Art.hq_scene(tier + 1), 300, c["name"], 18)
		prev.focus = Vector2(0.5, 0.35)
		uc.add_child(prev)
		uc.add_child(UI.title(str(nx2["name"]), 28, UI.BURGUNDY))
		uc.add_child(UI.para("Capacity %d staff · %d project slots · %d foreign offices · %d brands · upkeep %s/week. Unlocks: %s." % [int(nx2["cap"]), int(nx2["slots"]), int(nx2["offices"]), int(nx2["brands"]), G.money(float(nx2["upkeep"])),
			", ".join(nx2["depts"].filter(func(d): return not t["depts"].has(d)).map(func(d): return DB.biz["departments"][d]["name"]))], 19, UI.TEXT))
		uc.add_child(UI.btn("Build for %s (%d weeks)" % [G.money(float(nx2["cost"])), int(nx2["weeks"])], func():
			Router.confirm("Upgrade headquarters?", "Invest %s in a %s. Construction takes %d weeks; your company keeps operating." % [G.money(float(nx2["cost"])), nx2["name"], int(nx2["weeks"])], func():
				var e := CompanyEngine.hq_upgrade(c)
				Router.toast(e if e != "" else "Construction started!", "bad" if e != "" else "good")
				G.touch()), "primary", 22))
	UI.section(body, "Departments")
	for d in DB.biz["departments"]:
		var dd: Dictionary = DB.biz["departments"][d]
		var lvl := int(c["depts"].get(d, 0))
		var allowed: bool = t["depts"].has(d)
		var dcp := GradPanel.new().colors(Color("#fffdf9") if allowed else Color("#f4efe9"), Color("#f7efe6") if allowed else Color("#eee6de")).set_pad(16)
		body.add_child(dcp)
		var dc := UI.vbox(6)
		dcp.add_child(dc)
		var h := UI.hbox(8)
		h.add_child(UI.lbl(dd["name"], 22, UI.CREAM if allowed else UI.DIM, "semi"))
		h.add_child(UI.expand(UI.spacer()))
		h.add_child(UI.pill(("Level %d" % lvl) if allowed and lvl > 0 else "Locked", UI.GOLD if allowed else UI.DIM))
		dc.add_child(h)
		dc.add_child(UI.lbl(dd["desc"], 17, UI.MUTED))
		var staff: Array = []
		var faces := UI.hbox(-14)
		for r in dd["roles"]:
			for e in G.company_employees(G.pid(), r):
				staff.append("%s (%s)" % [e["name"], DB.role(r)["name"]])
				if faces.get_child_count() < 6:
					var av := Avatar.new().for_employee(e)
					av.custom_minimum_size = Vector2(52, 52)
					faces.add_child(av)
		if faces.get_child_count() > 0:
			dc.add_child(faces)
		dc.add_child(UI.para(("Staff: " + ", ".join(staff)) if not staff.is_empty() else "No staff yet.", 17, UI.TEXT if not staff.is_empty() else UI.DIM))
		if allowed:
			var row := UI.hbox(8)
			var role0: String = dd["roles"][0]
			row.add_child(UI.btn("Hire", func(): Router.go("recruit", {"role": role0}), "secondary", 19, 56))
			var ups: Array = dd["upgrades"]
			if lvl > 0 and lvl < ups.size():
				var dept: String = d
				row.add_child(UI.btn("Upgrade (%s)" % G.money(float(ups[lvl])), func():
					var e2 := CompanyEngine.dept_upgrade(c, dept)
					Router.toast(e2 if e2 != "" else "Department upgraded.", "bad" if e2 != "" else "good")
					G.touch(), "secondary", 19, 56))
			dc.add_child(row)
