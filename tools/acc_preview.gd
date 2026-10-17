extends Node3D
func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("f6c58a")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b9a2d6")
	e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_color = Color("fff0d8")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var sets := [{"head": "fes", "eyes": "", "scarf": "kirmizi"}, {"head": "kasket", "eyes": "gozluk", "scarf": "lacivert"},
		{"head": "denizci", "eyes": "", "scarf": "nazar"}, {"head": "tac", "eyes": "yuvarlak", "scarf": "mor"}, {"head": "cicek", "eyes": "", "scarf": "sari"}]
	for i in sets.size():
		var c := CatVisual.new()
		c.position = Vector3((i - 2) * 1.05, 0, 0)
		c.rotation_degrees.y = 18 if i < 2 else -18
		add_child(c)
		Accessories.apply(c, sets[i])
		c.blink_timer = 100.0
	var cam := Camera3D.new()
	cam.fov = 32
	add_child(cam)
	cam.position = Vector3(0, 1.25, 4.6)
	cam.look_at(Vector3(0, 0.62, 0))
