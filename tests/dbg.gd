extends Node
func _ready():
	var w: SimWorld = Game.create_world()
	w.new_game(77)
	while w.minute < 200.0:
		w.step(0.5)
	# a natural conflict: Mert falsely accuses Burak
	w.npc("burak").remember("falsely_accused", "mert", -0.8, 0.9, "", {}, w.day, w.minute, 3)
	w.npc("mert").remember("argued", "burak", -0.5, 0.7, "", {}, w.day, w.minute, 2)
	w.change_rel("mert", "burak", "friendship", -50.0)
	var d: Dictionary = w.events.defs["peace_offering"]
	print("medium candidates incl peace: ", w.director.candidates_for(d).map(func(c): return [c[2], snappedf(c[0], 0.01)]))
	print("mert aff->burak ", w.npc("mert").affinity("burak"), " avail burak ", w.available("burak"), " mert mood ", w.npc("mert").mood)
	while not (w.available("mert") and w.available("burak")):
		w.step(0.25)
	print("try: ", w.events.try_initiative(d, "mert"))
	get_tree().quit()
