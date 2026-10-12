class_name Screen
extends Control
## Base class for all screens: scrolling body, rebuild on world changes, title for the top bar.

var params: Dictionary = {}
var scroll: DragScroll
var body: VBoxContainer
var title_text := ""
var scrolls := true
var _dirty := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(p: Dictionary) -> void:
	params = p
	_make()
	_pre_build()
	build()


## Optional illustrated header: {"scene", "title", "sub", "focus", "h", "plaque"}.
func hero_spec() -> Dictionary:
	return {}


func _pre_build() -> void:
	var h := hero_spec()
	if h.is_empty() or body == null:
		return
	Art.hero(body, str(h.get("scene", "lab")), str(h.get("title", "")), str(h.get("sub", "")), float(h.get("h", 260.0)), h.get("focus", Vector2(0.5, 0.5)), str(h.get("plaque", "")))


func _make() -> void:
	if scrolls:
		scroll = DragScroll.new()
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.get_v_scroll_bar().modulate = Color(1, 1, 1, 0)
		add_child(scroll)
		var m := MarginContainer.new()
		m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m.add_theme_constant_override("margin_left", 22)
		m.add_theme_constant_override("margin_right", 22)
		m.add_theme_constant_override("margin_top", 16)
		m.add_theme_constant_override("margin_bottom", 40)
		scroll.add_child(m)
		body = UI.vbox(16)
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m.add_child(body)
	else:
		body = UI.vbox(12)
		body.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(body)


func build() -> void:
	pass


func rebuild() -> void:
	if body == null:
		return
	var y := scroll.scroll_vertical if scroll != null else 0
	for ch in body.get_children():
		body.remove_child(ch)
		ch.queue_free()
	_pre_build()
	build()
	if scroll != null and y > 0:
		await get_tree().process_frame
		if is_instance_valid(scroll):
			scroll.scroll_vertical = y


func on_world_changed() -> void:
	if is_visible_in_tree():
		rebuild()
	else:
		_dirty = true


func on_shown() -> void:
	if _dirty:
		_dirty = false
		rebuild()


func page_title() -> String:
	return title_text


## Visual environment of this screen (background palette); defaults to the active tab.
func env() -> String:
	if params.has("env"):
		return str(params["env"])
	return {"home": "home", "lab": "lab", "products": "products", "company": "company", "finance": "finance"}.get(Router.tab, "home")
