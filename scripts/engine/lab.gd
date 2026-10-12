class_name Lab
extends RefCounted
## Laboratory: technical tests (measured with noise that skill/equipment reduce), consumer research,
## perfumer projects (autonomous and commissioned briefs) and the proposal inbox.

const TESTS := {
	"performance": {"name": "Performance panel", "cost": 800.0, "desc": "Evaporation, longevity and projection on skin."},
	"stability": {"name": "Stability & aging", "cost": 1500.0, "desc": "Accelerated aging: oxidation, color, haze, crystals."},
	"regulatory": {"name": "Safety & labeling review", "cost": 500.0, "desc": "Checks the fictional FSC standard and allergen labeling."},
	"full": {"name": "Full technical dossier", "cost": 2500.0, "desc": "All of the above in one report."},
}


static func test_level(cid: String) -> int:
	return int(DB.hq_tier(int(G.company(cid)["hq"]["tier"]))["test"])


static func run_test(cid: String, fid: String, v: int, fmt: String, conc: float, kind: String, maturation := 0) -> Dictionary:
	var c := G.company(cid)
	var t: Dictionary = TESTS[kind]
	var cost := float(t["cost"])
	if FinanceEngine.cash_of(c) < cost:
		return {"error": "Not enough cash (%s)." % G.money(cost)}
	var fv := G.formula_version(fid, v)
	if fv.is_empty():
		return {"error": "Formula not found."}
	FinanceEngine.spend(c, "rnd", cost)
	var ev := FormulaEngine.evaluate(fv["items"], fmt, conc, {"maturation": maturation})
	var r := G.drng("test|%s|%d|%s|%s|%.1f|%d" % [fid, v, kind, fmt, conc, G.week()])
	var chem := Staff.best_skill(cid, "chemist")
	var lvl := test_level(cid) + CompanyEngine.dept_level(cid, "lab") - 1
	var sd := 0.18 * (1.0 - 0.5 * chem) * (1.25 - 0.15 * float(lvl))
	var res := {"kind": kind, "lvl": lvl, "sd": sd}
	if kind == "performance" or kind == "full":
		var f := exp(r.randfn(0.0, sd))
		res["longevity"] = float(ev["longevity"]) * f
		res["long_lo"] = res["longevity"] * exp(-1.64 * sd)
		res["long_hi"] = res["longevity"] * exp(1.64 * sd)
		res["sillage"] = float(ev["sillage"]) * exp(r.randfn(0.0, sd))
		res["projection"] = clampf(float(ev["projection"]) + r.randfn(0.0, sd * 0.4), 0.0, 1.0)
		res["intensity"] = clampf(float(ev["intensity"]) + r.randfn(0.0, sd * 0.4), 0.0, 1.0)
		var curve := []
		for x in ev["curve"]:
			curve.append(float(x) * f)
		res["curve"] = curve
		if lvl >= 2:
			var pc := []
			for x in ev["pcurve"]:
				pc.append(float(x) * f)
			res["pcurve"] = pc
		if lvl >= 3:
			res["anosmia"] = float(ev["anosmia"])
		res["notes"] = ev["notes"]
		res["family"] = ev["family"]
		res["open"] = Array(ev["open"])
		res["heart"] = Array(ev["heart"])
		res["dry"] = Array(ev["dry"])
		res["interactions"] = ev["interactions"]
	if kind == "stability" or kind == "full":
		var st: Dictionary = ev["stability"]
		var m := {}
		for k in st:
			m[k] = clampf(float(st[k]) + r.randfn(0.0, sd * 0.25), 0.0, 1.0)
		res["stability"] = m
		res["stab_label"] = FormulaEngine.stability_label(m)
	if kind == "regulatory" or kind == "full":
		res["violations"] = ev["violations"]
		res["allergens"] = ev["allergens"]
		res["natural"] = ev["natural"]
	var rec := {"id": G.new_id("t"), "company": cid, "formula": fid, "v": v, "fmt": fmt, "conc": conc, "mat": maturation, "w": G.week(), "res": res}
	G.s["tests"].append(rec)
	while G.s["tests"].size() > 120:
		G.s["tests"].remove_at(0)
	return rec


static func tests_for(fid: String) -> Array:
	return G.s["tests"].filter(func(t): return t["formula"] == fid)


static func run_survey(cid: String, spec: Dictionary, country: String, n: int, blind: bool) -> Dictionary:
	var c := G.company(cid)
	var cost := ConsumerEngine.survey_cost(n, country)
	if FinanceEngine.cash_of(c) < cost:
		return {"error": "Not enough cash (%s)." % G.money(cost)}
	FinanceEngine.spend(c, "rnd", cost)
	var key := "%s|%s|%d|%s|%d|%.0f" % [spec.get("label", ""), country, n, str(blind), G.week(), float(spec.get("price", 0))]
	var res := ConsumerEngine.survey(spec, country, n, blind, key)
	var rec := {"id": G.new_id("sv"), "company": cid, "label": spec.get("label", "Formula"), "formula": spec.get("formula", ""),
		"v": int(spec.get("v", 0)), "w": G.week(), "res": res, "spec": {"fmt": spec["fmt"], "conc": spec["conc"], "price": spec.get("price", 0), "volume": spec.get("volume", 50)}}
	G.s["surveys"].append(rec)
	while G.s["surveys"].size() > 60:
		G.s["surveys"].remove_at(0)
	return rec


# ---------------------------------------------------------------- perfumer projects
static func project_slots(cid: String) -> int:
	return int(DB.hq_tier(int(G.company(cid)["hq"]["tier"]))["slots"])


static func active_projects(cid: String) -> int:
	var n := 0
	for e in G.company_employees(cid, "perfumer"):
		if not e.get("project", {}).is_empty():
			n += 1
	return n


static func project_weeks(cid: String, e: Dictionary, base := 8.0) -> int:
	var prod := float(e.get("skills", {}).get("productivity", e["skill"]))
	var rm := Staff.best_skill(cid, "research_manager")
	var lab := CompanyEngine.dept_level(cid, "lab")
	return maxi(1, int(round(base / (0.6 + prod) * (1.0 - 0.15 * rm) * (1.0 - 0.1 * float(lab - 1)))))


static func commission(cid: String, eid: String, brief: Dictionary) -> String:
	var e := G.employee(eid)
	if e.is_empty() or e.get("employer", "") != cid or e["role"] != "perfumer":
		return "Not one of your perfumers."
	if not e.get("project", {}).is_empty() and e["project"].get("kind", "") == "brief":
		return "%s is already working on a brief." % e["name"]
	if active_projects(cid) >= project_slots(cid) and e.get("project", {}).is_empty():
		return "All %d project slots are in use. Upgrade your headquarters for more." % project_slots(cid)
	var wks := project_weeks(cid, e)
	e["project"] = {"kind": "brief", "brief": brief, "weeks_left": wks, "weeks": wks, "cost_week": 900.0, "start": G.week()}
	Staff.note(e, "Started brief: %s." % brief.get("family", "open"))
	return ""


static func weekly(c: Dictionary, rep: Dictionary) -> void:
	var cid: String = c["id"]
	if not c.get("is_player", false):
		return
	var auto: bool = c.get("lab_auto", true)
	for e in G.company_employees(cid, "perfumer"):
		if not e.get("training", {}).is_empty():
			continue
		var pj: Dictionary = e.get("project", {})
		if pj.is_empty():
			if auto and active_projects(cid) < project_slots(cid):
				var fam: String = G.pick(e["spec"]) if not e["spec"].is_empty() else str(G.pick(DB.bal["families"].keys()))
				var wks := project_weeks(cid, e, 10.0)
				e["project"] = {"kind": "auto", "brief": {"family": fam}, "weeks_left": wks, "weeks": wks, "cost_week": 500.0, "start": G.week()}
			continue
		FinanceEngine.spend(c, "rnd", float(pj.get("cost_week", 500.0)))
		pj["spent"] = float(pj.get("spent", 0.0)) + float(pj.get("cost_week", 500.0))
		pj["weeks_left"] = int(pj["weeks_left"]) - 1
		if int(pj["weeks_left"]) <= 0:
			_complete(c, e, pj, rep)
			e["project"] = {}


static func _complete(c: Dictionary, e: Dictionary, pj: Dictionary, rep: Dictionary) -> void:
	var cid: String = c["id"]
	var brief: Dictionary = pj["brief"]
	var fam: String = brief.get("family", "Floral Bouquet")
	var target := PerfumerAI.family_target(fam).duplicate()
	var dir: String = brief.get("direction", "")
	match dir:
		"fresher":
			target["citrus"] = float(target.get("citrus", 0.0)) + 0.5
		"sweeter":
			target["gourmand"] = float(target.get("gourmand", 0.0)) + 0.5
		"woodier":
			target["woody"] = float(target.get("woody", 0.0)) + 0.5
	var avail: Array = []
	for id in DB.ing_order:
		if G.ing_available(cid, id):
			avail.append(id)
	var lb := brief.duplicate()
	lb["target"] = target
	if dir == "longer":
		lb["longevity_min"] = float(brief.get("longevity_min", 6.0)) + 3.0
	if dir == "cheaper":
		lb["cost_kg_max"] = float(brief.get("cost_kg_max", 150.0)) * 0.6
	var skills: Dictionary = e["skills"].duplicate()
	if dir == "cheaper":
		skills["cost"] = 0.95
	var r := G.rng
	var gen := PerfumerAI.generate(lb, skills, avail, r)
	if gen.is_empty():
		return
	var ev: Dictionary = gen["ev"]
	var notes: Array = []
	var met := true
	if G.vcos(ev["profile"], PerfumerAI.target_vec(PerfumerAI.family_target(fam))) < 0.75:
		met = false
		notes.append("Drifted away from the %s family." % fam)
	if brief.has("cost_kg_max") and float(ev["cost_kg"]) > float(brief["cost_kg_max"]):
		met = false
		notes.append("Concentrate cost %s/kg is above the %s/kg target." % [G.money(float(ev["cost_kg"])), G.money(float(brief["cost_kg_max"]))])
	if brief.has("longevity_min") and float(ev["longevity"]) < float(brief["longevity_min"]):
		met = false
		notes.append("Longevity likely below the requested %.0fh." % float(brief["longevity_min"]))
	if not ev["violations"].is_empty():
		met = false
		notes.append("Exceeds an FSC concentration limit; needs adjustment before launch.")
	var tech := float(e["skills"].get("technique", 0.5))
	var est_long := float(ev["longevity"]) * exp(r.randfn(0.0, 0.25 * (1.0 - tech)))
	var aud: String = brief.get("audience", WorldGen.audience_for(ev["profile"], r))
	var nm := PerfumerAI.name_for(ev, r)
	var prop := {"id": G.new_id("pp"), "company": cid, "perfumer": e["id"], "items": gen["items"], "fmt": gen["fmt"], "conc": gen["conc"],
		"name": nm, "concept": PerfumerAI.concept_line(ev, ev["family"], r), "family": ev["family"], "audience": aud,
		"est_cost_kg": float(ev["cost_kg"]), "est_long": est_long, "dev_cost": float(pj.get("spent", 0.0)), "brief": brief if pj["kind"] == "brief" else {},
		"met": met, "notes": notes, "status": "open", "w": G.week(), "kind": pj["kind"], "parent": brief.get("parent", "")}
	G.s["proposals"].append(prop)
	while G.s["proposals"].size() > 80:
		var removed := false
		for i in G.s["proposals"].size():
			if G.s["proposals"][i]["status"] != "open":
				G.s["proposals"].remove_at(i)
				removed = true
				break
		if not removed:
			break
	Staff.note(e, "Submitted proposal \"%s\"." % nm)
	rep["events"].append("%s submitted a proposal: %s" % [e["name"], nm])
	G.log_event("%s submitted a new formula proposal: %s (%s)." % [e["name"], nm, ev["family"]], "good")


static func proposal(pid: String) -> Dictionary:
	for p in G.s["proposals"]:
		if p["id"] == pid:
			return p
	return {}


static func approve(prop: Dictionary) -> Dictionary:
	var e := G.employee(prop["perfumer"])
	var f := CompanyEngine.make_formula(prop["company"], prop["name"], prop["items"], prop["perfumer"], "Proposal by " + e.get("name", "perfumer"))
	f["fmt"] = prop["fmt"]
	f["conc"] = prop["conc"]
	f["audience"] = prop["audience"]
	prop["status"] = "approved"
	prop["formula"] = f["id"]
	if not e.is_empty():
		e["motivation"] = clampf(float(e["motivation"]) + 0.06, 0.0, 1.0)
		e["formulas"] = int(e.get("formulas", 0)) + 1
		Staff.note(e, "Proposal \"%s\" approved for development." % prop["name"])
	return f


static func reject(prop: Dictionary) -> void:
	prop["status"] = "rejected"
	var e := G.employee(prop["perfumer"])
	if not e.is_empty():
		e["motivation"] = clampf(float(e["motivation"]) - 0.04, 0.0, 1.0)


static func request_revision(prop: Dictionary, direction: String) -> String:
	var e := G.employee(prop["perfumer"])
	if e.is_empty() or e.get("employer", "") != prop["company"]:
		return "The perfumer is no longer with you."
	if not e.get("project", {}).is_empty() and e["project"].get("kind", "") == "brief":
		return "%s is busy with another brief." % e["name"]
	var brief: Dictionary = prop.get("brief", {}).duplicate()
	if brief.is_empty():
		brief = {"family": prop["family"] if DB.bal["families"].has(prop["family"]) else str(G.pick(e["spec"]))}
	brief["direction"] = direction
	brief["parent"] = prop["id"]
	brief["fmt"] = prop["fmt"]
	brief["audience"] = prop["audience"]
	var wks := maxi(1, int(project_weeks(prop["company"], e) / 3))
	e["project"] = {"kind": "brief", "brief": brief, "weeks_left": wks, "weeks": wks, "cost_week": 700.0, "start": G.week()}
	prop["status"] = "revising"
	return ""
