extends Node
## Loads every script so parse errors surface (screens are loaded lazily at runtime).

func run(_a: Array) -> void:
	var bad := 0
	for dir in ["res://scripts/ui/screens", "res://scripts/ui/comp", "res://scripts/ui", "res://scripts/engine", "res://scripts/autoload"]:
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f in d.get_files():
			if not f.ends_with(".gd"):
				continue
			var s: Script = load(dir + "/" + f)
			if s == null or not s.can_instantiate():
				print("FAILED: ", dir + "/" + f)
				bad += 1
	print("parse check done, failures: ", bad)
