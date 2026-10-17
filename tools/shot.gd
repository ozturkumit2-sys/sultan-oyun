extends Node
# Usage: godot --path . res://tools/shot.tscn -- scene=res://x.tscn out=/abs.png frames=60
var out := "/tmp/shot.png"
var frames := 60
var count := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var scene_path := ""
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			match kv[0]:
				"scene": scene_path = kv[1]
				"out": out = kv[1]
				"frames": frames = int(kv[1])
	if scene_path != "":
		var s = load(scene_path).instantiate()
		add_child(s)
func _process(_d: float) -> void:
	count += 1
	if count == frames:
		var img := get_viewport().get_texture().get_image()
		img.save_png(out)
		print("SHOT_SAVED ", out)
		get_tree().quit()
