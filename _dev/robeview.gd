extends Node3D
var out := "/tmp/claude-0/shots/"
var cam: Camera3D
func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.32, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.4, 0)
	add_child(sun)
	var f := HumanFigure.new()
	add_child(f)
	f.build({"shapes": {}, "outfit": [{"mesh": "entari", "color": Color(0.7, 0.2, 0.2), "lining": Color(0.2, 0.9, 0.2), "trim": Color(0.2, 0.2, 0.9)}]})
	f.body_mi.visible = false
	f.anim_player.stop()
	if OS.get_cmdline_user_args().has("rest"):
		f.skeleton.reset_bone_poses()
	cam = Camera3D.new()
	cam.fov = 40
	add_child(cam)
	cam.current = true
	for s in [["r1_back", Vector3(0.0, 1.9, 1.0)], ["r2_front", Vector3(0.0, 1.8, -1.0)], ["r3_side", Vector3(1.0, 1.7, 0.0)], ["r4_top", Vector3(0.05, 2.4, 0.15)]]:
		cam.look_at_from_position(s[1], Vector3(0, 1.35, 0))
		for i in range(3):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out + s[0] + ".png")
	get_tree().quit()
