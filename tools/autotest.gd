extends Node
## Headless gameplay checks: drives the cat with scripted, human-like inputs.
## Usage: godot --headless --path . res://tools/autotest.tscn -- [only=name] [trace]

var game: Node
var player: Player
var t := 0.0
var test := 0
var max_y := -INF
var tests := ["start_jump", "b2_b3", "carpet_cumba", "awning_bounce", "b5_b6", "chimney_kitten", "tram_awning", "alley", "tower"]
var state := {}
var settle := 0.0
var start_pos := Vector3.ZERO
var trace := false
const TOWER := Vector3(0, 8, -85)


func _ready() -> void:
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			tests = [a.substr(5)]
		if a == "trace":
			trace = true
	_begin()


func _release_all() -> void:
	for a in ["move_left", "move_right", "move_forward", "move_back", "jump", "dash"]:
		Input.action_release(a)


func _begin() -> void:
	_release_all()
	t = 0.0
	max_y = -INF
	state = {}
	GameState.set_health(3)
	match tests[test]:
		"start_jump": start_pos = Vector3(0, 6.1, 46.0)
		"alley": start_pos = Vector3(4.0, 14.6, -49.0)
		"carpet_cumba": start_pos = Vector3(1.4, 8.8, 6.0)
		"awning_bounce": start_pos = Vector3(2.0, 9.0, 5.4)
		"tower": start_pos = Vector3(-2.0, 23.6, -71.5)
		"chimney_kitten": start_pos = Vector3(3.5, 15.6, -17.0)
		"tram_awning":
			start_pos = Vector3(11.5, 9.1, -33.3)
			for tr in game.find_children("*", "AnimatableBody3D", true, false):
				if tr is Tram:
					tr.t = 1.0
					tr.dir = -1
					tr.pause = 1000.0
					tr.global_position = tr.b
		"b2_b3": start_pos = Vector3(2.0, 7.9, 25.0)
		"b5_b6": start_pos = Vector3(2.0, 14.1, -8.0)
	settle = 1.2


func _put(p: Vector3) -> void:
	player.dead = false
	player.global_position = p
	player.velocity = Vector3.ZERO
	player.checkpoint_pos = p
	game.cam.snap_to(0.0)


func _steer(d: Vector3) -> void:
	d.y = 0
	if d.length() > 1.0:
		d = d.normalized()
	for a in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(a)
	if d.x > 0.05:
		Input.action_press("move_right", d.x)
	if d.x < -0.05:
		Input.action_press("move_left", -d.x)
	if d.z > 0.05:
		Input.action_press("move_back", d.z)
	if d.z < -0.05:
		Input.action_press("move_forward", -d.z)


## Follow target points hopping between them like a player would.
func _hop_route(route: Array, delta: float, jump_dist := 3.2) -> bool:
	if not state.has("i"):
		state["i"] = 0
		state["jt"] = 1.0
		state["dj"] = false
	var i: int = state["i"]
	if i >= route.size():
		_steer(Vector3.ZERO)
		return true
	var tgt: Vector3 = route[i]
	var p := player.global_position
	var to := tgt - p
	var flat := Vector2(to.x, to.z).length()
	state["jt"] += delta
	if player.is_on_floor():
		if flat < 0.6 and abs(to.y) < 0.7:
			state["i"] = i + 1
			Input.action_release("jump")
			return false
		_steer(to * 2.0)
		# human-like: jump at the edge of the current platform
		var dir := Vector3(to.x, 0, to.z).normalized()
		var space := player.get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(p + dir * 0.75 + Vector3(0, 0.3, 0), p + dir * 0.75 + Vector3(0, -1.0, 0), 1)
		var edge := space.intersect_ray(q).is_empty()
		if (edge or (flat < jump_dist and to.y > 0.6)) and state["jt"] > 0.3:
			Input.action_release("jump")
			Input.action_press("jump")
			state["jt"] = 0.0
			state["dj"] = false
	else:
		_steer(to * (1.2 if flat < 1.5 else 2.0))
		if state["jt"] > 0.3:
			Input.action_release("jump")
		if not state["dj"] and player.velocity.y < 1.5 and p.y < tgt.y + 0.8 and state["jt"] > 0.32:
			Input.action_press("jump")
			state["dj"] = true
			state["jt"] = 0.16
	return false


func _physics_process(delta: float) -> void:
	if player == null:
		return
	game.cam.manual_t = 1e9
	game.cam.yaw = 0.0
	if settle > 0.0:
		settle -= delta
		_put(start_pos)
		return
	t += delta
	max_y = max(max_y, player.global_position.y)
	var name: String = tests[test]
	var p := player.global_position
	if trace and int(t * 60) % 6 == 0:
		print("  ", name, " t=", snapped(t, 0.01), " p=", p.snapped(Vector3.ONE * 0.01), " v=", player.velocity.snapped(Vector3.ONE * 0.1),
			" floor=", player.is_on_floor(), " wall_t=", snapped(player.wall_t, 0.01), " jumps=", player.jumps_used, " i=", state.get("i", -1))
	var done := false
	var ok := false
	match name:
		"start_jump":
			Input.action_press("move_forward")
			if p.z < 40.7 and not state.has("j"):
				state["j"] = true
				Input.action_press("jump")
			if t > 2.0:
				done = true
				ok = p.z < 38.0 and abs(p.y - 6.6) < 0.3
		"alley":
			if not state.has("hold"):
				state["hold"] = 0.0
			state["hold"] -= delta
			if t < 0.05:
				Input.action_press("move_right")
				Input.action_press("jump")
				state["hold"] = 0.25
			if state["hold"] <= 0.0:
				Input.action_release("jump")
			if t > 0.05 and player.wall_t > 0.0 and not player.is_on_floor() and state["hold"] < -0.05 and not state.has("side"):
				Input.action_press("jump")
				state["hold"] = 0.25
				var away_right: bool = player.wall_normal.x > 0
				Input.action_release("move_left")
				Input.action_release("move_right")
				Input.action_press("move_right" if away_right else "move_left")
			if p.y > 20.6:
				if not state.has("side"):
					state["side"] = "move_right" if player.velocity.x > 0 else "move_left"
				Input.action_release("move_left")
				Input.action_release("move_right")
				Input.action_press(state["side"])
			if t > 8.0:
				done = true
				ok = abs(p.y - 21.2) < 0.2 and (p.x < 2.5 or p.x > 5.5)
		"carpet_cumba":
			if _hop_route([Vector3(1.4, 8.6, 5.3), Vector3(4.5, 11.2, 4.5), Vector3(4.5, 13.05, 2.0)], delta, 2.6) or t > 8.0:
				done = true
				ok = p.y > 12.9
		"awning_bounce":
			if t < 0.4:
				Input.action_press("move_right")
			else:
				Input.action_release("move_right")
			if t > 3.0:
				done = true
				ok = max_y > 9.5
		"tower":
			var route := [Vector3(-1.0, 24.4, -76.0)]
			for st in [[95, 25.0, 5.35], [130, 25.9, 5.35], [165, 26.8, 5.35], [205, 27.6, 6.9], [240, 28.4, 7.5]]:
				var a := deg_to_rad(st[0])
				route.append(Vector3(TOWER.x + cos(a) * st[2], st[1] + 0.15, TOWER.z + sin(a) * st[2]))
			route.append(Vector3(TOWER.x + cos(deg_to_rad(250.0)) * 5.3, 30.05, TOWER.z + sin(deg_to_rad(250.0)) * 5.3))
			if _hop_route(route, delta, 3.0) or t > 30.0:
				done = true
				ok = p.y > 29.8
		"chimney_kitten":
			if _hop_route([Vector3(2.7, 16.6, -19.6), Vector3(4.4, 18.5, -19.4)], delta, 2.2) or t > 6.0:
				done = true
				ok = p.y > 18.3
		"tram_awning":
			if _hop_route([Vector3(11.5, 10.0, -37.2), Vector3(11.5, 14.6, -41.0)], delta, 4.5) or t > 8.0:
				done = true
				ok = p.y > 14.3
		"b2_b3":
			if _hop_route([Vector3(2.0, 9.3, 17.5), Vector3(1.4, 8.0, 11.0)], delta, 3.0) or t > 6.0:
				done = true
				ok = abs(p.y - 8.05) < 0.4 and p.z < 12.0
		"b5_b6":
			if _hop_route([Vector3(2.0, 15.6, -16.0), Vector3(2.0, 17.1, -25.5)], delta, 3.0) or t > 6.0:
				done = true
				ok = p.y > 16.8 and p.z < -24.0
	if done:
		print("TEST ", name, ": ", "PASS" if ok else "FAIL", "  pos=", p.snapped(Vector3.ONE * 0.01), " max_y=", snapped(max_y, 0.01), " reached=", state.get("i", -1))
		test += 1
		if test >= tests.size():
			get_tree().quit()
		else:
			_begin()
