extends Node
## Oyuncu ayarları ve giriş eylemleri (InputMap).

signal changed

const PATH := "user://settings.cfg"
const QUALITY_NAMES := ["Düşük", "Orta", "Yüksek"]

var quality := 1
var music_vol := 0.6
var sfx_vol := 0.85
var cam_sens := 1.0
var show_fps := false
var invert_y := false
var autosave := true
var ui_scale := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	load_settings()
	if OS.has_feature("mobile") and not FileAccess.file_exists(PATH):
		quality = 1


func _add_key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _register_inputs() -> void:
	_add_key("move_forward", [KEY_W, KEY_UP])
	_add_key("move_back", [KEY_S, KEY_DOWN])
	_add_key("move_left", [KEY_A, KEY_LEFT])
	_add_key("move_right", [KEY_D, KEY_RIGHT])
	_add_key("run", [KEY_SHIFT])
	_add_key("interact", [KEY_E, KEY_ENTER])
	_add_key("menu", [KEY_ESCAPE])
	_add_key("map", [KEY_M])
	_add_key("sit", [KEY_F])
	_add_key("people", [KEY_P])
	_add_key("time_pause", [KEY_SPACE])


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	quality = int(cf.get_value("graphics", "quality", quality))
	show_fps = bool(cf.get_value("graphics", "show_fps", show_fps))
	music_vol = float(cf.get_value("audio", "music", music_vol))
	sfx_vol = float(cf.get_value("audio", "sfx", sfx_vol))
	cam_sens = float(cf.get_value("controls", "cam_sens", cam_sens))
	invert_y = bool(cf.get_value("controls", "invert_y", invert_y))
	autosave = bool(cf.get_value("game", "autosave", autosave))
	ui_scale = float(cf.get_value("graphics", "ui_scale", ui_scale))


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("graphics", "quality", quality)
	cf.set_value("graphics", "show_fps", show_fps)
	cf.set_value("graphics", "ui_scale", ui_scale)
	cf.set_value("audio", "music", music_vol)
	cf.set_value("audio", "sfx", sfx_vol)
	cf.set_value("controls", "cam_sens", cam_sens)
	cf.set_value("controls", "invert_y", invert_y)
	cf.set_value("game", "autosave", autosave)
	cf.save(PATH)
	changed.emit()


func set_value(key: String, v) -> void:
	set(key, v)
	save_settings()


## Kalite ayarlarının ekrana uygulanması (oyun sahnesi çağırır)
func apply_to(viewport: Viewport, sun: DirectionalLight3D, env: Environment) -> void:
	# ayrıntı düzeyi, yansımalar ve karakter gölgeleri kaliteye göre
	viewport.mesh_lod_threshold = [5.0, 2.5, 1.0][clampi(quality, 0, 2)]
	var tree := viewport.get_tree() if viewport.is_inside_tree() else null
	if tree:
		for p in tree.get_nodes_in_group("room_probes"):
			p.visible = quality >= 1
		for f in tree.get_nodes_in_group("figures"):
			f.set_shadows(quality >= 1)
	match quality:
		0:
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.scaling_3d_scale = 0.7
			if sun:
				sun.shadow_enabled = false
			if env:
				env.glow_enabled = false
				env.fog_enabled = true
		1:
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.scaling_3d_scale = 0.85
			if sun:
				sun.shadow_enabled = true
				sun.directional_shadow_max_distance = 35.0
			if env:
				env.glow_enabled = true
				env.fog_enabled = true
		2:
			viewport.msaa_3d = Viewport.MSAA_2X
			viewport.scaling_3d_scale = 1.0
			if sun:
				sun.shadow_enabled = true
				sun.directional_shadow_max_distance = 55.0
			if env:
				env.glow_enabled = true
				env.fog_enabled = true
