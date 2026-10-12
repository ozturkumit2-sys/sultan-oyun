class_name Sheet
extends Control
## A panel that slides up from the bottom over a dimmed background.
## Subclasses fill `body` (a VBoxContainer inside the paper's margins).

signal closed

var paper: PaperPanel
var body: VBoxContainer
var dim: ColorRect
var close_btn: NoteButton
var height_frac := 0.62
var is_open := false
var _tw: Tween


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	dim = ColorRect.new()
	dim.color = Color(0.12, 0.08, 0.05, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(dim)
	paper = PaperPanel.new()
	add_child(paper)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	paper.content.add_child(body)
	close_btn = NoteButton.make("", "close", "round", Color("fffdf5"), Vector2(56, 56))
	close_btn.pressed.connect(close)
	paper.add_child(close_btn)


func setup_paper(style: String, frac: float, tab := "") -> void:
	paper.set_style(style)
	paper.tab_text = tab
	height_frac = frac


func _layout() -> void:
	var vs := get_viewport_rect().size
	var h := vs.y * height_frac
	paper.size = Vector2(vs.x - 20, h)
	paper.position = Vector2(10, vs.y - h - 6)
	close_btn.position = Vector2(paper.size.x - 66, 6 if paper.style != "clipboard" else 2)
	if paper.style == "manila":
		close_btn.position.y = 40
	if paper.style == "cork":
		close_btn.position = Vector2(paper.size.x - 64, 4)


func open() -> void:
	_layout()
	visible = true
	is_open = true
	Audio.play("page", -6.0)
	if _tw:
		_tw.kill()
	var target := paper.position.y
	paper.position.y = get_viewport_rect().size.y + 20
	_tw = create_tween().set_parallel(true)
	_tw.tween_property(paper, "position:y", target, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.tween_property(dim, "color:a", 0.28, 0.2)


func close() -> void:
	if not is_open:
		return
	is_open = false
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true)
	_tw.tween_property(paper, "position:y", get_viewport_rect().size.y + 20, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tw.tween_property(dim, "color:a", 0.0, 0.2)
	_tw.chain().tween_callback(func():
		visible = false
		closed.emit())


func clear_body() -> void:
	for c in body.get_children():
		c.queue_free()


static func label(text: String, size := 22, kind := "hand", col := UiKit.INK, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiKit.font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func scroll() -> ScrollContainer:
	var s := DragScroll.new()
	s.get_v_scroll_bar().modulate = Color(1, 1, 1, 0.35)
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.follow_focus = false
	return s
