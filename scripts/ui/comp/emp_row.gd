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
	av.seed_text = e["name"]
	av.fem = e.get("fem", false)
	av.custom_minimum_size = Vector2(64, 64)
	UI.row_card(parent, e["name"], sub, right, cb if cb.is_valid() else func(): Router.go("employee", {"id": eid}), av)
