class_name NPCManager
extends Node3D
## NPC düğümlerini GameState'teki rutinlere göre yönetir: nokta (spot) seçimi, rezervasyon,
## görünmeyen karakterlerin düşük maliyetli simülasyonu, saraya giriş/çıkış.

const ENTRANCE := Vector3(0, 0, 38.0)   # bahçe geçidi: saray dışından gelenler buradan girer
const NEAR_DIST := 48.0

var builder: PalaceBuilder
var player: Node3D
var nodes := {}          # id -> NPCNode
var _reserved := {}      # "room:idx" -> id
var _assigned := {}      # id -> key
var _lod_t := 0.0
var _map_rid: RID
var suspended := false   # zaman atlanırken saatlik yeniden yerleşim yapılmaz


func setup(b: PalaceBuilder, p: Node3D) -> void:
	builder = b
	player = p
	for id in GameState.npc_ids():
		_spawn(String(id))
	GameState.schedules_updated.connect(_on_schedules)
	GameState.time_jumped.connect(func():
		if not suspended:
			refresh(true))
	GameState.character_added.connect(func(id: String):
		if not suspended:
			_spawn(id))


## Küçük çocuklar (5 yaş altı) sahnede gösterilmez; dadılarının yanında, dairelerinde kabul edilir.
static func visible_age(c: Dictionary) -> bool:
	return not (String(c.get("role", "")) == "child" and int(c.get("age", 0)) < 5)


func _spawn(id: String) -> void:
	if nodes.has(id):
		return
	var c: Dictionary = GameState.ch(id)
	if c.is_empty() or not visible_age(c):
		return
	var n := NPCNode.new()
	n.setup(id, self)
	add_child(n)
	nodes[id] = n


func all_nodes() -> Array:
	return nodes.values()


func node_for(id: String) -> NPCNode:
	return nodes.get(id, null)


func _on_schedules() -> void:
	if not suspended:
		refresh(false)


func refresh(instant: bool) -> void:
	# büyüyüp sahneye çıkabilecek yaşa gelen çocuklar
	for nid in GameState.npc_ids():
		if not nodes.has(nid) and visible_age(GameState.ch(nid)):
			_spawn(String(nid))
	for id in nodes.keys():
		var n: NPCNode = nodes[id]
		var c: Dictionary = GameState.ch(id)
		if c.is_empty() or c.get("gone", false) or not c.get("alive", true):
			_release(id)
			n.show_npc(false)
			continue
		if n.talking_to_player:
			continue
		var room: String = c["location"]
		var act: String = c["activity"]
		var hidden := room == "disari" or act == "uyku"
		if hidden:
			if n.visible and not instant and _is_near(n) and room == "disari":
				# saraydan çıkış: girişe yürüsün
				_release(id)
				n.go_to({"pos": ENTRANCE, "yaw": 0.0, "type": "stand", "leave": true})
			else:
				_release(id)
				n.show_npc(false)
			continue
		var cur_key: String = _assigned.get(id, "")
		if cur_key != "" and cur_key.begins_with(room + ":") and n.visible and not instant:
			# aynı odada; etkinlik değişmiş olabilir
			var sp0 := _spot_by_key(cur_key)
			if _spot_ok(sp0, act):
				if n.state == "at_spot":
					n._arrive()
				continue
		var sp := _pick_spot(id, room, act)
		if not n.visible:
			n.show_npc(true)
			if instant or not _is_near_pos(sp.get("pos", Vector3.ZERO)):
				n.teleport_to_spot(sp)
			else:
				n.global_position = _entry_for(room, n)
				n.go_to(sp)
		elif instant:
			n.teleport_to_spot(sp)
		else:
			n.go_to(sp)


func _entry_for(room: String, n: NPCNode) -> Vector3:
	var c: Dictionary = GameState.ch(n.char_id)
	if c.get("profile", "") in ["official", "envoy", "physician", "treasury_clerk", "artist"]:
		return ENTRANCE
	return _snap(PalaceLayout.anchor(room))


func on_left(n: NPCNode) -> void:
	var c: Dictionary = GameState.ch(n.char_id)
	if c.get("location", "") == "disari" or c.get("activity", "") == "uyku":
		n.show_npc(false)


func _is_near(n: Node3D) -> bool:
	return player != null and n.global_position.distance_to(player.global_position) < NEAR_DIST


func _is_near_pos(p: Vector3) -> bool:
	return player != null and p.distance_to(player.global_position) < NEAR_DIST


func _release(id: String) -> void:
	var k: String = _assigned.get(id, "")
	if k != "":
		_reserved.erase(k)
		_assigned.erase(id)


func _spot_by_key(k: String) -> Dictionary:
	var parts := k.split(":")
	var arr: Array = builder.spots.get(parts[0], [])
	var i := int(parts[1])
	if i >= 0 and i < arr.size():
		return arr[i]
	return {}


func _spot_ok(sp: Dictionary, act: String) -> bool:
	if sp.is_empty():
		return false
	var prefs: Array = SchedulesData.ACTIVITY_SPOTS.get(act, ["stand"])
	return String(sp["type"]) in prefs


func _pick_spot(id: String, room: String, act: String) -> Dictionary:
	_release(id)
	var arr: Array = builder.spots.get(room, [])
	var prefs: Array = SchedulesData.ACTIVITY_SPOTS.get(act, ["stand"])
	var c: Dictionary = GameState.ch(id)
	if String(c.get("role", "")) == "child":
		# çocuklar yüksek sedirlere değil minderlere oturur
		prefs = prefs.filter(func(t): return t != "sit")
		if prefs.is_empty():
			prefs = ["stand"]
	var tag_pref := ""
	match String(c.get("profile", "")):
		"official":
			tag_pref = "vezir"
		"scribe":
			tag_pref = "katip"
		"kitchen":
			tag_pref = "asci"
		"gardener":
			tag_pref = "bahcivan"
		"treasury_clerk":
			tag_pref = "katip"
		"valide":
			tag_pref = "valide"
	if id == "kemal" and room == "hazine":
		tag_pref = "hazine"
	if room == id or (room == "leyla" and id == "leyla") or (room == "feraye" and id == "feraye"):
		tag_pref = id
	var best_i := -1
	var best_score := -999.0
	for i in range(arr.size()):
		var sp: Dictionary = arr[i]
		var key := "%s:%d" % [room, i]
		if _reserved.has(key):
			continue
		var t: String = sp["type"]
		var pi := prefs.find(t)
		if pi < 0:
			continue
		var score := 10.0 - pi * 3.0 + randf() * 2.0
		if tag_pref != "" and sp.get("tag", "") == tag_pref:
			score += 6.0
		elif sp.get("tag", "") in ["vezir", "katip", "asci", "bahcivan", "hazine", "valide", "hoca"] and sp.get("tag", "") != tag_pref:
			score -= 4.0
		if score > best_score:
			best_score = score
			best_i = i
	if best_i >= 0:
		var key2 := "%s:%d" % [room, best_i]
		_reserved[key2] = id
		_assigned[id] = key2
		return arr[best_i]
	# boş nokta yoksa odada rastgele bir yer
	var r := PalaceLayout.rect(room)
	var p := Vector3(randf_range(r.position.x + 2.0, r.end.x - 2.0), 0, randf_range(r.position.y + 2.0, r.end.y - 2.0))
	return {"pos": _snap(p), "yaw": randf() * TAU, "type": "stand"}


func _snap(p: Vector3) -> Vector3:
	if builder == null or builder.nav_region == null:
		return p
	var map := builder.nav_region.get_navigation_map()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return p
	var q := NavigationServer3D.map_get_closest_point(map, p)
	return Vector3(q.x, 0.0, q.z)


func wander_spot(n: NPCNode) -> Dictionary:
	var c: Dictionary = GameState.ch(n.char_id)
	var room: String = c["location"]
	if room == "disari":
		return {}
	var act: String = c["activity"]
	var prev: String = _assigned.get(n.char_id, "")
	var sp := _pick_spot(n.char_id, room, act)
	if _assigned.get(n.char_id, "") == prev and prev != "":
		var r := PalaceLayout.rect(room)
		var p := Vector3(randf_range(r.position.x + 2.0, r.end.x - 2.0), 0, randf_range(r.position.y + 2.0, r.end.y - 2.0))
		return {"pos": _snap(p), "yaw": randf() * TAU, "type": "stand"}
	return sp


func nearest_npc(n: NPCNode, maxd: float) -> Node3D:
	var best: Node3D = null
	var bd := maxd
	for o in nodes.values():
		if o == n or not o.visible:
			continue
		var d: float = o.global_position.distance_to(n.global_position)
		if d < bd:
			bd = d
			best = o
	return best


func _process(delta: float) -> void:
	_lod_t -= delta
	if _lod_t > 0.0 or player == null:
		return
	_lod_t = 0.5
	for n in nodes.values():
		if not n.visible:
			continue
		var near: bool = n.global_position.distance_to(player.global_position) < NEAR_DIST
		if near != n._near:
			n.set_near(near)
			if not near and n.state == "walk" and not n.spot.is_empty():
				n.teleport_to_spot(n.spot)
				if n.spot.get("leave", false):
					on_left(n)
