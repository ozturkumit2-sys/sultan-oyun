class_name Humanoid
extends Node3D
## Prosedürel Osmanlı esintili karakter modeli ve basit prosedürel animasyon
## (yürüme, koşma, oturma, konuşma jesti, nefes alma).

const SKINS := [Color(0.93, 0.79, 0.67), Color(0.83, 0.65, 0.5), Color(0.66, 0.49, 0.36)]
const BEARDS := {"short": Color(0.18, 0.12, 0.08), "long": Color(0.16, 0.11, 0.07), "grey": Color(0.55, 0.53, 0.5), "white": Color(0.88, 0.87, 0.84)}

static var _mats := {}

var anim := "idle"   # idle, walk, sit, sit_low, talk, work
var speed := 0.0
var _phase := 0.0
var _t := 0.0
var _sit := 0.0
var _talk_w := 0.0
var _work_w := 0.0

var body: Node3D
var lower: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var _base_lower_y := 0.0
var _female := false


static func mat(c: Color, rough: float = 0.82, metal: float = 0.0, emit: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f_%.2f" % [c.to_html(false), rough, metal, emit]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m


func _mi(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func cyl(top: float, bottom: float, h: float, segs: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return c


static func sph(r: float, h: float = -1.0, segs: int = 12, rings: int = 8) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h if h > 0 else r * 2.0
	s.radial_segments = segs
	s.rings = rings
	return s


static func box(sz: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = sz
	return b


func build(look: Dictionary, gender: String) -> void:
	for ch in get_children():
		ch.queue_free()
	_female = gender == "f"
	var robe := Color(String(look.get("robe", "e0d8c0")))
	var accent := Color(String(look.get("accent", "c8a050")))
	var outer := Color(String(look.get("outer", look.get("robe", "806040"))))
	var skin: Color = SKINS[clampi(int(look.get("skin", 1)), 0, 2)]
	var m_outer := mat(outer)
	var m_robe := mat(robe)
	var m_accent := mat(accent, 0.45, 0.55)
	var m_skin := mat(skin, 0.7)
	var m_dark := mat(Color(0.08, 0.06, 0.05), 0.6)

	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	lower = Node3D.new()
	lower.name = "Lower"
	body.add_child(lower)
	# alt kaftan / entari (koni)
	var bottom_r := 0.43 if _female else 0.36
	_mi(lower, cyl(0.22, bottom_r, 1.06, 14), m_outer, Vector3(0, 0.53, 0))
	# ön açıklıktan görünen iç entari şeridi
	_mi(lower, box(Vector3(0.15, 0.98, 0.03)), m_robe, Vector3(0, 0.55, -0.265 if not _female else -0.29), Vector3(-0.15 if not _female else -0.19, 0, 0))
	# gövde
	_mi(body, cyl(0.19 if not _female else 0.17, 0.235 if not _female else 0.215, 0.54, 14), m_outer, Vector3(0, 1.32, 0))
	_mi(body, box(Vector3(0.13, 0.46, 0.03)), m_robe, Vector3(0, 1.32, -0.2))
	for i in range(4):
		_mi(body, sph(0.017, -1, 6, 4), m_accent, Vector3(0, 1.48 - i * 0.1, -0.218))
	# kuşak
	_mi(body, cyl(0.24 if not _female else 0.22, 0.24 if not _female else 0.22, 0.1, 14), m_accent, Vector3(0, 1.08, 0))
	# boyun ve yaka
	_mi(body, cyl(0.06, 0.065, 0.12, 8), m_skin, Vector3(0, 1.63, 0))
	_mi(body, cyl(0.09, 0.14, 0.06, 12), m_robe, Vector3(0, 1.585, 0))
	# kafa
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.75, 0)
	body.add_child(head)
	_mi(head, sph(0.125, 0.27, 14, 10), m_skin, Vector3.ZERO)
	for sx in [-0.045, 0.045]:
		_mi(head, sph(0.017, -1, 6, 4), m_dark, Vector3(sx, 0.02, -0.112))
		_mi(head, box(Vector3(0.045, 0.01, 0.012)), m_dark, Vector3(sx, 0.055, -0.115))
	_mi(head, sph(0.022, -1, 6, 4), m_skin, Vector3(0, -0.01, -0.125), Vector3.ZERO, Vector3(1, 1.2, 1))
	var beard: String = look.get("beard", "")
	if beard != "" and not _female:
		var bc: Color = BEARDS.get(beard, BEARDS["short"])
		var mb := mat(bc, 0.9)
		var long := beard in ["long", "grey", "white"]
		_mi(head, sph(0.085, -1, 10, 6), mb, Vector3(0, -0.085 if not long else -0.1, -0.06), Vector3.ZERO, Vector3(1.05, 0.75 if not long else 1.15, 0.7))
		_mi(head, box(Vector3(0.09, 0.018, 0.02)), mb, Vector3(0, -0.04, -0.12))
	_headwear(String(look.get("head", "takke")), m_accent, robe, outer, skin)
	# kollar
	arm_l = _arm(Vector3(-0.245 if not _female else -0.22, 1.5, 0), m_outer, m_skin)
	arm_r = _arm(Vector3(0.245 if not _female else 0.22, 1.5, 0), m_outer, m_skin)
	_base_lower_y = lower.position.y


func _arm(pos: Vector3, m_sleeve: Material, m_skin: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	body.add_child(pivot)
	var r := 0.07 if not _female else 0.06
	_mi(pivot, cyl(r, r * 1.25, 0.56, 8), m_sleeve, Vector3(0, -0.28, 0))
	_mi(pivot, sph(0.052, -1, 8, 5), m_skin, Vector3(0, -0.6, 0))
	return pivot


func _headwear(kind: String, m_accent: Material, robe: Color, outer: Color, skin: Color) -> void:
	var white := mat(Color(0.96, 0.95, 0.9), 0.85)
	match kind:
		"sultan":
			_mi(head, sph(0.2, 0.3, 16, 10), white, Vector3(0, 0.15, 0.0), Vector3.ZERO, Vector3(1.15, 0.95, 1.1))
			_mi(head, cyl(0.07, 0.08, 0.12, 10), mat(Color(0.65, 0.1, 0.12)), Vector3(0, 0.3, 0))
			_mi(head, sph(0.035, -1, 8, 6), mat(Color(0.1, 0.65, 0.35), 0.2, 0.3, 0.6), Vector3(0, 0.17, -0.2))
			_mi(head, cyl(0.004, 0.022, 0.28, 6), white, Vector3(0, 0.33, -0.17), Vector3(-0.35, 0, 0))
			_mi(head, sph(0.02, -1, 6, 4), m_accent, Vector3(0, 0.2, -0.205))
		"vezir":
			_mi(head, cyl(0.155, 0.165, 0.34, 14), white, Vector3(0, 0.2, 0.0))
			_mi(head, cyl(0.168, 0.168, 0.035, 14), m_accent, Vector3(0, 0.08, 0))
			_mi(head, cyl(0.06, 0.07, 0.06, 10), mat(Color(0.6, 0.12, 0.12)), Vector3(0, 0.39, 0))
		"sarik":
			_mi(head, sph(0.165, 0.22, 14, 8), white, Vector3(0, 0.12, 0.0), Vector3.ZERO, Vector3(1.05, 1, 1.05))
			_mi(head, cyl(0.07, 0.08, 0.08, 10), mat(Color(0.6, 0.15, 0.15)), Vector3(0, 0.22, 0))
		"sarik_small":
			_mi(head, sph(0.145, 0.18, 12, 8), white, Vector3(0, 0.11, 0.0))
			_mi(head, cyl(0.06, 0.07, 0.06, 10), mat(outer.darkened(0.2)), Vector3(0, 0.2, 0))
		"kadi":
			_mi(head, sph(0.2, 0.26, 16, 10), white, Vector3(0, 0.14, 0.0), Vector3.ZERO, Vector3(1.15, 1, 1.15))
			_mi(head, cyl(0.205, 0.205, 0.04, 16), mat(Color(0.15, 0.4, 0.25)), Vector3(0, 0.09, 0))
		"bork":
			_mi(head, cyl(0.12, 0.13, 0.34, 12), white, Vector3(0, 0.22, 0.02))
			_mi(head, box(Vector3(0.2, 0.42, 0.03)), white, Vector3(0, 0.12, 0.17), Vector3(0.25, 0, 0))
			_mi(head, cyl(0.135, 0.135, 0.05, 12), m_accent, Vector3(0, 0.07, 0.02))
			_mi(head, box(Vector3(0.05, 0.14, 0.02)), m_accent, Vector3(0, 0.2, -0.13))
		"takke":
			_mi(head, sph(0.135, 0.15, 12, 6), mat(outer.darkened(0.15)), Vector3(0, 0.08, 0.0))
		"cook":
			_mi(head, cyl(0.13, 0.12, 0.17, 12), white, Vector3(0, 0.13, 0.0))
		"foreign_hat":
			var dark := mat(Color(0.1, 0.1, 0.14), 0.7)
			_mi(head, cyl(0.24, 0.24, 0.02, 16), dark, Vector3(0, 0.1, 0))
			_mi(head, cyl(0.1, 0.12, 0.15, 12), dark, Vector3(0, 0.18, 0))
			_mi(head, sph(0.02, -1, 6, 4), mat(Color(0.85, 0.85, 0.9), 0.3, 0.8), Vector3(0.1, 0.18, -0.05))
			_mi(head, sph(0.13, 0.2, 12, 6), mat(Color(0.35, 0.25, 0.15)), Vector3(0, 0.02, 0.03))
		"valide":
			var purple := mat(outer, 0.7)
			_mi(head, sph(0.14, 0.28, 14, 8), mat(robe.darkened(0.1)), Vector3(0, 0.02, 0.02))
			_mi(head, cyl(0.1, 0.13, 0.22, 12), purple, Vector3(0, 0.2, 0.02))
			_mi(head, cyl(0.132, 0.132, 0.04, 12), m_accent, Vector3(0, 0.11, 0.02))
			_mi(head, box(Vector3(0.3, 0.75, 0.02)), mat(Color(0.95, 0.93, 0.9), 0.9), Vector3(0, -0.2, 0.15), Vector3(0.12, 0, 0))
			_mi(head, sph(0.03, -1, 8, 4), mat(Color(0.75, 0.1, 0.2), 0.2, 0.4, 0.4), Vector3(0, 0.2, -0.12))
		"hotoz_blue", "hotoz_red":
			var hair := mat(Color(0.12, 0.07, 0.04), 0.8)
			_mi(head, sph(0.135, 0.25, 12, 8), hair, Vector3(0, 0.02, 0.025))
			_mi(head, box(Vector3(0.14, 0.55, 0.06)), hair, Vector3(0, -0.28, 0.12), Vector3(0.12, 0, 0))
			var capc := Color(0.2, 0.32, 0.6) if kind == "hotoz_blue" else Color(0.62, 0.12, 0.18)
			_mi(head, cyl(0.085, 0.1, 0.12, 12), mat(capc), Vector3(0.02, 0.15, 0.0), Vector3(0, 0, 0.12))
			_mi(head, cyl(0.102, 0.102, 0.03, 12), m_accent, Vector3(0.015, 0.1, 0.0), Vector3(0, 0, 0.12))
			_mi(head, box(Vector3(0.26, 0.6, 0.01)), mat(Color(0.97, 0.95, 0.92, 1.0), 0.9), Vector3(0, -0.12, 0.16), Vector3(0.18, 0, 0))
			_mi(head, sph(0.022, -1, 6, 4), m_accent, Vector3(-0.07, 0.15, -0.06))
		"scarf_dark", "scarf_light":
			var sc := Color(0.25, 0.25, 0.3) if kind == "scarf_dark" else robe.lightened(0.35)
			var msc := mat(sc, 0.9)
			_mi(head, sph(0.145, 0.3, 14, 8), msc, Vector3(0, 0.03, 0.03))
			_mi(head, box(Vector3(0.28, 0.5, 0.03)), msc, Vector3(0, -0.22, 0.12), Vector3(0.1, 0, 0))
		_:
			_mi(head, sph(0.135, 0.15, 12, 6), mat(outer), Vector3(0, 0.08, 0.0))


func set_anim(a: String) -> void:
	anim = a


func _process(delta: float) -> void:
	if body == null:
		return
	_t += delta
	var sit_target := 0.0
	var sit_drop := 0.0
	if anim == "sit":
		sit_target = 1.0
		sit_drop = 0.48
	elif anim == "sit_low":
		sit_target = 1.0
		sit_drop = 0.78
	_sit = move_toward(_sit, sit_target, delta * 3.0)
	_talk_w = move_toward(_talk_w, 1.0 if anim == "talk" else 0.0, delta * 3.0)
	_work_w = move_toward(_work_w, 1.0 if anim == "work" else 0.0, delta * 2.0)
	var mv := clampf(speed / 3.2, 0.0, 1.6)
	if mv > 0.05:
		_phase += delta * (5.2 + speed * 1.1)
	var swing := sin(_phase) * mv * 0.55 * (1.0 - _sit)
	var drop := (sit_drop if sit_target > 0.0 else 0.6) * _sit
	body.position.y = absf(sin(_phase)) * 0.035 * mv - drop
	body.rotation.x = -0.07 * clampf(speed / 6.0, 0.0, 1.0)
	body.scale = Vector3(1, 1.0 + sin(_t * 1.8) * 0.006, 1)
	# oturunca etek kısalır ve yayılır
	lower.scale = Vector3(1.0 + _sit * 0.25, 1.0 - _sit * 0.5, 1.0 + _sit * 0.35)
	lower.position.y = _base_lower_y + _sit * 0.22
	lower.position.z = -_sit * 0.08
	var ax_l := swing - _sit * 0.75
	var ax_r := -swing - _sit * 0.75
	var az_r := 0.0
	if _talk_w > 0.0:
		ax_r = lerpf(ax_r, -0.75 + sin(_t * 3.1) * 0.28, _talk_w)
		az_r = 0.18 * _talk_w
		head.rotation.x = sin(_t * 2.3) * 0.06 * _talk_w
	else:
		head.rotation.x = lerpf(head.rotation.x, sin(_t * 0.7) * 0.02, delta * 2.0)
	if _work_w > 0.0:
		ax_r = lerpf(ax_r, -0.9 + sin(_t * 4.0) * 0.35, _work_w)
		ax_l = lerpf(ax_l, -0.6 + sin(_t * 4.0 + 1.5) * 0.25, _work_w)
	arm_l.rotation = Vector3(ax_l, 0, -0.08)
	arm_r.rotation = Vector3(ax_r, 0, 0.08 + az_r)
	head.rotation.y = sin(_t * 0.4) * 0.12 * (1.0 - mv)
