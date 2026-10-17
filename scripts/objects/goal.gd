extends Node3D
class_name Goal
## The golden fish trophy at the top of Galata Tower.

signal reached

const FISH := preload("res://assets/models/fish.glb")
var fish: MeshInstance3D
var beam: MeshInstance3D
var t := 0.0
var done := false
var player: Player
var confetti: CPUParticles3D


func _ready() -> void:
	var gold := ModelUtil.bake(FISH, func(mname: String, m: Color) -> Color:
		match mname:
			"Dark":
				return Color(0.02, 0.02, 0.03)
			"Highlight":
				return Color(1, 1, 1)
		return Color("ffcf4a").srgb_to_linear().lerp(Color("e98a1e").srgb_to_linear(), smoothstep(0.3, 0.6, m.g)).lerp(Color("fff2b0").srgb_to_linear(), smoothstep(0.3, 0.6, m.b)))
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/toon_solid.gdshader")
	m.set_shader_parameter("use_vertex", 1.0)
	m.set_shader_parameter("gloss", 1.0)
	m.set_shader_parameter("rim_strength", 0.8)
	m.set_shader_parameter("emission_amount", 0.4)
	gold.surface_set_material(0, m)
	fish = MeshInstance3D.new()
	fish.mesh = gold
	fish.scale = Vector3.ONE * 3.2
	fish.position.y = 1.6
	add_child(fish)
	# pedestal
	var mb := MeshBuilder.new()
	mb.cylinder(Vector3.ZERO, 0.7, 0.5, City.lin("2d68b8"), 16, true, false, City.lin("f6efe3"))
	mb.cylinder(Vector3(0, 0.5, 0), 0.45, 0.25, City.lin("f6efe3"), 16)
	var pm := ShaderMaterial.new()
	pm.shader = preload("res://shaders/toon_solid.gdshader")
	pm.set_shader_parameter("use_vertex", 1.0)
	var ped := MeshInstance3D.new()
	ped.mesh = mb.commit(null, pm)
	add_child(ped)
	# light beam
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 1.0
	cyl.height = 14.0
	cyl.cap_top = false
	cyl.cap_bottom = false
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_color = Color(1.0, 0.85, 0.4, 0.18)
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cyl.material = bm
	beam = MeshInstance3D.new()
	beam.mesh = cyl
	beam.position.y = 7.5
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	confetti = CPUParticles3D.new()
	confetti.emitting = false
	confetti.one_shot = true
	confetti.amount = 80
	confetti.lifetime = 2.5
	confetti.explosiveness = 0.9
	confetti.direction = Vector3.UP
	confetti.spread = 60.0
	confetti.initial_velocity_min = 6.0
	confetti.initial_velocity_max = 10.0
	confetti.gravity = Vector3(0, -6, 0)
	confetti.angular_velocity_min = -300
	confetti.angular_velocity_max = 300
	var q := QuadMesh.new()
	q.size = Vector2(0.16, 0.1)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.vertex_color_use_as_albedo = true
	qm.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = qm
	confetti.mesh = q
	var grad := Gradient.new()
	grad.set_color(0, Color("e0533a"))
	grad.set_color(1, Color("27a9a0"))
	grad.add_point(0.33, Color("f2b33d"))
	grad.add_point(0.66, Color("1f4e9c"))
	confetti.color_initial_ramp = grad
	confetti.position.y = 2.0
	add_child(confetti)


func _process(delta: float) -> void:
	t += delta
	fish.rotation.y = t * 1.6
	fish.position.y = 1.7 + sin(t * 2.0) * 0.15
	if done:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		return
	if player.global_position.distance_to(global_position + Vector3(0, 0.8, 0)) < 2.0 and not player.dead:
		done = true
		confetti.restart()
		beam.visible = false
		reached.emit()
