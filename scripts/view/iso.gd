class_name Iso
extends RefCounted
## Isometric projection + cartoon drawing helpers (filled shapes with soft ink outlines).

const TW := 64.0
const TH := 32.0
const INK := Color(0.23, 0.2, 0.27, 0.78)
const INK_SOFT := Color(0.23, 0.2, 0.27, 0.35)


static func to_screen(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * TW * 0.5, (g.x + g.y) * TH * 0.5)


static func from_screen(p: Vector2) -> Vector2:
	var a := p.x / (TW * 0.5)
	var b := p.y / (TH * 0.5)
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


## grid point + height (px) -> screen
static func P(gx: float, gy: float, z := 0.0) -> Vector2:
	return Vector2((gx - gy) * TW * 0.5, (gx + gy) * TH * 0.5 - z)


static func shade(c: Color, f: float) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, c.a)


static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, outline := INK, width := 1.2) -> void:
	if pts.size() < 3:
		return
	ci.draw_colored_polygon(pts, fill)
	if outline.a > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, outline, width, true)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, c := INK, w := 1.2) -> void:
	ci.draw_line(a, b, c, w, true)


## An axis-aligned box on the grid. (x,y) back corner, w along x, d along y, h tall, z elevation.
## Colours: top, SW-facing side, SE-facing side. off = -node_position.
static func box(ci: CanvasItem, off: Vector2, x: float, y: float, w: float, d: float, h: float, z: float, top: Color, sw: Color, se: Color, outline := INK) -> void:
	var a0 := P(x, y, z) + off
	var b0 := P(x + w, y, z) + off
	var c0 := P(x + w, y + d, z) + off
	var d0 := P(x, y + d, z) + off
	var up := Vector2(0, -h)
	# SW face (front-left): d0 -> c0
	poly(ci, PackedVector2Array([d0, c0, c0 + up, d0 + up]), sw, outline)
	# SE face (front-right): c0 -> b0
	poly(ci, PackedVector2Array([c0, b0, b0 + up, c0 + up]), se, outline)
	# top
	poly(ci, PackedVector2Array([a0 + up, b0 + up, c0 + up, d0 + up]), top, outline)


## Box with automatic shading from one base colour.
static func cbox(ci: CanvasItem, off: Vector2, x: float, y: float, w: float, d: float, h: float, z: float, col: Color, outline := INK) -> void:
	box(ci, off, x, y, w, d, h, z, col.lightened(0.12), shade(col, 0.9), shade(col, 0.78), outline)


## Flat diamond on the floor/top at height z.
static func diamond(ci: CanvasItem, off: Vector2, x: float, y: float, w: float, d: float, z: float, col: Color, outline := Color(0, 0, 0, 0)) -> void:
	poly(ci, PackedVector2Array([P(x, y, z) + off, P(x + w, y, z) + off, P(x + w, y + d, z) + off, P(x, y + d, z) + off]), col, outline)


static func ellipse_pts(c: Vector2, rx: float, ry: float, n := 22, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, outline := INK, width := 1.2) -> void:
	var pts := ellipse_pts(c, rx, ry, 24)
	pts.remove_at(pts.size() - 1)
	poly(ci, pts, fill, outline, width)


## Iso floor ellipse (circle lying on the floor) at grid centre.
static func floor_ellipse(ci: CanvasItem, off: Vector2, gx: float, gy: float, r: float, z: float, fill: Color, outline := Color(0, 0, 0, 0)) -> void:
	var c := P(gx, gy, z) + off
	ellipse(ci, c, r * 45.25, r * 22.63, fill, outline)


static func rrect_pts(r: Rect2, rad: float, n := 4) -> PackedVector2Array:
	var pts := PackedVector2Array()
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad), Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	var starts := [-PI * 0.5, 0.0, PI * 0.5, PI]
	for k in 4:
		for i in n + 1:
			var a: float = starts[k] + PI * 0.5 * float(i) / n
			pts.append(cs[k] + Vector2(cos(a), sin(a)) * rad)
	return pts


static func rrect(ci: CanvasItem, r: Rect2, rad: float, fill: Color, outline := INK, width := 1.2) -> void:
	poly(ci, rrect_pts(r, rad), fill, outline, width)


## Capsule between two points (limbs).
static func capsule(ci: CanvasItem, a: Vector2, b: Vector2, r: float, fill: Color, outline := INK, width := 1.1) -> void:
	var dir := (b - a)
	var l := dir.length()
	if l < 0.01:
		ellipse(ci, a, r, r, fill, outline, width)
		return
	dir /= l
	var nrm := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array()
	var base := atan2(nrm.y, nrm.x)
	for i in 9:
		var ang := base - PI * float(i) / 8.0
		pts.append(b + Vector2(cos(ang), sin(ang)) * r)
	for i in 9:
		var ang2 := base + PI - PI * float(i) / 8.0
		pts.append(a + Vector2(cos(ang2), sin(ang2)) * r)
	poly(ci, pts, fill, outline, width)


## Transform that maps local 2D drawing onto a back wall plane.
## side "R": wall along x at y=0 ; side "L": wall along y at x=0 (reads left->right toward the back corner).
static func wall_xform(side: String, along: float, z: float, off: Vector2) -> Transform2D:
	if side == "R":
		return Transform2D(Vector2(1, 0.5), Vector2(0, 1), P(along, 0, z) + off)
	return Transform2D(Vector2(1, -0.5), Vector2(0, 1), P(0, along, z) + off)


## Length in px of one grid unit along a wall in the wall_xform local space.
const WALL_UNIT := 32.0
