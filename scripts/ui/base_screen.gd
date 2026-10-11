class_name BaseScreen
extends Control
## Tüm menü ekranları için ortak temel: arka plan, güvenli alan kenar boşlukları, başlık çubuğu, para rozeti.

var backdrop: Backdrop
var margin: MarginContainer
var root_v: VBoxContainer
var header: HBoxContainer
var _coin_label: Label


func setup_screen(bg_kind := "sunburst", top := Color("#ffb35c"), bottom := Color("#ff7a3d")) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop = Backdrop.new()
	backdrop.kind = bg_kind
	backdrop.c1 = top
	backdrop.c2 = bottom
	add_child(backdrop)
	margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14 + int(GameManager.safe_top()))
	margin.add_theme_constant_override("margin_bottom", 16 + int(GameManager.safe_bottom()))
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	root_v = UIKit.vbox(14)
	root_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root_v)


func make_header(title_text: String, back := true, coins := true) -> HBoxContainer:
	header = UIKit.hbox(12)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	if back:
		var b := UIKit.icon_button("back", UIKit.CREAM, 78)
		b.pressed.connect(func(): on_back())
		header.add_child(b)
	var t := UIKit.title(title_text, 44)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(t)
	if coins:
		header.add_child(coin_badge())
	elif back:
		header.add_child(UIKit.spacer(0, 78))
	root_v.add_child(header)
	return header


func coin_badge() -> PanelContainer:
	var p := PanelContainer.new()
	var s := UIKit.sb(Color("#3b2417"), 30, Color("#3b2417"), 0, 0, 12)
	s.bg_color = Color(0.23, 0.14, 0.09, 0.82)
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", s)
	var h := UIKit.hbox(6)
	h.add_child(UIKit.icon("coin", 40))
	_coin_label = UIKit.label(UIKit.coin_text(ProgressionManager.coins()), 28, Color("#ffe17a"))
	h.add_child(_coin_label)
	p.add_child(h)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ProgressionManager.coins_changed.is_connected(_on_coins):
		ProgressionManager.coins_changed.connect(_on_coins)
	return p


func _on_coins(v: int) -> void:
	if is_instance_valid(_coin_label):
		_coin_label.text = UIKit.coin_text(v)
		var tw := _coin_label.create_tween()
		_coin_label.pivot_offset = _coin_label.size * 0.5
		tw.tween_property(_coin_label, "scale", Vector2(1.25, 1.25), 0.1)
		tw.tween_property(_coin_label, "scale", Vector2.ONE, 0.2)


func _exit_tree() -> void:
	if ProgressionManager.coins_changed.is_connected(_on_coins):
		ProgressionManager.coins_changed.disconnect(_on_coins)


func on_back() -> bool:
	GameManager.go_back()
	return true
