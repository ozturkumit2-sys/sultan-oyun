class_name HumanAnims
extends RefCounted
## İskelet animasyonlarını yön tanımlı pozlardan üretir (model uzayı: yüz -Z, sağ +X, yukarı +Y).
## Her poz: kemik -> hedef yön (Vector3) ve isteğe bağlı "@kemik" -> kendi ekseni etrafında burulma (radyan).
## Oluşan AnimationLibrary tüm karakterlerde paylaşılır.

const SK := "Pivot/Skeleton:"

static var _lib: AnimationLibrary


static func library() -> AnimationLibrary:
	if _lib == null:
		_lib = _build()
	return _lib


# ---------------------------------------------------------------- poz çözücü
static func _solve(rig: CharacterRig, pose: Dictionary) -> Dictionary:
	var n := rig.bone_names.size()
	var G: Array[Basis] = []
	G.resize(n)
	var out := {}
	for i in range(n):
		var p := rig.bone_parents[i]
		var rest_local: Basis = rig.bone_rest[i].basis if p < 0 else (rig.bone_rest[p].basis.inverse() * rig.bone_rest[i].basis)
		var parent_g: Basis = Basis.IDENTITY if p < 0 else G[p]
		var u: Basis = parent_g * rest_local
		var bn := rig.bone_names[i]
		if pose.has(bn):
			var d: Vector3 = (pose[bn] as Vector3).normalized()
			var y := u.y.normalized()
			var axis := y.cross(d)
			var s := axis.length()
			var c := y.dot(d)
			if s > 1e-5:
				u = Basis(axis / s, atan2(s, c)) * u
			elif c < 0.0:
				u = Basis(u.x.normalized(), PI) * u
		var tw_key := "@" + bn
		if pose.has(tw_key):
			u = u * Basis(Vector3.UP, float(pose[tw_key]))
		G[i] = u.orthonormalized()
		var local: Basis = G[i] if p < 0 else (G[p].inverse() * G[i])
		out[bn] = local.get_rotation_quaternion()
	return out


static func _mirror(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, v.z)


## Simetrik yardımcı: sol taraf yönünü verip sağı aynala
static func _sym(pose: Dictionary, base: String, left: Vector3, right_override = null) -> void:
	pose[base + ".L"] = left
	pose[base + ".R"] = right_override if right_override != null else _mirror(left)


static func _stand() -> Dictionary:
	var p := {}
	p["spine"] = Vector3(0, 1, 0.02)
	p["spine1"] = Vector3(0, 1, 0.04)
	p["chest"] = Vector3(0, 1, 0.0)
	p["neck"] = Vector3(0, 1, -0.12)
	p["head"] = Vector3(0, 1, 0.02)
	_sym(p, "thigh", Vector3(-0.045, -1, 0.0))
	_sym(p, "shin", Vector3(-0.02, -1, 0.03))
	_sym(p, "foot", Vector3(-0.08, -0.5, -1))
	_sym(p, "toes", Vector3(-0.05, -0.15, -1))
	_sym(p, "clavicle", Vector3(-1, -0.12, 0.05))
	_sym(p, "upperarm", Vector3(-0.26, -1, 0.06))
	_sym(p, "forearm", Vector3(-0.06, -1, -0.28))
	_sym(p, "hand", Vector3(0.0, -1, -0.12))
	_sym(p, "fingers", Vector3(0.05, -1, -0.35))
	_sym(p, "thumb", Vector3(0.35, -0.8, -0.5))
	return p


static func _with(base: Dictionary, changes: Dictionary) -> Dictionary:
	var p := base.duplicate()
	for k in changes.keys():
		p[k] = changes[k]
	return p


# ---------------------------------------------------------------- animasyon kurucu
class PoseKey:
	var t: float
	var pose: Dictionary
	var pivot: Vector3
	func _init(t_: float, pose_: Dictionary, pivot_: Vector3 = Vector3.ZERO) -> void:
		t = t_
		pose = pose_
		pivot = pivot_


static func _anim(rig: CharacterRig, keys: Array, length: float, loop: bool, extra: Callable = Callable()) -> Animation:
	var a := Animation.new()
	a.length = length
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var solved := []
	for k in keys:
		solved.append(_solve(rig, (k as PoseKey).pose))
	for bn in rig.bone_names:
		var ti := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(ti, NodePath(SK + bn))
		a.track_set_interpolation_type(ti, Animation.INTERPOLATION_CUBIC)
		for i in range(keys.size()):
			a.rotation_track_insert_key(ti, (keys[i] as PoseKey).t, solved[i][bn])
	var pi := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(pi, NodePath("Pivot"))
	a.track_set_interpolation_type(pi, Animation.INTERPOLATION_CUBIC)
	for k in keys:
		a.position_track_insert_key(pi, (k as PoseKey).t, (k as PoseKey).pivot)
	if extra.is_valid():
		extra.call(a)
	return a


static func _build() -> AnimationLibrary:
	var rig := HumanFigure.rig()
	var lib := AnimationLibrary.new()
	var st := _stand()

	# --- bekleme: nefes, hafif ağırlık aktarımı, baş hareketi
	var i0 := st
	var i1 := _with(st, {"chest": Vector3(0, 1, 0.03), "spine1": Vector3(0.01, 1, 0.05), "@head": 0.10, "head": Vector3(0.01, 1, 0.0)})
	var i2 := _with(st, {"chest": Vector3(0, 1, -0.01), "@head": -0.06, "head": Vector3(-0.01, 1, 0.03)})
	lib.add_animation("idle", _anim(rig, [PoseKey.new(0.0, i0), PoseKey.new(1.6, i1, Vector3(0.006, -0.004, 0)), PoseKey.new(3.2, i0), PoseKey.new(4.8, i2, Vector3(-0.006, -0.004, 0)), PoseKey.new(6.4, i0)], 6.4, true))

	# --- yürüyüş (1 döngü = 2 adım, 1.0 sn @ 1.6 m/s)
	var w := []
	var contact_l := _with(st, {
		"thigh.L": Vector3(-0.05, -0.93, -0.38), "shin.L": Vector3(-0.03, -0.97, -0.2), "foot.L": Vector3(-0.06, -0.15, -1),
		"thigh.R": Vector3(0.05, -0.95, 0.32), "shin.R": Vector3(0.03, -0.8, 0.6), "foot.R": Vector3(0.06, -0.85, -0.6),
		"upperarm.L": Vector3(-0.15, -1, 0.3), "forearm.L": Vector3(-0.06, -1, -0.1),
		"upperarm.R": Vector3(0.15, -1, -0.32), "forearm.R": Vector3(0.06, -0.8, -0.7),
		"@spine1": 0.09, "@chest": 0.06, "@head": -0.12})
	var pass_l := _with(st, {
		"thigh.L": Vector3(-0.05, -1, -0.02), "shin.L": Vector3(-0.03, -1, 0.06),
		"thigh.R": Vector3(0.05, -0.9, -0.35), "shin.R": Vector3(0.03, -0.75, 0.62), "foot.R": Vector3(0.06, -0.55, -0.9),
		"upperarm.L": Vector3(-0.16, -1, 0.05), "upperarm.R": Vector3(0.16, -1, -0.05)})
	var contact_r := {}
	var pass_r := {}
	for k in contact_l.keys():
		contact_r[_swap(k)] = _mirror_val(k, contact_l[k])
	for k in pass_l.keys():
		pass_r[_swap(k)] = _mirror_val(k, pass_l[k])
	w = [PoseKey.new(0.0, contact_l, Vector3(0, -0.035, 0)), PoseKey.new(0.25, pass_l, Vector3(0.012, 0.0, 0)),
		PoseKey.new(0.5, contact_r, Vector3(0, -0.035, 0)), PoseKey.new(0.75, pass_r, Vector3(-0.012, 0.0, 0)),
		PoseKey.new(1.0, contact_l, Vector3(0, -0.035, 0))]
	lib.add_animation("walk", _anim(rig, w, 1.0, true))

	# --- sedir kenarında oturma (ayaklar yerde)
	var sit := _with(st, {
		"spine": Vector3(0, 1, -0.05), "spine1": Vector3(0, 1, -0.04), "chest": Vector3(0, 1, 0.02),
		"thigh.L": Vector3(-0.12, -0.08, -1), "thigh.R": Vector3(0.12, -0.08, -1),
		"shin.L": Vector3(-0.05, -1, -0.05), "shin.R": Vector3(0.05, -1, -0.05),
		"foot.L": Vector3(-0.1, -0.4, -1), "foot.R": Vector3(0.1, -0.4, -1),
		"upperarm.L": Vector3(-0.2, -1, -0.3), "upperarm.R": Vector3(0.2, -1, -0.3),
		"forearm.L": Vector3(0.05, -0.3, -1), "forearm.R": Vector3(-0.05, -0.3, -1),
		"hand.L": Vector3(0.05, -0.6, -1), "hand.R": Vector3(-0.05, -0.6, -1)})
	var sit2 := _with(sit, {"@head": 0.12, "chest": Vector3(0, 1, 0.04)})
	lib.add_animation("sit", _anim(rig, [PoseKey.new(0.0, sit, Vector3(0, -0.46, 0.16)), PoseKey.new(3.0, sit2, Vector3(0, -0.465, 0.16)), PoseKey.new(6.0, sit, Vector3(0, -0.46, 0.16))], 6.0, true))

	# --- bağdaş kurarak yerde (minder) oturma
	var low := _with(st, {
		"spine": Vector3(0, 1, -0.06), "spine1": Vector3(0, 1, -0.02), "chest": Vector3(0, 1, 0.04),
		"thigh.L": Vector3(-0.78, -0.2, -0.6), "thigh.R": Vector3(0.78, -0.2, -0.6),
		"shin.L": Vector3(0.85, -0.1, -0.15), "shin.R": Vector3(-0.85, -0.05, -0.3),
		"foot.L": Vector3(0.5, -0.2, -0.6), "foot.R": Vector3(-0.5, -0.2, -0.6),
		"upperarm.L": Vector3(-0.25, -1, -0.25), "upperarm.R": Vector3(0.25, -1, -0.25),
		"forearm.L": Vector3(-0.25, -0.4, -1), "forearm.R": Vector3(0.25, -0.4, -1),
		"hand.L": Vector3(-0.1, -1, -0.5), "hand.R": Vector3(0.1, -1, -0.5)})
	var low2 := _with(low, {"@head": -0.12, "chest": Vector3(0, 1, 0.07)})
	lib.add_animation("sit_low", _anim(rig, [PoseKey.new(0.0, low, Vector3(0, -0.76, 0.06)), PoseKey.new(3.5, low2, Vector3(0, -0.765, 0.06)), PoseKey.new(7.0, low, Vector3(0, -0.76, 0.06))], 7.0, true))

	# --- konuşma: el hareketleri, baş sallama, ağız
	var t1 := _with(st, {"upperarm.R": Vector3(0.25, -0.85, -0.45), "forearm.R": Vector3(0.15, 0.25, -1), "hand.R": Vector3(0.2, 0.3, -1), "fingers.R": Vector3(0.2, 0.2, -1), "head": Vector3(0, 1, 0.06), "@head": 0.05})
	var t2 := _with(st, {"upperarm.R": Vector3(0.3, -0.9, -0.3), "forearm.R": Vector3(0.5, 0.05, -1), "hand.R": Vector3(0.6, 0.0, -1), "upperarm.L": Vector3(-0.2, -1, -0.15), "forearm.L": Vector3(-0.1, -0.5, -1), "head": Vector3(0, 1, -0.02), "@head": -0.08})
	var t3 := _with(st, {"upperarm.R": Vector3(0.2, -0.95, -0.25), "forearm.R": Vector3(0.1, -0.2, -1), "head": Vector3(0.02, 1, 0.04)})
	var talk := _anim(rig, [PoseKey.new(0.0, t3), PoseKey.new(0.8, t1), PoseKey.new(1.7, t2), PoseKey.new(2.6, t1), PoseKey.new(3.4, t3)], 3.4, true, func(a: Animation):
		var bi := a.add_track(Animation.TYPE_BLEND_SHAPE)
		a.track_set_path(bi, NodePath("Pivot/Skeleton/Body:mouth_open"))
		var tt := 0.0
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		while tt < 3.4:
			a.blend_shape_track_insert_key(bi, tt, rng.randf_range(0.0, 0.45))
			tt += rng.randf_range(0.09, 0.18)
		a.blend_shape_track_insert_key(bi, 3.4, 0.0))
	lib.add_animation("talk", talk)

	# --- çalışma: masada yazı / tezgâhta iş
	var k1 := _with(st, {"spine1": Vector3(0, 1, -0.15), "chest": Vector3(0, 1, -0.2), "head": Vector3(0, 1, -0.35),
		"upperarm.L": Vector3(-0.2, -0.9, -0.45), "forearm.L": Vector3(0.1, -0.3, -1), "hand.L": Vector3(0.2, -0.5, -1),
		"upperarm.R": Vector3(0.2, -0.9, -0.4), "forearm.R": Vector3(-0.15, -0.35, -1), "hand.R": Vector3(-0.2, -0.6, -1)})
	var k2 := _with(k1, {"forearm.R": Vector3(0.05, -0.25, -1), "hand.R": Vector3(0.1, -0.7, -1), "@head": 0.08})
	var k3 := _with(k1, {"forearm.L": Vector3(-0.05, -0.4, -1), "forearm.R": Vector3(-0.25, -0.3, -1)})
	lib.add_animation("work", _anim(rig, [PoseKey.new(0.0, k1, Vector3(0, -0.01, 0)), PoseKey.new(0.6, k2, Vector3(0, -0.012, 0)), PoseKey.new(1.2, k3, Vector3(0, -0.01, 0)), PoseKey.new(1.8, k1, Vector3(0, -0.01, 0))], 1.8, true))
	return lib


static func _swap(k: String) -> String:
	var tw := k.begins_with("@")
	var b := k.substr(1) if tw else k
	if b.ends_with(".L"):
		b = b.substr(0, b.length() - 2) + ".R"
	elif b.ends_with(".R"):
		b = b.substr(0, b.length() - 2) + ".L"
	return ("@" + b) if tw else b


static func _mirror_val(k: String, v):
	if k.begins_with("@"):
		return -float(v)
	return _mirror(v as Vector3)
