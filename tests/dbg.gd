extends Node
func _ready():
	var w: SimWorld = Game.create_world()
	w.new_game(501)
	while w.minute < 46.0:
		w.step(0.5)
	var ctx := {"roles": {"usurper": "deniz", "boss": "ahmet"}, "vars": {}}
	print("best_of: ", w.pick_var("best_of", {"of": "usurper", "lim": -20}, ctx))
	for id in w.present_ids():
		print(id, " aff=", w.npc("deniz").affinity(id), " avail=", w.available(id))
	var ok := w.events.run_event("coup_announce", {"usurper": "deniz", "boss": "ahmet"}, {"_arc": "x"})
	print("ran ", ok)
	get_tree().quit()
