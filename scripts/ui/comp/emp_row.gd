class_name EmpRow
extends RefCounted

static func add(parent: Control, e: Dictionary, cb: Callable = Callable(), right := "") -> void:
	var eid: String = e["id"]
	var skill := Staff.perfumer_skill(e) if e["role"] == "perfumer" else float(e["skill"])
	var sub := "%s · skill %d · %s/yr" % [Staff.title_name(e), int(skill * 100), G.money(float(e["salary"]))]
	if e.get("employer", "") == G.pid():
		sub += " · motivation %d" % int(float(e["motivation"]) * 100)
		if not e.get("training", {}).is_empty():
			sub += " · training"
		if not e.get("project", {}).is_empty():
			sub += " · on a project"
	var av = Avatar.new()
	av.for_employee(e)
	av.custom_minimum_size = Vector2(64, 64)
	UI.row_card(parent, e["name"], sub, right, cb if cb.is_valid() else func(): Router.go("employee", {"id": eid}), av)


## Portrait card for 2-column team / candidate galleries.
static func card(e: Dictionary, cb: Callable = Callable(), right := "") -> Control:
	var eid: String = e["id"]
	var lab := Avatar.kind_for_role(str(e["role"])) == "lab"
	var tint := Color("#ece3f5") if lab else Color("#eef1e6")
	var p := GradPanel.new().colors(tint.lerp(Color("#fffdf9"), 0.55), tint).set_pad(12)
	p.tapped = cb if cb.is_valid() else func(): Router.go("employee", {"id": eid})
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UI.vbox(4)
	p.add_child(v)
	var av := Avatar.new().for_employee(e)
	av.custom_minimum_size = Vector2(132, 132)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(av)
	var n := UI.lbl(e["name"], 20, UI.CREAM, "semi", HORIZONTAL_ALIGNMENT_CENTER)
	n.clip_text = true
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(n)
	var r := UI.lbl(Staff.title_name(e), 15, UI.PLUM if lab else UI.SAGE.darkened(0.3), "medium", HORIZONTAL_ALIGNMENT_CENTER)
	r.clip_text = true
	r.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(r)
	var skill := Staff.perfumer_skill(e) if e["role"] == "perfumer" else float(e["skill"])
	var sk := UI.hbox(6)
	sk.add_child(UI.lbl("Skill", 14, UI.MUTED, "semi"))
	sk.add_child(UI.bar(skill, UI.GOLD, 8))
	sk.add_child(UI.lbl(str(int(skill * 100)), 15, UI.CREAM, "semi"))
	v.add_child(sk)
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.lbl(G.money(float(e["salary"])) + "/yr", 15, UI.MUTED, "medium"))
	if right != "":
		row.add_child(UI.pill(right, UI.BURGUNDY, 14))
	elif e.get("employer", "") == G.pid():
		var mot := float(e["motivation"])
		row.add_child(UI.pill("☺ %d" % int(mot * 100), UI.GREEN if mot > 0.45 else UI.RED, 13))
	v.add_child(row)
	return p
