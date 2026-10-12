extends Screen
## Annual industry awards.

func page_title() -> String:
	return "Industry awards"


func hero_spec() -> Dictionary:
	return {"scene": "stilllife", "title": "Golden Flacon Awards", "sub": "Every December, the industry crowns its best", "focus": Vector2(0.5, 0.6), "h": 250.0}


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
			var ccp := GradPanel.new().colors(Color("#fdf3dc") if mine else Color("#fffdf9"), Color("#f4e2c0") if mine else Color("#f6eee6")).set_pad(12)
			ccp.border = Color(UI.GOLD, 0.6 if mine else 0.15)
			body.add_child(ccp)
			var cc := UI.vbox(4)
			ccp.add_child(cc)
			var h := UI.hbox(12)
			var tr := TextureRect.new()
			tr.texture = Art.tex("res://assets/art/misc/trophy.svg")
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(84, 84)
			tr.modulate = Color(1, 1, 1, 1) if mine else Color(1, 1, 1, 0.55)
			h.add_child(tr)
			var v := UI.vbox(2)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(UI.lbl(a["cat"], 18, UI.MUTED))
			v.add_child(UI.lbl(a["name"], 22, UI.CREAM, "semi"))
			v.add_child(UI.lbl(G.company(a["company"]).get("name", "?"), 17, UI.GOLD2 if mine else UI.MUTED))
			h.add_child(v)
			cc.add_child(h)
