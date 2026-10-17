extends Node3D
class_name PigeonFlock
## A few pigeons pecking on a roof; they burst into the air when the cat runs at them.

var count := 6
var spread := 1.6
var birds: Array[BirdVisual] = []
var homes: Array[Vector3] = []
var vels: Array[Vector3] = []
var flying := false
var fly_t := 0.0
var player: Player
var t := 0.0


func _ready() -> void:
	for i in count:
		var b := BirdVisual.new()
		b.kind = "pigeon"
		b.scale = Vector3.ONE * 0.75
		var p := Vector3(randf_range(-spread, spread), 0.17, randf_range(-spread, spread))
		b.position = p
		b.rotation.y = randf() * TAU
		add_child(b)
		b.flap_amp = 0.0
		birds.append(b)
		homes.append(p)
		vels.append(Vector3.ZERO)
		for n in b.find_children("*", "MeshInstance3D", true, false):
			(n as MeshInstance3D).visibility_range_end = 45.0
			(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	t += delta
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		return
	var d := player.global_position.distance_to(global_position)
	if not flying:
		for i in birds.size():
			var b := birds[i]
			# pecking bob
			var ph := t * 3.0 + i * 1.7
			b.model.rotation.x = max(0.0, sin(ph)) * 0.5 if fmod(ph, 6.0) < 3.2 else 0.0
		if d < 3.8:
			_scatter()
	else:
		fly_t += delta
		for i in birds.size():
			var b := birds[i]
			vels[i].y += 1.5 * delta
			b.position += vels[i] * delta
			if vels[i].length() > 0.1:
				b.rotation.y = atan2(vels[i].x, vels[i].z)
			if fly_t > 3.5:
				b.visible = false
		if fly_t > 20.0 and d > 14.0:
			_land()


func _scatter() -> void:
	flying = true
	fly_t = 0.0
	Sfx.play("pigeons", randf_range(0.95, 1.05), -2.0)
	var away := global_position - player.global_position
	away.y = 0
	away = away.normalized()
	for i in birds.size():
		var b := birds[i]
		b.flap_amp = 0.9
		b.flap_speed = 22.0 + randf() * 6.0
		b.model.rotation.x = -0.3
		var dir := (away + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))).normalized()
		vels[i] = dir * randf_range(3.0, 5.0) + Vector3(0, randf_range(4.0, 6.0), 0)


func _land() -> void:
	flying = false
	for i in birds.size():
		var b := birds[i]
		b.position = homes[i]
		b.visible = true
		b.flap_amp = 0.0
		b.model.rotation.x = 0.0
