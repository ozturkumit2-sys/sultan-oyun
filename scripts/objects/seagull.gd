extends Node3D
class_name Seagull
## Enemy martı: circles, spots the cat, squawks, dives. Stomp it or pounce it.

enum S { PATROL, ALERT, DIVE, RECOVER, DEAD }
var center := Vector3.ZERO
var radius := 3.0
var height := 3.0
var speed := 1.1
var state := S.PATROL
var ang := 0.0
var st_t := 0.0
var vel := Vector3.ZERO
var dive_target := Vector3.ZERO
var visual: BirdVisual
var player: Player
var feathers: CPUParticles3D
var alert_label: Label3D


func _ready() -> void:
	ang = randf() * TAU
	visual = BirdVisual.new()
	visual.kind = "gull"
	visual.scale = Vector3.ONE * 1.5
	add_child(visual)
	global_position = center + Vector3(cos(ang) * radius, height, sin(ang) * radius)
	feathers = CPUParticles3D.new()
	feathers.emitting = false
	feathers.one_shot = true
	feathers.amount = 18
	feathers.lifetime = 1.2
	feathers.explosiveness = 1.0
	feathers.spread = 180.0
	feathers.initial_velocity_min = 2.0
	feathers.initial_velocity_max = 4.0
	feathers.gravity = Vector3(0, -2.5, 0)
	feathers.angular_velocity_min = -200
	feathers.angular_velocity_max = 200
	var q := QuadMesh.new()
	q.size = Vector2(0.18, 0.08)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	feathers.mesh = q
	add_child(feathers)
	alert_label = Label3D.new()
	alert_label.text = "!"
	alert_label.font = UIKit.font(800)
	alert_label.font_size = 96
	alert_label.outline_size = 20
	alert_label.modulate = Color("ffd23f")
	alert_label.outline_modulate = UIKit.CORAL
	alert_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alert_label.pixel_size = 0.007
	alert_label.position = Vector3(0, 1.0, 0)
	alert_label.visible = false
	add_child(alert_label)


func _go(s: S) -> void:
	state = s
	st_t = 0.0


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
		return
	st_t += delta
	var pos := global_position
	var pp := player.global_position + Vector3(0, 0.45, 0)
	match state:
		S.PATROL:
			ang += speed * delta
			var tgt := center + Vector3(cos(ang) * radius, height + sin(ang * 2.0) * 0.3, sin(ang) * radius)
			vel = (tgt - pos) * 4.0
			visual.gliding = fmod(ang, 3.0) > 1.6
			visual.flap_speed = 8.0
			var d := Vector2(pp.x - center.x, pp.z - center.z).length()
			if d < radius + 5.5 and pp.y < pos.y + 0.5 and pp.y > pos.y - 7.0 and not player.dead and st_t > 1.0:
				_go(S.ALERT)
				Sfx.play("gull", randf_range(0.9, 1.1), -2.0)
				alert_label.visible = true
		S.ALERT:
			vel = vel.lerp(Vector3(0, 0.6, 0), delta * 6.0)
			visual.gliding = false
			visual.flap_speed = 16.0
			_face(pp - pos, delta * 8.0)
			if st_t > 0.65:
				alert_label.visible = false
				dive_target = pp + Vector3(player.velocity.x, 0, player.velocity.z) * 0.25
				_go(S.DIVE)
				Sfx.play("gull_dive", 1.0, -4.0)
		S.DIVE:
			var dir := (dive_target - pos)
			if dir.length() < 0.5 or st_t > 1.4:
				_go(S.RECOVER)
			else:
				vel = vel.lerp(dir.normalized() * 11.0, delta * 6.0)
			visual.gliding = true
		S.RECOVER:
			var home := center + Vector3(cos(ang) * radius, height, sin(ang) * radius)
			vel = vel.lerp((home - pos).normalized() * 6.0, delta * 3.0)
			visual.gliding = false
			visual.flap_speed = 12.0
			if pos.distance_to(home) < 0.8 or st_t > 4.0:
				_go(S.PATROL)
		S.DEAD:
			vel.y -= 18.0 * delta
			visual.rotation.z += delta * 12.0
			if st_t > 1.4:
				queue_free()
	global_position += vel * delta
	if state != S.ALERT and state != S.DEAD and vel.length() > 0.3:
		_face(vel, delta * 6.0)
	if state != S.DEAD and not player.dead:
		_check_player(pp)


func _face(dir: Vector3, w: float) -> void:
	dir.y = 0
	if dir.length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), clamp(w, 0.0, 1.0))


func _check_player(pp: Vector3) -> void:
	var d := pp.distance_to(global_position)
	if d > 1.0:
		return
	var from_above := player.velocity.y < -0.5 and pp.y > global_position.y + 0.25
	if from_above or player.is_dashing():
		defeat()
		if not player.is_dashing():
			player.stomp_bounce()
		else:
			Sfx.play("stomp", 1.1, -2.0)
	else:
		player.hurt(global_position)
		_go(S.RECOVER)
		vel = (global_position - pp).normalized() * 6.0 + Vector3(0, 4, 0)


func defeat() -> void:
	_go(S.DEAD)
	feathers.restart()
	vel = Vector3(0, 6, 0)
	alert_label.visible = false
	GameState.add_fish(3)
	GameState.vibrate(30)
