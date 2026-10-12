extends Node
## Screenshot harness: runs the sim to a time, renders the office, saves PNGs.
## args: minute=150 zoom=1.0 focus=x,y out=/path.png seed=5 meddle=lights_off,break_printer
var view: OfficeView
var w: SimWorld
var frames := 0
var out := "/tmp/claude-0/shot.png"
var focus = null
var zoomv := 0.0
var minute := 150.0

func _ready():
	var seed_v := 5
	var meddles: Array = []
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		if kv.size() != 2: continue
		match kv[0]:
			"minute": minute = float(kv[1])
			"zoom": zoomv = float(kv[1])
			"focus":
				var p := kv[1].split(",")
				focus = Iso.P(float(p[0]), float(p[1]), 30)
			"out": out = kv[1]
			"seed": seed_v = int(kv[1])
			"meddle": meddles = Array(kv[1].split(","))
	w = Game.create_world()
	w.new_game(seed_v)
	while w.minute < minute and not w.day_over:
		w.step(0.25)

	view = OfficeView.new()
	add_child(view)
	view.build(w)
	for m in meddles:
		var act := {"id": m, "needs": ""}
		if m == "shuffle_files": act["owner"] = "selin"
		Interventions.apply(w, act, 29 if m == "set_temp" else null)
	if zoomv > 0.0: view.cam.zoom = Vector2(zoomv, zoomv)
	if focus != null: view.cam.position = focus

func _process(delta):
	frames += 1
	if w and not w.day_over:
		w.step(0.01)
	if frames == 69:
		print("lights_on=", w.office.objects["lights"]["on"], " mod=", view.modulate_node.color, " zoom=", view.cam.zoom, " pos=", view.cam.position, " temp=", w.office.objects["ac"]["temp"], " dt=", delta)
	if frames == 70:
		get_viewport().get_texture().get_image().save_png(out)
		get_tree().quit()
