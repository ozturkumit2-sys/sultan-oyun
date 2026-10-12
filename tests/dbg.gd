extends Node
func _ready():
	var w: SimWorld = Game.create_world()
	w.new_game(3)
	var applied := false
	var acts := {}
	while not w.day_over:
		w.step(0.25)
		if not applied and w.minute >= 15:
			applied = true
			Interventions.apply(w, {"id": "break_coffee", "needs": ""}, null)
			Interventions.apply(w, {"id": "break_printer", "needs": ""}, null)
		for id in w.order:
			var n: NPC = w.npc(id)
			if n.act in ["coffee", "print"] and n.phase == "do" and not acts.has(id + n.act + str(int(n.act_t == 0))):
				pass
	print("fired: ", w.events.fired_total)
	print("coffee state ", w.office.objects["coffee"], " printer ", w.office.objects["printer"])
	for id in w.order:
		var n: NPC = w.npc(id)
		print(id, " coffee_count=", n.coffee_count, " flags=", n.today_flags, " tasks=", n.tasks.map(func(t): return [t["id"], int(t["left"]), t.get("print"), t.get("printed")]))
	get_tree().quit()
