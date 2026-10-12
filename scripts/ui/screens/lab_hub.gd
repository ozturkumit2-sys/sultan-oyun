extends Screen
## Laboratory hub.

func page_title() -> String:
	return "Laboratory"


func build() -> void:
	var c := G.pc()
	var open_props = G.s["proposals"].filter(func(p): return p["company"] == G.pid() and p["status"] == "open").size()
	var forms = G.s["formulas"].values().filter(func(f): return f["company"] == G.pid() and not f.get("archived", false))
	var hero := UI.card(body, "gold")
	hero.add_child(UI.title("The Fragrance Laboratory", 32))
	hero.add_child(UI.para("Compose formulas from real perfumery materials, measure them, research consumers and steer your perfumers.", 20, UI.TEXT))
	var hs := UI.hbox(10)
	hs.add_child(UI.stat("Formulas", str(forms.size())))
	hs.add_child(UI.stat("Perfumers", str(Staff.count(G.pid(), "perfumer"))))
	hs.add_child(UI.stat("Projects", "%d / %d" % [Lab.active_projects(G.pid()), Lab.project_slots(G.pid())]))
	hero.add_child(hs)
	body.add_child(UI.btn("+ Compose a new formula", func(): Router.go("formula_editor", {}), "primary", 24, 84))
	var g := UI.grid(2, 12)
	UI.tile(g, "lab", "Formula library", "Your formulas, versions and accords", func(): Router.go("formulas"))
	UI.tile(g, "bottle", "Ingredient catalog", "%d materials · natural & synthetic" % DB.ing_order.size(), func(): Router.go("ingredients"))
	UI.tile(g, "chart", "Technical tests", "Longevity, projection, stability, safety", func(): Router.go("tests", {}))
	UI.tile(g, "users", "Consumer research", "Blind & branded surveys", func(): Router.go("research", {}))
	UI.tile(g, "mail", "Perfumer proposals", "Formulas created by your team", func(): Router.go("proposals"), open_props)
	UI.tile(g, "star", "Project briefs", "Commission a fragrance", func(): Router.go("briefs"))
	UI.tile(g, "finance", "Ingredient market", "Prices, supply and contracts", func(): Router.go("ingredient_market", {}))
	UI.tile(g, "factory", "Production", "Batches, inventory, factory", func(): Router.go("production"))
	body.add_child(g)
	var auto: bool = c.get("lab_auto", true)
	var ac := UI.card(body, "flat")
	var ah := UI.hbox(10)
	var av := UI.vbox(2)
	av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av.add_child(UI.lbl("Autonomous perfumer projects", 22, UI.TEXT, "semi"))
	av.add_child(UI.para("Idle perfumers develop their own ideas in their specialties (development costs apply).", 18))
	ah.add_child(av)
	ah.add_child(UI.chip("On" if auto else "Off", auto, func():
		c["lab_auto"] = not auto
		rebuild()))
	ac.add_child(ah)
