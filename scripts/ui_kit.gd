class_name UIKit
extends RefCounted
## İznik-tile inspired UI kit: cobalt, turquoise, coral on warm cream.

const COBALT := Color("1f4e9c")
const COBALT_DARK := Color("143570")
const TURQ := Color("27a9a0")
const CORAL := Color("e0533a")
const CREAM := Color("fff5e3")
const NAVY := Color("16213b")
const GOLD := Color("f2b33d")
const SAND := Color("f3dcb5")

static var _fonts := {}


static func font(weight := 700) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]
	var base: FontFile = load("res://assets/fonts/Baloo2.ttf")
	var fv := FontVariation.new()
	fv.base_font = base
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): weight}
	_fonts[weight] = fv
	return fv


static func label(text: String, size := 28, color := CREAM, weight := 700, outline := 0, outline_color := NAVY) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", outline_color)
	return l


static func panel_style(bg := CREAM, border := COBALT, radius := 26, border_w := 5) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.08, 0.05, 0.12, 0.35)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	s.set_content_margin_all(22)
	s.anti_aliasing = true
	return s


static func _btn_style(c: Color, radius: int, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(4)
	s.border_width_bottom = 8
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 8
	s.content_margin_bottom = 12
	s.anti_aliasing = true
	return s


static func button(text: String, c := COBALT, size := 34, min_w := 300) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 0)
	b.add_theme_font_override("font", font(800))
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", CREAM)
	b.add_theme_color_override("font_hover_color", CREAM)
	b.add_theme_color_override("font_pressed_color", CREAM)
	b.add_theme_color_override("font_focus_color", CREAM)
	b.add_theme_stylebox_override("normal", _btn_style(c, 22, c.darkened(0.3)))
	b.add_theme_stylebox_override("hover", _btn_style(c.lightened(0.08), 22, c.darkened(0.3)))
	var pressed := _btn_style(c.darkened(0.08), 22, c.darkened(0.35))
	pressed.border_width_bottom = 4
	pressed.content_margin_top = 12
	pressed.content_margin_bottom = 8
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Sfx.play("click", 1.0, -6.0))
	return b


static func slider_row(text: String, value: float, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := label(text, 26, NAVY, 700)
	l.custom_minimum_size = Vector2(230, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(300, 44)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var grab := StyleBoxFlat.new()
	grab.bg_color = COBALT
	grab.set_corner_radius_all(8)
	grab.content_margin_top = 6
	grab.content_margin_bottom = 6
	var area := StyleBoxFlat.new()
	area.bg_color = TURQ
	area.set_corner_radius_all(8)
	area.content_margin_top = 6
	area.content_margin_bottom = 6
	s.add_theme_stylebox_override("slider", grab)
	s.add_theme_stylebox_override("grabber_area", area)
	s.add_theme_stylebox_override("grabber_area_highlight", area)
	s.value_changed.connect(cb)
	h.add_child(s)
	return h


static func toggle_row(text: String, value: bool, cb: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := label(text, 26, NAVY, 700)
	l.custom_minimum_size = Vector2(230, 0)
	h.add_child(l)
	var b := button("Açık" if value else "Kapalı", TURQ if value else Color("9a8f86"), 24, 160)
	b.toggle_mode = true
	b.button_pressed = value
	b.toggled.connect(func(on: bool):
		b.text = "Açık" if on else "Kapalı"
		var c := TURQ if on else Color("9a8f86")
		b.add_theme_stylebox_override("normal", _btn_style(c, 22, c.darkened(0.3)))
		b.add_theme_stylebox_override("hover", _btn_style(c, 22, c.darkened(0.3)))
		b.add_theme_stylebox_override("pressed", _btn_style(c, 22, c.darkened(0.3)))
		cb.call(on))
	h.add_child(b)
	return h


# ------------------------------------------------------------ vector icons
static func draw_fish(ci: CanvasItem, c: Vector2, s: float, col: Color, outline := NAVY) -> void:
	var body := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		body.append(c + Vector2(cos(a) * s * 0.55, sin(a) * s * 0.32))
	var tail := PackedVector2Array([c + Vector2(s * 0.42, 0), c + Vector2(s * 0.85, -s * 0.34), c + Vector2(s * 0.85, s * 0.34)])
	ci.draw_colored_polygon(tail, outline)
	ci.draw_colored_polygon(_grow(body, c, s * 0.08), outline)
	var tail_in := PackedVector2Array([c + Vector2(s * 0.48, 0), c + Vector2(s * 0.78, -s * 0.24), c + Vector2(s * 0.78, s * 0.24)])
	ci.draw_colored_polygon(tail_in, col.darkened(0.12))
	ci.draw_colored_polygon(body, col)
	ci.draw_circle(c + Vector2(-s * 0.3, -s * 0.05), s * 0.09, outline)
	ci.draw_circle(c + Vector2(-s * 0.32, -s * 0.08), s * 0.035, Color.WHITE)


static func _grow(poly: PackedVector2Array, c: Vector2, by: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + (p - c).normalized() * by)
	return out


static func draw_paw(ci: CanvasItem, c: Vector2, s: float, col: Color, outline := NAVY) -> void:
	var pads := [[Vector2(0, s * 0.18), s * 0.34], [Vector2(-s * 0.36, -s * 0.2), s * 0.14], [Vector2(-s * 0.13, -s * 0.4), s * 0.15],
		[Vector2(s * 0.13, -s * 0.4), s * 0.15], [Vector2(s * 0.36, -s * 0.2), s * 0.14]]
	for p in pads:
		ci.draw_circle(c + p[0], p[1] + s * 0.07, outline)
	for p in pads:
		ci.draw_circle(c + p[0], p[1], col)


static func draw_cat_head(ci: CanvasItem, c: Vector2, s: float, col: Color, outline := NAVY, face := true) -> void:
	var earL := PackedVector2Array([c + Vector2(-s * 0.48, -s * 0.05), c + Vector2(-s * 0.42, -s * 0.62), c + Vector2(-s * 0.08, -s * 0.35)])
	var earR := PackedVector2Array([c + Vector2(s * 0.48, -s * 0.05), c + Vector2(s * 0.42, -s * 0.62), c + Vector2(s * 0.08, -s * 0.35)])
	ci.draw_colored_polygon(_grow(earL, c + Vector2(-s * 0.3, -s * 0.3), s * 0.07), outline)
	ci.draw_colored_polygon(_grow(earR, c + Vector2(s * 0.3, -s * 0.3), s * 0.07), outline)
	ci.draw_circle(c, s * 0.5 + s * 0.07, outline)
	ci.draw_colored_polygon(earL, col)
	ci.draw_colored_polygon(earR, col)
	ci.draw_circle(c, s * 0.5, col)
	if face:
		ci.draw_circle(c + Vector2(-s * 0.18, -s * 0.02), s * 0.08, outline)
		ci.draw_circle(c + Vector2(s * 0.18, -s * 0.02), s * 0.08, outline)
		ci.draw_circle(c + Vector2(0, s * 0.14), s * 0.05, CORAL)
