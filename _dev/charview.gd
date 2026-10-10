extends Node3D
## Geliştirme: karakter figürlerini stüdyo ışığında render eder.
var out := "/tmp/claude-0/shots/"
var cam: Camera3D

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.34, 0.38)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.78)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.6, 0.5, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(-0.3, PI + 0.8, 0)
	fill.light_energy = 0.35
	add_child(fill)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	floor_mi.mesh = pm
	add_child(floor_mi)
	var o_m := [
		{"mesh": "entari_in", "color": Color(0.92, 0.88, 0.78), "pattern": Vector4(0, 0, 1, 0), "pattern_color": Color(0.8, 0.72, 0.55), "scale": 2.0},
		{"mesh": "kaftan", "color": Color(0.45, 0.07, 0.1), "pattern": Vector4(1, 0, 0, 0), "pattern_color": Color(0.78, 0.6, 0.25), "metal": 0.6, "scale": 2.2, "lining": Color(0.85, 0.75, 0.55)},
		{"mesh": "sash", "color": Color(0.85, 0.7, 0.35), "pattern": Vector4(0, 0, 1, 0), "pattern_color": Color(0.5, 0.15, 0.1), "scale": 6.0},
	]
	var o_f := [
		{"mesh": "entari_in", "color": Color(0.18, 0.32, 0.55), "pattern": Vector4(0, 0, 0, 1), "pattern_color": Color(0.85, 0.75, 0.5), "scale": 4.0},
		{"mesh": "kaftan", "color": Color(0.12, 0.2, 0.36), "pattern": Vector4(0, 1, 0, 0), "pattern_color": Color(0.8, 0.65, 0.3), "metal": 0.5, "scale": 2.5},
		{"mesh": "sash", "color": Color(0.8, 0.65, 0.3)},
		{"mesh": "hair_f", "color": Color(0.12, 0.07, 0.04)},
	]
	var o_m1: Array = o_m.duplicate()
	o_m1.append({"mesh": "hw_sultan", "color": Color(0.95, 0.93, 0.88), "cap_color": Color(0.7, 0.1, 0.12)})
	o_m1.append({"mesh": "beard_short", "color": Color(0.12, 0.08, 0.05)})
	var o_f1: Array = o_f.duplicate()
	o_f1.append({"mesh": "hw_hotoz", "color": Color(0.15, 0.25, 0.5), "trim": Color(0.85, 0.7, 0.3), "trim_pattern": Vector4(0, 0, 0, 1)})
	var o_m2: Array = o_m.duplicate()
	o_m2[1] = {"mesh": "kaftan", "color": Color(0.15, 0.15, 0.2), "lining": Color(0.3, 0.3, 0.3)}
	o_m2.append({"mesh": "hw_kadi", "color": Color(0.96, 0.95, 0.92), "cap_color": Color(0.9, 0.9, 0.9)})
	o_m2.append({"mesh": "beard_full", "color": Color(0.85, 0.84, 0.8)})
	var o_m3: Array = o_m.duplicate()
	o_m3[1] = {"mesh": "kaftan", "color": Color(0.1, 0.35, 0.22), "pattern": Vector4(0, 1, 0, 0), "pattern_color": Color(0.75, 0.62, 0.3), "metal": 0.5}
	o_m3.append({"mesh": "hw_vezir", "color": Color(0.95, 0.94, 0.9), "trim": Color(0.85, 0.68, 0.3)})
	o_m3.append({"mesh": "beard_long", "color": Color(0.5, 0.48, 0.45)})
	var o_f2: Array = o_f.duplicate()
	o_f2.append({"mesh": "hw_scarf", "color": Color(0.85, 0.8, 0.7), "pattern": Vector4(0, 0, 0, 1), "pattern_color": Color(0.7, 0.55, 0.3)})
	var looks := [
		{"shapes": {}, "stubble": 0.8, "scalp": 0.6, "outfit": o_m1},
		{"shapes": {"female": 1.0}, "skin": Color(0.86, 0.68, 0.58), "outfit": o_f1, "eye": "hazel"},
		{"shapes": {"old": 1.0, "heavy": 0.6, "nose_hump": 0.8, "face_fat": 0.5}, "skin": Color(0.78, 0.6, 0.48), "outfit": o_m2, "hair": Color(0.6, 0.58, 0.55), "stubble": 0.5},
		{"shapes": {"muscle": 0.8, "tall": 0.6, "chin_prom": 0.6, "face_square": 0.7}, "skin": Color(0.72, 0.52, 0.4), "outfit": o_m3},
		{"shapes": {"female": 1.0, "old": 0.8, "female_old": 0.8, "thin": 0.4}, "skin": Color(0.84, 0.68, 0.6), "outfit": o_f2},
	]
	var figs := []
	var anims := ["idle", "idle", "talk", "idle", "idle"] if OS.get_cmdline_user_args().has("stand") else ["idle", "walk", "talk", "sit", "sit_low"]
	for i in range(looks.size()):
		var f := HumanFigure.new()
		add_child(f)
		f.build(looks[i])
		f.position = Vector3((i - 2) * 1.0, 0, 0)
		figs.append(f)
		f.set_anim(anims[i])
	await get_tree().process_frame
	for i in range(figs.size()):
		figs[i].anim_player.play(anims[i], 0.0)
		figs[i].anim_player.seek(0.6 if anims[i] != "walk" else 0.0, true)
		figs[i].set_process(false)
	if OS.get_cmdline_user_args().has("lodtest"):
		get_viewport().mesh_lod_threshold = 40.0
	cam = Camera3D.new()
	cam.fov = 40
	add_child(cam)
	cam.current = true
	await _shot("c01_full", Vector3(0, 1.0, -5.2), Vector3(0, 0.9, 0))
	await _shot("c02_side", Vector3(5.2, 1.0, 0.0), Vector3(0, 0.9, 0))
	await _shot("c03_heads", Vector3(0, 1.62, -2.1), Vector3(0, 1.55, 0))
	for i in range(looks.size()):
		var hx: float = (i - 2) * 1.0
		var hy: float = figs[i].skeleton.get_bone_global_pose(figs[i].skeleton.find_bone("head")).origin.y + figs[i].skeleton.position.y + 0.1
		await _shot("c1%d_head" % i, Vector3(hx - 0.25, hy + 0.05, -0.75), Vector3(hx, hy, 0))
	await _shot("c06_upper", Vector3(0.0, 1.45, -1.3), Vector3(0, 1.35, 0))
	await _shot("c07_upper_back", Vector3(0.3, 1.5, 1.2), Vector3(0, 1.35, 0))
	await _shot("c08_sit_side", Vector3(-3.5, 0.9, -1.8), Vector3(1.5, 0.5, 0))
	get_tree().quit()


func _shot(name: String, from: Vector3, at: Vector3) -> void:
	cam.look_at_from_position(from, at)
	for i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + name + ".png")
	print("shot ", name)
