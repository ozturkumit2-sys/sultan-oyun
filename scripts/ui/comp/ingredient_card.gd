class_name IngredientCard
extends RefCounted
## Illustrated material card (art, name, family, price or lock) used by the picker and catalog.

static func make(id: String, cb: Callable, w := 0.0, tag := "") -> Control:
	var rec := DB.ing(id)
	var avail := G.ing_available(G.pid(), id)
	var tops := FormulaEngine.top_dims(rec["vec"], 2)
	var col := UI.dim_color(tops[0]) if not tops.is_empty() else Color("#9fcfe0")
	var p := GradPanel.new().colors(col.lerp(Color("#fffaf4"), 0.82), col.lerp(Color("#f6ece4"), 0.62)).set_pad(10)
	p.border = Color(col.darkened(0.3), 0.25)
	p.tapped = cb
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if w > 0.0:
		p.custom_minimum_size.x = w
	var v := UI.vbox(2)
	p.add_child(v)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(0, 112)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(stage)
	var art := Art.ing_icon(id, 112)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	if not avail:
		art.modulate = Color(1, 1, 1, 0.45)
	stage.add_child(art)
	if tag != "":
		var tg := UI.pill(tag, UI.AMBER, 13)
		stage.add_child(tg)
	var n := UI.lbl(FormulaEngine.short_name(rec), 19, UI.CREAM, "semi", HORIZONTAL_ALIGNMENT_CENTER)
	n.clip_text = true
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(n)
	var sub := ", ".join(tops.map(func(d): return str(d).capitalize())) if not tops.is_empty() else str(rec["cat"])
	var sl := UI.lbl(sub, 15, UI.MUTED, "medium", HORIZONTAL_ALIGNMENT_CENTER)
	sl.clip_text = true
	sl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(sl)
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if rec.get("nat", false):
		row.add_child(UI.pill("Natural", UI.GREEN, 13))
	elif rec["cat"] == "Accord":
		row.add_child(UI.pill("Accord", UI.GOLD, 13))
	elif rec["role"] == "aromatic":
		row.add_child(UI.pill("Synthetic", UI.PLUM, 13))
	else:
		row.add_child(UI.pill(str(rec["role"]).capitalize(), UI.BLUE, 13))
	v.add_child(row)
	v.add_child(UI.lbl((G.money(G.ing_price(id)) + "/kg") if avail else "Locked · qualify", 17, UI.BURGUNDY if avail else UI.MUTED, "semi", HORIZONTAL_ALIGNMENT_CENTER))
	return p
