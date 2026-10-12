class_name EssenceShelf
extends GradPanel
## The perfumer's organ under the bench: essence vials you drag into the bottle.
## Drag up/onto the bottle to add a dose; a horizontal swipe scrolls the shelf; a tap shows the material.

var stage: LabStage
var on_drop: Callable          # func(id) -> float (percentage actually added; 0 when the bottle is full)
var filter := "all"
var _row: HBoxContainer
var _scroll: DragScroll
var _items: Array = []         # [{id, node}]
var _press_id := ""
var _press_pos := Vector2.ZERO
var _dragging := false
var _ghost: Control
var _hint: Label


func _init() -> void:
	top = Color("#fbf3ea")
	bottom = Color("#f1e2d2")
	border = Color(UI.GOLD, 0.35)
	set_pad(12)


func _ready() -> void:
	super._ready()
	var v := UI.vbox(8)
	add_child(v)
	var h := UI.hbox(8)
	h.add_child(UI.icon_bubble("bottle", UI.PLUM, 40))
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.lbl("Essence shelf", 21, UI.CREAM, "semi"))
	_hint = UI.lbl("Drag an essence into the bottle · tap for details", 15, UI.MUTED, "medium")
	tv.add_child(_hint)
	h.add_child(tv)
	v.add_child(h)
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	for o in [["All", "all"], ["Top", "top"], ["Heart", "heart"], ["Base", "base"], ["Naturals", "nat"], ["Solvents", "aux"]]:
		var key: String = o[1]
		f.add_child(UI.chip(str(o[0]), key == filter, func():
			filter = key
			_fill_row(), 17))
	v.add_child(f)
	_scroll = DragScroll.new()
	_scroll.horizontal = true
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.custom_minimum_size = Vector2(0, 150)
	_row = UI.hbox(8)
	_scroll.add_child(_row)
	v.add_child(_scroll)
	_fill_row()


func _exit_tree() -> void:
	if _press_id != "" or _dragging:
		DragScroll.locked = false
	_drop_ghost()


func _fill_row() -> void:
	# refresh chip states
	var chips: HFlowContainer = null
	for ch in get_child(0).get_children():
		if ch is HFlowContainer:
			chips = ch
	if chips != null:
		var keys := ["all", "top", "heart", "base", "nat", "aux"]
		for i in chips.get_child_count():
			UI.style_btn(chips.get_child(i) as Button, "chip_on" if keys[i] == filter else "chip", 17)
	for ch in _row.get_children():
		ch.queue_free()
	_items.clear()
	for id in DB.ing_order:
		if not G.ing_available(G.pid(), id):
			continue
		var rec := DB.ing(id)
		var aromatic: bool = rec.get("role", "") == "aromatic"
		var ok := true
		match filter:
			"top", "heart", "base":
				ok = aromatic and rec.get("note", "") == filter
			"nat":
				ok = rec.get("nat", false)
			"aux":
				ok = not aromatic
		if not ok:
			continue
		var node := _vial(id)
		_row.add_child(node)
		_items.append({"id": id, "node": node})
	_scroll.scroll_horizontal = 0


func _vial(id: String) -> Control:
	var rec := DB.ing(id)
	var tops := FormulaEngine.top_dims(rec["vec"], 1)
	var col := UI.dim_color(tops[0]) if not tops.is_empty() else Color("#9fcfe0")
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.shadowed(UI.sb(col.lerp(Color("#fffdf9"), 0.78), 18, Color(col.darkened(0.25), 0.35), 1, 6), 5))
	p.custom_minimum_size = Vector2(104, 140)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UI.vbox(0)
	p.add_child(v)
	v.add_child(Art.ing_icon(id, 92))
	var l := UI.lbl(FormulaEngine.short_name(rec), 13, UI.CREAM, "semi", HORIZONTAL_ALIGNMENT_CENTER)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.custom_minimum_size.x = 92
	v.add_child(l)
	var role: String = rec.get("note", "") if rec.get("role", "") == "aromatic" else "aux"
	v.add_child(UI.lbl(role.capitalize(), 12, UI.MUTED, "medium", HORIZONTAL_ALIGNMENT_CENTER))
	return p


func _item_at(gpos: Vector2) -> String:
	if not _scroll.get_global_rect().has_point(gpos):
		return ""
	for it in _items:
		var n: Control = it["node"]
		if is_instance_valid(n) and n.get_global_rect().has_point(gpos):
			return it["id"]
	return ""


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_press_id = _item_at(mb.position)
			_press_pos = mb.position
			_dragging = false
			if _press_id != "":
				DragScroll.locked = true
		elif _press_id != "":
			var id := _press_id
			_press_id = ""
			DragScroll.locked = false
			if _dragging:
				_dragging = false
				_end_drag(id, mb.position)
				get_viewport().set_input_as_handled()
			elif mb.position.distance_to(_press_pos) < 12.0:
				IngredientInfo.show(id)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _press_id != "":
		var mm := event as InputEventMouseMotion
		if (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			_press_id = ""
			DragScroll.locked = false
			_drop_ghost()
			return
		var d := mm.position - _press_pos
		if not _dragging:
			if absf(d.x) > 14.0 and absf(d.x) > absf(d.y) * 1.2:
				# a sideways swipe scrolls the shelf instead
				_press_id = ""
				DragScroll.locked = false
				return
			if d.length() > 10.0:
				_dragging = true
				_start_drag(_press_id, mm.position)
		if _dragging:
			_move_ghost(mm.position)
			get_viewport().set_input_as_handled()


func _start_drag(id: String, gpos: Vector2) -> void:
	_drop_ghost()
	var g := Control.new()
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.size = Vector2(112, 112)
	var halo := Glow.new()
	halo.color = Color("#ffffff")
	halo.strength = 2.4
	halo.size = Vector2(112, 112)
	g.add_child(halo)
	var ic := Art.ing_icon(id, 112)
	ic.size = Vector2(112, 112)
	g.add_child(ic)
	g.z_index = 50
	Router.overlay().add_child(g)
	_ghost = g
	_move_ghost(gpos)
	Snd.play("page", -8.0)


func _move_ghost(gpos: Vector2) -> void:
	if _ghost == null or not is_instance_valid(_ghost):
		return
	_ghost.position = gpos - Router.overlay().global_position - Vector2(56, 86)
	if stage != null:
		stage.hover(stage.drop_rect().has_point(gpos))


func _drop_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
	if stage != null:
		stage.hover(false)


func _end_drag(id: String, gpos: Vector2) -> void:
	var over := stage != null and stage.drop_rect().has_point(gpos)
	if not over:
		# float back to the shelf
		if _ghost != null and is_instance_valid(_ghost):
			var g := _ghost
			_ghost = null
			var tw := g.create_tween()
			tw.tween_property(g, "modulate:a", 0.0, 0.25)
			tw.tween_callback(g.queue_free)
		if stage != null:
			stage.hover(false)
		return
	_drop_ghost()
	var added: float = on_drop.call(id) if on_drop.is_valid() else 0.0
	if added > 0.0:
		stage.pour_from(id, gpos)
		Snd.play("success", -12.0)
	else:
		stage.bottle.shake()
		Router.toast("The bottle is full (100%). Lower another material first.", "bad")
