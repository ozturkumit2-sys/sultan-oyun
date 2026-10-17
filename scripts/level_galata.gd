extends Node3D
## Bölüm 1 — Galata Çatıları. Karaköy waterfront up the hill to the top of Galata Tower.

const TOWER := Vector3(0, 8.0, -85.0)
const TOWER_R := 4.6
const BALCONY_Y := 30.0

var city: City
var fish: FishField
var player: Player
var cam: Node3D
var hud: CanvasLayer
var sun: DirectionalLight3D
var checkpoints: Array[Checkpoint] = []
var path_rects: Array[Rect2] = []   # occupied footprints (avoid background overlap)
var finished := false
var hint_zones: Array = []          # [Vector3 centre, radius, text]
var current_hint := ""


func ground(z: float) -> float:
	if z >= 30.0:
		return 0.0
	if z <= -60.0:
		return 8.0
	var t := (30.0 - z) / 90.0
	return 8.0 * t * t * (3.0 - 2.0 * t)


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	var q: int = GameState.settings["quality"]
	get_viewport().scaling_3d_scale = 1.0 if q > 0 else 0.75
	sun = WorldEnv.make_environment(self, q)
	WorldEnv.make_sea(self)
	city = City.new(self, 21)
	city.ground_fn = ground
	fish = FishField.new()
	add_child(fish)

	_build_ground()
	_section_start()
	_section_awning_street()
	_section_chimneys()
	_section_tram()
	_section_alley()
	_section_tower()
	_build_background()
	WorldEnv.make_skyline(city)
	var t1 := Time.get_ticks_msec()
	city.commit(self)
	fish.build()
	_ambient()
	print("LEVEL BUILD ms: gen=", t1 - t0, " commit=", Time.get_ticks_msec() - t1)

	# player & camera
	player = Player.new()
	add_child(player)
	player.global_position = Vector3(0, 6.2, 46.5)
	player.kill_height = func(p: Vector3) -> float: return ground(p.z) + 0.9
	cam = preload("res://scripts/cam_rig.gd").new()
	add_child(cam)
	player.cam_rig = cam
	cam.setup(player, 0.0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("spawn="):
			var v := a.substr(6).split(",")
			player.global_position = Vector3(float(v[0]), float(v[1]), float(v[2]))
			if v.size() > 3:
				cam.snap_to(deg_to_rad(float(v[3])))
			if v.size() > 4:
				cam.pitch = deg_to_rad(float(v[4]))
			if v.size() > 5:
				cam.base_distance = float(v[5])
				cam.distance = float(v[5])
	hud = preload("res://scripts/hud.gd").new()
	add_child(hud)
	hud.restart_requested.connect(func(): get_tree().reload_current_scene())
	hud.menu_requested.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	GameState.reset_run(fish.total_value())
	GameState.running = false
	hud.set_totals(fish.total_value())
	hud.cam = cam.camera
	hud.goal_pos = TOWER + Vector3(0, BALCONY_Y - TOWER.y, 0)
	hud.goal_name = "Galata Kulesi"
	checkpoints[0].player = player
	checkpoints[0].activate(true)
	Sfx.play_music("res://assets/audio/music_galata.ogg", -8.0)
	Sfx.play_ambience("res://assets/audio/ambience_city.ogg")
	await get_tree().process_frame
	var skip_intro := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("spawn=") or a == "showresults" or a == "showpause" or a == "nointro":
			skip_intro = true
	if (skip_intro or get_parent() != get_tree().root) and not ("intro" in OS.get_cmdline_user_args()):
		_start_level()
	else:
		player.control_enabled = false
		hud.show_intro("Bölüm 1 · Galata Çatıları",
			"İstanbul'un yavru kedileri çatılarda kayboldu! Tarçın onları bulup Galata Kulesi'nin tepesindeki altın balığa ulaşmalı.",
			[["tower", "Galata Kulesi'nin tepesine çık"], ["kitten", "5 kayıp yavruyu kurtar (miyavlarını dinle)"],
			["fish", "Balıkları topla, altın balıklar 5 sayar"]], _start_level)


func _start_level() -> void:
	player.control_enabled = true
	GameState.running = true
	hud.end_intro_ui()
	hud.show_banner("Bölüm 1 · Galata Çatıları")
	if "stats" in OS.get_cmdline_user_args():
		_print_stats()
	if "showresults" in OS.get_cmdline_user_args():
		GameState.add_fish(87)
		GameState.find_kitten("duman", "Duman")
		GameState.find_kitten("tekir", "Tekir")
		hud.show_results({"record": true})
	if "showpause" in OS.get_cmdline_user_args():
		hud.toggle_pause()


func _print_stats() -> void:
	var tot := 0
	var buckets := {}
	var n_mi := 0
	for mi in find_children("*", "MeshInstance3D", true, false):
		n_mi += 1
		var m = mi.mesh
		if not (m is ArrayMesh):
			continue
		for si in m.get_surface_count():
			var c: int = m.surface_get_array_len(si)
			tot += c
			var k: String = String(mi.name).split("_")[1] if String(mi.name).begins_with("City_") else "other"
			buckets[k] = buckets.get(k, 0) + c
	print("mesh instances: ", n_mi, " total verts: ", tot)
	print(buckets)
	print("collision shapes: ", find_children("*", "CollisionShape3D", true, false).size())


func _process(_delta: float) -> void:
	if player == null or finished:
		return
	# tutorial hints
	var best := ""
	for hz in hint_zones:
		if player.global_position.distance_to(hz[0]) < hz[1]:
			best = hz[2]
			break
	if best != current_hint:
		current_hint = best
		if best == "":
			hud.hide_hint()
		else:
			hud.show_hint(best)
	# camera framing around the tower climb
	var to_t := Vector2(player.global_position.x - TOWER.x, player.global_position.z - TOWER.z)
	if to_t.length() < 11.0 and player.global_position.y > 22.0:
		var f := -Vector3(to_t.x, 0, to_t.y).normalized()
		cam.set_hint(atan2(-f.x, -f.z), 1.6, deg_to_rad(-16.0), 9.0)
	else:
		cam.clear_hint()


func hint(p: Vector3, r: float, text: String) -> void:
	hint_zones.append([p, r, text])


func reserve(cx: float, cz: float, w: float, d: float) -> void:
	path_rects.append(Rect2(cx - w * 0.5 - 1.0, cz - d * 0.5 - 1.0, w + 2.0, d + 2.0))


## Path house helper: reserves footprint, high detail.
func ph(cx: float, cz: float, w: float, d: float, top: float, opts := {}) -> float:
	reserve(cx, cz, w, d)
	opts["detail"] = true
	return city.house(cx, cz, w, d, top, opts)


func checkpoint(p: Vector3, yaw := 0.0) -> void:
	var c := Checkpoint.new()
	c.yaw = yaw
	add_child(c)
	c.global_position = p
	checkpoints.append(c)


func kitten(p: Vector3, id: String, name: String, coat: String, parent: Node3D = null) -> void:
	var k := Kitten.new()
	k.id = id
	k.display_name = name
	k.coat = coat
	if parent:
		parent.add_child(k)
		k.position = p
	else:
		add_child(k)
		k.global_position = p


func gull(c: Vector3, r: float, h: float, spd := 1.0) -> void:
	var g := Seagull.new()
	g.center = c
	g.radius = r
	g.height = h
	g.speed = spd
	add_child(g)


func pigeons(p: Vector3, n := 6) -> void:
	var f := PigeonFlock.new()
	f.count = n
	add_child(f)
	f.global_position = p


func sign3d(p: Vector3, text: String, yaw := 0.0) -> void:
	# a little wooden sign on a post
	city.at(p)
	city.mb("wood").box(p + Vector3(0, 0.55, 0), Vector3(0.1, 1.1, 0.1), City.lin("6e4a32"))
	city.mb("wood").box(p + Vector3(0, 1.25, 0), Vector3(1.5, 0.6, 0.08), City.lin("c79a62"), yaw, true)
	var l := Label3D.new()
	l.text = text
	l.font = UIKit.font(800)
	l.font_size = 40
	l.modulate = UIKit.NAVY
	l.outline_size = 0
	l.pixel_size = 0.0055
	l.width = 260
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.position = p + Vector3(0, 1.25, 0) + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.06)
	l.rotation.y = yaw
	add_child(l)


func bouncer_on_awning(center: Vector3, n: Vector3, width: float, strength := 17.0) -> void:
	city.awning(center, n, width, 1.6, 0.5, ["e8473a", "fff4e0"] if randf() < 0.5 else ["2a8f86", "fff4e0"])
	var bo := Bouncer.new()
	bo.strength = strength
	var u := n.cross(Vector3.UP).normalized()
	bo.size = Vector3(width, 0.7, 1.6) if abs(n.z) > 0.5 else Vector3(1.6, 0.7, width)
	add_child(bo)
	bo.global_position = center + n * 0.8 + Vector3(0, -0.45, 0)


func carpet_bridge(a: Vector3, b: Vector3, width := 1.4) -> void:
	city.at((a + b) * 0.5)
	var dir := b - a
	var right := dir.cross(Vector3.UP).normalized()
	city.clothesline(a + right * width * 0.5, b + right * width * 0.5, false, true)
	city.clothesline(a - right * width * 0.5, b - right * width * 0.5, false, true)
	# kilim: rows of coloured bands with zigzag motif
	var cols := ["b5322e", "e2a33a", "1f4e9c", "f3e3c3", "2a8f86", "7a2a3a"]
	var segs := int(dir.length() / 0.45)
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var p0 := a.lerp(b, t0) + Vector3(0, -sin(t0 * PI) * 0.12 - 0.02, 0)
		var p1 := a.lerp(b, t1) + Vector3(0, -sin(t1 * PI) * 0.12 - 0.02, 0)
		var c := City.lin(cols[(i / 2) % cols.size()] if i % 7 != 3 else "f3e3c3")
		city.mb("cloth").quad_uv(p0 - right * width * 0.5, p0 + right * width * 0.5, p1 + right * width * 0.5, p1 - right * width * 0.5, c, Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0))
		city.mb("cloth").quad_uv(p1 - right * width * 0.5, p1 + right * width * 0.5, p0 + right * width * 0.5, p0 - right * width * 0.5, c.darkened(0.2), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0))
	var mid := (a + b) * 0.5
	var flat := Vector2(dir.x, dir.z).length()
	var basis := Basis(Vector3.UP, atan2(dir.x, dir.z)) * Basis(Vector3.RIGHT, -atan2(dir.y, flat))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width + 0.3, 0.2, dir.length())
	cs.shape = bs
	cs.transform = Transform3D(basis, mid + Vector3(0, -0.2, 0))
	city.body.add_child(cs)


func balcony(p: Vector3, n: Vector3, width := 2.4, depth := 1.2) -> void:
	city.at(p)
	var size := Vector3(width, 0.22, depth) if abs(n.z) > 0.5 else Vector3(depth, 0.22, width)
	var c := p + n * depth * 0.5
	city.mb("plain").box(c, size, City.lin("e9e0d2"), 0.0, true)
	city.col_box(c, size)
	# railing (visual only, low)
	var u := n.cross(Vector3.UP).normalized()
	var front := p + n * (depth - 0.05)
	for i in 9:
		var x := -width * 0.5 + width * i / 8.0
		city.mb("plain").box(front + u * x + Vector3(0, 0.35, 0), Vector3(0.05, 0.6, 0.05), City.lin("3b3b45"))
	city.mb("plain").box(front + Vector3(0, 0.66, 0), Vector3(width, 0.05, 0.06) if abs(n.z) > 0.5 else Vector3(0.06, 0.05, width), City.lin("3b3b45"))


# =====================================================================
func _build_ground() -> void:
	# sloped streets (cobbles) covering the Galata hill, plus the quay
	var xs := 22
	var x0 := -120.0
	var x1 := 120.0
	var z0 := -175.0
	var z1 := 56.0
	var zsteps := 60
	for zi in zsteps:
		var za := lerpf(z1, z0, float(zi) / zsteps)
		var zb := lerpf(z1, z0, float(zi + 1) / zsteps)
		for xi in xs:
			var xa := lerpf(x0, x1, float(xi) / xs)
			var xb := lerpf(x0, x1, float(xi + 1) / xs)
			city.at(Vector3((xa + xb) * 0.5, 0, (za + zb) * 0.5))
			var col := City.lin("8c7c74")
			city.mb("street").quad(Vector3(xa, ground(za), za), Vector3(xb, ground(za), za), Vector3(xb, ground(zb), zb), Vector3(xa, ground(zb), zb), col)
	# quay edge & wall
	city.at(Vector3(0, 0, 56))
	city.mb("stone").box(Vector3(0, -0.8, 57), Vector3(240, 1.6, 2.0), City.lin("b9aa98"))
	city.mb("plain").box(Vector3(0, 0.05, 55.5), Vector3(240, 0.1, 1.0), City.lin("d8cfc3"))
	# bollards
	for i in 30:
		city.mb("plain").cylinder(Vector3(-110 + i * 7.5, 0, 55.6), 0.25, 0.6, City.lin("3a3a44"), 8)
	# lamp posts along the waterfront
	for i in 16:
		var lp := Vector3(-60 + i * 8.0, 0, 52.0)
		_lamp(lp)


func _lamp(p: Vector3) -> void:
	city.at(p)
	city.mb("plain").cylinder(p, 0.09, 3.6, City.lin("2f3540"), 8)
	city.mb("plain").box(p + Vector3(0, 3.62, 0), Vector3(0.4, 0.08, 0.4), City.lin("2f3540"))
	city.mb("lit").box(p + Vector3(0, 3.85, 0), Vector3(0.3, 0.38, 0.3), City.lin("ffd27a"))
	city.mb("plain").box(p + Vector3(0, 4.08, 0), Vector3(0.42, 0.08, 0.42), City.lin("2f3540"))


# ===================================================================== S0
func _section_start() -> void:
	# B0 — start roof by the quay
	ph(0, 44, 10, 8, 6.0, {"hex": "f0c9a8", "shops": true, "faces": ["s", "e", "w", "n"]})
	city.water_tank(Vector3(3.4, 6.0, 46.6))
	city.antenna(Vector3(-3.6, 6.0, 47.0))
	city.dish(Vector3(-3.8, 6.0, 42.5), 2.0)
	checkpoint(Vector3(0, 6.0, 46.5), 0.0)
	fish.line(Vector3(0, 6.6, 45.0), Vector3(0, 6.6, 41.2), 4)
	sign3d(Vector3(-2.6, 6.0, 41.4), "Zıpla!  Boşluğun üstünden atla", 0.0)
	hint(Vector3(0, 6.5, 42), 4.0, "Zıplamak için pati düğmesine bas")
	# B1
	ph(0, 35, 8, 6, 6.6, {"hex": "c9d6b8"})
	fish.arc(Vector3(0, 7.2, 40.3), Vector3(0, 7.4, 37.6), 1.3, 4)
	fish.line(Vector3(-1.5, 7.2, 35.5), Vector3(1.5, 7.2, 35.5), 3)
	var ctop := city.chimney(Vector3(2.6, 6.6, 33.6))
	fish.add(Vector3(2.6, ctop + 0.6, 33.6), true)
	# B2
	ph(2, 26.5, 8, 7, 7.8, {"hex": "e9b98f"})
	fish.line(Vector3(2, 8.4, 29.2), Vector3(2, 8.4, 24.2), 5)
	pigeons(Vector3(4.2, 7.8, 25.5), 6)
	checkpoint(Vector3(-0.5, 7.8, 24.6), 0.0)
	city.antenna(Vector3(-1.2, 7.8, 28.6))
	# B3 — pitched roof, ridge runs north
	ph(2, 17.5, 6, 8, 7.6, {"roof": "gable_x", "roof_h": 1.6, "hex": "f4e7d2"})
	fish.arc(Vector3(2, 8.6, 20.8), Vector3(2, 8.6, 14.2), 1.4, 6)
	hint(Vector3(2, 8.6, 20.0), 3.0, "Kiremitlerin üstünden aş!")


# ===================================================================== S1
func _section_awning_street() -> void:
	# B4 — tall building across the awning street
	ph(2, 0, 14, 8, 13.0, {"hex": "d98f6c", "shops": true, "faces": ["s", "n", "e", "w"]})
	# carpet bridge from B3 gable end to under the cumba
	carpet_bridge(Vector3(1.4, 7.75, 13.1), Vector3(1.4, 8.6, 5.0), 1.4)
	fish.line(Vector3(1.4, 9.3, 12.4), Vector3(1.4, 9.5, 6.0), 6)
	hint(Vector3(1.4, 9.0, 9.0), 3.0, "Halının üstünde dikkatli yürü")
	# cumba (bay window) on B4's south facade
	var ctop := city.cumba(Vector3(4.5, 9.0, 4.0), Vector3(0, 0, 1), 2.6, 2.0, 1.0)
	fish.add(Vector3(4.5, ctop + 0.6, 4.5))
	sign3d(Vector3(6.8, 13.0, 3.0), "Havada tekrar zıpla: çift zıplama!", PI)
	hint(Vector3(2.5, 9.3, 5.5), 2.6, "Havadayken tekrar zıpla: çift zıplama")
	# awnings = safety net & alternative route (bounce!)
	for x in [-3.0, 2.0, 6.5]:
		bouncer_on_awning(Vector3(x, ground(4.0) + 3.6, 4.02), Vector3(0, 0, 1), 3.0, 17.0)
	bouncer_on_awning(Vector3(-0.4, ground(13.5) + 3.4, 13.48), Vector3(0, 0, -1), 1.8, 16.5)
	fish.ring(Vector3(-3.0, 8.6, 5.6), 1.0, 6)
	# Kitten 1 — Duman, on a balcony just below the carpet bridge
	balcony(Vector3(3.8, 6.2, 13.5), Vector3(0, 0, -1), 2.4, 1.2)
	kitten(Vector3(3.8, 6.32, 12.9), "duman", "Duman", "duman")
	hint(Vector3(3.8, 7.0, 12.9), 2.0, "Halıya geri dönmek için çift zıpla")
	# street dressing
	for x in [-6.0, 9.5]:
		_lamp(Vector3(x, ground(9.0), 9.0))
	# cats-eye view: neighbours either side of the street
	ph(-7, 17.5, 7, 8, 9.5, {"roof": "hip", "faces": ["n", "s", "w", "e"]})
	ph(11, 17.0, 8, 7, 8.6, {"roof": "gable_x", "faces": ["n", "s", "e"]})
	ph(-9.5, 0, 6, 8, 11.5, {"faces": ["s", "w", "n"], "props": true})
	ph(13.5, 0.5, 8, 7, 12.0, {"roof": "hip", "faces": ["s", "e", "n"]})
	checkpoint(Vector3(7.0, 13.0, -1.5), 0.0)


# ===================================================================== S2
func _section_chimneys() -> void:
	fish.ring(Vector3(2, 13.6, 0.0), 2.2, 8)
	gull(Vector3(1.0, 13.0, -0.5), 3.4, 3.0, 0.9)
	sign3d(Vector3(-3.5, 13.0, 2.5), "Martıların üstüne zıpla!", 0.0)
	hint(Vector3(0, 13.5, 0), 5.5, "Martının üstüne düş ya da atıl (ok düğmesi)")
	# B5
	ph(2, -9, 10, 6, 14.0, {"hex": "b9cfd6", "props": false})
	var c1 := city.chimney(Vector3(-1.5, 14.0, -9.0), true, 1.5)
	fish.add(Vector3(-1.5, c1 + 0.6, -9.0), true)
	var t1 := city.water_tank(Vector3(5.2, 14.0, -10.4))
	fish.add(Vector3(5.2, t1 + 0.6, -10.4))
	fish.line(Vector3(2, 14.6, -6.6), Vector3(2, 14.6, -11.4), 4)
	gull(Vector3(2.0, 14.0, -9.0), 3.0, 3.2, 1.2)
	# B6
	ph(2, -17.5, 8, 7, 15.5, {"hex": "efe2c4"})
	pigeons(Vector3(0.0, 15.5, -16.5), 5)
	checkpoint(Vector3(-0.8, 15.5, -15.0), 0.0)
	# Kitten 2 — Kömür on a tall chimney stack (double jump)
	var c2 := city.chimney_stack(Vector3(4.4, 15.5, -19.4), 2.8)
	city.crate(Vector3(2.7, 15.5, -19.6), 1.1)
	kitten(Vector3(4.4, c2, -19.4), "komur", "Kömür", "komur")
	fish.arc(Vector3(2.5, 16.0, -18.0), Vector3(4.4, c2 + 0.4, -19.4), 1.6, 4)
	hint(Vector3(3.6, 15.6, -18.6), 3.0, "Yüksek bacaya çift zıplamayla çık")
	# B7 — gable along X, ridge you can run
	ph(2, -25.5, 9, 6, 15.5, {"roof": "gable_x", "roof_h": 1.5, "hex": "e7a98c"})
	fish.line(Vector3(-2.0, 17.6, -25.5), Vector3(6.0, 17.6, -25.5), 6)
	# side buildings
	ph(-6.5, -9.5, 6, 8, 12.5, {"roof": "hip", "props": false})
	ph(11.0, -10.0, 7, 9, 13.0, {"props": true})
	ph(-6.0, -20.0, 7, 9, 13.8, {"roof": "gable_z"})
	ph(11.5, -21.5, 8, 8, 14.2, {"props": true})


# ===================================================================== S3
func _section_tram() -> void:
	# the tram street runs east-west at z ≈ -33.3
	var gz := ground(-33.3)
	var tram := Tram.new()
	tram.a = Vector3(-14.0, gz, -33.3)
	tram.b = Vector3(13.0, gz, -33.3)
	tram.speed = 3.4
	add_child(tram)
	# Kitten 3 — Pamuk rides on the tram roof
	kitten(Vector3(-2.2, 2.62, 0.0), "pamuk", "Pamuk", "pamuk", tram)
	sign3d(Vector3(5.5, 15.5, -24.0), "Tramvayın üstüne atla!", 0.0)
	hint(Vector3(2.0, 16.5, -27.5), 3.5, "Tramvay altından geçerken atla")
	# rails
	city.at(Vector3(0, 0, -33.3))
	for zr in [-34.0, -32.6]:
		city.mb("plain").box(Vector3(0, ground(zr) + 0.03, zr), Vector3(60, 0.06, 0.12), City.lin("9aa0a8"))
	# overhead wire poles
	for x in [-16.0, -4.0, 8.0, 20.0]:
		city.mb("plain").cylinder(Vector3(x, ground(-29.4), -29.4), 0.1, 5.2, City.lin("3a3d48"), 8)
	city.mb("plain").box(Vector3(2, ground(-33.3) + 3.6, -33.3), Vector3(60, 0.04, 0.04), City.lin("2a2d36"))
	# north side: B8 with an awning to bounce up from the tram's east end
	var b8top := ph(8, -42, 12, 8, 14.5, {"hex": "f2d7b0", "shops": true})
	bouncer_on_awning(Vector3(11.5, ground(-38.0) + 3.4, -38.02), Vector3(0, 0, 1), 3.2, 17.0)
	bouncer_on_awning(Vector3(5.0, ground(-38.0) + 3.4, -38.02), Vector3(0, 0, 1), 3.0, 17.0)
	fish.line(Vector3(-10, ground(-33.3) + 3.4, -33.3), Vector3(10, ground(-33.3) + 3.4, -33.3), 10)
	fish.arc(Vector3(11.5, ground(-38) + 4.6, -36.5), Vector3(11.5, b8top + 0.6, -39.5), 2.5, 4)
	pigeons(Vector3(9.0, b8top, -43.5), 6)
	checkpoint(Vector3(12.0, b8top, -41.0), PI * 0.5)
	# west & east neighbours across the tram street
	ph(-7.0, -42.0, 10, 8, 13.0, {"roof": "hip", "shops": true})
	ph(19.5, -42.5, 9, 9, 13.5, {"roof": "gable_z", "shops": true})
	ph(-8.5, -26.0, 8, 6, 14.0, {"roof": "hip"})
	ph(13.0, -26.5, 8, 7, 14.5, {"props": true})


# ===================================================================== S4
func _section_alley() -> void:
	# annex floor of the alley (same height as B8, continuous)
	ph(4.0, -50.0, 3.0, 8.0, 14.5, {"hex": "cfa98a", "faces": []})
	# the two tall walls
	ph(0.0, -52.0, 5.0, 12.0, 21.2, {"hex": "f0c9a8", "faces": ["w", "e", "n", "s"]})
	ph(8.0, -52.0, 5.0, 12.0, 21.2, {"hex": "c9d6b8", "faces": ["w", "e", "n", "s"]})
	ph(4.0, -56.0, 3.0, 4.0, 16.0, {"hex": "d8c39a", "faces": ["s", "n"]})
	sign3d(Vector3(3.0, 14.5, -47.0), "Duvara tutun ve zıpla!", 0.0)
	hint(Vector3(4.0, 15.5, -50.0), 3.5, "Duvara doğru it ve zıpla: duvar zıplaması")
	# fish zig-zag up the alley
	for i in 5:
		var x := 3.2 if i % 2 == 0 else 4.8
		fish.add(Vector3(x, 15.8 + i * 1.2, -51.0))
	# Kitten 4 — Tekir on a window ledge halfway up
	city.at(Vector3(5.2, 18.6, -49.5))
	city.mb("plain").box(Vector3(5.1, 18.5, -49.0), Vector3(0.8, 0.22, 1.8), City.lin("efe6d8"), 0.0, true)
	city.col_box(Vector3(5.1, 18.5, -49.0), Vector3(0.8, 0.22, 1.8))
	kitten(Vector3(5.05, 18.62, -49.0), "tekir", "Tekir", "tekir")
	# top of the walls
	checkpoint(Vector3(0.0, 21.2, -55.0), 0.0)
	fish.line(Vector3(0, 21.8, -49), Vector3(0, 21.8, -57), 5)
	fish.add(Vector3(8.0, 22.2, -52.0), true)


# ===================================================================== S5
func _section_tower() -> void:
	# stepping roofs to the tower
	ph(0.0, -62.5, 6, 5, 22.8, {"hex": "e9b98f", "faces": ["e", "w", "n"]})
	ph(-2.0, -70.0, 5, 5, 23.5, {"hex": "f4e7d2", "faces": ["e", "w", "s"]})
	fish.line(Vector3(0, 23.4, -61), Vector3(-1.5, 24.1, -69), 5)
	checkpoint(Vector3(-2.5, 23.5, -69.0), 0.0)
	# scaffold platform between the roofs and the tower
	_scaffold(Vector3(-1.0, 24.2, -76.0))
	_tower()
	# spiral planks around the tower: (angle deg, y, kind)
	var steps := [[95, 25.0, 5.35], [130, 25.9, 5.35], [165, 26.8, 5.35], [205, 27.6, 6.9], [240, 28.4, 7.5]]
	var prev := Vector3.ZERO
	for i in steps.size():
		var a := deg_to_rad(steps[i][0])
		var y: float = steps[i][1]
		var r: float = steps[i][2]
		var c := TOWER + Vector3(cos(a) * r, 0, sin(a) * r)
		c.y = y
		var tangent_yaw := a  # plank long axis tangent to the tower
		city.plank(c, Vector3(1.5, 0.28, 2.4), -tangent_yaw)
		fish.add(c + Vector3(0, 0.7, 0))
		prev = c
	# a bonus plank further out with a golden fish (needs pounce)
	var ab := deg_to_rad(185.0)
	var bonus := TOWER + Vector3(cos(ab) * 11.0, 0, sin(ab) * 11.0)
	bonus.y = 27.0
	city.plank(bonus, Vector3(1.6, 0.28, 1.6), 0.0)
	fish.add(bonus + Vector3(0, 0.8, 0), true)
	# Kitten 5 — Bal waits on the bonus plank
	kitten(bonus + Vector3(0.3, 0.14, 0.3), "bal", "Bal", "bal")
	hint(TOWER + Vector3(-8.0, 20.0, 0.0), 4.0, "Uzak tahtaya atılarak (ok düğmesi) ulaş")
	gull(TOWER, 9.0, 21.0, 0.55)
	# goal on the balcony (north side)
	var g := Goal.new()
	add_child(g)
	g.global_position = TOWER + Vector3(0, BALCONY_Y - TOWER.y + 0.02, -(TOWER_R + 0.85))
	g.reached.connect(_on_goal)


func _scaffold(top: Vector3) -> void:
	city.at(top)
	var size := Vector3(2.4, 0.3, 2.4)
	city.mb("wood").box(top, size, City.lin("a9764a"), 0.0, true)
	city.col_box(top, size)
	var base_y := ground(top.z)
	for o in [Vector3(-1.0, 0, -1.0), Vector3(1.0, 0, -1.0), Vector3(1.0, 0, 1.0), Vector3(-1.0, 0, 1.0)]:
		var p: Vector3 = top + o
		var h := top.y - base_y
		city.mb("wood").box(Vector3(p.x, base_y + h * 0.5, p.z), Vector3(0.14, h, 0.14), City.lin("6e4a32"))
	for k in 6:
		var y := base_y + (top.y - base_y) * (k + 0.5) / 6.0
		city.mb("wood").box(Vector3(top.x, y, top.z - 1.0), Vector3(2.0, 0.08, 0.08), City.lin("7b5638"), 0.0)
		city.mb("wood").box(Vector3(top.x, y, top.z + 1.0), Vector3(2.0, 0.08, 0.08), City.lin("7b5638"), 0.0)


func _tower() -> void:
	var c := TOWER
	city.at(c)
	var stone := City.lin("cdbfae")
	var body_h := BALCONY_Y - c.y
	reserve(c.x, c.z, 34, 34)
	# plaza
	city.mb("stone").cylinder(c + Vector3(0, -0.3, 0), 14.0, 0.32, City.lin("b8aa9a"), 32)
	# base + body (slight taper)
	city.mb("stone").cylinder(c, TOWER_R + 0.5, 3.0, stone.darkened(0.08), 28, false)
	city.mb("stone").cylinder(c + Vector3(0, 3.0, 0), TOWER_R, body_h - 3.0, stone, 28, false, false, Color(-1, 0, 0), TOWER_R - 0.15)
	city.col_cyl(c, TOWER_R, body_h)
	# arched windows in rings
	for ring in 5:
		var y := c.y + 5.0 + ring * 3.6
		for k in 6:
			var a := TAU * k / 6.0 + ring * 0.5
			var n := Vector3(cos(a), 0, sin(a))
			var p := c + n * (TOWER_R - 0.05 - (y - c.y) / body_h * 0.15) + Vector3(0, y - c.y, 0)
			var u := n.cross(Vector3.UP).normalized()
			city.mb("glass").quad(p - u * 0.35 - Vector3(0, 0.7, 0) + n * 0.03, p + u * 0.35 - Vector3(0, 0.7, 0) + n * 0.03, p + u * 0.35 + Vector3(0, 0.5, 0) + n * 0.03, p - u * 0.35 + Vector3(0, 0.5, 0) + n * 0.03, City.lin("27303f"))
			city.mb("plain").quad(p - u * 0.5 - Vector3(0, 0.85, 0) + n * 0.015, p + u * 0.5 - Vector3(0, 0.85, 0) + n * 0.015, p + u * 0.5 + Vector3(0, 0.75, 0) + n * 0.015, p - u * 0.5 + Vector3(0, 0.75, 0) + n * 0.015, City.lin("efe6d8"))
	# balcony ring (walkable) with corbels
	var by := BALCONY_Y
	city.mb("stone").cylinder(Vector3(c.x, by - 0.45, c.z), TOWER_R + 1.6, 0.45, City.lin("e3d7c7"), 32, true, true)
	city.col_cyl(Vector3(c.x, by - 0.45, c.z), TOWER_R + 1.6, 0.45)
	for k in 24:
		var a2 := TAU * k / 24.0
		var n2 := Vector3(cos(a2), 0, sin(a2))
		city.mb("stone").box(Vector3(c.x, by - 0.9, c.z) + n2 * (TOWER_R + 0.6), Vector3(0.35, 0.6, 0.35), City.lin("bfb2a2"), -a2)
		# railing posts (visual only)
		city.mb("plain").box(Vector3(c.x, by + 0.35, c.z) + n2 * (TOWER_R + 1.5), Vector3(0.06, 0.7, 0.06), City.lin("2f3540"))
	for k in 48:
		var a3 := TAU * k / 48.0
		var a4 := TAU * (k + 1) / 48.0
		var p0 := Vector3(c.x, by + 0.7, c.z) + Vector3(cos(a3), 0, sin(a3)) * (TOWER_R + 1.5)
		var p1 := Vector3(c.x, by + 0.7, c.z) + Vector3(cos(a4), 0, sin(a4)) * (TOWER_R + 1.5)
		city._rope_seg(p0, p1, 0.04, City.lin("2f3540"))
	# upper drum with lit arched windows
	var drum_h := 3.6
	city.mb("stone").cylinder(Vector3(c.x, by, c.z), TOWER_R - 0.6, drum_h, City.lin("e8ddd0"), 28, false)
	city.col_cyl(Vector3(c.x, by, c.z), TOWER_R - 0.6, drum_h)
	for k in 12:
		var a5 := TAU * k / 12.0
		var n5 := Vector3(cos(a5), 0, sin(a5))
		var p5 := Vector3(c.x, by + 1.6, c.z) + n5 * (TOWER_R - 0.58)
		var u5 := n5.cross(Vector3.UP).normalized()
		city.mb("lit").quad(p5 - u5 * 0.4 - Vector3(0, 0.9, 0), p5 + u5 * 0.4 - Vector3(0, 0.9, 0), p5 + u5 * 0.4 + Vector3(0, 0.9, 0), p5 - u5 * 0.4 + Vector3(0, 0.9, 0), City.lin("ffcf7a"))
	city.mb("plain").cylinder(Vector3(c.x, by + drum_h, c.z), TOWER_R - 0.3, 0.3, City.lin("efe6d8"), 28)
	# conical roof + finial
	city.mb("roof").cone(Vector3(c.x, by + drum_h + 0.3, c.z), TOWER_R - 0.2, 8.5, City.lin("6f7e8f"), 28)
	city.mb("plain").cylinder(Vector3(c.x, by + drum_h + 8.6, c.z), 0.12, 1.6, City.lin("e8c25a"), 8)
	city.mb("plain").dome(Vector3(c.x, by + drum_h + 9.5, c.z), 0.3, City.lin("f2c94c"), 8, 3)
	# tower plaza dressing: little houses around
	for i in 10:
		var a6 := TAU * i / 10.0 + 0.2
		if abs(wrapf(a6 - PI * 0.5, -PI, PI)) < 0.7:
			continue  # keep the south side open for the scaffold
		var r6 := 17.0
		var hx := c.x + cos(a6) * r6
		var hz := c.z + sin(a6) * r6
		city.house(hx, hz, 7, 7, ground(hz) + randf_range(7.0, 11.0), {"roof": ["hip", "gable_x", "flat"][i % 3], "detail": true, "props": true})


# ===================================================================== background
func _build_background() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var z := 50.0
	while z > -168.0:
		var x := -110.0
		var depth := rng.randf_range(7.0, 10.0)
		while x < 110.0:
			var w := rng.randf_range(6.0, 10.0)
			var cx := x + w * 0.5
			var cz := z - depth * 0.5
			var near_path: bool = abs(cx - 2.0) < 13.0 and cz > -78.0
			var near_tower: bool = Vector2(cx - TOWER.x, cz - TOWER.z).length() < 24.0
			var blocked := false
			var r := Rect2(cx - w * 0.5, cz - depth * 0.5, w, depth)
			for pr in path_rects:
				if pr.intersects(r):
					blocked = true
					break
			if not near_path and not near_tower and not blocked and cz < 49.0:
				var dist: float = abs(cx) + max(0.0, -cz - 70.0)
				var detail := dist < 40.0
				var top := ground(cz) + rng.randf_range(7.0, 13.0)
				var roof: String = ["flat", "hip", "gable_x", "gable_z", "flat"][rng.randi() % 5]
				city.house(cx, cz, w - 0.6, depth - 0.6, top, {"roof": roof, "detail": detail, "props": rng.randf() < 0.5, "lit": 0.22, "faces": ["n", "s", "e", "w"] if detail else ["s", "e", "w"]})
			x += w + rng.randf_range(0.0, 1.5)
		z -= depth + rng.randf_range(3.0, 6.0)   # streets between rows


# ===================================================================== ambience
func _ambient() -> void:
	# ferries crossing the water
	for i in 3:
		var f = preload("res://scripts/objects/ferry.gd").new()
		f.start = Vector3(-260.0 + i * 120.0, -1.2, 110.0 + i * 55.0)
		f.dir = Vector3(1, 0, 0.12 * (1 if i % 2 == 0 else -1)).normalized()
		f.speed = 4.0 + i
		add_child(f)
	# seagulls circling high
	for i in 6:
		var b = preload("res://scripts/objects/sky_gull.gd").new()
		b.scale = Vector3.ONE * 1.4
		b.center = Vector3(randf_range(-30, 30), randf_range(26, 40), randf_range(-60, 40))
		b.radius = randf_range(8, 18)
		add_child(b)


func _on_goal() -> void:
	if finished:
		return
	finished = true
	player.control_enabled = false
	player.velocity = Vector3.ZERO
	Sfx.stop_music(0.6)
	Sfx.play("win", 1.0, -1.0)
	GameState.vibrate(80)
	hud.show_banner("Zirvedesin, Tarçın!")
	player.visual.sitting = true
	cam.start_cinematic(Vector3(TOWER.x, BALCONY_Y, TOWER.z), player.global_position + Vector3(0, 0.8, 0), 15.0, 3.5)
	await get_tree().create_timer(3.5).timeout
	var info := GameState.finish_level("galata")
	hud.show_results(info)
