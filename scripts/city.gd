class_name City
extends RefCounted
## Procedural İstanbul city kit. Geometry is merged per material bucket (few draw calls);
## collisions go into one StaticBody3D.

const SURF := preload("res://shaders/city_surface.gdshader")
const CLOTH := preload("res://shaders/cloth.gdshader")

var parent: Node3D
var body: StaticBody3D
var b := {}          # "bucket|chunk" -> MeshBuilder
var cur := Vector2i.ZERO
const CHUNK := 32.0
var rng := RandomNumberGenerator.new()
var ground_fn: Callable
var shadow_buckets := ["wall", "roof", "stone", "wood", "plain", "cloth"]

const WALL_COLS := ["f2d7b0", "e9b98f", "f0c9a8", "d98f6c", "c9d6b8", "b9cfd6", "f4e7d2", "e7a98c", "d8c39a", "efe2c4", "cfa98a", "a9c3b6"]
const SHUTTER_COLS := ["3f6b52", "345c7e", "7a4b33", "5a7d5f", "8a3b33", "2f5f6e"]
const ROOF_COLS := ["c4643f", "b85a3a", "cf7448", "a94f34", "bf6a48"]


func _init(p: Node3D, seed_val := 7) -> void:
	parent = p
	rng.seed = seed_val
	body = StaticBody3D.new()
	body.name = "CityCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)


## Selects the spatial chunk new geometry goes to (for frustum / shadow culling).
func at(p: Vector3) -> void:
	cur = Vector2i(floori(p.x / CHUNK), floori(p.z / CHUNK))


func mb(bucket: String) -> MeshBuilder:
	var key := "%s|%d|%d" % [bucket, cur.x, cur.y]
	if not b.has(key):
		b[key] = MeshBuilder.new()
	return b[key]


static func lin(hex: String) -> Color:
	return Color(hex).srgb_to_linear()


func ground(z: float) -> float:
	return ground_fn.call(z) if ground_fn.is_valid() else 0.0


# ------------------------------------------------------------------ collision
func col_box(center: Vector3, size: Vector3, rot_y := 0.0) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.transform = Transform3D(Basis(Vector3.UP, rot_y), center)
	body.add_child(cs)


func col_convex(points: PackedVector3Array) -> void:
	var cs := CollisionShape3D.new()
	var sh := ConvexPolygonShape3D.new()
	sh.points = points
	cs.shape = sh
	body.add_child(cs)


func col_cyl(base: Vector3, r: float, h: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	cs.position = base + Vector3(0, h * 0.5, 0)
	body.add_child(cs)


# ------------------------------------------------------------------ windows
func _window(center: Vector3, n: Vector3, u: Vector3, w: float, h: float, lit: bool, shutters: Color, detail: bool, frame_col := Color(-1, 0, 0)) -> void:
	var v := Vector3.UP
	var fc := lin("fbf3e6") if frame_col.r < 0.0 else frame_col
	if detail:
		var fw := w + 0.22
		var fh := h + 0.24
		var c0 := center + n * 0.02
		mb("plain").quad(c0 - u * fw * 0.5 - v * fh * 0.5, c0 + u * fw * 0.5 - v * fh * 0.5, c0 + u * fw * 0.5 + v * fh * 0.5, c0 - u * fw * 0.5 + v * fh * 0.5, fc)
		# sill
		var s0 := center - v * (h * 0.5 + 0.12) + n * 0.02
		var su := u * (fw * 0.5 + 0.05)
		var sf := s0 + n * 0.17
		mb("plain").quad(sf - su + v * 0.04, sf + su + v * 0.04, s0 + su + v * 0.04, s0 - su + v * 0.04, fc)
		mb("plain").quad(sf - su - v * 0.04, sf + su - v * 0.04, sf + su + v * 0.04, sf - su + v * 0.04, fc.darkened(0.08))
		if shutters.r >= 0.0:
			for sgn in [-1.0, 1.0]:
				var sc: Vector3 = center + u * sgn * (w * 0.5 + 0.11 + w * 0.26) + n * 0.03
				var sw := w * 0.5
				mb("wood").quad(sc - u * sw * 0.5 - v * h * 0.5, sc + u * sw * 0.5 - v * h * 0.5, sc + u * sw * 0.5 + v * h * 0.5, sc - u * sw * 0.5 + v * h * 0.5, shutters)
	var g0 := center + n * (0.035 if detail else 0.02)
	var gc := lin("ffcf7a") if lit else lin("2c3a52")
	var bucket := "lit" if lit else "glass"
	mb(bucket).quad(g0 - u * w * 0.5 - v * h * 0.5, g0 + u * w * 0.5 - v * h * 0.5, g0 + u * w * 0.5 + v * h * 0.5, g0 - u * w * 0.5 + v * h * 0.5, gc)
	if detail and not lit:
		# window cross bars
		var bc := lin("e8dfd0")
		var g1 := center + n * 0.045
		mb("plain").quad(g1 - u * 0.03 - v * h * 0.5, g1 + u * 0.03 - v * h * 0.5, g1 + u * 0.03 + v * h * 0.5, g1 - u * 0.03 + v * h * 0.5, bc)
		mb("plain").quad(g1 - u * w * 0.5 - v * 0.03 + v * h * 0.12, g1 + u * w * 0.5 - v * 0.03 + v * h * 0.12, g1 + u * w * 0.5 + v * 0.03 + v * h * 0.12, g1 - u * w * 0.5 + v * 0.03 + v * h * 0.12, bc)


## Facade windows on one face of a building.
func _facade(center: Vector3, n: Vector3, u: Vector3, width: float, gy: float, top: float, opts: Dictionary) -> void:
	var detail: bool = opts.get("detail", true)
	var fh := 2.3
	var cols := int(max(1.0, floor(width / 1.9)))
	var spacing := width / cols
	var lit_ratio: float = opts.get("lit", 0.18)
	var shutters: Color = opts.get("shutters", Color(-1, 0, 0))
	var k := 0
	while true:
		var wy := gy + fh * k + 1.45
		if wy + 0.7 > top - 0.35:
			break
		if wy - 0.7 > gy - 0.2:
			for i in cols:
				var x := -width * 0.5 + spacing * (i + 0.5)
				var shop: bool = k == 0 and opts.get("shops", false)
				var lit := rng.randf() < (lit_ratio * (1.8 if shop else 1.0))
				if shop:
					_window(center + u * x + Vector3(0, wy - 0.25, 0) + n * 0.0, n, u, min(spacing - 0.5, 1.7), 1.8, lit, Color(-1, 0, 0), detail, lin("6b3b2c"))
				else:
					_window(center + u * x + Vector3(0, wy, 0), n, u, 0.72, 1.12, lit, shutters, detail)
		k += 1
	# floor bands
	if detail:
		var bandc: Color = opts.get("trim", lin("f7eedf"))
		var kk := 1
		while gy + fh * kk + 0.2 < top - 0.6:
			var y := gy + fh * kk + 0.25
			var c0 := center + Vector3(0, y, 0) + n * 0.05
			mb("plain").quad(c0 - u * width * 0.5 - Vector3(0, 0.07, 0), c0 + u * width * 0.5 - Vector3(0, 0.07, 0), c0 + u * width * 0.5 + Vector3(0, 0.07, 0), c0 - u * width * 0.5 + Vector3(0, 0.07, 0), bandc)
			kk += 1


# ------------------------------------------------------------------ houses
## Builds a house whose roof (eaves for pitched roofs) sits at top_y.
## Returns the walkable top height (ridge for pitched roofs).
func house(cx: float, cz: float, w: float, d: float, top_y: float, opts := {}) -> float:
	at(Vector3(cx, 0, cz))
	var gy: float = opts.get("ground", min(ground(cz - d * 0.5), ground(cz + d * 0.5)))
	var base: float = gy - 1.5
	var wall_c: Color = opts.get("color", lin(WALL_COLS[rng.randi() % WALL_COLS.size()]))
	if opts.has("hex"):
		wall_c = lin(opts["hex"])
	var detail: bool = opts.get("detail", true)
	var roof: String = opts.get("roof", "flat")
	var h := top_y - base
	var center := Vector3(cx, base + h * 0.5, cz)
	mb("wall").box(center, Vector3(w, h, d), wall_c, 0.0, false, wall_c.darkened(0.04), wall_c, roof != "flat")
	if roof == "flat":
		var tc: Color = lin(opts.get("roof_hex", ["d9b8a0", "cfc2b4", "d6a98e", "c9b6a6"][rng.randi() % 4]))
		mb("terrace").quad(Vector3(cx - w * 0.5, top_y, cz + d * 0.5), Vector3(cx + w * 0.5, top_y, cz + d * 0.5), Vector3(cx + w * 0.5, top_y, cz - d * 0.5), Vector3(cx - w * 0.5, top_y, cz - d * 0.5), tc)
	if opts.get("collide", true):
		col_box(center, Vector3(w, h, d))
	if not opts.has("shutters") and rng.randf() < 0.55:
		opts["shutters"] = lin(SHUTTER_COLS[rng.randi() % SHUTTER_COLS.size()])
	var faces: Array = opts.get("faces", ["n", "s", "e", "w"])
	var gy_vis := gy + 0.0
	for f in faces:
		match f:
			"s": _facade(Vector3(cx, 0, cz + d * 0.5), Vector3(0, 0, 1), Vector3(1, 0, 0), w, max(gy_vis, ground(cz + d * 0.5)), top_y, opts)
			"n": _facade(Vector3(cx, 0, cz - d * 0.5), Vector3(0, 0, -1), Vector3(-1, 0, 0), w, max(gy_vis, ground(cz - d * 0.5)), top_y, opts)
			"e": _facade(Vector3(cx + w * 0.5, 0, cz), Vector3(1, 0, 0), Vector3(0, 0, -1), d, gy_vis, top_y, opts)
			"w": _facade(Vector3(cx - w * 0.5, 0, cz), Vector3(-1, 0, 0), Vector3(0, 0, 1), d, gy_vis, top_y, opts)
	# cornice
	var trim: Color = opts.get("trim", lin("f7eedf"))
	if detail:
		mb("plain").box(Vector3(cx, top_y - 0.17, cz), Vector3(w + 0.24, 0.26, d + 0.24), trim)
	var walk_top := top_y
	var roof_c: Color = lin(ROOF_COLS[rng.randi() % ROOF_COLS.size()])
	if opts.has("roof_color"):
		roof_c = opts["roof_color"]
	match roof:
		"flat":
			if opts.get("parapet", false):
				var ph := 0.45
				for s in [[Vector3(0, 0, d * 0.5 - 0.1), Vector3(w, ph, 0.2)], [Vector3(0, 0, -d * 0.5 + 0.1), Vector3(w, ph, 0.2)],
						[Vector3(w * 0.5 - 0.1, 0, 0), Vector3(0.2, ph, d)], [Vector3(-w * 0.5 + 0.1, 0, 0), Vector3(0.2, ph, d)]]:
					mb("plain").box(Vector3(cx, top_y + ph * 0.5, cz) + s[0], s[1], trim)
					if opts.get("collide", true):
						col_box(Vector3(cx, top_y + ph * 0.5, cz) + s[0], s[1])
		"gable_x", "gable_z":
			var rh: float = opts.get("roof_h", min(w, d) * 0.3)
			var ax := roof == "gable_x"
			mb("roof").gable(Vector3(cx, top_y, cz), w, d, rh, roof_c, wall_c, ax, 0.3)
			walk_top = top_y + rh
			if opts.get("collide", true):
				var pts := PackedVector3Array()
				var hw := w * 0.5 + 0.1
				var hd := d * 0.5 + 0.1
				if ax:
					pts = PackedVector3Array([Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd), Vector3(hw, 0, hd), Vector3(-hw, 0, hd), Vector3(-hw, rh, 0), Vector3(hw, rh, 0)])
				else:
					pts = PackedVector3Array([Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd), Vector3(hw, 0, hd), Vector3(-hw, 0, hd), Vector3(0, rh, -hd), Vector3(0, rh, hd)])
				for i in pts.size():
					pts[i] += Vector3(cx, top_y - 0.02, cz)
				col_convex(pts)
		"hip":
			var rh2: float = opts.get("roof_h", min(w, d) * 0.28)
			mb("roof").hip(Vector3(cx, top_y, cz), w, d, rh2, roof_c, 0.3)
			walk_top = top_y + rh2
			if opts.get("collide", true):
				var hw2 := w * 0.5 + 0.1
				var hd2 := d * 0.5 + 0.1
				var r0 := maxf(0.0, (w - d) * 0.5)
				var r1 := maxf(0.0, (d - w) * 0.5)
				var pts2 := PackedVector3Array([Vector3(-hw2, 0, -hd2), Vector3(hw2, 0, -hd2), Vector3(hw2, 0, hd2), Vector3(-hw2, 0, hd2), Vector3(-r0, rh2, -r1), Vector3(r0, rh2, r1)])
				for i in pts2.size():
					pts2[i] += Vector3(cx, top_y - 0.02, cz)
				col_convex(pts2)
	if opts.get("props", false):
		_random_props(cx, cz, w, d, top_y, roof)
	return walk_top


func _random_props(cx: float, cz: float, w: float, d: float, top: float, roof: String) -> void:
	var n := rng.randi_range(1, 3)
	for i in n:
		var px := cx + rng.randf_range(-w * 0.35, w * 0.35)
		var pz := cz + rng.randf_range(-d * 0.35, d * 0.35)
		var r := rng.randf()
		if roof == "flat":
			if r < 0.35:
				chimney(Vector3(px, top, pz), false)
			elif r < 0.6:
				water_tank(Vector3(px, top, pz), false)
			elif r < 0.8:
				antenna(Vector3(px, top, pz))
			else:
				dish(Vector3(px, top, pz), rng.randf() * TAU)
		else:
			if r < 0.5:
				antenna(Vector3(px, top + 0.8, pz))
			else:
				chimney(Vector3(px, top, pz), false, 2.2)


# ------------------------------------------------------------------ props
func chimney(p: Vector3, collide := true, h := 1.5) -> float:
	at(p)
	var c := lin("b8735a")
	mb("wall").box(p + Vector3(0, h * 0.5, 0), Vector3(0.9, h, 0.9), c)
	mb("plain").box(p + Vector3(0, h + 0.08, 0), Vector3(1.1, 0.16, 1.1), lin("8b5a48"))
	mb("plain").box(p + Vector3(0, h + 0.3, 0), Vector3(0.5, 0.3, 0.5), lin("6e4a3e"))
	if collide:
		col_box(p + Vector3(0, (h + 0.16) * 0.5, 0), Vector3(1.0, h + 0.16, 1.0))
	return p.y + h + 0.16


## Wide double chimney stack (friendlier landing spot).
func chimney_stack(p: Vector3, h := 2.6) -> float:
	at(p)
	var c := lin("b8735a")
	mb("wall").box(p + Vector3(0, h * 0.5, 0), Vector3(1.7, h, 1.5), c)
	mb("plain").box(p + Vector3(0, h + 0.08, 0), Vector3(1.95, 0.16, 1.75), lin("8b5a48"))
	for ox in [-0.45, 0.45]:
		mb("plain").box(p + Vector3(ox, h + 0.36, -0.4), Vector3(0.42, 0.4, 0.42), lin("6e4a3e"))
	col_box(p + Vector3(0, (h + 0.16) * 0.5, 0), Vector3(1.9, h + 0.16, 1.7))
	return p.y + h + 0.16


func water_tank(p: Vector3, collide := true) -> float:
	at(p)
	# classic rooftop tank on little legs
	var lc := lin("6f7781")
	for o in [Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5), Vector3(0.5, 0, 0.5), Vector3(-0.5, 0, 0.5)]:
		mb("plain").box(p + o + Vector3(0, 0.35, 0), Vector3(0.12, 0.7, 0.12), lc)
	mb("plain").cylinder(p + Vector3(0, 0.7, 0), 0.85, 1.25, lin("dfe4e8"), 16, true, true, lin("c8ced4"))
	mb("plain").cylinder(p + Vector3(0, 1.95, 0), 0.25, 0.12, lin("9aa3ad"), 10)
	if collide:
		col_cyl(p, 0.85, 1.95)
	return p.y + 1.95


func antenna(p: Vector3) -> void:
	var c := lin("7c848e")
	mb("plain").box(p + Vector3(0, 1.0, 0), Vector3(0.06, 2.0, 0.06), c)
	for i in 4:
		var y := 1.3 + i * 0.22
		var l := 1.1 - i * 0.18
		mb("plain").box(p + Vector3(0, y, 0), Vector3(l, 0.04, 0.04), c)


func dish(p: Vector3, rot: float) -> void:
	mb("plain").box(p + Vector3(0, 0.45, 0), Vector3(0.08, 0.9, 0.08), lin("7c848e"))
	var d := Vector3(sin(rot), 0.5, cos(rot)).normalized()
	var c := p + Vector3(0, 1.0, 0)
	var u := d.cross(Vector3.UP).normalized()
	var v := u.cross(d).normalized()
	var segs := 12
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var p0 := c + (u * cos(a0) + v * sin(a0)) * 0.5
		var p1 := c + (u * cos(a1) + v * sin(a1)) * 0.5
		var back := c - d * 0.15
		mb("plain").tri(c + d * 0.02, p1, p0, lin("eef0f2"))
		mb("plain").tri(back, p0, p1, lin("c9ced3"))


func plank(center: Vector3, size: Vector3, rot_y := 0.0, collide := true) -> void:
	at(center)
	mb("wood").box(center, size, lin("9c6b43"), rot_y, true)
	# little support brackets
	var bb := Basis(Vector3.UP, rot_y)
	for sx in [-0.35, 0.35]:
		mb("plain").box(center + bb * Vector3(size.x * sx, -size.y * 0.5 - 0.25, 0), Vector3(0.1, 0.5, 0.1), lin("5d4636"), rot_y)
	if collide:
		col_box(center, size, rot_y)


func crate(center: Vector3, s := 1.0, collide := true) -> void:
	at(center)
	mb("wood").box(center + Vector3(0, s * 0.5, 0), Vector3(s, s, s), lin("b98552"), rng.randf() * 0.3, true)
	if collide:
		col_box(center + Vector3(0, s * 0.5, 0), Vector3(s, s, s))


## Ottoman bay window (cumba) — a walkable ledge. face: normal of facade.
func cumba(base_center: Vector3, n: Vector3, width: float, height: float, depth := 0.9, color := Color(-1, 0, 0)) -> float:
	var c: Color = lin("a0663f") if color.r < 0.0 else color
	var u := n.cross(Vector3.UP).normalized()
	var center := base_center + n * depth * 0.5 + Vector3(0, height * 0.5, 0)
	var size := Vector3(width, height, depth) if abs(n.z) > 0.5 else Vector3(depth, height, width)
	mb("wood").box(center, size, c, 0.0, true, c.darkened(0.1), lin("8c4e33"))
	# windows on the front
	var front := base_center + n * depth
	for i in int(max(1.0, floor(width / 1.2))):
		var cols := int(max(1.0, floor(width / 1.2)))
		var x := -width * 0.5 + width / cols * (i + 0.5)
		_window(front + u * x + Vector3(0, height * 0.55, 0), n, -u if n.z > 0 or n.x < 0 else u, 0.6, height * 0.5, rng.randf() < 0.3, Color(-1, 0, 0), true, lin("f3e6cf"))
	# little roof cap
	mb("roof").box(center + Vector3(0, height * 0.5 + 0.08, 0), size + Vector3(0.2, 0.16, 0.2), lin("b5603c"))
	col_box(center + Vector3(0, 0.08, 0), size + Vector3(0.0, 0.16, 0.0))
	return base_center.y + height + 0.16


## Clothesline between two points. Optional walkable rope.
func clothesline(a: Vector3, b_: Vector3, walkable := true, laundry := true) -> void:
	at((a + b_) * 0.5)
	var pc := lin("6d6560")
	mb("plain").box(a + Vector3(0, -0.6, 0), Vector3(0.12, 1.4, 0.12), pc)
	mb("plain").box(b_ + Vector3(0, -0.6, 0), Vector3(0.12, 1.4, 0.12), pc)
	var dir := b_ - a
	var L := dir.length()
	var mid := (a + b_) * 0.5
	var yaw := atan2(dir.x, dir.z)
	var flat_len := Vector2(dir.x, dir.z).length()
	var pitch := atan2(dir.y, flat_len)
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -pitch)
	# rope
	var rope_c := lin("f4efe6")
	var segs := 10
	for i in segs:
		var t0 := float(i) / segs
		var t1 := float(i + 1) / segs
		var p0 := a.lerp(b_, t0)
		var p1 := a.lerp(b_, t1)
		var sag0 := -sin(t0 * PI) * 0.15
		var sag1 := -sin(t1 * PI) * 0.15
		_rope_seg(p0 + Vector3(0, sag0, 0), p1 + Vector3(0, sag1, 0), 0.045, rope_c)
	if walkable:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.5, 0.2, L)
		cs.shape = bs
		cs.transform = Transform3D(basis, mid + Vector3(0, -0.18, 0))
		body.add_child(cs)
	if laundry:
		var cols := ["e85d4a", "f2c14e", "5aa6d6", "ffffff", "8bc28c", "e78fb3", "f7f1e3", "3e74c7"]
		var n := int(L / 1.1)
		for i in n:
			var t := (i + 0.5) / n
			if rng.randf() < 0.25:
				continue
			var p := a.lerp(b_, t) + Vector3(0, -sin(t * PI) * 0.15 - 0.03, 0)
			var cw := rng.randf_range(0.45, 0.8)
			var ch := rng.randf_range(0.5, 0.95)
			var right := basis * Vector3(0, 0, 1)
			var col := lin(cols[rng.randi() % cols.size()])
			var p0 := p - right * cw * 0.5
			var p1 := p + right * cw * 0.5
			mb("cloth").quad_uv(p0 - Vector3(0, ch, 0), p1 - Vector3(0, ch, 0), p1, p0, col, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))


func _rope_seg(p0: Vector3, p1: Vector3, r: float, c: Color) -> void:
	var d := (p1 - p0)
	var L := d.length()
	if L < 0.001:
		return
	var z := d / L
	var x := z.cross(Vector3.UP)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := x.cross(z).normalized()
	for i in 4:
		var a0 := TAU * i / 4.0
		var a1 := TAU * (i + 1) / 4.0
		var o0 := (x * cos(a0) + y * sin(a0)) * r
		var o1 := (x * cos(a1) + y * sin(a1)) * r
		mb("plain").quad(p0 + o0, p0 + o1, p1 + o1, p1 + o0, c)


## Striped shop awning (visual). Returns top surface centre.
func awning(center: Vector3, n: Vector3, width: float, depth := 1.6, drop := 0.6, cols := ["e8473a", "fff4e0"]) -> void:
	at(center)
	var u := n.cross(Vector3.UP).normalized()
	var stripes := int(width / 0.4)
	for i in stripes:
		var x0 := -width * 0.5 + width * i / stripes
		var x1 := -width * 0.5 + width * (i + 1) / stripes
		var col := lin(cols[i % cols.size()])
		var a := center + u * x0
		var bb := center + u * x1
		var c := bb + n * depth - Vector3(0, drop, 0)
		var d := a + n * depth - Vector3(0, drop, 0)
		mb("cloth").quad_uv(d, c, bb, a, col, Vector2(0, 0.25), Vector2(1, 0.25), Vector2(1, 0), Vector2(0, 0))
		# valance
		var e := c - Vector3(0, 0.28, 0)
		var f := d - Vector3(0, 0.28, 0)
		mb("cloth").quad_uv(f, e, c, d, col, Vector2(0, 0.4), Vector2(1, 0.4), Vector2(1, 0.25), Vector2(0, 0.25))


# ------------------------------------------------------------------ landmarks
func mosque(c: Vector3, s: float, minarets := 2, col_hex := "e9e2d6") -> void:
	at(c)
	var col := lin(col_hex)
	var dome_c := lin("8f98a3")
	var bucket := "far"
	mb(bucket).box(c + Vector3(0, 3 * s, 0), Vector3(14 * s, 6 * s, 14 * s), col)
	mb(bucket).cylinder(c + Vector3(0, 6 * s, 0), 6.2 * s, 1.6 * s, col, 20, false)
	mb(bucket).dome(c + Vector3(0, 7.6 * s, 0), 6.2 * s, dome_c, 20, 6, 0.9)
	for k in 4:
		var a := TAU * k / 4.0 + PI * 0.25
		var o := Vector3(cos(a), 0, sin(a)) * 6.8 * s
		mb(bucket).cylinder(c + o + Vector3(0, 6 * s, 0), 1.6 * s, 0.6 * s, col, 10, false)
		mb(bucket).dome(c + o + Vector3(0, 6.6 * s, 0), 1.6 * s, dome_c, 10, 4)
	for k in 4:
		var a2 := TAU * k / 4.0
		var o2 := Vector3(cos(a2), 0, sin(a2)) * 7.4 * s
		mb(bucket).dome(c + o2 + Vector3(0, 4.5 * s, 0), 2.6 * s, dome_c, 12, 4)
	var mpos := [Vector3(-8.5, 0, -8.5), Vector3(8.5, 0, -8.5), Vector3(-8.5, 0, 8.5), Vector3(8.5, 0, 8.5), Vector3(-11, 0, 0), Vector3(11, 0, 0)]
	for i in minarets:
		var mp: Vector3 = c + mpos[i] * s
		mb(bucket).cylinder(mp, 0.75 * s, 17 * s, col, 10, false, false, Color(-1, 0, 0), 0.6 * s)
		mb(bucket).cylinder(mp + Vector3(0, 11 * s, 0), 1.1 * s, 0.4 * s, col, 10)
		mb(bucket).cylinder(mp + Vector3(0, 15 * s, 0), 1.0 * s, 0.35 * s, col, 10)
		mb(bucket).cone(mp + Vector3(0, 17 * s, 0), 0.8 * s, 4.2 * s, dome_c, 10)


func _make_mat(pattern: int, gloss := 0.0, rim := 0.12) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SURF
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("gloss", gloss)
	m.set_shader_parameter("rim_strength", rim)
	return m


const MERGED := {"wall": 0, "roof": 1, "stone": 2, "street": 3, "wood": 4, "plain": 5, "glass": 6, "terrace": 7}


func commit(materials_parent: Node3D) -> Dictionary:
	var city_mat := ShaderMaterial.new()
	city_mat.shader = SURF
	city_mat.set_shader_parameter("rim_strength", 0.12)
	var far_mat := ShaderMaterial.new()
	far_mat.shader = SURF
	far_mat.set_shader_parameter("force_pattern", 5)
	far_mat.set_shader_parameter("rim_strength", 0.0)
	var lit := StandardMaterial3D.new()
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lit.vertex_color_use_as_albedo = true
	lit.vertex_color_is_srgb = false
	var cloth := ShaderMaterial.new()
	cloth.shader = CLOTH
	var merged := {}   # chunk -> MeshBuilder
	var others := {}   # key -> builder
	for key in b.keys():
		var builder: MeshBuilder = b[key]
		if builder.is_empty():
			continue
		var parts: PackedStringArray = key.split("|")
		var bucket := parts[0]
		var chunk := parts[1] + "_" + parts[2]
		if MERGED.has(bucket):
			builder.set_alpha(MERGED[bucket] / 10.0)
			if not merged.has(chunk):
				merged[chunk] = MeshBuilder.new()
			merged[chunk].append(builder)
		else:
			others[key] = builder
	var out := {}
	for chunk in merged.keys():
		var mi := MeshInstance3D.new()
		mi.name = "City_city_" + chunk
		mi.mesh = merged[chunk].commit(null, city_mat)
		materials_parent.add_child(mi)
		out["city|" + chunk] = mi
	for key in others.keys():
		var bucket2: String = key.split("|")[0]
		var mi2 := MeshInstance3D.new()
		mi2.name = "City_" + key.replace("|", "_")
		var mat: Material = far_mat
		match bucket2:
			"lit": mat = lit
			"cloth": mat = cloth
		mi2.mesh = others[key].commit(null, mat)
		if bucket2 != "cloth":
			mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		materials_parent.add_child(mi2)
		out[key] = mi2
	b.clear()
	return out
