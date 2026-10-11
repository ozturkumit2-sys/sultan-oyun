class_name TapCard
extends PanelContainer
## Kaydırılabilir listelerde güvenle kullanılabilen dokunma kartı:
## parmak kaydırırsa dokunma sayılmaz, olay kaydırma kabına da iletilir.

signal tapped

var _down := false
var _down_pos := Vector2.ZERO
var _down_t := 0
var base_color := UIKit.CREAM
var border_color := UIKit.INK
var selected := false:
	set(v):
		selected = v
		_restyle()
var disabled := false:
	set(v):
		disabled = v
		_restyle()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_restyle()
	resized.connect(func(): pivot_offset = size * 0.5)


func set_colors(bg: Color, border := UIKit.INK) -> void:
	base_color = bg
	border_color = border
	_restyle()


func _restyle() -> void:
	var bg := base_color
	if disabled:
		bg = bg.lerp(Color("#d8cbbb"), 0.6)
	var s := UIKit.sb(bg, 22, UIKit.ORANGE if selected else border_color, 6 if selected else 3, 0, 8)
	s.border_width_bottom = 8 if selected else 6
	s.content_margin_top = 6
	s.content_margin_bottom = 8
	add_theme_stylebox_override("panel", s)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
			_down_pos = event.global_position
			_down_t = Time.get_ticks_msec()
			scale = Vector2(0.95, 0.95)
		else:
			scale = Vector2.ONE
			if _down and event.global_position.distance_to(_down_pos) < 22.0 and Time.get_ticks_msec() - _down_t < 900:
				_down = false
				if not disabled:
					AudioManager.sfx_r("tap", 0.08)
				tapped.emit()
			_down = false
	elif event is InputEventMouseMotion and _down:
		if event.global_position.distance_to(_down_pos) >= 22.0:
			_down = false
			scale = Vector2.ONE
