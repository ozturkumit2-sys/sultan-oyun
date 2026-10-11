class_name BowlSlot
extends Control
## Karıştırma kasesindeki tek yuva. Doluysa ikon gösterir; dokununca boşalır.

signal tapped

var index := 0
var item_id := "":
	set(v):
		item_id = v
		_refresh()
var mystery := false
var _icon: IngredientIcon
var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_icon = IngredientIcon.new()
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 12
	_icon.offset_top = 8
	_icon.offset_right = -12
	_icon.offset_bottom = -14
	add_child(_icon)
	_refresh()
	resized.connect(func(): pivot_offset = size * 0.5)


func _refresh() -> void:
	if _icon:
		_icon.set_item(item_id)
	queue_redraw()


func _process(delta: float) -> void:
	if mystery:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 4
	if mystery:
		DrawKit.glow(self, c, r * 1.35, Color(0.65, 0.4, 1.0, 0.45 + 0.2 * sin(_t * 4.0)))
	var bowl := DrawKit.ellipse(c + Vector2(0, 4), r, r * 0.92, 40)
	DrawKit.fill(self, bowl, Color("#f2e6d4") if item_id == "" else Color("#fffaf1"), 0.12)
	DrawKit.outline(self, bowl, UIKit.INK, 4.0)
	DrawKit.poly_line(self, DrawKit.arc(c + Vector2(0, 4), r - 10, r * 0.92 - 10, PI * 0.15, PI * 0.85, 12), Color(0, 0, 0, 0.08), 6.0)
	if item_id == "":
		DrawKit.text(self, "+", c + Vector2(0, -2), 44, Color(0.23, 0.14, 0.09, 0.3))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if item_id != "":
			tapped.emit()
