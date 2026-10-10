class_name BasePanel
extends Control
## Ortak modal pencere: karartılmış arka plan, başlık, kapat düğmesi ve içerik alanı.
## Açıkken oyun zamanı durur.

signal closed

var frame: PanelContainer
var header: HBoxContainer
var title_label: Label
var body: VBoxContainer
var pause_time := true
var _pause_key := ""


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.theme()
	_pause_key = "panel_%d" % get_instance_id()


func setup_frame(title: String, w_frac: float = 0.92, h_frac: float = 0.9, close_text: String = "Kapat") -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.01, 0.04, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	frame = PanelContainer.new()
	frame.anchor_left = (1.0 - w_frac) * 0.5
	frame.anchor_right = 1.0 - (1.0 - w_frac) * 0.5
	frame.anchor_top = (1.0 - h_frac) * 0.5
	frame.anchor_bottom = 1.0 - (1.0 - h_frac) * 0.5
	add_child(frame)
	var v := UI.vbox(10)
	frame.add_child(v)
	header = UI.hbox(12)
	v.add_child(header)
	title_label = UI.title(title, 36)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	header.add_child(title_label)
	if close_text != "":
		var close := UI.button(close_text, close_panel, 54)
		close.custom_minimum_size.x = 132
		header.add_child(close)
	v.add_child(UI.sep_line())
	body = UI.vbox(10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	if pause_time:
		GameState.push_pause(_pause_key)
	AudioManager.play_ui("open")


func close_panel() -> void:
	GameState.pop_pause(_pause_key)
	AudioManager.play_ui("close")
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	GameState.pop_pause(_pause_key)
