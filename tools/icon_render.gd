extends Node3D
func _ready() -> void:
	get_viewport().transparent_bg = true
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c9b6e0")
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 30, 0)
	sun.light_color = Color("fff0dc")
	sun.light_energy = 1.15
	add_child(sun)
	var c := CatVisual.new()
	c.coat = "tarcin"
	add_child(c)
	c.rotation_degrees.y = 12
	var cam := Camera3D.new()
	cam.fov = 26
	add_child(cam)
	cam.position = Vector3(0.25, 0.95, 2.6)
	cam.look_at(Vector3(0.0, 0.72, 0))
	await get_tree().process_frame
	c.blink_timer = 100.0
	c.look_yaw = 0.0
