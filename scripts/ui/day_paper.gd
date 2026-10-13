class_name DayPaper
extends Control
## End-of-day newspaper: real counts from the simulation + the day's three biggest stories.

signal next_day

var w: SimWorld
var paper: PaperPanel
var dim: ColorRect
var auto_t := -1.0
var next_btn: NoteButton
var summary: Dictionary


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_to_group("ui_blocker")
	dim = ColorRect.new()
	dim.color = Color(0.1, 0.07, 0.04, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	paper = PaperPanel.new()
	paper.set_style("newspaper")
	add_child(paper)


func show_day(world: SimWorld, sm: Dictionary) -> void:
	w = world
	summary = sm
	for c in paper.content.get_children():
		c.queue_free()
	var vs := get_viewport_rect().size
	paper.size = Vector2(vs.x - 36, vs.y - 120)
	paper.position = Vector2(18, 60)
	paper.pivot_offset = paper.size * 0.5
	var sc := Sheet.scroll()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	paper.content.add_child(sc)
	# masthead
	var mast := Control.new()
	mast.custom_minimum_size = Vector2(0, 118)
	mast.draw.connect(func():
		var ww := mast.size.x
		mast.draw_line(Vector2(0, 6), Vector2(ww, 6), UiKit.INK, 3.0)
		mast.draw_string(UiKit.font("slab"), Vector2(0, 62), Loc.t("paper.name"), HORIZONTAL_ALIGNMENT_CENTER, ww, 46, UiKit.INK)
		mast.draw_string(UiKit.font("type"), Vector2(0, 86), Loc.t("paper.tagline"), HORIZONTAL_ALIGNMENT_CENTER, ww, 16, Color(0.3, 0.3, 0.3))
		mast.draw_line(Vector2(0, 98), Vector2(ww, 98), UiKit.INK, 1.5)
		mast.draw_line(Vector2(0, 102), Vector2(ww, 102), UiKit.INK, 1.0)
		mast.draw_string(UiKit.font("type"), Vector2(4, 118), Loc.t("paper.day", {"day": sm["day"]}), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiKit.INK)
		mast.draw_string(UiKit.font("type"), Vector2(0, 118), "OFFICE EDITION", HORIZONTAL_ALIGNMENT_RIGHT, ww - 4, 16, UiKit.INK))
	v.add_child(mast)
	# headline
	var head := Sheet.label(Loc.t("ui.day", {"day": sm["day"]}) + " — " + Loc.t(sm["headline"]), 46, "slab", UiKit.RED)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	# numbers
	v.add_child(_rule(Loc.t("paper.stats")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var counts: Dictionary = sm.get("counts", {})
	var shown := 0
	for k in DayStats.ORDER:
		var c := int(counts.get(k, 0))
		if c <= 0 or k == "interventions":
			continue
		if shown >= 10:
			break
		grid.add_child(_stat(c, Loc.t("stat." + k)))
		shown += 1
	grid.add_child(_stat(int(counts.get("interventions", 0)), Loc.t("stat.interventions")))
	v.add_child(grid)
	# stories
	v.add_child(_rule(Loc.t("ui.stories")))
	var stories: Array = sm.get("stories", [])
	if stories.is_empty():
		v.add_child(Sheet.label(Loc.t("paper.no_stories"), 22, "type"))
	for st in stories:
		v.add_child(_story(st))
	# storylines: what's still unresolved (and what wrapped up today)
	var arcs: Array = sm.get("arcs", [])
	if not arcs.is_empty():
		v.add_child(_rule(Loc.t("ui.storylines").to_upper()))
		for a in arcs.slice(0, 4):
			v.add_child(_arc_line(a))
	# next day
	next_btn = NoteButton.make(Loc.t("ui.next_day"), "", "sticky", UiKit.sticky("yellow"), Vector2(260, 84))
	next_btn.font_size = 28
	next_btn.font_kind = "marker"
	next_btn.tilt = -2.0
	next_btn.pressed.connect(_go)
	var cb := CenterContainer.new()
	cb.custom_minimum_size = Vector2(0, 110)
	cb.add_child(next_btn)
	v.add_child(cb)
	auto_t = 9.0 if Game.settings.get("auto_next", false) else -1.0
	visible = true
	paper.rotation_degrees = -8.0
	paper.scale = Vector2(0.6, 0.6)
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(paper, "rotation_degrees", -1.2, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	Audio.play("paper_day")


func _rule(t: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 40)
	c.draw.connect(func():
		c.draw_line(Vector2(0, 8), Vector2(c.size.x, 8), UiKit.INK, 1.5)
		c.draw_string(UiKit.font("slab"), Vector2(0, 34), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UiKit.INK))
	return c


func _stat(n: int, t: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(300, 40)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.draw.connect(func():
		c.draw_string(UiKit.font("slab"), Vector2(0, 30), str(n), HORIZONTAL_ALIGNMENT_RIGHT, 52, 28, UiKit.RED)
		c.draw_string(UiKit.font("type"), Vector2(62, 28), t, HORIZONTAL_ALIGNMENT_LEFT, c.size.x - 64, 18, UiKit.INK))
	return c


func _story(st: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var actors: Array = st.get("actors", [])
	if not actors.is_empty() and w.npc(str(actors[0])) != null:
		var p := Portrait.make(w, str(actors[0]), Vector2(96, 112), true, 1.0)
		p.pivot_offset = Vector2(48, 56)
		p.rotation_degrees = randf_range(-4, 4)
		h.add_child(p)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(Sheet.label(C.fmt(st.get("minute", 0)), 16, "type", Color(0.4, 0.4, 0.4)))
	v.add_child(Sheet.label(st.get("text", ""), 22, "type", UiKit.INK))
	h.add_child(v)
	return h


func _arc_line(a: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var done: bool = a.get("done", false)
	var kicker := Loc.t("paper.concluded") if done else Loc.t("paper.continued")
	var t := Sheet.label("%s — %s" % [Loc.t("arc." + str(a["arc"])), kicker], 22, "slab", UiKit.RED if not done else UiKit.INK)
	v.add_child(t)
	if str(a.get("beat", "")) != "":
		v.add_child(Sheet.label(str(a["beat"]), 19, "type", Color(0.25, 0.25, 0.28)))
	return v


func _process(delta: float) -> void:
	if not visible or auto_t < 0.0:
		return
	auto_t -= delta
	if next_btn:
		next_btn.text = Loc.t("ui.next_day_in", {"n": int(ceil(auto_t))})
		next_btn.queue_redraw()
	if auto_t <= 0.0:
		auto_t = -1.0
		_go()


func _go() -> void:
	if not visible:
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		visible = false
		next_day.emit())
