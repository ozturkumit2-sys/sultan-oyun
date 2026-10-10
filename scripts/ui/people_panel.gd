class_name PeoplePanel
extends BasePanel
## Saray halkı listesi: kim nerede, ne yapıyor, size bakışı.

var game: Node
var list_box: GridContainer
var filter := "hepsi"
const FILTERS := [["hepsi", "Tümü"], ["harem", "Harem ve Aile"], ["devlet", "Devlet"], ["hizmet", "Hizmet ve Muhafız"]]


func open(g: Node) -> void:
	game = g
	setup_frame("Saray Halkı", 0.94, 0.92)
	var tabs := UI.hbox(8)
	body.add_child(tabs)
	for f in FILTERS:
		var fid: String = f[0]
		var b := UI.button(f[1], func(): _set_filter(fid), 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	var sc := UI.scroll()
	body.add_child(sc)
	list_box = UI.grid(3, 10, 10)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list_box)
	_fill()


func _set_filter(f: String) -> void:
	filter = f
	_fill()


func _cat(id: String) -> String:
	var role: String = GameState.ch(id)["role"]
	if role in ["valide", "harem", "harem_staff", "child", "chamberlain"]:
		return "harem"
	if role in ["official", "scribe", "envoy", "clerk"]:
		return "devlet"
	return "hizmet"


func _fill() -> void:
	UI.clear(list_box)
	var ids: Array = GameState.npc_ids()
	ids.sort_custom(func(a, b): return int(GameState.ch(a)["status"]) > int(GameState.ch(b)["status"]))
	for id in ids:
		if filter != "hepsi" and _cat(id) != filter:
			continue
		var cid: String = id
		var card := UI.card()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := UI.hbox(10)
		card.add_child(h)
		h.add_child(UI.portrait(id, 64))
		var v := UI.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var c: Dictionary = GameState.ch(id)
		var rk := HaremEngine.rank_name(GameState, id) if HaremEngine.is_harem_woman(GameState, id) else ""
		if String(c.get("role", "")) == "child":
			rk = "%d yaşında" % int(c.get("age", 0))
		v.add_child(UI.label(GameState.short_name(id) + ("  ·  " + rk if rk != "" else ""), 21, UI.GOLD2, UI.font_semi))
		var loc := "Saray dışında" if c["location"] == "disari" else PalaceLayout.room_short(c["location"])
		v.add_child(UI.label("%s • %s" % [loc, GameState.activity_text(id)], 16, UI.MUTED))
		var op: float = GameState.opinion(id, GameState.PLAYER)
		var oh := UI.hbox(6)
		oh.add_child(UI.label(GameState.opinion_label(op), 16, UI.TEXT))
		var bar := UI.bar(op, 100.0, UI.GOLD, 8)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		oh.add_child(bar)
		v.add_child(oh)
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(func():
			AudioManager.play_ui("click")
			game.open_profile(cid))
		card.add_child(btn)
		list_box.add_child(card)
	var gone: Array = []
	for id2 in GameState.w["characters"].keys():
		if GameState.ch(id2).get("gone", false):
			gone.append(GameState.short_name(id2))
	if not gone.is_empty() and filter == "hepsi":
		var l := UI.wrap_label("Saraydan ayrılanlar: " + ", ".join(PackedStringArray(gone)), 17, UI.MUTED)
		list_box.add_child(l)
