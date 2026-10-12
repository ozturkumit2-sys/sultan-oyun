class_name C
extends RefCounted
## Shared constants and tiny helpers for the simulation.

const GRID_W := 14
const GRID_H := 14
const DAY_START_HOUR := 9
const DAY_LEN := 540.0                 # 09:00 -> 18:00, in game minutes
const REAL_SECONDS_PER_DAY := 600.0    # ~10 real minutes at normal speed
const MIN_PER_SEC := DAY_LEN / REAL_SECONDS_PER_DAY
const WALK_SPEED := 2.7                # tiles per game minute
const NPC_IDS := ["ahmet", "selin", "mert", "zeynep", "burak", "ece", "deniz", "ceren"]
const SAVE_VERSION := 1


## "11:30" -> minutes since 09:00
static func hm(s: String) -> float:
	var p := s.split(":")
	return (int(p[0]) - DAY_START_HOUR) * 60.0 + float(int(p[1]))


## minutes since 09:00 -> "11:30"
static func fmt(m: float) -> String:
	var total := int(floor(m)) + DAY_START_HOUR * 60
	total = clampi(total, 0, 24 * 60 - 1)
	return "%02d:%02d" % [total / 60, total % 60]


static func clampf100(v: float) -> float:
	return clampf(v, -100.0, 100.0)


static func dict_get_path(d: Dictionary, path: String, def = null):
	var cur = d
	for k in path.split("."):
		if typeof(cur) != TYPE_DICTIONARY or not cur.has(k):
			return def
		cur = cur[k]
	return cur
