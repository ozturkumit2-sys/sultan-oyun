extends Screen
## Employee list.

var role_f := ""


func page_title() -> String:
	return "Employees"


func env() -> String:
	return "company"


func build() -> void:
	var c := G.pc()
	var es := G.company_employees(G.pid())
	Art.hero(body, "office", "Your team", "%d of %d desks filled" % [es.size(), Staff.capacity(c)], 280, Vector2(0.5, 0.5))
	var g := UI.hbox(10)
	g.add_child(UI.kpi("users", "Employees", "%d / %d" % [es.size(), Staff.capacity(c)], UI.PLUM))
	g.add_child(UI.kpi("finance", "Payroll", G.money(Staff.payroll_week(G.pid())) + "/wk", UI.GOLD))
	body.add_child(g)
	body.add_child(UI.btn("Recruit", func(): Router.go("recruit", {}), "primary", 22, 76))
	var ro: Array = [["All", ""]]
	for r in DB.biz["roles"]:
		ro.append([DB.role(r)["name"], r])
	body.add_child(UI.seg(ro, role_f, func(v):
		role_f = v
		rebuild(), 18))
	if es.is_empty():
		UI.empty(body, "You run the company alone for now. Hire a perfumer and a chemist to grow.")
	var grid := UI.grid(2, 12)
	for e in es:
		if role_f != "" and e["role"] != role_f:
			continue
		grid.add_child(EmpRow.card(e))
	body.add_child(grid)
