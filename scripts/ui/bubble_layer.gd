class_name BubbleLayer
extends Control
## Speech bubbles drawn in screen space above the speakers, always readable.

const MAX_W := 250.0
const FONT_SIZE := 20

var view: OfficeView
var bubbles: Array = []    # {id, text, life, max, lines: Array, size: Vector2, pos: Vector2, to}
var font: Font


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	font = UiKit.font("hand")


func add(npc_id: String, text: String, to: String) -> void:
	# one bubble per speaker: replace the previous one
	for b in bubbles.duplicate():
		if b["id"] == npc_id:
			bubbles.erase(b)
	var dur := clampf(2.2 + text.length() * 0.045, 2.6, 5.5)
	var lines := _wrap(text)
	var wmax := 0.0
	for l in lines:
		wmax = maxf(wmax, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
	var sz := Vector2(wmax + 26.0, lines.size() * (FONT_SIZE + 2) + 30.0)
	bubbles.append({"id": npc_id, "text": text, "life": 0.0, "max": dur, "lines": lines, "size": sz, "pos": Vector2.ZERO, "to": to})
	while bubbles.size() > 6:
		bubbles.pop_front()


func clear_all() -> void:
	bubbles.clear()


func _wrap(text: String) -> Array:
	var words := text.split(" ")
	var lines: Array = []
	var cur := ""
	for wd in words:
		var cand := wd if cur == "" else cur + " " + wd
		if font.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x > MAX_W and cur != "":
			lines.append(cur)
			cur = wd
		else:
			cur = cand
	if cur != "":
		lines.append(cur)
	return lines


func _process(delta: float) -> void:
	if view == null:
		return
	var vs := get_viewport_rect().size
	for i in range(bubbles.size() - 1, -1, -1):
		var b: Dictionary = bubbles[i]
		b["life"] += delta
		if b["life"] >= b["max"]:
			bubbles.remove_at(i)
	# place above heads, then push overlapping bubbles upward
	var rects: Array = []
	for b in bubbles:
		var cv: CharacterView = view.chars.get(b["id"])
		if cv == null or not cv.visible:
			b["pos"] = Vector2(-9999, -9999)
			continue
		var sitting := cv.npc.pose in ["sit", "type", "eat", "read"]
		var head := view.world_to_screen(cv.position + Vector2(0, -84 if not sitting else -76))
		var sz: Vector2 = b["size"]
		var p := Vector2(head.x - sz.x * 0.5, head.y - sz.y - 6)
		p.x = clampf(p.x, 8, vs.x - sz.x - 8)
		p.y = clampf(p.y, 130, vs.y - 160 - sz.y)
		var r := Rect2(p, sz)
		var guard := 0
		var moved := true
		while moved and guard < 8:
			moved = false
			guard += 1
			for o in rects:
				if r.intersects(o.grow(3)):
					r.position.y = o.position.y - sz.y - 4
					moved = true
		b["pos"] = r.position
		b["head"] = head
		rects.append(r)
	queue_redraw()


func _draw() -> void:
	for b in bubbles:
		var p: Vector2 = b["pos"]
		if p.x < -999:
			continue
		var sz: Vector2 = b["size"]
		var life: float = b["life"]
		var a := minf(1.0, life / 0.15) * minf(1.0, (b["max"] - life) / 0.35)
		var pop := 1.0 + 0.12 * maxf(0.0, 1.0 - life / 0.15)
		var r := Rect2(p, sz)
		var c := r.get_center()
		draw_set_transform(c, 0.0, Vector2(pop, pop))
		var rr := Rect2(-sz * 0.5, sz)
		var col: Color = UiKit.NPC_COLOR.get(b["id"], UiKit.INK)
		# tail toward the speaker's head
		var head: Vector2 = b.get("head", c + Vector2(0, sz.y))
		var hl := (head - c)
		var tip := hl.limit_length(sz.y * 0.5 + 18.0)
		var base_x := clampf(tip.x * 0.5, -sz.x * 0.3, sz.x * 0.3)
		var tail := PackedVector2Array([Vector2(base_x - 9, rr.end.y - 4), Vector2(base_x + 9, rr.end.y - 4), tip])
		draw_colored_polygon(PackedVector2Array([rr.position + Vector2(3, 5), Vector2(rr.end.x + 3, rr.position.y + 5), rr.end + Vector2(3, 5), Vector2(rr.position.x + 3, rr.end.y + 5)]), Color(0, 0, 0, 0.14 * a))
		Iso.rrect(self, rr, 12, Color(1, 1, 1, 0.97 * a), Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, 0.85 * a), 1.6)
		draw_colored_polygon(tail, Color(1, 1, 1, 0.97 * a))
		draw_line(tail[0], tail[2], Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, 0.85 * a), 1.6, true)
		draw_line(tail[1], tail[2], Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, 0.85 * a), 1.6, true)
		draw_line(tail[0] + Vector2(1, -1), tail[1] + Vector2(-1, -1), Color(1, 1, 1, a), 3.0)
		# name tag
		var n: NPC = view.w.npc(b["id"])
		var name_s: String = n.name if n else ""
		var nw := font.get_string_size(name_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 14
		Iso.rrect(self, Rect2(rr.position + Vector2(10, -10), Vector2(nw, 20)), 6, Color(col.r, col.g, col.b, a), Color(0, 0, 0, 0))
		draw_string(UiKit.font("hand"), rr.position + Vector2(17, 5), name_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, a))
		var y := rr.position.y + 16.0 + FONT_SIZE * 0.8
		for l in b["lines"]:
			draw_string(font, Vector2(rr.position.x + 13, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, a))
			y += FONT_SIZE + 2
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
