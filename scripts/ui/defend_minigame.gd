class_name DefendMinigame
extends Control
## Sabotaj savunması: üç kalkan rününe zamanında dokun. Hepsi = engel, hızlı hepsi = kusursuz.

signal finished(hits: int, perfect: bool)

var color := Color("#4a7dff")
var ability_name := ""
var window := 1.25
var _runes: Array = []
var _t := 0.0
var _done := false
var _rng := RandomNumberGenerator.new()
var _hits := 0
var _fast := 0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 75


func start(ab_color: Color, ab_name: String) -> void:
	color = ab_color
	ability_name = ab_name
	_rng.randomize()
	if ProgressionManager.spec_tier("defender") >= 1:
		window *= 1.4
	for i in 3:
		_runes.append({"p": Vector2(_rng.randf_range(0.18, 0.82), _rng.randf_range(0.34, 0.74)), "t0": 0.7 + i * window * 0.85, "hit": -1.0})
	var t := UIKit.title("SAVUN!", 64, Color.WHITE, UIKit.INK, 14)
	t.set_anchors_preset(Control.PRESET_TOP_WIDE)
	t.offset_top = GameManager.screen_size.y * 0.14
	add_child(t)
	var tip := UIKit.title("Kalkan rünlerine sönmeden dokun!", 28, Color("#fff1a8"), UIKit.INK, 8)
	tip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tip.offset_top = GameManager.screen_size.y * 0.14 + 80
	add_child(tip)
	AudioManager.sfx("shield", 0.8)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var pending := false
	for r in _runes:
		var age: float = _t - float(r["t0"])
		if r["hit"] < 0.0:
			if age > window:
				r["hit"] = 0.0
				AudioManager.sfx("fail", 1.2, -8.0)
			else:
				pending = true
	if not pending:
		_finish()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var area := _area()
		for r in _runes:
			var age: float = _t - float(r["t0"])
			if r["hit"] >= 0.0 or age < 0.0 or age > window:
				continue
			var rp: Vector2 = area.position + r["p"] * area.size
			if rp.distance_to(event.position) < 90.0:
				r["hit"] = 1.0
				_hits += 1
				if age <= window * 0.55:
					_fast += 1
				AudioManager.sfx("shield", 1.0 + _hits * 0.1)
				GameManager.vibrate(25)
				FxBurst.spawn(self, rp, "sparkles", 12, color.lightened(0.4))
				break
		accept_event()


func _area() -> Rect2:
	return Rect2(30, size.y * 0.3, size.x - 60, size.y * 0.5)


func _finish() -> void:
	if _done:
		return
	_done = true
	var perfect := _hits >= 3 and _fast >= 3
	var txt := "KUSURSUZ SAVUNMA!" if perfect else ("ENGELLENDİ!" if _hits >= 3 else ("KISMEN!" if _hits == 2 else "DELİNDİ!"))
	var res := UIKit.title(txt, 56, Color("#7dffb0") if _hits >= 3 else (Color("#fff1a8") if _hits == 2 else Color("#ff8a8a")), UIKit.INK, 14)
	res.position = Vector2(0, size.y * 0.6)
	res.size = Vector2(size.x, 80)
	add_child(res)
	UIKit.pop_in(res)
	await get_tree().create_timer(0.9 if not GameManager.fast() else 0.5).timeout
	finished.emit(_hits, perfect)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.04, 0.16, 0.86))
	var area := _area()
	DrawKit.shape(self, DrawKit.rrect(area.grow(16), 40), Color("#1f2650"), 5.0, 0.12, Color("#0a0f22"))
	DrawKit.glow(self, area.get_center(), area.size.x * 0.6, Color(color, 0.2))
	for r in _runes:
		var age: float = _t - float(r["t0"])
		if r["hit"] >= 0.0 or age < 0.0 or age > window:
			continue
		var rp: Vector2 = area.position + r["p"] * area.size
		var k := 1.0 - age / window
		DrawKit.glow(self, rp, 110, Color(color, 0.55))
		draw_arc(rp, 40 + 60 * k, 0, TAU, 48, Color(1, 1, 1, 0.85), 6.0, true)
		var sh := PackedVector2Array()
		sh.append(rp + Vector2(0, -44))
		sh.append(rp + Vector2(36, -30))
		sh.append_array(DrawKit.quad(rp + Vector2(36, -30), rp + Vector2(34, 22), rp + Vector2(0, 46), 8))
		sh.append_array(DrawKit.quad(rp + Vector2(0, 46), rp + Vector2(-34, 22), rp + Vector2(-36, -30), 8))
		DrawKit.shape(self, sh, color.lightened(0.15), 5.0, 0.25)
		DrawKit.shine(self, rp + Vector2(-12, -16), 7, 12, 0.5, 0.3)
	for i in 3:
		var cc := Vector2(size.x * 0.5 - 60 + i * 60, area.end.y + 40)
		var r2: Dictionary = _runes[i]
		var col := Color(1, 1, 1, 0.25)
		if r2["hit"] > 0.5:
			col = Color("#3ddc84")
		elif r2["hit"] >= 0.0:
			col = Color("#ff6b6b")
		DrawKit.circle(self, cc, 16, col, 4.0, 0.1)
