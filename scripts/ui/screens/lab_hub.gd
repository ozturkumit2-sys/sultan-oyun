extends Screen
## Laboratory hub: the perfumer's atelier — bench with the latest juice, the palette of materials,
## recent formulas as bottles and illustrated doors into every lab activity.

func page_title() -> String:
	return "Laboratory"


func env() -> String:
	return "lab"


func build() -> void:
	var c := G.pc()
	var open_props: int = G.s["proposals"].filter(func(p): return p["company"] == G.pid() and p["status"] == "open").size()
	var forms: Array = G.s["formulas"].values().filter(func(f): return f["company"] == G.pid() and not f.get("archived", false) and not f.get("accord", false))
	forms.sort_custom(func(a, b): return int(a["versions"][a["versions"].size() - 1]["w"]) > int(b["versions"][b["versions"].size() - 1]["w"]))
	_hero(forms)
	var ks := UI.hbox(10)
	ks.add_child(UI.kpi("lab", "Formulas", str(forms.size()), UI.PLUM, func(): Router.go("formulas")))
	ks.add_child(UI.kpi("users", "Perfumers", str(Staff.count(G.pid(), "perfumer")), UI.ROSE, func(): Router.go("recruit", {"role": "perfumer"})))
	ks.add_child(UI.kpi("star", "Projects", "%d / %d" % [Lab.active_projects(G.pid()), Lab.project_slots(G.pid())], UI.GOLD, func(): Router.go("briefs")))
	body.add_child(ks)
	body.add_child(UI.btn("+ Compose a new formula", func(): Router.go("formula_editor", {}), "primary", 24, 84))
	if not forms.is_empty():
		UI.section(body, "On your shelf", UI.btn("All", func(): Router.go("formulas"), "ghost", 19, 44))
		var sc := DragScroll.new()
		sc.horizontal = true
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		sc.custom_minimum_size = Vector2(0, 268)
		var row := UI.hbox(12)
		sc.add_child(row)
		for f in forms.slice(0, 10):
			row.add_child(_formula_card(f))
		body.add_child(sc)
	_palette()
	UI.section(body, "The atelier")
	Art.grid2(body, [
		Art.card("stilllife", "Formula library", "%d formulas & accords" % G.s["formulas"].values().filter(func(f): return f["company"] == G.pid()).size(), func(): Router.go("formulas"), 0, Vector2(0.5, 0.6)),
		Art.ing_card(["rose_absolute", "bergamot", "vanilla_abs"], "Ingredient catalog", "%d materials" % DB.ing_order.size(), func(): Router.go("ingredients"), Color("#f4ece6")),
		Art.card("lab", "Technical tests", "Longevity · projection · stability", func(): Router.go("tests", {}), 0, Vector2(0.45, 0.7)),
		Art.card("office", "Consumer research", "Blind & branded surveys", func(): Router.go("research", {}), 0, Vector2(0.3, 0.4)),
		_people_card("Perfumer proposals", "%d waiting for you" % open_props if open_props > 0 else "Ideas from your team", func(): Router.go("proposals"), open_props),
		Art.card("lab", "Project briefs", "Commission a fragrance", func(): Router.go("briefs"), 0, Vector2(0.9, 0.45)),
		Art.card("garden", "Ingredient market", "Prices, harvests, contracts", func(): Router.go("ingredient_market", {}), 0, Vector2(0.6, 0.7)),
		Art.card("factory", "Production", "Batches, inventory, factory", func(): Router.go("production"), 0, Vector2(0.5, 0.6)),
	])
	var auto: bool = c.get("lab_auto", true)
	var ac := GradPanel.new().colors(Color("#f6f1fb"), Color("#ece3f5")).set_pad(16)
	body.add_child(ac)
	var ah := UI.hbox(10)
	ac.add_child(ah)
	ah.add_child(UI.icon_bubble("users", UI.PLUM, 52))
	var av := UI.vbox(2)
	av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av.add_child(UI.lbl("Autonomous perfumer projects", 21, UI.TEXT, "semi"))
	av.add_child(UI.para("Idle perfumers develop their own ideas in their specialties (development costs apply).", 17))
	ah.add_child(av)
	ah.add_child(UI.chip("On" if auto else "Off", auto, func():
		c["lab_auto"] = not auto
		rebuild()))


func _hero(forms: Array) -> void:
	var hero := Control.new()
	hero.custom_minimum_size = Vector2(0, 420)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(hero)
	var sv := Art.hero(null, "lab", "The Fragrance Laboratory", "Compose · measure · research", 420, Vector2(0.55, 0.62))
	sv.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero.add_child(sv)
	var gl := Glow.new()
	gl.color = Color("#fffaf0")
	gl.strength = 1.5
	gl.anchor_left = 1.0
	gl.anchor_right = 1.0
	gl.offset_left = -250
	gl.offset_right = 0
	gl.offset_top = 40
	gl.offset_bottom = 300
	hero.add_child(gl)
	var bv := BottleView.new()
	var look := {"shape": 6, "cap": 1, "glass": 0, "label": 0, "accent": G.pc().get("color", "#c9a55a"), "tint": "natural"}
	var nm := ""
	if not forms.is_empty():
		var f: Dictionary = forms[0]
		for k in f.get("look", {}):
			look[k] = f["look"][k]
		var fv: Dictionary = f["versions"][f["versions"].size() - 1]
		var ev := FormulaEngine.evaluate(fv["items"], f.get("fmt", "edp"), float(f.get("conc", 18.0)))
		bv.liquid = BottleView.liquid_color(ev.get("profile", PackedFloat32Array()))
		nm = f["name"]
	else:
		look["tint"] = "blush"
	bv.setup(look, "", nm)
	bv.vivid = true
	bv.idle_bubbles = true
	bv.anchor_left = 1.0
	bv.anchor_right = 1.0
	bv.offset_left = -210
	bv.offset_right = -40
	bv.offset_top = 70
	bv.offset_bottom = 330
	hero.add_child(bv)
	var tp := TapPanel.new()
	tp.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	tp.set_anchors_preset(Control.PRESET_FULL_RECT)
	tp.tapped = func(): bv.stir(1.0)
	hero.add_child(tp)


func _formula_card(f: Dictionary) -> Control:
	var fv: Dictionary = f["versions"][f["versions"].size() - 1]
	var ev := FormulaEngine.evaluate(fv["items"], f.get("fmt", "edp"), float(f.get("conc", 18.0)))
	var prof: PackedFloat32Array = ev.get("profile", PackedFloat32Array())
	var tint := UI.scent_tint(prof)
	var p := GradPanel.new().colors(tint[0], tint[1]).set_pad(10)
	p.border = Color(Color(tint[2]).darkened(0.3), 0.2)
	var fid: String = f["id"]
	p.tapped = func(): Router.go("formula_editor", {"fid": fid})
	p.custom_minimum_size = Vector2(170, 258)
	var v := UI.vbox(4)
	p.add_child(v)
	var look := {"shape": absi(hash(fid)) % 10, "cap": absi(hash(fid + "c")) % 8, "glass": 0, "label": 0, "accent": "#c9a55a", "tint": "natural"}
	for k in f.get("look", {}):
		look[k] = f["look"][k]
	var bv := BottleView.new().setup(look, "", "", prof)
	bv.vivid = true
	bv.show_label = false
	bv.custom_minimum_size = Vector2(0, 160)
	v.add_child(bv)
	var t := UI.lbl(f["name"], 19, UI.CREAM, "title")
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(t)
	var s := UI.lbl("%s · v%d" % [str(ev.get("family", "")), f["versions"].size()], 14, UI.MUTED, "medium")
	s.clip_text = true
	s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(s)
	return p


## The perfumer's palette: a scrolling organ of the materials you can use.
func _palette() -> void:
	var avail: Array = DB.ing_order.filter(func(x): return G.ing_available(G.pid(), x))
	UI.section(body, "Your palette · %d materials" % avail.size(), UI.btn("Catalog", func(): Router.go("ingredients"), "ghost", 19, 44))
	var p := GradPanel.new().colors(Color("#fbf6ef"), Color("#f3e9de")).set_pad(8)
	body.add_child(p)
	var sc := DragScroll.new()
	sc.horizontal = true
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.custom_minimum_size = Vector2(0, 132)
	p.add_child(sc)
	var row := UI.hbox(4)
	sc.add_child(row)
	for id in avail:
		var iid: String = id
		var tp := TapPanel.new()
		tp.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		tp.tapped = func(): IngredientInfo.show(iid)
		var v := UI.vbox(0)
		tp.add_child(v)
		v.add_child(Art.ing_icon(iid, 96))
		var l := UI.lbl(FormulaEngine.short_name(DB.ing(iid)), 13, UI.MUTED, "medium", HORIZONTAL_ALIGNMENT_CENTER)
		l.custom_minimum_size.x = 96
		l.clip_text = true
		v.add_child(l)
		row.add_child(tp)


func _people_card(title: String, sub: String, cb: Callable, badge: int) -> Control:
	var team: Array = G.s["employees"].values().filter(func(e): return e.get("employer", "") == G.pid() and e["role"] == "perfumer")
	if team.is_empty():
		team = G.s["candidates"].map(func(id): return G.employee(id)).filter(func(e): return not e.is_empty() and e["role"] == "perfumer")
	return Art.people_card(team, title, sub, cb, Color("#f6e2e6"), badge, "lab")
