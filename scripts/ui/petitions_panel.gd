class_name PetitionsPanel
extends BasePanel
## Halk Kabul Salonu: halkın dilekçelerini dinleyip hüküm verme.

var game: Node
var content: VBoxContainer
var result_box: VBoxContainer


func open(g: Node) -> void:
	game = g
	setup_frame("Arz Odası — Halkın Dilekçeleri", 0.94, 0.92)
	var st: Dictionary = GameState.w["state"]
	body.add_child(UI.label("Adalet itibarı: %%%d  •  Dinlenen dilekçe: %d  •  Kadıasker: %s" % [int(st["justice"]), int(GameState.w["petitions"].get("heard", 0)), GameState.short_name(GameState.post_holder("adalet")) if GameState.post_holder("adalet") != "" else "yok"], 18, UI.MUTED))
	result_box = UI.vbox(4)
	body.add_child(result_box)
	var sc := UI.scroll()
	body.add_child(sc)
	content = UI.vbox(12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	_build()


func _build() -> void:
	UI.clear(content)
	var lst: Array = PetitionEngine.list(GameState)
	if lst.is_empty():
		content.add_child(UI.wrap_label("Bugün huzura çıkacak dilekçe sahibi kalmadı. Yeni dilekçeler birkaç günde bir gelir.", 20, UI.MUTED))
	for pet in lst:
		var card := UI.card()
		var v := UI.vbox(8)
		card.add_child(v)
		v.add_child(UI.label(String(pet["ctx"]["name"]), 24, UI.GOLD2, UI.font_semi))
		v.add_child(UI.wrap_label(String(pet["text"]), 20, UI.CREAM))
		for o in PetitionEngine.options_for(GameState, pet):
			var uid: String = pet["uid"]
			var idx: int = o["idx"]
			var label: String = o["text"]
			if float(o["cost"]) > 0:
				label += "  (%s)" % GameState.fmt_money(float(o["cost"]))
			var b := UI.button(label, func(): _decide(uid, idx), 54)
			b.disabled = not o["affordable"]
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(b)
		content.add_child(card)


func _decide(uid: String, idx: int) -> void:
	var res := PetitionEngine.decide(GameState, uid, idx)
	UI.clear(result_box)
	if res != "":
		var card := UI.card(Color(UI.EMERALD, 0.35), UI.GOLD)
		card.add_child(UI.wrap_label(res, 20, UI.CREAM))
		result_box.add_child(card)
	_build()
