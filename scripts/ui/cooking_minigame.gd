class_name CookingMinigame
extends Control
## Kısa etkileşimli pişirme mücadelesi. Yönteme göre üç tip:
## - Zamanlama (Fırın/Kızartma/Izgara): ibre hedef bölgedeyken 3 kez dokun.
## - Basılı tut (Haşlama/Dondurma): seviyeyi hareketli bantta tut.
## - Rünler (Büyülü): beliren rünlere zamanında dokun.
## Sabotaj etkileri: hız/bölge daraltma, titreme, karanlık.

signal finished(quality: float)

const TITLES := {"bake": "FIRINLA!", "fry": "KIZART!", "freeze": "DONDUR!", "boil": "KAYNAT!", "grill": "IZGARALA!", "magic": "BÜYÜLE!"}
const TIPS := {"timing": "İbre yeşil bölgedeyken dokun! (3 kez)", "hold": "Ekrana basılı tut, seviyeyi parlayan bantta tut!", "runes": "Beliren rünlere sönmeden dokun!"}

var method := "bake"
var mods: Dictionary = {}
var kind := "timing"
var _t := 0.0
var _done := false
var _accs: Array = []
var _needle := 0.0
var _dir := 1.0
var _speed := 0.85
var _zone_c := 0.5
var _zone_w := 0.24
var _perfect_w := 0.07
var _last_tap := 0.0
var _jitter_t := 0.0
var _flip := 0.0
var _level := 0.15
var _holding := false
var _band_c := 0.55
var _band_w := 0.22
var _in_band := 0.0
var _duration := 6.0
var _runes: Array = []
var _rune_i := 0
var _rune_w := 1.15
var _feedback := ""
var _feedback_t := 0.0
var _feedback_col := Color.WHITE
var _rng := RandomNumberGenerator.new()
var _dark_rect: ColorRect
var _focus := Vector2.ZERO
var _title: Label
var _tip: Label
var _gauge := Rect2()
var _area := Rect2()
var _bubbles: Array = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 70


func start(m: String, md: Dictionary) -> void:
	method = m
	mods = md
	_rng.randomize()
	match m:
		"boil", "freeze":
			kind = "hold"
		"magic":
			kind = "runes"
		_:
			kind = "timing"
	var spd := float(mods.get("speed", 1.0))
	var zone := float(mods.get("zone", 1.0))
	_speed = (0.85 if m == "bake" else (0.95 if m == "fry" else 1.0)) * spd
	_zone_w *= zone
	_perfect_w *= zone
	_band_w *= zone
	_rune_w /= spd
	_zone_c = _rng.randf_range(0.35, 0.65)
	_title = UIKit.title(TITLES.get(m, "PİŞİR!"), 60, Color.WHITE, UIKit.INK, 14)
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = GameManager.screen_size.y * 0.16
	add_child(_title)
	_tip = UIKit.title(TIPS[kind], 26, Color("#fff1a8"), UIKit.INK, 8)
	_tip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tip.offset_top = GameManager.screen_size.y * 0.16 + 80
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_tip)
	if float(mods.get("dark", 0.0)) > 0.0:
		_dark_rect = ColorRect.new()
		_dark_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_dark_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = """
shader_type canvas_item;
uniform vec2 focus = vec2(360.0, 640.0);
uniform float radius = 110.0;
uniform float darkness = 1.0;
uniform vec2 rect_size = vec2(720.0, 1280.0);
void fragment() {
	vec2 p = UV * rect_size;
	float d = distance(p, focus);
	float a = smoothstep(radius * 0.55, radius, d) * darkness * 0.96;
	COLOR = vec4(0.03, 0.01, 0.08, a);
}
"""
		var mat := ShaderMaterial.new()
		mat.shader = sh
		_dark_rect.material = mat
		add_child(_dark_rect)
	AudioManager.sfx("cook_start")
	match m:
		"fry", "grill":
			AudioManager.loop_start("sizzle", -6.0)
		"boil":
			AudioManager.loop_start("bubble", -4.0)
		"freeze":
			AudioManager.sfx("freeze")
		"magic":
			AudioManager.sfx("magic")
	if kind == "runes":
		for i in 5:
			_runes.append({"p": Vector2(_rng.randf_range(0.18, 0.82), _rng.randf_range(0.36, 0.78)), "t0": 0.6 + i * (_rune_w * 0.9), "hit": -1.0})
	for i in 10:
		_bubbles.append({"x": _rng.randf(), "y": _rng.randf(), "s": _rng.randf_range(0.2, 0.5)})


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var sz := size
	_area = Rect2(30, sz.y * 0.3, sz.x - 60, sz.y * 0.5)
	_gauge = Rect2(60, sz.y * 0.5, sz.x - 120, 64)
	_feedback_t = maxf(0.0, _feedback_t - delta)
	match kind:
		"timing":
			_needle += _dir * _speed * delta
			if _needle > 1.0:
				_needle = 2.0 - _needle
				_dir = -1.0
			elif _needle < 0.0:
				_needle = -_needle
				_dir = 1.0
			if method == "bake":
				_zone_c = clampf(_zone_c + sin(_t * 1.2) * delta * 0.05, 0.2, 0.8)
			if mods.get("jitter", false):
				_jitter_t -= delta
				if _jitter_t <= 0.0:
					_jitter_t = _rng.randf_range(0.25, 0.6)
					_needle = clampf(_needle + _rng.randf_range(-0.1, 0.1), 0.0, 1.0)
			_flip = maxf(0.0, _flip - delta * 3.0)
			if _t - _last_tap > 4.5:
				_register_tap(0.25, "Yandı!")
			_focus = Vector2(_gauge.position.x + _needle * _gauge.size.x, _gauge.get_center().y)
		"hold":
			var rise := 0.6 if method == "boil" else 0.5
			_level += (rise if _holding else -0.45) * delta
			if mods.get("jitter", false) and _rng.randf() < delta * 2.0:
				_level += _rng.randf_range(-0.12, 0.12)
			_level = clampf(_level, 0.0, 1.0)
			_band_c = 0.55 + 0.2 * sin(_t * (1.2 if method == "boil" else 0.9)) + 0.06 * sin(_t * 3.1)
			if absf(_level - _band_c) <= _band_w * 0.5:
				_in_band += delta
			var mr := _meter_rect()
			_focus = Vector2(mr.get_center().x, mr.end.y - _level * mr.size.y)
			if _t >= _duration:
				var q := clampf(_in_band / (_duration * 0.62), 0.0, 1.0)
				_finish(lerpf(0.25, 1.0, q))
		"runes":
			var active := false
			for i in _runes.size():
				var r: Dictionary = _runes[i]
				var age: float = _t - float(r["t0"])
				if r["hit"] < 0.0 and age > _rune_w:
					r["hit"] = 0.0
					_feedback = "Kaçtı!"
					_feedback_col = Color("#ff8a8a")
					_feedback_t = 0.6
				if r["hit"] < 0.0 and age >= 0.0:
					active = true
					_focus = _area.position + r["p"] * _area.size
			if not active:
				var all_done := true
				for r2 in _runes:
					if r2["hit"] < 0.0:
						all_done = false
				if all_done and _t > 1.0:
					var s := 0.0
					for r3 in _runes:
						s += float(r3["hit"])
					_finish(clampf(0.2 + s / _runes.size() * 0.8, 0.0, 1.0))
	if _dark_rect:
		var mat: ShaderMaterial = _dark_rect.material
		mat.set_shader_parameter("focus", _focus)
		mat.set_shader_parameter("rect_size", size)
		mat.set_shader_parameter("darkness", float(mods.get("dark", 0.0)))
		mat.set_shader_parameter("radius", 120.0)
	queue_redraw()


func _meter_rect() -> Rect2:
	return Rect2(size.x * 0.5 - 50, size.y * 0.36, 100, size.y * 0.42)


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	var pressed := false
	var released := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		released = not event.pressed
		pos = event.position
	else:
		return
	match kind:
		"timing":
			if pressed:
				_tap_timing()
		"hold":
			if pressed:
				_holding = true
			elif released:
				_holding = false
		"runes":
			if pressed:
				_tap_rune(pos)
	accept_event()


func _tap_timing() -> void:
	var d := absf(_needle - _zone_c)
	var acc := 0.2
	var txt := "Kötü!"
	if d <= _perfect_w * 0.5:
		acc = 1.0
		txt = "KUSURSUZ!"
	elif d <= _zone_w * 0.5:
		acc = lerpf(0.92, 0.74, (d - _perfect_w * 0.5) / maxf(0.001, _zone_w * 0.5 - _perfect_w * 0.5))
		txt = "Harika!"
	elif d <= _zone_w:
		acc = 0.5
		txt = "İdare eder"
	_register_tap(acc, txt)


func _register_tap(acc: float, txt: String) -> void:
	_accs.append(acc)
	_last_tap = _t
	_feedback = txt
	_feedback_t = 0.7
	_feedback_col = Color("#7dffb0") if acc >= 0.9 else (Color("#fff1a8") if acc >= 0.5 else Color("#ff8a8a"))
	AudioManager.sfx("perfect" if acc >= 0.99 else ("tick" if acc >= 0.5 else "fail"), 1.0, -2.0 if acc >= 0.5 else -8.0)
	GameManager.vibrate(20 if acc >= 0.9 else 50)
	if method == "fry":
		_speed *= 1.22
	if method == "grill":
		_flip = 1.0
		_zone_c = _rng.randf_range(0.25, 0.75)
		AudioManager.sfx("grill_hiss", 1.0, -6.0)
	if _accs.size() >= 3:
		var s := 0.0
		for a in _accs:
			s += a
		_finish(s / _accs.size())


func _tap_rune(pos: Vector2) -> void:
	for r in _runes:
		var age: float = _t - float(r["t0"])
		if r["hit"] >= 0.0 or age < 0.0 or age > _rune_w:
			continue
		var rp: Vector2 = _area.position + r["p"] * _area.size
		if rp.distance_to(pos) < 80.0:
			var acc := 1.0 - (age / _rune_w) * 0.45
			r["hit"] = acc
			_feedback = "KUSURSUZ!" if acc > 0.85 else "İyi!"
			_feedback_col = Color("#7dffb0") if acc > 0.85 else Color("#fff1a8")
			_feedback_t = 0.6
			AudioManager.sfx("star", 1.0 + _rune_i * 0.08)
			_rune_i += 1
			FxBurst.spawn(self, rp, "sparkles", 10, Color("#d9b8ff"))
			return


func _finish(q: float) -> void:
	if _done:
		return
	_done = true
	AudioManager.loop_stop("sizzle")
	AudioManager.loop_stop("bubble")
	var txt := "Yandı!"
	var col := Color("#ff8a8a")
	if q >= 0.95:
		txt = "KUSURSUZ!"
		col = Color("#7dffb0")
		AudioManager.sfx("perfect")
		FxBurst.spawn(self, size * Vector2(0.5, 0.45), "confetti", 30)
	elif q >= 0.8:
		txt = "HARİKA!"
		col = Color("#7dffb0")
		AudioManager.sfx("ding")
	elif q >= 0.6:
		txt = "İYİ!"
		col = Color("#fff1a8")
		AudioManager.sfx("ding", 0.9)
	elif q >= 0.4:
		txt = "İDARE EDER"
		col = Color("#ffd28a")
		AudioManager.sfx("ding", 0.8)
	else:
		AudioManager.sfx("fail")
	var res := UIKit.title(txt, 64, col, UIKit.INK, 14)
	res.set_anchors_preset(Control.PRESET_CENTER)
	res.position = Vector2(size.x * 0.5 - 300, size.y * 0.62)
	res.size = Vector2(600, 90)
	add_child(res)
	UIKit.pop_in(res)
	var pct := UIKit.title("Pişirme kalitesi: %%%d" % int(roundf(q * 100.0)), 30, Color.WHITE, UIKit.INK, 8)
	pct.position = Vector2(size.x * 0.5 - 300, size.y * 0.62 + 84)
	pct.size = Vector2(600, 50)
	add_child(pct)
	await get_tree().create_timer(1.1 if not GameManager.fast() else 0.6).timeout
	finished.emit(q)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.05, 0.14, 0.86))
	var card := Rect2(18, size.y * 0.27, size.x - 36, size.y * 0.58)
	DrawKit.shape(self, DrawKit.rrect(card, 44), Color("#2f1f47"), 5.0, 0.12, Color("#140a22"))
	var mc: Color = KitchenStation.METHOD_COLORS.get(method, UIKit.ORANGE)
	match kind:
		"timing":
			var g := _gauge
			var shake := Vector2(sin(_t * 40.0) * 6.0 * _flip, 0)
			var gr := Rect2(g.position + shake, g.size)
			DrawKit.shape(self, DrawKit.rrect(gr.grow(10), 24), Color("#2a1b3d"), 5.0, 0.0)
			DrawKit.fill(self, DrawKit.rrect(gr, 18), Color("#ff6b6b"), 0.15)
			var yz := Rect2(gr.position.x + (_zone_c - _zone_w) * gr.size.x, gr.position.y, _zone_w * 2.0 * gr.size.x, gr.size.y)
			yz = yz.intersection(gr)
			DrawKit.fill(self, DrawKit.rrect(yz, 10), Color("#ffd23f"), 0.15)
			var gz := Rect2(gr.position.x + (_zone_c - _zone_w * 0.5) * gr.size.x, gr.position.y, _zone_w * gr.size.x, gr.size.y).intersection(gr)
			DrawKit.fill(self, DrawKit.rrect(gz, 10), Color("#3ddc84"), 0.15)
			var pz := Rect2(gr.position.x + (_zone_c - _perfect_w * 0.5) * gr.size.x, gr.position.y, _perfect_w * gr.size.x, gr.size.y).intersection(gr)
			DrawKit.fill(self, DrawKit.rrect(pz, 6), Color("#bfffd8"), 0.1)
			DrawKit.outline(self, DrawKit.rrect(gr, 18), UIKit.INK, 4.0)
			var nx := gr.position.x + _needle * gr.size.x
			var needle := PackedVector2Array([Vector2(nx - 14, gr.position.y - 30), Vector2(nx + 14, gr.position.y - 30), Vector2(nx + 4, gr.end.y + 14), Vector2(nx - 4, gr.end.y + 14)])
			DrawKit.shape(self, needle, Color.WHITE, 4.0, 0.0)
			for i in 3:
				var cc := Vector2(size.x * 0.5 - 60 + i * 60, gr.end.y + 70)
				var done := i < _accs.size()
				DrawKit.circle(self, cc, 18, (Color("#3ddc84") if float(_accs[i]) >= 0.74 else (Color("#ffd23f") if float(_accs[i]) >= 0.5 else Color("#ff6b6b"))) if done else Color(1, 1, 1, 0.25), 4.0, 0.1)
			_draw_pan(Vector2(size.x * 0.5, g.position.y - 120), mc)
		"hold":
			var mr := _meter_rect()
			DrawKit.shape(self, DrawKit.rrect(mr.grow(10), 30), Color("#2a1b3d"), 5.0, 0.0)
			var inner := DrawKit.rrect(mr, 24)
			DrawKit.fill(self, inner, Color("#3a2a50"))
			var by := mr.end.y - _band_c * mr.size.y
			var band := Rect2(mr.position.x - 18, by - _band_w * 0.5 * mr.size.y, mr.size.x + 36, _band_w * mr.size.y)
			DrawKit.fill(self, DrawKit.rrect(band, 14), Color(0.25, 1.0, 0.55, 0.35 + 0.15 * sin(_t * 6.0)))
			DrawKit.outline(self, DrawKit.rrect(band, 14), Color("#3ddc84"), 4.0)
			var lv := Rect2(mr.position.x, mr.end.y - _level * mr.size.y, mr.size.x, _level * mr.size.y)
			var fc := Color("#ff7a3d") if method == "boil" else Color("#7fd3ff")
			for p in Geometry2D.intersect_polygons(DrawKit.rrect(lv, 4), inner):
				DrawKit.fill(self, p, fc, 0.2)
			for b in _bubbles:
				var bp := Vector2(mr.position.x + 14 + b["x"] * (mr.size.x - 28), mr.end.y - fposmod(b["y"] + _t * b["s"], 1.0) * _level * mr.size.y)
				draw_arc(bp, 5, 0, TAU, 12, Color(1, 1, 1, 0.6), 2.0, true)
			DrawKit.outline(self, inner, UIKit.INK, 4.0)
			var prog := clampf(_t / _duration, 0.0, 1.0)
			var pr := Rect2(size.x * 0.5 - 200, mr.end.y + 40, 400, 20)
			DrawKit.fill(self, DrawKit.rrect(pr, 10), Color(1, 1, 1, 0.2))
			DrawKit.fill(self, DrawKit.rrect(Rect2(pr.position, Vector2(maxf(20, pr.size.x * prog), pr.size.y)), 10), Color("#fff1a8"))
			var ok := clampf(_in_band / (_duration * 0.62), 0.0, 1.0)
			DrawKit.text(self, "%%%d" % int(ok * 100.0), Vector2(size.x * 0.5 + 170, mr.get_center().y), 40, Color("#7dffb0"), true, UIKit.INK, 8)
			if _holding:
				DrawKit.glow(self, Vector2(size.x * 0.5, mr.end.y + 10), 90, Color(fc, 0.35))
		"runes":
			DrawKit.fill(self, DrawKit.rrect(_area, 40), Color(0.3, 0.15, 0.5, 0.35))
			for r in _runes:
				var age: float = _t - float(r["t0"])
				if r["hit"] >= 0.0 or age < 0.0 or age > _rune_w:
					continue
				var rp: Vector2 = _area.position + r["p"] * _area.size
				var k := 1.0 - age / _rune_w
				DrawKit.glow(self, rp, 90, Color(0.75, 0.5, 1.0, 0.6))
				draw_arc(rp, 30 + 50 * k, 0, TAU, 40, Color(1, 1, 1, 0.8), 5.0, true)
				DrawKit.shape(self, DrawKit.star_pts(rp, 34, 15), Color("#d9b8ff"), 4.0, 0.2)
				DrawKit.circle(self, rp, 10, Color.WHITE, 3.0, 0.0)
	if _feedback_t > 0.0:
		var a := minf(1.0, _feedback_t * 3.0)
		var c := _feedback_col
		c.a = a
		DrawKit.text(self, _feedback, Vector2(size.x * 0.5, size.y * 0.44 - (1.0 - _feedback_t) * 30.0), 46, c, true, Color(0.2, 0.1, 0.1, a), 10)


func _draw_pan(c: Vector2, mc: Color) -> void:
	var bob := sin(_t * 8.0) * 3.0
	DrawKit.glow(self, c + Vector2(0, 30), 120, Color(mc, 0.35))
	match method:
		"bake":
			DrawKit.shape(self, DrawKit.rrect(Rect2(c + Vector2(-110, -70), Vector2(220, 150)), 24), Color("#e8734a"), 5.0, 0.15)
			var win := DrawKit.rrect(Rect2(c + Vector2(-80, -40), Vector2(160, 96)), 14)
			DrawKit.fill(self, win, Color("#2a1b1b"))
			DrawKit.fill(self, DrawKit.rrect(Rect2(c + Vector2(-70, -30), Vector2(140, 76)), 10), Color(1.0, 0.55 + 0.1 * sin(_t * 5.0), 0.2, 0.9))
			DrawKit.outline(self, win, UIKit.INK, 4.0)
		"fry", "grill":
			var pan := DrawKit.ellipse(c + Vector2(0, bob), 120, 44, 40)
			DrawKit.shape(self, pan, Color("#4f5562"), 5.0, 0.15)
			DrawKit.fill(self, DrawKit.ellipse(c + Vector2(0, bob - 2), 96, 32, 36), Color("#2f333b"))
			DrawKit.line(self, c + Vector2(110, bob), c + Vector2(200, bob + 26), UIKit.INK, 18.0)
			DrawKit.line(self, c + Vector2(110, bob), c + Vector2(200, bob + 26), Color("#8a5a3b"), 10.0)
			for i in 5:
				var fp := c + Vector2(-60 + i * 30, bob - 30 - fposmod(_t * 40.0 + i * 13.0, 40.0))
				draw_circle(fp, 4, Color(1, 0.8, 0.3, 0.8), true, -1.0, true)
		_:
			DrawKit.shape(self, DrawKit.ellipse(c, 100, 60, 32), mc, 5.0, 0.2)
