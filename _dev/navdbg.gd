extends Node
func _ready() -> void:
	GameState.new_game("Test", 1)
	for d in range(3):
		GameState.advance_minutes(1440)
	var pb := PalaceBuilder.new()
	add_child(pb)
	pb.build_all()
	pb.nav_region.bake_navigation_mesh(false)
	var map := pb.nav_region.get_navigation_map()
	for i in range(90):
		if i % 10 == 0:
			print("f", i, " iter=", NavigationServer3D.map_get_iteration_id(map), " c=", NavigationServer3D.map_get_closest_point(map, Vector3(0, 0, 6)))
		await get_tree().physics_frame
	print("A iter=", NavigationServer3D.map_get_iteration_id(map), " active maps=", NavigationServer3D.get_process_info(NavigationServer3D.INFO_ACTIVE_MAPS), " closest=", NavigationServer3D.map_get_closest_point(map, Vector3(0, 0, 6)), " paused=", get_tree().paused)
	get_tree().quit()
