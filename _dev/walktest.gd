extends Node
## Geliştirme testi: oyuncunun otomatik yürüyüşünü (odaya / karaktere git) fizik ile simüle eder,
## takılma noktalarını ve takıldığı çarpışma şekillerini raporlar. Dışa aktarıma dahil değildir.

var game: Node
var results := []


func _ready() -> void:
	GameState.new_game("Test", 1)
	GameState.set_speed(0)
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	while not game._ready_done:
		await get_tree().process_frame
	GameState.set_speed(0)
	for i in range(30):
		await get_tree().physics_frame
	_low_steps()
	if OS.get_cmdline_user_args().has("objs"):
		await _objs()
		get_tree().quit()
		return
	var hours := [0, 270, 240]
	var stuck_total := 0
	var wrong_total := 0
	var runs := 0
	for h in hours:
		if h > 0:
			GameState.advance_minutes(h, true)
			for k in range(20):
				await get_tree().physics_frame
		print("--- saat ", GameState.time_string())
		for id in GameState.npc_ids():
			var n: NPCNode = game.npcs.node_for(id)
			if n == null or not n.visible:
				continue
			# her karakter için iki farklı başlangıç: avlu ve rastgele bir oda
			for start in ["avlu", PalaceLayout.ROOMS.keys()[(runs * 7) % PalaceLayout.ROOMS.size()]]:
				var r: Dictionary = await _run_char(id, start)
				runs += 1
				if r["stuck"]:
					stuck_total += 1
				if r["wrong"]:
					wrong_total += 1
				if r["stuck"] or r["wrong"]:
					print("  FAIL %s from %s -> %s" % [id, start, r["info"]])
	print("char runs=%d stuck=%d wrong_place=%d" % [runs, stuck_total, wrong_total])
	# odalar
	var rs := 0
	var rbad := 0
	for room in PalaceLayout.ROOMS.keys():
		for start in ["avlu", "bahce", "harem"]:
			if start == room:
				continue
			var r2: Dictionary = await _run_room(room, start)
			rs += 1
			if r2["stuck"] or r2["wrong"]:
				rbad += 1
				print("  FAIL room %s from %s -> %s" % [room, start, r2["info"]])
	print("room runs=%d bad=%d" % [rs, rbad])
	print("npc stuck teleports=", NPCNode.stuck_teleports)
	get_tree().quit()


func _objs() -> void:
	var bad := 0
	for it in game.interactables():
		var start := "avlu"
		await _place(start)
		var p: PlayerController = game.player
		var goal: Vector3 = it["pos"]
		if not p.walk_to(goal):
			print("  NO PATH ", it["label"])
			bad += 1
			continue
		var r: Dictionary = await _watch(func(): return goal, 2.0)
		var y := p.global_position.y
		print("  %s -> %s y=%.2f t=%.1f %s" % [it["label"], "OK" if not (r["stuck"] or r["wrong"]) else "FAIL", y, r.get("t", 0.0), r["info"]])
		if r["stuck"] or r["wrong"]:
			bad += 1
	# basamaklı alanlara elle yürüme: köşk ve kürsülerin üstüne
	for tgt in [Vector3(0, 0.4, 73), Vector3(53.5, 0.3, 33.5), Vector3(0, 0.2, -52), Vector3(-27, 0.3, 38.8), Vector3(-49, 0.24, 38.6)]:
		await _place(PalaceLayout.room_at_v(tgt))
		var p2: PlayerController = game.player
		var ok := p2.walk_to(tgt)
		var r2: Dictionary = await _watch(func(): return tgt, 1.0)
		print("  platform %s path=%s -> y=%.2f %s %s" % [_v(tgt), ok, p2.global_position.y, "OK" if not (r2["stuck"] or r2["wrong"]) else "FAIL", r2["info"]])
	print("objects bad=", bad)


func _low_steps() -> void:
	# yerden yükselen, 0.12-0.55 m yüksekliğinde çarpışma kutuları (tırmanılamaz basamaklar)
	var n := 0
	for cs in game.builder.body.get_children():
		var sh: Shape3D = cs.shape
		var top := 0.0
		var bottom := 0.0
		if sh is BoxShape3D:
			top = cs.position.y + sh.size.y * 0.5
			bottom = cs.position.y - sh.size.y * 0.5
		elif sh is CylinderShape3D:
			top = cs.position.y + sh.height * 0.5
			bottom = cs.position.y - sh.height * 0.5
		if bottom < 0.05 and top > 0.12 and top < 0.55:
			n += 1
	print("low step colliders (0.12-0.55m)=", n)


func _place(start: String) -> void:
	var p: PlayerController = game.player
	p.stop_auto()
	if p.seated:
		p.stand_up()
	p.global_position = game._snap(PalaceLayout.anchor(start)) + Vector3(0, 0.05, 0)
	p.velocity = Vector3.ZERO
	for i in range(5):
		await get_tree().physics_frame


func _run_char(id: String, start: String) -> Dictionary:
	await _place(start)
	var n: NPCNode = game.npcs.node_for(id)
	game.walk_to_char(id)
	var r: Dictionary = await _watch(func(): return n.global_position, 2.7)
	if r["wrong"]:
		r["info"] += " | retries=%d npc_state=%s near=%s act=%s" % [game.player._follow_retries, n.state, n._near, GameState.ch(id).get("activity", "")]
	return r


func _run_room(room: String, start: String) -> Dictionary:
	await _place(start)
	game.walk_to_room(room)
	var tgt: Vector3 = game._snap(PalaceLayout.anchor(room))
	return await _watch(func(): return tgt, 1.5)


func _watch(goal: Callable, ok_dist: float) -> Dictionary:
	var p: PlayerController = game.player
	var last := p.global_position
	var still := 0.0
	var t := 0.0
	var res := {"stuck": false, "wrong": false, "info": ""}
	var blk := [false]
	var cb := func(): blk[0] = true
	p.blocked.connect(cb)
	while t < 90.0:
		await get_tree().physics_frame
		var dt := 1.0 / 60.0
		t += dt
		if p._stuck_n > int(res.get("hic", 0)):
			res["hic"] = p._stuck_n
			res["hic_at"] = "%s %s %s" % [_v(p.global_position), PalaceLayout.room_at_v(p.global_position), _hit(p)]
		if not p.auto_walking:
			break
		if still > 1.2 and not res.has("slow"):
			res["slow"] = "%s" % _hit(p)
		if p.global_position.distance_to(last) < 0.004:
			still += dt
		else:
			still = 0.0
		last = p.global_position
		if still > 6.0:
			res["stuck"] = true
			res["info"] = "stuck at %s room=%s %s | idx=%d/%d" % [_v(p.global_position), PalaceLayout.room_at_v(p.global_position), _hit(p), p.mover.idx, p.mover.path.size()]
			p.stop_auto()
			return res
	p.blocked.disconnect(cb)
	if blk[0]:
		res["stuck"] = true
		res["info"] = "BLOCKED at %s room=%s %s" % [_v(p.global_position), PalaceLayout.room_at_v(p.global_position), res.get("slow", "")]
		return res
	if p.auto_walking:
		res["stuck"] = true
		res["info"] = "timeout at %s" % _v(p.global_position)
		p.stop_auto()
		return res
	if int(res.get("hic", 0)) > 0:
		print("    hiccup n=%d at %s" % [res["hic"], res["hic_at"]])
	res["t"] = t
	var g: Vector3 = goal.call()
	var d := Vector2(g.x - p.global_position.x, g.z - p.global_position.z).length()
	if d > ok_dist:
		res["wrong"] = true
		res["info"] = "ended %.1fm away at %s (%s) goal %s (%s) t=%.1f" % [d, _v(p.global_position), PalaceLayout.room_at_v(p.global_position), _v(g), PalaceLayout.room_at_v(g), t]
	return res


func _hit(p: PlayerController) -> String:
	var s := ""
	for i in range(p.get_slide_collision_count()):
		var c := p.get_slide_collision(i)
		var sh = c.get_collider_shape()
		if sh is CollisionShape3D:
			var shape: Shape3D = sh.shape
			var sz := ""
			if shape is BoxShape3D:
				sz = _v(shape.size)
			elif shape is CylinderShape3D:
				sz = "cyl r%.2f h%.2f" % [shape.radius, shape.height]
			s += "[%s %s @%s n=%s]" % [c.get_collider().name, sz, _v(sh.global_position), _v(c.get_normal())]
		else:
			s += "[%s]" % str(c.get_collider())
	return s


func _v(v: Vector3) -> String:
	return "(%.1f,%.2f,%.1f)" % [v.x, v.y, v.z]
