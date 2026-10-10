class_name NPCNode
extends CharacterBody3D
## Saraydaki bir karakterin 3D temsili. Mantıksal konum GameState'te tutulur;
## bu düğüm yalnızca oyuncunun yakınındayken navigasyon yolu boyunca yürür.

const WALK_SPEED := 1.9
static var stuck_teleports := 0   # tanılama: yolda takılıp ışınlanan NPC sayısı

var char_id := ""
var model: HumanFigure
var label: Label3D
var mover := Locomotion.new()
var mgr: Node = null

var spot := {}           # hedef nokta
var state := "idle"      # idle, walk, at_spot, leaving
var talking_to_player := false
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var _wander_t := 0.0
var _social_t := 0.0
var _near := true
var _repaths := 0


func setup(id: String, manager: Node) -> void:
	char_id = id
	mgr = manager
	name = "NPC_" + id


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.4
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	add_child(cs)
	model = HumanFigure.new()
	add_child(model)
	var c: Dictionary = GameState.ch(char_id)
	model.build_from_char(c, char_id)
	model.rotation.y = randf() * TAU
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 36
	label.outline_size = 10
	label.pixel_size = 0.0036
	label.position = Vector3(0, 0.55 + 1.8 * model.scale.y, 0)
	label.modulate = Color(1.0, 0.93, 0.75)
	label.outline_modulate = Color(0.05, 0.04, 0.08, 0.9)
	label.no_depth_test = false
	label.visibility_range_end = 11.0
	label.visibility_range_begin = 1.2
	label.font = load("res://assets/fonts/FiraSans-SemiBold.ttf")
	add_child(label)
	update_label()
	_wander_t = randf_range(5.0, 20.0)


func update_label() -> void:
	var c: Dictionary = GameState.ch(char_id)
	label.text = GameState.short_name(char_id)
	if GameState.is_married_to_player(char_id):
		label.modulate = Color(1.0, 0.75, 0.85)


func show_npc(v: bool) -> void:
	visible = v
	collision_layer = 4 if v else 0
	set_physics_process(v and _near)


func set_near(v: bool) -> void:
	_near = v
	set_physics_process(visible and v)
	model.set_lod_active(visible and v)


func teleport_to_spot(sp: Dictionary) -> void:
	spot = sp
	if sp.is_empty():
		return
	global_position = sp["pos"]
	model.rotation.y = float(sp["yaw"])
	_arrive()


func go_to(sp: Dictionary) -> void:
	spot = sp
	if sp.is_empty():
		return
	if not visible or not _near:
		teleport_to_spot(sp)
		return
	if not mover.compute(get_world_3d().navigation_map, global_position, sp["pos"], 0.35):
		teleport_to_spot(sp)
		return
	state = "walk"
	_stuck_t = 0.0
	_repaths = 0
	_last_pos = global_position
	model.set_anim("walk")


func _arrive() -> void:
	state = "at_spot"
	velocity = Vector3.ZERO
	model.position.y = 0.0
	model.speed = 0.0
	var t: String = spot.get("type", "stand")
	var act: String = GameState.ch(char_id).get("activity", "")
	if t == "sit":
		model.set_anim("sit")
	elif t == "sit_low":
		model.set_anim("sit_low")
	elif t == "work" or act in ["calisma", "talim"]:
		model.set_anim("work")
	else:
		model.set_anim("idle")
	if spot.has("yaw"):
		model.rotation.y = float(spot["yaw"])


func face(pos: Vector3) -> void:
	var d := pos - global_position
	d.y = 0
	if d.length() > 0.05:
		model.rotation.y = atan2(-d.x, -d.z)


func begin_talk(player_pos: Vector3) -> void:
	talking_to_player = true
	if state == "walk":
		state = "idle"
		velocity = Vector3.ZERO
		model.speed = 0.0
	if not String(model.anim).begins_with("sit"):
		face(player_pos)
	model.set_anim("talk" if not String(model.anim).begins_with("sit") else model.anim)


func end_talk() -> void:
	talking_to_player = false
	if not spot.is_empty():
		if global_position.distance_to(spot["pos"]) > 1.0:
			go_to(spot)
		else:
			_arrive()
	else:
		model.set_anim("idle")


func _physics_process(delta: float) -> void:
	if talking_to_player:
		return
	if state == "walk":
		var dir := mover.next_dir(global_position)
		if not mover.active:
			global_position = spot["pos"]
			if state == "walk":
				_arrive()
			if mgr and spot.get("leave", false):
				mgr.on_left(self)
			return
		var spd := WALK_SPEED * (1.25 if spot.get("leave", false) else 1.0)
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
		velocity.y = -0.5 if is_on_floor() else velocity.y - 20.0 * delta
		move_and_slide()
		if is_on_wall() and dir.length() > 0.1:
			var real := get_real_velocity()
			if Vector2(real.x, real.z).length() < spd * 0.4:
				var rise := Locomotion.try_step_up(self, dir)
				if rise > 0.0:
					model.position.y -= rise
		if model.position.y < 0.0:
			model.position.y = minf(0.0, lerpf(model.position.y, 0.0, clampf(delta * 12.0, 0.0, 1.0)) + delta * 0.3)
		var hs := Vector2(velocity.x, velocity.z).length()
		model.speed = hs
		if hs > 0.2:
			model.rotation.y = lerp_angle(model.rotation.y, atan2(-velocity.x, -velocity.z), clampf(delta * 8.0, 0.0, 1.0))
		_stuck_t += delta
		if _stuck_t > 1.5:
			if global_position.distance_to(_last_pos) < 0.3:
				_repaths += 1
				if _repaths <= 1:
					mover.compute(get_world_3d().navigation_map, global_position, spot["pos"], 0.35)
				else:
					stuck_teleports += 1
					teleport_to_spot(spot)
					if mgr and spot.get("leave", false):
						mgr.on_left(self)
			_last_pos = global_position
			_stuck_t = 0.0
	elif state == "at_spot":
		var act: String = GameState.ch(char_id).get("activity", "")
		if act == "gezinti" or act == "nobet":
			_wander_t -= delta
			if _wander_t <= 0.0:
				_wander_t = randf_range(12.0, 30.0) if act == "gezinti" else randf_range(25.0, 50.0)
				if mgr:
					var nsp: Dictionary = mgr.wander_spot(self)
					if not nsp.is_empty():
						go_to(nsp)
		elif act in ["sohbet", "yemek", "kabul", "dinlenme"]:
			_social_t -= delta
			if _social_t <= 0.0:
				_social_t = randf_range(3.0, 7.0)
				var other: Node3D = mgr.nearest_npc(self, 3.2) if mgr else null
				if other:
					if not String(model.anim).begins_with("sit"):
						face(other.global_position)
						model.set_anim("talk" if randf() < 0.5 else "idle")
