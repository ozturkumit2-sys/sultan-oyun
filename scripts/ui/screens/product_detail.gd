extends Screen
## Product details, performance, reviews, history and actions.

var tab := "overview"


func page_title() -> String:
	return G.product(params.get("id", "")).get("name", "Product")


func build() -> void:
	var p := G.product(params["id"])
	if p.is_empty():
		return
	var mine := G.is_player(p["company"])
	var b := G.brand(p["brand"])
	var ev = MarketEngine.product_ev(p)
	var sh := Showcase.new().setup(p["bottle"], b.get("name", ""), p["name"], ev.get("profile", PackedFloat32Array()))
	sh.custom_minimum_size = Vector2(0, 470)
	body.add_child(sh)
	var tint := UI.scent_tint(ev.get("profile", PackedFloat32Array()))
	var heroc := GradPanel.new().colors(tint[0], tint[1]).set_pad(18)
	heroc.border = Color(Color(tint[2]).darkened(0.3), 0.2)
	body.add_child(heroc)
	var hero := UI.vbox(10)
	heroc.add_child(hero)
	var hh := UI.hbox(14)
	var hv := UI.vbox(4)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UI.title(p["name"], 32))
	hv.add_child(UI.lbl(b.get("name", ""), 20, UI.GOLD2, "semi"))
	hv.add_child(UI.lbl("%s · %s %.0f%% · %d ml" % [ev.get("family", ""), DB.formats[p["fmt"]]["name"], float(p["conc"]), int(p["volume"])], 18, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
	var fv := G.formula_version(p["formula"], int(p["fv"]))
	hv.add_child(UI.lbl("Formula %s v%d · %s" % [G.formula(p["formula"]).get("name", "?"), int(p["fv"]) + 1, {"fem": "Feminine", "masc": "Masculine", "any": "Unisex"}[p["audience"]]], 17, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
	var rt: Dictionary = p["rating"]
	if int(rt["n"]) > 0:
		var rr := UI.hbox(8)
		rr.add_child(UI.stars(float(rt["sum"]) / float(rt["n"]), 22))
		rr.add_child(UI.lbl("%.1f (%d)" % [float(rt["sum"]) / float(rt["n"]), int(rt["n"])], 18, UI.MUTED))
		hv.add_child(rr)
	var tg := HFlowContainer.new()
	tg.add_theme_constant_override("h_separation", 6)
	tg.add_child(UI.pill(str(p["status"]).capitalize(), UI.GREEN if p["status"] == "active" else UI.DIM))
	for t in p.get("tags", []):
		tg.add_child(UI.pill(str(t), UI.GOLD))
	for a in p.get("awards", []):
		tg.add_child(UI.pill("🏆 " + str(a), UI.GOLD2))
	if p.get("edition", {}).get("type", "regular") == "limited":
		tg.add_child(UI.pill("Limited %d/%d made" % [int(p["edition"].get("made", 0)), int(p["edition"].get("limit", 0))], UI.ROSE))
	hv.add_child(tg)
	hh.add_child(hv)
	hero.add_child(hh)
	if not mine:
		hero.add_child(UI.lbl("Owned by " + G.company(p["company"])["name"], 19, UI.MUTED))
	body.add_child(UI.seg([["Overview", "overview"], ["Sales", "sales"], ["Reviews", "reviews"], ["History", "history"]], tab, func(v):
		tab = v
		rebuild()))
	match tab:
		"overview":
			_overview(p, ev, mine)
		"sales":
			_sales(p)
		"reviews":
			_reviews(p)
		"history":
			_history(p)


func _overview(p: Dictionary, ev: Dictionary, mine: bool) -> void:
	var wk: Array = p["wk"]
	var last: Array = wk[wk.size() - 1] if not wk.is_empty() else [0, 0, 0.0, 0.0, 0]
	var avg := Rivals.avg_units(p, 4) if not wk.is_empty() else 0.0
	var g := UI.grid(2, 10)
	g.add_child(UI.stat("Units last week", G.group_int(int(last[1])), ("Lost sales: %d" % int(last[4])) if int(last[4]) > 0 else "", UI.CREAM, UI.RED))
	g.add_child(UI.stat("Revenue last week", G.money(float(last[2]))))
	g.add_child(UI.stat("In stock", G.group_int(int(p["inv"])), ("%.1f weeks cover" % (float(p["inv"]) / avg)) if avg > 0.0 else "", UI.RED if int(p["inv"]) <= 0 and p["status"] == "active" else UI.CREAM))
	g.add_child(UI.stat("Unit cost / price", "%s / %s" % [G.money(float(p["unit_cost"]), 2), G.money(float(p["price"]), 0)]))
	g.add_child(UI.stat("Lifetime units", G.group_int(int(p["st"]["units"]))))
	g.add_child(UI.stat("Contribution", G.money(float(p["st"].get("cm", 0.0))), "after cost & fees", UI.GREEN if float(p["st"].get("cm", 0.0)) >= 0.0 else UI.RED))
	body.add_child(g)
	# pipeline
	var orders = G.s["orders"].filter(func(o): return o["product"] == p["id"])
	if not orders.is_empty():
		UI.section(body, "Production pipeline")
		for o in orders:
			ProductionRow.add(body, o)
	if mine:
		UI.section(body, "Actions")
		var a := UI.grid(2, 10)
		if p["status"] != "discontinued":
			a.add_child(UI.btn("Produce more", func(): OrderDialog.open(p), "primary", 21, 72))
			a.add_child(UI.btn("Change price", func(): _price(p), "secondary", 21, 72))
			a.add_child(UI.btn("Markets", func(): _markets(p), "secondary", 21, 72))
			a.add_child(UI.btn("Advertise", func(): Router.go("campaign_new", {"product": p["id"]}), "secondary", 21, 72))
			a.add_child(UI.btn("Reformulate", func(): _reformulate(p), "secondary", 21, 72))
			a.add_child(UI.btn("Survey", func(): Router.go("research", {"product": p["id"]}), "secondary", 21, 72))
			if p.get("kind", "full") == "full":
				a.add_child(UI.btn("Line extension", func(): _extension(p), "secondary", 21, 72))
			a.add_child(UI.btn("Discontinue", func(): Router.confirm("Discontinue %s?" % p["name"], "It stops selling. Its history is preserved and you can relaunch it later. Remaining stock stays in inventory.", func():
				p["status"] = "discontinued"
				p["disc_week"] = G.week()
				CompanyEngine.plog(p, "Discontinued.")
				G.touch(), "Discontinue", true), "danger", 21, 72))
		else:
			a.add_child(UI.btn("Relaunch", func():
				p["status"] = "active" if p.get("launched", false) else "dev"
				CompanyEngine.plog(p, "Relaunched.")
				G.touch(), "primary", 21, 72))
		body.add_child(a)
	# markets
	UI.section(body, "Markets")
	for cid in p["markets"]:
		var m: Dictionary = p["mk"].get(cid, {})
		var mc := UI.card(body, "flat", 6)
		var mh := UI.hbox(10)
		mh.add_child(UI.lbl(DB.country(cid)["name"], 22, UI.CREAM, "semi"))
		mh.add_child(UI.expand(UI.spacer()))
		mh.add_child(UI.lbl("%d units last week" % int(m.get("last", 0)), 19, UI.GOLD2, "semi"))
		mc.add_child(mh)
		var r2 := UI.hbox(10)
		var aw := UI.vbox(2)
		aw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		aw.add_child(UI.lbl("Awareness %s" % G.pct(float(m.get("aw", 0.0)), 1), 17, UI.MUTED))
		aw.add_child(UI.bar(float(m.get("aw", 0.0)) / 0.5, UI.GOLD, 8))
		r2.add_child(aw)
		var sa := UI.vbox(2)
		sa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sa.add_child(UI.lbl("Satisfied buyers %s" % G.pct(float(m.get("sat", 0.5))), 17, UI.MUTED))
		sa.add_child(UI.bar(float(m.get("sat", 0.5)), UI.GREEN, 8))
		r2.add_child(sa)
		mc.add_child(r2)
		mc.add_child(UI.lbl("Loyal customers %s · Buzz %s · Lifetime %s units" % [G.group_int(int(m.get("loyal", 0))), G.pct(float(m.get("buzz", 0.0))), G.group_int(int(m.get("u", 0)))], 17, UI.MUTED))
	# composition summary
	UI.section(body, "Fragrance")
	var fc := UI.card(body)
	var notes: Dictionary = ev.get("notes", {})
	for k in ["top", "heart", "base"]:
		if notes.has(k) and not notes[k].is_empty():
			UI.kv(fc, k.capitalize() + " notes", ", ".join(notes[k]))
	if mine:
		var tests := Lab.tests_for(p["formula"])
		if not tests.is_empty():
			var t: Dictionary = tests[tests.size() - 1]
			if t["res"].has("longevity"):
				UI.kv(fc, "Measured longevity", "%.1fh" % float(t["res"]["longevity"]), UI.GOLD2)
				UI.kv(fc, "Measured projection", FormulaEngine.projection_label(float(t["res"]["projection"])), UI.GOLD2)
		fc.add_child(UI.btn("Open formula", func(): Router.go("formula_editor", {"fid": p["formula"], "v": int(p["fv"])}), "ghost", 20, 56))
	if not p.get("critics", []).is_empty():
		UI.section(body, "Critics")
		for cr in p["critics"]:
			var cc := UI.card(body, "flat", 4)
			var ch := UI.hbox(10)
			ch.add_child(UI.lbl("%s · %s" % [cr["critic"], cr["outlet"]], 19, UI.GOLD2, "semi"))
			ch.add_child(UI.expand(UI.spacer()))
			ch.add_child(UI.lbl("%.1f/10" % float(cr["score"]), 20, UI.CREAM, "title"))
			cc.add_child(ch)
			cc.add_child(UI.para(str(cr["text"]), 19, UI.TEXT))


func _sales(p: Dictionary) -> void:
	var wk: Array = p["wk"]
	if wk.size() < 2:
		UI.empty(body, "Sales history appears once the product has been on sale for a couple of weeks.")
		return
	var units: Array = []
	var rev: Array = []
	var lost: Array = []
	var xl: Array = []
	for i in wk.size():
		units.append(float(wk[i][1]))
		rev.append(float(wk[i][2]))
		lost.append(float(wk[i][4]))
		xl.append(G.short_date(int(wk[i][0])) if i % maxi(1, int(wk.size() / 4)) == 0 else "")
	UI.section(body, "Weekly units (and lost sales)")
	var c1 := UI.card(body)
	var ch := LineChart.new()
	ch.set_data([{"v": units, "c": UI.GOLD}, {"v": lost, "c": UI.RED}], xl, "int")
	var mk: Array = []
	for vv in p["versions"]:
		for i in wk.size():
			if int(wk[i][0]) == int(vv[1]) and int(vv[0]) > 0:
				mk.append([i, "v%d" % (int(vv[0]) + 1)])
	ch.markers = mk
	c1.add_child(ch)
	UI.section(body, "Weekly revenue")
	var c2 := UI.card(body)
	var ch2 := LineChart.new()
	ch2.set_data([{"v": rev, "c": UI.ROSE}], xl, "money")
	c2.add_child(ch2)
	UI.section(body, "By year")
	var yc := UI.card(body, "flat", 6)
	for y in p["yr"]:
		var a: Array = p["yr"][y]
		UI.kv(yc, str(y), "%s units · %s · contrib. %s" % [G.group_int(int(a[0])), G.money(float(a[1])), G.money(float(a[2]))])
	var bv: Dictionary = p["st"].get("by_v", {})
	if bv.size() > 1:
		UI.section(body, "Units by formula version")
		var vc := UI.card(body, "flat", 6)
		for k in bv:
			UI.kv(vc, "Version %d" % (int(k) + 1), G.group_int(int(bv[k])))


func _reviews(p: Dictionary) -> void:
	var rt: Dictionary = p["rating"]
	if int(rt["n"]) == 0:
		UI.empty(body, "No customer reviews yet.")
		return
	var rc := UI.card(body)
	var avg := float(rt["sum"]) / float(rt["n"])
	var rh := UI.hbox(14)
	rh.add_child(UI.title("%.1f" % avg, 52, UI.GOLD2))
	var rv := UI.vbox(2)
	rv.add_child(UI.stars(avg, 26))
	rv.add_child(UI.lbl("%d reviews on ScentNotes" % int(rt["n"]), 18, UI.MUTED))
	rh.add_child(rv)
	rc.add_child(rh)
	for s in range(4, -1, -1):
		var h := UI.hbox(8)
		h.add_child(UI.lbl("%d★" % (s + 1), 18, UI.MUTED))
		h.add_child(UI.bar(float(rt["d"][s]) / float(rt["n"]), UI.GOLD, 10))
		h.add_child(UI.lbl(str(int(rt["d"][s])), 16, UI.MUTED))
		rc.add_child(h)
	var revs: Array = p["reviews"]
	for i in range(revs.size() - 1, -1, -1):
		ReviewCard.add(body, revs[i])


func _history(p: Dictionary) -> void:
	var hc := UI.card(body, "flat", 6)
	UI.kv(hc, "Created", G.date_str(int(p["created"])))
	if int(p["launch_week"]) != -1:
		UI.kv(hc, "Launched", G.date_str(int(p["launch_week"])) if int(p["launch_week"]) >= 0 else "Before 2027")
	var perf: String = p.get("perfumer", "ceo")
	UI.kv(hc, "Original perfumer", "You (CEO)" if perf == "ceo" or perf == "" else G.employee(perf).get("name", "Unknown"))
	UI.kv(hc, "Countries sold", ", ".join(p.get("countries_sold", {}).keys()) if not p.get("countries_sold", {}).is_empty() else "—")
	UI.kv(hc, "Formula versions sold", str(p["versions"].size()))
	UI.kv(hc, "Campaigns", str(p["campaigns"].size()))
	UI.kv(hc, "Returns", G.group_int(int(p["st"]["returns"])))
	var lg: Array = p["log"]
	UI.section(body, "Timeline")
	for i in range(lg.size() - 1, -1, -1):
		var row := UI.hbox(10)
		row.add_child(UI.lbl(G.short_date(int(lg[i][0])), 17, UI.DIM))
		row.add_child(UI.lbl(str(lg[i][1]), 19, UI.TEXT, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
		body.add_child(row)


func _price(p: Dictionary) -> void:
	Router.number("Retail price", float(p["price"]), maxf(2.0, round(float(p["unit_cost"]) * 1.1)), maxf(80.0, float(p["price"]) * 3.0), 1.0, func(v):
		CompanyEngine.plog(p, "Price changed from %s to %s." % [G.money(float(p["price"]), 0), G.money(v, 0)])
		p["price"] = v
		p["base_price"] = v
		G.touch(), func(v): return G.money(v, 0), "Unit cost %s. Lower prices sell more units; premium prices earn more per bottle — and signal quality to some buyers." % G.money(float(p["unit_cost"]), 2))


func _markets(p: Dictionary) -> void:
	var sel: Array = p["markets"].duplicate()
	Router.modal("Sales markets", func(v: VBoxContainer):
		v.add_child(UI.para("Choose where %s is sold. Without an office, sales go through your online store with cross-border shipping." % p["name"], 20))
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		for ct in DB.countries:
			var id: String = ct["id"]
			var b := UI.chip(ct["name"], sel.has(id), Callable())
			b.pressed.connect(func():
				if sel.has(id):
					if sel.size() > 1:
						sel.erase(id)
				else:
					sel.append(id)
				UI.style_btn(b, "chip_on" if sel.has(id) else "chip", 21))
			flow.add_child(b)
		v.add_child(flow), [["Cancel", Callable(), "secondary"], ["Save", func():
			p["markets"] = sel
			var b2 := G.brand(p["brand"])
			for m in sel:
				if not b2["markets"].has(m):
					b2["markets"].append(m)
			CompanyEngine.plog(p, "Markets: " + ", ".join(sel))
			G.touch(), "primary"]])


func _reformulate(p: Dictionary) -> void:
	var f := G.formula(p["formula"])
	var opts: Array = []
	for i in f["versions"].size():
		var vv: Dictionary = f["versions"][i]
		opts.append(["Version %d%s" % [i + 1, " (current)" if i == int(p["fv"]) else ""], i, "%s · %s" % [str(vv.get("note", "")), G.short_date(int(vv["w"]))]])
	opts.append(["Edit formula → new version", -1, "Opens the editor; save a new version, then come back and switch"])
	Router.pick("Formula version for %s" % p["name"], opts, func(v):
		if v == -1:
			Router.go("formula_editor", {"fid": p["formula"], "v": int(p["fv"])})
			return
		if v == int(p["fv"]):
			return
		var ev_old = MarketEngine.product_ev(p)
		p["prev_sat"] = _avg_sat(ev_old)
		p["fv"] = v
		p["versions"].append([v, G.week()])
		CompanyEngine.plog(p, "Reformulated to version %d. Future batches use the new formula; stock on hand is the previous version." % (v + 1))
		G.clear_cache()
		G.touch())


func _avg_sat(ev: Dictionary) -> float:
	if ev.is_empty():
		return 0.0
	var b := ConsumerEngine.seg_base(ev)
	var t := 0.0
	for x in b["sat"]:
		t += x
	return t / float(b["sat"].size())


func _extension(p: Dictionary) -> void:
	Router.pick("Line extension", [["Travel size (10 ml)", "travel", "Same fragrance, impulse & travel buyers"], ["Sample vials (2 ml)", "sample", "Cheap trial that converts into full bottles"],
		["Limited edition", "limited", "Numbered run with special packaging"], ["Discovery set", "discovery", "Minis of several of your fragrances"]], func(k):
		if k == "discovery":
			Router.go("discovery", {"brand": p["brand"]})
		elif k == "limited":
			Router.go("launch", {"parent": p["id"], "kind": "full", "edition": "limited"})
		else:
			Router.go("launch", {"parent": p["id"], "kind": k}))
