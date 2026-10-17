extends Node3D
class_name HubKitten
## A rescued kitten living at Kedi Evi: wanders, naps on cushions, greets Tarçın.

var coat := "duman"
var display_name := "Yavru"
var visual: CatVisual
var label: Label3D
var spots: Array = []          # preferred resting spots (Vector3)
var bounds := Rect2(-7.5, -5.0, 15.0, 11.0)
var blockers: Array = []       # Rect2 footprints to avoid
var floor_y := 12.0
var target := Vector3.ZERO
var state := "idle"
var timer := 1.0
var hop := 0.0
var player: Node3D
var speed := 1.5
var meow_player: AudioStreamPlayer3D


func _ready() -> void:
	visual = CatVisual.new()
	visual.coat = coat
	visual.show_scarf = false
	visual.scale = Vector3.ONE * 0.62
	add_child(visual)
	label = Label3D.new()
	label.text = display_name
	label.font = UIKit.font(800)
	label.font_size = 44
	label.outline_size = 14
	label.modulate = UIKit.CREAM
	label.outline_modulate = UIKit.COBALT
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.005
	label.position = Vector3(0, 1.0, 0)
	label.visible = false
	add_child(label)
	meow_player = AudioStreamPlayer3D.new()
	if ResourceLoader.exists("res://assets/audio/meow_kitten.ogg"):
		meow_player.stream = load("res://assets/audio/meow_kitten.ogg")
	meow_player.unit_size = 4.0
	meow_player.max_distance = 30.0
	meow_player.bus = "SFX"
	add_child(meow_player)
	timer = randf_range(0.5, 3.0)
	position.y = floor_y


func _free_point() -> Vector3:
	for i in 20:
		var p := Vector3(randf_range(bounds.position.x, bounds.end.x), floor_y, randf_range(bounds.position.y, bounds.end.y))
		var ok := true
		for b in blockers:
			if (b as Rect2).grow(0.4).has_point(Vector2(p.x, p.z)):
				ok = false
				break
		if ok:
			return p
	return Vector3(0, floor_y, 2)


func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	timer -= delta
	var near := false
	if player:
		var to := player.global_position - global_position
		to.y = 0
		near = to.length() < 2.4
		label.visible = to.length() < 3.5
		if near and state != "greet":
			state = "greet"
			timer = randf_range(1.5, 2.5)
			hop = 1.0
			if randf() < 0.6:
				meow_player.pitch_scale = randf_range(1.15, 1.4)
				meow_player.play()
		if state == "greet":
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 6.0)
			visual.sitting = false
			visual.excited = 1.0
			visual.speed_ratio = 0.0
			if timer <= 0.0 and not near:
				state = "idle"
				timer = 0.5
	match state:
		"idle":
			visual.speed_ratio = 0.0
			if timer <= 0.0:
				if randf() < 0.45 and not spots.is_empty():
					target = spots[randi() % spots.size()] + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
				else:
					target = _free_point()
				target.y = floor_y
				state = "walk"
		"walk":
			var d := target - global_position
			d.y = 0
			if d.length() < 0.15:
				state = "rest"
				timer = randf_range(3.0, 8.0)
				visual.sitting = randf() < 0.75
			else:
				var step: Vector3 = d.normalized() * minf(speed * delta, d.length())
				global_position += step
				rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), delta * 8.0)
				visual.speed_ratio = 0.4
				visual.sitting = false
		"rest":
			visual.speed_ratio = 0.0
			if timer <= 0.0:
				visual.sitting = false
				state = "idle"
				timer = randf_range(0.5, 2.0)
				if randf() < 0.25:
					meow_player.pitch_scale = randf_range(1.15, 1.4)
					meow_player.play()
	# happy hop when greeting
	hop = max(0.0, hop - delta * 2.0)
	visual.position.y = abs(sin(hop * PI * 2.0)) * 0.25 * hop
	visual.excited = max(0.0, visual.excited - delta)
	visual.on_floor = true
