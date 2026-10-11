class_name SpeechBubble
extends Control
## Çizgi roman konuşma balonu. Kuyruk yönü ayarlanabilir, belirli süre sonra kaybolur.

var text := ""
var tail := Vector2(-0.3, 1.0)   # x: -1..1 kuyruğun yatay konumu, y: 1 aşağı / -1 yukarı
var bubble_color := Color.WHITE
var _label: Label
var max_w := 380.0


static func show_at(parent: Node, pos: Vector2, txt: String, dur := 2.4, tail_x := -0.3, color := Color.WHITE, width := 380.0) -> SpeechBubble:
	var b := SpeechBubble.new()
	b.text = txt
	b.tail = Vector2(tail_x, 1.0)
	b.bubble_color = color
	b.max_w = width
	parent.add_child(b)
	b._build()
	b.position = pos - Vector2(b.size.x * (0.5 + tail_x * 0.35), b.size.y + 24)
	b.position.x = clampf(b.position.x, 8.0, GameManager.screen_size.x - b.size.x - 8.0)
	b.pop(dur)
	return b


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 40


func _build() -> void:
	_label = UIKit.wrap_label(text, 24, UIKit.INK, true)
	_label.custom_minimum_size = Vector2(0, 0)
	var f: Font = GameManager.font_bold
	var w := minf(max_w, f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 8)
	_label.custom_minimum_size.x = maxf(80.0, w)
	_label.position = Vector2(20, 14)
	add_child(_label)
	_label.size = Vector2(_label.custom_minimum_size.x, 0)
	_label.reset_size()
	var lh := _label.get_minimum_size().y
	size = Vector2(_label.custom_minimum_size.x + 40, lh + 28)
	_label.size = Vector2(_label.custom_minimum_size.x, lh)
	pivot_offset = Vector2(size.x * (0.5 + tail.x * 0.35), size.y + 20)


func pop(dur: float) -> void:
	scale = Vector2(0.3, 0.3)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if dur > 0.0:
		tw.tween_interval(dur)
		tw.tween_property(self, "modulate:a", 0.0, 0.25)
		tw.tween_callback(queue_free)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var pts := DrawKit.rrect(r, 22)
	var tx := size.x * (0.5 + tail.x * 0.35)
	var tri := PackedVector2Array([Vector2(tx - 14, size.y - 4), Vector2(tx + 14, size.y - 4), Vector2(tx - 4 + tail.x * 18, size.y + 22)])
	DrawKit.shadow(self, Vector2(size.x * 0.5, size.y + 6), size.x * 0.45, 10, 0.18)
	DrawKit.fill(self, tri, UIKit.INK)
	var tri_in := PackedVector2Array([Vector2(tx - 9, size.y - 6), Vector2(tx + 9, size.y - 6), Vector2(tx - 3 + tail.x * 15, size.y + 15)])
	DrawKit.fill(self, pts, bubble_color)
	DrawKit.outline(self, pts, UIKit.INK, 4.0)
	DrawKit.fill(self, tri_in, bubble_color)
