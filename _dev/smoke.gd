extends Node
## Geliştirme amaçlı duman testi (dışa aktarılan oyuna dahil edilmez).

func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	GameState.new_game("Test", 1)
	print("new_game ok, npcs=", GameState.npc_ids().size(), " pending=", EventEngine.pending(GameState).size(), " agenda=", DivanEngine.agenda(GameState).size(), " petitions=", PetitionEngine.list(GameState).size())
	var b := Economy.budget(GameState)
	print("budget gelir=", int(b["gelir"]), " gider=", int(b["giderler"]["toplam"]), " net=", int(b["net"]))
	# diyalog: her karakterle her konu
	var n_lines := 0
	for id in GameState.npc_ids():
		var g := DialogueEngine.greeting(GameState, id)
		n_lines += 1
		for t in DialogueEngine.topics(GameState, id):
			var r: Dictionary = DialogueEngine.choose(GameState, id, t["id"], "")
			n_lines += 1
			if r["sub"].size() > 0:
				var s0: Dictionary = r["sub"][0]
				if not s0.get("disabled", false):
					var r2: Dictionary = DialogueEngine.choose(GameState, id, s0["id"], s0.get("arg", ""))
					if r2["sub"].size() > 0:
						var s1: Dictionary = r2["sub"][0]
						DialogueEngine.choose(GameState, id, s1["id"], s1.get("arg", ""))
	print("dialogue ok lines=", n_lines, " time=", GameState.time_string(), " day=", GameState.get_day())
	# divan ve dilekçe
	var ag := DivanEngine.agenda(GameState)
	if not ag.is_empty():
		print("divan: ", ag[0]["title"], " -> ", DivanEngine.decide(GameState, ag[0]["uid"], 0))
	var pt := PetitionEngine.list(GameState)
	if not pt.is_empty():
		print("dilekce -> ", PetitionEngine.decide(GameState, pt[0]["uid"], 0))
	# olaylar
	for ev in EventEngine.pending(GameState).duplicate():
		var opts := EventEngine.options_for(GameState, ev)
		print("olay: ", ev["title"], " seçenek=", opts.size())
		if ev.get("talk", "") == "":
			print("  -> ", EventEngine.resolve(GameState, ev["uid"], 0))
	# zaman: 90 gün
	for d in range(90):
		GameState.advance_minutes(1440)
		if d % 15 == 14:
			var bb := Economy.budget(GameState)
			print("gün ", GameState.get_day(), " ", GameState.date_string(), " hazine=", int(GameState.treasury()), " net=", int(bb["net"]), " huzur=", int(GameState.people_huzur()), " fiyat=", "%.2f" % float(GameState.w["state"]["food_price"]), " bekleyen=", EventEngine.pending(GameState).size(), " kulis=", GameState.w["npc_log"].size())
		# bekleyen olayları çöz
		for ev2 in EventEngine.pending(GameState).duplicate():
			if ev2.get("talk", "") == "" and GameState.rng.randf() < 0.5:
				var o2 := EventEngine.options_for(GameState, ev2)
				var pick := GameState.rng.randi() % o2.size()
				if o2[pick]["available"] and o2[pick]["affordable"]:
					EventEngine.resolve(GameState, ev2["uid"], pick)
			elif ev2.get("talk", "") != "" and GameState.rng.randf() < 0.4:
				var r3 := DialogueEngine.choose(GameState, ev2["talk"], "ev:" + String(ev2["uid"]), "")
				if r3["sub"].size() > 0:
					DialogueEngine.choose(GameState, ev2["talk"], r3["sub"][0]["id"], r3["sub"][0]["arg"])
		var ag2 := DivanEngine.agenda(GameState)
		if not ag2.is_empty() and d % 3 == 0:
			var oo := DivanEngine.options_for(GameState, ag2[0])
			DivanEngine.decide(GameState, ag2[0]["uid"], oo.size() - 1 if not oo[0]["affordable"] else 0)
	print("events history=", GameState.w["events"]["history"].size())
	for h in GameState.w["events"]["history"]:
		print("  ", h["day"], " ", h["title"])
	print("kulis örnek:")
	for i in range(mini(8, GameState.w["npc_log"].size())):
		print("  ", GameState.w["npc_log"][GameState.w["npc_log"].size() - 1 - i]["text"])
	# kayıt / yükleme
	var tr_before := GameState.treasury()
	var day_before := GameState.get_day()
	var ok := SaveSystem.save_game("3")
	print("save ok=", ok)
	GameState.w = {}
	var ok2 := SaveSystem.load_game("3")
	print("load ok=", ok2, " treasury match=", absf(GameState.treasury() - tr_before) < 0.01, " day match=", GameState.get_day() == day_before, " type(time)=", typeof(GameState.w["time"]))
	GameState.advance_minutes(600)
	print("after load advance ok ", GameState.time_string())
	SaveSystem.delete_slot("3")
	print("logic time ms=", Time.get_ticks_msec() - t0)
	# saray inşası ve navigasyon
	var t1 := Time.get_ticks_msec()
	var pb := PalaceBuilder.new()
	add_child(pb)
	pb.build_all()
	print("palace built ms=", Time.get_ticks_msec() - t1, " meshes=", pb.geo_root.get_child_count(), " colliders=", pb.body.get_child_count(), " spots rooms=", pb.spots.size(), " interact=", pb.interactables.size())
	var tris := 0
	for mi in pb.geo_root.get_children():
		var m: ArrayMesh = mi.mesh
		tris += m.surface_get_array_len(0) / 3
	print("triangles=", tris)
	var t2 := Time.get_ticks_msec()
	pb.nav_region.bake_navigation_mesh(false)
	print("nav bake ms=", Time.get_ticks_msec() - t2, " polys=", pb.nav_region.navigation_mesh.get_polygon_count(), " verts=", pb.nav_region.navigation_mesh.vertices.size())
	var map := pb.nav_region.get_navigation_map()
	var waited := 0
	while waited < 240 and NavigationServer3D.map_get_closest_point(map, Vector3(0, 0, 6)).y < 0.1:
		await get_tree().process_frame
		waited += 1
	print("nav synced after frames=", waited, " iter=", NavigationServer3D.map_get_iteration_id(map), " regions=", NavigationServer3D.map_get_regions(map).size(), " active=", NavigationServer3D.map_is_active(map), " closest=", NavigationServer3D.map_get_closest_point(map, Vector3(0, 0, 6)))
	var bad := 0
	for rid in PalaceLayout.ROOMS.keys():
		var a := NavigationServer3D.map_get_closest_point(map, PalaceLayout.anchor("avlu"))
		var bpt := NavigationServer3D.map_get_closest_point(map, PalaceLayout.anchor(rid))
		var path := NavigationServer3D.map_get_path(map, a, bpt, true)
		var end_ok := path.size() > 0 and path[path.size() - 1].distance_to(bpt) < 0.6
		var anc_ok := bpt.distance_to(PalaceLayout.anchor(rid)) < 1.5
		if not end_ok or not anc_ok:
			bad += 1
			print("  NAV PROBLEM ", rid, " path=", path.size(), " anchor_snap_dist=", bpt.distance_to(PalaceLayout.anchor(rid)))
	print("nav rooms checked, problems=", bad)
	# spot erişilebilirliği
	var spot_bad := 0
	for room in pb.spots.keys():
		for sp in pb.spots[room]:
			var q := NavigationServer3D.map_get_closest_point(map, sp["pos"])
			if Vector2(q.x - sp["pos"].x, q.z - sp["pos"].z).length() > 0.9:
				spot_bad += 1
				if spot_bad < 15:
					print("  SPOT off-nav ", room, " ", sp["type"], " ", sp["pos"], " -> ", q)
	print("spots off nav=", spot_bad)
	get_tree().quit()
