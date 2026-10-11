class_name CharacterFigure
extends Node2D
## Katmanlı, prosedürel 2D karakter (göğüs hizasından yukarısı).
## Parça sistemi: kafa, gözler, kaşlar, burun, ağız, saç (ön/arka), şapka, gövde, önlük, aksesuar, kollar.
## Yeniden kullanılabilir ifade sistemi (EXPR), kol pozları (POSES), mutasyon katmanları ve tepki animasyonları.
## Orijin: gövdenin alt ortası. Kafa merkezi HC'de.

signal reaction_finished(reaction: String)

const HC := Vector2(0, -205)
const W := 4.5
const INK := Color("#3b2417")

const EXPR := {
	"neutral": ["normal", "neutral", "smile_small"],
	"happy": ["normal", "raised", "smile"],
	"laugh": ["happy", "raised", "laugh"],
	"love": ["heart", "raised", "smile"],
	"surprised": ["wide", "high", "o"],
	"shocked": ["wide", "high", "O"],
	"disgust": ["sly", "angry", "wavy"],
	"angry": ["angry", "angry", "grit"],
	"sad": ["sad", "sad", "frown"],
	"cry": ["closed", "sad", "cry"],
	"dizzy": ["dizzy", "neutral", "wavy"],
	"chew": ["happy", "raised", "chew"],
	"smug": ["sly", "smug", "smirk"],
	"determined": ["normal", "angry_soft", "flat"],
	"goofy": ["normal", "raised", "tongue"],
	"wink": ["wink", "raised", "grin"],
	"scared": ["wide", "sad", "grit"],
	"grin": ["normal", "raised", "grin"],
	"sleepy": ["sly", "neutral", "flat"],
	"evil": ["angry", "angry", "grin"],
}

const POSES := {
	"idle": [Vector2(0.22, 0.12), Vector2(0.22, 0.12)],
	"up": [Vector2(2.6, 0.35), Vector2(2.6, 0.35)],
	"present": [Vector2(0.5, -1.4), Vector2(0.5, -1.4)],
	"stir": [Vector2(0.22, 0.12), Vector2(0.65, -1.25)],
	"point": [Vector2(0.22, 0.12), Vector2(1.95, 0.1)],
	"wave": [Vector2(0.22, 0.12), Vector2(2.5, 0.5)],
	"hips": [Vector2(0.75, -1.9), Vector2(0.75, -1.9)],
	"think": [Vector2(0.22, 0.12), Vector2(0.3, -2.5)],
	"loose": [Vector2(1.1, 0.5), Vector2(1.1, 0.5)],
	"shrug": [Vector2(1.0, -2.2), Vector2(1.0, -2.2)],
	"cast": [Vector2(0.22, 0.12), Vector2(2.2, -0.6)],
}

var spec: Dictionary = {}
var expression := "happy"
var base_expression := "happy"
var mutation := ""
var pose_name := "idle"
var look := Vector2.ZERO
var talking := 0.0
var soot := 0.0
var bob_amount := 3.0
var idle_enabled := true
var portrait := false

var _rig: Node2D
var _t := 0.0
var _blink_t := 2.5
var _blinking := 0.0
var _mouth_open := false
var _mouth_t := 0.0
var _expr_hold := 0.0
var _arms := [Vector2(0.22, 0.12), Vector2(0.22, 0.12)]
var _arm_target := [Vector2(0.22, 0.12), Vector2(0.22, 0.12)]
var _tween: Tween
var _anim_offset := Vector2.ZERO
var _anim_rot := 0.0
var _anim_scale := Vector2.ONE
var _float := 0.0
var _flicker_t := 0.0
var _ghost_mod := Color(1, 1, 1, 1)
var holder: Node2D


func _init() -> void:
	_rig = Node2D.new()
	_rig.name = "Rig"
	add_child(_rig)
	_rig.draw.connect(_draw_rig)
	holder = Node2D.new()
	holder.name = "Holder"
	_rig.add_child(holder)
	holder.position = Vector2(0, -60)


func setup(s: Dictionary) -> void:
	spec = s
	base_expression = s.get("expression", "happy")
	expression = base_expression
	redraw()


func redraw() -> void:
	if _rig:
		_rig.queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	var bob := sin(_t * 2.2) * bob_amount if idle_enabled else 0.0
	var breath := 1.0 + sin(_t * 2.2 + 0.6) * 0.008
	if mutation == "ghost_form":
		bob += sin(_t * 1.6) * 8.0
	_rig.position = _anim_offset + Vector2(0, bob - _float)
	_rig.rotation = _anim_rot
	_rig.scale = _anim_scale * Vector2(1.0, breath)
	var need := false
	# göz kırpma
	_blink_t -= delta
	if _blinking > 0.0:
		_blinking -= delta
		if _blinking <= 0.0:
			need = true
	elif _blink_t <= 0.0:
		_blinking = 0.12
		_blink_t = randf_range(2.0, 5.0)
		need = true
	# konuşma / çiğneme
	if talking > 0.0 or expression == "chew":
		talking = maxf(0.0, talking - delta)
		_mouth_t -= delta
		if _mouth_t <= 0.0:
			_mouth_t = 0.11 if expression != "chew" else 0.16
			_mouth_open = not _mouth_open
			need = true
		if talking <= 0.0 and expression != "chew" and _mouth_open:
			_mouth_open = false
			need = true
	# geçici ifade
	if _expr_hold > 0.0:
		_expr_hold -= delta
		if _expr_hold <= 0.0:
			expression = base_expression
			need = true
	# kollar
	var stir_off := 0.0
	if pose_name == "stir":
		stir_off = sin(_t * 7.0) * 0.28
	elif pose_name == "wave":
		stir_off = sin(_t * 9.0) * 0.35
	for i in 2:
		var tgt: Vector2 = _arm_target[i]
		if i == 1 and stir_off != 0.0:
			tgt.y += stir_off
		var cur_a: Vector2 = _arms[i]
		var nv := cur_a.lerp(tgt, minf(1.0, delta * 12.0))
		if nv.distance_to(cur_a) > 0.002:
			need = true
		_arms[i] = nv
	if mutation == "flaming_hair" or "aura" in spec.get("extras", []):
		_flicker_t -= delta
		if _flicker_t <= 0.0:
			_flicker_t = 0.08
			need = true
	if need:
		_rig.queue_redraw()


# ------------------------------------------------------------------ genel API
func set_expression(e: String, hold := 0.0) -> void:
	if not EXPR.has(e):
		e = "happy"
	expression = e
	_expr_hold = hold
	if hold <= 0.0:
		base_expression = e
	redraw()


func set_pose(p: String) -> void:
	if not POSES.has(p):
		p = "idle"
	pose_name = p
	_arm_target = [POSES[p][0], POSES[p][1]]


func set_mutation(m: String) -> void:
	mutation = m
	if m == "ghost_form":
		_rig.modulate = Color(0.78, 0.9, 1.2, 0.66)
	else:
		_rig.modulate = Color(1, 1, 1, 1)
	redraw()


func talk(sec := 1.2) -> void:
	talking = sec
	_mouth_t = 0.0


func head_top() -> Vector2:
	return Vector2(0, _head_top() - 30.0) * scale + Vector2(0, 0)


func head_pos_local() -> Vector2:
	return HC


func hold(node: Node2D) -> void:
	for c in holder.get_children():
		c.queue_free()
	if node != null:
		holder.add_child(node)


# ------------------------------------------------------------------ yardımcılar
func _sv(key: String, def: Variant) -> Variant:
	return spec.get(key, def)


func _col(key: String, def: String) -> Color:
	var v: Variant = spec.get(key, def)
	if v is Color:
		return v
	return Color(str(v))


func _has_extra(e: String) -> bool:
	return spec.get("extras", []).has(e)


func _has_acc(a: String) -> bool:
	return spec.get("acc", []).has(a)


func _skin() -> Color:
	var c := _col("skin", "#f7c9a0")
	if mutation == "frog":
		return Color("#7ccf5a")
	if mutation == "vampire_teeth":
		return c.lerp(Color("#e6e0f0"), 0.55)
	return c


func _ink() -> Color:
	return INK


func _head_kind() -> String:
	return str(spec.get("head", "round"))


func _head_rx() -> float:
	match _head_kind():
		"wide":
			return 84.0
		"long":
			return 70.0
		"robot":
			return 76.0
		"alien":
			return 92.0
	return 76.0


func _head_top() -> float:
	match _head_kind():
		"wide":
			return HC.y + 4.0 - 76.0
		"long":
			return HC.y - 84.0
		"robot":
			return HC.y - 72.0
		"alien":
			return HC.y - 110.0
	return HC.y - 79.0


func _head_pts() -> PackedVector2Array:
	match _head_kind():
		"wide":
			return DrawKit.ellipse(HC + Vector2(0, 4), 84, 76, 48)
		"long":
			return DrawKit.ellipse(HC, 70, 84, 48)
		"robot":
			return DrawKit.rrect(Rect2(HC - Vector2(76, 72), Vector2(152, 144)), 32, 6)
		"alien":
			return DrawKit.smooth(PackedVector2Array([HC + Vector2(-94, -24), HC + Vector2(-82, -84), HC + Vector2(0, -112),
				HC + Vector2(82, -84), HC + Vector2(94, -24), HC + Vector2(62, 58), HC + Vector2(0, 92), HC + Vector2(-62, 58)]), 3)
	return DrawKit.ellipse(HC, 76, 79, 48)


func _eye_centers() -> Array:
	match _head_kind():
		"wide":
			return [HC + Vector2(-30, -6), HC + Vector2(30, -6)]
		"long":
			return [HC + Vector2(-25, -4), HC + Vector2(25, -4)]
		"alien":
			return [HC + Vector2(-38, -10), HC + Vector2(38, -10)]
	return [HC + Vector2(-27, -6), HC + Vector2(27, -6)]


func _mouth_center() -> Vector2:
	match _head_kind():
		"wide":
			return HC + Vector2(0, 38)
		"long":
			return HC + Vector2(0, 44)
		"alien":
			return HC + Vector2(0, 52)
		"robot":
			return HC + Vector2(0, 32)
	return HC + Vector2(0, 38)


func _torso_pts() -> PackedVector2Array:
	return DrawKit.smooth(PackedVector2Array([Vector2(-100, 0), Vector2(-105, -52), Vector2(-97, -102), Vector2(-72, -130),
		Vector2(-30, -140), Vector2(30, -140), Vector2(72, -130), Vector2(97, -102), Vector2(105, -52), Vector2(100, 0)]), 2)


func _clip_fill(r: CanvasItem, poly: PackedVector2Array, clip: PackedVector2Array, col: Color) -> void:
	for p in Geometry2D.intersect_polygons(poly, clip):
		if p.size() >= 3:
			r.draw_colored_polygon(p, col)


# ------------------------------------------------------------------ ana çizim
func _draw_rig() -> void:
	var r := _rig
	var sk := _skin()
	var ex: Array = EXPR.get(expression, EXPR["happy"])
	var eyes_mode: String = ex[0]
	if _blinking > 0.0 and ["normal", "wide", "sly", "angry", "sad", "heart", "wink"].has(eyes_mode):
		eyes_mode = "blink"
	if _has_extra("aura"):
		var pulse := 0.4 + 0.12 * sin(_t * 3.0)
		DrawKit.glow(r, HC + Vector2(0, 30), 250, Color(0.55, 0.25, 1.0, pulse))
	if _has_extra("wings"):
		_wings(r)
	_body_back(r)
	_hair_back(r)
	if mutation == "giant_ears":
		_giant_ears(r, sk)
	_neck(r, sk)
	_body(r)
	_apron(r)
	_neck_acc(r)
	_ears(r, sk)
	DrawKit.shape(r, _head_pts(), sk, W, 0.1, _ink())
	if _head_kind() == "robot":
		_robot_head_details(r)
	_face(r, sk, ex, eyes_mode)
	_hair_front(r)
	_hat(r)
	_extras_front(r)
	_mutation_front(r, sk)
	_arms_draw(r, sk)
	if soot > 0.0:
		_soot(r)


# ------------------------------------------------------------------ arka katman
func _wings(r: CanvasItem) -> void:
	var flap := sin(_t * 6.0) * 0.12
	for s in [-1.0, 1.0]:
		var c1 := Color(1.0, 0.75, 0.95, 0.5)
		var c2 := Color(0.7, 0.95, 1.0, 0.45)
		var up := DrawKit.ellipse(Vector2(s * 120, -170), 78, 40, 28, s * (0.55 + flap))
		DrawKit.fill(r, up, c1)
		DrawKit.outline(r, up, Color(1, 1, 1, 0.9), 3.0)
		var lo := DrawKit.ellipse(Vector2(s * 104, -96), 52, 28, 24, s * (-0.35 - flap))
		DrawKit.fill(r, lo, c2)
		DrawKit.outline(r, lo, Color(1, 1, 1, 0.9), 3.0)


func _body_back(r: CanvasItem) -> void:
	var body: String = _sv("body", "chef")
	if body == "cape":
		var outer := _col("body_color", "#1c1424")
		var inner := _col("body_color2", "#b3122e")
		for s in [-1.0, 1.0]:
			var pts := PackedVector2Array([Vector2(s * 40, -128), Vector2(s * 70, -132), Vector2(s * 128, -310), Vector2(s * 96, -250), Vector2(s * 58, -190)])
			DrawKit.shape(r, pts, outer, W, 0.1, _ink())
			var inn := PackedVector2Array([Vector2(s * 52, -140), Vector2(s * 70, -142), Vector2(s * 116, -286), Vector2(s * 94, -246), Vector2(s * 64, -190)])
			DrawKit.fill(r, inn, inner, 0.2)
	if _has_extra("hood"):
		var hood := DrawKit.smooth(PackedVector2Array([HC + Vector2(-104, 60), HC + Vector2(-112, -30), HC + Vector2(-80, -100), HC + Vector2(-10, -150),
			HC + Vector2(20, -128), HC + Vector2(84, -100), HC + Vector2(112, -30), HC + Vector2(104, 60), HC + Vector2(60, 90), HC + Vector2(-60, 90)]), 2)
		DrawKit.shape(r, hood, _col("body_color", "#1a1426"), W, 0.15, _ink())
	if str(_sv("hat", "")) == "ghost_sheet":
		var sheet := DrawKit.smooth(PackedVector2Array([HC + Vector2(-100, 70), HC + Vector2(-104, -20), HC + Vector2(-80, -96), HC + Vector2(0, -126),
			HC + Vector2(80, -96), HC + Vector2(104, -20), HC + Vector2(100, 70), HC + Vector2(60, 96), HC + Vector2(-60, 96)]), 2)
		DrawKit.shape(r, sheet, Color("#f4f6ff"), W, 0.08, _ink())
	if str(_sv("hat", "")) == "headscarf":
		var sc := _col("hat_color", "#7a3b8f")
		var back := DrawKit.smooth(PackedVector2Array([HC + Vector2(-92, 50), HC + Vector2(-98, -20), HC + Vector2(-74, -86), HC + Vector2(0, -104),
			HC + Vector2(74, -86), HC + Vector2(98, -20), HC + Vector2(92, 50), HC + Vector2(50, 92), HC + Vector2(-50, 92)]), 2)
		DrawKit.shape(r, back, sc, W, 0.12, _ink())
		_pattern_dots(r, back, _col("hat_color2", "#ffd23f"), 22.0, 4.0)


func _pattern_dots(r: CanvasItem, clip: PackedVector2Array, col: Color, step: float, rad: float) -> void:
	var minp := Vector2(INF, INF)
	var maxp := Vector2(-INF, -INF)
	for p in clip:
		minp = minp.min(p)
		maxp = maxp.max(p)
	var row := 0
	var y := minp.y + step * 0.5
	while y < maxp.y:
		var x := minp.x + (step * 0.5 if row % 2 == 0 else step)
		while x < maxp.x:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), clip):
				r.draw_circle(Vector2(x, y), rad, col, true, -1.0, true)
			x += step
		y += step * 0.85
		row += 1


func _hair_back(r: CanvasItem) -> void:
	var hs: String = _sv("hair", "short")
	var hcol := _col("hair_color", "#5a3420")
	match hs:
		"long", "witch_long":
			var ln := 150.0 if hs == "witch_long" else 120.0
			var pts := DrawKit.smooth(PackedVector2Array([HC + Vector2(-82, -30), HC + Vector2(-98, 40), HC + Vector2(-94, ln - 20), HC + Vector2(-70, ln),
				HC + Vector2(70, ln), HC + Vector2(94, ln - 20), HC + Vector2(98, 40), HC + Vector2(82, -30), HC + Vector2(0, -94)]), 2)
			DrawKit.shape(r, pts, hcol, W, 0.2, _ink())
		"fairy":
			var pts2 := PackedVector2Array()
			for i in 15:
				var a := PI * 0.95 + i * (PI * 1.1) / 14.0
				pts2.append(HC + Vector2(cos(a) * 92, sin(a) * 90 - 10))
			for i in 9:
				var x := 96.0 - i * 24.0
				pts2.append(HC + Vector2(x, 128 + (12.0 if i % 2 == 0 else -4.0)))
			DrawKit.shape(r, DrawKit.smooth(pts2, 2), hcol, W, 0.2, _ink())
		"afro":
			DrawKit.shape(r, DrawKit.blob(HC + Vector2(0, -36), 112, 7, 0.07, 18), hcol, W, 0.2, _ink())
		"pigtails":
			for s in [-1.0, 1.0]:
				var tail := DrawKit.ellipse(HC + Vector2(s * 96, 46), 24, 44, 24, s * 0.35)
				DrawKit.shape(r, tail, hcol, W, 0.2, _ink())
				DrawKit.circle(r, HC + Vector2(s * 84, 8), 9, Color("#ff5fa2"), 3.0)
		"bun", "granny_bun", "bun_pencil":
			if not _hat_covers_top():
				if hs == "bun_pencil":
					DrawKit.line(r, HC + Vector2(-44, -128), HC + Vector2(40, -78), _ink(), 12.0)
					DrawKit.line(r, HC + Vector2(-44, -128), HC + Vector2(40, -78), Color("#ffd23f"), 6.0)
					DrawKit.dot(r, HC + Vector2(-44, -128), 4.0, Color("#ff7ab8"))
				DrawKit.circle(r, HC + Vector2(0, -92), 32, hcol, W, 0.2, _ink())


func _hat_covers_top() -> bool:
	return ["toque", "small_toque", "witch", "tricorne", "headscarf", "dark_toque", "wizard", "mushroom", "ghost_sheet", "beret"].has(str(_sv("hat", "none")))


func _giant_ears(r: CanvasItem, sk: Color) -> void:
	for s in [-1.0, 1.0]:
		var e := DrawKit.ellipse(HC + Vector2(s * (_head_rx() + 22), -6), 40, 58, 30, s * 0.25)
		DrawKit.shape(r, e, sk, W, 0.1, _ink())
		DrawKit.fill(r, DrawKit.ellipse(HC + Vector2(s * (_head_rx() + 24), -4), 22, 38, 24, s * 0.25), Color("#ff9fb5"))


func _neck(r: CanvasItem, sk: Color) -> void:
	if _head_kind() == "robot":
		DrawKit.shape(r, DrawKit.rrect(Rect2(-20, -158, 40, 36), 6), Color("#7d8a9b"), W, 0.2, _ink())
		return
	DrawKit.shape(r, DrawKit.rrect(Rect2(-24, -160, 48, 40), 10), sk.darkened(0.08), W, 0.0, _ink())


# ------------------------------------------------------------------ gövde
func _body(r: CanvasItem) -> void:
	var body: String = _sv("body", "chef")
	var c := _col("body_color", "#f7f7f2")
	var c2 := _col("body_color2", "#e0444f")
	var torso := _torso_pts()
	var ink := _ink()
	match body:
		"robot":
			DrawKit.shape(r, torso, c, W, 0.3, ink)
			DrawKit.shape(r, DrawKit.rrect(Rect2(-48, -112, 96, 62), 12), Color("#26303d"), W, 0.1, ink)
			var lights := [Color("#ff4f5e"), Color("#ffd23f"), Color("#3ddc84")]
			for i in 3:
				var on := int(_t * 3.0 + i) % 3 != 0
				var lc: Color = lights[i] if on else Color(lights[i]).darkened(0.6)
				DrawKit.circle(r, Vector2(-26 + i * 26, -92), 8, lc, 2.5, 0.0)
				if on:
					DrawKit.glow(r, Vector2(-26 + i * 26, -92), 18, Color(lc, 0.5))
			for i in 4:
				r.draw_line(Vector2(-34, -70 + i * 5), Vector2(34, -70 + i * 5), Color("#5c6b7d"), 2.0, true)
			for p in [Vector2(-80, -30), Vector2(80, -30), Vector2(-70, -116), Vector2(70, -116)]:
				DrawKit.circle(r, p, 5, Color("#dfe6ee"), 2.0, 0.0)
		"robe":
			DrawKit.shape(r, torso, c, W, 0.18, ink)
			_clip_fill(r, PackedVector2Array([Vector2(-30, -142), Vector2(30, -142), Vector2(0, -78)]), torso, Color("#2b1d3a"))
			DrawKit.poly_line(r, PackedVector2Array([Vector2(-32, -140), Vector2(0, -76), Vector2(32, -140)]), c2, 6.0)
			var rng := RandomNumberGenerator.new()
			rng.seed = 11
			for i in 7:
				var p := Vector2(rng.randf_range(-80, 80), rng.randf_range(-110, -10))
				if Geometry2D.is_point_in_polygon(p, torso) and absf(p.x) > 22:
					DrawKit.fill(r, DrawKit.star_pts(p, 9, 4), c2)
		"labcoat":
			DrawKit.shape(r, torso, c, W, 0.1, ink)
			_clip_fill(r, PackedVector2Array([Vector2(-30, -142), Vector2(30, -142), Vector2(0, -40)]), torso, c2)
			for s in [-1.0, 1.0]:
				var lap := PackedVector2Array([Vector2(s * 30, -142), Vector2(s * 4, -40), Vector2(s * 20, -40), Vector2(s * 56, -118)])
				DrawKit.shape(r, lap, c.darkened(0.06), 3.5, 0.0, ink)
			DrawKit.shape(r, DrawKit.rrect(Rect2(-80, -84, 38, 34), 5), c.darkened(0.04), 3.0, 0.0, ink)
			DrawKit.line(r, Vector2(-70, -84), Vector2(-70, -100), Color("#4a7dff"), 5.0)
			DrawKit.line(r, Vector2(-58, -84), Vector2(-58, -104), Color("#ff4f5e"), 5.0)
		"cardigan":
			DrawKit.shape(r, torso, c, W, 0.15, ink)
			_clip_fill(r, PackedVector2Array([Vector2(-22, -142), Vector2(22, -142), Vector2(12, 0), Vector2(-12, 0)]), torso, Color("#f3e3d3"))
			for i in 12:
				var x := -96.0 + i * 16.0
				if absf(x) < 20:
					continue
				r.draw_line(Vector2(x, -120), Vector2(x * 1.02, 0), Color(c.darkened(0.2), 0.5), 2.0, true)
			for y in [-110, -80, -50, -20]:
				DrawKit.circle(r, Vector2(-17, y), 4, Color("#f2c14e"), 2.0, 0.0)
		"cape":
			DrawKit.shape(r, torso, c, W, 0.15, ink)
			_clip_fill(r, PackedVector2Array([Vector2(-26, -142), Vector2(26, -142), Vector2(0, -60)]), torso, Color("#f4f0f8"))
			var bow := PackedVector2Array([Vector2(-22, -136), Vector2(0, -126), Vector2(22, -136), Vector2(22, -116), Vector2(0, -124), Vector2(-22, -116)])
			DrawKit.shape(r, bow, c2, 3.0, 0.1, ink)
			for s in [-1.0, 1.0]:
				DrawKit.shape(r, PackedVector2Array([Vector2(s * 28, -140), Vector2(s * 4, -60), Vector2(s * 20, -56), Vector2(s * 70, -128)]), c.lightened(0.08), 3.0, 0.0, ink)
		"pirate":
			DrawKit.shape(r, torso, Color("#f7f2e8"), W, 0.1, ink)
			var y := -132.0
			while y < 0:
				_clip_fill(r, PackedVector2Array([Vector2(-120, y), Vector2(120, y), Vector2(120, y + 11), Vector2(-120, y + 11)]), torso, c2)
				y += 22.0
			for s in [-1.0, 1.0]:
				var vest := PackedVector2Array([Vector2(s * 26, -136), Vector2(s * 74, -128), Vector2(s * 100, -60), Vector2(s * 100, 0), Vector2(s * 30, 0), Vector2(s * 40, -70)])
				var clipped := Geometry2D.intersect_polygons(vest, torso)
				for cp in clipped:
					DrawKit.shape(r, cp, c, 3.5, 0.15, ink)
			DrawKit.outline(r, torso, ink, W)
			DrawKit.shape(r, DrawKit.rrect(Rect2(-100, -24, 200, 18), 4), Color("#4a2c1a"), 3.0, 0.0, ink)
			DrawKit.shape(r, DrawKit.rrect(Rect2(-14, -28, 28, 26), 4), Color("#f2c14e"), 3.0, 0.1, ink)
		"spacesuit":
			DrawKit.shape(r, torso, c, W, 0.2, ink)
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, -138), 52, 16, 28), Color("#9aa6bd"), W, 0.2, ink)
			DrawKit.circle(r, Vector2(-50, -84), 16, c2, 3.0)
			DrawKit.fill(r, DrawKit.star_pts(Vector2(-50, -84), 10, 4), Color("#fff1a8"))
			r.draw_line(Vector2(0, -122), Vector2(0, 0), Color(c.darkened(0.25)), 3.0, true)
			r.draw_line(Vector2(30, -100), Vector2(80, -100), Color(c2, 0.8), 6.0, true)
		"fairy_dress":
			DrawKit.shape(r, torso, c, W, 0.18, ink)
			for i in 7:
				var a := PI + PI * i / 6.0
				var p := Vector2(0, -136) + Vector2(cos(a) * 42, sin(a) * 6 + 14)
				DrawKit.shape(r, DrawKit.ellipse(p, 16, 10, 16, a + PI / 2), c2, 3.0, 0.1, ink)
			for s in [-1.0, 1.0]:
				r.draw_line(Vector2(s * 20, -100), Vector2(s * 60, -30), Color(c.darkened(0.25)), 3.0, true)
		"cloak":
			DrawKit.shape(r, torso, c, W, 0.2, ink)
			DrawKit.poly_line(r, PackedVector2Array([Vector2(-26, -136), Vector2(-12, 0)]), c2, 7.0)
			DrawKit.poly_line(r, PackedVector2Array([Vector2(26, -136), Vector2(12, 0)]), c2, 7.0)
			DrawKit.circle(r, Vector2(0, -132), 10, c2.lightened(0.2), 3.0)
			DrawKit.glow(r, Vector2(0, -132), 22, Color(c2, 0.6))
		"velvet":
			DrawKit.shape(r, torso, c, W, 0.18, ink)
			_clip_fill(r, PackedVector2Array([Vector2(-28, -142), Vector2(28, -142), Vector2(0, -50)]), torso, Color("#fbf6ff"))
			for s in [-1.0, 1.0]:
				var lap2 := PackedVector2Array([Vector2(s * 28, -142), Vector2(s * 2, -50), Vector2(s * 18, -50), Vector2(s * 62, -120)])
				DrawKit.shape(r, lap2, c.darkened(0.12), 3.5, 0.0, ink)
				DrawKit.poly_line(r, PackedVector2Array([Vector2(s * 62, -120), Vector2(s * 18, -50)]), c2, 4.0)
			for y in [-40, -16]:
				DrawKit.circle(r, Vector2(30, y), 5, c2, 2.0, 0.0)
		_:
			DrawKit.shape(r, torso, c, W, 0.12, ink)
			DrawKit.shape(r, DrawKit.rrect(Rect2(-38, -152, 76, 22), 8), c.darkened(0.04), 3.5, 0.0, ink)
			DrawKit.poly_line(r, DrawKit.bezier(Vector2(-30, -134), Vector2(10, -122), Vector2(32, -86), Vector2(32, 0)), ink, 3.5, false)
			var bc := c.darkened(0.45) if c.get_luminance() > 0.5 else c.lightened(0.5)
			for y in [-100, -66, -32]:
				for x in [8, 54]:
					DrawKit.circle(r, Vector2(x, y), 5.5, bc, 2.0, 0.0)


func _apron(r: CanvasItem) -> void:
	var ap: String = _sv("apron", "")
	if ap == "" or ap == "none":
		return
	var c := _col("apron_color", "#e9e2d0")
	var pts := DrawKit.smooth(PackedVector2Array([Vector2(-44, -110), Vector2(44, -110), Vector2(52, -62), Vector2(74, -24), Vector2(78, 0),
		Vector2(-78, 0), Vector2(-74, -24), Vector2(-52, -62)]), 1)
	var torso := _torso_pts()
	var clip := Geometry2D.intersect_polygons(pts, torso)
	if clip.is_empty():
		return
	var ap_poly: PackedVector2Array = clip[0]
	DrawKit.line(r, Vector2(-40, -108), Vector2(-26, -146), _ink(), 9.0)
	DrawKit.line(r, Vector2(40, -108), Vector2(26, -146), _ink(), 9.0)
	DrawKit.line(r, Vector2(-40, -108), Vector2(-26, -146), c, 4.0)
	DrawKit.line(r, Vector2(40, -108), Vector2(26, -146), c, 4.0)
	DrawKit.fill(r, ap_poly, c, 0.12)
	match ap:
		"striped":
			var x := -80.0
			while x < 80:
				_clip_fill(r, PackedVector2Array([Vector2(x, -120), Vector2(x + 8, -120), Vector2(x + 8, 0), Vector2(x, 0)]), ap_poly, Color("#f4f4f4"))
				x += 20.0
		"rainbow":
			var bands := [Color("#ff5f5f"), Color("#ffb020"), Color("#ffe14a"), Color("#3ddc84"), Color("#4a9dff"), Color("#a25cff")]
			for i in 6:
				var y0 := -110.0 + i * 19.0
				_clip_fill(r, PackedVector2Array([Vector2(-90, y0), Vector2(90, y0), Vector2(90, y0 + 19), Vector2(-90, y0 + 19)]), ap_poly, bands[i])
		"leather":
			var inner := DrawKit.transform_pts(ap_poly, Vector2(0, -6), Vector2(0.88, 0.92))
			DrawKit.outline(r, inner, Color("#d9b48a"), 2.0)
		"pink":
			DrawKit.fill(r, DrawKit.heart_pts(Vector2(0, -50), 14), Color("#ff5fa2"))
		_:
			DrawKit.shape(r, DrawKit.rrect(Rect2(-26, -58, 52, 30), 6), c.darkened(0.06), 3.0, 0.0, _ink())
	DrawKit.outline(r, ap_poly, _ink(), 3.5)


func _neck_acc(r: CanvasItem) -> void:
	var ink := _ink()
	if _has_acc("neckerchief"):
		var nc := _col("acc_color", "#e0444f")
		DrawKit.shape(r, PackedVector2Array([Vector2(-34, -144), Vector2(34, -144), Vector2(0, -98)]), nc, 3.5, 0.15, ink)
		DrawKit.circle(r, Vector2(0, -140), 10, nc.darkened(0.1), 3.0)
	if _has_acc("ascot"):
		var ac := Color("#fbf6ff")
		var fr := DrawKit.smooth(PackedVector2Array([Vector2(-18, -146), Vector2(18, -146), Vector2(24, -120), Vector2(10, -96), Vector2(0, -88), Vector2(-10, -96), Vector2(-24, -120)]), 2)
		DrawKit.shape(r, fr, ac, 3.5, 0.15, ink)
		DrawKit.circle(r, Vector2(0, -126), 7, Color("#f2c14e"), 2.5)
	if _has_acc("bowtie"):
		var bc := _col("acc_color", "#e0444f")
		DrawKit.shape(r, PackedVector2Array([Vector2(-30, -150), Vector2(0, -138), Vector2(-30, -124)]), bc, 3.5, 0.15, ink)
		DrawKit.shape(r, PackedVector2Array([Vector2(30, -150), Vector2(0, -138), Vector2(30, -124)]), bc, 3.5, 0.15, ink)
		DrawKit.circle(r, Vector2(0, -138), 7, bc.darkened(0.15), 3.0)
	if _has_acc("scarf"):
		var sc := _col("acc_color", "#4a9dff")
		DrawKit.shape(r, DrawKit.rrect(Rect2(-44, -158, 88, 26), 12), sc, 3.5, 0.15, ink)
		DrawKit.shape(r, DrawKit.rrect(Rect2(14, -140, 24, 66), 8), sc.darkened(0.08), 3.5, 0.1, ink)


func _ears(r: CanvasItem, sk: Color) -> void:
	var hk := _head_kind()
	if hk == "robot":
		for s in [-1.0, 1.0]:
			DrawKit.shape(r, DrawKit.rrect(Rect2(s * 78 - 9, HC.y - 22, 18, 44), 6), Color("#8a97a8"), W, 0.2, _ink())
		return
	if hk == "alien" or _has_extra("hood") or mutation == "giant_ears":
		return
	if ["headscarf", "ghost_sheet"].has(str(_sv("hat", ""))):
		return
	var rx := _head_rx()
	for s in [-1.0, 1.0]:
		var e := DrawKit.ellipse(HC + Vector2(s * (rx - 4), 6), 14, 20, 20)
		DrawKit.shape(r, e, sk, W, 0.05, _ink())
		DrawKit.fill(r, DrawKit.ellipse(HC + Vector2(s * (rx - 2), 6), 6, 10, 12), sk.darkened(0.15))
	if _has_acc("earring"):
		DrawKit.circle(r, HC + Vector2(rx - 2, 26), 6, Color("#f2c14e"), 2.5)
	if _has_acc("earring_gold"):
		r.draw_arc(HC + Vector2(-rx + 2, 34), 9, 0, TAU, 20, _ink(), 6.0, true)
		r.draw_arc(HC + Vector2(-rx + 2, 34), 9, 0, TAU, 20, Color("#f2c14e"), 3.0, true)


func _robot_head_details(r: CanvasItem) -> void:
	var screen := DrawKit.rrect(Rect2(HC + Vector2(-60, -44), Vector2(120, 96)), 22)
	DrawKit.shape(r, screen, Color("#16202b"), W, 0.0, _ink())
	DrawKit.fill(r, DrawKit.ellipse(HC + Vector2(-30, -30), 30, 10, 16, -0.3), Color(1, 1, 1, 0.08))


# ------------------------------------------------------------------ yüz
func _face(r: CanvasItem, sk: Color, ex: Array, eyes_mode: String) -> void:
	var eyes_kind: String = _sv("eyes", "normal")
	var mouth_mode: String = ex[2]
	if talking > 0.0 and _mouth_open:
		mouth_mode = "talk"
	elif talking > 0.0:
		mouth_mode = "smile_small" if mouth_mode != "frown" else mouth_mode
	if eyes_kind == "led":
		_led_face(r, eyes_mode, mouth_mode)
		return
	if eyes_kind == "glow":
		_glow_face(r, mouth_mode)
		return
	var happyish := ["happy", "laugh", "love", "grin", "wink", "goofy", "chew"].has(expression)
	if happyish and spec.get("blush", true):
		for s in [-1.0, 1.0]:
			DrawKit.fill(r, DrawKit.ellipse(HC + Vector2(s * 50, 24), 14, 8, 16), Color(1.0, 0.45, 0.5, 0.35))
	if _has_acc("freckles"):
		for s in [-1.0, 1.0]:
			for p in [Vector2(44, 18), Vector2(54, 24), Vector2(48, 30), Vector2(58, 14)]:
				r.draw_circle(HC + Vector2(s * p.x, p.y), 2.2, sk.darkened(0.35), true, -1.0, true)
	var mc := _mouth_center()
	var facial: String = _sv("facial", "")
	if facial == "beard_big":
		_beard(r)
	_mouth(r, mc, mouth_mode, sk)
	if facial == "big_mustache":
		_mustache(r, mc, 1.0)
	elif facial == "thin_mustache":
		for s in [-1.0, 1.0]:
			DrawKit.poly_line(r, DrawKit.quad(mc + Vector2(s * 3, -14), mc + Vector2(s * 16, -20), mc + Vector2(s * 28, -10)), _col("hair_color", "#c9a040").darkened(0.15), 5.0)
	elif facial == "beard_big":
		_mustache(r, mc, 0.85)
	if _has_acc("mustache"):
		_mustache(r, mc, 0.7)
	_nose(r, sk)
	var ec: Array = _eye_centers()
	if eyes_kind == "three":
		for i in 2:
			_eye_alien(r, ec[i], 1.0, eyes_mode)
		_eye_alien(r, HC + Vector2(0, -50), 1.25, eyes_mode)
	elif mutation == "robot_eyes":
		var visor := DrawKit.rrect(Rect2(HC.x - 64, ec[0].y - 20, 128, 40), 16)
		DrawKit.shape(r, visor, Color("#3a0b12"), W, 0.0, _ink())
		var sx := sin(_t * 3.0) * 44.0
		DrawKit.glow(r, Vector2(sx, ec[0].y), 26, Color(1.0, 0.2, 0.2, 0.9))
		r.draw_line(Vector2(-54, ec[0].y), Vector2(54, ec[0].y), Color("#ff4f5e"), 4.0, true)
	else:
		for i in 2:
			var side := -1.0 if i == 0 else 1.0
			var m := eyes_mode
			if eyes_mode == "wink":
				m = "normal" if i == 0 else "happy"
			var scl := 1.0
			if eyes_kind == "zombie" and i == 1:
				scl = 0.8
			_eye(r, ec[i], m, side, scl, eyes_kind == "zombie" and i == 1)
		if not (_has_acc("eyepatch")):
			pass
		_brows(r, ec, ex[1])
	if mutation == "vampire_teeth":
		for i in 2:
			DrawKit.fill(r, DrawKit.ellipse(ec[i] + Vector2(0, 22), 14, 5, 14), Color(0.4, 0.2, 0.5, 0.3))
	_face_acc(r, ec)
	if expression == "disgust":
		DrawKit.fill(r, DrawKit.ellipse(HC + Vector2(0, 30), 60, 34, 24), Color(0.4, 0.8, 0.2, 0.28))
	if expression == "angry":
		var vp := HC + Vector2(44, -52)
		for k in 4:
			var a := k * PI / 2 + PI / 4
			r.draw_line(vp + Vector2(cos(a), sin(a)) * 4, vp + Vector2(cos(a), sin(a)) * 12, Color("#e0242f"), 4.0, true)
	if expression == "scared" or expression == "shocked":
		var sp := HC + Vector2(62, -40)
		DrawKit.fill(r, PackedVector2Array([sp + Vector2(-7, 4), sp + Vector2(0, -12), sp + Vector2(7, 4)]), Color("#9fe3ff"))
		r.draw_circle(sp + Vector2(0, 5), 7, Color("#9fe3ff"), true, -1.0, true)


func _eye(r: CanvasItem, c: Vector2, mode: String, side: float, scl: float, small_pupil := false) -> void:
	var ink := _ink()
	var iris := _col("iris", "#5a3a22")
	match mode:
		"happy":
			DrawKit.poly_line(r, DrawKit.arc(c + Vector2(0, 6), 12 * scl, 11 * scl, PI * 1.1, PI * 1.9, 12), ink, 5.0)
			return
		"closed", "blink":
			DrawKit.poly_line(r, DrawKit.arc(c + Vector2(0, -4), 12 * scl, 8 * scl, PI * 0.1, PI * 0.9, 12), ink, 5.0)
			if mode == "closed" and expression == "cry":
				r.draw_line(c + Vector2(0, 8), c + Vector2(side * 4, 40), Color(0.5, 0.85, 1.0, 0.85), 6.0, true)
			return
		"heart":
			var hp := DrawKit.heart_pts(c + Vector2(0, 2), 15 * scl)
			DrawKit.shape(r, hp, Color("#ff3b6b"), 3.5, 0.2, ink)
			DrawKit.dot(r, c + Vector2(-5, -4), 3.0, Color(1, 1, 1, 0.8))
			return
		"dizzy":
			var sp := PackedVector2Array()
			for i in 30:
				var a := i * 0.6 + _t * 6.0
				var rr := 1.0 + i * 0.45
				sp.append(c + Vector2(cos(a), sin(a)) * rr * scl)
			DrawKit.poly_line(r, sp, ink, 3.5)
			return
	var rx := 14.0 * scl
	var ry := 18.0 * scl
	var ir := 8.5 * scl
	if mode == "wide":
		rx = 17.0 * scl
		ry = 21.0 * scl
		ir = 7.0 * scl
	var pts := DrawKit.ellipse(c, rx, ry, 28)
	DrawKit.fill(r, pts, Color.WHITE)
	var ip := c + Vector2(look.x * 4.0, look.y * 3.0 + 2.0)
	r.draw_circle(ip, ir, iris, true, -1.0, true)
	r.draw_circle(ip, ir * (0.35 if small_pupil else 0.55), Color("#1a0f0a"), true, -1.0, true)
	r.draw_circle(ip + Vector2(3, -4) * scl, 2.8 * scl, Color.WHITE, true, -1.0, true)
	var sk := _skin()
	match mode:
		"angry":
			var inner := -side
			var lid := PackedVector2Array([c + Vector2(-rx - 4, -ry - 6), c + Vector2(rx + 4, -ry - 6),
				c + Vector2(inner * (rx + 4), -ry * 0.05), c + Vector2(-inner * (rx + 4), -ry * 0.7)])
			if inner < 0:
				lid = PackedVector2Array([c + Vector2(-rx - 4, -ry - 6), c + Vector2(rx + 4, -ry - 6),
					c + Vector2(rx + 4, -ry * 0.7), c + Vector2(-rx - 4, -ry * 0.05)])
			_clip_fill(r, lid, DrawKit.ellipse(c, rx + 1, ry + 1, 28), sk)
			DrawKit.outline(r, pts, ink, 3.5)
			r.draw_line(c + Vector2(inner * (rx + 2), -ry * 0.05), c + Vector2(-inner * (rx + 2), -ry * 0.7), ink, 4.5, true)
			return
		"sad":
			var inner2 := -side
			var lid2 := PackedVector2Array([c + Vector2(-rx - 4, -ry - 6), c + Vector2(rx + 4, -ry - 6),
				c + Vector2(rx + 4, -ry * (0.75 if inner2 > 0 else 0.1)), c + Vector2(-rx - 4, -ry * (0.1 if inner2 > 0 else 0.75))])
			_clip_fill(r, lid2, DrawKit.ellipse(c, rx + 1, ry + 1, 28), sk)
			DrawKit.outline(r, pts, ink, 3.5)
			return
		"sly":
			var lid3 := PackedVector2Array([c + Vector2(-rx - 4, -ry - 6), c + Vector2(rx + 4, -ry - 6), c + Vector2(rx + 4, -ry * 0.05), c + Vector2(-rx - 4, -ry * 0.05)])
			_clip_fill(r, lid3, DrawKit.ellipse(c, rx + 1, ry + 1, 28), sk)
			DrawKit.outline(r, pts, ink, 3.5)
			r.draw_line(c + Vector2(-rx, -ry * 0.05), c + Vector2(rx, -ry * 0.05), ink, 4.5, true)
			return
	DrawKit.outline(r, pts, ink, 3.5)


func _eye_alien(r: CanvasItem, c: Vector2, scl: float, mode: String) -> void:
	if mode == "happy" or mode == "closed" or mode == "blink":
		DrawKit.poly_line(r, DrawKit.arc(c + Vector2(0, 6 if mode == "happy" else -2), 14 * scl, 10 * scl,
			PI * 1.1 if mode == "happy" else PI * 0.1, PI * 1.9 if mode == "happy" else PI * 0.9, 12), _ink(), 5.0)
		return
	var rx := 16.0 * scl
	var ry := 20.0 * scl
	if mode == "wide":
		rx *= 1.15
		ry *= 1.15
	var pts := DrawKit.ellipse(c, rx, ry, 28)
	DrawKit.shape(r, pts, Color("#120a24"), 3.5, 0.0, _ink())
	r.draw_circle(c + Vector2(-5, -7) * scl, 5.0 * scl, Color.WHITE, true, -1.0, true)
	r.draw_circle(c + Vector2(5, 6) * scl, 2.5 * scl, Color(1, 1, 1, 0.7), true, -1.0, true)
	if mode == "heart":
		DrawKit.fill(r, DrawKit.heart_pts(c, 10 * scl), Color("#ff3b6b"))


func _brows(r: CanvasItem, ec: Array, mode: String) -> void:
	if _has_extra("no_brows"):
		return
	var bc := _col("hair_color", "#5a3420").darkened(0.2)
	if spec.has("brow_color"):
		bc = _col("brow_color", "#5a3420")
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		var b: Vector2 = ec[i] + Vector2(0, -30)
		var din := -s
		var dy_in := 0.0
		var dy_out := 0.0
		var arch := -4.0
		var m := mode
		if mode == "smug":
			m = "high" if i == 1 else "neutral"
		match m:
			"raised":
				dy_in = -7.0
				dy_out = -5.0
				arch = -6.0
			"high":
				dy_in = -14.0
				dy_out = -12.0
				arch = -8.0
			"angry":
				dy_in = 9.0
				dy_out = -7.0
				arch = 0.0
			"angry_soft":
				dy_in = 4.0
				dy_out = -3.0
				arch = -2.0
			"sad":
				dy_in = -9.0
				dy_out = 6.0
				arch = -2.0
		var p_in := b + Vector2(din * 14, dy_in)
		var p_out := b + Vector2(-din * 14, dy_out)
		DrawKit.poly_line(r, DrawKit.quad(p_out, b + Vector2(0, arch + (dy_in + dy_out) * 0.5), p_in, 8), bc, 7.5)


func _nose(r: CanvasItem, sk: Color) -> void:
	var n: String = _sv("nose", "button")
	var np := HC + Vector2(0, 14)
	if _head_kind() == "long":
		np = HC + Vector2(0, 18)
	match n:
		"none":
			return
		"big":
			DrawKit.shape(r, DrawKit.ellipse(np + Vector2(0, 2), 15, 12, 22), sk.darkened(0.1), 3.0, 0.0, sk.darkened(0.45))
			DrawKit.dot(r, np + Vector2(-5, -3), 3.5, Color(1, 1, 1, 0.45))
		"pointy":
			var pts := DrawKit.smooth(PackedVector2Array([np + Vector2(-8, -16), np + Vector2(6, -14), np + Vector2(30, 14), np + Vector2(22, 20), np + Vector2(-4, 12)]), 2)
			DrawKit.shape(r, pts, sk.darkened(0.06), 3.0, 0.0, sk.darkened(0.5))
			if _has_acc("wart"):
				DrawKit.circle(r, np + Vector2(16, 6), 5, Color("#6aa84f"), 2.0, 0.0)
		"small":
			DrawKit.shape(r, DrawKit.ellipse(np, 6, 5, 14), sk.darkened(0.12), 2.5, 0.0, sk.darkened(0.45))
		_:
			DrawKit.shape(r, DrawKit.ellipse(np, 9, 7, 16), sk.darkened(0.1), 2.5, 0.0, sk.darkened(0.45))
			DrawKit.dot(r, np + Vector2(-3, -2), 2.5, Color(1, 1, 1, 0.45))


func _mouth(r: CanvasItem, mc: Vector2, mode: String, sk: Color) -> void:
	var ink := _ink()
	var dark := Color("#6b1f2a")
	if mutation == "frog":
		DrawKit.poly_line(r, DrawKit.quad(mc + Vector2(-46, -10), mc + Vector2(0, 18), mc + Vector2(46, -10)), ink, 5.0)
		return
	if mutation == "giant_tongue":
		mode = "O"
	match mode:
		"smile":
			DrawKit.poly_line(r, DrawKit.quad(mc + Vector2(-20, -4), mc + Vector2(0, 14), mc + Vector2(20, -4)), ink, 5.0)
		"smile_small":
			DrawKit.poly_line(r, DrawKit.quad(mc + Vector2(-13, -2), mc + Vector2(0, 8), mc + Vector2(13, -2)), ink, 5.0)
		"grin", "laugh", "talk", "cry":
			var depth := 24.0
			var half := 24.0
			if mode == "laugh":
				depth = 40.0
				half = 28.0
			elif mode == "talk":
				depth = 18.0
				half = 15.0
			var pts := PackedVector2Array()
			if mode == "cry":
				pts = DrawKit.quad(mc + Vector2(-20, 8), mc + Vector2(0, -10), mc + Vector2(20, 8), 10)
				pts.append_array(DrawKit.quad(mc + Vector2(20, 8), mc + Vector2(0, 22), mc + Vector2(-20, 8), 10))
			else:
				pts.append(mc + Vector2(-half, -6))
				pts.append(mc + Vector2(half, -6))
				pts.append_array(DrawKit.quad(mc + Vector2(half, -6), mc + Vector2(0, depth + 6), mc + Vector2(-half, -6), 14))
			DrawKit.fill(r, pts, dark)
			if mode == "laugh" or mode == "talk":
				_clip_fill(r, DrawKit.ellipse(mc + Vector2(0, depth * 0.62), half * 0.6, depth * 0.3, 16), pts, Color("#ff7a8a"))
			if mode != "cry":
				_clip_fill(r, PackedVector2Array([mc + Vector2(-40, -10), mc + Vector2(40, -10), mc + Vector2(40, 1), mc + Vector2(-40, 1)]), pts, Color.WHITE)
			DrawKit.outline(r, pts, ink, 4.0)
		"o":
			DrawKit.shape(r, DrawKit.ellipse(mc + Vector2(0, 4), 9, 11, 18), dark, 4.0, 0.0, ink)
		"O":
			var op := DrawKit.ellipse(mc + Vector2(0, 6), 15, 19, 20)
			DrawKit.shape(r, op, dark, 4.0, 0.0, ink)
			_clip_fill(r, DrawKit.ellipse(mc + Vector2(0, 18), 10, 6, 14), op, Color("#ff7a8a"))
		"frown":
			DrawKit.poly_line(r, DrawKit.quad(mc + Vector2(-18, 8), mc + Vector2(0, -8), mc + Vector2(18, 8)), ink, 5.0)
		"wavy":
			var wp := PackedVector2Array()
			for i in 7:
				wp.append(mc + Vector2(-21 + i * 7, 4.0 if i % 2 == 0 else -4.0))
			DrawKit.poly_line(r, wp, ink, 4.5)
		"flat":
			DrawKit.poly_line(r, PackedVector2Array([mc + Vector2(-14, 2), mc + Vector2(14, 2)]), ink, 5.0)
		"tongue":
			DrawKit.poly_line(r, DrawKit.quad(mc + Vector2(-20, -4), mc + Vector2(0, 12), mc + Vector2(20, -4)), ink, 5.0)
			var tp := DrawKit.ellipse(mc + Vector2(7, 14), 9, 11, 16)
			DrawKit.shape(r, tp, Color("#ff7a8a"), 3.5, 0.0, ink)
			r.draw_line(mc + Vector2(7, 8), mc + Vector2(7, 18), Color("#d94d63"), 2.5, true)
		"chew":
			if _mouth_open:
				DrawKit.shape(r, DrawKit.ellipse(mc + Vector2(0, 4), 10, 7, 16), dark, 4.0, 0.0, ink)
			else:
				var cp := PackedVector2Array()
				for i in 5:
					cp.append(mc + Vector2(-12 + i * 6, 3.0 if i % 2 == 0 else -1.0))
				DrawKit.poly_line(r, cp, ink, 4.5)
			DrawKit.fill(r, DrawKit.ellipse(mc + Vector2(26, -4), 9, 8, 14), sk.darkened(0.06))
		"smirk":
			DrawKit.poly_line(r, DrawKit.quad(mc + Vector2(-16, 2), mc + Vector2(4, 10), mc + Vector2(20, -8)), ink, 5.0)
		"grit":
			var gp := DrawKit.rrect(Rect2(mc + Vector2(-20, -8), Vector2(40, 17)), 6)
			DrawKit.fill(r, gp, Color.WHITE)
			for i in 3:
				r.draw_line(mc + Vector2(-10 + i * 10, -8), mc + Vector2(-10 + i * 10, 9), Color("#b9a9a0"), 2.0, true)
			r.draw_line(mc + Vector2(-20, 0), mc + Vector2(20, 0), Color("#b9a9a0"), 2.0, true)
			DrawKit.outline(r, gp, ink, 4.0)
	if mutation == "giant_tongue":
		var tg := DrawKit.smooth(PackedVector2Array([mc + Vector2(-14, 8), mc + Vector2(14, 8), mc + Vector2(20, 56), mc + Vector2(12, 96), mc + Vector2(-12, 96), mc + Vector2(-20, 56)]), 2)
		DrawKit.shape(r, tg, Color("#ff6f86"), W, 0.15, ink)
		r.draw_line(mc + Vector2(0, 20), mc + Vector2(0, 80), Color("#d94d63"), 3.0, true)
	if _has_acc("fangs") or mutation == "vampire_teeth":
		for s in [-1.0, 1.0]:
			var fp := PackedVector2Array([mc + Vector2(s * 8, -3), mc + Vector2(s * 17, -3), mc + Vector2(s * 12.5, 11)])
			DrawKit.shape(r, fp, Color.WHITE, 2.5, 0.0, ink)


func _mustache(r: CanvasItem, mc: Vector2, sc: float) -> void:
	var c := _col("hair_color", "#3a2a20")
	if _has_acc("mustache") and not spec.has("facial"):
		c = _col("hair_color", "#3a2a20")
	for s in [-1.0, 1.0]:
		var pts := DrawKit.smooth(PackedVector2Array([mc + Vector2(0, -14) * sc, mc + Vector2(s * 18, -22) * sc + Vector2(0, 0),
			mc + Vector2(s * 38, -18) * sc, mc + Vector2(s * 52, -30) * sc, mc + Vector2(s * 50, -10) * sc,
			mc + Vector2(s * 28, -2) * sc, mc + Vector2(s * 6, -6) * sc]), 2)
		var adj := PackedVector2Array()
		for p in pts:
			adj.append(mc + (p - mc) * 1.0 + Vector2(0, (1.0 - sc) * -6.0))
		DrawKit.shape(r, adj, c, 3.5, 0.15, _ink())


func _beard(r: CanvasItem) -> void:
	var c := _col("beard_color", "#c8431f")
	var pts := DrawKit.smooth(PackedVector2Array([HC + Vector2(-74, -4), HC + Vector2(-70, 50), HC + Vector2(-42, 102), HC + Vector2(0, 118),
		HC + Vector2(42, 102), HC + Vector2(70, 50), HC + Vector2(74, -4), HC + Vector2(50, 22), HC + Vector2(22, 26), HC + Vector2(0, 22),
		HC + Vector2(-22, 26), HC + Vector2(-50, 22)]), 2)
	DrawKit.shape(r, pts, c, W, 0.18, _ink())
	for p in [Vector2(-40, 60), Vector2(0, 86), Vector2(40, 60), Vector2(-20, 96), Vector2(22, 96)]:
		DrawKit.poly_line(r, DrawKit.arc(HC + p, 8, 6, 0.2, PI - 0.2, 8), c.darkened(0.25), 3.0)


func _face_acc(r: CanvasItem, ec: Array) -> void:
	var ink := _ink()
	if _has_acc("glasses") or _has_acc("glasses_round"):
		var rr := 21.0 if _has_acc("glasses_round") else 18.0
		var fc := Color("#6b3d1f") if _has_acc("glasses_round") else ink
		for i in 2:
			DrawKit.fill(r, DrawKit.ellipse(ec[i], rr, rr, 24), Color(1, 1, 1, 0.16))
			r.draw_arc(ec[i], rr, 0, TAU, 30, fc, 4.5, true)
			r.draw_line(ec[i] + Vector2(-8, -10), ec[i] + Vector2(-2, -14), Color(1, 1, 1, 0.8), 3.0, true)
		r.draw_line(ec[0] + Vector2(rr, 0), ec[1] - Vector2(rr, 0), fc, 4.0, true)
	if _has_acc("monocle"):
		var mp: Vector2 = ec[1]
		DrawKit.fill(r, DrawKit.ellipse(mp, 21, 21, 24), Color(1, 1, 1, 0.18))
		r.draw_arc(mp, 21, 0, TAU, 30, ink, 7.0, true)
		r.draw_arc(mp, 21, 0, TAU, 30, Color("#f2c14e"), 3.5, true)
		DrawKit.poly_line(r, DrawKit.quad(mp + Vector2(16, 14), mp + Vector2(30, 70), mp + Vector2(10, 110)), Color("#f2c14e"), 2.5, false)
	if _has_acc("eyepatch"):
		var ep: Vector2 = ec[0]
		r.draw_line(ep + Vector2(-60, -30), ep + Vector2(70, -60), ink, 5.0, true)
		DrawKit.shape(r, DrawKit.ellipse(ep, 20, 21, 22), Color("#1e1714"), 3.5, 0.15, ink)
	if _has_acc("stitches"):
		var a := HC + Vector2(-58, 30)
		var b := HC + Vector2(-34, 52)
		r.draw_line(a, b, Color("#4a3a3a"), 3.0, true)
		for k in 4:
			var p := a.lerp(b, (k + 0.5) / 4.0)
			r.draw_line(p + Vector2(-5, 5), p + Vector2(5, -5), Color("#4a3a3a"), 2.5, true)


func _led_face(r: CanvasItem, eyes_mode: String, mouth_mode: String) -> void:
	var lc := _col("led_color", "#4ad6ff")
	if expression == "angry" or expression == "evil":
		lc = Color("#ff4f5e")
	var ec: Array = [HC + Vector2(-28, -14), HC + Vector2(28, -14)]
	for i in 2:
		var c: Vector2 = ec[i]
		DrawKit.glow(r, c, 30, Color(lc, 0.35))
		match eyes_mode:
			"happy", "closed", "blink":
				var up := eyes_mode == "happy"
				DrawKit.poly_line(r, PackedVector2Array([c + Vector2(-12, 4 if up else -2), c + Vector2(0, -6 if up else 6), c + Vector2(12, 4 if up else -2)]), lc, 6.0)
			"heart":
				DrawKit.fill(r, DrawKit.heart_pts(c, 13), Color("#ff6fa0"))
			"dizzy":
				r.draw_line(c + Vector2(-10, -10), c + Vector2(10, 10), lc, 5.0, true)
				r.draw_line(c + Vector2(-10, 10), c + Vector2(10, -10), lc, 5.0, true)
			"wide":
				r.draw_arc(c, 13, 0, TAU, 24, lc, 5.0, true)
			"angry":
				var s := -1.0 if i == 0 else 1.0
				DrawKit.fill(r, PackedVector2Array([c + Vector2(-13, -6 * s * -1 - 2), c + Vector2(13, 6 * s * -1 - 2), c + Vector2(13, 8), c + Vector2(-13, 8)]), lc)
			"sad":
				DrawKit.fill(r, DrawKit.rrect(Rect2(c + Vector2(-12, 0), Vector2(24, 8)), 3), lc)
			_:
				DrawKit.fill(r, DrawKit.rrect(Rect2(c + Vector2(-11, -12), Vector2(22, 24)), 5), lc)
	var mc := HC + Vector2(0, 26)
	var dots := PackedVector2Array()
	match mouth_mode:
		"smile", "smile_small", "grin", "talk", "chew", "tongue", "smirk":
			for i in 7:
				var x := -24.0 + i * 8.0
				dots.append(mc + Vector2(x, (1.0 - pow(x / 24.0, 2)) * 8.0))
		"laugh":
			for i in 9:
				var x2 := -28.0 + i * 7.0
				dots.append(mc + Vector2(x2, (1.0 - pow(x2 / 28.0, 2)) * 14.0))
		"o", "O":
			for i in 10:
				var a := TAU * i / 10.0
				dots.append(mc + Vector2(cos(a) * 9, sin(a) * 9 + 4))
		"frown", "cry":
			for i in 7:
				var x3 := -24.0 + i * 8.0
				dots.append(mc + Vector2(x3, pow(x3 / 24.0, 2) * 10.0))
		_:
			for i in 7:
				dots.append(mc + Vector2(-24 + i * 8, 4.0 if mouth_mode != "wavy" else (4.0 if i % 2 == 0 else -2.0)))
	for d in dots:
		r.draw_circle(d, 3.5, lc, true, -1.0, true)


func _glow_face(r: CanvasItem, mouth_mode: String) -> void:
	var gc := _col("led_color", "#c77dff")
	for s in [-1.0, 1.0]:
		var c := HC + Vector2(s * 28, -8)
		DrawKit.glow(r, c, 34, Color(gc, 0.6))
		var slit := PackedVector2Array([c + Vector2(-16, s * 0 - 2), c + Vector2(0, -8 + (3.0 if expression == "angry" else 0.0)), c + Vector2(16, -2), c + Vector2(0, 5)])
		if expression == "angry" or expression == "evil":
			slit = PackedVector2Array([c + Vector2(-16, -6 * -s), c + Vector2(16, 6 * -s), c + Vector2(10, 6), c + Vector2(-10, 6)])
		DrawKit.fill(r, slit, gc.lightened(0.4))
	if ["laugh", "grin", "talk"].has(mouth_mode):
		var mc := HC + Vector2(0, 40)
		var jag := PackedVector2Array()
		for i in 9:
			jag.append(mc + Vector2(-28 + i * 7, -2.0 if i % 2 == 0 else 8.0))
		DrawKit.glow(r, mc, 30, Color(gc, 0.4))
		DrawKit.poly_line(r, jag, gc.lightened(0.3), 4.0)


# ------------------------------------------------------------------ saç & şapka
func _hair_front(r: CanvasItem) -> void:
	var hs: String = _sv("hair", "short")
	if hs == "none" or hs == "bald" or _head_kind() == "robot" or _head_kind() == "alien":
		if hs == "bald":
			DrawKit.shine(r, HC + Vector2(-26, -56), 18, 9, 0.45)
		return
	if ["headscarf", "ghost_sheet"].has(str(_sv("hat", ""))):
		return
	var hcol := _col("hair_color", "#5a3420")
	var rx := _head_rx() + 5.0
	var top := _head_top() - 6.0
	var ry := HC.y - top
	var fringe: Array = []
	match hs:
		"long", "fairy", "witch_long", "pigtails":
			fringe = [Vector2(rx, 16), Vector2(60, -24), Vector2(18, -50), Vector2(4, -42), Vector2(-4, -42), Vector2(-18, -50), Vector2(-60, -24), Vector2(-rx, 16)]
		"slick":
			fringe = [Vector2(rx, -8), Vector2(46, -46), Vector2(0, -26), Vector2(-46, -46), Vector2(-rx, -8)]
		"swoop":
			fringe = [Vector2(rx, -2), Vector2(56, -36), Vector2(10, -52), Vector2(-30, -40), Vector2(-62, -22), Vector2(-rx, 0)]
		"curly", "afro":
			fringe = [Vector2(rx, -4), Vector2(56, -30), Vector2(36, -40), Vector2(18, -32), Vector2(0, -42), Vector2(-18, -32), Vector2(-36, -40), Vector2(-56, -30), Vector2(-rx, -4)]
		"granny_bun", "bun", "bun_pencil":
			fringe = [Vector2(rx, 0), Vector2(50, -38), Vector2(0, -50), Vector2(-50, -38), Vector2(-rx, 0)]
		"mohawk":
			fringe = [Vector2(rx - 6, -10), Vector2(30, -54), Vector2(-30, -54), Vector2(-rx + 6, -10)]
		_:
			fringe = [Vector2(rx, -6), Vector2(60, -30), Vector2(40, -40), Vector2(20, -32), Vector2(0, -44), Vector2(-20, -32), Vector2(-40, -42), Vector2(-60, -28), Vector2(-rx, -6)]
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		pts.append(HC + Vector2(cos(a) * rx, sin(a) * ry))
	for f in fringe:
		pts.append(HC + f)
	var sm := DrawKit.smooth(pts, 1)
	if hs == "curly" or hs == "afro":
		for i in 9:
			var a2 := PI + PI * (i + 0.5) / 9.0
			DrawKit.circle(r, HC + Vector2(cos(a2) * rx * 0.96, sin(a2) * ry * 0.96), 20, hcol, W, 0.2, _ink())
	DrawKit.shape(r, sm, hcol, W, 0.22, _ink())
	if hs == "mohawk" and not _hat_covers_top():
		var mp := PackedVector2Array([Vector2(-16, top + 30)])
		for i in 5:
			mp.append(Vector2(-14 + i * 7, top - 44 + (0.0 if i % 2 == 0 else 16.0)))
		mp.append(Vector2(16, top + 30))
		DrawKit.shape(r, mp, hcol, W, 0.2, _ink())
	if hs == "swoop":
		DrawKit.shape(r, DrawKit.blob(Vector2(-30, top + 14), 26, 3, 0.1, 8), hcol, W, 0.22, _ink())
	DrawKit.poly_line(r, DrawKit.arc(HC + Vector2(-8, -6), rx * 0.62, ry * 0.8, PI * 1.25, PI * 1.45, 8), Color(1, 1, 1, 0.35), 6.0)


func _hat(r: CanvasItem) -> void:
	var hat: String = _sv("hat", "none")
	var top := _head_top()
	var ink := _ink()
	var hc := _col("hat_color", "#ffffff")
	match hat:
		"toque", "small_toque", "dark_toque":
			var sc := 1.0
			var tall := float(spec.get("hat_tall", 1.0))
			var off := Vector2.ZERO
			if hat == "small_toque":
				sc = 0.72
				off = Vector2(10, 6)
			if hat == "dark_toque":
				tall = 1.35
			var base := Vector2(0, top + 18) + off
			var puff := PackedVector2Array()
			for p in [Vector2(-66, 0), Vector2(-82, -34 * tall), Vector2(-66, -78 * tall), Vector2(-34, -100 * tall), Vector2(0, -106 * tall),
					Vector2(34, -100 * tall), Vector2(66, -78 * tall), Vector2(82, -34 * tall), Vector2(66, 0)]:
				puff.append(base + p * sc)
			var pc := hc if hat != "dark_toque" else _col("hat_color", "#1a1426")
			DrawKit.shape(r, DrawKit.smooth(puff, 2), pc, W, 0.1, ink)
			var fold := pc.darkened(0.12)
			DrawKit.poly_line(r, DrawKit.quad(base + Vector2(-30, -10) * sc, base + Vector2(-38, -50 * tall) * sc, base + Vector2(-24, -80 * tall) * sc), fold, 3.5)
			DrawKit.poly_line(r, DrawKit.quad(base + Vector2(26, -10) * sc, base + Vector2(34, -50 * tall) * sc, base + Vector2(20, -82 * tall) * sc), fold, 3.5)
			if hat == "dark_toque":
				for p in [Vector2(-34, -50), Vector2(20, -80), Vector2(40, -30), Vector2(-10, -96)]:
					var sp := base + Vector2(p.x, p.y * tall) * sc
					DrawKit.fill(r, DrawKit.star_pts(sp, 9, 4), _col("hat_color2", "#c77dff"))
			DrawKit.shape(r, DrawKit.rrect(Rect2(base + Vector2(-66, -10) * sc, Vector2(132, 34) * sc), 10 * sc), pc.darkened(0.04), W, 0.05, ink)
		"witch":
			var brim := DrawKit.ellipse(Vector2(0, top + 22), 122, 26, 40)
			DrawKit.shape(r, brim, hc, W, 0.2, ink)
			var cone := DrawKit.smooth(PackedVector2Array([Vector2(-62, top + 18), Vector2(-34, top - 70), Vector2(4, top - 132), Vector2(66, top - 150),
				Vector2(28, top - 96), Vector2(58, top + 18)]), 2)
			DrawKit.shape(r, cone, hc, W, 0.2, ink)
			var band := PackedVector2Array([Vector2(-60, top + 2), Vector2(58, top + 2), Vector2(57, top + 18), Vector2(-61, top + 18)])
			DrawKit.shape(r, band, _col("hat_color2", "#ffd23f"), 3.0, 0.1, ink)
			DrawKit.shape(r, DrawKit.rrect(Rect2(-12, top - 2, 24, 24), 4), Color("#2b1d3a"), 3.0, 0.0, Color("#ffd23f"))
		"tricorne":
			var tri := DrawKit.smooth(PackedVector2Array([Vector2(-116, top + 26), Vector2(-96, top - 18), Vector2(-44, top - 50), Vector2(0, top - 58),
				Vector2(44, top - 50), Vector2(96, top - 18), Vector2(116, top + 26), Vector2(60, top + 10), Vector2(0, top + 20), Vector2(-60, top + 10)]), 2)
			DrawKit.shape(r, tri, hc, W, 0.18, ink)
			DrawKit.poly_line(r, DrawKit.quad(Vector2(-108, top + 22), Vector2(0, top + 2), Vector2(108, top + 22), 14), Color("#f2c14e"), 4.0)
			DrawKit.circle(r, Vector2(0, top - 18), 13, Color("#f4f0e6"), 3.0, 0.0)
			r.draw_circle(Vector2(-5, top - 20), 3.2, ink, true, -1.0, true)
			r.draw_circle(Vector2(5, top - 20), 3.2, ink, true, -1.0, true)
			r.draw_line(Vector2(-12, top - 2), Vector2(12, top + 6), Color("#f4f0e6"), 3.5, true)
			r.draw_line(Vector2(12, top - 2), Vector2(-12, top + 6), Color("#f4f0e6"), 3.5, true)
		"headscarf":
			var cap := PackedVector2Array()
			var rx := _head_rx() + 8
			for i in 21:
				var a := PI + PI * i / 20.0
				cap.append(HC + Vector2(cos(a) * rx, sin(a) * (HC.y - top + 8)))
			cap.append(HC + Vector2(rx - 4, -18))
			cap.append(HC + Vector2(0, -34))
			cap.append(HC + Vector2(-rx + 4, -18))
			var sm := DrawKit.smooth(cap, 1)
			DrawKit.shape(r, sm, hc, W, 0.12, ink)
			_pattern_dots(r, sm, _col("hat_color2", "#ffd23f"), 22.0, 4.5)
			DrawKit.outline(r, sm, ink, W)
			var kp := HC + Vector2(0, 88)
			DrawKit.shape(r, PackedVector2Array([kp, kp + Vector2(-26, 22), kp + Vector2(-8, 26)]), hc, 3.0, 0.1, ink)
			DrawKit.shape(r, PackedVector2Array([kp, kp + Vector2(26, 22), kp + Vector2(8, 26)]), hc, 3.0, 0.1, ink)
			DrawKit.circle(r, kp, 9, hc.darkened(0.1), 3.0)
		"flower_crown":
			var fcols := [Color("#ff7ab8"), Color("#ffd23f"), Color("#ffffff"), Color("#c77dff"), Color("#ff9b3d")]
			for i in 7:
				var a := PI * 1.08 + PI * 0.84 * i / 6.0
				var p := Vector2(0, top + 34) + Vector2(cos(a) * 76, sin(a) * 34)
				r.draw_circle(p, 6, Color("#4caf50"), true, -1.0, true)
				for k in 5:
					var pa := TAU * k / 5.0 + i
					DrawKit.circle(r, p + Vector2(cos(pa), sin(pa)) * 8, 7, fcols[i % fcols.size()], 2.0, 0.0)
				r.draw_circle(p, 5, Color("#ffd23f"), true, -1.0, true)
		"beret":
			var bp := DrawKit.ellipse(Vector2(14, top + 8), 78, 28, 32, 0.14)
			DrawKit.shape(r, bp, _col("hat_color", "#e0444f"), W, 0.2, ink)
			DrawKit.circle(r, Vector2(20, top - 22), 7, _col("hat_color", "#e0444f").darkened(0.1), 3.0)
		"bandana":
			var bc := _col("hat_color", "#e0444f")
			var band2 := DrawKit.smooth(PackedVector2Array([Vector2(-80, top + 44), Vector2(-70, top + 4), Vector2(0, top - 8), Vector2(70, top + 4), Vector2(80, top + 44), Vector2(0, top + 30)]), 2)
			DrawKit.shape(r, band2, bc, W, 0.15, ink)
			_pattern_dots(r, band2, Color(1, 1, 1, 0.9), 18.0, 3.0)
			DrawKit.outline(r, band2, ink, W)
			DrawKit.shape(r, PackedVector2Array([Vector2(74, top + 30), Vector2(112, top + 20), Vector2(104, top + 46)]), bc, 3.5, 0.1, ink)
			DrawKit.shape(r, PackedVector2Array([Vector2(74, top + 34), Vector2(104, top + 64), Vector2(86, top + 70)]), bc, 3.5, 0.1, ink)
		"mushroom":
			var dome := DrawKit.smooth(PackedVector2Array([Vector2(-94, top + 34), Vector2(-84, top - 18), Vector2(-42, top - 54), Vector2(0, top - 62),
				Vector2(42, top - 54), Vector2(84, top - 18), Vector2(94, top + 34)]), 2)
			DrawKit.shape(r, dome, Color("#e0444f"), W, 0.2, ink)
			for p in [Vector2(-48, top - 10), Vector2(10, top - 38), Vector2(56, top - 4), Vector2(-10, top + 14)]:
				DrawKit.shape(r, DrawKit.ellipse(p, 14, 10, 16), Color("#fff6e8"), 2.5, 0.0, ink)
		"cat_ears":
			r.draw_arc(Vector2(0, top + 40), 74, PI * 1.05, PI * 1.95, 24, ink, 12.0, true)
			r.draw_arc(Vector2(0, top + 40), 74, PI * 1.05, PI * 1.95, 24, Color("#ff7ab8"), 6.0, true)
			for s in [-1.0, 1.0]:
				var ear := PackedVector2Array([Vector2(s * 26, top + 6), Vector2(s * 50, top - 40), Vector2(s * 70, top + 16)])
				DrawKit.shape(r, ear, _col("hair_color", "#5a3420"), W, 0.15, ink)
				DrawKit.fill(r, PackedVector2Array([Vector2(s * 36, top + 6), Vector2(s * 50, top - 24), Vector2(s * 62, top + 10)]), Color("#ff9fb5"))
		"crown":
			var cr := PackedVector2Array([Vector2(-54, top + 26), Vector2(-56, top - 14), Vector2(-34, top + 6), Vector2(-18, top - 28), Vector2(0, top + 2),
				Vector2(18, top - 28), Vector2(34, top + 6), Vector2(56, top - 14), Vector2(54, top + 26)])
			DrawKit.shape(r, cr, Color("#f2c14e"), W, 0.25, ink)
			for p in [Vector2(-28, top + 14), Vector2(0, top + 14), Vector2(28, top + 14)]:
				DrawKit.circle(r, p, 6, Color("#ff4f7a") if p.x == 0 else Color("#4a9dff"), 2.5, 0.0)
		"wizard":
			DrawKit.shape(r, DrawKit.ellipse(Vector2(0, top + 22), 104, 22, 36), Color("#4b3bb5"), W, 0.2, ink)
			var wc := DrawKit.smooth(PackedVector2Array([Vector2(-58, top + 20), Vector2(-24, top - 80), Vector2(10, top - 140), Vector2(-30, top - 150),
				Vector2(30, top - 120), Vector2(56, top + 20)]), 2)
			DrawKit.shape(r, wc, Color("#5b4bd6"), W, 0.2, ink)
			for p in [Vector2(-20, top - 20), Vector2(18, top - 60), Vector2(-4, top - 100)]:
				DrawKit.fill(r, DrawKit.star_pts(p, 11, 5), Color("#ffd23f"))
		"ghost_sheet":
			var gs := PackedVector2Array()
			var rx2 := _head_rx() + 14
			for i in 21:
				var a := PI + PI * i / 20.0
				gs.append(HC + Vector2(cos(a) * rx2, sin(a) * (HC.y - top + 14)))
			gs.append(HC + Vector2(rx2 - 10, -14))
			gs.append(HC + Vector2(0, -36))
			gs.append(HC + Vector2(-rx2 + 10, -14))
			DrawKit.shape(r, DrawKit.smooth(gs, 1), Color("#f4f6ff"), W, 0.08, ink)
			DrawKit.shape(r, DrawKit.smooth(PackedVector2Array([Vector2(-8, top - 6), Vector2(18, top - 34), Vector2(40, top - 30), Vector2(20, top - 14), Vector2(14, top + 4)]), 2), Color("#f4f6ff"), W, 0.08, ink)


func _extras_front(r: CanvasItem) -> void:
	var top := _head_top()
	if _has_extra("antenna"):
		DrawKit.line(r, Vector2(-30, top + 4), Vector2(-40, top - 40), _ink(), 9.0)
		DrawKit.line(r, Vector2(-30, top + 4), Vector2(-40, top - 40), Color("#9aa6b2"), 4.0)
		var blink_on := int(_t * 2.0) % 2 == 0
		DrawKit.circle(r, Vector2(-40, top - 44), 9, Color("#ff4f5e") if blink_on else Color("#a8323c"), 3.0)
		if blink_on:
			DrawKit.glow(r, Vector2(-40, top - 44), 24, Color(1, 0.3, 0.3, 0.6))
	if _has_extra("antennas_alien"):
		_antennas(r, top, Color("#c6ff6b"))
	if _has_extra("hood"):
		var rim := DrawKit.arc(HC + Vector2(0, 6), 96, 100, PI * 1.08, PI * 1.92, 20)
		DrawKit.poly_line(r, rim, _ink(), 18.0)
		DrawKit.poly_line(r, rim, _col("body_color2", "#7c3bd6"), 10.0)


func _antennas(r: CanvasItem, top: float, col: Color) -> void:
	for s in [-1.0, 1.0]:
		var base := Vector2(s * 30, top + 10)
		var tip := Vector2(s * 54, top - 54)
		var pts := DrawKit.quad(base, Vector2(s * 20, top - 30), tip, 10)
		DrawKit.stroke(r, pts, Color("#7de0c2"), 5.0, _ink(), 3.0)
		DrawKit.glow(r, tip, 24, Color(col, 0.6))
		DrawKit.circle(r, tip, 10, col, 3.0)


func _mutation_front(r: CanvasItem, sk: Color) -> void:
	var top := _head_top()
	match mutation:
		"frog":
			for s in [-1.0, 1.0]:
				var c := Vector2(s * 36, top + 6)
				DrawKit.circle(r, c, 23, sk, W, 0.1)
				DrawKit.circle(r, c + Vector2(0, -2), 15, Color.WHITE, 3.0, 0.0)
				DrawKit.fill(r, DrawKit.ellipse(c + Vector2(look.x * 3, 0), 9, 5, 14), Color("#1a0f0a"))
		"alien_antennas":
			_antennas(r, top - 6, Color("#ffd23f"))
		"flaming_hair":
			for i in 7:
				var x := -66.0 + i * 22.0
				var h := 50.0 + 26.0 * sin(_t * 9.0 + i * 1.7)
				var base := Vector2(x, top + 16)
				var fl := DrawKit.smooth(PackedVector2Array([base + Vector2(-16, 0), base + Vector2(-10, -h * 0.5), base + Vector2(0, -h),
					base + Vector2(10, -h * 0.5), base + Vector2(16, 0)]), 2)
				DrawKit.fill(r, fl, Color(1.0, 0.45, 0.1, 0.92))
				var fl2 := DrawKit.transform_pts(fl, base * 0.4 + Vector2(0, -2), Vector2(0.6, 0.6))
				DrawKit.fill(r, fl2, Color(1.0, 0.85, 0.2, 0.95))
			DrawKit.glow(r, Vector2(0, top - 10), 110, Color(1.0, 0.5, 0.1, 0.35))


# ------------------------------------------------------------------ kollar
func _arm_points(side: float, ang: Vector2) -> Array:
	var s := Vector2(side * 82, -114)
	var a := ang.x
	var d1 := Vector2(sin(a) * side, cos(a))
	var e := s + d1 * 58.0
	var a2 := a + ang.y
	var d2 := Vector2(sin(a2) * side, cos(a2))
	var h := e + d2 * 54.0
	return [s, e, h, d2]


func _arms_draw(r: CanvasItem, sk: Color) -> void:
	if _has_extra("no_arms"):
		return
	var body: String = _sv("body", "chef")
	var sleeve := _col("body_color", "#f7f7f2")
	if body == "labcoat":
		sleeve = _col("body_color", "#ffffff")
	elif body == "pirate":
		sleeve = Color("#f7f2e8")
	var hand := sk
	if body == "robot":
		sleeve = Color("#9aa6b2")
		hand = Color("#b8c4d2")
	elif body == "cloak":
		hand = Color("#2a2036")
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var ap: Array = _arm_points(side, _arms[i])
		var pts := PackedVector2Array([ap[0], ap[1], ap[2] - ap[3] * 10.0])
		if body == "robot":
			DrawKit.stroke(r, pts, sleeve, 20.0, _ink(), 4.0)
			DrawKit.circle(r, ap[1], 12, Color("#7d8a9b"), 3.5)
		else:
			DrawKit.stroke(r, pts, sleeve, 30.0, _ink(), 4.5)
			if body == "pirate":
				var e2: Vector2 = ap[1]
				r.draw_line(e2.lerp(ap[0], 0.4) + Vector2(-12, 0), e2.lerp(ap[0], 0.4) + Vector2(12, 0), _col("body_color2", "#d64545"), 6.0, true)
		DrawKit.circle(r, ap[2], 15, hand, W, 0.1)


func _soot(r: CanvasItem) -> void:
	var sc := Color(0.15, 0.12, 0.12, 0.55 * soot)
	for p in [Vector2(-30, -20), Vector2(26, 10), Vector2(-10, 30), Vector2(40, -30), Vector2(-46, 18)]:
		DrawKit.fill(r, DrawKit.blob(HC + p, 16, int(p.x * 7 + p.y), 0.25, 8), sc)


# ------------------------------------------------------------------ tepkiler
func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_anim_offset = Vector2.ZERO
	_anim_rot = 0.0
	_anim_scale = Vector2.ONE
	_float = 0.0


func _set_off(v: Vector2) -> void:
	_anim_offset = v


func _set_rot(v: float) -> void:
	_anim_rot = v


func _set_scl(v: Vector2) -> void:
	_anim_scale = v


func _set_float(v: float) -> void:
	_float = v


func _clear_soot() -> void:
	soot = 0.0
	redraw()


func _fx(kind: String, local: Vector2, count := 14, col := Color.WHITE, txt := "") -> void:
	FxBurst.spawn(self, local, kind, count, col, txt)


## Tepki animasyonunu oynatır; süresini döndürür.
func react(kind: String) -> float:
	_kill_tween()
	var tw := create_tween()
	_tween = tw
	var head := Vector2(0, _head_top())
	var dur := 1.5
	match kind:
		"laugh":
			set_expression("laugh", 1.7)
			AudioManager.sfx_r("laugh", 0.06)
			var t := FxBurst.spawn(self, head + Vector2(70, -10), "text", 1, Color.WHITE, Loc.t("HA HA!"))
			t.text_color = Color("#ffd23f")
			for k in 6:
				tw.tween_method(_set_rot, 0.0 if k == 0 else (0.05 if k % 2 == 1 else -0.05), (-0.05 if k % 2 == 0 else 0.05), 0.12)
			tw.tween_method(_set_rot, 0.05, 0.0, 0.1)
			dur = 1.7
		"cry":
			set_expression("cry", 2.0)
			AudioManager.sfx_r("cry", 0.05)
			_fx("tears", HC + Vector2(0, -4), 12)
			tw.tween_interval(0.5)
			tw.tween_callback(func(): _fx("tears", HC + Vector2(0, -4), 12))
			tw.tween_method(_set_off, Vector2.ZERO, Vector2(0, 6), 0.4)
			tw.tween_method(_set_off, Vector2(0, 6), Vector2.ZERO, 0.4)
			dur = 2.0
		"cheer":
			set_expression("laugh", 1.6)
			set_pose("up")
			AudioManager.sfx_r("cheer", 0.05)
			_fx("confetti", head + Vector2(0, 20), 26)
			for k in 2:
				tw.tween_method(_set_off, Vector2.ZERO, Vector2(0, -34), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
				tw.tween_method(_set_off, Vector2(0, -34), Vector2.ZERO, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tw.tween_interval(0.6)
			tw.tween_callback(func(): set_pose("idle"))
			dur = 1.6
		"cough":
			set_expression("disgust", 1.6)
			AudioManager.sfx_r("cough", 0.06)
			for k in 3:
				tw.tween_callback(func(): _fx("smoke", _mouth_center() + Vector2(20, 0), 5))
				tw.tween_method(_set_rot, 0.0, 0.14, 0.1)
				tw.tween_method(_set_rot, 0.14, 0.0, 0.25)
			dur = 1.6
		"faint":
			set_expression("dizzy", 2.4)
			set_pose("loose")
			AudioManager.sfx("faint")
			tw.tween_method(_set_rot, 0.0, -1.25, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.parallel().tween_method(_set_off, Vector2.ZERO, Vector2(-30, 50), 0.45)
			tw.tween_callback(func(): _fx("stars", Vector2(-160, -150), 10))
			tw.tween_interval(1.2)
			tw.tween_method(_set_rot, -1.25, 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_method(_set_off, Vector2(-30, 50), Vector2.ZERO, 0.5)
			tw.tween_callback(func(): set_pose("idle"))
			dur = 2.4
		"float":
			set_expression("love", 2.4)
			set_pose("up")
			AudioManager.sfx("float")
			_fx("sparkles", HC, 16, Color("#c7b8ff"))
			tw.tween_method(_set_float, 0.0, 80.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_method(_set_rot, 0.0, 0.12, 0.8)
			tw.tween_method(_set_rot, 0.12, -0.12, 0.6)
			tw.tween_method(_set_float, 80.0, 0.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_method(_set_rot, -0.12, 0.0, 0.5)
			tw.tween_callback(func(): set_pose("idle"))
			dur = 2.4
		"transform":
			set_expression("shocked", 1.6)
			AudioManager.sfx("transform")
			_fx("puff", HC, 18, Color(0.9, 0.85, 1.0))
			_fx("sparkles", HC, 14, Color("#ffd23f"))
			tw.tween_method(_set_scl, Vector2.ONE, Vector2(1.25, 0.8), 0.12)
			tw.tween_method(_set_scl, Vector2(1.25, 0.8), Vector2(0.85, 1.2), 0.12)
			tw.tween_method(_set_scl, Vector2(0.85, 1.2), Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			dur = 1.6
		"disgust":
			set_expression("disgust", 1.6)
			AudioManager.sfx_r("yuck", 0.06)
			for k in 8:
				tw.tween_method(_set_off, Vector2(3 if k % 2 == 0 else -3, 0), Vector2(-3 if k % 2 == 0 else 3, 0), 0.05)
			tw.tween_method(_set_off, Vector2(3, 0), Vector2.ZERO, 0.05)
			dur = 1.5
		"surprised":
			set_expression("shocked", 1.5)
			AudioManager.sfx_r("surprise", 0.05)
			var t2 := FxBurst.spawn(self, head + Vector2(0, -40), "text", 1, Color.WHITE, "!")
			t2.text_color = Color("#ff4f5e")
			tw.tween_method(_set_off, Vector2.ZERO, Vector2(0, -24), 0.12)
			tw.tween_method(_set_off, Vector2(0, -24), Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			dur = 1.4
		"love":
			set_expression("love", 1.9)
			AudioManager.sfx_r("aww", 0.05)
			_fx("hearts", head + Vector2(0, 20), 9)
			tw.tween_method(_set_rot, 0.0, 0.08, 0.4).set_trans(Tween.TRANS_SINE)
			tw.tween_method(_set_rot, 0.08, -0.08, 0.6).set_trans(Tween.TRANS_SINE)
			tw.tween_method(_set_rot, -0.08, 0.0, 0.4).set_trans(Tween.TRANS_SINE)
			dur = 1.9
		"chew":
			set_expression("chew", 1.2)
			AudioManager.sfx_r("munch", 0.1)
			tw.tween_method(_set_scl, Vector2.ONE, Vector2(1.02, 0.98), 0.3)
			tw.tween_method(_set_scl, Vector2(1.02, 0.98), Vector2.ONE, 0.3)
			dur = 1.2
		"taste":
			tw.tween_method(_set_rot, 0.0, 0.1, 0.25)
			tw.parallel().tween_method(_set_off, Vector2.ZERO, Vector2(0, 14), 0.25)
			tw.tween_method(_set_rot, 0.1, 0.0, 0.25)
			tw.parallel().tween_method(_set_off, Vector2(0, 14), Vector2.ZERO, 0.25)
			dur = 0.5
		"hit":
			soot = 1.0
			set_expression("dizzy", 2.0)
			AudioManager.sfx("backfire")
			_fx("smoke", HC + Vector2(0, -60), 14, Color(0.3, 0.3, 0.32))
			tw.tween_method(_set_scl, Vector2.ONE, Vector2(1.15, 0.85), 0.1)
			tw.tween_method(_set_scl, Vector2(1.15, 0.85), Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tw.tween_interval(1.4)
			tw.tween_callback(_clear_soot)
			dur = 2.0
		"jump":
			tw.tween_method(_set_off, Vector2.ZERO, Vector2(0, -30), 0.15)
			tw.tween_method(_set_off, Vector2(0, -30), Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			dur = 0.4
		"smug":
			set_expression("smug", 1.5)
			set_pose("hips")
			tw.tween_interval(1.4)
			tw.tween_callback(func(): set_pose("idle"))
			dur = 1.5
		"sad":
			set_expression("sad", 2.0)
			tw.tween_method(_set_off, Vector2.ZERO, Vector2(0, 10), 0.5)
			tw.tween_interval(1.0)
			tw.tween_method(_set_off, Vector2(0, 10), Vector2.ZERO, 0.5)
			dur = 2.0
	if GameManager.fast():
		tw.set_speed_scale(2.0)
		dur *= 0.5
	tw.tween_callback(func(): reaction_finished.emit(kind))
	redraw()
	return dur


# ------------------------------------------------------------------ hazır karakterler
static func preset(id: String) -> Dictionary:
	match id:
		"bruno":
			return {"skin": Color("#e5a878"), "head": "wide", "hair": "short", "hair_color": Color("#3a2a20"), "facial": "big_mustache",
				"hat": "toque", "hat_tall": 1.25, "body": "chef", "body_color": Color("#f7f7f2"), "acc": ["neckerchief"],
				"acc_color": Color("#e0444f"), "nose": "big", "iris": Color("#4a3020"), "expression": "neutral"}
		"mira":
			return {"skin": Color("#9c6440"), "head": "long", "hair": "bun_pencil", "hair_color": Color("#7b4fd6"), "hat": "none",
				"body": "labcoat", "body_color": Color("#ffffff"), "body_color2": Color("#4a7dff"), "acc": ["glasses_round", "earring"],
				"nose": "small", "iris": Color("#2a1a10"), "expression": "neutral"}
		"max":
			return {"skin": Color("#ffe0c7"), "head": "long", "hair": "swoop", "hair_color": Color("#f2d06b"), "facial": "thin_mustache",
				"hat": "none", "body": "velvet", "body_color": Color("#6a2fa0"), "body_color2": Color("#f2c14e"), "acc": ["monocle", "ascot"],
				"nose": "small", "iris": Color("#3f7bff"), "expression": "smug"}
		"morgana":
			return {"skin": Color("#8fd16a"), "head": "long", "hair": "witch_long", "hair_color": Color("#2b1d3a"), "hat": "witch",
				"hat_color": Color("#5b2a86"), "hat_color2": Color("#ffd23f"), "body": "robe", "body_color": Color("#5b2a86"),
				"body_color2": Color("#ffd23f"), "nose": "pointy", "acc": ["wart"], "iris": Color("#e8b51c"), "expression": "evil"}
		"x3000":
			return {"skin": Color("#c9d3df"), "head": "robot", "eyes": "led", "hair": "none", "hat": "small_toque", "hat_color": Color("#ffffff"),
				"body": "robot", "body_color": Color("#b8c4d2"), "extras": ["antenna", "no_brows"], "nose": "none", "blush": false,
				"led_color": Color("#4ad6ff"), "expression": "neutral"}
		"gulizar":
			return {"skin": Color("#b9c7a6"), "head": "round", "eyes": "zombie", "hair": "granny_bun", "hair_color": Color("#e8e8e8"),
				"hat": "headscarf", "hat_color": Color("#7a3b8f"), "hat_color2": Color("#ffd23f"), "body": "cardigan",
				"body_color": Color("#8e3b46"), "apron": "classic", "apron_color": Color("#f5e6c8"), "acc": ["glasses_round", "stitches"],
				"nose": "big", "iris": Color("#6b7a5a"), "expression": "happy", "brow_color": Color("#c9c9c9")}
		"velvet":
			return {"skin": Color("#e8e4f0"), "head": "long", "hair": "slick", "hair_color": Color("#1c1424"), "hat": "small_toque",
				"hat_color": Color("#2a1f33"), "body": "cape", "body_color": Color("#1c1424"), "body_color2": Color("#b3122e"),
				"acc": ["fangs"], "nose": "small", "iris": Color("#b3122e"), "expression": "smug", "blush": false}
		"barbunya":
			return {"skin": Color("#d79b6a"), "head": "wide", "hair": "short", "hair_color": Color("#b5361c"), "facial": "beard_big",
				"beard_color": Color("#c8431f"), "hat": "tricorne", "hat_color": Color("#2b1d16"), "body": "pirate",
				"body_color": Color("#6b3d1f"), "body_color2": Color("#d64545"), "acc": ["eyepatch", "earring_gold"], "nose": "big",
				"iris": Color("#3a2a20"), "expression": "grin"}
		"zorp":
			return {"skin": Color("#7de0c2"), "head": "alien", "eyes": "three", "hair": "none", "hat": "none", "body": "spacesuit",
				"body_color": Color("#d3dbea"), "body_color2": Color("#7c6bff"), "extras": ["antennas_alien", "no_brows"], "nose": "none",
				"expression": "happy"}
		"lila":
			return {"skin": Color("#ffe3d6"), "head": "round", "hair": "fairy", "hair_color": Color("#ff7ab8"), "hat": "flower_crown",
				"body": "fairy_dress", "body_color": Color("#6cd38a"), "body_color2": Color("#ffb8ec"), "extras": ["wings"],
				"acc": ["freckles"], "nose": "small", "iris": Color("#2fbf71"), "expression": "happy"}
		"obscura":
			return {"skin": Color("#2e2340"), "head": "round", "eyes": "glow", "hair": "none", "hat": "dark_toque",
				"hat_color": Color("#1a1426"), "hat_color2": Color("#c77dff"), "body": "cloak", "body_color": Color("#1a1426"),
				"body_color2": Color("#7c3bd6"), "extras": ["aura", "hood", "no_brows"], "nose": "none", "led_color": Color("#c77dff"),
				"expression": "neutral", "blush": false}
	return {}


static func chef_spec(chef: Dictionary) -> Dictionary:
	var jacket: Dictionary = IngredientDatabase.cosmetic("jacket", str(chef.get("jacket", "white")))
	var apron: Dictionary = IngredientDatabase.cosmetic("apron", str(chef.get("apron", "classic")))
	var acc: String = chef.get("accessory", "none")
	var s := {
		"skin": IngredientDatabase.skin_color(int(chef.get("skin", 1))),
		"head": "round",
		"hair": chef.get("hair", "short"),
		"hair_color": IngredientDatabase.hair_color(int(chef.get("hair_color", 1))),
		"hat": chef.get("hat", "toque"),
		"hat_color": Color("#ffffff"),
		"body": "chef",
		"body_color": Color(jacket.get("color", "#f7f7f2")),
		"apron": chef.get("apron", "classic"),
		"apron_color": Color(apron.get("color", "#e9e2d0")) if str(apron.get("color", "")) != "" else Color("#e9e2d0"),
		"acc": [acc] if acc != "none" else [],
		"acc_color": Color("#e0444f"),
		"nose": "button",
		"iris": Color("#5a3a22"),
		"expression": chef.get("expression", "happy"),
	}
	if s["hat"] == "beret":
		s["hat_color"] = Color("#e0444f")
	elif s["hat"] == "bandana":
		s["hat_color"] = Color("#3f7bff")
	if acc == "scarf":
		s["acc_color"] = Color("#4a9dff")
	return s
