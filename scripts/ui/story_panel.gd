class_name StoryPanel
extends BasePanel
## Kısa anlatı penceresi (gece sahnesi, zaman atlama özeti vb.): başlık, metin ve "Devam".

var _after: Callable


func open(title: String, text: String, after: Callable = Callable(), w: float = 0.72, h: float = 0.66) -> void:
	_after = after
	setup_frame(title, w, h, "")
	var sc := UI.scroll()
	body.add_child(sc)
	var r := UI.rich(text, 23)
	sc.add_child(r)
	var go := UI.button("Devam", close_panel, 62, true)
	go.custom_minimum_size.x = 240
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	body.add_child(go)


func close_panel() -> void:
	var cb := _after
	super.close_panel()
	if cb.is_valid():
		cb.call()
