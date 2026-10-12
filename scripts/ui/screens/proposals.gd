extends Screen
## Perfumer proposal inbox.

var show := "open"


func page_title() -> String:
	return "Perfumer proposals"


func build() -> void:
	body.add_child(UI.seg([["Open", "open"], ["Revising", "revising"], ["Postponed", "postponed"], ["Decided", "decided"]], show, func(v):
		show = v
		rebuild()))
	var list: Array = []
	for p in G.s["proposals"]:
		if p["company"] != G.pid():
			continue
		var stt: String = p["status"]
		if (show == "decided" and (stt == "approved" or stt == "rejected")) or stt == show:
			list.append(p)
	if list.is_empty():
		UI.empty(body, "No proposals here. Hire perfumers — they develop ideas on their own or work on your briefs." if show == "open" else "Nothing here.")
		if Staff.count(G.pid(), "perfumer") == 0:
			body.add_child(UI.btn("Hire a perfumer", func(): Router.go("recruit", {"role": "perfumer"}), "primary", 22))
	for i in range(list.size() - 1, -1, -1):
		_card(list[i])


func _card(p: Dictionary) -> void:
	var e := G.employee(p["perfumer"])
	var c := UI.card(body)
	var h := UI.hbox(8)
	h.add_child(UI.title(p["name"], 28))
	h.add_child(UI.expand(UI.spacer()))
	h.add_child(UI.pill("Brief" if p["kind"] == "brief" else "Own idea", UI.BLUE if p["kind"] == "brief" else UI.ROSE))
	c.add_child(h)
	c.add_child(UI.lbl("by %s · %s" % [e.get("name", "former perfumer"), G.short_date(int(p["w"]))], 18, UI.MUTED))
	c.add_child(UI.para(str(p["concept"]), 20, UI.TEXT))
	var g := UI.grid(2, 8)
	g.add_child(UI.stat("Family", str(p["family"])))
	g.add_child(UI.stat("Suggested for", {"fem": "Feminine", "masc": "Masculine", "any": "Unisex"}.get(p["audience"], "Unisex")))
	g.add_child(UI.stat("Concentrate cost", G.money(float(p["est_cost_kg"])) + "/kg"))
	g.add_child(UI.stat("Perfumer's longevity estimate", "~%.0fh" % float(p["est_long"])))
	c.add_child(g)
	c.add_child(UI.lbl("%s %.0f%% · development cost so far %s" % [DB.formats[p["fmt"]]["name"], float(p["conc"]), G.money(float(p["dev_cost"]))], 18, UI.MUTED))
	if p["kind"] == "brief":
		if p["met"]:
			c.add_child(UI.pill("Brief met", UI.GREEN))
		else:
			for n in p["notes"]:
				c.add_child(UI.para("⚠ " + str(n), 18, UI.AMBER))
	var top: Array = p["items"].duplicate()
	top.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	c.add_child(UI.para("Key materials: " + ", ".join(top.slice(0, 6).map(func(it): return "%s %.1f%%" % [FormulaEngine.short_name(DB.ing(it[0])), float(it[1])])), 18, UI.MUTED))
	var pid: String = p["id"]
	if p["status"] == "open" or p["status"] == "postponed":
		var a := UI.grid(2, 8)
		a.add_child(UI.btn("Approve", func():
			var f := Lab.approve(Lab.proposal(pid))
			G.touch()
			Router.confirm("Approved", "\"%s\" is now in your formula library. Open it in the editor?" % f["name"], func(): Router.go("formula_editor", {"fid": f["id"]}), "Open")
			, "primary", 21, 68))
		a.add_child(UI.btn("Request revision", func(): _revise(pid), "secondary", 21, 68))
		a.add_child(UI.btn("Commission survey", func(): _survey(pid), "secondary", 21, 68))
		a.add_child(UI.btn("Open in editor", func(): Router.go("formula_editor", {"items": p["items"], "name": p["name"], "fmt": p["fmt"], "conc": p["conc"]}), "secondary", 21, 68))
		if p["status"] == "open":
			a.add_child(UI.btn("Postpone", func():
				Lab.proposal(pid)["status"] = "postponed"
				G.touch(), "ghost", 21, 68))
		a.add_child(UI.btn("Reject", func():
			Lab.reject(Lab.proposal(pid))
			G.touch(), "danger", 21, 68))
		c.add_child(a)
	elif p["status"] == "approved" and p.has("formula"):
		var fid: String = p["formula"]
		c.add_child(UI.btn("Open formula", func(): Router.go("formula_editor", {"fid": fid}), "ghost", 20, 56))


func _revise(pid: String) -> void:
	Router.pick("Revision direction", [["Cheaper", "cheaper", "Bring the concentrate cost down"], ["Longer lasting", "longer", "More base and fixation"],
		["Fresher", "fresher", "Brighter citrus/aromatic opening"], ["Sweeter", "sweeter", "More gourmand warmth"], ["Woodier", "woodier", "More woods"]], func(d):
		var e := Lab.request_revision(Lab.proposal(pid), d)
		Router.toast(e if e != "" else "Revision requested.", "bad" if e != "" else "good")
		G.touch())


func _survey(pid: String) -> void:
	var p := Lab.proposal(pid)
	var f := Lab.approve(p) if p["status"] != "approved" else G.formula(p.get("formula", ""))
	G.touch()
	Router.go("research", {"fid": f["id"], "v": 0, "fmt": p["fmt"], "conc": p["conc"]})
