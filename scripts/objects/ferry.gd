extends Node3D
## İstanbul vapuru crossing the water (ambient).

var start := Vector3.ZERO
var dir := Vector3(1, 0, 0)
var speed := 5.0
var dist := 0.0
var span := 520.0
var smoke: CPUParticles3D


func _ready() -> void:
	var mb := MeshBuilder.new()
	var white := City.lin("f4f1ea")
	var black := City.lin("23242b")
	var orange := City.lin("e07a2e")
	# hull
	mb.box(Vector3(0, 0.9, 0), Vector3(4.6, 1.8, 22.0), white, 0.0, true)
	mb.box(Vector3(0, 0.25, 0), Vector3(4.7, 0.5, 22.2), black, 0.0, true)
	mb.box(Vector3(0, 1.85, 0), Vector3(4.8, 0.15, 22.4), black)
	# decks
	mb.box(Vector3(0, 3.0, 0), Vector3(4.2, 2.2, 15.0), white)
	mb.box(Vector3(0, 4.4, 0), Vector3(3.6, 0.6, 9.0), white)
	for side in [-1.0, 1.0]:
		for i in 10:
			var z := -6.8 + i * 1.5
			var c := Vector3(side * 2.11, 3.1, z)
			var n := Vector3(side, 0, 0)
			var u := Vector3(0, 0, -side)
			mb.quad(c - u * 0.5 - Vector3(0, 0.45, 0), c + u * 0.5 - Vector3(0, 0.45, 0), c + u * 0.5 + Vector3(0, 0.45, 0), c - u * 0.5 + Vector3(0, 0.45, 0), City.lin("ffd98a") if i % 3 == 0 else City.lin("3a4a63"))
	# funnel
	mb.cylinder(Vector3(0, 4.7, 1.0), 0.7, 2.6, black, 12)
	mb.cylinder(Vector3(0, 6.0, 1.0), 0.72, 0.5, orange, 12, false)
	var mi := MeshInstance3D.new()
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/toon_solid.gdshader")
	m.set_shader_parameter("use_vertex", 1.0)
	mi.mesh = mb.commit(null, m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	smoke = CPUParticles3D.new()
	smoke.amount = 14
	smoke.lifetime = 4.0
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 12.0
	smoke.initial_velocity_min = 1.5
	smoke.initial_velocity_max = 2.0
	smoke.gravity = Vector3(-0.6, 0.3, 0)
	smoke.scale_amount_min = 1.0
	smoke.scale_amount_max = 2.2
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	sm.radial_segments = 6
	sm.rings = 3
	var smm := StandardMaterial3D.new()
	smm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smm.albedo_color = Color(0.85, 0.8, 0.85, 0.5)
	smm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.material = smm
	smoke.mesh = sm
	smoke.position = Vector3(0, 7.0, 1.0)
	add_child(smoke)
	dist = randf() * span
	_place()


func _place() -> void:
	global_position = start + dir * dist
	rotation.y = atan2(dir.x, dir.z)


func _process(delta: float) -> void:
	dist += speed * delta
	if dist > span:
		dist = 0.0
	_place()
