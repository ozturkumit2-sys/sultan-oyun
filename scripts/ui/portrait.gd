class_name Portrait
extends Control
## A live character portrait (optionally framed as a polaroid) for UI cards.

var cv: CharacterView
var clip: Control
var polaroid := true
var tilt := 0.0
var zoom := 1.0
var npc_id := ""


static func make(world: SimWorld, id: String, sz: Vector2, polaroid_frame := true, z := 1.0) -> Portrait:
	var p := Portrait.new()
	p.custom_minimum_size = sz
	p.polaroid = polaroid_frame
	p.zoom = z
	p.npc_id = id
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.clip = Control.new()
	p.clip.clip_contents = true
	p.clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(p.clip)
	p.cv = CharacterView.new()
	p.cv.portrait = true
	p.cv.setup(world.npc(id), world)
	p.clip.add_child(p.cv)
	return p


func _process(_d: float) -> void:
	if cv == null:
		return
	var inner := _inner_rect()
	clip.position = inner.position
	clip.size = inner.size
	var s := inner.size.y / 50.0 * zoom
	cv.scale = Vector2(s, s)
	cv.position = Vector2(inner.size.x * 0.5 - 2.0 * s, inner.size.y + 26.0 * s)
	queue_redraw()


func _inner_rect() -> Rect2:
	if polaroid:
		return Rect2(Vector2(8, 8), size - Vector2(16, 30))
	return Rect2(Vector2.ZERO, size)


func _draw() -> void:
	var bg: Color = UiKit.NPC_COLOR.get(npc_id, Color.GRAY).lightened(0.72)
	if polaroid:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(Rect2(r.position + Vector2(3, 5), r.size), Color(0, 0, 0, 0.18))
		draw_rect(r, Color("fffdf8"))
		draw_rect(_inner_rect(), bg)
		draw_rect(r, UiKit.INK_SOFT, false, 1.0)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), bg)
