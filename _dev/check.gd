extends Node
func _ready():
	var files := []
	_scan("res://scripts", files)
	var bad := 0
	for f in files:
		var s = load(f)
		if s == null:
			bad += 1
			print("FAILED: ", f)
	print("checked ", files.size(), " scripts, failed ", bad)
	get_tree().quit()
func _scan(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sd in d.get_directories():
		_scan(dir + "/" + sd, out)
