class_name EventsPanel
extends BasePanel
## Bekleyen olaylar ve görüşme talepleri; geçmiş kararlar.

var game: Node
var content: VBoxContainer
var show_history := false
var result_box: VBoxContainer


func open(g: Node) -> void:
	game = g
	setup_frame("Saray Olayları", 0.94, 0.92)
	var tabs := UI.hbox(8)
	body.add_child(tabs)
	var b1 := UI.button("Bekleyenler", func(): _set_mode(false), 50)
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(b1)
	var b2 := UI.button("Geçmiş Kararlar", func(): _set_mode(true), 50)
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(b2)
	result_box = UI.vbox(4)
	body.add_child(result_box)
	var sc := UI.scroll()
	body.add_child(sc)
	content = UI.vbox(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	_build()


func _set_mode(h: bool) -> void:
	show_history = h
	UI.clear(result_box)
	_build()


func _build() -> void:
	UI.clear(content)
	if show_history:
		var hist: Array = GameState.w["events"]["history"]
		if hist.is_empty():
			content.add_child(UI.label("Henüz karar verilmiş bir olay yok.", 20, UI.MUTED))
		for i in range(hist.size() - 1, -1, -1):
			var h: Dictionary = hist[i]
			var card := UI.card()
			var v := UI.vbox(4)
			card.add_child(v)
			v.add_child(UI.label("%d. gün — %s" % [int(h["day"]) + 1, h["title"]], 21, UI.GOLD2, UI.font_semi))
			v.add_child(UI.wrap_label("Kararınız: " + String(h["choice"]), 18, UI.CREAM))
			if String(h["result"]) != "":
				v.add_child(UI.wrap_label(String(h["result"]), 18, UI.MUTED))
			content.add_child(card)
		return
	var pend: Array = EventEngine.pending(GameState)
	if pend.is_empty():
		content.add_child(UI.wrap_label("Şu anda bekleyen bir olay yok. Saray yaşamı sürüyor; yeni gelişmeler olduğunda burada göreceksiniz.", 20, UI.MUTED))
	for ev in pend:
		ev["seen"] = true
		var card2 := UI.card()
		var v2 := UI.vbox(8)
		card2.add_child(v2)
		var left := int(ev["expires"]) - GameState.get_day()
		v2.add_child(UI.title(String(ev["title"]), 28))
		v2.add_child(UI.label("Süre: %s" % ("bugün son gün" if left <= 0 else "%d gün" % left), 16, UI.MUTED))
		var talk: String = ev.get("talk", "")
		if talk != "":
			var c: Dictionary = GameState.ch(talk)
			var where := "saray dışında (yarın gelecek)" if c.get("location", "") == "disari" else PalaceLayout.room_name(c.get("location", ""))
			v2.add_child(UI.wrap_label("%s sizinle bizzat görüşmek istiyor. Şu an: %s." % [GameState.short_name(talk), where], 20, UI.CREAM))
			var row := UI.hbox(8)
			v2.add_child(row)
			if c.get("location", "") != "disari":
				var t2 := talk
				var g1 := UI.button("Yanına Git", func(): _go(t2), 54, true)
				g1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(g1)
				var g2 := UI.button("Huzura Çağır", func(): _summon(t2), 54)
				g2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(g2)
		else:
			v2.add_child(UI.wrap_label(String(ev["text"]), 20, UI.CREAM))
			for o in EventEngine.options_for(GameState, ev):
				if not o["available"]:
					continue
				var uid: String = ev["uid"]
				var idx: int = o["idx"]
				var label: String = o["text"]
				if float(o["cost"]) > 0:
					label += "  (%s)" % GameState.fmt_money(float(o["cost"]))
				var b := UI.button(label, func(): _choose(uid, idx), 54)
				b.disabled = not o["affordable"]
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				v2.add_child(b)
		content.add_child(card2)
	GameState.events_changed.emit()


func _choose(uid: String, idx: int) -> void:
	var res := EventEngine.resolve(GameState, uid, idx)
	UI.clear(result_box)
	if res != "":
		var card := UI.card(Color(UI.EMERALD, 0.35), UI.GOLD)
		card.add_child(UI.wrap_label(res, 20, UI.CREAM))
		result_box.add_child(card)
	_build()


func _go(id: String) -> void:
	game.walk_to_char(id)
	close_panel()


func _summon(id: String) -> void:
	game.summon(id)
	close_panel()
