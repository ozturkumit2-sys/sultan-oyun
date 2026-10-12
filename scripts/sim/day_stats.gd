class_name DayStats
extends RefCounted
## Counts what really happened today, for the end-of-day newspaper.

const ORDER := [
	"arguments", "big_fights", "new_friendships", "reconciliations", "rumors", "secrets_revealed",
	"broken_promotions", "wrong_rewards", "scoldings", "praises", "late_arrivals", "helps",
	"refusals", "blames", "pranks_found", "breakdowns", "emails", "interventions",
]

var counts: Dictionary = {}
var notable: Array = []      # {text, imp, cat, actors, minute}
var history: Array = []      # past day summaries (last 30)


func reset() -> void:
	counts.clear()
	notable.clear()


func add(key: String, n := 1) -> void:
	counts[key] = int(counts.get(key, 0)) + n


func get_count(key: String) -> int:
	return int(counts.get(key, 0))


func note(entry: Dictionary) -> void:
	notable.append(entry)


func chaos_score() -> float:
	var s := 0.0
	s += get_count("arguments") * 3.0
	s += get_count("big_fights") * 7.0
	s += get_count("rumors") * 0.4
	s += get_count("secrets_revealed") * 2.5
	s += get_count("broken_promotions") * 6.0
	s += get_count("wrong_rewards") * 3.0
	s += get_count("scoldings") * 2.0
	s += get_count("late_arrivals") * 1.0
	s += get_count("blames") * 2.0
	s += get_count("breakdowns") * 1.5
	s += get_count("emails") * 2.5
	s += get_count("refusals") * 1.5
	s -= get_count("reconciliations") * 2.0
	s -= get_count("helps") * 0.5
	return maxf(s, 0.0)


func headline_key() -> String:
	var c := chaos_score()
	if c < 9.0:
		return "paper.title_calm"
	if c < 19.0:
		return "paper.title_drama"
	if c < 34.0:
		return "paper.title_mayhem"
	return "paper.title_chaos"


func top_stories(n := 3) -> Array:
	var arr := notable.duplicate()
	arr.sort_custom(func(a, b):
		if a["imp"] != b["imp"]:
			return a["imp"] > b["imp"]
		return a["minute"] > b["minute"])
	# avoid two stories of the same category when possible
	var out: Array = []
	var cats := {}
	for e in arr:
		if out.size() >= n:
			break
		if cats.has(e["cat"]) and arr.size() > n * 2:
			continue
		out.append(e)
		cats[e["cat"]] = true
	if out.size() < n:
		for e in arr:
			if out.size() >= n:
				break
			if not out.has(e):
				out.append(e)
	return out


func summary(day: int) -> Dictionary:
	return {"day": day, "counts": counts.duplicate(), "stories": top_stories(3), "headline": headline_key(), "chaos": chaos_score()}


func to_dict() -> Dictionary:
	return {"counts": counts.duplicate(), "notable": notable.duplicate(true), "history": history.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	counts = d.get("counts", {})
	notable = d.get("notable", [])
	history = d.get("history", [])
