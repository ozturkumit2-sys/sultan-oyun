extends Node
## GameManager: owns the simulation, settings, and SaveManager functions.

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"
const JOURNAL_PATH := "user://journal.json"     # Discovery Journal: lifetime collection across games

signal settings_changed

var world: SimWorld
var settings := {"sound": true, "music": true, "auto_next": false, "tips_seen": false, "lang": ""}
var chars: Array = []
var facts: Dictionary = {}
var event_defs: Array = []
var arc_defs: Array = []
var rumor_defs: Dictionary = {}
var iv_data: Dictionary = {}
var journal: Dictionary = {}
var speed := 1.0          # 0 = paused, 1 = normal, 2 = fast


func _ready() -> void:
	load_settings()
	settings["lang"] = Loc.lang
	_load_data()


func _read(path: String):
	if not FileAccess.file_exists(path):
		push_error("Missing data file " + path)
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _load_data() -> void:
	chars = _read("res://data/characters.json")
	localize_chars()
	facts = _read("res://data/facts.json")
	event_defs = _read("res://data/events.json")
	arc_defs = _read("res://data/arcs.json")
	rumor_defs = _read("res://data/rumors.json")
	iv_data = _read("res://data/interventions.json")
	if FileAccess.file_exists(JOURNAL_PATH):
		var j = JSON.parse_string(FileAccess.get_file_as_string(JOURNAL_PATH))
		if typeof(j) == TYPE_DICTIONARY:
			journal = j


## Character names follow the language (Chinese and Hindi write them in their own script).
func localize_chars() -> void:
	for c in chars:
		c["name"] = Loc.npc_name(str(c["id"]))


## Language picked in settings: save, switch, and bring the office back in the new language.
func change_language(code: String) -> void:
	if code == Loc.lang:
		return
	if world != null:
		save_game()
	settings["lang"] = code
	save_settings()
	Loc.load_lang(code)
	localize_chars()
	if world != null:
		load_game()
	Loc.changed.emit()


func create_world() -> SimWorld:
	var w := SimWorld.new()
	w.load_data(chars, facts, event_defs, Loc.dialogue, Callable(Loc, "t"))
	w.load_story(arc_defs, rumor_defs)
	w.load_interventions(iv_data)
	return w


func new_game(seed_in := 0) -> void:
	world = create_world()
	world.new_game(seed_in)
	world.discovery.merge(journal)
	speed = 1.0
	save_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_day() -> int:
	if not has_save():
		return 0
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return 0
	return int(d.get("day", 1))


func save_game() -> bool:
	if world == null:
		return false
	var f := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(world.to_dict()))
	f.close()
	save_journal()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY or int(d.get("version", 0)) != C.SAVE_VERSION:
		return false
	world = create_world()
	world.from_dict(d)
	world.discovery.merge(journal)
	world.relocalize()
	speed = 1.0
	return true


## The journal outlives any single office: merged into every game, saved with it.
func save_journal() -> void:
	if world == null:
		return
	journal = world.discovery.to_dict()
	journal.erase("cascades")
	var f := FileAccess.open(JOURNAL_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(journal))
		f.close()


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in settings:
			settings[k] = cfg.get_value("settings", k, settings[k])


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.save(SETTINGS_PATH)
	settings_changed.emit()


func set_setting(k: String, v) -> void:
	settings[k] = v
	save_settings()
