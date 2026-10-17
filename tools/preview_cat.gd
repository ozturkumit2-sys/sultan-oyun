extends Node3D
func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("f6c58a")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b9a2d6")
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_color = Color("fff0d8")
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)
	var floor := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(8, 0.2, 4)
	floor.mesh = bm; floor.position.y = -0.1
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color("c96a4a"); floor.material_override = fm
	add_child(floor)
	var coats := ["tarcin", "duman", "komur", "boncuk"]
	var view := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("view="): view = int(a.split("=")[1])
	for i in coats.size():
		var c := CatVisual.new()
		c.coat = coats[i]
		c.position = Vector3((i - 1.5) * 1.3, 0, 0)
		if view == 1: c.rotation_degrees.y = 90
		if view == 2: c.rotation_degrees.y = 180
		c.speed_ratio = 0.0
		add_child(c)
		match i:
			1: c.sitting = true
			2: c.speed_ratio = 1.0
			3:
				c.on_floor = false
				c.vel_y = 6.0
	var cam := Camera3D.new()
	cam.fov = 40
	add_child(cam)
	cam.position = Vector3(0.0, 1.6, 4.8)
	cam.look_at(Vector3(0, 0.55, 0))
