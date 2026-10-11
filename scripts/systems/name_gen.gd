class_name NameGen
extends RefCounted
## Dinamik yemek isimleri.
## - 1-2 temel malzemeli karışımlar: malzemeleri anan açıklayıcı isim ("Acı Biberli Limonlu Cips").
## - 3+ temel malzemeli karışımlar: malzemeleri saymayan, karaktere dayalı hikâyeli isim
##   ("Acı Ninja Hayalet") ve kısa bir efsane. Tablolar data/names.json içindedir, dile özeldir.
## Aynı kimlik her zaman aynı ismi üretir (seçimler kimliğin özetinden türetilir).

const STORY_MIN_BASES := 3


static func _L() -> Dictionary:
	var langs: Dictionary = IngredientDatabase.names.get("lang", {})
	var l: Dictionary = langs.get(Loc.lang, {})
	if l.is_empty():
		l = langs.get("en", langs.get("tr", {}))
	return l


static func _pick(arr: Array, h: int, salt: int) -> Variant:
	if arr.is_empty():
		return ""
	return arr[((h >> (salt % 24)) ^ (salt * 2654435761)) % arr.size()]


## Kelime girdisi düz metin ya da {"t": metin, "g": cinsiyet} olabilir.
static func _word(v: Variant) -> Array:
	if v is Dictionary:
		return [str(v.get("t", "")), str(v.get("g", "m"))]
	return [str(v), "m"]


## Sıfat girdisi düz metin ya da {"m": .., "f": .., "n": ..} olabilir.
static func _adj_form(v: Variant, g: String) -> String:
	if v is Dictionary:
		return str(v.get(g, v.get("m", "")))
	return str(v)


## Sıfatı belirleyen baskın istatistik.
static func adj_stat(stats: Dictionary) -> String:
	var w: Dictionary = IngredientDatabase.names.get("adj_weights", {})
	var best := "weird"
	var bv := -1.0
	for k in ["spicy", "sweet", "toxic", "magic", "weird", "volatile", "fresh", "life"]:
		var v := float(stats.get(k, 0.0)) * float(w.get(k, 1.0))
		if v > bv:
			bv = v
			best = k
	return best


static func _persona_tag(tags: Array) -> String:
	for t in IngredientDatabase.names.get("persona_priority", []):
		if tags.has(t):
			return t
	return "default"


static func _role_tag(tags: Array, persona_tag: String) -> String:
	var same := {"robot": "mechanical", "mechanical": "robot"}
	for t in IngredientDatabase.names.get("role_priority", []):
		if t == persona_tag or same.get(persona_tag, "") == t:
			continue
		if tags.has(t):
			return t
	return "default"


## Hikâyeli isim ve efsane. Döndürür: {name, lore, persona_tag}
static func story(id: String, stats: Dictionary, tags: Array) -> Dictionary:
	var L := _L()
	var h := FusionEngine.fnv("story:" + id)
	var ptag := _persona_tag(tags)
	var rtag := _role_tag(tags, ptag)
	var astat := adj_stat(stats)
	var personas: Dictionary = L.get("persona", {})
	var pw := _word(_pick(personas.get(ptag, personas.get("default", ["?"])), h, 1))
	var roles: Dictionary = L.get("role", {})
	var role := str(_pick(roles.get(rtag, roles.get("default", [""])), h, 5))
	if role == pw[0]:
		role = str(_pick(roles.get("default", [""]), h, 7))
	var adjs: Dictionary = L.get("adj", {})
	var adj := _adj_form(_pick(adjs.get(astat, ["?"]), h, 3), pw[1])
	var seq := str(_pick(L.get("sequel", [""]), h, 9))
	var tpl := _weighted_template(L.get("templates", [{"w": 1, "t": "{adj} {persona}"}]), h)
	var name := tpl.replace("{adj}", adj).replace("{role}", role).replace("{persona}", pw[0]).replace("{sequel}", seq)
	name = name.strip_edges().replace("  ", " ")
	var origins: Dictionary = L.get("origin", {})
	var okey := ptag if origins.has(ptag) else ("robot" if ptag == "mechanical" and origins.has("robot") else "default")
	var origin := str(_pick(origins.get(okey, [""]), h, 11))
	var effects: Dictionary = L.get("effect", {})
	var effect := str(_pick(effects.get(astat, [""]), h, 13))
	var lore := str(L.get("lore", "{origin} {effect}")).replace("{origin}", origin).replace("{effect}", effect)
	return {"name": name, "lore": lore.strip_edges(), "persona_tag": ptag}


static func _weighted_template(tpls: Array, h: int) -> String:
	var total := 0
	for t in tpls:
		total += int(t.get("w", 1))
	if total <= 0:
		return "{adj} {persona}"
	var roll := (h >> 3) % total
	for t in tpls:
		roll -= int(t.get("w", 1))
		if roll < 0:
			return str(t.get("t", "{adj} {persona}"))
	return str(tpls[0].get("t", "{adj} {persona}"))


## 1-2 malzemeli pişmiş yemek ismi. main/second: eşya sözlükleri, dish: yöntem yemek adı (çevrilmiş).
static func simple_dish(main: Dictionary, second: Dictionary, dish: String) -> String:
	if Loc.lang == "tr":
		var adjs: Array = [main["adj"]]
		if second["id"] != main["id"]:
			adjs.append(second["adj"])
		var cand := " ".join(PackedStringArray(adjs)) + " " + dish
		if cand.split(" ").size() > 4:
			cand = str(main["adj"]) + " " + dish
		return cand
	var L := _L()
	dish = str(L.get("dish", {}).get(dish, Loc.t(dish)))
	var a := _short(main)
	if second["id"] == main["id"]:
		return str(L.get("dish1", "{a} {dish}")).replace("{a}", a).replace("{dish}", dish)
	return str(L.get("dish2", "{a} & {b} {dish}")).replace("{a}", a).replace("{b}", _short(second)).replace("{dish}", dish)


## 1-2 malzemeli (pişirilmemiş) füzyon ismi. ordered: ana malzeme ilk sırada.
static func simple_fusion(ordered: Array) -> String:
	var main: Dictionary = ordered[0]
	var second: Dictionary = ordered[1] if ordered.size() > 1 else main
	if Loc.lang == "tr":
		var parts: Array = []
		for k in range(ordered.size() - 1, 0, -1):
			parts.append(ordered[k]["adj"])
		parts.append(main["noun"])
		var cand := " ".join(PackedStringArray(parts))
		if cand.split(" ").size() > 4:
			cand = str(second["adj"]) + " " + str(main["noun"])
		return cand
	if second["id"] == main["id"]:
		return _short(main)
	var L := _L()
	return str(L.get("fusion2", "{b} {main}")).replace("{b}", _short(second)).replace("{main}", _short(main))


static func _short(it: Dictionary) -> String:
	return str(it.get("name", "?"))


## Sabotajla lanetlenmiş yemek adı.
static func cursed(name: String) -> String:
	var pat := str(_L().get("cursed", "{name}")) if Loc.lang != "tr" else "Lanetli {name}"
	return pat.replace("{name}", name)


## Fermente malzeme karışmış yemek adı.
static func tainted(name: String, ing: Dictionary) -> String:
	if Loc.lang == "tr":
		return str(ing.get("adj", "")) + " " + name
	return str(_L().get("tainted", "{name} + {ing}")).replace("{name}", name).replace("{ing}", str(ing.get("name", "")))
