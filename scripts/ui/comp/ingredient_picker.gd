class_name IngredientPicker
extends RefCounted
## Modal material picker with family / role filters.

const FILTERS := [["All", "all"], ["Top", "top"], ["Heart", "heart"], ["Base", "base"], ["Natural", "nat"], ["Synthetic", "syn"], ["Accords", "accord"], ["Solvents & aux", "aux"]]


static func open(cb: Callable) -> void:
	var state := {"f": "all"}
	Router.modal("Add a material", func(v: VBoxContainer):
		var list := UI.vbox(8)
		var fill := func(): pass
		fill = func():
			for ch in list.get_children():
				ch.queue_free()
			for id in DB.ing_order:
				var rec := DB.ing(id)
				var f: String = state["f"]
				var ok := true
				match f:
					"top", "heart", "base":
						ok = rec["role"] == "aromatic" and rec["note"] == f
					"nat":
						ok = rec.get("nat", false) and rec["role"] == "aromatic"
					"syn":
						ok = not rec.get("nat", false) and rec["role"] == "aromatic" and rec["cat"] != "Accord"
					"accord":
						ok = rec["cat"] == "Accord"
					"aux":
						ok = rec["role"] != "aromatic"
				if not ok:
					continue
				var avail := G.ing_available(G.pid(), id)
				var tops := FormulaEngine.top_dims(rec["vec"], 2)
				var sub := ", ".join(tops.map(func(d): return str(d).capitalize())) if not tops.is_empty() else str(rec["cat"])
				sub += " · " + ("natural" if rec.get("nat", false) else "synthetic")
				var dot := ColorRect.new()
				dot.color = UI.dim_color(tops[0]) if not tops.is_empty() else UI.BLUE
				dot.custom_minimum_size = Vector2(8, 52)
				var right := G.money(G.ing_price(id)) + "/kg" if avail else "🔒 Qualify"
				var iid: String = id
				UI.row_card(list, FormulaEngine.short_name(rec), sub, right, func():
					if avail:
						Router.close_modal()
						cb.call(iid)
					else:
						IngredientInfo.show(iid), dot, UI.GOLD2 if avail else UI.MUTED)
		var seg := UI.seg(FILTERS, state["f"], func(x): pass, 19)
		v.add_child(seg)
		for b in seg.get_children():
			var btn := b as Button
			var val: String = ""
			for fl in FILTERS:
				if fl[0] == btn.text:
					val = fl[1]
			btn.pressed.connect(func():
				state["f"] = val
				for b2 in seg.get_children():
					UI.style_btn(b2 as Button, "chip_on" if (b2 as Button).text == btn.text else "chip", 19)
				fill.call())
		v.add_child(list)
		fill.call(), [])
