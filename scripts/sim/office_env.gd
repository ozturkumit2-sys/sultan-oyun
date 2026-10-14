class_name OfficeEnv
extends RefCounted
## OfficeEnvironmentManager: walkable grid, pathfinding, places, object states and items.

const OUTSIDE := Vector2(15.4, 11.5)

var blocked := PackedByteArray()
var edge_block := {}          # "x,y>x2,y2" -> true (both directions stored)
var places := {}              # id -> Dictionary (copy of layout place + "occupant")
var place_order: Array = []
var objects := {}             # object states
var items := {}               # item_id -> {owner, home, at}


func _init() -> void:
	blocked.resize(C.GRID_W * C.GRID_H)
	for f in OfficeLayout.furniture():
		if f.get("block", false):
			for c in f["cells"]:
				blocked[c[1] * C.GRID_W + c[0]] = 1
	for p in OfficeLayout.partitions():
		var a: Vector2i
		var b: Vector2i
		if p[0] == "v":
			a = Vector2i(p[1] - 1, p[2]); b = Vector2i(p[1], p[2])
		else:
			a = Vector2i(p[1], p[2] - 1); b = Vector2i(p[1], p[2])
		edge_block[_ek(a, b)] = true
		edge_block[_ek(b, a)] = true
	for p in OfficeLayout.places():
		var d: Dictionary = p.duplicate(true)
		d["occupant"] = ""
		places[d["id"]] = d
		place_order.append(d["id"])
	reset_objects()


func reset_objects() -> void:
	objects = {
		"coffee": {"broken": false, "ghost_fixed": false, "last_user": "", "fixing": "", "discovered": false},
		"printer": {"broken": false, "last_user": "", "fixing": "", "discovered": false},
		"lights": {"on": true, "off_at": -1.0, "fixing": ""},
		"ac": {"temp": 22, "set_by": ""},
		"board": {"time": 120.0, "changed": false},
		"promo": {"credit": "", "altered": false, "reviewed": false},
		"desks": {},
		"email": {},       # sender -> {"mode": "all"/"redirect", "to": id}
		# --- objects added for the big intervention update
		"ws": {},          # per person: their computer / inbox / phone / papers state
		"water": {"broken": false, "last_user": "", "fixing": "", "discovered": false, "lemon": false},
		"microwave": {"broken": false, "last_user": "", "fixing": "", "discovered": false},
		"projector": {"broken": false, "fixing": "", "discovered": false},
		"net": {"down": false, "fixing": "", "discovered": false, "broken": false},
		"kitchen": {"reserved": "", "cake_out": false, "snacks_at": "", "tray": false, "last_cup": false, "salt": false},
		"fridge": {"cleared": false, "note": ""},
		"music": {"genre": "", "set_by": ""},
		"alarm": {"on": false, "until": -1.0},
		"clock": {"offset": 0},
		"door": {"locked": false},
		"front_door": {"jammed": false},
		"notice": {"pins": []},
		"plant": {"revived": false},
		"supplies": {"at": ""},
		"hr": {"shortlist": "", "swapped": ""},
		"coats": {"swapped": ""},
	}
	for id in C.NPC_IDS:
		objects["ws"][id] = {}
	objects["coffee"]["decaf"] = false
	objects["coffee"]["strong"] = false
	objects["coffee"]["late_until"] = -1.0
	objects["printer"]["no_paper"] = false
	objects["printer"]["queue"] = ""
	objects["lights"]["party"] = false
	objects["lights"]["flicker_until"] = -1.0
	objects["ac"]["locked"] = false
	objects["board"]["agenda"] = ""
	objects["board"]["chair"] = ""
	objects["board"]["title"] = ""
	for ws in OfficeLayout.workstations():
		objects["desks"][ws["owner"]] = {"messed": false}
	objects["desks"]["ahmet"] = {"messed": false}
	items = {
		"glasses": {"owner": "ahmet", "home": "desk_ahmet", "at": "desk_ahmet"},
		"usb": {"owner": "selin", "home": "desk_selin", "at": "desk_selin"},
		"mug": {"owner": "mert", "home": "desk_mert", "at": "desk_mert"},
		"planner": {"owner": "ceren", "home": "desk_ceren", "at": "desk_ceren"},
		"charger": {"owner": "burak", "home": "desk_burak", "at": "desk_burak"},
	}


## Object states that reset overnight (the cleaner, IT and the morning shift
## undo most pranks). Things that stay: wallpapers, signatures, titles, notes.
const WS_KEEP := ["wallpaper", "signature", "title", "ringtone", "autoreply"]


func overnight_reset() -> void:
	var o := objects
	o["water"]["fixing"] = ""
	o["microwave"]["fixing"] = ""
	o["net"] = {"down": false, "fixing": "", "discovered": false, "broken": false}
	o["projector"]["fixing"] = ""
	o["kitchen"] = {"reserved": "", "cake_out": false, "snacks_at": "", "tray": false, "last_cup": false, "salt": false}
	o["fridge"]["cleared"] = false
	o["music"] = {"genre": "", "set_by": ""}
	o["alarm"] = {"on": false, "until": -1.0}
	o["clock"]["offset"] = 0
	o["door"]["locked"] = false
	o["front_door"]["jammed"] = false
	o["coffee"]["decaf"] = false
	o["coffee"]["strong"] = false
	o["coffee"]["late_until"] = -1.0
	o["printer"]["no_paper"] = false
	o["printer"]["queue"] = ""
	o["lights"]["party"] = false
	o["lights"]["flicker_until"] = -1.0
	o["ac"]["locked"] = false
	o["board"]["agenda"] = ""
	o["board"]["chair"] = ""
	o["board"]["title"] = ""
	o["supplies"]["at"] = ""
	o["hr"] = {"shortlist": "", "swapped": ""}
	var pins: Array = o["notice"]["pins"]
	while pins.size() > 4:
		pins.pop_front()
	for id in o["ws"]:
		var keep := {}
		for k in WS_KEEP:
			if o["ws"][id].has(k):
				keep[k] = o["ws"][id][k]
		o["ws"][id] = keep


## Timed object states (once per game minute).
func tick(w) -> void:
	var o := objects
	if o["alarm"]["on"] and w.minute > float(o["alarm"]["until"]):
		o["alarm"]["on"] = false
		w.office_changed.emit("alarm")
		w.events.fire("alarm_over", {})
	var fl := float(o["lights"].get("flicker_until", -1.0))
	if fl > 0.0 and w.minute > fl:
		o["lights"]["flicker_until"] = -1.0
		w.office_changed.emit("lights")


## The spot someone stands at to repair an object.
static func fix_place(obj: String) -> String:
	match obj:
		"printer": return "printer"
		"coffee": return "coffee"
		"lights": return "breaker"
		"water": return "water"
		"microwave": return "micro"
		"projector": return "m3"
		"net": return "server"
	return "printer"


func is_broken(obj: String) -> bool:
	if obj == "lights":
		return not objects["lights"]["on"]
	return objects.has(obj) and objects[obj].get("broken", false)


static func _ek(a: Vector2i, b: Vector2i) -> String:
	return "%d,%d>%d,%d" % [a.x, a.y, b.x, b.y]


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < C.GRID_W and c.y < C.GRID_H


func walkable(c: Vector2i) -> bool:
	return in_bounds(c) and blocked[c.y * C.GRID_W + c.x] == 0


func can_step(a: Vector2i, b: Vector2i) -> bool:
	if not walkable(b):
		return false
	var dx := b.x - a.x
	var dy := b.y - a.y
	if abs(dx) + abs(dy) == 1:
		return not edge_block.has(_ek(a, b))
	# diagonal: both L routes must be free
	var m1 := Vector2i(a.x + dx, a.y)
	var m2 := Vector2i(a.x, a.y + dy)
	if not walkable(m1) or not walkable(m2):
		return false
	if edge_block.has(_ek(a, m1)) or edge_block.has(_ek(m1, b)):
		return false
	if edge_block.has(_ek(a, m2)) or edge_block.has(_ek(m2, b)):
		return false
	return true


static func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x)), int(floor(p.y)))


func nearest_walkable(c: Vector2i) -> Vector2i:
	if walkable(c):
		return c
	var best := c
	var bd := 1e9
	for y in C.GRID_H:
		for x in C.GRID_W:
			var v := Vector2i(x, y)
			if walkable(v):
				var d := float((v - c).length_squared())
				if d < bd:
					bd = d
					best = v
	return best


## A* over cells (8-dir), then line-of-sight smoothing. Returns continuous waypoints (cell centers / end pos).
func find_path(from: Vector2, to_cell: Vector2i, end_pos = null) -> PackedVector2Array:
	var start := cell_of(from)
	if not in_bounds(start):
		start = Vector2i(13, 11)
	start = nearest_walkable(start)
	var goal := nearest_walkable(to_cell)
	var out := PackedVector2Array()
	if start == goal:
		out.append(end_pos if end_pos != null else Vector2(goal) + Vector2(0.5, 0.5))
		return out
	var open: Array = [start]
	var came := {}
	var g := {start: 0.0}
	var f := {start: _h(start, goal)}
	var closed := {}
	var found := false
	var guard := 0
	var best_cell := start
	var best_h := _h(start, goal)
	while open.size() > 0 and guard < 4000:
		guard += 1
		var bi := 0
		var bf := 1e18
		for i in open.size():
			var fv: float = f.get(open[i], 1e18)
			if fv < bf:
				bf = fv
				bi = i
		var cur: Vector2i = open[bi]
		open.remove_at(bi)
		if cur == goal:
			found = true
			break
		var hc := _h(cur, goal)
		if hc < best_h:
			best_h = hc
			best_cell = cur
		closed[cur] = true
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nb := Vector2i(cur.x + dx, cur.y + dy)
				if closed.has(nb) or not can_step(cur, nb):
					continue
				var step := 1.0 if (dx == 0 or dy == 0) else 1.4142
				var ng: float = g[cur] + step
				if ng < g.get(nb, 1e18):
					came[nb] = cur
					g[nb] = ng
					f[nb] = ng + _h(nb, goal)
					if not open.has(nb):
						open.append(nb)
	var endc := goal
	if not found:
		# unreachable goal: go as close as possible instead of walking through walls
		endc = best_cell
		end_pos = null
		if endc == start:
			out.append(Vector2(start) + Vector2(0.5, 0.5))
			return out
	var cells: Array = [endc]
	var c: Vector2i = endc
	while came.has(c):
		c = came[c]
		cells.push_front(c)
	# smoothing (string pulling)
	var pts: Array = []
	for cc in cells:
		pts.append(Vector2(cc) + Vector2(0.5, 0.5))
	pts[0] = from if in_bounds(cell_of(from)) else pts[0]
	if end_pos != null:
		pts[pts.size() - 1] = end_pos
	var smooth: Array = [pts[0]]
	var i := 0
	while i < pts.size() - 1:
		var j := pts.size() - 1
		while j > i + 1 and not line_clear(pts[i], pts[j]):
			j -= 1
		smooth.append(pts[j])
		i = j
	for k in range(1, smooth.size()):
		out.append(smooth[k])
	return out


func _h(a: Vector2i, b: Vector2i) -> float:
	var dx: float = abs(a.x - b.x)
	var dy: float = abs(a.y - b.y)
	return max(dx, dy) + 0.4142 * min(dx, dy)


func line_clear(a: Vector2, b: Vector2) -> bool:
	var dist := a.distance_to(b)
	var n := int(ceil(dist / 0.2)) + 1
	var prev := cell_of(a)
	for k in range(1, n + 1):
		var p := a.lerp(b, float(k) / n)
		var cc := cell_of(p)
		if cc != prev:
			if not can_step(prev, cc):
				return false
			prev = cc
		# keep a little clearance from blocked neighbours
		for off in [Vector2(0.28, 0), Vector2(-0.28, 0), Vector2(0, 0.28), Vector2(0, -0.28)]:
			if not walkable(cell_of(p + off)):
				return false
	return true


## Cells reachable from a start cell (debug/validation).
func reachable_from(s: Vector2i) -> Dictionary:
	var seen := {s: true}
	var q: Array = [s]
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var nb := Vector2i(cur.x + dx, cur.y + dy)
				if (dx != 0 or dy != 0) and not seen.has(nb) and can_step(cur, nb):
					seen[nb] = true
					q.append(nb)
	return seen


# ------------------------------------------------------------------ places

func place(id: String) -> Dictionary:
	return places.get(id, {})


func place_pos(id: String) -> Vector2:
	var p: Dictionary = places.get(id, {})
	if p.is_empty():
		return Vector2(7.5, 7.5)
	if p.has("seat"):
		return Vector2(p["seat"][0], p["seat"][1])
	return Vector2(p["cell"][0] + 0.5, p["cell"][1] + 0.5)


func place_cell(id: String) -> Vector2i:
	var p: Dictionary = places.get(id, {})
	if p.is_empty():
		return Vector2i(7, 7)
	return Vector2i(p["cell"][0], p["cell"][1])


func places_with_tag(tag: String) -> Array:
	var r: Array = []
	for id in place_order:
		if tag in places[id]["tags"]:
			r.append(id)
	return r


func free_place_with_tag(tag: String, rng: RandomNumberGenerator, near = null, for_npc := "") -> String:
	var cands: Array = []
	for id in places_with_tag(tag):
		var occ: String = places[id]["occupant"]
		if occ == "" or occ == for_npc:
			cands.append(id)
	if cands.is_empty():
		return ""
	if near != null:
		cands.sort_custom(func(a, b): return place_pos(a).distance_to(near) < place_pos(b).distance_to(near))
		return cands[0]
	return cands[rng.randi() % cands.size()]


func reserve(id: String, npc_id: String) -> bool:
	if not places.has(id):
		return false
	var occ: String = places[id]["occupant"]
	if occ != "" and occ != npc_id:
		return false
	places[id]["occupant"] = npc_id
	return true


func release(id: String, npc_id: String) -> void:
	if places.has(id) and places[id]["occupant"] == npc_id:
		places[id]["occupant"] = ""


func release_all(npc_id: String) -> void:
	for id in place_order:
		if places[id]["occupant"] == npc_id:
			places[id]["occupant"] = ""


# ------------------------------------------------------------------ items

func items_at(loc: String) -> Array:
	var r: Array = []
	for k in items:
		if items[k]["at"] == loc:
			r.append(k)
	return r


func item_owned_by(npc_id: String) -> String:
	for k in items:
		if items[k]["owner"] == npc_id:
			return k
	return ""


# ------------------------------------------------------------------ save

func to_dict() -> Dictionary:
	return {"objects": objects.duplicate(true), "items": items.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	reset_objects()
	var o: Dictionary = d.get("objects", {})
	for k in o:
		if objects.has(k) and typeof(o[k]) == TYPE_DICTIONARY:
			for kk in o[k]:
				objects[k][kk] = o[k][kk]
	for id in C.NPC_IDS:
		if not objects["ws"].has(id):
			objects["ws"][id] = {}
	var it: Dictionary = d.get("items", {})
	for k in it:
		if items.has(k):
			items[k] = it[k]
	for id in place_order:
		places[id]["occupant"] = ""
