class_name UI
extends RefCounted
## Luxury design system: palette, typography and reusable building blocks for every screen.

const BG := Color("#0f0d12")
const BG2 := Color("#16131a")
const PANEL := Color("#1d1922")
const PANEL2 := Color("#25202b")
const LINE := Color(0.79, 0.65, 0.35, 0.22)
const GOLD := Color("#c9a55a")
const GOLD2 := Color("#e6cf95")
const CREAM := Color("#f3ebdd")
const TEXT := Color("#eee6d8")
const MUTED := Color("#a59b8e")
const DIM := Color("#6f665d")
const INK := Color("#17131b")
const GREEN := Color("#7cc79a")
const RED := Color("#e5786e")
const ROSE := Color("#d99aa5")
const BLUE := Color("#86acd9")
const AMBER := Color("#e3a857")
const DIM_COLORS := {"citrus": "#f2d24b", "aromatic": "#8fc1a0", "green": "#6fae5a", "aquatic": "#6db6d9", "floral": "#e79ab3",
	"fruity": "#f08a5d", "gourmand": "#c98b5a", "spicy": "#d0573f", "woody": "#9b7a52", "amber": "#d6953a", "musk": "#c9bfd6",
	"powdery": "#d9c7e8", "animalic": "#7a5240"}

static var _fonts := {}


static func font(kind := "body") -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var path: String = {"body": "Montserrat-Regular", "medium": "Montserrat-Medium", "semi": "Montserrat-SemiBold", "bold": "Montserrat-Bold",
		"title": "Playfair-SemiBold", "title_bold": "Playfair-Bold"}.get(kind, "Montserrat-Regular")
	var f: Font = load("res://assets/fonts/%s.ttf" % path)
	_fonts[kind] = f
	return f


static func dim_color(d: String) -> Color:
	return Color(DIM_COLORS.get(d, "#888888"))


static func sb(bg: Color, radius := 18, border := Color(0, 0, 0, 0), bw := 0, pad := 16.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	s.anti_aliasing = true
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.75
	s.content_margin_bottom = pad * 0.75
	return s


static func lbl(text: String, size := 24, color := TEXT, kind := "body", align := HORIZONTAL_ALIGNMENT_LEFT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 60
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func para(text: String, size := 22, color := MUTED) -> Label:
	return lbl(text, size, color, "body", HORIZONTAL_ALIGNMENT_LEFT, true)


static func title(text: String, size := 40, color := CREAM) -> Label:
	return lbl(text, size, color, "title")


static func money_lbl(v: float, size := 24, kind := "semi") -> Label:
	return lbl(G.money(v), size, GREEN if v >= 0.0 else RED, kind)


static func hbox(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func grid(cols := 2, sep := 12) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", sep)
	g.add_theme_constant_override("v_separation", sep)
	return g


static func spacer(h := 8.0, w := 0.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func expand(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func panel(style := "dark", pad := 18.0) -> PanelContainer:
	var p := PanelContainer.new()
	match style:
		"dark":
			p.add_theme_stylebox_override("panel", sb(PANEL, 18, LINE, 1, pad))
		"gold":
			p.add_theme_stylebox_override("panel", sb(Color(0.79, 0.65, 0.35, 0.12), 18, Color(0.79, 0.65, 0.35, 0.55), 1, pad))
		"cream":
			p.add_theme_stylebox_override("panel", sb(CREAM, 18, Color(0, 0, 0, 0), 0, pad))
		"flat":
			p.add_theme_stylebox_override("panel", sb(PANEL2, 14, Color(0, 0, 0, 0), 0, pad))
		"warn":
			p.add_theme_stylebox_override("panel", sb(Color(0.9, 0.47, 0.43, 0.12), 14, Color(0.9, 0.47, 0.43, 0.5), 1, pad))
		"good":
			p.add_theme_stylebox_override("panel", sb(Color(0.49, 0.78, 0.6, 0.1), 14, Color(0.49, 0.78, 0.6, 0.45), 1, pad))
	return p


## Card: returns the inner VBox (already inside a styled PanelContainer added to parent).
static func card(parent: Control, style := "dark", sep := 12, pad := 18.0) -> VBoxContainer:
	var p := panel(style, pad)
	var v := vbox(sep)
	p.add_child(v)
	if parent != null:
		parent.add_child(p)
	return v


static func section(parent: Control, text: String, right: Control = null) -> HBoxContainer:
	var h := hbox(10)
	var l := lbl(text.to_upper(), 19, GOLD, "semi")
	l.add_theme_constant_override("line_spacing", 0)
	h.add_child(l)
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size = Vector2(10, 1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(line)
	if right != null:
		h.add_child(right)
	parent.add_child(h)
	return h


static func style_btn(b: Button, style := "primary", size := 24) -> void:
	var c_bg := GOLD
	var c_fg := INK
	var border := Color(0, 0, 0, 0)
	var bw := 0
	match style:
		"secondary":
			c_bg = Color(0.79, 0.65, 0.35, 0.08)
			c_fg = GOLD2
			border = Color(0.79, 0.65, 0.35, 0.7)
			bw = 2
		"ghost":
			c_bg = Color(1, 1, 1, 0.0)
			c_fg = GOLD2
		"danger":
			c_bg = Color(0.9, 0.47, 0.43, 0.14)
			c_fg = RED
			border = Color(0.9, 0.47, 0.43, 0.6)
			bw = 2
		"dark":
			c_bg = PANEL2
			c_fg = TEXT
			border = LINE
			bw = 1
		"chip":
			c_bg = PANEL2
			c_fg = TEXT
			border = Color(1, 1, 1, 0.08)
			bw = 1
		"chip_on":
			c_bg = Color(0.79, 0.65, 0.35, 0.25)
			c_fg = GOLD2
			border = GOLD
			bw = 2
	var rad := 999 if style.begins_with("chip") else 16
	var n := sb(c_bg, rad, border, bw, 18)
	var h := sb(c_bg.lightened(0.08) if c_bg.a > 0.5 else Color(c_bg.r, c_bg.g, c_bg.b, c_bg.a + 0.08), rad, border, bw, 18)
	var p := sb(c_bg.darkened(0.12) if c_bg.a > 0.5 else Color(c_bg.r, c_bg.g, c_bg.b, c_bg.a + 0.15), rad, border, bw, 18)
	var d := sb(Color(0.3, 0.28, 0.3, 0.5), rad, Color(0, 0, 0, 0), 0, 18)
	for st in [["normal", n], ["hover", h], ["pressed", p], ["disabled", d], ["hover_pressed", p], ["focus", n]]:
		b.add_theme_stylebox_override(st[0], st[1])
	b.add_theme_font_override("font", font("semi"))
	b.add_theme_font_size_override("font_size", size)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(k, c_fg)
	b.add_theme_color_override("font_disabled_color", Color(0.75, 0.72, 0.7, 0.6))
	b.focus_mode = Control.FOCUS_NONE


static func btn(text: String, cb: Callable, style := "primary", size := 24, min_h := 76.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	if style != "ghost" and not style.begins_with("chip"):
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	style_btn(b, style, size)
	if cb.is_valid():
		b.pressed.connect(func():
			Snd.click()
			cb.call())
	return b


static func chip(text: String, on: bool, cb: Callable, size := 21) -> Button:
	return btn(text, cb, "chip_on" if on else "chip", size, 56)


## Segmented selector: options = [[label, value], ...]
static func seg(options: Array, selected: Variant, cb: Callable, size := 21, wrap := true) -> Control:
	var box: Container
	if wrap:
		var f := HFlowContainer.new()
		f.add_theme_constant_override("h_separation", 8)
		f.add_theme_constant_override("v_separation", 8)
		box = f
	else:
		box = hbox(8)
	for o in options:
		var val: Variant = o[1]
		var b := chip(str(o[0]), val == selected, func(): cb.call(val), size)
		box.add_child(b)
	return box


static func kv(parent: Control, key: String, value: String, vcolor := TEXT, size := 22) -> HBoxContainer:
	var h := hbox(10)
	var k := lbl(key, size, MUTED)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(k)
	var v := lbl(value, size, vcolor, "semi", HORIZONTAL_ALIGNMENT_RIGHT)
	if value.length() > 24:
		# long values wrap on the right instead of squeezing the key into a single column
		k.autowrap_mode = TextServer.AUTOWRAP_OFF
		k.size_flags_horizontal = Control.SIZE_FILL
		v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	if parent != null:
		parent.add_child(h)
	return h


static func stat(label: String, value: String, sub := "", color := CREAM, sub_color := MUTED) -> PanelContainer:
	var p := panel("flat", 14)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := vbox(2)
	p.add_child(v)
	v.add_child(lbl(label.to_upper(), 16, MUTED, "semi"))
	var vl := lbl(value, 30, color, "title")
	vl.clip_text = true
	v.add_child(vl)
	if sub != "":
		v.add_child(lbl(sub, 18, sub_color, "medium"))
	return p


static func pill(text: String, color := GOLD, size := 17) -> PanelContainer:
	var p := PanelContainer.new()
	var s := sb(Color(color.r, color.g, color.b, 0.16), 999, Color(color.r, color.g, color.b, 0.6), 1, 10)
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", s)
	p.add_child(lbl(text, size, color.lightened(0.15), "semi"))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


static func bar(value: float, color := GOLD, h := 10.0, bg := Color(1, 1, 1, 0.07)) -> Control:
	var b := MeterBar.new()
	b.value = clampf(value, 0.0, 1.0)
	b.color = color
	b.bg = bg
	b.custom_minimum_size = Vector2(40, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


static func divider(parent: Control) -> void:
	var r := ColorRect.new()
	r.color = LINE
	r.custom_minimum_size = Vector2(10, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


## A tappable row card: title, subtitle, right value, optional leading control.
static func row_card(parent: Control, title_text: String, sub: String, right: String, cb: Callable, lead: Control = null, right_color := GOLD2) -> PanelContainer:
	var p := TapPanel.new()
	p.add_theme_stylebox_override("panel", sb(PANEL, 16, LINE, 1, 16))
	p.tapped = cb
	var h := hbox(14)
	p.add_child(h)
	if lead != null:
		h.add_child(lead)
	var v := vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := lbl(title_text, 24, TEXT, "semi")
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(t)
	if sub != "":
		var s := lbl(sub, 19, MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true)
		v.add_child(s)
	h.add_child(v)
	if right != "":
		h.add_child(lbl(right, 22, right_color, "semi", HORIZONTAL_ALIGNMENT_RIGHT))
	if cb.is_valid():
		h.add_child(lbl("›", 34, DIM, "title"))
	if parent != null:
		parent.add_child(p)
	return p


static func empty(parent: Control, text: String) -> void:
	var c := card(parent, "flat")
	c.add_child(lbl(text, 22, MUTED, "body", HORIZONTAL_ALIGNMENT_CENTER, true))


static func slider(minv: float, maxv: float, step: float, val: float, cb: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = minv
	s.max_value = maxv
	s.step = step
	s.value = val
	s.custom_minimum_size = Vector2(120, 48)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var track := sb(Color(1, 1, 1, 0.1), 999, Color(0, 0, 0, 0), 0, 0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var fill := sb(GOLD, 999, Color(0, 0, 0, 0), 0, 0)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	s.add_theme_icon_override("grabber", _knob())
	s.add_theme_icon_override("grabber_highlight", _knob())
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(v): cb.call(v))
	return s


static var _knob_tex: Texture2D


static func _knob() -> Texture2D:
	if _knob_tex != null:
		return _knob_tex
	var img := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	for y in 40:
		for x in 40:
			var d := Vector2(x - 19.5, y - 19.5).length()
			var a := clampf(18.0 - d, 0.0, 1.0)
			var c := GOLD2 if d < 13.0 else GOLD
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	_knob_tex = ImageTexture.create_from_image(img)
	return _knob_tex


static func line_edit(text: String, placeholder := "", size := 26) -> LineEdit:
	var e := LineEdit.new()
	e.text = text
	e.placeholder_text = placeholder
	e.custom_minimum_size = Vector2(100, 72)
	e.add_theme_font_override("font", font("medium"))
	e.add_theme_font_size_override("font_size", size)
	e.add_theme_color_override("font_color", TEXT)
	e.add_theme_color_override("font_placeholder_color", DIM)
	e.add_theme_color_override("caret_color", GOLD)
	e.add_theme_stylebox_override("normal", sb(PANEL2, 14, LINE, 1, 16))
	e.add_theme_stylebox_override("focus", sb(PANEL2, 14, GOLD, 2, 16))
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return e


static func stars(v: float, size := 22) -> Label:
	var full := int(round(v))
	var s := ""
	for i in 5:
		s += "★" if i < full else "☆"
	return lbl(s, size, GOLD)


static func trend_text(cur: float, prev: float) -> String:
	if prev <= 0.0:
		return ""
	var d := cur / prev - 1.0
	return ("↑ " if d >= 0.0 else "↓ ") + G.pct(absf(d))


static func icon(name: String, size := 40.0, color := GOLD) -> Control:
	var i := Ico.new()
	i.kind = name
	i.color = color
	i.custom_minimum_size = Vector2(size, size)
	return i


static func dims_bars(parent: Control, v: PackedFloat32Array, n := 5) -> void:
	var idx: Array = []
	for i in v.size():
		idx.append(i)
	idx.sort_custom(func(a, b): return v[a] > v[b])
	for k in mini(n, idx.size()):
		var i: int = idx[k]
		if v[i] < 0.02:
			continue
		var h := hbox(10)
		var l := lbl(DB.dims[i].capitalize(), 20, MUTED)
		l.custom_minimum_size.x = 140
		h.add_child(l)
		h.add_child(bar(v[i] / maxf(0.01, v[idx[0]]), dim_color(DB.dims[i]), 12))
		h.add_child(lbl(G.pct(v[i]), 18, MUTED))
		parent.add_child(h)


static func tile(parent: Control, icon_name: String, title_text: String, sub: String, cb: Callable, badge := 0) -> PanelContainer:
	var p := TapPanel.new()
	p.add_theme_stylebox_override("panel", sb(PANEL, 18, LINE, 1, 16))
	p.tapped = cb
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 150)
	var v := vbox(6)
	p.add_child(v)
	var ic := icon(icon_name, 44, GOLD)
	(ic as Ico).badge = badge
	v.add_child(ic)
	v.add_child(lbl(title_text, 23, CREAM, "semi", HORIZONTAL_ALIGNMENT_LEFT, true))
	if sub != "":
		v.add_child(lbl(sub, 18, MUTED, "body", HORIZONTAL_ALIGNMENT_LEFT, true))
	if parent != null:
		parent.add_child(p)
	return p


static func back_row(parent: Control, text: String, cb: Callable) -> void:
	parent.add_child(btn(text, cb, "secondary", 22, 64))
