class_name FinanceEngine
extends RefCounted
## Double-entry style accounting kept consistent at all times:
## assets (cash + raw + WIP + finished goods + PP&E + goodwill) − debt == paid-in capital + retained earnings.
## Inventory values are derived from physical records (kg, units), so they can never drift from stock.

const OPEX := ["payroll", "marketing", "rnd", "distribution", "facilities", "production", "admin", "depreciation", "writeoff", "integration"]
const CAT_NAMES := {
	"revenue": "Revenue", "returns": "Returns & refunds", "cogs": "Cost of goods sold", "payroll": "Payroll",
	"marketing": "Marketing", "rnd": "Research & development", "distribution": "Distribution & fees",
	"facilities": "Facilities & offices", "production": "Production overhead", "admin": "Administration",
	"depreciation": "Depreciation", "writeoff": "Inventory write-offs", "integration": "Integration costs",
	"interest": "Interest", "other_income": "Other income", "tax": "Taxes",
}


static func new_fin(cash: float) -> Dictionary:
	return {"cash": cash, "ppe": 0.0, "goodwill": 0.0, "debt": 0.0, "paid_in": cash, "retained": 0.0,
		"tax_cf": 0.0, "wk": {}, "hist": [], "years": {}, "lifetime": {}}


static func F(c: Dictionary) -> Dictionary:
	return c["fin"]


static func cash_of(c: Dictionary) -> float:
	return float(c["fin"]["cash"])


## P&L posting (+income / −expense). Updates retained earnings immediately.
static func pl(c: Dictionary, cat: String, amount: float) -> void:
	if is_nan(amount) or is_inf(amount):
		push_error("Invalid P&L amount for " + cat)
		return
	var f: Dictionary = c["fin"]
	f["retained"] = float(f["retained"]) + amount
	var wk: Dictionary = f["wk"]
	wk[cat] = float(wk.get(cat, 0.0)) + amount


static func cash(c: Dictionary, delta: float) -> void:
	if is_nan(delta) or is_inf(delta):
		push_error("Invalid cash delta")
		return
	var f: Dictionary = c["fin"]
	f["cash"] = float(f["cash"]) + delta


static func spend(c: Dictionary, cat: String, amt: float) -> void:
	if amt == 0.0:
		return
	pl(c, cat, -amt)
	cash(c, -amt)


static func earn(c: Dictionary, cat: String, amt: float) -> void:
	if amt == 0.0:
		return
	pl(c, cat, amt)
	cash(c, amt)


static func capex(c: Dictionary, amt: float) -> void:
	cash(c, -amt)
	c["fin"]["ppe"] = float(c["fin"]["ppe"]) + amt


static func borrow(c: Dictionary, amt: float) -> void:
	cash(c, amt)
	c["fin"]["debt"] = float(c["fin"]["debt"]) + amt


static func repay(c: Dictionary, amt: float) -> void:
	cash(c, -amt)
	c["fin"]["debt"] = maxf(0.0, float(c["fin"]["debt"]) - amt)


static func raise_equity(c: Dictionary, amt: float) -> void:
	cash(c, amt)
	c["fin"]["paid_in"] = float(c["fin"]["paid_in"]) + amt


static func dividend(c: Dictionary, amt: float) -> void:
	cash(c, -amt)
	c["fin"]["retained"] = float(c["fin"]["retained"]) - amt
	var f: Dictionary = c["fin"]
	f["div_total"] = float(f.get("div_total", 0.0)) + amt


# ---------------------------------------------------------------- raw materials
static func buy_raw(c: Dictionary, ing_id: String, kg: float, total_cost: float) -> void:
	cash(c, -total_cost)
	add_raw(c, ing_id, kg, total_cost)


static func add_raw(c: Dictionary, ing_id: String, kg: float, total_value: float) -> void:
	var raw: Dictionary = c["raw"]
	var cur: Array = raw.get(ing_id, [0.0, 0.0])
	var q := float(cur[0])
	var avg := float(cur[1])
	var nq := q + kg
	var navg := (q * avg + total_value) / nq if nq > 0.0 else 0.0
	raw[ing_id] = [nq, navg]


## Removes kg from stock and returns its book value (moving average cost).
static func take_raw(c: Dictionary, ing_id: String, kg: float) -> float:
	var raw: Dictionary = c["raw"]
	var cur: Array = raw.get(ing_id, [0.0, 0.0])
	var q := float(cur[0])
	var take := minf(q, kg)
	var val := take * float(cur[1])
	var left := q - take
	if left <= 0.000001:
		raw.erase(ing_id)
	else:
		raw[ing_id] = [left, float(cur[1])]
	return val


static func raw_kg(c: Dictionary, ing_id: String) -> float:
	return float(c["raw"].get(ing_id, [0.0, 0.0])[0])


static func raw_value(c: Dictionary) -> float:
	var t := 0.0
	for k in c["raw"]:
		var a: Array = c["raw"][k]
		t += float(a[0]) * float(a[1])
	return t


static func fg_value(cid: String) -> float:
	var t := 0.0
	for p in G.s["products"].values():
		if p["company"] == cid:
			t += float(p.get("inv", 0)) * float(p.get("unit_cost", 0.0))
	return t


static func wip_value(cid: String) -> float:
	var t := 0.0
	for o in G.s["orders"]:
		if o["company"] == cid and o["stage"] != "done":
			t += float(o.get("value", 0.0))
	return t


static func assets(c: Dictionary) -> float:
	var f: Dictionary = c["fin"]
	return float(f["cash"]) + raw_value(c) + ProductionEngine.transit_value(c["id"]) + wip_value(c["id"]) + fg_value(c["id"]) + float(f["ppe"]) + float(f["goodwill"])


static func equity(c: Dictionary) -> float:
	var f: Dictionary = c["fin"]
	return float(f["paid_in"]) + float(f["retained"])


static func balance_gap(c: Dictionary) -> float:
	## Should be ~0. Non-zero means an accounting bug.
	return assets(c) - float(c["fin"]["debt"]) - equity(c)


# ---------------------------------------------------------------- weekly close
static func close_week(c: Dictionary, units: int) -> Dictionary:
	var f: Dictionary = c["fin"]
	var wk: Dictionary = f["wk"]
	var pre_tax := 0.0
	for k in wk:
		pre_tax += float(wk[k])
	# simplified corporate tax with loss carry-forward (fictional game rule)
	var rate := float(DB.country(c["home"]).get("tax", 0.25))
	var cf := float(f["tax_cf"])
	var tax := 0.0
	if pre_tax < 0.0:
		f["tax_cf"] = cf + (-pre_tax)
	else:
		var taxable := maxf(0.0, pre_tax - cf)
		f["tax_cf"] = maxf(0.0, cf - pre_tax)
		tax = taxable * rate
		if tax > 0.0:
			spend(c, "tax", tax)
	var rec := {"w": G.week(), "cash": float(f["cash"]), "debt": float(f["debt"]), "u": units}
	for k in wk:
		rec[k] = snappedf(float(wk[k]), 0.01)
	rec["net"] = snappedf(pre_tax - tax, 0.01)
	var hist: Array = f["hist"]
	hist.append(rec)
	var keep := 520 if G.is_player(c["id"]) else 156
	while hist.size() > keep:
		hist.remove_at(0)
	var y := str(G.year_of(G.week()))
	var yr: Dictionary = f["years"].get(y, {})
	for k in rec:
		if k in ["w", "cash", "debt"]:
			continue
		yr[k] = float(yr.get(k, 0.0)) + float(rec[k])
	yr["cash"] = float(f["cash"])
	yr["debt"] = float(f["debt"])
	f["years"][y] = yr
	var life: Dictionary = f["lifetime"]
	for k in wk:
		life[k] = float(life.get(k, 0.0)) + float(wk[k])
	f["wk"] = {}
	return rec


## Aggregated P&L over the last n weeks (n=0 → current open week).
static func period(c: Dictionary, n: int, offset := 0) -> Dictionary:
	var out := {}
	var hist: Array = c["fin"]["hist"]
	var end := hist.size() - offset
	var start := maxi(0, end - n)
	for i in range(start, end):
		var rec: Dictionary = hist[i]
		for k in rec:
			if k in ["w", "cash", "debt"]:
				continue
			out[k] = float(out.get(k, 0.0)) + float(rec[k])
	out["weeks"] = end - start
	return out


static func summarize(pnl: Dictionary) -> Dictionary:
	var rev := float(pnl.get("revenue", 0.0))
	var ret := float(pnl.get("returns", 0.0))
	var cogs := float(pnl.get("cogs", 0.0))
	var gp := rev + ret + cogs
	var opex := 0.0
	for k in OPEX:
		opex += float(pnl.get(k, 0.0))
	var op := gp + opex
	var dep := float(pnl.get("depreciation", 0.0))
	var pre := op + float(pnl.get("interest", 0.0)) + float(pnl.get("other_income", 0.0))
	var net := pre + float(pnl.get("tax", 0.0))
	return {"revenue": rev, "returns": ret, "cogs": cogs, "gross": gp, "opex": opex, "operating": op,
		"ebitda": op - dep, "pretax": pre, "net": net, "margin": gp / rev if rev > 0.0 else 0.0}


static func ttm(c: Dictionary) -> Dictionary:
	return summarize(period(c, 52))


static func growth(c: Dictionary) -> float:
	var a := float(period(c, 13).get("revenue", 0.0))
	var b := float(period(c, 13, 13).get("revenue", 0.0))
	if b <= 1000.0:
		return 0.5 if a > 1000.0 else 0.0
	return clampf(a / b - 1.0, -0.8, 2.0)


static func valuation(c: Dictionary) -> float:
	var t := ttm(c)
	var rev := float(t["revenue"])
	var ebitda := float(t["ebitda"])
	var g := growth(c)
	var prest := 0.0
	var bs := G.company_brands(c["id"])
	for b in bs:
		prest = maxf(prest, float(b["prestige"]))
	var ev_rev := rev * (0.9 + 1.6 * clampf(g, 0.0, 1.0) + 1.2 * prest)
	var ev_e := ebitda * (8.0 + 5.0 * clampf(g, 0.0, 1.0) + 3.0 * prest)
	var ev := maxf(ev_rev * (0.8 if ebitda > 0.0 else 0.55), ev_e)
	var f: Dictionary = c["fin"]
	var eq_book := equity(c)
	return maxf(eq_book, ev + float(f["cash"]) - float(f["debt"]))


static func credit_limit(c: Dictionary) -> float:
	var t := ttm(c)
	var base := maxf(0.0, float(t["ebitda"])) * 3.5 + maxf(0.0, assets(c) - float(c["fin"]["cash"])) * 0.5
	var fm := Staff.best_skill(c["id"], "finance_manager")
	return maxf(25000.0, base * (1.0 + 0.4 * fm))


static func base_rate(c: Dictionary) -> float:
	var t := ttm(c)
	var lev := float(c["fin"]["debt"]) / maxf(50000.0, float(t["ebitda"]) * 4.0 + 1.0)
	var fm := Staff.best_skill(c["id"], "finance_manager")
	return clampf(0.065 + 0.05 * lev - 0.015 * fm - (0.01 if c.get("public", false) else 0.0), 0.04, 0.2)


## Loans: equal weekly installments.
static func take_loan(c: Dictionary, amount: float, weeks: int, rate: float, kind := "term") -> Dictionary:
	var wr := rate / 52.0
	var pay := amount * wr / (1.0 - pow(1.0 + wr, -weeks)) if wr > 0.0 else amount / weeks
	var ln := {"id": G.new_id("L"), "company": c["id"], "principal": amount, "left": amount, "rate": rate, "weeks": weeks,
		"weeks_left": weeks, "pay": pay, "kind": kind, "start": G.week()}
	G.s["loans"].append(ln)
	borrow(c, amount)
	return ln


static func service_loans(c: Dictionary) -> void:
	var keep: Array = []
	for ln in G.s["loans"]:
		if ln["company"] != c["id"]:
			keep.append(ln)
			continue
		var left := float(ln["left"])
		var interest := left * float(ln["rate"]) / 52.0
		var principal := 0.0
		if ln["kind"] == "overdraft":
			principal = 0.0
		else:
			principal = minf(left, float(ln["pay"]) - interest)
		spend(c, "interest", interest)
		if principal > 0.0:
			repay(c, principal)
			ln["left"] = left - principal
		ln["weeks_left"] = int(ln["weeks_left"]) - 1
		if float(ln["left"]) > 0.5 and (int(ln["weeks_left"]) > 0 or ln["kind"] == "overdraft"):
			keep.append(ln)
		elif float(ln["left"]) > 0.5:
			repay(c, float(ln["left"]))
	G.s["loans"] = keep


static func company_loans(cid: String) -> Array:
	return G.s["loans"].filter(func(l): return l["company"] == cid)


## Ensures cash is not negative after the week: draws on an emergency credit line, repays it when cash allows.
static func liquidity(c: Dictionary) -> void:
	var cashv := cash_of(c)
	var od: Dictionary = {}
	for ln in G.s["loans"]:
		if ln["company"] == c["id"] and ln["kind"] == "overdraft":
			od = ln
	if cashv < 0.0:
		var need := -cashv + 5000.0
		if od.is_empty():
			od = {"id": G.new_id("L"), "company": c["id"], "principal": 0.0, "left": 0.0, "rate": 0.22, "weeks": 0,
				"weeks_left": 0, "pay": 0.0, "kind": "overdraft", "start": G.week()}
			G.s["loans"].append(od)
		od["left"] = float(od["left"]) + need
		od["principal"] = float(od["principal"]) + need
		borrow(c, need)
		if G.is_player(c["id"]):
			G.log_event("Emergency credit line drawn: %s at 22%% interest." % G.money(need), "warn")
	elif not od.is_empty() and cashv > 20000.0:
		var pay := minf(float(od["left"]), cashv - 15000.0)
		repay(c, pay)
		od["left"] = float(od["left"]) - pay
		if float(od["left"]) <= 0.5:
			G.s["loans"].erase(od)
