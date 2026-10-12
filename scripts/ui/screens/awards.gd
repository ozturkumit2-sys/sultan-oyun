extends Screen
## Annual industry awards.

func page_title() -> String:
	return "Industry awards"


func build() -> void:
	body.add_child(UI.para("The Golden Flacon Awards are held every December. Juries weigh critics, consumer ratings, innovation and momentum — not just sales. Nothing is guaranteed.", 19))
	var aw: Array = G.s["awards"]
	if aw.is_empty():
		UI.empty(body, "The first ceremony takes place in December %d." % G.year_of(G.week()))
		return
	var years := {}
	for a in aw:
		years[int(a["year"])] = true
	var ys: Array = years.keys()
	ys.sort()
	ys.reverse()
	for y in ys:
		UI.section(body, "Golden Flacon %d" % y)
		for a in aw:
			if int(a["year"]) != y:
				continue
			var mine := G.is_player(a["company"])
			var cc := UI.card(body, "gold" if mine else "flat", 4)
			var h := UI.hbox(10)
			h.add_child(UI.icon("trophy", 38, UI.GOLD if mine else UI.MUTED))
			var v := UI.vbox(2)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(UI.lbl(a["cat"], 18, UI.MUTED))
			v.add_child(UI.lbl(a["name"], 22, UI.CREAM, "semi"))
			v.add_child(UI.lbl(G.company(a["company"]).get("name", "?"), 17, UI.GOLD2 if mine else UI.MUTED))
			h.add_child(v)
			cc.add_child(h)
