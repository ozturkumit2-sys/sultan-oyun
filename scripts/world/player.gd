class_name PlayerController
extends CharacterBody3D
## Hükümdarın kontrolü: sanal joystick / WASD hareketi, üçüncü şahıs kamera (duvara girmez),
## etkileşim taraması, oturma ve haritadan otomatik yürüme.

signal room_changed(room: String)
signal target_changed(target: Dictionary)
signal arrived
signal blocked

const WALK := 3.3
const RUN := 6.4
const GRAVITY := 22.0

var model: HumanFigure
var pivot: Node3D
var spring: SpringArm3D
var camera: Camera3D
var mover := Locomotion.new()

var move_input := Vector2.ZERO
var run_toggle := false
var cam_yaw := 0.0
var cam_pitch := -0.3
var cam_dist := 4.4
var auto_walking := false
var seated := false
var seat := {}
var current_room := ""
var target := {}
var game: Node = null

var _scan_t := 0.0
var _room_t := 0.0
var _step_acc := 0.0
var _steps: AudioStreamPlayer3D
var _mouse_drag := false
var hide_model := false          # konuşma yakın çekiminde gizle
var follow_node: Node3D = null   # karaktere giderken hedef karakter (hareket ederse yol güncellenir)
var follow_dist := 1.6
var _repath_t := 0.0
var _prog_t := 0.0
var _prog_pos := Vector3.ZERO
var _stuck_n := 0
var _side := Vector3.ZERO
var _side_t := 0.0
var _follow_retries := 0
var _follow_gap := INF


func setup(g: Node) -> void:
	game = g


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.75
	cs.shape = cap
	cs.position = Vector3(0, 0.875, 0)
	add_child(cs)
	model = HumanFigure.new()
	model.name = "Model"
	add_child(model)
	var pl: Dictionary = GameState.player()
	var pc: Dictionary = pl.duplicate()
	if not pc.has("look"):
		pc["look"] = CharactersData.PLAYER_DEFAULT["look"]
	pc["gender"] = "m"
	pc["role"] = "sultan"
	pc["age"] = pc.get("age", 27)
	model.build_from_char(pc, "sultan_oyuncu")
	pivot = Node3D.new()
	pivot.name = "CamPivot"
	pivot.position = Vector3(0, 1.6, 0)
	add_child(pivot)
	spring = SpringArm3D.new()
	spring.collision_mask = 1 | 8
	spring.margin = 0.15
	var sh := SphereShape3D.new()
	sh.radius = 0.22
	spring.shape = sh
	spring.spring_length = cam_dist
	spring.add_excluded_object(get_rid())
	pivot.add_child(spring)
	camera = Camera3D.new()
	camera.fov = 64.0
	camera.near = 0.08
	camera.far = 3500.0
	camera.current = true
	spring.add_child(camera)
	_steps = AudioStreamPlayer3D.new()
	_steps.max_distance = 15.0
	_steps.position = Vector3(0, 0.1, 0)
	add_child(_steps)
	_steps.stream = AudioManager.stream("step_stone")


func place(pos: Vector3, yaw: float) -> void:
	global_position = pos
	model.rotation.y = yaw
	cam_yaw = yaw


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom(-0.5)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom(0.5)
		elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_mouse_drag = mb.pressed
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and _mouse_drag:
		var mm := event as InputEventMouseMotion
		rotate_camera(mm.relative * 0.005)
	elif event.is_action_pressed("interact"):
		do_interact()
	elif event.is_action_pressed("sit"):
		if seated:
			stand_up()
		else:
			do_interact()


func rotate_camera(rel: Vector2) -> void:
	var s: float = Settings.cam_sens
	cam_yaw -= rel.x * s
	cam_pitch -= rel.y * s * (-1.0 if Settings.invert_y else 1.0)
	cam_pitch = clampf(cam_pitch, -1.15, 0.35)


func zoom(d: float) -> void:
	cam_dist = clampf(cam_dist + d, 1.6, 9.0)


## Haritadan/listeden otomatik yürüyüş. follow verilirse o karakterin yanına (follow_dist) kadar gider.
func walk_to(pos: Vector3, follow: Node3D = null, stop_dist: float = 1.6) -> bool:
	if seated:
		stand_up()
	follow_node = follow
	follow_dist = stop_dist
	var end_reach := 0.5 if follow == null else 0.4
	if not mover.compute(get_world_3d().navigation_map, global_position, pos, end_reach):
		auto_walking = false
		return false
	auto_walking = true
	collision_mask = 1          # otomatik yürürken diğer insanlara takılma
	_repath_t = 0.6
	_prog_t = 0.0
	_prog_pos = global_position
	_stuck_n = 0
	_follow_retries = 0
	_follow_gap = INF
	return true


func stop_auto() -> void:
	if auto_walking:
		auto_walking = false
		mover.stop()
	follow_node = null
	collision_mask = 1 | 4


func _finish_auto() -> void:
	var f := follow_node
	stop_auto()
	if f and is_instance_valid(f):
		var d := f.global_position - global_position
		if Vector2(d.x, d.z).length() > 0.05:
			model.rotation.y = atan2(-d.x, -d.z)
	arrived.emit()


func _auto_dir(delta: float) -> Vector3:
	# karakteri takip ediyorsak: yeterince yaklaştık mı, hedef yer değiştirdi mi?
	if follow_node:
		if not is_instance_valid(follow_node) or not follow_node.visible:
			_finish_auto()
			return Vector3.ZERO
		var fp := follow_node.global_position
		if Locomotion.flat(global_position, fp) <= follow_dist:
			_finish_auto()
			return Vector3.ZERO
		_repath_t -= delta
		if _repath_t <= 0.0:
			_repath_t = 0.6
			if Locomotion.flat(mover.target, fp) > 0.8:
				mover.compute(get_world_3d().navigation_map, global_position, fp, 0.4)
	var d := mover.next_dir(global_position)
	if not mover.active and follow_node and _follow_retries < 8:
		# hedef karakter biz yürürken yer değiştirdi: yeni konumuna yol hesapla
		# (aradaki mesafe artık kısalmıyorsa karakter erişilemez bir yerdedir; orada dur)
		var gap := Locomotion.flat(global_position, follow_node.global_position)
		if gap > follow_dist + 0.4 and gap < _follow_gap - 0.3:
			_follow_gap = gap
			_follow_retries += 1
			if mover.compute(get_world_3d().navigation_map, global_position, follow_node.global_position, 0.4):
				d = mover.next_dir(global_position)
	if not mover.active:
		_finish_auto()
		return Vector3.ZERO
	if _side_t > 0.0:
		_side_t -= delta
		return (_side + d * 0.3).normalized()
	# ilerleme kontrolü: takılırsa önce yolu yeniden hesapla, sonra yana kay, olmazsa vazgeç
	_prog_t += delta
	if _prog_t >= 0.8:
		if global_position.distance_to(_prog_pos) < 0.25:
			_stuck_n += 1
			if _stuck_n >= 4:
				stop_auto()
				blocked.emit()
				return Vector3.ZERO
			var goal := follow_node.global_position if follow_node else mover.target
			mover.compute(get_world_3d().navigation_map, global_position, goal, mover.final_reach)
			if _stuck_n >= 2:
				# sıkıştığımız yerden yana doğru bir adım
				_side = Vector3(-d.z, 0.0, d.x) * (1.0 if _stuck_n % 2 == 0 else -1.0)
				_side_t = 0.4
		else:
			_stuck_n = 0
		_prog_t = 0.0
		_prog_pos = global_position
	return d


func _physics_process(delta: float) -> void:
	var input := move_input
	var kb := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if kb.length() > input.length():
		input = kb
	if input.length() > 0.15:
		if auto_walking:
			stop_auto()
		if seated:
			stand_up()
	var dir := Vector3.ZERO
	var spd := 0.0
	if seated:
		velocity = Vector3.ZERO
		model.speed = 0.0
	elif auto_walking:
		dir = _auto_dir(delta)
		if auto_walking:
			spd = RUN * 0.85
			var rem := mover.remaining(global_position)
			if rem < 1.5:
				spd = maxf(WALK, spd * rem / 1.5)
	else:
		var fwd := Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
		var right := Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
		dir = right * input.x + fwd * (-input.y)
		var mag := clampf(input.length(), 0.0, 1.0)
		if dir.length() > 0.01:
			dir = dir.normalized()
		var running: bool = Input.is_action_pressed("run") or run_toggle or mag > 0.93
		spd = (RUN if running else WALK) * (mag if mag < 0.93 else 1.0)
	if not seated:
		var hv := Vector3(velocity.x, 0, velocity.z)
		hv = hv.lerp(dir * spd, clampf(delta * 11.0, 0.0, 1.0))
		velocity.x = hv.x
		velocity.z = hv.z
		if is_on_floor():
			velocity.y = -0.5
		else:
			velocity.y -= GRAVITY * delta
		move_and_slide()
		# alçak basamak (eşik, kürsü, köşk zemini) önünde takıldıysa çık
		if dir.length() > 0.1 and spd > 0.5 and is_on_wall():
			var real := get_real_velocity()
			if Vector2(real.x, real.z).length() < spd * 0.4:
				var rise := Locomotion.try_step_up(self, dir)
				if rise > 0.0:
					# basamakta model ve kamera sıçramasın: görsel olarak yumuşat
					model.position.y -= rise
					pivot.position.y -= rise
		var hs := Vector2(velocity.x, velocity.z).length()
		model.speed = hs
		if hs > 0.25:
			var ty := atan2(-velocity.x, -velocity.z)
			model.rotation.y = lerp_angle(model.rotation.y, ty, clampf(delta * 10.0, 0.0, 1.0))
			model.set_anim("walk")
			_step_acc += hs * delta
			if _step_acc > (0.9 if hs > 4.5 else 0.75):
				_step_acc = 0.0
				if _steps.stream:
					_steps.pitch_scale = randf_range(0.85, 1.15)
					_steps.volume_db = linear_to_db(maxf(Settings.sfx_vol * 0.5, 0.001))
					_steps.play()
		elif model.anim == "walk":
			model.set_anim("idle")
		if global_position.y < -6.0:
			global_position = PalaceLayout.anchor("avlu") + Vector3(0, 0.5, 0)
	if model.position.y < 0.0:
		model.position.y = minf(0.0, lerpf(model.position.y, 0.0, clampf(delta * 12.0, 0.0, 1.0)) + delta * 0.3)
	if pivot.position.y < 1.6:
		pivot.position.y = minf(1.6, lerpf(pivot.position.y, 1.6, clampf(delta * 8.0, 0.0, 1.0)) + delta * 0.2)
	# kamera
	pivot.rotation = Vector3(cam_pitch, cam_yaw, 0)
	var dist := cam_dist
	if current_room != "" and not PalaceLayout.is_outdoor(current_room):
		dist = minf(cam_dist, 4.0)
	spring.spring_length = lerpf(spring.spring_length, dist, clampf(delta * 6.0, 0.0, 1.0))
	# kamera duvar yüzünden çok yaklaşırsa model görüşü kapatmasın
	model.visible = (not hide_model) and spring.get_hit_length() > 0.85
	# oda ve etkileşim
	_room_t -= delta
	if _room_t <= 0.0:
		_room_t = 0.2
		var r := PalaceLayout.room_at_v(global_position)
		if r != "" and r != current_room:
			current_room = r
			GameState.player_room = r
			room_changed.emit(r)
		GameState.player_pos = global_position
		GameState.player_yaw = model.rotation.y
	_scan_t -= delta
	if _scan_t <= 0.0:
		_scan_t = 0.15
		_scan()


func _scan() -> void:
	var best := {}
	var best_score := 999.0
	var pos := global_position
	var fwd := Vector3(-sin(model.rotation.y), 0, -cos(model.rotation.y))
	if game == null:
		return
	if not seated:
		for npc in game.npc_nodes():
			if not npc.visible:
				continue
			var d: Vector3 = npc.global_position - pos
			d.y = 0.0
			var dl := d.length()
			if dl > 2.8:
				continue
			var sc := dl - fwd.dot(d.normalized()) * 0.8
			if sc < best_score:
				best_score = sc
				best = {"kind": "npc", "id": npc.char_id, "label": "Konuş: " + GameState.short_name(npc.char_id), "node": npc}
		for it in game.interactables():
			var p: Vector3 = it["pos"]
			var d2 := p - pos
			d2.y = 0.0
			var dl2 := d2.length()
			if dl2 > 2.0:
				continue
			var sc2 := dl2 - fwd.dot(d2.normalized() if dl2 > 0.01 else fwd) * 0.5 + 0.3
			if sc2 < best_score:
				best_score = sc2
				best = {"kind": "obj", "data": it, "label": it["label"]}
		if best.is_empty():
			var sp: Dictionary = game.nearest_seat(pos, 1.5)
			if not sp.is_empty():
				best = {"kind": "seat", "spot": sp, "label": "Otur"}
	else:
		best = {"kind": "stand", "label": "Kalk"}
	var changed := false
	if best.get("kind", "") != target.get("kind", "") or best.get("label", "") != target.get("label", ""):
		changed = true
	target = best
	if changed:
		target_changed.emit(target)


func do_interact() -> void:
	if target.is_empty():
		return
	match String(target["kind"]):
		"npc":
			game.open_dialogue(String(target["id"]))
		"obj":
			game.use_object(target["data"])
		"seat":
			var sp: Dictionary = target["spot"]
			sit_at(sp["pos"], float(sp["yaw"]), String(sp["type"]) == "sit_low")
		"stand":
			stand_up()


func sit_at(pos: Vector3, yaw: float, low: bool = false) -> void:
	auto_walking = false
	seated = true
	seat = {"pos": pos, "yaw": yaw, "back": global_position}
	global_position = Vector3(pos.x, pos.y, pos.z)
	velocity = Vector3.ZERO
	model.position.y = 0.0
	model.rotation.y = yaw
	model.speed = 0.0
	model.set_anim("sit_low" if low else "sit")
	collision_layer = 0
	_scan_t = 0.0


func stand_up() -> void:
	if not seated:
		return
	seated = false
	var back: Vector3 = seat.get("back", global_position)
	var fwd := Vector3(-sin(model.rotation.y), 0, -cos(model.rotation.y))
	global_position = Vector3(global_position.x, 0.05, global_position.z) + fwd * 0.6
	if PalaceLayout.room_at_v(global_position) == "":
		global_position = back
	model.set_anim("idle")
	collision_layer = 2
	_scan_t = 0.0
