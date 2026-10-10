class_name SaveLoadPanel
extends BasePanel
## Kayıt yuvaları: kaydetme ve yükleme.

signal loaded(slot: String)

var saving := true
var list: VBoxContainer
var msg: Label


func open(is_saving: bool) -> void:
	saving = is_saving
	setup_frame("Oyunu Kaydet" if saving else "Kayıt Yükle", 0.7, 0.86)
	msg = UI.label("", 19, UI.GREEN)
	body.add_child(msg)
	var sc := UI.scroll()
	body.add_child(sc)
	list = UI.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	_build()


func _build() -> void:
	UI.clear(list)
	for slot in SaveSystem.SLOTS:
		if saving and slot == "oto":
			continue
		var s: String = slot
		var card := UI.card()
		var h := UI.hbox(12)
		card.add_child(h)
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(SaveSystem.SLOT_NAMES[s], 22, UI.GOLD2, UI.font_semi))
		var hd := SaveSystem.read_header(s)
		if SaveSystem.has_save(s):
			v.add_child(UI.label("%s" % hd.get("summary", "Kayıt"), 18))
			v.add_child(UI.label("Kaydedildi: %s  •  Hazine: %s" % [String(hd.get("saved_at", "?")), GameState.fmt_money(float(hd.get("treasury", 0)))], 16, UI.MUTED))
		else:
			v.add_child(UI.label("Boş yuva", 18, UI.MUTED))
		if saving:
			var b := UI.button("Kaydet", func(): _save(s), 54, true)
			b.custom_minimum_size.x = 150
			h.add_child(b)
		else:
			var b2 := UI.button("Yükle", func(): _load(s), 54, true)
			b2.custom_minimum_size.x = 150
			b2.disabled = not SaveSystem.has_save(s)
			h.add_child(b2)
			if SaveSystem.has_save(s) and s != "oto":
				var d := UI.button("Sil", func(): _delete(s), 54)
				d.custom_minimum_size.x = 90
				h.add_child(d)
		list.add_child(card)


func _save(slot: String) -> void:
	if SaveSystem.save_game(slot):
		msg.text = "Oyun kaydedildi: " + SaveSystem.SLOT_NAMES[slot]
		msg.add_theme_color_override("font_color", UI.GREEN)
		AudioManager.play_ui("chime")
	else:
		msg.text = "Kayıt başarısız oldu!"
		msg.add_theme_color_override("font_color", UI.RED)
	_build()


func _load(slot: String) -> void:
	loaded.emit(slot)


func _delete(slot: String) -> void:
	SaveSystem.delete_slot(slot)
	_build()
