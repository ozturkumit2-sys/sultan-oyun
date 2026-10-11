extends Node
## SaveManager — sürümlü, doğrulanan ve atomik yazılan yerel kayıt sistemi.
## Kayıt user://save.json'da tutulur; her başarılı yazımdan önce eski dosya save.bak olarak saklanır.

signal saved
signal loaded

const SAVE_VERSION := 1
const SAVE_PATH := "user://save.json"
const TMP_PATH := "user://save.tmp"
const BAK_PATH := "user://save.bak"

var data: Dictionary = {}
var _dirty := false
var _save_timer := 0.0
var last_error := ""
var loaded_from := "defaults"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


func _process(delta: float) -> void:
	if _dirty:
		_save_timer -= delta
		if _save_timer <= 0.0:
			save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if _dirty:
			save_now()


static func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"created": int(Time.get_unix_time_from_system()),
		"profile": {"name": "Şef", "created": false},
		"chef": {"skin": 1, "hair": "short", "hair_color": 1, "expression": "happy", "hat": "toque",
			"jacket": "white", "apron": "classic", "accessory": "none", "assistant": ""},
		"coins": 150,
		"xp": 0,
		"level": 1,
		"skill_points": 0,
		"specs": {"fusion": 0, "defender": 0, "artist": 0, "chaos": 0},
		"owned": {"hair": [], "expression": [], "hat": [], "jacket": [], "apron": [], "accessory": [],
			"plates": [], "garnishes": [], "decor": []},
		"decor": "classic",
		"ingredients": [],
		"recipes": {},
		"generic_reg": {},
		"hints_bought": [],
		"career": {"matches": {}, "leagues_done": []},
		"achievements": [],
		"secrets": [],
		"mutations_seen": [],
		"stats": {"wins": 0, "losses": 0, "living_caught": 0, "backfires": 0, "fusions": 0, "dishes": 0,
			"coins_earned": 0, "perfect_cooks": 0, "defended": 0, "matches": 0, "best_round": 0.0},
		"daily": {"date": "", "best": 0.0, "claimed": false, "plays": 0, "history": {}},
		"settings": {"music": 0.7, "sfx": 0.9, "vibration": true, "fast": false},
		"tutorial": {"kitchen": false, "judging": false, "lab": false, "plating": false},
	}


func load_game() -> void:
	var d: Variant = _read_json(SAVE_PATH)
	loaded_from = "save"
	if not (d is Dictionary):
		d = _read_json(BAK_PATH)
		loaded_from = "backup"
	if not (d is Dictionary):
		d = {}
		loaded_from = "defaults"
	data = _validate(d)
	loaded.emit()


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var txt := f.get_as_text()
	f.close()
	if txt.strip_edges() == "":
		return null
	var json := JSON.new()
	if json.parse(txt) != OK:
		push_warning("Kayıt dosyası bozuk: %s" % path)
		return null
	return json.data


## Yüklenen veriyi varsayılan şablonla birleştirir; yanlış türdeki alanlar varsayılana döner.
func _validate(loaded_d: Dictionary) -> Dictionary:
	var def := default_data()
	var out: Dictionary = _merge(def, loaded_d)
	out["version"] = SAVE_VERSION
	# Sayısal alanlar JSON'dan float gelir; tam sayıya çevir.
	for k in ["coins", "xp", "level", "skill_points", "created"]:
		out[k] = maxi(0, int(out[k]))
	out["level"] = maxi(1, int(out["level"]))
	var chef: Dictionary = out["chef"]
	chef["skin"] = clampi(int(chef["skin"]), 0, 5)
	chef["hair_color"] = clampi(int(chef["hair_color"]), 0, 8)
	var specs: Dictionary = out["specs"]
	for s in specs.keys():
		specs[s] = clampi(int(specs[s]), 0, 3)
	var st: Dictionary = out["stats"]
	for s in st.keys():
		if s == "best_round":
			st[s] = float(st[s])
		else:
			st[s] = maxi(0, int(st[s]))
	# Kimlik listeleri sadece string içermeli
	for k in ["ingredients", "achievements", "secrets", "mutations_seen", "hints_bought"]:
		out[k] = _string_array(out[k])
	var owned: Dictionary = out["owned"]
	for k in owned.keys():
		owned[k] = _string_array(owned[k])
	var career: Dictionary = out["career"]
	var leagues_done: Array = []
	for v in career.get("leagues_done", []):
		if v is float or v is int:
			leagues_done.append(int(v))
	career["leagues_done"] = leagues_done
	if not (career.get("matches") is Dictionary):
		career["matches"] = {}
	return out


func _string_array(a: Variant) -> Array:
	var res: Array = []
	if a is Array:
		for v in a:
			if v is String and not res.has(v):
				res.append(v)
	return res


func _merge(def: Variant, src: Variant) -> Variant:
	if def is Dictionary:
		if not (src is Dictionary):
			return def.duplicate(true)
		var res: Dictionary = {}
		var d: Dictionary = def
		var s: Dictionary = src
		if d.is_empty():
			# Serbest anahtarlı sözlük (ör. tarifler) — olduğu gibi kopyala
			return s.duplicate(true)
		for k in d.keys():
			if s.has(k):
				res[k] = _merge(d[k], s[k])
			else:
				res[k] = _copy(d[k])
		return res
	if def is Array:
		if src is Array:
			return src.duplicate(true)
		return def.duplicate(true)
	if def is bool:
		return src if src is bool else def
	if def is int or def is float:
		if src is int or src is float:
			return src
		return def
	if def is String:
		return src if src is String else def
	return src if typeof(src) == typeof(def) else def


func _copy(v: Variant) -> Variant:
	if v is Dictionary or v is Array:
		return v.duplicate(true)
	return v


## Değişiklik yapıldığını bildirir; kısa bir gecikmeyle toplu kaydeder.
func mark_dirty(immediate := false) -> void:
	_dirty = true
	_save_timer = 0.0 if immediate else 0.6
	if immediate:
		save_now()


func save_now() -> bool:
	_dirty = false
	var txt := JSON.stringify(data, "", false)
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if f == null:
		last_error = "Geçici dosya açılamadı (%d)" % FileAccess.get_open_error()
		push_warning(last_error)
		return false
	f.store_string(txt)
	f.flush()
	f.close()
	# Yazılanı geri okuyup doğrula; başarısızsa mevcut kayda dokunma.
	var check: Variant = _read_json(TMP_PATH)
	if not (check is Dictionary):
		last_error = "Kayıt doğrulanamadı"
		push_warning(last_error)
		return false
	var dir := DirAccess.open("user://")
	if dir == null:
		last_error = "user:// açılamadı"
		return false
	if dir.file_exists("save.json"):
		if dir.file_exists("save.bak"):
			dir.remove("save.bak")
		dir.rename("save.json", "save.bak")
	var err := dir.rename("save.tmp", "save.json")
	if err != OK:
		last_error = "Kayıt yeniden adlandırılamadı (%d)" % err
		push_warning(last_error)
		# Yedeği geri getir
		if dir.file_exists("save.bak") and not dir.file_exists("save.json"):
			dir.copy("user://save.bak", "user://save.json")
		return false
	saved.emit()
	return true


func reset_all() -> void:
	data = default_data()
	save_now()
	loaded.emit()


# ---------------------------------------------------------------- kısayollar
func setting(key: String, def: Variant = null) -> Variant:
	return data["settings"].get(key, def)


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	mark_dirty()
