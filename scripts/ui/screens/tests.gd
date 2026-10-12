extends Screen
## Technical testing laboratory.

var fid := ""
var v := -1
var fmt := "edp"
var conc := 18.0


func page_title() -> String:
	return "Technical tests"


func hero_spec() -> Dictionary:
	return {"scene": "lab", "title": "Technical tests", "sub": "Longevity, projection, stability, safety", "focus": Vector2(0.45, 0.7), "h": 250.0}


func setup(p: Dictionary) -> void:
	params = p
	fid = p.get("fid", "")
	v = int(p.get("v", -1))
	fmt = p.get("fmt", "edp")
	conc = float(p.get("conc", 18.0))
	if fid == "":
		var forms := _forms()
		if not forms.is_empty():
			_select(forms[forms.size() - 1]["id"])
	_make()
	_pre_build()
	build()


func _forms() -> Array:
	return G.s["formulas"].values().filter(func(f): return f["company"] == G.pid() and not f.get("accord", false) and not f.get("archived", false))


func _select(id: String) -> void:
	fid = id
	var f := G.formula(id)
	v = f["versions"].size() - 1
	fmt = f.get("fmt", "edp")
	conc = float(f.get("conc", DB.formats[fmt]["def"]))


func build() -> void:
	var forms := _forms()
	if forms.is_empty():
		UI.empty(body, "Create a formula first.")
		body.add_child(UI.btn("Formula editor", func(): Router.replace("formula_editor", {}), "primary", 22))
		return
	var opts: Array = []
	for f in forms:
		opts.append([f["name"], f["id"]])
	UI.section(body, "Formula")
	body.add_child(UI.seg(opts, fid, func(x):
		_select(x)
		rebuild(), 20))
	var f := G.formula(fid)
	if f["versions"].size() > 1:
		var vo: Array = []
		for i in f["versions"].size():
			vo.append(["v%d" % (i + 1), i])
		body.add_child(UI.seg(vo, v, func(x):
			v = x
			rebuild()))
	var fo: Array = []
	for fm in DB.biz["formats"]:
		fo.append([fm["name"], fm["id"]])
	body.add_child(UI.seg(fo, fmt, func(x):
		fmt = x
		conc = float(DB.formats[x]["def"])
		rebuild(), 19))
	body.add_child(UI.lbl("%s at %.1f%% concentrate" % [DB.formats[fmt]["name"], conc], 19, UI.MUTED))
	var lvl := Lab.test_level(G.pid())
	var chem := Staff.best_skill(G.pid(), "chemist")
	body.add_child(UI.para("Measurement precision depends on your chemist (%s) and lab equipment (level %d). Advanced curves unlock with a larger headquarters." % ["skill %d" % int(chem * 100) if chem > 0.0 else "none hired", lvl], 18))
	var g := UI.grid(2, 10)
	for k in Lab.TESTS:
		var t: Dictionary = Lab.TESTS[k]
		var kind: String = k
		UI.tile(g, "chart", "%s · %s" % [t["name"], G.money(float(t["cost"]))], t["desc"], func():
			var r := Lab.run_test(G.pid(), fid, v, fmt, conc, kind)
			if r.has("error"):
				Router.toast(r["error"], "bad")
			else:
				Tutorial.check()
				G.touch())
	body.add_child(g)
	var ts := Lab.tests_for(fid)
	UI.section(body, "Results")
	if ts.is_empty():
		UI.empty(body, "No tests run on this formula yet.")
	for i in range(ts.size() - 1, maxi(-1, ts.size() - 7), -1):
		TestCard.add(body, ts[i])
