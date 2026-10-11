extends Node
## Geliştirme: tüm betikleri derleyip hataları raporlar.

func _ready() -> void:
	var files: Array = []
	_scan("res://scripts", files)
	_scan("res://_dev", files)
	var bad := 0
	for f in files:
		var s: Script = load(f)
		if s == null or not s.can_instantiate():
			bad += 1
			print("BAD: ", f)
	print("checked ", files.size(), " bad ", bad)
	get_tree().quit()


func _scan(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_scan(dir + "/" + sub, out)
