class_name FusionEngine
extends RefCounted
## Deterministik füzyon motoru.
## - Aynı girdiler (sıra önemsiz) ve aynı yöntem her zaman aynı tarifi üretir.
## - El yapımı tarifler data/recipes.json'dan gelir; geri kalanlar özelliklerden dinamik üretilir.
## - Dinamik tariflerin kimliği girdilerin FNV-1a özetinden türetilir ve kayıtta tutulur.

const STAT_KEYS := ["sweet", "spicy", "fresh", "weird", "magic", "toxic", "volatile", "life", "rarity"]
const METHOD_TAGS := {"freeze": "cold", "grill": "grilled", "fry": "crunchy", "bake": "baked", "boil": "stew", "magic": "magic"}
const DECOR_BY_TAG := [["fire", "flames"], ["ghost", "ghost_wisps"], ["frog", "frog_eyes"], ["mechanical", "bolts"],
	["insect", "beetle_legs"], ["cosmic", "stars"], ["electric", "lightning"], ["cold", "ice_shards"], ["flower", "flowers"],
	["gothic", "roses"], ["sea", "tentacles"], ["magic", "sparkles"], ["candy", "sprinkles"], ["luxury", "gold_leaf"],
	["fermented", "bubbles"], ["slime", "bubbles"], ["dark", "drizzle"], ["sweet", "sprinkles"], ["savory", "steam"]]
const LIVING_BY_TAG := [["frog", "jump"], ["ghost", "float"], ["robot", "steal"], ["mechanical", "steal"], ["monster", "hide"],
	["sea", "hide"], ["alien", "change"], ["slime", "change"], ["insect", "run"], ["bouncy", "jump"], ["electric", "jump"],
	["cosmic", "float"], ["magic", "change"]]

static var _cache: Dictionary = {}
static var _registry: Dictionary = {}   # dinamik id -> {inputs, method}


static func fnv(s: String) -> int:
	var h := 2166136261
	for b in s.to_utf8_buffer():
		h = h ^ b
		h = (h * 16777619) & 0xFFFFFFFF
	return h


static func clear_cache() -> void:
	_cache.clear()


static func load_registry(reg: Dictionary) -> void:
	for k in reg.keys():
		var e: Variant = reg[k]
		if e is Dictionary and e.get("inputs") is Array:
			_registry[k] = {"inputs": e["inputs"], "method": str(e.get("method", ""))}


static func registry_entry(id: String) -> Dictionary:
	return _registry.get(id, {})


static func is_generic(id: String) -> bool:
	return id.begins_with("gf_") or id.begins_with("gd_")


static func exists(id: String) -> bool:
	return IngredientDatabase.ingredients.has(id) or IngredientDatabase.recipes.has(id) or _registry.has(id)


## Herhangi bir kimliği (malzeme, el yapımı tarif veya dinamik tarif) eşya sözlüğüne çevirir.
static func item(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var res: Dictionary = {}
	if IngredientDatabase.ingredients.has(id):
		res = _from_ingredient(IngredientDatabase.ingredients[id])
	elif IngredientDatabase.recipes.has(id):
		var r: Dictionary = IngredientDatabase.recipes[id]
		var m: Variant = r.get("method")
		res = _build(id, r.get("inputs", []), m if m is String else "", r)
	elif _registry.has(id):
		var e: Dictionary = _registry[id]
		res = _build(id, e["inputs"], e["method"], {})
	else:
		push_warning("Bilinmeyen eşya: " + id)
		res = _from_ingredient({"id": id, "name": "???", "noun": "???", "adj": "???", "category": "experimental",
			"stats": {}, "color": "#888888", "color2": "#444444", "tags": []})
	_cache[id] = res
	return res


static func _from_ingredient(d: Dictionary) -> Dictionary:
	var stats := {}
	var src: Dictionary = d.get("stats", {})
	for k in STAT_KEYS:
		stats[k] = float(src.get(k, 0))
	var tags: Array = d.get("tags", []).duplicate()
	var cat: String = d.get("category", "")
	if cat != "" and not tags.has(cat):
		tags.append(cat)
	return {"id": d["id"], "name": d.get("name", d["id"]), "kind": "ingredient", "noun": d.get("noun", d.get("name", "")),
		"adj": d.get("adj", d.get("name", "")), "category": cat, "stats": stats, "tags": tags,
		"color": d.get("color", "#cccccc"), "color2": d.get("color2", "#999999"), "depth": 0, "inputs": [],
		"method": "", "living": "", "handcrafted": false, "secret": false, "visual": {"base": "icon"},
		"desc": d.get("desc", "")}


## Füzyon: pişirmeden iki/üç eşyayı birleştirir.
static func fuse(inputs: Array) -> Dictionary:
	var rid: String = IngredientDatabase.find_recipe(inputs, "")
	if rid != "":
		return item(rid)
	var key: String = IngredientDatabase.make_key(inputs, "")
	var gid := "gf_%08x" % fnv(key)
	if not _registry.has(gid):
		_registry[gid] = {"inputs": _sorted(inputs), "method": ""}
	return item(gid)


## Pişirme: eşyaları bir yöntemle yemeğe dönüştürür.
static func cook(inputs: Array, method: String) -> Dictionary:
	var rid: String = IngredientDatabase.find_recipe(inputs, method)
	if rid != "":
		return item(rid)
	var key: String = IngredientDatabase.make_key(inputs, method)
	var gid := "gd_%s_%08x" % [method, fnv(key)]
	if not _registry.has(gid):
		_registry[gid] = {"inputs": _sorted(inputs), "method": method}
	return item(gid)


## Önizleme: kasedeki kombinasyon bilinen bir el yapımı tarif mi?
static func peek_recipe(inputs: Array, method: String) -> String:
	return IngredientDatabase.find_recipe(inputs, method)


static func _sorted(a: Array) -> Array:
	var r: Array = []
	for x in a:
		r.append(str(x))
	r.sort()
	return r


static func _score_main(it: Dictionary) -> float:
	var s: Dictionary = it["stats"]
	return s["life"] + s["rarity"] + s["magic"] * 0.5 + float(it.get("depth", 0)) * 30.0


static func _order_items(items: Array) -> Array:
	var arr := items.duplicate()
	arr.sort_custom(func(a, b):
		var sa := _score_main(a)
		var sb := _score_main(b)
		if absf(sa - sb) > 0.001:
			return sa > sb
		return str(a["id"]) < str(b["id"]))
	return arr


static func combine_stats(items: Array) -> Dictionary:
	var n := items.size()
	var out := {}
	if n == 0:
		for k in STAT_KEYS:
			out[k] = 0.0
		return out
	for k in STAT_KEYS:
		var sum := 0.0
		var mx := 0.0
		for it in items:
			var v: float = it["stats"][k]
			sum += v
			mx = maxf(mx, v)
		var avg := sum / n
		if k == "rarity":
			out[k] = mx * 0.75 + avg * 0.25 + 4.0 * (n - 1)
		else:
			out[k] = avg * 0.65 + mx * 0.35
	if n > 1:
		var has_cold := false
		var has_fire := false
		var tag_count := {}
		for it in items:
			var seen := {}
			for t in it["tags"]:
				if t == "cold":
					has_cold = true
				if t == "fire":
					has_fire = true
				if not seen.has(t):
					seen[t] = true
					tag_count[t] = int(tag_count.get(t, 0)) + 1
		if has_cold and has_fire:
			out["volatile"] += 20.0
			out["weird"] += 15.0
		var shared := 0
		for t in tag_count.keys():
			if tag_count[t] >= 2:
				shared += 1
		shared = mini(shared, 3)
		out["fresh"] += 3.0 * shared
		out["toxic"] -= 3.0 * shared
	return out


static func _clamp_stats(s: Dictionary) -> void:
	for k in STAT_KEYS:
		s[k] = clampf(float(s[k]), 0.0, 100.0)


static func adj_of(phrase: String) -> String:
	for i in range(phrase.length() - 1, -1, -1):
		var c := phrase[i]
		if "aıAI".contains(c):
			return phrase + "lı"
		if "eiEİ".contains(c):
			return phrase + "li"
		if "ouOU".contains(c):
			return phrase + "lu"
		if "öüÖÜ".contains(c):
			return phrase + "lü"
	return phrase + "li"


static func _build(id: String, inputs: Array, method: String, recipe: Dictionary) -> Dictionary:
	var items: Array = []
	var depth := 0
	var bases: Array = []
	for inp in inputs:
		var it := item(str(inp))
		items.append(it)
		depth = maxi(depth, int(it.get("depth", 0)))
		for b in it.get("bases", [it["id"]]):
			if not bases.has(b):
				bases.append(b)
	bases.sort()
	depth += 1
	var stats := combine_stats(items)
	var tags: Array = []
	for it in items:
		for t in it["tags"]:
			if not tags.has(t):
				tags.append(t)
	var md: Dictionary = {}
	if method != "":
		md = IngredientDatabase.methods.get(method, {})
		var mod: Dictionary = md.get("mod", {})
		for k in mod.keys():
			stats[k] = float(stats.get(k, 0.0)) + float(mod[k])
		var mt: String = METHOD_TAGS.get(method, "")
		if mt != "" and not tags.has(mt):
			tags.append(mt)
	var handcrafted := not recipe.is_empty()
	if handcrafted:
		var bonus: Dictionary = recipe.get("bonus", {})
		for k in bonus.keys():
			stats[k] = float(stats.get(k, 0.0)) + float(bonus[k])
		for t in recipe.get("tags_add", []):
			if not tags.has(t):
				tags.append(t)
	_clamp_stats(stats)
	if stats["weird"] < 20.0 and stats["magic"] < 20.0 and stats["toxic"] < 20.0 and not tags.has("classic"):
		tags.append("classic")
	var ordered := _order_items(items)
	var main: Dictionary = ordered[0]
	var second: Dictionary = ordered[1] if ordered.size() > 1 else main
	var h := fnv(id)
	var is_dish := method != ""
	var res := {
		"id": id, "kind": "dish" if is_dish else "fusion", "stats": stats, "tags": tags, "depth": depth,
		"inputs": _sorted(inputs), "method": method, "handcrafted": handcrafted,
		"secret": bool(recipe.get("secret", false)), "unlocks": str(recipe.get("unlocks", "")),
	}
	res["bases"] = bases
	# ---- isim (3+ temel malzemede hikâyeli isim)
	var name := ""
	var story := not handcrafted and bases.size() >= NameGen.STORY_MIN_BASES
	if is_dish:
		var dishes: Array = md.get("dish", ["Yemek"])
		res["dish_index"] = h % dishes.size()
	if handcrafted:
		name = recipe["name"]
	elif story:
		var st := NameGen.story(id, stats, tags)
		name = st["name"]
		res["story"] = true
		res["lore"] = st["lore"]
	elif is_dish:
		var dishes2: Array = md.get("dish", ["Yemek"])
		name = NameGen.simple_dish(main, second, str(dishes2[int(res["dish_index"])]))
	else:
		name = NameGen.simple_fusion(ordered)
	res["name"] = name
	if handcrafted and recipe.has("noun"):
		res["noun"] = recipe["noun"]
		res["adj"] = recipe.get("adj", adj_of(recipe["noun"]))
	else:
		res["noun"] = name
		res["adj"] = adj_of(name)
	res["category"] = str(recipe.get("category", main.get("category", "experimental")))
	if not tags.has(res["category"]):
		tags.append(res["category"])
	# ---- görsel
	var visual: Dictionary = {}
	if handcrafted and recipe.has("visual"):
		visual = recipe["visual"].duplicate(true)
	else:
		var base := "blob"
		if is_dish:
			var vbases: Array = md.get("base", ["cake"])
			base = str(vbases[int(res.get("dish_index", 0)) % vbases.size()])
		var c1 := Color(main["color"])
		var c2 := Color(second["color"]) if second["id"] != main["id"] else Color(main["color2"])
		if not is_dish:
			c1 = c1.lerp(Color(second["color"]), 0.35)
		var decor: Array = []
		for pair in DECOR_BY_TAG:
			if tags.has(pair[0]) and not decor.has(pair[1]):
				decor.append(pair[1])
			if decor.size() >= 2:
				break
		visual = {"base": base, "c1": "#" + c1.to_html(false), "c2": "#" + c2.to_html(false), "decor": decor}
	res["visual"] = visual
	res["color"] = visual.get("c1", "#cccccc")
	res["color2"] = visual.get("c2", "#999999")
	# ---- canlılık
	var living := ""
	if handcrafted:
		var lv: Variant = recipe.get("living")
		living = lv if lv is String else ""
	elif is_dish and stats["life"] >= 62.0:
		living = "run"
		for pair in LIVING_BY_TAG:
			if tags.has(pair[0]):
				living = pair[1]
				break
	res["living"] = living if is_dish else ""
	if handcrafted:
		res["desc"] = str(recipe.get("desc", ""))
	elif story:
		res["desc"] = str(res["lore"]) + ((" " + Loc.t("Dikkat: canlı!")) if living != "" and is_dish else "")
	else:
		res["desc"] = describe(stats, is_dish, living != "" and is_dish)
	res["hint"] = str(recipe.get("hint", ""))
	return res


const DESC_WORDS := {"sweet": "tatlı", "spicy": "acı", "fresh": "taze", "weird": "tuhaf", "magic": "büyülü",
	"toxic": "şüpheli", "volatile": "patlamaya hazır", "life": "kıpır kıpır"}


static func describe(stats: Dictionary, is_dish: bool, living: bool) -> String:
	var keys: Array = DESC_WORDS.keys()
	keys.sort_custom(func(a, b):
		if absf(stats[a] - stats[b]) > 0.01:
			return stats[a] > stats[b]
		return a < b)
	var t := Loc.t("Çok %s, biraz %s.") % [Loc.t(DESC_WORDS[keys[0]]), Loc.t(DESC_WORDS[keys[1]])]
	if living:
		t += " " + Loc.t("Dikkat: canlı!")
	return t


## Sabotaj gibi dış etkilerle yemeğin özelliklerini değiştirir (kopya döndürür).
static func modify(dish: Dictionary, stat_mods: Dictionary, add_tags: Array = [], prefix := "") -> Dictionary:
	var d := dish.duplicate(true)
	var s: Dictionary = d["stats"]
	for k in stat_mods.keys():
		s[k] = float(s.get(k, 0.0)) + float(stat_mods[k])
	_clamp_stats(s)
	for t in add_tags:
		if not d["tags"].has(t):
			d["tags"].append(t)
	if prefix == "cursed" and not d.get("cursed_name", false):
		d["name"] = NameGen.cursed(str(d["name"]))
		d["cursed_name"] = true
	return d


## Fermente bir malzemeyi yemeğe belirli oranda karıştırır.
static func taint(dish: Dictionary, ingredient_id: String, weight: float) -> Dictionary:
	var ing := item(ingredient_id)
	var d := dish.duplicate(true)
	var s: Dictionary = d["stats"]
	for k in STAT_KEYS:
		s[k] = s[k] * (1.0 - weight) + float(ing["stats"][k]) * weight
	if weight > 0.15:
		s["rarity"] += 5.0
	_clamp_stats(s)
	for t in ing["tags"]:
		if not d["tags"].has(t):
			d["tags"].append(t)
	d["tags"].erase("classic")
	if not d.has("tainted"):
		d["name"] = NameGen.tainted(str(d["name"]), ing)
	d["tainted"] = ingredient_id
	return d


## Bir eşyanın füzyon zincirinde belirli bir malzeme var mı? (Gizemli malzeme kontrolü)
static func contains_ingredient(id: String, target: String) -> bool:
	if id == target:
		return true
	var it := item(id)
	for inp in it.get("inputs", []):
		if contains_ingredient(str(inp), target):
			return true
	return false
