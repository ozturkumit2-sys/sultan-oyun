extends Node3D
## Kedi Evi — Tarçın's rooftop home above Galata. Rescued kittens live here,
## Şapkacı Dede sells accessories, and archways lead to the levels.

const TOP := 12.0               # terrace height
const HW := 9.0                 # terrace half-width (x)
const HD := 7.0                 # terrace half-depth (z)
const KITTEN_COATS := {"duman": "Duman", "komur": "Kömür", "pamuk": "Pamuk", "tekir": "Tekir", "bal": "Bal"}

var city: City
var player: Player
var cam: Node3D
var hud: CanvasLayer
var shop_open := false
var dede: CatVisual
var zones: Array = []           # [centre Vector3, radius, text, Callable, Color]
var blockers: Array = []        # Rect2 footprints for kitten wandering
var cushions: Array = []
var try_on_spot := Vector3(3.4, TOP, 0.6)
var portal_mats: Array = []


func _ready() -> void:
	if "demo" in OS.get_cmdline_user_args():
		GameState.rescued = {"galata": ["duman", "komur", "pamuk", "tekir"]}
		GameState.bank = 120
	var q: int = GameState.settings["quality"]
	get_viewport().scaling_3d_scale = 1.0 if q > 0 else 0.75
	WorldEnv.make_environment(self, q)
	WorldEnv.make_sea(self)
	city = City.new(self, 41)
	city.ground_fn = func(z: float) -> float: return 0.0 if z > 0.0 else minf(8.0, -z * 0.12)
	_build_terrace()
	_build_house()
	_build_shop()
	_build_portals()
	_build_lights()
	_build_surroundings()
	WorldEnv.make_skyline(city)
	city.commit(self)

	player = Player.new()
	add_child(player)
	player.global_position = Vector3(0, TOP + 0.1, 3.8)
	var start_yaw := 0.0
	if GameState.came_from == "galata":
		player.global_position = Vector3(-2.3, TOP + 0.1, -4.4)
		player.facing = Vector3(0, 0, 1)
		start_yaw = PI
	GameState.came_from = ""
	player.kill_height = func(_p: Vector3) -> float: return -100.0
	cam = preload("res://scripts/cam_rig.gd").new()
	add_child(cam)
	player.cam_rig = cam
	cam.setup(player, start_yaw)
	cam.base_distance = 6.0
	hud = preload("res://scripts/hub_hud.gd").new()
	add_child(hud)
	hud.menu_requested.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	hud.shop.closed.connect(_close_shop)
	hud.shop.preview_changed.connect(func(eq): Accessories.apply(player.visual, eq))
	var rescued: Array = GameState.rescued_in("galata")
	hud.kitten_coats = rescued.duplicate()
	_spawn_kittens(rescued)
	Sfx.play_music("res://assets/audio/music_menu.ogg", -9.0)
	Sfx.play_ambience("res://assets/audio/ambience_city.ogg")
	await get_tree().process_frame
	if "shopdemo" in OS.get_cmdline_user_args():
		_open_shop()
		hud.shop._try("fes")
	if rescued.is_empty():
		hud.show_banner("Kedi Evi'ne hoş geldin!")
	else:
		hud.show_banner("%d yavru evde seni bekliyor" % rescued.size())


func _process(delta: float) -> void:
	if shop_open or player == null:
		return
	var best = null
	var bd := INF
	for z in zones:
		var d: float = Vector2(player.global_position.x - z[0].x, player.global_position.z - z[0].z).length()
		if d < z[1] and d < bd:
			bd = d
			best = z
	if best != null:
		hud.set_action(best[2], best[3], best[4])
	else:
		hud.clear_action()


# ------------------------------------------------------------------ terrace
func _build_terrace() -> void:
	city.house(0, 0, HW * 2, HD * 2, TOP, {"hex": "f0c9a8", "detail": true, "roof_hex": "d9b8a0", "faces": ["s", "e", "w", "n"]})
	# parapet (visual) + tall invisible walls so Tarçın can't fall off
	var trim := City.lin("f7eedf")
	city.at(Vector3.ZERO)
	var ph := 0.6
	for s in [[Vector3(0, 0, HD - 0.12), Vector3(HW * 2, ph, 0.24)], [Vector3(0, 0, -HD + 0.12), Vector3(HW * 2, ph, 0.24)],
			[Vector3(HW - 0.12, 0, 0), Vector3(0.24, ph, HD * 2)], [Vector3(-HW + 0.12, 0, 0), Vector3(0.24, ph, HD * 2)]]:
		city.mb("plain").box(Vector3(0, TOP + ph * 0.5, 0) + s[0], s[1], trim)
		var big: Vector3 = s[1]
		big.y = 8.0
		city.col_box(Vector3(0, TOP + 4.0, 0) + s[0], big)
	# potted geraniums along the south parapet
	for i in 7:
		var x := -7.5 + i * 2.5
		_pot(Vector3(x, TOP, HD - 0.6))
	# clothesline on the east side
	city.clothesline(Vector3(HW - 0.8, TOP + 1.8, 5.5), Vector3(HW - 0.8, TOP + 1.8, 1.5), false, true)
	city.water_tank(Vector3(-7.6, TOP, 5.4))
	blockers.append(Rect2(-8.6, 4.4, 2.0, 2.0))
	city.antenna(Vector3(7.8, TOP, -6.2))
	# food & water bowls
	for i in 3:
		var bp := Vector3(-4.2 + i * 0.7, TOP, 5.6)
		city.mb("plain").cylinder(bp, 0.24, 0.12, City.lin(["2d68b8", "e0533a", "27a9a0"][i]), 12, true, false, City.lin("b8743f"))
	# a little welcome mat
	var rug_cols := ["b5322e", "f3e3c3", "1f4e9c", "f3e3c3", "e2a33a", "f3e3c3", "b5322e"]
	for i in rug_cols.size():
		city.mb("plain").box(Vector3(0, TOP + 0.015, 3.6 + i * 0.14), Vector3(1.5, 0.03, 0.14), City.lin(rug_cols[i]))


func _pot(p: Vector3) -> void:
	city.mb("plain").cylinder(p, 0.32, 0.45, City.lin("c4643f"), 10, true, false, City.lin("5b3d2b"), 0.38)
	for k in 6:
		var a := TAU * k / 6.0
		city.mb("plain").dome(p + Vector3(cos(a) * 0.18, 0.5, sin(a) * 0.18), 0.16, City.lin("3e8e41"), 8, 3)
	for k in 4:
		var a2 := TAU * k / 4.0 + 0.4
		city.mb("lit").dome(p + Vector3(cos(a2) * 0.14, 0.62, sin(a2) * 0.14), 0.08, City.lin("e8434f"), 6, 2)
	city.col_box(p + Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 0.7))
	blockers.append(Rect2(p.x - 0.5, p.z - 0.5, 1.0, 1.0))


# ------------------------------------------------------------------ Tarçın's house
func _build_house() -> void:
	var c := Vector3(-6.6, TOP, -1.2)
	city.at(c)
	var wood := City.lin("b5814f")
	city.mb("wood").box(c + Vector3(0, 0.85, 0), Vector3(2.2, 1.7, 2.4), wood, 0.0, false, wood.darkened(0.08))
	city.mb("roof").gable(c + Vector3(0, 1.7, 0), 2.2, 2.4, 0.9, City.lin("c4643f"), wood, false, 0.25)
	# round door facing +x
	for k in 16:
		var a0 := PI * k / 16.0
		var a1 := PI * (k + 1) / 16.0
		var dc := c + Vector3(1.111, 0.55, 0)
		city.mb("plain").tri(dc, dc + Vector3(0, sin(a0) * 0.5, cos(a0) * 0.5), dc + Vector3(0, sin(a1) * 0.5, cos(a1) * 0.5), City.lin("2a1d18"))
	city.mb("plain").quad(c + Vector3(1.111, 0.0, -0.5), c + Vector3(1.111, 0.0, 0.5), c + Vector3(1.111, 0.55, 0.5), c + Vector3(1.111, 0.55, -0.5), City.lin("2a1d18"))
	city.col_box(c + Vector3(0, 1.0, 0), Vector3(2.3, 2.0, 2.5))
	blockers.append(Rect2(c.x - 1.3, c.z - 1.4, 2.6, 2.8))
	var l := Label3D.new()
	l.text = "Tarçın'ın Evi"
	l.font = UIKit.font(800)
	l.font_size = 56
	l.modulate = UIKit.CREAM
	l.outline_size = 16
	l.outline_modulate = UIKit.CORAL
	l.pixel_size = 0.006
	l.position = c + Vector3(1.15, 1.45, 0)
	l.rotation.y = PI * 0.5
	add_child(l)
	# cushions (minder) where kittens nap
	var cols := ["e0533a", "27a9a0", "f2b33d", "1f4e9c"]
	var spots := [Vector3(-4.6, TOP, 1.6), Vector3(-3.4, TOP, 2.6), Vector3(-5.0, TOP, -3.6), Vector3(-2.6, TOP, 0.4)]
	for i in spots.size():
		var sp: Vector3 = spots[i]
		city.mb("plain").box(sp + Vector3(0, 0.07, 0), Vector3(0.9, 0.14, 0.9), City.lin(cols[i]))
		city.mb("plain").box(sp + Vector3(0, 0.15, 0), Vector3(0.7, 0.04, 0.7), City.lin(cols[i]).lightened(0.25))
		cushions.append(sp + Vector3(0, 0.16, 0))


# ------------------------------------------------------------------ shop
func _build_shop() -> void:
	var c := Vector3(6.8, TOP, -1.2)
	city.at(c)
	var wood := City.lin("8c5a3a")
	# counter (facing -x, towards the middle of the terrace)
	city.mb("wood").box(c + Vector3(-1.0, 0.5, 0), Vector3(0.9, 1.0, 3.4), City.lin("a86d45"), 0.0, false, City.lin("8c5a3a"))
	city.mb("plain").box(c + Vector3(-1.0, 1.03, 0), Vector3(1.05, 0.06, 3.6), City.lin("f3e3c3"))
	# İznik tiles on the counter front
	for k in 6:
		var z := -1.45 + k * 0.58
		var tc := c + Vector3(-1.46, 0.5, z)
		city.mb("plain").quad(tc + Vector3(0, -0.25, 0.25), tc + Vector3(0, -0.25, -0.25), tc + Vector3(0, 0.25, -0.25), tc + Vector3(0, 0.25, 0.25), City.lin("f6efe3"))
		city.mb("plain").quad(tc + Vector3(-0.005, -0.15, 0.15), tc + Vector3(-0.005, -0.15, -0.15), tc + Vector3(-0.005, 0.15, -0.15), tc + Vector3(-0.005, 0.15, 0.15), City.lin("1f4e9c" if k % 2 == 0 else "27a9a0"))
	# back wall + shelves
	city.mb("wood").box(c + Vector3(0.9, 1.4, 0), Vector3(0.2, 2.8, 3.6), wood)
	for sy in [1.3, 2.0]:
		city.mb("wood").box(c + Vector3(0.6, sy, 0), Vector3(0.45, 0.06, 3.2), City.lin("6e4a32"))
	# striped awning over the stall
	city.awning(c + Vector3(0.95, 2.9, 0), Vector3(-1, 0, 0), 3.8, 2.2, 0.55, ["e8473a", "fff4e0"])
	# sign
	var l := Label3D.new()
	l.text = "Şapkacı Dede"
	l.font = UIKit.font(800)
	l.font_size = 60
	l.modulate = UIKit.CREAM
	l.outline_size = 16
	l.outline_modulate = UIKit.COBALT
	l.pixel_size = 0.0065
	l.position = c + Vector3(0.78, 3.25, 0)
	l.rotation.y = -PI * 0.5
	add_child(l)
	city.col_box(c + Vector3(-0.2, 1.0, 0), Vector3(2.5, 2.0, 3.6))
	blockers.append(Rect2(c.x - 1.6, c.z - 1.9, 3.0, 3.8))
	# hats on display
	var shelf_items := ["fes", "kasket", "denizci", "tac", "cicek", "gozluk"]
	for i in shelf_items.size():
		var acc := Accessories.build(shelf_items[i])
		if acc == null:
			continue
		var row := 0 if i < 3 else 1
		var col := i % 3
		add_child(acc)
		acc.global_position = c + Vector3(0.6, [1.33, 2.03][row] - 0.38 + (0.12 if shelf_items[i] == "gozluk" else 0.0), -1.0 + col * 1.0) + Vector3(0, 0, 0)
		acc.rotation.y = -PI * 0.5
		acc.scale = Vector3.ONE * 1.25
	# Şapkacı Dede himself
	dede = CatVisual.new()
	dede.coat = "duman"
	dede.show_scarf = true
	add_child(dede)
	dede.global_position = c + Vector3(0.0, 0.62, 0.0)
	city.mb("wood").box(c + Vector3(0.0, 0.3, 0.0), Vector3(0.7, 0.6, 0.7), City.lin("7b5638"))
	dede.rotation.y = -PI * 0.5
	dede.scale = Vector3.ONE * 1.1
	dede.sitting = true
	Accessories.apply(dede, {"head": "fes", "eyes": "yuvarlak", "scarf": "yesil"})
	zones.append([c + Vector3(-2.3, 0, 0), 1.7, "Dükkâna Gir", _open_shop, UIKit.TURQ])


func _open_shop() -> void:
	shop_open = true
	hud.set_gameplay_ui(false)
	player.control_enabled = false
	player.velocity = Vector3.ZERO
	player.global_position = try_on_spot + Vector3(0, 0.05, 0)
	var cam_pos := try_on_spot + Vector3(-1.15, 1.25, 2.3)
	var face := cam_pos - try_on_spot
	player.facing = Vector3(face.x, 0, face.z).normalized()
	player.visual_root.rotation.y = atan2(player.facing.x, player.facing.z)
	cam.set_fixed(cam_pos, try_on_spot + Vector3(0.75, 0.75, 0.25))
	hud.shop.open()
	Sfx.play("meow", 0.75, -6.0)


func _close_shop() -> void:
	shop_open = false
	hud.shop.visible = false
	hud.set_gameplay_ui(true)
	player.control_enabled = true
	Accessories.apply(player.visual, GameState.equipped)
	cam.release_fixed()
	cam.snap_to(cam.yaw)


# ------------------------------------------------------------------ level doors
func _build_portals() -> void:
	var gal: Array = GameState.rescued_in("galata")
	var best: Dictionary = GameState.best.get("galata", {})
	var info := "Yavru %d/5" % gal.size()
	if not best.is_empty():
		info += " · En iyi %d balık" % best.get("fish", 0)
	_portal(Vector3(-2.3, TOP, -HD + 0.55), "Galata Çatıları", info, false, func(): _go_level())
	_portal(Vector3(2.3, TOP, -HD + 0.55), "Kapalıçarşı", "Yakında açılacak", true, func():
		hud.show_banner("Kapalıçarşı yakında açılıyor!")
		Sfx.play("hurt", 1.3, -10.0))


func _portal(c: Vector3, title: String, info: String, locked: bool, cb: Callable) -> void:
	city.at(c)
	var tile_a := City.lin("1f4e9c") if not locked else City.lin("6f6a74")
	var tile_b := City.lin("27a9a0") if not locked else City.lin("8d8792")
	var stone := City.lin("f3e8d6") if not locked else City.lin("b8b1a8")
	var w := 2.2
	var h := 2.4
	# pillars
	for sx in [-1.0, 1.0]:
		var pc := c + Vector3(sx * (w * 0.5 + 0.2), h * 0.5, 0)
		city.mb("stone").box(pc, Vector3(0.4, h, 0.5), stone)
		for k in 4:
			city.mb("plain").box(pc + Vector3(0, -h * 0.5 + 0.35 + k * 0.55, 0.255), Vector3(0.26, 0.26, 0.01), tile_a if k % 2 == 0 else tile_b)
		city.col_box(pc, Vector3(0.4, h, 0.5))
	# pointed (Ottoman) arch made of blocks
	var segs := 9
	for side in [-1.0, 1.0]:
		for k in segs:
			var t0 := float(k) / segs
			var t1 := float(k + 1) / segs
			var arc := func(t: float) -> Vector3:
				var a := t * PI * 0.5
				var x: float = side * (w * 0.5 + 0.2) * cos(a) * (1.0 - 0.18 * t)
				var y: float = h + sin(a) * 1.0 + t * t * 0.25
				return c + Vector3(x, y, 0)
			var p0: Vector3 = arc.call(t0)
			var p1: Vector3 = arc.call(t1)
			var mid := (p0 + p1) * 0.5
			city.mb("stone").box(mid, Vector3(0.42, 0.36, 0.5), stone if k % 2 == 0 else (tile_a if not locked else stone))
	city.mb("stone").box(c + Vector3(0, h + 1.35, 0), Vector3(0.36, 0.36, 0.5), City.lin("f2b33d") if not locked else stone)
	# glowing doorway
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w + 0.05, h + 0.9)
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/portal.gdshader")
	m.set_shader_parameter("locked", 1.0 if locked else 0.0)
	mi.material_override = m
	mi.position = c + Vector3(0, (h + 0.9) * 0.5, -0.05)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	portal_mats.append(m)
	# back wall behind the doorway (solid)
	city.col_box(c + Vector3(0, 1.6, -0.3), Vector3(w, 3.2, 0.2))
	# labels
	var l := Label3D.new()
	l.text = title
	l.font = UIKit.font(800)
	l.font_size = 64
	l.modulate = UIKit.CREAM
	l.outline_size = 18
	l.outline_modulate = UIKit.COBALT if not locked else Color("5b5560")
	l.pixel_size = 0.0065
	l.position = c + Vector3(0, h + 0.45, 0.1)
	add_child(l)
	var l2 := Label3D.new()
	l2.text = info
	l2.font = UIKit.font(700)
	l2.font_size = 40
	l2.modulate = UIKit.CREAM
	l2.outline_size = 12
	l2.outline_modulate = UIKit.NAVY
	l2.pixel_size = 0.0055
	l2.position = c + Vector3(0, 0.35, 0.3)
	add_child(l2)
	blockers.append(Rect2(c.x - 1.6, c.z - 0.6, 3.2, 1.3))
	var col := UIKit.CORAL if not locked else Color("8d8792")
	zones.append([c + Vector3(0, 0, 1.2), 1.4, ("%s'na Git" % title) if title.ends_with("ları") else ("%s'ya Git" % title), cb, col])


func _go_level() -> void:
	hud.clear_action()
	player.control_enabled = false
	Sfx.play("whoosh", 1.0, -4.0)
	await hud.fade_to(1.0, 0.45)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ------------------------------------------------------------------ fairy lights
func _build_lights() -> void:
	var poles := [Vector3(-HW + 0.6, TOP, HD - 0.6), Vector3(HW - 0.6, TOP, HD - 0.6), Vector3(HW - 0.6, TOP, -HD + 0.6), Vector3(-HW + 0.6, TOP, -HD + 0.6)]
	for p in poles:
		city.at(p)
		city.mb("wood").box(p + Vector3(0, 1.6, 0), Vector3(0.12, 3.2, 0.12), City.lin("6e4a32"))
	var cols := ["ffd27a", "ff9e6b", "fff1c4", "9fe3d8"]
	var lines := [[0, 1], [1, 2], [2, 3], [3, 0], [0, 2]]
	for ln in lines:
		var a: Vector3 = poles[ln[0]] + Vector3(0, 3.1, 0)
		var b: Vector3 = poles[ln[1]] + Vector3(0, 3.1, 0)
		var n := int(a.distance_to(b) / 0.8)
		var prev := a
		for i in n + 1:
			var t := float(i) / n
			var p2 := a.lerp(b, t) + Vector3(0, -sin(t * PI) * 0.7, 0)
			city.at(p2)
			if i > 0:
				city._rope_seg(prev, p2, 0.015, City.lin("2a2a30"))
			city.mb("lit").sphere(p2 + Vector3(0, -0.08, 0), 0.07, City.lin(cols[i % cols.size()]), 6, 4)
			prev = p2


# ------------------------------------------------------------------ the city around
func _build_surroundings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 90:
		var x := rng.randf_range(-80, 80)
		var z := rng.randf_range(-95, 30)
		if abs(x) < 14 and abs(z) < 12:
			continue
		var top := city.ground(z) + rng.randf_range(5, 11)
		city.house(x, z, rng.randf_range(6, 9), rng.randf_range(6, 9), top, {"roof": ["hip", "flat", "gable_x", "gable_z"][i % 4], "detail": abs(x) < 40 and z > -50, "collide": false, "props": true})
	# Galata Tower beyond the doors
	var c := Vector3(-8.0, 8.0, -62.0)
	city.at(c)
	city.mb("stone").cylinder(c, 5.0, 24.0, City.lin("cdbfae"), 24, false)
	city.mb("stone").cylinder(c + Vector3(0, 23.6, 0), 6.4, 0.45, City.lin("e3d7c7"), 24)
	city.mb("stone").cylinder(c + Vector3(0, 24.0, 0), 4.3, 3.6, City.lin("e8ddd0"), 24, false)
	for k in 12:
		var a := TAU * k / 12.0
		var n := Vector3(cos(a), 0, sin(a))
		var p := c + Vector3(0, 25.6, 0) + n * 4.32
		var u := n.cross(Vector3.UP).normalized()
		city.mb("lit").quad(p - u * 0.4 - Vector3(0, 0.9, 0), p + u * 0.4 - Vector3(0, 0.9, 0), p + u * 0.4 + Vector3(0, 0.9, 0), p - u * 0.4 + Vector3(0, 0.9, 0), City.lin("ffcf7a"))
	city.mb("roof").cone(c + Vector3(0, 27.6, 0), 4.6, 9.0, City.lin("6f7e8f"), 24)


# ------------------------------------------------------------------ kittens
func _spawn_kittens(ids: Array) -> void:
	for i in ids.size():
		var id: String = ids[i]
		var k := HubKitten.new()
		k.coat = id
		k.display_name = KITTEN_COATS.get(id, "Yavru")
		k.floor_y = TOP
		k.bounds = Rect2(-HW + 1.2, -HD + 2.2, HW * 2 - 2.4, HD * 2 - 3.4)
		k.blockers = blockers
		k.spots = cushions
		add_child(k)
		k.global_position = cushions[i % cushions.size()] if i < cushions.size() else Vector3(randf_range(-3, 3), TOP, randf_range(-2, 3))
		k.position.y = TOP
