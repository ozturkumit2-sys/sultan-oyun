extends Screen
## Company hub: the house itself — headquarters, people, markets, brands and the competition.

func page_title() -> String:
	return "Company"


func env() -> String:
	return "company"


func build() -> void:
	var c := G.pc()
	var tier := int(c["hq"]["tier"])
	var hero := Art.hero(body, Art.hq_scene(tier), DB.hq_tier(tier)["name"], "%s · %d staff · %d market%s" % [DB.country(c["home"])["name"], Staff.count(G.pid()), c["offices"].size(), "" if c["offices"].size() == 1 else "s"], 380, Vector2(0.5, 0.3), c["name"])
	var tap := TapPanel.new()
	tap.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.tapped = func(): Router.go("hq")
	hero.add_child(tap)
	if int(c["hq"].get("weeks_left", 0)) > 0:
		var pill := UI.pill("Construction · %d weeks left" % int(c["hq"]["weeks_left"]), UI.AMBER, 17)
		pill.position = Vector2(16, 16)
		hero.add_child(pill)
	var s := UI.hbox(10)
	s.add_child(UI.kpi("users", "Staff", "%d / %d" % [Staff.count(G.pid()), Staff.capacity(c)], UI.PLUM, func(): Router.go("staff")))
	s.add_child(UI.kpi("globe", "Markets", "%d / %d" % [c["offices"].size(), DB.countries.size()], UI.BLUE, func(): Router.go("world_map", {})))
	s.add_child(UI.kpi("crown", "Brands", str(G.company_brands(G.pid()).size()), UI.ROSE, func(): Router.go("brands")))
	body.add_child(s)
	var ep := GradPanel.new().colors(Color("#fffdf9"), Color("#f2f4ea")).set_pad(16)
	ep.tapped = func(): Router.go("hq")
	var tp := TierPath.new()
	tp.tier = tier
	tp.custom_minimum_size = Vector2(0, 128)
	ep.add_child(tp)
	body.add_child(ep)
	var team: Array = G.s["employees"].values().filter(func(e): return e.get("employer", "") == G.pid())
	var cands: Array = G.s["candidates"].map(func(id): return G.employee(id)).filter(func(e): return not e.is_empty())
	var rivals_p: Array = G.s["employees"].values().filter(func(e): return e["role"] == "perfumer" and e.get("employer", "") != "" and e.get("employer", "") != G.pid())
	rivals_p.sort_custom(func(a, b): return float(a["skill"]) > float(b["skill"]))
	var camps: int = G.s["campaigns"].filter(func(k): return k["company"] == G.pid() and k["status"] == "active").size()
	var ag: int = G.s["channels"].filter(func(a): return a["company"] == G.pid() and a.get("active", true)).size()
	UI.section(body, "People")
	Art.grid2(body, [
		Art.people_card(team, "Employees", "%d people · %s/wk" % [Staff.count(G.pid()), G.money(Staff.payroll_week(G.pid()))], func(): Router.go("staff"), Color("#eef1e6"), 0, "office"),
		Art.people_card(cands, "Recruitment", "%d candidates" % cands.size(), func(): Router.go("recruit", {}), Color("#f6e2e6")),
		Art.people_card(rivals_p, "Perfumer transfers", "Approach rivals' noses", func(): Router.go("transfer"), Color("#ece3f5"), 0, "lab"),
		Art.card("office", "Delegation", "Managers run routine work", func(): Router.go("delegation"), 0, Vector2(0.3, 0.45)),
	])
	UI.section(body, "Markets & brands")
	Art.grid2(body, [
		Art.card("world", "World map", "%d of %d markets" % [c["offices"].size(), DB.countries.size()], func(): Router.go("world_map", {}), 0, Vector2(0.5, 0.5)),
		Art.card("boutique", "Brands", "Portfolio & positioning", func(): Router.go("brands"), 0, Vector2(0.5, 0.45)),
		Art.card("studio", "Marketing", ("%d campaign%s live" % [camps, "" if camps == 1 else "s"]) if camps > 0 else "Campaigns & ambassadors", func(): Router.go("marketing"), 0, Vector2(0.5, 0.5)),
		Art.tex_card("res://assets/art/channels/store.svg", "Distribution", "%d retail partner%s" % [ag, "" if ag == 1 else "s"], func(): Router.go("distribution", {}), Color("#f3e6ec")),
	])
	UI.section(body, "The industry")
	Art.grid2(body, [
		Art.card("skyline", "Competitors", "Rankings & rival houses", func(): Router.go("competitors"), 0, Vector2(0.5, 0.5)),
		Art.card("hq4", "Acquisitions", "Buy rival companies", func(): Router.go("acquisitions"), 0, Vector2(0.5, 0.35)),
		Art.tex_card("res://assets/art/misc/trophy.svg", "Awards", "Golden Flacon", func(): Router.go("awards"), Color("#f8ead2")),
		Art.card("garden", "Ingredient market", "Harvests & contracts", func(): Router.go("ingredient_market", {}), 0, Vector2(0.6, 0.7)),
	])
