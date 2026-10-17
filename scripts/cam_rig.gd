extends Node3D
## Third-person platformer camera: lazy vertical follow, soft auto-rotate,
## touch/gamepad orbit, spring arm collision, shake, and level-provided hints.

var target: Node3D
var yaw := 0.0
var pitch := deg_to_rad(-22.0)
var distance := 7.0
var base_distance := 7.0
var focus := Vector3.ZERO
var focus_y := 0.0
var manual_t := 0.0
var shake_amt := 0.0
var hint_yaw := INF
var hint_strength := 0.0
var hint_pitch := INF
var hint_dist := -1.0

var cinematic := false
var cine_center := Vector3.ZERO
var cine_radius := 16.0
var cine_height := 4.0
var cine_angle := 0.0
var cine_look := Vector3.ZERO
var cine_cam: Camera3D
var yaw_node: Node3D
var pitch_node: Node3D
var arm: SpringArm3D
var camera: Camera3D


func _ready() -> void:
	top_level = true
	yaw_node = Node3D.new()
	add_child(yaw_node)
	pitch_node = Node3D.new()
	yaw_node.add_child(pitch_node)
	arm = SpringArm3D.new()
	arm.spring_length = distance
	arm.collision_mask = 1
	arm.margin = 0.25
	var sph := SphereShape3D.new()
	sph.radius = 0.25
	arm.shape = sph
	pitch_node.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 62.0
	camera.near = 0.1
	camera.far = 900.0
	arm.add_child(camera)
	camera.current = true


func setup(t: Node3D, start_yaw: float) -> void:
	target = t
	if t is CollisionObject3D:
		arm.add_excluded_object(t.get_rid())
	snap_to(start_yaw)


func snap_to(new_yaw: float) -> void:
	yaw = new_yaw
	if target:
		focus = target.global_position + Vector3(0, 1.1, 0)
		focus_y = focus.y
	_apply(0.0)


func shake(a: float) -> void:
	shake_amt = max(shake_amt, a)


func set_hint(h_yaw: float, strength: float, h_pitch := INF, h_dist := -1.0) -> void:
	hint_yaw = h_yaw
	hint_strength = strength
	hint_pitch = h_pitch
	hint_dist = h_dist


func clear_hint() -> void:
	hint_yaw = INF
	hint_pitch = INF
	hint_dist = -1.0


func start_cinematic(center: Vector3, look: Vector3, radius: float, height: float) -> void:
	cinematic = true
	cine_center = center
	cine_look = look
	cine_radius = radius
	cine_height = height
	var cp := camera.global_position - center
	cine_angle = atan2(cp.z, cp.x)
	cine_cam = Camera3D.new()
	cine_cam.fov = camera.fov
	cine_cam.far = camera.far
	get_parent().add_child(cine_cam)
	cine_cam.global_transform = camera.global_transform
	cine_cam.current = true


## Fixed framing (shop try-on etc.): smoothly moves a separate camera to pos, looking at look.
var fixed := false
var fixed_pos := Vector3.ZERO
var fixed_look := Vector3.ZERO


func set_fixed(pos: Vector3, look: Vector3) -> void:
	if cine_cam == null:
		cine_cam = Camera3D.new()
		cine_cam.fov = 50.0
		cine_cam.far = camera.far
		get_parent().add_child(cine_cam)
	if not fixed:
		cine_cam.global_transform = camera.global_transform
	fixed = true
	fixed_pos = pos
	fixed_look = look
	cine_cam.current = true


func release_fixed() -> void:
	fixed = false
	camera.current = true


func _process(delta: float) -> void:
	if fixed and cine_cam:
		cine_cam.global_position = cine_cam.global_position.lerp(fixed_pos, clamp(delta * 4.0, 0.0, 1.0))
		var want := cine_cam.global_transform.looking_at(fixed_look, Vector3.UP)
		cine_cam.global_transform.basis = cine_cam.global_transform.basis.slerp(want.basis, clamp(delta * 5.0, 0.0, 1.0))
		return
	if cinematic:
		cine_angle += delta * 0.35
		var want := cine_center + Vector3(cos(cine_angle) * cine_radius, cine_height, sin(cine_angle) * cine_radius)
		cine_cam.global_position = cine_cam.global_position.lerp(want, clamp(delta * 2.0, 0.0, 1.0))
		cine_cam.look_at(cine_look)
		return
	if target == null:
		return
	var sens: float = GameState.settings["cam_sens"]
	# --- manual control
	var look := GameState.touch_look
	GameState.touch_look = Vector2.ZERO
	var pad := Input.get_axis("cam_left", "cam_right")
	if look.length() > 0.0 or abs(pad) > 0.1:
		manual_t = 1.6
	else:
		manual_t -= delta
	yaw -= look.x * 0.0065 * sens
	yaw -= pad * 2.4 * delta * sens
	var inv := -1.0 if GameState.settings["invert_y"] else 1.0
	pitch -= look.y * 0.005 * sens * inv
	pitch = clamp(pitch, deg_to_rad(-60.0), deg_to_rad(8.0))

	# --- auto rotate behind movement (lazy)
	var p: Player = target as Player
	if p and manual_t <= 0.0:
		var hv := Vector3(p.velocity.x, 0, p.velocity.z)
		var spd := hv.length()
		if spd > 2.0 and not p.dead:
			var heading := atan2(-hv.x, -hv.z)
			var diff := wrapf(heading - yaw, -PI, PI)
			if abs(diff) < deg_to_rad(110.0):
				yaw = lerp_angle(yaw, heading, delta * 0.9 * clamp(spd / 7.0, 0.0, 1.0) * clamp(abs(diff) / 0.6, 0.0, 1.0))
		# gently return pitch to default
		pitch = lerp_angle(pitch, deg_to_rad(-22.0) if hint_pitch == INF else hint_pitch, delta * 0.8)
	if hint_yaw != INF and manual_t <= 0.0:
		yaw = lerp_angle(yaw, hint_yaw, delta * hint_strength)
	var want_dist := base_distance if hint_dist < 0.0 else hint_dist
	distance = lerp(distance, want_dist, delta * 2.0)
	_apply(delta)


func _apply(delta: float) -> void:
	var tp := target.global_position + Vector3(0, 1.1, 0)
	var pl: Player = target as Player
	if pl and pl.dead and delta > 0.0:
		return
	var grounded := true
	var p: Player = target as Player
	if p:
		grounded = p.is_on_floor() or p.wall_t > 0.0
	if delta == 0.0:
		focus = tp
		focus_y = tp.y
	else:
		focus.x = lerp(focus.x, tp.x, clamp(delta * 10.0, 0.0, 1.0))
		focus.z = lerp(focus.z, tp.z, clamp(delta * 10.0, 0.0, 1.0))
		# lazy vertical: hold height during jumps, catch up on landing / big drops
		if grounded or tp.y < focus_y - 1.2 or tp.y > focus_y + 3.0:
			focus_y = lerp(focus_y, tp.y, clamp(delta * (6.0 if grounded else 3.5), 0.0, 1.0))
		focus.y = focus_y
	global_position = focus
	yaw_node.rotation.y = yaw
	pitch_node.rotation.x = pitch
	arm.spring_length = distance
	# shake
	if shake_amt > 0.0:
		shake_amt = max(0.0, shake_amt - delta * 1.6)
		camera.h_offset = randf_range(-1.0, 1.0) * shake_amt * 0.4
		camera.v_offset = randf_range(-1.0, 1.0) * shake_amt * 0.4
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
