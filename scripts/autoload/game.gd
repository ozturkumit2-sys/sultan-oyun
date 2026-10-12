extends Node
## World state (single source of truth) and shared helpers.
## All persistent data lives in `s` (JSON-serializable). Engines are static scripts that operate on it.

signal changed            # any state change the UI should reflect
signal week_done(report: Dictionary)
signal toast(text: String, kind: String)

const SAVE_VERSION := 3
const START_YEAR := 2027
const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var s: Dictionary = {}
var rng := RandomNumberGenerator.new()
var cache: Dictionary = {}       # derived data, never saved
var busy := false
var settings: Dictionary = {"music": 0.6, "sfx": 0.8, "autosave": true, "confirm_week": false, "haptics": true}


func has_game() -> bool:
	return not s.is_empty()


# ---------------------------------------------------------------- ids & lookups
func new_id(prefix: String) -> String:
	var n := int(s.get("next_id", 1))
	s["next_id"] = n + 1
	return "%s%d" % [prefix, n]


func pid() -> String:
	return str(s.get("player_id", "c0"))


func pc() -> Dictionary:
	return s["companies"].get(pid(), {})


func company(id: String) -> Dictionary:
	return s["companies"].get(id, {})


func brand(id: String) -> Dictionary:
	return s["brands"].get(id, {})


func product(id: String) -> Dictionary:
	return s["products"].get(id, {})


func formula(id: String) -> Dictionary:
	return s["formulas"].get(id, {})


func employee(id: String) -> Dictionary:
	return s["employees"].get(id, {})


func is_player(cid: String) -> bool:
	return cid == pid()


func company_brands(cid: String, active_only := true) -> Array:
	var out: Array = []
	for b in s["brands"].values():
		if b["company"] == cid and (not active_only or b.get("status", "active") == "active"):
			out.append(b)
	return out


func company_products(cid: String, statuses := ["active"]) -> Array:
	var out: Array = []
	for p in s["products"].values():
		if p["company"] == cid and (statuses.is_empty() or statuses.has(p["status"])):
			out.append(p)
	return out


func company_employees(cid: String, role_id := "") -> Array:
	var out: Array = []
	for e in s["employees"].values():
		if e.get("employer", "") == cid and (role_id == "" or e["role"] == role_id):
			out.append(e)
	return out


func formula_version(fid: String, v := -1) -> Dictionary:
	var f := formula(fid)
	if f.is_empty():
		return {}
	var vs: Array = f["versions"]
	if vs.is_empty():
		return {}
	if v < 0 or v >= vs.size():
		return vs[vs.size() - 1]
	return vs[v]


# ---------------------------------------------------------------- calendar
func week() -> int:
	return int(s.get("week", 0))


func year_of(w: int) -> int:
	return START_YEAR + int(w / 52)


func week_of_year(w: int) -> int:
	return w % 52 + 1


func month_of(w: int) -> int:
	return clampi(int(float(w % 52) / 52.0 * 12.0), 0, 11)


func date_str(w := -1) -> String:
	if w < 0:
		w = week()
	return "Week %d · %s %d" % [week_of_year(w), MONTHS[month_of(w)], year_of(w)]


func short_date(w: int) -> String:
	return "%s %d" % [MONTHS[month_of(w)], year_of(w)]


# ---------------------------------------------------------------- formatting
func money(v: float, decimals := -1) -> String:
	var neg := v < 0
	var a := absf(v)
	var t := ""
	if a >= 1e9:
		t = "%.2fB" % (a / 1e9)
	elif a >= 1e6:
		t = "%.2fM" % (a / 1e6)
	elif a >= 1e4:
		t = "%.1fK" % (a / 1e3)
	elif decimals >= 0:
		t = ("%." + str(decimals) + "f") % a
	elif a >= 100:
		t = group_int(int(round(a)))
	else:
		t = "%.2f" % a
	return ("-$" if neg else "$") + t


func group_int(n: int) -> String:
	var neg := n < 0
	var str_n := str(absi(n))
	var out := ""
	var cnt := 0
	for i in range(str_n.length() - 1, -1, -1):
		out = str_n[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if neg else "") + out


func pct(v: float, decimals := 0) -> String:
	return ("%." + str(decimals) + "f%%") % (v * 100.0)


# ---------------------------------------------------------------- math helpers
static func sigmoid(x: float) -> float:
	return 1.0 / (1.0 + exp(-x))


static func dot(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var t := 0.0
	for i in mini(a.size(), b.size()):
		t += a[i] * b[i]
	return t


static func vnorm(v: PackedFloat32Array) -> PackedFloat32Array:
	var t := 0.0
	for x in v:
		t += maxf(0.0, x)
	var out := PackedFloat32Array()
	out.resize(v.size())
	if t <= 0.0:
		return out
	for i in v.size():
		out[i] = maxf(0.0, v[i]) / t
	return out


static func vcos(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var ab := 0.0
	var aa := 0.0
	var bb := 0.0
	for i in mini(a.size(), b.size()):
		ab += a[i] * b[i]
		aa += a[i] * a[i]
		bb += b[i] * b[i]
	if aa <= 0.0 or bb <= 0.0:
		return 0.0
	return ab / sqrt(aa * bb)


static func to_vec(a: Variant) -> PackedFloat32Array:
	if a is PackedFloat32Array:
		return a
	return PackedFloat32Array(a if a is Array else [])


## Deterministic RNG for a player action (does not disturb the world RNG).
func drng(key: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(s.get("seed", 1)) + "|" + key)
	return r


func rand_normal(r: RandomNumberGenerator, mean := 0.0, sd := 1.0) -> float:
	return r.randfn(mean, sd)


func pick(arr: Array, r: RandomNumberGenerator = null) -> Variant:
	if arr.is_empty():
		return null
	var rr := r if r != null else rng
	return arr[rr.randi_range(0, arr.size() - 1)]


# ---------------------------------------------------------------- ingredient market
func ing_price(id: String) -> float:
	var base := float(DB.ing(id).get("cost", 0.0))
	var m: Dictionary = s.get("ing_market", {}).get(id, {})
	return base * float(m.get("idx", 1.0))


func ing_available(cid: String, id: String) -> bool:
	var rec := DB.ing(id)
	if rec.is_empty():
		return false
	if int(rec.get("tier", 0)) == 0:
		return true
	return company(cid).get("unlocked", {}).has(id)


# ---------------------------------------------------------------- notifications
func log_event(text: String, kind := "info", cid := "") -> void:
	## Player-facing news feed. Only entries relevant to the player (or world news with cid == "*").
	if cid != "" and cid != "*" and cid != pid():
		return
	var lg: Array = s["log"]
	lg.append({"w": week(), "t": text, "k": kind})
	if lg.size() > 250:
		lg.remove_at(0)


func inbox_add(item: Dictionary) -> String:
	item["id"] = new_id("m")
	item["w"] = week()
	item["done"] = false
	s["inbox"].append(item)
	return item["id"]


func inbox_open() -> Array:
	var out: Array = []
	for m in s["inbox"]:
		if not m.get("done", false):
			out.append(m)
	return out


func inbox_resolve(mid: String) -> void:
	for m in s["inbox"]:
		if m["id"] == mid:
			m["done"] = true
	var keep: Array = []
	for m in s["inbox"]:
		if not m["done"] or week() - int(m["w"]) < 26:
			keep.append(m)
	s["inbox"] = keep


func notify(text: String, kind := "info") -> void:
	toast.emit(text, kind)


func touch() -> void:
	changed.emit()


# ---------------------------------------------------------------- rng persistence
func seed_world(seed_val: int) -> void:
	s["seed"] = seed_val
	rng.seed = seed_val
	s["rng_state"] = str(rng.state)


func store_rng() -> void:
	s["rng_state"] = str(rng.state)


func restore_rng() -> void:
	rng.seed = int(s.get("seed", 1))
	var st := str(s.get("rng_state", ""))
	if st.is_valid_int():
		rng.state = st.to_int()


func clear_cache(full := true) -> void:
	if full:
		cache.clear()
		return
	# keep chemistry evaluations (pure functions of formula + format), drop market-derived data
	for k in cache.keys():
		if k != "eval" and not str(k).begins_with("pev|"):
			cache.erase(k)
