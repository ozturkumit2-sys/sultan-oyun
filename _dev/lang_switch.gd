extends Node

func _ready() -> void:
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	await get_tree().create_timer(0.3).timeout
	SaveManager.data = SaveManager.default_data()
	SaveManager.data["profile"]["created"] = true
	GameManager.goto("settings", {}, false)
	await get_tree().create_timer(1.0).timeout
	for code in ["ar", "ja", "tr", "de", "en"]:
		var s := get_tree().current_scene
		print("scene ", s, " cur=", Loc.lang)
		s._choose_language(code, null)
		await get_tree().create_timer(1.0).timeout
		var st: Dictionary = FusionEngine.cook(["flour", "frog_essence", "chili", "ghost_dust"], "fry")
		print(code, " lang=", Loc.lang, " rtl=", get_tree().root.is_layout_rtl(), " saved=", SaveManager.setting("lang", ""), " | ", IngredientDatabase.ingredients["chicken"]["name"], " | ", st["name"], " | ", SaveManager.player_name())
	get_tree().quit()
