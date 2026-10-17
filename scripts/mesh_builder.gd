class_name MeshBuilder
extends RefCounted
## Accumulates triangles (with vertex colours / normals / world-scale UVs) and
## commits them to an ArrayMesh. Quads/polygons are given counter-clockwise as
## seen from the front; Godot treats clockwise as front, so we emit reversed.

var verts := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var uvs := PackedVector2Array()


func is_empty() -> bool:
	return verts.is_empty()


func _push(p: Vector3, n: Vector3, c: Color, uv: Vector2) -> void:
	verts.append(p)
	normals.append(n)
	colors.append(c)
	uvs.append(uv)


func tri(a: Vector3, b: Vector3, c: Vector3, col: Color, n := Vector3.ZERO, ua := Vector2.ZERO, ub := Vector2.ZERO, uc := Vector2.ZERO) -> void:
	if n == Vector3.ZERO:
		n = (b - a).cross(c - a).normalized()
	_push(a, n, col, ua)
	_push(c, n, col, uc)
	_push(b, n, col, ub)


func tri_smooth(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, col: Color, ua := Vector2.ZERO, ub := Vector2.ZERO, uc := Vector2.ZERO) -> void:
	_push(a, na, col, ua)
	_push(c, nc, col, uc)
	_push(b, nb, col, ub)


## Quad a,b,c,d counter-clockwise from the front. UVs are world-scale (metres)
## projected on the quad's own plane unless given.
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, uv_scale := 1.0) -> void:
	var n := (b - a).cross(c - a).normalized()
	var u_axis := (b - a).normalized()
	var v_axis := n.cross(u_axis).normalized()
	var o := a
	var f := func(p: Vector3) -> Vector2:
		var r := p - o
		return Vector2(r.dot(u_axis), r.dot(v_axis)) * uv_scale
	tri(a, b, c, col, n, f.call(a), f.call(b), f.call(c))
	tri(a, c, d, col, n, f.call(a), f.call(c), f.call(d))


func quad_uv(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	var n := (b - a).cross(c - a).normalized()
	tri(a, b, c, col, n, ua, ub, uc)
	tri(a, c, d, col, n, ua, uc, ud)


## Axis-aligned (optionally y-rotated) box. center = box centre.
func box(center: Vector3, size: Vector3, col: Color, rot_y := 0.0, bottom := false, side_col := Color(-1, 0, 0), top_col := Color(-1, 0, 0), top := true) -> void:
	var h := size * 0.5
	var b := Basis(Vector3.UP, rot_y)
	var p := func(x: float, y: float, z: float) -> Vector3:
		return center + b * Vector3(x * h.x, y * h.y, z * h.z)
	var sc := col if side_col.r < 0.0 else side_col
	var tc := col if top_col.r < 0.0 else top_col
	if top:
		quad(p.call(-1, 1, 1), p.call(1, 1, 1), p.call(1, 1, -1), p.call(-1, 1, -1), tc)
	if bottom:
		quad(p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, -1, 1), p.call(-1, -1, 1), col)
	# +z (front)
	quad(p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1), sc)
	# -z
	quad(p.call(1, -1, -1), p.call(-1, -1, -1), p.call(-1, 1, -1), p.call(1, 1, -1), sc)
	# +x
	quad(p.call(1, -1, 1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(1, 1, 1), col)
	# -x
	quad(p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1), col)


## Cylinder along Y from base centre.
func cylinder(base: Vector3, radius: float, height: float, col: Color, segs := 16, top := true, bottom := false, top_col := Color(-1, 0, 0), r_top := -1.0) -> void:
	var rt := radius if r_top < 0.0 else r_top
	var tc := col if top_col.r < 0.0 else top_col
	var slope := (radius - rt) / maxf(height, 0.0001)
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var n0 := (d0 + Vector3(0, slope, 0)).normalized()
		var n1 := (d1 + Vector3(0, slope, 0)).normalized()
		var b0 := base + d0 * radius
		var b1 := base + d1 * radius
		var t0 := base + d0 * rt + Vector3(0, height, 0)
		var t1 := base + d1 * rt + Vector3(0, height, 0)
		var u0 := radius * a0
		var u1 := radius * a1
		# outward-facing: ccw from outside is b1,b0,t0,t1
		tri_smooth(b1, b0, t0, n1, n0, n0, col, Vector2(u1, 0), Vector2(u0, 0), Vector2(u0, height))
		tri_smooth(b1, t0, t1, n1, n0, n1, col, Vector2(u1, 0), Vector2(u0, height), Vector2(u1, height))
		if top and rt > 0.001:
			var c := base + Vector3(0, height, 0)
			tri(c, t1, t0, tc, Vector3.UP)
		if bottom:
			tri(base, b0, b1, col, Vector3.DOWN)


func cone(base: Vector3, radius: float, height: float, col: Color, segs := 16) -> void:
	var apex := base + Vector3(0, height, 0)
	var k := radius / height
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var am := (a0 + a1) * 0.5
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var n0 := (d0 + Vector3(0, k, 0)).normalized()
		var n1 := (d1 + Vector3(0, k, 0)).normalized()
		var nm := (Vector3(cos(am), 0, sin(am)) + Vector3(0, k, 0)).normalized()
		tri_smooth(base + d1 * radius, base + d0 * radius, apex, n1, n0, nm, col)


## Hemisphere dome (smooth), optionally stretched vertically (onion-ish when squash>1).
func dome(center: Vector3, radius: float, col: Color, segs := 20, rings := 8, y_scale := 1.0) -> void:
	for r in rings:
		var p0 := PI * 0.5 * r / rings
		var p1 := PI * 0.5 * (r + 1) / rings
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var v := func(a: float, p: float) -> Vector3:
				return Vector3(cos(a) * cos(p), sin(p) * y_scale, sin(a) * cos(p))
			var nn := func(a: float, p: float) -> Vector3:
				return Vector3(cos(a) * cos(p), sin(p) / y_scale, sin(a) * cos(p)).normalized()
			var a: Vector3 = center + v.call(a0, p0) * radius
			var b: Vector3 = center + v.call(a1, p0) * radius
			var c: Vector3 = center + v.call(a1, p1) * radius
			var d: Vector3 = center + v.call(a0, p1) * radius
			tri_smooth(b, a, d, nn.call(a1, p0), nn.call(a0, p0), nn.call(a0, p1), col)
			if r < rings - 1:
				tri_smooth(b, d, c, nn.call(a1, p0), nn.call(a0, p1), nn.call(a1, p1), col)


## Gable roof sitting on top of a w x d footprint at height y. Ridge along X if axis_x.
func gable(center_base: Vector3, w: float, d: float, h: float, roof_col: Color, gable_col: Color, axis_x := true, overhang := 0.25, rot_y := 0.0) -> void:
	var b := Basis(Vector3.UP, rot_y)
	var hw := w * 0.5
	var hd := d * 0.5
	if not axis_x:
		var tmp := hw
		hw = hd
		hd = tmp
		b = b * Basis(Vector3.UP, PI * 0.5)
	var P := func(x: float, y: float, z: float) -> Vector3:
		return center_base + b * Vector3(x, y, z)
	var o := overhang
	# slopes (ridge along local X)
	quad(P.call(-hw - o, -0.08, hd + o), P.call(hw + o, -0.08, hd + o), P.call(hw + o, h, 0), P.call(-hw - o, h, 0), roof_col)
	quad(P.call(hw + o, -0.08, -hd - o), P.call(-hw - o, -0.08, -hd - o), P.call(-hw - o, h, 0), P.call(hw + o, h, 0), roof_col)
	# gable triangles
	tri(P.call(hw, 0, hd), P.call(hw, 0, -hd), P.call(hw, h, 0), gable_col)
	tri(P.call(-hw, 0, -hd), P.call(-hw, 0, hd), P.call(-hw, h, 0), gable_col)
	# underside of overhang (dark)
	var uc := roof_col.darkened(0.45)
	quad(P.call(-hw - o, -0.08, hd + o), P.call(-hw - o, -0.08 + o * 0.5, hd), P.call(hw + o, -0.08 + o * 0.5, hd), P.call(hw + o, -0.08, hd + o), uc)
	quad(P.call(hw + o, -0.08, -hd - o), P.call(hw + o, -0.08 + o * 0.5, -hd), P.call(-hw - o, -0.08 + o * 0.5, -hd), P.call(-hw - o, -0.08, -hd - o), uc)


## Hip (pyramid-like) roof.
func hip(center_base: Vector3, w: float, d: float, h: float, roof_col: Color, overhang := 0.25, rot_y := 0.0) -> void:
	var b := Basis(Vector3.UP, rot_y)
	var hw := w * 0.5 + overhang
	var hd := d * 0.5 + overhang
	var ridge: float = max(0.0, (w - d) * 0.5) if w > d else 0.0
	var ridge_z: float = max(0.0, (d - w) * 0.5) if d > w else 0.0
	var P := func(x: float, y: float, z: float) -> Vector3:
		return center_base + b * Vector3(x, y, z)
	var y0 := -0.08
	var c00: Vector3 = P.call(-hw, y0, -hd)
	var c10: Vector3 = P.call(hw, y0, -hd)
	var c11: Vector3 = P.call(hw, y0, hd)
	var c01: Vector3 = P.call(-hw, y0, hd)
	var r0: Vector3 = P.call(-ridge, h, -ridge_z)
	var r1: Vector3 = P.call(ridge, h, ridge_z)
	if ridge > 0.0:
		quad(c01, c11, r1, r0, roof_col)
		quad(c10, c00, r0, r1, roof_col)
		tri(c11, c10, r1, roof_col)
		tri(c00, c01, r0, roof_col)
	elif ridge_z > 0.0:
		quad(c11, c10, r0, r1, roof_col)
		quad(c00, c01, r1, r0, roof_col)
		tri(c01, c11, r1, roof_col)
		tri(c10, c00, r0, roof_col)
	else:
		var top: Vector3 = P.call(0, h, 0)
		tri(c01, c11, top, roof_col)
		tri(c11, c10, top, roof_col)
		tri(c10, c00, top, roof_col)
		tri(c00, c01, top, roof_col)


func set_alpha(a: float) -> void:
	for i in colors.size():
		colors[i].a = a


func append(o: MeshBuilder) -> void:
	verts.append_array(o.verts)
	normals.append_array(o.normals)
	colors.append_array(o.colors)
	uvs.append_array(o.uvs)


func commit(mesh: ArrayMesh = null, material: Material = null) -> ArrayMesh:
	if mesh == null:
		mesh = ArrayMesh.new()
	if verts.is_empty():
		return mesh
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_COLOR] = colors
	arr[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if material:
		mesh.surface_set_material(mesh.get_surface_count() - 1, material)
	return mesh
