extends Node
func _ready() -> void:
	var hub = load("res://scenes/hub.tscn").instantiate()
	add_child(hub)
	await get_tree().create_timer(0.5).timeout
	for pos in [Vector3(-2.3, 12.1, -5.1), Vector3(2.3, 12.1, -5.1), Vector3(4.5, 12.1, -1.2), Vector3(0, 12.1, 2)]:
		hub.player.global_position = pos
		await get_tree().create_timer(0.2).timeout
		print("at ", pos, " action=", hub.hud.action_btn.visible, " '", hub.hud.action_btn.text, "'")
	# walk into the north parapet: must not fall off
	hub.player.global_position = Vector3(1.5, 12.1, 4.5)
	Input.action_press("move_back")
	Input.action_press("jump")
	await get_tree().create_timer(3.0).timeout
	Input.action_release("move_back")
	print("after walking south 3s: ", hub.player.global_position.snapped(Vector3.ONE * 0.01))
	get_tree().quit()
