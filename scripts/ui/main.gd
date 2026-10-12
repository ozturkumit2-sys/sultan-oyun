extends Control
## Root UI: background, top bar (title, date, cash, inbox, next week), screen host, bottom tab bar,
## overlay for modals/toasts. Handles safe areas and Android back.

var top_bar: PanelContainer
var nav_bar: PanelContainer
var host: Control
var ov: Control
var title_lbl: Label
var sub_lbl: Label
var back_btn: Button
var inbox_ico: Ico
var tab_btns := {}
var backdrop: Backdrop
var nb_btn: Button
var _safe := Vector4.ZERO


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_tree().set_quit_on_go_back(false)
	_compute_safe()
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	backdrop = Backdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var col := UI.vbox(0)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	_build_top(col)
	host = Control.new()
	host.name = "Host"
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.clip_contents = true
	col.add_child(host)
	_build_nav(col)
	ov = Control.new()
	ov.name = "Overlay"
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ov)
	Router.main = self
	G.changed.connect(func(): Router.world_changed())
	G.toast.connect(func(t, k): Router.toast(t, k))
	Router.menu()


func _compute_safe() -> void:
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var vs := get_viewport_rect().size
	if win.x <= 0 or win.y <= 0:
		return
	var sc := vs.y / float(win.y)
	_safe = Vector4(0, maxf(0.0, safe.position.y) * sc, 0, maxf(0.0, float(win.y - safe.end.y)) * sc)
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		_safe = Vector4.ZERO


func safe_top() -> float:
	return _safe.y


func safe_bottom() -> float:
	return _safe.w


func _build_top(col: VBoxContainer) -> void:
	top_bar = PanelContainer.new()
	var st := UI.sb(Color(1, 0.985, 0.965, 0.9), 0, UI.LINE, 0, 14)
	st.border_width_bottom = 1
	UI.shadowed(st, 6, 0.8)
	st.content_margin_top = 10 + safe_top()
	st.content_margin_bottom = 10
	top_bar.add_theme_stylebox_override("panel", st)
	var h := UI.hbox(10)
	top_bar.add_child(h)
	back_btn = UI.btn("", func(): Router.back(), "ghost", 24, 70)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back_btn.custom_minimum_size = Vector2(62, 70)
	var bi := UI.icon("back", 34, UI.BURGUNDY)
	bi.position = Vector2(14, 18)
	back_btn.add_child(bi)
	h.add_child(back_btn)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl = UI.title("Perfume Empire", 30)
	title_lbl.clip_text = true
	title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(title_lbl)
	sub_lbl = UI.lbl("", 19, UI.MUTED, "medium")
	sub_lbl.clip_text = true
	tv.add_child(sub_lbl)
	h.add_child(tv)
	var ib := UI.btn("", func(): Router.go("inbox"), "ghost", 20, 70)
	ib.size_flags_horizontal = Control.SIZE_SHRINK_END
	ib.custom_minimum_size = Vector2(66, 70)
	inbox_ico = UI.icon("mail", 40, UI.BURGUNDY)
	inbox_ico.position = Vector2(13, 15)
	ib.add_child(inbox_ico)
	h.add_child(ib)
	var nb := UI.btn("Next week ▸", func(): Router.next_week(), "primary", 21, 70)
	nb_btn = nb
	nb.custom_minimum_size.x = 176
	nb.size_flags_horizontal = Control.SIZE_SHRINK_END
	h.add_child(nb)
	col.add_child(top_bar)


func _build_nav(col: VBoxContainer) -> void:
	nav_bar = PanelContainer.new()
	var st := UI.sb(Color(1, 0.985, 0.965, 0.96), 0, UI.LINE, 0, 6)
	st.border_width_top = 1
	st.border_width_bottom = 0
	st.shadow_color = Color(UI.SHADOW, 0.12)
	st.shadow_size = 12
	st.shadow_offset = Vector2(0, -2)
	st.content_margin_bottom = 6 + safe_bottom()
	nav_bar.add_theme_stylebox_override("panel", st)
	var h := UI.hbox(0)
	nav_bar.add_child(h)
	for t in [["home", "Home", "home"], ["lab", "Lab", "lab"], ["products", "Products", "bottle"], ["company", "Company", "company"], ["finance", "Finance", "finance"]]:
		var id: String = t[0]
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 96)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pill := Panel.new()
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_theme_stylebox_override("panel", UI.sb(Color("#f4d8db"), 22, Color(0, 0, 0, 0), 0, 0))
		pill.set_anchors_preset(Control.PRESET_FULL_RECT)
		pill.offset_left = 10
		pill.offset_right = -10
		pill.offset_top = 6
		pill.offset_bottom = -6
		b.add_child(pill)
		var v := UI.vbox(2)
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := UI.icon(t[2], 40, UI.MUTED)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var l := UI.lbl(t[1], 17, UI.MUTED, "semi", HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(l)
		b.add_child(v)
		b.pressed.connect(func():
			Snd.click()
			Router.go_tab(id))
		h.add_child(b)
		tab_btns[id] = [ic, l, pill]
	col.add_child(nav_bar)


func show_bars(on: bool) -> void:
	top_bar.visible = on
	nav_bar.visible = on


func update_bars() -> void:
	if not Router.in_game or not G.has_game():
		return
	var cur := Router.current()
	title_lbl.text = cur.page_title() if cur != null and cur.page_title() != "" else G.pc().get("name", "")
	var cash := FinanceEngine.cash_of(G.pc())
	sub_lbl.text = "%s  ·  %s" % [G.date_str(), G.money(cash)]
	sub_lbl.add_theme_color_override("font_color", UI.MUTED if cash >= 0.0 else UI.RED)
	back_btn.visible = Router.stack.size() > 1
	inbox_ico.badge = G.inbox_open().size()
	for id in tab_btns:
		var on: bool = id == Router.tab
		(tab_btns[id][0] as Ico).color = UI.BURGUNDY if on else UI.MUTED
		(tab_btns[id][1] as Label).add_theme_color_override("font_color", UI.BURGUNDY if on else UI.MUTED)
		(tab_btns[id][2] as Panel).visible = on
	backdrop.set_env(cur.env() if cur != null else "home")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if what == NOTIFICATION_WM_CLOSE_REQUEST and OS.get_name() != "Android":
			if G.has_game() and Router.in_game:
				Save.save_game("auto")
			get_tree().quit()
			return
		Router.back()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if G.has_game() and Router.in_game and not G.busy:
			Save.save_game("auto")
