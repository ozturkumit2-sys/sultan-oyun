class_name GameWorld
extends Node
## Oyun dünyasının tüm kalıcı durumu, takvim ve simülasyon saati.
## Kayda giren her şey `w` sözlüğündedir.

signal time_ticked
signal hour_changed(hour: int)
signal day_changed(day: int)
signal month_changed(report: Dictionary)
signal stats_changed
signal relation_changed(a: String, b: String, applied: Dictionary)
signal notify(text: String, kind: String)
signal events_changed
signal log_added(entry: Dictionary)
signal speed_changed(idx: int)
signal schedules_updated
signal time_jumped
signal game_started
signal character_added(id: String)
signal character_removed(id: String)

const PLAYER := "sultan"
const SAVE_VERSION := 1
const GAME_VERSION := "0.3.0"
const SPEEDS := [0.0, 2.0, 6.0, 20.0]
const SPEED_LABELS := ["II", "1x", "3x", "10x"]
const DAYS_PER_MONTH := 30
const MONTHS := ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
const START_YEAR := 912
const CAL_OFFSET := 104   # oyun 15 Nisan'da başlar
const START_MINUTES := 8 * 60 + 20

const REL_DIMS := ["sevgi", "guven", "saygi", "korku", "kiskanclik", "rekabet", "siyasi_uyum", "borcluluk", "arkadaslik", "romantik"]
const REL_NAMES := {
	"sevgi": "Sevgi", "guven": "Güven", "saygi": "Saygı", "korku": "Korku", "kiskanclik": "Kıskançlık",
	"rekabet": "Rekabet", "siyasi_uyum": "Siyasi Uyum", "borcluluk": "Minnet", "arkadaslik": "Dostluk", "romantik": "Gönül Bağı",
}
const REL_DEFAULT := {"sevgi": 40.0, "guven": 40.0, "saygi": 50.0, "korku": 10.0, "kiskanclik": 0.0, "rekabet": 0.0, "siyasi_uyum": 50.0, "borcluluk": 0.0, "arkadaslik": 20.0, "romantik": 0.0}

var w: Dictionary = {}
var active := false
var speed_idx := 1
var _pauses := {}
var _accum := 0.0
var rng := RandomNumberGenerator.new()
var player_room := "avlu"
var player_pos := Vector3(0, 0, 6)
var player_yaw := 0.0
var _id_counter := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()


# ================================================================ yeni oyun

func new_game(sultan_name: String, difficulty: int = 1) -> void:
	rng.randomize()
	w = {}
	w["meta"] = {"save_version": SAVE_VERSION, "game_version": GAME_VERSION, "seed": rng.randi(), "difficulty": difficulty, "created": Time.get_datetime_string_from_system()}
	w["time"] = START_MINUTES
	w["id_counter"] = 0
	var player: Dictionary = CharactersData.PLAYER_DEFAULT.duplicate(true)
	player["name"] = sultan_name
	player["full"] = "Sultan " + sultan_name
	player["alive"] = true
	player["location"] = "avlu"
	player["married_to"] = []
	player["memories"] = []
	w["characters"] = {PLAYER: player}
	for id in CharactersData.CHARACTERS.keys():
		w["characters"][id] = make_static_char(id)
	w["relations"] = {}
	for seed_rel in CharactersData.REL_SEEDS:
		set_rel_values(seed_rel[0], seed_rel[1], seed_rel[2])
	for id2 in CharactersData.PLAYER_RELS.keys():
		set_rel_values(id2, PLAYER, CharactersData.PLAYER_RELS[id2])
	var posts := {}
	for p in CharactersData.POSTS.keys():
		posts[p] = CharactersData.POSTS[p]["holder"]
	w["posts"] = posts
	var provs: Array = ProvincesData.PROVINCES.duplicate(true)
	for p2 in provs:
		p2["exempt_until"] = -1
		p2["ambar"] = 0
		p2["drought"] = int(p2.get("drought", 0))
		if difficulty == 2:
			p2["huzur"] = float(p2["huzur"]) - 8.0
			p2["gida"] = float(p2["gida"]) * 0.8
		elif difficulty == 0:
			p2["huzur"] = float(p2["huzur"]) + 6.0
	w["provinces"] = provs
	w["neighbors"] = ProvincesData.NEIGHBORS.duplicate(true)
	w["state"] = {
		"treasury": [240000.0, 160000.0, 95000.0][clampi(difficulty, 0, 2)],
		"tax_level": 2, "palace_level": 1, "army_level": 1, "food_price": 1.0,
		"prestige": 55.0, "legitimacy": 62.0, "justice": 55.0, "people_rep": 55.0,
		"history": [], "last_report": {}, "last_month": cal_month_index(),
	}
	w["modifiers"] = []
	w["projects"] = []
	w["events"] = {"pending": [], "scheduled": [], "history": [], "fired": {}, "cooldown": {}}
	w["divan"] = {"agenda": [], "next_refresh": 0, "decided": []}
	w["petitions"] = {"list": [], "next_refresh": 0, "heard": 0}
	w["log"] = []
	w["npc_log"] = []
	w["lore"] = {}
	w["flags"] = {}
	w["dialogue"] = {"recent": {}, "today": {}, "last_talk": {}}
	w["tasks"] = []
	w["dynasty"] = {"name": "Zehrâni", "rulers": [{"name": sultan_name, "from_day": 0}], "history": [{"day": 0, "text": "Sultan %s tahta çıktı." % sultan_name}]}
	w["harem"] = HaremEngine.default_data()
	w["crimes"] = JusticeEngine.default_data()
	w["player"] = {"pos": [0.0, 0.0, 6.0], "yaw": 0.0, "room": "avlu", "books": 0}
	player_pos = Vector3(0, 0, 6)
	player_yaw = 0.0
	player_room = "avlu"
	_pauses.clear()
	speed_idx = 1
	active = true
	update_all_schedules()
	EventEngine.on_new_game(self)
	DivanEngine.refresh_agenda(self, true)
	PetitionEngine.refresh(self, true)
	add_log("Sultan %s, Zehrâni tahtına çıktı. Saltanatın ilk günü başladı." % sultan_name, "hanedan", 1)
	game_started.emit()


## Başlangıç karakter tablosundan oyun içi karakter kaydı üretir (yeni oyun ve eski kayıt göçü).
func make_static_char(id: String) -> Dictionary:
	var c: Dictionary = (CharactersData.CHARACTERS[id] as Dictionary).duplicate(true)
	c["id"] = id
	c["alive"] = true
	c["mood"] = _base_mood(c)
	c["needs"] = {"enerji": 80.0, "tokluk": 70.0, "sosyal": 60.0}
	c["memories"] = []
	c["location"] = c["home"]
	c["activity"] = "gorev"
	c["married_to"] = []
	c["haunts"] = SchedulesData.HAUNTS.get(id, [])
	c["romanceable"] = c.get("romanceable", false)
	c["serves"] = c.get("serves", "")
	c["office"] = c.get("office", c["home"])
	return c


func _base_mood(c: Dictionary) -> float:
	var t: Dictionary = c["traits"]
	return clampf(10.0 + (float(t["ozguven"]) - 50.0) * 0.2 + (float(t["sabir"]) - 50.0) * 0.15 - (float(t["kiskanclik"]) - 50.0) * 0.15, -40.0, 40.0)


## Oyun sırasında yeni karakter ekler (harem, eş, çocuk...). Eksik alanları doldurur.
func add_character(proto: Dictionary, id_prefix: String = "h") -> String:
	var id := next_id(id_prefix)
	var c: Dictionary = proto.duplicate(true)
	c["id"] = id
	c["alive"] = true
	if not c.has("traits"):
		c["traits"] = {}
	for t in CharactersData.TRAIT_NAMES.keys():
		if not c["traits"].has(t):
			c["traits"][t] = 50
	if not c.has("skills"):
		c["skills"] = {}
	for s in CharactersData.SKILL_NAMES.keys():
		if not c["skills"].has(s):
			c["skills"][s] = 20
	for k in ["goals", "fears", "likes", "lore", "memories", "married_to", "haunts"]:
		if not c.has(k):
			c[k] = []
	for k2 in ["secret_goal", "bio", "post", "serves"]:
		if not c.has(k2):
			c[k2] = ""
	c["mood"] = c.get("mood", _base_mood(c))
	c["needs"] = {"enerji": 80.0, "tokluk": 70.0, "sosyal": 60.0}
	c["location"] = c.get("home", "avlu")
	c["activity"] = "dinlenme"
	c["office"] = c.get("office", c.get("home", "avlu"))
	c["romanceable"] = c.get("romanceable", false)
	c["born_day"] = get_day() - int(c.get("age", 0)) * 360
	w["characters"][id] = c
	var pr: Dictionary = c.get("rel_to_player", {})
	if not pr.is_empty():
		set_rel_values(id, PLAYER, pr)
		c.erase("rel_to_player")
	c["location"] = plan_for(id, get_hour())["room"]
	character_added.emit(id)
	schedules_updated.emit()
	return id


## Karakteri hayattan çıkarır (ölüm / idam). Makamı ve evliliği boşalır.
func kill_character(id: String, text: String = "", kind: String = "saray") -> void:
	var c := ch(id)
	if c.is_empty() or id == PLAYER:
		return
	c["alive"] = false
	c["death_day"] = get_day()
	var post := post_of(id)
	if post != "":
		w["posts"][post] = ""
	var wives: Array = player().get("married_to", [])
	if id in wives:
		wives.erase(id)
	c["location"] = "disari"
	c["activity"] = "disarida"
	if text != "":
		add_log(text, kind, 2)
	character_removed.emit(id)
	schedules_updated.emit()


func is_child(id: String) -> bool:
	var c := ch(id)
	return String(c.get("role", "")) == "child" and int(c.get("age", 0)) < 16


## Sosyal simülasyona ve kulise katılan yetişkinler
func social_ids() -> Array:
	var out: Array = []
	for id in npc_ids():
		if int(ch(id).get("age", 30)) >= 14:
			out.append(id)
	return out


func next_id(prefix: String = "x") -> String:
	w["id_counter"] = int(w.get("id_counter", 0)) + 1
	return "%s%d" % [prefix, int(w["id_counter"])]


# ================================================================ zaman

func _process(delta: float) -> void:
	if not active or is_paused():
		return
	var spd: float = SPEEDS[speed_idx]
	_accum += delta * spd
	if _accum >= 1.0:
		var m := int(_accum)
		_accum -= m
		advance_minutes(m)


func push_pause(reason: String) -> void:
	_pauses[reason] = true


func pop_pause(reason: String) -> void:
	_pauses.erase(reason)


func clear_pauses() -> void:
	_pauses.clear()


func is_paused() -> bool:
	return not _pauses.is_empty() or speed_idx == 0


func set_speed(i: int) -> void:
	speed_idx = clampi(i, 0, SPEEDS.size() - 1)
	speed_changed.emit(speed_idx)


func advance_minutes(m: int, jump: bool = false) -> void:
	if m <= 0:
		return
	var t0 := total_minutes()
	var t1 := t0 + m
	var cur := t0
	while true:
		var next_hour_t := (cur / 60 + 1) * 60
		if next_hour_t > t1:
			break
		w["time"] = next_hour_t
		_on_hour()
		cur = next_hour_t
	w["time"] = t1
	time_ticked.emit()
	if jump:
		time_jumped.emit()


func skip_to_hour(target_hour: int) -> int:
	var h := get_hour()
	var mins := (target_hour - h) * 60 - get_minute()
	if mins <= 0:
		mins += 24 * 60
	advance_minutes(mins, true)
	return mins


func total_minutes() -> int:
	return int(w.get("time", 0))


func get_day() -> int:
	return total_minutes() / 1440


func get_hour() -> int:
	return (total_minutes() % 1440) / 60


func get_minute() -> int:
	return total_minutes() % 60


func hour_f() -> float:
	return float(total_minutes() % 1440) / 60.0


func cal_day() -> int:
	return get_day() + CAL_OFFSET


func cal_month_index() -> int:
	return cal_day() / DAYS_PER_MONTH


func get_month() -> int:
	return cal_month_index() % 12


func get_year() -> int:
	return START_YEAR + cal_day() / (DAYS_PER_MONTH * 12)


func day_of_month() -> int:
	return cal_day() % DAYS_PER_MONTH + 1


func weekday() -> int:
	return get_day() % 7


func is_divan_day() -> bool:
	return weekday() in SchedulesData.DIVAN_DAYS


func date_string() -> String:
	return "%d %s %d" % [day_of_month(), MONTHS[get_month()], get_year()]


func time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]


func weekday_name() -> String:
	return SchedulesData.WEEKDAYS[weekday()]


func day_part() -> String:
	var h := get_hour()
	if h >= 5 and h < 11:
		return "sabah"
	if h >= 11 and h < 17:
		return "gun"
	if h >= 17 and h < 21:
		return "aksam"
	return "gece"


func _on_hour() -> void:
	var h := get_hour()
	if h == 0:
		_on_day()
	update_all_schedules()
	_update_needs()
	SocialSim.hourly(self)
	EventEngine.hourly(self)
	HaremEngine.hourly(self)
	hour_changed.emit(h)


func _on_day() -> void:
	var day := get_day()
	if cal_day() % (DAYS_PER_MONTH * 12) == 0:
		for id in w["characters"].keys():
			if w["characters"][id].get("alive", true):
				w["characters"][id]["age"] = int(w["characters"][id]["age"]) + 1
		HaremEngine.yearly(self)
	_decay_memories()
	_drift_moods()
	_expire_modifiers()
	w["dialogue"]["today"] = {}
	if cal_month_index() != int(w["state"].get("last_month", -1)):
		w["state"]["last_month"] = cal_month_index()
		var report := Economy.monthly_tick(self)
		month_changed.emit(report)
	EventEngine.daily(self)
	HaremEngine.daily(self)
	JusticeEngine.daily(self)
	DivanEngine.daily(self)
	PetitionEngine.daily(self)
	day_changed.emit(day)
	stats_changed.emit()


func _update_needs() -> void:
	for id in npc_ids():
		var c: Dictionary = w["characters"][id]
		var n: Dictionary = c["needs"]
		var act: String = c["activity"]
		if act == "uyku":
			n["enerji"] = minf(100.0, float(n["enerji"]) + 11.0)
		else:
			n["enerji"] = maxf(0.0, float(n["enerji"]) - 4.0)
		if act in ["yemek", "kahvalti"]:
			n["tokluk"] = minf(100.0, float(n["tokluk"]) + 45.0)
		else:
			n["tokluk"] = maxf(0.0, float(n["tokluk"]) - 4.0)
		if act in ["sohbet", "yemek", "kabul"]:
			n["sosyal"] = minf(100.0, float(n["sosyal"]) + 15.0)
		else:
			n["sosyal"] = maxf(0.0, float(n["sosyal"]) - 2.0 * (float(c["traits"]["sosyal"]) / 50.0))


func _drift_moods() -> void:
	for id in npc_ids():
		var c: Dictionary = w["characters"][id]
		var base := _base_mood(c)
		var n: Dictionary = c["needs"]
		var need_pen := 0.0
		for k in n.keys():
			if float(n[k]) < 25.0:
				need_pen += 6.0
		var mem_push := 0.0
		for m in c["memories"]:
			if not m.get("resolved", false):
				mem_push += float(m["emotion"]) * float(m["strength"]) * 0.04
		var target := clampf(base + mem_push - need_pen, -100.0, 100.0)
		c["mood"] = lerpf(float(c["mood"]), target, 0.35)


func _decay_memories() -> void:
	for id in w["characters"].keys():
		var c: Dictionary = w["characters"][id]
		if not c.has("memories"):
			continue
		var keep: Array = []
		var t: Dictionary = c.get("traits", {})
		var grudge := 1.0 - float(t.get("merhamet", 50)) / 400.0
		for m in c["memories"]:
			var rate := 0.985 if float(m["emotion"]) >= 0 else 0.99 * grudge + 0.01
			if m.get("resolved", false):
				rate = 0.96
			m["strength"] = float(m["strength"]) * rate
			if float(m["strength"]) > 0.08:
				keep.append(m)
		c["memories"] = keep


func _expire_modifiers() -> void:
	var keep: Array = []
	for m in w["modifiers"]:
		if int(m["until"]) > get_day():
			keep.append(m)
	w["modifiers"] = keep


func sleep_until_morning() -> int:
	var mins := skip_to_hour(7)
	add_log("Hükümdar dinlendi; yeni bir gün başladı.", "zaman", 0)
	return mins


# ================================================================ karakterler

func ch(id: String) -> Dictionary:
	return w["characters"].get(id, {})


func player() -> Dictionary:
	return w["characters"][PLAYER]


func npc_ids() -> Array:
	var out: Array = []
	for id in w["characters"].keys():
		if id != PLAYER and w["characters"][id].get("alive", true) and not w["characters"][id].get("gone", false):
			out.append(id)
	return out


func full_name(id: String) -> String:
	var c := ch(id)
	if c.is_empty():
		return "?"
	return String(c.get("full", c["name"]))


func short_name(id: String) -> String:
	var c := ch(id)
	if c.is_empty():
		return "?"
	if id == PLAYER:
		return "Sultan " + String(c["name"])
	if c["role"] == "valide":
		return "Valide Sultan"
	var t: String = c.get("title", "")
	if t == "":
		return String(c["name"])
	if t in ["Kont", "Molla", "Şehzade"]:
		return t + " " + String(c["name"])
	return String(c["name"]) + " " + t


func title_of(id: String) -> String:
	var c := ch(id)
	var f: String = c.get("full", "")
	var n: String = c.get("name", "")
	var t := f.replace(n, "").strip_edges()
	return t


func chars_in_room(room: String, awake_only: bool = true) -> Array:
	var out: Array = []
	for id in npc_ids():
		var c: Dictionary = w["characters"][id]
		if c["location"] == room:
			if awake_only and c["activity"] in ["uyku", "disarida"]:
				continue
			out.append(id)
	return out


func witnesses(room: String, exclude: Array = []) -> Array:
	var out: Array = []
	for id in chars_in_room(room):
		if not id in exclude:
			out.append(id)
	return out


func mood_label(v: float) -> String:
	if v > 45:
		return "Neşeli"
	if v > 15:
		return "Huzurlu"
	if v > -15:
		return "Durgun"
	if v > -45:
		return "Endişeli"
	return "Öfkeli ve kırgın"


func adjust_mood(id: String, d: float) -> void:
	var c := ch(id)
	if c.is_empty() or id == PLAYER:
		return
	c["mood"] = clampf(float(c["mood"]) + d, -100.0, 100.0)


func trait_of(id: String, t: String) -> float:
	var c := ch(id)
	return float(c.get("traits", {}).get(t, 50))


func skill_of(id: String, s: String) -> float:
	var c := ch(id)
	return float(c.get("skills", {}).get(s, 30))


func post_of(id: String) -> String:
	for p in w["posts"].keys():
		if w["posts"][p] == id:
			return p
	return ""


func post_holder(post: String) -> String:
	return String(w["posts"].get(post, ""))


func is_married_to_player(id: String) -> bool:
	return id in player().get("married_to", [])


# ================================================================ ilişkiler

func rel(a: String, b: String) -> Dictionary:
	var k := a + ">" + b
	var rels: Dictionary = w["relations"]
	if not rels.has(k):
		rels[k] = REL_DEFAULT.duplicate()
	return rels[k]


func rel_val(a: String, b: String, dim: String) -> float:
	var k := a + ">" + b
	var rels: Dictionary = w["relations"]
	if rels.has(k):
		return float(rels[k].get(dim, REL_DEFAULT[dim]))
	return float(REL_DEFAULT[dim])


func set_rel_values(a: String, b: String, vals: Dictionary) -> void:
	var r := rel(a, b)
	for k in vals.keys():
		r[k] = clampf(float(vals[k]), 0.0, 100.0)


func rel_add(a: String, b: String, deltas: Dictionary, emit: bool = true) -> Dictionary:
	if a == b or ch(a).is_empty() or ch(b).is_empty():
		return {}
	var r := rel(a, b)
	var applied := {}
	for k in deltas.keys():
		var before := float(r.get(k, REL_DEFAULT.get(k, 0.0)))
		var after := clampf(before + float(deltas[k]), 0.0, 100.0)
		r[k] = after
		if absf(after - before) >= 0.5:
			applied[k] = after - before
	if emit and not applied.is_empty():
		relation_changed.emit(a, b, applied)
	return applied


func opinion(a: String, b: String) -> float:
	var r := rel(a, b)
	var v := float(r["sevgi"]) * 0.35 + float(r["guven"]) * 0.3 + float(r["saygi"]) * 0.25 + float(r["arkadaslik"]) * 0.1
	v -= float(r["kiskanclik"]) * 0.15 + float(r["rekabet"]) * 0.1 + float(r["korku"]) * 0.05
	return clampf(v + 5.0, 0.0, 100.0)


func opinion_label(v: float) -> String:
	if v >= 75:
		return "Bağlılık"
	if v >= 60:
		return "Yakınlık"
	if v >= 45:
		return "Saygılı"
	if v >= 32:
		return "Mesafeli"
	if v >= 20:
		return "Soğuk"
	return "Düşmanca"


# ================================================================ hafıza

func add_memory(who: String, type: String, actors: Array, emotion: float, text: String, source: String = "dogrudan", truth: bool = true, extra: Dictionary = {}) -> Dictionary:
	var c := ch(who)
	if c.is_empty():
		return {}
	var strength := 1.0
	if source == "gozlem":
		strength = 0.8
	elif source == "soylenti":
		strength = 0.55
	var m := {"id": next_id("m"), "type": type, "day": get_day(), "actors": actors, "truth": truth, "source": source,
		"emotion": emotion, "strength": strength, "resolved": false, "text": text, "key": extra.get("key", "")}
	for k in extra.keys():
		m[k] = extra[k]
	var mems: Array = c["memories"]
	mems.append(m)
	if mems.size() > 40:
		mems.sort_custom(func(x, y): return float(x["strength"]) * absf(float(x["emotion"])) > float(y["strength"]) * absf(float(y["emotion"])))
		mems.resize(40)
	if who != PLAYER:
		adjust_mood(who, emotion * 0.25 * strength)
	return m


func knows_key(who: String, key: String) -> bool:
	if key == "":
		return false
	for m in ch(who).get("memories", []):
		if m.get("key", "") == key:
			return true
	return false


func memories_about(who: String, actor: String) -> Array:
	var out: Array = []
	for m in ch(who).get("memories", []):
		if actor in m["actors"]:
			out.append(m)
	return out


func strongest_memory_about(who: String, actor: String, recent_days: int = 30) -> Dictionary:
	var best := {}
	var best_v := 0.0
	for m in memories_about(who, actor):
		if get_day() - int(m["day"]) > recent_days:
			continue
		var v := absf(float(m["emotion"])) * float(m["strength"])
		if v > best_v:
			best_v = v
			best = m
	return best


func has_memory(who: String, type: String, actor: String = "", unresolved_only: bool = false) -> bool:
	for m in ch(who).get("memories", []):
		if m["type"] == type and (actor == "" or actor in m["actors"]):
			if unresolved_only and m.get("resolved", false):
				continue
			return true
	return false


func resolve_memories(who: String, type: String, actor: String) -> void:
	for m in ch(who).get("memories", []):
		if m["type"] == type and actor in m["actors"]:
			m["resolved"] = true


## Oyuncunun eylemine tanık olanlara gözlem anısı ekler
func witness_action(room: String, type: String, actors: Array, text: String, key: String, emotion_for: Callable) -> Array:
	var ws := witnesses(room, actors)
	for wid in ws:
		var emo: float = emotion_for.call(wid)
		add_memory(wid, type, actors, emo, text, "gozlem", true, {"key": key})
	return ws


# ================================================================ bilgi / geçmiş

func lore_unlocked(id: String) -> Array:
	return w["lore"].get(id, [])


func unlock_lore(id: String, idx: int) -> bool:
	var arr: Array = w["lore"].get(id, [])
	if idx in arr:
		return false
	arr.append(idx)
	arr.sort()
	w["lore"][id] = arr
	return true


func flag(k: String) -> bool:
	return bool(w["flags"].get(k, false))


func set_flag(k: String, v = true) -> void:
	w["flags"][k] = v


# ================================================================ günlük

func add_log(text: String, kind: String = "bilgi", importance: int = 1) -> void:
	var e := {"day": get_day(), "t": total_minutes(), "text": text, "kind": kind, "imp": importance}
	var lg: Array = w["log"]
	lg.append(e)
	if lg.size() > 300:
		lg.remove_at(0)
	log_added.emit(e)
	if importance >= 2:
		notify.emit(text, kind)


func add_npc_event(text: String, actors: Array, room: String, kind: String = "kulis") -> void:
	var known := room == player_room
	var e := {"day": get_day(), "t": total_minutes(), "text": text, "actors": actors, "room": room, "kind": kind, "known": known}
	var lg: Array = w["npc_log"]
	lg.append(e)
	if lg.size() > 150:
		lg.remove_at(0)
	if known:
		add_log(text, kind, 1)


func log_for_day(day: int, min_imp: int = 0) -> Array:
	var out: Array = []
	for e in w["log"]:
		if int(e["day"]) == day and int(e["imp"]) >= min_imp:
			out.append(e)
	return out


func reveal_gossip(count: int = 2) -> Array:
	var out: Array = []
	var lg: Array = w["npc_log"]
	for i in range(lg.size() - 1, -1, -1):
		var e: Dictionary = lg[i]
		if not e["known"] and get_day() - int(e["day"]) <= 6:
			e["known"] = true
			out.append(e)
			add_log("Kulis: " + String(e["text"]), "kulis", 1)
			if out.size() >= count:
				break
	return out


# ================================================================ hazine ve devlet

func treasury() -> float:
	return float(w["state"]["treasury"])


func spend(amount: float, reason: String = "") -> bool:
	if treasury() < amount:
		notify.emit("Hazinede yeterli akçe yok (%s gerekli)." % fmt_money(amount), "uyari")
		return false
	w["state"]["treasury"] = treasury() - amount
	stats_changed.emit()
	return true


func earn(amount: float) -> void:
	w["state"]["treasury"] = treasury() + amount
	stats_changed.emit()


func state_add(stat: String, v: float) -> void:
	w["state"][stat] = clampf(float(w["state"].get(stat, 50.0)) + v, 0.0, 100.0)
	stats_changed.emit()


func province(id: String) -> Dictionary:
	for p in w["provinces"]:
		if p["id"] == id:
			return p
	return {}


func people_huzur() -> float:
	var tot := 0.0
	var pop := 0.0
	for p in w["provinces"]:
		tot += float(p["huzur"]) * float(p["pop"])
		pop += float(p["pop"])
	return tot / maxf(pop, 1.0)


func total_pop() -> float:
	var pop := 0.0
	for p in w["provinces"]:
		pop += float(p["pop"])
	return pop


func add_modifier(prov: String, stat: String, value: float, days: int, src: String = "") -> void:
	w["modifiers"].append({"prov": prov, "stat": stat, "value": value, "until": get_day() + days, "src": src})


func modifier_sum(prov: String, stat: String) -> float:
	var s := 0.0
	for m in w["modifiers"]:
		if m["stat"] == stat and (m["prov"] == prov or m["prov"] == "*"):
			s += float(m["value"])
	return s


func player_skill(s: String) -> float:
	return float(player()["skills"].get(s, 40))


func player_skill_add(s: String, v: float) -> void:
	var sk: Dictionary = player()["skills"]
	sk[s] = clampf(float(sk.get(s, 40)) + v, 0.0, 100.0)


static func fmt_money(v: float) -> String:
	var n := int(round(v))
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if neg else "") + out + " akçe"


# ================================================================ günlük rutinler

func plan_for(id: String, hour: int) -> Dictionary:
	var c := ch(id)
	var prof: Array = SchedulesData.PROFILES.get(c.get("profile", ""), [])
	var slot: Array = []
	for s in prof:
		if hour >= int(s[0]) and hour < int(s[1]):
			slot = s
			break
	if slot.is_empty():
		return {"room": c.get("home", "avlu"), "activity": "dinlenme"}
	# geçici yönlendirme (görüşme talebi vb.)
	var ov: Dictionary = c.get("override", {})
	if not ov.is_empty():
		if total_minutes() < int(ov["until"]):
			return {"room": ov["room"], "activity": ov["activity"]}
		c.erase("override")
	var activity: String = slot[2]
	var opts: Array = slot[3]
	if activity == "toplanti" and not is_divan_day():
		activity = "gorev"
		opts = [["@office", 1.0]]
	var r := RandomNumberGenerator.new()
	r.seed = hash(id + ":" + str(get_day()) + ":" + str(slot[0]))
	var total := 0.0
	var weights: Array = []
	var haunts: Array = c.get("haunts", [])
	for o in opts:
		var room := _resolve_room(c, String(o[0]))
		var wt := float(o[1])
		if room == "divan" and activity != "toplanti" and c.get("profile", "") == "scribe" and not is_divan_day():
			wt = 0.0
		if room in haunts:
			wt *= 2.0
		if room in ["kutuphane"]:
			wt *= 0.5 + trait_of(id, "zeka") / 100.0
		if room in ["harem", "avlu", "mutfak", "harem_bahce"] and activity in ["sohbet", "gezinti"]:
			wt *= 0.5 + trait_of(id, "sosyal") / 100.0
		weights.append([room, wt])
		total += wt
	var pick := r.randf() * total
	var chosen: String = weights[0][0]
	for pw in weights:
		pick -= float(pw[1])
		if pick <= 0.0:
			chosen = pw[0]
			break
	if chosen == "" or (chosen != "disari" and not PalaceLayout.has_room(chosen)):
		chosen = c.get("home", "avlu")
	return {"room": chosen, "activity": activity}


func _resolve_room(c: Dictionary, key: String) -> String:
	match key:
		"@home":
			return String(c.get("home", "avlu"))
		"@office":
			return String(c.get("office", c.get("home", "avlu")))
		"@serves":
			var s: String = c.get("serves", "")
			if s != "" and not ch(s).is_empty():
				var sl: String = ch(s)["location"]
				if sl == "disari":
					return "harem"
				return sl
			return "harem"
	return key


func update_all_schedules() -> void:
	var ids := npc_ids()
	ids.sort_custom(func(a, b): return (1 if ch(a).get("profile", "") == "nedime" else 0) < (1 if ch(b).get("profile", "") == "nedime" else 0))
	var h := get_hour()
	for id in ids:
		var plan := plan_for(id, h)
		var c: Dictionary = w["characters"][id]
		c["location"] = plan["room"]
		c["activity"] = plan["activity"]
	schedules_updated.emit()


func set_override(id: String, room: String, activity: String, minutes: int) -> void:
	var c := ch(id)
	if c.is_empty():
		return
	c["override"] = {"room": room, "activity": activity, "until": total_minutes() + minutes}
	c["location"] = room
	c["activity"] = activity
	schedules_updated.emit()


func activity_text(id: String) -> String:
	var c := ch(id)
	return SchedulesData.ACTIVITY_NAMES.get(c.get("activity", ""), "")


# ================================================================ kayıt

func serialize() -> Dictionary:
	w["player"]["pos"] = [player_pos.x, player_pos.y, player_pos.z]
	w["player"]["yaw"] = player_yaw
	w["player"]["room"] = player_room
	w["meta"]["saved_at"] = Time.get_datetime_string_from_system()
	w["meta"]["speed"] = speed_idx
	return w


func load_world(data: Dictionary) -> void:
	w = data
	var pp: Array = w["player"].get("pos", [0.0, 0.0, 6.0])
	player_pos = Vector3(float(pp[0]), float(pp[1]), float(pp[2]))
	player_yaw = float(w["player"].get("yaw", 0.0))
	player_room = String(w["player"].get("room", "avlu"))
	speed_idx = int(w["meta"].get("speed", 1))
	if speed_idx == 0:
		speed_idx = 1
	_pauses.clear()
	_accum = 0.0
	active = true
	game_started.emit()


func summary_text() -> String:
	if w.is_empty():
		return ""
	return "Sultan %s — %s" % [String(player()["name"]), date_string()]
