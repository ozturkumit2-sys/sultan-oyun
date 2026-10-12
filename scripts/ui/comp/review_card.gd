class_name ReviewCard
extends RefCounted

static func add(parent: Control, rv: Dictionary) -> void:
	var c := UI.card(parent, "flat", 4)
	var h := UI.hbox(8)
	h.add_child(UI.stars(float(rv["stars"]), 20))
	h.add_child(UI.lbl("%s · %s · %s" % [rv.get("by", "user"), DB.country(rv.get("c", "US")).get("name", ""), G.short_date(int(rv["w"]))], 16, UI.MUTED))
	c.add_child(h)
	c.add_child(UI.para(str(rv["text"]), 20, UI.TEXT))
	var foot := "%s · wore it ~%.0fh" % [rv.get("seg", ""), float(rv.get("long", 0))]
	if int(rv.get("fv", 0)) > 0:
		foot += " · v%d" % (int(rv["fv"]) + 1)
	c.add_child(UI.lbl(foot, 15, UI.DIM))
