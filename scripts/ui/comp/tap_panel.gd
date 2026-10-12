class_name TapPanel
extends PanelContainer
## Panel that reports a tap (press + release in place). Drag-scroll cancels taps automatically.

var tapped: Callable
var _down := false
var _start := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if not tapped.is_valid():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_down = true
			_start = mb.global_position
			modulate = Color(0.93, 0.9, 0.92)
			scale = Vector2(0.985, 0.985)
			pivot_offset = size * 0.5
		else:
			modulate = Color.WHITE
			scale = Vector2.ONE
			if _down and get_global_rect().has_point(mb.global_position) and mb.global_position.distance_to(_start) < 24.0:
				_down = false
				Snd.click()
				tapped.call()
			_down = false
	elif event is InputEventMouseMotion and _down:
		if (event as InputEventMouseMotion).global_position.distance_to(_start) > 24.0:
			_down = false
			modulate = Color.WHITE
			scale = Vector2.ONE
