extends Node
## Autoload "GameState": run stats, settings, save data, input map.

signal fish_changed(total: int)
signal kittens_changed(found: int)
signal health_changed(hp: int)
signal message(text: String, kind: String)

const SAVE_PATH := "user://save.cfg"
const KITTEN_TOTAL := 5

var fish := 0
var fish_total := 0
var kittens_found: Array[String] = []
var health := 3
var max_health := 3
var run_time := 0.0
var running := false

var settings := {
	"music": 0.7,
	"sfx": 0.9,
	"vibration": true,
	"cam_sens": 1.0,
	"invert_y": false,
	"quality": 1,   # 0 low, 1 high
}
var best := {}  # level -> {fish, kittens, time}

var touch_move := Vector2.ZERO   # written by on-screen joystick
var touch_look := Vector2.ZERO   # accumulated swipe delta, consumed by camera


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	load_data()


func _process(delta: float) -> void:
	if running and not get_tree().paused:
		run_time += delta


func _add_key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)


func _add_joy_btn(action: String, btn: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	InputMap.action_add_event(action, e)


func _add_joy_axis(action: String, axis: int, val: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = val
	InputMap.action_add_event(action, e)


func _setup_input() -> void:
	_add_key("move_left", [KEY_A, KEY_LEFT])
	_add_key("move_right", [KEY_D, KEY_RIGHT])
	_add_key("move_forward", [KEY_W, KEY_UP])
	_add_key("move_back", [KEY_S, KEY_DOWN])
	_add_key("jump", [KEY_SPACE, KEY_K])
	_add_key("dash", [KEY_SHIFT, KEY_J])
	_add_key("cam_left", [KEY_Q])
	_add_key("cam_right", [KEY_E])
	_add_key("pause", [KEY_ESCAPE, KEY_P])
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_axis("cam_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis("cam_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_joy_btn("jump", JOY_BUTTON_A)
	_add_joy_btn("dash", JOY_BUTTON_X)
	_add_joy_btn("pause", JOY_BUTTON_START)


func reset_run(total_fish: int) -> void:
	fish = 0
	fish_total = total_fish
	kittens_found.clear()
	health = max_health
	run_time = 0.0
	running = true
	fish_changed.emit(fish)
	kittens_changed.emit(0)
	health_changed.emit(health)


func add_fish(n := 1) -> void:
	fish += n
	fish_changed.emit(fish)


func find_kitten(id: String, display_name: String) -> void:
	if id in kittens_found:
		return
	kittens_found.append(id)
	kittens_changed.emit(kittens_found.size())
	message.emit("%s kurtarıldı!  %d/%d" % [display_name, kittens_found.size(), KITTEN_TOTAL], "kitten")


func set_health(h: int) -> void:
	health = clamp(h, 0, max_health)
	health_changed.emit(health)


func vibrate(ms: int) -> void:
	if settings["vibration"] and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func finish_level(level: String) -> Dictionary:
	running = false
	var prev: Dictionary = best.get(level, {})
	var rec := {
		"fish": max(fish, prev.get("fish", 0)),
		"kittens": max(kittens_found.size(), prev.get("kittens", 0)),
		"time": run_time if prev.get("time", 0.0) == 0.0 else min(run_time, prev.get("time", 0.0)),
	}
	var new_record: bool = prev.is_empty() or run_time < prev.get("time", INF)
	best[level] = rec
	save_data()
	return {"record": new_record, "best": rec}


func save_data() -> void:
	var cf := ConfigFile.new()
	for k in settings.keys():
		cf.set_value("settings", k, settings[k])
	for lv in best.keys():
		cf.set_value("best", lv, best[lv])
	cf.save(SAVE_PATH)


func load_data() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	for k in settings.keys():
		settings[k] = cf.get_value("settings", k, settings[k])
	if cf.has_section("best"):
		for lv in cf.get_section_keys("best"):
			best[lv] = cf.get_value("best", lv)
	apply_audio()


func apply_audio() -> void:
	var m := AudioServer.get_bus_index("Music")
	var s := AudioServer.get_bus_index("SFX")
	if m >= 0:
		AudioServer.set_bus_volume_db(m, linear_to_db(max(0.0001, settings["music"])))
	if s >= 0:
		AudioServer.set_bus_volume_db(s, linear_to_db(max(0.0001, settings["sfx"])))


func format_time(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	return "%d:%02d" % [m, s]
