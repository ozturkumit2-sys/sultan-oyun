extends Screen
## Composition editor: real ingredient percentages of the concentrate, dilution to a finished format,
## live olfactive preview (what the perfumer smells), cost, validation and versioned saving.

const TEMPLATES := [
	["Citrus Cologne", "edc", [["bergamot", 30], ["lemon", 12], ["orange", 10], ["lavender", 8], ["linalool", 10], ["hedione", 12], ["geranium", 3], ["galaxolide", 8], ["cedarwood", 4], ["bht", 0.3], ["dpg", 2.7]]],
	["Fresh Aquatic", "edt", [["bergamot", 14], ["dihydromyrcenol", 16], ["grapefruit", 6], ["hedione", 18], ["iso_e_super", 18], ["cedarwood", 8], ["galaxolide", 14], ["bht", 0.3], ["dpg", 5.7]]],
	["Floral Bouquet", "edp", [["pea", 18], ["citronellol", 10], ["geraniol", 3], ["geranium", 6], ["ylang", 4], ["hedione", 16], ["ionones", 6], ["muguet_accord", 8], ["benzyl_salicylate", 8], ["galaxolide", 12], ["ethylene_brassylate", 9]]],
	["Woody Amber", "edp", [["bergamot", 10], ["iso_e_super", 32], ["cedarwood", 14], ["patchouli", 6], ["amber_accord", 14], ["hedione", 10], ["galaxolide", 12], ["dpg", 2]]],
	["Vanilla Gourmand", "edp", [["orange", 8], ["ethyl_maltol", 1.5], ["vanillin", 10], ["coumarin", 3], ["amber_accord", 18], ["peach_lactone", 5], ["patchouli", 5], ["galaxolide", 18], ["iso_e_super", 14], ["benzyl_benzoate", 10], ["dpg", 7.5]]],
	["Aromatic Fougère", "edt", [["bergamot", 12], ["lavender", 16], ["geranium", 6], ["coumarin", 4], ["linalool", 8], ["cedarwood", 14], ["patchouli", 6], ["iso_e_super", 16], ["galaxolide", 10], ["bht", 0.3], ["dpg", 7.7]]],
	["Clean Musk", "edp", [["galaxolide", 25], ["ethylene_brassylate", 28], ["hedione", 15], ["pea", 8], ["bergamot", 8], ["iso_e_super", 10], ["benzyl_salicylate", 6]]],
	["Fruity Floral", "edt", [["orange", 10], ["peach_lactone", 6], ["ethyl_maltol", 0.8], ["pea", 18], ["citronellol", 8], ["hedione", 16], ["muguet_accord", 8], ["galaxolide", 16], ["ethylene_brassylate", 10], ["dpg", 7.2]]],
]

var items: Array = []
var fmt := "edp"
var conc := 18.0
var fname := "New Formula"
var fid := ""
var base_v := -1
var is_accord := false
var preview_box: VBoxContainer
var totals_box: VBoxContainer
var rows_box: VBoxContainer
var _timer: Timer
var _value_lbls: Array = []


func page_title() -> String:
	return "Accord editor" if is_accord else "Formula editor"


func setup(p: Dictionary) -> void:
	params = p
	fid = p.get("fid", "")
	is_accord = p.get("accord", false)
	if fid != "":
		var f := G.formula(fid)
		base_v = int(p.get("v", f["versions"].size() - 1))
		var fv: Dictionary = f["versions"][base_v]
		items = fv["items"].duplicate(true)
		fname = f["name"]
		fmt = f.get("fmt", "edp")
		conc = float(f.get("conc", DB.formats[fmt]["def"]))
		is_accord = f.get("accord", false)
	elif p.has("items"):
		items = p["items"].duplicate(true)
		fname = p.get("name", "New Formula")
		fmt = p.get("fmt", "edp")
		conc = float(p.get("conc", DB.formats[fmt]["def"]))
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 0.18
	_timer.timeout.connect(_refresh_preview)
	add_child(_timer)
	_make()
	build()


func build() -> void:
	_value_lbls.clear()
	# header
	var hc := UI.card(body, "gold")
	var hh := UI.hbox(10)
	var t := UI.title(fname, 32)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hh.add_child(t)
	hh.add_child(UI.btn("Rename", func(): Router.text_input("Formula name", fname, func(s):
		if s != "":
			fname = s
			if fid != "":
				G.formula(fid)["name"] = s
			rebuild()), "ghost", 20, 56))
	hc.add_child(hh)
	if fid != "":
		var f := G.formula(fid)
		var vopts: Array = []
		for i in f["versions"].size():
			vopts.append(["v%d" % (i + 1), i])
		hc.add_child(UI.seg(vopts, base_v, func(v): _load_version(v)))
		var fv: Dictionary = f["versions"][base_v]
		hc.add_child(UI.lbl("Version %d · %s · %s" % [base_v + 1, str(fv.get("note", "")), G.short_date(int(fv["w"]))], 18, UI.MUTED))
	if not is_accord:
		var fopts: Array = []
		for fm in DB.biz["formats"]:
			fopts.append([fm["name"], fm["id"]])
		hc.add_child(UI.seg(fopts, fmt, func(v):
			fmt = v
			conc = float(DB.formats[fmt]["def"])
			rebuild(), 19))
		var fd: Dictionary = DB.formats[fmt]
		var cr := UI.hbox(10)
		var cl := UI.lbl("Concentrate %.1f%%" % conc, 21, UI.GOLD2, "semi")
		cl.custom_minimum_size.x = 230
		cr.add_child(cl)
		cr.add_child(UI.slider(float(fd["min"]), float(fd["max"]), 0.5, conc, func(x):
			conc = x
			cl.text = "Concentrate %.1f%%" % x
			_queue()))
		hc.add_child(cr)
		hc.add_child(UI.para("The concentrate below always totals 100%%. It is diluted to %.1f%% in %s for the finished %s." % [conc, "carrier oil" if fd["base"] == "oil" else "perfumer's ethanol", fd["name"]], 18))
	totals_box = UI.vbox(6)
	body.add_child(totals_box)
	# composition
	UI.section(body, "Composition (%% of concentrate)")
	rows_box = UI.vbox(10)
	body.add_child(rows_box)
	_build_rows()
	var tools := UI.grid(2, 10)
	tools.add_child(UI.btn("+ Add material", _pick_material, "primary", 21, 70))
	tools.add_child(UI.btn("+ Insert accord", _pick_accord, "secondary", 21, 70))
	tools.add_child(UI.btn("Scale to 100%", func():
		items = FormulaEngine.normalize_items(items)
		rebuild(), "secondary", 21, 70))
	tools.add_child(UI.btn("Fill with DPG", func():
		var tot := _total()
		if tot < 100.0:
			items = FormulaEngine.normalize_items(items, "dpg")
			rebuild(), "secondary", 21, 70))
	tools.add_child(UI.btn("Start from a classic", _pick_template, "secondary", 21, 70))
	tools.add_child(UI.btn("Clear", func(): Router.confirm("Clear formula?", "Remove all materials from this draft?", func():
		items = []
		rebuild(), "Clear", true), "ghost", 21, 70))
	body.add_child(tools)
	# preview
	UI.section(body, "Olfactive preview")
	preview_box = UI.vbox(12)
	body.add_child(preview_box)
	_refresh_preview()
	# actions
	UI.section(body, "Save & next steps")
	var sv := UI.grid(2, 10)
	sv.add_child(UI.btn("Save as new version" if fid != "" else "Save formula", _save, "primary", 21, 76))
	sv.add_child(UI.btn("Save as new formula", _save_new, "secondary", 21, 76))
	if not is_accord:
		sv.add_child(UI.btn("Save as accord", _save_accord, "secondary", 21, 76))
		sv.add_child(UI.btn("Lab test", func(): _after_save(func(f2, v2): Router.go("tests", {"fid": f2, "v": v2, "fmt": fmt, "conc": conc})), "secondary", 21, 76))
		sv.add_child(UI.btn("Consumer survey", func(): _after_save(func(f2, v2): Router.go("research", {"fid": f2, "v": v2, "fmt": fmt, "conc": conc})), "secondary", 21, 76))
		sv.add_child(UI.btn("Launch product", func(): _after_save(func(f2, v2): Router.go("launch", {"fid": f2, "v": v2, "fmt": fmt, "conc": conc})), "primary", 21, 76))
	body.add_child(sv)
	if fid != "":
		var f3 := G.formula(fid)
		body.add_child(UI.btn("Archive formula" if not f3.get("archived", false) else "Restore formula", func():
			f3["archived"] = not f3.get("archived", false)
			G.touch()
			Router.back(), "ghost", 20, 60))


func _build_rows() -> void:
	for ch in rows_box.get_children():
		ch.queue_free()
	_value_lbls.clear()
	if items.is_empty():
		UI.empty(rows_box, "Add materials or start from a classic structure.")
		return
	var order := {"top": 0, "heart": 1, "base": 2, "solvent": 3}
	items.sort_custom(func(a, b):
		var ra := DB.ing(a[0])
		var rb := DB.ing(b[0])
		var oa: int = order.get(ra.get("note", "heart") if ra.get("role", "") == "aromatic" else "solvent", 3)
		var ob: int = order.get(rb.get("note", "heart") if rb.get("role", "") == "aromatic" else "solvent", 3)
		if oa != ob:
			return oa < ob
		return float(a[1]) > float(b[1]))
	for i in items.size():
		_row(i)


func _row(i: int) -> void:
	var it: Array = items[i]
	var rec := DB.ing(it[0])
	var p := UI.panel("dark", 14)
	var v := UI.vbox(6)
	p.add_child(v)
	var h := UI.hbox(8)
	var nm := UI.lbl(FormulaEngine.short_name(rec), 23, UI.CREAM, "semi")
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	h.add_child(nm)
	var role: String = rec.get("role", "aromatic")
	var tag: String = rec.get("note", "") if role == "aromatic" else role
	var tcol = {"top": UI.AMBER, "heart": UI.ROSE, "base": UI.GOLD, "solvent": UI.BLUE, "carrier": UI.BLUE, "auxiliary": UI.BLUE}.get(tag, UI.MUTED)
	h.add_child(UI.pill(tag.capitalize(), tcol, 16))
	if rec.get("nat", false):
		h.add_child(UI.pill("Natural", UI.GREEN, 16))
	var idx := i
	var info := UI.btn("i", func(): IngredientInfo.show(rec["id"]), "ghost", 20, 48)
	info.custom_minimum_size.x = 44
	h.add_child(info)
	var x := UI.btn("✕", func():
		items.remove_at(idx)
		_build_rows()
		_queue(), "ghost", 20, 48)
	x.custom_minimum_size.x = 48
	h.add_child(x)
	v.add_child(h)
	var r := UI.hbox(8)
	var maxv := 60.0 if role == "aromatic" else 40.0
	if float(rec.get("str", 0)) >= 2.4:
		maxv = 10.0
	if it[0] == "bht" or it[0] == "uv_absorber":
		maxv = 2.0
	var vl := UI.lbl("%.2f%%" % float(it[1]), 22, UI.GOLD2, "semi", HORIZONTAL_ALIGNMENT_RIGHT)
	vl.custom_minimum_size.x = 104
	var fin := UI.lbl("", 16, UI.MUTED, "body", HORIZONTAL_ALIGNMENT_RIGHT)
	var sl := UI.slider(0.0, maxv, 0.05 if maxv <= 10.0 else 0.1, float(it[1]), func(val):
		items[idx][1] = snappedf(val, 0.01)
		vl.text = "%.2f%%" % val
		_fin_text(fin, idx)
		_queue())
	var minus := UI.btn("−", func(): sl.value = maxf(0.0, sl.value - (0.1 if maxv <= 10.0 else 0.5)), "dark", 24, 52)
	minus.custom_minimum_size.x = 52
	var plus := UI.btn("+", func(): sl.value = sl.value + (0.1 if maxv <= 10.0 else 0.5), "dark", 24, 52)
	plus.custom_minimum_size.x = 52
	r.add_child(minus)
	r.add_child(sl)
	r.add_child(plus)
	var tap := TapPanel.new()
	tap.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	tap.add_child(vl)
	tap.tapped = func(): Router.number(FormulaEngine.short_name(rec), float(items[idx][1]), 0.0, 100.0, 0.01, func(nv):
		items[idx][1] = snappedf(nv, 0.01)
		sl.set_value_no_signal(minf(nv, maxv))
		vl.text = "%.2f%%" % nv
		_fin_text(fin, idx)
		_queue(), func(xv): return "%.2f%%" % xv)
	r.add_child(tap)
	v.add_child(r)
	_fin_text(fin, idx)
	v.add_child(fin)
	rows_box.add_child(p)


func _fin_text(l: Label, idx: int) -> void:
	if idx >= items.size():
		return
	var it: Array = items[idx]
	var rec := DB.ing(it[0])
	var fin := float(it[1]) * conc / 100.0
	var t := "Finished product: %.3f%%" % fin if not is_accord else ""
	var mx: Variant = rec.get("reg", {}).get("max")
	if mx != null and not is_accord:
		t += "  ·  FSC limit %.2f%%" % float(mx)
		l.add_theme_color_override("font_color", UI.RED if fin > float(mx) else UI.MUTED)
	var price := G.ing_price(it[0])
	t += "  ·  %s/kg" % G.money(price)
	l.text = t


func _total() -> float:
	var t := 0.0
	for it in items:
		t += float(it[1])
	return t


func _queue() -> void:
	if _timer != null:
		_timer.start()


func _refresh_preview() -> void:
	if preview_box == null:
		return
	for ch in preview_box.get_children():
		ch.queue_free()
	for ch in totals_box.get_children():
		ch.queue_free()
	var tot := _total()
	var tc := UI.card(totals_box, "flat", 6)
	var th := UI.hbox(12)
	var ok := absf(tot - 100.0) <= 0.05
	th.add_child(UI.lbl("Total", 22, UI.MUTED))
	var tl := UI.lbl("%.2f%%" % tot, 28, UI.GREEN if ok else UI.RED, "title")
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(tl)
	if items.is_empty():
		tc.add_child(th)
		return
	var cost := FormulaEngine.concentrate_cost(items)
	th.add_child(UI.lbl("%s/kg" % G.money(cost), 22, UI.GOLD2, "semi"))
	tc.add_child(th)
	if not is_accord:
		var jml := FormulaEngine.juice_cost_ml(items, fmt, conc)
		tc.add_child(UI.lbl("Juice cost: %s per 50 ml · %s per 100 ml" % [G.money(jml * 50.0, 2), G.money(jml * 100.0, 2)], 19, UI.MUTED))
	if not ok:
		tc.add_child(UI.lbl("Adjust to exactly 100% (use 'Scale to 100%' or 'Fill with DPG').", 18, UI.RED))
	if is_accord:
		return
	var ev := FormulaEngine.evaluate(FormulaEngine.normalize_items(items) if not ok else items, fmt, conc)
	var pc := UI.card(preview_box)
	var ph := UI.hbox(10)
	ph.add_child(UI.title(str(ev["family"]), 30, UI.GOLD2))
	pc.add_child(ph)
	var rad := Radar.new()
	rad.custom_minimum_size = Vector2(0, 360)
	rad.set_profiles([[ev["open"], UI.AMBER], [ev["heart"], UI.ROSE], [ev["dry"], UI.GOLD]])
	pc.add_child(rad)
	var lg := UI.hbox(14)
	lg.add_child(UI.lbl("● Opening", 17, UI.AMBER))
	lg.add_child(UI.lbl("● Heart", 17, UI.ROSE))
	lg.add_child(UI.lbl("● Dry-down", 17, UI.GOLD))
	pc.add_child(lg)
	var notes: Dictionary = ev["notes"]
	for k in ["top", "heart", "base"]:
		if notes[k].is_empty():
			continue
		var nh := UI.hbox(8)
		var kl := UI.lbl(k.capitalize() + " notes", 19, UI.MUTED)
		kl.custom_minimum_size.x = 150
		nh.add_child(kl)
		nh.add_child(UI.lbl(", ".join(notes[k]), 20, UI.TEXT, "medium", HORIZONTAL_ALIGNMENT_LEFT, true))
		pc.add_child(nh)
	UI.divider(pc)
	pc.add_child(UI.lbl("YOUR NOSE TELLS YOU", 16, UI.GOLD, "semi"))
	for d in [["Freshness", float(ev["fresh"]), UI.BLUE], ["Sweetness", float(ev["sweet"]), UI.AMBER], ["Complexity", float(ev["complexity"]), UI.GOLD],
			["Contrast / tension", float(ev["tension"]), UI.ROSE], ["Raw edges", float(ev["harsh"]), UI.RED], ["Initial strength", float(ev["intensity"]), UI.GOLD2]]:
		var dh := UI.hbox(10)
		var dl := UI.lbl(d[0], 19, UI.MUTED)
		dl.custom_minimum_size.x = 210
		dh.add_child(dl)
		dh.add_child(UI.bar(clampf(d[1], 0.0, 1.0), d[2], 10))
		pc.add_child(dh)
	if not ev["interactions"].is_empty():
		pc.add_child(UI.para("Accords detected: " + ", ".join(ev["interactions"]), 18, UI.GOLD2))
	pc.add_child(UI.para("Longevity, projection and stability are measured in the lab — your nose only gives a first impression.", 17, UI.DIM))
	var tests := _matching_test()
	if not tests.is_empty():
		var res: Dictionary = tests["res"]
		var mc := UI.card(preview_box, "good")
		mc.add_child(UI.lbl("LAST LAB MEASUREMENT (%s)" % G.short_date(int(tests["w"])), 16, UI.GREEN, "semi"))
		if res.has("longevity"):
			UI.kv(mc, "Longevity", "%.1fh (%.1f–%.1f)" % [float(res["longevity"]), float(res["long_lo"]), float(res["long_hi"])])
			UI.kv(mc, "Projection", FormulaEngine.projection_label(float(res["projection"])))
		if res.has("stab_label"):
			UI.kv(mc, "Stability", str(res["stab_label"]))
	var errs: Array = ev["errors"].duplicate()
	if not ok:
		errs = errs.filter(func(e): return not str(e).begins_with("Concentrate totals"))
	if not errs.is_empty() or not ev["warnings"].is_empty():
		var wc := UI.card(preview_box, "warn")
		for e in errs:
			wc.add_child(UI.para("• " + str(e), 19, UI.RED))
		for w in ev["warnings"]:
			wc.add_child(UI.para("• " + str(w), 19, UI.AMBER))
	if not ev["allergens"].is_empty():
		preview_box.add_child(UI.para("Allergen labeling required: " + ", ".join(ev["allergens"].map(func(a): return FormulaEngine.short_name(DB.ing(a)))), 17, UI.DIM))


func _matching_test() -> Dictionary:
	if fid == "":
		return {}
	var f := G.formula(fid)
	for i in range(G.s["tests"].size() - 1, -1, -1):
		var t: Dictionary = G.s["tests"][i]
		if t["formula"] == fid and int(t["v"]) == base_v and t["fmt"] == fmt and absf(float(t["conc"]) - conc) < 0.01 and str(f["versions"][base_v]["items"]) == str(items):
			return t
	return {}


func _load_version(v: int) -> void:
	var f := G.formula(fid)
	base_v = v
	items = f["versions"][v]["items"].duplicate(true)
	rebuild()


func _pick_material() -> void:
	IngredientPicker.open(func(id):
		for it in items:
			if it[0] == id:
				Router.toast("Already in the formula.")
				return
		var rec := DB.ing(id)
		var amt := 5.0
		if float(rec.get("str", 0)) >= 2.4:
			amt = 1.0
		if id == "bht":
			amt = 0.2
		if rec["role"] != "aromatic":
			amt = 3.0
		items.append([id, amt])
		_build_rows()
		_queue())


func _pick_accord() -> void:
	var opts: Array = []
	for f in G.s["formulas"].values():
		if f["company"] == G.pid() and f.get("accord", false):
			opts.append([f["name"], f["id"], "%d materials" % f["versions"][f["versions"].size() - 1]["items"].size()])
	if opts.is_empty():
		Router.info("No accords yet", "Save a composition as an accord first (e.g. your signature rose or amber base), then insert it into any formula.")
		return
	Router.pick("Insert accord", opts, func(aid):
		Router.number("Accord share of concentrate", 10.0, 1.0, 80.0, 0.5, func(share):
			var fv := G.formula_version(aid)
			for it in fv["items"]:
				var add = float(it[1]) * share / 100.0
				var found := false
				for mine in items:
					if mine[0] == it[0]:
						mine[1] = snappedf(float(mine[1]) + add, 0.01)
						found = true
				if not found:
					items.append([it[0], snappedf(add, 0.01)])
			_build_rows()
			_queue(), func(x): return "%.1f%%" % x))


func _pick_template() -> void:
	var opts: Array = []
	for i in TEMPLATES.size():
		opts.append([TEMPLATES[i][0], i, DB.formats[TEMPLATES[i][1]]["name"]])
	Router.pick("Start from a classic structure", opts, func(i):
		var t: Array = TEMPLATES[i]
		var its: Array = []
		for it in t[2]:
			if G.ing_available(G.pid(), it[0]):
				its.append([it[0], float(it[1])])
		items = FormulaEngine.normalize_items(its)
		fmt = t[1]
		conc = float(DB.formats[fmt]["def"])
		if fname == "New Formula":
			fname = t[0] + " Study"
		rebuild())


func _valid_for_save() -> bool:
	if items.is_empty():
		Router.toast("The formula is empty.", "bad")
		return false
	if absf(_total() - 100.0) > 0.05:
		Router.toast("The concentrate must total 100%.", "bad")
		return false
	return true


func _clean_items() -> Array:
	var out: Array = []
	for it in items:
		if float(it[1]) > 0.0:
			out.append([it[0], snappedf(float(it[1]), 0.01)])
	return out


func _save() -> void:
	if not _valid_for_save():
		return
	if fid == "":
		_create(false)
		return
	var f := G.formula(fid)
	var cur: Dictionary = f["versions"][base_v]
	if str(cur["items"]) == str(_clean_items()):
		f["fmt"] = fmt
		f["conc"] = conc
		Router.toast("No changes to save.")
		return
	Router.text_input("Version note", "Adjusted composition", func(note):
		base_v = CompanyEngine.add_version(fid, _clean_items(), note if note != "" else "Revision")
		f["fmt"] = fmt
		f["conc"] = conc
		items = f["versions"][base_v]["items"].duplicate(true)
		Tutorial.check()
		G.touch()
		Router.toast("Saved as version %d. Earlier versions are preserved." % (base_v + 1), "good")
		rebuild())


func _save_new() -> void:
	if not _valid_for_save():
		return
	_create(is_accord)


func _save_accord() -> void:
	if not _valid_for_save():
		return
	_create(true)


func _create(accord: bool) -> void:
	Router.text_input("Name your %s" % ("accord" if accord else "formula"), fname if fname != "New Formula" else "", func(n):
		if n == "":
			n = "Untitled"
		var f := CompanyEngine.make_formula(G.pid(), n, _clean_items(), "ceo", "Original")
		f["accord"] = accord
		f["fmt"] = fmt
		f["conc"] = conc
		if not accord:
			fid = f["id"]
			base_v = 0
			fname = n
		Tutorial.check()
		G.touch()
		Router.toast("%s \"%s\" saved." % ["Accord" if accord else "Formula", n], "good")
		rebuild())


## Ensures the current draft is saved, then continues with (formula id, version).
func _after_save(next: Callable) -> void:
	if not _valid_for_save():
		return
	if fid != "" and str(G.formula(fid)["versions"][base_v]["items"]) == str(_clean_items()):
		G.formula(fid)["fmt"] = fmt
		G.formula(fid)["conc"] = conc
		next.call(fid, base_v)
		return
	if fid != "":
		base_v = CompanyEngine.add_version(fid, _clean_items(), "Revision")
		G.formula(fid)["fmt"] = fmt
		G.formula(fid)["conc"] = conc
		Tutorial.check()
		G.touch()
		next.call(fid, base_v)
		return
	Router.text_input("Name your formula", fname if fname != "New Formula" else "", func(n):
		if n == "":
			n = "Untitled"
		var f := CompanyEngine.make_formula(G.pid(), n, _clean_items(), "ceo", "Original")
		f["fmt"] = fmt
		f["conc"] = conc
		fid = f["id"]
		base_v = 0
		fname = n
		Tutorial.check()
		G.touch()
		next.call(fid, 0))
