class_name UiTheme
extends RefCounted
## Global theme: handwriting font, ink colours, unobtrusive scrollbars.


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = UiKit.font("hand")
	t.default_font_size = 22
	t.set_color("font_color", "Label", UiKit.INK)
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		t.set_stylebox(s, "Button", empty)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.2, 0.2, 0.3, 0.35)
	grab.set_corner_radius_all(4)
	grab.content_margin_left = 3
	grab.content_margin_right = 3
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	t.set_stylebox("scroll", "VScrollBar", empty)
	t.set_stylebox("panel", "ScrollContainer", empty)
	return t
