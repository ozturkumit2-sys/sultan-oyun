extends Node
## Localization. UI/log strings live in data/lang/<lang>.json, dialogue in
## data/dialogue_<lang>.json. Missing keys fall back to English, key by key.
##
## Placeholders:
##   {x}          the value (a name, an item, a number...)
##   {x:case}     the value with a grammatical ending (Turkish: in, i, e, de, den, le;
##                German: s). Names get an apostrophe in Turkish ("Selin'in").
##   {x?m|f}      picks a word by the gender of the person in x ("cansado|cansada").
##                x can be a role, or me / to in speech bubbles.

signal changed

const LANGS := [
	["en", "English"], ["tr", "Türkçe"], ["de", "Deutsch"], ["es", "Español"],
	["fr", "Français"], ["zh", "中文"], ["hi", "हिन्दी"],
]
const SETTINGS_PATH := "user://settings.cfg"

var lang := "en"
var strings: Dictionary = {}
var en_strings: Dictionary = {}
var dialogue: Dictionary = {}
var en_dialogue: Dictionary = {}
var available: Array = []
var people: Dictionary = {}       # id -> {"name": default name, "gender": "m"/"f"}
var genders: Dictionary = {}      # display name -> "m"/"f"
var _re := RegEx.new()


func _ready() -> void:
	_re.compile("\\{(\\w+)(?::(\\w+))?(?:\\?([^|{}]*)\\|([^{}]*))?\\}")
	for l in LANGS:
		available.append(l[0])
	en_strings = _read_json("res://data/lang/en.json")
	en_dialogue = _read_json("res://data/dialogue_en.json")
	var chars = JSON.parse_string(FileAccess.get_file_as_string("res://data/characters.json")) if FileAccess.file_exists("res://data/characters.json") else []
	if typeof(chars) == TYPE_ARRAY:
		for c in chars:
			people[str(c["id"])] = {"name": str(c["name"]), "gender": str(c.get("gender", "m"))}
	load_lang(_initial_lang())


## Saved choice, else the phone's language when we have it, else English.
func _initial_lang() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var saved := str(cfg.get_value("settings", "lang", ""))
		if available.has(saved):
			return saved
	var sys := OS.get_locale_language()
	return sys if available.has(sys) else "en"


func load_lang(code: String) -> void:
	if not available.has(code):
		code = "en"
	lang = code
	if code == "en":
		strings = en_strings
		dialogue = en_dialogue
	else:
		strings = _read_json("res://data/lang/%s.json" % code)
		var dl := _read_json("res://data/dialogue_%s.json" % code)
		dialogue = en_dialogue.duplicate()
		for k in dl:
			dialogue[k] = dl[k]
	genders.clear()
	for id in people:
		genders[npc_name(id)] = people[id]["gender"]


## Switch language at runtime (settings); listeners rebuild their screens.
func set_lang(code: String) -> void:
	if code == lang:
		return
	load_lang(code)
	changed.emit()


func lang_name(code: String) -> String:
	for l in LANGS:
		if l[0] == code:
			return l[1]
	return code


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
	return strings.has(key) or en_strings.has(key)


func raw(key: String):
	if strings.has(key):
		return strings[key]
	return en_strings.get(key, key)


## Translate a key; {name} placeholders are filled from args.
func t(key: String, args: Dictionary = {}) -> String:
	var s = raw(key)
	if typeof(s) == TYPE_ARRAY:
		s = s[randi() % s.size()] if s.size() > 0 else ""
	var out: String = str(s)
	if not args.is_empty() and out.find("{") >= 0:
		out = fill(out, args)
	return out


## The n-th variant of a key that holds several (used to re-render stored lines).
func variant(key: String, i: int) -> String:
	var s = raw(key)
	if typeof(s) == TYPE_ARRAY:
		if s.is_empty():
			return ""
		return str(s[clampi(i, 0, s.size() - 1)])
	return str(s)


func variant_count(key: String) -> int:
	var s = raw(key)
	return s.size() if typeof(s) == TYPE_ARRAY else 1


## Display name of a character in the current language.
func npc_name(id: String) -> String:
	var k := "name." + id
	if strings.has(k):
		return str(strings[k])
	return str(people.get(id, {}).get("name", id))


func fill(s: String, args: Dictionary) -> String:
	return fill_with(s, func(k): return args.get(k))


## Fills placeholders; getter(name) returns the value or null (left untouched).
func fill_with(s: String, getter: Callable) -> String:
	if s.find("{") < 0:
		return s
	var out := ""
	var pos := 0
	for m in _re.search_all(s):
		out += s.substr(pos, m.get_start() - pos)
		pos = m.get_end()
		var v = getter.call(m.get_string(1))
		if v == null:
			# unknown person for a gendered word: use the first form
			out += m.get_string(3) if m.get_start(3) >= 0 else m.get_string()
			continue
		var val := str(v)
		if m.get_start(3) >= 0:
			# gender choice
			out += m.get_string(3) if genders.get(val, "m") == "m" else m.get_string(4)
		elif m.get_string(2) != "":
			out += inflect(val, m.get_string(2), genders.has(val))
		else:
			out += val
	out += s.substr(pos)
	return out


## Placeholder names used by a template ("{a:in}" -> "a").
func placeholders(s: String) -> Array:
	var out: Array = []
	if s.find("{") < 0:
		return out
	for m in _re.search_all(s):
		if not out.has(m.get_string(1)):
			out.append(m.get_string(1))
	return out


# ------------------------------------------------------------------ grammar helpers

func inflect(word: String, kase: String, proper: bool) -> String:
	match lang:
		"tr":
			return _tr_suffix(word, kase, proper)
		"de":
			if kase == "s":
				var last := word.right(1).to_lower()
				return word + ("’" if last in ["s", "ß", "x", "z"] else "s")
	return word


const TR_VOWELS := "aeıioöuü"
const TR_HARD := "fstkçşhp"


func _tr_lower(s: String) -> String:
	return s.replace("I", "ı").replace("İ", "i").to_lower()


func _tr_suffix(word: String, kase: String, proper: bool) -> String:
	if word == "":
		return word
	var lw := _tr_lower(word)
	var lastv := ""
	for i in range(lw.length() - 1, -1, -1):
		var ch := lw[i]
		if TR_VOWELS.find(ch) >= 0:
			lastv = ch
			break
	if lastv == "":
		lastv = "e"
	var back := "aıou".find(lastv) >= 0
	var round := "ouöü".find(lastv) >= 0
	var A := "a" if back else "e"
	var I := ("u" if round else "ı") if back else ("ü" if round else "i")
	var last := lw.right(1)
	var vowel_end := TR_VOWELS.find(last) >= 0
	var hard := TR_HARD.find(last) >= 0
	var suf := ""
	match kase:
		"in":
			suf = ("n" + I + "n") if vowel_end else (I + "n")
		"i":
			suf = ("y" + I) if vowel_end else I
		"e":
			suf = ("y" + A) if vowel_end else A
		"de":
			suf = ("t" if hard else "d") + A
		"den":
			suf = ("t" if hard else "d") + A + "n"
		"le":
			suf = ("yl" + A) if vowel_end else ("l" + A)
		"dir":
			suf = ("t" if hard else "d") + I + "r"
		_:
			return word
	return word + ("'" if proper else "") + suf


## Upper case that knows Turkish dotted/dotless i.
func upper(s: String) -> String:
	if lang == "tr":
		s = s.replace("i", "İ").replace("ı", "I")
	return s.to_upper()


## First letter upper case.
func cap(s: String) -> String:
	if s == "":
		return s
	return upper(s.left(1)) + s.substr(1)


## Chinese has no spaces: lines may break between any two characters.
func is_cjk() -> bool:
	return lang == "zh"


## How long speech bubbles stay, relative to English (Chinese packs more per character).
func read_scale() -> float:
	return 2.3 if lang == "zh" else 1.0


const NO_LINE_START := "，。！？；：、）」』”’…—～·%》〉!?.,;:)]}"


## Splits text into pieces a line may break between: [piece, glue-before].
func wrap_tokens(text: String) -> Array:
	var out: Array = []
	if not is_cjk():
		for wd in text.split(" "):
			out.append([wd, " "])
		return out
	var cur := ""
	var glue := ""
	for i in text.length():
		var ch := text[i]
		var code := ch.unicode_at(0)
		var wide := code >= 0x2E80
		if ch == " ":
			if cur != "":
				out.append([cur, glue])
			cur = ""
			glue = " "
			continue
		if NO_LINE_START.find(ch) >= 0 and (cur != "" or not out.is_empty()):
			if cur != "":
				cur += ch
			else:
				out[out.size() - 1][0] += ch
			continue
		if wide:
			if cur != "":
				out.append([cur, glue])
				glue = ""
			cur = ch
			out.append([cur, glue])
			cur = ""
			glue = ""
		else:
			if cur != "" and cur.unicode_at(cur.length() - 1) >= 0x2E80:
				out.append([cur, glue])
				cur = ""
				glue = ""
			cur += ch
	if cur != "":
		out.append([cur, glue])
	return out


## Every placeholder a key may use, in English or the current language.
func ref_names(key: String) -> Array:
	var out: Array = []
	for src in [en_strings, strings]:
		var s = src.get(key, "")
		var arr: Array = s if typeof(s) == TYPE_ARRAY else [s]
		for x in arr:
			for ph in placeholders(str(x)):
				if not out.has(ph):
					out.append(ph)
	return out


## "Label: value" separator (French puts a space before the colon, Chinese uses a wide one).
func colon() -> String:
	match lang:
		"fr":
			return " : "
		"zh":
			return "："
	return ": "
