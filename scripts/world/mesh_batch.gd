class_name MeshBatch
extends RefCounted
## Statik saray geometrisini malzeme bazında tek mesh'lerde toplar.
## Böylece her oda için az sayıda draw call oluşur.

var _verts := {}   # mat -> PackedVector3Array
var _norms := {}   # mat -> PackedVector3Array
var _uvs := {}     # mat -> PackedVector2Array
var _cols := {}    # mat -> PackedColorArray


func _ensure(mat: String) -> void:
	if not _verts.has(mat):
		_verts[mat] = PackedVector3Array()
		_norms[mat] = PackedVector3Array()
		_uvs[mat] = PackedVector2Array()
		_cols[mat] = PackedColorArray()


func is_empty() -> bool:
	return _verts.is_empty()


func triangle_count() -> int:
	var n := 0
	for m in _verts.keys():
		n += (_verts[m] as PackedVector3Array).size() / 3
	return n


## Saat yönü önyüz sarımını (Godot) normal yönüne göre otomatik ayarlar.
func add_tri(mat_key: String, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var rs: Array = Mats.resolve(mat_key)
	var mat: String = rs[0]
	var col: Color = rs[1]
	_ensure(mat)
	var face := (b - a).cross(c - a)
	var navg := na + nb + nc
	var v: PackedVector3Array = _verts[mat]
	var n: PackedVector3Array = _norms[mat]
	var u: PackedVector2Array = _uvs[mat]
	var cl: PackedColorArray = _cols[mat]
	cl.append(col); cl.append(col); cl.append(col)
	_cols[mat] = cl
	if face.dot(navg) > 0.0:
		# saat yönünün tersi -> çevir
		v.append(a); v.append(c); v.append(b)
		n.append(na); n.append(nc); n.append(nb)
		u.append(ua); u.append(uc); u.append(ub)
	else:
		v.append(a); v.append(b); v.append(c)
		n.append(na); n.append(nb); n.append(nc)
		u.append(ua); u.append(ub); u.append(uc)
	_verts[mat] = v
	_norms[mat] = n
	_uvs[mat] = u


func add_quad(mat: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	add_tri(mat, a, b, c, n, n, n, ua, ub, uc)
	add_tri(mat, a, c, d, n, n, n, ua, uc, ud)


## Dünya ölçekli UV ile kutu. tile <= 0 ise üst yüzey 0..1 gerilir (halı vb.)
func add_box(mat: String, center: Vector3, size: Vector3, rot_y: float = 0.0, tile: float = 2.0, faces: int = 63) -> void:
	var basis := Basis(Vector3.UP, rot_y)
	var h := size * 0.5
	var stretch := tile <= 0.0
	var t := 1.0 if stretch else 1.0 / tile
	# yüz tanımları: normal, eksen u, eksen v
	var defs := [
		[Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0), 1],
		[Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0), 2],
		[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), 4],
		[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), 8],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0), 16],
		[Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 1, 0), 32],
	]
	for dd in defs:
		if (faces & int(dd[3])) == 0:
			continue
		var nl: Vector3 = dd[0]
		var ax_u: Vector3 = dd[1]
		var ax_v: Vector3 = dd[2]
		var fc := nl * h
		var eu := ax_u * h
		var ev := ax_v * h
		var corners := [fc - eu - ev, fc + eu - ev, fc + eu + ev, fc - eu + ev]
		var uvs: Array = []
		for k in range(4):
			var p: Vector3 = corners[k]
			if stretch and nl.y > 0.5:
				uvs.append(Vector2((p.x / size.x) + 0.5, (p.z / size.z) + 0.5))
			elif stretch:
				uvs.append(Vector2(0.02, 0.02))
			else:
				var wp: Vector3 = p + (center if rot_y == 0.0 else Vector3.ZERO)
				uvs.append(Vector2(wp.dot(ax_u) * t, -wp.dot(ax_v) * t))
		var wn := basis * nl
		var wc: Array = []
		for k in range(4):
			wc.append(center + basis * (corners[k] as Vector3))
		add_quad(mat, wc[0], wc[1], wc[2], wc[3], wn, uvs[0], uvs[1], uvs[2], uvs[3])


## Silindir / koni gövdesi. inward=true ise iç yüzeyler görünür.
func add_tube(mat: String, base: Vector3, r_bottom: float, r_top: float, height: float, segs: int = 12, inward: bool = false, cap_top: bool = false, cap_bottom: bool = false, uv_u: float = 1.0, uv_v: float = 1.0, rot: float = 0.0) -> void:
	var slope := (r_bottom - r_top) / maxf(height, 0.001)
	for i in range(segs):
		var a0 := rot + TAU * float(i) / segs
		var a1 := rot + TAU * float(i + 1) / segs
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var p0 := base + d0 * r_bottom
		var p1 := base + d1 * r_bottom
		var p2 := base + d1 * r_top + Vector3(0, height, 0)
		var p3 := base + d0 * r_top + Vector3(0, height, 0)
		var n0 := (d0 + Vector3(0, slope, 0)).normalized()
		var n1 := (d1 + Vector3(0, slope, 0)).normalized()
		if inward:
			n0 = -n0
			n1 = -n1
		var u0 := float(i) / segs * uv_u
		var u1 := float(i + 1) / segs * uv_u
		add_tri(mat, p0, p1, p2, n0, n1, n1, Vector2(u0, uv_v), Vector2(u1, uv_v), Vector2(u1, 0))
		add_tri(mat, p0, p2, p3, n0, n1, n0, Vector2(u0, uv_v), Vector2(u1, 0), Vector2(u0, 0))
		if cap_top and r_top > 0.001:
			var ct := base + Vector3(0, height, 0)
			add_tri(mat, ct, p3, p2, Vector3.UP, Vector3.UP, Vector3.UP, Vector2(0.5, 0.5), Vector2(0.5 + d0.x * 0.5, 0.5 + d0.z * 0.5), Vector2(0.5 + d1.x * 0.5, 0.5 + d1.z * 0.5))
		if cap_bottom and r_bottom > 0.001:
			add_tri(mat, base, p0, p1, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector2(0.5, 0.5), Vector2(0.5 + d0.x * 0.5, 0.5 + d0.z * 0.5), Vector2(0.5 + d1.x * 0.5, 0.5 + d1.z * 0.5))


## Yarım küre kubbe. profile > 1 hafif sivri (Osmanlı) kubbe verir.
func add_dome(mat: String, base: Vector3, radius: float, height: float, segs: int = 24, rings: int = 10, inward: bool = false, uv_u: float = 1.0, uv_v: float = 1.0) -> void:
	for j in range(rings):
		var t0 := float(j) / rings
		var t1 := float(j + 1) / rings
		var ph0 := t0 * PI * 0.5
		var ph1 := t1 * PI * 0.5
		# ph=0 ekvator, ph=PI/2 tepe
		var r0 := cos(ph0) * radius
		var r1 := cos(ph1) * radius
		var y0 := sin(ph0) * height
		var y1 := sin(ph1) * height
		for i in range(segs):
			var a0 := TAU * float(i) / segs
			var a1 := TAU * float(i + 1) / segs
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var p00 := base + d0 * r0 + Vector3(0, y0, 0)
			var p10 := base + d1 * r0 + Vector3(0, y0, 0)
			var p01 := base + d0 * r1 + Vector3(0, y1, 0)
			var p11 := base + d1 * r1 + Vector3(0, y1, 0)
			var hr := height / maxf(radius, 0.001)
			var n00 := Vector3(d0.x * cos(ph0) * hr, sin(ph0), d0.z * cos(ph0) * hr).normalized()
			var n10 := Vector3(d1.x * cos(ph0) * hr, sin(ph0), d1.z * cos(ph0) * hr).normalized()
			var n01 := Vector3(d0.x * cos(ph1) * hr, sin(ph1), d0.z * cos(ph1) * hr).normalized()
			var n11 := Vector3(d1.x * cos(ph1) * hr, sin(ph1), d1.z * cos(ph1) * hr).normalized()
			if inward:
				n00 = -n00; n10 = -n10; n01 = -n01; n11 = -n11
			var ua := float(i) / segs * uv_u
			var ub := float(i + 1) / segs * uv_u
			var va := (1.0 - t0) * uv_v
			var vb := (1.0 - t1) * uv_v
			add_tri(mat, p00, p10, p11, n00, n10, n11, Vector2(ua, va), Vector2(ub, va), Vector2(ub, vb))
			if j < rings - 1:
				add_tri(mat, p00, p11, p01, n00, n11, n01, Vector2(ua, va), Vector2(ub, vb), Vector2(ua, vb))


func add_sphere(mat: String, center: Vector3, radius: Vector3, segs: int = 12, rings: int = 8) -> void:
	for j in range(rings):
		var th0 := PI * float(j) / rings
		var th1 := PI * float(j + 1) / rings
		for i in range(segs):
			var a0 := TAU * float(i) / segs
			var a1 := TAU * float(i + 1) / segs
			var u00 := Vector3(sin(th0) * cos(a0), cos(th0), sin(th0) * sin(a0))
			var u10 := Vector3(sin(th0) * cos(a1), cos(th0), sin(th0) * sin(a1))
			var u01 := Vector3(sin(th1) * cos(a0), cos(th1), sin(th1) * sin(a0))
			var u11 := Vector3(sin(th1) * cos(a1), cos(th1), sin(th1) * sin(a1))
			var p00 := center + u00 * radius
			var p10 := center + u10 * radius
			var p01 := center + u01 * radius
			var p11 := center + u11 * radius
			var uv00 := Vector2(float(i) / segs, float(j) / rings)
			var uv10 := Vector2(float(i + 1) / segs, float(j) / rings)
			var uv01 := Vector2(float(i) / segs, float(j + 1) / rings)
			var uv11 := Vector2(float(i + 1) / segs, float(j + 1) / rings)
			if j > 0:
				add_tri(mat, p00, p10, p11, u00, u10, u11, uv00, uv10, uv11)
			if j < rings - 1:
				add_tri(mat, p00, p11, p01, u00, u11, u01, uv00, uv11, uv01)


## Düzlemsel bir çokgeni kalınlık vererek çıkarır.
## origin: çokgen düzleminin (0,0) noktası, right/up: düzlem eksenleri (birim), depth: normal yönünde kalınlık.
func add_extrude(mat: String, poly: PackedVector2Array, origin: Vector3, right: Vector3, up: Vector3, depth: float, tile: float = 1.0, side_mat: String = "") -> void:
	var nrm := right.cross(up).normalized()
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		return
	var back := origin + nrm * depth
	var t := 1.0 / maxf(tile, 0.001)
	for k in range(0, idx.size(), 3):
		var pa: Vector2 = poly[idx[k]]
		var pb: Vector2 = poly[idx[k + 1]]
		var pc: Vector2 = poly[idx[k + 2]]
		var a := origin + right * pa.x + up * pa.y
		var b := origin + right * pb.x + up * pb.y
		var c := origin + right * pc.x + up * pc.y
		add_tri(mat, a, b, c, -nrm, -nrm, -nrm, Vector2(pa.x, -pa.y) * t, Vector2(pb.x, -pb.y) * t, Vector2(pc.x, -pc.y) * t)
		add_tri(mat, a + nrm * depth, b + nrm * depth, c + nrm * depth, nrm, nrm, nrm, Vector2(-pa.x, -pa.y) * t, Vector2(-pb.x, -pb.y) * t, Vector2(-pc.x, -pc.y) * t)
	var sm := side_mat if side_mat != "" else mat
	var n := poly.size()
	# kenar yüzleri: çokgen yönelimine göre dışa bakan normal
	var area := 0.0
	for i in range(n):
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % n]
		area += p.x * q.y - q.x * p.y
	var ccw := area > 0.0
	var run := 0.0
	for i in range(n):
		var p2: Vector2 = poly[i]
		var q2: Vector2 = poly[(i + 1) % n]
		var e := q2 - p2
		var en := Vector2(e.y, -e.x) if ccw else Vector2(-e.y, e.x)
		en = en.normalized()
		var wn := (right * en.x + up * en.y).normalized()
		var a3 := origin + right * p2.x + up * p2.y
		var b3 := origin + right * q2.x + up * q2.y
		var len := e.length()
		add_quad(sm, a3, b3, b3 + nrm * depth, a3 + nrm * depth, wn, Vector2(run * t, 0), Vector2((run + len) * t, 0), Vector2((run + len) * t, depth * t), Vector2(run * t, depth * t))
		run += len


## Dikey düz panel (tek yüz ya da çift yüz)
func add_panel(mat: String, center: Vector3, width: float, height: float, rot_y: float, double_sided: bool = true, tile: float = 0.0) -> void:
	var basis := Basis(Vector3.UP, rot_y)
	var r := basis * Vector3(width * 0.5, 0, 0)
	var u := Vector3(0, height * 0.5, 0)
	var n := basis * Vector3(0, 0, 1)
	var a := center - r - u
	var b := center + r - u
	var c := center + r + u
	var d := center - r + u
	var uw := 1.0 if tile <= 0.0 else width / tile
	var vh := 1.0 if tile <= 0.0 else height / tile
	add_quad(mat, a, b, c, d, n, Vector2(0, vh), Vector2(uw, vh), Vector2(uw, 0), Vector2(0, 0))
	if double_sided:
		add_quad(mat, a, b, c, d, -n, Vector2(uw, vh), Vector2(0, vh), Vector2(0, 0), Vector2(uw, 0))


## Yatay disk
func add_disc(mat: String, center: Vector3, radius: float, segs: int = 24, up: bool = true, tile: float = 0.0) -> void:
	var n := Vector3.UP if up else Vector3.DOWN
	for i in range(segs):
		var a0 := TAU * float(i) / segs
		var a1 := TAU * float(i + 1) / segs
		var p0 := center + Vector3(cos(a0), 0, sin(a0)) * radius
		var p1 := center + Vector3(cos(a1), 0, sin(a1)) * radius
		var uv0: Vector2
		var uv1: Vector2
		var uvc: Vector2
		if tile <= 0.0:
			uvc = Vector2(0.5, 0.5)
			uv0 = Vector2(0.5 + cos(a0) * 0.5, 0.5 + sin(a0) * 0.5)
			uv1 = Vector2(0.5 + cos(a1) * 0.5, 0.5 + sin(a1) * 0.5)
		else:
			uvc = Vector2(center.x, center.z) / tile
			uv0 = Vector2(p0.x, p0.z) / tile
			uv1 = Vector2(p1.x, p1.z) / tile
		add_tri(mat, center, p0, p1, n, n, n, uvc, uv0, uv1)


## Yatay halka (havuz kenarı, kemer üstü vb.)
func add_ring(mat: String, center: Vector3, r_in: float, r_out: float, segs: int = 16, rot: float = 0.0) -> void:
	for i in range(segs):
		var a0 := rot + TAU * float(i) / segs
		var a1 := rot + TAU * float(i + 1) / segs
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var p0 := center + d0 * r_in
		var p1 := center + d1 * r_in
		var p2 := center + d1 * r_out
		var p3 := center + d0 * r_out
		var u0 := float(i) / segs
		var u1 := float(i + 1) / segs
		add_quad(mat, p0, p1, p2, p3, Vector3.UP, Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0), Vector2(u0, 0))


## Sivri kemerli (Osmanlı) açıklığın üstündeki duvar parçası.
## Yerel düzlemde x: -w/2..w/2, y: spring..top. Ark merkezli iki çember.
static func arch_curve(w: float, spring: float, steps: int = 10, rfac: float = 0.62) -> PackedVector2Array:
	var r := rfac * w
	var cx := r - w * 0.5
	var th := acos(clampf(cx / r, -1.0, 1.0))
	var pts := PackedVector2Array()
	# sol ark: merkez (+cx), açı PI'den PI-th'ye
	for i in range(steps + 1):
		var a := PI - th * float(i) / steps
		pts.append(Vector2(cx + r * cos(a), spring + r * sin(a)))
	# sağ ark: merkez (-cx), açı th'den 0'a
	for i in range(1, steps + 1):
		var a2 := th - th * float(i) / steps
		pts.append(Vector2(-cx + r * cos(a2), spring + r * sin(a2)))
	return pts


static func arch_apex(w: float, spring: float, rfac: float = 0.62) -> float:
	var r := rfac * w
	var cx := r - w * 0.5
	return spring + sqrt(maxf(r * r - cx * cx, 0.0))


func build(parent: Node3D, node_name: String, mats: Dictionary, cast_shadows: bool = true) -> Array:
	var created: Array = []
	for mat in _verts.keys():
		var v: PackedVector3Array = _verts[mat]
		if v.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = _norms[mat]
		arrays[Mesh.ARRAY_TEX_UV] = _uvs[mat]
		if Mats.DEFS.get(mat, {}).get("vcol", false):
			arrays[Mesh.ARRAY_COLOR] = _cols[mat]
		if Mats.has_normal(mat):
			# normal haritası için teğetler (MikkTSpace, C++)
			var st := SurfaceTool.new()
			st.create_from_arrays(arrays)
			st.generate_tangents()
			arrays = st.commit_to_arrays()
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		if mats.has(mat):
			mesh.surface_set_material(0, mats[mat])
		var mi := MeshInstance3D.new()
		mi.name = "%s_%s" % [node_name, mat]
		mi.mesh = mesh
		if not cast_shadows:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		created.append(mi)
	_verts.clear()
	_norms.clear()
	_uvs.clear()
	_cols.clear()
	return created
