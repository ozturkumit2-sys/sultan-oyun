extends Screen
## Save slots.

func page_title() -> String:
	return "Save / load"


func build() -> void:
	var mode: String = params.get("mode", "load")
	if not Router.in_game:
		var h := UI.hbox(14)
		h.add_child(UI.btn("‹", func(): Router.back(), "ghost", 40, 70))
		h.add_child(UI.title("Load game", 40))
		body.add_child(h)
	for slot in Save.SLOTS:
		var inf := Save.info(slot)
		var cc := UI.card(body)
		cc.add_child(UI.lbl("Autosave" if slot == "auto" else "Slot " + slot.substr(4), 22, UI.GOLD2, "semi"))
		if inf.is_empty():
			cc.add_child(UI.lbl("Empty", 19, UI.DIM))
		elif inf.get("corrupt", false):
			cc.add_child(UI.lbl("Unreadable save", 19, UI.RED))
		else:
			cc.add_child(UI.lbl("%s · %s · %s" % [inf["company"], G.date_str(int(inf["week"])), G.money(float(inf["cash"]))], 19, UI.TEXT))
			cc.add_child(UI.lbl(str(inf["saved"]), 16, UI.DIM))
		var row := UI.hbox(8)
		var s2: String = slot
		if not inf.is_empty() and not inf.get("corrupt", false):
			row.add_child(UI.btn("Load", func():
				var e := Save.load_game(s2)
				if e != "":
					Router.info("Could not load", e)
					return
				Router.start_game(), "primary", 20, 58))
		if G.has_game() and Router.in_game and slot != "auto":
			row.add_child(UI.btn("Save here", func():
				Save.save_game(s2)
				Router.toast("Saved.", "good")
				rebuild(), "secondary", 20, 58))
		if not inf.is_empty() and slot != "auto":
			row.add_child(UI.btn("Delete", func(): Router.confirm("Delete save?", "This cannot be undone.", func():
				Save.delete_slot(s2)
				rebuild(), "Delete", true), "danger", 20, 58))
		cc.add_child(row)
