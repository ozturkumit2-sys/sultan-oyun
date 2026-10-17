class_name WorldEnv
extends RefCounted
## Sunset environment, sun, sea and the far İstanbul skyline (shared by menu and level).

const SUN_ROT := Vector3(-17.0, -78.0, 0.0)


static func make_environment(parent: Node3D, quality := 1) -> DirectionalLight3D:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/sky_sunset.gdshader")
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a68fc4")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color("f0b49a")
	env.fog_density = 0.0028
	env.fog_sky_affect = 0.0
	env.fog_aerial_perspective = 0.0
	env.glow_enabled = quality > 0
	env.glow_intensity = 0.45
	env.glow_strength = 0.9
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.05
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	we.environment = env
	parent.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = SUN_ROT
	sun.light_color = Color("ffd9a8")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 55.0 if quality > 0 else 35.0
	sun.directional_shadow_split_1 = 0.25
	sun.directional_shadow_blend_splits = false
	parent.add_child(sun)
	return sun


static func sun_dir() -> Vector3:
	# direction towards the sun
	var b := Basis.from_euler(Vector3(deg_to_rad(SUN_ROT.x), deg_to_rad(SUN_ROT.y), 0.0))
	return b.z.normalized()


static func make_sea(parent: Node3D, y := -1.2) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2400, 2400)
	pm.subdivide_width = 120
	pm.subdivide_depth = 120
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/water.gdshader")
	m.set_shader_parameter("sun_dir", sun_dir())
	mi.material_override = m
	mi.position = Vector3(0, y, 200)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## Far skyline: historic peninsula with mosques, Asian shore, Maiden's Tower, the bridge.
static func make_skyline(city: City) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var fb := "far"
	# land masses
	city.at(Vector3(-300, 0, 300))
	_land(city, Vector3(-560, 0, 120), Vector3(-80, 0, 560), -1.2, 3.0, City.lin("9b8a8f"))
	city.at(Vector3(450, 0, 0))
	_land(city, Vector3(230, 0, -500), Vector3(900, 0, 520), -1.2, 2.0, City.lin("8d8095"))
	# historic peninsula houses (silhouettes)
	city.at(Vector3(-300, 0, 300))
	for i in 420:
		var x := rng.randf_range(-540, -95)
		var z := rng.randf_range(135, 540)
		var hill := 18.0 * exp(-pow((x + 260) / 120.0, 2) - pow((z - 260) / 140.0, 2)) + 10.0 * exp(-pow((x + 110) / 70.0, 2) - pow((z - 360) / 80.0, 2))
		var w := rng.randf_range(6, 14)
		var h := rng.randf_range(5, 13)
		var c := City.lin(["e8d6c4", "d9c0b0", "cdb7b5", "e2cfc0", "bfa8a6"][rng.randi() % 5]).darkened(rng.randf_range(0.0, 0.15))
		city.mb(fb).box(Vector3(x, hill + h * 0.5 - 1.0, z), Vector3(w, h, w * rng.randf_range(0.7, 1.3)), c, rng.randf() * 0.4)
	city.mosque(Vector3(-150, 1.0, 165), 1.5, 2)                 # Yeni Cami
	city.mosque(Vector3(-262, 17.0, 262), 2.1, 4)                # Süleymaniye
	city.mosque(Vector3(-70, 9.0, 380), 2.0, 4, "efe2dc")        # Hagia Sophia (pinkish)
	city.mosque(Vector3(-120, 9.0, 430), 2.0, 6)                 # Blue Mosque (six minarets)
	# Asian shore houses
	city.at(Vector3(450, 0, 0))
	for i in 360:
		var x2 := rng.randf_range(240, 800)
		var z2 := rng.randf_range(-480, 500)
		var hill2 := 14.0 * exp(-pow((x2 - 520) / 160.0, 2)) + 6.0
		var w2 := rng.randf_range(7, 16)
		var h2 := rng.randf_range(5, 14)
		var c2 := City.lin(["d9c7c9", "cbb9c4", "e0d2cf", "bfb0bd"][rng.randi() % 4])
		city.mb(fb).box(Vector3(x2, hill2 + h2 * 0.5 - 2.0, z2), Vector3(w2, h2, w2), c2, rng.randf() * 0.5)
	city.mosque(Vector3(300, 8.0, 330), 1.4, 2)
	# Maiden's Tower
	city.at(Vector3(140, 0, 300))
	city.mb(fb).cylinder(Vector3(150, -1.5, 300), 9.0, 2.5, City.lin("8c8580"), 16)
	city.mb(fb).box(Vector3(150, 4.0, 300), Vector3(9, 8, 7), City.lin("f1e6da"))
	city.mb(fb).cylinder(Vector3(152, 1.0, 300), 2.0, 14.0, City.lin("f6ece2"), 12)
	city.mb(fb).cone(Vector3(152, 15.0, 300), 2.4, 4.5, City.lin("8f98a3"), 12)
	# Bosphorus bridge (far north-east)
	city.at(Vector3(320, 0, -380))
	var t1 := Vector3(250, 0, -420)
	var t2 := Vector3(420, 0, -330)
	for tp in [t1, t2]:
		city.mb(fb).box(tp + Vector3(0, 30, 0), Vector3(3, 60, 3), City.lin("c7c3cc"))
		city.mb(fb).box(tp + Vector3(0, 58, 0), Vector3(3, 2, 12), City.lin("c7c3cc"))
	var dir := (t2 - t1)
	var side := dir.cross(Vector3.UP).normalized() * 5.0
	for k in 24:
		var a := t1.lerp(t2, k / 24.0) + Vector3(0, 28, 0)
		var bb := t1.lerp(t2, (k + 1) / 24.0) + Vector3(0, 28, 0)
		city.mb(fb).box((a + bb) * 0.5, Vector3(abs(bb.x - a.x) + 0.5, 1.2, 10.0), City.lin("d8d4dc"), atan2(dir.x, dir.z) + PI * 0.5)
		var sag := func(t: float) -> float: return 58.0 - 26.0 * (1.0 - pow(2.0 * t - 1.0, 2.0))
		for s in [-1.0, 1.0]:
			var p0: Vector3 = t1.lerp(t2, k / 24.0) + Vector3(0, sag.call(k / 24.0), 0) + side * s
			var p1: Vector3 = t1.lerp(t2, (k + 1) / 24.0) + Vector3(0, sag.call((k + 1) / 24.0), 0) + side * s
			city._rope_seg(p0, p1, 0.5, City.lin("eeeaf2"))
	# hazy far hills ring
	city.at(Vector3(0, 0, -400))
	for i in 40:
		var a2 := lerpf(-PI * 0.95, -PI * 0.05, i / 39.0)
		var r := 620.0 + rng.randf_range(-40, 40)
		var c3 := Vector3(cos(a2) * r, -2.0, sin(a2) * r)
		city.mb(fb).dome(c3, rng.randf_range(90, 160), City.lin("a58ea8"), 10, 3, rng.randf_range(0.25, 0.4))


static func _land(city: City, a: Vector3, b: Vector3, y0: float, y1: float, col: Color) -> void:
	var c := (a + b) * 0.5
	var s := (b - a).abs()
	city.mb("far").box(Vector3(c.x, (y0 + y1) * 0.5, c.z), Vector3(s.x, y1 - y0, s.z), col)
