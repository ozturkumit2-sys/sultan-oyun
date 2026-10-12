class_name ProductionRow
extends RefCounted
## Production order status row.

const STAGES := {"materials": "Waiting for materials", "compounding": "Compounding", "maturing": "Maturing", "filling": "Filtration & filling",
	"rework": "Rework", "qc_hold": "QC hold — decision needed", "done": "Done"}


static func add(parent: Control, o: Dictionary) -> void:
	var p := G.product(o["product"])
	var c := UI.card(parent, "flat", 6)
	var h := UI.hbox(10)
	h.add_child(UI.lbl("%s × %s" % [G.group_int(int(o["qty"])), p.get("name", "?")], 21, UI.CREAM, "semi"))
	h.add_child(UI.expand(UI.spacer()))
	var col := UI.RED if o["stage"] == "qc_hold" else UI.BLUE
	h.add_child(UI.pill(STAGES.get(o["stage"], o["stage"]), col, 16))
	c.add_child(h)
	var left := int(o.get("wait", 0)) + int(o.get("mat_left", 0)) + int(o.get("fill_left", 0)) + (1 if o["stage"] == "materials" else 0)
	var mf := ProductionEngine.mfr_info(o["company"], o["mfr"])
	var line := "%s · ~%d week(s) left · batch value %s" % [mf["name"], left, G.money(float(o["value"]))]
	if o.has("blocked"):
		line += " · blocked: " + str(o["blocked"])
	c.add_child(UI.lbl(line, 17, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
	if o["stage"] == "qc_hold":
		for m in G.inbox_open():
			if m.get("order", "") == o["id"]:
				var mid: String = m["id"]
				c.add_child(UI.btn("Decide", func(): Inbox.open_item(mid), "primary", 20, 56))
