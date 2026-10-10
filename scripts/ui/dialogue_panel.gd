class_name DialoguePanel
extends BasePanel
## Doğal konuşma ekranı: karakterin sözü, ilişki değişimleri ve kimliğe göre değişen seçenekler.

var char_id := ""
var game: Node
var npc_node: Node
var speech: RichTextLabel
var delta_label: RichTextLabel
var options_box: GridContainer
var sub_title: Label
var mood_label: Label
var rel_bars: VBoxContainer
var _in_sub := false


func open(id: String, g: Node, node: Node) -> void:
	char_id = id
	game = g
	npc_node = node
	setup_frame("", 0.97, 0.66, "")
	frame.anchor_top = 0.43
	frame.anchor_bottom = 0.985
	# üst kısım karartılmasın: konuşulan kişi yakın çekimde görünür
	var dim: ColorRect = get_child(0)
	dim.color = Color(0, 0, 0, 0)
	# başlık satırı
	UI.clear(header)
	header.add_child(UI.portrait(id, 74))
	var namebox := UI.vbox(2)
	namebox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := UI.title(GameState.full_name(id), 32)
	namebox.add_child(nm)
	mood_label = UI.label("", 18, UI.MUTED)
	namebox.add_child(mood_label)
	header.add_child(namebox)
	rel_bars = UI.vbox(2)
	rel_bars.custom_minimum_size = Vector2(250, 0)
	header.add_child(rel_bars)
	var prof := UI.button("Profil", _open_profile, 52)
	prof.custom_minimum_size.x = 110
	header.add_child(prof)
	var leave := UI.button("Ayrıl", _leave, 52, true)
	leave.custom_minimum_size.x = 110
	header.add_child(leave)
	# gövde
	var row := UI.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	var left := UI.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.05
	row.add_child(left)
	var sp_card := UI.card(Color(UI.NAVY2, 0.85))
	sp_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(sp_card)
	var sc := UI.scroll()
	sp_card.add_child(sc)
	var spv := UI.vbox(6)
	spv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(spv)
	speech = UI.rich("", 22)
	spv.add_child(speech)
	delta_label = UI.rich("", 19)
	left.add_child(delta_label)
	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	sub_title = UI.label("", 19, UI.GOLD2)
	right.add_child(sub_title)
	var osc := UI.scroll()
	right.add_child(osc)
	options_box = UI.grid(2, 8, 8)
	options_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	osc.add_child(options_box)
	DialogueEngine.start(GameState, id)
	_say(DialogueEngine.greeting(GameState, id), {})
	_show_topics()


func _refresh_header() -> void:
	var c: Dictionary = GameState.ch(char_id)
	var op: float = GameState.opinion(char_id, GameState.PLAYER)
	mood_label.text = "%s  •  %s  •  Size bakışı: %s" % [GameState.activity_text(char_id), GameState.mood_label(float(c.get("mood", 0))), GameState.opinion_label(op)]
	UI.clear(rel_bars)
	var r: Dictionary = GameState.rel(char_id, GameState.PLAYER)
	var dims := ["sevgi", "guven", "saygi"]
	if c.get("romanceable", false):
		dims.append("romantik")
	for d in dims:
		var h := UI.hbox(6)
		var l := UI.label(GameState.REL_NAMES[d], 15, UI.MUTED)
		l.custom_minimum_size = Vector2(88, 0)
		h.add_child(l)
		var col := UI.GOLD
		if d == "romantik":
			col = Color("d76b8a")
		elif d == "guven":
			col = UI.BLUE
		elif d == "sevgi":
			col = UI.GREEN
		var b := UI.bar(float(r.get(d, 0)), 100.0, col, 10)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
		rel_bars.add_child(h)


func _say(text: String, deltas: Dictionary) -> void:
	speech.text = text
	delta_label.text = UI.delta_text(deltas)
	_refresh_header()


func _show_topics() -> void:
	_in_sub = false
	sub_title.text = "Ne konuşmak istersiniz?"
	UI.clear(options_box)
	for t in DialogueEngine.topics(GameState, char_id):
		var tid: String = t["id"]
		var b := UI.button(String(t["label"]), func(): _pick(tid, ""), 54, t.get("kind", "") in ["event", "special"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 20)
		options_box.add_child(b)


func _show_sub(sub: Array, title: String) -> void:
	_in_sub = true
	sub_title.text = title
	UI.clear(options_box)
	for s in sub:
		var sid: String = s["id"]
		var sarg: String = s.get("arg", "")
		var b := UI.button(String(s["label"]), func(): _pick(sid, sarg), 54)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = s.get("disabled", false)
		b.add_theme_font_size_override("font_size", 19)
		options_box.add_child(b)
	var back := UI.button("‹ Geri", _show_topics, 54)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_box.add_child(back)


func _pick(topic: String, arg: String) -> void:
	var r: Dictionary = DialogueEngine.choose(GameState, char_id, topic, arg)
	if r["sub"].size() > 0:
		if String(r["text"]) != "":
			_say(String(r["text"]), {})
		_show_sub(r["sub"], String(r.get("sub_title", "")))
		return
	if String(r["text"]) != "":
		_say(String(r["text"]), r["deltas"])
	if r.get("end", false):
		close_panel()
		return
	if not r["deltas"].is_empty():
		AudioManager.play_ui("chime" if _positive(r["deltas"]) else "low")
	_show_topics()


func _positive(d: Dictionary) -> bool:
	var s := 0.0
	for k in d.keys():
		var v := float(d[k])
		s += -v if k in ["korku", "kiskanclik", "rekabet"] else v
	return s >= 0.0


func _open_profile() -> void:
	if game:
		game.open_profile(char_id)


func _leave() -> void:
	var r: Dictionary = DialogueEngine.choose(GameState, char_id, "veda", "")
	speech.text = String(r["text"])
	close_panel()


func close_panel() -> void:
	if npc_node and is_instance_valid(npc_node):
		npc_node.end_talk()
	super.close_panel()
