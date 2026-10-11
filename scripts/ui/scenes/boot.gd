extends Control
## Boot — açılış logosu, veri doğrulama ve ilk yönlendirme (ilk açılışta şef oluşturma).


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bd := Backdrop.new()
	bd.kind = "sunburst"
	bd.c1 = Color("#7c3bd6")
	bd.c2 = Color("#2a1b3d")
	add_child(bd)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := UIKit.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(v)
	var logo := TextureRect.new()
	logo.texture = load("res://icon.png")
	logo.custom_minimum_size = Vector2(260, 260)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(logo)
	var letters := UIKit.hbox(0)
	letters.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(letters)
	var word := Loc.t("FUSE CHEF")
	var cols := [Color("#ffd23f"), Color("#ff9b3d"), Color("#ff5fa2"), Color("#a25cff"), Color("#ffffff"), Color("#3ddc84"), Color("#4ad6ff"), Color("#ffd23f"), Color("#ff9b3d")]
	var labels: Array = []
	for i in word.length():
		var l := UIKit.title(word[i], 82, cols[i % cols.size()], UIKit.INK, 18)
		l.custom_minimum_size.x = 30 if word[i] == " " else 0
		letters.add_child(l)
		labels.append(l)
		l.modulate.a = 0.0
	var sub := UIKit.title(Loc.t("ÇILGIN MUTFAK SAVAŞI"), 34, Color.WHITE, UIKit.INK, 10)
	sub.modulate.a = 0.0
	v.add_child(sub)
	var bar := UIKit.bar(0, 100, UIKit.GREEN, 22, 420)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(UIKit.spacer(30))
	v.add_child(bar)
	logo.pivot_offset = Vector2(130, 130)
	logo.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(logo, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	for i in labels.size():
		var l2: Label = labels[i]
		tw.tween_callback(func():
			AudioManager.sfx("pop", 0.9 + i * 0.06, -6.0)
			l2.modulate.a = 1.0
			l2.pivot_offset = l2.size * 0.5
			l2.scale = Vector2(1.6, 1.6)
			var t2 := l2.create_tween()
			t2.tween_property(l2, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
		tw.tween_interval(0.06)
	tw.tween_property(sub, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(bar, "value", 100.0, 1.0)
	await tw.finished
	if not IngredientDatabase.load_errors.is_empty():
		var err := UIKit.wrap_label(Loc.t("Veri uyarısı: %s") % str(IngredientDatabase.load_errors[0]), 18, Color("#ffd0d0"))
		v.add_child(err)
	if SaveManager.loaded_from == "backup":
		GameManager.toast(Loc.t("Kayıt dosyası onarıldı (yedekten yüklendi)."), UIKit.ORANGE, "info")
	await get_tree().create_timer(0.3).timeout
	AudioManager.music("menu")
	if not bool(SaveManager.data["profile"].get("created", false)):
		GameManager.goto("chef", {"first": true}, false)
	else:
		GameManager.goto("menu", {}, false)


func on_back() -> bool:
	return true
