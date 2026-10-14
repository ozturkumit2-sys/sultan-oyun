class_name NPC
extends RefCounted
## One office worker: personality, needs, relationships (NPCRelationshipSystem),
## memories (NPCMemorySystem), knowledge, intents and current activity state.

enum S { OUTSIDE, WALKING, ACTING, GONE }

var id := ""
var def: Dictionary = {}
var name := ""
var traits: Dictionary = {}
var prefs: Dictionary = {}

# --- live state
var present := false
var state: int = S.OUTSIDE
var pos := Vector2(15.4, 11.5)
var face_front := true
var face_right := true
var pose := "stand"        # stand, walk, sit, type, phone, coffee, fix, talk, search, eat, read
var expr := "normal"       # normal, happy, angry, surprised, sad
var expr_timer := 0.0      # real seconds
var emote := ""
var emote_timer := 0.0

# --- needs & feelings (0..100 / -100..100)
var mood := 20.0
var stress := 15.0
var coffee_need := 20.0
var social_need := 30.0

# --- activity
var act := ""
var act_place := ""
var act_target := ""
var act_dur := 0.0
var act_t := 0.0
var act_data: Dictionary = {}
var phase := ""             # "walk", "do"
var path := PackedVector2Array()
var path_i := 0
var hold_until := -1.0      # abs minute; frozen in a scene until then
var hold_face := ""
var repath_t := 0.0
var current_activity_label := ""

# --- mind
const REL_STATS := ["trust", "friendship", "rivalry", "respect", "romance", "suspicion", "resentment"]
const REL_POSITIVE := ["rivalry", "romance", "suspicion", "resentment"]   # 0..100; the rest are -100..100
var rel: Dictionary = {}          # other_id -> {trust, friendship, rivalry, respect, romance, suspicion, resentment} (one-way)
var memories: Array = []          # dicts
var known: Dictionary = {}        # fact_id -> day learned
var belief: Dictionary = {}       # fact_id -> certainty 0..1 (missing = sure)
var plans: Array = []             # long-term intentions {kind, target, day, heat}
var morale := 60.0                # job satisfaction 0..100, changes slowly over days
var mood_acc := 0.0               # mood integrated over today (for morale)
var mood_time := 0.0
var intents: Array = []           # dicts {type, target, event, prio, until, place, data}
var goal := ""
var tasks: Array = []             # {id, name, total, left, deadline, print, printed, usb}
var meeting_belief := -1.0        # minute they think the meeting starts; -2 = believes cancelled
var meeting_state := ""           # "", "waiting", "in", "done", "missed"
var meeting_wait := 0.0
var arrive_at := 0.0
var leave_at := 525.0
var lunch_at := 220.0
var lunch_done := false
var coffee_count := 0
var last_desk_check := -100.0
var promoted := false
var title_override := ""
var today_flags: Dictionary = {}
var pending_notif := ""
var speaking := 0.0               # real seconds of active speech (for mouth anim)
var reviewed_today := false


func setup(d: Dictionary) -> void:
	def = d
	id = d["id"]
	name = d["name"]
	traits = d["traits"].duplicate()
	prefs = d.get("prefs", {}).duplicate()
	morale = float(d.get("morale", 60.0))


func t(k: String) -> float:
	return float(traits.get(k, 0.5))


func role_title() -> String:
	if title_override != "":
		return title_override
	return def.get("role", "")


# ------------------------------------------------------------------ relationships

func r(other: String) -> Dictionary:
	if not rel.has(other):
		rel[other] = {"trust": 10.0, "friendship": 5.0, "rivalry": 0.0, "respect": 10.0, "romance": 0.0, "suspicion": 0.0, "resentment": 0.0}
	var x: Dictionary = rel[other]
	if x.size() < REL_STATS.size():
		for st in REL_STATS:
			if not x.has(st):
				x[st] = 10.0 if st == "respect" else 0.0
	return x


func get_rel(other: String, stat: String) -> float:
	if other == id or other == "":
		return 0.0
	return float(r(other).get(stat, 0.0))


func change_rel(other: String, stat: String, d: float) -> float:
	if other == id or other == "":
		return 0.0
	var cur := r(other)
	if not cur.has(stat):
		return 0.0
	var before: float = cur[stat]
	var lo := 0.0 if stat in REL_POSITIVE else -100.0
	cur[stat] = clampf(before + d, lo, 100.0)
	return cur[stat] - before


## Overall disposition toward someone, roughly -100..100.
func affinity(other: String) -> float:
	if other == id or other == "":
		return 0.0
	var x := r(other)
	return x["friendship"] * 0.55 + x["trust"] * 0.35 - x["rivalry"] * 0.45 + x["respect"] * 0.12 \
		- x["resentment"] * 0.4 - x["suspicion"] * 0.15 + mem_bias(other) * 18.0


# ------------------------------------------------------------------ memory (NPCMemorySystem)

## A memory: what happened (kind/text), who it was about and who else was there,
## who it helped or hurt, how it felt, how sure the person is, and when.
func remember(kind: String, about: String, val: float, weight: float, text: String, args: Dictionary, day: int, minute: float, imp := 1, extra: Dictionary = {}) -> void:
	# merge with a same-day identical memory
	for m in memories:
		if m["kind"] == kind and m["about"] == about and m["day"] == day:
			m["w"] = clampf(m["w"] + weight * 0.5, 0.0, 1.5)
			m["t"] = minute
			if text != "":
				m["text"] = text
				m["args"] = args
			if extra.has("cert"):
				m["cert"] = maxf(float(m.get("cert", 1.0)), float(extra["cert"]))
			return
	var m2 := {"kind": kind, "about": about, "val": val, "w": weight, "text": text, "args": args, "day": day, "t": minute, "imp": imp,
		"with": extra.get("with", []), "emo": extra.get("emo", _emo_for(val)), "gain": extra.get("gain", ""), "harm": extra.get("harm", ""),
		"cert": float(extra.get("cert", 1.0)), "src": extra.get("src", "saw")}
	if m2["harm"] == "" and val < -0.25:
		m2["harm"] = id
	if m2["gain"] == "" and val > 0.25:
		m2["gain"] = id
	memories.append(m2)
	if memories.size() > 48:
		# forget the faintest
		var wi := 0
		var wv := 1e9
		for i in memories.size():
			var s: float = abs(memories[i]["val"]) * memories[i]["w"]
			if s < wv:
				wv = s
				wi = i
		memories.remove_at(wi)


static func _emo_for(v: float) -> String:
	if v <= -0.6: return "hurt"
	if v <= -0.25: return "annoyed"
	if v >= 0.6: return "grateful"
	if v >= 0.25: return "pleased"
	return "neutral"


func mem_bias(about: String) -> float:
	var s := 0.0
	for m in memories:
		if m["about"] == about:
			s += float(m["val"]) * float(m["w"])
	return clampf(s, -2.0, 2.0)


func has_memory(kind: String, about := "", since_day := -1) -> bool:
	for m in memories:
		if m["kind"] == kind and (about == "" or m["about"] == about) and m["day"] >= since_day:
			return true
	return false


func recent_memories(n: int) -> Array:
	var withtext: Array = []
	for m in memories:
		if m.get("text", "") != "":
			withtext.append(m)
	withtext.sort_custom(func(a, b):
		if a["day"] != b["day"]:
			return a["day"] > b["day"]
		return a["t"] > b["t"])
	return withtext.slice(0, n)


## Overnight fading. Unforgiving people hold grudges longer.
func decay_memories() -> void:
	var keep: Array = []
	var forgive := t("forgiveness")
	for m in memories:
		var f := 0.86
		if float(m["val"]) < 0.0:
			f = lerpf(0.94, 0.78, forgive)
		if int(m.get("imp", 1)) >= 3:
			f = sqrt(f)   # big moments stay with people for many days
		m["w"] = float(m["w"]) * f
		if m["w"] > 0.06:
			keep.append(m)
	memories = keep


# ------------------------------------------------------------------ knowledge

func knows(fact: String) -> bool:
	return known.has(fact)


## How sure this person is about something they know (0 = never heard of it).
func certainty(fact: String) -> float:
	if not known.has(fact):
		return 0.0
	return float(belief.get(fact, 1.0))


func forget_fact(fact: String) -> void:
	known.erase(fact)
	belief.erase(fact)


# ------------------------------------------------------------------ plans (cross-day intentions)

func has_plan(kind: String, target := "") -> bool:
	for p in plans:
		if p["kind"] == kind and (target == "" or p.get("target", "") == target):
			return true
	return false


func plan_target(kind: String) -> String:
	for p in plans:
		if p["kind"] == kind:
			return p.get("target", "")
	return ""


func add_plan(kind: String, target: String, day: int, heat := 1.0) -> void:
	for i in range(plans.size() - 1, -1, -1):
		var p: Dictionary = plans[i]
		if p["kind"] == kind and p.get("target", "") == target:
			p["heat"] = minf(3.0, float(p.get("heat", 1.0)) + heat)
			if float(p["heat"]) <= 0.0:
				plans.remove_at(i)
			return
	if heat <= 0.0:
		return   # cooling off a plan that doesn't exist does nothing
	plans.append({"kind": kind, "target": target, "day": day, "heat": heat})
	if plans.size() > 6:
		plans.pop_front()


func drop_plan(kind: String, target := "") -> void:
	for i in range(plans.size() - 1, -1, -1):
		if plans[i]["kind"] == kind and (target == "" or plans[i].get("target", "") == target):
			plans.remove_at(i)


## Plans cool off overnight; hot ones linger for days.
func decay_plans() -> void:
	for i in range(plans.size() - 1, -1, -1):
		plans[i]["heat"] = float(plans[i].get("heat", 1.0)) - 0.25
		if plans[i]["heat"] <= 0.0:
			plans.remove_at(i)


# ------------------------------------------------------------------ intents

func add_intent(it: Dictionary) -> void:
	# replace same type+target
	for i in range(intents.size() - 1, -1, -1):
		var o: Dictionary = intents[i]
		if o["type"] == it["type"] and o.get("target", "") == it.get("target", "") and o.get("place", "") == it.get("place", "") and o.get("meetup", "") == it.get("meetup", ""):
			intents.remove_at(i)
	intents.append(it)


func top_intent(now: float) -> Dictionary:
	var best: Dictionary = {}
	for i in range(intents.size() - 1, -1, -1):
		var it: Dictionary = intents[i]
		if it.get("until", 1e12) < now:
			intents.remove_at(i)
			continue
		if float(it.get("wait_until", -1.0)) > now:
			continue
		if best.is_empty() or it["prio"] > best["prio"]:
			best = it
	return best


func remove_intent(it: Dictionary) -> void:
	intents.erase(it)


# ------------------------------------------------------------------ tasks

func current_task() -> Dictionary:
	for tk in tasks:
		if tk["left"] > 0.0:
			return tk
	return {}


func task_needing_print() -> Dictionary:
	for tk in tasks:
		if tk.get("print", false) and tk["left"] <= 0.0 and not tk.get("printed", false):
			return tk
	return {}


func work_left() -> float:
	var s := 0.0
	for tk in tasks:
		s += tk["left"]
	return s


# ------------------------------------------------------------------ expression

func set_expr(e: String, secs := 4.0) -> void:
	expr = e
	expr_timer = secs


func set_emote(e: String, secs := 2.6) -> void:
	emote = e
	emote_timer = secs


func base_expr() -> String:
	if stress > 78:
		return "sad" if mood < 0 else "surprised"
	if mood > 45:
		return "happy"
	if mood < -45:
		return "angry" if stress > 50 else "sad"
	if mood < -20:
		return "sad"
	return "normal"


func mood_word() -> String:
	if mood > 60: return "mood.ecstatic"
	if mood > 30: return "mood.happy"
	if mood > 5: return "mood.content"
	if mood > -20: return "mood.meh"
	if mood > -45: return "mood.grumpy"
	if mood > -70: return "mood.upset"
	return "mood.furious"


# ------------------------------------------------------------------ save

func to_dict() -> Dictionary:
	return {
		"id": id, "present": present, "state": state, "pos": [pos.x, pos.y],
		"mood": mood, "stress": stress, "coffee_need": coffee_need, "social_need": social_need,
		"rel": rel.duplicate(true), "memories": memories.duplicate(true), "known": known.duplicate(true),
		"intents": intents.duplicate(true), "goal": goal, "tasks": tasks.duplicate(true),
		"meeting_belief": meeting_belief, "meeting_state": meeting_state, "arrive_at": arrive_at,
		"leave_at": leave_at, "lunch_at": lunch_at, "lunch_done": lunch_done, "traits": traits.duplicate(),
		"promoted": promoted, "title_override": title_override, "today_flags": today_flags.duplicate(true),
		"coffee_count": coffee_count, "reviewed_today": reviewed_today, "pending_notif": pending_notif,
		"belief": belief.duplicate(), "plans": plans.duplicate(true), "morale": morale,
		"mood_acc": mood_acc, "mood_time": mood_time,
	}


func from_dict(d: Dictionary) -> void:
	present = d.get("present", false)
	state = int(d.get("state", S.OUTSIDE))
	var p: Array = d.get("pos", [15.4, 11.5])
	pos = Vector2(p[0], p[1])
	mood = d.get("mood", 20.0)
	stress = d.get("stress", 15.0)
	coffee_need = d.get("coffee_need", 20.0)
	social_need = d.get("social_need", 30.0)
	rel = d.get("rel", {})
	for o in rel:
		r(o)
	memories = d.get("memories", [])
	for m in memories:
		m["day"] = int(m.get("day", 1))   # JSON brings ints back as floats
	known = d.get("known", {})
	intents = d.get("intents", [])
	goal = d.get("goal", "")
	tasks = d.get("tasks", [])
	meeting_belief = d.get("meeting_belief", -1.0)
	meeting_state = d.get("meeting_state", "")
	arrive_at = d.get("arrive_at", 0.0)
	leave_at = d.get("leave_at", 525.0)
	lunch_at = d.get("lunch_at", 220.0)
	lunch_done = d.get("lunch_done", false)
	if d.has("traits"):
		traits = d["traits"]
	promoted = d.get("promoted", false)
	title_override = d.get("title_override", "")
	today_flags = d.get("today_flags", {})
	coffee_count = int(d.get("coffee_count", 0))
	reviewed_today = d.get("reviewed_today", false)
	pending_notif = d.get("pending_notif", "")
	belief = d.get("belief", {})
	plans = d.get("plans", [])
	morale = float(d.get("morale", def.get("morale", 60.0)))
	mood_acc = float(d.get("mood_acc", 0.0))
	mood_time = float(d.get("mood_time", 0.0))
	# activity is re-decided after loading
	act = ""
	phase = ""
	path = PackedVector2Array()
	hold_until = -1.0
	if present:
		state = S.ACTING
