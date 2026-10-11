class_name Modal
extends Control
## Ekranı karartan açılır pencere. Kullanım: var m := UIKit.modal(self, "Başlık", "Metin", [["Tamam", "ok", UIKit.GREEN]])
## var secim = await m.closed

signal closed(choice: String)

var cancel_choice := ""
var panel: PanelContainer
var content: VBoxContainer
var _closing := false


func _init() -> void:
	add_to_group("ui_blocker")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 80
	add_to_group("modal")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.06, 0.16, 0.62))


func build(title_text: String, body: String, buttons: Array, extra: Control = null, width := 600.0) -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel = UIKit.panel(UIKit.CREAM, 34, UIKit.INK, 5, 26)
	panel.custom_minimum_size = Vector2(minf(width, GameManager.screen_size.x - 36), 0)
	center.add_child(panel)
	content = UIKit.vbox(16)
	panel.add_child(content)
	if title_text != "":
		var t := UIKit.title(title_text, 42, Color.WHITE, UIKit.INK, 12)
		t.autowrap_mode = UIKit.wrap_mode()
		t.custom_minimum_size.x = 300
		content.add_child(t)
	if body != "":
		var b := UIKit.wrap_label(body, 26, UIKit.INK, false)
		content.add_child(b)
	if extra != null:
		content.add_child(extra)
	if not buttons.is_empty():
		var row: BoxContainer = UIKit.hbox(14) if buttons.size() <= 2 else UIKit.vbox(12)
		if row is HBoxContainer:
			row.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_child(row)
		for bd in buttons:
			var btn := UIKit.button(bd[0], bd[2] if bd.size() > 2 else UIKit.ORANGE, Vector2(0, 84), 28)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var choice: String = bd[1]
			btn.pressed.connect(func(): close(choice))
			row.add_child(btn)
			if choice == "cancel" or choice == "no" or choice == "close":
				cancel_choice = choice
	modulate.a = 0.0
	panel.pivot_offset = Vector2(300, 200)
	panel.scale = Vector2(0.8, 0.8)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioManager.sfx("pop", 1.1, -4.0)
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5


func close(choice: String) -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	tw.tween_callback(func():
		closed.emit(choice)
		queue_free())


func on_back() -> void:
	if cancel_choice != "":
		close(cancel_choice)
