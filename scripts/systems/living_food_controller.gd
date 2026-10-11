class_name LivingFoodController
extends Control
## Canlı yemek sistemi. Hafif durum makinesi: CANLANMA → KAÇIŞ (mini oyun) → YAKALANDI / KAÇTI → ÇÖZÜLDÜ.
## Davranışlar: jump (zıpla), run (koş), hide (saklan), float (süzül), steal (çatal çal), change (kılık değiştir).
## Başarısızlık asla oyunu bozmaz: yemek dağınık ama yine de sunulur.

signal resolved(result: String)

enum State {WAKE, ESCAPE, CAUGHT, ESCAPED, DONE}

const NAMES := {"jump": "ZIPLIYOR!", "run": "KAÇIYOR!", "hide": "SAKLANDI!", "float": "UÇUYOR!", "steal": "ÇATALLARI ÇALDI!", "change": "KILIK DEĞİŞTİRDİ!"}
const TIPS := {"jump": "Zıplayan yemeğe 3 kez dokun!", "run": "Koşan yemeğe 3 kez dokun!", "hide": "Kapaklar karışırken izle, yemeğin altında olduğu kapağa dokun!",
	"float": "Süzülen yemeğe hızlıca dokunarak aşağı çek!", "steal": "Önce 4 mutfak aletini topla, sonra yemeği yakala!", "change": "Gerçek yemek göz kırptı! Karışınca onu bul!"}
const ESCAPE_LINES := ["Yemek mutfaktan kaçtı ama bir garsonun kucağına düştü!", "Yemek kapıya kadar koştu, sonra geri döndü. Biraz dağınık!",
	"Yemek perdeye tırmandı! Sonunda indirdiniz ama sos her yerde.", "Yemek jürinin şapkasına saklandı. Rezalet ama komik!"]

var behavior := "jump"
var item: Dictionary = {}
var state := State.WAKE
var duration := 7.0
var _t := 0.0
var _dish: DishView
var _hits := 0
var _need := 3
var _target := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _cloches: Array = []
var _cloche_real := 0
var _shuffling := false
var _tries := 1
var _utensils: Array = []
var _decoys: Array = []
var _float_y := 0.0
var _area := Rect2()
var _title: Label
var _tip: Label
var _jump_tw: Tween
var _info := ""


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 72


func start(it: Dictionary, beh: String) -> void:
	item = it
	behavior = beh if NAMES.has(beh) else "jump"
	_rng.randomize()
	if ProgressionManager.spec_tier("artist") >= 3:
		duration *= 1.3
		_tries = 2
	await get_tree().process_frame
	_area = Rect2(40, size.y * 0.32, size.x - 80, size.y * 0.42)
	_title = UIKit.title("%s %s" % [it.get("name", "Yemek"), NAMES[behavior]], 40, Color("#fff1a8"), UIKit.INK, 12)
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = size.y * 0.13
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_title)
	_tip = UIKit.title(TIPS[behavior], 26, Color.WHITE, UIKit.INK, 8)
	_tip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tip.offset_top = size.y * 0.13 + 110
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_tip)
	_dish = DishView.new()
	_dish.setup(it)
	_dish.set_alive(true)
	_dish.face_mood = "happy"
	_dish.scale = Vector2(0.75, 0.75)
	_dish.position = _area.get_center() + Vector2(0, 60)
	add_child(_dish)
	AudioManager.sfx("croak" if it.get("tags", []).has("frog") else "boing")
	state = State.ESCAPE
	match behavior:
		"jump":
			_next_jump()
		"run":
			_dish.position = Vector2(_area.position.x, _area.end.y - 40)
		"hide":
			_need = 1
			_setup_cloches()
		"float":
			_need = 10
			_float_y = 0.0
			_dish.position = Vector2(_area.get_center().x, _area.end.y)
			AudioManager.sfx("float")
		"steal":
			_need = 5
			for i in 4:
				_utensils.append({"p": Vector2(_rng.randf_range(_area.position.x + 40, _area.end.x - 40), _rng.randf_range(_area.position.y + 40, _area.end.y - 40)),
					"k": i, "got": false, "rot": _rng.randf_range(-1, 1)})
			AudioManager.sfx("steal")
		"change":
			_need = 1
			_setup_decoys()


var _j_from := Vector2.ZERO
var _j_mid := Vector2.ZERO
var _j_to := Vector2.ZERO


func _next_jump() -> void:
	if state != State.ESCAPE:
		return
	_j_to = Vector2(_rng.randf_range(_area.position.x + 60, _area.end.x - 60), _rng.randf_range(_area.position.y + 120, _area.end.y))
	_j_from = _dish.position
	_j_mid = (_j_from + _j_to) * 0.5 + Vector2(0, -160)
	_jump_tw = create_tween()
	var dur := 0.62 - _hits * 0.08
	_jump_tw.tween_method(_jump_step, 0.0, 1.0, dur)
	_jump_tw.tween_callback(_jump_land)
	_jump_tw.tween_interval(0.15)
	_jump_tw.tween_callback(_jump_again)


func _jump_step(k: float) -> void:
	var a := _j_from.lerp(_j_mid, k)
	var b := _j_mid.lerp(_j_to, k)
	_dish.position = a.lerp(b, k)
	_dish.wobble = 0.1 * sin(k * PI)


func _jump_land() -> void:
	AudioManager.sfx_r("boing", 0.2, -6.0)
	_dish.wobble = -0.18


func _jump_again() -> void:
	_dish.wobble = 0.0
	_next_jump()


func _begin_swap(a: int, b: int, dur: float) -> void:
	var xa: float = _cloches[a]["x"]
	var xb: float = _cloches[b]["x"]
	var t2 := create_tween()
	t2.tween_method(_swap_step.bind(a, b, xa, xb), 0.0, 1.0, dur)


func _set_lift(v: float, i: int) -> void:
	_cloches[i]["lift"] = v
	queue_redraw()


func _swap_step(v: float, a: int, b: int, xa: float, xb: float) -> void:
	_cloches[a]["x"] = lerpf(xa, xb, v)
	_cloches[b]["x"] = lerpf(xb, xa, v)
	queue_redraw()


func _setup_cloches() -> void:
	_dish.visible = false
	for i in 3:
		_cloches.append({"x": _area.position.x + _area.size.x * (0.2 + 0.3 * i), "lift": 0.0})
	_cloche_real = _rng.randi() % 3
	_cloches[_cloche_real]["lift"] = 1.0
	_dish.visible = true
	_dish.position = Vector2(_cloches[_cloche_real]["x"], _area.end.y - 30)
	_dish.scale = Vector2(0.5, 0.5)
	_shuffling = true
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_method(_set_lift.bind(_cloche_real), 1.0, 0.0, 0.35)
	tw.tween_callback(func(): _dish.visible = false)
	var swaps := 5 + (1 if BattleManager.difficulty >= 3 else 0)
	for k in swaps:
		var a := _rng.randi() % 3
		var b := (a + 1 + _rng.randi() % 2) % 3
		tw.tween_callback(func(): AudioManager.sfx("whoosh", 1.3, -10.0))
		tw.tween_callback(_begin_swap.bind(a, b, 0.32 - k * 0.012))
		tw.tween_interval(0.34 - k * 0.012)
	tw.tween_callback(func(): _shuffling = false)


func _setup_decoys() -> void:
	_dish.visible = false
	var n := 4
	for i in n:
		var d := DishView.new()
		d.setup(item)
		d.scale = Vector2(0.45, 0.45)
		d.set_alive(i == 0)
		d.color_shift = 0.0
		d.position = Vector2(_area.position.x + _area.size.x * (0.14 + 0.24 * i), _area.get_center().y + 60)
		add_child(d)
		_decoys.append({"node": d, "real": i == 0})
	_shuffling = true
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_callback(func():
		for dd in _decoys:
			dd["node"].set_alive(true))
	for k in 6:
		var a := _rng.randi() % n
		var b := (a + 1 + _rng.randi() % (n - 1)) % n
		var na: DishView = _decoys[a]["node"]
		var nb: DishView = _decoys[b]["node"]
		tw.tween_callback(func():
			var pa := na.position
			var pb := nb.position
			var t2 := create_tween()
			t2.tween_property(na, "position", pb, 0.3)
			t2.parallel().tween_property(nb, "position", pa, 0.3)
			AudioManager.sfx("whoosh", 1.4, -12.0))
		tw.tween_interval(0.36)
	tw.tween_callback(func(): _shuffling = false)


func _process(delta: float) -> void:
	if state != State.ESCAPE:
		return
	_t += delta
	match behavior:
		"run":
			var spd := 260.0 + _hits * 120.0
			_dish.position.x += spd * delta * (1.0 if int(_t * 0.9) % 2 == 0 else -1.0)
			_dish.position.x = clampf(_dish.position.x, _area.position.x, _area.end.x)
			_dish.position.y = _area.end.y - 40 - absf(sin(_t * 12.0)) * 30.0
			_dish.rotation = sin(_t * 12.0) * 0.12
		"float":
			_float_y += delta * (0.16 + BattleManager.difficulty * 0.01)
			_float_y = clampf(_float_y, 0.0, 1.0)
			_dish.position = Vector2(_area.get_center().x + sin(_t * 2.0) * 120.0, lerpf(_area.end.y, _area.position.y - 60, _float_y))
			if _float_y >= 1.0:
				_resolve(false)
		"steal":
			_dish.position = _area.get_center() + Vector2(cos(_t * 1.8) * _area.size.x * 0.38, sin(_t * 2.6) * _area.size.y * 0.3) + Vector2(0, 40)
	if _t >= duration and state == State.ESCAPE and not _shuffling:
		_resolve(false)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if state != State.ESCAPE:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var pos: Vector2 = event.position
	accept_event()
	match behavior:
		"jump", "run", "float":
			if pos.distance_to(_dish.position + Vector2(0, -40)) < 110.0:
				_hits += 1
				_pat(pos)
				if behavior == "float":
					_float_y = maxf(0.0, _float_y - 0.12)
				if _hits >= _need:
					_resolve(true)
		"hide":
			if _shuffling:
				return
			for i in _cloches.size():
				var cx: float = _cloches[i]["x"]
				if absf(pos.x - cx) < 90.0 and absf(pos.y - (_area.end.y - 70)) < 120.0:
					var tw := create_tween()
					tw.tween_method(_set_lift.bind(i), 0.0, 1.0, 0.25)
					if i == _cloche_real:
						_dish.position = Vector2(cx, _area.end.y - 30)
						_dish.visible = true
						_resolve(true)
					else:
						_tries -= 1
						AudioManager.sfx("fail", 1.2, -6.0)
						if _tries <= 0:
							_dish.position = Vector2(_cloches[_cloche_real]["x"], _area.end.y - 30)
							_dish.visible = true
							_cloches[_cloche_real]["lift"] = 1.0
							_resolve(false)
					return
		"steal":
			for u in _utensils:
				if not u["got"] and pos.distance_to(u["p"]) < 70.0:
					u["got"] = true
					_hits += 1
					_pat(pos)
					return
			if _hits >= 4 and pos.distance_to(_dish.position + Vector2(0, -40)) < 110.0:
				_hits += 1
				_pat(pos)
				_resolve(true)
		"change":
			if _shuffling:
				return
			for dd in _decoys:
				var n: DishView = dd["node"]
				if pos.distance_to(n.position + Vector2(0, -30)) < 90.0:
					if dd["real"]:
						_dish.position = n.position
						_resolve(true)
					else:
						_tries -= 1
						n.face_mood = "angry"
						n.redraw()
						AudioManager.sfx("fail", 1.2, -6.0)
						if _tries <= 0:
							_resolve(false)
					return


func _pat(pos: Vector2) -> void:
	AudioManager.sfx_r("pop", 0.15)
	GameManager.vibrate(18)
	FxBurst.spawn(self, pos, "stars", 6)
	if _dish:
		_dish.wobble = -0.2
		var tw := create_tween()
		tw.tween_property(_dish, "wobble", 0.0, 0.25)


func _resolve(caught: bool) -> void:
	if state != State.ESCAPE:
		return
	state = State.CAUGHT if caught else State.ESCAPED
	if _jump_tw and _jump_tw.is_valid():
		_jump_tw.kill()
	for dd in _decoys:
		if not dd["real"]:
			dd["node"].visible = false
		else:
			dd["node"].face_mood = "happy" if caught else "scared"
	var txt := "YAKALANDI!" if caught else "KAÇTI!"
	var res := UIKit.title(txt, 64, Color("#7dffb0") if caught else Color("#ff8a8a"), UIKit.INK, 14)
	res.position = Vector2(0, size.y * 0.76)
	res.size = Vector2(size.x, 80)
	add_child(res)
	UIKit.pop_in(res)
	if caught:
		AudioManager.sfx("catch")
		FxBurst.spawn(self, _dish.position + Vector2(0, -40), "confetti", 26)
		if _dish:
			_dish.face_mood = "scared"
			_dish.redraw()
	else:
		AudioManager.sfx("escape")
		_info = ESCAPE_LINES[_rng.randi() % ESCAPE_LINES.size()]
		var l := UIKit.title(_info, 26, Color.WHITE, UIKit.INK, 8)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.position = Vector2(30, size.y * 0.76 + 80)
		l.size = Vector2(size.x - 60, 80)
		add_child(l)
	state = State.DONE
	await get_tree().create_timer(1.4 if not GameManager.fast() else 0.8).timeout
	resolved.emit("caught" if caught else "escaped")
	queue_free()


func escape_line() -> String:
	return _info


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.06, 0.12, 0.86))
	if _area.size.x <= 0.0:
		return
	DrawKit.shape(self, DrawKit.rrect(_area.grow(16), 40), Color("#3a2440"), 5.0, 0.12, Color("#140a22"))
	var floor_r := Rect2(_area.position.x - 20, _area.end.y - 10, _area.size.x + 40, 40)
	DrawKit.fill(self, DrawKit.rrect(floor_r, 16), Color(1, 1, 1, 0.12))
	if state == State.ESCAPE or state == State.DONE:
		var left := clampf(1.0 - _t / duration, 0.0, 1.0)
		var tb := Rect2(size.x * 0.5 - 200, _area.position.y - 50, 400, 18)
		DrawKit.fill(self, DrawKit.rrect(tb, 9), Color(1, 1, 1, 0.2))
		DrawKit.fill(self, DrawKit.rrect(Rect2(tb.position, Vector2(maxf(18, tb.size.x * left), tb.size.y)), 9), Color("#ffd23f") if left > 0.3 else Color("#ff6b6b"))
		if behavior in ["jump", "run", "float"]:
			for i in _need:
				if _need > 5 and i % 2 == 1:
					continue
				var k := i if _need <= 5 else i / 2
				var cnt := _need if _need <= 5 else _need / 2
				var cc := Vector2(size.x * 0.5 - (cnt - 1) * 26 + k * 52, _area.position.y - 90)
				var got := _hits > i
				DrawKit.circle(self, cc, 14, Color("#3ddc84") if got else Color(1, 1, 1, 0.25), 3.0, 0.1)
	match behavior:
		"hide":
			for c in _cloches:
				var cx: float = c["x"]
				var lift: float = c["lift"]
				var base := Vector2(cx, _area.end.y - 10 - lift * 120.0)
				var dome := DrawKit.arc(base, 70, 84, PI, TAU, 24)
				DrawKit.shape(self, dome, Color("#cfd8e3"), 5.0, 0.25)
				DrawKit.line(self, base + Vector2(-76, 0), base + Vector2(76, 0), UIKit.INK, 12.0)
				DrawKit.line(self, base + Vector2(-76, 0), base + Vector2(76, 0), Color("#9aa6b2"), 6.0)
				DrawKit.circle(self, base + Vector2(0, -88), 12, Color("#9aa6b2"), 4.0)
				DrawKit.shine(self, base + Vector2(-34, -54), 12, 24, 0.5, 0.4)
		"steal":
			for u in _utensils:
				if u["got"]:
					continue
				var p: Vector2 = u["p"]
				var dir := Vector2(cos(u["rot"]), sin(u["rot"]))
				DrawKit.line(self, p - dir * 40, p + dir * 40, UIKit.INK, 14.0)
				DrawKit.line(self, p - dir * 40, p + dir * 40, Color("#dfe6ee"), 7.0)
				match int(u["k"]):
					0:
						for k2 in 3:
							var off := dir.orthogonal() * (k2 - 1) * 7.0
							DrawKit.line(self, p + dir * 40 + off, p + dir * 58 + off, Color("#dfe6ee"), 4.0)
					1:
						DrawKit.shape(self, DrawKit.ellipse(p + dir * 50, 14, 10, 16, dir.angle()), Color("#dfe6ee"), 4.0, 0.2)
					2:
						for k3 in 3:
							draw_arc(p + dir * 52, 8 + k3 * 4, 0, TAU, 16, Color("#dfe6ee"), 2.5, true)
					_:
						DrawKit.shape(self, PackedVector2Array([p + dir * 38 - dir.orthogonal() * 6, p + dir * 70, p + dir * 38 + dir.orthogonal() * 8]), Color("#eef3f8"), 3.0, 0.2)
