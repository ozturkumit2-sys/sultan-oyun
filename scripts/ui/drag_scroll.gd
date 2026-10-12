class_name DragScroll
extends ScrollContainer
## Finger-drag scrolling list for touch screens.
## Godot's built-in drag scrolling doesn't reach the container when the touch starts on a button.
## This listens before the GUI (_input): after a small threshold along the scroll axis it takes over
## scrolling, cancels the press on the button under the finger, and flings with inertia on release.

const THRESHOLD := 12.0
const FAR := Vector2(-50000, -50000)
const FRICTION := 4.0   # velocity damping per second

static var _owner: DragScroll = null   # only one list scrolls at a time

var horizontal := false
var _down := false
var _dragging := false
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _last_t := 0
var _vel := 0.0
var _pos := 0.0


func _init() -> void:
	# built-in scrolling off (avoids double scroll); the mouse wheel is handled below
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _exit_tree() -> void:
	if _owner == self:
		_owner = null


func _blocked() -> bool:
	for n in get_tree().get_nodes_in_group("ui_blocker"):
		var c := n as CanvasItem
		if c != null and c.is_visible_in_tree() and not c.is_ancestor_of(self):
			return true
	return false


func _axis(v: Vector2) -> float:
	return v.x if horizontal else v.y


func _max_scroll() -> float:
	var bar: ScrollBar = get_h_scroll_bar() if horizontal else get_v_scroll_bar()
	return maxf(0.0, bar.max_value - bar.page)


func _cur() -> float:
	return float(scroll_horizontal if horizontal else scroll_vertical)


func _apply(v: float) -> void:
	_pos = clampf(v, 0.0, _max_scroll())
	if horizontal:
		scroll_horizontal = int(roundf(_pos))
	else:
		scroll_vertical = int(roundf(_pos))


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.position == FAR:
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or \
				mb.button_index == MOUSE_BUTTON_WHEEL_LEFT or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			if mb.pressed and get_global_rect().has_point(mb.position) and not _blocked() and _max_scroll() > 0.0:
				var dir := -1.0 if (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT) else 1.0
				_vel = 0.0
				_apply(_cur() + dir * 80.0 * maxf(1.0, mb.factor))
				get_viewport().set_input_as_handled()
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if get_global_rect().has_point(mb.position) and not _blocked():
				_down = true
				_dragging = false
				_start = mb.position
				_last = mb.position
				_last_t = Time.get_ticks_msec()
				_vel = 0.0
				_pos = _cur()
				set_process(false)
		elif _down:
			_down = false
			if _dragging:
				_dragging = false
				if _owner == self:
					_owner = null
				get_viewport().set_input_as_handled()
				if absf(_vel) > 60.0:
					set_process(true)
	elif event is InputEventMouseMotion and _down:
		var mm := event as InputEventMouseMotion
		if mm.position == FAR:
			return
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_down = false
			return
		if not _dragging:
			var d := mm.position - _start
			var along := absf(_axis(d))
			var across := absf(d.y if horizontal else d.x)
			if along >= THRESHOLD and along > across and (_owner == null or _owner == self) and _max_scroll() > 0.0:
				_dragging = true
				_owner = self
				_last = mm.position
				_last_t = Time.get_ticks_msec()
				_cancel_press()
			elif across >= THRESHOLD * 1.5:
				_down = false   # moving on the other axis: not ours
				return
			else:
				return
		var step := _axis(mm.position - _last)
		var now := Time.get_ticks_msec()
		var dt := maxf(1.0, float(now - _last_t)) / 1000.0
		_vel = lerpf(_vel, -step / dt, 0.4)
		_last = mm.position
		_last_t = now
		_apply(_pos - step)
		get_viewport().set_input_as_handled()


## Cancel the press on whatever is under the finger: move the pointer far away and release there.
func _cancel_press() -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = FAR
	mv.global_position = FAR
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = FAR
	up.global_position = FAR
	var vp := get_viewport()
	vp.push_input.call_deferred(mv, true)
	vp.push_input.call_deferred(up, true)


func _process(delta: float) -> void:
	if _down or absf(_vel) < 20.0:
		_vel = 0.0
		set_process(false)
		return
	var before := _pos
	_apply(_pos + _vel * delta)
	_vel *= exp(-FRICTION * delta)
	if is_equal_approx(before, _pos):
		_vel = 0.0
		set_process(false)
