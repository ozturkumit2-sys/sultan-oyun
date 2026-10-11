class_name SabotageDialog
extends Control
## Sabotaj uyarısı: rakibin hamlesini önceden gösterir ve üç anlamlı seçenek sunar.
## Savun → DefendMinigame; Uyum Sağla → dönüştürülmüş etki; Riski Kabul Et → tam etki ama geri tepme şansı.

signal done(result: Dictionary)

var ability := ""
var _panel: PanelContainer
var _busy := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 78
	add_to_group("modal")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.02, 0.08, 0.6))


func open(ab: String, opponent: Dictionary, target_item := "") -> void:
	ability = ab
	var info := SabotageSystem.ability(ab)
	var col := Color(info.get("color", "#ff4f5e"))
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = UIKit.panel(UIKit.CREAM, 34, UIKit.INK, 5, 22)
	_panel.custom_minimum_size = Vector2(minf(640, GameManager.screen_size.x - 30), 0)
	center.add_child(_panel)
	var v := UIKit.vbox(12)
	_panel.add_child(v)
	var head := UIKit.hbox(10)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(UIKit.icon("skull", 54))
	head.add_child(UIKit.title("SABOTAJ!", 50, Color("#ff4f5e"), UIKit.INK, 12))
	v.add_child(head)
	var nm := UIKit.chip(info.get("name", ab), col, 26)
	nm.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(nm)
	var line: String = opponent.get("warn", "Rakip bir şeyler planlıyor!")
	v.add_child(UIKit.wrap_label(line, 24, Color("#7a3a3a"), true))
	if ab == "ingredient_theft" and target_item != "":
		var row := UIKit.hbox(8)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var ic := IngredientIcon.new()
		ic.custom_minimum_size = Vector2(70, 70)
		ic.set_item(target_item)
		row.add_child(ic)
		row.add_child(UIKit.label("Hedef: %s" % FusionEngine.item(target_item)["name"], 24, UIKit.INK))
		v.add_child(row)
	v.add_child(_option("SAVUN", info.get("defend", ""), UIKit.BLUE, "shield", "defend"))
	v.add_child(_option("UYUM SAĞLA", info.get("adapt", ""), UIKit.GREEN, "refresh", "adapt"))
	var acc_text: String = info.get("accept", "")
	if ProgressionManager.spec_tier("chaos") >= 3:
		acc_text = acc_text.replace("%20", "%40")
	v.add_child(_option("RİSKİ KABUL ET", acc_text, UIKit.ORANGE, "fire", "accept"))
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	AudioManager.sfx("warning")
	GameManager.vibrate(80)


func _option(title_text: String, desc: String, col: Color, icon_name: String, choice: String) -> Control:
	var card := TapCard.new()
	card.set_colors(col.lightened(0.78), col.darkened(0.2))
	var h := UIKit.hbox(12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(h)
	h.add_child(UIKit.icon(icon_name, 56))
	var tv := UIKit.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tv)
	tv.add_child(UIKit.label(title_text, 28, col.darkened(0.35), true, HORIZONTAL_ALIGNMENT_LEFT))
	var d := UIKit.wrap_label(desc, 20, UIKit.INK, false, HORIZONTAL_ALIGNMENT_LEFT)
	tv.add_child(d)
	card.tapped.connect(func(): _choose(choice))
	return card


func _choose(choice: String) -> void:
	if _busy:
		return
	_busy = true
	var hits := 0
	var perfect := false
	var extra := ""
	if choice == "defend":
		_panel.visible = false
		var dm := DefendMinigame.new()
		get_parent().add_child(dm)
		var info := SabotageSystem.ability(ability)
		dm.start(Color(info.get("color", "#4a7dff")), info.get("name", ""))
		var r: Array = await dm.finished
		hits = r[0]
		perfect = r[1]
	elif choice == "adapt" and ability == "rotten_surprise":
		extra = await _pick_jar()
	if not is_inside_tree() or not BattleManager.active:
		return
	var res := BattleManager.resolve_sabotage(ability, choice, hits, perfect, extra)
	res["choice"] = choice
	res["ability"] = ability
	done.emit(res)
	queue_free()


func _pick_jar() -> String:
	for c in _panel.get_children():
		c.queue_free()
	var v := UIKit.vbox(12)
	_panel.add_child(v)
	v.add_child(UIKit.title("Kavanozunu Seç", 40, Color.WHITE, UIKit.INK, 10))
	v.add_child(UIKit.wrap_label("Gülizar Nine bir kavanoz ekleyecek. Hangisi olsun?", 24))
	var row := UIKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var picked := [""]
	var sig := [false]
	for fid in SabotageSystem.FERMENTED:
		var card := TapCard.new()
		card.custom_minimum_size = Vector2(170, 190)
		var cv := UIKit.vbox(2)
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(cv)
		var ic := IngredientIcon.new()
		ic.custom_minimum_size = Vector2(110, 110)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.set_item(fid)
		cv.add_child(ic)
		var l := UIKit.label(IngredientDatabase.ingredients[fid]["name"], 18)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 150
		cv.add_child(l)
		var f2: String = fid
		card.tapped.connect(func():
			picked[0] = f2
			sig[0] = true)
		row.add_child(card)
	while not sig[0]:
		if not is_inside_tree():
			return SabotageSystem.FERMENTED[0]
		await get_tree().process_frame
	return picked[0]


func on_back() -> void:
	pass
