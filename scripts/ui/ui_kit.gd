class_name UiKit
extends RefCounted
## Stationery-themed UI kit: fonts, palette and drawing helpers for sticky notes,
## index cards, manila folders, tape, pins and paper clips.

const INK := Color("2b2d42")
const INK_SOFT := Color(0.17, 0.18, 0.26, 0.55)
const RED := Color("e63946")
const BLUE := Color("2b6cb0")
const GREEN := Color("2a9d8f")
const PAPER := Color("fffdf5")
const KRAFT := Color("d9bf93")
const CORK := Color("c9a16b")
const MANILA := Color("f0d69c")
const TAPE := Color(0.98, 0.95, 0.82, 0.78)
const STICKY := {
	"yellow": Color("fff07a"), "pink": Color("ffb3c6"), "blue": Color("a8d8ff"), "green": Color("b8f2a0"),
	"orange": Color("ffcf96"), "lilac": Color("d9c8ff"), "white": Color("fffdf5"),
}
const CAT_COLOR := {
	"conflict": "pink", "malfunction": "orange", "help": "green", "friendship": "green", "solidarity": "green",
	"rumor": "lilac", "secret": "lilac", "romance": "pink", "boss": "orange", "meeting": "blue", "promotion": "yellow",
	"scheme": "lilac", "ghost": "white", "prank": "yellow", "email": "blue", "reward": "yellow", "drama": "pink",
	"player": "white", "work": "blue", "cliques": "orange", "misc": "yellow",
}
const NPC_COLOR := {
	"ahmet": Color("34416b"), "selin": Color("8e3b57"), "mert": Color("2f7fc1"), "zeynep": Color("d08a12"),
	"burak": Color("4c7a5a"), "ece": Color("e0608a"), "deniz": Color("6b4fb3"), "ceren": Color("2a9d8f"),
}

static var _fonts := {}


static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var path := ""
	match kind:
		"marker": path = "res://assets/fonts/PermanentMarker-Regular.ttf"
		"hand": path = "res://assets/fonts/PatrickHand-Regular.ttf"
		"type": path = "res://assets/fonts/SpecialElite-Regular.ttf"
		"slab": path = "res://assets/fonts/AlfaSlabOne-Regular.ttf"
		_: path = "res://assets/fonts/PatrickHand-Regular.ttf"
	var f: Font = load(path)
	_fonts[kind] = f
	return f


static func sticky(name: String) -> Color:
	return STICKY.get(name, STICKY["yellow"])


## Paper note with drop shadow and a slight curl at the bottom-right corner.
static func draw_note(ci: CanvasItem, r: Rect2, col: Color, shadow := true, curl := true) -> void:
	if shadow:
		ci.draw_colored_polygon(PackedVector2Array([r.position + Vector2(4, 6), Vector2(r.end.x + 3, r.position.y + 6), r.end + Vector2(3, 5), Vector2(r.position.x + 4, r.end.y + 5)]), Color(0.2, 0.15, 0.1, 0.18))
	ci.draw_rect(r, col)
	if curl:
		var c := r.end
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-16, 0), c, c + Vector2(0, -16)]), col.darkened(0.12))
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-16, 0), c + Vector2(0, -16), c + Vector2(-13, -13)]), col.lightened(0.25))
	# faint top band like a real sticky note glue strip
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 7)), Color(1, 1, 1, 0.18))


static func draw_tape(ci: CanvasItem, center: Vector2, size: Vector2, angle: float) -> void:
	var pts := PackedVector2Array()
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	for v in [Vector2(-hx, -hy), Vector2(hx, -hy), Vector2(hx, hy), Vector2(-hx, hy)]:
		pts.append(center + v.rotated(angle))
	ci.draw_colored_polygon(pts, TAPE)
	# jagged ends
	for s in [-1, 1]:
		var e: Vector2 = center + Vector2(hx * s, 0).rotated(angle)
		for k in 4:
			var p := e + Vector2(0, -hy + k * size.y / 3.0).rotated(angle)
			ci.draw_line(p, p + Vector2(2.5 * s, size.y / 6.0).rotated(angle), Color(0.9, 0.86, 0.7, 0.6), 1.0)


static func draw_pin(ci: CanvasItem, p: Vector2, col: Color) -> void:
	ci.draw_circle(p + Vector2(1.5, 2.5), 6.5, Color(0, 0, 0, 0.18))
	ci.draw_circle(p, 6.5, col)
	ci.draw_circle(p + Vector2(-2, -2), 2.2, col.lightened(0.5))


static func draw_clip(ci: CanvasItem, p: Vector2, h := 34.0) -> void:
	var c := Color("8d99ae")
	var pts := PackedVector2Array([p + Vector2(0, h), p + Vector2(0, 6), p + Vector2(5, 0), p + Vector2(10, 6), p + Vector2(10, h - 8), p + Vector2(6, h - 4), p + Vector2(3, h - 8), p + Vector2(3, 10)])
	ci.draw_polyline(pts, c, 2.2, true)


static func draw_lined_paper(ci: CanvasItem, r: Rect2, col := PAPER, line_gap := 26.0, margin := true) -> void:
	ci.draw_rect(r, col)
	var y := r.position.y + line_gap + 8.0
	while y < r.end.y - 4:
		ci.draw_line(Vector2(r.position.x + 6, y), Vector2(r.end.x - 6, y), Color(0.45, 0.65, 0.9, 0.28), 1.0)
		y += line_gap
	if margin:
		ci.draw_line(Vector2(r.position.x + 34, r.position.y + 2), Vector2(r.position.x + 34, r.end.y - 2), Color(0.9, 0.3, 0.35, 0.35), 1.2)


static func draw_scribble_bar(ci: CanvasItem, r: Rect2, frac: float, col: Color) -> void:
	# hand-drawn looking progress bar
	ci.draw_rect(Rect2(r.position + Vector2(1, 2), r.size), Color(0, 0, 0, 0.08))
	ci.draw_rect(r, Color(1, 1, 1, 0.65))
	var fw := r.size.x * clampf(frac, 0.0, 1.0)
	if fw > 1.0:
		var n := int(fw / 5.0)
		for i in n:
			var x := r.position.x + i * 5.0
			ci.draw_line(Vector2(x, r.end.y - 1), Vector2(x + 7, r.position.y + 1), col, 2.4, true)
		ci.draw_rect(Rect2(r.position, Vector2(fw, r.size.y)), Color(col.r, col.g, col.b, 0.35))
	ci.draw_rect(r, INK, false, 1.4)
