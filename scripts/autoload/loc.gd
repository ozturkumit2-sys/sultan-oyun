extends Node
## Localization. UI/log strings live in data/lang/<lang>.json, dialogue in
## data/dialogue_<lang>.json. Adding a language = adding those two files.

var lang := "en"
var strings: Dictionary = {}
var dialogue: Dictionary = {}
var available := ["en"]


func _ready() -> void:
	load_lang(lang)


func load_lang(code: String) -> void:
	lang = code
	strings = _read_json("res://data/lang/%s.json" % code)
	if strings.is_empty() and code != "en":
		strings = _read_json("res://data/lang/en.json")
	dialogue = _read_json("res://data/dialogue_%s.json" % code)
	if dialogue.is_empty() and code != "en":
		dialogue = _read_json("res://data/dialogue_en.json")


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var txt := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Bad JSON: " + path)
		return {}
	return data


func has(key: String) -> bool:
	return strings.has(key)


## Translate a key; {name} placeholders are filled from args.
func t(key: String, args: Dictionary = {}) -> String:
	var s = strings.get(key, key)
	if typeof(s) == TYPE_ARRAY:
		s = s[randi() % s.size()]
	var out: String = str(s)
	if not args.is_empty():
		out = fill(out, args)
	return out


static func fill(s: String, args: Dictionary) -> String:
	var out := s
	for k in args:
		out = out.replace("{" + str(k) + "}", str(args[k]))
	return out
