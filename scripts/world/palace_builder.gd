class_name PalaceBuilder
extends Node3D
## Zehrâni Sarayı'nı PalaceLayout planından prosedürel olarak inşa eder.
## Üretilen geometri malzeme bazında birleştirilir (oda başına az draw call),
## çarpışma kutuları ve navigasyon ağı (NavigationMesh) aynı yapıdan üretilir.

signal progress(frac: float, text: String)

const T := PalaceLayout.WALL_T
const WARM := Color(1.0, 0.8, 0.58)
const FANCY_CATS := ["devlet", "ozel", "harem"]
const NAV_LAYER := 16           # fizik katmanı 5: navigasyon kaynağı
const STEP_MAX := 0.45          # bu yüksekliğe kadar zemine oturan yüzeyler basamak sayılır
const OBST_H := 2.4             # daha yüksek eşyalar navigasyon için bu yüksekliğe uzatılır

var nav_region: NavigationRegion3D
var body: StaticBody3D
var upper_body: StaticBody3D
var nav_src: StaticBody3D       # yalnızca navigasyon ağı pişirmek için (fizik dünyasında etkisiz)
var geo_root: Node3D
var light_root: Node3D
var occ_root: Node3D
var spots: Dictionary = {}
var interactables: Array = []
var sound_points: Array = []
var b: MeshBatch


func _make_nodes() -> void:
	nav_region = NavigationRegion3D.new()
	nav_region.name = "Nav"
	add_child(nav_region)
	body = StaticBody3D.new()
	body.name = "Colliders"
	body.collision_layer = 1
	body.collision_mask = 0
	nav_region.add_child(body)
	upper_body = StaticBody3D.new()
	upper_body.name = "UpperColliders"
	upper_body.collision_layer = 8
	upper_body.collision_mask = 0
	nav_region.add_child(upper_body)
	nav_src = StaticBody3D.new()
	nav_src.name = "NavSource"
	nav_src.collision_layer = NAV_LAYER
	nav_src.collision_mask = 0
	nav_region.add_child(nav_src)
	geo_root = Node3D.new()
	geo_root.name = "Geometry"
	add_child(geo_root)
	light_root = Node3D.new()
	light_root.name = "Lights"
	add_child(light_root)
	occ_root = Node3D.new()
	occ_root.name = "Occluders"
	add_child(occ_root)
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.5
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.5
	nm.agent_max_slope = 40.0
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.region_min_size = 6.0
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = NAV_LAYER
	nm.filter_baking_aabb = AABB(Vector3(-63, -1.0, -58), Vector3(126, 16.0, 141))
	nav_region.navigation_mesh = nm


## Senkron inşa (araç betikleri ve hızlı cihazlar için)
func build_all() -> void:
	_make_nodes()
	var ids := PalaceLayout.ROOMS.keys()
	for id in ids:
		_build_room(String(id))
	_build_exterior()
	_store_meta()


## Kare kare inşa: yükleme ekranı akıcı kalır
func build_async() -> void:
	_make_nodes()
	var ids := PalaceLayout.ROOMS.keys()
	var i := 0
	for id in ids:
		_build_room(String(id))
		i += 1
		progress.emit(float(i) / (ids.size() + 2), PalaceLayout.room_name(String(id)))
		await get_tree().process_frame
	_build_exterior()
	_store_meta()
	progress.emit(1.0, "Saray hazır")


func _store_meta() -> void:
	set_meta("spots", spots)
	set_meta("interactables", interactables)
	set_meta("sound_points", sound_points)


func load_meta() -> void:
	spots = get_meta("spots", {})
	interactables = get_meta("interactables", [])
	sound_points = get_meta("sound_points", [])
	nav_region = get_node_or_null("Nav")
	body = get_node_or_null("Nav/Colliders")
	upper_body = get_node_or_null("Nav/UpperColliders")
	geo_root = get_node_or_null("Geometry")
	light_root = get_node_or_null("Lights")
	occ_root = get_node_or_null("Occluders")


# ---------------------------------------------------------------- yardımcılar

func col_box(center: Vector3, size: Vector3, rot_y: float = 0.0, upper: bool = false) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = Transform3D(Basis(Vector3.UP, rot_y), center)
	(upper_body if upper else body).add_child(cs)
	if not upper:
		_nav_copy(center, size.y, rot_y, sh)


## Navigasyon kaynağı: zemin ve alçak basamaklar olduğu gibi; yere oturan daha yüksek
## eşyalar (minder, sedir, havuz kenarı, çiçeklik...) tavana kadar uzatılır ki yol hiçbir
## zaman bunların üstünden geçmesin.
func _nav_copy(center: Vector3, h: float, rot_y: float, shape: Shape3D) -> void:
	var top := center.y + h * 0.5
	var bottom := center.y - h * 0.5
	var ncs := CollisionShape3D.new()
	if top > STEP_MAX and bottom < 1.0 and top < OBST_H:
		var nh := OBST_H - bottom
		if shape is BoxShape3D:
			var bs := BoxShape3D.new()
			bs.size = Vector3((shape as BoxShape3D).size.x, nh, (shape as BoxShape3D).size.z)
			ncs.shape = bs
		else:
			var cy := CylinderShape3D.new()
			cy.radius = (shape as CylinderShape3D).radius
			cy.height = nh
			ncs.shape = cy
		ncs.transform = Transform3D(Basis(Vector3.UP, rot_y), Vector3(center.x, bottom + nh * 0.5, center.z))
	else:
		ncs.shape = shape
		ncs.transform = Transform3D(Basis(Vector3.UP, rot_y), center)
	nav_src.add_child(ncs)


## Pişirme bittikten sonra navigasyon kaynağına gerek kalmaz
func free_nav_source() -> void:
	if nav_src and is_instance_valid(nav_src):
		nav_src.queue_free()
		nav_src = null


## Görünmez alanların çizilmesini engelleyen kutu engelleyici (occlusion culling)
func occ_box(center: Vector3, size: Vector3) -> void:
	if size.x < 0.6 and size.z < 0.6:
		return
	var oi := OccluderInstance3D.new()
	var bo := BoxOccluder3D.new()
	bo.size = size
	oi.occluder = bo
	oi.position = center
	occ_root.add_child(oi)


func col_cyl(base: Vector3, r: float, h: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	cs.position = base + Vector3(0, h * 0.5, 0)
	body.add_child(cs)
	_nav_copy(cs.position, h, 0.0, sh)


func spot(room: String, pos: Vector3, type: String, yaw: float = 0.0, tag: String = "") -> void:
	if not spots.has(room):
		spots[room] = []
	spots[room].append({"pos": pos, "type": type, "yaw": yaw, "tag": tag})


func interact(id: String, room: String, pos: Vector3, label: String, action: String, extra: Dictionary = {}) -> void:
	var d := {"id": id, "room": room, "pos": pos, "label": label, "action": action}
	d.merge(extra)
	interactables.append(d)


func omni(pos: Vector3, rng: float, energy: float, color: Color = WARM, night_only: bool = false) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.omni_range = rng
	l.omni_attenuation = 1.1
	l.light_energy = energy
	l.light_color = color
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 45.0
	l.distance_fade_length = 12.0
	l.set_meta("base_energy", energy)
	l.add_to_group("night_lights" if night_only else "room_lights", true)
	light_root.add_child(l)


static func face_yaw(dir: Vector3) -> float:
	return atan2(-dir.x, -dir.z)


static func xf(origin: Vector3, yaw: float, local: Vector3) -> Vector3:
	return origin + Basis(Vector3.UP, yaw) * local


func _finish_batch(name_: String, cast_shadows: bool = true) -> void:
	var keys: Array = []
	for k in b._verts.keys():
		keys.append(k)
	b.build(geo_root, name_, Mats.all_for(keys), cast_shadows)


# ---------------------------------------------------------------- oda inşası

func _build_room(id: String) -> void:
	var room: Dictionary = PalaceLayout.ROOMS[id]
	var r: Array = room["rect"]
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var w := x1 - x0
	var d := z1 - z0
	b = MeshBatch.new()
	# zemin
	var floor_mat: String = room["floor"]
	b.add_box(floor_mat, Vector3((x0 + x1) * 0.5, -0.1, (z0 + z1) * 0.5), Vector3(w, 0.2, d), 0.0, Mats.tile(floor_mat), 4)
	col_box(Vector3((x0 + x1) * 0.5, -0.25, (z0 + z1) * 0.5), Vector3(w, 0.5, d))
	# duvarlar
	for side in ["n", "s", "e", "w"]:
		_build_side(id, room, side)
	# tavan
	match String(room["ceiling"]):
		"flat":
			_flat_ceiling(id, room)
		"dome":
			_dome_ceiling(id, room)
	# döşeme
	var fn := "_furnish_" + id
	if has_method(fn):
		call(fn, room, x0, z0, x1, z1)
	_finish_batch(id)
	_room_atmos(id, room, x0, z0, x1, z1)


# ---------------------------------------------------------------- ışık ortamı: yansıma ve köşe gölgeleri

static var _ao_floor_mat: StandardMaterial3D
static var _ao_wall_mat: StandardMaterial3D


static func _grad_tex(vertical: bool) -> ImageTexture:
	var n := 64
	var img := Image.create(4 if vertical else n, n if vertical else 4, false, Image.FORMAT_L8)
	for i in range(n):
		var t := float(i) / float(n - 1)          # 0: köşe, 1: uzak
		var v := lerpf(0.52, 1.0, pow(t, 0.7))
		for j in range(4):
			if vertical:
				img.set_pixel(j, i, Color(v, v, v))
			else:
				img.set_pixel(i, j, Color(v, v, v))
	return ImageTexture.create_from_image(img)


static func _ao_mat(vertical: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.albedo_texture = _grad_tex(vertical)
	m.texture_repeat = false
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	return m


func _wall_segments(id: String, side: String, room: Dictionary) -> Array:
	var info := _side_info(room["rect"], side)
	var out := []
	for span in PalaceLayout.side_spans(id, side):
		if not String(span[2]) in ["wall", "outer"]:
			continue
		var a := float(span[0])
		var c := float(span[1])
		var cur := a
		for d in PalaceLayout.doors_on_line(String(info["axis"]), float(info["line"]), a, c):
			var dc := float(d["c"])
			var hw := float(d["w"]) * 0.5 + 0.1
			if dc - hw > cur:
				out.append([cur, dc - hw])
			cur = maxf(cur, dc + hw)
		if c > cur:
			out.append([cur, c])
	return out


func _room_atmos(id: String, room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	if String(room["kind"]) == "outdoor":
		return
	var h := float(room["h"])
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	# kutu yansıtmalı yansıma sondası: cilalı mermer ve çiniler odayı yansıtır
	var rp := ReflectionProbe.new()
	rp.name = "Probe_" + id
	rp.size = Vector3(x1 - x0, h + 0.4, z1 - z0)
	rp.position = Vector3(cx, h * 0.5, cz)
	rp.origin_offset = Vector3(0, 1.6 - h * 0.5, 0)
	rp.box_projection = true
	rp.interior = true
	rp.enable_shadows = false
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.max_distance = maxf(x1 - x0, z1 - z0) * 1.6
	rp.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	var warm := String(room["cat"]) in ["harem", "ozel", "aile"]
	rp.ambient_color = Color(0.62, 0.55, 0.48) if warm else Color(0.58, 0.56, 0.53)
	rp.ambient_color_energy = 0.55
	rp.cull_mask = 1
	rp.intensity = 0.8
	rp.add_to_group("room_probes")
	light_root.add_child(rp)
	# duvar dibi köşe gölgesi (zemin ve duvar şeritleri)
	if _ao_floor_mat == null:
		_ao_floor_mat = _ao_mat(false)
		_ao_wall_mat = _ao_mat(true)
	var st_f := SurfaceTool.new()
	st_f.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_w := SurfaceTool.new()
	st_w.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fw := 0.85
	var wh := 0.7
	var t := T * 0.5 + 0.005
	var any := false
	for side in ["n", "s", "e", "w"]:
		var info := _side_info(room["rect"], side)
		var inn: Vector3 = info["in"]
		for seg in _wall_segments(id, side, room):
			any = true
			var a := float(seg[0])
			var c := float(seg[1])
			var line := float(info["line"])
			var p0: Vector3
			var p1: Vector3
			if String(info["axis"]) == "z":
				p0 = Vector3(a, 0, line)
				p1 = Vector3(c, 0, line)
			else:
				p0 = Vector3(line, 0, a)
				p1 = Vector3(line, 0, c)
			p0 += inn * t
			p1 += inn * t
			var y := 0.012
			# zemin şeridi: u=0 duvarda, u=1 içeride
			_quad_uv(st_f, p0 + Vector3(0, y, 0), p1 + Vector3(0, y, 0), p1 + inn * fw + Vector3(0, y, 0), p0 + inn * fw + Vector3(0, y, 0),
				[Vector2(0, 0.5), Vector2(0, 0.5), Vector2(1, 0.5), Vector2(1, 0.5)])
			# duvar şeridi: v=0 dipte, v=1 yukarıda
			var o := inn * 0.008
			_quad_uv(st_w, p0 + o, p1 + o, p1 + o + Vector3(0, wh, 0), p0 + o + Vector3(0, wh, 0),
				[Vector2(0.5, 0), Vector2(0.5, 0), Vector2(0.5, 1), Vector2(0.5, 1)])
	if not any:
		return
	for pair in [[st_f, _ao_floor_mat], [st_w, _ao_wall_mat]]:
		var mi := MeshInstance3D.new()
		mi.mesh = (pair[0] as SurfaceTool).commit()
		mi.material_override = pair[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.name = "AO_" + id
		geo_root.add_child(mi)


func _quad_uv(st: SurfaceTool, a: Vector3, b2: Vector3, c: Vector3, d: Vector3, uv: Array) -> void:
	for idx in [0, 1, 2, 0, 2, 3]:
		st.set_uv(uv[idx])
		st.add_vertex([a, b2, c, d][idx])


func _side_info(r: Array, side: String) -> Dictionary:
	match side:
		"n":
			return {"axis": "z", "line": float(r[1]), "in": Vector3(0, 0, 1)}
		"s":
			return {"axis": "z", "line": float(r[3]), "in": Vector3(0, 0, -1)}
		"w":
			return {"axis": "x", "line": float(r[0]), "in": Vector3(1, 0, 0)}
	return {"axis": "x", "line": float(r[2]), "in": Vector3(-1, 0, 0)}


func _build_side(id: String, room: Dictionary, side: String) -> void:
	var si := _side_info(room["rect"], side)
	var spans := PalaceLayout.side_spans(id, side)
	for span in spans:
		var a: float = span[0]
		var e: float = span[1]
		var wtype: String = span[2]
		if wtype == "none":
			continue
		if wtype == "arcade":
			_arcade(id, room, si, a, e)
			continue
		var wall_h := float(room["h"])
		if wtype == "low":
			wall_h = 1.15
		elif wtype == "outer":
			wall_h = 4.5
		var doors := PalaceLayout.doors_on_line(si["axis"], si["line"], a, e)
		var cur := a
		for door in doors:
			var dc := float(door["c"])
			var dw := float(door["w"])
			var g0 := dc - dw * 0.5
			var g1 := dc + dw * 0.5
			if g0 > cur:
				_wall_piece(id, room, si, cur, g0, wall_h, wtype)
			if dw < 5.0 and wtype == "wall":
				_door(id, room, si, dc, dw, wall_h)
			elif wtype != "wall":
				_gate_posts(si, dc, dw, wall_h)
			cur = g1
		if cur < e:
			_wall_piece(id, room, si, cur, e, wall_h, wtype)


func _along(si: Dictionary, s: float, inward: float, y: float) -> Vector3:
	var inn: Vector3 = si["in"]
	var line: float = si["line"]
	if si["axis"] == "z":
		return Vector3(s, y, line + inn.z * inward)
	return Vector3(line + inn.x * inward, y, s)


func _wall_box(si: Dictionary, s0: float, s1: float, in0: float, in1: float, y0: float, y1: float, mat: String) -> void:
	var c := _along(si, (s0 + s1) * 0.5, (in0 + in1) * 0.5, (y0 + y1) * 0.5)
	var size: Vector3
	if si["axis"] == "z":
		size = Vector3(s1 - s0, y1 - y0, absf(in1 - in0))
	else:
		size = Vector3(absf(in1 - in0), y1 - y0, s1 - s0)
	b.add_box(mat, c, size, 0.0, Mats.tile(mat))


func _wall_piece(id: String, room: Dictionary, si: Dictionary, s0: float, s1: float, wall_h: float, wtype: String) -> void:
	if s1 - s0 < 0.05:
		return
	var mid := (s0 + s1) * 0.5
	var wsize: Vector3 = Vector3(s1 - s0, wall_h, T) if si["axis"] == "z" else Vector3(T, wall_h, s1 - s0)
	col_box(_along(si, mid, T * 0.5, wall_h * 0.5), wsize)
	if wall_h >= 3.0 and s1 - s0 >= 1.2:
		occ_box(_along(si, mid, T * 0.5, wall_h * 0.5), wsize * Vector3(1, 0.98, 1))
	if wtype == "low" or wtype == "outer":
		_wall_box(si, s0, s1, 0.0, T, 0.0, wall_h, "stone_ext")
		_wall_box(si, s0 - 0.05, s1 + 0.05, -0.06, T + 0.06, wall_h, wall_h + 0.12, "marble_warm")
		if wtype == "low":
			# korkuluk babaları
			var n := int((s1 - s0) / 2.5)
			for i in range(n + 1):
				var s := s0 + (s1 - s0) * float(i) / maxf(n, 1)
				b.add_box("marble_warm", _along(si, s, T * 0.5, wall_h * 0.5), Vector3(0.45, wall_h + 0.1, 0.5) if si["axis"] == "z" else Vector3(0.5, wall_h + 0.1, 0.45))
		return
	var inn: Vector3 = si["in"]
	var outside_p := _along(si, mid, -0.6, 0.0)
	var nb := PalaceLayout.room_at(outside_p.x, outside_p.z)
	var exterior := nb == "" or PalaceLayout.is_outdoor(nb)
	var dado: String = room.get("dado", "")
	var inner0 := T * 0.5 if exterior else 0.0
	var upper := "plaster"
	if exterior:
		_wall_box(si, s0, s1, 0.0, inner0, 0.0, wall_h, "plaster_ext")
		# dış yüze sıva bandı ve pencere izleri
		_wall_box(si, s0, s1, -0.08, 0.0, 0.0, 0.6, "stone_ext")
	if dado != "":
		_wall_box(si, s0, s1, inner0, T, 0.0, 1.35, dado)
		_wall_box(si, s0, s1, inner0, T, 1.35, wall_h, upper)
		var trim := "gold_plain" if room["cat"] in FANCY_CATS else "wood_dark"
		_wall_box(si, s0, s1, T, T + 0.04, 1.31, 1.41, trim)
	else:
		_wall_box(si, s0, s1, inner0, T, 0.0, wall_h, upper if room["kind"] != "room" or room["cat"] != "hizmet" else "stone_ext")
	if room["kind"] == "room" and wall_h > 5.0:
		_wall_box(si, s0, s1, T, T + 0.1, wall_h - 0.4, wall_h - 0.1, "wood_dark")
	# dış duvarlarda iç yüze vitray pencereler
	if exterior and room["kind"] == "room" and s1 - s0 > 3.0:
		var count := int((s1 - s0) / 4.0)
		for i in range(count):
			var s := s0 + (s1 - s0) * (float(i) + 0.5) / count
			var p_in := _along(si, s, T + 0.012, wall_h - 1.9)
			var yaw_in := face_yaw(-inn) + PI
			b.add_panel("window", p_in, 0.9, 1.3, yaw_in, false)
			var p_out := _along(si, s, -0.012, wall_h - 1.9)
			b.add_panel("lattice", p_out, 1.0, 1.4, yaw_in + PI, false, 0.5)


func _gate_posts(si: Dictionary, dc: float, dw: float, wall_h: float) -> void:
	for sgn in [-1.0, 1.0]:
		var s: float = dc + sgn * (dw * 0.5 + 0.25)
		b.add_box("marble_warm", _along(si, s, T * 0.5, (wall_h + 0.6) * 0.5), Vector3(0.6, wall_h + 0.6, 0.6))
		b.add_sphere("marble_warm", _along(si, s, T * 0.5, wall_h + 0.8), Vector3(0.25, 0.25, 0.25), 8, 5)
		col_box(_along(si, s, T * 0.5, (wall_h + 0.6) * 0.5), Vector3(0.6, wall_h + 0.6, 0.6))


## Düzlem eksenleri: yatay duvarda right=+X (çıkarma +Z), dikeyde right=+Z (çıkarma -X)
func _plane(si: Dictionary, s: float, inward_from: float, depth: float) -> Dictionary:
	var inn: Vector3 = si["in"]
	var line: float = si["line"]
	if si["axis"] == "z":
		# +Z yönünde çıkarılır; başlangıç: içeri doğru en küçük z
		var za := line + inn.z * inward_from
		var zb := line + inn.z * (inward_from + depth)
		return {"origin": Vector3(s, 0, minf(za, zb)), "right": Vector3(1, 0, 0), "up": Vector3(0, 1, 0)}
	var xa := line + inn.x * inward_from
	var xb := line + inn.x * (inward_from + depth)
	return {"origin": Vector3(maxf(xa, xb), 0, s), "right": Vector3(0, 0, 1), "up": Vector3(0, 1, 0)}


func _door(id: String, room: Dictionary, si: Dictionary, dc: float, dw: float, wall_h: float) -> void:
	var spring := 2.7
	var apex := MeshBatch.arch_apex(dw, spring)
	if apex > wall_h - 0.3:
		spring -= apex - (wall_h - 0.3)
		apex = wall_h - 0.3
	var curve := MeshBatch.arch_curve(dw, spring)
	var poly := PackedVector2Array(curve)
	poly.append(Vector2(dw * 0.5, wall_h))
	poly.append(Vector2(-dw * 0.5, wall_h))
	var pl := _plane(si, dc, 0.0, T)
	b.add_extrude("plaster", poly, pl["origin"], pl["right"], pl["up"], T, 3.0, "stone_white")
	col_box(_along(si, dc, T * 0.5, (apex + wall_h) * 0.5 + 0.2), Vector3(dw, wall_h - apex, T) if si["axis"] == "z" else Vector3(T, wall_h - apex, dw), 0.0, true)
	# kemer çerçevesi (iç yüz)
	var bw := 0.17
	var frame_mat := "gold_plain" if room["cat"] in FANCY_CATS else "marble_warm"
	var inner := MeshBatch.arch_curve(dw, spring)
	var outer := MeshBatch.arch_curve(dw + bw * 2.0, spring)
	var band := PackedVector2Array(inner)
	for i in range(outer.size() - 1, -1, -1):
		band.append(outer[i])
	var fp := _plane(si, dc, T, 0.05)
	b.add_extrude(frame_mat, band, fp["origin"], fp["right"], fp["up"], 0.05, 1.0)
	for sgn in [-1.0, 1.0]:
		var s: float = dc + sgn * (dw * 0.5 + bw * 0.5)
		var c := _along(si, s, T + 0.025, spring * 0.5)
		b.add_box(frame_mat, c, Vector3(bw, spring, 0.05) if si["axis"] == "z" else Vector3(0.05, spring, bw))
	# açık kapı kanatları (duvara yaslı)
	if room["kind"] == "room" and dw <= 3.2:
		for sgn2 in [-1.0, 1.0]:
			var s2: float = dc + sgn2 * (dw * 0.5 + bw + dw * 0.25 + 0.04)
			var c2 := _along(si, s2, T + 0.08, (spring + 0.3) * 0.5)
			b.add_box("wood_dark", c2, Vector3(dw * 0.5, spring + 0.3, 0.06) if si["axis"] == "z" else Vector3(0.06, spring + 0.3, dw * 0.5))
			var c3 := _along(si, s2, T + 0.12, spring * 0.55)
			b.add_box("gold_plain", c3, Vector3(dw * 0.3, 0.08, 0.03) if si["axis"] == "z" else Vector3(0.03, 0.08, dw * 0.3))


func _column(base: Vector3, height: float, r: float, shaft: String = "marble", cap: String = "marble_warm", collide: bool = true) -> void:
	b.add_box(cap, base + Vector3(0, 0.2, 0), Vector3(r * 3.0, 0.4, r * 3.0))
	b.add_tube(shaft, base + Vector3(0, 0.4, 0), r, r * 0.9, height - 0.85, 12, false, false, false, 1.0, (height - 0.85) * 0.5)
	b.add_tube(cap, base + Vector3(0, height - 0.45, 0), r * 1.0, r * 1.7, 0.3, 8, false, true, false)
	b.add_box(cap, base + Vector3(0, height - 0.075, 0), Vector3(r * 3.6, 0.15, r * 3.6))
	if collide:
		col_cyl(base, r * 1.5, height)


func _arcade(id: String, room: Dictionary, si: Dictionary, a: float, e: float) -> void:
	var h := float(room["h"])
	var length := e - a
	var nbays := maxi(1, int(round(length / 4.0)))
	var bay := length / nbays
	var off := 0.3
	var depth := 0.5
	var r: Array = room["rect"]
	var corr_depth := float(r[3]) - float(r[1]) if si["axis"] == "z" else float(r[2]) - float(r[0])
	for i in range(nbays + 1):
		var s := a + bay * i
		_column(_along(si, s, off, 0.0), 2.7, 0.2)
	for i in range(nbays):
		var s0 := a + bay * i
		var sm := s0 + bay * 0.5
		var ow := bay - 0.6
		var spring := 2.7
		var curve := MeshBatch.arch_curve(ow, spring, 10, 0.6)
		var poly := PackedVector2Array([Vector2(-bay * 0.5, spring)])
		poly.append_array(curve)
		poly.append(Vector2(bay * 0.5, spring))
		poly.append(Vector2(bay * 0.5, h))
		poly.append(Vector2(-bay * 0.5, h))
		var pl := _plane(si, sm, off - depth * 0.5, depth)
		b.add_extrude("plaster_ext", poly, pl["origin"], pl["right"], pl["up"], depth, 3.0, "stone_red" if i % 2 == 0 else "stone_white")
		col_box(_along(si, sm, off, (4.1 + h) * 0.5), Vector3(bay, h - 4.1, depth) if si["axis"] == "z" else Vector3(depth, h - 4.1, bay), 0.0, true)
		# revak kubbeleri
		var dome_base := _along(si, sm, corr_depth * 0.5, h + 0.35)
		var dr := minf(1.9, minf(bay, corr_depth) * 0.47)
		b.add_tube("plaster_ext", dome_base, dr, dr, 0.45, 8, false)
		b.add_dome("lead", dome_base + Vector3(0, 0.45, 0), dr + 0.08, dr * 0.85, 12, 5)
		var top := dome_base + Vector3(0, 0.45 + dr * 0.85, 0)
		b.add_tube("gold_plain", top, 0.05, 0.03, 0.45, 6)
		b.add_sphere("gold_plain", top + Vector3(0, 0.3, 0), Vector3(0.08, 0.08, 0.08), 6, 4)
		# revak kandili
		if i % 2 == 1:
			var lp := _along(si, sm, corr_depth * 0.5, h - 1.4)
			b.add_tube("iron", lp + Vector3(0, 0.25, 0), 0.01, 0.01, 1.15, 4)
			b.add_sphere("lamp", lp, Vector3(0.13, 0.18, 0.13), 8, 5)
	# saçak
	var eave_c := _along(si, (a + e) * 0.5, -0.55, h + 0.1)
	b.add_box("wood_dark", eave_c, Vector3(length + 0.6, 0.18, 1.5) if si["axis"] == "z" else Vector3(1.5, 0.18, length + 0.6), 0.0, 2.0)
	b.add_box("lead_roof", eave_c + Vector3(0, 0.12, 0), Vector3(length + 0.7, 0.06, 1.6) if si["axis"] == "z" else Vector3(1.6, 0.06, length + 0.7), 0.0, 4.0)


func _flat_ceiling(id: String, room: Dictionary) -> void:
	var r: Array = room["rect"]
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var h := float(room["h"])
	_slab(x0, z0, x1, z1, h)
	if room["kind"] == "room":
		_parapet(x0, z0, x1, z1, h)
	# kandiller
	if room["kind"] == "corridor":
		var cx := (x0 + x1) * 0.5
		var cz := (z0 + z1) * 0.5
		var w := x1 - x0
		var d := z1 - z0
		var n := int(maxf(w, d) / 14.0)
		for i in range(n):
			var t := (float(i) + 0.5) / n
			var p := Vector3(lerpf(x0, x1, t) if w > d else cx, h - 1.3, cz if w > d else lerpf(z0, z1, t))
			omni(p, 9.0, 0.55)
	else:
		var cx2 := (x0 + x1) * 0.5
		var cz2 := (z0 + z1) * 0.5
		_hanging_lamp(Vector3(cx2, h - 2.2, cz2), h)
		omni(Vector3(cx2, h - 1.8, cz2), maxf(x1 - x0, z1 - z0) * 0.85, 1.25)


func _slab(x0: float, z0: float, x1: float, z1: float, h: float) -> void:
	var c := Vector3((x0 + x1) * 0.5, h + 0.175, (z0 + z1) * 0.5)
	var s := Vector3(x1 - x0, 0.35, z1 - z0)
	b.add_box("ceiling", c, s, 0.0, Mats.tile("ceiling"), 8)
	b.add_box("lead_roof", c, s, 0.0, 4.0, 1 | 2 | 4 | 16 | 32)
	col_box(c, s, 0.0, true)
	occ_box(c, s)


func _parapet(x0: float, z0: float, x1: float, z1: float, h: float) -> void:
	var y := h + 0.35 + 0.25
	b.add_box("stone_ext", Vector3((x0 + x1) * 0.5, y, z0 + 0.15), Vector3(x1 - x0, 0.5, 0.3), 0.0, 3.0)
	b.add_box("stone_ext", Vector3((x0 + x1) * 0.5, y, z1 - 0.15), Vector3(x1 - x0, 0.5, 0.3), 0.0, 3.0)
	b.add_box("stone_ext", Vector3(x0 + 0.15, y, (z0 + z1) * 0.5), Vector3(0.3, 0.5, z1 - z0), 0.0, 3.0)
	b.add_box("stone_ext", Vector3(x1 - 0.15, y, (z0 + z1) * 0.5), Vector3(0.3, 0.5, z1 - z0), 0.0, 3.0)


func _dome_ceiling(id: String, room: Dictionary) -> void:
	var r: Array = room["rect"]
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var h := float(room["h"])
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var s := minf(x1 - x0, z1 - z0) * 0.56
	var hs := s * 0.5
	_slab(x0, z0, x1, cz - hs, h)
	_slab(x0, cz + hs, x1, z1, h)
	_slab(x0, cz - hs, cx - hs, cz + hs, h)
	_slab(cx + hs, cz - hs, x1, cz + hs, h)
	_parapet(x0, z0, x1, z1, h)
	var R := hs * sqrt(2.0) + 0.05
	var drum_h := 1.5
	b.add_tube("iznik_blue", Vector3(cx, h, cz), R, R, 0.35 + drum_h, 8, true, false, false, 8.0, 2.0)
	b.add_tube("plaster_ext", Vector3(cx, h + 0.35, cz), R + 0.3, R + 0.3, drum_h, 8, false)
	b.add_ring("lead_roof", Vector3(cx, h + 0.35 + drum_h, cz), R - 0.05, R + 0.32, 8)
	for k in range(8):
		var a := TAU * (float(k) + 0.5) / 8.0
		var dist := R * cos(PI / 8.0)
		var dir := Vector3(cos(a), 0, sin(a))
		var p := Vector3(cx, h + 0.35 + drum_h * 0.5, cz) + dir * (dist - 0.03)
		b.add_panel("window", p, 0.7, 0.95, face_yaw(dir), false)
		var po := Vector3(cx, h + 0.35 + drum_h * 0.5, cz) + dir * ((R + 0.3) * cos(PI / 8.0) + 0.03)
		b.add_panel("lattice", po, 0.8, 1.05, face_yaw(-dir), false, 0.5)
	var dome_base := Vector3(cx, h + 0.35 + drum_h, cz)
	b.add_dome("dome_in", dome_base, R, R * 0.92, 28, 12, true)
	b.add_dome("lead", dome_base, R + 0.32, (R + 0.32) * 0.96, 28, 10, false)
	_finial(dome_base + Vector3(0, (R + 0.32) * 0.96 - 0.05, 0), 1.6)
	_chandelier(Vector3(cx, h - 2.8, cz), minf(hs * 0.55, 3.0), h + 0.35 + drum_h + R * 0.6)
	omni(Vector3(cx, h - 2.2, cz), maxf(x1 - x0, z1 - z0) * 0.8, 1.35)
	omni(Vector3(cx, h + drum_h, cz), R * 2.2, 0.6, Color(1, 0.9, 0.75))


func _finial(top: Vector3, sc: float) -> void:
	b.add_tube("gold_plain", top, 0.08 * sc, 0.05 * sc, 0.9 * sc, 6)
	b.add_sphere("gold_plain", top + Vector3(0, 0.35 * sc, 0), Vector3.ONE * 0.16 * sc, 8, 6)
	b.add_sphere("gold_plain", top + Vector3(0, 0.66 * sc, 0), Vector3.ONE * 0.11 * sc, 8, 6)
	var cres := PackedVector2Array()
	for i in range(13):
		var a := deg_to_rad(30.0) - deg_to_rad(240.0) * float(i) / 12.0
		cres.append(Vector2(cos(a), sin(a)) * 0.3 * sc)
	var c_in := Vector2(0, 0.1 * sc)
	var ri := sqrt(pow(0.26 * sc, 2) + pow(0.05 * sc, 2))
	var a0 := atan2(0.15 * sc - c_in.y, -0.26 * sc)
	var a1 := atan2(0.15 * sc - c_in.y, 0.26 * sc) + TAU
	for i in range(1, 12):
		var a2 := lerpf(a0, a1, float(i) / 12.0)
		cres.append(c_in + Vector2(cos(a2), sin(a2)) * ri)
	b.add_extrude("gold_plain", cres, top + Vector3(0, 1.15 * sc, -0.03 * sc), Vector3(1, 0, 0), Vector3(0, 1, 0), 0.06 * sc, 1.0)


func _chandelier(center: Vector3, radius: float, ceil_y: float) -> void:
	b.add_tube("brass", center, radius, radius, 0.08, 24, false)
	b.add_tube("brass", center, radius - 0.05, radius - 0.05, 0.08, 24, true)
	b.add_tube("brass", center + Vector3(0, -0.4, 0), radius * 0.55, radius * 0.55, 0.06, 16, false)
	var n := 16
	for i in range(n):
		var a := TAU * float(i) / n
		var p := center + Vector3(cos(a), 0, sin(a)) * radius
		b.add_sphere("lamp_glass", p + Vector3(0, 0.16, 0), Vector3(0.09, 0.15, 0.09), 6, 4)
		b.add_sphere("lamp", p + Vector3(0, 0.12, 0), Vector3(0.04, 0.06, 0.04), 4, 3)
	for i in range(4):
		var a2 := TAU * float(i) / 4.0
		var p2 := center + Vector3(cos(a2), 0, sin(a2)) * radius
		b.add_tube("iron", p2, 0.012, 0.012, ceil_y - center.y, 4)


func _hanging_lamp(p: Vector3, ceil_y: float) -> void:
	b.add_tube("iron", p + Vector3(0, 0.3, 0), 0.012, 0.012, ceil_y - p.y - 0.3, 4)
	b.add_sphere("lamp_glass", p, Vector3(0.22, 0.3, 0.22), 10, 6)
	b.add_sphere("lamp", p + Vector3(0, -0.05, 0), Vector3(0.08, 0.1, 0.08), 6, 4)
	b.add_tube("brass", p + Vector3(0, 0.25, 0), 0.12, 0.05, 0.12, 8, false, true)


# ---------------------------------------------------------------- mobilyalar

func _carpet(mat: String, c: Vector3, w: float, d: float, yaw: float = 0.0) -> void:
	b.add_box(mat, Vector3(c.x, 0.015, c.z), Vector3(w, 0.03, d), yaw, 0.0)


## Duvar boyunca sedir: a->e uç noktaları zeminde, inward odanın içine doğru
func _sedir(room_id: String, a: Vector3, e: Vector3, inward: Vector3, cush: String, depth: float = 1.0, spacing: float = 1.5, tag: String = "") -> void:
	var dir := e - a
	var length := dir.length()
	dir = dir.normalized()
	var yaw := atan2(-dir.z, dir.x)
	var mid := (a + e) * 0.5
	b.add_box("wood_dark", mid + inward * (depth * 0.5) + Vector3(0, 0.17, 0), Vector3(length, 0.34, depth), yaw, 1.5)
	b.add_box(cush, mid + inward * (depth * 0.5) + Vector3(0, 0.41, 0), Vector3(length, 0.14, depth * 0.96), yaw)
	b.add_box(cush, mid + inward * 0.13 + Vector3(0, 0.72, 0), Vector3(length, 0.5, 0.24), yaw)
	col_box(mid + inward * (depth * 0.5) + Vector3(0, 0.38, 0), Vector3(length, 0.76, depth), yaw)
	var n := int(length / spacing)
	for i in range(n):
		var t := (float(i) + 0.5) / n * length
		spot(room_id, a + dir * t + inward * (depth + 0.05), "sit", face_yaw(inward), tag)


func _sini(room_id: String, c: Vector3, r: float = 0.6, cush: String = "brocade_red", seats: int = 4) -> void:
	b.add_tube("wood_dark", c, 0.18, 0.18, 0.32, 8, false, true)
	b.add_tube("brass", c + Vector3(0, 0.32, 0), r, r, 0.04, 18, false, true)
	b.add_sphere("food", c + Vector3(0.15, 0.4, 0.05), Vector3(0.12, 0.06, 0.12), 6, 4)
	b.add_tube("brass", c + Vector3(-0.2, 0.36, -0.1), 0.06, 0.05, 0.14, 6, false, true)
	col_cyl(c, r, 0.7)
	for i in range(seats):
		var a := TAU * float(i) / seats + PI * 0.25
		var dir := Vector3(cos(a), 0, sin(a))
		var p := c + dir * (r + 0.55)
		b.add_box(cush, p + Vector3(0, 0.07, 0), Vector3(0.62, 0.14, 0.62), a)
		spot(room_id, p, "sit_low", face_yaw(-dir))


func _shelf(c: Vector3, yaw: float, width: float = 2.4, height: float = 2.8) -> void:
	b.add_box("wood_dark", c + Vector3(0, height * 0.5, 0), Vector3(width, height, 0.5), yaw, 1.5)
	b.add_box("books", xf(c, yaw, Vector3(0, height * 0.5 - 0.05, 0.06)), Vector3(width - 0.16, height - 0.3, 0.42), yaw, 2.0)
	b.add_box("wood_dark", xf(c, yaw, Vector3(0, height + 0.06, 0.02)), Vector3(width + 0.12, 0.12, 0.56), yaw, 1.5)
	col_box(c + Vector3(0, height * 0.5, 0), Vector3(width, height, 0.55), yaw)


func _bed(room_id: String, c: Vector3, yaw: float, cloth: String = "brocade_red", canopy: bool = true) -> void:
	b.add_box("wood_dark", xf(c, yaw, Vector3(0, 0.22, 0)), Vector3(2.2, 0.44, 2.6), yaw, 1.5)
	b.add_box("fabric_cream", xf(c, yaw, Vector3(0, 0.55, 0)), Vector3(2.0, 0.24, 2.4), yaw)
	b.add_box(cloth, xf(c, yaw, Vector3(0, 0.69, 0.35)), Vector3(2.05, 0.06, 1.7), yaw)
	b.add_box("fabric_cream", xf(c, yaw, Vector3(-0.45, 0.76, -0.95)), Vector3(0.75, 0.18, 0.4), yaw)
	b.add_box("fabric_cream", xf(c, yaw, Vector3(0.45, 0.76, -0.95)), Vector3(0.75, 0.18, 0.4), yaw)
	b.add_box("wood_dark", xf(c, yaw, Vector3(0, 0.9, -1.27)), Vector3(2.2, 1.0, 0.1), yaw, 1.5)
	if canopy:
		for p in [Vector3(-1.05, 0, -1.25), Vector3(1.05, 0, -1.25), Vector3(-1.05, 0, 1.25), Vector3(1.05, 0, 1.25)]:
			b.add_tube("gold_plain", xf(c, yaw, p), 0.05, 0.05, 2.75, 6)
		b.add_box(cloth, xf(c, yaw, Vector3(0, 2.8, 0)), Vector3(2.3, 0.16, 2.7), yaw)
		b.add_box("curtain_red", xf(c, yaw, Vector3(-1.12, 1.6, -0.6)), Vector3(0.04, 2.2, 1.0), yaw)
		b.add_box("curtain_red", xf(c, yaw, Vector3(1.12, 1.6, -0.6)), Vector3(0.04, 2.2, 1.0), yaw)
	col_box(xf(c, yaw, Vector3(0, 0.5, 0)), Vector3(2.3, 1.0, 2.7), yaw)


func _chest(c: Vector3, yaw: float, size: Vector3 = Vector3(1.2, 0.7, 0.7), gold_inside: bool = false) -> void:
	b.add_box("wood_dark", c + Vector3(0, size.y * 0.5, 0), size, yaw, 1.0)
	b.add_box("gold_plain", xf(c, yaw, Vector3(0, size.y * 0.75, 0)), Vector3(size.x + 0.04, 0.06, size.z + 0.04), yaw)
	b.add_box("gold_plain", xf(c, yaw, Vector3(-size.x * 0.35, size.y * 0.5, 0)), Vector3(0.06, size.y + 0.02, size.z + 0.04), yaw)
	b.add_box("gold_plain", xf(c, yaw, Vector3(size.x * 0.35, size.y * 0.5, 0)), Vector3(0.06, size.y + 0.02, size.z + 0.04), yaw)
	if gold_inside:
		b.add_sphere("gold_plain", c + Vector3(0, size.y + 0.05, 0), Vector3(size.x * 0.4, 0.14, size.z * 0.35), 8, 4)
	col_box(c + Vector3(0, size.y * 0.5, 0), size, yaw)


func _rahle(c: Vector3, yaw: float, with_book: bool = true) -> void:
	b.add_box("wood_dark", xf(c, yaw, Vector3(0, 0.18, 0)), Vector3(0.6, 0.36, 0.4), yaw, 1.0)
	b.add_box("wood", xf(c, yaw, Vector3(0, 0.42, 0)), Vector3(0.62, 0.04, 0.45), yaw, 1.0)
	if with_book:
		b.add_box("parchment", xf(c, yaw, Vector3(0, 0.46, 0)), Vector3(0.42, 0.03, 0.3), yaw)
		b.add_box("brocade_red", xf(c, yaw, Vector3(0, 0.445, 0)), Vector3(0.44, 0.025, 0.32), yaw)


func _brazier(c: Vector3) -> void:
	b.add_tube("brass", c, 0.25, 0.18, 0.6, 8, false, false, true)
	b.add_tube("brass", c + Vector3(0, 0.6, 0), 0.18, 0.42, 0.25, 12, false, false, false)
	b.add_tube("brass", c + Vector3(0, 0.6, 0), 0.17, 0.4, 0.24, 12, true, false, false)
	b.add_sphere("fire", c + Vector3(0, 0.8, 0), Vector3(0.28, 0.08, 0.28), 8, 4)
	col_cyl(c, 0.45, 1.0)


func _vase(c: Vector3, mat: String = "iznik_blue", flowers: bool = true) -> void:
	b.add_sphere(mat, c + Vector3(0, 0.32, 0), Vector3(0.24, 0.32, 0.24), 10, 6)
	b.add_tube(mat, c + Vector3(0, 0.55, 0), 0.08, 0.12, 0.2, 10)
	if flowers:
		b.add_sphere("flowers", c + Vector3(0, 0.95, 0), Vector3(0.32, 0.25, 0.32), 8, 5)
		b.add_tube("leaf", c + Vector3(0, 0.7, 0), 0.03, 0.03, 0.2, 4)
	col_cyl(c, 0.3, 0.8)


func _cypress(c: Vector3, height: float = 7.0) -> void:
	b.add_tube("bark", c, 0.16, 0.12, 0.9, 6)
	var seed_ := int(absf(c.x * 13.0 + c.z * 7.0))
	_foliage(c + Vector3(0, 0.55, 0), height, func(t: float) -> float:
		return 0.82 * pow(sin(PI * clampf(pow(t, 0.8), 0.0, 1.0)), 0.75) * (1.0 - 0.25 * t), 12, 16, 0.2, seed_, "foliage_dark")
	col_cyl(c, 0.45, 2.0)


func _round_tree(c: Vector3, sc: float = 1.0, leaf: String = "leaf") -> void:
	b.add_tube("bark", c, 0.3 * sc, 0.2 * sc, 3.2 * sc, 7)
	var mat := "foliage_light" if leaf == "leaf_light" else "foliage"
	var seed_ := int(absf(c.x * 11.0 + c.z * 5.0))
	_foliage(c + Vector3(0, 2.3 * sc, 0), 3.8 * sc, func(t: float) -> float:
		return 2.3 * sc * pow(sin(PI * t), 0.7), 12, 10, 0.18, seed_, mat)
	_foliage(c + Vector3(1.0 * sc, 2.6 * sc, 0.5 * sc), 2.4 * sc, func(t: float) -> float:
		return 1.5 * sc * pow(sin(PI * t), 0.7), 10, 8, 0.2, seed_ + 3, mat)
	col_cyl(c, 0.45 * sc, 3.0)


## Topaklı yaprak gövdesi: dönel yüzey + düzgün gürültü, yumuşak normaller, silindirik UV
func _foliage(base: Vector3, height: float, radius: Callable, segs: int, rings: int, noise_amp: float, seed_: int, mat: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var ph := []
	for i in range(6):
		ph.append(rng.randf() * TAU)
	var grid: Array = []
	for i in range(rings + 1):
		var t := float(i) / float(rings)
		var row: Array = []
		for k in range(segs):
			var th := float(k) / float(segs) * TAU
			var n := sin(th * 3.0 + ph[0] + t * 7.0) * 0.5 + sin(th * 5.0 + ph[1] - t * 11.0) * 0.3 + sin(t * 17.0 + ph[2]) * 0.2
			var r: float = float(radius.call(t)) * (1.0 + noise_amp * n)
			row.append(base + Vector3(cos(th) * r, t * height, sin(th) * r))
		grid.append(row)
	var tip := base + Vector3(0, height, 0)
	# yumuşak normaller: komşu farkları
	var nrm: Array = []
	for i in range(rings + 1):
		var row_n: Array = []
		for k in range(segs):
			var p: Vector3 = grid[i][k]
			var pu: Vector3 = grid[i][(k + 1) % segs] - grid[i][(k - 1 + segs) % segs]
			var pv: Vector3 = grid[mini(i + 1, rings)][k] - grid[maxi(i - 1, 0)][k]
			var nn := pu.cross(pv).normalized()
			var out := Vector3(p.x - base.x, 0, p.z - base.z)
			if nn.dot(out) < 0.0:
				nn = -nn
			row_n.append(nn if nn.length() > 0.1 else Vector3.UP)
		nrm.append(row_n)
	var circ := TAU * 0.8
	for i in range(rings):
		for k in range(segs):
			var k2 := (k + 1) % segs
			var u0 := float(k) / float(segs) * circ
			var u1 := float(k + 1) / float(segs) * circ
			var v0 := float(i) / float(rings) * height * 0.7
			var v1 := float(i + 1) / float(rings) * height * 0.7
			var a: Vector3 = grid[i][k]
			var b2: Vector3 = grid[i][k2]
			var c2: Vector3 = grid[i + 1][k2]
			var d: Vector3 = grid[i + 1][k]
			b.add_tri(mat, a, b2, c2, nrm[i][k], nrm[i][k2], nrm[i + 1][k2], Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1))
			b.add_tri(mat, a, c2, d, nrm[i][k], nrm[i + 1][k2], nrm[i + 1][k], Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1))


func _flowerbed(c: Vector3, w: float, d: float) -> void:
	b.add_box("marble_warm", c + Vector3(0, 0.17, 0), Vector3(w, 0.34, d), 0.0, 2.0)
	b.add_box("flowers", c + Vector3(0, 0.36, 0), Vector3(w - 0.25, 0.06, d - 0.25), 0.0, 1.6)
	col_box(c + Vector3(0, 0.35, 0), Vector3(w, 0.7, d))


func _lantern_post(c: Vector3) -> void:
	b.add_box("marble_warm", c + Vector3(0, 0.2, 0), Vector3(0.5, 0.4, 0.5))
	b.add_tube("iron", c + Vector3(0, 0.4, 0), 0.06, 0.05, 2.4, 6)
	b.add_tube("iron", c + Vector3(0, 2.8, 0), 0.22, 0.26, 0.5, 6, true, false, true)
	b.add_sphere("lamp", c + Vector3(0, 3.05, 0), Vector3(0.18, 0.24, 0.18), 6, 4)
	b.add_tube("lead", c + Vector3(0, 3.3, 0), 0.35, 0.02, 0.4, 6, false, false, true)
	col_cyl(c, 0.35, 2.5)
	omni(c + Vector3(0, 3.0, 0), 13.0, 2.4, Color(1.0, 0.75, 0.45), true)


func _basin(c: Vector3, r: float, h: float = 0.6, segs: int = 8, water: bool = true) -> void:
	b.add_tube("marble_warm", c, r, r, h, segs, false)
	b.add_tube("marble_warm", c, r - 0.3, r - 0.3, h, segs, true)
	b.add_ring("marble", c + Vector3(0, h, 0), r - 0.3, r, segs)
	if water:
		b.add_disc("water", c + Vector3(0, h - 0.15, 0), r - 0.3, segs, true, 2.0)
	col_cyl(c, r, h + 0.3)
	sound_points.append({"type": "fountain", "pos": c + Vector3(0, 0.8, 0)})


func _banner(c: Vector3, yaw: float, mat: String, w: float = 1.4, h: float = 3.2) -> void:
	b.add_box(mat, c, Vector3(w, h, 0.03), yaw)
	b.add_box("gold_plain", c + Vector3(0, h * 0.5 + 0.05, 0), Vector3(w + 0.3, 0.08, 0.08), yaw)
	# alt sivri uç
	var poly := PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(0, -0.5)])
	var right := Basis(Vector3.UP, yaw) * Vector3(1, 0, 0)
	var nrm := Basis(Vector3.UP, yaw) * Vector3(0, 0, 1)
	b.add_extrude(mat, poly, c - Vector3(0, h * 0.5, 0) - nrm * 0.015, right, Vector3.UP, 0.03, 1.0)


## Duvara yaslı dikey disk (kalkan, kasa kapısı, nişan tahtası). f: ön yüzün baktığı yön
func _wall_disc(mat: String, center: Vector3, f: Vector3, r: float, depth: float, segs: int = 20) -> void:
	var poly := PackedVector2Array()
	for i in range(segs):
		var a := TAU * float(i) / segs
		poly.append(Vector2(cos(a), sin(a)) * r)
	var right := f.cross(Vector3.UP).normalized()
	b.add_extrude(mat, poly, center, right, Vector3.UP, depth, r * 2.0)


func _guard_post(room_id: String, p: Vector3, look: Vector3) -> void:
	spot(room_id, p, "guard", face_yaw(look), "guard")


# ---------------------------------------------------------------- odalar

func _furnish_taht(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "taht"
	# kürsü (dais)
	b.add_box("marble_warm", Vector3(0, 0.1, -52.0), Vector3(10, 0.2, 5.3), 0.0, 2.0)
	col_box(Vector3(0, 0.1, -52.0), Vector3(10, 0.2, 5.3))
	_carpet("carpet_red", Vector3(0, 0.2, -52.0), 8.5, 4.6)
	b.add_box("carpet_red", Vector3(0, 0.215, -52.0), Vector3(8.5, 0.03, 4.6), 0.0, 0.0)
	# taht
	var tc := Vector3(0, 0.2, -53.0)
	b.add_box("gold", tc + Vector3(0, 0.3, 0), Vector3(2.4, 0.6, 1.8), 0.0, 0.8)
	b.add_box("brocade_red", tc + Vector3(0, 0.68, 0.1), Vector3(2.1, 0.18, 1.5))
	b.add_box("gold", tc + Vector3(0, 1.4, -0.82), Vector3(2.4, 1.8, 0.18), 0.0, 0.8)
	b.add_box("brocade_red", tc + Vector3(0, 1.25, -0.68), Vector3(1.9, 1.0, 0.14))
	for sx in [-1.12, 1.12]:
		b.add_box("gold", tc + Vector3(sx, 0.95, 0.05), Vector3(0.18, 0.5, 1.6), 0.0, 0.8)
		b.add_sphere("gold_plain", tc + Vector3(sx, 1.25, 0.8), Vector3(0.12, 0.12, 0.12), 6, 4)
	b.add_extrude("gold", MeshBatch.arch_curve(2.4, 2.25, 8, 0.65), tc + Vector3(0, 0, -0.91), Vector3(1, 0, 0), Vector3(0, 1, 0), 0.18, 0.8)
	# baldaken
	for p in [Vector3(-1.6, 0, -1.2), Vector3(1.6, 0, -1.2), Vector3(-1.6, 0, 1.3), Vector3(1.6, 0, 1.3)]:
		b.add_tube("gold_plain", tc + p, 0.07, 0.07, 3.6, 8)
	b.add_box("brocade_gold", tc + Vector3(0, 3.7, 0.05), Vector3(3.6, 0.22, 2.9))
	b.add_dome("gold", tc + Vector3(0, 3.8, 0.05), 1.5, 1.1, 16, 6, false, 2.0, 1.0)
	b.add_sphere("gold_plain", tc + Vector3(0, 5.0, 0.05), Vector3(0.14, 0.14, 0.14), 6, 4)
	col_box(tc + Vector3(0, 1.0, -0.2), Vector3(2.5, 2.0, 1.6))
	interact("taht", id, Vector3(0, 0, -51.1), "Tahta Otur", "sit_throne", {"seat": tc + Vector3(0, 0.62, 0.1), "yaw": PI})
	# kırmızı yol halısı
	_carpet("carpet_red", Vector3(0, 0, -41.5), 4.0, 15.0)
	# sütunlar
	for sx in [-8.5, 8.5]:
		for z in [-50.5, -45.0, -39.5]:
			_column(Vector3(sx, 0, z), 8.6, 0.38)
	# yan sedirler
	_sedir(id, Vector3(-13.65, 0, -52), Vector3(-13.65, 0, -36), Vector3(1, 0, 0), "brocade_red", 1.0, 1.6, "courtier")
	_sedir(id, Vector3(13.65, 0, -52), Vector3(13.65, 0, -36), Vector3(-1, 0, 0), "brocade_red", 1.0, 1.6, "courtier")
	_carpet("carpet_blue", Vector3(-10.5, 0, -44), 3.6, 14)
	_carpet("carpet_blue", Vector3(10.5, 0, -44), 3.6, 14)
	_brazier(Vector3(-4.2, 0.2, -50.4))
	_brazier(Vector3(4.2, 0.2, -50.4))
	_banner(Vector3(-4.0, 4.6, -54.55), 0.0, "banner_red", 1.5, 3.6)
	_banner(Vector3(4.0, 4.6, -54.55), 0.0, "banner_green", 1.5, 3.6)
	_vase(Vector3(-12.6, 0, -53.8))
	_vase(Vector3(12.6, 0, -53.8))
	_guard_post(id, Vector3(-3.0, 0, -34.4), Vector3(0, 0, 1))
	_guard_post(id, Vector3(3.0, 0, -34.4), Vector3(0, 0, 1))
	_guard_post(id, Vector3(-5.6, 0.2, -52.5), Vector3(0, 0, 1))
	for z in [-48.0, -44.0, -40.0, -36.0]:
		spot(id, Vector3(-5.0, 0, z), "stand", face_yaw(Vector3(1, 0, 0)))
		spot(id, Vector3(5.0, 0, z), "stand", face_yaw(Vector3(-1, 0, 0)))
	spot(id, Vector3(-2.2, 0.2, -50.0), "stand", PI, "advisor")
	spot(id, Vector3(2.2, 0.2, -50.0), "stand", PI, "advisor")
	omni(Vector3(0, 3.5, -51), 9.0, 0.9)


func _furnish_divan(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "divan"
	_sedir(id, Vector3(-59.65, 0, -26.5), Vector3(-59.65, 0, -20.6), Vector3(1, 0, 0), "brocade_green", 1.1, 1.7, "vezir")
	_sedir(id, Vector3(-59.65, 0, -15.4), Vector3(-59.65, 0, -9.5), Vector3(1, 0, 0), "brocade_green", 1.1, 1.7, "vezir")
	_sedir(id, Vector3(-58.5, 0, -27.65), Vector3(-47.5, 0, -27.65), Vector3(0, 0, 1), "brocade_green", 1.1, 1.7, "vezir")
	_sedir(id, Vector3(-42.5, 0, -27.65), Vector3(-31.5, 0, -27.65), Vector3(0, 0, 1), "brocade_green", 1.1, 1.7, "vezir")
	_sedir(id, Vector3(-58.5, 0, -8.35), Vector3(-47, 0, -8.35), Vector3(0, 0, -1), "brocade_green", 1.1, 1.7, "katip")
	# başköşe (hükümdar kürsüsü) batı duvarı ortası
	b.add_box("marble_warm", Vector3(-57.3, 0.12, -18), Vector3(3.6, 0.24, 4.4), 0.0, 2.0)
	col_box(Vector3(-57.3, 0.12, -18), Vector3(3.6, 0.24, 4.4))
	b.add_box("gold", Vector3(-58.4, 0.5, -18), Vector3(1.4, 0.5, 2.6), 0.0, 0.8)
	b.add_box("brocade_gold", Vector3(-58.3, 0.82, -18), Vector3(1.2, 0.14, 2.4))
	b.add_box("brocade_red", Vector3(-59.1, 1.25, -18), Vector3(0.3, 0.8, 2.3))
	col_box(Vector3(-58.4, 0.6, -18), Vector3(1.6, 1.2, 2.8))
	interact("divan_kursu", id, Vector3(-56.2, 0, -18), "Divanı Topla", "divan", {"seat": Vector3(-58.2, 0.85, -18), "yaw": face_yaw(Vector3(1, 0, 0))})
	# Adalet Kasrı kafesi: kuzey duvarda yaldızlı kafes pencere
	var kx := -37.0
	b.add_panel("lattice", Vector3(kx, 4.4, -27.62), 2.6, 1.8, PI, false, 0.6)
	b.add_panel("black", Vector3(kx, 4.4, -27.64), 2.6, 1.8, PI, false)
	var arch := MeshBatch.arch_curve(2.6, 5.3, 10, 0.62)
	var band := PackedVector2Array(arch)
	var outer := MeshBatch.arch_curve(3.0, 5.3, 10, 0.62)
	for i in range(outer.size() - 1, -1, -1):
		band.append(outer[i])
	b.add_extrude("gold_plain", band, Vector3(kx, 0, -27.65), Vector3(1, 0, 0), Vector3(0, 1, 0), 0.06, 1.0)
	b.add_extrude("lattice", MeshBatch.arch_curve(2.6, 5.3, 10, 0.62), Vector3(kx, 0, -27.64), Vector3(1, 0, 0), Vector3(0, 1, 0), 0.02, 0.6)
	b.add_box("gold_plain", Vector3(kx, 3.45, -27.6), Vector3(3.0, 0.15, 0.12))
	for sx in [-1.4, 1.4]:
		b.add_box("gold_plain", Vector3(kx + sx, 4.37, -27.6), Vector3(0.18, 1.85, 0.08))
	_carpet("carpet_blue", Vector3(-46, 0, -18), 16, 12)
	_carpet("carpet_red", Vector3(-53, 0, -18), 3.0, 8)
	for x in [-50.0, -46.0, -42.0]:
		_rahle(Vector3(x, 0, -11.5), 0.0)
		spot(id, Vector3(x, 0, -10.7), "sit_low", 0.0, "katip")
	_brazier(Vector3(-38, 0, -24))
	_brazier(Vector3(-38, 0, -12))
	_vase(Vector3(-31.2, 0, -26.8))
	_vase(Vector3(-31.2, 0, -9.2))
	for z in [-24.0, -20.0, -16.0, -12.0]:
		spot(id, Vector3(-36.0, 0, z), "stand", face_yaw(Vector3(-1, 0, 0)))
	_guard_post(id, Vector3(-31.4, 0, -20.6), Vector3(-1, 0, 0))


func _furnish_hukumdar(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "hukumdar"
	_bed(id, Vector3(-33.0, 0, -52.0), 0.0, "brocade_red", true)
	interact("yatak", id, Vector3(-33.0, 0, -49.6), "Uyu", "sleep")
	_carpet("carpet_red", Vector3(-26, 0, -45), 10, 8)
	_sedir(id, Vector3(-14.35, 0, -52.5), Vector3(-14.35, 0, -51.0), Vector3(-1, 0, 0), "brocade_purple", 1.0, 1.4)
	_sedir(id, Vector3(-14.35, 0, -46.8), Vector3(-14.35, 0, -36.0), Vector3(-1, 0, 0), "brocade_purple", 1.0, 1.6)
	# yazı masası
	b.add_box("wood_dark", Vector3(-21.0, 0.4, -51.6), Vector3(2.4, 0.8, 1.1), 0.0, 1.5)
	b.add_box("parchment", Vector3(-21.3, 0.82, -51.6), Vector3(0.7, 0.03, 0.5))
	b.add_box("brocade_red", Vector3(-20.4, 0.86, -51.8), Vector3(0.5, 0.1, 0.36))
	b.add_tube("brass", Vector3(-20.0, 0.8, -51.3), 0.06, 0.05, 0.18, 6, false, true)
	b.add_box("brocade_gold", Vector3(-21.0, 0.25, -50.4), Vector3(0.9, 0.5, 0.7))
	col_box(Vector3(-21.0, 0.45, -51.6), Vector3(2.4, 0.9, 1.1))
	interact("masa", id, Vector3(-21.0, 0, -49.9), "Devlet Defterleri", "state_book")
	# ocak (külahlı şömine)
	b.add_box("marble_warm", Vector3(-26.0, 0.6, -54.3), Vector3(2.4, 1.2, 0.9), 0.0, 2.0)
	b.add_box("black", Vector3(-26.0, 0.55, -53.86), Vector3(1.4, 0.9, 0.05))
	b.add_sphere("fire", Vector3(-26.0, 0.35, -54.0), Vector3(0.5, 0.18, 0.25), 8, 4)
	b.add_tube("plaster", Vector3(-26.0, 1.2, -54.25), 1.2, 0.25, 3.0, 4, false, false, false, 1.0, 1.0, PI * 0.25)
	b.add_box("gold_plain", Vector3(-26.0, 1.25, -53.85), Vector3(2.5, 0.1, 0.12))
	col_box(Vector3(-26.0, 1.0, -54.3), Vector3(2.4, 2.0, 0.9))
	omni(Vector3(-26.0, 1.0, -52.8), 6.0, 1.0, Color(1.0, 0.55, 0.25))
	_chest(Vector3(-36.6, 0, -48.6), PI * 0.5, Vector3(1.3, 0.75, 0.75))
	_shelf(Vector3(-29.6, 0, -54.4), 0.0, 2.6, 2.6)
	_vase(Vector3(-15.0, 0, -54.0))
	_vase(Vector3(-37.0, 0, -34.0))
	_sini(id, Vector3(-24.0, 0, -42.0), 0.6, "brocade_purple", 4)
	b.add_panel("steel", Vector3(-37.6, 1.9, -40.0), 1.0, 1.6, PI * 0.5, false)
	b.add_box("gold_plain", Vector3(-37.62, 1.9, -40.0), Vector3(0.05, 1.8, 1.2))
	spot(id, Vector3(-30.0, 0, -40.0), "stand", 0.0)
	spot(id, Vector3(-18.0, 0, -42.0), "stand", 0.0)


func _furnish_kutuphane(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "kutuphane"
	for x in [-57.5, -54.5, -51.5, -45.0, -42.0]:
		_shelf(Vector3(x, 0, -54.35), 0.0, 2.8, 3.2)
	for z in [-51.5, -48.0, -40.5, -37.0]:
		_shelf(Vector3(-59.35, 0, z), PI * 0.5, 2.8, 3.2)
	_carpet("carpet_green", Vector3(-48, 0, -44), 11, 9)
	for p in [Vector3(-51, 0, -46), Vector3(-48, 0, -46), Vector3(-45, 0, -46), Vector3(-51, 0, -42), Vector3(-48, 0, -42), Vector3(-45, 0, -42)]:
		_rahle(p, 0.0)
		b.add_box("brocade_green", p + Vector3(0, 0.07, 0.65), Vector3(0.6, 0.14, 0.6))
		spot(id, p + Vector3(0, 0, 0.7), "sit_low", 0.0, "reader")
	interact("rahle", id, Vector3(-48, 0, -40.8), "Kitap Oku", "read")
	# küre
	b.add_tube("brass", Vector3(-41.0, 0, -37.0), 0.25, 0.06, 0.9, 8, false, false, true)
	b.add_sphere("brocade_blue", Vector3(-41.0, 1.35, -37.0), Vector3(0.45, 0.45, 0.45), 14, 8)
	b.add_tube("brass", Vector3(-41.0, 0.9, -37.0), 0.5, 0.5, 0.04, 18, false)
	col_cyl(Vector3(-41.0, 0, -37.0), 0.5, 1.8)
	_sedir(id, Vector3(-38.35, 0, -53.0), Vector3(-38.35, 0, -46.0), Vector3(-1, 0, 0), "brocade_green", 1.0, 1.5)
	_vase(Vector3(-39.0, 0, -34.2), "iznik", true)
	spot(id, Vector3(-55.0, 0, -44.0), "stand", PI * 0.5, "browse")
	spot(id, Vector3(-48.0, 0, -51.5), "stand", 0.0, "browse")


func _furnish_valide(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "valide"
	_sedir(id, Vector3(15.5, 0, -54.65), Vector3(34.5, 0, -54.65), Vector3(0, 0, 1), "brocade_purple", 1.1, 1.6, "valide")
	_sedir(id, Vector3(35.65, 0, -53.5), Vector3(35.65, 0, -46.5), Vector3(-1, 0, 0), "brocade_purple", 1.1, 1.6)
	_sedir(id, Vector3(35.65, 0, -41.5), Vector3(35.65, 0, -35.0), Vector3(-1, 0, 0), "brocade_purple", 1.1, 1.6)
	b.add_box("brocade_gold", Vector3(25, 0.52, -53.0), Vector3(2.0, 0.1, 1.0))
	_carpet("carpet_red", Vector3(25, 0, -45), 12, 10)
	_sini(id, Vector3(25.0, 0, -45.0), 0.75, "brocade_purple", 5)
	_sini(id, Vector3(19.0, 0, -40.0), 0.55, "brocade_red", 3)
	# nakış kasnağı
	b.add_tube("wood_dark", Vector3(17.5, 0, -50.0), 0.05, 0.05, 1.0, 6)
	b.add_tube("wood", Vector3(17.5, 1.0, -50.0), 0.45, 0.45, 0.05, 16, false, true)
	col_cyl(Vector3(17.5, 0, -50.0), 0.45, 1.1)
	_vase(Vector3(15.2, 0, -34.2))
	_vase(Vector3(34.8, 0, -34.2), "iznik_green")
	_chest(Vector3(15.0, 0, -45.0), PI * 0.5, Vector3(1.2, 0.7, 0.7))
	_banner(Vector3(21.0, 4.0, -54.62), 0.0, "curtain_red", 1.2, 3.0)
	_banner(Vector3(29.0, 4.0, -54.62), 0.0, "curtain_red", 1.2, 3.0)
	interact("valide_kose", id, Vector3(25, 0, -51.5), "Otur", "sit_here", {"seat": Vector3(25, 0.5, -53.4), "yaw": PI})
	spot(id, Vector3(22.0, 0, -37.0), "stand", 0.0)
	spot(id, Vector3(28.0, 0, -38.0), "stand", 0.0)


func _furnish_sehzade(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "sehzade"
	b.add_box("wood", Vector3(48, 0.15, -53.0), Vector3(5, 0.3, 2.6), 0.0, 1.5)
	col_box(Vector3(48, 0.15, -53.0), Vector3(5, 0.3, 2.6))
	_rahle(Vector3(48, 0.3, -52.6), PI)
	b.add_box("brocade_green", Vector3(48, 0.38, -53.5), Vector3(0.8, 0.16, 0.8))
	spot(id, Vector3(48, 0.3, -53.4), "sit_low", PI, "hoca")
	for row in [-47.5, -44.0]:
		for x in [42.5, 46.0, 49.5, 53.0]:
			_rahle(Vector3(x, 0, row), PI)
			b.add_box("brocade_blue", Vector3(x, 0.07, row + 0.65), Vector3(0.6, 0.14, 0.6))
			spot(id, Vector3(x, 0, row + 0.7), "sit_low", 0.0, "ogrenci")
	_carpet("carpet_blue", Vector3(47.75, 0, -45.7), 14, 7)
	# duvar haritası ve hat levhaları
	b.add_panel("parchment", Vector3(36.39, 3.2, -49.5), 4.0, 2.4, PI * 0.5, false)
	b.add_box("wood_dark", Vector3(36.37, 3.2, -49.5), Vector3(0.04, 2.6, 4.2))
	for x in [41.0, 55.0]:
		b.add_panel("parchment", Vector3(x, 3.4, -54.62), 1.4, 0.8, 0.0, false)
		b.add_box("gold_plain", Vector3(x, 3.4, -54.64), Vector3(1.55, 0.95, 0.03))
	_shelf(Vector3(59.35, 0, -51.0), -PI * 0.5, 2.6, 3.0)
	_shelf(Vector3(59.35, 0, -47.5), -PI * 0.5, 2.6, 3.0)
	# ok hedefi ve kılıç rafı
	b.add_tube("wood_dark", Vector3(57.5, 0, -38.0), 0.06, 0.06, 1.1, 6)
	_wall_disc("food", Vector3(57.5, 1.4, -38.0), Vector3(-1, 0, 0), 0.6, 0.15)
	_wall_disc("banner_red", Vector3(57.38, 1.4, -38.0), Vector3(-1, 0, 0), 0.3, 0.02)
	col_cyl(Vector3(57.5, 0, -38.0), 0.6, 1.4)
	b.add_box("wood_dark", Vector3(59.5, 1.2, -42.0), Vector3(0.3, 1.6, 2.0))
	for z in [-42.7, -42.2, -41.7, -41.2]:
		b.add_box("steel", Vector3(59.3, 1.25, z), Vector3(0.04, 1.3, 0.06))
	col_box(Vector3(59.5, 0.8, -42.0), Vector3(0.4, 1.6, 2.0))
	_vase(Vector3(37.0, 0, -34.2))
	spot(id, Vector3(44.0, 0, -38.0), "stand", 0.0)
	spot(id, Vector3(52.0, 0, -38.0), "stand", 0.0)


func _furnish_harem(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "harem"
	_basin(Vector3(45, 0, -18), 2.4, 0.6, 8)
	b.add_tube("marble_warm", Vector3(45, 0.4, -18), 0.35, 0.25, 1.1, 8, false, true)
	b.add_tube("marble_warm", Vector3(45, 1.5, -18), 0.7, 0.2, 0.25, 8, false, true, true)
	_sedir(id, Vector3(31.5, 0, -27.65), Vector3(58.5, 0, -27.65), Vector3(0, 0, 1), "brocade_purple", 1.1, 1.6, "harem")
	_sedir(id, Vector3(59.65, 0, -26.5), Vector3(59.65, 0, -10.0), Vector3(-1, 0, 0), "brocade_red", 1.1, 1.6, "harem")
	_carpet("carpet_red", Vector3(38, 0, -18), 8, 12)
	_carpet("carpet_green", Vector3(52.5, 0, -18), 8, 12)
	_sini(id, Vector3(38.0, 0, -22.0), 0.65, "brocade_red", 4)
	_sini(id, Vector3(52.0, 0, -14.0), 0.65, "brocade_gold", 4)
	# ud
	b.add_sphere("wood", Vector3(40.0, 0.6, -14.0), Vector3(0.3, 0.12, 0.38), 10, 6)
	b.add_box("wood_dark", Vector3(40.0, 0.62, -14.55), Vector3(0.06, 0.04, 0.5))
	# perdeler
	for x in [34.0, 56.0]:
		b.add_box("curtain_green", Vector3(x, 3.6, -27.6), Vector3(1.6, 4.8, 0.05))
	_vase(Vector3(31.0, 0, -9.0), "iznik_green")
	_vase(Vector3(59.0, 0, -9.0))
	_vase(Vector3(31.0, 0, -26.8), "iznik")
	interact("harem_cesme", id, Vector3(45, 0, -15.0), "Çeşme Başında Dinlen", "rest", {"minutes": 30})
	for p in [Vector3(42, 0, -14), Vector3(48, 0, -22), Vector3(36, 0, -16), Vector3(54, 0, -20)]:
		spot(id, p, "stand", face_yaw(Vector3(45, 0, -18) - p))


func _furnish_leyla(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "leyla"
	_bed(id, Vector3(41.5, 0, 11.5), PI, "brocade_blue", true)
	_sedir(id, Vector3(30.35, 0, -6.5), Vector3(30.35, 0, 2.0), Vector3(1, 0, 0), "brocade_blue", 1.0, 1.5, "leyla")
	_carpet("carpet_blue", Vector3(37.5, 0, 1.0), 7, 7)
	_rahle(Vector3(36.0, 0, 6.0), 0.0)
	b.add_box("parchment", Vector3(36.4, 0.47, 6.1), Vector3(0.3, 0.02, 0.4), 0.4)
	spot(id, Vector3(36.0, 0, 6.7), "sit_low", 0.0, "yazi")
	_shelf(Vector3(44.65, 0, 2.0), -PI * 0.5, 2.2, 2.4)
	b.add_sphere("wood", Vector3(33.0, 0.5, 8.0), Vector3(0.3, 0.12, 0.38), 10, 6)
	b.add_box("wood_dark", Vector3(33.0, 0.52, 7.45), Vector3(0.06, 0.04, 0.5))
	_vase(Vector3(44.2, 0, -7.2), "iznik_blue")
	_vase(Vector3(30.9, 0, 13.2))
	spot(id, Vector3(38.0, 0, -2.0), "stand", 0.0)
	spot(id, Vector3(36.0, 0, 9.0), "sleep", PI, "yatak")


func _furnish_feraye(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "feraye"
	_bed(id, Vector3(48.5, 0, 11.5), PI, "brocade_red", true)
	_sedir(id, Vector3(59.65, 0, -6.5), Vector3(59.65, 0, 4.0), Vector3(-1, 0, 0), "brocade_gold", 1.0, 1.5, "feraye")
	_carpet("carpet_red", Vector3(52.5, 0, 1.0), 7, 7)
	_chest(Vector3(56.5, 0, 12.8), PI, Vector3(1.0, 0.6, 0.6), true)
	b.add_box("wood_dark", Vector3(56.6, 0.4, -7.0), Vector3(2.0, 0.8, 0.9), 0.0, 1.5)
	b.add_box("parchment", Vector3(56.2, 0.82, -7.0), Vector3(0.6, 0.02, 0.45), 0.2)
	b.add_box("parchment", Vector3(57.0, 0.82, -6.9), Vector3(0.5, 0.02, 0.4), -0.3)
	col_box(Vector3(56.6, 0.45, -7.0), Vector3(2.0, 0.9, 0.9))
	spot(id, Vector3(56.6, 0, -6.0), "stand", PI, "masa")
	b.add_panel("steel", Vector3(45.38, 1.8, 3.0), 0.9, 1.5, PI * 0.5, false)
	b.add_box("gold_plain", Vector3(45.37, 1.8, 3.0), Vector3(0.05, 1.7, 1.1))
	_vase(Vector3(45.8, 0, -7.2), "iznik")
	spot(id, Vector3(52.0, 0, 3.0), "stand", 0.0)
	spot(id, Vector3(50.0, 0, 9.0), "sleep", PI, "yatak")


func _furnish_hazine(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "hazine"
	for p in [Vector3(-57.5, 0, -6.0), Vector3(-55.5, 0, -6.0), Vector3(-53.5, 0, -6.0), Vector3(-57.5, 0, 11.5), Vector3(-55.5, 0, 11.5)]:
		_chest(p, 0.0, Vector3(1.3, 0.8, 0.8), true)
	for p2 in [Vector3(-50.0, 0, 0.0), Vector3(-50.0, 0, 6.0)]:
		b.add_box("marble_warm", p2 + Vector3(0, 0.45, 0), Vector3(2.6, 0.9, 1.6), 0.0, 2.0)
		b.add_tube("gold_plain", p2 + Vector3(-0.6, 0.9, 0), 0.4, 0.0, 0.5, 10)
		b.add_tube("gold_plain", p2 + Vector3(0.5, 0.9, 0.2), 0.35, 0.0, 0.42, 10)
		b.add_sphere("gold", p2 + Vector3(0.1, 0.95, -0.4), Vector3(0.22, 0.12, 0.22), 8, 4)
		col_box(p2 + Vector3(0, 0.5, 0), Vector3(2.6, 1.0, 1.6))
	# kasa kapısı
	b.add_box("iron", Vector3(-59.6, 1.6, 3.0), Vector3(0.12, 3.2, 3.0))
	_wall_disc("iron", Vector3(-59.5, 1.8, 3.0), Vector3(1, 0, 0), 1.3, 0.06)
	_wall_disc("brass", Vector3(-59.43, 1.8, 3.0), Vector3(1, 0, 0), 0.35, 0.05)
	for zz in [1.8, 4.2]:
		b.add_box("brass", Vector3(-59.5, 1.6, zz), Vector3(0.06, 2.8, 0.08))
	# zırh ve kalkanlar
	for z in [-3.0, 9.0]:
		b.add_tube("wood_dark", Vector3(-59.0, 0, z), 0.05, 0.05, 1.8, 6)
		b.add_tube("steel", Vector3(-59.0, 1.1, z), 0.28, 0.24, 0.7, 10, false, true)
		b.add_sphere("steel", Vector3(-59.0, 1.95, z), Vector3(0.18, 0.22, 0.18), 8, 5)
		col_cyl(Vector3(-59.0, 0, z), 0.35, 2.0)
	# Hazine nazırı masası
	b.add_box("wood_dark", Vector3(-38.0, 0.4, 3.0), Vector3(1.0, 0.8, 2.8), 0.0, 1.5)
	b.add_box("parchment", Vector3(-38.0, 0.82, 2.4), Vector3(0.5, 0.03, 0.7))
	b.add_tube("brass", Vector3(-38.0, 0.8, 3.8), 0.04, 0.04, 0.4, 6)
	b.add_box("brass", Vector3(-38.0, 1.2, 3.8), Vector3(0.05, 0.03, 0.6))
	b.add_tube("brass", Vector3(-38.0, 1.0, 3.5), 0.14, 0.16, 0.03, 10, false, true)
	b.add_tube("brass", Vector3(-38.0, 1.0, 4.1), 0.14, 0.16, 0.03, 10, false, true)
	col_box(Vector3(-38.0, 0.45, 3.0), Vector3(1.0, 0.9, 2.8))
	interact("hazine_masa", id, Vector3(-36.6, 0, 3.0), "Hazine Defterini İncele", "treasury")
	spot(id, Vector3(-39.0, 0, 3.0), "work", face_yaw(Vector3(1, 0, 0)), "hazine")
	spot(id, Vector3(-39.0, 0, 5.4), "work", face_yaw(Vector3(1, 0, 0)), "katip")
	_carpet("carpet_red", Vector3(-45, 0, 3), 8, 10)
	_guard_post(id, Vector3(-31.6, 0, 5.8), Vector3(-1, 0, 0))
	spot(id, Vector3(-46.0, 0, -2.0), "stand", 0.0)
	spot(id, Vector3(-44.0, 0, 9.0), "stand", PI)


func _furnish_elci(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "elci"
	b.add_box("marble_warm", Vector3(-49, 0.12, 38.6), Vector3(7, 0.24, 4.0), 0.0, 2.0)
	col_box(Vector3(-49, 0.12, 38.6), Vector3(7, 0.24, 4.0))
	b.add_box("gold", Vector3(-49, 0.55, 39.5), Vector3(2.0, 0.6, 1.4), 0.0, 0.8)
	b.add_box("brocade_red", Vector3(-49, 0.9, 39.4), Vector3(1.8, 0.14, 1.2))
	b.add_box("gold", Vector3(-49, 1.4, 40.2), Vector3(2.0, 1.4, 0.15), 0.0, 0.8)
	col_box(Vector3(-49, 0.8, 39.6), Vector3(2.1, 1.6, 1.5))
	interact("elci_kursu", id, Vector3(-49, 0, 37.2), "Elçi Kürsüsüne Otur", "sit_here", {"seat": Vector3(-49, 0.85, 39.3), "yaw": 0.0})
	_carpet("carpet_red", Vector3(-49, 0, 28.5), 4.0, 15)
	_carpet("carpet_blue", Vector3(-55.5, 0, 30), 4, 14)
	_carpet("carpet_blue", Vector3(-42.5, 0, 30), 4, 14)
	var flags := ["banner_blue", "banner_purple", "banner_green", "banner_red"]
	for i in range(4):
		var z := 23.5 + i * 4.5
		_banner(Vector3(-59.6, 4.2, z), PI * 0.5, flags[i], 1.3, 3.2)
	_sedir(id, Vector3(-38.35, 0, 22.0), Vector3(-38.35, 0, 27.5), Vector3(-1, 0, 0), "brocade_blue", 1.0, 1.6)
	_sedir(id, Vector3(-38.35, 0, 32.5), Vector3(-38.35, 0, 38.0), Vector3(-1, 0, 0), "brocade_blue", 1.0, 1.6)
	for p in [Vector3(-54.0, 0, 34.5), Vector3(-44.0, 0, 34.5)]:
		b.add_box("wood_dark", p + Vector3(0, 0.4, 0), Vector3(1.8, 0.8, 0.9), 0.0, 1.5)
		_chest(p + Vector3(0, 0.8, 0), 0.0, Vector3(0.7, 0.35, 0.45), true)
		col_box(p + Vector3(0, 0.6, 0), Vector3(1.8, 1.2, 0.9))
	spot(id, Vector3(-49.0, 0, 30.0), "stand", PI, "elci")
	spot(id, Vector3(-52.0, 0, 26.0), "stand", PI * 0.5)
	spot(id, Vector3(-46.0, 0, 26.0), "stand", -PI * 0.5)
	_guard_post(id, Vector3(-51.5, 0, 19.7), Vector3(0, 0, 1))


func _furnish_halk(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "halk"
	b.add_box("wood", Vector3(-27, 0.15, 38.8), Vector3(6, 0.3, 3.6), 0.0, 1.5)
	col_box(Vector3(-27, 0.15, 38.8), Vector3(6, 0.3, 3.6))
	b.add_box("wood_dark", Vector3(-27, 0.6, 39.8), Vector3(1.8, 0.6, 1.2), 0.0, 1.5)
	b.add_box("brocade_green", Vector3(-27, 0.95, 39.7), Vector3(1.6, 0.12, 1.0))
	b.add_box("wood_dark", Vector3(-27, 1.5, 40.4), Vector3(1.8, 1.2, 0.12), 0.0, 1.5)
	col_box(Vector3(-27, 0.9, 39.9), Vector3(1.9, 1.5, 1.3))
	interact("arz_kursu", id, Vector3(-27, 0, 37.2), "Dilekçeleri Dinle", "petitions", {"seat": Vector3(-27, 1.0, 39.6), "yaw": 0.0})
	# parmaklık
	b.add_box("wood_dark", Vector3(-32.5, 0.55, 33.0), Vector3(8.5, 1.1, 0.14), 0.0, 1.5)
	b.add_box("wood_dark", Vector3(-21.5, 0.55, 33.0), Vector3(8.5, 1.1, 0.14), 0.0, 1.5)
	col_box(Vector3(-32.5, 0.55, 33.0), Vector3(8.5, 1.1, 0.2))
	col_box(Vector3(-21.5, 0.55, 33.0), Vector3(8.5, 1.1, 0.2))
	# bekleme sıraları
	for z in [24.0, 27.5]:
		for x in [-33.0, -21.0]:
			b.add_box("wood", Vector3(x, 0.25, z), Vector3(5.0, 0.5, 0.7), 0.0, 1.5)
			col_box(Vector3(x, 0.35, z), Vector3(5.0, 0.7, 0.7))
			for k in range(3):
				spot(id, Vector3(x - 1.6 + k * 1.6, 0, z + 0.65), "sit", PI, "dilekci")
	# kâtip masası
	_rahle(Vector3(-23.0, 0.3, 37.8), 0.0)
	spot(id, Vector3(-23.0, 0.3, 38.4), "sit_low", PI, "katip")
	_carpet("carpet_green", Vector3(-27, 0, 35.5), 6, 3)
	_vase(Vector3(-37.0, 0, 40.2))
	_vase(Vector3(-17.0, 0, 40.2))
	_guard_post(id, Vector3(-29.6, 0, 33.6), Vector3(0, 0, -1))
	spot(id, Vector3(-27.0, 0, 30.0), "stand", 0.0, "dilekci")


func _furnish_muhafiz(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "muhafiz"
	for z in [24.0, 28.0, 32.0]:
		b.add_box("wood_dark", Vector3(-14.6, 0.35, z), Vector3(2.2, 0.7, 1.1), 0.0, 1.5)
		b.add_box("fabric_cream", Vector3(-14.6, 0.75, z), Vector3(2.0, 0.12, 0.95))
		b.add_box("wood_dark", Vector3(-14.6, 1.75, z), Vector3(2.2, 0.12, 1.1), 0.0, 1.5)
		b.add_box("fabric_cream", Vector3(-14.6, 1.86, z), Vector3(2.0, 0.1, 0.95))
		for zz in [z - 0.5, z + 0.5]:
			b.add_box("wood_dark", Vector3(-13.55, 1.0, zz), Vector3(0.1, 2.0, 0.1))
		col_box(Vector3(-14.6, 1.0, z), Vector3(2.2, 2.0, 1.1))
	# silah rafı
	b.add_box("wood_dark", Vector3(-4.6, 1.2, 36.0), Vector3(0.3, 2.2, 3.0), 0.0, 1.5)
	for k in range(6):
		var zz2 := 34.8 + k * 0.48
		b.add_tube("wood", Vector3(-4.9, 0.1, zz2), 0.03, 0.03, 2.4, 4)
		b.add_tube("steel", Vector3(-4.9, 2.5, zz2), 0.05, 0.0, 0.3, 4)
	col_box(Vector3(-4.7, 1.2, 36.0), Vector3(0.5, 2.4, 3.0))
	for z in [24.0, 27.0]:
		_wall_disc("steel", Vector3(-4.38, 2.2, z), Vector3(-1, 0, 0), 0.42, 0.05)
		b.add_sphere("brass", Vector3(-4.42, 2.2, z), Vector3(0.08, 0.08, 0.08), 6, 4)
	# talim mankeni
	b.add_tube("wood_dark", Vector3(-9.0, 0, 37.5), 0.08, 0.08, 1.7, 6)
	b.add_box("wood", Vector3(-9.0, 1.45, 37.5), Vector3(1.0, 0.1, 0.1))
	b.add_sphere("food", Vector3(-9.0, 1.85, 37.5), Vector3(0.18, 0.2, 0.18), 8, 5)
	b.add_tube("food", Vector3(-9.0, 1.0, 37.5), 0.28, 0.22, 0.6, 8)
	col_cyl(Vector3(-9.0, 0, 37.5), 0.35, 2.0)
	b.add_box("wood", Vector3(-9.0, 0.4, 28.0), Vector3(1.4, 0.8, 2.6), 0.0, 1.5)
	b.add_sphere("food", Vector3(-9.0, 0.88, 27.5), Vector3(0.2, 0.08, 0.14), 6, 4)
	b.add_tube("brass", Vector3(-8.8, 0.8, 28.6), 0.08, 0.07, 0.2, 6, false, true)
	col_box(Vector3(-9.0, 0.45, 28.0), Vector3(1.4, 0.9, 2.6))
	spot(id, Vector3(-10.0, 0, 28.0), "sit_low", -PI * 0.5)
	spot(id, Vector3(-8.0, 0, 28.0), "sit_low", PI * 0.5)
	spot(id, Vector3(-9.0, 0, 36.2), "work", PI, "talim")
	spot(id, Vector3(-12.5, 0, 24.0), "sleep", 0.0)
	_guard_post(id, Vector3(-12.0, 0, 19.7), Vector3(0, 0, -1))


func _furnish_mutfak(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "mutfak"
	# ocaklar (güney duvarı)
	for x in [8.0, 14.0, 20.0]:
		b.add_box("stone_ext", Vector3(x, 0.6, 39.9), Vector3(4.0, 1.2, 1.6), 0.0, 3.0)
		b.add_box("black", Vector3(x, 0.55, 39.08), Vector3(2.4, 0.7, 0.05))
		b.add_sphere("fire", Vector3(x, 0.45, 39.3), Vector3(0.9, 0.2, 0.35), 8, 4)
		b.add_tube("brass", Vector3(x - 0.9, 1.2, 39.8), 0.55, 0.62, 0.7, 12, false, false, true)
		b.add_tube("brass", Vector3(x + 0.9, 1.2, 39.8), 0.45, 0.5, 0.55, 12, false, false, true)
		b.add_tube("plaster", Vector3(x, 1.2, 40.1), 1.9, 0.5, 3.5, 4, false, false, false, 1.0, 1.0, PI * 0.25)
		col_box(Vector3(x, 1.2, 39.9), Vector3(4.0, 2.4, 1.6))
		omni(Vector3(x, 1.3, 38.6), 6.0, 0.9, Color(1.0, 0.55, 0.25))
		# baca
		b.add_tube("stone_ext", Vector3(x, 7.35, 39.6), 0.55, 0.5, 4.0, 8)
		b.add_tube("lead", Vector3(x, 11.35, 39.6), 0.75, 0.05, 1.1, 8, false, false, true)
	# çalışma tezgâhları
	for x in [10.0, 18.0]:
		b.add_box("wood", Vector3(x, 0.45, 33.5), Vector3(4.0, 0.9, 1.2), 0.0, 1.5)
		b.add_sphere("food", Vector3(x - 0.8, 0.98, 33.5), Vector3(0.25, 0.1, 0.2), 6, 4)
		b.add_tube("brass", Vector3(x + 0.9, 0.9, 33.4), 0.2, 0.18, 0.25, 8, false, false, true)
		col_box(Vector3(x, 0.45, 33.5), Vector3(4.0, 0.9, 1.2))
		spot(id, Vector3(x, 0, 32.6), "work", PI, "asci")
		spot(id, Vector3(x, 0, 34.4), "work", 0.0, "asci")
	# raflar ve küpler
	_shelf(Vector3(4.65, 0, 25.0), PI * 0.5, 2.6, 2.4)
	for z in [29.0, 30.0, 31.0]:
		b.add_sphere("red_clay", Vector3(5.0, 0.55, z + 4.0), Vector3(0.35, 0.55, 0.35), 8, 6)
	col_box(Vector3(5.0, 0.6, 34.0), Vector3(0.8, 1.2, 3.2))
	# yemek salonu
	_carpet("carpet_red", Vector3(24.0, 0, 26.0), 9, 9)
	_sini(id, Vector3(21.5, 0, 24.0), 0.7, "brocade_red", 5)
	_sini(id, Vector3(26.5, 0, 28.0), 0.7, "brocade_green", 5)
	_sedir(id, Vector3(29.65, 0, 20.5), Vector3(29.65, 0, 31.5), Vector3(-1, 0, 0), "brocade_red", 1.0, 1.5)
	interact("mutfak_tezgah", id, Vector3(14.0, 0, 32.2), "Bir Şeyler Atıştır", "snack", {"minutes": 20})
	sound_points.append({"type": "kitchen", "pos": Vector3(14, 1.0, 37)})
	spot(id, Vector3(8.0, 0, 37.5), "work", 0.0, "asci")
	spot(id, Vector3(20.0, 0, 37.5), "work", 0.0, "asci")
	spot(id, Vector3(12.0, 0, 22.0), "sleep", 0.0)
	# mutfak kubbecikleri
	for x in [10.0, 20.0]:
		var base := Vector3(x, 7.35, 27.0)
		b.add_tube("plaster_ext", base, 2.2, 2.2, 0.5, 8)
		b.add_dome("lead", base + Vector3(0, 0.5, 0), 2.3, 1.9, 14, 6)
		_finial(base + Vector3(0, 2.35, 0), 0.6)


func _furnish_avlu(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "avlu"
	var fc := Vector3(0, 0, -7)
	# şadırvan
	_basin(fc, 3.4, 0.7, 8)
	b.add_tube("marble", fc + Vector3(0, 0.0, 0), 1.0, 1.0, 1.9, 8, false, true, false, 4.0, 1.0)
	b.add_tube("gold_plain", fc + Vector3(0, 1.9, 0), 1.1, 1.1, 0.12, 8, false, true)
	for k in range(8):
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var tap := fc + Vector3(cos(a), 0, sin(a)) * 1.02 + Vector3(0, 1.1, 0)
		b.add_sphere("brass", tap, Vector3(0.06, 0.06, 0.06), 6, 4)
		var cp := fc + Vector3(cos(a), 0, sin(a)) * 2.75
		b.add_tube("marble", cp + Vector3(0, 0.7, 0), 0.12, 0.1, 2.6, 8)
	b.add_tube("lead", fc + Vector3(0, 3.3, 0), 4.6, 1.0, 1.4, 8, false, false, true, 1.0, 1.0, PI / 8.0)
	b.add_tube("wood_dark", fc + Vector3(0, 3.18, 0), 4.6, 4.6, 0.14, 8, false, false, true, 1.0, 1.0, PI / 8.0)
	b.add_tube("plaster_ext", fc + Vector3(0, 4.7, 0), 1.0, 1.0, 0.5, 8)
	b.add_dome("lead", fc + Vector3(0, 5.2, 0), 1.1, 1.0, 12, 5)
	_finial(fc + Vector3(0, 6.15, 0), 0.7)
	sound_points.append({"type": "fountain", "pos": fc + Vector3(0, 1.0, 0)})
	# çim parterler
	var beds := [[-14.0, -19.0], [14.0, -19.0], [-14.0, 5.0], [14.0, 5.0]]
	for bd in beds:
		var c := Vector3(bd[0], 0, bd[1])
		b.add_box("grass", c + Vector3(0, 0.06, 0), Vector3(12.0, 0.12, 9.0), 0.0, 3.0)
		b.add_box("marble_warm", c + Vector3(0, 0.12, -4.6), Vector3(12.4, 0.24, 0.25), 0.0, 2.0)
		b.add_box("marble_warm", c + Vector3(0, 0.12, 4.6), Vector3(12.4, 0.24, 0.25), 0.0, 2.0)
		b.add_box("marble_warm", c + Vector3(-6.1, 0.12, 0), Vector3(0.25, 0.24, 9.0), 0.0, 2.0)
		b.add_box("marble_warm", c + Vector3(6.1, 0.12, 0), Vector3(0.25, 0.24, 9.0), 0.0, 2.0)
		col_box(c + Vector3(0, 0.35, 0), Vector3(12.4, 0.7, 9.4))
		_cypress(c + Vector3(-4.2, 0.12, -2.5), 7.5)
		_cypress(c + Vector3(4.2, 0.12, 2.5), 6.8)
		_flowerbed(c + Vector3(2.0, 0.12, -2.4), 3.0, 1.2)
		_flowerbed(c + Vector3(-2.0, 0.12, 2.4), 3.0, 1.2)
	_round_tree(Vector3(-17.0, 0.12, 6.5), 1.3)
	_round_tree(Vector3(17.0, 0.12, -20.5), 1.25)
	# banklar
	for p in [Vector3(-6.5, 0, -14.0), Vector3(6.5, 0, -14.0), Vector3(-6.5, 0, 0.0), Vector3(6.5, 0, 0.0)]:
		b.add_box("marble_warm", p + Vector3(0, 0.25, 0), Vector3(0.7, 0.5, 2.6), 0.0, 2.0)
		b.add_box("marble", p + Vector3(0, 0.52, 0), Vector3(0.8, 0.06, 2.7), 0.0, 2.0)
		col_box(p + Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 2.7))
		var face := Vector3(-signf(p.x), 0, 0)
		spot(id, p + face * 0.75 + Vector3(0, 0, -0.6), "sit", face_yaw(face))
		spot(id, p + face * 0.75 + Vector3(0, 0, 0.6), "sit", face_yaw(face))
	for p2 in [Vector3(-8, 0, -24), Vector3(8, 0, -24), Vector3(-8, 0, 10), Vector3(8, 0, 10)]:
		_lantern_post(p2)
	for p3 in [Vector3(0, 0, 2), Vector3(-4, 0, -12), Vector3(4, 0, -2), Vector3(-10, 0, -7), Vector3(10, 0, -7), Vector3(0, 0, -16), Vector3(-3, 0, 9), Vector3(3, 0, 11), Vector3(-20, 0, -7), Vector3(20, 0, -7)]:
		spot(id, p3, "stand", randf() * TAU)
	interact("sadirvan", id, Vector3(0, 0, -2.9), "Şadırvanda Dinlen", "rest", {"minutes": 20})
	_guard_post(id, Vector3(-2.6, 0, -26.5), Vector3(0, 0, 1))


func _furnish_harem_bahce(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "harem_bahce"
	b.add_box("path", Vector3(45, 0.02, 30), Vector3(3.0, 0.04, 22), 0.0, 2.0)
	b.add_box("path", Vector3(45, 0.025, 25), Vector3(30, 0.04, 2.4), 0.0, 2.0)
	# havuz
	var pc := Vector3(39.0, 0, 33.0)
	b.add_box("marble_warm", pc + Vector3(0, 0.3, -2.1), Vector3(8.4, 0.6, 0.4), 0.0, 2.0)
	b.add_box("marble_warm", pc + Vector3(0, 0.3, 2.1), Vector3(8.4, 0.6, 0.4), 0.0, 2.0)
	b.add_box("marble_warm", pc + Vector3(-4.0, 0.3, 0), Vector3(0.4, 0.6, 3.8), 0.0, 2.0)
	b.add_box("marble_warm", pc + Vector3(4.0, 0.3, 0), Vector3(0.4, 0.6, 3.8), 0.0, 2.0)
	b.add_box("water", pc + Vector3(0, 0.42, 0), Vector3(7.6, 0.04, 3.8), 0.0, 2.0)
	for k in range(3):
		b.add_tube("marble", pc + Vector3(-2.5 + k * 2.5, 0.3, 0), 0.12, 0.08, 0.5, 8)
	col_box(pc + Vector3(0, 0.5, 0), Vector3(8.4, 1.0, 4.6))
	sound_points.append({"type": "fountain", "pos": pc + Vector3(0, 0.6, 0)})
	# köşk
	var kc := Vector3(53.5, 0, 33.5)
	b.add_box("marble_warm", kc + Vector3(0, 0.15, 0), Vector3(6.5, 0.3, 6.5), 0.0, 2.0)
	for p in [Vector3(-2.8, 0, -2.8), Vector3(2.8, 0, -2.8), Vector3(-2.8, 0, 2.8), Vector3(2.8, 0, 2.8)]:
		_column(kc + p + Vector3(0, 0.3, 0), 3.0, 0.16)
	b.add_box("wood_dark", kc + Vector3(0, 3.4, 0), Vector3(8.0, 0.2, 8.0), 0.0, 2.0)
	b.add_tube("lead", kc + Vector3(0, 3.5, 0), 5.6, 2.0, 0.9, 4, false, false, false, 1.0, 1.0, PI * 0.25)
	b.add_tube("plaster_ext", kc + Vector3(0, 4.4, 0), 2.0, 2.0, 0.5, 8)
	b.add_dome("lead", kc + Vector3(0, 4.9, 0), 2.1, 1.8, 14, 6)
	_finial(kc + Vector3(0, 6.65, 0), 0.6)
	_sedir(id, kc + Vector3(-2.4, 0.3, 2.4), kc + Vector3(2.4, 0.3, 2.4), Vector3(0, 0, -1), "brocade_red", 0.9, 1.5, "kosk")
	_carpet("carpet_red", kc + Vector3(0, 0.3, 0), 4.0, 3.0)
	b.add_box("carpet_red", kc + Vector3(0, 0.315, -0.3), Vector3(4.0, 0.03, 3.0), 0.0, 0.0)
	col_box(kc + Vector3(0, 0.15, 0), Vector3(6.5, 0.3, 6.5))
	for p2 in [Vector3(33, 0, 22), Vector3(58, 0, 22), Vector3(33, 0, 39), Vector3(48, 0, 39)]:
		_cypress(p2, 6.5)
	_round_tree(Vector3(36.0, 0, 24.5), 1.0, "leaf_light")
	_round_tree(Vector3(56.0, 0, 26.0), 0.9, "leaf_light")
	_flowerbed(Vector3(40, 0, 22.5), 6.0, 1.4)
	_flowerbed(Vector3(50, 0, 22.5), 6.0, 1.4)
	_flowerbed(Vector3(51.0, 0, 39.0), 4.0, 1.4)
	for p3 in [Vector3(42, 0, 28), Vector3(48, 0, 30), Vector3(36, 0, 37), Vector3(45, 0, 36)]:
		spot(id, p3, "stand", randf() * TAU)
	interact("harem_kosku", id, kc + Vector3(0, 0.3, 0.6), "Köşkte Dinlen", "rest", {"minutes": 30})
	_lantern_post(Vector3(43, 0, 27))


func _furnish_bahce(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	var id := "bahce"
	b.add_box("path", Vector3(0, 0.02, 60.5), Vector3(4.0, 0.04, 39), 0.0, 2.0)
	b.add_box("path", Vector3(0, 0.025, 50.0), Vector3(118, 0.04, 3.0), 0.0, 2.0)
	b.add_box("path", Vector3(45, 0.022, 45.0), Vector3(3.0, 0.04, 8.0), 0.0, 2.0)
	# büyük havuz
	var pc := Vector3(0, 0, 61.0)
	for e in [[Vector3(0, 0.3, -5.2), Vector3(22.4, 0.6, 0.4)], [Vector3(0, 0.3, 5.2), Vector3(22.4, 0.6, 0.4)], [Vector3(-11.0, 0.3, 0), Vector3(0.4, 0.6, 10.0)], [Vector3(11.0, 0.3, 0), Vector3(0.4, 0.6, 10.0)]]:
		b.add_box("marble_warm", pc + (e[0] as Vector3), e[1] as Vector3, 0.0, 2.0)
	b.add_box("water", pc + Vector3(0, 0.42, 0), Vector3(21.6, 0.04, 10.0), 0.0, 2.0)
	for k in range(5):
		b.add_tube("marble", pc + Vector3(-8.0 + k * 4.0, 0.3, 0), 0.15, 0.1, 0.55, 8)
	col_box(pc + Vector3(0, 0.5, 0), Vector3(22.4, 1.0, 10.8))
	sound_points.append({"type": "fountain", "pos": pc + Vector3(0, 0.6, 0)})
	# deniz köşkü
	var kc := Vector3(0, 0, 73.0)
	b.add_box("marble_warm", kc + Vector3(0, 0.2, 0), Vector3(10, 0.4, 9.0), 0.0, 2.0)
	col_box(kc + Vector3(0, 0.2, 0), Vector3(10, 0.4, 9.0))
	for k in range(8):
		var a := TAU * float(k) / 8.0 + PI / 8.0
		_column(kc + Vector3(cos(a), 0, sin(a)) * 3.8 + Vector3(0, 0.4, 0), 3.3, 0.17)
	b.add_tube("wood_dark", kc + Vector3(0, 3.7, 0), 6.2, 6.2, 0.2, 8, false, false, true, 1.0, 1.0, PI / 8.0)
	b.add_tube("lead", kc + Vector3(0, 3.9, 0), 6.2, 3.2, 0.8, 8, false, false, false, 1.0, 1.0, PI / 8.0)
	b.add_tube("plaster_ext", kc + Vector3(0, 4.7, 0), 3.2, 3.2, 0.7, 8)
	b.add_dome("lead", kc + Vector3(0, 5.4, 0), 3.3, 2.9, 16, 7)
	b.add_dome("dome_in", kc + Vector3(0, 3.7, 0), 3.4, 1.0, 16, 5, true)
	_finial(kc + Vector3(0, 8.25, 0), 0.8)
	_sedir(id, kc + Vector3(-3.2, 0.4, 3.0), kc + Vector3(3.2, 0.4, 3.0), Vector3(0, 0, -1), "brocade_green", 0.9, 1.6, "kosk")
	b.add_box("carpet_green", kc + Vector3(0, 0.415, -0.4), Vector3(5.0, 0.03, 4.0), 0.0, 0.0)
	interact("deniz_kosku", id, kc + Vector3(0, 0.4, 0.6), "Denizi Seyret", "rest", {"minutes": 45})
	# selvi dizileri
	for z in [44.5, 53.5]:
		_cypress(Vector3(-3.5, 0, z), 7.0)
		_cypress(Vector3(3.5, 0, z), 7.0)
	for x in [-44.0, -36.0, -28.0, 28.0, 36.0, 52.0]:
		_cypress(Vector3(x, 0, 52.6), 6.5)
	# meyve bahçesi (batı)
	for x in [-55.0, -48.0, -41.0, -34.0]:
		for z in [56.0, 64.0, 72.0]:
			_round_tree(Vector3(x + (int(z) % 3), 0, z), 0.85, "leaf_light" if int(x) % 2 == 0 else "leaf")
	_round_tree(Vector3(-22.0, 0, 46.5), 1.5)
	_round_tree(Vector3(24.0, 0, 46.5), 1.4)
	# lale tarhları (doğu)
	for x in [18.0, 26.0, 34.0, 42.0, 50.0]:
		for z in [56.0, 63.0, 70.0]:
			_flowerbed(Vector3(x, 0, z), 5.0, 2.4)
	_flowerbed(Vector3(-16, 0, 56), 6.0, 2.0)
	_flowerbed(Vector3(-16, 0, 66), 6.0, 2.0)
	# bahçıvan kulübesi
	var hc := Vector3(-52.0, 0, 46.5)
	b.add_box("wood", hc + Vector3(0, 1.4, 0), Vector3(5.0, 2.8, 4.0), 0.0, 1.5)
	b.add_tube("red_clay", hc + Vector3(0, 2.8, 0), 4.0, 0.2, 1.6, 4, false, false, true, 1.0, 1.0, PI * 0.25)
	b.add_box("wood_dark", hc + Vector3(0, 1.0, 2.02), Vector3(1.1, 2.0, 0.06))
	col_box(hc + Vector3(0, 1.4, 0), Vector3(5.0, 2.8, 4.0))
	spot(id, hc + Vector3(1.5, 0, 3.0), "work", 0.0, "bahcivan")
	spot(id, hc + Vector3(0, 0, 2.6), "sleep", 0.0)
	for p in [Vector3(-12, 0, 47.5), Vector3(12, 0, 47.5), Vector3(-7, 0, 69.0), Vector3(7, 0, 69.0)]:
		_lantern_post(p)
	for p2 in [Vector3(-30, 0, 52), Vector3(30, 0, 52), Vector3(-15, 0, 74), Vector3(15, 0, 74), Vector3(-8, 0, 53), Vector3(8, 0, 53), Vector3(-25, 0, 66), Vector3(30, 0, 77), Vector3(40, 0, 52)]:
		spot(id, p2, "stand", randf() * TAU)
	for p3 in [Vector3(20, 0, 59.5), Vector3(38, 0, 66.5), Vector3(-37, 0, 60)]:
		spot(id, p3, "work", 0.0, "bahcivan")
	# taş banklar
	for p4 in [Vector3(-8, 0, 47.2), Vector3(8, 0, 47.2)]:
		b.add_box("marble_warm", p4 + Vector3(0, 0.25, 0), Vector3(2.6, 0.5, 0.7), 0.0, 2.0)
		col_box(p4 + Vector3(0, 0.4, 0), Vector3(2.6, 0.8, 0.7))
		spot(id, p4 + Vector3(0, 0, 0.75), "sit", PI)


func _furnish_gecit(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	_vase(Vector3(-3.0, 0, 24.0), "iznik_blue")
	_vase(Vector3(3.0, 0, 36.0), "iznik_green")
	spot("gecit", Vector3(0, 0, 30), "stand", 0.0)


func _furnish_koridor_k(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	for x in [-56.0, -36.0, 36.0, 56.0]:
		_vase(Vector3(x, 0, -32.4), "iznik_blue")
	_guard_post("koridor_k", Vector3(-2.8, 0, -32.2), Vector3(0, 0, 1))
	_guard_post("koridor_k", Vector3(36.0, 0, -29.0), Vector3(-1, 0, 0))
	spot("koridor_k", Vector3(-10, 0, -30.5), "stand", 0.0)
	spot("koridor_k", Vector3(14, 0, -30.5), "stand", 0.0)


func _furnish_koridor_g(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	for x in [-56.0, -40.0, 40.0, 56.0]:
		_vase(Vector3(x, 0, 14.6), "iznik")
	spot("koridor_g", Vector3(-10, 0, 16.5), "stand", 0.0)
	spot("koridor_g", Vector3(10, 0, 16.5), "stand", 0.0)


func _furnish_koridor_d(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	_guard_post("koridor_d", Vector3(29.0, 0, -15.0), Vector3(-1, 0, 0))
	spot("koridor_d", Vector3(27, 0, 0), "stand", 0.0)


func _furnish_koridor_b(room: Dictionary, x0: float, z0: float, x1: float, z1: float) -> void:
	spot("koridor_b", Vector3(-27, 0, 0), "stand", 0.0)
	spot("koridor_b", Vector3(-27, 0, -15), "stand", 0.0)


# ---------------------------------------------------------------- dış dünya

func _build_exterior() -> void:
	b = MeshBatch.new()
	# kara kütlesi ve yalı yarı
	b.add_box("stone_ext", Vector3(0, -6.25, -260.0), Vector3(1200, 12.0, 688.0), 0.0, 6.0, 1 | 2 | 16 | 32)
	b.add_box("ground_far", Vector3(0, -0.27, -260.0), Vector3(1200, 0.04, 688.0), 0.0, 12.0, 4)
	# deniz
	b.add_box("sea", Vector3(0, -11.0, 1300.0), Vector3(4000, 0.1, 2400.0), 0.0, 0.0, 4)
	# karşı kıyı tepeleri
	var hills := [[-600.0, 1100.0, 260.0, 90.0], [-250.0, 1250.0, 330.0, 130.0], [150.0, 1150.0, 300.0, 100.0], [500.0, 1300.0, 380.0, 150.0], [850.0, 1050.0, 250.0, 80.0], [-900.0, 1000.0, 300.0, 110.0]]
	for hl in hills:
		b.add_tube("leaf", Vector3(hl[0], -12.0, hl[1]), hl[2], hl[2] * 0.25, hl[3], 12, false, true)
	# karşı kıyı şehri: kubbeler ve minareler
	for i in range(14):
		var x := -420.0 + i * 62.0
		var z := 900.0 + float((i * 37) % 90)
		b.add_box("plaster_ext", Vector3(x, -4.0, z), Vector3(30.0, 16.0, 22.0), 0.0, 8.0)
		b.add_dome("lead", Vector3(x, 4.0, z), 9.0 + float(i % 3) * 3.0, 8.0 + float(i % 3) * 2.0, 12, 5)
		if i % 2 == 0:
			b.add_tube("plaster_ext", Vector3(x + 18.0, -12.0, z), 2.2, 1.8, 46.0, 8)
			b.add_tube("lead", Vector3(x + 18.0, 34.0, z), 2.4, 0.05, 10.0, 8)
	# sarayın dış cephe kaidesi
	b.add_box("stone_ext", Vector3(0, -0.6, 82.0), Vector3(124, 1.0, 4.0), 0.0, 3.0, 1 | 2 | 16)
	_finish_batch("Disari", false)
