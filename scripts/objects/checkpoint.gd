extends Node3D
class_name Checkpoint
## A food bowl ("mama kabı"). Touch it to set the respawn point.

var yaw := 0.0
var active := false
var bowl: MeshInstance3D
var food: MeshInstance3D
var flag: Label3D
var player: Player
var ring: CPUParticles3D
var t := 0.0
static var current: Checkpoint


func _ready() -> void:
	var mb := MeshBuilder.new()
	mb.cylinder(Vector3.ZERO, 0.42, 0.22, City.lin("2d68b8"), 18, false, true, Color(-1, 0, 0), 0.5)
	mb.cylinder(Vector3(0, 0.0, 0), 0.36, 0.2, City.lin("f6efe3"), 18, true, false, City.lin("f6efe3"), 0.44)
	bowl = MeshInstance3D.new()
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/toon_solid.gdshader")
	m.set_shader_parameter("use_vertex", 1.0)
	m.set_shader_parameter("gloss", 0.6)
	m.set_shader_parameter("rim_strength", 0.4)
	bowl.mesh = mb.commit(null, m)
	add_child(bowl)
	var fb := MeshBuilder.new()
	fb.dome(Vector3(0, 0.17, 0), 0.34, City.lin("b8743f"), 12, 4, 0.35)
	food = MeshInstance3D.new()
	food.mesh = fb.commit(null, m)
	food.visible = false
	add_child(food)
	flag = Label3D.new()
	flag.font = UIKit.font(800)
	flag.text = "Kontrol noktası"
	flag.font_size = 48
	flag.outline_size = 14
	flag.modulate = UIKit.CREAM
	flag.outline_modulate = UIKit.TURQ
	flag.pixel_size = 0.006
	flag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flag.position = Vector3(0, 1.3, 0)
	flag.visible = false
	add_child(flag)
	ring = CPUParticles3D.new()
	ring.emitting = false
	ring.one_shot = true
	ring.amount = 20
	ring.lifetime = 0.8
	ring.explosiveness = 1.0
	ring.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	ring.emission_ring_radius = 0.5
	ring.emission_ring_inner_radius = 0.45
	ring.emission_ring_height = 0.0
	ring.emission_ring_axis = Vector3.UP
	ring.direction = Vector3.UP
	ring.spread = 15.0
	ring.initial_velocity_min = 2.0
	ring.initial_velocity_max = 3.0
	ring.gravity = Vector3.ZERO
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	sm.radial_segments = 6
	sm.rings = 3
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.albedo_color = Color("7fe0d6")
	sm.material = pm
	ring.mesh = sm
	add_child(ring)


func _process(delta: float) -> void:
	t += delta
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		return
	if not active and player.global_position.distance_to(global_position) < 1.3:
		activate()
	if active:
		food.scale = Vector3.ONE * (1.0 + sin(t * 3.0) * 0.03)


func activate(silent := false) -> void:
	if current and current != self:
		current.active = false
	current = self
	active = true
	food.visible = true
	player.set_checkpoint(global_position + Vector3(0, 0.3, 0), yaw)
	GameState.set_health(GameState.max_health)
	if not silent:
		ring.restart()
		Sfx.play("checkpoint", 1.0, -3.0)
		flag.visible = true
		var tw := create_tween()
		tw.tween_interval(1.6)
		tw.tween_callback(func(): flag.visible = false)
