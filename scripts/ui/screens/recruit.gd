extends Screen
## Recruitment: candidate pool refreshed every 4 weeks.

var role_f := ""


func page_title() -> String:
	return "Recruitment"


func build() -> void:
	if role_f == "" and params.has("role"):
		role_f = params["role"]
	var c := G.pc()
	body.add_child(UI.para("Staff %d / %d. New candidates arrive every 4 weeks; better reputation and headquarters attract stronger people. Recruitment fee ≈ %d%% of annual salary." % [Staff.count(G.pid()), Staff.capacity(c), int(round((0.15 - 0.07 * Staff.best_skill(G.pid(), "hr_manager")) * 100))], 19))
	var ro: Array = [["All", ""]]
	for r in DB.biz["roles"]:
		ro.append([DB.role(r)["name"], r])
	body.add_child(UI.seg(ro, role_f, func(v):
		role_f = v
		rebuild(), 18))
	var any := false
	for id in G.s["candidates"]:
		var e := G.employee(id)
		if e.is_empty() or (role_f != "" and e["role"] != role_f):
			continue
		any = true
		var eid: String = id
		EmpRow.add(body, e, func(): _offer(eid), "Hire")
	if not any:
		UI.empty(body, "No candidates for this role right now. Check again in a few weeks.")
	var free = G.s["employees"].values().filter(func(x): return x.get("employer", "") == "" and x.get("status", "") == "free" and (role_f == "" or x["role"] == role_f))
	if not free.is_empty():
		UI.section(body, "Free agents (left other companies)")
		for e in free.slice(0, 10):
			var eid2: String = e["id"]
			EmpRow.add(body, e, func(): _offer(eid2), "Hire")


func _offer(eid: String) -> void:
	var e := G.employee(eid)
	var ask := Staff.market_value(e)
	var st := {"salary": ask, "years": 2}
	Router.modal("Offer to %s" % e["name"], func(v: VBoxContainer):
		v.add_child(UI.lbl("%s · skill %d · asks ~%s/yr" % [DB.role(e["role"])["name"], int((Staff.perfumer_skill(e) if e["role"] == "perfumer" else float(e["skill"])) * 100), G.money(ask)], 20, UI.MUTED))
		if e["role"] == "perfumer":
			v.add_child(UI.lbl("Specialties: " + ", ".join(e["spec"]), 19, UI.TEXT))
			for k in ["creativity", "technique", "cost", "productivity"]:
				var h := UI.hbox(8)
				var l := UI.lbl(k.capitalize(), 18, UI.MUTED)
				l.custom_minimum_size.x = 170
				h.add_child(l)
				h.add_child(UI.bar(float(e["skills"][k]), UI.GOLD, 8))
				v.add_child(h)
		var sl := UI.lbl("Salary offer: %s" % G.money(ask), 22, UI.GOLD2, "semi")
		v.add_child(sl)
		v.add_child(UI.slider(ask * 0.75, ask * 1.4, 500.0, ask, func(x):
			st["salary"] = x
			sl.text = "Salary offer: %s" % G.money(x)))
		v.add_child(UI.seg([["1 year", 1], ["2 years", 2], ["3 years", 3], ["4 years", 4]], 2, func(x): st["years"] = x))
		v.add_child(UI.para("Recruitment fee: %s. Offers below their expectation may be declined." % G.money(Staff.hire_fee(G.pid(), e)), 18)),
		[["Cancel", Callable(), "secondary"], ["Make offer", func():
			var r := Staff.hire(G.pid(), eid, float(st["salary"]), int(st["years"]))
			Router.toast(r if r != "" else "%s accepted!" % e["name"], "bad" if r != "" else "good")
			G.touch(), "primary"]])
