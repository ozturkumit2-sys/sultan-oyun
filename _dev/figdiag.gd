extends Node3D
func _ready() -> void:
	var m = load("res://assets/characters/body.res")
	print("body type=", m, " class=", m.get_class() if m else "null")
	if m:
		print(" surfaces=", m.get_surface_count(), " blend=", m.get_blend_shape_count(), " aabb=", m.get_aabb())
		for i in range(m.get_surface_count()):
			print("  s", i, " name=", m.surface_get_name(i), " fmt=", m.surface_get_format(i), " len=", m.surface_get_array_len(i), " idx=", m.surface_get_array_index_len(i))
	var r = HumanFigure.rig()
	print("rig=", r, " bones=", r.bone_names.size() if r else -1, " rest0=", r.bone_rest[0] if r else null)
	var f := HumanFigure.new()
	add_child(f)
	f.build(CharacterLooks.for_character(CharactersData.CHARACTERS["leyla"], "leyla"))
	await get_tree().process_frame
	await get_tree().process_frame
	print("parts=", f.parts.size(), " skel bones=", f.skeleton.get_bone_count())
	for p in f.parts:
		print("  ", p.name, " vis=", p.is_visible_in_tree(), " aabb=", p.get_aabb(), " skin=", p.skin != null, " mesh=", p.mesh != null)
	var hi := f.skeleton.find_bone("head")
	print("head global=", f.skeleton.get_bone_global_pose(hi).origin, " anim=", f.anim_player.current_animation)
	get_tree().quit()
