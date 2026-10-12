extends Node
## Versioned local saves with atomic writes, a backup copy and safe handling of corrupted files.

const DIR := "user://saves"
const SLOTS := ["auto", "slot1", "slot2", "slot3"]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_load_settings()


func path(slot: String) -> String:
	return "%s/%s.json" % [DIR, slot]


func save_game(slot := "auto") -> bool:
	if not G.has_game():
		return false
	G.store_rng()
	G.s["version"] = G.SAVE_VERSION
	G.s["saved_at"] = Time.get_datetime_string_from_system()
	var txt := JSON.stringify(G.s)
	var p := path(slot)
	var tmp := p + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: " + tmp)
		return false
	f.store_string(txt)
	f.close()
	if FileAccess.file_exists(p):
		DirAccess.rename_absolute(p, p + ".bak")
	var err := DirAccess.rename_absolute(tmp, p)
	# small sidecar with the slot summary so the save/load screen does not parse whole saves
	var c := G.pc()
	var mf := FileAccess.open(p + ".meta", FileAccess.WRITE)
	if mf != null:
		mf.store_string(JSON.stringify({"company": c.get("name", "?"), "week": G.week(), "saved": G.s["saved_at"],
			"cash": float(c.get("fin", {}).get("cash", 0.0)), "version": G.SAVE_VERSION}))
		mf.close()
	return err == OK


func info(slot: String) -> Dictionary:
	var p := path(slot)
	if not FileAccess.file_exists(p):
		return {}
	if FileAccess.file_exists(p + ".meta"):
		var mf := FileAccess.open(p + ".meta", FileAccess.READ)
		if mf != null:
			var md: Variant = JSON.parse_string(mf.get_as_text())
			if md is Dictionary and md.has("week"):
				return md
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var head := f.get_as_text()
	var d: Variant = JSON.parse_string(head)
	if not d is Dictionary:
		return {"corrupt": true}
	var c: Dictionary = d.get("companies", {}).get(str(d.get("player_id", "c0")), {})
	return {"company": c.get("name", "?"), "week": int(d.get("week", 0)), "saved": d.get("saved_at", ""),
		"cash": float(c.get("fin", {}).get("cash", 0.0)), "version": int(d.get("version", 0))}


func load_game(slot: String) -> String:
	var res := _read(path(slot))
	if res.is_empty():
		res = _read(path(slot) + ".bak")
		if res.is_empty():
			return "The save file could not be read."
	var v := int(res.get("version", 0))
	if v > G.SAVE_VERSION:
		return "This save was made with a newer version of the game."
	DB.load_all()
	G.clear_cache()
	G.s = _migrate(res, v)
	_repair(G.s)
	G.restore_rng()
	Events.apply_regs()
	return ""


func _read(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary and d.has("companies") and d.has("week"):
		return d
	return {}


func _migrate(d: Dictionary, v: int) -> Dictionary:
	# Older versions: fill in containers that did not exist yet.
	var sk := WorldGen.skeleton()
	for k in sk:
		if not d.has(k):
			d[k] = sk[k]
	d["version"] = G.SAVE_VERSION
	return d


func _repair(d: Dictionary) -> void:
	## JSON turns ints into floats and may lose packed arrays; normalize the hot fields.
	d["week"] = int(d["week"])
	d["next_id"] = int(d["next_id"])
	for p in d["products"].values():
		p["inv"] = maxi(0, int(p.get("inv", 0)))
		p["fv"] = int(p.get("fv", 0))
		p["launch_week"] = int(p.get("launch_week", -1))
		for k in ["wk", "reviews", "critics", "log", "tags", "awards", "campaigns", "markets", "set"]:
			if not p.has(k):
				p[k] = []
		if not p.has("mk"):
			p["mk"] = {}
	for c in d["companies"].values():
		for k in ["raw", "unlocked", "qualifying", "offices", "delegation", "factory", "stats", "ai"]:
			if not c.has(k):
				c[k] = {}
		c["hq"]["tier"] = int(c["hq"]["tier"])
		var fin: Dictionary = c["fin"]
		for k in ["cash", "ppe", "goodwill", "debt", "paid_in", "retained"]:
			var x := float(fin.get(k, 0.0))
			fin[k] = 0.0 if is_nan(x) or is_inf(x) else x
	for e in d["employees"].values():
		e["contract_end"] = int(e.get("contract_end", -1))
		e["title"] = int(e.get("title", 1))


func delete_slot(slot: String) -> void:
	for suffix in ["", ".bak", ".meta"]:
		if FileAccess.file_exists(path(slot) + suffix):
			DirAccess.remove_absolute(path(slot) + suffix)


func save_settings() -> void:
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(G.settings))


func _load_settings() -> void:
	if not FileAccess.file_exists("user://settings.json"):
		return
	var f := FileAccess.open("user://settings.json", FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for k in d:
			G.settings[k] = d[k]
