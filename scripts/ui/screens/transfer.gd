extends Screen
## Perfumer transfer market: approach perfumers working for rival houses.

func page_title() -> String:
	return "Perfumer transfers"


func build() -> void:
	body.add_child(UI.para("Rival perfumers weigh salary, signing bonus, your prestige and headquarters, their loyalty and motivation. Contracts still running require a buyout paid to their employer.", 19))
	var list: Array = []
	for e in G.s["employees"].values():
		if e["role"] == "perfumer" and e.get("employer", "") != "" and e["employer"] != G.pid() and G.company(e["employer"]).get("active", true):
			list.append(e)
	list.sort_custom(func(a, b): return Staff.perfumer_skill(a) > Staff.perfumer_skill(b))
	for e in list:
		var eid: String = e["id"]
		var left := maxi(0, int(e["contract_end"]) - G.week())
		var sub := "%s · skill %d · %s/yr · contract %s" % [G.company(e["employer"])["name"], int(Staff.perfumer_skill(e) * 100), G.money(float(e["salary"])), ("%d wks" % left) if left > 0 else "expired"]
		var av = Avatar.new()
		av.seed_text = e["name"]
		av.fem = e.get("fem", false)
		av.custom_minimum_size = Vector2(64, 64)
		UI.row_card(body, e["name"], sub, "Approach", func(): _approach(eid), av)


func _approach(eid: String) -> void:
	var e := G.employee(eid)
	var cur := float(e["salary"])
	var st := {"salary": snappedf(cur * 1.2, 500.0), "bonus": snappedf(cur * 0.2, 500.0)}
	var left := maxi(0, int(e["contract_end"]) - G.week())
	var buyout := cur / 52.0 * minf(float(left), 104.0) * 0.5
	Router.modal("Approach %s" % e["name"], func(v: VBoxContainer):
		v.add_child(UI.lbl("At %s · %s/yr · loyalty %d · motivation %d" % [G.company(e["employer"])["name"], G.money(cur), int(float(e["loyalty"]) * 100), int(float(e["motivation"]) * 100)], 19, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
		v.add_child(UI.lbl("Specialties: " + ", ".join(e["spec"]), 19, UI.TEXT))
		var hist: Array = e["history"]
		if not hist.is_empty():
			v.add_child(UI.para("Career: " + "; ".join(hist.slice(maxi(0, hist.size() - 3)).map(func(x): return str(x[1]))), 17))
		var sl := UI.lbl("Salary: %s" % G.money(float(st["salary"])), 21, UI.GOLD2, "semi")
		v.add_child(sl)
		v.add_child(UI.slider(cur, cur * 2.2, 500.0, float(st["salary"]), func(x):
			st["salary"] = x
			sl.text = "Salary: %s" % G.money(x)))
		var bl := UI.lbl("Signing bonus: %s" % G.money(float(st["bonus"])), 21, UI.GOLD2, "semi")
		v.add_child(bl)
		v.add_child(UI.slider(0.0, cur * 1.5, 500.0, float(st["bonus"]), func(x):
			st["bonus"] = x
			bl.text = "Signing bonus: %s" % G.money(x)))
		v.add_child(UI.para("Contract buyout to their employer: %s." % G.money(buyout), 18)),
		[["Cancel", Callable(), "secondary"], ["Make offer", func():
			var r := Staff.approach(e, float(st["salary"]), float(st["bonus"]))
			Router.toast(r["msg"], "good" if r["ok"] else "bad")
			G.touch(), "primary"]])
