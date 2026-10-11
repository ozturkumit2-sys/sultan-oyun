class_name UIKit
extends RefCounted
## Tutarlı görsel dil için arayüz yapı taşları: tombul 3B düğmeler, krem paneller,
## konturlu başlıklar, ikonlar, yıldızlar, ilerleme çubukları.

const INK := Color("#3b2417")
const CREAM := Color("#fff7ea")
const PAPER := Color("#ffeccc")
const ORANGE := Color("#ff9b3d")
const PINK := Color("#ff5fa2")
const PURPLE := Color("#a25cff")
const GREEN := Color("#2fc977")
const BLUE := Color("#4a7dff")
const YELLOW := Color("#ffc928")
const RED := Color("#ff4f5e")
const GRAY := Color("#b9a998")
const DARK := Color("#2a1b3d")


static func sb(bg: Color, radius := 24, border := Color(0, 0, 0, 0), bw := 0, bottom := 0, margin := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	if bottom > 0:
		s.border_width_bottom = bottom
	s.anti_aliasing = true
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	return s


static func label(text: String, size := 26, color := INK, bold := true, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", GameManager.font_bold if bold else GameManager.font_semi)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrap_label(text: String, size := 24, color := INK, bold := false, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, size, color, bold, align)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 100
	return l


static func title(text: String, size := 54, color := Color.WHITE, outline := INK, ow := 14) -> Label:
	var l := label(text, size, color, true)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", ow)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25))
	l.add_theme_constant_override("shadow_offset_y", 5)
	l.add_theme_constant_override("shadow_offset_x", 0)
	return l


static func outlined(l: Label, outline := INK, ow := 8) -> Label:
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", ow)
	return l


static func style_button(b: Button, color: Color, radius := 26, font_size := 30) -> void:
	var dark := color.darkened(0.32)
	var n := sb(color, radius, dark, 0, 8, 16)
	n.border_color = dark
	var h := sb(color.lightened(0.07), radius, dark, 0, 8, 16)
	var p := sb(color.darkened(0.06), radius, dark, 0, 3, 16)
	p.content_margin_top = n.content_margin_top + 5
	p.content_margin_bottom = maxf(0, n.content_margin_bottom - 5)
	var d := sb(Color("#cbbba9"), radius, Color("#a39280"), 0, 8, 16)
	for st in [["normal", n], ["hover", h], ["pressed", p], ["disabled", d], ["hover_pressed", p]]:
		b.add_theme_stylebox_override(st[0], st[1])
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_override("font", GameManager.font_bold)
	b.add_theme_font_size_override("font_size", font_size)
	var txt := Color.WHITE if color.get_luminance() < 0.72 else INK
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, txt)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.75))
	b.add_theme_color_override("font_outline_color", Color(dark, 0.55) if txt == Color.WHITE else Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 6 if txt == Color.WHITE else 0)
	b.add_theme_constant_override("icon_max_width", int(font_size * 1.5))
	b.add_theme_constant_override("h_separation", 10)


static func button(text: String, color := ORANGE, min_size := Vector2(0, 86), font_size := 30, icon := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	style_button(b, color, 26, font_size)
	if icon != "":
		b.icon = GameManager.icon_tex(icon)
		b.expand_icon = false
	_juice(b)
	return b


static func icon_button(icon_name: String, color := CREAM, sz := 84) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(sz, sz)
	style_button(b, color, int(sz * 0.32), 24)
	var tr := TextureRect.new()
	tr.texture = GameManager.icon_tex(icon_name)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = sz * 0.16
	tr.offset_right = -sz * 0.16
	tr.offset_top = sz * 0.12
	tr.offset_bottom = -sz * 0.2
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tr)
	_juice(b)
	return b


static func _juice(b: Button) -> void:
	b.button_down.connect(func():
		AudioManager.sfx_r("click", 0.05)
		GameManager.vibrate(12))
	b.resized.connect(func(): b.pivot_offset = b.size * 0.5)


static func pop_in(c: Control, delay := 0.0) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(0.6, 0.6)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(c, "modulate:a", 1.0, 0.2)


static func panel(color := CREAM, radius := 28, border := INK, bw := 4, margin := 18) -> PanelContainer:
	var p := PanelContainer.new()
	var s := sb(color, radius, border, bw, 0, margin)
	s.content_margin_top = margin
	s.content_margin_bottom = margin
	s.shadow_color = Color(0, 0, 0, 0.18)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 5)
	p.add_theme_stylebox_override("panel", s)
	return p


static func vbox(sep := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(h := 10.0, w := 0.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func expander() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func icon(icon_name: String, sz := 40.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = GameManager.icon_tex(icon_name)
	t.custom_minimum_size = Vector2(sz, sz)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func icon_label(icon_name: String, text: String, size := 26, color := INK, isz := 38.0) -> HBoxContainer:
	var h := hbox(6)
	h.add_child(icon(icon_name, isz))
	var l := label(text, size, color)
	h.add_child(l)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


static func stars(filled: int, total := 3, sz := 40.0) -> HBoxContainer:
	var h := hbox(2)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in total:
		h.add_child(icon("star" if i < filled else "star_empty", sz))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


static func chip(text: String, color: Color, size := 20) -> PanelContainer:
	var p := PanelContainer.new()
	var s := sb(color, 16, color.darkened(0.3), 0, 3, 10)
	s.content_margin_top = 3
	s.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", s)
	var l := label(text, size, Color.WHITE if color.get_luminance() < 0.7 else INK)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func bar(value: float, max_v: float, color: Color, h := 18.0, w := 200.0) -> Control:
	var b := ProgressBarDraw.new()
	b.value = value
	b.max_value = max_v
	b.color = color
	b.custom_minimum_size = Vector2(w, h)
	return b


static func scroll(child: Control, horizontal := false) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER if horizontal else ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if horizontal else ScrollContainer.SCROLL_MODE_AUTO
	s.scroll_deadzone = 14
	s.add_child(child)
	if horizontal:
		child.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


static func modal(parent: Node, title_text: String, body: String, buttons: Array, extra: Control = null) -> Modal:
	var m := Modal.new()
	parent.add_child(m)
	m.build(title_text, body, buttons, extra)
	return m


static func coin_text(n: int) -> String:
	var s := str(n)
	if n >= 1000:
		s = "%d.%03d" % [n / 1000, n % 1000]
	return s


static func fmt(v: float) -> String:
	if absf(v - roundf(v)) < 0.01:
		return str(int(roundf(v)))
	return ("%.1f" % v).replace(".", ",")
