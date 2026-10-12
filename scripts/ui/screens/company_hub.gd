extends Screen
## Company hub.

func page_title() -> String:
	return "Company"


func build() -> void:
	var c := G.pc()
	var hq := HQView.new()
	hq.tier = int(c["hq"]["tier"])
	hq.name_text = c["name"]
	hq.accent = Color(str(c.get("color", "#c9a55a")))
	hq.building = int(c["hq"].get("weeks_left", 0)) > 0
	hq.custom_minimum_size = Vector2(0, 300)
	var hp := UI.panel("dark", 0)
	hp.add_child(hq)
	body.add_child(hp)
	var s := UI.hbox(10)
	s.add_child(UI.stat("Staff", "%d / %d" % [Staff.count(G.pid()), Staff.capacity(c)]))
	s.add_child(UI.stat("Offices", str(c["offices"].size())))
	s.add_child(UI.stat("Brands", str(G.company_brands(G.pid()).size())))
	body.add_child(s)
	var g := UI.grid(2, 12)
	UI.tile(g, "company", "Headquarters", DB.hq_tier(int(c["hq"]["tier"]))["name"], func(): Router.go("hq"))
	UI.tile(g, "users", "Employees", "%d people · payroll %s/wk" % [Staff.count(G.pid()), G.money(Staff.payroll_week(G.pid()))], func(): Router.go("staff"))
	UI.tile(g, "plus", "Recruitment", "%d candidates" % G.s["candidates"].size(), func(): Router.go("recruit", {}))
	UI.tile(g, "deal", "Perfumer transfers", "Approach rivals' perfumers", func(): Router.go("transfer"))
	UI.tile(g, "globe", "World map", "Markets & offices", func(): Router.go("world_map", {}))
	UI.tile(g, "crown", "Brands", "Portfolio & positioning", func(): Router.go("brands"))
	UI.tile(g, "megaphone", "Marketing", "Campaigns, influencers, celebrities", func(): Router.go("marketing"))
	UI.tile(g, "truck", "Distribution", "Retail partners", func(): Router.go("distribution", {}))
	UI.tile(g, "chart", "Competitors", "Rankings & rival houses", func(): Router.go("competitors"))
	UI.tile(g, "bank", "Acquisitions", "Buy rival companies", func(): Router.go("acquisitions"))
	UI.tile(g, "cog", "Delegation", "Let managers run routine work", func(): Router.go("delegation"))
	UI.tile(g, "trophy", "Awards", "Industry recognition", func(): Router.go("awards"))
	body.add_child(g)
