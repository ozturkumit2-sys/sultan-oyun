extends Node3D
func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.2, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0, 0, 0)
	e.ambient_light_energy = 0.0
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-90, 0, 0)
	sun.light_energy = 1.0
	add_child(sun)
	var cols := [Color(0.5, 0.5, 0.5), Color(0.5, 0.5, 0.5)]
	for i in 2:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.8, 1.8)
		q.orientation = PlaneMesh.FACE_Y
		mi.mesh = q
		mi.position = Vector3((i - 0.5) * 2.0, 0, 0)
		if i == 0:
			var m := StandardMaterial3D.new()
			m.albedo_color = cols[i]
			m.roughness = 1.0
			m.metallic_specular = 0.0
			mi.material_override = m
		else:
			var sm := ShaderMaterial.new()
			var sh := Shader.new()
			sh.code = "shader_type spatial;\nvoid fragment(){ ALBEDO = vec3(0.5); ROUGHNESS=1.0; SPECULAR=0.0; }\nvoid light(){ DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT),0.0,1.0) * ATTENUATION * LIGHT_COLOR / PI; }"
			sm.shader = sh
			mi.material_override = sm
		add_child(mi)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 4.0
	cam.position = Vector3(0, 5, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	add_child(cam)
	await get_tree().create_timer(0.5).timeout
	var img := get_viewport().get_texture().get_image()
	print("STD ", img.get_pixel(img.get_width() / 4, img.get_height() / 2), "  CUSTOM ", img.get_pixel(img.get_width() * 3 / 4, img.get_height() / 2))
	get_tree().quit()
