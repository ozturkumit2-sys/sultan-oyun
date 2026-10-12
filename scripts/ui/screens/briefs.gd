extends Screen
## Commission fragrance projects from your perfumers.

var st := {"emp": "", "family": "Woody Amber", "audience": "any", "fmt": "edp", "cost": 150.0, "long": 0.0}


func page_title() -> String:
	return "Project briefs"


func build() -> void:
	var perfs := G.company_employees(G.pid(), "perfumer")
	body.add_child(UI.para("Project slots in use: %d of %d. Your perfumers use the same ingredients and formulation model as you — skill improves consistency, not guaranteed success." % [Lab.active_projects(G.pid()), Lab.project_slots(G.pid())], 19))
	if perfs.is_empty():
		UI.empty(body, "You have no perfumers yet.")
		body.add_child(UI.btn("Hire a perfumer", func(): Router.go("recruit", {"role": "perfumer"}), "primary", 22))
		return
	UI.section(body, "Your perfumers")
	for e in perfs:
		var pj: Dictionary = e.get("project", {})
		var c := UI.card(body, "flat", 6)
		var h := UI.hbox(8)
		h.add_child(UI.lbl(e["name"], 22, UI.CREAM, "semi"))
		h.add_child(UI.expand(UI.spacer()))
		h.add_child(UI.lbl("skill %d" % int(Staff.perfumer_skill(e) * 100), 18, UI.GOLD2))
		c.add_child(h)
		c.add_child(UI.lbl("Specialties: " + ", ".join(e["spec"]), 17, UI.MUTED))
		if pj.is_empty():
			c.add_child(UI.lbl("Idle", 18, UI.GREEN))
		else:
			c.add_child(UI.lbl("%s: %s · %d of %d weeks left" % ["Brief" if pj["kind"] == "brief" else "Own idea", pj["brief"].get("family", "?"), int(pj["weeks_left"]), int(pj["weeks"])], 18, UI.TEXT))
			c.add_child(UI.bar(1.0 - float(pj["weeks_left"]) / float(maxi(1, int(pj["weeks"]))), UI.GOLD, 8))
	UI.section(body, "New brief")
	if st["emp"] == "" or G.employee(st["emp"]).is_empty():
		st["emp"] = perfs[0]["id"]
	var eo: Array = []
	for e in perfs:
		eo.append([e["name"], e["id"]])
	body.add_child(UI.seg(eo, st["emp"], func(v):
		st["emp"] = v
		rebuild(), 19))
	var fo: Array = []
	for k in DB.bal["families"]:
		fo.append([k, k])
	body.add_child(UI.lbl("Fragrance family", 19, UI.MUTED))
	body.add_child(UI.seg(fo, st["family"], func(v):
		st["family"] = v
		rebuild(), 18))
	body.add_child(UI.lbl("Audience", 19, UI.MUTED))
	body.add_child(UI.seg([["Feminine", "fem"], ["Masculine", "masc"], ["Unisex", "any"]], st["audience"], func(v):
		st["audience"] = v
		rebuild(), 19))
	var fmo: Array = []
	for fm in DB.biz["formats"]:
		fmo.append([fm["name"], fm["id"]])
	body.add_child(UI.lbl("Format", 19, UI.MUTED))
	body.add_child(UI.seg(fmo, st["fmt"], func(v):
		st["fmt"] = v
		rebuild(), 18))
	var cl := UI.lbl("Max concentrate cost: %s/kg" % G.money(float(st["cost"])), 20, UI.GOLD2, "semi")
	body.add_child(cl)
	body.add_child(UI.slider(20, 3000, 10, float(st["cost"]), func(x):
		st["cost"] = x
		cl.text = "Max concentrate cost: %s/kg" % G.money(x)))
	var ll := UI.lbl("Minimum longevity: %s" % ("none" if float(st["long"]) <= 0.0 else "%.0fh" % float(st["long"])), 20, UI.GOLD2, "semi")
	body.add_child(ll)
	body.add_child(UI.slider(0, 16, 1, float(st["long"]), func(x):
		st["long"] = x
		ll.text = "Minimum longevity: %s" % ("none" if x <= 0.0 else "%.0fh" % x)))
	var e2 := G.employee(st["emp"])
	body.add_child(UI.para("Estimated duration: %d weeks · development cost about %s per week." % [Lab.project_weeks(G.pid(), e2), G.money(900.0)], 18))
	body.add_child(UI.btn("Commission brief", func():
		var brief := {"family": st["family"], "audience": st["audience"], "fmt": st["fmt"], "cost_kg_max": float(st["cost"]), "posit": G.company_brands(G.pid())[0]["posit"]}
		if float(st["long"]) > 0.0:
			brief["longevity_min"] = float(st["long"])
		var err := Lab.commission(G.pid(), st["emp"], brief)
		Router.toast(err if err != "" else "Brief commissioned.", "bad" if err != "" else "good")
		G.touch(), "primary", 23, 80))
