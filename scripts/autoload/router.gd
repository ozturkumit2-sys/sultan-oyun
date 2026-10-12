extends Node
## Screen navigation (tab roots + push/pop stack), Android back handling, modal dialogs, toasts,
## and the "Next week" flow.

const TABS := {"home": "dashboard", "lab": "lab_hub", "products": "products_hub", "company": "company_hub", "finance": "finance_hub"}

var main: Control
var stack: Array = []
var tab := "home"
var modals: Array = []
var in_game := false


func host() -> Control:
	return main.host


func overlay() -> Control:
	return main.ov


func current() -> Screen:
	return stack[stack.size() - 1] if not stack.is_empty() else null


func _make(name: String, params: Dictionary) -> Screen:
	var scr: Script = load("res://scripts/ui/screens/%s.gd" % name)
	var s: Screen = scr.new()
	s.name = name
	host().add_child(s)
	s.setup(params)
	return s


func _clear() -> void:
	for s in stack:
		if is_instance_valid(s):
			s.queue_free()
	stack.clear()


func menu() -> void:
	in_game = false
	close_all_modals()
	_clear()
	main.show_bars(false)
	stack.append(_make("main_menu", {}))


func start_game() -> void:
	in_game = true
	main.show_bars(true)
	go_tab("home")
	Snd.music(true)


func go_tab(t: String) -> void:
	if tab != t and in_game:
		Snd.play("page", -10.0)
	tab = t
	close_all_modals()
	_clear()
	stack.append(_make(TABS[t], {}))
	main.update_bars()


func go(name: String, params := {}) -> Screen:
	if not stack.is_empty():
		current().visible = false
	var s := _make(name, params)
	stack.append(s)
	_fade(s)
	main.update_bars()
	return s


func replace(name: String, params := {}) -> Screen:
	if not stack.is_empty():
		var top: Screen = stack.pop_back()
		top.queue_free()
	return go(name, params)


func back() -> void:
	if not modals.is_empty():
		close_modal()
		return
	if stack.size() > 1:
		var top: Screen = stack.pop_back()
		top.queue_free()
		var cur := current()
		cur.visible = true
		cur.on_shown()
		_fade(cur)
		main.update_bars()
		return
	if in_game and tab != "home":
		go_tab("home")
		return
	if in_game:
		confirm("Leave the game?", "Your progress is saved automatically each week. Save now and return to the main menu?", func():
			Save.save_game("auto")
			menu(), "Save & exit")
	else:
		get_tree().quit()


func _fade(c: Control) -> void:
	c.modulate = Color(1, 1, 1, 0)
	var tw := c.create_tween()
	tw.tween_property(c, "modulate", Color.WHITE, 0.16)


func refresh() -> void:
	var cur := current()
	if cur != null:
		cur.rebuild()
	main.update_bars()


func world_changed() -> void:
	for s in stack:
		if is_instance_valid(s):
			(s as Screen).on_world_changed()
	if main != null:
		main.update_bars()


# ---------------------------------------------------------------- modals
func modal(title_text: String, builder: Callable, buttons: Array = [], sheet := true) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_to_group("ui_blocker")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var panel := PanelContainer.new()
	var st := UI.sb(UI.BG2, 26, UI.LINE, 1, 24)
	st.corner_radius_bottom_left = 0 if sheet else 26
	st.corner_radius_bottom_right = 0 if sheet else 26
	st.content_margin_bottom = 24 + main.safe_bottom() if sheet else 24
	panel.add_theme_stylebox_override("panel", st)
	root.add_child(panel)
	var v := UI.vbox(14)
	panel.add_child(v)
	var head := UI.hbox(10)
	var t := UI.title(title_text, 32)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var x := UI.btn("✕", func(): close_modal(), "ghost", 28, 60)
	x.custom_minimum_size.x = 60
	head.add_child(x)
	v.add_child(head)
	var sc := DragScroll.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.get_v_scroll_bar().modulate = Color(1, 1, 1, 0)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var content := UI.vbox(14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	v.add_child(sc)
	builder.call(content)
	if not buttons.is_empty():
		var bh := UI.hbox(12)
		for b in buttons:
			var cb: Callable = b[1]
			var keep_open: bool = b.size() > 3 and b[3]
			var bt := UI.btn(b[0], func():
				if not keep_open:
					close_modal()
				if cb.is_valid():
					cb.call(), b[2] if b.size() > 2 else "primary", 24)
			bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bh.add_child(bt)
		v.add_child(bh)
	overlay().add_child(root)
	modals.append(root)
	var vs := main.get_viewport_rect().size
	panel.size = Vector2(vs.x if sheet else vs.x - 40.0, vs.y * 0.86)
	panel.position = Vector2(0 if sheet else 20, vs.y)
	main.get_tree().process_frame.connect(func(): _size_modal(root, panel, content, sheet, not buttons.is_empty()), CONNECT_ONE_SHOT)
	return root


func _size_modal(root: Control, panel: PanelContainer, content: Control, sheet: bool, has_buttons: bool) -> void:
	if not is_instance_valid(root):
		return
	var vs := main.get_viewport_rect().size
	var want = content.get_combined_minimum_size().y + 120.0 + (92.0 if has_buttons else 0.0) + (main.safe_bottom() if sheet else 0.0)
	var h := clampf(want, 260.0, vs.y * 0.86)
	panel.size = Vector2(panel.size.x, h)
	if sheet:
		var tw := panel.create_tween()
		tw.tween_property(panel, "position:y", vs.y - h, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		panel.position.y = (vs.y - h) * 0.5


func close_modal() -> void:
	if modals.is_empty():
		return
	var m: Control = modals.pop_back()
	if is_instance_valid(m):
		m.queue_free()


func close_all_modals() -> void:
	while not modals.is_empty():
		close_modal()


func confirm(title_text: String, text: String, ok: Callable, ok_text := "Confirm", danger := false) -> void:
	modal(title_text, func(v: VBoxContainer): v.add_child(UI.para(text, 24, UI.TEXT)),
		[["Cancel", Callable(), "secondary"], [ok_text, ok, "danger" if danger else "primary"]])


func info(title_text: String, text: String) -> void:
	modal(title_text, func(v: VBoxContainer): v.add_child(UI.para(text, 24, UI.TEXT)), [["OK", Callable(), "primary"]])


## options: [[label, value, subtitle?]]
func pick(title_text: String, options: Array, cb: Callable) -> void:
	modal(title_text, func(v: VBoxContainer):
		for o in options:
			var val: Variant = o[1]
			UI.row_card(v, str(o[0]), str(o[2]) if o.size() > 2 else "", "", func():
				close_modal()
				cb.call(val)), [])


func number(title_text: String, value: float, minv: float, maxv: float, step: float, cb: Callable, fmt: Callable = Callable(), note := "") -> void:
	var state := {"v": value}
	modal(title_text, func(v: VBoxContainer):
		var big := UI.title(fmt.call(value) if fmt.is_valid() else str(value), 44, UI.GOLD2)
		big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(big)
		var row := UI.hbox(10)
		var minus := UI.btn("−", Callable(), "dark", 30, 64)
		minus.custom_minimum_size.x = 72
		var plus := UI.btn("+", Callable(), "dark", 30, 64)
		plus.custom_minimum_size.x = 72
		var sl := UI.slider(minv, maxv, step, value, func(x):
			state["v"] = x
			big.text = fmt.call(x) if fmt.is_valid() else str(x))
		minus.pressed.connect(func(): sl.value = sl.value - step)
		plus.pressed.connect(func(): sl.value = sl.value + step)
		row.add_child(minus)
		row.add_child(sl)
		row.add_child(plus)
		v.add_child(row)
		if note != "":
			v.add_child(UI.para(note, 20)),
		[["Cancel", Callable(), "secondary"], ["Apply", func(): cb.call(state["v"]), "primary"]])


func text_input(title_text: String, default: String, cb: Callable, placeholder := "") -> void:
	var holder := {}
	modal(title_text, func(v: VBoxContainer):
		var e := UI.line_edit(default, placeholder)
		e.max_length = 32
		holder["e"] = e
		v.add_child(e)
		e.call_deferred("grab_focus"),
		[["Cancel", Callable(), "secondary"], ["OK", func(): cb.call((holder["e"] as LineEdit).text.strip_edges()), "primary"]], false)


func toast(text: String, kind := "info") -> void:
	if main == null:
		return
	var p := PanelContainer.new()
	var col := UI.GOLD
	match kind:
		"bad", "error":
			col = UI.RED
			Snd.play("error")
		"good":
			col = UI.GREEN
			Snd.play("success", -8.0)
	p.add_theme_stylebox_override("panel", UI.sb(Color(0.08, 0.07, 0.09, 0.96), 16, col, 2, 18))
	var vs := main.get_viewport_rect().size
	var l := UI.lbl(text, 22, UI.TEXT, "medium", HORIZONTAL_ALIGNMENT_LEFT, true)
	l.custom_minimum_size = Vector2(vs.x - 100, 0)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay().add_child(p)
	p.position = Vector2(30, main.safe_top() + 120)
	p.modulate = Color(1, 1, 1, 0)
	var tw := p.create_tween()
	tw.tween_property(p, "modulate", Color.WHITE, 0.15)
	tw.tween_interval(2.6)
	tw.tween_property(p, "modulate", Color(1, 1, 1, 0), 0.4)
	tw.tween_callback(p.queue_free)


# ---------------------------------------------------------------- week flow
func next_week() -> void:
	if G.busy or not G.has_game():
		return
	G.busy = true
	var cover := ColorRect.new()
	cover.color = Color(0, 0, 0, 0.55)
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	var l := UI.title("Closing the week…", 34, UI.GOLD2)
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cover.add_child(l)
	overlay().add_child(cover)
	l.position = Vector2(main.get_viewport_rect().size.x * 0.5 - 200, main.get_viewport_rect().size.y * 0.45)
	l.size = Vector2(400, 60)
	await main.get_tree().process_frame
	await main.get_tree().process_frame
	var rep := Sim.advance()
	if G.settings.get("autosave", true):
		Save.save_game("auto")
	cover.queue_free()
	G.busy = false
	Snd.play("week")
	if float(rep.get("fin", {}).get("net", 0.0)) > 0.0:
		Snd.play("coin", -10.0)
	world_changed()
	G.week_done.emit(rep)
	show_report(rep)


func show_report(rep: Dictionary) -> void:
	var fin: Dictionary = rep.get("fin", {})
	modal("Week %d results" % G.week_of_year(int(rep["w"])), func(v: VBoxContainer):
		var g := UI.grid(2, 10)
		var rev := float(fin.get("revenue", 0.0))
		var net := float(fin.get("net", 0.0))
		g.add_child(UI.stat("Revenue", G.money(rev), "", UI.CREAM))
		g.add_child(UI.stat("Net result", G.money(net), "", UI.GREEN if net >= 0.0 else UI.RED))
		g.add_child(UI.stat("Units sold", G.group_int(int(fin.get("u", 0))), "", UI.CREAM))
		var cd := float(rep.get("cash_delta", 0.0))
		g.add_child(UI.stat("Cash", G.money(float(rep.get("cash", 0.0))), ("+" if cd >= 0.0 else "") + G.money(cd), UI.CREAM, UI.GREEN if cd >= 0.0 else UI.RED))
		v.add_child(g)
		if not rep["launches"].is_empty():
			v.add_child(UI.pill("Launched: " + ", ".join(rep["launches"]), UI.GREEN, 20))
		var tops: Array = rep.get("top", [])
		if not tops.is_empty():
			UI.section(v, "Products this week")
			for t in tops.slice(0, 5):
				var pid: String = t[3]
				UI.row_card(v, t[0], "%s units · %s" % [G.group_int(int(t[1])), G.money(float(t[2]))], "", func():
					close_modal()
					go("product_detail", {"id": pid}))
		if not rep["stockouts"].is_empty():
			var w := UI.card(v, "warn")
			w.add_child(UI.para("Out of stock: %s. Customers walked away — order production!" % ", ".join(rep["stockouts"]), 21, UI.TEXT))
		if not rep["events"].is_empty():
			UI.section(v, "Events")
			for e in rep["events"].slice(0, 6):
				v.add_child(UI.para("• " + str(e), 21, UI.TEXT))
		var open := G.inbox_open().size()
		if open > 0:
			v.add_child(UI.btn("Open inbox (%d)" % open, func():
				close_modal()
				go("inbox"), "secondary", 22)),
		[["Continue", Callable(), "primary"]])
