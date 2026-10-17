extends Node3D
class_name Kitten
## A lost kitten. Meows (3D) so the player can find it; touching it rescues it.

var id := "k"
var display_name := "Yavru"
var coat := "duman"
var visual: CatVisual
var bubble: Label3D
var meow_player: AudioStreamPlayer3D
var meow_t := 2.0
var rescued := false
var t := 0.0
var hearts: CPUParticles3D
var player: Player


func _ready() -> void:
	visual = CatVisual.new()
	visual.coat = coat
	visual.show_scarf = false
	visual.scale = Vector3.ONE * 0.62
	add_child(visual)
	visual.sitting = true
	bubble = Label3D.new()
	bubble.text = "Miyav!"
	bubble.font = UIKit.font(800)
	bubble.font_size = 64
	bubble.outline_size = 18
	bubble.modulate = UIKit.CREAM
	bubble.outline_modulate = UIKit.COBALT
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = false
	bubble.pixel_size = 0.006
	bubble.position = Vector3(0, 1.25, 0)
	bubble.visible = false
	add_child(bubble)
	meow_player = AudioStreamPlayer3D.new()
	if ResourceLoader.exists("res://assets/audio/meow_kitten.ogg"):
		meow_player.stream = load("res://assets/audio/meow_kitten.ogg")
	meow_player.unit_size = 6.0
	meow_player.max_distance = 45.0
	meow_player.bus = "SFX"
	add_child(meow_player)
	hearts = CPUParticles3D.new()
	hearts.emitting = false
	hearts.one_shot = true
	hearts.amount = 16
	hearts.lifetime = 1.0
	hearts.explosiveness = 0.9
	hearts.direction = Vector3.UP
	hearts.spread = 50.0
	hearts.initial_velocity_min = 2.5
	hearts.initial_velocity_max = 4.0
	hearts.gravity = Vector3(0, -2.0, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.18
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("ff6f91")
	sm.material = m
	hearts.mesh = sm
	hearts.position.y = 0.6
	add_child(hearts)
	# lazy LOD: kittens far away are hidden
	for n in visual.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).visibility_range_end = 55.0


func _process(delta: float) -> void:
	if rescued:
		return
	t += delta
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
	meow_t -= delta
	if meow_t <= 0.0:
		meow_t = randf_range(3.0, 5.0)
		meow_player.pitch_scale = randf_range(1.15, 1.35)
		meow_player.play()
		bubble.visible = true
		bubble.scale = Vector3.ONE * 0.4
		var tw := create_tween()
		tw.tween_property(bubble, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(1.0)
		tw.tween_callback(func(): bubble.visible = false)
		visual.excited = 1.0
	visual.excited = max(0.0, visual.excited - delta)
	if player:
		var to: Vector3 = player.global_position - global_position
		to.y = 0
		if to.length() < 8.0 and to.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 3.0)
			visual.sitting = to.length() > 2.5
		if player.global_position.distance_to(global_position + Vector3(0, 0.3, 0)) < 1.15 and not player.dead:
			_rescue()


func _rescue() -> void:
	rescued = true
	bubble.text = "Teşekkürler!"
	bubble.visible = true
	hearts.restart()
	Sfx.play("kitten", 1.0, -1.0)
	GameState.vibrate(40)
	GameState.find_kitten(id, display_name)
	var tw := create_tween()
	tw.tween_property(visual, "position:y", 1.2, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(visual, "rotation:y", TAU * 2.0, 0.7)
	tw.tween_property(visual, "scale", Vector3.ZERO, 0.3)
	tw.parallel().tween_property(bubble, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
