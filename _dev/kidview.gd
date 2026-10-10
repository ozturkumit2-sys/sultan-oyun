extends Node3D
## Geliştirme: çocuk ve cariye figürlerini yetişkinlerle yan yana render eder.
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
	GameState.new_game("Kayhan", 1)
	var gs := GameState
	HaremEngine.refresh_candidates(gs, true)
	var cands: Array = HaremEngine.data(gs)["candidates"]
	var people := [
		[gs.player(), "sultan"],
		[cands[0]["proto"], "cv1"],
		[_kid("m", 14, 1), "k14"],
		[_kid("m", 8, 0), "k8"],
		[_kid("f", 6, 1), "k6"],
		[cands[1]["proto"], "cv2"],
	]
	var x := -3.0
	for p in people:
		var f := HumanFigure.new()
		add_child(f)
		f.build(CharacterLooks.for_character(p[0], p[1]))
		f.position = Vector3(x, 0, 0)
		f.rotation.y = PI
		x += 1.2
	cam = Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.0, 5.2)
	cam.look_at(Vector3(0, 0.85, 0))
	cam.fov = 45
	cam.current = true
	for i in range(30):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	for f2 in get_children():
		if f2 is HumanFigure:
			var hi: int = f2.skeleton.find_bone("head")
			print("head pose scale ", f2.skeleton.get_bone_pose_scale(hi), " node scale ", f2.scale)
	get_viewport().get_texture().get_image().save_png(out + "kids.png")
	cam.position = Vector3(0.6, 1.0, 2.4)
	cam.look_at(Vector3(0.6, 0.95, 0))
	for i in range(10):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "kids_close.png")
	get_tree().quit()


func _kid(g: String, age: int, skin: int) -> Dictionary:
	return {"gender": g, "age": age, "role": "child", "look": {"robe": "2f5f8f" if g == "m" else "8a3a5a", "outer": "1c3b5c" if g == "m" else "6a2a4a", "accent": "e0c070", "head": "sarik_small" if g == "m" else "", "skin": skin}}
