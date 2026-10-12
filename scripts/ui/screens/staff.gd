extends Screen
## Employee list.

var role_f := ""


func page_title() -> String:
	return "Employees"


func build() -> void:
	var c := G.pc()
	var es := G.company_employees(G.pid())
	var g := UI.hbox(10)
	g.add_child(UI.stat("Employees", "%d / %d" % [es.size(), Staff.capacity(c)]))
	g.add_child(UI.stat("Payroll", G.money(Staff.payroll_week(G.pid())) + "/wk"))
	body.add_child(g)
	body.add_child(UI.btn("Recruit", func(): Router.go("recruit", {}), "primary", 22))
	var ro: Array = [["All", ""]]
	for r in DB.biz["roles"]:
		ro.append([DB.role(r)["name"], r])
	body.add_child(UI.seg(ro, role_f, func(v):
		role_f = v
		rebuild(), 18))
	if es.is_empty():
		UI.empty(body, "You run the company alone for now. Hire a perfumer and a chemist to grow.")
	for e in es:
		if role_f != "" and e["role"] != role_f:
			continue
		EmpRow.add(body, e)
