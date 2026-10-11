extends Node
## GameManager — sahne geçişleri (iris efekti), geri tuşu davranışı, global tema/yazı tipleri,
## bildirim (toast) sistemi ve titreşim.

const SCENES := {
	"boot": "res://scenes/Boot.tscn",
	"menu": "res://scenes/MainMenu.tscn",
	"chef": "res://scenes/ChefCustomization.tscn",
	"career": "res://scenes/CareerMap.tscn",
	"kitchen": "res://scenes/KitchenBattle.tscn",
	"lab": "res://scenes/FusionLab.tscn",
	"judging": "res://scenes/JudgingStage.tscn",
	"results": "res://scenes/Results.tscn",
	"book": "res://scenes/RecipeBook.tscn",
	"daily": "res://scenes/DailyChallenge.tscn",
	"settings": "res://scenes/Settings.tscn",
	"shop": "res://scenes/Shop.tscn",
}

const C_INK := Color("#3b2417")
const C_CREAM := Color("#fff7ea")
const C_PAPER := Color("#ffeccc")
const C_ORANGE := Color("#ff9b3d")
const C_PINK := Color("#ff5fa2")
const C_PURPLE := Color("#a25cff")
const C_GREEN := Color("#3ddc84")
const C_BLUE := Color("#4a7dff")
const C_YELLOW := Color("#ffd23f")
const C_RED := Color("#ff4f5e")
const C_DARK := Color("#2a1b3d")

var font_base: FontFile
var font_bold: FontVariation
var font_semi: FontVariation
var font_reg: FontVariation
var theme: Theme
var params: Dictionary = {}
var current_key := ""
var history: Array = []
var busy := false
var _overlay_layer: CanvasLayer
var _iris: ColorRect
var _toast_layer: CanvasLayer
var _toast_queue: Array = []
var _toast_showing := false
var _back_lock := 0
var screen_size := Vector2(720, 1280)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fonts()
	_build_theme()
	get_tree().root.theme = theme
	_build_overlay()
	ProgressionManager.achievement_unlocked.connect(_on_achievement)
	ProgressionManager.secret_unlocked.connect(_on_secret)
	ProgressionManager.level_up.connect(_on_level)
	Loc.language_changed.connect(func(_c: String): apply_fonts())
	get_tree().root.size_changed.connect(_on_resize)
	_on_resize()
	var cs := get_tree().current_scene
	if cs != null:
		current_key = _key_for_path(cs.scene_file_path)


func _on_resize() -> void:
	screen_size = get_viewport().get_visible_rect().size


func _key_for_path(p: String) -> String:
	for k in SCENES.keys():
		if SCENES[k] == p:
			return k
	return ""


## Ekranın güvenli üst boşluğu (çentik) — sanal piksel cinsinden.
func safe_top() -> float:
	var sa := DisplayServer.get_display_safe_area()
	var ws := DisplayServer.window_get_size()
	if ws.y <= 0:
		return 0.0
	var scale := screen_size.y / float(ws.y)
	return clampf(sa.position.y * scale, 0.0, 90.0)


func safe_bottom() -> float:
	var sa := DisplayServer.get_display_safe_area()
	var ws := DisplayServer.window_get_size()
	if ws.y <= 0:
		return 0.0
	var scale := screen_size.y / float(ws.y)
	var bottom := float(ws.y) - float(sa.position.y + sa.size.y)
	return clampf(bottom * scale, 0.0, 60.0)


func _build_fonts() -> void:
	font_base = load("res://assets/fonts/Baloo2.ttf")
	font_bold = FontVariation.new()
	font_bold.base_font = font_base
	font_bold.variation_opentype = {"wght": 800}
	font_semi = FontVariation.new()
	font_semi.base_font = font_base
	font_semi.variation_opentype = {"wght": 650}
	font_reg = FontVariation.new()
	font_reg.base_font = font_base
	font_reg.variation_opentype = {"wght": 520}
	apply_fonts()


const FALLBACK_FONTS := {"ar": "res://assets/fonts/BalooBhaijaan2.ttf", "zh": "res://assets/fonts/NotoSansSC.ttf",
	"ja": "res://assets/fonts/MPLUSRounded1c.ttf"}
var _fallback_cache: Dictionary = {}


## Arapça ve Çince/Japonca karakterler için yedek yazı tipleri. Han karakterleri iki dilde ortak
## olduğundan aktif dilin yazı tipi önce gelir (Japoncada Japon, Çincede Çin glif biçimleri).
func apply_fonts() -> void:
	var order: Array = ["ar", "zh", "ja"]
	if Loc.lang == "ja":
		order = ["ja", "zh", "ar"]
	elif Loc.lang == "zh":
		order = ["zh", "ja", "ar"]
	var fb: Array[Font] = []
	for k in order:
		if not _fallback_cache.has(k):
			var path: String = FALLBACK_FONTS[k]
			_fallback_cache[k] = load(path) if ResourceLoader.exists(path) else null
		if _fallback_cache[k] != null:
			fb.append(_fallback_cache[k])
	for f in [font_base, font_bold, font_semi, font_reg]:
		if f != null:
			f.fallbacks = fb


func _sb(bg: Color, radius := 22, border := Color(0, 0, 0, 0), bw := 0, bottom := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(bw)
	if bottom > 0:
		s.border_width_bottom = bottom
	s.anti_aliasing = true
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font = font_semi
	theme.default_font_size = 26
	theme.set_color("font_color", "Label", C_INK)
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.6))
	theme.set_font("font", "Button", font_bold)
	theme.set_font_size("font_size", "Button", 28)
	var bn := _sb(C_ORANGE, 24, C_ORANGE.darkened(0.35), 0, 7)
	theme.set_stylebox("normal", "Button", bn)
	var bh := _sb(C_ORANGE.lightened(0.08), 24, C_ORANGE.darkened(0.35), 0, 7)
	theme.set_stylebox("hover", "Button", bh)
	var bp := _sb(C_ORANGE.darkened(0.05), 24, C_ORANGE.darkened(0.35), 0, 2)
	bp.content_margin_top = 15
	theme.set_stylebox("pressed", "Button", bp)
	theme.set_stylebox("disabled", "Button", _sb(Color("#c9b8a6"), 24, Color("#9d8b78"), 0, 7))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "PanelContainer", _sb(C_CREAM, 28, C_INK, 4))
	theme.set_stylebox("panel", "Panel", _sb(C_CREAM, 28, C_INK, 4))
	var le := _sb(Color.WHITE, 18, C_INK, 3)
	theme.set_stylebox("normal", "LineEdit", le)
	theme.set_stylebox("focus", "LineEdit", _sb(Color.WHITE, 18, C_ORANGE, 4))
	theme.set_color("font_color", "LineEdit", C_INK)
	theme.set_color("caret_color", "LineEdit", C_ORANGE)
	theme.set_font_size("font_size", "LineEdit", 30)
	var grab := _sb(C_ORANGE, 12)
	theme.set_stylebox("grabber", "VScrollBar", grab)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grab)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var sc := _sb(Color(0, 0, 0, 0.08), 12)
	sc.content_margin_left = 3
	sc.content_margin_right = 3
	theme.set_stylebox("scroll", "VScrollBar", sc)
	theme.set_stylebox("scroll", "HScrollBar", sc)
	theme.set_stylebox("grabber", "HScrollBar", grab)
	theme.set_stylebox("grabber_highlight", "HScrollBar", grab)
	theme.set_stylebox("grabber_pressed", "HScrollBar", grab)
	var slider_bg := _sb(Color("#e8d6bd"), 10)
	slider_bg.content_margin_top = 8
	slider_bg.content_margin_bottom = 8
	theme.set_stylebox("slider", "HSlider", slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", _sb(C_ORANGE, 10))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _sb(C_ORANGE, 10))
	var gimg := Image.create(44, 44, false, Image.FORMAT_RGBA8)
	gimg.fill(Color(0, 0, 0, 0))
	for y in 44:
		for x in 44:
			var dd := Vector2(x - 21.5, y - 21.5).length()
			if dd < 20.5:
				gimg.set_pixel(x, y, C_INK if dd > 16.5 else Color.WHITE)
			elif dd < 21.5:
				gimg.set_pixel(x, y, Color(C_INK, 21.5 - dd))
	var gtex := ImageTexture.create_from_image(gimg)
	theme.set_icon("grabber", "HSlider", gtex)
	theme.set_icon("grabber_highlight", "HSlider", gtex)


func _build_overlay() -> void:
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 120
	add_child(_overlay_layer)
	_iris = ColorRect.new()
	_iris.set_anchors_preset(Control.PRESET_FULL_RECT)
	_iris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float radius = 1.5;
uniform float aspect = 0.5625;
uniform vec4 col_a : source_color = vec4(0.17, 0.09, 0.26, 1.0);
uniform vec4 col_b : source_color = vec4(0.42, 0.16, 0.45, 1.0);
void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= aspect;
	float d = length(uv);
	float a = smoothstep(radius, radius + 0.012, d);
	vec2 g = fract(UV * vec2(9.0 * aspect, 9.0)) - 0.5;
	float dots = smoothstep(0.16, 0.12, length(g));
	vec3 c = mix(col_a.rgb, col_b.rgb, UV.y * 0.8 + dots * 0.25);
	COLOR = vec4(c, a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("radius", 1.5)
	_iris.material = mat
	_overlay_layer.add_child(_iris)
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = 110
	add_child(_toast_layer)


func _set_iris(r: float) -> void:
	var mat: ShaderMaterial = _iris.material
	mat.set_shader_parameter("radius", r)
	mat.set_shader_parameter("aspect", screen_size.x / maxf(1.0, screen_size.y))
	_iris.mouse_filter = Control.MOUSE_FILTER_STOP if r < 1.0 else Control.MOUSE_FILTER_IGNORE


func goto(key: String, p := {}, push := true) -> void:
	if busy or not SCENES.has(key):
		return
	busy = true
	params = p
	if push and current_key != "" and current_key != key and not ["judging", "results", "boot"].has(current_key):
		history.append(current_key)
		if history.size() > 12:
			history.pop_front()
	AudioManager.sfx("whoosh", 1.0, -4.0)
	var tw := create_tween()
	tw.tween_method(_set_iris, 0.9, 0.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	AudioManager.stop_all_loops()
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(SCENES[key])
	if err != OK:
		push_error("Sahne yüklenemedi: " + key)
	current_key = key
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_method(_set_iris, 0.0, 0.9, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_set_iris(1.5)
	busy = false


func go_back() -> void:
	if busy:
		return
	var target := "menu"
	while not history.is_empty():
		var k: String = history.pop_back()
		if k != current_key and not ["judging", "results", "kitchen", "boot"].has(k):
			target = k
			break
	goto(target, {}, false)


func reset_history() -> void:
	history.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_handle_back()
		get_viewport().set_input_as_handled()


func _handle_back() -> void:
	var now := Time.get_ticks_msec()
	if now - _back_lock < 350 or busy:
		return
	_back_lock = now
	# Açık bir açılır pencere varsa önce onu kapat
	var top := _top_modal()
	if top != null:
		if top.has_method("on_back"):
			top.on_back()
		return
	var cs := get_tree().current_scene
	if cs != null and cs.has_method("on_back"):
		if cs.on_back():
			return
	if current_key == "menu":
		var cs2 := get_tree().current_scene
		if cs2 != null and cs2.has_method("confirm_quit"):
			cs2.confirm_quit()
		else:
			get_tree().quit()
		return
	go_back()


func _top_modal() -> Node:
	var modals := get_tree().get_nodes_in_group("modal")
	var best: Node = null
	for m in modals:
		if m.is_inside_tree() and m.visible:
			best = m
	return best


# ------------------------------------------------------------------ toast
func toast(text: String, color := C_PURPLE, icon := "star") -> void:
	_toast_queue.append({"text": text, "color": color, "icon": icon})
	if not _toast_showing:
		_next_toast()


func _next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_showing = false
		return
	_toast_showing = true
	var t: Dictionary = _toast_queue.pop_front()
	var panel := PanelContainer.new()
	var sb := _sb(t["color"], 26, Color(t["color"]).darkened(0.4), 0, 6)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	panel.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = icon_tex(t["icon"])
	if tex != null:
		var ic := TextureRect.new()
		ic.texture = tex
		ic.custom_minimum_size = Vector2(44, 44)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(ic)
	var lbl := Label.new()
	lbl.text = t["text"]
	lbl.add_theme_font_override("font", font_bold)
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.autowrap_mode = UIKit.wrap_mode()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(minf(screen_size.x - 140, 540), 0)
	row.add_child(lbl)
	panel.add_child(row)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_child(panel)
	await get_tree().process_frame
	var w := panel.size.x
	panel.position = Vector2((screen_size.x - w) * 0.5, -panel.size.y - 20)
	var y_target := 24.0 + safe_top()
	var tw := create_tween()
	tw.tween_property(panel, "position:y", y_target, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(panel, "position:y", -panel.size.y - 20, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(panel.queue_free)
	tw.tween_callback(_next_toast)


func _on_achievement(id: String) -> void:
	var a: Dictionary = IngredientDatabase.achievements.get(id, {})
	toast(Loc.t("Başarım: %s  (+%d)") % [a.get("name", id), int(a.get("coins", 0))], C_ORANGE, "trophy")
	AudioManager.sfx("unlock")


func _on_secret(id: String) -> void:
	var s: Dictionary = IngredientDatabase.secrets.get(id, {})
	toast(Loc.t("Gizli karakter açıldı: %s!") % s.get("name", id), C_PINK, "sparkle")
	AudioManager.sfx("unlock", 1.2)


func _on_level(lvl: int) -> void:
	toast(Loc.t("Seviye %d! +1 uzmanlık puanı") % lvl, C_GREEN, "levelup")
	AudioManager.sfx("levelup")


var _icons: Dictionary = {}


## res://assets/ui/icons/<ad>.png ikonlarını önbellekli yükler.
func icon_tex(icon_name: String) -> Texture2D:
	if _icons.has(icon_name):
		return _icons[icon_name]
	var path := "res://assets/ui/icons/%s.png" % icon_name
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_icons[icon_name] = t
	return t


func vibrate(ms := 40) -> void:
	if bool(SaveManager.setting("vibration", true)):
		Input.vibrate_handheld(ms)


func fast() -> bool:
	return bool(SaveManager.setting("fast", false))
