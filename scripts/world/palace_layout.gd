class_name PalaceLayout
extends RefCounted
## Sarayın mimari planı: odalar, kapılar ve bağlantılar.
## Koordinatlar metre cinsindendir. X doğu, Z güney yönüdür.

const WALL_T := 0.35

## kind: "room" (kapalı), "corridor" (revak/koridor), "outdoor" (açık hava)
## ceiling: "flat", "dome", "none"
## sides: her kenar için "wall" (varsayılan), "none", "low", "outer" ya da [[başlangıç, bitiş, tür], ...]
const ROOMS := {
	"kutuphane": {"name": "Saray Kütüphanesi", "short": "Kütüphane", "rect": [-60, -55, -38, -33], "h": 7.0, "kind": "room", "ceiling": "flat", "floor": "wood_floor", "dado": "iznik_blue", "cat": "ilim", "anchor": [-49, -36]},
	"hukumdar": {"name": "Hükümdarın Özel Dairesi", "short": "Özel Daire", "rect": [-38, -55, -14, -33], "h": 7.5, "kind": "room", "ceiling": "flat", "floor": "marble_floor", "dado": "iznik", "cat": "ozel", "anchor": [-26, -36]},
	"taht": {"name": "Taht Salonu", "short": "Taht Salonu", "rect": [-14, -55, 14, -33], "h": 9.0, "kind": "room", "ceiling": "dome", "floor": "marble_floor", "dado": "iznik", "cat": "devlet", "anchor": [0, -37]},
	"valide": {"name": "Valide Sultan Dairesi", "short": "Valide Dairesi", "rect": [14, -55, 36, -33], "h": 7.5, "kind": "room", "ceiling": "dome", "floor": "marble_floor", "dado": "iznik_green", "cat": "harem", "anchor": [25, -36]},
	"sehzade": {"name": "Şehzadelerin Eğitim Odaları", "short": "Şehzade Odaları", "rect": [36, -55, 60, -33], "h": 7.0, "kind": "room", "ceiling": "flat", "floor": "wood_floor", "dado": "iznik_blue", "cat": "aile", "anchor": [48, -36]},
	"koridor_k": {"name": "Kuzey Revakı", "short": "Kuzey Revakı", "rect": [-60, -33, 60, -28], "h": 5.0, "kind": "corridor", "ceiling": "flat", "floor": "marble_floor", "dado": "iznik", "cat": "koridor", "anchor": [0, -30.5],
		"sides": {"s": [[-60, -30, "wall"], [-30, -24, "none"], [-24, 24, "arcade"], [24, 30, "none"], [30, 60, "wall"]]}},
	"divan": {"name": "Divan Salonu", "short": "Divan", "rect": [-60, -28, -30, -8], "h": 8.0, "kind": "room", "ceiling": "dome", "floor": "marble_floor", "dado": "iznik", "cat": "devlet", "anchor": [-34, -18]},
	"hazine": {"name": "Hazine Dairesi", "short": "Hazine", "rect": [-60, -8, -30, 14], "h": 7.0, "kind": "room", "ceiling": "flat", "floor": "marble_dark_floor", "dado": "iznik_blue", "cat": "devlet", "anchor": [-34, 3]},
	"koridor_b": {"name": "Batı Revakı", "short": "Batı Revakı", "rect": [-30, -28, -24, 14], "h": 5.0, "kind": "corridor", "ceiling": "flat", "floor": "marble_floor", "dado": "iznik", "cat": "koridor", "anchor": [-27, -7],
		"sides": {"n": "none", "s": "none", "e": "arcade"}},
	"avlu": {"name": "Ana Saray Avlusu", "short": "Avlu", "rect": [-24, -28, 24, 14], "h": 0.0, "kind": "outdoor", "ceiling": "none", "floor": "paving", "cat": "acik", "anchor": [0, 6],
		"sides": {"n": "none", "s": "none", "e": "none", "w": "none"}},
	"koridor_d": {"name": "Doğu Revakı", "short": "Doğu Revakı", "rect": [24, -28, 30, 14], "h": 5.0, "kind": "corridor", "ceiling": "flat", "floor": "marble_floor", "dado": "iznik", "cat": "koridor", "anchor": [27, -7],
		"sides": {"n": "none", "s": "none", "w": "arcade"}},
	"harem": {"name": "Harem Ortak Alanı", "short": "Harem", "rect": [30, -28, 60, -8], "h": 8.0, "kind": "room", "ceiling": "dome", "floor": "marble_floor", "dado": "iznik_green", "cat": "harem", "anchor": [34, -18]},
	"leyla": {"name": "Leyla Sultan Dairesi", "short": "Leyla'nın Odası", "rect": [30, -8, 45, 14], "h": 6.5, "kind": "room", "ceiling": "flat", "floor": "wood_floor", "dado": "iznik_blue", "cat": "harem", "anchor": [37.5, -4]},
	"feraye": {"name": "Feraye Sultan Dairesi", "short": "Feraye'nin Odası", "rect": [45, -8, 60, 14], "h": 6.5, "kind": "room", "ceiling": "flat", "floor": "wood_floor", "dado": "iznik", "cat": "harem", "anchor": [52.5, -4]},
	"koridor_g": {"name": "Güney Revakı", "short": "Güney Revakı", "rect": [-60, 14, 60, 19], "h": 5.0, "kind": "corridor", "ceiling": "flat", "floor": "marble_floor", "dado": "iznik", "cat": "koridor", "anchor": [0, 16.5],
		"sides": {"n": [[-60, -30, "wall"], [-30, -24, "none"], [-24, 24, "arcade"], [24, 30, "none"], [30, 60, "wall"]]}},
	"elci": {"name": "Elçi Kabul Salonu", "short": "Elçi Salonu", "rect": [-60, 19, -38, 41], "h": 8.0, "kind": "room", "ceiling": "dome", "floor": "marble_floor", "dado": "iznik", "cat": "devlet", "anchor": [-49, 22]},
	"halk": {"name": "Halk Kabul Salonu", "short": "Halk Kabul", "rect": [-38, 19, -16, 41], "h": 7.0, "kind": "room", "ceiling": "flat", "floor": "marble_floor", "dado": "iznik_blue", "cat": "devlet", "anchor": [-27, 22]},
	"muhafiz": {"name": "Saray Muhafız Alanı", "short": "Muhafızlar", "rect": [-16, 19, -4, 41], "h": 6.0, "kind": "room", "ceiling": "flat", "floor": "paving_in", "dado": "", "cat": "hizmet", "anchor": [-10, 22]},
	"gecit": {"name": "Bahçe Geçidi", "short": "Bahçe Geçidi", "rect": [-4, 19, 4, 41], "h": 5.0, "kind": "corridor", "ceiling": "flat", "floor": "marble_floor", "dado": "iznik", "cat": "koridor", "anchor": [0, 30],
		"sides": {"n": "none", "s": "none"}},
	"mutfak": {"name": "Mutfak ve Yemek Salonu", "short": "Mutfak", "rect": [4, 19, 30, 41], "h": 7.0, "kind": "room", "ceiling": "flat", "floor": "paving_in", "dado": "", "cat": "hizmet", "anchor": [17, 22]},
	"harem_bahce": {"name": "Harem Bahçesi", "short": "Harem Bahçesi", "rect": [30, 19, 60, 41], "h": 0.0, "kind": "outdoor", "ceiling": "none", "floor": "grass", "cat": "acik", "anchor": [45, 23],
		"sides": {"n": "none", "w": "none", "e": "outer", "s": "low"}},
	"bahce": {"name": "Saray Bahçeleri", "short": "Bahçeler", "rect": [-60, 41, 60, 80], "h": 0.0, "kind": "outdoor", "ceiling": "none", "floor": "grass", "cat": "acik", "anchor": [0, 46],
		"sides": {"n": "none", "w": "outer", "e": "outer", "s": "low"}},
}

## axis "z": kapı z=at hattı üzerinde, x ekseninde c merkezli. axis "x": x=at hattı üzerinde, z ekseninde.
const DOORS := [
	{"a": "kutuphane", "b": "koridor_k", "axis": "z", "at": -33, "c": -49, "w": 2.6},
	{"a": "hukumdar", "b": "koridor_k", "axis": "z", "at": -33, "c": -26, "w": 2.6},
	{"a": "kutuphane", "b": "hukumdar", "axis": "x", "at": -38, "c": -44, "w": 2.2},
	{"a": "hukumdar", "b": "taht", "axis": "x", "at": -14, "c": -49, "w": 2.2},
	{"a": "taht", "b": "koridor_k", "axis": "z", "at": -33, "c": 0, "w": 4.0},
	{"a": "valide", "b": "koridor_k", "axis": "z", "at": -33, "c": 25, "w": 2.6},
	{"a": "valide", "b": "sehzade", "axis": "x", "at": 36, "c": -44, "w": 2.2},
	{"a": "sehzade", "b": "koridor_k", "axis": "z", "at": -33, "c": 48, "w": 2.6},
	{"a": "divan", "b": "koridor_k", "axis": "z", "at": -28, "c": -45, "w": 3.0},
	{"a": "divan", "b": "koridor_b", "axis": "x", "at": -30, "c": -18, "w": 3.0},
	{"a": "hazine", "b": "koridor_b", "axis": "x", "at": -30, "c": 3, "w": 2.6},
	{"a": "koridor_k", "b": "koridor_b", "axis": "z", "at": -28, "c": -27, "w": 6.0},
	{"a": "koridor_k", "b": "koridor_d", "axis": "z", "at": -28, "c": 27, "w": 6.0},
	{"a": "koridor_g", "b": "koridor_b", "axis": "z", "at": 14, "c": -27, "w": 6.0},
	{"a": "koridor_g", "b": "koridor_d", "axis": "z", "at": 14, "c": 27, "w": 6.0},
	{"a": "harem", "b": "koridor_d", "axis": "x", "at": 30, "c": -18, "w": 3.0},
	{"a": "harem", "b": "leyla", "axis": "z", "at": -8, "c": 37.5, "w": 2.2},
	{"a": "harem", "b": "feraye", "axis": "z", "at": -8, "c": 52.5, "w": 2.2},
	{"a": "elci", "b": "koridor_g", "axis": "z", "at": 19, "c": -49, "w": 3.0},
	{"a": "halk", "b": "koridor_g", "axis": "z", "at": 19, "c": -27, "w": 3.0},
	{"a": "elci", "b": "halk", "axis": "x", "at": -38, "c": 30, "w": 2.2},
	{"a": "muhafiz", "b": "koridor_g", "axis": "z", "at": 19, "c": -10, "w": 2.6},
	{"a": "muhafiz", "b": "halk", "axis": "x", "at": -16, "c": 30, "w": 2.2},
	{"a": "muhafiz", "b": "gecit", "axis": "x", "at": -4, "c": 30, "w": 2.2},
	{"a": "gecit", "b": "koridor_g", "axis": "z", "at": 19, "c": 0, "w": 8.0},
	{"a": "mutfak", "b": "koridor_g", "axis": "z", "at": 19, "c": 17, "w": 3.0},
	{"a": "mutfak", "b": "gecit", "axis": "x", "at": 4, "c": 30, "w": 2.2},
	{"a": "mutfak", "b": "harem_bahce", "axis": "x", "at": 30, "c": 34, "w": 2.6},
	{"a": "harem_bahce", "b": "koridor_g", "axis": "z", "at": 19, "c": 45, "w": 3.0},
	{"a": "harem_bahce", "b": "bahce", "axis": "z", "at": 41, "c": 45, "w": 3.0},
	{"a": "gecit", "b": "bahce", "axis": "z", "at": 41, "c": 0, "w": 8.0},
]

const CAT_COLORS := {
	"devlet": Color(0.62, 0.22, 0.2),
	"harem": Color(0.55, 0.3, 0.5),
	"ozel": Color(0.7, 0.55, 0.22),
	"aile": Color(0.3, 0.45, 0.65),
	"ilim": Color(0.25, 0.42, 0.55),
	"hizmet": Color(0.45, 0.4, 0.32),
	"koridor": Color(0.35, 0.36, 0.42),
	"acik": Color(0.25, 0.48, 0.3),
}

## Haritada gösterilecek sıralı oda listesi (koridorlar hariç)
const MAP_ORDER := ["taht", "divan", "hukumdar", "kutuphane", "valide", "sehzade", "harem", "leyla", "feraye", "hazine", "avlu", "elci", "halk", "muhafiz", "mutfak", "harem_bahce", "bahce", "gecit"]


static func room_ids() -> Array:
	return ROOMS.keys()


static func has_room(id: String) -> bool:
	return ROOMS.has(id)


static func room_name(id: String) -> String:
	if ROOMS.has(id):
		return ROOMS[id]["name"]
	if id == "disari":
		return "Saray Dışında"
	return "Bilinmeyen"


static func room_short(id: String) -> String:
	if ROOMS.has(id):
		return ROOMS[id]["short"]
	if id == "disari":
		return "Saray Dışı"
	return "?"


static func rect(id: String) -> Rect2:
	var r: Array = ROOMS[id]["rect"]
	return Rect2(Vector2(r[0], r[1]), Vector2(r[2] - r[0], r[3] - r[1]))


static func anchor(id: String) -> Vector3:
	if not ROOMS.has(id):
		return Vector3(0, 0, 6)
	var a: Array = ROOMS[id]["anchor"]
	return Vector3(a[0], 0.0, a[1])


static func is_outdoor(id: String) -> bool:
	return ROOMS.has(id) and ROOMS[id]["kind"] == "outdoor"


static func room_at(x: float, z: float) -> String:
	for id in ROOMS.keys():
		var r: Array = ROOMS[id]["rect"]
		if x >= r[0] and x <= r[2] and z >= r[1] and z <= r[3]:
			return id
	return ""


static func room_at_v(p: Vector3) -> String:
	return room_at(p.x, p.z)


## Bir odanın belirli kenarındaki aralıkları döndürür: [[a, b, tür], ...]
static func side_spans(id: String, side: String) -> Array:
	var room: Dictionary = ROOMS[id]
	var r: Array = room["rect"]
	var a := 0.0
	var b := 0.0
	if side == "n" or side == "s":
		a = r[0]
		b = r[2]
	else:
		a = r[1]
		b = r[3]
	var default_type := "wall"
	if room.has("sides") and room["sides"].has(side):
		var s = room["sides"][side]
		if s is Array:
			var out: Array = []
			for span in s:
				out.append([float(span[0]), float(span[1]), String(span[2])])
			return out
		default_type = String(s)
	return [[a, b, default_type]]


## Belirli bir hat üzerindeki kapılar
static func doors_on_line(axis: String, at: float, from_v: float, to_v: float) -> Array:
	var out: Array = []
	for d in DOORS:
		if d["axis"] == axis and absf(float(d["at"]) - at) < 0.01:
			var c := float(d["c"])
			if c > from_v - 0.01 and c < to_v + 0.01:
				out.append(d)
	out.sort_custom(func(x, y): return float(x["c"]) < float(y["c"]))
	return out


static func door_between(a: String, b: String) -> Dictionary:
	for d in DOORS:
		if (d["a"] == a and d["b"] == b) or (d["a"] == b and d["b"] == a):
			return d
	return {}


static func door_point(d: Dictionary) -> Vector3:
	if d["axis"] == "z":
		return Vector3(float(d["c"]), 0, float(d["at"]))
	return Vector3(float(d["at"]), 0, float(d["c"]))


## Odalar arası komşuluk grafiği (kapılar + revak bağlantıları)
static func neighbors(id: String) -> Array:
	var out: Array = []
	for d in DOORS:
		if d["a"] == id:
			out.append(d["b"])
		elif d["b"] == id:
			out.append(d["a"])
	# Avlu revaklara açık
	if id == "avlu":
		out.append_array(["koridor_k", "koridor_b", "koridor_d", "koridor_g"])
	elif id in ["koridor_k", "koridor_b", "koridor_d", "koridor_g"]:
		out.append("avlu")
	return out


## Basit genişlik öncelikli yol (oda kimlikleri listesi)
static func room_path(from_id: String, to_id: String) -> Array:
	if from_id == to_id:
		return [from_id]
	var prev := {from_id: ""}
	var queue: Array = [from_id]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		for n in neighbors(cur):
			if not prev.has(n):
				prev[n] = cur
				if n == to_id:
					var path: Array = [n]
					var p: String = cur
					while p != "":
						path.push_front(p)
						p = prev[p]
					return path
				queue.append(n)
	return [from_id, to_id]


## İki oda arasındaki yürüme mesafesinin kabaca tahmini (metre)
static func travel_distance(from_id: String, to_id: String) -> float:
	var path := room_path(from_id, to_id)
	var dist := 0.0
	for i in range(path.size() - 1):
		dist += anchor(path[i]).distance_to(anchor(path[i + 1]))
	return dist
