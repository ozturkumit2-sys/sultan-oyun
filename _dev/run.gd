extends Node
## Dev test runner: godot --headless res://_dev/run.tscn -- <test> [args]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var t := args[0] if args.size() > 0 else "perf"
	var scr: Script = load("res://_dev/t_%s.gd" % t)
	if scr == null or not scr.can_instantiate():
		push_error("Cannot load test " + t)
		get_tree().quit(1)
		return
	var node: Node = scr.new()
	add_child(node)
	get_tree().create_timer(600.0).timeout.connect(func(): get_tree().quit(2))
	await node.run(args.slice(1))
	get_tree().quit()
