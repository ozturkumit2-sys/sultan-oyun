class_name Tutorial
extends RefCounted
## Guided first launch: formula → (optional) lab test → launch & first batch → first sales.

const STEPS := [
	["Create your first formula", "Open the Lab and compose a fragrance concentrate. Start from a classic structure if you like — every percentage is yours to change.", "lab"],
	["Test it (optional)", "Run a performance panel to see longevity and projection, or skip ahead and trust your nose.", "lab"],
	["Launch your first perfume", "Design the bottle, set the price and order a first production batch from a contract manufacturer.", "lab"],
	["Produce the first batch", "Tap Next Week. Contract filling takes a week or two; your perfume launches the moment stock arrives.", "week"],
	["Watch your first sales", "Advance a week to see customers react. Then keep building your house!", "week"],
]


static func step() -> int:
	return int(G.s.get("tutorial", {}).get("step", 0))


static func done() -> bool:
	return G.s.get("tutorial", {}).get("done", false)


static func check() -> void:
	if not G.has_game() or done():
		return
	var t: Dictionary = G.s["tutorial"]
	var st := int(t["step"])
	var cid := G.pid()
	var forms = G.s["formulas"].values().filter(func(f): return f["company"] == cid)
	var prods := G.company_products(cid, ["dev", "active", "discontinued"])
	var sold := false
	for p in prods:
		if int(p["st"]["units"]) > 0:
			sold = true
	if st == 0 and not forms.is_empty():
		st = 1
	if st == 1 and (not G.s["tests"].is_empty() or not prods.is_empty()):
		st = 2
	if st == 2 and not prods.is_empty():
		var ordered := false
		for o in G.s["orders"]:
			if o["company"] == cid:
				ordered = true
		for p in prods:
			if p["status"] == "active":
				ordered = true
		if ordered:
			st = 3
	if st == 3:
		for p in prods:
			if p["status"] == "active":
				st = 4
	if st == 4 and sold:
		t["done"] = true
		G.inbox_add({"type": "info", "title": "Your first sales!", "text": "Customers are buying your fragrance. Watch reviews, keep stock flowing, hire a perfumer, and grow your house. Tip: the weekly report shows what drove the results."})
	t["step"] = st


static func skip_test() -> void:
	if step() == 1:
		G.s["tutorial"]["step"] = 2


static func after_week(_rep: Dictionary) -> void:
	check()
