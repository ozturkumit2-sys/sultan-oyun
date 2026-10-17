extends Node
func _ready() -> void:
	var hub = load("res://scenes/hub.tscn").instantiate()
	add_child(hub)
	await get_tree().create_timer(0.5).timeout
	GameState.bank = 100
	GameState.owned = []
	hub._open_shop()
	await get_tree().process_frame
	hub.hud.shop._buy("tac")
	print("after tac (too expensive): bank=", GameState.bank, " owned=", GameState.owned)
	hub.hud.shop._buy("fes")
	print("after fes: bank=", GameState.bank, " owned=", GameState.owned, " eq=", GameState.equipped)
	hub.hud.shop._set_tab("scarf")
	hub.hud.shop._buy("nazar")
	print("after nazar: bank=", GameState.bank, " eq=", GameState.equipped)
	hub.hud.shop.closed.emit()
	await get_tree().process_frame
	print("shop closed, control=", hub.player.control_enabled, " head acc=", hub.player.visual.parts["Head"].get_children().filter(func(c): return String(c.name).begins_with("Acc_")).size())
	GameState.owned = []
	GameState.equipped = {"head": "", "eyes": "", "scarf": "kirmizi"}
	GameState.bank = 0
	GameState.rescued = {}
	GameState.best = {}
	GameState.save_data()
	get_tree().quit()
