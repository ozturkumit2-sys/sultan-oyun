extends Node
## Sürümlenebilir, bozulmaya dayanıklı kayıt sistemi.
## Biçim: tür bilgisini koruyan JSON (JSON.from_native). Her yuva için ayrı başlık dosyası,
## atomik yazım (geçici dosya + yeniden adlandırma) ve bir önceki kaydın yedeği (.bak).

signal saved(slot: String)
signal save_failed(slot: String, reason: String)

const DIR := "user://saves/"
const SLOTS := ["oto", "1", "2", "3"]
const SLOT_NAMES := {"oto": "Otomatik Kayıt", "1": "Kayıt 1", "2": "Kayıt 2", "3": "Kayıt 3"}

var pending_load_slot := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(DIR)


func _path(slot: String) -> String:
	return DIR + "yuva_%s.json" % slot


func _meta_path(slot: String) -> String:
	return DIR + "yuva_%s.meta" % slot


func save_game(slot: String) -> bool:
	if not GameState.active or GameState.w.is_empty():
		save_failed.emit(slot, "Etkin oyun yok")
		return false
	var world: Dictionary = GameState.serialize()
	var header := {
		"save_version": GameState.SAVE_VERSION, "game_version": GameState.GAME_VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true), "unix": Time.get_unix_time_from_system(),
		"summary": GameState.summary_text(), "day": GameState.get_day(), "sultan": String(GameState.player()["name"]),
		"treasury": GameState.treasury(),
	}
	var text := JSON.stringify(JSON.from_native({"header": header, "world": world}))
	if not _atomic_write(_path(slot), text):
		save_failed.emit(slot, "Dosya yazılamadı")
		return false
	_atomic_write(_meta_path(slot), JSON.stringify(header))
	saved.emit(slot)
	return true


func _atomic_write(p: String, text: String) -> bool:
	var tmp := p + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	f.close()
	# doğrula
	var check := FileAccess.get_file_as_string(tmp)
	if check.length() != text.length():
		return false
	if FileAccess.file_exists(p):
		var bak := p + ".bak"
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(p, bak)
	return DirAccess.rename_absolute(tmp, p) == OK


func read_header(slot: String) -> Dictionary:
	var mp := _meta_path(slot)
	if not FileAccess.file_exists(mp):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(mp))
	if parsed is Dictionary:
		return parsed
	return {}


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(_path(slot)) or FileAccess.file_exists(_path(slot) + ".bak")


func has_any_save() -> bool:
	for s in SLOTS:
		if has_save(s):
			return true
	return false


func latest_slot() -> String:
	var best := ""
	var best_t := -1.0
	for s in SLOTS:
		if not has_save(s):
			continue
		var h := read_header(s)
		var t := float(h.get("unix", 0.0))
		if t > best_t:
			best_t = t
			best = s
	return best


func _read_world(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var text := FileAccess.get_file_as_string(p)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if parsed == null:
		return {}
	var data = JSON.to_native(parsed, false)
	if not data is Dictionary or not data.has("world"):
		return {}
	var world = data["world"]
	if not world is Dictionary:
		return {}
	if not world.has("characters") or not world.has("time") or not world.has("state"):
		return {}
	var hdr: Dictionary = data.get("header", {})
	return _migrate(world, int(hdr.get("save_version", 1)))


## Yükler; ana dosya bozuksa yedekten kurtarmayı dener.
func load_game(slot: String) -> bool:
	var world := _read_world(_path(slot))
	if world.is_empty():
		world = _read_world(_path(slot) + ".bak")
		if world.is_empty():
			return false
		push_warning("Kayıt bozuk; yedekten yüklendi: " + slot)
	GameState.load_world(world)
	return true


func delete_slot(slot: String) -> void:
	for p in [_path(slot), _path(slot) + ".bak", _meta_path(slot)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## Eski sürüm kayıtlarını güncel biçime taşır ve eksik alanları tamamlar.
func _migrate(w: Dictionary, from_version: int) -> Dictionary:
	var v := from_version
	while v < GameState.SAVE_VERSION:
		# Gelecek sürümler için dönüşümler buraya eklenir.
		v += 1
	var defaults := {
		"modifiers": [], "projects": [], "log": [], "npc_log": [], "lore": {}, "flags": {}, "tasks": [],
		"dialogue": {"recent": {}, "today": {}, "last_talk": {}},
		"events": {"pending": [], "scheduled": [], "history": [], "fired": {}, "cooldown": {}},
		"divan": {"agenda": [], "next_refresh": 0, "decided": []},
		"petitions": {"list": [], "next_refresh": 0, "heard": 0},
		"dynasty": {"name": "Zehrâni", "rulers": [], "history": []},
		"player": {"pos": [0.0, 0.0, 6.0], "yaw": 0.0, "room": "avlu", "books": 0},
		"id_counter": 1000,
		"harem": HaremEngine.default_data(),
		"crimes": JusticeEngine.default_data(),
	}
	for k in defaults.keys():
		if not w.has(k):
			w[k] = defaults[k]
	if not w.has("meta"):
		w["meta"] = {}
	w["meta"]["save_version"] = GameState.SAVE_VERSION
	# sonradan eklenen sabit karakterler (ör. Hasodabaşı Cafer Ağa)
	if not w.has("relations"):
		w["relations"] = {}
	for sid in CharactersData.CHARACTERS.keys():
		if not w["characters"].has(sid):
			w["characters"][sid] = GameState.make_static_char(sid)
			for seed_rel in CharactersData.REL_SEEDS:
				if seed_rel[0] == sid or seed_rel[1] == sid:
					var r: Dictionary = GameState.REL_DEFAULT.duplicate()
					for k in seed_rel[2].keys():
						r[k] = float(seed_rel[2][k])
					w["relations"][String(seed_rel[0]) + ">" + String(seed_rel[1])] = r
			if CharactersData.PLAYER_RELS.has(sid):
				var pr: Dictionary = GameState.REL_DEFAULT.duplicate()
				for k2 in CharactersData.PLAYER_RELS[sid].keys():
					pr[k2] = float(CharactersData.PLAYER_RELS[sid][k2])
				w["relations"][sid + ">" + GameState.PLAYER] = pr
	for id in w["characters"].keys():
		var c: Dictionary = w["characters"][id]
		for ck in ["memories", "married_to"]:
			if not c.has(ck):
				c[ck] = []
		if id != GameState.PLAYER:
			if not c.has("needs"):
				c["needs"] = {"enerji": 80.0, "tokluk": 70.0, "sosyal": 60.0}
			if not c.has("mood"):
				c["mood"] = 0.0
	return w
