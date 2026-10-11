extends Node
## IngredientDatabase — tüm oyun içeriğini (malzemeler, tarifler, temalar, jüri, rakipler, ligler,
## kozmetikler) JSON dosyalarından yükler ve hızlı erişim için dizinler.

const STAT_KEYS := ["sweet", "spicy", "fresh", "weird", "magic", "toxic", "volatile", "life", "rarity"]
const STAT_NAMES := {"sweet": "Tatlılık", "spicy": "Acılık", "fresh": "Tazelik", "weird": "Tuhaflık",
	"magic": "Büyü", "toxic": "Zehir", "volatile": "Oynaklık", "life": "Canlılık", "rarity": "Nadirlik"}
const STAT_COLORS := {"sweet": Color("#ff7ab8"), "spicy": Color("#ff4f3a"), "fresh": Color("#3ddc84"),
	"weird": Color("#b35ad8"), "magic": Color("#7c6bff"), "toxic": Color("#8fbf3a"), "volatile": Color("#ffb020"),
	"life": Color("#ff8a5c"), "rarity": Color("#f2c14e")}
const METHOD_ORDER := ["bake", "fry", "freeze", "boil", "grill", "magic"]

var ingredients: Dictionary = {}
var ingredient_order: Array = []
var categories: Dictionary = {}
var recipes: Dictionary = {}
var recipe_order: Array = []
var recipe_index: Dictionary = {}   # anahtar -> tarif id
var methods: Dictionary = {}
var themes: Dictionary = {}
var theme_order: Array = []
var judges: Array = []
var judge_map: Dictionary = {}
var judge_lines: Dictionary = {}   # jüri id -> bağlamsal replik havuzları (data/judge_lines.json)
var names: Dictionary = {}         # hikâyeli isim tabloları (data/names.json)
var reactions: Array = []
var opponents: Dictionary = {}
var opponent_order: Array = []
var leagues: Array = []
var rules: Dictionary = {}
var matches: Dictionary = {}
var match_order: Array = []
var content: Dictionary = {}
var mutations: Dictionary = {}
var mutation_order: Array = []
var secrets: Dictionary = {}
var achievements: Dictionary = {}
var achievement_order: Array = []
var plates: Dictionary = {}
var plate_order: Array = []
var garnishes: Dictionary = {}
var garnish_order: Array = []
var decor: Dictionary = {}
var decor_order: Array = []
var specializations: Array = []
var load_errors: Array = []
var content_version := 1


func _ready() -> void:
	load_all()


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		load_errors.append("Açılamadı: " + path)
		return {}
	var json := JSON.new()
	var err := json.parse(f.get_as_text())
	f.close()
	if err != OK:
		load_errors.append("%s: satır %d — %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if json.data is Dictionary:
		return json.data
	load_errors.append("Sözlük değil: " + path)
	return {}


func load_all() -> void:
	load_errors.clear()
	var ing := _load_json("res://data/ingredients.json")
	categories = ing.get("categories", {})
	for it in ing.get("ingredients", []):
		var d: Dictionary = it
		d["kind"] = "ingredient"
		d["depth"] = 0
		d["stats"] = _norm_stats(d.get("stats", {}))
		ingredients[d["id"]] = d
		ingredient_order.append(d["id"])

	var rec := _load_json("res://data/recipes.json")
	methods = rec.get("methods", {})
	for r in rec.get("recipes", []):
		var d: Dictionary = r
		for inp in d.get("inputs", []):
			if not ingredients.has(inp) and not _recipe_id_listed(rec, inp):
				load_errors.append("Tarif %s bilinmeyen girdi: %s" % [d["id"], inp])
		recipes[d["id"]] = d
		recipe_order.append(d["id"])
		var m: Variant = d.get("method")
		var key := make_key(d.get("inputs", []), m if m is String else "")
		if recipe_index.has(key):
			load_errors.append("Yinelenen tarif anahtarı: " + key)
		recipe_index[key] = d["id"]

	var th := _load_json("res://data/themes.json")
	for t in th.get("themes", []):
		themes[t["id"]] = t
		theme_order.append(t["id"])

	var jd := _load_json("res://data/judges.json")
	judges = jd.get("judges", [])
	for j in judges:
		judge_map[j["id"]] = j
	reactions = jd.get("reactions", [])
	judge_lines = _load_json("res://data/judge_lines.json")

	var op := _load_json("res://data/opponents.json")
	for o in op.get("opponents", []):
		opponents[o["id"]] = o
		opponent_order.append(o["id"])

	var lg := _load_json("res://data/leagues.json")
	rules = lg.get("rules", {})
	leagues = lg.get("leagues", [])
	for l in leagues:
		var lid := int(l["id"])
		l["id"] = lid
		var idx := 0
		for m in l.get("matches", []):
			m["league"] = lid
			m["index"] = idx
			idx += 1
			matches[m["id"]] = m
			match_order.append(m["id"])
			if not opponents.has(m["opponent"]):
				load_errors.append("Maç %s bilinmeyen rakip" % m["id"])
			for t in m.get("themes", []):
				if not themes.has(t):
					load_errors.append("Maç %s bilinmeyen tema %s" % [m["id"], t])

	content = _load_json("res://data/content.json")
	content_version = int(content.get("version", 1))
	for m in content.get("mutations", []):
		mutations[m["id"]] = m
		mutation_order.append(m["id"])
	for s in content.get("secrets", []):
		secrets[s["id"]] = s
	for a in content.get("achievements", []):
		achievements[a["id"]] = a
		achievement_order.append(a["id"])
	for p in content.get("plates", []):
		plates[p["id"]] = p
		plate_order.append(p["id"])
	for g in content.get("garnishes", []):
		garnishes[g["id"]] = g
		garnish_order.append(g["id"])
	for d in content.get("decor", []):
		decor[d["id"]] = d
		decor_order.append(d["id"])
	specializations = content.get("specializations", [])
	names = _load_json("res://data/names.json")
	if not load_errors.is_empty():
		for e in load_errors:
			push_warning("[Veri] " + str(e))
	_slots.clear()
	for root in [ingredients, categories, recipes, methods, themes, judges, reactions, judge_lines, opponents, leagues, rules, content]:
		_collect(root, 0)
	apply_language()


# ------------------------------------------------------------------ çeviri
## Veri içindeki görünür metinlerin konumları: [kap, anahtar/indeks, Türkçe asıl]
var _slots: Array = []
## Çevrilmeyen (kimlik/renk/etiket) alanlar
const NO_TR := {"id": 1, "tags": 1, "inputs": 1, "method": 1, "color": 1, "color2": 1, "c1": 1, "c2": 1, "base": 1,
	"decor": 1, "likes": 1, "dislikes": 1, "icon": 1, "type": 1, "living": 1, "unlocks": 1, "match": 1, "opponent": 1,
	"themes": 1, "mystery": 1, "preferred": 1, "methods": 1, "likes_tags": 1, "noun": 1, "adj": 1, "weights": 1,
	"target": 1, "stats": 1, "bonus": 1, "tags_add": 1, "visual": 1, "category": 1, "skin_tones": 1, "hair_colors": 1,
	"kind": 1, "slot": 1, "judge": 1, "mutation": 1, "ability": 0, "weight_shift": 1, "rule": 1, "hat": 1, "shape": 1,
	"style": 1, "pose": 1, "preset": 1, "reaction": 1, "anim": 1, "sfx": 1, "key": 1, "stat": 1, "tag": 1, "effect": 0}


func _collect(v: Variant, depth: int) -> void:
	if depth > 12:
		return
	if v is Dictionary:
		var d: Dictionary = v
		for k in d.keys():
			if NO_TR.get(str(k), 0) == 1:
				continue
			var x: Variant = d[k]
			if x is String:
				if _translatable(x):
					_slots.append([d, k, x])
			elif x is Dictionary or x is Array:
				_collect(x, depth + 1)
	elif v is Array:
		var a: Array = v
		for i in a.size():
			var x: Variant = a[i]
			if x is String:
				if _translatable(x):
					_slots.append([a, i, x])
			elif x is Dictionary or x is Array:
				_collect(x, depth + 1)


## Kimlik gibi görünen (boşluksuz küçük harf/rakam/alt çizgi) ve renk kodu metinlerini atla.
static func _translatable(s: String) -> bool:
	if s.strip_edges() == "" or s.begins_with("#") or s.begins_with("res://"):
		return false
	var idlike := true
	for c in s:
		if not ((c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_"):
			idlike = false
			break
	return not idlike


## Tüm veri metinlerini aktif dile göre yeniden yazar.
func apply_language() -> void:
	for sl in _slots:
		var c: Variant = sl[0]
		c[sl[1]] = Loc.t(str(sl[2]))


func _recipe_id_listed(rec: Dictionary, id: String) -> bool:
	for r in rec.get("recipes", []):
		if r["id"] == id:
			return true
	return false


func _norm_stats(s: Dictionary) -> Dictionary:
	var out := {}
	for k in STAT_KEYS:
		out[k] = clampf(float(s.get(k, 0)), 0.0, 100.0)
	return out


## Girdi sırası önemsiz, deterministik tarif anahtarı.
static func make_key(inputs: Array, method: String) -> String:
	var arr: Array = []
	for i in inputs:
		arr.append(str(i))
	arr.sort()
	return "+".join(PackedStringArray(arr)) + "|" + (method if method != "" else "fuse")


func find_recipe(inputs: Array, method: String) -> String:
	return recipe_index.get(make_key(inputs, method), "")


func is_ingredient(id: String) -> bool:
	return ingredients.has(id)


func is_recipe(id: String) -> bool:
	return recipes.has(id)


func cosmetic_list(slot: String) -> Array:
	return content.get("cosmetics", {}).get(slot, [])


func cosmetic(slot: String, id: String) -> Dictionary:
	for c in cosmetic_list(slot):
		if c["id"] == id:
			return c
	return {}


func skin_color(idx: int) -> Color:
	var arr: Array = content.get("skin_tones", ["#f7c9a0"])
	return Color(arr[clampi(idx, 0, arr.size() - 1)])


func hair_color(idx: int) -> Color:
	var arr: Array = content.get("hair_colors", ["#2b1d16"])
	return Color(arr[clampi(idx, 0, arr.size() - 1)])


func league(id: int) -> Dictionary:
	for l in leagues:
		if int(l["id"]) == id:
			return l
	return {}


func method_name(m: String) -> String:
	return methods.get(m, {}).get("name", m)


func theme(id: String) -> Dictionary:
	return themes.get(id, {})


func handcrafted_dishes() -> Array:
	return recipe_order.duplicate()
