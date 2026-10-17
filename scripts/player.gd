extends CharacterBody3D
class_name Player
## Tarçın — the rooftop cat. Tight platformer controller.

signal respawned
signal landed(impact: float)

const RUN_SPEED := 7.2
const ACCEL_GROUND := 60.0
const DECEL_GROUND := 45.0
const ACCEL_AIR := 22.0
const G_UP := 28.0
const G_DOWN := 40.0
const G_CUT := 62.0          # gravity when jump released early
const MAX_FALL := 24.0
const JUMP_V := 11.0
const DJ_V := 9.6
const WALL_SLIDE := 2.2
const WALL_JUMP_V := 10.6
const WALL_PUSH := 6.8
const DASH_SPEED := 14.0
const DASH_TIME := 0.2
const COYOTE := 0.12
const BUFFER := 0.14

var cam_rig: Node3D
var visual: CatVisual
var visual_root: Node3D
var shadow_blob: MeshInstance3D
var dust: CPUParticles3D
var sparkle: CPUParticles3D

var facing := Vector3(0, 0, -1)
var coyote_t := 0.0
var buffer_t := 0.0
var jumps_used := 0
var jump_held := false
var can_dash := true
var dash_t := 0.0
var dash_cd := 0.0
var wall_t := 0.0
var wall_normal := Vector3.ZERO
var wall_jump_lock := 0.0
var invuln := 0.0
var was_on_floor := true
var prev_vy := 0.0
var idle_t := 0.0
var meow_t := 0.0
var step_phase := 0.0
var control_enabled := true
var dead := false
var checkpoint_pos := Vector3.ZERO
var checkpoint_yaw := 0.0
var kill_height: Callable = func(_p: Vector3) -> float: return -50.0
var air_time := 0.0
var bounce_lock := 0.0
var jump_t := 10.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_max_angle = deg_to_rad(48.0)
	floor_snap_length = 0.35
	floor_stop_on_slope = true
	floor_constant_speed = true
	safe_margin = 0.02
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 0.95
	cs.shape = cap
	cs.position.y = 0.475
	add_child(cs)
	visual_root = Node3D.new()
	add_child(visual_root)
	visual = CatVisual.new()
	visual.coat = "tarcin"
	visual_root.add_child(visual)
	visual.scale = Vector3.ONE * 1.05
	_make_shadow()
	_make_particles()
	checkpoint_pos = global_position
	add_to_group("player")


func _make_shadow() -> void:
	shadow_blob = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.95, 0.95)
	q.orientation = PlaneMesh.FACE_Y
	shadow_blob.mesh = q
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/blob_shadow.gdshader")
	shadow_blob.material_override = m
	shadow_blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow_blob.top_level = true
	add_child(shadow_blob)


func _make_particles() -> void:
	dust = CPUParticles3D.new()
	dust.emitting = false
	dust.one_shot = true
	dust.amount = 14
	dust.lifetime = 0.45
	dust.explosiveness = 0.95
	dust.direction = Vector3(0, 0.3, 0)
	dust.spread = 90.0
	dust.flatness = 0.8
	dust.initial_velocity_min = 1.6
	dust.initial_velocity_max = 3.0
	dust.gravity = Vector3(0, 1.5, 0)
	dust.damping_min = 4.0
	dust.damping_max = 6.0
	dust.scale_amount_min = 0.6
	dust.scale_amount_max = 1.1
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0))
	dust.scale_amount_curve = curve
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	sm.radial_segments = 8
	sm.rings = 4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.95, 0.88, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.material = mat
	dust.mesh = sm
	dust.position.y = 0.05
	add_child(dust)
	sparkle = CPUParticles3D.new()
	sparkle.emitting = false
	sparkle.one_shot = true
	sparkle.amount = 12
	sparkle.lifetime = 0.4
	sparkle.explosiveness = 1.0
	sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	sparkle.emission_ring_radius = 0.35
	sparkle.emission_ring_inner_radius = 0.3
	sparkle.emission_ring_height = 0.0
	sparkle.emission_ring_axis = Vector3.UP
	sparkle.direction = Vector3(1, 0, 0)
	sparkle.spread = 180.0
	sparkle.flatness = 1.0
	sparkle.initial_velocity_min = 2.0
	sparkle.initial_velocity_max = 2.5
	sparkle.gravity = Vector3.ZERO
	sparkle.scale_amount_curve = curve
	var sm2 := SphereMesh.new()
	sm2.radius = 0.06
	sm2.height = 0.12
	sm2.radial_segments = 6
	sm2.rings = 3
	var mat2 := StandardMaterial3D.new()
	mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat2.albedo_color = Color(1.0, 0.92, 0.55)
	sm2.material = mat2
	sparkle.mesh = sm2
	sparkle.position.y = 0.3
	add_child(sparkle)


func _get_input() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	v += GameState.touch_move
	if v.length() > 1.0:
		v = v.normalized()
	return v


func _cam_yaw() -> float:
	return cam_rig.yaw if cam_rig else 0.0


func _physics_process(delta: float) -> void:
	if dead:
		return
	var inp := _get_input() if control_enabled else Vector2.ZERO
	var yaw := _cam_yaw()
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var wish := right * inp.x + fwd * (-inp.y)
	var wish_len := wish.length()
	var on_floor := is_on_floor()

	# --- timers
	coyote_t = COYOTE if on_floor else coyote_t - delta
	buffer_t -= delta
	dash_cd -= delta
	wall_jump_lock -= delta
	invuln -= delta
	bounce_lock -= delta
	jump_t += delta
	if control_enabled and Input.is_action_just_pressed("jump"):
		buffer_t = BUFFER
	jump_held = Input.is_action_pressed("jump")

	if on_floor:
		jumps_used = 0
		can_dash = true
		air_time = 0.0
	else:
		air_time += delta

	# --- horizontal movement
	var hv := Vector3(velocity.x, 0, velocity.z)
	var target := wish * RUN_SPEED
	if dash_t > 0.0:
		dash_t -= delta
	else:
		var accel := ACCEL_GROUND if on_floor else ACCEL_AIR
		if on_floor and wish_len < 0.05:
			accel = DECEL_GROUND
		if wall_jump_lock > 0.0:
			accel *= 0.25
		# allow keeping extra speed in air (after dash / bounce) but bleed it slowly
		hv = hv.move_toward(target, accel * delta)
	velocity.x = hv.x
	velocity.z = hv.z

	# --- wall slide detection
	var touching_wall := false
	if not on_floor and is_on_wall() and dash_t <= 0.0:
		var n := get_wall_normal()
		if abs(n.y) < 0.35:
			touching_wall = true
			wall_normal = Vector3(n.x, 0, n.z).normalized()
	if touching_wall and velocity.y < 1.0:
		wall_t = 0.15
	else:
		wall_t -= delta
	var sliding := wall_t > 0.0 and not on_floor and velocity.y < 1.0
	# sticky walls: keep contact while sliding unless the stick pushes away
	if sliding and wish.dot(wall_normal) < 0.5:
		velocity.x -= wall_normal.x * 2.5
		velocity.z -= wall_normal.z * 2.5
		var into := Vector3(velocity.x, 0, velocity.z).dot(-wall_normal)
		if into > 3.0:
			velocity.x += wall_normal.x * (into - 3.0)
			velocity.z += wall_normal.z * (into - 3.0)

	# --- gravity
	var g := G_DOWN
	if velocity.y > 0.0:
		g = G_UP if jump_held or bounce_lock > 0.0 or jump_t < 0.15 else G_CUT
	if dash_t > 0.0:
		g *= 0.35
	velocity.y -= g * delta
	if sliding:
		velocity.y = max(velocity.y, -WALL_SLIDE)
	velocity.y = max(velocity.y, -MAX_FALL)

	# --- jumping
	if buffer_t > 0.0:
		if on_floor or coyote_t > 0.0:
			_do_jump(JUMP_V, false)
		elif sliding or (wall_t > -0.08 and wall_normal != Vector3.ZERO and not on_floor):
			_do_wall_jump(wish)
		elif jumps_used < 2:
			_do_jump(DJ_V, true)

	# --- dash / pounce
	if control_enabled and Input.is_action_just_pressed("dash") and can_dash and dash_cd <= 0.0:
		_do_dash(wish)

	var vy_before := velocity.y
	move_and_slide()
	on_floor = is_on_floor()

	# --- landing
	if on_floor and not was_on_floor:
		var impact: float = clamp(-prev_vy / 18.0, 0.0, 1.0)
		visual.land(0.35 + impact * 0.65)
		if impact > 0.25:
			dust.restart()
		Sfx.play("land", 1.0 + randf() * 0.1, -8.0 + impact * 6.0)
		landed.emit(impact)
	was_on_floor = on_floor
	prev_vy = vy_before

	# --- facing & visuals
	hv = Vector3(velocity.x, 0, velocity.z)
	if sliding and wall_normal != Vector3.ZERO:
		facing = facing.slerp(-wall_normal, clamp(delta * 14.0, 0.0, 1.0)).normalized()
	elif hv.length() > 0.4:
		facing = facing.slerp(hv.normalized(), clamp(delta * 14.0, 0.0, 1.0)).normalized()
	if facing.length() < 0.1:
		facing = Vector3(0, 0, -1)
	visual_root.rotation.y = atan2(facing.x, facing.z)
	visual.speed_ratio = clamp(hv.length() / RUN_SPEED, 0.0, 1.0) if on_floor else 0.0
	visual.on_floor = on_floor
	visual.vel_y = velocity.y
	visual.wall_cling = sliding
	visual.dash = dash_t > 0.0
	# idle sit
	if on_floor and wish_len < 0.05 and hv.length() < 0.3:
		idle_t += delta
	else:
		idle_t = 0.0
	visual.sitting = idle_t > 5.0
	if idle_t > 8.0:
		meow_t -= delta
		if meow_t <= 0.0:
			meow_t = randf_range(6.0, 10.0)
			Sfx.play("meow", randf_range(0.95, 1.1), -4.0)
	# footsteps
	if on_floor and hv.length() > 1.0:
		var ph := visual.gait / PI
		if floor(ph) != floor(step_phase):
			Sfx.play("step", randf_range(0.9, 1.15), -16.0)
		step_phase = ph
	# invulnerability blink
	visual.visible = invuln <= 0.0 or int(invuln * 14.0) % 2 == 0
	_update_shadow()
	# falling out of the world
	if global_position.y < kill_height.call(global_position):
		fall_out()


func _do_jump(v: float, double: bool) -> void:
	velocity.y = v
	jump_t = 0.0
	buffer_t = 0.0
	coyote_t = 0.0
	if double:
		jumps_used = 2
		visual.trigger_flip()
		sparkle.restart()
		Sfx.play("jump2", 1.0, -3.0, 0.04)
	else:
		jumps_used = 1
		visual.jump_stretch()
		dust.restart()
		Sfx.play("jump", 1.0, -4.0, 0.05)
	GameState.vibrate(12)


func _do_wall_jump(wish: Vector3) -> void:
	var n := wall_normal
	velocity.y = WALL_JUMP_V
	var push := n * WALL_PUSH
	velocity.x = push.x + wish.x * 1.5
	velocity.z = push.z + wish.z * 1.5
	facing = n
	jumps_used = 1
	can_dash = true
	wall_t = -1.0
	wall_jump_lock = 0.18
	bounce_lock = 0.28
	buffer_t = 0.0
	visual.jump_stretch()
	Sfx.play("wall", 1.0, -3.0, 0.05)
	GameState.vibrate(15)


func _do_dash(wish: Vector3) -> void:
	var dir := wish.normalized() if wish.length() > 0.2 else facing
	dir.y = 0
	dir = dir.normalized()
	facing = dir
	dash_t = DASH_TIME
	dash_cd = 0.3
	velocity.x = dir.x * DASH_SPEED
	velocity.z = dir.z * DASH_SPEED
	if is_on_floor():
		velocity.y = 4.2
	else:
		velocity.y = max(velocity.y * 0.3, 3.2)
		can_dash = false
	Sfx.play("dash", 1.0, -4.0, 0.05)
	GameState.vibrate(10)


func is_dashing() -> bool:
	return dash_t > 0.0


func bounce(strength: float, sfx := "bounce") -> void:
	velocity.y = strength
	jumps_used = 1
	can_dash = true
	bounce_lock = strength / G_UP
	visual.jump_stretch()
	if sfx != "":
		Sfx.play(sfx, randf_range(0.95, 1.05), -2.0)
	GameState.vibrate(18)


func stomp_bounce() -> void:
	bounce(12.5, "stomp")
	if cam_rig and cam_rig.has_method("shake"):
		cam_rig.shake(0.15)


func hurt(from: Vector3) -> void:
	if invuln > 0.0 or dead:
		return
	GameState.set_health(GameState.health - 1)
	invuln = 1.4
	visual.hit_flash()
	Sfx.play("hurt", 1.0, -2.0)
	GameState.vibrate(60)
	if cam_rig and cam_rig.has_method("shake"):
		cam_rig.shake(0.35)
	var away := global_position - from
	away.y = 0
	away = away.normalized() if away.length() > 0.01 else -facing
	velocity = away * 7.0 + Vector3(0, 7.5, 0)
	dash_t = 0.0
	if GameState.health <= 0:
		_die()


func fall_out() -> void:
	if dead:
		return
	GameState.set_health(GameState.health - 1)
	Sfx.play("respawn", 1.0, -3.0)
	GameState.vibrate(40)
	_die()


func _die() -> void:
	dead = true
	velocity = Vector3.ZERO
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("fade_out_in"):
		await hud.fade_out_in(0.35)
	else:
		await get_tree().create_timer(0.35).timeout
	respawn()


func respawn() -> void:
	global_position = checkpoint_pos
	velocity = Vector3.ZERO
	facing = Vector3(-sin(checkpoint_yaw), 0, -cos(checkpoint_yaw))
	if GameState.health <= 0:
		GameState.set_health(GameState.max_health)
	invuln = 1.2
	dead = false
	was_on_floor = false
	if cam_rig and cam_rig.has_method("snap_to"):
		cam_rig.snap_to(checkpoint_yaw)
	respawned.emit()


func set_checkpoint(pos: Vector3, yaw: float) -> void:
	checkpoint_pos = pos
	checkpoint_yaw = yaw


func _update_shadow() -> void:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.3, 0), global_position + Vector3(0, -30, 0), 1)
	q.exclude = [get_rid()]
	var r := space.intersect_ray(q)
	if r.is_empty():
		shadow_blob.visible = false
		return
	shadow_blob.visible = true
	var h: float = global_position.y - r.position.y
	shadow_blob.global_position = r.position + r.normal * 0.03
	var s: float = clamp(1.0 - h * 0.06, 0.45, 1.0)
	shadow_blob.scale = Vector3(s, 1, s)
	var n: Vector3 = r.normal
	if abs(n.dot(Vector3.UP)) < 0.999:
		var b := Basis()
		b.y = n
		b.x = n.cross(Vector3.FORWARD).normalized()
		b.z = b.x.cross(n).normalized()
		shadow_blob.global_transform.basis = b.scaled(Vector3(s, 1, s))
	else:
		shadow_blob.global_transform.basis = Basis().scaled(Vector3(s, 1, s))
	(shadow_blob.material_override as ShaderMaterial).set_shader_parameter("alpha", clamp(0.55 - h * 0.03, 0.15, 0.55))
