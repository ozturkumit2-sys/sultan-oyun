extends Node
func _ready() -> void:
	GameState.new_game("T", 1)
	var pb := PalaceBuilder.new()
	add_child(pb)
	pb.build_all()
	var rows := []
	for cs in pb.body.get_children():
		var sh: Shape3D = cs.shape
		var top := 0.0
		var bottom := 0.0
		var sz := ""
		if sh is BoxShape3D:
			top = cs.position.y + sh.size.y * 0.5
			bottom = cs.position.y - sh.size.y * 0.5
			sz = "box %.2fx%.2fx%.2f" % [sh.size.x, sh.size.y, sh.size.z]
		elif sh is CylinderShape3D:
			top = cs.position.y + sh.height * 0.5
			bottom = cs.position.y - sh.height * 0.5
			sz = "cyl r%.2f h%.2f" % [sh.radius, sh.height]
		if bottom < 0.15 and top > 0.06 and top < 1.6:
			rows.append("%s top=%.2f bot=%.2f @(%.1f,%.1f) %s" % [PalaceLayout.room_at_v(cs.position), top, bottom, cs.position.x, cs.position.z, sz])
	rows.sort()
	for r in rows:
		print(r)
	print("count=", rows.size())
	get_tree().quit()
