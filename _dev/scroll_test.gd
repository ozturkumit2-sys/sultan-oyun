extends Node
## Dokunmatik sürükleme kaydırma testi (dükkân ve tarif kitabı).

func _ready() -> void:
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	await get_tree().create_timer(0.3).timeout
	SaveManager.data = SaveManager.default_data()
	SaveManager.data["profile"]["created"] = true
	SaveManager.data["coins"] = 5000
	GameManager.goto("shop", {}, false)
	await get_tree().create_timer(1.2).timeout
	var ds: DragScroll = _find(get_tree().root)
	print("scroll found: ", ds != null)
	var r := ds.get_global_rect()
	var c := r.get_center()
	print("max before: ", ds.get_v_scroll_bar().max_value, " page ", ds.get_v_scroll_bar().page)
	# 0) önce dokunma testi
	var card0 := _first_card(ds)
	var cp0 := card0.get_global_rect().get_center()
	print("card0 ", cp0, " rect ", r)
	await _move(cp0)
	await _press(cp0, true)
	await _press(cp0, false)
	await get_tree().create_timer(0.4).timeout
	print("tap-first modal=", _count_modal(get_tree().root))
	for m in _modals(get_tree().root):
		m.queue_free()
	await get_tree().create_timer(0.3).timeout
	# 1) sürükle: kaydırmalı, satın alma penceresi açılmamalı
	await _press(c, true)
	for i in 12:
		await _move(c + Vector2(0, -25 * (i + 1)))
	await _press(c + Vector2(0, -300), false)
	await get_tree().create_timer(0.6).timeout
	print("after drag scroll_vertical=", ds.scroll_vertical, " modal=", _count_modal(get_tree().root))
	# 2) dokun: kart üzerinde bas-bırak -> satın alma penceresi açılmalı
	ds.set("_vel", 0.0)
	ds.set_process(false)
	await get_tree().create_timer(0.1).timeout
	ds.scroll_vertical = 0
	await get_tree().create_timer(0.3).timeout
	var card := _first_card(ds)
	var cp := card.get_global_rect().get_center()
	card.tapped.connect(func(): print("TAPPED signal"))
	print("scroll now ", ds.scroll_vertical, " cp ", cp)
	await _move(cp)
	print("hovered before: ", get_viewport().gui_get_hovered_control())
	await _press(cp, true)
	print("hovered after press: ", get_viewport().gui_get_hovered_control(), " card down=", card.get("_down"))
	await _press(cp, false)
	await get_tree().create_timer(0.4).timeout
	print("after tap modal=", _count_modal(get_tree().root))
	get_tree().quit()


func _press(p: Vector2, down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = down
	ev.position = p
	ev.global_position = p
	if down:
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(ev, true)
	await get_tree().process_frame


func _move(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(ev, true)
	await get_tree().process_frame


func _find(n: Node) -> DragScroll:
	if n is DragScroll:
		return n
	for ch in n.get_children():
		var r := _find(ch)
		if r != null:
			return r
	return null


func _first_card(n: Node) -> Control:
	if n is TapCard and not (n as TapCard).disabled:
		return n
	for ch in n.get_children():
		var r := _first_card(ch)
		if r != null:
			return r
	return null


func _count_modal(n: Node) -> int:
	var k := 1 if n is Modal else 0
	for ch in n.get_children():
		k += _count_modal(ch)
	return k


func _modals(n: Node) -> Array:
	var out: Array = []
	if n is Modal:
		out.append(n)
	for ch in n.get_children():
		out.append_array(_modals(ch))
	return out
