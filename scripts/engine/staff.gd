class_name Staff
extends RefCounted
## Employees, recruitment, contracts, motivation, training, departures and transfers.
## Skills feed real effects through best_skill()/dept_power() used by the other engines.

const PERFUMER_SKILLS := ["creativity", "technique", "cost", "productivity"]


static func make_person(role_id: String, r: RandomNumberGenerator, level: float, nat := "") -> Dictionary:
	var pools: Dictionary = DB.names["people"]
	if nat == "" or not pools.has(nat):
		nat = pools.keys()[r.randi_range(0, pools.size() - 1)]
	var pool: Dictionary = pools[nat]
	var fem := r.randf() < 0.5
	var first: String = G.pick(pool["f"] if fem else pool["m"], r)
	var last: String = G.pick(pool["l"], r)
	var taken := {}
	for x in G.s.get("employees", {}).values():
		taken[x["name"]] = true
	for tries in 10:
		if not taken.has("%s %s" % [first, last]):
			break
		first = G.pick(pool["f"] if fem else pool["m"], r)
		last = G.pick(pool["l"], r)
	var sk := clampf(level + r.randfn(0.0, 0.12), 0.08, 0.98)
	var e := {
		"id": G.new_id("e"), "name": "%s %s" % [first, last], "fem": fem, "nat": nat, "role": role_id,
		"skill": sk, "skills": {}, "exp": clampi(int(2 + sk * 18 + r.randi_range(-3, 4)), 1, 35),
		"motivation": clampf(0.65 + r.randfn(0.0, 0.1), 0.3, 0.95), "loyalty": clampf(0.5 + r.randfn(0.0, 0.15), 0.1, 0.95),
		"reputation": clampf(sk * 0.8 + r.randfn(0.0, 0.1), 0.02, 0.99), "employer": "", "contract_end": -1,
		"hired": -1, "salary": 0.0, "title": 1, "spec": [], "history": [], "training": {}, "country": "",
		"project": {}, "status": "candidate", "formulas": 0, "launches": 0,
	}
	if role_id == "perfumer":
		var sks := {}
		for k in PERFUMER_SKILLS:
			sks[k] = clampf(sk + r.randfn(0.0, 0.15), 0.05, 0.99)
		e["skills"] = sks
		var fams: Array = DB.bal["families"].keys()
		e["spec"] = [fams[r.randi_range(0, fams.size() - 1)], fams[r.randi_range(0, fams.size() - 1)]]
		if e["spec"][0] == e["spec"][1]:
			e["spec"].pop_back()
	e["salary"] = market_value(e)
	return e


static func market_value(e: Dictionary) -> float:
	var rr: Dictionary = DB.role(e["role"])
	var lo := float(rr["salary"][0])
	var hi := float(rr["salary"][1])
	var v := lo + (hi - lo) * (0.7 * pow(float(e["skill"]), 1.3) + 0.3 * float(e["reputation"]))
	v *= 1.0 + 0.08 * (int(e.get("title", 1)) - 1)
	return snappedf(v, 500.0)


static func perfumer_skill(e: Dictionary) -> float:
	var s: Dictionary = e.get("skills", {})
	if s.is_empty():
		return float(e["skill"])
	return 0.4 * float(s["technique"]) + 0.35 * float(s["creativity"]) + 0.25 * float(s["productivity"])


static func eff(e: Dictionary) -> float:
	## Effective skill including motivation.
	return float(e["skill"]) * (0.7 + 0.3 * float(e["motivation"]))


static func best_skill(cid: String, role_id: String) -> float:
	var best := 0.0
	for e in G.s["employees"].values():
		if e.get("employer", "") == cid and e["role"] == role_id and e.get("training", {}).is_empty():
			best = maxf(best, eff(e))
	return best


static func count(cid: String, role_id := "") -> int:
	var n := 0
	for e in G.s["employees"].values():
		if e.get("employer", "") == cid and (role_id == "" or e["role"] == role_id):
			n += 1
	return n


static func capacity(c: Dictionary) -> int:
	return int(DB.hq_tier(int(c["hq"]["tier"]))["cap"])


static func payroll_week(cid: String) -> float:
	var t := 0.0
	for e in G.s["employees"].values():
		if e.get("employer", "") == cid:
			t += float(e["salary"]) / 52.0
	return t


static func note(e: Dictionary, text: String) -> void:
	var h: Array = e["history"]
	h.append([G.week(), text])
	if h.size() > 30:
		h.remove_at(0)


# ---------------------------------------------------------------- recruitment
static func refresh_candidates(force := false) -> void:
	var w := G.week()
	if not force and w - int(G.s.get("cand_week", -99)) < 4:
		return
	G.s["cand_week"] = w
	for id in G.s["candidates"].duplicate():
		var e := G.employee(id)
		if not e.is_empty() and e.get("employer", "") == "":
			G.s["employees"].erase(id)
	G.s["candidates"] = []
	var c := G.pc()
	var r := G.rng
	var tier := int(c["hq"]["tier"])
	var rep := float(c.get("reputation", 0.3))
	var base := 0.32 + 0.08 * tier + 0.15 * rep
	var roles := ["perfumer", "perfumer", "perfumer", "chemist", "chemist", "research_manager", "production_manager", "marketing_manager", "sales_manager", "finance_manager", "hr_manager", "country_manager", "executive_manager"]
	var n := 9 + tier * 2
	for i in n:
		var rid: String = roles[r.randi_range(0, roles.size() - 1)]
		var e := make_person(rid, r, base + r.randf_range(-0.12, 0.15))
		e["salary"] = market_value(e)
		G.s["employees"][e["id"]] = e
		G.s["candidates"].append(e["id"])


static func hire_fee(cid: String, e: Dictionary) -> float:
	var hr := best_skill(cid, "hr_manager")
	return float(e["salary"]) * (0.15 - 0.07 * hr)


## Returns "" on success or a reason string.
static func hire(cid: String, eid: String, salary: float, years: int) -> String:
	var c := G.company(cid)
	var e := G.employee(eid)
	if e.is_empty() or e.get("employer", "") != "":
		return "No longer available."
	if count(cid) >= capacity(c):
		return "Headquarters at capacity (%d staff). Upgrade your headquarters." % capacity(c)
	var ask := market_value(e)
	var need := ask * (1.0 - 0.06 * float(e["motivation"]))
	if salary < need:
		var r := G.drng("hire|%s|%d|%d" % [eid, G.week(), int(salary)])
		var p := clampf(1.0 - (need - salary) / need * 6.0, 0.0, 1.0)
		if r.randf() > p:
			return "%s declined. They expect about %s per year." % [e["name"], G.money(ask)]
	var fee := hire_fee(cid, e)
	if FinanceEngine.cash_of(c) < fee:
		return "Not enough cash for the recruitment fee (%s)." % G.money(fee)
	FinanceEngine.spend(c, "admin", fee)
	e["salary"] = salary
	e["employer"] = cid
	e["status"] = "active"
	e["hired"] = G.week()
	e["contract_end"] = G.week() + years * 52
	e["motivation"] = clampf(float(e["motivation"]) + (salary / ask - 1.0) * 0.5 + 0.05, 0.2, 1.0)
	G.s["candidates"].erase(eid)
	note(e, "Joined %s as %s." % [c["name"], DB.role(e["role"])["name"]])
	if G.is_player(cid):
		G.log_event("%s joined as %s." % [e["name"], DB.role(e["role"])["name"]], "good")
	return ""


static func dismiss(cid: String, eid: String) -> void:
	var c := G.company(cid)
	var e := G.employee(eid)
	if e.is_empty() or e.get("employer", "") != cid:
		return
	var sev := float(e["salary"]) / 52.0 * 8.0
	FinanceEngine.spend(c, "payroll", sev)
	_release(e, "Dismissed by %s." % c["name"])
	for o in G.company_employees(cid):
		o["motivation"] = clampf(float(o["motivation"]) - 0.03, 0.0, 1.0)
	if G.is_player(cid):
		G.log_event("%s left the company (severance %s)." % [e["name"], G.money(sev)], "info")


static func _release(e: Dictionary, why: String) -> void:
	note(e, why)
	e["employer"] = ""
	e["status"] = "free"
	e["project"] = {}
	e["country"] = ""
	for c in G.s["companies"].values():
		for cc in c.get("offices", {}).values():
			if cc.get("manager", "") == e["id"]:
				cc["manager"] = ""


static func train(cid: String, eid: String) -> String:
	var c := G.company(cid)
	var e := G.employee(eid)
	if not e.get("training", {}).is_empty():
		return "Already in training."
	var cost := 3000.0 + float(e["salary"]) * 0.06
	if FinanceEngine.cash_of(c) < cost:
		return "Not enough cash (%s)." % G.money(cost)
	FinanceEngine.spend(c, "admin", cost)
	var gain := (1.0 - float(e["skill"])) * 0.12 * (1.0 + 0.5 * best_skill(cid, "hr_manager"))
	e["training"] = {"weeks": 4, "gain": gain}
	e["motivation"] = clampf(float(e["motivation"]) + 0.06, 0.0, 1.0)
	note(e, "Started a 4-week training program.")
	return ""


static func promote(cid: String, eid: String) -> String:
	var e := G.employee(eid)
	if int(e["title"]) >= 3:
		return "Already at the highest title."
	e["title"] = int(e["title"]) + 1
	e["salary"] = snappedf(float(e["salary"]) * 1.12, 500.0)
	e["motivation"] = clampf(float(e["motivation"]) + 0.15, 0.0, 1.0)
	e["loyalty"] = clampf(float(e["loyalty"]) + 0.06, 0.0, 1.0)
	note(e, "Promoted to %s." % title_name(e))
	return ""


static func title_name(e: Dictionary) -> String:
	var r: String = DB.role(e["role"])["name"]
	match int(e.get("title", 1)):
		2:
			return "Senior " + r
		3:
			return ("Master " if e["role"] == "perfumer" else "Head ") + r
	return r


static func raise_salary(cid: String, eid: String, new_salary: float) -> void:
	var e := G.employee(eid)
	var old := float(e["salary"])
	e["salary"] = new_salary
	e["motivation"] = clampf(float(e["motivation"]) + clampf((new_salary / old - 1.0) * 1.5, -0.3, 0.25), 0.0, 1.0)
	note(e, "Salary changed to %s." % G.money(new_salary))


static func renew(cid: String, eid: String, salary: float, years: int) -> String:
	var e := G.employee(eid)
	var ask := market_value(e) * (1.05 - 0.15 * float(e["loyalty"]))
	if salary < ask * 0.97:
		return "%s wants at least %s per year to renew." % [e["name"], G.money(ask)]
	raise_salary(cid, eid, salary)
	e["contract_end"] = G.week() + years * 52
	e["loyalty"] = clampf(float(e["loyalty"]) + 0.04, 0.0, 1.0)
	note(e, "Renewed contract for %d years." % years)
	return ""


# ---------------------------------------------------------------- weekly
static func weekly(c: Dictionary) -> void:
	var cid: String = c["id"]
	var payroll := payroll_week(cid)
	FinanceEngine.spend(c, "payroll", payroll)
	if not G.is_player(cid):
		return
	var r := G.rng
	var rep := float(c.get("reputation", 0.3))
	var hr := best_skill(cid, "hr_manager")
	var crowd := -0.2 if count(cid) > capacity(c) else 0.0
	for e in G.company_employees(cid):
		var tr: Dictionary = e.get("training", {})
		if not tr.is_empty():
			tr["weeks"] = int(tr["weeks"]) - 1
			if int(tr["weeks"]) <= 0:
				e["skill"] = clampf(float(e["skill"]) + float(tr["gain"]), 0.0, 0.99)
				if e["role"] == "perfumer":
					for k in e["skills"]:
						e["skills"][k] = clampf(float(e["skills"][k]) + float(tr["gain"]) * 0.8, 0.0, 0.99)
				e["training"] = {}
				note(e, "Completed training (+%d skill)." % int(round(float(tr["gain"]) * 100)))
				G.log_event("%s completed training." % e["name"], "good")
		# experience slowly raises skill
		if r.randf() < 0.02:
			e["skill"] = clampf(float(e["skill"]) + 0.01 * (1.0 - float(e["skill"])), 0.0, 0.99)
		var value := market_value(e)
		var target := 0.55 + clampf((float(e["salary"]) / value - 1.0) * 0.8, -0.35, 0.25) + 0.12 * (rep - 0.3) + 0.1 * hr + crowd
		e["motivation"] = clampf(lerpf(float(e["motivation"]), target, 0.06), 0.0, 1.0)
		# contract expiry
		var ce := int(e["contract_end"])
		if ce - G.week() == 4:
			G.inbox_add({"type": "contract", "emp": e["id"], "title": "Contract expiring: " + e["name"],
				"text": "%s's contract ends in 4 weeks. Renew or let it expire." % e["name"]})
		if ce >= 0 and G.week() >= ce:
			_release(e, "Contract with %s expired." % c["name"])
			G.log_event("%s's contract expired and they left." % e["name"], "warn")
			continue
		# resignation from low motivation
		if float(e["motivation"]) < 0.3 and r.randf() < 0.04 * (1.0 - float(e["loyalty"])) * (1.0 - 0.5 * hr):
			_release(e, "Resigned from %s." % c["name"])
			G.log_event("%s resigned (low motivation)." % e["name"], "bad")


## A rival tries to poach a strong, under-motivated player employee.
static func rival_poach(r: RandomNumberGenerator) -> void:
	var cid := G.pid()
	var best: Dictionary = {}
	var bestv := 0.0
	for e in G.company_employees(cid):
		var v := float(e["skill"]) * (1.2 - float(e["motivation"])) * (1.1 - float(e["loyalty"]))
		if v > bestv:
			bestv = v
			best = e
	if best.is_empty() or bestv < 0.25 or r.randf() > 0.12 * bestv:
		return
	var rivals: Array = []
	for c in G.s["companies"].values():
		if not c.get("is_player", false) and c.get("active", true) and FinanceEngine.cash_of(c) > 500000.0:
			rivals.append(c)
	if rivals.is_empty():
		return
	var rc: Dictionary = G.pick(rivals, r)
	var offer := snappedf(maxf(market_value(best), float(best["salary"])) * r.randf_range(1.15, 1.4), 1000.0)
	G.inbox_add({"type": "poach", "emp": best["id"], "rival": rc["id"], "offer": offer,
		"title": "%s approaches %s" % [rc["name"], best["name"]],
		"text": "%s offered %s %s per year (currently %s). Counter-offer or let them go?" % [rc["name"], best["name"], G.money(offer), G.money(float(best["salary"]))]})


static func resolve_poach(mid: String, counter: bool) -> String:
	var m: Dictionary = {}
	for x in G.s["inbox"]:
		if x["id"] == mid:
			m = x
	if m.is_empty():
		return ""
	var e := G.employee(m["emp"])
	G.inbox_resolve(mid)
	if e.is_empty() or e.get("employer", "") != G.pid():
		return "They are no longer with you."
	var offer := float(m["offer"])
	if counter:
		raise_salary(G.pid(), e["id"], offer * 1.02)
		e["loyalty"] = clampf(float(e["loyalty"]) + 0.08, 0.0, 1.0)
		e["contract_end"] = maxi(int(e["contract_end"]), G.week() + 104)
		return "%s stays with a new salary of %s." % [e["name"], G.money(offer * 1.02)]
	var rc := G.company(m["rival"])
	transfer(e, rc["id"], offer, 3)
	return "%s joined %s." % [e["name"], rc["name"]]


static func transfer(e: Dictionary, to_cid: String, salary: float, years: int) -> void:
	var from := str(e.get("employer", ""))
	_release(e, "Left %s." % (G.company(from).get("name", "the market") if from != "" else "the market"))
	e["employer"] = to_cid
	e["status"] = "active"
	e["salary"] = salary
	e["hired"] = G.week()
	e["contract_end"] = G.week() + years * 52
	e["motivation"] = clampf(float(e["motivation"]) + 0.15, 0.0, 1.0)
	note(e, "Joined %s." % G.company(to_cid)["name"])


## Transfer negotiation for a rival's perfumer. Returns {ok, msg, ask}
static func approach(e: Dictionary, salary: float, bonus: float) -> Dictionary:
	var c := G.pc()
	var from := G.company(e.get("employer", ""))
	var cur := float(e["salary"])
	var left_weeks := maxi(0, int(e["contract_end"]) - G.week())
	var buyout := cur / 52.0 * minf(float(left_weeks), 104.0) * 0.5
	var tier_gap := float(int(c["hq"]["tier"]) - int(from.get("hq", {}).get("tier", 2))) * 0.06
	var prest := float(c.get("reputation", 0.3)) - float(from.get("reputation", 0.5))
	var pull := (salary + bonus / 2.0) / cur - 1.0 + tier_gap + prest * 0.4 + (0.6 - float(e["motivation"])) * 0.5
	var need := 0.12 + 0.35 * float(e["loyalty"])
	var ask := cur * (1.0 + need - tier_gap - prest * 0.4 - (0.6 - float(e["motivation"])) * 0.5) - bonus / 2.0
	if count(c["id"]) >= capacity(c):
		return {"ok": false, "msg": "Your headquarters is at staff capacity.", "ask": ask}
	if pull < need:
		return {"ok": false, "msg": "%s is not convinced. Counter-demand: about %s per year (with your bonus)." % [e["name"], G.money(maxf(ask, cur))], "ask": ask}
	var total := bonus + buyout
	if FinanceEngine.cash_of(c) < total:
		return {"ok": false, "msg": "Signing bonus plus contract buyout (%s) exceeds your cash." % G.money(total), "ask": ask}
	FinanceEngine.spend(c, "admin", total)
	if not from.is_empty():
		FinanceEngine.earn(from, "other_income", buyout)
	transfer(e, c["id"], salary, 3)
	G.log_event("%s joined from %s (bonus %s, buyout %s)." % [e["name"], from.get("name", "?"), G.money(bonus), G.money(buyout)], "good")
	return {"ok": true, "msg": "%s accepted and joins your company." % e["name"], "ask": ask}
