class_name UI
extends RefCounted
## Tema ve arayüz yardımcıları: koyu lacivert, zümrüt yeşili, eskitilmiş altın.

const NAVY := Color("0c142c")
const NAVY2 := Color("152044")
const NAVY3 := Color("1d2b57")
const EMERALD := Color("1d6a50")
const EMERALD2 := Color("2b8a68")
const GOLD := Color("c9a24e")
const GOLD2 := Color("ead18c")
const CREAM := Color("f3ead4")
const TEXT := Color("efe6cf")
const MUTED := Color("aaa186")
const RED := Color("a33a35")
const GREEN := Color("6fbf73")
const BLUE := Color("6c9be0")

static var _theme: Theme
static var font_body: FontFile
static var font_semi: FontFile
static var font_title: FontFile
static var font_logo: FontFile


static func fonts() -> void:
	if font_body:
		return
	font_body = load("res://assets/fonts/FiraSans-Regular.ttf")
	font_semi = load("res://assets/fonts/FiraSans-SemiBold.ttf")
	font_title = load("res://assets/fonts/CormorantGaramond-Bold.ttf")
	font_logo = load("res://assets/fonts/CinzelDecorative-Bold.ttf")


static func sb(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 10, pad: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = true
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	fonts()
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 22
	# Button
	t.set_stylebox("normal", "Button", sb(NAVY3, GOLD.darkened(0.25), 2, 10, 14))
	t.set_stylebox("hover", "Button", sb(NAVY3.lightened(0.08), GOLD, 2, 10, 14))
	t.set_stylebox("pressed", "Button", sb(EMERALD, GOLD2, 2, 10, 14))
	t.set_stylebox("disabled", "Button", sb(Color(0.12, 0.14, 0.2, 0.8), Color(0.3, 0.3, 0.35), 1, 10, 14))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD2)
	t.set_color("font_pressed_color", "Button", CREAM)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.53, 0.5))
	t.set_font("font", "Button", font_semi)
	t.set_font_size("font_size", "Button", 22)
	# Label
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.45))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	# Panel
	t.set_stylebox("panel", "PanelContainer", sb(Color(NAVY, 0.96), GOLD.darkened(0.15), 2, 14, 18))
	t.set_stylebox("panel", "Panel", sb(Color(NAVY, 0.96), GOLD.darkened(0.15), 2, 14, 18))
	# RichTextLabel
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font("normal_font", "RichTextLabel", font_body)
	t.set_font("bold_font", "RichTextLabel", font_semi)
	t.set_font("italics_font", "RichTextLabel", font_body)
	t.set_font_size("normal_font_size", "RichTextLabel", 22)
	t.set_font_size("bold_font_size", "RichTextLabel", 22)
	t.set_font_size("italics_font_size", "RichTextLabel", 21)
	# LineEdit
	t.set_stylebox("normal", "LineEdit", sb(NAVY2, GOLD.darkened(0.2), 2, 8, 12))
	t.set_stylebox("focus", "LineEdit", sb(NAVY2, GOLD2, 2, 8, 12))
	t.set_color("font_color", "LineEdit", CREAM)
	t.set_font_size("font_size", "LineEdit", 24)
	# ProgressBar
	t.set_stylebox("background", "ProgressBar", sb(Color(0.05, 0.07, 0.14, 0.9), Color(0, 0, 0, 0), 0, 6, 0))
	t.set_stylebox("fill", "ProgressBar", sb(GOLD, Color(0, 0, 0, 0), 0, 6, 0))
	t.set_font_size("font_size", "ProgressBar", 14)
	# ScrollContainer / scrollbars
	var grab := sb(GOLD.darkened(0.2), Color(0, 0, 0, 0), 0, 6, 4)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", sb(GOLD, Color(0, 0, 0, 0), 0, 6, 4))
	t.set_stylebox("grabber_pressed", "VScrollBar", sb(GOLD2, Color(0, 0, 0, 0), 0, 6, 4))
	t.set_stylebox("scroll", "VScrollBar", sb(Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 0, 6, 4))
	t.set_constant("scrollbar_h_separation", "ScrollContainer", 6)
	# HSlider
	t.set_stylebox("slider", "HSlider", sb(NAVY3, Color(0, 0, 0, 0), 0, 6, 4))
	t.set_stylebox("grabber_area", "HSlider", sb(GOLD, Color(0, 0, 0, 0), 0, 6, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", sb(GOLD2, Color(0, 0, 0, 0), 0, 6, 4))
	# CheckButton
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_font_size("font_size", "CheckButton", 22)
	# TabBar
	t.set_stylebox("tab_selected", "TabBar", sb(EMERALD, GOLD, 2, 8, 14))
	t.set_stylebox("tab_unselected", "TabBar", sb(NAVY3, GOLD.darkened(0.4), 1, 8, 14))
	t.set_stylebox("tab_hovered", "TabBar", sb(NAVY3.lightened(0.1), GOLD, 1, 8, 14))
	t.set_font("font", "TabBar", font_semi)
	t.set_font_size("font_size", "TabBar", 20)
	t.set_color("font_selected_color", "TabBar", CREAM)
	t.set_color("font_unselected_color", "TabBar", MUTED)
	t.set_color("font_hovered_color", "TabBar", GOLD2)
	# Tooltip
	t.set_stylebox("panel", "TooltipPanel", sb(NAVY, GOLD, 1, 6, 8))
	_theme = t
	return t


# ------------------------------------------------------------ widget yardımcıları

static func label(text: String, size: int = 22, color: Color = TEXT, font: Font = null) -> Label:
	fonts()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func title(text: String, size: int = 34) -> Label:
	fonts()
	var l := label(text, size, GOLD2, font_title)
	return l


static func wrap_label(text: String, size: int = 21, color: Color = TEXT) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func rich(text: String, size: int = 22) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = text
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size - 1)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


static func button(text: String, cb: Callable = Callable(), min_h: int = 56, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = false
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if primary:
		b.add_theme_stylebox_override("normal", sb(EMERALD, GOLD, 2, 10, 14))
		b.add_theme_stylebox_override("hover", sb(EMERALD2, GOLD2, 2, 10, 14))
	if cb.is_valid():
		b.pressed.connect(func():
			AudioManager.play_ui("click")
			cb.call())
	return b


static func hbox(sep: int = 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


static func vbox(sep: int = 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


static func grid(cols: int, hsep: int = 10, vsep: int = 10) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", hsep)
	g.add_theme_constant_override("v_separation", vsep)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


static func scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


static func card(bg: Color = NAVY2, border: Color = Color(GOLD, 0.35), pad: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(bg, border, 1, 10, pad))
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p


static func bar(value: float, max_v: float = 100.0, color: Color = GOLD, h: int = 14, w: int = 0) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = max_v
	p.value = value
	p.show_percentage = false
	p.custom_minimum_size = Vector2(w, h)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("fill", sb(color, Color(0, 0, 0, 0), 0, 6, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func stat_row(name: String, value: float, color: Color = GOLD, show_num: bool = true) -> HBoxContainer:
	var h := hbox(10)
	var l := label(name, 19, MUTED)
	l.custom_minimum_size = Vector2(150, 0)
	h.add_child(l)
	var b := bar(value, 100.0, color, 14)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	if show_num:
		var n := label(str(int(round(value))), 19, TEXT)
		n.custom_minimum_size = Vector2(40, 0)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(n)
	return h


static func sep_line() -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(GOLD, 0.35)
	c.custom_minimum_size = Vector2(0, 2)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func delta_text(deltas: Dictionary) -> String:
	var parts: Array = []
	for k in deltas.keys():
		var v := float(deltas[k])
		if absf(v) < 0.5:
			continue
		var name: String = GameState.REL_NAMES.get(k, k)
		var good := v > 0
		if k in ["korku", "kiskanclik", "rekabet"]:
			good = not good
		var col := "#7fd18a" if good else "#e07a6a"
		parts.append("[color=%s]%s %s%d[/color]" % [col, name, "+" if v > 0 else "", int(round(v))])
	return "  ".join(PackedStringArray(parts))


static func portrait(id: String, size: int = 64) -> Control:
	var c := PortraitIcon.new()
	c.char_id = id
	c.custom_minimum_size = Vector2(size, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func clear(node: Node) -> void:
	for ch in node.get_children():
		node.remove_child(ch)
		ch.queue_free()
