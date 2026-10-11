class_name CharacterAnimationController
extends Node
## Bir CharacterFigure'ı sahnede "yaşatan" yardımcı: rastgele bakınma, ara sıra jest,
## konuşma balonları ve olaylara tepki dizileri. Görsel sunum mantıktan ayrıdır.

var figure: CharacterFigure
var bubble_parent: Control
var bubble_offset := Vector2(0, -330)
var lines: Array = []
var interval := Vector2(7.0, 12.0)
var active := true
var talk_tail := -0.3
var _next := 4.0
var _look_t := 0.0


static func attach(fig: CharacterFigure, parent: Control, taunts: Array) -> CharacterAnimationController:
	var c := CharacterAnimationController.new()
	c.figure = fig
	c.bubble_parent = parent
	c.lines = taunts
	fig.add_child(c)
	return c


func _process(delta: float) -> void:
	if figure == null or not active:
		return
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = randf_range(1.0, 3.0)
		figure.look = Vector2(randf_range(-1, 1), randf_range(-0.5, 0.5))
		figure.redraw()
	_next -= delta
	if _next <= 0.0:
		_next = randf_range(interval.x, interval.y)
		if not lines.is_empty() and randf() < 0.75:
			say(lines[randi() % lines.size()])
		else:
			figure.react(["jump", "smug", "taste"][randi() % 3])


func say(text: String, dur := 2.4) -> void:
	if figure == null or bubble_parent == null or text == "":
		return
	var gp := figure.get_global_transform_with_canvas().origin
	var local := gp - bubble_parent.get_global_transform_with_canvas().origin
	SpeechBubble.show_at(bubble_parent, local + bubble_offset * figure.scale, text, dur, talk_tail, Color.WHITE, 340)
	figure.talk(minf(dur, 1.6))


func play(seq: Array) -> void:
	## seq: [["say", "metin"], ["react", "laugh"], ["wait", 0.5], ["pose", "up"]]
	for step in seq:
		match step[0]:
			"say":
				say(step[1])
				await get_tree().create_timer(1.2).timeout
			"react":
				var d := figure.react(step[1])
				await get_tree().create_timer(d).timeout
			"wait":
				await get_tree().create_timer(float(step[1])).timeout
			"pose":
				figure.set_pose(step[1])
			"expr":
				figure.set_expression(step[1], float(step[2]) if step.size() > 2 else 0.0)
