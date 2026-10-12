extends Node
## Static game data loaded from editable JSON files in res://data.
## Nothing here changes during play; all mutable world state lives in G.s.

var dims: PackedStringArray = []
var ingredients: Dictionary = {}      # id -> record
var ing_order: Array = []             # ids in catalog order
var segments: Array = []
var seg_index: Dictionary = {}
var countries: Array = []
var country_by_id: Dictionary = {}
var month_demand: Array = []
var label_matrix: Dictionary = {}
var biz: Dictionary = {}
var names: Dictionary = {}
var rivals: Array = []
var bal: Dictionary = {}
var texts: Dictionary = {}
var world_map: Dictionary = {}

var formats: Dictionary = {}
var packaging: Dictionary = {}
var positionings: Dictionary = {}
var channels: Dictionary = {}
var campaigns: Dictionary = {}
var manufacturers: Dictionary = {}


func _ready() -> void:
	load_all()


func _json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Missing data file: " + path)
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	if v == null:
		push_error("Invalid JSON: " + path)
		return {}
	return v


func load_all() -> void:
	var ing: Dictionary = _json("res://data/ingredients.json")
	dims = PackedStringArray(ing.get("dims", []))
	ingredients.clear()
	ing_order.clear()
	for r in ing.get("ingredients", []):
		var rec: Dictionary = r
		var v := PackedFloat32Array()
		v.resize(dims.size())
		var od: Dictionary = rec.get("odor", {})
		for i in dims.size():
			v[i] = float(od.get(dims[i], 0.0))
		rec["vec"] = v
		ingredients[rec["id"]] = rec
		ing_order.append(rec["id"])
	var m: Dictionary = _json("res://data/markets.json")
	segments = m.get("segments", [])
	for i in segments.size():
		var s: Dictionary = segments[i]
		s["idx"] = i
		s["pref"] = PackedFloat32Array(s["pref"])
		seg_index[s["id"]] = i
	countries = m.get("countries", [])
	for c in countries:
		c["trend"] = PackedFloat32Array(c["trend"])
		country_by_id[c["id"]] = c
	month_demand = m.get("month_demand", [])
	label_matrix = m.get("labels", {})
	biz = _json("res://data/business.json")
	for f in biz["formats"]:
		formats[f["id"]] = f
	for p in biz["packaging"]:
		packaging[p["id"]] = p
	for p in biz["positionings"]:
		positionings[p["id"]] = p
	for c in biz["channels"]:
		channels[c["id"]] = c
	for c in biz["campaigns"]:
		campaigns[c["id"]] = c
	for mf in biz["manufacturers"]:
		manufacturers[mf["id"]] = mf
	names = _json("res://data/names.json")
	rivals = _json("res://data/competitors.json").get("rivals", [])
	bal = _json("res://data/balance.json")
	texts = _json("res://data/texts.json")
	world_map = _json("res://data/world_map.json")


func ing(id: String) -> Dictionary:
	return ingredients.get(id, {})


func country(id: String) -> Dictionary:
	return country_by_id.get(id, {})


func b(section: String, key: String, def: Variant = 0.0) -> Variant:
	## Balance coefficient lookup: DB.b("perf", "skin_k")
	var sec: Dictionary = bal.get(section, {})
	return sec.get(key, def)


func hq_tier(t: int) -> Dictionary:
	for h in biz["hq"]:
		if int(h["tier"]) == t:
			return h
	return biz["hq"][0]


func role(id: String) -> Dictionary:
	return biz["roles"].get(id, {})


func dim_index(d: String) -> int:
	return dims.find(d)
